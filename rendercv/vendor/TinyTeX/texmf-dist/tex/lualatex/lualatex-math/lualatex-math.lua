--
-- This is file `lualatex-math.lua',
-- generated with the docstrip utility.
--
-- The original source files were:
--
-- lualatex-math.dtx  (with options: `lua')
-- 
-- This is a generated file.
-- 
-- Copyright 2011-2020 Philipp Stephani
-- 
-- This file may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either
-- version 1.3c of this license or (at your option) any later
-- version.  The latest version of this license is in
-- 
--    http://www.latex-project.org/lppl.txt
-- 
-- and version 1.3c or later is part of all distributions of
-- LaTeX version 2009/09/24 or later.
-- 
lualatex = lualatex or {}
lualatex.math = lualatex.math or {}
luatexbase.provides_module({
  name = "lualatex-math",
  date = "2013/08/03",
  version = 1.3,
  description = "Patches for mathematics typesetting with LuaLaTeX",
  author = "Philipp Stephani",
  licence = "LPPL v1.3+"
})
local unpack = unpack or table.unpack
local cctb = luatexbase.catcodetables or
  {string = luatexbase.registernumber("catcodetable@string")}
function lualatex.math.print_class_fam_slot(char)
  local code = tex.getmathcode(char)
  local class, family, slot = unpack(code)
  local result = string.format("%i %i %i ", class, family, slot)
  tex.sprint(cctb.string, result)
end
return lualatex.math
