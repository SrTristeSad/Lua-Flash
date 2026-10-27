-- Lua-Flash Player 0.5: LUAFGAME 2 objects, state and conditional rules.
-- Data-only interpreter: NEVER evaluates code contained in a game package.
-- LUAFGAME 1 is delegated unchanged to src.package for backwards compatibility.
local Legacy=require("src.package")
local Model=require("src.model")
local P={}
local MAX_BYTES=25*1024*1024
local MAX_RULES,MAX_OBJECTS,MAX_STATES=128,256,64
local MAX_STATE=1000000
local reserved={escape=true,f11=true,space=true,left=true,right=true,home=true,
  ["end"]=true,o=true,d=true,g=true,l=true,i=true,s=true}

local function integer(n,low,high)
  return type(n)=="number" and n==math.floor(n) and n>=low and n<=high
end
local function id(s)
  return type(s)=="string" and #s>=1 and #s<=32 and
    s:match("^[%a_][%w_]*$")~=nil
end
local function esc(s)
  return (s:gsub("[^%w%-%._ ]",function(ch) return string.format("%%%02X",ch:byte()) end))
end
local function unesc(s)
  return (s:gsub("%%(%x%x)",function(h) return string.char(tonumber(h,16)) end))
end
local function split(s)
  local t={}
  for v in (s.."\t"):gmatch("(.-)\t") do t[#t+1]=v end
  return t
end
local function existingShape(doc,layer,shape)
  if not integer(layer,1,#doc.layers) or not integer(shape,1,100000) then return false end
  for _,shapes in pairs(doc.layers[layer].keys) do
    if shapes[shape] then return true end
  end
  return false
end

function P.validate(g)
  if type(g)~="table" or type(g.document)~="table" or
     type(g.title)~="string" or #g.title<1 or #g.title>120 or
     g.title:find("[%c]") then return false,"invalid title/document" end
  if not integer(g.duration,1,3600) or not integer(g.goal,1,100000) or
     type(g.smooth)~="boolean" then return false,"invalid options" end
  if type(g.objects)~="table" or #g.objects<1 or #g.objects>MAX_OBJECTS or
     type(g.states)~="table" or #g.states>MAX_STATES or
     type(g.rules)~="table" or #g.rules<1 or #g.rules>MAX_RULES then
    return false,"invalid collection size"
  end
  local objNames,statNames,slots={},{},{}
  for _,o in ipairs(g.objects) do
    if type(o)~="table" or not id(o.id) or objNames[o.id] or
       not existingShape(g.document,o.layer,o.shape) then
      return false,"invalid/duplicate object"
    end
    local slot=o.layer..":"..o.shape
    if slots[slot] then return false,"duplicate object binding" end
    slots[slot]=true;objNames[o.id]=true
  end
  for _,v in ipairs(g.states) do
    if type(v)~="table" or not id(v.id) or statNames[v.id] or
       not integer(v.value,0,MAX_STATE) then return false,"invalid/duplicate state" end
    statNames[v.id]=true
  end
  for i,r in ipairs(g.rules) do
    if type(r)~="table" or
       (r.event~="CLICKID" and r.event~="KEY") then return false,"invalid event "..i end
    if r.event=="CLICKID" then
      if not objNames[r.target] then return false,"unknown object "..i end
    elseif not id(r.target) or #r.target>24 or reserved[r.target] then
      return false,"invalid key "..i
    end
    local a=r.action
    if a=="SCORE" then
      if not integer(r.value,-100,100) or r.value==0 or r.variable~=nil then
        return false,"invalid SCORE"
      end
    elseif a=="SEEK" then
      if not integer(r.value,1,g.document.totalFrames) or r.variable~=nil then
        return false,"invalid SEEK"
      end
    elseif a=="ADD" or a=="SET" then
      if not statNames[r.variable] or not integer(r.value,a=="ADD" and -1000 or 0,
        a=="ADD" and 1000 or MAX_STATE) then return false,"invalid state action" end
    elseif a=="PAUSE" or a=="PLAY" then
      if r.value~=nil or r.variable~=nil then return false,"invalid transport action" end
    else return false,"unknown action" end
    if r.when~=nil then
      local w=r.when
      if type(w)~="table" or not statNames[w.id] or
         (w.op~="GE" and w.op~="EQ" and w.op~="LE") or
         not integer(w.value,0,MAX_STATE) then return false,"invalid condition" end
    end
  end
  return true
end

function P.encode(g)
  if g and (g.version==1 or (not g.objects and not g.states)) then
    return Legacy.encode(g)
  end
  local ok,err=P.validate(g)
  if not ok then return nil,err end
  local scene=Model.encode(g.document)
  local lines={
    "LUAFGAME 2","TITLE\t"..esc(g.title),
    "DURATION\t"..g.duration,"GOAL\t"..g.goal,
    "SMOOTH\t"..(g.smooth and "1" or "0")
  }
  for _,o in ipairs(g.objects) do
    lines[#lines+1]=table.concat({"OBJECT",o.id,o.layer,o.shape},"\t")
  end
  for _,v in ipairs(g.states) do
    lines[#lines+1]=table.concat({"STATE",v.id,v.value},"\t")
  end
  for _,r in ipairs(g.rules) do
    local cond=r.when
    local v1,v2
    if r.action=="ADD" or r.action=="SET" then
      v1,v2=r.variable,r.value
    else v1,v2=r.value or "-","-" end
    lines[#lines+1]=table.concat({
      "RULE",r.event,r.target,r.action,v1 or "-",v2,
      cond and "WHEN" or "-",cond and cond.id or "-",
      cond and cond.op or "-",cond and cond.value or "-"
    },"\t")
  end
  lines[#lines+1]="SCENE_BYTES\t"..#scene
  local output=table.concat(lines,"\n").."\n"..scene.."\nENDGAME\n"
  if #output>MAX_BYTES then return nil,"package size exceeds limit" end
  return output
end

local function parse(data)
  local cursor=1
  local function line()
    if cursor>16384 then error("header too long",0) end
    local e=data:find("\n",cursor,true)
    if not e then error("truncated header",0) end
    local s=data:sub(cursor,e-1); cursor=e+1
    if s:find("\r",1,true) then error("invalid newline",0) end
    return split(s)
  end
  if table.concat(line(),"\t")~="LUAFGAME 2" then error("invalid version",0) end
  local attributes={}, objects={},states={},rules={}
  while true do
    local f=line()
    local kind=f[1]
    if kind=="SCENE_BYTES" then
      if #f~=2 then error("invalid scene length field",0) end
      local n=tonumber(f[2])
      if not integer(n,1,MAX_BYTES-256) then error("invalid scene size",0) end
      if data:sub(cursor+n)~="\nENDGAME\n" then error("trailing data or truncation",0) end
      local scene=data:sub(cursor,cursor+n-1)
      local doc,err=Model.decode(scene)
      if not doc then error("invalid embedded scene: "..tostring(err),0) end
      local sm=attributes.SMOOTH
      if sm~="0" and sm~="1" then error("invalid SMOOTH flag",0) end
      return {
        version=2,title=unesc(attributes.TITLE or ""),
        duration=tonumber(attributes.DURATION),goal=tonumber(attributes.GOAL),
        smooth=sm=="1",document=doc,objects=objects,states=states,rules=rules
      }
    elseif kind=="TITLE" or kind=="DURATION" or kind=="GOAL" or kind=="SMOOTH" then
      if #f~=2 or attributes[kind]~=nil then error("duplicate/invalid option",0) end
      attributes[kind]=f[2]
    elseif kind=="OBJECT" then
      if #f~=4 or #objects>=MAX_OBJECTS then error("invalid object",0) end
      objects[#objects+1]={id=f[2],layer=tonumber(f[3]),shape=tonumber(f[4])}
    elseif kind=="STATE" then
      if #f~=3 or #states>=MAX_STATES then error("invalid state",0) end
      states[#states+1]={id=f[2],value=tonumber(f[3])}
    elseif kind=="RULE" then
      if #f~=10 or #rules>=MAX_RULES then error("invalid rule",0) end
      local action=f[4]
      local variable,value
      if action=="ADD" or action=="SET" then variable=f[5];value=tonumber(f[6])
      else
        if f[6]~="-" then error("extra action parameter",0) end
        value=f[5]~="-" and tonumber(f[5]) or nil
      end
      local when
      if f[7]=="WHEN" then
        when={id=f[8],op=f[9],value=tonumber(f[10])}
      elseif f[7]~="-" or f[8]~="-" or f[9]~="-" or f[10]~="-" then
        error("invalid condition fields",0)
      end
      rules[#rules+1]={
        event=f[2],target=f[3],action=action,variable=variable,value=value,when=when
      }
    else error("unknown record",0) end
  end
end

function P.decode(data)
  if type(data)~="string" or #data<40 or #data>MAX_BYTES then
    return nil,"invalid package size"
  end
  if data:sub(1,11)=="LUAFGAME 1\n" then
    local game,err=Legacy.decode(data)
    if game then game.version=1 end
    return game,err
  end
  local success,g=pcall(parse,data)
  if not success then return nil,tostring(g) end
  local ok,err=P.validate(g)
  if not ok then return nil,err end
  return g
end

return P
