local ffi=require('ffi')
local Core=assert(loadfile('Source/registry_core.lua'))()
local Index=assert(loadfile('Source/category_index.lua'))()
local rows=assert(loadfile('Tests/category_capture.lua'))()
local kdm=assert(loadfile('Tests/kdm_capture.lua'))()
local u32,le32=Core.u32,Core.le32
local function unhex(s)return(s:gsub('..',function(x)return string.char(tonumber(x,16))end))end
local root=0x100000
local function fixture()
 local mem=ffi.new('uint8_t[?]',0x200000);local f={writes=0,mem=mem}
 function f.read(a,n)if a<root or a+n>root+0x200000 then return nil end;return ffi.string(mem+a-root,n)end
 function f.put(a,s)ffi.copy(mem+a-root,s,#s)end
 function f.word(a,v)f.put(a,le32(v))end
 for _,v in ipairs(rows)do f.put(root+0x1ce4+v.index*184,unhex(v.row));f.put(root+0xb9ce4+v.position*24,unhex(v.map))end
 f.word(root+0x1ce0,#rows);f.word(root+0xddcf8,12)
 -- Reconstruct the native initial category index from captured row headers.
 local sorted={};for _,v in ipairs(rows)do sorted[#sorted+1]=v end
 table.sort(sorted,function(a,b)local x,y=u32(unhex(a.row),12),u32(unhex(b.row),12);return x==y and a.index<b.index or x<y end)
 local n=0
 for kind=0,23 do
  f.word(root+0xd1ce4+kind*4,n)
  for _,v in ipairs(sorted)do if u32(unhex(v.row),12)==kind then f.word(root+0xd1d48+n*4,v.position);n=n+1 end end
 end
 f.word(root+0xd1d44,n);assert(n==2928)
 for i,t in ipairs(kdm)do
  local pos=2927+i;f.put(root+0x1ce4+pos*184,le32(pos)..unhex(t.row):sub(5))
  f.put(root+0xb9ce4+pos*24,le32(pos)..le32(t.key)..le32(t.key)..string.rep('\0',12))
 end
 f.word(root+0x1ce0,2932)
 f.io={read=f.read,u32=u32,le32=le32,guard=function()return not f.badguard,'signature mismatch'end}
 f.core=Core.new({journal=f.journal,read=f.read,root=function()return root end,writable=function()return true end,
  write=function(a,s)
   f.writes=f.writes+1
   if a==f.fail then f.fail=nil;f.put(a,s:sub(1,math.floor(#s/2)));return false end
   f.put(a,s);return true
  end})
 return f
end
local total=0
local function new_journal()
 local h=assert(io.open('Source/runtime_prefix.lua','r'));local src=h:read('*a');h:close()
 rawset(_G,'HD2WriteJournal',nil)
 return assert(loadstring(assert(src:match('(%-%- Shutdown journal.-)\nlocal function initialize%(%)'))..'\nreturn journal'))()
end
local function test(n,fn)fn();total=total+1;print('PASS '..n)end
local function lookup(f,key)
 local first,last=u32(f.read(root+0xd1cf0,4),0),u32(f.read(root+0xd1cf4,4),0)
 for i=first,last-1 do local pos=u32(f.read(root+0xd1d48+i*4,4),0);local m=f.read(root+0xb9ce4+pos*24,24);if u32(m,8)==key then return pos end end
end
test('captured KDM entries are invisible to old category lookup and resolve after repair',function()
 local f=fixture();for _,t in ipairs(kdm)do assert(not lookup(f,t.key))end
 local h=assert(io.open('/tmp/hd2-category-before.bin','wb'));h:write(f.read(root,0x200000));h:close()
 assert(Index.repair(f.core,f.io));for _,t in ipairs(kdm)do assert(lookup(f,t.key))end
 h=assert(io.open('/tmp/hd2-category-after.bin','wb'));h:write(f.read(root,0x200000));h:close()
end)
test('all record bytes and ownership states stay unchanged',function()
 local f=fixture();local old=f.read(root+0x1ce4,2932*184);local maps=f.read(root+0xb9ce4,2932*24)
 assert(Index.repair(f.core,f.io));assert(f.read(root+0x1ce4,#old)==old and f.read(root+0xb9ce4,#maps)==maps)
end)
test('all existing category entries preserved with no duplicates',function()
 local f=fixture();assert(Index.repair(f.core,f.io));local seen={}
 for i=0,2931 do local p=u32(f.read(root+0xd1d48+i*4,4),0);assert(not seen[p]and p<2932);seen[p]=true end
end)
test('repeat repair performs no writes',function()
 local f=fixture();assert(Index.repair(f.core,f.io));local n=f.writes;assert(Index.repair(f.core,f.io));assert(f.writes==n)
end)
test('partial index and boundary writes roll back',function()
 for _,off in ipairs({0xd1d48,0xd1ce4})do local f=fixture();local old=f.read(root,0x200000);f.fail=root+off
  assert(not Index.repair(f.core,f.io));assert(old==f.read(root,0x200000))end
end)
test('invalid code, boundaries, membership and map alignment fail without writes',function()
 for _,case in ipairs({'code','bounds','membership','map','type'})do
  local f=fixture()
  if case=='code'then f.badguard=true elseif case=='bounds'then f.word(root+0xd1d44,5000)
  elseif case=='membership'then f.word(root+0xd1d48,5000)elseif case=='map'then f.word(root+0xb9ce4,5)
  else f.word(root+0x1ce4+12,99)end
  assert(not Index.repair(f.core,f.io));assert(f.writes==0)
 end
end)
test('later attachment appends are indexed without losing KDM entries',function()
 local f=fixture();assert(Index.repair(f.core,f.io))
 for i=0,6 do
  local pos=2932+i;local key=0x123400+i
  f.put(root+0x1ce4+pos*184,le32(pos)..le32(key)..le32(key)..le32(2)..le32(0)..le32(2)..string.rep('\0',160))
  f.put(root+0xb9ce4+pos*24,le32(pos)..le32(key)..le32(key)..string.rep('\0',12))
 end
 f.word(root+0x1ce0,2939);assert(Index.repair(f.core,f.io))
 assert(u32(f.read(root+0xd1d44,4),0)==2939)
 for _,t in ipairs(kdm)do assert(lookup(f,t.key))end
end)
test('shutdown restores the original category index after repair',function()
 local g=new_journal();local old_new=Core.new
 Core.new=function(io)io.journal=g;return old_new(io)end
 local f=fixture();Core.new=old_new
 local before=f.read(root,0x200000)
 assert(Index.repair(f.core,f.io));assert(f.read(root,0x200000)~=before)
 local restored,skipped=g.run();assert(restored>0 and skipped==0)
 assert(f.read(root,0x200000)==before,'category index differs from original after shutdown restore')
end)
print(total..' category index checks passed')
