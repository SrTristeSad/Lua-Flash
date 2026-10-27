-- Player 0.14: validated LUAFGAME 9 easing, runtime curves, and old game compatibility.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v9")
local Previous=require("src.package_v8")
local Example=require("src.game_example_v9")
local Ex8=require("src.game_example_v8")
local Ex7=require("src.game_example_v7")
local Ex6=require("src.game_example_v6")
local Ex5=require("src.game_example_v5")
local Ex4=require("src.game_example_v4")
local Ex3=require("src.game_example_v3")
local Ex2=require("src.game_example_v2")
local Ex1=require("src.game_example")
local Old=require("src.package")
local Tween=require("src.sprite_tween")
local Media=require("src.media_runtime")
local Interpolation=require("src.interpolation")
local Geometry=require("src.sprite_transform")

local bytes=Example.bytes()
assert(bytes:sub(1,11)=="LUAFGAME 9\n")
local game,err=Package.decode(bytes)
assert(game,err)
assert(game.version==9 and #game.easings==4)
assert(Package.encode(game)==bytes,"v9 byte-for-byte roundtrip")

local sources={
  assert(Old.encode(Ex1.definition())),
  assert(Previous.encode(Ex2.definition())),
  assert(Previous.encode(Ex3.definition())),
  assert(Previous.encode(Ex4.definition())),
  assert(Previous.encode(Ex5.definition())),
  assert(Previous.encode(Ex6.definition())),
  assert(Previous.encode(Ex7.definition())),
  assert(Previous.encode(Ex8.definition()))
}
for i,legacy in ipairs(sources) do
  local decoded,reason=Package.decode(legacy)
  assert(decoded,reason)
  assert(Package.encode(decoded)==legacy,"v"..i.." changed during decode/encode")
end

local function rejected(mutator)
  local g=Example.definition()
  mutator(g)
  assert(not Package.encode(g),"unsafe easing entry serialized")
end
rejected(function(g) g.easings[1].index=99 end)
rejected(function(g) g.easings[1].frame=90 end) -- final key is not a segment
rejected(function(g) g.easings[1].frame=2 end) -- no key at frame 2
rejected(function(g) g.easings[1].mode="LUA" end)
rejected(function(g) g.easings[1].mode="ease_in" end)
rejected(function(g) g.easings[1].frame=0/0 end)
rejected(function(g) g.easings[#g.easings+1]={index=1,frame=1,mode="STEP"} end)
rejected(function(g) g.easings[1].index=1.5 end)
for i,payload in ipairs({
  bytes.."extra",bytes:sub(1,#bytes-10),
  bytes:gsub("LUAFGAME 9","LUAFGAME 10",1),
  bytes:gsub("EASING_COUNT\t4","EASING_COUNT\t9999",1),
  bytes:gsub("EASING\t1\t1\tEASE_IN_OUT","EASING\t1\t1\tEXEC",1),
  bytes:gsub("EASING\t1\t1\tEASE_IN_OUT","EASING\t1\t99\tEASE_IN_OUT",1),
  bytes:gsub("BASE_BYTES\t","BASE_BYTES\t10",1)
}) do
  assert(not Package.decode(payload),"corrupt package #"..i.." accepted")
end

local sampler=Tween.new(game)
local frame=1+22*.25
local first=sampler:sample(1,frame)
assert(math.abs(first.x-30*.125)<1e-7,"in-out easing failed")
assert(first.y==-45*.125 and first.angle==90*.125)
assert(sampler:sample(1,frame)==first,"cached result not reused")

-- Each mode's exact normalized progress at 25%.
local expected={
 LINEAR=.25,EASE_IN=.0625,EASE_OUT=.4375,
 EASE_IN_OUT=.125,SMOOTH=.15625,STEP=0
}
for mode,value in pairs(expected) do
  local g=Ex8.definition()
  g.version=9
  g.easings={{index=1,frame=1,mode=mode}}
  local restored=assert(Package.decode(assert(Package.encode(g))))
  local pose=Tween.new(restored):sample(1,frame)
  assert(math.abs(pose.x-30*value)<1e-7,mode.." interpolation mismatch")
end
local stepping=Ex8.definition()
stepping.version=9
stepping.easings={{index=1,frame=1,mode="STEP"}}
local sample=Tween.new(stepping)
assert(sample:sample(1,22.99).x==0)
assert(sample:sample(1,23).x==30)
assert(sample:sample(1,23.01).x>30,"step only belongs to its chosen segment")
local passthrough=Tween.new(Ex8.definition())
assert(passthrough:sample(1,frame).x==7.5,"old packages remain LINEAR")

-- Rendering and hit testing use exactly the same eased pose.
local drawn={}
_G.love={
 filesystem={newFileData=function(data,name) return {data=data,name=name} end},
 image={newImageData=function()
   return {getWidth=function() return 16 end,getHeight=function() return 16 end,
     getPixel=function(_,x,y) return 1,1,1,x>=8 and 1 or 0 end}
 end},
 graphics={newImage=function()
     return {setFilter=function() end,getWidth=function() return 16 end,
       getHeight=function() return 16 end}
   end,push=function() end,pop=function() end,setScissor=function() end,
   translate=function() end,scale=function() end,setColor=function() end,
   draw=function(...) drawn[#drawn+1]={...} end
 },
 sound={newSoundData=function(data) return data end},
 audio={newSource=function() return {stop=function() end,play=function() end} end}
}
local media=Media.new(game)
local interpolation=Interpolation.new(game.document)
local eased=assert(media:spriteRect(1,frame,interpolation:sample(frame)))
local pointX,pointY=Geometry.toWorld(eased,.875,.5)
assert(media:hit(pointX,pointY,frame,interpolation).sprite=="bola")
media:draw(game.document,0,0,800,450,frame,interpolation)
assert(#drawn>0)
local call=drawn[#drawn]
assert(math.abs(call[4]-eased.angle)<1e-7,"draw must use eased pose")
local linearMedia=Media.new(Ex8.definition())
local linear=assert(linearMedia:spriteRect(1,frame,interpolation:sample(frame)))
assert(eased.originX~=linear.originX,"easing must change on-screen position")
media:release();linearMedia:release()

print("OK: LUAFGAME 9 easing modes, alpha hits, render, safe package, v1-v8")
