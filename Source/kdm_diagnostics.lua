-- Bounded read-only snapshots. No native calls, writes or broad memory scans.
local D={}
function D.capture(io,targets,pass)
 local s,why=io.snapshot()
 if not s then io.emit('KDM_DIAGNOSTIC_UNAVAILABLE '..tostring(why));return false end
 local wanted={}
 for _,t in ipairs(targets)do
  if t.key==0x1e28f118 or t.key==0x71e406e4 or t.key==0x1b8329ab or t.key==0xf5cb7633
   or t.key==0xae5978b1 or t.key==0xd2a83ca7 then
   wanted[t.key]={name=t.name,target=t}
   if t.template_key then wanted[t.template_key]=wanted[t.template_key]or{name='append template'} end
  end
 end
 io.emit(string.format('KDM_DIAGNOSTIC_BEGIN pass=%d count=%d root=0x%X',pass,s.count,s.root))
 for key,entry in pairs(wanted)do
  local found=0
  for off=0,#s.maps-24,24 do
   local map=s.maps:sub(off+1,off+24)
   if io.u32(map,8)==key then
    found=found+1;local index=io.u32(map,0)
    if index and index<s.count then
     local row=io.read(s.root+0x1ce4+index*184,184)
     io.emit(string.format('KDM_RECORD key=%08X position=%d index=%d map24=%s row184=%s',key,off/24,index,io.hex(map),row and io.hex(row)or'UNREADABLE'))
    else io.emit(string.format('KDM_BAD_INDEX key=%08X',key)) end
   end
  end
  io.emit(string.format('KDM_MATCHES key=%08X matches=%d name=%s',key,found,entry.name))
  if entry.target then
   local kit,err=io.inspect(entry.target)
   io.emit(string.format('KDM_KIT key=%08X header64=%s',key,kit and io.hex(kit)or tostring(err)))
  end
 end
 local after=io.snapshot()
 io.emit('KDM_DIAGNOSTIC_END stable='..tostring(after~=nil and after.root==s.root and after.count==s.count)..'; inventory data only, menu visibility unverified')
 return true
end
return D
