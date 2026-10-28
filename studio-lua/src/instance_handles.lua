-- Handles for editing Studio symbol instances directly with the mouse.
-- All positions are stage-space except the fixed-size screen-space hit radius.
local Transform=require("src.instance_transform")
local M={}
local function finite(v)
  return type(v)=="number" and v==v and math.abs(v)<math.huge
end
local function rotate(x,y,rad)
  local c,s=math.cos(rad),math.sin(rad)
  return c*x-s*y,s*x+c*y
end
function M.points(instance,symbol,frame,zoom)
  if not Transform.valid(instance) or not finite(zoom) or zoom<=0 then return nil end
  local x1,y1,x2,y2=Transform.symbolBounds(symbol,frame)
  if not x1 or x2-x1<1e-5 or y2-y1<1e-5 then return nil end
  local ax,ay=Transform.toWorld(instance,x1,y1)
  local bx,by=Transform.toWorld(instance,x2,y1)
  local cx,cy=Transform.toWorld(instance,x2,y2)
  local dx,dy=Transform.toWorld(instance,x1,y2)
  local vx,vy=bx-ax,by-ay
  local magnitude=math.sqrt(vx*vx+vy*vy)
  if magnitude<1e-5 then return nil end
  local normalX,normalY=vy/magnitude,-vx/magnitude
  -- Flipped vertical axis changes which side of the top edge is outward.
  if instance.sx*instance.sy<0 then normalX,normalY=-normalX,-normalY end
  local mx,my=(ax+bx)/2,(ay+by)/2
  local rx,ry=mx+normalX*(26/zoom),my+normalY*(26/zoom)
  return {tl={ax,ay},tr={bx,by},br={cx,cy},bl={dx,dy},
    rotate={rx,ry},pivot={(ax+cx)/2,(ay+cy)/2},
    localBounds={x1,y1,x2,y2}}
end
function M.hit(points,view,mx,my)
  if not points or not view or not view.scale then return nil end
  for _,kind in ipairs({"rotate","scale"}) do
    local pt=kind=="scale" and points.br or points.rotate
    local dx=mx-(view.ox+pt[1]*view.scale)
    local dy=my-(view.oy+pt[2]*view.scale)
    if dx*dx+dy*dy<=100 then return kind end
  end
  return nil
end
-- Return a new instance pose, keeping the opposite corner (resize) or center
-- (rotation) stationary. Invalid / inverted scales are rejected atomically.
function M.apply(initial,symbol,frame,zoom,kind,mouseX,mouseY,points)
  if not Transform.valid(initial) or not finite(mouseX) or not finite(mouseY) then
    return nil,"invalid pointer"
  end
  points=points or M.points(initial,symbol,frame,zoom)
  if not points then return nil,"no editable bounds" end
  local output={uid=initial.uid,symbolId=initial.symbolId,
    x=initial.x,y=initial.y,sx=initial.sx,sy=initial.sy,angle=initial.angle or 0}
  if kind=="scale" then
    local bounds=points.localBounds
    local width,height=bounds[3]-bounds[1],bounds[4]-bounds[2]
    local anchorX,anchorY=points.tl[1],points.tl[2]
    local rad=math.rad(initial.angle or 0)
    local qx,qy=rotate(mouseX-anchorX,mouseY-anchorY,-rad)
    local sx,sy=qx/width,qy/height
    if not finite(sx) or not finite(sy) or sx*initial.sx<=0 or sy*initial.sy<=0
        or math.abs(sx)<0.1 or math.abs(sy)<0.1
        or math.abs(sx)>20 or math.abs(sy)>20 then return nil,"scale limit" end
    local offX,offY=rotate(bounds[1]*sx,bounds[2]*sy,rad)
    output.sx,output.sy=sx,sy
    output.x,output.y=anchorX-offX,anchorY-offY
  elseif kind=="rotate" then
    local pivot=points.pivot
    local orig=points.rotate
    local a=math.atan2 and math.atan2(orig[2]-pivot[2],orig[1]-pivot[1])
      or math.atan(orig[2]-pivot[2],orig[1]-pivot[1])
    local b=math.atan2 and math.atan2(mouseY-pivot[2],mouseX-pivot[1])
      or math.atan(mouseY-pivot[2],mouseX-pivot[1])
    local rad=math.rad(initial.angle or 0)+(b-a)
    local x1,y1,x2,y2=points.localBounds[1],points.localBounds[2],
      points.localBounds[3],points.localBounds[4]
    local centerX,centerY=(x1+x2)/2,(y1+y2)/2
    local offX,offY=rotate(centerX*initial.sx,centerY*initial.sy,rad)
    output.angle=math.deg(rad)%360
    output.x,output.y=pivot[1]-offX,pivot[2]-offY
  else
    return nil,"unknown handle"
  end
  if not Transform.valid(output) or math.abs(output.x)>100000 or math.abs(output.y)>100000 then
    return nil,"position limit"
  end
  return output
end
return M
