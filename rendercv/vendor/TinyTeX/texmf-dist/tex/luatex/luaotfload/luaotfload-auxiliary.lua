-----------------------------------------------------------------------
--         FILE:  luaotfload-auxiliary.lua
--  DESCRIPTION:  part of luaotfload
--       AUTHOR:  Khaled Hosny, Élie Roux, Philipp Gesang
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") {
    name          = "luaotfload-auxiliary",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / auxiliary functions",
    license       = "GPL v2.0"
}

luaotfload                  = luaotfload or { }
local log                   = luaotfload.log
local logreport             = log.report
local fonthashes            = fonts.hashes
local encodings             = fonts.encodings
local identifiers           = fonthashes.identifiers
local fontnames             = fonts.names

local fontid                = font.id
local texsprint             = tex.sprint

local dofile                = dofile
local getmetatable          = getmetatable
local setmetatable          = setmetatable
local utfcodepoint          = utf8.codepoint
local stringlower           = string.lower
local stringupper           = string.upper
local stringformat          = string.format
local stringgsub            = string.gsub
local stringbyte            = string.byte
local stringfind            = string.find
local tablecopy             = table.copy

local harf = luaotfload.harfbuzz
local GSUBtag, GPOStag
if harf then
  GSUBtag = harf.Tag.new("GSUB")
  GPOStag = harf.Tag.new("GPOS")
end

local aux                   = { }
local luaotfload_callbacks  = { }

-----------------------------------------------------------------------
---                          font patches
-----------------------------------------------------------------------

--- https://github.com/khaledhosny/luaotfload/issues/54

local function rewrite_fontname(tfmdata, specification)
  local format = tfmdata.format or tfmdata.properties.format
  if stringfind (specification, " ") then
    tfmdata.name = stringformat ("%q", specification)
  else
    --- other specs should parse just fine
    tfmdata.name = specification
  end
end

local rewriting = false

function aux.start_rewrite_fontname()
  if rewriting == false then
    luatexbase.add_to_callback (
      "luaotfload.patch_font",
      rewrite_fontname,
      "luaotfload.rewrite_fontname")
    rewriting = true
    logreport ("log", 1, "aux",
               "start rewriting tfmdata.name field")
  end
end

function aux.stop_rewrite_fontname()
  if rewriting == true then
    luatexbase.remove_from_callback
      ("luaotfload.patch_font", "luaotfload.rewrite_fontname")
    rewriting = false
    logreport ("log", 1, "aux",
               "stop rewriting tfmdata.name field")
  end
end


--[[doc--
This sets two dimensions apparently relied upon by the unicode-math
package.
--doc]]--

local function set_sscale_dimens(fontdata)
  local resources     = fontdata.resources      if not resources     then return end
  local mathconstants = resources.MathConstants if not mathconstants then return end
  local parameters    = fontdata.parameters     if not parameters    then return end
  --- the default values below are complete crap
  parameters [10] = mathconstants.ScriptPercentScaleDown       or 70
  parameters [11] = mathconstants.ScriptScriptPercentScaleDown or 50
end

luaotfload_callbacks [#luaotfload_callbacks + 1] = {
  "patch_font", set_sscale_dimens, "set_sscale_dimens",
}

-- Starting with LuaTeX 1.11.2, this is a more reliable way of selecting the
-- right font than relying on psnames
luaotfload_callbacks [#luaotfload_callbacks + 1] = {
  "patch_font", function(fontdata)
    fontdata.subfont = fontdata.specification.sub or 1
  end, "set_font_index",
}

local default_units = 1000

--- fontobj -> int
local function lookup_units(fontdata)
  local units = fontdata.units
  if units and units > 0 then return units end
  local shared     = fontdata.shared    if not shared     then return default_units end
  local rawdata    = shared.rawdata     if not rawdata    then return default_units end
  local metadata   = rawdata.metadata   if not metadata   then return default_units end
  local capheight  = metadata.capheight if not capheight  then return default_units end
  local units      = metadata.units or fontdata.units
  if not units or units == 0 then
    return default_units
  end
  return units
