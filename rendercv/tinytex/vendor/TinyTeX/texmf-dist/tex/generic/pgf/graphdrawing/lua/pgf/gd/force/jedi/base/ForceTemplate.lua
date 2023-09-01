-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- This is the parent class for forces. It provides a constructor and methods
-- stubs to be overwritten in the subclasses.

-- Imports
local lib = require "pgf.gd.lib"

local ForceTemplate = lib.class {}

-- constructor
function ForceTemplate:constructor()
  self.force = self.force
  self.fw_attributes = self.fw_attributes
  if not self.force.time_fun then
    self.force.time_fun = function() return 1 end
  end
end

-- Method stub for preprocessing
--
-- @param v The vertices the list will be build on

function ForceTemplate:preprocess(v)
end

-- Method stub for applying the forces
--
-- @param data A table holding data like the table the forces are  collected
--             in, the current iteration, the current time stamp, some options
--             or the natural spring length

function ForceTemplate:applyTo(data)
end

return ForceTemplate