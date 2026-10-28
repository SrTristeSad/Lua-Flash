-- Lua-Flash Player 0.28: Player-only vector renderer with conservative culling.
-- Never changes the shared Runtime used by Studio. Culling is performed in
-- document coordinates; a safety margin includes stroke widths.
local Runtime=require("src.runtime")
local Responsive=require("src.responsive")
local V={}
V.__index=V

local function bounds(shape)
  local p=shape.points
  local x1,y1,x2,y2=p[1],p[2],p[1],p[2]
  if shape.kind=="brush" then
    for i=3,#p,2 do
      local x,y=p[i],p[i+1]
      if x<x1 then x1=x end
      if x>x2 then x2=x end
      if y<y1 then y1=y end
      if y>y2 then y2=y end
    end
  else
    x2,y2=p[3] or x1,p[4] or y1
    if x2<x1 then x1,x2=x2,x1 end
    if y2<y1 then y1,y2=y2,y1 end
  end
  -- Geometry and brush caps may extend beyond the centerline. Half stroke
  -- is sufficient for antialiased points/lines; add one unit for precision.
  local extra=(shape.kind=="brush" or shape.kind=="line") and
    math.max(.5,(shape.thickness or 2)/2)+1 or 1
  return {x1-extra,y1-extra,x2+extra,y2+extra}
end

function V.new()
  return setmetatable({
    cachedBounds=setmetatable({},{__mode="k"}),
    frames=0,drawn=0,culled=0,lastDrawn=0,lastCulled=0,
    boundsBuilt=0
  },V)
end
function V:invalidate()
  self.cachedBounds=setmetatable({},{__mode="k"})
end
function V:visible(shape,w,h)
  local box=self.cachedBounds[shape]
  if not box then
    box=bounds(shape)
    self.cachedBounds[shape]=box
    self.boundsBuilt=self.boundsBuilt+1
  end
  return not (box[3]<0 or box[4]<0 or box[1]>w or box[2]>h)
end
local function paint(shape,lg)
  local c,p=shape.color,shape.points
  lg.setColor(c[1],c[2],c[3],c[4] or 1)
  lg.setLineWidth(shape.thickness or 2)
  if shape.kind=="brush" then
    if #p>=6 then
      lg.line(p)
    else
      lg.circle("fill",p[1],p[2],math.max(.5,(shape.thickness or 2)/2))
    end
  elseif shape.kind=="line" then
    lg.line(p[1],p[2],p[3],p[4])
  elseif shape.kind=="rect" then
    lg.rectangle("fill",math.min(p[1],p[3]),math.min(p[2],p[4]),
      math.abs(p[3]-p[1]),math.abs(p[4]-p[2]))
  elseif shape.kind=="ellipse" then
    lg.ellipse("fill",(p[1]+p[3])/2,(p[2]+p[4])/2,
      math.max(.01,math.abs(p[3]-p[1])/2),math.max(.01,math.abs(p[4]-p[2])/2))
  end
end
local function clippedScissor(x,y,w,h)
  local lg=love.graphics
  if not lg.getDimensions then
    lg.setScissor(x,y,w,h)
    return
  end
  local screenW,screenH=lg.getDimensions()
  local view=Responsive.layout(screenW,screenH)
  local px=view.x+x*view.scale
  local py=view.y+y*view.scale
  -- Clip to actual window; scissor does not obey lg.scale/translate.
  local left=math.max(0,math.floor(px))
  local top=math.max(0,math.floor(py))
  local right=math.min(screenW,math.ceil(px+w*view.scale))
  local bottom=math.min(screenH,math.ceil(py+h*view.scale))
  lg.setScissor(left,top,math.max(0,right-left),math.max(0,bottom-top))
end

function V:draw(doc,frame,x,y,width,height)
  local lg=love.graphics
  local ox,oy,scale=Runtime.geometry(doc,x,y,width,height)
  lg.push("all")
  lg.setColor(.18,.19,.23)
  lg.rectangle("fill",x,y,width,height)
  clippedScissor(x,y,width,height)
  lg.setColor(1,1,1)
  lg.rectangle("fill",ox,oy,doc.width*scale,doc.height*scale)
  lg.translate(ox,oy)
  lg.scale(scale)
  local drawn,culled=0,0
  for _,layer in ipairs(doc.layers) do
    if layer.visible then
      local shapes=layer.keys[frame] or {}
      for _,shape in ipairs(shapes) do
        if self:visible(shape,doc.width,doc.height) then
          paint(shape,lg)
          drawn=drawn+1
        else
          culled=culled+1
        end
      end
    end
  end
  lg.pop()
  self.frames=self.frames+1
  self.drawn=self.drawn+drawn
  self.culled=self.culled+culled
  self.lastDrawn=drawn
  self.lastCulled=culled
  return ox,oy,scale
end
function V:stats()
  return {frames=self.frames,drawn=self.drawn,culled=self.culled,
    lastDrawn=self.lastDrawn,lastCulled=self.lastCulled,
    boundsBuilt=self.boundsBuilt}
end
return V
