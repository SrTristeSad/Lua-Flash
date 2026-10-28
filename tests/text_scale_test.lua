-- Lua-Flash 0.26: safe persistent font sizes and bounded button text fitting.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local T=require("src.text_scale")
assert(T.valid("normal") and T.valid("large") and T.valid("extra"))
assert(not T.valid("huge") and not T.valid(nil))
assert(#T.levels()==3)
assert(T.sizes("normal").regular==13 and T.sizes("extra").regular==17)
assert(T.sizes("extra").small==16 and T.sizes("large").heading==25)
assert(T.step("normal",1)=="large" and T.step("large",1)=="extra")
assert(T.step("extra",1)=="extra")
assert(T.step("extra",-1)=="large" and T.step("normal",-1)=="normal")
assert(T.fitRatio(100,80)==.8 and T.fitRatio(50,80)==1)
assert(T.fitRatio(0,80)==1)
local file={}
local fs={
  read=function(path) return file[path] end,
  write=function(path,value)
    assert(path=="player-font-size.txt")
    file[path]=value
    return true
  end
}
assert(T.load(fs)=="normal")
assert(T.save(fs,"extra") and file["player-font-size.txt"]=="font=extra\n")
assert(T.load(fs)=="extra")
assert(T.save(fs,"large") and T.load(fs)=="large")
assert(T.save(fs,"normal") and T.load(fs)=="normal")
assert(not T.save(fs,"__malicious__",nil))
file["player-font-size.txt"]="return os.execute('evil')"
assert(T.load(fs)=="normal","settings must never execute Lua code")
file["player-font-size.txt"]="font=extra\nextra=something"
assert(T.load(fs)=="normal","unexpected content must be rejected")
file["player-font-size.txt"]=string.rep("x",100)
assert(T.load(fs)=="normal")
assert(T.load({read=function() error("locked") end})=="normal")
assert(not T.save({write=function() error("disk full") end},"extra"))

local font={
  getWidth=function(_,s) return #s*10 end
}
local value,ratio=T.fitted("OK",font,60)
assert(value=="OK" and ratio==1)
value,ratio=T.fitted("Button",font,50)
assert(value=="Button" and math.abs(ratio-5/6)<.001)
value,ratio=T.fitted("ABCDEFGHIJKLMNOPQRSTUVWXYZ",font,60)
assert(#value<26 and value:sub(-3)=="..." and ratio==1)
assert(font:getWidth(value)<=60)
-- Truncation must never split a UTF-8 character; ellipses are ASCII.
value,ratio=T.fitted("Seleção de Áudio e Contraste",font,120)
assert(value:sub(-3)=="..." and ratio==1)
assert(not value:find("[\194-\244]$"),
  "partial UTF-8 sequence must not be produced")
print("OK: Player 0.26 three font sizes, persistence, width fitting and safe UTF-8 truncation")
