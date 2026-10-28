-- Player 0.28: synthetic crowded scene and draw-call reduction (no FPS claim).
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local M=require("src.model")
local I=require("src.interpolation")
local Render=require("src.viewport_renderer")
local Runtime=require("src.runtime")
local doc=M.new(800,450,30)
doc.totalFrames=512
local LAYERS,KEYS,SHAPES=18,32,20
local visiblePerLayer=5
for li=1,LAYERS do
  local layer=li==1 and doc.layers[1] or M.addLayer(doc)
  for ki=1,KEYS do
    local frame=1+(ki-1)*16
    local shapes={}
    for j=1,SHAPES do
      local onscreen=j%4==0
      local x=onscreen and (j*23+li)%700 or 2100+j*7
      local y=onscreen and (j*19+ki)%360 or 1800+li*8
      shapes[j]={kind="rect",color={.2,.4,.6},
        thickness=2,points={x,y,x+12,y+8}}
    end
    layer.keys[frame]=shapes
  end
end
local before=M.encode(doc)
local sampler=I.new(doc)
local player=Render.new()
local count={rectangles=0}
local function nop() end
_G.love={graphics=setmetatable({
  getDimensions=function() return 1040,690 end,
  rectangle=function() count.rectangles=count.rectangles+1 end,
  setScissor=nop,
},{__index=function() return nop end})}

local start=os.clock()
-- Baseline runtime draws all authored vectors, including the offscreen ones.
local exact=sampler:sample(33)
Runtime.draw(exact,1,18,100,1004,434)
assert(count.rectangles==LAYERS*SHAPES+2,
  "baseline should include all rectangles plus background/stage")
count.rectangles=0
player:draw(exact,1,18,100,1004,434)
assert(count.rectangles==LAYERS*visiblePerLayer+2,
  "Player must not submit offscreen primitives to LÖVE")
assert(player:stats().lastCulled==LAYERS*(SHAPES-visiblePerLayer))

local inspected=0
for frame=1,510,5 do
  local scene=sampler:sample(frame+.5)
  count.rectangles=0
  player:draw(scene,1,18,100,1004,434)
  local c=player:stats()
  assert(c.lastCulled==LAYERS*(SHAPES-visiblePerLayer))
  assert(c.lastDrawn==LAYERS*visiblePerLayer)
  assert(count.rectangles==c.lastDrawn+2)
  inspected=inspected+1
end
assert(inspected>=100)
assert(sampler.compatibilityChecks==LAYERS*(KEYS-1))
-- Conservative edge checks: thick strokes touching the stage must survive.
local edge=Render.new()
local function shape(kind,points,thickness)
  return {kind=kind,points=points,color={1,1,1},thickness=thickness}
end
assert(edge:visible(shape("rect",{-10,20,10,40}),800,450),
  "partially visible rectangle was culled")
assert(edge:visible(shape("line",{-8,50,-8,100},20),800,450),
  "thick line touching left edge was culled")
assert(edge:visible(shape("brush",{805,10,805,90,805,130},12),800,450),
  "thick brush touching right edge was culled")
assert(not edge:visible(shape("rect",{900,500,920,530}),800,450),
  "fully offscreen rectangle was not culled")
assert(not edge:visible(shape("line",{-100,-20,-80,-20},4),800,450),
  "fully offscreen line was not culled")
local mutable=shape("rect",{900,10,920,30})
assert(not edge:visible(mutable,800,450))
mutable.points={10,10,20,20}
edge:invalidate()
assert(edge:visible(mutable,800,450),
  "bounds cache did not refresh after explicit invalidation")

assert(M.encode(doc)==before,"renderer and sampler changed source game")
collectgarbage("collect")
local kb=collectgarbage("count")
assert(kb<70*1024,"crowded scene used unexpectedly large Lua memory")
print(string.format(
 "OK: Player 0.28 crowd: %d authored forms, %d sampled frames, %d/%d visible per frame, %.2f ms CPU in synthetic test, %.1fMB Lua",
 LAYERS*KEYS*SHAPES,inspected,LAYERS*visiblePerLayer,LAYERS*SHAPES,
 (os.clock()-start)*1000,kb/1024))
