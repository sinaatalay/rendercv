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
-- Basic library functions

local lib = {}

-- Declare namespace

require("pgf.gd").lib = lib


-- General lib functions:


---
-- Finds the first value in the |array| for which |test| is true.
--
-- @param array  An array to search in.
-- @param test   A function that is applied to each element of the
--               array together with the index of the element and the
--               whole table.
--
-- @return The value of the first value where the test is true.
-- @return The index of the first value where the test is true.
-- @return The function value of the first value where the test is
--         true (only returned if test is a function).
--
function lib.find(array, test)
  for i=1,#array do
    local t = array[i]
    local result = test(t,i,array)
    if result then
      return t,i,result
    end
  end
end


---
-- Finds the first value in the |array| for which a function
-- returns a minimal value
--
-- @param array  An array to search in.
-- @param f      A function that is applied to each element of the
--               array together with the index of the element and the
--               whole table. It should return an integer and, possibly, a value.
--
-- Among all elements for which a non-nil integer is returned, let |i|
-- by the index of the element where this integer is minimal.
--
-- @return |array[i]|
-- @return |i|
-- @return The return value(s) of the function at |array[i]|.
--
function lib.find_min(array, f)
  local best = math.huge
  local best_result
  local best_index
  for i=1,#array do
    local t = array[i]
    local result, p = f(t,i,array)
    if result and p < best then
      best = p
      best_result = result
      best_index = i
    end
  end
  if best_index then
    return array[best_index],best_index,best_result,best
  end
end




---
-- Copies a table while preserving its metatable.
--
-- @param source The table to copy.
-- @param target The table to which values are to be copied or |nil| if a new
--               table is to be allocated.
--
-- @return The |target| table or a newly allocated table containing all
--         keys and values of the |source| table.
--
function lib.copy(source, target)
  if not target then
    target = {}
  end
  for key, val in pairs(source) do
    target[key] = val
  end
  return setmetatable(target, getmetatable(source))
end


