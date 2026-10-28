-- Boolean filled-region operations in Studio; geometry is bounded polygonal
-- flattening of Beziers, not exact cubic boolean algebra.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Vector=require("src.vector_paths")
local Boolean=require("src.vector_boolean")
local function rect(v,x1,y1,x2,y2)
  local p=assert(Vector.addPath(v,1,1,x1,y1,{.1,.2,.8},2,{.9,.5,.2}))
  assert(Vector.addNode(p,x2,y1))
  assert(Vector.addNode(p,x2,y2))
  assert(Vector.addNode(p,x1,y2))
  assert(Vector.close(p))
  return p
end
local function signedArea(p)
  local pts=Vector.sample(p,2)
  local sum=0
  for i=1,#pts-3,2 do
    sum=sum+pts[i]*pts[i+3]-pts[i+2]*pts[i+1]
  end
  return sum/2
end
local function within(x,y) return math.abs(x-y)<.01 end
for _,test in ipairs({
  {op="union",expect=2600},
  {op="intersection",expect=600},
  {op="difference",expect=1000}
}) do
  local v=Vector.new()
  local a=rect(v,0,0,40,40)
  local b=rect(v,20,10,60,50)
  local original=Vector.encode(v)
  local plan,err=Boolean.plan(v,1,1,a.id,b.id,test.op)
  assert(plan,err)
  assert(Vector.encode(v)==original,"planning must not modify source")
  assert(plan.resultCount==1)
  plan.apply()
  local output=Vector.at(v,1,1)
  assert(#output==1 and output[1].closed and output[1].fill)
  assert(within(signedArea(output[1]),test.expect),
    test.op.." resulting area was "..signedArea(output[1]))
  local encoded=Vector.encode(v)
  assert(Vector.encode(assert(Vector.decode(encoded)))==encoded,
    "boolean result must survive LFVECTOR save/reload")
  assert(Vector.encode(assert(Vector.decode(original)))==original,
    "undo snapshot must restore original operands")
  print("OK: "..test.op.." overlap with correct filled area")
end
do
  local v=Vector.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,50,40,80,70)
  local plan=assert(Boolean.plan(v,1,1,a.id,b.id,"union"))
  assert(plan.resultCount==2)
  plan.apply()
  local p=Vector.at(v,1,1)
  assert(#p==2 and p[1].id~=p[2].id)
  assert(within(signedArea(p[1])+signedArea(p[2]),1300))
  assert(not Boolean.plan(v,1,1,p[1].id,p[2].id,"intersection"))
  print("OK: disjoint union outputs two independent paths")
end
do
  local v=Vector.new()
  local a=rect(v,0,0,50,50)
  local b=rect(v,10,10,30,30)
  local u=assert(Boolean.plan(v,1,1,a.id,b.id,"union"))
  assert(u.resultCount==1)
  local i=assert(Boolean.plan(v,1,1,a.id,b.id,"intersection"))
  assert(i.resultCount==1)
  local result,err=Boolean.plan(v,1,1,a.id,b.id,"difference")
  assert(result,err)
  assert(Vector.encode(v):find("LFVECTOR 1",1,true),
    "planning hole output must not alter storage format")
  result.apply()
  assert(#Vector.at(v,1,1)==1 and #Vector.at(v,1,1)[1].holes==1,
    "nested subtraction must preserve its interior cutout")
  assert(Vector.encode(v):find("LFVECTOR 3",1,true))
  print("OK: nested Boolean subtraction produces a compound hole")
end
do
  local v=Vector.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,20,0,40,20)
  assert(not Boolean.plan(v,1,1,a.id,b.id,"union"),
    "collinear coincident touching edges must fail safely")
  assert(#Vector.at(v,1,1)==2)
  print("OK: shared boundary rejected instead of corrupting topology")
end
do
  local v=Vector.new()
  local p=assert(Vector.addPath(v,1,1,10,10,{1,0,0},2,{1,0,0}))
  Vector.addNode(p,40,10)
  Vector.addNode(p,40,40)
  local r=rect(v,20,20,60,50)
  assert(not Boolean.plan(v,1,1,p.id,r.id,"union"),
    "open paths must be refused")
  assert(not Boolean.plan(v,1,1,r.id,r.id,"union"),
    "identical operand must be refused")
  assert(not Boolean.plan(v,1,1,r.id,999,"union"))
  print("OK: malformed operation inputs rejected")
end
