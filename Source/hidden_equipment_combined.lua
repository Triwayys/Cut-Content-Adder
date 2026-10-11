-- HD2-Addon: mods/codex/hidden_equipment_combined
-- Combined hidden equipment unlocks; build 25480438 only; in-game testing pending.
local VERSION = '1.0'
local GAME_SHA256 = '2e2c3b7c2500646dadd5f2b4c6e0504dbb7e7896139f64cddc0d1813c718f51e'
local EXE_SHA256 = 'f5fee03dcfdb2e553a4752c283590950ac13316b376d8196aa556ff0400d5f06'
local NAME = 'HiddenEquipmentCombined'
local prior = rawget(_G, NAME)
if prior then return prior end
local public = {version = VERSION, status = 'initializing'}
rawset(_G, NAME, public)

local loader = rawget(_G, 'CowboyBingusModLoader')
local log
if type(loader) == 'table' and type(loader.open_log) == 'function' then
    local ok, handle = pcall(loader.open_log, 'HiddenEquipmentCombined.log')
    if ok then log = handle end
end
local function emit(message)
    local line = '[HiddenEquipmentCombined] ' .. message
    pcall(print, line)
    if log then pcall(function() log:write(line .. '\n'); log:flush() end) end
end
local function finish(message)
    public.status = message
    emit(message)
    if log then pcall(function() log:close() end); log = nil end
end
if type(loader) ~= 'table' or loader.api ~= 1 or (tonumber(loader.version) or 0) < 16 or type(loader.open_log) ~= 'function' then
    finish('disabled: incompatible Bingus interface; require API 1, interface version 16+, open_log. Observed api='..tostring(type(loader)=='table' and loader.api)..'; interface_version='..tostring(type(loader)=='table' and loader.version))
    return public
end
if type(rawget(_G, 'update')) ~= 'function' then
    finish('disabled: update callback unavailable')
    return public
end

