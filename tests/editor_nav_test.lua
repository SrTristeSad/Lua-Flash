-- Player 0.25 editor Tab/Shift+Tab keyboard focus and geometry regression.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local E=require("src.editor_nav")
local nav=E.new()
assert(nav:selected()==nil)
local items=nav:items(4)
assert(#items==23 and items[1]=="track_prev" and items[#items]=="save")
local short=nav:items(2)
assert(#short==21 and short[3]=="key1" and short[4]=="key2")
for _,id in ipairs(short) do
 assert(id~="key3" and id~="key4")
end
assert(nav:next(false,4)=="track_prev")
assert(nav:next(false,4)=="track_next")
assert(nav:next(true,4)=="track_prev")
nav:clear()
assert(nav:next(true,4)=="save")
local x,y,w,h=nav:rect(720,105,302,412,4)
assert(x==720+302-105 and y==105+412-39 and w==93 and h==29)
nav:clear()
local seen={}
for i=1,23 do
 local id=nav:next(false,4)
 assert(not seen[id],"duplicate or skipped keyboard action")
 seen[id]=true
 local bx,by,bw,bh=nav:rect(720,105,302,412,4)
 assert(bx>=720 and bx+bw<=1022 and by>=105 and by+bh<=517,
   "focused editor element outside panel")
end
assert(nav:next(false,4)=="track_prev")
assert(seen.undo and seen.curve and seen.save and seen.scale_y_next)
nav:clear()
for i=1,3 do nav:next(false,4) end
x,y,w,h=nav:rect(720,105,302,412,4)
assert(x==728 and y==204 and w==286 and h==25,
  "first frame-row focus rectangle must match visible row")
-- If key count shrinks, a formerly visible row cannot get an active outline.
nav:next(false,4)
assert(nav:selected()=="key2")
assert(not nav:rect(720,105,302,412,1))
assert(nav:next(false,1)=="insert","Tab should recover from hidden focus row")
print("OK: Player 0.25 23 editor controls, row visibility, selection and focus geometry")
