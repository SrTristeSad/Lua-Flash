-- Lua-Flash Player 0.10: compact PNG alpha masks and bounded collision scanning.
-- Masks are created lazily once per decoded image, never per frame.
local A={}
local THRESHOLD=0.10
local SAMPLE_BUDGET=65536

function A.build(imageData)
  local w,h=imageData:getWidth(),imageData:getHeight()
  assert(w>0 and h>0 and w<=1024 and h<=1024,"invalid mask dimensions")
  local rows,opaque,empty={},true,true
  for y=0,h-1 do
    local pixels={}
    for x=0,w-1 do
      local _,_,_,alpha=imageData:getPixel(x,y)
      local isSolid=alpha>=THRESHOLD
      pixels[#pixels+1]=isSolid and "\1" or "\0"
      if isSolid then empty=false else opaque=false end
    end
    rows[y+1]=table.concat(pixels)
  end
  return {w=w,h=h,rows=rows,opaque=opaque,empty=empty}
end

function A.contains(mask,rect,x,y)
  local p=rect.points
  local w,h=p[3]-p[1],p[4]-p[2]
  if w<=0 or h<=0 or x<p[1] or x>=p[3] or y<p[2] or y>=p[4] then return false end
  if mask==nil then return true end -- old mock environments without love.image
  if mask.empty then return false end
  if mask.opaque then return true end
  local col=math.floor((x-p[1])*mask.w/w)+1
  local row=math.floor((y-p[2])*mask.h/h)+1
  return mask.rows[row]:byte(col)==1
end

function A.shapeContains(shape,x,y)
  local p=shape.points
  if not p or #p<4 then return false end
  local x1,y1,x2,y2=p[1],p[2],p[3],p[4]
  if shape.kind=="rect" then
    x1,y1,x2,y2=math.min(x1,x2),math.min(y1,y2),math.max(x1,x2),math.max(y1,y2)
    return x>=x1 and x<=x2 and y>=y1 and y<=y2
  elseif shape.kind=="ellipse" then
    x1,y1,x2,y2=math.min(x1,x2),math.min(y1,y2),math.max(x1,x2),math.max(y1,y2)
    local rx,ry=(x2-x1)/2,(y2-y1)/2
    if rx==0 or ry==0 then return false end
    local cx,cy=x1+rx,y1+ry
    return ((x-cx)/rx)^2+((y-cy)/ry)^2<=1
  end
  -- Previous approximate collision behavior for line/brush strokes.
  local minX,maxX,minY,maxY=p[1],p[1],p[2],p[2]
  for i=3,#p,2 do
    minX=math.min(minX,p[i]);maxX=math.max(maxX,p[i])
    minY=math.min(minY,p[i+1]);maxY=math.max(maxY,p[i+1])
  end
  return x>=minX and x<=maxX and y>=minY and y<=maxY
end

local function intersection(a,b)
  local x1=math.max(a.points[1],b.points[1])
  local y1=math.max(a.points[2],b.points[2])
  local x2=math.min(a.points[3],b.points[3])
  local y2=math.min(a.points[4],b.points[4])
  if x1>=x2 or y1>=y2 then return nil end
  return x1,y1,x2,y2
end

-- Evaluate opaque source-pixel centers in the intersecting region, bounded to
-- a per-pair budget. Extremely large overlaps use deterministic sparse sampling.
function A.scan(mask,rect,x1,y1,x2,y2,predicate)
  if mask.empty then return false end
  local p=rect.points
  local dx,dy=(p[3]-p[1])/mask.w,(p[4]-p[2])/mask.h
  if dx<=0 or dy<=0 then return false end
  local fromX=math.max(0,math.ceil((x1-p[1])/dx-0.5))
  local fromY=math.max(0,math.ceil((y1-p[2])/dy-0.5))
  local toX=math.min(mask.w-1,math.floor((x2-p[1])/dx-0.5))
  local toY=math.min(mask.h-1,math.floor((y2-p[2])/dy-0.5))
  if toX<fromX or toY<fromY then return false end
  local count=(toX-fromX+1)*(toY-fromY+1)
  local step=math.max(1,math.ceil(math.sqrt(count/SAMPLE_BUDGET)))
  for y=fromY,toY,step do
    local row=mask.rows[y+1]
    for x=fromX,toX,step do
      if row:byte(x+1)==1 then
        local wx=p[1]+(x+0.5)*dx
        local wy=p[2]+(y+0.5)*dy
        if predicate(wx,wy) then return true end
      end
    end
  end
  return false
end

function A.overlap(maskA,rectA,maskB,rectB)
  local x1,y1,x2,y2=intersection(rectA,rectB)
  if not x1 then return false end
  if maskA and maskA.empty or maskB and maskB.empty then return false end
  if (not maskA or maskA.opaque) and (not maskB or maskB.opaque) then return true end
  if maskA and not maskA.opaque then
    return A.scan(maskA,rectA,x1,y1,x2,y2,
      function(x,y) return A.contains(maskB,rectB,x,y) end)
  end
  return A.scan(maskB,rectB,x1,y1,x2,y2,
    function(x,y) return A.contains(maskA,rectA,x,y) end)
end

function A.overlapShape(mask,rect,shape)
  if not mask then return true end
  local p=shape.points
  if not p then return false end
  local minX,maxX,minY,maxY=p[1],p[1],p[2],p[2]
  for i=3,#p,2 do
    minX=math.min(minX,p[i]);maxX=math.max(maxX,p[i])
    minY=math.min(minY,p[i+1]);maxY=math.max(maxY,p[i+1])
  end
  local other={points={minX,minY,maxX,maxY}}
  local x1,y1,x2,y2=intersection(rect,other)
  return x1~=nil and A.scan(mask,rect,x1,y1,x2,y2,
    function(x,y) return A.shapeContains(shape,x,y) end) or false
end

return A
