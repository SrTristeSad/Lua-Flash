-- Lua-Flash Player 0.1: runtime independente do Studio; formato proprio .lflash.
local Model = require("src.model")
local Runtime = require("src.runtime")
local Demo = require("src.demo")
local doc = Demo.create()
local runner = Runtime.new(doc)
runner.playing = true
local source = "Demonstracao interna"
local notification = "Solte um projeto .lflash nesta janela para reproduzir."
local loop = true
local fonts = {}
local palette = {
  bg = {.075,.085,.11}, bar={.11,.13,.17}, panel={.13,.15,.19},
  text={.90,.94,1}, muted={.64,.69,.76}, blue={.24,.67,.98},
  highlight={.19,.35,.51}, line={.23,.28,.35}
}

local function size()
  local w,h=love.graphics.getDimensions()
  local top=90
  local bottom=130
  return w,h,top,math.max(80,h-top-bottom)
end

local function inside(x,y,bx,by,bw,bh)
  return x>=bx and x<=bx+bw and y>=by and y<=by+bh
end

local function label(t,x,y,col,font)
  local lg=love.graphics
  lg.setColor(col or palette.text)
  if font then lg.setFont(font) end
  lg.print(t,x,y)
  if font then lg.setFont(fonts.regular) end
end

local function button(title,x,y,width,highlighted)
  local lg=love.graphics
  lg.setColor(highlighted and palette.highlight or palette.panel)
  lg.rectangle("fill",x,y,width,35,6,6)
  lg.setColor(palette.line)
  lg.rectangle("line",x+.5,y+.5,width-1,34,6,6)
  label(title,x+12,y+9)
end

local function openData(text, name)
  local result, err=Model.decode(text)
  if not result then
    notification="Arquivo recusado: "..tostring(err)
    return false
  end
  doc=result
  runner=Runtime.new(doc)
  runner:seek(1)
  runner.playing=true
  source=name or "Projeto carregado"
  notification="Projeto carregado com sucesso. Espaco pausa ou reproduz."
  return true
end

local function savedProject()
  local bytes,err=love.filesystem.read("projeto.lflash")
  if not bytes then
    notification="Nenhum projeto salvo. Salve no Studio ou arraste um arquivo .lflash."
    return
  end
  openData(bytes,"projeto.lflash (Studio)")
end

local function resetDemo()
  doc=Demo.create()
  runner=Runtime.new(doc)
  runner.playing=true
  source="Demonstracao interna"
  notification="Animacao de exemplo carregada."
end

local function previous()
  runner.playing=false
  runner:seek(runner.frame-1)
end

local function nextFrame()
  runner.playing=false
  runner:seek(runner.frame+1)
end

local function clickScrub(mx)
  local w=love.graphics.getWidth()
  local left,right=32,w-32
  local n=1+math.floor(math.max(0,math.min(1,(mx-left)/(right-left)))*(doc.totalFrames-1)+.5)
  runner:seek(n)
end

function love.load()
  love.window.setTitle("Lua-Flash Player 0.1")
  love.window.setMode(1040,690,{resizable=true,minwidth=660,minheight=420})
  fonts.regular=love.graphics.newFont(13)
  fonts.heading=love.graphics.newFont(22)
  fonts.small=love.graphics.newFont(12)
  love.graphics.setFont(fonts.regular)
  love.graphics.setDefaultFilter("linear","linear")
end

function love.update(dt)
  local previousFrame=runner.frame
  runner:update(dt)
  if runner.playing and not loop and runner.frame<previousFrame then
    runner:seek(doc.totalFrames)
    runner.playing=false
    notification="Reproducao concluida."
  end
end

function love.draw()
  local lg=love.graphics
  local w,h,top,stageHeight=size()
  lg.clear(palette.bg)
  lg.setColor(palette.bar)
  lg.rectangle("fill",0,0,w,top)
  label("LUA-FLASH",20,17,palette.blue,fonts.heading)
  label("PLAYER 0.1  |  Formato proprio .lflash",21,51,palette.muted,fonts.small)

  button("DEMO",w-395,25,80,false)
  button("PROJETO SALVO",w-305,25,143,false)
  button(loop and "LOOP: ON" or "LOOP: OFF",w-153,25,132,loop)

  Runtime.draw(doc,runner.frame,18,top+10,w-36,stageHeight-15)
  lg.setColor(palette.bar)
  lg.rectangle("fill",0,top+stageHeight,w,h-top-stageHeight)

  local y=top+stageHeight+17
  label(source,24,y,palette.text)
  label(string.format("Quadro %d / %d  |  %g FPS  |  %dx%d",runner.frame,doc.totalFrames,doc.fps,doc.width,doc.height),
    w-295,y,palette.muted,fonts.small)

  local sy=y+35
  lg.setColor(palette.line)
  lg.rectangle("fill",32,sy,w-64,8,4,4)
  lg.setColor(palette.blue)
  local completed=(runner.frame-1)/math.max(1,doc.totalFrames-1)
  lg.rectangle("fill",32,sy,math.max(2,(w-64)*completed),8,4,4)
  lg.circle("fill",32+(w-64)*completed,sy+4,8)

  local controls=sy+23
  label("ESPACO  "..(runner.playing and "Pausar" or "Reproduzir").."    |    SETAS  Passar quadros    |    HOME  Reiniciar",32,controls,palette.text,fonts.small)
  label("ARRASTE .LFLASH  Abrir projeto    |    F11  Tela cheia",32,controls+19,palette.muted,fonts.small)

  lg.setColor(palette.bar)
  lg.rectangle("fill",0,h-26,w,26)
  label(notification,14,h-22,palette.muted,fonts.small)
end

function love.mousepressed(x,y,key)
  if key~=1 then return end
  local w,h,top,stageHeight=size()
  if inside(x,y,w-395,25,80,35) then resetDemo()
  elseif inside(x,y,w-305,25,143,35) then savedProject()
  elseif inside(x,y,w-153,25,132,35) then loop=not loop
  elseif inside(x,y,24,top+stageHeight+41,w-48,25) then clickScrub(x) end
end

function love.keypressed(key)
  if key=="space" then runner.playing=not runner.playing
  elseif key=="left" then previous()
  elseif key=="right" then nextFrame()
  elseif key=="home" then runner:seek(1)
  elseif key=="end" then runner:seek(doc.totalFrames)
  elseif key=="f11" then love.window.setFullscreen(not love.window.getFullscreen())
  elseif key=="escape" then
    if love.window.getFullscreen() then love.window.setFullscreen(false) else love.event.quit() end
  elseif key=="o" then savedProject()
  elseif key=="d" then resetDemo()
  elseif key=="l" then loop=not loop
  elseif key=="s" and love.keyboard.isDown("lctrl","rctrl") then
    local ok,err=love.filesystem.write("player_demo.lflash",Model.encode(doc))
    notification=ok and ("Arquivo salvo: "..love.filesystem.getSaveDirectory().."/player_demo.lflash")
      or ("Falha ao salvar: "..tostring(err))
  end
end

function love.filedropped(file)
  local filename=file:getFilename() or ""
  if not filename:lower():match("%.lflash$") then
    notification="Formato nao aceito. Arraste um arquivo .lflash."
    return
  end
  local ok,err=file:open("r")
  if not ok then notification="Falha ao abrir arquivo: "..tostring(err);return end
  local bytes=file:read(25*1024*1024+1)
  file:close()
  if not bytes then notification="Falha ao ler projeto.";return end
  openData(bytes,filename:match("[^/\\]+$") or filename)
end
