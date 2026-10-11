local D=assert(loadfile('Source/kdm_diagnostics.lua'))()
local Core=assert(loadfile('Source/registry_core.lua'))()
local word=Core.le32
local log,reads={},0
local target={key=0x1e28f118,name='Pacesetter',template_key=0x8b9ed77d}
local map=word(0)..word(target.key)..word(target.key)..string.rep('\0',12)
local function hex(b)return (b:gsub('.',function(c)return string.format('%02X',c:byte())end))end
local s={root=0x100000,count=1,maps=map}
local api={snapshot=function()return s end,u32=Core.u32,hex=hex,emit=function(x)log[#log+1]=x end,
 read=function(a,n)assert(a==s.root+0x1ce4 and n==184);reads=reads+1;return string.rep('\0',184)end,
 inspect=function(t)assert(t==target);return string.rep('\0',64)end}
assert(D.capture(api,{target},1));assert(reads==1)
local all=table.concat(log,'\n');assert(all:find('row184=') and all:find('header64=') and all:find('stable=true'))
print('PASS full record and native header capture with bounded reads')
reads=0;s.maps=word(99)..map:sub(5);assert(D.capture(api,{target},2));assert(reads==0)
print('PASS out-of-range index is never dereferenced')
api.snapshot=function()return nil,'not ready'end;assert(not D.capture(api,{target},1))
print('PASS unavailable registry does not cause reads')
print('3 diagnostic checks passed')
