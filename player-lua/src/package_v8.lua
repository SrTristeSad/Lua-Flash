-- Lua-Flash Player 0.13: LUAFGAME 8 sprite transform keyframes.
-- A strictly data-only envelope around v7. Versions 1..7 stay byte-identical.
local Previous=require("src.package_v7")
local P={}
local LIMIT=25*1024*1024
local MAX_TRACKS,MAX_KEYS=64,2048

local function int(n,a,b)
  return type(n)=="number" and n==n and n==math.floor(n) and n>=a and n<=b
end
local function split(line)
  local fields={}
  for value in (line.."\t"):gmatch("(.-)\t") do fields[#fields+1]=value end
  return fields
end
local function baseGame(game)
  local copy={}
  for k,v in pairs(game) do copy[k]=v end
  copy.version=7
  copy.tweens=nil
  return copy
end
function P.validate(g)
  if type(g)~="table" or g.version~=8 or type(g.tweens)~="table" or
     #g.tweens>MAX_TRACKS then return false,"invalid transform tracks" end
  local ok,err=Previous.validate(baseGame(g))
  if not ok then return false,err end
  local used,keysTotal={},0
  for _,track in ipairs(g.tweens) do
    if type(track)~="table" or not int(track.index,1,#g.sprites) or
       used[track.index] or type(track.keys)~="table" or
       #track.keys<2 or #track.keys>128 then
      return false,"invalid sprite track" end
    used[track.index]=true
    keysTotal=keysTotal+#track.keys
    if keysTotal>MAX_KEYS then return false,"too many tween keys" end
    local prior=0
    for _,key in ipairs(track.keys) do
      if type(key)~="table" or not int(key.frame,1,g.document.totalFrames) or
         key.frame<=prior or
         not int(key.x,-4096,4096) or not int(key.y,-4096,4096) or
         not int(key.angle,-360,360) or
         not int(key.scaleX,10,400) or not int(key.scaleY,10,400) then
        return false,"invalid tween key" end
      prior=key.frame
    end
    if track.keys[1].frame~=1 then
      return false,"sprite tracks must start at frame 1"
    end
  end
  return true
end
function P.encode(g)
  if type(g)~="table" or g.version~=8 then return Previous.encode(g) end
  local ok,err=P.validate(g)
  if not ok then return nil,err end
  local embedded,reason=Previous.encode(baseGame(g))
  if not embedded then return nil,reason end
  local chunks={"LUAFGAME 8\nBASE_BYTES\t"..#embedded.."\n",
    embedded,"\n","TWEEN_COUNT\t"..#g.tweens.."\n"}
  for _,t in ipairs(g.tweens) do
    chunks[#chunks+1]=table.concat({"TWEEN",t.index,#t.keys},"\t").."\n"
    for _,k in ipairs(t.keys) do
      chunks[#chunks+1]=table.concat({"KEY",k.frame,k.x,k.y,k.angle,
        k.scaleX,k.scaleY},"\t").."\n"
    end
  end
  chunks[#chunks+1]="ENDGAME8\n"
  local bytes=table.concat(chunks)
  if #bytes>LIMIT then return nil,"game exceeds size limit" end
  return bytes
end
local function parse(data)
  local cursor=1
  local function line()
    local e=data:find("\n",cursor,true)
    if not e or e-cursor>160 then error("invalid record",0) end
    local str=data:sub(cursor,e-1);cursor=e+1
    if str:find("\r",1,true) then error("CRLF not allowed",0) end
    return split(str)
  end
  local magic=line()
  if #magic~=1 or magic[1]~="LUAFGAME 8" then error("unknown package",0) end
  local f=line();local size=tonumber(f[2])
  if #f~=2 or f[1]~="BASE_BYTES" or not int(size,40,LIMIT-100) or
     cursor+size>#data then error("invalid embedded length",0) end
  local embedded=data:sub(cursor,cursor+size-1)
  cursor=cursor+size
  if data:sub(cursor,cursor)~="\n" then error("missing delimiter",0) end
  cursor=cursor+1
  local g,err=Previous.decode(embedded)
  if not g or g.version~=7 then
    error("invalid v7 base: "..tostring(err),0)
  end
  g.version=8;g.tweens={}
  local countLine=line()
  local count=tonumber(countLine[2])
  if #countLine~=2 or countLine[1]~="TWEEN_COUNT" or not int(count,0,MAX_TRACKS) then
    error("invalid tween count",0)
  end
  local total=0
  for _=1,count do
    local head=line()
    local index,n=tonumber(head[2]),tonumber(head[3])
    if #head~=3 or head[1]~="TWEEN" or not int(n,2,128) then
      error("invalid track header",0)
    end
    total=total+n
    if total>MAX_KEYS then error("too many tween keys",0) end
    local track={index=index,keys={}}
    for _=1,n do
      local fields=line()
      if #fields~=7 or fields[1]~="KEY" then error("invalid tween key",0) end
      track.keys[#track.keys+1]={
        frame=tonumber(fields[2]),x=tonumber(fields[3]),
        y=tonumber(fields[4]),angle=tonumber(fields[5]),
        scaleX=tonumber(fields[6]),scaleY=tonumber(fields[7])
      }
    end
    g.tweens[#g.tweens+1]=track
  end
  local last=line()
  if #last~=1 or last[1]~="ENDGAME8" or cursor~=#data+1 then
    error("unexpected trailing data",0)
  end
  return g
end
function P.decode(data)
  if type(data)~="string" or #data<40 or #data>LIMIT then
    return nil,"invalid game package size" end
  if data:sub(1,11)~="LUAFGAME 8\n" then return Previous.decode(data) end
  local success,g=pcall(parse,data)
  if not success then return nil,tostring(g) end
  local ok,err=P.validate(g)
  if not ok then return nil,err end
  return g
end
return P
