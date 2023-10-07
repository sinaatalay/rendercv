-----------------------------------------------------------------------
--         FILE:  luaotfload-notdef.lua
--  DESCRIPTION:  part of luaotfload / notdef
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-notdef",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / notdef",
    license       = "GPL v2.0",
    author        = "Marcel Krüger"
}

local harfbuzz           = luaotfload.harfbuzz
local flush_node         = node.direct.flush_node
local getfont            = font.getfont
local getnext            = node.direct.getnext
local getwhd             = node.direct.getwhd
local insert             = table.insert
local insert_after       = node.direct.insert_after
local kern_id            = node.id'kern'
local disc_id            = node.id'disc'
local nodenew            = node.direct.new
local nodecopy           = node.direct.copy
local otfregister        = fonts.constructors.features.otf.register
local protect_glyph      = node.direct.protect_glyph
local remove             = node.direct.remove
local setfont            = node.direct.setfont
local traverse_char      = node.direct.traverse_char
local traverse_id        = node.direct.traverse_id
local setchar            = node.direct.setchar
local setdisc            = node.direct.setdisc
local getdisc            = node.direct.getdisc
local getwidth           = node.direct.getwidth
local setkern            = node.direct.setkern
local setattributelist   = node.direct.setattributelist
local getattributelist   = node.direct.getattributelist
local setmove            = luaotfload.fontloader.nodes.injections.setmove

-- According to DerivedCoreProperties.txt, Default_Ignorable_Code_Point
-- is generated from:
--    Other_Default_Ignorable_Code_Point
--  + Cf (Format characters)
--  + Variation_Selector
--  - White_Space
--  - FFF9..FFFB (Interlinear annotation format characters)
--  - 13430..13438 (Egyptian hieroglyph format characters)
--  - Prepended_Concatenation_Mark (Exceptional format characters that should be visible)
-- Based on HarfBuzz, we add the exclusion
--  - Lo (Letter, Other)
-- This affects Hangul fillers.
local ignorable_codepoints do
  local sep = lpeg.P' '^0 * ';' * lpeg.P' '^0
  local codepoint = lpeg.S'0123456789ABCDEF'^4/function(c)return tonumber(c, 16)end
  local codepoint_range = codepoint * ('..' * codepoint + lpeg.Cc(false))
  local function multirawset(table, key1, key2, value)
    for key = key1,(key2 or key1) do
      rawset(table, key, value)
    end
    return table
  end
  local entry = lpeg.Cg(codepoint * ';' * (1-lpeg.P';')^0 * ';Cf;' * lpeg.Cc(true))^-1 * (1-lpeg.P'\n')^0 * '\n'
  local file = lpeg.Cf(
      lpeg.Ct''
    * entry^0
  , rawset)
  local f = io.open(kpse.find_file"UnicodeData.txt")
  ignorable_codepoints = file:match(f:read'*a')
  f:close()
  entry = lpeg.Cg(codepoint_range * sep * ('Other_Default_Ignorable_Code_Point' * lpeg.Cc(true)
                                               + 'Variation_Selector' * lpeg.Cc(true)
                                               + 'White_Space' * lpeg.Cc(nil)
                                               + 'Prepended_Concatenation_Mark' * lpeg.Cc(nil)
                                          ) * ' # ' * (1-lpeg.P'Lo'))^-1 * (1-lpeg.P'\n')^0 * '\n'
  file = lpeg.Cf(
      lpeg.Carg(1)
    * entry^0
  , multirawset)
  f = io.open(kpse.find_file"PropList.txt")
  ignorable_codepoints = file:match(f:read'*a', 1, ignorable_codepoints)
  f:close()
  for i = 0xFFF9,0xFFFB do
    ignorable_codepoints[i] = nil
  end
  for i = 0x13430,0x13438 do
    ignorable_codepoints[i] = nil
  end
end

ignorable_codepoints[0xAD] = nil

