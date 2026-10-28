-- Player 0.28: offscreen culling must preserve all shapes touching the stage.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Renderer=require("src.viewport_renderer")
local R=require("src.responsive")
local calls={lines=0,rectangles=0,ellipses=0,circles=0,scissors={}}
local screenW,screenH=1040,690
local function nop() end
_G.love={graphics={
  push=nop,pop=nop,setColor=nop,setLineWidth=nop,
  translate=nop,scale=nop,
  getDimensions=function() return screenW,screenH end,
  line=function() calls.lines=calls.lines+1 end,
  rectangle=function() calls.rectangles=calls.rectangles+1 end,
  ellipse=function() calls.ellipses=calls.ellipses+1 end,
  circle=function() calls.circles=calls.circles+1 end,
  setScissor=function(x,y,w,h)
    calls.scissors[#calls.scissors+1]={x,y,w,h}
    assert(x>=0 and y>=0 and x+w<=screenW and y+h<=screenH,
      "scissor must be in physical window coordinates")
  end
}}
local renderer=Renderer.new()
local doc=Model.new(800,450,24)
local layer=doc.layers[1]
local function shape(kind,x1,y1,x2,y2,thickness)
  local s=Model.makeShape(kind,{.9,.8,.1},thickness or 2,x1,y1)
  s.points={x1,y1,x2,y2}
  return s
end
local onscreen=shape("rect",10,10,20,20)
local hiddenRect=shape("rect",900,30,950,60)
local hiddenEllipse=shape("ellipse",-80,-60,-10,-15)
local partlyIn=shape("ellipse",-10,20,30,55)
local thickEdge=shape("line",-5,100,-5,200,18)
local outsideLine=shape("line",850,50,900,50,10)
local outsideBrush=shape("brush",-100,20,-50,30,3)
outsideBrush.points={-100,20,-75,22,-50,30}
local brushDot=shape("brush",802,220,802,220,8)
local lineIn=shape("line",50,60,90,80,1)
local brushIn=shape("brush",10,100,60,110,5)
brushIn.points={10,100,35,105,60,110}
layer.keys[1]={
  onscreen,hiddenRect,hiddenEllipse,partlyIn,thickEdge,
  outsideLine,outsideBrush,brushDot,lineIn,brushIn
}
assert(renderer:visible(partlyIn,800,450))
assert(renderer:visible(thickEdge,800,450))
assert(renderer:visible(brushDot,800,450),
  "stroke cap overlaps stage despite center at x=802")
assert(not renderer:visible(hiddenRect,800,450))
assert(not renderer:visible(outsideBrush,800,450))
local x,y,scale=renderer:draw(doc,1,18,100,1004,434)
assert(x and y and scale>0)
local stats=renderer:stats()
assert(stats.lastDrawn==6 and stats.lastCulled==4,
  "unexpected culling result: "..stats.lastDrawn.." drawn, "..stats.lastCulled.." culled")
assert(calls.ellipses==1 and calls.lines==2 and calls.rectangles==3,
  "visible geometry must match LÖVE primitives with background")
assert(calls.scissors[1][1]==18 and calls.scissors[1][2]==100)
local boundsBefore=stats.boundsBuilt
renderer:draw(doc,1,18,100,1004,434)
assert(renderer:stats().boundsBuilt==boundsBefore,
  "unchanged authored geometry must reuse cached bounds")

-- A modified source document explicitly invalidates its bounding cache.
onscreen.points={900,900,980,970}
assert(renderer:visible(onscreen,800,450),
  "bounds remain cached until explicit source change invalidation")
renderer:invalidate()
assert(not renderer:visible(onscreen,800,450))

-- With responsive scaling, scissor rectangles are never outside the actual
-- 640x400 window; the culling still uses document coordinates, not pixels.
screenW,screenH=640,400
calls.scissors={}
renderer:draw(doc,1,18,100,1004,434)
local view=R.layout(640,400)
local left=math.floor(view.x+18*view.scale)
local top=math.floor(view.y+100*view.scale)
assert(calls.scissors[1][1]==left and calls.scissors[1][2]==top)
local ignored=Model.addLayer(doc)
ignored.visible=false
ignored.keys[1]={shape("rect",10,10,20,20)}
local before=renderer:stats().drawn
renderer:draw(doc,1,18,100,1004,434)
assert(renderer:stats().drawn-before==5,
  "hidden layers must not be drawn")
print("OK: Player 0.28 conservative offscreen culling, borders, strokes, cache and 640x400 scissors")
