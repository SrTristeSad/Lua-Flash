-- Lua-Flash Player 0.27: indexed, bounded exact-frame vector scene cache.
-- Does not modify the shared Studio renderer or the source document.
local R={}
R.__index=R
local Model=require("src.model")
local Runtime=require("src.runtime")
local function keysOf(layer)
  local indices={}
  for frame in pairs(layer.keys or {}) do
    indices[#indices+1]=frame
  end
  table.sort(indices)
  return indices
end
local function latest(indices,frame)
  local lo,hi=1,#indices
  while lo<=hi do
    local mid=math.floor((lo+hi)/2)
    if indices[mid]<=frame then lo=mid+1 else hi=mid-1 end
  end
  return hi>=1 and indices[hi] or nil
end
function R.new(document)
  assert(document and document.layers and document.totalFrames)
  local self=setmetatable({
    document=document,indices={},cachedFrame=nil,cachedScene=nil,
    searches=0,rebuilds=0,reused=0
  },R)
  self:reindex()
  return self
end
function R:reindex()
  self.indices={}
  for i,layer in ipairs(self.document.layers) do
    self.indices[i]=keysOf(layer)
  end
  self.cachedScene=nil
  self.cachedFrame=nil
end
function R:scene(frame)
  local document=self.document
  frame=math.max(1,math.min(document.totalFrames,math.floor(frame)))
  if frame==self.cachedFrame then
    self.reused=self.reused+1
    return self.cachedScene
  end
  local layers={}
  for i,layer in ipairs(document.layers) do
    local key=latest(self.indices[i],frame)
    self.searches=self.searches+1
    layers[i]={visible=layer.visible,keys={[1]=key and layer.keys[key] or {}}}
  end
  local scene={width=document.width,height=document.height,layers=layers}
  self.cachedScene=scene
  self.cachedFrame=frame
  self.rebuilds=self.rebuilds+1
  return scene
end
function R:draw(frame,x,y,w,h)
  return Runtime.draw(self:scene(frame),1,x,y,w,h)
end
function R:stats()
  return {searches=self.searches,rebuilds=self.rebuilds,
    reused=self.reused,frame=self.cachedFrame or 0}
end
return R
