-- Lua-Flash Player 0.7: LUAFGAME 4 bundled PNG/WAV resources.
-- Binary-safe data envelope around a validated LUAFGAME 3 document.
-- Backward compatible with game package versions 1 through 3.
local Previous=require("src.package_v3")
local P={}
local LIMIT=25*1024*1024
local RESOURCE_LIMIT=2*1024*1024
local TOTAL_RESOURCES=12*1024*1024
local function finite(v)
  return type(v)=="number" and v==v and v~=math.huge and v~=-math.huge
end
local function integer(v,min,max)
  return finite(v) and v==math.floor(v) and v>=min and v<=max
end
local function identifier(s)
  return type(s)=="string" and #s>0 and #s<=32 and s:match("^[A-Za-z_][A-Za-z0-9_]*$")~=nil
end
local function u32be(s,p)
  local a,b,c,d=s:byte(p,p+3)
  return a and (a*16777216+b*65536+c*256+d) or nil
end
local function u32le(s,p)
  local a,b,c,d=s:byte(p,p+3)
  return a and (a+b*256+c*65536+d*16777216) or nil
end
local function u16le(s,p)
  local a,b=s:byte(p,p+1)
  return a and (a+b*256) or nil
end
local function validPNG(s)
  if #s<45 or s:sub(1,8)~="\137PNG\r\n\26\n" or s:sub(13,16)~="IHDR" or
     u32be(s,9)~=13 then return false end
  local w,h=u32be(s,17),u32be(s,21)
  return integer(w,1,1024) and integer(h,1,1024) and s:byte(25)==8 and
     (s:byte(26)==2 or s:byte(26)==6) and s:byte(27)==0 and s:byte(28)==0
end
local function validWAV(s)
  if #s<44 or s:sub(1,4)~="RIFF" or s:sub(9,12)~="WAVE" or
     s:sub(13,16)~="fmt " or u32le(s,17)~=16 or
     s:sub(37,40)~="data" then return false end
  local channels,rate,bits=u16le(s,23),u32le(s,25),u16le(s,35)
  local dataBytes=u32le(s,41)
  return u32le(s,5)==#s-8 and u16le(s,21)==1 and
     integer(channels,1,2) and integer(rate,8000,44100) and bits==16 and
     dataBytes==#s-44 and dataBytes>0 and
     u16le(s,33)==channels*2 and u32le(s,29)==rate*channels*2 and
     dataBytes%(channels*2)==0 and dataBytes<=rate*channels*2*10
end
local function validAsset(asset)
  if type(asset)~="table" or not identifier(asset.id) or
     type(asset.data)~="string" or #asset.data<44 or
     #asset.data>RESOURCE_LIMIT then return false end
  if asset.kind=="PNG" then return validPNG(asset.data)
  elseif asset.kind=="WAV" then return validWAV(asset.data) end
  return false
end
local function ruleExists(game,cue)
  if cue.event=="WIN" then return cue.target=="-" and cue.other=="-" end
  for _,rule in ipairs(game.rules) do
    if rule.event==cue.event and rule.target==cue.target then
      if cue.event=="COLLIDE" then
        if (rule.other==cue.other) then return true end
      elseif cue.other=="-" then return true end
    end
  end
  return false
end
function P.validate(g)
  if type(g)~="table" or g.version~=4 or
     type(g.resources)~="table" or #g.resources>24 or
     type(g.sprites)~="table" or #g.sprites>64 or
     type(g.cues)~="table" or #g.cues>64 then
    return false,"invalid media collection"
  end
  local good,err=Previous.validate(g)
  if not good then return false,err end
  local names,total={},0
  for _,asset in ipairs(g.resources) do
    if not validAsset(asset) or names[asset.id] then
      return false,"invalid/duplicate PNG or WAV asset" end
    names[asset.id]=asset.kind
    total=total+#asset.data
    if total>TOTAL_RESOURCES then return false,"media data exceeds limit" end
  end
  for _,s in ipairs(g.sprites) do
    if type(s)~="table" or names[s.asset]~="PNG" or
       not integer(s.x,-4096,4096) or not integer(s.y,-4096,4096) or
       not integer(s.width,1,2048) or not integer(s.height,1,2048) then
      return false,"invalid sprite placement"
    end
  end
  for _,c in ipairs(g.cues) do
    if type(c)~="table" or names[c.asset]~="WAV" or
       not (c.event=="CLICKID" or c.event=="KEY" or
            c.event=="COLLIDE" or c.event=="WIN") or
       not ruleExists(g,c) then return false,"invalid sound event" end
  end
  return true
end
local function baseGame(g)
  local out={}
  for k,v in pairs(g) do out[k]=v end
  out.version=3
  out.resources=nil;out.sprites=nil;out.cues=nil
  return out
