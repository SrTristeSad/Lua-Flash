-- Lua-Flash 0.5 showcase: exported data-only game with IDs and conditional state.
local Scene=require("src.demo")
local Package=require("src.package_v2")
local E={}
function E.definition()
  return {
    version=2,title="Bola Magica - desafio Lua-Flash",
    duration=40,goal=6,smooth=true,document=Scene.create(),
    objects={
      {id="bola",layer=2,shape=1},
      {id="brilho",layer=2,shape=2},
      {id="ceu",layer=1,shape=1}
    },
    states={{id="toques",value=0}},
    rules={
      {event="CLICKID",target="bola",action="ADD",variable="toques",value=1},
      {event="CLICKID",target="bola",action="SCORE",value=1,
        when={id="toques",op="GE",value=2}},
      {event="CLICKID",target="brilho",action="SCORE",value=1},
      {event="CLICKID",target="ceu",action="SCORE",value=-1},
      {event="KEY",target="z",action="SEEK",value=1}
    }
  }
end
function E.bytes()
  return assert(Package.encode(E.definition()))
end
return E
