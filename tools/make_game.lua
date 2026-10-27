-- Turn an existing .lflash scene into a simple declarative .lfgame.
-- Usage: lua tools/make_game.lua scene.lflash output.lfgame layer shape goal seconds [smooth]
-- No code loading, shell execution or network. This runs only locally for authors.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Package=require("src.package_v3")
local a=arg or {}
if not a[1] or not a[2] or not a[3] or not a[4] or not a[5] or not a[6] then
  io.stderr:write("Usage: lua tools/make_game.lua scene.lflash output.lfgame layer shape goal seconds [smooth]\n")
  os.exit(2)
end
local function number(s)
  local n=tonumber(s)
  if not n or n~=math.floor(n) then error("Expected integer, got "..tostring(s)) end
  return n
end
assert(a[1]:lower():match("%.lflash$"),"input must be .lflash")
assert(a[2]:lower():match("%.lfgame$"),"output must be .lfgame")
assert(a[1]~=a[2],"refusing to overwrite source")
local f,err=io.open(a[1],"rb")
assert(f,err)
local bytes=f:read(25*1024*1024+1)
f:close()
local doc,parseErr=Model.decode(bytes)
assert(doc,parseErr)
local title=(a[2]:match("[^/\\]+$") or a[2]):gsub("%.lfgame$","")
if #title>120 then title=title:sub(1,120) end
local layer,shape=number(a[3]),number(a[4])
local bindings={}
if doc.layers[layer] then
  for frame,shapes in pairs(doc.layers[layer].keys) do
    if shapes[shape] then
      bindings[#bindings+1]={id="alvo",layer=layer,frame=frame,shape=shape}
    end
  end
end
table.sort(bindings,function(x,y) return x.frame<y.frame end)
local game={
  version=3,title=title,
  duration=number(a[6]),goal=number(a[5]),smooth=a[7]=="smooth",
  document=doc,
  objects={{id="alvo"}},bindings=bindings,
  states={},
  rules={{event="CLICKID",target="alvo",action="SCORE",value=1}}
}
local data,encodeErr=Package.encode(game)
assert(data,encodeErr)
local dest,openErr=io.open(a[2],"wb")
assert(dest,openErr)
assert(dest:write(data));assert(dest:close())
print("Created "..a[2].." ("..#data.." bytes), one CLICKID rule, no executable scripts.")
