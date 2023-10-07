--
-- This is file `babel-transforms.lua',
-- generated with the docstrip utility.
--
-- The original source files were:
--
-- babel.dtx  (with options: `transforms')
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

Babel.linebreaking.replacements = {}
Babel.linebreaking.replacements[0] = {}  -- pre
Babel.linebreaking.replacements[1] = {}  -- post

-- Discretionaries contain strings as nodes
function Babel.str_to_nodes(fn, matches, base)
  local n, head, last
  if fn == nil then return nil end
  for s in string.utfvalues(fn(matches)) do
    if base.id == 7 then
      base = base.replace
    end
    n = node.copy(base)
    n.char    = s
    if not head then
      head = n
    else
      last.next = n
    end
    last = n
  end
  return head
end

Babel.fetch_subtext = {}

Babel.ignore_pre_char = function(node)
  return (node.lang == Babel.nohyphenation)
end

-- Merging both functions doesn't seen feasible, because there are too
-- many differences.
Babel.fetch_subtext[0] = function(head)
  local word_string = ''
  local word_nodes = {}
  local lang
  local item = head
  local inmath = false

  while item do

    if item.id == 11 then
      inmath = (item.subtype == 0)
    end

    if inmath then
      -- pass

    elseif item.id == 29 then
      local locale = node.get_attribute(item, Babel.attr_locale)

      if lang == locale or lang == nil then
        lang = lang or locale
        if Babel.ignore_pre_char(item) then
          word_string = word_string .. Babel.us_char
        else
          word_string = word_string .. unicode.utf8.char(item.char)
        end
        word_nodes[#word_nodes+1] = item
      else
        break
      end

    elseif item.id == 12 and item.subtype == 13 then
      word_string = word_string .. ' '
      word_nodes[#word_nodes+1] = item

    -- Ignore leading unrecognized nodes, too.
    elseif word_string ~= '' then
      word_string = word_string .. Babel.us_char
      word_nodes[#word_nodes+1] = item  -- Will be ignored
    end

    item = item.next
  end

  -- Here and above we remove some trailing chars but not the
  -- corresponding nodes. But they aren't accessed.
  if word_string:sub(-1) == ' ' then
    word_string = word_string:sub(1,-2)
  end
  word_string = unicode.utf8.gsub(word_string, Babel.us_char .. '+$', '')
  return word_string, word_nodes, item, lang
end

Babel.fetch_subtext[1] = function(head)
  local word_string = ''
  local word_nodes = {}
  local lang
  local item = head
  local inmath = false

  while item do

    if item.id == 11 then
      inmath = (item.subtype == 0)
    end

    if inmath then
      -- pass

    elseif item.id == 29 then
      if item.lang == lang or lang == nil then
        if (item.char ~= 124) and (item.char ~= 61) then -- not =, not |
          lang = lang or item.lang
          word_string = word_string .. unicode.utf8.char(item.char)
          word_nodes[#word_nodes+1] = item
        end
      else
        break
      end

    elseif item.id == 7 and item.subtype == 2 then
      word_string = word_string .. '='
      word_nodes[#word_nodes+1] = item

    elseif item.id == 7 and item.subtype == 3 then
      word_string = word_string .. '|'
      word_nodes[#word_nodes+1] = item

    -- (1) Go to next word if nothing was found, and (2) implicitly
    -- remove leading USs.
    elseif word_string == '' then
      -- pass

    -- This is the responsible for splitting by words.
    elseif (item.id == 12 and item.subtype == 13) then
      break

    else
      word_string = word_string .. Babel.us_char
      word_nodes[#word_nodes+1] = item  -- Will be ignored
    end

    item = item.next
  end

  word_string = unicode.utf8.gsub(word_string, Babel.us_char .. '+$', '')
  return word_string, word_nodes, item, lang
end

function Babel.pre_hyphenate_replace(head)
  Babel.hyphenate_replace(head, 0)
end

function Babel.post_hyphenate_replace(head)
  Babel.hyphenate_replace(head, 1)
end

Babel.us_char = string.char(31)

function Babel.hyphenate_replace(head, mode)
  local u = unicode.utf8
  local lbkr = Babel.linebreaking.replacements[mode]

  local word_head = head

  while true do  -- for each subtext block

    local w, w_nodes, nw, lang = Babel.fetch_subtext[mode](word_head)

    if Babel.debug then
      print()
      print((mode == 0) and '@@@@<' or '@@@@>', w)
    end

    if nw == nil and w == '' then break end

    if not lang then goto next end
    if not lbkr[lang] then goto next end

    -- For each saved (pre|post)hyphenation. TODO. Reconsider how
    -- loops are nested.
    for k=1, #lbkr[lang] do
      local p = lbkr[lang][k].pattern
      local r = lbkr[lang][k].replace
      local attr = lbkr[lang][k].attr or -1

      if Babel.debug then
        print('*****', p, mode)
      end

      -- This variable is set in some cases below to the first *byte*
      -- after the match, either as found by u.match (faster) or the
      -- computed position based on sc if w has changed.
      local last_match = 0
      local step = 0

      -- For every match.
      while true do
        if Babel.debug then
          print('=====')
        end
        local new  -- used when inserting and removing nodes

        local matches = { u.match(w, p, last_match) }

        if #matches < 2 then break end

        -- Get and remove empty captures (with ()'s, which return a
        -- number with the position), and keep actual captures
        -- (from (...)), if any, in matches.
        local first = table.remove(matches, 1)
        local last  = table.remove(matches, #matches)
        -- Non re-fetched substrings may contain \31, which separates
        -- subsubstrings.
        if string.find(w:sub(first, last-1), Babel.us_char) then break end

        local save_last = last -- with A()BC()D, points to D

        -- Fix offsets, from bytes to unicode. Explained above.
        first = u.len(w:sub(1, first-1)) + 1
        last  = u.len(w:sub(1, last-1)) -- now last points to C

        -- This loop stores in a small table the nodes
        -- corresponding to the pattern. Used by 'data' to provide a
        -- predictable behavior with 'insert' (w_nodes is modified on
        -- the fly), and also access to 'remove'd nodes.
        local sc = first-1           -- Used below, too
        local data_nodes = {}

        local enabled = true
        for q = 1, last-first+1 do
          data_nodes[q] = w_nodes[sc+q]
          if enabled
              and attr > -1
              and not node.has_attribute(data_nodes[q], attr)
            then
            enabled = false
          end
        end

        -- This loop traverses the matched substring and takes the
        -- corresponding action stored in the replacement list.
        -- sc = the position in substr nodes / string
        -- rc = the replacement table index
        local rc = 0

        while rc < last-first+1 do -- for each replacement
          if Babel.debug then
            print('.....', rc + 1)
          end
          sc = sc + 1
          rc = rc + 1

          if Babel.debug then
            Babel.debug_hyph(w, w_nodes, sc, first, last, last_match)
            local ss = ''
            for itt in node.traverse(head) do
             if itt.id == 29 then
               ss = ss .. unicode.utf8.char(itt.char)
             else
               ss = ss .. '{' .. itt.id .. '}'
             end
            end
            print('*****************', ss)

          end

          local crep = r[rc]
          local item = w_nodes[sc]
          local item_base = item
          local placeholder = Babel.us_char
          local d

          if crep and crep.data then
            item_base = data_nodes[crep.data]
          end

          if crep then
            step = crep.step or 0
          end

          if (not enabled) or (crep and next(crep) == nil) then -- = {}
            last_match = save_last    -- Optimization
            goto next

          elseif crep == nil or crep.remove then
            node.remove(head, item)
            table.remove(w_nodes, sc)
            w = u.sub(w, 1, sc-1) .. u.sub(w, sc+1)
            sc = sc - 1  -- Nothing has been inserted.
            last_match = utf8.offset(w, sc+1+step)
            goto next

          elseif crep and crep.kashida then -- Experimental
            node.set_attribute(item,
               Babel.attr_kashida,
               crep.kashida)
            last_match = utf8.offset(w, sc+1+step)
            goto next

          elseif crep and crep.string then
            local str = crep.string(matches)
            if str == '' then  -- Gather with nil
              node.remove(head, item)
              table.remove(w_nodes, sc)
              w = u.sub(w, 1, sc-1) .. u.sub(w, sc+1)
              sc = sc - 1  -- Nothing has been inserted.
            else
              local loop_first = true
              for s in string.utfvalues(str) do
                d = node.copy(item_base)
                d.char = s
                if loop_first then
                  loop_first = false
                  head, new = node.insert_before(head, item, d)
                  if sc == 1 then
                    word_head = head
                  end
                  w_nodes[sc] = d
                  w = u.sub(w, 1, sc-1) .. u.char(s) .. u.sub(w, sc+1)
                else
                  sc = sc + 1
                  head, new = node.insert_before(head, item, d)
                  table.insert(w_nodes, sc, new)
                  w = u.sub(w, 1, sc-1) .. u.char(s) .. u.sub(w, sc)
                end
                if Babel.debug then
                  print('.....', 'str')
                  Babel.debug_hyph(w, w_nodes, sc, first, last, last_match)
                end
              end  -- for
              node.remove(head, item)
            end  -- if ''
            last_match = utf8.offset(w, sc+1+step)
            goto next

          elseif mode == 1 and crep and (crep.pre or crep.no or crep.post) then
            d = node.new(7, 3)   -- (disc, regular)
            d.pre     = Babel.str_to_nodes(crep.pre, matches, item_base)
            d.post    = Babel.str_to_nodes(crep.post, matches, item_base)
            d.replace = Babel.str_to_nodes(crep.no, matches, item_base)
            d.attr = item_base.attr
            if crep.pre == nil then  -- TeXbook p96
              d.penalty = crep.penalty or tex.hyphenpenalty
            else
              d.penalty = crep.penalty or tex.exhyphenpenalty
            end
            placeholder = '|'
            head, new = node.insert_before(head, item, d)

          elseif mode == 0 and crep and (crep.pre or crep.no or crep.post) then
            -- ERROR

          elseif crep and crep.penalty then
            d = node.new(14, 0)   -- (penalty, userpenalty)
            d.attr = item_base.attr
            d.penalty = crep.penalty
            head, new = node.insert_before(head, item, d)

          elseif crep and crep.space then
            -- 655360 = 10 pt = 10 * 65536 sp
            d = node.new(12, 13)      -- (glue, spaceskip)
            local quad = font.getfont(item_base.font).size or 655360
            node.setglue(d, crep.space[1] * quad,
                            crep.space[2] * quad,
                            crep.space[3] * quad)
            if mode == 0 then
              placeholder = ' '
            end
            head, new = node.insert_before(head, item, d)

          elseif crep and crep.spacefactor then
            d = node.new(12, 13)      -- (glue, spaceskip)
            local base_font = font.getfont(item_base.font)
            node.setglue(d,
              crep.spacefactor[1] * base_font.parameters['space'],
              crep.spacefactor[2] * base_font.parameters['space_stretch'],
              crep.spacefactor[3] * base_font.parameters['space_shrink'])
            if mode == 0 then
              placeholder = ' '
            end
            head, new = node.insert_before(head, item, d)

          elseif mode == 0 and crep and crep.space then
            -- ERROR

          end  -- ie replacement cases

          -- Shared by disc, space and penalty.
          if sc == 1 then
            word_head = head
          end
          if crep.insert then
            w = u.sub(w, 1, sc-1) .. placeholder .. u.sub(w, sc)
            table.insert(w_nodes, sc, new)
            last = last + 1
          else
            w_nodes[sc] = d
            node.remove(head, item)
            w = u.sub(w, 1, sc-1) .. placeholder .. u.sub(w, sc+1)
          end

          last_match = utf8.offset(w, sc+1+step)

          ::next::

        end  -- for each replacement

        if Babel.debug then
            print('.....', '/')
            Babel.debug_hyph(w, w_nodes, sc, first, last, last_match)
        end

      end  -- for match

    end  -- for patterns

    ::next::
    word_head = nw
  end  -- for substring
  return head
end

-- This table stores capture maps, numbered consecutively
Babel.capture_maps = {}

-- The following functions belong to the next macro
function Babel.capture_func(key, cap)
  local ret = "[[" .. cap:gsub('{([0-9])}', "]]..m[%1]..[[") .. "]]"
  local cnt
  local u = unicode.utf8
  ret, cnt = ret:gsub('{([0-9])|([^|]+)|(.-)}', Babel.capture_func_map)
  if cnt == 0 then
    ret = u.gsub(ret, '{(%x%x%x%x+)}',
          function (n)
            return u.char(tonumber(n, 16))
          end)
  end
  ret = ret:gsub("%[%[%]%]%.%.", '')
  ret = ret:gsub("%.%.%[%[%]%]", '')
  return key .. [[=function(m) return ]] .. ret .. [[ end]]
end

function Babel.capt_map(from, mapno)
  return Babel.capture_maps[mapno][from] or from
end

-- Handle the {n|abc|ABC} syntax in captures
function Babel.capture_func_map(capno, from, to)
  local u = unicode.utf8
  from = u.gsub(from, '{(%x%x%x%x+)}',
       function (n)
         return u.char(tonumber(n, 16))
       end)
  to = u.gsub(to, '{(%x%x%x%x+)}',
       function (n)
         return u.char(tonumber(n, 16))
       end)
  local froms = {}
  for s in string.utfcharacters(from) do
    table.insert(froms, s)
  end
  local cnt = 1
  table.insert(Babel.capture_maps, {})
  local mlen = table.getn(Babel.capture_maps)
  for s in string.utfcharacters(to) do
    Babel.capture_maps[mlen][froms[cnt]] = s
    cnt = cnt + 1
  end
  return "]]..Babel.capt_map(m[" .. capno .. "]," ..
         (mlen) .. ").." .. "[["
end

-- Create/Extend reversed sorted list of kashida weights:
function Babel.capture_kashida(key, wt)
  wt = tonumber(wt)
  if Babel.kashida_wts then
    for p, q in ipairs(Babel.kashida_wts) do
      if wt  == q then
        break
      elseif wt > q then
        table.insert(Babel.kashida_wts, p, wt)
        break
      elseif table.getn(Babel.kashida_wts) == p then
        table.insert(Babel.kashida_wts, wt)
      end
    end
  else
    Babel.kashida_wts = { wt }
  end
  return 'kashida = ' .. wt
end

-- Experimental: applies prehyphenation transforms to a string (letters
-- and spaces).
function Babel.string_prehyphenation(str, locale)
  local n, head, last, res
  head = node.new(8, 0) -- dummy (hack just to start)
  last = head
  for s in string.utfvalues(str) do
    if s == 20 then
      n = node.new(12, 0)
    else
      n = node.new(29, 0)
      n.char = s
    end
    node.set_attribute(n, Babel.attr_locale, locale)
    last.next = n
    last = n
  end
  head = Babel.hyphenate_replace(head, 0)
  res = ''
  for n in node.traverse(head) do
    if n.id == 12 then
      res = res .. ' '
    elseif n.id == 29 then
      res = res .. unicode.utf8.char(n.char)
    end
  end
  tex.print(res)
end
