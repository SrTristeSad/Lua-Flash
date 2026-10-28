-- Lua-Flash Studio 0.1 with built-in preview for the native .lflash format.
-- No legacy Adobe SWF/FLA/ActionScript compatibility by design.
local Model = require("src.model")
local Exposure = require("src.frame_exposure")
local Library = require("src.symbol_library")
local SymbolPreview = require("src.symbol_preview")
local Runtime = require("src.runtime")
local doc = Model.new(800,450,24)
local runtime = Runtime.new(doc)
local symbolLibrary=Library.new()
local selectedSymbol=nil
local mode,tool="studio","brush"
local selected,dragged,dragX,dragY,offset= nil,nil,0,0,1
local undo,redo={},{}
local msg="Lua-Flash: plataforma nova em Lua | F1 ajuda"
local palette={{.16,.58,.94},{.98,.31,.37},{.24,.75,.49},{.99,.76,.24},{.16,.18,.23},{.65,.36,.93}}
local colorIndex,thickness=1,4
local view={x=180,y=58,w=800,h=480,ox=0,oy=0,scale=1}
local tools={{"select","V Selecionar"},{"brush","B Pincel"},{"line","L Linha"},{"rect","R Retangulo"},{"ellipse","O Elipse"},{"erase","E Borracha"}}
local font
local frameClipboard=nil
local timelineDrag=nil
local selectedKeys={}
local timelineCell=19
local function timelineCount(w)
  return math.max(1,math.floor((w-250-18)/timelineCell))
end
local function clampOffset(w)
  offset=math.max(1,math.min(offset,math.max(1,doc.totalFrames-timelineCount(w)+1)))
end
local function clone(value)
  if type(value)~="table" then return value end
  local out={}
  for k,v in pairs(value) do out[k]=clone(v) end
  return out
end
local projectName="projeto"
local naming=false
local nameDraft=""
local function cleanName(name)
  name=(name or ""):gsub("^%s+",""):gsub("%s+$","")
  if #name<1 or #name>64 or name:find("[^%w_%-]") then return nil end
  return name
end

local function dimensions()
  local w,h=love.graphics.getDimensions()
  local bottom=170
  view.x,view.y,view.w,view.h=176,53,math.max(180,w-176-204),math.max(170,h-bottom-53)
  view.ox,view.oy,view.scale=Runtime.geometry(doc,view.x,view.y,view.w,view.h)
  return w,h,h-bottom
end

