# Credits and provenance

- **Cut Content Adder** (formerly Hidden Equipment Combined; this combined build, including the v1.0 clean-shutdown
  fix): by **Triways**.

- Original LAS-22 Shear Unlock & Customization listing by boring:
  https://ayakamods.com/mods/unlock-hidden-weapon-las-22-shear-customization.4392/
  The user supplied LAS22-Shear-Unlock-Customization-v1.0.4-English(1).zip.
  The customization Lua in this build is adapted from that supplied source;
  dynamic indices, table counts, manager selection and guarded rollback were
  added for combined-mod compatibility. Resource lease logic is retained.
- Earlier combined unlock code uses identifiers and implementation material
  from the user-supplied Unlock Kit v0.7 and Shear v1.0.4. The Unlock Kit author
  was not identified in the supplied archive; no attribution is invented.
- Bingus Shared Loader by CowboyBingus is an external dependency, not bundled.
  The supplied customization source cites ArmoryPreviewCache for native package
  API contracts: https://github.com/CowboyBingus/ArmoryPreviewCache
- Hyena name/model identifier: SHODAN-HORAI/SHODAN-Stat-Editor,
  commit fdfad898093f8adc167e357b00776c3a08c553c2. No editor implementation is bundled.
- Cape identifiers: Filediver by xypwn and contributors; HD2 Archive Labeling
  contributors; HelldiversData by shalzuth and the DiegoPincheiraIb fork.
  See CAPE-RESEARCH.md for exact sources and limits. Only identifiers and
  relevant test fixtures are bundled, not their full datasets or implementations.
- Combined integration and testing prepared with Codex assistance.

This package does not assert a new licence grant over the supplied derivative
code. Original game assets belong to their respective owners. No game asset
bundles, loader binaries, save data or server credentials are included.

## v0.1.8 catalogue expansion
Current catalogue facts additionally use SkyeShade/HD2Runtime, current
SHODAN-HORAI/SHODAN-Stat-Editor identifiers and Filediver kit metadata.
Exact commits and methods are in RESEARCH-AND-COVERAGE.md. These projects are
research sources, not new runtime dependencies. Their implementations and full
game-data dumps are not redistributed in this package.

The v0.1.12 index repair was derived from the user-supplied exact-build loaded-code snapshot. No full game DLL, memory snapshot or game assets are included.
