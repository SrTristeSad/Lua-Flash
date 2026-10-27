-- Built-in Lua-Flash mini-game. No arbitrary scripts from imported files.
local G={}
G.__index=G
function G.new()
  return setmetatable({score=0,misses=0,remaining=30,active=true,
    reticleX=400,reticleY=225},G)
end
function G:update(dt,playing)
  if not self.active or not playing or type(dt)~="number" or dt<=0 then return end
  self.remaining=math.max(0,self.remaining-math.min(dt,.25))
  if self.remaining==0 then self.active=false end
end
function G:moveReticle(dx,dy,doc)
  self.reticleX=math.max(0,math.min(doc.width,self.reticleX+dx))
  self.reticleY=math.max(0,math.min(doc.height,self.reticleY+dy))
end
function G:setReticle(x,y)
  self.reticleX,self.reticleY=x,y
end
function G:attempt(hit)
  if not self.active then return false end
  if hit and hit.layer==2 then
    self.score=self.score+1
    return true
  end
  self.misses=self.misses+1
  return false
end
return G
