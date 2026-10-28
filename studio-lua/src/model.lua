-- Lua-Flash document model; pure Lua, without external dependencies.
local M = {}

local function copy(v)
  if type(v) ~= "table" then return v end
  local t = {}
  for k, x in pairs(v) do t[k] = copy(x) end
  return t
end
M.copy = copy

function M.new(width, height, fps)
  return {
    width = width or 800, height = height or 450, fps = fps or 24,
    totalFrames = 60, currentFrame = 1, currentLayer = 1,
    layers = {{name = "Camada 1", visible = true, locked = false, keys = {[1] = {}}}}
  }
end

function M.frame(layer, n)
  local best = -1
  local objects = {}
  if not layer then return objects end
  for index, shapes in pairs(layer.keys) do
    if index <= n and index > best then best, objects = index, shapes end
  end
  return objects
end

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

function M.isKey(layer, n) return layer and layer.keys[n] ~= nil end

function M.ensureKey(layer, n)
  assert(layer and n >= 1, "invalid layer/frame")
  if not layer.keys[n] then layer.keys[n] = copy(M.frame(layer, n)) end
  return layer.keys[n]
end

function M.removeKey(layer, n)
  if not layer or n == 1 or not layer.keys[n] then return false end
  layer.keys[n] = nil
  return true
end

function M.addLayer(doc)
  local n = #doc.layers + 1
  doc.layers[n] = {name = "Camada " .. n, visible = true, locked = false, keys = {[1] = {}}}
  doc.currentLayer = n
  return doc.layers[n]
end

function M.makeShape(kind, color, thickness, x, y)
  return {
    kind = kind, color = copy(color), thickness = thickness or 3,
    points = {x, y, x, y}
  }
end

function M.move(shape, dx, dy)
  for i = 1, #shape.points, 2 do
    shape.points[i] = shape.points[i] + dx
    shape.points[i + 1] = shape.points[i + 1] + dy
  end
end

function M.bounds(shape)
  local p = shape.points
  local x1, y1, x2, y2 = p[1], p[2], p[1], p[2]
  for i = 3, #p, 2 do
    local x, y = p[i], p[i + 1]
    x1, y1, x2, y2 = math.min(x1, x), math.min(y1, y), math.max(x2, x), math.max(y2, y)
  end
  return x1, y1, x2, y2
end

function M.hit(shape, x, y)
  local x1, y1, x2, y2 = M.bounds(shape)
  local t = math.max(6, (shape.thickness or 3) + 3)
  return x >= x1 - t and x <= x2 + t and y >= y1 - t and y <= y2 + t
end

local function esc(s)
  return (tostring(s):gsub("[^%w%-%._]", function(ch)
    return string.format("%%%02X", string.byte(ch))
  end))
end

local function unesc(s)
  return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

local function fmt(x)
  return string.format("%.5f", x)
end

