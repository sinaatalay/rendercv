-------------------------------------------------------------------------------
--         FILE:  luaotfload-configuration.lua
--  DESCRIPTION:  part of luaotfload / luaotfload-tool / config file reader
--       AUTHOR:  Philipp Gesang, <phg@phi-gamma.net>
--       AUTHOR:  Dohyun Kim <nomosnomos@gmail.com>
-------------------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-configuration",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / config file reader",
    license       = "GPL v2.0"
}

------------------------------

local status_file             = "luaotfload-status"
local luaotfloadstatus        = require (status_file)

local string                  = string
local stringfind              = string.find
local stringformat            = string.format
local stringstrip             = string.strip
local stringsub               = string.sub

local tableappend             = table.append
local tableconcat             = table.concat
local tablecopy               = table.copy
local table                   = table
local tabletohash             = table.tohash

local math                    = math
local mathfloor               = math.floor

local io                      = io
local ioloaddata              = io.loaddata
local iopopen                 = io.popen
local iowrite                 = io.write

local os                      = os
local osdate                  = os.date
local osgetenv                = os.getenv

local lpeg                    = require "lpeg"
local lpegmatch               = lpeg.match
local commasplitter           = lpeg.splitat ","
local equalssplitter          = lpeg.splitat "="

local kpseexpand_path         = kpse.expand_path

local lfs                     = lfs
local lfsisfile               = lfs.isfile
local lfsisdir                = lfs.isdir

local file                    = file
local filejoin                = file.join
local filereplacesuffix       = file.replacesuffix

local logreport               = print -- overloaded later
local getwritablepath         = luaotfload.fontloader.caches.getwritablepath


local config_parser -- set later during init
local stripslashes  -- set later during init

-------------------------------------------------------------------------------
---                                SETTINGS
-------------------------------------------------------------------------------

local path_t = 0
local kpse_t = 1

local val_home            = kpseexpand_path "~"
local val_xdg_config_home = kpseexpand_path "$XDG_CONFIG_HOME"

if val_xdg_config_home == "" then val_xdg_config_home = "~/.config" end

local config_paths = {
  --- needs adapting for those other OS
  { path_t, "./luaotfload.conf" },
  { path_t, "./luaotfloadrc" },
  { path_t, filejoin (val_xdg_config_home, "luaotfload/luaotfload.conf") },
  { path_t, filejoin (val_xdg_config_home, "luaotfload/luaotfloadrc") },
  { path_t, filejoin (val_home, ".luaotfloadrc") },
  { kpse_t, "luaotfloadrc" },
  { kpse_t, "luaotfload.conf" },
}

local valid_formats = tabletohash {
  "otf", "ttc", "ttf", "afm", "pfb"
}

local default_location_precedence = {
  "system", "texmf", "local"
}
local valid_locations = tabletohash {
  "system", "texmf", "local"
}

local default_anon_sequence = {
  "tex", "path", "name"
}

local valid_resolvers = tabletohash {
  "tex", "path", "name", "file", "my"
}

local base_features = tabletohash {
  -- Adopt the generic default from HarfBuzz.
  -- The first line is generally enabled there,
  -- the second only for horizontal text.
  -- The third line is luaotfload specific
  "abvm", "blwm", "ccmp", "locl", "mark", "mkmk", "rlig",
  "calt", "clig", "curs", "dist", "kern", "liga", "rclt",
  "itlc",
}
local feature_presets = {
  arab = table.merged( tabletohash {
    "isol", "fina", "fin2", "fin3", "medi", "med2", "init",
    "cswh", "mset",
  }, base_features),
  deva = table.merged( tabletohash {
    "init", "nukt", "akhn", "rphf", "blwf", "half", "pstf",
    "vatu", "pres", "blws", "abvs", "psts", "haln",
  }, base_features),
  khmr = table.merged( tabletohash {
    "pref", "blwf", "abvf", "pstf", "pres", "blws", "abvs",
    "psts",
  }, base_features),
  hang = table.merged( tabletohash {
    "ccmp", "ljmo", "vjmo", "tjmo",
  }, base_features),
}

--[[doc--

  We allow loading of arbitrary fontloaders. Nevertheless we maintain a
  list of the “official” ones shipped with Luaotfload so we can emit a
  different log message.

--doc]]--

local function default_fontloader ()
  return luaotfloadstatus and luaotfloadstatus.notes.loader or "reference"
