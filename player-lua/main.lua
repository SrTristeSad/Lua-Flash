-- Lua-Flash Player 0.23. Independent runtime for native .lflash animations.
-- Does not execute SWF, ActionScript or embedded project code.
local Model=require("src.model")
local Runtime=require("src.runtime")
local Demo=require("src.demo")
local Transport=require("src.transport")
local Interpolation=require("src.interpolation")
local Input=require("src.input")
local TargetGame=require("src.target_game")
local GamePackage=require("src.package_v9")
local SpriteTween=require("src.sprite_tween")
local KeyframeEditor=require("src.keyframe_editor")
local EditHistory=require("src.edit_history")
local Recovery=require("src.recovery")
local Diagnostics=require("src.diagnostics")
local ErrorReport=require("src.error_report")
local SpriteTransform=require("src.sprite_transform")
local MediaRuntime=require("src.media_runtime")
local Session=require("src.session")
local GameExample=require("src.game_example_v9")
local FileImport=require("src.file_import")
local NativeDialog=require("src.native_dialog")
local WindowIcon=require("src.window_icon")
local Responsive=require("src.responsive")

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
local history=nil
local recoveryClock=0
local recoveryStore=nil
local diagnostics=Diagnostics.new()
local errors=ErrorReport.new(love.filesystem)
local lastRuntimeError=nil
local showDiagnostics=false
local selectedAudioChannel="effects"
local pathPrompt={open=false,value="",message=""}
local editor={open=false,track=1,segment=1,scroll=0,drag=nil}
local C={
  bg={.075,.085,.11},top={.11,.13,.17},panel={.14,.16,.20},
  text={.90,.94,1},muted={.62,.69,.77},accent={.25,.70,.99},
  highlight={.19,.36,.52},line={.23,.28,.35},green={.35,.86,.65}
}
local MAX_FILE=25*1024*1024
-- CI-only graphical smoke mode; runs regular LÖVE graphics before exiting.
local ciSmoke=(os.getenv("LUA_FLASH_SMOKE")=="1")
local drawnFrames=0

local function screenLayout()
  local w,h=love.graphics.getDimensions()
  return Responsive.layout(w,h)
end
local function logicalPointer(x,y)
  return Responsive.logical(screenLayout(),x,y)
end
local function metrics()
  local screen=screenLayout()
  local w,h=screen.w,screen.h
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
  selectedAudioChannel="effects"
  history=nil
  recoveryClock=0
  recoveryStore=nil
  editor={open=false,track=1,segment=1,scroll=0,drag=nil}
  document=doc
  lastRuntimeError=nil
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

local function canReplace()
  if history and history:isDirty() then
    notice="Alteracoes nao salvas. Ctrl+S antes de abrir outro projeto."
    return false
  end
  return true
end

local function openBytes(content,name)
  if not canReplace() then return false end
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
local function openGameBytes(content,name,originalKey)
  if not canReplace() then return false end
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
  history=definition.version>=8 and EditHistory.new(definition) or nil
  recoveryStore=history and Recovery.new(love.filesystem,GamePackage,
    originalKey or Recovery.identity(name or definition.title,content)) or nil
  smooth=definition.smooth
  notice="Jogo "..definition.title.." iniciado. Sem execucao de scripts externos."
  if recoveryStore and recoveryStore:read() then
    notice="Copia de recuperacao disponivel neste jogo: Ctrl+R."
  end
  return true
end

-- Load from an explicit path without handing untrusted content to Lua code.
-- This is used by drag/drop, Explorer's Open With, and the Ctrl+O path dialog.
local function openNativePath(path)
  if not canReplace() then return false end
  local loaded,err
  if NativeDialog.available() then
    -- UTF-16 Windows file APIs support accented and non-ASCII paths.
    local kind,name=FileImport.classify(path)
    if not kind then notice=name;return false end
    local bytes
    bytes,err=NativeDialog.readPath(path,FileImport.MAX_BYTES)
    if bytes then loaded={kind=kind,name=name,bytes=bytes,path=path} end
  else
    loaded,err=FileImport.readPath(path)
  end
  if not loaded then
    notice=err
    return false
  end
  local success
  if loaded.kind=="game" then
    success=openGameBytes(loaded.bytes,loaded.name)
  else
    success=openBytes(loaded.bytes,loaded.name)
  end
  if success then
    pathPrompt.open=false
    pathPrompt.message=""
  end
  return success
end
local openPathPrompt
local function openFilePicker()
  if not canReplace() then return end
  if not NativeDialog.available() then
    return openPathPrompt()
  end
  transport.playing=false
  local record,err=NativeDialog.choose(FileImport.MAX_BYTES)
  if not record then
    if err~="cancelled" then notice=err end
    return
  end
  local kind,name=FileImport.classify(record.path)
  if not kind then notice=name;return end
  local loaded
  if kind=="game" then loaded=openGameBytes(record.bytes,name)
  else loaded=openBytes(record.bytes,name) end
  if loaded then
    pathPrompt.open=false
    pathPrompt.message=""
  end
