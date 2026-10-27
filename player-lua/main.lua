-- Lua-Flash Player 0.11. Independent runtime for native .lflash animations.
-- Does not execute SWF, ActionScript or embedded project code.
local Model=require("src.model")
local Runtime=require("src.runtime")
local Demo=require("src.demo")
local Transport=require("src.transport")
local Interpolation=require("src.interpolation")
local Input=require("src.input")
local TargetGame=require("src.target_game")
local GamePackage=require("src.package_v6")
local MediaRuntime=require("src.media_runtime")
local Session=require("src.session")
local GameExample=require("src.game_example_v6")

local document=Demo.create()
local transport=Transport.new(document)
transport.playing=true
local sampler=Interpolation.new(document)
local smooth=true -- demo uses keyframed animation; imported projects start in exact mode.
local source="Demonstracao interna"
local notice="Solte um projeto .lflash na janela ou use o exemplo incluido."
local fonts={}
local input=Input.new()
local game=nil
local session=nil
local packageDefinition=nil
local media=nil
local C={
  bg={.075,.085,.11},top={.11,.13,.17},panel={.14,.16,.20},
  text={.90,.94,1},muted={.62,.69,.77},accent={.25,.70,.99},
  highlight={.19,.36,.52},line={.23,.28,.35},green={.35,.86,.65}
}
local MAX_FILE=25*1024*1024
-- CI-only graphical smoke mode; runs regular LÖVE graphics before exiting.
local ciSmoke=(os.getenv("LUA_FLASH_SMOKE")=="1")
local drawnFrames=0

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
  if media then media:release() end
  media=nil
  document=doc
  transport=Transport.new(document)
  transport.playing=true
  sampler=Interpolation.new(document)
  input:reset()
  game=nil
  session=nil
  packageDefinition=nil
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

-- A .lfgame contains a validated native scene and data-only interaction rules.
local function openGameBytes(content,name)
  if type(content)~="string" or #content>MAX_FILE then
    notice="Jogo recusado: pacote maior que 25 MB."
    return false
  end
  local ok,definition,err=pcall(GamePackage.decode,content)
  if not ok or not definition then
    notice="Jogo recusado: "..tostring(ok and err or definition)
    return false
  end
  local prepared=nil
  if definition.version>=4 then
    local ready,result=pcall(MediaRuntime.new,definition)
    if not ready then
      notice="Falha ao decodificar PNG/WAV: "..tostring(result)
      return false
    end
    prepared=result
  end
  install(definition.document,name or definition.title,false)
  packageDefinition=definition
  session=Session.new(definition,transport)
  media=prepared
  smooth=definition.smooth
  notice="Jogo "..definition.title.." iniciado. Sem execucao de scripts externos."
  return true
end

local function openGameExample()
  openGameBytes(GameExample.bytes(),"Exemplo externo .lfgame")
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
  local content,name
  if packageDefinition then
    content=assert(GamePackage.encode(packageDefinition))
    name="player_game.lfgame"
  else
    content=Model.encode(document)
    name="player_demo.lflash"
  end
  local ok,err=love.filesystem.write(name,content)
  notice=ok and ("Copia salva: "..love.filesystem.getSaveDirectory().."/"..name)
    or ("Erro ao salvar: "..tostring(err))
end

local function seekFromX(x,w)
  transport:seekProgress((x-32)/(w-64))
end

local function startGame()
  install(Demo.create(),"Acerte a bola - minijogo do Player",true)
  game=TargetGame.new()
  transport.loop=true
  notice="Minijogo: clique ou toque na bola; WASD move mira e ENTER dispara."
end

local function sceneViewport()
  local w,h,top,stageHeight=metrics()
  return {x=18,y=top+10,w=w-36,h=stageHeight-15}
end

local function currentHit(x,y)
  return Input.hitTest(document,transport.position,x,y,smooth and sampler or nil)
end

