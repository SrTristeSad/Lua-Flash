function love.conf(t)
  -- CI-only headless Windows test: run directly inside bundled LuaJIT,
  -- before SDL creates a window on hosted runners without a real GPU.
  if os.getenv("LUA_FLASH_SMOKE_WIN_NATIVE")=="1" then
    local suffix=string.char(0xC3,0x81) -- Unicode LATIN CAPITAL A WITH ACUTE
    local path=assert(os.getenv("TEMP")).."/LuaFlash-"..suffix.."udio.lfgame"
    local bytes,err=require("src.native_dialog").readPath(path,25*1024*1024)
    assert(bytes,err)
    local game,problem=require("src.package_v9").decode(bytes)
    assert(game and game.version==9,problem)
    local marker=assert(os.getenv("LUA_FLASH_SMOKE_WIN_NATIVE_OKFILE"))
    local file=assert(io.open(marker,"wb"))
    assert(file:write("LUAF_WIN_NATIVE_OK"))
    assert(file:close())
    os.exit(0)
  end
  t.identity = "lua-flash"
  t.version = "11.5"
  t.window.title = "Lua-Flash Player"
  t.window.width = 1040
  t.window.height = 690
  t.window.resizable = true
  t.window.highdpi = true
  t.modules.physics = false
  t.modules.joystick = false
end
