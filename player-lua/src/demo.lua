-- Animated native Player test; contains only five actor keyframes.
local Model=require("src.model")
local Demo={}
function Demo.create()
  local d=Model.new(800,450,30)
  d.totalFrames=90
  local background=d.layers[1]
  background.name="Paisagem"
  local sky=Model.makeShape("rect",{.09,.16,.26},1,0,0)
  sky.points={0,0,800,450}
  local floor=Model.makeShape("rect",{.14,.34,.29},1,0,360)
  floor.points={0,360,800,450}
  local sun=Model.makeShape("ellipse",{.99,.78,.29},1,565,32)
  sun.points={565,32,695,162}
  background.keys[1]={sky,floor,sun}
  local actor=Model.addLayer(d)
  actor.name="Bola animada"
  for _,point in ipairs({
    {1,80,230},{23,300,70},{45,580,225},{67,340,310},{90,82,230}
  }) do
    local n,x,y=point[1],point[2],point[3]
    local body=Model.makeShape("ellipse",{.31,.72,.99},1,x,y)
    body.points={x,y,x+94,y+94}
    local highlight=Model.makeShape("ellipse",{.78,.93,1},1,x+21,y+15)
    highlight.points={x+21,y+15,x+46,y+40}
    actor.keys[n]={body,highlight}
  end
  d.currentFrame=1
  d.currentLayer=2
  return d
end
return Demo
