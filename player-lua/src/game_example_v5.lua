-- Lua-Flash Player 0.8: playable follow-sprite with real click/collision events.
-- All bundled PNG/WAV artwork/sounds are first-party original test media.
local Example4=require("src.game_example_v4")
local Package=require("src.package_v5")
local E={}
function E.definition()
  local game=Example4.definition()
  game.version=5
  game.title="Bola com sprite - Player 0.8"
  game.spriteBindings={{index=1,id="bola",mode="FOLLOW"}}
  -- Existing native vector "bola" gives the sprite an animated center.
  -- The sprite itself is the topmost click and collision geometry.
  return game
end
function E.bytes()
  return assert(Package.encode(E.definition()))
end
return E
