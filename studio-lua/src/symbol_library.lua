-- Studio-only reusable symbols. The shared Player model stays unchanged.
-- LUALIB 1 is an auxiliary authoring file, NOT an Adobe FLA/XFL format.
local Model=require("src.model")
local M={}
local allowed={graphic=true,movieclip=true,button=true}
local function integer(n,min,max)
  return type(n)=="number" and n==math.floor(n) and n>=min and n<=max
end
local function finite(n)
  return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
local function hex(s)
  return (s:gsub(".",function(c) return string.format("%02X",c:byte()) end))
end
local function unhex(s)
  if #s%2~=0 or s:find("[^%x]") then return nil end
  return (s:gsub("%x%x",function(c) return string.char(tonumber(c,16)) end))
end
local function sortedKeys(t)
  local a={}
  for k in pairs(t) do a[#a+1]=k end
  table.sort(a)
  return a
end
function M.new()
  return {nextSymbolId=1,nextInstanceId=1,symbols={},tracks={}}
end
function M.create(lib,kind,name,shapes)
  if not allowed[kind] then return nil,"invalid symbol type" end
  if type(name)~="string" or #name==0 or #name>64 then return nil,"invalid name" end
  if type(shapes)~="table" then return nil,"invalid shapes" end
  if M.count(lib)>=256 then return nil,"symbol limit reached" end
  local id=lib.nextSymbolId
  if not integer(id,1,100000000) or lib.symbols[id] then return nil,"invalid symbol id" end
  local definition=Model.new()
  definition.layers[1].keys[1]=Model.copy(shapes)
  local minx,miny
  for _,shape in ipairs(definition.layers[1].keys[1]) do
    local x,y=Model.bounds(shape)
    minx=minx and math.min(minx,x) or x
    miny=miny and math.min(miny,y) or y
  end
  for _,shape in ipairs(definition.layers[1].keys[1]) do
    Model.move(shape,-(minx or 0),-(miny or 0))
  end
  definition.totalFrames=1
  local symbol={id=id,kind=kind,name=name,definition=definition}
  lib.symbols[id]=symbol
  lib.nextSymbolId=id+1
  return symbol
end
function M.count(lib)
  local n=0
  for _ in pairs(lib.symbols) do n=n+1 end
  return n
end
function M.list(lib)
  local list={}
  for _,id in ipairs(sortedKeys(lib.symbols)) do list[#list+1]=lib.symbols[id] end
  return list
end
function M.find(lib,id) return lib.symbols[id] end
function M.ensureKey(lib,layer,frame,blank)
  assert(integer(layer,1,128) and integer(frame,1,10000),"invalid timeline position")
  local track=lib.tracks[layer]
  if not track then track={};lib.tracks[layer]=track end
  if not track[frame] then
    local items={}
    if not blank then
      for n,entries in pairs(track) do
        if n<frame and (not items.source or n>items.source) then
          items={source=n}
        end
      end
      local source=items.source
      items=source and Model.copy(track[source]) or {}
    end
    track[frame]=items
  elseif blank then
    track[frame]={}
  end
  return track[frame]
end
function M.removeKey(lib,layer,frame)
  if frame==1 or not lib.tracks[layer] then return false end
  if not lib.tracks[layer][frame] then return false end
  lib.tracks[layer][frame]=nil
  return true
end
function M.at(lib,layer,frame)
  local track=lib.tracks[layer]
  if not track then return {} end
  local index=0
  for n in pairs(track) do if n<=frame and n>index then index=n end end
  return track[index] or {}
end
function M.place(lib,layer,frame,symbolId,x,y)
  if not lib.symbols[symbolId] then return nil,"unknown symbol" end
  if not integer(layer,1,128) or not integer(frame,1,10000)
      or not finite(x) or not finite(y) or math.abs(x)>100000 or math.abs(y)>100000 then
    return nil,"invalid instance placement"
  end
  local items=M.ensureKey(lib,layer,frame)
  if #items>=10000 or lib.nextInstanceId>100000000 then return nil,"instance limit" end
  local item={uid=lib.nextInstanceId,symbolId=symbolId,x=x,y=y,sx=1,sy=1}
  lib.nextInstanceId=lib.nextInstanceId+1
  items[#items+1]=item
  return item
end
function M.encode(lib)
  local out={"LUALIB 1"}
  for _,symbol in ipairs(M.list(lib)) do
    out[#out+1]=table.concat({"S",symbol.id,symbol.kind,hex(symbol.name),hex(Model.encode(symbol.definition))},"\t")
  end
  for _,layer in ipairs(sortedKeys(lib.tracks)) do
    for _,frame in ipairs(sortedKeys(lib.tracks[layer])) do
      out[#out+1]=table.concat({"K",layer,frame},"\t")
      for _,v in ipairs(lib.tracks[layer][frame]) do
        out[#out+1]=table.concat({"I",v.uid,v.symbolId,string.format("%.6f",v.x),
          string.format("%.6f",v.y),string.format("%.6f",v.sx),string.format("%.6f",v.sy)},"\t")
      end
    end
  end
  out[#out+1]="END"
  return table.concat(out,"\n").."\n"
end
local function fields(line)
  local a={}
  for part in (line.."\t"):gmatch("(.-)\t") do a[#a+1]=part end
  return a
end
function M.decode(data)
  if type(data)~="string" or #data>8*1024*1024 then return nil,"invalid library size" end
  local lib=M.new()
  local lines={}
  for line in (data.."\n"):gmatch("(.-)\n") do
    if line~="" then lines[#lines+1]=line:gsub("\r$","") end
  end
  if lines[1]~="LUALIB 1" then return nil,"unsupported library format" end
  local current,ended,instances=nil,false,0
  for i=2,#lines do
    local f=fields(lines[i])
    local op=f[1]
    if ended then return nil,"trailing records" end
    if op=="S" then
      local id=tonumber(f[2])
      local name=unhex(f[4] or "")
      local raw=unhex(f[5] or "")
      if not integer(id,1,100000000) or not allowed[f[3]] or
          not name or #name==0 or #name>64 or not raw or lib.symbols[id]
          or M.count(lib)>=256 then return nil,"invalid symbol record" end
      local definition=Model.decode(raw)
      if not definition then return nil,"invalid symbol definition" end
      lib.symbols[id]={id=id,kind=f[3],name=name,definition=definition}
      lib.nextSymbolId=math.max(lib.nextSymbolId,id+1)
    elseif op=="K" then
      local layer,frame=tonumber(f[2]),tonumber(f[3])
      if not integer(layer,1,128) or not integer(frame,1,10000) then return nil,"invalid track" end
      if lib.tracks[layer] and lib.tracks[layer][frame] then return nil,"duplicate track key" end
      lib.tracks[layer]=lib.tracks[layer] or {}
      lib.tracks[layer][frame]={}
      current=lib.tracks[layer][frame]
    elseif op=="I" then
      local uid,symbolId=tonumber(f[2]),tonumber(f[3])
      local x,y,sx,sy=tonumber(f[4]),tonumber(f[5]),tonumber(f[6]),tonumber(f[7])
      if not integer(uid,1,100000000) or not integer(symbolId,1,100000000)
          or not finite(x) or not finite(y) or not finite(sx) or not finite(sy)
          or math.abs(x)>100000 or math.abs(y)>100000 or sx==0 or sy==0
          or math.abs(sx)>100 or math.abs(sy)>100 or not current or not lib.symbols[symbolId]
          or instances>=100000 then return nil,"invalid instance record" end
      current[#current+1]={uid=uid,symbolId=symbolId,x=x,y=y,sx=sx,sy=sy}
      lib.nextInstanceId=math.max(lib.nextInstanceId,uid+1)
      instances=instances+1
    elseif op=="END" then
      ended=true
    else
      return nil,"unknown library record"
    end
  end
  if not ended then return nil,"unfinished library" end
  return lib
end
return M
