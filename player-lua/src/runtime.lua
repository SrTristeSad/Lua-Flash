-- Lua-Flash native runtime: plays Lua-Flash documents, not SWF.
-- Shares the very same scene renderer with Studio.
local Model = require("src.model")
local Runtime = {}
Runtime.__index = Runtime

function Runtime.new(doc)
  return setmetatable({document=doc,frame=doc.currentFrame or 1,playing=false,elapsed=0},Runtime)
end

function Runtime:seek(n)
  self.frame=math.max(1,math.min(self.document.totalFrames, math.floor(n)))
  self.elapsed=0
  return self.frame
end

function Runtime:update(dt)
  if not self.playing then return end
  self.elapsed=self.elapsed+math.min(dt,0.2)
  local interval=1/math.max(1,self.document.fps)
  while self.elapsed>=interval do
    self.elapsed=self.elapsed-interval
    self.frame=self.frame%self.document.totalFrames+1
  end
end

function Runtime.geometry(doc,x,y,width,height)
  local scale=math.min(width/doc.width,height/doc.height)
  return x+(width-doc.width*scale)/2,y+(height-doc.height*scale)/2,scale
end

local function paint(shape)
  local lg=love.graphics
  local c=shape.color
  lg.setColor(c[1],c[2],c[3],c[4] or 1)
  lg.setLineWidth(shape.thickness or 2)
  local p=shape.points
  if shape.kind=="brush" then
    if #p>=6 then lg.line(p) else lg.circle("fill",p[1],p[2],math.max(.5,(shape.thickness or 2)/2)) end
  elseif shape.kind=="line" then
    lg.line(p[1],p[2],p[3],p[4])
  elseif shape.kind=="rect" then
    lg.rectangle("fill",math.min(p[1],p[3]),math.min(p[2],p[4]),
      math.abs(p[3]-p[1]),math.abs(p[4]-p[2]))
  elseif shape.kind=="ellipse" then
    lg.ellipse("fill",(p[1]+p[3])/2,(p[2]+p[4])/2,
      math.max(0.01,math.abs(p[3]-p[1])/2), math.max(0.01,math.abs(p[4]-p[2])/2))
  end
end

function Runtime.draw(doc,frame,x,y,width,height)
  local lg=love.graphics
  local ox,oy,scale=Runtime.geometry(doc,x,y,width,height)
  lg.push("all")
  lg.setColor(.18,.19,.23)
  lg.rectangle("fill",x,y,width,height)
  lg.setScissor(x,y,width,height)
  lg.setColor(1,1,1)
  lg.rectangle("fill",ox,oy,doc.width*scale,doc.height*scale)
  lg.translate(ox,oy)
  lg.scale(scale)
  for _,layer in ipairs(doc.layers) do
    if layer.visible then
      for _,shape in ipairs(Model.frame(layer,frame)) do paint(shape) end
    end
  end
  lg.pop()
  return ox,oy,scale
end

return Runtime
