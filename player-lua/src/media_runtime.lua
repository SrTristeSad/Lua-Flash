-- Lua-Flash 0.7: LÖVE-backed decoded image and short PCM sound resources.
-- Only validated in-memory FileData; no filesystem paths, network or scripts.
local Runtime=require("src.runtime")
local Model=require("src.model")
local Collision=require("src.collision")
local M={}
M.__index=M

function M.new(definition)
  local self=setmetatable({definition=definition,images={},sounds={},muted=false,
    volume=1,bindingsByIndex={},bindingsById={}},M)
  for _,b in ipairs(definition.spriteBindings or {}) do
    self.bindingsByIndex[b.index]=b
    self.bindingsById[b.id]=b
  end
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
-- Sprite rectangles are computed in STAGE coordinates. FOLLOW tracks the center
-- of the native object through its bound keyframes and visual interpolation.
function M:spriteRect(index,position,scene)
  local sprite=self.definition.sprites[index]
  if not sprite then return nil end
  local x,y=sprite.x,sprite.y
  local binding=self.bindingsByIndex[index]
  if binding and binding.mode=="FOLLOW" then
    local shape=Collision.resolve(self.definition,binding.id,position,scene)
    if not shape then return nil end
    local x1,y1,x2,y2=Model.bounds(shape)
    x=(x1+x2-sprite.width)/2
    y=(y1+y2-sprite.height)/2
  end
  return {kind="rect",points={x,y,x+sprite.width,y+sprite.height}}
end

function M:shapeForObject(id,position,scene)
  local b=self.bindingsById[id]
  return b and self:spriteRect(b.index,position,scene) or nil
end

-- Sprites are painted ABOVE vectors, so they are tested front-to-back first.
-- Current collision/hit-test is axis-aligned; transparent PNG pixels still hit.
function M:hit(x,y,position,sampler)
  if not x or not y then return nil end
  local scene=nil
  for index=#self.definition.sprites,1,-1 do
    local bind=self.bindingsByIndex[index]
    if bind then
      if bind.mode=="FOLLOW" and sampler and not scene then
        scene=sampler:sample(position)
      end
      local rect=self:spriteRect(index,position,scene)
      if rect then
        local p=rect.points
        if x>=p[1] and x<=p[3] and y>=p[2] and y<=p[4] then
          return {sprite=bind.id,kind="sprite",spriteIndex=index}
        end
      end
    end
  end
  return nil
end

function M:draw(document,x,y,w,h,position,sampler)
  if #self.definition.sprites==0 then return end
  local ox,oy,scale=Runtime.geometry(document,x,y,w,h)
  local lg=love.graphics
  lg.push("all")
  lg.setScissor(x,y,w,h)
  lg.translate(ox,oy)
  lg.scale(scale)
  lg.setColor(1,1,1,1)
  local scene=nil
  for index,sprite in ipairs(self.definition.sprites) do
    local image=self.images[sprite.asset]
    if image then
      local bind=self.bindingsByIndex[index]
      if bind and bind.mode=="FOLLOW" and sampler and not scene then
        scene=sampler:sample(position)
      end
      local rect=self:spriteRect(index,position or 1,scene)
      if rect then
        local p=rect.points
        lg.draw(image,p[1],p[2],0,
          sprite.width/image:getWidth(),sprite.height/image:getHeight())
      end
    end
  end
  lg.pop()
end

function M:setVolume(value)
  if type(value)~="number" or value~=value then return self.volume end
  self.volume=math.max(0,math.min(1,value))
  for _,sound in pairs(self.sounds) do
    if sound.setVolume then sound:setVolume(self.volume) end
  end
  return self.volume
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
