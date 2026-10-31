-- Ripple timeline duration without modifying native LUAFLASH/LUALIB/LFVECTOR codecs.
-- Insertion is AFTER the current frame; deletion removes the FOLLOWING frame,
-- or the last frame when the playhead is already at the end.
local M={}
local LIMIT=10000

local function integer(v)
  return type(v)=="number" and v==math.floor(v)
end

local function validateTrack(track,total)
  if type(track)~="table" then return false end
  for frame in pairs(track) do
    if not integer(frame) or frame<1 or frame>total then return false end
  end
  return true
end

local function shifted(track,pivot,operation)
  local result={}
  for frame,objects in pairs(track) do
    local destination=frame
    if operation=="insert" then
      if frame>pivot then destination=frame+1 end
    elseif frame>pivot then
      destination=frame-1
    end
    result[destination]=objects
  end
  return result
end

local function prepareSidecar(source,total,count)
  if type(source)~="table" or type(source.tracks)~="table" then
    return nil,"trilhas auxiliares invalidas"
  end
  for layer,track in pairs(source.tracks) do
    if not integer(layer) or layer<1 or layer>count
        or not validateTrack(track,total) then
      return nil,"trilha auxiliar fora da timeline"
    end
  end
  return source.tracks
end

function M.plan(doc,library,vectors,frame,operation)
  if type(doc)~="table" or type(doc.layers)~="table"
      or #doc.layers<1 or not integer(doc.totalFrames)
      or doc.totalFrames<1 or doc.totalFrames>LIMIT
      or not integer(frame) or frame<1 or frame>doc.totalFrames
      or (operation~="insert" and operation~="remove") then
    return nil,"posicao ou operacao invalida"
  end
  if operation=="insert" and doc.totalFrames==LIMIT then
    return nil,"limite de 10000 quadros atingido"
  end
  if operation=="remove" and doc.totalFrames==1 then
    return nil,"a cena precisa manter um quadro"
  end

  local count=#doc.layers
  local libraryTracks,libErr=prepareSidecar(library,doc.totalFrames,count)
  if not libraryTracks then return nil,libErr end
  local vectorTracks,vecErr=prepareSidecar(vectors,doc.totalFrames,count)
  if not vectorTracks then return nil,vecErr end

  local pivot=operation=="insert" and frame
    or math.min(frame+1,doc.totalFrames)
  local layerTracks={}
  for index,layer in ipairs(doc.layers) do
    if type(layer)~="table" or not validateTrack(layer.keys,doc.totalFrames)
        or not layer.keys[1] then
      return nil,"camada com quadros invalidos: "..index
    end
    layerTracks[index]=layer.keys
  end
  if operation=="remove" then
    for _,track in ipairs(layerTracks) do
      if track[pivot]~=nil then
        return nil,"ha quadro-chave no quadro "..pivot
      end
    end
    for _,tracks in ipairs({libraryTracks,vectorTracks}) do
      for _,track in pairs(tracks) do
        if track[pivot]~=nil then
          return nil,"ha conteudo auxiliar no quadro "..pivot
        end
      end
    end
  end

  local newLayerTracks={}
  for index,track in ipairs(layerTracks) do
    newLayerTracks[index]=shifted(track,pivot,operation)
  end
  local function remap(tracks)
    local updated={}
    for index,track in pairs(tracks) do
      updated[index]=shifted(track,pivot,operation)
    end
    return updated
  end
  local newLibraryTracks=remap(libraryTracks)
  local newVectorTracks=remap(vectorTracks)
  local newTotal=doc.totalFrames+(operation=="insert" and 1 or -1)
  local newCurrent=math.min(frame,newTotal)
  return {
    action=operation,affectedFrame=operation=="insert" and pivot+1 or pivot,
    totalFrames=newTotal,
    apply=function()
      for index,layer in ipairs(doc.layers) do layer.keys=newLayerTracks[index] end
      library.tracks=newLibraryTracks
      vectors.tracks=newVectorTracks
      doc.totalFrames=newTotal
      doc.currentFrame=newCurrent
    end
  }
end

return M
