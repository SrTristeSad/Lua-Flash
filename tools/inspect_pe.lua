-- Lua-Flash: read-only PE32/PE32+ structural inspector.
-- No executable code is loaded or run. Lua 5.1+ compatible.
-- Usage: lua tools/inspect_pe.lua path/to/program.exe

local function inspect(data)
  local length = #data
  local function guard(pos, size)
    if type(pos) ~= 'number' or pos < 1 or size < 0 or
       pos > length + 1 or size > length - pos + 1 then
      error('PE data truncated or outside file at offset ' .. tostring((pos or 1)-1), 0)
    end
  end
  local function byte(pos) guard(pos, 1); return data:byte(pos) end
  local function word(pos)
    guard(pos, 2)
    local a,b = data:byte(pos, pos+1)
    return a + 256*b
  end
  local function dword(pos)
    guard(pos, 4)
    local a,b,c,d = data:byte(pos, pos+3)
    return a + 256*b + 65536*c + 16777216*d
  end
  local function ascii(pos, maxLen)
    guard(pos, 1)
    local endpos = math.min(length, pos + (maxLen or 256) - 1)
    local stop = data:find('\0', pos, true)
    if stop and stop <= endpos then endpos = stop-1 end
    return data:sub(pos, endpos)
  end
  if length < 128 or data:sub(1,2) ~= 'MZ' then error('Not an MZ executable') end
  local pe = dword(0x3c+1) + 1
  guard(pe,24)
  if data:sub(pe,pe+3) ~= 'PE\0\0' then error('Not a PE file') end
  local machine, sectionCount = word(pe+4), word(pe+6)
  local timestamp = dword(pe+8)
  local optSize = word(pe+20)
  local optional = pe+24
  guard(optional, optSize)
  if sectionCount < 1 or sectionCount > 96 then error('Unexpected section count') end
  local magic=word(optional)
  if magic~=0x10b and magic~=0x20b then error('Unknown PE optional header') end
  local directories = optional + (magic==0x10b and 96 or 112)
  local countOffset=optional+(magic==0x10b and 92 or 108)
  if dword(countOffset)<5 or directories + 5*8-1 > optional+optSize then
    error('Missing required data directories')
  end
  local function dir(i) return dword(directories+i*8),dword(directories+i*8+4) end
  local sections = {}
  for i=0, sectionCount-1 do
    local off=optional+optSize+i*40
    guard(off,40)
    local item={name=ascii(off,8), virtualSize=dword(off+8), rva=dword(off+12),
      rawSize=dword(off+16), fileOffset=dword(off+20)}
    sections[#sections+1] = item
  end
  local function raw(rva)
    for _,s in ipairs(sections) do
      if rva>=s.rva and rva < s.rva + math.max(s.virtualSize,s.rawSize) then
        local off=s.fileOffset + (rva-s.rva) + 1
        guard(off,1)
        return off
      end
    end
    error(string.format('Unmapped RVA 0x%X',rva),0)
  end
  local imports = {}
  local importRva, importSize=dir(1)
  if importRva ~= 0 then
    local base=raw(importRva)
    for i=0,math.min(256,math.floor(importSize/20)) do
      local p=base + i*20
      guard(p,20)
      local orig=dword(p)
      local nameRva=dword(p+12)
      local firstThunk=dword(p+16)
      if orig == 0 and nameRva == 0 and firstThunk == 0 then break end
      if nameRva==0 then error('Import without library name') end
      imports[#imports+1]=ascii(raw(nameRva),160)
    end
  end
  local version
  local resourceRva, resourceSize=dir(2)
  if resourceRva ~= 0 and resourceSize > 0 then
    local root=raw(resourceRva)
    local function dirEntries(rel)
      if rel < 0 or rel + 16 > resourceSize then return {} end
      local start=root+rel
      guard(start,16)
      local n=word(start+12)+word(start+14)
      if n > 5000 or rel + 16 + n*8 > resourceSize then return {} end
      local out={}
      for i=0,n-1 do
        local e=start+16+i*8
        out[#out+1]={id=dword(e),link=dword(e+4)}
      end
      return out
    end
    local function isDir(link) return link>=0x80000000 end
    local function lower(link) return link%0x80000000 end
    for _,typeEntry in ipairs(dirEntries(0)) do
      if typeEntry.id==16 and isDir(typeEntry.link) then
        for _,idEntry in ipairs(dirEntries(lower(typeEntry.link))) do
          if isDir(idEntry.link) then
            for _,langEntry in ipairs(dirEntries(lower(idEntry.link))) do
              if not isDir(langEntry.link) then
                local entry=root+langEntry.link
                guard(entry,16)
                local versionRva,versionSize=dword(entry),dword(entry+4)
                if versionSize>=52 and versionSize < 1024*1024 then
                  local vp=raw(versionRva)
                  guard(vp,versionSize)
                  local blob=data:sub(vp,vp+versionSize-1)
                  local signature=string.char(0xbd,0x04,0xef,0xfe)
                  local at=blob:find(signature,1,true)
                  if at and at+23<=#blob then
                    local p=vp+at-1
                    local fileMS,fileLS=dword(p+8),dword(p+12)
                    local prodMS,prodLS=dword(p+16),dword(p+20)
                    local function ver(ms,ls)
                      return string.format('%d.%d.%d.%d',math.floor(ms/65536),ms%65536,math.floor(ls/65536),ls%65536)
                    end
                    version={file=ver(fileMS,fileLS),product=ver(prodMS,prodLS),language=langEntry.id}
                  end
                end
                break
              end
            end
          end
          if version then break end
        end
      end
      if version then break end
    end
  end
  local certPos,certLen=dir(4) -- Security directory is FILE OFFSET (not RVA).
  local hasCertificate=certPos>0 and certLen>=8 and certPos+certLen<=length
  return {
    size=length,machine=machine,
    architecture=machine==0x14c and 'x86' or (machine==0x8664 and 'x64' or 'other'),
    kind=(magic==0x10b and 'PE32' or 'PE32+'),timestamp=timestamp,
    sectionCount=sectionCount,sections=sections,imports=imports,version=version,
    certificatePresent=hasCertificate,certificateBytes=hasCertificate and certLen or 0
  }
end

local function printReport(r)
  print('Lua-Flash PE inspection — static only')
  print('Format: '..r.kind..' | CPU: '..r.architecture..' | Size: '..r.size..' bytes')
  print('PE timestamp (UTC): '..os.date('!%Y-%m-%d %H:%M:%S',r.timestamp))
  if r.version then print('File version: '..r.version.file..' | Product: '..r.version.product)
  else print('File version: no valid VERSIONINFO found') end
  print('Embedded certificate: '..tostring(r.certificatePresent)..' ('..r.certificateBytes..' bytes; cryptographic validity NOT checked)')
  print('Sections:')
  for _,s in ipairs(r.sections) do
    print(string.format('  %-9s RVA=%08X Size=%d Offset=%d',s.name,s.rva,s.rawSize,s.fileOffset))
  end
  print('Import libraries: '..(#r.imports==0 and '(none)' or table.concat(r.imports,', ')))
end

local path = arg and arg[1]
if not path or path=='' then
  io.stderr:write('Usage: lua tools/inspect_pe.lua file.exe\n')
  os.exit(2)
end
local f,err=io.open(path,'rb')
if not f then io.stderr:write('Cannot open: '..tostring(err)..'\n');os.exit(2) end
local data=f:read('*a');f:close()
local ok,result=pcall(inspect,data)
if not ok then io.stderr:write('Inspection failed: '..tostring(result)..'\n');os.exit(1) end
printReport(result)
