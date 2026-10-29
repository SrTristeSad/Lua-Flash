-- Reordering layers must preserve corresponding artwork, symbols and vectors.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local M=require("src.model")
local L=require("src.symbol_library")
local V=require("src.vector_paths")
local Ops=require("src.layer_ops")
local doc=M.new()
M.addLayer(doc)
M.addLayer(doc)
local lib=L.new()
local vec=V.new()
local symbol=assert(L.create(lib,"graphic","Selo",{
  M.makeShape("rect",{1,0,0},2,0,0)
}))
for i=1,3 do
  local layer=doc.layers[i]
  layer.name="Plano "..i
  layer.keys[1]={M.makeShape("rect",{i/3,.2,.4},2,i*10,i*5)}
  layer.keys[4]={M.makeShape("line",{.2,.3,.4},1,i*20,0)}
  layer.visible=(i~=3)
  layer.locked=(i==2)
  assert(L.place(lib,i,1,symbol.id,i*15,10))
  local p=assert(V.addPath(vec,i,1,i*100,0,{.1,.2,.3},2,{.4,.5,.6}))
  assert(V.addNode(p,i*100+20,0))
  assert(V.addNode(p,i*100+10,20))
  assert(V.close(p))
end
doc.currentLayer=2
local originals={M.encode(doc),L.encode(lib),V.encode(vec)}
local originalIDs={}
for i=1,3 do originalIDs[i]=L.at(lib,i,1)[1].uid end

local tx=assert(Ops.planMove(doc,lib,vec,2,-1))
assert(tx.from==2 and tx.to==1)
assert(M.encode(doc)==originals[1] and L.encode(lib)==originals[2]
  and V.encode(vec)==originals[3],"planning must not mutate inputs")
tx.apply()
assert(doc.currentLayer==1 and doc.layers[1].name=="Plano 2")
assert(doc.layers[1].locked and not doc.layers[2].locked)
assert(doc.layers[2].name=="Plano 1" and doc.layers[3].name=="Plano 3")
assert(doc.layers[1].keys[4][1].points[1]==40)
assert(L.at(lib,1,1)[1].uid==originalIDs[2])
assert(L.at(lib,2,1)[1].uid==originalIDs[1])
assert(V.at(vec,1,1)[1].nodes[1].x==200)
assert(V.at(vec,2,1)[1].nodes[1].x==100)
assert(M.encode(assert(M.decode(M.encode(doc))))==M.encode(doc))
assert(L.encode(assert(L.decode(L.encode(lib))))==L.encode(lib))
assert(V.encode(assert(V.decode(V.encode(vec))))==V.encode(vec))
local reverse=assert(Ops.planMove(doc,lib,vec,1,1))
reverse.apply()
assert(doc.currentLayer==2)
assert(M.encode(doc)==originals[1] and L.encode(lib)==originals[2]
  and V.encode(vec)==originals[3],"opposite move must restore original bytes")
assert(not Ops.planMove(doc,lib,vec,1,-1))
assert(not Ops.planMove(doc,lib,vec,3,1))
assert(not Ops.planMove(doc,lib,vec,2,2))
assert(not Ops.planMove(doc,{},vec,2,-1))
assert(not Ops.planMove(doc,lib,{},2,-1))
local renamed=assert(Ops.planRename(doc,1,"  Céu Azul  "))
renamed.apply()
assert(doc.layers[1].name=="Céu Azul")
assert(M.decode(M.encode(doc)).layers[1].name=="Céu Azul")
for _,bad in ipairs({"  ","\n","\0",string.rep("a",49)}) do
  assert(not Ops.planRename(doc,1,bad),"invalid layer names must be refused")
end
assert(not Ops.planRename(doc,1,"Céu Azul"))
assert(not Ops.planRename(doc,4,"Wrong"))
print("OK: atomic layer reorder preserves frame keys, instances, vector tracks and serialization")

-- Exercise visible Studio controls, keyboard rename, undo/redo and save.
local files={}
local modifiers={}
_G.love={
  keyboard={isDown=function(...)
    for i=1,select("#",...) do
      if modifiers[select(i,...)] then return true end
    end
    return false
  end},
  filesystem={
    write=function(name,data) files[name]=data;return true end,
    read=function(name) return files[name] end,
    getInfo=function(name) return files[name] and {type="file"} or nil end,
    getSaveDirectory=function() return "/tmp" end
  },
  graphics={getDimensions=function() return 1200,780 end}
}
dofile("studio-lua/main.lua")
local function press(key,ctrl,alt)
  modifiers.lctrl=ctrl or false
  modifiers.lalt=alt or false
  love.keypressed(key)
  modifiers.lctrl,modifiers.lalt=false,false
end
local function project()
  press("s",true)
  return assert(M.decode(files["projeto.lflash"]))
end
love.mousepressed(600,18,1) -- add second layer
assert(#project().layers==2)
press("f2")
press("a",true) -- clear existing name
love.textinput("Café Fundo")
press("return")
assert(project().layers[2].name=="Café Fundo")
press("f2")
press("a",true)
love.textinput(" ")
press("return") -- invalid; must remain in edit mode
love.textinput("Rascunho")
press("escape")
assert(project().layers[2].name=="Café Fundo",
  "Escape must cancel invalid rename instead of committing")
-- Move via sidebar ^ button, then undo and redo.
love.mousepressed(1155,100,1)
local moved=project()
assert(moved.currentLayer==1 and moved.layers[1].name=="Café Fundo")
press("z",true)
assert(project().layers[2].name=="Café Fundo")
press("y",true)
assert(project().layers[1].name=="Café Fundo")
-- Ctrl+Alt+Down returns the active layer to second position.
press("down",true,true)
assert(project().layers[2].name=="Café Fundo")
press("up",true,true)
assert(project().layers[1].name=="Café Fundo")
-- No-op move at upper boundary must not add an undo entry.
press("up",true,true)
assert(project().currentLayer==1)
press("z",true)
assert(project().layers[2].name=="Café Fundo")
assert(files["projeto.lflash.lflib"] and files["projeto.lflash.lfvec"])
print("OK: Studio rename dialog, mouse ordering, keyboard ordering, undo/redo and file save")
