"""Rebuild the data-only addon from the supplied Lua sources; Python 3 stdlib."""
from pathlib import Path
import hashlib
import json
import struct

ROOT = Path(__file__).resolve().parent
MODULE = 'mods/codex/hidden_equipment_combined'

def resource_hash(data):
    mask, m = (1 << 64) - 1, 0xc6a4a7935bd1e995
    h = len(data) * m & mask
    end = len(data) // 8 * 8
    for i in range(0, end, 8):
        k = int.from_bytes(data[i:i+8], 'little') * m & mask
        k ^= k >> 47
        k = k * m & mask
        h ^= k
        h = h * m & mask
    if data[end:]:
        h ^= int.from_bytes(data[end:], 'little')
        h = h * m & mask
    h ^= h >> 47
    h = h * m & mask
    return h ^ (h >> 47)

def build():
    src = ROOT / 'Source'
    source = (src / 'runtime_prefix.lua').read_text(encoding='utf-8')
    source += '\nlocal Core=(function()\n' + (src / 'registry_core.lua').read_text(encoding='utf-8')
    source += '\nend)()\nlocal Native=(function()\n' + (src / 'native_catalogue.lua').read_text(encoding='utf-8')
    source += '\nend)()\nlocal Diagnostics=(function()\n' + (src / 'kdm_diagnostics.lua').read_text(encoding='utf-8')
    source += '\nend)()\nlocal CategoryIndex=(function()\n' + (src / 'category_index.lua').read_text(encoding='utf-8')
    source += '\nend)()\n' + (src / 'runtime_suffix.lua').read_text(encoding='utf-8')
    payload = source.encode('utf-8')
    assert payload.startswith(('-- HD2-Addon: ' + MODULE + '\n').encode())
    (src / 'hidden_equipment_combined.lua').write_bytes(payload)
    header = bytearray((ROOT / 'archive_header.bin').read_bytes())
    assert len(header) == 200
    size = (len(payload) + 200 + 15) & ~15
    struct.pack_into('<Q', header, 32, size)
    struct.pack_into('<Q', header, 104, resource_hash(MODULE.encode()))
    struct.pack_into('<I', header, 160, len(payload) + 8)
    struct.pack_into('<I', header, 192, len(payload))
    archive = bytes(header) + payload + bytes(size - 200 - len(payload))
    path = ROOT / 'Addon' / '9ba626afa44a3aa3.patch_0'
    path.parent.mkdir(exist_ok=True)
    path.write_bytes(archive)
    for suffix in ['.stream', '.gpu_resources']:
        Path(str(path) + suffix).write_bytes(b'')
    assert archive[200:200+len(payload)] == payload
    # Loader v17 reads resource size at table +56 (104 +56), NOT +64.
    resource_offset = struct.unpack_from('<Q', archive, 120)[0]
    resource_size = struct.unpack_from('<I', archive, 160)[0]
    assert resource_offset == 192 and resource_size == len(payload) + 8
    assert struct.unpack_from('<I', archive, 168)[0] == 0
    assert resource_offset + resource_size <= len(archive)
    companion_source = (src / 'shear_customization.lua').read_bytes()
    companion_module = companion_source.splitlines()[0].decode().split(': ', 1)[1]
    ch = bytearray((ROOT / 'archive_header.bin').read_bytes())
    csize = (len(companion_source) + 200 + 15) & ~15
    struct.pack_into('<Q', ch, 32, csize)
    struct.pack_into('<Q', ch, 104, resource_hash(companion_module.encode()))
    struct.pack_into('<I', ch, 160, len(companion_source) + 8)
    struct.pack_into('<I', ch, 192, len(companion_source))
    ca = bytes(ch) + companion_source + bytes(csize - 200 - len(companion_source))
    cp = ROOT / 'Addon' / '9ba626afa44a3aa3.patch_1'
    cp.write_bytes(ca)
    for suffix in ['.stream', '.gpu_resources']:
        Path(str(cp) + suffix).write_bytes(b'')
    assert ca[200:200+len(companion_source)] == companion_source
    assert struct.unpack_from('<I', ca, 160)[0] == len(companion_source) + 8
    return {'customization_module': companion_module,
            'customization_source_sha256': hashlib.sha256(companion_source).hexdigest(),
            'customization_patch_sha256': hashlib.sha256(ca).hexdigest(),
            'module': MODULE, 'source_sha256': hashlib.sha256(payload).hexdigest(),
            'patch_sha256': hashlib.sha256(archive).hexdigest(),
            'payload_bytes': len(payload), 'archive_bytes': len(archive),
            'archive_readback_verified': True}

if __name__ == '__main__':
    print(json.dumps(build(), indent=2))
