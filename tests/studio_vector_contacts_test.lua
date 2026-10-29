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
  local tx,err=Bool.plan(v,1,1,a.id,b.id,"union")
  assert(tx,err)
  assert(tx.resultCount==1)
  tx.apply()
  assert(#V.at(v,1,1)==1 and area(V.at(v,1,1)[1].nodes)==800)
  print("OK: a fully shared edge is distinguished and merged safely")
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


do
  -- Two cubic approximations of circles that touch at a single native
  -- anchor. The hulls overlap only at x=r; neither filled area crosses.
  local K=.5522847498307936
  local function circle(v,cx,cy,r)
    local p=assert(V.addPath(v,1,1,cx+r,cy,{.2,.3,.8},2,{.7,.6,.1}))
    assert(V.addNode(p,cx,cy+r))
    assert(V.addNode(p,cx-r,cy))
    assert(V.addNode(p,cx,cy-r))
    assert(V.close(p))
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
  local v=V.new()
  local first=circle(v,0,0,20)
  local second=circle(v,40,0,20)
  local before=V.encode(v)
  local tx,err=Bool.plan(v,1,1,first.id,second.id,"union")
  assert(tx,err)
  assert(tx.resultCount==2,"tangent circles must remain separate filled regions")
  assert(V.encode(v)==before)
  tx.apply()
  assert(#V.at(v,1,1)==2 and #V.at(v,1,1)[1].nodes==4)
  assert(#V.at(v,1,1)[2].nodes==4)
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  print("OK: smoothly tangent circles at a shared anchor retain cubic controls")
end


do
  -- Identical compound artwork with a real interior cutout should not lose
  -- its transparent holes when the duplicate is merged or intersected.
  for _,operation in ipairs({"union","intersection","difference"}) do
    local v=V.new()
    local outer=rect(v,0,0,100,100)
    local hole=rect(v,25,25,75,75)
    local subtract=assert(Bool.plan(v,1,1,outer.id,hole.id,"difference"))
    subtract.apply()
    local compound=V.at(v,1,1)[1]
    assert(#compound.holes==1)
    local second=assert(V.addPath(v,1,1,0,0,compound.stroke,
      compound.width,compound.fill))
    for i,n in ipairs(compound.nodes) do
      second.nodes[i]={x=n.x,y=n.y,ix=n.ix,iy=n.iy,ox=n.ox,oy=n.oy}
    end
    second.closed=true
    second.holes={}
    for i,nodes in ipairs(compound.holes) do
      second.holes[i]={}
      for j,n in ipairs(nodes) do
        second.holes[i][j]={x=n.x,y=n.y,ix=n.ix,iy=n.iy,
          ox=n.ox,oy=n.oy}
      end
    end
    assert(Contacts.identical(compound,second))
    local snapshot=V.encode(v)
    local tx,err=Bool.plan(v,1,1,compound.id,second.id,operation)
    if operation=="difference" then
      assert(not tx and err=="empty result")
      assert(snapshot==V.encode(v))
    else
      assert(tx,err)
      assert(snapshot==V.encode(v))
      tx.apply()
      local result=V.at(v,1,1)
      assert(#result==1 and result[1].holes and #result[1].holes==1)
      assert(V.inFill(result[1],10,10))
      assert(not V.inFill(result[1],50,50))
      assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
    end
  end
  print("OK: fully coincident compound shapes preserve their existing holes")
end


do
  -- Only part of A's right-hand boundary overlaps B's left-hand boundary.
  -- Union must remove this shared internal edge and retain the two notches.
  for _,op in ipairs({"union","difference","intersection"}) do
    local v=V.new()
    local a=rect(v,0,0,20,20)
    local b=rect(v,20,5,40,15)
    local bytes=V.encode(v)
    local tx,err=Bool.plan(v,1,1,a.id,b.id,op)
    if op=="intersection" then
      assert(not tx and err=="empty result")
      assert(V.encode(v)==bytes)
    else
      assert(tx,err)
      assert(V.encode(v)==bytes)
      tx.apply()
      local shapes=V.at(v,1,1)
      assert(#shapes==1 and shapes[1].id==a.id)
      local expected=op=="union" and 600 or 400
      assert(area(shapes[1].nodes)==expected,
        "shared partial edge "..op.." area must be "..expected)
      if op=="union" then
        assert(#shapes[1].nodes==8,"partial shared edge requires an L-shaped boundary")
        assert(V.inFill(shapes[1],30,10))
        assert(not V.inFill(shapes[1],30,18))
      else
        assert(#shapes[1].nodes==4)
        assert(not V.inFill(shapes[1],30,10))
      end
      assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
    end
  end
  print("OK: partially coincident rectangle sides support union, difference and empty intersection")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local triangle=assert(V.addPath(v,1,1,10,20,{.2,.3,.8},2,{.7,.6,.1}))
  assert(V.addNode(triangle,15,30))
  assert(V.addNode(triangle,5,30))
  assert(V.close(triangle))
  -- The triangle's tip contacts the MIDDLE of A's bottom cubic, not an anchor.
  local saved=V.encode(v)
  local tx,err=Bool.plan(v,1,1,a.id,triangle.id,"union")
  assert(tx,err)
  assert(tx.resultCount==2)
  assert(V.encode(v)==saved)
  tx.apply()
  local pieces=V.at(v,1,1)
  assert(#pieces==2 and area(pieces[1].nodes)==400)
  assert(area(pieces[2].nodes)==50)
  local intersection=V.new()
  local aa=rect(intersection,0,0,20,20)
  local bb=assert(V.addPath(intersection,1,1,10,20,{.2,.3,.8},2,{.7,.6,.1}))
  assert(V.addNode(bb,15,30))
  assert(V.addNode(bb,5,30))
  assert(V.close(bb))
  local plan,why=Bool.plan(intersection,1,1,aa.id,bb.id,"intersection")
  assert(not plan and why=="empty result")
  print("OK: original anchor touching interior of straight Bezier is point-only tangency")
end
do
  local v=V.new()
  local a=rect(v,0,0,20,20)
  local b=rect(v,20,5,40,15)
  -- A bent control can never qualify as an EXACT straight shared rectangle.
  b.nodes[4].ox=b.nodes[4].ox+.01
  local handled=Contacts.sharedRectangle(a,b,"union")
  assert(handled==false)
  print("OK: curved coincident-lookalikes never use exact straight rectangle shortcut")
end
