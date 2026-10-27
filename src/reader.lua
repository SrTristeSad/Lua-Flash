-- Leitura de inteiros little-endian e campos de bits SWF, sem bitops.
local R = {}
R.__index = R
function R.new(data, pos)
  return setmetatable({data=data, pos=pos or 1, remain=0, bits=0}, R)
end
function R:check(n)
  if n < 0 or self.pos + n - 1 > #self.data then error("SWF truncado em "..(self.pos-1),2) end
end
function R:u8()
  self:check(1)
  local n=self.data:byte(self.pos); self.pos=self.pos+1; return n
end
function R:u16() local a,b=self:u8(),self:u8(); return a+b*256 end
function R:u32() local a,b,c,d=self:u8(),self:u8(),self:u8(),self:u8(); return a+b*256+c*65536+d*16777216 end
function R:bytes(n) self:check(n); local d=self.data:sub(self.pos,self.pos+n-1); self.pos=self.pos+n; return d end
function R:align() self.remain=0 end
function R:bitsU(n)
  if n < 0 or n > 32 then error("Largura de bits invalida") end
  local v=0
  for _=1,n do
    if self.remain==0 then self.bits=self:u8(); self.remain=8 end
    self.remain=self.remain-1
    v=v*2+math.floor(self.bits/2^self.remain)%2
  end
  return v
end
function R:bitsS(n)
  if n==0 then return 0 end
  local v=self:bitsU(n)
  if v>=2^(n-1) then return v-2^n end
  return v
end
function R:rect()
  self:align()
  local n=self:bitsU(5)
  if n < 1 or n > 31 then error("RECT invalido") end
  local r={xmin=self:bitsS(n)/20,xmax=self:bitsS(n)/20,
    ymin=self:bitsS(n)/20,ymax=self:bitsS(n)/20}
  self:align(); return r
end
function R:matrix()
  self:align()
  local m={a=1,b=0,c=0,d=1,tx=0,ty=0}
  if self:bitsU(1)==1 then
    local n=self:bitsU(5); m.a=self:bitsS(n)/65536; m.d=self:bitsS(n)/65536
  end
  if self:bitsU(1)==1 then
    local n=self:bitsU(5); m.c=self:bitsS(n)/65536; m.b=self:bitsS(n)/65536
  end
  local n=self:bitsU(5)
  m.tx=self:bitsS(n)/20; m.ty=self:bitsS(n)/20; self:align()
  return m
end
return R