end

local registered_loaders = {
  default    = default_fontloader (),
  reference  = "reference",
  unpackaged = "unpackaged",
  context    = "context",
}

local function pick_fontloader (s)
  local ldr = registered_loaders[s]
  if ldr ~= nil and type (ldr) == "string" then
    logreport ("log", 2, "conf", "Using predefined fontloader %q.", ldr)
    return ldr
  end
  local idx = stringfind (s, ":")
  if idx and idx > 2 then
    if stringsub (s, 1, idx - 1) == "context" then
      local pth = stringsub (s, idx + 1)
      pth = stringstrip (pth)
      logreport ("log", 2, "conf", "Context base path specified at %q.", pth)
      if lfsisdir (pth) then
        logreport ("log", 5, "conf", "Context base path exists at %q.", pth)
        return pth
      end
      pth = kpseexpand_path (pth)
      if lfsisdir (pth) then
        logreport ("log", 5, "conf", "Context base path exists at %q.", pth)
        return pth
      end
      logreport ("both", 0, "conf", "Context base path not found at %q.", pth)
    end
  end
  return nil
end

--[[doc--

  The ``post_linebreak_filter`` has been made the default callback for
  hooking the colorizer into. This helps with the linebreaking whose
  inserted hyphens would remain unaffected by the coloring otherwise.

  http://tex.stackexchange.com/q/238539/14066

--doc]]--

local permissible_color_callbacks = {
  default               = "post_linebreak_filter",
  pre_linebreak_filter  = "pre_linebreak_filter",
  post_linebreak_filter = "post_linebreak_filter",
  pre_output_filter     = "pre_output_filter",
}

local known_dvi_drivers = {
  xdvipsk = 'xdvipsk',
  dvisvgm = 'dvisvgm',
}

-------------------------------------------------------------------------------
---                                DEFAULTS
-------------------------------------------------------------------------------

local default_config = {
  db = {
    location_precedence = default_location_precedence,
    formats             = "otf,ttf,ttc",
    scan_local          = false,
    skip_read           = false,
    strip               = true,
    update_live         = true,
    compress            = true,
    max_fonts           = 2^51,
    designsize_dimen    = "bp",
  },
  run = {
    anon_sequence      = default_anon_sequence,
    resolver           = "cached",
    definer            = "patch",
    log_level          = 0,
    color_callback     = "post_linebreak_filter",
    fontloader         = default_fontloader (),
    default_dvi_driver = "dvisvgm"
  },
  misc = {
    bisect         = false,
    version        = luaotfload.version,
    statistics     = false,
    termwidth      = nil,
    keepnames      = true,
  },
  paths = {
    names_dir           = "names",
    cache_dir           = "fonts",
    index_file          = "luaotfload-names.lua",
    lookups_file        = "luaotfload-lookup-cache.lua",
    lookup_path_lua     = nil,
    lookup_path_luc     = nil,
    index_path_lua      = nil,
    index_path_luc      = nil,
  },
  default_features = {
    global = { mode = "node" },
    dflt = base_features,

    arab = feature_presets.arab,
    syrc = feature_presets.arab,
    mong = feature_presets.arab,
    nko  = feature_presets.arab,

    deva = feature_presets.deva,
    beng = feature_presets.deva,
    guru = feature_presets.deva,
    gujr = feature_presets.deva,
    orya = feature_presets.deva,
    taml = feature_presets.deva,
    telu = feature_presets.deva,
    knda = feature_presets.deva,
    mlym = feature_presets.deva,
    sinh = feature_presets.deva,

    khmr = feature_presets.khmr,
    tibt = feature_presets.khmr,
    thai = feature_presets.thai,
    lao  = feature_presets.thai,

    hang = feature_presets.hang,
  },
}

-------------------------------------------------------------------------------
---                          RECONFIGURATION TASKS
-------------------------------------------------------------------------------

--[[doc--

    Procedures to be executed in order to put the new configuration into effect.

--doc]]--

local reconf_tasks = nil

local min_terminal_width = 40

