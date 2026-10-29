-- Transactional Studio layer management.
-- Indices are serialized into LUAFLASH, LFLIB and LFVECTOR. Moving a layer
-- must therefore permute all three tracks together, never only doc.layers.
local M={}

local function validIndex(doc,index)
  return type(doc)=="table" and type(doc.layers)=="table"
    and type(index)=="number" and index%1==0
    and index>=1 and index<=#doc.layers
end

function M.cleanName(value)
  if type(value)~="string" then return nil,"nome invalido" end
  local name=value:gsub("^%s+",""):gsub("%s+$","")
  if #name<1 or #name>48 or name:find("[%z\1-\31\127]") then
    return nil,"nome deve ter 1 a 48 bytes e nao conter controles"
  end
  return name
end

function M.planRename(doc,index,value)
  if not validIndex(doc,index) then return nil,"camada inexistente" end
  local name,err=M.cleanName(value)
  if not name then return nil,err end
  if doc.layers[index].name==name then return nil,"nome sem alteracao" end
  return {name=name,apply=function()
    doc.layers[index].name=name
  end}
end

function M.planMove(doc,library,vectors,index,delta)
  if not validIndex(doc,index) or (delta~=-1 and delta~=1) then
    return nil,"movimento de camada invalido"
  end
  local dest=index+delta
  if not validIndex(doc,dest) then
    return nil,"camada ja esta no limite da pilha"
  end
  if type(library)~="table" or type(library.tracks)~="table"
      or type(vectors)~="table" or type(vectors.tracks)~="table" then
    return nil,"dados de instancias ou vetores invalidos"
  end
  return {
    from=index,to=dest,apply=function()
      doc.layers[index],doc.layers[dest]=doc.layers[dest],doc.layers[index]
      library.tracks[index],library.tracks[dest]=
        library.tracks[dest],library.tracks[index]
      vectors.tracks[index],vectors.tracks[dest]=
        vectors.tracks[dest],vectors.tracks[index]
      doc.currentLayer=dest
    end
  }
end

return M
