-- Symbol-scoped cubic Beziers: LFVECTOR 1 compatibility and LFVECTOR 2 authoring.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Library=require("src.symbol_library")
local Vector=require("src.vector_paths")
local Preview=require("src.symbol_preview")
local Motion=require("src.symbol_motion")
local Transform=require("src.instance_transform")
local Group=require("src.instance_group")
local Marquee=require("src.marquee_selection")
local Handles=require("src.instance_handles")
local doc=Model.new()
local lib=Library.new()
local vectors=Vector.new()
local p=assert(Vector.addPath(vectors,1,1,120,80,{1,.2,.3},3,{.1,.8,.2}))
Vector.addNode(p,160,80)
Vector.addNode(p,160,120)
Vector.close(p)
local symbol=assert(Library.create(lib,"graphic","Vector-only",{}))
local bx,by=Vector.bounds(p)
local scope=assert(Vector.capture(vectors,symbol.id,{p},bx,by,1))
assert(scope~=vectors and #Vector.at(scope,1,1)==1)
assert(Vector.at(scope,1,1)[1].nodes[1].x==0)
assert(p.nodes[1].x==120,"capture cannot mutate the original path")
local item=assert(Library.place(lib,1,1,symbol.id,300,200))
assert(Transform.hit(item,symbol,1,320,210,scope),"vector-only symbols must be pickable")
local x1,y1,x2,y2=Transform.box(item,symbol,1,scope)
assert(x1==300 and y1==200 and x2>=340 and y2>=240)
assert(Handles.points(item,symbol,1,1,scope),"vector-only symbols need resize handles")
local snap=Vector.encode(vectors)
assert(snap:find("LFVECTOR 2",1,true) and snap:find("S\t1",1,true))
local restored=assert(Vector.decode(snap))
assert(Vector.encode(restored)==snap)
local restoredScope=assert(Vector.scope(restored,symbol.id))
assert(#Vector.at(restoredScope,1,1)==1)
assert(Vector.at(restored,1,1)[1].nodes[1].x==120)
-- Distinct paths can share the same ID on successive keyframes (one animated identity).
Vector.ensureKey(scope,1,2)
local frame2=Vector.at(scope,1,2)
assert(Vector.moveNode(frame2[1],1,5,5))
assert(Vector.at(scope,1,1)[1].nodes[1].x==0)
assert(Vector.encode(assert(Vector.decode(Vector.encode(vectors))))==Vector.encode(vectors))
Vector.ensureKey(scope,1,3,true)
assert(#Vector.at(scope,1,3)==0,"blank keyframe must break vector exposure")
local drawnLines=0
_G.love={graphics={
  push=function()end,pop=function()end,setScissor=function()end,
  translate=function()end,scale=function()end,rotate=function()end,
  setColor=function()end,setLineWidth=function()end,
  line=function()drawnLines=drawnLines+1 end,
  circle=function()end,rectangle=function()end,ellipse=function()end,
  polygon=function()end
}}
local view={ox=0,oy=0,x=0,y=0,w=800,h=450,scale=1}
Preview.draw(lib,doc,1,view,Motion.new(),vectors)
assert(drawnLines>0,"vector-only symbol must render in Studio stage preview")
local picked=Preview.pickInstance(lib,doc,1,view,320,210,Motion.new(),vectors)
assert(picked==item)
local ids={[item.uid]=true}
local item2=assert(Library.place(lib,1,1,symbol.id,410,230))
ids[item2.uid]=true
assert(Marquee.select(lib,doc,1,1,290,190,500,300,vectors)[item.uid])
local tx=assert(Group.plan(doc,lib,1,1,ids,"centerY",nil,vectors))
tx.apply()
assert(Library.at(lib,1,1)[2].y==Library.at(lib,1,1)[1].y)
-- Button built with only vector content must support the Hit state.
local button=assert(Library.create(lib,"button","Vector button",{}))
Vector.capture(vectors,button.id,{p},bx,by,1)
local btn=assert(Library.place(lib,1,1,button.id,40,40))
assert(Preview.pickButton(lib,doc,1,view,65,60,vectors)==btn.uid)
-- Existing LFVECTOR 1 documents have no S sections and remain readable.
local legacy=Vector.new()
local old=assert(Vector.addPath(legacy,1,1,2,3,{0,0,0},1))
Vector.addNode(old,5,6)
local legacyEncoded=Vector.encode(legacy)
assert(legacyEncoded:find("LFVECTOR 1",1,true))
assert(Vector.encode(assert(Vector.decode(legacyEncoded)))==legacyEncoded)
assert(not Vector.decode("LFVECTOR 2\nS\t1\nEND\n"))
assert(not Vector.decode("LFVECTOR 1\nS\t1\nES\nEND\n"))
assert(not Vector.decode("LFVECTOR 2\nS\t1\nS\t2\nES\nEND\n"))
assert(not Vector.decode("LFVECTOR 2\nES\nEND\n"))
print("OK: scoped vector symbol geometry, preview, editing, LFVECTOR 1/2 compatibility")
