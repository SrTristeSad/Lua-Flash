-- Exportable first-party example of the exact same format third-party creators can use.
local Scene=require("src.demo")
local Package=require("src.package")
local D={}
function D.definition()
  return {
    title="Acerte a bola - pacote externo",
    duration=30,goal=8,smooth=true,
    document=Scene.create(),
    rules={
      {event="CLICK",layer=2,shape=1,action="SCORE",value=1},
      {event="CLICK",layer=1,shape=1,action="SCORE",value=-1},
      {event="KEY",key="z",action="SEEK",value=1}
    }
  }
end
function D.bytes()
  return assert(Package.encode(D.definition()))
end
return D
