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
  },{__index=function() return nop end}),
  window={
    setTitle=nop,setMode=nop,
    getFullscreen=function() return fullscreen end,
    setFullscreen=function(v) fullscreen=v end,
  },
  filesystem={
    write=function(name, data) saved[name]=data;return true end,
    read=function(name) return saved[name],saved[name] and nil or "not found" end,
    getSaveDirectory=function() return "/test/lua-flash" end,
  },
  keyboard={isDown=function() return ctrl end},
  mouse={getPosition=function() return 200,100 end},
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

local function fakeFile(content,name)
  return {
    getFilename=function() return name end,
    open=function() return true end,
    read=function(_,limit) return content:sub(1,limit) end,
    close=nop
  }
end

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
