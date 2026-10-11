-- HD2-Addon: mods/codex/hidden_equipment_combined
-- Combined hidden equipment unlocks; build 25480438 only; in-game testing pending.
local VERSION = '1.0'
local GAME_SHA256 = '2e2c3b7c2500646dadd5f2b4c6e0504dbb7e7896139f64cddc0d1813c718f51e'
local EXE_SHA256 = 'f5fee03dcfdb2e553a4752c283590950ac13316b376d8196aa556ff0400d5f06'
local NAME = 'HiddenEquipmentCombined'
local prior = rawget(_G, NAME)
if prior then return prior end
local public = {version = VERSION, status = 'initializing'}
rawset(_G, NAME, public)

local loader = rawget(_G, 'CowboyBingusModLoader')
local log
if type(loader) == 'table' and type(loader.open_log) == 'function' then
    local ok, handle = pcall(loader.open_log, 'HiddenEquipmentCombined.log')
    if ok then log = handle end
end
local function emit(message)
    local line = '[HiddenEquipmentCombined] ' .. message
    pcall(print, line)
    if log then pcall(function() log:write(line .. '\n'); log:flush() end) end
end
local function finish(message)
    public.status = message
    emit(message)
    if log then pcall(function() log:close() end); log = nil end
end
if type(loader) ~= 'table' or loader.api ~= 1 or (tonumber(loader.version) or 0) < 16 or type(loader.open_log) ~= 'function' then
    finish('disabled: incompatible Bingus interface; require API 1, interface version 16+, open_log. Observed api='..tostring(type(loader)=='table' and loader.api)..'; interface_version='..tostring(type(loader)=='table' and loader.version))
    return public
end
if type(rawget(_G, 'update')) ~= 'function' then
    finish('disabled: update callback unavailable')
    return public
end

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

local function initialize()
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
    if type(bytes) ~= 'string' then return nil end
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




ffi.cdef [[
uint64_t GetTickCount64(void);
int WriteProcessMemory(void *, void *, const void *, size_t, size_t *);
]]
local game=k.GetModuleHandleA('game.dll')
if game==nil then finish('disabled: game.dll unavailable');return public end
local base=tonumber(ffi.cast('uintptr_t',game))
local ok,hash=pcall(sha256_of_module,base)
local exok,exhash=pcall(sha256_of_module,k.GetModuleHandleA(nil))
if not ok or hash~=GAME_SHA256 or not exok or exhash~=EXE_SHA256 then finish('disabled: build mismatch; expected Steam 25480438. game.dll='..tostring(hash)..'; exe='..tostring(exhash));return public end
local function now()return tonumber(k.GetTickCount64())/1000 end
local function ptr(a)local b=read(a,8);return b and u64at(b,0)end
local function hex(b)return (b:gsub('.',function(c)return string.format('%02X',c:byte())end))end
local function rip(rva,op)
 local b=read(base+rva,7);assert(b and b:sub(1,3)==op,'root instruction mismatch')
 local d=u32(b,3);if d>=0x80000000 then d=d-0x100000000 end
 return base+rva+7+d
end
local item_slot=rip(0x136fdf0,string.char(0x48,0x8b,0x05))
local class_slot=rip(0x11e7c65,string.char(0x48,0x8b,0x1d))
local SHEAR,SCYTHE=0x7de53646,0xe673dcc8
local expected_class=le32(SHEAR)..le32(0)..string.char(0x48,0xb9,0xa4,0xba,0xa5,0x45,0x31,0x7e)..le32(1)..string.rep('\0',12)
local function writable(addr,len)
 local rb,rs,state,prot,kind=region(addr)
 return rb and addr+len<=rb+rs and state==0x1000 and prot==4 and kind==0x20000
end
local function write(addr,b)
 if not writable(addr,#b)then return false end
 local count=ffi.new('size_t[1]')
 local buf=ffi.new('uint8_t[?]',#b);ffi.copy(buf,b,#b)
 return k.WriteProcessMemory(process,ffi.cast('void *',addr),buf,#b,count)~=0 and tonumber(count[0])==#b and read(addr,#b)==b
end
local function replace32(b,off,v)return b:sub(1,off)..le32(v)..b:sub(off+5)end