end

--[[doc--
This callback corrects some values of the Cambria font.
--doc]]--
--- fontobj -> unit
local function patch_cambria_domh(fontdata)
  local mathconstants = fontdata.MathConstants
  if mathconstants and fontdata.psname == "CambriaMath" then
    --- my test Cambria has 2048
    local units = fontdata.units or lookup_units(fontdata)
    local sz    = fontdata.parameters.size or fontdata.size
    local mh    = 2800 / units * sz
    if mathconstants.DisplayOperatorMinHeight < mh then
      mathconstants.DisplayOperatorMinHeight = mh
    end
  end
end

luaotfload_callbacks [#luaotfload_callbacks + 1] = {
  "patch_font", patch_cambria_domh, "patch_cambria_domh",
}


--[[doc--

  Add missing field to fonts that lack it. Addresses issue
  https://github.com/lualatex/luaotfload/issues/253

  This is considered a hack, especially since importing the
  unicode-math package fixes the problem quite nicely.

--doc]]--

--- fontobj -> unit
local function fixup_fontdata(data)
  local t = type (data)
  --- Some OT fonts like Libertine R lack the resources table, causing
  --- the fontloader to nil-index.
  if t == "table" then
    if data and not data.resources then data.resources = { } end
  end
end

luaotfload_callbacks [#luaotfload_callbacks + 1] = {
  "patch_font_unsafe", fixup_fontdata, "fixup_fontdata",
}


--[[doc--

Comment from fontspec:

 “Here we patch fonts tfm table to emulate \XeTeX's \cs{fontdimen8},
  which stores the caps-height of the font. (Cf.\ \cs{fontdimen5} which
  stores the x-height.)

  Falls back to measuring the glyph if the font doesn't contain the
  necessary information.
  This needs to be extended for fonts that don't contain an `X'.”

--doc]]--

local capheight_reference_chars      = { "X", "M", "Ж", "ξ", }
local capheight_reference_codepoints do
  capheight_reference_codepoints = { }
  for i = 1, #capheight_reference_chars do
    local chr = capheight_reference_chars [i]
    capheight_reference_codepoints [i] = utfcodepoint (chr)
  end
end

local function determine_capheight(fontdata)
  local parameters = fontdata.parameters if not parameters then return false end
  local characters = fontdata.characters if not characters then return false end
  --- Pretty simplistic but it does return *some* value for most fonts;
  --- we could also refine the approach to return some kind of average
  --- of all capital letters or a user-provided subset.
  for i = 1, #capheight_reference_codepoints do
    local refcp   = capheight_reference_codepoints [i]
    local refchar = characters [refcp]
    if refchar then
      logreport ("both", 4, "aux",
                 "picked height of character '%s' (U+%04X) as \\fontdimen8 \z
                  candidate",
                 capheight_reference_chars [i], refcp)
      return refchar.height
    end
  end
  return false
end

local function query_ascender(fontdata)
  local parameters = fontdata.parameters if not parameters then return false end
  local ascender   = parameters.ascender
  if ascender then
    return ascender --- pre-scaled
  end

  local shared     = fontdata.shared     if not shared     then return false end
  local rawdata    = shared.rawdata      if not rawdata    then return false end
  local metadata   = rawdata.metadata    if not metadata   then return false end
  ascender         = metadata.ascender   if not ascender   then return false end
  local size       = parameters.size     if not size       then return false end
  local units = lookup_units (fontdata)
  if not units or units == 0 then return false end
  return ascender * size / units --- scaled
end

local function query_capheight(fontdata)
  local parameters = fontdata.parameters  if not parameters then return false end
  local shared     = fontdata.shared      if not shared     then return false end
  local rawdata    = shared.rawdata       if not rawdata    then return false end
  local metadata   = rawdata.metadata     if not metadata   then return false end
  local capheight  = metadata.capheight   if not capheight  then return false end
  local size       = parameters.size      if not size       then return false end
  local units = lookup_units (fontdata)
  if not units or units == 0 then return false end
  return capheight * size / units
