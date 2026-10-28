-- Player 0.18: bounded local error logs + guarded callbacks.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Report=require("src.error_report")
local files={}
local writes=0
local fs={
  read=function(name) return files[name] end,
  write=function(name,contents)
    writes=writes+1
    files[name]=contents
    return true
  end
}
local logger=Report.new(fs)
local result=logger:record("media", "invalid sound decoder")
assert(result:find("media: invalid sound decoder",1,true))
assert(files["player-errors.log"]:find("invalid sound decoder",1,true))
logger:record("media","invalid sound decoder")
assert(writes==1,"identical per-frame errors must not fill disk")
local ok,value=logger:protect("test",function(x) return x*2 end,21)
assert(ok and value==42)
local good,reason=logger:protect("render",function()
  error("injected draw failure")
end)
assert(not good and tostring(reason):find("injected draw failure",1,true))
assert(files["player-errors.log"]:find("injected draw failure",1,true))
assert(logger.count==3)
-- Local logs must stay bounded even after many unrelated failures.
for i=1,100 do
  logger:record("stress."..i,("error message %d"):format(i)..
    string.rep("x",700))
end
assert(#files["player-errors.log"]<=32768)
local broken=Report.new({
  read=function() error("read-only sandbox") end,
  write=function() error("disk full") end
})
assert(broken:record("disk","cannot write"):find("cannot write",1,true),
  "logging errors must never crash the Player")
print("OK: Player 0.18 bounded local logs, callback errors, duplicate suppression")
