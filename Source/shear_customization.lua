-- HD2-Addon: mods/codex/las22_shear_customization_experiment_m4
-- Temporary write experiment. Correct attachment parent deltas; verify native filter prerequisites.
local VERSION = '1.0'
local GAME_SHA256 = '2e2c3b7c2500646dadd5f2b4c6e0504dbb7e7896139f64cddc0d1813c718f51e'
local EXE_SHA256 = 'f5fee03dcfdb2e553a4752c283590950ac13316b376d8196aa556ff0400d5f06'
local NAME = 'LAS22ShearCustomizationExperimentM4'
local prior = rawget(_G, NAME)
if prior then return prior end
local public = {version = VERSION, status = 'initializing'}
rawset(_G, NAME, public)

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

local loader = rawget(_G, 'CowboyBingusModLoader')
local log
if type(loader) == 'table' and type(loader.open_log) == 'function' then
    local ok, handle = pcall(loader.open_log, 'LAS22ShearCustomizationExperimentM4.log')
    if ok then log = handle end
end
local function emit(message)
    local line = '[LAS22ShearCustomizationExperimentM4] ' .. message
    pcall(print, line)
    if log then pcall(function() log:write(line .. '\n'); log:flush() end) end
end
local function finish(message)
    public.status = message
    emit(message)
    if log then pcall(function() log:close() end); log = nil end
end
if type(loader) ~= 'table' or loader.api ~= 1 or (loader.version or 0) < 16 then
    finish('disabled: Bingus Shared Loader API1 compatible generation16+ required')
    return public
end
emit('LOADER interface_version='..tostring(loader.version)..' api='..tostring(loader.api))
if type(rawget(_G, 'update')) ~= 'function' then
    finish('disabled: update callback unavailable')
    return public
end

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





local items={
 {name='flashlight',slot=1,attachment=0xd9a3531e,key=0x43eb45f8,sourceIndex=234,sourceKey=0xbab6812e,record='ea0000002e81b6ba1e53a3d9020000000000000002000000ffffff7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000',mapping='ea0000002e81b6ba1e53a3d9080000000800000000000000'},
 {name='optic',slot=2,attachment=0x322a9233,key=0x3d148feb,sourceIndex=235,sourceKey=0xc4494b3d,record='eb0000003d4b49c433922a32020000000000000002000000ffffff7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000',mapping='eb0000003d4b49c433922a32090000000900000000000000'},
 {name='stock',slot=3,attachment=0x80fbe63d,key=0xec406e92,sourceIndex=261,sourceKey=0x151daa44,record='0501000044aa1d153de6fb80020000000000000002000000ffffff7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000',mapping='0501000044aa1d153de6fb80230000002300000000000000'},
 {name='muzzle',slot=4,attachment=0xd65dc159,key=0xac168849,sourceIndex=227,sourceKey=0xcb408ce,record='e3000000ce08b40c9bf717e9020000000000000001000000ffffff7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',mapping='e3000000ce08b40c9bf717e9010000000100000000000000'},
 {name='standard',slot=5,attachment=0x5672e4b7,key=0x6c8e4fcc,sourceIndex=247,sourceKey=0x92610c35,record='f7000000350c619239dfd0f3020000000000000002000000ffffff7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000',mapping='f7000000350c619239dfd0f3150000001500000000000000'},
 {name='extended',slot=5,attachment=0x3d0687c6,key=0xee8a2a85,sourceIndex=248,sourceKey=0x93c2fffd,record='f8000000fdffc293406dd9f9020000000000000002000000ffffff7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100000000000000',mapping='f8000000fdffc293406dd9f9160000001600000000000000'},
 {name='rapid',slot=5,attachment=0x53120a73,key=0x40566154,sourceIndex=250,sourceKey=0xdcf0dcbc,record='fa000000bcdcf0dc730b7787020000000000000001000000ffffff7f000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000',mapping='fa000000bcdcf0dc730b7787180000001800000000000000'},
}

