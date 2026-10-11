local WEAPONS={
 {name="R-4 Hyena",hi=3849937749,lo=2835179488,template_key=3866352840,category=1},
 {name="LAS-22 Shear",key=2112173638,hi=2117158309,lo=3131357512,template_key=3866352840,category=1},
 {name="P-41 Ombudsman",hi=3185701459,lo=1115697165,template_hi=98887106,template_lo=3681436834},
 {name="G-11 Caltrops",hi=694738618,lo=1835806473,template_hi=1290398391,template_lo=2242354043},
 {name="R-2124 Constitution",hi=2071323923,lo=805129382,template_key=3866352840,category=1},
}
local STRATS={
 {name="Eagle Gas Airstrike",id=126,key=4196275240,record_key=2961949068},
 {name="M-103 Supply FRV",id=26,key=2636699686,record_key=2996892424},
 {name="TD-110 Maelstrom",id=50,key=460870572,record_key=2237630340},
 {name="M-104 Incinerator FRV",id=135,key=2846457047,record_key=3657826519},
}
local COSMETICS={
 {name="DP-00 Tactical / Armour",key=1058794522,kind=0,kit_index=23,archive_hi=1032647176,archive_lo=2396348561,body_count=3,allow_append=true,template_key=2342442877,record_key=2943433394},
 {name="DP-00 Tactical / Helmet",key=1481290619,kind=1,kit_index=24,archive_hi=3946386673,archive_lo=1581339135,body_count=1,allow_append=true,template_key=2141363041,record_key=703523490},
 {name="B-22 Model Citizen / Armour",key=3414071094,kind=0,kit_index=39,archive_hi=287332222,archive_lo=3521156600,body_count=3,allow_append=true,template_key=2342442877,record_key=3696494697},
 {name="B-22 Model Citizen / Helmet",key=3964228207,kind=1,kit_index=40,archive_hi=3517160286,archive_lo=3670427306,body_count=1,allow_append=true,template_key=2141363041,record_key=1571461053},
 {name="B-16 Battle-Scarred Veteran / Armour",key=2962098489,kind=0,kit_index=41,archive_hi=149489304,archive_lo=207824274,body_count=3,allow_append=true,template_key=2342442877},
 {name="B-16 Battle-Scarred Veteran / Helmet",key=2511084797,kind=1,kit_index=42,archive_hi=1752577621,archive_lo=1337944646,body_count=1,allow_append=true,template_key=2141363041},
 {name="TR-9 Cavalier of Democracy / Armour",key=2483492566,kind=0,kit_index=60,archive_hi=3226334764,archive_lo=1383999329,body_count=3,allow_append=true,template_key=2342442877,record_key=2712908266},
 {name="TR-9 Cavalier of Democracy / Helmet",key=4004823774,kind=1,kit_index=62,archive_hi=2095849254,archive_lo=1161163720,body_count=1,allow_append=true,template_key=2141363041,record_key=1122513689},
 {name="TR-117 Alpha Commander / Armour",key=2675118910,kind=0,kit_index=67,archive_hi=1587164681,archive_lo=2247141088,body_count=3,allow_append=true,template_key=2342442877,record_key=3066485739},
 {name="TR-117 Alpha Commander / Helmet",key=793893084,kind=1,kit_index=68,archive_hi=2083821220,archive_lo=1757347880,body_count=1,allow_append=true,template_key=2141363041,record_key=1945105139},
 {name="IX-Voidwalker / Helmet",key=1685612430,kind=1,kit_index=69,archive_hi=3802325812,archive_lo=121212318,body_count=1,allow_append=true,template_key=2141363041,record_key=2547900634},
 {name="B-02 Gloom Warden / Helmet",key=1951513251,kind=1,kit_index=70,archive_hi=2015580395,archive_lo=3949848280,body_count=1,allow_append=true,template_key=2141363041},
 {name="TR-7 Ambassador of the Brand / Armour",key=2325051543,kind=0,kit_index=133,archive_hi=2110341219,archive_lo=1581110643,body_count=3,allow_append=true,template_key=2342442877,record_key=495842462},
 {name="TR-40 Gold Eagle / Armour",key=470325800,kind=0,kit_index=142,archive_hi=1165294900,archive_lo=3185288644,body_count=3,allow_append=true,template_key=2342442877,record_key=276679263},
 {name="TR-7 Ambassador of the Brand / Helmet",key=904434511,kind=1,kit_index=144,archive_hi=2697887104,archive_lo=3894396462,body_count=1,allow_append=true,template_key=2141363041,record_key=1967836924},
 {name="TR-40 Gold Eagle / Helmet",key=4191752871,kind=1,kit_index=159,archive_hi=3247858599,archive_lo=4082075900,body_count=1,allow_append=true,template_key=2141363041,record_key=3813318023},
 {name="KDM-500 OUTRIDER / Armour",key=2925099185,kind=0,kit_index=192,archive_hi=1197770917,archive_lo=2250053088,body_count=3,allow_append=true,template_key=2342442877,record_key=3421347422},
 {name="KDM-500 Outrider / Helmet",key=3534240935,kind=1,kit_index=193,archive_hi=483817193,archive_lo=529584669,body_count=1,allow_append=true,template_key=2141363041,record_key=1407130184},
 {name="KDM-763 Pacesetter / Armour",key=505999640,kind=0,kit_index=259,archive_hi=433518175,archive_lo=2800812486,body_count=3,allow_append=true,template_key=2342442877},
 {name="KDM-763 Pacesetter / Helmet",key=1910769380,kind=1,kit_index=260,archive_hi=4054519444,archive_lo=1158672886,body_count=1,allow_append=true,template_key=2141363041},
 {name="KDM-73 Dragoon / Armour",key=461580715,kind=0,kit_index=261,archive_hi=3644310702,archive_lo=1587491361,body_count=3,allow_append=true,template_key=2342442877},
 {name="KDM-73 Dragoon / Helmet",key=4123751987,kind=1,kit_index=262,archive_hi=2294184900,archive_lo=1079231488,body_count=1,allow_append=true,template_key=2141363041},
 {name="TR-62 Knight / Armour",key=1934028230,kind=0,kit_index=289,archive_hi=136584103,archive_lo=852064925,body_count=3,allow_append=true,template_key=2342442877,record_key=2899116161},
 {name="TR-62 Knight / Helmet",key=856924396,kind=1,kit_index=290,archive_hi=4271435113,archive_lo=2553098419,body_count=1,allow_append=true,template_key=2141363041,record_key=2694550156},
 {name="Unreleased Cape / Cape",key=3690580532,kind=2,kit_index=293,archive_hi=1778254319,archive_lo=3213798145,body_count=1,allow_append=true,template_key=865246378,record_key=3690580532},
 {name="Unreleased Cape / Cape",key=2592491111,kind=2,kit_index=303,archive_hi=2368300255,archive_lo=630901283,body_count=1,allow_append=true,template_key=865246378},
 {name="Fallen Hero's Vengeance / Cape",key=865246378,kind=2,kit_index=305,archive_hi=1490801536,archive_lo=1573507977,body_count=1,allow_append=true,template_key=865246378,record_key=865246378},
 {name="Unreleased Cape / Cape",key=2457217350,kind=2,kit_index=310,archive_hi=3523552945,archive_lo=1801652088,body_count=1,allow_append=true,template_key=865246378},
 {name="Unreleased Cape / Cape",key=3881932101,kind=2,kit_index=314,archive_hi=2408221691,archive_lo=696782753,body_count=1,allow_append=true,template_key=865246378},
 {name="Protector of the Heart / Cape",key=2002245864,kind=2,kit_index=315,archive_hi=2392479574,archive_lo=2466967261,body_count=1,allow_append=true,template_key=865246378,record_key=2002245864},
 {name="Emblem of Freedom / Cape",key=463066946,kind=2,kit_index=316,archive_hi=2947285411,archive_lo=784094650,body_count=1,allow_append=true,template_key=865246378,record_key=463066946},
 {name="Reckoning's Cheer / Cape",key=3076249017,kind=2,kit_index=319,archive_hi=2807149773,archive_lo=328928947,body_count=1,allow_append=true,template_key=865246378,record_key=3076249017},
 {name="Unreleased Cape / Cape",key=3667835749,kind=2,kit_index=320,archive_hi=216158098,archive_lo=408825979,body_count=1,allow_append=true,template_key=865246378},
 {name="United in Equality / Cape",key=1838911009,kind=2,kit_index=322,archive_hi=1792867061,archive_lo=1961924803,body_count=1,allow_append=true,template_key=865246378,record_key=1838911009},
 {name="Against the Tyrant Cloud (inferred label) / Cape",key=1917397047,kind=2,kit_index=323,archive_hi=629382893,archive_lo=67133499,body_count=1,allow_append=true,template_key=865246378,record_key=1917397047},
 {name="Veridical Ideology / Cape",key=4028901518,kind=2,kit_index=324,archive_hi=2099341247,archive_lo=4092314581,body_count=1,allow_append=true,template_key=865246378,record_key=4028901518},
 {name="Message of Morale / Cape",key=3890208935,kind=2,kit_index=329,archive_hi=2389483846,archive_lo=245321061,body_count=1,allow_append=true,template_key=865246378,record_key=3890208935},
 {name="Ingress-81 / Cape",key=1902399433,kind=2,kit_index=331,archive_hi=4200242540,archive_lo=2339239898,body_count=1,allow_append=true,template_key=865246378,record_key=1902399433},
 {name="Eye of Freedom / Cape",key=582381095,kind=2,kit_index=393,archive_hi=672417350,archive_lo=4084293277,body_count=1,allow_append=true,template_key=865246378,record_key=582381095},
 {name="Eye of Liberty / Cape",key=453241154,kind=2,kit_index=394,archive_hi=3079676520,archive_lo=1659211903,body_count=1,allow_append=true,template_key=865246378,record_key=453241154},
 {name="Unreleased Cape / Cape",key=1675418984,kind=2,kit_index=400,archive_hi=465542919,archive_lo=866537833,body_count=1,allow_append=true,template_key=865246378},
 {name="SC-37 Legionnaire / Armour [hidden kit C2A2375F]",key=3265410911,kind=0,kit_index=81,archive_hi=3589823669,archive_lo=4021570770,body_count=3,allow_append=true,template_key=2342442877,record_key=2304644113},
 {name="SC-37 Legionnaire / Armour [hidden kit 9BC153C0]",key=2613138368,kind=0,kit_index=83,archive_hi=3341392019,archive_lo=1797097634,body_count=3,allow_append=true,template_key=2342442877,record_key=2076675618},
 {name="SC-37 Legionnaire (variant) / Helmet [hidden kit E406CED0]",key=3825651408,kind=1,kit_index=84,archive_hi=3139685289,archive_lo=3075624081,body_count=1,allow_append=true,template_key=2141363041,record_key=1180262890},
 {name="SC-37 Legionnaire (variant) / Helmet [hidden kit 44D93620]",key=1155085856,kind=1,kit_index=86,archive_hi=226215179,archive_lo=1113333162,body_count=1,allow_append=true,template_key=2141363041,record_key=2194213002},
 {name="SC-30 Trailblazer Scout / Armour [hidden kit 756159E4]",key=1969314276,kind=0,kit_index=97,archive_hi=3878350592,archive_lo=1848809363,body_count=3,allow_append=true,template_key=2342442877},
 {name="SC-30 Trailblazer Scout / Helmet [hidden kit 7FA29B61]",key=2141363041,kind=1,kit_index=99,archive_hi=2889696503,archive_lo=207594043,body_count=1,allow_append=true,template_key=2141363041,record_key=2141363041},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 9B5BC520]",key=2606482720,kind=1,kit_index=100,archive_hi=1108652185,archive_lo=2904840381,body_count=1,allow_append=true,template_key=2141363041},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit DB7DB6AA]",key=3682449066,kind=1,kit_index=101,archive_hi=2933949674,archive_lo=3567088962,body_count=1,allow_append=true,template_key=2141363041,record_key=3682449066},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 8507BB35]",key=2231876405,kind=1,kit_index=103,archive_hi=3438060159,archive_lo=3619451950,body_count=1,allow_append=true,template_key=2141363041,record_key=2231876405},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 020A57A8]",key=34232232,kind=1,kit_index=104,archive_hi=4002270341,archive_lo=226130235,body_count=1,allow_append=true,template_key=2141363041,record_key=34232232},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 52045A9B]",key=1376017051,kind=1,kit_index=105,archive_hi=354667867,archive_lo=421840994,body_count=1,allow_append=true,template_key=2141363041,record_key=1376017051},
 {name="SC-30 Trailblazer Scout (variant) / Helmet [hidden kit 782087B2]",key=2015397810,kind=1,kit_index=106,archive_hi=138781019,archive_lo=3140607174,body_count=1,allow_append=true,template_key=2141363041,record_key=2015397810},
 {name="B-24 Enforcer / Armour [hidden kit 8B9ED77D]",key=2342442877,kind=0,kit_index=107,archive_hi=2022568337,archive_lo=1351702537,body_count=3,allow_append=true,template_key=2342442877,record_key=2342442877},
 {name="B-24 Enforcer / Armour [hidden kit AC0ADECD]",key=2886393549,kind=0,kit_index=109,archive_hi=409401186,archive_lo=3297990890,body_count=3,allow_append=true,template_key=2342442877,record_key=2886393549},
 {name="FS-05 Marksman / Armour [hidden kit 076D9AAD]",key=124623533,kind=0,kit_index=111,archive_hi=835740753,archive_lo=2694216177,body_count=3,allow_append=true,template_key=2342442877},
 {name="FS-05 Marksman / Armour [hidden kit 58DBDACD]",key=1490803405,kind=0,kit_index=112,archive_hi=3433826903,archive_lo=2896408210,body_count=3,allow_append=true,template_key=2342442877,record_key=671123458},
 {name="FS-05 Marksman / Helmet [hidden kit 0F41A67E]",key=255960702,kind=1,kit_index=114,archive_hi=3835812435,archive_lo=1269596558,body_count=1,allow_append=true,template_key=2141363041,record_key=255960702},
 {name="FS-05 Marksman / Helmet [hidden kit 7B6406DA]",key=2070152922,kind=1,kit_index=115,archive_hi=3235646076,archive_lo=2412073492,body_count=1,allow_append=true,template_key=2141363041,record_key=3058335410},
 {name="FS-05 Marksman / Helmet [hidden kit 36456057]",key=910516311,kind=1,kit_index=116,archive_hi=2148068218,archive_lo=248298689,body_count=1,allow_append=true,template_key=2141363041,record_key=910516311},
 {name="FS-05 Marksman / Helmet [hidden kit D915A671]",key=3642074737,kind=1,kit_index=118,archive_hi=3917520839,archive_lo=616470982,body_count=1,allow_append=true,template_key=2141363041,record_key=3642074737},
 {name="FS-05 Marksman / Helmet [hidden kit E417AE7B]",key=3826757243,kind=1,kit_index=119,archive_hi=2255901022,archive_lo=2066804029,body_count=1,allow_append=true,template_key=2141363041,record_key=3826757243},
 {name="FS-05 Marksman / Helmet [hidden kit 4452E375]",key=1146282869,kind=1,kit_index=120,archive_hi=237110597,archive_lo=1126970998,body_count=1,allow_append=true,template_key=2141363041,record_key=1146282869},
 {name="FS-05 Marksman / Helmet [hidden kit 0C0AF708]",key=202045192,kind=1,kit_index=121,archive_hi=1387674437,archive_lo=3349601196,body_count=1,allow_append=true,template_key=2141363041,record_key=202045192},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit 5C1A87D2]",key=1545242578,kind=1,kit_index=125,archive_hi=2314701972,archive_lo=1136656028,body_count=1,allow_append=true,template_key=2141363041,record_key=1545242578},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit 68AA2D85]",key=1755983237,kind=1,kit_index=126,archive_hi=1997498211,archive_lo=186331794,body_count=1,allow_append=true,template_key=2141363041,record_key=1755983237},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit 126F9CB6]",key=309304502,kind=1,kit_index=128,archive_hi=358388545,archive_lo=2402052722,body_count=1,allow_append=true,template_key=2141363041,record_key=309304502},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit 0542E6F1]",key=88270577,kind=1,kit_index=129,archive_hi=4166678506,archive_lo=3465214586,body_count=1,allow_append=true,template_key=2141363041,record_key=88270577},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit B6A2F46A]",key=3064132714,kind=1,kit_index=130,archive_hi=809702328,archive_lo=2223238983,body_count=1,allow_append=true,template_key=2141363041,record_key=3064132714},
 {name="SC-34 Infiltrator (variant) / Helmet [hidden kit A2F4F328]",key=2733962024,kind=1,kit_index=131,archive_hi=2913716702,archive_lo=3144559612,body_count=1,allow_append=true,template_key=2141363041,record_key=2733962024},
 {name="B-01 Tactical / Armour [hidden kit 250FD6C1]",key=621795009,kind=0,kit_index=132,archive_hi=3206678783,archive_lo=1856778051,body_count=3,allow_append=true,template_key=2342442877,record_key=3935965925},
 {name="B-01 Tactical / Armour [hidden kit 1D0E3431]",key=487470129,kind=0,kit_index=134,archive_hi=3775059454,archive_lo=1759604319,body_count=3,allow_append=true,template_key=2342442877,record_key=2053442827},
 {name="B-01 Tactical / Armour [hidden kit 708451E9]",key=1887719913,kind=0,kit_index=135,archive_hi=3515097195,archive_lo=772407656,body_count=3,allow_append=true,template_key=2342442877,record_key=2394592819},
 {name="B-01 Tactical / Armour [hidden kit D59566D5]",key=3583338197,kind=0,kit_index=140,archive_hi=3026204229,archive_lo=2569010486,body_count=3,allow_append=true,template_key=2342442877,record_key=2905408536},
 {name="B-01 Tactical / Armour [hidden kit 1369B95B]",key=325695835,kind=0,kit_index=141,archive_hi=1850493196,archive_lo=4170930748,body_count=3,allow_append=true,template_key=2342442877,record_key=2553569133},
 {name="B-01 Tactical / Helmet [hidden kit 2180EB8D]",key=562097037,kind=1,kit_index=143,archive_hi=3148842524,archive_lo=3948424950,body_count=1,allow_append=true,template_key=2141363041,record_key=529287881},
 {name="B-01 Tactical / Helmet [hidden kit 4F6CCD6C]",key=1332530540,kind=1,kit_index=145,archive_hi=2306375798,archive_lo=1084519576,body_count=1,allow_append=true,template_key=2141363041,record_key=1332530540},
 {name="B-01 Tactical / Helmet [hidden kit 40A7D694]",key=1084741268,kind=1,kit_index=146,archive_hi=3762888372,archive_lo=4214586666,body_count=1,allow_append=true,template_key=2141363041,record_key=2694161121},
 {name="TBD / Helmet [hidden kit 8CE73DAE]",key=2363964846,kind=1,kit_index=147,archive_hi=539686219,archive_lo=1340464517,body_count=1,allow_append=true,template_key=2141363041,record_key=4100314171},
 {name="B-01 Tactical / Helmet [hidden kit 69B2EC39]",key=1773333561,kind=1,kit_index=148,archive_hi=3858667789,archive_lo=2102840622,body_count=1,allow_append=true,template_key=2141363041,record_key=1773333561},
 {name="B-01 Tactical / Helmet [hidden kit EE7019ED]",key=4000324077,kind=1,kit_index=153,archive_hi=668106260,archive_lo=3035000656,body_count=1,allow_append=true,template_key=2141363041,record_key=1483434009},
 {name="B-01 Tactical / Helmet [hidden kit E207C84A]",key=3792160842,kind=1,kit_index=154,archive_hi=1020279313,archive_lo=1503039157,body_count=1,allow_append=true,template_key=2141363041,record_key=3792160842},
 {name="B-01 Tactical / Helmet [hidden kit 10707D29]",key=275807529,kind=1,kit_index=155,archive_hi=1055415311,archive_lo=1152225996,body_count=1,allow_append=true,template_key=2141363041,record_key=275807529},
 {name="B-01 Tactical / Helmet [hidden kit FDBF4741]",key=4257171265,kind=1,kit_index=156,archive_hi=849782646,archive_lo=477151643,body_count=1,allow_append=true,template_key=2141363041,record_key=2067677478},
 {name="B-01 Tactical / Helmet [hidden kit B638F3C4]",key=3057185732,kind=1,kit_index=157,archive_hi=3439904546,archive_lo=593393100,body_count=1,allow_append=true,template_key=2141363041,record_key=3057185732},
 {name="B-01 Tactical / Helmet [hidden kit 843DF174]",key=2218652020,kind=1,kit_index=158,archive_hi=2587341024,archive_lo=3743448160,body_count=1,allow_append=true,template_key=2141363041,record_key=2218652020},
 {name="Prosperous Green / Cape",key=3822047995,kind=2,kit_index=318,archive_hi=1138998390,archive_lo=1419351956,body_count=1,allow_append=true,template_key=865246378,record_key=3822047995},
 {name="Red Planet's Memory / Cape",key=2632342951,kind=2,kit_index=325,archive_hi=3334997962,archive_lo=342846618,body_count=1,allow_append=true,template_key=865246378,record_key=2632342951},
 {name="Proud Gold / Cape",key=4112773733,kind=2,kit_index=326,archive_hi=3680123751,archive_lo=731725265,body_count=1,allow_append=true,template_key=865246378,record_key=4112773733},
 {name="Patriot Blue / Cape",key=114199832,kind=2,kit_index=327,archive_hi=1115173758,archive_lo=2959508638,body_count=1,allow_append=true,template_key=865246378,record_key=114199832},
 {name="Scraps of Sovereignty / Cape",key=4014974242,kind=2,kit_index=341,archive_hi=2112209738,archive_lo=2212817321,body_count=1,allow_append=true,template_key=865246378,record_key=4014974242},

 -- Additional named cape targets identified in the user screenshots.
 {name="Agent of Oblivion / Cape",key=4111053667,kind=2,kit_index=300,archive_hi=1600514194,archive_lo=1241225098,body_count=1,allow_append=true,template_key=865246378,record_key=4111053667},
 {name="Beacon of Mercy / Cape",key=1695626205,kind=2,kit_index=301,archive_hi=171779887,archive_lo=367145536,body_count=1,allow_append=true,template_key=865246378},
 {name="Bugslayer / Cape",key=2020619131,kind=2,kit_index=330,archive_hi=678120188,archive_lo=3843483101,body_count=1,allow_append=true,template_key=865246378},
 {name="Vector of Victory / Cape",key=3201849683,kind=2,kit_index=372,archive_hi=1030166427,archive_lo=2552704199,body_count=1,allow_append=true,template_key=865246378},
 {name="Podium of Prosperity / Cape",key=340532591,kind=2,kit_index=373,archive_hi=1898434015,archive_lo=3403335577,body_count=1,allow_append=true,template_key=865246378},
 {name="Defender of our dream / Cape",key=1113633420,kind=2,kit_index=375,archive_hi=724081672,archive_lo=785894094,body_count=1,allow_append=true,template_key=865246378,record_key=1113633420},
 {name="Tyranny's Bane / Cape",key=3058055083,kind=2,kit_index=395,archive_hi=628588342,archive_lo=1380686520,body_count=1,allow_append=true,template_key=865246378},
 {name="Agent of Oblivion / Cape",key=391288265,kind=2,kit_index=396,archive_hi=3037730311,archive_lo=2382213057,body_count=1,allow_append=true,template_key=865246378},

 -- Unnamed screenshot candidates; exact build metadata, visual match unconfirmed.
 {name="TBD / Armour",key=2669749508,kind=0,kit_index=73,archive_hi=1530440574,archive_lo=548708849,body_count=3,allow_append=true,template_key=2342442877},
 {name="TBD / Helmet",key=2776529082,kind=1,kit_index=74,archive_hi=3374736250,archive_lo=3152079601,body_count=1,allow_append=true,template_key=2141363041},
 {name="Unidentified kit / Armour",key=323545031,kind=0,kit_index=206,archive_hi=555019256,archive_lo=1251441740,body_count=3,allow_append=true,template_key=2342442877,record_key=2806949459},

 -- Unidentified cape candidates; one may be the empty/no-cape model.
 {name="Unidentified kit / Cape",key=199989180,kind=2,kit_index=299,archive_hi=3105026548,archive_lo=4079046279,body_count=1,allow_append=true,template_key=865246378},
 {name="Unidentified kit / Cape",key=1513263450,kind=2,kit_index=317,archive_hi=1198184012,archive_lo=2339479523,body_count=1,allow_append=true,template_key=865246378,record_key=1513263450},
 {name="Unidentified kit / Cape",key=534865247,kind=2,kit_index=321,archive_hi=1523003314,archive_lo=2673608503,body_count=1,allow_append=true,template_key=865246378},
 {name="Unidentified kit / Cape",key=2901358327,kind=2,kit_index=328,archive_hi=734346287,archive_lo=1124055989,body_count=1,allow_append=true,template_key=865246378},
 {name="Unidentified kit / Cape",key=1588662851,kind=2,kit_index=340,archive_hi=1640141849,archive_lo=4117792194,body_count=1,allow_append=true,template_key=865246378},
 {name="Unidentified kit / Cape",key=193259933,kind=2,kit_index=410,archive_hi=1219870751,archive_lo=3639782500,body_count=1,allow_append=true,template_key=865246378},
}
local function classes()
  local p=ptr(class_slot)
  -- The supplied Shear source locates classification-range metadata at +0x1b28.
  return p and read(p,0x1b20)
