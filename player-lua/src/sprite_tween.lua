-- Player 0.13: pure-Lua sprite transform tweening in timeline coordinates.
-- Position key values are stage offsets added to the existing STATIC/FOLLOW base.
-- Angles and scales are absolute; pivot comes from the v7 transform (or center).
local Tween={}
Tween.__index=Tween
local function between(a,b,t)
  return a+(b-a)*t
end
local function ease(mode,t)
  if mode=="STEP" then return 0 end
  if mode=="EASE_IN" then return t*t end
  if mode=="EASE_OUT" then return 1-(1-t)*(1-t) end
  if mode=="EASE_IN_OUT" then
    if t<.5 then return 2*t*t end
    return 1-2*(1-t)*(1-t)
  end
  if mode=="SMOOTH" then return t*t*(3-2*t) end
  return t
end
local function shortestAngle(a,b,t)
  local delta=((b-a+180)%360)-180
  return a+delta*t
end
function Tween.new(definition)
  local tracks={}
  for _,track in ipairs(definition.tweens or {}) do tracks[track.index]=track.keys end
  local curves={}
  for _,entry in ipairs(definition.easings or {}) do
    curves[entry.index..":"..entry.frame]=entry.mode
  end
  return setmetatable({tracks=tracks,curves=curves,cache={}},Tween)
end
function Tween:sample(index,position)
  local keys=self.tracks[index]
  if not keys then return nil end
  local saved=self.cache[index]
  if saved and saved.position==position then return saved.result end
  local first,last=keys[1],keys[#keys]
  local out
  if position<=first.frame then
    out={x=first.x,y=first.y,angle=first.angle,
      scaleX=first.scaleX,scaleY=first.scaleY}
  elseif position>=last.frame then
    out={x=last.x,y=last.y,angle=last.angle,
      scaleX=last.scaleX,scaleY=last.scaleY}
  else
    -- Binary search: find the active pair even with 128 keyframes.
    local lo,hi=1,#keys-1
    while lo<hi do
      local m=math.floor((lo+hi+1)/2)
      if keys[m].frame<=position then lo=m else hi=m-1 end
    end
    local a,b=keys[lo],keys[lo+1]
    local t=(position-a.frame)/(b.frame-a.frame)
    t=ease(self.curves[index..":"..a.frame] or "LINEAR",t)
    out={
      x=between(a.x,b.x,t),y=between(a.y,b.y,t),
      angle=shortestAngle(a.angle,b.angle,t),
      scaleX=between(a.scaleX,b.scaleX,t),
      scaleY=between(a.scaleY,b.scaleY,t)
    }
  end
  self.cache[index]={position=position,result=out}
  return out
end
return Tween
