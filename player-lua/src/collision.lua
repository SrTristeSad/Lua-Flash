-- Lua-Flash Player 0.6: frame-aware object bindings and collision geometry.
-- The author binds an object ID explicitly to a shape at each relevant keyframe.
-- Binding is independent of shape index across DIFFERENT keyframes.
local Model=require("src.model")
local Collision={}
local function finite(x)
  return type(x)=="number" and x==x and math.abs(x)<math.huge
end

function Collision.resolve(definition,id,position,scene)
  local doc=definition.document
  if not finite(position) then return nil end
  for _,binding in ipairs(definition.bindings or {}) do
    if binding.id==id then
      local layer=doc.layers[binding.layer]
      if layer then
        local nearest=-1
        for key in pairs(layer.keys) do
          if key<=position and key>nearest then nearest=key end
        end
        if nearest==binding.frame then
          local outputLayer=scene and scene.layers[binding.layer] or layer
          local shapes=scene and Model.frame(outputLayer,1) or Model.frame(layer,position)
          return shapes[binding.shape],binding
        end
      end
    end
  end
  return nil
end

local function bounds(s)
  if type(s)~="table" or type(s.points)~="table" or #s.points<4 then return nil end
  local a,b,c,d=Model.bounds(s)
  if not(finite(a) and finite(b) and finite(c) and finite(d)) then return nil end
  return a,b,c,d
end

local function ellipseEllipse(a,b)
  -- Conservative normalized separation, with exact check for circular objects.
  local ax1,ay1,ax2,ay2=bounds(a)
  local bx1,by1,bx2,by2=bounds(b)
  local arx,ary=(ax2-ax1)/2,(ay2-ay1)/2
  local brx,bry=(bx2-bx1)/2,(by2-by1)/2
  if arx<=0 or ary<=0 or brx<=0 or bry<=0 then return false end
  local dx=math.abs((ax1+ax2)/2-(bx1+bx2)/2)
  local dy=math.abs((ay1+ay2)/2-(by1+by2)/2)
  -- No false negatives for circles, conservative for ellipses.
  return (dx/(arx+brx))^2+(dy/(ary+bry))^2<=1
end

local function rectangleEllipse(rect,ellipse)
  local x1,y1,x2,y2=bounds(rect)
  local a,b,c,d=bounds(ellipse)
  local rx,ry=(c-a)/2,(d-b)/2
  if rx<=0 or ry<=0 then return false end
  local cx,cy=(a+c)/2,(b+d)/2
  local nx=math.max(x1,math.min(cx,x2))
  local ny=math.max(y1,math.min(cy,y2))
  return ((nx-cx)/rx)^2+((ny-cy)/ry)^2<=1
end

function Collision.overlap(a,b)
  local ax1,ay1,ax2,ay2=bounds(a)
  local bx1,by1,bx2,by2=bounds(b)
  if not ax1 or not bx1 or ax2<bx1 or bx2<ax1 or ay2<by1 or by2<ay1 then return false end
  if a.kind=="ellipse" and b.kind=="ellipse" then return ellipseEllipse(a,b) end
  if a.kind=="rect" and b.kind=="ellipse" then return rectangleEllipse(a,b) end
  if a.kind=="ellipse" and b.kind=="rect" then return rectangleEllipse(b,a) end
  -- Line/brush pairs use AABB broad-phase collision for now.
  return true
end

return Collision
