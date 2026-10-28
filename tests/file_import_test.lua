-- Lua-Flash 0.21 file importer: typed paths, command-line args and drag/drop.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Import=require("src.file_import")
local Version=require("src.package_v9")
local Example=require("src.game_example_v9")
local Model=require("src.model")
local Demo=require("src.demo")
assert(Import.MAX_BYTES==25*1024*1024)
local kind,name=Import.classify([[C:\Jogos em Lua\Meu Jogo.LFGAME]])
assert(kind=="game" and name=="Meu Jogo.LFGAME")
kind,name=Import.classify("/home/user/arte animada.LFLASH")
assert(kind=="project" and name=="arte animada.LFLASH")
for _,v in ipairs({"","a.swf","a.lua","game.lfgame.exe","a\n.lfgame",string.rep("a",2050)..".lfgame"}) do
  assert(not Import.classify(v),"unsupported input accepted: "..v:sub(1,50))
end
assert(Import.fromArguments({"--", "file.swf", [[C:\Users\Ana\Arte.lflash]]})==
  [[C:\Users\Ana\Arte.lflash]])
assert(Import.fromArguments({"--help","engine.love"})==nil)
assert(Import.fromArguments(nil)==nil)
local contents=Example.bytes()
local closed=0
local function fakeOpen(path,mode)
  assert(path=="demo.lfgame" and mode=="rb")
  return {
    read=function(_,n) assert(n==Import.MAX_BYTES+1);return contents end,
    close=function() closed=closed+1;return true end
  }
end
local imported=assert(Import.readPath("demo.lfgame",fakeOpen))
assert(imported.kind=="game" and imported.name=="demo.lfgame")
assert(closed==1)
assert(Version.decode(imported.bytes))
assert(not Import.readPath("demo.swf",fakeOpen))
assert(not Import.readPath("demo.lfgame",function() return nil,"no access" end))
assert(not Import.readPath("demo.lfgame",function() error("permission denied") end))
local closeCount=0
local dropped={
  getFilename=function() return "/tmp/meu-jogo.lfgame" end,
  open=function(_,mode) assert(mode=="r");return true end,
  read=function(_,n) assert(n==Import.MAX_BYTES+1);return contents end,
  close=function() closeCount=closeCount+1 end
}
local item=assert(Import.readDropped(dropped))
assert(item.name=="meu-jogo.lfgame" and item.kind=="game" and closeCount==1)
local badSize={
  getFilename=function() return "huge.lflash" end,
  open=function() return true end,
  read=function() return string.rep("x",Import.MAX_BYTES+1) end,
  close=function() end
}
assert(not Import.readDropped(badSize),"size limit must include final byte")
assert(not Import.readDropped({
  getFilename=function() return "game.lfgame" end,
  open=function() return true end,
  read=function() error("broken disk") end,
  close=function() end
}))
assert(not Import.readDropped({
  getFilename=function() return "legacy.swf" end
}))
local animation=Model.encode(Demo.create())
local data=assert(Import.readPath("scene.lflash",function()
  return {read=function() return animation end,close=function() end}
end))
assert(Model.decode(data.bytes))
print("OK: 0.21 command-line/drag-drop file importer; path, type, size and error checks")
