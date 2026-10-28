-- Studio-only area booleans on CLOSED filled Bézier outlines.
-- Curves are flattened to a bounded polygonal approximation (not exact cubic
-- boolean topology); touching edges, self-crossings and excessive contour
-- complexity are rejected instead of producing incorrect fills.
local Vector=require("src.vector_paths")
local Flatten=require("src.bezier_flatten")
local Retention=require("src.bezier_retention")
local CubicIntersections=require("src.cubic_intersections")
local M={}
local EPS=1e-7
local SNAP=1e-5
local function finite(x) return type(x)=="number" and x==x and math.abs(x)<math.huge end
local function copy(t)
  if type(t)~="table" then return t end
  local r={}
  for k,v in pairs(t) do r[k]=copy(v) end
  return r
end
local function cross(ax,ay,bx,by) return ax*by-ay*bx end
local function area(p)
  local s=0
  for i,a in ipairs(p) do
    local b=p[i%#p+1]
    s=s+a.x*b.y-b.x*a.y
  end
  return s/2
end
local function near(a,b) return math.abs(a.x-b.x)<SNAP and math.abs(a.y-b.y)<SNAP end
local function dist2(a,b) return (a.x-b.x)^2+(a.y-b.y)^2 end
local function clean(points)
  local result={}
  for _,p in ipairs(points) do
    if not finite(p.x) or not finite(p.y) or
        math.abs(p.x)>100000 or math.abs(p.y)>100000 then return nil end
    if #result==0 or dist2(result[#result],p)>SNAP*SNAP then
      result[#result+1]={x=p.x,y=p.y}
    end
  end
  if #result>=2 and near(result[1],result[#result]) then table.remove(result) end
  local changed=true
  while changed and #result>3 do
    changed=false
    for i=1,#result do
      local a=result[(i-2)%#result+1]
      local b=result[i]
      local c=result[i%#result+1]
      local abx,aby=b.x-a.x,b.y-a.y
      local bcx,bcy=c.x-b.x,c.y-b.y
      local length=math.sqrt(abx*abx+aby*aby)+math.sqrt(bcx*bcx+bcy*bcy)
      if length>EPS and math.abs(cross(abx,aby,bcx,bcy))/length<1e-6
          and abx*bcx+aby*bcy>=0 then
        table.remove(result,i)
        changed=true
        break
      end
    end
  end
  if #result<3 or math.abs(area(result))<1e-5 then return nil end
  if area(result)<0 then
    local flipped={}
    for i=#result,1,-1 do flipped[#flipped+1]=result[i] end
    result=flipped
  end
  return result
end
local function flatten(path)
  if not path or not path.closed or not path.fill or #path.nodes<3 then
    return nil,"duas formas fechadas e preenchidas sao necessarias"
  end
  if #(path.holes or {})>16 then return nil,"limite de 16 furos" end
  local region={rings={},holes={},lookups={}}
  local total=0
  local function ringFor(nodes)
    if #nodes<3 or #nodes>48 then
      return nil,"contorno deve ter entre 3 e 48 nos"
    end
    local points,edgesOrError=Flatten.ringWithEdges(nodes,
      {tolerance=.25,maxPoints=385})
    if not points then return nil,edgesOrError end
    local poly=clean(points)
    if not poly or #poly>384 then return nil,"contorno invalido ou complexo" end
    total=total+#poly
    if total>512 then return nil,"limite de 512 vertices por forma" end
    return poly,Retention.lookup(points,edgesOrError,nodes)
  end
  local outer,outerLookup=ringFor(path.nodes)
  if not outer then return nil,outerLookup end
  region.outer=outer
  region.rings[#region.rings+1]=outer
  region.lookups[#region.lookups+1]=outerLookup
  region.sources={{polygon=outer,nodes=path.nodes}}
  for _,nodes in ipairs(path.holes or {}) do
    local hole,holeLookup=ringFor(nodes)
    if not hole then return nil,holeLookup end
    region.holes[#region.holes+1]=hole
    region.sources[#region.sources+1]={polygon=hole,nodes=nodes}
    -- Edges must follow the boundary of the filled set, so hole rings run
    -- clockwise while outer rings run counterclockwise.
    local reversed={}
    for i=#hole,1,-1 do reversed[#reversed+1]=hole[i] end
    region.rings[#region.rings+1]=reversed
    region.lookups[#region.lookups+1]=holeLookup
  end
  return region
end
local function pointOnSegment(p,a,b)
  local dx,dy=b.x-a.x,b.y-a.y
  local apx,apy=p.x-a.x,p.y-a.y
  local d2=dx*dx+dy*dy
  if d2<EPS*EPS then return dist2(p,a)<SNAP*SNAP end
  local t=(apx*dx+apy*dy)/d2
  return t>=-EPS and t<=1+EPS
      and math.abs(cross(dx,dy,apx,apy))/math.sqrt(d2)<SNAP
end
local function inside(poly,p)
  local result=false
  for i,a in ipairs(poly) do
    local b=poly[i%#poly+1]
    if pointOnSegment(p,a,b) then return nil end
    if (a.y>p.y)~=(b.y>p.y)
        and p.x<(b.x-a.x)*(p.y-a.y)/(b.y-a.y)+a.x then
      result=not result
    end
  end
  return result
end
local function segmentIntersection(a,b,c,d)
  local rx,ry=b.x-a.x,b.y-a.y
  local sx,sy=d.x-c.x,d.y-c.y
  local denominator=cross(rx,ry,sx,sy)
  local qx,qy=c.x-a.x,c.y-a.y
  if math.abs(denominator)<EPS then
    if math.abs(cross(qx,qy,rx,ry))<EPS then
      local rr=rx*rx+ry*ry
      if rr<EPS then return nil,nil,"degenerate edge" end
      local t0=(qx*rx+qy*ry)/rr
      local t1=((d.x-a.x)*rx+(d.y-a.y)*ry)/rr
      if math.min(1,math.max(t0,t1))-math.max(0,math.min(t0,t1))>EPS then
        return nil,nil,"coincident edges are not supported"
      end
      if math.min(1,math.max(t0,t1))>=math.max(0,math.min(t0,t1))-EPS then
        return nil,nil,"touching boundaries are not supported"
      end
    end
    return nil
  end
  local t=cross(qx,qy,sx,sy)/denominator
  local u=cross(qx,qy,rx,ry)/denominator
  if t>=-EPS and t<=1+EPS and u>=-EPS and u<=1+EPS then
    if t<=EPS or t>=1-EPS or u<=EPS or u>=1-EPS then
      return nil,nil,"touching vertices are not supported"
    end
    return t,u
  end
  return nil
end
local function simple(poly)
  for i=1,#poly do
    local a,b=poly[i],poly[i%#poly+1]
    for j=i+1,#poly do
      if j~=i+1 and not (i==1 and j==#poly) then
        local c,d=poly[j],poly[j%#poly+1]
        local t,u,err=segmentIntersection(a,b,c,d)
        if t or err then return false end
      end
    end
  end
  return true
end
local function ringsIntersect(a,b)
  for i,p in ipairs(a) do
    local q=a[i%#a+1]
    for j,r in ipairs(b) do
      local t=b[j%#b+1]
      local u,v,issue=segmentIntersection(p,q,r,t)
      if u or issue then return true end
    end
  end
  return false
end
local function validateRegion(region)
  for _,ring in ipairs(region.rings) do
    if not simple(ring) then return nil,"contorno autointersectante" end
  end
  for i,hole in ipairs(region.holes) do
    if ringsIntersect(region.outer,hole) then return nil,"furo cruza a borda externa" end
    if inside(region.outer,hole[1])~=true then return nil,"furo fora da forma" end
    for j=1,i-1 do
      local other=region.holes[j]
      if ringsIntersect(hole,other) then return nil,"furos sobrepostos" end
      if inside(hole,other[1])~=false or inside(other,hole[1])~=false then
        return nil,"furos aninhados ou sobrepostos"
      end
    end
  end
  return true
end
local function regionInside(region,point)
  local included=inside(region.outer,point)
  if included~=true then return included end
  for _,hole in ipairs(region.holes) do
    local contained=inside(hole,point)
    if contained==nil then return nil end
    if contained then return false end
  end
  return true
end
local function cuts(poly)
  local out={}
  for i=1,#poly do out[i]={0,1} end
  return out
end
local function uniqueSorted(ts)
  table.sort(ts)
  local out={}
  for _,t in ipairs(ts) do
    if #out==0 or t-out[#out]>EPS then out[#out+1]=t end
  end
  return out
end
local function point(a,b,t)
  return {x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t}
end
local function key(p)
  return math.floor(p.x/SNAP+0.5)..":"..math.floor(p.y/SNAP+0.5)
end
local function selectedEdges(poly,other,ts,operation,fromB,lookup)
  local out={}
  for i,a in ipairs(poly) do
    local b=poly[i%#poly+1]
    local values=uniqueSorted(ts[i])
    local original=Retention.get(lookup,a,b)
    local function endpoint(t)
      if t<=EPS then return point(a,b,0),original and original.t0 end
      if t>=1-EPS then return point(a,b,1),original and original.t1 end
      -- Both operands refer to the SAME refined intersection point. The
      -- parameter belongs to the original cubic, not the chord fraction.
      for _,hit in ipairs(ts[i].hits or {}) do
        if math.abs(hit.chordT-t)<EPS then
          return hit.at,hit.cubicT
        end
      end
      local param=original and
        original.t0+(original.t1-original.t0)*t or nil
      return point(a,b,t),param
    end
    for j=1,#values-1 do
      local t0,t1=values[j],values[j+1]
      if t1-t0>EPS then
        local midpoint=point(a,b,(t0+t1)/2)
        local isInside=regionInside(other,midpoint)
        if isInside==nil then return nil,"boundary classification ambiguous" end
        local keep
        if operation=="union" then keep=not isInside
        elseif operation=="intersection" then keep=isInside
        elseif operation=="difference" then
          if fromB then keep=isInside else keep=not isInside end
        end
        if keep then
          local p,pt0=endpoint(t0)
          local q,pt1=endpoint(t1)
          local meta
          if original then
            meta={nodes=original.nodes,segment=original.segment,
              t0=pt0,t1=pt1}
          end
          if fromB and operation=="difference" then
            p,q=q,p
            if meta then meta.t0,meta.t1=meta.t1,meta.t0 end
          end
          out[#out+1]={a=p,b=q,meta=meta}
        end
      end
    end
  end
  return out
end
local function contours(edges)
  local starts,ends={},{}
  for i,e in ipairs(edges) do
    local ka,kb=key(e.a),key(e.b)
    if ka==kb or starts[ka] then return nil,"ambiguous output topology" end
    starts[ka]=i
    ends[kb]=(ends[kb] or 0)+1
  end
  for ka in pairs(starts) do if ends[ka]~=1 then return nil,"open boolean boundary" end end
  local outers,holes,visited={},{},{}
  for i=1,#edges do
    if not visited[i] then
      local firstKey=key(edges[i].a)
      local current=i
      local ring={}
      local ringEdges={}
      local closed=false
      for _=1,#edges+1 do
        if visited[current] then return nil,"repeated contour edge" end
        visited[current]=true
        local e=edges[current]
        ring[#ring+1]=e.a
        ringEdges[#ringEdges+1]=e
        local nextKey=key(e.b)
        if nextKey==firstKey then closed=true;break end
        current=starts[nextKey]
        if not current then return nil,"unclosed boolean result" end
      end
      if not closed then return nil,"unclosed boolean loop" end
      local winding=area(ring)
      local polygon=clean(ring)
      if not polygon then return nil,"degenerate boolean region" end
      if #polygon>256 then return nil,"output exceeds 256 anchors" end
      if winding<0 then
        holes[#holes+1]={points=polygon,edges=ringEdges}
      else
        outers[#outers+1]={outer=polygon,outerEdges=ringEdges,
          holes={},holeEdges={}}
      end
    end
  end
  -- Assign each negative contour to its smallest enclosing positive contour.
  -- Containment uses actual geometry, not bounding-box proximity.
  for _,hole in ipairs(holes) do
    local container,minArea=nil,nil
    for _,outer in ipairs(outers) do
      local within=inside(outer.outer,hole.points[1])
      if within==nil then return nil,"hole touches outer contour" end
      if within then
        local size=math.abs(area(outer.outer))
        if not minArea or size<minArea then container,minArea=outer,size end
      end
    end
    if not container then return nil,"orphan hole contour" end
    if #container.holes>=16 then return nil,"more than 16 holes" end
    container.holes[#container.holes+1]=hole.points
    container.holeEdges[#container.holeEdges+1]=hole.edges
  end
  if #outers==0 then return nil,"no filled outer contour" end
  return outers
end
-- When an entire source ring survives a Boolean unchanged, retain its
-- ORIGINAL cubic nodes. Only boundaries that the operation actually cuts are
-- linearized. This also preserves curved holes and disconnected islands.
local function sameRing(a,b)
  if #a~=#b or #a==0 then return false end
  local function equal(p,q)
    return math.abs(p.x-q.x)<=1e-5 and math.abs(p.y-q.y)<=1e-5
  end
  for offset=1,#b do
    if equal(a[1],b[offset]) then
      for _,direction in ipairs({1,-1}) do
        local matched=true
        for i=1,#a do
          local index=(offset-1+(i-1)*direction)%#b+1
          if not equal(a[i],b[index]) then matched=false;break end
        end
        if matched then return true end
      end
    end
  end
  return false
end
local function originalRing(polygon,regions)
  for _,region in ipairs(regions) do
    for _,source in ipairs(region.sources) do
      if sameRing(polygon,source.polygon) then
        return copy(source.nodes)
      end
    end
  end
  return nil
end

local function calculate(a,b,operation)
  local ca,err=flatten(a)
  if not ca then return nil,err end
  local cb,err2=flatten(b)
  if not cb then return nil,err2 end
  local validA,errorA=validateRegion(ca)
  if not validA then return nil,errorA end
  local validB,errorB=validateRegion(cb)
  if not validB then return nil,errorB end
  local ta,tb={},{}
  for i,ring in ipairs(ca.rings) do ta[i]=cuts(ring) end
  for i,ring in ipairs(cb.rings) do tb[i]=cuts(ring) end
  local crossing=0
  for ri,ringA in ipairs(ca.rings) do
    for i,a in ipairs(ringA) do
      local nextA=ringA[i%#ringA+1]
      for rj,ringB in ipairs(cb.rings) do
        for j,b in ipairs(ringB) do
          local nextB=ringB[j%#ringB+1]
          local t,u,issue=segmentIntersection(a,nextA,b,nextB)
          if issue then return nil,issue end
          if t then
            local sourceA=Retention.get(ca.lookups[ri],a,nextA)
            local sourceB=Retention.get(cb.lookups[rj],b,nextB)
            local refined=sourceA and sourceB and
              CubicIntersections.refine(sourceA,sourceB,t,u)
            if refined then
              local ah=ta[ri][i]
              local bh=tb[rj][j]
              ah.hits=ah.hits or {}
              bh.hits=bh.hits or {}
              ah.hits[#ah.hits+1]={chordT=t,at=refined.point,
                cubicT=refined.aT}
              bh.hits[#bh.hits+1]={chordT=u,at=refined.point,
                cubicT=refined.bT}
            end
            ta[ri][i][#ta[ri][i]+1]=t
            tb[rj][j][#tb[rj][j]+1]=u
            crossing=crossing+1
          end
        end
      end
    end
  end
  if crossing>500 then return nil,"too many intersections" end
  local result={}
  for i,ring in ipairs(ca.rings) do
    local edges,err=selectedEdges(ring,cb,ta[i],operation,false,ca.lookups[i])
    if not edges then return nil,err end
    for _,e in ipairs(edges) do result[#result+1]=e end
  end
  for i,ring in ipairs(cb.rings) do
    local edges,err=selectedEdges(ring,ca,tb[i],operation,true,cb.lookups[i])
    if not edges then return nil,err end
    for _,e in ipairs(edges) do result[#result+1]=e end
  end
  if #result==0 then return nil,"empty result" end
  local shapes,err=contours(result)
  if not shapes then return nil,err end
  for _,shape in ipairs(shapes) do
    shape.outerNodes=originalRing(shape.outer,{ca,cb})
    if not shape.outerNodes then
      shape.outerNodes=Retention.fromEdges(shape.outerEdges,256)
    end
    shape.holeNodes={}
    for i,hole in ipairs(shape.holes) do
      shape.holeNodes[i]=originalRing(hole,{ca,cb})
      if not shape.holeNodes[i] then
        shape.holeNodes[i]=Retention.fromEdges(shape.holeEdges[i],256)
      end
    end
  end
  return shapes
end
local function pathFromPolygon(shape,source,id)
  local p={id=id,closed=true,stroke=copy(source.stroke),
    width=source.width,fill=copy(source.fill),nodes={},holes={}}
  local function nodesFor(points)
    local output={}
    for _,q in ipairs(points) do
      output[#output+1]={x=q.x,y=q.y,ix=q.x,iy=q.y,ox=q.x,oy=q.y}
    end
    return output
  end
  p.nodes=shape.outerNodes or nodesFor(shape.outer)
  for i,hole in ipairs(shape.holes) do
    p.holes[#p.holes+1]=(shape.holeNodes and shape.holeNodes[i]) or nodesFor(hole)
  end
  if #p.holes==0 then p.holes=nil end
  return p
end
function M.plan(scope,layer,frame,firstId,secondId,operation)
  if operation~="union" and operation~="intersection" and operation~="difference"
      or firstId==secondId or not scope then return nil,"invalid operation" end
  local items=Vector.at(scope,layer,frame)
  local a,b
  for _,path in ipairs(items) do
    if path.id==firstId then a=path end
    if path.id==secondId then b=path end
  end
  if not a or not b then return nil,"select two filled paths on the same frame" end
  local rings,err=calculate(a,b,operation)
  if not rings then return nil,err end
  if #items-2+#rings>500 then return nil,"path count limit" end
  if not finite(scope.nextId) or scope.nextId+#rings-2>10000000 then
    return nil,"path ID limit"
  end
  local paths={}
  for i,ring in ipairs(rings) do
    local id=i==1 and firstId or scope.nextId+i-2
    paths[i]=pathFromPolygon(ring,a,id)
  end
  return {resultCount=#paths,ids=(function()
    local out={}
    for _,p in ipairs(paths) do out[#out+1]=p.id end
    return out
  end)(),apply=function()
    local target=Vector.ensureKey(scope,layer,frame)
    local replaced={}
    local foundFirst,foundSecond=false,false
    for _,item in ipairs(target) do
      if item.id==firstId then foundFirst=true
      elseif item.id==secondId then foundSecond=true
      else replaced[#replaced+1]=item end
    end
    if not foundFirst or not foundSecond then error("boolean source changed") end
    for _,p in ipairs(paths) do replaced[#replaced+1]=p end
    scope.tracks[layer][frame]=replaced
    scope.nextId=scope.nextId+#paths-1
  end}
end
return M
