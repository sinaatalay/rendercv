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
-- This class offers functions for converting the documentation of Lua
-- and other code into \TeX.
--
-- @field renderers This array must consist of tables having two
-- fields: |test| and |renderer|. The first must be set to a function
-- that is called with an information table as parameter and must
-- return |true| if the function stored in the |renderer| should be
-- called. (Typically, the |test| will test whether the ``head line''
-- following a documentation block has a special form.)

local DocumentParser = {
  renderers = {}
}

-- Namespace:
require 'pgf.manual'.DocumentParser = DocumentParser

-- Imports
local keys = require 'pgf.gd.interface.InterfaceCore'.keys

-- Forwards:

local collect_infos, render_infos


---
-- Includes the documentation stored in some file in the manual.
--
-- @param filename The file from which the documentation is to be read
-- @param type The type of the file.

function DocumentParser.include(filename, typ)

  local fullname = assert(kpse.find_file(filename:gsub("%.", "/"), typ or "lua")
        or kpse.find_file(filename:gsub("%.", "\\"), typ or "lua"),
        "file " .. filename .. " not found")

  local file, error = io.open(fullname)

  -- First, let us read the file into a table to make handling easier:
  local lines = {}

  for line in file:lines() do
    lines [#lines + 1] = line
  end

  -- A table storing the current output. The array part contains TeX
  -- lines, the table part contains information about special table.s
  local output = {}

  -- Now, start the main parser loop.
  local i = 1
  while i <= #lines do

    if lines[i]:match("^%-%-%-") then
      local infos = collect_infos (lines, i)

      infos.filename = filename

      render_infos(infos, output)

      i = infos.last_line
    end

    i = i + 1
  end

  -- Render output:
  for _,l in ipairs(output) do
    if type(l) == "string" then
      tex.print(l)
    else
      l()
    end
  end

end



---
-- Add a test and a renderer to the array of renderers.
--
-- @param test A test function (see |DocumentParser.renderers|).
-- @param renderer A rendering function.

function DocumentParser.addRenderer (test, renderer)
  DocumentParser.renderers [#DocumentParser.renderers + 1] =
    { test = test, renderer = renderer }
end


-- Forwards:
local print_on_output, print_on_output_escape, print_docline_on_output, open_mode, close_mode, print_lines_on_output



local function strip_quotes(s)
  if s then return string.gsub(s, '^"(.*)"$', "%1") end
end

local function split(s)
  local t = {}
  for line in string.gmatch(s, ".-\n") do
    t[#t+1] = line
  end
  for i=#t,1,-1 do
    if t[i]:match("^%s*$") then
      t[i] = nil
    else
      return t
    end
  end
  return t
end


local function process_string(s)
  if s then
    local t = split(s.."\n")
    -- Compute min spaces
    local min = math.huge
    for _,l in ipairs(t) do
      min = math.min(min, string.find(l, "%S") or math.huge)
    end
    if min < math.huge then
      -- Now, trim 'em all!
      for i=1,#t do
        t[i] = string.sub(t[i],min,-2)
      end
    end
    return t
  end
end


local function process_examples(t)
  if not t then
    return nil
  end

  if type(t) == "string" then
    t = {t}
  end

  local n = {}
  for i=1,#t do
    local code, options
    if type(t[i]) == "table" then
      code = assert(t[i].code)
      options = t[i].options
    else
      code = t[i]
    end
    n[i] = {
      options = process_string(strip_quotes(options)),
      code = process_string(strip_quotes(code))
    }
  end
  return n
end



-- The standard renderers:


-- The function renderer
DocumentParser.addRenderer (
  function (infos)
    -- The test
    return
      infos.keywords["function"] or
      infos.head_line:match("^%s*function%s+") or
      infos.head_line:match("^%s*local%s+function%s+")
  end,
  function (infos, output)
    -- The renderer

    if infos.keywords["function"] then
      local k = infos.keywords["function"][1]
      infos.head_line = k:match("^%s*@(.*)")
    end

    local rest = infos.head_line:match("function%s+(.*)")
    local tab  = rest:match("([^(]*[%.%:]).*")
    local fun  = rest:match("[^(]*[%.%:](.-)%s*%(") or rest:match("(.-)%s*%(")
    local pars = rest:match(".-%((.*)%)")

    -- Render the head
    print_on_output_escape(output, [[\begin{luacommand}]])
    output[#output+1] = "{" .. (tab or "") .. fun .. "}"
    print_on_output_escape(output,
                           "{", tab or "", "}",
                           "{", fun, "}",
                           "{", pars, "}")

    if tab then
      local table_name = tab:sub(1,-2)
      local t = output[table_name] or {}
      t[#t+1] = {
        link = "pgf/lua/" .. tab .. fun,
        text = "function " .. tab .. "\\declare{" .. fun .. "} (" .. pars .. ")"
      }
      output[table_name] = t
    end

    local mode = "text"
    for _,l in ipairs(infos.doc_lines) do
      if mode ~= "done" then
        mode = print_docline_on_output(output, l, mode)
      end
    end
    close_mode(output, mode)

    print_on_output(output, [[\end{luacommand}]])

  end
)


-- The table renderer
DocumentParser.addRenderer (
  function (infos)
    -- The test
    return
      infos.keywords["table"] or
      infos.head_line:match("=%s*{")
  end,
  function (infos, output)
    -- The renderer

    if infos.keywords["table"] then
      local k = infos.keywords["table"][1]
      infos.head_line = k:match("^%s*@table(.*)") .. "="
    end

    local name =
      infos.head_line:match("^%s*local%s+(.-)%s*=") or
      infos.head_line:match("^%s*(.*)%s*=")

    -- Render the head
    print_on_output_escape(output,
                           [[\begin{luatable}]],
                           "{", name:match("(.*[%.%:]).*") or "", "}",
                           "{", name:match(".*[%.%:](*-)") or name,"}",
                           "{", infos.filename, "}")

    local mode = "text"
    for _,l in ipairs(infos.doc_lines) do
      mode = print_docline_on_output(output, l, mode)
    end
    close_mode(output, mode)

    output[#output+1] =
      function ()
        if output[name] then
          tex.print("\\par\\emph{Alphabetical method summary:}\\par{\\small")
          table.sort(output[name], function (a,b) return a.text < b.text end)
          for _,l in ipairs(output[name]) do
            tex.print("\\texttt{\\hyperlink{" .. l.link .. "}{" .. l.text:gsub("_", "\\_") .. "}}\\par")
          end
          tex.print("}")
        end
      end

    print_on_output(output, [[\end{luatable}]])

  end
)



-- The library renderer
DocumentParser.addRenderer (
  function (infos)
    -- The test
    return infos.keywords["library"]
  end,
  function (infos, output)
    -- The renderer

    local name = infos.filename:gsub("%.library$",""):gsub("^pgf%.gd%.","")

    -- Render the head
    print_on_output_escape(output, "\\begin{lualibrary}{", name, "}")

    local mode = "text"
    for _,l in ipairs(infos.doc_lines) do
      mode = print_docline_on_output(output, l, mode)
    end
    close_mode(output, mode)

    print_on_output(output, "\\end{lualibrary}")

  end
)


-- The section renderer
DocumentParser.addRenderer (
  function (infos)
    -- The test
    return infos.keywords["section"]
  end,
  function (infos, output)
    -- The renderer
    local mode = "text"
    for _,l in ipairs(infos.doc_lines) do
      mode = print_docline_on_output(output, l, mode)
    end
    close_mode(output, mode)
  end
)


-- The documentation (plain text) renderer
DocumentParser.addRenderer (
  function (infos)
    -- The test
    return infos.keywords["documentation"]
  end,
  function (infos, output)
    -- The renderer
    local mode = "text"
    for _,l in ipairs(infos.doc_lines) do
      mode = print_docline_on_output(output, l, mode)
    end
    close_mode(output, mode)
  end
)


-- The declare renderer
DocumentParser.addRenderer (
  function (infos)
    -- The test
    return
      infos.keywords["declare"] or
      infos.head_line:match("declare%s*{") or
      infos.head_line:match("^%s*key%s*")
  end,
  function (infos, output)
    -- The renderer

    local key_name

    if infos.keywords["declare"] then
      local k = infos.keywords["declare"][1]
      key_name = k:match("^%s*@declare%s*(.*)")
    elseif infos.head_line:match("^%s*key%s*") then
      key_name = infos.head_line:match('^%s*key%s*"(.*)"') or
                 infos.head_line:match("^%s*key%s*'(.*)'")
    else
      local l = infos.lines [infos.last_line + 1]
      key_name = l:match('key%s*=%s*"(.*)"') or l:match("key%s*=%s*'(.*)'")
    end

    assert (key_name, "could not determine key")
    local key = assert (keys[key_name], "unknown key '" .. key_name .. "'")

    -- Render the head
    if key.type then
      print_on_output_escape(output,
                             "\\begin{luadeclare}",
                             "{", key.key, "}",
                             "{\\meta{", key.type, "}}",
                             "{", key.default or "", "}",
                             "{", key.initial or "", "}")
    else
      print_on_output_escape(output,
                             "\\begin{luadeclarestyle}",
                             "{", key.key, "}",
                             "{}",
                             "{", key.default or "", "}",
                             "{", key.initial or "", "}")
    end


    local mode = "text"

    print_lines_on_output(output, process_string(strip_quotes(key.summary)))
    print_lines_on_output(output, process_string(strip_quotes(key.documentation)))

    if key.examples then
      local e = process_examples(key.examples)
      print_on_output(output,
                      "\\par\\smallskip\\emph{Example" .. (((#e>1) and "s") or "") .. "}\\par")
      for _,example in ipairs(e) do
        local opts = table.concat(example.options or {}, "")
        print_on_output(output, "\\begin{codeexample}[" .. opts .. "]")
        print_lines_on_output(output, example.code)
        print_on_output(output, "\\end{codeexample}")
      end
    end

    print_on_output(output, key.type and "\\end{luadeclare}" or "\\end{luadeclarestyle}")
  end
)



-- The empty line
DocumentParser.addRenderer (
  function (infos)
    -- The test
    return
      #infos.doc_lines == 1 and
      infos.doc_lines[1]:match("^%-*%s*$")
  end,
  function (infos, output)
  end
)


function print_lines_on_output(output, lines)
  for n,l in ipairs(lines or {}) do
    if (n == 1 or n == #lines) and l == "" then
       -- skip leading and trailing blank lines
    else
      output[#output+1] = l
    end
  end
end

function print_on_output(output, ...)
  local args = {...}
  if #args > 0 then
    for i = 1, #args do
      args[i] = tostring(args[i])
    end
    output[#output+1] = table.concat(args)
  end
end

function print_on_output_escape(output, ...)
  local args = {...}
  if #args > 0 then
    for i = 1, #args do
      args[i] = tostring(args[i]):gsub("_", "\\_")
    end
    output[#output+1] = table.concat(args)
  end
end


function print_docline_on_output(output, l, mode)

  if l:match("^%s*@section") then
    print_on_output(output, "\\", l:match("%s*@section%s*(.*)"))
  elseif l:match("^%s*@param%s+") then
    if mode ~= "param" then
      close_mode (output, mode)
      mode = open_mode (output, "param")
    end
    print_on_output(output, "\\item[\\texttt{",
                    l:match("%s@param%s+(.-)%s"):gsub("_", "\\_"),
                    "}] ",
                    l:match("%s@param%s+.-%s+(.*)"))
  elseif l:match("^%s*@return%s+") then
    if mode ~= "return" then
      close_mode (output, mode)
      mode = open_mode (output, "returns")
    end
    print_on_output(output, "\\item[]", l:match("%s@return%s+(.*)"))
  elseif l:match("^%s*@see%s+") then
    if mode ~= "text" then
      close_mode (output, mode)
      mode = open_mode (output, "text")
    end
    print_on_output(output, "\\par\\emph{See also:} \\texttt{",
                    l:match("%s@see%s+(.*)"):gsub("_", "\\_"),
                    "}")
  elseif l:match("^%s*@usage%s+") then
    if mode ~= "text" then
      close_mode (output, mode)
      mode = open_mode (output, "text")
    end
    print_on_output(output, "\\par\\emph{Usage:} ",
                    l:match("%s@usage%s+(.*)"))
  elseif l:match("^%s*@field+") then
    close_mode (output, mode)
    mode = open_mode (output, "field")
    print_on_output(output, "{",
                    (l:match("%s@field%s+(.-)%s") or l:match("%s@field%s+(.*)")):gsub("_", "\\_"),
                    "}",
                    l:match("%s@field%s+.-%s+(.*)"))
  elseif l:match("^%s*@done") or l:match("^%s*@text") then
    close_mode(output, mode)
    print_on_output(output, l)

    mode = "text"
  elseif l:match("^%s*@library") then
    -- do nothing
  elseif l:match("^%s*@function") then
    -- do nothing
  elseif l:match("^%s*@end") then
    close_mode(output, mode)
    mode = "done"
  elseif l:match("^%s*@") then
    error("Unknown mark " .. l)
  else
    print_on_output(output, l)
  end

  return mode
end

function open_mode (output, mode)
  if mode == "param" then
    print_on_output(output, "\\begin{luaparameters}")
  elseif mode == "field" then
    print_on_output(output, "\\begin{luafield}")
  elseif mode == "returns" then
    print_on_output(output, "\\begin{luareturns}")
  end
  return mode
end

function close_mode (output, mode)
  if mode == "param" then
    print_on_output(output, "\\end{luaparameters}")
  elseif mode == "field" then
    print_on_output(output, "\\end{luafield}")
  elseif mode == "returns" then
    print_on_output(output, "\\end{luareturns}")
  end
  return mode
end


function collect_infos (lines, i, state)

  local doc_lines = {}

  local keywords = {}

  local function find_keywords(line)
    local keyword = line:match("^%s*@([^%s]*)")
    if keyword then
      local t = keywords[keyword] or {}
      t[#t+1] = line
      keywords[keyword] = t
    end
    return line
  end

  -- Copy triple matches:
  while lines[i] and lines[i]:match("^%-%-%-") do
    doc_lines [#doc_lines + 1] = find_keywords(lines[i]:sub(4))
    i = i + 1
  end

  -- Continue with double matches:
  while lines[i] and lines[i]:match("^%-%-") do
    doc_lines [#doc_lines + 1] = find_keywords(lines[i]:sub(3))
    i = i + 1
  end

  local head_line = ""

  if not keywords["end"] then
    -- Skip empty lines
    while lines[i] and lines[i]:match("^%s*$") do
      i = i + 1
    end
    head_line = lines[i] or ""
    if lines[i] and lines[i]:match("^%-%-%-") then
      i = i - 1
    end
  end

  return {
    lines     = lines,
    last_line = i,
    doc_lines = doc_lines,
    keywords  = keywords,
    head_line = head_line
  }

end



function render_infos(infos, state)

  for _,renderer in ipairs(DocumentParser.renderers) do
    if renderer.test (infos, state) then
      renderer.renderer (infos, state)
      return
    end
  end

  pgf.debug(infos)
  error("Unknown documentation type")
end


return DocumentParser
