-- Copyright 2012 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


-- Imports
local Storage = require "pgf.gd.lib.Storage"


---
-- This class provides a (non-functional) default implementation of a
-- binding between a display layer and the algorithm layer. Subclasses
-- must implement most of the member functions declared in this class.
--
-- A instance of a subclass of this class encapsulates the complete
-- implementation of all specific code needed for the communication
-- between the display layer and the graph drawing engine.
--
-- Note that you never call the methods of a |Binding| object
-- directly, neither from the display layer nor from the algorithm
-- layer. Instead, you use the more powerful and more easy to use
-- functions from |InterfaceToDisplay| and
-- |InterfaceToAlgorithms|. They call the appropriate |Binding|
-- methods internally.
--
-- Because of the above, in order to use the graph drawing system
-- inside a new display layer, you need to subclass |Binding| and
-- implement all the functions. Then you need to write the display
-- layer in such a way that it calls the appropriate functions from
-- |InterfaceToDisplay|.
--
-- @field storage A |Storage| storing the information passed from the
-- display layer. The interpretation of this left to the actual
-- binding.

local Binding = {
  storage = Storage.newTableStorage ()
}
Binding.__index = Binding

-- Namespace
require("pgf.gd.bindings").Binding = Binding





--
-- This method gets called whenever the graph drawing coroutine should
-- be resumed. First, the binding layer should ask the display layer
-- to execute the |code|, then, after this is done, the function
-- |InterfaceToDisplay.resumeGraphDrawingCoroutine| should be called
-- by this function.
--
-- @param code Some code to be executed by the display layer.

function Binding:resumeGraphDrawingCoroutine(code)
  -- Does nothing by default
end


---
-- Declare a new key. This callback is called by |declare|. It is the job
-- of the display layer to make the parameter |t.key| available to the
-- parsing process. Furthermore, if |t.initial| is not |nil|, the
-- display layer must convert it into a value that is stored as the
-- initial value and call |InterfaceToDisplay.setOptionInitial|.
--
-- @param t See |InterfaceToAlgorithms.declare| for details.

function Binding:declareCallback(t)
  -- Does nothing by default
end




-- Rendering

---
-- This function and, later on, |renderStop| are called whenever the
-- rendering of a laid-out graph starts or stops. See
-- |InterfaceToDisplay.render| for details.

function Binding:renderStart()
  -- Does nothing by default
end

---
-- See |renderStart|.

function Binding:renderStop()
  -- Does nothing by default
end





---
-- This function and the corresponding |...Stop...| functions are
-- called whenever a collection kind should be rendered. See
-- |InterfaceToDisplay.render_collections| for details.
--
-- @param kind The kind (a string).
-- @param layer The kind's layer (a number).

function Binding:renderCollectionStartKind(kind, layer)
  -- Does nothing by default
end


---
-- The counterpart to |renderCollectionStartKind|.
--
-- @param kind The kind.
-- @param layer The kind's layer.

function Binding:renderCollectionStopKind(kind, layer)
  -- Does nothing by default
end


---
-- Renders a single collection, see |renderCollectionStartKind| for
-- details.
--
-- @param collection The collection object.

function Binding:renderCollection(collection)
  -- Does nothing by default
end



---
-- This function and the corresponding |...Stop...| functions are
-- called whenever a vertex should be rendered. See
-- |InterfaceToDisplay.render_vertices| for details.
--

function Binding:renderVerticesStart()
  -- Does nothing by default
end


---
-- The counterpart to |renderVerticesStop|.
--

function Binding:renderVerticesStop()
  -- Does nothing by default
end


---
-- Renders a single vertex, see |renderVertexStartKind| for
-- details.
--
-- @param vertex The |Vertex| object.

function Binding:renderVertex(vertex)
  -- Does nothing by default
end



---
-- This method is called by the interface to the display layer after
-- the display layer has called |createVertex| to create a new
-- vertex. After having done its internal bookkeeping, the interface
-- calls this function to allow the binding to perform further
-- bookkeeping on the node. Typically, this will be done using the
-- information stored in |Binding.infos|.
--
-- @param v The vertex.

function Binding:everyVertexCreation(v)
  -- Does nothing by default
end





---
-- This function and the corresponding |...Stop...| functions are
-- called whenever an edge should be rendered. See
-- |InterfaceToDisplay.render_edges| for details.
--

function Binding:renderEdgesStart()
  -- Does nothing by default
end


---
-- The counterpart to |renderEdgesStop|.
--

function Binding:renderEdgesStop()
  -- Does nothing by default
end


---
-- Renders a single vertex, see |renderEdgeStartKind| for
-- details.
--
-- @param edge The |Edge| object.

function Binding:renderEdge(edge)
  -- Does nothing by default
end


---
-- Like |everyVertexCreation|, only for edges.
--
-- @param e The edge.

function Binding:everyEdgeCreation(e)
  -- Does nothing by default
end


---
-- Generate a new vertex. This method will be called when the
-- \emph{algorithm} layer wishes to trigger the creation of a new
-- vertex. This call will be made while an algorithm is running. It is
-- now the job of the binding to cause the display layer to create the
-- node. This is done by calling the |yield| method of the scope's
-- coroutine.
--
-- @param init  A table of initial values for the node. The following
-- fields will be used:
-- %
-- \begin{itemize}
--   \item |name| If present, this name will be given to the
--     node. If not present, an internal name is generated. Note that,
--     unless the node is a subgraph node, this name may not be the name
--     of an already present node of the graph; in this case an error
--     results.
--   \item |shape| If present, a shape of the node.
--   \item |generated_options| A table that is passed back to the
--     display layer as a list of key--value pairs.
--   \item |text| The text of the node, to be passed back to the
--     higher layer. This is what should be displayed as the node's text.
-- \end{itemize}

function Binding:createVertex(init)
  -- Does nothing by default
end




return Binding