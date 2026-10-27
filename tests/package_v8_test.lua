-- Player 0.13: animated sprite pose, compatibility, rendering and interaction.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v8")
local Previous=require("src.package_v7")
local Example=require("src.game_example_v8")
local Ex7=require("src.game_example_v7")
local Ex6=require("src.game_example_v6")
local Ex5=require("src.game_example_v5")
local Ex4=require("src.game_example_v4")
local Ex3=require("src.game_example_v3")
local Ex2=require("src.game_example_v2")
local Ex1=require("src.game_example")
local Legacy=require("src.package")
local Tween=require("src.sprite_tween")
local Geometry=require("src.sprite_transform")
local Media=require("src.media_runtime")
local Sampler=require("src.interpolation")
local Input=require("src.input")
local Session=require("src.session")
local Transport=require("src.transport")

local bytes=Example.bytes()
assert(bytes:sub(1,11)=="LUAFGAME 8\n")
local game,err=Package.decode(bytes);assert(game,err)
assert(game.version==8 and #game.tweens==1 and #game.tweens[1].keys==5)
assert(Package.encode(game)==bytes,"binary v8 package must roundtrip")
for _,old in ipairs({
  assert(Legacy.encode(Ex1.definition())),
  assert(Previous.encode(Ex2.definition())),
  assert(Previous.encode(Ex3.definition())),
  assert(Previous.encode(Ex4.definition())),
  assert(Previous.encode(Ex5.definition())),
  assert(Previous.encode(Ex6.definition())),
  assert(Previous.encode(Ex7.definition()))
}) do
  local decoded,decodeErr=Package.decode(old)
  assert(decoded,decodeErr)
  assert(Package.encode(decoded)==old,"v1-v7 packages must stay byte-identical")
end
local function reject(mutate)
  local value=Example.definition()
  mutate(value)
  assert(not Package.encode(value),"invalid track serialized")
end
reject(function(g) g.tweens[1].index=999 end)
reject(function(g) g.tweens[1].keys[1].frame=2 end)
reject(function(g) g.tweens[1].keys[2].frame=1 end)
reject(function(g) g.tweens[1].keys[2].scaleX=0 end)
reject(function(g) g.tweens[1].keys[2].scaleY=401 end)
reject(function(g) g.tweens[1].keys[2].angle=361 end)
reject(function(g) g.tweens[1].keys[2].x=10000 end)
reject(function(g) g.tweens[1].keys[2].y=0/0 end)
reject(function(g) g.tweens[2]=g.tweens[1] end)
reject(function(g) g.tweens[1].keys={g.tweens[1].keys[1]} end)
for i,bad in ipairs({
 bytes.."junk", bytes:sub(1,#bytes-10),
 bytes:gsub("LUAFGAME 8","LUAFGAME 9",1),
 bytes:gsub("TWEEN_COUNT\t1","TWEEN_COUNT\t99",1),
 bytes:gsub("TWEEN\t1\t5","TWEEN\t1\t500",1),
 bytes:gsub("KEY\t23\t30","KEY\t23\t99999",1),
 bytes:gsub("BASE_BYTES\t","BASE_BYTES\t7",1)
}) do
  assert(not Package.decode(bad),"corrupted v8 game accepted: "..i)
end

local tween=Tween.new(game)
local a=tween:sample(1,12)
assert(a.x==15 and a.y==-22.5 and a.angle==45)
assert(a.scaleX==125 and a.scaleY==92.5)
assert(tween:sample(1,12)==a,"tween should reuse pose for same position")
assert(tween:sample(1,90).angle==360)
assert(tween:sample(1,200).x==0)
assert(tween:sample(2,12)==nil)
local alternate=Example.definition()
alternate.tweens[1].keys={
 {frame=1,x=0,y=0,angle=170,scaleX=100,scaleY=100},
 {frame=23,x=10,y=20,angle=-170,scaleX=200,scaleY=100}
}
local turn=Tween.new(alternate):sample(1,12)
assert(math.abs(turn.angle-180)<1e-6,"rotation must choose shortest arc")
assert(turn.x==5 and turn.y==10 and turn.scaleX==150)
local k1=alternate.tweens[1].keys[1]
assert(k1.angle==170,"tween must not mutate source keyframes")

local drawn={}
_G.love={
 filesystem={newFileData=function(data,name) return {name=name,data=data} end},
 sound={newSoundData=function(data) return data end},
 audio={newSource=function() return {stop=function() end,play=function() end} end},
 image={newImageData=function()
   return {getWidth=function() return 16 end,getHeight=function() return 16 end,
     getPixel=function(_,x,y) return 1,1,1,x>=8 and 1 or 0 end}
 end},
 graphics={
   newImage=function() return {setFilter=function() end,
     getWidth=function() return 16 end,getHeight=function() return 16 end} end,
   push=function() end,pop=function() end,setScissor=function() end,
   translate=function() end,scale=function() end,setColor=function() end,
   draw=function(...) drawn[#drawn+1]={...} end
 }
}
local media=Media.new(game)
local sampler=Sampler.new(game.document)
local position=12
local scene=sampler:sample(position)
local pose=assert(media:spriteRect(1,position,scene))
assert(pose.transformed and math.abs(pose.angle-math.pi/4)<1e-6)
local cx,cy=Geometry.toWorld(pose,.875,.5)
local tx,ty=Geometry.toWorld(pose,.125,.5)
local hit=assert(media:hit(cx,cy,position,sampler))
assert(hit.sprite=="bola")
local transparent=media:hit(tx,ty,position,sampler)
assert(not transparent or transparent.sprite~="bola")
local input=Input.new()
local vp={x=0,y=0,w=800,h=450}
input:pointer("down","mouse",1,cx,cy,game.document,position,vp,sampler,media)
local click=input:pointer("up","mouse",1,cx,cy,game.document,position,vp,sampler,media)
assert(click.clicked and click.hit.sprite=="bola")
local session=Session.new(game,Transport.new(game.document))
assert(session:dispatch(click) and session.states.toques==1)
media:draw(game.document,0,0,800,450,position,sampler)
assert(#drawn>0)
local draw=drawn[#drawn]
assert(math.abs(draw[4]-math.pi/4)<1e-6,"rendering must use tweened rotation")
local changed=assert(media:spriteRect(1,23,sampler:sample(23)))
assert(changed.originX~=pose.originX and changed.originY~=pose.originY)
-- A moving sprite's collision uses its CURRENT keyframed pose, not its static v7 one.
local g2=Example.definition()
g2.tweens[1].keys={
 {frame=1,x=0,y=0,angle=0,scaleX=100,scaleY=100},
 {frame=23,x=0,y=0,angle=0,scaleX=100,scaleY=100}
}
local mediaNear=Media.new(assert(Package.decode(assert(Package.encode(g2)))))
assert(mediaNear:collides("bola","barreira",23,sampler:sample(23)),
 "the base position should touch the barrier")
g2.tweens[1].keys[2].x=500
local mediaFar=Media.new(assert(Package.decode(assert(Package.encode(g2)))))
assert(not mediaFar:collides("bola","barreira",23,sampler:sample(23)),
 "keyframed offset must also move collision geometry")
local moved=assert(mediaFar:shapeForObject("bola",23,sampler:sample(23)))
local mx,my=Geometry.toWorld(moved,.875,.5)
assert(mediaFar:hit(mx,my,23,sampler).sprite=="bola",
 "keyframed position must also move pointer target")
media:release();mediaNear:release();mediaFar:release()
print("OK: v8 keyframes, shortest rotation, alpha hit, rendering, collision, v1-v7")
