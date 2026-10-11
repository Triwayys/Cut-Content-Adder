> Historical v0.1.12 evidence. For the v0.1.13 additions and current scope, see VARIANT-AUDIT.md and Source/catalogue.json.

# KDM index repair evidence — v0.1.12

The user supplied the exact-build game.dll and a complete loaded-code snapshot:
41,921,039 bytes captured, zero unreadable chunks. The snapshot and DLL are not
redistributed. Only a 90-byte lookup routine used by the offline replay is bundled.

## Observed failure
The v0.1.10 diagnostic contains one stable inventory record for each KDM body
and helmet, with status 2 in both captures. The records are not being reset.
All four native kit identities also validate. Yet the user sees neither set.

## Missing operation found in the captured code
At RVA 0x18d81e2, the armour menu searches cosmetics through category boundaries
at registry +0xd1cf0/+0xd1cf4, and a position array at +0xd1d48. Failure to find
a kit makes it try a set-ID entry and then skip the item. A standalone inserted
kit has no parent set inventory record to rescue that lookup.

The reusable lookup at 0x13720c0 uses the same category-index mechanism.
The native builder at 0x136e6a0 groups records by their type (+12 in a 184-byte
row), writes 24 category starts at +0xd1ce4 and total count at +0xd1d44, and
fills the 32-bit mapping-position array at +0xd1d48.

Previous combined versions updated the inventory count, rows and mappings but
never this secondary index. This is a concrete implementation omission. The
prior snapshots did not capture the live index itself; the offline before-state
is reconstructed from the user's 2928 original registry headers using the native
grouping algorithm. The test then inserts the four captured KDM records and
runs the actual lookup machine code before and after repair.

## Repair
Source/category_index.lua reconstructs the same stable type grouping after
unlock operations, provided the live schema and existing membership validate.
It only writes index positions and boundaries. All inventory row bytes, maps,
status flags and entitlements remain unchanged by this operation. Unexpected
row/map alignment, invalid types, inconsistent membership or modified native
signatures make it refuse the write. Partial writes roll back through the
existing transaction mechanism. Native code is neither called nor patched.

## What is and is not proven
The actual category lookup now resolves all four IDs in offline emulation.
Regression tests preserve ordinary locked records and Shear functionality.
This does not prove that every later menu/asset condition succeeds on the user's
PC. In-game confirmation of listing, preview and equipping remains necessary.
The successful lookup is stronger evidence than the earlier inventory-write
success count, but is not described as a completed gameplay test.
