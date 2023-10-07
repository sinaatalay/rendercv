if not modules then modules = { } end modules ['font-imp-italics'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv and hand-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local next, tonumber = next, tonumber

local fonts              = fonts
local handlers           = fonts.handlers
local registerotffeature = handlers.otf.features.register
local registerafmfeature = handlers.afm.features.register

-- This is a precursor to what we do in lmtx now via tweaks but at some point I
-- might make this a mkiv features too using staircase kerns.

-- local function initialize(tfmdata,key,value)
--     local factor = tonumber(value) or 1
--     for unicode, character in next, tfmdata.characters do
--         local olditalic = character.italic
--         if olditalic and olditalic ~= 0 then
--             character.width       = character.width + olditalic
--             character.italic      = 0
--             character.bottomright = -factor * olditalic -- lmtx only
--         end
--     end
-- end
--
-- local specification = {
--     name        = "italicwidths",
--     description = "add italic to width",
--     manipulators = {
--         base = initialize,
--         node = initialize, -- only makes sense for math
--     }
-- }
--
-- registerotffeature(specification)
-- registerafmfeature(specification)

local function initialize(tfmdata,value) -- hm, always value
    if value then
        -- the magic 40 and it formula come from Dohyun Kim but we might need another guess
        local parameters = tfmdata.parameters
        local italicangle = parameters.italicangle
        if italicangle and italicangle ~= 0 then
            local properties = tfmdata.properties
            local factor = tonumber(value) or 1
            properties.hasitalics = true
            properties.autoitalicamount = factor * (parameters.uwidth or 40)/2
        end
    end
end

local specification = {
    name         = "itlc",
    description  = "italic correction",
    initializers = {
        base = initialize,
        node = initialize,
    }
}

registerotffeature(specification)
registerafmfeature(specification)

if context then

    local function initialize(tfmdata,value) -- yes no delay
        tfmdata.properties.textitalics = toboolean(value)
    end

    local specification = {
        name         = "textitalics",
        description  = "use alternative text italic correction",
        initializers = {
            base = initialize,
            node = initialize,
        }
    }

    registerotffeature(specification)
    registerafmfeature(specification)

    -- only used when testing

    local letter = characters.is_letter
    local always = true

    local function collapseitalics(tfmdata,key,value)
        local threshold = value == true and 100 or tonumber(value)
        if threshold and threshold > 0 then
            if threshold > 100 then
                threshold = 100
            end
            for unicode, data in next, tfmdata.characters do
                if always or letter[unicode] or letter[data.unicode] then
                    local italic = data.italic
                    if italic and italic ~= 0 then
                        local width = data.width
                        if width and width ~= 0 then
                            local delta = threshold * italic / 100
                            data.width  = width  + delta
                            data.italic = italic - delta
                        end
                    end
                end
            end
        end
    end

    local dimensions_specification = {
        name        = "collapseitalics",
        description = "collapse italics",
        manipulators = {
            base = collapseitalics,
            node = collapseitalics,
        }
    }

    registerotffeature(dimensions_specification)
    registerafmfeature(dimensions_specification)

end
