-- Player 0.2: transport, interpolation and backwards-compatible native .lflash.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Transport=require("src.transport")
local Interpolation=require("src.interpolation")
local Demo=require("src.demo")

local d=Demo.create()
assert(d.totalFrames==90 and d.fps==30)
assert(Model.isKey(d.layers[2],1) and Model.isKey(d.layers[2],23))
assert(Model.isKey(d.layers[2],45) and Model.isKey(d.layers[2],67))
assert(Model.isKey(d.layers[2],90))
assert(not Model.isKey(d.layers[2],2))
local source=Model.encode(d)
local t=Transport.new(d)

assert(t.position==1 and t:frame()==1 and t.speed==1 and not t.playing)
assert(t:progress()==0)
assert(t:cycleSpeed(1)==1.25 and t:cycleSpeed(-1)==1)
assert(t:setSpeed(2)==2)
assert(t:setSpeed(25)==2,"speed should be bounded")
assert(t:setSpeed(.25)==.25)
assert(t:cycleSpeed(-1)==.25)
t:setSpeed(1)

assert(t:toggle())
t:update(1/60)
assert(math.abs(t.position-1.5)<1e-8)
assert(t:frame()==1)
t:update(-1)
assert(math.abs(t.position-1.5)<1e-8,"negative dt should be ignored")
t:update(0/0)
assert(math.abs(t.position-1.5)<1e-8,"NaN dt should be ignored")

t:seek(90)
t:update(1/30)
assert(math.abs(t.position-1)<1e-8,"loop should wrap after final frame")
t.loop=false
t:seek(90)
t.playing=true
t:update(1/30)
assert(t:frame()==90 and not t.playing,"non-loop should stop at end")
assert(t:toggle() and t.position==1,"replay should restart after ending")

t.playing=false
t:seekProgress(0.5)
assert(math.abs(t.position-45.5)<1e-8)
t:step(-1)
assert(t:frame()==44 and not t.playing)
t:seekProgress(-12)
assert(t:frame()==1)
t:seekProgress(18)
assert(t:frame()==90)
assert(t:progress()==1)

local interpolator=Interpolation.new(d)
local snap=interpolator:sample(12)
assert(snap.width==d.width and snap.height==d.height)
assert(#snap.layers==#d.layers)
local x1=d.layers[2].keys[1][1].points[1]
local x2=d.layers[2].keys[23][1].points[1]
local mid=snap.layers[2].keys[1][1].points[1]
assert(math.abs(mid-(x1+(x2-x1)*.5))<1e-8,"should blend between adjacent keyframes")
assert(snap.layers[1].keys[1][1]==d.layers[1].keys[1][1],"static scenery can be held")
assert(d.layers[2].keys[1][1].points[1]==x1,"tween must not change authoring document")

local endSnap=interpolator:sample(90)
assert(endSnap.layers[2].keys[1][1]==d.layers[2].keys[90][1])
local reconstructed=assert(Model.decode(source))
assert(Model.encode(reconstructed)==source,"native format must remain readable")

-- An incompatible shape list must hold the old artwork (no partial morph).
local mismatch=Model.new(100,100,24)
local old=Model.makeShape("rect",{1,0,0},2,0,0)
old.points={0,0,20,20}
local changed=Model.makeShape("ellipse",{0,1,0},2,40,40)
changed.points={40,40,70,70}
mismatch.layers[1].keys[1]={old}
mismatch.layers[1].keys[10]={changed}
local held=Interpolation.new(mismatch):sample(5)
assert(held.layers[1].keys[1][1]==old,"must hold when shape types differ")

print("OK: player 0.2 speed, looping, scrubbing, tweening and native data")
