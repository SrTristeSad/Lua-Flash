-- Native project browser and safe project-switching regression.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Browser=require("src.project_browser")
local Model=require("src.model")
local Library=require("src.symbol_library")
local Vector=require("src.vector_paths")
local files,modified={},{}
local tick=0
local function put(name,data)
  files[name]=data
  tick=tick+1
  modified[name]=tick
  return true
end
local fs={
  write=put,
  read=function(name)
    return files[name],files[name] and nil or "not found"
  end,
  getInfo=function(name)
    if files[name] then return {type="file",modtime=modified[name] or 0} end
  end,
  getSaveDirectory=function() return "/test/lua-flash" end,
  getDirectoryItems=function()
    local out={}
    for name in pairs(files) do out[#out+1]=name end
    return out
  end
}
do
  put("zeta.lflash",Model.encode(Model.new()))
  put("alpha.lflash",Model.encode(Model.new()))
  put("untrusted path.lflash","invalid")
  put("alpha.lflash.lfvec",Vector.encode(Vector.new()))
  local list=assert(Browser.list(fs))
  assert(#list==2 and list[1].name=="alpha" and list[2].name=="zeta",
    "saved project listing must sort by modification date and reject unsafe names")
  local bundle=assert(Browser.read(fs,"alpha"))
  assert(bundle.document and bundle.vectors and not bundle.library)
  assert(not Browser.read(fs,"../alpha"),"path traversal must be rejected")
  local oldRead=fs.read
  fs.read=function(name)
    if name=="alpha.lflash.lfvec" then return nil,"I/O error" end
    return oldRead(name)
  end
  assert(not Browser.read(fs,"alpha"),"unreadable existing sidecars must not be silently discarded")
  fs.read=oldRead
  files,modified={},{}
  tick=0
end
local modifiers={}
_G.love={
  keyboard={isDown=function(...)
    for i=1,select("#",...) do
      if modifiers[select(i,...)] then return true end
    end
    return false
  end},
  filesystem=fs,
  graphics=setmetatable({getDimensions=function() return 1200,780 end,
    getWidth=function() return 1200 end}, {__index=function() return function() end end}),
  mouse={getPosition=function() return 0,0 end}
}
dofile("studio-lua/main.lua")
local function press(key,ctrl,shift)
  modifiers.lctrl=ctrl or false
  modifiers.lshift=shift or false
  love.keypressed(key)
  modifiers.lctrl,modifiers.lshift=false,false
end
local function saveAs(name)
  press("s",true,true)
  love.textinput(name)
  press("return")
end
local function reload(name)
  return assert(Model.decode(files[name..".lflash"]))
end
saveAs("um")
assert(files["um.lflash"] and files["um.lflash.lflib"] and files["um.lflash.lfvec"])
press("f7")
press("s",true)
assert(not reload("um").layers[1].visible)
press("n",true)
saveAs("dois")
press("f8")
press("s",true)
assert(reload("dois").layers[1].locked)
press("n",true)
press("o",true)
-- Current blank project is unsaved; first Enter must only show a warning.
press("return")
press("escape")
press("s",true)
assert(files["projeto.lflash"],
  "cancelling a pending project switch must leave the current document intact")
press("o",true)
press("return")
-- The current scene was saved, so this opens the most recent project:
-- projeto.lflash, whose modification time is later than dois.
press("down")
press("return")
assert(reload("dois").layers[1].locked)
-- Switching again to um, which precedes both recent files.
press("o",true)
press("down")
press("down")
press("return")
local before=files["um.lflash"]
press("s",true)
assert(files["um.lflash"]==before,
  "opening a different project must restore its exact native document")
assert(files["um.lflash.lflib"] and files["um.lflash.lfvec"])
-- Unsaved edits must require an explicit second acceptance.
press("f8")
press("o",true)
press("return")
press("escape")
press("s",true)
assert(reload("um").layers[1].locked,
  "cancelled unsaved confirmation must preserve edited layer state")
-- Corrupted project must not replace either the scene or authoring sidecars.
put("corrupt.lflash","corrupt document")
press("o",true)
press("return")
press("escape")
local previous=files["um.lflash"]
press("s",true)
assert(files["um.lflash"]==previous)
assert(Library.decode(files["um.lflash.lflib"]))
assert(Vector.decode(files["um.lflash.lfvec"]))
print("OK: project listing, safe bundle loading, keyboard opening and unsaved-change guard")
