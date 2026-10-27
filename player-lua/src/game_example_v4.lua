-- First-party, original artwork (16x16 PNG) and original short tone (WAV).
-- Demonstrates how external authors can embed media in LUAFGAME 4 files.
local Game=require("src.game_example_v3")
local Package=require("src.package_v4")
local E={}
local pngBase64="iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAPUlEQVR42mNgoAX4v0n3//+HQIxGE9aIRRM2miLNOA0hRTOGd0jVjGEIOZpRvDHqgsGQDkg1hOw8QZOcCwDY6eSyOTVzXgAAAABJRU5ErkJggg=="
local abc="ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local function unbase64(s)
  local out,bits,value={},0,0
  for i=1,#s do
    local ch=s:sub(i,i)
    if ch~="=" then
      local at=abc:find(ch,1,true)
      assert(at,"invalid embedded example base64")
      value=value*64+(at-1)
      bits=bits+6
      if bits>=8 then
        bits=bits-8
        local n=math.floor(value/2^bits)%256
        out[#out+1]=string.char(n)
        value=value%2^bits
      end
    end
  end
  return table.concat(out)
end
local function u16(n)
  return string.char(n%256,math.floor(n/256)%256)
end
local function u32(n)
  return u16(n%65536)..u16(math.floor(n/65536))
end
local function tone()
  local n=1600
  local samples={}
  for i=0,n-1 do
    local envelope=math.min(1,i/100)*math.min(1,(n-i-1)/350)
    local s=math.floor(math.sin(i*2*math.pi*620/8000)*envelope*10000)
    if s<0 then s=65536+s end
    samples[#samples+1]=u16(s)
  end
  local data=table.concat(samples)
  return "RIFF"..u32(36+#data).."WAVEfmt "..u32(16)..u16(1)..u16(1)..
    u32(8000)..u32(16000)..u16(2)..u16(16)..
    "data"..u32(#data)..data
end
function E.definition()
  local game=Game.definition()
  game.version=4
  game.title="Bola sonora - imagens e efeitos"
  game.resources={
    {id="estrela",kind="PNG",data=unbase64(pngBase64)},
    {id="acerto",kind="WAV",data=tone()}
  }
  game.sprites={{asset="estrela",x=660,y=260,width=64,height=64}}
  game.cues={
    {asset="acerto",event="CLICKID",target="bola",other="-"},
    {asset="acerto",event="COLLIDE",target="bola",other="barreira"},
    {asset="acerto",event="WIN",target="-",other="-"}
  }
  return game
end
function E.bytes()
  return assert(Package.encode(E.definition()))
end
return E
