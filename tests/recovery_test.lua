-- Player 0.17: per-project rotating recovery, corrupt fallback and diagnostics.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local R=require("src.recovery")
local P=require("src.package_v9")
local Ex=require("src.game_example_v9")
local D=require("src.diagnostics")
local game=assert(P.decode(Ex.bytes()))
local saved={}
local writes,forceFailure=0,false
local fs={
  read=function(path) return saved[path] end,
  write=function(path,bytes)
    if forceFailure then return nil,"disk failure" end
    writes=writes+1
    saved[path]=bytes
    return true
  end,
  createDirectory=function(path) assert(path=="recovery");return true end,
  remove=function(path) if saved[path] then saved[path]=nil;return true end;return false end
}
local projectKey=R.identity("scene-A.lfgame",Ex.bytes())
local otherKey=R.identity("scene-B.lfgame",Ex.bytes())
assert(projectKey~=otherKey,"projects with same contents but different names must be separate")
local a,b=R.new(fs,P,projectKey),R.new(fs,P,otherKey)
assert(not a:read() and not b:read())
local one,pathA=assert(a:save(game))
assert(pathA:match("%-a%.rec$") and one.sequence==1)
assert(#one.bytes==#Ex.bytes())
game.tweens[1].keys[2].x=47
local two,pathB=assert(a:save(game))
assert(pathB:match("%-b%.rec$") and two.sequence==2)
assert(two.game.tweens[1].keys[2].x==47)
assert(a:read().sequence==2)
assert(not b:read(),"recovery must not leak to another project")
-- Interrupted newest slot: the previous valid slot still restores.
saved[pathB]=saved[pathB]:sub(1,math.floor(#saved[pathB]/2))
local fallback=assert(a:read())
assert(fallback.sequence==1 and fallback.game.tweens[1].keys[2].x~=47)
assert(not a:readSlot("b"))
-- Wrong-key substitution cannot move a recovery between projects.
saved["recovery/"..otherKey.."-a.rec"]=saved[pathA]
assert(not b:read(),"different project must reject swapped recovery bytes")
saved["recovery/"..otherKey.."-a.rec"]=nil
-- Next write keeps fallback and rebuilds the damaged slot.
local three,pathC=assert(a:save(game))
assert(pathC==pathB and three.sequence==2)
local stored=saved[pathB]
saved[pathB]=stored:sub(1,#stored-1).."x"
assert(a:read().sequence==1,"checksum must reject a corrupted body")
saved[pathB]=stored
assert(a:read().sequence==2)
-- Failed writes must not destroy other slot.
forceFailure=true
assert(not a:save(game))
forceFailure=false
assert(a:read().sequence==2)
-- Invalid or oversized game should never become a recovery.
local invalid=assert(P.decode(Ex.bytes()))
invalid.tweens[1].keys[2].x=10000
local beforeWrites=writes
assert(not a:save(invalid))
assert(writes==beforeWrites)
assert(a:read().sequence==2)
-- Multi-generation rotation.
game.tweens[1].keys[2].x=60
local nextSave,nextPath=assert(a:save(game))
assert(nextSave.sequence==3 and nextPath==pathA)
assert(a:read().game.tweens[1].keys[2].x==60)
a:clear()
assert(not a:read())
assert(not saved[pathA] and not saved[pathB])

local d=D.new()
for i=1,180 do d:update(1/60) end
local metrics=d:snapshot(game,nil,nil)
assert(metrics.fps>59 and metrics.fps<61)
assert(metrics.keys==#game.tweens[1].keys and metrics.tracks==1)
assert(metrics.resources==#game.resources)
assert(metrics.memoryKB>0 and metrics.worstMs>=16)
assert(d.samples==180)
d:update(-1);d:update(0/0);d:update(100)
assert(d.samples==180,"malformed frame durations should be ignored")
print("OK: Player 0.17 recovery isolation, 2-slot fallback, integrity, diagnostics")
