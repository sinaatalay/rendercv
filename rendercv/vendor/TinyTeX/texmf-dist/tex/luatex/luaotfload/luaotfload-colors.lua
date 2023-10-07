-----------------------------------------------------------------------
--         FILE:  luaotfload-colors.lua
--  DESCRIPTION:  part of luaotfload / font colors
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-colors",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / color",
    license       = "GPL v2.0",
    author        = "Khaled Hosny, Elie Roux, Philipp Gesang, Dohyun Kim, David Carlisle",
    copyright     = "Luaotfload Development Team"
    }

--[[doc--

buggy coloring with the pre_output_filter when expansion is enabled
    · tfmdata for different expansion values is split over different objects
    · in ``initializeexpansion()``, chr.expansion_factor is set, and only
      those characters that have it are affected
    · in constructors.scale: chr.expansion_factor = ve*1000 if commented out
      makes the bug vanish

explanation: http://tug.org/pipermail/luatex/2013-May/004305.html

--doc]]--

local logreport             = luaotfload and luaotfload.log.report or print

local nodedirect            = node.direct
local newnode               = nodedirect.new
local insert_node_before    = nodedirect.insert_before
local insert_node_after     = nodedirect.insert_after
local todirect              = nodedirect.todirect
local tonode                = nodedirect.tonode
local setfield              = nodedirect.setfield
local setdisc               = nodedirect.setdisc
local setreplace            = nodedirect.setreplace
local getid                 = nodedirect.getid
local getfont               = nodedirect.getfont
local getchar               = nodedirect.getchar
local getlist               = nodedirect.getlist
local getdisc               = nodedirect.getdisc
local getsubtype            = nodedirect.getsubtype
local getnext               = nodedirect.getnext
local nodetail              = nodedirect.tail
local getattribute          = nodedirect.has_attribute
local setattribute          = nodedirect.set_attribute

local call_callback         = luatexbase.call_callback

local stringformat          = string.format
local identifiers           = fonts.hashes.identifiers

local add_color_callback --[[ this used to be a global‽ ]]

local custom_setcolor, custom_settransparent

--[[doc--
Color string parser.
--doc]]--

local lpeg           = require"lpeg"
local lpegmatch      = lpeg.match
local C, Cc, P, R, S = lpeg.C, lpeg.Cc, lpeg.P, lpeg.R, lpeg.S

local spaces         = S"\t "^0
local digit16        = R("09", "af", "AF")
local opaque         = S("fF") * S("fF")
local octet          = digit16 * digit16 / function(s)
    return tonumber(s, 16) / 255
end

local function lpeg_repeat(patt, count)
    patt = P(patt)
    local result = patt
    for i = 2, count do
        result = result * patt
    end
    return result
end

local split_color     = spaces * C(lpeg_repeat(digit16, 6)) * (opaque + C(lpeg_repeat(digit16, 2)))^-1 * spaces * -1
                      + spaces * (C((spaces * (1 - S', ')^1)^1) + Cc(nil)) * spaces * (',' * spaces * C((spaces * (1 - S' ,')^1)^1)^-1 * spaces)^-1 * -1

luatexbase.create_callback('luaotfload.split_color', 'exclusive', function(value)
    local rgb, a = lpegmatch(split_color, value)
    if not rgb and not a then
        logreport("both", 0, "color",
                  "%q is not a valid rgb[a] color expression",
                  digits)
    end
    return rgb, a
end)

local extract_color  = octet * octet * octet / function(r,g,b)
                         return stringformat("%.3g %.3g %.3g rg", r, g, b)
                       end * -1
luatexbase.create_callback('luaotfload.parse_color', 'exclusive', function(value)
    local rgb = lpegmatch(extract_color, value)
    if not rgb then
        logreport("both", 0, "color",
                  "Invalid color part in color expression %q",
                  value)
    end
    return rgb
end)

-- Keep the currently collected page resources needed for the current
-- colors in `res`.

local res = nil

--- float -> unit
local function pageresources(alpha)
    res = res or {true} -- Initialize with /TransGs1
    local f = res[alpha]
        or stringformat("/TransGs%.3g gs", alpha, alpha)
    res[alpha] = f
    return f
