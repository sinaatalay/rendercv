-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare

declare {
  key = "use pdp",
  type = "boolean",
  initial = "true",

  summary = [["
    Whether or not to use the Planar Drawing Postprocessing
    to improve the drawing.
  "]]
}

declare {
  key = "use sf",
  type = "boolean",
  initial = "true",

  summary = [["
    Whether or not to use the Sort and Flip Algorithm
    to improve the combinatorical embedding.
    "]]
}

declare {
  key = "grid spacing",
  type = "number",
  initial = "10",

  summary = [["
    If the |use pdp| option is not set,
    this sets the spacing of the grid used by the shift method.
    A bigger grid spacing will result in a bigger drawing.
  "]]
}

declare {
  key = "pdp cooling factor",
  type = "number",
  initial = "0.98",

  summary = [["
    This sets the cooling factor used by the Planar Drawing Postprocessing.
    A higher cooling factor can result in better quality of the drawing,
    but will increase the run time of the algorithm.
  "]]
}

declare {
  key = "start repulsive exponent",
  type = "number",
  initial = "2",

  summary = [["
    Start value of the exponent used in the calculation of all repulsive forces in PDP
  "]]
}

declare {
  key = "end repulsive exponent",
  type = "number",
  initial = "2",

  summary = [["
    End value of the exponent used in the calculation of all repulsive forces in PDP.
  "]]
}

declare {
  key = "start attractive exponent",
  type = "number",
  initial = "2",

  summary = [["
    Start value of the exponent used in PDP's calculation of the attractive force between
    nodes connected by an edge.
  "]]
}

declare {
  key = "end attractive exponent",
  type = "number",
  initial = "2",

  summary = [["
    End value of the exponent used in PDP's calculation of the attractive force between
    nodes connected by an edge.
  "]]
}

declare {
  key = "exponent change iterations",
  type = "number",
  initial = "1",

  summary = [["
    The number of iterations over which to modify the force exponents.
    In iteration one the exponents will have their start value and in iteration
    |exponent change iterations| they will have their end value.
  "]]
}

declare {
  key = "edge approach threshold",
  type = "number",
  initial = "0.3",

  summary = [["
    The maximum ration between the actual and the desired node-edge distance
    which is required to count an edge as stressed.
  "]]
}

declare {
  key = "edge stretch threshold",
  type = "number",
  initial = "1.5",

  summary = [["
    The minimum ration between the actual and the desired edge length
    which is required to count an edge as stressed.
  "]]
}

declare {
  key = "stress counter threshold",
  type = "number",
  initial = "30",

  summary = [["
    The number of iterations an edge has to be under stress before it will be subdivided.
  "]]
}

declare {
  key = "edge divisions",
  type = "number",
  initial = "0",

  summary = [["
    The number of edges in which stressed edges will be subdivided.
  "]]
}
