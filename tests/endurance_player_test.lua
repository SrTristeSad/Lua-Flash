-- Player 0.26: deterministic 20-minute synthetic playback endurance regression.
-- Simulates 72,000 60Hz ticks without sleeping; not a GPU benchmark.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Transport=require("src.transport")
local Interpolation=require("src.interpolation")
local Tween=require("src.sprite_tween")
local Package=require("src.package_v9")
local Example=require("src.game_example_v9")
local Diagnostics=require("src.diagnostics")
local original=Example.bytes()
local g=assert(Package.decode(original))
local timeline=Transport.new(g.document)
local interpolator=Interpolation.new(g.document)
local sprites=Tween.new(g)
local stats=Diagnostics.new()
local first=collectgarbage("count")
local frameCount,wraps,samples=72000,0,0
timeline.playing=true
timeline.loop=true
local start=os.clock()
for tick=1,frameCount do
  timeline:update(1/60)
  stats:update(1/60)
  assert(timeline.position>=1 and timeline.position<g.document.totalFrames+1,
    "timeline position escaped during long playback")
  wraps=wraps+timeline.lastWraps
  if tick%8==0 then
    local p=timeline.position
    local scene=interpolator:sample(p)
    assert(scene and scene.layers and #scene.layers==#g.document.layers)
    -- Cache should return the same scene for an unchanged playhead.
    assert(interpolator:sample(p)==scene)
    -- A single transformed sprite track is enough to exercise tween queries.
    local t=sprites:sample(1,p)
    assert(t==nil or type(t)=="table")
    samples=samples+1
  end
end
assert(wraps>100,"long-running playback did not cross expected loops")
assert(samples==9000)
local after=collectgarbage("count")
collectgarbage("collect")
local retained=collectgarbage("count")
assert(retained-first<8*1024,
  "long session retained over 8MB of Lua state")
assert(Package.encode(g)==original,
  "playback mutated the imported game instead of sampling it")
local metrics=stats:snapshot(g,nil,nil)
assert(metrics.fps>=59 and metrics.fps<=61)
assert(stats.samples==frameCount)
-- Independent non-loop session must stop exactly at the end.
local single=Transport.new(g.document)
single.loop=false
single.playing=true
for _=1,500 do single:update(.25) end
assert(not single.playing and single.position==g.document.totalFrames)
print(string.format(
  "OK: Player 0.26 20-min virtual session, %d ticks, %d loop wraps, %d samples, retained %.1fKB, %.3fs CPU",
  frameCount,wraps,samples,retained-first,os.clock()-start))
