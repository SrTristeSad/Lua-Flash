-- Lua-Flash 0.5 rule engine: fixed opcodes, state and named objects.
-- Backwards compatible with LUAFGAME 1. No downloaded script execution.
local Collision=require("src.collision")
local S={}
S.__index=S
local MAX_STATE=1000000
local MAX_SWEEP_STEPS=80
local SUBSTEPS_PER_FRAME=4
local function clamp(x)
  return math.max(0,math.min(MAX_STATE,x))
end

function S.new(definition,transport)
  local states,objects={},{}
  for _,variable in ipairs(definition.states or {}) do
    states[variable.id]=variable.value
  end
  if not definition.version or definition.version<3 then
    for _,obj in ipairs(definition.objects or {}) do
      objects[obj.layer..":"..obj.shape]=obj.id
    end
  end
  -- Compile unique unordered collision pairs once per session.
  local pairs,seen={},{}
  for _,rule in ipairs(definition.rules) do
    if rule.event=="COLLIDE" then
      local a,b=rule.target,rule.other
      local key=a<b and (a..":"..b) or (b..":"..a)
      if not seen[key] then
        seen[key]=true
        pairs[#pairs+1]={a=a,b=b,key=key}
      end
    end
  end
  return setmetatable({
    definition=definition,transport=transport,remaining=definition.duration,
    active=true,won=false,score=0,events=0,states=states,objects=objects,
    colliding={},collisionPairs=pairs,lastCollision=nil,
    lastAction="Clique nos objetos do palco"
  },S)
end
function S:update(dt)
  if not self.active or not self.transport.playing or
     type(dt)~="number" or dt~=dt or dt<=0 then return end
  self.remaining=math.max(0,self.remaining-math.min(dt,.25))
  if self.remaining<=0 then
    self.active=false
    self.transport.playing=false
    self.lastAction="Tempo esgotado"
  end
end
local function condition(self,when)
  if not when then return true end
  local value=self.states[when.id]
  if value==nil then return false end
  if when.op=="GE" then return value>=when.value
  elseif when.op=="LE" then return value<=when.value
  elseif when.op=="EQ" then return value==when.value end
  return false
end
function S:objectForHit(hit,position)
  if not hit then return nil end
  if hit.sprite then return hit.sprite end
  if not self.definition.version or self.definition.version<3 then
    return self.objects[hit.layer..":"..hit.shape]
  end
  local layer=self.definition.document.layers[hit.layer]
  if not layer then return nil end
  local nearest=-1
  for key in pairs(layer.keys) do
    if key<=position and key>nearest then nearest=key end
  end
  for _,b in ipairs(self.definition.bindings) do
    if b.layer==hit.layer and b.frame==nearest and b.shape==hit.shape then
      return b.id
    end
  end
  return nil
end

local function matches(self,rule,event)
  if rule.event=="COLLIDE" and event.type=="collision" then
    return (rule.target==event.a and rule.other==event.b) or
           (rule.target==event.b and rule.other==event.a)
  end
  if rule.event=="CLICK" and event.clicked and event.hit then
    return rule.layer==event.hit.layer and rule.shape==event.hit.shape
  elseif rule.event=="CLICKID" and event.clicked and event.hit then
    local id=self:objectForHit(event.hit,event.frame or self.transport.position)
    return id~=nil and rule.target==id
  elseif rule.event=="KEY" and event.type=="keydown" then
    return (rule.target or rule.key)==event.key
  end
  return false
end
function S:dispatch(event)
  if not self.active or type(event)~="table" then return false end
  local consumed=false
  for _,rule in ipairs(self.definition.rules) do
    if matches(self,rule,event) and condition(self,rule.when) then
      consumed=true
      self.events=self.events+1
      local a=rule.action
      if a=="SCORE" then
        self.score=clamp(self.score+rule.value)
        self.lastAction=rule.value>0 and ("+"..rule.value.." pontos") or
          (rule.value.." pontos")
        if self.score>=self.definition.goal then
          self.won=true;self.active=false;self.transport.playing=false
          self.lastAction="Objetivo alcancado!"
        end
      elseif a=="SEEK" then
        self.transport:seek(rule.value)
        self.lastAction="Quadro "..rule.value
      elseif a=="PAUSE" then
        self.transport.playing=false
        self.lastAction="Pausado por regra"
      elseif a=="PLAY" then
        self.transport.playing=true
        self.lastAction="Reproduzindo por regra"
      elseif a=="ADD" or a=="SET" then
        local previous=self.states[rule.variable] or 0
        self.states[rule.variable]=clamp(a=="ADD" and previous+rule.value or rule.value)
        self.lastAction=rule.variable.." = "..self.states[rule.variable]
      end
    end
    if not self.active then break end
  end
  return consumed
end

-- Temporal collision sampling: for regular playback only, sample intermediate
-- positions instead of checking the final frame alone. The bounded budget limits
-- work for very high speed playback. Seeking stays instantaneous.
local function sweepSamples(first,last,total,wraps)
  local positions={}
  -- A numeric wrap count also detects complete loops that happen to finish
  -- at a frame greater than or equal to the starting frame.
  local distance=wraps>0 and (total*wraps+last-first)
    or math.max(0,last-first)
  local steps=math.max(1,math.min(MAX_SWEEP_STEPS,
    math.ceil(distance*SUBSTEPS_PER_FRAME)))
  local prior=first
  for i=1,steps do
    local advanced=first+distance*i/steps
    if wraps>0 and math.floor((advanced-1)/total)>math.floor((prior-1)/total) then
      positions[#positions+1]=1
    end
    local sample=wraps>0 and (((advanced-1)%total)+1) or advanced
    positions[#positions+1]=sample
    prior=advanced
  end
  return positions
end

local function intersects(self,pair,position,sampler,media,scene)
  local left=(media and media:shapeForObject(pair.a,position,scene)) or
    Collision.resolve(self.definition,pair.a,position,scene)
  local right=(media and media:shapeForObject(pair.b,position,scene)) or
    Collision.resolve(self.definition,pair.b,position,scene)
  if not left or not right or not Collision.overlap(left,right) then return false end
  if media and (media.bindingsById[pair.a] or media.bindingsById[pair.b]) then
    return media:collides(pair.a,pair.b,position,scene)
  end
  return true
end

-- previousPosition is supplied ONLY during automatic playback. A manual seek
-- passes nil, preventing false collisions along a teleport path.
-- wrapped is true only when the transport clock traversed its loop boundary.
function S:checkCollisions(sampler,media,previousPosition,wrapped)
  if not self.definition.version or self.definition.version<3 or not self.active then
    return false
  end
  if #self.collisionPairs==0 then return false end
  local currentPos=self.transport.position
  local positions
  local wraps=wrapped==true and 1 or
    (type(wrapped)=="number" and math.max(0,math.floor(wrapped)) or 0)
  if type(previousPosition)=="number" and previousPosition==previousPosition and
     previousPosition>=1 and previousPosition<=self.definition.document.totalFrames and
     (wraps>0 or currentPos>=previousPosition) then
    positions=sweepSamples(previousPosition,currentPos,
      self.definition.document.totalFrames,wraps)
  else
    positions={currentPos}
  end
  local any=false
  for _,position in ipairs(positions) do
    local scene=sampler and sampler:sample(position) or nil
    for _,pair in ipairs(self.collisionPairs) do
      local touching=intersects(self,pair,position,sampler,media,scene)
      local wasTouching=self.colliding[pair.key] or false
      if touching and not wasTouching then
        self.lastCollision={a=pair.a,b=pair.b}
        local triggered=self:dispatch({
          type="collision",a=pair.a,b=pair.b,frame=position
        })
        any=triggered or any
      end
      self.colliding[pair.key]=touching or nil
      if not self.active then return any end
    end
  end
  return any
end
return S
