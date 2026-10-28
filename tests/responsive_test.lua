-- Player 0.23: UI scales into small windows and all pointer coordinates
-- map back to their stage positions with consistent letterboxing.
package.path="./player-lua/?.lua;./player-lua/?/init.lua;"..package.path
local R=require("src.responsive")
local large=R.layout(1440,900)
assert(large.w==1440 and large.h==900 and large.scale==1)
assert(large.x==0 and large.y==0 and not large.compact)
local normal=R.layout(1040,690)
assert(normal.w==1040 and normal.h==690 and normal.scale==1)
local sizes={
  {780,450},{600,380},{640,400},{900,600},{800,800},{1920,1080}
}
for _,size in ipairs(sizes) do
  local view=R.layout(size[1],size[2])
  assert(view.scale>0 and view.scale<=1)
  assert(view.x>=0 and view.y>=0 and
    view.x+view.w*view.scale<=size[1]+.0001 and
    view.y+view.h*view.scale<=size[2]+.0001)
  for _,xy in ipairs({{0,0},{34,25},{560,350},{1039,689}}) do
    if xy[1]<=view.w and xy[2]<=view.h then
      local x,y=R.screen(view,xy[1],xy[2])
      local lx,ly=R.logical(view,x,y)
      assert(math.abs(lx-xy[1])<.00001 and math.abs(ly-xy[2])<.00001)
    end
  end
end
local small=R.layout(640,400)
assert(small.compact and small.w==1040 and small.h==690)
assert(small.x>0 and small.y==0)
assert(not R.logical(small,small.x-1,10),
 "click in letterbox should not activate any buttons")
assert(not R.logical(small,small.x+small.w*small.scale+2,100))
assert(not R.logical(small,nil,1))
local sx,sy=R.screen(small,1040-240,42)
local x,y=R.logical(small,sx,sy)
assert(math.abs(x-800)<.001 and math.abs(y-42)<.001)
print("OK: Player 0.23 responsive 600x380 through full-HD with reversible pointers")
