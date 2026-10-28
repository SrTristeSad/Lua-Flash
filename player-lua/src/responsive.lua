-- Player 0.23: logical viewport to keep controls accessible on small windows.
-- Graphics dimensions and pointer events remain in LÖVE's logical pixel units.
local R={}
local BASE_W,BASE_H=1040,690
function R.layout(w,h)
  assert(type(w)=="number" and type(h)=="number" and w>0 and h>0)
  local scale=math.min(1,w/BASE_W,h/BASE_H)
  local virtualW=scale<1 and BASE_W or w
  local virtualH=scale<1 and BASE_H or h
  local offsetX=(w-virtualW*scale)/2
  local offsetY=(h-virtualH*scale)/2
  return {
    scale=scale,x=offsetX,y=offsetY,w=virtualW,h=virtualH,
    screenW=w,screenH=h,compact=scale<1
  }
end
function R.logical(layout,x,y)
  if type(x)~="number" or type(y)~="number" then return nil end
  local lx=(x-layout.x)/layout.scale
  local ly=(y-layout.y)/layout.scale
  if lx<0 or ly<0 or lx>layout.w or ly>layout.h then return nil end
  return lx,ly
end
function R.screen(layout,x,y)
  return layout.x+x*layout.scale,layout.y+y*layout.scale
end
return R