--- The “termwidth” value is only considered when printing
--- short status messages, e.g. when building the database
--- online.
local function check_termwidth ()
  if config.luaotfload.misc.termwidth == nil then
      local tw = 79
      if not (   os.type == "windows" --- Assume broken terminal.
              or osgetenv "TERM" == "dumb")
      then
          local p = iopopen "tput cols"
          if p then
              result = tonumber (p:read "*all")
              p:close ()
              if result then
                  tw = result
              else
                  logreport ("log", 2, "db", "tput returned non-number.")
              end
          else
              logreport ("log", 2, "db", "Shell escape disabled or tput executable missing.")
              logreport ("log", 2, "db", "Assuming 79 cols terminal width.")
          end
      end
      config.luaotfload.misc.termwidth = tw
  end
  return true
end

local function set_font_filter ()
  local names = fonts.names
  if names and names.set_font_filter then
    local formats = config.luaotfload.db.formats
    if not formats or formats == "" then
      formats = default_config.db.formats
    end
    names.set_font_filter (formats)
  end
  return true
end

local function set_location_precedence_list ()
  local names = fonts.names
  if names and names.set_location_precedence then
    local locations = config.luaotfload.db.location_precedence
    if not locations or locations == "" then
      locations = default_config.db.location_precedence
    end
    fonts.names.set_location_precedence (locations)
  end
  return true
end

local function set_size_dimension ()
  local names = fonts.names
  if names and names.set_size_dimension then
    local dim = config.luaotfload.db.designsize_dimen
    if not dim or dim == "" then
      dim = default_config.db.designsize_dimen
    end
    names.set_size_dimension (dim)
  end
  return true
end

local function set_name_resolver ()
  local names = fonts.names
  if names and names.resolve_cached then
    --- replace the resolver from luatex-fonts
    if config.luaotfload.db.resolver == "cached" then
        logreport ("both", 2, "cache", "Caching of name: lookups active.")
        names.resolvespec  = fonts.names.lookup_font_name_cached
    else
        names.resolvespec  = fonts.names.lookup_font_name
    end
  end
  return true
end

local function set_loglevel ()
  if luaotfload then
    luaotfload.log.set_loglevel (config.luaotfload.run.log_level)
    return true
  end
  return false
end

local function build_cache_paths ()
  local paths  = config.luaotfload.paths
  local prefix = getwritablepath (paths.names_dir, "")

  if not prefix then
    luaotfload.error ("Impossible to find a suitable writeable cache...")
    return false
  end

  prefix = lpegmatch (stripslashes, prefix)
  logreport ("log", 0, "conf", "Root cache directory is %q.", prefix)

  local index_file      = filejoin (prefix, paths.index_file)
  local lookups_file    = filejoin (prefix, paths.lookups_file)

  paths.prefix          = prefix
  paths.index_path_lua  = filereplacesuffix (index_file,   "lua")
  paths.index_path_luc  = filereplacesuffix (index_file,   "luc")
  paths.lookup_path_lua = filereplacesuffix (lookups_file, "lua")
  paths.lookup_path_luc = filereplacesuffix (lookups_file, "luc")
  return true
end


local function set_default_features ()
  local default_features = config.luaotfload.default_features
  luaotfload.features    = luaotfload.features or {
                             global   = { },
                             defaults = { },
                           }
  local current_features = luaotfload.features
  for var, val in next, default_features do
    if var == "global" then
      current_features.global = val
    else
      current_features.defaults[var] = val
    end
  end
  return true
end

reconf_tasks = {
  { "Set the log level"         , set_loglevel         },
  { "Build cache paths"         , build_cache_paths    },
  { "Check terminal dimensions" , check_termwidth      },
  { "Set the font filter"       , set_font_filter      },
  { "Set design size dimension" , set_size_dimension   },
  { "Install font name resolver", set_name_resolver    },
  { "Set default features"      , set_default_features },
  { "Set location precedence"   , set_location_precedence_list },
}

-------------------------------------------------------------------------------
---                          OPTION SPECIFICATION
-------------------------------------------------------------------------------

local string_t    = "string"
local table_t     = "table"
local number_t    = "number"
local boolean_t   = "boolean"
local function_t  = "function"

local function tointeger (n)
  n = tonumber (n)
  if n then
    return mathfloor (n + 0.5)
  end
end

