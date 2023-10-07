-----------------------------------------------------------------------
--         FILE:  luaotfload-letterspace.lua
--  DESCRIPTION:  part of luaotfload / letterspacing
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-letterspace",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / letterspacing",
    license       = "GPL v2.0",
    copyright     = "PRAGMA ADE / ConTeXt Development Team",
    author        = "Hans Hagen, PRAGMA-ADE, Hasselt NL; adapted by Philipp Gesang, Ulrike Fischer, Marcel Krüger"
}

--- This code diverged quite a bit from its origin in Context. Please
--- do *not* report bugs on the Context list.

local logreport          = luaotfload.log.report

local getmetatable       = getmetatable
local setmetatable       = setmetatable
local tonumber           = tonumber
local unpack             = table.unpack

local next               = next
local node, fonts        = node, fonts

local nodedirect         = node.direct

local getfield           = nodedirect.getfield
local setfield           = nodedirect.setfield

local getfont            = nodedirect.getfont
local getid              = nodedirect.getid

local getnext            = nodedirect.getnext
local setnext            = nodedirect.setnext

local getprev            = nodedirect.getprev
local setprev            = nodedirect.setprev

local getboth            = nodedirect.getboth

local setlink            = nodedirect.setlink

local getdisc            = nodedirect.getdisc
local setdisc            = nodedirect.setdisc

local getsubtype         = nodedirect.getsubtype
local setsubtype         = nodedirect.setsubtype

local getchar            = nodedirect.getchar
local setchar            = nodedirect.setchar

local getkern            = nodedirect.getkern
local setkern            = nodedirect.setkern

local getglue            = nodedirect.getglue
local setglue            = nodedirect.setglue

local hasattribute       = nodedirect.has_attribute
local setattribute       = nodedirect.set_attribute

local getattributelist   = nodedirect.getattributelist
local setattributelist   = nodedirect.setattributelist

local find_node_tail     = nodedirect.tail
local todirect           = nodedirect.todirect
local tonode             = nodedirect.tonode

local insert_node_before = nodedirect.insert_before
local real_free_node     = nodedirect.free
local copy_node          = nodedirect.copy
local new_node           = nodedirect.new

local glyph_code         = node.id"glyph"
local kern_code          = node.id"kern"
local disc_code          = node.id"disc"
local glue_code          = node.id"glue"
local whatsit_code       = node.id"whatsit"

local fonthashes         = fonts.hashes
local identifiers        = fonthashes.identifiers
local chardata           = fonthashes.characters
local otffeatures        = fonts.constructors.newfeatures "otf"
local markdata

-- For every attribute list cached in attribute_table, we have to make
-- sure that it doesn't get deleted. Therefore attribute_cleanup maps
-- from a node which has the attribute_list referenced in
-- attribute_table to the key from attribute_table.
-- Whenever a node which has an entry in attribute_cleanup is deleted,
-- we delete the corresponding entry from attribute_table since we can
-- no longer guarantee that it's references somewhere.
local attribute_table    = {}
local attribute_cleanup  = {}
local attr = luatexbase.new_attribute("luaotfload.letterspace_done")

local function free_node(n)
  local k = attribute_cleanup[n]
  if k then
    attribute_cleanup[n], attribute_table[k] = nil
  end
  return real_free_node(n)
end

local function getprevreal(n)
  repeat
    n = getprev(n)
  until not n or getid(n) ~= whatsit_code
  return n
end
local function getnextreal(n)
  repeat
    n = getnext(n)
  until not n or getid(n) ~= whatsit_code
  return n
end

--[[doc--

  Since the letterspacing method was derived initially from Context’s
  typo-krn.lua we keep the sub-namespace “letterspace” inside the
  “luaotfload” table.

--doc]]--

luaotfload.letterspace   = luaotfload.letterspace or { }
local letterspace        = luaotfload.letterspace

local lectured = false
letterspace.keepligature = true
letterspace.keeptogether = false
letterspace.keepwordspacing = false

---=================================================================---
---                     preliminary definitions
---=================================================================---
-- We set up a layer emulating some Context internals that are needed
-- for the letterspacing callback.
-----------------------------------------------------------------------
--- node-ini
-----------------------------------------------------------------------

local kerning_code      = 0
local userkern_code     = 1
local userskip_code     = 0
local spaceskip_code    = 13
local xspaceskip_code   = 14

