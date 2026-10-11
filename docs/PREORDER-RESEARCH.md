# Preorder armor additions (v0.1.7)

Six existing cosmetic records were matched against the user-supplied build
25480438 registry dump and Filediver kit data. All six captured records have
cosmetic type 3 and locked status 1. Armor and helmets use distinct paired
record/equipment IDs; cape-style equal-ID matching would miss these records.

| Item | Equipment ID | Record ID |
| --- | --- | --- |
| TR-9 Cavalier of Democracy | 0x940716D6 | 0xA1B3B1EA |
| TR-9 Cavalier of Democracy helmet | 0xEEB4C2DE | 0x42E83319 |
| TR-7 Ambassador of the Brand | 0x8A957897 | 0x1D8DF49E |
| TR-7 Ambassador of the Brand helmet | 0x35E8934F | 0x754ACEFC |
| TR-62 Knight | 0x7346EDC6 | 0xACCD0081 |
| TR-62 Knight helmet | 0x3313A0EC | 0xA09B928C |

Sources: user-provided HiddenEquipmentRegistry(1).log; Filediver kit dataset
at https://github.com/xypwn/filediver/tree/e5c4b91fcc02c04aed05dfac3136d7de23004526
(generated_customization_armor_sets.dl_bin). Captured headers are included in
Tests/live_preorder_fixture.json and .lua.

Implementation changes only each verified existing record's availability field
from 0 or 1 to 2. It preserves already available states 2 and 4, requires matching
map and row identities and type, and never appends missing armor records.
No DLC entitlement is granted. Asset availability and any further menu gating
must be checked in game; offline tests cannot establish those.

The Shear customization companion source and archive are unchanged from v0.1.6.
