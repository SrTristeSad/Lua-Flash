-- Lua-Flash Player 0.2. Independent runtime for native .lflash animations.
-- Does not execute SWF, ActionScript or embedded project code.
local Model=require("src.model")
local Runtime=require("src.runtime")
local Demo=require("src.demo")
local Transport=require("src.transport")
local Interpolation=require("src.interpolation")

local document=Demo.create()
local transport=Transport.new(document)
transport.playing=true
local sampler=Interpolation.new(document)
local smooth=true -- demo uses keyframed animation; imported projects start in exact mode.
local source="Demonstracao interna"
local notice="Solte um projeto .lflash na janela ou use o exemplo incluido."
local fonts={}
local C={
  bg={.075,.085,.11},top={.11,.13,.17},panel={.14,.16,.20},
  text={.90,.94,1},muted={.62,.69,.77},accent={.25,.70,.99},
  highlight={.19,.36,.52},line={.23,.28,.35},green={.35,.86,.65}
}
local MAX_FILE=25*1024*1024

local function metrics()
  local w,h=love.graphics.getDimensions()
  local top,bottom=90,151
  return w,h,top,math.max(80,h-top-bottom)
end

local function inside(x,y,bx,by,bw,bh)
  return x>=bx and x<=bx+bw and y>=by and y<=by+bh
end

local function label(s,x,y,color,font)
  local lg=love.graphics
  lg.setColor(color or C.text)
  if font then lg.setFont(font) end
  lg.print(tostring(s),x,y)
  if font then lg.setFont(fonts.regular) end
end

local function button(s,x,y,w,h,active)
  local lg=love.graphics
  lg.setColor(active and C.highlight or C.panel)
  lg.rectangle("fill",x,y,w,h,5,5)
  lg.setColor(C.line)
  lg.rectangle("line",x+.5,y+.5,w-1,h-1,5,5)
  label(s,x+10,y+math.floor((h-14)/2))
end

local function install(doc,name,isDemo)
  document=doc
  transport=Transport.new(document)
  transport.playing=true
  sampler=Interpolation.new(document)
  source=name or "Projeto Lua-Flash"
  smooth=isDemo == true
  notice=isDemo and "Animacao de demonstracao carregada." or
    "Projeto aberto. Aperte I para ativar ou desativar interpolacao visual."
end

local function openBytes(content,name)
  if type(content)~="string" or #content>MAX_FILE then
    notice="Arquivo rejeitado: tamanho invalido (maximo 25 MB)."
    return false
  end
  local ok,doc,err=pcall(Model.decode,content)
  if not ok or not doc then
    notice="Nao foi possivel abrir o projeto: "..tostring(ok and err or doc)
    return false
  end
  install(doc,name,false)
  return true
end

local function openSaved()
  local bytes,err=love.filesystem.read("projeto.lflash")
  if not bytes then
    notice="Nenhum projeto salvo nesta instalacao: "..tostring(err)
    return
  end
  openBytes(bytes,"projeto.lflash (Studio)")
end

local function saveCopy()
  local content=Model.encode(document)
  local ok,err=love.filesystem.write("player_demo.lflash",content)
  notice=ok and ("Copia salva: "..love.filesystem.getSaveDirectory().."/player_demo.lflash")
    or ("Erro ao salvar: "..tostring(err))
end

local function seekFromX(x,w)
  transport:seekProgress((x-32)/(w-64))
end

local function toggleSmooth()
  smooth=not smooth
  notice=smooth and "Interpolacao visual ativada (nao altera seu arquivo)." or
    "Interpolacao visual desativada: quadros exatos do projeto."
end

function love.load()
  love.window.setTitle("Lua-Flash Player 0.2")
  love.window.setMode(1040,690,{resizable=true,minwidth=780,minheight=450})
  love.graphics.setDefaultFilter("linear","linear")
  fonts.regular=love.graphics.newFont(13)
  fonts.heading=love.graphics.newFont(22)
  fonts.small=love.graphics.newFont(12)
  love.graphics.setFont(fonts.regular)
end

function love.update(dt)
  transport:update(dt)
end

local function renderScene(x,y,w,h)
  if smooth then
    sampler:draw(transport.position,x,y,w,h)
  else
    Runtime.draw(document,transport:frame(),x,y,w,h)
  end
end

