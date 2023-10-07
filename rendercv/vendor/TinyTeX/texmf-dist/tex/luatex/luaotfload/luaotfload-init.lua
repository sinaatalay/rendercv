-----------------------------------------------------------------------
--         FILE:  luaotfload-init.lua
--  DESCRIPTION:  part of luaotfload / font loader initialization
-- REQUIREMENTS:  luatex v.0.80 or later; packages lualibs
--       AUTHOR:  Philipp Gesang (Phg), <phg@phi-gamma.net>, Marcel Krüger
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") {
    name          = "luaotfload-init",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / initialization",
    license       = "GPL v2.0"
}
-----------------------------------------------------------------------


local setmetatable = setmetatable
local kpsefind_file   = kpse.find_file
local lfsisdir     = lfs.isdir

--[[doc--

  Initialization phases:

      - Load Lualibs from package
      - Set up the logger routines
      - Load Fontloader
          - as package specified in configuration
          - from Context install
          - (optional: from raw unpackaged files distributed with
            Luaotfload)

  The initialization of the Lualibs may be made configurable in the
  future as well allowing to load both the files and the merged package
  depending on a configuration setting. However, this would require
  separating out the configuration parser into a self-contained
  package, which might be problematic due to its current dependency on
  the Lualibs itself.

--doc]]--

local log        --- filled in after loading the log module
local logreport  --- filled in after loading the log module

--[[doc--

    \subsection{Preparing the Font Loader}
    We treat the fontloader as a semi-black box so behavior is
    consistent between formats.
    We load the fontloader code directly in the same fashion as the
    Plain format \identifier{luatex-fonts} that is part of Context.
    How this is executed depends on the presence on the
    \emphasis{merged font loader code}.
    In \identifier{luaotfload} this is contained in the file
    \fileent{luaotfload-merged.lua}.
    If this file cannot be found, the original libraries from \CONTEXT
    of which the merged code was composed are loaded instead.
    Since these files are not shipped with Luaotfload, an installation
    of Context is required.
    (Since we pull the fontloader directly from the Context minimals,
    the necessary Context version is likely to be more recent than that
    of other TeX distributions like Texlive.)
    The imported font loader will call \luafunction{callback.register}
    once while reading \fileent{font-def.lua}.
    This is unavoidable unless we modify the imported files, but
    harmless if we make it call a dummy instead.
    However, this problem might vanish if we decide to do the merging
    ourselves, like the \identifier{lualibs} package does.
    With this step we would obtain the freedom to load our own
    overrides in the process right where they are needed, at the cost
    of losing encapsulation.
    The decision on how to progress is currently on indefinite hold.

--doc]]--

--- below paths are relative to the texmf-context

local ignore, ltx, ctx = 0, 1, 2

local context_module_paths = { -- [ltx] =
  "tex/generic/context/luatex", -- [ctx] =
  {"tex/context/base/mkiv", "tex/context/base" },
}

local context_modules = {

  --- Since 2.6 those are directly provided by the Lualibs package.
  { ignore, "l-lua"      },
  { ignore, "l-lpeg"     },
  { ignore, "l-function" },
  { ignore, "l-string"   },
  { ignore, "l-table"    },
  { ignore, "l-io"       },
  { ignore, "l-file"     },
  { ignore, "l-boolean"  },
  { ignore, "l-math"     },
  { ignore, "l-unicode"  }, -- NEW UF 19.09.2018
  { ignore, "util-str"   },
  { ignore, "util-fil"   },

  --- These constitute the fontloader proper.
  { ltx,   "basics-gen" },
  { ctx,   "data-con"          },
  { ltx,   "basics-nod" },
  { ltx,   "basics-chr" }, -- NEW UF 14.12.2018
  { ctx,   "font-ini"          },
  { ltx,   "fonts-mis"  }, -- NEW UF 19.09.2018
  { ctx,   "font-con"          },
  { ltx,   "fonts-enc"  },
  { ctx,   "font-cid"          },
  { ctx,   "font-map"          },
--  { ltx,   "fonts-syn"  }, -- ignore??
  { ctx,   "font-vfc"          }, -- NEW UF 19.09.2018
  { ctx,   "font-otr"          },
  { ctx,   "font-cff"          },
  { ctx,   "font-ttf"          },
  { ctx,   "font-dsp"          },
  { ctx,   "font-oti"          },
  { ctx,   "font-ott"          },
  { ctx,   "font-otl"          },
  { ctx,   "font-oto"          },
  { ctx,   "font-otj"          },
  { ctx,   "font-oup"          },
  { ctx,   "font-ota"          },
  { ctx,   "font-ots"          },
  { ctx,   "font-otc"          },
  { ctx,   "font-osd"          },
  { ctx,   "font-ocl"          },
  { ctx,   "font-onr"          },
  { ctx,   "font-one"          },
  { ctx,   "font-afk"          },
  { ltx,   "fonts-tfm"  },
  { ctx,   "font-lua"          },
  { ctx,   "font-def"          },
  { ctx,   "font-shp"          },
  { ltx,   "fonts-def"  },
  { ltx,   "fonts-ext"  },
  { ctx,   "font-imp-tex"      },
  { ctx,   "font-imp-ligatures"},
  { ctx,   "font-imp-italics"  },
  { ctx,   "font-imp-effects"  },
  { ltx,   "fonts-lig"  },
  { ltx,   "fonts-gbn"  },

} --[[context_modules]]

