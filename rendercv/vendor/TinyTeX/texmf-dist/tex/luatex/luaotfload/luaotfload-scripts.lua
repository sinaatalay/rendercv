-----------------------------------------------------------------------
--         FILE:  luaotfload-script.lua
--  DESCRIPTION:  part of luaotfload / script
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-script",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / Script helpers",
    license       = "CC0 1.0 Universal",
    author        = "Marcel Krüger"
}

local canonical_name = {
  dflt = "DFLT",
  hira = "kana",
  laoo = "lao",
  yiii = "yi",
  nkoo = "nko",
  yaii = "vai",
  ["lao "] = "lao",
  ["yi  "] = "yi",
  ["nko "] = "nko",
  ["vai "] = "vai",
}
local versioned_script = {
  mym = "mymr", mymr = "mym",
  bng = "beng", beng = "bng",
  dev = "deva", deva = "dev",
  gjr = "gujr", gujr = "gjr",
  gur = "guru", guru = "gur",
  knd = "knda", knda = "knd",
  mlm = "mlym", mlym = "mlm",
  ory = "orya", orya = "ory",
  tml = "taml", taml = "tml",
  tel = "telu", telu = "tel",
}
local function get_versioned(original)
  local base = original:gsub("%d$", "") -- Strip any existing version
  local versioned = versioned_script[base]
  if not versioned then
    return original
  end
  if #base == 3 then
    local t = base
    base = versioned
    versioned = t
  end
  if base == "mymr" then
    return "mym2", "mymr"
  end
  return versioned .. '3', versioned .. '2', base
end

-- We never return trailing spaces because I consider them implementation details.
local function script_to_ot(iso)
  iso = iso:lower()
  return get_versioned(canonical_name[iso] or iso)
end

local function script_to_iso(tag)
  tag = tag:lower()
  tag = canonical_name[tag] or tag
  local stripped, did_strip = tag:gsub("%d$", "")
  tag = did_strip == 1 and versioned_script[stripped] or tag
  local tag_length = #tag
  if tag_length == 4 then return tag end -- Optimization for common case
  -- I promise you, I am not making this one up
  return tag .. string.rep(tag:sub(tag_length, tag_length), 4-tag_length)
end

local function to_harfbuzz(script, language)
  local otscript = script_to_iso(script)
  -- if script_to_ot(otscript) == script then
  --   return otscript, language
  -- end
  return otscript, "x-hbot" .. language .. "-hbsc" .. script
end

return {
  to_harfbuzz = to_harfbuzz,
  script = {
    to_ot = script_to_ot,
    to_iso = script_to_iso,
  },
}