---
-- Copies an array while preserving its metatable.
--
-- @param source The array to copy.
-- @param target The array to which values are to be copied or |nil| if a new
-- table is to be allocated. The elements of the
-- |source| array will be added at the end.
--
-- @return The |target| table or a newly allocated table containing all
--         keys and values of the |source| table.
--
function lib.icopy(source, target)
  target = target or {}
  for _, val in ipairs(source) do
    target[#target+1] = val
  end
  return setmetatable(target, getmetatable(source))
end




---
-- Apply a function to all pairs of a table, resulting in a new table.
--
-- @param source The table.
-- @param fun A function taking two arguments (|val| and |key|, in
-- that order). Should return two values (a |new_val| and a
-- |new_key|). This pair will be inserted into the new table. If,
-- however, |new_key| is |nil|, the |new_value| will be inserted at
-- the position |key|. This means, in particular, that if the |fun|
-- takes only a single argument and returns only a single argument,
-- you have a ``classical'' value mapper. Also note that if
-- |new_value| is |nil|, the value is removed from the table.
--
-- @return The new table.
--
function lib.map(source, fun)
  local target = {}
  for key, val in pairs(source) do
    local new_val, new_key = fun(val, key)
    if new_key == nil then
      new_key = key
    end
    target[new_key] = new_val
  end
  return target
end



---
-- Apply a function to all elements of an array, resulting in a new
-- array.
--
-- @param source The array.
-- @param fun A function taking two arguments (|val| and |i|, the
-- current index). This function is applied to all elements of the
-- array. The result of this function is placed at the end of a new
-- array, expect when the function returns |nil|, in which case the
-- element is skipped. If this function is not provided (is |nil|),
-- the identity function is used.
-- @param new The target array (if |nil|, a new array is create).
-- %
--\begin{codeexample}[code only]
--  local a = lib.imap(array, function(v) if some_test(v) then return v end end)
--\end{codeexample}
--
-- The above code is a filter that will remove all elements from the
-- array that do not pass |some_test|.
-- %
--\begin{codeexample}[code only]
--  lib.imap(a, lib.id, b)
--\end{codeexample}
--
-- The above code has the same effect as |lib.icopy(a,b)|.
--
-- @return The new array
--
function lib.imap(source, fun, new)
  if not new then
    new = { }
  end
  for i, v in ipairs(source) do
    new[#new+1] = fun(v, i)
  end
  return new
end


---
-- Generate a random permutation of the numbers $1$ to $n$ in time
-- $O(n)$. Knuth's shuffle is used for this.
--
-- @param n The desired size of the table
-- @return A random permutation

function lib.random_permutation(n)
  local p = {}
  for i=1,n do
    p[i] = i
  end
  for i=1,n-1 do
    local j = lib.random(i,n)
    p[i], p[j] = p[i], p[j]
  end
  return p
end


---
-- The identity function, so you can write |lib.id| instead of
-- |function (x) return x end|.
--

function lib.id(...)
  return ...
end



---
-- Tries to find an option in different objects that have an
-- options field.
--
-- This function iterates over all objects given as parameters. In
-- each, it tries to find out whether the options field of the object
-- contains the option |name| and, if so,
-- returns the value. The important point is that checking whether the
-- option table of an object contains the name field is done using
-- |rawget| for all but the last parameter. This means that when you
-- write
-- %
--\begin{codeexample}[code only]
--lib.lookup_option("foo", vertex, graph)
--\end{codeexample}
-- %
-- and if |/graph drawing/foo| has an initial value set, if the
-- parameter is not explicitly set in a vertex, you will get the value
-- set for the graph or, if it is not set there either, the initial
-- value. In contrast, if you write
-- %
--\begin{codeexample}[code only]
-- vertex.options["foo"] or graph.options["foo"]
--\end{codeexample}
-- %
-- what happens is that the first access to |.options| will
-- \emph{always} return something when an initial parameter has been
-- set for the option |foo|.
--
-- @param name   The name of the options
-- @param ...    Any number of objects. Each must have an options
--               field.
--
-- @return The found option

function lib.lookup_option(name, ...)
  local list = {...}
  for i=1,#list-1 do
    local o = list[i].options
    if o then
      local v = rawget(o, name)
      if v then
        return v
      end
    end
  end
  return list[#list].options[name]
end



---
-- Turns a table |t| into a class in the sense of object oriented
-- programming. In detail, this means that |t| is augmented by
-- a |new| function, which takes an optional table of |initial| values
-- and which outputs a new table whose metatable is the
-- class. The |new| function will call the function |constructor| if
-- it exists. Furthermore, the class object's |__index| is set to itself
-- and its meta table is set to the |base_class| field of the
-- table. If |t| is |nil|, a new table is created.
--
-- Here is a typical usage of this function:
-- %
--\begin{codeexample}[code only]
--local Point = lib.class {}
--
--function Point:length()
--  return math.sqrt(self.x*self.x + self.y*self.y)
--end
--
--local p = Point.new { x = 5, y = 6 }
--
--print(p:length())
--\end{codeexample}
-- %
-- We can subclass this as follows:
-- %
--\begin{codeexample}[code only]
--local Point3D = lib.class { base_class = Point }
--
--function Point3D:length()
--  local l = Point.length(self) -- Call base class's function
--  return math.sqrt(l*l + self.z*self.zdy)
--end
--
--local p = Point3D.new { x = 5, y = 6, z = 6 }
--
--print(p:length())
--\end{codeexample}
--
-- @param t A table that gets augmented to a class. If |nil|, a new
-- table is created.
-- @return The augmented table.

function lib.class(t)
  t = t or {}

  -- First, setup indexing, if necessary
  if not t.__index then
    t.__index = t
  end

  -- Second, setup new method, if necessary
  t.new = t.new or
    function (initial)

      -- Create new object
      local obj = {}
      for k,v in pairs(initial or {}) do
        obj[k] = v
      end
      setmetatable(obj, t)

      if obj.constructor then
        obj:constructor()
      end

      return obj
    end

  -- Third, setup inheritance, if necessary
  if not getmetatable(t) then
    setmetatable(t, t.base_class)
  end

  return t
end



---
-- Returns a method that is loaded only on demand for a class.
--
-- The idea behind this function is that you may have a class (or just
-- a table) for which some methods are needed only seldomly. In this
-- case, you can put these methods in a separate file and then use
-- |ondemand| to indicate that the methods are found in a
-- another file.
-- %
--\begin{codeexample}[code only]
-- -- File Foo.lua
-- local Foo = {}
-- function Foo.bar ()  ... end
-- function Foo.bar2 () ... end
-- Foo.bar3 = lib.ondemand("Foo_extra", Foo, "bar3")
-- Foo.bar4 = lib.ondemand("Foo_extra", Foo, "bar4")
--
-- return Foo
--
-- -- Foo_extra.lua
-- local Foo = require "Foo"
-- function Foo.bar3 () ... end
-- function Foo.bar4 () ... end
--\end{codeexample}
--
-- @param filename The name of the file when extra methods are
-- located.
-- @param table The table for which the missing functions should be
-- loaded when they are accessed.
-- @param method The name of the method.
--
-- @return A function that, when called, loads the filename using
-- |require| and, then, forwards the call to the method.

function lib.ondemand(filename, table, name)
  return function(...)
       require (filename)
       return table[name] (...)
     end
end



---
-- This implements the a random number generator similar to the one
-- provided by Lua, but based on the tex.uniformdeviate primitive to
-- avoid differences in random numbers due to platform specifics.
--
-- @param l Lower bound
-- @param u Upper bound
-- @return A random number
function lib.random(l,u)
  local fraction_one = 268435456
  local r = tex.uniform_rand(fraction_one)/fraction_one
  if l and u then
    assert(l <= u)
    return math.floor(r*(u-l+1)) + l
  elseif l then
    assert(1.0 <= l)
    return math.floor(r*l) + 1.0
  else
    return r
  end
end

---
-- Provide the seed for the random number generator
--
-- @param seed random seed
function lib.randomseed(seed)
  tex.init_rand(seed)
end

-- Done

return lib
