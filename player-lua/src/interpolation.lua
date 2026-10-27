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

function I.new(doc)
  local keys={}
  for i,layer in ipairs(doc.layers) do
    local indices={}
    for frame in pairs(layer.keys) do indices[#indices+1]=frame end
    table.sort(indices)
    keys[i]=indices
  end
  return setmetatable({doc=doc,keys=keys},I)
end

function I:sample(position)
  local doc=self.doc
  position=math.max(1,math.min(doc.totalFrames,position))
  local sampled={
    width=doc.width,height=doc.height, layers={}
  }
  for i,layer in ipairs(doc.layers) do
    local indices=self.keys[i]
    local previous,nextKey
    for _,frame in ipairs(indices) do
      if frame<=position then previous=frame else nextKey=frame;break end
    end
    local shapes=previous and layer.keys[previous] or {}
    local output=shapes
    if previous and nextKey and position>previous then
      local dest=layer.keys[nextKey]
      -- Blend only an entire compatible shape list to avoid accidental morphs
      -- when objects appear, disappear or change type.
      local compatible=#shapes==#dest
      if compatible then
        for j,a in ipairs(shapes) do
          if a.kind~=dest[j].kind or #a.points~=#dest[j].points then
            compatible=false
            break
          end
        end
      end
      if compatible then
        local t=(position-previous)/(nextKey-previous)
        output={}
        for j,s in ipairs(shapes) do
          output[j]=mixShape(s,dest[j],t)
        end
      end
    end
    sampled.layers[i]={
      visible=layer.visible,
      keys={[1]=output}
    }
  end
  return sampled
end

function I:draw(position,x,y,w,h)
  local Runtime=require("src.runtime")
  return Runtime.draw(self:sample(position),1,x,y,w,h)
end

return I
