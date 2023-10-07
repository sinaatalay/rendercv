-------------------------------------------------------------------------------
--         FILE:  luaotfload-dvi.lua
--  DESCRIPTION:  part of luaotfload / DVI
-------------------------------------------------------------------------------


assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-dvi",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / DVI",
    license       = "GPL v2.0",
    author        = "Marcel Krüger",
    copyright     = "Luaotfload Development Team",  
}

local getfont = font.getfont
local setfont = node.direct.setfont
local getdisc = node.direct.getdisc
local getlist = node.direct.getlist
local is_glyph = node.direct.is_glyph
local todirect = node.direct.todirect
local traverse_glyph = node.direct.traverse_glyph
local traverse_list = node.direct.traverse_list
local traverse_id = node.direct.traverse_id
local traverse = node.direct.traverse
local uses_font = node.direct.uses_font
local define_font = font.define
local hlist_t = node.id'hlist'
local vlist_t = node.id'vlist'
local disc_t = node.id'disc'
local glyph_t = node.id'glyph'

require'luaotfload-configuration'
local configuration = config.luaotfload

-- DVI output support
--
-- When writing DVI files, we can't assume that the DVI reader has access to our
-- font dictionaries, so we need an independent representation for our glyphs. The
-- approach we chose in coordination with the dvisvgm author is to create a DVI font
-- name which indicates the font filename and some essential backend parameters
-- (especially otential extend, shrink, embolden, etc. factors) and then use GIDs in
-- the page stream.
--
-- Normally we could easily implement this using virtual fonts, but because we are
-- dealing with DVI output, LuaTeX is not evaluating virtual fonts by itself.
-- So instead, we process the shaped output and replace all glyph nodes with glyph
-- nodes from special fonts which have the characteristics expected brom the DVI reader.

-- mapped_fonts maps fontids from the user to fontids used in the DVI file
local mapped_fonts = setmetatable({}, {__index = function(t, fid)
  local font = getfont(fid)
  local mapped = font and font.backend_font or false
  t[fid] = mapped
  return mapped
end})

local full_hprocess
local function full_vprocess(head)
  for _, id, _, list in traverse_list(head) do
    if id == hlist_t then
      full_hprocess(list)
    elseif id == vlist_t then
      full_vprocess(list)
    else
      assert(false)
    end
  end
end

function full_hprocess(head)
  local last_f, last_mapping, last_mapped_font
  for n, id in traverse(head) do
    if id == hlist_t then
      full_hprocess(getlist(n))
    elseif id == vlist_t then
      full_vprocess(getlist(n))
    elseif id == disc_t then
      local _, _, rep = getdisc(n)
      for n, c, f in traverse_glyph(rep) do
        if f ~= last_f then
          last_f, last_mapping = f, mapped_fonts[f]
          last_mapped_font = last_mapping and last_mapping.font
        end
        if last_mapping then
          local mapped = last_mapping[c]
          if mapped then setfont(n, mapped_font, mapped) end
        end
      end
    elseif id == glyph_t then
      local c, f = is_glyph(n)
      if f ~= last_f then
        last_f, last_mapping = f, mapped_fonts[f]
        last_mapped_font = last_mapping and last_mapping.font
      end
      if last_mapping then
        local mapped = last_mapping[c]
        if mapped then setfont(n, last_mapped_font, mapped) end
      end
    end
  end
end

local function delayed_register_callback()
  luatexbase.add_to_callback('pre_shipout_filter', function(list)
    full_vprocess(todirect(list)) -- list should always be a single list node, so we can treat it as if it were a vlist with one node
    return true
  end, 'luaotfload.dvi')
  delayed_register_callback = function() end
end

local function process(head, font)
  local mapping = mapped_fonts[font]
  if not mapping then return head end
  local mapped_font = mapping.font
  for n, c, f in traverse_glyph(head) do if f == font then
    local mapped = mapping[c]
    if mapped then setfont(n, mapped_font, mapped) end
  end end
  for n in traverse_id(disc_t, head) do if uses_font(n, font) then
    local pre, post, rep = getdisc(n)
    for n, c, f in traverse_glyph(pre) do if f == font then
      local mapped = mapping[c]
      if mapped then setfont(n, mapped_font, mapped) end
    end end
    for n, c, f in traverse_glyph(post) do if f == font then
      local mapped = mapping[c]
      if mapped then setfont(n, mapped_font, mapped) end
    end end
    for n, c, f in traverse_glyph(rep) do if f == font then
      local mapped = mapping[c]
      if mapped then setfont(n, mapped_font, mapped) end
    end end
  end end
end
local function manipulate(tfmdata, _, dvi_kind)
  if dvi_kind == 'xdvipsk' then
    -- xdvipsk wants to read tea leaves instead of using reasonable interfaces.
    -- They will have to make sense of whatever output this produces.
    return
  elseif dvi_kind ~= 'dvisvgm' then
    texio.write_nl(string.format('WARNING (luaotfload): Unsupported DVI backend %q, falling back to dvisvgm.', dvi_kind))
  end
  -- Legacy fonts can be written to the DVI file directly
  if 2 ~= (tfmdata.encodingbytes or ((tfmdata.format == 'truetype' or tfmdata.format == 'opentype') and 2 or 1)) then
    return
  end
  delayed_register_callback()
  local newfont = {}
  for k,v in pairs(tfmdata) do
    newfont[k] = v
  end
  local newchars = {}
  newfont.characters = newchars
  local lookup = {}
  for k,v in pairs(tfmdata.characters) do
    local newchar = {
      width = v.width, -- Only width should really be necessary
      height = v.height,
      depth = v.depth,
    }
    newchars[v.index or k] = newchar
    lookup[k] = v.index or k
  end
  newfont.checksum = string.unpack('>I4', 'LuaF') -- Use a magic checksum such that the reader
                                                  -- can uniquely identify these fonts.
  local name = '[' .. newfont.name .. ']:' -- TODO: Why .name? I would have expected .filename
  if newfont.subfont and newfont.subfont ~= 1 then
    name = name .. 'index=' .. tostring(math.tointeger(newfont.subfont-1)) .. ';'
  end
  if newfont.extend and newfont.extend ~= 1000 then
    name = name .. 'extend=' .. tostring(math.tointeger(math.round(newfont.extend*65.536))) .. ';'
  end
  if newfont.slant and newfont.slant ~= 0 then
    name = name .. 'slant=' .. tostring(math.tointeger(math.round(newfont.slant*65.536))) .. ';'
  end
  if newfont.mode == 2 and newfont.width and newfont.width ~= 0 then
    name = name .. 'embolden=' .. tostring(math.tointeger(math.round(newfont.width*65.78176))) .. ';'
  end
  newfont.name = name:sub(1,-2) -- Stri th trailing : or ;
  tfmdata.backend_font = lookup
  lookup.font = define_font(newfont)
end

fonts.constructors.features.otf.register {
  name = "dvifont",
  default = configuration.run.default_dvi_driver,
  manipulators = {
    node = manipulate,
    base = manipulate,
  },
  -- Processors are not needed since we are using pre_shipout_filter
  -- processors = {
  --   node = process,
  --   base = process,
  -- },
}
