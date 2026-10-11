# Cut Content Adder

**By Triways.** A Helldivers 2 mod that unlocks cut, hidden and unreleased content already present in the game files: weapons, stratagems, armour sets, helmets and capes, plus customization for the LAS-22 Shear.

Version **1.0**, verified against Steam build **25480438** only. In-game confirmation of some items is still pending (see below).

## What it unlocks

117 items in total, plus 7 LAS-22 Shear attachments:

| Category | Count |
| --- | --- |
| Weapons (R-4 Hyena, LAS-22 Shear, P-41 Ombudsman, G-11 Caltrops, R-2124 Constitution) | 5 |
| Stratagems (Eagle Gas Airstrike, M-103 Supply FRV, TD-110 Maelstrom, M-104 Incinerator FRV) | 4 |
| Armours | 25 |
| Helmets | 47 |
| Capes | 36 |
| LAS-22 Shear attachments (flashlight, optic, stock, muzzle, standard, extended and rapid heatsinks) | 7 |

The full catalogue is in [`Source/catalogue.json`](Source/catalogue.json) and [`docs/ITEM-CATALOGUE.md`](docs/ITEM-CATALOGUE.md). 32 of the items are verified in the inventory but their visibility in the armoury menus is **unconfirmed**; some cosmetics have no confirmed in-game name yet.

## Requirements

- Helldivers 2, Steam build 25480438 (the mod disables itself on any other build).
- [Bingus Shared Loader](https://github.com/CowboyBingus) (API 1, interface version 16 or newer). Not bundled.

## Install

1. Fully exit Helldivers 2.
2. Add the mod zip from the Releases page to your mod manager (Arsenal) and deploy it.
3. Disable any older Hidden Equipment Combined, standalone Shear unlock or Shear customization mods, so only one copy is active.
4. Start the game. The first line of `HiddenEquipmentCombined.log` should read `LOADED v1.0`.

## v1.0: clean shutdown

Earlier builds crashed when the game was closed. The mod edits live game memory (inventory registry, category index, Shear progression pointer, package references) and never put it back before the engine tore those structures down. Every verified write is now journaled, and `shutdown()` undoes them in reverse order before releasing the package references. A value changed by the game itself is never overwritten.

After closing the game, the log shows:

```
SHUTDOWN_RESTORE writes undone=N skipped=0; original registry restored before engine teardown
```

## Build and test

Rebuild the addon archives from the Lua sources (Python 3, standard library only):

```
python3 build_mod.py
```

Run the tests with LuaJIT from the repository root:

```
luajit Tests/registry_tests.lua
luajit Tests/category_tests.lua
luajit Tests/customization_tests.lua
luajit Tests/shutdown_tests.lua
```

(also `scope`, `native`, `vehicle` and `diagnostic` tests). They run against synthetic or captured fixtures, not against the game.

## Credits and licence

See [CREDITS.md](CREDITS.md). The LAS-22 Shear customization is adapted from the original *LAS-22 Shear Unlock & Customization* mod by boring, and the identifiers come from several community research projects listed there. This repository does not grant any licence over that derived code. Game assets belong to their respective owners, and none are included. Not affiliated with Arrowhead or Sony.
