-- Studio-only symbol library regression. No modifications to the Player model.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local M=require("src.model")
local L=require("src.symbol_library")
local lib=L.new()
local shape=M.makeShape("rect",{1,.2,.3},2,50,40)
shape.points={50,40,80,70}
for _,kind in ipairs({"graphic","movieclip","button"}) do
  local sym=assert(L.create(lib,kind,"Teste "..kind,{shape}))
  assert(sym.definition.layers[1].keys[1][1].points[1]==0)
  assert(sym.definition.layers[1].keys[1][1].points[2]==0)
end
assert(L.count(lib)==3)
local graphic=L.list(lib)[1]
shape.points[1]=-999
assert(graphic.definition.layers[1].keys[1][1].points[1]==0,"symbol must own copied geometry")
local a=assert(L.place(lib,1,1,graphic.id,100,200))
assert(a.uid==1 and a.symbolId==graphic.id)
assert(#L.at(lib,1,8)==1)
L.ensureKey(lib,1,9,true)
assert(#L.at(lib,1,9)==0,"blank key must break exposure")
local b=assert(L.place(lib,1,10,graphic.id,30,20))
assert(b.uid~=a.uid)
assert(#L.at(lib,1,10)==1)
local serialized=L.encode(lib)
local restored=assert(L.decode(serialized))
assert(L.count(restored)==3)
assert(L.encode(restored)==serialized,"library round-trip must be deterministic")
assert(#L.at(restored,1,8)==1 and #L.at(restored,1,9)==0)
assert(#L.at(restored,1,10)==1)
assert(restored.nextInstanceId==3 and restored.nextSymbolId==4)
assert(not L.place(restored,1,1,999,0,0))
assert(not L.decode("LUALIB 1\nI\t1\t1\t0\t0\t1\t1\nEND\n"))
assert(not L.decode("LUALIB 1\nK\t1\t1\nI\t1\t999\t0\t0\t1\t1\nEND\n"))
assert(not L.decode("LUALIB 1\nBOGUS\nEND\n"))
assert(L.removeKey(restored,1,9))
assert(#L.at(restored,1,9)==1)
print("OK: graphic, movieclip, button, stable IDs, instances and sidecar round-trip")
