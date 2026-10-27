-- Publish a transformed sprite into an existing media-enabled LUAFGAME 6/7.
-- lua tools/transform_sprite.lua in.lfgame out.lfgame index angle scaleX scaleY pivotX pivotY
-- Angle degrees; scale/pivot percentages. No code execution from imported games.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v7")
local a=arg or {}
if not a[8] then
  io.stderr:write("Usage: lua tools/transform_sprite.lua input.lfgame output.lfgame spriteIndex angle scaleX scaleY pivotX pivotY\n")
  os.exit(2)
end
assert(a[1]~=a[2],"refuse to overwrite source")
assert(a[1]:lower():match("%.lfgame$") and a[2]:lower():match("%.lfgame$"),
  "input/output must be .lfgame")
local f,err=io.open(a[1],"rb");assert(f,err)
local bytes=f:read(25*1024*1024+1);assert(f:close())
local game,readErr=Package.decode(bytes)
assert(game,readErr)
assert(game.version==6 or game.version==7,
  "sprite transforms need LUAFGAME 6 or 7")
if game.version==6 then game.version=7;game.transforms={} end
local function number(s)
  local n=tonumber(s)
  assert(n and n==math.floor(n),"integer required: "..tostring(s))
  return n
end
local index=number(a[3])
for i=#game.transforms,1,-1 do
  if game.transforms[i].index==index then table.remove(game.transforms,i) end
end
game.transforms[#game.transforms+1]={
  index=index,angle=number(a[4]),scaleX=number(a[5]),scaleY=number(a[6]),
  pivotX=number(a[7]),pivotY=number(a[8])
}
local output,encodeErr=Package.encode(game);assert(output,encodeErr)
local dest,writeErr=io.open(a[2],"wb");assert(dest,writeErr)
assert(dest:write(output));assert(dest:close())
print("Published "..a[2].." ("..#output.." bytes), transformed sprite #"..index)
