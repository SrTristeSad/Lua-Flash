-- Studio-only Bézier segment / path editing operations.
-- Every plan validates first. Call apply() only after recording Studio undo.
local V=require("src.vector_paths")
local M={}
local function valid(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function integer(v) return valid(v) and v==math.floor(v) end
local function clone(value)
  if type(value)~="table" then return value end
  local result={}
  for k,v in pairs(value) do result[k]=clone(v) end
  return result
end
local function lerp(a,b,t) return a+(b-a)*t end
local function coords(a,b,t)
  return {x=lerp(a.x,b.x,t),y=lerp(a.y,b.y,t)}
end
local function dist2(ax,ay,bx,by)
  return (ax-bx)^2+(ay-by)^2
end
local function locate(scope,layer,frame,id)
  if not scope or not integer(layer) or layer<1 or layer>128
      or not integer(frame) or frame<1 or frame>10000
      or not integer(id) then return nil end
  local items=V.at(scope,layer,frame)
  for i,path in ipairs(items) do if path.id==id then return path,i end end
  return nil
end
-- Cubic P0,P1,P2,P3. Split with De Casteljau, retaining exactly the same curve.
function M.splitSegment(path,segment,t)
  local count=path and #path.nodes or 0
  if not integer(segment) or segment<1
      or segment>(path.closed and count or count-1)
      or not valid(t) or t<=.001 or t>=.999 or count>=256 then
    return false,"invalid segment or parameter"
  end
  local nextIndex=segment%count+1
  local a,b=path.nodes[segment],path.nodes[nextIndex]
  local p0={x=a.x,y=a.y}
  local p1={x=a.ox,y=a.oy}
  local p2={x=b.ix,y=b.iy}
  local p3={x=b.x,y=b.y}
  local q0,q1,q2=coords(p0,p1,t),coords(p1,p2,t),coords(p2,p3,t)
  local r0,r1=coords(q0,q1,t),coords(q1,q2,t)
  local p=coords(r0,r1,t)
  for _,pt in ipairs({q0,q1,q2,r0,r1,p}) do
    if not valid(pt.x) or not valid(pt.y)
        or math.abs(pt.x)>100000 or math.abs(pt.y)>100000 then
      return false,"coordinate limit"
    end
  end
  a.ox,a.oy=q0.x,q0.y
  b.ix,b.iy=q2.x,q2.y
  local inserted={x=p.x,y=p.y,ix=r0.x,iy=r0.y,ox=r1.x,oy=r1.y}
  table.insert(path.nodes,segment+1,inserted)
  return true,segment+1
end
-- Hit test uses polyline approximation only to find the segment and parameter;
-- the actual split is exact at that selected t.
function M.pickSegment(paths,x,y,tolerance)
  if not valid(x) or not valid(y) or not valid(tolerance) or tolerance<=0 then
    return nil
  end
  local limit=tolerance*tolerance
  local closest,ci,ct,best=nil,nil,nil,limit
  for i=#paths,1,-1 do
    local path=paths[i]
    local nodes=path.nodes
    local count=path.closed and #nodes or #nodes-1
    for segment=1,count do
      local a,b=nodes[segment],nodes[segment%#nodes+1]
      local px,py=a.x,a.y
      for step=1,40 do
        local t=step/40
        local q=1-t
        local vx=q^3*a.x+3*q*q*t*a.ox+3*q*t*t*b.ix+t^3*b.x
        local vy=q^3*a.y+3*q*q*t*a.oy+3*q*t*t*b.iy+t^3*b.y
        local dx,dy=vx-px,vy-py
        local d=dx*dx+dy*dy
        local f=d>0 and math.max(0,math.min(1,
          ((x-px)*dx+(y-py)*dy)/d)) or 0
        local cx,cy=px+f*dx,py+f*dy
        local distance=dist2(x,y,cx,cy)
        if distance<=best then
          best=distance
          closest=path
          ci=segment
          ct=(step-1+f)/40
        end
        px,py=vx,vy
      end
    end
  end
  if not closest or ct<=.001 or ct>=.999 then return nil end
  return closest,ci,ct
end
-- Bend an existing cubic without moving its endpoints. The same offset is
-- applied to the two controls, divided by their combined Bernstein weight,
-- so the curve passes through the dragged position at parameter t.
function M.bendSegment(path,segment,t,dx,dy)
  local count=path and #path.nodes or 0
  if not integer(segment) or segment<1
      or segment>(path.closed and count or count-1)
      or not valid(t) or t<.05 or t>.95
      or not valid(dx) or not valid(dy) then
    return nil,"invalid segment drag"
  end
  local result=clone(path)
  local a=result.nodes[segment]
  local b=result.nodes[segment%count+1]
  local factor=1/(3*t*(1-t))
  local points={{a.ox+dx*factor,a.oy+dy*factor},
    {b.ix+dx*factor,b.iy+dy*factor}}
  for _,p in ipairs(points) do
    if not valid(p[1]) or not valid(p[2]) or
        math.abs(p[1])>100000 or math.abs(p[2])>100000 then
      return nil,"coordinate limit"
    end
  end
  a.ox,a.oy=points[1][1],points[1][2]
  b.ix,b.iy=points[2][1],points[2][2]
  return result
end
function M.planBend(scope,layer,frame,id,segment,t,dx,dy)
  local path=locate(scope,layer,frame,id)
  if not path then return nil,"path not found" end
  local result,err=M.bendSegment(path,segment,t,dx,dy)
  if not result then return nil,err end
  return {id=id,apply=function()
    local paths=V.ensureKey(scope,layer,frame)
    for i,p in ipairs(paths) do
      if p.id==id then paths[i]=result;return end
    end
    error("path changed before bend")
  end}
end

function M.planInsert(scope,layer,frame,id,segment,t)
  local path=locate(scope,layer,frame,id)
  if not path then return nil,"path not found" end
  local updated=clone(path)
  local ok,index=M.splitSegment(updated,segment,t)
  if not ok then return nil,index end
  return {id=id,index=index,apply=function()
    local target=V.ensureKey(scope,layer,frame)
    for i,item in ipairs(target) do
      if item.id==id then target[i]=updated;return end
    end
    error("path changed before split")
  end}
end
-- Splitting a path at an existing interior anchor produces two open paths;
-- the new part receives a fresh stable ID.
function M.planBreak(scope,layer,frame,id,index)
  local path=locate(scope,layer,frame,id)
  if not path or path.closed or not integer(index)
      or index<=1 or index>=#path.nodes
      or not integer(scope.nextId) or scope.nextId>10000000 then
    return nil,"interior anchor required on open path"
  end
  if #V.at(scope,layer,frame)>=500 then return nil,"path limit" end
  local first,second=clone(path),clone(path)
  first.nodes,second.nodes={},{}
  for n=1,index do first.nodes[#first.nodes+1]=clone(path.nodes[n]) end
  for n=index,#path.nodes do second.nodes[#second.nodes+1]=clone(path.nodes[n]) end
  local a=first.nodes[#first.nodes]
  a.ox,a.oy=a.x,a.y
  local b=second.nodes[1]
  b.ix,b.iy=b.x,b.y
  second.id=scope.nextId
  return {firstId=id,secondId=second.id,apply=function()
    local items=V.ensureKey(scope,layer,frame)
    if #items>=500 then error("path limit") end
    for i,item in ipairs(items) do
      if item.id==id then
        items[i]=first
        table.insert(items,i+1,second)
        scope.nextId=scope.nextId+1
        return
      end
    end
    error("path changed before break")
  end}
end
local function reversed(nodes)
  local out={}
  for i=#nodes,1,-1 do
    local n=nodes[i]
    out[#out+1]={x=n.x,y=n.y,ix=n.ox,iy=n.oy,ox=n.ix,oy=n.iy}
  end
  return out
end
-- Join two open paths along the closest pair of endpoints, including
-- reversed orientation. Endpoint welding allows at most maxDistance pixels.
function M.planJoin(scope,layer,frame,aId,bId,maxDistance)
  if aId==bId then return nil,"select distinct paths" end
  local a=locate(scope,layer,frame,aId)
  local b=locate(scope,layer,frame,bId)
  maxDistance=maxDistance or 12
  if not a or not b or a.closed or b.closed
      or #a.nodes<2 or #b.nodes<2
      or not valid(maxDistance) or maxDistance<0 or maxDistance>100 then
    return nil,"two open paths required"
  end
  if #a.nodes+#b.nodes-1>256 then return nil,"point limit" end
  local best,reverseA,reverseB
  for _,ra in ipairs({false,true}) do
    for _,rb in ipairs({false,true}) do
      local na=ra and a.nodes[1] or a.nodes[#a.nodes]
      local nb=rb and b.nodes[#b.nodes] or b.nodes[1]
      local d=dist2(na.x,na.y,nb.x,nb.y)
      if not best or d<best then best,reverseA,reverseB=d,ra,rb end
    end
  end
  if best>maxDistance*maxDistance then return nil,"endpoints too far apart" end
  local first=reverseA and reversed(a.nodes) or clone(a.nodes)
  local second=reverseB and reversed(b.nodes) or clone(b.nodes)
  local endA,startB=first[#first],second[1]
  -- Keep A's anchor stationary, graft B's outgoing handle relative to its start.
  endA.ox=endA.x+(startB.ox-startB.x)
  endA.oy=endA.y+(startB.oy-startB.y)
  for i=2,#second do first[#first+1]=second[i] end
  local merged=clone(a)
  merged.nodes=first
  merged.fill=nil
  -- Refuse joins of stroke styles that differ rather than silently dropping B's.
  if a.width~=b.width or #a.stroke~=#b.stroke then return nil,"stroke styles differ" end
  for i=1,#a.stroke do
    if math.abs(a.stroke[i]-b.stroke[i])>1e-6 then return nil,"stroke styles differ" end
  end
  for _,n in ipairs(first) do
    for _,key in ipairs({"x","y","ix","iy","ox","oy"}) do
      if not valid(n[key]) or math.abs(n[key])>100000 then
        return nil,"coordinate limit"
      end
    end
  end
  return {id=aId,removed=bId,apply=function()
    local items=V.ensureKey(scope,layer,frame)
    local ia,ib
    for i,p in ipairs(items) do
      if p.id==aId then ia=i elseif p.id==bId then ib=i end
    end
    if not ia or not ib then error("paths changed before join") end
    items[ia]=merged
    table.remove(items,ib)
  end}
end
-- Closed boundaries must accept a fill click even if they are currently
-- unfilled. Stroke selection in V.hit cannot cover this case by itself.
local function contains(path,x,y)
  local pts=V.sample(path,24)
  if #pts<6 then return false end
  local hit=false
  local prev=#pts-1
  for i=1,#pts-1,2 do
    local ax,ay=pts[i],pts[i+1]
    local bx,by=pts[prev],pts[prev+1]
    if (ay>y)~=(by>y) and x<(bx-ax)*(y-ay)/(by-ay)+ax then
      hit=not hit
    end
    prev=i
  end
  return hit
end
-- Fill the topmost CLOSED path under cursor regardless of its old fill.
function M.pickFill(paths,x,y)
  if not valid(x) or not valid(y) then return nil end
  for i=#paths,1,-1 do
    local p=paths[i]
    if p.closed and (contains(p,x,y) or V.hit(p,x,y,2)) then return p end
  end
  return nil
end
function M.planFill(scope,layer,frame,id,color)
  local p=locate(scope,layer,frame,id)
  if not p or not p.closed then return nil,"closed path required" end
  if color~=nil then
    if type(color)~="table" or #color<3 or #color>4 then return nil,"invalid fill" end
    for _,v in ipairs(color) do
      if not valid(v) or v<0 or v>1 then return nil,"invalid fill" end
    end
  end
  local newColor=color and clone(color) or nil
  return {id=id,apply=function()
    local paths=V.ensureKey(scope,layer,frame)
    for _,path in ipairs(paths) do
      if path.id==id then path.fill=newColor;return end
    end
    error("path changed before fill")
  end}
end
return M
