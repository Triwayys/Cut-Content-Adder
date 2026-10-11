-- Run with a non-GC64 LuaJIT 2.1 (matching the supplied v17 bytecode format):
-- luajit Tests/discovery_tests.lua /path/to/loader.patch_0 Addon/9ba626afa44a3aa3.patch_0
-- Executes the supplied loader's ACTUAL archive scanner, without game/native calls.
local ffi,bit=require('ffi'),require('bit')
local function bytes(path)
  local f=assert(io.open(path,'rb'));local b=f:read('*a');f:close();return b
end
local function u32(b,o)
  local a,c,d,e=b:byte(o+1,o+4);return a+c*256+d*65536+e*16777216
end
local function word(n)return string.char(n%256,math.floor(n/256)%256,math.floor(n/65536)%256,math.floor(n/16777216)%256)end
local function replace(b,o,n)return b:sub(1,o)..word(n)..b:sub(o+5)end
local loader=bytes(assert(arg[1],'loader patch path required'))
local payload=loader:sub(201,200+u32(loader,192))
local discovery
local function hook()
  for i=1,25 do
    local name,v=debug.getlocal(2,i);if not name then break end
    if type(v)=='table' and type(rawget(v,'scan'))=='function'
      and type(rawget(v,'declaration'))=='function' then discovery=v end
  end
end
package.loaded['core/wwise/lua/wwise_visualization']={}
package.loaded['core/wwise/lua/wwise_bank_reference']={}
stingray={Application={can_get=function()return false end}}
local original_print=print;print=function()end
debug.sethook(hook,'r')
local ok,err=pcall(assert(loadstring(payload)))
debug.sethook();print=original_print
assert(ok,err);assert(discovery,'loader scanner not captured')
local hash=discovery.hasher(ffi,bit)
local path=assert(arg[2],'addon patch path required')
local archive=bytes(path)
local function scan(b)
  local function open()
    local pos=0
    return {
      seek=function(self,mode,off)
        off=off or 0
        if mode=='end' then pos=#b+off elseif mode=='set' then pos=off else pos=pos+off end
        return pos
      end,
      read=function(self,n)local s=b:sub(pos+1,pos+n);pos=pos+#s;return s end,
      close=function()return true end}
  end
  local found,errors=discovery.scan({path},hash,open)
  assert(#errors==0,table.concat(errors,'; '));return found
end
local found=scan(archive)
assert(#found==1 and found[1]=='mods/codex/hidden_equipment_combined')
print('PASS actual v17 scanner discovers corrected package')
local broken=replace(replace(archive,160,12107),168,u32(archive,192)+8)
assert(#scan(broken)==0)
print('PASS reproduces v0.1.0 silent discovery failure')
local wrong_hash=replace(archive,104,0)
assert(#scan(wrong_hash)==0)
print('PASS loader rejects mismatched module hash')
local short_size=replace(archive,160,u32(archive,192)+7)
assert(#scan(short_size)==0)
print('PASS loader rejects resource size shorter than payload')
print('4 loader discovery checks passed; Windows/game execution not tested')

-- Exercise the startup gate against the ACTUAL loader object, not invented metadata.
local actual_loader=CowboyBingusModLoader
assert(actual_loader.api==1 and actual_loader.version==16)
print('PASS supplied v17 distribution exposes API 1 / internal version 16')
local source=archive:sub(201,200+u32(archive,192))
local logs={}
actual_loader.open_log=function()
  return {write=function(self,s)logs[#logs+1]=s end,flush=function()end,close=function()end}
end
update=function()end
HiddenEquipmentCombined=nil
local previous_guard=source:gsub('%(tonumber%(loader.version%) or 0%) < 16','(tonumber(loader.version) or 0) < 17')
local rejected=assert(loadstring(previous_guard))()
assert(rejected.status:find('incompatible Bingus interface',1,true))
print('PASS reproduces previous erroneous version rejection')
HiddenEquipmentCombined=nil
local accepted=assert(loadstring(source))()
assert(ffi.os~='Windows','run this offline startup test on Linux')
assert(accepted.status=='disabled: Windows x64 LuaJIT FFI required')
print('PASS corrected startup accepts actual loader and reaches platform check')
actual_loader.api=2;HiddenEquipmentCombined=nil
local wrong_api=assert(loadstring(source))()
assert(wrong_api.status:find('incompatible Bingus interface',1,true))
actual_loader.api=1
print('PASS incompatible API is still rejected')

local custom_path='Addon/9ba626afa44a3aa3.patch_1'
local custom_archive=bytes(custom_path)
local custom_found=scan(custom_archive)
assert(#custom_found==1 and custom_found[1]=='mods/codex/las22_shear_customization_experiment_m4')
print('PASS actual loader discovers customization companion')
local custom_source=custom_archive:sub(201,200+u32(custom_archive,192))
LAS22ShearCustomizationExperimentM4=nil
local custom=assert(loadstring(custom_source))()
assert(custom.status=='disabled: Windows x64 LuaJIT FFI required')
print('PASS customization source compiles and accepts actual loader interface')
