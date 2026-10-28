-- Generate a distributable data-only .lfgame example outside of the Player.
-- Run from repository root: lua tools/export_example.lua dist/Exemplo-0.26.lfgame
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Example=require("src.game_example_v9")
local output=(arg and arg[1]) or "Exemplo-0.26.lfgame"
local bytes=Example.bytes()
local f,err=io.open(output,"wb")
if not f then error(err) end
assert(f:write(bytes))
assert(f:close())
print(string.format("Wrote %d bytes of declarative game data to %s",#bytes,output))
