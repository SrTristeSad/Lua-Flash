-- Studio-only Flash exposure adaptation. Shared model remains identical to Player.
local M={}
-- Flash-style exposure spans derived from native keyframes. These are not
-- stored redundantly: existing LUAFLASH 1 projects remain byte-compatible.
-- A blank keyframe is an explicit empty table; in-between frames hold exposure.
function M.spans(layer, totalFrames)
  local spans, indices = {}, {}
  if not layer or not layer.keys then return spans end
  for n in pairs(layer.keys) do
    if type(n) == "number" and n >= 1 and n <= totalFrames
        and n == math.floor(n) then indices[#indices + 1] = n end
  end
  table.sort(indices)
  for i, n in ipairs(indices) do
    local following = indices[i + 1] or (totalFrames + 1)
    spans[#spans + 1] = {
      index = n, duration = following - n,
      blank = #layer.keys[n] == 0, objects = layer.keys[n]
    }
  end
  return spans
end

function M.exposure(layer, n, totalFrames)
  if not layer or type(n) ~= "number" or n < 1
      or type(totalFrames) ~= "number" or n > totalFrames then return nil end
  local best = nil
  for key in pairs(layer.keys) do
    if type(key) == "number" and key <= n and (not best or key > best) then best = key end
  end
  if not best then return nil end
  local following = totalFrames + 1
  for key in pairs(layer.keys) do
    if type(key) == "number" and key > best and key < following then following = key end
  end
  return {
    index = best, duration = following - best, blank = #layer.keys[best] == 0,
    isKey = best == n, objects = layer.keys[best]
  }
end

function M.insertBlankKey(layer, n)
  assert(layer and type(n) == "number" and n >= 1 and n == math.floor(n), "invalid layer/frame")
  layer.keys[n] = {}
  return layer.keys[n]
end

return M
