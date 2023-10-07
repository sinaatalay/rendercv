if not modules then modules = { } end modules ['font-ini'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- Not much is happening here.

local allocate    = utilities.storage.allocate
local sortedhash  = table.sortedhash

fonts             = fonts or { }
local fonts       = fonts

local identifiers = allocate()

fonts.hashes      = fonts.hashes     or { identifiers = identifiers }
fonts.tables      = fonts.tables     or { }
fonts.helpers     = fonts.helpers    or { }
fonts.tracers     = fonts.tracers    or { } -- for the moment till we have move to moduledata
fonts.specifiers  = fonts.specifiers or { } -- in format !

fonts.analyzers   = { } -- not needed here
fonts.readers     = { }
fonts.definers    = { methods = { } }
fonts.loggers     = { register = function() end }

if context then

    font.originaleach = font.each

    function font.each()
        return sortedhash(identifiers)
    end

    fontloader = nil

end

-- Outside context one can bump textbase to some higher value but only the
-- textbase given here is officially supported (read: bug testing etc will
-- use the values below).

fonts.privateoffsets = {
    textbase      = 0xF0000, -- used for hidden (opentype features)
    textextrabase = 0xFD000, -- used for visible by name
    mathextrabase = 0xFE000, -- used for visible by code
    mathbase      = 0xFF000, -- used for hidden (virtual math)
    keepnames     = false,   -- when set to true names are always kept (not for context)
}

if node and not tex.getfontoffamily then
    tex.getfontoffamily = node.family_font -- we moved this
end
