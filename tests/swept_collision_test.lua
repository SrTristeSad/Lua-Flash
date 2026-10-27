-- Player 0.11: detect transient fast collisions without false teleport hits.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Model=require("src.model")
local Session=require("src.session")
local Transport=require("src.transport")
local Sampler=require("src.interpolation")
local function rect(x,y,w,h)
  local s=Model.makeShape("rect",{1,1,1},1,x,y)
  s.points={x,y,x+w,y+h}
  return s
end
local function ellipse(x,y)
  local s=Model.makeShape("ellipse",{.2,.8,1},1,x,y)
  s.points={x,y,x+10,y+10}
  return s
end
local function setup(path)
  local d=Model.new(100,100,30)
  d.totalFrames=30
  local barrier=d.layers[1]
  barrier.keys[1]={rect(50,40,6,24)}
  local actor=Model.addLayer(d)
  actor.name="mover"
  local bindings={{id="parede",layer=1,frame=1,shape=1}}
  for frame,x in pairs(path) do
    actor.keys[frame]={ellipse(x,45)}
    bindings[#bindings+1]={id="bola",layer=2,frame=frame,shape=1}
  end
  local game={
    version=3,document=d,duration=30,goal=5000,smooth=true,
    title="swept test",objects={{id="bola"},{id="parede"}},
    bindings=bindings,states={{id="impactos",value=0}},
    rules={{event="COLLIDE",target="bola",other="parede",
      action="ADD",variable="impactos",value=1}}
  }
  local transport=Transport.new(d)
  return Session.new(game,transport),transport,Sampler.new(d)
end

-- Without sweep, both endpoints are clear, but the actor crossed the obstacle.
local s,t,sampler=setup({[1]=5,[11]=85})
t:seek(11)
assert(not s:checkCollisions(sampler),"end-frame-only must not report transient hit")
assert(s.states.impactos==0)
t:seek(1)
assert(not s:checkCollisions(sampler),"manual seek to start is not a collision")
t:seek(11)
assert(s:checkCollisions(sampler,nil,1,false),"sweep should detect fast crossing")
assert(s.states.impactos==1 and s.events==1)
assert(not s:checkCollisions(sampler),"no repeated events after contact ends")
assert(s.states.impactos==1)
-- Explicit seek over the same path must NOT trigger collisions.
t:seek(1);s:checkCollisions(sampler)
t:seek(11)
assert(not s:checkCollisions(sampler))
assert(s.states.impactos==1)
-- Replaying the segment should trigger a new enter, after separation.
t:seek(1);s:checkCollisions(sampler)
t:seek(11)
assert(s:checkCollisions(sampler,nil,1,false))
assert(s.states.impactos==2)

-- Two separate entries through the same barrier during ONE frame update.
local s2,t2,i2=setup({[1]=5,[4]=49,[7]=85,[10]=49,[13]=5})
t2:seek(13)
assert(s2:checkCollisions(i2,nil,1,false))
assert(s2.states.impactos==2,
  "contact, separation and second contact should count as two events")
assert(not s2.colliding["bola:parede"],"endpoint is separated")
-- Each pair is prepared once, regardless of number of collision rules.
s2.definition.rules[#s2.definition.rules+1]={
  event="COLLIDE",target="parede",other="bola",action="SCORE",value=1}
local prepared=Session.new(s2.definition,Transport.new(s2.definition.document))
assert(#prepared.collisionPairs==1)

-- Loop boundary: at frame 1 the actor is touching, at final frame it is not.
local loopS,loopT,loopI=setup({[1]=47,[10]=84,[30]=84})
loopT:seek(30)
assert(not loopS:checkCollisions(loopI))
loopT:seek(1)
assert(loopS:checkCollisions(loopI,nil,30,true),"loop return to 1 must see contact")
assert(loopS.states.impactos==1)
assert(not loopS:checkCollisions(loopI),"touch should not repeat at same frame")
-- A second loop requires separation before another entry.
loopT:seek(30);loopS:checkCollisions(loopI)
loopT:seek(1)
assert(loopS:checkCollisions(loopI,nil,30,true))
assert(loopS.states.impactos==2)

-- Bounded work, even for a long fast-forward.
local longS,longT,longI=setup({[1]=5,[30]=85})
longT:seek(30)
longS:checkCollisions(longI,nil,1,false)
assert(longI.computations<=80,"limit swept intermediate scene evaluations")

print("OK: Player 0.11 continuous collision samples, re-entry, loops, seeking and budget")
