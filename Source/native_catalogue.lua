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
