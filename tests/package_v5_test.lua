-- Player 0.8: LUAFGAME 5 follows objects, hit tests sprites and collides.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v5")
local Package4=require("src.package_v4")
local Example=require("src.game_example_v5")
local Example4=require("src.game_example_v4")
local Old3=require("src.game_example_v3")
local Old2=require("src.game_example_v2")
local Old1=require("src.game_example")
local OldPackage=require("src.package")
local Game=require("src.session")
local Transport=require("src.transport")
local Interpolation=require("src.interpolation")
local Input=require("src.input")
local Media=require("src.media_runtime")
local Model=require("src.model")

local game=Example.definition()
local bytes,err=Package.encode(game)
assert(bytes,err)
assert(bytes:sub(1,11)=="LUAFGAME 5\n")
local decoded,decodeErr=Package.decode(bytes)
assert(decoded,decodeErr)
assert(decoded.version==5 and decoded.spriteBindings[1].mode=="FOLLOW")
assert(Package.encode(decoded)==bytes,"v5 binary roundtrip")
for _,old in ipairs({
  assert(OldPackage.encode(Old1.definition())),
  assert(Package4.encode(Old2.definition())),
  assert(Package4.encode(Old3.definition())),
  assert(Package4.encode(Example4.definition()))
}) do
  local legacy,reason=Package.decode(old)
  assert(legacy,reason)
  assert(Package.encode(legacy)==old,"v1-v4 byte fidelity")
end

local invalid=Example.definition()
invalid.spriteBindings[1].id="not_an_object"
assert(not Package.encode(invalid),"missing ID")
invalid=Example.definition()
invalid.spriteBindings[1].index=42
assert(not Package.encode(invalid),"unknown sprite")
invalid=Example.definition()
invalid.spriteBindings[1].mode="EXECUTE"
assert(not Package.encode(invalid),"unknown position mode")
invalid=Example.definition()
invalid.spriteBindings[2]={index=1,id="barreira",mode="STATIC"}
assert(not Package.encode(invalid),"one sprite cannot have multiple identities")
invalid=Example.definition()
invalid.spriteBindings[2]={index=1,id="bola",mode="STATIC"}
assert(not Package.encode(invalid),"cannot bind same object twice")

local corrupt={
  bytes.."EXTRA",
  bytes:sub(1,#bytes-12),
  bytes:gsub("LUAFGAME 5","LUAFGAME 6",1),
  bytes:gsub("SPRITE_BIND_COUNT\t1","SPRITE_BIND_COUNT\t999",1),
  bytes:gsub("SPRITE_BIND\t1\tbola\tFOLLOW","SPRITE_BIND\t1\tbola\tEVAL",1),
  bytes:gsub("BASE_BYTES\t","BASE_BYTES\t5",1),
  bytes:gsub("SPRITE_BIND\t1\tbola\tFOLLOW","SPRITE_BIND\t2\tbola\tFOLLOW",1)
}
for i,payload in ipairs(corrupt) do
  assert(not Package.decode(payload),"reject malformed v5 package #"..i)
end

local spriteDraws=0
_G.love={
  filesystem={newFileData=function(data,name) return {data=data,name=name} end},
  sound={newSoundData=function(data) return data end},
  audio={newSource=function()
    return {play=function() end,stop=function() end,
      setVolume=function(self,v) self.volume=v end}
  end},
  graphics={newImage=function()
    return {setFilter=function() end,getWidth=function() return 16 end,
      getHeight=function() return 16 end}
  end,push=function() end,pop=function() end,setScissor=function() end,
    translate=function() end,scale=function() end,setColor=function() end,
    draw=function() spriteDraws=spriteDraws+1 end}
}

local media=Media.new(decoded)
local sampler=Interpolation.new(decoded.document)
local first=assert(media:spriteRect(1,1))
local p=first.points
assert(p[1]==95 and p[2]==245 and p[3]==159 and p[4]==309,
  "FOLLOW must center image over vector object")
local changed=assert(media:spriteRect(1,23))
assert(changed.points[1]~=p[1],"FOLLOW should track new keyframe")
assert(media:hit(127,277,1,sampler).sprite=="bola")
assert(media:hit(127,277,1)==nil or media:hit(127,277,1).sprite=="bola")
assert(media:hit(5,5,1,sampler)==nil)
local s=Game.new(decoded,Transport.new(decoded.document))
assert(s:objectForHit({sprite="bola"},1)=="bola")
local input=Input.new()
local viewport={x=0,y=0,w=800,h=450}
local down=input:pointer("down","mouse",1,127,277,decoded.document,1,viewport,sampler,media)
local up=input:pointer("up","mouse",1,127,277,decoded.document,1,viewport,sampler,media)
assert(down.hit and down.hit.sprite=="bola")
assert(up.clicked and up.hit.sprite=="bola")
assert(s:dispatch(up) and s.states.toques==1)
assert(s:dispatch(up) and s.score==1,"named sprite click triggers normal score rules")

-- Native vector collisions are replaced by the more specific sprite rectangle.
local t=Transport.new(decoded.document)
local active=Game.new(decoded,t)
t:seek(1)
assert(not active:checkCollisions(sampler,media))
t:seek(23)
assert(active:checkCollisions(sampler,media),"sprite must collide with native barrier")
local collisions=active.states.choques
assert(collisions==1)
assert(not active:checkCollisions(sampler,media))
t:seek(45)
assert(not active:checkCollisions(sampler,media))
t:seek(23)
assert(active:checkCollisions(sampler,media))
assert(active.states.choques==2)

media:draw(decoded.document,0,0,800,450,23,sampler)
assert(spriteDraws==1)
assert(media:setVolume(.6)==.6 and media.volume==.6)
assert(media:setVolume(200)==1)
assert(media:setVolume(-10)==0)
assert(media:toggleMute() and not media:trigger({type="win"},s))
assert(not media:toggleMute())
media:release()
-- Fixed overlay: static placement remains unchanged when native object moves.
local static=Example.definition()
static.spriteBindings[1].mode="STATIC"
local m=Media.new(assert(Package.decode(assert(Package.encode(static)))))
local a=assert(m:spriteRect(1,1))
local b=assert(m:spriteRect(1,45))
assert(a.points[1]==b.points[1] and a.points[2]==b.points[2])
m:release()
print("OK: v5 sprites follow objects, foreground mouse/touch hits, collisions and v1-v4 compatibility")
