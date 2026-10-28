-- Adaptive Boolean precision and original cubic preservation tests.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local V=require("src.vector_paths")
local B=require("src.vector_boolean")
local Flat=require("src.bezier_flatten")
local K=.5522847498307936
local function circle(v,cx,cy,r)
  local x,y,h=cx,cy,r*K
  local p=assert(V.addPath(v,1,1,x+r,y,{.3,.5,.7},2,{.6,.7,.8}))
  V.addNode(p,x,y+r)
  V.addNode(p,x-r,y)
  V.addNode(p,x,y-r)
  V.close(p)
  local n=p.nodes
  n[1].ox,n[1].oy=x+r,y+h
  n[2].ix,n[2].iy=x+h,y+r
  n[2].ox,n[2].oy=x-h,y+r
  n[3].ix,n[3].iy=x-r,y+h
  n[3].ox,n[3].oy=x-r,y-h
  n[4].ix,n[4].iy=x-h,y-r
  n[4].ox,n[4].oy=x+h,y-r
  n[1].ix,n[1].iy=x+r,y-h
  return p
end
local function rectangle(v,x1,y1,x2,y2)
  local p=assert(V.addPath(v,1,1,x1,y1,{.3,.5,.7},2,{.6,.7,.8}))
  for _,point in ipairs({{x2,y1},{x2,y2},{x1,y2}}) do
    V.addNode(p,point[1],point[2])
  end
  V.close(p)
  return p
end
local function approx(a,b,eps) return math.abs(a-b)<eps end
local function unchanged(original,newNodes)
  assert(#original==#newNodes,"untouched cubic ring must keep original anchor count")
  for i,n in ipairs(original) do
    for _,name in ipairs({"x","y","ix","iy","ox","oy"}) do
      assert(approx(n[name],newNodes[i][name],1e-8),
        "untouched cubic control changed "..i..":"..name)
    end
  end
end
local function polygonArea(points)
  local sum=0
  for i,a in ipairs(points) do
    local b=points[i%#points+1]
    sum=sum+a.x*b.y-a.y*b.x
  end
  return math.abs(sum)*.5
end
local function area(nodes)
  local pts=V.sample({nodes=nodes,closed=true},32)
  local result={}
  for i=1,#pts-2,2 do result[#result+1]={x=pts[i],y=pts[i+1]} end
  return polygonArea(result)
end
do
  local v=V.new()
  local c=circle(v,100,100,80)
  local coarse=V.sample(c,2)
  local flat,err=Flat.ring(c.nodes,{tolerance=.25,maxPoints=512})
  assert(flat,err)
  local coarsePolygon={}
  for i=1,#coarse-2,2 do
    coarsePolygon[#coarsePolygon+1]={x=coarse[i],y=coarse[i+1]}
  end
  assert(#flat>#coarsePolygon,"adaptive sampling must subdivide curved segments")
  local exact=math.pi*80*80
  local fineError=math.abs(polygonArea(flat)-exact)
  local coarseError=math.abs(polygonArea(coarsePolygon)-exact)
  assert(fineError<coarseError*.5,
    "adaptive sampling must improve area accuracy: "..fineError.." vs "..coarseError)
  local tooSmall,why=Flat.ring(c.nodes,{tolerance=.001,maxPoints=10})
  assert(not tooSmall and why,"excessive precision should fail safely")
  assert(not Flat.ring(c.nodes,{tolerance=0}))
  assert(not Flat.ring(c.nodes,{maxDepth=0}))
  print("OK: adaptive curvature sampling improves circular area and enforces limits")
end
do
  local v=V.new()
  local c=circle(v,150,120,60)
  local outer=rectangle(v,0,0,300,250)
  local snapshot=V.encode(v)
  local plan,err=B.plan(v,1,1,outer.id,c.id,"difference")
  assert(plan,err)
  assert(V.encode(v)==snapshot)
  plan.apply()
  local result=V.at(v,1,1)[1]
  assert(#V.at(v,1,1)==1 and result.holes and #result.holes==1)
  unchanged(c.nodes,result.holes[1])
  unchanged(outer.nodes,result.nodes)
  assert(V.inFill(result,30,30) and not V.inFill(result,150,120))
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  print("OK: nested subtraction keeps exact cubic curve around its hole")
end
do
  local v=V.new()
  local c=circle(v,150,120,60)
  local mask=rectangle(v,0,0,300,250)
  local tx,err=B.plan(v,1,1,mask.id,c.id,"intersection")
  assert(tx,err)
  tx.apply()
  local result=V.at(v,1,1)[1]
  assert(#V.at(v,1,1)==1)
  unchanged(c.nodes,result.nodes)
  print("OK: wholly contained intersection retains original Bezier controls")
end
do
  local v=V.new()
  local c=circle(v,150,120,60)
  local remote=rectangle(v,270,40,290,60)
  local tx,err=B.plan(v,1,1,c.id,remote.id,"union")
  assert(tx,err)
  assert(tx.resultCount==2)
  tx.apply()
  local result=V.at(v,1,1)
  local found
  for _,p in ipairs(result) do
    if #p.nodes==4 and p.nodes[1].x>100 and p.nodes[1].x<250 then found=p end
  end
  assert(found)
  unchanged(c.nodes,found.nodes)
  print("OK: disjoint union retains original untouched curved outline")
end
do
  local v=V.new()
  local c1=circle(v,125,120,60)
  local c2=circle(v,185,120,60)
  local snapshot=V.encode(v)
  local tx,err=B.plan(v,1,1,c1.id,c2.id,"intersection")
  assert(tx,err)
  assert(V.encode(v)==snapshot)
  tx.apply()
  local result=V.at(v,1,1)
  assert(#result==1)
  local observed=area(result[1].nodes)
  local r,d=60,60
  local expected=2*r*r*math.acos(d/(2*r))-.5*d*math.sqrt(4*r*r-d*d)
  assert(math.abs(observed-expected)<60,
    "cubic intersection approximation too coarse: got "..observed.." expected "..expected)
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  print("OK: curved/curved crossing maintains bounded intersection area error")
end
