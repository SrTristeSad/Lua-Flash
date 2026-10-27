-- Integration and hostile-input tests for the data-only LUAFGAME 1 format.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package")
local Session=require("src.session")
local Transport=require("src.transport")
local Input=require("src.input")
local Interpolation=require("src.interpolation")
local Example=require("src.game_example")
local demo=Example.definition()
local encoded,err=Package.encode(demo)
assert(encoded,err)
assert(encoded:find("LUAFGAME 1\n",1,true)==1)
assert(encoded:find("\nENDGAME\n",1,true))
local parsed,decodeErr=Package.decode(encoded)
assert(parsed,decodeErr)
assert(parsed.title==demo.title and parsed.duration==30 and parsed.goal==8)
assert(#parsed.rules==4 and parsed.smooth and parsed.document.totalFrames==90)
assert(Package.encode(parsed)==encoded,"round-trip must be lossless")
assert(not Package.decode("print(os.execute('echo BAD'))"),"never interpret Lua code")
assert(not Package.decode(encoded.."garbage"),"reject appended data")
assert(not Package.decode(encoded:sub(1,#encoded-10)),"reject truncated data")
assert(not Package.decode(encoded:gsub("SCENE_BYTES\t","SCENE_BYTES\t9999",1)),"reject length mismatch")
assert(not Package.decode(encoded:gsub("LUAFGAME 1","LUAFGAME 2",1)),"reject unrecognized version")
assert(not Package.decode(encoded:gsub("RULE\tCLICK\t2\t1","RULE\tCLICK\t222\t1",1)),
  "reject invalid target layers")
assert(not Package.decode(encoded:gsub("RULE\tKEY\tz\tSEEK","RULE\tKEY\tescape\tSEEK",1)),
  "reserved keyboard shortcuts are forbidden")
assert(not Package.decode(encoded:gsub("RULE\tKEY\tz\tSEEK\t1","RULE\tKEY\tz\tEXEC\t1",1)),
  "disallowed opcodes must be rejected")
local invalid=Example.definition()
invalid.rules[1].action="LOAD"
assert(not Package.encode(invalid),"unknown instructions must not serialize")

local t=Transport.new(parsed.document)
t.playing=true
local s=Session.new(parsed,t)
local actor={clicked=true,hit={layer=2,shape=1},type="pointerup"}
local shine={clicked=true,hit={layer=2,shape=2},type="pointerup"}
local background={clicked=true,hit={layer=1,shape=1},type="pointerup"}
assert(s:dispatch(actor) and s.score==1)
assert(s:dispatch(shine) and s.score==2)
assert(s:dispatch(background) and s.score==1)
assert(not s:dispatch({clicked=true,hit={layer=1,shape=2}}))
t:seek(40)
assert(s:dispatch({type="keydown",key="z"}) and t.position==1)
assert(not s:dispatch({type="keydown",key="q"}))
s:update(.25)
assert(s.remaining==29.75)
t.playing=false
s:update(.25)
assert(s.remaining==29.75,"pause must freeze timer")
t.playing=true
for i=1,7 do assert(s:dispatch(actor)) end
assert(s.won and not s.active and s.score>=s.definition.goal and not t.playing)
assert(not s:dispatch(actor),"no scoring after finishing")
local s2=Session.new(parsed,Transport.new(parsed.document))
s2.transport.playing=true
for i=1,200 do s2:update(.25) end
assert(not s2.active and s2.remaining==0 and not s2.won,"timeout")
assert(not s2:dispatch(actor))
-- End-to-end clickable package target, with Stage -> Point mapping.
local route=Input.new()
local viewport={x=0,y=0,w=800,h=450}
local sampler=Interpolation.new(parsed.document)
local down=route:pointer("down","mouse",1,127,277,parsed.document,1,viewport,sampler)
local up=route:pointer("up","mouse",1,127,277,parsed.document,1,viewport,sampler)
assert(down.hit and down.hit.layer==2 and up.clicked)
local s3=Session.new(parsed,Transport.new(parsed.document))
assert(s3:dispatch(up) and s3.score==1)
print("OK: LUAFGAME 1 decode/encode, hostile data, input rules, score, victory and timeout")
