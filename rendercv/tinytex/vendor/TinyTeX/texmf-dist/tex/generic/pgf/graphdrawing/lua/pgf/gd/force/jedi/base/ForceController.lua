-- Copyright 2014 by Ida Bruhns
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


--- This class is the most basic class for the Jedi framework. It manages the
-- forces, epochs, options and streamlines the graph drawing process.
-- In detail, the force template will do the following:
-- %
-- \begin{itemize}
--   \item Hold the table with all epochs currently defined, and provide
--     a function to add new ones
--   \item Hold the table associating forces with the epochs, and provide a
--     function to add new ones
--   \item Define all the non-algorithm-specific options provided by Jedi
--   \item Assert user options to catch exceptions
--   \item Save user options and library functions to local variables to enhance
--     runtime.
--   \item Add any forces that are indicated by set options
--   \item Find and call the initial positioning algorithm requested
--   \item Determine if coarsening is enabled, and manage coarsening process if so
--   \item Call the preprocessing function of each force to obtain a vertex list the
--     force will be applied to
--   \item Calculate the forces affecting each vertex.
--   \item Move the vertices, check for equilibria/used up iterations, update
--     virtual time
-- \end{itemize}

local ForceController = {}
ForceController.__index = ForceController

-- Imports
local declare = require "pgf.gd.interface.InterfaceToAlgorithms".declare
local Coordinate = require "pgf.gd.model.Coordinate"
local CoarseGraph = require 'pgf.gd.force.jedi.base.CoarseGraphFW'
local PriorityQueue = require "pgf.gd.lib.PriorityQueue"
local ForcePullToPoint = require "pgf.gd.force.jedi.forcetypes.ForcePullToPoint"
local ForcePullToGrid = require "pgf.gd.force.jedi.forcetypes.ForcePullToGrid"

local epochs = {
  [1] = "preprocessing",
  [2] = "initial layout",
  [3] = "start coarsening process",
  [4] = "before coarsen",
  [5] = "start coarsen",
  [6] = "during coarsen",
  [7] = "end coarsen",
  [8] = "before expand",
  [9] = "start expand",
  [10] = "during expand",
  [11] = "end expand",
  [12] = "end coarsening process",
  [13] = "after expand",
  [14] = "postprocessing"
}

-- Automatic parameter generation for epoch-variables
for _,e in ipairs(epochs) do
  ---
  declare {
    key = "iterations " .. e,
    type = "number"
  }

  ---
  declare {
    key = "maximum displacement per step " .. e,
    type = "number"
  }

 ---
  declare {
    key = "global speed factor " .. e,
    type = "length"
  }

  ---
  declare {
    key = "maximum time " .. e,
    type = "number"
  }

  ---
  declare {
    key = "find equilibrium ".. e,
    type = "boolean"
  }

  ---
  declare {
    key = "equilibrium threshold ".. e,
    type = "number"
  }
end

-- Implementation starts here

--- Function allowing user to add an at the specified position
--
-- @params epoch A string that names the epoch
-- @params position The position in the epoch array at which the epoch should be inserted

function ForceController:addEpoch(epoch, position)
  table.insert(epochs, position, epoch)
end

--- Function allowing the user to find an epoch's position in the epoch table
--
-- @params epoch The epoch who's position we are trying to find
--
-- @return An integer value matching the epch's index, or $-1$ if epoch was not found

function ForceController:findEpoch(epoch)
  for j, e in ipairs(epochs) do
    if e == epoch then
      return j
    end
  end
  return -1
end


-- locals for performance
local net_forces = {}
local sqrt = math.sqrt
local abs = math.abs
local sum_up, options, move_vertices, get_net_force, preprocessing, epoch_forces

--- Creating a new force algorithm
-- @params ugraph The ugraph object the graph drawing algorithm will run on
-- @params fw_attributes The storage object holding the additional attributes defined by
--         the engineer
--
-- @returns A new instance of force template
function ForceController.new(ugraph, fw_attributes)
  return setmetatable(
  {epoch_forces = {},
    ugraph              = ugraph,
    fw_attributes       = fw_attributes,
    pull_to_point       = false,
  }, ForceController)
