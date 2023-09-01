if not modules then modules = { } end modules ['font-imp-tex'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local next = next

local fonts              = fonts
local otf                = fonts.handlers.otf
local registerotffeature = otf.features.register
local addotffeature      = otf.addfeature

-- We provide a few old and obsolete compatibility input features. We need numbers
-- for some fonts so no names here. Do we also need them for afm fonts?

local tlig = {
    type     = "ligature",
    order    = { "tlig" },
    prepend  = true,
    data     = {
        [0x2013] = { 0x002D, 0x002D },
        [0x2014] = { 0x002D, 0x002D, 0x002D },
    },
}

local tquo = {
    type     = "ligature",
    order    = { "tquo" },
    prepend  = true,
    data     = {
        [0x201C] = { 0x0060, 0x0060 },
        [0x201D] = { 0x0027, 0x0027 },
        [0x201E] = { 0x002C, 0x002C },
    },
}

local trep = {
    type      = "substitution",
    order     = { "trep" },
    prepend   = true,
    data      = {
     -- [0x0022] = 0x201D,
        [0x0027] = 0x2019,
     -- [0x0060] = 0x2018,
    },
}

addotffeature("trep",trep) -- last
addotffeature("tlig",tlig)
addotffeature("tquo",tquo) -- first

registerotffeature { name = "tlig", description = "tex ligatures" }
registerotffeature { name = "tquo", description = "tex quotes" }
registerotffeature { name = "trep", description = "tex replacements" }

-- some day this will be moved to font-imp-scripts.lua

-- anum

local anum_arabic = {
    [0x0030] = 0x0660,
    [0x0031] = 0x0661,
    [0x0032] = 0x0662,
    [0x0033] = 0x0663,
    [0x0034] = 0x0664,
    [0x0035] = 0x0665,
    [0x0036] = 0x0666,
    [0x0037] = 0x0667,
    [0x0038] = 0x0668,
    [0x0039] = 0x0669,
}

local anum_persian = {
    [0x0030] = 0x06F0,
    [0x0031] = 0x06F1,
    [0x0032] = 0x06F2,
    [0x0033] = 0x06F3,
    [0x0034] = 0x06F4,
    [0x0035] = 0x06F5,
    [0x0036] = 0x06F6,
    [0x0037] = 0x06F7,
    [0x0038] = 0x06F8,
    [0x0039] = 0x06F9,
}

local function valid(data)
    local features = data.resources.features
    if features then
        for k, v in next, features do
            for k, v in next, v do
                if v.arab then
                    return true
                end
            end
        end
    end
end

local specification = {
    {
        type     = "substitution",
        features = { arab = { urd = true, dflt = true } },
        order    = { "anum" },
        data     = anum_arabic,
        valid    = valid,
    },
    {
        type     = "substitution",
        features = { arab = { urd = true } },
        order    = { "anum" },
        data     = anum_persian,
        valid    = valid,
    },
}

addotffeature("anum",specification)

registerotffeature {
    -- this makes it a known feature (in tables)
    name        = "anum",
    description = "arabic digits",
}

-- -- example:
--
-- fonts.handlers.otf.addfeature {
--     name     = "hangulfix",
--     type     = "substitution",
--     features = { ["hang"] = { ["*"] = true } },
--     data     = {
--         [0x1160] = 0x119E,
--     },
--     order    = { "hangulfix" },
--     flags    = { },
--     prepend  = true,
-- })
