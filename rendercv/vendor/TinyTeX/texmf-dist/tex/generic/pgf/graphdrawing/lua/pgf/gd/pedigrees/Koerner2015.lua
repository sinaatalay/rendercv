-- Copyright 2015 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local Koerner2015 = {}


-- Namespace
require("pgf.gd.pedigrees").Koerner2015 = Koerner2015

-- Imports
local InterfaceToAlgorithms = require "pgf.gd.interface.InterfaceToAlgorithms"
local Storage               = require "pgf.gd.lib.Storage"
local Direct                = require "pgf.gd.lib.Direct"

-- Shorthand:
local declare = InterfaceToAlgorithms.declare


---
declare {
  key = "mate",
  type = "boolean",

  summary = [["
    Edges of type |mate| join mates.
  "]],
}


---
declare {
  key = "child",
  type = "boolean",

  summary = [["
    Edges of type |child| join a parent to a child. The parent is the tail
    of the edge, the child is the head.
  "]],
}

---
declare {
  key = "sibling",
  type = "boolean",

  summary = [["
    Edges of type |sibling| join a siblings (persons with identical parents).
  "]],
}


---
declare {
  key = "simple pedigree layout",
  algorithm = Koerner2015,

  postconditions = {
    upward_oriented = true
  },

  summary = [["
    A simple algorithm for drawing a pedigree.
  "]],
  documentation = [["
      ...
  "]],
  examples = [["
    \tikz \graph [simple pedigree layout, default edge operator=complete bipartite]
    {
      Eve -- [mate] Felix;
      { Eve, Felix } -> [child] { George, Hank };

      Alice -- [mate] Bob;
      { Alice, Bob } -> [child] { Charly, Dave, Eve };
    };
  "]]
}


function Koerner2015:run()

  local g = self.digraph

  -- Compute ranks:

  local visited = {}
  local ranks = {}

  local queue = { { g.vertices[1], 1 } }

  local queue_start = 1
  local queue_end   = 1

  local function put(v, r)
    queue_end = queue_end + 1
    queue [queue_end] = { v, r }
  end

  local function get()
    local v = queue[queue_start][1]
    local r = queue[queue_start][2]
    queue_start = queue_start + 1
    return v,r
  end

  while queue_start <= queue_end do

    -- Pop
    local v, rank = get()
    ranks[v] = rank

    visited [v] = true

    -- Follow mates:
    for _,a in ipairs(g:outgoing(v)) do
      if a:options("sibling") then
        if not visited[a.head] then
          put(a.head, rank)
        end
      end
    end
    for _,a in ipairs(g:incoming(v)) do
      if a:options("child") then
        if not visited[a.tail] then
          put(a.tail, rank-1)
        end
      end
    end
    for _,a in ipairs(g:outgoing(v)) do
      if a:options("child") then
        if not visited[a.head] then
          put(a.head, rank+1)
        end
      end
    end
    for _,a in ipairs(g:outgoing(v)) do
      if a:options("mate") then
        if not visited[a.head] then
          put(a.head, rank)
        end
      end
    end
  end

  for i,v in ipairs(g.vertices) do
    v.pos.x = i*50
    v.pos.y = ranks[v] * 50
  end

end

return Koerner2015


