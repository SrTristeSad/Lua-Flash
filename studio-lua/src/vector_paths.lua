-- Studio-only cubic Bezier paths, separate from LUAFLASH 1 shared core.
-- Authoring storage: LFVECTOR 1 auxiliary project file.
local M={}
local function finite(n)
  return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
local function validPos(n) return finite(n) and math.abs(n)<=100000 end
local function copy(a)
  if type(a)~="table" then return a end
  local b={}
  for k,v in pairs(a) do b[k]=copy(v) end
  return b
end
local function int(n,min,max)
  return finite(n) and n==math.floor(n) and n>=min and n<=max
end
local function sorted(t)
  local keys={}
  for k in pairs(t) do keys[#keys+1]=k end
  table.sort(keys)
  return keys
end
local function rgba(c)
  return type(c)=="table" and #c>=3 and #c<=4
    and finite(c[1]) and finite(c[2]) and finite(c[3])
    and c[1]>=0 and c[1]<=1 and c[2]>=0 and c[2]<=1
    and c[3]>=0 and c[3]<=1
    and (not c[4] or finite(c[4]) and c[4]>=0 and c[4]<=1)
end
function M.new() return {nextId=1,tracks={}} end
function M.at(v,layer,frame)
  local t=v.tracks[layer]
  if not t then return {} end
  local best=0
  for n in pairs(t) do if n<=frame and n>best then best=n end end
  return t[best] or {}
end
function M.ensureKey(v,layer,frame,blank)
  assert(int(layer,1,128) and int(frame,1,10000),"invalid vector key")
  v.tracks[layer]=v.tracks[layer] or {}
  local track=v.tracks[layer]
  if not track[frame] then track[frame]=blank and {} or copy(M.at(v,layer,frame))
  elseif blank then track[frame]={} end
  return track[frame]
end
function M.removeKey(v,layer,frame)
  if frame==1 or not v.tracks[layer] or not v.tracks[layer][frame] then return false end
  v.tracks[layer][frame]=nil
  return true
end
function M.addPath(v,layer,frame,x,y,stroke,width,fill)
  if not validPos(x) or not validPos(y) or not rgba(stroke)
      or not finite(width) or width<.1 or width>200
      or (fill and not rgba(fill))
      or not int(v.nextId,1,10000000) then return nil,"invalid path" end
  local paths=M.ensureKey(v,layer,frame)
  if #paths>=500 then return nil,"too many vector paths" end
  local node={x=x,y=y,ix=x,iy=y,ox=x,oy=y}
  local path={id=v.nextId,closed=false,stroke=copy(stroke),width=width,
    fill=fill and copy(fill) or nil,nodes={node}}
  v.nextId=v.nextId+1
  paths[#paths+1]=path
  return path
end
function M.addNode(path,x,y)
  if not validPos(x) or not validPos(y) or not path
      or #path.nodes>=256 or path.closed then return nil,"invalid point" end
  path.nodes[#path.nodes+1]={x=x,y=y,ix=x,iy=y,ox=x,oy=y}
  return #path.nodes
end
function M.handle(path,index,x,y,which)
  local node=path and path.nodes[index]
  if not node or not validPos(x) or not validPos(y)
      or (which~="out" and which~="in") then return false end
  if which=="out" then node.ox,node.oy=x,y
  else node.ix,node.iy=x,y end
  return true
end
function M.moveNode(path,index,x,y)
  local node=path and path.nodes[index]
  if not node or not validPos(x) or not validPos(y) then return false end
  local dx,dy=x-node.x,y-node.y
  node.x,node.y=x,y
  node.ix,node.iy=node.ix+dx,node.iy+dy
  node.ox,node.oy=node.ox+dx,node.oy+dy
  return true
end
function M.move(path,dx,dy)
  if not validPos(dx) or not validPos(dy) then return false end
  for _,n in ipairs(path.nodes) do
    if not validPos(n.x+dx) or not validPos(n.y+dy) then return false end
  end
  for _,n in ipairs(path.nodes) do M.moveNode(path,_,n.x+dx,n.y+dy) end
  return true
end
function M.close(path)
  if not path or #path.nodes<3 then return false end
  path.closed=true
  return true
end
local function cubic(a,t)
  local q=1-t
  return q*q*q*a[1]+3*q*q*t*a[2]+3*q*t*t*a[3]+t*t*t*a[4]
end
function M.sample(path,steps)
  steps=math.max(2,math.min(64,math.floor(steps or 12)))
  local result={}
  if not path or #path.nodes==0 then return result end
  local count=#path.nodes
  result[#result+1]=path.nodes[1].x
  result[#result+1]=path.nodes[1].y
  local segments=path.closed and count or count-1
  for i=1,segments do
    local p=path.nodes[i]
    local n=path.nodes[i%count+1]
    for j=1,steps do
      local t=j/steps
      result[#result+1]=cubic({p.x,p.ox,n.ix,n.x},t)
      result[#result+1]=cubic({p.y,p.oy,n.iy,n.y},t)
    end
  end
  return result
end
function M.bounds(path)
  local data=M.sample(path)
  if #data==0 then return nil end
  local x1,y1,x2,y2=data[1],data[2],data[1],data[2]
  for i=3,#data,2 do
    local x,y=data[i],data[i+1]
    x1,y1,x2,y2=math.min(x1,x),math.min(y1,y),math.max(x2,x),math.max(y2,y)
  end
  return x1,y1,x2,y2
end
function M.pickNode(paths,x,y,tolerance)
  local limit=(tolerance or 8)^2
  for i=#paths,1,-1 do
    local path=paths[i]
    for j=#path.nodes,1,-1 do
      local node=path.nodes[j]
      local dx,dy=node.x-x,node.y-y
      if dx*dx+dy*dy<=limit then return path,j end
    end
  end
  return nil
end
local function segmentDistanceSq(x,y,ax,ay,bx,by)
  local dx,dy=bx-ax,by-ay
  local denom=dx*dx+dy*dy
  local t=denom>0 and math.max(0,math.min(1,((x-ax)*dx+(y-ay)*dy)/denom)) or 0
  local px,py=ax+t*dx,ay+t*dy
  return (x-px)^2+(y-py)^2
end
function M.hit(path,x,y,tolerance)
  if not path or not validPos(x) or not validPos(y) then return false end
  local points=M.sample(path)
  local r=(tolerance or 7)^2
  for i=3,#points,2 do
    if segmentDistanceSq(x,y,points[i-2],points[i-1],points[i],points[i+1])<=r then
      return true
    end
  end
  return false
end
function M.pick(paths,x,y,tolerance)
  for i=#paths,1,-1 do
    if M.hit(paths[i],x,y,tolerance) then return paths[i] end
  end
  return nil
end
local function fmt(n) return string.format("%.6f",n) end
local function colorFields(c)
  if not c then return "-" end
  return table.concat({fmt(c[1]),fmt(c[2]),fmt(c[3]),fmt(c[4] or 1)},",")
end
local function parseColor(s)
  if s=="-" then return nil end
  if type(s)~="string" then return nil,"invalid color" end
  local parts={}
  for v in (s..","):gmatch("(.-),") do
    parts[#parts+1]=tonumber(v)
  end
  if #parts~=4 or not rgba(parts) then return nil,"invalid color" end
  return parts
end
-- Build a change-set first; the editor records one undo snapshot and commits
-- vectors together with native artwork and symbol instances.
function M.planTransfer(v,layer,sources,delta,duplicate,totalFrames)
  if not int(layer,1,128) or not int(delta,-10000,10000) or delta==0
      or type(sources)~="table" or #sources==0 then return nil,"invalid transfer" end
  local from,selected,outputs={},{},{}
  local track=v.tracks[layer] or {}
  for _,n in ipairs(sources) do
    if not int(n,1,totalFrames) then return nil,"invalid source" end
    selected[n]=true
    from[#from+1]=n
  end
  local nextId=v.nextId
  local idMap={}
  for _,n in ipairs(from) do
    local target=n+delta
    if target<1 or target>totalFrames or
        track[target] and (duplicate or not selected[target]) then
      return nil,"vector destination occupied"
    end
    local visible=M.at(v,layer,n)
    if #visible>0 or track[n] then
      local paths=copy(visible)
      if duplicate then
        for _,p in ipairs(paths) do
          if not idMap[p.id] then
            if not int(nextId,1,10000000) then return nil,"vector ID limit" end
            idMap[p.id]=nextId
            nextId=nextId+1
          end
          p.id=idMap[p.id]
        end
      end
      outputs[target]=paths
    end
  end
  return {apply=function()
    if not duplicate then
      for _,n in ipairs(from) do track[n]=nil end
    end
    if next(outputs) then
      v.tracks[layer]=track
      for n,paths in pairs(outputs) do track[n]=paths end
    end
    v.nextId=nextId
  end}
end
function M.planPaste(v,layer,frame,paths)
  if not int(layer,1,128) or not int(frame,1,10000) or
      type(paths)~="table" or #paths>500 then return nil,"invalid clipboard" end
  local newPaths=copy(paths)
  local nextId=v.nextId
  local idMap={}
  for _,path in ipairs(newPaths) do
    if type(path)~="table" or not int(path.id,1,10000000)
        or type(path.nodes)~="table" or #path.nodes==0 then return nil,"invalid vector" end
    if not idMap[path.id] then
      if not int(nextId,1,10000000) then return nil,"vector ID limit" end
      idMap[path.id]=nextId
      nextId=nextId+1
    end
    path.id=idMap[path.id]
  end
  return {apply=function()
    v.tracks[layer]=v.tracks[layer] or {}
    v.tracks[layer][frame]=newPaths
    v.nextId=nextId
  end}
end
local function svgNum(n) return string.format("%.4f",n) end
local function svgColor(c)
  if not c then return "none" end
  return string.format("#%02X%02X%02X",
    math.floor(c[1]*255+.5),math.floor(c[2]*255+.5),math.floor(c[3]*255+.5))
end
function M.svg(v,doc,frame)
  local result={}
  for li,layer in ipairs(doc.layers) do
    if layer.visible then
      for _,path in ipairs(M.at(v,li,frame)) do
        local n=path.nodes
        local commands={"M",svgNum(n[1].x),svgNum(n[1].y)}
        local count=path.closed and #n or #n-1
        for j=1,count do
          local a,b=n[j],n[j%#n+1]
          commands[#commands+1]="C"
          for _,coordinate in ipairs({a.ox,a.oy,b.ix,b.iy,b.x,b.y}) do
            commands[#commands+1]=svgNum(coordinate)
          end
        end
        if path.closed then commands[#commands+1]="Z" end
        result[#result+1]=string.format(
          '<path d="%s" fill="%s" stroke="%s" stroke-width="%s" stroke-linejoin="round"/>',
          table.concat(commands," "),svgColor(path.closed and path.fill),
          svgColor(path.stroke),svgNum(path.width))
      end
    end
  end
  return table.concat(result," ")
end

function M.encode(v)
  local out={"LFVECTOR 1"}
  for _,layer in ipairs(sorted(v.tracks)) do
    for _,frame in ipairs(sorted(v.tracks[layer])) do
      out[#out+1]=table.concat({"K",layer,frame},"\t")
      for _,path in ipairs(v.tracks[layer][frame]) do
        out[#out+1]=table.concat({"P",path.id,path.closed and 1 or 0,
          fmt(path.width),colorFields(path.stroke),colorFields(path.fill)},"\t")
        for _,n in ipairs(path.nodes) do
          out[#out+1]=table.concat({"N",fmt(n.x),fmt(n.y),fmt(n.ix),fmt(n.iy),
            fmt(n.ox),fmt(n.oy)},"\t")
        end
        out[#out+1]="EP"
      end
      out[#out+1]="EK"
    end
  end
  out[#out+1]="END"
  return table.concat(out,"\n").."\n"
end
local function fields(s)
  local o={}
  for a in (s.."\t"):gmatch("(.-)\t") do o[#o+1]=a end
  return o
end
function M.decode(data)
  if type(data)~="string" or #data>8*1024*1024 then return nil,"invalid vector size" end
  local lines={}
  for s in (data.."\n"):gmatch("(.-)\n") do
    if s~="" then lines[#lines+1]=s:gsub("\r$","") end
  end
  if lines[1]~="LFVECTOR 1" then return nil,"unknown vector format" end
  local v=M.new()
  local layer,frame,path,ended,count=nil,nil,nil,false,0
  for i=2,#lines do
    local f=fields(lines[i])
    if ended then return nil,"trailing vector data" end
    if f[1]=="K" then
      local li,fr=tonumber(f[2]),tonumber(f[3])
      if layer or path or not int(li,1,128) or not int(fr,1,10000)
          or v.tracks[li] and v.tracks[li][fr] then
        return nil,"invalid vector key"
      end
      v.tracks[li]=v.tracks[li] or {}
      v.tracks[li][fr]={}
      layer,frame=li,fr
    elseif f[1]=="P" then
      local id,closed,width=tonumber(f[2]),f[3]=="1",tonumber(f[4])
      local stroke,e1=parseColor(f[5])
      local fill,e2=parseColor(f[6])
      if not layer or path or not int(id,1,10000000) or not finite(width)
          or width<.1 or width>200 or not stroke or e1 or e2
          or (f[3]~="0" and f[3]~="1")
          or #v.tracks[layer][frame]>=500 then return nil,"invalid vector path" end
      path={id=id,closed=closed,width=width,stroke=stroke,fill=fill,nodes={}}
      v.tracks[layer][frame][#v.tracks[layer][frame]+1]=path
      v.nextId=math.max(v.nextId,id+1)
      count=count+1
      if count>50000 then return nil,"too many vector paths" end
    elseif f[1]=="N" then
      if not path or #path.nodes>=256 then return nil,"invalid vector node" end
      local coords={}
      for j=2,7 do
        local value=tonumber(f[j])
        if not validPos(value) then return nil,"invalid coordinate" end
        coords[j-1]=value
      end
      path.nodes[#path.nodes+1]={
        x=coords[1],y=coords[2],ix=coords[3],iy=coords[4],
        ox=coords[5],oy=coords[6]
      }
    elseif f[1]=="EP" then
      if not path or #path.nodes<1 or path.closed and #path.nodes<3 then
        return nil,"invalid path termination"
      end
      path=nil
    elseif f[1]=="EK" then
      if not layer or path then return nil,"invalid key termination" end
      layer,frame=nil,nil
    elseif f[1]=="END" then
      if layer or path then return nil,"unfinished vector data" end
      ended=true
    else return nil,"unknown vector record" end
  end
  if not ended then return nil,"missing vector end" end
  return v
end
return M
