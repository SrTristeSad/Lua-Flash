-- Lua-Flash Studio 0.1 with built-in preview for the native .lflash format.
-- No legacy Adobe SWF/FLA/ActionScript compatibility by design.
local Model = require("src.model")
local Exposure = require("src.frame_exposure")
local Library = require("src.symbol_library")
local SymbolPreview = require("src.symbol_preview")
local Transform = require("src.instance_transform")
local Handles = require("src.instance_handles")
local Properties = require("src.instance_properties")
local Group = require("src.instance_group")
local Marquee = require("src.marquee_selection")
local Vector = require("src.vector_paths")
local VectorRenderer = require("src.vector_renderer")
local SymbolMotion = require("src.symbol_motion")
local TimelineOps = require("src.timeline_ops")
local Runtime = require("src.runtime")
local doc = Model.new(800,450,24)
local runtime = Runtime.new(doc)
local symbolLibrary=Library.new()
local vectors=Vector.new()
local symbolMotion=SymbolMotion.new()
local selectedSymbol=nil
local rootDoc=doc
local editingSymbolId=nil
-- Instance tracks belong to the main scene; symbols currently contain vector art only.
local symbolTimeline=Library.new()
local function trackLibrary()
  return editingSymbolId and symbolTimeline or symbolLibrary
