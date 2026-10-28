-- Lua-Flash 0.7: LÖVE-backed decoded image and short PCM sound resources.
-- Only validated in-memory FileData; no filesystem paths, network or scripts.
local Runtime=require("src.runtime")
local Model=require("src.model")
local Collision=require("src.collision")
local PixelMask=require("src.pixel_mask")
local SpriteTransform=require("src.sprite_transform")
local SpriteTween=require("src.sprite_tween")
local AudioMixer=require("src.audio_mixer")
local M={}
M.__index=M

function M.new(definition)
  local self=setmetatable({definition=definition,images={},sounds={},muted=false,
    volume=1,bindingsByIndex={},bindingsById={},animationsByIndex={},
    masks={},assetFiles={},maskBuilds=0,transformsByIndex={},
    tween=SpriteTween.new(definition),mixer=AudioMixer.new(love.audio)},M)
  for _,transform in ipairs(definition.transforms or {}) do
    self.transformsByIndex[transform.index]=transform
  end
  for _,anim in ipairs(definition.animations or {}) do
    self.animationsByIndex[anim.index]=anim
  end
  for _,b in ipairs(definition.spriteBindings or {}) do
    self.bindingsByIndex[b.index]=b
    self.bindingsById[b.id]=b
  end
  for _,asset in ipairs(definition.resources or {}) do
    local ext=asset.kind=="PNG" and ".png" or ".wav"
    local data=love.filesystem.newFileData(asset.data,asset.id..ext)
    if asset.kind=="PNG" then self.assetFiles[asset.id]=data end
    if asset.kind=="PNG" then
      local image=love.graphics.newImage(data)
      image:setFilter("nearest","nearest")
      self.images[asset.id]=image
    else
      local soundData=love.sound.newSoundData(data)
      self.sounds[asset.id]=soundData
      self.mixer:add(asset.id,soundData)
    end
  end
  return self
end
-- Select the PNG based on the current native timeline position (not wall time).
function M:imageAsset(index,position)
  local sprite=self.definition.sprites[index]
  if not sprite then return nil end
  local anim=self.animationsByIndex[index]
  if not anim then return sprite.asset end
  local frame=math.max(1,math.floor(position or 1))
  local sequence=math.floor((frame-1)/anim.period)%#anim.frames+1
  return anim.frames[sequence]
end

function M:playAsset(id,channel)
  return self.mixer:play(id,channel or "effects")
end

