-- Studio-only drawing and pointer hit tests for reusable symbol instances.
local Model=require("src.model")
local Library=require("src.symbol_library")
local Motion=require("src.symbol_motion")
local Transform=require("src.instance_transform")
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

function Preview.draw(lib,doc,frame,view,state)
  local g=love.graphics
  state=state or Motion.new()
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
          g.rotate(math.rad(instance.angle or 0))
          g.scale(instance.sx,instance.sy)
          local symbolFrame=Motion.frame(state,lib,sym,instance,index,frame)
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

-- Return topmost visible instance plus its layer. Used by Studio selection.
function Preview.pickInstance(lib,doc,frame,view,mx,my,state)
  if not view or not view.scale or view.scale<=0 then return nil end
  local x,y=(mx-view.ox)/view.scale,(my-view.oy)/view.scale
  if x<0 or y<0 or x>doc.width or y>doc.height then return nil end
  state=state or Motion.new()
  for li=#doc.layers,1,-1 do
    if doc.layers[li].visible then
      local items=Library.at(lib,li,frame)
      for index=#items,1,-1 do
        local inst=items[index]
        local sym=Library.find(lib,inst.symbolId)
        if sym and Transform.hit(inst,sym,Motion.frame(state,lib,sym,inst,li,frame),x,y) then
          return inst,li
        end
      end
    end
  end
  return nil
end

-- The fourth Button key is a non-rendered hit area, if present.
-- For early Studio preview, when absent, use geometry from the Up state.
function Preview.pickButton(lib,doc,frame,view,mx,my)
  if not view or not view.scale or view.scale<=0 then return nil end
  local x,y=(mx-view.ox)/view.scale,(my-view.oy)/view.scale
  if x<0 or y<0 or x>doc.width or y>doc.height then return nil end
  for layerIndex=#doc.layers,1,-1 do
    if doc.layers[layerIndex].visible then
      local items=Library.at(lib,layerIndex,frame)
      for i=#items,1,-1 do
        local instance=items[i]
        local sym=Library.find(lib,instance.symbolId)
        if sym and sym.kind=="button" and Transform.valid(instance) then
          local lx,ly=Transform.toLocal(instance,x,y)
          local hitFrame=sym.definition.layers[1].keys[4] and 4 or 1
          for li=#sym.definition.layers,1,-1 do
            local inner=sym.definition.layers[li]
            if inner.visible then
              for _,shape in ipairs(Model.frame(inner,hitFrame)) do
                if Model.hit(shape,lx,ly) then return instance.uid end
              end
            end
          end
        end
      end
    end
  end
  return nil
end
function Preview.pointerMoved(state,lib,doc,frame,view,mx,my)
  Motion.setHover(state,Preview.pickButton(lib,doc,frame,view,mx,my))
end
return Preview
