if not modules then modules = { } end modules ['font-one'] = {
    version   = 1.001,
    optimize  = true,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- Some code may look a bit obscure but this has to do with the fact that we also
-- use this code for testing and much code evolved in the transition from TFM to AFM
-- to OTF.
--
-- The following code still has traces of intermediate font support where we handles
-- font encodings. Eventually font encoding went away but we kept some code around
-- in other modules.
--
-- This version implements a node mode approach so that users can also more easily
-- add features.

local fonts, logs, trackers, containers, resolvers = fonts, logs, trackers, containers, resolvers

local next, type, tonumber, rawget = next, type, tonumber, rawget
local match, gsub = string.match, string.gsub
local abs = math.abs
local P, S, R, Cmt, C, Ct, Cs, Carg = lpeg.P, lpeg.S, lpeg.R, lpeg.Cmt, lpeg.C, lpeg.Ct, lpeg.Cs, lpeg.Carg
local lpegmatch, patterns = lpeg.match, lpeg.patterns
local sortedhash = table.sortedhash

local trace_features      = false  trackers.register("afm.features",   function(v) trace_features = v end)
local trace_indexing      = false  trackers.register("afm.indexing",   function(v) trace_indexing = v end)
local trace_loading       = false  trackers.register("afm.loading",    function(v) trace_loading  = v end)
local trace_defining      = false  trackers.register("fonts.defining", function(v) trace_defining = v end)

local report_afm          = logs.reporter("fonts","afm loading")

local setmetatableindex   = table.setmetatableindex
local derivetable         = table.derive

local findbinfile         = resolvers.findbinfile

local privateoffset       = fonts.constructors and fonts.constructors.privateoffset or 0xF0000 -- 0x10FFFF

local definers            = fonts.definers
local readers             = fonts.readers
local constructors        = fonts.constructors

local afm                 = constructors.handlers.afm
local pfb                 = constructors.handlers.pfb
local otf                 = fonts.handlers.otf

local otfreaders          = otf.readers
local otfenhancers        = otf.enhancers

local afmfeatures         = constructors.features.afm
local registerafmfeature  = afmfeatures.register

local afmenhancers        = constructors.enhancers.afm
local registerafmenhancer = afmenhancers.register

afm.version               = 1.513 -- incrementing this number one up will force a re-cache
afm.cache                 = containers.define("fonts", "one", afm.version, true)
afm.autoprefixed          = true -- this will become false some day (catches texnansi-blabla.*)

afm.helpdata              = { }  -- set later on so no local for this
afm.syncspace             = true -- when true, nicer stretch values

local overloads           = fonts.mappings.overloads

local applyruntimefixes   = fonts.treatments and fonts.treatments.applyfixes

-- We cache files. Caching is taken care of in the loader. We cheat a bit by adding
-- ligatures and kern information to the afm derived data. That way we can set them
-- faster when defining a font.
--
-- We still keep the loading two phased: first we load the data in a traditional
-- fashion and later we transform it to sequences. Then we apply some methods also
-- used in opentype fonts (like tlig).

function afm.load(filename)
    filename = resolvers.findfile(filename,'afm') or ""
    if filename ~= "" and not fonts.names.ignoredfile(filename) then
        local name = file.removesuffix(file.basename(filename))
        local data = containers.read(afm.cache,name)
        local attr = lfs.attributes(filename)
        local size = attr and attr.size or 0
        local time = attr and attr.modification or 0
        --
        local pfbfile = file.replacesuffix(name,"pfb")
        local pfbname = resolvers.findfile(pfbfile,"pfb") or ""
        if pfbname == "" then
            pfbname = resolvers.findfile(file.basename(pfbfile),"pfb") or ""
        end
        local pfbsize = 0
        local pfbtime = 0
        if pfbname ~= "" then
            local attr = lfs.attributes(pfbname)
            pfbsize = attr.size or 0
            pfbtime = attr.modification or 0
        end
        if not data or data.size ~= size or data.time ~= time or data.pfbsize ~= pfbsize or data.pfbtime ~= pfbtime then
            report_afm("reading %a",filename)
            data = afm.readers.loadfont(filename,pfbname)
            if data then
                afmenhancers.apply(data,filename)
             -- otfreaders.addunicodetable(data) -- only when not done yet
                fonts.mappings.addtounicode(data,filename)
                otfreaders.stripredundant(data)
             -- otfreaders.extend(data)
                otfreaders.pack(data)
                data.size = size
                data.time = time
                data.pfbsize = pfbsize
                data.pfbtime = pfbtime
                report_afm("saving %a in cache",name)
             -- data.resources.unicodes = nil -- consistent with otf but here we save not much
                data = containers.write(afm.cache, name, data)
                data = containers.read(afm.cache,name)
            end
        end
        if data then
         -- constructors.addcoreunicodes(unicodes)
            otfreaders.unpack(data)
            otfreaders.expand(data) -- inline tables
            otfreaders.addunicodetable(data) -- only when not done yet
            otfenhancers.apply(data,filename,data)
            if applyruntimefixes then
                applyruntimefixes(filename,data)
            end
        end
        return data
    end
end

-- we run a more advanced analyzer later on anyway

local uparser = fonts.mappings.makenameparser() -- each time

local function enhance_unify_names(data, filename)
    local unicodevector = fonts.encodings.agl.unicodes -- loaded runtime in context
    local unicodes      = { }
    local names         = { }
    local private       = data.private or privateoffset
    local descriptions  = data.descriptions
    for name, blob in sortedhash(data.characters) do -- sorting is nicer for privates
        local code = unicodevector[name] -- or characters.name_to_unicode[name]
        if not code then
            code = lpegmatch(uparser,name)
            if type(code) ~= "number" then
                code = private
                private = private + 1
                report_afm("assigning private slot %U for unknown glyph name %a",code,name)
            end
        end
        local index = blob.index
        unicodes[name] = code
        names[name] = index
        blob.name = name
        descriptions[code] = {
            boundingbox = blob.boundingbox,
            width       = blob.width,
            kerns       = blob.kerns,
            index       = index,
            name        = name,
        }
    end
    for unicode, description in next, descriptions do
        local kerns = description.kerns
        if kerns then
            local krn = { }
            for name, kern in next, kerns do
                local unicode = unicodes[name]
                if unicode then
                    krn[unicode] = kern
                else
                 -- print(unicode,name)
                end
            end
            description.kerns = krn
        end
    end
    data.characters = nil
    data.private    = private
    local resources = data.resources
    local filename  = resources.filename or file.removesuffix(file.basename(filename))
    resources.filename = resolvers.unresolve(filename) -- no shortcut
    resources.unicodes = unicodes -- name to unicode
    resources.marks    = { } -- todo
 -- resources.names    = names -- name to index
end

local everywhere = { ["*"] = { ["*"] = true } } -- or: { ["*"] = { "*" } }
local noflags    = { false, false, false, false }

local function enhance_normalize_features(data)
    local ligatures  = setmetatableindex("table")
    local kerns      = setmetatableindex("table")
    local extrakerns = setmetatableindex("table")
    for u, c in next, data.descriptions do
        local l = c.ligatures
        local k = c.kerns
        local e = c.extrakerns
        if l then
            ligatures[u] = l
            for u, v in next, l do
                l[u] = { ligature = v }
            end
            c.ligatures = nil
        end
        if k then
            kerns[u] = k
            for u, v in next, k do
                k[u] = v -- { v, 0 }
            end
            c.kerns = nil
        end
        if e then
            extrakerns[u] = e
            for u, v in next, e do
                e[u] = v -- { v, 0 }
            end
            c.extrakerns = nil
        end
    end
    local features = {
        gpos = { },
        gsub = { },
    }
    local sequences = {
        -- only filled ones
    }
    if next(ligatures) then
        features.gsub.liga = everywhere
        data.properties.hasligatures = true
        sequences[#sequences+1] = {
            features = {
                liga = everywhere,
            },
            flags    = noflags,
            name     = "s_s_0",
            nofsteps = 1,
            order    = { "liga" },
            type     = "gsub_ligature",
            steps    = {
                {
                    coverage = ligatures,
                },
            },
        }
    end
    if next(kerns) then
        features.gpos.kern = everywhere
        data.properties.haskerns = true
        sequences[#sequences+1] = {
            features = {
                kern = everywhere,
            },
            flags    = noflags,
            name     = "p_s_0",
            nofsteps = 1,
            order    = { "kern" },
            type     = "gpos_pair",
            steps    = {
                {
                    format   = "kern",
                    coverage = kerns,
                },
            },
        }
    end
    if next(extrakerns) then
        features.gpos.extrakerns = everywhere
        data.properties.haskerns = true
        sequences[#sequences+1] = {
            features = {
                extrakerns = everywhere,
            },
            flags    = noflags,
            name     = "p_s_1",
            nofsteps = 1,
            order    = { "extrakerns" },
            type     = "gpos_pair",
            steps    = {
                {
                    format   = "kern",
                    coverage = extrakerns,
                },
            },
        }
    end
    -- todo: compress kerns
    data.resources.features  = features
    data.resources.sequences = sequences
end

local function enhance_fix_names(data)
    for k, v in next, data.descriptions do
        local n = v.name
        local r = overloads[n]
        if r then
            local name = r.name
            if trace_indexing then
                report_afm("renaming characters %a to %a",n,name)
            end
            v.name    = name
            v.unicode = r.unicode
        end
    end
end

-- These helpers extend the basic table with extra ligatures, texligatures and extra
-- kerns. This saves quite some lookups later.

local addthem = function(rawdata,ligatures)
    if ligatures then
        local descriptions = rawdata.descriptions
        local resources    = rawdata.resources
        local unicodes     = resources.unicodes
     -- local names        = resources.names
        for ligname, ligdata in next, ligatures do
            local one = descriptions[unicodes[ligname]]
            if one then
                for _, pair in next, ligdata do
                    local two   = unicodes[pair[1]]
                    local three = unicodes[pair[2]]
                    if two and three then
                        local ol = one.ligatures
                        if ol then
                            if not ol[two] then
                                ol[two] = three
                            end
                        else
                            one.ligatures = { [two] = three }
                        end
                    end
                end
            end
        end
    end
end

local function enhance_add_ligatures(rawdata)
    addthem(rawdata,afm.helpdata.ligatures)
end

-- We keep the extra kerns in separate kerning tables so that we can use them
-- selectively.
--
-- This is rather old code (from the beginning when we had only tfm). If we unify
-- the afm data (now we have names all over the place) then we can use shcodes but
-- there will be many more looping then. But we could get rid of the tables in
-- char-cmp then. Als, in the generic version we don't use the character database.
-- (Ok, we can have a context specific variant).

local function enhance_add_extra_kerns(rawdata) -- using shcodes is not robust here
    local descriptions = rawdata.descriptions
    local resources    = rawdata.resources
    local unicodes     = resources.unicodes
    local function do_it_left(what)
        if what then
            for unicode, description in next, descriptions do
                local kerns = description.kerns
                if kerns then
                    local extrakerns
                    for complex, simple in next, what do
                        complex = unicodes[complex]
                        simple = unicodes[simple]
                        if complex and simple then
                            local ks = kerns[simple]
                            if ks and not kerns[complex] then
                                if extrakerns then
                                    extrakerns[complex] = ks
                                else
                                    extrakerns = { [complex] = ks }
                                end
                            end
                        end
                    end
                    if extrakerns then
                        description.extrakerns = extrakerns
                    end
                end
            end
        end
    end
    local function do_it_copy(what)
        if what then
            for complex, simple in next, what do
                complex = unicodes[complex]
                simple  = unicodes[simple]
                if complex and simple then
                    local complexdescription = descriptions[complex]
                    if complexdescription then -- optional
                        local simpledescription = descriptions[complex]
                        if simpledescription then
                            local extrakerns
                            local kerns = simpledescription.kerns
                            if kerns then
                                for unicode, kern in next, kerns do
                                    if extrakerns then
                                        extrakerns[unicode] = kern
                                    else
                                        extrakerns = { [unicode] = kern }
                                    end
                                end
                            end
                            local extrakerns = simpledescription.extrakerns
                            if extrakerns then
                                for unicode, kern in next, extrakerns do
                                    if extrakerns then
                                        extrakerns[unicode] = kern
                                    else
                                        extrakerns = { [unicode] = kern }
                                    end
                                end
                            end
                            if extrakerns then
                                complexdescription.extrakerns = extrakerns
                            end
                        end
                    end
                end
            end
        end
    end
    -- add complex with values of simplified when present
    do_it_left(afm.helpdata.leftkerned)
    do_it_left(afm.helpdata.bothkerned)
    -- copy kerns from simple char to complex char unless set
    do_it_copy(afm.helpdata.bothkerned)
    do_it_copy(afm.helpdata.rightkerned)
end

-- The copying routine looks messy (and is indeed a bit messy).

local function adddimensions(data) -- we need to normalize afm to otf i.e. indexed table instead of name
    if data then
        for unicode, description in next, data.descriptions do
            local bb = description.boundingbox
            if bb then
                local ht =  bb[4]
                local dp = -bb[2]
                if ht == 0 or ht < 0 then
                    -- no need to set it and no negative heights, nil == 0
                else
                    description.height = ht
                end
                if dp == 0 or dp < 0 then
                    -- no negative depths and no negative depths, nil == 0
                else
                    description.depth  = dp
                end
            end
        end
    end
end

local function copytotfm(data)
    if data and data.descriptions then
        local metadata     = data.metadata
        local resources    = data.resources
        local properties   = derivetable(data.properties)
        local descriptions = derivetable(data.descriptions)
        local goodies      = derivetable(data.goodies)
        local characters   = { }
        local parameters   = { }
        local unicodes     = resources.unicodes
        --
        for unicode, description in next, data.descriptions do -- use parent table
            characters[unicode] = { }
        end
        --
        local filename   = constructors.checkedfilename(resources)
        local fontname   = metadata.fontname or metadata.fullname
        local fullname   = metadata.fullname or metadata.fontname
        local endash     = 0x2013
        local emdash     = 0x2014
        local space      = 0x0020 -- space
        local spacer     = "space"
        local spaceunits = 500
        --
        local monospaced  = metadata.monospaced
        local charwidth   = metadata.charwidth
        local italicangle = metadata.italicangle
        local charxheight = metadata.xheight and metadata.xheight > 0 and metadata.xheight
        properties.monospaced  = monospaced
        parameters.italicangle = italicangle
        parameters.charwidth   = charwidth
        parameters.charxheight = charxheight
        -- nearly the same as otf, catches
        local d_endash = descriptions[endash]
        local d_emdash = descriptions[emdash]
        local d_space  = descriptions[space]
        if not d_space or d_space == 0 then
            d_space = d_endash
        end
        if d_space then
            spaceunits, spacer = d_space.width or 0, "space"
        end
        if properties.monospaced then
            if spaceunits == 0 and d_emdash then
                spaceunits, spacer = d_emdash.width or 0, "emdash"
            end
        else
            if spaceunits == 0 and d_endash then
                spaceunits, spacer = d_emdash.width or 0, "endash"
            end
        end
        if spaceunits == 0 and charwidth then
            spaceunits, spacer = charwidth or 0, "charwidth"
        end
        if spaceunits == 0 then
            spaceunits = tonumber(spaceunits) or 500
        end
        if spaceunits == 0 then
            spaceunits = 500
        end
        --
        parameters.slant         = 0
        parameters.space         = spaceunits
        parameters.space_stretch = 500
        parameters.space_shrink  = 333
        parameters.x_height      = 400
        parameters.quad          = 1000
        --
        if italicangle and italicangle ~= 0 then
            parameters.italicangle  = italicangle
            parameters.italicfactor = math.cos(math.rad(90+italicangle))
            parameters.slant        = - math.tan(italicangle*math.pi/180)
        end
        if monospaced then
            parameters.space_stretch = 0
            parameters.space_shrink  = 0
        elseif afm.syncspace then
            parameters.space_stretch = spaceunits/2
            parameters.space_shrink  = spaceunits/3
        end
        parameters.extra_space = parameters.space_shrink
        if charxheight then
            parameters.x_height = charxheight
        else
            -- same as otf
            local x = 0x0078 -- x
            if x then
                local x = descriptions[x]
                if x then
                    parameters.x_height = x.height
                end
            end
            --
        end
        --
        if metadata.sup then
            local dummy    = { 0, 0, 0 }
            parameters[ 1] = metadata.designsize        or 0
            parameters[ 2] = metadata.checksum          or 0
            parameters[ 3],
            parameters[ 4],
            parameters[ 5] = unpack(metadata.space      or dummy)
            parameters[ 6] =        metadata.quad       or 0
            parameters[ 7] =        metadata.extraspace or 0
            parameters[ 8],
            parameters[ 9],
            parameters[10] = unpack(metadata.num        or dummy)
            parameters[11],
            parameters[12] = unpack(metadata.denom      or dummy)
            parameters[13],
            parameters[14],
            parameters[15] = unpack(metadata.sup        or dummy)
            parameters[16],
            parameters[17] = unpack(metadata.sub        or dummy)
            parameters[18] =        metadata.supdrop    or 0
            parameters[19] =        metadata.subdrop    or 0
            parameters[20],
            parameters[21] = unpack(metadata.delim      or dummy)
            parameters[22] =        metadata.axisheight or 0
        end
        --
        parameters.designsize = (metadata.designsize or 10)*65536
        parameters.ascender   = abs(metadata.ascender  or 0)
        parameters.descender  = abs(metadata.descender or 0)
        parameters.units      = 1000
        --
        properties.spacer   = spacer
        properties.format   = fonts.formats[filename] or "type1"
        properties.filename = filename
        properties.fontname = fontname
        properties.fullname = fullname
        properties.psname   = fullname
        properties.name     = filename or fullname or fontname
        properties.private  = properties.private or data.private or privateoffset
        --
if not CONTEXTLMTXMODE or CONTEXTLMTXMODE == 0 then
        properties.encodingbytes = 2
end
        --
        if next(characters) then
            return {
                characters   = characters,
                descriptions = descriptions,
                parameters   = parameters,
                resources    = resources,
                properties   = properties,
                goodies      = goodies,
            }
        end
    end
    return nil
end

-- Originally we had features kind of hard coded for AFM files but since I expect to
-- support more font formats, I decided to treat this fontformat like any other and
-- handle features in a more configurable way.

function afm.setfeatures(tfmdata,features)
    local okay = constructors.initializefeatures("afm",tfmdata,features,trace_features,report_afm)
    if okay then
        return constructors.collectprocessors("afm",tfmdata,features,trace_features,report_afm)
    else
        return { } -- will become false
    end
end

local function addtables(data)
    local resources  = data.resources
    local lookuptags = resources.lookuptags
    local unicodes   = resources.unicodes
    if not lookuptags then
        lookuptags = { }
        resources.lookuptags = lookuptags
    end
    setmetatableindex(lookuptags,function(t,k)
        local v = type(k) == "number" and ("lookup " .. k) or k
        t[k] = v
        return v
    end)
    if not unicodes then
        unicodes = { }
        resources.unicodes = unicodes
        setmetatableindex(unicodes,function(t,k)
            setmetatableindex(unicodes,nil)
            for u, d in next, data.descriptions do
                local n = d.name
                if n then
                    t[n] = u
                end
            end
            return rawget(t,k)
        end)
    end
    constructors.addcoreunicodes(unicodes) -- do we really need this?
end

local function afmtotfm(specification)
    local afmname = specification.filename or specification.name
    if specification.forced == "afm" or specification.format == "afm" then -- move this one up
        if trace_loading then
            report_afm("forcing afm format for %a",afmname)
        end
    else
        local tfmname = findbinfile(afmname,"ofm") or ""
        if tfmname ~= "" then
            if trace_loading then
                report_afm("fallback from afm to tfm for %a",afmname)
            end
            return -- just that
        end
    end
    if afmname ~= "" then
        -- weird, isn't this already done then?
        local features = constructors.checkedfeatures("afm",specification.features.normal)
        specification.features.normal = features
        constructors.hashinstance(specification,true) -- also weird here
        --
        specification = definers.resolve(specification) -- new, was forgotten
        local cache_id = specification.hash
        local tfmdata  = containers.read(constructors.cache, cache_id) -- cache with features applied
        if not tfmdata then
            local rawdata = afm.load(afmname)
            if rawdata and next(rawdata) then
                addtables(rawdata)
                adddimensions(rawdata)
                tfmdata = copytotfm(rawdata)
                if tfmdata and next(tfmdata) then
                    local shared = tfmdata.shared
                    if not shared then
                        shared         = { }
                        tfmdata.shared = shared
                    end
                    shared.rawdata   = rawdata
                    shared.dynamics  = { }
                    tfmdata.changed  = { }
                    shared.features  = features
                    shared.processes = afm.setfeatures(tfmdata,features)
                end
            elseif trace_loading then
                report_afm("no (valid) afm file found with name %a",afmname)
            end
            tfmdata = containers.write(constructors.cache,cache_id,tfmdata)
        end
        return tfmdata
    end
end

-- As soon as we could intercept the TFM reader, I implemented an AFM reader. Since
-- traditional pdfTeX could use OpenType fonts with AFM companions, the following
-- method also could handle those cases, but now that we can handle OpenType
-- directly we no longer need this features.

local function read_from_afm(specification)
    local tfmdata = afmtotfm(specification)
    if tfmdata then
        tfmdata.properties.name = specification.name
        tfmdata.properties.id   = specification.id
        tfmdata = constructors.scale(tfmdata, specification)
        local allfeatures = tfmdata.shared.features or specification.features.normal
        constructors.applymanipulators("afm",tfmdata,allfeatures,trace_features,report_afm)
        fonts.loggers.register(tfmdata,'afm',specification)
    end
    return tfmdata
end

-- We have the usual two modes and related features initializers and processors.

registerafmfeature {
    name         = "mode",
    description  = "mode",
    initializers = {
        base = otf.modeinitializer,
        node = otf.modeinitializer,
    }
}

registerafmfeature {
    name         = "features",
    description  = "features",
    default      = true,
    initializers = {
        node     = otf.nodemodeinitializer,
        base     = otf.basemodeinitializer,
    },
    processors   = {
        node     = otf.featuresprocessor,
    }
}

-- readers

fonts.formats.afm = "type1"
fonts.formats.pfb = "type1"

local function check_afm(specification,fullname)
    local foundname = findbinfile(fullname, 'afm') or "" -- just to be sure
    if foundname == "" then
        foundname = fonts.names.getfilename(fullname,"afm") or ""
    end
    if fullname and foundname == "" and afm.autoprefixed then
        local encoding, shortname = match(fullname,"^(.-)%-(.*)$") -- context: encoding-name.*
        if encoding and shortname and fonts.encodings.known[encoding] then
            shortname = findbinfile(shortname,'afm') or "" -- just to be sure
            if shortname ~= "" then
                foundname = shortname
                if trace_defining then
                    report_afm("stripping encoding prefix from filename %a",afmname)
                end
            end
        end
    end
    if foundname ~= "" then
        specification.filename = foundname
        specification.format   = "afm"
        return read_from_afm(specification)
    end
end

function readers.afm(specification,method)
    local fullname = specification.filename or ""
    local tfmdata  = nil
    if fullname == "" then
        local forced = specification.forced or ""
        if forced ~= "" then
            tfmdata = check_afm(specification,specification.name .. "." .. forced)
        end
        if not tfmdata then
            local check_tfm = readers.check_tfm
            method = (check_tfm and (method or definers.method or "afm or tfm")) or "afm"
            if method == "tfm" then
                tfmdata = check_tfm(specification,specification.name)
            elseif method == "afm" then
                tfmdata = check_afm(specification,specification.name)
            elseif method == "tfm or afm" then
                tfmdata = check_tfm(specification,specification.name) or check_afm(specification,specification.name)
            else -- method == "afm or tfm" or method == "" then
                tfmdata = check_afm(specification,specification.name) or check_tfm(specification,specification.name)
            end
        end
    else
        tfmdata = check_afm(specification,fullname)
    end
    return tfmdata
end

function readers.pfb(specification,method) -- only called when forced
    local original = specification.specification
    if trace_defining then
        report_afm("using afm reader for %a",original)
    end
    specification.forced = "afm"
    local function swap(name)
        local value = specification[swap]
        if value then
            specification[swap] = gsub("%.pfb",".afm",1)
        end
    end
    swap("filename")
    swap("fullname")
    swap("forcedname")
    swap("specification")
    return readers.afm(specification,method)
end

-- now we register them

registerafmenhancer("unify names",          enhance_unify_names)
registerafmenhancer("add ligatures",        enhance_add_ligatures)
registerafmenhancer("add extra kerns",      enhance_add_extra_kerns)
registerafmenhancer("normalize features",   enhance_normalize_features)
registerafmenhancer("check extra features", otfenhancers.enhance)
registerafmenhancer("fix names",            enhance_fix_names)
