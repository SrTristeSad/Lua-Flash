-- LÖVE rendering for Studio-only vector paths. Nothing is added to Player.
local Paths=require("src.vector_paths")
local M={}
local function paintPath(lg,path)
  local pts=Paths.sample(path,12)
  if #pts<4 then return end
  if path.closed and path.fill and #pts>=8 then
    local polygon={}
    -- Closing segment already returns to initial vertex; strip duplicate.
    for i=1,#pts-2 do polygon[#polygon+1]=pts[i] end
    if #polygon>=6 and love.math and love.math.triangulate then
      local ok,tris=pcall(love.math.triangulate,polygon)
      if ok and tris then
        local hasHoles=path.holes and #path.holes>0
        -- The outer fill is clipped using a stencil. Holes must stay
        -- transparent; never fall back to incorrectly filling them.
        if not hasHoles or (lg.stencil and lg.setStencilTest) then
          if hasHoles then
            lg.stencil(function()
              lg.polygon("fill",polygon)
            end,"replace",1,false)
            lg.stencil(function()
              for _,nodes in ipairs(path.holes) do
                local pts=Paths.sampleHole(nodes,12)
                local ring={}
                for i=1,#pts-2 do ring[#ring+1]=pts[i] end
                if #ring>=6 then
                  local good,holes=pcall(love.math.triangulate,ring)
                  if good and holes then
                    for _,tri in ipairs(holes) do lg.polygon("fill",tri) end
                  end
                end
              end
            end,"replace",0,true)
            lg.setStencilTest("equal",1)
          end
          lg.setColor(path.fill)
          for _,triangle in ipairs(tris) do lg.polygon("fill",triangle) end
          if hasHoles then lg.setStencilTest() end
        end
      end
    end
  end
  lg.setColor(path.stroke)
  lg.setLineWidth(path.width)
  lg.line(pts)
  for _,hole in ipairs(path.holes or {}) do
    local ring=Paths.sampleHole(hole,12)
    if #ring>=4 then lg.line(ring) end
  end
end
local function handles(lg,path,zoom)
  local nodeSize=math.max(2,5/zoom)
  lg.setLineWidth(math.max(.5,1/zoom))
  for _,node in ipairs(path.nodes) do
    lg.setColor(.16,.52,.9,.8)
    lg.line(node.ix,node.iy,node.x,node.y,node.ox,node.oy)
    lg.setColor(1,.70,.22)
    lg.circle("fill",node.ix,node.iy,nodeSize*.72)
    lg.circle("fill",node.ox,node.oy,nodeSize*.72)
    lg.setColor(.12,.78,1)
    lg.circle("fill",node.x,node.y,nodeSize)
    lg.setColor(.05,.16,.27)
    lg.circle("line",node.x,node.y,nodeSize)
  end
end
M.paintPath=paintPath

function M.draw(v,doc,frame,view,selectedId)
  local lg=love.graphics
  lg.push("all")
  lg.setScissor(view.x,view.y,view.w,view.h)
  lg.translate(view.ox,view.oy)
  lg.scale(view.scale)
  for layerIndex,layer in ipairs(doc.layers) do
    if layer.visible then
      for _,path in ipairs(Paths.at(v,layerIndex,frame)) do
        paintPath(lg,path)
      end
    end
  end
  if selectedId then
    local layer=doc.layers[doc.currentLayer]
    if layer and layer.visible then
      for _,path in ipairs(Paths.at(v,doc.currentLayer,frame)) do
        if path.id==selectedId then handles(lg,path,view.scale);break end
      end
    end
  end
  lg.pop()
end
return M