end

local extract_transparent = octet * -1
luatexbase.create_callback('luaotfload.parse_transparent', 'exclusive', function(value)
    local a
    if type(value) == 'string' then
        a = lpegmatch(extract_transparent, value)
        if not a then
            logreport("both", 0, "color",
                      "Invalid transparency part in color expression %q",
                      value)
        end
    else
        a = value
    end
    if a then
        a = pageresources(a)
    end
    return a
end)


--- string -> (string | nil)
local function sanitize_color_expression (digits)
    digits = tostring(digits)
    local rgb, a = call_callback('luaotfload.split_color', digits)
    if rgb then
        rgb = call_callback('luaotfload.parse_color', rgb)
    end
    if a then
        a = call_callback('luaotfload.parse_transparent', a)
    end
    return rgb, a
end

local color_stack = 0
-- Beside maybe allowing {transpareny} package compatibility at some
-- point, this ensures that the stack is only created if it is actually
-- needed. Especially important because it adds /TransGs1 gs to every page
local function transparent_stack()
    -- if token.is_defined'TRP@colorstack' then -- transparency
        -- transparent_stack = tonumber(token.get_macro'TRP@colorstack')
    -- else
        transparent_stack = pdf.newcolorstack("/TransGs1 gs","direct",true)
    -- end
    return transparent_stack
end

--- Luatex internal types

local nodetype          = node.id
local glyph_t           = nodetype("glyph")
local hlist_t           = nodetype("hlist")
local vlist_t           = nodetype("vlist")
local whatsit_t         = nodetype("whatsit")
local disc_t            = nodetype("disc")
local colorstack_t      = node.subtype("pdf_colorstack")

local color_callback
local color_attr        = luatexbase.new_attribute("luaotfload_color_attribute")

-- Pass nil for new_color or old_color to indicate no color
-- If color is nil, pass tail to decide where to add whatsit
local function color_whatsit (head, curr, stack, old_color, new_color, tail)
    if new_color == old_color then
        return head, curr, old_color
    end
    local colornode = newnode(whatsit_t, colorstack_t)
    setfield(colornode, "stack", tonumber(stack) or stack())
    setfield(colornode, "command", new_color and (old_color and 0 or 1) or 2) -- 1: push, 2: pop
    setfield(colornode, "data", new_color) -- Is nil for pop
    if tail then
        head, curr = insert_node_after (head, curr, colornode)
    else
        head = insert_node_before(head, curr, colornode)
    end
    return head, curr, new_color
end

-- number -> string | nil
local function get_glyph_color (font_id, char)
    local tfmdata    = identifiers[font_id]
    local properties = tfmdata and tfmdata.properties
    local font_color = properties and properties.color_rgb
    local font_transparent = properties and properties.color_a
    if type(font_color) == "table" then
        local char_tbl = tfmdata.characters[char]
        char = char_tbl and (char_tbl.index or char)
        font_color = char and font_color[char] or font_color.default
        font_transparent = font_transparent and (char and font_transparent[char] or font_transparent.default)
    end
    return font_color, font_transparent
end

--[[doc--
While the second argument and second returned value are apparently
always nil when the function is called, they temporarily take string
values during the node list traversal.
--doc]]--

