-- Lua-Flash Player 0.9: original animated PNG frames and short timeline WAV.
local Previous=require("src.game_example_v5")
local Package=require("src.package_v6")
local B64="iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAS0lEQVR42mNgoAVoUv70H4T/B6wHYxifIs0wPkWa8bqEWM1YXUKqZgyXkKMZxRXkaMYwgBxvDKIwIMcbONMC2ZqJdQnR+YFszaQCAET5saW3IAWdAAAAAElFTkSuQmCC"
local alphabet="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function decode64(s)
  local out,buffer,bits={},0,0
  for i=1,#s do
    local c=s:sub(i,i)
    if c~="=" then
      local at=assert(alphabet:find(c,1,true),"invalid internal sample")
      buffer=buffer*64+at-1
      bits=bits+6
      if bits>=8 then
        bits=bits-8
        out[#out+1]=string.char(math.floor(buffer/2^bits)%256)
        buffer=buffer%2^bits
      end
    end
  end
  return table.concat(out)
end
local E={}
function E.definition()
  local game=Previous.definition()
  game.version=6
  game.title="Sprite animado + efeitos na timeline - 0.9"
  game.resources[#game.resources+1]={id="estrela_alt",kind="PNG",data=decode64(B64)}
  game.animations={{index=1,period=7,frames={"estrela","estrela_alt"}}}
  game.timelineSounds={{frame=23,asset="acerto"},{frame=45,asset="acerto"}}
  return game
end
function E.bytes() return assert(Package.encode(E.definition())) end
return E
