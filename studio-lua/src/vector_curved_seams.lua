-- Exact shared cubic seams for two closed, filled paths.
-- A common whole cubic is matched by all four controls in reverse order.
-- Other boundaries must be disjoint; then the two path boundaries can be
-- spliced without tessellating or changing the remaining Bezier controls.
local Flatten=require("src.bezier_flatten")
local M={}
local EPS=1e-7
local function near(a,b)
  return math.abs(a.x-b.x)<EPS and math.abs(a.y-b.y)<EPS
end
local function cross(ax,ay,bx,by) return ax*by-ay*bx end
local function controls(nodes,i)
  local n=nodes[i]
  local m=nodes[i%#nodes+1]
  return {{x=n.x,y=n.y},{x=n.ox,y=n.oy},
    {x=m.ix,y=m.iy},{x=m.x,y=m.y}}
end
local function reversedEqual(a,b)
  for i=1,4 do
    if not near(a[i],b[5-i]) then return false end
  end
  return true
end
local function pointIn(poly,p)
  local yes=false
  for i,a in ipairs(poly) do
    local b=poly[i%#poly+1]
    if (a.y>p.y)~=(b.y>p.y)
        and p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x then
      yes=not yes
    end
  end
  return yes
end
local function intersection(a,b,c,d)
  local rx,ry=b.x-a.x,b.y-a.y
  local sx,sy=d.x-c.x,d.y-c.y
  local qx,qy=c.x-a.x,c.y-a.y
  local det=cross(rx,ry,sx,sy)
  if math.abs(det)<1e-9 then
    if math.abs(cross(qx,qy,rx,ry))>1e-8 then return nil end
    local rr=rx*rx+ry*ry
    if rr<1e-12 then return "invalid" end
    local t=(qx*rx+qy*ry)/rr
    local u=((d.x-a.x)*rx+(d.y-a.y)*ry)/rr
    if math.min(1,math.max(t,u))-math.max(0,math.min(t,u))>1e-8 then
      return "coincident"
    end
    return nil
  end
  local t=cross(qx,qy,sx,sy)/det
  local u=cross(qx,qy,rx,ry)/det
  if t>=-1e-8 and t<=1+1e-8 and u>=-1e-8 and u<=1+1e-8 then
    return {x=a.x+rx*t,y=a.y+ry*t}
  end
  return nil
end
local function validContours(a,b,ai,bi)
  local pa,ea=Flatten.ringWithEdges(a,{tolerance=.08,maxPoints=512})
  local pb,eb=Flatten.ringWithEdges(b,{tolerance=.08,maxPoints=512})
  if not pa or not pb then return false end
  local sharedStart={x=a[ai].x,y=a[ai].y}
  local sharedEnd={x=a[ai%#a+1].x,y=a[ai%#a+1].y}
  -- All polygon pieces outside the shared cubic must lie outside the
  -- other's filled interior, including cases where both contours overlap
  -- only in a narrow area.
  for _,set in ipairs({
    {poly=pa,edges=ea,shared=ai,other=pb},
    {poly=pb,edges=eb,shared=bi,other=pa}
  }) do
    for i,p in ipairs(set.poly) do
      if set.edges[i] and set.edges[i].segment~=set.shared then
        local q=set.poly[i%#set.poly+1]
        if pointIn(set.other,{
          x=(p.x+q.x)*.5,y=(p.y+q.y)*.5
        }) then return false end
      end
    end
  end
  for i,p in ipairs(pa) do
    local q=pa[i%#pa+1]
    if ea[i] and ea[i].segment~=ai then
      for j,r in ipairs(pb) do
        local s=pb[j%#pb+1]
        if eb[j] and eb[j].segment~=bi then
          local pos=intersection(p,q,r,s)
          if pos then
            if type(pos)=="string" or
                not near(pos,sharedStart) and not near(pos,sharedEnd) then
              return false
            end
          end
        end
      end
    end
  end
  return true
end
local function combine(a,b,ai,bi)
  local pieces={}
  local function append(nodes,from,skip)
    for shift=0,#nodes-2 do
      local idx=(from-1+shift)%#nodes+1
      if idx~=skip then
        pieces[#pieces+1]=controls(nodes,idx)
      end
    end
  end
  append(a,ai%#a+1,ai)
  append(b,bi%#b+1,bi)
  if #pieces<3 or #pieces>256 then return nil end
  local nodes={}
  for i,c in ipairs(pieces) do
    local prev=pieces[(i-2)%#pieces+1]
    if not near(prev[4],c[1]) then return nil end
    nodes[i]={x=c[1].x,y=c[1].y,
      ix=prev[3].x,iy=prev[3].y,
      ox=c[2].x,oy=c[2].y}
  end
  return nodes
end
function M.plan(a,b,operation)
  if not a or not b or not a.closed or not b.closed or
      not a.fill or not b.fill or
      #(a.holes or {})>0 or #(b.holes or {})>0 or
      #a.nodes<3 or #b.nodes<3 then return false end
  local seamI,seamJ,count=nil,nil,0
  for i=1,#a.nodes do
    local ac=controls(a.nodes,i)
    for j=1,#b.nodes do
      if reversedEqual(ac,controls(b.nodes,j)) then
        count=count+1
        seamI,seamJ=i,j
      end
    end
  end
  if count~=1 then return false end
  if not validContours(a.nodes,b.nodes,seamI,seamJ) then
    -- Shared cubic is real but other boundaries are ambiguous: do not fall
    -- through to a polygon-only cutter that might discard the coincidence.
    return true,nil,"shared curved contour has overlapping or ambiguous interiors"
  end
  if operation=="intersection" then return true,nil,"empty result" end
  if operation=="difference" then
    return true,{{outer={},outerNodes=a.nodes,holes={},holeNodes={}}}
  end
  local nodes=combine(a.nodes,b.nodes,seamI,seamJ)
  if not nodes then return true,nil,"shared curved boundary cannot be joined" end
  return true,{{outer={},outerNodes=nodes,holes={},holeNodes={}}}
end
return M
