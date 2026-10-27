-- Cena de exemplo nativa, sem arquivos Adobe e sem scripts de terceiros.
local Model=require("src.model")
local Demo={}
function Demo.create()
  local d=Model.new(800,450,30)
  d.totalFrames=90
  local back=d.layers[1]
  back.name="Cenario"
  local bg=Model.makeShape("rect",{.09,.16,.26},1,0,0)
  bg.points={0,0,800,450}
  local floor=Model.makeShape("rect",{.14,.34,.29},1,0,360)
  floor.points={0,360,800,450}
  local sun=Model.makeShape("ellipse",{.99,.78,.29},1,565,32)
  sun.points={565,32,695,162}
  back.keys[1]={bg,floor,sun}
  local actor=Model.addLayer(d)
  actor.name="Animacao"
  for n=1,d.totalFrames do
    local phase=(n-1)/(d.totalFrames-1)
    local x=30+660*phase
    local y=190+math.sin(phase*math.pi*4)*40
    local body=Model.makeShape("ellipse",{.31,.72,.99},1,x,y)
    body.points={x,y,x+94,y+94}
    local shine=Model.makeShape("ellipse",{.78,.93,1},1,x+21,y+15)
    shine.points={x+21,y+15,x+46,y+40}
    actor.keys[n]={body,shine}
  end
  d.currentFrame=1
  d.currentLayer=2
  return d
end
return Demo