end
local function class(hi,lo)
  local b=classes(); if not b then return nil,nil,'classification table unavailable' end
  local key,category
  for off=0,#b-32,32 do
    if u32(b,off)~=0 and u32(b,off+8)==lo and u32(b,off+12)==hi then
      if key then return nil,nil,'duplicate model classification' end
      key,category=u32(b,off),u32(b,off+16)
    end
  end
  return key,category,'model missing from this build'
end
local native=Native.new({read=read,ptr=ptr,u32=u32,u64=u64at,base=base})
local function strat_flag(id,key)return native:strat_flag(id,key)end
local core=Core.new({journal=journal,read=read,write=write,writable=writable,
  root=function()return ptr(item_slot)end,class=class,strat_flag=strat_flag,kit=function(t)return native:kit(t)end})
local next_check,observed_root,stable_root,discovery_root=0,nil,nil,nil
local diagnostic_root,diagnostic_time,diagnostic_pass=nil,0,0
local statuses={}
local function status(name,message)
  if statuses[name]~=message then statuses[name]=message;emit(name..': '..message) end
end
local function inventory(s)
  local b=classes();if not b then return end
  emit('DISCOVERY_BEGIN: unregistered classification entries; identifiers only, NOT proof of usable equipment')
  local registered={}
  for off=0,#s.maps-24,24 do registered[u32(s.maps,off+4)]=true end
  local n=0
  for off=0,#b-32,32 do
    local key,lo,hi,category=u32(b,off),u32(b,off+8),u32(b,off+12),u32(b,off+16)
    if key>65535 and category>=1 and category<=6 and not registered[key] and (lo~=0 or hi~=0) then
      emit(string.format('UNREGISTERED class=%d key=0x%08X model=%08X:%08X category=%d',off/32,key,hi,lo,category))
      n=n+1
    end
  end
  emit('DISCOVERY_END candidates='..n..'; unsupported entries left unchanged')
