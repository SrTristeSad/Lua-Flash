-- Conservative point-only tangent and exact coincidence handling.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local V=require("src.vector_paths")
local Bool=require("src.vector_boolean")
local Contacts=require("src.vector_contacts")
local function rect(v,x1,y1,x2,y2)
  local p=assert(V.addPath(v,1,1,x1,y1,{.2,.3,.8},2,{.7,.6,.1}))
  assert(V.addNode(p,x2,y1))
  assert(V.addNode(p,x2,y2))
  assert(V.addNode(p,x1,y2))
  assert(V.close(p))
  return p
end
local function area(nodes)
  local r=0
  for i,a in ipairs(nodes) do
    local b=nodes[i%#nodes+1]
    r=r+a.x*b.y-b.x*a.y
  end
  return math.abs(r)/2
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,20,20,40,40)
  local before=V.encode(v)
  local plan,err=Bool.plan(v,1,1,a.id,b.id,"union")
  assert(plan,err)
  assert(plan.resultCount==2,"corner-touching squares have separate interiors")
  assert(V.encode(v)==before,"planning must not mutate its operands")
  plan.apply()
  local result=V.at(v,1,1)
  assert(#result==2 and result[1].id~=result[2].id)
  assert(area(result[1].nodes)==400 and area(result[2].nodes)==400)
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  assert(#V.at(assert(V.decode(before)),1,1)==2,"undo snapshot remains valid")
  print("OK: tangent-at-one-corner union preserves two independently filled shapes")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,20,20,40,40)
  local plan,err=Bool.plan(v,1,1,a.id,b.id,"difference")
  assert(plan,err)
  assert(plan.resultCount==1)
  plan.apply()
  local result=V.at(v,1,1)
  assert(#result==1 and result[1].id==a.id and area(result[1].nodes)==400)
  print("OK: subtracting a corner-touching region leaves source unchanged")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,20,20,40,40)
  local before=V.encode(v)
  local result,err=Bool.plan(v,1,1,a.id,b.id,"intersection")
  assert(not result and err=="empty result")
  assert(V.encode(v)==before,"empty point intersection does not alter source")
  print("OK: corner-only intersection is empty, with atomic refusal")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,20,0,40,20)
  assert(Contacts.classifyPolygons({
    {x=0,y=0},{x=20,y=0},{x=20,y=20},{x=0,y=20}
  },{
    {x=20,y=0},{x=40,y=0},{x=40,y=20},{x=20,y=20}
  })=="coincident")
  assert(not Bool.plan(v,1,1,a.id,b.id,"union"),
    "shared edge still requires unsupported overlapping-topology handling")
  print("OK: coincident boundary segment is distinguished from point-only contact")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,0,0,20,20)
  assert(Contacts.identical(a,b))
  local saved=V.encode(v)
  local tx=assert(Bool.plan(v,1,1,a.id,b.id,"union"))
  assert(V.encode(v)==saved)
  tx.apply()
  assert(#V.at(v,1,1)==1 and V.at(v,1,1)[1].id==a.id)
  assert(area(V.at(v,1,1)[1].nodes)==400)
  print("OK: fully coincident filled outlines union without degenerate edges")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,0,0,20,20)
  local tx=assert(Bool.plan(v,1,1,a.id,b.id,"intersection"))
  tx.apply()
  assert(#V.at(v,1,1)==1 and area(V.at(v,1,1)[1].nodes)==400)
  print("OK: fully coincident filled outlines intersect as one")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,0,0,20,20)
  local bytes=V.encode(v)
  local plan,err=Bool.plan(v,1,1,a.id,b.id,"difference")
  assert(not plan and err=="empty result")
  assert(bytes==V.encode(v))
  print("OK: subtracting fully coincident outline remains empty and atomic")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,0,0,20,20)
  local original=b.nodes
  b.nodes={original[3],original[4],original[1],original[2]}
  assert(Contacts.identical(a,b),"cyclic start point must not change coincidence")
  b.nodes={original[4],original[3],original[2],original[1]}
  for _,n in ipairs(b.nodes) do
    n.ix,n.ox=n.ox,n.ix
    n.iy,n.oy=n.oy,n.iy
  end
  assert(Contacts.identical(a,b),"reverse winding must preserve equivalence")
  local tx=assert(Bool.plan(v,1,1,a.id,b.id,"union"))
  tx.apply()
  assert(#V.at(v,1,1)==1)
  print("OK: identical outlines recognize rotated start and reversed winding")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,20,20,40,40)
  b.nodes[1].x=20.0001
  assert(not Contacts.identical(a,b))
  local before=V.encode(v)
  local plan,err=Bool.plan(v,1,1,a.id,b.id,"union")
  if not plan then
    assert(err,"ambiguous near-contact must return a reason")
    assert(before==V.encode(v))
  end
  print("OK: near-miss is not mistaken for exact shared-anchor tangency")
end