local function onEvent(event)
  if event.clicked then
    if session then
      event.frame=transport.position
      local consumed=session:dispatch(event)
      if media then
        media:trigger(event,session)
        if session.won then media:trigger({type="win"},session) end
      end
      if consumed then notice=session.lastAction
      else notice="Sem acao configurada neste objeto." end
      return
    end
    if game then
      local success=game:attempt(event.hit)
      notice=game.active and (success and "Acertou! +"..game.score.." pontos." or "Errou! Continue tentando.")
        or "Tempo esgotado. Clique JOGAR para reiniciar."
    elseif event.hit then
      notice=string.format("Objeto selecionado: camada %d, forma %d (%s).",
        event.hit.layer,event.hit.shape,event.hit.kind)
    else
      notice="Clique realizado sobre o palco."
    end
  end
end

local function toggleSmooth()
  smooth=not smooth
  notice=smooth and "Interpolacao visual ativada (nao altera seu arquivo)." or
    "Interpolacao visual desativada: quadros exatos do projeto."
end

function love.load()
  love.window.setTitle("Lua-Flash Player 0.11")
  love.window.setMode(1040,690,{resizable=true,minwidth=780,minheight=450})
  love.graphics.setDefaultFilter("linear","linear")
  fonts.regular=love.graphics.newFont(13)
  fonts.heading=love.graphics.newFont(22)
  fonts.small=love.graphics.newFont(12)
  love.graphics.setFont(fonts.regular)
  if os.getenv("LUA_FLASH_SMOKE_MEDIA")=="1" then
    openGameExample()
    if not media then error("media demo failed to load") end
    local first=media:maskFor("estrela")
    local second=media:maskFor("estrela_alt")
    assert(first and second and first.w==16 and second.h==16,
      "LÖVE PNG alpha decoding failed")
  end
end

function love.update(dt)
  if ciSmoke and drawnFrames>=5 then love.event.quit();return end
  local before,playing=transport.position,transport.playing
  transport:update(dt)
  local wrapped=playing and transport.loop and transport.position<before
  if media then media:timelineAdvance(before,transport.position,playing) end
  if game then
    game:update(dt,transport.playing)
    if not game.active then transport.playing=false end
  end
  if session then
    session:update(dt)
    if session:checkCollisions(smooth and sampler or nil,media,
      playing and before or nil,wrapped) then
      notice=session.lastAction
      if media and session.lastCollision then
        media:trigger({type="collision",
          a=session.lastCollision.a,b=session.lastCollision.b},session)
        if session.won then media:trigger({type="win"},session) end
      end
    end
  end
end

local function renderScene(x,y,w,h)
  if smooth then
    sampler:draw(transport.position,x,y,w,h)
  else
    Runtime.draw(document,transport:frame(),x,y,w,h)
  end
  if media then media:draw(document,x,y,w,h,transport.position,smooth and sampler or nil) end
end

