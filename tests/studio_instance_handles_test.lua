-- Geometry of direct-manipulation handles and numeric property validation.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Lib=require("src.symbol_library")
local Transform=require("src.instance_transform")
local Handles=require("src.instance_handles")
local Props=require("src.instance_properties")
local lib=Lib.new()
local shape=Model.makeShape("rect",{1,0,0},2,15,20)
shape.points={15,20,65,60}
local sym=assert(Lib.create(lib,"graphic","Test",{shape}))
local inst=assert(Lib.place(lib,1,1,sym.id,100,80))
local view={ox=120,oy=100,scale=2}
local points=assert(Handles.points(inst,sym,1,view.scale))
local function hit(pt) return view.ox+pt[1]*view.scale,view.oy+pt[2]*view.scale end
local bx,by=hit(points.br)
local rx,ry=hit(points.rotate)
assert(Handles.hit(points,view,bx,by)=="scale")
assert(Handles.hit(points,view,rx,ry)=="rotate")
assert(not Handles.hit(points,view,800,800))
local startAX,startAY=points.tl[1],points.tl[2]
local scaled=assert(Handles.apply(inst,sym,1,view.scale,"scale",
  startAX+100,startAY+80,points))
assert(math.abs(scaled.sx-2)<1e-8 and math.abs(scaled.sy-2)<1e-8)
assert(inst.sx==1 and inst.sy==1,"handle preview must not mutate live item")
local scalePoints=assert(Handles.points(scaled,sym,1,view.scale))
assert(math.abs(scalePoints.tl[1]-startAX)<1e-7 and
  math.abs(scalePoints.tl[2]-startAY)<1e-7,
  "scale must anchor opposite corner")
assert(not Handles.apply(inst,sym,1,view.scale,"scale",startAX-50,startAY+30,points),
  "scale must reject flip crossing")
assert(not Handles.apply(inst,sym,1,view.scale,"scale",1e8,1e8,points),
  "scale limit should reject extreme pointer")
local origin={x=points.pivot[1],y=points.pivot[2]}
local rad=math.atan2 and math.atan2(points.rotate[2]-origin.y,points.rotate[1]-origin.x)
  or math.atan(points.rotate[2]-origin.y,points.rotate[1]-origin.x)
local rr=rad+math.pi/2
local proposed=assert(Handles.apply(inst,sym,1,view.scale,"rotate",
  origin.x+math.cos(rr)*30,origin.y+math.sin(rr)*30,points))
assert(math.abs(proposed.angle-90)<1e-6)
local center=assert(Handles.points(proposed,sym,1,view.scale)).pivot
assert(math.abs(center[1]-origin.x)<1e-6 and math.abs(center[2]-origin.y)<1e-6,
  "rotation must preserve center")
assert(math.abs(Props.read(proposed,"angle")-90)<1e-6)
local position=assert(Props.set(proposed,"x","125.5"))
assert(position.x==125.5 and proposed.x~=125.5)
local sx=assert(Props.set(proposed,"sx","1.25"))
assert(sx.sx==1.25)
local turn=assert(Props.set(proposed,"angle","-90"))
assert(turn.angle==270)
assert(not Props.set(proposed,"angle","nan"))
assert(not Props.set(proposed,"x","100001"))
assert(not Props.set(proposed,"sx","0"))
assert(not Props.set(proposed,"sy","21"))
assert(not Props.set(proposed,"sx","abc"))
assert(not Props.set(proposed,"angle","1e309"))
assert(Props.format(inst,"sx")=="1.000")
print("OK: handles scale anchored corner, rotate about center and numeric property limits")
