-- 
--  This is file `lualibs-basic.lua',
--  generated with the docstrip utility.
-- 
--  The original source files were:
-- 
--  lualibs.dtx  (with options: `basic')
--  This is a generated file.
--  
--  Copyright (C) 2009--2021 by
--          PRAGMA ADE / ConTeXt Development Team
--          The LaTeX Project Team
--  
--  See ConTeXt's mreadme.pdf for the license.
--  
--  This work consists of the main source file lualibs.dtx
--  and the derived files lualibs.lua, lualibs-basic.lua,
--  and lualibs-extended.lua.
--  
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lualibs                 = lualibs or { }
local info              = lualibs.info
local loadmodule        = lualibs.loadmodule

local lualibs_basic_module = {
  name          = "lualibs-basic",
  version       = "2.76",       --TAGVERSION
  date          = "2023-07-13", --TAGDATE
  description   = "ConTeXt Lua libraries -- basic collection.",
  author        = "Hans Hagen, PRAGMA-ADE, Hasselt NL & Elie Roux & Philipp Gesang",
  copyright     = "PRAGMA ADE / ConTeXt Development Team",
  license       = "See ConTeXt's mreadme.pdf for the license",
}

local loaded = false --- track success of package loading

if lualibs.prefer_merged then
  info"Loading merged package for collection “basic”."
  loaded = loadmodule('lualibs-basic-merged.lua')
else
  info"Ignoring merged packages."
  info"Falling back to individual libraries from collection “basic”."
end


if loaded == false then
  loadmodule("lualibs-lua.lua")
  loadmodule("lualibs-package.lua")
  loadmodule("lualibs-lpeg.lua")
  loadmodule("lualibs-function.lua")
  loadmodule("lualibs-string.lua")
  loadmodule("lualibs-table.lua")
  loadmodule("lualibs-boolean.lua")
  loadmodule("lualibs-number.lua")
  loadmodule("lualibs-math.lua")
  loadmodule("lualibs-io.lua")
  loadmodule("lualibs-os.lua")
  loadmodule("lualibs-file.lua")
  loadmodule("lualibs-md5.lua")
  loadmodule("lualibs-dir.lua")
  loadmodule("lualibs-unicode.lua")
  loadmodule("lualibs-url.lua")
  loadmodule("lualibs-set.lua")
end

lualibs.basic_loaded = true
-- vim:tw=71:sw=2:ts=2:expandtab

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- 
--  End of File `lualibs-basic.lua'.