local function snapshot()
  undo[#undo+1]={document=Model.encode(doc),symbols=Library.encode(symbolLibrary)}
  if #undo>40 then table.remove(undo,1) end
  redo={}
end

local function install(newdoc)
  doc=newdoc
  runtime=Runtime.new(doc)
  selected,dragged=nil,nil
  selectedKeys={}
  timelineDrag=nil
  dimensions()
end

local function history(reverse)
  local from,to=reverse and undo or redo,reverse and redo or undo
  if #from==0 then msg="Nada para "..(reverse and "desfazer" or "refazer");return end
  to[#to+1]={document=Model.encode(doc),symbols=Library.encode(symbolLibrary)}
  local contents=table.remove(from)
  local d,err=Model.decode(contents.document)
  local lib,liberr=Library.decode(contents.symbols)
  if d and lib then
    install(d)
    symbolLibrary=lib
    if selectedSymbol and not Library.find(lib,selectedSymbol) then selectedSymbol=nil end
  else
    msg="Historico invalido: "..tostring(err or liberr)
  end
end

local function save()
  local filename=projectName..".lflash"
  local bytes=Model.encode(doc)
  -- The native project stays LUAFLASH 1. Symbols live in a separate sidecar.
  local libOk,libErr=love.filesystem.write(filename..".lflib",Library.encode(symbolLibrary))
  if not libOk then msg="Erro ao salvar biblioteca: "..tostring(libErr);return end
  local ok,err=love.filesystem.write(filename,bytes)
  msg=ok and ("Projeto salvo: "..love.filesystem.getSaveDirectory().."/"..filename.." (+ .lflib)") or ("Erro ao salvar: "..tostring(err))
end
local function beginSaveAs()
  naming=true
  nameDraft=projectName=="projeto" and "" or projectName
  msg="Salvar como: digite um nome (letras, numeros, _ ou -). Enter confirma; Esc cancela."
end

local function load(data,libraryData)
  local d,err=Model.decode(data)
  if not d then msg="Nao foi possivel abrir: "..tostring(err);return end
  local lib,liberr=libraryData and Library.decode(libraryData) or Library.new()
  if not lib then msg="Biblioteca invalida: "..tostring(liberr);return end
  install(d)
  symbolLibrary=lib
  selectedSymbol=nil
  undo,redo={},{}
  msg="Projeto Lua-Flash aberto"
end

local function newProject()
  snapshot()
  install(Model.new(800,450,24))
  symbolLibrary=Library.new()
  selectedSymbol=nil
  runtime.playing=false
  mode="studio"
  projectName="projeto"
  naming=false
  msg="Novo projeto criado (Ctrl+Z para recuperar o anterior)"
end

local function openLast()
  local s,err=love.filesystem.read(projectName..".lflash")
  if s then
    local libData=love.filesystem.read(projectName..".lflash.lflib")
    load(s,libData)
  else msg="Arquivo nao encontrado: "..tostring(err) end
end

local function setFrame(n)
  runtime:seek(n)
  doc.currentFrame=runtime.frame
  selected=nil
end

local function active()
  return doc.layers[doc.currentLayer]
end

local function jumpKey(direction)
  local layer=active()
  if not layer then return end
  local target
  for frame in pairs(layer.keys) do
    if type(frame)=="number" and ((direction>0 and frame>doc.currentFrame) or (direction<0 and frame<doc.currentFrame)) then
      if not target or (direction>0 and frame<target) or (direction<0 and frame>target) then target=frame end
    end
  end
  if target then runtime.playing=false;setFrame(target) else msg="Nenhum quadro-chave nessa direcao" end
end

local function currentShapes(create)
  local layer=active()
  if not layer or layer.locked then return nil end
  return create and Model.ensureKey(layer,doc.currentFrame) or Model.frame(layer,doc.currentFrame)
end

local function inBox(x,y,bx,by,bw,bh)
  return x>=bx and y>=by and x<bx+bw and y<by+bh
end

local function xy(mx,my)
  return (mx-view.ox)/view.scale,(my-view.oy)/view.scale
end

local function insideStage(mx,my)
  return inBox(mx,my,view.ox,view.oy,doc.width*view.scale,doc.height*view.scale)
end

local function label(s,x,y,col)
  love.graphics.setColor(col or {.88,.90,.94})
  love.graphics.print(s,x,y)
end

local function button(s,x,y,w,h,activeButton)
  love.graphics.setColor(activeButton and {.19,.49,.70} or {.22,.25,.30})
  love.graphics.rectangle("fill",x,y,w,h,5,5)
  love.graphics.setColor(.42,.45,.5)
  love.graphics.rectangle("line",x+.5,y+.5,w-1,h-1,5,5)
  label(s,x+10,y+8)
end

function love.load()
  love.window.setTitle("Lua-Flash Studio 0.2 (com pre-visualizacao)")
  love.window.setMode(1200,780,{resizable=true,minwidth=850,minheight=590})
  love.graphics.setDefaultFilter("linear","linear")
  font=love.graphics.newFont(13)
  love.graphics.setFont(font)
  dimensions()
end

function love.update(dt)
  runtime:update(dt)
  if runtime.playing then doc.currentFrame=runtime.frame end
end

local function ui()
  local lg=love.graphics
  local w,h,track=dimensions()
  clampOffset(w)
  lg.clear(.12,.14,.18)
  lg.setColor(.15,.18,.22)
  lg.rectangle("fill",0,0,w,50)
  label("LUA-FLASH",16,17,{.38,.83,1})
  button("STUDIO",160,8,95,34,mode=="studio")
  button("PLAYER",263,8,95,34,mode=="player")
  button(runtime.playing and "PAUSAR" or "TESTAR",366,8,91,34,runtime.playing)
  if mode=="studio" then
    button("SALVAR",465,8,82,34,false)
    button("+ CAMADA",555,8,109,34,false)
    label("Formato proprio .lflash | Sem SWF/FLA",w-337,17,{.67,.72,.8})
  else
    label("Previa de publicacao Lua-Flash | ESPACO inicia/pausa",475,17,{.67,.72,.8})
  end

  if mode=="studio" then
    lg.setColor(.15,.17,.20)
    lg.rectangle("fill",0,50,170,track-50)
    lg.rectangle("fill",w-198,50,198,track-50)
    label("FERRAMENTAS",14,65,{.45,.82,1})
    for i,item in ipairs(tools) do
      button(item[2],11,92+(i-1)*39,146,34,tool==item[1])
    end
    label("CORES",14,346,{.45,.82,1})
    for i,c in ipairs(palette) do
      lg.setColor(c)
      lg.rectangle("fill",12+(i-1)%3*46,375+math.floor((i-1)/3)*44,36,35,5,5)
      if colorIndex==i then
        lg.setColor(1,1,1);lg.rectangle("line",12+(i-1)%3*46,375+math.floor((i-1)/3)*44,36,35,5,5)
      end
    end
    label("Espessura: "..thickness.."  (- / +)",12,477)
    label("CAMADAS",w-186,65,{.45,.82,1})
    button("+ Nova camada",w-187,90,176,34,false)
    for i,layer in ipairs(doc.layers) do
      local name=(layer.visible and "o " or "- ")..layer.name..(layer.locked and " [X]" or "")
      button(name,w-187,132+(i-1)*35,118,31,i==doc.currentLayer)
      button(layer.visible and "O" or "-",w-65,132+(i-1)*35,25,31,layer.visible)
      button(layer.locked and "X" or "L",w-37,132+(i-1)*35,26,31,layer.locked)
    end
    label("Palco "..doc.width.." x "..doc.height,w-185,track-92)
    label("FPS: "..doc.fps,w-185,track-72)
    label("Camada "..doc.currentLayer.." | F7 vis. F8 trava",w-185,track-52)
    label("BIBLIOTECA  |  Ctrl+F8 cria Graphic",w-186,326,{.45,.82,1})
    local symbolList=Library.list(symbolLibrary)
    for i=1,math.min(#symbolList,5) do
      local symbol=symbolList[i]
      local title=symbol.id.." "..symbol.kind..": "..symbol.name
      button(title:sub(1,24),w-187,348+(i-1)*28,175,26,selectedSymbol==symbol.id)
    end
  end

  runtime.draw(doc,doc.currentFrame,view.x,view.y,view.w,view.h)
  SymbolPreview.draw(symbolLibrary,doc,doc.currentFrame,view)
  if mode=="studio" and selected then
    local layer=active()
    local shapes=layer and Model.frame(layer,doc.currentFrame)
    if shapes and shapes[selected] then
      local x1,y1,x2,y2=Model.bounds(shapes[selected])
      lg.setColor(.1,.63,1)
      lg.setLineWidth(1)
      lg.rectangle("line",view.ox+x1*view.scale-3,view.oy+y1*view.scale-3,(x2-x1)*view.scale+6,(y2-y1)*view.scale+6)
    end
  end

  lg.setColor(.15,.17,.20)
  lg.rectangle("fill",0,track,w,h-track)
  lg.setColor(.25,.28,.32)
  lg.line(0,track,w,track)
  label(mode=="studio" and "TIMELINE | F6: chave  F9: vazio  SHIFT+F6: excluir" or "REPRODUCAO  |  ESPACO: play/pause",12,track+10,{.44,.82,1})
  label("Quadro "..doc.currentFrame.." / "..doc.totalFrames.."    "..doc.fps.." FPS",12,track+41)
  label("Anterior/Proximo: <- ->",12,track+64,{.64,.7,.78})
  if mode=="studio" then
    local startX,cell=250,timelineCell
    local count=timelineCount(w)
    local rows=math.min(#doc.layers,3)
    for row=1,rows do
      local layerIndex=((doc.currentLayer+row-2)%#doc.layers)+1
      local layer=doc.layers[layerIndex]
      local rowY=track+38+(row-1)*26
      label(tostring(layerIndex)..(layerIndex==doc.currentLayer and "*" or ""),222,rowY+4)
      for j=1,count do
        local n=offset+j-1
        if n<=doc.totalFrames then
          local cx=startX+(j-1)*cell
          local exposure=Exposure.exposure(layer,n,doc.totalFrames)
          local hasKey=exposure and exposure.isKey
          local blank=exposure and exposure.blank
          local chosen=layerIndex==doc.currentLayer and selectedKeys[n]
          lg.setColor(chosen and {.60,.40,.87} or
            (n==doc.currentFrame and {.2,.62,.88} or
            (blank and {.24,.26,.30} or {.36,.42,.50})))
          lg.rectangle("fill",cx,rowY,cell-2,23)
          if row==1 and (n%5==0 or j==1) then label(tostring(n),cx,track+17,{.72,.76,.82}) end
          if hasKey then
            lg.setColor(.97,.82,.32)
            if blank then
              lg.circle("line",cx+math.min(8,cell/2),rowY+16,3)
            else
              lg.circle("fill",cx+math.min(8,cell/2),rowY+16,3)
            end
          elseif exposure then
            lg.setColor(.58,.63,.69)
            lg.line(cx+3,rowY+16,cx+math.max(4,cell-5),rowY+16)
          end
        end
      end
    end
    label("Roda: rolar | Ctrl+roda: zoom ("..timelineCell.." px)",250,track+91,{.63,.68,.74})
  end
  lg.setColor(.1,.12,.14)
  lg.rectangle("fill",0,h-24,w,24)
  label(naming and ("SALVAR COMO > "..nameDraft.."_") or msg,10,h-20,{.76,.8,.85})
end

function love.draw() ui() end

function love.mousepressed(mx,my,mousebutton)
  if mousebutton~=1 then return end
  if naming then return end
  local w,h,track=dimensions()
  if inBox(mx,my,160,8,95,34) then mode="studio";runtime.playing=false;return end
  if inBox(mx,my,263,8,95,34) then mode="player";runtime.playing=true;return end
  if inBox(mx,my,366,8,91,34) then runtime.playing=not runtime.playing;return end
  if mode=="player" then return end
  if inBox(mx,my,465,8,82,34) then save();return end
  if inBox(mx,my,555,8,109,34) or inBox(mx,my,w-187,90,176,34) then
    snapshot();Model.addLayer(doc);selected=nil;msg="Camada criada";return
  end
  for i,item in ipairs(tools) do
    if inBox(mx,my,11,92+(i-1)*39,146,34) then tool=item[1];msg="Ferramenta: "..tool;return end
  end
  local symbols=Library.list(symbolLibrary)
  for i=1,math.min(#symbols,5) do
    if inBox(mx,my,w-187,348+(i-1)*28,175,26) then
      selectedSymbol=symbols[i].id
      tool="symbol"
      msg="Instancia selecionada: "..symbols[i].name.." | clique no palco"
      return
    end
  end
  for i in ipairs(palette) do
    if inBox(mx,my,12+(i-1)%3*46,375+math.floor((i-1)/3)*44,36,35) then colorIndex=i;return end
  end
  for i,layer in ipairs(doc.layers) do
    local cy=132+(i-1)*35
    if inBox(mx,my,w-65,cy,25,31) then
      snapshot();layer.visible=not layer.visible
      msg=layer.visible and "Camada visivel" or "Camada oculta";return
    end
    if inBox(mx,my,w-37,cy,26,31) then
      snapshot();layer.locked=not layer.locked
      msg=layer.locked and "Camada bloqueada" or "Camada desbloqueada";return
    end
    if inBox(mx,my,w-187,cy,118,31) then
      doc.currentLayer=i;selected=nil;return
    end
  end
  if my>=track+38 and my<track+38+math.min(#doc.layers,3)*26
      and mx>=250 and mx<w-18 then
    local row=math.floor((my-track-38)/26)+1
    local layerIndex=((doc.currentLayer+row-2)%#doc.layers)+1
    if layerIndex~=doc.currentLayer then
      doc.currentLayer=layerIndex
      selectedKeys={}
      timelineDrag=nil
    end
    local n=offset+math.floor((mx-250)/timelineCell)
    if n>=1 and n<=doc.totalFrames then
      runtime.playing=false
      setFrame(n)
      if Model.isKey(active(),n) and not active().locked then
        if love.keyboard.isDown("lshift","rshift") then
          selectedKeys[n]=not selectedKeys[n] or nil
        else
          if not selectedKeys[n] then selectedKeys={[n]=true} end
          local sources={}
          for key,enabled in pairs(selectedKeys) do
            if enabled and active().keys[key] then sources[#sources+1]=key end
          end
          table.sort(sources)
          timelineDrag={source=n,target=n,sources=sources,duplicate=love.keyboard.isDown("lctrl","rctrl")}
        end
      elseif not love.keyboard.isDown("lshift","rshift") then
        selectedKeys={}
      end
    end
    return
  end
  if not insideStage(mx,my) then return end
  local layer=active()
  if not layer or layer.locked then msg="Camada bloqueada";return end
  local x,y=xy(mx,my)
  local existing=Model.frame(layer,doc.currentFrame)
  if tool=="symbol" then
    if not selectedSymbol or not Library.find(symbolLibrary,selectedSymbol) then
      msg="Selecione um simbolo na biblioteca";return
    end
    snapshot()
    Model.ensureKey(layer,doc.currentFrame)
    local instance,err=Library.place(symbolLibrary,doc.currentLayer,doc.currentFrame,selectedSymbol,x,y)
    msg=instance and "Instancia adicionada ao palco" or tostring(err)
  elseif tool=="select" then
    selected=nil
    for i=#existing,1,-1 do if Model.hit(existing[i],x,y) then selected=i;break end end
    if selected then
      snapshot()
      Model.ensureKey(layer,doc.currentFrame)
      dragged="move";dragX,dragY=x,y
    end
  elseif tool=="erase" then
    for i=#existing,1,-1 do
      if Model.hit(existing[i],x,y) then
        snapshot()
        local shapes=Model.ensureKey(layer,doc.currentFrame)
        table.remove(shapes,i);selected=nil;break
      end
    end
  else
    snapshot()
    local shapes=Model.ensureKey(layer,doc.currentFrame)
    local shape=Model.makeShape(tool,palette[colorIndex],thickness,x,y)
    shapes[#shapes+1]=shape
    dragged=shape
    selected=nil
  end
end

function love.mousemoved(mx,my,dx,dy)
  if timelineDrag then
    local w,h,track=dimensions()
    if mx>=250 and mx<w-18 and my>=track+38 and my<=track+79 then
      local frame=offset+math.floor((mx-250)/timelineCell)
      if frame>=1 and frame<=doc.totalFrames then timelineDrag.target=frame end
    end
    return
  end
  if not dragged or mode~="studio" then return end
  local x,y=xy(mx,my)
  x,y=math.max(0,math.min(doc.width,x)),math.max(0,math.min(doc.height,y))
  if dragged=="move" then
    local shapes=currentShapes(true)
    if shapes and selected and shapes[selected] then Model.move(shapes[selected],x-dragX,y-dragY) end
    dragX,dragY=x,y
  elseif dragged.kind=="brush" then
    local p=dragged.points
    if math.abs(p[#p-1]-x)+math.abs(p[#p]-y)>1 then
      p[#p+1]=x
      p[#p+1]=y
    end
  else
    dragged.points[3],dragged.points[4]=x,y
  end
end

function love.mousereleased(_,_,button)
  if button~=1 then return end
  if timelineDrag then
    local op=timelineDrag
    timelineDrag=nil
    local layer=active()
    if layer and not layer.locked and op.source~=op.target then
      local delta=op.target-op.source
      local sourceSet={}
      for _,key in ipairs(op.sources) do sourceSet[key]=true end
      local valid=#op.sources>0
      for _,key in ipairs(op.sources) do
        local destination=key+delta
        if destination<1 or destination>doc.totalFrames
            or (not op.duplicate and key==1)
            or (layer.keys[destination] and (op.duplicate or not sourceSet[destination])) then
          valid=false
          break
        end
      end
      if valid then
        snapshot()
        local copied={}
        for _,key in ipairs(op.sources) do copied[key+delta]=clone(layer.keys[key]) end
        if not op.duplicate then
          for _,key in ipairs(op.sources) do layer.keys[key]=nil end
        end
        selectedKeys={}
        for key,shapes in pairs(copied) do
          layer.keys[key]=shapes
          selectedKeys[key]=true
        end
        setFrame(op.target)
        msg=op.duplicate and "Quadros-chave duplicados" or "Quadros-chave movidos"
      else
        msg="Operacao cancelada: destino ocupado, limite ou quadro inicial"
      end
    end
  end
  dragged=nil
end

function love.wheelmoved(_,dy)
  if mode~="studio" then return end
  local mx,my=love.mouse.getPosition()
  local _,_,track=dimensions()
  if my>=track then
    local w=love.graphics.getWidth and love.graphics.getWidth() or select(1,love.graphics.getDimensions())
    if love.keyboard.isDown("lctrl","rctrl") then
      local old=timelineCell
      timelineCell=math.max(12,math.min(38,timelineCell+math.floor(dy*2)))
      if timelineCell~=old then
        local focused=offset+math.floor((mx-250)/old)
        offset=focused-math.floor((mx-250)/timelineCell)
      end
    else
      offset=offset-math.floor(dy*3)
    end
    clampOffset(w)
  else
    thickness=math.max(1,math.min(40,thickness+math.floor(dy)))
  end
end

function love.textinput(text)
  if naming and #nameDraft+#text<=64 and not text:find("[^%w_%-]") then
    nameDraft=nameDraft..text
  end
end

function love.keypressed(key)
  if naming then
    if key=="escape" then naming=false;msg="Salvar como cancelado";return end
    if key=="backspace" then nameDraft=nameDraft:sub(1,-2);return end
    if key=="return" or key=="kpenter" then
      local safe=cleanName(nameDraft)
      if not safe then msg="Nome invalido: use letras, numeros, _ ou -";return end
      local filename=safe..".lflash"
      if safe~=projectName and love.filesystem.getInfo and love.filesystem.getInfo(filename) then
        msg="Arquivo existente. Escolha outro nome.";return
      end
      projectName=safe
      naming=false
      save()
      return
    end
    return
  end
  local ctrl=love.keyboard.isDown("lctrl","rctrl")
  local shift=love.keyboard.isDown("lshift","rshift")
  if ctrl and key=="f8" and mode=="studio" then
    if active().locked then msg="Camada bloqueada";return end
    local kind=shift and "movieclip" or (love.keyboard.isDown("lalt","ralt") and "button" or "graphic")
    local shapes=Model.frame(active(),doc.currentFrame)
    if #shapes==0 then msg="Desenhe algo antes de criar um simbolo";return end
    snapshot()
    local symbol,err=Library.create(symbolLibrary,kind,"Simbolo "..symbolLibrary.nextSymbolId,shapes)
    if symbol then
      selectedSymbol=symbol.id
      tool="symbol"
      msg="Simbolo "..symbol.kind.." criado. Clique no palco para instanciar."
    else msg=tostring(err) end
    return
  end
  if ctrl and key=="c" and mode=="studio" then
    frameClipboard=clone(Model.frame(active(),doc.currentFrame))
    msg="Quadro copiado para area interna do Studio"
    return
  end
  if ctrl and key=="v" and mode=="studio" then
    if not frameClipboard then msg="Nenhum quadro copiado";return end
    if active().locked then msg="Camada bloqueada";return end
    snapshot()
    active().keys[doc.currentFrame]=clone(frameClipboard)
    selected=nil
    msg="Quadro colado na camada atual"
    return
  end
  if ctrl and key=="n" then newProject();return end
  if ctrl and shift and key=="s" then beginSaveAs();return end
  if ctrl and key=="s" then save();return end
  if ctrl and key=="o" then openLast();return end
  if ctrl and key=="e" then
    local ok,err=love.filesystem.write("quadro.svg",Model.svg(doc,doc.currentFrame))
    msg=ok and "SVG exportado para pasta de dados do Lua-Flash" or tostring(err)
    return
  end
  if ctrl and key=="z" then history(true);return end
  if ctrl and key=="y" then history(false);return end
  if key=="tab" then mode=(mode=="studio") and "player" or "studio";runtime.playing=mode=="player";return end
  if key=="space" then runtime.playing=not runtime.playing;return end
  if key=="left" then runtime.playing=false;setFrame(doc.currentFrame-1);return end
  if key=="right" then runtime.playing=false;setFrame(doc.currentFrame+1);return end
  if key=="f1" then msg="TAB Studio/Player | F6 chave | F7 visibilidade | F8 trava | Ctrl+N novo | Ctrl+S salva";return end
  if mode~="studio" then return end
  if key=="pageup" then jumpKey(-1);return end
  if key=="pagedown" then jumpKey(1);return end
  if key=="home" then runtime.playing=false;setFrame(1);return end
  if key=="end" then runtime.playing=false;setFrame(doc.totalFrames);return end
  if key=="f7" then
    if not active() then return end
    snapshot()
    active().visible=not active().visible
    msg=active().visible and "Camada visivel" or "Camada oculta"
    return
  end
  if key=="f8" then
    if not active() then return end
    snapshot()
    active().locked=not active().locked
    msg=active().locked and "Camada bloqueada" or "Camada desbloqueada"
    return
  end
  if key=="f9" then
    if active().locked then msg="Camada bloqueada";return end
    snapshot()
    Exposure.insertBlankKey(active(),doc.currentFrame)
    Library.ensureKey(symbolLibrary,doc.currentLayer,doc.currentFrame,true)
    selected=nil
    msg="Quadro-chave vazio inserido"
    return
  end
  if key=="f6" then
    if active().locked then msg="Camada bloqueada";return end
    snapshot()
    if shift then
      Model.removeKey(active(),doc.currentFrame)
      Library.removeKey(symbolLibrary,doc.currentLayer,doc.currentFrame)
    else
      Model.ensureKey(active(),doc.currentFrame)
      Library.ensureKey(symbolLibrary,doc.currentLayer,doc.currentFrame)
    end
    selected=nil
    return
  end
  if key=="v" then tool="select"
  elseif key=="b" then tool="brush"
  elseif key=="l" then tool="line"
  elseif key=="r" then tool="rect"
  elseif key=="o" then tool="ellipse"
  elseif key=="e" then tool="erase"
  elseif key=="-" or key=="kp-" then thickness=math.max(1,thickness-1)
  elseif key=="=" or key=="+" or key=="kp+" then thickness=math.min(40,thickness+1) end
end

function love.filedropped(file)
  if not file:getFilename():lower():match("%.lflash$") then
    msg="Somente projetos Lua-Flash .lflash sao aceitos";return
  end
  if not file:open("r") then msg="Nao foi possivel abrir arquivo";return end
  local content=file:read()
  file:close()
  if content then
    load(content)
    projectName="projeto"
    msg="Projeto importado. Ctrl+Shift+S permite salvar com novo nome."
  end
end
