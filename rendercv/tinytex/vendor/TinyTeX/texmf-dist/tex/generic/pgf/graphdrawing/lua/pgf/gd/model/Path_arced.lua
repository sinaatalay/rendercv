-- Copyright 2014 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local Path = require 'pgf.gd.model.Path'

-- Imports

local Coordinate = require "pgf.gd.model.Coordinate"
local Transform  = require "pgf.gd.lib.Transform"



-- Locals

local rigid = Path.rigid

local tan = math.tan
local sin = math.sin
local cos = math.cos
local sqrt = math.sqrt
local atan2 = math.atan2
local abs = math.abs

local to_rad = math.pi/180
local to_deg = 180/math.pi
local pi_half = math.pi/2

local function sin_quarter(x)
  x = x % 360
  if x == 0 then
    return 0
  elseif x == 90 then
    return 1
  elseif x == 180 then
    return 0
  else
    return -1
  end
end

local function cos_quarter(x)
  x = x % 360
  if x == 0 then
    return 1
  elseif x == 90 then
    return 0
  elseif x == 180 then
    return -1
  else
    return 0
  end
end

local function atan2deg(y,x)

  -- Works like atan2, but returns the angle in degrees and, returns
  -- exactly a multiple of 90 if x or y are zero

  if x == 0 then
    if y < 0 then
      return -90
    else
      return 90
    end
  elseif y == 0 then
    if x < 0 then
      return 180
    else
      return 0
    end
  else
    return atan2(y,x) * to_deg
  end

end

