

local PlanarLayout = {}
require("pgf.gd.planar").PlanarLayout = PlanarLayout

-- imports
local Coordinate = require "pgf.gd.model.Coordinate"
local Storage = require "pgf.gd.lib.Storage"
local BoyerMyrvold = require "pgf.gd.planar.BoyerMyrvold2004"
local ShiftMethod = require "pgf.gd.planar.ShiftMethod"
local Embedding = require "pgf.gd.planar.Embedding"
local PDP = require "pgf.gd.planar.PDP"
local InterfaceToAlgorithms = require("pgf.gd.interface.InterfaceToAlgorithms")
local createEdge = InterfaceToAlgorithms.createEdge
local createVertex = InterfaceToAlgorithms.createVertex

InterfaceToAlgorithms.declare {
  key = "planar layout",
  algorithm = PlanarLayout,
  preconditions = {
    connected = true,
    loop_free = true,
    simple    = true,
  },
  postconditions = {
    fixed = true,
  },
  summary = [["
    The planar layout draws planar graphs without edge crossings.
  "]],
  documentation = [["
    The planar layout is a pipeline of algorithms to produce
    a crossings-free drawing of a planar graph.
    First a combinatorical embedding of the graph is created using
    the Algorithm from Boyer and Myrvold.
    The combinatorical Embedding is then being improved by
    by the Sort and Flip algorithm and triangulated afterwards.
    To determine the actual node positions the shift method
    by de Fraysseix, Pach and Pollack is used.
    Finally the force based Planar Drawing Postprocessing improves the drawing.
  "]],
  examples = {
    [["
      \tikz \graph [nodes={draw, circle}] {
          a -- {
              b -- {
                  d -- i,
                  e,
                  f
              },
              c -- {
                  g,
                  h
              }
          },
          f --[no span edge] a,
          h --[no span edge] a,
          i --[no span edge] g,
          f --[no span edge] g,
          c --[no span edge] d,
          e --[no span edge] c
      }
    "]]
  }
}

function PlanarLayout:run()
  --local file = io.open("timing.txt", "a")

  local options = self.digraph.options

  -- get embedding
  local bm = BoyerMyrvold.new()
  bm:init(self.ugraph)
  local embedding = bm:run()

  assert(embedding, "Graph is not planar")

  --local start = os.clock()
  if options["use sf"] then
    embedding:improve()
  end

  -- choose external face
  local exedge, exsize = embedding:get_biggest_face()

  -- surround graph with triangle
  local v1, v2, vn = embedding:surround_by_triangle(exedge, exsize)

  -- make maximal planar
  embedding:triangulate()

  if options["show virtual"] then
    -- add virtual vertices to input graph
    for _, vertex in ipairs(embedding.vertices) do
      if vertex.virtual then
        vertex.inputvertex = createVertex(self, {
          name = nil,--vertex.name,
          generated_options = {},
          text = vertex.name
        })
        vertex.virtual = false
      end
    end

    -- add virtual edges to input graph
    for _, vertex in ipairs(embedding.vertices) do
      for halfedge in Embedding.adjacency_iterator(vertex.link) do
        if halfedge.virtual then
          createEdge(
            self,
            vertex.inputvertex,
            halfedge.target.inputvertex
          )
        end
        halfedge.virtual = false
      end
    end
  end

  -- create canonical ordering
  local order = embedding:canonical_order(v1, v2, vn)

  local sm = ShiftMethod.new()
  sm:init(order)
  local gridpos = sm:run()

  local gridspacing = options["grid spacing"]
  for _, v in ipairs(order) do
    if not v.virtual then
      local iv = v.inputvertex
      iv.pos.x = gridpos[v].x * gridspacing
      iv.pos.y = gridpos[v].y * gridspacing
    end
  end

  embedding:remove_virtual()

  --start = os.clock()
  if options["use pdp"] then
    local pdp = PDP.new(
      self.ugraph, embedding,
      options["node distance"],
      options["node distance"],
      options["pdp cooling factor"],
      options["exponent change iterations"],
      options["start repulsive exponent"],
      options["end repulsive exponent"],
      options["start attractive exponent"],
      options["end attractive exponent"],
      options["edge approach threshold"],
      options["edge stretch threshold"],
      options["stress counter threshold"],
      options["edge divisions"]
    )
    pdp:run()
  end

end
