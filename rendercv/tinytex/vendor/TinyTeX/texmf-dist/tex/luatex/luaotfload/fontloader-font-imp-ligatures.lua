if not modules then modules = { } end modules ['font-imp-ligatures'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local lpegmatch = lpeg.match
local utfsplit = utf.split
local settings_to_array = utilities.parsers.settings_to_array

local fonts              = fonts
local otf                = fonts.handlers.otf
local registerotffeature = otf.features.register
local addotffeature      = otf.addfeature

-- This is a quick and dirty hack.

local lookups = { }
local protect = { }
local revert  = { }
local zwjchar = 0x200C
local zwj     = { zwjchar }

addotffeature {
    name    = "blockligatures",
    type    = "chainsubstitution",
    nocheck = true, -- because there is no 0x200C in the font
    prepend = true, -- make sure we do it early
    future  = true, -- avoid nilling due to no steps yet
    lookups = {
        {
            type = "multiple",
            data = lookups,
        },
    },
    data = {
        rules = protect,
    }
}

addotffeature {
    name     = "blockligatures",
    type     = "chainsubstitution",
    nocheck  = true,  -- because there is no 0x200C in the font
    append   = true,  -- this is done late
    overload = false, -- we don't want to overload the previous definition
    lookups  = {
        {
            type = "ligature",
            data = lookups,
        },
    },
    data = {
        rules = revert,
    }
}

registerotffeature {
    name        = 'blockligatures',
    description = 'block certain ligatures',
}

local splitter = lpeg.splitat(":")

local function blockligatures(str)

    local t = settings_to_array(str)

    for i=1,#t do
        local ti = t[i]
        local before, current, after = lpegmatch(splitter,ti)
        if current and after then -- before is returned when no match
            -- experimental joke
            if before then
                before = utfsplit(before)
                for i=1,#before do
                    before[i] = { before[i] }
                end
            end
            if current then
                current = utfsplit(current)
            end
            if after then
                after = utfsplit(after)
                for i=1,#after do
                    after[i] = { after[i] }
                end
            end
        else
            before  = nil
            current = utfsplit(ti)
            after   = nil
        end
        if #current > 1 then
            local one = current[1]
            local two = current[2]
            lookups[one] = { one, zwjchar }
            local one = { one }
            local two = { two }
            local new = #protect + 1
            protect[new] = {
                before  = before,
                current = { one, two },
                after   = after,
                lookups = { 1, false }, -- not shared !
            }
            revert[new] = {
             -- before = before,
                current = { one, zwj },
             -- after   = { two, unpack(after) },
                after   = { two },
                lookups = { 1, false }, -- not shared !
            }
        end
    end
end

-- blockligatures("\0\0")

otf.helpers.blockligatures = blockligatures

-- blockligatures("fi,ff")
-- blockligatures("fl")
-- blockligatures("u:fl:age")

if context then

    interfaces.implement {
        name      = "blockligatures",
        arguments = "string",
        actions   = blockligatures,
    }

end
