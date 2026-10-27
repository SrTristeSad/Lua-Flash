-- Publish a v5 sprite as a 2-frame PNG animation with one timeline WAV cue.
-- lua tools/animate_media.lua source.lfgame output.lfgame spriteIndex framePeriod alt.png wavId cueFrame
-- Only reads local binary assets; emits data-only LUAFGAME 6, never executable Lua.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v6")
local a=arg or {}
if not a[7] then
  io.stderr:write("Usage: lua tools/animate_media.lua src.lfgame dst.lfgame spriteIndex framePeriod alt.png wavId cueFrame\n")
  os.exit(2)
end
assert(a[1]~=a[2],"do not overwrite input")
assert(a[1]:lower():match("%.lfgame$") and a[2]:lower():match("%.lfgame$"),
  "file names must end with .lfgame")
local function read(file)
  local f,err=io.open(file,"rb")
  assert(f,err)
  local bytes=f:read(25*1024*1024+1)
  assert(f:close())
  return bytes
end
local function number(s)
  local n=tonumber(s)
  assert(n and n==math.floor(n),"integer required: "..tostring(s))
  return n
end
local game,err=Package.decode(read(a[1]))
assert(game,err)
assert(game.version==5 or game.version==6,"input must be v5/v6 with embedded PNG")
local index,period=number(a[3]),number(a[4])
local sprite=assert(game.sprites[index],"sprite index not found")
local alt=read(a[5])
local newId="frame_png_"..(#game.resources+1)
local wav=a[6]
local found=false
for _,resource in ipairs(game.resources) do
  if resource.id==wav and resource.kind=="WAV" then found=true;break end
end
assert(found,"WAV resource ID not present in game")
if game.version==5 then
  game.version=6
  game.animations={}
  game.timelineSounds={}
end
game.resources[#game.resources+1]={id=newId,kind="PNG",data=alt}
for i=#game.animations,1,-1 do
  if game.animations[i].index==index then table.remove(game.animations,i) end
end
game.animations[#game.animations+1]={
  index=index,period=period,frames={sprite.asset,newId}
}
game.timelineSounds[#game.timelineSounds+1]={frame=number(a[7]),asset=wav}
local bytes,encodeErr=Package.encode(game)
assert(bytes,encodeErr)
local f,writeErr=io.open(a[2],"wb")
assert(f,writeErr)
assert(f:write(bytes))
assert(f:close())
print("Created "..a[2].." with animated sprite and timeline sound ("..#bytes.." bytes).")
