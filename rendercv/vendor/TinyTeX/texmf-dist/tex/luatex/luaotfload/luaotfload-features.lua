-----------------------------------------------------------------------
--         FILE:  luaotfload-features.lua
--  DESCRIPTION:  part of luaotfload / font features
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-features",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / features",
    license       = "GPL v2.0",
    author        = "Hans Hagen, Khaled Hosny, Elie Roux, Philipp Gesang, Marcel Krüger",
    copyright     = "PRAGMA ADE / ConTeXt Development Team",
}

local type              = type
local next              = next
local tonumber          = tonumber

local lpeg              = require "lpeg"
local lpegmatch         = lpeg.match
local P                 = lpeg.P
local R                 = lpeg.R
local S                 = lpeg.S
local C                 = lpeg.C

local lower             = string.lower

local table             = table
local tabletohash       = table.tohash
local tablesort         = table.sort

--- this appears to be based in part on luatex-fonts-def.lua

local fonts             = fonts
local definers          = fonts.definers
local handlers          = fonts.handlers
local fontidentifiers   = fonts.hashes and fonts.hashes.identifiers
local otf               = handlers.otf

local config            = config or { luaotfload = { run = { } } }

local as_script         = config.luaotfload.run.live
local normalize

if as_script then
    function normalize(features)
        return {
            axis = features and features.axis,
            instance = features and features.instance,
        }
    end
else
    normalize = otf.features.normalize
end

local log              = luaotfload.log
local report           = log.report

local stringgsub       = string.gsub
local stringformat     = string.format
local stringis_empty   = string.is_empty

local function cmp_by_idx (a, b) return a.idx < b.idx end

local defined_combos = 0

