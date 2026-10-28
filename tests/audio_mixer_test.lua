-- Lua-Flash Player 0.19: polyphony, separate buses and bounded playback.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Mixer=require("src.audio_mixer")
local Media=require("src.media_runtime")
local Game=require("src.game_example_v6")
local Package=require("src.package_v6")
local sources={}
local audio={
  newSource=function(data,kind)
    assert(kind=="static")
    local source={data=data,plays=0,stops=0,playing=false,volume=1}
    function source:isPlaying() return self.playing end
    function source:stop() self.stops=self.stops+1;self.playing=false end
    function source:play() self.plays=self.plays+1;self.playing=true end
    function source:setVolume(v) self.volume=v end
    sources[#sources+1]=source
    return source
  end
}
local m=Mixer.new(audio)
for i=1,6 do assert(m:add("audio"..i,"pcm"..i)) end
assert(not m:add("audio1","duplicate"))
assert(not m:play("missing"))
assert(not m:play("audio1","bogus"))
assert(m:play("audio1","effects"))
assert(m:play("audio1","timeline"))
assert(#sources==2 and sources[1].playing and sources[2].playing,
  "same PCM sound should overlap without stopping previous voice")
assert(sources[1].stops==1 and sources[2].stops==1)
assert(m:setChannelVolume("effects",.4)==.4)
assert(m:setChannelVolume("timeline",.7)==.7)
assert(m:setVolume(.5)==.5)
assert(math.abs(sources[1].volume-.2)<1e-8)
assert(math.abs(sources[2].volume-.35)<1e-8)
assert(m:setChannelVolume("unknown",.2)==nil)
assert(m:setVolume(0/0)==.5)
assert(m:setVolume(2)==1 and m:setVolume(-1)==0)
assert(m:setVolume(1)==1)
assert(m:play("audio1","effects"))
assert(m:play("audio1","effects"))
assert(#m.assets.audio1.voices==4)
assert(m:play("audio1","effects"))
assert(#m.assets.audio1.voices==4 and m.steals==1,
  "per-resource overflow must steal oldest voice")
for id=2,6 do
  for i=1,4 do assert(m:play("audio"..id,"effects")) end
end
assert(m:stats().voices==16 and m:stats().active==16)
assert(m:stats().steals>1 and m.totalStarts==25)
assert(m:toggleMute())
assert(m:stats().active==0)
assert(not m:play("audio1"))
assert(not m:toggleMute())
assert(m:play("audio1"))
local before=m:stats().voices
assert(before==16)
m:release()
assert(m:stats().voices==0 and m:stats().active==0)

-- Backward compatible test doubles without isPlaying use restart semantics.
local legacy={
  newSource=function()
    return {play=function(self) self.count=(self.count or 0)+1 end,
      stop=function(self) self.stopped=(self.stopped or 0)+1 end}
  end
}
local fallback=Mixer.new(legacy)
fallback:add("short","pcm")
assert(fallback:play("short") and fallback:play("short"))
assert(fallback:stats().voices==1)
fallback:release()

-- The media runtime must route cues into independent channels; multiple
-- timeline loops must cross each cue exactly as often as expected.
_G.love={
  filesystem={newFileData=function(data,name) return {data=data,name=name} end},
  sound={newSoundData=function(data) return data end},
  audio=audio,
  graphics={newImage=function()
    return {setFilter=function() end,getWidth=function() return 16 end,
      getHeight=function() return 16 end}
  end}
}
local g=Game.definition()
g.timelineSounds[#g.timelineSounds+1]={frame=1,asset="acerto"}
local media=Media.new(assert(Package.decode(assert(Package.encode(g)))))
assert(media:timelineAdvance(1,1,true,2))
assert(media.mixer.totalStarts==6,"two complete loops should fire all crossed cues")
local stats=media:audioStats()
assert(stats.active<=4 and stats.voices<=4,"single sound cannot exceed pool limit")
assert(media:setChannelVolume("timeline",.3)==.3)
assert(media:setChannelVolume("effects",.65)==.65)
assert(media:playAsset("acerto","effects"))
assert(media:setVolume(.8)==.8)
assert(media:toggleMute())
assert(not media:timelineAdvance(22.5,23.5,true))
assert(not media:toggleMute())
assert(media:timelineAdvance(22.5,23.5,true))
media:release()
assert(media:audioStats().voices==0)
print("OK: Player 0.19 bounded 16-voice mixer, gain buses, overlap and loops")
