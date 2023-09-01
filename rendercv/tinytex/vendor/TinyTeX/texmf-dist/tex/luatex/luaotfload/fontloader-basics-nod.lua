if not modules then modules = { } end modules ['luatex-fonts-nod'] = {
    version   = 1.001,
    comment   = "companion to luatex-fonts.lua",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

if context then
    os.exit()
end

-- Don't depend on code here as it is only needed to complement the font handler
-- code. I will move some to another namespace as I don't see other macro packages
-- use the context logic. It's a subset anyway. More will be stripped.

-- Attributes:

if tex.attribute[0] ~= 0 then

    texio.write_nl("log","!")
    texio.write_nl("log","! Attribute 0 is reserved for ConTeXt's font feature management and has to be")
    texio.write_nl("log","! set to zero. Also, some attributes in the range 1-255 are used for special")
    texio.write_nl("log","! purposes so setting them at the TeX end might break the font handler.")
    texio.write_nl("log","!")

    tex.attribute[0] = 0 -- else no features

end

attributes            = attributes or { }
attributes.unsetvalue = -0x7FFFFFFF

local numbers, last = { }, 127

attributes.private = attributes.private or function(name)
    local number = numbers[name]
    if not number then
        if last < 255 then
            last = last + 1
        end
        number = last
        numbers[name] = number
    end
    return number
end

-- Nodes (a subset of context so that we don't get too much unused code):

nodes              = { }
nodes.handlers     = { }

local nodecodes    = { }
local glyphcodes   = node.subtypes("glyph")
local disccodes    = node.subtypes("disc")

for k, v in next, node.types() do
    v = string.gsub(v,"_","")
    nodecodes[k] = v
    nodecodes[v] = k
end
for k, v in next, glyphcodes do
    glyphcodes[v] = k
end
for k, v in next, disccodes do
    disccodes[v] = k
end

nodes.nodecodes  = nodecodes
nodes.glyphcodes = glyphcodes
nodes.disccodes  = disccodes
nodes.dirvalues  = { lefttoright = 0, righttoleft = 1 }

nodes.handlers.protectglyphs   = node.protectglyphs   or node.protect_glyphs   -- beware: nodes!
nodes.handlers.unprotectglyphs = node.unprotectglyphs or node.unprotect_glyphs -- beware: nodes!

-- in generic code, at least for some time, we stay nodes, while in context
-- we can go nuts (e.g. experimental); this split permits us us keep code
-- used elsewhere stable but at the same time play around in context

-- much of this will go away .. it's part of the context interface and not
-- officially in luatex-*.lua

local direct       = node.direct
local nuts         = { }
nodes.nuts         = nuts

local tonode       = direct.tonode
local tonut        = direct.todirect

nodes.tonode       = tonode
nodes.tonut        = tonut

nuts.tonode        = tonode
nuts.tonut         = tonut

nuts.getattr       = direct.get_attribute
nuts.getboth       = direct.getboth
nuts.getchar       = direct.getchar
nuts.getdirection  = direct.getdirection
nuts.getdisc       = direct.getdisc
nuts.getreplace    = direct.getreplace
nuts.getfield      = direct.getfield
nuts.getfont       = direct.getfont
nuts.getid         = direct.getid
nuts.getkern       = direct.getkern
nuts.getlist       = direct.getlist
nuts.getnext       = direct.getnext
nuts.getoffsets    = direct.getoffsets
nuts.getoptions    = direct.getoptions or function() return 0 end
nuts.getprev       = direct.getprev
nuts.getsubtype    = direct.getsubtype
nuts.getwidth      = direct.getwidth
nuts.setattr       = direct.setfield
nuts.setboth       = direct.setboth
nuts.setchar       = direct.setchar
nuts.setcomponents = direct.setcomponents
nuts.setdirection  = direct.setdirection
nuts.setdisc       = direct.setdisc
nuts.setreplace    = direct.setreplace
nuts.setfield      = direct.setfield
nuts.setkern       = direct.setkern
nuts.setlink       = direct.setlink
nuts.setlist       = direct.setlist
nuts.setnext       = direct.setnext
nuts.setoffsets    = direct.setoffsets
nuts.setprev       = direct.setprev
nuts.setsplit      = direct.setsplit
nuts.setsubtype    = direct.setsubtype
nuts.setwidth      = direct.setwidth

nuts.getglyphdata  = nuts.getattribute    or nuts.getattr
nuts.setglyphdata  = nuts.setattribute    or nuts.setattr

nuts.ischar        = direct.ischar        or direct.is_char
nuts.isglyph       = direct.isglyph       or direct.is_glyph
nuts.copy          = direct.copy
nuts.copynode      = direct.copy
nuts.copylist      = direct.copylist      or direct.copy_list
nuts.endofmath     = direct.endofmath     or direct.end_of_math
nuts.flush         = direct.flush
nuts.flushlist     = direct.flushlist     or direct.flush_list
nuts.flushnode     = direct.flushnode     or direct.flush_node
nuts.free          = direct.free
nuts.insertafter   = direct.insertafter   or direct.insert_after
nuts.insertbefore  = direct.insertbefore  or direct.insert_before
nuts.isnode        = direct.isnode        or direct.is_node
nuts.isdirect      = direct.isdirect      or direct.is_direct
nuts.isnut         = direct.isdirect      or direct.is_direct
nuts.kerning       = direct.kerning
nuts.ligaturing    = direct.ligaturing
nuts.new           = direct.new
nuts.remove        = direct.remove
nuts.tail          = direct.tail
nuts.traverse      = direct.traverse
nuts.traversechar  = direct.traversechar  or direct.traverse_char
nuts.traverseglyph = direct.traverseglyph or direct.traverse_glyph
nuts.traverseid    = direct.traverseid    or direct.traverse_id

-- properties as used in the (new) injector:

local propertydata = (direct.getpropertiestable or direct.get_properties_table)()
nodes.properties   = { data = propertydata }

if direct.set_properties_mode then
    direct.set_properties_mode(true,true)
    function direct.set_properties_mode() end
end

nuts.getprop = function(n,k)
    local p = propertydata[n]
    if p then
        return p[k]
    end
end

nuts.setprop = function(n,k,v)
    if v then
        local p = propertydata[n]
        if p then
            p[k] = v
        else
            propertydata[n] = { [k] = v }
        end
    end
end

nodes.setprop = nodes.setproperty
nodes.getprop = nodes.getproperty

-- a few helpers (we need to keep 'm in sync with context) .. some day components
-- might go so here we isolate them

local setprev       = nuts.setprev
local setnext       = nuts.setnext
local getnext       = nuts.getnext
local setlink       = nuts.setlink
local getfield      = nuts.getfield
local setfield      = nuts.setfield
local getsubtype    = nuts.getsubtype
local isglyph       = nuts.isglyph
local find_tail     = nuts.tail
local flushlist     = nuts.flushlist
local flushnode     = nuts.flushnode
local traverseid    = nuts.traverseid
local copynode      = nuts.copynode

local glyph_code    = nodes.nodecodes.glyph
local ligature_code = nodes.glyphcodes.ligature

do -- this is consistent with the rest of context, not that we need it

    local p = nodecodes.localpar or nodecodes.local_par

    if p then
        nodecodes.par = p
        nodecodes[p] = "par"
        nodecodes.localpar  = p -- for old times sake
        nodecodes.local_par = p -- for old times sake
    end

end

do

    local getcomponents = node.direct.getcomponents
    local setcomponents = node.direct.setcomponents

    local function copynocomponents(g,copyinjection)
        local components = getcomponents(g)
        if components then
            setcomponents(g)
            local n = copynode(g)
            if copyinjection then
                copyinjection(n,g)
            end
            setcomponents(g,components)
            -- maybe also upgrade the subtype but we don't use it anyway
            return n
        else
            local n = copynode(g)
            if copyinjection then
                copyinjection(n,g)
            end
            return n
        end
    end

    local function copyonlyglyphs(current)
        local head     = nil
        local previous = nil
        for n in traverseid(glyph_code,current) do
            n = copynode(n)
            if head then
                setlink(previous,n)
            else
                head = n
            end
            previous = n
        end
        return head
    end

    local function countcomponents(start,marks)
        local char = isglyph(start)
        if char then
            if getsubtype(start) == ligature_code then
                local n = 0
                local components = getcomponents(start)
                while components do
                    n = n + countcomponents(components,marks)
                    components = getnext(components)
                end
                return n
            elseif not marks[char] then
                return 1
            end
        end
        return 0
    end

    local function flushcomponents()
        -- this is a no-op in mkiv / generic
    end

    nuts.components = {
        set              = setcomponents,
        get              = getcomponents,
        copyonlyglyphs   = copyonlyglyphs,
        copynocomponents = copynocomponents,
        count            = countcomponents,
        flush            = flushcomponents,
    }

end

nuts.usesfont = direct.usesfont or direct.uses_font

do

    -- another poor mans substitute ... i will move these to a more protected
    -- namespace .. experimental hack

    local dummy = tonut(node.new("glyph"))

    nuts.traversers = {
        glyph    = nuts.traverseid(nodecodes.glyph,dummy),
        glue     = nuts.traverseid(nodecodes.glue,dummy),
        disc     = nuts.traverseid(nodecodes.disc,dummy),
        boundary = nuts.traverseid(nodecodes.boundary,dummy),

        char     = nuts.traversechar(dummy),

        node     = nuts.traverse(dummy),
    }

end

if not nuts.setreplace then

    local getdisc  = nuts.getdisc
    local setfield = nuts.setfield

    function nuts.getreplace(n)
        local _, _, h, _, _, t = getdisc(n,true)
        return h, t
    end

    function nuts.setreplace(n,h)
        setfield(n,"replace",h)
    end

end

do

    local getsubtype = nuts.getsubtype

    function nuts.startofpar(n)
        local s = getsubtype(n)
        return s == 0 or s == 2 -- sorry, hardcoded, won't change anyway
    end

end
