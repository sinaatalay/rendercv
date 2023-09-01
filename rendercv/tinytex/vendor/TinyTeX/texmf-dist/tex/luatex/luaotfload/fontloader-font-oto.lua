if not modules then modules = { } end modules ['font-oto'] = { -- original tex
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- Todo: Enable fixes from the lmt to here. Also in font-con.lua wrt the changed
-- assignments. (Around texlive 2024 in order not to disturb generic.)

local concat, unpack = table.concat, table.unpack
local insert, remove = table.insert, table.remove
local format, gmatch, gsub, find, match, lower, strip = string.format, string.gmatch, string.gsub, string.find, string.match, string.lower, string.strip
local type, next, tonumber, tostring = type, next, tonumber, tostring

local trace_baseinit         = false  trackers.register("otf.baseinit",     function(v) trace_baseinit     = v end)
local trace_singles          = false  trackers.register("otf.singles",      function(v) trace_singles      = v end)
local trace_multiples        = false  trackers.register("otf.multiples",    function(v) trace_multiples    = v end)
local trace_alternatives     = false  trackers.register("otf.alternatives", function(v) trace_alternatives = v end)
local trace_ligatures        = false  trackers.register("otf.ligatures",    function(v) trace_ligatures    = v end)
local trace_kerns            = false  trackers.register("otf.kerns",        function(v) trace_kerns        = v end)
local trace_preparing        = false  trackers.register("otf.preparing",    function(v) trace_preparing    = v end)

local report_prepare         = logs.reporter("fonts","otf prepare")

local fonts                  = fonts
local otf                    = fonts.handlers.otf

local otffeatures            = otf.features
local registerotffeature     = otffeatures.register

otf.defaultbasealternate     = "none" -- first last

local getprivate             = fonts.constructors.getprivate

local wildcard               = "*"
local default                = "dflt"

local formatters             = string.formatters
local f_unicode              = formatters["%U"]
local f_uniname              = formatters["%U (%s)"]
local f_unilist              = formatters["% t (% t)"]

local function gref(descriptions,n)
    if type(n) == "number" then
        local name = descriptions[n].name
        if name then
            return f_uniname(n,name)
        else
            return f_unicode(n)
        end
    elseif n then
        local num = { }
        local nam = { }
        local j   = 0
        for i=1,#n do
            local ni = n[i]
            if tonumber(ni) then -- first is likely a key
                j = j + 1
                local di = descriptions[ni]
                num[j] = f_unicode(ni)
                nam[j] = di and di.name or "-"
            end
        end
        return f_unilist(num,nam)
    else
        return "<error in base mode tracing>"
    end
end

local function cref(feature,sequence)
    return formatters["feature %a, type %a, (chain) lookup %a"](feature,sequence.type,sequence.name)
end

local function report_substitution(feature,sequence,descriptions,unicode,substitution)
    if unicode == substitution then
        report_prepare("%s: base substitution %s maps onto itself",
            cref(feature,sequence),
            gref(descriptions,unicode))
    else
        report_prepare("%s: base substitution %s => %S",
            cref(feature,sequence),
            gref(descriptions,unicode),
            gref(descriptions,substitution))
    end
end

local function report_alternate(feature,sequence,descriptions,unicode,replacement,value,comment)
    if unicode == replacement then
        report_prepare("%s: base alternate %s maps onto itself",
            cref(feature,sequence),
            gref(descriptions,unicode))
    else
        report_prepare("%s: base alternate %s => %s (%S => %S)",
            cref(feature,sequence),
            gref(descriptions,unicode),
            replacement and gref(descriptions,replacement),
            value,
            comment)
    end
end

local function report_ligature(feature,sequence,descriptions,unicode,ligature)
    report_prepare("%s: base ligature %s => %S",
        cref(feature,sequence),
        gref(descriptions,ligature),
        gref(descriptions,unicode))
end

local function report_kern(feature,sequence,descriptions,unicode,otherunicode,value)
    report_prepare("%s: base kern %s + %s => %S",
        cref(feature,sequence),
        gref(descriptions,unicode),
        gref(descriptions,otherunicode),
        value)
end

-- We need to make sure that luatex sees the difference between base fonts that have
-- different glyphs in the same slots in fonts that have the same fullname (or filename).
-- LuaTeX will merge fonts eventually (and subset later on). If needed we can use a more
-- verbose name as long as we don't use <()<>[]{}/%> and the length is < 128.

local basehash, basehashes, applied = { }, 1, { }

local function registerbasehash(tfmdata)
    local properties = tfmdata.properties
    local hash       = concat(applied," ")
    local base       = basehash[hash]
    if not base then
        basehashes     = basehashes + 1
        base           = basehashes
        basehash[hash] = base
    end
    properties.basehash = base
    properties.fullname = (properties.fullname or properties.name) .. "-" .. base
 -- report_prepare("fullname base hash '%a, featureset %a",tfmdata.properties.fullname,hash)
    applied = { }
end

local function registerbasefeature(feature,value)
    applied[#applied+1] = feature  .. "=" .. tostring(value)
end

-- The original basemode ligature builder used the names of components and did some expression
-- juggling to get the chain right. The current variant starts with unicodes but still uses
-- names to make the chain. This is needed because we have to create intermediates when needed
-- but use predefined snippets when available. To some extend the current builder is more stupid
-- but I don't worry that much about it as ligatures are rather predicatable.
--
-- Personally I think that an ff + i == ffi rule as used in for instance latin modern is pretty
-- weird as no sane person will key that in and expect a glyph for that ligature plus the following
-- character. Anyhow, as we need to deal with this, we do, but no guarantes are given.
--
--         latin modern       dejavu
--
-- f+f       102 102             102 102
-- f+i       102 105             102 105
-- f+l       102 108             102 108
-- f+f+i                         102 102 105
-- f+f+l     102 102 108         102 102 108
-- ff+i    64256 105           64256 105
-- ff+l                        64256 108
--
-- As you can see here, latin modern is less complete than dejavu but
-- in practice one will not notice it.
--
-- The while loop is needed because we need to resolve for instance pseudo names like
-- hyphen_hyphen to endash so in practice we end up with a bit too many definitions but the
-- overhead is neglectable. We can have changed[first] or changed[second] but it quickly becomes
-- messy if we need to take that into account.

local function makefake(tfmdata,name,present)
    local private   = getprivate(tfmdata)
    local character = { intermediate = true, ligatures = { } }
    tfmdata.resources.unicodes[name] = private
    tfmdata.characters[private] = character
    tfmdata.descriptions[private] = { name = name }
    present[name] = private
    return character
end

local function make_1(present,tree,name)
    if tonumber(tree) then
        present[name] = v
    else
        for k, v in next, tree do
            if k == "ligature" then
                present[name] = v
            else
                make_1(present,v,name .. "_" .. k)
            end
        end
    end
end

local function make_3(present,tfmdata,characters,tree,name,preceding,unicode,done,v)
    local character = characters[preceding]
    if not character then
        if trace_baseinit then
            report_prepare("weird ligature in lookup %a, current %C, preceding %C",sequence.name,v,preceding)
        end
        character = makefake(tfmdata,name,present)
    end
    local ligatures = character.ligatures
    if ligatures then
        ligatures[unicode] = { char = v }
    else
        character.ligatures = { [unicode] = { char = v } }
    end
    if done then
        local d = done[name]
        if not d then
            done[name] = { "dummy", v }
        else
            d[#d+1] = v
        end
    end
end

local function make_2(present,tfmdata,characters,tree,name,preceding,unicode,done)
    if tonumber(tree) then
        make_3(present,tfmdata,characters,tree,name,preceding,unicode,done,tree)
    else
        for k, v in next, tree do
            if k == "ligature" then
                make_3(present,tfmdata,characters,tree,name,preceding,unicode,done,v)
            else
                local code = present[name] or unicode
                local name = name .. "_" .. k
                make_2(present,tfmdata,characters,v,name,code,k,done)
            end
        end
    end
end

local function preparesubstitutions(tfmdata,feature,value,validlookups,lookuplist)
    local characters   = tfmdata.characters
    local descriptions = tfmdata.descriptions
    local resources    = tfmdata.resources
    local changed      = tfmdata.changed

    local ligatures    = { }
    local alternate    = tonumber(value) or true and 1
    local defaultalt   = otf.defaultbasealternate
    local trace_singles      = trace_baseinit and trace_singles
    local trace_alternatives = trace_baseinit and trace_alternatives
    local trace_ligatures    = trace_baseinit and trace_ligatures

    -- A chain of changes is handled in font-con which is cleaner because
    -- we can have shared changes and such.

    if not changed then
        changed = { }
        tfmdata.changed = changed
    end

    for i=1,#lookuplist do
        local sequence = lookuplist[i]
        local steps    = sequence.steps
        local kind     = sequence.type
        if kind == "gsub_single" then
            for i=1,#steps do
                for unicode, data in next, steps[i].coverage do
                    if unicode ~= data then
-- if not changed[unicode] then
                        changed[unicode] = data
-- end
                    end
                    if trace_singles then
                        report_substitution(feature,sequence,descriptions,unicode,data)
                    end
                end
            end
        elseif kind == "gsub_alternate" then
            for i=1,#steps do
                for unicode, data in next, steps[i].coverage do
                    local replacement = data[alternate]
                    if replacement then
                        if unicode ~= replacement then
-- if not changed[unicode] then
                            changed[unicode] = replacement
-- end
                        end
                        if trace_alternatives then
                            report_alternate(feature,sequence,descriptions,unicode,replacement,value,"normal")
                        end
                    elseif defaultalt == "first" then
                        replacement = data[1]
                        if unicode ~= replacement then
-- if not changed[unicode] then
                            changed[unicode] = replacement
-- end
                        end
                        if trace_alternatives then
                            report_alternate(feature,sequence,descriptions,unicode,replacement,value,defaultalt)
                        end
                    elseif defaultalt == "last" then
                        replacement = data[#data]
                        if unicode ~= replacement then
-- if not changed[unicode] then
                            changed[unicode] = replacement
-- end
                        end
                        if trace_alternatives then
                            report_alternate(feature,sequence,descriptions,unicode,replacement,value,defaultalt)
                        end
                    else
                        if trace_alternatives then
                            report_alternate(feature,sequence,descriptions,unicode,replacement,value,"unknown")
                        end
                    end
                end
            end
        elseif kind == "gsub_ligature" then
            for i=1,#steps do
                for unicode, data in next, steps[i].coverage do
                    ligatures[#ligatures+1] = { unicode, data, "" } -- lookupname }
                    if trace_ligatures then
                        report_ligature(feature,sequence,descriptions,unicode,data)
                    end
                end
            end
        end
    end

    local nofligatures = #ligatures

    if nofligatures > 0 then
        local characters = tfmdata.characters
        local present    = { }
        local done       = trace_baseinit and trace_ligatures and { }

        for i=1,nofligatures do
            local ligature = ligatures[i]
            local unicode  = ligature[1]
            local tree     = ligature[2]
            make_1(present,tree,"ctx_"..unicode)
        end

        for i=1,nofligatures do
            local ligature   = ligatures[i]
            local unicode    = ligature[1]
            local tree       = ligature[2]
            local lookupname = ligature[3]
            make_2(present,tfmdata,characters,tree,"ctx_"..unicode,unicode,unicode,done,sequence)
        end

    end

end

local function preparepositionings(tfmdata,feature,value,validlookups,lookuplist)
    local characters   = tfmdata.characters
    local descriptions = tfmdata.descriptions
    local resources    = tfmdata.resources
    local properties   = tfmdata.properties
    local traceindeed  = trace_baseinit and trace_kerns
    -- check out this sharedkerns trickery
    for i=1,#lookuplist do
        local sequence = lookuplist[i]
        local steps    = sequence.steps
        local kind     = sequence.type
        local format   = sequence.format
        if kind == "gpos_pair" then
            for i=1,#steps do
                local step   = steps[i]
                local format = step.format
                if format == "kern" or format == "move" then
                    for unicode, data in next, steps[i].coverage do
                        local character = characters[unicode]
                        local kerns = character.kerns
                        if not kerns then
                            kerns = { }
                            character.kerns = kerns
                        end
                        if traceindeed then
                            for otherunicode, kern in next, data do
                                if not kerns[otherunicode] and kern ~= 0 then
                                    kerns[otherunicode] = kern
                                    report_kern(feature,sequence,descriptions,unicode,otherunicode,kern)
                                end
                            end
                        else
                            for otherunicode, kern in next, data do
                                if not kerns[otherunicode] and kern ~= 0 then
                                    kerns[otherunicode] = kern
                                end
                            end
                        end
                    end
                else
                    for unicode, data in next, steps[i].coverage do
                        local character = characters[unicode]
                        local kerns     = character.kerns
                        for otherunicode, kern in next, data do
                            -- kern[2] is true (all zero) or a table
                            local other = kern[2]
                            if other == true or (not other and not (kerns and kerns[otherunicode])) then
                                local kern = kern[1]
                                if kern == true then
                                    -- all zero
                                elseif kern[1] ~= 0 or kern[2] ~= 0 or kern[4] ~= 0 then
                                    -- a complex pair not suitable for basemode
                                else
                                    kern = kern[3]
                                    if kern ~= 0 then
                                        if kerns then
                                            kerns[otherunicode] = kern
                                        else
                                            kerns = { [otherunicode] = kern }
                                            character.kerns = kerns
                                        end
                                        if traceindeed then
                                            report_kern(feature,sequence,descriptions,unicode,otherunicode,kern)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

end

local function initializehashes(tfmdata)
    -- already done
end

local function checkmathreplacements(tfmdata,fullname,fixitalics)
    if tfmdata.mathparameters then
        local characters = tfmdata.characters
        local changed    = tfmdata.changed
        if next(changed) then
            if trace_preparing or trace_baseinit then
                report_prepare("checking math replacements for %a",fullname)
            end
            for unicode, replacement in next, changed do
                local u = characters[unicode]
                local r = characters[replacement]
                if u and r then
                    local n = u.next
                    local v = u.vert_variants
                    local h = u.horiz_variants
                    if fixitalics then
                        -- quite some warnings on stix ...
                        local ui = u.italic
                        if ui and not r.italic then
                            if trace_preparing then
                                report_prepare("using %i units of italic correction from %C for %U",ui,unicode,replacement)
                            end
                            r.italic = ui -- print(ui,ri)
                        end
                    end
                    if n and not r.next then
                        if trace_preparing then
                            report_prepare("forcing %s for %C substituted by %U","incremental step",unicode,replacement)
                        end
                        r.next = n
                    end
                    if v and not r.vert_variants then
                        if trace_preparing then
                            report_prepare("forcing %s for %C substituted by %U","vertical variants",unicode,replacement)
                        end
                        r.vert_variants = v
                    end
                    if h and not r.horiz_variants then
                        if trace_preparing then
                            report_prepare("forcing %s for %C substituted by %U","horizontal variants",unicode,replacement)
                        end
                        r.horiz_variants = h
                    end
                else
                    if trace_preparing then
                        report_prepare("error replacing %C by %U",unicode,replacement)
                    end
                end
            end
        end
    end
end

local function featuresinitializer(tfmdata,value)
    if true then -- value then
        local starttime = trace_preparing and os.clock()
        local features  = tfmdata.shared.features
        local fullname  = tfmdata.properties.fullname or "?"
        if features then
            initializehashes(tfmdata)
            local collectlookups    = otf.collectlookups
            local rawdata           = tfmdata.shared.rawdata
            local properties        = tfmdata.properties
            local script            = properties.script
            local language          = properties.language
            local rawresources      = rawdata.resources
            local rawfeatures       = rawresources and rawresources.features
            local basesubstitutions = rawfeatures and rawfeatures.gsub
            local basepositionings  = rawfeatures and rawfeatures.gpos
            local substitutionsdone = false
            local positioningsdone  = false
            --
            if basesubstitutions or basepositionings then
                local sequences = tfmdata.resources.sequences
                for s=1,#sequences do
                    local sequence = sequences[s]
                    local sfeatures = sequence.features
                    if sfeatures then
                        local order = sequence.order
                        if order then
                            for i=1,#order do --
                                local feature = order[i]
                                local value = features[feature]
                                if value then
                                    local validlookups, lookuplist = collectlookups(rawdata,feature,script,language)
-- if not validlookups and not lookuplist and script == "math" then
--     validlookups, lookuplist = collectlookups(rawdata,feature,"dflt","dflt")
-- end
                                    if not validlookups then
                                        -- skip
                                    elseif basesubstitutions and basesubstitutions[feature] then
                                        if trace_preparing then
                                            report_prepare("filtering base %s feature %a for %a with value %a","sub",feature,fullname,value)
                                        end
                                        preparesubstitutions(tfmdata,feature,value,validlookups,lookuplist)
                                        registerbasefeature(feature,value)
                                        substitutionsdone = true
                                    elseif basepositionings and basepositionings[feature] then
                                        if trace_preparing then
                                            report_prepare("filtering base %a feature %a for %a with value %a","pos",feature,fullname,value)
                                        end
                                        preparepositionings(tfmdata,feature,value,validlookups,lookuplist)
                                        registerbasefeature(feature,value)
                                        positioningsdone = true
                                    end
                                end
                            end
                        end
                    end
                end
            end
            --
            if substitutionsdone then
                checkmathreplacements(tfmdata,fullname,features.fixitalics)
            end
            --
            registerbasehash(tfmdata)
        end
        if trace_preparing then
            report_prepare("preparation time is %0.3f seconds for %a",os.clock()-starttime,fullname)
        end
    end
end

registerotffeature {
    name         = "features",
    description  = "features",
    default      = true,
    initializers = {
     -- position = 1, -- after setscript (temp hack ... we need to force script / language to 1
        base     = featuresinitializer,
    }
}

otf.basemodeinitializer = featuresinitializer
