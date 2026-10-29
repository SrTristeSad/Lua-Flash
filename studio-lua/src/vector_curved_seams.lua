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
local reversedEqual
local function cloneNodes(nodes)
  local out={}
  for i,n in ipairs(nodes) do
    out[i]={x=n.x,y=n.y,ix=n.ix,iy=n.iy,ox=n.ox,oy=n.oy}
  end
  return out
end
local function blend(a,b,t)
  return {x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t}
end
local function halves(p,t)
  local a,b,c=blend(p[1],p[2],t),blend(p[2],p[3],t),
    blend(p[3],p[4],t)
  local d,e=blend(a,b,t),blend(b,c,t)
  local mid=blend(d,e,t)
  return {p[1],a,d,mid},{mid,e,c,p[4]}
end
local function portion(p,lo,hi)
  local source=p
  if hi<1 then source=select(1,halves(source,hi)) end
  if lo>0 then
    local _,right=halves(source,lo/hi)
    source=right
  end
  return source
end
local function evaluate(p,t)
  local u=1-t
  return {
    x=u*u*u*p[1].x+3*u*u*t*p[2].x+3*u*t*t*p[3].x+t*t*t*p[4].x,
    y=u*u*u*p[1].y+3*u*u*t*p[2].y+3*u*t*t*p[3].y+t*t*t*p[4].y
  }
end
local function nearestParameter(p,target)
  -- Only used as a candidate generator. Matching all four subcurve
  -- controls later establishes actual geometry, not this approximation.
  local bestT,bestDist=0,math.huge
  for i=0,64 do
    local t=i/64
    local q=evaluate(p,t)
    local d=(q.x-target.x)^2+(q.y-target.y)^2
    if d<bestDist then bestT,bestDist=t,d end
  end
  local low=math.max(0,bestT-1/64)
  local high=math.min(1,bestT+1/64)
  for _=1,45 do
    local t1=low+(high-low)/3
    local t2=high-(high-low)/3
    local p1,p2=evaluate(p,t1),evaluate(p,t2)
    local d1=(p1.x-target.x)^2+(p1.y-target.y)^2
    local d2=(p2.x-target.x)^2+(p2.y-target.y)^2
    if d1<d2 then high=t2 else low=t1 end
  end
  local t=(low+high)*.5
  local q=evaluate(p,t)
  if (q.x-target.x)^2+(q.y-target.y)^2>1e-12 then return nil end
  return t
end
local function insertAnchor(nodes,index,t)
  local p=controls(nodes,index)
  local left,right=halves(p,t)
  nodes[index].ox,nodes[index].oy=left[2].x,left[2].y
  local nextIndex=index%#nodes+1
  local nextNode=nodes[nextIndex]
  nextNode.ix,nextNode.iy=right[3].x,right[3].y
  table.insert(nodes,index+1,{
    x=left[4].x,y=left[4].y,
    ix=left[3].x,iy=left[3].y,
    ox=right[2].x,oy=right[2].y
  })
end
local function partialSeam(longer,shorter)
  for i=1,#longer do
    local p=controls(longer,i)
    for j=1,#shorter do
      local q=controls(shorter,j)
      local lo=nearestParameter(p,q[4])
      local hi=nearestParameter(p,q[1])
      if lo and hi and hi-lo>1e-6 and
          (lo>1e-6 or hi<1-1e-6) then
        if reversedEqual(portion(p,lo,hi),q) then
          local expanded=cloneNodes(longer)
          local seam=i
          if hi<1-1e-6 then insertAnchor(expanded,i,hi) end
          if lo>1e-6 then
            insertAnchor(expanded,i,lo/(hi<1-1e-6 and hi or 1))
            seam=i+1
          end
          if reversedEqual(controls(expanded,seam),q) then
            return expanded,seam,j
          end
        end
      end
    end
  end
  return nil
end
reversedEqual=function(a,b)
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
  local aNodes,bNodes=a.nodes,b.nodes
  if count==0 then
    local adjusted,ai,bj=partialSeam(a.nodes,b.nodes)
    if adjusted then
      aNodes,seamI,seamJ=adjusted,ai,bj
      count=1
    else
      adjusted,bj,ai=partialSeam(b.nodes,a.nodes)
      if adjusted then
        bNodes,seamI,seamJ=adjusted,ai,bj
        count=1
      end
    end
  end
  if count~=1 then return false end
  if not validContours(aNodes,bNodes,seamI,seamJ) then
    -- Shared cubic is real but other boundaries are ambiguous: do not fall
    -- through to a polygon-only cutter that might discard the coincidence.
    return true,nil,"shared curved contour has overlapping or ambiguous interiors"
  end
  if operation=="intersection" then return true,nil,"empty result" end
  if operation=="difference" then
    return true,{{outer={},outerNodes=a.nodes,holes={},holeNodes={}}}
  end
  local nodes=combine(aNodes,bNodes,seamI,seamJ)
  if not nodes then return true,nil,"shared curved boundary cannot be joined" end
  return true,{{outer={},outerNodes=nodes,holes={},holeNodes={}}}
end
return M