if not chardata then
  chardata = { }
  table.setmetatableindex(chardata, function(t, k)
    if k == true then
      return chardata[currentfont()]
    else
      local tfmdata = font.getfont(k) or font.fonts[k]
      if tfmdata then
        local characters = tfmdata.characters
        t[k] = characters
        return characters
      end
    end
  end)
  fonthashes.characters = chardata
end

if not markdata then
  markdata = setmetatable({}, {__index = function(t, k)
    if k == true then
      return t[currentfont()]
    else
      local tfmdata = font.getfont(k) or font.fonts[k]
      if tfmdata then
        local marks = tfmdata.resources.marks or {}
        t[k] = marks
        return marks
      end
    end
  end})
end

---=================================================================---
---                 character kerning functionality
---=================================================================---

-- UF changed 2017-07-14
local function kern_injector (fillup, kern)
 if fillup then
   local g = new_node(glue_code)
   setglue(g, 0, kern, 0, 1, 0)
   return g
 end
   local g = new_node(kern_code)
   setkern(g,kern)
   return g
end
-- /UF

local function kernable_skip (n)
  local st = getsubtype (n)
  return st == userskip_code
      or st == spaceskip_code
      or st == xspaceskip_code
end

--[[doc--

    Caveat lector.
    This is an adaptation of the Context character kerning mechanism
    that emulates XeTeX-style fontwise letterspacing. Note that in its
    present state it is far inferior to the original, which is
    attribute-based and ignores font-boundaries. Nevertheless, due to
    popular demand the following callback has been added.

--doc]]--

local kernamounts = table.setmetatableindex(function (t, f) --- fontid -> {kern, fill}
  local tfmdata = font.getfont(f) or font.fonts[f]
  if tfmdata then
    local fontproperties = tfmdata.properties
    local fontparameters = tfmdata.parameters
    if fontproperties and fontparameters then
      local r
      if fontproperties.kerncharacters == "max" then
        r = {fontparameters.quad/4, true}
      elseif fontproperties.kerncharacters then
        r = {fontproperties.kerncharacters * fontparameters.quad, false}
      else
        r = {}
      end
      t[f] = r
      return r
    end
  end
  return {}
end)

local kerncharacters
kerncharacters = function (head)
  local start         = head
  local lastfont      = nil
  local keeptogether  = letterspace.keeptogether --- function
  local keepligature  = letterspace.keepligature
