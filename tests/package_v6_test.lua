-- Player 0.9: sprite sequences and WAV frame cues, with 1-5 compatibility.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v6")
local Package5=require("src.package_v5")
local Example=require("src.game_example_v6")
local Demo5=require("src.game_example_v5")
local Demo4=require("src.game_example_v4")
local Demo3=require("src.game_example_v3")
local Demo2=require("src.game_example_v2")
local Demo1=require("src.game_example")
local Old=require("src.package")
local Media=require("src.media_runtime")
local Session=require("src.session")
local Transport=require("src.transport")
local Interpolation=require("src.interpolation")

local definition=Example.definition()
local bytes,err=Package.encode(definition)
assert(bytes,err)
assert(bytes:sub(1,11)=="LUAFGAME 6\n")
local decoded,reason=Package.decode(bytes)
assert(decoded,reason)
assert(decoded.version==6 and #decoded.resources==3)
assert(#decoded.animations==1 and #decoded.timelineSounds==2)
assert(Package.encode(decoded)==bytes,"binary roundtrip must preserve media")
for _,older in ipairs({
  assert(Old.encode(Demo1.definition())),
  assert(Package5.encode(Demo2.definition())),
  assert(Package5.encode(Demo3.definition())),
  assert(Package5.encode(Demo4.definition())),
  assert(Package5.encode(Demo5.definition()))
}) do
  local game,e=Package.decode(older)
  assert(game,e)
  assert(Package.encode(game)==older,"legacy game must roundtrip byte-for-byte")
end
local function reject(mutate)
  local g=Example.definition()
  mutate(g)
  assert(not Package.encode(g),"invalid game should not be serialized")
end
reject(function(g) g.animations[1].index=333 end)
reject(function(g) g.animations[1].period=0 end)
reject(function(g) g.animations[1].frames[2]="acerto" end)
reject(function(g) g.animations[1].frames[2]="no_such_png" end)
reject(function(g) g.animations[2]={index=1,period=1,frames={"estrela","estrela_alt"}} end)
reject(function(g) g.timelineSounds[1].frame=9999 end)
reject(function(g) g.timelineSounds[1].asset="estrela" end)
reject(function(g) g.timelineSounds[1].asset="unknown" end)
for i,part in ipairs({
  bytes.."TRAILER",
  bytes:sub(1,#bytes-10),
  bytes:gsub("LUAFGAME 6","LUAFGAME 7",1),
  bytes:gsub("ANIMATION_COUNT\t1","ANIMATION_COUNT\t99",1),
  bytes:gsub("TIMELINE_SOUND_COUNT\t2","TIMELINE_SOUND_COUNT\t200",1),
  bytes:gsub("ANIMATION\t1\t7\t2","ANIMATION\t1\t0\t2",1),
  bytes:gsub("TIMELINE_SOUND\t23\tacerto","TIMELINE_SOUND\t23\tunknown",1),
  bytes:gsub("BASE_BYTES\t","BASE_BYTES\t11",1)
}) do
  assert(not Package.decode(part),"corrupt package must be rejected #"..i)
end

local stopped,played,rendered,volume=0,0,{},nil
_G.love={
  filesystem={newFileData=function(data,name) return {data=data,name=name} end},
  sound={newSoundData=function(file) return file end},
  audio={newSource=function()
    return {
      stop=function() stopped=stopped+1 end,
      play=function() played=played+1 end,
      setVolume=function(_,v) volume=v end
    }
  end},
  graphics={
    newImage=function(file)
      return {
        fileName=file.name,
        setFilter=function() end,
        getWidth=function() return 16 end,
        getHeight=function() return 16 end
      }
    end,
    push=function() end,pop=function() end,setScissor=function() end,
    translate=function() end,scale=function() end,setColor=function() end,
    draw=function(img) rendered[#rendered+1]=img.fileName end
  }
}
local media=Media.new(decoded)
assert(media:imageAsset(1,1)=="estrela")
assert(media:imageAsset(1,7)=="estrela")
assert(media:imageAsset(1,8)=="estrela_alt")
assert(media:imageAsset(1,15)=="estrela")
assert(media:imageAsset(1,90)=="estrela")
local sampler=Interpolation.new(decoded.document)
media:draw(decoded.document,0,0,800,450,8,sampler)
assert(rendered[#rendered]=="estrela_alt.png","draw must choose animated frame")
media:draw(decoded.document,0,0,800,450,15,sampler)
assert(rendered[#rendered]=="estrela.png")
assert(not media:timelineAdvance(22,22.9,true),"no cue before frame boundary")
assert(media:timelineAdvance(22.9,23.4,true))
assert(played==1)
assert(not media:timelineAdvance(23.4,23.8,true),"do not replay within frame")
assert(not media:timelineAdvance(23.8,26,false),"paused clock must be silent")
assert(media:timelineAdvance(44.8,45.5,true))
assert(played==2)
-- Playback wraps at end -> 1; only triggered cues in crossed range may fire.
assert(not media:timelineAdvance(89.9,1.2,true))
local loopGame=Example.definition()
loopGame.timelineSounds[#loopGame.timelineSounds+1]={frame=1,asset="acerto"}
local loopMedia=Media.new(assert(Package.decode(assert(Package.encode(loopGame)))))
assert(loopMedia:timelineAdvance(89.9,1.2,true))
assert(played==3)
-- A tiny timeline can complete two loops and return to the SAME position.
assert(loopMedia:timelineAdvance(1,1,true,2))
assert(played==6,"multiple complete loops must not silence timeline cues")
assert(not loopMedia:timelineAdvance(45,1,false))
assert(media:setVolume(.35)==.35 and volume==.35)
assert(media:toggleMute())
assert(not media:timelineAdvance(22.9,23.4,true))
assert(played==6)
assert(not media:toggleMute())
assert(media:timelineAdvance(22.9,23.4,true))
assert(played==7)
media:release();loopMedia:release()
assert(stopped>=4)
print("OK: LUAFGAME 6 media frames, WAV timeline, pause/loop, malformed data and v1-v5")
