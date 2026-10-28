-- Group edits are atomic and undo-compatible across exposure keys.
package.path="./studio-lua/?.lua;./studio-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Library=require("src.symbol_library")
local Group=require("src.instance_group")
local function fresh()
  local doc=Model.new()
  local lib=Library.new()
  local rect=Model.makeShape("rect",{1,0,0},2,0,0)
  rect.points={0,0,10,10}
  local symbol=assert(Library.create(lib,"graphic","Shape",{rect}))
  local ids,placed={},{}
  for i,x in ipairs({20,50,110}) do
    local item=assert(Library.place(lib,1,1,symbol.id,x,i*20))
    ids[item.uid]=true
    placed[i]=item
  end
  return doc,lib,ids,placed
end
local function plan(doc,lib,ids,name,value)
  return assert(Group.plan(doc,lib,1,1,ids,name,value))
end
local function same(a,b) return math.abs(a-b)<.000001 end
do
  local doc,lib,ids,v=fresh()
  local before=Library.encode(lib)
  local tx=plan(doc,lib,ids,"left")
  assert(Library.encode(lib)==before,"planning must not mutate")
  tx.apply()
  local items=Library.at(lib,1,1)
  assert(same(items[1].x,items[2].x) and same(items[2].x,items[3].x))
  assert(doc.layers[1].keys[1],"group edit should preserve art")
  assert(Library.encode(assert(Library.decode(before)))==before,"undo snapshot must restore")
end
do
  for _,op in ipairs({"centerX","right","top","centerY","bottom"}) do
    local doc,lib,ids=fresh()
    local tx=plan(doc,lib,ids,op)
    tx.apply()
    local arr=Library.at(lib,1,1)
    if op=="centerX" or op=="right" then
      assert(same(arr[1].x,arr[2].x) and same(arr[2].x,arr[3].x))
    else
      assert(same(arr[1].y,arr[2].y) and same(arr[2].y,arr[3].y))
    end
  end
end
do
  local doc,lib,ids=fresh()
  local tx=plan(doc,lib,ids,"distributeX")
  tx.apply()
  local arr=Library.at(lib,1,1)
  assert(same(arr[2].x,65),"distribution should equalize center spacing")
  local saved=Library.encode(lib)
  assert(not Group.plan(doc,lib,1,1,{[arr[1].uid]=true,[arr[2].uid]=true},"distributeX"))
  assert(Library.encode(lib)==saved)
end
do
  local doc,lib,ids=fresh()
  local tx=plan(doc,lib,ids,"distributeY")
  tx.apply()
  local arr=Library.at(lib,1,1)
  assert(same(arr[2].y,40))
end
do
  local doc,lib,ids=fresh()
  local initial=Library.encode(lib)
  local tx=plan(doc,lib,ids,"move",{dx=7,dy=-9})
  assert(Library.encode(lib)==initial)
  tx.apply()
  for i,item in ipairs(Library.at(lib,1,1)) do
    assert(same(item.x,({20,50,110})[i]+7) and same(item.y,i*20-9))
  end
  local beforeScale=Library.encode(lib)
  tx=plan(doc,lib,ids,"scale",1.5)
  tx.apply()
  local items=Library.at(lib,1,1)
  assert(same(items[1].sx,1.5) and same(items[3].sx,1.5))
  assert(items[1].x<27 and items[3].x>117,"scale must expand around group pivot")
  tx=plan(doc,lib,ids,"rotate",90)
  tx.apply()
  assert(items[1].angle==90 and items[2].angle==90 and items[3].angle==90)
  assert(not Group.plan(doc,lib,1,1,ids,"scale",30),"invalid scale should be atomic")
  assert(not Group.plan(doc,lib,1,1,ids,"move",{dx=999999,dy=0}))
  assert(Library.encode(assert(Library.decode(beforeScale)))==beforeScale)
end
do
  local doc,lib,ids,items=fresh()
  local secondKey=Library.ensureKey(lib,1,5)
  assert(secondKey[1].uid==items[1].uid)
  local snapshot=Library.encode(lib)
  local tx=assert(Group.plan(doc,lib,1,6,ids,"move",{dx=9,dy=0}))
  assert(Library.encode(lib)==snapshot)
  tx.apply()
  assert(lib.tracks[1][6] and #lib.tracks[1][6]==3)
  assert(same(lib.tracks[1][6][1].x,29))
  assert(same(lib.tracks[1][5][1].x,20),"edit must not mutate prior exposure")
  local before=Library.encode(lib)
  doc.layers[1].locked=true
  assert(not Group.plan(doc,lib,1,6,ids,"right"))
  assert(Library.encode(lib)==before)
  doc.layers[1].locked=false
  assert(not Group.plan(doc,lib,2,6,ids,"right"))
  assert(not Group.plan(doc,lib,1,6,{[999]=true,[items[1].uid]=true},"right"))
end
print("OK: group alignment/distribution, transforms, atomic validation and exposure isolation")
