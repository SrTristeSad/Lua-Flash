-- Add or replace a declarative easing on an LUAFGAME 8/9 sprite segment.
-- Usage: lua tools/set_easing.lua source.lfgame output.lfgame spriteIndex startFrame MODE
-- MODE: LINEAR, EASE_IN, EASE_OUT, EASE_IN_OUT, SMOOTH, STEP
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v9")
local a=arg or {}
if not a[5] or a[6] then
  io.stderr:write("Usage: lua tools/set_easing.lua source.lfgame result.lfgame spriteIndex startFrame LINEAR|EASE_IN|EASE_OUT|EASE_IN_OUT|SMOOTH|STEP\n")
  os.exit(2)
end
assert(a[1]~=a[2],"source and destination must differ")
assert(a[1]:lower():match("%.lfgame$") and a[2]:lower():match("%.lfgame$"),
  "both files must have .lfgame extension")
local function whole(s)
  local n=tonumber(s)
  assert(n and n==math.floor(n),"expected integer")
  return n
end
local f,err=io.open(a[1],"rb");assert(f,err)
local bytes=f:read(25*1024*1024+1);assert(f:close())
local game,reason=Package.decode(bytes);assert(game,reason)
assert(game.version==8 or game.version==9,"requires LUAFGAME 8/9")
local index,frame=whole(a[3]),whole(a[4])
if game.version==8 then game.version=9;game.easings={} end
for i=#game.easings,1,-1 do
  if game.easings[i].index==index and game.easings[i].frame==frame then
    table.remove(game.easings,i)
  end
end
if a[5]~="LINEAR" then
  game.easings[#game.easings+1]={index=index,frame=frame,mode=a[5]}
end
local result,encodeErr=Package.encode(game);assert(result,encodeErr)
local out,writeErr=io.open(a[2],"wb");assert(out,writeErr)
assert(out:write(result));assert(out:close())
print(string.format("Published %s (%d bytes); easing=%s",a[2],#result,a[5]))
