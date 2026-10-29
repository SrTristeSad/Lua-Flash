-- Conservative contact classification for filled vector outlines.
-- Only exact shared source anchors can establish a safe point-only touch.
-- Coincident boundaries and crossings remain unsupported by the polygon clipper.
local M={}
local EPS=1e-9
local function finite(x)
  return type(x)=="number" and x==x and math.abs(x)<math.huge
end
local function same(a,b)
  return math.abs(a.x-b.x)<=EPS and math.abs(a.y-b.y)<=EPS
end
local function cross(ax,ay,bx,by) return ax*by-ay*bx end
local function segmentContact(a,b,c,d)
  local rx,ry=b.x-a.x,b.y-a.y
  local sx,sy=d.x-c.x,d.y-c.y
  local qx,qy=c.x-a.x,c.y-a.y
  local det=cross(rx,ry,sx,sy)
  if math.abs(det)<EPS then
    if math.abs(cross(qx,qy,rx,ry))>EPS then return "none" end
    local rr=rx*rx+ry*ry
    if rr<EPS then return "invalid" end
    local t0=(qx*rx+qy*ry)/rr
    local t1=((d.x-a.x)*rx+(d.y-a.y)*ry)/rr
    local lo=math.max(0,math.min(t0,t1))
    local hi=math.min(1,math.max(t0,t1))
    if hi-lo>EPS then return "coincident" end
    if hi<lo-EPS then return "none" end
    return "touch",{
      x=a.x+rx*math.max(0,math.min(1,(lo+hi)/2)),
      y=a.y+ry*math.max(0,math.min(1,(lo+hi)/2))}
  end
  local t=cross(qx,qy,sx,sy)/det
  local u=cross(qx,qy,rx,ry)/det
  if t<-EPS or t>1+EPS or u<-EPS or u>1+EPS then
    return "none"
  end
  if t>EPS and t<1-EPS and u>EPS and u<1-EPS then
    return "cross"
  end
  return "touch",{x=a.x+rx*t,y=a.y+ry*t}
end
function M.classifyPolygons(a,b)
  if type(a)~="table" or type(b)~="table" or #a<3 or #b<3 then
    return nil,"invalid polygon"
  end
  local contacts={}
  for _,ring in ipairs({a,b}) do
    for _,p in ipairs(ring) do
      if not finite(p.x) or not finite(p.y) then
        return nil,"invalid coordinate"
      end
    end
  end
  for i,p in ipairs(a) do
    local q=a[i%#a+1]
    for j,r in ipairs(b) do
      local s=b[j%#b+1]
      local kind,position=segmentContact(p,q,r,s)
      if kind=="cross" or kind=="coincident" or kind=="invalid" then
        return kind
      end
      if kind=="touch" then
        local seen=false
        for _,contact in ipairs(contacts) do
          local dx,dy=contact.x-position.x,contact.y-position.y
          if dx*dx+dy*dy<=EPS*EPS then seen=true;break end
        end
        if not seen then contacts[#contacts+1]=position end
      end
    end
  end
  if #contacts>1 then return "multiple-touch" end
  if #contacts==1 then return "point",contacts[1] end
  return "disjoint"
end
local function isInside(poly,p)
  local inside=false
  for i,a in ipairs(poly) do
    local b=poly[i%#poly+1]
    if (a.y>p.y)~=(b.y>p.y)
        and p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x then
      inside=not inside
    end
  end
  return inside
end
local function originalAnchor(nodes,p)
  for _,node in ipairs(nodes) do
    if same(node,p) then return true end
  end
  return false
end
-- This specialization permits union/difference when simple shapes meet only
-- at one explicit anchor; the result has unchanged filled interiors.
-- No attempt is made to merge two outer loops at the touching point.
function M.safeCornerTouch(aRegion,bRegion,aPath,bPath)
  if #aRegion.holes~=0 or #bRegion.holes~=0 then return false end
  local a,b=aRegion.outer,bRegion.outer
  local kind,pos=M.classifyPolygons(a,b)
  if kind~="point" then return false end
  if not originalAnchor(aPath.nodes,pos) or not originalAnchor(bPath.nodes,pos) then
    return false
  end
  for _,p in ipairs(a) do
    if not same(p,pos) and isInside(b,p) then return false end
  end
  for _,p in ipairs(b) do
    if not same(p,pos) and isInside(a,p) then return false end
  end
  return true
end
local function colorlessCopy(nodes)
  local out={}
  for i,n in ipairs(nodes) do
    out[i]={x=n.x,y=n.y,ix=n.ix,iy=n.iy,ox=n.ox,oy=n.oy}
  end
  return out
end
-- Exact cyclic geometry including handles; avoids merging merely similar
-- shapes at tessellation resolution.
function M.identical(a,b)
  if not a or not b or not a.closed or not b.closed
      or #(a.holes or {})~=0 or #(b.holes or {})~=0 then return false end
  local aa,bb=a.nodes,b.nodes
  if #aa~=#bb or #aa<3 then return false end
  for offset=1,#bb do
    for _,dir in ipairs({1,-1}) do
      local ok=true
      for i=1,#aa do
        local j=(offset-1+(i-1)*dir)%#bb+1
        local an,bn=aa[i],bb[j]
        if not same(an,bn) then ok=false;break end
        local inX,inY,outX,outY=bn.ix,bn.iy,bn.ox,bn.oy
        if dir==-1 then inX,inY,outX,outY=outX,outY,inX,inY end
        if math.abs(an.ix-inX)>EPS or math.abs(an.iy-inY)>EPS
            or math.abs(an.ox-outX)>EPS or math.abs(an.oy-outY)>EPS then
          ok=false;break
        end
      end
      if ok then return true end
    end
  end
  return false
end
function M.originalResult(path)
  return {outer={},outerNodes=colorlessCopy(path.nodes),holes={},holeNodes={}}
end
return M
