-- 
--  This is file `lualibs-extended.lua',
--  generated with the docstrip utility.
-- 
--  The original source files were:
-- 
--  lualibs.dtx  (with options: `extended')
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
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
-- %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
lualibs = lualibs or { }


local lualibs_extended_module = {
  name          = "lualibs-extended",
  version       = "2.76",       --TAGVERSION
  date          = "2023-07-13", --TAGDATE
  description   = "ConTeXt Lua libraries -- extended collection.",
  author        = "Hans Hagen, PRAGMA-ADE, Hasselt NL & Elie Roux & Philipp Gesang",
  copyright     = "PRAGMA ADE / ConTeXt Development Team",
  license       = "See ConTeXt's mreadme.pdf for the license",
}

local stringformat     = string.format
local loadmodule       = lualibs.loadmodule
local texiowrite       = texio.write
local texiowrite_nl    = texio.write_nl


local error, logger, mklog
if luatexbase and luatexbase.provides_module then
  --- TODO test how those work out when running tex
  local __error,_,_,__logger =
    luatexbase.provides_module(lualibs_extended_module)
  error  = __error
  logger = __logger
  mklog = function ( ) return logger end
else
  mklog = function (t)
    local prefix = stringformat("[%s] ", t)
    return function (...)
      texiowrite_nl(prefix)
      texiowrite   (stringformat(...))
    end
  end
  error  = mklog"ERROR"
  logger = mklog"INFO"
end

local info = lualibs.info


local dummy_function = function ( ) end
local newline        = function ( ) texiowrite_nl"" end

local fake_logs = function (name)
  return {
    name     = name,
    enable   = dummy_function,
    disable  = dummy_function,
    reporter = mklog,
    newline  = newline
  }
end

local fake_trackers = function (name)
  return {
    name     = name,
    enable   = dummy_function,
    disable  = dummy_function,
    register = mklog,
    newline  = newline,
  }
end

local backup_store = { }

local fake_context = function ( )
  if logs     then backup_store.logs     = logs     end
  if trackers then backup_store.trackers = trackers end
  logs     = fake_logs"logs"
  trackers = fake_trackers"trackers"
end

local unfake_context = function ( )
  if backup_store then
    local bl, bt = backup_store.logs, backup_store.trackers
    if bl   then logs     = bl   end
    if bt   then trackers = bt   end
  end
end

fake_context()

local loaded = false
if lualibs.prefer_merged then
  info"Loading merged package for collection “extended”."
  loaded = loadmodule('lualibs-extended-merged.lua')
else
  info"Ignoring merged packages."
  info"Falling back to individual libraries from collection “extended”."
end

if loaded == false then
  loadmodule("lualibs-util-sac.lua")--- streams: string based file parsers
  loadmodule("lualibs-util-str.lua")--- string formatters (fast)
  loadmodule("lualibs-util-fil.lua")--- extra file helpers
  loadmodule("lualibs-util-tab.lua")--- extended table operations
  loadmodule("lualibs-util-sto.lua")--- storage (hash allocation)
  ----------("lualibs-util-pck.lua")---!packers; necessary?
  ----------("lualibs-util-seq.lua")---!sequencers (function chaining)
  ----------("lualibs-util-mrg.lua")---!only relevant in mtx-package
  loadmodule("lualibs-util-prs.lua")--- miscellaneous parsers; cool. cool cool cool
  ----------("lualibs-util-fmt.lua")---!column formatter (rarely used)
  loadmodule("lualibs-util-dim.lua")--- conversions between dimensions
  loadmodule("lualibs-util-jsn.lua")--- JSON parser

  ----------("lualibs-trac-set.lua")---!generalization of trackers
  ----------("lualibs-trac-log.lua")---!logging
  loadmodule("lualibs-trac-inf.lua")--- timing/statistics
  loadmodule("lualibs-util-lua.lua")--- operations on lua bytecode
  loadmodule("lualibs-util-deb.lua")--- extra debugging
  loadmodule("lualibs-util-tpl.lua")--- templating
  loadmodule("lualibs-util-sta.lua")--- stacker (for writing pdf)
  loadmodule("lualibs-util-zip.lua")--- compression and zip files
end

unfake_context() --- TODO check if this works at runtime

lualibs.extended_loaded = true
-- vim:tw=71:sw=2:ts=2:expandtab

-- 
--  End of File `lualibs-extended.lua'.
