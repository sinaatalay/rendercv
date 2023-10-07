if not modules then modules = { } end modules ['font-def'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- We can overload some of the definers.functions so we don't local them.

local lower, gsub = string.lower, string.gsub
local tostring, next = tostring, next
local lpegmatch = lpeg.match
local suffixonly, removesuffix, basename = file.suffix, file.removesuffix, file.basename
local formatters = string.formatters
local sortedhash, sortedkeys = table.sortedhash, table.sortedkeys

local allocate = utilities.storage.allocate

local trace_defining     = false  trackers  .register("fonts.defining", function(v) trace_defining     = v end)
local directive_embedall = false  directives.register("fonts.embedall", function(v) directive_embedall = v end)

trackers.register("fonts.loading", "fonts.defining", "otf.loading", "afm.loading", "tfm.loading")

local report_defining = logs.reporter("fonts","defining")

-- Here we deal with defining fonts. We do so by intercepting the default loader
-- that only handles TFM files. Although, we started out that way but in the
-- meantime we can hardly speak of TFM any more.

local fonts         = fonts
local fontdata      = fonts.hashes.identifiers
local readers       = fonts.readers
local definers      = fonts.definers
local specifiers    = fonts.specifiers
local constructors  = fonts.constructors
local fontgoodies   = fonts.goodies

readers.sequence    = allocate { 'otf', 'ttf', 'afm', 'tfm', 'lua' } -- dfont ttc

local variants      = allocate()
specifiers.variants = variants

definers.methods    = definers.methods or { }

local internalized  = allocate() -- internal tex numbers (private)

local loadedfonts   = constructors.loadedfonts
local designsizes   = constructors.designsizes

-- not in generic (some day I'll make two defs, one for context, one for generic)

local resolvefile   = fontgoodies and fontgoodies.filenames and fontgoodies.filenames.resolve or function(s) return s end

-- We hardly gain anything when we cache the final (pre scaled) TFM table. But it
-- can be handy for debugging, so we no longer carry this code along. Also, we now
-- have quite some reference to other tables so we would end up with lots of
-- catches.
--
-- We can prefix a font specification by "name:" or "file:". The first case will
-- result in a lookup in the synonym table.
--
--   [ name: | file: ] identifier [ separator [ specification ] ]
--
-- The following function split the font specification into components and prepares
-- a table that will move along as we proceed.

-- beware, we discard additional specs
--
-- method:name method:name(sub) method:name(sub)*spec method:name*spec
-- name name(sub) name(sub)*spec name*spec
-- name@spec*oeps

local function makespecification(specification,lookup,name,sub,method,detail,size)
    size = size or 655360
    if not lookup or lookup == "" then
        lookup = definers.defaultlookup
    end
    if trace_defining then
        report_defining("specification %a, lookup %a, name %a, sub %a, method %a, detail %a",
            specification, lookup, name, sub, method, detail)
    end
    local t = {
        lookup        = lookup,        -- forced type
        specification = specification, -- full specification
        size          = size,          -- size in scaled points or -1000*n
        name          = name,          -- font or filename
        sub           = sub,           -- subfont (eg in ttc)
        method        = method,        -- specification method
        detail        = detail,        -- specification
        resolved      = "",            -- resolved font name
        forced        = "",            -- forced loader
        features      = { },           -- preprocessed features
    }
    return t
end

definers.makespecification = makespecification

if context then

    local splitter, splitspecifiers = nil, "" -- not so nice

    local P, C, S, Cc, Cs = lpeg.P, lpeg.C, lpeg.S, lpeg.Cc, lpeg.Cs

    local left   = P("(")
    local right  = P(")")
    local colon  = P(":")
    local space  = P(" ")
    local lbrace = P("{")
    local rbrace = P("}")

    definers.defaultlookup = "file"

    local prefixpattern = P(false)

    local function addspecifier(symbol)
        splitspecifiers     = splitspecifiers .. symbol
        local method        = S(splitspecifiers)
        local lookup        = C(prefixpattern) * colon
        local sub           = left * C(P(1-left-right-method)^1) * right
        local specification = C(method) * C(P(1)^1)
        local name          = Cs((lbrace/"") * (1-rbrace)^1 * (rbrace/"") + (1-sub-specification)^1)
        splitter = P((lookup + Cc("")) * name * (sub + Cc("")) * (specification + Cc("")))
    end

    local function addlookup(str)
        prefixpattern = prefixpattern + P(str)
    end

    definers.addlookup = addlookup

    addlookup("file")
    addlookup("name")
    addlookup("spec")

    local function getspecification(str)
        return lpegmatch(splitter,str or "") -- weird catch
    end

    definers.getspecification = getspecification

    function definers.registersplit(symbol,action,verbosename)
        addspecifier(symbol)
        variants[symbol] = action
        if verbosename then
            variants[verbosename] = action
        end
    end

    function definers.analyze(specification, size)
        -- can be optimized with locals
        local lookup, name, sub, method, detail = getspecification(specification or "")
        return makespecification(specification, lookup, name, sub, method, detail, size)
    end

end

-- We can resolve the filename using the next function:

definers.resolvers = definers.resolvers or { }
local resolvers    = definers.resolvers

-- todo: reporter

function resolvers.file(specification)
    local name = resolvefile(specification.name) -- catch for renames
    local suffix = lower(suffixonly(name))
    if fonts.formats[suffix] then
        specification.forced     = suffix
        specification.forcedname = name
        specification.name       = removesuffix(name)
    else
        specification.name       = name -- can be resolved
    end
end

function resolvers.name(specification)
    local resolve = fonts.names.resolve
    if resolve then
        local resolved, sub, subindex, instance = resolve(specification.name,specification.sub,specification) -- we pass specification for overloaded versions
        if resolved then
            specification.resolved = resolved
            specification.sub      = sub
            specification.subindex = subindex
            -- new, needed for experiments
            if instance then
                specification.instance = instance
                local features = specification.features
                if not features then
                    features = { }
                    specification.features = features
                end
                local normal = features.normal
                if not normal then
                    normal = { }
                    features.normal = normal
                end
                normal.instance = instance
            end
            --
            local suffix = lower(suffixonly(resolved))
            if fonts.formats[suffix] then
                specification.forced     = suffix
                specification.forcedname = resolved
                specification.name       = removesuffix(resolved)
            else
                specification.name       = resolved
            end
        end
    else
        resolvers.file(specification)
    end
end

function resolvers.spec(specification)
    local resolvespec = fonts.names.resolvespec
    if resolvespec then
        local resolved, sub, subindex = resolvespec(specification.name,specification.sub,specification) -- we pass specification for overloaded versions
        if resolved then
            specification.resolved   = resolved
            specification.sub        = sub
            specification.subindex   = subindex
            specification.forced     = lower(suffixonly(resolved))
            specification.forcedname = resolved
            specification.name       = removesuffix(resolved)
        end
    else
        resolvers.name(specification)
    end
end

function definers.resolve(specification)
    if not specification.resolved or specification.resolved == "" then -- resolved itself not per se in mapping hash
        local r = resolvers[specification.lookup]
        if r then
            r(specification)
        end
    end
    if specification.forced == "" then
        specification.forced     = nil
        specification.forcedname = nil
    end
    specification.hash = lower(specification.name .. ' @ ' .. constructors.hashfeatures(specification))
    if specification.sub and specification.sub ~= "" then
        specification.hash = specification.sub .. ' @ ' .. specification.hash
    end
    return specification
end

-- The main read function either uses a forced reader (as determined by a lookup) or
-- tries to resolve the name using the list of readers.
--
-- We need to cache when possible. We do cache raw tfm data (from TFM, AFM or OTF).
-- After that we can cache based on specificstion (name) and size, that is, TeX only
-- needs a number for an already loaded fonts. However, it may make sense to cache
-- fonts before they're scaled as well (store TFM's with applied methods and
-- features). However, there may be a relation between the size and features (esp in
-- virtual fonts) so let's not do that now.
--
-- Watch out, here we do load a font, but we don't prepare the specification yet.

function definers.applypostprocessors(tfmdata)
    local postprocessors = tfmdata.postprocessors
    if postprocessors then
        local properties = tfmdata.properties
        for i=1,#postprocessors do
            local extrahash = postprocessors[i](tfmdata) -- after scaling etc
            if type(extrahash) == "string" and extrahash ~= "" then
                -- e.g. a reencoding needs this
                extrahash = gsub(lower(extrahash),"[^a-z]","-")
                properties.fullname = formatters["%s-%s"](properties.fullname,extrahash)
            end
        end
    end
    return tfmdata
end

-- function definers.applypostprocessors(tfmdata)
--     return tfmdata
-- end

local function checkembedding(tfmdata)
    local properties = tfmdata.properties
    local embedding
    if directive_embedall then
        embedding = "full"
    elseif properties and properties.filename and constructors.dontembed[properties.filename] then
        embedding = "no"
    else
        embedding = "subset"
    end
    if properties then
        properties.embedding = embedding
    else
        tfmdata.properties = { embedding = embedding }
    end
    tfmdata.embedding = embedding
end

local function checkfeatures(tfmdata)
    local resources = tfmdata.resources
    local shared    = tfmdata.shared
    if resources and shared then
        local features     = resources.features
        local usedfeatures = shared.features
        if features and usedfeatures then
            local usedlanguage = usedfeatures.language or "dflt"
            local usedscript   = usedfeatures.script or "dflt"
            local function check(what)
                if what then
                    local foundlanguages = { }
                    for feature, scripts in next, what do
                        if usedscript == "auto" or scripts["*"] then
                            -- ok
                        elseif not scripts[usedscript] then
                         -- report_defining("font %!font:name!, feature %a, no script %a",
                         --     tfmdata,feature,usedscript)
                        else
                            for script, languages in next, scripts do
                                if languages["*"] then
                                    -- ok
                                elseif context and not languages[usedlanguage] then
                                    report_defining("font %!font:name!, feature %a, script %a, no language %a",
                                        tfmdata,feature,script,usedlanguage)
                                end
                            end
                        end
                        for script, languages in next, scripts do
                            for language in next, languages do
                                foundlanguages[language] = true
                            end
                        end
                    end
                    if false then
                        foundlanguages["*"] = nil
                        foundlanguages = sortedkeys(foundlanguages)
                        for feature, scripts in sortedhash(what) do
                            for script, languages in next, scripts do
                                if not languages["*"] then
                                    for i=1,#foundlanguages do
                                        local language = foundlanguages[i]
                                        if context and not languages[language] then
                                            report_defining("font %!font:name!, feature %a, script %a, no language %a",
                                                tfmdata,feature,script,language)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
            check(features.gsub)
            check(features.gpos)
        end
    end
end

function definers.loadfont(specification)
    local hash = constructors.hashinstance(specification)
    -- todo: also hash by instance / factors
    local tfmdata = loadedfonts[hash] -- hashes by size !
    if not tfmdata then
        -- normally context will not end up here often (if so there is an issue somewhere)
        local forced = specification.forced or ""
        if forced ~= "" then
            local reader = readers[lower(forced)] -- normally forced is already lowered
            tfmdata = reader and reader(specification)
            if not tfmdata then
                report_defining("forced type %a of %a not found",forced,specification.name)
            end
        else
            local sequence = readers.sequence -- can be overloaded so only a shortcut here
            for s=1,#sequence do
                local reader = sequence[s]
                if readers[reader] then -- we skip not loaded readers
                    if trace_defining then
                        report_defining("trying (reader sequence driven) type %a for %a with file %a",reader,specification.name,specification.filename)
                    end
                    tfmdata = readers[reader](specification)
                    if tfmdata then
                        break
                    else
                        specification.filename = nil
                    end
                end
            end
        end
        if tfmdata then
            tfmdata = definers.applypostprocessors(tfmdata)
            checkembedding(tfmdata) -- todo: general postprocessor
            loadedfonts[hash] = tfmdata
            designsizes[specification.hash] = tfmdata.parameters.designsize
            checkfeatures(tfmdata)
        end
    end
    if not tfmdata then
        report_defining("font with asked name %a is not found using lookup %a",specification.name,specification.lookup)
    end
    return tfmdata
end

function constructors.readanddefine(name,size) -- no id -- maybe a dummy first
    local specification = definers.analyze(name,size)
    local method = specification.method
    if method and variants[method] then
        specification = variants[method](specification)
    end
    specification = definers.resolve(specification)
    local hash = constructors.hashinstance(specification)
    local id = definers.registered(hash)
    if not id then
        local tfmdata = definers.loadfont(specification)
        if tfmdata then
            tfmdata.properties.hash = hash
            id = font.define(tfmdata)
            definers.register(tfmdata,id)
        else
            id = 0  -- signal
        end
    end
    return fontdata[id], id
end

-- So far the specifiers. Now comes the real definer. Here we cache based on id's.
-- Here we also intercept the virtual font handler.
--
-- In the previously defined reader (the one resulting in a TFM table) we cached the
-- (scaled) instances. Here we cache them again, but this time based on id. We could
-- combine this in one cache but this does not gain much. By the way, passing id's
-- back to in the callback was introduced later in the development.

function definers.registered(hash)
    local id = internalized[hash]
    return id, id and fontdata[id]
end

function definers.register(tfmdata,id)
    if tfmdata and id then
        local hash = tfmdata.properties.hash
        if not hash then
            report_defining("registering font, id %a, name %a, invalid hash",id,tfmdata.properties.filename or "?")
        elseif not internalized[hash] then
            internalized[hash] = id
            if trace_defining then
                report_defining("registering font, id %s, hash %a",id,hash)
            end
            fontdata[id] = tfmdata
        end
    end
end

function definers.read(specification,size,id) -- id can be optional, name can already be table
    statistics.starttiming(fonts)
    if type(specification) == "string" then
        specification = definers.analyze(specification,size)
    end
    local method = specification.method
    if method and variants[method] then
        specification = variants[method](specification)
    end
    specification = definers.resolve(specification)
    local hash = constructors.hashinstance(specification)
    local tfmdata = definers.registered(hash) -- id
    if tfmdata then
        if trace_defining then
            report_defining("already hashed: %s",hash)
        end
    else
        tfmdata = definers.loadfont(specification) -- can be overloaded
-- put in properties instead
        if tfmdata then
            tfmdata.original = specification.specification
            if trace_defining then
                report_defining("loaded and hashed: %s",hash)
            end
            tfmdata.properties.hash = hash
            if id then
                definers.register(tfmdata,id)
            end
        else
            if trace_defining then
                report_defining("not loaded and hashed: %s",hash)
            end
        end
    end
    if not tfmdata then -- or id?
        report_defining( "unknown font %a, loading aborted",specification.name)
    elseif trace_defining and type(tfmdata) == "table" then
        local properties = tfmdata.properties or { }
        local parameters = tfmdata.parameters or { }
        report_defining("using %a font with id %a, name %a, size %a, bytes %a, encoding %a, fullname %a, filename %a",
            properties.format or "unknown", id or "-", properties.name, parameters.size, properties.encodingbytes,
            properties.encodingname, properties.fullname, basename(properties.filename))
    end
    statistics.stoptiming(fonts)
    return tfmdata
end

function font.getfont(id)
    return fontdata[id] -- otherwise issues
end

-- We overload the <l n='tfm'/> reader.

if not context then
    callbacks.register('define_font', definers.read, "definition of fonts (tfmdata preparation)")
end
