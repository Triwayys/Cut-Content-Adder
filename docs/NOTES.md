# Cut Content Adder v1.0

By Triways. See CREDITS.md for the original authors and sources this build relies on.

## v1.0 — crash on exit fix
Closing the game used to crash (access violation inside helldivers2.exe) because both
components modified live game memory (inventory registry, category index, Shear progression
rows pointer, heatsink package references) and never restored it before the engine tore
those structures down. Every verified write is now journaled and `shutdown()` replays the
journal in reverse order, then releases the heatsink package references. A value the game
changed itself is never overwritten, and nothing is written if the registry was replaced.
Check `HiddenEquipmentCombined.log` / `LAS22ShearCustomizationExperimentM4.log` after
quitting for `SHUTDOWN_RESTORE writes undone=N skipped=0`. Not game-tested.

Carries forward the five v0.1.14 cape additions and adds eight named cape definitions identified in the latest screenshots. The added records use captured-build kit and archive identities. In-game preview and equipping remain unconfirmed.

Retains 45 hidden armour/helmet variants by distinct kit ID. See VARIANT-AUDIT.md. Shared in-game names remain unchanged. Appearance and equipping are not game-tested.

Retains the category-index update after inventory insertion. The armour
menu uses this secondary index to find cosmetic equipment; previous versions
only appended the inventory records and therefore did not make newly inserted
KDM entries discoverable through that lookup.

This is an evidence-based fix, verified offline with the captured game's actual
lookup instructions. In-game visibility, preview and equipping still require
confirmation. It is not another full code-capture build.

## Install
1. Fully exit Helldivers 2. Replace the previous combined mod with this ZIP.
2. Disable overlapping unlockers and standalone Shear customization mods.
3. Keep Bingus Shared Loader enabled (API 1, interface version 16+; supplied
   v17 accepted). Put Bingus last with Arsenal default priority, first with
   first-mod priority.
4. Purge and Deploy, then launch. Allow about one minute for initialization.
5. Enter the ship and reopen the armour and helmet lists. Check KDM-763
   Pacesetter and KDM-73 Dragoon, both body and helmet.

If either is absent, send HiddenEquipmentCombined.log. No further code snapshot
is requested. In the log, 'armoury category index: OK: rebuilt ...' or 'OK: current'
confirms index handling. WAIT/SKIP explains a rejected guard. The item summary
still measures inventory state, not proven UI visibility.

Requires exact Steam build 25480438 / EXE 1.8.46015.0. No Mod Options Menu or
HD2Runtime dependency. Changes are local runtime changes, not account ownership.

## Screenshot-identified additions

Adds eight cape kit definitions from the captured build, matched to named items
shown in the latest screenshots: Beacon of Mercy, Bugslayer, Defender of our
dream (the screenshot displays “Defender of the Wall”), Vector of Victory,
Podium of Prosperity, Tyranny’s Bane and two distinct Agent of Oblivion
definitions. Kit and archive identities are exact; in-game preview/equipping
remains unconfirmed. Unnamed screenshot items are not guessed.

## Unnamed screenshot candidates

Adds three exact captured-build cosmetic definitions for further in-game
identification: two armour candidates (TBD and unidentified) and one TBD
helmet. Their IDs, archive hashes and kit types are verified against the
captured data, but they cannot yet be mapped to a particular screenshot model.
The existing runtime guards validate each definition before changing its
availability.

## Unidentified cape candidates

Adds six cape definitions with exact IDs but unresolved visual identities. One
may be the no-cape model shown in the screenshots; this cannot be established
from the captured catalogue alone. Check the in-game thumbnails to identify
which entry (if any) is the empty cape.

## Scope retained
117 explicit targets: 5 personal weapons/throwables, 4 stratagems, 25 armour
bodies, 47 helmets and 36 capes. See ITEM-CATALOGUE.md and Source/catalogue.json.
- Shear, Ombudsman, Caltrops, Hyena and commemorative Constitution.
- Eagle Gas Airstrike, Supply FRV, Incinerator FRV and Maelstrom.
- KDM-763, KDM-73, KDM-500, Gold Eagle, Model Citizen, preorder sets,
  promotional/special armour and selected experimental hidden definitions.
- Event/campaign capes and six unreleased-labelled cape definitions.
- Previous working Shear customization, unchanged byte-for-byte.

Illumination flare remains removed. Ordinary warbond, Superstore, requisition
and collaboration warbond equipment are not unlock targets. Updating the
inventory index does not change their ownership/availability flags. The fix
indexes existing records of every type so their current states remain correctly
represented; it does not grant those items.

## Technical safeguards and limits
The fix uses three exact loaded-code signatures, root/count/readability checks,
row/map alignment checks, type bounds, existing index membership validation,
write readback and rollback. It reproduces the native category grouping into
existing reserved storage. No game code is patched and no native function is
called. It also handles subsequent Shear attachment appends.

76 cosmetic targets were in the original captured registry; 15 require guarded
insertion. Unfinished entries may still lack working previews or assets. APC,
mission-only tools, NPC equipment, emotes, titles and other unsupported content
remain outside scope. This is not an exhaustive unlock of every game object.

## Validation
- Seven new category-index checks: KDM lookup, unchanged record/ownership bytes,
  preserved existing memberships, repeat application, rollback, invalid-layout
  rejection and later attachment insertion.
- Four actual-game machine-code lookup replays: all KDM IDs absent before repair,
  all four resolve afterwards in the emulator.
- 62 registry/cosmetic, six native/catalogue, four scope, ten customization and
  ten loader checks passed for this revision.

Run tests from this directory with LuaJIT. Native lookup replay additionally
requires Python unicorn and the /tmp fixtures produced by category_tests.lua.
Rebuild with python3 build_mod.py. REPAIR-EVIDENCE.md explains the diagnosis.
