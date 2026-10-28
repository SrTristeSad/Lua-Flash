-- Timeline transaction unit tests: movement/duplication must update native and symbol tracks together.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Library=require("src.symbol_library")
local Ops=require("src.timeline_ops")

local function fresh()
  local doc=Model.new()
  local lib=Library.new()
  local shape=Model.makeShape("rect",{.8,.2,.1},2,10,20)
  shape.points={10,20,40,60}
  local symbol=assert(Library.create(lib,"graphic","Logo",{shape}))
  local layer=doc.layers[1]
  layer.keys[1]={}
  layer.keys[2]={Model.copy(shape)}
  layer.keys[4]={Model.copy(shape)}
  return doc,lib,symbol.id
end

do
  local doc,lib,id=fresh()
  local first=assert(Library.place(lib,1,2,id,20,30))
  Library.ensureKey(lib,1,4)
  assert(Library.at(lib,1,4)[1].uid==first.uid)
  local beforeDoc,beforeLib=Model.encode(doc),Library.encode(lib)
  local tx=assert(Ops.plan(doc,lib,1,{2,4},5,false))
  -- Plan must not mutate either document until caller records undo.
  assert(Model.encode(doc)==beforeDoc and Library.encode(lib)==beforeLib)
  tx.apply()
  assert(doc.layers[1].keys[2]==nil and doc.layers[1].keys[4]==nil)
  assert(doc.layers[1].keys[7] and doc.layers[1].keys[9])
  assert(not lib.tracks[1][2] and not lib.tracks[1][4])
  assert(Library.at(lib,1,7)[1].uid==first.uid)
  assert(Library.at(lib,1,9)[1].uid==first.uid)
  local restoredDoc=assert(Model.decode(beforeDoc))
  local restoredLib=assert(Library.decode(beforeLib))
  assert(restoredDoc.layers[1].keys[2] and restoredDoc.layers[1].keys[4])
  assert(Library.at(restoredLib,1,4)[1].uid==first.uid)
  print("OK: group move transfers instances and supports saved undo snapshots")
end

do
  local doc,lib,id=fresh()
  local instance=assert(Library.place(lib,1,2,id,20,30))
  Library.ensureKey(lib,1,4)
  local tx=assert(Ops.plan(doc,lib,1,{2,4},5,true))
  tx.apply()
  assert(doc.layers[1].keys[2] and doc.layers[1].keys[4])
  assert(doc.layers[1].keys[7] and doc.layers[1].keys[9])
  local duplicated=Library.at(lib,1,7)[1]
  assert(duplicated.uid~=instance.uid,"duplicate must have independent instance ID")
  assert(duplicated.uid==Library.at(lib,1,9)[1].uid,
    "one instance spanning multiple keys must retain its duplicated identity")
  assert(Library.at(lib,1,2)[1].uid==instance.uid)
  duplicated.x=777
  assert(Library.at(lib,1,2)[1].x==20,"duplicated instances must be deep copies")
  local saved=assert(Library.decode(Library.encode(lib)))
  assert(Library.at(saved,1,7)[1].uid==duplicated.uid)
  print("OK: group duplication creates stable independent instance IDs")
end

do
  local doc,lib,id=fresh()
  assert(Library.place(lib,1,2,id,20,30))
  local beforeDoc,beforeLib=Model.encode(doc),Library.encode(lib)
  assert(not Ops.plan(doc,lib,1,{1},4,false),"frame 1 must not move")
  assert(not Ops.plan(doc,lib,1,{2},2,true),"occupied main destination")
  assert(not Ops.plan(doc,lib,1,{2},-2,false),"negative destination")
  assert(not Ops.plan(doc,lib,1,{2},999,false),"out-of-range destination")
  Library.ensureKey(lib,1,6,true)
  assert(not Ops.plan(doc,lib,1,{2},4,false),
    "occupied symbol destination must reject entire operation")
  assert(Model.encode(doc)==beforeDoc)
  assert(lib.tracks[1][2] and not lib.tracks[1][4])
  lib.tracks[1][6]=nil
  assert(Library.encode(lib)==beforeLib)
  local tx=assert(Ops.plan(doc,lib,1,{1},5,true))
  tx.apply()
  assert(doc.layers[1].keys[1] and doc.layers[1].keys[6])
  print("OK: collisions, bounds and protected initial frame are atomic")
end

do
  local doc,lib,id=fresh()
  assert(Library.place(lib,1,2,id,4,5))
  -- A keyframe without an explicit sidecar key may move without creating a phantom key.
  local tx=assert(Ops.plan(doc,lib,1,{4},5,false))
  tx.apply()
  assert(doc.layers[1].keys[9] and not doc.layers[1].keys[4])
  assert(not lib.tracks[1][9])
  print("OK: legacy keys without symbol tracks remain supported")
end
