-- Player 0.18: stress moderately large native scenes and timeline key searching.
-- Reports timing/memory information, without flaky wall-clock pass/fail thresholds.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local M=require("src.model")
local I=require("src.interpolation")
local D=require("src.diagnostics")
collectgarbage("collect")
local baseline=collectgarbage("count")
local doc=M.new(900,600,30)
doc.totalFrames=512
local LAYERS,KEYS,SHAPES=18,32,20
for li=1,LAYERS do
  local layer=li==1 and doc.layers[1] or M.addLayer(doc)
  layer.name="stress_"..li
  for ki=1,KEYS do
    local frame=1+(ki-1)*16
    local shapes={}
    for j=1,SHAPES do
      local x=(j*29+li*17)%820+(ki-1)*.25
      local y=(j*13+li*31)%540+(ki-1)*.75
      local sh=M.makeShape("rect",{.22,.47,.67},1,x,y)
      sh.points={x,y,x+8,y+12}
      shapes[j]=sh
    end
    layer.keys[frame]=shapes
  end
end
local shapeCount=LAYERS*KEYS*SHAPES
assert(shapeCount==11520)
local bytes=M.encode(doc)
local decoded,err=M.decode(bytes)
assert(decoded,err)
assert(#decoded.layers==LAYERS)
local sampler=I.new(decoded)
local start=os.clock()
local samples=0
for frame=1,510,5 do
  local position=frame+.5
  local scene=sampler:sample(position)
  assert(#scene.layers==LAYERS)
  assert(#scene.layers[1].keys[1]==SHAPES)
  local oldComputations=sampler.computations
  assert(sampler:sample(position)==scene)
  assert(sampler.computations==oldComputations,
    "same fractional frame should be served from cache")
  samples=samples+1
end
local elapsed=os.clock()-start
-- Key searches stay correct before, between and after the final authored key.
local first=sampler:sample(1).layers[1].keys[1][1].points[1]
local exact=sampler:sample(17).layers[1].keys[1][1].points[1]
local mid=sampler:sample(9).layers[1].keys[1][1].points[1]
assert(first<mid and mid<exact,"binary key-search lost the correct interval")
assert(sampler:sample(511).layers[1].keys[1]==decoded.layers[1].keys[497],
  "final key must be held until end of timeline")
assert(M.encode(doc)==bytes,"stress queries must never mutate source scene")
collectgarbage("collect")
local current=collectgarbage("count")
assert(current-baseline<30*1024,
  "large timeline test retained excessive Lua memory")
local stats=D.new()
for _=1,180 do stats:update(1/60) end
local fps=stats:snapshot(nil,nil,nil)
assert(fps.fps>=59 and fps.fps<=61)
print(string.format(
  "OK: Player 0.18 stress: %d layers, %d authored shapes, %d samples, %.3fs, %.1fMB Lua",
  LAYERS,shapeCount,samples,elapsed,current/1024))
