-- Lua-Flash 0.22: original 64px logo in pure Lua ImageData, for the window
-- and taskbar while running. Independent of the Studio and Adobe artwork.
local Icon={}
local function polygon(x,y,points)
  local inside=false
  local last=#points
  for i=1,#points,2 do
    local j=i+2
    if j>last then j=1 end
    local xi,yi=points[i],points[i+1]
    local xj,yj=points[j],points[j+1]
    if (yi>y)~=(yj>y) and x<(xj-xi)*(y-yi)/(yj-yi)+xi then
      inside=not inside
    end
  end
  return inside
end
function Icon.pixel(x,y,size)
  size=size or 64
  local xx=(x+.5)*64/size
  local yy=(y+.5)*64/size
  local dx=math.abs(xx-32)-27
  local dy=math.abs(yy-32)-27
  -- Rounded square with 10px corner radius, signed distance approximation.
  local dist=math.sqrt(math.max(dx+10,0)^2+math.max(dy+10,0)^2)+
    math.min(math.max(dx+10,dy+10),0)-10
  if dist>=.5 then return 0,0,0,0 end
  local alpha=math.max(0,math.min(1,.5-dist))
  local r,g,b=.064,.094,.18
  -- Cyan orbit/stroke, a distinctive tech accent.
  local ox=(xx-32)/23
  local oy=(yy-32)/23
  local ring=math.abs(ox*ox+oy*oy-1)<.135
  if ring and xx<47 then r,g,b=.10,.72,.95 end
  -- A bold forward-leaning lightning emblem, separate from the orbit.
  local bolt={
    36,9,20,34,30,34,25,55,
    47,28,36,28,43,9
  }
  if polygon(xx,yy,bolt) then
    r,g,b=.97,.88,.35
    if xx>35 then r,g,b=1,.72,.20 end
  end
  return r,g,b,alpha
end
function Icon.create(newImageData,size)
  size=size or 64
  local image=newImageData(size,size)
  for y=0,size-1 do
    for x=0,size-1 do
      image:setPixel(x,y,Icon.pixel(x,y,size))
    end
  end
  return image
end
return Icon
