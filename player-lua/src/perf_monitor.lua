-- Player 0.27: bounded CPU instrumentation for update and draw callbacks.
-- The sample windows use a fixed 120-frame ring per channel (no unbounded log).
local P={}
P.__index=P
local VALID={update=true,draw=true}
local LIMIT=120
local function clock()
  if love and love.timer and type(love.timer.getTime)=="function" then
    return love.timer.getTime()
  end
  return os.clock()
end
function P.new(source)
  return setmetatable({source=source or clock,channels={}},P)
end
function P:time()
  local ok,stamp=pcall(self.source)
  return ok and type(stamp)=="number" and stamp or nil
end
function P:record(channel,duration)
  if not VALID[channel] or type(duration)~="number" or duration~=duration
      or duration<0 or duration==math.huge then return false end
  -- Ignore pathological wall-time jumps, or background/suspended events.
  duration=math.min(duration,1)
  local ch=self.channels[channel]
  if not ch then
    ch={values={},next=1,count=0,sum=0,peak=0,total=0}
    self.channels[channel]=ch
  end
  local previous=ch.values[ch.next] or 0
  ch.sum=ch.sum-previous+duration
  ch.values[ch.next]=duration
  ch.next=ch.next%LIMIT+1
  ch.count=math.min(LIMIT,ch.count+1)
  ch.total=ch.total+1
  if duration>ch.peak then ch.peak=duration end
  return true
end
function P:measure(channel,beginTime)
  local now=self:time()
  if not now or not beginTime then return false end
  return self:record(channel,now-beginTime)
end
function P:stats(channel)
  local ch=self.channels[channel]
  if not ch then return {avgMs=0,maxMs=0,samples=0,total=0} end
  local max=0
  for _,v in ipairs(ch.values) do
    if v>max then max=v end
  end
  return {avgMs=ch.count>0 and ch.sum/ch.count*1000 or 0,
    maxMs=max*1000,samples=ch.count,total=ch.total}
end
function P:reset()
  self.channels={}
end
return P
