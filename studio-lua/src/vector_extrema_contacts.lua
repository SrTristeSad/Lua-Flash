-- Certified single-point contacts at extrema of two original cubic outlines.
-- If one complete outline lies on one side of an x/y support line and the
-- other lies on the opposite side, their filled interiors cannot intersect.
-- Unlike polygon samples, cubic derivative roots locate interior extrema.
-- Reject shared edges, multiple contacts, holes and any uncertain case.
local Contacts=require("src.vector_contacts")
local M={}
local EPS=1e-9
local function finite(v)
  return type(v)=="number" and v==v and math.abs(v)<math.huge
end
local function point(p,t)
  local u=1-t
  return {
    x=u^3*p[1].x+3*u*u*t*p[2].x+3*u*t*t*p[3].x+t^3*p[4].x,
    y=u^3*p[1].y+3*u*u*t*p[2].y+3*u*t*t*p[3].y+t^3*p[4].y
  }
end
local function stationary(p,axis)
  local a,b,c,d=p[1][axis],p[2][axis],p[3][axis],p[4][axis]
  local quadratic=3*(-a+3*b-3*c+d)
  local linear=2*(3*a-6*b+3*c)
  local constant=3*(b-a)
  local roots={0,1}
  if math.abs(quadratic)<1e-12 then
    if math.abs(linear)>1e-12 then
      local t=-constant/linear
      if t>0 and t<1 then roots[#roots+1]=t end
    end
  else
    local delta=linear*linear-4*quadratic*constant
    if delta>=0 then
      local root=math.sqrt(delta)
      local t1=(-linear-root)/(2*quadratic)
      local t2=(-linear+root)/(2*quadratic)
      if t1>0 and t1<1 then roots[#roots+1]=t1 end
      if t2>0 and t2<1 then roots[#roots+1]=t2 end
    end
  end
  return roots
end
local function extrema(nodes,axis)
  if type(nodes)~="table" or #nodes<3 or #nodes>48 then return nil end
  local low={value=math.huge,positions={}}
  local high={value=-math.huge,positions={}}
  local function add(extreme,value,p,isLow)
    local diff=value-extreme.value
    local better=isLow and diff<-EPS or (not isLow and diff>EPS)
    if better then
      extreme.value=value
      extreme.positions={}
    elseif math.abs(diff)>EPS then
      return
    end
    for _,other in ipairs(extreme.positions) do
      if math.abs(other.x-p.x)<=EPS and math.abs(other.y-p.y)<=EPS then
        return
      end
    end
    extreme.positions[#extreme.positions+1]=p
  end
  for i,a in ipairs(nodes) do
    local b=nodes[i%#nodes+1]
    local p={{x=a.x,y=a.y},{x=a.ox,y=a.oy},
      {x=b.ix,y=b.iy},{x=b.x,y=b.y}}
    for _,q in ipairs(p) do
      if not finite(q.x) or not finite(q.y)
          or math.abs(q.x)>100000 or math.abs(q.y)>100000 then
        return nil
      end
    end
    for _,t in ipairs(stationary(p,axis)) do
      local at=point(p,t)
      add(low,at[axis],at,true)
      add(high,at[axis],at,false)
    end
  end
  return low,high
end
local function singleContact(maximum,minimum)
  if not maximum or not minimum then return false end
  if math.abs(maximum.value-minimum.value)>EPS
      or #maximum.positions~=1 or #minimum.positions~=1 then
    return false
  end
  local a,b=maximum.positions[1],minimum.positions[1]
  return math.abs(a.x-b.x)<=EPS and math.abs(a.y-b.y)<=EPS
end
-- Tri-state interface: handled, shapes, error. False means that the existing
-- Boolean engine must decide normally; there is no speculative snapping.
function M.plan(a,b,operation)
  if not a or not b or not a.closed or not b.closed
      or not a.fill or not b.fill
      or #(a.holes or {})>0 or #(b.holes or {})>0 then
    return false
  end
  for _,axis in ipairs({"x","y"}) do
    local amin,amax=extrema(a.nodes,axis)
    local bmin,bmax=extrema(b.nodes,axis)
    if not amin or not bmin then return false end
    if singleContact(amax,bmin) or singleContact(bmax,amin) then
      if operation=="intersection" then
        return true,nil,"empty result"
      elseif operation=="difference" then
        return true,{Contacts.originalResult(a)}
      elseif operation=="union" then
        return true,{Contacts.originalResult(a),Contacts.originalResult(b)}
      end
    end
  end
  return false
end
return M
