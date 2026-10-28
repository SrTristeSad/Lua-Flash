-- Studio -> Player native .lflash interoperability, without SDL/window.
local savedPath=package.path
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local StudioModel=require("src.model")
local authored=StudioModel.new(800,450,24)
StudioModel.addLayer(authored)
local original=StudioModel.encode(authored)
assert(original and #original>0)
package.loaded["src.model"]=nil
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..savedPath
local PlayerModel=require("src.model")
local playerCopy,problem=PlayerModel.decode(original)
assert(playerCopy,problem)
assert(playerCopy.width==800 and playerCopy.height==450 and playerCopy.fps==24)
assert(#playerCopy.layers==#authored.layers)
assert(PlayerModel.encode(playerCopy)==original,
  "Studio->Player round trip lost or changed project data")
print("OK: Studio project loads losslessly in Player .lflash model")
