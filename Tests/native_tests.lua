local Core=assert(loadfile('Source/registry_core.lua'))()
local Native=assert(loadfile('Source/native_catalogue.lua'))()
local h=assert(io.open('Source/runtime_suffix.lua'));local source=h:read('*a');h:close()
local catalog=assert(loadstring(source:sub(1,assert(source:find('local function classes',1,true))-1)..'return {WEAPONS,STRATS,COSMETICS}'))()
local u32,le32=Core.u32,Core.le32
local function u64(b,o)return u32(b,o)+u32(b,o+4)*4294967296 end
local function le64(n)return le32(n%4294967296)..le32(math.floor(n/4294967296))end
local function fixture(t)
 local f={base=0x10000000,mem={}}
 function f.put(a,b)for i=1,#b do f.mem[a+i-1]=b:byte(i)end end
 function f.read(a,n)local b={};for i=0,n-1 do local v=f.mem[a+i];if v==nil then return nil end;b[#b+1]=string.char(v) end;return table.concat(b)end
 function f.ptr(a)local b=f.read(a,8);return b and u64(b,0)end
 local m,array,kit,body=0x50000000,0x50010000,0x50020000,0x50030000
 f.put(f.base+53634296,le64(m));f.put(m,le64(array)..le64(411));f.put(array,string.rep('\0',411*8))
 f.put(array+t.kit_index*8,le64(kit));f.put(kit,string.rep('\0',64))
 f.put(kit,le32(t.key));f.put(kit+32,le32(t.archive_lo)..le32(t.archive_hi));f.put(kit+40,le32(t.kind))
 f.put(kit+48,le64(body)..le64(t.body_count));f.put(body,string.rep('\0',t.body_count*24))
 f.kit,f.manager,f.array=kit,m,array
 f.native=Native.new({base=f.base,read=f.read,ptr=f.ptr,u32=u32,u64=u64})
 return f
end
local tests=0
local function check(n,fn)fn();tests=tests+1;print('PASS '..n)end
check('all selected native kit identities, types, archives and body counts accepted',function()
 for _,t in ipairs(catalog[3])do local f=fixture(t);assert(f.native:kit(t),t.name);local b=assert(f.native:inspect_kit(t));assert(#b==64 and u32(b,0)==t.key) end
end)
check('native kit mismatches and absent body memory fail closed',function()
 local t=catalog[3][1]
 for _,case in ipairs({'type','archive','id','body_count','body_memory','manager'})do
  local f=fixture(t)
  if case=='type' then f.put(f.kit+40,le32(9)) end
  if case=='archive' then f.put(f.kit+32,le32(1)) end
  if case=='id' then f.put(f.kit,le32(1)) end
  if case=='body_count' then f.put(f.kit+56,le32(1000)) end
  if case=='body_memory' then f.put(f.kit+48,le64(0x60000000)) end
  if case=='manager' then f.put(f.manager+8,le64(999999)) end
  assert(not f.native:kit(t),case)
 end
end)
local function strat_fixture(t)
 local f=fixture(catalog[3][1]);local table_addr=f.base+0x1400000;local info=0x50080000
 f.put(f.base+0x136fc20,string.char(0x48,0x89,0x5c,0x24,0x08,0x48,0x8b,0xd9,0x85,0xd2,0x75))
 f.put(f.base+0x136fc37,string.char(0x48,0x8d,0x05)..le32(table_addr-(f.base+0x136fc37+7)))
 f.put(table_addr+t.id*8,le64(info));f.put(info,string.rep('\0',0xd0));f.put(info,le32(t.id)..le32(t.key))
 f.put(info+16,le64(0x50090000));f.put(0x50090000,'NAME\0');f.info=info
 return f
end
check('all selected stratagem native type/key pairs accepted',function()
 for _,t in ipairs(catalog[2])do local f=strat_fixture(t);assert(f.native:strat_flag(t.id,t.key)==f.info+0x80,t.name)end
end)
check('stratagem mismatch cannot select another definition at same type slot',function()
 local t=catalog[2][1]
 for _,case in ipairs({'key','type','signature','name'})do
  local f=strat_fixture(t)
  if case=='key' then f.put(f.info+4,le32(999)) end
  if case=='type' then f.put(f.info,le32(999)) end
  if case=='signature' then f.put(f.base+0x136fc20,'x') end
  if case=='name' then f.put(f.info+16,le64(0)) end
  assert(not f.native:strat_flag(t.id,t.key),case)
 end
end)
check('catalogue has unique cosmetic IDs, model IDs and stratagem keys',function()
 for group,items in ipairs(catalog)do
  local seen={}
  for _,t in ipairs(items)do
   local key=group==1 and (t.hi..':'..t.lo)or t.key;assert(not seen[key]);seen[key]=true
  end
 end
end)
check('gas and Maelstrom exact IDs included; mission utility items excluded',function()
 local names={};for _,t in ipairs(catalog[2])do names[t.name]=t end
 assert(names['Eagle Gas Airstrike'].key==0xfa1e1428 and names['Eagle Gas Airstrike'].id==126)
 assert(names['TD-110 Maelstrom'].key==0x1b7853ac and names['TD-110 Maelstrom'].id==50)
 assert(not names.Resupply and not names.Reinforce and not names['Eagle Rearm'])
end)
print(tests..' native/catalogue checks passed (95 positive identities replayed)')
