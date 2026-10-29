-- Refined cubic / cubic intersections: numerical roots, safeguards and
-- intersection-aware Boolean provenance. No old project formats are changed.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Intersection=require("src.cubic_intersections")
local V=require("src.vector_paths")
local B=require("src.vector_boolean")
local function straight(ax,ay,bx,by)
  return {
    {x=ax,y=ay,ox=ax+(bx-ax)/3,oy=ay+(by-ay)/3},
    {x=bx,y=by,ix=ax+2*(bx-ax)/3,iy=ay+2*(by-ay)/3}
  }
end
local function meta(nodes,segment,lo,hi)
  return {nodes=nodes,segment=segment or 1,t0=lo or 0,t1=hi or 1}
end
local function approx(a,b,tol) return math.abs(a-b)<(tol or 1e-5) end
do
  local a=meta(straight(0,0,100,100))
  local b=meta(straight(0,100,100,0))
  local result,err=Intersection.refine(a,b,.48,.52)
  assert(result,err)
  assert(approx(result.point.x,50) and approx(result.point.y,50))
  assert(approx(result.aT,.5) and approx(result.bT,.5))
  assert(result.residual<1e-5)
  local pa=assert(Intersection.evaluate(a,result.aT))
  local pb=assert(Intersection.evaluate(b,result.bT))
  assert(approx(pa.x,pb.x) and approx(pa.y,pb.y))
  print("OK: straight-line cubic crossing Newton solution")
end
do
  local a=meta({
    {x=0,y=-30,ox=25,oy=105},
    {x=100,y=50,ix=70,iy=-90}
  })
  local b=meta(straight(-10,10,110,10))
  local root,err=Intersection.refine(a,b,.36,.5)
  assert(root,err)
  assert(root.residual<1e-5)
  local pointA=assert(Intersection.evaluate(a,root.aT))
  local pointB=assert(Intersection.evaluate(b,root.bT))
  assert(approx(pointA.y,10) and approx(pointB.y,10))
  assert(approx(pointA.x,pointB.x))
  assert(root.aT>0 and root.aT<1)
  assert(root.bT>0 and root.bT<1)
  print("OK: curved/straight crossing refined onto both original cubics")
end
do
  local a=meta(straight(0,0,100,0))
  local parallel=meta(straight(0,1,100,1))
  local root=Intersection.refine(a,parallel,.5,.5)
  assert(not root,"near parallel non-crossing cubics cannot invent a root")
  local tangent=meta(straight(0,0,100,0))
  assert(not Intersection.refine(a,tangent,.5,.5),
    "coincident cubic segments require separate topology handling")
  assert(not Intersection.refine({},a,.5,.5))
  assert(not Intersection.refine(a,parallel,-1,.5))
  print("OK: safe failure for tangent, parallel and invalid inputs")
end
local K=.5522847498307936
local function circle(v,cx,cy,r)
  local p=assert(V.addPath(v,1,1,cx+r,cy,{.1,.3,.6},2,{.4,.7,.8}))
  V.addNode(p,cx,cy+r)
  V.addNode(p,cx-r,cy)
  V.addNode(p,cx,cy-r)
  V.close(p)
  local n=p.nodes
  local h=r*K
  n[1].ox,n[1].oy=cx+r,cy+h
  n[2].ix,n[2].iy=cx+h,cy+r
  n[2].ox,n[2].oy=cx-h,cy+r
  n[3].ix,n[3].iy=cx-r,cy+h
  n[3].ox,n[3].oy=cx-r,cy-h
  n[4].ix,n[4].iy=cx-h,cy-r
  n[4].ox,n[4].oy=cx+h,cy-r
  n[1].ix,n[1].iy=cx+r,cy-h
  return p
end
local function nearestOnCurve(nodes,pt)
  local best=math.huge
  for segment=1,#nodes do
    local m=meta(nodes,segment,0,1)
    for i=0,512 do
      local p=assert(Intersection.evaluate(m,i/512))
      local dx,dy=p.x-pt.x,p.y-pt.y
      local d=dx*dx+dy*dy
      if d<best then best=d end
    end
  end
  return math.sqrt(best)
end
do
  local v=V.new()
  local a=circle(v,125,120,60)
  local b=circle(v,185,120,60)
  local original=V.encode(v)
  local tx,err=B.plan(v,1,1,a.id,b.id,"intersection")
  assert(tx,err)
  assert(V.encode(v)==original)
  tx.apply()
  local result=V.at(v,1,1)
  assert(#result==1 and result[1].closed and result[1].fill)
  local both=0
  for _,n in ipairs(result[1].nodes) do
    local d1=nearestOnCurve(a.nodes,n)
    local d2=nearestOnCurve(b.nodes,n)
    if d1<.2 and d2<.2 then
      both=both+1
      assert(d1<.2 and d2<.2)
    end
  end
  assert(both>=2,"clipped circular lens must have both cubic crossing anchors")
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  print("OK: numeric refinements produce shared cubic crossings in Boolean lens")
end
