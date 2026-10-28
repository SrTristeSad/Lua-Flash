-- Player 0.25 persistent high-contrast preference, failure tolerance and palette.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local V=require("src.visual_settings")
local saved={}
local fs={
 read=function(path) assert(path=="player-settings.txt");return saved[path] end,
 write=function(path,contents)
   assert(path=="player-settings.txt")
   saved[path]=contents
   return true
 end
}
assert(V.load(fs)==false)
assert(V.save(fs,true) and saved["player-settings.txt"]=="contrast=high\n")
assert(V.load(fs)==true)
assert(V.save(fs,false) and saved["player-settings.txt"]=="contrast=normal\n")
assert(V.load(fs)==false)
saved["player-settings.txt"]="return os.execute('echo danger')"
assert(not V.load(fs),"user preferences must not execute Lua code")
saved["player-settings.txt"]="contrast=high\nextra=malicious\n"
assert(not V.load(fs),"settings parser must reject unexpected data")
assert(not V.save({write=function() error("readonly") end},true))
assert(not V.load({read=function() error("unreadable") end}))
local a,b=V.palette(false),V.palette(true)
for _,key in ipairs({"bg","top","panel","text","muted","accent","highlight",
 "line","green","focus"}) do
 local x,y=a[key],b[key]
 assert(type(x)=="table" and type(y)=="table")
 for _,v in ipairs(x) do assert(v>=0 and v<=1) end
 for _,v in ipairs(y) do assert(v>=0 and v<=1) end
end
assert(b.text[1]==1 and b.bg[1]==0)
assert(b.line[1]==1 and b.focus[1]==1)
assert(a.focus~=b.focus and a.accent~=b.accent)
print("OK: Player 0.25 safe high-contrast settings, palette and failure recovery")
