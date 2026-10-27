-- Lua-Flash Player: independent timeline transport.
-- Position is a 1-based fractional frame. It never changes the source document.
local T={}
T.__index=T
local speeds={0.25,0.5,0.75,1,1.25,1.5,2,3,4}

function T.new(doc)
  assert(type(doc)=="table" and type(doc.totalFrames)=="number" and doc.totalFrames>=1)
  return setmetatable({
    doc=doc,position=1,playing=false,loop=true,speed=1
  },T)
end

function T:frame()
  return math.min(self.doc.totalFrames,math.max(1,math.floor(self.position)))
end

function T:progress()
  if self.doc.totalFrames<=1 then return 0 end
  return (self.position-1)/(self.doc.totalFrames-1)
end

function T:seek(position)
  if type(position)~="number" or position~=position then return self:frame() end
  self.position=math.max(1,math.min(self.doc.totalFrames,position))
  return self:frame()
end

function T:seekProgress(progress)
  if type(progress)~="number" or progress~=progress then return self:frame() end
  progress=math.max(0,math.min(1,progress))
  return self:seek(1+(self.doc.totalFrames-1)*progress)
end

function T:step(delta)
  self.playing=false
  return self:seek(self:frame()+delta)
end

function T:toggle()
  self.playing=not self.playing
  if self.playing and not self.loop and self.position>=self.doc.totalFrames then
    self.position=1
  end
  return self.playing
end

function T:setSpeed(n)
  if type(n)=="number" and n==n and n>=.25 and n<=4 then self.speed=n end
  return self.speed
end

function T:cycleSpeed(direction)
  local bestIndex=1
  local closest=math.huge
  for i,value in ipairs(speeds) do
    local diff=math.abs(self.speed-value)
    if diff<closest then closest=diff; bestIndex=i end
  end
  local index=math.max(1,math.min(#speeds,bestIndex+direction))
  self.speed=speeds[index]
  return self.speed
end

function T:update(dt)
  if not self.playing or type(dt)~="number" or dt~=dt or dt<=0 then return end
  -- Do not fast-forward by several seconds after a minimized/backgrounded window.
  dt=math.min(dt,0.25)
  local frames=self.doc.totalFrames
  if frames==1 then
    if not self.loop then self.playing=false end
    return
  end
  local nextPosition=self.position+dt*self.doc.fps*self.speed
  if self.loop then
    self.position=((nextPosition-1)%frames)+1
  elseif nextPosition>=frames+1 then
    self.position=frames
    self.playing=false
  else
    self.position=nextPosition
  end
end

return T
