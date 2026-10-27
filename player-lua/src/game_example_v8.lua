-- First-party LUAFGAME 8 example: independently animated sprite pose.
local Previous=require("src.game_example_v7")
local Package=require("src.package_v8")
local E={}
function E.definition()
  local game=Previous.definition()
  game.version=8
  game.title="Sprite animado por keyframes - Player 0.13"
  game.tweens={{
    index=1,keys={
      {frame=1,x=0,y=0,angle=0,scaleX=100,scaleY=100},
      {frame=23,x=30,y=-45,angle=90,scaleX=150,scaleY=85},
      {frame=45,x=-20,y=30,angle=180,scaleX=75,scaleY=150},
      {frame=67,x=35,y=-20,angle=270,scaleX=130,scaleY=90},
      {frame=90,x=0,y=0,angle=360,scaleX=100,scaleY=100}
    }
  }}
  return game
end
function E.bytes()
  return assert(Package.encode(E.definition()))
end
return E
