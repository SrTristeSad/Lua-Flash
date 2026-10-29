-- Synchronized, bounded layer viewport shared by Studio sidebar and timeline.
-- View state never becomes part of the native LUAFLASH document format.
local M={}
M.rows=3

local function integer(n)
  return type(n)=="number" and n==math.floor(n) and n==n
end

function M.clamp(total,first)
  if not integer(total) or total<1 then return 1 end
  if not integer(first) then first=1 end
  return math.max(1,math.min(first,math.max(1,total-M.rows+1)))
end

function M.count(total,first)
  first=M.clamp(total,first)
  return math.min(M.rows,math.max(0,total-first+1))
end

function M.index(total,first,row)
  if not integer(row) or row<1 or row>M.rows then return nil end
  first=M.clamp(total,first)
  local n=first+row-1
  return n<=total and n or nil
end

function M.ensureVisible(total,first,selected)
  first=M.clamp(total,first)
  if not integer(selected) or selected<1 or selected>total then
    return first
  end
  if selected<first then first=selected end
  if selected>=first+M.rows then first=selected-M.rows+1 end
  return M.clamp(total,first)
end

function M.scroll(total,first,delta)
  if not integer(delta) then return M.clamp(total,first) end
  return M.clamp(total,M.clamp(total,first)+delta)
end

return M
