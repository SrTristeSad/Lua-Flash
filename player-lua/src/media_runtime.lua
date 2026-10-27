-- Lua-Flash 0.7: LÖVE-backed decoded image and short PCM sound resources.
-- Only validated in-memory FileData; no filesystem paths, network or scripts.
local Runtime=require("src.runtime")
local M={}
M.__index=M

function M.new(definition)
  local self=setmetatable({definition=definition,images={},sounds={},muted=false},M)
  for _,asset in ipairs(definition.resources or {}) do
    local ext=asset.kind=="PNG" and ".png" or ".wav"
    local data=love.filesystem.newFileData(asset.data,asset.id..ext)
    if asset.kind=="PNG" then
      local image=love.graphics.newImage(data)
      image:setFilter("nearest","nearest")
      self.images[asset.id]=image
    else
      local soundData=love.sound.newSoundData(data)
      self.sounds[asset.id]=love.audio.newSource(soundData,"static")
    end
  end
  return self
end
function M:release()
  for _,sound in pairs(self.sounds) do sound:stop() end
end
function M:toggleMute()
  self.muted=not self.muted
  if self.muted then self:release() end
  return self.muted
end
function M:draw(document,x,y,w,h)
  if #self.definition.sprites==0 then return end
  local ox,oy,scale=Runtime.geometry(document,x,y,w,h)
  local lg=love.graphics
  lg.push("all")
  lg.setScissor(x,y,w,h)
  lg.translate(ox,oy)
  lg.scale(scale)
  lg.setColor(1,1,1,1)
  for _,sprite in ipairs(self.definition.sprites) do
    local image=self.images[sprite.asset]
    if image then
      lg.draw(image,sprite.x,sprite.y,0,
        sprite.width/image:getWidth(),sprite.height/image:getHeight())
    end
  end
  lg.pop()
end

function M:trigger(event,session)
  if self.muted or not event then return false end
  local fired=false
  for _,cue in ipairs(self.definition.cues) do
    local matched=false
    if cue.event=="WIN" then
      matched=event.type=="win"
    elseif cue.event=="KEY" then
      matched=event.type=="keydown" and event.key==cue.target
    elseif cue.event=="CLICKID" then
      matched=event.clicked and event.hit~=nil and session and
        session:objectForHit(event.hit,event.frame or session.transport.position)==cue.target
    elseif cue.event=="COLLIDE" then
      matched=event.type=="collision" and
        ((event.a==cue.target and event.b==cue.other) or
         (event.a==cue.other and event.b==cue.target))
    end
    if matched then
      local sound=self.sounds[cue.asset]
      if sound then sound:stop();sound:play();fired=true end
    end
  end
  return fired
end

return M
