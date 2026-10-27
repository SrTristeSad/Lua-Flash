-- Lua-Flash Player 0.8: LUAFGAME 5 interactive PNG sprites.
-- Binary-safe wrapper around LUAFGAME 4; versions 1-4 remain unchanged.
-- SPRITE_BIND assigns one existing game object ID to a PNG overlay.
-- FOLLOW centers the image on the animated native object, STATIC uses x/y.
local Previous=require("src.package_v4")
local P={}
local MAX=25*1024*1024
local function integer(n,a,b)
  return type(n)=="number" and n==math.floor(n) and n>=a and n<=b
end
local function baseGame(game)
  local out={}
  for key,value in pairs(game) do out[key]=value end
  out.version=4
  out.spriteBindings=nil
  return out
end

function P.validate(game)
  if type(game)~="table" or game.version~=5 or type(game.spriteBindings)~="table"
     or #game.spriteBindings>64 then
    return false,"invalid sprite bindings"
  end
  local ok,err=Previous.validate(baseGame(game))
  if not ok then return false,err end
  local objects,byIndex,byObject={},{},{}
  for _,obj in ipairs(game.objects) do objects[obj.id]=true end
  for i,bind in ipairs(game.spriteBindings) do
    if type(bind)~="table" or
       not integer(bind.index,1,#game.sprites) or
       not objects[bind.id] or
       (bind.mode~="FOLLOW" and bind.mode~="STATIC") or
       byIndex[bind.index] or byObject[bind.id] then
      return false,"invalid or duplicate sprite binding #"..i
    end
    byIndex[bind.index]=true
    byObject[bind.id]=true
  end
  return true
end

function P.encode(game)
  if type(game)~="table" or game.version~=5 then
    return Previous.encode(game)
  end
  local valid,err=P.validate(game)
  if not valid then return nil,err end
  local original,reason=Previous.encode(baseGame(game))
  if not original then return nil,reason end
  local chunks={"LUAFGAME 5\nBASE_BYTES\t"..#original.."\n",
    original,"\n","SPRITE_BIND_COUNT\t"..#game.spriteBindings.."\n"}
  for _,b in ipairs(game.spriteBindings) do
    chunks[#chunks+1]=table.concat({"SPRITE_BIND",b.index,b.id,b.mode},"\t").."\n"
  end
  chunks[#chunks+1]="ENDGAME5\n"
  local bytes=table.concat(chunks)
  if #bytes>MAX then return nil,"game too large" end
  return bytes
end

local function split(s)
  local parts={}
  for v in (s.."\t"):gmatch("(.-)\t") do parts[#parts+1]=v end
  return parts
end

local function parse(data)
  local cursor=1
  local function line()
    if cursor>MAX then error("invalid header position",0) end
    local stop=data:find("\n",cursor,true)
    if not stop or stop-cursor>160 then error("invalid package record",0) end
    local s=data:sub(cursor,stop-1)
    cursor=stop+1
    if s:find("\r",1,true) then error("invalid line ending",0) end
    return split(s)
  end
  local magic=line()
  if #magic~=1 or magic[1]~="LUAFGAME 5" then error("unknown game version",0) end
  local lengthLine=line()
  local size=tonumber(lengthLine[2])
  if #lengthLine~=2 or lengthLine[1]~="BASE_BYTES" or
     not integer(size,40,MAX-100) or cursor+size>#data then
    error("invalid base size",0)
  end
  local binary=data:sub(cursor,cursor+size-1)
  cursor=cursor+size
  if data:sub(cursor,cursor)~="\n" then error("missing base delimiter",0) end
  cursor=cursor+1
  local game,err=Previous.decode(binary)
  if not game or game.version~=4 then
    error("invalid v4 base: "..tostring(err),0)
  end
  game.version=5
  game.spriteBindings={}
  local count=line()
  local n=tonumber(count[2])
  if #count~=2 or count[1]~="SPRITE_BIND_COUNT" or not integer(n,0,64) then
    error("invalid binding count",0)
  end
  for _=1,n do
    local f=line()
    if #f~=4 or f[1]~="SPRITE_BIND" then error("invalid sprite binding",0) end
    game.spriteBindings[#game.spriteBindings+1]={
      index=tonumber(f[2]),id=f[3],mode=f[4]
    }
  end
  local terminator=line()
  if #terminator~=1 or terminator[1]~="ENDGAME5" or cursor~=#data+1 then
    error("trailing or missing data",0)
  end
  return game
end

function P.decode(data)
  if type(data)~="string" or #data<40 or #data>MAX then
    return nil,"invalid package size"
  end
  if data:sub(1,11)~="LUAFGAME 5\n" then
    return Previous.decode(data)
  end
  local ok,game=pcall(parse,data)
  if not ok then return nil,tostring(game) end
  local valid,err=P.validate(game)
  if not valid then return nil,err end
  return game
end
return P
