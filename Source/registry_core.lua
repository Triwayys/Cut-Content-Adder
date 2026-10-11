-- Pure registry logic. Runtime adapter provides bounded reads and verified writes.
local Core = {}
local COUNT, ROWS, MAPS, GATE = 0x1ce0, 0x1ce4, 0xb9ce4, 0xddcf8
local CAP, RS, MS = 4096, 184, 24
local function u32(b,o)
  if type(b)~='string' or #b<o+4 then return nil end
  local a,c,d,e=b:byte(o+1,o+4); return a+c*256+d*65536+e*16777216
end
local function le32(n)
  return string.char(n%256,math.floor(n/256)%256,math.floor(n/65536)%256,math.floor(n/16777216)%256)
end
local function replace(b,o,n) return b:sub(1,o)..le32(n)..b:sub(o+5) end
Core.u32,Core.le32=u32,le32
function Core.new(io)
  local self={io=io,fatal=false}
  function self:snapshot()
    local root=io.root()
    if not root or root<65536 then return nil,'registry pointer unavailable' end
    if u32(io.read(root+GATE,4),0)~=12 then return nil,'registry not ready' end
    local count=u32(io.read(root+COUNT,4),0)
    if not count or count<1 or count>CAP then return nil,'registry count invalid' end
    local maps=io.read(root+MAPS,count*MS)
    if not maps then return nil,'registry mappings unreadable' end
    return {root=root,count=count,maps=maps}
  end
  function self:current(s)
    return io.root()==s.root and u32(io.read(s.root+GATE,4),0)==12
      and u32(io.read(s.root+COUNT,4),0)==s.count
  end
  function self:find(s,key)
    local result
    for p=0,s.count-1 do
      local m=s.maps:sub(p*MS+1,(p+1)*MS)
      -- Composite attachment IDs are not base-equipment identities.
      if u32(m,4)==key and u32(m,8)==key then
        if result then return nil,'duplicate equipment mappings' end
        local idx=u32(m,0)
        if not idx or idx>=s.count then return nil,'mapping index out of range' end
        local row=io.read(s.root+ROWS+idx*RS,RS)
        if not row or u32(row,0)~=idx or u32(row,4)~=key or u32(row,8)~=key then
          return nil,'record identity mismatch'
        end
        result={index=idx,row=row,map=m}
      end
    end
    return result
  end
  function self:find_cosmetic(s,t)
    local record_key=t.record_key or t.key
    local result
    for p=0,s.count-1 do
      local map=s.maps:sub(p*MS+1,(p+1)*MS)
      if u32(map,4)==record_key and u32(map,8)==t.key then
        if result then return nil,'duplicate cosmetic mappings' end
        local index=u32(map,0)
        if not index or index>=s.count then return nil,'cosmetic index out of range' end
        local row=io.read(s.root+ROWS+index*RS,RS)
        if not row or u32(row,0)~=index or u32(row,4)~=record_key or u32(row,8)~=t.key
          or u32(row,12)~=3 then return nil,'cosmetic identity/type mismatch' end
        result={index=index,row=row,map=map}
      end
    end
    return result
  end
  function self:find_stratagem(s,t)
    local record_key=t.record_key or t.key
    local result
    for p=0,s.count-1 do
      local map=s.maps:sub(p*MS+1,(p+1)*MS)
      if u32(map,4)==record_key and u32(map,8)==t.key then
        if result then return nil,'duplicate stratagem mappings' end
        local index=u32(map,0)
        if not index or index>=s.count then return nil,'stratagem index out of range' end
        local row=io.read(s.root+ROWS+index*RS,RS)
        if not row or u32(row,0)~=index or u32(row,4)~=record_key or u32(row,8)~=t.key
          or u32(row,12)~=10 then return nil,'stratagem identity/type mismatch' end
        result={index=index,row=row,map=map}
      end
    end
    return result
  end
  function self:transaction(s,changes)
    if self.fatal then return false,'writes disabled after unsafe transaction' end
    if not self:current(s) then return false,'registry changed before transaction' end
    for _,c in ipairs(changes) do
      if io.read(c.addr,#c.old)~=c.old then return false,'data changed before transaction' end
      if not io.writable(c.addr,#c.new) then return false,'target memory is not writable' end
    end
    local attempted={}
    local good,err=pcall(function()
      for _,c in ipairs(changes) do
        assert(self:current(s),'registry changed during transaction')
        assert(io.read(c.addr,#c.old)==c.old,'data changed during transaction')
        attempted[#attempted+1]=c
        assert(io.write(c.addr,c.new) and io.read(c.addr,#c.new)==c.new,'write/readback failed')
        if c.count then s.count=u32(c.new,0) end
      end
      assert(self:current(s),'registry changed after transaction')
      for _,c in ipairs(changes) do assert(io.read(c.addr,#c.new)==c.new,'final readback failed') end
    end)
    if good then
      -- Remember how to undo every verified write; shutdown() replays this in reverse order.
      if io.journal then
        for _,c in ipairs(changes) do
          io.journal.push(string.format('registry@%X',c.addr),function()
            if io.root()~=s.root or u32(io.read(s.root+GATE,4),0)~=12 then return false end
            if io.read(c.addr,#c.new)~=c.new then return false end
            return io.write(c.addr,c.old)
          end)
        end
      end
      return true
    end
    -- Never roll back into a replaced registry. Stop writing if ownership is unclear.
    local safe=io.root()==s.root and u32(io.read(s.root+GATE,4),0)==12
    local actual=u32(io.read(s.root+COUNT,4),0)
    local expected=s.count
    for _,c in ipairs(attempted) do
      if c.count then safe=safe and (actual==u32(c.old,0) or actual==u32(c.new,0)); expected=actual end
    end
    safe=safe and actual==expected
    if safe then
      for i=#attempted,1,-1 do
        local c=attempted[i]
        if io.root()~=s.root or u32(io.read(s.root+GATE,4),0)~=12 then safe=false;break end
        if not io.write(c.addr,c.old) or io.read(c.addr,#c.old)~=c.old then safe=false;break end
      end
    end
    if not safe then self.fatal=true end
    return false,tostring(err)..'; rollback='..tostring(safe)
  end
  function self:weapon(t)
    local key,category,why=io.class(t.hi,t.lo)
    if not key then return false,why or 'target model not found' end
    if t.key and key~=t.key then return false,'target key/model mismatch' end
    local s,e=self:snapshot(); if not s then return false,e end
    local existing,err=self:find(s,key);if err then return false,err end
    if existing then
      if u32(existing.row,12)~=1 then return false,'existing record is not base equipment' end
      local status=u32(existing.row,20)
      if status==2 or status==4 then return true,'available' end
      if status~=0 and status~=1 then return false,'unknown equipment status '..tostring(status) end
      local ok,msg=self:transaction(s,{{addr=s.root+ROWS+existing.index*RS+20,old=le32(status),new=le32(2)}})
      return ok,msg or 'existing entry enabled'
    end
    local template_key,template_category,te
    if t.template_key then template_key,template_category=t.template_key,t.category
    else template_key,template_category,te=io.class(t.template_hi,t.template_lo) end
    if not template_key then return false,te or 'template class missing' end
    if category~=template_category then return false,'target/template categories differ' end
    local template,fe=self:find(s,template_key)
    if not template then return false,fe or 'template record missing' end
    if u32(template.row,12)~=1 then return false,'template is not base equipment' end
    local status=u32(template.row,20)
    if status~=0 and status~=1 and status~=2 and status~=4 then return false,'unknown template status' end
    if s.count>=CAP then return false,'registry full' end
    local ts=u32(template.row,20)
    if ts~=0 and ts~=1 and ts~=2 and ts~=4 then return false,'unknown append template status' end
    local ra,ma,ca=s.root+ROWS+s.count*RS,s.root+MAPS+s.count*MS,s.root+COUNT
    local ro,mo=io.read(ra,RS),io.read(ma,MS)
    if ro~=string.rep('\0',RS) or mo~=string.rep('\0',MS) then return false,'append slots occupied' end
    local row=replace(replace(replace(replace(template.row,0,s.count),4,key),8,key),20,2)
    local map=replace(replace(replace(template.map,0,s.count),4,key),8,key)
    local ok,msg=self:transaction(s,{
      {addr=ra,old=ro,new=row},{addr=ma,old=mo,new=map},
      {addr=ca,old=le32(s.count),new=le32(s.count+1),count=true}})
    return ok,msg or 'entry appended'
  end
  function self:cosmetic(t)
    local s,e=self:snapshot();if not s then return false,e end
    local existing,why=self:find_cosmetic(s,t)
    if not existing then return false,why or 'cosmetic record absent; no synthetic cosmetic record created' end
    if u32(existing.row,12)~=3 then return false,'cosmetic cosmetic record type mismatch' end
    local state=u32(existing.row,20)
    if state==2 or state==4 then return true,'available' end
    if state~=0 and state~=1 then return false,'unknown cosmetic status '..tostring(state) end
    local ok,msg=self:transaction(s,{{addr=s.root+ROWS+existing.index*RS+20,old=le32(state),new=le32(2)}})
    return ok,msg or 'existing cosmetic entry enabled'
  end
  function self:cape(t)
    local s,e=self:snapshot();if not s then return false,e end
    local existing,why=self:find(s,t.key)
    if not existing then return false,why or 'cape record absent; no synthetic cape record created' end
    if u32(existing.row,12)~=3 then return false,'cape cosmetic record type mismatch' end
    local state=u32(existing.row,20)
    if state==2 or state==4 then return true,'available' end
    if state~=0 and state~=1 then return false,'unknown cape status '..tostring(state) end
    local ok,msg=self:transaction(s,{{addr=s.root+ROWS+existing.index*RS+20,old=le32(state),new=le32(2)}})
    return ok,msg or 'existing cape entry enabled'
  end
  -- One indexed snapshot is shared across the cosmetic pass. Appends invalidate it.
  function self:catalogue_cosmetic(t,s)
    if io.kit then local ok,why=io.kit(t);if not ok then return false,why end end
    local e;if not s then s,e=self:snapshot() end;if not s then return false,e end
    if not s.cosmetic_index then
      s.cosmetic_index={}
      for p=0,s.count-1 do
        local map=s.maps:sub(p*MS+1,(p+1)*MS);local key=u32(map,8)
        local list=s.cosmetic_index[key] or {};s.cosmetic_index[key]=list;list[#list+1]=map
      end
    end
    local matches=s.cosmetic_index[t.key]
    if matches and #matches>0 then
      if #matches~=1 then return false,'duplicate cosmetic equipment identities' end
      local map=matches[1];local index=u32(map,0);local rk=u32(map,4)
      if rk~=t.key and rk~=t.record_key then return false,'unexpected cosmetic record key' end
      if index>=s.count then return false,'cosmetic index out of range' end
      local row=io.read(s.root+ROWS+index*RS,RS)
      if not row or u32(row,0)~=index or u32(row,4)~=rk or u32(row,8)~=t.key or u32(row,12)~=3 then
        return false,'cosmetic row identity/type mismatch'
      end
      local state=u32(row,20)
      if state==2 or state==4 then return true,'available' end
      if state~=0 and state~=1 then return false,'unknown cosmetic status' end
      local ok,why=self:transaction(s,{{addr=s.root+ROWS+index*RS+20,old=le32(state),new=le32(2)}})
      return ok,why or 'existing cosmetic enabled'
    end
    if not t.allow_append then return false,'cosmetic absent' end
    local template,why=self:find(s,t.template_key)
    if not template or u32(template.row,12)~=3 then return false,why or 'standalone cosmetic template missing' end
    if template.map:sub(13)~=string.rep('\0',12) then return false,'template is not standalone' end
    local state=u32(template.row,20)
    if state~=0 and state~=1 and state~=2 and state~=4 then return false,'unknown template state' end
    return self:append_standalone(s,t.key,template,3)
  end
  function self:append_standalone(s,key,template,kind,prefix)
    if s.count>=CAP then return false,'registry full' end
    -- A standalone item uses equal record/equipment keys and no parent-relative offsets.
    -- Both armor and helmet examples of this shape occur in the supplied live dump.
    for p=0,s.count-1 do
      local map=s.maps:sub(p*MS+1,(p+1)*MS)
      if u32(map,4)==key or u32(map,8)==key then return false,'append identity collision' end
    end
    if u32(template.row,12)~=kind then return false,'append template type mismatch' end
    local ts=u32(template.row,20)
    if ts~=0 and ts~=1 and ts~=2 and ts~=4 then return false,'unknown append template status' end
    local ra,ma,ca=s.root+ROWS+s.count*RS,s.root+MAPS+s.count*MS,s.root+COUNT
    local ro,mo=io.read(ra,RS),io.read(ma,MS)
    if ro~=string.rep('\0',RS) or mo~=string.rep('\0',MS) then return false,'append slots occupied' end
    local row=replace(replace(replace(replace(template.row,0,s.count),4,key),8,key),20,2)
    local map=le32(s.count)..le32(key)..le32(key)..string.rep('\0',12)
    local changes=prefix or {}
    changes[#changes+1]={addr=ra,old=ro,new=row};changes[#changes+1]={addr=ma,old=mo,new=map}
    changes[#changes+1]={addr=ca,old=le32(s.count),new=le32(s.count+1),count=true}
    local ok,why=self:transaction(s,changes)
    return ok,why or 'standalone entry appended (gameplay unverified)'
  end
  function self:stratagem(t)
    local s,e=self:snapshot();if not s then return false,e end
    local found,why=self:find_stratagem(s,t)
    if why then return false,why end
    if not found and not t.allow_append then return false,'stratagem registry entry absent; no partial unlock' end
    local flag,err=io.strat_flag(t.id,t.key)
    if not flag then return false,err or 'stratagem table unavailable' end
    local old=io.read(flag,1)
    if not old then return false,'selection flag unreadable' end
    if not found then
      local template,te=self:find(s,t.template_key)
      if not template or u32(template.row,12)~=10 or template.map:sub(13)~=string.rep('\0',12) then
        return false,te or 'standalone stratagem template unavailable'
      end
      local changes={}
      if math.floor(old:byte()/2)%2==0 then changes[1]={addr=flag,old=old,new=string.char(old:byte()+2)} end
      return self:append_standalone(s,t.key,template,10,changes)
    end
    local status=u32(found.row,20)
    if status~=0 and status~=1 and status~=2 and status~=4 then return false,'unknown stratagem status' end
    local changes={}
    if math.floor(old:byte()/2)%2==0 then changes[#changes+1]={addr=flag,old=old,new=string.char(old:byte()+2)} end
    if status~=2 and status~=4 then changes[#changes+1]={addr=s.root+ROWS+found.index*RS+20,old=le32(status),new=le32(2)} end
    if #changes==0 then return true,'available' end
    local ok,msg=self:transaction(s,changes)
    return ok,msg or 'selection and registry status enabled'
  end
  return self
end
return Core
