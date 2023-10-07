local unicode_data = require'luaotfload-unicode'
local bcp47 = require'luaotfload-bcp47'

local mapping_tables = unicode_data.casemapping
local soft_dotted = unicode_data.soft_dotted
local ccc = unicode_data.ccc

local uppercase = mapping_tables.uppercase
local lowercase = mapping_tables.lowercase
local cased = mapping_tables.cased
local case_ignorable = mapping_tables.case_ignorable

local otfregister  = fonts.constructors.features.otf.register

local direct = node.direct
local is_char = direct.is_char
local has_glyph = direct.has_glyph
local uses_font = direct.uses_font
local getnext = direct.getnext
local setchar = direct.setchar
local setdisc = direct.setdisc
local getdisc = direct.getdisc
local getfield = direct.getfield
local remove = direct.remove
local free = direct.free
local copy = direct.copy
local insert_after = direct.insert_after
local traverse = direct.traverse

local report = luaotfload.log.report

local disc = node.id'disc'

--[[ We make some implicit assumptions about contexts in SpecialCasing.txt here which happened to be true when I wrote the code:
--
-- * Before_Dot only appears as Not_Before_Dot
-- * No other context appears with Not_
-- * Final_Sigma is never language dependent
-- * Other contexts are always language dependent
-- * The only languages with special mappings are Lithuanian (lt/"LTH "/lit), Turkish (tr/"TRK "/tur), and Azeri/Azerbaijani (az/"AZE "/aze)
--   (Additionally we add special mappings for de-x-eszett, el, el-x-iota, hy-x-yiwn which are not present in SpecialCasing.txt)
]]

local UPPER_MASK = 0x3FF
local HAS_VOWEL = 0x200000
local HAS_YPOGEGRAMMENI = 0x400000
local HAS_ACCENT = 0x800000
local HAS_DIALYTIKA = 0x1000000
local HAS_OTHER_GREEK_DIACRITIC = 0x2000000

local greek_data
local greek_diacritic = {
  [0x0300] = HAS_ACCENT,
  [0x0301] = HAS_ACCENT,
  [0x0342] = HAS_ACCENT,
  [0x0302] = HAS_ACCENT,
  [0x0303] = HAS_ACCENT,
  [0x0311] = HAS_ACCENT,
  [0x0308] = HAS_DIALYTIKA,
  [0x0344] = HAS_DIALYTIKA | HAS_ACCENT,
  [0x0345] = HAS_YPOGEGRAMMENI,
  [0x0304] = HAS_OTHER_GREEK_DIACRITIC,
  [0x0306] = HAS_OTHER_GREEK_DIACRITIC,
  [0x0313] = HAS_OTHER_GREEK_DIACRITIC,
  [0x0314] = HAS_OTHER_GREEK_DIACRITIC,
  [0x0343] = HAS_OTHER_GREEK_DIACRITIC,
}

local greek_precombined_iota = {
  [0x0391] = 0x1FBC,
  [0x0397] = 0x1FCC,
  [0x03A9] = 0x1FFC,
}

