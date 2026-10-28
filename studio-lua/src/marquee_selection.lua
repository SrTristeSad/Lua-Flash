-- Marquee selection of visible symbol instances in the active layer.
-- Left-to-right requires full containment; right-to-left selects intersections.
-- This module never mutates the scene or symbol tracks.
local Library=require("src.symbol_library")
local Transform=require("src.instance_transform")
local M={}
local function valid(v) return type(v)=="number" and v==v and math.abs(v)<math.huge end
function M.bounds(ax,ay,bx,by)
  if not (valid(ax) and valid(ay) and valid(bx) and valid(by)) then return nil end
  return math.min(ax,bx),math.min(ay,by),math.max(ax,bx),math.max(ay,by)
end
function M.select(lib,doc,layerIndex,frame,ax,ay,bx,by)
  local x1,y1,x2,y2=M.bounds(ax,ay,bx,by)
  if not x1 then return nil,"invalid rectangle" end
  local layer=doc.layers[layerIndex]
  if not layer or not layer.visible or layer.locked then return {} end
  if x2-x1<.001 or y2-y1<.001 then return {} end
  local contained=ax<=bx
  local selected={}
  for _,item in ipairs(Library.at(lib,layerIndex,frame)) do
    local symbol=Library.find(lib,item.symbolId)
    if symbol and Transform.valid(item) then
      local ix1,iy1,ix2,iy2=Transform.box(item,symbol,1)
      if ix1 then
        local matches
        if contained then
          matches=ix1>=x1 and iy1>=y1 and ix2<=x2 and iy2<=y2
        else
          matches=ix2>=x1 and ix1<=x2 and iy2>=y1 and iy1<=y2
        end
        if matches then selected[item.uid]=true end
      end
    end
  end
  return selected
end
function M.merge(existing,newSelection,add)
  local merged={}
  if add then
    for id,enabled in pairs(existing or {}) do if enabled then merged[id]=true end end
  end
  for id,enabled in pairs(newSelection or {}) do if enabled then merged[id]=true end end
  return merged
end
return M
