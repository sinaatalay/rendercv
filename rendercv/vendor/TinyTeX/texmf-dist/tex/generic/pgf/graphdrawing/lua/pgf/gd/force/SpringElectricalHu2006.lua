-- Copyright 2011 by Jannis Pohlmann
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


local SpringElectricalHu2006 = {}

-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare




---

declare {
  key       = "spring electrical Hu 2006 layout",
  algorithm = SpringElectricalHu2006,

  preconditions = {
    connected = true,
    loop_free = true,
    simple    = true,
  },

  old_graph_model = true,

  summary = [["
    Implementation of a spring electrical graph drawing algorithm based on
    a paper by Hu.
  "]],
  documentation = [["
    \begin{itemize}
      \item
        Y. Hu.
        \newblock Efficient, high-quality force-directed graph drawing.
        \newblock \emph{The Mathematica Journal}, 2006.
    \end{itemize}

    There are some modifications compared to the original algorithm,
    see the Diploma thesis of Pohlmann for details.
  "]]
}

-- Imports

local PathLengths = require "pgf.gd.lib.PathLengths"
local Vector      = require "pgf.gd.deprecated.Vector"

local QuadTree    = require "pgf.gd.force.QuadTree"
local CoarseGraph = require "pgf.gd.force.CoarseGraph"

local lib = require "pgf.gd.lib"


function SpringElectricalHu2006:run()

  -- Setup properties
  local options = self.digraph.options

  self.iterations = options['iterations']
  self.cooling_factor = options['cooling factor']
  self.initial_step_length = options['initial step length']
  self.convergence_tolerance = options['convergence tolerance']

  self.natural_spring_length = options['node distance']
  self.spring_constant = options['spring constant']

  self.approximate_repulsive_forces = options['approximate remote forces']
  self.repulsive_force_order = options['electric force order']

  self.coarsen = options['coarsen']
  self.downsize_ratio = options['downsize ratio']
  self.minimum_graph_size = options['minimum coarsening size']

  -- Adjust types
  self.downsize_ratio = math.max(0, math.min(1, self.downsize_ratio))
  self.graph_size = #self.graph.nodes
  self.graph_density = (2 * #self.graph.edges) / (#self.graph.nodes * (#self.graph.nodes - 1))

  -- validate input parameters
  assert(self.iterations >= 0, 'iterations (value: ' .. self.iterations .. ') need to be greater than 0')
  assert(self.cooling_factor >= 0 and self.cooling_factor <= 1, 'the cooling factor (value: ' .. self.cooling_factor .. ') needs to be between 0 and 1')
  assert(self.initial_step_length >= 0, 'the initial step length (value: ' .. self.initial_step_length .. ') needs to be greater than or equal to 0')
  assert(self.convergence_tolerance >= 0, 'the convergence tolerance (value: ' .. self.convergence_tolerance .. ') needs to be greater than or equal to 0')
  assert(self.natural_spring_length >= 0, 'the natural spring dimension (value: ' .. self.natural_spring_length .. ') needs to be greater than or equal to 0')
  assert(self.spring_constant >= 0, 'the spring constant (value: ' .. self.spring_constant .. ') needs to be greater or equal to 0')
  assert(self.downsize_ratio >= 0 and self.downsize_ratio <= 1, 'the downsize ratio (value: ' .. self.downsize_ratio .. ') needs to be between 0 and 1')
  assert(self.minimum_graph_size >= 2, 'the minimum coarsening size of coarse graphs (value: ' .. self.minimum_graph_size .. ') needs to be greater than or equal to 2')

  -- initialize node weights
  for _,node in ipairs(self.graph.nodes) do
    if node:getOption('electric charge') ~= nil then
      node.weight = node:getOption('electric charge')
    else
      node.weight = 1
    end
  end

  -- initialize edge weights
  for _,edge in ipairs(self.graph.edges) do
    edge.weight = 1
  end

  -- initialize the coarse graph data structure. note that the algorithm
  -- is the same regardless whether coarsening is used, except that the
  -- number of coarsening steps without coarsening is 0
  local coarse_graph = CoarseGraph.new(self.graph)

  -- check if the multilevel approach should be used
  if self.coarsen then
    -- coarsen the graph repeatedly until only minimum_graph_size nodes
    -- are left or until the size of the coarse graph was not reduced by
    -- at least the downsize ratio configured by the user
    while coarse_graph:getSize() > self.minimum_graph_size
      and coarse_graph:getRatio() <= (1 - self.downsize_ratio)
    do
      coarse_graph:coarsen()
    end
  end

  if self.coarsen then
    -- use the natural spring length as the initial natural spring length
    local spring_length = self.natural_spring_length

    -- compute a random initial layout for the coarsest graph
    self:computeInitialLayout(coarse_graph.graph, spring_length)

    -- set the spring length to the average edge length of the initial layout
    spring_length = 0
    for _,edge in ipairs(coarse_graph.graph.edges) do
      spring_length = spring_length + edge.nodes[1].pos:minus(edge.nodes[2].pos):norm()
    end
    spring_length = spring_length / #coarse_graph.graph.edges

    -- additionally improve the layout with the force-based algorithm
    -- if there are more than two nodes in the coarsest graph
    if coarse_graph:getSize() > 2 then
      self:computeForceLayout(coarse_graph.graph, spring_length, SpringElectricalHu2006.adaptive_step_update)
    end

    -- undo coarsening step by step, applying the force-based sub-algorithm
    -- to every intermediate coarse graph as well as the original graph
    while coarse_graph:getLevel() > 0 do

      -- compute the diameter of the parent coarse graph
      local parent_diameter = PathLengths.pseudoDiameter(coarse_graph.graph)

      -- interpolate the previous coarse graph from its parent
      coarse_graph:interpolate()

      -- compute the diameter of the current coarse graph
      local current_diameter = PathLengths.pseudoDiameter(coarse_graph.graph)

      -- scale node positions by the quotient of the pseudo diameters
      for _,node in ipairs(coarse_graph.graph) do
        node.pos:update(function (n, value)
          return value * (current_diameter / parent_diameter)
        end)
      end

      -- compute forces in the graph
      self:computeForceLayout(coarse_graph.graph, spring_length, SpringElectricalHu2006.conservative_step_update)
    end
  else
    -- compute a random initial layout for the coarsest graph
    self:computeInitialLayout(coarse_graph.graph, self.natural_spring_length)

    -- set the spring length to the average edge length of the initial layout
    spring_length = 0
    for _,edge in ipairs(coarse_graph.graph.edges) do
      spring_length = spring_length + edge.nodes[1].pos:minus(edge.nodes[2].pos):norm()
    end
    spring_length = spring_length / #coarse_graph.graph.edges

    -- improve the layout with the force-based algorithm
    self:computeForceLayout(coarse_graph.graph, spring_length, SpringElectricalHu2006.adaptive_step_update)
  end
end



function SpringElectricalHu2006:computeInitialLayout(graph, spring_length)
  -- TODO how can supernodes and fixed nodes go hand in hand?
  -- maybe fix the supernode if at least one of its subnodes is
  -- fixated?

  -- fixate all nodes that have a 'desired at' option. this will set the
  -- node.fixed member to true and also set node.pos.x and node.pos.y
  self:fixateNodes(graph)

  if #graph.nodes == 2 then
    if not (graph.nodes[1].fixed and graph.nodes[2].fixed) then
      local fixed_index = graph.nodes[2].fixed and 2 or 1
      local loose_index = graph.nodes[2].fixed and 1 or 2

      if not graph.nodes[1].fixed and not graph.nodes[2].fixed then
        -- both nodes can be moved, so we assume node 1 is fixed at (0,0)
        graph.nodes[1].pos.x = 0
        graph.nodes[1].pos.y = 0
      end

      -- position the loose node relative to the fixed node, with
      -- the displacement (random direction) matching the spring length
      local direction = Vector.new{x = lib.random(1, spring_length), y = lib.random(1, spring_length)}
      local distance = 3 * spring_length * self.graph_density * math.sqrt(self.graph_size) / 2
      local displacement = direction:normalized():timesScalar(distance)

      graph.nodes[loose_index].pos = graph.nodes[fixed_index].pos:plus(displacement)
    else
      -- both nodes are fixed, initial layout may be far from optimal
    end
  else

    -- use a random positioning technique
    local function positioning_func(n)
      local radius = 3 * spring_length * self.graph_density * math.sqrt(self.graph_size) / 2
      return lib.random(-radius, radius)
    end

    -- compute initial layout based on the random positioning technique
    for _,node in ipairs(graph.nodes) do
      if not node.fixed then
        node.pos.x = positioning_func(1)
        node.pos.y = positioning_func(2)
      end
    end
  end
end



function SpringElectricalHu2006:computeForceLayout(graph, spring_length, step_update_func)
  -- global (=repulsive) force function
  function accurate_repulsive_force(distance, weight)
    -- note: the weight is taken into the equation here. unlike in the original
    -- algorithm different electric charges are allowed for each node in this
    -- implementation
    return - weight * self.spring_constant * math.pow(spring_length, self.repulsive_force_order + 1) / math.pow(distance, self.repulsive_force_order)
  end

  -- global (=repulsive, approximated) force function
  function approximated_repulsive_force(distance, mass)
    return - mass * self.spring_constant * math.pow(spring_length, self.repulsive_force_order + 1) / math.pow(distance, self.repulsive_force_order)
  end

  -- local (spring) force function
  function attractive_force(distance)
    return (distance * distance) / spring_length
  end

  -- define the Barnes-Hut opening criterion
  function barnes_hut_criterion(cell, particle)
    local distance = particle.pos:minus(cell.center_of_mass):norm()
    return cell.width / distance <= 1.2
  end

  -- fixate all nodes that have a 'desired at' option. this will set the
  -- node.fixed member to true and also set node.pos.x and node.pos.y
  self:fixateNodes(graph)

  -- adjust the initial step length automatically if desired by the user
  local step_length = self.initial_step_length == 0 and spring_length or self.initial_step_length

  -- convergence criteria etc.
  local converged = false
  local energy = math.huge
  local iteration = 0
  local progress = 0

  while not converged and iteration < self.iterations do
    -- remember old node positions
    local old_positions = lib.map(graph.nodes, function (node)
      return node.pos:copy(), node
    end)

    -- remember the old system energy and reset it for the current iteration
    local old_energy = energy
    energy = 0

    -- build the quadtree for approximating repulsive forces, if desired
    local quadtree = nil
    if self.approximate_repulsive_forces then
      quadtree = self:buildQuadtree(graph)
    end

    for _,v in ipairs(graph.nodes) do
      if not v.fixed then
        -- vector for the displacement of v
        local d = Vector.new(2)

        -- compute repulsive forces
        if self.approximate_repulsive_forces then
          -- determine the cells that have a repulsive influence on v
          local cells = quadtree:findInteractionCells(v, barnes_hut_criterion)

          -- compute the repulsive force between these cells and v
          for _,cell in ipairs(cells) do
            -- check if the cell is a leaf
            if #cell.subcells == 0 then
              -- compute the forces between the node and all particles in the cell
              for _,particle in ipairs(cell.particles) do
            local real_particles = lib.copy(particle.subparticles)
            table.insert(real_particles, particle)

            for _,real_particle in ipairs(real_particles) do
              local delta = real_particle.pos:minus(v.pos)

              -- enforce a small virtual distance if the node and the cell's
              -- center of mass are located at (almost) the same position
              if delta:norm() < 0.1 then
                delta:update(function (n, value) return 0.1 + lib.random() * 0.1 end)
              end

              -- compute the repulsive force vector
              local repulsive_force = approximated_repulsive_force(delta:norm(), real_particle.mass)
              local force = delta:normalized():timesScalar(repulsive_force)

              -- move the node v accordingly
              d = d:plus(force)
            end
              end
            else
              -- compute the distance between the node and the cell's center of mass
              local delta = cell.center_of_mass:minus(v.pos)

              -- enforce a small virtual distance if the node and the cell's
              -- center of mass are located at (almost) the same position
              if delta:norm() < 0.1 then
            delta:update(function (n, value) return 0.1 + lib.random() * 0.1 end)
              end

              -- compute the repulsive force vector
              local repulsive_force = approximated_repulsive_force(delta:norm(), cell.mass)
              local force = delta:normalized():timesScalar(repulsive_force)

              -- move the node v accordingly
              d = d:plus(force)
            end
          end
        else
          for _,u in ipairs(graph.nodes) do
            if v ~= u then
              -- compute the distance between u and v
              local delta = u.pos:minus(v.pos)

              -- enforce a small virtual distance if the nodes are
              -- located at (almost) the same position
              if delta:norm() < 0.1 then
            delta:update(function (n, value) return 0.1 + lib.random() * 0.1 end)
              end

              -- compute the repulsive force vector
              local repulsive_force = accurate_repulsive_force(delta:norm(), u.weight)
              local force = delta:normalized():timesScalar(repulsive_force)

              -- move the node v accordingly
              d = d:plus(force)
            end
          end
        end

        -- compute attractive forces between v and its neighbors
        for _,edge in ipairs(v.edges) do
          local u = edge:getNeighbour(v)

          -- compute the distance between u and v
          local delta = u.pos:minus(v.pos)

          -- enforce a small virtual distance if the nodes are
          -- located at (almost) the same position
          if delta:norm() < 0.1 then
            delta:update(function (n, value) return 0.1 + lib.random() * 0.1 end)
          end

          -- compute the spring force vector between u and v
          local attr_force = attractive_force(delta:norm())
          local force = delta:normalized():timesScalar(attr_force)

          -- move the node v accordingly
          d = d:plus(force)
        end

        -- really move the node now
        -- TODO note how all nodes are moved by the same amount  (step_length)
        -- while Walshaw multiplies the normalized force with min(step_length,
        -- d:norm()). could that improve this algorithm even further?
        v.pos = v.pos:plus(d:normalized():timesScalar(step_length))

        -- TODO Hu doesn't mention this but the energy of a particle is
        -- typically considered as the product of its mass and the square of
        -- its forces. This means we should probably take the weight of
        -- the node v into the equation, doesn't it?
        --
        -- update the energy function
        energy = energy + math.pow(d:norm(), 2)
	-- vector for the displacement of v
	local d = Vector.new(2)
	
	-- compute repulsive forces
	if self.approximate_repulsive_forces then
	  -- determine the cells that have a repulsive influence on v
	  local cells = quadtree:findInteractionCells(v, barnes_hut_criterion)
	  
	  -- compute the repulsive force between these cells and v
	  for _,cell in ipairs(cells) do
	    -- check if the cell is a leaf
	    if #cell.subcells == 0 then
	      -- compute the forces between the node and all particles in the cell
	      for _,particle in ipairs(cell.particles) do
		local real_particles = lib.copy(particle.subparticles)
		table.insert(real_particles, particle)
		
		for _,real_particle in ipairs(real_particles) do
		  local delta = real_particle.pos:minus(v.pos)
		  
		  -- enforce a small virtual distance if the node and the cell's 
		  -- center of mass are located at (almost) the same position
		  if delta:norm() < 0.1 then
		    delta:update(function (n, value) return 0.1 + lib.random() * 0.1 end)
		  end
		  
		  -- compute the repulsive force vector
		  local repulsive_force = approximated_repulsive_force(delta:norm(), real_particle.mass)
		  local force = delta:normalized():timesScalar(repulsive_force)
		  
		  -- move the node v accordingly
		  d = d:plus(force)
		end
	      end
	    else
	      -- compute the distance between the node and the cell's center of mass
	      local delta = cell.center_of_mass:minus(v.pos)
	      
	      -- enforce a small virtual distance if the node and the cell's 
	      -- center of mass are located at (almost) the same position
	      if delta:norm() < 0.1 then
		delta:update(function (n, value) return 0.1 + lib.random() * 0.1 end)
	      end
	      
	      -- compute the repulsive force vector
	      local repulsive_force = approximated_repulsive_force(delta:norm(), cell.mass)
	      local force = delta:normalized():timesScalar(repulsive_force)
	      
	      -- move the node v accordingly
	      d = d:plus(force)
	    end
	  end
	else
	  for _,u in ipairs(graph.nodes) do
	    if v ~= u then
	      -- compute the distance between u and v
	      local delta = u.pos:minus(v.pos)
	      
	      -- enforce a small virtual distance if the nodes are
	      -- located at (almost) the same position
	      if delta:norm() < 0.1 then
		delta:update(function (n, value) return 0.1 + lib.random() * 0.1 end)
	      end
	      
	      -- compute the repulsive force vector
	      local repulsive_force = accurate_repulsive_force(delta:norm(), u.weight)
	      local force = delta:normalized():timesScalar(repulsive_force)
	      
	      -- move the node v accordingly
	      d = d:plus(force)
	    end
	  end
	end
    
	-- compute attractive forces between v and its neighbours
	for _,edge in ipairs(v.edges) do
	  local u = edge:getNeighbour(v)
	  
	  -- compute the distance between u and v
	  local delta = u.pos:minus(v.pos)
	  
	  -- enforce a small virtual distance if the nodes are
	  -- located at (almost) the same position
	  if delta:norm() < 0.1 then
	    delta:update(function (n, value) return 0.1 + lib.random() * 0.1 end)
	  end
	  
	  -- compute the spring force vector between u and v
	  local attr_force = attractive_force(delta:norm())
	  local force = delta:normalized():timesScalar(attr_force)
	  
	  -- move the node v accordingly
	  d = d:plus(force)
	end
	
	-- really move the node now
	-- TODO note how all nodes are moved by the same amount  (step_length)
	-- while Walshaw multiplies the normalized force with min(step_length, 
	-- d:norm()). could that improve this algorithm even further?
	v.pos = v.pos:plus(d:normalized():timesScalar(step_length))
	
	-- TODO Hu doesn't mention this but the energy of a particle is 
	-- typically considered as the product of its mass and the square of 
	-- its forces. This means we should probably take the weight of
	-- the node v into the equation, doesn't it?
	--
	-- update the energy function
	energy = energy + math.pow(d:norm(), 2)
      end
    end

    -- update the step length and progress counter
    step_length, progress = step_update_func(step_length, self.cooling_factor, energy, old_energy, progress)

    -- compute the maximum node movement in this iteration
    local max_movement = 0
    for _,x in ipairs(graph.nodes) do
      local delta = x.pos:minus(old_positions[x])
      max_movement = math.max(delta:norm(), max_movement)
    end

    -- the algorithm will converge if the maximum movement is below a
    -- threshold depending on the spring length and the convergence
    -- tolerance
    if max_movement < spring_length * self.convergence_tolerance then
      converged = true
    end

    -- increment the iteration counter
    iteration = iteration + 1
  end
end



-- Fixes nodes at their specified positions.
--
function SpringElectricalHu2006:fixateNodes(graph)
  local number_of_fixed_nodes = 0

  for _,node in ipairs(graph.nodes) do
    -- read the 'desired at' option of the node
    local coordinate = node:getOption('desired at')

    if coordinate then
      -- apply the coordinate
      node.pos.x = coordinate.x
      node.pos.y = coordinate.y

      -- mark the node as fixed
      node.fixed = true

      number_of_fixed_nodes = number_of_fixed_nodes + 1
    end
  end
  if number_of_fixed_nodes > 1 then
     self.growth_direction = "fixed"  -- do not grow, orientation is now fixed
  end
end



function SpringElectricalHu2006:buildQuadtree(graph)
  -- compute the minimum x and y coordinates of all nodes
  local min_pos = graph.nodes[1].pos
  for _,node in ipairs(graph.nodes) do
    min_pos = Vector.new(2, function (n) return math.min(min_pos[n], node.pos[n]) end)
  end

  -- compute maximum x and y coordinates of all nodes
  local max_pos = graph.nodes[1].pos
  for _,node in ipairs(graph.nodes) do
    max_pos = Vector.new(2, function (n) return math.max(max_pos[n], node.pos[n]) end)
  end

  -- make sure the maximum position is at least a tiny bit
  -- larger than the minimum position
  if min_pos:equals(max_pos) then
    max_pos = max_pos:plus(Vector.new(2, function (n)
      return 0.1 + lib.random() * 0.1
    end))
  end

  -- make sure to make the quadtree area slightly larger than required
  -- in theory; for some reason Lua will otherwise think that nodes with
  -- min/max x/y coordinates are outside the box... weird? yes.
  min_pos = min_pos:minus({1,1})
  max_pos = max_pos:plus({1,1})

  -- create the quadtree
  quadtree = QuadTree.new(min_pos.x, min_pos.y,
                          max_pos.x - min_pos.x,
                          max_pos.y - min_pos.y)

  -- insert nodes into the quadtree
  for _,node in ipairs(graph.nodes) do
    local particle = QuadTree.Particle.new(node.pos, node.weight)
    particle.node = node
    quadtree:insert(particle)
  end

  return quadtree
end



function SpringElectricalHu2006.conservative_step_update(step, cooling_factor)
  return cooling_factor * step, nil
end



function SpringElectricalHu2006.adaptive_step_update(step, cooling_factor, energy, old_energy, progress)
  if energy < old_energy then
    progress = progress + 1
    if progress >= 5 then
      progress = 0
      step = step / cooling_factor
    end
  else
    progress = 0
    step = cooling_factor * step
  end
  return step, progress
end


-- done

return SpringElectricalHu2006