local function handle_combination (combo, spec, size)
    defined_combos = defined_combos + 1
    if not combo [1] then
        report ("both", 0, "features",
                "combo %d: Empty font combination requested.",
                defined_combos)
        return false
    end

    if not fontidentifiers then
        fontidentifiers = fonts.hashes and fonts.hashes.identifiers
    end

    local chain   = { }
    local fontids = { }
    local n       = #combo

    tablesort (combo, cmp_by_idx)

    --- pass 1: skim combo and resolve fonts
    report ("both", 2, "features", "combo %d: combining %d fonts.",
            defined_combos, n)
    for i = 1, n do
        local cur = combo [i]
        local id  = cur.id
        local idx = cur.idx
        local fnt = fontidentifiers [id]
        if fnt then
            local chars = cur.chars
            if chars == true then
                report ("both", 2, "features",
                        " *> %.2d: fallback font %d at rank %d.",
                        i, id, idx)
            else
                report ("both", 2, "features",
                        " *> %.2d: include font %d at rank %d (%d items).",
                        i, id, idx, (chars and #chars or 0))
            end
            chain   [#chain + 1]   = { fnt, chars, idx = idx }
            fontids [#fontids + 1] = { id = id }
        else
            report ("both", 0, "features",
                    " *> %.2d: font %d at rank %d unknown, skipping.",
                    n, id, idx)
            --- TODO might instead attempt to define the font at this point
            ---      but that’d require some modifications to the syntax
        end
    end

    local nc = #chain
    if nc == 0 then
        report ("both", 0, "features",
                " *> no valid font (of %d) in combination.", n)
        return false
    end

    local basefnt = chain [1] [1]
    if nc == 1 then
        report ("both", 0, "features",
                " *> combination boils down to a single font (%s) \z
                 of %d initially specified; not pursuing this any \z
                 further.", basefnt.fullname, n)
        return basefnt
    end

    local basechar       = basefnt.characters
    local baseprop       = basefnt.properties
    baseprop.name        = spec
    baseprop.virtualized = true
    basefnt.fonts        = fontids

    for i = 2, nc do
        local cur = chain [i]
        local fnt = cur [1]
        local def = cur [2]
        local src = fnt.characters
        local cnt = 0

        local function pickchr (uc, unavailable)
            local chr = src [uc]
            if unavailable == true and basechar [uc] then
                --- fallback mode: already known
                return
            end
            if chr then
                chr.commands = { { "slot", i, uc } }
                basechar [uc] = chr
                cnt = cnt + 1
            end
        end

        if def == true then --> fallback; grab all currently unavailable
            for uc, _chr in next, src do pickchr (uc, true) end
        else --> grab only defined range
            for j = 1, #def do
                local this = def [j]
                if type (this) == "number" then
                    report ("both", 2, "features",
                            " *> [%d][%d]: import codepoint U+%.4X",
                            i, j, this)
                    pickchr (this)
                elseif type (this) == "table" then
                    local lo, hi = unpack (this)
                    report ("both", 2, "features",
                            " *> [%d][%d]: import codepoint range U+%.4X--U+%.4X",
                            i, j, lo, hi)
                    for uc = lo, hi do pickchr (uc) end
                else
                    report ("both", 0, "features",
                            " *> item no. %d of combination definition \z
                             %d not processable.", j, i)
                end
            end
        end
        report ("both", 2, "features",
                " *> font %d / %d: imported %d glyphs into combo.",
                i, nc, cnt)
    end
    return {
        lookup        = "combo",
        file          = basefnt.filename,
        name          = stringformat ("luaotfload<%d>", defined_combos),
        specification = spec,
        features      = { normal = { } },
        forced        = "evl",
        eval          = function () return basefnt end,
        size          = size,
    }
end

---[[ begin excerpt from font-ott.lua ]]

local function swapped (h)
    local r = { }
    for k, v in next, h do
        r[stringgsub(v,"[^a-z0-9]","")] = k -- is already lower
    end
    return r
end

local tables           = otf.tables
local scripts          = tables.scripts
local languages        = tables.languages
local verbosescripts   = swapped(scripts  )
local verboselanguages = swapped(languages)

---[[ end excerpt from font-ott.lua ]]

--[[doc--

    As discussed, we will issue a warning because of incomplete support
    when one of the scripts below is requested.

    Reference: https://github.com/lualatex/luaotfload/issues/31

--doc]]--

local support_incomplete = tabletohash({
   -- "deva", 
    "beng", "guru", "gujr",
    "orya", "taml", "telu", "knda",
    "mlym", "sinh",
}, true)

--[[doc--

    Which features are active by default depends on the script
    requested.

--doc]]--

--- (string, string) dict -> (string, string) dict
local function apply_default_features (rawlist)
    local speclist = {}
    for k, v in pairs(rawlist) do
        if type(v) == 'string' then
            v = ({['true'] = true, ['false'] = false})[lower(v)] or v
        end
        speclist[k] = v
    end
    local default_features = luaotfload.features

    speclist = speclist or { }
    speclist[""] = nil --- invalid options stub

    --- handle language tag
    local language = speclist.language
    if language then
        language = stringgsub(lower(language), "[^a-z0-9]", "")
        language = rawget(verboselanguages, language) -- srsly, rawget?
                or (languages[language] and language)
                or "dflt"
    else
        language = "dflt"
    end
    speclist.language = language

    --- handle script tag
    local script = speclist.script
    if script then
        script = stringgsub(lower(script), "[^a-z0-9]","")
        script = rawget(verbosescripts, script)
              or (scripts[script] and script)
              or "dflt"
        if support_incomplete[script] then
            report("log", 0, "features",
                "Support for the requested script: "
                .. "%q may be incomplete.", script)
        end
    else
        script = "dflt"
    end
    speclist.script = script

    report("log", 2, "features",
        "Auto-selecting default features for script: %s.",
        script)

    local requested = default_features.defaults[script]
    if not requested then
        report("log", 2, "features",
            "No default features for script %q, falling back to \"dflt\".",
            script)
        requested = default_features.defaults.dflt
    end

    for feat, state in next, requested do
        if speclist[feat] == nil then speclist[feat] = state end
    end

    for feat, state in next, default_features.global do
        --- This is primarily intended for setting node
        --- mode unless “base” is requested, as stated
        --- in the manual.
        if speclist[feat] == nil then speclist[feat] = state end
    end
    return speclist
end

local import_values = {
    --- That’s what the 1.x parser did, not quite as graciously,
    --- with an array of branch expressions.
    -- "style", "optsize",--> from slashed notation; handled otherwise
    { "lookup", false },
    { "sub",    false },
}

local supported = {
    b    = "b",
    i    = "i",
    bi   = "bi",
    r    = "r",
    aat  = false,
    icu  = false,
    gr   = false,
}

--- (string | (string * string) | bool) list -> (string * number)
local function handle_slashed (modifiers)
    local style, optsize
    for i=1, #modifiers do
        local mod  = modifiers[i]
        if type(mod) == "table" and mod[1] == "optsize" then --> optical size
            optsize = tonumber(mod[2])
        elseif mod == false then
            --- ignore
            report("log", 0, "features", "unsupported font option: %s", v)
        elseif supported[mod] then
            style = supported[mod]
        elseif not stringis_empty(mod) then
            style = stringgsub(mod, "[^%a%d]", "")
        end
    end
    return style, optsize
end

local extract_subfont
do
    local eof         = P(-1)
    --- Theoretically a valid subfont address can be up to ten
    --- digits long. Additionally we allow names
    local sub_expr    = P"(" * C((1 - S"()")^1) * P")" * eof
    local full_path   = C(P(1 - sub_expr)^1)
    extract_subfont   = full_path * sub_expr
end

local function analyze(spec_string, size)
    local request = lpegmatch(luaotfload.parsers.font_request,
                              spec_string)
----inspect(request)
    if not request then
        --- happens when called with an absolute path
        --- in an anonymous lookup;
        --- we try to behave as friendly as possible
        --- just go with it ...
        report("log", 1, "features", "invalid request %q of type anon",
               spec_string)
        report("log", 1, "features",
               "use square bracket syntax or consult the documentation.")
        --- The result of \fontname must be re-feedable into \font
        --- which is expected by the Latex font mechanism. Now this
        --- is complicated with TTC fonts that need to pass the
        --- number of the requested subfont along with the file name.
        --- Thus we test whether the request is a bare path only or
        --- ends in a subfont expression (decimal digits inside
        --- parentheses).
        --- https://github.com/lualatex/luaotfload/issues/57
        local fullpath, sub = lpegmatch(extract_subfont,
                                        spec_string)
        if fullpath and sub then
            return {
                lookup = 'path',
                sub = tonumber(sub) or sub,
                name = fullpath,
                size = size,
            }
        else
            return {
                lookup = 'path',
                name = spec_string,
                size = size,
            }
        end
    end

    local lookup, name = request.lookup, request.name
    if lookup == "combo" then
        return handle_combination (name, spec_string, size)
    end

    local features = {
        raw = request.features or {}
    }

    local specification = {
        specification = spec_string,
        size = size,
        lookup = lookup,
        name = name,
        sub = request.sub or false,
        features = features,
    }

    if lookup == 'id' then
        local original_font = fontidentifiers [request.id]
        if not original_font then return end
        local original_spec = original_font.specification
        if not original_spec then return end
        if size < 0 then
            specification.size = original_spec.size * size // -1000
        end
        specification.lookup = original_spec.lookup
        specification.name = original_spec.name
        specification.sub = specification.sub or original_spec.sub
        specification.style = original_spec.style
        specification.optsize = original_spec.optsize
        specification.forced = original_spec.forced
        if original_spec.features then
            features.raw = table.merged(original_spec.features.raw, features.raw)
        end
    end

    local processed_features = apply_default_features(features.raw)

    if request.modifiers then
        local style, optsize = handle_slashed(request.modifiers)
        specification.style, specification.optsize = style, optsize
    end

    for n=1, #import_values do
        local feat       = import_values[n][1]
        local keep       = import_values[n][2]
        local newvalue   = processed_features[feat]
        if newvalue then
            specification[feat] = newvalue
            if not keep then
                processed_features[feat] = nil
            end
        end
    end

    --- The next line sets the “rand” feature to “random”; I haven’t
    --- investigated it any further (luatex-fonts-ext), so it will
    --- just stay here.
    features.normal = normalize (processed_features)
    if features.normal.instance then
        if features.normal.axis then
            report("term and log", 0, "features", "instance and axis provided, instance will be ignored")
        else
            specification.instance = features.normal.instance
        end
    end

    local forced_mode = request.features and request.features.mode
    if forced_mode then
        forced_mode = lower(forced_mode)
        if fonts.readers[forced_mode] then
            specification.forced = forced_mode
        end
    end

    return specification
end

fonts.definers.analyze = analyze

if as_script == true then --- skip the remainder of the file
    report ("log", 5, "features",
            "Exiting early from luaotfload-features.lua.")
    return
end

do
    local helpers = otf.readers.helpers
    local axistofactors = helpers.axistofactors
    local cleanname = helpers.cleanname
    local getaxisscale = helpers.getaxisscale
    local function search(table, term, key_field, value_field)
        if not table then return end
        term = cleanname(term)
        for i=1, #table do
            local entry = table[i]
            if cleanname(entry[key_field]) == term then
                return entry[value_field]
            end
        end
    end
    function helpers.getfactors(tfmdata, instance) -- `instance` might refer to an `axis` value here
        assert(instance == true or type(instance) == "string", "Fontloader changed interface of helpers.getfactors. This is a bug, please notify the luaotfload maintainers.")
        local variabledata = tfmdata.variabledata
        if not variabledata then return end
        local instances = variabledata.instances
        local axis = variabledata.axis
        local designaxis = variabledata.designaxis
        local segments = variabledata.segments
        if not axis then return end
        local factors = {}
        if instance == true then
            for i=1, #axis do
                local cur = axis[i]
                local default = cur.default
                factors[i] = getaxisscale(segments, cur.minimum, default, cur.maximum, default)
            end
            return factors
        end
        local values = search(instances, instance, "subfamily", "values")
        if values then
            for i=1, #axis do
                local cur = axis[i]
                factors[i] = getaxisscale(segments, cur.minimum, cur.default, cur.maximum, values[i].value)
            end
            return factors
        end
        values = axistofactors(instance)
        for i=1, #axis do
            local cur = axis[i]
            local default = cur.default
            local value = cur.name and values[cur.name] or values[cur.tag]
            value = tonumber(value) or (value and search(search(designaxis, cur.tag, "tag", "variants"), cleanname(value), "name", "value")) or default
            factors[i] = getaxisscale(segments, cur.minimum, default, cur.maximum, value)
        end
        return factors
    end

    -- Additionally we patch trytosharefont to ensure that variable fonts work
    -- with default values whenever no explicit values are passed.
    local original_trytosharefont = fonts.constructors.trytosharefont
    function fonts.constructors.trytosharefont(target, tfmdata)
        original_trytosharefont(target, tfmdata)
        if not target.streamprovider and tfmdata.resources.variabledata then
            local format = tfmdata.properties.format
            target.streamprovider = format == 'opentype' and 1 or format == 'truetype' and 2 or 0
        end
    end
end

-- We assume that the other otf stuff is loaded already; though there’s
-- another check below during the initialization phase.


local tlig_specification = {
    {
        type      = "substitution",
        features  = everywhere,
        data      = {
            --- quotedblright:
            --- " (QUOTATION MARK)   → ” (RIGHT DOUBLE QUOTATION MARK)
            [0x0022] = 0x201D,

            --- quoteleft:
            --- ' (APOSTROPHE)       → ’ (RIGHT SINGLE QUOTATION MARK)
            [0x0027] = 0x2019,

            --- quoteright:
            --- ` (GRAVE ACCENT)     → ‘ (LEFT SINGLE QUOTATION MARK)
            [0x0060] = 0x2018,
        },
        flags     = noflags,
        order     = { "tlig" },
        prepend   = true,
    },
    {
        type     = "ligature",
        features = everywhere,
        data     = {

            --- endash:
            --- [--] (HYPHEN-MINUS, HYPHEN-MINUS)                   → – (EN DASH)
            [0x2013] = {0x002D, 0x002D},

            --- emdash:
            --- [---] (HYPHEN-MINUS, HYPHEN-MINUS, HYPHEN-MINUS)    → — (EM DASH)
            [0x2014] = {0x002D, 0x002D, 0x002D},

            --- quotedblleft:
            --- [''] (GRAVE ACCENT, GRAVE ACCENT)                   → “ (LEFT DOUBLE QUOTATION MARK)
            [0x201C] = {0x0060, 0x0060},

            --- quotedblright:
            --- [``] (APOSTROPHE, APOSTROPHE)                       → ” (RIGHT DOUBLE QUOTATION MARK)
            [0x201D] = {0x0027, 0x0027},

            --- exclamdown:
            --- [!'] (EXCLAMATION MARK, GRAVE ACCENT)               → ¡ (INVERTED EXCLAMATION MARK)
            [0x00A1] = {0x0021, 0x0060},

            --- questiondown:
            --- [?'] (QUESTION MARK, GRAVE ACCENT)                  → ¡ (INVERTED EXCLAMATION MARK)
            [0x00BF] = {0x003F, 0x0060},

            --- next three originate in T1 encoding (Xetex applies them too)
            --- quotedblbase:
            --- [,,] (COMMA, COMMA)                                 → ¡ (DOUBLE LOW-9 QUOTATION MARK)
            [0x201E] = {0x002C, 0x002C},

            --- LEFT-POINTING DOUBLE ANGLE QUOTATION MARK:
            --- [,,] (LESS-THAN SIGN, LESS-THAN SIGN)               → ¡ (LEFT-POINTING ANGLE QUOTATION MARK)
            [0x00AB] = {0x003C, 0x003C},

            --- RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK:
            --- [,,] (GREATER-THAN SIGN, GREATER-THAN SIGN)         → ¡ (RIGHT-POINTING DOUBLE ANGLE QUOTATION MARK)
            [0x00BB] = {0x003E, 0x003E},
        },
        flags    = noflags,
        order    = { "tlig" },
        prepend  = true,
    },
}

-- "substitution" features allow to replace individual characters with other
-- characters. This is often used inside of fonts to e.g. implement stylistic
-- sets.
-- As an example how such features can be added in the fontloader, we have a
-- simple implementation of the ROT13 cipher as a font feature. It can be
-- used by enabling the `rot13` font feature in a font, but we are not aware of
-- any practical usecase for this.
local rot13_specification = {
    type      = "substitution",
    features  = everywhere,
    data      = {
        [65] = 78, [ 97] = 110, [78] = 65, [110] =  97,
        [66] = 79, [ 98] = 111, [79] = 66, [111] =  98,
        [67] = 80, [ 99] = 112, [80] = 67, [112] =  99,
        [68] = 81, [100] = 113, [81] = 68, [113] = 100,
        [69] = 82, [101] = 114, [82] = 69, [114] = 101,
        [70] = 83, [102] = 115, [83] = 70, [115] = 102,
        [71] = 84, [103] = 116, [84] = 71, [116] = 103,
        [72] = 85, [104] = 117, [85] = 72, [117] = 104,
        [73] = 86, [105] = 118, [86] = 73, [118] = 105,
        [74] = 87, [106] = 119, [87] = 74, [119] = 106,
        [75] = 88, [107] = 120, [88] = 75, [120] = 107,
        [76] = 89, [108] = 121, [89] = 76, [121] = 108,
        [77] = 90, [109] = 122, [90] = 77, [122] = 109,
    },
    flags     = noflags,
    order     = { "rot13" },
    prepend   = true,
}

local interrolig_specification = {
    { type     = "ligature", data = { [0x203d] = {0x21, 0x3f}, [0x2e18] = {0xa1, 0xbf}, }, },
    { type     = "ligature", data = { [0x203d] = {0x3f, 0x21}, [0x2e18] = {0xbf, 0xa1}, }, },
}

local autofeatures = {
    --- always present with Luaotfload; anum for Arabic and Persian is
    --- predefined in font-otc.
    { "tlig" , tlig_specification , "tex ligatures and substitutions" },
    { "rot13", rot13_specification, "rot13"                           },
    { "!!??",  interrolig_specification, "interrobang substitutions"  },
}

local function add_auto_features ()
    local nfeats = #autofeatures
    report ("both", 5, "features",
            "auto-installing %d feature definitions", nfeats)
    for i = 1, nfeats do
        local name, spec, desc = unpack (autofeatures [i])
        spec.description = desc
        otf.addfeature (name, spec)
    end
end

luaotfload.apply_default_features = apply_default_features

do
    local function mathparaminitializer(tfmdata, value, features)
        if not next(tfmdata.mathparameters) then return end
        if value == 'auto' then
            if features.script == 'math' then return end
        end
        tfmdata.mathparameters = {}
    end
    fonts.constructors.features.otf.register {
        name = 'nomathparam',
        description = 'Set Math parameters based on this font',
        default = 'auto',
        initializers = {
            base = mathparaminitializer,
            node = mathparaminitializer,
          -- plug = mathparaminitializer,
        },
    }
end

do
    local function mathfontdimen(tfmdata, _, value)
        if not (tfmdata.mathparameters and next(tfmdata.mathparameters)) then return end
        local parameters = tfmdata.parameters
        local mathparameters = tfmdata.mathparameters
        if value == 'xetex' then
            parameters[10] = mathparameters.ScriptPercentScaleDown
            parameters[11] = mathparameters.ScriptScriptPercentScaleDown
            parameters[12] = mathparameters.DelimitedSubFormulaMinHeight
            parameters[13] = mathparameters.DisplayOperatorMinHeight
            parameters[14] = mathparameters.MathLeading
            parameters[15] = mathparameters.AxisHeight
            parameters[16] = mathparameters.AccentBaseHeight
            parameters[17] = mathparameters.FlattenedAccentBaseHeight
            parameters[18] = mathparameters.SubscriptShiftDown
            parameters[19] = mathparameters.SubscriptTopMax
            parameters[20] = mathparameters.SubscriptBaselineDropMin
            parameters[21] = mathparameters.SuperscriptShiftUp
            parameters[22] = mathparameters.SuperscriptShiftUpCramped
            parameters[23] = mathparameters.SuperscriptBottomMin
            parameters[24] = mathparameters.SuperscriptBaselineDropMax
            parameters[25] = mathparameters.SubSuperscriptGapMin
            parameters[26] = mathparameters.SuperscriptBottomMaxWithSubscript
            parameters[27] = mathparameters.SpaceAfterScript
            parameters[28] = mathparameters.UpperLimitGapMin
            parameters[29] = mathparameters.UpperLimitBaselineRiseMin
            parameters[30] = mathparameters.LowerLimitGapMin
            parameters[31] = mathparameters.LowerLimitBaselineDropMin
            parameters[32] = mathparameters.StackTopShiftUp
            parameters[33] = mathparameters.StackTopDisplayStyleShiftUp
            parameters[34] = mathparameters.StackBottomShiftDown
            parameters[35] = mathparameters.StackBottomDisplayStyleShiftDown
            parameters[36] = mathparameters.StackGapMin
            parameters[37] = mathparameters.StackDisplayStyleGapMin
            parameters[38] = mathparameters.StretchStackTopShiftUp
            parameters[39] = mathparameters.StretchStackBottomShiftDown
            parameters[40] = mathparameters.StretchStackGapAboveMin
            parameters[41] = mathparameters.StretchStackGapBelowMin
            parameters[42] = mathparameters.FractionNumeratorShiftUp
            parameters[43] = mathparameters.FractionNumeratorDisplayStyleShiftUp
            parameters[44] = mathparameters.FractionDenominatorShiftDown
            parameters[45] = mathparameters.FractionDenominatorDisplayStyleShiftDown
            parameters[46] = mathparameters.FractionNumeratorGapMin
            parameters[47] = mathparameters.FractionNumeratorDisplayStyleGapMin
            parameters[48] = mathparameters.FractionRuleThickness
            parameters[49] = mathparameters.FractionDenominatorGapMin
            parameters[50] = mathparameters.FractionDenominatorDisplayStyleGapMin
            parameters[51] = mathparameters.SkewedFractionHorizontalGap
            parameters[52] = mathparameters.SkewedFractionVerticalGap
            parameters[53] = mathparameters.OverbarVerticalGap
            parameters[54] = mathparameters.OverbarRuleThickness
            parameters[55] = mathparameters.OverbarExtraAscender
            parameters[56] = mathparameters.UnderbarVerticalGap
            parameters[57] = mathparameters.UnderbarRuleThickness
            parameters[58] = mathparameters.UnderbarExtraDescender
            parameters[59] = mathparameters.RadicalVerticalGap
            parameters[60] = mathparameters.RadicalDisplayStyleVerticalGap
            parameters[61] = mathparameters.RadicalRuleThickness
            parameters[62] = mathparameters.RadicalExtraAscender
            parameters[63] = mathparameters.RadicalKernBeforeDegree
            parameters[64] = mathparameters.RadicalKernAfterDegree
            parameters[65] = mathparameters.RadicalDegreeBottomRaisePercent
            -- parameters[66] = mathparameters.MinConnectorOverlap
            -- parameters[67] = mathparameters.SubscriptShiftDownWithSuperscript
            -- parameters[68] = mathparameters.FractionDelimiterSize
            -- parameters[69] = mathparameters.FractionDelimiterDisplayStyleSize
            -- parameters[70] = mathparameters.NoLimitSubFactor
            -- parameters[71] = mathparameters.NoLimitSupFactor
        elseif value == 'tex2' then
            parameters[8] = mathparameters.FractionNumeratorDisplayStyleShiftUp
            parameters[9] = mathparameters.FractionNumeratorShiftUp
            parameters[10] = mathparameters.StackTopShiftUp
            parameters[11] = mathparameters.FractionDenominatorDisplayStyleShiftDown
            parameters[12] = mathparameters.FractionDenominatorShiftDown
            parameters[13] = mathparameters.SuperscriptShiftUp
            parameters[14] = mathparameters.SuperscriptShiftUp
            parameters[15] = mathparameters.SuperscriptShiftUpCramped
            parameters[16] = mathparameters.SubscriptShiftDown
            parameters[17] = mathparameters.SubscriptShiftDown
            parameters[18] = mathparameters.SuperscriptBaselineDropMax
            parameters[19] = mathparameters.SubscriptBaselineDropMin
            parameters[20] = mathparameters.FractionDelimiterDisplayStyleSize
            parameters[21] = mathparameters.FractionDelimiterSize
            parameters[22] = mathparameters.AxisHeight
        elseif value == 'tex3' then
            parameters[8] = mathparameters.Defa
            parameters[9] = mathparameters.UpperLimitGapMin
            parameters[10] = mathparameters.LowerLimitGapMin
            parameters[11] = mathparameters.UpperLimitBaselineRiseMin
            parameters[12] = mathparameters.LowerLimitBaselineDropMin
            parameters[13] = 0
        end
    end
    fonts.constructors.features.otf.register {
        name = 'mathfontdimen',
        description = 'Set fontdimen values for compatibility with other engines',
        manipulators = {
            base = mathfontdimen,
          -- node = mathfontdimen,
          -- plug = mathfontdimen,
        },
    }
end

do
    local function restore(tfmdata, value, features)
        if not tfmdata.properties.monospaced then return end
        if features.fixedspace then return end -- In this case, 'auto' is true
        local parameters = tfmdata.parameters
        local space = parameters.space
        parameters.space_stretch, parameters.space_shrink = space/2, space/3
    end
    fonts.constructors.features.otf.register {
        name = 'internal__variablespace',
        default = true,
        initializers = {
            base = restore,
            node = restore,
        },
    }
    local function node_fixedspace(tfmdata, value, features)
        if value == 'auto' then return end
        if tfmdata.properties.monospaced then return end -- handled by internal__variablespace
        local parameters = tfmdata.parameters
        parameters.space_stretch, parameters.space_shrink = 0, 0
    end
    local hb = luaotfload.harfbuzz
    local post_tag = hb and hb.Tag.new'post'
    local function harf_fixedspace(tfmdata, value, features)
        if value == 'auto' then
            -- We have to determine if we have a monospace font.
            -- Let's be honest, it would be boring if that were easy.
            local post_table = tfmdata.hb.shared.face:get_table(post_tag):get_data()
            if #post_table < 16 then
                -- Invalid OpenType font... Let's assume that it's not
                -- monospaced:
                return
            end
            local monospaced = string.unpack('>I4', post_table, 13) ~= 0
            if not monospaced then return end -- FIXME: How to determine?
        end
        local parameters = tfmdata.parameters
        parameters.space_stretch, parameters.space_shrink = 0, 0
    end
    fonts.constructors.features.otf.register {
        name = 'fixedspace',
        description = 'Do not stretch or shrink spaces',
        default = 'auto',
        initializers = {
            base = node_fixedspace,
            node = node_fixedspace,
            plug = harf_fixedspace,
        },
    }
end

local uni_normalize = require'lua-uni-normalize'.direct
local normalize_lookup = setmetatable({}, {__index = function(t, f)
    local fontdir = assert(font.getfont(f))
    local normalize_func = t[fontdir]
    local characters = fontdir.characters
    local function result(head)
        return normalize_func(head, f, characters, true)
    end
    t[f] = result
    return result
end})
-- When this is loaded as part of luaotfload-tool, then we can't access nodes
-- and therefore uni_normalize doesn't exists. In that case we don't need it
-- anyway, so just skip it then.
local normalize_funcs = uni_normalize and {
    nfc = uni_normalize.NFC,
    nfd = uni_normalize.NFD,
    nfkd = uni_normalize.NFKD,
}
fonts.constructors.features.otf.register {
    name = 'normalize',
    default = 'nfc',
    description = 'Normalize text to NFC before shaping',
    manipulators = {
        node = function(fonttable, _, value)
            if value == true then
                value = 'nfc'
            end
            local func = normalize_funcs[value]
            if not func then
                report ("report", 0, "features",
                        "Unsupported normalization method replaced by NFC")
                func = normalize_funcs.nfc
            end
            normalize_lookup[fonttable] = func
        end,
    },
    processors = {
      position = 1,
      node = function(head, f, _, _, _)
          return normalize_lookup[f](head)
      end,
    },
}

-- mathsize feature for compatibility with older fontloader versions
-- Not all that useful in most cases since it leads to messy font sizes,
-- especially reloading a font using this feature based on it's \fontname
-- will load a wrong size.
-- Only supported for base mode since the other modes don't make sense for
-- math fonts.
local calculatescale = fonts.constructors.calculatescale
function fonts.constructors.calculatescale(tfmdata, size, _, spec)
    local parameters = tfmdata.parameters
    local sizepercentage = parameters and parameters.sizepercentage
    if sizepercentage then
        size = size * sizepercentage / 100
    end
    return calculatescale(tfmdata, size, _, spec)
end

fonts.constructors.features.otf.register {
    name = 'mathsize',
    description = 'Scale math fonts based on their scriptpercentage parameters',
    initializers = {
        base = function(tfmdata, mathsize)
            local mathdata = tfmdata.shared.rawdata.metadata.math
            if not mathdata then return end

            if mathsize == 1 then
                tfmdata.parameters.sizepercentage = 100
            elseif mathsize == 2 then
                tfmdata.parameters.sizepercentage = mathdata.ScriptPercentScaleDown
            elseif mathsize == 3 then
                tfmdata.parameters.sizepercentage = mathdata.ScriptScriptPercentScaleDown
            end
        end,
    },
}

return function ()
    if not fonts and fonts.handlers then
        report ("log", 0, "features",
                "OTF mechanisms missing -- did you forget to \z
                load a font loader?")
        return false
    end
    add_auto_features ()
    return true
end
-- vim:tw=79:sw=4:ts=4:expandtab