end

--- Running the force algorithm

function ForceController:run()
  -- locals for performance
  local ugraph = self.ugraph
  local coarse_graph = CoarseGraph.new(ugraph, self.fw_attributes)
  local vertices_initalized = false
  options = ugraph.options
  epoch_forces = self.epoch_forces
  local minimum_graph_size = options["minimum coarsening size"]
  local vertices = ugraph.vertices
  local arcs = ugraph.arcs
  local downsize_ratio = options["downsize ratio"]
  local natural_spring_length = options["node distance"]
  local snap_to_grid = options["snap to grid"]
  local coarsen = options["coarsen"]

  -- Assert user input
  assert(minimum_graph_size >= 2, 'the minimum coarsening size of coarse graphs (value: ' .. minimum_graph_size .. ') needs to be greater than or equal to 2')
  assert(downsize_ratio >= 0 and downsize_ratio <=1, 'the downsize ratio of the coarse graphs (value: ' .. downsize_ratio .. ') needs to be greater than or equal to 0 and smaller than or equal to 1')
  assert(natural_spring_length >= 0, 'the node distance (value: ' .. natural_spring_length .. ') needs to be greater than or equal to 0')

  -- initialize vertex and arc weights
  for _,vertex in ipairs(vertices) do
    vertex.weight = vertex.options["coarsening weight"]
    vertex.mass = vertex.options.mass
  end

  for _,arc in ipairs(arcs) do
    arc.weight = 1
  end

  -- Initialize epoch_forces table entries as empty tables
  for _, e in ipairs(epochs) do
    if not self.epoch_forces[e] then
      self.epoch_forces[e] = {}
    end
  end

  -- Find initial positioning algorithm
  local initial_positioning_class = options.algorithm_phases['initial positioning force framework'] -- initial_types[self.initial_layout]

  -- If snap to grid option is set and no force was added yet, add an extra
  -- force to post-processing
  if snap_to_grid then
    self:addForce{
      force_type = ForcePullToGrid,
      cap = 1,
      time_fun = function() return 40 end,
      epoch = {"postprocessing"}
    }
    options["iterations postprocessing"] = options["iterations postprocessing"] or 200
    options["maximum time postprocessing"] = options["maximum time postprocessing"] or 200
    options["find equilibrium postprocessing"] = options["find equilibrium postprocessing"] or true
    options["equilibrium threshold postprocessing"] = options["equilibrium threshold postprocessing"] or 1
    options["maximum displacement per step postprocessing"] = options["maximum displacement per step postprocessing"] or 1
    options["global speed factor postprocessing"] = options["global speed factor postprocessing"] or 1
  end

  -- Find marker epochs
  local start_coarsening = self:findEpoch("start coarsening process")
  local end_coarsening = self:findEpoch("end coarsening process")
  local start_coarsen = self:findEpoch("start coarsen")
  local end_coarsen = self:findEpoch("end coarsen")
  local start_expand = self:findEpoch("start expand")
  local end_expand = self:findEpoch("end expand")


  -- iterate over epoch table
  local i = 1
  while i <= #epochs do
    local e = epochs[i]

    local iterations = options["iterations "..e] or options["iterations"]
    -- assert input
    assert(iterations >= 0, 'iterations (value: ' .. iterations .. ') needs to be greater than 0')

    -- Check for desired vertices and collect them in a table if any are found
    local desired = false
    local desired_vertices = {}
    -- initialize node weights
    for _,vertex in ipairs(vertices) do
      if vertex.options then
        if vertex.options["desired at"] then
          desired = true
          desired_vertices[vertex] = vertex.options["desired at"]
        end
      end
    end

    -- Add pull to point force if desired vertices were found and engineer did not add
    -- this force
    if desired and not self.pull_to_point then
      self:addForce{
        force_type = ForcePullToPoint,
        time_fun   = function(t_now, t_max) return 5 end
      }
    end

    -- initialize the coarse graph data structure.
    if coarsen then
      -- vertices = coarse_graph.ugraph.vertices
      -- arcs = coarse_graph.ugraph.arcs
      if i >= start_coarsening and i < end_coarsening then
        -- coarsen the graph repeatedly until only minimum_graph_size nodes
        -- are left or until the size of the coarse graph was not reduced by
        -- at least the downsize ratio configured by the user
        if i >= start_coarsen and i < start_expand then
          if coarse_graph:getSize() > minimum_graph_size and coarse_graph:getRatio() <= (1 - downsize_ratio) then
            if i == start_coarsen then
              coarse_graph:coarsen()
            elseif i < end_coarsen then
              preprocessing(coarse_graph.ugraph.vertices, coarse_graph.ugraph.arcs, e, coarse_graph.ugraph)
              move_vertices(coarse_graph.ugraph.vertices, e)
            else
              i = start_coarsen - 1
            end
          end
        end

        -- between coarsening and expanding
        if (i > end_coarsen) and (i < start_expand) then
          -- use the natural spring length as the initial natural spring length
          local spring_length = natural_spring_length

          if not vertices_initalized then
            initial_positioning_class.new { vertices = coarse_graph.ugraph.vertices,
                                            options = options,
                                            desired_vertices = desired_vertices
                                          }:run()
            vertices_initalized = true
          end

          preprocessing(coarse_graph.ugraph.vertices, coarse_graph.ugraph.arcs, e, coarse_graph.ugraph)

          -- set the spring length to the average arc length of the initial layout
          local spring_length = 0
          for _,arc in ipairs(arcs) do
            local x = abs(arc.head.pos.x - arc.tail.pos.x)
            local y = abs(arc.head.pos.y - arc.tail.pos.y)
            spring_length = spring_length + sqrt(x * x + y * y)
          end
          spring_length = spring_length / #arcs

          -- additionally improve the layout with the force-based algorithm
          -- if there are more than two nodes in the coarsest graph
          if coarse_graph:getSize() > 2 and end_coarsen and not start_expand then
            move_vertices(coarse_graph.ugraph.vertices, e)
          end
        end

        -- undo coarsening step by step, applying the force-based sub-algorithm
        -- to every intermediate coarse graph as well as the original graph
        if i >= start_expand then
          if coarse_graph:getLevel() > 0 then
            if i == start_expand then
              coarse_graph:uncoarsen()
            elseif i < end_expand then
              preprocessing(coarse_graph.ugraph.vertices, coarse_graph.ugraph.arcs, e, coarse_graph.ugraph)
              move_vertices(coarse_graph.ugraph.vertices, e)
            else
              i = start_expand - 1
            end
          else
            preprocessing(coarse_graph.ugraph.vertices, coarse_graph.ugraph.arcs, e, coarse_graph.ugraph)
            move_vertices(coarse_graph.ugraph.vertices, e)
          end
        end
      -- Before and after the coarsening process
      elseif i < start_coarsening or i > end_coarsening then
        if not vertices_initalized then
          initial_positioning_class.new {
            vertices = coarse_graph.ugraph.vertices,
            options = options,
            desired_vertices = desired_vertices }:run()
          vertices_initalized = true
        end
        preprocessing(coarse_graph.ugraph.vertices, coarse_graph.ugraph.arcs, e, coarse_graph.ugraph)
        move_vertices(coarse_graph.ugraph.vertices, e)
      end
    else
      -- Same without coarsen
      if i < start_coarsening or i > end_coarsening then
        if not vertices_initalized then
          initial_positioning_class.new {
            vertices = vertices,
            options = options,
            desired_vertices = desired_vertices }:run()
          vertices_initalized = true
        end
        preprocessing(vertices, arcs, e, ugraph)
        move_vertices(vertices, e, self.ugraph)
      end
    end
    i = i + 1
  end
