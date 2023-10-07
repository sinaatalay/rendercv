--
-- This is file `babel-bidi-basic.lua',
-- generated with the docstrip utility.
--
-- The original source files were:
--
-- babel.dtx  (with options: `basic')
-- 
--
-- Copyright (C) 2012-2023 Javier Bezos and Johannes L. Braams.
-- Copyright (C) 1989-2012 Johannes L. Braams and
--           any individual authors listed elsewhere in this file.
-- All rights reserved.
--
--
-- This file is part of the Babel system.
-- --------------------------------------
--
-- It may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--   http://www.latex-project.org/lppl.txt
-- and version 1.3 or later is part of all distributions of LaTeX
-- version 2003/12/01 or later.
--
-- This work has the LPPL maintenance status "maintained".
--
-- The Current Maintainer of this work is Javier Bezos.
--
-- The list of derived (unpacked) files belonging to the distribution
-- and covered by LPPL is defined by the unpacking scripts (with
-- extension |.ins|) which are part of the distribution.
--

Babel = Babel or {}

-- eg, Babel.fontmap[1][<prefontid>]=<dirfontid>

Babel.fontmap = Babel.fontmap or {}
Babel.fontmap[0] = {}      -- l
Babel.fontmap[1] = {}      -- r
Babel.fontmap[2] = {}      -- al/an

Babel.bidi_enabled = true
Babel.mirroring_enabled = true

require('babel-data-bidi.lua')

local characters = Babel.characters
local ranges = Babel.ranges

local DIR = node.id('dir')
local GLYPH = node.id('glyph')

local function insert_implicit(head, state, outer)
  local new_state = state
  if state.sim and state.eim and state.sim ~= state.eim then
    dir = ((outer == 'r') and 'TLT' or 'TRT') -- ie, reverse
    local d = node.new(DIR)
    d.dir = '+' .. dir
    node.insert_before(head, state.sim, d)
    local d = node.new(DIR)
    d.dir = '-' .. dir
    node.insert_after(head, state.eim, d)
  end
  new_state.sim, new_state.eim = nil, nil
  return head, new_state
end

local function insert_numeric(head, state)
  local new
  local new_state = state
  if state.san and state.ean and state.san ~= state.ean then
    local d = node.new(DIR)
    d.dir = '+TLT'
    _, new = node.insert_before(head, state.san, d)
    if state.san == state.sim then state.sim = new end
    local d = node.new(DIR)
    d.dir = '-TLT'
    _, new = node.insert_after(head, state.ean, d)
    if state.ean == state.eim then state.eim = new end
  end
  new_state.san, new_state.ean = nil, nil
  return head, new_state
end

-- TODO - \hbox with an explicit dir can lead to wrong results
-- <R \hbox dir TLT{<R>}> and <L \hbox dir TRT{<L>}>. A small attempt
-- was s made to improve the situation, but the problem is the 3-dir
-- model in babel/Unicode and the 2-dir model in LuaTeX don't fit
-- well.

