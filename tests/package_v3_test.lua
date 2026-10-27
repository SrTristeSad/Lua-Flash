-- Player 0.6: named object bindings survive keyframe index reorder; collision edge events.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local P=require("src.package_v3")
local P2=require("src.package_v2")
local Legacy=require("src.package")
local Ex=require("src.game_example_v3")
local Ex2=require("src.game_example_v2")
local Ex1=require("src.game_example")
local Session=require("src.session")
local Transport=require("src.transport")
local Collision=require("src.collision")
local Interpolation=require("src.interpolation")
local Model=require("src.model")

local definition=Ex.definition()
local bytes,err=P.encode(definition)
assert(bytes,err)
assert(bytes:sub(1,11)=="LUAFGAME 3\n")
local game,readError=P.decode(bytes)
assert(game,readError)
assert(game.version==3 and #game.objects==3 and #game.bindings==11)
assert(P.encode(game)==bytes,"byte-for-byte v3 roundtrip")
assert(game.title==definition.title and game.goal==8)

-- Both older formats open through the newest loader and serialize without migration.
local older=assert(Legacy.encode(Ex1.definition()))
local intermediate=assert(P2.encode(Ex2.definition()))
local a,ae=P.decode(older);assert(a,ae)
local b,be=P.decode(intermediate);assert(b,be)
assert(a.version==1 and b.version==2)
assert(P.encode(a)==older and P.encode(b)==intermediate,"preserve legacy bytes")

-- Collision in model space respects geometry and rejects separated shapes.
local rect=Model.makeShape("rect",{1,0,0},1,20,20)
rect.points={20,20,80,80}
local ball=Model.makeShape("ellipse",{0,1,0},1,70,30)
ball.points={70,30,90,50}
assert(Collision.overlap(rect,ball))
local far=Model.makeShape("ellipse",{0,0,1},1,200,200)
far.points={200,200,240,240}
assert(not Collision.overlap(rect,far))
local another=Model.makeShape("rect",{1,1,0},1,40,40)
another.points={40,40,55,55}
assert(Collision.overlap(rect,another))

local clock=Transport.new(game.document)
clock.playing=true
local session=Session.new(game,clock)
clock:seek(1)
assert(not session:checkCollisions(Interpolation.new(game.document)))
clock:seek(23)
assert(session:checkCollisions(Interpolation.new(game.document)),"new collision enters")
assert(session.states.choques==1 and session.score==1)
assert(not session:checkCollisions(Interpolation.new(game.document)),"no repeat each tick")
assert(session.states.choques==1)
clock:seek(45)
assert(not session:checkCollisions(Interpolation.new(game.document)),"collision exited")
clock:seek(23)
assert(session:checkCollisions(Interpolation.new(game.document)),"re-entry triggers")
assert(session.states.choques==2 and session.score==2)

-- ID remains attached to object despite changing shape order between keys.
local modified=Ex.definition()
local actor=modified.document.layers[2]
actor.keys[45][1],actor.keys[45][2]=actor.keys[45][2],actor.keys[45][1]
for _,binding in ipairs(modified.bindings) do
  if binding.layer==2 and binding.frame==45 then
    binding.shape=binding.shape==1 and 2 or 1
  end
end
local encoded=assert(P.encode(modified))
local decoded=assert(P.decode(encoded))
local ses=Session.new(decoded,Transport.new(decoded.document))
assert(ses:objectForHit({layer=2,shape=1},23)=="bola")
assert(ses:objectForHit({layer=2,shape=2},45)=="bola")
assert(ses:objectForHit({layer=2,shape=1},45)=="brilho")
assert(ses:objectForHit({layer=2,shape=1},46)=="brilho")
local shape=Collision.resolve(decoded,"bola",45)
assert(shape==decoded.document.layers[2].keys[45][2],"resolved the same object")
assert(ses:dispatch({type="pointerup",clicked=true,frame=45,
  hit={layer=2,shape=2}}) and ses.states.toques==1)
assert(ses:dispatch({type="pointerup",clicked=true,frame=46,
  hit={layer=2,shape=2}}) and ses.score==1)
assert(not ses:dispatch({type="pointerup",clicked=true,frame=45,
  hit={layer=99,shape=1}}))

-- Key rule and conditional score remain usable with V3.
ses.transport:seek(40)
assert(ses:dispatch({type="keydown",key="z"}) and ses.transport:frame()==1)

local invalid=Ex.definition()
invalid.bindings[2].frame=2000
assert(not P.encode(invalid),"bound frame outside timeline")
invalid=Ex.definition()
invalid.bindings[2].shape=999
assert(not P.encode(invalid),"missing shape")
invalid=Ex.definition()
invalid.bindings[3].shape=1
assert(not P.encode(invalid),"duplicate shape binding")
invalid=Ex.definition()
invalid.objects[2].id="bola"
assert(not P.encode(invalid),"duplicate names")
invalid=Ex.definition()
invalid.rules[4].other="not_a_real_object"
assert(not P.encode(invalid),"collision with unknown ID")
invalid=Ex.definition()
invalid.rules[4].event="EXEC"
assert(not P.encode(invalid),"unsupported rules forbidden")
invalid=Ex.definition()
invalid.rules[4].target="barreira"
invalid.rules[4].other="barreira"
assert(not P.encode(invalid),"self collision invalid")
invalid=Ex.definition()
invalid.rules[1].action="LOAD"
assert(not P.encode(invalid),"untrusted opcodes blocked")

local malformed={
  bytes.."garbage",
  bytes:sub(1,#bytes-10),
  bytes:gsub("LUAFGAME 3","LUAFGAME 4",1),
  bytes:gsub("SCENE_BYTES\t","SCENE_BYTES\t9999",1),
  bytes:gsub("BIND\tbola\t2\t1\t1","BIND\tbola\t2\t10000\t1",1),
  bytes:gsub("OBJECT\tbola","OBJECT\tbola!!",1),
  bytes:gsub("COLLIDE\tbola\tbarreira","COLLIDE\tbola\tmissing",1),
  bytes:gsub("STATE\ttoques\t0","STATE\ttoques\t-1",1),
}
for i,payload in ipairs(malformed) do
  assert(not P.decode(payload),"malformed game must be rejected: "..i)
end
print("OK: LUAFGAME 3 roundtrip, v1/v2 compatibility, keyframe IDs, geometry and collision events")
