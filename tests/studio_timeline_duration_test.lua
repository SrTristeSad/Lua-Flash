-- Global exposure-duration editing: native artwork, symbol and Bézier keys.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Library=require("src.symbol_library")
local Vector=require("src.vector_paths")
local Exposure=require("src.frame_exposure")
local Duration=require("src.timeline_duration")

local doc=Model.new(800,450,24)
Model.addLayer(doc)
doc.currentLayer=1
doc.currentFrame=2
doc.layers[2].locked=true -- global time edits must preserve locked content
for i,layer in ipairs(doc.layers) do
  layer.keys[4]={Model.makeShape("line",{.1*i,.2,.3},2,10*i,8*i)}
  layer.keys[7]={Model.makeShape("rect",{.4,.3,.2},2,20*i,15*i)}
end
local lib=Library.new()
local sym=assert(Library.create(lib,"graphic","Ball",{
  Model.makeShape("rect",{.3,.3,.3},1,1,2)
}))
for i=1,2 do
  assert(Library.place(lib,i,4,sym.id,10*i,10))
  assert(Library.place(lib,i,7,sym.id,15*i,10))
end
local vec=Vector.new()
for i=1,2 do
  for _,frame in ipairs({4,7}) do
    local p=assert(Vector.addPath(vec,i,frame,10*i,10,{1,0,0},2))
    assert(Vector.addNode(p,20*i,20))
  end
end
local scoped=Vector.scope(vec,sym.id,true)
local nativeScope=Vector.addPath(scoped,1,1,5,5,{1,0,0},1)
assert(nativeScope)
local original={Model.encode(doc),Library.encode(lib),Vector.encode(vec)}
local keyId=Library.at(lib,1,4)[1].uid
local vectorId=Vector.at(vec,1,4)[1].id
local tx=assert(Duration.plan(doc,lib,vec,2,"insert"))
assert(tx.affectedFrame==3 and tx.totalFrames==61)
assert(original[1]==Model.encode(doc) and original[2]==Library.encode(lib)
  and original[3]==Vector.encode(vec),"planning must not mutate anything")
tx.apply()
assert(doc.totalFrames==61 and doc.currentFrame==2)
for i,layer in ipairs(doc.layers) do
  assert(layer.keys[5] and layer.keys[8] and not layer.keys[4])
  assert(Exposure.exposure(layer,4,61).index==1)
  assert(Exposure.exposure(layer,5,61).index==5)
  assert(layer.locked==(i==2))
  assert(Library.at(lib,i,5)[1] and Vector.at(vec,i,5)[1])
  assert(not lib.tracks[i][4] and not vec.tracks[i][4])
end
assert(Library.at(lib,1,5)[1].uid==keyId)
assert(Vector.at(vec,1,5)[1].id==vectorId)
assert(Vector.scope(vec,sym.id).tracks[1][1][1].id==nativeScope.id,
  "symbol-local vectors must not be moved by stage ripple")
assert(not Duration.plan(doc,lib,vec,4,"remove"),
  "deleting any explicit key must refuse the entire transaction")
assert(doc.totalFrames==61)
local inverse=assert(Duration.plan(doc,lib,vec,2,"remove"))
assert(inverse.affectedFrame==3)
inverse.apply()
assert(doc.totalFrames==60 and doc.currentFrame==2)
assert(Model.encode(doc)==original[1])
assert(Library.encode(lib)==original[2])
assert(Vector.encode(vec)==original[3])
-- Reject a key present only in a sidecar even when the document layer is empty.
lib.tracks[1][3]={}
assert(not Duration.plan(doc,lib,vec,2,"remove"))
lib.tracks[1][3]=nil
vec.tracks[1][3]={}
assert(not Duration.plan(doc,lib,vec,2,"remove"))
vec.tracks[1][3]=nil
-- Refuse malformed/out-of-bounds input before any writes.
vec.tracks[3]={[1]={}}
assert(not Duration.plan(doc,lib,vec,2,"insert"))
vec.tracks[3]=nil
doc.totalFrames=10000
assert(not Duration.plan(doc,lib,vec,2,"insert"))
doc.totalFrames=1
assert(not Duration.plan(doc,lib,vec,1,"remove"))
doc.totalFrames=60
assert(not Duration.plan(doc,lib,vec,0,"insert"))
assert(not Duration.plan(doc,lib,vec,2,"unknown"))
doc.currentFrame=60
local extended=assert(Duration.plan(doc,lib,vec,60,"insert"))
extended.apply()
assert(doc.totalFrames==61 and doc.currentFrame==60)
local shortened=assert(Duration.plan(doc,lib,vec,61,"remove"))
shortened.apply()
assert(doc.totalFrames==60 and doc.currentFrame==60)
assert(Model.encode(assert(Model.decode(Model.encode(doc))))==Model.encode(doc))
assert(Library.encode(assert(Library.decode(Library.encode(lib))))==Library.encode(lib))
assert(Vector.encode(assert(Vector.decode(Vector.encode(vec))))==Vector.encode(vec))
print("OK: scene ripple duration preserves keyframes, symbol identities and vector scopes")

-- Actual Studio keyboard/buttons, undo/redo, rejection and persisted duration.
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
local function press(key,ctrl,shift)
 modifiers.lctrl=ctrl or false
 modifiers.lshift=shift or false
 love.keypressed(key)
 modifiers.lctrl,modifiers.lshift=false,false
end
local function project()
 press("s",true)
 return assert(Model.decode(files["projeto.lflash"]))
end
local first=project()
assert(first.totalFrames==60 and first.currentFrame==1)
press("f5")
assert(project().totalFrames==61,"F5 must extend root timeline")
press("z",true)
assert(project().totalFrames==60,"F5 must be undoable")
press("y",true)
assert(project().totalFrames==61,"F5 must be redoable")
press("f5",false,true)
assert(project().totalFrames==60,"Shift+F5 must remove safe trailing exposure")
-- Place a keyframe on frame 4. Inserting after frame 2 shifts it to frame 5.
for _=1,3 do press("right") end
press("f6")
press("left");press("left")
local before=project()
assert(before.currentFrame==2 and before.layers[1].keys[4])
press("f5")
local after=project()
assert(after.totalFrames==61 and after.currentFrame==2)
assert(after.layers[1].keys[5] and not after.layers[1].keys[4])
-- Removing the preceding unkeyed frame reverses the extension.
press("f5",false,true)
local restored=project()
assert(restored.totalFrames==60 and restored.layers[1].keys[4])
-- Deleting keyframe 4 through the time control is rejected, not destructive.
press("right") -- frame 3; next frame 4 has a key
press("f5",false,true)
local protected=project()
assert(protected.totalFrames==60 and protected.layers[1].keys[4])
-- Click buttons near bottom left (170 px timeline).
press("home")
love.mousepressed(20,780-170+97,1)
assert(project().totalFrames==61)
love.mousepressed(120,780-170+97,1)
assert(project().totalFrames==60)
assert(Model.decode(files["projeto.lflash"]))
assert(Library.decode(files["projeto.lflash.lflib"]))
assert(Vector.decode(files["projeto.lflash.lfvec"]))
print("OK: Studio F5/Shift+F5, clickable duration controls, undo and project save")
