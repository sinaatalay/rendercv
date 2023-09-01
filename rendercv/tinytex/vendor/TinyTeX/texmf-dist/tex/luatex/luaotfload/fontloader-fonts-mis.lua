if not modules then modules = { } end modules ['luatex-font-mis'] = {
    version   = 1.001,
    comment   = "companion to luatex-*.tex",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

if context then
    os.exit()
end

local currentfont  = font.current

local hashes       = fonts.hashes
local identifiers  = hashes.identifiers or { }
local marks        = hashes.marks       or { }

hashes.identifiers = identifiers
hashes.marks       = marks

table.setmetatableindex(marks,function(t,k)
    if k == true then
        return marks[currentfont()]
    else
        local resources = identifiers[k].resources or { }
        local marks = resources.marks or { }
        t[k] = marks
        return marks
    end
end)

function font.each()
    return table.sortedhash(fonts.hashes.identifiers)
end
