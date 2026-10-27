-- Lua-Flash 0.6 built-in showcase: collision events + persistent IDs across keys.
local Model=require("src.model")
local Scene=require("src.demo")
local Package=require("src.package_v3")
local Example={}
function Example.definition()
  local doc=Scene.create()
  local barrier=Model.addLayer(doc)
  barrier.name="Obstaculo"
  local rect=Model.makeShape("rect",{.96,.34,.27},2,330,140)
  rect.points={330,140,410,240}
  barrier.keys[1]={rect}
  local bindings={
    {id="barreira",layer=3,frame=1,shape=1}
  }
  for _,frame in ipairs({1,23,45,67,90}) do
    bindings[#bindings+1]={id="bola",layer=2,frame=frame,shape=1}
    bindings[#bindings+1]={id="brilho",layer=2,frame=frame,shape=2}
  end
  return {
    version=3,title="Bola e barreira - motor 0.6",
    duration=40,goal=8,smooth=true,
    document=doc,
    objects={{id="bola"},{id="brilho"},{id="barreira"}},
    bindings=bindings,
    states={{id="toques",value=0},{id="choques",value=0}},
    rules={
      {event="CLICKID",target="bola",action="ADD",variable="toques",value=1},
      {event="CLICKID",target="bola",action="SCORE",value=1,
        when={id="toques",op="GE",value=2}},
      {event="CLICKID",target="brilho",action="SCORE",value=1},
      {event="COLLIDE",target="bola",other="barreira",action="ADD",variable="choques",value=1},
      {event="COLLIDE",target="bola",other="barreira",action="SCORE",value=1},
      {event="KEY",target="z",action="SEEK",value=1}
    }
  }
end
function Example.bytes()
  return assert(Package.encode(Example.definition()))
end
return Example