local function toarray (s)
  local fields = { lpegmatch (commasplitter, s) }
  local ret    = { }
  for i = 1, #fields do
    local field = stringstrip (fields[i])
    if field and field ~= "" then
      ret[#ret + 1] = field
    end
  end
  return ret
end

local function tohash (s)
  local result = { }
  local fields = toarray (s)
  for _, field in next, fields do
    local var, val
    if stringfind (field, "=") then
      local tmp
      var, tmp = lpegmatch (equalssplitter, field)
      if tmp == "true" or tmp == "yes" then val = true else val = tmp end
    else
      var, val = field, true
    end
    result[var] = val
  end
  return result
end

local option_spec = {
  db = {
    formats      = {
      in_t  = string_t,
      out_t = string_t,
      transform = function (f)
        local fields = toarray (f)

        --- check validity
        if not fields then
          logreport ("both", 0, "conf",
                     "Expected list of identifiers, got %q.", f)
          return nil
        end

        --- strip dupes
        local known  = { }
        local result = { }
        for i = 1, #fields do
          local field = fields[i]
          if known[field] ~= true then
            --- yet unknown, tag as seen
            known[field] = true
            --- include in output if valid
            if valid_formats[field] == true then
              result[#result + 1] = field
            else
              logreport ("both", 4, "conf",
                         "Invalid font format identifier %q, ignoring.",
                         field)
            end
          end
        end
        if #result == 0 then
          --- force defaults
          return nil
        end
        return tableconcat (result, ",")
      end
    },
    location_precedence = {
      in_t      = string_t,
      out_t     = table_t,
      transform = function (s)
        local bits = { lpegmatch (commasplitter, s) }
        if next (bits) then
          local seq = { }
          local done = { }
          for i = 1, #bits do
            local bit = bits [i]
            if valid_locations [bit] then
              if not done [bit] then
                done [bit] = true
                seq [#seq + 1] = bit
              else
                logreport ("both", 0, "conf",
                           "ignoring duplicate location %s at position %d \z
                            in precedence list",
                           bit, i)
              end
            else
              logreport ("both", 0, "conf",
                         "location precedence list contains invalid item %s \z
                          at position %d.",
                         bit, i)
            end
          end
          if next (seq) then
            logreport ("both", 2, "conf",
                       "overriding anon lookup sequence %s.",
                       tableconcat (seq, ","))
            return seq
          end
        end
        logreport ("both", 0, "conf", "no lookup locations enabled, falling back to default precedence list")
        return default_location_precedence
      end
    },
    scan_local   = { in_t = boolean_t, },
    skip_read    = { in_t = boolean_t, },
    strip        = { in_t = boolean_t, },
    update_live  = { in_t = boolean_t, },
    compress     = { in_t = boolean_t, },
    max_fonts    = {
      in_t      = number_t,
      out_t     = number_t, --- TODO int_t from 5.3.x on
      transform = tointeger,
    },
    designsize_dimen = {
      in_t  = string_t,
      out_t = string_t,
    },
  },
  run = {
    anon_sequence = {
      in_t      = string_t,
      out_t     = table_t,
      transform = function (s)
        if s ~= "default" then
          local bits = { lpegmatch (commasplitter, s) }
          if next (bits) then
            local seq = { }
            local done = { }
            for i = 1, #bits do
              local bit = bits [i]
              if valid_resolvers [bit] then
                if not done [bit] then
                  done [bit] = true
                  seq [#seq + 1] = bit
                else
                  logreport ("both", 0, "conf",
                             "ignoring duplicate resolver %s at position %d \z
                              in lookup sequence",
                             bit, i)
                end
              else
                logreport ("both", 0, "conf",
                           "lookup sequence contains invalid item %s \z
                            at position %d.",
                           bit, i)
              end
            end
            if next (seq) then
              logreport ("both", 2, "conf",
                         "overriding anon lookup sequence %s.",
                         tableconcat (seq, ","))
              return seq
            end
          end
        end
        return default_anon_sequence
      end
    },
    live = { in_t = boolean_t, }, --- false for the tool, true for TeX run
    resolver = {
      in_t      = string_t,
      out_t     = string_t,
      transform = function (r) return r == "normal" and r or "cached" end,
    },
    definer = {
      in_t      = string_t,
      out_t     = string_t,
      transform = function (d)
        if   d == "generic"      or d == "patch"
          or d == "info_generic" or d == "info_patch"
        then
          return d
        end
        return "patch"
      end,
    },
    fontloader = {
      in_t      = string_t,
      out_t     = string_t,
      transform = function (id)
        local ldr = pick_fontloader (id)
        if ldr ~= nil then
          return ldr
        end
        logreport ("log", 0, "conf",
                    "Requested fontloader %q not defined, "
                    .. "use at your own risk.",
                    id)
        return id
      end,
    },
    log_level = {
      in_t      = number_t,
      out_t     = number_t, --- TODO int_t from 5.3.x on
      transform = tointeger,
    },
    color_callback = {
      in_t      = string_t,
      out_t     = string_t,
      transform = function (cb_spec)
        --- These are the two that make sense.
        local cb = permissible_color_callbacks[cb_spec]
        if cb then
          logreport ("log", 3, "conf",
                     "Using callback %q for font colorization.",
                     cb)
          return cb
        end
        logreport ("log", 0, "conf",
                    "Requested callback identifier %q invalid, "
                    .. "falling back to default.",
                    cb_spec)
        return permissible_color_callbacks.default
      end,
    },
    default_dvi_driver = {
      in_t      = string_t,
      out_t     = string_t,
      transform = function (driver)
        local mapped = known_dvi_drivers[driver]
        if mapped then
          logreport ("log", 5, "conf",
                     "Using default DVI driver %q if used in DVI mode.",
                     mapped)
          return mapped
        end
        logreport ("log", 0, "conf",
                    "Requested default DVI driver %q invalid, "
                    .. "falling back to dvisvgm.",
                    driver)
        return known_dvi_drivers.dvisvgm
      end,
    },
  },
  misc = {
    bisect          = { in_t = boolean_t, }, --- doesn’t make sense in a config file
    version         = { in_t = string_t,  },
    statistics      = { in_t = boolean_t, },
    termwidth       = {
      in_t      = number_t,
      out_t     = number_t,
      transform = function (w)
        w = tointeger (w)
        if w < min_terminal_width then
          return min_terminal_width
        end
        return w
      end,
    },
    keepnames       = { in_t = boolean_t, },
  },
  paths = {
    names_dir           = { in_t = string_t, },
    cache_dir           = { in_t = string_t, },
    index_file          = { in_t = string_t, },
    lookups_file        = { in_t = string_t, },
    lookup_path_lua     = { in_t = string_t, },
    lookup_path_luc     = { in_t = string_t, },
    index_path_lua      = { in_t = string_t, },
    index_path_luc      = { in_t = string_t, },
  },
  default_features = {
    __default = { in_t  = string_t, out_t = table_t, transform = tohash, },
  },
}

-------------------------------------------------------------------------------
---                               FORMATTERS
-------------------------------------------------------------------------------

local function commented (str)
  return ";" .. str
end

local underscore_replacer = lpeg.replacer ("_", "-", true)

local function dashed (var)
  --- INI spec dictates that dashes are valid in variable names, not
  --- underscores.
  return underscore_replacer (var) or var
end

local indent = "  "
local function format_string (var, val)
  return stringformat (indent .. "%s = %s", var, val)
end

local function format_integer (var, val)
  return stringformat (indent .. "%s = %d", var, val)
end

local function format_boolean (var, val)
  return stringformat (indent .. "%s = %s", var, val == true and "true" or "false")
end

local function format_keyval (var, val)
  local list = { }
  local keys = table.sortedkeys (val)
  for i = 1, #keys do
    local key    = keys[i]
    local subval = val[key]
    if subval == true then
      list[#list + 1] = stringformat ("%s", key)
    else
      list[#list + 1] = stringformat ("%s=%s", key, val[key])
    end
  end
  if next (list) then
    return stringformat (indent .. "%s = %s",
                         var,
                         tableconcat (list, ","))
  end
end

local function format_list (var, val)
  local elts = { }
  for i = 1, #val do elts [i] = val [i] end
  if next (elts) then
    return stringformat (indent .. "%s = %s",
                         var, tableconcat (elts, ","))
  end
end

local function format_section (title)
  return stringformat ("[%s]", dashed (title))
end

local conf_header = [==[
;;-----------------------------------------------------------------------------
;; Luaotfload Configuration
;;-----------------------------------------------------------------------------
;;
;; This file was generated by luaotfload-tool
;; on %s. Configuration variables
;; are documented in the manual to luaotfload.conf(5).
;;
;;-----------------------------------------------------------------------------

]==]

local conf_footer = [==[

;; vim:filetype=dosini:expandtab:shiftwidth=2
]==]

--- Each dumpable variable (the ones mentioned in the man page) receives a
--- formatter that will be used in dumping the variable. Each value receives a
--- “commented” flag that indicates whether or not the line should be printed
--- as a comment.

local formatters = {
  db = {
    compress         = { false, format_boolean },
    designsize_dimen = { false, format_string  },
    formats          = { false, format_string  },
    max_fonts        = { false, format_integer },
    scan_local       = { false, format_boolean },
    skip_read        = { false, format_boolean },
    strip            = { false, format_boolean },
    update_live      = { false, format_boolean },
  },
  default_features = {
    __default = { true, format_keyval },
  },
  misc = {
    bisect     = { false, format_boolean },
    statistics = { false, format_boolean },
    termwidth  = { true , format_integer },
    version    = { true , format_string  },
  },
  paths = {
    cache_dir    = { false, format_string },
    names_dir    = { false, format_string },
    index_file   = { false, format_string },
    lookups_file = { false, format_string },
  },
  run = {
    anon_sequence      = { false, format_list    },
    color_callback     = { false, format_string  },
    definer            = { false, format_string  },
    fontloader         = { true,  format_string  },
    log_level          = { false, format_integer },
    resolver           = { false, format_string  },
    default_dvi_driver = { false, format_string  },
  },
}

-------------------------------------------------------------------------------
---                           MAIN FUNCTIONALITY
-------------------------------------------------------------------------------

--[[doc--

  tilde_expand -- Rudimentary tilde expansion; covers just the “substitute ‘~’
  by the current users’s $HOME” part.

--doc]]--

local function tilde_expand (p)
  if #p > 2 then
    if stringsub (p, 1, 2) == "~/" then
      local homedir = osgetenv "HOME"
      if homedir and lfsisdir (homedir) then
        p = filejoin (homedir, stringsub (p, 3))
      end
    end
  end
  return p
end

local function resolve_config_path ()
  for i = 1, #config_paths do
    local t, p = unpack (config_paths[i])
    local fullname
    if t == kpse_t then
      fullname = kpse.find_file (p)
      logreport ("both", 6, "conf", "kpse lookup: %s -> %s.", p, fullname)
    elseif t == path_t then
      local expanded = tilde_expand (p)
      if lfsisfile (expanded) then
        fullname = expanded
      end
      logreport ("both", 6, "conf", "path lookup: %s -> %s.", p, fullname)
    end
    if fullname then
      logreport ("both", 3, "conf", "Reading configuration file at %q.", fullname)
      return fullname
    end
  end
  logreport ("both", 2, "conf", "No configuration file found.")
  return false
end

local function add_config_paths (t)
  if not next (t) then
    return
  end
  local result = { }
  for i = 1, #t do
    local path = t[i]
    result[#result + 1] = { path_t, path }
  end
  config_paths = tableappend (result, config_paths)
end

local process_options = function (opts)
  local new = { }
  for i = 1, #opts do
    local section = opts[i]
    local title = section.section.title
    local vars  = section.variables

    if not title then --- trigger warning: arrow code ahead
      logreport ("both", 2, "conf", "Section %d lacks a title; skipping.", i)
    elseif not vars then
      logreport ("both", 2, "conf", "Section %d (%s) lacks a variable section; skipping.", i, title)
    else
      local spec = option_spec[title]
      if not spec then
        logreport ("both", 2, "conf", "Section %d (%s) unknown; skipping.", i, title)
      else
        local newsection = new[title]
        if not newsection then
          newsection = { }
          new[title] = newsection
        end

        for var, val in next, vars do
          local vspec = spec[var] or spec.__default
          local t_val = type (val)
          if not vspec then
            logreport ("both", 2, "conf",
                       "Section %d (%s): invalid configuration variable %q (%q); ignoring.",
                       i, title,
                       var, tostring (val))
          elseif t_val ~= vspec.in_t then
            logreport ("both", 2, "conf",
                       "Section %d (%s): type mismatch of input value %q (%q, %s != %s); ignoring.",
                       i, title,
                       var, tostring (val), t_val, vspec.in_t)
          else --- type matches
            local transform = vspec.transform
            if transform then
              local dval
              local t_transform = type (transform)
              if t_transform == function_t then
                dval = transform (val)
              elseif t_transform == table_t then
                dval = transform[val]
              end
              if dval then
                local out_t = vspec.out_t
                if out_t then
                  local t_dval = type (dval)
                  if t_dval == out_t then
                    newsection[var] = dval
                  else
                    logreport ("both", 2, "conf",
                               "Section %d (%s): type mismatch of derived value of %q (%q, %s != %s); ignoring.",
                               i, title,
                               var, tostring (dval), t_dval, out_t)
                  end
                else
                  newsection[var] = dval
                end
              else
                logreport ("both", 2, "conf",
                           "Section %d (%s): value of %q could not be derived via %s from input %q; ignoring.",
                           i, title, var, t_transform, tostring (val))
              end
            else --- insert as is
              newsection[var] = val
            end
          end
        end
      end
    end
  end
  return new
end

local function apply (old, new)
  if not new then
    if not old then
      return false
    end
    return tablecopy (old)
  elseif not old then
    return tablecopy (new)
  end
  local result = tablecopy (old)
  for name, section in next, new do
    local t_section = type (section)
    if t_section ~= table_t then
      logreport ("both", 1, "conf",
                 "Error applying configuration: entry %s is %s, expected table.",
                 section, t_section)
      --- ignore
    else
      local currentsection = result[name]
      for var, val in next, section do
        currentsection[var] = val
      end
    end
  end
  result.status = luaotfloadstatus
  return result
end

local function reconfigure()
  for i = 1, #reconf_tasks do
    local name, task = unpack (reconf_tasks[i])
    logreport ("both", 3, "conf", "Launch post-configuration task %q.", name)
    if not task () then
      logreport ("both", 0, "conf", "Post-configuration task %q failed.", name)
      return false
    end
  end
  return true
end

local function read (extra)
  if extra then
    add_config_paths (extra)
  end

  local readme = resolve_config_path ()
  if readme == false then
    logreport ("both", 2, "conf", "No configuration file.")
    return false
  end

  local raw = ioloaddata (readme)
  if not raw then
    logreport ("both", 2, "conf", "Error reading the configuration file %q.", readme)
    return false
  end

  local parsed = lpegmatch (config_parser, raw)
  if not parsed then
    logreport ("both", 2, "conf", "Error parsing configuration file %q.", readme)
    return false
  end

  local ret, msg = process_options (parsed)
  if not ret then
    logreport ("both", 2, "conf", "File %q is not a valid configuration file.", readme)
    logreport ("both", 2, "conf", "Error: %s", msg)
    return false
  end
  return ret
end

local function apply_defaults ()
  local defaults      = default_config
  local vars          = read ()
  --- Side-effects galore ...
  config.luaotfload   = apply (defaults, vars)
  return reconfigure ()
end

local function dump ()
  local sections = table.sortedkeys (config.luaotfload)
  local confdata = { }
  for i = 1, #sections do
    local section    = sections[i]
    local vars       = config.luaotfload[section]
    local varnames   = table.sortedkeys (vars)
    local sformats   = formatters[section]
    if sformats then
      confdata[#confdata + 1] = format_section (section)
      for j = 1, #varnames do
        local var = varnames[j]
        local val = vars[var]
        local comment, sformat = unpack (sformats[var] or { })
        if not sformat then
          comment, sformat = unpack (sformats.__default or { })
        end

        if sformat then
          local dashedvar = dashed (var)
          if comment then
            confdata[#confdata + 1] = commented (sformat (dashedvar, val))
          else
            confdata[#confdata + 1] = sformat (dashedvar, val)
          end
        end

      end
      confdata[#confdata + 1] = ""
    end
  end
  if next(confdata) then
    iowrite (stringformat (conf_header,
                           osdate ("%Y-%m-%d %H:%M:%S", os.time ())))
    iowrite (tableconcat (confdata, "\n"))
    iowrite (conf_footer)
  end
end

-------------------------------------------------------------------------------
---                                 EXPORTS
-------------------------------------------------------------------------------

return function ()
  config.luaotfload = { }
  logreport         = luaotfload.log.report
  local parsers     = luaotfload.parsers
  config_parser     = parsers.config
  stripslashes      = parsers.stripslashes

  luaotfload.default_config = default_config
  config.actions = {
    read             = read,
    apply            = apply,
    apply_defaults   = apply_defaults,
    reconfigure      = reconfigure,
    dump             = dump,
  }
  if not apply_defaults () then
    logreport ("log", 0, "load",
               "Configuration unsuccessful: error loading default settings.")
  end
  return true
end
