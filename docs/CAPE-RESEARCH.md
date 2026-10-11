# Cape research — 7 October 2026

## Scope
Arrowhead's support article, updated 3 September 2026, explicitly lists ten
limited-time capes. Its list also includes two armour sets, which are not capes
and are not added here. Pillars of Freedom is excluded: the contemporary Steam
guide describes it as available to future recruits, not time-exclusive.

Official list:
https://arrowhead.zendesk.com/hc/en-us/articles/15980844977820-Can-I-still-obtain-time-limited-items-and-capes-Or-pre-order-armor

Event history reference:
https://steamcommunity.com/sharedfiles/filedetails/?id=3386077525
The Steam guide puts Veridical Ideology under potentially returning items;
Arrowhead's newer support article explicitly includes it in the limited list,
so it is included here. No promise about future availability is made.

## Targets
All listed item keys occur exactly once in the supplied build-25480438 registry
dump with matching mapping/record identity and cosmetic record type 3. All also
occur in Filediver's current customization-kit dataset as kit type 2 (Cape).
The two type numbers belong to different tables, not conflicting definitions.

| Cape | Event | Item key | Asset archive |
| --- | --- | --- | --- |
| Fallen Hero's Vengeance | Malevelon Creek memorial (2024) | `0x33929CAA` | `58dbd3805dc9d389` |
| Eye of Freedom | First anniversary (2025) | `0x22B66E27` | `28144646f3715e9d` |
| Emblem of Freedom | First anniversary/community event (2025) | `0x1B99D742` | `afac01a32ebc55ba` |
| Protector of the Heart | Defence of Super Earth (2025) | `0x7757D8E8` | `8e9a5756930aeedd` |
| Ingress-81 | Station-81 ARG (2025) | `0x71644FC9` | `fa5a9d6c8b6df7da` |
| Veridical Ideology | Liberty Day (2025) | `0xF024288E` | `7d2167bff3ebc3d5` |
| Against the Tyrant Cloud | Liberation of Oshaune (2025) | `0x72492837` | `25839eed0400603b` |
| Reckoning's Cheer | Festival of Reckoning (2025) | `0xB75BD5B9` | `a751b4cd139b0eb3` |
| Eye of Liberty | Second anniversary (2026) | `0x1B03E942` | `b790226862e5907f` |
| United in Equality | Victory Day / Equality-On-Sea (2026) | `0x6D9B8E21` | `6adcfaf574f098c3` |
| Message of Morale (campaign reward) | September 2026 campaign reward; separately researched | `0xE7DFE0A7` | `8e6ca1460e9f4d65` |

## Identifier evidence and limits
The runtime searches by item key, validates the live record type and changes
only its availability field. It never writes using an archive hash or a fixed
registry index. Archive hashes below were used only to identify the right kit.

- Filediver armor-set definitions and binary dataset, pinned commit
  e5c4b91fcc02c04aed05dfac3136d7de23004526:
  https://github.com/xypwn/filediver/blob/e5c4b91fcc02c04aed05dfac3136d7de23004526/datalibrary/armor_sets.go
  https://github.com/xypwn/filediver/blob/e5c4b91fcc02c04aed05dfac3136d7de23004526/datalibrary/generated_customization_armor_sets.dl_bin
- Named archive mappings maintained by the HD2 modding community:
  https://docs.google.com/spreadsheets/d/1oQys_OI5DWou4GeRE3mW56j7BIi4M7KftBIPAl1ULFw/edit?gid=446642267
  This directly identifies nine of the ten official cape names, including
  Reckoning's Cheer. The corresponding kit IDs were read from the binary.
- Localization cross-checks from shalzuth/HelldiversData and its
  DiegoPincheiraIb/HelldiversData fork cover the anniversaries, Creek,
  Protector of the Heart, Ingress-81, Veridical Ideology and United in Equality.
  https://github.com/shalzuth/HelldiversData
  https://github.com/DiegoPincheiraIb/HelldiversData
- Against the Tyrant Cloud has weaker name-to-ID evidence: its identification
  is inferred from the exact cracked internal name cape_special_gloom, whose
  MurmurHash64A upper 32 bits match kit 0x72492837, and the cape's documented
  Oshaune/Gloom event. The cape-type dataset and live registry entry are verified,
  but the visible name should be confirmed in game. It is an explicit candidate,
  not a claim of a complete localized-name cross-check.
- The additional September campaign cape ID 3890208935 (0xE7DFE0A7) was reported
  first-hand by a modder here and independently matches the cape dataset and
  the supplied live registry:
  https://www.reddit.com/r/HelldiversUnfiltered/comments/1wbvqkb/new_mo_cape_details_id_desc/
  Its Message of Morale label is matched to contemporary campaign reporting:
  https://helldivers.wiki.gg/wiki/Campaigns
  This is an extra campaign target, not one of Arrowhead's ten listed capes.

The supplied live dump marks the ten older capes as status 2 (available), and
Message of Morale as status 1 (locked). The code preserves available/owned
states, enables states 0/1, and rejects unknown states. This is not evidence
that any newly added cape has been previewed or equipped successfully.

The included live_cape_fixture.json contains only the relevant captured
headers and identifier metadata, not the full original log.
