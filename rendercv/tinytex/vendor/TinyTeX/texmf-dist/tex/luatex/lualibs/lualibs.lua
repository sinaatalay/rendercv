-- 
--  This is file `lualibs.lua',
--  generated with the docstrip utility.
-- 
--  The original source files were:
-- 
--  lualibs.dtx  (with options: `lualibs')
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
lualibs = lualibs or { }

lualibs.module_info = {
  name          = "lualibs",
  version       = "2.76",       --TAGVERSION
    date        = "2023-07-13", --TAGDATE
  description   = "ConTeXt Lua standard libraries.",
  author        = "Hans Hagen, PRAGMA-ADE, Hasselt NL & Elie Roux & Philipp Gesang",
  copyright     = "PRAGMA ADE / ConTeXt Development Team",
  license       = "See ConTeXt's mreadme.pdf for the license",
}


config           = config or { }
config.lualibs   = config.lualibs or { }

if config.lualibs.prefer_merged ~= nil then
  lualibs.prefer_merged = config.lualibs.prefer_merged
else
  lualibs.prefer_merged = true
end

if config.lualibs.load_extended ~= nil then
  lualibs.load_extended = config.lualibs.load_extended
else
  lualibs.load_extended = true
end

if config.lualibs.verbose ~= nil then
  config.lualibs.verbose = config.lualibs.verbose
else
  config.lualibs.verbose = false
end


local dofile          = dofile
local kpsefind_file   = kpse.find_file
local stringformat    = string.format
local texiowrite_nl   = texio.write_nl

local find_file, error, warn, info
do
  local _error, _warn, _info
  if luatexbase and luatexbase.provides_module then
    _error, _warn, _info = luatexbase.provides_module(lualibs.module_info)
  else
    _error, _warn, _info = texiowrite_nl, texiowrite_nl, texiowrite_nl
  end

  if lualibs.verbose then
    error, warn, info = _error, _warn, _info
  else
    local dummylogger = function ( ) end
    error, warn, info = _error, dummylogger, dummylogger
  end
  lualibs.error, lualibs.warn, lualibs.info = error, warn, info
end

if status.kpse_used == 0 then
 kpse.set_program_name("luatex")
end

find_file = kpsefind_file


local loadmodule = loadmodule or function (name, t)
  if not t then t = "library" end
  local filepath  = find_file(name, "lua")
  if not filepath or filepath == "" then
    warn(stringformat("Could not locate %s “%s”.", t, name))
    return false
  end
  dofile(filepath)
  return true
end

lualibs.loadmodule = loadmodule


if lualibs.basic_loaded        ~= true
or config.lualibs.force_reload == true
then
  loadmodule"lualibs-basic.lua"
  loadmodule"lualibs-compat.lua" --- restore stuff gone since v1.*
end

if  lualibs.load_extended       == true
and lualibs.extended_loaded     ~= true
or  config.lualibs.force_reload == true
then
  loadmodule"lualibs-extended.lua"
end

--- This restores the default of loading everything should a package
--- have requested otherwise. Will be gone once there is a canonical
--- interface for parameterized loading of libraries.
config.lualibs.load_extended = true

-- vim:tw=71:sw=2:ts=2:expandtab

-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- 
--  End of File `lualibs.lua'.
