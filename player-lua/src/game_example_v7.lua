-- Lua-Flash 0.12: showcases 45-degree PNG sprite rotation and 130% scale.
local Old=require("src.game_example_v6")
local Package=require("src.package_v7")
local E={}
function E.definition()
  local game=Old.definition()
  game.version=7
  game.title="Bola giratoria - Player 0.12"
  game.transforms={
    {index=1,angle=45,scaleX=130,scaleY=130,pivotX=50,pivotY=50}
  }
  return game
end
function E.bytes()
  return assert(Package.encode(E.definition()))
end
return E
