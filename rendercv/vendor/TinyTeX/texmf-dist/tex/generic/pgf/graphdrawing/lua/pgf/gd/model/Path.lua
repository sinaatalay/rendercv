-- Copyright 2014 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


---
-- A Path models a path in the plane.
--
-- Following the PostScript/\textsc{pdf}/\textsc{svg} convention, a
-- path consists of a series of path segments, each of which can be
-- closed or not. Each path segment, in turn, consists of a series of
-- Bézier curves and straight line segments; see
-- Section~\ref{section-paths} for an introduction to paths in
-- general.
--
-- A |Path| object is a table whose array part stores
-- |Coordinate| objects, |strings|, and |function|s that
-- describe the path of the edge. The following strings are allowed in
-- this array:
-- %
-- \begin{itemize}
--   \item |"moveto"| The line's path should stop at the current
--     position and then start anew at the next coordinate in the array.
--   \item |"lineto"| The line should continue from the current position
--     to the next coordinate in the array.
--   \item |"curveto"| The line should continue form the current
--     position with a Bézier curve that is specified by the next three
--     |Coordinate| objects (in the usual manner).
--   \item |"closepath"| The line's path should be ``closed'' in the sense
--     that the current subpath that was started with the most recent
--     moveto operation should now form a closed curve.
-- \end{itemize}
--
-- Instead of a |Coordinate|, a |Path| may also contain a function. In
-- this case, the function, when called, must return the |Coordinate|
-- that is ``meant'' by the position. This allows algorithms to
-- add coordinates to a path that are still not fixed at the moment
-- they are added to the path.

local Path = {}
Path.__index = Path


-- Namespace

require("pgf.gd.model").Path = Path


-- Imports

local Coordinate = require "pgf.gd.model.Coordinate"
local Bezier     = require "pgf.gd.lib.Bezier"

local lib        = require "pgf.gd.lib"


-- Private function

function Path.rigid (x)
  if type(x) == "function" then
    return x()
  else
    return x
  end
end

local rigid = Path.rigid


