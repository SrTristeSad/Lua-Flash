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
