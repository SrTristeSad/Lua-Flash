-- Exact full and partial shared cubic seams: output retains the original arcs.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local V=require("src.vector_paths")
local Boolean=require("src.vector_boolean")
local Seams=require("src.vector_curved_seams")
local function same(a,b,tolerance)
  return math.abs(a-b)<(tolerance or 1e-6)
end
local function path(v,points)
  local p=assert(V.addPath(v,1,1,points[1][1],points[1][2],
    {.2,.4,.7},2,{.8,.6,.3}))
  for i=2,#points do assert(V.addNode(p,points[i][1],points[i][2])) end
  assert(V.close(p))
  return p
end
local function pair()
  local v=V.new()
  local a=path(v,{{0,0},{100,0},{100,60},{0,60}})
  local b=path(v,{{100,0},{0,0},{0,-80},{100,-80}})
  a.nodes[1].ox,a.nodes[1].oy=25,-30
  a.nodes[2].ix,a.nodes[2].iy=75,-30
  b.nodes[1].ox,b.nodes[1].oy=75,-30
  b.nodes[2].ix,b.nodes[2].iy=25,-30
  a.nodes[3].ox,a.nodes[3].oy=80,80
  a.nodes[4].ix,a.nodes[4].iy=20,80
  return v,a,b
end
local function curve(v,p)
  local found=false
  for _,n in ipairs(p.nodes) do
    if same(n.x,100) and same(n.y,60) then
      assert(same(n.ox,80) and same(n.oy,80),
        "an original uncut cubic handle must be preserved")
      found=true
    end
  end
  assert(found,"original curved outer edge is missing")