---
-- Creates an empty path.
--
-- @param initial A table containing an array of strings and
-- coordinates that constitute the path. Coordinates may be given as
-- tables or as a pair of numbers. In this case, each pair of numbers
-- is converted into one coordinate. If omitted, a new empty path
-- is created.
--
-- @return A empty Path
--
function Path.new(initial)
  if initial then
    local new = {}
    local i = 1
    local count = 0
    while i <= #initial do
      local e = initial[i]
      if type(e) == "string" then
        assert (count == 0, "illformed path")
        if e == "moveto" then
          count = 1
        elseif e == "lineto" then
          count = 1
        elseif e == "closepath" then
          count = 0
        elseif e == "curveto" then
          count = 3
        else
          error ("unknown path command " .. e)
        end
        new[#new+1] = e
      elseif type(e) == "number" then
        if count == 0 then
          new[#new+1] = "lineto"
        else
          count = count - 1
        end
        new[#new+1] = Coordinate.new(e,initial[i+1])
        i = i + 1
      elseif type(e) == "table" or type(e) == "function" then
        if count == 0 then
          new[#new+1] = "lineto"
        else
          count = count - 1
        end
        new[#new+1] = e
      else
        error ("invalid object on path")
      end
      i = i + 1
    end
    return setmetatable(new, Path)
  else
    return setmetatable({}, Path)
  end
end


---
-- Creates a copy of a path.
--
-- @return A copy of the path

function Path:clone()
  local new = {}
  for _,x in ipairs(self) do
    if type(x) == "table" then
      new[#new+1] = x:clone()
    else
      new[#new+1] = x
    end
  end
  return setmetatable(new, Path)
end



---
-- Returns the path in reverse order.
--
-- @return A copy of the reversed path

function Path:reversed()

  -- First, build segments
  local subpaths = {}
  local subpath  = {}

  local function closepath ()
    if subpath.start then
      subpaths [#subpaths + 1] = subpath
      subpath = {}
    end
  end

  local prev
  local start

  local i = 1
  while i <= #self do
    local x = self[i]
    if x == "lineto" then
      subpath[#subpath+1] = {
        action   = 'lineto',
        from     = prev,
        to       = self[i+1]
      }
      prev = self[i+1]
      i = i + 2
    elseif x == "moveto" then
      closepath()
      prev = self[i+1]
      start = prev
      subpath.start = prev
      i = i + 2
    elseif x == "closepath" then
      subpath [#subpath + 1] = {
        action   = "closepath",
        from     = prev,
        to       = start,
      }
      prev = nil
      start = nil
      closepath()
      i = i + 1
    elseif x == "curveto" then
      local s1, s2, to = self[i+1], self[i+2], self[i+3]
      subpath [#subpath + 1] = {
        action    = "curveto",
        from      = prev,
        to        = to,
        support_1 = s1,
        support_2 = s2,
      }
      prev = self[i+3]
      i = i + 4
    else
      error ("illegal path command '" .. x .. "'")
    end
  end
  closepath ()

  local new = Path.new ()

  for _,subpath in ipairs(subpaths) do
    if #subpath == 0 then
      -- A subpath that consists only of a moveto:
      new:appendMoveto(subpath.start)
    else
      -- We start with a moveto to the end point:
      new:appendMoveto(subpath[#subpath].to)

      -- Now walk backwards:
      for i=#subpath,1,-1 do
        if subpath[i].action == "lineto" then
          new:appendLineto(subpath[i].from)
        elseif subpath[i].action == "closepath" then
          new:appendLineto(subpath[i].from)
        elseif subpath[i].action == "curveto" then
          new:appendCurveto(subpath[i].support_2,
                            subpath[i].support_1,
                            subpath[i].from)
        else
          error("illegal path command")
        end
      end

      -- Append a closepath, if necessary
      if subpath[#subpath].action == "closepath" then
        new:appendClosepath()
      end
    end
  end

  return new
end


---
-- Transform all points on a path.
--
-- @param t A transformation, see |pgf.gd.lib.Transform|. It is
-- applied to all |Coordinate| objects on the path.

function Path:transform(t)
  for _,c in ipairs(self) do
    if type(c) == "table" then
      c:apply(t)
    end
  end
end


---
-- Shift all points on a path.
--
-- @param x An $x$-shift
-- @param y A $y$-shift

function Path:shift(x,y)
  for _,c in ipairs(self) do
    if type(c) == "table" then
      c.x = c.x + x
      c.y = c.y + y
    end
  end
end


---
-- Shift by all points on a path.
--
-- @param x A coordinate

function Path:shiftByCoordinate(x)
  for _,c in ipairs(self) do
    if type(c) == "table" then
      c.x = c.x + x.x
      c.y = c.y + x.y
    end
  end
end


---
-- Makes the path empty.
--

function Path:clear()
  for i=1,#self do
    self[i] = nil
  end
end


---
-- Appends a |moveto| to the path.
--
-- @param x A |Coordinate| or |function| or, if the |y| parameter is
-- not |nil|, a number that is the $x$-part of a coordinate.
-- @param y The $y$-part of the coordinate.

function Path:appendMoveto(x,y)
  self[#self + 1] = "moveto"
  self[#self + 1] = y and Coordinate.new(x,y) or x
end


---
-- Appends a |lineto| to the path.
--
-- @param x A |Coordinate| or |function|, if the |y| parameter is not
-- |nil|, a number that is the $x$-part of a coordinate.
-- @param y The $y$-part of the coordinate.

function Path:appendLineto(x,y)
  self[#self + 1] = "lineto"
  self[#self + 1] = y and Coordinate.new(x,y) or x
end



---
-- Appends a |closepath| to the path.

function Path:appendClosepath()
  self[#self + 1] = "closepath"
end


---
-- Appends a |curveto| to the path. There can be either three
-- coordinates (or functions) as parameters (the two support points
-- and the target) or six numbers, where two consecutive numbers form a
-- |Coordinate|. Which case is meant is detected by the presence of a
-- sixth non-nil parameter.

function Path:appendCurveto(a,b,c,d,e,f)
  self[#self + 1] = "curveto"
  if f then
    self[#self + 1] = Coordinate.new(a,b)
    self[#self + 1] = Coordinate.new(c,d)
    self[#self + 1] = Coordinate.new(e,f)
  else
    self[#self + 1] = a
    self[#self + 1] = b
    self[#self + 1] = c
  end
end






---
-- Makes a path ``rigid'', meaning that all coordinates that are only
-- given as functions are replaced by the values these functions
-- yield.

function Path:makeRigid()
  for i=1,#self do
    self[i] = rigid(self[i])
  end
end


---
-- Returns an array of all coordinates that are present in a
-- path. This means, essentially, that all strings are filtered out.
--
-- @return An array of all coordinate objects on the path.

function Path:coordinates()
  local cloud = {}
  for i=1,#self do
    local p = self[i]
    if type(p) == "table" then
      cloud[#cloud + 1] = p
    elseif type(p) == "function" then
      cloud[#cloud + 1] = p()
    end
  end
  return cloud
end


---
-- Returns a bounding box of the path. This will not necessarily be
-- the minimal bounding box in case the path contains curves because,
-- then, the support points of the curve are used for the computation
-- rather than the actual bounding box of the path.
--
-- If the path contains no coordinates, all return values are 0.
--
-- @return |min_x| The minimum $x$ value of the bounding box of the path
-- @return |min_y| The minimum $y$ value
-- @return |max_x|
-- @return |max_y|
-- @return |center_x| The center of the bounding box
-- @return |center_y|

function Path:boundingBox()
  if #self > 0 then
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge

    for i=1,#self do
      local c = rigid(self[i])
      if type(c) == "table" then
        local x = c.x
        local y = c.y
        if x < min_x then min_x = x end
        if y < min_y then min_y = y end
        if x > max_x then max_x = x end
        if y > max_y then max_y = y end
      end
    end

    if min_x ~= math.huge then
      return min_x, min_y, max_x, max_y, (min_x+max_x) / 2, (min_y+max_y) / 2
    end
  end
  return 0, 0, 0, 0, 0, 0
end


-- Forwards

local segmentize, bb, boxes_intersect, intersect_curves

local eps = 0.0001



---
-- Computes all intersections of a path with another path and returns
-- them as an array of coordinates. The intersections will be sorted
-- ``along the path |self|''. The implementation uses a
-- divide-and-conquer approach that should be reasonably fast in
-- practice.
--
-- @param path Another path
--
-- @return Array of all intersections of |path| with |self| in the
-- order they appear on |self|. Each entry of this array is a table
-- with the following fields:
-- %
-- \begin{itemize}
--   \item |index| The index of the segment in |self| where
--     the intersection occurs.
--   \item |time| The ``time'' at which a point traveling along the
--     segment from its start point to its end point.
--   \item |point| The point itself.
-- \end{itemize}

function Path:intersectionsWith(path)

  local p1    = segmentize(self)
  local memo1 = prepare_memo(p1)
  local p2    = segmentize(path)
  local memo2 = prepare_memo(p2)

  local intersections = {}

  local function intersect_segments(i1, i2)

    local s1 = p1[i1]
    local s2 = p2[i2]
    local r = {}

    if s1.action == 'lineto' and s2.action == 'lineto' then
      local a = s2.to.x - s2.from.x
      local b = s1.from.x - s1.to.x
      local c = s2.from.x - s1.from.x
      local d = s2.to.y - s2.from.y
      local e = s1.from.y - s1.to.y
      local f = s2.from.y - s1.from.y

      local det = a*e - b*d

      if math.abs(det) > eps*eps then
        local t, s = (c*d - a*f)/det, (b*f - e*c)/det

        if t >= 0 and t<=1 and s>=0 and s <= 1 then
          local p = s1.from:clone()
          p:moveTowards(s1.to, t)
          return { { time = t, point = p } }
        end
      end
    elseif s1.action == 'lineto' and s2.action == 'curveto' then
      intersect_curves (0, 1,
                        s1.from.x, s1.from.y,
                        s1.from.x*2/3+s1.to.x*1/3, s1.from.y*2/3+s1.to.y*1/3,
                        s1.from.x*1/3+s1.to.x*2/3, s1.from.y*1/3+s1.to.y*2/3,
                        s1.to.x, s1.to.y,
                        s2.from.x, s2.from.y,
                        s2.support_1.x, s2.support_1.y,
                        s2.support_2.x, s2.support_2.y,
                        s2.to.x, s2.to.y,
                        r)
    elseif s1.action == 'curveto' and s2.action == 'lineto' then
      intersect_curves (0, 1,
                        s1.from.x, s1.from.y,
                        s1.support_1.x, s1.support_1.y,
                        s1.support_2.x, s1.support_2.y,
                        s1.to.x, s1.to.y,
                        s2.from.x, s2.from.y,
                        s2.from.x*2/3+s2.to.x*1/3, s2.from.y*2/3+s2.to.y*1/3,
                        s2.from.x*1/3+s2.to.x*2/3, s2.from.y*1/3+s2.to.y*2/3,
                        s2.to.x, s2.to.y,
                        r)
    else
      intersect_curves (0, 1,
                        s1.from.x, s1.from.y,
                        s1.support_1.x, s1.support_1.y,
                        s1.support_2.x, s1.support_2.y,
                        s1.to.x, s1.to.y,
                        s2.from.x, s2.from.y,
                        s2.support_1.x, s2.support_1.y,
                        s2.support_2.x, s2.support_2.y,
                        s2.to.x, s2.to.y,
                        r)
    end
    return r
  end

  local function intersect (i1, j1, i2, j2)

    if i1 > j1 or i2 > j2 then
      return
    end

    local bb1 = bb(i1, j1, memo1)
    local bb2 = bb(i2, j2, memo2)

    if boxes_intersect(bb1, bb2) then
      -- Ok, need to do something
      if i1 == j1 and i2 == j2 then
        local intersects = intersect_segments (i1, i2)
        for _,t in ipairs(intersects) do
          intersections[#intersections+1] = {
            time = t.time,
            index = p1[i1].path_pos,
            point = t.point
          }
        end
      elseif i1 == j1 then
        local m2 = math.floor((i2 + j2) / 2)
        intersect(i1, j1, i2, m2)
        intersect(i1, j1, m2+1, j2)
      elseif i2 == j2 then
        local m1 = math.floor((i1 + j1) / 2)
        intersect(i1, m1, i2, j2)
        intersect(m1+1, j1, i2, j2)
      else
        local m1 = math.floor((i1 + j1) / 2)
        local m2 = math.floor((i2 + j2) / 2)
        intersect(i1, m1, i2, m2)
        intersect(m1+1, j1, i2, m2)
        intersect(i1, m1, m2+1, j2)
        intersect(m1+1, j1, m2+1, j2)
      end
    end
  end

  -- Run the recursion
  intersect(1, #p1, 1, #p2)

  -- Sort
  table.sort(intersections, function(a,b)
    return a.index < b.index or
      a.index == b.index and a.time < b.time
    end)

  -- Remove duplicates
  local remains = {}
  remains[1] = intersections[1]
  for i=2,#intersections do
    local next = intersections[i]
    local prev = remains[#remains]
    if math.abs(next.point.x - prev.point.x) + math.abs(next.point.y - prev.point.y) > eps then
      remains[#remains+1] = next
    end
  end

  return remains
end


-- Returns true if two bounding boxes intersection

function boxes_intersect (bb1, bb2)
  return (bb1.max_x >= bb2.min_x - eps*eps and
      bb1.min_x <= bb2.max_x + eps*eps and
      bb1.max_y >= bb2.min_y - eps*eps and
      bb1.min_y <= bb2.max_y + eps*eps)
end


-- Turns a path into a sequence of segments, each being either a
-- lineto or a curveto from some point to another point. It also sets
-- up a memorization array for the bounding boxes.

function segmentize (path)

  local prev
  local start
  local s = {}

  local i = 1
  while i <= #path do
    local x = path[i]

    if x == "lineto" then
      x = rigid(path[i+1])
      s [#s + 1] = {
        path_pos = i,
        action   = "lineto",
        from     = prev,
        to       = x,
        bb       = {
          min_x = math.min(prev.x, x.x),
          max_x = math.max(prev.x, x.x),
          min_y = math.min(prev.y, x.y),
          max_y = math.max(prev.y, x.y),
        }
      }
      prev = x
      i = i + 2
    elseif x == "moveto" then
      prev = rigid(path[i+1])
      start = prev
      i = i + 2
    elseif x == "closepath" then
      s [#s + 1] = {
        path_pos = i,
        action   = "lineto",
        from     = prev,
        to       = start,
        bb       = {
          min_x = math.min(prev.x, start.x),
          max_x = math.max(prev.x, start.x),
          min_y = math.min(prev.y, start.y),
          max_y = math.max(prev.y, start.y),
        }
      }
      prev = nil
      start = nil
      i = i + 1
    elseif x == "curveto" then
      local s1, s2, to = rigid(path[i+1]), rigid(path[i+2]), rigid(path[i+3])
      s [#s + 1] = {
        action    = "curveto",
        path_pos  = i,
        from      = prev,
        to        = to,
        support_1 = s1,
        support_2 = s2,
        bb        = {
          min_x = math.min(prev.x, s1.x, s2.x, to.x),
          max_x = math.max(prev.x, s1.x, s2.x, to.x),
          min_y = math.min(prev.y, s1.y, s2.y, to.y),
          max_y = math.max(prev.y, s1.y, s2.y, to.y),
        }
      }
      prev = path[i+3]
      i = i + 4
    else
      error ("illegal path command '" .. x .. "'")
    end
  end

  return s
end


function prepare_memo (s)

  local memo = {}

  memo.base = #s

  -- Fill memo table
  for i,e in ipairs (s) do
    memo[i*#s + i] = e.bb
  end

  return memo
end


-- This function computes the bounding box of all segments between i
-- and j (inclusively)

function bb (i, j, memo)
  local b = memo[memo.base*i + j]
  if not b then
    assert (i < j, "memorization table filled incorrectly")

    local mid = math.floor((i+j)/2)
    local bb1 = bb (i, mid, memo)
    local bb2 = bb (mid+1, j, memo)
    b = {
      min_x = math.min(bb1.min_x, bb2.min_x),
      max_x = math.max(bb1.max_x, bb2.max_x),
      min_y = math.min(bb1.min_y, bb2.min_y),
      max_y = math.max(bb1.max_y, bb2.max_y)
    }
    memo[memo.base*i + j] = b
  end

  return b
end



-- Intersect two Bézier curves.

function intersect_curves(t0, t1,
                          c1_ax, c1_ay, c1_bx, c1_by,
                          c1_cx, c1_cy, c1_dx, c1_dy,
                          c2_ax, c2_ay, c2_bx, c2_by,
                          c2_cx, c2_cy, c2_dx, c2_dy,
                          intersections)

  -- Only do something, if the bounding boxes intersect:
  local c1_min_x = math.min(c1_ax, c1_bx, c1_cx, c1_dx)
  local c1_max_x = math.max(c1_ax, c1_bx, c1_cx, c1_dx)
  local c1_min_y = math.min(c1_ay, c1_by, c1_cy, c1_dy)
  local c1_max_y = math.max(c1_ay, c1_by, c1_cy, c1_dy)
  local c2_min_x = math.min(c2_ax, c2_bx, c2_cx, c2_dx)
  local c2_max_x = math.max(c2_ax, c2_bx, c2_cx, c2_dx)
  local c2_min_y = math.min(c2_ay, c2_by, c2_cy, c2_dy)
  local c2_max_y = math.max(c2_ay, c2_by, c2_cy, c2_dy)

  if c1_max_x >= c2_min_x and
     c1_min_x <= c2_max_x and
     c1_max_y >= c2_min_y and
     c1_min_y <= c2_max_y then

    -- Everything "near together"?
    if c1_max_x - c1_min_x < eps and c1_max_y - c1_min_y < eps then

      -- Compute intersection of lines c1_a to c1_d and c2_a to c2_d
      local a = c2_dx - c2_ax
      local b = c1_ax - c1_dx
      local c = c2_ax - c1_ax
      local d = c2_dy - c2_ay
      local e = c1_ay - c1_dy
      local f = c2_ay - c1_ay

      local det = a*e - b*d
      local t

      t = (c*d - a*f)/det
      if t<0 then
        t=0
      elseif t>1 then
        t=1
      end

      intersections [#intersections + 1] = {
        time = t0 + t*(t1-t0),
        point = Coordinate.new(c1_ax + t*(c1_dx-c1_ax), c1_ay+t*(c1_dy-c1_ay))
      }
    else
      -- Cut 'em in half!
      local c1_ex, c1_ey = (c1_ax + c1_bx)/2, (c1_ay + c1_by)/2
      local c1_fx, c1_fy = (c1_bx + c1_cx)/2, (c1_by + c1_cy)/2
      local c1_gx, c1_gy = (c1_cx + c1_dx)/2, (c1_cy + c1_dy)/2

      local c1_hx, c1_hy = (c1_ex + c1_fx)/2, (c1_ey + c1_fy)/2
      local c1_ix, c1_iy = (c1_fx + c1_gx)/2, (c1_fy + c1_gy)/2

      local c1_jx, c1_jy = (c1_hx + c1_ix)/2, (c1_hy + c1_iy)/2

      local c2_ex, c2_ey = (c2_ax + c2_bx)/2, (c2_ay + c2_by)/2
      local c2_fx, c2_fy = (c2_bx + c2_cx)/2, (c2_by + c2_cy)/2
      local c2_gx, c2_gy = (c2_cx + c2_dx)/2, (c2_cy + c2_dy)/2

      local c2_hx, c2_hy = (c2_ex + c2_fx)/2, (c2_ey + c2_fy)/2
      local c2_ix, c2_iy = (c2_fx + c2_gx)/2, (c2_fy + c2_gy)/2

      local c2_jx, c2_jy = (c2_hx + c2_ix)/2, (c2_hy + c2_iy)/2

      intersect_curves (t0, (t0+t1)/2,
                        c1_ax, c1_ay, c1_ex, c1_ey, c1_hx, c1_hy, c1_jx, c1_jy,
                        c2_ax, c2_ay, c2_ex, c2_ey, c2_hx, c2_hy, c2_jx, c2_jy,
                        intersections)
      intersect_curves (t0, (t0+t1)/2,
                        c1_ax, c1_ay, c1_ex, c1_ey, c1_hx, c1_hy, c1_jx, c1_jy,
                        c2_jx, c2_jy, c2_ix, c2_iy, c2_gx, c2_gy, c2_dx, c2_dy,
                        intersections)
      intersect_curves ((t0+t1)/2, t1,
                        c1_jx, c1_jy, c1_ix, c1_iy, c1_gx, c1_gy, c1_dx, c1_dy,
                        c2_ax, c2_ay, c2_ex, c2_ey, c2_hx, c2_hy, c2_jx, c2_jy,
                        intersections)
      intersect_curves ((t0+t1)/2, t1,
                        c1_jx, c1_jy, c1_ix, c1_iy, c1_gx, c1_gy, c1_dx, c1_dy,
                        c2_jx, c2_jy, c2_ix, c2_iy, c2_gx, c2_gy, c2_dx, c2_dy,
                        intersections)
    end
  end
end


---
-- Shorten a path at the beginning. We are given the index of a
-- segment inside the path as well as a point in time along this
-- segment. The path is now shortened so that everything before this
-- segment and everything in the segment before the given time is
-- removed from the path.
--
-- @param index The index of a path segment.
-- @param time A time along the specified path segment.

function Path:cutAtBeginning(index, time)

  local cut_path = Path:new ()

  -- Ok, first, we need to find the segment *before* the current
  -- one. Usually, this will be a moveto or a lineto, but things could
  -- be different.
  assert (type(self[index-1]) == "table" or type(self[index-1]) == "function",
          "segment before intersection does not end with a coordinate")

  local from   = rigid(self[index-1])
  local action = self[index]

  -- Now, depending on the type of segment, we do different things:
  if action == "lineto" then

    -- Ok, compute point:
    local to = rigid(self[index+1])

    from:moveTowards(to, time)

    -- Ok, this is easy: We start with a fresh moveto ...
    cut_path[1] = "moveto"
    cut_path[2] = from

    -- ... and copy the rest
    for i=index,#self do
      cut_path[#cut_path+1] = self[i]
    end
  elseif action == "curveto" then

    local to = rigid(self[index+3])
    local s1 = rigid(self[index+1])
    local s2 = rigid(self[index+2])

    -- Now, compute the support vectors and the point at time:
    from:moveTowards(s1, time)
    s1:moveTowards(s2, time)
    s2:moveTowards(to, time)

    from:moveTowards(s1, time)
    s1:moveTowards(s2, time)

    from:moveTowards(s1, time)

    -- Ok, this is easy: We start with a fresh moveto ...
    cut_path[1] = "moveto"
    cut_path[2] = from
    cut_path[3] = "curveto"
    cut_path[4] = s1
    cut_path[5] = s2
    cut_path[6] = to

    -- ... and copy the rest
    for i=index+4,#self do
      cut_path[#cut_path+1] = self[i]
    end

  elseif action == "closepath" then
    -- Let us find the start point:
    local found
    for i=index,1,-1 do
      if self[i] == "moveto" then
        -- Bingo:
        found = i
        break
      end
    end

    assert(found, "no moveto found in path")

    local to = rigid(self[found+1])
    from:moveTowards(to,time)

    cut_path[1] = "moveto"
    cut_path[2] = from
    cut_path[3] = "lineto"
    cut_path[4] = to

    -- ... and copy the rest
    for i=index+1,#self do
      cut_path[#cut_path+1] = self[i]
    end
  else
    error ("wrong path operation")
  end

  -- Move cut_path back:
  for i=1,#cut_path do
    self[i] = cut_path[i]
  end
  for i=#cut_path+1,#self do
    self[i] = nil
  end
end




---
-- Shorten a path at the end. This method works like |cutAtBeginning|,
-- only the path is cut at the end.
--
-- @param index The index of a path segment.
-- @param time A time along the specified path segment.

function Path:cutAtEnd(index, time)

  local cut_path = Path:new ()

  -- Ok, first, we need to find the segment *before* the current
  -- one. Usually, this will be a moveto or a lineto, but things could
  -- be different.
  assert (type(self[index-1]) == "table" or type(self[index-1]) == "function",
          "segment before intersection does not end with a coordinate")

  local from   = rigid(self[index-1])
  local action = self[index]

  -- Now, depending on the type of segment, we do different things:
  if action == "lineto" then

    -- Ok, compute point:
    local to = rigid(self[index+1])
    to:moveTowards(from, 1-time)

    for i=1,index do
      cut_path[i] = self[i]
    end
    cut_path[index+1] = to

  elseif action == "curveto" then

    local s1 = rigid(self[index+1])
    local s2 = rigid(self[index+2])
    local to = rigid(self[index+3])

    -- Now, compute the support vectors and the point at time:
    to:moveTowards(s2, 1-time)
    s2:moveTowards(s1, 1-time)
    s1:moveTowards(from, 1-time)

    to:moveTowards(s2, 1-time)
    s2:moveTowards(s1, 1-time)

    to:moveTowards(s2, 1-time)

    -- ... and copy the rest
    for i=1,index do
      cut_path[i] = self[i]
    end

    cut_path[index+1] = s1
    cut_path[index+2] = s2
    cut_path[index+3] = to

  elseif action == "closepath" then
    -- Let us find the start point:
    local found
    for i=index,1,-1 do
      if self[i] == "moveto" then
        -- Bingo:
        found = i
        break
      end
    end

    assert(found, "no moveto found in path")

    local to = rigid(self[found+1]:clone())
    to:moveTowards(from,1-time)

    for i=1,index-1 do
      cut_path[i] = self[i]
    end
    cut_path[index] = 'lineto'
    cut_path[index+1] = to
  else
    error ("wrong path operation")
  end

  -- Move cut_path back:
  for i=1,#cut_path do
    self[i] = cut_path[i]
  end
  for i=#cut_path+1,#self do
    self[i] = nil
  end
end




---
-- ``Pads'' the path. The idea is the following: Suppose we stroke the
-- path with a pen whose width is twice the value |padding|. The outer
-- edge of this stroked drawing is now a path by itself. The path will
-- be a bit longer and ``larger''. The present function tries to
-- compute an approximation to this resulting path.
--
-- The algorithm used to compute the enlarged part does not necessarily
-- compute the precise new path. It should work correctly for polyline
-- paths, but not for curved paths.
--
-- @param padding A padding distance.
-- @return The padded path.
--

function Path:pad(padding)

  local padded = self:clone()
  padded:makeRigid()

  if padding == 0 then
    return padded
  end

  -- First, decompose the path into subpaths:
  local subpaths = {}
  local subpath = {}
  local start_index = 1

  local function closepath(end_index)
    if #subpath >= 1 then
      subpath.start_index = start_index
      subpath.end_index   = end_index
      start_index = end_index + 1

      local start = 1
      if (subpath[#subpath] - subpath[1]):norm() < 0.01 and subpath[2] then
        start = 2
        subpath.skipped = subpath[1]
      end
      subpath[#subpath + 1] = subpath[start]
      subpath[#subpath + 1] = subpath[start+1]
      subpaths[#subpaths + 1] = subpath
      subpath = {}
    end
  end

  for i,p in ipairs(padded) do
    if p ~= "closepath" then
      if type(p) == "table" then
        subpath[#subpath + 1] = p
      end
    else
      closepath (i)
    end
  end
  closepath(#padded)

  -- Second, iterate over the subpaths:
  for _,subpath in ipairs(subpaths) do
    local new_coordinates = {}
    local _,_,_,_,c_x,c_y = Coordinate.boundingBox(subpath)
    local c = Coordinate.new(c_x,c_y)

    -- Find out the orientation of the path
    local count = 0
    for i=1,#subpath-2 do
      local d2 = subpath[i+1] - subpath[i]
      local d1 = subpath[i+2] - subpath[i+1]

      local diff = math.atan2(d2.y,d2.x) - math.atan2(d1.y,d1.x)

      if diff < -math.pi then
        count = count + 1
      elseif diff > math.pi then
        count = count - 1
      end
    end

    for i=2,#subpath-1 do
      local p = subpath[i]
      local d1 = subpath[i] - subpath[i-1]
      local d2 = subpath[i+1] - subpath[i]

      local orth1 = Coordinate.new(-d1.y, d1.x)
      local orth2 = Coordinate.new(-d2.y, d2.x)

      orth1:normalize()
      orth2:normalize()

      if count < 0 then
        orth1:scale(-1)
        orth2:scale(-1)
      end

      -- Ok, now we want to compute the intersection of the lines
      -- perpendicular to p + padding*orth1 and p + padding*orth2:

      local det = orth1.x * orth2.y - orth1.y * orth2.x

      local c
      if math.abs(det) < 0.1 then
        c = orth1 + orth2
        c:scale(padding/2)
      else
        c = Coordinate.new (padding*(orth2.y-orth1.y)/det, padding*(orth1.x-orth2.x)/det)
      end

      new_coordinates[i] = c+p
    end

    for i=2,#subpath-1 do
      local p = subpath[i]
      local new_p = new_coordinates[i]
      p.x = new_p.x
      p.y = new_p.y
    end

    if subpath.skipped then
      local p = subpath[1]
      local new_p = new_coordinates[#subpath-2]
      p.x = new_p.x
      p.y = new_p.y
    end

    -- Now, we need to correct the curveto fields:
    for i=subpath.start_index,subpath.end_index do
      if self[i] == 'curveto' then
        local from = rigid(self[i-1])
        local s1   = rigid(self[i+1])
        local s2   = rigid(self[i+2])
        local to   = rigid(self[i+3])

        local p1x, p1y, _, _, h1x, h1y =
          Bezier.atTime(from.x, from.y, s1.x, s1.y, s2.x, s2.y,
                        to.x, to.y, 1/3)

        local p2x, p2y, _, _, _, _, h2x, h2y =
          Bezier.atTime(from.x, from.y, s1.x, s1.y, s2.x, s2.y,
                        to.x, to.y, 2/3)

        local orth1 = Coordinate.new (p1y - h1y, -(p1x - h1x))
        orth1:normalize()
        orth1:scale(-padding)

        local orth2 = Coordinate.new (p2y - h2y, -(p2x - h2x))
        orth2:normalize()
        orth2:scale(padding)

        if count < 0 then
          orth1:scale(-1)
          orth2:scale(-1)
        end

        local new_s1, new_s2 =
          Bezier.supportsForPointsAtTime(padded[i-1],
                                         Coordinate.new(p1x+orth1.x,p1y+orth1.y), 1/3,
                                         Coordinate.new(p2x+orth2.x,p2y+orth2.y), 2/3,
                                         padded[i+3])

        padded[i+1] = new_s1
        padded[i+2] = new_s2
      end
    end
  end

  return padded
end



---
-- Appends an arc (as in the sense of ``a part of the circumference of
-- a circle'') to the path. You may optionally provide a
-- transformation matrix, which will be applied to the arc. In detail,
-- the following happens: We first invert the transformation
-- and apply it to the start point. Then we compute the arc
-- ``normally'', as if no transformation matrix were present. Then we
-- apply the transformation matrix to all computed points.
--
-- @function Path:appendArc(start_angle,end_angle,radius,trans)
--
-- @param start_angle The start angle of the arc. Must be specified in
-- degrees.
-- @param end_angle the end angle of the arc.
-- @param radius The radius of the circle on which this arc lies.
-- @param trans A transformation matrix. If |nil|, the identity
-- matrix will be assumed.

Path.appendArc   = lib.ondemand("Path_arced", Path, "appendArc")



---
-- Appends a clockwise arc (as in the sense of ``a part of the circumference of
-- a circle'') to the path such that it ends at a given point. If a
-- transformation matrix is given, both start and end point are first
-- transformed according to the inverted transformation, then the arc
-- is computed and then transformed back.
--
-- @function Path:appendArcTo(target,radius_or_center,clockwise,trans)
--
-- @param target The point where the arc should end.
-- @param radius_or_center If a number, it is the radius of the circle
-- on which this arc lies. If it is a |Coordinate|, this is the center
-- of the circle.
-- @param clockwise If true, the arc will be clockwise. Otherwise (the
-- default, if nothing or |nil| is given), the arc will be counter
-- clockwise.
-- @param trans A transformation matrix. If missing,
-- the identity matrix is assumed.

Path.appendArcTo = lib.ondemand("Path_arced", Path, "appendArcTo")




--
-- @return The Path as string.
--
function Path:__tostring()
  local r = {}
  local i = 1
  while i <= #self do
    local p = self[i]

    if p == "lineto" then
      r [#r+1] = " -- " .. tostring(rigid(self[i+1]))
      i = i + 1
    elseif p == "moveto" then
      r [#r+1] = " " .. tostring(rigid(self[i+1]) )
      i = i + 1
    elseif p == "curveto" then
      r [#r+1] = " .. controls " .. tostring(rigid(self[i+1])) .. " and " ..
      tostring(rigid(self[i+2])) .. " .. " .. tostring(rigid(self[i+3]))
      i = i + 3
    elseif p == "closepath" then
      r [#r+1] = " -- cycle"
    else
      error("illegal path command")
    end
    i = i + 1
  end
  return table.concat(r)
end



-- Done

return Path
