-- Lua-Flash 0.9: LUAFGAME 6, declarative sprite image sequences and timeline WAV.
-- Wraps a validated v5 package; old formats retain byte-for-byte compatibility.
local Previous=require("src.package_v5")
local P={}
local LIMIT=25*1024*1024
local function integer(n,min,max)
  return type(n)=="number" and n==n and n==math.floor(n) and n>=min and n<=max
end
local function split(line)
  local parts={}
  for field in (line.."\t"):gmatch("(.-)\t") do parts[#parts+1]=field end
  return parts
end
local function base(g)
  local result={}
  for k,v in pairs(g) do result[k]=v end
  result.version=5
  result.animations=nil
  result.timelineSounds=nil
  return result
end
function P.validate(g)
  if type(g)~="table" or g.version~=6 or type(g.animations)~="table" or
     type(g.timelineSounds)~="table" or #g.animations>64 or
     #g.timelineSounds>128 then return false,"invalid timeline media collections" end
  local valid,err=Previous.validate(base(g))
  if not valid then return false,err end
  local assets={}
  for _,resource in ipairs(g.resources) do assets[resource.id]=resource.kind end
  local used={}
  for _,a in ipairs(g.animations) do
    if type(a)~="table" or not integer(a.index,1,#g.sprites) or used[a.index] or
       not integer(a.period,1,120) or type(a.frames)~="table" or
       #a.frames<2 or #a.frames>16 then return false,"invalid sprite animation" end
    used[a.index]=true
    for _,id in ipairs(a.frames) do
      if assets[id]~="PNG" then return false,"animation references non-PNG resource" end
    end
  end
  for _,t in ipairs(g.timelineSounds) do
    if type(t)~="table" or not integer(t.frame,1,g.document.totalFrames) or
       assets[t.asset]~="WAV" then return false,"invalid timeline sound" end
  end
  return true
end
function P.encode(g)
  if type(g)~="table" or g.version~=6 then return Previous.encode(g) end
  local ok,err=P.validate(g)
  if not ok then return nil,err end
  local old,reason=Previous.encode(base(g))
  if not old then return nil,reason end
  local chunks={"LUAFGAME 6\nBASE_BYTES\t"..#old.."\n",old,"\n",
    "ANIMATION_COUNT\t"..#g.animations.."\n"}
  for _,a in ipairs(g.animations) do
    chunks[#chunks+1]=table.concat({"ANIMATION",a.index,a.period,#a.frames,
      table.concat(a.frames,",")},"\t").."\n"
  end
  chunks[#chunks+1]="TIMELINE_SOUND_COUNT\t"..#g.timelineSounds.."\n"
  for _,t in ipairs(g.timelineSounds) do
    chunks[#chunks+1]=table.concat({"TIMELINE_SOUND",t.frame,t.asset},"\t").."\n"
  end
  chunks[#chunks+1]="ENDGAME6\n"
  local bytes=table.concat(chunks)
  if #bytes>LIMIT then return nil,"game too large" end
  return bytes
end
local function parse(data)
  local cursor=1
  local function line()
    if cursor>LIMIT then error("header outside bounds",0) end
    local finish=data:find("\n",cursor,true)
    if not finish or finish-cursor>300 then error("missing or oversize record",0) end
    local s=data:sub(cursor,finish-1)
    cursor=finish+1
    if s:find("\r",1,true) then error("CRLF not supported",0) end
    return split(s)
  end
  local function count(expected,max)
    local f=line()
    local n=tonumber(f[2])
    if #f~=2 or f[1]~=expected or not integer(n,0,max) then
      error("invalid "..expected,0)
    end
    return n
  end
  local magic=line()
  if #magic~=1 or magic[1]~="LUAFGAME 6" then error("unsupported game format",0) end
  local n=count("BASE_BYTES",LIMIT)
  if n<40 or cursor+n>#data then error("truncated base package",0) end
  local bytes=data:sub(cursor,cursor+n-1)
  cursor=cursor+n
  if data:sub(cursor,cursor)~="\n" then error("missing package separator",0) end
  cursor=cursor+1
  local g,err=Previous.decode(bytes)
  if not g or g.version~=5 then error("invalid v5 base: "..tostring(err),0) end
  g.version=6
  g.animations={}
  g.timelineSounds={}
  for _=1,count("ANIMATION_COUNT",64) do
    local f=line()
    if #f~=5 or f[1]~="ANIMATION" then error("invalid animation record",0) end
    local index,period,num=tonumber(f[2]),tonumber(f[3]),tonumber(f[4])
    if not integer(num,2,16) then error("invalid animation length",0) end
    local frames={}
    for v in f[5]:gmatch("([^,]+)") do frames[#frames+1]=v end
    if #frames~=num then error("animation frame count mismatch",0) end
    g.animations[#g.animations+1]={index=index,period=period,frames=frames}
  end
  for _=1,count("TIMELINE_SOUND_COUNT",128) do
    local f=line()
    if #f~=3 or f[1]~="TIMELINE_SOUND" then
      error("invalid timeline sound record",0)
    end
    g.timelineSounds[#g.timelineSounds+1]={frame=tonumber(f[2]),asset=f[3]}
  end
  local ending=line()
  if #ending~=1 or ending[1]~="ENDGAME6" or cursor~=#data+1 then
    error("unexpected trailing data",0)
  end
  return g
end
function P.decode(data)
  if type(data)~="string" or #data<40 or #data>LIMIT then
    return nil,"invalid package size"
  end
  if data:sub(1,11)~="LUAFGAME 6\n" then return Previous.decode(data) end
  local ok,g=pcall(parse,data)
  if not ok then return nil,tostring(g) end
  local valid,err=P.validate(g)
  if not valid then return nil,err end
  return g
end
return P