function Babel.bidi(head, ispar, hdir)
  local d   -- d is used mainly for computations in a loop
  local prev_d = ''
  local new_d = false

  local nodes = {}
  local outer_first = nil
  local inmath = false

  local glue_d = nil
  local glue_i = nil

  local has_en = false
  local first_et = nil

  local has_hyperlink = false

  local ATDIR = Babel.attr_dir

  local save_outer
  local temp = node.get_attribute(head, ATDIR)
  if temp then
    temp = temp & 0x3
    save_outer = (temp == 0 and 'l') or
                 (temp == 1 and 'r') or
                 (temp == 2 and 'al')
  elseif ispar then            -- Or error? Shouldn't happen
    save_outer = ('TRT' == tex.pardir) and 'r' or 'l'
  else                         -- Or error? Shouldn't happen
    save_outer = ('TRT' == hdir) and 'r' or 'l'
  end
    -- when the callback is called, we are just _after_ the box,
    -- and the textdir is that of the surrounding text
  -- if not ispar and hdir ~= tex.textdir then
  --   save_outer = ('TRT' == hdir) and 'r' or 'l'
  -- end
  local outer = save_outer
  local last = outer
  -- 'al' is only taken into account in the first, current loop
  if save_outer == 'al' then save_outer = 'r' end

  local fontmap = Babel.fontmap

  for item in node.traverse(head) do

    -- In what follows, #node is the last (previous) node, because the
    -- current one is not added until we start processing the neutrals.

    -- three cases: glyph, dir, otherwise
    if item.id == GLYPH
       or (item.id == 7 and item.subtype == 2) then

      local d_font = nil
      local item_r
      if item.id == 7 and item.subtype == 2 then
        item_r = item.replace    -- automatic discs have just 1 glyph
      else
        item_r = item
      end
      local chardata = characters[item_r.char]
      d = chardata and chardata.d or nil
      if not d or d == 'nsm' then
        for nn, et in ipairs(ranges) do
          if item_r.char < et[1] then
            break
          elseif item_r.char <= et[2] then
            if not d then d = et[3]
            elseif d == 'nsm' then d_font = et[3]
            end
            break
          end
        end
      end
      d = d or 'l'

      -- A short 'pause' in bidi for mapfont
      d_font = d_font or d
      d_font = (d_font == 'l' and 0) or
               (d_font == 'nsm' and 0) or
               (d_font == 'r' and 1) or
               (d_font == 'al' and 2) or
               (d_font == 'an' and 2) or nil
      if d_font and fontmap and fontmap[d_font][item_r.font] then
        item_r.font = fontmap[d_font][item_r.font]
      end

      if new_d then
        table.insert(nodes, {nil, (outer == 'l') and 'l' or 'r', nil})
        if inmath then
          attr_d = 0
        else
          attr_d = node.get_attribute(item, ATDIR)
          attr_d = attr_d & 0x3
        end
        if attr_d == 1 then
          outer_first = 'r'
          last = 'r'
        elseif attr_d == 2 then
          outer_first = 'r'
          last = 'al'
        else
          outer_first = 'l'
          last = 'l'
        end
        outer = last
        has_en = false
        first_et = nil
        new_d = false
      end

      if glue_d then
        if (d == 'l' and 'l' or 'r') ~= glue_d then
           table.insert(nodes, {glue_i, 'on', nil})
        end
        glue_d = nil
        glue_i = nil
      end

    elseif item.id == DIR then
      d = nil

      if head ~= item then new_d = true end

    elseif item.id == node.id'glue' and item.subtype == 13 then
      glue_d = d
      glue_i = item
      d = nil

    elseif item.id == node.id'math' then
      inmath = (item.subtype == 0)

    elseif item.id == 8 and item.subtype == 19 then
      has_hyperlink = true

    else
      d = nil
    end

    -- AL <= EN/ET/ES     -- W2 + W3 + W6
    if last == 'al' and d == 'en' then
      d = 'an'           -- W3
    elseif last == 'al' and (d == 'et' or d == 'es') then
      d = 'on'           -- W6
    end

    -- EN + CS/ES + EN     -- W4
    if d == 'en' and #nodes >= 2 then
      if (nodes[#nodes][2] == 'es' or nodes[#nodes][2] == 'cs')
          and nodes[#nodes-1][2] == 'en' then
        nodes[#nodes][2] = 'en'
      end
    end

    -- AN + CS + AN        -- W4 too, because uax9 mixes both cases
    if d == 'an' and #nodes >= 2 then
      if (nodes[#nodes][2] == 'cs')
          and nodes[#nodes-1][2] == 'an' then
        nodes[#nodes][2] = 'an'
      end
    end

    -- ET/EN               -- W5 + W7->l / W6->on
    if d == 'et' then
      first_et = first_et or (#nodes + 1)
    elseif d == 'en' then
      has_en = true
      first_et = first_et or (#nodes + 1)
    elseif first_et then       -- d may be nil here !
      if has_en then
        if last == 'l' then
          temp = 'l'    -- W7
        else
          temp = 'en'   -- W5
        end
      else
        temp = 'on'     -- W6
      end
      for e = first_et, #nodes do
        if nodes[e][1].id == GLYPH then nodes[e][2] = temp end
      end
      first_et = nil
      has_en = false
    end

    -- Force mathdir in math if ON (currently works as expected only
    -- with 'l')
    if inmath and d == 'on' then
      d = ('TRT' == tex.mathdir) and 'r' or 'l'
    end

    if d then
      if d == 'al' then
        d = 'r'
        last = 'al'
      elseif d == 'l' or d == 'r' then
        last = d
      end
      prev_d = d
      table.insert(nodes, {item, d, outer_first})
    end

    outer_first = nil

  end

  -- TODO -- repeated here in case EN/ET is the last node. Find a
  -- better way of doing things:
  if first_et then       -- dir may be nil here !
    if has_en then
      if last == 'l' then
        temp = 'l'    -- W7
      else
        temp = 'en'   -- W5
      end
    else
      temp = 'on'     -- W6
    end
    for e = first_et, #nodes do
      if nodes[e][1].id == GLYPH then nodes[e][2] = temp end
    end
  end

  -- dummy node, to close things
  table.insert(nodes, {nil, (outer == 'l') and 'l' or 'r', nil})

  ---------------  NEUTRAL -----------------

  outer = save_outer
  last = outer

  local first_on = nil

  for q = 1, #nodes do
    local item

    local outer_first = nodes[q][3]
    outer = outer_first or outer
    last = outer_first or last

    local d = nodes[q][2]
    if d == 'an' or d == 'en' then d = 'r' end
    if d == 'cs' or d == 'et' or d == 'es' then d = 'on' end --- W6

    if d == 'on' then
      first_on = first_on or q
    elseif first_on then
      if last == d then
        temp = d
      else
        temp = outer
      end
      for r = first_on, q - 1 do
        nodes[r][2] = temp
        item = nodes[r][1]    -- MIRRORING
        if Babel.mirroring_enabled and item.id == GLYPH
             and temp == 'r' and characters[item.char] then
          local font_mode = ''
          if item.font > 0 and font.fonts[item.font].properties then
            font_mode = font.fonts[item.font].properties.mode
          end
          if font_mode ~= 'harf' and font_mode ~= 'plug' then
            item.char = characters[item.char].m or item.char
          end
        end
      end
      first_on = nil
    end

    if d == 'r' or d == 'l' then last = d end
  end

  --------------  IMPLICIT, REORDER ----------------

  outer = save_outer
  last = outer

  local state = {}
  state.has_r = false

  for q = 1, #nodes do

    local item = nodes[q][1]

    outer = nodes[q][3] or outer

    local d = nodes[q][2]

    if d == 'nsm' then d = last end             -- W1
    if d == 'en' then d = 'an' end
    local isdir = (d == 'r' or d == 'l')

    if outer == 'l' and d == 'an' then
      state.san = state.san or item
      state.ean = item
    elseif state.san then
      head, state = insert_numeric(head, state)
    end

    if outer == 'l' then
      if d == 'an' or d == 'r' then     -- im -> implicit
        if d == 'r' then state.has_r = true end
        state.sim = state.sim or item
        state.eim = item
      elseif d == 'l' and state.sim and state.has_r then
        head, state = insert_implicit(head, state, outer)
      elseif d == 'l' then
        state.sim, state.eim, state.has_r = nil, nil, false
      end
    else
      if d == 'an' or d == 'l' then
        if nodes[q][3] then -- nil except after an explicit dir
          state.sim = item  -- so we move sim 'inside' the group
        else
          state.sim = state.sim or item
        end
        state.eim = item
      elseif d == 'r' and state.sim then
        head, state = insert_implicit(head, state, outer)
      elseif d == 'r' then
        state.sim, state.eim = nil, nil
      end
    end

    if isdir then
      last = d           -- Don't search back - best save now
    elseif d == 'on' and state.san  then
      state.san = state.san or item
      state.ean = item
    end

  end

  head = node.prev(head) or head

  -------------- FIX HYPERLINKS ----------------

  if has_hyperlink then
    local flag, linking = 0, 0
    for item in node.traverse(head) do
      if item.id == DIR then
        if item.dir == '+TRT' or item.dir == '+TLT' then
          flag = flag + 1
        elseif item.dir == '-TRT' or item.dir == '-TLT' then
          flag = flag - 1
        end
      elseif item.id == 8 and item.subtype == 19 then
        linking = flag
      elseif item.id == 8 and item.subtype == 20 then
        if linking > 0 then
          if item.prev.id == DIR and
              (item.prev.dir == '-TRT' or item.prev.dir == '-TLT') then
            d = node.new(DIR)
            d.dir = item.prev.dir
            node.remove(head, item.prev)
            node.insert_after(head, item, d)
          end
        end
        linking = 0
      end
    end
  end

  return head
end
