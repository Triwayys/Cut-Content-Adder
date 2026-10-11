> Historical v0.1.12 evidence. For the v0.1.13 additions and current scope, see VARIANT-AUDIT.md and Source/catalogue.json.

# v0.1.12 update

See REPAIR-EVIDENCE.md for the category-index fix. Illumination flare remains removed. The following scope research describes the retained special-only selection.

# Scope correction and evidence — 9 October 2026

v0.1.8 incorrectly treated the whole inspected equipment catalogue as a wanted
unlock list. v0.1.9 uses an explicit special/hidden-only list and removes 560
runtime targets. It does not simply exclude armour while retaining normal
weapons or stratagems. Ordinary Superstore, requisition and collaboration warbond
items are excluded too, to preserve normal progression.

## Official acquisition cross-checks
The ordinary Exo Experts mechs (Lumberer and Breakthrough), Ironclad Democracy
weapons/armour, and Castellan's Creed collaboration equipment are not hidden
rewards. They have published warbond acquisition routes and are excluded.
- https://blog.playstation.com/2026/04/21/helldivers-2-the-exo-experts-warbond-drops-april-28/
- https://blog.playstation.com/2026/09/15/helldivers-2-ironclad-democracy-warbond-launches-sept-22/
- https://news.xbox.com/en-us/2026/08/07/helldivers-2-x-warhammer-40000-warbond-xbox/
- https://arrowhead.zendesk.com/hc/en-us/articles/24179640976796-Killzone-Collab-Free-Killzone-warbond-unlock

Arrowhead identifies Gold Eagle, Model Citizen, ten limited/event capes and the
three preorder sets. Those remain included, as does the earlier Message of
Morale target. Campaign documentation identifies Hyena, Supply FRV, both KDM-500
pieces, IX-Voidwalker, Eagle Gas and Maelstrom. Those remain included.
- https://arrowhead.zendesk.com/hc/en-us/articles/15980844977820-Can-I-still-obtain-time-limited-items-and-capes-Or-pre-order-armor
- https://arrowhead.zendesk.com/hc/en-us/articles/29563053705500-I-didn-t-get-a-campaign-reward

Historical promotional/commemorative items (Alpha Commander, DP-00 and
Constitution) are retained as special rewards. This is not a claim that every
historical reward is currently unobtainable. Purchased Super Citizen equipment
and currently obtainable collaboration warbond gear are excluded.

## Technical sources and evidence limits
The previous catalogue used Filediver kits.dl_bin (411 cosmetic definitions),
HD2Runtime's same-executable armour/stratagem metadata, SHODAN personal weapon
model identifiers, English name data and community archive labels. The user's
2928-record inventory capture provides exact existing record identities.

- Filediver: https://github.com/xypwn/filediver
  commit 9f92623133cde32b1167e13f05ce6c4825805ccf
- HD2Runtime: https://github.com/SkyeShade/HD2Runtime
  commit dcd996daca2573443956c07252c55c2d86dd0320
  snapshot executable prefix F5FEE03DCFDB
- SHODAN: https://github.com/SHODAN-HORAI/SHODAN-Stat-Editor
  commit 67b7879d8501b6138d52e06ac920dc8a8dfb306c
- English names: https://github.com/DiegoPincheiraIb/HelldiversData
  commit 618d871c3a83c49c3ebd91bcb0e122fea0a95b0c
- Community archive labels:
  https://docs.google.com/spreadsheets/d/1oQys_OI5DWou4GeRE3mW56j7BIi4M7KftBIPAl1ULFw/edit

Both KDM-763 and KDM-73 body/helmet definitions are identified but absent in the
captured inventory. They retain guarded standalone insertion. B-16, B-02 and
six explicitly unreleased-labelled capes remain experimental data-derived
targets; their labels are not official confirmation of future release or usable
assets. Their inventory identities are listed in ITEM-CATALOGUE.md.

No entire installation archive scan was performed. These catalogues do not
establish that every hidden game object was found, classified or made usable.
Unknown/TBD definitions and unexplained variants are intentionally held out;
see COVERAGE-AUDIT.md. Mission-only tools, NPC-only weapons, unsupported APC,
other customization, boosters, player cards, titles, emotes and vehicle skins
are not covered. The package must not be advertised as unlocking absolutely
everything in the files.

CAPE-RESEARCH.md and PREORDER-RESEARCH.md are historical research notes; current
implementation and scope are defined by this README and Source/catalogue.json.
