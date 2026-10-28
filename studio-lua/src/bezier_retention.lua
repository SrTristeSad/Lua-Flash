-- Reconstruct untouched PARTS of original cubic paths after polygonal Boolean clipping.
-- Intersection locations remain approximated within the adaptive tolerance.
-- A clipped cubic's controls are translated at its endpoints to meet the
-- shared polygon intersection exactly, avoiding cracks in compound rings.
local M={}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function key(a,b)
  return string.format("%.6f,%.6f>%.6f,%.6f",a.x,a.y,b.x,b.y)
end
function M.lookup(samples,metadata,nodes)
  local out={}
  for i,a in ipairs(samples) do
    local b=samples[i%#samples+1]
    local info=metadata[i]
    if info then
      out[key(a,b)]={nodes=nodes,segment=info.segment,
        t0=info.t0,t1=info.t1}
      out[key(b,a)]={nodes=nodes,segment=info.segment,
        t0=info.t1,t1=info.t0}
    end
  end
  return out
end
function M.get(lookup,a,b)
  return lookup and lookup[key(a,b)] or nil
end
local function pt(x,y) return {x=x,y=y} end
local function interpolate(a,b,t)
  return pt(a.x+(b.x-a.x)*t,a.y+(b.y-a.y)*t)
end
local function split(points,t)
  local a=interpolate(points[1],points[2],t)
  local b=interpolate(points[2],points[3],t)
  local c=interpolate(points[3],points[4],t)
  local d=interpolate(a,b,t)
  local e=interpolate(b,c,t)
  local m=interpolate(d,e,t)
  return {points[1],a,d,m},{m,e,c,points[4]}
end
local function subcurve(nodes,segment,t0,t1)
  local n=nodes[segment]
  local other=nodes[segment%#nodes+1]
  if not n or not other or not finite(t0) or not finite(t1)
      or t0<0 or t0>1 or t1<0 or t1>1 then return nil end
  local reversed=t0>t1
  local lo,hi=math.min(t0,t1),math.max(t0,t1)
  if hi-lo<1e-10 then return nil end
  local points={pt(n.x,n.y),pt(n.ox,n.oy),pt(other.ix,other.iy),
    pt(other.x,other.y)}
  if hi<1 then points=select(1,split(points,hi)) end
  if lo>0 then
    local _,right=split(points,lo/hi)
    points=right
  end
  if reversed then
    points={points[4],points[3],points[2],points[1]}
  end
  return points
end
local function cubicFor(edge)
  local m=edge.meta
  local points=m and subcurve(m.nodes,m.segment,m.t0,m.t1)
  if not points then
    return {pt(edge.a.x,edge.a.y),pt(edge.a.x,edge.a.y),
      pt(edge.b.x,edge.b.y),pt(edge.b.x,edge.b.y)}
  end
  local startDx,startDy=edge.a.x-points[1].x,edge.a.y-points[1].y
  local endDx,endDy=edge.b.x-points[4].x,edge.b.y-points[4].y
  points[1]=pt(edge.a.x,edge.a.y)
  points[2]=pt(points[2].x+startDx,points[2].y+startDy)
  points[3]=pt(points[3].x+endDx,points[3].y+endDy)
  points[4]=pt(edge.b.x,edge.b.y)
  return points
end
local function compatible(a,b)
  return a and b and a.meta and b.meta
    and a.meta.nodes==b.meta.nodes
    and a.meta.segment==b.meta.segment
    and math.abs(a.meta.t1-b.meta.t0)<1e-7
end
function M.fromEdges(edges,maxNodes)
  if not edges or #edges<3 then return nil,"invalid Boolean boundary" end
  local runs={}
  for _,edge in ipairs(edges) do
    local current=runs[#runs]
    if current and compatible(current,edge) then
      current.b=edge.b
      current.meta.t1=edge.meta.t1
    else
      local m=edge.meta
      runs[#runs+1]={a=edge.a,b=edge.b,meta=m and {
        nodes=m.nodes,segment=m.segment,t0=m.t0,t1=m.t1} or nil}
    end
  end
  -- Unwrap a cubic that happens to straddle the ring's arbitrary first edge.
  if #runs>1 and compatible(runs[#runs],runs[1]) then
    local last=table.remove(runs)
    runs[1].a=last.a
    runs[1].meta.t0=last.meta.t0
  end
  if #runs<3 or #runs>(maxNodes or 256) then
    -- A single or two cubic segments are a valid closed lens; no 3-node
    -- requirement is imposed on the internal cubic segments themselves.
    if #runs>(maxNodes or 256) then return nil,"Bezier output node limit" end
  end
  local pieces={}
  for i,edge in ipairs(runs) do
    local c=cubicFor(edge)
    for _,p in ipairs(c) do
      if not finite(p.x) or not finite(p.y) or
          math.abs(p.x)>100000 or math.abs(p.y)>100000 then
        return nil,"Bezier control coordinate limit"
      end
    end
    pieces[i]=c
  end
  -- Even a two-piece contour is valid if it has at least three non-collinear
  -- anchors? LFVECTOR requires three nodes for a closed path. Insert a split
  -- if needed; the existing polygon fallback remains the safe alternative.
  if #pieces<3 then return nil,"fewer than three cubic segments" end
  local nodes={}
  for i,c in ipairs(pieces) do
    local prev=pieces[(i-2)%#pieces+1]
    nodes[i]={x=c[1].x,y=c[1].y,ix=prev[3].x,iy=prev[3].y,
      ox=c[2].x,oy=c[2].y}
  end
  return nodes
end
return M
