-- Verify containment vs crossing marquee, rotated bounds and non-mutating selection.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Lib=require("src.symbol_library")
local Marquee=require("src.marquee_selection")
local Group=require("src.instance_group")
local doc=Model.new()
local lib=Lib.new()
local rect=Model.makeShape("rect",{1,.4,.2},2,0,0)
rect.points={0,0,20,20}
local sym=assert(Lib.create(lib,"graphic","Object",{rect}))
local a=assert(Lib.place(lib,1,1,sym.id,40,40))
local b=assert(Lib.place(lib,1,1,sym.id,100,40))
local c=assert(Lib.place(lib,1,1,sym.id,180,40))
local before=Lib.encode(lib)
local selection=assert(Marquee.select(lib,doc,1,1,20,20,145,80))
assert(selection[a.uid] and selection[b.uid] and not selection[c.uid])
local narrow=assert(Marquee.select(lib,doc,1,1,30,30,50,50))
assert(not narrow[a.uid],"left-to-right only selects fully enclosed objects")
local cross=assert(Marquee.select(lib,doc,1,1,50,50,30,30))
assert(cross[a.uid] and not cross[b.uid],"right-to-left must intersect")
assert(not next(assert(Marquee.select(lib,doc,1,1,50,50,50,50))))
local merged=Marquee.merge(selection,{[c.uid]=true},true)
assert(Group.count(merged)==3)
local replaced=Marquee.merge(selection,{[c.uid]=true},false)
assert(Group.count(replaced)==1 and replaced[c.uid])
assert(Lib.encode(lib)==before,"marquee must not alter symbol tracks")
-- Transformed bounds must be considered in rectangle selection.
a.angle=45
local rotatedCross=assert(Marquee.select(lib,doc,1,1,100,100,25,25))
assert(rotatedCross[a.uid])
local layer=doc.layers[1]
layer.locked=true
assert(Group.count(Marquee.select(lib,doc,1,1,10,10,210,100))==0)
layer.locked=false
layer.visible=false
assert(Group.count(Marquee.select(lib,doc,1,1,10,10,210,100))==0)
layer.visible=true
local invalid,err=Marquee.select(lib,doc,1,1,0,0,0/0,12)
assert(not invalid and err=="invalid rectangle")
-- Group panel parser rejects nonnumeric, overflows and illegal scale factors.
local op,value=Group.parseProperty("dx","-12.50")
assert(op=="move" and value.dx==-12.5 and value.dy==0)
op,value=Group.parseProperty("dy","8")
assert(op=="move" and value.dy==8)
op,value=Group.parseProperty("scale","125")
assert(op=="scale" and value==1.25)
op,value=Group.parseProperty("rotation","-90")
assert(op=="rotate" and value==-90)
for _,args in ipairs({
  {"dx","abc"},{"dy","100001"},{"scale","0"},{"scale","5"},
  {"scale","2001"},{"rotation","5000"},{"rotation","nan"},
  {"scale","1e309"},{"unknown","3"}
}) do assert(not Group.parseProperty(args[1],args[2])) end
-- A numeric group delta must remain atomic and capable of undo snapshots.
local ids={[a.uid]=true,[b.uid]=true}
local snapshot=Lib.encode(lib)
local tx=assert(Group.plan(doc,lib,1,1,ids,"move",{dx=12.5,dy=0}))
assert(Lib.encode(lib)==snapshot)
tx.apply()
assert(math.abs(Lib.at(lib,1,1)[1].x-52.5)<1e-6)
assert(Lib.encode(assert(Lib.decode(snapshot)))==snapshot)
print("OK: marquee containment/crossing, rotated boxes and numeric group properties")