function love.draw()
  local lg=love.graphics
  local w,h,top,stageHeight=metrics()
  lg.clear(C.bg)
  lg.setColor(C.top)
  lg.rectangle("fill",0,0,w,top)
  label("LUA-FLASH",20,13,C.accent,fonts.heading)
  label("PLAYER 0.2  |  Arquivos nativos .lflash",21,50,C.muted,fonts.small)

  button("DEMO",w-395,24,80,36,false)
  button("PROJETO SALVO",w-305,24,143,36,false)
  button(transport.loop and "LOOP: ON" or "LOOP: OFF",w-153,24,132,36,transport.loop)
  renderScene(18,top+10,w-36,stageHeight-15)

  lg.setColor(C.top)
  lg.rectangle("fill",0,top+stageHeight,w,h-top-stageHeight)
  local topPanel=top+stageHeight+12
  label(source,25,topPanel,C.text)
  label(string.format("Quadro %d/%d  |  %g FPS",transport:frame(),document.totalFrames,document.fps),
    w-260,topPanel,C.muted,fonts.small)

  local barY=topPanel+30
  lg.setColor(C.line)
  lg.rectangle("fill",32,barY,w-64,7,4,4)
  local progress=math.max(0,math.min(1,transport:progress()))
  lg.setColor(C.accent)
  lg.rectangle("fill",32,barY,math.max(1,(w-64)*progress),7,4,4)
  lg.circle("fill",32+(w-64)*progress,barY+3.5,7)

  local ctrlY=barY+23
  button("<<",27,ctrlY,52,32,false)
  button(transport.playing and "PAUSAR" or "PLAY",85,ctrlY,94,32,transport.playing)
  button(">>",185,ctrlY,52,32,false)
  button("-",250,ctrlY,34,32,false)
  button(string.format("%gx",transport.speed),289,ctrlY,58,32,false)
  button("+",353,ctrlY,34,32,false)
  button(smooth and "SUAVE: ON" or "SUAVE: OFF",w-155,ctrlY,135,32,smooth)
  label("Espaco: play  |  Setas: quadro  |  I: interpolacao  |  F11: tela cheia",27,ctrlY+40,C.muted,fonts.small)

  lg.setColor(C.top)
  lg.rectangle("fill",0,h-26,w,26)
  label(notice,13,h-22,C.muted,fonts.small)
end

function love.mousepressed(x,y,key)
  if key~=1 then return end
  local w,h,top,stageHeight=metrics()
  if inside(x,y,w-395,24,80,36) then
    install(Demo.create(),"Demonstracao interna",true)
  elseif inside(x,y,w-305,24,143,36) then openSaved()
  elseif inside(x,y,w-153,24,132,36) then transport.loop=not transport.loop
  end
  local topPanel=top+stageHeight+12
  local barY=topPanel+30
  local ctrlY=barY+23
  if inside(x,y,28,barY-8,w-56,22) then seekFromX(x,w)
  elseif inside(x,y,27,ctrlY,52,32) then transport:step(-1)
  elseif inside(x,y,85,ctrlY,94,32) then transport:toggle()
  elseif inside(x,y,185,ctrlY,52,32) then transport:step(1)
  elseif inside(x,y,250,ctrlY,34,32) then transport:cycleSpeed(-1)
  elseif inside(x,y,353,ctrlY,34,32) then transport:cycleSpeed(1)
  elseif inside(x,y,w-155,ctrlY,135,32) then toggleSmooth() end
end

function love.keypressed(key)
  local ctrl=love.keyboard.isDown("lctrl","rctrl")
  if ctrl and key=="s" then saveCopy();return end
  if key=="space" then transport:toggle()
  elseif key=="left" then transport:step(-1)
  elseif key=="right" then transport:step(1)
  elseif key=="home" then transport.playing=false;transport:seek(1)
  elseif key=="end" then transport.playing=false;transport:seek(document.totalFrames)
  elseif key=="f11" then love.window.setFullscreen(not love.window.getFullscreen())
  elseif key=="escape" then
    if love.window.getFullscreen() then love.window.setFullscreen(false) else love.event.quit() end
  elseif key=="d" then install(Demo.create(),"Demonstracao interna",true)
  elseif key=="o" then openSaved()
  elseif key=="l" then transport.loop=not transport.loop
  elseif key=="i" then toggleSmooth()
  elseif key=="-" or key=="kp-" then transport:cycleSpeed(-1)
  elseif key=="=" or key=="kp+" then transport:cycleSpeed(1) end
end

function love.wheelmoved(_,dy)
  if dy~=0 then transport:step(dy>0 and 1 or -1) end
end

function love.filedropped(file)
  local filename=file:getFilename() or ""
  if not filename:lower():match("%.lflash$") then
    notice="Arquivo nao suportado: use projetos do Lua-Flash (.lflash)."
    return
  end
  local ok,err=file:open("r")
  if not ok then notice="Nao foi possivel abrir: "..tostring(err);return end
  local bytes=file:read(MAX_FILE+1)
  file:close()
  if not bytes then notice="Erro ao ler arquivo.";return end
  openBytes(bytes,filename:match("[^/\\]+$") or filename)
end