-- Greek handling based on https://icu.unicode.org/design/case/greek-upper
-- with smaller variations since we ant to preserve nodes whenever possible.
local function init_greek_data()
  local NFD = require'lua-uni-normalize'.NFD
  local data = {}
  greek_data = data

  local vowels = {
    [utf8.codepoint'Α'] = true, [utf8.codepoint'Ε'] = true,
    [utf8.codepoint'Η'] = true, [utf8.codepoint'Ι'] = true,
    [utf8.codepoint'Ο'] = true, [utf8.codepoint'Ω'] = true,
    [utf8.codepoint'Υ'] = true,
  }
  local function handle_char(c)
    local decomp = NFD(utf8.char(c))
    local first = utf8.codepoint(decomp)
    local upper = uppercase[first]
    if upper then
      if not tonumber(upper) then
        upper = upper._
        assert(#upper == 1)
        upper = upper[1]
      end
    else
      upper = first
    end
    if upper > UPPER_MASK then return end -- Only happens for unassigned codepoints
    local datum = upper
    if vowels[upper] then
      datum = datum | HAS_VOWEL
    end
    if utf8.len(decomp) > 1 then
      for _, c in utf8.codes(decomp) do
        local dia = greek_diacritic[c]
        if dia and dia ~= HAS_OTHER_GREEK_DIACRITIC then datum = datum | dia end
      end
    end
    data[c] = datum
  end
  for c = 0x0370, 0x03ff do handle_char(c) end
  for c = 0x1f00, 0x1fff do handle_char(c) end
  for c = 0x2126, 0x2126 do handle_char(c) end
end

local relevant_languages = {
  lt = true,
  tr = true,
  az = true,
  hy = {_ = true, yiwn = true},
  el = {_ = true, iota = true},
  de = {_ = false, eszett = true},
}

local function font_lang(feature)
  return setmetatable({}, {__index = function(t, fid)
    local f = font.getfont(fid)
    local features = f.specification.features.normal
    local lang = features[feature]
    if type(lang) ~= 'string' or lang == 'auto' then
      lang = features.language
      lang = lang == 'lth' and 'lt'
          or lang == 'trk' and 'tr'
          or lang == 'aze' and 'az'
          or lang == 'hye' and 'hy'
          or (lang == 'ell' or lang == 'pgr') and 'el'
          or false
    end
    if lang == 'de-alt' then
      lang = 'de-x-eszett'
    end
    local parsed = lang and bcp47.parse(lang)
    if lang and not parsed then
      report('luaotfload-case', 0, 'Unable to parse passed language tag')
    end
    lang = parsed and parsed.language
    local subtags = lang and relevant_languages[lang]
    if subtags then
      local private = parsed.private
      if subtags ~= true and private then
        local first = true
        for _, ext in ipairs(private) do
          if subtags[ext] then
            if first then
              lang = lang .. '-x'
              first = nil
            end
            lang = lang .. '-' .. ext
          end
        end
        if first then
          lang = subtags._ and lang
        end
      end
    else
      lang = false
    end
    t[fid] = lang
    return lang
  end})
end

local function is_followed_by_cased(font, n, after)
  n = getnext(n)
  repeat
    while n do
      local char, id = is_char(n, font)
      if not char and id == disc then
        after = getnext(n)
        n = getfield(n, 'replace')
        char, id = is_char(n, font)
      end
      if char then
        if not case_ignorable[char] then
          return cased[char]
        end
        n = getnext(n)
      else
        return false
      end
    end
    n, after = after
  until not n
  return false
end

local function is_Final_Sigma(font, mapping, n, after)
  mapping = mapping.Final_Sigma
  if not mapping then return false end
  mapping = mapping._
  if not mapping then return false end
  return not is_followed_by_cased(font, n, after) and mapping
end

local function is_More_Above(font, mapping, n, after)
  mapping = mapping.More_Above
  if not mapping then return false end
  mapping = mapping._
  if not mapping then return false end
  n = getnext(n)
  repeat
    while n do
      local char, id = is_char(n, font)
      if id == disc then
        after = getnext(n)
        n = getfield(n, 'replace')
        char, id = is_char(n, font)
      elseif char then
        local char_ccc = ccc[char]
        if not char_ccc then
          return false
        elseif char_ccc == 230 then
          return mapping
        end
        n = getnext(n)
      else
        return false
      end
    end
    n, after = after
  until not n
  return false
end

local function is_Not_Before_Dot(font, mapping, n, after)
  mapping = mapping.Not_Before_Dot
  if not mapping then return false end
  mapping = mapping._
  if not mapping then return false end
  n = getnext(n)
  repeat
    while n do
      local char, id = is_char(n, font)
      if id == disc then
        after = getnext(n)
        n = getfield(n, 'replace')
        char, id = is_char(n, font)
      elseif char then
        local char_ccc = ccc[char]
        if not char_ccc then
          return mapping
        elseif char_ccc == 230 then
          return char ~= 0x0307 and mapping
        end
        n = getnext(n)
      else
        return mapping
      end
    end
    n, after = after
  until not n
  return mapping
end

local function is_Language_Mapping(font, mapping, n, after, seen_soft_dotted, seen_I)
  if not mapping then return false end
  if seen_soft_dotted then
    local mapping = mapping.After_Soft_Dotted
    mapping = mapping and mapping._
    if mapping then
      return mapping
    end
  end
  if seen_I then
    local mapping = mapping.After_I
    mapping = mapping and mapping._
    if mapping then
      return mapping
    end
  end
  return is_More_Above(font, mapping, n, after) or is_Not_Before_Dot(font, mapping, n, after) or mapping._ -- Might be nil
end

local function process(table, feature)
  local font_lang = font_lang(feature)
  -- The other seen_... are booleans, while seen_greek has more states:
  --   - nil: Not greek
  --   - true: Greek. Last was not a vowel with accent and without dialytika
  --   - node: Greek. Last vowel with accent and without dialytika
  local function processor(head, font, after, seen_cased, seen_soft_dotted, seen_I, seen_greek)
    local lang = font_lang[font]
    local greek, greek_iota
    if lang == 'el' or lang == 'el-x-iota' then
      if table == uppercase then
        if not greek_data then
          init_greek_data()
        end
        greek, greek_iota = greek_data, lang == 'el-x-iota'
      end
      lang = false
    end
    local n = head
    while n do
      do
        local new = has_glyph(n)
        if n ~= new then
          seen_cased, seen_soft_dotted, seen_I, seen_greek = nil
        end
        n = new
      end
      if not n then break end
      local char, id = is_char(n, font)
      if char then
        if greek and (char >= 0x0370 and char <= 0x03ff or char >= 0x1f00 and char <= 0x1fff or char == 0x2126) then
          -- In the greek uppercase situation we want to remove diacritics except under some exceptions.
          local first_datum = greek[char] or 0
          local datum = first_datum
          local upper = datum & UPPER_MASK
          -- When a vowel ges an accent removed and does not have a dialytika and is followed by a Ι or Υ,
          -- then this iota or ypsilon gets a dialytika.
          if datum & HAS_VOWEL ~= 0 and seen_greek and seen_greek ~= true and (upper == 0x0399 or upper == 0x03a5) then
            datum = datum | HAS_DIALYTIKA;
          end
          local has_ypogegrammeni = datum & HAS_YPOGEGRAMMENI ~= 0
          local add_ypogegrammeni = has_ypogegrammeni
          local post = getnext(n)
          local last
          local saved_tonos, saved_dialytika
          while post do
            local char = is_char(post, font)
            if not char then break end
            local diacritic_data = greek_diacritic[char]
            if not diacritic_data then break end
            -- Preserve flags to be aware if a dialytika has to be reinserted
            -- TODO: Keep dialytika node around
            datum = datum | diacritic_data
            -- Preserve ypogegrammeni (iota subscript) but convert them into capital iotas.
            -- If el-x-iota is active keep the combining character instead.
            if diacritic_data & HAS_YPOGEGRAMMENI ~= 0 then
              has_ypogegrammeni = true
              if not greek_iota then
                setchar(post, 0x0399)
              end
              last = post
              post = getnext(post)
            else
              -- Otherwise they get removed
              local old = post
              head, post = remove(head, post)
              if char == 0x0301 and not saved_tonos then
                -- But if we have a tonos we might want to reinsert it later
                saved_tonos = old
              elseif diacritic_data & HAS_DIALYTIKA ~= 0 and not saved_dialytika then
                -- Similar for dilytika
                saved_dialytika = old
              else
                free(old)
              end
            end
          end
          -- Special case: An isolated Ή preserves the tonos.
          if upper == 0x0397
              and not has_ypogegrammeni
              and not seen_cased
              and not is_followed_by_cased(font, n, after)
              then
            if first_datum & HAS_ACCENT ~= 0 then
              upper = 0x0389
              -- If it's precomposed we don't have to keep any combining accents
              if saved_tonos then
                free(saved_tonos)
                saved_tonos = nil
              end
            end
          else
            -- Not the special case so we don't have to keep the tonos node
            if saved_tonos then
              free(saved_tonos)
              saved_tonos = nil
            end
            -- Handle precomposed dialytika. If both a combining ans a precomposed
            -- dialyika are present (typically because the precomposed one is
            -- automatically added at the beginning) prefer the combining one to
            -- preserve attributes.
            if datum & HAS_DIALYTIKA ~= 0 and not saved_dialytika then
              if upper == 0x0399 then -- upper == 'Ι'
                upper = 0x03AA
              elseif upper == 0x03A5 then -- upper == 'Υ'
                upper = 0x03AB
              else
                assert(false) -- Should not be possible
              end
            end
          end
          if greek_iota and add_ypogegrammeni then
            local mapped = greek_precombined_iota[upper]
            if mapped then -- AFAICT always true
              upper = mapped
              add_ypogegrammeni = false
            end
          end
          setchar(n, upper)
          -- Potentially reinsert accents
          if saved_dialytika then
            head, n = insert_after(head, n, saved_dialytika)
            setchar(n, 0x0308) -- Needed since we might have a U+0344 (COMBINING GREEK DIALYTIKA TONOS)
          end
          if saved_tonos then
            head, n = insert_after(head, n, saved_tonos)
          end
          if add_ypogegrammeni then
            head, n = insert_after(head, n, copy(n))
            setchar(n, 0x0399)
          end
          -- If we preserved any combining ypogegrammeni nodes, skip them now
          n = last or n
          seen_greek = datum & (HAS_VOWEL | HAS_ACCENT | HAS_DIALYTIKA) == HAS_VOWEL | HAS_ACCENT and n or true
          seen_I, seen_soft_dotted = nil
        else
          local mapping = table[char]
          if mapping then
            if tonumber(mapping) then
              setchar(n, mapping)
            else
              mapping = seen_cased and is_Final_Sigma(font, mapping, n, after)
                     or lang and is_Language_Mapping(font, mapping[lang], n, after, seen_soft_dotted, seen_I)
                     or mapping._
              if #mapping == 0 then
                local old = n
                head, n = remove(head, n)
                free(old)
                goto continue
              else
                setchar(n, mapping[1])
                for i=2, #mapping do
                  head, n = insert_after(head, n, copy(n))
                  setchar(n, mapping[i])
                end
              end
            end
          end
          local char_ccc = ccc[char]
          if not char_ccc or char_ccc == 230 then
            seen_I = char == 0x49 or nil
            seen_soft_dotted = soft_dotted[char]
          end
          seen_greek = nil
        end
        if not case_ignorable[char] then
          seen_cased = cased[char] or nil
        end
      elseif id == disc and uses_font(n, font) then
        local pre, post, rep = getdisc(n)
        local after = getnext(n)
        pre, post, rep, seen_cased, seen_soft_dotted, seen_I, seen_greek =
            processor(pre, font, nil, seen_cased, seen_soft_dotted, seen_I, seen_greek),
            processor(post, font, after, seen_greek),
            processor(rep, font, after, seen_cased, seen_soft_dotted, seen_I, seen_greek)
        setdisc(n, pre, post, rep)
      else
        seen_cased, seen_soft_dotted, seen_I = nil
      end
      n = getnext(n)
      ::continue::
    end
    return head, seen_cased, seen_soft_dotted, seen_I, seen_greek
  end
  return function(head, font, ...) return (processor(head, font)) end
end

local upper_process = process(uppercase, 'upper')
otfregister {
  name = 'upper',
  description = 'Map to uppercase',
  default = false,
  processors = {
    position = 1,
    plug = upper_process,
    node = upper_process,
    base = upper_process,
  },
}

local lower_process = process(lowercase, 'lower')
otfregister {
  name = 'lower',
  description = 'Map to lowercase',
  default = false,
  processors = {
    position = 1,
    plug = lower_process,
    node = lower_process,
    base = lower_process,
  },
}
