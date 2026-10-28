-- Player 0.22: native chooser OS guard and original runtime icon.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Native=require("src.native_dialog")
local Icon=require("src.window_icon")
local oldLove=_G.love
_G.love={system={getOS=function() return "Linux" end}}
assert(not Native.available(),"native Windows dialog must not open on Linux")
local selection,err=Native.choose()
assert(not selection and (err:find("Windows") or err:find("FFI")))
local read,problem=Native.readPath([[C:\Jogos\test.lfgame]],1024)
assert(not read and problem)
_G.love=oldLove
local calls={}
local data={
  setPixel=function(_,x,y,r,g,b,a)
    assert(x>=0 and x<64 and y>=0 and y<64)
    assert(r>=0 and g>=0 and b>=0 and a>=0 and a<=1)
    calls[#calls+1]={x,y,r,g,b,a}
  end
}
local image=Icon.create(function(width,height)
  assert(width==64 and height==64)
  return data
end)
assert(image==data and #calls==64*64)
local function at(x,y)
  local i=y*64+x+1
  return calls[i][3],calls[i][4],calls[i][5],calls[i][6]
end
local _,_,_,a=at(0,0)
assert(a==0,"logo corners must remain transparent")
local r,g,b,alpha=at(33,20)
assert(alpha>0 and r>0 and g>0 and b>0)
local highlighted=0
for _,pixel in ipairs(calls) do
  if pixel[6]>0 and pixel[3]>.90 and pixel[4]>.65 then
    highlighted=highlighted+1
  end
end
assert(highlighted>90,"bolt emblem needs visible highlight")
print("OK: Player 0.22 native picker fallback and generated original icon")
