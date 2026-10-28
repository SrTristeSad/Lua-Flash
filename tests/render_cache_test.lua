-- Player 0.27: indexed vector frame rendering and cache regression.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Cache=require("src.render_cache")
local doc=Model.new(900,600,30)
doc.totalFrames=512
local LAYERS,KEYS,SHAPES=18,32,20
for li=1,LAYERS do
  local layer=li==1 and doc.layers[1] or Model.addLayer(doc)
  layer.visible=li~=3
  for k=1,KEYS do
    local frame=1+(k-1)*16
    local shapes={}
    for j=1,SHAPES do
      local shape=Model.makeShape("rect",{.4,.6,.8},1,j*13+li,k*3)
      shape.points={j*13+li,k*3,j*13+li+5,k*3+6}
      shapes[j]=shape
    end
    layer.keys[frame]=shapes
  end
end
local cache=Cache.new(doc)
local inspected=0
for frame=1,doc.totalFrames,5 do
  local scene=cache:scene(frame)
  assert(scene.width==doc.width and scene.height==doc.height)
  for li,layer in ipairs(doc.layers) do
    assert(scene.layers[li].visible==layer.visible)
    assert(scene.layers[li].keys[1]==Model.frame(layer,frame),
      "indexed cache must preserve actual source shape list and layer order")
  end
  assert(cache:scene(frame)==scene,"same integer frame must reuse cached scene")
  assert(cache:scene(frame+.75)==scene,
    "exact mode must reuse scene for subframe positions")
  inspected=inspected+1
end
local stats=cache:stats()
assert(stats.rebuilds==inspected and stats.searches==inspected*LAYERS)
assert(stats.reused==2*inspected)
local original=cache:scene(33)
assert(original.layers[1].keys[1]==doc.layers[1].keys[33])
doc.layers[1].keys[33]={Model.makeShape("ellipse",{1,0,0},1,10,10)}
cache:reindex()
local refreshed=cache:scene(33)
assert(refreshed~=original and
  refreshed.layers[1].keys[1]==doc.layers[1].keys[33],
  "reindex must refresh when the authored document changes")
assert(cache:scene(512).layers[1].keys[1]==doc.layers[1].keys[497])

local calls={rect=0,ellipse=0}
_G.love={graphics=setmetatable({
  rectangle=function() calls.rect=calls.rect+1 end,
  ellipse=function() calls.ellipse=calls.ellipse+1 end
},{__index=function() return function() end end})}
cache:draw(33,18,100,1004,434)
assert(calls.ellipse>=1 and calls.rect>100,
  "Player renderer must draw the indexed scene in the normal LÖVE path")
assert(doc.layers[1].keys[33][1].kind=="ellipse",
  "rendering must not mutate authored shape tables")
print(("OK: Player 0.27 cached vector renderer, %d sampled frames, %d "..
 "key searches vs previous %d scans, preserved draw and reindex"):format(
 inspected,stats.searches,inspected*LAYERS*KEYS))