ffi.cdef [[
uint64_t GetTickCount64(void);
int WriteProcessMemory(void *,void *,const void *,size_t,size_t *);
void *VirtualAlloc(void *,size_t,uint32_t,uint32_t);
]]
local game=k.GetModuleHandleA('game.dll')
if game==nil then finish('disabled: game.dll unavailable');return public end
local base=tonumber(ffi.cast('uintptr_t',game))
local ok,hash=pcall(sha256_of_module,base)
local exok,exhash=pcall(sha256_of_module,k.GetModuleHandleA(nil))
if not ok or hash~=GAME_SHA256 or not exok or exhash~=EXE_SHA256 then finish('disabled: version mismatch');return public end
local function now()return tonumber(k.GetTickCount64())/1000 end
local function ptr(a)local b=read(a,8);return b and u64at(b,0)end
local function unhex(h)return (h:gsub('..',function(c)return string.char(tonumber(c,16))end))end
local function packptr(v)local a=ffi.new('uint64_t[1]',v);return ffi.string(a,8)end
local function replace(b,off,v)return b:sub(1,off)..v..b:sub(off+#v+1)end
local function zeros(n)return string.rep(string.char(0),n)end
local function rip(rva,op)
 local b=read(base+rva,7);assert(b and b:sub(1,3)==op,'RIP opcode mismatch')
 local d=u32(b,3);if d>=0x80000000 then d=d-0x100000000 end
 return base+rva+7+d
end
local function writable(a,n)
 local rb,rs,state,prot,kind=region(a)
 return rb and a+n<=rb+rs and state==0x1000 and prot==4 and kind==0x20000
end
local function write(a,b)
 if not writable(a,#b)then return false end
 local buf=ffi.new('uint8_t[?]',#b);ffi.copy(buf,b,#b);local count=ffi.new('size_t[1]')
 return k.WriteProcessMemory(process,ffi.cast('void *',a),buf,#b,count)~=0 and tonumber(count[0])==#b and read(a,#b)==b
end
local item_slot=rip(0x136fdf0,string.char(0x48,0x8b,0x05))
local progression_slot=rip(0x11f4f57,string.char(0x4c,0x8b,0x15))
local model_owner_slot=rip(0x50ed85,string.char(0x48,0x8b,0x05))
local class_slot=rip(0x11e7c65,string.char(0x48,0x8b,0x1d))
local SHEAR,SCYTHE=0x7de53646,0xe673dcc8
local shear_model=unhex('48b9a4baa545317e')

-- Process-local package references for optional Shear heatsinks.
-- API contract cross-checked against CowboyBingus/ArmoryPreviewCache.
-- No weapon records, executable instructions or networking data are changed here.
local lease_signatures = {
{rva=0x12fe350,hex='4585c00f8475010000415641574883ec38'},
{rva=0x12fe361,hex='48895c24504c8bfa48896c24584c8bf1488974246048897c24304c896424284c8d25b9244d024c896c24204c8d2d89254d02418be866660f1f840000000000418b560833c0498b37458b46184c0fafc6448d4aff85d27459498b0e0f1f40008bd84903d84923d948c1e3044803d94839330f84f7000000ffc03bc272e24d8b5e104c8bd133c0660f1f8400000000008bd84903d84923d948c1e3044903da488b0b493bcb740d483bce7408ffc03bc272de33db48893348c7430801000000488b15cade01024c8d05b38b0001488b7b08498bcc4c8bce488d4216493bc5480f42caba1600000048890da2de0102e8cdf41eff4c8b0596de0102488d0db71bfc00ffc04c8bcf4863d04903d04889157dde0102488d15f63ffc00e8819e430048837b08017514488b057b7e0202488bce488b5010ff92f00200004983c7084883ed010f85f8feffff4c8b6c24204c8b642428488b7c2430488b742460488b6c2458488b5c24504883c438415f415e'},
{rva=0x12fe4ce,hex='c3'},
{rva=0x12fe4cf,hex='48ff4308e947ffffff'},
{rva=0x12fe4e0,hex='4585c00f8460010000415641574883ec38'},
{rva=0x12fe4f1,hex='48895c24504c8bfa48896c24584c8bf148897424604c896424284c8d252e234d024c896c24204c8d2dfe234d0248897c2430418be866660f1f840000000000498b374885f60f84d9000000418b4e0833c0418b5618480fafd6448d49ff85c90f84bf0000004d8b060f1f80000000008bd84803da4923d948c1e3044903d8483933740bffc03bc172e6e996000000488b7b084885ff0f8489000000488b155ddd01024c8d05468a000148ffcf498bcc4c8bce48897b08488d4216493bc5480f42caba1600000048890d32dd0102e85df31eff4c8b0526dd0102488d0d471afc00ffc04c8bcf4863d04903d04889150ddd0102488d15163ffc00e8119d430048837b0800751f488bd6498bcee89f174300488b05007d0202488bce488b5010ff92000300004983c7084883ed010f850dffffff4c8b6c24204c8b642428488b7c2430488b742460488b6c2458488b5c24504883c438415f415e'},
{rva=0x12fe649,hex='c3'}
}
local lease_assets = {
 {name='extended',attachment='568fdacc4729ca7d',package='5e87f35b2673021f'},
 {name='rapid',attachment='94d087000381e9b4',package='bd755625baa41400'},
}
local function hexle(v)
 local b=unhex(v);return b
end
-- unhex() above decodes in byte order; these identifiers are little-endian.
local lease_ready,lease_disabled,lease_owner,lease_allocator=false,false,nil,nil
local held={};local lease_next,lease_wait_log=0,false
local acquire_package,release_package
local argument=ffi.new('uint64_t[1]')
local function package_owner()
 local p=ptr(base+0x347ceb0)
 if not p then return nil end
 local h=read(p,32)
 if not h then return nil end
 assert(u64at(h,0)==p+32 and u32(h,8)==1024 and h:sub(17,24)==zeros(8)
  and u32(h,24)==2,'package lease manager layout changed')
 local allocator=ptr(p+16416)
 if not allocator then return nil end
 local rows=assert(read(p+32,16384),'package lease rows unavailable')
 local counts,n={},0
 for i=0,1023 do
  local id=rows:sub(i*16+1,i*16+8)
  if id~=zeros(8) then
   assert(u32(rows,i*16+12)==0,'package count high word changed')
   local count=u32(rows,i*16+8)
   assert(count>0 and count<1000000 and not counts[id],'package count invalid')
   counts[id]=count;n=n+1
  end
 end
 return p,allocator,counts,n
end
local function menu_load_allowed()
 local state=ptr(base+0x347ce28);local ui=ptr(base+0x347cd90)
 if not state or not ui then return false end
 local stack=read(state+0x429c,24)
 if not stack then return false end
 local depth=u32(stack,20)
 assert(depth<=5,'UI state depth changed')
 local top=depth>0 and u32(stack,(depth-1)*4) or -1
 local blocked=read(ui+15892,4)
 return (depth==0 or top==5 or top==14) and ptr(ui+15432)~=nil
  and blocked and u32(blocked,0)==0
end
local function verify_package_api()
 local exe=tonumber(ffi.cast('uintptr_t',k.GetModuleHandleA(nil)))
 for _,v in ipairs(lease_signatures)do
  local expected=unhex(v.hex)
  assert(read(base+v.rva,#expected)==expected,'package API instruction mismatch')
 end
 local root=ptr(base+0x3326308)
 assert(root==exe+0x27c8d80,'script API root changed')
 local app=assert(ptr(root+16),'application API unavailable')
 assert(ptr(app+752)==exe+0x320dd0 and ptr(app+768)==exe+0x321030,'package API dispatch changed')
 -- Confirm actual attachment settings -> native package map, not guessed names.
 local map=assert(read(base+0x3799810,28),'package map unavailable')
 local storage,n=u64at(map,0),u32(map,8)
 local bit=require('bit')
 assert(n>0 and n<=262144 and bit.band(n,n-1)==0,'package map bounds changed')
 local q=ffi.new('uint64_t[1]')
 local settings_slot=rip(0x11f4697,string.char(0x4c,0x8d,0x1d))
 for _,asset in ipairs(lease_assets)do
  asset.id=hexle(asset.package);asset.resource=hexle(asset.attachment)
  local found=false
  local target=asset.name=='extended' and 0x3d0687c6 or 0x53120a73
  for g=0,8 do
   local h=assert(read(assert(ptr(settings_slot+g*8)),16))
   local c=u32(h,8);assert(c<=256,'attachment row bounds changed')
   local rows=assert(read(u64at(h,0),c*88))
   for j=0,c-1 do if u32(rows,j*88+8)==target then
    assert(not found and rows:sub(j*88+33,j*88+40)==asset.resource,'heatsink identity changed')
    found=true
   end end
  end
  assert(found,'heatsink settings missing')
  ffi.copy(q,asset.resource,8)
  local start=tonumber((q[0]*u32(map,24))%n);local matched=false
  for probe=0,math.min(n,256)-1 do
   local row=assert(read(storage+((start+probe)%n)*16,16))
   if row:sub(1,8)==asset.resource then
    assert(row:sub(9,16)==asset.id,'heatsink package mapping changed')
    matched=true;break
   end
   if row:sub(1,8)==map:sub(17,24)then break end
  end
  assert(matched,'heatsink package mapping unresolved')
  emit('HEATSINK_PACKAGE_MAPPING_VERIFIED '..asset.name)
 end
 acquire_package=ffi.cast('void (*)(void *,const uint64_t *,uint32_t)',base+0x12fe350)
 release_package=ffi.cast('void (*)(void *,const uint64_t *,uint32_t)',base+0x12fe4e0)
 lease_ready=true
 emit('HEATSINK_PACKAGE_API_VERIFIED build25480438; requests restricted to menu/briefing')
end
local function release_owned_packages()
 local p,a,counts=package_owner()
 if p~=lease_owner or a~=lease_allocator then return end
 for _,asset in ipairs(lease_assets)do if held[asset.id]and counts[asset.id]then
  ffi.copy(argument,asset.id,8);release_package(ffi.cast('void *',p),argument,1)
  local p2,a2,after=package_owner()
  assert(p2==p and a2==a and (after[asset.id]or 0)==counts[asset.id]-1,'heatsink release verification failed')
  held[asset.id]=nil;counts=after
  emit('HEATSINK_PACKAGE_RELEASE_VERIFIED '..asset.name)
 end end
end
local function lease_tick()
 if lease_disabled or public.status~='active' or now()<lease_next then return end
 lease_next=now()+2
 local p,a,counts,n=package_owner()
 if not p then return end
 if p~=lease_owner or a~=lease_allocator then
  if lease_owner then emit('HEATSINK_PACKAGE_MANAGER_CHANGED; previous manager retired; waiting for safe menu')end
  lease_owner,lease_allocator,held=p,a,{}
 end
 local missing=false
 for _,asset in ipairs(lease_assets)do
  if held[asset.id] and not counts[asset.id] then
   held[asset.id]=nil;emit('HEATSINK_PACKAGE_REFERENCE_LOST '..asset.name)
  end
  if not held[asset.id]then missing=true end
 end
 if not missing then return end
 if not menu_load_allowed()then
  if not lease_wait_log then emit('HEATSINK_PACKAGE_WAIT safe menu/briefing required');lease_wait_log=true end
  return
 end
 lease_wait_log=false
 if not lease_ready then verify_package_api()end
 for _,asset in ipairs(lease_assets)do if not held[asset.id]then
  assert(n<1008 or counts[asset.id],'package lease table capacity exhausted')
  assert(ptr(base+0x347ceb0)==p and ptr(p+16416)==a,'package manager changed before request')
  local before=counts[asset.id]or 0
  ffi.copy(argument,asset.id,8)
  acquire_package(ffi.cast('void *',p),argument,1)
  held[asset.id]=true -- Track our increment before any post-call assertions.
  local p2,a2,after,n2=package_owner()
  assert(p2==p and a2==a and after[asset.id]==before+1,'heatsink acquire verification failed')
  counts,n=after,n2
  emit(string.format('HEATSINK_PACKAGE_ACQUIRE_VERIFIED %s refs=%d->%d; held through mission',asset.name,before,after[asset.id]))
 end end
end

local start,next_check,done=now(),0,false
local function tick()
 if now()-start>300 then done=true;finish('disabled: initialization timeout');return end
 if now()-start<30 or now()<next_check then return end;next_check=now()+2
 local root=ptr(item_slot);local gate=root and read(root+0xddcf8,4)
 if not gate or u32(gate,0)~=12 then return end
 local count=assert(read(root+0x1ce0,4));local count_n=u32(count,0)
 assert(count_n>=1 and count_n+7<=4096,'registry capacity exhausted')
 local class=assert(read(assert(ptr(class_slot))+42*32,32))
 assert(u32(class,0)==SHEAR and class:sub(9,16)==shear_model and u32(class,16)==1 and u32(class,20)==0,'Shear classification mismatch')
 local model_owner=assert(ptr(model_owner_slot));local model_table=assert(ptr(model_owner+0xf12cf0))
 local buckets=assert(read(model_table,0x17e*16));local cfg=nil
 for i=0,0x17d do
  if buckets:sub(i*16+1,i*16+8)==shear_model then
   assert(not cfg,'duplicate model');local idx=u32(buckets,i*16+8);assert(idx<0x17e,'model index bound');cfg=model_table+0x17e0+idx*0x1308
  end
 end
 local model=assert(cfg and read(cfg,0x1308),'Shear model unavailable')
 assert(u32(model,0x12fc)==0xd62dc83d,'Shear upgrade key mismatch')
 for i=1,5 do
  local item=items[i];local matched=false
  for j=0,9 do if u32(model,j*8)==item.slot and u32(model,j*8+4)==item.attachment then matched=true end end
  assert(matched,'Shear default mismatch: '..item.name)
 end
 local mapping=assert(read(root+0xb9ce4,count_n*24));local map_by_key={}
 for i=0,count_n-1 do
  local entry=mapping:sub(i*24+1,(i+1)*24);local key=u32(entry,4)
  assert(not map_by_key[key],'duplicate registry key');map_by_key[key]=entry
 end
 if not map_by_key[SHEAR] then return end
 local shear_index=u32(map_by_key[SHEAR],0)
 assert(shear_index<count_n and u32(map_by_key[SHEAR],8)==SHEAR,'Shear mapping identity mismatch')
 local shear_row=assert(read(root+0x1ce4+shear_index*184,24))
 assert(u32(shear_row,0)==shear_index and u32(shear_row,4)==SHEAR and u32(shear_row,8)==SHEAR
  and u32(shear_row,12)==1 and (u32(shear_row,20)==2 or u32(shear_row,20)==4),'Shear record not available')
 assert(mapping:sub(shear_index*24+1,(shear_index+1)*24)==map_by_key[SHEAR],'Shear native owner position mismatch')
 local progression=assert(ptr(progression_slot));local ph=assert(read(progression,24))
 local group_count=u32(ph,16)
 assert(u32(ph,0)==2 and group_count>=1 and group_count<256,'progression header/count mismatch')
 local rows_ptr=u64at(ph,8);local original_rows=assert(read(rows_ptr,group_count*112))
 local template
 for i=0,group_count-1 do
  local row=original_rows:sub(i*112+1,(i+1)*112)
  assert(u32(row,0)~=0xd62dc83d,'Shear upgrade group already exists; disable standalone Shear mod')
  if u32(row,0)==0x56219b65 then assert(not template,'duplicate Scythe progression');template=row end
 end
 assert(template and u32(template,4)==24 and u32(template,8)==2 and u32(template,12)==SCYTHE and u32(template,104)==25,'upgrade template mismatch')
 local manager_addr=root+0x178a4ec;local manager=assert(read(manager_addr,512*148))
 local manager_index
 for i=0,511 do
  local row=manager:sub(i*148+1,(i+1)*148)
  assert(u32(row,0)~=SHEAR,'Shear manager already exists; disable standalone Shear mod')
  if not manager_index and row==zeros(148) then manager_index=i end
 end
 assert(manager_index,'no empty weapon manager slot')
 local manager_target=manager_addr+manager_index*148;local manager_old=zeros(148)
 local records_addr=root+0x1ce4+count_n*184;local maps_addr=root+0xb9ce4+count_n*24
 local records_old=assert(read(records_addr,7*184));local maps_old=assert(read(maps_addr,7*24))
 assert(records_old==zeros(7*184) and maps_old==zeros(7*24),'registry append area occupied')
 assert(count_n+7<=4096 and 0x1ce4+4096*184==0xb9ce4,'registry capacity mismatch')
 -- Read all settings and independently check the exact slot filter before any writes.
 local settings_slot=rip(0x11f4697,string.char(0x4c,0x8d,0x1d))
 local group_count_bytes=assert(read(base+0x11f468a,6))
 assert(group_count_bytes:sub(1,2)==string.char(0x8b,0x3d),'settings count opcode')
 local disp=u32(group_count_bytes,2);if disp>=0x80000000 then disp=disp-0x100000000 end
 local settings_count=u32(assert(read(base+0x11f468a+6+disp,4)),0)
 assert(settings_count==9,'settings group count changed')
 local allowed={}
 for j=0,9 do allowed[u32(model,0x50+j*4)]=true end
 local found={}
 local muzzle_addr,muzzle_original,standard_name
 for g=0,settings_count-1 do
  local header=assert(read(assert(ptr(settings_slot+g*8)),16))
  local row_count=u32(header,8);assert(row_count<=256,'settings row bound')
  local rows=assert(read(u64at(header,0),row_count*88))
  for j=0,row_count-1 do
   local row=rows:sub(j*88+1,(j+1)*88);local id=u32(row,8)
   if id==0xd65dc159 then
    assert(not muzzle_addr and u32(row,12)==0x37709874,'Shear muzzle text record changed')
    muzzle_addr=u64at(header,0)+j*88;muzzle_original=row
   elseif id==0xe917f79b then
    assert(not standard_name and u32(row,12)==0x6113b753,'standard laser muzzle text changed')
    standard_name=row:sub(13,16)
   end
   for _,item in ipairs(items)do if id==item.attachment then
    local n=u32(row,0x38);assert(n>=1 and n<=10,'attachment slots invalid')
    local slots=assert(read(u64at(row,0x30),n*4));local first=u32(slots,0);local accept=false
    for s=0,n-1 do local st=u32(slots,s*4);if st==first and st>=1 and st<=9 and allowed[st]then accept=true end end
    assert(accept and first==item.slot,'native slot filter rejects '..item.name)
    assert(not found[id],'duplicate attachment settings');found[id]=true
   end end
  end
 end
 for _,item in ipairs(items)do assert(found[item.attachment],'attachment settings missing: '..item.name)end
 emit('SETTINGS_FILTER_VERIFIED all7 attachment IDs have native-compatible slots')
 assert(muzzle_addr and muzzle_original and standard_name,'muzzle name source unavailable')
 local muzzle_expected=replace(muzzle_original,12,standard_name)
 local new_records,new_maps,grants={},{},{}
 for i,item in ipairs(items)do
  assert(not map_by_key[item.key],'Shear attachment already registered: '..item.name)
  local source_map=assert(map_by_key[item.sourceKey]);assert(source_map==unhex(item.mapping),'template mapping changed: '..item.name)
  local source_record=assert(read(root+0x1ce4+item.sourceIndex*184,184))
  local canonical_record=unhex(item.record)
  assert(#canonical_record==184,'canonical layout invalid: '..item.name)
  -- The first16 bytes identify this record; the remaining bytes include player state.
  assert(source_record:sub(1,16)==canonical_record:sub(1,16)
   and u32(source_record,0)==item.sourceIndex
   and u32(source_record,4)==item.sourceKey
   and u32(source_record,8)==u32(source_map,8)
   and u32(source_record,12)==2,'template identity changed: '..item.name)
  local owner_index=item.sourceIndex-u32(source_map,16)
  local owner_record=assert(read(root+0x1ce4+owner_index*184,16))
  local owner_map=assert(read(root+0xb9ce4+owner_index*24,24))
  assert(owner_index==226 and u32(owner_record,0)==226
   and u32(owner_record,4)==SCYTHE and u32(owner_record,8)==SCYTHE
   and u32(owner_record,12)==1 and u32(owner_map,4)==SCYTHE
   and u32(owner_map,8)==SCYTHE,'template owner changed: '..item.name)
  local changed={}
  for offset=16,180,4 do
   if u32(source_record,offset)~=u32(canonical_record,offset)then
    changed[#changed+1]=string.format('%#x:%#x->%#x',offset,u32(canonical_record,offset),u32(source_record,offset))
   end
  end
  emit(string.format('TEMPLATE_IDENTITY_VERIFIED item=%s source_state=%d owner=%#x; canonical layout used; state_differences=%s',
   item.name,u32(source_record,20),SCYTHE,#changed>0 and table.concat(changed,',')or'none'))
  local idx=count_n+i-1
  local row=replace(replace(replace(canonical_record,0,le32(idx)),4,le32(item.key)),8,le32(item.attachment))
  row=replace(replace(row,20,le32(2)),176,le32(1))
  new_records[#new_records+1]=row
  -- Native filter 0x13706B4 subtracts +0x10 rows to reach the owning weapon.
  -- Both offsets agree in all 2928 captured original mappings.
  local parent_delta=idx-shear_index
  local new_map=replace(replace(replace(source_map,0,le32(idx)),4,le32(item.key)),8,le32(item.attachment))
  new_map=replace(replace(new_map,12,le32(parent_delta)),16,le32(parent_delta))
  assert(idx-u32(new_map,16)==shear_index and idx-u32(new_map,12)==shear_index,'attachment owner mismatch')
  new_maps[#new_maps+1]=new_map
  if i<=5 then grants[#grants+1]=le32(1)..le32(item.key)..le32(1)end
  emit(string.format('PREPARED attachment=%s id=%#x composite=%#x append_index=%d; source metadata inherited; parent deltas rebuilt for Shear',item.name,item.attachment,item.key,idx))
 end
 local manager_new=replace(zeros(148),0,le32(SHEAR))
 for t=0,2 do for i=1,5 do local item=items[i];manager_new=replace(manager_new,12+t*40+item.slot*4,le32(item.attachment))end end
 local levels_offset=math.ceil(((group_count+1)*112)/4096)*4096
 local slab=k.VirtualAlloc(nil,levels_offset+0x2000,0x3000,4);assert(slab~=nil,'scratch allocation failed')
 local slab_addr=tonumber(ffi.cast('uintptr_t',slab));public.slab=slab_addr
 local new_levels_addr,new_grants_addr=slab_addr+levels_offset,slab_addr+levels_offset+0x1000
 local new_branches_addr=slab_addr+levels_offset+0x1100
 local branches=unhex('852a8aee0100000000000000ec0e15d70000000000000000000000000000000000000000000000000000000001000000546156400100000000000000ec0e15d70000000000000000000000000000000000000000000000000000000001000000')
 local level=le32(1)..le32(10)..le32(3)..zeros(0x848-12)
 level=replace(replace(level,0x828,packptr(new_grants_addr)),0x830,le32(5))
 level=replace(replace(level,0x838,packptr(new_branches_addr)),0x840,le32(2))
 local new_group=replace(replace(replace(replace(template,0,le32(0xd62dc83d)),12,le32(SHEAR)),96,packptr(new_levels_addr)),104,le32(1))
 local new_rows=original_rows..new_group
 assert(write(new_grants_addr,table.concat(grants)) and write(new_branches_addr,branches) and write(new_levels_addr,level) and write(slab_addr,new_rows),'scratch initialization/readback failed')
 emit('PREPARED isolated single-level group; existing groups copied unchanged; two selectable Shear heatsink branches; display metadata inherited from Scythe; no purchases required')
 local operations={
  {addr=muzzle_addr+12,old=muzzle_original:sub(13,16),new=standard_name,name='Shear_muzzle_display_name_only'},
  {addr=records_addr,old=records_old,new=table.concat(new_records),name='attachment_records'},
  {addr=maps_addr,old=maps_old,new=table.concat(new_maps),name='attachment_mappings'},
  {addr=manager_target,old=manager_old,new=manager_new,name='Shear_manager'},
  {addr=progression+8,old=ph:sub(9,16),new=packptr(slab_addr),name='progression_rows_pointer'},
  {addr=progression+16,old=ph:sub(17,20),new=le32(group_count+1),name='progression_count'},
  {addr=root+0x1ce0,old=count,new=le32(count_n+7),name='registry_count'}
 }
 for _,op in ipairs(operations)do assert(writable(op.addr,#op.new),'target not writable: '..op.name);assert(read(op.addr,#op.old)==op.old,'target changed: '..op.name)end
 assert(ptr(item_slot)==root and ptr(progression_slot)==progression,'root changed before transaction')
 local attempted={}
 local success,why=pcall(function()
  for _,op in ipairs(operations)do
   assert(ptr(item_slot)==root and ptr(progression_slot)==progression,'root changed during transaction')
   assert(read(root+0x1ce0,4)==count,'registry count changed during transaction')
   assert(read(op.addr,#op.old)==op.old,'target changed before write: '..op.name)
   attempted[#attempted+1]=op;assert(write(op.addr,op.new),'write/readback failed: '..op.name)
   emit('WRITE_VERIFIED '..op.name)
  end
  for _,op in ipairs(operations)do assert(read(op.addr,#op.new)==op.new,'final readback failed: '..op.name)end
  assert(read(slab_addr,group_count*112)==original_rows,'existing groups changed')
  assert(read(cfg,0x1308)==model,'Shear model data changed')
  assert(read(muzzle_addr,88)==muzzle_expected,'muzzle settings changed beyond name key')
  emit('MUZZLE_TEXT_VERIFIED attachment=D65DC159 name_key=6113B753; standard laser muzzle label reused; other84 bytes preserved, only4 bytes changed')
  for i,item in ipairs(items)do
   local index=count_n+i-1
   local m=assert(read(root+0xb9ce4+index*24,24))
   local parent=index-u32(m,16)
   local owner=assert(read(root+0xb9ce4+parent*24,24))
   assert(parent==shear_index and u32(owner,4)==SHEAR and u32(owner,8)==SHEAR,'native parent filter rejects '..item.name)
   assert(u32(m,8)==item.attachment and u32(m,4)==item.key,'published attachment key mismatch')
   emit(string.format('OWNER_FILTER_VERIFIED item=%s index=%d delta=%d parent=%d owner=%#x',item.name,index,u32(m,16),parent,SHEAR))
  end
 end)
 if not success then
  local restored=ptr(item_slot)==root and ptr(progression_slot)==progression
  local actual=read(root+0x1ce0,4)
  restored=restored and (actual==count or actual==le32(count_n+7))
  if restored then for i=#attempted,1,-1 do
   local op=attempted[i]
   if ptr(item_slot)~=root or ptr(progression_slot)~=progression then restored=false;break end
   local current=read(op.addr,#op.new)
   -- A failed write may have copied only a prefix. Never replace unrelated data.
   local owned=current==op.new or current==op.old
   if not owned and current then
    for cut=1,#op.new-1 do if current==op.new:sub(1,cut)..op.old:sub(cut+1) then owned=true;break end end
   end
   if not owned then restored=false;break end
   local rb=write(op.addr,op.old);restored=restored and rb;emit('ROLLBACK '..op.name..' '..tostring(rb))
   if not rb then break end
  end end
  done=true;finish('failed: '..tostring(why)..'; rollback='..tostring(restored));return
 end
 done=true;public.status='active'
 -- Register undo steps (replayed in reverse by shutdown) so the engine never tears down our slab/records.
 for _,op in ipairs(operations)do
  journal.push('shear@'..op.name,function()
   if ptr(item_slot)~=root or ptr(progression_slot)~=progression then return false end
   if read(op.addr,#op.new)~=op.new then return false end
   return write(op.addr,op.old)
  end)
 end
 emit('BRANCH_GATE_VERIFIED level_count=1 grant_count=5 branch_count=2; branch keys=EE8A2A85/40566154')
 public.registry_root=root;public.progression_root=progression;public.owner_index=shear_index
 emit(string.format('SUCCESS: Shear customization; groups=%d manager=%d owner=%d registry=%d; seven attachments; game test required',group_count+1,manager_index,shear_index,count_n+7))
 -- Keep this log open for package lifecycle observations.
end
local previous=rawget(_G,'update');local wrapper
wrapper=function(...)
 if not done then local good,why=pcall(tick);if not good then done=true;finish('disabled: '..tostring(why))end end
 if done and public.status=='active' and not lease_disabled then
  local good,why=pcall(lease_tick)
  if not good then
   lease_disabled=true
   local restored,reason=pcall(release_owned_packages)
   emit('HEATSINK_PACKAGE_DISABLED '..tostring(why)..'; release='..tostring(restored)..'; '..tostring(reason))
  end
 end
 if done and public.status~='active' and rawget(_G,'update')==wrapper then rawset(_G,'update',previous)end
 return previous(...)
end
local previous_shutdown=rawget(_G,'shutdown')
rawset(_G,'shutdown',function(...)
 done=true;lease_disabled=true
 local released,why=pcall(release_owned_packages)
 emit('SHUTDOWN_RELEASE heatsink packages ok='..tostring(released)..(released and '' or ' '..tostring(why)))
 local ran,restored,skipped=pcall(journal.run)
 if ran then
  emit('SHUTDOWN_RESTORE writes undone='..tostring(restored)..' skipped='..tostring(skipped)..'; original registry and progression restored before engine teardown')
 else
  emit('SHUTDOWN_RESTORE_ERROR '..tostring(restored))
 end
 if public.status=='active' then public.status='shutdown: original state restored' end
 if previous_shutdown then return previous_shutdown(...) end
end)
rawset(_G,'update',wrapper);public.status='waiting'
emit('waiting for available Shear; dynamic registry count and owner; seven attachments plus heatsink package leases')
return public
