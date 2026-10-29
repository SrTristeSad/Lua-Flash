-- A single layer viewport drives the Studio sidebar and timeline.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local View=require("src.layer_viewport")
local Model=require("src.model")
assert(View.clamp(1,50)==1)
assert(View.clamp(12,-5)==1 and View.clamp(12,100)==10)
assert(View.count(1,1)==1 and View.count(12,10)==3)
assert(View.index(12,10,1)==10 and View.index(12,10,3)==12)
assert(not View.index(12,10,4))
assert(View.ensureVisible(12,1,12)==10)
assert(View.ensureVisible(12,10,8)==8)
assert(View.ensureVisible(12,8,9)==8)
assert(View.scroll(12,10,3)==10 and View.scroll(12,10,-3)==7)
assert(View.clamp(0,50)==1 and View.count(0,50)==0)
local files,labels={},{}
local modifiers={}
local mx,my=0,0
local function nop() end
_G.love={
 keyboard={isDown=function(...)
   for i=1,select("#",...) do
     if modifiers[select(i,...)] then return true end
   end
   return false
 end},
 mouse={getPosition=function() return mx,my end},
 filesystem={
   write=function(name,data) files[name]=data;return true end,
   read=function(name) return files[name] end,
   getInfo=function(name) return files[name] and {type="file"} or nil end,
   getSaveDirectory=function() return "/tmp" end
 },
 graphics=setmetatable({
   getDimensions=function() return 1200,780 end,
   getWidth=function() return 1200 end,
   print=function(s,x,y) labels[#labels+1]={s=tostring(s),x=x,y=y} end
 }, {__index=function() return nop end})
}
dofile("studio-lua/main.lua")
local function press(key,ctrl,shift)
 modifiers.lctrl=ctrl or false
 modifiers.lshift=shift or false
 love.keypressed(key)
 modifiers.lctrl,modifiers.lshift=false,false
end
local function project()
 press("s",true)
 return assert(Model.decode(files["projeto.lflash"]))
end
local function drawAndCheck(first,last,total)
 labels={}
 love.draw()
 local expected="Camadas "..first.."-"..last.."/"..total
 local found=false
 for _,label in ipairs(labels) do
   if label.s==expected then found=true end
 end
 assert(found,"sidebar did not draw synchronized range: "..expected)
 for row=1,last-first+1 do
   local n=first+row-1
   local y=780-170+38+(row-1)*26+4
   local has=false
   for _,label in ipairs(labels) do
     if label.x==222 and label.y==y and label.s:match("^"..n) then has=true end
   end
   assert(has,"timeline missing visible layer "..n)
 end
end
for _=1,11 do love.mousepressed(600,18,1) end
local doc=project()
assert(#doc.layers==12 and doc.currentLayer==12)
drawAndCheck(10,12,12) -- adding an active layer scrolls both views
-- Toggle the first visible layer, not the tenth sidebar button beyond the window.
love.mousepressed(1200-60,132+4,1)
local hidden=project()
assert(not hidden.layers[10].visible and hidden.layers[1].visible)
love.mousepressed(1200-185,132+4,1) -- select the first visible layer
assert(project().currentLayer==10)
love.mousepressed(260,780-170+38+2*26+4,1) -- third timeline row
assert(project().currentLayer==12,"timeline third row must map to layer 12")
-- Scroll viewport without changing current layer or document state.
love.mousepressed(1200-180,244+4,1) -- ANT. button, 10 -> 7
drawAndCheck(7,9,12)
assert(project().currentLayer==12,"viewport-only scroll must not change active layer")
mx,my=1190,150
love.wheelmoved(0,1) -- sidebar wheel, 7 -> 4
drawAndCheck(4,6,12)
mx,my=260,780-170+45
modifiers.lshift=true
love.wheelmoved(0,-1) -- timeline shift+wheel, 4 -> 7
modifiers.lshift=false
drawAndCheck(7,9,12)
-- The timeline label column must select a layer even when no keyframe is clicked.
love.mousepressed(230,780-170+38+4,1)
assert(project().currentLayer==7)
love.mousepressed(1200-90,244+4,1) -- PROX., 7 -> 10
drawAndCheck(10,12,12)
-- Existing horizontal timeline wheel and Ctrl+wheel zoom must remain available.
mx,my=300,780-170+45
love.wheelmoved(0,-1)
drawAndCheck(10,12,12)
-- Open/reset/undo operations keep selected layer visible in both views.
press("n",true)
assert(#project().layers==1)
drawAndCheck(1,1,1)
press("z",true)
local undone=project()
assert(#undone.layers==12 and undone.currentLayer==7)
drawAndCheck(7,9,12)
-- No changes to layer count or native timeline frames from viewport-only scrolling.
local old=project()
assert(#old.layers==12 and old.totalFrames==60 and old.currentFrame==1)
print("OK: 12-layer sidebar/timeline scroll, selection, toggles, drawing and undo")