local function setnotdef(tfmdata, factor)
  local desc = tfmdata.shared.rawdata.descriptions
  -- So we have to find the .notdef glyph. We only know that it has GID
  -- 0, but we need it's Unicode mapping. Normally it isn't mapped in
  -- the font, so we auto-assigned the first private slot:
  local guess = desc[0xF0000]
  if guess and guess.index == 0 then
    tfmdata.notdefcode = 0xF0000
    return
  end
  -- If this didn't happen, it might be mapped to one of the
  -- replacement characters:
  for code = 0xFFFC,0xFFFF do
    guess = desc[code]
    if guess and guess.index == 0 then
      tfmdata.notdefcode = code
      return
    end
  end
  -- Oh no, we couldn't find it. Maybe we can find it by name?
  local code = tfmdata.resources.unicodes[".notdef"]
  -- Better safe than sorry
  guess = code and desc[code]
  if guess and guess.index == 0 then
    tfmdata.notdefcode = code
    return
  end
  -- So the font didn't do the obvious things and then it lied to us.
  -- At this point we should think about sending an automated complain
  -- to the font author, but we probably can't trust the contact
  -- information either.
  -- We will fall back to brute force now:
  for code, char in pairs(desc) do
    if char.index == 0 then
      tfmdata.notdefcode = code
      return
    end
  end
  -- If we ever reach this point, something odd happened. Either there
  -- are no glyphs at all (then LuaTeX will complain anyway, so let's
  -- ignore that case) or someone tried to use this with a legacy font.
  -- In that case there most likely isn't a `.notdef` glyph anyway and
  -- inserting glyph 0 would insert a random character, so `notdefcode`
  -- better stays `nil`.
end

local glyph_id = node.id'glyph'
local function donotdef(head, font, _, _, _)
  local tfmdata = getfont(font)
  local notdef, chars = tfmdata.unscaled.notdefcode, tfmdata.characters
  if not notdef then return end
  for cur, cid, fid in traverse_char(head) do if fid == font then
    local w, h, d = getwhd(cur)
    if w == 0 and h == 0 and d == 0 and not chars[cid] and not ignorable_codepoints[cid] then
      local notdefnode = nodenew(glyph_id, 256)
      setfont(notdefnode, font, notdef)
      insert_after(cur, cur, notdefnode)
      protect_glyph(cur)
    end
  end end
end

otfregister {
  name        = "notdef",
  description = "Add notdef glyphs",
  default     = 1,
  initializers = {
    node = setnotdef,
  },
  processors = {
    node = donotdef,
  }
}

local font_invisible_replacement = setmetatable({}, {__index = function(t, fid)
  local fontdata = font.getfont(fid)
  local replacement = fontdata.shared.features.invisible
  if replacement == "remove" then
    t[fid] = false
    return false
  end
  replacement = tonumber(replacement) or 32
  local char = fontdata.characters[replacement]
  if char then
    t[fid] = {replacement, -char.width}
    return t[fid]
  else
    t[fid] = false
    return false
  end
end})

