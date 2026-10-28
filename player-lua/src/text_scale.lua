-- Lua-Flash Player 0.26: bounded font-size preferences and usable text widths.
-- Font settings are data only; input files are never evaluated as Lua.
local T={}
local levels={"normal","large","extra"}
local sizes={
 normal={regular=13,small=12,heading=22},
 large={regular=15,small=14,heading=25},
 extra={regular=17,small=16,heading=28}
}
local path="player-font-size.txt"
function T.levels() return levels end
function T.valid(level) return sizes[level]~=nil end
function T.sizes(level) return sizes[level] or sizes.normal end
function T.step(current,direction)
  local i=1
  for j,name in ipairs(levels) do if name==current then i=j;break end end
  i=math.min(#levels,math.max(1,i+(direction or 0)))
  return levels[i]
end
function T.load(fs)
  if not fs or type(fs.read)~="function" then return "normal" end
  local ok,data=pcall(fs.read,path)
  if not ok or type(data)~="string" or #data>32 then return "normal" end
  local value=data:match("^font=([a-z]+)\n$")
  return T.valid(value) and value or "normal"
end
function T.save(fs,level)
  if not T.valid(level) or not fs or type(fs.write)~="function" then return false end
  local ok,result=pcall(fs.write,path,"font="..level.."\n")
  return ok and not not result
end
-- Ratio to fit a label within a button without expanding its hitbox or
-- spilling onto another control. minRatio prevents unusably thin glyphs.
function T.fitRatio(measuredWidth,limit)
  if type(measuredWidth)~="number" or type(limit)~="number" or
     measuredWidth<=0 or limit<=0 then return 1 end
  return math.min(1,limit/measuredWidth)
end
function T.fitted(text,font,maxWidth)
  if not font or type(font.getWidth)~="function" or
      not maxWidth or maxWidth<=0 then return tostring(text),1 end
  local value=tostring(text)
  local ratio=T.fitRatio(font:getWidth(value),maxWidth)
  if ratio>=.70 then return value,ratio end
  -- Respect legibility rather than squeezing text indefinitely. Use UTF-8
  -- safe prefix truncation and a single ellipsis. Fonts cache all glyphs.
  local chars={}
  for utf8char in value:gmatch("[%z\1-\127\194-\244][\128-\191]*") do
    chars[#chars+1]=utf8char
  end
  local ellipsis="..."
  local lo,hi=0,#chars
  while lo<hi do
    local mid=math.floor((lo+hi+1)/2)
    local candidate=table.concat(chars,"",1,mid)..ellipsis
    if font:getWidth(candidate)<=maxWidth then lo=mid
    else hi=mid-1 end
  end
  return table.concat(chars,"",1,lo)..ellipsis,1
end
return T
