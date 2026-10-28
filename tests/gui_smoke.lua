-- Smoke test: Lua-Flash Player and Studio callbacks with a mocked LÖVE host.
-- Complements (does not replace) real LÖVE graphical testing.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;./studio-lua/?.lua;"..package.path
local saved={}
local ctrl=false
local fullscreen=false
local function nop() end
_G.love={
  graphics=setmetatable({
    getWidth=function() return 1040 end,
    getHeight=function() return 690 end,
    getDimensions=function() return 1040,690 end,
    newFont=function() return {} end,
    getFont=function() return {} end,
    newImage=function() return {setFilter=function() end,getWidth=function() return 16 end,getHeight=function() return 16 end} end,
  },{__index=function() return nop end}),
  window={
    setTitle=nop,setMode=nop,
    getFullscreen=function() return fullscreen end,
    setFullscreen=function(v) fullscreen=v end,
  },
  filesystem={
    write=function(name, data) saved[name]=data;return true end,
    createDirectory=function() return true end,
    remove=function(name) if saved[name] then saved[name]=nil;return true end;return false end,
    newFileData=function(data,name) return {data=data,name=name} end,
    read=function(name) return saved[name],saved[name] and nil or "not found" end,
    getSaveDirectory=function() return "/test/lua-flash" end,
  },
  keyboard={isDown=function(a,b) return ctrl and (a=="lctrl" or a=="rctrl" or b=="lctrl" or b=="rctrl") end},
  mouse={getPosition=function() return 200,100 end},
  sound={newSoundData=function(data) return data end},
  audio={newSource=function() return {stop=nop,play=nop} end},
  event={quit=nop}
}

local Model=require("src.model")
local Demo=require("src.demo")
local source=Model.encode(Demo.create())
assert(Model.decode(source),"Demo codec should be valid")

dofile("player-lua/main.lua")
assert(type(love.load)=="function" and type(love.draw)=="function")
love.load()
love.draw()
-- Player 0.18: a rendering fault is logged and shows fallback instead of
-- escaping the LÖVE callback and closing the user's current work.
local oldClear=love.graphics.clear
love.graphics.clear=function() error("injected Player draw failure") end
love.draw()
love.graphics.clear=oldClear
assert(saved["player-errors.log"] and
  saved["player-errors.log"]:find("injected Player draw failure",1,true))
