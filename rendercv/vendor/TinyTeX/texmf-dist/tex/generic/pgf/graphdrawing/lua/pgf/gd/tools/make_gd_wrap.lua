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
-- This program generates a C wrap file around graph drawing
-- algorithms. The idea is that when you have a graph drawing
-- algorithm implemented in C and wish to invoke it from Lua, you need
-- a wrapper that manages the translation between Lua and C. This
-- program is intended to make it (reasonably) easy to produce such a
-- wrapper.



-- Sufficient number of arguments?

if #arg < 4 or arg[1] == "-h" or arg[1] == "-?" or arg[1] == "--help" then
  print([["
Usage: make_gd_wrap library1 library2 ... libraryn template library_name target_c_file

This program will read all of the graph drawing library files using
Lua's require. Then, it will iterate over all declared algorithm keys
(declared using declare { algorithm_written_in_c = ... }) and will
produce the code for library for the required target C files based on
the template.
"]])
  os.exit()
end


-- Imports

local InterfaceToDisplay = require "pgf.gd.interface.InterfaceToDisplay"
local InterfaceCore      = require "pgf.gd.interface.InterfaceCore"


-- Ok, setup:

InterfaceToDisplay.bind(require "pgf.gd.bindings.Binding")


-- Now, read all libraries:

for i=1,#arg-3 do
  require(arg[i])
end


-- Now, read the template:

local file = io.open(arg[#arg-2])
local template = file:read("*a")
file:close()

-- Let us grab the declaration:

local functions_dec     = (template:match("%$functions(%b{})") or ""):match("^{(.*)}$")
local functions_reg_dec = (template:match("%$functions_registry(%b{})") or ""):match("^{(.*)}$")
local factories_dec     = (template:match("%$factories(%b{})") or ""):match("^{(.*)}$")
local factories_reg_dec = (template:match("%$factories_registry(%b{})") or ""):match("^{(.*)}$")

-- Now, handle all keys with a algorithm_written_in_c field

local keys = InterfaceCore.keys
local filename = arg[#arg]
local target = arg[#arg-1]

local includes = {}
local functions = {}
local functions_registry = {}

local factories = {}
local factories_reg = {}

for _,k in ipairs(keys) do

  if k.algorithm_written_in_c and k.code then

    local library, fun_name = k.algorithm_written_in_c:match("(.*)%.(.*)")

    if target == library then
      -- First, gather the includes:
      if type(k.includes) == "string" then
        if not includes[k.includes] then
          includes[#includes + 1] = k.includes
          includes[k.includes]    = true
        end
      elseif type(k.includes) == "table" then
        for _,i in ipairs(k.includes) do
          if not includes[i] then
            includes[#includes + 1] = i
            includes[i] = true
          end
        end
      end

      -- Second, create a code block:
      functions[#functions+1] = functions_dec:gsub("%$([%w_]-)%b{}",
        {
          function_name = fun_name,
          function_body = k.code
        })

      -- Third, create functions_registry entry
      functions_registry[#functions_registry + 1] = functions_reg_dec:gsub("%$([%w_]-)%b{}",
        {
          function_name = fun_name,
          function_body = k.code
        })
    end
  end


  if k.module_class then

    -- First, gather the includes:
    if type(k.includes) == "string" then
      if not includes[k.includes] then
        includes[#includes + 1] = k.includes
        includes[k.includes]    = true
      end
    elseif type(k.includes) == "table" then
      for _,i in ipairs(k.includes) do
        if not includes[i] then
          includes[#includes + 1] = i
          includes[i] = true
        end
      end
    end

    -- Second, create a code block:
    factories[#factories+1] = factories_dec:gsub(
      "%$([%w_]-)%b{}",
      {
        factory_class = k.module_class,
        factory_code  = k.code,
        factory_base  = k.module_base,
        factory_name  = k.module_class .. '_factory'
      })

    -- Third, create factories_registry entry
    factories_reg[#factories_reg + 1] = factories_reg_dec:gsub(
      "%$([%w_]-)%b{}",
      {
        factory_class = k.module_class,
        factory_code  = k.code,
        factory_base  = k.module_base,
        factory_name  = k.module_class .. '_factory'
      })
  end
end


local file = io.open(filename, "w")

if not file then
  print ("failed to open file " .. filename)
  os.exit(-1)
end

file:write ((template:gsub(
  "%$([%w_]-)%b{}",
  {
    factories          = table.concat(factories, "\n\n"),
    factories_registry = table.concat(factories_reg, "\n"),
    functions          = table.concat(functions, "\n\n"),
    functions_registry = table.concat(functions_registry, "\n"),
    includes           = table.concat(includes, "\n"),
    library_c_name     = target:gsub("%.", "_"),
    library_name       = target
  })))
file:close()