end

local function query_fontdimen8(fontdata)
  local parameters = fontdata.parameters if not parameters then return false end
  local fontdimen8 = parameters [8]
  if fontdimen8 then return fontdimen8 end
  return false
end

local function caphtfmt(ref, ht)
  if not ht  then return "<none>"      end
  if not ref then return tostring (ht) end
  return stringformat ("%s(δ=%s)", ht, ht - ref)
end

local function set_capheight(fontdata)
    if not fontdata then
      logreport ("both", 0, "aux",
                 "error: set_capheight() received garbage")
      return
    end
    local capheight_dimen8   = query_fontdimen8    (fontdata)
    local capheight_alleged  = query_capheight     (fontdata)
    local capheight_ascender = query_ascender      (fontdata)
    local capheight_measured = determine_capheight (fontdata)
    logreport ("term", 4, "aux",
               "capht: param[8]=%s advertised=%s ascender=%s measured=%s",
               tostring (capheight_dimen8),
               caphtfmt (capheight_dimen8, capheight_alleged),
               caphtfmt (capheight_dimen8, capheight_ascender),
               caphtfmt (capheight_dimen8, capheight_measured))
    if capheight_dimen8 then --- nothing to do
      return
    end

    local capheight = capheight_alleged or capheight_ascender or capheight_measured
    if capheight then
      fontdata.parameters [8] = capheight
    end
end

luaotfload_callbacks [#luaotfload_callbacks + 1] = {
  "patch_font", set_capheight, "set_capheight",
}

-- Of course there are also fonts with no sensible x-height, so let's add a
-- fallback there:
local function set_xheight(tfmdata)
  local parameters = tfmdata.parameters
  if not parameters then return end
  if not ((parameters.x_height or parameters[5] or 0) == 0) then return end
  if tfmdata.characters and tfmdata.characters[120] then
    parameters.x_height = tfmdata.characters[120].height
  else
    parameters.x_height = (parameters.ascender or 0)/2
  end
end
luaotfload_callbacks [#luaotfload_callbacks + 1] = {
  "patch_font", set_xheight, "set_xheight",
}
-----------------------------------------------------------------------
---                      glyphs and characters
-----------------------------------------------------------------------

--- int -> int -> bool
function aux.font_has_glyph(font_id, codepoint)
  local fontdata = fonts.hashes.identifiers[font_id]
  if fontdata then
    if fontdata.characters[codepoint] ~= nil then return true end
  end
  return false
end

--- undocumented

local function raw_slot_of_name(font_id, glyphname)
  local fontdata = font.fonts[font_id]
  if fontdata.type == "virtual" then --- get base font for glyph idx
    local codepoint  = encodings.agl.unicodes[glyphname]
    local glyph      = fontdata.characters[codepoint]
    if fontdata.characters[codepoint] then
      return codepoint
    end
  end
  return false
end

--[[doc--

  This one is approximately “name_to_slot” from the microtype package;
  note that it is all about Adobe Glyph names and glyph slots in the
  font. The names and values may diverge from actual Unicode.

  http://www.adobe.com/devnet/opentype/archives/glyph.html

  The “unsafe” switch triggers a fallback lookup in the raw fonts
  table. As some of the information is stored as references, this may
  have unpredictable side-effects.

--doc]]--

