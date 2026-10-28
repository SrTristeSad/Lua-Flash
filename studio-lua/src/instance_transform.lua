-- Coordinate geometry for Studio symbol instances, independent of LÖVE.
-- The instance origin is the symbol's (0,0); angle is stored in degrees.
local Model=require("src.model")
local Vector=require("src.vector_paths")
local M={}
local function numeric(n) return type(n)=="number" and n==n and math.abs(n)<math.huge end
function M.valid(instance)
  return type(instance)=="table" and numeric(instance.x) and numeric(instance.y)
    and numeric(instance.sx) and numeric(instance.sy)
    and instance.sx~=0 and instance.sy~=0
    and numeric(instance.angle or 0)
end
function M.toWorld(instance,x,y)
  local rad=math.rad(instance.angle or 0)
  local c,s=math.cos(rad),math.sin(rad)
  local a,b=x*instance.sx,y*instance.sy
  return instance.x+a*c-b*s,instance.y+a*s+b*c
end
function M.toLocal(instance,x,y)
  local rad=math.rad(instance.angle or 0)
  local c,s=math.cos(rad),math.sin(rad)
  local dx,dy=x-instance.x,y-instance.y
  return (dx*c+dy*s)/instance.sx,(-dx*s+dy*c)/instance.sy
end
function M.symbolBounds(symbol,frame,vectorScope)
  if not symbol or not symbol.definition then return nil end
  local x1,y1,x2,y2
  for _,layer in ipairs(symbol.definition.layers) do
    if layer.visible then
      for _,shape in ipairs(Model.frame(layer,frame or 1)) do
        local a,b,c,d=Model.bounds(shape)
        if a and b and c and d then
          x1=x1 and math.min(x1,a) or a
          y1=y1 and math.min(y1,b) or b
          x2=x2 and math.max(x2,c) or c
          y2=y2 and math.max(y2,d) or d
        end
      end
    end
  end
  if vectorScope then
    for layerIndex,layer in ipairs(symbol.definition.layers) do
      if layer.visible then
        for _,path in ipairs(Vector.at(vectorScope,layerIndex,frame or 1)) do
          local a,b,c,d=Vector.bounds(path)
          if a then
            x1=x1 and math.min(x1,a) or a
            y1=y1 and math.min(y1,b) or b
            x2=x2 and math.max(x2,c) or c
            y2=y2 and math.max(y2,d) or d
          end
        end
      end
    end
  end
  if not x1 then return nil end
  return x1,y1,x2,y2
end
function M.box(instance,symbol,frame,vectorScope)
  if not M.valid(instance) then return nil end
  local x1,y1,x2,y2=M.symbolBounds(symbol,frame,vectorScope)
  if not x1 then return nil end
  local left,top,right,bottom
  for _,point in ipairs({{x1,y1},{x2,y1},{x2,y2},{x1,y2}}) do
    local x,y=M.toWorld(instance,point[1],point[2])
    left=left and math.min(left,x) or x
    top=top and math.min(top,y) or y
    right=right and math.max(right,x) or x
    bottom=bottom and math.max(bottom,y) or y
  end
  return left,top,right,bottom
end
function M.hit(instance,symbol,frame,x,y,vectorScope)
  if not M.valid(instance) then return false end
  local x1,y1,x2,y2=M.symbolBounds(symbol,frame,vectorScope)
  if not x1 then return false end
  local lx,ly=M.toLocal(instance,x,y)
  -- Fallback for zero-width/height strokes.
  return lx>=x1-3 and lx<=x2+3 and ly>=y1-3 and ly<=y2+3
end
function M.adjust(instance,dx,dy,scaleFactor,rotation)
  if not M.valid(instance) or not numeric(dx) or not numeric(dy)
      or not numeric(scaleFactor) or scaleFactor<=0 or not numeric(rotation) then
    return false
  end
  local sx,sy=instance.sx*scaleFactor,instance.sy*scaleFactor
  if math.abs(sx)<0.1 or math.abs(sy)<0.1
      or math.abs(sx)>20 or math.abs(sy)>20 then return false end
  local x,y=instance.x+dx,instance.y+dy
  if math.abs(x)>100000 or math.abs(y)>100000 then return false end
  instance.x,instance.y=x,y
  instance.sx,instance.sy=sx,sy
  instance.angle=((instance.angle or 0)+rotation)%360
  return true
end
return M
