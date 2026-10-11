local ffi=require('ffi')
local Core=assert(loadfile('Source/registry_core.lua'))()
local rows=assert(loadfile('Tests/live_vehicle_fixture.lua'))()
local root=0x100000
local function unhex(s)return(s:gsub('..',function(c)return string.char(tonumber(c,16))end))end
local targets={
 {id=5,key=0x651210db,index=383,flag=1},
 {id=105,key=0xea902c4b,record_key=0x7baaf574,index=667,flag=3},
 {id=26,key=0x9d28d826,record_key=0xb2a0f308,index=2751,flag=3},
 {id=135,key=0xa9a97cd7,record_key=0xda0600d7,index=2753,flag=3},
}
local function fixture()
 local mem=ffi.new('uint8_t[?]',0x200000);local writes=0
 local function put(a,b)ffi.copy(mem+a-root,b,#b)end
 local function read(a,n)return ffi.string(mem+a-root,n)end
 put(root+0x1ce0,Core.le32(2928));put(root+0xddcf8,Core.le32(12))
 for _,r in ipairs(rows)do put(root+0xb9ce4+r.position*24,unhex(r.map));put(root+0x1ce4+r.index*184,unhex(r.row))end
 for _,t in ipairs(targets)do put(root+0x100000+t.id,string.char(t.flag))end
 local io={root=function()return root end,read=read,writable=function()return true end,
 write=function(a,b)writes=writes+1;put(a,b);return true end,
 strat_flag=function(id)return root+0x100000+id end}
 return Core.new(io),put,read,function()return writes end
end
local cases=0
for _,t in ipairs(targets)do
 local c,put,read,writes=fixture()
 local before=read(root,0x200000)
 assert(c:stratagem(t))
 local status_addr=root+0x1ce4+t.index*184+20
 assert(Core.u32(read(status_addr,4),0)==2)
 local expected=before
 local function set(a,b)local offset=a-root;expected=expected:sub(1,offset)..b..expected:sub(offset+#b+1)end
 set(status_addr,Core.le32(2));set(root+0x100000+t.id,string.char(3))
 assert(read(root,0x200000)==expected,'unexpected memory change')
 local n=writes();assert(c:stratagem(t));assert(writes()==n,'not idempotent')
 print('PASS exact live header replay id='..t.id..'; only status/selection changed');cases=cases+1
end
local t=targets[4]
local c,put,read,writes=fixture()
assert(not c:stratagem({id=t.id,key=t.key,record_key=123}));assert(writes()==0)
print('PASS wrong composite ID rejected');cases=cases+1
c,put,read,writes=fixture();put(root+0x1ce4+t.index*184+12,Core.le32(2))
assert(not c:stratagem(t));assert(writes()==0)
print('PASS incorrect record type rejected');cases=cases+1
c,put,read,writes=fixture();put(root+0x1ce4+t.index*184+4,Core.le32(123))
assert(not c:stratagem(t));assert(writes()==0)
print('PASS mapping/record identity mismatch rejected');cases=cases+1
print(cases..' live-fixture regression checks passed; gameplay untested')