--- int -> string -> bool -> (int | false)
function aux.slot_of_name(font_id, glyphname, unsafe)
  if not font_id   or type (font_id)   ~= "number"
  or not glyphname or type (glyphname) ~= "string"
  then
    logreport ("both", 0, "aux",
               "invalid parameters to slot_of_name (%s, %s)",
               tostring (font_id), tostring (glyphname))
    return false
  end

  local tfmdata = identifiers [font_id]
  if not tfmdata then return raw_slot_of_name (font_id, glyphname) end
  local hbdata = tfmdata.hb
  if hbdata then
    local hbshared = hbdata.shared
    local nominals = hbshared.nominals
    local hbfont = hbshared.font

    local gid = hbfont:get_glyph_from_name(glyphname)
    if gid ~= nil then
      return nominals[gid] or gid + hbshared.gid_offset
    end
  else
    local resources = tfmdata.resources  if not resources then return false end
    local unicodes  = resources.unicodes if not unicodes  then return false end

    local unicode = unicodes [glyphname]
    if unicode then
      if type (unicode) == "number" then
        return unicode
      else
        return unicode [1] --- for multiple components
      end
    end
  end
  return false
end

--[[doc--

  Inverse of above; not authoritative as to my knowledge the official
  inverse of the AGL is the AGLFN. Maybe this whole issue should be
  dealt with in a separate package that loads char-def.lua and thereby
  solves the problem for the next couple decades.

  http://partners.adobe.com/public/developer/en/opentype/aglfn13.txt

--doc]]--

local indices

--- int -> (string | false)
function aux.name_of_slot(codepoint)
  if not codepoint or type (codepoint) ~= "number" then
    logreport ("both", 0, "aux",
               "invalid parameters to name_of_slot (%s)",
               tostring (codepoint))
    return false
  end

  if not indices then --- this will load the glyph list
    local unicodes = encodings.agl.unicodes
    if not unicodes or not next (unicodes)then
      logreport ("both", 0, "aux",
                 "name_of_slot: failed to load the AGL.")
    end
    indices = table.swapped (unicodes)
  end

  local glyphname = indices [codepoint]
  if glyphname then
    return glyphname
  end
  return false
end

--[[doc--

  Get the GID of the glyph associated with a given name.

--doc]]--
function aux.gid_of_name(font_id, glyphname)
  local slot = aux.slot_of_name(font_id, glyphname)
  if not slot then return end
  local tfmdata = identifiers[font_id] or font.fonts[font_id]
  -- assert(tfmdata) -- Otherwise slot_of_name would have failed already
  return tfmdata.characters[slot].index or slot
end

-----------------------------------------------------------------------
---                 features / scripts / languages
-----------------------------------------------------------------------
--- lots of arrowcode ahead

local function get_features(tfmdata)
  local resources = tfmdata.resources  if not resources then return false end
  local features  = resources.features if not features  then return false end
  return features
end

local function get_hbface(tfmdata)
  if not tfmdata.hb then return end
  return tfmdata.hb.shared.face
end

--[[doc--
This function, modeled after “check_script()” from fontspec, returns
true if in the given font, the script “asked_script” is accounted for in at
least one feature.
--doc]]--

--- int -> string -> bool
function aux.provides_script(font_id, asked_script)
  if not font_id      or type (font_id)      ~= "number"
  or not asked_script or type (asked_script) ~= "string"
  then
    logreport ("both", 0, "aux",
               "invalid parameters to provides_script(%s, %s)",
               tostring (font_id), tostring (asked_script))
    return false
  end
  asked_script = stringlower(asked_script)
  local tfmdata = identifiers[font_id]
  if not tfmdata then
    logreport ("log", 0, "aux", "no font with id %d", font_id)
    return false
  end
  local hbface = get_hbface(tfmdata)
  if hbface then
    local script = harf.Tag.new(asked_script == "dflt" and "DFLT"
                                                        or asked_script)
    for _, tag in next, { GSUBtag, GPOStag } do
      if hbface:ot_layout_find_script(tag, script) then
        return true
      end
    end
    return false
  else
    local features = get_features (tfmdata)
    if features == false then
      logreport ("log", 1, "aux", "font no %d lacks a features table", font_id)
      return false
    end
    for method, featuredata in next, features do
      --- where method: "gpos" | "gsub"
      for feature, data in next, featuredata do
        if data[asked_script] then
          logreport ("log", 1, "aux",
                     "font no %d (%s) defines feature %s for script %s",
                     font_id, fontname, feature, asked_script)
          return true
        end
      end
    end
    logreport ("log", 0, "aux",
               "font no %d (%s) defines no feature for script %s",
               font_id, fontname, asked_script)
  end
  return false
