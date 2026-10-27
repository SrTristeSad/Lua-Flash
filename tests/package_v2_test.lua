-- LUAFGAME 2: named objects, states, conditions, legacy v1 reader and safety.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local V2=require("src.package_v2")
local Legacy=require("src.package")
local OldExample=require("src.game_example")
local Example=require("src.game_example_v2")
local Session=require("src.session")
local Transport=require("src.transport")
local Input=require("src.input")
local Interpolation=require("src.interpolation")

local g=Example.definition()
local bytes,err=V2.encode(g)
assert(bytes,err)
assert(bytes:sub(1,11)=="LUAFGAME 2\n")
local d,e=V2.decode(bytes)
assert(d,e)
assert(d.version==2 and d.title==g.title and #d.rules==5)
assert(#d.objects==3 and #d.states==1)
assert(V2.encode(d)==bytes,"v2 roundtrip")
assert(d.document.totalFrames==90)
local leg=Legacy.encode(OldExample.definition())
local backward,backErr=V2.decode(leg)
assert(backward,backErr)
assert(backward.version==1 and #backward.rules==4)
assert(V2.encode(backward)==leg,"v1 bytes must be preserved")

local transport=Transport.new(d.document)
transport.playing=true
local session=Session.new(d,transport)
local ball={type="pointerup",clicked=true,hit={layer=2,shape=1}}
local shine={type="pointerup",clicked=true,hit={layer=2,shape=2}}
local sky={type="pointerup",clicked=true,hit={layer=1,shape=1}}
assert(session:dispatch(ball) and session.states.toques==1 and session.score==0)
assert(session:dispatch(ball) and session.states.toques==2 and session.score==1)
assert(session:dispatch(shine) and session.score==2)
assert(session:dispatch(sky) and session.score==1)
transport:seek(40)
assert(session:dispatch({type="keydown",key="z"}) and transport.position==1)
assert(not session:dispatch({type="keydown",key="x"}))
assert(session:dispatch(ball) and session.score==2 and session.states.toques==3)
for i=1,4 do session:dispatch(shine) end
assert(session.won and session.score==6 and not session.active and not transport.playing)
assert(not session:dispatch(ball))

local copy=Example.definition()
copy.states[1].id="bad key"
assert(not V2.encode(copy))
copy=Example.definition()
copy.objects[2].id="bola"
assert(not V2.encode(copy),"duplicated object id")
copy=Example.definition()
copy.objects[2].layer=2;copy.objects[2].shape=1
assert(not V2.encode(copy),"duplicate binding")
copy=Example.definition()
copy.rules[2].when.id="missing"
assert(not V2.encode(copy),"unknown state in condition")
copy=Example.definition()
copy.rules[2].when.op="EXEC"
assert(not V2.encode(copy),"condition opcode not allowed")
copy=Example.definition()
copy.rules[1].action="EVAL"
assert(not V2.encode(copy),"unknown action")
copy=Example.definition()
copy.rules[1].value=999999999
assert(not V2.encode(copy),"bounded variable delta")

local malformed={
  bytes.."garbage",
  bytes:sub(1,#bytes-14),
  bytes:gsub("LUAFGAME 2","LUAFGAME 3",1),
  bytes:gsub("SCENE_BYTES\t","SCENE_BYTES\t999999",1),
  bytes:gsub("RULE\tCLICKID\tbola\tADD","RULE\tCLICKID\tbola\tLOAD",1),
  bytes:gsub("OBJECT\tbola\t2\t1","OBJECT\tbola\t22\t1",1),
  bytes:gsub("STATE\ttoques\t0","STATE\ttoques\t999999999",1),
  bytes:gsub("RULE\tKEY\tz\tSEEK","RULE\tKEY\tescape\tSEEK",1),
  bytes:gsub("RULE\tCLICKID\tbola\tSCORE\t1","RULE\tCLICKID\tmissing\tSCORE\t1",1),
  "LUAFGAME 2\nTITLE\tbad\nRULE\tCLICKID\tbola\tEVAL\n"
}
for i,payload in ipairs(malformed) do
  assert(not V2.decode(payload),"malformed payload #"..i.." should be rejected")
end

-- Validate click hit routing into session using actual v2 object alias.
local route=Input.new()
local sampler=Interpolation.new(d.document)
local vp={x=0,y=0,w=800,h=450}
local down=route:pointer("down","mouse",1,127,277,d.document,1,vp,sampler)
local up=route:pointer("up","mouse",1,127,277,d.document,1,vp,sampler)
assert(down.hit and up.clicked)
local gameSession=Session.new(d,Transport.new(d.document))
assert(gameSession:dispatch(up) and gameSession.states.toques==1)

-- Condition operators and SET state action.
local advanced=Example.definition()
advanced.rules={
  {event="KEY",target="q",action="SET",variable="toques",value=10},
  {event="KEY",target="x",action="SCORE",value=2,
    when={id="toques",op="EQ",value=10}},
  {event="KEY",target="y",action="SCORE",value=1,
    when={id="toques",op="LE",value=10}}
}
local newer=assert(V2.decode(assert(V2.encode(advanced))))
local state=Session.new(newer,Transport.new(newer.document))
assert(not state:dispatch({type="keydown",key="x"}))
assert(state:dispatch({type="keydown",key="q"}) and state.states.toques==10)
assert(state:dispatch({type="keydown",key="x"}) and state.score==2)
assert(state:dispatch({type="keydown",key="y"}) and state.score==3)
print("OK: LUAFGAME 2 roundtrip, legacy v1, names, conditions, state and malformed packages")