--  if not lectured and keepligature ~= true then
--    logreport ("both", 0, "letterspace",
--               "Breaking ligatures through letterspacing is deprecated and "
--            .. "will be removed soon. Please disable unwanted ligatures through "
--            .. "font features instead and reset luaotfload.letterspace.keepligature "
--            .. "to true to maintain compatibility with future versions of luaotfload.")
--    lectured = true
--  end
  if type(keepligature) ~= "function" then
    local savedligature = keepligature
    keepligature = function() return savedligature end
  end
  local keepwordspacing = letterspace.keepwordspacing
  if type(keepwordspacing) ~= "function" then
    local savedwordspacing = keepwordspacing
    keepwordspacing = function() return savedwordspacing end
  end

  local kernamounts   = kernamounts
  local firstkern     = true

  while start do
    local id = getid(start)
    if id == glyph_code then
      --- 1) look up kern factor (slow, but cached rudimentarily)
      if hasattribute(start, attr, 1) then -- We already kerned this node
        firstkern = false -- TODO: I'm not sure about this one yet
        goto nextnode
      end
      local fontid = getfont(start)
      local krn, fillup = unpack(kernamounts[fontid])
      if not krn or krn == 0 then
        firstkern = true
        goto nextnode
      elseif firstkern then
        firstkern = false
        if (id ~= disc_code) and (not getfield(start, "components")) then
          --- not a ligature, skip node
          goto nextnode
        end
      end

      lastfont = fontid

      --- 2) resolve ligatures
      local c = getfield(start, "components")

      if c then
        if keepligature(start) then
          -- keep 'm
          c = nil
        else
          while c do
            local s = start
            local p, n = getboth (s)
            if p then
              setlink (p, c)
            else
              head = c
            end
            if n then
              local tail = find_node_tail(c)
              setlink (tail, n)
            end
            start = c
            setfield(s, "components", nil)
            free_node(s) --> double free with multipart components
            c = getfield (start, "components")
          end
        end
      end -- kern ligature

      --- 3) apply the extra kerning
      local prev = getprevreal(start)
      if prev then
        local pid = getid(prev)

        if not pid then
          -- nothing

        elseif pid == glue_code and kernable_skip(prev)
                                and not keepwordspacing(prev, lastfont) then
          local wd, stretch, shrink = getglue(prev)
          if wd > 0 then
            local newwd     = wd + krn
            local stretched = (stretch * newwd) / wd
            local shrunk    = (shrink  * newwd) / wd
            if fillup then
              setglue(prev, newwd, 2 * stretched, 2 * shrunk, 1, 0)
            else
              setglue(prev, newwd, stretched, shrunk, 0, 0)
            end
          end

        elseif pid == kern_code then
          local prev_subtype = getsubtype(prev)
          if prev_subtype == kerning_code   --- context does this by means of an
          or prev_subtype == userkern_code  --- attribute; we may need a test
          then

            local pprev    = getprevreal(prev)
            local pprev_id = getid(pprev)

            if    keeptogether
              and pprev_id == glyph_code
              and keeptogether(pprev, start)
            then
              -- keep
            else
              setsubtype (prev, userkern_code)
              local prev_kern = getkern(prev)
              prev_kern = prev_kern + krn
              setkern (prev, prev_kern)
            end
          end

        elseif pid == glyph_code then
          if getfont(prev) == lastfont then
            local prevchar = getchar(prev)
            local lastchar = getchar(start)
            if keeptogether and keeptogether(prev, start) then
              -- keep 'm
            elseif identifiers[lastfont] then
              local lastfontchars = chardata[lastfont]
              if lastfontchars then
                local prevchardata  = lastfontchars[prevchar]
                if not prevchardata then
                  --- font doesn’t contain the glyph
                else
                  local kern = 0
                  local kerns = prevchardata.kerns
                  if kerns then kern = kerns[lastchar] or kern end
                  krn = kern + (markdata[lastfont][lastchar] and 0 or krn) -- here
                  insert_node_before(head,start,kern_injector(fillup,krn))
                end
              end
            end
          else
            insert_node_before(head,start,kern_injector(fillup,krn))
          end

        elseif pid == disc_code then
          local disc = prev -- disc
          local pre, post, replace = getdisc (disc)
          local prv = getprevreal(disc)
          local nxt = getnextreal(disc)

          if pre and prv then -- must pair with start.prev
            -- this one happens in most cases
            local before = copy_node(prv)
            setprev(pre,    before)
            setnext(before, pre)
            setprev(before, nil)
            pre = kerncharacters (before)
            pre = getnext(pre)
            setprev(pre, nil)
            setfield(disc, "pre", pre)
            free_node(before)
          end

          if post and nxt then  -- must pair with start
            local after = copy_node(nxt)
            local tail = find_node_tail(post)
            setnext(tail,  after)
            setprev(after, tail)
            post = kerncharacters (post)
            setnext(getprev(after), nil)
            setfield(disc, "post", post)
            free_node(after)
          end

          if replace and prv and nxt then -- must pair with start and start.prev
            local before = copy_node(prv)
            local after = copy_node(nxt)
            local tail = find_node_tail(replace)
            setprev(replace, before)
            setnext(before,  replace)
            setprev(before,  nil)
            setnext(tail,    after)
            setprev(after,   tail)
            setnext(after,   nil)
            replace = kerncharacters (before)
            replace = getnext(replace)
            setprev(replace, nil)
            setnext(getprev(after), nil)
            setfield(disc, "replace", replace)
            free_node(after)
            free_node(before)

          elseif identifiers[lastfont] then
            if    prv
              and getid(prv)   == glyph_code
              and getfont(prv) == lastfont
            then
              local kern     = 0
              local prevchar = getchar(prv)
              local lastchar = getchar(start)
              local lastfontchars = chardata[lastfont]
              if lastfontchars then
                local prevchardata = lastfontchars[prevchar]
                if not prevchardata then
                  --- font doesn’t contain the glyph
                else
                  local kerns = prevchardata.kerns
                  if kerns then kern = kerns[lastchar] or kern end
                end
              end
              krn = kern + (markdata[lastfont][lastchar] and 0 or krn) -- here
            end
            setfield(disc, "replace", kern_injector(false, krn))
          end --[[if replace and prv and nxt]]
        end --[[if not pid]]
        local attr_list = getattributelist(start)
        local new_attr_list = attribute_table[attr_list]
        if new_attr_list then
          setattributelist(start, new_attr_list)
        else
          setattribute(start, attr, 1)
          attribute_cleanup[start] = attr_list
          attribute_table[attr_list] = getattributelist(start)
        end
      end --[[if prev]]
    end --[[if id == glyph_code]]

    ::nextnode::
    if start then
      start = getnext(start)
    end
  end
  return head
