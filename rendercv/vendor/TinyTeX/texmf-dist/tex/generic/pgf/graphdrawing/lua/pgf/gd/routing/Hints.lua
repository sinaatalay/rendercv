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
-- The |Hints| class provides a way for graph drawing algorithms to
-- communicate certain possibilities concerning the routing of edges
-- to edge routing algorithms. This partly decouples the choice of the
-- vertex positioning algorithms from the choice of edge routing
-- algorithm. For instance, for a simple necklace routing, it is
-- unclear whether the edges on the necklace should be routing ``along
-- the necklace'' or not. Thus, necklace routing algorithms will
-- ``hint'' that a necklace is present and only when the
-- |necklace routing| algorithm is selected will these hints lead to
-- actual bending of edges.
--
-- For each kind of hint, there are methods in this class for creating
-- the hints and other methods for reading them. Hints are always
-- local to the ugraph.

local Hints = {}

-- Namespace
require("pgf.gd.routing").Hints = Hints

-- Imports
local Storage    = require("pgf.gd.lib.Storage")
local Coordinate = require("pgf.gd.model.Coordinate")




-- The necklace storage

local necklaces = Storage.new()


---
-- Adds a necklace hint. In this case, the hint indicates that the
-- given sequence of vertices lie on a circle.
--
-- The idea is that an algorithm may specify that in a
-- given graph certain sequences of nodes form a ``necklace'', which
-- is typically a circle. There may be more than one necklace inside a
-- given graph. For each necklace,
-- whenever an arc connects subsequent nodes on the necklace, they get
-- bend in such a way that they lie follow the path of the
-- necklace. If an arc lies on more than one necklace, the ``last one
-- wins''.
--
-- @param ugraph The ugraph to which this hint is added
-- @param necklace The sequence of vertices that form the necklace. If
-- the necklace is closed, the last vertex must equal the first one.
-- @param center If provided, must be |Coordinate| that specifies the
-- center of the circle on which the vertices lie. If not provided,
-- the origin is assumed.
-- @param clockwise If |true|, the vertices are in clockwise order,
-- otherwise in counter-clockwise order.

function Hints.addNecklaceCircleHint(ugraph, necklace, center, clockwise)
  local a = necklaces[ugraph] or {}
  necklaces[ugraph] = a

  a[#a+1] = {
    necklace  = necklace,
    center    = center or Coordinate.origin,
    clockwise = clockwise
  }
end


---
-- Gets the necklace hints.
--
-- This function will return an array whose entries are necklace
-- hints. Each entry in the array has a |necklace| field, which is the
-- field passed to the |addNecklaceXxxx| methods. For a circle
-- necklace, the |center| and |clockwise| fields will be set. (Other
-- necklaces are not yet implemented.)
--
-- @param ugraph The ugraph for which the necklace hints are
-- requested.
-- @return The array of necklaces as described above.

function Hints.getNecklaceHints(ugraph)
  return necklaces[ugraph] or {}
end

-- done

return Hints

