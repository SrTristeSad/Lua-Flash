-- Run from repository root: lua tests/model_test.lua
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Runtime=require("src.runtime")

local doc=Model.new(640,360,24)
assert(doc.width==640 and doc.height==360)
assert(doc.fps==24)
local layer=doc.layers[1]
local points={4.25,10.5,40.125,65.875}
local sh=Model.makeShape("line",{0.15,0.25,0.35},2.5,points[1],points[2])
sh.points[3],sh.points[4]=points[3],points[4]
table.insert(layer.keys[1],sh)
assert(Model.frame(layer,4)[1]==sh,"held frame")
Model.ensureKey(layer,8)
assert(Model.isKey(layer,8))
assert(Model.frame(layer,7)[1]==sh)
assert(Model.frame(layer,8)[1]~=sh,"key must isolate shapes")
Model.move(layer.keys[8][1],10,-2)
assert(Model.frame(layer,1)[1].points[1]==points[1],"key editing may not change previous frame")
assert(Model.removeKey(layer,8))
assert(Model.frame(layer,8)[1]==sh)

local encoded=Model.encode(doc)
local decoded,err=Model.decode(encoded)
assert(decoded,err)
assert(#decoded.layers==1)
local read=decoded.layers[1].keys[1][1]
assert(read.kind=="line")
for i=1,4 do
  assert(math.abs(read.points[i]-points[i])<.00001,
    "point "..i.." corrupted: expected "..points[i].." got "..tostring(read.points[i]))
end
assert(Model.svg(doc,1):find("<svg",1,true))
assert(not Model.decode("FWSxxxxx"),"must not accept Flash SWF")
assert(not Model.decode("LUAFLASH 2"),"must reject incompatible version")

local player=Runtime.new(doc)
assert(player.frame==1)
player.playing=true
player:update(1/24)
assert(player.frame==2)
player:seek(60)
player:update(1/24)
assert(player.frame==1,"playback loops")
local x,y,scale=Runtime.geometry(doc,0,0,1280,720)
assert(x==0 and y==0 and scale==2)
local Demo=require("src.demo")
local sample=Demo.create()
assert(#sample.layers==2 and sample.totalFrames==90)
assert(#Model.frame(sample.layers[2],1)==2)
assert(Model.frame(sample.layers[2],1)[1].points[1]~=Model.frame(sample.layers[2],90)[1].points[1])
local sampleRoundTrip=assert(Model.decode(Model.encode(sample)))
assert(#Model.frame(sampleRoundTrip.layers[2],90)==2)
print("OK: native player and studio codec, timeline, sample, frames")