end

--[[doc--
This function, modeled after “check_language()” from fontspec, returns
true if in the given font, the language with tage “asked_language” is
accounted for in the script with tag “asked_script” in at least one
feature.
--doc]]--

--- int -> string -> string -> bool
function aux.provides_language(font_id, asked_script, asked_language)
  if not font_id        or type (font_id)        ~= "number"
  or not asked_script   or type (asked_script)   ~= "string"
  or not asked_language or type (asked_language) ~= "string"
  then
    logreport ("both", 0, "aux",
               "invalid parameters to provides_language(%s, %s, %s)",
               tostring (font_id),
               tostring (asked_script),
               tostring (asked_language))
    return false
  end
  asked_script   = stringlower(asked_script)
  local tfmdata = identifiers[font_id]
  if not tfmdata then
    logreport ("log", 0, "aux", "no font with id %d", font_id)
    return false
  end
  local hbface = get_hbface(tfmdata)
  if hbface then
    asked_language  = stringupper(asked_language)
    if asked_language == "DFLT" then
      return aux.provides_script(font_id, asked_script)
    end
    local script = harf.Tag.new(asked_script == "dflt" and "DFLT"
                                                        or asked_script)
    local language = harf.Tag.new(asked_language == "DFLT" and "dflt"
                                                            or asked_language)
    for _, tag in next, { GSUBtag, GPOStag } do
      local _, script_idx = hbface:ot_layout_find_script(tag, script)
      if hbface:ot_layout_find_language(tag, script_idx, language) then
        return true
      end
    end
    return false
  else
    asked_language  = stringlower(asked_language)
    local tfmdata = identifiers[font_id]
    if not tfmdata then return false end
    local features = get_features (tfmdata)
    if features == false then
      logreport ("log", 1, "aux", "font no %d lacks a features table", font_id)
      return false
    end
    for method, featuredata in next, features do
      --- where method: "gpos" | "gsub"
      for feature, data in next, featuredata do
        local scriptdata = data[asked_script]
        if scriptdata and scriptdata[asked_language] then
          logreport ("log", 1, "aux",
                     "font no %d (%s) defines feature %s "
                     .. "for script %s with language %s",
                     font_id, fontname, feature,
                     asked_script, asked_language)
          return true
        end
      end
    end
    logreport ("log", 0, "aux",
               "font no %d (%s) defines no feature "
               .. "for script %s with language %s",
               font_id, fontname, asked_script, asked_language)
    return false
  end
end

--[[doc--
A function to check if a font is a variabe font with a given axis.
--doc]]--

function aux.provides_axis(font_id, asked_axis)
  if not font_id      or type (font_id)      ~= "number"
  or not asked_axis or type (asked_axis) ~= "string"
  then
    logreport ("both", 0, "aux",
               "invalid parameters to provides_axis(%s, %s)",
               tostring (font_id), tostring (asked_axis))
    return false
  end
  local tfmdata = identifiers[font_id]
  if not tfmdata then
    logreport ("log", 0, "aux", "no font with id %d", font_id)
    return false
  end
  local hbface = get_hbface(tfmdata)
  if hbface then
    if not hbface:ot_var_has_data() then return false end

    if #asked_axis <= 4 then
      local tag = harf.Tag.new(asked_axis)
      local info = hbface:ot_var_find_axis_info(tag)
      if info then
        return true -- TODO: More info?
      end
    end

    asked_axis = stringlower(asked_axis)
    local infos = hbface:ot_var_get_axis_infos()
    for i=1, #infos do
      local info = infos[i]
      if hbface:get_name(info.name_id):lower() == asked_axis then
        return true -- TODO: More info?
      end
    end
  else
    asked_axis = stringlower(asked_axis)
    local resources = tfmdata.resources
    local variabledata = resources and resources.variabledata
    if not variabledata then return false end
    local axes = variabledata.axis
    if not axes then return false end -- Shouldn't happen
    for i=1, #axes do
      local axis = axes[i]
      if axis.tag == asked_axis or axis.name == asked_axis then
        return true -- TODO: More info?
      end
    end
  end
  return false
