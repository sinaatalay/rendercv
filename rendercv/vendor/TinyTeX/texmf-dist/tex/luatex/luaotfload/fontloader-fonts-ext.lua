if not modules then modules = { } end modules ['luatex-fonts-ext'] = {
    version   = 1.001,
    comment   = "companion to luatex-*.tex",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

if context then
    os.exit()
end

local byte = string.byte

local fonts              = fonts
local handlers           = fonts.handlers
local otf                = handlers.otf
local afm                = handlers.afm
local registerotffeature = otf.features.register
local registerafmfeature = afm.features.register

-- extra generic stuff

function fonts.loggers.onetimemessage() end

-- done elsewhere
--
-- loadmodule('font-ext-imp-italic.lua')
-- loadmodule('font-ext-imp-effect.lua')
-- loadmodule('luatex-fonts-lig.lua')

-- protrusion (simplified version)

fonts.protrusions        = fonts.protrusions        or { }
fonts.protrusions.setups = fonts.protrusions.setups or { }
local setups             = fonts.protrusions.setups

setups['default'] = { -- demo vector

    factor   = 1,
    left     = 1,
    right    = 1,

    [0x002C] = { 0, 1    }, -- comma
    [0x002E] = { 0, 1    }, -- period
    [0x003A] = { 0, 1    }, -- colon
    [0x003B] = { 0, 1    }, -- semicolon
    [0x002D] = { 0, 1    }, -- hyphen
    [0x2013] = { 0, 0.50 }, -- endash
    [0x2014] = { 0, 0.33 }, -- emdash
    [0x3001] = { 0, 1    }, -- ideographic comma      、
    [0x3002] = { 0, 1    }, -- ideographic full stop  。
    [0x060C] = { 0, 1    }, -- arabic comma           ،
    [0x061B] = { 0, 1    }, -- arabic semicolon       ؛
    [0x06D4] = { 0, 1    }, -- arabic full stop       ۔

}

local function initializeprotrusion(tfmdata,value)
    if value then
        local setup = setups[value]
        if setup then
            local factor, left, right = setup.factor or 1, setup.left or 1, setup.right or 1
            local emwidth = tfmdata.parameters.quad
            tfmdata.parameters.protrusion = {
                auto = true,
            }
            for i, chr in next, tfmdata.characters do
                local v, pl, pr = setup[i], nil, nil
                if v then
                    pl, pr = v[1], v[2]
                end
                if pl and pl ~= 0 then chr.left_protruding  = left *pl*factor end
                if pr and pr ~= 0 then chr.right_protruding = right*pr*factor end
            end
        end
    end
end

local specification = {
    name        = "protrusion",
    description = "shift characters into the left and or right margin",
    initializers = {
        base = initializeprotrusion,
        node = initializeprotrusion,
    }
}

registerotffeature(specification)
registerafmfeature(specification)

-- expansion (simplified version)

fonts.expansions        = fonts.expansions        or { }
fonts.expansions.setups = fonts.expansions.setups or { }
local setups            = fonts.expansions.setups

setups['default'] = { -- demo vector

    stretch     = 2,
    shrink      = 2,
    step        = .5,
    factor      = 1,

    [byte('A')] = 0.5, [byte('B')] = 0.7, [byte('C')] = 0.7, [byte('D')] = 0.5, [byte('E')] = 0.7,
    [byte('F')] = 0.7, [byte('G')] = 0.5, [byte('H')] = 0.7, [byte('K')] = 0.7, [byte('M')] = 0.7,
    [byte('N')] = 0.7, [byte('O')] = 0.5, [byte('P')] = 0.7, [byte('Q')] = 0.5, [byte('R')] = 0.7,
    [byte('S')] = 0.7, [byte('U')] = 0.7, [byte('W')] = 0.7, [byte('Z')] = 0.7,
    [byte('a')] = 0.7, [byte('b')] = 0.7, [byte('c')] = 0.7, [byte('d')] = 0.7, [byte('e')] = 0.7,
    [byte('g')] = 0.7, [byte('h')] = 0.7, [byte('k')] = 0.7, [byte('m')] = 0.7, [byte('n')] = 0.7,
    [byte('o')] = 0.7, [byte('p')] = 0.7, [byte('q')] = 0.7, [byte('s')] = 0.7, [byte('u')] = 0.7,
    [byte('w')] = 0.7, [byte('z')] = 0.7,
    [byte('2')] = 0.7, [byte('3')] = 0.7, [byte('6')] = 0.7, [byte('8')] = 0.7, [byte('9')] = 0.7,
}

local function initializeexpansion(tfmdata,value)
    if value then
        local setup = setups[value]
        if setup then
            local factor = setup.factor or 1
            tfmdata.parameters.expansion = {
                stretch = 10 * (setup.stretch or 0),
                shrink  = 10 * (setup.shrink  or 0),
                step    = 10 * (setup.step    or 0),
                auto    = true,
            }
            for i, chr in next, tfmdata.characters do
                local v = setup[i]
                if v and v ~= 0 then
                    chr.expansion_factor = v*factor
                else -- can be option
                    chr.expansion_factor = factor
                end
            end
        end
    end
end

local specification = {
    name        = "expansion",
    description = "apply hz optimization",
    initializers = {
        base = initializeexpansion,
        node = initializeexpansion,
    }
}

registerotffeature(specification)
registerafmfeature(specification)

-- normalizer (generic only)

if not otf.features.normalize then

    otf.features.normalize = function(t)
        if t.rand then
            t.rand = "random"
        end
        return t
    end

end

-- bonus

function fonts.helpers.nametoslot(name)
    local t = type(name)
    if t == "string" then
        local tfmdata = fonts.hashes.identifiers[currentfont()]
        local shared  = tfmdata and tfmdata.shared
        local fntdata = shared and shared.rawdata
        return fntdata and fntdata.resources.unicodes[name]
    elseif t == "number" then
        return n
    end
end

-- \font\test=file:somefont:reencode=mymessup
--
--  fonts.encodings.reencodings.mymessup = {
--      [109] = 110, -- m
--      [110] = 109, -- n
--  }

-- reencoding (generic only)

fonts.encodings             = fonts.encodings or { }
local reencodings           = { }
fonts.encodings.reencodings = reencodings

local function specialreencode(tfmdata,value)
    -- we forget about kerns as we assume symbols and we
    -- could issue a message if ther are kerns but it's
    -- a hack anyway so we odn't care too much here
    local encoding = value and reencodings[value]
    if encoding then
        local temp = { }
        local char = tfmdata.characters
        for k, v in next, encoding do
            temp[k] = char[v]
        end
        for k, v in next, temp do
            char[k] = temp[k]
        end
        -- if we use the font otherwise luatex gets confused so
        -- we return an additional hash component for fullname
        return string.format("reencoded:%s",value)
    end
end

local function initialize(tfmdata,value)
    tfmdata.postprocessors = tfmdata.postprocessors or { }
    table.insert(tfmdata.postprocessors,
        function(tfmdata)
            return specialreencode(tfmdata,value)
        end
    )
end

registerotffeature {
    name         = "reencode",
    description  = "reencode characters",
    manipulators = {
        base = initialize,
        node = initialize,
    }
}

-- math stuff (generic only)

local function initialize(tfmdata,key,value)
    if value then
        tfmdata.mathparameters = nil
    end
end

registerotffeature {
    name         = "ignoremathconstants",
    description  = "ignore math constants table",
    initializers = {
        base = initialize,
        node = initialize,
    }
}