local function load_context_modules (pth)

  local load_module   = luaotfload.loaders.context
  local ignore_module = luaotfload.loaders.ignore

  logreport ("both", 2, "init",
             "Loading fontloader components from context.")
  for i = 1, #context_modules do
    local kind, spec = unpack (context_modules [i])
    if kind == ignore then
      ignore_module (spec)
    else
      if kind == ltx then
        spec = 'luatex-' .. spec
      end
      local sub = context_module_paths[kind]
      local tsub = type (sub)
      if not pth then
        load_module (spec)
      elseif tsub == "string" then
        load_module (spec, file.join (pth, sub))
      elseif tsub == "table" then
        local pfx
        local nsub = #sub
        for j = 1, nsub do
          local full = file.join (pth, sub [j])
          if lfsisdir (full) then --- pick the first real one
            pfx = full
            break
          end
        end
        if pfx then
          load_module (spec, pfx)
        else
          logreport ("both", 0, "init",
                     "None of the %d search paths for module %q exist; \z
                      falling back to default path.",
                     nsub, tostring (spec))
          load_module (spec) --- maybe we’ll get by after all?
        end
      else
        logreport ("both", 0, "init",
                   "Internal error, please report. \z
                    This is not your fault.")
        os.exit (-1)
      end
    end
  end

end

local function verify_context_dir (pth)
  if lfsisdir(file.join(pth, context_module_paths[ltx])) then
    return true
  end
  for _, d in ipairs(context_module_paths[ctx]) do
    if lfsisdir(file.join(pth, d)) then
      return true
    end
  end
  logreport("both", 0, "init", "A directory name has been passed as \z
    fontloader name but this directory does not acutally seem to contain \z
    a font loader. I will try to interpret your fontloader name in another \z
    way for now, but please fix your settings.")
  return false
end

local function init_main(early_hook)
  config                       = config or { } --- global
  config.luaotfload            = config.luaotfload or { }
  config.lualibs               = config.lualibs    or { }
  config.lualibs.verbose       = false
  config.lualibs.prefer_merged = true
  config.lualibs.load_extended = true
  fonts                        = fonts or { }

  require "lualibs"

  if not lualibs    then error "this module requires Luaotfload" end
  if not luaotfload then error "this module requires Luaotfload" end

  --[[doc--

    The logger needs to be in place prior to loading the fontloader due
    to order of initialization being crucial for the logger functions
    that are swapped.

  --doc]]--

  luaotfload.loaders.luaotfload "log"
  log       = luaotfload.log
  logreport = log.report
  log.set_loglevel (default_log_level)

  logreport ("log", 4, "init", "Concealing callback.register().")
  local trapped_register = callback.register

  function callback.register (id)
    logreport ("log", 4, "init",
               "Dummy callback.register() invoked on %s.",
               id)
  end

  --[[doc--

    By default, the fontloader requires a number of \emphasis{private
    attributes} for internal use.
    These must be kept consistent with the attribute handling methods
    as provided by \identifier{luatexbase}.
    Our strategy is to override the function that allocates new
    attributes before we initialize the font loader, making it a
    wrapper around \luafunction{luatexbase.new_attribute}.\footnote{%
        Many thanks, again, to Hans Hagen for making this part
        configurable!
    }
    The attribute identifiers are prefixed “\fileent{luaotfload@}” to
    avoid name clashes.

  --doc]]--

  local new_attribute    = luatexbase.new_attribute
  local the_attributes   = luatexbase.attributes

  local context_environment = luaotfload.fontloader
  context_environment.CONTEXTLMTXMODE = 0
  context_environment.attributes = {
    private = function (name)
      local attr   = "luaotfload@" .. name --- used to be: “otfl@”
      local number = the_attributes[attr]
      if not number then number = new_attribute(attr) end
      return number
    end
  }

  --[[doc--

      First save a copy of font.each in order to also catch old-style fonts

  --doc]]--

  font.originaleach = font.each

  local load_fontloader_module = luaotfload.loaders.fontloader
  local ignore_module          = luaotfload.loaders.ignore

  do
    local saved_reporter = texio.reporter
    local saved_exit = os.exit
    local errmsg
    function texio.reporter(msg, ...)
      errmsg = msg
    end
    function os.exit()
      error(errmsg)
    end
    load_fontloader_module "basics-gen"
    texio.reporter = saved_reporter
    os.exit = saved_exit
  end

  if early_hook then early_hook() end

  --[[doc--

      The font loader requires that the attribute with index zero be
      zero. We happily oblige.
      (Cf. \fileent{luatex-fonts-nod.lua}.)

  --doc]]--

  tex.attribute[0] = 0

  --[[doc--

      Now that things are sorted out we can finally load the
      fontloader.

  --doc]]--

  local fontloader = config.luaotfload and config.luaotfload.run.fontloader
                                        or "reference"
  fontloader = tostring (fontloader)

  if fontloader == "reference" then
    logreport ("log", 0, "init", "Using reference fontloader.")
    load_fontloader_module (luaotfload.fontloader_package)

  elseif fontloader == "default" then
    --- Same as above but loader name not correctly replaced by the file name
    --- of our fontloader package. Perhaps something’s wrong with the status
    --- file which contains the datestamped filename? In any case, it can’t
    --- hurt reporting it as a bug.
    logreport ("both", 0, "init", "Fontloader substitution failed, got \"default\".")
    logreport ("log",  4, "init", "Falling back to reference fontloader.")
    load_fontloader_module (luaotfload.fontloader_package)

  elseif fontloader == "unpackaged" then

    logreport ("log", 0, "init",
               "Loading fontloader components individually.")
    for i = 1, #context_modules do
      local mod = context_modules[i];
      (mod[1] == ignore and ignore_module or load_fontloader_module)(mod[2])
    end

  elseif fontloader == "context" then
    logreport ("log", 0, "init",
               "Loading Context modules in lookup path.")
    load_context_modules ()

  elseif lfsisdir (fontloader) and verify_context_dir (fontloader) then
    logreport ("log", 0, "init",
               "Loading Context files under prefix %q.",
               fontloader)
    load_context_modules (fontloader)

  elseif lfs.isfile (fontloader) then
    logreport ("log", 0, "init",
               "Loading fontloader from absolute path %q.",
               fontloader)
    local _void = assert (loadfile (fontloader, nil, context_environment)) ()

  elseif kpsefind_file (fontloader) then
    local path = kpsefind_file (fontloader)
    logreport ("log", 0, "init",
               "Loading fontloader %q from kpse-resolved path %q.",
               fontloader, path)
    local _void = assert (loadfile (path, nil, context_environment)) ()

  elseif kpsefind_file (("fontloader-%s.lua"):format(fontloader)) then
    logreport ("log", 0, "init",
               "Using predefined fontloader %q.",
               fontloader)
    load_fontloader_module (fontloader)

  else
    logreport ("both", 0, "init",
               "No match for requested fontloader %q.",
               fontloader)
    fontloader = luaotfload.fontloader_package
    logreport ("both", 0, "init",
               "Defaulting to predefined fontloader %q.",
               fontloader)
    load_fontloader_module (fontloader)
  end

  ---load_fontloader_module "font-odv.lua" --- <= Devanagari support from Context

  logreport ("log", 0, "init",
             "Context OpenType loader version %.3f",
             fonts.handlers.otf.version)
  callback.register = trapped_register
  nodes = context_environment.nodes
  -- setmetatable(context_environment, nil) -- Would be nice, might break the
  -- fontloader
end --- [init_main]

if not luatexbase.callbacktypes.pre_shaping_filter then
  luatexbase.create_callback('pre_shaping_filter', 'list')
  luatexbase.create_callback('post_shaping_filter', 'reverselist')
end

local init_post_install_callbacks = function ()
  --[[doc--

    we do our own callback handling with the means provided by
    luatexbase.
    note: \luafunction{pre_linebreak_filter} and
    \luafunction{hpack_filter} are coupled in \context in the
    concept of \emphasis{node processor}.

  --doc]]--

  -- The order is important here: multiscript=auto needs to look at the
  -- fallback fonts, so they already have to be processed at that stage
  local fallback = luaotfload.loaders.luaotfload "fallback".process
  local multiscript = luaotfload.loaders.luaotfload "multiscript".process

  local call_callback = luatexbase.call_callback
  local tex_get = tex.get
  local flush_list = node.flush_list
  local handler = luaotfload.fontloader.nodes.simple_font_handler
  local function callback(head, groupcode, _, _, direction)
    if not direction then
      direction = tex_get'textdirection'
    else
      direction = direction == "TRT" and 1 or 0
    end
    local result = call_callback("pre_shaping_filter", head, groupcode, direction)
    if result == false then
      return false
    elseif result ~= true then
      head = result
    end
    multiscript(head, nil, nil, nil, direction)
    fallback(head, nil, nil, nil, direction)
    result = handler(head, groupcode, nil, nil, direction)
    -- handler never returns a boolean and only returns nil if it was passed in
    -- We keep it general though for consistency
    if result == false then
      flush_list(head)
      return nil
    elseif result ~= true then
      head = result
    end
    result = call_callback("post_shaping_filter", head, groupcode, direction)
    if result == false then
      flush_list(head)
      return nil
    elseif result == true then
      return head
    else
      return result
    end
  end
  luatexbase.add_to_callback("pre_linebreak_filter",
                             callback,
                             "luaotfload.node_processor",
                             1)
  luatexbase.add_to_callback("hpack_filter",
                             callback,
                             "luaotfload.node_processor",
                             1)

  local streams = fonts.hashes.streams
  luatexbase.add_to_callback("glyph_stream_provider",function(id,index,mode)
    if id <= 0 then return "" end
    local stream = streams[id].streams
    if not stream then return "" end
    return stream[index] or ""
  end, "luaotfload.glyph_stream")
end

local function init_post_load_agl ()

  --[[doc--

      Adobe Glyph List.
      -----------------------------------------------------------------

      Context provides a somewhat different font-age.lua from an
      unclear origin. Unfortunately, the file name it reads from is
      hard-coded in font-enc.lua, so we have to replace the entire
      table.

      This shouldn’t cause any complications. Due to its implementation
      the glyph list will be loaded upon loading a OTF or TTF for the
      first time during a TeX run. (If one sticks to TFM/OFM then it is
      never read at all.) For this reason we can install a metatable
      that looks up the file of our choosing and only falls back to the
      Context one in case it cannot be found.

  --doc]]--

  local encodings = fonts.encodings

  if not encodings then
    --- Might happen during refactoring; we continue graciously but in
    --- a somewhat defect state.
    logreport ("log", 0, "init",
               "preconditions unmet, skipping the Adobe Glyph List; "
               .. "this is a Luaotfload bug.")
    return
  end

  if next (fonts.encodings.agl) then
      --- unnecessary because the file shouldn’t be loaded at this time
      --- but we’re just making sure
      fonts.encodings.agl = nil
      collectgarbage"collect"
  end

  local agl_init = { }      --- start out empty, fill on demand
  encodings.agl  = agl_init --- ugh, replaced again later

  setmetatable (agl_init, { __index = function (t, k)

    if k ~= "unicodes" then
      return nil
    end

    local glyphlist = kpsefind_file "luaotfload-glyphlist.lua"
    if glyphlist then
      logreport ("log", 1, "init", "loading the Adobe glyph list")
    else
      glyphlist = kpsefind_file "font-age.lua"
      logreport ("both", 0, "init",
                 "loading the extended glyph list from ConTeXt")
    end

    if not glyphlist then
      logreport ("both", 4, "init",
                 "Adobe glyph list not found, please check your installation.")
      return nil
    end
    logreport ("both", 4, "init",
               "found Adobe glyph list file at %q, using that.",
               glyphlist)

    local unicodes = dofile(glyphlist)
    encodings.agl  = { unicodes = unicodes }
    return unicodes
  end })

end

local function init_post_apply_keepnames ()
  local keepnames = config.luaotfload.misc.keepnames
  luaotfload.fontloader.fonts.privateoffsets.keepnames = keepnames
end

--- (unit -> unit) list
local init_post_actions = {
  init_post_install_callbacks,
  init_post_load_agl,
  init_post_apply_keepnames
}

--- unit -> size_t
local function init_post ()
  --- hook for actions that need to take place after the fontloader is
  --- installed

  local n = #init_post_actions
  for i = 1, n do
    local action = init_post_actions[i]
    local taction = type (action)
    if not action or taction ~= "function" then
      logreport ("both", 1, "init",
                 "post hook WARNING: action %d not a function but %s/%s; ignoring.",
                 i, action, taction)
    else
      --- call closure
      action ()
    end
  end

  return n
end --- [init_post]

return function (early_hook)
  local starttime = os.gettimeofday ()
  init_main (early_hook)
  logreport ("both", 1, "init",
             "fontloader loaded in %0.3f seconds",
             os.gettimeofday() - starttime)
  local n = init_post ()
  logreport ("both", 5, "init", "post hook terminated, %d actions performed", n)
  return true
end
-- vim:tw=79:sw=2:ts=2:expandtab
