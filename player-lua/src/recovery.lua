-- Lua-Flash Player 0.17: project-scoped, rotating, checksummed recovery.
-- Independent of UI and LÖVE globals; requires filesystem and package codec.
-- Two slots: a partial write to one slot cannot overwrite the other slot.
local R={}
R.__index=R
local MAX_BYTES=25*1024*1024
local MOD=4294967296
local function digest(data)
  local a,b=2166136261,123456789
  for i=1,#data do
    local byte=data:byte(i)
    a=(a*131+byte)%MOD
    b=(b*137+byte)%MOD
  end
  return string.format("%08x%08x",a,b)
end
function R.identity(name,sourceBytes)
  assert(type(name)=="string" and type(sourceBytes)=="string",
    "recovery identity requires source name and original bytes")
  return digest(name.."\0"..sourceBytes)
end
function R.new(filesystem,codec,key)
  assert(type(filesystem)=="table" and type(codec)=="table" and
    type(key)=="string" and key:match("^[0-9a-f]+$") and #key==16)
  return setmetatable({fs=filesystem,codec=codec,key=key},R)
end
local function filename(self,slot)
  return "recovery/"..self.key.."-"..slot..".rec"
end
local function encodeEnvelope(key,sequence,bytes)
  return table.concat({
    "LUAFRECOVERY 1\n","PROJECT\t",key,"\n",
    "SEQ\t",sequence,"\n","LENGTH\t",#bytes,"\n",
    "CHECKSUM\t",digest(bytes),"\n\n",bytes})
end
local function parseEnvelope(self,raw)
  if type(raw)~="string" or #raw>MAX_BYTES+256 then
    return nil,"recovery file exceeds size limit"
  end
  local from,to,id,sequence,length,sum=raw:find(
    "^LUAFRECOVERY 1\nPROJECT\t([0-9a-f]+)\nSEQ\t(%d+)\nLENGTH\t(%d+)\nCHECKSUM\t([0-9a-f]+)\n\n")
  local seq,n=tonumber(sequence),tonumber(length)
  if not from or not to or id~=self.key or
    not seq or seq<1 or seq>1000000000 or seq%1~=0 or
    not n or n<40 or n>MAX_BYTES or n%1~=0 or
    #raw-to~=n then return nil,"invalid recovery envelope" end
  local bytes=raw:sub(to+1)
  if digest(bytes)~=sum then return nil,"recovery checksum mismatch" end
  local ok,game,err=pcall(self.codec.decode,bytes)
  if not ok or not game then
    return nil,"recovery game invalid: "..tostring(ok and err or game)
  end
  return {bytes=bytes,game=game,sequence=seq}
end
function R:readSlot(slot)
  local bytes=self.fs.read(filename(self,slot))
  if not bytes then return nil,"no recovery slot" end
  return parseEnvelope(self,bytes)
end
function R:read()
  local a=self:readSlot("a")
  local b=self:readSlot("b")
  if a and (not b or a.sequence>=b.sequence) then return a end
  if b then return b end
  return nil,"no valid recovery for this project"
end
function R:save(game)
  local ok,bytes,err=pcall(self.codec.encode,game)
  if not ok or not bytes or #bytes>MAX_BYTES then
    return nil,"cannot encode recovery: "..tostring(ok and err or bytes)
  end
  local recent=self:read()
  local seq=recent and recent.sequence+1 or 1
  local slot
  if recent then
    local a=self:readSlot("a")
    slot=a and a.sequence==recent.sequence and "b" or "a"
  else
    slot="a"
  end
  if not self.fs.createDirectory("recovery") then
    return nil,"cannot create recovery directory"
  end
  local path=filename(self,slot)
  local contents=encodeEnvelope(self.key,seq,bytes)
  local written,reason=self.fs.write(path,contents)
  if not written then return nil,"recovery write failed: "..tostring(reason) end
  local validated,problem=self:readSlot(slot)
  if not validated or validated.sequence~=seq or validated.bytes~=bytes then
    return nil,"recovery verification failed: "..tostring(problem)
  end
  return validated,path
end
function R:clear()
  local a=self.fs.remove(filename(self,"a"))
  local b=self.fs.remove(filename(self,"b"))
  -- Missing slots are a normal condition, so clear is best-effort.
  return a or b
end
return R