--- (node * (string | nil)) -> (node * (string | nil))
local function node_colorize (head, toplevel, current_color, current_transparent)
    local n = head
    while n do
        local n_id = getid(n)

        if n_id == hlist_t or n_id == vlist_t then
            local n_list = getlist(n)
            if getattribute(n_list, color_attr) then
                head, n, current_color = color_whatsit(head, n, color_stack, current_color, nil)
                head, n, current_transparent = color_whatsit(head, n, transparent_stack, current_transparent, nil)
            else
                n_list, current_color, current_transparent = node_colorize(n_list, false, current_color, current_transparent)
                if getsubtype(n) == 1 then -- created by linebreak
                    local nn = nodetail(n_list)
                    n_list, nn, current_color = color_whatsit(n_list, nn, color_stack, current_color, nil, true)
                    n_list, nn, current_transparent = color_whatsit(n_list, nn, transparent_stack, current_transparent, nil, true)
                end
                setfield(n, "head", n_list)
            end

        elseif n_id == disc_t then
            local n_pre, n_post, n_replace = getdisc(n)
            n_replace, current_color, current_transparent = node_colorize(n_replace, false, current_color, current_transparent)
            setdisc(n, n_pre, n_post, n_replace)

        elseif n_id == glyph_t then
            --- colorization is restricted to those fonts
            --- that received the “color” property upon
            --- loading (see ``setcolor()`` above)
            local glyph_color, glyph_transparent = get_glyph_color(getfont(n), getchar(n))
            if custom_setcolor then
                if glyph_color then
                    head, n = custom_setcolor(head, n, glyph_color) -- Don't change current_color to transform all other color_whatsit calls into noops
                end
            else
                head, n, current_color = color_whatsit(head, n, color_stack, current_color, glyph_color)
            end
            if custom_settransparent then
                if glyph_transparent then
                    head, n = custom_settransparent(head, n, glyph_transparent) -- Don't change current_transparent to transform all other color_whatsit calls into noops
                end
            else
                head, n, current_transparent = color_whatsit(head, n, transparent_stack, current_transparent, glyph_transparent)
            end

        elseif n_id == whatsit_t then
            head, n, current_color = color_whatsit(head, n, color_stack, current_color, nil)
            head, n, current_transparent = color_whatsit(head, n, transparent_stack, current_transparent, nil)

        end

        n = getnext(n)
    end

    if toplevel then
        local nn = nodetail(head)
        head, nn, current_color = color_whatsit(head, nn, color_stack, current_color, nil, true)
        head, nn, current_transparent = color_whatsit(head, nn, transparent_stack, current_transparent, nil, true)
    end

    setattribute(head, color_attr, 1)
    return head, current_color, current_transparent
end

local getpageres = pdf.getpageresources or function() return pdf.pageresources end
local setpageres = pdf.setpageresources or function(s) pdf.pageresources = s end
local catat11    = luatexbase.registernumber("catcodetable@atletter")
local gettoks, scantoks = tex.gettoks, tex.scantoks
local pgf = { bye = "pgfutil@everybye", extgs = "\\pgf@sys@addpdfresource@extgs@plain" }

--- node -> node
local function color_handler (head)
    head = todirect(head)
    head = node_colorize(head, true)
    head = tonode(head)

    -- now append our page resources
    if res and tonumber(transparent_stack) then
        if scantoks and nil == pgf.loaded then
            pgf.loaded = token.create(pgf.bye).cmdname == "assign_toks"
        end
        local tpr = pgf.loaded                 and gettoks(pgf.bye) or -- PGF
                    -- token.is_defined'TRP@list' and token.get_macro'TRP@list' or -- transparency
                                                   getpageres() or ""

        local t   = ""
        for k in pairs(res) do
            local str = stringformat("/TransGs%.3g<</ca %.3g>>", k, k) -- don't touch stroking elements
            if not tpr:find(str) then
                t = t .. str
            end
        end
        if t ~= "" then
            if pgf.loaded then
                scantoks("global", pgf.bye, catat11, stringformat("%s{%s}%s", pgf.extgs, t, tpr))
            -- elseif token.is_defined'TRP@list' then
            --     token.set_macro('TRP@list', t .. tpr, 'global')
            else
                local tpr, n = tpr:gsub("/ExtGState<<", "%1"..t)
                if n == 0 then
                    tpr = stringformat("%s/ExtGState<<%s>>", tpr, t)
                end
                setpageres(tpr)
            end
        end
        res = nil -- reset res
    end
    return head
end

local color_callback_name      = "luaotfload.color_handler"
local color_callback_activated = 0
local add_to_callback          = luatexbase.add_to_callback

