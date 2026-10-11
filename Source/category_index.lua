-- Derived from exact-build loaded code: native builder 0x136e6a0,
-- category lookup 0x13720c0, armour menu lookup 0x18d81e2.
local Index={}
local BOUNDS,ENTRIES,ROWS,MAPS=0xd1ce4,0xd1d48,0x1ce4,0xb9ce4
function Index.repair(core,io)
 local ok,why=io.guard();if not ok then return false,why end
 local s,err=core:snapshot();if not s then return false,err end
 local rows=io.read(s.root+ROWS,s.count*184)
 local bounds=io.read(s.root+BOUNDS,100)
 local indices=io.read(s.root+ENTRIES,s.count*4)
 if not rows or not bounds or not indices then return false,'category index unreadable' end
 local u32,le32=io.u32,io.le32
 local indexed=u32(bounds,96)
 if u32(bounds,0)~=0 or indexed>s.count then return false,'category boundaries invalid' end
 local groups={};for kind=0,23 do groups[kind]={}end
 for pos=0,s.count-1 do
  local m=pos*24;local row=pos*184
  -- Native builder's indices are row positions and consumers use mapping positions.
  -- Refuse an unexpected layout rather than reorder any inventory records.
  if u32(s.maps,m)~=pos or u32(rows,row)~=pos
   or u32(s.maps,m+4)~=u32(rows,row+4)or u32(s.maps,m+8)~=u32(rows,row+8)then
   return false,'category row/map alignment mismatch'
  end
  local kind=u32(rows,row+12)
  if not kind or kind>23 then return false,'category type out of range' end
  local g=groups[kind];g[#g+1]=pos
 end
 -- Validate the existing index, including old entries that must be preserved.
 local seen={}
 for kind=0,23 do
  local first,last=u32(bounds,kind*4),u32(bounds,(kind+1)*4)
  if first>last or last>indexed then return false,'category boundaries inconsistent' end
  for n=first,last-1 do
   local pos=u32(indices,n*4)
   if not pos or pos>=s.count or seen[pos]or u32(rows,pos*184+12)~=kind then
    return false,'existing category membership invalid'
   end
   seen[pos]=true
  end
 end
 local newbounds,newindices={},{};local n=0
 for kind=0,23 do
  newbounds[#newbounds+1]=le32(n)
  for _,pos in ipairs(groups[kind])do newindices[#newindices+1]=le32(pos);n=n+1 end
 end
 newbounds[#newbounds+1]=le32(n)
 local nb,ni=table.concat(newbounds),table.concat(newindices)
 if nb==bounds and ni==indices then return true,'current ('..n..' entries)' end
 if io.read(s.root+ROWS,#rows)~=rows or io.read(s.root+MAPS,#s.maps)~=s.maps then
  return false,'inventory changed during category rebuild'
 end
 local changes={}
 if ni~=indices then changes[#changes+1]={addr=s.root+ENTRIES,old=indices,new=ni}end
 if nb~=bounds then changes[#changes+1]={addr=s.root+BOUNDS,old=bounds,new=nb}end
 local done,msg=core:transaction(s,changes)
 return done,msg or ('rebuilt '..indexed..' -> '..n..' entries; ownership unchanged')
end
return Index
