-- Lua-Flash Player 0.27: bounded, robust CPU samples in update/draw paths.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local P=require("src.perf_monitor")
local now=0
local perf=P.new(function() return now end)
local empty=perf:stats("update")
assert(empty.avgMs==0 and empty.samples==0 and empty.total==0)
assert(not perf:record("invalid",.005))
assert(not perf:record("update",-1))
assert(not perf:record("update",0/0))
assert(not perf:record("update",math.huge))
assert(not perf:measure("draw",nil))
for i=1,1000 do
  assert(perf:record("draw",i%3==0 and .015 or .005))
  assert(perf:record("update",.001))
end
local draw=perf:stats("draw")
local update=perf:stats("update")
assert(draw.samples==120 and draw.total==1000)
assert(draw.maxMs>=14.99 and draw.maxMs<=15.01)
assert(draw.avgMs>7 and draw.avgMs<9)
assert(update.samples==120 and update.total==1000)
assert(math.abs(update.avgMs-1)<.0000001)
now=1
local start=perf:time()
now=1.008
assert(perf:measure("update",start))
assert(perf:stats("update").total==1001)
assert(perf:stats("update").avgMs>1)
assert(perf:stats("update").maxMs>7.99)
assert(perf:record("draw",90)) -- suspended process: clamp to 1 second
assert(perf:stats("draw").maxMs==1000)
local before=collectgarbage("count")
for i=1,40000 do
 perf:record("update",.001)
 perf:record("draw",.002)
end
collectgarbage("collect")
local after=collectgarbage("count")
assert(after-before<1500,"CPU monitor must not grow with session duration")
assert(perf:stats("draw").samples==120)
assert(perf:stats("update").total==41001)
perf:reset()
assert(perf:stats("draw").samples==0)
local broken=P.new(function() error("timer unavailable") end)
assert(not broken:time() and not broken:measure("update",1))
print("OK: Player 0.27 CPU draw/update rolling windows, strict bounds and 40k samples")
