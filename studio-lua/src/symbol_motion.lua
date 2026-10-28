-- Studio-only symbol clock model. No Flash bytecode or Player dependency.
-- Graphic: parent timeline synchronized; MovieClip: per-instance clock;
-- Button: Up/Over/Down frames, fourth frame reserved for hit testing.
local Library=require("src.symbol_library")
local M={}
function M.new()
  return {clocks={},lastVisible={},hover=nil,pressed=nil,mouseX=nil,mouseY=nil}
end
local function total(symbol)
  return math.max(1,math.floor(symbol.definition.totalFrames or 1))
end
local function sourceFrame(lib,layer,frame)
  local track=lib.tracks[layer]
  if not track then return frame end
  local source=0
  for n in pairs(track) do
    if n<=frame and n>source then source=n end
  end
  return source>0 and source or frame
end
function M.reset(state)
  state.clocks={}
  state.lastVisible={}
  state.hover=nil
  state.pressed=nil
end
function M.update(state,lib,doc,frame,dt,playing)
  local visible={}
  for layerIndex,layer in ipairs(doc.layers) do
    if layer.visible then
      for _,instance in ipairs(Library.at(lib,layerIndex,frame)) do
        local symbol=Library.find(lib,instance.symbolId)
        if symbol and symbol.kind=="movieclip" then
          local key=tostring(layerIndex)..":"..tostring(instance.uid)
          visible[key]=true
          if not state.lastVisible[key] then
            state.clocks[key]=0
          elseif playing then
            -- Cap a runaway frame after a suspended app; accumulate deterministic dt.
            state.clocks[key]=(state.clocks[key] or 0)+math.max(0,math.min(dt or 0,0.2))
          end
        end
      end
    end
  end
  for key in pairs(state.clocks) do
    if not visible[key] then state.clocks[key]=nil end
  end
  state.lastVisible=visible
end
function M.frame(state,lib,symbol,instance,layerIndex,parentFrame)
  local count=total(symbol)
  if symbol.kind=="graphic" then
    local source=sourceFrame(lib,layerIndex,parentFrame)
    return (parentFrame-source)%count+1
  elseif symbol.kind=="movieclip" then
    local key=tostring(layerIndex)..":"..tostring(instance.uid)
    local elapsed=state.clocks[key] or 0
    local fps=math.max(1,math.min(120,symbol.definition.fps or 24))
    return math.floor(elapsed*fps)%count+1
  end
  if state.pressed==instance.uid and state.hover==instance.uid then
    return math.min(count,3)
  elseif state.hover==instance.uid then
    return math.min(count,2)
  end
  return 1
end
function M.setHover(state,uid) state.hover=uid end
function M.press(state) state.pressed=state.hover end
function M.release(state) state.pressed=nil end
return M