-- Timeline WAV cues use a separate gain bus. Multi-loop advancement emits
-- all crossed frames in chronological order (bounded to 64 cue starts per
-- update, preventing audio storms after a huge clock jump).
function M:timelineAdvance(oldPosition,newPosition,wasPlaying,wrapCount)
  if not wasPlaying or not self.definition.timelineSounds then return false end
  if type(oldPosition)~="number" or type(newPosition)~="number" or
     oldPosition~=oldPosition or newPosition~=newPosition then return false end
  local wraps=type(wrapCount)=="number" and math.max(0,math.floor(wrapCount)) or 0
  if wraps==0 and newPosition<oldPosition then wraps=1 end
  if oldPosition==newPosition and wraps==0 then return false end
  local previous,current=math.floor(oldPosition),math.floor(newPosition)
  local total=self.definition.document.totalFrames
  local fired,count=false,0
  local function range(low,high)
    -- Stable ordering for different cues at the same frame is kept.
    local cues={}
    for _,item in ipairs(self.definition.timelineSounds) do
      if item.frame>low and item.frame<=high then cues[#cues+1]=item end
    end
    table.sort(cues,function(a,b) return a.frame<b.frame end)
    for _,item in ipairs(cues) do
      if count>=64 then return false end
      fired=self:playAsset(item.asset,"timeline") or fired
      count=count+1
    end
    return true
  end
  if wraps==0 then range(previous,current)
  else
    if not range(previous,total) then return fired end
    for _=1,math.min(wraps-1,64) do
      if not range(0,total) then return fired end
    end
    range(0,current)
  end
  return fired
end

-- PNG alpha masks are generated only when needed and reused across frames.
-- Missing love.image in test doubles retains the old bounding-box semantics.
function M:maskFor(assetId)
  local existing=self.masks[assetId]
  if existing then return existing end
  if not love.image or not love.image.newImageData then return nil end
  local data=self.assetFiles[assetId]
  if not data then return nil end
  local decoded=love.image.newImageData(data)
  local mask=PixelMask.build(decoded)
  self.masks[assetId]=mask
  self.maskBuilds=self.maskBuilds+1
  return mask
end

-- Alpha-tested sprite against another sprite or vector shape.
-- Broad-phase stays in native geometry; the fine phase checks opaque pixels.
function M:collides(idA,idB,position,scene)
  local boundA,boundB=self.bindingsById[idA],self.bindingsById[idB]
  local a=(boundA and self:shapeForObject(idA,position,scene)) or
    Collision.resolve(self.definition,idA,position,scene)
  local b=(boundB and self:shapeForObject(idB,position,scene)) or
    Collision.resolve(self.definition,idB,position,scene)
  if not a or not b or not Collision.overlap(a,b) then return false end
  if not boundA and not boundB then return true end
  local ma=boundA and self:maskFor(self:imageAsset(boundA.index,position)) or nil
  local mb=boundB and self:maskFor(self:imageAsset(boundB.index,position)) or nil
  if not a.transformed and not b.transformed then
    if boundA and boundB then return PixelMask.overlap(ma,a,mb,b) end
    if boundA then return PixelMask.overlapShape(ma,a,b) end
    return PixelMask.overlapShape(mb,b,a)
  end
  -- Transformed masks need an inverse coordinate mapping, not AABB-only hits.
  -- Test both directions when both objects are PNGs, avoiding missed contacts
  -- where one raster's projected centers fall between the other's samples.
  if boundA and boundB then
    return SpriteTransform.intersects(a,ma,b,mb,
      function(x,y) return SpriteTransform.contains(b,mb,x,y) end) or
      SpriteTransform.intersects(b,mb,a,ma,
      function(x,y) return SpriteTransform.contains(a,ma,x,y) end)
  end
  if boundA then
    return SpriteTransform.intersects(a,ma,b,nil,
      function(x,y) return PixelMask.shapeContains(b,x,y) end)
  end
  return SpriteTransform.intersects(b,mb,a,nil,
    function(x,y) return PixelMask.shapeContains(a,x,y) end)
end

function M:release()
  self.mixer:release()
end
function M:toggleMute()
  self.muted=self.mixer:toggleMute()
  return self.muted
end
function M:setChannelVolume(channel,value)
  return self.mixer:setChannelVolume(channel,value)
end
function M:audioStats()
  return self.mixer:stats()
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
  -- A v8 tween adds stage offsets on top of the existing STATIC/FOLLOW
  -- placement. Rotation and scale override v7 values while interpolating.
  local key=self.tween:sample(index,position or 1)
  local transform=self.transformsByIndex[index]
  if key then
    x=x+key.x
    y=y+key.y
    transform={
      angle=key.angle,scaleX=key.scaleX,scaleY=key.scaleY,
      pivotX=transform and transform.pivotX or 50,
      pivotY=transform and transform.pivotY or 50
    }
  end
  return SpriteTransform.build({kind="rect",
    points={x,y,x+sprite.width,y+sprite.height}},transform)
end

function M:shapeForObject(id,position,scene)
  local b=self.bindingsById[id]
  return b and self:spriteRect(b.index,position,scene) or nil
end

-- When a vector is represented by an interactive PNG, its underlying vector
-- cannot bypass the PNG's alpha transparency during pointer hit testing.
function M:isOverriddenVectorHit(layer,shape,position)
  if not self.definition.bindings then return false end
  local layerData=self.definition.document.layers[layer]
  if not layerData then return false end
  local current=-1
  for frame in pairs(layerData.keys) do
    if frame<=position and frame>current then current=frame end
  end
  for _,binding in ipairs(self.definition.bindings) do
    if binding.layer==layer and binding.frame==current and
       binding.shape==shape and self.bindingsById[binding.id] then
      return true
    end
  end
  return false
end

-- Sprites are painted ABOVE vectors, so they are tested front-to-back first.
-- Inverse-map hits through rotation/scale/pivot; transparent pixels pass through.
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
        if x>=p[1] and x<p[3] and y>=p[2] and y<p[4] and
           SpriteTransform.contains(rect,
             self:maskFor(self:imageAsset(index,position)),x,y) then
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
    local image=self.images[self:imageAsset(index,position)]
    if image then
      local bind=self.bindingsByIndex[index]
      if bind and bind.mode=="FOLLOW" and sampler and not scene then
        scene=sampler:sample(position)
      end
      local rect=self:spriteRect(index,position or 1,scene)
      if rect then
        SpriteTransform.draw(image,rect)
      end
    end
  end
  lg.pop()
end

function M:setVolume(value)
  if type(value)~="number" or value~=value then return self.volume end
  self.volume=self.mixer:setVolume(value)
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
      fired=self:playAsset(cue.asset) or fired
    end
  end
  return fired
end

return M
