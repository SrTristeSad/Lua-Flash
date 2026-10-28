-- Studio-only preview for symbol instances; no Flash runtime emulation.
local Model=require("src.model")
local Library=require("src.symbol_library")
local Preview={}
local function drawShape(g,shape)
  local p,c=shape.points,shape.color
  g.setColor(c[1],c[2],c[3],c[4] or 1)
  g.setLineWidth(shape.thickness or 2)
  if shape.kind=="brush" then
    if #p>=6 then g.line(p)
    else g.circle("fill",p[1],p[2],math.max(.5,(shape.thickness or 2)/2)) end
  elseif shape.kind=="line" then
    g.line(p[1],p[2],p[3],p[4])
  elseif shape.kind=="rect" then
    g.rectangle("fill",math.min(p[1],p[3]),math.min(p[2],p[4]),
      math.abs(p[3]-p[1]),math.abs(p[4]-p[2]))
  elseif shape.kind=="ellipse" then
    g.ellipse("fill",(p[1]+p[3])/2,(p[2]+p[4])/2,
      math.max(.01,math.abs(p[3]-p[1])/2),math.max(.01,math.abs(p[4]-p[2])/2))
  end
end
function Preview.draw(lib,doc,frame,view)
  local g=love.graphics
  g.push("all")
  g.setScissor(view.x,view.y,view.w,view.h)
  g.translate(view.ox,view.oy)
  g.scale(view.scale)
  for index,layer in ipairs(doc.layers) do
    if layer.visible then
      for _,instance in ipairs(Library.at(lib,index,frame)) do
        local sym=Library.find(lib,instance.symbolId)
        if sym then
          g.push()
          g.translate(instance.x,instance.y)
          g.scale(instance.sx,instance.sy)
          local symbolFrame=1 -- Phase 1: static preview; internal clocks come later.
          for _,inner in ipairs(sym.definition.layers) do
            if inner.visible then
              for _,shape in ipairs(Model.frame(inner,symbolFrame)) do drawShape(g,shape) end
            end
          end
          g.pop()
        end
      end
    end
  end
  g.pop()
end
return Preview
