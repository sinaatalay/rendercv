if not modules then modules = { } end modules ['font-oti'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local lower = string.lower

local fonts              = fonts
local constructors       = fonts.constructors

local otf                = constructors.handlers.otf
local otffeatures        = constructors.features.otf
local registerotffeature = otffeatures.register

local otftables          = otf.tables or { }
otf.tables               = otftables

local allocate           = utilities.storage.allocate

registerotffeature {
    name        = "features",
    description = "initialization of feature handler",
    default     = true,
}

-- these are later hooked into node and base initializaters

local function setmode(tfmdata,value)
    if value then
        tfmdata.properties.mode = lower(value)
    end
end

otf.modeinitializer = setmode

local function setlanguage(tfmdata,value)
    if value then
        local cleanvalue = lower(value)
        local languages  = otftables and otftables.languages
        local properties = tfmdata.properties
        if not languages then
            properties.language = cleanvalue
        elseif languages[value] then
            properties.language = cleanvalue
        else
            properties.language = "dflt"
        end
    end
end

local function setscript(tfmdata,value)
    if value then
        local cleanvalue = lower(value)
        local scripts    = otftables and otftables.scripts
        local properties = tfmdata.properties
        if not scripts then
            properties.script = cleanvalue
        elseif scripts[value] then
            properties.script = cleanvalue
        else
            properties.script = "dflt"
        end
    end
end

registerotffeature {
    name        = "mode",
    description = "mode",
    initializers = {
        base = setmode,
        node = setmode,
        plug = setmode,
    }
}

registerotffeature {
    name         = "language",
    description  = "language",
    initializers = {
        base = setlanguage,
        node = setlanguage,
        plug = setlanguage,
    }
}

registerotffeature {
    name        = "script",
    description = "script",
    initializers = {
        base = setscript,
        node = setscript,
        plug = setscript,
    }
}

-- here (as also in generic

otftables.featuretypes = allocate {
    gpos_single              = "position",
    gpos_pair                = "position",
    gpos_cursive             = "position",
    gpos_mark2base           = "position",
    gpos_mark2ligature       = "position",
    gpos_mark2mark           = "position",
    gpos_context             = "position",
    gpos_contextchain        = "position",
    gsub_single              = "substitution",
    gsub_multiple            = "substitution",
    gsub_alternate           = "substitution",
    gsub_ligature            = "substitution",
    gsub_context             = "substitution",
    gsub_contextchain        = "substitution",
    gsub_reversecontextchain = "substitution",
    gsub_reversesub          = "substitution",
}

function otffeatures.checkeddefaultscript(featuretype,autoscript,scripts)
    if featuretype == "position" then
        local default = scripts.dflt
        if default then
            if autoscript == "position" or autoscript == true then
                return default
            else
                report_otf("script feature %s not applied, enable default positioning")
            end
        else
            -- no positioning at all
        end
    elseif featuretype == "substitution" then
        local default = scripts.dflt
        if default then
            if autoscript == "substitution" or autoscript == true then
                return default
            end
        end
    end
end

function otffeatures.checkeddefaultlanguage(featuretype,autolanguage,languages)
    if featuretype == "position" then
        local default = languages.dflt
        if default then
            if autolanguage == "position" or autolanguage == true then
                return default
            else
                report_otf("language feature %s not applied, enable default positioning")
            end
        else
            -- no positioning at all
        end
    elseif featuretype == "substitution" then
        local default = languages.dflt
        if default then
            if autolanguage == "substitution" or autolanguage == true then
                return default
            end
        end
    end
end

-- the following might become available generic in due time but for now
-- this is some context playground (development code)

-- if not context then
--     return
-- end

-- local helpers        = otf.readers.helpers
-- local axistofactors  = helpers.axistofactors
-- local normalizedaxis = helpers.normalizedaxis
-- local getaxisscale   = helpers.getaxisscale
-- local cleanname      = containers.cleanname

-- local function validvariable(tfmdata)
--     if tfmdata.properties.factors then
--         return
--     end
--     local resources    = tfmdata.resources
--     local variabledata = resources and resources.variabledata
--     if not variabledata then
--         return
--     end
--     local instances = variabledata.instances
--     local axis      = variabledata.axis
--     local segments  = variabledata.segments
--     if instances and axis then
--         return instances, axis, segments
--     end
-- end

-- local function initializeinstance(tfmdata,value)
--     if type(value) == "string" then
--         local instances, axis, segments = validvariable(tfmdata)
--         if instances then
--             local values
--             for i=1,#instances do
--                 local instance = instances[i]
--                 if cleanname(instance.subfamily) == value then
--                     values = instance.values
--                     break
--                 end
--             end
--             if values then
--                 local factors = { }
--                 for i=1,#axis do
--                     local a = axis[i]
--                     factors[i] = getaxisscale(segments,a.minimum,a.default,a.maximum,values[i].value)
--                 end
--                 tfmdata.properties.instance = {
--                     hash    = instance,
--                     factors = factors,
--                 }
--             end
--         else
--             report("incomplete variable data")
--         end
--     end
-- end

-- local function initializeaxis(tfmdata,value)
--     if type(value) == "string" then
--         local instances, axis, segments = validvariable(tfmdata)
--         if instances then
--             local values = axistofactors(value)
--             if values then
--                 local factors = { }
--                 for i=1,#axis do
--                     local a = axis[i]
--                     local d = a.default
--                     factors[i] = getaxisscale(segments,a.minimum,d,a.maximum,values[a.name or a.tag] or d)
--                 end
--                 tfmdata.properties.instance = {
--                     hash    = cleanname(value),
--                     factors = factors,
--                 }
--             end
--         else
--             report("incomplete variable data")
--         end
--     end
-- end

-- registerotffeature {
--     name        = "instance",
--     description = "variation instance",
--     initializers = {
--         node = initializeinstance,
--         base = initializeinstance,
--     }
-- }

-- registerotffeature {
--     name        = "axis",
--     description = "variation axis",
--     initializers = {
--         node = initializeaxis,
--         base = initializeaxis,
--     }
-- }
