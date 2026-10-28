-- Lua-Flash 0.22: Windows common Open File dialog, UTF-16 paths and
-- bounded Win32 file reads. No shell, PowerShell or spawned helpers.
-- Linux/macOS keep the cross-platform Ctrl+O path fallback.
local Native={}
local cached
local function api()
  if cached then return cached end
  if not love or not love.system or not love.system.getOS or
      love.system.getOS()~="Windows" then
    return nil,"Seletor nativo disponivel somente no Windows."
  end
  local ok,ffi=pcall(require,"ffi")
  if not ok then return nil,"LuaJIT FFI indisponivel." end
  local definitions=[[
    typedef struct {
      uint32_t lStructSize; void* hwndOwner; void* hInstance;
      const uint16_t* lpstrFilter; uint16_t* lpstrCustomFilter;
      uint32_t nMaxCustFilter; uint32_t nFilterIndex;
      uint16_t* lpstrFile; uint32_t nMaxFile;
      uint16_t* lpstrFileTitle; uint32_t nMaxFileTitle;
      const uint16_t* lpstrInitialDir; const uint16_t* lpstrTitle;
      uint32_t Flags; uint16_t nFileOffset; uint16_t nFileExtension;
      const uint16_t* lpstrDefExt; uintptr_t lCustData; void* lpfnHook;
      const uint16_t* lpTemplateName; void* pvReserved;
      uint32_t dwReserved; uint32_t FlagsEx;
    } LUAF_OPENFILENAMEW;
    int __stdcall GetOpenFileNameW(LUAF_OPENFILENAMEW*);
    uint32_t __stdcall CommDlgExtendedError(void);
    int __stdcall MultiByteToWideChar(uint32_t,uint32_t,const char*,int,
      uint16_t*,int);
    int __stdcall WideCharToMultiByte(uint32_t,uint32_t,const uint16_t*,int,
      char*,int,const char*,int*);
    void* __stdcall CreateFileW(const uint16_t*,uint32_t,uint32_t,void*,
      uint32_t,uint32_t,void*);
    int __stdcall GetFileSizeEx(void*,int64_t*);
    int __stdcall ReadFile(void*,void*,uint32_t,uint32_t*,void*);
    int __stdcall CloseHandle(void*);
  ]]
  local declared=pcall(ffi.cdef,definitions)
  if not declared then return nil,"Declaracoes Win32 indisponiveis." end
  local loaded,comdlg=pcall(ffi.load,"comdlg32")
  if not loaded then return nil,"Dialogo do Windows indisponivel." end
  local kernelOK,kernel=pcall(ffi.load,"kernel32")
  if not kernelOK then return nil,"Acesso de arquivos Win32 indisponivel." end
  cached={ffi=ffi,dialog=comdlg,kernel=kernel}
  return cached
end
function Native.available()
  return api()~=nil
end
local function toWide(win,text)
  if type(text)~="string" or #text==0 then return nil end
  local n=win.kernel.MultiByteToWideChar(65001,8,text,#text,nil,0)
  if n<=0 or n>32767 then return nil end
  local buf=win.ffi.new("uint16_t[?]",n+1)
  if win.kernel.MultiByteToWideChar(65001,8,text,#text,buf,n)~=n then
    return nil
  end
  buf[n]=0
  return buf
end
local function fromWide(win,buf)
  local count=win.kernel.WideCharToMultiByte(65001,0,buf,-1,nil,0,nil,nil)
  if count<=1 or count>32768 then return nil end
  local out=win.ffi.new("char[?]",count)
  if win.kernel.WideCharToMultiByte(65001,0,buf,-1,out,count,nil,nil)~=count then
    return nil
  end
  return win.ffi.string(out,count-1)
end
local function asError(prefix)
  return prefix.." Verifique as permissoes, o formato e o caminho."
end

-- A Unicode-safe alternative to LuaJIT's C runtime io.open, which can
-- misinterpret UTF-8 paths on some Windows locales.
function Native.readPath(path,maxBytes)
  local win,err=api()
  if not win then return nil,err end
  if type(path)~="string" or #path==0 or #path>2048 or
      path:find("[%z\r\n]") then
    return nil,"Caminho invalido."
  end
  local wide=toWide(win,path)
  if not wide then return nil,"Caminho Unicode invalido." end
  local ffi=win.ffi
  local handle=win.kernel.CreateFileW(wide,0x80000000,0x00000001,nil,3,0x80,nil)
  if handle==nil or handle==ffi.cast("void*",-1) then
    return nil,asError("Nao foi possivel abrir o arquivo.")
  end
  local function close() win.kernel.CloseHandle(handle) end
  local size=ffi.new("int64_t[1]")
  if win.kernel.GetFileSizeEx(handle,size)==0 then
    close()
    return nil,"Nao foi possivel consultar o tamanho do arquivo."
  end
  local length=tonumber(size[0])
  if length<=0 or length>math.min(maxBytes or 25*1024*1024,25*1024*1024) then
    close()
    return nil,"Arquivo vazio ou maior que 25 MB."
  end
  local bytes=ffi.new("uint8_t[?]",length)
  local read=ffi.new("uint32_t[1]")
  local ok=win.kernel.ReadFile(handle,bytes,length,read,nil)
  close()
  if ok==0 or tonumber(read[0])~=length then
    return nil,"Falha na leitura integral do arquivo."
  end
  return ffi.string(bytes,length)
end

local function asciiWide(win,text)
  local value=win.ffi.new("uint16_t[?]",#text)
  for i=1,#text do value[i-1]=text:byte(i) end
  return value
end
function Native.choose(maxBytes)
  local win,err=api()
  if not win then return nil,err end
  local ffi=win.ffi
  local filename=ffi.new("uint16_t[?]",32768)
  local filter=asciiWide(win,
    "Lua-Flash (*.lflash;*.lfgame)\0*.lflash;*.lfgame\0Todos os arquivos\0*.*\0\0")
  local title=asciiWide(win,"Abrir projeto Lua-Flash\0")
  local options=ffi.new("LUAF_OPENFILENAMEW")
  options.lStructSize=ffi.sizeof(options)
  options.lpstrFilter=filter
  options.nFilterIndex=1
  options.lpstrFile=filename
  options.nMaxFile=32768
  options.lpstrTitle=title
  -- EXPLORER | FILEMUSTEXIST | PATHMUSTEXIST | NOCHANGEDIR | HIDEREADONLY
  options.Flags=0x80000+0x1000+0x800+0x8+0x4
  if win.dialog.GetOpenFileNameW(options)==0 then
    local code=tonumber(win.dialog.CommDlgExtendedError())
    if code==0 then return nil,"cancelled" end
    return nil,"Erro no seletor do Windows: "..tostring(code)
  end
  local path=fromWide(win,filename)
  if not path then return nil,"O caminho selecionado nao e UTF-8 valido." end
  local bytes,problem=Native.readPath(path,maxBytes)
  if not bytes then return nil,problem end
  return {path=path,bytes=bytes}
end
return Native
