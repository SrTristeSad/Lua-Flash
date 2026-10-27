-- Lua-Flash Player 0.6: LUAFGAME 3, stable object IDs across keyframes.
-- Data-only serialization; never executes imported code.
-- V1/V2 packages remain decoded/encoded by the previous codec.
local Previous=require("src.package_v2")
local Model=require("src.model")
local P={}
local MAX_BYTES=25*1024*1024
local MAX_OBJECTS,MAX_BINDS,MAX_RULES,MAX_STATES=256,4096,128,64
local reserved={escape=true,f11=true,space=true,left=true,right=true,home=true,
  ["end"]=true,o=true,d=true,g=true,l=true,i=true,s=true}
local function int(n,a,b)
  return type(n)=="number" and n==math.floor(n) and n>=a and n<=b
end
local function id(s)
  return type(s)=="string" and #s>0 and #s<=32 and s:match("^[A-Za-z_][A-Za-z0-9_]*$")~=nil
end
local function esc(s)
  return (s:gsub("[^%w%-%._ ]",function(ch) return string.format("%%%02X",ch:byte()) end))
end
local function unesc(s)
  return (s:gsub("%%(%x%x)",function(h) return string.char(tonumber(h,16)) end))
end
local function split(s)
  local t={}
  for field in (s.."\t"):gmatch("(.-)\t") do t[#t+1]=field end
  return t
end
local function fields(...)
  local t={...}
  for i,v in ipairs(t) do t[i]=tostring(v) end
  return table.concat(t,"\t")
end
local function validAction(rule,doc,states)
  local a=rule.action
  if a=="SCORE" then
    return int(rule.value,-100,100) and rule.value~=0 and rule.variable==nil
  elseif a=="SEEK" then
    return int(rule.value,1,doc.totalFrames) and rule.variable==nil
  elseif a=="ADD" then
    return states[rule.variable] and int(rule.value,-1000,1000)
  elseif a=="SET" then
    return states[rule.variable] and int(rule.value,0,1000000)
  elseif a=="PAUSE" or a=="PLAY" then
    return rule.value==nil and rule.variable==nil
  end
  return false
end
function P.validate(g)
  if type(g)~="table" or type(g.document)~="table" or
     type(g.title)~="string" or #g.title<1 or #g.title>120 or
     g.title:find("[%c]") or type(g.smooth)~="boolean" or
     not int(g.duration,1,3600) or not int(g.goal,1,100000) then
    return false,"invalid game options"
  end
  local doc=g.document
  if type(doc.layers)~="table" or
     type(g.objects)~="table" or #g.objects<1 or #g.objects>MAX_OBJECTS or
     type(g.bindings)~="table" or #g.bindings<1 or #g.bindings>MAX_BINDS or
     type(g.states)~="table" or #g.states>MAX_STATES or
     type(g.rules)~="table" or #g.rules<1 or #g.rules>MAX_RULES then
    return false,"invalid collection"
  end
  local ids,states,slots,attached,bindingsById={},{},{},{},{}
  for _,o in ipairs(g.objects) do
    if type(o)~="table" or not id(o.id) or ids[o.id] then
      return false,"invalid or duplicate object ID"
    end
    ids[o.id]=true
  end
  for _,v in ipairs(g.states) do
    if type(v)~="table" or not id(v.id) or states[v.id] or
       not int(v.value,0,1000000) then return false,"invalid state" end
    states[v.id]=true
  end
  for _,b in ipairs(g.bindings) do
    if type(b)~="table" or not ids[b.id] or
       not int(b.layer,1,#doc.layers) or
       not int(b.frame,1,doc.totalFrames) or
       not int(b.shape,1,100000) or
       not doc.layers[b.layer].keys[b.frame] or
       not doc.layers[b.layer].keys[b.frame][b.shape] then
      return false,"invalid object binding"
    end
    local slot=b.layer..":"..b.frame..":"..b.shape
    if slots[slot] then return false,"duplicate shape binding" end
    slots[slot]=true
    local objectFrame=b.id..":"..b.frame
    if attached[objectFrame] then return false,"ambiguous object across layers at frame" end
    attached[objectFrame]=true
    bindingsById[b.id]=true
  end
  for name in pairs(ids) do
    if not bindingsById[name] then return false,"unbound object "..name end
  end
  for i,r in ipairs(g.rules) do
    if type(r)~="table" then return false,"invalid rule" end
    if r.event=="CLICKID" then
      if not ids[r.target] or r.other~=nil then return false,"invalid click target" end
    elseif r.event=="COLLIDE" then
      if not ids[r.target] or not ids[r.other] or r.target==r.other then
        return false,"invalid collision target"
      end
    elseif r.event=="KEY" then
      if not id(r.target) or #r.target>24 or reserved[r.target] or r.other~=nil then
        return false,"invalid keyboard target"
      end
    else return false,"unknown event "..i end
    if not validAction(r,doc,states) then return false,"invalid action "..i end
    local w=r.when
    if w~=nil and (type(w)~="table" or not states[w.id] or
       (w.op~="GE" and w.op~="LE" and w.op~="EQ") or
       not int(w.value,0,1000000)) then return false,"invalid condition" end
  end
  return true
end

function P.encode(g)
  if not g or g.version==1 or g.version==2 or (not g.bindings and not g.version) then
    return Previous.encode(g)
  end
  local ok,err=P.validate(g)
  if not ok then return nil,err end
  local scene=Model.encode(g.document)
  local lines={"LUAFGAME 3","TITLE\t"..esc(g.title),"DURATION\t"..g.duration,
    "GOAL\t"..g.goal,"SMOOTH\t"..(g.smooth and "1" or "0")}
  for _,obj in ipairs(g.objects) do
    lines[#lines+1]=fields("OBJECT",obj.id)
  end
  for _,b in ipairs(g.bindings) do
    lines[#lines+1]=fields("BIND",b.id,b.layer,b.frame,b.shape)
  end
  for _,s in ipairs(g.states) do
    lines[#lines+1]=fields("STATE",s.id,s.value)
  end
  for _,r in ipairs(g.rules) do
    local p1,p2
    if r.action=="ADD" or r.action=="SET" then
      p1,p2=r.variable,r.value
    else p1,p2=r.value or "-","-" end
    local w=r.when
    lines[#lines+1]=fields("RULE",r.event,r.target,r.other or "-",r.action,
      p1 or "-",p2,w and "WHEN" or "-",w and w.id or "-",
      w and w.op or "-",w and w.value or "-")
  end
  lines[#lines+1]=fields("SCENE_BYTES",#scene)
  local bytes=table.concat(lines,"\n").."\n"..scene.."\nENDGAME\n"
  if #bytes>MAX_BYTES then return nil,"package too large" end
  return bytes
end

local function parse(data)
  local cursor=1
  local function line()
    if cursor>262144 then error("header too long",0) end
    local last=data:find("\n",cursor,true)
    if not last then error("truncated header",0) end
    local s=data:sub(cursor,last-1)
    cursor=last+1
    if s:find("\r",1,true) then error("invalid CRLF",0) end
    return split(s)
  end
  local magic=line()
  if #magic~=1 or magic[1]~="LUAFGAME 3" then error("unsupported version",0) end
  local params,objects,bindings,states,rules={},{},{},{},{}
  while true do
    local f=line()
    if f[1]=="SCENE_BYTES" then
      if #f~=2 then error("invalid scene length",0) end
      local len=tonumber(f[2])
      if not int(len,1,MAX_BYTES) or data:sub(cursor+len)~="\nENDGAME\n" then
        error("truncated scene / incorrect trailer",0)
      end
      local doc,err=Model.decode(data:sub(cursor,cursor+len-1))
      if not doc then error("invalid scene: "..tostring(err),0) end
      if params.SMOOTH~="1" and params.SMOOTH~="0" then error("invalid SMOOTH",0) end
      return {
        version=3, title=unesc(params.TITLE or ""),
        duration=tonumber(params.DURATION),goal=tonumber(params.GOAL),
        smooth=params.SMOOTH=="1",
        document=doc, objects=objects, bindings=bindings,
        states=states,rules=rules
      }
    elseif f[1]=="TITLE" or f[1]=="DURATION" or f[1]=="GOAL" or f[1]=="SMOOTH" then
      if #f~=2 or params[f[1]]~=nil then error("duplicate/invalid option",0) end
      params[f[1]]=f[2]
    elseif f[1]=="OBJECT" then
      if #f~=2 or #objects>=MAX_OBJECTS then error("invalid OBJECT",0) end
      objects[#objects+1]={id=f[2]}
    elseif f[1]=="BIND" then
      if #f~=5 or #bindings>=MAX_BINDS then error("invalid BIND",0) end
      bindings[#bindings+1]={id=f[2],layer=tonumber(f[3]),
        frame=tonumber(f[4]),shape=tonumber(f[5])}
    elseif f[1]=="STATE" then
      if #f~=3 or #states>=MAX_STATES then error("invalid STATE",0) end
      states[#states+1]={id=f[2],value=tonumber(f[3])}
    elseif f[1]=="RULE" then
      if #f~=11 or #rules>=MAX_RULES then error("invalid RULE",0) end
      local a=f[5]
      local variable,value
      if a=="ADD" or a=="SET" then variable=f[6];value=tonumber(f[7])
      else
        if f[7]~="-" then error("extra action value",0) end
        value=f[6]~="-" and tonumber(f[6]) or nil
      end
      local w
      if f[8]=="WHEN" then
        w={id=f[9],op=f[10],value=tonumber(f[11])}
      elseif f[8]~="-" or f[9]~="-" or f[10]~="-" or f[11]~="-" then
        error("invalid condition",0)
      end
      rules[#rules+1]={event=f[2],target=f[3],
        other=f[4]~="-" and f[4] or nil,
        action=a,variable=variable,value=value,when=w}
    else error("unknown header field",0) end
  end
end

function P.decode(data)
  if type(data)~="string" or #data<40 or #data>MAX_BYTES then
    return nil,"invalid package size"
  end
  if data:sub(1,11)=="LUAFGAME 1\n" or data:sub(1,11)=="LUAFGAME 2\n" then
    return Previous.decode(data)
  end
  local ok,g=pcall(parse,data)
  if not ok then return nil,tostring(g) end
  local valid,err=P.validate(g)
  if not valid then return nil,err end
  return g
end
return P
