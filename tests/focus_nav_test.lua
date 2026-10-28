-- Player 0.24: focus order, reverse tab, geometry and no input loss.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local F=require("src.focus_nav")
local f=F.new()
assert(f:count()==12)
assert(not f:selected() and not f:rect(1040,690,90,449))
assert(f:next()=="package")
assert(f:selected()=="package")
local first=f:rect(1040,690,90,449)
assert(first[1]==1040-575 and first[2]==24 and first[3]==83)
assert(f:next()=="game")
assert(f:next(true)=="package")
f:clear()
assert(f:next(true)=="smooth" and f:next()=="package")
local names={}
for _=1,12 do names[#names+1]=f:next() end
assert(names[1]=="game" and names[12]=="package")
for _=1,10 do f:next() end
assert(f:selected()=="speed")
local rect=f:rect(1040,690,90,449)
assert(rect[1]==289 and rect[3]==58)
local smallR=f:rect(1040,690,90,449)
assert(smallR[2]+smallR[4]<690)
print("OK: Player 0.24 keyboard focus order, shift-tab and control hitboxes")
