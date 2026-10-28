-- Studio 0.2 regression: project lifecycle and layer toggles without a display.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local saved
local files={}
_G.love={
  keyboard={isDown=function() return false end},
  filesystem={
    write=function(name,data) saved=data;files[name]=data;return true end,
    getInfo=function(name) return files[name] and {type="file"} or nil end,
    getSaveDirectory=function() return "/tmp" end
  },
  graphics={getDimensions=function() return 1200,780 end}
}
dofile("studio-lua/main.lua")
local function capture()
  love.keypressed("s")
  assert(saved,"Ctrl+S test requires modifier mock")
  return assert(Model.decode(saved))
end
local modifiers={}
love.keyboard.isDown=function(...)
  for i=1,select("#",...) do
    if modifiers[select(i,...)] then return true end
  end
  return false
end
local function press(key,ctrl)
  modifiers.lctrl=ctrl or false
  love.keypressed(key)
  modifiers.lctrl=false
end
local function project()
  press("s",true)
  return assert(Model.decode(saved))
end
local first=project()
assert(#first.layers>=1 and first.layers[first.currentLayer].visible)
press("f7")
local hidden=project()
assert(not hidden.layers[hidden.currentLayer].visible,"F7 must hide active layer")
press("f8")
local locked=project()
assert(locked.layers[locked.currentLayer].locked,"F8 must lock active layer")
press("z",true)
local undone=project()
assert(not undone.layers[undone.currentLayer].locked,"undo must restore lock state")
press("n",true)
local fresh=project()
assert(fresh.width==800 and fresh.height==450 and fresh.fps==24)
assert(fresh.layers[fresh.currentLayer].visible and not fresh.layers[fresh.currentLayer].locked)
press("z",true)
local restored=project()
assert(not restored.layers[restored.currentLayer].visible,"Ctrl+Z should restore previous project")
print("OK: Studio 0.2 project creation, visibility, lock and undo")


-- Save As creates independent files without overwriting existing projects.
modifiers.lctrl=true;modifiers.lshift=true
love.keypressed("s")
modifiers.lctrl=false;modifiers.lshift=false
love.textinput("studio_test")
love.keypressed("return")
assert(files["studio_test.lflash"],"Save As failed to create named file")
local original=files["projeto.lflash"]
modifiers.lctrl=true;modifiers.lshift=true
love.keypressed("s")
modifiers.lctrl=false;modifiers.lshift=false
for i=1,#"studio_test" do love.keypressed("backspace") end
love.textinput("projeto")
love.keypressed("return")
assert(files["projeto.lflash"]==original,"Save As overwrote existing file")
love.keypressed("escape")
print("OK: Studio Save As prevents overwriting an existing project")

-- Sidebar controls operate on the clicked layer, not only the selected one.
press("n",true)
local baseline=project()
love.mousepressed(1200-65,132+2,1)
local toggled=project()
assert(not toggled.layers[1].visible,"sidebar eye control did not hide the layer")
love.mousepressed(1200-37,132+2,1)
local blocked=project()
assert(blocked.layers[1].locked,"sidebar lock control did not lock the layer")
print("OK: Studio sidebar layer visibility and lock controls")


-- Timeline clipboard must make an independent keyframe and be undoable.
press("n",true)
press("f6")
press("c",true)
press("right")
press("v",true)
local pasted=project()
assert(Model.isKey(pasted.layers[pasted.currentLayer],2),"paste should create explicit key at frame 2")
press("z",true)
local reverted=project()
assert(not Model.isKey(reverted.layers[reverted.currentLayer],2),"undo should remove pasted key")
press("pagedown")
local endFrame=project()
assert(endFrame.currentFrame==2,"next key should not move when none exists")
press("end")
assert(project().currentFrame==project().totalFrames,"End should move to last frame")
press("home")
assert(project().currentFrame==1,"Home should move to first frame")
print("OK: Studio timeline copy/paste, undo and navigation")


-- Timeline drag keeps mandatory frame 1; other keyframes are movable.
press("n",true)
local track=780-170
love.mousepressed(250+8,track+45,1)
love.mousemoved(250+19*3+8,track+45,57,0)
love.mousereleased(250+19*3+8,track+45,1)
assert(Model.isKey(project().layers[1],1),"frame 1 must never be moved away")
press("right")
press("f6")
love.mousepressed(250+19+8,track+45,1)
love.mousemoved(250+19*3+8,track+45,38,0)
love.mousereleased(250+19*3+8,track+45,1)
local moved=project()
assert(Model.isKey(moved.layers[1],4),"drag should move frame 2 to 4")
assert(not Model.isKey(moved.layers[1],2),"move should remove source key")
press("z",true)
local undone=project()
assert(Model.isKey(undone.layers[1],2) and not Model.isKey(undone.layers[1],4))
modifiers.lctrl=true
love.mousepressed(250+19+8,track+45,1)
modifiers.lctrl=false
love.mousemoved(250+19*4+8,track+45,57,0)
love.mousereleased(250+19*4+8,track+45,1)
local copied=project()
assert(Model.isKey(copied.layers[1],2) and Model.isKey(copied.layers[1],5))
love.mousepressed(250+19+8,track+45,1)
love.mousemoved(250+19*4+8,track+45,57,0)
love.mousereleased(250+19*4+8,track+45,1)
local protected=project()
assert(Model.isKey(protected.layers[1],2) and Model.isKey(protected.layers[1],5))
print("OK: Studio drag, duplication, undo and first-frame protection")


-- Zoomed timeline drag must use resized cells for the destination.
press("n",true)
press("right")
press("f6")
love.mouse={getPosition=function() return 250,780-170+45 end}
modifiers.lctrl=true
love.wheelmoved(0,4)
modifiers.lctrl=false
-- At 27 px per cell, dragging frame 2 to frame 4 must not use 19 px.
local cell=27
love.mousepressed(250+cell+8,780-170+45,1)
love.mousemoved(250+cell*3+8,780-170+45,cell*2,0)
love.mousereleased(250+cell*3+8,780-170+45,1)
local zoomed=project()
assert(Model.isKey(zoomed.layers[1],4),"zoomed drag did not hit frame 4")
assert(not Model.isKey(zoomed.layers[1],2),"zoomed drag kept source key")
print("OK: Studio zoom-aware timeline mouse dragging")