end
do
  for _,operation in ipairs({"union","intersection","difference"}) do
    local v,a,b=pair()
    local previous=V.encode(v)
    local handled,shapes,error=Seams.plan(a,b,operation)
    assert(handled,"exact reverse cubic boundary must be recognized")
    local tx,err=Boolean.plan(v,1,1,a.id,b.id,operation)
    if operation=="intersection" then
      assert(not tx and err=="empty result" and shapes==nil)
      assert(V.encode(v)==previous)
    else
      assert(tx,err)
      assert(tx.resultCount==1)
      assert(V.encode(v)==previous)
      tx.apply()
      local result=V.at(v,1,1)
      assert(#result==1)
      assert(V.inFill(result[1],50,20))
      if operation=="union" then
        assert(V.inFill(result[1],50,-50))
        assert(#result[1].nodes==6)
      else
        assert(not V.inFill(result[1],50,-50))
        assert(#result[1].nodes==4)
      end
      curve(v,result[1])
      assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
    end
  end
  print("OK: exact reversed cubic shared seam union/difference/empty intersection")
end
local function blend(a,b,t)
  return {x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t}
end
local function half(p,t)
  local a,b,c=blend(p[1],p[2],t),blend(p[2],p[3],t),blend(p[3],p[4],t)
  local d,e=blend(a,b,t),blend(b,c,t)
  local m=blend(d,e,t)
  return {p[1],a,d,m},{m,e,c,p[4]}
end
local function subcurve(p,lo,hi)
  local first=p
  if hi<1 then first=select(1,half(first,hi)) end
  if lo>0 then first=select(2,half(first,lo/hi)) end
  return first
end
local function partial()
  local v=V.new()
  local a=path(v,{{0,0},{100,0},{100,60},{0,60}})
  a.nodes[1].ox,a.nodes[1].oy=25,-30
  a.nodes[2].ix,a.nodes[2].iy=75,-30
  a.nodes[3].ox,a.nodes[3].oy=80,80
  a.nodes[4].ix,a.nodes[4].iy=20,80
  local p={{x=0,y=0},{x=25,y=-30},{x=75,y=-30},{x=100,y=0}}
  local arc=subcurve(p,.25,.75)
  local b=path(v,{
    {arc[4].x,arc[4].y},{arc[1].x,arc[1].y},
    {arc[1].x,-70},{arc[4].x,-70}
  })
  b.nodes[1].ox,b.nodes[1].oy=arc[3].x,arc[3].y
  b.nodes[2].ix,b.nodes[2].iy=arc[2].x,arc[2].y
  return v,a,b
end
do
  for _,op in ipairs({"union","difference","intersection"}) do
    local v,a,b=partial()
    local previous=V.encode(v)
    local handled,shapes,error=Seams.plan(a,b,op)
    assert(handled,error or "partial curve must be matched")
    local tx,err=Boolean.plan(v,1,1,a.id,b.id,op)
    if op=="intersection" then
      assert(not tx and err=="empty result")
      assert(previous==V.encode(v))
    else
      assert(tx,err)
      assert(previous==V.encode(v),"planning a partial curve must not mutate inputs")
      tx.apply()
      local paths=V.at(v,1,1)
      assert(#paths==1)
      if op=="union" then
        assert(V.inFill(paths[1],50,-50))
        assert(V.inFill(paths[1],50,30))
        assert(#paths[1].nodes==8,
          "only the two exact subcurve seam anchors may be added")
      else
        assert(not V.inFill(paths[1],50,-50))
        assert(#paths[1].nodes==4)
      end
      curve(v,paths[1])
      assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
    end
  end
  print("OK: exact partial cubic shared arc across all Boolean operations")
end
do
  local v,a,b=pair()
  b.nodes[1].ox=b.nodes[1].ox+.002
  local handled=Seams.plan(a,b,"union")
  assert(not handled,"similar-looking but nonidentical cubics must not snap")
  local bytes=V.encode(v)
  local _,error=Boolean.plan(v,1,1,a.id,b.id,"union")
  assert(V.encode(v)==bytes,"ambiguous seam cannot change source document")
  print("OK: tiny control differences never qualify as exact curved coincidences")
end
do
  local v,a,b=pair()
  -- This B shares the identical cubic but occupies the SAME filled side,
  -- and cannot be joined as two disjoint regions.
  b.nodes[3].x,b.nodes[3].y=0,50
  b.nodes[4].x,b.nodes[4].y=100,50
  b.nodes[2].oy=b.nodes[2].y
  local handled,shapes,error=Seams.plan(a,b,"union")
  assert(handled and not shapes and error,
    "non-seam overlap must be rejected despite identical shared cubic")
  print("OK: real curved seam cannot mask overlapping filled interiors")
end


do
  -- A curved upper boundary is touched by a second shape's original tip,
  -- at t=.37 (deliberately not an adaptive tessellation midpoint).
  local v=V.new()
  local base=path(v,{{0,0},{100,0},{100,60},{0,60}})
  base.nodes[1].ox,base.nodes[1].oy=25,-30
  base.nodes[2].ix,base.nodes[2].iy=75,-30
  local t=.37
  local u=1-t
  local x=3*u*u*t*25+3*u*t*t*75+t^3*100
  local y=-90*u*t
  local tip=path(v,{{x,y},{x-7,y-35},{x+7,y-35}})
  local snapshot=V.encode(v)
  local Flatten=require("src.bezier_flatten")
  local Contacts=require("src.vector_contacts")
  local Detector=require("src.cubic_detection")
  local pa=assert(Flatten.ring(base.nodes,{tolerance=.25,maxPoints=385}))
  local pb=assert(Flatten.ring(tip.nodes,{tolerance=.25,maxPoints=385}))
  local contact=Contacts.classifyPolygons(pa,pb)
  local allowed=Contacts.safeCornerTouch({outer=pa,holes={}},
    {outer=pb,holes={}},base,tip)
  local detected,detectError=Detector.detect(base.nodes,tip.nodes,{maxVisits=12000})
  print("TANGENCY DIAG",contact,allowed,
    detected and #detected or "nil",detectError)
  for _,hit in ipairs(detected or {}) do
    print("TANGENCY HIT",hit.point.x,hit.point.y,
      hit.aSegment,hit.bSegment,hit.aT,hit.bT,
      (hit.point.x-x)^2+(hit.point.y-y)^2)
  end
  local union,err=Boolean.plan(v,1,1,base.id,tip.id,"union")
  assert(union,err)
  assert(union.resultCount==2,
    "nonlinear point tangent must keep both independently filled shapes")
  assert(snapshot==V.encode(v))
  union.apply()
  local result=V.at(v,1,1)
  assert(#result==2)
  assert(V.inFill(result[1],50,20))
  assert(V.inFill(result[2],x,y-15))
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  print("OK: exact tip-on-nonlinear-cubic tangency is not a filled crossing")
end
