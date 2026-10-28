-- Multi-ring Boolean clipping, successive cutouts and mixed compound operands.
-- Exercises full LFVECTOR 3 save/reload, exact area for polygonal fixtures and
-- rejection of corrupted nested / boundary-crossing hole operands.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local V=require("src.vector_paths")
local B=require("src.vector_boolean")
local function rect(v,x1,y1,x2,y2)
  local p=assert(V.addPath(v,1,1,x1,y1,{.25,.5,.75},2,{.8,.4,.1}))
  assert(V.addNode(p,x2,y1))
  assert(V.addNode(p,x2,y2))
  assert(V.addNode(p,x1,y2))
  assert(V.close(p))
  return p
end
local function signedArea(nodes)
  local area=0
  for i,a in ipairs(nodes) do
    local b=nodes[i%#nodes+1]
    area=area+a.x*b.y-a.y*b.x
  end
  return math.abs(area)*.5
end
local function filledArea(paths)
  local sum=0
  for _,p in ipairs(paths) do
    sum=sum+signedArea(p.nodes)
    for _,h in ipairs(p.holes or {}) do sum=sum-signedArea(h) end
  end
  return sum
end
local function equal(a,b) return math.abs(a-b)<.001 end
local function donut()
  local v=V.new()
  local big=rect(v,0,0,100,100)
  local hole=rect(v,20,20,40,40)
  local tx,err=B.plan(v,1,1,big.id,hole.id,"difference")
  assert(tx,err)
  tx.apply()
  assert(#V.at(v,1,1)==1 and #V.at(v,1,1)[1].holes==1)
  return v,V.at(v,1,1)[1]
end
do
  local v,a=donut()
  local second=rect(v,60,60,80,80)
  local original=V.encode(v)
  local tx,err=B.plan(v,1,1,a.id,second.id,"difference")
  assert(tx,err)
  assert(V.encode(v)==original,"planning must not mutate existing hole")
  tx.apply()
  local p=assert(V.at(v,1,1)[1])
  assert(#V.at(v,1,1)==1 and p.holes and #p.holes==2)
  assert(equal(filledArea({p}),9200))
  assert(not V.inFill(p,30,30) and not V.inFill(p,70,70))
  assert(V.inFill(p,50,50) and V.inFill(p,90,90))
  local saved=V.encode(v)
  assert(saved:find("LFVECTOR 3",1,true))
  assert(V.encode(assert(V.decode(saved)))==saved)
  assert(#V.at(assert(V.decode(original)),1,1)==2)
  print("OK: second subtraction creates a second independent hole")
end
do
  local v,a=donut()
  local b=rect(v,35,25,55,45)
  local tx,err=B.plan(v,1,1,a.id,b.id,"difference")
  assert(tx,err)
  tx.apply()
  local p=V.at(v,1,1)[1]
  assert(#V.at(v,1,1)==1 and #p.holes==1)
  assert(equal(filledArea({p}),9275),filledArea({p}))
  assert(not V.inFill(p,50,30) and not V.inFill(p,30,30))
  assert(V.inFill(p,60,30) and V.inFill(p,50,50))
  print("OK: subtracting across an existing cutout expands its boundary")
end
do
  local v,a=donut()
  local island=rect(v,25,25,35,35)
  local tx,err=B.plan(v,1,1,a.id,island.id,"union")
  assert(tx,err)
  assert(tx.resultCount==2)
  tx.apply()
  local parts=V.at(v,1,1)
  assert(#parts==2 and equal(filledArea(parts),9700))
  assert(V.inFill(parts[2],30,30))
  assert(not V.inFill(parts[1],30,30))
  assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
  print("OK: union inside a cutout preserves an independent filled island")
end
do
  local v,a=donut()
  local mask=rect(v,10,10,50,50)
  local tx,err=B.plan(v,1,1,a.id,mask.id,"intersection")
  assert(tx,err)
  tx.apply()
  local p=assert(V.at(v,1,1)[1])
  assert(#V.at(v,1,1)==1 and p.holes and #p.holes==1)
  assert(equal(filledArea({p}),1200))
  assert(V.inFill(p,15,15) and not V.inFill(p,30,30))
  print("OK: compound intersection keeps an enclosed hole")
end
do
  local v,b=donut()
  local mask=rect(v,10,10,50,50)
  local tx,err=B.plan(v,1,1,mask.id,b.id,"intersection")
  assert(tx,err)
  tx.apply()
  assert(#V.at(v,1,1)==1 and #V.at(v,1,1)[1].holes==1)
  assert(equal(filledArea(V.at(v,1,1)),1200))
  print("OK: hole-bearing SECOND operand is clipped correctly")
end
do
  local v,a=donut()
  local covered=rect(v,25,25,35,35)
  local tx,err=B.plan(v,1,1,a.id,covered.id,"difference")
  assert(tx,err)
  tx.apply()
  assert(#V.at(v,1,1)==1 and equal(filledArea(V.at(v,1,1)),9600))
  local empty=rect(v,26,26,34,34)
  assert(not B.plan(v,1,1,a.id,empty.id,"intersection"),
    "intersection entirely inside the cutout must be empty")
  print("OK: subtract inside existing hole is a geometric no-op")
end
do
  local v,a=donut()
  local malformed=V.at(v,1,1)[1]
  local snapshot=V.encode(v)
  -- Touching or outside outer boundary is never accepted as a valid hole.
  V.move({nodes=malformed.holes[1]},-30,0)
  local b=rect(v,120,0,140,20)
  local before=V.encode(v)
  local tx,err=B.plan(v,1,1,a.id,b.id,"union")
  assert(not tx and err and (err:find("furo") or err:find("contorno")))
  assert(V.encode(v)==before)
  assert(snapshot:find("LFVECTOR 3",1,true))
  print("OK: invalid compound operand refuses operation without mutation")
end