end

openPathPrompt=function()
  if not canReplace() then return end
  pathPrompt={open=true,value="",message=""}
  transport.playing=false
  notice="Cole o caminho completo do arquivo .lflash ou .lfgame."
end
local function closePathPrompt()
  pathPrompt.open=false
  pathPrompt.message=""
end
local function editPathKey(key,ctrl)
  if ctrl and key=="v" and love.system and love.system.getClipboardText then
    local clipboard=love.system.getClipboardText()
    if type(clipboard)=="string" and not clipboard:find("[%z\r\n]") then
      local candidate=pathPrompt.value..clipboard
      if #candidate<=FileImport.MAX_PATH then pathPrompt.value=candidate end
    end
    return
  end
  if key=="escape" then closePathPrompt();return end
  if key=="return" or key=="kpenter" then
    local value=pathPrompt.value
    -- Windows Explorer "Copy as path" wraps names in double quotes.
    if value:sub(1,1)=='"' and value:sub(-1)=='"' then
      value=value:sub(2,-2)
    end
    if not openNativePath(value) then
      pathPrompt.message=notice
    end
    return
  end
  if key=="backspace" then
    local value=pathPrompt.value
    local i=#value
    -- Remove one UTF-8 codepoint, including non-ASCII Windows paths.
    while i>1 and value:byte(i)>=128 and value:byte(i)<192 do i=i-1 end
    pathPrompt.value=value:sub(1,i-1)
  end
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
    local ok,result,err=pcall(GamePackage.encode,packageDefinition)
    if not ok or not result then
      notice="Erro: projeto invalido, nao salvo: "..tostring(ok and err or result)
      return false
    end
    content=result
    name="player_game.lfgame"
  else
    local ok,result=pcall(Model.encode,document)
    if not ok then notice="Erro ao salvar cena: "..tostring(result);return false end
    content=result
    name="player_demo.lflash"
  end
  local ok,err=love.filesystem.write(name,content)
  if ok then
    if history then history:markSaved() end
    if recoveryStore then recoveryStore:clear() end
    notice="Copia salva: "..love.filesystem.getSaveDirectory().."/"..name
  else
    notice="Erro ao salvar: "..tostring(err)
  end
  return ok==true
end

-- Recovery is an additional copy, never written over the imported game.
-- Writes happen only after edits have settled for 12 seconds, not per drag.
local function autosaveRecovery(dt)
  if not history or not recoveryStore or editor.drag then return end
  recoveryClock=recoveryClock+dt
  if recoveryClock<12 then return end
  recoveryClock=0
  if not history:isDirty() then return end
  local saved,problem=recoveryStore:save(packageDefinition)
  if not saved then notice="Aviso: recuperacao falhou: "..tostring(problem) end
end

local function openRecovery()
  if history and history:isDirty() then
    notice="Salve o jogo atual com Ctrl+S antes de recuperar outro."
    return
  end
  if not recoveryStore then
    notice="Abra primeiro o jogo original para localizar sua recuperacao."
    return
  end
  local restored,err=recoveryStore:read()
  if not restored then
    notice="Recuperacao indisponivel: "..tostring(err)
    return
  end
  local key=recoveryStore.key
  if openGameBytes(restored.bytes,"Recuperacao "..source,key) then
    notice="Recuperacao verificada (copia "..restored.sequence.."). Ctrl+S salva."
  end
end

local function seekFromX(x,w)
  transport:seekProgress((x-32)/(w-64))
end

local function startGame()
  if not canReplace() then return end
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

-- A compact visual segment/curve editor, intentionally scoped to the Player.
-- It changes only game data, and Ctrl+S saves the edited .lfgame package.
local function editorTrack()
  return packageDefinition and packageDefinition.tweens and
    packageDefinition.tweens[editor.track] or nil
