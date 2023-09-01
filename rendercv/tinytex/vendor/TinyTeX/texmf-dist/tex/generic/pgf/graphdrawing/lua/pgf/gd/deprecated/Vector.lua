-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- Vector class
--
-- This class augments a normal array so that:
--
-- 1) Several functions like "plus" or "normalize" become available.
-- 2) You can access the ".x" and ".y" fields to get the fields [1] and [2].

local Vector = {}


-- Namespace:
local lib = require "pgf.gd.lib"
lib.Vector = Vector


-- Class setup
Vector.__index =
  function (t, k)
    if k == "x" then
      return rawget(t,1)
    elseif k == "y" then
      return rawget(t,2)
    else
      return rawget(Vector,k)
    end
  end
Vector.__newindex =
  function (t, k, v)
    if k == "x" then
      rawset(t,1,v)
    elseif k == "y" then
      rawset(t,2,v)
    else
      rawset(t,k,v)
    end
  end



--- Creates a new vector with \meta{n} values using an optional \meta{fill\_function}.
--
-- @param n             The number of elements of the vector. (If omitted, then 2.)
-- @param fill_function Optional function that takes a number between 1 and \meta{n}
--                      and is expected to return a value for the corresponding element
--                      of the vector. If omitted, all elements of the vector will
--                      be initialized with 0.
--
-- @return A newly-allocated vector with \meta{n} elements.
--
function Vector.new(n, fill_function)
  -- create vector
  local vector = { }
  setmetatable(vector, Vector)

  local n = n or 2

  if type(n) == 'table' then
    for k,v in pairs(n) do
      vector[k] = v
    end
  else
    -- fill vector elements with values
    if not fill_function then
      for i = 1,n do
        rawset(vector,i,0)
      end
    else
      for i = 1,n do
        rawset(vector,i,fill_function(i))
      end
    end
  end

  return vector
end



--- Creates a copy of the vector that holds the same elements as the original.
--
-- @return A newly-allocated copy of the vector holding exactly the same elements.
--
function Vector:copy()
  return Vector.new(#self, function (n) return self[n] end)
end



--- Performs a vector addition and returns the result in a new vector.
--
-- @param other The vector to add.
--
-- @return A new vector with the result of the addition.
--
function Vector:plus(other)
  assert(#self == #other)

  return Vector.new(#self, function (n) return self[n] + other[n] end)
end



--- Subtracts two vectors and returns the result in a new vector.
--
-- @param other Vector to subtract.
--
-- @return A new vector with the result of the subtraction.
--
function Vector:minus(other)
  assert(#self == #other)

  return Vector.new(#self, function (n) return self[n] - other[n] end)
end



--- Divides a vector by a scalar value and returns the result in a new vector.
--
-- @param scalar Scalar value to divide the vector by.
--
-- @return A new vector with the result of the division.
--
function Vector:dividedByScalar(scalar)
  return Vector.new(#self, function (n) return self[n] / scalar end)
end



--- Multiplies a vector by a scalar value and returns the result in a new vector.
--
-- @param scalar Scalar value to multiply the vector with.
--
-- @return A new vector with the result of the multiplication.
--
function Vector:timesScalar(scalar)
  return Vector.new(#self, function (n) return self[n] * scalar end)
end



--- Performs the dot product of two vectors and returns the result in a new vector.
--
-- @param other Vector to perform the dot product with.
--
-- @return A new vector with the result of the dot product.
--
function Vector:dotProduct(other)
  assert(#self == #other)

  local product = 0
  for n = 1,#self do
    product = product + self[n] * other[n]
  end
  return product
end



--- Computes the Euclidean norm of the vector.
--
-- @return The Euclidean norm of the vector.
--
function Vector:norm()
  return math.sqrt(self:dotProduct(self))
end



--- Normalizes the vector and returns the result in a new vector.
--
-- @return Normalized version of the original vector.
--
function Vector:normalized()
  local norm = self:norm()
  if norm == 0 then
    return Vector.new(#self)
  else
    return self:dividedByScalar(self:norm())
  end
end



--- Updates the values of the vector in-place.
--
-- @param update_function A function that is called for each element of the
--                        vector. The elements are replaced by the values
--                        returned from this function.
--
function Vector:update(update_function)
  for i=1,#self do
    self[i] = update_function(self[i])
  end
end



--- Limits all elements of the vector in-place.
--
-- @param limit_function A function that is called for each index/element
--                       pair. It is supposed to return minimum and maximum
--                       values for the element. The element is then clamped
--                       to these values.
--
function Vector:limit(limit_function)
  for i=1,#self do
    local min, max = limit_function(i, self[i])
    self[i] = math.max(min, math.min(max, value))
  end
end


--- Tests whether all elements of two vectors are the same
--
-- @param other The other vector
--
-- @return true or false
--
function Vector:equals(other)
  if #self ~= #other then
    return false
  end

  for n = 1, #self do
    if self[n] ~= other[n] then
      return false
    end
  end

  return true
end


function Vector:__tostring()
  return '(' .. table.concat(self, ', ') .. ')'
end





-- Done

return Vector
