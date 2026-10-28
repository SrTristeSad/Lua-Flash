-- Graphic parent sync, independent MovieClip clocks and Button states/hit.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Library=require("src.symbol_library")
local Motion=require("src.symbol_motion")
local Preview=require("src.symbol_preview")

local lib=Library.new()
local doc=Model.new(800,450,24)
local source=Model.makeShape("rect",{1,0,0},2,0,0)
source.points={0,0,20,20}
local nextPose=Model.makeShape("rect",{0,1,0},2,0,0)
nextPose.points={0,0,28,28}
local third=Model.makeShape("rect",{0,0,1},2,0,0)
third.points={0,0,30,30}
local graphic=assert(Library.create(lib,"graphic","Loop",{source}))
assert(Library.appendPose(lib,graphic.id,{nextPose})==2)
assert(Library.appendPose(lib,graphic.id,{third})==3)
local movieclip=assert(Library.create(lib,"movieclip","Independent",{source}))
assert(Library.appendPose(lib,movieclip.id,{nextPose})==2)
assert(Library.appendPose(lib,movieclip.id,{third})==3)
local button=assert(Library.create(lib,"button","Play",{source}))
assert(Library.appendPose(lib,button.id,{nextPose})==2)
assert(Library.appendPose(lib,button.id,{third})==3)
assert(Library.appendPose(lib,button.id,{nextPose})==4)
assert(not Library.appendPose(lib,button.id,{source}),"Button must have four states")
local graphicInstance=assert(Library.place(lib,1,1,graphic.id,100,200))
local clipInstance=assert(Library.place(lib,1,1,movieclip.id,150,200))
local buttonInstance=assert(Library.place(lib,1,1,button.id,250,200))
local state=Motion.new()
assert(Motion.frame(state,lib,graphic,graphicInstance,1,1)==1)
assert(Motion.frame(state,lib,graphic,graphicInstance,1,2)==2)
assert(Motion.frame(state,lib,graphic,graphicInstance,1,3)==3)
assert(Motion.frame(state,lib,graphic,graphicInstance,1,4)==1)
Library.ensureKey(lib,1,5)
assert(Motion.frame(state,lib,graphic,graphicInstance,1,5)==1,
  "new parent key starts the Graphic sync from its own frame")
assert(Motion.frame(state,lib,movieclip,clipInstance,1,1)==1)
Motion.update(state,lib,doc,1,0,true) -- first appearance starts at internal frame one
Motion.update(state,lib,doc,1,1/24,true)
assert(Motion.frame(state,lib,movieclip,clipInstance,1,1)==2)
assert(Motion.frame(state,lib,graphic,graphicInstance,1,1)==1,
  "Graphic must not advance when the parent frame is paused")
Motion.update(state,lib,doc,1,1/24,false)
assert(Motion.frame(state,lib,movieclip,clipInstance,1,1)==2,
  "pausing should hold the MovieClip clock")
Motion.update(state,lib,doc,2,1/24,true)
assert(Motion.frame(state,lib,movieclip,clipInstance,1,2)==3)
Motion.update(state,lib,doc,3,1/24,true)
assert(Motion.frame(state,lib,movieclip,clipInstance,1,3)==1)
doc.layers[1].visible=false
Motion.update(state,lib,doc,3,1/24,true)
assert(next(state.clocks)==nil,"hidden clip should release its clock")
doc.layers[1].visible=true
Motion.update(state,lib,doc,3,1/24,true)
assert(Motion.frame(state,lib,movieclip,clipInstance,1,3)==1,
  "reappearing clip should restart")
Motion.reset(state)
assert(Motion.frame(state,lib,movieclip,clipInstance,1,1)==1)
local view={x=0,y=0,w=1200,h=780,ox=10,oy=20,scale=2}
local function point(x,y) return 10+x*2,20+y*2 end
local mx,my=point(250+25,200+25)
assert(Preview.pickButton(lib,doc,1,view,mx,my)==buttonInstance.uid,
  "fourth state should define hit area")
Preview.pointerMoved(state,lib,doc,1,view,mx,my)
assert(Motion.frame(state,lib,button,buttonInstance,1,1)==2)
Motion.press(state)
assert(Motion.frame(state,lib,button,buttonInstance,1,1)==3)
Motion.release(state)
assert(Motion.frame(state,lib,button,buttonInstance,1,1)==2)
local farx,fary=point(600,400)
Preview.pointerMoved(state,lib,doc,1,view,farx,fary)
assert(Motion.frame(state,lib,button,buttonInstance,1,1)==1)
local encoded=Library.encode(lib)
local restored=assert(Library.decode(encoded))
assert(restored.symbols[graphic.id].definition.totalFrames==3)
assert(restored.symbols[button.id].definition.totalFrames==4)
assert(Library.encode(restored)==encoded)

-- Stubbed renderer verifies that the selected pose actually reaches drawing.
local lastColor
_G.love={graphics={
  push=function() end,pop=function() end,setScissor=function() end,
  translate=function() end,scale=function() end,setColor=function(r,g,b) lastColor={r,g,b} end,
  setLineWidth=function() end,rectangle=function() end,ellipse=function() end,
  line=function() end,circle=function() end
}}
Preview.draw(restored,doc,2,view,Motion.new())
assert(lastColor and lastColor[1]==1,"Button Up (last symbol) should render correctly")
print("OK: Graphic sync, MovieClip clock, Button Up/Over/Down/Hit and persistence")
