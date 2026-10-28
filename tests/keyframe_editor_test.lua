-- Player 0.15: safe in-place keyframe edits and LUAFGAME 9 preservation.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Edit=require("src.keyframe_editor")
local Package=require("src.package_v9")
local Example=require("src.game_example_v9")
local Tween=require("src.sprite_tween")
local function fresh() return assert(Package.decode(Example.bytes())) end
local game=fresh()
local track=game.tweens[1]
assert(#track.keys==5 and #game.easings==4)
local original=track.keys[2]
local originalX=original.x
local at,reason=Edit.insert(game,1,12)
assert(at==2,reason)
assert(#track.keys==6 and track.keys[2].frame==12)
local initial=Tween.new(Example.definition()):sample(1,12)
assert(math.abs(track.keys[2].x-initial.x)<1)
assert(Package.validate(game),"insertion must preserve valid package")
assert(#game.easings==5,"split segment preserves easing on new segment")
local changed=Edit.setPosition(game,1,at,50,-25)
assert(changed==at and track.keys[at].x==50 and track.keys[at].y==-25)
assert(Edit.shiftPosition(game,1,at,5,10))
assert(track.keys[at].x==55 and track.keys[at].y==-15)
assert(Edit.moveFrame(game,1,at,13))
assert(track.keys[at].frame==13)
local movedEasing=false
for _,e in ipairs(game.easings) do
  if e.index==1 and e.frame==13 then movedEasing=true end
  assert(e.frame~=12,"old easing key must move along with the selected key")
end
assert(movedEasing)
local oldBytes=assert(Package.encode(game))
assert(Package.decode(oldBytes),"edited game must reimport")
assert(Edit.remove(game,1,at)==2)
assert(#track.keys==5 and Package.validate(game))
assert(#game.easings==4)
assert(track.keys[2].x==originalX,"removing inserted key leaves original intact")
local bytes=assert(Package.encode(game))
assert(#bytes==#Example.bytes() and bytes==Example.bytes(),
  "add/retime/delete round-trip should recover unmodified original game")

local function reject(action)
  local data=assert(Package.encode(game))
  local result=action()
  assert(not result,"expected invalid edit rejection")
  assert(Package.encode(game)==data,"rejected edit must not mutate package")
end
reject(function() return Edit.insert(game,1,1) end)
reject(function() return Edit.insert(game,1,23) end)
reject(function() return Edit.insert(game,1,9999) end)
reject(function() return Edit.remove(game,1,1) end)
reject(function() return Edit.moveFrame(game,1,1,2) end)
reject(function() return Edit.moveFrame(game,1,2,1) end)
reject(function() return Edit.moveFrame(game,1,2,45) end)
reject(function() return Edit.shiftPosition(game,1,2,10000,0) end)
reject(function() return Edit.setPosition(game,1,2,0/0,3) end)
reject(function() return Edit.moveFrame(game,100,2,5) end)
local last=#track.keys
assert(Edit.remove(game,1,last)==last-1)
assert(#track.keys==4 and Package.validate(game),
  "deleting final key must discard orphan easing")
assert(Edit.remove(game,1,#track.keys))
assert(Edit.remove(game,1,#track.keys))
assert(#track.keys==2 and Package.validate(game))
reject(function() return Edit.remove(game,1,2) end)
assert(Edit.shiftPosition(game,1,1,5,5),
  "initial pose may be moved while its frame remains fixed")
assert(Package.validate(game))
print("OK: Player 0.15 keyframe insertion, retiming, XY editing, deletion and validation")