end

---=================================================================---
---                         integration
---=================================================================---

--- · callback:     kerncharacters
--- · enabler:      enablefontkerning

--- callback wrappers

--- (node_t -> node_t) -> string -> string list -> bool
local registered_as = { } --- procname -> callbacks
local function add_processor (processor, name, ...)
  local callbacks = { ... }
  for i=1, #callbacks do
    luatexbase.add_to_callback(callbacks[i], processor, name)
  end
  registered_as[name] = callbacks --- for removal
  return true
end

--- When font kerning is requested, usually by defining a font with the
--- ``letterspace`` parameter, we inject a wrapper for the
--- ``kerncharacters()`` node processor in the relevant callbacks. This
--- wrapper initially converts the received head node into its “direct”
--- counterpart. Likewise, the callback result is converted back to an
--- ordinary node prior to returning. Internally, ``kerncharacters()``
--- performs all node operations on direct nodes.

--- unit -> bool
local function enablefontkerning ( )

  local function handler (hd)
    local direct_hd = todirect (hd)
    logreport ("term", 5, "letterspace",
               "kerncharacters() invoked with node.direct interface \z
               (``%s`` -> ``%s``)", tostring (hd), tostring (direct_hd))
    local direct_hd = kerncharacters (direct_hd)
    if not direct_hd then --- bad
      logreport ("both", 0, "letterspace",
                 "kerncharacters() failed to return a valid new head")
    end

    for k, v in next, attribute_cleanup do attribute_cleanup[k], attribute_table[v] = nil end
    assert(not next(attribute_table))

    return tonode (direct_hd)
  end

  return add_processor( handler
                      , "luaotfload.letterspace"
                      , "pre_linebreak_filter"
                      , "hpack_filter")
end

--[[doc--

  Fontwise kerning is enabled via the “kernfactor” option at font
  definition time. Unlike the Context implementation which relies on
  Luatex attributes, it uses a font property for passing along the
  letterspacing factor of a node.

  The callback is activated the first time a letterspaced font is
  requested and stays active until the end of the run. Since the font
  is a property of individual glyphs, every glyph in the entire
  document must be checked for the kern property. This is quite
  inefficient compared to Context’s attribute based approach, but Xetex
  compatibility reduces our options significantly.

--doc]]--


local fontkerning_enabled = false --- callback state

--- fontobj -> float -> unit
local function initializefontkerning (tfmdata, factor)
  if factor ~= "max" then
    factor = tonumber (factor) or 0
  end
  if factor == "max" or factor ~= 0 then
    local fontproperties = tfmdata.properties
    if fontproperties then
      --- hopefully this field stays unused otherwise
      fontproperties.kerncharacters = factor
    end
    if not fontkerning_enabled then
      fontkerning_enabled = enablefontkerning ()
    end
  end
end

--- like the font colorization, fontwise kerning is hooked into the
--- feature mechanism

otffeatures.register {
  name        = "kernfactor",
  description = "kernfactor",
  initializers = {
    base = initializefontkerning,
    node = initializefontkerning,
    plug = initializefontkerning,
  }
}

--[[doc--

  The “letterspace” feature is essentially identical with the above
  “kernfactor” method, but scales the factor to percentages to match
  Xetex’s behavior. (See the Xetex reference, page 5, section 1.2.2.)

  Since Xetex doesn’t appear to have a (documented) “max” keyword, we
  assume all input values are numeric.

--doc]]--

local function initializecompatfontkerning (tfmdata, percentage)
  local factor = tonumber (percentage)
  if not factor then
    logreport ("both", 0, "letterspace",
               "Invalid argument to letterspace: %s (type %q), " ..
               "was expecting percentage as Lua number instead.",
               percentage, type (percentage))
    return
  end
  return initializefontkerning (tfmdata, factor * 0.01)
end

otffeatures.register {
  name        = "letterspace",
  description = "letterspace",
  initializers = {
    base = initializecompatfontkerning,
    node = initializecompatfontkerning,
    plug = initializecompatfontkerning,
  }
}

--[[example--

See https://bitbucket.org/phg/lua-la-tex-tests/src/tip/pln-letterspace-8-compare.tex
for an example.

--example]]--

--- vim:sw=2:ts=2:expandtab:tw=71

