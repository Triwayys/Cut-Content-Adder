local ffi=require('ffi')
local Core=assert(loadfile('Source/registry_core.lua'))()
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
local function new_journal()
  rawset(_G,'HD2WriteJournal',nil)
  local h=assert(io.open('Source/runtime_prefix.lua','r'));local src=h:read('*a');h:close()
  local block=src:match('(%-%- Shutdown journal.-)\nlocal function initialize%(%)')
  assert(block,'journal block not found in runtime_prefix.lua')
  return assert(loadstring(block..'\nreturn journal'))()
end
local function snapshot(f)return ffi.string(f.mem,0x200000)end
local function journaled_fixture(count)
  local f=fixture(count);f.journal=new_journal();f.io.journal=f.journal
  f.core=Core.new(f.io)
  return f
end
check('shutdown restores memory byte-for-byte after appends and unlocks',function()
  local f=journaled_fixture();local before=snapshot(f)
  for _,t in ipairs(f.targets)do assert(f.core:weapon(t))end
  assert(f.count()==2931);assert(snapshot(f)~=before)
  local restored,skipped=f.journal.run()
  assert(restored>0 and skipped==0,'restored='..restored..' skipped='..skipped)
  assert(snapshot(f)==before,'registry differs from original after shutdown restore')
  assert(f.count()==2928)
end)
check('existing locked equipment status is restored',function()
  local f=journaled_fixture();f.record(13,300,201,1);local before=snapshot(f)
  assert(f.core:weapon(f.targets[1]))
  assert(u32(f.read(f.root+0x1ce4+300*184+20,4),0)==2)
  f.journal.run();assert(snapshot(f)==before)
end)
check('journal is replayed in reverse and only once',function()
  local f=journaled_fixture();local before=snapshot(f)
  assert(f.core:weapon(f.targets[1]));assert(f.core:weapon(f.targets[2]))
  local r1=f.journal.run();local r2,s2=f.journal.run()
  assert(r1>0 and r2==0 and s2==0 and snapshot(f)==before)
end)
check('value changed by the game after our write is never overwritten',function()
  local f=journaled_fixture()
  assert(f.core:weapon(f.targets[1]))
  local addr=f.root+0x1ce0;f.word(addr,5000)  -- game changed the count itself
  local restored,skipped=f.journal.run()
  assert(skipped>=1 and f.count()==5000)
end)
check('replaced or released registry is left untouched',function()
  local f=journaled_fixture()
  assert(f.core:weapon(f.targets[1]))
  local original_root=f.root;f.io.root=function()return 0x180000 end
  local after=snapshot(f);local restored,skipped=f.journal.run()
  assert(restored==0 and skipped>0 and snapshot(f)==after)
  f.io.root=function()return original_root end
end)
check('registry no longer ready (gate != 12) is left untouched',function()
  local f=journaled_fixture();assert(f.core:weapon(f.targets[1]))
  f.word(f.root+0xddcf8,0);local after=snapshot(f)
  local restored=f.journal.run();assert(restored==0 and snapshot(f)==after)
end)
check('failed transaction registers nothing to undo',function()
  local f=journaled_fixture();f.readonly=true
  assert(not f.core:weapon(f.targets[1]));assert(#f.journal.entries==0)
end)
print(tests..' shutdown checks passed')
return tests
