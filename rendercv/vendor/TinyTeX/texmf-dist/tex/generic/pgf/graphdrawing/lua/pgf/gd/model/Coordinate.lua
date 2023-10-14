-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


---
-- A Coordinate models a position on the drawing canvas.
--
-- It has an |x| field and a |y| field, which are numbers that will be
-- interpreted as \TeX\ points (1/72.27th of an inch). The $x$-axis goes
-- right and the $y$-axis goes up.
--
-- @field x
-- @field y
--
-- There is also a static field called |origin| that is always equal to the origin.

local Coordinate = {}
Coordinate.__index = Coordinate


-- Namespace

require("pgf.gd.model").Coordinate = Coordinate




--- Creates a new coordinate.
--
-- @param x The $x$ value
-- @param y The $y$ value
--
-- @return A coordinate
--
function Coordinate.new(x,y)
  return setmetatable( {x=x, y=y}, Coordinate)
end


Coordinate.origin = Coordinate.new(0,0)


--- Creates a new coordinate that is a copy of an existing one.
--
-- @return A new coordinate at the same location as |self|
--
function Coordinate:clone()
  return setmetatable( { x = self.x, y = self.y }, Coordinate)
end



--- Apply a transformation matrix to a coordinate,
-- see |pgf.gd.lib.Transform| for details.
--
-- @param t A transformation.

function Coordinate:apply(t)
  local x = self.x
  local y = self.y
  self.x = t[1]*x + t[2]*y + t[5]
  self.y = t[3]*x + t[4]*y + t[6]
end


--- Shift a coordinate
--
-- @param a An $x$ offset
-- @param b A $y$ offset

function Coordinate:shift(a,b)
  self.x = self.x + a
  self.y = self.y + b
end


---
-- ``Unshift'' a coordinate (which is the same as shifting by the
-- inversed coordinate; only faster).
--
-- @param a An $x$ offset
-- @param b A $y$ offset

function Coordinate:unshift(a,b)
  self.x = self.x - a
  self.y = self.y - b
end


---
-- Like |shift|, only for coordinate parameters.
--
-- @param c Another coordinate. The $x$- and $y$-values of |self| are
-- increased by the $x$- and $y$-values of this coordinate.

function Coordinate:shiftByCoordinate(c)
  self.x = self.x + c.x
  self.y = self.y + c.y
end


---
-- Like |unshift|, only for coordinate parameters.
--
-- @param c Another coordinate.

function Coordinate:unshiftByCoordinate(c)
  self.x = self.x - c.x
  self.y = self.y - c.y
end


---
-- Moves the coordinate a fraction of |f| along a straight line to |c|.
--
-- @param c Another coordinate
-- @param f A fraction

function Coordinate:moveTowards(c,f)
  self.x = self.x + f*(c.x-self.x)
  self.y = self.y + f*(c.y-self.y)
end



--- Scale a coordinate by a factor
--
-- @param s A factor.

function Coordinate:scale(s)
  self.x = s*self.x
  self.y = s*self.y
end




---
-- Add two coordinates, yielding a new coordinate. Note that it will
-- be a lot faster to call shift, whenever this is possible.
--
-- @param a A coordinate
-- @param b A coordinate

function Coordinate.__add(a,b)
  return setmetatable({ x = a.x + b.x, y = a.y + b.y }, Coordinate)
end


---
-- Subtract two coordinates, yielding a new coordinate. Note that it will
-- be a lot faster to call unshift, whenever this is possible.
--
-- @param a A coordinate
-- @param b A coordinate

function Coordinate.__sub(a,b)
  return setmetatable({ x = a.x - b.x, y = a.y - b.y }, Coordinate)
end


---
-- The unary minus (mirror the coordinate against the origin).
--
-- @param a A coordinate

function Coordinate.__unm(a)
  return setmetatable({ x = - a.x, y = - a.y }, Coordinate)
end


---
-- The multiplication operator. Its effect depends on the parameters:
-- If both are coordinates, their dot-product is returned. If exactly
-- one of them is a coordinate and the other is a number, the scalar
-- multiple of this coordinate is returned.
--
-- @param a A coordinate or a scalar
-- @param b A coordinate or a scalar
-- @return The dot product or scalar product.

function Coordinate.__mul(a,b)
  if getmetatable(a) == Coordinate then
    if getmetatable(b) == Coordinate then
      return a.x * b.x + a.y * b.y
    else
      return setmetatable({ x = a.x * b, y = a.y *b }, Coordinate)
    end
  else
    return setmetatable({ x = a * b.x, y = a * b.y }, Coordinate)
  end
end

---
-- The division operator. Returns the scalar division of a coordinate
-- by a scalar.
--
-- @param a A coordinate
-- @param b A scalar (not equal to zero).
-- @return The scalar product or a * (1/b).

function Coordinate.__div(a,b)
  return setmetatable({ x = a.x / b, y = a.y / b }, Coordinate)
end


---
-- The norm function. Returns the norm of a coordinate.
--
-- @param a A coordinate
-- @return The norm of the coordinate

function Coordinate:norm()
  return math.sqrt(self.x * self.x + self.y * self.y)
end


---
-- Normalize a vector: Ensure that it has length 1. If the vector used
-- to be the 0-vector, it gets replaced by (1,0).
--

function Coordinate:normalize()
  local x, y = self.x, self.y
  if x == 0 and y == 0 then
    self.x = 1
  else
    local norm = math.sqrt(x*x+y*y)
    self.x = x / norm
    self.y = y / norm
  end
end


---
-- Normalized version of a vector: Like |normalize|, only the result is
-- returned in a new vector.
--
-- @return Normalized version of |self|

function Coordinate:normalized()
  local x, y = self.x, self.y
  if x == 0 and y == 0 then
    return setmetatable({ x = 1, y = 0 }, Coordinate)
  else
    local norm = math.sqrt(x*x+y*y)
    return setmetatable({ x = x/norm, y = y/norm }, Coordinate)
  end
end



---
-- Compute a bounding box around an array of coordinates
--
-- @param array An array of coordinates
--
-- @return |min_x| The minimum $x$ value of the bounding box of the array
-- @return |min_y| The minimum $y$ value
-- @return |max_x|
-- @return |max_y|
-- @return |center_x| The center of the bounding box
-- @return |center_y|

function Coordinate.boundingBox(array)
  if #array > 0 then
    local min_x, min_y = math.huge, math.huge
    local max_x, max_y = -math.huge, -math.huge

    for i=1,#array do
      local c = array[i]
      local x = c.x
      local y = c.y
      if x < min_x then min_x = x end
      if y < min_y then min_y = y end
      if x > max_x then max_x = x end
      if y > max_y then max_y = y end
    end

    return min_x, min_y, max_x, max_y, (min_x+max_x) / 2, (min_y+max_y) / 2
  end
end




-- Returns a string representation of an arc. This is mainly for debugging
--
-- @return The Arc as string.
--
function Coordinate:__tostring()
  return "(" .. self.x .. "pt," .. self.y .. "pt)"
end


-- Done

return Coordinate