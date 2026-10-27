-- Lua-Flash 0.12: LUAFGAME 7 adds declarative sprite transformations.
-- Never executes imported Lua. Versions 1..6 remain byte-identical.
local Previous=require("src.package_v6")
local P={}
local LIMIT=25*1024*1024
local function integer(x,a,b)
  return type(x)=="number" and x==x and x==math.floor(x) and x>=a and x<=b
end
local function parts(line)
  local values={}
  for value in (line.."\t"):gmatch("(.-)\t") do values[#values+1]=value end
  return values
end
local function previousGame(game)
  local g={}
  for k,v in pairs(game) do g[k]=v end
  g.version=6;g.transforms=nil
  return g
end
function P.validate(game)
  if type(game)~="table" or game.version~=7 or
     type(game.transforms)~="table" or #game.transforms>64 then
    return false,"invalid sprite transformations"
  end
  local ok,err=Previous.validate(previousGame(game))
  if not ok then return false,err end
  local used={}
  for _,t in ipairs(game.transforms) do
    if type(t)~="table" or not integer(t.index,1,#game.sprites) or used[t.index] or
       not integer(t.angle,-360,360) or
       not integer(t.scaleX,10,400) or not integer(t.scaleY,10,400) or
       not integer(t.pivotX,0,100) or not integer(t.pivotY,0,100) then
      return false,"invalid or duplicate sprite transform"
    end
    used[t.index]=true
  end
  return true
end
function P.encode(game)
  if type(game)~="table" or game.version~=7 then
    return Previous.encode(game)
  end
  local ok,err=P.validate(game)
  if not ok then return nil,err end
  local base,baseErr=Previous.encode(previousGame(game))
  if not base then return nil,baseErr end
  local out={"LUAFGAME 7\nBASE_BYTES\t"..#base.."\n",base,"\n",
    "TRANSFORM_COUNT\t"..#game.transforms.."\n"}
  for _,t in ipairs(game.transforms) do
    out[#out+1]=table.concat({"TRANSFORM",t.index,t.angle,
      t.scaleX,t.scaleY,t.pivotX,t.pivotY},"\t").."\n"
  end
  out[#out+1]="ENDGAME7\n"
  local data=table.concat(out)
  if #data>LIMIT then return nil,"game exceeds 25 MB" end
  return data
end
local function parse(data)
  local cursor=1
  local function line()
    local e=data:find("\n",cursor,true)
    if not e or e-cursor>160 then error("invalid record",0) end
    local s=data:sub(cursor,e-1)
    cursor=e+1
    if s:find("\r",1,true) then error("invalid CRLF",0) end
    return parts(s)
  end
  local magic=line()
  if #magic~=1 or magic[1]~="LUAFGAME 7" then error("unsupported version",0) end
  local f=line();local size=tonumber(f[2])
  if #f~=2 or f[1]~="BASE_BYTES" or not integer(size,40,LIMIT-100) or
     cursor+size>#data then error("invalid base size",0) end
  local base=data:sub(cursor,cursor+size-1)
  cursor=cursor+size
  if data:sub(cursor,cursor)~="\n" then error("missing delimiter",0) end
  cursor=cursor+1
  local game,err=Previous.decode(base)
  if not game or game.version~=6 then error("invalid v6 base: "..tostring(err),0) end
  game.version=7;game.transforms={}
  local nline=line();local count=tonumber(nline[2])
  if #nline~=2 or nline[1]~="TRANSFORM_COUNT" or not integer(count,0,64) then
    error("invalid transformation count",0)
  end
  for _=1,count do
    local item=line()
    if #item~=7 or item[1]~="TRANSFORM" then error("invalid transform",0) end
    game.transforms[#game.transforms+1]={
      index=tonumber(item[2]),angle=tonumber(item[3]),
      scaleX=tonumber(item[4]),scaleY=tonumber(item[5]),
      pivotX=tonumber(item[6]),pivotY=tonumber(item[7])
    }
  end
  local term=line()
  if #term~=1 or term[1]~="ENDGAME7" or cursor~=#data+1 then
    error("unexpected trailing data",0)
  end
  return game
end
function P.decode(data)
  if type(data)~="string" or #data<40 or #data>LIMIT then
    return nil,"invalid game package size"
  end
  if data:sub(1,11)~="LUAFGAME 7\n" then return Previous.decode(data) end
  local ok,g=pcall(parse,data)
  if not ok then return nil,tostring(g) end
  local valid,err=P.validate(g)
  if not valid then return nil,err end
  return g
end
return P
