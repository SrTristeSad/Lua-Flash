-- Player 0.28: interpolate only compatible preindexed vector segments.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local M=require("src.model")
local I=require("src.interpolation")
local doc=M.new(800,450,30)
doc.totalFrames=40
local a=doc.layers[1]
local function rect(x)
  return {kind="rect",color={.4,.5,.6},thickness=2,
    points={x,10,x+10,25}}
end
a.keys[1]={rect(10),rect(50)}
a.keys[11]={rect(30),rect(70)}
a.keys[21]={rect(60),rect(100)}
local layer=M.addLayer(doc)
layer.keys[1]={rect(1)}
layer.keys[11]={{kind="ellipse",points={1,2,3,4},
  color={1,1,1},thickness=2}}
layer.keys[21]={rect(20)}
local inter=I.new(doc)
assert(inter.compatibilityChecks==4,
  "two adjacent pairs for each of two layers must be prechecked")
assert(inter.segments[1][1] and inter.segments[1][11])
assert(not inter.segments[2][1] and not inter.segments[2][11],
  "incompatible morphs must hold the preceding authored shape")
for frame=1,40 do
  local pos=frame+.25
  local scene=inter:sample(pos)
  local source=inter:sample(pos)
  assert(source==scene,"same temporal point must be cached")
  assert(#scene.layers==2 and #scene.layers[1].keys[1]==2)
  assert(inter.compatibilityChecks==4,
    "CPU expensive compatibility scanning must happen at load time only")
end
local at6=inter:sample(6)
local shapes=at6.layers[1].keys[1]
assert(math.abs(shapes[1].points[1]-20)<1e-7,
  "position halfway between frame 1 and 11 must be interpolated")
assert(math.abs(shapes[2].points[1]-60)<1e-7)
assert(shapes[1]~=a.keys[1][1] and shapes[1].color~=a.keys[1][1].color,
  "smooth scene must not mutate authored shapes")
local held=at6.layers[2].keys[1]
assert(held==layer.keys[1],"incompatible change must hold previous shape")
assert(inter:sample(11).layers[1].keys[1]==a.keys[11],
  "exact key must refer to original authored list")
assert(inter:sample(40).layers[1].keys[1]==a.keys[21],
  "last key must remain visible until timeline ends")
assert(inter.blended>0 and inter.computations<=45)
-- After an explicit source edit, refreshing segment metadata is required.
a.keys[11][1].kind="ellipse"
inter:reindex()
assert(not inter.segments[1][1] and not inter.segments[1][11])
assert(inter:sample(6).layers[1].keys[1]==a.keys[1],
  "reindexed incompatible shapes must not interpolate")
assert(a.keys[1][1].points[1]==10,
  "sampling and reindexing must not rewrite source documents")
print("OK: Player 0.28 preindexed morph compatibility, 40 frames and safe invalidation")
