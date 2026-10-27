-- Lua-Flash Player 0.14: LUAFGAME 9 easing profiles on v8 sprite tracks.
-- Strict data-only envelope. Old game formats 1 through 8 are untouched.
local Previous=require("src.package_v8")
local P={}
local LIMIT=25*1024*1024
local MAX_CURVES=2048
P.MODES={"LINEAR","EASE_IN","EASE_OUT","EASE_IN_OUT","SMOOTH","STEP"}
local allowed={}
for _,mode in ipairs(P.MODES) do allowed[mode]=true end
local function integer(n,a,b)
  return type(n)=="number" and n==n and n==math.floor(n) and n>=a and n<=b
end
local function split(s)
  local t={}
  for field in (s.."\t"):gmatch("(.-)\t") do t[#t+1]=field end
  return t
end
local function baseGame(g)
  local copy={}
  for k,v in pairs(g) do copy[k]=v end
  copy.version=8;copy.easings=nil
  return copy
end

function P.validate(g)
  if type(g)~="table" or g.version~=9 or
      type(g.easings)~="table" or #g.easings>MAX_CURVES then
    return false,"invalid easing list"
  end
  local ok,err=Previous.validate(baseGame(g))
  if not ok then return false,err end
  local segments,used={},{}
  for _,track in ipairs(g.tweens) do
    local indexed={}
    for i=1,#track.keys-1 do indexed[track.keys[i].frame]=true end
    segments[track.index]=indexed
  end
  for _,e in ipairs(g.easings) do
    if type(e)~="table" or not integer(e.index,1,#g.sprites) or
        not integer(e.frame,1,g.document.totalFrames) or
        not allowed[e.mode] or not segments[e.index] or
        not segments[e.index][e.frame] then
      return false,"easing references missing sprite segment or unsupported mode"
    end
    local slot=e.index..":"..e.frame
    if used[slot] then return false,"duplicate easing segment" end
    used[slot]=true
  end
  return true
end

function P.encode(g)
  if type(g)~="table" or g.version~=9 then return Previous.encode(g) end
  local ok,err=P.validate(g)
  if not ok then return nil,err end
  local base,reason=Previous.encode(baseGame(g))
  if not base then return nil,reason end
  local chunks={"LUAFGAME 9\nBASE_BYTES\t"..#base.."\n",base,"\n",
    "EASING_COUNT\t"..#g.easings.."\n"}
  for _,e in ipairs(g.easings) do
    chunks[#chunks+1]=table.concat({"EASING",e.index,e.frame,e.mode},"\t").."\n"
  end
  chunks[#chunks+1]="ENDGAME9\n"
  local bytes=table.concat(chunks)
  if #bytes>LIMIT then return nil,"game package exceeds 25 MB" end
  return bytes
end
local function parse(data)
  local cursor=1
  local function line()
    local finish=data:find("\n",cursor,true)
    if not finish or finish-cursor>160 then error("invalid easing record",0) end
    local s=data:sub(cursor,finish-1)
    cursor=finish+1
    if s:find("\r",1,true) then error("CRLF not supported",0) end
    return split(s)
  end
  local magic=line()
  if #magic~=1 or magic[1]~="LUAFGAME 9" then
    error("unsupported format",0)
  end
  local header=line()
  local size=tonumber(header[2])
  if #header~=2 or header[1]~="BASE_BYTES" or
     not integer(size,40,LIMIT-100) or cursor+size>#data then
    error("invalid base game size",0)
  end
  local base=data:sub(cursor,cursor+size-1)
  cursor=cursor+size
  if data:sub(cursor,cursor)~="\n" then error("missing base separator",0) end
  cursor=cursor+1
  local g,reason=Previous.decode(base)
  if not g or g.version~=8 then
    error("invalid LUAFGAME 8 base: "..tostring(reason),0)
  end
  g.version=9;g.easings={}
  local list=line()
  local count=tonumber(list[2])
  if #list~=2 or list[1]~="EASING_COUNT" or
     not integer(count,0,MAX_CURVES) then error("invalid easing count",0) end
  for _=1,count do
    local record=line()
    if #record~=4 or record[1]~="EASING" then error("invalid EASING",0) end
    g.easings[#g.easings+1]={
      index=tonumber(record[2]),
      frame=tonumber(record[3]),
      mode=record[4]
    }
  end
  local ending=line()
  if #ending~=1 or ending[1]~="ENDGAME9" or cursor~=#data+1 then
    error("invalid trailer or extra data",0)
  end
  return g
end
function P.decode(data)
  if type(data)~="string" or #data<40 or #data>LIMIT then
    return nil,"invalid package size"
  end
  if data:sub(1,11)~="LUAFGAME 9\n" then return Previous.decode(data) end
  local ok,g=pcall(parse,data)
  if not ok then return nil,tostring(g) end
  local valid,err=P.validate(g)
  if not valid then return nil,err end
  return g
end
return P
