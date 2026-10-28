-- Studio-only area booleans on CLOSED filled Bézier outlines.
-- Curves are flattened to a bounded polygonal approximation (not exact cubic
-- boolean topology); ambiguous touching edges, holes and oversized contours
-- are rejected rather than producing misleading shapes.
local Vector=require("src.vector_paths")
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
  if #path.nodes>48 then return nil,"forma muito complexa (48 nos no maximo)" end
  local sampled=Vector.sample(path,8)
  local points={}
  for i=1,#sampled,2 do
    points[#points+1]={x=sampled[i],y=sampled[i+1]}
  end
  local poly=clean(points)
  if not poly or #poly>384 then return nil,"contorno invalido ou complexo" end
  return poly
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
local function selectedEdges(poly,other,ts,operation,fromB)
  local out={}
  for i,a in ipairs(poly) do
    local b=poly[i%#poly+1]
    local values=uniqueSorted(ts[i])
    for j=1,#values-1 do
      local t0,t1=values[j],values[j+1]
      if t1-t0>EPS then
        local midpoint=point(a,b,(t0+t1)/2)
        local isInside=inside(other,midpoint)
        if isInside==nil then return nil,"boundary classification ambiguous" end
        local keep
        if operation=="union" then keep=not isInside
        elseif operation=="intersection" then keep=isInside
        elseif operation=="difference" then
          if fromB then keep=isInside else keep=not isInside end
        end
        if keep then
          local p=point(a,b,t0)
          local q=point(a,b,t1)
          if fromB and operation=="difference" then p,q=q,p end
          out[#out+1]={a=p,b=q}
        end
      end
    end
  end
  return out
end
local function contours(edges)
  local starts,ends={}
  for i,e in ipairs(edges) do
    local ka,kb=key(e.a),key(e.b)
    if ka==kb or starts[ka] then return nil,"ambiguous output topology" end
    starts[ka]=i
    ends[kb]=(ends[kb] or 0)+1
  end
  for ka in pairs(starts) do if ends[ka]~=1 then return nil,"open boolean boundary" end end
  local loops,visited={},{}
  for i=1,#edges do
    if not visited[i] then
      local firstKey=key(edges[i].a)
      local current=i
      local ring={}
      for _=1,#edges+1 do
        if visited[current] then return nil,"repeated contour edge" end
        visited[current]=true
        local e=edges[current]
        ring[#ring+1]=e.a
        local nextKey=key(e.b)
        if nextKey==firstKey then break end
        current=starts[nextKey]
        if not current then return nil,"unclosed boolean result" end
      end
      local polygon=clean(ring)
      if not polygon then return nil,"degenerate boolean region" end
      -- A negative original winding is a hole; current Studio format has no
      -- compound paths, so a hole would be rendered as filled. Reject it.
      if area(ring)<-1e-4 then return nil,"result has a hole (not yet supported)" end
      if #polygon>256 then return nil,"output exceeds 256 anchors" end
      loops[#loops+1]=polygon
    end
  end
  return loops
end
local function calculate(a,b,operation)
  local ca,err=flatten(a)
  if not ca then return nil,err end
  local cb,err2=flatten(b)
  if not cb then return nil,err2 end
  if not simple(ca) or not simple(cb) then return nil,"self-intersecting paths unsupported" end
  local ta,tb=cuts(ca),cuts(cb)
  local crossing=0
  for i,aa in ipairs(ca) do
    local ab=ca[i%#ca+1]
    for j,ba in ipairs(cb) do
      local bb=cb[j%#cb+1]
      local t,u,issue=segmentIntersection(aa,ab,ba,bb)
      if issue then return nil,issue end
      if t then
        ta[i][#ta[i]+1]=t
        tb[j][#tb[j]+1]=u
        crossing=crossing+1
      end
    end
  end
  if crossing>500 then return nil,"too many intersections" end
  local fromA,err3=selectedEdges(ca,cb,ta,operation,false)
  if not fromA then return nil,err3 end
  local fromB,err4=selectedEdges(cb,ca,tb,operation,true)
  if not fromB then return nil,err4 end
  for _,e in ipairs(fromB) do fromA[#fromA+1]=e end
  if #fromA==0 then return nil,"empty result" end
  local rings,err5=contours(fromA)
  if not rings then return nil,err5 end
  return rings
end
local function pathFromPolygon(points,source,id)
  local p={id=id,closed=true,stroke=copy(source.stroke),
    width=source.width,fill=copy(source.fill),nodes={}}
  for _,q in ipairs(points) do
    p.nodes[#p.nodes+1]={x=q.x,y=q.y,ix=q.x,iy=q.y,ox=q.x,oy=q.y}
  end
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
