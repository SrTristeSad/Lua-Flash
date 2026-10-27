-- LUAFGAME 4: binary PNG/WAV import, resource validation, runtime cues, legacy formats.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local P=require("src.package_v4")
local P3=require("src.package_v3")
local Old=require("src.package")
local Example=require("src.game_example_v4")
local Example3=require("src.game_example_v3")
local Ex1=require("src.game_example")
local Ex2=require("src.game_example_v2")
local Media=require("src.media_runtime")
local Session=require("src.session")
local Transport=require("src.transport")
local g=Example.definition()
local bytes,err=P.encode(g)
assert(bytes,err)
assert(bytes:sub(1,11)=="LUAFGAME 4\n")
local restored,decodeError=P.decode(bytes)
assert(restored,decodeError)
assert(restored.version==4 and #restored.resources==2)
assert(#restored.sprites==1 and #restored.cues==3)
assert(P.encode(restored)==bytes,"binary game roundtrip")
for _,asset in ipairs(restored.resources) do
  assert(#asset.data>44)
  if asset.kind=="PNG" then assert(asset.data:sub(1,8)=="\137PNG\r\n\26\n") end
  if asset.kind=="WAV" then assert(asset.data:sub(1,4)=="RIFF") end
end

for _,older in ipairs({
  assert(Old.encode(Ex1.definition())),
  assert(P3.encode(Ex2.definition())),
  assert(P3.encode(Example3.definition()))
}) do
  local found,msg=P.decode(older)
  assert(found,msg)
  assert(P.encode(found)==older,"old game must retain original binary form")
end

local bad=Example.definition()
bad.resources[1].kind="LUA"
assert(not P.encode(bad),"must reject arbitrary executable resources")
bad=Example.definition()
bad.resources[2].data="RIFFnot a wave file"
assert(not P.encode(bad))
bad=Example.definition()
bad.sprites[1].asset="acerto"
assert(not P.encode(bad),"audio cannot be drawn as sprite")
bad=Example.definition()
bad.cues[1].asset="estrela"
assert(not P.encode(bad),"image cannot be played as sound")
bad=Example.definition()
bad.cues[1].event="EVAL"
assert(not P.encode(bad))
bad=Example.definition()
bad.cues[1].target="fake_object"
assert(not P.encode(bad))
bad=Example.definition()
bad.resources[2].id="estrela"
assert(not P.encode(bad),"duplicate asset IDs")
bad=Example.definition()
bad.sprites[1].width=0
assert(not P.encode(bad))
bad=Example.definition()
bad.cues[2].other="not_a_barrier"
assert(not P.encode(bad))
local malformed={
  bytes.."TRAILING",
  bytes:sub(1,#bytes-12),
  bytes:gsub("LUAFGAME 4","LUAFGAME 5",1),
  bytes:gsub("RESOURCE_COUNT\t2","RESOURCE_COUNT\t27",1),
  bytes:gsub("SPRITE_COUNT\t1","SPRITE_COUNT\t60",1),
  bytes:gsub("CUE_COUNT\t3","CUE_COUNT\t999",1),
  bytes:gsub("RESOURCE\testrela\tPNG","RESOURCE\testrela\tEXE",1),
  bytes:gsub("RESOURCE\tacerto\tWAV","RESOURCE\tacerto\tLUA",1),
  bytes:gsub("SPRITE\testrela","SPRITE\tnot_existing",1),
  bytes:gsub("GAME_BYTES\t","GAME_BYTES\t12",1)
}
for i,payload in ipairs(malformed) do
  assert(not P.decode(payload),"must reject corrupt media #" .. i)
end

local soundStop,soundPlay,draws=0,0,0
local images={}
_G.love={
  filesystem={newFileData=function(data,name)
    return {data=data,name=name}
  end},
  sound={newSoundData=function(data)
    assert(data.data:sub(1,4)=="RIFF")
    return data
  end},
  audio={newSource=function(_,kind)
    assert(kind=="static")
    return {stop=function() soundStop=soundStop+1 end,
      play=function() soundPlay=soundPlay+1 end}
  end},
  graphics={
    newImage=function(file)
      assert(file.data:sub(1,8)=="\137PNG\r\n\26\n")
      return {setFilter=function() end,getWidth=function() return 16 end,
        getHeight=function() return 16 end}
    end,
    push=function() end,pop=function() end,setScissor=function() end,
    translate=function() end,scale=function() end,setColor=function() end,
    draw=function() draws=draws+1 end
  }
}
local media=Media.new(restored)
local session=Session.new(restored,Transport.new(restored.document))
assert(media:trigger({type="pointerup",clicked=true,frame=1,
    hit={layer=2,shape=1}},session))
assert(soundPlay==1 and soundStop==1)
assert(media:trigger({type="collision",a="barreira",b="bola"},session))
assert(soundPlay==2)
assert(media:trigger({type="win"},session))
assert(soundPlay==3)
assert(not media:trigger({type="keydown",key="q"},session))
media:draw(restored.document,0,0,800,450)
assert(draws==1,"should render embedded PNG once")
assert(media:toggleMute())
assert(not media:trigger({type="win"},session))
assert(soundPlay==3)
assert(not media:toggleMute())
assert(media:trigger({type="win"},session))
assert(soundPlay==4)
media:release()
print("OK: Player 0.7 PNG/WAV packages, 1-3 compatibility, invalid media, rendering and audio cues")
