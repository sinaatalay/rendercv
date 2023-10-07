if not modules then modules = { } end modules ['font-con'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- Todo: Enable fixes from the lmt to here. Also in font-oto.lua wrt the changed
-- assignments. (Around texlive 2024 in order not to disturb generic.)

-- some names of table entries will be changed (no _)

local next, tostring, tonumber, rawget = next, tostring, tonumber, rawget
local format, match, lower, gsub, find = string.format, string.match, string.lower, string.gsub, string.find
local sort, insert, concat = table.sort, table.insert, table.concat
local sortedkeys, sortedhash, serialize, fastcopy = table.sortedkeys, table.sortedhash, table.serialize, table.fastcopy
local derivetable = table.derive
local ioflush = io.flush
local round = math.round
local setmetatable, getmetatable, rawget, rawset = setmetatable, getmetatable, rawget, rawset

local trace_defining  = false  trackers.register("fonts.defining",  function(v) trace_defining = v end)
local trace_scaling   = false  trackers.register("fonts.scaling",   function(v) trace_scaling  = v end)

local report_defining = logs.reporter("fonts","defining")

-- Watch out: no negative depths and negative heights are permitted in regular
-- fonts. Also, the code in LMTX is a bit different. Here we only implement a
-- few helper functions.

local fonts                  = fonts
local constructors           = fonts.constructors or { }
fonts.constructors           = constructors
local handlers               = fonts.handlers or { } -- can have preloaded tables
fonts.handlers               = handlers

local allocate               = utilities.storage.allocate
local setmetatableindex      = table.setmetatableindex

-- will be directives

constructors.dontembed       = allocate()
constructors.namemode        = "fullpath" -- will be a function

constructors.version         = 1.01
constructors.cache           = containers.define("fonts", "constructors", constructors.version, false)

constructors.privateoffset   = fonts.privateoffsets.textbase or 0xF0000
constructors.cacheintex      = true -- so we see the original table in fonts.font

constructors.addtounicode    = true

constructors.fixprotrusion   = true

-- This might become an interface:

local designsizes           = allocate()
constructors.designsizes    = designsizes
local loadedfonts           = allocate()
constructors.loadedfonts    = loadedfonts

-- We need to normalize the scale factor (in scaled points). This has to do with the
-- fact that TeX uses a negative multiple of 1000 as a signal for a font scaled
-- based on the design size.

local factors = {
    pt = 65536.0,
    bp = 65781.8,
}

function constructors.setfactor(f)
    constructors.factor = factors[f or 'pt'] or factors.pt
end

constructors.setfactor()

function constructors.scaled(scaledpoints, designsize) -- handles designsize in sp as well
    if scaledpoints < 0 then
        local factor = constructors.factor
        if designsize then
            if designsize > factor then -- or just 1000 / when? mp?
                return (- scaledpoints/1000) * designsize -- sp's
            else
                return (- scaledpoints/1000) * designsize * factor
            end
        else
            return (- scaledpoints/1000) * 10 * factor
        end
    else
        return scaledpoints
    end
end

function constructors.getprivate(tfmdata)
    local properties = tfmdata.properties
    local private = properties.private
    properties.private = private + 1
    return private
end

function constructors.setmathparameter(tfmdata,name,value)
    local m = tfmdata.mathparameters
    local c = tfmdata.MathConstants
    if m then
        m[name] = value
    end
    if c and c ~= m then
        c[name] = value
    end
end

function constructors.getmathparameter(tfmdata,name)
    local p = tfmdata.mathparameters or tfmdata.MathConstants
    if p then
        return p[name]
    end
end

-- Beware, the boundingbox is passed as reference so we may not overwrite it in the
-- process; numbers are of course copies. Here 65536 equals 1pt. (Due to excessive
-- memory usage in CJK fonts, we no longer pass the boundingbox.)
--
-- The scaler is only used for OTF and AFM and virtual fonts. If a virtual font has
-- italic correction make sure to set the hasitalics flag. Some more flags will be
-- added in the future.
--
-- The reason why the scaler was originally split, is that for a while we
-- experimented with a helper function. However, in practice the API calls are too
-- slow to make this profitable and the Lua based variant was just faster. A days
-- wasted day but an experience richer.

function constructors.cleanuptable(tfmdata)
    -- This no longer makes sense because the addition of font.getcopy and its
    -- possible usage in generic implicates that we need to return the whole
    -- lot now.
end

-- experimental, sharing kerns (unscaled and scaled) saves memory
-- local sharedkerns, basekerns = constructors.check_base_kerns(tfmdata)
-- loop over descriptions (afm and otf have descriptions, tfm not)
-- there is no need (yet) to assign a value to chr.tonunicode

-- constructors.prepare_base_kerns(tfmdata) -- optimalization

-- we have target.name=metricfile and target.fullname=RealName and target.filename=diskfilename
-- when collapsing fonts, luatex looks as both target.name and target.fullname as ttc files
-- can have multiple subfonts

function constructors.calculatescale(tfmdata,scaledpoints)
    local parameters = tfmdata.parameters
    if scaledpoints < 0 then
        scaledpoints = (- scaledpoints/1000) * (tfmdata.designsize or parameters.designsize) -- already in sp
    end
    return scaledpoints, scaledpoints / (parameters.units or 1000) -- delta
end

local unscaled = {
    ScriptPercentScaleDown          = true,
    ScriptScriptPercentScaleDown    = true,
    RadicalDegreeBottomRaisePercent = true,
    NoLimitSupFactor                = true,
    NoLimitSubFactor                = true,
}

function constructors.assignmathparameters(target,original) -- simple variant, not used in context
    -- when a tfm file is loaded, it has already been scaled
    -- and it never enters the scaled so this is otf only and
    -- even then we do some extra in the context math plugins
    local mathparameters = original.mathparameters
    if mathparameters and next(mathparameters) then
        local targetparameters     = target.parameters
        local targetproperties     = target.properties
        local targetmathparameters = { }
        local factor               = targetproperties.math_is_scaled and 1 or targetparameters.factor
        for name, value in next, mathparameters do
            if unscaled[name] then
                targetmathparameters[name] = value
            else
                targetmathparameters[name] = value * factor
            end
        end
        if not targetmathparameters.FractionDelimiterSize then
            targetmathparameters.FractionDelimiterSize = 1.01 * targetparameters.size
        end
        if not mathparameters.FractionDelimiterDisplayStyleSize then
            targetmathparameters.FractionDelimiterDisplayStyleSize = 2.40 * targetparameters.size
        end
        if not targetmathparameters.SpaceBeforeScript then
            targetmathparameters.SpaceBeforeScript = targetmathparameters.SpaceAfterScript
        end
        target.mathparameters = targetmathparameters
    end
end

function constructors.beforecopyingcharacters(target,original)
    -- can be used for additional tweaking
end

function constructors.aftercopyingcharacters(target,original)
    -- can be used for additional tweaking
end

-- It's probably ok to hash just the indices because there is not that much
-- chance that one will shift slots and leave the others unset then. Anyway,
-- there is of course some overhead here, but it might as well get compensated
-- by less time spent on including the font resource twice. For the moment
-- we default to false, so a macro package has to enable it explicitly. In
-- LuaTeX the fullname is used to identify a font as being unique.

local nofinstances = 0
local instances    = setmetatableindex(function(t,k)
    nofinstances = nofinstances + 1
    t[k] = nofinstances
    return nofinstances
end)

function constructors.trytosharefont(target,tfmdata)
    local properties = target.properties
    local instance   = properties.instance
    if instance then
        local fullname = target.fullname
        local fontname = target.fontname
        local psname   = target.psname
        local format   = tfmdata.properties.format
        if format == "opentype" then
            target.streamprovider = 1
        elseif format == "truetype" then
            target.streamprovider = 2
        else
            target.streamprovider = 0
        end
        if target.streamprovider > 0 then
            if fullname then
                fullname = fullname .. ":" .. instances[instance]
                target.fullname = fullname
            end
            if fontname then
                fontname = fontname .. ":" .. instances[instance]
                target.fontname = fontname
            end
            if psname then
                psname = psname   .. ":" .. instances[instance]
                target.psname = psname
            end
        end
    end
end

local synonyms = {
    exheight      = "x_height",
    xheight       = "x_height",
    ex            = "x_height",
    emwidth       = "quad",
    em            = "quad",
    spacestretch  = "space_stretch",
    stretch       = "space_stretch",
    spaceshrink   = "space_shrink",
    shrink        = "space_shrink",
    extraspace    = "extra_space",
    xspace        = "extra_space",
    slantperpoint = "slant",
}

function constructors.enhanceparameters(parameters)
    local mt = getmetatable(parameters)
    local getter = function(t,k)
        if not k then
            return nil
        end
        local s = synonyms[k]
        if s then
            return rawget(t,s) or (mt and mt[s]) or nil
        end
        if k == "spacing" then
            return {
                width   = t.space,
                stretch = t.space_stretch,
                shrink  = t.space_shrink,
                extra   = t.extra_space,
            }
        end
        return mt and mt[k] or nil
    end
    local setter = function(t,k,v)
        if not k then
            return 0
        end
        local s = synonyms[k]
        if s then
            rawset(t,s,v)
        elseif k == "spacing" then
            if type(v) == "table" then
                rawset(t,"space",v.width or 0)
                rawset(t,"space_stretch",v.stretch or 0)
                rawset(t,"space_shrink",v.shrink or 0)
                rawset(t,"extra_space",v.extra or 0)
            end
        else
            rawset(t,k,v)
        end
    end
    setmetatable(parameters, {
        __index    = getter,
        __newindex = setter,
    })
end

local function mathkerns(v,vdelta)
    local k = { }
    for i=1,#v do
        local entry  = v[i]
        local height = entry.height
        local kern   = entry.kern
        k[i] = {
            height = height and vdelta*height or 0,
            kern   = kern   and vdelta*kern   or 0,
        }
    end
    return k
end

local psfake = 0

local function fixedpsname(psname,fallback)
    local usedname = psname
    if psname and psname ~= "" then
        if find(psname," ",1,true) then
            usedname = gsub(psname,"[%s]+","-")
        else
            -- we assume that the name is sane enough (we might sanitize completely some day)
        end
    elseif not fallback or fallback == "" then
        psfake = psfake + 1
        psname = "fakename-" .. psfake
    else
        -- filenames can be a mess so we do a drastic cleanup
        psname   = fallback
        usedname = gsub(psname,"[^a-zA-Z0-9]+","-")
    end
    return usedname, psname ~= usedname
end

function constructors.scale(tfmdata,specification)
    local target         = { } -- the new table
    --
    if tonumber(specification) then
        specification    = { size = specification }
    end
    target.specification = specification
    --
    local scaledpoints   = specification.size
    local relativeid     = specification.relativeid
    --
    local properties     = tfmdata.properties     or { }
    local goodies        = tfmdata.goodies        or { }
    local resources      = tfmdata.resources      or { }
    local descriptions   = tfmdata.descriptions   or { } -- bad news if empty
    local characters     = tfmdata.characters     or { } -- bad news if empty
    local changed        = tfmdata.changed        or { } -- for base mode
    local shared         = tfmdata.shared         or { }
    local parameters     = tfmdata.parameters     or { }
    local mathparameters = tfmdata.mathparameters or { }
    --
    local targetcharacters     = { }
    local targetdescriptions   = derivetable(descriptions)
    local targetparameters     = derivetable(parameters)
    local targetproperties     = derivetable(properties)
    local targetgoodies        = goodies                        -- we need to loop so no metatable
    target.characters          = targetcharacters
    target.descriptions        = targetdescriptions
    target.parameters          = targetparameters
 -- target.mathparameters      = targetmathparameters           -- happens elsewhere
    target.properties          = targetproperties
    target.goodies             = targetgoodies
    target.shared              = shared
    target.resources           = resources
    target.unscaled            = tfmdata                        -- the original unscaled one
    --
    -- specification.mathsize : 1=text 2=script 3=scriptscript
    -- specification.textsize : natural (text)size
    -- parameters.mathsize    : 1=text 2=script 3=scriptscript >1000 enforced size (feature value other than yes)
    --
    local mathsize    = tonumber(specification.mathsize) or 0
    local textsize    = tonumber(specification.textsize) or scaledpoints
 -- local forcedsize  = tonumber(parameters.mathsize   ) or 0 -- can be set by the feature "mathsize"
    local extrafactor = tonumber(specification.factor  ) or 1
 -- if context then
 --     -- do nothing, as we moved this upstream
 -- elseif (mathsize == 2 or forcedsize == 2) and parameters.scriptpercentage then
 --     scaledpoints = parameters.scriptpercentage * textsize / 100
 -- elseif (mathsize == 3 or forcedsize == 3) and parameters.scriptscriptpercentage then
 --     scaledpoints = parameters.scriptscriptpercentage * textsize / 100
 -- elseif forcedsize > 1000 then -- safeguard
 --     scaledpoints = forcedsize
 -- end
    targetparameters.mathsize    = mathsize    -- context specific
    targetparameters.textsize    = textsize    -- context specific
 -- targetparameters.forcedsize  = forcedsize  -- context specific
    targetparameters.extrafactor = extrafactor -- context specific
    --
    local addtounicode  = constructors.addtounicode
    --
    local tounicode     = fonts.mappings.tounicode
    local unknowncode   = tounicode(0xFFFD)
    --
    local defaultwidth  = resources.defaultwidth  or 0
    local defaultheight = resources.defaultheight or 0
    local defaultdepth  = resources.defaultdepth or 0
    local units         = parameters.units or 1000
    --
    -- boundary keys are no longer needed as we now have a string 'right_boundary'
    -- that can be used in relevant tables (kerns and ligatures) ... not that I ever
    -- used them
    --
 -- boundarychar_label = 0,     -- not needed
 -- boundarychar       = 65536, -- there is now a string 'right_boundary'
 -- false_boundarychar = 65536, -- produces invalid tfm in luatex
    --
    targetproperties.language   = properties.language or "dflt" -- inherited
    targetproperties.script     = properties.script   or "dflt" -- inherited
    targetproperties.mode       = properties.mode     or "base" -- inherited
    targetproperties.method     = properties.method
    --
    local askedscaledpoints   = scaledpoints
    local scaledpoints, delta = constructors.calculatescale(tfmdata,scaledpoints,nil,specification) -- no shortcut, dan be redefined
    --
    local hdelta         = delta
    local vdelta         = delta
    --
    target.designsize    = parameters.designsize -- not really needed so it might become obsolete
    target.units         = units
    target.units_per_em  = units                 -- just a trigger for the backend
    --
    local direction      = properties.direction or tfmdata.direction or 0 -- pointless, as we don't use omf fonts at all
    target.direction     = direction
    properties.direction = direction
    --
    target.size          = scaledpoints
    --
    target.encodingbytes = properties.encodingbytes or 1
    target.subfont       = properties.subfont
    target.embedding     = properties.embedding or "subset"
    target.tounicode     = 1
    target.cidinfo       = properties.cidinfo
    target.format        = properties.format
    target.cache         = constructors.cacheintex and "yes" or "renew"
    --
    local original = properties.original or tfmdata.original
    local fontname = properties.fontname or tfmdata.fontname
    local fullname = properties.fullname or tfmdata.fullname
    local filename = properties.filename or tfmdata.filename
    local psname   = properties.psname   or tfmdata.psname
    local name     = properties.name     or tfmdata.name
    --
    -- The psname used in pdf file as well as for selecting subfont in ttc although
    -- we don't need that subfont look up here (mapfile stuff).
    --
    local psname, psfixed = fixedpsname(psname,fontname or fullname or file.nameonly(filename))
    --
    target.original = original
    target.fontname = fontname
    target.fullname = fullname
    target.filename = filename
    target.psname   = psname
    target.name     = name
    --
    properties.fontname = fontname
    properties.fullname = fullname
    properties.filename = filename
    properties.psname   = psname
    properties.name     = name
    -- expansion (hz)
    local expansion = parameters.expansion
    if expansion then
        target.stretch = expansion.stretch
        target.shrink  = expansion.shrink
        target.step    = expansion.step
    end
    -- slanting
    local slantfactor = parameters.slantfactor or 0
    if slantfactor ~= 0 then
        target.slant = slantfactor * 1000
    else
        target.slant = 0
    end
    -- widening
    local extendfactor = parameters.extendfactor or 0
    if extendfactor ~= 0 and extendfactor ~= 1 then
        hdelta = hdelta * extendfactor
        target.extend = extendfactor * 1000
    else
        target.extend = 1000 -- extent ?
    end
    -- squeezing
    local squeezefactor = parameters.squeezefactor or 0
    if squeezefactor ~= 0 and squeezefactor ~= 1 then
        vdelta = vdelta * squeezefactor
        target.squeeze = squeezefactor * 1000
    else
        target.squeeze = 1000 -- extent ?
    end
    -- effects
    local mode = parameters.mode or 0
    if mode ~= 0 then
        target.mode = mode
    end
    local width = parameters.width or 0
    if width ~= 0 then
        target.width = width * delta * 1000 / 655360
    end
    --
    targetparameters.factor       = delta
    targetparameters.hfactor      = hdelta
    targetparameters.vfactor      = vdelta
    targetparameters.size         = scaledpoints
    targetparameters.units        = units
    targetparameters.scaledpoints = askedscaledpoints
    targetparameters.mode         = mode
    targetparameters.width        = width
    --
    local isvirtual        = properties.virtualized or tfmdata.type == "virtual"
    local hasquality       = parameters.expansion or parameters.protrusion
    local hasitalics       = properties.hasitalics
    local autoitalicamount = properties.autoitalicamount
    local stackmath        = not properties.nostackmath
    local haskerns         = properties.haskerns     or properties.mode == "base" -- we can have afm in node mode
    local hasligatures     = properties.hasligatures or properties.mode == "base" -- we can have afm in node mode
    local realdimensions   = properties.realdimensions
    local writingmode      = properties.writingmode or "horizontal"
    local identity         = properties.identity or "horizontal"
    local vfonts = target.fonts
    if vfonts and #vfonts > 0 then
        target.fonts = fastcopy(vfonts) -- maybe we virtualize more afterwards
    elseif isvirtual then
        target.fonts = { { id = 0 } } -- catch error
    end
    --
    if changed and not next(changed) then
        changed = false
    end
    --
    target.type        = isvirtual and "virtual" or "real"
    target.writingmode = writingmode == "vertical" and "vertical" or "horizontal"
    target.identity    = identity == "vertical" and "vertical" or "horizontal"
    --
    target.postprocessors = tfmdata.postprocessors
    --
    local targetslant         = (parameters.slant         or parameters[1] or 0) * factors.pt -- per point
    local targetspace         = (parameters.space         or parameters[2] or 0) * hdelta
    local targetspace_stretch = (parameters.space_stretch or parameters[3] or 0) * hdelta
    local targetspace_shrink  = (parameters.space_shrink  or parameters[4] or 0) * hdelta
    local targetx_height      = (parameters.x_height      or parameters[5] or 0) * vdelta
    local targetquad          = (parameters.quad          or parameters[6] or 0) * hdelta
    local targetextra_space   = (parameters.extra_space   or parameters[7] or 0) * hdelta
    --
    targetparameters.slant         = targetslant -- slantperpoint
    targetparameters.space         = targetspace
    targetparameters.space_stretch = targetspace_stretch
    targetparameters.space_shrink  = targetspace_shrink
    targetparameters.x_height      = targetx_height
    targetparameters.quad          = targetquad
    targetparameters.extra_space   = targetextra_space
    --
    local hshift = parameters.hshift
    if hshift then
        targetparameters.hshift = delta * hshift
    end
    local vshift = parameters.vshift
    if vshift then
        targetparameters.vshift = delta * vshift
    end
    --
    local ascender = parameters.ascender
    if ascender then
        targetparameters.ascender  = delta * ascender
    end
    local descender = parameters.descender
    if descender then
        targetparameters.descender = delta * descender
    end
    --
    constructors.enhanceparameters(targetparameters) -- official copies for us, now virtual
    --
    -- I need to fix this in luatex ... get rid of quad there so that we can omit this here.
    --
    local protrusionfactor = constructors.fixprotrusion and ((targetquad ~= 0 and 1000/targetquad) or 1) or 1
    --
    local scaledwidth      = defaultwidth  * hdelta
    local scaledheight     = defaultheight * vdelta
    local scaleddepth      = defaultdepth  * vdelta
    --
    local hasmath = (properties.hasmath or next(mathparameters)) and true
    --
    if hasmath then
        constructors.assignmathparameters(target,tfmdata) -- does scaling and whatever is needed
        properties.hasmath       = true
        target.nomath            = false
        target.MathConstants     = target.mathparameters
        --
        local oldmath            = properties.oldmath
        targetproperties.oldmath = oldmath
        target.oldmath           = oldmath
    else
        properties.hasmath       = false
        target.nomath            = true
        target.mathparameters    = nil -- nop
    end
    --
    -- Here we support some context specific trickery (this might move to a plugin). During the
    -- transition to opentype the engine had troubles with italics so we had some additional code
    -- for fixing that. In node mode (text) we don't care much if italics gets passed because
    -- the engine does nothign with them then.
    --
    if hasmath then
        local mathitalics = properties.mathitalics
        if mathitalics == false then
            if trace_defining then
                report_defining("%s italics %s for font %a, fullname %a, filename %a","math",hasitalics and "ignored" or "disabled",name,fullname,filename)
            end
            hasitalics       = false
            autoitalicamount = false
        end
    else
        local textitalics = properties.textitalics
        if textitalics == false then
            if trace_defining then
                report_defining("%s italics %s for font %a, fullname %a, filename %a","text",hasitalics and "ignored" or "disabled",name,fullname,filename)
            end
            hasitalics       = false
            autoitalicamount = false
        end
    end
    --
    -- end of context specific trickery
    --
    if trace_defining then
        report_defining("defining tfm, name %a, fullname %a, filename %a, %spsname %a, hscale %a, vscale %a, math %a, italics %a",
            name,fullname,filename,psfixed and "(fixed) " or "",psname,hdelta,vdelta,
            hasmath and "enabled" or "disabled",hasitalics and "enabled" or "disabled")
    end
    --
    constructors.beforecopyingcharacters(target,tfmdata)
    --
    local sharedkerns = { }
    --
    -- we can have a dumb mode (basemode without math etc) that skips most
    --
    for unicode, character in next, characters do
        local chr, description, index
        if changed then
            local c = changed[unicode]
            if c and c ~= unicode then
             -- local cc = changed[c]
             -- if cc then
             --     while cc do
             --         c = cc
             --         cc = changed[c]
             --     end
             -- end
                -- check not needed:
                if c then
                    description = descriptions[c] or descriptions[unicode] or character
                    character   = characters[c] or character
                    index       = description.index or c
                else
                    description = descriptions[unicode] or character
                    index       = description.index or unicode
                end
            else
                description = descriptions[unicode] or character
                index       = description.index or unicode
            end
        else
            description = descriptions[unicode] or character
            index       = description.index or unicode
        end
        local width     = description.width
        local height    = description.height
        local depth     = description.depth
        local isunicode = description.unicode
        if realdimensions then
            -- this is mostly for checking issues
            if not height or height == 0 then
                local bb = description.boundingbox
                local ht =  bb[4]
                if ht ~= 0 then
                    height = ht
                end
                if not depth or depth == 0 then
                    local dp = -bb[2]
                    if dp ~= 0 then
                        depth = dp
                    end
                end
            elseif not depth or depth == 0 then
                local dp = -description.boundingbox[2]
                if dp ~= 0 then
                    depth = dp
                end
            end
        end
        if width  then width  = hdelta*width  else width  = scaledwidth  end
        if height then height = vdelta*height else height = scaledheight end
    --  if depth  then depth  = vdelta*depth  else depth  = scaleddepth  end
        if depth and depth ~= 0 then
            depth = delta*depth
            if isunicode then
                chr = {
                    index   = index,
                    height  = height,
                    depth   = depth,
                    width   = width,
                    unicode = isunicode,
                }
            else
                chr = {
                    index  = index,
                    height = height,
                    depth  = depth,
                    width  = width,
                }
            end
        else
            if isunicode then
                chr = {
                    index   = index,
                    height  = height,
                    width   = width,
                    unicode = isunicode,
                }
            else
                chr = {
                    index  = index,
                    height = height,
                    width  = width,
                }
            end
        end
        if addtounicode then
            chr.tounicode = isunicode and tounicode(isunicode) or unknowncode
        end
        if hasquality then
            -- we could move these calculations elsewhere (saves calculations)
            local ve = character.expansion_factor
            if ve then
                chr.expansion_factor = ve*1000 -- expansionfactor, hm, can happen elsewhere
            end
            local vl = character.left_protruding
            if vl then
                chr.left_protruding  = protrusionfactor*width*vl
            end
            local vr = character.right_protruding
            if vr then
                chr.right_protruding  = protrusionfactor*width*vr
            end
        end
        --
        if hasmath then
            --
            -- todo, just operate on descriptions.math
            local vn = character.next
            if vn then
                chr.next = vn
            else
                local vv = character.vert_variants
                if vv then
                    local t = { }
                    for i=1,#vv do
                        local vvi = vv[i]
                        local s = vvi["start"]   or 0
                        local e = vvi["end"]     or 0
                        local a = vvi["advance"] or 0
                        t[i] = { -- zero check nicer for 5.3
                            ["start"]    = s == 0 and 0 or s * vdelta,
                            ["end"]      = e == 0 and 0 or e * vdelta,
                            ["advance"]  = a == 0 and 0 or a * vdelta,
                            ["extender"] = vvi["extender"],
                            ["glyph"]    = vvi["glyph"],
                        }
                    end
                    chr.vert_variants = t
                else
                    local hv = character.horiz_variants
                    if hv then
                        local t = { }
                        for i=1,#hv do
                            local hvi = hv[i]
                            local s = hvi["start"]   or 0
                            local e = hvi["end"]     or 0
                            local a = hvi["advance"] or 0
                            t[i] = { -- zero check nicer for 5.3
                                ["start"]    = s == 0 and 0 or s * hdelta,
                                ["end"]      = e == 0 and 0 or e * hdelta,
                                ["advance"]  = a == 0 and 0 or a * hdelta,
                                ["extender"] = hvi["extender"],
                                ["glyph"]    = hvi["glyph"],
                            }
                        end
                        chr.horiz_variants = t
                    end
                end
                -- todo also check mathitalics (or that one can go away)
            end
            local vi = character.vert_italic
            if vi and vi ~= 0 then
                chr.vert_italic = vi*hdelta
            end
            local va = character.accent
            if va then
                chr.top_accent = vdelta*va
            end
            if stackmath then
                local mk = character.mathkerns
                if mk then
                    local tr = mk.topright
                    local tl = mk.topleft
                    local br = mk.bottomright
                    local bl = mk.bottomleft
                    chr.mathkern = { -- singular -> should be patched in luatex !
                        top_right    = tr and mathkerns(tr,vdelta) or nil,
                        top_left     = tl and mathkerns(tl,vdelta) or nil,
                        bottom_right = br and mathkerns(br,vdelta) or nil,
                        bottom_left  = bl and mathkerns(bl,vdelta) or nil,
                    }
                end
            end
            if hasitalics then
                local vi = character.italic
                if vi and vi ~= 0 then
                    chr.italic = vi*hdelta
                end
            end
        elseif autoitalicamount then -- itlc feature
            local vi = description.italic
            if not vi then
                local bb = description.boundingbox
                if bb then
                    local vi = bb[3] - description.width + autoitalicamount
                    if vi > 0 then -- < 0 indicates no overshoot or a very small auto italic
                        chr.italic = vi*hdelta
                    end
                else
                 -- report_defining("no boundingbox for character %C in font %a, fullname %a, filename %a",unicode,name,fullname,filename)
                end
            elseif vi ~= 0 then
                chr.italic = vi*hdelta
            end
        elseif hasitalics then -- unlikely
            local vi = character.italic
            if vi and vi ~= 0 then
                chr.italic = vi*hdelta
            end
        end
        if haskerns then
            local vk = character.kerns
            if vk then
                local s = sharedkerns[vk]
                if not s then
                    s = { }
                    for k,v in next, vk do s[k] = v*hdelta end
                    sharedkerns[vk] = s
                end
                chr.kerns = s
            end
        end
        if hasligatures then
            local vl = character.ligatures
            if vl then
                if true then
                    chr.ligatures = vl -- shared
                else
                    local tt = { }
                    for i, l in next, vl do
                        tt[i] = l
                    end
                    chr.ligatures = tt
                end
            end
        end
        if isvirtual then
            local vc = character.commands
            if vc then
                -- we assume non scaled commands here
                -- tricky .. we need to scale pseudo math glyphs too
                -- which is why we deal with rules too
                local ok = false
                for i=1,#vc do
                    local key = vc[i][1]
                    if key == "right" or key == "down" or key == "rule" then
                        ok = true
                        break
                    end
                end
                if ok then
                    local tt = { }
                    for i=1,#vc do
                        local ivc = vc[i]
                        local key = ivc[1]
                        if key == "right" then
                            tt[i] = { key, ivc[2]*hdelta }
                        elseif key == "down" then
                            tt[i] = { key, ivc[2]*vdelta }
                        elseif key == "rule" then
                            tt[i] = { key, ivc[2]*vdelta, ivc[3]*hdelta }
                        else -- not comment
                            tt[i] = ivc -- shared since in cache and untouched
                        end
                    end
                    chr.commands = tt
                else
                    chr.commands = vc
                end
             -- chr.index = nil
            end
        end
        targetcharacters[unicode] = chr
    end
    --
    properties.setitalics = hasitalics -- for postprocessing
    --
    constructors.aftercopyingcharacters(target,tfmdata)
    --
    constructors.trytosharefont(target,tfmdata)
    --
    -- catch inconsistencies
    --
    local vfonts = target.fonts
    if isvirtual or target.type == "virtual" or properties.virtualized then
        properties.virtualized = true
        target.type = "virtual"
        if not vfonts or #vfonts == 0 then
            target.fonts = { { id = 0 } }
        end
    elseif vfonts then
        properties.virtualized = true
        target.type = "virtual"
        if #vfonts == 0 then
            target.fonts = { { id = 0 } }
        end
    end
    --
    return target
end

function constructors.finalize(tfmdata)
    if tfmdata.properties and tfmdata.properties.finalized then
        return
    end
    --
    if not tfmdata.characters then
        return nil
    end
    --
    if not tfmdata.goodies then
        tfmdata.goodies = { } -- context specific
    end
    --
    local parameters = tfmdata.parameters
    if not parameters then
        return nil
    end
    --
    if not parameters.expansion then
        parameters.expansion = {
            stretch = tfmdata.stretch or 0,
            shrink  = tfmdata.shrink  or 0,
            step    = tfmdata.step    or 0,
        }
    end
    --
    if not parameters.size then
        parameters.size = tfmdata.size
    end
    --
    if not parameters.mode then
        parameters.mode = 0
    end
    --
    if not parameters.width then
        parameters.width = 0
    end
    --
    if not parameters.slantfactor then
        parameters.slantfactor = (tfmdata.slant or 0)/1000
    end
    --
    if not parameters.extendfactor then
        parameters.extendfactor = (tfmdata.extend or 1000)/1000
    end
    --
    if not parameters.squeezefactor then
        parameters.squeezefactor = (tfmdata.squeeze or 1000)/1000
    end
    --
    local designsize = parameters.designsize
    if designsize then
        parameters.minsize = tfmdata.minsize or designsize
        parameters.maxsize = tfmdata.maxsize or designsize
    else
        designsize = factors.pt * 10
        parameters.designsize = designsize
        parameters.minsize    = designsize
        parameters.maxsize    = designsize
    end
    parameters.minsize = tfmdata.minsize or parameters.designsize
    parameters.maxsize = tfmdata.maxsize or parameters.designsize
    --
    if not parameters.units then
        parameters.units = tfmdata.units or tfmdata.units_per_em or 1000
    end
    --
    if not tfmdata.descriptions then
        local descriptions = { } -- yes or no
        setmetatableindex(descriptions, function(t,k) local v = { } t[k] = v return v end)
        tfmdata.descriptions = descriptions
    end
    --
    local properties = tfmdata.properties
    if not properties then
        properties = { }
        tfmdata.properties = properties
    end
    --
    if not properties.virtualized then
        properties.virtualized = tfmdata.type == "virtual"
    end
    --
    properties.fontname      = properties.fontname or tfmdata.fontname
    properties.filename      = properties.filename or tfmdata.filename
    properties.fullname      = properties.fullname or tfmdata.fullname
    properties.name          = properties.name     or tfmdata.name
    properties.psname        = properties.psname   or tfmdata.psname
    --
    properties.encodingbytes = tfmdata.encodingbytes or 1
    properties.subfont       = tfmdata.subfont       or nil
    properties.embedding     = tfmdata.embedding     or "subset"
    properties.tounicode     = tfmdata.tounicode     or 1
    properties.cidinfo       = tfmdata.cidinfo       or nil
    properties.format        = tfmdata.format        or "type1"
    properties.direction     = tfmdata.direction     or 0
    properties.writingmode   = tfmdata.writingmode   or "horizontal"
    properties.identity      = tfmdata.identity      or "horizontal"
    properties.usedbitmap    = tfmdata.usedbitmap
    --
    if not tfmdata.resources then
        tfmdata.resources = { }
    end
    if not tfmdata.shared then
        tfmdata.shared = { }
    end
    --
    -- tfmdata.fonts
    -- tfmdata.unscaled
    --
    if not properties.hasmath then
        properties.hasmath = not tfmdata.nomath
    end
    --
    tfmdata.MathConstants    = nil
    tfmdata.postprocessors   = nil
    --
    tfmdata.fontname         = nil
    tfmdata.filename         = nil
    tfmdata.fullname         = nil
    tfmdata.name             = nil -- most tricky part
    tfmdata.psname           = nil
    --
    tfmdata.encodingbytes    = nil
    tfmdata.subfont          = nil
    tfmdata.embedding        = nil
    tfmdata.tounicode        = nil
    tfmdata.cidinfo          = nil
    tfmdata.format           = nil
    tfmdata.direction        = nil
    tfmdata.type             = nil
    tfmdata.nomath           = nil
    tfmdata.designsize       = nil
    --
    tfmdata.size             = nil
    tfmdata.stretch          = nil
    tfmdata.shrink           = nil
    tfmdata.step             = nil
    tfmdata.slant            = nil
    tfmdata.extend           = nil
    tfmdata.squeeze          = nil
    tfmdata.mode             = nil
    tfmdata.width            = nil
    tfmdata.units            = nil
    tfmdata.units_per_em     = nil
    --
    tfmdata.cache            = nil
    --
    properties.finalized     = true
    --
    return tfmdata
end

-- A unique hash value is generated by:

local hashmethods        = { }
constructors.hashmethods = hashmethods

function constructors.hashfeatures(specification) -- will be overloaded
    local features = specification.features
    if features then
        local t, n = { }, 0
        for category, list in sortedhash(features) do
            if next(list) then
                local hasher = hashmethods[category]
                if hasher then
                    local hash = hasher(list)
                    if hash then
                        n = n + 1
                        t[n] = category .. ":" .. hash
                    end
                end
            end
        end
        if n > 0 then
            return concat(t," & ")
        end
    end
    return "unknown"
end

hashmethods.normal = function(list)
    local s = { }
    local n = 0
    for k, v in next, list do
        if not k then
            -- no need to add to hash
        elseif k == "number" or k == "features" then
            -- no need to add to hash (maybe we need a skip list)
        else
            n = n + 1
            if type(v) == "table" then
                -- table.sequenced
                local t = { }
                local m = 0
                for k, v in next, v do
                    m = m + 1
                    t[m] = k .. '=' .. tostring(v)
                end
                sort(t)
                s[n] = k .. '={' .. concat(t,",") .. "}"
            else
                s[n] = k .. '=' .. tostring(v)
            end
        end
    end
    if n > 0 then
        sort(s)
        return concat(s,"+")
    end
end

-- In principle we can share tfm tables when we are in need for a font, but then we
-- need to define a font switch as an id/attr switch which is no fun, so in that
-- case users can best use dynamic features ... so, we will not use that speedup.
-- Okay, when we get rid of base mode we can optimize even further by sharing, but
-- then we loose our testcases for LuaTeX.

function constructors.hashinstance(specification,force)
    local hash      = specification.hash
    local size      = specification.size
    local fallbacks = specification.fallbacks
    if force or not hash then
        hash = constructors.hashfeatures(specification)
        specification.hash = hash
    end
    if size < 1000 and designsizes[hash] then
        size = round(constructors.scaled(size,designsizes[hash]))
    else
        size = round(size)
    end
    specification.size = size
    if fallbacks then
        return hash .. ' @ ' .. size .. ' @ ' .. fallbacks
    else
        return hash .. ' @ ' .. size
    end
end

function constructors.setname(tfmdata,specification) -- todo: get specification from tfmdata
    if constructors.namemode == "specification" then
        -- not to be used in context !
        local specname = specification.specification
        if specname then
            tfmdata.properties.name = specname
            if trace_defining then
                report_otf("overloaded fontname %a",specname)
            end
        end
    end
end

function constructors.checkedfilename(data)
    local foundfilename = data.foundfilename
    if not foundfilename then
        local askedfilename = data.filename or ""
        if askedfilename ~= "" then
            askedfilename = resolvers.resolve(askedfilename) -- no shortcut
            foundfilename = resolvers.findbinfile(askedfilename,"") or ""
            if foundfilename == "" then
                report_defining("source file %a is not found",askedfilename)
                foundfilename = resolvers.findbinfile(file.basename(askedfilename),"") or ""
                if foundfilename ~= "" then
                    report_defining("using source file %a due to cache mismatch",foundfilename)
                end
            end
        end
        data.foundfilename = foundfilename
    end
    return foundfilename
end

local formats = allocate()
fonts.formats = formats

setmetatableindex(formats, function(t,k)
    local l = lower(k)
    if rawget(t,k) then
        t[k] = l
        return l
    end
    return rawget(t,file.suffix(l))
end)

do

    local function setindeed(mode,source,target,group,name,position)
        local action = source[mode]
        if not action then
            return
        end
        local t = target[mode]
        if not t then
            report_defining("fatal error in setting feature %a, group %a, mode %a",name,group,mode)
            os.exit()
        elseif position then
            -- todo: remove existing
            insert(t, position, { name = name, action = action })
        else
            for i=1,#t do
                local ti = t[i]
                if ti.name == name then
                    ti.action = action
                    return
                end
            end
            insert(t, { name = name, action = action })
        end
    end

    local function set(group,name,target,source)
        target = target[group]
        if not target then
            report_defining("fatal target error in setting feature %a, group %a",name,group)
            os.exit()
        end
        local source = source[group]
        if not source then
            report_defining("fatal source error in setting feature %a, group %a",name,group)
            os.exit()
        end
        local position = source.position
        setindeed("node",source,target,group,name,position)
        setindeed("base",source,target,group,name,position)
        setindeed("plug",source,target,group,name,position)
    end

    local function register(where,specification)
        local name = specification.name
        if name and name ~= "" then
            local default      = specification.default
            local description  = specification.description
            local initializers = specification.initializers
            local processors   = specification.processors
            local manipulators = specification.manipulators
            local modechecker  = specification.modechecker
            if default then
                where.defaults[name] = default
            end
            if description and description ~= "" then
                where.descriptions[name] = description
            end
            if initializers then
                set('initializers',name,where,specification)
            end
            if processors then
                set('processors',  name,where,specification)
            end
            if manipulators then
                set('manipulators',name,where,specification)
            end
            if modechecker then
               where.modechecker = modechecker
            end
        end
    end

    constructors.registerfeature = register

    function constructors.getfeatureaction(what,where,mode,name)
        what = handlers[what].features
        if what then
            where = what[where]
            if where then
                mode = where[mode]
                if mode then
                    for i=1,#mode do
                        local m = mode[i]
                        if m.name == name then
                            return m.action
                        end
                    end
                end
            end
        end
    end

    local newfeatures        = { }
    constructors.newfeatures = newfeatures -- downward compatible
    constructors.features    = newfeatures

    local function setnewfeatures(what)
        local handler  = handlers[what]
        local features = handler.features
        if not features then
            local tables     = handler.tables     -- can be preloaded
            local statistics = handler.statistics -- can be preloaded
            features = allocate {
                defaults     = { },
                descriptions = tables and tables.features or { },
                used         = statistics and statistics.usedfeatures or { },
                initializers = { base = { }, node = { }, plug = { } },
                processors   = { base = { }, node = { }, plug = { } },
                manipulators = { base = { }, node = { }, plug = { } },
            }
            features.register = function(specification) return register(features,specification) end
            handler.features = features -- will also become hidden
        end
        return features
    end

    setmetatable(newfeatures, {
        __call  = function(t,k) local v = t[k] return v end,
        __index = function(t,k) local v = setnewfeatures(k) t[k] = v return v end,
    })

end

do

    local newhandler        = { }
    constructors.handlers   = newhandler -- downward compatible
    constructors.newhandler = newhandler

    local function setnewhandler(what) -- could be a metatable newindex
        local handler = handlers[what]
        if not handler then
            handler = { }
            handlers[what] = handler
        end
        return handler
    end

    setmetatable(newhandler, {
        __call  = function(t,k) local v = t[k] return v end,
        __index = function(t,k) local v = setnewhandler(k) t[k] = v return v end,
    })

end

do
    -- a pitty that we need to be generic as we have nicer mechanisms for this ...

    local newenhancer        = { }
    constructors.enhancers   = newenhancer
    constructors.newenhancer = newenhancer

    local function setnewenhancer(format)

        local handler   = handlers[format]
        local enhancers = handler.enhancers

        if not enhancers then

            local actions  = allocate() -- no need to allocate thee
            local before   = allocate()
            local after    = allocate()
            local order    = allocate()
            local known    = { }
            local nofsteps = 0
            local patches  = { before = before, after = after }

            local trace   = false
            local report  = logs.reporter("fonts",format .. " enhancing")

            trackers.register(format .. ".loading", function(v) trace = v end)

            local function enhance(name,data,filename,raw)
                local enhancer = actions[name]
                if enhancer then
                    if trace then
                        report("apply enhancement %a to file %a",name,filename)
                        ioflush()
                    end
                    enhancer(data,filename,raw)
                else
                    -- no message as we can have private ones
                end
            end

            local function apply(data,filename,raw)
                local basename = file.basename(lower(filename))
                if trace then
                    report("%s enhancing file %a","start",filename)
                end
                ioflush() -- we want instant messages
                for e=1,nofsteps do
                    local enhancer = order[e]
                    local b = before[enhancer]
                    if b then
                        for pattern, action in next, b do
                            if find(basename,pattern) then
                                action(data,filename,raw)
                            end
                        end
                    end
                    enhance(enhancer,data,filename,raw) -- we have one installed: check extra features
                    local a = after[enhancer]
                    if a then
                        for pattern, action in next, a do
                            if find(basename,pattern) then
                                action(data,filename,raw)
                            end
                        end
                    end
                    ioflush() -- we want instant messages
                end
                if trace then
                    report("%s enhancing file %a","stop",filename)
                end
                ioflush() -- we want instant messages
            end

            local function register(what,action)
                if action then
                    if actions[what] then
                        -- overloading, e.g."check extra features"
                    else
                        nofsteps        = nofsteps + 1
                        order[nofsteps] = what
                        known[what]     = nofsteps
                    end
                    actions[what] = action
                else
                    report("bad enhancer %a",what)
                end
            end

            -- We used to have a lot of enhancers but no longer with the new font loader. The order of enhancers
            -- is the order of definition. The before/after patches are there for old times sake and happen
            -- before or after a (named) enhancer. An example of a set enhancer is "check extra features" so one
            -- one set patches before or after that is applied. Unknown enhancers are auto-registered. It's a bit
            -- messy but we keep it for compatibility reasons.
            --
            -- fonts.handlers.otf.enhancers.patches.register("before","some patches","somefont",function(data,filename)
            --     print("!!!!!!!") -- before | after
            -- end)
            --
            -- fonts.handlers.otf.enhancers.register("more patches",function(data,filename)
            --     print("???????") -- enhance
            -- end)

            local function patch(what,where,pattern,action)
                local pw = patches[what]
                if pw then
                    local ww = pw[where]
                    if ww then
                        ww[pattern] = action
                    else
                        pw[where] = { [pattern] = action }
                        if not known[where] then
                            nofsteps        = nofsteps + 1
                            order[nofsteps] = where
                            known[where]    = nofsteps
                        end
                    end
                end
            end

            enhancers = {
                register = register,
                apply    = apply,
                patch    = patch,
                report   = report,
                patches  = {
                    register = patch,
                    report   = report,
                }, -- for old times sake
            }

            handler.enhancers = enhancers
        end
        return enhancers
    end

    setmetatable(newenhancer, {
        __call  = function(t,k) local v = t[k] return v end,
        __index = function(t,k) local v = setnewenhancer(k) t[k] = v return v end,
    })

end

-- We need to check for default features. For this we provide a helper function.

function constructors.checkedfeatures(what,features)
    local defaults = handlers[what].features.defaults
    if features and next(features) then
        features = fastcopy(features) -- can be inherited (mt) but then no loops possible
        for key, value in next, defaults do
            if features[key] == nil then
                features[key] = value
            end
        end
        return features
    else
        return fastcopy(defaults) -- we can change features in place
    end
end

-- before scaling

function constructors.initializefeatures(what,tfmdata,features,trace,report)
    if features and next(features) then
        local properties       = tfmdata.properties or { } -- brrr
        local whathandler      = handlers[what]
        local whatfeatures     = whathandler.features
        local whatmodechecker  = whatfeatures.modechecker
        -- properties.mode can be enforces (for instance in font-otd)
        local mode             = properties.mode or (whatmodechecker and whatmodechecker(tfmdata,features,features.mode)) or features.mode or "base"
        properties.mode        = mode -- also status
        features.mode          = mode -- both properties.mode or features.mode can be changed
        --
        local done             = { }
        while true do
            local redo = false
            local initializers = whatfeatures.initializers[mode]
            if initializers then
                for i=1,#initializers do
                    local step = initializers[i]
                    local feature = step.name
-- we could intercept mode here .. needs a rewrite of this whole loop then but it's cleaner that way
                    local value = features[feature]
                    if not value then
                        -- disabled
                    elseif done[feature] then
                        -- already done
                    else
                        local action = step.action
                        if trace then
                            report("initializing feature %a to %a for mode %a for font %a",feature,
                                value,mode,tfmdata.properties.fullname)
                        end
                        action(tfmdata,value,features) -- can set mode (e.g. goodies) so it can trigger a restart
                        if mode ~= properties.mode or mode ~= features.mode then
                            if whatmodechecker then
                                properties.mode = whatmodechecker(tfmdata,features,properties.mode) -- force checking
                                features.mode   = properties.mode
                            end
                            if mode ~= properties.mode then
                                mode = properties.mode
                                redo = true
                            end
                        end
                        done[feature] = true
                    end
                    if redo then
                        break
                    end
                end
                if not redo then
                    break
                end
            else
                break
            end
        end
        properties.mode = mode -- to be sure
        return true
    else
        return false
    end
end

-- while typesetting

function constructors.collectprocessors(what,tfmdata,features,trace,report)
    local processes    = { }
    local nofprocesses = 0
    if features and next(features) then
        local properties     = tfmdata.properties
        local whathandler    = handlers[what]
        local whatfeatures   = whathandler.features
        local whatprocessors = whatfeatures.processors
        local mode           = properties.mode
        local processors     = whatprocessors[mode]
        if processors then
            for i=1,#processors do
                local step = processors[i]
                local feature = step.name
                if features[feature] then
                    local action = step.action
                    if trace then
                        report("installing feature processor %a for mode %a for font %a",feature,mode,tfmdata.properties.fullname)
                    end
                    if action then
                        nofprocesses = nofprocesses + 1
                        processes[nofprocesses] = action
                    end
                end
            end
        elseif trace then
            report("no feature processors for mode %a for font %a",mode,properties.fullname)
        end
    end
    return processes
end

-- after scaling

function constructors.applymanipulators(what,tfmdata,features,trace,report)
    if features and next(features) then
        local properties       = tfmdata.properties
        local whathandler      = handlers[what]
        local whatfeatures     = whathandler.features
        local whatmanipulators = whatfeatures.manipulators
        local mode             = properties.mode
        local manipulators     = whatmanipulators[mode]
        if manipulators then
            for i=1,#manipulators do
                local step = manipulators[i]
                local feature = step.name
                local value = features[feature]
                if value then
                    local action = step.action
                    if trace then
                        report("applying feature manipulator %a for mode %a for font %a",feature,mode,properties.fullname)
                    end
                    if action then
                        action(tfmdata,feature,value)
                    end
                end
            end
        end
    end
end

function constructors.addcoreunicodes(unicodes) -- maybe make this a metatable if used at all
    if not unicodes then
        unicodes = { }
    end
    unicodes.space  = 0x0020
    unicodes.hyphen = 0x002D
    unicodes.zwj    = 0x200D
    unicodes.zwnj   = 0x200C
    return unicodes
end

-- -- keep for a while: old tounicode code
--
-- if changed then
--     -- basemode hack (we try to catch missing tounicodes, e.g. needed for ssty in math cambria)
--     local c = changed[unicode]
--     if c then
--      -- local ligatures = character.ligatures -- the original ligatures (as we cannot rely on remapping)
--         description = descriptions[c] or descriptions[unicode] or character
--         character = characters[c] or character
--         index = description.index or c
--         if tounicode then
--             touni = tounicode[index] -- nb: index!
--             if not touni then -- goodie
--                 local d = descriptions[unicode] or characters[unicode]
--                 local i = d.index or unicode
--                 touni = tounicode[i] -- nb: index!
--             end
--         end
--      -- if ligatures and not character.ligatures then
--      --     character.ligatures = ligatures -- the original targets (for now at least.. see libertine smallcaps)
--      -- end
--     else
--         description = descriptions[unicode] or character
--         index = description.index or unicode
--         if tounicode then
--             touni = tounicode[index] -- nb: index!
--         end
--     end
-- else
--     description = descriptions[unicode] or character
--     index = description.index or unicode
--     if tounicode then
--         touni = tounicode[index] -- nb: index!
--     end
-- end
