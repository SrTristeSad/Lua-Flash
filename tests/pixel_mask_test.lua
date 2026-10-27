-- Player 0.10: transparent pixels, sprite collisions and reusable frame caches.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local Mask=require("src.pixel_mask")
local Media=require("src.media_runtime")
local Example=require("src.game_example_v6")
local Interpolation=require("src.interpolation")
local Input=require("src.input")
local Session=require("src.session")
local Transport=require("src.transport")
local Package=require("src.package_v6")
local game=assert(Package.decode(Example.bytes()))

local readCount=0
local imageData={
  getWidth=function() return 4 end,
  getHeight=function() return 4 end,
  getPixel=function(_,x,y)
    readCount=readCount+1
    return 1,1,1,x>=2 and 1 or 0
  end
}
local m=Mask.build(imageData)
assert(not m.opaque and not m.empty and readCount==16)
local rect={kind="rect",points={0,0,40,40}}
assert(not Mask.contains(m,rect,5,5),"transparent PNG left half must ignore clicks")
assert(Mask.contains(m,rect,35,5),"opaque PNG right half must accept clicks")
assert(not Mask.contains(m,rect,40,5),"right boundary excluded")
assert(Mask.contains(m,rect,21,39))
local transparent={kind="rect",points={0,0,15,40}}
local opaque={kind="rect",points={28,0,38,40}}
assert(not Mask.overlap(m,rect,nil,transparent),"AABB-only overlap is not collision")
assert(Mask.overlap(m,rect,nil,opaque),"overlapping opaque pixels collide")
local ellipse={kind="ellipse",points={0,0,18,40}}
assert(not Mask.overlapShape(m,rect,ellipse))
local ellipse2={kind="ellipse",points={22,0,40,40}}
assert(Mask.overlapShape(m,rect,ellipse2))
local empty=Mask.build({getWidth=function() return 1 end,
  getHeight=function() return 1 end,getPixel=function() return 0,0,0,0 end})
assert(empty.empty and not Mask.contains(empty,rect,20,20))
assert(not Mask.overlap(empty,rect,nil,opaque))
local fully=Mask.build({getWidth=function() return 1 end,
  getHeight=function() return 1 end,getPixel=function() return 0,0,0,1 end})
assert(fully.opaque and Mask.contains(fully,rect,10,10))

local numDecodes,rendered=0,0
_G.love={
  filesystem={newFileData=function(data,name) return {name=name,data=data} end},
  image={newImageData=function(file)
    numDecodes=numDecodes+1
    assert(file.name:match("%.png$"))
    return imageData
  end},
  graphics={
    newImage=function()
      return {setFilter=function() end,getWidth=function() return 4 end,
        getHeight=function() return 4 end}
    end,
    push=function() end,pop=function() end,setScissor=function() end,
    translate=function() end,scale=function() end,setColor=function() end,
    draw=function() rendered=rendered+1 end
  },
  sound={newSoundData=function(file) return file end},
  audio={newSource=function() return {stop=function() end,play=function() end} end}
}
local media=Media.new(game)
local sampler=Interpolation.new(game.document)
local first=assert(media:spriteRect(1,1))
local p=first.points
assert(p[1]==95 and p[3]==159)
assert(media:hit(p[1]+56,p[2]+32,1,sampler).sprite=="bola")
assert(media:hit(p[1]+8,p[2]+32,1,sampler)==nil,"transparent region cannot hit")
assert(media:maskFor("estrela")==media:maskFor("estrela"))
assert(media.maskBuilds==1 and numDecodes==1,"mask should be cached per resource")
-- A new animated PNG can have its own mask; then reuse the same cached bitmap.
local nextRect=assert(media:spriteRect(1,8,sampler:sample(8)))
local nextP=nextRect.points
local alt=assert(media:hit(nextP[1]+56,nextP[2]+32,8,sampler))
assert(alt.sprite=="bola")
assert(media.maskBuilds==2 and numDecodes==2)
for i=1,8 do media:hit(p[1]+56,p[2]+32,1,sampler) end
assert(media.maskBuilds==2 and numDecodes==2)

local route=Input.new()
local vp={x=0,y=0,w=800,h=450}
local down=route:pointer("down","mouse",1,p[1]+8,p[2]+32,
  game.document,1,vp,sampler,media)
local up=route:pointer("up","mouse",1,p[1]+8,p[2]+32,
  game.document,1,vp,sampler,media)
assert(down.hit==nil or not down.hit.sprite)
assert(up.hit==nil or not up.hit.sprite)
local d2=route:pointer("down","mouse",1,p[1]+56,p[2]+32,
  game.document,1,vp,sampler,media)
local u2=route:pointer("up","mouse",1,p[1]+56,p[2]+32,
  game.document,1,vp,sampler,media)
assert(d2.hit and d2.hit.sprite=="bola" and u2.clicked)

-- Collision with the barrier must be verified by the opaque pixels.
local transport=Transport.new(game.document)
local session=Session.new(game,transport)
local scene=sampler:sample(23)
assert(media:collides("bola","barreira",23,scene))
transport:seek(23)
assert(session:checkCollisions(sampler,media) and session.states.choques==1)
assert(not session:checkCollisions(sampler,media))
transport:seek(45)
session:checkCollisions(sampler,media)
transport:seek(23)
assert(session:checkCollisions(sampler,media))

-- Interpolation is immutable and computed only once per position.
local a=sampler:sample(23.25)
local computations=sampler.computations
assert(a==sampler:sample(23.25))
assert(sampler.computations==computations)
local b=sampler:sample(23.5)
assert(a~=b and sampler.computations==computations+1)
assert(game.document.layers[2].keys[23]~=a.layers[2].keys[1])
media:draw(game.document,0,0,800,450,8,sampler)
assert(rendered>0)
media:release()
print("OK: Player 0.10 alpha hit testing, collision masks, lazy caching and interpolation reuse")
