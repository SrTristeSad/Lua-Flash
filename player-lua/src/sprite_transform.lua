-- Lua-Flash 0.12: sprite geometry with scale, rotation and normalized pivot.
-- All math is in native stage coordinates (LÖVE positive rotation is clockwise on screen).
local T={}
local rad=math.pi/180
local function xy(rect)
  local p=rect.points
  return p[1],p[2],p[3]-p[1],p[4]-p[2]
end
function T.build(rect,transform)
  if not transform then return rect end
  local x,y,w,h=xy(rect)
  local px,py=transform.pivotX/100,transform.pivotY/100
  local sx,sy=transform.scaleX/100,transform.scaleY/100
  local a=transform.angle*rad
  local co,si=math.cos(a),math.sin(a)
  local ox,oy=x+w*px,y+h*py
  local shape={kind="rect",transformed=true,
    originX=ox,originY=oy,w=w,h=h,px=px,py=py,
    sx=sx,sy=sy,co=co,si=si,angle=a}
  local minX,minY,maxX,maxY=math.huge,math.huge,-math.huge,-math.huge
  for _,u in ipairs({0,1}) do
    for _,v in ipairs({0,1}) do
      local dx,dy=(u-px)*w*sx,(v-py)*h*sy
      local wx,wy=ox+dx*co-dy*si,oy+dx*si+dy*co
      minX=math.min(minX,wx);maxX=math.max(maxX,wx)
      minY=math.min(minY,wy);maxY=math.max(maxY,wy)
    end
  end
  shape.points={minX,minY,maxX,maxY}
  return shape
end
function T.toWorld(shape,u,v)
  if not shape.transformed then
    local p=shape.points
    return p[1]+u*(p[3]-p[1]),p[2]+v*(p[4]-p[2])
  end
  local dx=(u-shape.px)*shape.w*shape.sx
  local dy=(v-shape.py)*shape.h*shape.sy
  return shape.originX+dx*shape.co-dy*shape.si,
    shape.originY+dx*shape.si+dy*shape.co
end
function T.toUV(shape,x,y)
  if not shape.transformed then
    local p=shape.points
    return (x-p[1])/(p[3]-p[1]),(y-p[2])/(p[4]-p[2])
  end
  local dx,dy=x-shape.originX,y-shape.originY
  return (dx*shape.co+dy*shape.si)/(shape.w*shape.sx)+shape.px,
    (-dx*shape.si+dy*shape.co)/(shape.h*shape.sy)+shape.py
end
function T.contains(shape,mask,x,y)
  local u,v=T.toUV(shape,x,y)
  if not u or not v or u<0 or u>=1 or v<0 or v>=1 then return false end
  if not mask then return true end
  if mask.empty then return false end
  if mask.opaque then return true end
  local col=math.floor(u*mask.w)+1
  local row=math.floor(v*mask.h)+1
  return mask.rows[row]:byte(col)==1
end
function T.draw(image,shape)
  if not shape.transformed then
    local p=shape.points
    love.graphics.draw(image,p[1],p[2],0,
      (p[3]-p[1])/image:getWidth(),(p[4]-p[2])/image:getHeight())
    return
  end
  love.graphics.draw(image,shape.originX,shape.originY,shape.angle,
    shape.w*shape.sx/image:getWidth(),shape.h*shape.sy/image:getHeight(),
    shape.px*image:getWidth(),shape.py*image:getHeight())
end
-- Sample opaque source pixel centers projected through the transformation.
-- Bounded to 65536 checks per pair; this is not exact continuous collision detection.
function T.intersects(shapeA,maskA,shapeB,maskB,containsB)
  local pa,pb=shapeA.points,shapeB.points
  if pa[3]<pb[1] or pb[3]<pa[1] or pa[4]<pb[2] or pb[4]<pa[2] then return false end
  local countA=maskA and maskA.w*maskA.h or 1024
  local w,h=maskA and maskA.w or 32,maskA and maskA.h or 32
  local step=math.max(1,math.ceil(math.sqrt(countA/65536)))
  for row=0,h-1,step do
    for col=0,w-1,step do
      local u,v=(col+0.5)/w,(row+0.5)/h
      local opaque=not maskA or not maskA.empty and
        (maskA.opaque or maskA.rows[row+1]:byte(col+1)==1)
      if opaque then
        local x,y=T.toWorld(shapeA,u,v)
        if containsB(x,y) then return true end
      end
    end
  end
  return false
end
return T
