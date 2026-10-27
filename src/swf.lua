-- Visualizador experimental: FWS/CWS, timeline e DefineShape 1/2/3 limitados.
-- NÃO interpreta ActionScript, imagens, som, sprites aninhados ou SWF LZMA (ZWS).
local Reader = require("src.reader")
local SWF = {}
local MAX_BYTES, MAX_TAGS, MAX_FRAMES = 32*1024*1024, 100000, 20000

local function rgb(r, alpha)
  local c={r:u8()/255,r:u8()/255,r:u8()/255,1}
  if alpha then c[4]=r:u8()/255 end
  return c
end
local function matrix(m)
  if not m then return {a=1,b=0,c=0,d=1,tx=0,ty=0} end
  return {a=m.a,b=m.b,c=m.c,d=m.d,tx=m.tx,ty=m.ty}
end
local function count(r)
  local n=r:u8()
  return n==255 and r:u16() or n
end
local function fills(r,alpha)
  local styles, n = {},count(r)
  if n>10000 then error("Estilos demais") end
  for i=1,n do
    local typ=r:u8()
    if typ~=0 then error("Somente preenchimentos solidos sao suportados") end
    styles[i]=rgb(r,alpha)
  end
  return styles
end
local function lines(r,alpha)
  local n=count(r)
  if n>10000 then error("Contornos demais") end
  for _=1,n do r:u16();rgb(r,alpha) end
