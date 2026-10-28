-- Lua-Flash Player 0.17: bounded runtime diagnostics, independent of graphics.
local D={}
D.__index=D
function D.new()
  return setmetatable({samples=0,elapsed=0,frames=0,worstDt=0,
    avgFPS=0,peakMemoryKB=0,lastMemoryKB=0},D)
end
function D:update(dt)
  if type(dt)~="number" or dt~=dt or dt<0 or dt>10 then return end
  self.samples=self.samples+1
  self.frames=self.frames+1
  self.elapsed=self.elapsed+dt
  self.worstDt=math.max(self.worstDt,dt)
  if self.elapsed>=1 then
    self.avgFPS=self.elapsed>0 and self.frames/self.elapsed or 0
    self.elapsed=0;self.frames=0
  end
  -- Avoid collecting garbage: this is a read-only diagnostic.
  if self.samples%30==0 then
    self.lastMemoryKB=collectgarbage("count")
    self.peakMemoryKB=math.max(self.peakMemoryKB,self.lastMemoryKB)
  end
end
function D:snapshot(game,media,session)
  local tracks,keys,resources=0,0,0
  if game then
    tracks=#(game.tweens or {})
    for _,track in ipairs(game.tweens or {}) do keys=keys+#track.keys end
    resources=#(game.resources or {})
  end
  return {fps=self.avgFPS,memoryKB=collectgarbage("count"),
    worstMs=self.worstDt*1000,tracks=tracks,keys=keys,
    resources=resources,maskBuilds=media and media.maskBuilds or 0,
    collisionPairs=session and #(session.collisionPairs or {}) or 0}
end
return D
