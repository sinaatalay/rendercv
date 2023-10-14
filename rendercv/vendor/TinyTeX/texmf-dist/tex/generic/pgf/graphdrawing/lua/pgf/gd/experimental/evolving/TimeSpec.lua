-- Copyright 2015 by Malte Skambath
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information


-- Imports
local declare = require("pgf.gd.interface.InterfaceToAlgorithms").declare

---

declare {
  key     = "snapshot",
  type    = "time",
  initial = "0s",
  summary = "The time of the snapshot in which a PGF node should be visible.",
  documentation = [["
    This option defines the time in seconds when respectively in which
    state or snapshot of the graph the PGF represents a graph node.
  "]],
}

---

declare {
  key     = "supernode",
  type    = "string",
  initial = "null",
  summary = "A unique name for a node a given PGF node should be assigned to.",
  documentation = [["
    Because it should be possible that nodes can change their
    appearance, they are represented by separate PGF nodes in each
    snapshot. To identify PGF nodes of the same supernode we have to
    specify this key.
  "]],
}

---

declare {
  key     = "fadein time",
  type    = "time",
  initial = "0.5s",
  summary = [["
    The time in seconds it should take that a nodes will be fade in
    when it disappears in the graph.
  "]],
}

---

declare {
  key     = "fadeout time",
  type    = "time",
  initial = "0.5s",
  summary = "",
  documentation = "The same as |fadein time| but for disappearing nodes.",
}
