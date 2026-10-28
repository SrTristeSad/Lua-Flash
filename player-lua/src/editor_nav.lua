-- Player 0.25: keyboard focus for every visible keyframe editor control.
-- Rectangles mirror drawCurveEditor/editorClick exactly.
local E={}
E.__index=E
local ids={
 "track_prev","track_next","key1","key2","key3","key4",
 "insert","delete","frame_prev","frame_next",
 "x_prev","x_next","y_prev","y_next",
 "angle_prev","angle_next","scale_x_prev","scale_x_next",
 "scale_y_prev","scale_y_next","undo","curve","save"
}
local areas={
 track_prev={12,36,35,30},track_next={"right",36,35,30},
 key1={8,99, "inner",25},key2={8,125,"inner",25},
 key3={8,151,"inner",25},key4={8,177,"inner",25},
 insert={12,239,80,28},delete={102,239,80,28},
 frame_prev={192,239,43,28},frame_next={244,239,43,28},
 x_prev={12,272,59,28},x_next={81,272,59,28},
 y_prev={150,272,59,28},y_next={219,272,68,28},
 angle_prev={12,305,59,27},angle_next={81,305,59,27},
 scale_x_prev={150,305,64,27},scale_x_next={224,305,64,27},
 scale_y_prev={12,337,62,27},scale_y_next={84,337,62,27},
 undo={156,337,132,27},curve={12,"bottom",170,29},
 save={"save","bottom",93,29},
}
function E.new()
 return setmetatable({id=nil},E)
end
function E:clear() self.id=nil end
function E:selected() return self.id end
function E:items(keyCount)
 local result={}
 local rows=math.min(4,math.max(0,keyCount or 0))
 for _,id in ipairs(ids) do
   local row=tonumber(id:match("^key(%d)$"))
   if not row or row<=rows then result[#result+1]=id end
 end
 return result
end
function E:next(reverse,keyCount)
 local items=self:items(keyCount)
 if #items==0 then self.id=nil;return nil end
 local index
 for i,id in ipairs(items) do if id==self.id then index=i;break end end
 if not index and self.id and self.id:match("^key%d$") then
   -- An undo/delete can hide the currently focused row. Resume at the
   -- nearest visible action, instead of silently losing navigation.
   for i,id in ipairs(items) do
     if id=="insert" then index=reverse and i or i-1;break end
   end
 end
 if not index then index=reverse and 1 or 0 end
 index=((index-1+(reverse and -1 or 1))%#items)+1
 self.id=items[index]
 return self.id
end
function E:rect(x,y,w,h,keyCount)
 local id=self.id
 if not id then return nil end
 local found=false
 for _,v in ipairs(self:items(keyCount)) do
   if v==id then found=true;break end
 end
 if not found then return nil end
 local rect=areas[id]
 local rx=rect[1]
 if rx=="right" then rx=w-47
 elseif rx=="save" then rx=w-105 end
 local ry=rect[2]=="bottom" and h-39 or rect[2]
 local rw=rect[3]=="inner" and w-16 or rect[3]
 return x+rx,y+ry,rw,rect[4]
end
return E
