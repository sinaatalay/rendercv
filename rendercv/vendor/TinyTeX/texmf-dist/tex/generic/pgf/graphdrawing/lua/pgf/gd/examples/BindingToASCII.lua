local lib = require "pgf.gd.lib"

-- Create a binding to ourselves
local BindingToASCII = lib.class { base_class = require "pgf.gd.bindings.Binding" }

local canvas

function BindingToASCII:renderStart()
  canvas = {}
  -- Clear the canvas
  for x=-30,30 do
    canvas [x] = {}
    for y=-30,30 do
      canvas[x][y] = ' '
    end
  end
end

function BindingToASCII:renderStop()
  for y=10,-30,-1 do
    local t = {}
    for x=-30,30 do
      local s = canvas[x][y]
      for i=1,#s do
        pos = x+30+i-math.floor(#s/2)
        if not t[pos] or t[pos] == " " or t[pos] == "." then
          t[pos] = string.sub(s,i,i)
        end
      end
    end
    print(table.concat(t))
  end
end

function BindingToASCII:renderVertex(v)
  canvas [math.floor(v.pos.x)][math.floor(v.pos.y)] = v.name
end

function BindingToASCII:renderEdge(e)

  local function connect (p,q)

    local x1, y1, x2, y2 = math.floor(p.x+0.5), math.floor(p.y+0.5), math.floor(q.x+0.5), math.floor(q.y+0.5)

    -- Go upward with respect to x
    if x2 < x1 then
      x1, y1, x2, y2 = x2, y2, x1, y1
    end

    local delta_x = x2-x1
    local delta_y = y2-y1

    if math.abs(delta_x) > math.abs(delta_y) then
      local slope = delta_y/delta_x
      for i=x1,x2 do
        local x,y = i, math.floor(y1 + (i-x1)*slope + 0.5)

        if canvas[x][y] == " " then
          canvas[x][y] = '.'
        end
      end
    elseif math.abs(delta_y) > 0 then
      local slope = delta_x/delta_y
      for i=y1,y2,(y1<y2 and 1) or -1 do
        local x,y = math.floor(x1 + (i-y1)*slope + 0.5), i

        if canvas[x][y] == " " then
          canvas[x][y] = '.'
        end
      end
    end
  end


  local p = e.tail.pos

  for i=1,#e.path do
    if type(e.path[i]) == "table" then
      connect(p, e.path[i])
      p = e.path[i]
    end
  end

  connect(p, e.head.pos)
end

return BindingToASCII