function love.draw()
  drawnFrames=drawnFrames+1
  local lg=love.graphics
  local w,h,top,stageHeight=metrics()
  lg.clear(C.bg)
  lg.setColor(C.top)
  lg.rectangle("fill",0,0,w,top)
  label("LUA-FLASH",20,13,C.accent,fonts.heading)
  label("PLAYER 0.11  |  Colisao por movimento e desempenho",21,60,C.muted,fonts.small)
  button("PACOTE",w-575,24,83,36,session~=nil)
  button("JOGAR",w-486,24,83,36,game~=nil)

  button("DEMO",w-395,24,80,36,false)
  button("PROJETO SALVO",w-305,24,143,36,false)
  button(transport.loop and "LOOP: ON" or "LOOP: OFF",w-153,24,132,36,transport.loop)
  renderScene(18,top+10,w-36,stageHeight-15)

  if game then
    local viewport=sceneViewport()
    local ox,oy,scale=Runtime.geometry(document,viewport.x,viewport.y,viewport.w,viewport.h)
    local reticleX=ox+game.reticleX*scale
    local reticleY=oy+game.reticleY*scale
    lg.push("all")
    lg.setScissor(viewport.x,viewport.y,viewport.w,viewport.h)
    lg.setColor(0,0,0,.58)
    lg.rectangle("fill",viewport.x+12,viewport.y+12,248,80,8,8)
    label("ACERTE A BOLA",viewport.x+22,viewport.y+17,C.green)
    label("Pontos: "..game.score.."   Erros: "..game.misses,
      viewport.x+22,viewport.y+39,C.text,fonts.small)
    label(string.format("Tempo: %.1fs",game.remaining),
      viewport.x+22,viewport.y+58,C.text,fonts.small)
    lg.setColor(1,.35,.35,.95)
    lg.setLineWidth(2)
    lg.circle("line",reticleX,reticleY,12)
    lg.line(reticleX-18,reticleY,reticleX+18,reticleY)
    lg.line(reticleX,reticleY-18,reticleX,reticleY+18)
    if not game.active then
      lg.setColor(0,0,0,.72)
      lg.rectangle("fill",ox+document.width*scale*.22,oy+document.height*scale*.36,
        document.width*scale*.56,document.height*scale*.25,10,10)
      label("FIM DE JOGO - "..game.score.." PONTOS",
        ox+document.width*scale*.26,oy+document.height*scale*.43,C.text)
    end
    lg.pop()
  end

  if session then
    local viewport=sceneViewport()
    local x,y=viewport.x+12,viewport.y+12
    lg.push("all")
    lg.setScissor(viewport.x,viewport.y,viewport.w,viewport.h)
    lg.setColor(0,0,0,.72)
    lg.rectangle("fill",x,y,330,128,8,8)
    label(session.definition.title,x+10,y+9,C.green)
    label("Pontos: "..session.score.." / "..session.definition.goal..
      (media and (media.muted and "  |  SOM: OFF" or ("  |  VOL: "..math.floor(media.volume*100+.5).."%")) or ""),
      x+10,y+33,C.text,fonts.small)
    label(string.format("Tempo: %.1fs | Eventos: %d",session.remaining,session.events),
      x+10,y+52,C.text,fonts.small)
    local stateText=""
    if session.definition.version and session.definition.version>=2 then
      for _,item in ipairs(session.definition.states) do
        if stateText~="" then stateText=stateText.."  |  " end
        stateText=stateText..item.id..": "..tostring(session.states[item.id])
      end
    end
    if stateText~="" then label(stateText,x+10,y+72,C.green,fonts.small) end
    label(session.lastAction,x+10,y+97,C.muted,fonts.small)
    if not session.active then
      lg.setColor(0,0,0,.74)
      lg.rectangle("fill",viewport.x+viewport.w*.22,viewport.y+viewport.h*.40,
        viewport.w*.56,75,9,9)
      label(session.won and "VITORIA!" or "FIM DE JOGO",
        viewport.x+viewport.w*.40,viewport.y+viewport.h*.40+24,C.text)
    end
    lg.pop()
  end

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
  label(session and "Jogo v6: colisao continua amostrada | F8/F9/F10" or
    (game and "Clique/toque na bola | WASD: mira | ENTER: disparar | G: novo jogo" or
    "Espaco: play | Setas: quadro | I: interpolacao | F11: tela cheia"),
    27,ctrlY+40,C.muted,fonts.small)

  lg.setColor(C.top)
  lg.rectangle("fill",0,h-26,w,26)
  label(notice,13,h-22,C.muted,fonts.small)
end

function love.mousepressed(x,y,key,istouch)
  if istouch or key~=1 then return end
  local w,h,top,stageHeight=metrics()
  if inside(x,y,w-575,24,83,36) then openGameExample();return
  elseif inside(x,y,w-486,24,83,36) then startGame();return
  elseif inside(x,y,w-395,24,80,36) then
    install(Demo.create(),"Demonstracao interna",true);return
  elseif inside(x,y,w-305,24,143,36) then openSaved();return
  elseif inside(x,y,w-153,24,132,36) then transport.loop=not transport.loop;return
  end
  local topPanel=top+stageHeight+12
  local barY=topPanel+30
  local ctrlY=barY+23
  if inside(x,y,28,barY-8,w-56,22) then seekFromX(x,w);return
  elseif inside(x,y,27,ctrlY,52,32) then transport:step(-1);return
  elseif inside(x,y,85,ctrlY,94,32) then transport:toggle();return
  elseif inside(x,y,185,ctrlY,52,32) then transport:step(1);return
  elseif inside(x,y,250,ctrlY,34,32) then transport:cycleSpeed(-1);return
  elseif inside(x,y,353,ctrlY,34,32) then transport:cycleSpeed(1);return
  elseif inside(x,y,w-155,ctrlY,135,32) then toggleSmooth();return
  end
  local event=input:pointer("down","mouse",1,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media)
  if game and event.inside then game:setReticle(event.x,event.y) end
