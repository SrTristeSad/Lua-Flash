-- Atomic Studio-only keyframe edits across native artwork and symbol instances.
-- No modifications to shared Player core / LUAFLASH 1.
local Model=require("src.model")
local M={}

local function integer(n)
  return type(n)=="number" and n==math.floor(n)
end

-- Build and validate the entire operation before touching either document.
-- A transaction is applied by the caller after recording the undo snapshot.
function M.plan(doc,library,layerIndex,sources,delta,duplicate)
  local layer=doc.layers[layerIndex]
  if not layer or layer.locked then return nil,"camada bloqueada ou inexistente" end
  if not integer(delta) or delta==0 then return nil,"deslocamento invalido" end
  if type(sources)~="table" or #sources==0 then return nil,"sem quadros selecionados" end

  local sourceSet,ordered={},{}
  for _,source in ipairs(sources) do
    if not integer(source) or source<1 or source>doc.totalFrames
        or not layer.keys[source] then return nil,"quadro de origem invalido" end
    if not sourceSet[source] then
      sourceSet[source]=true
      ordered[#ordered+1]=source
    end
  end
  table.sort(ordered)
  local sourceTrack=library.tracks[layerIndex]
  local artwork,instances,uidMap={}, {}, {}
  local nextUID=library.nextInstanceId
  for _,source in ipairs(ordered) do
    local dest=source+delta
    if dest<1 or dest>doc.totalFrames
        or (not duplicate and source==1)
        or (layer.keys[dest] and (duplicate or not sourceSet[dest]))
        or (sourceTrack and sourceTrack[dest]
          and (duplicate or not sourceSet[dest])) then
      return nil,"destino ocupado, limite ou quadro inicial"
    end

    artwork[dest]=Model.copy(layer.keys[source])
    if sourceTrack and sourceTrack[source] then
      local cloned=Model.copy(sourceTrack[source])
      if duplicate then
        for _,instance in ipairs(cloned) do
          local id=instance.uid
          if not uidMap[id] then
            if not integer(nextUID) or nextUID>100000000 then
              return nil,"limite de identificadores de instancias"
            end
            uidMap[id]=nextUID
            nextUID=nextUID+1
          end
          instance.uid=uidMap[id]
        end
      end
      instances[dest]=cloned
    end
  end

  local transaction={destinations={}}
  for _,source in ipairs(ordered) do
    transaction.destinations[#transaction.destinations+1]=source+delta
  end
  function transaction.apply()
    if not duplicate then
      for _,source in ipairs(ordered) do
        layer.keys[source]=nil
        if sourceTrack then sourceTrack[source]=nil end
      end
    end
    for dest,objects in pairs(artwork) do layer.keys[dest]=objects end
    if next(instances) then
      if not library.tracks[layerIndex] then library.tracks[layerIndex]={} end
      for dest,items in pairs(instances) do library.tracks[layerIndex][dest]=items end
    end
    library.nextInstanceId=nextUID
  end
  return transaction
end

return M
