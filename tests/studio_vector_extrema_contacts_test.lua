-- Interior/interior cubic tangencies certified by source-curve extrema.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local V=require("src.vector_paths")
local B=require("src.vector_boolean")
local Extrema=require("src.vector_extrema_contacts")
local Intersection=require("src.cubic_intersections")
local function path(v,points)
  local p=assert(V.addPath(v,1,1,points[1][1],points[1][2],
    {.2,.3,.8},2,{.8,.6,.2}))
  for i=2,#points do assert(V.addNode(p,points[i][1],points[i][2])) end
  assert(V.close(p))
  return p
end
local function pair()
  local v=V.new()
  local a=path(v,{{0,0},{100,0},{100,-60},{0,-60}})
  local b=path(v,{{0,40},{100,40},{100,100},{0,100}})
  local h=80/3
  -- The first cubic of each shape has an interior support point at t=1/2.
  -- A reaches maximum y=20, B reaches minimum y=20, both at x=50.
  a.nodes[1].ox,a.nodes[1].oy=25,h
  a.nodes[2].ix,a.nodes[2].iy=75,h
  b.nodes[1].ox,b.nodes[1].oy=25,40-h
  b.nodes[2].ix,b.nodes[2].iy=75,40-h
  return v,a,b
end
local function translated(p,dx,dy)
  for _,n in ipairs(p.nodes) do
    n.x,n.y=n.x+dx,n.y+dy
    n.ix,n.iy=n.ix+dx,n.iy+dy
    n.ox,n.oy=n.ox+dx,n.oy+dy
  end
end
local function flipXY(p)
  for _,n in ipairs(p.nodes) do
    n.x,n.y=n.y,n.x
    n.ix,n.iy=n.iy,n.ix
    n.ox,n.oy=n.oy,n.ox
  end
end
for _,axis in ipairs({"y","x"}) do
  for _,op in ipairs({"union","difference","intersection"}) do
    local v,a,b=pair()
    if axis=="x" then flipXY(a);flipXY(b) end
    local m={nodes=a.nodes,segment=1,t0=0,t1=1}
    local p=assert(Intersection.evaluate(m,.5))
    assert(math.abs(p.x-(axis=="y" and 50 or 20))<1e-8)
    assert(math.abs(p.y-(axis=="y" and 20 or 50))<1e-8)
    assert(not (p.x==a.nodes[1].x and p.y==a.nodes[1].y))
    local handled,shapes,issue=Extrema.plan(a,b,op)
    assert(handled,"cubic interior contact must be certified on "..axis)
    local saved=V.encode(v)
    local tx,err=B.plan(v,1,1,a.id,b.id,op)
    if op=="intersection" then
      assert(not shapes and issue=="empty result")
      assert(not tx and err=="empty result")
    else
      assert(shapes and #shapes==(op=="union" and 2 or 1))
      assert(tx,err)
      assert(tx.resultCount==(op=="union" and 2 or 1))
      assert(V.encode(v)==saved,"planning must not edit source curves")
      tx.apply()
      local paths=V.at(v,1,1)
      assert(#paths==(op=="union" and 2 or 1))
      assert(#paths[1].nodes==4 and paths[1].nodes[1].ox==a.nodes[1].ox)
      assert(#paths[1].holes==0 or not paths[1].holes)
      assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
    end
    if op=="intersection" then
      assert(V.encode(v)==saved,"empty intersection must be atomic")
    end
  end
end
print("OK: two original cubic interiors touch at unique x/y support extrema")
do
  local v,a,b=pair()
  translated(b,0,.0001)
  assert(not Extrema.plan(a,b,"union"),"near gap is not an exact contact")
  translated(b,0,-.0002)
  assert(not Extrema.plan(a,b,"union"),"actual overlap cannot be certified")
  assert(#V.at(v,1,1)==2)
end
do
  local v=V.new()
  local a=path(v,{{0,20},{100,20},{100,-60},{0,-60}})
  local b=path(v,{{0,20},{100,20},{100,100},{0,100}})
  assert(not Extrema.plan(a,b,"union"),
    "a shared straight boundary cannot masquerade as point tangency")
end
do
  local v,a,b=pair()
  a.holes={{a.nodes[1],a.nodes[2],a.nodes[3]}}
  assert(not Extrema.plan(a,b,"union"),"holes are excluded")
end
print("OK: near gaps, overlapping regions, shared edges and holes stay conservative")
