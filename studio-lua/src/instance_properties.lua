-- Numeric property validation for editable Studio instance fields.
local Transform=require("src.instance_transform")
local M={}
M.fields={"x","y","sx","sy","angle"}
function M.read(instance,field)
  if field=="angle" then return instance.angle or 0 end
  return instance[field]
end
function M.format(instance,field)
  local v=M.read(instance,field)
  if field=="x" or field=="y" then return string.format("%.2f",v) end
  if field=="angle" then return string.format("%.1f",v) end
  return string.format("%.3f",v)
end
function M.set(instance,field,text)
  if type(text)~="string" or #text>32 then return nil,"invalid numeric input" end
  local sanitized=text:gsub("^%s+",""):gsub("%s+$","")
  if sanitized=="" or not sanitized:match("^[%+%-]?%d*%.?%d+$") then
    return nil,"invalid numeric input"
  end
  local value=tonumber(sanitized)
  if not value or value~=value or math.abs(value)==math.huge then
    return nil,"nonfinite number"
  end
  local copy={}
  for k,v in pairs(instance) do copy[k]=v end
  if field=="x" or field=="y" then
    if math.abs(value)>100000 then return nil,"position limit" end
  elseif field=="sx" or field=="sy" then
    if math.abs(value)<0.1 or math.abs(value)>20 then return nil,"scale limit" end
  elseif field=="angle" then
    value=value%360
  else return nil,"unknown field" end
  copy[field]=value
  if not Transform.valid(copy) then return nil,"invalid transform" end
  return copy
end
return M
