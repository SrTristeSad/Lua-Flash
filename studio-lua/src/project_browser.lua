-- Project discovery and sidecar loading within LÖVE's save directory.
-- File names are deliberately restricted to the Studio Save As convention.
local M={}
function M.validName(name)
  return type(name)=="string" and #name>=1 and #name<=64
    and not name:find("[^%w_%-]")
end
function M.list(fs)
  if type(fs)~="table" or type(fs.getDirectoryItems)~="function" then
    return nil,"listagem de projetos indisponivel"
  end
  local ok,items=pcall(fs.getDirectoryItems,"")
  if not ok or type(items)~="table" then
    return nil,"nao foi possivel listar projetos"
  end
  local projects={}
  local seen={}
  for _,filename in ipairs(items) do
    if type(filename)=="string" and filename:sub(-7)==".lflash" then
      local name=filename:sub(1,-8)
      if M.validName(name) and not seen[name] then
        local info=fs.getInfo and fs.getInfo(filename)
        if not info or info.type=="file" then
          projects[#projects+1]={name=name,modified=info and info.modtime or 0}
          seen[name]=true
        end
      end
    end
  end
  table.sort(projects,function(a,b)
    if a.modified==b.modified then return a.name<b.name end
    return a.modified>b.modified
  end)
  return projects
end
function M.read(fs,name)
  if not M.validName(name) then return nil,"nome de projeto invalido" end
  if type(fs)~="table" or type(fs.read)~="function" then
    return nil,"leitura de projetos indisponivel"
  end
  local filename=name..".lflash"
  local doc,err=fs.read(filename)
  if not doc then return nil,"nao foi possivel ler "..filename..": "..tostring(err) end
  local function optional(extension)
    local path=filename..extension
    local bytes,why=fs.read(path)
    if not bytes and fs.getInfo and fs.getInfo(path) then
      return nil,"erro na leitura de "..path..": "..tostring(why)
    end
    return bytes
  end
  local library,libraryErr=optional(".lflib")
  if libraryErr then return nil,libraryErr end
  local vectors,vectorsErr=optional(".lfvec")
  if vectorsErr then return nil,vectorsErr end
  return {document=doc,library=library,vectors=vectors}
end
return M
