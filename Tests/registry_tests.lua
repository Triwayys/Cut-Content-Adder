local ffi=require('ffi')
local Core=assert(loadfile('Source/registry_core.lua') or loadfile('build/Source/registry_core.lua'))()
local u32,le32=Core.u32,Core.le32
local tests=0
local function check(name,fn)
  fn();tests=tests+1;print('PASS '..name)
end
local function fixture(count)
  local f={root=0x100000,writes=0,models={},log={}}
  local mem=ffi.new('uint8_t[?]',0x200000)
  f.mem=mem
  function f.read(a,n)
    local off=a-0x100000
    if off<0 or off+n>0x200000 then return nil end
    return ffi.string(mem+off,n)
  end
  function f.put(a,b)ffi.copy(mem+(a-0x100000),b,#b)end
  function f.word(a,n)f.put(a,le32(n))end
  f.word(f.root+0x1ce0,count or 2928);f.word(f.root+0xddcf8,12)
  function f.record(position,index,key,status)
    local a=f.root+0x1ce4+index*184
    f.word(a,index);f.word(a+4,key);f.word(a+8,key);f.word(a+12,key==301 and 10 or 1);f.word(a+20,status or 2)
    f.word(a+176,0xabcdef01) -- ensure unrelated metadata remains intact
    local m=f.root+0xb9ce4+position*24
    f.word(m,index);f.word(m+4,key);f.word(m+8,key)
  end
  f.record(10,226,101,2);f.record(11,100,102,2);f.record(12,200,103,2)
  f.models['1:1']={201,1};f.models['2:2']={202,2};f.models['3:3']={203,3}
  f.models['11:11']={101,1};f.models['12:12']={102,2};f.models['13:13']={103,3}
  f.targets={
    {hi=1,lo=1,template_hi=11,template_lo=11},
    {hi=2,lo=2,template_hi=12,template_lo=12},
    {hi=3,lo=3,template_hi=13,template_lo=13}}
  f.flag=f.root+0x110000;f.put(f.flag,string.char(0x80))
  f.io={read=f.read,root=function()return f.root end,
    writable=function(a,n)return not f.readonly end,
    class=function(hi,lo)local v=f.models[hi..':'..lo];if v then return v[1],v[2] end end,
    strat_flag=function(id)if f.no_flag then return nil,'missing flag' end;return f.flag end,
    write=function(a,b)
      f.writes=f.writes+1
      if f.fail==a then f.fail=nil;f.put(a,b:sub(1,math.max(1,math.floor(#b/2))));return false end
      f.put(a,b)
      if f.after_write then f.after_write(a,b) end
      return true
    end}
  f.core=Core.new(f.io)
  function f.count()return u32(f.read(f.root+0x1ce0,4),0)end
  return f
end
check('packaged Hyena catalogue resolves and unlocks existing or absent records',function()
 local h=assert(io.open('Source/runtime_suffix.lua','r'));local source=h:read('*a');h:close()
 local catalogue=assert(loadstring(source:match('(local WEAPONS=.-)local STRATS=')..'return WEAPONS'))()
 local t=catalogue[1];assert(t.name=='R-4 Hyena' and t.hi==0xe5796355 and t.lo==0xa8fd67e0)
 for _,exists in ipairs({false,true}) do
  local f=fixture();f.models[t.hi..':'..t.lo]={201,1}
  f.record(10,226,t.template_key,2)
  if exists then f.record(13,300,201,1) end
  assert(f.core:weapon(t));assert(f.count()==(exists and 2928 or 2929))
  local writes=f.writes;assert(f.core:weapon(t));assert(f.writes==writes)
 end
end)
check('three appends use fresh counts and preserve metadata',function()
 local f=fixture();for _,t in ipairs(f.targets)do assert(f.core:weapon(t))end
 assert(f.count()==2931)
 for i=0,2 do local b=f.read(f.root+0x1ce4+(2928+i)*184,184)
  assert(u32(b,4)==201+i and u32(b,176)==0xabcdef01)end
end)
check('non-default registry count accepted',function()
 local f=fixture(3000);assert(f.core:weapon(f.targets[1]));assert(f.count()==3001)
end)
check('mapping position need not equal record index',function()
 local f=fixture();assert(f.core:weapon(f.targets[1]));assert(f.count()==2929)
end)
check('already registered unlocked item is idempotent',function()
 local f=fixture();assert(f.core:weapon(f.targets[1]));local w=f.writes
 assert(f.core:weapon(f.targets[1]));assert(f.writes==w and f.count()==2929)
end)
check('existing locked equipment enabled without duplicate',function()
 local f=fixture();f.record(13,300,201,1);assert(f.core:weapon(f.targets[1]))
 assert(f.count()==2928 and u32(f.read(f.root+0x1ce4+300*184+20,4),0)==2)
end)
check('owned state four retained',function()
 local f=fixture();f.record(13,300,201,4);assert(f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('unknown status rejected without writes',function()
 local f=fixture();f.record(13,300,201,99);assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('missing model rejected',function()
 local f=fixture();f.models['1:1']=nil;assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('model/key mismatch rejected',function()
 local f=fixture();f.targets[1].key=999;assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('category mismatch rejected',function()
 local f=fixture();f.models['1:1'][2]=9;assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('duplicate mappings rejected',function()
 local f=fixture();f.record(13,300,201,1);f.record(14,301,201,1)
 assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('record identity mismatch rejected',function()
 local f=fixture();f.word(f.root+0x1ce4+226*184+4,999)
 assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('occupied append slot preserved',function()
 local f=fixture();f.word(f.root+0x1ce4+2928*184,999)
 assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('capacity exhausted rejected',function()
 local f=fixture(4096);assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('unready registry leaves memory untouched',function()
 local f=fixture();f.word(f.root+0xddcf8,0);assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('read-only memory leaves memory untouched',function()
 local f=fixture();f.readonly=true;assert(not f.core:weapon(f.targets[1]));assert(f.writes==0)
end)
check('partial mapping write rolled back and retry succeeds',function()
 local f=fixture();f.fail=f.root+0xb9ce4+2928*24
 assert(not f.core:weapon(f.targets[1]));assert(f.count()==2928 and not f.core.fatal)
 assert(f.read(f.root+0x1ce4+2928*184,184)==string.rep('\0',184))
 assert(f.read(f.root+0xb9ce4+2928*24,24)==string.rep('\0',24))
 assert(f.core:weapon(f.targets[1]))
end)
check('count publish failure rolled back',function()
 local f=fixture();f.fail=f.root+0x1ce0
 assert(not f.core:weapon(f.targets[1]));assert(f.count()==2928 and not f.core.fatal)
 assert(f.read(f.root+0x1ce4+2928*184,184)==string.rep('\0',184))
end)
check('root change during transaction stops further writes',function()
 local f=fixture();f.after_write=function()f.root=0x200000 end
 assert(not f.core:weapon(f.targets[1]));assert(f.core.fatal and f.writes==1)
end)
check('external count change stops rollback into competing data',function()
 local f=fixture();f.after_write=function()f.word(f.root+0x1ce0,3001)end
 assert(not f.core:weapon(f.targets[1]));assert(f.core.fatal and f.writes==1)
end)
check('stratagem enables both fields and preserves other flag bits',function()
 local f=fixture();f.record(13,300,301,1)
 assert(f.core:stratagem({key=301,id=5}));assert(f.read(f.flag,1):byte()==0x82)
 assert(u32(f.read(f.root+0x1ce4+300*184+20,4),0)==2)
end)
check('selection flag reset is repaired even when registry unlocked',function()
 local f=fixture();f.record(13,300,301,2);assert(f.core:stratagem({key=301,id=5}))
 f.put(f.flag,string.char(0x80));assert(f.core:stratagem({key=301,id=5}));assert(f.read(f.flag,1):byte()==0x82)
end)
check('registry status reset is repaired',function()
 local f=fixture();f.record(13,300,301,1);f.put(f.flag,string.char(0x82))
 assert(f.core:stratagem({key=301,id=5}));assert(u32(f.read(f.root+0x1ce4+300*184+20,4),0)==2)
end)
check('absent stratagem record does not change selection flag',function()
 local f=fixture();assert(not f.core:stratagem({key=301,id=5}));assert(f.writes==0)
end)
check('stratagem table failure leaves registry unchanged',function()
 local f=fixture();f.record(13,300,301,1);f.no_flag=true
 assert(not f.core:stratagem({key=301,id=5}));assert(f.writes==0)
end)
check('stratagem partial failure rolls back both fields',function()
 local f=fixture();f.record(13,300,301,1);f.fail=f.root+0x1ce4+300*184+20
 assert(not f.core:stratagem({key=301,id=5}));assert(f.read(f.flag,1):byte()==0x80)
 assert(u32(f.read(f.root+0x1ce4+300*184+20,4),0)==1)
end)
check('same-pointer registry reset can be reapplied',function()
 local f=fixture();assert(f.core:weapon(f.targets[1]))
 f.put(f.root+0x1ce4+2928*184,string.rep('\0',184));f.put(f.root+0xb9ce4+2928*24,string.rep('\0',24))
 f.word(f.root+0x1ce0,2928);assert(f.core:weapon(f.targets[1]));assert(f.count()==2929)
end)

local cape_fixture=assert(loadfile('Tests/live_cape_fixture.lua'))()
local function unhex(h)return(h:gsub('..',function(c)return string.char(tonumber(c,16))end))end
for _,v in ipairs(cape_fixture)do
 check('cape live identity and all accepted states: '..v.name,function()
  for _,state in ipairs({0,1,2,4})do
   local f=fixture();local row=unhex(v.row);local map=unhex(v.map)
   f.put(f.root+0x1ce4+v.index*184,row);f.put(f.root+0xb9ce4+v.index*24,map)
   f.word(f.root+0x1ce4+v.index*184+20,state)
   local before=f.read(f.root,0x200000)
   local expected=before
   if state==0 or state==1 then
    local offset=0x1ce4+v.index*184+20
    expected=before:sub(1,offset)..le32(2)..before:sub(offset+5)
   end
   assert(f.core:cape(v));assert(f.read(f.root,0x200000)==expected,'unrelated bytes changed')
   local w=f.writes;assert(f.core:cape(v));assert(f.writes==w)
  end
 end)
end
check('missing cape never appends',function()
 local f=fixture();assert(not f.core:cape({key=999}));assert(f.writes==0 and f.count()==2928)
end)
check('weapon with cape key is rejected',function()
 local f=fixture();assert(not f.core:cape({key=101}));assert(f.writes==0)
end)
check('cape unknown state and duplicate identity are rejected',function()
 local f=fixture();f.record(20,400,901,99);f.word(f.root+0x1ce4+400*184+12,3)
 assert(not f.core:cape({key=901}));assert(f.writes==0)
 f.word(f.root+0x1ce4+400*184+20,1);f.record(21,401,901,1)
 assert(not f.core:cape({key=901}));assert(f.writes==0)
end)
check('cape partial write rollback preserves surrounding data',function()
 local f=fixture();f.record(20,400,901,1);f.word(f.root+0x1ce4+400*184+12,3)
 local before=f.read(f.root,0x200000);f.fail=f.root+0x1ce4+400*184+20
 assert(not f.core:cape({key=901}));assert(f.read(f.root,0x200000)==before)
end)

local preorder_fixture=assert(loadfile('Tests/live_preorder_fixture.lua'))()
local function preorder_record(f,v)
 f.put(f.root+0x1ce4+v.index*184,unhex(v.row))
 f.put(f.root+0xb9ce4+v.position*24,unhex(v.map))
end
for _,v in ipairs(preorder_fixture) do
 check('preorder captured composite identity: '..v.name,function()
  for _,state in ipairs({0,1,2,4}) do
   local f=fixture();preorder_record(f,v)
   local offset=0x1ce4+v.index*184+20;f.word(f.root+offset,state)
   local before=f.read(f.root,0x200000);local expected=before
   if state==0 or state==1 then expected=before:sub(1,offset)..le32(2)..before:sub(offset+5) end
   assert(f.core:cosmetic(v));assert(f.read(f.root,0x200000)==expected)
   local w=f.writes;assert(f.core:cosmetic(v));assert(f.writes==w)
  end
 end)
end
check('preorder rejects missing, wrong composite ID, row identity, type and status',function()
 local v=preorder_fixture[1]
 for _,field in ipairs({'missing','record','row','type','state'}) do
  local f=fixture();if field~='missing' then preorder_record(f,v) end
  local row=f.root+0x1ce4+v.index*184
  if field=='record' then f.word(f.root+0xb9ce4+v.position*24+4,v.key) end
  if field=='row' then f.word(row+8,123) end
  if field=='type' then f.word(row+12,1) end
  if field=='state' then f.word(row+20,99) end
  assert(not f.core:cosmetic(v));assert(f.writes==0 and f.count()==2928)
 end
end)
check('preorder partial write rolls back',function()
 local f=fixture();local v=preorder_fixture[1];preorder_record(f,v)
 local before=f.read(f.root,0x200000);f.fail=f.root+0x1ce4+v.index*184+20
 assert(not f.core:cosmetic(v));assert(f.read(f.root,0x200000)==before)
end)
check('preorder targets retained in expanded catalogue',function()
 local h=assert(io.open('Source/runtime_suffix.lua'));local s=h:read('*a');h:close()
 local cat=assert(loadstring(s:match('(local COSMETICS=.-)local function classes')..'return COSMETICS'))()
 for _,v in ipairs(preorder_fixture) do
  local found=false
  for _,t in ipairs(cat) do if t.key==v.key then assert(t.record_key==v.record_key);found=true end end
  assert(found)
 end
end)
print(tests..' registry/cosmetic tests passed')


local h=assert(io.open('Source/runtime_suffix.lua'));local source=h:read('*a');h:close()
local cosmetics=assert(loadstring(source:match('(local COSMETICS=.-)local function classes')..'return COSMETICS'))()
local live=assert(loadfile('Tests/live_catalogue_fixture.lua'))()
local function full_fixture()
 local f=fixture()
 for _,v in ipairs(live) do
  f.put(f.root+0x1ce4+v.index*184,unhex(v.row))
  f.put(f.root+0xb9ce4+v.position*24,unhex(v.map))
 end
 f.io.kit=function(t)return true end
 return f
end
check('all 374 captured cosmetic records change only availability',function()
 local f=full_fixture();local before=f.read(f.root,0x200000);local expected=before
 local changes={}
 for _,v in ipairs(live) do
  if u32(unhex(v.row),20)<2 then changes[#changes+1]=0x1ce4+v.index*184+20 end
 end
 table.sort(changes,function(a,b)return a>b end)
 for _,offset in ipairs(changes) do expected=expected:sub(1,offset)..le32(2)..expected:sub(offset+5) end
 local snap=assert(f.core:snapshot())
 for _,v in ipairs(live) do assert(f.core:catalogue_cosmetic(v,snap)) end
 assert(f.read(f.root,0x200000)==expected)
end)
check('special-only kits enable and missing special kits append without collisions',function()
 local f=full_fixture()
 for _,t in ipairs(cosmetics) do assert(f.core:catalogue_cosmetic(t),t.name) end
 assert(f.count()==2928+15)
 local writes=f.writes
 for _,t in ipairs(cosmetics) do assert(f.core:catalogue_cosmetic(t)) end
 assert(f.writes==writes)
end)
local function kdm()
 for _,t in ipairs(cosmetics) do if t.key==0x1e28f118 then return t end end
 error('KDM Pacesetter target missing')
end
check('missing KDM kit appends standalone identity and retains template tail',function()
 local f=full_fixture();local t=kdm();local snap=assert(f.core:snapshot())
 local template=assert(f.core:find(snap,t.template_key))
 f.word(f.root+0x1ce4+template.index*184+180,0x12345678)
 assert(f.core:catalogue_cosmetic(t))
 local row=f.read(f.root+0x1ce4+2928*184,184);local map=f.read(f.root+0xb9ce4+2928*24,24)
 assert(u32(row,4)==t.key and u32(row,8)==t.key and u32(row,12)==3 and u32(row,20)==2)
 assert(u32(row,180)==0x12345678 and map:sub(13)==string.rep('\0',12))
end)
check('cosmetic append gate rejects absent native definition and bad template',function()
 local f=full_fixture();f.io.kit=function()return false,'absent' end
 assert(not f.core:catalogue_cosmetic(kdm()));assert(f.writes==0)
 f.io.kit=function()return true end
 local snap=assert(f.core:snapshot());local t=assert(f.core:find(snap,kdm().template_key))
 f.word(f.root+0x1ce4+t.index*184+12,1)
 assert(not f.core:catalogue_cosmetic(kdm()));assert(f.writes==0)
end)
check('cosmetic append partial failures roll back row, map and count',function()
 for _,addr in ipairs({0x1ce4+2928*184,0xb9ce4+2928*24,0x1ce0}) do
  local f=full_fixture();local before=f.read(f.root,0x200000);f.fail=f.root+addr
  assert(not f.core:catalogue_cosmetic(kdm()));assert(f.read(f.root,0x200000)==before)
 end
end)
check('cosmetic shared snapshot detects stale count before writing',function()
 local f=full_fixture();local snap=assert(f.core:snapshot());f.word(f.root+0x1ce0,2929)
 assert(not f.core:catalogue_cosmetic(kdm(),snap));assert(f.writes==0)
end)
check('cosmetic append rejects full registry, occupied slots and foreign identity',function()
 for _,case in ipairs({'full','occupied','collision'}) do
  local f=full_fixture()
  if case=='full' then f.word(f.root+0x1ce0,4096) end
  if case=='occupied' then f.word(f.root+0xb9ce4+2928*24,42) end
  if case=='collision' then f.record(22,420,kdm().key,1) end
  assert(not f.core:catalogue_cosmetic(kdm()));assert(f.writes==0)
 end
end)
check('standalone stratagem append and selection are one rollback unit',function()
 for _,failure in ipairs({0,0x1ce4+2928*184,0xb9ce4+2928*24,0x1ce0}) do
  local f=fixture();f.record(13,300,301,2)
  local t={name='portable',id=31,key=98765,record_key=98765,allow_append=true,template_key=301}
  local before=f.read(f.root,0x200000)
  if failure~=0 then f.fail=f.root+failure;assert(not f.core:stratagem(t));assert(f.read(f.root,0x200000)==before)
  else assert(f.core:stratagem(t));assert(f.count()==2929 and f.read(f.flag,1):byte()==0x82) end
 end
end)
check('full cosmetic catalogue retains each named user request',function()
 for _,key in ipairs({0x1e28f118,0x71e406e4,0x1b8329ab,0xf5cb7633,0x1c089a28,0xf9d912a7,0xcb7e9736,0xec49526f,0xae5978b1,0xd2a83ca7,0x6478678e}) do
  local found=false;for _,t in ipairs(cosmetics) do if t.key==key then found=true end end;assert(found)
 end
end)
check('filtered cosmetic pass leaves every excluded inventory record unchanged',function()
 local f=full_fixture();local selected={};for _,t in ipairs(cosmetics)do selected[t.key]=true end
 local before={}
 for _,v in ipairs(live)do
  if not selected[v.key]then
   local a=f.root+0x1ce4+v.index*184
   f.word(a+20,1);before[a]=f.read(a,184)
  end
 end
 for _,t in ipairs(cosmetics)do assert(f.core:catalogue_cosmetic(t),t.name)end
 for a,b in pairs(before)do assert(f.read(a,184)==b,'excluded record was modified')end
end)
print(tests..' total registry/cosmetic checks passed')
return tests