love.draw()
love.update(1/30)
love.keypressed("space")
love.draw()
love.keypressed("left")
love.keypressed("right")
love.keypressed("home")
love.keypressed("end")
love.keypressed("l")
love.keypressed("f11")
assert(fullscreen)
love.keypressed("escape")
assert(not fullscreen)
love.mousepressed(950,35,1)
love.mousepressed(250,600,1)
ctrl=true
love.keypressed("s")
ctrl=false
assert(saved["player_demo.lflash"])
love.keypressed("d")
-- Player 0.3: test interactive game callbacks before opening Studio.
love.mousepressed(560,31,1,false)
love.mousemoved(257,367,0,0,false)
love.mousepressed(257,367,1,false)
love.mousereleased(257,367,1,false)
love.touchpressed("touch-A",257,367)
love.touchmoved("touch-A",257,367)
love.touchreleased("touch-A",257,367)
love.keypressed("a")
love.keypressed("w")
love.keypressed("d")
love.keypressed("s")
love.keypressed("return")
love.keypressed("g")
-- 0.4: load declarative example, dispatch key rule, click, draw, and save it.
love.mousepressed(470,31,1,false)
-- v0.14 visual curve editor: select the second segment and cycle its mode.
love.keypressed("e")
love.draw()
love.mousepressed(745,239,1,false)
love.keypressed("c")
love.draw()
-- Add a key midway through the selected segment (frame 23..45).
love.mousepressed(748,360,1,false)
love.draw()
-- Change pose X/Y and move its frame forward; delete it again.
love.mousepressed(808,397,1,false)
love.mousepressed(955,397,1,false)
love.mousepressed(972,360,1,false)
love.draw()
love.mousepressed(818,360,1,false)
love.draw()
-- Drag the actual sprite at frame 23 to modify its saved position.
love.mousepressed(745,239,1,false)
local Demo9=require("src.game_example_v9")
local Media=require("src.media_runtime")
local Interpolation=require("src.interpolation")
local SpriteTransform=require("src.sprite_transform")
local StageRuntime=require("src.runtime")
local def=Demo9.definition()
local view={x=18,y=100,w=1004,h=434}
local ox,oy,scale=StageRuntime.geometry(def.document,view.x,view.y,view.w,view.h)
local preview=Media.new(def)
local scene=Interpolation.new(def.document):sample(23)
local rect=assert(preview:spriteRect(1,23,scene))
local sx,sy=SpriteTransform.toWorld(rect,.70,.50)
local px,py=ox+sx*scale,oy+sy*scale
preview:release()
love.mousepressed(px,py,1,false)
love.mousemoved(px+19,py+10,19,10,false)
love.mousereleased(px+19,py+10,1,false)
love.draw()
-- v0.16 rotation + scale X/Y, undo and redo must preserve dragged X.
love.mousepressed(808,427,1,false)  -- G +5
love.mousepressed(955,427,1,false)  -- SX +10
love.mousepressed(808,459,1,false)  -- SY +10
ctrl=true
love.keypressed("z")
love.keypressed("z")
love.keypressed("z")
love.keypressed("y")
love.keypressed("y")
love.keypressed("y")
ctrl=false
love.draw()
-- A separate recovery copy is written after unsaved changes settle.
love.update(12.1)
local Recovery=require("src.recovery")
local Package=require("src.package_v9")
local key=Recovery.identity("Exemplo externo .lfgame",require("src.game_example_v9").bytes())
local autosave=Recovery.new(love.filesystem,Package,key)
local copy=assert(autosave:read())
local recovered=copy.game
assert(copy.sequence==1 and recovered.version==9)
assert(recovered.tweens[1].keys[2].angle==95)
-- Loading another demo with unsaved edits must be blocked.
love.keypressed("d")
love.keypressed("f3")
love.draw()
-- Ctrl+R while unsaved is deliberately refused.
ctrl=true
love.keypressed("r")
ctrl=false
love.keypressed("e")
love.keypressed("z")
love.keypressed("f8")
love.keypressed("f9")
love.keypressed("f10")
love.keypressed("f10")
love.update(1/24)
love.draw()
ctrl=true
love.keypressed("s")
ctrl=false
assert(saved["player_game.lfgame"])
assert(not autosave:read(),"successful manual save clears stale recovery slots")
local GamePackage=require("src.package_v9")
local savedGame=assert(GamePackage.decode(saved["player_game.lfgame"]))
assert(savedGame.version==9)
local edited=false
for _,curve in ipairs(savedGame.easings) do
  if curve.index==1 and curve.frame==23 then
    assert(curve.mode=="EASE_IN_OUT","editor change must persist in saved package")
    edited=true
  end
end
assert(edited,"GUI must modify selected easing segment")
assert(#savedGame.tweens[1].keys==5,
  "visual add then delete must leave original key count")
assert(savedGame.tweens[1].keys[2].frame==23)
assert(savedGame.tweens[1].keys[2].x>30,
  "dragging sprite must update the selected keyframe pose")
assert(savedGame.tweens[1].keys[2].angle==95,
  "GUI rotate must survive undo and redo")
assert(savedGame.tweens[1].keys[2].scaleX==160)
assert(savedGame.tweens[1].keys[2].scaleY==95)
love.keyreleased("w")
love.focus(false)
love.draw()

local function fakeFile(content,name)
  return {
    getFilename=function() return name end,
    open=function() return true end,
    read=function(_,limit) return content:sub(1,limit) end,
    close=nop
  }
end

love.filedropped(fakeFile(saved["player_game.lfgame"],"exported.lfgame"))
love.draw()
love.filedropped(fakeFile("LUAFGAME 1\nINVALID\n","broken.lfgame"))
love.draw()
love.filedropped(fakeFile(source,"demo.lflash"))
love.draw()
love.filedropped(fakeFile("BAD FILE","bad.lflash"))
love.draw()
love.filedropped(fakeFile(source,"legacy.swf"))
love.draw()
saved["projeto.lflash"]=source
love.keypressed("o")
love.draw()

-- Studio has its own entry point, with independent window callbacks.
package.loaded["src.model"]=nil
package.loaded["src.runtime"]=nil
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;./player-lua/?.lua;"..package.path
dofile("studio-lua/main.lua")
love.load()
love.draw()
love.mousepressed(220,160,1)
love.mousemoved(300,220,80,60)
love.mousereleased(300,220,1)
love.draw()
love.keypressed("f6")
love.keypressed("space")
love.update(1/24)
love.draw()
ctrl=true
love.keypressed("s")
ctrl=false
assert(saved["projeto.lflash"])
assert(Model.decode(saved["projeto.lflash"]))
love.keypressed("tab")
love.draw()
love.keypressed("tab")
love.draw()
love.filedropped(fakeFile(source,"demo.lflash"))
love.draw()
print("OK: player and studio initialisation, rendering callbacks, controls, file loading")
