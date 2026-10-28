-- Lua-Flash Player 0.21: safe input for native Lua-Flash documents.
-- No shell execution or external scripts; only binary .lflash/.lfgame data.
local Import={}
Import.MAX_BYTES=25*1024*1024
Import.MAX_PATH=2048
local function basename(name)
  return name:match("[^/\\]+$") or name
end
function Import.classify(path)
  if type(path)~="string" or #path==0 or #path>Import.MAX_PATH or
      path:find("%z") or path:find("[\r\n]") then
    return nil,"Caminho de arquivo invalido."
  end
  local lower=path:lower()
  if lower:sub(-7)==".lfgame" then return "game",basename(path) end
  if lower:sub(-7)==".lflash" then return "project",basename(path) end
  return nil,"Tipo de arquivo nao suportado: use .lflash ou .lfgame."
end
function Import.readPath(path,openFile)
  local kind,name=Import.classify(path)
  if not kind then return nil,name end
  local open=openFile or io.open
  local ok,file,err=pcall(open,path,"rb")
  if not ok or not file then
    return nil,"Nao foi possivel abrir o arquivo: "..tostring(ok and err or file)
  end
  local readOK,contents=pcall(function()
    return file:read(Import.MAX_BYTES+1)
  end)
  pcall(function() file:close() end)
  if not readOK or type(contents)~="string" then
    return nil,"Falha ao ler o arquivo."
  end
  if #contents==0 or #contents>Import.MAX_BYTES then
    return nil,"Arquivo vazio ou maior que 25 MB."
  end
  return {kind=kind,name=name,bytes=contents,path=path}
end
function Import.readDropped(file)
  local named,filename=pcall(function() return file:getFilename() end)
  if not named then return nil,"Nao foi possivel identificar o arquivo." end
  local kind,name=Import.classify(filename)
  if not kind then return nil,name end
  local ok,opened,err=pcall(function() return file:open("r") end)
  if not ok or not opened then
    return nil,"Nao foi possivel abrir o arquivo solto: "..tostring(ok and err or opened)
  end
  local readOK,contents=pcall(function()
    return file:read(Import.MAX_BYTES+1)
  end)
  pcall(function() file:close() end)
  if not readOK or type(contents)~="string" then
    return nil,"Falha ao ler o arquivo solto."
  end
  if #contents==0 or #contents>Import.MAX_BYTES then
    return nil,"Arquivo vazio ou maior que 25 MB."
  end
  return {kind=kind,name=name,bytes=contents,path=filename}
end
function Import.fromArguments(arguments)
  if type(arguments)~="table" then return nil end
  -- The love.load arguments normally omit the executable and .love path.
  -- Keep unrelated flags out and accept a single playable native file.
  for _,argument in ipairs(arguments) do
    if type(argument)=="string" and #argument<=Import.MAX_PATH and
      Import.classify(argument) then
      return argument
    end
  end
end
return Import
