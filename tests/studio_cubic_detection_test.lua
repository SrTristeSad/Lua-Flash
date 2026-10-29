-- Direct crossing discovery independent of polygonal tessellation.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Detect=require("src.cubic_detection")
local Solver=require("src.cubic_intersections")
local function line(x1,y1,x2,y2)
  return {
    {x=x1,y=y1,ox=x1+(x2-x1)/3,oy=y1+(y2-y1)/3,
      ix=x1,iy=y1},
    {x=x2,y=y2,ix=x1+2*(x2-x1)/3,iy=y1+2*(y2-y1)/3,
      ox=x2,oy=y2}
  }
end
local function approx(a,b,eps) return math.abs(a-b)<(eps or 1e-5) end
do
  local a=line(0,0,100,100)
  local b=line(0,100,100,0)
  -- Close the two-node open strokes with straight return arcs far away from
  -- the tested crossing. The detector accepts actual cubic arc sequences.
  local hits,err=Detect.detect(a,b)
  assert(hits,err)
  assert(#hits>=1)
  local found
  for _,h in ipairs(hits) do
    if approx(h.point.x,50) and approx(h.point.y,50) then found=h end
  end
  assert(found,"direct crossing must be found without any polygon sampling")
  assert(found.residual<1e-5)
  print("OK: bounded cubic subdivision detects transverse line intersection")
end
do
  -- The y(t) of this curve is 10(t-.30)(t-.35)(t-1.2).
  -- Its extremely shallow hump crosses y=0 TWICE at parameters .30 and
  -- .35, even though coarse chords of the whole arc remain below y=0.
  local arch={
    {x=0,y=-1.26,ix=0,iy=-1.26,ox=100/3,oy=1.69},
    {x=100,y=-.91,ix=200/3,iy=-1.52666666666667,ox=100,oy=-.91}
  }
  local baseline=line(0,0,100,0)
  local hits,err=Detect.detect(arch,baseline,{maxVisits=20000})
  assert(hits,err)
  local roots={}
  for _,h in ipairs(hits) do
    if h.aSegment==1 and h.bSegment==1 then
      roots[#roots+1]=h
    end
  end
  assert(#roots==2,"must detect two close crossings missed by coarse chord: got "..#roots)
  assert(approx(roots[1].aT,.30,2e-4))
  assert(approx(roots[2].aT,.35,2e-4))
  assert(roots[1].residual<1e-5 and roots[2].residual<1e-5)
  print("OK: two direct cubic roots in a subpixel hump")
end
do
  local a=line(0,0,100,0)
  local b=line(0,1,100,1)
  local hits,err=Detect.detect(a,b)
  assert(hits,err)
  assert(#hits==0,"parallel paths must not invent intersections")
  assert(not Detect.detect({{x=0,y=0}},b))
  local bad=line(0,0,100,0)
  bad[1].ox=0/0
  assert(not Detect.detect(bad,b))
  print("OK: non-crossing, invalid and parallel curves")
end


do
  local Vector=require("src.vector_paths")
  local Boolean=require("src.vector_boolean")
  local v=Vector.new()
  -- Filled closed shape whose top cubic crosses y=0 twice, only .05 apart in
  -- its parameter space. A static .25-unit tessellation misses the tiny cap.
  local arch=assert(Vector.addPath(v,1,1,0,-1.26,{0,0,0},1,{1,0,0}))
  assert(Vector.addNode(arch,100,-.91))
  assert(Vector.addNode(arch,100,-20))
  assert(Vector.addNode(arch,0,-20))
  assert(Vector.close(arch))
  assert(Vector.handle(arch,1,100/3,1.69,"out"))
  assert(Vector.handle(arch,2,200/3,-1.52666666666667,"in"))
  local mask=assert(Vector.addPath(v,1,1,5,0,{0,0,0},1,{0,1,0}))
  for _,pt in ipairs({{95,0},{95,10},{5,10}}) do
    assert(Vector.addNode(mask,pt[1],pt[2]))
  end
  assert(Vector.close(mask))
  local original=Vector.encode(v)
  local tx,err=Boolean.plan(v,1,1,arch.id,mask.id,"intersection")
  assert(tx,err)
  assert(Vector.encode(v)==original,"precision retries must not mutate operands")
  tx.apply()
  local result=Vector.at(v,1,1)
  assert(#result>=1)
  local minY,maxY=math.huge,-math.huge
  for _,p in ipairs(result) do
    for _,node in ipairs(p.nodes) do
      minY=math.min(minY,node.y)
      maxY=math.max(maxY,node.y)
    end
  end
  assert(minY>=-1e-4 and maxY>0,
    "Boolean must recover area above y=0 missed by coarse tessellation")
  assert(Vector.encode(assert(Vector.decode(Vector.encode(v))))==Vector.encode(v))
  print("OK: Boolean retries finer tessellation to capture two direct cubic crossings")
end
