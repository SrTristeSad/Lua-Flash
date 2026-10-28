-- Lua-Flash Player 0.16: bounded undo/redo snapshots of EDITABLE game data.
-- Excludes large binary PNG/WAV assets and the immutable scene document.
local H={}
H.__index=H
local LIMIT=32
local function clone(value)
  if type(value)~="table" then return value end
  local copy={}
  for k,v in pairs(value) do copy[k]=clone(v) end
  return copy
end
local function snapshot(g,track,selected)
  return {version=g.version,tweens=clone(g.tweens),easings=clone(g.easings),
    track=track or 1,selected=selected or 1}
end
function H.new(game)
  local self=setmetatable({game=game,past={},future={},saved=nil},H)
  self.saved=snapshot(game)
  return self
end
function H:begin(track,selected)
  return snapshot(self.game,track,selected)
end
function H:record(before)
  if not before then return false end
  local now=snapshot(self.game)
  -- A no-op (such as clicking a zero-delta drag) is not a history edit.
  local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
  end
  if before.version==now.version and same(before.tweens,now.tweens) and
     same(before.easings,now.easings) then return false end
  self.past[#self.past+1]=before
  if #self.past>LIMIT then table.remove(self.past,1) end
  self.future={}
  return true
end
local function restore(self,target)
  self.game.version=target.version
  self.game.tweens=clone(target.tweens)
  self.game.easings=clone(target.easings)
  return target.track,target.selected
end
function H:undo(track,selected)
  if #self.past==0 then return nil,"nothing to undo" end
  self.future[#self.future+1]=snapshot(self.game,track,selected)
  local target=table.remove(self.past)
  return restore(self,target)
end
function H:redo(track,selected)
  if #self.future==0 then return nil,"nothing to redo" end
  self.past[#self.past+1]=snapshot(self.game,track,selected)
  local target=table.remove(self.future)
  return restore(self,target)
end
function H:isDirty()
  local current=snapshot(self.game)
  local saved=self.saved
  local function same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
  end
  return current.version~=saved.version or
    not same(current.tweens,saved.tweens) or
    not same(current.easings,saved.easings)
end
function H:markSaved()
  self.saved=snapshot(self.game)
end
function H:reset(game)
  self.game=game
  self.past={}
  self.future={}
  self.saved=snapshot(game)
end
return H
