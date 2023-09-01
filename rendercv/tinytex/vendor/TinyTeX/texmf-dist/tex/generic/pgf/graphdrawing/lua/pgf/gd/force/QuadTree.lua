-- Copyright 2011 by Jannis Pohlmann
-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


--- An implementation of a quad trees.
--
-- The class QuadTree provides methods form handling quadtrees.
--

local QuadTree = {
  -- Subclasses
  Particle = {},
  Cell = {}
}
QuadTree.__index = QuadTree

-- Namespace:
require("pgf.gd.force").QuadTree = QuadTree

-- Imports:
local Vector = require "pgf.gd.deprecated.Vector"
local lib = require "pgf.gd.lib"


--- Creates a new quad tree.
--
-- @return A newly-allocated quad tree.
--
function QuadTree.new(x, y, width, height, max_particles)
  local tree = {
    root_cell = QuadTree.Cell.new(x, y, width, height, max_particles)
  }
  setmetatable(tree, QuadTree)
  return tree
end



--- Inserts a particle
--
-- @param param A particle of type QuadTree.Particle
--
function QuadTree:insert(particle)
  self.root_cell:insert(particle)
end



--- Computes the interactions of a particle with other cells
--
-- @param particle A particle
-- @param test_func A test function, which on input of a cubical cell and a particle should
--                  decide whether the cubical cell should be inserted into the result
-- @param cells An optional array of cells, to which the found cells will be added
--
-- @return The cells array or a new array, if it was empty.
--
function QuadTree:findInteractionCells(particle, test_func, cells)
  local test_func = test_func or function (cell, particle) return true end
  cells = cells or {}

  self.root_cell:findInteractionCells(particle, test_func, cells)

  return cells
end




--- Particle subclass
QuadTree.Particle.__index = QuadTree.Particle



--- Creates a new particle.
--
-- @return A newly-allocated particle.
--
function QuadTree.Particle.new(pos, mass)
  local particle = {
    pos = pos:copy(),
    mass = mass or 1,
    subparticles = {},
  }
  setmetatable(particle, QuadTree.Particle)
  return particle
end



--- A cell of a quadtree
--
-- TT: Why is it called "cubical", by the way?!

QuadTree.Cell.__index = QuadTree.Cell



--- Creates a new cubicle cell.
--
-- @return a newly-allocated cubicle cell.
--
function QuadTree.Cell.new(x, y, width, height, max_particles)
  local cell = {
    x = x,
    y = y,
    width = width,
    height = height,
    max_particles = max_particles or 1,
    subcells = {},
    particles = {},
    center_of_mass = nil,
    mass = 0,
  }
  setmetatable(cell, QuadTree.Cell)
  return cell
end



function QuadTree.Cell:containsParticle(particle)
  return particle.pos.x >= self.x and particle.pos.x <= self.x + self.width
     and particle.pos.y >= self.y and particle.pos.y <= self.y + self.height
end



function QuadTree.Cell:findSubcell(particle)
  return lib.find(self.subcells, function (cell)
    return cell:containsParticle(particle)
  end)
end



function QuadTree.Cell:createSubcells()
  assert(type(self.subcells) == 'table' and #self.subcells == 0)
  assert(type(self.particles) == 'table' and #self.particles <= self.max_particles)

  if #self.subcells == 0 then
    for _,x in ipairs({self.x, self.x + self.width/2}) do
      for _,y in ipairs({self.y, self.y + self.height/2}) do
        local cell = QuadTree.Cell.new(x, y, self.width/2, self.height/2, self.max_particles)
        table.insert(self.subcells, cell)
      end
    end
  end
end



function QuadTree.Cell:insert(particle)
  -- check if we have a particle with the exact same position already
  local existing = lib.find(self.particles, function (other)
    return other.pos:equals(particle.pos)
  end)

  if existing then
    -- we already have a particle at the same position; splitting the cell
    -- up makes no sense; instead we add the new particle as a
    -- subparticle of the existing one
    table.insert(existing.subparticles, particle)
  else
    if #self.subcells == 0 and #self.particles < self.max_particles then
      table.insert(self.particles, particle)
    else
      if #self.subcells == 0 then
        self:createSubcells()
      end

      -- move particles to the new subcells
      for _,existing in ipairs(self.particles) do
        local cell = self:findSubcell(existing)
        assert(cell, 'failed to find a cell for particle ' .. tostring(existing.pos))
        cell:insert(existing)
      end

      self.particles = {}

      local cell = self:findSubcell(particle)
      assert(cell)
      cell:insert(particle)
    end
  end

  self:updateMass()
  self:updateCenterOfMass()

  assert(self.mass)
  assert(self.center_of_mass)
end



function QuadTree.Cell:updateMass()
  -- reset mass to zero
  self.mass = 0

  if #self.subcells == 0 then
    -- the mass is the number of particles of the cell
    for _,particle in ipairs(self.particles) do
      self.mass = self.mass + particle.mass
      for _,subparticle in ipairs(particle.subparticles) do
        self.mass = self.mass + subparticle.mass
      end
    end
  else
    -- the mass is the sum of the masses of the subcells
    for _,subcell in ipairs(self.subcells) do
      self.mass = self.mass + subcell.mass
    end
  end
end



function QuadTree.Cell:updateCenterOfMass()
  -- reset center of mass, assuming the cell is empty
  self.center_of_mass = nil

  if #self.subcells == 0 then
    -- the center of mass is the average position of the particles
    -- weighted by their masses
    self.center_of_mass = Vector.new (2)
    for _,p in ipairs(self.particles) do
      for _,sp in ipairs(p.subparticles) do
        self.center_of_mass = self.center_of_mass:plus(sp.pos:timesScalar(sp.mass))
      end
      self.center_of_mass = self.center_of_mass:plus(p.pos:timesScalar(p.mass))
    end
    self.center_of_mass = self.center_of_mass:dividedByScalar(self.mass)
  else
    -- the center of mass is the average of the weighted centers of mass
    -- of the subcells
    self.center_of_mass = Vector.new(2)
    for _,sc in ipairs(self.subcells) do
      if sc.center_of_mass then
        self.center_of_mass = self.center_of_mass:plus(sc.center_of_mass:timesScalar(sc.mass))
      else
        assert(sc.mass == 0)
      end
    end
    self.center_of_mass = self.center_of_mass:dividedByScalar(self.mass)
  end
end



function QuadTree.Cell:findInteractionCells(particle, test_func, cells)
  if #self.subcells == 0 or test_func(self, particle) then
    table.insert(cells, self)
  else
    for _,subcell in ipairs(self.subcells) do
      subcell:findInteractionCells(particle, test_func, cells)
    end
  end
end


function QuadTree.Cell:__tostring()
  return '((' .. self.x .. ', ' .. self.y .. ') '
      .. 'to (' .. self.x + self.width .. ', ' .. self.y + self.height .. '))'
      .. (self.particle and ' => ' .. self.particle.name or '')
      .. (self.center_of_mass and ' mass ' .. self.mass .. ' at ' .. tostring(self.center_of_mass) or '')
end



-- done

return QuadTree