local push, pop do
  local function checkprop(n)
    local p = node.direct.getproperty(n)
    return p and p.zwnj
  end
  local list = {}
  function push(head)
    head = node.direct.todirect(head)
    local l = {}
    list[#list+1] = l
    for n, id in node.direct.traverse(head) do
      if checkprop(n) then
        head = node.direct.remove(head, n)
        l[#l+1] = n
      elseif id == disc_id then
        local pre, post, replace = getdisc(n)
        for nn in node.direct.traverse(pre) do
          if checkprop(nn) then
            local after
            pre, after = node.direct.remove(pre, nn)
            l[#l+1] = {nn, n, 'pre'}
          end
        end
        for nn in node.direct.traverse(post) do
          if checkprop(nn) then
            post = node.direct.remove(post, nn)
            l[#l+1] = {nn, n, 'post'}
          end
        end
        for nn in node.direct.traverse(replace) do
          if checkprop(nn) then
            replace = node.direct.remove(replace, nn)
            l[#l+1] = {nn, n, 'replace'}
          end
        end
        setdisc(n, pre, post, replace)
      end
    end
    return head
  end
  local getfield, setfield = node.direct.getfield, node.direct.setfield
  local function pop(head)
    head = node.direct.todirect(head)
    local l = list[#list]
    list[#list] = nil
    for i = #l,1,-1 do
      local e = l[i]
      local n = tonumber(e)
      local disc, thishead
      if n then
        thishead = head
      else
        disc, n = e[2], e[1]
        thishead = getfield(disc, e[3])
      end
      local prev, next = node.direct.getboth(n)
      if prev or not next then
        thishead = node.direct.insert_after(thishead, prev, n)
      else
        thishead = node.direct.insert_before(thishead, next, n)
      end
      if disc then
        setfield(disc, e[3], thishead)
      else
        head = thishead
      end
    end
    return head
  end
  fonts.handlers.otf.handlers.marked_push = push
  fonts.handlers.otf.handlers.marked_pop = pop
end
local sequence1 = {
  features = {["semiignored-node"] = {["*"] = {["*"] = true}}},
  flags = {false, false, false, false},
  name = "semiignored-node",
  order = {"semiignored-node"},
  type = "marked_push",
}
local sequence2 = {
  features = {["semiignored-node"] = {["*"] = {["*"] = true}}},
  flags = {false, false, false, false},
  name = "semiignored-node",
  order = {"semiignored-node"},
  type = "marked_pop",
}
local function pushpopinitialiser(tfmdata, value, features)
  local resources = tfmdata.resources
  local sequences = resources and resources.sequences
  local first_gpos, last_gpos
  if sequences then
    local alreadydone
    for i=1,#sequences do
      local sequence = sequences[i]
      if sequence1 == sequence then
        return
      elseif sequence.type:sub(1,5) == "gpos_" then
        if not first_gpos then
          first_gpos = i
        end
        last_gpos = i
      end
    end
    if first_gpos then
      insert(sequences, last_gpos+1, sequence2)
      insert(sequences, first_gpos, sequence1)
    end
  end
end

otfregister {
  name = 'semiignored-node',
  description = 'Allow adding nodes which break ligatures but do not affect kerning',
  default = true, -- Should basically never be disabled manually
  initializers = {
    node = pushpopinitialiser,
    -- plug = ? -- TODO: Manually handle in luaotfload-harf-plug.lua
  },
}

local delayed_remove do
  local delayed
  function delayed_remove(n)
    flush_node(delayed)
    delayed = n
  end
end

local function ignorablehandler(head, fid, ...) -- FIXME: The arguments are probably wrong
  local fontparam = font_invisible_replacement[fid]
  local replacement = fontparam and fontparam[1]
  local font_kern = fontparam and fontparam[2]
  for n, c, f in traverse_char(head) do if f == fid then
    local lookup = ignorable_codepoints[c]
    if lookup then
      if replacement then
        setchar(n, replacement)
        if font_kern then
          local k = nodenew(kern_id)
          setkern(k, font_kern)
          setattributelist(k, getattributelist(n))
          head = insert_after(head, n, k)
        end
      else
        local after
        head, after = remove(head, n)
        delayed_remove(n)
      end
    end
  end end
  delayed_remove()
  for n in traverse_id(disc_id, head) do
    local a, b, c = getdisc(n)
    setdisc(ignorablehandler(a, fid), ignorablehandler(b, fid), ignorablehandler(c, fid))
  end
  return head
end

if harfbuzz then
  local harf_settings = luaotfload.harf
  local preserve_flag = harfbuzz.Buffer.FLAG_PRESERVE_DEFAULT_IGNORABLES or 0
  local remove_flag = harfbuzz.Buffer.FLAG_REMOVE_DEFAULT_IGNORABLES or 0
  local dotted_circle_flag = harfbuzz.Buffer.FLAG_DO_NOT_INSERT_DOTTED_CIRCLE or 0
  harf_settings.default_buf_flags = (harf_settings.default_buf_flags & ~remove_flag) | preserve_flag | dotted_circle_flag
  local function dottedcircleinitialize(tfmdata, value)
    if not tfmdata.hb then return end
    local hb = tfmdata.hb
    hb.buf_flags = hb.buf_flags & ~dotted_circle_flag
  end
  otfregister {
    name = 'dottedcircle',
    description = 'Insert dotted circle to fix invalid clusters',
    default = true,
    initializers = {
      plug = dottedcircleinitialize,
    },
  }
end
otfregister {
  name = 'invisible',
  description = 'Remove invisible control characters',
  default = true,
  processors = {
    node = ignorablehandler,
    plug = ignorablehandler,
  },
}

--- vim:sw=2:ts=2:expandtab:tw=71