end

--[[doc--
We strip the syntax elements from feature definitions (shouldn’t
actually be there in the first place, but who cares ...)
--doc]]--

local lpeg        = require"lpeg"
local C, P, S     = lpeg.C, lpeg.P, lpeg.S
local lpegmatch   = lpeg.match

local sign            = S"+-"
local rhs             = P"=" * P(1)^0 * P(-1)
local strip_garbage   = sign^-1 * C((1 - rhs)^1)

--s   = "+foo"        --> foo
--ss  = "-bar"        --> bar
--sss = "baz"         --> baz
--t   = "foo=bar"     --> foo
--tt  = "+bar=baz"    --> bar
--ttt = "-baz=true"   --> baz
--
--print(lpeg.match(strip_garbage, s))
--print(lpeg.match(strip_garbage, ss))
--print(lpeg.match(strip_garbage, sss))
--print(lpeg.match(strip_garbage, t))
--print(lpeg.match(strip_garbage, tt))
--print(lpeg.match(strip_garbage, ttt))

--[[doc--
This function, modeled after “check_feature()” from fontspec, returns
true if in the given font, the language with tag “asked_language” is
accounted for in the script with tag “asked_script” in feature
“asked_feature”.
--doc]]--

--- int -> string -> string -> string -> bool
function aux.provides_feature(font_id,        asked_script,
                                   asked_language, asked_feature)
  if not font_id        or type (font_id)        ~= "number"
  or not asked_script   or type (asked_script)   ~= "string"
  or not asked_language or type (asked_language) ~= "string"
  or not asked_feature  or type (asked_feature)  ~= "string"
  then
    logreport ("both", 0, "aux",
               "invalid parameters to provides_feature(%s, %s, %s, %s)",
               tostring (font_id),        tostring (asked_script),
               tostring (asked_language), tostring (asked_feature))
    return false
  end
  asked_script    = stringlower(asked_script)
  asked_feature   = lpegmatch(strip_garbage, asked_feature)

  local tfmdata = identifiers[font_id]
  if not tfmdata then
    logreport ("log", 0, "aux", "no font with id %d", font_id)
    return false
  end
  local hbface = get_hbface(tfmdata)
  if hbface then
    asked_language  = stringupper(asked_language)
    local script = harf.Tag.new(asked_script == "dflt" and "DFLT"
                                                        or asked_script)
    local language = harf.Tag.new(asked_language == "DFLT" and "dflt"
                                                            or asked_language)
    local feature = harf.Tag.new(asked_feature)

    for _, tag in next, { GSUBtag, GPOStag } do
      local _, script_idx = hbface:ot_layout_find_script(tag, script)
      local _, language_idx = hbface:ot_layout_find_language(tag, script_idx, language)
      if hbface:ot_layout_find_feature(tag, script_idx, language_idx, feature) then
        return true
      end
    end
    return false
  else
    asked_language  = stringlower(asked_language)
    local features = get_features (tfmdata)
    if features == false then
      logreport ("log", 1, "aux", "font no %d lacks a features table", font_id)
      return false
    end
    for method, featuredata in next, features do
      --- where method: "gpos" | "gsub"
      local feature = featuredata[asked_feature]
      if feature then
        local scriptdata = feature[asked_script]
        if scriptdata and scriptdata[asked_language] then
          logreport ("log", 1, "aux",
                     "font no %d (%s) defines feature %s "
                     .. "for script %s with language %s",
                     font_id, fontname, asked_feature,
                     asked_script, asked_language)
          return true
        end
      end
    end
    logreport ("log", 0, "aux",
               "font no %d (%s) does not define feature %s for script %s with language %s",
               font_id, fontname, asked_feature, asked_script, asked_language)
  end