end
local function tick()
  if now()<next_check then return end;next_check=now()+2
  local s,why=core:snapshot()
  if not s then
    observed_root,stable_root=nil,nil
    status('registry',why);public.status='waiting';return
  end
  if observed_root~=s.root then
    observed_root=s.root;stable_root=nil;statuses={}
    status('registry','waiting for stable pointer');return
  end
  if stable_root~=s.root then
    stable_root=s.root;emit(string.format('REGISTRY_READY root=0x%X count=%d',s.root,s.count))
  end
  if discovery_root~=s.root then inventory(s);discovery_root=s.root end
  local success=0
  for _,t in ipairs(WEAPONS) do
    if core.fatal then break end
    local ok,message=core:weapon(t);status(t.name,(ok and 'OK: ' or 'WAIT/SKIP: ')..tostring(message))
    if ok then success=success+1 end
  end
  for _,t in ipairs(STRATS) do
    if core.fatal then break end
    local ok,message=core:stratagem(t);status(t.name,(ok and 'OK: ' or 'WAIT/SKIP: ')..tostring(message))
    if ok then success=success+1 end
  end
  native:begin()
  local cosmetic_snapshot=core:snapshot()
  for _,t in ipairs(COSMETICS) do
    if core.fatal then break end
    if not cosmetic_snapshot then cosmetic_snapshot=core:snapshot() end
    local before=cosmetic_snapshot and cosmetic_snapshot.count
    local ok,message=core:catalogue_cosmetic(t,cosmetic_snapshot)
    if ok and not t.record_key then message='inventory state verified; armoury visibility UNCONFIRMED' end
    status(string.format('%s [%08X]',t.name,t.key),(ok and 'OK: ' or 'WAIT/SKIP: ')..tostring(message))
    if ok then success=success+1 end
    if not ok or (cosmetic_snapshot and cosmetic_snapshot.count~=before) then cosmetic_snapshot=nil end
  end
  local index_ok,index_message=CategoryIndex.repair(core,{read=read,u32=u32,le32=le32,guard=function()return native:category_guard()end})
  status('armoury category index',(index_ok and 'OK: ' or 'WAIT/SKIP: ')..tostring(index_message))
  public.status=core.fatal and 'disabled: transaction ownership lost' or ('inventory states verified (NOT menu visibility): '..success..'/'..(#WEAPONS+#STRATS+#COSMETICS))
  status('summary',public.status)
  if diagnostic_root~=s.root then diagnostic_root=s.root;diagnostic_pass=0;diagnostic_time=now() end
  if diagnostic_pass<2 and now()>=diagnostic_time then
    diagnostic_pass=diagnostic_pass+1;diagnostic_time=now()+60
    local ok,err=pcall(function()
      Diagnostics.capture({snapshot=function()return core:snapshot()end,read=read,u32=u32,hex=hex,
        emit=emit,inspect=function(t)return native:inspect_kit(t)end},COSMETICS,diagnostic_pass)
    end)
    if not ok then emit('KDM_DIAGNOSTIC_ERROR '..tostring(err)) end
  end
  local custom=rawget(_G,'LAS22ShearCustomizationExperimentM4')
  status('Shear customization',custom and custom.status or 'waiting for customization component')
end
local previous=rawget(_G,'update')
local stopped=false
rawset(_G,'update',function(...)
  if not stopped then
    local ok,err=pcall(tick)
    if not ok or core.fatal then
      stopped=true;finish('disabled: '..tostring(err or 'unsafe transaction; restart required'))
    end
  end
  return previous(...)
end)
local previous_shutdown=rawget(_G,'shutdown')
rawset(_G,'shutdown',function(...)
  stopped=true
  local ok,restored,skipped=pcall(journal.run)
  if ok then
    emit('SHUTDOWN_RESTORE writes undone='..tostring(restored)..' skipped='..tostring(skipped)..'; original registry restored before engine teardown')
    public.status='shutdown: original registry restored'
  else
    emit('SHUTDOWN_RESTORE_ERROR '..tostring(restored))
  end
  if previous_shutdown then return previous_shutdown(...) end
end)
public.status='waiting'
emit('LOADED v'..VERSION..'; loader='..tostring(loader.version)..'; verified build 25480438; automatic unlocks enabled')
emit('No Mod Options Menu dependency. Shear customization is included as a companion component; illumination flare is excluded. Cosmetic category index repair enabled; in-game confirmation pending.')
return public
end -- initialize
local initialized,result=pcall(initialize)
if not initialized then finish('disabled during initialization: '..tostring(result)) end
return public