local function subarc (path, startx, starty, start_angle, delta, radius, trans, center_x, center_y)

  local end_angle = start_angle + delta
  local factor = tan (delta*to_rad/4) * 1.333333333333333333333 * radius

  local s1, c1, s190, c190, s2, c2, s290, c290

  if start_angle % 90 == 0 then
    s1, c1, s190, c190 = sin_quarter(start_angle), cos_quarter(start_angle), sin_quarter(start_angle+90), cos_quarter(start_angle+90)
  else
    local a1 = start_angle*to_rad
    s1, c1, s190, c190 = sin(a1), cos(a1), sin(a1+pi_half), cos(a1+pi_half)
  end

  if end_angle % 90 == 0 then
    s2, c2, s290, c290 = sin_quarter(end_angle), cos_quarter(end_angle), sin_quarter(end_angle-90), cos_quarter(end_angle-90)
  else
    local a2 = end_angle * to_rad
    s2, c2, s290, c290 = sin(a2), cos(a2), sin(a2-pi_half), cos(a2-pi_half)
  end

  local lastx, lasty = center_x + c2*radius, center_y + s2*radius

  path[#path + 1] = "curveto"
  path[#path + 1] = Coordinate.new (startx + c190*factor, starty + s190*factor)
  path[#path + 1] = Coordinate.new (lastx  + c290*factor, lasty  + s290*factor)
  path[#path + 1] = Coordinate.new (lastx, lasty)

  if trans then
    path[#path-2]:apply(trans)
    path[#path-1]:apply(trans)
    path[#path  ]:apply(trans)
  end

  return lastx, lasty, end_angle
end



local function arc (path, start, start_angle, end_angle, radius, trans, centerx, centery)

  -- @param path is the path object
  -- @param start is the start coordinate
  -- @param start_angle is given in degrees
  -- @param end_angle is given in degrees
  -- @param radius is the radius
  -- @param trans is an optional transformation matrix that gets applied to all computed points
  -- @param centerx optionally: x-part of the center of the circle
  -- @param centery optionally: y-part of the center of the circle

  local startx, starty = start.x, start.y

  -- Compute center:
  centerx = centerx or startx - cos(start_angle*to_rad)*radius
  centery = centery or starty - sin(start_angle*to_rad)*radius

  if start_angle < end_angle then
    -- First, ensure that the angles are in a reasonable range:
    start_angle = start_angle % 360
    end_angle   = end_angle % 360

    if end_angle <= start_angle then
      -- In case the modulo has inadvertently moved the end angle
      -- before the start angle:
      end_angle = end_angle + 360
    end

    -- Ok, now create a series of arcs that are at most quarter-cycles:
    while start_angle < end_angle do
      if start_angle + 179 < end_angle then
        -- Add a quarter cycle:
        startx, starty, start_angle = subarc(path, startx, starty, start_angle, 90, radius, trans, centerx, centery)
      elseif start_angle + 90 < end_angle then
        -- Add 60 degrees to ensure that there are no small segments
        -- at the end
        startx, starty, start_angle = subarc(path, startx, starty, start_angle, (end_angle-start_angle)/2, radius, trans, centerx, centery)
      else
        subarc(path, startx, starty, start_angle, end_angle - start_angle, radius, trans, centerx, centery)
        break
      end
    end

  elseif start_angle > end_angle then
    -- First, ensure that the angles are in a reasonable range:
    start_angle = start_angle % 360
    end_angle   = end_angle % 360

    if end_angle >= start_angle then
      -- In case the modulo has inadvertedly moved the end angle
      -- before the start angle:
      end_angle = end_angle - 360
    end

    -- Ok, now create a series of arcs that are at most quarter-cycles:
    while start_angle > end_angle do
      if start_angle - 179 > end_angle then
        -- Add a quarter cycle:
        startx, starty, start_angle = subarc(path, startx, starty, start_angle, -90, radius, trans, centerx, centery)
      elseif start_angle - 90 > end_angle then
        -- Add 60 degrees to ensure that there are no small segments
        -- at the end
        startx, starty, start_angle = subarc(path, startx, starty, start_angle, (end_angle-start_angle)/2, radius, trans, centerx, centery)
      else
        subarc(path, startx, starty, start_angle, end_angle - start_angle, radius, trans, centerx, centery)
        break
      end
    end

  -- else, do nothing
  end
end


-- Doc see Path.lua

function Path:appendArc(start_angle,end_angle,radius, trans)

  local start = rigid(self[#self])
  assert(type(start) == "table", "trying to append an arc to a path that does not end with a coordinate")

  if trans then
    start = start:clone()
    start:apply(Transform.invert(trans))
  end

  arc (self, start, start_angle, end_angle, radius, trans)
end




-- Doc see Path.lua

function Path:appendArcTo (target, radius_or_center, clockwise, trans)

  local start = rigid(self[#self])
  assert(type(start) == "table", "trying to append an arc to a path that does not end with a coordinate")

  local trans_target = target
  local centerx, centery, radius

  if type(radius_or_center) == "number" then
    radius = radius_or_center
  else
    centerx, centery = radius_or_center.x, radius_or_center.y
  end

  if trans then
    start = start:clone()
    trans_target = target:clone()
    local itrans = Transform.invert(trans)
    start:apply(itrans)
    trans_target:apply(itrans)
    if centerx then
      local t = radius_or_center:clone()
      t:apply(itrans)
      centerx, centery = t.x, t.y
    end
  end

  if not centerx then
    -- Compute center
    local dx, dy = target.x - start.x, target.y - start.y

    if abs(dx) == abs(dy) and abs(dx) == radius then
      if (dx < 0 and dy < 0) or (dx > 0 and dy > 0) then
        centerx = start.x
        centery = trans_target.y
      else
        centerx = trans_target.x
        centery = start.y
      end
    else
      local l_sq = dx*dx + dy*dy
      if l_sq >= radius*radius*4*0.999999 then
        centerx = (start.x+trans_target.x) / 2
        centery = (start.y+trans_target.y) / 2
        assert(l_sq <= radius*radius*4/0.999999, "radius too small for arc")
      else
        -- Normalize
        local l = sqrt(l_sq)
        local nx = dx / l
        local ny = dy / l

        local e = sqrt(radius*radius - 0.25*l_sq)

        centerx = start.x + 0.5*dx - ny*e
        centery = start.y + 0.5*dy + nx*e
      end
    end
  end

  local start_dx, start_dy, target_dx, target_dy =
    start.x - centerx, start.y - centery,
    trans_target.x - centerx, trans_target.y - centery

  if not radius then
    -- Center is given, compute radius:
    radius_sq = start_dx^2 + start_dy^2

    -- Ensure that the circle is, indeed, centered:
    assert (abs(target_dx^2 + target_dy^2 - radius_sq)/radius_sq < 1e-5, "attempting to add an arc with incorrect center")

    radius = sqrt(radius_sq)
  end

  -- Compute start and end angle:
  local start_angle = atan2deg(start_dy, start_dx)
  local end_angle = atan2deg(target_dy, target_dx)

  if clockwise then
    if end_angle > start_angle then
      end_angle = end_angle - 360
    end
  else
    if end_angle < start_angle then
      end_angle = end_angle + 360
    end
  end

  arc (self, start, start_angle, end_angle, radius, trans, centerx, centery)

  -- Patch last point to avoid rounding problems:
  self[#self] = target
end



-- Done

return true