end
local function shape(body,code)
  local r=Reader.new(body)
  local id=r:u16()
  local bounds=r:rect()
  if code==83 then return nil,"DefineShape4 nao implementado" end
  local alpha=(code==32)
  local styles=fills(r,alpha)
  lines(r,alpha)
  local fbits,lbits=r:bitsU(4),r:bitsU(4)
  local x,y,fill0,fill1=0,0,0,0
  local polygons,path={},{}
  local function flush()
    if #path>=6 then
      local c=styles[fill1~=0 and fill1 or fill0]
      if c then polygons[#polygons+1]={points=path,color=c} end
    end
    path={}
  end
  local function add(px,py)
    if #path==0 then path[1],path[2]=x/20,y/20 end
    path[#path+1],path[#path+1]=px/20,py/20
  end
  for _=1,50000 do
    if r:bitsU(1)==0 then
      local flags=r:bitsU(5)
      if flags==0 then flush();return {id=id,bounds=bounds,polygons=polygons} end
      flush()
      if flags%2==1 then local n=r:bitsU(5);x,y=r:bitsS(n),r:bitsS(n) end
      if math.floor(flags/2)%2==1 then fill0=r:bitsU(fbits) end
      if math.floor(flags/4)%2==1 then fill1=r:bitsU(fbits) end
      if math.floor(flags/8)%2==1 then r:bitsU(lbits) end
      if math.floor(flags/16)%2==1 then
        r:align()
        local more=fills(r,alpha);lines(r,alpha)
        for _,s in ipairs(more) do styles[#styles+1]=s end
        fbits,lbits=r:bitsU(4),r:bitsU(4)
      end
    else
      local straight=r:bitsU(1)==1
      local n=r:bitsU(4)+2
      if straight then
        local dx,dy=0,0
        if r:bitsU(1)==1 then
          dx,dy=r:bitsS(n),r:bitsS(n)
        elseif r:bitsU(1)==1 then dy=r:bitsS(n)
        else dx=r:bitsS(n) end
        add(x+dx,y+dy);x,y=x+dx,y+dy
      else
        local cx,cy,ax,ay=r:bitsS(n),r:bitsS(n),r:bitsS(n),r:bitsS(n)
        local px,py=x+cx,y+cy
        local ex,ey=px+ax,py+ay
        for j=1,8 do
          local t,mt=j/8,1-j/8
          add(mt*mt*x+2*mt*t*px+t*t*ex,mt*mt*y+2*mt*t*py+t*t*ey)
        end
        x,y=ex,ey
      end
    end
  end
  error("Forma excedeu limite de registros")
end

local function parse(bytes,decompress)
  if type(bytes)~="string" or #bytes<12 then error("SWF ausente ou truncado") end
  local signature=bytes:sub(1,3)
  if signature~="FWS" and signature~="CWS" and signature~="ZWS" then error("Assinatura SWF invalida") end
  local header=Reader.new(bytes,4)
  local version,declared=header:u8(),header:u32()
  if declared>MAX_BYTES or declared<12 then error("Tamanho descompactado SWF invalido") end
  if signature=="ZWS" then error("ZWS/LZMA ainda nao suportado") end
  if signature=="CWS" then
    if not decompress then error("CWS requer descompressor zlib") end
    local unpacked=decompress(bytes:sub(9))
    if type(unpacked)~="string" then error("Descompressao invalida") end
    bytes="FWS"..bytes:sub(4,8)..unpacked
  end
  if #bytes~=declared then error("Tamanho SWF divergente do cabecalho") end
  local r=Reader.new(bytes,9)
  local bounds=r:rect()
  local fps=r:u16()/256
  local advertisedFrames=r:u16()
  local movie={signature=signature,version=version,bounds=bounds,width=bounds.xmax-bounds.xmin,
    height=bounds.ymax-bounds.ymin,fps=fps>0 and fps or 12,advertisedFrames=advertisedFrames,
    frames={},definitions={},unsupported={},hasActionScript=false,tagCounts={},totalTags=0}
  if movie.width<=0 or movie.height<=0 then error("Palco SWF invalido") end
  local bg={1,1,1,1}
  local display={}
  while r.pos<=#bytes do
    movie.totalTags=movie.totalTags+1
    if movie.totalTags>MAX_TAGS then error("SWF com tags demais") end
    local h=r:u16()
    local code,len=math.floor(h/64),h%64
    if len==63 then len=r:u32() end
    if len>MAX_BYTES then error("Tag grande demais") end
    local body=r:bytes(len)
    movie.tagCounts[code]=(movie.tagCounts[code] or 0)+1
    if code==0 then break
    elseif code==9 then
      if #body<3 then error("Background invalido") end
      bg=rgb(Reader.new(body),false)
    elseif code==2 or code==22 or code==32 or code==83 then
      local ok,def,err=pcall(shape,body,code)
      if ok and def then movie.definitions[def.id]=def
      else movie.unsupported[#movie.unsupported+1]=tostring(ok and err or def) end
    elseif code==4 then
      local p=Reader.new(body)
      local id,depth=p:u16(),p:u16()
      display[depth]={id=id,matrix=p:matrix()}
    elseif code==26 then
      local p=Reader.new(body)
      local flags,depth=p:u8(),p:u16()
      local current=display[depth]
      local item={id=current and current.id or nil,matrix=matrix(current and current.matrix)}
      if math.floor(flags/2)%2==1 then item.id=p:u16() end
      if math.floor(flags/4)%2==1 then item.matrix=p:matrix() end
      if item.id then display[depth]=item end
    elseif code==5 then
      local p=Reader.new(body);p:u16();display[p:u16()]=nil
    elseif code==28 then
      local p=Reader.new(body);display[p:u16()]=nil
    elseif code==12 or code==59 or code==82 then
      movie.hasActionScript=true
    elseif code==1 then
      if #movie.frames>=MAX_FRAMES then error("SWF excedeu maximo de quadros") end
      local objects={}
      for depth,item in pairs(display) do
        objects[#objects+1]={depth=depth,id=item.id,matrix=matrix(item.matrix)}
      end
      table.sort(objects,function(a,b) return a.depth<b.depth end)
      movie.frames[#movie.frames+1]={objects=objects,background={bg[1],bg[2],bg[3],bg[4]}}
    end
  end
  return movie
end
function SWF.parse(data,decompress)
  local ok,m=pcall(parse,data,decompress)
  if ok then return m end
  return nil,tostring(m)
end
return SWF