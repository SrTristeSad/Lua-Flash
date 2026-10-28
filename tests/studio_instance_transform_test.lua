-- Stage instances: rotate/scale/translate with inverse hit tests and legacy saves.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Library=require("src.symbol_library")
local Transform=require("src.instance_transform")
local Preview=require("src.symbol_preview")
local Motion=require("src.symbol_motion")
local lib=Library.new()
local doc=Model.new()
local shape=Model.makeShape("rect",{1,0,0},2,0,0)
shape.points={0,0,40,20}
local symbol=assert(Library.create(lib,"graphic","Rect",{shape}))
local instance=assert(Library.place(lib,1,1,symbol.id,100,80))
assert(instance.angle==0 and instance.sx==1)
assert(Transform.valid(instance))
local x,y=Transform.toWorld(instance,10,5)
assert(x==110 and y==85)
local lx,ly=Transform.toLocal(instance,x,y)
assert(math.abs(lx-10)<1e-9 and math.abs(ly-5)<1e-9)
assert(Transform.hit(instance,symbol,1,110,85))
assert(Transform.adjust(instance,4,-5,2,90))
assert(instance.x==104 and instance.y==75 and instance.angle==90)
assert(instance.sx==2 and instance.sy==2)
local worldX,worldY=Transform.toWorld(instance,10,5)
assert(math.abs(worldX-94)<1e-6 and math.abs(worldY-95)<1e-6)
local backX,backY=Transform.toLocal(instance,worldX,worldY)
assert(math.abs(backX-10)<1e-6 and math.abs(backY-5)<1e-6)
assert(Transform.hit(instance,symbol,1,worldX,worldY))
local x1,y1,x2,y2=Transform.box(instance,symbol,1)
assert(x1<=worldX and x2>=worldX and y1<=worldY and y2>=worldY)
assert(not Transform.adjust(instance,0,0,100,0),"extreme scale must be rejected")
local view={ox=20,oy=30,scale=2,x=20,y=30,w=800,h=450}
local picked,layer=Preview.pickInstance(lib,doc,1,view,20+worldX*2,30+worldY*2,Motion.new())
assert(picked==instance and layer==1)
assert(not Preview.pickInstance(lib,doc,1,view,20+300*2,30+300*2,Motion.new()))
local encoded=Library.encode(lib)
local restored=assert(Library.decode(encoded))
assert(Library.at(restored,1,1)[1].angle==90)
assert(Library.at(restored,1,1)[1].sx==2)
assert(Library.encode(restored)==encoded)
-- Previously shipped LUALIB 1 files had seven values per I entry (no angle).
local previous=encoded:gsub("(I\t%d+\t%d+\t[%d%.%-]+\t[%d%.%-]+\t[%d%.%-]+\t[%d%.%-]+)\t[%d%.%-]+","%1")
local legacy=assert(Library.decode(previous))
assert(Library.at(legacy,1,1)[1].angle==0,"legacy instances must be unrotated")
assert(Library.encode(legacy):find("\t0.000000\n",1,true),"rotation must be written")
local clone=Model.copy(instance)
assert(Transform.adjust(clone,0,0,.5,-90))
assert(clone.angle==0 and clone.sx==1)
assert(instance.angle==90,"transform must not modify copied source")
local drawnRotation=nil
_G.love={graphics={
  push=function() end,pop=function() end,setScissor=function() end,
  translate=function() end,scale=function() end,rotate=function(rad) drawnRotation=rad end,
  setColor=function() end,setLineWidth=function() end,
  line=function() end,circle=function() end,rectangle=function() end,ellipse=function() end
}}
Preview.draw(lib,doc,1,view,Motion.new())
assert(drawnRotation and math.abs(drawnRotation-math.pi/2)<1e-6)
print("OK: instance transforms, visual rotation, hit tests and old LUALIB 1 compatibility")
