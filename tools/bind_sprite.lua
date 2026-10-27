-- Bind an image already embedded in LUAFGAME 4 to an existing named object.
-- Usage: lua tools/bind_sprite.lua in.lfgame out.lfgame sprite_index object_id FOLLOW|STATIC
-- Does not read/execute scripts. The original file is never overwritten.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v5")
local args=arg or {}
assert(args[1] and args[2] and args[3] and args[4] and args[5],
  "Usage: lua tools/bind_sprite.lua source.lfgame dest.lfgame index object_id FOLLOW|STATIC")
assert(args[1]~=args[2],"input and output must differ")
assert(args[1]:lower():match("%.lfgame$") and args[2]:lower():match("%.lfgame$"),
  "file extension must be .lfgame")
local f,err=io.open(args[1],"rb")
assert(f,err)
local bytes=f:read(25*1024*1024+1)
assert(f:close())
local game,reason=Package.decode(bytes)
assert(game,reason)
assert(game.version==4 or game.version==5,"source needs a media-enabled package")
if game.version==4 then
  game.version=5
  game.spriteBindings={}
end
local index=tonumber(args[3])
assert(index and index==math.floor(index),"index must be integer")
-- Replace an existing mapping for this image only.
for i=#game.spriteBindings,1,-1 do
  if game.spriteBindings[i].index==index then
    table.remove(game.spriteBindings,i)
  end
end
game.spriteBindings[#game.spriteBindings+1]={
  index=index,id=args[4],mode=args[5]
}
local output,encodeErr=Package.encode(game)
assert(output,encodeErr)
local destination,openErr=io.open(args[2],"wb")
assert(destination,openErr)
assert(destination:write(output))
assert(destination:close())
print(string.format("Created %s (%d bytes, interactive sprite #%d => %s, %s)",
  args[2],#output,index,args[4],args[5]))