end
function P.encode(g)
  if type(g)~="table" or g.version~=4 then return Previous.encode(g) end
  local good,err=P.validate(g)
  if not good then return nil,err end
  local base,baseErr=Previous.encode(baseGame(g))
  if not base then return nil,baseErr end
  local pieces={"LUAFGAME 4\nGAME_BYTES\t"..#base.."\n",base,"\n",
    "RESOURCE_COUNT\t"..#g.resources.."\n"}
  for _,r in ipairs(g.resources) do
    pieces[#pieces+1]=table.concat({"RESOURCE",r.id,r.kind,#r.data},"\t").."\n"
    pieces[#pieces+1]=r.data.."\n"
  end
  pieces[#pieces+1]="SPRITE_COUNT\t"..#g.sprites.."\n"
  for _,s in ipairs(g.sprites) do
    pieces[#pieces+1]=table.concat({"SPRITE",s.asset,s.x,s.y,s.width,s.height},"\t").."\n"
  end
  pieces[#pieces+1]="CUE_COUNT\t"..#g.cues.."\n"
  for _,c in ipairs(g.cues) do
    pieces[#pieces+1]=table.concat({"CUE",c.asset,c.event,c.target,c.other},"\t").."\n"
  end
  pieces[#pieces+1]="ENDGAME4\n"
  local bytes=table.concat(pieces)
  if #bytes>LIMIT then return nil,"game exceeds 25 MB" end
  return bytes
end
local function fields(line)
  local out={}
  for field in (line.."\t"):gmatch("(.-)\t") do out[#out+1]=field end
  return out
end
local function parse(bytes)
  local cursor=1
  local function line()
    if cursor>LIMIT then error("invalid header position",0) end
    local last=bytes:find("\n",cursor,true)
    if not last or last-cursor>160 then error("invalid media record",0) end
    local str=bytes:sub(cursor,last-1)
    cursor=last+1
    if str:find("\r",1,true) then error("invalid newline",0) end
    return fields(str)
  end
  local function blob(n)
    if not integer(n,1,LIMIT) or cursor+n>#bytes then
      error("truncated binary payload",0)
    end
    local data=bytes:sub(cursor,cursor+n-1)
    cursor=cursor+n
    if bytes:sub(cursor,cursor)~="\n" then error("missing payload delimiter",0) end
    cursor=cursor+1
    return data
  end
  local function count(expected,max)
    local f=line()
    local n=tonumber(f[2])
    if #f~=2 or f[1]~=expected or not integer(n,0,max) then
      error("invalid "..expected,0)
    end
    return n
  end
  local top=line()
  if #top~=1 or top[1]~="LUAFGAME 4" then error("unknown version",0) end
  local gameData=blob(count("GAME_BYTES",LIMIT))
  local g,err=Previous.decode(gameData)
  if not g then error("invalid base game: "..tostring(err),0) end
  if g.version~=3 then error("base game must use v3",0) end
  g.version=4;g.resources={};g.sprites={};g.cues={}
  local total=0
  for _=1,count("RESOURCE_COUNT",24) do
    local f=line()
    local len=tonumber(f[4])
    if #f~=4 or f[1]~="RESOURCE" or not integer(len,44,RESOURCE_LIMIT) then
      error("invalid resource header",0)
    end
    total=total+len
    if total>TOTAL_RESOURCES then error("too many resource bytes",0) end
    g.resources[#g.resources+1]={id=f[2],kind=f[3],data=blob(len)}
  end
  for _=1,count("SPRITE_COUNT",64) do
    local f=line()
    if #f~=6 or f[1]~="SPRITE" then error("invalid sprite",0) end
    g.sprites[#g.sprites+1]={asset=f[2],x=tonumber(f[3]),y=tonumber(f[4]),
      width=tonumber(f[5]),height=tonumber(f[6])}
  end
  for _=1,count("CUE_COUNT",64) do
    local f=line()
    if #f~=5 or f[1]~="CUE" then error("invalid audio cue",0) end
    g.cues[#g.cues+1]={asset=f[2],event=f[3],target=f[4],other=f[5]}
  end
  local last=line()
  if #last~=1 or last[1]~="ENDGAME4" or cursor~=#bytes+1 then
    error("unexpected trailing media data",0)
  end
  return g
end

function P.decode(bytes)
  if type(bytes)~="string" or #bytes<40 or #bytes>LIMIT then
    return nil,"invalid game package size"
  end
  if bytes:sub(1,11)~="LUAFGAME 4\n" then return Previous.decode(bytes) end
  local ok,g=pcall(parse,bytes)
  if not ok then return nil,tostring(g) end
  local valid,err=P.validate(g)
  if not valid then return nil,err end
  return g
end
return P
