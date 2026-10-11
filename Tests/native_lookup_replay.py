"""Execute the captured game's actual category-lookup machine code in an emulator."""
from pathlib import Path
import struct
from unicorn import Uc,UC_ARCH_X86,UC_MODE_64
from unicorn.x86_const import UC_X86_REG_RCX,UC_X86_REG_RDX,UC_X86_REG_R8,UC_X86_REG_RSP,UC_X86_REG_RAX
code=bytes.fromhex(Path('Tests/native_category_lookup.hex').read_text())
keys=[0x1e28f118,0x71e406e4,0x1b8329ab,0xf5cb7633]
def lookup(mem,key):
 u=Uc(UC_ARCH_X86,UC_MODE_64);u.mem_map(0x100000,0x200000);u.mem_write(0x100000,mem)
 u.mem_map(0x400000,0x2000);u.mem_write(0x400000,code)
 u.mem_map(0x500000,0x2000);u.mem_write(0x501000,struct.pack('<Q',0x401000))
 u.reg_write(UC_X86_REG_RCX,0x100000);u.reg_write(UC_X86_REG_RDX,key);u.reg_write(UC_X86_REG_R8,3);u.reg_write(UC_X86_REG_RSP,0x501000)
 u.emu_start(0x400000,0x401000,count=50000)
 return u.reg_read(UC_X86_REG_RAX)
before=Path('/tmp/hd2-category-before.bin').read_bytes();after=Path('/tmp/hd2-category-after.bin').read_bytes()
for key in keys:
 assert lookup(before,key)==0
 ptr=lookup(after,key);assert ptr and struct.unpack_from('<I',after,ptr-0x100000+8)[0]==key
 print(f'PASS actual game lookup: {key:08X}, absent before / resolves after')
print('4 actual machine-code lookup replays passed; in-game UI still requires confirmation')
