-- Visual-only tweening for native .lflash projects.
-- Only compatible shapes at matching indices between adjacent keyframes are blended.
-- The authoring document and keyframe data remain unchanged.
local Model=require("src.model")
local I={}
I.__index=I

local function lerp(a,b,t) return a+(b-a)*t end

local function mixShape(a,b,t)
  if a.kind~=b.kind or #a.points~=#b.points then return a end
  local points,color={},{}
  for i=1,#a.points do
    points[i]=lerp(a.points[i],b.points[i],t)
  end
  for i=1,math.max(#a.color,#b.color) do
    color[i]=lerp(a.color[i] or 1,b.color[i] or 1,t)
  end
  return {
    kind=a.kind,points=points,color=color,
    thickness=lerp(a.thickness or 2,b.thickness or 2,t)
  }
end

-- Segment compatibility is immutable for a loaded document. Evaluate once
-- per key pair rather than comparing every vector on every sampled frame.
local function compatible(a,b)
  if #a~=#b then return false end
  for i,shape in ipairs(a) do
    local nextShape=b[i]
    if shape.kind~=nextShape.kind or #shape.points~=#nextShape.points then
      return false
    end
  end
  return true
end

function I.new(doc)
  local self=setmetatable({
    doc=doc,keys={},segments={},cachePosition=nil,cacheScene=nil,
    computations=0,compatibilityChecks=0,blended=0
  },I)
  self:reindex()
  return self
end

function I:reindex()
  self.keys={}
  self.segments={}
  for i,layer in ipairs(self.doc.layers) do
    local indices={}
    for frame in pairs(layer.keys) do indices[#indices+1]=frame end
    table.sort(indices)
    self.keys[i]=indices
    local segment={}
    for index=1,#indices-1 do
      local from,to=indices[index],indices[index+1]
      segment[from]=compatible(layer.keys[from],layer.keys[to])
      self.compatibilityChecks=self.compatibilityChecks+1
    end
    self.segments[i]=segment
  end
  self.cachePosition=nil
  self.cacheScene=nil
end

function I:sample(position)
  local doc=self.doc
  position=math.max(1,math.min(doc.totalFrames,position))
  if self.cachePosition==position then return self.cacheScene end
  self.computations=self.computations+1
  local sampled={
    width=doc.width,height=doc.height, layers={}
  }
  for i,layer in ipairs(doc.layers) do
    local indices=self.keys[i]
    -- Find adjacent keys in O(log K) rather than scanning every key on
    -- each of many temporal collision samples.
    local lo,hi=1,#indices
    while lo<=hi do
      local middle=math.floor((lo+hi)/2)
      if indices[middle]<=position then lo=middle+1
      else hi=middle-1 end
    end
    local previous=hi>=1 and indices[hi] or nil
    local nextKey=lo<=#indices and indices[lo] or nil
    local shapes=previous and layer.keys[previous] or {}
    local output=shapes
    if previous and nextKey and position>previous then
      local dest=layer.keys[nextKey]
      -- Compatibility was checked once when building the segment index.
      -- A mismatched shape list still holds the preceding key unchanged.
      if self.segments[i][previous] then
        local t=(position-previous)/(nextKey-previous)
        output={}
        for j,s in ipairs(shapes) do
          output[j]=mixShape(s,dest[j],t)
          self.blended=self.blended+1
        end
      end
    end
    sampled.layers[i]={
      visible=layer.visible,
      keys={[1]=output}
    }
  end
  self.cachePosition=position
  self.cacheScene=sampled
  return sampled
end

function I:draw(position,x,y,w,h)
  local Runtime=require("src.runtime")
  return Runtime.draw(self:sample(position),1,x,y,w,h)
end

return I