end


--- Preprocessing for all force types in force configuration
--
-- @params v The vertices of the current graph
-- @params a The arcs of the current graph
-- @params epoch The preprocessing algorithm will only be applied to the forces
--                associated with this epoch.
-- @params ugraph The current graph object

function preprocessing(v, a, epoch, ugraph)
  for _, fc in ipairs(epoch_forces[epoch]) do
    fc:preprocess(v, a, ugraph)
  end
end


--- Adding forces to the algorithm.
--
-- @params force_data A table containing force type, time function, force function,
--                    capping thresholds and the epochs in which this force will be active

function ForceController:addForce(force_data)
  local t = force_data.force_type
  if t == ForcePullToPoint then
    self.pull_to_point = true
  end

  local f = t.new {force = force_data, options = self.ugraph.options, fw_attributes = self.fw_attributes or {}}
  if force_data.epoch == nil then
    force_data.epoch = {}
  end
  for _,e in ipairs(force_data.epoch) do
    local tab = self.epoch_forces[e]
    if not tab then
      tab = {}
    end
    tab[#tab +1] = f
    self.epoch_forces[e] = tab
  end
end


--- Moving vertices according to force functions until the maximum number of
-- iterations is reached
--
-- @params vertices The vertices in the current graph
-- @params epoch The current epoch, to find the forces that are active

function move_vertices(vertices, epoch, g)
  if #epoch_forces[epoch] == 0 then
    return
  end
  local iterations = options["iterations ".. epoch] or options["iterations"]
  local find_equilibrium = options["find equilibrium ".. epoch] or options["find equilibrium"]
  local epsilon = options["equilibrium threshold ".. epoch] or options["equilibrium threshold"]
  local speed = options["global speed factor ".. epoch] or options["global speed factor"]
  local max_step = options["maximum displacement per step ".. epoch] or options["maximum displacement per step"]

  assert(epsilon >= 0, 'the threshold for finding an equilibirum (equilibrium threshold) (value: ' .. epsilon .. ') needs to be greater than or equal to 0')
  assert(speed > 0, 'the speed at which the vertices move (value: ' .. speed .. ') needs to be greater than 0')
  assert(max_step > 0, 'the maximum displacement per step each vertex can move per iteration (value: ' .. max_step .. ') needs to be greater than 0')

  local max_time = options["maximum time ".. epoch] or options["maximum time"]
  local d_t = max_time/iterations
  local t_now = 0
  local random = lib.random
  local randomseed = lib.randomseed

  for j = 1 , iterations do
    t_now = t_now + d_t
    net_forces =  get_net_force(vertices, j, t_now, epoch)

    -- normalize the force vector if necessary
    for v, c in pairs(net_forces) do
      local n = sqrt(c.x*c.x+c.y*c.y)
      if n > max_step then
        local factor = max_step/n
        c.x = c.x*factor
        c.y = c.y*factor
      end
    end

    -- if not in equilibrium yet, apply forces
    if not find_equilibrium or sum_up(net_forces)*d_t > epsilon then
      local cool_down_dt = d_t
      if cool_down_dt > 1 then
        cool_down_dt = 1 + 1/d_t
      end
      for _, v in ipairs(vertices) do
        local factor = 1/(v.mass or 1)
        local c1 = net_forces[v]
        local x = speed * cool_down_dt * c1.x * factor
        local y = speed * cool_down_dt * c1.y * factor
        local p = v.pos
        p.x = p.x + x
        p.y = p.y + y
      end
    else
      break
    end
  end
end


-- calculate the net force for each vertex in one iteration
--
-- @params vertices the vertices of the current graph
-- @params j The current iteration
-- @params t_now The current virtual time
-- @params epoch The current epoch
--
-- @return A table of coordinate-objects associated with vertices. The
--          coordinate object hold the calculated net displacement for
--          the $x$ and $y$ coordinate.
function get_net_force(vertices, j, t_now, epoch)
  local net_forces = {}
  local natural_spring_length = options["node distance"]

  for _,v in ipairs(vertices) do
    net_forces[v] = Coordinate.new(0,0)
  end

  for _,force_class in ipairs(epoch_forces[epoch]) do
    force_class:applyTo{net_forces = net_forces, options = options, j = j, t_now = t_now, k = natural_spring_length}
  end

  return net_forces
end

-- Helper function to sum up all calculated forces
--
-- @params tab A table holding coordinate objects as values
--
-- @returns The sum of the absolute $x$ and $y$ values in this table
function sum_up(tab)
  local sum = 0
  for v, c in pairs(tab) do
    sum = sum + abs(c.x) + abs(c.y)
  end
  return sum
end

return ForceController
