-- Studio 0.2 regression: project lifecycle and layer toggles without a display.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local saved
local files={}
_G.love={
  keyboard={isDown=function() return false end},
  filesystem={
    write=function(name,data) saved=data;files[name]=data;return true end,
    read=function(name) return files[name] end,
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


-- Shift selection and atomic multi-keyframe moves.
-- Restore 19px cells after the preceding zoom regression.
modifiers.lctrl=true
love.wheelmoved(0,-4)
modifiers.lctrl=false
press("n",true)
press("right")
press("f6")
press("right")
press("right")
press("f6")
local y=780-170+45
local function x(frame) return 250+(frame-1)*19+8 end
love.mousepressed(x(2),y,1);love.mousereleased(x(2),y,1)
modifiers.lshift=true
love.mousepressed(x(4),y,1);love.mousereleased(x(4),y,1)
modifiers.lshift=false
love.mousepressed(x(2),y,1)
love.mousemoved(x(7),y,95,0)
love.mousereleased(x(7),y,1)
local grouped=project()
assert(Model.isKey(grouped.layers[1],7) and Model.isKey(grouped.layers[1],9))
assert(not Model.isKey(grouped.layers[1],2) and not Model.isKey(grouped.layers[1],4))
press("z",true)
local restoredGroup=project()
assert(Model.isKey(restoredGroup.layers[1],2) and Model.isKey(restoredGroup.layers[1],4))
assert(not Model.isKey(restoredGroup.layers[1],7))
print("OK: Studio multi-selection, group move and undo")


-- Multi-layer timeline: click second visible track to select that layer.
press("n",true)
love.mousepressed(600,18,1)
local multi=project()
assert(#multi.layers==2 and multi.currentLayer==2)
love.mousepressed(250+8,780-170+38+26+5,1)
local switched=project()
assert(switched.currentLayer==1,"second timeline track must activate layer 1")
print("OK: Studio multi-layer timeline track selection")


-- Studio symbol workflow: create a Graphic from artwork, stamp it, save and undo.
local SymbolLibrary=require("src.symbol_library")
press("n",true)
press("b")
love.mousepressed(250,200,1)
love.mousemoved(270,220,20,20)
love.mousereleased(270,220,1)
modifiers.lctrl=true
love.keypressed("f8")
modifiers.lctrl=false
local sidecar=files["projeto.lflash.lflib"]
project()
sidecar=files["projeto.lflash.lflib"]
local authoring=assert(SymbolLibrary.decode(sidecar))
assert(SymbolLibrary.count(authoring)==1,"Ctrl+F8 should create a symbol")
love.mousepressed(325,260,1)
love.mousereleased(325,260,1)
project()
local placed=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(#SymbolLibrary.at(placed,1,1)==1,"symbol tool must place instance on stage")
press("z",true)
project()
local undoneSymbol=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(#SymbolLibrary.at(undoneSymbol,1,1)==0,"undo must remove placed instance")
print("OK: Studio symbol creation, stage stamping, sidecar save and undo")


-- Moving / copying an authored key must keep symbol-instance tracks aligned.
-- Restore a stage instance after the preceding undo before exposing frame 2.
love.mousepressed(325,260,1)
love.mousereleased(325,260,1)
press("right")
press("f6")
project()
local beforeTransfer=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(beforeTransfer.tracks[1][2] and #beforeTransfer.tracks[1][2]==1,
  "F6 should expose the existing instance at frame 2")
local uidBefore=beforeTransfer.tracks[1][2][1].uid
local yTimeline=780-170+45
love.mousepressed(x(2),yTimeline,1)
love.mousemoved(x(6),yTimeline,76,0)
love.mousereleased(x(6),yTimeline,1)
local docMoved=project()
local libMoved=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(Model.isKey(docMoved.layers[1],6) and not Model.isKey(docMoved.layers[1],2))
assert(libMoved.tracks[1][6] and not libMoved.tracks[1][2])
assert(libMoved.tracks[1][6][1].uid==uidBefore)
press("z",true)
local docRestored=project()
local libRestored=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(Model.isKey(docRestored.layers[1],2) and not Model.isKey(docRestored.layers[1],6))
assert(libRestored.tracks[1][2] and not libRestored.tracks[1][6])
modifiers.lctrl=true
love.mousepressed(x(2),yTimeline,1)
modifiers.lctrl=false
love.mousemoved(x(6),yTimeline,76,0)
love.mousereleased(x(6),yTimeline,1)
local docCopied=project()
local libCopied=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(Model.isKey(docCopied.layers[1],2) and Model.isKey(docCopied.layers[1],6))
assert(libCopied.tracks[1][6] and libCopied.tracks[1][2])
assert(libCopied.tracks[1][6][1].uid~=libCopied.tracks[1][2][1].uid,
  "Ctrl+drag should produce independent instance identity")
print("OK: Studio timeline moves and duplicates symbol instances with undo")


-- Clipboard should paste both the artwork and independent symbol instances.
press("c",true)
press("right")
press("right")
press("v",true)
local pastedDoc=project()
local pastedLib=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(Model.isKey(pastedDoc.layers[1],8),"paste must create artwork key at frame 8")
assert(pastedLib.tracks[1][8] and #pastedLib.tracks[1][8]==1,
  "paste must include symbol instance")
assert(pastedLib.tracks[1][8][1].uid~=pastedLib.tracks[1][6][1].uid,
  "paste must assign a new instance ID")
press("z",true)
local undoPasteDoc=project()
local undoPasteLib=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(not Model.isKey(undoPasteDoc.layers[1],8) and not undoPasteLib.tracks[1][8],
  "undo must restore both artwork and instance tracks")
print("OK: Studio Ctrl+C/V copies both art and symbols with independent undo")


-- Capture a second symbol pose via UI; undo and sidecar must stay synchronized.
local priorLibrary=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
local firstDefinition=priorLibrary.symbols[1].definition.totalFrames
modifiers.lctrl=true
love.keypressed("f10")
modifiers.lctrl=false
project()
local posed=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(posed.symbols[1].definition.totalFrames==firstDefinition+1,
  "Ctrl+F10 should append an editable pose to selected symbol")
press("z",true)
project()
local poseUndone=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(poseUndone.symbols[1].definition.totalFrames==firstDefinition,
  "undo should restore the previous symbol timeline")
print("OK: Studio Ctrl+F10 symbol pose authoring and undo")


-- Symbol in-place editing must preserve the main scene and the saved sidecar.
press("n",true)
press("b")
love.mousepressed(300,250,1)
love.mousemoved(340,270,40,20)
love.mousereleased(340,270,1)
press("f8",true)
local originalScene=project()
assert(#originalScene.layers[1].keys[1]==1)
press("return",true)  -- Ctrl+Enter enters the selected symbol definition.
press("f5")           -- Append an ordinary exposure frame to the symbol.
press("f9")           -- Add an explicit blank keyframe at frame two.
press("r")
love.mousepressed(350,250,1)
love.mousemoved(390,290,40,40)
love.mousereleased(390,290,1)
local savedScene=project()
assert(Model.encode(savedScene)==Model.encode(originalScene),
  "editing symbol must never overwrite the main .lflash scene")
local editedLibrary=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(editedLibrary.symbols[1].definition.totalFrames==2)
assert(#editedLibrary.symbols[1].definition.layers[1].keys[2]==1,
  "symbol edit must update the nested keyframe")
press("z",true)
project()
local innerUndo=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(#innerUndo.symbols[1].definition.layers[1].keys[2]==0,
  "undo must revert inner symbol artwork")
press("y",true)
project()
local innerRedo=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(#innerRedo.symbols[1].definition.layers[1].keys[2]==1,
  "redo must restore inner symbol artwork")
love.keypressed("escape")
assert(Model.encode(project())==Model.encode(originalScene),
  "returning from symbol edit must preserve the root scene")
press("o",true) -- Reload the two files from LÖVE filesystem.
local reloaded=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(#reloaded.symbols[1].definition.layers[1].keys[2]==1)
love.mousepressed(1050,357,1) -- Select first item in the library after reopening.
love.mousepressed(700,20,1) -- Edit symbol through toolbar button.
press("f5")
local expanded=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
-- Before save, the previous sidecar must still contain the older version.
assert(expanded.symbols[1].definition.totalFrames==2)
project()
local savedAgain=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(savedAgain.symbols[1].definition.totalFrames==3)
love.mousepressed(700,20,1) -- Back to main scene.
assert(Model.encode(project())==Model.encode(originalScene))
print("OK: nested symbol timeline, root-safe saving, undo/redo and reloading")


-- Double-click library navigation and Button's four internal states.
press("n",true)
press("b")
love.mousepressed(300,250,1)
love.mousemoved(340,270,40,20)
love.mousereleased(340,270,1)
modifiers.lctrl=true;modifiers.lalt=true
love.keypressed("f8")
modifiers.lctrl=false;modifiers.lalt=false
local buttonRoot=project()
love.mousepressed(1050,357,1,false,2)
for i=1,3 do press("f5") end
project()
local buttonStates=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(buttonStates.symbols[1].kind=="button")
assert(buttonStates.symbols[1].definition.totalFrames==4,
  "button timeline should reach four states")
press("f5")
project()
local cappedButton=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(cappedButton.symbols[1].definition.totalFrames==4,
  "button state 5 must be rejected")
love.keypressed("escape")
assert(Model.encode(project())==Model.encode(buttonRoot),
  "button editing must not affect the root document")
print("OK: library double-click and four-state Button editor limit")


-- Stage instance selection, keyboard transformations and drag with undo.
press("n",true)
press("b")
love.mousepressed(300,250,1)
love.mousemoved(340,270,40,20)
love.mousereleased(340,270,1)
press("f8",true)
love.mousepressed(325,260,1)
love.mousereleased(325,260,1)
press("v")
love.mousepressed(335,267,1)
love.mousereleased(335,267,1)
project()
local placedInstance=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"])).tracks[1][1][1]
modifiers.lalt=true
love.keypressed("right")
modifiers.lshift=true
love.keypressed("down")
modifiers.lshift=false
modifiers.lalt=false
love.keypressed("rightbracket")
press("rightbracket",true)
project()
local transformed=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"])).tracks[1][1][1]
assert(math.abs(transformed.x-placedInstance.x-1)<.0001)
assert(math.abs(transformed.y-placedInstance.y-10)<.0001)
assert(transformed.angle==5 and math.abs(transformed.sx-1.1)<.0001)
press("z",true)
project()
local scaleUndo=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"])).tracks[1][1][1]
assert(scaleUndo.angle==5 and scaleUndo.sx==1)
-- Re-select after undo, drag, then undo the gesture atomically.
love.mousepressed(338,276,1)
love.mousemoved(354,288,16,12)
love.mousereleased(354,288,1)
project()
local movedInstance=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"])).tracks[1][1][1]
assert(movedInstance.x>scaleUndo.x and movedInstance.y>scaleUndo.y)
press("z",true)
project()
local dragUndo=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"])).tracks[1][1][1]
assert(math.abs(dragUndo.x-scaleUndo.x)<.0001)
assert(math.abs(dragUndo.y-scaleUndo.y)<.0001)
print("OK: symbol instance selection, keyboard transforms, drag and undo")


-- Scale/rotation handles and numeric property editor through actual callbacks.
press("n",true)
press("r")
love.mousepressed(300,250,1)
love.mousemoved(340,270,40,20)
love.mousereleased(340,270,1)
press("f8",true)
love.mousepressed(325,260,1)
love.mousereleased(325,260,1)
press("v")
love.mousepressed(335,267,1)
love.mousereleased(335,267,1)
local Handles=require("src.instance_handles")
local Runtime=require("src.runtime")
local sceneNow=project()
local libNow=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
local instNow=libNow.tracks[1][1][1]
local ox,oy,zoom=Runtime.geometry(sceneNow,176,53,820,557)
local function stageScreen(pt) return ox+pt[1]*zoom,oy+pt[2]*zoom end
local pts=assert(Handles.points(instNow,libNow.symbols[1],1,zoom))
local bmx,bmy=stageScreen(pts.br)
love.mousepressed(bmx,bmy,1)
love.mousemoved(bmx+20,bmy+12,20,12)
love.mousereleased(bmx+20,bmy+12,1)
project()
local scaledLib=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
local scaledInstance=scaledLib.tracks[1][1][1]
assert(scaledInstance.sx>1 and scaledInstance.sy>1,
  "bottom-right handle must scale selected instance")
local afterPts=assert(Handles.points(scaledInstance,scaledLib.symbols[1],1,zoom))
local rmx,rmy=stageScreen(afterPts.rotate)
local px,py=stageScreen(afterPts.pivot)
love.mousepressed(rmx,rmy,1)
-- Move rotation handle around the fixed symbol pivot by a quarter-turn.
love.mousemoved(px-(rmy-py),py+(rmx-px),0,0)
love.mousereleased(px-(rmy-py),py+(rmx-px),1)
project()
local rotatedLib=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(rotatedLib.tracks[1][1][1].angle>30,
  "rotation handle must rotate selected instance")
-- Numeric edit is deliberately absolute (not a relative transform).
love.mousepressed(760+82+20,65+35+5,1)
love.textinput("999")
love.keypressed("return")
project()
local absoluteLib=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(math.abs(absoluteLib.tracks[1][1][1].x-999)<.001,
  "numeric property X must apply entered absolute value")
press("z",true)
project()
local undoProperty=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(undoProperty.tracks[1][1][1].x~=999,
  "numeric property edit must be undoable")
print("OK: UI drag handles, rotation handle, numeric X property and undo")


-- Multi-instance Shift+selection, alignment panel and single-step group undo.
press("n",true)
press("r")
love.mousepressed(300,250,1)
love.mousemoved(340,270,40,20)
love.mousereleased(340,270,1)
press("f8",true)
for _,xp in ipairs({325,390,455}) do
  love.mousepressed(xp,260,1)
  love.mousereleased(xp,260,1)
end
project()
local baselineGroup=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(#baselineGroup.tracks[1][1]==3)
press("v")
love.mousepressed(330,265,1);love.mousereleased(330,265,1)
modifiers.lshift=true
love.mousepressed(395,265,1);love.mousereleased(395,265,1)
love.mousepressed(460,265,1);love.mousereleased(460,265,1)
modifiers.lshift=false
-- Group panel begins at x=760, y=65; top-left button aligns left bounds.
love.mousepressed(790,114,1);love.mousereleased(790,114,1)
project()
local aligned=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
local alignItems=aligned.tracks[1][1]
assert(math.abs(alignItems[1].x-alignItems[2].x)<.01 and
  math.abs(alignItems[2].x-alignItems[3].x)<.01,
  "group alignment must move all three selected instances")
-- Group keyboard rotation must preserve independent IDs and update all angles.
love.keypressed("rightbracket")
project()
local rotated=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
for _,item in ipairs(rotated.tracks[1][1]) do
  assert(item.angle==5,"group rotation must affect every selected instance")
end
-- Dragging an already selected member moves the entire group with one undo.
love.mousepressed(330,265,1)
love.mousemoved(349,278,19,13)
love.mousereleased(349,278,1)
project()
local draggedGroup=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
for i,item in ipairs(draggedGroup.tracks[1][1]) do
  assert(item.x>rotated.tracks[1][1][i].x+5,
    "dragging group member must move every selected instance")
end
press("z",true)
project()
local dragUndone=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
for i,item in ipairs(dragUndone.tracks[1][1]) do
  assert(math.abs(item.x-rotated.tracks[1][1][i].x)<.001,
    "one undo must revert the entire group drag")
end
press("z",true)
project()
local rotationUndo=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
for _,item in ipairs(rotationUndo.tracks[1][1]) do
  assert(item.angle==0,"one undo must revert entire group rotation")
end
press("z",true)
project()
local alignmentUndo=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
assert(alignmentUndo.tracks[1][1][1].x<alignmentUndo.tracks[1][1][2].x and
  alignmentUndo.tracks[1][1][2].x<alignmentUndo.tracks[1][1][3].x,
  "one undo must revert the entire alignment")
print("OK: Shift multi-select, align panel, group rotation and atomic undo")


-- Marquee selection on empty canvas and relative group X property in the UI.
press("n",true)
press("r")
love.mousepressed(300,250,1)
love.mousemoved(340,270,40,20)
love.mousereleased(340,270,1)
press("f8",true)
for _,xp in ipairs({325,390,455}) do
  love.mousepressed(xp,260,1)
  love.mousereleased(xp,260,1)
end
project()
local marqueeBaseline=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
local baseXs={}
for i,item in ipairs(marqueeBaseline.tracks[1][1]) do baseXs[i]=item.x end
press("v")
-- Begin in empty canvas so this is a marquee, not a normal shape or instance drag.
love.mousepressed(290,245,1)
love.mousemoved(510,310,220,65)
love.mousereleased(510,310,1)
-- Group properties are below align buttons, in the same inspector.
love.mousepressed(886,302,1)
love.textinput("30")
love.keypressed("return")
project()
local marqueeChanged=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
for i,item in ipairs(marqueeChanged.tracks[1][1]) do
  assert(math.abs(item.x-baseXs[i]-30)<.001,
    "marquee selection and numeric group X must affect every instance")
end
press("z",true)
project()
local marqueeUndo=assert(SymbolLibrary.decode(files["projeto.lflash.lflib"]))
for i,item in ipairs(marqueeUndo.tracks[1][1]) do
  assert(math.abs(item.x-baseXs[i])<.001,
    "a single undo must revert the entire numeric group property")
end
-- Crossing rectangle selects the last object even though not fully contained.
press("escape")
love.mousepressed(520,315,1)
love.mousemoved(475,254,-45,-61)
love.mousereleased(475,254,1)
-- A selected single instance receives individual property panel, not group actions.
project()
assert(#assert(SymbolLibrary.decode(files["projeto.lflash.lflib"])).tracks[1][1]==3)
print("OK: marquee selection, relative group X property, undo and crossing selection")


-- Studio-only Bezier pen, closed fill, node editing, undo, and auxiliary save.
press("n",true)
press("p") -- Pen tool; clicks create Bezier anchors in the vector sidecar.
for _,pt in ipairs({{320,260},{385,260},{385,320}}) do
  love.mousepressed(pt[1],pt[2],1)
  love.mousereleased(pt[1],pt[2],1)
end
love.mousepressed(320,260,1) -- Close by clicking the initial anchor.
love.mousereleased(320,260,1)
love.keypressed("f") -- Toggle fill on the selected closed path.
local noVectors=project()
local Paths=require("src.vector_paths")
local vectorCreated=assert(Paths.decode(files["projeto.lflash.lfvec"]))
local vpath=assert(Paths.at(vectorCreated,1,1)[1])
assert(vpath.closed and #vpath.nodes==3 and vpath.fill,
  "pen must create a closed filled cubic vector path")
assert(#noVectors.layers[1].keys[1]==0,
  "vector objects should not corrupt legacy LUAFLASH 1 shapes")
love.mousepressed(872,20,1) -- Node-edit button in Studio toolbar.
love.mousepressed(320,260,1)
love.mousemoved(338,274,18,14)
love.mousereleased(338,274,1)
project()
local editedPaths=assert(Paths.decode(files["projeto.lflash.lfvec"]))
local movedNode=assert(Paths.at(editedPaths,1,1)[1].nodes[1])
assert(movedNode.x>vpath.nodes[1].x and movedNode.y>vpath.nodes[1].y,
  "node tool must move vector anchor using mouse")
press("z",true)
project()
local restoredPaths=assert(Paths.decode(files["projeto.lflash.lfvec"]))
assert(math.abs(restoredPaths.tracks[1][1][1].nodes[1].x-vpath.nodes[1].x)<.001,
  "undo must restore pre-edit vector geometry")
press("y",true)
project()
local redonePaths=assert(Paths.decode(files["projeto.lflash.lfvec"]))
assert(math.abs(redonePaths.tracks[1][1][1].nodes[1].x-movedNode.x)<.001,
  "redo must restore edited Bezier anchor")
press("o",true)
project()
local loadedVectors=assert(Paths.decode(files["projeto.lflash.lfvec"]))
assert(#Paths.at(loadedVectors,1,1)==1,"reopen must preserve vector sidecar")
press("right")
press("f9")
project()
local blankVector=assert(Paths.decode(files["projeto.lflash.lfvec"]))
assert(#Paths.at(blankVector,1,2)==0,
  "F9 blank key must also stop exposure of earlier vector drawings")
print("OK: Studio Pen, fill, node drag, vector sidecar reload and undo/redo")


-- Copying a Bezier frame must preserve geometry with a separate editable ID;
-- SVG export must include the cubic path rather than silently dropping vectors.
press("home")
press("c",true)
press("right")
press("right")
press("v",true)
project()
local copiedVectors=assert(Paths.decode(files["projeto.lflash.lfvec"]))
local copyAt3=assert(Paths.at(copiedVectors,1,3)[1])
local originalAt1=assert(Paths.at(copiedVectors,1,1)[1])
assert(copyAt3.id~=originalAt1.id and copyAt3.closed and copyAt3.fill,
  "Ctrl+C/V must preserve full vector geometry using a fresh path identity")
press("e",true)
assert(files["quadro.svg"] and files["quadro.svg"]:find(" C ",1,true),
  "SVG export must contain cubic Bezier segments")
assert(files["quadro.svg"]:find("<path",1,true),
  "SVG export must include the vector object")
press("z",true)
project()
local pasteUndone=assert(Paths.decode(files["projeto.lflash.lfvec"]))
assert(#Paths.at(pasteUndone,1,3)==0,
  "undo must remove pasted vector drawing together with its timeline key")
print("OK: Studio vector frame clipboard, SVG export and undo")
