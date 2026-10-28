-- Lua-Flash Player 0.15: validated edits for v8/v9 sprite transform keyframes.
-- Pure model operations. Never run scripts from external game packages.
-- All operations are transactional: rejected edits leave a game unchanged.
local Tween=require("src.sprite_tween")
local Edit={}
local MAX_KEYS=2048
local function integer(n,lo,hi)
  return type(n)=="number" and n==n and n==math.floor(n) and n>=lo and n<=hi
end
local function round(n)
  return math.floor(n+0.5)
end
local function findTrack(g,index)
  for _,track in ipairs(g.tweens or {}) do
    if track.index==index then return track end
  end
end
local function countKeys(g)
  local count=0
  for _,t in ipairs(g.tweens or {}) do count=count+#t.keys end
  return count
end
local function locate(track,frame)
  for i,key in ipairs(track.keys) do
    if key.frame>=frame then return i,key.frame==frame end
  end
  return #track.keys+1,false
end
local function removeEasing(g,index,frame)
  if not g.easings then return end
  for i=#g.easings,1,-1 do
    local e=g.easings[i]
    if e.index==index and e.frame==frame then table.remove(g.easings,i) end
  end
end
function Edit.insert(g,index,frame)
  local t=findTrack(g,index)
  if not t then return nil,"sprite track not found" end
  if not integer(frame,2,g.document.totalFrames) then return nil,"invalid frame" end
  if #t.keys>=128 or countKeys(g)>=MAX_KEYS then return nil,"keyframe limit reached" end
  local at,exists=locate(t,frame)
  if exists then return nil,"keyframe already exists" end
  local pose=Tween.new(g):sample(index,frame)
  if not pose then return nil,"pose unavailable" end
  -- Round values to the integer fields required by the LUAFGAME serializer.
  local key={frame=frame,x=round(pose.x),y=round(pose.y),
    angle=math.max(-360,math.min(360,round(pose.angle))),
    scaleX=math.max(10,math.min(400,round(pose.scaleX))),
    scaleY=math.max(10,math.min(400,round(pose.scaleY)))}
  table.insert(t.keys,at,key)
  -- A split interval preserves its outgoing easing on the new right segment.
  if g.easings and at>1 and at<=#t.keys-1 then
    for _,e in ipairs(g.easings) do
      if e.index==index and e.frame==t.keys[at-1].frame then
        g.easings[#g.easings+1]={index=index,frame=frame,mode=e.mode}
        break
      end
    end
  end
  return at
end
function Edit.remove(g,index,selected)
  local t=findTrack(g,index)
  if not t then return nil,"sprite track not found" end
  if not integer(selected,2,#t.keys) then return nil,"first keyframe cannot be removed" end
  if #t.keys<=2 then return nil,"at least two keyframes are required" end
  local frame=t.keys[selected].frame
  table.remove(t.keys,selected)
  removeEasing(g,index,frame)
  return math.min(selected,#t.keys)
end
function Edit.moveFrame(g,index,selected,newFrame)
  local t=findTrack(g,index)
  if not t then return nil,"sprite track not found" end
  if not integer(selected,2,#t.keys) then return nil,"first frame is fixed" end
  local prior=t.keys[selected-1].frame
  local after=t.keys[selected+1] and t.keys[selected+1].frame or
    g.document.totalFrames+1
  if not integer(newFrame,prior+1,after-1) then
    return nil,"frame must stay between adjacent keys"
  end
  local key=t.keys[selected]
  local oldFrame=key.frame
  key.frame=newFrame
  for _,e in ipairs(g.easings or {}) do
    if e.index==index and e.frame==oldFrame then e.frame=newFrame end
  end
  return selected
end
function Edit.shiftPosition(g,index,selected,dx,dy)
  local t=findTrack(g,index)
  if not t then return nil,"sprite track not found" end
  if not integer(selected,1,#t.keys) or type(dx)~="number" or
     type(dy)~="number" or dx~=dx or dy~=dy then
    return nil,"invalid position edit"
  end
  local key=t.keys[selected]
  local x,y=round(key.x+dx),round(key.y+dy)
  if not integer(x,-4096,4096) or not integer(y,-4096,4096) then
    return nil,"position outside stage edit limits"
  end
  key.x=x;key.y=y
  return selected
end
function Edit.setPosition(g,index,selected,x,y)
  local t=findTrack(g,index)
  if not t then return nil,"sprite track not found" end
  if not integer(selected,1,#t.keys) or
     not integer(x,-4096,4096) or not integer(y,-4096,4096) then
    return nil,"invalid position"
  end
  t.keys[selected].x=x;t.keys[selected].y=y
  return selected
end
return Edit
