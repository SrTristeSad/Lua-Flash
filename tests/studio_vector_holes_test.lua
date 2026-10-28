-- Compound vector path holes: nested subtraction, LFVECTOR 3, rendering,
-- precise interior picking, scene/symbol scope roundtrip and SVG export.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local V=require("src.vector_paths")
local Boolean=require("src.vector_boolean")
local Edit=require("src.vector_edit")
local Renderer=require("src.vector_renderer")
local Preview=require("src.symbol_preview")
local Library=require("src.symbol_library")
local Motion=require("src.symbol_motion")
local function rect(v,x1,y1,x2,y2)
  local p=assert(V.addPath(v,1,1,x1,y1,{.1,.2,.8},2,{.9,.5,.2}))
  assert(V.addNode(p,x2,y1))
  assert(V.addNode(p,x2,y2))
  assert(V.addNode(p,x1,y2))
  assert(V.close(p))
  return p
end
local v=V.new()
local a=rect(v,0,0,100,100)
local b=rect(v,25,25,75,75)
local original=V.encode(v)
local tx,err=Boolean.plan(v,1,1,a.id,b.id,"difference")
assert(tx,err)
assert(V.encode(v)==original,"planning must not mutate path storage")
assert(tx.resultCount==1)
tx.apply()
local ring=assert(V.at(v,1,1)[1])
assert(#V.at(v,1,1)==1)
assert(ring.id==a.id and ring.closed and ring.fill)
assert(ring.holes and #ring.holes==1 and #ring.holes[1]==4)
assert(V.inFill(ring,10,10))
assert(not V.inFill(ring,50,50),"cutout must be transparent")
assert(V.inFill(ring,80,80))
assert(not V.hit(ring,50,50,1),"cutout must not be selectable as fill")
assert(V.hit(ring,25,50,1),"hole stroke must remain selectable")
assert(Edit.pickFill(V.at(v,1,1),10,10)==ring)
assert(not Edit.pickFill(V.at(v,1,1),50,50),
  "bucket must not fill already removed interior")
local saved=V.encode(v)
assert(saved:sub(1,10)=="LFVECTOR 3")
assert(saved:find("\nH\n",1,true) and saved:find("\nEH\n",1,true))
assert(saved:find("\nN\t",1,true))
local restored,decodeError=V.decode(saved)
assert(restored,decodeError)
assert(V.encode(restored)==saved,"compound LFVECTOR 3 must roundtrip exactly")
local undo=assert(V.decode(original))
assert(#V.at(undo,1,1)==2,"undo snapshot restores two operands")
local copied=V.ensureKey(restored,1,3)
assert(copied[1].holes and #copied[1].holes[1]==4)
assert(V.move(copied[1],10,12))
assert(V.inFill(copied[1],20,22))
assert(not V.inFill(copied[1],60,62))
assert(V.at(restored,1,1)[1].nodes[1].x==0)
assert(V.at(restored,1,1)[1].holes[1][1].x==25,
  "moving later exposure must not mutate earlier hole")
-- Compound operands are explicitly rejected until multi-ring boolean sweep.
local c=rect(restored,120,120,140,140)
local rejected,reason=Boolean.plan(restored,1,1,ring.id,c.id,"union")
assert(not rejected and reason:find("furos"),"must not ignore existing holes")
local doc=Model.new(800,450,24)
local svg=V.svg(v,doc,1)
assert(svg:find('fill-rule="evenodd"',1,true))
assert(svg:find(" M ",1,true),"compound SVG should contain the hole subpath")
local calls={stencil=0,triangles=0,lines=0,tests={}}
_G.love={math={triangulate=function(points)
  return {points}
end},graphics={
  push=function()end,pop=function()end,setScissor=function()end,
  translate=function()end,scale=function()end,rotate=function()end,
  setColor=function()end,setLineWidth=function()end,
  line=function()calls.lines=calls.lines+1 end,
  circle=function()end,rectangle=function()end,ellipse=function()end,
  polygon=function()
    calls.triangles=calls.triangles+1
  end,
  stencil=function(callback,action,value,keep)
    calls.stencil=calls.stencil+1
    assert(action=="replace")
    if calls.stencil%2==1 then assert(value==1)
    else assert(value==0 and keep==true) end
    callback()
  end,
  setStencilTest=function(mode,val)
    calls.tests[#calls.tests+1]={mode,val}
  end
}}
local view={x=0,y=0,w=800,h=450,ox=0,oy=0,scale=1}
Renderer.draw(v,doc,1,view)
assert(calls.stencil==2 and calls.triangles>=3 and calls.lines>=2)
assert(calls.tests[1][1]=="equal" and calls.tests[1][2]==1)
assert(calls.tests[2][1]==nil,"stencil must be restored after fill")
-- Vector-only compound symbol: same renderer, local-space placement and click.
local symbols=Library.new()
local symbol=assert(Library.create(symbols,"graphic","Hollow",{}))
local scope=assert(V.capture(v,symbol.id,V.at(v,1,1),0,0,1))
local instance=assert(Library.place(symbols,1,1,symbol.id,200,100))
local motion=Motion.new()
local beforeLines=calls.lines
Preview.draw(symbols,doc,1,view,motion,v)
assert(calls.lines>beforeLines)
assert(Preview.pickInstance(symbols,doc,1,view,210,110,motion,v)==instance)
-- The bounding-box picker may pick the hole, but the vector fill itself will
-- not: selecting a specific path must respect the empty interior.
assert(not V.inFill(V.at(scope,1,1)[1],50,50))
assert(V.encode(assert(V.decode(V.encode(v))))==V.encode(v))
-- Corrupted compound structures must fail to load without a partial document.
assert(not V.decode(saved:gsub("\nEH\n","\n",1)))
assert(not V.decode(saved:gsub("\nH\n","\n",1)))
print("OK: compound holes, transparency, LFVECTOR 3, SVG and symbol preview")