-- Shutdown journal shared by every module in this package (hidden equipment + Shear customization).
-- Each successful write to game memory registers an undo closure; shutdown() replays them in
-- reverse order so the engine tears down its ORIGINAL registry, not our modified one.
local journal = rawget(_G, 'HD2WriteJournal')
if not journal then
    journal = {entries = {}}
    function journal.push(name, undo)
        journal.entries[#journal.entries + 1] = {name = name, undo = undo}
    end
    function journal.run()
        local entries = journal.entries
        journal.entries = {}
        local restored, skipped = 0, 0
        for i = #entries, 1, -1 do
            local ok, result = pcall(entries[i].undo)
            if ok and result then restored = restored + 1 else skipped = skipped + 1 end
        end
        return restored, skipped
    end
    rawset(_G, 'HD2WriteJournal', journal)
end

local function initialize()
local ok_ffi, ffi = pcall(require, 'ffi')
if not ok_ffi or ffi.os ~= 'Windows' or not ffi.abi('64bit') then
    finish('disabled: Windows x64 LuaJIT FFI required')
    return public
end
ffi.cdef [[
    void *GetModuleHandleA(const char *);
    uint32_t GetModuleFileNameW(void *, uint16_t *, uint32_t);
    void *GetCurrentProcess(void);
    int ReadProcessMemory(void *, const void *, void *, size_t, size_t *);
    size_t VirtualQuery(const void *, void *, size_t);
    void *CreateFileW(const uint16_t *, uint32_t, uint32_t, void *, uint32_t, uint32_t, void *);
    int ReadFile(void *, void *, uint32_t, uint32_t *, void *);
    int CloseHandle(void *);
    int32_t BCryptOpenAlgorithmProvider(void **, const uint16_t *, const uint16_t *, uint32_t);
    int32_t BCryptCreateHash(void *, void **, void *, uint32_t, const void *, uint32_t, uint32_t);
    int32_t BCryptHashData(void *, const void *, uint32_t, uint32_t);
    int32_t BCryptFinishHash(void *, void *, uint32_t, uint32_t);
    int32_t BCryptDestroyHash(void *);
    int32_t BCryptCloseAlgorithmProvider(void *, uint32_t);
]]
local k, bcrypt = ffi.load('kernel32'), ffi.load('bcrypt')
local process = k.GetCurrentProcess()
local function read(address, length)
    if type(address) ~= 'number' or address < 65536 or address + length >= 0x800000000000
        or length < 1 or length > 1024 * 1024 then return nil end
    local out, count = ffi.new('uint8_t[?]', length), ffi.new('size_t[1]')
    if k.ReadProcessMemory(process, ffi.cast('const void *', address), out, length, count) == 0
        or tonumber(count[0]) ~= length then return nil end
    return ffi.string(out, length)
end
local function u32(bytes, offset)
    if type(bytes) ~= 'string' then return nil end
    local a, b, c, d = bytes:byte(offset + 1, offset + 4)
    if not d then return nil end
    return a + b * 256 + c * 65536 + d * 16777216
end
local function u64at(bytes, offset)
    local p = ffi.new('uint64_t[1]')
    ffi.copy(p, bytes:sub(offset + 1, offset + 8), 8)
    return tonumber(p[0])
end
local function f32(bytes, offset)
    if #bytes < offset + 4 then return nil end
    local n = ffi.new('union { uint32_t bits; float value; }')
    n.bits = u32(bytes, offset)
    return tonumber(n.value)
end
local function sha256_of_module(module)
    local path = ffi.new('uint16_t[32768]')
    local n = tonumber(k.GetModuleFileNameW(ffi.cast('void *', module), path, 32768))
    assert(n > 0 and n < 32768, 'module_path_unavailable')
    local file = k.CreateFileW(path, 0x80000000, 7, nil, 3, 0x08000000, nil)
    assert(file ~= ffi.cast('void *', -1), 'module_file_unavailable')
    local algorithm, hash = ffi.new('void *[1]'), ffi.new('void *[1]')
    local ok, result = pcall(function()
        local name = ffi.new('uint16_t[7]', {83, 72, 65, 50, 53, 54, 0})
        assert(bcrypt.BCryptOpenAlgorithmProvider(algorithm, name, nil, 0) == 0, 'sha256_provider')
        assert(bcrypt.BCryptCreateHash(algorithm[0], hash, nil, 0, nil, 0, 0) == 0, 'sha256_create')
        local chunk, count = ffi.new('uint8_t[65536]'), ffi.new('uint32_t[1]')
        local total = 0
        while true do
            assert(k.ReadFile(file, chunk, 65536, count, nil) ~= 0, 'module_file_read')
            if count[0] == 0 then break end
            total = total + tonumber(count[0])
            assert(total <= 64 * 1024 * 1024, 'module_file_size_limit')
            assert(bcrypt.BCryptHashData(hash[0], chunk, count[0], 0) == 0, 'sha256_update')
        end
        local digest, parts = ffi.new('uint8_t[32]'), {}
        assert(bcrypt.BCryptFinishHash(hash[0], digest, 32, 0) == 0, 'sha256_finish')
        for i = 0, 31 do parts[#parts + 1] = string.format('%02x', digest[i]) end
        return table.concat(parts)
    end)
    if hash[0] ~= nil then bcrypt.BCryptDestroyHash(hash[0]) end
    if algorithm[0] ~= nil then bcrypt.BCryptCloseAlgorithmProvider(algorithm[0], 0) end
    k.CloseHandle(file)
    assert(ok, result)
    return result
end

local function dlsum(name)
    local h=5381
    for i=1,#name do h=(h*33+name:byte(i))%4294967296 end
    return (h-5381)%4294967296
end
local function le32(v)
    return string.char(v%256,math.floor(v/256)%256,
        math.floor(v/65536)%256,math.floor(v/16777216)%256)
end
local function region(address)
    local info=ffi.new('uint8_t[48]')
    if tonumber(k.VirtualQuery(ffi.cast('const void *',address),info,48))~=48 then return nil end
    local bytes=ffi.string(info,48)
    return u64at(bytes,0),u64at(bytes,24),u32(bytes,32),u32(bytes,36),u32(bytes,40)
end
local function readable(state,protection,kind)
    local base=protection%256
    return state==0x1000 and (kind==0x20000 or kind==0x40000)
        and protection<0x100 and (base==2 or base==4 or base==8
            or base==0x20 or base==0x40 or base==0x80)
end




ffi.cdef [[
uint64_t GetTickCount64(void);
int WriteProcessMemory(void *, void *, const void *, size_t, size_t *);
]]
local game=k.GetModuleHandleA('game.dll')
if game==nil then finish('disabled: game.dll unavailable');return public end
local base=tonumber(ffi.cast('uintptr_t',game))
local ok,hash=pcall(sha256_of_module,base)
local exok,exhash=pcall(sha256_of_module,k.GetModuleHandleA(nil))
if not ok or hash~=GAME_SHA256 or not exok or exhash~=EXE_SHA256 then finish('disabled: build mismatch; expected Steam 25480438. game.dll='..tostring(hash)..'; exe='..tostring(exhash));return public end
local function now()return tonumber(k.GetTickCount64())/1000 end
local function ptr(a)local b=read(a,8);return b and u64at(b,0)end
local function hex(b)return (b:gsub('.',function(c)return string.format('%02X',c:byte())end))end
local function rip(rva,op)
 local b=read(base+rva,7);assert(b and b:sub(1,3)==op,'root instruction mismatch')
 local d=u32(b,3);if d>=0x80000000 then d=d-0x100000000 end
 return base+rva+7+d
end
local item_slot=rip(0x136fdf0,string.char(0x48,0x8b,0x05))
local class_slot=rip(0x11e7c65,string.char(0x48,0x8b,0x1d))
local SHEAR,SCYTHE=0x7de53646,0xe673dcc8
local expected_class=le32(SHEAR)..le32(0)..string.char(0x48,0xb9,0xa4,0xba,0xa5,0x45,0x31,0x7e)..le32(1)..string.rep('\0',12)
local function writable(addr,len)
 local rb,rs,state,prot,kind=region(addr)
 return rb and addr+len<=rb+rs and state==0x1000 and prot==4 and kind==0x20000
end
local function write(addr,b)
 if not writable(addr,#b)then return false end
 local count=ffi.new('size_t[1]')
 local buf=ffi.new('uint8_t[?]',#b);ffi.copy(buf,b,#b)
 return k.WriteProcessMemory(process,ffi.cast('void *',addr),buf,#b,count)~=0 and tonumber(count[0])==#b and read(addr,#b)==b
end
local function replace32(b,off,v)return b:sub(1,off)..le32(v)..b:sub(off+5)end

local Core=(function()
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

end)()
local Native=(function()
-- Read-only, build-pinned native identity checks. No native functions are called.
local Native={}
function Native.new(io)
 local n={}
 local function word(b,o)return b and io.u32(b,o)end
 function n:begin() self.kits=nil end
 function n:kit(t)
  if not self.kits then
   local manager=io.ptr(io.base+53634296)
   local head=manager and io.read(manager,16)
   local array=head and io.u64(head,0);local count=word(head,8)
   if not array or array<65536 or not count or count<1 or count>2048 or word(head,12)~=0 then
    return false,'customization kit table unavailable'
   end
   local pointers=io.read(array,count*8)
   if not pointers then return false,'kit pointers unreadable' end
   self.kits={manager=manager,array=array,count=count,pointers=pointers}
  end
  local cache=self.kits
  local function at(i)
   if i<0 or i>=cache.count then return nil end
   local addr=io.u64(cache.pointers,i*8)
   local b=addr and addr>=65536 and io.read(addr,64)
   if word(b,0)==t.key then return b end
  end
  local b=at(t.kit_index)
  if not b then
   for i=0,cache.count-1 do b=at(i);if b then break end end
  end
  if not b then return false,'kit definition missing' end
  if word(b,40)~=t.kind or word(b,32)~=t.archive_lo or word(b,36)~=t.archive_hi then
   return false,'kit type/archive identity mismatch'
  end
  local bodies,count=io.u64(b,48),word(b,56)
  if count~=t.body_count or count<1 or count>8 or word(b,60)~=0 or bodies<65536 then
   return false,'kit body layout mismatch'
  end
  if not io.read(bodies,count*24) then return false,'kit bodies unavailable' end
  local head=io.read(cache.manager,16)
  if io.ptr(io.base+53634296)~=cache.manager or not head or io.u64(head,0)~=cache.array
   or word(head,8)~=cache.count then self.kits=nil;return false,'kit table changed' end
  return true
 end
 -- Read-only diagnostic after the same kit identity guards used by unlocking.
 function n:inspect_kit(t)
  local ok,why=self:kit(t);if not ok then return nil,why end
  local cache=self.kits
  for i=0,cache.count-1 do
   local addr=io.u64(cache.pointers,i*8)
   local b=addr and addr>=65536 and io.read(addr,64)
   if word(b,0)==t.key then
    if not self:kit(t) then return nil,'kit changed during diagnostic' end
    return b
   end
  end
  return nil,'kit disappeared during diagnostic'
 end
 function n:category_guard()
  if io.read(io.base+0x136eb50,27)~=string.char(139,2,72,141,146,184,0,0,0,139,140,134,228,28,13,0,3,76,132,48,137,156,142,72,29,13,0)then return false,'category index code signature mismatch' end
  if io.read(io.base+0x18d81e2,27)~=string.char(65,139,149,240,28,13,0,69,139,141,244,28,13,0,65,59,209,115,51,76,141,4,149,72,29,13,0)then return false,'category index code signature mismatch' end
  if io.read(io.base+0x13720ca,34)~=string.char(65,139,192,139,132,129,228,28,13,0,65,141,72,1,69,139,140,139,228,28,13,0,65,59,193,115,42,77,141,131,72,29,13,0)then return false,'category index code signature mismatch' end
  return true
 end
 function n:strat_flag(id,key)
  if type(id)~='number' or id<0 or id>255 or id%1~=0 then return nil,'invalid stratagem type' end
  local sig=string.char(0x48,0x89,0x5c,0x24,0x08,0x48,0x8b,0xd9,0x85,0xd2,0x75)
  if io.read(io.base+0x136fc20,#sig)~=sig then return nil,'stratagem function signature mismatch' end
  local insn=io.read(io.base+0x136fc37,7)
  if not insn or insn:byte(2)~=0x8d or (insn:byte(1)~=0x48 and insn:byte(1)~=0x4c)
   or insn:byte(3)%8~=5 or insn:byte(3)>=64 then return nil,'stratagem table signature mismatch' end
  local d=word(insn,3);if d>=0x80000000 then d=d-0x100000000 end
  local addr=io.ptr(io.base+0x136fc37+7+d+id*8)
  local info=addr and addr>=65536 and io.read(addr,0xd0)
  if not info or word(info,0)~=id or word(info,4)~=key then return nil,'stratagem type/key mismatch' end
  local debug=io.u64(info,16)
  if not debug or debug<65536 or not io.read(debug,1) then return nil,'stratagem name pointer invalid' end
  return addr+0x80
 end
 return n
end
return Native

end)()
local Diagnostics=(function()
-- Bounded read-only snapshots. No native calls, writes or broad memory scans.
local D={}
function D.capture(io,targets,pass)
 local s,why=io.snapshot()
 if not s then io.emit('KDM_DIAGNOSTIC_UNAVAILABLE '..tostring(why));return false end
 local wanted={}
 for _,t in ipairs(targets)do
  if t.key==0x1e28f118 or t.key==0x71e406e4 or t.key==0x1b8329ab or t.key==0xf5cb7633
   or t.key==0xae5978b1 or t.key==0xd2a83ca7 then
   wanted[t.key]={name=t.name,target=t}
   if t.template_key then wanted[t.template_key]=wanted[t.template_key]or{name='append template'} end
  end
 end
 io.emit(string.format('KDM_DIAGNOSTIC_BEGIN pass=%d count=%d root=0x%X',pass,s.count,s.root))
 for key,entry in pairs(wanted)do
  local found=0
  for off=0,#s.maps-24,24 do
   local map=s.maps:sub(off+1,off+24)
   if io.u32(map,8)==key then
    found=found+1;local index=io.u32(map,0)
    if index and index<s.count then
     local row=io.read(s.root+0x1ce4+index*184,184)
     io.emit(string.format('KDM_RECORD key=%08X position=%d index=%d map24=%s row184=%s',key,off/24,index,io.hex(map),row and io.hex(row)or'UNREADABLE'))
    else io.emit(string.format('KDM_BAD_INDEX key=%08X',key)) end
   end
  end
  io.emit(string.format('KDM_MATCHES key=%08X matches=%d name=%s',key,found,entry.name))
  if entry.target then
   local kit,err=io.inspect(entry.target)
   io.emit(string.format('KDM_KIT key=%08X header64=%s',key,kit and io.hex(kit)or tostring(err)))
  end
 end
 local after=io.snapshot()
 io.emit('KDM_DIAGNOSTIC_END stable='..tostring(after~=nil and after.root==s.root and after.count==s.count)..'; inventory data only, menu visibility unverified')
 return true
end
return D

end)()
local CategoryIndex=(function()
-- Derived from exact-build loaded code: native builder 0x136e6a0,
-- category lookup 0x13720c0, armour menu lookup 0x18d81e2.
local Index={}
local BOUNDS,ENTRIES,ROWS,MAPS=0xd1ce4,0xd1d48,0x1ce4,0xb9ce4
function Index.repair(core,io)
 local ok,why=io.guard();if not ok then return false,why end
 local s,err=core:snapshot();if not s then return false,err end
 local rows=io.read(s.root+ROWS,s.count*184)
 local bounds=io.read(s.root+BOUNDS,100)
 local indices=io.read(s.root+ENTRIES,s.count*4)
 if not rows or not bounds or not indices then return false,'category index unreadable' end
 local u32,le32=io.u32,io.le32
 local indexed=u32(bounds,96)
 if u32(bounds,0)~=0 or indexed>s.count then return false,'category boundaries invalid' end
 local groups={};for kind=0,23 do groups[kind]={}end
 for pos=0,s.count-1 do
  local m=pos*24;local row=pos*184
  -- Native builder's indices are row positions and consumers use mapping positions.
  -- Refuse an unexpected layout rather than reorder any inventory records.
  if u32(s.maps,m)~=pos or u32(rows,row)~=pos
   or u32(s.maps,m+4)~=u32(rows,row+4)or u32(s.maps,m+8)~=u32(rows,row+8)then
   return false,'category row/map alignment mismatch'
  end
  local kind=u32(rows,row+12)
  if not kind or kind>23 then return false,'category type out of range' end
  local g=groups[kind];g[#g+1]=pos
 end
 -- Validate the existing index, including old entries that must be preserved.
 local seen={}
 for kind=0,23 do
  local first,last=u32(bounds,kind*4),u32(bounds,(kind+1)*4)
  if first>last or last>indexed then return false,'category boundaries inconsistent' end
  for n=first,last-1 do
   local pos=u32(indices,n*4)
   if not pos or pos>=s.count or seen[pos]or u32(rows,pos*184+12)~=kind then
    return false,'existing category membership invalid'
   end
   seen[pos]=true
  end
 end
 local newbounds,newindices={},{};local n=0
 for kind=0,23 do
  newbounds[#newbounds+1]=le32(n)
  for _,pos in ipairs(groups[kind])do newindices[#newindices+1]=le32(pos);n=n+1 end
 end
 newbounds[#newbounds+1]=le32(n)
 local nb,ni=table.concat(newbounds),table.concat(newindices)
 if nb==bounds and ni==indices then return true,'current ('..n..' entries)' end
 if io.read(s.root+ROWS,#rows)~=rows or io.read(s.root+MAPS,#s.maps)~=s.maps then
  return false,'inventory changed during category rebuild'
 end
 local changes={}
 if ni~=indices then changes[#changes+1]={addr=s.root+ENTRIES,old=indices,new=ni}end
 if nb~=bounds then changes[#changes+1]={addr=s.root+BOUNDS,old=bounds,new=nb}end
 local done,msg=core:transaction(s,changes)
 return done,msg or ('rebuilt '..indexed..' -> '..n..' entries; ownership unchanged')
end
return Index

end)()
local WEAPONS={
 {name="R-4 Hyena",hi=3849937749,lo=2835179488,template_key=3866352840,category=1},
 {name="LAS-22 Shear",key=2112173638,hi=2117158309,lo=3131357512,template_key=3866352840,category=1},
 {name="P-41 Ombudsman",hi=3185701459,lo=1115697165,template_hi=98887106,template_lo=3681436834},
 {name="G-11 Caltrops",hi=694738618,lo=1835806473,template_hi=1290398391,template_lo=2242354043},
 {name="R-2124 Constitution",hi=2071323923,lo=805129382,template_key=3866352840,category=1},
}
local STRATS={
 {name="Eagle Gas Airstrike",id=126,key=4196275240,record_key=2961949068},
 {name="M-103 Supply FRV",id=26,key=2636699686,record_key=2996892424},
 {name="TD-110 Maelstrom",id=50,key=460870572,record_key=2237630340},
 {name="M-104 Incinerator FRV",id=135,key=2846457047,record_key=3657826519},
}
local COSMETICS={
 {name="DP-00 Tactical / Armour",key=1058794522,kind=0,kit_index=23,archive_hi=1032647176,archive_lo=2396348561,body_count=3,allow_append=true,template_key=2342442877,record_key=2943433394},
 {name="DP-00 Tactical / Helmet",key=1481290619,kind=1,kit_index=24,archive_hi=3946386673,archive_lo=1581339135,body_count=1,allow_append=true,template_key=2141363041,record_key=703523490},
 {name="B-22 Model Citizen / Armour",key=3414071094,kind=0,kit_index=39,archive_hi=287332222,archive_lo=3521156600,body_count=3,allow_append=true,template_key=2342442877,record_key=3696494697},
 {name="B-22 Model Citizen / Helmet",key=3964228207,kind=1,kit_index=40,archive_hi=3517160286,archive_lo=3670427306,body_count=1,allow_append=true,template_key=2141363041,record_key=1571461053},
 {name="B-16 Battle-Scarred Veteran / Armour",key=2962098489,kind=0,kit_index=41,archive_hi=149489304,archive_lo=207824274,body_count=3,allow_append=true,template_key=2342442877},
 {name="B-16 Battle-Scarred Veteran / Helmet",key=2511084797,kind=1,kit_index=42,archive_hi=1752577621,archive_lo=1337944646,body_count=1,allow_append=true,template_key=2141363041},
 {name="TR-9 Cavalier of Democracy / Armour",key=2483492566,kind=0,kit_index=60,archive_hi=3226334764,archive_lo=1383999329,body_count=3,allow_append=true,template_key=2342442877,record_key=2712908266},
 {name="TR-9 Cavalier of Democracy / Helmet",key=4004823774,kind=1,kit_index=62,archive_hi=2095849254,archive_lo=1161163720,body_count=1,allow_append=true,template_key=2141363041,record_key=1122513689},
 {name="TR-117 Alpha Commander / Armour",key=2675118910,kind=0,kit_index=67,archive_hi=1587164681,archive_lo=2247141088,body_count=3,allow_append=true,template_key=2342442877,record_key=3066485739},
 {name="TR-117 Alpha Commander / Helmet",key=793893084,kind=1,kit_index=68,archive_hi=2083821220,archive_lo=1757347880,body_count=1,allow_append=true,template_key=2141363041,record_key=1945105139},
 {name="IX-Voidwalker / Helmet",key=1685612430,kind=1,kit_index=69,archive_hi=3802325812,archive_lo=121212318,body_count=1,allow_append=true,template_key=2141363041,record_key=2547900634},
 {name="B-02 Gloom Warden / Helmet",key=1951513251,kind=1,kit_index=70,archive_hi=2015580395,archive_lo=3949848280,body_count=1,allow_append=true,template_key=2141363041},
 {name="TR-7 Ambassador of the Brand / Armour",key=2325051543,kind=0,kit_index=133,archive_hi=2110341219,archive_lo=1581110643,body_count=3,allow_append=true,template_key=2342442877,record_key=495842462},
 {name="TR-40 Gold Eagle / Armour",key=470325800,kind=0,kit_index=142,archive_hi=1165294900,archive_lo=3185288644,body_count=3,allow_append=true,template_key=2342442877,record_key=276679263},
 {name="TR-7 Ambassador of the Brand / Helmet",key=904434511,kind=1,kit_index=144,archive_hi=2697887104,archive_lo=3894396462,body_count=1,allow_append=true,template_key=2141363041,record_key=1967836924},
 {name="TR-40 Gold Eagle / Helmet",key=4191752871,kind=1,kit_index=159,archive_hi=3247858599,archive_lo=4082075900,body_count=1,allow_append=true,template_key=2141363041,record_key=3813318023},
 {name="KDM-500 OUTRIDER / Armour",key=2925099185,kind=0,kit_index=192,archive_hi=1197770917,archive_lo=2250053088,body_count=3,allow_append=true,template_key=2342442877,record_key=3421347422},
 {name="KDM-500 Outrider / Helmet",key=3534240935,kind=1,kit_index=193,archive_hi=483817193,archive_lo=529584669,body_count=1,allow_append=true,template_key=2141363041,record_key=1407130184},
 {name="KDM-763 Pacesetter / Armour",key=505999640,kind=0,kit_index=259,archive_hi=433518175,archive_lo=2800812486,body_count=3,allow_append=true,template_key=2342442877},
 {name="KDM-763 Pacesetter / Helmet",key=1910769380,kind=1,kit_index=260,archive_hi=4054519444,archive_lo=1158672886,body_count=1,allow_append=true,template_key=2141363041},
 {name="KDM-73 Dragoon / Armour",key=461580715,kind=0,kit_index=261,archive_hi=3644310702,archive_lo=1587491361,body_count=3,allow_append=true,template_key=2342442877},
 {name="KDM-73 Dragoon / Helmet",key=4123751987,kind=1,kit_index=262,archive_hi=2294184900,archive_lo=1079231488,body_count=1,allow_append=true,template_key=2141363041},
 {name="TR-62 Knight / Armour",key=1934028230,kind=0,kit_index=289,archive_hi=136584103,archive_lo=852064925,body_count=3,allow_append=true,template_key=2342442877,record_key=2899116161},
 {name="TR-62 Knight / Helmet",key=856924396,kind=1,kit_index=290,archive_hi=4271435113,archive_lo=2553098419,body_count=1,allow_append=true,template_key=2141363041,record_key=2694550156},
 {name="Unreleased Cape / Cape",key=3690580532,kind=2,kit_index=293,archive_hi=1778254319,archive_lo=3213798145,body_count=1,allow_append=true,template_key=865246378,record_key=3690580532},
 {name="Unreleased Cape / Cape",key=2592491111,kind=2,kit_index=303,archive_hi=2368300255,archive_lo=630901283,body_count=1,allow_append=true,template_key=865246378},
 {name="Fallen Hero's Vengeance / Cape",key=865246378,kind=2,kit_index=305,archive_hi=1490801536,archive_lo=1573507977,body_count=1,allow_append=true,template_key=865246378,record_key=865246378},
 {name="Unreleased Cape / Cape",key=2457217350,kind=2,kit_index=310,archive_hi=3523552945,archive_lo=1801652088,body_count=1,allow_append=true,template_key=865246378},
 {name="Unreleased Cape / Cape",key=3881932101,kind=2,kit_index=314,archive_hi=2408221691,archive_lo=696782753,body_count=1,allow_append=true,template_key=865246378},
 {name="Protector of the Heart / Cape",key=2002245864,kind=2,kit_index=315,archive_hi=2392479574,archive_lo=2466967261,body_count=1,allow_append=true,template_key=865246378,record_key=2002245864},
 {name="Emblem of Freedom / Cape",key=463066946,kind=2,kit_index=316,archive_hi=2947285411,archive_lo=784094650,body_count=1,allow_append=true,template_key=865246378,record_key=463066946},
 {name="Reckoning's Cheer / Cape",key=3076249017,kind=2,kit_index=319,archive_hi=2807149773,archive_lo=328928947,body_count=1,allow_append=true,template_key=865246378,record_key=3076249017},
 {name="Unreleased Cape / Cape",key=3667835749,kind=2,kit_index=320,archive_hi=216158098,archive_lo=408825979,body_count=1,allow_append=true,template_key=865246378},
 {name="United in Equality / Cape",key=1838911009,kind=2,kit_index=322,archive_hi=1792867061,archive_lo=1961924803,body_count=1,allow_append=true,template_key=865246378,record_key=1838911009},
 {name="Against the Tyrant Cloud (inferred label) / Cape",key=1917397047,kind=2,kit_index=323,archive_hi=629382893,archive_lo=67133499,body_count=1,allow_append=true,template_key=865246378,record_key=1917397047},
 {name="Veridical Ideology / Cape",key=4028901518,kind=2,kit_index=324,archive_hi=2099341247,archive_lo=4092314581,body_count=1,allow_append=true,template_key=865246378,record_key=4028901518},
 {name="Message of Morale / Cape",key=3890208935,kind=2,kit_index=329,archive_hi=2389483846,archive_lo=245321061,body_count=1,allow_append=true,template_key=865246378,record_key=3890208935},
 {name="Ingress-81 / Cape",key=1902399433,kind=2,kit_index=331,archive_hi=4200242540,archive_lo=2339239898,body_count=1,allow_append=true,template_key=865246378,record_key=1902399433},
 {name="Eye of Freedom / Cape",key=582381095,kind=2,kit_index=393,archive_hi=672417350,archive_lo=4084293277,body_count=1,allow_append=true,template_key=865246378,record_key=582381095},
 {name="Eye of Liberty / Cape",key=453241154,kind=2,kit_index=394,archive_hi=3079676520,archive_lo=1659211903,body_count=1,allow_append=true,template_key=865246378,record_key=453241154},
 {name="Unreleased Cape / Cape",key=1675418984,kind=2,kit_index=400,archive_hi=465542919,archive_lo=866537833,body_count=1,allow_append=true,template_key=865246378},
 {name="SC-37 Legionnaire / Armour [hidden kit C2A2375F]",key=3265410911,kind=0,kit_index=81,archive_hi=3589823669,archive_lo=4021570770,body_count=3,allow_append=true,template_key=2342442877,record_key=2304644113},
 {name="SC-37 Legionnaire / Armour [hidden kit 9BC153C0]",key=2613138368,kind=0,kit_index=83,archive_hi=3341392019,archive_lo=1797097634,body_count=3,allow_append=true,template_key=2342442877,record_key=2076675618},
 {name="SC-37 Legionnaire (variant) / Helmet [hidden kit E406CED0]",key=3825651408,kind=1,kit_index=84,archive_hi=3139685289,archive_lo=3075624081,body_count=1,allow_append=true,template_key=2141363041,record_key=1180262890},
 {name="SC-37 Legionnaire (variant) / Helmet [hidden kit 44D93620]",key=1155085856,kind=1,kit_index=86,archive_hi=226215179,archive_lo=1113333162,body_count=1,allow_append=true,template_key=2141363041,record_key=2194213002},
 {name="SC-30 Trailblazer Scout / Armour [hidden kit 756159E4]",key=1969314276,kind=0,kit_index=97,archive_hi=3878350592,archive_lo=1848809363,body_count=3,allow_append=true,template_key=2342442877},
 {name="SC-30 Trailblazer Scout / Helmet [hidden kit 7FA29B61]",key=2141363041,kind=1,kit_index=99,archive_hi=2889696503,archive_lo=207594043,body_count=1,allow_append=true,template_key=2141363041,record_key=2141363041},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 9B5BC520]",key=2606482720,kind=1,kit_index=100,archive_hi=1108652185,archive_lo=2904840381,body_count=1,allow_append=true,template_key=2141363041},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit DB7DB6AA]",key=3682449066,kind=1,kit_index=101,archive_hi=2933949674,archive_lo=3567088962,body_count=1,allow_append=true,template_key=2141363041,record_key=3682449066},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 8507BB35]",key=2231876405,kind=1,kit_index=103,archive_hi=3438060159,archive_lo=3619451950,body_count=1,allow_append=true,template_key=2141363041,record_key=2231876405},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 020A57A8]",key=34232232,kind=1,kit_index=104,archive_hi=4002270341,archive_lo=226130235,body_count=1,allow_append=true,template_key=2141363041,record_key=34232232},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 52045A9B]",key=1376017051,kind=1,kit_index=105,archive_hi=354667867,archive_lo=421840994,body_count=1,allow_append=true,template_key=2141363041,record_key=1376017051},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 782087B2]",key=2015397810,kind=1,kit_index=106,archive_hi=138781019,archive_lo=3140607174,body_count=1,allow_append=true,template_key=2141363041,record_key=2015397810},
 {name="B-24 Enforcer / Armour [hidden kit 8B9ED77D]",key=2342442877,kind=0,kit_index=107,archive_hi=2022568337,archive_lo=1351702537,body_count=3,allow_append=true,template_key=2342442877,record_key=2342442877},
 {name="B-24 Enforcer / Armour [hidden kit AC0ADECD]",key=2886393549,kind=0,kit_index=109,archive_hi=409401186,archive_lo=3297990890,body_count=3,allow_append=true,template_key=2342442877,record_key=2886393549},
 {name="FS-05 Marksman / Armour [hidden kit 076D9AAD]",key=124623533,kind=0,kit_index=111,archive_hi=835740753,archive_lo=2694216177,body_count=3,allow_append=true,template_key=2342442877},
 {name="FS-05 Marksman / Armour [hidden kit 58DBDACD]",key=1490803405,kind=0,kit_index=112,archive_hi=3433826903,archive_lo=2896408210,body_count=3,allow_append=true,template_key=2342442877,record_key=671123458},
 {name="FS-05 Marksman / Helmet [hidden kit 0F41A67E]",key=255960702,kind=1,kit_index=114,archive_hi=3835812435,archive_lo=1269596558,body_count=1,allow_append=true,template_key=2141363041,record_key=255960702},
 {name="FS-05 Marksman / Helmet [hidden kit 7B6406DA]",key=2070152922,kind=1,kit_index=115,archive_hi=3235646076,archive_lo=2412073492,body_count=1,allow_append=true,template_key=2141363041,record_key=3058335410},
 {name="FS-05 Marksman / Helmet [hidden kit 36456057]",key=910516311,kind=1,kit_index=116,archive_hi=2148068218,archive_lo=248298689,body_count=1,allow_append=true,template_key=2141363041,record_key=910516311},
 {name="FS-05 Marksman / Helmet [hidden kit D915A671]",key=3642074737,kind=1,kit_index=118,archive_hi=3917520839,archive_lo=616470982,body_count=1,allow_append=true,template_key=2141363041,record_key=3642074737},
 {name="FS-05 Marksman / Helmet [hidden kit E417AE7B]",key=3826757243,kind=1,kit_index=119,archive_hi=2255901022,archive_lo=2066804029,body_count=1,allow_append=true,template_key=2141363041,record_key=3826757243},
 {name="FS-05 Marksman / Helmet [hidden kit 4452E375]",key=1146282869,kind=1,kit_index=120,archive_hi=237110597,archive_lo=1126970998,body_count=1,allow_append=true,template_key=2141363041,record_key=1146282869},
 {name="FS-05 Marksman / Helmet [hidden kit 0C0AF708]",key=202045192,kind=1,kit_index=121,archive_hi=1387674437,archive_lo=3349601196,body_count=1,allow_append=true,template_key=2141363041,record_key=202045192},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit 5C1A87D2]",key=1545242578,kind=1,kit_index=125,archive_hi=2314701972,archive_lo=1136656028,body_count=1,allow_append=true,template_key=2141363041,record_key=1545242578},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit 68AA2D85]",key=1755983237,kind=1,kit_index=126,archive_hi=1997498211,archive_lo=186331794,body_count=1,allow_append=true,template_key=2141363041,record_key=1755983237},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit 126F9CB6]",key=309304502,kind=1,kit_index=128,archive_hi=358388545,archive_lo=2402052722,body_count=1,allow_append=true,template_key=2141363041,record_key=309304502},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit 0542E6F1]",key=88270577,kind=1,kit_index=129,archive_hi=4166678506,archive_lo=3465214586,body_count=1,allow_append=true,template_key=2141363041,record_key=88270577},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit B6A2F46A]",key=3064132714,kind=1,kit_index=130,archive_hi=809702328,archive_lo=2223238983,body_count=1,allow_append=true,template_key=2141363041,record_key=3064132714},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit A2F4F328]",key=2733962024,kind=1,kit_index=131,archive_hi=2913716702,archive_lo=3144559612,body_count=1,allow_append=true,template_key=2141363041,record_key=2733962024},
 {name="B-01 Tactical / Armour [hidden kit 250FD6C1]",key=621795009,kind=0,kit_index=132,archive_hi=3206678783,archive_lo=1856778051,body_count=3,allow_append=true,template_key=2342442877,record_key=3935965925},
 {name="B-01 Tactical / Armour [hidden kit 1D0E3431]",key=487470129,kind=0,kit_index=134,archive_hi=3775059454,archive_lo=1759604319,body_count=3,allow_append=true,template_key=2342442877,record_key=2053442827},
 {name="B-01 Tactical / Armour [hidden kit 708451E9]",key=1887719913,kind=0,kit_index=135,archive_hi=3515097195,archive_lo=772407656,body_count=3,allow_append=true,template_key=2342442877,record_key=2394592819},
 {name="B-01 Tactical / Armour [hidden kit D59566D5]",key=3583338197,kind=0,kit_index=140,archive_hi=3026204229,archive_lo=2569010486,body_count=3,allow_append=true,template_key=2342442877,record_key=2905408536},
 {name="B-01 Tactical / Armour [hidden kit 1369B95B]",key=325695835,kind=0,kit_index=141,archive_hi=1850493196,archive_lo=4170930748,body_count=3,allow_append=true,template_key=2342442877,record_key=2553569133},
 {name="B-01 Tactical / Helmet [hidden kit 2180EB8D]",key=562097037,kind=1,kit_index=143,archive_hi=3148842524,archive_lo=3948424950,body_count=1,allow_append=true,template_key=2141363041,record_key=529287881},
 {name="B-01 Tactical / Helmet [hidden kit 4F6CCD6C]",key=1332530540,kind=1,kit_index=145,archive_hi=2306375798,archive_lo=1084519576,body_count=1,allow_append=true,template_key=2141363041,record_key=1332530540},
 {name="B-01 Tactical / Helmet [hidden kit 40A7D694]",key=1084741268,kind=1,kit_index=146,archive_hi=3762888372,archive_lo=4214586666,body_count=1,allow_append=true,template_key=2141363041,record_key=2694161121},
 {name="TBD / Helmet [hidden kit 8CE73DAE]",key=2363964846,kind=1,kit_index=147,archive_hi=539686219,archive_lo=1340464517,body_count=1,allow_append=true,template_key=2141363041,record_key=4100314171},
 {name="B-01 Tactical / Helmet [hidden kit 69B2EC39]",key=1773333561,kind=1,kit_index=148,archive_hi=3858667789,archive_lo=2102840622,body_count=1,allow_append=true,template_key=2141363041,record_key=1773333561},
 {name="B-01 Tactical / Helmet [hidden kit EE7019ED]",key=4000324077,kind=1,kit_index=153,archive_hi=668106260,archive_lo=3035000656,body_count=1,allow_append=true,template_key=2141363041,record_key=1483434009},
 {name="B-01 Tactical / Helmet [hidden kit E207C84A]",key=3792160842,kind=1,kit_index=154,archive_hi=1020279313,archive_lo=1503039157,body_count=1,allow_append=true,template_key=2141363041,record_key=3792160842},
 {name="B-01 Tactical / Helmet [hidden kit 10707D29]",key=275807529,kind=1,kit_index=155,archive_hi=1055415311,archive_lo=1152225996,body_count=1,allow_append=true,template_key=2141363041,record_key=275807529},
 {name="B-01 Tactical / Helmet [hidden kit FDBF4741]",key=4257171265,kind=1,kit_index=156,archive_hi=849782646,archive_lo=477151643,body_count=1,allow_append=true,template_key=2141363041,record_key=2067677478},
 {name="B-01 Tactical / Helmet [hidden kit B638F3C4]",key=3057185732,kind=1,kit_index=157,archive_hi=3439904546,archive_lo=593393100,body_count=1,allow_append=true,template_key=2141363041,record_key=3057185732},
 {name="B-01 Tactical / Helmet [hidden kit 843DF174]",key=2218652020,kind=1,kit_index=158,archive_hi=2587341024,archive_lo=3743448160,body_count=1,allow_append=true,template_key=2141363041,record_key=2218652020},
 {name="Prosperous Green / Cape",key=3822047995,kind=2,kit_index=318,archive_hi=1138998390,archive_lo=1419351956,body_count=1,allow_append=true,template_key=865246378,record_key=3822047995},
 {name="Red Planet's Memory / Cape",key=2632342951,kind=2,kit_index=325,archive_hi=3334997962,archive_lo=342846618,body_count=1,allow_append=true,template_key=865246378,record_key=2632342951},
 {name="Proud Gold / Cape",key=4112773733,kind=2,kit_index=326,archive_hi=3680123751,archive_lo=731725265,body_count=1,allow_append=true,template_key=865246378,record_key=4112773733},
 {name="Patriot Blue / Cape",key=114199832,kind=2,kit_index=327,archive_hi=1115173758,archive_lo=2959508638,body_count=1,allow_append=true,template_key=865246378,record_key=114199832},
 {name="Scraps of Sovereignty / Cape",key=4014974242,kind=2,kit_index=341,archive_hi=2112209738,archive_lo=2212817321,body_count=1,allow_append=true,template_key=865246378,record_key=4014974242},

 -- Additional named cape targets identified in the user screenshots.
 {name="Agent of Oblivion / Cape",key=4111053667,kind=2,kit_index=300,archive_hi=1600514194,archive_lo=1241225098,body_count=1,allow_append=true,template_key=865246378,record_key=4111053667},
 {name="Beacon of Mercy / Cape",key=1695626205,kind=2,kit_index=301,archive_hi=171779887,archive_lo=367145536,body_count=1,allow_append=true,template_key=865246378},
 {name="Bugslayer / Cape",key=2020619131,kind=2,kit_index=330,archive_hi=678120188,archive_lo=3843483101,body_count=1,allow_append=true,template_key=865246378},
 {name="Vector of Victory / Cape",key=3201849683,kind=2,kit_index=372,archive_hi=1030166427,archive_lo=2552704199,body_count=1,allow_append=true,template_key=865246378},
 {name="Podium of Prosperity / Cape",key=340532591,kind=2,kit_index=373,archive_hi=1898434015,archive_lo=3403335577,body_count=1,allow_append=true,template_key=865246378},
 {name="Defender of our dream / Cape",key=1113633420,kind=2,kit_index=375,archive_hi=724081672,archive_lo=785894094,body_count=1,allow_append=true,template_key=865246378,record_key=1113633420},
 {name="Tyranny's Bane / Cape",key=3058055083,kind=2,kit_index=395,archive_hi=628588342,archive_lo=1380686520,body_count=1,allow_append=true,template_key=865246378},
 {name="Agent of Oblivion / Cape",key=391288265,kind=2,kit_index=396,archive_hi=3037730311,archive_lo=2382213057,body_count=1,allow_append=true,template_key=865246378},

 -- Unnamed screenshot candidates; exact build metadata, visual match unconfirmed.
 {name="TBD / Armour",key=2669749508,kind=0,kit_index=73,archive_hi=1530440574,archive_lo=548708849,body_count=3,allow_append=true,template_key=2342442877},
 {name="TBD / Helmet",key=2776529082,kind=1,kit_index=74,archive_hi=3374736250,archive_lo=3152079601,body_count=1,allow_append=true,template_key=2141363041},
 {name="Unidentified kit / Armour",key=323545031,kind=0,kit_index=206,archive_hi=555019256,archive_lo=1251441740,body_count=3,allow_append=true,template_key=2342442877,record_key=2806949459},

 -- Unidentified cape candidates; one may be the empty/no-cape model.
 {name="Unidentified kit / Cape",key=199989180,kind=2,kit_index=299,archive_hi=3105026548,archive_lo=4079046279,body_count=1,allow_append=true,template_key=865246378},
 {name="Unidentified kit / Cape",key=1513263450,kind=2,kit_index=317,archive_hi=1198184012,archive_lo=2339479523,body_count=1,allow_append=true,template_key=865246378,record_key=1513263450},
 {name="Unidentified kit / Cape",key=534865247,kind=2,kit_index=321,archive_hi=1523003314,archive_lo=2673608503,body_count=1,allow_append=true,template_key=865246378},
 {name="Unidentified kit / Cape",key=2901358327,kind=2,kit_index=328,archive_hi=734346287,archive_lo=1124055989,body_count=1,allow_append=true,template_key=865246378},
 {name="Unidentified kit / Cape",key=1588662851,kind=2,kit_index=340,archive_hi=1640141849,archive_lo=4117792194,body_count=1,allow_append=true,template_key=865246378},
 {name="Unidentified kit / Cape",key=193259933,kind=2,kit_index=410,archive_hi=1219870751,archive_lo=3639782500,body_count=1,allow_append=true,template_key=865246378},
}
local function classes()
  local p=ptr(class_slot)
  -- The supplied Shear source locates classification-range metadata at +0x1b28.
  return p and read(p,0x1b20)
end
local function class(hi,lo)
  local b=classes(); if not b then return nil,nil,'classification table unavailable' end
  local key,category
  for off=0,#b-32,32 do
    if u32(b,off)~=0 and u32(b,off+8)==lo and u32(b,off+12)==hi then
      if key then return nil,nil,'duplicate model classification' end
      key,category=u32(b,off),u32(b,off+16)
    end
  end
  return key,category,'model missing from this build'
end
local native=Native.new({read=read,ptr=ptr,u32=u32,u64=u64at,base=base})
local function strat_flag(id,key)return native:strat_flag(id,key)end
local core=Core.new({journal=journal,read=read,write=write,writable=writable,
  root=function()return ptr(item_slot)end,class=class,strat_flag=strat_flag,kit=function(t)return native:kit(t)end})
local next_check,observed_root,stable_root,discovery_root=0,nil,nil,nil
local diagnostic_root,diagnostic_time,diagnostic_pass=nil,0,0
local statuses={}
local function status(name,message)
  if statuses[name]~=message then statuses[name]=message;emit(name..': '..message) end
end
local function inventory(s)
  local b=classes();if not b then return end
  emit('DISCOVERY_BEGIN: unregistered classification entries; identifiers only, NOT proof of usable equipment')
  local registered={}
  for off=0,#s.maps-24,24 do registered[u32(s.maps,off+4)]=true end
  local n=0
  for off=0,#b-32,32 do
    local key,lo,hi,category=u32(b,off),u32(b,off+8),u32(b,off+12),u32(b,off+16)
    if key>65535 and category>=1 and category<=6 and not registered[key] and (lo~=0 or hi~=0) then
      emit(string.format('UNREGISTERED class=%d key=0x%08X model=%08X:%08X category=%d',off/32,key,hi,lo,category))
      n=n+1
    end
  end
  emit('DISCOVERY_END candidates='..n..'; unsupported entries left unchanged')
end
local function tick()
  if now()<next_check then return end;next_check=now()+2
  local s,why=core:snapshot()
  if not s then
    observed_root,stable_root=nil,nil
    status('registry',why);public.status='waiting';return
  end
  if observed_root~=s.root then
    observed_root=s.root;stable_root=nil;statuses={}
    status('registry','waiting for stable pointer');return
  end
  if stable_root~=s.root then
    stable_root=s.root;emit(string.format('REGISTRY_READY root=0x%X count=%d',s.root,s.count))
  end
  if discovery_root~=s.root then inventory(s);discovery_root=s.root end
  local success=0
  for _,t in ipairs(WEAPONS) do
    if core.fatal then break end
    local ok,message=core:weapon(t);status(t.name,(ok and 'OK: ' or 'WAIT/SKIP: ')..tostring(message))
    if ok then success=success+1 end
  end
  for _,t in ipairs(STRATS) do
    if core.fatal then break end
    local ok,message=core:stratagem(t);status(t.name,(ok and 'OK: ' or 'WAIT/SKIP: ')..tostring(message))
    if ok then success=success+1 end
  end
  native:begin()
  local cosmetic_snapshot=core:snapshot()
  for _,t in ipairs(COSMETICS) do
    if core.fatal then break end
    if not cosmetic_snapshot then cosmetic_snapshot=core:snapshot() end
    local before=cosmetic_snapshot and cosmetic_snapshot.count
    local ok,message=core:catalogue_cosmetic(t,cosmetic_snapshot)
    if ok and not t.record_key then message='inventory state verified; armoury visibility UNCONFIRMED' end
    status(string.format('%s [%08X]',t.name,t.key),(ok and 'OK: ' or 'WAIT/SKIP: ')..tostring(message))
    if ok then success=success+1 end
    if not ok or (cosmetic_snapshot and cosmetic_snapshot.count~=before) then cosmetic_snapshot=nil end
  end
  local index_ok,index_message=CategoryIndex.repair(core,{read=read,u32=u32,le32=le32,guard=function()return native:category_guard()end})
  status('armoury category index',(index_ok and 'OK: ' or 'WAIT/SKIP: ')..tostring(index_message))
  public.status=core.fatal and 'disabled: transaction ownership lost' or ('inventory states verified (NOT menu visibility): '..success..'/'..(#WEAPONS+#STRATS+#COSMETICS))
  status('summary',public.status)
  if diagnostic_root~=s.root then diagnostic_root=s.root;diagnostic_pass=0;diagnostic_time=now() end
  if diagnostic_pass<2 and now()>=diagnostic_time then
    diagnostic_pass=diagnostic_pass+1;diagnostic_time=now()+60
    local ok,err=pcall(function()
      Diagnostics.capture({snapshot=function()return core:snapshot()end,read=read,u32=u32,hex=hex,
        emit=emit,inspect=function(t)return native:inspect_kit(t)end},COSMETICS,diagnostic_pass)
    end)
    if not ok then emit('KDM_DIAGNOSTIC_ERROR '..tostring(err)) end
  end
  local custom=rawget(_G,'LAS22ShearCustomizationExperimentM4')
  status('Shear customization',custom and custom.status or 'waiting for customization component')
end
local previous=rawget(_G,'update')
local stopped=false
rawset(_G,'update',function(...)
  if not stopped then
    local ok,err=pcall(tick)
    if not ok or core.fatal then
      stopped=true;finish('disabled: '..tostring(err or 'unsafe transaction; restart required'))
    end
  end
  return previous(...)
end)
local previous_shutdown=rawget(_G,'shutdown')
rawset(_G,'shutdown',function(...)
  stopped=true
  local ok,restored,skipped=pcall(journal.run)
  if ok then
    emit('SHUTDOWN_RESTORE writes undone='..tostring(restored)..' skipped='..tostring(skipped)..'; original registry restored before engine teardown')
    public.status='shutdown: original registry restored'
  else
    emit('SHUTDOWN_RESTORE_ERROR '..tostring(restored))
  end
  if previous_shutdown then return previous_shutdown(...) end
end)
public.status='waiting'
emit('LOADED v'..VERSION..'; loader='..tostring(loader.version)..'; verified build 25480438; automatic unlocks enabled')
emit('No Mod Options Menu dependency. Shear customization is included as a companion component; illumination flare is excluded. Cosmetic category index repair enabled; in-game confirmation pending.')
return public
end -- initialize
local initialized,result=pcall(initialize)
if not initialized then finish('disabled during initialization: '..tostring(result)) end
return public
