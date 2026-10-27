-- Publish a LUAFGAME 3 game with one PNG sprite and one WAV effect.
-- Usage: lua tools/attach_media.lua input.lfgame output.lfgame art.png x y w h effect.wav CLICKID object [other]
-- Events are validated against declared game rules. Assets are bundled by value.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v4")
local argv=arg or {}
if not argv[10] then
  io.stderr:write("Usage: lua tools/attach_media.lua in.lfgame out.lfgame image.png x y width height effect.wav CLICKID|KEY|COLLIDE|WIN target [other]\n")
  os.exit(2)
end
local function read(path)
  local f,err=io.open(path,"rb")
  assert(f,err)
  local data=f:read(25*1024*1024+1)
  assert(f:close())
  return data
end
local function number(raw)
  local n=tonumber(raw)
  assert(n and n==math.floor(n),"expected integer: "..tostring(raw))
  return n
end
assert(argv[1]:lower():match("%.lfgame$") and argv[2]:lower():match("%.lfgame$"),
  "input/output must be .lfgame")
assert(argv[1]~=argv[2],"refuse to overwrite input")
local game,err=Package.decode(read(argv[1]))
assert(game,err)
assert(game.version==3 or game.version==4,
  "media requires a LUAFGAME 3 or LUAFGAME 4 source game")
local image=read(argv[3])
local sound=read(argv[8])
if game.version==3 then
  game.version=4;game.resources={};game.sprites={};game.cues={}
end
local suffix=#game.resources+1
local imgId="imagem_"..suffix
local wavId="som_"..suffix
game.resources[#game.resources+1]={id=imgId,kind="PNG",data=image}
game.resources[#game.resources+1]={id=wavId,kind="WAV",data=sound}
game.sprites[#game.sprites+1]={
  asset=imgId,x=number(argv[4]),y=number(argv[5]),
  width=number(argv[6]),height=number(argv[7])
}
game.cues[#game.cues+1]={
  asset=wavId,event=argv[9],target=argv[10],other=argv[11] or "-"
}
local bytes,encodeErr=Package.encode(game)
assert(bytes,encodeErr)
local f,writeErr=io.open(argv[2],"wb")
assert(f,writeErr)
assert(f:write(bytes))
assert(f:close())
print(string.format("Wrote %s (%d bytes, %d assets). No external scripts.",argv[2],#bytes,#game.resources))