--- unit -> unit
add_color_callback = function ( )
    color_callback = config.luaotfload.run.color_callback
    if not color_callback then
        color_callback = "post_linebreak_filter"
    end

    if color_callback_activated == 0 then
        add_to_callback(color_callback,
                        color_handler,
                        color_callback_name)
        add_to_callback("hpack_filter",
                        function (head, groupcode)
                            if  groupcode == "hbox"          or
                                groupcode == "adjusted_hbox" or
                                groupcode == "align_set"     then
                                head = color_handler(head)
                            end
                            return head
                        end,
                        color_callback_name)
        add_to_callback("post_mlist_to_hlist_filter",
                        function (head, display_type)
                            if display_type == "text" then
                                return head
                            end
                            return color_handler(head)
                        end,
                        color_callback_name)
        color_callback_activated = 1
    end
end

--[[doc--
``setcolor`` modifies tfmdata.properties.color in place
--doc]]--

--- fontobj -> string -> unit
---
---         (where “string” is a rgb value as three octet
---         hexadecimal, with an optional fourth transparency
---         value)
---
local glyph_color_tables = { }
-- Currently this either sets a common color for the whole font or
-- builds a GID lookup table. This might change later to replace the
-- lookup table with color information in the character hash. The
-- problem with that approach right now are differences between harf
-- and node and difficulties with getting the mapped unicode value for
-- a GID.
local function setcolor (tfmdata, value)
    local sanitized_rgb, sanitized_a
    local color_table = glyph_color_tables[tonumber(value) or value]
    if color_table then
        sanitized_rgb = {}
        local unicodes = tfmdata.resources.unicodes
        local gid_mapping = {}
        local descriptions = tfmdata.descriptions or tfmdata.characters
        for color, glyphs in next, color_table do
            for _, glyph in ipairs(glyphs) do
                local gid = glyph == "default" and "default" or tonumber(glyph)
                if not gid then
                    local unicode = unicodes[glyph]
                    local desc = unicode and descriptions[unicode]
                    gid = desc and (desc.index or unicode)
                end
                if gid then
                    local a
                    sanitized_rgb[gid], a
                        = sanitize_color_expression(color)
                    if a then
                        sanitized_a = sanitized_a or {}
                        sanitized_a[gid] = a
                    end
                else
                    -- TODO: ??? Error out, warn or just ignore? Ignore
                    -- makes sense because we have to ignore for GIDs
                    -- anyway.
                end
            end
        end
    else
        sanitized_rgb, sanitized_a = sanitize_color_expression(value)
    end
    local properties = tfmdata.properties

    if sanitized_rgb then
        properties.color_rgb, properties.color_a = sanitized_rgb, sanitized_a
        add_color_callback()
    end
end

function luaotfload.add_colorscheme(name, colortable)
  if fonts == nil then
    fonts = name
    name = #glyph_color_tables + 1
  else
    name = name:lower()
  end
  glyph_color_tables[name] = colortable
  return name
end

-- cb must have the signature
-- head, n = cb(head, n, color)
-- and apply the PDF color operators in color to the node n.
-- Call with nil to disable.
function luaotfload.set_colorhandler(cb)
  custom_setcolor = cb
end
function luaotfload.set_transparenthandler(cb)
  custom_settransparent = cb
end
function luaotfload.set_transparent_colorstack(stack)
  if type(transparent_stack) == 'number' then
    tex.error"luaotfload's transparency stack can't be changed after it has been used"
  else
    local t = type(stack)
    if t == 'function' or t == 'number' then
      function transparent_stack()
        if t == 'function' then
          transparent_stack = stack()
        else
          transparent_stack = stack
        end
        return transparent_stack
      end
    else
      tex.error("Invalid argument in luaotfload.set_transparent_colorstack")
    end
  end
end

setmetatable(fonts.handlers.otf.statistics.usedfeatures.color, {
  __index = function(t, k)
    t[k] = k
    return k
  end,
})

return function ()
    assert(logreport == luaotfload.log.report)
    logreport = luaotfload.log.report
    if not fonts then
        logreport ("log", 0, "color",
                   "OTF mechanisms missing -- did you forget to \z
                   load a font loader?")
        return false
    end
    fonts.handlers.otf.features.register {
        name        = "color",
        description = "color",
        initializers = {
            base = setcolor,
            node = setcolor,
            plug = setcolor,
        }
    }
    return true
end

-- vim:tw=71:sw=4:ts=4:expandtab

