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
local function onStraightArc(nodes,p)
  for i,a in ipairs(nodes) do
    local b=nodes[i%#nodes+1]
    local dx,dy=b.x-a.x,b.y-a.y
    local length2=dx*dx+dy*dy
    if length2>EPS*EPS then
      local function validControl(x,y)
        local px,py=x-a.x,y-a.y
        local t=(px*dx+py*dy)/length2
        return math.abs(cross(dx,dy,px,py))<=EPS*math.sqrt(length2)
          and t>=-EPS and t<=1+EPS
      end
      local px,py=p.x-a.x,p.y-a.y
      local t=(px*dx+py*dy)/length2
      if validControl(a.ox,a.oy) and validControl(b.ix,b.iy)
          and math.abs(cross(dx,dy,px,py))<=EPS*math.sqrt(length2)
          and t>=-EPS and t<=1+EPS then
        return true
      end
    end
  end
  return false
end
local function onNonlinearArc(nodes,p)
  -- Find an exact closest-point root numerically. Candidate search is not
  -- proof: require residual < 1e-8 and a transverse derivative so a cusp
  -- cannot masquerade as a regular tangent contact.
  local candidates=0
  for i,a in ipairs(nodes) do
    local b=nodes[i%#nodes+1]
    local c={{x=a.x,y=a.y},{x=a.ox,y=a.oy},
      {x=b.ix,y=b.iy},{x=b.x,y=b.y}}
    local function at(t)
      local u=1-t
      return {
        x=u^3*c[1].x+3*u*u*t*c[2].x+3*u*t*t*c[3].x+t^3*c[4].x,
        y=u^3*c[1].y+3*u*u*t*c[2].y+3*u*t*t*c[3].y+t^3*c[4].y
      }
    end
    local best,bestD=0,math.huge
    for step=0,64 do
      local t=step/64
      local q=at(t)
      local d=(q.x-p.x)^2+(q.y-p.y)^2
      if d<bestD then best,bestD=t,d end
    end
    if bestD<4 then
      local lo=math.max(0,best-1/64)
      local hi=math.min(1,best+1/64)
      for _=1,48 do
        local lt=lo+(hi-lo)/3
        local rt=hi-(hi-lo)/3
        local left,right=at(lt),at(rt)
        local ld=(left.x-p.x)^2+(left.y-p.y)^2
        local rd=(right.x-p.x)^2+(right.y-p.y)^2
        if ld<rd then hi=rt else lo=lt end
      end
      local t=(lo+hi)*.5
      local q=at(t)
      if t>1e-5 and t<1-1e-5 and
          (q.x-p.x)^2+(q.y-p.y)^2<1e-14 then
        local u=1-t
        local dx=3*(u*u*(c[2].x-c[1].x)+
          2*u*t*(c[3].x-c[2].x)+t*t*(c[4].x-c[3].x))
        local dy=3*(u*u*(c[2].y-c[1].y)+
          2*u*t*(c[3].y-c[2].y)+t*t*(c[4].y-c[3].y))
        if dx*dx+dy*dy>1e-8 then
          candidates=candidates+1
        end
      end
    end
  end
  return candidates==1
end
local function onOriginalArc(nodes,p)
  return onStraightArc(nodes,p) or onNonlinearArc(nodes,p)
end
-- Supports a single exact original-anchor contact with the interior of
-- another cubic, including curved arcs. Ambiguous or crossing contacts are
-- still rejected rather than interpreted as tangent fills.
function M.safeCornerTouch(aRegion,bRegion,aPath,bPath)
  if #aRegion.holes~=0 or #bRegion.holes~=0 then return false end
  local a,b=aRegion.outer,bRegion.outer
  local kind,pos=M.classifyPolygons(a,b)
  if kind~="point" and kind~="disjoint" then return false end
  if kind=="disjoint" then
    -- Polygon chords may miss a real exact contact on a curved interior.
    -- Locate it on the ORIGINAL cubics; require one unique contact only.
    local contacts={}
    local function consider(p)
      for _,q in ipairs(contacts) do if same(p,q) then return end end
      contacts[#contacts+1]={x=p.x,y=p.y}
    end
    for _,node in ipairs(aPath.nodes) do
      if onOriginalArc(bPath.nodes,node) then consider(node) end
    end
    for _,node in ipairs(bPath.nodes) do
      if onOriginalArc(aPath.nodes,node) then consider(node) end
    end
    if #contacts~=1 then return false end
    pos=contacts[1]
  end
  local anchorA=originalAnchor(aPath.nodes,pos)
  local anchorB=originalAnchor(bPath.nodes,pos)
  if not anchorA and not anchorB then return false end
  if not anchorA and not onOriginalArc(aPath.nodes,pos) then return false end
  if not anchorB and not onOriginalArc(bPath.nodes,pos) then return false end
  -- Reject a hidden transverse crossing missed by the polygonal outline.
  -- Tangencies do not appear as roots in this transverse-only detector.
  if kind=="disjoint" then
    local Detector=require("src.cubic_detection")
    local hits=Detector.detect(aPath.nodes,bPath.nodes,{maxVisits=12000})
    if not hits then return false end
    for _,hit in ipairs(hits) do
      local dx,dy=hit.point.x-pos.x,hit.point.y-pos.y
      if dx*dx+dy*dy>1e-8 then return false end
      -- A root at the same contact must terminate at an actual anchor of
      -- at least one source cubic; interior/interior transversal crossings
      -- are not safe point tangencies.
      local endpoint=hit.aT<=1e-6 or hit.aT>=1-1e-6 or
        hit.bT<=1e-6 or hit.bT>=1-1e-6
      if not endpoint then return false end
    end
  end
  for _,p in ipairs(a) do
    if not same(p,pos) and isInside(b,p) then return false end
  end
  for _,p in ipairs(b) do
    if not same(p,pos) and isInside(a,p) then return false end
  end
  return true
end
-- Recognize actual axis-aligned RECTANGLES with monotone straight
-- Bezier handles. This is a deliberately narrow exact specialization:
-- only two rectangles sharing a positive-length boundary and having
-- disjoint interiors are supported. Other coincident/curved edges remain
-- rejected by the general polygon clipper.
local function axisRectangle(path)
  if not path or not path.closed or path.holes and #path.holes>0
      or #path.nodes~=4 then return nil end
  local x1,y1,x2,y2
  for _,n in ipairs(path.nodes) do
    if not finite(n.x) or not finite(n.y) then return nil end
    x1=x1 and math.min(x1,n.x) or n.x
    y1=y1 and math.min(y1,n.y) or n.y
    x2=x2 and math.max(x2,n.x) or n.x
    y2=y2 and math.max(y2,n.y) or n.y
  end
  if x2-x1<=EPS or y2-y1<=EPS then return nil end
  local seen={}
  for i,n in ipairs(path.nodes) do
    local m=path.nodes[i%4+1]
    local sideX=math.abs(n.x-m.x)<=EPS
    local sideY=math.abs(n.y-m.y)<=EPS
    if sideX==sideY then return nil end
    local function handle(x,y)
      if not finite(x) or not finite(y) then return false end
      local dx,dy=m.x-n.x,m.y-n.y
      local len2=dx*dx+dy*dy
      local px,py=x-n.x,y-n.y
      local t=(px*dx+py*dy)/len2
      return t>=-EPS and t<=1+EPS
        and math.abs(cross(dx,dy,px,py))<=EPS*math.sqrt(len2)
    end
    if not handle(n.ox,n.oy) or not handle(m.ix,m.iy) then return nil end
    local k=(math.abs(n.x-x1)<=EPS and "L" or
      math.abs(n.x-x2)<=EPS and "R" or "?")..
      (math.abs(n.y-y1)<=EPS and "T" or
       math.abs(n.y-y2)<=EPS and "B" or "?")
    if k:find("?",1,true) or seen[k] then return nil end
    seen[k]=true
  end
  if not (seen.LT and seen.RT and seen.RB and seen.LB) then return nil end
  return {x1=x1,y1=y1,x2=x2,y2=y2}
end
local function lineKey(x,y)
  return string.format("%.8f:%.8f",x,y)
end
local function simplifyPolygon(points)
  local changed=true
  while changed and #points>3 do
    changed=false
    for i=1,#points do
      local a=points[(i-2)%#points+1]
      local b=points[i]
      local c=points[i%#points+1]
      if math.abs(cross(b.x-a.x,b.y-a.y,c.x-b.x,c.y-b.y))<=EPS then
        table.remove(points,i)
        changed=true
        break
      end
    end
  end
  return points
end
local function rectangleUnion(a,b)
  local xs={a.x1,a.x2,b.x1,b.x2}
  local ys={a.y1,a.y2,b.y1,b.y2}
  local function unique(values)
    table.sort(values)
    local out={}
    for _,v in ipairs(values) do
      if #out==0 or math.abs(v-out[#out])>EPS then out[#out+1]=v end
    end
    return out
  end
  xs,ys=unique(xs),unique(ys)
  local occupied={}
  local function filled(x,y)
    return (x>a.x1 and x<a.x2 and y>a.y1 and y<a.y2) or
      (x>b.x1 and x<b.x2 and y>b.y1 and y<b.y2)
  end
  for i=1,#xs-1 do
    occupied[i]={}
    for j=1,#ys-1 do
      occupied[i][j]=filled((xs[i]+xs[i+1])*.5,(ys[j]+ys[j+1])*.5)
    end
  end
  local segments,starts={},{}
  local function edge(x1,y1,x2,y2)
    local first=lineKey(x1,y1)
    if starts[first] then return false end
    segments[#segments+1]={a={x=x1,y=y1},b={x=x2,y=y2}}
    starts[first]=#segments
    return true
  end
  for i=1,#xs-1 do
    for j=1,#ys-1 do
      if occupied[i][j] then
        local x1,x2,y1,y2=xs[i],xs[i+1],ys[j],ys[j+1]
        if not (occupied[i][j-1]) then
          if not edge(x1,y1,x2,y1) then return nil end
        end
        if not (occupied[i+1] and occupied[i+1][j]) then
          if not edge(x2,y1,x2,y2) then return nil end
        end
        if not occupied[i][j+1] then
          if not edge(x2,y2,x1,y2) then return nil end
        end
        if not (occupied[i-1] and occupied[i-1][j]) then
          if not edge(x1,y2,x1,y1) then return nil end
        end
      end
    end
  end
  local polygon,used={},{}
  local current=1
  for _=1,#segments do
    if not current or used[current] then return nil end
    used[current]=true
    local e=segments[current]
    polygon[#polygon+1]=e.a
    current=starts[lineKey(e.b.x,e.b.y)]
  end
  if current~=1 then return nil end
  simplifyPolygon(polygon)
  if #polygon<4 or #polygon>256 then return nil end
  local nodes={}
  for i,p in ipairs(polygon) do
    nodes[i]={x=p.x,y=p.y,ix=p.x,iy=p.y,ox=p.x,oy=p.y}
  end
  return nodes
end
function M.sharedRectangle(a,b,operation)
  local ra,rb=axisRectangle(a),axisRectangle(b)
  if not ra or not rb then return false end
  local overlapX=math.min(ra.x2,rb.x2)-math.max(ra.x1,rb.x1)
  local overlapY=math.min(ra.y2,rb.y2)-math.max(ra.y1,rb.y1)
  if overlapX>EPS and overlapY>EPS then return false end
  if not ((math.abs(overlapX)<=EPS and overlapY>EPS) or
      (math.abs(overlapY)<=EPS and overlapX>EPS)) then
    return false
  end
  if operation=="intersection" then return true,nil,"empty result" end
  if operation=="difference" then return true,{M.originalResult(a)} end
  local nodes=rectangleUnion(ra,rb)
  if not nodes then return true,nil,"unsupported shared rectangle topology" end
  return true,{{outer={},outerNodes=nodes,holes={},holeNodes={}}}
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
local function sameRing(aa,bb)
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
function M.identical(a,b)
  if not a or not b or not a.closed or not b.closed or
      not sameRing(a.nodes,b.nodes) then return false end
  local ah,bh=a.holes or {},b.holes or {}
  if #ah~=#bh then return false end
  local used={}
  for _,hole in ipairs(ah) do
    local match=nil
    for j,other in ipairs(bh) do
      if not used[j] and sameRing(hole,other) then
        match=j
        break
      end
    end
    if not match then return false end
    used[match]=true
  end
  return true
end
function M.originalResult(path)
  local holes={}
  for _,hole in ipairs(path.holes or {}) do
    holes[#holes+1]=colorlessCopy(hole)
  end
  return {outer={},outerNodes=colorlessCopy(path.nodes),
    holes=holes,holeNodes=holes}
end
return M
