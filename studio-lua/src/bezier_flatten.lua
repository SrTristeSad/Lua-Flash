-- Adaptive cubic Bezier flattening for the Studio Boolean editor.
-- Limits are enforced before any result reaches the scene. The output consists
-- of ordered {x,y} samples without a duplicated closing vertex.
local M={}
local function finite(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
local function point(x,y) return {x=x,y=y} end
local function midpoint(a,b) return point((a.x+b.x)*.5,(a.y+b.y)*.5) end
local function flatEnough(p0,p1,p2,p3,tolerance)
  local dx,dy=p3.x-p0.x,p3.y-p0.y
  local squared=dx*dx+dy*dy
  if squared<1e-14 then
    local d1=(p1.x-p0.x)^2+(p1.y-p0.y)^2
    local d2=(p2.x-p0.x)^2+(p2.y-p0.y)^2
    return math.max(d1,d2)<=tolerance*tolerance
  end
  local length=math.sqrt(squared)
  local d1=math.abs(dx*(p1.y-p0.y)-dy*(p1.x-p0.x))/length
  local d2=math.abs(dx*(p2.y-p0.y)-dy*(p2.x-p0.x))/length
  -- A collinear cubic can still fold back on itself: only flatten if both
  -- control points project within the line segment.
  local t1=((p1.x-p0.x)*dx+(p1.y-p0.y)*dy)/squared
  local t2=((p2.x-p0.x)*dx+(p2.y-p0.y)*dy)/squared
  return math.max(d1,d2)<=tolerance and
    t1>=-1e-7 and t1<=1+1e-7 and t2>=-1e-7 and t2<=1+1e-7
end
local function flattenCubic(out,p0,p1,p2,p3,tolerance,maxDepth,maxPoints,depth,edges,segment,t0,t1)
  if flatEnough(p0,p1,p2,p3,tolerance) then
    if #out>=maxPoints then return nil,"limite de vertices" end
    local edgeIndex=#out
    out[#out+1]=point(p3.x,p3.y)
    if edges then edges[edgeIndex]={segment=segment,t0=t0,t1=t1} end
    return true
  end
  if depth>=maxDepth then return nil,"curva excede tolerancia geometrica" end
  local a,b,c=midpoint(p0,p1),midpoint(p1,p2),midpoint(p2,p3)
  local d,e=midpoint(a,b),midpoint(b,c)
  local m=midpoint(d,e)
  local midpointT=(t0+t1)*.5
  local ok,err=flattenCubic(out,p0,a,d,m,tolerance,maxDepth,maxPoints,
    depth+1,edges,segment,t0,midpointT)
  if not ok then return nil,err end
  return flattenCubic(out,m,e,c,p3,tolerance,maxDepth,maxPoints,
    depth+1,edges,segment,midpointT,t1)
end
local function flattenRing(nodes,options,withEdges)
  options=options or {}
  local tolerance=options.tolerance or .25
  local maxDepth=options.maxDepth or 12
  local maxPoints=options.maxPoints or 512
  if not finite(tolerance) or tolerance<=0 or tolerance>10 or
      type(maxDepth)~="number" or maxDepth<1 or maxDepth>16 or
      type(maxPoints)~="number" or maxPoints<3 or maxPoints>4096 or
      type(nodes)~="table" or #nodes<3 then
    return nil,"parametros de subdivisao invalidos"
  end
  local out={}
  local edges=withEdges and {} or nil
  for i,n in ipairs(nodes) do
    for _,v in ipairs({n.x,n.y,n.ix,n.iy,n.ox,n.oy}) do
      if not finite(v) or math.abs(v)>100000 then
        return nil,"coordenada vetorial invalida"
      end
    end
    local nextNode=nodes[i%#nodes+1]
    if i==1 then out[1]=point(n.x,n.y) end
    local p0=point(n.x,n.y)
    local p1=point(n.ox,n.oy)
    local p2=point(nextNode.ix,nextNode.iy)
    local p3=point(nextNode.x,nextNode.y)
    local ok,err=flattenCubic(out,p0,p1,p2,p3,tolerance,maxDepth,
      maxPoints,0,edges,i,0,1)
    if not ok then return nil,err end
  end
  if #out>1 then
    local a,b=out[1],out[#out]
    if (a.x-b.x)^2+(a.y-b.y)^2<1e-14 then
      out[#out]=nil
    end
  end
  if #out<3 then return nil,"contorno degenerado" end
  return out,edges
end
function M.ring(nodes,options)
  local points,err=flattenRing(nodes,options,false)
  if not points then return nil,err end
  return points
end
-- For Boolean reconstruction: edges[i] describes the original cubic and
-- parameter interval from points[i] to points[i%#points+1].
function M.ringWithEdges(nodes,options)
  return flattenRing(nodes,options,true)
end
return M
