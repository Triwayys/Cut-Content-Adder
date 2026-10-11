-- Execute the actual adapted customization tick against synthetic native tables.
-- Fixture identities are taken from the supplied Shear source; this is not a game test.
local ffi=require('ffi')
local Core=assert(loadfile('Source/registry_core.lua'))()
local function bytes(p)local f=assert(io.open(p,'rb'));local s=f:read('*a');f:close();return s end
local source=bytes('Source/shear_customization.lua')
local itemsource=assert(source:match('(local items=%b{})'))
local ticksource=assert(source:match('(local start,next_check,done=.-)local previous=rawget'))
local function unhex(s)return(s:gsub('..',function(c)return string.char(tonumber(c,16))end))end
local function packptr(v)local q=ffi.new('uint64_t[1]',v);return ffi.string(q,8)end
local function u64at(s,o)local q=ffi.new('uint64_t[1]');ffi.copy(q,s:sub(o+1,o+8),8);return tonumber(q[0])end
local function replace(s,o,v)return s:sub(1,o)..v..s:sub(o+#v+1)end
local SHEAR,SCYTHE=0x7de53646,0xe673dcc8
local items=assert(loadstring(itemsource..'return items'))()
local total=0
local function check(n,fn)fn();total=total+1;print('PASS '..n)end
local function fixture(count,shearIndex,groups,managerSlot)
 count=count or 2932;shearIndex=shearIndex or 2929;groups=groups or 56;managerSlot=managerSlot or 80
 local blocks={};local f={time=0,writes=0,logs={}}
 local function add(a,n)local b={a=a,n=n,m=ffi.new('uint8_t[?]',n)};blocks[#blocks+1]=b;return a end
 local function locate(a,n)for _,b in ipairs(blocks)do if a>=b.a and a+n<=b.a+b.n then return b.m+(a-b.a) end end end
 local function read(a,n)local q=locate(a,n);return q and ffi.string(q,n)end
 local function put(a,b)local q=assert(locate(a,#b),string.format('unmapped %x %d',a,#b));ffi.copy(q,b,#b)end
 local function word(a,v)put(a,Core.le32(v))end
 local function pointer(a,v)put(a,packptr(v))end
 local root=add(0x10000000,0x1800000)
 local itemslot=add(0x20000000,32);pointer(itemslot,root)
 local progression=add(0x21000000,24);pointer(itemslot+8,progression)
 local progressionRows=add(0x21100000,(groups+1)*112)
 word(progression,2);pointer(progression+8,progressionRows);word(progression+16,groups)
 for i=0,groups-1 do word(progressionRows+i*112,0x10000+i) end
 local template=progressionRows+24*112
 word(template,0x56219b65);word(template+4,24);word(template+8,2);word(template+12,SCYTHE);word(template+104,25)
 local class=add(0x21200000,0x1b20);pointer(itemslot+16,class)
 word(class+42*32,SHEAR);put(class+42*32+8,unhex('48b9a4baa545317e'));word(class+42*32+16,1)
 local owner=0x21300000;add(owner+0xf12cf0,8);pointer(itemslot+24,owner)
 local mt=add(0x30000000,0x17e0+0x1308);pointer(owner+0xf12cf0,mt)
 put(mt,unhex('48b9a4baa545317e'));word(mt+8,0)
 local model=mt+0x17e0;word(model+0x12fc,0xd62dc83d)
 for i=1,5 do word(model+(i-1)*8,items[i].slot);word(model+(i-1)*8+4,items[i].attachment);word(model+0x50+(i-1)*4,items[i].slot)end
 word(root+0xddcf8,12);word(root+0x1ce0,count)
 for i=0,count-1 do
  local m=root+0xb9ce4+i*24;word(m,i);word(m+4,0x20000+i);word(m+8,0x20000+i)
 end
 local function baseRecord(idx,key)
  local m=root+0xb9ce4+idx*24;word(m,idx);word(m+4,key);word(m+8,key)
  local r=root+0x1ce4+idx*184;word(r,idx);word(r+4,key);word(r+8,key);word(r+12,1);word(r+20,2)
 end
 baseRecord(226,SCYTHE);baseRecord(shearIndex,SHEAR)
 for _,v in ipairs(items)do put(root+0x1ce4+v.sourceIndex*184,unhex(v.record));put(root+0xb9ce4+v.sourceIndex*24,unhex(v.mapping))end
 for i=0,managerSlot-1 do word(root+0x178a4ec+i*148,0x40000+i)end
 local settings=add(0x22000000,9*8);local heads=add(0x22100000,9*16)
 local rows=add(0x22200000,16*88);local slots=add(0x22300000,8*4)
 for g=0,8 do pointer(settings+g*8,heads+g*16);pointer(heads+g*16,rows+(g==0 and 0 or (7+g)*88));word(heads+g*16+8,g==0 and 8 or 1)end
 for i,v in ipairs(items)do
  local a=rows+(i-1)*88;word(a+8,v.attachment);pointer(a+0x30,slots+(i-1)*4);word(a+0x38,1);word(slots+(i-1)*4,v.slot)
  if v.name=='muzzle' then word(a+12,0x37709874);f.muzzle=a end
 end
 word(rows+7*88+8,0xe917f79b);word(rows+7*88+12,0x6113b753)
 local base=0x40000000;add(base+0x11f4680,0x100)
 put(base+0x11f468a,string.char(0x8b,0x3d)..Core.le32(0x60-0x10));word(base+0x11f4680+0x60,9)
 rawset(_G,'HD2WriteJournal',nil)
 local jsrc=bytes('Source/shear_customization.lua')
 local journal=assert(loadstring(assert(jsrc:match('(%-%- Shutdown journal.-)\nlocal loader'))..'\nreturn journal'))()
 f.journal=journal
 local env={journal=journal,ffi=ffi,u32=Core.u32,le32=Core.le32,u64at=u64at,read=read,unhex=unhex,packptr=packptr,replace=replace,
  zeros=function(n)return string.rep('\0',n)end,base=base,SHEAR=SHEAR,SCYTHE=SCYTHE,shear_model=unhex('48b9a4baa545317e'),
  item_slot=itemslot,progression_slot=itemslot+8,class_slot=itemslot+16,model_owner_slot=itemslot+24,public={status='waiting'},
  ptr=function(a)local s=read(a,8);return s and u64at(s,0)end,
  now=function()return f.time end,emit=function(s)f.logs[#f.logs+1]=s end,
  rip=function(rva)assert(rva==0x11f4697);return settings end,
  writable=function(a,n)return locate(a,n)~=nil and a~=f.readonly end,
  write=function(a,b)
   f.writes=f.writes+1
   if f.fail==a then f.fail=nil;put(a,b:sub(1,math.floor(#b/2)));return false end
   put(a,b);if f.after_write then f.after_write(a,b)end;return true
  end,
  k={VirtualAlloc=function(_,n)f.alloc_size=n;add(0x50000000,n);return ffi.cast('void *',0x50000000)end}}
 env.finish=function(s)env.public.status=s end;setmetatable(env,{__index=_G})
 local code=itemsource..'\n'..ticksource..'\nreturn function()if not done then tick()end end'
 local chunk=assert(loadstring(code));setfenv(chunk,env);local tick=chunk()
 f.read,f.put,f.word,f.pointer,f.root,f.env,f.tick,f.count_n,f.shearIndex,f.groups,f.managerSlot=read,put,word,pointer,root,env,tick,count,shearIndex,groups,managerSlot
 function f.run()f.time=31;return pcall(tick)end
 return f
end
for _,case in ipairs({{2929,2928,56,80},{2932,2929,56,80},{3010,17,64,91},{2939,2931,57,80}})do
 check('dynamic Shear count/owner/groups/manager '..table.concat(case,'/'),function()
  local f=fixture(unpack(case));local originals=f.read(f.root+0xb9ce4,case[1]*24)
  local ok,why=f.run();assert(ok,why);assert(f.env.public.status=='active',f.env.public.status)
  assert(Core.u32(f.read(f.root+0x1ce0,4),0)==case[1]+7)
  assert(f.read(f.root+0xb9ce4,case[1]*24)==originals)
  for i,v in ipairs(items)do
   local idx=case[1]+i-1;local m=f.read(f.root+0xb9ce4+idx*24,24)
   assert(Core.u32(m,4)==v.key and Core.u32(m,8)==v.attachment)
   assert(idx-Core.u32(m,12)==case[2] and idx-Core.u32(m,16)==case[2])
  end
  local w=f.writes;f.time=40;f.tick();assert(f.writes==w,'repeated initialization wrote again')
 end)
end
check('missing Shear waits without writes',function()
 local f=fixture();f.word(f.root+0xb9ce4+f.shearIndex*24+4,0x999999);assert(f.run());assert(f.writes==0)
end)
check('conflicting customization group rejected without writes',function()
 local f=fixture();f.word(0x21100000,0xd62dc83d);assert(not f.run());assert(f.writes==0)
end)
check('occupied append record preserved',function()
 local f=fixture();f.word(f.root+0x1ce4+f.count_n*184,7);assert(not f.run());assert(f.writes==0)
end)
check('partial mapping write restores registry and progression',function()
 local f=fixture();local before=f.read(f.root+0x1ce4,0xc0000);local ph=f.read(0x21000000,24)
 f.fail=f.root+0xb9ce4+f.count_n*24;assert(f.run());assert(f.env.public.status:find('rollback=true',1,true))
 assert(f.read(f.root+0x1ce4,0xc0000)==before and f.read(0x21000000,24)==ph)
end)
check('registry replacement prevents rollback into new owner',function()
 local f=fixture();local mutation=f.root+0x1ce4+f.count_n*184
 f.after_write=function(a)if a==mutation then f.pointer(f.env.item_slot,0x60000000)end end
 assert(f.run());assert(f.env.public.status:find('rollback=false',1,true));assert(f.read(f.root+0x1ce0,4)==Core.le32(f.count_n))
end)
check('parent mapping identity mismatch rejected',function()
 local f=fixture();f.word(f.root+0x1ce4+f.shearIndex*184+4,123);assert(not f.run());assert(f.writes==0)
end)
check('shutdown restores registry, manager, muzzle name and progression pointer',function()
 local f=fixture();local regions={{f.root,0x1800000},{0x21000000,24},{0x22200000,16*88}}
 local before={};for i,r in ipairs(regions)do before[i]=f.read(r[1],r[2])end
 assert(f.run());assert(f.env.public.status=='active')
 assert(f.read(f.root+0x1ce0,4)~=Core.le32(f.count_n))
 local restored,skipped=f.journal.run();assert(restored==7 and skipped==0,restored..'/'..skipped)
 for i,r in ipairs(regions)do assert(f.read(r[1],r[2])==before[i],'region '..i..' differs after shutdown restore')end
end)
check('shutdown is a no-op when Shear never applied',function()
 local f=fixture();f.word(f.root+0xb9ce4+f.shearIndex*24+4,0x999999);assert(f.run())
 local restored,skipped=f.journal.run();assert(restored==0 and skipped==0)
end)
print(total..' customization integration checks passed; in-game UI/resources not tested')
