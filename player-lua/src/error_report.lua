-- Lua-Flash Player 0.18: bounded, best-effort error reporting.
-- File errors never throw back into the game loop. No remote telemetry.
local E={}
E.__index=E
local MAX_LOG=32768
local MAX_MESSAGE=1100
local function clean(value)
  local s=tostring(value or "unknown error")
  s=s:gsub("[%z\1-\8\11\12\14-\31]","?")
  return #s>MAX_MESSAGE and s:sub(1,MAX_MESSAGE).."... [truncated]" or s
end
function E.new(filesystem)
  return setmetatable({fs=filesystem,last=nil,count=0,
    filename="player-errors.log"},E)
end
function E:record(where,reason)
  local message=clean(where)..": "..clean(reason)
  self.count=self.count+1
  -- Errors recurring every frame may be displayed again but should not
  -- continuously rewrite files (or fill the user's disk).
  if self.last==message then return message end
  self.last=message
  local stamp=os.date("!%Y-%m-%dT%H:%M:%SZ")
  local entry=stamp.." | "..message.."\n"
  if self.fs and self.fs.write then
    pcall(function()
      local old=self.fs.read and self.fs.read(self.filename) or ""
      if type(old)~="string" then old="" end
      if #entry>MAX_LOG then entry=entry:sub(-MAX_LOG) end
      local limit=MAX_LOG-#entry
      if #old>limit then old=old:sub(-limit) end
      self.fs.write(self.filename,old..entry)
    end)
  end
  return message
end
function E:protect(where,fn,...)
  local args={...}
  local unpackArgs=table.unpack or unpack
  local ok,result= xpcall(function()
    return fn(unpackArgs(args,1,#args))
  end,function(reason)
    return debug and debug.traceback and debug.traceback(clean(reason),2)
      or clean(reason)
  end)
  if not ok then
    self:record(where,result)
    return false,result
  end
  return true,result
end
return E