end

-----------------------------------------------------------------------
---                         font dimensions
-----------------------------------------------------------------------

--- int -> string -> int
local function get_math_dimension(font_id, dimenname)
  if type(font_id) == "string" then
    font_id = fontid(font_id) --- safeguard
  end
  local fontdata  = identifiers[font_id]
  local mathdata  = fontdata.mathparameters
  if mathdata then
    return mathdata[dimenname] or 0
  end
  return 0
end

aux.get_math_dimension = get_math_dimension

--- int -> string -> unit
function aux.sprint_math_dimension(font_id, dimenname)
  if type(font_id) == "string" then
    font_id = fontid(font_id)
  end
  local dim = get_math_dimension(font_id, dimenname)
  texsprint(luatexbase.catcodetables["latex-package"], dim, "sp")
end

-----------------------------------------------------------------------
---                    extra database functions
-----------------------------------------------------------------------

--[====[-- TODO -> port this to new db model

--- local directories -------------------------------------------------

--- migrated from luaotfload-database.lua
--- https://github.com/lualatex/luaotfload/pull/61#issuecomment-17776975

--- string -> (int * int)
local function scan_external_dir (dir)
  local old_names, new_names = names.data()
  if not old_names then
    old_names = load_names()
  end
  new_names = tablecopy(old_names)
  local n_scanned, n_new = scan_dir(dir, old_names, new_names)
  --- FIXME
  --- This doesn’t seem right. If a db update is triggered after this
  --- point, then the added fonts will be saved along with it --
  --- which is not as “temporarily” as it should be. (This should be
  --- addressed during a refactoring of names_resolve().)
  names.data = new_names
  return n_scanned, n_new
end

aux.scan_external_dir = scan_external_dir

--]====]--

function aux.scan_external_dir()
  print "ERROR: scan_external_dir() is not implemented"
end

--- db queries --------------------------------------------------------

--- https://github.com/lualatex/luaotfload/issues/74
--- string -> (string * int)
local function resolve_fontname(name)
  local foundname, subfont = luaotfload.resolvers.name {
    name          = name,
    specification = "name:" .. name,
  }
  if foundname then
    return foundname, subfont
  end
  return false, false
end

aux.resolve_fontname = resolve_fontname

--- string list -> (string * int)
function aux.resolve_fontlist(names)
  for n = 1, #names do
    local foundname, subfont = resolve_fontname(this)
    if foundname then
      return foundname, subfont
    end
  end
  return false, false
end

--- index access ------------------------------------------------------

--- Based on a discussion on the Luatex mailing list:
--- http://tug.org/pipermail/luatex/2014-June/004881.html

--[[doc--

  aux.read_font_index -- Read the names index from the canonical
  location and return its contents. This does not affect the behavior
  of Luaotfload: The returned table is independent of what the font
  resolvers use internally. Access is raw: each call to the function
  will result in the entire table being re-read from disk.

--doc]]--

local load_names        = fontnames.load
local access_font_index = fontnames.access_font_index

function aux.read_font_index()
  return load_names (true) or { }
end

--[[doc--

  aux.font_index -- Access Luaotfload’s internal database. If the
  database hasn’t been loaded yet this will cause it to be loaded, with
  all the possible side-effects like for instance creating the index
  file if it doesn’t exist, reading all font files, &c.

--doc]]--

function aux.font_index() return access_font_index () end


--- loaded fonts ------------------------------------------------------

--- just a proof of concept

--- fontobj -> string list -> (string list) list
local function get_font_data (tfmdata, keys)
  local acc = {}
  for n = 1, #keys do
    acc[n] = tfmdata[keys[n]] or false
  end
  return acc
end

--[[doc--

    The next one operates on the fonts.hashes.identifiers table.
    It returns a list containing tuples of font ids and the
    contents of the fields specified in the first argument.
    Font table entries that were created indirectly -- e.g. by
    \letterspacefont or during font expansion -- will not be
    listed.

--doc]]--

local default_keys = { "fullname" }