end
local function editorSelection()
  local track=editorTrack()
  if not track then return nil,nil,nil end
  editor.segment=math.max(1,math.min(#track.keys,editor.segment))
  local key=track.keys[editor.segment]
  if not key then return nil,nil,nil end
  local mode=editor.segment==#track.keys and "FINAL" or "LINEAR"
  for _,e in ipairs(packageDefinition.easings or {}) do
    if e.index==track.index and e.frame==key.frame then
      mode=e.mode;break
    end
  end
  return track,key,mode
end
local function editorNavigateTracks(delta)
  if not packageDefinition or not packageDefinition.tweens then return end
  local n=#packageDefinition.tweens
  if n==0 then return end
  editor.track=((editor.track-1+delta)%n)+1
  editor.segment=1;editor.scroll=0
  notice="Sprite "..editorTrack().index.." selecionado."
end
local function editorNavigateSegments(delta)
  local track=editorTrack()
  if not track then return end
  editor.segment=math.max(1,math.min(#track.keys,editor.segment+delta))
  if editor.segment<editor.scroll+1 then editor.scroll=editor.segment-1 end
  if editor.segment>editor.scroll+4 then editor.scroll=editor.segment-4 end
  notice="Trecho selecionado: "..track.keys[editor.segment].frame
end
local editBegin,editCommit,editorUndo,editorAdjustPose
local function editorCycleCurve()
  local track,key,mode=editorSelection()
  if not track or editor.segment==#track.keys then
    notice="Ultimo quadro nao inicia trecho de easing.";return
  end
  if packageDefinition.version==8 then
    packageDefinition.version=9
    packageDefinition.easings={}
  end
  local before=editBegin()
  local modes=GamePackage.MODES
  local nextIndex=1
  for i,value in ipairs(modes) do
    if value==mode then nextIndex=(i%#modes)+1;break end
  end
  local nextMode=modes[nextIndex]
  for i=#packageDefinition.easings,1,-1 do
    local e=packageDefinition.easings[i]
    if e.index==track.index and e.frame==key.frame then
      table.remove(packageDefinition.easings,i)
    end
  end
  if nextMode~="LINEAR" then
    packageDefinition.easings[#packageDefinition.easings+1]={
      index=track.index,frame=key.frame,mode=nextMode
    }
  end
  editCommit(before)
  notice="Curva do sprite "..track.index.." (quadro "..key.frame.."): "..nextMode..
    " | Ctrl+S para salvar"
end
local function editorRefresh()
  if media then media.tween=SpriteTween.new(packageDefinition) end
  notice="Quadros-chave atualizados. Ctrl+S para salvar."
end
editBegin=function()
  return history and history:begin(editor.track,editor.segment) or nil
end
editCommit=function(before)
  if history and history:record(before) then
    recoveryClock=0
    editorRefresh()
  end
end
editorUndo=function(redo)
  if not history then return end
  if editor.drag then editor.drag=nil end
  local track,selected,err
  if redo then track,selected=history:redo(editor.track,editor.segment)
  else track,selected=history:undo(editor.track,editor.segment) end
  if not track then
    notice=selected or "Sem alteracoes no historico."
    return
  end
  editor.track=track
  editor.segment=selected
  local chosen=editorTrack()
  if chosen then
    editor.segment=math.min(editor.segment,#chosen.keys)
    editor.scroll=math.max(0,editor.segment-4)
    transport.playing=false
    transport:seek(chosen.keys[editor.segment].frame)
  end
  recoveryClock=0
  if media then media.tween=SpriteTween.new(packageDefinition) end
  notice=redo and "Refazer aplicado." or "Desfazer aplicado."
end
editorAdjustPose=function(which,delta)
  local track,key=editorSelection()
  if not key then return end
  local before=editBegin()
  local changed,err
  if which=="ANGLE" then
    changed,err=KeyframeEditor.rotate(packageDefinition,track.index,editor.segment,delta)
  else
    changed,err=KeyframeEditor.scale(packageDefinition,track.index,
      editor.segment,which,delta)
  end
  if not changed then notice=err;return end
  transport.playing=false
  transport:seek(key.frame)
  editCommit(before)
end
local function editorInsertKey()
  local track=editorTrack()
  if not track then return end
  local frame=math.floor(transport.position+.5)
  -- If the playhead sits exactly on a key, insert halfway to its successor.
  for i,key in ipairs(track.keys) do
    if key.frame==frame then
      local nextKey=track.keys[i+1]
      if nextKey and nextKey.frame-frame>1 then
        frame=math.floor((frame+nextKey.frame)/2)
      else
        notice="Escolha um quadro livre na barra inferior.";return
      end
      break
    end
  end
  local before=editBegin()
  local at,err=KeyframeEditor.insert(packageDefinition,track.index,frame)
  if not at then notice=err;return end
  editor.segment=at
  editor.scroll=math.max(0,at-4)
  transport.playing=false
  transport:seek(frame)
  editCommit(before)
end
local function editorDeleteKey()
  local track=editorTrack()
  if not track then return end
  local before=editBegin()
  local at,err=KeyframeEditor.remove(packageDefinition,track.index,editor.segment)
  if not at then notice=err;return end
  editor.segment=at
  editor.scroll=math.max(0,math.min(editor.scroll,#track.keys-4))
  transport:seek(track.keys[at].frame)
  editCommit(before)
end
local function editorMoveFrame(delta)
  local track,key=editorSelection()
  if not key then return end
  local frame=key.frame+delta
  local before=editBegin()
  local at,err=KeyframeEditor.moveFrame(packageDefinition,track.index,
    editor.segment,frame)
  if not at then notice=err;return end
  transport.playing=false
  transport:seek(frame)
  editCommit(before)
end
local function editorNudge(dx,dy)
  local track,key=editorSelection()
  if not key then return end
  local before=editBegin()
  local _,err=KeyframeEditor.shiftPosition(packageDefinition,track.index,
    editor.segment,dx,dy)
  if err then notice=err;return end
  transport.playing=false
  transport:seek(key.frame)
  editCommit(before)
end
local function editorBeginDrag(wx,wy)
  local track,key=editorSelection()
  if not track or not media then return false end
  local sx,sy=Input.stagePoint(wx,wy,document,sceneViewport())
  if not sx then return false end
  local rect=media:spriteRect(track.index,transport.position,
    smooth and sampler:sample(transport.position) or nil)
  if not rect then return false end
  local mask=media:maskFor(media:imageAsset(track.index,transport.position))
  if not SpriteTransform.contains(rect,mask,sx,sy) then return false end
  editor.drag={
    startX=sx,startY=sy,
    origX=key.x,origY=key.y,
    index=track.index,selected=editor.segment,
    before=editBegin()
  }
  transport.playing=false
  return true
end
local function editorDrag(wx,wy)
  local drag=editor.drag
  if not drag then return false end
  local viewport=sceneViewport()
  local ox,oy,scale=Runtime.geometry(document,
    viewport.x,viewport.y,viewport.w,viewport.h)
  local sx,sy=(wx-ox)/scale,(wy-oy)/scale
  local x=math.floor(drag.origX+sx-drag.startX+.5)
  local y=math.floor(drag.origY+sy-drag.startY+.5)
  if x<-4096 or x>4096 or y<-4096 or y>4096 then return true end
  local updated=KeyframeEditor.setPosition(packageDefinition,
    drag.index,drag.selected,x,y)
  if updated and media then media.tween=SpriteTween.new(packageDefinition) end
  return true
end
local function editorDrawOutline()
  if not editor.open or not media then return end
  local track=editorTrack()
  if not track then return end
  local p=transport.position
  local rect=media:spriteRect(track.index,p,smooth and sampler:sample(p) or nil)
  if not rect then return end
  local viewport=sceneViewport()
  local ox,oy,scale=Runtime.geometry(document,
    viewport.x,viewport.y,viewport.w,viewport.h)
  local points={}
  for _,corner in ipairs({{0,0},{1,0},{1,1},{0,1}}) do
    local x,y=SpriteTransform.toWorld(rect,corner[1],corner[2])
    points[#points+1]=ox+x*scale
    points[#points+1]=oy+y*scale
  end
  local lg=love.graphics
  lg.push("all")
  lg.setScissor(viewport.x,viewport.y,viewport.w,viewport.h)
  lg.setColor(C.accent)
  lg.setLineWidth(2)
  lg.polygon("line",points)
  lg.pop()
end

local function editorBounds()
  local viewport=sceneViewport()
  return viewport.x+viewport.w-314,viewport.y+10,302,412
end
local function drawCurveEditor()
  if not editor.open then return end
  local track,key,mode=editorSelection()
  if not track then return end
  local x,y,w,h=editorBounds()
  local lg=love.graphics
  lg.push("all")
  lg.setColor(.065,.085,.115,.96)
  lg.rectangle("fill",x,y,w,h,9,9)
  lg.setColor(C.accent)
  lg.rectangle("line",x+.5,y+.5,w-1,h-1,9,9)
  label("EDITOR DE KEYFRAMES [E]",x+12,y+10,C.text,fonts.regular)
  button("<",x+12,y+36,35,30,false)
  button(">",x+w-47,y+36,35,30,false)
  label(string.format("Sprite %d  |  %d trechos",track.index,#track.keys-1),
    x+56,y+43,C.green,fonts.small)
  label("Clique na chave para editar:",x+12,y+78,C.muted,fonts.small)
  local max=math.min(4,#track.keys-editor.scroll)
  for row=1,max do
    local i=editor.scroll+row
    local start,finish=track.keys[i],track.keys[i+1]
    local current="LINEAR"
    for _,e in ipairs(packageDefinition.easings or {}) do
      if e.index==track.index and e.frame==start.frame then
        current=e.mode;break
      end
    end
    local yy=y+99+(row-1)*26
    if i==editor.segment then
      lg.setColor(C.highlight)
      lg.rectangle("fill",x+8,yy,w-16,25,4,4)
    end
    label(finish and string.format("%3d > %3d    %s",start.frame,finish.frame,current)
      or string.format("%3d   (FINAL)",start.frame),
      x+17,yy+4,i==editor.segment and C.text or C.muted,fonts.small)
  end
  label(string.format("Chave %d/%d  Q:%d X:%d Y:%d",
    editor.segment,#track.keys,key.frame,key.x,key.y),
    x+12,y+203,C.green,fonts.small)
  label(string.format("Ang:%d  Escala X:%d%%  Y:%d%%",
    key.angle,key.scaleX,key.scaleY),
    x+12,y+222,C.muted,fonts.small)
  button("+CHAVE",x+12,y+239,80,28,false)
  button("-CHAVE",x+102,y+239,80,28,false)
  button("Q -",x+192,y+239,43,28,false)
  button("Q +",x+244,y+239,43,28,false)
  button("X -",x+12,y+272,59,28,false)
  button("X +",x+81,y+272,59,28,false)
  button("Y -",x+150,y+272,59,28,false)
  button("Y +",x+219,y+272,68,28,false)
  button("G -",x+12,y+305,59,27,false)
  button("G +",x+81,y+305,59,27,false)
  button("SX -",x+150,y+305,64,27,false)
  button("SX +",x+224,y+305,64,27,false)
  button("SY -",x+12,y+337,62,27,false)
  button("SY +",x+84,y+337,62,27,false)
  button("DESFAZER",x+156,y+337,132,27,false)
  button("CURVA: "..mode,x+12,y+h-39,170,29,true)
  button("SALVAR",x+w-105,y+h-39,93,29,false)
  lg.pop()
end
local function editorClick(x,y)
  if not editor.open then return false end
  local bx,by,bw,bh=editorBounds()
  if not inside(x,y,bx,by,bw,bh) then return false end
  local track=editorTrack()
  if not track then return true end
  if inside(x,y,bx+12,by+36,35,30) then editorNavigateTracks(-1)
  elseif inside(x,y,bx+bw-47,by+36,35,30) then editorNavigateTracks(1)
  elseif inside(x,y,bx+12,by+239,80,28) then editorInsertKey()
  elseif inside(x,y,bx+102,by+239,80,28) then editorDeleteKey()
  elseif inside(x,y,bx+192,by+239,43,28) then editorMoveFrame(-1)
  elseif inside(x,y,bx+244,by+239,43,28) then editorMoveFrame(1)
  elseif inside(x,y,bx+12,by+272,59,28) then editorNudge(-5,0)
  elseif inside(x,y,bx+81,by+272,59,28) then editorNudge(5,0)
  elseif inside(x,y,bx+150,by+272,59,28) then editorNudge(0,-5)
  elseif inside(x,y,bx+219,by+272,68,28) then editorNudge(0,5)
  elseif inside(x,y,bx+12,by+305,59,27) then editorAdjustPose("ANGLE",-5)
  elseif inside(x,y,bx+81,by+305,59,27) then editorAdjustPose("ANGLE",5)
  elseif inside(x,y,bx+150,by+305,64,27) then editorAdjustPose("X",-10)
  elseif inside(x,y,bx+224,by+305,64,27) then editorAdjustPose("X",10)
  elseif inside(x,y,bx+12,by+337,62,27) then editorAdjustPose("Y",-10)
  elseif inside(x,y,bx+84,by+337,62,27) then editorAdjustPose("Y",10)
  elseif inside(x,y,bx+156,by+337,132,27) then editorUndo(false)
  elseif inside(x,y,bx+12,by+bh-39,170,29) then editorCycleCurve()
  elseif inside(x,y,bx+bw-105,by+bh-39,93,29) then saveCopy()
  else
    for row=1,math.min(4,#track.keys-editor.scroll) do
      if inside(x,y,bx+8,by+99+(row-1)*26,bw-16,25) then
        editor.segment=editor.scroll+row
        transport.playing=false
        transport:seek(track.keys[editor.segment].frame)
        notice="Quadro-chave "..track.keys[editor.segment].frame.." selecionado."
        break
      end
    end
  end
  return true
end

local function toggleSmooth()
  smooth=not smooth
  notice=smooth and "Interpolacao visual ativada (nao altera seu arquivo)." or
    "Interpolacao visual desativada: quadros exatos do projeto."
end

function love.load(arguments)
  love.window.setTitle("Lua-Flash Player 0.23")
  love.window.setMode(1040,690,{resizable=true,minwidth=600,minheight=380,highdpi=true})
  love.graphics.setDefaultFilter("linear","linear")
  if love.image and love.image.newImageData and
      love.window and love.window.setIcon then
    pcall(function()
      local icon=WindowIcon.create(love.image.newImageData)
      love.window.setIcon(icon)
    end)
  end
  fonts.regular=love.graphics.newFont(13)
  fonts.heading=love.graphics.newFont(22)
  fonts.small=love.graphics.newFont(12)
  love.graphics.setFont(fonts.regular)
  local launchPath=FileImport.fromArguments(arguments)
  if launchPath then openNativePath(launchPath) end
  if os.getenv("LUA_FLASH_SMOKE_WIN_NATIVE")=="1" and launchPath then
    assert(NativeDialog.available(),"Windows native file API unavailable")
    local binary,readError=NativeDialog.readPath(launchPath,FileImport.MAX_BYTES)
    assert(binary and #binary>0,readError)
    assert(packageDefinition and packageDefinition.version==9,
      "native Unicode path file could not be imported")
    -- CI sentinel is emitted only after a successful Win32 Unicode read.
    local marker=os.getenv("LUA_FLASH_SMOKE_WIN_NATIVE_OKFILE")
    if marker and marker~="" then
      local output=assert(io.open(marker,"wb"))
      assert(output:write("LUAF_WIN_NATIVE_OK"))
      assert(output:close())
    end
  end
  if os.getenv("LUA_FLASH_SMOKE_CLI")=="1" then
    assert(launchPath and packageDefinition and packageDefinition.version==9,
      "command-line native game import failed")
  end
  if os.getenv("LUA_FLASH_SMOKE_MEDIA")=="1" then
    openGameExample()
    if not media then error("media demo failed to load") end
    local first=media:maskFor("estrela")
    local second=media:maskFor("estrela_alt")
    assert(first and second and first.w==16 and second.h==16,
      "LÖVE PNG alpha decoding failed")
    -- Exercise real LÖVE SoundData -> Source playback in CI (dummy audio).
    assert(media:playAsset("acerto","effects"),"event voice did not start")
    assert(media:playAsset("acerto","timeline"),"timeline voice did not start")
    local audio=media:audioStats()
    assert(audio.voices>=1 and audio.voices<=16,
      "real LÖVE WAV sources violated the voice budget")
    assert(media:setChannelVolume("timeline",.6)==.6)
  end
end

function love.update(dt)
  if ciSmoke and drawnFrames>=5 then love.event.quit();return end
  autosaveRecovery(dt)
  diagnostics:update(dt)
  local before,playing=transport.position,transport.playing
  transport:update(dt)
  local wraps=playing and transport.lastWraps or 0
  if media then media:timelineAdvance(before,transport.position,playing,transport.lastWraps) end
  if game then
    game:update(dt,transport.playing)
    if not game.active then transport.playing=false end
  end
  if session then
    session:update(dt)
    if session:checkCollisions(smooth and sampler or nil,media,
      playing and before or nil,wraps) then
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
  local view=screenLayout()
  local w,h,top,stageHeight=metrics()
  lg.clear(C.bg)
  lg.push("all")
  lg.translate(view.x,view.y)
  lg.scale(view.scale,view.scale)
  lg.setColor(C.top)
  lg.rectangle("fill",0,0,w,top)
  label("LUA-FLASH",20,13,C.accent,fonts.heading)
  label("PLAYER 0.23  |  Interface adaptavel e icone Windows",21,60,C.muted,fonts.small)
  button("PACOTE",w-575,24,83,36,session~=nil)
  button("JOGAR",w-486,24,83,36,game~=nil)

  button("DEMO",w-395,24,80,36,false)
  button("ABRIR ARQUIVO",w-305,24,143,36,pathPrompt.open)
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

  editorDrawOutline()
  drawCurveEditor()

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
  label(session and "Jogo v9: E edita | Ctrl+Z/Y desfaz/refaz | Ctrl+S salva" or
    (game and "Clique/toque na bola | WASD: mira | ENTER: disparar | G: novo jogo" or
    "Espaco: play | Setas: quadro | I: interpolacao | F11: tela cheia"),
    27,ctrlY+40,C.muted,fonts.small)

  lg.setColor(C.top)
  lg.rectangle("fill",0,h-26,w,26)
  label(notice,13,h-22,C.muted,fonts.small)
  if lastRuntimeError then
    lg.push("all")
    lg.setColor(.35,.10,.11,.95)
    lg.rectangle("fill",12,94,math.max(240,w-24),58,6,6)
    label("Falha recuperavel registrada em player-errors.log",22,102,C.text,fonts.small)
    label(lastRuntimeError:sub(1,112),22,123,C.text,fonts.small)
    lg.pop()
  end

  if pathPrompt.open then
    local lg=love.graphics
    local pw=math.min(w-50,800)
    local ph=206
    local x,y=(w-pw)/2,math.max(90,(h-ph)/2)
    lg.push("all")
    lg.setColor(0,0,0,.58)
    lg.rectangle("fill",0,0,w,h)
    lg.setColor(.085,.115,.15,1)
    lg.rectangle("fill",x,y,pw,ph,10,10)
    lg.setColor(C.accent)
    lg.rectangle("line",x+.5,y+.5,pw-1,ph-1,10,10)
    label("ABRIR ARQUIVO NATIVO [Ctrl+O]",x+16,y+15,C.text,fonts.heading)
    label("Arraste o arquivo para a janela ou cole o caminho completo:",x+16,y+52,C.muted,fonts.small)
    lg.setColor(.15,.18,.24,1)
    lg.rectangle("fill",x+16,y+75,pw-32,37,5,5)
    lg.setScissor(x+20,y+77,pw-40,34)
    label(pathPrompt.value~="" and pathPrompt.value or "C:\\pasta\\meu-jogo.lfgame",
      x+23,y+84,pathPrompt.value~="" and C.text or C.muted,fonts.small)
    lg.setScissor()
    label("ENTER: abrir  |  ESC: cancelar  |  Ctrl+V: colar",x+16,y+126,C.muted,fonts.small)
    if pathPrompt.message~="" then
      label(pathPrompt.message:sub(1,110),x+16,y+151,{1,.57,.52},fonts.small)
    end
    lg.pop()
  end
  if showDiagnostics then
    local report=diagnostics:snapshot(packageDefinition,media,session)
    lg.push("all")
    lg.setColor(.025,.035,.055,.93)
    lg.rectangle("fill",w-281,93,269,175,7,7)
    label("DIAGNOSTICO [F3]",w-270,100,C.green,fonts.small)
    label(string.format("FPS medio: %.1f | Pior dt: %.1f ms",
      report.fps,report.worstMs),w-270,123,C.text,fonts.small)
    label(string.format("Memoria Lua: %.1f MB",
      report.memoryKB/1024),w-270,146,C.text,fonts.small)
    label(string.format("Sprites: %d  Chaves: %d  Midias: %d",
      report.tracks,report.keys,report.resources),
      w-270,169,C.text,fonts.small)
    label(string.format("Mascaras: %d | Pares: %d",
      report.maskBuilds,report.collisionPairs),
      w-270,192,C.text,fonts.small)
    if media then
      local audio=media:audioStats()
      label(string.format("Vozes: %d/%d | Ativas: %d | Reuso: %d",
        audio.voices,audio.maxVoices,audio.active,audio.steals),
        w-270,215,C.green,fonts.small)
      label(string.format("Efeito: %d%% | Timeline: %d%%",
        math.floor(media.mixer.gains.effects*100+.5),
        math.floor(media.mixer.gains.timeline*100+.5)),
        w-270,237,C.muted,fonts.small)
    end
    lg.pop()
  end
  lg.pop()
end

function love.mousepressed(x,y,key,istouch)
  if istouch or key~=1 then return end
  x,y=logicalPointer(x,y)
  if not x then return end
  if pathPrompt.open then return end
  if editorClick(x,y) then return end
  if editor.open and Input.stagePoint(x,y,document,sceneViewport()) then
    editorBeginDrag(x,y)
    return
  end
  local w,h,top,stageHeight=metrics()
  if inside(x,y,w-575,24,83,36) then openGameExample();return
  elseif inside(x,y,w-486,24,83,36) then startGame();return
  elseif inside(x,y,w-395,24,80,36) then
    if canReplace() then install(Demo.create(),"Demonstracao interna",true) end;return
  elseif inside(x,y,w-305,24,143,36) then openFilePicker();return
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
  x,y=logicalPointer(x,y)
  if not x then
    if editor.drag then editCommit(editor.drag.before);editor.drag=nil end
    return
  end
  if editor.open then
    if editor.drag then editCommit(editor.drag.before);editor.drag=nil end
    return
  end
  onEvent(input:pointer("up","mouse",1,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media))
end

function love.mousemoved(x,y,dx,dy,istouch)
  if istouch then return end
  local newX,newY=logicalPointer(x,y)
  if not newX then return end
  x,y=newX,newY
  dx,dy=dx/screenLayout().scale,dy/screenLayout().scale
  if editor.drag then editorDrag(x,y);return end
  local sx,sy=Input.stagePoint(x,y,document,sceneViewport())
  if game and sx then game:setReticle(sx,sy) end
  input:pointer("move","mouse",1,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media)
end

function love.touchpressed(id,x,y)
  local logicalX,logicalY=logicalPointer(x,y)
  if not logicalX then return end
  x,y=logicalX,logicalY
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
  local logicalX,logicalY=logicalPointer(x,y)
  if not logicalX then return end
  x,y=logicalX,logicalY
  local sx,sy=Input.stagePoint(x,y,document,sceneViewport())
  if game and sx then game:setReticle(sx,sy) end
  input:pointer("move","touch",id,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media)
end

function love.touchreleased(id,x,y)
  local logicalX,logicalY=logicalPointer(x,y)
  if not logicalX then return end
  x,y=logicalX,logicalY
  onEvent(input:pointer("up","touch",id,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media))
end

function love.touchcancelled(id,x,y)
  local logicalX,logicalY=logicalPointer(x,y)
  if not logicalX then return end
  x,y=logicalX,logicalY
  input:pointer("cancel","touch",id,x,y,document,transport.position,
    sceneViewport(),smooth and sampler or nil,media)
end

function love.focus(focused)
  if not focused then input:reset() end
end

function love.keypressed(key)
  local ctrl=love.keyboard.isDown("lctrl","rctrl")
  if pathPrompt.open then editPathKey(key,ctrl);return end
  if ctrl and key=="o" then
    if love.keyboard.isDown("lshift","rshift") then openPathPrompt()
    else openFilePicker() end
    return
  end
  input:key("down",key)
  if ctrl and key=="s" then saveCopy();return end
  if ctrl and (key=="y" or
      (key=="z" and love.keyboard.isDown("lshift","rshift"))) then
    editorUndo(true);return
  end
  if ctrl and key=="z" then editorUndo(false);return end
  if ctrl and key=="r" then openRecovery();return end
  if key=="f3" then showDiagnostics=not showDiagnostics;return end
  if key=="f4" then lastRuntimeError=nil;return end
  if key=="e" and packageDefinition and packageDefinition.version>=8 and
      packageDefinition.tweens and #packageDefinition.tweens>0 then
    editor.open=not editor.open
    if editor.open then transport.playing=false;editor.drag=nil end
    notice=editor.open and "Editor de curvas aberto. Clique em um trecho." or
      "Editor de curvas fechado."
    return
  end
  if editor.open then
    if key=="escape" then editor.open=false;notice="Editor fechado.";return
    elseif key=="c" then editorCycleCurve();return
    elseif key=="up" then editorNavigateSegments(-1);return
    elseif key=="down" then editorNavigateSegments(1);return
    elseif key=="insert" then editorInsertKey();return
    elseif key=="delete" then editorDeleteKey();return
    elseif key=="r" then editorAdjustPose("ANGLE",5);return
    elseif key=="t" then editorAdjustPose("ANGLE",-5);return
    elseif key=="x" then editorAdjustPose("X",10);return
    elseif key=="v" then editorAdjustPose("X",-10);return
    elseif key=="b" then editorAdjustPose("Y",10);return
    elseif key=="n" then editorAdjustPose("Y",-10);return
    elseif key=="[" then editorMoveFrame(-1);return
    elseif key=="]" then editorMoveFrame(1);return
    elseif key=="pageup" then editorNavigateTracks(-1);return
    elseif key=="pagedown" then editorNavigateTracks(1);return
    end
  end
  if key=="f5" and media then
    selectedAudioChannel=selectedAudioChannel=="effects" and "timeline" or "effects"
    notice="Canal selecionado: "..selectedAudioChannel.." (F6/F7 ajustam volume)."
    return
  end
  if (key=="f6" or key=="f7") and media then
    local value=media.mixer.gains[selectedAudioChannel]+
      (key=="f6" and -.1 or .1)
    local gain=media:setChannelVolume(selectedAudioChannel,value)
    notice="Canal "..selectedAudioChannel..": "..math.floor(gain*100+.5).."%"
    return
  end
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
  elseif key=="d" then if canReplace() then install(Demo.create(),"Demonstracao interna",true) end
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
  if editor.open and dy~=0 then
    local mx,my=love.mouse.getPosition()
    local x,y=logicalPointer(mx,my)
    local bx,by,bw,bh=editorBounds()
    if x and inside(x,y,bx,by,bw,bh) then
      local track=editorTrack()
      if track then
        editor.scroll=math.max(0,math.min(math.max(0,#track.keys-4),
          editor.scroll-(dy>0 and 1 or -1)))
      end
      return
    end
  end
  if dy~=0 then transport:step(dy>0 and 1 or -1) end
end

function love.filedropped(file)
  if not canReplace() then return end
  local loaded,err=FileImport.readDropped(file)
  if not loaded then notice=err;pathPrompt.message=err;return end
  local ok
  if loaded.kind=="game" then ok=openGameBytes(loaded.bytes,loaded.name)
  else ok=openBytes(loaded.bytes,loaded.name) end
  if ok then closePathPrompt() else pathPrompt.message=notice end
end

function love.textinput(text)
  if not pathPrompt.open or type(text)~="string" then return end
  if text:find("[%z\r\n]") then return end
  local candidate=pathPrompt.value..text
  if #candidate<=FileImport.MAX_PATH then pathPrompt.value=candidate end
end

-- Keep application and user work open if callbacks fail unexpectedly.
-- Logs remain local to the LÖVE save directory. If rendering itself fails,
-- display a minimal error screen rather than recursively calling love.draw.
local callbacks={
  "load","update","draw","mousepressed","mousereleased","mousemoved",
  "touchpressed","touchmoved","touchreleased","touchcancelled",
  "keypressed","keyreleased","textinput","wheelmoved","filedropped","focus"
}
for _,name in ipairs(callbacks) do
  local original=love[name]
  if type(original)=="function" then
    love[name]=function(...)
      local ok,result=errors:protect("love."..name,original,...)
      if not ok then
        transport.playing=false
        lastRuntimeError=tostring(result):gsub("[\r\n]+"," "):sub(1,240)
        notice="Falha detectada; veja player-errors.log e F3."
        if name=="draw" then
          pcall(function()
            local lg=love.graphics
            if lg.reset then lg.reset() end
            lg.clear(.08,.08,.11,1)
            lg.setColor(1,.78,.78,1)
            lg.print("Lua-Flash Player: erro de desenho recuperavel",24,28)
            lg.print(lastRuntimeError:sub(1,135),24,56)
            lg.print("Abra outro arquivo ou reinicie o Player.",24,86)
          end)
        end
        return nil
      end
      return result
    end
  end
end
