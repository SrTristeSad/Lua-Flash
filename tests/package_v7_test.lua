-- Player 0.12: LUAFGAME 7 transform rules, rotated alpha hit-tests and collisions.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Package=require("src.package_v7")
local Previous=require("src.package_v6")
local Ex=require("src.game_example_v7")
local Ex6=require("src.game_example_v6")
local Ex5=require("src.game_example_v5")
local Ex4=require("src.game_example_v4")
local Ex3=require("src.game_example_v3")
local Ex2=require("src.game_example_v2")
local Ex1=require("src.game_example")
local Base=require("src.package")
local T=require("src.sprite_transform")
local Media=require("src.media_runtime")
local Input=require("src.input")
local Session=require("src.session")
local Transport=require("src.transport")
local Sampler=require("src.interpolation")
local Mask=require("src.pixel_mask")
local Collision=require("src.collision")
local bytes=Ex.bytes()
assert(bytes:sub(1,11)=="LUAFGAME 7\n")
local game,err=Package.decode(bytes)
assert(game,err)
assert(game.version==7 and #game.transforms==1)
assert(Package.encode(game)==bytes)
for _,old in ipairs({
  assert(Base.encode(Ex1.definition())),
  assert(Previous.encode(Ex2.definition())),
  assert(Previous.encode(Ex3.definition())),
  assert(Previous.encode(Ex4.definition())),
  assert(Previous.encode(Ex5.definition())),
  assert(Previous.encode(Ex6.definition()))
}) do
  local loaded,e=Package.decode(old)
  assert(loaded,e)
  assert(Package.encode(loaded)==old,"all old versions must preserve bytes")
end
local function reject(f)
  local g=Ex.definition()
  f(g)
  assert(not Package.encode(g),"invalid transform accepted")
end
reject(function(g) g.transforms[1].scaleX=0 end)
reject(function(g) g.transforms[1].scaleY=401 end)
reject(function(g) g.transforms[1].pivotX=101 end)
reject(function(g) g.transforms[1].pivotY=-1 end)
reject(function(g) g.transforms[1].index=99 end)
reject(function(g) g.transforms[1].angle=361 end)
reject(function(g) g.transforms[1].angle=0/0 end)
reject(function(g) g.transforms[2]={
  index=1,angle=0,scaleX=100,scaleY=100,pivotX=0,pivotY=0
} end)
for i,corrupted in ipairs({
  bytes.."trailer",bytes:sub(1,#bytes-10),
  bytes:gsub("LUAFGAME 7","LUAFGAME 8",1),
  bytes:gsub("TRANSFORM_COUNT\t1","TRANSFORM_COUNT\t99",1),
  bytes:gsub("TRANSFORM\t1\t45","TRANSFORM\t9\t45",1),
  bytes:gsub("BASE_BYTES\t","BASE_BYTES\t7",1),
}) do
  assert(not Package.decode(corrupted),"invalid package accepted #"..i)
end

-- Pure geometry: 90-degree turn around center maps right-half pixels downward.
local rect={kind="rect",points={0,0,40,20}}
local turn=T.build(rect,{angle=90,scaleX=100,scaleY=100,pivotX=50,pivotY=50})
local px,py=T.toWorld(turn,.75,.5)
assert(math.abs(px-20)<1e-7 and math.abs(py-20)<1e-7)
local u,v=T.toUV(turn,px,py)
assert(math.abs(u-.75)<1e-7 and math.abs(v-.5)<1e-7)
assert(math.abs(turn.points[1]-10)<1e-7 and math.abs(turn.points[3]-30)<1e-7)
local rightMask=Mask.build({getWidth=function() return 4 end,
 getHeight=function() return 4 end,
 getPixel=function(_,x,y) return 1,1,1,x>=2 and 1 or 0 end})
assert(T.contains(turn,rightMask,px,py))
local tx,ty=T.toWorld(turn,.25,.5)
assert(not T.contains(turn,rightMask,tx,ty))
-- AABB overlap without opaque rotated overlap must NOT be a collision.
local ghost={kind="rect",points={17,1,22,5}}
assert(Collision.overlap(turn,ghost),"broad-phase should accept candidate")
assert(not T.intersects(turn,rightMask,ghost,nil,
  function(x,y) return Mask.shapeContains(ghost,x,y) end))
local solid={kind="rect",points={17,17,23,24}}
assert(T.intersects(turn,rightMask,solid,nil,
  function(x,y) return Mask.shapeContains(solid,x,y) end))

local images,drawCalls,decoded=0,{},0
_G.love={
 filesystem={newFileData=function(data,name) return {data=data,name=name} end},
 image={newImageData=function()
   decoded=decoded+1
   return {getWidth=function() return 4 end,getHeight=function() return 4 end,
     getPixel=function(_,x,y) return 1,1,1,x>=2 and 1 or 0 end}
 end},
 graphics={
   newImage=function()
     images=images+1
     return {setFilter=function() end,getWidth=function() return 4 end,
       getHeight=function() return 4 end}
   end,
   push=function() end,pop=function() end,
   setScissor=function() end,translate=function() end,
   scale=function() end,setColor=function() end,
   draw=function(...) drawCalls[#drawCalls+1]={...} end
 },
 sound={newSoundData=function(data) return data end},
 audio={newSource=function()
   return {stop=function() end,play=function() end}
 end}
}
local media=Media.new(game)
local sampler=Sampler.new(game.document)
local shape=assert(media:shapeForObject("bola",1,sampler:sample(1)))
assert(shape.transformed and shape.angle>0)
local x,y=T.toWorld(shape,.875,.5)
local hx,hy=T.toWorld(shape,.125,.5)
assert(media:hit(x,y,1,sampler).sprite=="bola",
 "transformed opaque PNG must capture click")
local wrong=media:hit(hx,hy,1,sampler)
assert(not wrong or wrong.sprite~="bola",
 "transparent transformed PNG must not capture hit")
local routing=Input.new()
local vp={x=0,y=0,w=800,h=450}
routing:pointer("down","mouse",1,x,y,game.document,1,vp,sampler,media)
local click=routing:pointer("up","mouse",1,x,y,game.document,1,vp,sampler,media)
assert(click.clicked and click.hit.sprite=="bola")
local gameSession=Session.new(game,Transport.new(game.document))
assert(gameSession:dispatch(click) and gameSession.states.toques==1)
media:draw(game.document,0,0,800,450,1,sampler)
assert(#drawCalls>0)
local call=drawCalls[#drawCalls]
assert(math.abs(call[4]-math.pi/4)<1e-7,"LÖVE must render 45-degree rotated")
assert(call[5]>0 and call[6]>0,"scale must be positive")
assert(media:maskFor("estrela")==media:maskFor("estrela") and decoded==1)
media:release()

print("OK: Player 0.12 transform format, old games, rotated alpha hit and render")