--- string list -> (int * string list) list
function aux.get_loaded_fonts (keys)
  keys = keys or default_keys
  local acc = {}
  for id, tfmdata in pairs(identifiers) do
    local data = get_font_data(tfmdata, keys)
    acc[#acc+1] = { id, data }
  end
  return acc
end

--- Raw access to the font.* namespace is unsafe so no documentation on
--- this one.
function aux.get_raw_fonts ()
  local res = { }
  for i, v in font.each() do
    if v.filename then
      res[#res+1] = { i, v }
    end
  end
  return res
end

-----------------------------------------------------------------------
---                         font parameters
-----------------------------------------------------------------------
--- analogy of font-hsh

fonthashes.parameters    = fonthashes.parameters or { }
fonthashes.quads         = fonthashes.quads or { }

local parameters         = fonthashes.parameters or { }
local quads              = fonthashes.quads or { }

setmetatable(parameters, { __index = function (t, font_id)
  local tfmdata = identifiers[font_id]
  if not tfmdata then --- unsafe; avoid
    tfmdata = font.fonts[font_id]
  end
  if tfmdata and type(tfmdata) == "table" then
    local fontparameters = tfmdata.parameters
    t[font_id] = fontparameters
    return fontparameters
  end
  return nil
end})

--[[doc--

  Note that the reason as to why we prefer functions over table indices
  is that functions are much safer against unintended manipulation.
  This justifies the overhead they cost.

--doc]]--

--- int -> (number | false)
function aux.get_quad(font_id)
  local quad = quads[font_id]
  if quad then
    return quad
  end
  local fontparameters = parameters[font_id]
  if fontparameters then
    local quad     = fontparameters.quad or 0
    quads[font_id] = quad
    return quad
  end
  return false
end

-----------------------------------------------------------------------
---                         Script/language fixup
-----------------------------------------------------------------------
local otftables = fonts.constructors.handlers.otf.tables
local function setscript(tfmdata, value)
  if value then
    local cleanvalue = string.lower(value)
    local scripts  = otftables and otftables.scripts
    local properties = tfmdata.properties
    if not scripts then
      properties.script = cleanvalue
    elseif scripts[value] then
      properties.script = cleanvalue
    else
      properties.script = "dflt"
    end
  end
  local resources = tfmdata.resources
  local features = resources and resources.features
  if features then
    local properties = tfmdata.properties
    local script, language = properties.script, properties.language
    local script_found, language_found = false, false
    for _, data in next, features do for _, feature_data in next, data do
      local scr = feature_data[script]
      if scr then
        script_found = true
        if scr[language] then
          language_found = true
          goto double_break
        end
      end
    end end
    ::double_break::
    if not script_found then properties.script = "dflt" end
    if not language_found then properties.language = "dflt" end
  end
end
fonts.constructors.features.otf.register {
  name         = "script",
  initializers = {
    base = setscript,
    node = setscript,
    plug = setscript,
  },
}

-----------------------------------------------------------------------
---                         initialization
-----------------------------------------------------------------------

local function inject_callbacks (lst)
  if not lst and next (lst) then return false end

  local function inject (def)
    local cb, fn, id = unpack (def)
    cb = tostring (cb)
    id = tostring (id)
    if not cb or not fn or not id or not type (fn) == "function" then
      logreport ("both", 0, "aux", "Invalid callback requested (%q, %s, %q).",
                 cb, tostring (fn), id)
      return false
    end
    cb = stringformat ("luaotfload.%s",     cb)
    id = stringformat ("luaotfload.aux.%s", id)
    logreport ("log", 5, "aux", "Installing callback %q->%q.", cb, id)
    luatexbase.add_to_callback (cb, fn, id)
    return true
  end

  local ret = true
  for i = 1, #lst do ret = inject (lst [i]) end
  return ret
end

return function ()
  luaotfload.aux = aux
  return inject_callbacks (luaotfload_callbacks)
end

-- vim:tw=79:sw=2:ts=8:et

