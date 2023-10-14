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
-- @section subsubsection {The Reingold--Tilford Layout}
--
-- @end

local ReingoldTilford1981 = {}

-- Imports
local layered = require "pgf.gd.layered"
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare
local Storage = require "pgf.gd.lib.Storage"

---
declare {
  key       = "tree layout",
  algorithm = ReingoldTilford1981,

  preconditions = {
    connected = true,
    tree      = true
  },

  postconditions = {
    upward_oriented = true
  },

  documentation_in = "pgf.gd.trees.doc"
}


---
declare {
  key    = "missing nodes get space",
  type   = "boolean",
  documentation_in = "pgf.gd.trees.doc"
}



---
declare {
  key     = "significant sep",
  type    = "length",
  initial = "0",
  documentation_in = "pgf.gd.trees.doc"
}


---
declare {
  key  = "binary tree layout",
  use = {
    { key = "tree layout" },
    { key = "minimum number of children" , value=2 },
    { key = "significant sep", value = 10 },
  },
  documentation_in = "pgf.gd.trees.doc"
}

---
declare {
  key = "extended binary tree layout",
  use = {
    { key = "tree layout" },
    { key = "minimum number of children" , value=2 },
    { key = "missing nodes get space" },
    { key = "significant sep", value = 0 },
  },
  documentation_in = "pgf.gd.trees.doc"
}




-- Now comes the implementation:

function ReingoldTilford1981:run()

  local root = self.spanning_tree.root

  local layers = Storage.new()
  local descendants = Storage.new()

  self.extended_version = self.digraph.options['missing nodes get space']

  self:precomputeDescendants(root, 1, layers, descendants)
  self:computeHorizontalPosition(root, layers, descendants)
  layered.arrange_layers_by_baselines(layers, self.adjusted_bb, self.ugraph)

end


function ReingoldTilford1981:precomputeDescendants(node, depth, layers, descendants)
  local my_descendants = { node }

  for _,arc in ipairs(self.spanning_tree:outgoing(node)) do
    local head = arc.head
    self:precomputeDescendants(head, depth+1, layers, descendants)
    for _,d in ipairs(descendants[head]) do
      my_descendants[#my_descendants + 1] = d
    end
  end

  layers[node] = depth
  descendants[node] = my_descendants
end



function ReingoldTilford1981:computeHorizontalPosition(node, layers, descendants)

  local children = self.spanning_tree:outgoing(node)

  node.pos.x = 0

  local child_depth = layers[node] + 1

  if #children > 0 then
    -- First, compute positions for all children:
    for i=1,#children do
      self:computeHorizontalPosition(children[i].head, layers, descendants)
    end

    -- Now, compute minimum distances and shift them
    local right_borders = {}

    for i=1,#children-1 do

      local local_right_borders = {}

      -- Advance "right border" of the subtree rooted at
      -- the i-th child
      for _,d in ipairs(descendants[children[i].head]) do
        local layer = layers[d]
        local x     = d.pos.x
        if self.extended_version or not (layer > child_depth and d.kind == "dummy") then
          if not right_borders[layer] or right_borders[layer].pos.x < x then
            right_borders[layer] = d
          end
          if not local_right_borders[layer] or local_right_borders[layer].pos.x < x then
            local_right_borders[layer] = d
          end
        end
      end

      local left_borders = {}
      -- Now left for i+1 st child
      for _,d in ipairs(descendants[children[i+1].head]) do
        local layer = layers[d]
        local x     = d.pos.x
        if self.extended_version or not (layer > child_depth and d.kind == "dummy") then
          if not left_borders[layer] or left_borders[layer].pos.x > x then
            left_borders[layer] = d
          end
        end
      end

      -- Now walk down the lines and try to find out what the minimum
      -- distance needs to be.

      local shift = -math.huge
      local first_dist = left_borders[child_depth].pos.x - local_right_borders[child_depth].pos.x
      local is_significant = false

      for layer,n2 in pairs(left_borders) do
        local n1 = right_borders[layer]
        if n1 then
          shift = math.max(
            shift,
            layered.ideal_sibling_distance(self.adjusted_bb, self.ugraph, n1, n2) + n1.pos.x - n2.pos.x
          )
        end
        if local_right_borders[layer] then
          if layer > child_depth and
            (left_borders[layer].pos.x - local_right_borders[layer].pos.x <= first_dist) then
            is_significant = true
          end
        end
      end

      if is_significant then
        shift = shift + self.ugraph.options['significant sep']
      end

      -- Shift all nodes in the subtree by shift:
      for _,d in ipairs(descendants[children[i+1].head]) do
        d.pos.x = d.pos.x + shift
      end
    end

    -- Finally, position root in the middle:
    node.pos.x = (children[1].head.pos.x + children[#children].head.pos.x) / 2
  end
end



return ReingoldTilford1981