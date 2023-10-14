-- Copyright 2013 by Till Tantau
--
-- This file may be distributed an/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License
--
-- See the file doc/generic/pgf/licenses/LICENSE for more information

-- @release $Header$


---
-- The table doc is used for documentation purposes. It is used to
-- provide lazy documentation for keys, that is, to install
-- documentation for keys only when this information is requested and
-- when the documentation is kept in a separate file.
--
-- Using the doc facility is easy:
-- %
-- \begin{enumerate}
--   \item In the |declare| statement of the key, you do not provide
--     fields like |documentation| or |summary|. Rather, you provide the
--     field |documentation_in|, which gets the name of a Lua file the
--     will be read whenever one of the fields |documentation|, |summary|,
--     or |examples| is requested for the key.
--   \item When the key is requested, |require| will be applied to the
--     filename given in the |documentation_in| field.
--   \item In this file, you start with the following code:
--     %
--\begin{codeexample}[code only]
--local doc           = require 'pgf.gd.doc'
--local key           = doc.key
--local documentation = doc.documentation
--local summary       = doc.summary
--local example       = doc.example
--\end{codeexample}
--     %
--     This will setup nice shortcuts for the commands you are going to
--     use in your file.
--   \item Next, for each to-be-lazily-documented key, add a block to
--     the file like the following:
--     %
--\begin{codeexample}[code only]
-- ---
-- key           "my radius"
-- summary       "This key specifies a radius."
-- documentation
-- [[
-- This key is used, whenever...
-- ]]
-- example       "\tikz \graph [foo layout, my radius=5] { a--b };"
-- example       "\tikz \graph [foo layout, my radius=3] { c--d };"
--\end{codeexample}
--
--     Note that |[[| and |]]| are used in Lua for raw multi-line strings.
--
--     The effect of the above code will be that for the key |my radius|
--     the different field like |summary| or |documentation| get
--     updated. The |key| function simple ``selects'' a key and subsequent
--     commands like |summary| will update this key until a different key
--     is selected through another use of |key|.
-- \end{enumerate}

local doc = {}

local current_key


-- Namespace
require "pgf.gd".doc = doc


-- Imports
local keys = require "pgf.gd.interface.InterfaceCore".keys

---
-- Selects the key which will be subsequently updated by the other
-- functions of this class.
--
-- @param key A key.

function doc.key (key)
  current_key = assert(keys[key], "trying to document not-yet-declared key")
end


---
-- Updates (replaces) the summary field of the last key selected
-- through the |key| command.
--
-- @param string A (new) summary string.

function doc.summary (string)
  current_key.summary = string
end


---
-- Updates (replaces) the documentation field of the last key selected
-- through the |key| command.
--
-- @param string A (new) documentation string. Typically, the |[[|
-- syntax will be used to specify this string.

function doc.documentation (string)
  current_key.documentation = string
end


---
-- Adds an example to the |examples| field of the last key selected
-- through the |key| command.
--
-- @param string An additional example string.

function doc.example (string)
  local examples = rawget(current_key, "examples") or {}
  examples[#examples + 1] = string
  current_key.examples = examples
end


return doc
