-- Lua-Flash Player 0.4, declarative game format LUAFGAME 1.
-- Read-only data, not an executable Lua module or a Flash/SWF compatibility layer.
local Model=require("src.model")
local P={}
local MAX_BYTES=25*1024*1024
local MAX_RULES=128
local MAX_TITLE=120
local reserved={escape=true,f11=true,space=true,left=true,right=true,home=true,
  ["end"]=true,o=true,d=true,g=true,l=true,i=true,s=true}
local function escaped(s)
  return (s:gsub("[^%w%-%._ ]",function(c) return string.format("%%%02X",c:byte()) end))
end
local function unescape(s)
  return (s:gsub("%%(%x%x)",function(hex) return string.char(tonumber(hex,16)) end))
end
local function validInteger(n,a,b)
  return type(n)=="number" and n==math.floor(n) and n>=a and n<=b
end
local function validRule(rule,doc)
  if type(rule)~="table" or type(rule.event)~="string" or type(rule.action)~="string" then return false end
  if rule.event=="CLICK" then
    if not validInteger(rule.layer,1,#doc.layers) or not validInteger(rule.shape,1,100000) then return false end
    local exists=false
    for _,shapes in pairs(doc.layers[rule.layer].keys) do
      if shapes[rule.shape] then exists=true;break end
    end
    if not exists then return false end
  elseif rule.event=="KEY" then
    if type(rule.key)~="string" or not rule.key:match("^[%w_]+$") or
       #rule.key>24 or reserved[rule.key] then return false end
  else return false end
  if rule.action=="SCORE" then return validInteger(rule.value,-100,100) and rule.value~=0
  elseif rule.action=="SEEK" then return validInteger(rule.value,1,doc.totalFrames)
  elseif rule.action=="PAUSE" or rule.action=="PLAY" then return rule.value==nil end
  return false
end

function P.validate(game)
  if type(game)~="table" or type(game.document)~="table" or type(game.title)~="string" then
    return false,"missing game or document"
  end
  if #game.title<1 or #game.title>MAX_TITLE or game.title:find("[%c]") then return false,"invalid game title" end
  if not validInteger(game.duration,1,3600) or not validInteger(game.goal,1,100000) then
    return false,"invalid duration/goal"
  end
  if type(game.smooth)~="boolean" or type(game.rules)~="table" or
     #game.rules<1 or #game.rules>MAX_RULES then return false,"invalid rules" end
  for i,r in ipairs(game.rules) do
    if not validRule(r,game.document) then return false,"invalid rule #"..i end
  end
  return true
end

function P.encode(game)
  local ok,err=P.validate(game)
  if not ok then return nil,err end
  local scene=Model.encode(game.document)
  if #scene>MAX_BYTES-2048 then return nil,"scene exceeds size limit" end
  local out={
    "LUAFGAME 1",
    "TITLE\t"..escaped(game.title),
    "DURATION\t"..game.duration,
    "GOAL\t"..game.goal,
    "SMOOTH\t"..(game.smooth and "1" or "0")
  }
  for _,r in ipairs(game.rules) do
    if r.event=="CLICK" then
      out[#out+1]=table.concat({"RULE","CLICK",r.layer,r.shape,r.action,r.value or "-"},"\t")
    else
      out[#out+1]=table.concat({"RULE","KEY",r.key,r.action,r.value or "-"},"\t")
    end
  end
  out[#out+1]="SCENE_BYTES\t"..#scene
  local body=table.concat(out,"\n").."\n"..scene.."\nENDGAME\n"
  if #body>MAX_BYTES then return nil,"package exceeds 25 MB" end
  return body
end

local function header(data)
  local cursor=1
  local function line()
    if cursor>8192 then error("game header too large",0) end
    local finish=data:find("\n",cursor,true)
    if not finish then error("truncated game header",0) end
    local result=data:sub(cursor,finish-1)
    cursor=finish+1
    if result:find("\r",1,true) then error("invalid newline",0) end
    return result
  end
  if line()~="LUAFGAME 1" then error("unknown game format/version",0) end
  local fields={}
  local function split(s)
    local parts={}
    for p in (s.."\t"):gmatch("(.-)\t") do parts[#parts+1]=p end
    return parts
  end
  local r
  repeat
    r=split(line())
    if r[1]=="SCENE_BYTES" then break end
    if r[1]=="RULE" then
      fields.rules=fields.rules or {}
      if #fields.rules>=MAX_RULES then error("too many rules",0) end
      local rule
      if r[2]=="CLICK" and #r==6 then
        rule={event="CLICK",layer=tonumber(r[3]),shape=tonumber(r[4]),action=r[5],
          value=r[6]~="-" and tonumber(r[6]) or nil}
      elseif r[2]=="KEY" and #r==5 then
        rule={event="KEY",key=r[3],action=r[4],value=r[5]~="-" and tonumber(r[5]) or nil}
      else error("invalid game rule",0) end
      fields.rules[#fields.rules+1]=rule
    elseif (r[1]=="TITLE" or r[1]=="DURATION" or r[1]=="GOAL" or r[1]=="SMOOTH") and
      #r==2 and fields[r[1]]==nil then
      fields[r[1]]=r[2]
    else error("unexpected game header field",0) end
  until false
  if #r~=2 then error("invalid scene length",0) end
  local n=tonumber(r[2])
  if not validInteger(n,1,MAX_BYTES-256) then error("invalid scene length",0) end
  if cursor+n+8>#data then error("truncated scene",0) end
  local scene=data:sub(cursor,cursor+n-1)
  if data:sub(cursor+n)~="\nENDGAME\n" then error("game trailer mismatch",0) end
  return fields,scene
end

function P.decode(data)
  if type(data)~="string" or #data>MAX_BYTES or #data<40 then return nil,"invalid game package size" end
  local ok,fields,scene=pcall(header,data)
  if not ok then return nil,tostring(fields) end
  local status,doc,docErr=pcall(Model.decode,scene)
  if not status or not doc then return nil,"invalid project: "..tostring(status and docErr or doc) end
  local game={
    title=unescape(fields.TITLE or ""),
    duration=tonumber(fields.DURATION),goal=tonumber(fields.GOAL),
    smooth=fields.SMOOTH=="1",rules=fields.rules or {},document=doc
  }
  if fields.SMOOTH~="1" and fields.SMOOTH~="0" then return nil,"invalid interpolation flag" end
  local good,err=P.validate(game)
  if not good then return nil,err end
  return game
end

return P
