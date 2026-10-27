-- Explicit, fixed action dispatcher for LUAFGAME 1. No load(), dofile(), IO or network.
local S={}
S.__index=S
function S.new(definition,transport)
  return setmetatable({
    definition=definition,transport=transport,remaining=definition.duration,
    active=true,won=false,score=0,events=0,lastAction="Clique nos objetos do palco"
  },S)
end
function S:update(dt)
  if not self.active or not self.transport.playing or type(dt)~="number" or dt~=dt or dt<=0 then return end
  self.remaining=math.max(0,self.remaining-math.min(dt,.25))
  if self.remaining<=0 then
    self.active=false
    self.transport.playing=false
    self.lastAction="Tempo esgotado"
  end
end
function S:dispatch(event)
  if not self.active or type(event)~="table" then return false end
  local consumed=false
  for _,rule in ipairs(self.definition.rules) do
    local match=false
    if rule.event=="CLICK" and event.clicked and event.hit then
      match=rule.layer==event.hit.layer and rule.shape==event.hit.shape
    elseif rule.event=="KEY" and event.type=="keydown" then
      match=rule.key==event.key
    end
    if match then
      consumed=true
      self.events=self.events+1
      if rule.action=="SCORE" then
        self.score=math.max(0,self.score+rule.value)
        self.lastAction=rule.value>0 and ("+"..rule.value.." pontos") or (rule.value.." pontos")
        if self.score>=self.definition.goal then
          self.won=true;self.active=false;self.transport.playing=false
          self.lastAction="Objetivo alcancado!"
        end
      elseif rule.action=="SEEK" then
        self.transport:seek(rule.value)
        self.lastAction="Quadro "..rule.value
      elseif rule.action=="PAUSE" then
        self.transport.playing=false;self.lastAction="Pausado por uma regra"
      elseif rule.action=="PLAY" then
        self.transport.playing=true;self.lastAction="Reproduzindo por uma regra"
      end
    end
    if not self.active then break end
  end
  return consumed
end
return S
