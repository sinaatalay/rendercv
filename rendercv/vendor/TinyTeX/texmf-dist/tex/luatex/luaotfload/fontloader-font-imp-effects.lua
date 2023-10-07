if not modules then modules = { } end modules ['font-imp-effects'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- todo: pickup from goodies: if type(effect) then ...

local next, type, tonumber = next, type, tonumber
local is_boolean = string.is_boolean

local fonts              = fonts

local handlers           = fonts.handlers
local registerotffeature = handlers.otf.features.register
local registerafmfeature = handlers.afm.features.register

local settings_to_hash   = utilities.parsers.settings_to_hash_colon_too

local helpers            = fonts.helpers
local prependcommands    = helpers.prependcommands
local charcommand        = helpers.commands.char
local leftcommand        = helpers.commands.left
local rightcommand       = helpers.commands.right
local upcommand          = helpers.commands.up
local downcommand        = helpers.commands.down
local dummycommand       = helpers.commands.dummy

----- constructors       = fonts.constructors
----- getmathparameter   = constructors.getmathparameter
----- setmathparameter   = constructors.setmathparameter

local report_effect      = logs.reporter("fonts","effect")
local report_slant       = logs.reporter("fonts","slant")
local report_extend      = logs.reporter("fonts","extend")
local report_squeeze     = logs.reporter("fonts","squeeze")

local trace              = false

trackers.register("fonts.effect", function(v) trace = v end)
trackers.register("fonts.slant",  function(v) trace = v end)
trackers.register("fonts.extend", function(v) trace = v end)
trackers.register("fonts.squeeze",function(v) trace = v end)

local function initializeslant(tfmdata,value)
    value = tonumber(value)
    if not value then
        value =  0
    elseif value >  1 then
        value =  1
    elseif value < -1 then
        value = -1
    end
    if trace then
        report_slant("applying %0.3f",value)
    end
    tfmdata.parameters.slantfactor = value
end

local specification = {
    name        = "slant",
    description = "slant glyphs",
    initializers = {
        base = initializeslant,
        node = initializeslant,
    }
}

registerotffeature(specification)
registerafmfeature(specification)

local function initializeextend(tfmdata,value)
    value = tonumber(value)
    if not value then
        value =  0
    elseif value >  10 then
        value =  10
    elseif value < -10 then
        value = -10
    end
    if trace then
        report_extend("applying %0.3f",value)
    end
    tfmdata.parameters.extendfactor = value
end

local specification = {
    name        = "extend",
    description = "scale glyphs horizontally",
    initializers = {
        base = initializeextend,
        node = initializeextend,
    }
}

registerotffeature(specification)
registerafmfeature(specification)

local function initializesqueeze(tfmdata,value)
    value = tonumber(value)
    if not value then
        value =  0
    elseif value >  10 then
        value =  10
    elseif value < -10 then
        value = -10
    end
    if trace then
        report_squeeze("applying %0.3f",value)
    end
    tfmdata.parameters.squeezefactor = value
end

local specification = {
    name        = "squeeze",
    description = "scale glyphs vertically",
    initializers = {
        base = initializesqueeze,
        node = initializesqueeze,
    }
}

registerotffeature(specification)
registerafmfeature(specification)

local effects = {
    inner   = 0,
    normal  = 0,
    outer   = 1,
    outline = 1,
    both    = 2,
    hidden  = 3,
}

local function initializeeffect(tfmdata,value)
    local spec
    if type(value) == "number" then
        spec = { width = value }
    else
        spec = settings_to_hash(value)
    end
    local effect = spec.effect or "both"
    local width  = tonumber(spec.width) or 0
    local mode   = effects[effect]
    if not mode then
        report_effect("invalid effect %a",effect)
    elseif width == 0 and mode == 0 then
        report_effect("invalid width %a for effect %a",width,effect)
    else
        local parameters = tfmdata.parameters
        local properties = tfmdata.properties
        parameters.mode  = mode
        parameters.width = width * 1000
        if is_boolean(spec.auto) == true then
            local squeeze = 1 - width/20
            local average = (1 - squeeze) * width * 100
            spec.squeeze  = squeeze
            spec.extend   = 1 + width/2
            spec.wdelta   = average
            spec.hdelta   = average/2
            spec.ddelta   = average/2
            spec.vshift   = average/2
        end
        local factor  = tonumber(spec.factor)  or 0
        local hfactor = tonumber(spec.hfactor) or factor
        local vfactor = tonumber(spec.vfactor) or factor
        local delta   = tonumber(spec.delta)   or 1
        local wdelta  = tonumber(spec.wdelta)  or delta
        local hdelta  = tonumber(spec.hdelta)  or delta
        local ddelta  = tonumber(spec.ddelta)  or hdelta
        local vshift  = tonumber(spec.vshift)  or 0
        local slant   = spec.slant
        local extend  = spec.extend
        local squeeze = spec.squeeze
        if slant then
            initializeslant(tfmdata,slant)
        end
        if extend then
            initializeextend(tfmdata,extend)
        end
        if squeeze then
            initializesqueeze(tfmdata,squeeze)
        end
        properties.effect = {
            effect  = effect,
            width   = width,
            factor  = factor,
            hfactor = hfactor,
            vfactor = vfactor,
            wdelta  = wdelta,
            hdelta  = hdelta,
            ddelta  = ddelta,
            vshift  = vshift,
            slant   = tfmdata.parameters.slantfactor,
            extend  = tfmdata.parameters.extendfactor,
            squeeze = tfmdata.parameters.squeezefactor,
        }
    end
end

local rules = {
    "RadicalRuleThickness",
    "OverbarRuleThickness",
    "FractionRuleThickness",
    "UnderbarRuleThickness",
}

-- radicals are not yet ok

local function setmathparameters(tfmdata,characters,mathparameters,dx,dy,squeeze,multiplier)
    -- hm, this was "if delta ~= 0 then" but delta was gone
    if dy ~= 0 then
        for i=1,#rules do
            local name  = rules[i]
            local value = mathparameters[name]
            if value then
               mathparameters[name] = (squeeze or 1) * (value + dy)
            end
        end
    end
end

local function setmathcharacters(tfmdata,characters,mathparameters,dx,dy,squeeze,wdelta,hdelta,ddelta)

    -- still not the perfect rule

    local function wdpatch(char)
        if wsnap ~= 0 then
            char.width  = char.width + wdelta/2
        end
    end

    local function htpatch(char)
        if hsnap ~= 0 then
            local height = char.height
            if height then
                char.height = char.height + 2 * dy
            end
        end
    end

    local character = characters[0x221A]

    if character and character.next then
        local char = character
        local next = character.next
        wdpatch(char)
        htpatch(char)
        while next do
            char = characters[next]
            wdpatch(char)
            htpatch(char)
            next = char.next
        end
        if char then
            local v = char.vert_variants
            if v then
                local top = v[#v]
                if top then
                    local char = characters[top.glyph]
                    htpatch(char)
                end
            end
        end
    end

end

-- local show_effect = { "lua", function(f,c)
--     report_effect("font id %i, char %C",f,c)
--     inspect(fonts.hashes.characters[f][c])
-- end }

local function manipulateeffect(tfmdata)
    local effect = tfmdata.properties.effect
    if effect then
        local characters     = tfmdata.characters
        local parameters     = tfmdata.parameters
        local mathparameters = tfmdata.mathparameters
        local multiplier     = effect.width * 100
        local factor         = parameters.factor
        local hfactor        = parameters.hfactor
        local vfactor        = parameters.vfactor
        local wdelta         = effect.wdelta * hfactor * multiplier
        local hdelta         = effect.hdelta * vfactor * multiplier
        local ddelta         = effect.ddelta * vfactor * multiplier
        local vshift         = effect.vshift * vfactor * multiplier
        local squeeze        = effect.squeeze
        local hshift         = wdelta / 2
        local dx             = multiplier * vfactor
        local dy             = vshift
        local factor         = (1 + effect.factor)  * factor
        local hfactor        = (1 + effect.hfactor) * hfactor
        local vfactor        = (1 + effect.vfactor) * vfactor
        vshift = vshift ~= 0 and upcommand[vshift] or false
        hshift = rightcommand[hshift]
        for unicode, character in next, characters do
            local oldwidth  = character.width
            local oldheight = character.height
            local olddepth  = character.depth
            if oldwidth and oldwidth > 0 then
                character.width = oldwidth + wdelta
                local commands = character.commands
                if vshift then
                    if commands then
                        prependcommands ( commands,
                         -- show_effect,
                            hshift,
                            vshift
                        )
                    else
                        character.commands = {
                         -- show_effect,
                            hshift,
                            vshift,
                            charcommand[unicode]
                        }
                    end
                else
                    if commands then
                      prependcommands ( commands,
                       -- show_effect,
                          hshift
                      )
                    else
                        character.commands = {
                         -- show_effect,
                            hshift,
                            charcommand[unicode]
                      }
                    end
                end
            end
            if oldheight and oldheight > 0 then
               character.height = oldheight + hdelta
            end
            if olddepth and olddepth > 0 then
               character.depth = olddepth + ddelta
            end
        end
        if mathparameters then
            setmathparameters(tfmdata,characters,mathparameters,dx,dy,squeeze,multiplier)
            setmathcharacters(tfmdata,characters,mathparameters,dx,dy,squeeze,wdelta,hdelta,ddelta)
        end
        parameters.factor  = factor
        parameters.hfactor = hfactor
        parameters.vfactor = vfactor
        if trace then
            report_effect("applying")
            report_effect("  effect  : %s", effect.effect)
            report_effect("  width   : %s => %s", effect.width,  multiplier)
            report_effect("  factor  : %s => %s", effect.factor, factor )
            report_effect("  hfactor : %s => %s", effect.hfactor,hfactor)
            report_effect("  vfactor : %s => %s", effect.vfactor,vfactor)
            report_effect("  wdelta  : %s => %s", effect.wdelta, wdelta)
            report_effect("  hdelta  : %s => %s", effect.hdelta, hdelta)
            report_effect("  ddelta  : %s => %s", effect.ddelta, ddelta)
        end
    end
end

local specification = {
    name        = "effect",
    description = "apply effects to glyphs",
    initializers = {
        base = initializeeffect,
        node = initializeeffect,
    },
    manipulators = {
        base = manipulateeffect,
        node = manipulateeffect,
    },
}

registerotffeature(specification)
registerafmfeature(specification)

local function initializeoutline(tfmdata,value)
    value = tonumber(value)
    if not value then
        value = 0
    else
        value = tonumber(value) or 0
    end
    local parameters = tfmdata.parameters
    local properties = tfmdata.properties
    parameters.mode  = effects.outline
    parameters.width = value * 1000
    properties.effect = {
        effect = effect,
        width  = width,
    }
end

local specification = {
    name        = "outline",
    description = "outline glyphs",
    initializers = {
        base = initializeoutline,
        node = initializeoutline,
    }
}

registerotffeature(specification)
registerafmfeature(specification)