function M.encode(doc)
  local out = {"LUAFLASH 1", table.concat({
    "DOC", doc.width, doc.height, doc.fps, doc.totalFrames, doc.currentFrame, doc.currentLayer
  }, "\t")}
  for _, layer in ipairs(doc.layers) do
    out[#out + 1] = table.concat({"LAYER", esc(layer.name), layer.visible and 1 or 0, layer.locked and 1 or 0}, "\t")
    local keys = {}
    for n in pairs(layer.keys) do keys[#keys + 1] = n end
    table.sort(keys)
    for _, n in ipairs(keys) do
      out[#out + 1] = "KEY\t" .. n
      for _, shape in ipairs(layer.keys[n]) do
        local pts = {}
        for j = 1, #shape.points, 2 do
          pts[#pts + 1] = fmt(shape.points[j]) .. "," .. fmt(shape.points[j + 1])
        end
        out[#out + 1] = table.concat({
          "SHAPE", shape.kind, fmt(shape.color[1]), fmt(shape.color[2]),
          fmt(shape.color[3]), fmt(shape.thickness), table.concat(pts, ";")
        }, "\t")
      end
      out[#out + 1] = "ENDKEY"
    end
    out[#out + 1] = "ENDLAYER"
  end
  out[#out + 1] = "END"
  return table.concat(out, "\n") .. "\n"
end

local function split(line)
  local fields = {}
  for f in (line .. "\t"):gmatch("(.-)\t") do fields[#fields + 1] = f end
  return fields
end

local allowed = {brush = true, line = true, rect = true, ellipse = true}

function M.decode(data)
  if type(data) ~= "string" or #data > 25 * 1024 * 1024 then return nil, "invalid project size" end
  local lines = {}
  for s in (data .. "\n"):gmatch("(.-)\n") do
    if s ~= "" then lines[#lines + 1] = s:gsub("\r$", "") end
  end
  if lines[1] ~= "LUAFLASH 1" then return nil, "unsupported .lflash format" end
  local head = split(lines[2] or "")
  local w, h, fps = tonumber(head[2]), tonumber(head[3]), tonumber(head[4])
  if head[1] ~= "DOC" or not w or not h or not fps or w < 1 or h < 1 or w > 16000 or h > 16000 or fps < 1 or fps > 120 then
    return nil, "invalid document header"
  end
  local doc = M.new(w, h, fps)
  doc.totalFrames = math.max(1, math.min(10000, tonumber(head[5]) or 60))
  doc.currentFrame = math.max(1, math.min(doc.totalFrames, tonumber(head[6]) or 1))
  doc.currentLayer = tonumber(head[7]) or 1
  doc.layers = {}
  local layer, frame
  local shapeCount = 0
  for i = 3, #lines do
    local f = split(lines[i])
    if f[1] == "LAYER" then
      if layer or #doc.layers >= 128 then return nil, "invalid layer nesting/count" end
      layer = {name = unesc(f[2] or "Camada"), visible = f[3] == "1", locked = f[4] == "1", keys = {}}
      doc.layers[#doc.layers + 1] = layer
    elseif f[1] == "KEY" then
      frame = tonumber(f[2])
      if not layer or not frame or frame < 1 or frame > doc.totalFrames or layer.keys[frame] then return nil, "invalid keyframe" end
      layer.keys[frame] = {}
    elseif f[1] == "SHAPE" then
      if not layer or not frame or not allowed[f[2]] then return nil, "invalid shape" end
      local color, thickness = {tonumber(f[3]), tonumber(f[4]), tonumber(f[5])}, tonumber(f[6])
      if not color[1] or not color[2] or not color[3] or not thickness or thickness < 0 or thickness > 1000 then
        return nil, "invalid shape style"
      end
      local pts = {}
      for pair in (f[7] or ""):gmatch("[^;]+") do
        local a, b = pair:match("^([^,]+),([^,]+)$")
        local x, y = tonumber(a), tonumber(b)
        if not x or not y or #pts > 8192 then return nil, "invalid shape points" end
        pts[#pts + 1] = x
        pts[#pts + 1] = y
      end
      if #pts < 4 or (#pts % 2 ~= 0) then return nil, "empty shape" end
      shapeCount = shapeCount + 1
      if shapeCount > 100000 then return nil, "too many shapes" end
      layer.keys[frame][#layer.keys[frame] + 1] = {
        kind = f[2], color = color, thickness = thickness, points = pts
      }
    elseif f[1] == "ENDKEY" then
      if not frame then return nil, "unexpected ENDKEY" end
      frame = nil
    elseif f[1] == "ENDLAYER" then
      if not layer or frame then return nil, "unexpected ENDLAYER" end
      layer = nil
    elseif f[1] == "END" then
      if layer or frame then return nil, "unfinished project" end
      break
    else
      return nil, "unknown record " .. tostring(f[1])
    end
  end
  if #doc.layers < 1 then return nil, "project has no layers" end
  for _, l in ipairs(doc.layers) do l.keys[1] = l.keys[1] or {} end
  doc.currentLayer = math.max(1, math.min(#doc.layers, doc.currentLayer))
  return doc
end

local function rgb(shape)
  local c = shape.color
  return string.format("#%02X%02X%02X", math.floor(c[1] * 255 + .5),
    math.floor(c[2] * 255 + .5), math.floor(c[3] * 255 + .5))
end

function M.svg(doc, n)
  local lines = {
    string.format('<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">', doc.width, doc.height, doc.width, doc.height),
    string.format('<rect width="%d" height="%d" fill="white"/>', doc.width, doc.height)
  }
  for _, layer in ipairs(doc.layers) do
    if layer.visible then
      for _, shape in ipairs(M.frame(layer, n)) do
        local p, color, thick = shape.points, rgb(shape), shape.thickness
        if shape.kind == "brush" then
          local parts = {"M", fmt(p[1]), fmt(p[2])}
          for i = 3, #p, 2 do parts[#parts + 1] = "L"; parts[#parts + 1] = fmt(p[i]); parts[#parts + 1] = fmt(p[i + 1]) end
          lines[#lines + 1] = string.format('<path d="%s" stroke="%s" stroke-width="%s" stroke-linecap="round" stroke-linejoin="round" fill="none"/>',
            table.concat(parts, " "), color, fmt(thick))
        elseif shape.kind == "line" then
          lines[#lines + 1] = string.format('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>',
            fmt(p[1]), fmt(p[2]), fmt(p[3]), fmt(p[4]), color, fmt(thick))
        elseif shape.kind == "rect" then
          local x1, y1, x2, y2 = M.bounds(shape)
          lines[#lines + 1] = string.format('<rect x="%s" y="%s" width="%s" height="%s" fill="%s"/>',
            fmt(x1), fmt(y1), fmt(x2-x1), fmt(y2-y1), color)
        elseif shape.kind == "ellipse" then
          local x1, y1, x2, y2 = M.bounds(shape)
          lines[#lines + 1] = string.format('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"/>',
            fmt((x1+x2)/2), fmt((y1+y2)/2), fmt((x2-x1)/2), fmt((y2-y1)/2), color)
        end
      end
    end
  end
  lines[#lines + 1] = "</svg>"
  return table.concat(lines, "\n") .. "\n"
end

return M
