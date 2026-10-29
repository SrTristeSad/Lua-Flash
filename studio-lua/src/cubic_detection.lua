-- Detect transverse intersections using original cubic control hulls, not
-- tessellated polygon chords. Hierarchical De Casteljau subdivision gives
-- conservative bounding boxes; only converged Newton roots are returned.
-- The bounded work budget rejects pathological near-overlaps safely.
local Solver=require("src.cubic_intersections")
local M={}
local function finite(v)
  return type(v)=="number" and v==v and math.abs(v)<math.huge
end
local function midpoint(a,b)
  return {x=(a.x+b.x)*.5,y=(a.y+b.y)*.5}
end
local function controls(nodes,i)
  local n=nodes[i]
  local b=nodes[i%#nodes+1]
  return {{x=n.x,y=n.y},{x=n.ox,y=n.oy},
    {x=b.ix,y=b.iy},{x=b.x,y=b.y}}
end
local function hull(p)
  local x1,y1,x2,y2=p[1].x,p[1].y,p[1].x,p[1].y
  for i=2,4 do
    local n=p[i]
    x1=math.min(x1,n.x)
    y1=math.min(y1,n.y)
    x2=math.max(x2,n.x)
    y2=math.max(y2,n.y)
  end
  return x1,y1,x2,y2,math.max(x2-x1,y2-y1)
end
local function overlap(a,b)
  local ax,ay,bx,by=hull(a)
  local cx,cy,dx,dy=hull(b)
  return ax<=dx+1e-8 and cx<=bx+1e-8 and
    ay<=dy+1e-8 and cy<=by+1e-8
end
local function halves(p)
  local a=midpoint(p[1],p[2])
  local b=midpoint(p[2],p[3])
  local c=midpoint(p[3],p[4])
  local d=midpoint(a,b)
  local e=midpoint(b,c)
  local f=midpoint(d,e)
  return {p[1],a,d,f},{f,e,c,p[4]}
end
local function findPair(aNodes,ai,bNodes,bi,options)
  local maxVisits=options.maxVisits or 10000
  local maxDepth=options.maxDepth or 30
  local budget=options.budget
  local aCurve=controls(aNodes,ai)
  local bCurve=controls(bNodes,bi)
  if not overlap(aCurve,bCurve) then return {} end
  local stack={{a=aCurve,b=bCurve,a0=0,a1=1,b0=0,b1=1,depth=0}}
  local hits={}
  while #stack>0 do
    local node=table.remove(stack)
    budget.count=budget.count+1
    if budget.count>maxVisits then return nil,"limite da busca cubica" end
    if overlap(node.a,node.b) then
      local aw,ah,al=hull(node.a)
      local bw,bh,bl=hull(node.b)
      local splitA=(node.a1-node.a0)*al
      local splitB=(node.b1-node.b0)*bl
      -- Subdivide until both parameter intervals are narrow enough for
      -- Newton's local convergence, even for a nearly degenerate control hull.
      local leaf=(node.a1-node.a0)<=1/1024 and
        (node.b1-node.b0)<=1/1024
      if leaf or node.depth>=maxDepth then
        local am={nodes=aNodes,segment=ai,t0=node.a0,t1=node.a1}
        local bm={nodes=bNodes,segment=bi,t0=node.b0,t1=node.b1}
        local root=Solver.refine(am,bm,.5,.5)
        if root and root.aT>=-1e-8 and root.aT<=1+1e-8
            and root.bT>=-1e-8 and root.bT<=1+1e-8 then
          local repeated=false
          for _,found in ipairs(hits) do
            if math.abs(found.aT-root.aT)<1e-5 and
                math.abs(found.bT-root.bT)<1e-5 then
              repeated=true;break
            end
          end
          if not repeated then
            hits[#hits+1]={aSegment=ai,bSegment=bi,
              aT=root.aT,bT=root.bT,point=root.point,
              residual=root.residual}
          end
        end
      elseif splitA>=splitB then
        local left,right=halves(node.a)
        local t=(node.a0+node.a1)*.5
        stack[#stack+1]={a=right,b=node.b,
          a0=t,a1=node.a1,b0=node.b0,b1=node.b1,depth=node.depth+1}
        stack[#stack+1]={a=left,b=node.b,
          a0=node.a0,a1=t,b0=node.b0,b1=node.b1,depth=node.depth+1}
      else
        local left,right=halves(node.b)
        local t=(node.b0+node.b1)*.5
        stack[#stack+1]={a=node.a,b=right,
          a0=node.a0,a1=node.a1,b0=t,b1=node.b1,depth=node.depth+1}
        stack[#stack+1]={a=node.a,b=left,
          a0=node.a0,a1=node.a1,b0=node.b0,b1=t,depth=node.depth+1}
      end
    end
  end
  return hits
end
function M.detect(aNodes,bNodes,options)
  options=options or {}
  if type(aNodes)~="table" or type(bNodes)~="table"
      or #aNodes<2 or #bNodes<2
      or #aNodes>256 or #bNodes>256 then
    return nil,"curvas de entrada invalidas"
  end
  local budget={count=0}
  local all={}
  for i=1,#aNodes do
    for j=1,#bNodes do
      local a,b=controls(aNodes,i),controls(bNodes,j)
      for _,p in ipairs({a[1],a[2],a[3],a[4],b[1],b[2],b[3],b[4]}) do
        if not finite(p.x) or not finite(p.y) or
            math.abs(p.x)>100000 or math.abs(p.y)>100000 then
          return nil,"controle cubico invalido"
        end
      end
      if overlap(a,b) then
        local roots,err=findPair(aNodes,i,bNodes,j,{
          budget=budget,maxVisits=options.maxVisits or 10000,
          maxDepth=options.maxDepth or 30
        })
        if not roots then return nil,err end
        for _,root in ipairs(roots) do
          local duplicate=false
          for _,hit in ipairs(all) do
            local dx=root.point.x-hit.point.x
            local dy=root.point.y-hit.point.y
            if dx*dx+dy*dy<1e-10 then duplicate=true;break end
          end
          if not duplicate then all[#all+1]=root end
          if #all>500 then return nil,"intersecoes demais" end
        end
      end
    end
  end
  table.sort(all,function(a,b)
    if a.aSegment==b.aSegment then return a.aT<b.aT end
    return a.aSegment<b.aSegment
  end)
  return all
end
return M
