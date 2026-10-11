local h=assert(io.open('Source/runtime_suffix.lua'));local source=h:read('*a');h:close()
local cat=assert(loadstring(source:sub(1,assert(source:find('local function classes',1,true))-1)..'return {WEAPONS,STRATS,COSMETICS}'))()
local excluded=assert(loadfile('Tests/excluded_targets.lua'))()
local groups={'weapons','stratagems','cosmetics'}
for i,g in ipairs(groups)do
 local selected={}
 for _,t in ipairs(cat[i])do selected[i==1 and (t.hi..':'..t.lo)or t.key]=true end
 for _,t in ipairs(excluded[g])do assert(not selected[i==1 and (t.hi..':'..t.lo)or t.key],g..' ordinary/unknown target reintroduced: '..t.name)end
 print('PASS excluded '..g..' absent from executable runtime catalogue')
end
assert(#cat[1]==5 and #cat[2]==4 and #cat[3]==91)
local names={};for _,g in ipairs(cat)do for _,t in ipairs(g)do names[t.name]=true end end
for _,n in ipairs({'Orbital illumination flare','AR-23 Liberator','MP-98 Knight','LAS-12 Sai','EXO-55 Breakthrough Exosuit','EXO-51 Lumberer Exosuit','B-100 Portable Hellbomb','M-102 Gunner FRV','Orbital Precision Strike','AC-1 Dutiful / Armour','DP-53 Savior of the Free / Armour'})do assert(not names[n],n)end
print('PASS scope excludes ordinary progression, Superstore, purchased editions and collaboration warbonds')
print('4 scope checks passed')

local ordinary={ [82]=true,[85]=true,[98]=true,[102]=true,[108]=true,[110]=true,[113]=true,[117]=true,[124]=true,[127]=true,[136]=true,[137]=true,[138]=true,[139]=true,[149]=true,[150]=true,[151]=true,[152]=true }
for _,t in ipairs(cat[3])do assert(not ordinary[t.kit_index], 'ordinary version of variant family included: '..t.name)end
print('PASS normal player kits within shared-name families stay excluded')
