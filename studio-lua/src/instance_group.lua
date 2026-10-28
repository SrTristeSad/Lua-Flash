-- Atomic multi-instance alignment, distribution and shared-pivot transforms.
-- All selected objects must be from the same unlocked layer on the active frame.
-- Planning does not mutate the document: UI records one undo snapshot, then applies.
local Model=require("src.model")
local Library=require("src.symbol_library")
local Transform=require("src.instance_transform")
local Vector=require("src.vector_paths")
local M={}
local function finite(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
local function clampValid(p)
  return Transform.valid(p) and math.abs(p.x)<=100000 and math.abs(p.y)<=100000
    and math.abs(p.sx)>=0.1 and math.abs(p.sy)>=0.1
    and math.abs(p.sx)<=20 and math.abs(p.sy)<=20
end
local function collect(doc,lib,layerIndex,frame,ids,vectors)
  local layer=doc.layers[layerIndex]
  if not layer or layer.locked then return nil,"camada bloqueada ou inexistente" end
  if type(ids)~="table" then return nil,"selecao invalida" end
  local selected={}
  for uid,enabled in pairs(ids) do
    if enabled then selected[uid]=true end
  end
  local items,seen={},{}
  for _,item in ipairs(Library.at(lib,layerIndex,frame)) do
    if selected[item.uid] then
      if seen[item.uid] then return nil,"identificador duplicado" end
      local sym=Library.find(lib,item.symbolId)
      if not sym or not Transform.valid(item) then return nil,"simbolo invalido" end
      local left,top,right,bottom=Transform.box(item,sym,1,
        vectors and Vector.scope(vectors,sym.id))
      if not left then return nil,"simbolo sem geometria" end
      items[#items+1]={uid=item.uid,source=item,left=left,top=top,
        right=right,bottom=bottom,cx=(left+right)/2,cy=(top+bottom)/2}
      seen[item.uid]=true
    end
  end
  for uid in pairs(selected) do if not seen[uid] then return nil,"selecao desatualizada" end end
  if #items<2 then return nil,"selecione pelo menos duas instancias" end
  return items
end
function M.count(ids)
  local count=0
  for _,enabled in pairs(ids or {}) do if enabled then count=count+1 end end
  return count
end
function M.plan(doc,lib,layerIndex,frame,ids,op,value,vectors)
  local items,err=collect(doc,lib,layerIndex,frame,ids,vectors)
  if not items then return nil,err end
  local minx,miny,maxx,maxy
  for _,item in ipairs(items) do
    minx=minx and math.min(minx,item.left) or item.left
    miny=miny and math.min(miny,item.top) or item.top
    maxx=maxx and math.max(maxx,item.right) or item.right
    maxy=maxy and math.max(maxy,item.bottom) or item.bottom
  end
  local cx,cy=(minx+maxx)/2,(miny+maxy)/2
  local updates={}
  for _,entry in ipairs(items) do
    updates[entry.uid]=Model.copy(entry.source)
  end
  local function move(entry,dx,dy)
    updates[entry.uid].x=entry.source.x+dx
    updates[entry.uid].y=entry.source.y+dy
  end
  if op=="left" or op=="centerX" or op=="right" or op=="top"
      or op=="centerY" or op=="bottom" then
    for _,entry in ipairs(items) do
      local dx,dy=0,0
      if op=="left" then dx=minx-entry.left
      elseif op=="centerX" then dx=cx-entry.cx
      elseif op=="right" then dx=maxx-entry.right
      elseif op=="top" then dy=miny-entry.top
      elseif op=="centerY" then dy=cy-entry.cy
      else dy=maxy-entry.bottom end
      move(entry,dx,dy)
    end
  elseif op=="distributeX" or op=="distributeY" then
    if #items<3 then return nil,"distribuicao exige pelo menos tres instancias" end
    local horizontal=op=="distributeX"
    table.sort(items,function(a,b)
      local av=horizontal and a.cx or a.cy
      local bv=horizontal and b.cx or b.cy
      return av==bv and a.uid<b.uid or av<bv
    end)
    local first=horizontal and items[1].cx or items[1].cy
    local last=horizontal and items[#items].cx or items[#items].cy
    local step=(last-first)/(#items-1)
    for i,entry in ipairs(items) do
      local current=horizontal and entry.cx or entry.cy
      local delta=first+(i-1)*step-current
      move(entry,horizontal and delta or 0,horizontal and 0 or delta)
    end
  elseif op=="move" then
    if type(value)~="table" or not finite(value.dx) or not finite(value.dy) then
      return nil,"deslocamento invalido"
    end
    for _,entry in ipairs(items) do move(entry,value.dx,value.dy) end
  elseif op=="scale" or op=="rotate" then
    if not finite(value) then return nil,"transformacao invalida" end
    if op=="scale" and (value<=0 or value>20) then return nil,"escala invalida" end
    local theta=op=="rotate" and math.rad(value) or 0
    local c,s=math.cos(theta),math.sin(theta)
    for _,entry in ipairs(items) do
      local original=entry.source
      local point=updates[entry.uid]
      local dx,dy=original.x-cx,original.y-cy
      if op=="scale" then
        point.x=cx+dx*value;point.y=cy+dy*value
        point.sx=original.sx*value;point.sy=original.sy*value
      else
        point.x=cx+dx*c-dy*s;point.y=cy+dx*s+dy*c
        point.angle=((original.angle or 0)+value)%360
      end
    end
  else
    return nil,"operacao desconhecida"
  end
  local changed=false
  for _,entry in ipairs(items) do
    local a,b=entry.source,updates[entry.uid]
    if not clampValid(b) then return nil,"limite de transformacao atingido" end
    if math.abs(a.x-b.x)>1e-8 or math.abs(a.y-b.y)>1e-8
        or math.abs(a.sx-b.sx)>1e-8 or math.abs(a.sy-b.sy)>1e-8
        or math.abs((a.angle or 0)-(b.angle or 0))>1e-8 then changed=true end
  end
  if not changed then return nil,"nenhuma alteracao" end
  return {apply=function()
    local layer=doc.layers[layerIndex]
    Model.ensureKey(layer,frame)
    local target=Library.ensureKey(lib,layerIndex,frame)
    for _,item in ipairs(target) do
      local adjusted=updates[item.uid]
      if adjusted then
        item.x,item.y=adjusted.x,adjusted.y
        item.sx,item.sy,item.angle=adjusted.sx,adjusted.sy,adjusted.angle or 0
      end
    end
  end}
end
-- Relative properties used by the Studio group inspector.
-- These are offsets/factors, never absolute coordinates of individual symbols.
function M.parseProperty(field,raw)
  if type(raw)~="string" or #raw>24 then return nil,"invalid number" end
  local s=raw:gsub("^%s+",""):gsub("%s+$","")
  if not s:match("^[%+%-]?%d*%.?%d+$") then return nil,"invalid number" end
  local value=tonumber(s)
  if not finite(value) then return nil,"invalid number" end
  if field=="dx" or field=="dy" then
    if math.abs(value)>100000 then return nil,"offset limit" end
    return "move",field=="dx" and {dx=value,dy=0} or {dx=0,dy=value}
  elseif field=="scale" then
    if value<10 or value>2000 then return nil,"scale limit (10-2000%)" end
    return "scale",value/100
  elseif field=="rotation" then
    if math.abs(value)>3600 then return nil,"rotation limit" end
    return "rotate",value
  end
  return nil,"unknown property"
end

return M