end

function love.mousereleased(x,y,key,istouch)
  if istouch or key~=1 then return end
  onEvent(input:pointer("up","mouse",1,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media))
end

function love.mousemoved(x,y,dx,dy,istouch)
  if istouch then return end
  local sx,sy=Input.stagePoint(x,y,document,sceneViewport())
  if game and sx then game:setReticle(sx,sy) end
  input:pointer("move","mouse",1,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media)
end

function love.touchpressed(id,x,y)
  local sx,sy=Input.stagePoint(x,y,document,sceneViewport())
  if not sx then
    love.mousepressed(x,y,1,false)
    return
  end
  input:pointer("down","touch",id,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media)
  if game then game:setReticle(sx,sy) end
end

function love.touchmoved(id,x,y)
  local sx,sy=Input.stagePoint(x,y,document,sceneViewport())
  if game and sx then game:setReticle(sx,sy) end
  input:pointer("move","touch",id,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media)
end

function love.touchreleased(id,x,y)
  onEvent(input:pointer("up","touch",id,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media))
end

function love.touchcancelled(id,x,y)
  input:pointer("cancel","touch",id,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media)
end

function love.focus(focused)
  if not focused then input:reset() end
end

function love.keypressed(key)
  input:key("down",key)
  local ctrl=love.keyboard.isDown("lctrl","rctrl")
  if ctrl and key=="s" then saveCopy();return end
  if key=="f8" and media then
    notice="Volume: "..math.floor(media:setVolume(media.volume-.1)*100+.5).."%"
    return
  elseif key=="f9" and media then
    notice="Volume: "..math.floor(media:setVolume(media.volume+.1)*100+.5).."%"
    return
  end
  if key=="f10" and media then
    notice=media:toggleMute() and "Efeitos sonoros silenciados." or "Efeitos sonoros ativados."
    return
  end
  if session then
    local event={type="keydown",key=key}
    local handled=session:dispatch(event)
    if media then
      media:trigger(event,session)
      if session.won then media:trigger({type="win"},session) end
    end
    if handled then notice=session.lastAction;return end
  end
  if key=="g" then startGame();return end
  if game then
    local direction={w={0,-25},a={-25,0},s={0,25},d={25,0}}
    local motion=direction[key]
    if motion then game:moveReticle(motion[1],motion[2],document);return end
    if key=="return" or key=="kpenter" then
      local result=game:attempt(currentHit(game.reticleX,game.reticleY))
      notice=result and "Acertou com o teclado!" or "Errou o alvo!"
      return
    end
  end
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

function love.keyreleased(key)
  input:key("up",key)
end

function love.wheelmoved(_,dy)
  if dy~=0 then transport:step(dy>0 and 1 or -1) end
end

function love.filedropped(file)
  local filename=file:getFilename() or ""
  local isProject=filename:lower():match("%.lflash$")~=nil
  local isGame=filename:lower():match("%.lfgame$")~=nil
  if not isProject and not isGame then
    notice="Arquivo nao suportado: use .lflash ou .lfgame."
    return
  end
  local ok,err=file:open("r")
  if not ok then notice="Nao foi possivel abrir: "..tostring(err);return end
  local bytes=file:read(MAX_FILE+1)
  file:close()
  if not bytes then notice="Erro ao ler arquivo.";return end
  local displayName=filename:match("[^/\\]+$") or filename
  if isGame then openGameBytes(bytes,displayName)
  else openBytes(bytes,displayName) end
end
