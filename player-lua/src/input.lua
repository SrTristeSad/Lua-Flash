-- Lua-Flash Player 0.3: pure-Lua stage input and shape hit-testing.
-- No user-supplied Lua code is evaluated. Events are plain data.
local Model=require("src.model")
local Runtime=require("src.runtime")
local Input={}
Input.__index=Input

local function finite(n)
  return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
local function segmentDistanceSquared(x,y,ax,ay,bx,by)
  local dx,dy=bx-ax,by-ay
  local denom=dx*dx+dy*dy
  local t=denom>0 and math.max(0,math.min(1,((x-ax)*dx+(y-ay)*dy)/denom)) or 0
  local px,py=ax+t*dx,ay+t*dy
  return (x-px)^2+(y-py)^2
end

local function insideShape(shape,x,y)
  local p=shape.points
  if not p or #p<4 then return false end
  local x1,y1,x2,y2=Model.bounds(shape)
  local kind=shape.kind
  if kind=="rect" then
    return x>=x1 and x<=x2 and y>=y1 and y<=y2
  elseif kind=="ellipse" then
    local rx,ry=(x2-x1)/2,(y2-y1)/2
    if rx<=0 or ry<=0 then return false end
    local dx,dy=(x-(x1+rx))/rx,(y-(y1+ry))/ry
    return dx*dx+dy*dy<=1
  elseif kind=="line" or kind=="brush" then
    local tolerance=math.max(4,(shape.thickness or 2)*.5+3)
    local limit=tolerance*tolerance
    for i=1,#p-3,2 do
      if segmentDistanceSquared(x,y,p[i],p[i+1],p[i+2],p[i+3])<=limit then
        return true
      end
    end
    return false
  end
  return false
end

function Input.new()
  return setmetatable({pointers={},keys={}},Input)
end

function Input.stagePoint(wx,wy,doc,viewport)
  if not finite(wx) or not finite(wy) or not viewport or
     viewport.w<=0 or viewport.h<=0 or doc.width<=0 or doc.height<=0 then return nil end
  local ox,oy,scale=Runtime.geometry(doc,viewport.x,viewport.y,viewport.w,viewport.h)
  local x,y=(wx-ox)/scale,(wy-oy)/scale
  if x<0 or y<0 or x>doc.width or y>doc.height then return nil end
  return x,y
end

function Input.hitTest(doc,frame,x,y,sampler)
  if not finite(x) or not finite(y) or x<0 or y<0 or x>doc.width or y>doc.height then return nil end
  local target=sampler and sampler:sample(frame) or doc
  for layerIndex=#target.layers,1,-1 do
    local layer=target.layers[layerIndex]
    if layer.visible then
      local shapes=Model.frame(layer,sampler and 1 or math.floor(frame))
      for shapeIndex=#shapes,1,-1 do
        if insideShape(shapes[shapeIndex],x,y) then
          return {layer=layerIndex,shape=shapeIndex,kind=shapes[shapeIndex].kind}
        end
      end
    end
  end
  return nil
end

local function sameTarget(a,b)
  if not a and not b then return true end -- valid click on empty stage
  return a and b and a.layer==b.layer and a.shape==b.shape
end

-- phase: "down", "move", "up" or "cancel".
-- identifier is mouse number or LÖVE touch ID; source separates them.
function Input:pointer(phase,source,identifier,wx,wy,doc,frame,viewport,sampler)
  local x,y=Input.stagePoint(wx,wy,doc,viewport)
  -- Pointer moves only need coordinates: avoid allocating a tweened scene each mousemove.
  local target=(phase=="down" or phase=="up") and x and Input.hitTest(doc,frame,x,y,sampler) or nil
  local event={
    type="pointer"..phase, source=source, id=identifier,
    x=x,y=y, inside=x~=nil, hit=target, clicked=false
  }
  local key=source..":"..tostring(identifier)
  if phase=="down" then
    if x then self.pointers[key]={x=x,y=y,hit=target} end
  elseif phase=="up" then
    local initial=self.pointers[key]
    if initial and x and sameTarget(initial.hit,target) then
      local dx,dy=x-initial.x,y-initial.y
      event.clicked=dx*dx+dy*dy<=24*24
    end
    self.pointers[key]=nil
  elseif phase=="cancel" then
    self.pointers[key]=nil
  end
  return event
end

function Input:key(phase,key)
  if phase=="down" then self.keys[key]=true
  elseif phase=="up" then self.keys[key]=nil end
  return {type="key"..phase,key=key}
end

function Input:reset()
  self.pointers={}
  self.keys={}
end

return Input
