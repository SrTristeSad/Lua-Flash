-- Player 0.24: predictable Tab navigation over the same visible UI controls.
-- All bounds use the Player's logical layout and match their mouse targets.
local F={}
local order={"package","game","demo","open","loop","prev","play","next","slow","speed","fast","smooth"}
function F.new()
  return setmetatable({index=nil}, {__index=F})
end
function F:clear() self.index=nil end
function F:next(backward)
  local d=backward and -1 or 1
  self.index=(((self.index or (backward and 1 or 0))-1+d)%#order)+1
  return order[self.index]
end
function F:selected()
  return self.index and order[self.index] or nil
end
function F:rect(w,h,top,stageHeight)
  if not self.index then return nil end
  local id=order[self.index]
  local topBoxes={
    package={w-575,24,83,36},game={w-486,24,83,36},
    demo={w-395,24,80,36},open={w-305,24,143,36},
    loop={w-153,24,132,36}
  }
  if topBoxes[id] then return topBoxes[id] end
  local barY=top+stageHeight+12+30
  local y=barY+23
  local bottom={
    prev={27,y,52,32},play={85,y,94,32},next={185,y,52,32},
    slow={250,y,34,32},speed={289,y,58,32},fast={353,y,34,32},
    smooth={w-155,y,135,32}
  }
  return bottom[id]
end
function F:count() return #order end
return F
