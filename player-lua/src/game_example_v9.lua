-- Lua-Flash Player 0.14: easing profiles on sprite transform tracks.
local Previous=require("src.game_example_v8")
local Package=require("src.package_v9")
local E={}
function E.definition()
  local game=Previous.definition()
  game.version=9
  game.title="Movimento suave - Player 0.14"
  game.easings={
    {index=1,frame=1,mode="EASE_IN_OUT"},
    {index=1,frame=23,mode="EASE_OUT"},
    {index=1,frame=45,mode="SMOOTH"},
    {index=1,frame=67,mode="EASE_IN"}
  }
  return game
end
function E.bytes()
  return assert(Package.encode(E.definition()))
end
return E