end
local mode,tool="studio","brush"
local selected,dragged,dragX,dragY,offset= nil,nil,0,0,1
local selectedInstance=nil
local selectedInstances={}
local groupDragStarted=false
local marquee=nil
local selectedVector=nil
local penPath=nil
local vectorDrag=nil
local instanceDragStarted=false
local handleDrag=nil
local propertiesOpen=true
local propertyEditor=nil
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
local function libraryPanel(track)
  local top=math.max(326,132+#doc.layers*35+10)
  local slots=math.max(0,math.min(5,math.floor((track-105-top-22)/28)))
  return top,slots
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
  undo[#undo+1]={document=Model.encode(rootDoc),symbols=Library.encode(symbolLibrary),vectors=Vector.encode(vectors),editingSymbolId=editingSymbolId}
  if #undo>40 then table.remove(undo,1) end
  redo={}
end

local function install(newdoc)
  doc=newdoc
  runtime=Runtime.new(doc)
  SymbolMotion.reset(symbolMotion)
  selected,dragged=nil,nil
  selectedInstance=nil
  selectedInstances={}
  groupDragStarted=false
  marquee=nil
  selectedVector=nil
  penPath=nil
  vectorDrag=nil
  instanceDragStarted=false
  handleDrag=nil
  propertyEditor=nil
  selectedKeys={}
  timelineDrag=nil
  dimensions()
end

local function history(reverse)
  local from,to=reverse and undo or redo,reverse and redo or undo
  if #from==0 then msg="Nada para "..(reverse and "desfazer" or "refazer");return end
  to[#to+1]={document=Model.encode(rootDoc),symbols=Library.encode(symbolLibrary),vectors=Vector.encode(vectors),editingSymbolId=editingSymbolId}
  local contents=table.remove(from)
  local d,err=Model.decode(contents.document)
  local lib,liberr=Library.decode(contents.symbols)
  local vec,vecerr=Vector.decode(contents.vectors or Vector.encode(Vector.new()))
  if d and lib and vec then
    rootDoc=d
    symbolLibrary=lib
    vectors=vec
    editingSymbolId=contents.editingSymbolId
    if editingSymbolId and not Library.find(lib,editingSymbolId) then editingSymbolId=nil end
    symbolTimeline=Library.new()
    local focus=editingSymbolId and Library.find(lib,editingSymbolId)
    install(focus and focus.definition or rootDoc)
    if selectedSymbol and not Library.find(lib,selectedSymbol) then selectedSymbol=nil end
  else
    msg="Historico invalido: "..tostring(err or liberr or vecerr)
  end
end

local function save()
  local filename=projectName..".lflash"
  local bytes=Model.encode(rootDoc)
  -- Native LUAFLASH 1 stays unchanged. Vector geometry is an authoring sidecar.
  local vecOk,vecErr=love.filesystem.write(filename..".lfvec",Vector.encode(vectors))
  if not vecOk then msg="Erro ao salvar vetores: "..tostring(vecErr);return end
  local libOk,libErr=love.filesystem.write(filename..".lflib",Library.encode(symbolLibrary))
  if not libOk then msg="Erro ao salvar biblioteca: "..tostring(libErr);return end
  local ok,err=love.filesystem.write(filename,bytes)
  msg=ok and ("Projeto salvo: "..love.filesystem.getSaveDirectory().."/"..filename.." (+ .lflib e .lfvec)") or ("Erro ao salvar: "..tostring(err))
end
local function beginSaveAs()
  naming=true
  nameDraft=projectName=="projeto" and "" or projectName
  msg="Salvar como: digite um nome (letras, numeros, _ ou -). Enter confirma; Esc cancela."
end

local function load(data,libraryData,vectorData)
  local d,err=Model.decode(data)
  if not d then msg="Nao foi possivel abrir: "..tostring(err);return end
  local lib,liberr=libraryData and Library.decode(libraryData) or Library.new()
  if not lib then msg="Biblioteca invalida: "..tostring(liberr);return end
  local vec,vecerr=vectorData and Vector.decode(vectorData) or Vector.new()
  if not vec then msg="Vetores invalidos: "..tostring(vecerr);return end
  vectors=vec
  rootDoc=d
  editingSymbolId=nil
  symbolTimeline=Library.new()
  install(rootDoc)
  symbolLibrary=lib
  selectedSymbol=nil
  undo,redo={},{}
  msg="Projeto Lua-Flash aberto"
end

local function newProject()
  snapshot()
  rootDoc=Model.new(800,450,24)
  editingSymbolId=nil
  symbolTimeline=Library.new()
  install(rootDoc)
  symbolLibrary=Library.new()
  vectors=Vector.new()
  selectedSymbol=nil
  runtime.playing=false
  mode="studio"
  projectName="projeto"
  naming=false
  msg="Novo projeto criado (Ctrl+Z para recuperar o anterior)"
end

local function editSymbol(id)
  local symbol=Library.find(symbolLibrary,id)
  if not symbol then msg="Simbolo nao encontrado";return end
  if editingSymbolId then msg="Volte ao palco para escolher outro simbolo";return end
  editingSymbolId=id
  selectedSymbol=id
  symbolTimeline=Library.new()
  install(symbol.definition)
  mode="studio"
  tool="select"
  runtime.playing=false
  offset=1
  msg="Editando "..symbol.name.." | F5 estende, F6 cria chave; Esc volta ao palco"
end

local function exitSymbol()
  if not editingSymbolId then return end
  editingSymbolId=nil
  symbolTimeline=Library.new()
  install(rootDoc)
  mode="studio"
  tool="select"
  runtime.playing=false
  offset=1
  msg="Voltou ao palco principal. Alteracoes do simbolo mantidas."
end

local function openLast()
  local s,err=love.filesystem.read(projectName..".lflash")
  if s then
    local libData=love.filesystem.read(projectName..".lflash.lflib")
    local vectorData=love.filesystem.read(projectName..".lflash.lfvec")
    load(s,libData,vectorData)
  else msg="Arquivo nao encontrado: "..tostring(err) end
end

local function setFrame(n)
  runtime:seek(n)
  SymbolMotion.reset(symbolMotion)
  doc.currentFrame=runtime.frame
  selected=nil
  selectedInstance=nil
  selectedInstances={}
  groupDragStarted=false
  marquee=nil
  penPath=nil
  vectorDrag=nil
  selectedVector=nil
  handleDrag=nil
  propertyEditor=nil
end

local function active()
  return doc.layers[doc.currentLayer]
end

local function activeInstance()
  if editingSymbolId or not selectedInstance then return nil end
  for _,item in ipairs(Library.at(symbolLibrary,selectedInstance.layer,doc.currentFrame)) do
    if item.uid==selectedInstance.uid then return item end
  end
  return nil
end

local function selectedCount()
  return editingSymbolId and 0 or Group.count(selectedInstances)
end

local groupActions={
  {label="ESQ",op="left",col=0,row=0},
  {label="CENT X",op="centerX",col=1,row=0},
  {label="DIR",op="right",col=2,row=0},
  {label="TOPO",op="top",col=0,row=1},
  {label="CENT Y",op="centerY",col=1,row=1},
  {label="BASE",op="bottom",col=2,row=1},
  {label="DIST X",op="distributeX",col=0,row=2},
  {label="DIST Y",op="distributeY",col=1,row=2},
  {label="MENOS",op="scale",value=.9,col=0,row=3},
  {label="MAIS",op="scale",value=1.1,col=1,row=3},
  {label="-5 G",op="rotate",value=-5,col=2,row=3},
  {label="+5 G",op="rotate",value=5,col=0,row=4},
}
local function applyGroup(op,value)
  if editingSymbolId or not selectedInstance or selectedCount()<2 then
    msg="Selecione duas ou mais instancias";return false
  end
  local tx,err=Group.plan(doc,symbolLibrary,selectedInstance.layer,
    doc.currentFrame,selectedInstances,op,value)
  if not tx then msg="Grupo: "..tostring(err);return false end
  snapshot()
  tx.apply()
  msg="Grupo: "..op.." aplicado a "..selectedCount().." instancias"
  return true
end

local function panelGeometry()
  return view.x+view.w-236,65,226,219
end
local groupPropertyFields={
  {id="dx",name="Mover X",default="0"},
  {id="dy",name="Mover Y",default="0"},
  {id="scale",name="Escala %",default="100"},
  {id="rotation",name="Giro graus",default="0"}
}
local function groupPanelHeight()
  return 354
end
local function selectedHandlePoints()
  local item=activeInstance()
  local symbol=item and Library.find(symbolLibrary,item.symbolId)
  if not symbol then return nil end
  local frame=SymbolMotion.frame(symbolMotion,symbolLibrary,symbol,item,
    selectedInstance.layer,doc.currentFrame)
  return Handles.points(item,symbol,frame,view.scale),symbol,frame
end

local function prepareInstanceEdit()
  local instance=activeInstance()
  local layer=selectedInstance and doc.layers[selectedInstance.layer]
  if not instance or not layer or layer.locked then
    msg="Instancia indisponivel ou camada bloqueada"
    return nil
  end
  snapshot()
  -- Create separate key exposures for both native artwork and instance tracks.
  Model.ensureKey(layer,doc.currentFrame)
  Library.ensureKey(symbolLibrary,selectedInstance.layer,doc.currentFrame)
  return activeInstance()
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

local function vectorScope()
  return Vector.scope(vectors,editingSymbolId,true)
end
local function vectorOnFrame(id)
  if not id then return nil end
  for _,path in ipairs(Vector.at(vectorScope(),doc.currentLayer,doc.currentFrame)) do
    if path.id==id then return path end
  end
  return nil
end
local function editVectorFrame()
  local layer=active()
  if not layer or layer.locked then return false end
  snapshot()
  Model.ensureKey(layer,doc.currentFrame)
  Vector.ensureKey(vectorScope(),doc.currentLayer,doc.currentFrame)
  return true
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
  if not editingSymbolId then
    SymbolMotion.update(symbolMotion,symbolLibrary,doc,doc.currentFrame,dt,runtime.playing)
  end
  if mode=="player" and not editingSymbolId and love.mouse and love.mouse.getPosition then
    local mx,my=love.mouse.getPosition()
    SymbolPreview.pointerMoved(symbolMotion,symbolLibrary,doc,doc.currentFrame,view,mx,my)
  end
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
    if editingSymbolId or selectedSymbol then
      button(editingSymbolId and "VOLTAR PALCO" or "EDIT SIMBOLO",672,8,138,34,editingSymbolId~=nil)
    end
    button("P",816,8,36,34,tool=="pen")
    button("A",856,8,36,34,tool=="node")
    if w>1180 then label("Vetor Studio | sem SWF/FLA",900,17,{.67,.72,.8}) end
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
    if selectedVector then label("VETOR #"..selectedVector.." | F preench.",12,488,{.45,.82,1}) end
    local chosenInstance=activeInstance()
    if chosenInstance then
      if selectedCount()>1 then
        label("GRUPO: "..selectedCount().." instancias",12,513,{.45,.82,1})
        label("Shift+clique: incluir/remover",12,541)
        label("Arraste para mover o grupo",12,565)
      else
      button(propertiesOpen and "PROPRIEDADES -" or "PROPRIEDADES +",11,508,146,32,propertiesOpen)
      label("Instancia #"..chosenInstance.uid,12,548,{.45,.82,1})
      label(string.format("X %.1f | Y %.1f",chosenInstance.x,chosenInstance.y),12,570)
      end
    end
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
    if editingSymbolId then
      local sym=Library.find(symbolLibrary,editingSymbolId)
      label("EDITANDO: "..(sym and sym.name or "?"),w-185,track-112,{.98,.78,.38})
    end
    local libY,visibleSlots=libraryPanel(track)
    if libY<track-108 then label("BIBLIOTECA | Ctrl+F8",w-186,libY,{.45,.82,1}) end
    local symbolList=Library.list(symbolLibrary)
    for i=1,math.min(#symbolList,visibleSlots) do
      local symbol=symbolList[i]
      local title=symbol.id.." "..symbol.kind..": "..symbol.name
      button(title:sub(1,24),w-187,libY+22+(i-1)*28,175,26,selectedSymbol==symbol.id)
    end
  end

  runtime.draw(doc,doc.currentFrame,view.x,view.y,view.w,view.h)
  if not editingSymbolId then
    SymbolPreview.draw(symbolLibrary,doc,doc.currentFrame,view,symbolMotion,vectors)
  end
  VectorRenderer.draw(vectorScope(),doc,doc.currentFrame,view,selectedVector)
  if mode=="studio" and marquee then
    local x1,y1,x2,y2=Marquee.bounds(marquee.ax,marquee.ay,marquee.bx,marquee.by)
    if x1 then
      lg.setScissor(view.x,view.y,view.w,view.h)
      lg.setColor(.12,.66,.98,.16)
      lg.rectangle("fill",view.ox+x1*view.scale,view.oy+y1*view.scale,
        (x2-x1)*view.scale,(y2-y1)*view.scale)
      lg.setColor(.21,.76,1)
      lg.setLineWidth(1)
      lg.rectangle("line",view.ox+x1*view.scale,view.oy+y1*view.scale,
        (x2-x1)*view.scale,(y2-y1)*view.scale)
      lg.setScissor()
    end
  end
  if mode=="studio" and not editingSymbolId and selectedInstance then
    local item=activeInstance()
    local points=selectedCount()==1 and selectedHandlePoints() or nil
    if item and points then
      local function screen(pt)
        return view.ox+pt[1]*view.scale,view.oy+pt[2]*view.scale
      end
      local ax,ay=screen(points.tl)
      local bx,by=screen(points.tr)
      local cx,cy=screen(points.br)
      local dx,dy=screen(points.bl)
      local rx,ry=screen(points.rotate)
      lg.setColor(.1,.75,1)
      lg.setLineWidth(1)
      lg.line(ax,ay,bx,by,cx,cy,dx,dy,ax,ay)
      lg.line((ax+bx)/2,(ay+by)/2,rx,ry)
      for _,pt in ipairs({points.tl,points.tr,points.bl,points.br}) do
        local px,py=screen(pt)
        lg.setColor(.95,.96,.99)
        lg.rectangle("fill",px-4,py-4,8,8)
        lg.setColor(.1,.75,1)
        lg.rectangle("line",px-4,py-4,8,8)
      end
      lg.setColor(1,.73,.30)
      lg.circle("fill",rx,ry,6)
      lg.setColor(.17,.20,.24)
      lg.circle("line",rx,ry,6)
    end
    if item and selectedCount()>1 then
      for uid in pairs(selectedInstances) do
        for _,entry in ipairs(Library.at(symbolLibrary,selectedInstance.layer,doc.currentFrame)) do
          if entry.uid==uid then
            local sym=Library.find(symbolLibrary,entry.symbolId)
            local x1,y1,x2,y2=Transform.box(entry,sym,1)
            if x1 then
              lg.setColor(.15,.83,1)
              lg.setLineWidth(1)
              lg.rectangle("line",view.ox+x1*view.scale-2,view.oy+y1*view.scale-2,
                (x2-x1)*view.scale+4,(y2-y1)*view.scale+4)
            end
          end
        end
      end
      local px,py,pw,ph=panelGeometry()
      lg.setColor(.11,.14,.19,.96)
      lg.rectangle("fill",px,py,pw,groupPanelHeight(),6,6)
      lg.setColor(.36,.55,.72)
      lg.rectangle("line",px,py,pw,groupPanelHeight(),6,6)
      label("ALINHAR / DISTRIBUIR ("..selectedCount()..")",px+8,py+8,{.50,.85,1})
      for _,action in ipairs(groupActions) do
        button(action.label,px+7+action.col*73,py+38+action.row*34,
          69,30,false)
      end
      label("TRANSFORMACAO DO GRUPO",px+8,py+211,{.50,.85,1})
      for i,field in ipairs(groupPropertyFields) do
        local y=py+232+(i-1)*29
        label(field.name,px+8,y+5)
        local editing=propertyEditor and propertyEditor.group and propertyEditor.field==field.id
        lg.setColor(editing and {.23,.37,.48} or {.20,.24,.30})
        lg.rectangle("fill",px+106,y,110,24,3,3)
        label(editing and (propertyEditor.draft.."_") or field.default,px+114,y+5,{.95,.97,1})
      end
    end
    if item and selectedCount()==1 and propertiesOpen then
      local px,py,pw,ph=panelGeometry()
      lg.setColor(.11,.14,.19,.96)
      lg.rectangle("fill",px,py,pw,ph,6,6)
      lg.setColor(.36,.55,.72)
      lg.rectangle("line",px,py,pw,ph,6,6)
      label("PROPRIEDADES #"..item.uid,px+10,py+8,{.50,.85,1})
      button("X",px+pw-31,py+4,26,26,false)
      for i,field in ipairs(Properties.fields) do
        local cy=py+35+(i-1)*31
        local title=({x="X",y="Y",sx="Escala X",sy="Escala Y",angle="Angulo"})[field]
        label(title,px+9,cy+6)
        local focused=propertyEditor and propertyEditor.field==field
        lg.setColor(focused and {.23,.37,.48} or {.20,.24,.30})
        lg.rectangle("fill",px+82,cy,132,25,3,3)
        local val=focused and (propertyEditor.draft.."_") or Properties.format(item,field)
        label(val,px+88,cy+5,{.95,.97,1})
      end
    end
  end
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
  label(mode=="studio" and (editingSymbolId and "SIMBOLO | F5: estender  F6: chave  F9: vazio  Esc: voltar" or "TIMELINE | F6: chave  F9: vazio  SHIFT+F6: excluir") or "REPRODUCAO  |  ESPACO: play/pause",12,track+10,{.44,.82,1})
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

function love.mousepressed(mx,my,mousebutton,istouch,presses)
  if mousebutton~=1 then return end
  if naming then return end
  local w,h,track=dimensions()
  if inBox(mx,my,160,8,95,34) then mode="studio";runtime.playing=false;return end
  if inBox(mx,my,263,8,95,34) then mode="player";runtime.playing=true;return end
  if inBox(mx,my,366,8,91,34) then runtime.playing=not runtime.playing;return end
  if mode=="studio" and inBox(mx,my,816,8,36,34) then
    tool="pen";penPath=nil;msg="Caneta Bezier: clique cria ponto, arraste cria curva; Enter termina";return
  end
  if mode=="studio" and inBox(mx,my,856,8,36,34) then
    tool="node";penPath=nil;msg="Editar nos: arraste os pontos e as alcas de controle";return
  end
  if mode=="studio" and inBox(mx,my,672,8,138,34) then
    if editingSymbolId then exitSymbol() elseif selectedSymbol then editSymbol(selectedSymbol) end
    return
  end
  if mode=="player" then
    if not editingSymbolId then
      SymbolPreview.pointerMoved(symbolMotion,symbolLibrary,doc,doc.currentFrame,view,mx,my)
    end
    SymbolMotion.press(symbolMotion)
    return
  end
  if inBox(mx,my,465,8,82,34) then save();return end
  if inBox(mx,my,555,8,109,34) or inBox(mx,my,w-187,90,176,34) then
    snapshot();Model.addLayer(doc);selected=nil;msg="Camada criada";return
  end
  for i,item in ipairs(tools) do
    if inBox(mx,my,11,92+(i-1)*39,146,34) then tool=item[1];penPath=nil;msg="Ferramenta: "..tool;return end
  end
  local symbols=Library.list(symbolLibrary)
  local libY,visibleSlots=libraryPanel(track)
  for i=1,math.min(#symbols,visibleSlots) do
    if inBox(mx,my,w-187,libY+22+(i-1)*28,175,26) then
      if editingSymbolId then
        msg="Saia da edicao interna para selecionar outro simbolo"
        return
      end
      selectedSymbol=symbols[i].id
      if presses and presses>=2 then
        editSymbol(selectedSymbol)
      else
        tool="symbol"
        msg="Simbolo selecionado: "..symbols[i].name.." | duplo clique edita, clique no palco instancia"
      end
      return
    end
  end
  for i in ipairs(palette) do
    if inBox(mx,my,12+(i-1)%3*46,375+math.floor((i-1)/3)*44,36,35) then
      colorIndex=i
      local path=tool=="node" and vectorOnFrame(selectedVector)
      if path and editVectorFrame() then
        path=vectorOnFrame(selectedVector)
        if love.keyboard.isDown("lshift","rshift") and path.closed then
          path.fill=clone(palette[i])
          msg="Cor do preenchimento vetorial atualizada"
        else
          path.stroke=clone(palette[i])
          msg="Cor do contorno vetorial atualizada"
        end
      end
      return
    end
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
  if mode=="studio" and not editingSymbolId and activeInstance() and selectedCount()>1 then
    local px,py=panelGeometry()
    if inBox(mx,my,px,py,226,groupPanelHeight()) then
      for _,action in ipairs(groupActions) do
        if inBox(mx,my,px+7+action.col*73,py+38+action.row*34,69,30) then
          applyGroup(action.op,action.value)
          return
        end
      end
      for i,field in ipairs(groupPropertyFields) do
        if inBox(mx,my,px+106,py+232+(i-1)*29,110,24) then
          propertyEditor={group=true,field=field.id,draft=field.default,replace=true}
          msg="Digite o ajuste relativo e pressione Enter; Esc cancela"
          return
        end
      end
      return
    end
  end
  if mode=="studio" and not editingSymbolId and activeInstance() and selectedCount()==1 then
    if inBox(mx,my,11,508,146,32) then
      propertiesOpen=not propertiesOpen
      propertyEditor=nil
      return
    end
    if propertiesOpen then
      local px,py,pw,ph=panelGeometry()
      if inBox(mx,my,px,py,pw,ph) then
        if inBox(mx,my,px+pw-31,py+4,26,26) then
          propertiesOpen=false
          propertyEditor=nil
        else
          for i,field in ipairs(Properties.fields) do
            if inBox(mx,my,px+82,py+35+(i-1)*31,132,25) then
              propertyEditor={field=field,draft=Properties.format(activeInstance(),field),replace=true}
              msg="Edite "..field.." e pressione Enter para aplicar; Esc cancela"
              break
            end
          end
        end
        return
      end
    end
  end
  -- The scale / rotate handles take precedence over instance body picking.
  if mode=="studio" and tool=="select" and not editingSymbolId and activeInstance() and selectedCount()==1 then
    local points,symbol,frame=selectedHandlePoints()
    local kind=Handles.hit(points,view,mx,my)
    if kind then
      local item=activeInstance()
      if doc.layers[selectedInstance.layer].locked then
        msg="Camada bloqueada";return
      end
      handleDrag={kind=kind,base=Model.copy(item),symbol=symbol,
        frame=frame,points=points,dirty=false}
      return
    end
  end
  if not insideStage(mx,my) then return end
  local layer=active()
  if not layer or layer.locked then msg="Camada bloqueada";return end
  local x,y=xy(mx,my)
  local existing=Model.frame(layer,doc.currentFrame)
  if tool=="pen" then
    local pending=vectorOnFrame(penPath)
    if not pending then
      if not editVectorFrame() then msg="Camada bloqueada";return end
      local path,err=Vector.addPath(vectors,doc.currentLayer,doc.currentFrame,x,y,
        palette[colorIndex],thickness,nil)
      if not path then msg=tostring(err);return end
      selectedVector=path.id
      penPath=path.id
      vectorDrag={kind="new",id=path.id,node=1,dirty=true}
      msg="Caminho iniciado. Clique adiciona nos; arraste cria alcas; Enter finaliza."
    elseif #pending.nodes>=3
        and (pending.nodes[1].x-x)^2+(pending.nodes[1].y-y)^2<=(9/view.scale)^2 then
      Vector.close(pending)
      penPath=nil
      vectorDrag=nil
      msg="Caminho fechado. Pressione F para ativar preenchimento."
    else
      local index,err=Vector.addNode(pending,x,y)
      if not index then msg=tostring(err);return end
      vectorDrag={kind="new",id=pending.id,node=index,dirty=true}
      if presses and presses>=2 then penPath=nil;vectorDrag=nil end
    end
    return
  elseif tool=="node" then
    local paths=Vector.at(vectorScope(),doc.currentLayer,doc.currentFrame)
    local tol=8/view.scale
    local chosen=vectorOnFrame(selectedVector)
    if chosen then
      for ni,node in ipairs(chosen.nodes) do
        for _,which in ipairs({"in","out"}) do
          local hx,hy=which=="in" and node.ix or node.ox,
            which=="in" and node.iy or node.oy
          if (hx-x)^2+(hy-y)^2<=tol*tol
              and (hx-node.x)^2+(hy-node.y)^2>.01 then
            vectorDrag={kind=which,id=chosen.id,node=ni,dirty=false}
            return
          end
        end
      end
    end
    local found,node=Vector.pickNode(paths,x,y,tol)
    if found then
      selectedVector=found.id
      vectorDrag={kind="node",id=found.id,node=node,dirty=false}
      return
    end
    found=Vector.pick(paths,x,y,tol)
    selectedVector=found and found.id or nil
    if found then vectorDrag={kind="path",id=found.id,x=x,y=y,dirty=false} end
    msg=found and ("Vetor #"..found.id.." selecionado") or "Sem vetor nessa posicao"
    return
  elseif tool=="symbol" then
    if editingSymbolId then
      msg="Instancias aninhadas ainda nao disponiveis";return
    end
    if not selectedSymbol or not Library.find(symbolLibrary,selectedSymbol) then
      msg="Selecione um simbolo na biblioteca";return
    end
    snapshot()
    Model.ensureKey(layer,doc.currentFrame)
    local instance,err=Library.place(symbolLibrary,doc.currentLayer,doc.currentFrame,selectedSymbol,x,y)
    if instance then
      selectedInstance={uid=instance.uid,layer=doc.currentLayer}
      selectedInstances={[instance.uid]=true}
      propertiesOpen=true
    end
    msg=instance and "Instancia adicionada ao palco" or tostring(err)
  elseif tool=="select" then
    selected=nil
    if not editingSymbolId then
      local item,layerIndex=SymbolPreview.pickInstance(symbolLibrary,doc,doc.currentFrame,view,mx,my,symbolMotion)
      if item then
        local shift=love.keyboard.isDown("lshift","rshift")
        if shift and selectedCount()>0 then
          if selectedInstance and selectedInstance.layer~=layerIndex then
            msg="Selecao multipla limitada a uma camada";return
          end
          if selectedInstances[item.uid] then
            selectedInstances[item.uid]=nil
            if selectedCount()==0 then selectedInstance=nil
            elseif selectedInstance.uid==item.uid then
              for uid in pairs(selectedInstances) do
                selectedInstance={uid=uid,layer=layerIndex};break
              end
            end
          else
            selectedInstances[item.uid]=true
            selectedInstance={uid=item.uid,layer=layerIndex}
          end
          dragged=nil
          msg="Instancias selecionadas: "..selectedCount()
          return
        end
        local alreadySelected=selectedInstances[item.uid]
        if not alreadySelected or selectedCount()==0 then
          selectedInstances={[item.uid]=true}
        end
        doc.currentLayer=layerIndex
        selectedInstance={uid=item.uid,layer=layerIndex}
        propertiesOpen=true
        propertyEditor=nil
        if not doc.layers[layerIndex].locked then
          dragged=selectedCount()>1 and "group" or "instance"
          groupDragStarted=false
          instanceDragStarted=false
          dragX,dragY=x,y
        end
        msg=selectedCount()>1 and "Grupo selecionado | arraste para mover"
          or ("Instancia #"..item.uid.." selecionada | arraste, [ / ] gira")
        return
      end
    end
    if not love.keyboard.isDown("lshift","rshift") then
      selectedInstance=nil
      selectedInstances={}
    end
    for i=#existing,1,-1 do if Model.hit(existing[i],x,y) then selected=i;break end end
    if selected then
      snapshot()
      Model.ensureKey(layer,doc.currentFrame)
      dragged="move";dragX,dragY=x,y
    elseif not editingSymbolId then
      marquee={ax=x,ay=y,bx=x,by=y,
        add=love.keyboard.isDown("lshift","rshift"),layer=doc.currentLayer}
      msg="Selecao por area: esquerda→direita contem; direita→esquerda cruza"
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
  if mode=="player" then
    if not editingSymbolId then
      SymbolPreview.pointerMoved(symbolMotion,symbolLibrary,doc,doc.currentFrame,view,mx,my)
    end
    return
  end
  if marquee then
    local x,y=xy(mx,my)
    marquee.bx=math.max(0,math.min(doc.width,x))
    marquee.by=math.max(0,math.min(doc.height,y))
    return
  end
  if vectorDrag then
    local x,y=xy(mx,my)
    x,y=math.max(0,math.min(doc.width,x)),math.max(0,math.min(doc.height,y))
    local p=vectorOnFrame(vectorDrag.id)
    if not p then vectorDrag=nil;return end
    if not vectorDrag.dirty and not editVectorFrame() then vectorDrag=nil;return end
    if not vectorDrag.dirty then vectorDrag.dirty=true;p=vectorOnFrame(vectorDrag.id) end
    if vectorDrag.kind=="node" then
      Vector.moveNode(p,vectorDrag.node,x,y)
    elseif vectorDrag.kind=="in" or vectorDrag.kind=="out" then
      Vector.handle(p,vectorDrag.node,x,y,vectorDrag.kind)
    elseif vectorDrag.kind=="new" then
      local n=p.nodes[vectorDrag.node]
      if n then
        Vector.handle(p,vectorDrag.node,x,y,"out")
        Vector.handle(p,vectorDrag.node,2*n.x-x,2*n.y-y,"in")
      end
    elseif vectorDrag.kind=="path" then
      Vector.move(p,x-vectorDrag.x,y-vectorDrag.y)
      vectorDrag.x,vectorDrag.y=x,y
    end
    return
  end
  if timelineDrag then
    local w,h,track=dimensions()
    if mx>=250 and mx<w-18 and my>=track+38
        and my<track+38+math.min(#doc.layers,3)*26 then
      local frame=offset+math.floor((mx-250)/timelineCell)
      if frame>=1 and frame<=doc.totalFrames then timelineDrag.target=frame end
    end
    return
  end
  if handleDrag and mode=="studio" then
    local mxStage,myStage=xy(mx,my)
    local proposal=Handles.apply(handleDrag.base,handleDrag.symbol,
      handleDrag.frame,view.scale,handleDrag.kind,mxStage,myStage,handleDrag.points)
    if proposal then
      local source=activeInstance()
      if not handleDrag.dirty and source and (
        math.abs(proposal.x-source.x)>1e-4 or math.abs(proposal.y-source.y)>1e-4
        or math.abs(proposal.sx-source.sx)>1e-4
        or math.abs(proposal.sy-source.sy)>1e-4
        or math.abs((proposal.angle or 0)-(source.angle or 0))>1e-4) then
        if not prepareInstanceEdit() then handleDrag=nil;return end
        handleDrag.dirty=true
      end
      if handleDrag.dirty then
        local item=activeInstance()
        if item then
          item.x,item.y=proposal.x,proposal.y
          item.sx,item.sy,item.angle=proposal.sx,proposal.sy,proposal.angle
        end
      end
    end
    return
  end
  if not dragged or mode~="studio" then return end
  local x,y=xy(mx,my)
  x,y=math.max(0,math.min(doc.width,x)),math.max(0,math.min(doc.height,y))
  if dragged=="group" then
    local dx,dy=x-dragX,y-dragY
    if dx~=0 or dy~=0 then
      local tx,err=Group.plan(doc,symbolLibrary,selectedInstance.layer,
        doc.currentFrame,selectedInstances,"move",{dx=dx,dy=dy})
      if tx then
        if not groupDragStarted then snapshot();groupDragStarted=true end
        tx.apply()
        dragX,dragY=x,y
      elseif err~="nenhuma alteracao" then msg=tostring(err) end
    end
    return
  end
  if dragged=="instance" then
    local dx,dy=x-dragX,y-dragY
    if dx~=0 or dy~=0 then
      if not instanceDragStarted then
        if not prepareInstanceEdit() then dragged=nil;return end
        instanceDragStarted=true
      end
      local item=activeInstance()
      if item then Transform.adjust(item,dx,dy,1,0) end
      dragX,dragY=x,y
    end
    return
  end
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
  if mode=="player" then SymbolMotion.release(symbolMotion);return end
  if marquee then
    local box=marquee
    marquee=nil
    local dx,dy=box.bx-box.ax,box.by-box.ay
    if math.abs(dx)*view.scale>=4 or math.abs(dy)*view.scale>=4 then
      local found=Marquee.select(symbolLibrary,doc,box.layer,doc.currentFrame,
        box.ax,box.ay,box.bx,box.by)
      selectedInstances=Marquee.merge(selectedInstances,found,box.add)
      selectedInstance=nil
      for _,item in ipairs(Library.at(symbolLibrary,box.layer,doc.currentFrame)) do
        if selectedInstances[item.uid] then
          selectedInstance={uid=item.uid,layer=box.layer}
        end
      end
      propertyEditor=nil
      selected=nil
      msg="Area selecionada: "..selectedCount().." instancias"
    end
    dragged=nil
    return
  end
  if timelineDrag then
    local op=timelineDrag
    timelineDrag=nil
    if op.source~=op.target then
      local tx,err=TimelineOps.plan(doc,trackLibrary(),doc.currentLayer,
        op.sources,op.target-op.source,op.duplicate)
      local vectorTx,vectorErr
      if tx then
        vectorTx,vectorErr=Vector.planTransfer(vectorScope(),doc.currentLayer,
          op.sources,op.target-op.source,op.duplicate,doc.totalFrames)
      end
      if tx and vectorTx then
        snapshot()
        tx.apply()
        if vectorTx then vectorTx.apply() end
        selectedKeys={}
        for _,frame in ipairs(tx.destinations) do selectedKeys[frame]=true end
        setFrame(op.target)
        msg=op.duplicate and "Quadros e instancias duplicados" or "Quadros e instancias movidos"
      else
        msg="Operacao cancelada: "..tostring(err or vectorErr)
      end
    end
  end
  dragged=nil
  vectorDrag=nil
  instanceDragStarted=false
  groupDragStarted=false
  handleDrag=nil
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
  if propertyEditor then
    if #text<=20 and text:match("^[%d%.%+%-]+$") then
      if propertyEditor.replace then propertyEditor.draft="" end
      propertyEditor.replace=false
      if #propertyEditor.draft+#text<=24 then propertyEditor.draft=propertyEditor.draft..text end
    end
    return
  end
  if naming and #nameDraft+#text<=64 and not text:find("[^%w_%-]") then
    nameDraft=nameDraft..text
  end
end

function love.keypressed(key)
  if mode=="studio" and not naming and not propertyEditor then
    if key=="return" and tool=="pen" and penPath and not love.keyboard.isDown("lctrl","rctrl") then
      penPath=nil;vectorDrag=nil;msg="Caminho aberto finalizado";return
    end
    if key=="escape" and tool=="pen" and penPath then
      penPath=nil;vectorDrag=nil;msg="Edicao de caminho finalizada";return
    end
    if key=="p" then tool="pen";penPath=nil;msg="Caneta Bezier ativada";return end
    if key=="a" then tool="node";penPath=nil;msg="Edicao de pontos ativada";return end
    if key=="f" and selectedVector then
      local path=vectorOnFrame(selectedVector)
      if path and path.closed and editVectorFrame() then
        path=vectorOnFrame(selectedVector)
        if path.fill then path.fill=nil else path.fill=clone(palette[colorIndex]) end
        msg=path.fill and "Preenchimento ativado" or "Preenchimento removido"
        return
      end
    end
    if key=="c" and not love.keyboard.isDown("lctrl","rctrl") and selectedVector then
      local p=vectorOnFrame(selectedVector)
      if p and #p.nodes>=3 and not p.closed and editVectorFrame() then
        Vector.close(vectorOnFrame(selectedVector))
        penPath=nil
        msg="Caminho fechado"
        return
      end
    end
  end
  if propertyEditor then
    if key=="escape" then propertyEditor=nil;msg="Edicao de propriedade cancelada";return end
    if key=="backspace" then
      if propertyEditor.replace then propertyEditor.draft="" else
        propertyEditor.draft=propertyEditor.draft:sub(1,-2)
      end
      propertyEditor.replace=false
      return
    end
    if key=="return" or key=="kpenter" then
      if propertyEditor.group then
        local op,value=Group.parseProperty(propertyEditor.field,propertyEditor.draft)
        if op then
          applyGroup(op,value)
          propertyEditor=nil
        else msg="Valor relativo invalido: "..tostring(value) end
        return
      end
      local source=activeInstance()
      local result,err=source and Properties.set(source,propertyEditor.field,propertyEditor.draft)
      if result then
        if result[propertyEditor.field]~=Properties.read(source,propertyEditor.field) then
          if prepareInstanceEdit() then
            local item=activeInstance()
            if item then item[propertyEditor.field]=result[propertyEditor.field] end
          end
        end
        msg="Propriedade "..propertyEditor.field.." atualizada"
        propertyEditor=nil
      else
        msg="Valor invalido: "..tostring(err or "instancia indisponivel")
      end
      return
    end
    return
  end
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
  if key=="escape" and marquee then marquee=nil;msg="Selecao por area cancelada";return end
  local ctrl=love.keyboard.isDown("lctrl","rctrl")
  local shift=love.keyboard.isDown("lshift","rshift")
  local alt=love.keyboard.isDown("lalt","ralt")
  if key=="escape" and not editingSymbolId and mode=="studio" and selectedCount()>0 then
    selectedInstance=nil
    selectedInstances={}
    propertyEditor=nil
    msg="Selecao limpa"
    return
  end
  if mode=="studio" and not editingSymbolId and selectedCount()>1 then
    if key=="leftbracket" or key=="rightbracket" then
      applyGroup(ctrl and "scale" or "rotate",
        ctrl and (key=="leftbracket" and .9 or 1.1)
          or (key=="leftbracket" and -5 or 5))
      return
    elseif alt and (key=="left" or key=="right" or key=="up" or key=="down") then
      local step=shift and 10 or 1
      applyGroup("move",{
        dx=(key=="right" and step or 0)-(key=="left" and step or 0),
        dy=(key=="down" and step or 0)-(key=="up" and step or 0)
      })
      return
    end
  end
  if mode=="studio" and not editingSymbolId and selectedInstance then
    local dx,dy,scale,rotation=0,0,1,0
    local handled=false
    if key=="leftbracket" or key=="rightbracket" then
      if ctrl then scale=key=="leftbracket" and .9 or 1.1
      else rotation=key=="leftbracket" and -5 or 5 end
      handled=true
    elseif alt and (key=="left" or key=="right" or key=="up" or key=="down") then
      local step=shift and 10 or 1
      dx=(key=="right" and step or 0)-(key=="left" and step or 0)
      dy=(key=="down" and step or 0)-(key=="up" and step or 0)
      handled=true
    end
    if handled then
      local source=activeInstance()
      if source and doc.layers[selectedInstance.layer] and not doc.layers[selectedInstance.layer].locked then
        local candidate=Model.copy(source)
        if Transform.adjust(candidate,dx,dy,scale,rotation) then
          local target=prepareInstanceEdit()
          if target then
            target.x,target.y=candidate.x,candidate.y
            target.sx,target.sy,target.angle=candidate.sx,candidate.sy,candidate.angle
            msg="Instancia #"..target.uid.." transformada"
          end
        else msg="Limite de transformacao atingido" end
      else msg="Camada bloqueada ou instancia indisponivel" end
      return
    end
  end
  if ctrl and key=="f8" and mode=="studio" then
    if editingSymbolId then msg="Volte ao palco para criar outro simbolo";return end
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
  if ctrl and key=="f10" and mode=="studio" then
    if editingSymbolId then msg="Use F5 e F6 para editar a timeline interna";return end
    local symbol=selectedSymbol and Library.find(symbolLibrary,selectedSymbol)
    if not symbol then msg="Selecione um simbolo na biblioteca";return end
    if active().locked then msg="Camada bloqueada";return end
    local limit=symbol.kind=="button" and 4 or 10000
    if symbol.definition.totalFrames>=limit then
      msg="Limite de quadros internos do simbolo atingido";return
    end
    local shapes=Model.frame(active(),doc.currentFrame)
    snapshot()
    local frame,err=Library.appendPose(symbolLibrary,selectedSymbol,shapes)
    if frame then
      msg="Pose "..frame.." adicionada ao simbolo. Button: 1 Up, 2 Over, 3 Down, 4 Hit."
      SymbolMotion.reset(symbolMotion)
    else
      msg=tostring(err)
    end
    return
  end
  if ctrl and key=="c" and mode=="studio" then
    frameClipboard={
      shapes=clone(Model.frame(active(),doc.currentFrame)),
      instances=clone(Library.at(trackLibrary(),doc.currentLayer,doc.currentFrame)),
      vectors=clone(Vector.at(vectorScope(),doc.currentLayer,doc.currentFrame))
    }
    msg="Quadro e instancias copiados"
    return
  end
  if ctrl and key=="v" and mode=="studio" then
    if not frameClipboard then msg="Nenhum quadro copiado";return end
    local tx,err=TimelineOps.planPaste(doc,trackLibrary(),doc.currentLayer,
      doc.currentFrame,frameClipboard)
    if not tx then msg="Nao foi possivel colar: "..tostring(err);return end
    local vectorTx,vectorErr
    vectorTx,vectorErr=Vector.planPaste(vectorScope(),doc.currentLayer,
      doc.currentFrame,frameClipboard.vectors or {})
    if not vectorTx then msg="Nao foi possivel colar vetor: "..tostring(vectorErr);return end
    snapshot()
    tx.apply()
    if vectorTx then vectorTx.apply() end
    selected=nil
    msg="Quadro e instancias colados"
    return
  end
  if ctrl and (key=="return" or key=="kpenter") and mode=="studio" then
    if editingSymbolId then exitSymbol()
    elseif selectedSymbol then editSymbol(selectedSymbol)
    else msg="Selecione um simbolo na biblioteca antes de editar" end
    return
  end
  if key=="escape" and editingSymbolId then exitSymbol();return end
  if ctrl and key=="n" then newProject();return end
  if ctrl and shift and key=="s" then beginSaveAs();return end
  if ctrl and key=="s" then save();return end
  if ctrl and key=="o" then openLast();return end
  if ctrl and key=="e" then
    local svg=Model.svg(doc,doc.currentFrame)
    if not editingSymbolId then
      svg=svg:gsub("</svg>",Vector.svg(vectorScope(),doc,doc.currentFrame).."</svg>")
    end
    local ok,err=love.filesystem.write("quadro.svg",svg)
    msg=ok and "SVG exportado para pasta de dados do Lua-Flash" or tostring(err)
    return
  end
  if ctrl and key=="z" then history(true);return end
  if ctrl and key=="y" then history(false);return end
  if key=="tab" then mode=(mode=="studio") and "player" or "studio";runtime.playing=mode=="player";return end
  if key=="space" then runtime.playing=not runtime.playing;return end
  if key=="left" then runtime.playing=false;setFrame(doc.currentFrame-1);return end
  if key=="right" then runtime.playing=false;setFrame(doc.currentFrame+1);return end
  if key=="f1" then msg="TAB preview | F6 key | F9 blank | Ctrl+F8 symbol | Ctrl+F10 pose | Ctrl+S save";return end
  if mode~="studio" then return end
  if key=="pageup" then jumpKey(-1);return end
  if key=="pagedown" then jumpKey(1);return end
  if key=="home" then runtime.playing=false;setFrame(1);return end
  if key=="end" then runtime.playing=false;setFrame(doc.totalFrames);return end
  if key=="f5" and editingSymbolId then
    local symbol=Library.find(symbolLibrary,editingSymbolId)
    local limit=symbol and symbol.kind=="button" and 4 or 10000
    if doc.totalFrames>=limit then msg="Limite de quadros internos atingido";return end
    snapshot()
    doc.totalFrames=doc.totalFrames+1
    runtime.playing=false
    setFrame(doc.totalFrames)
    msg="Timeline do simbolo estendida para "..doc.totalFrames.." quadros"
    return
  end
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
    Vector.ensureKey(vectorScope(),doc.currentLayer,doc.currentFrame,true)
    Library.ensureKey(trackLibrary(),doc.currentLayer,doc.currentFrame,true)
    selected=nil
    msg="Quadro-chave vazio inserido"
    return
  end
  if key=="f6" then
    if active().locked then msg="Camada bloqueada";return end
    snapshot()
    if shift then
      Model.removeKey(active(),doc.currentFrame)
      Library.removeKey(trackLibrary(),doc.currentLayer,doc.currentFrame)
      Vector.removeKey(vectorScope(),doc.currentLayer,doc.currentFrame)
    else
      Model.ensureKey(active(),doc.currentFrame)
      Library.ensureKey(trackLibrary(),doc.currentLayer,doc.currentFrame)
      Vector.ensureKey(vectorScope(),doc.currentLayer,doc.currentFrame)
    end
    selected=nil
    return
  end
  if mode=="studio" and tool=="node"
      and (key=="-" or key=="kp-" or key=="=" or key=="+" or key=="kp+")
      and selectedVector then
    local path=vectorOnFrame(selectedVector)
    if path then
      local delta=(key=="-" or key=="kp-") and -1 or 1
      local nextWidth=math.max(.1,math.min(200,path.width+delta))
      if math.abs(nextWidth-path.width)>1e-6 and editVectorFrame() then
        vectorOnFrame(selectedVector).width=nextWidth
        msg="Contorno vetorial: "..nextWidth
      end
      return
    end
  end
  if key=="v" then tool="select";penPath=nil
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
