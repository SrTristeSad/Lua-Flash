-- Lua-Flash Player 0.19: bounded polyphonic PCM sound mixer.
-- Uses LÖVE Source voices. WAV SoundData is decoded only once per resource.
-- Effect and timeline buses have independent gains and master volume.
local A={}
A.__index=A
local MAX_VOICES=16
local MAX_PER_RESOURCE=4
local function volume(v)
  return type(v)=="number" and v==v and v~=math.huge and
    v~=-math.huge and math.max(0,math.min(1,v)) or nil
end
function A.new(audio)
  assert(audio and type(audio.newSource)=="function","LÖVE audio unavailable")
  return setmetatable({
    audio=audio,assets={},voices={},volume=1,muted=false,
    gains={effects=1,timeline=1},serial=0,totalStarts=0,steals=0
  },A)
end
function A:add(id,data)
  if type(id)~="string" or self.assets[id] then return false end
  self.assets[id]={data=data,voices={}}
  return true
end
local function applyGain(self,voice)
  if voice.source.setVolume then
    voice.source:setVolume(self.muted and 0 or
      self.volume*self.gains[voice.channel])
  end
end
local function playing(voice)
  -- Test doubles and audio backends without isPlaying keep old monophonic
  -- restart behavior; real LÖVE supports isPlaying and true overlapping.
  if not voice.source.isPlaying then return false end
  local ok,active=pcall(voice.source.isPlaying,voice.source)
  return ok and active==true
end
local function oldest(voices)
  local result
  for _,v in ipairs(voices) do
    if not result or v.serial<result.serial then result=v end
  end
  return result
end
function A:play(id,channel)
  local asset=self.assets[id]
  if not asset or self.muted then return false end
  channel=channel or "effects"
  if not self.gains[channel] then return false end
  local voice
  for _,v in ipairs(asset.voices) do
    if not playing(v) then voice=v;break end
  end
  if not voice and #asset.voices<MAX_PER_RESOURCE then
    if #self.voices>=MAX_VOICES then
      -- Recycle the oldest voice globally, even if owned by another sound.
      local evicted=oldest(self.voices)
      if evicted then
        evicted.source:stop()
        local old=evicted.asset.voices
        for i=#old,1,-1 do
          if old[i]==evicted then table.remove(old,i);break end
        end
        for i=#self.voices,1,-1 do
          if self.voices[i]==evicted then table.remove(self.voices,i);break end
        end
        self.steals=self.steals+1
      end
    end
    local source=self.audio.newSource(asset.data,"static")
    voice={source=source,asset=asset,channel=channel,serial=0}
    asset.voices[#asset.voices+1]=voice
    self.voices[#self.voices+1]=voice
  elseif not voice then
    voice=oldest(asset.voices)
    self.steals=self.steals+1
  end
  if not voice then return false end
  voice.source:stop()
  voice.channel=channel
  self.serial=self.serial+1
  voice.serial=self.serial
  applyGain(self,voice)
  voice.source:play()
  self.totalStarts=self.totalStarts+1
  return true
end
function A:setVolume(v)
  local gain=volume(v)
  if gain==nil then return self.volume end
  self.volume=gain
  for _,v in ipairs(self.voices) do applyGain(self,v) end
  return self.volume
end
function A:setChannelVolume(channel,v)
  if self.gains[channel]==nil then return nil end
  local gain=volume(v)
  if gain==nil then return self.gains[channel] end
  self.gains[channel]=gain
  for _,voice in ipairs(self.voices) do
    if voice.channel==channel then applyGain(self,voice) end
  end
  return gain
end
function A:stop()
  for _,voice in ipairs(self.voices) do voice.source:stop() end
end
function A:toggleMute()
  self.muted=not self.muted
  if self.muted then self:stop() end
  for _,voice in ipairs(self.voices) do applyGain(self,voice) end
  return self.muted
end
function A:countActive()
  local active=0
  for _,v in ipairs(self.voices) do
    if playing(v) then active=active+1 end
  end
  return active
end
function A:stats()
  return {voices=#self.voices,active=self:countActive(),
    steals=self.steals,totalStarts=self.totalStarts,maxVoices=MAX_VOICES}
end
function A:release()
  self:stop()
  self.voices={}
  for _,a in pairs(self.assets) do a.voices={} end
end
return A
