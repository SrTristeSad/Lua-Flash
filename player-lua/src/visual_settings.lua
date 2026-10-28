-- Player 0.25: high-contrast theme, written as plain data (never loadstring).
local V={}
V.normal={
  bg={.075,.085,.11},top={.11,.13,.17},panel={.14,.16,.20},
  text={.90,.94,1},muted={.62,.69,.77},accent={.25,.70,.99},
  highlight={.19,.36,.52},line={.23,.28,.35},green={.35,.86,.65},
  focus={.98,.85,.32},stageOutline={.25,.70,.99}
}
V.high={
  bg={0,0,0},top={.04,.04,.04},panel={.10,.10,.10},
  text={1,1,1},muted={.92,.92,.92},accent={1,.88,.05},
  highlight={.23,.23,.23},line={1,1,1},green={.60,1,.57},
  focus={1,.40,1},stageOutline={1,.88,.05}
}
local path="player-settings.txt"
function V.palette(high)
 return high and V.high or V.normal
end
function V.load(fs)
 if not fs or type(fs.read)~="function" then return false end
 local ok,value=pcall(fs.read,path)
 return ok and value=="contrast=high\n" or false
end
function V.save(fs,high)
 if not fs or type(fs.write)~="function" then return false end
 local ok,wrote=pcall(fs.write,path,high and "contrast=high\n" or "contrast=normal\n")
 return ok and not not wrote
end
return V
