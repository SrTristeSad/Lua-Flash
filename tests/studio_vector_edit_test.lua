-- Regression of geometry-preserving Bezier segmentation, path splitting
-- / joining, fill tools, undo snapshots and legacy LFVECTOR serialization.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local V=require("src.vector_paths")
local Ops=require("src.vector_edit")
local function approx(a,b,eps) return math.abs(a-b)<(eps or .000001) end
local function path(v,coords,color)
  local p=assert(V.addPath(v,1,1,coords[1][1],coords[1][2],
    color or {1,.3,.1},2))
  for i=2,#coords do assert(V.addNode(p,coords[i][1],coords[i][2])) end
  return p
end
do
  local v=V.new()
  local p=path(v,{{10,40},{150,40}})
  assert(V.handle(p,1,40,-20,"out"))
  assert(V.handle(p,2,120,100,"in"))
  local baseline=V.sample(p,40)
  local before=V.encode(v)
  local plan=assert(Ops.planInsert(v,1,1,p.id,1,.375))
  assert(V.encode(v)==before,"planning must not mutate")
  plan.apply()
  local result=V.at(v,1,1)[1]
  assert(#result.nodes==3 and result.id==p.id)
  for i=0,40 do
    local t=i/40
    local a,b=result.nodes[1],result.nodes[2]
    local c,d=result.nodes[2],result.nodes[3]
    local left=t<=.375
    local q=left and t/.375 or (t-.375)/.625
    local n0,n1=left and a or c,left and b or d
    local r=1-q
    local x=r^3*n0.x+3*r*r*q*n0.ox+3*r*q*q*n1.ix+q^3*n1.x
    local y=r^3*n0.y+3*r*r*q*n0.oy+3*r*q*q*n1.iy+q^3*n1.y
    -- Evaluate original at the same parameter directly.
    local x0,y0=10,40
    local u=1-t
    local expectedX=u^3*10+3*u*u*t*40+3*u*t*t*120+t^3*150
    local expectedY=u^3*40+3*u*u*t*(-20)+3*u*t*t*100+t^3*40
    assert(approx(x,expectedX,1e-5) and approx(y,expectedY,1e-5),
      "segment insertion must reproduce exact original cubic")
  end
  local found,segment,t=Ops.pickSegment({result},result.nodes[2].x+5,
    result.nodes[2].y,15)
  assert(found and segment and t and t>0 and t<1)
  assert(not Ops.planInsert(v,1,1,p.id,1,0))
  assert(not Ops.planInsert(v,1,1,p.id,1,1))
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  print("OK: exact De Casteljau segment subdivision, plan and persistence")
end
do
  local v=V.new()
  local p=path(v,{{0,0},{20,0},{40,20},{60,20}})
  local original=V.encode(v)
  local broken=assert(Ops.planBreak(v,1,1,p.id,2))
  assert(V.encode(v)==original)
  broken.apply()
  local a,b=V.at(v,1,1)[1],V.at(v,1,1)[2]
  assert(a.id==p.id and b.id~=a.id)
  assert(#a.nodes==2 and #b.nodes==3)
  assert(a.nodes[#a.nodes].x==b.nodes[1].x)
  assert(b.nodes[1].ix==b.nodes[1].x)
  assert(not Ops.planBreak(v,1,1,a.id,1))
  local merge=assert(Ops.planJoin(v,1,1,a.id,b.id,1))
  local snapshot=V.encode(v)
  assert(V.encode(v)==snapshot)
  merge.apply()
  local joined=V.at(v,1,1)
  assert(#joined==1 and joined[1].id==a.id and #joined[1].nodes==4)
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  assert(V.encode(assert(V.decode(snapshot)))==snapshot)
  print("OK: break open path at anchor and rejoin without duplicate seam")
end
do
  local v=V.new()
  local a=path(v,{{0,0},{20,0}})
  local b=path(v,{{40,0},{20,0}}) -- end/end join requires reversing B
  local tx=assert(Ops.planJoin(v,1,1,a.id,b.id,1))
  tx.apply()
  local result=V.at(v,1,1)[1]
  assert(#result.nodes==3 and result.nodes[3].x==40)
  local distant=path(v,{{100,100},{120,100}})
  assert(not Ops.planJoin(v,1,1,result.id,distant.id,12))
  local otherColor=path(v,{{40,0},{50,0}},{0,1,0})
  assert(not Ops.planJoin(v,1,1,result.id,otherColor.id,1))
  print("OK: nearest-end join reversal and refusal of incompatible strokes")
end
do
  local v=V.new()
  local a=path(v,{{10,10},{60,10},{60,60},{10,60}})
  assert(V.close(a))
  local first=Ops.pickFill(V.at(v,1,1),30,30)
  assert(first==a,"bucket must see inside unfilled closed shape")
  assert(not Ops.pickFill(V.at(v,1,1),100,100))
  local before=V.encode(v)
  local fill=assert(Ops.planFill(v,1,1,a.id,{.3,.5,.7}))
  assert(V.encode(v)==before)
  fill.apply()
  assert(V.at(v,1,1)[1].fill[1]==.3)
  assert(V.hit(V.at(v,1,1)[1],30,30,1.5))
  local clear=assert(Ops.planFill(v,1,1,a.id,nil))
  clear.apply()
  assert(V.at(v,1,1)[1].fill==nil)
  assert(Ops.pickFill(V.at(v,1,1),30,30)==V.at(v,1,1)[1])
  assert(not Ops.planFill(v,1,1,a.id,{3,0,0}))
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  print("OK: bucket fill/erase for previously unfilled closed Bézier areas")
end
