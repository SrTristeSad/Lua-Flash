-- Numeric refinement of intersections between two ORIGINAL cubic Bezier arcs.
-- Polygon chords discover crossing topology; safeguarded Newton iteration
-- refines the corresponding cubic parameters without changing that topology.
-- Returns nil if convergence is ambiguous; callers must retain their safe
-- polygonal fallback in that case.
local M={}
local function finite(x)
  return type(x)=="number" and x==x and x~=math.huge and x~=-math.huge
end
local function point(x,y) return {x=x,y=y} end
local function lerp(a,b,t) return a+(b-a)*t end
local function segment(meta)
  if type(meta)~="table" or type(meta.nodes)~="table"
      or type(meta.segment)~="number" or meta.segment%1~=0
      or type(meta.t0)~="number" or type(meta.t1)~="number" then return nil end
  local count=#meta.nodes
  if count<2 or meta.segment<1 or meta.segment>count then return nil end
  local a,b=meta.nodes[meta.segment],meta.nodes[meta.segment%count+1]
  if not a or not b then return nil end
  local p={{a.x,a.y},{a.ox,a.oy},{b.ix,b.iy},{b.x,b.y}}
  for _,v in ipairs(p) do
    if not finite(v[1]) or not finite(v[2]) then return nil end
  end
  if not finite(meta.t0) or not finite(meta.t1)
      or meta.t0<0 or meta.t0>1 or meta.t1<0 or meta.t1>1 then return nil end
  return p
end
local function evaluate(p,t)
  local u=1-t
  local x=u*u*u*p[1][1]+3*u*u*t*p[2][1]+3*u*t*t*p[3][1]+t*t*t*p[4][1]
  local y=u*u*u*p[1][2]+3*u*u*t*p[2][2]+3*u*t*t*p[3][2]+t*t*t*p[4][2]
  local dx=3*(u*u*(p[2][1]-p[1][1])
    +2*u*t*(p[3][1]-p[2][1])+t*t*(p[4][1]-p[3][1]))
  local dy=3*(u*u*(p[2][2]-p[1][2])
    +2*u*t*(p[3][2]-p[2][2])+t*t*(p[4][2]-p[3][2]))
  return x,y,dx,dy
end
function M.evaluate(meta,t)
  local p=segment(meta)
  if not p or not finite(t) or t<0 or t>1 then return nil end
  local x,y,dx,dy=evaluate(p,t)
  return point(x,y),point(dx,dy)
end
function M.refine(aMeta,bMeta,aFraction,bFraction)
  local pa,pb=segment(aMeta),segment(bMeta)
  if not pa or not pb or not finite(aFraction) or not finite(bFraction)
      or aFraction<0 or aFraction>1 or bFraction<0 or bFraction>1 then
    return nil,"parametros invalidos"
  end
  local t=lerp(aMeta.t0,aMeta.t1,aFraction)
  local u=lerp(bMeta.t0,bMeta.t1,bFraction)
  -- Allow a modest movement outside the original tessellated edge when a
  -- chord crossing is offset from its actual arc crossing.
  local spanA=math.abs(aMeta.t1-aMeta.t0)
  local spanB=math.abs(bMeta.t1-bMeta.t0)
  local amin=math.max(0,math.min(aMeta.t0,aMeta.t1)-spanA*.35)
  local amax=math.min(1,math.max(aMeta.t0,aMeta.t1)+spanA*.35)
  local bmin=math.max(0,math.min(bMeta.t0,bMeta.t1)-spanB*.35)
  local bmax=math.min(1,math.max(bMeta.t0,bMeta.t1)+spanB*.35)
  local function residual(t0,u0)
    local ax,ay=evaluate(pa,t0)
    local bx,by=evaluate(pb,u0)
    local dx,dy=ax-bx,ay-by
    return dx*dx+dy*dy,ax,ay,bx,by
  end
  local err2=residual(t,u)
  for _=1,20 do
    if err2<1e-12 then break end
    local ax,ay,adx,ady=evaluate(pa,t)
    local bx,by,bdx,bdy=evaluate(pb,u)
    local fx,fy=ax-bx,ay-by
    local det=bdx*ady-adx*bdy
    local magnitude=math.sqrt(adx*adx+ady*ady)
      *math.sqrt(bdx*bdx+bdy*bdy)
    if magnitude<1e-12 or math.abs(det)<magnitude*1e-9 then
      return nil,"curvas quase tangentes"
    end
    local dt=(fx*bdy-bdx*fy)/det
    local du=(fx*ady-adx*fy)/det
    local accepted=false
    local step=1
    for _=1,12 do
      local nt=t+dt*step
      local nu=u+du*step
      if nt>=amin and nt<=amax and nu>=bmin and nu<=bmax then
        local nextErr=residual(nt,nu)
        if nextErr<err2 then
          t,u,err2=nt,nu,nextErr
          accepted=true
          break
        end
      end
      step=step*.5
    end
    if not accepted then break end
  end
  -- Reject numerically unstable roots. Do not invent a more accurate cut if
  -- the polynomial system does not actually intersect nearby.
  if err2>1e-8 then return nil,"intersecao cubica sem convergencia" end
  local _,ax,ay,bx,by=residual(t,u)
  local x,y=(ax+bx)*.5,(ay+by)*.5
  if not finite(x) or not finite(y)
      or math.abs(x)>100000 or math.abs(y)>100000 then
    return nil,"intersecao fora do limite"
  end
  return {point=point(x,y),aT=t,bT=u,residual=math.sqrt(err2)}
end
return M
