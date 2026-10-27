-- Add/replace a full tween track to a native LUAFGAME 7/8 game.
-- Usage: lua tools/animate_transform.lua in.lfgame out.lfgame index frame,x,y,angle,sx,sy ...
-- Each frame offset/angle/scale entry is a set of integer values.
-- No Lua source from the game is executed.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v8")
local a=arg or {}
if #a<5 then
  io.stderr:write("Usage: lua tools/animate_transform.lua source.lfgame output.lfgame spriteIndex 1,x,y,angle,sx,sy frame,x,y,angle,sx,sy ...\n")
  os.exit(2)
end
assert(a[1]~=a[2],"source and destination must differ")
assert(a[1]:lower():match("%.lfgame$") and a[2]:lower():match("%.lfgame$"),
  "input and output must be .lfgame")
local f,err=io.open(a[1],"rb");assert(f,err)
local bytes=f:read(25*1024*1024+1);assert(f:close())
local game,reason=Package.decode(bytes);assert(game,reason)
assert(game.version==7 or game.version==8,"requires a v7 or v8 game")
if game.version==7 then game.version=8;game.tweens={} end
local index=tonumber(a[3])
assert(index and index==math.floor(index),"invalid sprite index")
local keys={}
for i=4,#a do
  local values={}
  for part in a[i]:gmatch("([^,]+)") do
    values[#values+1]=tonumber(part)
  end
  assert(#values==6,"expected frame,x,y,angle,sx,sy")
  for _,v in ipairs(values) do
    assert(v and v==math.floor(v),"key values must be integers")
  end
  keys[#keys+1]={frame=values[1],x=values[2],y=values[3],
    angle=values[4],scaleX=values[5],scaleY=values[6]}
end
for i=#game.tweens,1,-1 do
  if game.tweens[i].index==index then table.remove(game.tweens,i) end
end
game.tweens[#game.tweens+1]={index=index,keys=keys}
local output,encodeErr=Package.encode(game);assert(output,encodeErr)
local dest,writeErr=io.open(a[2],"wb");assert(dest,writeErr)
assert(dest:write(output));assert(dest:close())
print(string.format("Published %s with %d sprite keyframes (%d bytes)",a[2],#keys,#output))
