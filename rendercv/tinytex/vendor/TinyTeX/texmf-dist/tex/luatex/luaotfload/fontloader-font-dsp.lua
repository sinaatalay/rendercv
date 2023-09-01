if not modules then modules = { } end modules ['font-dsp'] = {
    version   = 1.001,
    optimize  = true,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- many 0,0 entry/exit

-- This loader went through a few iterations. First I made a ff compatible one so
-- that we could do some basic checking. Also some verbosity was added (named
-- glyphs). Eventually all that was dropped for a context friendly format, simply
-- because keeping the different table models in sync too to much time. I have the
-- old file somewhere. A positive side effect is that we get an (upto) much smaller
-- smaller tma/tmc file. In the end the loader will be not much slower than the
-- c based ff one.

-- Being binary encoded, an opentype is rather compact. When expanded into a Lua table
-- quite some memory can be used. This is very noticeable in the ff loader, which for
-- a good reason uses a verbose format. However, when we use that data we create a couple
-- of hashes. In the Lua loader we create these hashes directly, which save quite some
-- memory.
--
-- We convert a font file only once and then cache it. Before creating the cached instance
-- packing takes place: common tables get shared. After (re)loading and unpacking we then
-- get a rather efficient internal representation of the font. In the new loader there is a
-- pitfall. Because we use some common coverage magic we put a bit more information in
-- the mark and cursive coverage tables than strickly needed: a reference to the coverage
-- itself. This permits a fast lookup of the second glyph involved. In the marks we
-- expand the class indicator to a class hash, in the cursive we use a placeholder that gets
-- a self reference. This means that we cannot pack these subtables unless we add a unique
-- id per entry (the same one per coverage) and that makes the tables larger. Because only a
-- few fonts benefit from this, I decided to not do this. Experiments demonstrated that it
-- only gives a few percent gain (on for instance husayni we can go from 845K to 828K
-- bytecode). Better stay conceptually clean than messy compact.

-- When we can reduce all basic lookups to one step we might safe a bit in the processing
-- so then only chains are multiple.

-- I used to flatten kerns here but that has been moved elsewhere because it polutes the code
-- here and can be done fast afterwards. One can even wonder if it makes sense to do it as we
-- pack anyway. In a similar fashion the unique placeholders in anchors in marks have been
-- removed because packing doesn't save much there anyway.

-- Although we have a bit more efficient tables in the cached files, the internals are still
-- pretty similar. And although we have a slightly more direct coverage access the processing
-- of node lists is not noticeable faster for latin texts, but for arabic we gain some 10%
-- (and could probably gain a bit more).

-- All this packing in the otf format is somewhat obsessive as nowadays 4K resolution
-- multi-gig videos pass through our networks and storage and memory is abundant.

-- Although we use a few table readers there i sno real gain in there (apart from having
-- less code. After all there are often not that many demanding features.

local next, type, tonumber = next, type, tonumber
local band = bit32.band
local extract = bit32.extract
local bor = bit32.bor
local lshift = bit32.lshift
local rshift = bit32.rshift
local gsub = string.gsub
local lower = string.lower
local sub = string.sub
local strip = string.strip
local tohash = table.tohash
local concat = table.concat
local copy = table.copy
local reversed = table.reversed
local sort = table.sort
local insert = table.insert
local round = math.round

local settings_to_hash  = utilities.parsers.settings_to_hash_colon_too
local setmetatableindex = table.setmetatableindex
local formatters        = string.formatters
local sortedkeys        = table.sortedkeys
local sortedhash        = table.sortedhash
local sequenced         = table.sequenced

local report            = logs.reporter("otf reader")

local readers           = fonts.handlers.otf.readers
local streamreader      = readers.streamreader

local setposition       = streamreader.setposition
local getposition       = streamreader.getposition
local readuinteger      = streamreader.readcardinal1
local readushort        = streamreader.readcardinal2
local readulong         = streamreader.readcardinal4
local readinteger       = streamreader.readinteger1
local readshort         = streamreader.readinteger2
local readstring        = streamreader.readstring
local readtag           = streamreader.readtag
local readbytes         = streamreader.readbytes
local readfixed         = streamreader.readfixed4
local read2dot14        = streamreader.read2dot14
local skipshort         = streamreader.skipshort
local skipbytes         = streamreader.skip
local readbytetable     = streamreader.readbytetable
local readbyte          = streamreader.readbyte
local readcardinaltable = streamreader.readcardinaltable
local readintegertable  = streamreader.readintegertable
local readfword         = readshort

local short  = 2
local ushort = 2
local ulong  = 4

directives.register("fonts.streamreader",function()

    streamreader      = utilities.streams

    setposition       = streamreader.setposition
    getposition       = streamreader.getposition
    readuinteger      = streamreader.readcardinal1
    readushort        = streamreader.readcardinal2
    readulong         = streamreader.readcardinal4
    readinteger       = streamreader.readinteger1
    readshort         = streamreader.readinteger2
    readstring        = streamreader.readstring
    readtag           = streamreader.readtag
    readbytes         = streamreader.readbytes
    readfixed         = streamreader.readfixed4
    read2dot14        = streamreader.read2dot14
    skipshort         = streamreader.skipshort
    skipbytes         = streamreader.skip
    readbytetable     = streamreader.readbytetable
    readbyte          = streamreader.readbyte
    readcardinaltable = streamreader.readcardinaltable
    readintegertable  = streamreader.readintegertable
    readfword         = readshort

end)

local gsubhandlers      = { }
local gposhandlers      = { }

readers.gsubhandlers    = gsubhandlers
readers.gposhandlers    = gposhandlers

local helpers           = readers.helpers
local gotodatatable     = helpers.gotodatatable
local setvariabledata   = helpers.setvariabledata

local lookupidoffset    = -1    -- will become 1 when we migrate (only -1 for comparign with old)

local classes = {
    "base",
    "ligature",
    "mark",
    "component",
}

local gsubtypes = {
    "single",
    "multiple",
    "alternate",
    "ligature",
    "context",
    "chainedcontext",
    "extension",
    "reversechainedcontextsingle",
}

local gpostypes = {
    "single",
    "pair",
    "cursive",
    "marktobase",
    "marktoligature",
    "marktomark",
    "context",
    "chainedcontext",
    "extension",
}

local chaindirections = {
    context                     =  0,
    chainedcontext              =  1,
    reversechainedcontextsingle = -1,
}

local function setmetrics(data,where,tag,d)
    local w = data[where]
    if w then
        local v = w[tag]
        if v then
            -- it looks like some fonts set the value and not the delta
         -- report("adding %s to %s.%s value %s",d,where,tag,v)
            w[tag] = v + d
        end
    end
end

local variabletags = {
    hasc = function(data,d) setmetrics(data,"windowsmetrics","typoascender",d) end,
    hdsc = function(data,d) setmetrics(data,"windowsmetrics","typodescender",d) end,
    hlgp = function(data,d) setmetrics(data,"windowsmetrics","typolinegap",d) end,
    hcla = function(data,d) setmetrics(data,"windowsmetrics","winascent",d) end,
    hcld = function(data,d) setmetrics(data,"windowsmetrics","windescent",d) end,
    vasc = function(data,d) setmetrics(data,"vhea not done","ascent",d) end,
    vdsc = function(data,d) setmetrics(data,"vhea not done","descent",d) end,
    vlgp = function(data,d) setmetrics(data,"vhea not done","linegap",d) end,
    xhgt = function(data,d) setmetrics(data,"windowsmetrics","xheight",d) end,
    cpht = function(data,d) setmetrics(data,"windowsmetrics","capheight",d) end,
    sbxs = function(data,d) setmetrics(data,"windowsmetrics","subscriptxsize",d) end,
    sbys = function(data,d) setmetrics(data,"windowsmetrics","subscriptysize",d) end,
    sbxo = function(data,d) setmetrics(data,"windowsmetrics","subscriptxoffset",d) end,
    sbyo = function(data,d) setmetrics(data,"windowsmetrics","subscriptyoffset",d) end,
    spxs = function(data,d) setmetrics(data,"windowsmetrics","superscriptxsize",d) end,
    spys = function(data,d) setmetrics(data,"windowsmetrics","superscriptysize",d) end,
    spxo = function(data,d) setmetrics(data,"windowsmetrics","superscriptxoffset",d) end,
    spyo = function(data,d) setmetrics(data,"windowsmetrics","superscriptyoffset",d) end,
    strs = function(data,d) setmetrics(data,"windowsmetrics","strikeoutsize",d) end,
    stro = function(data,d) setmetrics(data,"windowsmetrics","strikeoutpos",d) end,
    unds = function(data,d) setmetrics(data,"postscript","underlineposition",d) end,
    undo = function(data,d) setmetrics(data,"postscript","underlinethickness",d) end,
}

local read_cardinal = {
    streamreader.readcardinal1,
    streamreader.readcardinal2,
    streamreader.readcardinal3,
    streamreader.readcardinal4,
}

local read_integer = {
    streamreader.readinteger1,
    streamreader.readinteger2,
    streamreader.readinteger3,
    streamreader.readinteger4,
}

directives.register("fonts.streamreader",function()

    read_cardinal = {
        streamreader.readcardinal1,
        streamreader.readcardinal2,
        streamreader.readcardinal3,
        streamreader.readcardinal4,
    }

    read_integer = {
        streamreader.readinteger1,
        streamreader.readinteger2,
        streamreader.readinteger3,
        streamreader.readinteger4,
    }

end)

-- Traditionally we use these unique names (so that we can flatten the lookup list
-- (we create subsets runtime) but I will adapt the old code to newer names.

-- chainsub
-- reversesub

local lookupnames = {
    gsub = {
        single                      = "gsub_single",
        multiple                    = "gsub_multiple",
        alternate                   = "gsub_alternate",
        ligature                    = "gsub_ligature",
        context                     = "gsub_context",
        chainedcontext              = "gsub_contextchain",
        reversechainedcontextsingle = "gsub_reversecontextchain", -- reversesub
    },
    gpos = {
        single                      = "gpos_single",
        pair                        = "gpos_pair",
        cursive                     = "gpos_cursive",
        marktobase                  = "gpos_mark2base",
        marktoligature              = "gpos_mark2ligature",
        marktomark                  = "gpos_mark2mark",
        context                     = "gpos_context",
        chainedcontext              = "gpos_contextchain",
    }
}

-- keep this as reference:
--
-- local lookupbits = {
--     [0x0001] = "righttoleft",
--     [0x0002] = "ignorebaseglyphs",
--     [0x0004] = "ignoreligatures",
--     [0x0008] = "ignoremarks",
--     [0x0010] = "usemarkfilteringset",
--     [0x00E0] = "reserved",
--     [0xFF00] = "markattachmenttype",
-- }
--
-- local lookupstate = setmetatableindex(function(t,k)
--     local v = { }
--     for kk, vv in next, lookupbits do
--         if band(k,kk) ~= 0 then
--             v[vv] = true
--         end
--     end
--     t[k] = v
--     return v
-- end)

local lookupflags = setmetatableindex(function(t,k)
    local v = {
        band(k,0x0008) ~= 0 and true or false, -- ignoremarks
        band(k,0x0004) ~= 0 and true or false, -- ignoreligatures
        band(k,0x0002) ~= 0 and true or false, -- ignorebaseglyphs
        band(k,0x0001) ~= 0 and true or false, -- r2l
    }
    t[k] = v
    return v
end)

-- Variation stores: it's not entirely clear if the regions are a shared
-- resource (it looks like they are). Anyway, we play safe and use a
-- share.

-- values can be anything the min/max permits so we can either think of
-- real values of a fraction along the axis (probably easier)

-- wght=400,wdth=100,ital=1

local function axistofactors(str)
    local t = settings_to_hash(str)
    for k, v in next, t do
        t[k] = tonumber(v) or v -- this also normalizes numbers itself
    end
    return t
end

local hash = table.setmetatableindex(function(t,k)
    local v = sequenced(axistofactors(k),",")
    t[k] = v
    return v
end)

helpers.normalizedaxishash = hash

local cleanname = fonts.names and fonts.names.cleanname or function(name)
    return name and (gsub(lower(name),"[^%a%d]","")) or nil
end

helpers.cleanname = cleanname

function helpers.normalizedaxis(str)
    return hash[str] or str
end

-- contradicting spec ... (signs) so i'll check it and fix it once we have
-- proper fonts

local function getaxisscale(segments,minimum,default,maximum,user)
    --
    -- returns the right values cf example in standard
    --
    if not minimum or not default or not maximum then
        return false
    end
    if user < minimum then
        user = minimum
    elseif user > maximum then
        user = maximum
    end
    if user < default then
        default = - (default - user) / (default - minimum)
    elseif user > default then
        default = (user - default) / (maximum - default)
    else
        default = 0
    end
    if not segments then
        return default
    end
    local e
    for i=1,#segments do
        local s = segments[i]
        if type(s) ~= "number" then
         -- report("using default axis scale")
            return default
        elseif s[1] >= default then
            if s[2] == default then
                return default
            else
                e = i
                break
            end
        end
    end
    if e then
        local b = segments[e-1]
        local e = segments[e]
        return b[2] + (e[2] - b[2]) * (default - b[1]) / (e[1] - b[1])
    else
        return false
    end
end

local function getfactors(data,instancespec)
    if instancespec == true then
        -- take default
    elseif type(instancespec) ~= "string" or instancespec == "" then
        return
    end
    local variabledata = data.variabledata
    if not variabledata then
        return
    end
    local instances = variabledata.instances
    local axis      = variabledata.axis
    local segments  = variabledata.segments
    if instances and axis then
        local values
        if instancespec == true then
            -- first instance:
         -- values = instances[1].values
            -- axis defaults:
            values = { }
            for i=1,#axis do
                values[i] = {
                 -- axis  = axis[i].tag,
                    value = axis[i].default,
                }
            end

        else
            for i=1,#instances do
                local instance = instances[i]
                if cleanname(instance.subfamily) == instancespec then
                    values = instance.values
                    break
                end
            end
        end
        if values then
            local factors = { }
            for i=1,#axis do
                local a = axis[i]
                factors[i] = getaxisscale(segments,a.minimum,a.default,a.maximum,values[i].value)
            end
            return factors
        end
        local values = axistofactors(hash[instancespec] or instancespec)
        if values then
            local factors = { }
            for i=1,#axis do
                local a = axis[i]
                local d = a.default
                factors[i] = getaxisscale(segments,a.minimum,d,a.maximum,values[a.name or a.tag] or d)
            end
            return factors
        end
    end
end

local function getscales(regions,factors)
    local scales = { }
    for i=1,#regions do
        local region = regions[i]
        local s = 1
        for j=1,#region do
            local axis  = region[j]
            local f     = factors[j]
            local start = axis.start
            local peak  = axis.peak
            local stop  = axis.stop
            -- get rid of these tests, false flag
            if start > peak or peak > stop then
                -- * 1
            elseif start < 0 and stop > 0 and peak ~= 0 then
                -- * 1
            elseif peak == 0 then
                -- * 1
            elseif f < start or f > stop then
                -- * 0
                s = 0
                break
            elseif f < peak then
             -- s = - s * (f - start) / (peak - start)
                s = s * (f - start) / (peak - start)
            elseif f > peak then
                s = s * (stop - f) / (stop - peak)
            else
                -- * 1
            end
        end
        scales[i] = s
    end
    return scales
end

helpers.getaxisscale  = getaxisscale
helpers.getfactors    = getfactors
helpers.getscales     = getscales
helpers.axistofactors = axistofactors

local function readvariationdata(f,storeoffset,factors) -- store
    local position = getposition(f)
    setposition(f,storeoffset)
    -- header
    local format       = readushort(f)
    local regionoffset = storeoffset + readulong(f)
    local nofdeltadata = readushort(f)
    local deltadata    = readcardinaltable(f,nofdeltadata,ulong)
    -- regions
    setposition(f,regionoffset)
    local nofaxis    = readushort(f)
    local nofregions = readushort(f)
    local regions    = { }
    for i=1,nofregions do -- 0
        local t = { }
        for i=1,nofaxis do
            t[i] = { -- maybe no keys, just 1..3
                start = read2dot14(f),
                peak  = read2dot14(f),
                stop  = read2dot14(f),
            }
        end
        regions[i] = t
    end
    -- deltas
 -- if factors then
        for i=1,nofdeltadata do
            setposition(f,storeoffset+deltadata[i])
            local nofdeltasets = readushort(f)
            local nofshorts    = readushort(f)
            local nofregions   = readushort(f)
            local usedregions  = { }
            local deltas       = { }
            for i=1,nofregions do
                usedregions[i] = regions[readushort(f)+1]
            end
            -- we could test before and save a for
            for i=1,nofdeltasets do
                local t = readintegertable(f,nofshorts,short)
                for i=nofshorts+1,nofregions do
                    t[i] = readinteger(f)
                end
                deltas[i] = t
            end
            deltadata[i] = {
                regions = usedregions,
                deltas  = deltas,
                scales  = factors and getscales(usedregions,factors) or nil,
            }
        end
 -- end
    setposition(f,position)
    return regions, deltadata
end

helpers.readvariationdata = readvariationdata

-- Beware: only use the simple variant if we don't set keys/values (otherwise too many entries). We
-- could also have a variant that applies a function but there is no real benefit in this.

local function readcoverage(f,offset,simple)
    setposition(f,offset)
    local coverageformat = readushort(f)
    if coverageformat == 1 then
        local nofcoverage = readushort(f)
        if simple then
            -- often 1 or 2
            if nofcoverage == 1 then
                return { readushort(f) }
            elseif nofcoverage == 2 then
                return { readushort(f), readushort(f) }
            else
                return readcardinaltable(f,nofcoverage,ushort)
            end
        elseif nofcoverage == 1 then
            return { [readushort(f)] = 0 }
        elseif nofcoverage == 2 then
            return { [readushort(f)] = 0, [readushort(f)] = 1 }
        else
            local coverage = { }
            for i=0,nofcoverage-1 do
                coverage[readushort(f)] = i -- index in record
            end
            return coverage
        end
    elseif coverageformat == 2 then
        local nofranges = readushort(f)
        local coverage  = { }
        local n         = simple and 1 or 0 -- needs checking
        for i=1,nofranges do
            local firstindex = readushort(f)
            local lastindex  = readushort(f)
            local coverindex = readushort(f)
            if simple then
                for i=firstindex,lastindex do
                    coverage[n] = i
                    n = n + 1
                end
            else
                for i=firstindex,lastindex do
                    coverage[i] = n
                    n = n + 1
                end
            end
        end
        return coverage
    else
        report("unknown coverage format %a ",coverageformat)
        return { }
    end
end

local function readclassdef(f,offset,preset)
    setposition(f,offset)
    local classdefformat = readushort(f)
    local classdef = { }
    if type(preset) == "number" then
        for k=0,preset-1 do
            classdef[k] = 1
        end
    end
    if classdefformat == 1 then
        local index       = readushort(f)
        local nofclassdef = readushort(f)
        for i=1,nofclassdef do
            classdef[index] = readushort(f) + 1
            index = index + 1
        end
    elseif classdefformat == 2 then
        local nofranges = readushort(f)
        local n = 0
        for i=1,nofranges do
            local firstindex = readushort(f)
            local lastindex  = readushort(f)
            local class      = readushort(f) + 1
            for i=firstindex,lastindex do
                classdef[i] = class
            end
        end
    else
        report("unknown classdef format %a ",classdefformat)
    end
    if type(preset) == "table" then
        for k in next, preset do
            if not classdef[k] then
                classdef[k] = 1
            end
        end
    end
    return classdef
end

local function classtocoverage(defs)
    if defs then
        local list = { }
        for index, class in next, defs do
            local c = list[class]
            if c then
                c[#c+1] = index
            else
                list[class] = { index }
            end
        end
        return list
    end
end

-- extra readers

local skips = { [0] =
    0, -- ----
    1, -- ---x
    1, -- --y-
    2, -- --yx
    1, -- -h--
    2, -- -h-x
    2, -- -hy-
    3, -- -hyx
    2, -- v--x
    2, -- v-y-
    3, -- v-yx
    2, -- vh--
    3, -- vh-x
    3, -- vhy-
    4, -- vhyx
}

-- We can assume that 0 is nothing and in fact we can start at 1 as
-- usual in Lua to make sure of that.

local function readvariation(f,offset)
    local p = getposition(f)
    setposition(f,offset)
    local outer  = readushort(f)
    local inner  = readushort(f)
    local format = readushort(f)
    setposition(f,p)
    if format == 0x8000 then
        return outer, inner
    end
end

local function readposition(f,format,mainoffset,getdelta)
    if format == 0 then
        return false
    end
    -- a few happen often
    if format == 0x04 then
        local h = readshort(f)
        if h == 0 then
            return true -- all zero
        else
            return { 0, 0, h, 0 }
        end
    end
    if format == 0x05 then
        local x = readshort(f)
        local h = readshort(f)
        if x == 0 and h == 0 then
            return true -- all zero
        else
            return { x, 0, h, 0 }
        end
    end
    if format == 0x44 then
        local h = readshort(f)
        if getdelta then
            local d = readshort(f) -- short or ushort
            if d > 0 then
                local outer, inner = readvariation(f,mainoffset+d)
                if outer then
                    h = h + getdelta(outer,inner)
                end
            end
        else
            skipshort(f,1)
        end
        if h == 0 then
            return true -- all zero
        else
            return { 0, 0, h, 0 }
        end
    end
    --
    -- todo:
    --
    -- if format == 0x55 then
    --     local x = readshort(f)
    --     local h = readshort(f)
    --     ....
    -- end
    --
    local x = band(format,0x1) ~= 0 and readshort(f) or 0 -- x placement
    local y = band(format,0x2) ~= 0 and readshort(f) or 0 -- y placement
    local h = band(format,0x4) ~= 0 and readshort(f) or 0 -- h advance
    local v = band(format,0x8) ~= 0 and readshort(f) or 0 -- v advance
    if format >= 0x10 then
        local X = band(format,0x10) ~= 0 and skipshort(f) or 0
        local Y = band(format,0x20) ~= 0 and skipshort(f) or 0
        local H = band(format,0x40) ~= 0 and skipshort(f) or 0
        local V = band(format,0x80) ~= 0 and skipshort(f) or 0
        local s = skips[extract(format,4,4)]
        if s > 0 then
            skipshort(f,s)
        end
        if getdelta then
            if X > 0 then
                local outer, inner = readvariation(f,mainoffset+X)
                if outer then
                    x = x + getdelta(outer,inner)
                end
            end
            if Y > 0 then
                local outer, inner = readvariation(f,mainoffset+Y)
                if outer then
                    y = y + getdelta(outer,inner)
                end
            end
            if H > 0 then
                local outer, inner = readvariation(f,mainoffset+H)
                if outer then
                    h = h + getdelta(outer,inner)
                end
            end
            if V > 0 then
                local outer, inner = readvariation(f,mainoffset+V)
                if outer then
                    v = v + getdelta(outer,inner)
                end
            end
        end
        return { x, y, h, v }
    elseif x == 0 and y == 0 and h == 0 and v == 0 then
        return true -- all zero
    else
        return { x, y, h, v }
    end
end

local function readanchor(f,offset,getdelta) -- maybe also ignore 0's as in pos
    if not offset or offset == 0 then
        return nil -- false
    end
    setposition(f,offset)
    -- no need to skip as we position each
    local format = readshort(f) -- 1: x y 2: x y index 3 x y X Y
    local x = readshort(f)
    local y = readshort(f)
    if format == 3 then
        if getdelta then
            local X = readshort(f)
            local Y = readshort(f)
            if X > 0 then
                local outer, inner = readvariation(f,offset+X)
                if outer then
                    x = x + getdelta(outer,inner)
                end
            end
            if Y > 0 then
                local outer, inner = readvariation(f,offset+Y)
                if outer then
                    y = y + getdelta(outer,inner)
                end
            end
        else
            skipshort(f,2)
        end
        return { x, y } -- , { xindex, yindex }
    else
        return { x, y }
    end
end

-- common handlers: inlining can be faster but we cache anyway
-- so we don't bother too much about speed here

local function readfirst(f,offset)
    if offset then
        setposition(f,offset)
    end
    return { readushort(f) }
end

-- quite often 0, 1, 2

local function readarray(f,offset)
    if offset then
        setposition(f,offset)
    end
    local n = readushort(f)
    if n == 1 then
        return { readushort(f) }, 1
    elseif n > 0 then
        return readcardinaltable(f,n,ushort), n
    end
end

local function readcoveragearray(f,offset,t,simple)
    if not t then
        return nil
    end
    local n = #t
    if n == 0 then
        return nil
    end
    for i=1,n do
        t[i] = readcoverage(f,offset+t[i],simple)
    end
    return t
end

local function covered(subset,all)
    local used, u
    for i=1,#subset do
        local s = subset[i]
        if all[s] then
            if used then
                u = u + 1
                used[u] = s
            else
                u = 1
                used = { s }
            end
        end
    end
    return used
end

-- We generalize the chained lookups so that we can do with only one handler
-- when processing them.

-- pruned

local function readlookuparray(f,noflookups,nofcurrent)
    local lookups = { }
    if noflookups > 0 then
        local length = 0
        for i=1,noflookups do
            local index = readushort(f) + 1
            if index > length then
                length = index
            end
            local lookup = readushort(f) + 1
            local list   = lookups[index]
            if list then
                list[#list+1] = lookup
            else
                lookups[index] = { lookup }
            end
        end
        for index=1,length do
            if not lookups[index] then
                lookups[index] = false
            end
        end
     -- if length > nofcurrent then
     --     report("more lookups than currently matched characters")
     -- end
    end
    return lookups
end

-- not pruned
--
-- local function readlookuparray(f,noflookups,nofcurrent)
--     local lookups = { }
--     for i=1,nofcurrent do
--         lookups[i] = false
--     end
--     for i=1,noflookups do
--         local index = readushort(f) + 1
--         if index > nofcurrent then
--             report("more lookups than currently matched characters")
--             for i=nofcurrent+1,index-1 do
--                 lookups[i] = false
--             end
--             nofcurrent = index
--         end
--         lookups[index] = readushort(f) + 1
--     end
--     return lookups
-- end

local function unchainedcontext(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,what)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype = readushort(f)
    if subtype == 1 then
        local coverage     = readushort(f)
        local subclasssets = readarray(f)
        local rules        = { }
        if subclasssets then
            coverage = readcoverage(f,tableoffset+coverage,true)
            for i=1,#subclasssets do
                local offset = subclasssets[i]
                if offset > 0 then
                    local firstcoverage = coverage[i]
                    local rulesoffset   = tableoffset + offset
                    local subclassrules = readarray(f,rulesoffset)
                    for rule=1,#subclassrules do
                        setposition(f,rulesoffset + subclassrules[rule])
                        local nofcurrent = readushort(f)
                        local noflookups = readushort(f)
                        local current    = { { firstcoverage } }
                        for i=2,nofcurrent do
                            current[i] = { readushort(f) }
                        end
                        local lookups = readlookuparray(f,noflookups,nofcurrent)
                        rules[#rules+1] = {
                            current = current,
                            lookups = lookups
                        }
                    end
                end
            end
        else
            report("empty subclassset in %a subtype %i","unchainedcontext",subtype)
        end
        return {
            format = "glyphs",
            rules  = rules,
        }
    elseif subtype == 2 then
        -- We expand the classes as later on we do a pack over the whole table so then we get
        -- back efficiency. This way we can also apply the coverage to the first current.
        local coverage        = readushort(f)
        local currentclassdef = readushort(f)
        local subclasssets    = readarray(f)
        local rules           = { }
        if subclasssets then
            coverage             = readcoverage(f,tableoffset + coverage)
            currentclassdef      = readclassdef(f,tableoffset + currentclassdef,coverage)
            local currentclasses = classtocoverage(currentclassdef,fontdata.glyphs)
            for class=1,#subclasssets do
                local offset = subclasssets[class]
                if offset > 0 then
                    local firstcoverage = currentclasses[class]
                    if firstcoverage then
                        firstcoverage = covered(firstcoverage,coverage) -- bonus
                        if firstcoverage then
                            local rulesoffset   = tableoffset + offset
                            local subclassrules = readarray(f,rulesoffset)
                            for rule=1,#subclassrules do
                                setposition(f,rulesoffset + subclassrules[rule])
                                local nofcurrent = readushort(f)
                                local noflookups = readushort(f)
                                local current    = { firstcoverage }
                                for i=2,nofcurrent do
                                    current[i] = currentclasses[readushort(f) + 1]
                                end
                                local lookups = readlookuparray(f,noflookups,nofcurrent)
                                rules[#rules+1] = {
                                    current = current,
                                    lookups = lookups
                                }
                            end
                        else
                            report("no coverage")
                        end
                    else
                        report("no coverage class")
                    end
                end
            end
        else
            report("empty subclassset in %a subtype %i","unchainedcontext",subtype)
        end
        return {
            format = "class",
            rules  = rules,
        }
    elseif subtype == 3 then
        local nofglyphs  = readushort(f)
        local noflookups = readushort(f)
        local current    = readcardinaltable(f,nofglyphs,ushort)
        local lookups    = readlookuparray(f,noflookups,#current)
        current = readcoveragearray(f,tableoffset,current,true)
        return {
            format = "coverage",
            rules  = {
                {
                    current = current,
                    lookups = lookups,
                }
            }
        }
    else
        report("unsupported subtype %a in %a %s",subtype,"unchainedcontext",what)
    end
end

-- todo: optimize for n=1 ?

-- class index needs checking, probably no need for +1

local function chainedcontext(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,what)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype = readushort(f)
    if subtype == 1 then
        local coverage     = readushort(f)
        local subclasssets = readarray(f)
        local rules        = { }
        if subclasssets then
            coverage = readcoverage(f,tableoffset+coverage,true)
            for i=1,#subclasssets do
                local offset = subclasssets[i]
                if offset > 0 then
                    local firstcoverage = coverage[i]
                    local rulesoffset   = tableoffset + offset
                    local subclassrules = readarray(f,rulesoffset)
                    for rule=1,#subclassrules do
                        setposition(f,rulesoffset + subclassrules[rule])
                        local nofbefore = readushort(f)
                        local before
                        if nofbefore > 0 then
                            before = { }
                            for i=1,nofbefore do
                                before[i] = { readushort(f) }
                            end
                        end
                        local nofcurrent = readushort(f)
                        local current    = { { firstcoverage } }
                        for i=2,nofcurrent do
                            current[i] = { readushort(f) }
                        end
                        local nofafter = readushort(f)
                        local after
                        if nofafter > 0 then
                            after = { }
                            for i=1,nofafter do
                                after[i] = { readushort(f) }
                            end
                        end
                        local noflookups = readushort(f)
                        local lookups    = readlookuparray(f,noflookups,nofcurrent)
                        rules[#rules+1] = {
                            before  = before,
                            current = current,
                            after   = after,
                            lookups = lookups,
                        }
                    end
                end
            end
        else
            report("empty subclassset in %a subtype %i","chainedcontext",subtype)
        end
        return {
            format = "glyphs",
            rules  = rules,
        }
    elseif subtype == 2 then
        local coverage        = readushort(f)
        local beforeclassdef  = readushort(f)
        local currentclassdef = readushort(f)
        local afterclassdef   = readushort(f)
        local subclasssets    = readarray(f)
        local rules           = { }
        if subclasssets then
            local coverage        = readcoverage(f,tableoffset + coverage)
            local beforeclassdef  = readclassdef(f,tableoffset + beforeclassdef,nofglyphs)
            local currentclassdef = readclassdef(f,tableoffset + currentclassdef,coverage)
            local afterclassdef   = readclassdef(f,tableoffset + afterclassdef,nofglyphs)
            local beforeclasses   = classtocoverage(beforeclassdef,fontdata.glyphs)
            local currentclasses  = classtocoverage(currentclassdef,fontdata.glyphs)
            local afterclasses    = classtocoverage(afterclassdef,fontdata.glyphs)
            for class=1,#subclasssets do
                local offset = subclasssets[class]
                if offset > 0 then
                    local firstcoverage = currentclasses[class]
                    if firstcoverage then
                        firstcoverage = covered(firstcoverage,coverage) -- bonus
                        if firstcoverage then
                            local rulesoffset   = tableoffset + offset
                            local subclassrules = readarray(f,rulesoffset)
                            for rule=1,#subclassrules do
                                -- watch out, in context we first get the counts and then the arrays while
                                -- here we get them mixed
                                setposition(f,rulesoffset + subclassrules[rule])
                                local nofbefore = readushort(f)
                                local before
                                if nofbefore > 0 then
                                    before = { }
                                    for i=1,nofbefore do
                                        before[i] = beforeclasses[readushort(f) + 1]
                                    end
                                end
                                local nofcurrent = readushort(f)
                                local current    = { firstcoverage }
                                for i=2,nofcurrent do
                                    current[i] = currentclasses[readushort(f)+ 1]
                                end
                                local nofafter = readushort(f)
                                local after
                                if nofafter > 0 then
                                    after = { }
                                    for i=1,nofafter do
                                        after[i] = afterclasses[readushort(f) + 1]
                                    end
                                end
                                -- no sequence index here (so why in context as it saves nothing)
                                local noflookups = readushort(f)
                                local lookups    = readlookuparray(f,noflookups,nofcurrent)
                                rules[#rules+1] = {
                                    before  = before,
                                    current = current,
                                    after   = after,
                                    lookups = lookups,
                                }
                            end
                        else
                            report("no coverage")
                        end
                    else
                        report("class is not covered")
                    end
                end
            end
        else
            report("empty subclassset in %a subtype %i","chainedcontext",subtype)
        end
        return {
            format = "class",
            rules  = rules,
        }
    elseif subtype == 3 then
        local before     = readarray(f)
        local current    = readarray(f)
        local after      = readarray(f)
        local noflookups = readushort(f)
        local lookups    = readlookuparray(f,noflookups,#current)
        before  = readcoveragearray(f,tableoffset,before,true)
        current = readcoveragearray(f,tableoffset,current,true)
        after   = readcoveragearray(f,tableoffset,after,true)
        return {
            format = "coverage",
            rules  = {
                {
                    before  = before,
                    current = current,
                    after   = after,
                    lookups = lookups,
                }
            }
        }
    else
        report("unsupported subtype %a in %a %s",subtype,"chainedcontext",what)
    end
end

local function extension(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,types,handlers,what)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype = readushort(f)
    if subtype == 1 then
        local lookuptype = types[readushort(f)]
        local faroffset  = readulong(f)
        local handler    = handlers[lookuptype]
        if handler then
            -- maybe we can just pass one offset (or tableoffset first)
            return handler(f,fontdata,lookupid,tableoffset + faroffset,0,glyphs,nofglyphs), lookuptype
        else
            report("no handler for lookuptype %a subtype %a in %s %s",lookuptype,subtype,what,"extension")
        end
    else
        report("unsupported subtype %a in %s %s",subtype,what,"extension")
    end
end

-- gsub handlers

function gsubhandlers.single(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype = readushort(f)
    if subtype == 1 then
        local coverage = readushort(f)
        local delta    = readshort(f) -- can be negative
        local coverage = readcoverage(f,tableoffset+coverage) -- not simple as we need to set key/value anyway
        for index in next, coverage do
            local newindex = (index + delta) % 65536 -- modulo is new in 1.8.3
            if index > nofglyphs or newindex > nofglyphs then
                report("invalid index in %s format %i: %i -> %i (max %i)","single",subtype,index,newindex,nofglyphs)
                coverage[index] = nil
            else
                coverage[index] = newindex
            end
        end
        return {
            coverage = coverage
        }
    elseif subtype == 2 then -- in streamreader a seek and fetch is faster than a temp table
        local coverage        = readushort(f)
        local nofreplacements = readushort(f)
        local replacements    = readcardinaltable(f,nofreplacements,ushort)
        local coverage = readcoverage(f,tableoffset + coverage) -- not simple as we need to set key/value anyway
        for index, newindex in next, coverage do
            newindex = newindex + 1
            if index > nofglyphs or newindex > nofglyphs then
                report("invalid index in %s format %i: %i -> %i (max %i)","single",subtype,index,newindex,nofglyphs)
                coverage[index] = nil
            else
                coverage[index] = replacements[newindex]
            end
        end
        return {
            coverage = coverage
        }
    else
        report("unsupported subtype %a in %a substitution",subtype,"single")
    end
end

-- we see coverage format 0x300 in some old ms fonts

local function sethandler(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,what)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype = readushort(f)
    if subtype == 1 then
        local coverage    = readushort(f)
        local nofsequence = readushort(f)
        local sequences   = readcardinaltable(f,nofsequence,ushort)
        for i=1,nofsequence do
            setposition(f,tableoffset + sequences[i])
            sequences[i] = readcardinaltable(f,readushort(f),ushort)
        end
        local coverage = readcoverage(f,tableoffset + coverage)
        for index, newindex in next, coverage do
            newindex = newindex + 1
            if index > nofglyphs or newindex > nofglyphs then
                report("invalid index in %s format %i: %i -> %i (max %i)",what,subtype,index,newindex,nofglyphs)
                coverage[index] = nil
            else
                coverage[index] = sequences[newindex]
            end
        end
        return {
            coverage = coverage
        }
    else
        report("unsupported subtype %a in %a substitution",subtype,what)
    end
end

function gsubhandlers.multiple(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return sethandler(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,"multiple")
end

function gsubhandlers.alternate(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return sethandler(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,"alternate")
end

function gsubhandlers.ligature(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype = readushort(f)
    if subtype == 1 then
        local coverage  = readushort(f)
        local nofsets   = readushort(f)
        local ligatures = readcardinaltable(f,nofsets,ushort)
        for i=1,nofsets do
            local offset = lookupoffset + offset + ligatures[i]
            setposition(f,offset)
            local n = readushort(f)
            if n == 1 then
                ligatures[i] = { offset + readushort(f) }
            else
                local l = { }
                for i=1,n do
                    l[i] = offset + readushort(f)
                end
                ligatures[i] = l
            end
        end
        local coverage = readcoverage(f,tableoffset + coverage)
        for index, newindex in next, coverage do
            local hash = { }
            local ligatures = ligatures[newindex+1]
            for i=1,#ligatures do
                local offset = ligatures[i]
                setposition(f,offset)
                local lig = readushort(f)
                local cnt = readushort(f)
                local hsh = hash
                for i=2,cnt do
                    local c = readushort(f)
                    local h = hsh[c]
                    if not h then
                        h = { }
                        hsh[c] = h
                    end
                    hsh =  h
                end
                hsh.ligature = lig
            end
            coverage[index] = hash
        end
        return {
            coverage = coverage
        }
    else
        report("unsupported subtype %a in %a substitution",subtype,"ligature")
    end
end

function gsubhandlers.context(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return unchainedcontext(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,"substitution"), "context"
end

function gsubhandlers.chainedcontext(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return chainedcontext(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,"substitution"), "chainedcontext"
end

function gsubhandlers.extension(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return extension(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,gsubtypes,gsubhandlers,"substitution")
end

function gsubhandlers.reversechainedcontextsingle(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype = readushort(f)
    if subtype == 1 then -- NEEDS CHECKING
        local current      = readfirst(f)
        local before       = readarray(f)
        local after        = readarray(f)
        local replacements = readarray(f)
        current = readcoveragearray(f,tableoffset,current,true)
        before  = readcoveragearray(f,tableoffset,before,true)
        after   = readcoveragearray(f,tableoffset,after,true)
        return {
            format = "reversecoverage", -- reversesub
            rules  = {
                {
                    before       = before,
                    current      = current,
                    after        = after,
                    replacements = replacements,
                }
            }
        }, "reversechainedcontextsingle"
    else
        report("unsupported subtype %a in %a substitution",subtype,"reversechainedcontextsingle")
    end
end

-- gpos handlers

local function readpairsets(f,tableoffset,sets,format1,format2,mainoffset,getdelta)
    local done = { }
    for i=1,#sets do
        local offset = sets[i]
        local reused = done[offset]
        if not reused then
            offset = tableoffset + offset
            setposition(f,offset)
            local n = readushort(f)
            reused = { }
            for i=1,n do
                reused[i] = {
                    readushort(f), -- second glyph id
                    readposition(f,format1,offset,getdelta),
                    readposition(f,format2,offset,getdelta),
                }
            end
            done[offset] = reused
        end
        sets[i] = reused
    end
    return sets
end

local function readpairclasssets(f,nofclasses1,nofclasses2,format1,format2,mainoffset,getdelta)
    local classlist1  = { }
    for i=1,nofclasses1 do
        local classlist2 = { }
        classlist1[i] = classlist2
        for j=1,nofclasses2 do
            local one = readposition(f,format1,mainoffset,getdelta)
            local two = readposition(f,format2,mainoffset,getdelta)
            if one or two then
                classlist2[j] = { one, two }
            else
                classlist2[j] = false
            end
        end
    end
    return classlist1
end

-- no real gain in kerns as we pack

function gposhandlers.single(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype  = readushort(f)
    local getdelta = fontdata.temporary.getdelta
    if subtype == 1 then
        local coverage = readushort(f)
        local format   = readushort(f)
        local value    = readposition(f,format,tableoffset,getdelta)
        local coverage = readcoverage(f,tableoffset+coverage)
        for index, newindex in next, coverage do
            coverage[index] = value -- will be packed and shared anyway
        end
        return {
            format   = "single",
            coverage = coverage,
        }
    elseif subtype == 2 then
        local coverage  = readushort(f)
        local format    = readushort(f)
        local nofvalues = readushort(f)
        local values    = { }
        for i=1,nofvalues do
            values[i] = readposition(f,format,tableoffset,getdelta)
        end
        local coverage = readcoverage(f,tableoffset+coverage)
        for index, newindex in next, coverage do
            coverage[index] = values[newindex+1]
        end
        return {
            format   = "single",
            coverage = coverage,
        }
    else
        report("unsupported subtype %a in %a positioning",subtype,"single")
    end
end

-- this needs checking! if no second pair then another advance over the list

-- ValueFormat1 applies to the ValueRecord of the first glyph in each pair. ValueRecords for all first glyphs must use ValueFormat1. If ValueFormat1 is set to zero (0), the corresponding glyph has no ValueRecord and, therefore, should not be repositioned.
-- ValueFormat2 applies to the ValueRecord of the second glyph in each pair. ValueRecords for all second glyphs must use ValueFormat2. If ValueFormat2 is set to null, then the second glyph of the pair is the “next” glyph for which a lookup should be performed.

-- local simple = {
--     [true]  = { [true] = { true,  true }, [false] = { true  } },
--     [false] = { [true] = { false, true }, [false] = { false } },
-- }

-- function gposhandlers.pair(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
--     local tableoffset = lookupoffset + offset
--     setposition(f,tableoffset)
--     local subtype  = readushort(f)
--     local getdelta = fontdata.temporary.getdelta
--     if subtype == 1 then
--         local coverage = readushort(f)
--         local format1  = readushort(f)
--         local format2  = readushort(f)
--         local sets     = readarray(f)
--               sets     = readpairsets(f,tableoffset,sets,format1,format2,mainoffset,getdelta)
--               coverage = readcoverage(f,tableoffset + coverage)
--         local shared   = { } -- partial sparse, when set also needs to be handled in the packer
--         for index, newindex in next, coverage do
--             local set  = sets[newindex+1]
--             local hash = { }
--             for i=1,#set do
--                 local value = set[i]
--                 if value then
--                     local other  = value[1]
--                     if shared then
--                         local s = shared[value]
--                         if s == nil then
--                             local first  = value[2]
--                             local second = value[3]
--                             if first or second then
--                                 s = { first, second or nil } -- needs checking
--                             else
--                                 s = false
--                             end
--                             shared[value] = s
--                         end
--                         hash[other] = s or nil
--                     else
--                         local first  = value[2]
--                         local second = value[3]
--                         if first or second then
--                             hash[other] = { first, second or nil } -- needs checking
--                         else
--                             hash[other] = nil -- what if set, maybe warning
--                         end
--                     end
--                 end
--             end
--             coverage[index] = hash
--         end
--         return {
--             shared   = shared and true or nil,
--             format   = "pair",
--             coverage = coverage,
--         }
--     elseif subtype == 2 then
--         local coverage     = readushort(f)
--         local format1      = readushort(f)
--         local format2      = readushort(f)
--         local classdef1    = readushort(f)
--         local classdef2    = readushort(f)
--         local nofclasses1  = readushort(f) -- incl class 0
--         local nofclasses2  = readushort(f) -- incl class 0
--         local classlist    = readpairclasssets(f,nofclasses1,nofclasses2,format1,format2,tableoffset,getdelta)
--               coverage     = readcoverage(f,tableoffset+coverage)
--               classdef1    = readclassdef(f,tableoffset+classdef1,coverage)
--               classdef2    = readclassdef(f,tableoffset+classdef2,nofglyphs)
--         local usedcoverage = { }
--         local shared       = { } -- partial sparse, when set also needs to be handled in the packer
--         for g1, c1 in next, classdef1 do
--             if coverage[g1] then
--                 local l1 = classlist[c1]
--                 if l1 then
--                     local hash = { }
--                     for paired, class in next, classdef2 do
--                         local offsets = l1[class]
--                         if offsets then
--                             local first  = offsets[1]
--                             local second = offsets[2]
--                             if first or second then
--                                 if shared then
--                                     local s1 = shared[first]
--                                     if s1 == nil then
--                                         s1 = { }
--                                         shared[first] = s1
--                                     end
--                                     local s2 = s1[second]
--                                     if s2 == nil then
--                                         s2 = { first, second or nil }
--                                         s1[second] = s2
--                                     end
--                                     hash[paired] = s2
--                                 else
--                                     hash[paired] = { first, second or nil }
--                                 end
--                             else
--                                 -- upto the next lookup for this combination
--                             end
--                         end
--                     end
--                     usedcoverage[g1] = hash
--                 end
--             end
--         end
--         return {
--             shared   = shared and true or nil,
--             format   = "pair",
--             coverage = usedcoverage,
--         }
--     elseif subtype == 3 then
--         report("yet unsupported subtype %a in %a positioning",subtype,"pair")
--     else
--         report("unsupported subtype %a in %a positioning",subtype,"pair")
--     end
-- end

function gposhandlers.pair(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype  = readushort(f)
    local getdelta = fontdata.temporary.getdelta
    if subtype == 1 then
        local coverage = readushort(f)
        local format1  = readushort(f)
        local format2  = readushort(f)
        local sets     = readarray(f)
              sets     = readpairsets(f,tableoffset,sets,format1,format2,mainoffset,getdelta)
              coverage = readcoverage(f,tableoffset + coverage)
        local shared   = { } -- partial sparse, when set also needs to be handled in the packer
        for index, newindex in next, coverage do
            local set  = sets[newindex+1]
            local hash = { }
            for i=1,#set do
                local value = set[i]
                if value then
                    local other = value[1]
                    local share = shared[value]
                    if share == nil then
                        local first  = value[2]
                        local second = value[3]
                        if first or second then
                            share = { first, second or nil } -- needs checking
                        else
                            share = false
                        end
                        shared[value] = share
                    end
                    hash[other] = share or nil -- really overload ?
                end
            end
            coverage[index] = hash
        end
        return {
            shared   = shared and true or nil,
            format   = "pair",
            coverage = coverage,
        }
    elseif subtype == 2 then
        local coverage     = readushort(f)
        local format1      = readushort(f)
        local format2      = readushort(f)
        local classdef1    = readushort(f)
        local classdef2    = readushort(f)
        local nofclasses1  = readushort(f) -- incl class 0
        local nofclasses2  = readushort(f) -- incl class 0
        local classlist    = readpairclasssets(f,nofclasses1,nofclasses2,format1,format2,tableoffset,getdelta)
              coverage     = readcoverage(f,tableoffset+coverage)
              classdef1    = readclassdef(f,tableoffset+classdef1,coverage)
              classdef2    = readclassdef(f,tableoffset+classdef2,nofglyphs)
        local usedcoverage = { }
        local shared       = { } -- partial sparse, when set also needs to be handled in the packer
        for g1, c1 in next, classdef1 do
            if coverage[g1] then
                local l1 = classlist[c1]
                if l1 then
                    local hash = { }
                    for paired, class in next, classdef2 do
                        local offsets = l1[class]
                        if offsets then
                            local first  = offsets[1]
                            local second = offsets[2]
                            if first or second then
                                local s1 = shared[first]
                                if s1 == nil then
                                    s1 = { }
                                    shared[first] = s1
                                end
                                local s2 = s1[second]
                                if s2 == nil then
                                    s2 = { first, second or nil }
                                    s1[second] = s2
                                end
                                hash[paired] = s2
                            end
                        end
                    end
                    usedcoverage[g1] = hash
                end
            end
        end
        return {
            shared   = shared and true or nil,
            format   = "pair",
            coverage = usedcoverage,
        }
    elseif subtype == 3 then
        report("yet unsupported subtype %a in %a positioning",subtype,"pair")
    else
        report("unsupported subtype %a in %a positioning",subtype,"pair")
    end
end

function gposhandlers.cursive(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype  = readushort(f)
    local getdelta = fontdata.temporary.getdelta
    if subtype == 1 then
        local coverage   = tableoffset + readushort(f)
        local nofrecords = readushort(f)
        local records    = { }
        for i=1,nofrecords do
            local entry = readushort(f)
            local exit  = readushort(f)
            records[i] = {
             -- entry = entry ~= 0 and (tableoffset + entry) or false,
             -- exit  = exit  ~= 0 and (tableoffset + exit ) or nil,
                entry ~= 0 and (tableoffset + entry) or false,
                exit  ~= 0 and (tableoffset + exit ) or nil,
            }
        end
        -- slot 1 will become hash after loading and it must be unique because we
        -- pack the tables (packed we turn the cc-* into a zero)
        local cc = (fontdata.temporary.cursivecount or 0) + 1
        fontdata.temporary.cursivecount = cc
        cc = "cc-" .. cc
        coverage = readcoverage(f,coverage)
        for i=1,nofrecords do
            local r = records[i]
            records[i] = {
             -- 1,
                cc,
             -- readanchor(f,r.entry,getdelta) or false,
             -- readanchor(f,r.exit, getdelta) or nil,
                readanchor(f,r[1],getdelta) or false,
                readanchor(f,r[2],getdelta) or nil,
            }
        end
        for index, newindex in next, coverage do
            coverage[index] = records[newindex+1]
        end
        return {
            coverage = coverage,
        }
    else
        report("unsupported subtype %a in %a positioning",subtype,"cursive")
    end
end

local function handlemark(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,ligature)
    local tableoffset = lookupoffset + offset
    setposition(f,tableoffset)
    local subtype  = readushort(f)
    local getdelta = fontdata.temporary.getdelta
    if subtype == 1 then
        -- we are one based, not zero
        local markcoverage = tableoffset + readushort(f)
        local basecoverage = tableoffset + readushort(f)
        local nofclasses   = readushort(f)
        local markoffset   = tableoffset + readushort(f)
        local baseoffset   = tableoffset + readushort(f)
        --
        local markcoverage = readcoverage(f,markcoverage)
        local basecoverage = readcoverage(f,basecoverage,true) -- TO BE CHECKED: true
        --
        setposition(f,markoffset)
        local markclasses    = { }
        local nofmarkclasses = readushort(f)
        --
        local lastanchor  = fontdata.lastanchor or 0
        local usedanchors = { }
        --
        for i=1,nofmarkclasses do
            local class  = readushort(f) + 1
            local offset = readushort(f)
            if offset == 0 then
                markclasses[i] = false
            else
                markclasses[i] = { class, markoffset + offset }
            end
            usedanchors[class] = true
        end
        for i=1,nofmarkclasses do
            local mc = markclasses[i]
            if mc then
                mc[2] = readanchor(f,mc[2],getdelta)
            end
        end
        --
        setposition(f,baseoffset)
        local nofbaserecords = readushort(f)
        local baserecords    = { }
        --
        if ligature then
            -- 3 components
            -- 1 : class .. nofclasses -- NULL when empty
            -- 2 : class .. nofclasses -- NULL when empty
            -- 3 : class .. nofclasses -- NULL when empty
            for i=1,nofbaserecords do -- here i is the class
                local offset = readushort(f)
                if offset == 0 then
                    baserecords[i] = false
                else
                    baserecords[i] = baseoffset + offset
                end
            end
            for i=1,nofbaserecords do
                local recordoffset = baserecords[i]
                if recordoffset then
                    setposition(f,recordoffset)
                    local nofcomponents = readushort(f)
                    local components = { }
                    for i=1,nofcomponents do
                        local classes = { }
                        for i=1,nofclasses do
                            local offset = readushort(f)
                            if offset ~= 0 then
                                classes[i] = recordoffset + offset
                            else
                                classes[i] = false
                            end
                        end
                        components[i] = classes
                    end
                    baserecords[i] = components
                end
            end
            local baseclasses = { } -- setmetatableindex("table")
            for i=1,nofclasses do
                baseclasses[i] = { }
            end
            for i=1,nofbaserecords do
                local components = baserecords[i]
                if components then
                    local b = basecoverage[i]
                    for c=1,#components do
                        local classes = components[c]
                        if classes then
                            for i=1,nofclasses do
                                local anchor = readanchor(f,classes[i],getdelta)
                                local bclass = baseclasses[i]
                                local bentry = bclass[b]
                                if bentry then
                                    bentry[c] = anchor
                                else
                                    bclass[b]= { [c] = anchor }
                                end
                            end
                        end
                    end
                end
            end
            for index, newindex in next, markcoverage do
                markcoverage[index] = markclasses[newindex+1] or nil
            end
            return {
                format      = "ligature",
                baseclasses = baseclasses,
                coverage    = markcoverage,
            }
        else
            for i=1,nofbaserecords do
                local r = { }
                for j=1,nofclasses do
                    local offset = readushort(f)
                    if offset == 0 then
                        r[j] = false
                    else
                        r[j] = baseoffset + offset
                    end
                end
                baserecords[i] = r
            end
            local baseclasses = { } -- setmetatableindex("table")
            for i=1,nofclasses do
                baseclasses[i] = { }
            end
            for i=1,nofbaserecords do
                local r = baserecords[i]
                local b = basecoverage[i]
                for j=1,nofclasses do
                    baseclasses[j][b] = readanchor(f,r[j],getdelta)
                end
            end
            for index, newindex in next, markcoverage do
                markcoverage[index] = markclasses[newindex+1] or nil
            end
            -- we could actually already calculate the displacement if we want
            return {
                format      = "base",
                baseclasses = baseclasses,
                coverage    = markcoverage,
            }
        end
    else
        report("unsupported subtype %a in",subtype)
    end

end

function gposhandlers.marktobase(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return handlemark(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
end

function gposhandlers.marktoligature(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return handlemark(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,true)
end

function gposhandlers.marktomark(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return handlemark(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
end

function gposhandlers.context(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return unchainedcontext(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,"positioning"), "context"
end

function gposhandlers.chainedcontext(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return chainedcontext(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,"positioning"), "chainedcontext"
end

function gposhandlers.extension(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs)
    return extension(f,fontdata,lookupid,lookupoffset,offset,glyphs,nofglyphs,gpostypes,gposhandlers,"positioning")
end

-- main loader

do

    local plugins = { }

    function plugins.size(f,fontdata,tableoffset,feature)
        if fontdata.designsize then
            -- yes, there are fonts with multiple size entries ... it probably relates
            -- to the other two fields (menu entries in some language)
        else
            local function check(offset)
                setposition(f,offset)
                local designsize = readushort(f)
                if designsize > 0 then -- we could also have a threshold
                    local fontstyleid = readushort(f)
                    local guimenuid   = readushort(f)
                    local minsize     = readushort(f)
                    local maxsize     = readushort(f)
                    if minsize == 0 and maxsize == 0 and fontstyleid == 0 and guimenuid == 0 then
                        minsize = designsize
                        maxsize = designsize
                    end
                    if designsize >= minsize and designsize <= maxsize then
                        return minsize, maxsize, designsize
                    end
                end
            end
            local minsize, maxsize, designsize = check(tableoffset+feature.offset+feature.parameters)
            if not designsize then
                -- some old adobe fonts have: tableoffset+feature.parameters and we could
                -- use some heuristic but why bother ... this extra check will be removed
                -- some day and/or when we run into an issue
                minsize, maxsize, designsize = check(tableoffset+feature.parameters)
                if designsize then
                    report("bad size feature in %a, falling back to wrong offset",fontdata.filename or "?")
                else
                    report("bad size feature in %a,",fontdata.filename or "?")
                end
            end
            if designsize then
                fontdata.minsize    = minsize
                fontdata.maxsize    = maxsize
                fontdata.designsize = designsize
            end
        end
    end

 -- function plugins.rvrn(f,fontdata,tableoffset,feature)
 --     -- todo, at least a message
 -- end

    -- feature order needs checking ... as we loop over a hash ... however, in the file
    -- they are sorted so order is not that relevant

    local function reorderfeatures(fontdata,scripts,features)
        local scriptlangs  = { }
        local featurehash  = { }
        local featureorder = { }
        for script, languages in next, scripts do
            for language, record in next, languages do
                local hash = { }
                local list = record.featureindices
                for k=1,#list do
                    local index   = list[k]
                    local feature = features[index]
                    local lookups = feature.lookups
                    local tag     = feature.tag
                    if tag then
                        hash[tag] = true
                    end
                    if lookups then
                        for i=1,#lookups do
                            local lookup = lookups[i]
                            local o = featureorder[lookup]
                            if o then
                                local okay = true
                                for i=1,#o do
                                    if o[i] == tag then
                                        okay = false
                                        break
                                    end
                                end
                                if okay then
                                    o[#o+1] = tag
                                end
                            else
                                featureorder[lookup] = { tag }
                            end
                            local f = featurehash[lookup]
                            if f then
                                local h = f[tag]
                                if h then
                                    local s = h[script]
                                    if s then
                                        s[language] = true
                                    else
                                        h[script] = { [language] = true }
                                    end
                                else
                                    f[tag] = { [script] = { [language] = true } }
                                end
                            else
                                featurehash[lookup] = { [tag] = { [script] = { [language] = true } } }
                            end
                            --
                            local h = scriptlangs[tag]
                            if h then
                                local s = h[script]
                                if s then
                                    s[language] = true
                                else
                                    h[script] = { [language] = true }
                                end
                            else
                                scriptlangs[tag] = { [script] = { [language] = true } }
                            end
                        end
                    end
                end
            end
        end
        return scriptlangs, featurehash, featureorder
    end

    local function readscriplan(f,fontdata,scriptoffset)
        setposition(f,scriptoffset)
        local nofscripts = readushort(f)
        local scripts    = { }
        for i=1,nofscripts do
            scripts[readtag(f)] = scriptoffset + readushort(f)
        end
        -- script list -> language system info
        local languagesystems = setmetatableindex("table")
        for script, offset in next, scripts do
            setposition(f,offset)
            local defaultoffset = readushort(f)
            local noflanguages  = readushort(f)
            local languages     = { }
            if defaultoffset > 0 then
                languages.dflt = languagesystems[offset + defaultoffset]
            end
            for i=1,noflanguages do
                local language      = readtag(f)
                local offset        = offset + readushort(f)
                languages[language] = languagesystems[offset]
            end
            scripts[script] = languages
        end
        -- script list -> language system info -> feature list
        for offset, usedfeatures in next, languagesystems do
            if offset > 0 then
                setposition(f,offset)
                local featureindices        = { }
                usedfeatures.featureindices = featureindices
                usedfeatures.lookuporder    = readushort(f) -- reserved, not used (yet)
                usedfeatures.requiredindex  = readushort(f) -- relates to required (can be 0xFFFF)
                local noffeatures           = readushort(f)
                for i=1,noffeatures do
                    featureindices[i] = readushort(f) + 1
                end
            end
        end
        return scripts
    end

    local function readfeatures(f,fontdata,featureoffset)
        setposition(f,featureoffset)
        local features    = { }
        local noffeatures = readushort(f)
        for i=1,noffeatures do
            -- also shared?
            features[i] = {
                tag    = readtag(f),
                offset = readushort(f)
            }
        end
        --
        for i=1,noffeatures do
            local feature = features[i]
            local offset  = featureoffset+feature.offset
            setposition(f,offset)
            local parameters = readushort(f) -- feature.parameters
            local noflookups = readushort(f)
            if noflookups > 0 then
--                 local lookups   = { }
--                 feature.lookups = lookups
--                 for j=1,noflookups do
--                     lookups[j] = readushort(f) + 1
--                 end
                local lookups   = readcardinaltable(f,noflookups,ushort)
                feature.lookups = lookups
                for j=1,noflookups do
                    lookups[j] = lookups[j] + 1
                end
            end
            if parameters > 0 then
                feature.parameters = parameters
                local plugin = plugins[feature.tag]
                if plugin then
                    plugin(f,fontdata,featureoffset,feature)
                end
            end
        end
        return features
    end

    local function readlookups(f,lookupoffset,lookuptypes,featurehash,featureorder)
        setposition(f,lookupoffset)
        local noflookups = readushort(f)
        local lookups    = readcardinaltable(f,noflookups,ushort)
        for lookupid=1,noflookups do
            local offset = lookups[lookupid]
            setposition(f,lookupoffset+offset)
            local subtables    = { }
            local typebits     = readushort(f)
            local flagbits     = readushort(f)
            local lookuptype   = lookuptypes[typebits]
            local lookupflags  = lookupflags[flagbits]
            local nofsubtables = readushort(f)
            for j=1,nofsubtables do
                subtables[j] = offset + readushort(f) -- we can probably put lookupoffset here
            end
            -- which one wins?
            local markclass = band(flagbits,0x0010) ~= 0 -- usemarkfilteringset
            if markclass then
                markclass = readushort(f) -- + 1
            end
            local markset = rshift(flagbits,8)
            if markset > 0 then
                markclass = markset -- + 1
            end
            lookups[lookupid] = {
                type      = lookuptype,
             -- chain     = chaindirections[lookuptype] or nil,
                flags     = lookupflags,
                name      = lookupid,
                subtables = subtables,
                markclass = markclass,
                features  = featurehash[lookupid], -- not if extension
                order     = featureorder[lookupid],
            }
        end
        return lookups
    end

    local f_lookupname = formatters["%s_%s_%s"]

    local function resolvelookups(f,lookupoffset,fontdata,lookups,lookuptypes,lookuphandlers,what,tableoffset)

        local sequences      = fontdata.sequences  or { }
        local sublookuplist  = fontdata.sublookups or { }
        fontdata.sequences   = sequences
        fontdata.sublookups  = sublookuplist
        local nofsublookups  = #sublookuplist
        local nofsequences   = #sequences -- 0
        local lastsublookup  = nofsublookups
        local lastsequence   = nofsequences
        local lookupnames    = lookupnames[what]
        local sublookuphash  = { }
        local sublookupcheck = { }
        local glyphs         = fontdata.glyphs
        local nofglyphs      = fontdata.nofglyphs or #glyphs
        local noflookups     = #lookups
        local lookupprefix   = sub(what,2,2) -- g[s|p][ub|os]
        --
        local usedlookups    = false -- setmetatableindex("number")
        --
        local allsteps = { } -- new per 2022-09-25

        for lookupid=1,noflookups do
            local lookup     = lookups[lookupid]
            local lookuptype = lookup.type
            local subtables  = lookup.subtables
            local features   = lookup.features
            local handler    = lookuphandlers[lookuptype]
            if handler then
                local nofsubtables = #subtables
                local order        = lookup.order
                local flags        = lookup.flags
                -- this is expected in the font handler (faster checking)
                if flags[1] then flags[1] = "mark" end
                if flags[2] then flags[2] = "ligature" end
                if flags[3] then flags[3] = "base" end
                --
                local markclass    = lookup.markclass
             -- local chain        = lookup.chain
                if nofsubtables > 0 then
                    local steps     = { }
                    local nofsteps  = 0
                    local oldtype   = nil
                    for s=1,nofsubtables do
                        local step, lt = handler(f,fontdata,lookupid,lookupoffset,subtables[s],glyphs,nofglyphs)
                        if lt then
                            lookuptype = lt
                            if oldtype and lt ~= oldtype then
                                report("messy %s lookup type %a and %a",what,lookuptype,oldtype)
                            end
                            oldtype = lookuptype
                        end
                        if not step then
                            report("unsupported %s lookup type %a",what,lookuptype)
                        else
                            nofsteps = nofsteps + 1
                            steps[nofsteps] = step
                            local rules = step.rules
                            if rules then
                                allsteps[#allsteps+1] = step -- new per 2022-09-25
                                for i=1,#rules do
                                    local rule         = rules[i]
                                    local before       = rule.before
                                    local current      = rule.current
                                    local after        = rule.after
                                    local replacements = rule.replacements
                                    if before then
                                        for i=1,#before do
                                            before[i] = tohash(before[i])
                                        end
                                        -- as with original ctx ff loader
                                        rule.before = reversed(before)
                                    end
                                    if current then
                                        if replacements then
                                            -- We have a reverse lookup and therefore only one current entry. We might need
                                            -- to reverse the order in the before and after lists so that needs checking.
                                            local first = current[1]
                                            local hash  = { }
                                            local repl  = { }
                                            for i=1,#first do
                                                local c = first[i]
                                                hash[c] = true
                                                repl[c] = replacements[i]
                                            end
                                            rule.current      = { hash }
                                            rule.replacements = repl
                                        else
                                            for i=1,#current do
                                                current[i] = tohash(current[i])
                                            end
                                        end
                                    else
                                        -- weird lookup
                                    end
                                    if after then
                                        for i=1,#after do
                                            after[i] = tohash(after[i])
                                        end
                                    end
                                    if usedlookups then
                                        local lookups = rule.lookups
                                        if lookups then
                                            for k, v in next, lookups do
                                                if v then
                                                    for k, v in next, v do
                                                        usedlookups[v] = usedlookups[v] + 1
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if nofsteps ~= nofsubtables then
                        report("bogus subtables removed in %s lookup type %a",what,lookuptype)
                    end
                    lookuptype = lookupnames[lookuptype] or lookuptype
                    if features then
                        nofsequences = nofsequences + 1
                     -- report("registering %i as sequence step %i",lookupid,nofsequences)
                        local l = {
                            index     = nofsequences,
                            name      = f_lookupname(lookupprefix,"s",lookupid+lookupidoffset),
                            steps     = steps,
                            nofsteps  = nofsteps,
                            type      = lookuptype,
                            markclass = markclass or nil,
                            flags     = flags,
                         -- chain     = chain,
                            order     = order,
                            features  = features,
                        }
                        sequences[nofsequences] = l
                        lookup.done = l
                    else
                        nofsublookups = nofsublookups + 1
                     -- report("registering %i as sublookup %i",lookupid,nofsublookups)
                        local l = {
                            index     = nofsublookups,
                            name      = f_lookupname(lookupprefix,"l",lookupid+lookupidoffset),
                            steps     = steps,
                            nofsteps  = nofsteps,
                            type      = lookuptype,
                            markclass = markclass or nil,
                            flags     = flags,
                         -- chain     = chain,
                        }
                        sublookuplist[nofsublookups] = l
                        sublookuphash[lookupid] = nofsublookups
                        sublookupcheck[lookupid] = 0
                        lookup.done = l
                    end
                else
                    report("no subtables for lookup %a",lookupid)
                end
            else
                report("no handler for lookup %a with type %a",lookupid,lookuptype)
            end
        end

        if usedlookups then
            report("used %s lookups: % t",what,sortedkeys(usedlookups))
        end

        -- When we have a context, we have sublookups that resolve into lookups for which we need to
        -- know the type. We split the main lookuptable in two parts: sequences (the main lookups)
        -- and subtable lookups (simple specs with no features). We could keep them merged and might do
        -- that once we only use this loader. Then we can also move the simple specs into the sequence.
        -- After all, we pack afterwards.

        local reported = { }

        local function report_issue(i,what,step,kind)
--             if not reported[step] then
                report("rule %i in step %i of %s has %s lookups",i,step,what,kind)
--                 reported[name] = true
--             end
        end

     -- for i=lastsequence+1,nofsequences do
     --     local sequence = sequences[i]
     --     local steps    = sequence.steps
     --     for i=1,#steps do
     --         local step  = steps[i]

            for s=1,#allsteps do          -- new per 2022-09-25
                local step  = allsteps[s] -- new per 2022-09-25
                local rules = step.rules
                if rules then
                    for i=1,#rules do
                        local rule     = rules[i]
                        local rlookups = rule.lookups
                        if not rlookups then
                            report_issue(i,what,s,"no")
                        elseif not next(rlookups) then
                            -- can be ok as it aborts a chain sequence
                         -- report_issue(i,what,s,"empty")
                            rule.lookups = nil
                        else
                            -- we can have holes in rlookups flagged false and we can have multiple lookups
                            -- applied (first time seen in seguemj)
                            local length = #rlookups
                            for index=1,length do
                                local lookuplist = rlookups[index]
                                if lookuplist then
                                    local length   = #lookuplist
                                    local found    = { }
                                    local noffound = 0
                                    for index=1,length do
                                        local lookupid = lookuplist[index]
                                        if lookupid then
                                            local h = sublookuphash[lookupid]
                                            if not h then
                                                -- here we have a lookup that is used independent as well
                                                -- as in another one
                                                local lookup = lookups[lookupid]
                                                if lookup then
                                                    local d = lookup.done
                                                    if d then
                                                        nofsublookups = nofsublookups + 1
                                                     -- report("registering %i as sublookup %i",lookupid,nofsublookups)
                                                        local l = {
                                                            index     = nofsublookups, -- handy for tracing
                                                            name      = f_lookupname(lookupprefix,"d",lookupid+lookupidoffset),
                                                            derived   = true,          -- handy for tracing
                                                            steps     = d.steps,
                                                            nofsteps  = d.nofsteps,
                                                            type      = d.lookuptype or "gsub_single", -- todo: check type
                                                            markclass = d.markclass or nil,
                                                            flags     = d.flags,
                                                         -- chain     = d.chain,
                                                        }
                                                        sublookuplist[nofsublookups] = copy(l) -- we repack later
                                                        sublookuphash[lookupid] = nofsublookups
                                                        sublookupcheck[lookupid] = 1
                                                        h = nofsublookups
                                                    else
                                                        report_issue(i,what,s,"missing")
                                                        rule.lookups = nil
                                                        break
                                                    end
                                                else
                                                    report_issue(i,what,s,"bad")
                                                    rule.lookups = nil
                                                    break
                                                end
                                            else
                                                sublookupcheck[lookupid] = sublookupcheck[lookupid] + 1
                                            end
                                            if h then
                                                noffound = noffound + 1
                                                found[noffound] = h
                                            end
                                        end
                                    end
                                    rlookups[index] = noffound > 0 and found or false
                                else
                                    rlookups[index] = false
                                end
                            end
                        end
                    end
                end
            end
     -- end -- new per 2022-09-25

        for i, n in sortedhash(sublookupcheck) do
            local l = lookups[i]
            local t = l.type
            if n == 0 and t ~= "extension" then
                local d = l.done
                report("%s lookup %s of type %a is not used",what,d and d.name or l.name,t)
            end
        end

    end

    local function loadvariations(f,fontdata,variationsoffset,lookuptypes,featurehash,featureorder)
        setposition(f,variationsoffset)
        local version    = readulong(f) -- two times readushort
        local nofrecords = readulong(f)
        local records    = { }
        for i=1,nofrecords do
            records[i] = {
                conditions    = readulong(f),
                substitutions = readulong(f),
            }
        end
        for i=1,nofrecords do
            local record = records[i]
            local offset = record.conditions
            if offset == 0 then
                record.condition = nil
                record.matchtype = "always"
            else
                local offset = variationsoffset+offset
                setposition(f,offset)
                local nofconditions = readushort(f)
                local conditions    = { }
                for i=1,nofconditions do
                    conditions[i] = offset + readulong(f)
                end
                record.conditions = conditions
                record.matchtype  = "condition"
            end
        end
        for i=1,nofrecords do
            local record = records[i]
            if record.matchtype == "condition" then
                local conditions = record.conditions
                for i=1,#conditions do
                    setposition(f,conditions[i])
                    conditions[i] = {
                        format   = readushort(f),
                        axis     = readushort(f),
                        minvalue = read2dot14(f),
                        maxvalue = read2dot14(f),
                    }
                end
            end
        end

        for i=1,nofrecords do
            local record = records[i]
            local offset = record.substitutions
            if offset == 0 then
                record.substitutions = { }
            else
                setposition(f,variationsoffset + offset)
                local version          = readulong(f)
                local nofsubstitutions = readushort(f)
                local substitutions    = { }
                for i=1,nofsubstitutions do
                    substitutions[readushort(f)] = readulong(f)
                end
                for index, alternates in sortedhash(substitutions) do
                    if index == 0 then
                        record.substitutions = false
                    else
                        local tableoffset = variationsoffset + offset + alternates
                        setposition(f,tableoffset)
                        local parameters = readulong(f) -- feature parameters
                        local noflookups = readushort(f)
                        local lookups    = readcardinaltable(f,noflookups,ushort) -- not sure what to do with these
                        -- todo : resolve to proper lookups
                        record.substitutions = lookups
                    end
                end
            end
        end
        setvariabledata(fontdata,"features",records)
    end

    local function readscripts(f,fontdata,what,lookuptypes,lookuphandlers,lookupstoo)
        local tableoffset = gotodatatable(f,fontdata,what,true)
        if tableoffset then
            local version          = readulong(f)
            local scriptoffset     = tableoffset + readushort(f)
            local featureoffset    = tableoffset + readushort(f)
            local lookupoffset     = tableoffset + readushort(f)
            -- MFK : Rubik-Regular.ttf : we need to delay adding the offset
         -- local variationsoffset = version > 0x00010000 and (tableoffset + readulong(f)) or 0
            local variationsoffset = version > 0x00010000 and readulong(f) or 0
            if not scriptoffset then
                return
            end
            local scripts  = readscriplan(f,fontdata,scriptoffset)
            local features = readfeatures(f,fontdata,featureoffset)
            --
            local scriptlangs, featurehash, featureorder = reorderfeatures(fontdata,scripts,features)
            --
            if fontdata.features then
                fontdata.features[what] = scriptlangs
            else
                fontdata.features = { [what] = scriptlangs }
            end
            --
            if not lookupstoo then
                return
            end
            --
            local lookups = readlookups(f,lookupoffset,lookuptypes,featurehash,featureorder)
            --
            if lookups then
                resolvelookups(f,lookupoffset,fontdata,lookups,lookuptypes,lookuphandlers,what,tableoffset)
            end
            --
            if variationsoffset > 0 then
             -- loadvariations(f,fontdata,variationsoffset,lookuptypes,featurehash,featureorder)
                loadvariations(f,fontdata,tableoffset + variationsoffset,lookuptypes,featurehash,featureorder)
            end
        end
    end

    local function checkkerns(f,fontdata,specification)
        local datatable = fontdata.tables.kern
        if not datatable then
            return -- no kerns
        end
        local features     = fontdata.features
        local gposfeatures = features and features.gpos
        local name
        if not gposfeatures or not gposfeatures.kern then
            name = "kern"
        elseif specification.globalkerns then
            name = "globalkern"
        else
            report("ignoring global kern table, using gpos kern feature")
            return
        end
        setposition(f,datatable.offset)
        local version   = readushort(f)
        local noftables = readushort(f)
        if noftables > 1 then
            report("adding global kern table as gpos feature %a",name)
            local kerns = setmetatableindex("table")
            for i=1,noftables do
                local version  = readushort(f)
                local length   = readushort(f)
                local coverage = readushort(f)
                -- bit 8-15 of coverage: format 0 or 2
                local format   = rshift(coverage,8) -- is this ok
                if format == 0 then
                    local nofpairs      = readushort(f)
                    local searchrange   = readushort(f)
                    local entryselector = readushort(f)
                    local rangeshift    = readushort(f)
                    for i=1,nofpairs do
                        kerns[readushort(f)][readushort(f)] = readfword(f)
                    end
                elseif format == 2 then
                    -- apple specific so let's ignore it
                else
                    -- not supported by ms
                end
            end
            local feature = { dflt = { dflt = true } }
            if not features then
                fontdata.features = { gpos = { [name] = feature } }
            elseif not gposfeatures then
                fontdata.features.gpos = { [name] = feature }
            else
                gposfeatures[name] = feature
            end
            local sequences = fontdata.sequences
            if not sequences then
                sequences = { }
                fontdata.sequences = sequences
            end
            local nofsequences = #sequences + 1
            sequences[nofsequences] = {
                index     = nofsequences,
                name      = name,
                steps     = {
                    {
                        coverage = kerns,
                        format   = "kern",
                    },
                },
                nofsteps  = 1,
                type      = "gpos_pair",
                flags     = { false, false, false, false },
                order     = { name },
                features  = { [name] = feature },
            }
        else
            report("ignoring empty kern table of feature %a",name)
        end
    end

    function readers.gsub(f,fontdata,specification)
        if specification.details then
            readscripts(f,fontdata,"gsub",gsubtypes,gsubhandlers,specification.lookups)
        end
    end

    function readers.gpos(f,fontdata,specification)
        if specification.details then
            readscripts(f,fontdata,"gpos",gpostypes,gposhandlers,specification.lookups)
            if specification.lookups then
                checkkerns(f,fontdata,specification)
            end
        end
    end

end

function readers.gdef(f,fontdata,specification)
    if not specification.glyphs then
        return
    end
    local datatable = fontdata.tables.gdef
    if datatable then
        local tableoffset = datatable.offset
        setposition(f,tableoffset)
        local version          = readulong(f)
        local classoffset      = readushort(f)
        local attachmentoffset = readushort(f) -- used for bitmaps
        local ligaturecarets   = readushort(f) -- used in editors (maybe nice for tracing)
        local markclassoffset  = readushort(f)
        local marksetsoffset   = version >= 0x00010002 and readushort(f) or 0
        local varsetsoffset    = version >= 0x00010003 and readulong(f) or 0
        local glyphs           = fontdata.glyphs
        local marks            = { }
        local markclasses      = setmetatableindex("table")
        local marksets         = setmetatableindex("table")
        fontdata.marks         = marks
        fontdata.markclasses   = markclasses
        fontdata.marksets      = marksets
        -- class definitions
        if classoffset ~= 0 then
            setposition(f,tableoffset + classoffset)
            local classformat = readushort(f)
            if classformat == 1 then
                local firstindex = readushort(f)
                local lastindex  = firstindex + readushort(f) - 1
                for index=firstindex,lastindex do
                    local class = classes[readushort(f)]
                    if class == "mark" then
                        marks[index] = true
                    end
                    glyphs[index].class = class
                end
            elseif classformat == 2 then
                local nofranges = readushort(f)
                for i=1,nofranges do
                    local firstindex = readushort(f)
                    local lastindex  = readushort(f)
                    local class      = classes[readushort(f)]
                    if class then
                        for index=firstindex,lastindex do
                            glyphs[index].class = class
                            if class == "mark" then
                                marks[index] = true
                            end
                        end
                    end
                end
            end
        end
        -- mark classes
        if markclassoffset ~= 0 then
            setposition(f,tableoffset + markclassoffset)
            local classformat = readushort(f)
            if classformat == 1 then
                local firstindex = readushort(f)
                local lastindex  = firstindex + readushort(f) - 1
                for index=firstindex,lastindex do
                    markclasses[readushort(f)][index] = true
                end
            elseif classformat == 2 then
                local nofranges = readushort(f)
                for i=1,nofranges do
                    local firstindex = readushort(f)
                    local lastindex  = readushort(f)
                    local class      = markclasses[readushort(f)]
                    for index=firstindex,lastindex do
                        class[index] = true
                    end
                end
            end
        end
        -- mark sets : todo: just make the same as class sets above
        if marksetsoffset ~= 0 then
            marksetsoffset = tableoffset + marksetsoffset
            setposition(f,marksetsoffset)
            local format = readushort(f)
            if format == 1 then
                local nofsets = readushort(f)
                local sets    = readcardinaltable(f,nofsets,ulong)
                for i=1,nofsets do
                    local offset = sets[i]
                    if offset ~= 0 then
                        marksets[i] = readcoverage(f,marksetsoffset+offset)
                    end
                end
            end
        end

        local factors = specification.factors

        if (specification.variable or factors) and varsetsoffset ~= 0 then

            local regions, deltas = readvariationdata(f,tableoffset+varsetsoffset,factors)

         -- setvariabledata(fontdata,"gregions",regions)

            if factors then
                fontdata.temporary.getdelta = function(outer,inner)
                    local delta = deltas[outer+1]
                    if delta then
                        local d = delta.deltas[inner+1]
                        if d then
                            local scales = delta.scales
                            local dd = 0
                            for i=1,#scales do
                                local di = d[i]
                                if di then
                                    dd = dd + scales[i] * di
                                else
                                    break
                                end
                            end
                            return round(dd)
                        end
                    end
                    return 0
                end
            end

        end
    end
end

-- We keep this code here instead of font-otm.lua because we need coverage
-- helpers. Okay, these helpers could go to the main reader file some day.

local function readmathvalue(f)
    local v = readshort(f)
    skipshort(f,1) -- offset to device table
    return v
end

local function readmathconstants(f,fontdata,offset)
    setposition(f,offset)
    fontdata.mathconstants = {
        ScriptPercentScaleDown                   = readshort(f),
        ScriptScriptPercentScaleDown             = readshort(f),
        DelimitedSubFormulaMinHeight             = readushort(f),
        DisplayOperatorMinHeight                 = readushort(f),
        MathLeading                              = readmathvalue(f),
        AxisHeight                               = readmathvalue(f),
        AccentBaseHeight                         = readmathvalue(f),
        FlattenedAccentBaseHeight                = readmathvalue(f),
        SubscriptShiftDown                       = readmathvalue(f),
        SubscriptTopMax                          = readmathvalue(f),
        SubscriptBaselineDropMin                 = readmathvalue(f),
        SuperscriptShiftUp                       = readmathvalue(f),
        SuperscriptShiftUpCramped                = readmathvalue(f),
        SuperscriptBottomMin                     = readmathvalue(f),
        SuperscriptBaselineDropMax               = readmathvalue(f),
        SubSuperscriptGapMin                     = readmathvalue(f),
        SuperscriptBottomMaxWithSubscript        = readmathvalue(f),
        SpaceAfterScript                         = readmathvalue(f),
        UpperLimitGapMin                         = readmathvalue(f),
        UpperLimitBaselineRiseMin                = readmathvalue(f),
        LowerLimitGapMin                         = readmathvalue(f),
        LowerLimitBaselineDropMin                = readmathvalue(f),
        StackTopShiftUp                          = readmathvalue(f),
        StackTopDisplayStyleShiftUp              = readmathvalue(f),
        StackBottomShiftDown                     = readmathvalue(f),
        StackBottomDisplayStyleShiftDown         = readmathvalue(f),
        StackGapMin                              = readmathvalue(f),
        StackDisplayStyleGapMin                  = readmathvalue(f),
        StretchStackTopShiftUp                   = readmathvalue(f),
        StretchStackBottomShiftDown              = readmathvalue(f),
        StretchStackGapAboveMin                  = readmathvalue(f),
        StretchStackGapBelowMin                  = readmathvalue(f),
        FractionNumeratorShiftUp                 = readmathvalue(f),
        FractionNumeratorDisplayStyleShiftUp     = readmathvalue(f),
        FractionDenominatorShiftDown             = readmathvalue(f),
        FractionDenominatorDisplayStyleShiftDown = readmathvalue(f),
        FractionNumeratorGapMin                  = readmathvalue(f),
        FractionNumeratorDisplayStyleGapMin      = readmathvalue(f),
        FractionRuleThickness                    = readmathvalue(f),
        FractionDenominatorGapMin                = readmathvalue(f),
        FractionDenominatorDisplayStyleGapMin    = readmathvalue(f),
        SkewedFractionHorizontalGap              = readmathvalue(f),
        SkewedFractionVerticalGap                = readmathvalue(f),
        OverbarVerticalGap                       = readmathvalue(f),
        OverbarRuleThickness                     = readmathvalue(f),
        OverbarExtraAscender                     = readmathvalue(f),
        UnderbarVerticalGap                      = readmathvalue(f),
        UnderbarRuleThickness                    = readmathvalue(f),
        UnderbarExtraDescender                   = readmathvalue(f),
        RadicalVerticalGap                       = readmathvalue(f),
        RadicalDisplayStyleVerticalGap           = readmathvalue(f),
        RadicalRuleThickness                     = readmathvalue(f),
        RadicalExtraAscender                     = readmathvalue(f),
        RadicalKernBeforeDegree                  = readmathvalue(f),
        RadicalKernAfterDegree                   = readmathvalue(f),
        RadicalDegreeBottomRaisePercent          = readshort(f),
    }
end

local function readmathglyphinfo(f,fontdata,offset)
    setposition(f,offset)
    local italics    = readushort(f)
    local accents    = readushort(f)
    local extensions = readushort(f)
    local kerns      = readushort(f)
    local glyphs     = fontdata.glyphs
    if italics ~= 0 then
        setposition(f,offset+italics)
        local coverage  = readushort(f)
        local nofglyphs = readushort(f)
        coverage = readcoverage(f,offset+italics+coverage,true)
        setposition(f,offset+italics+4)
        for i=1,nofglyphs do
            local italic = readmathvalue(f)
            if italic ~= 0 then
                local glyph = glyphs[coverage[i]]
                local math  = glyph.math
                if not math then
                    glyph.math = { italic = italic }
                else
                    math.italic = italic
                end
            end
        end
        fontdata.hasitalics = true
    end
    if accents ~= 0 then
        setposition(f,offset+accents)
        local coverage  = readushort(f)
        local nofglyphs = readushort(f)
        coverage = readcoverage(f,offset+accents+coverage,true)
        setposition(f,offset+accents+4)
        for i=1,nofglyphs do
            local accent = readmathvalue(f)
            if accent ~= 0 then
                local glyph = glyphs[coverage[i]]
                local math  = glyph.math
                if not math then
                    glyph.math = { accent = accent }
                else
                    math.accent = accent -- will become math.topanchor
                end
            end
        end
    end
    if extensions ~= 0 then
        setposition(f,offset+extensions)
    end
    if kerns ~= 0 then
        local kernoffset = offset + kerns
        setposition(f,kernoffset)
        local coverage  = readushort(f)
        local nofglyphs = readushort(f)
        if nofglyphs > 0 then
            local function get(offset)
                setposition(f,kernoffset+offset)
                local n = readushort(f)
                if n == 0 then
                    local k = readmathvalue(f)
                    if k == 0 then
                        -- no need for it (happens sometimes)
                    else
                        return { { kern = k } }
                    end
                else
                    local l = { }
                    for i=1,n do
                        l[i] = { height = readmathvalue(f) }
                    end
                    for i=1,n do
                        l[i].kern = readmathvalue(f)
                    end
                    l[n+1] = { kern = readmathvalue(f) }
                    return l
                end
            end
            local kernsets = { }
            for i=1,nofglyphs do
                local topright    = readushort(f)
                local topleft     = readushort(f)
                local bottomright = readushort(f)
                local bottomleft  = readushort(f)
                kernsets[i] = {
                    topright    = topright    ~= 0 and topright    or nil,
                    topleft     = topleft     ~= 0 and topleft     or nil,
                    bottomright = bottomright ~= 0 and bottomright or nil,
                    bottomleft  = bottomleft  ~= 0 and bottomleft  or nil,
                }
            end
            coverage = readcoverage(f,kernoffset+coverage,true)
            for i=1,nofglyphs do
                local kernset = kernsets[i]
                if next(kernset) then
                    local k = kernset.topright    if k then kernset.topright    = get(k) end
                    local k = kernset.topleft     if k then kernset.topleft     = get(k) end
                    local k = kernset.bottomright if k then kernset.bottomright = get(k) end
                    local k = kernset.bottomleft  if k then kernset.bottomleft  = get(k) end
                    if next(kernset) then
                        local glyph = glyphs[coverage[i]]
                        local math  = glyph.math
                        if math then
                            math.kerns = kernset
                        else
                            glyph.math = { kerns = kernset }
                        end
                    end
                end
            end
        end
    end
end

local function readmathvariants(f,fontdata,offset)
    setposition(f,offset)
    local glyphs        = fontdata.glyphs
    local minoverlap    = readushort(f)
    local vcoverage     = readushort(f)
    local hcoverage     = readushort(f)
    local vnofglyphs    = readushort(f)
    local hnofglyphs    = readushort(f)
    local vconstruction = readcardinaltable(f,vnofglyphs,ushort)
    local hconstruction = readcardinaltable(f,hnofglyphs,ushort)

    fontdata.mathconstants.MinConnectorOverlap = minoverlap

    -- variants[i] = {
    --     glyph   = readushort(f),
    --     advance = readushort(f),
    -- }

    local function get(offset,coverage,nofglyphs,construction,kvariants,kparts,kitalic,korientation,orientation)
        if coverage ~= 0 and nofglyphs > 0 then
            local coverage = readcoverage(f,offset+coverage,true)
            for i=1,nofglyphs do
                local c = construction[i]
                if c ~= 0 then
                    local index = coverage[i]
                    local glyph = glyphs[index]
                    local math  = glyph.math
                    setposition(f,offset+c)
                    local assembly    = readushort(f)
                    local nofvariants = readushort(f)
                    if nofvariants > 0 then
                        local variants, v = nil, 0
                        for i=1,nofvariants do
                            local variant = readushort(f)
                            if variant == index then
                                -- ignore
                            elseif variants then
                                v = v + 1
                                variants[v] = variant
                            else
                                v = 1
                                variants = { variant }
                            end
                            skipshort(f)
                        end
                        if not variants then
                            -- only self
                        elseif not math then
                            math = { [kvariants] = variants }
                            glyph.math = math
                        else
                            math[kvariants] = variants
                        end
                    end
                    if assembly ~= 0 then
                        setposition(f,offset + c + assembly)
                        local italic   = readmathvalue(f)
                        local nofparts = readushort(f)
                        local parts    = { }
                        for i=1,nofparts do
                            local p = {
                                glyph   = readushort(f),
                                start   = readushort(f),
                                ["end"] = readushort(f),
                                advance = readushort(f),
                            }
                            local flags = readushort(f)
                            if band(flags,0x0001) ~= 0 then
                                p.extender = 1 -- true
                            end
                            parts[i] = p
                        end
                        if not math then
                            math = {
                                [kparts] = parts
                            }
                            glyph.math = math
                        else
                            math[kparts] = parts
                        end
                        if italic and italic ~= 0 then
                            math[kitalic] = italic
                        end
                        if orientation then
                            math[korientation] = orientation
                        end
                    end
                end
            end
        end
    end

 -- if LUATEXENGINE == "luametatex" then
    if CONTEXTLMTXMODE and CONTEXTLMTXMODE > 0 then
        get(offset,hcoverage,hnofglyphs,hconstruction,"variants","parts","partsitalic","partsorientation","horizontal")
        get(offset,vcoverage,vnofglyphs,vconstruction,"variants","parts","partsitalic","partsorientation","vertical")
    else
        get(offset,vcoverage,vnofglyphs,vconstruction,"vvariants","vparts","vitalic")
        get(offset,hcoverage,hnofglyphs,hconstruction,"hvariants","hparts","hitalic")
    end
end

function readers.math(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"math",specification.glyphs)
    if tableoffset then
        local version = readulong(f)
     -- if version ~= 0x00010000 then
     --     report("table version %a of %a is not supported (yet), maybe font %s is bad",version,"math",fontdata.filename)
     --     return
     -- end
        local constants = readushort(f)
        local glyphinfo = readushort(f)
        local variants  = readushort(f)
        if constants == 0 then
            report("the math table of %a has no constants",fontdata.filename)
        else
            readmathconstants(f,fontdata,tableoffset+constants)
        end
        if glyphinfo ~= 0 then
            readmathglyphinfo(f,fontdata,tableoffset+glyphinfo)
        end
        if variants ~= 0 then
            readmathvariants(f,fontdata,tableoffset+variants)
        end
    end
end

function readers.colr(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"colr",specification.glyphs)
    if tableoffset then
        local version = readushort(f)
        if version ~= 0 and version ~= 1 then
            report("table version %a of %a is not supported (yet), maybe font %s is bad",version,"colr",fontdata.filename)
            return
        else
            -- both versions have this in common
        end
        if not fontdata.tables.cpal then
            report("color table %a in font %a has no mandate %a table","colr",fontdata.filename,"cpal")
            fontdata.colorpalettes = { }
        end
        local glyphs       = fontdata.glyphs
        local nofglyphs    = readushort(f)
        local baseoffset   = readulong(f)
        local layeroffset  = readulong(f)
        local noflayers    = readushort(f)
        local layerrecords = { }
        local maxclass     = 0
        -- The special value 0xFFFF is foreground (but we index from 1). It
        -- more looks like indices into a palette so 'class' is a better name
        -- than 'palette'.
        setposition(f,tableoffset + layeroffset)
        for i=1,noflayers do
            local slot  = readushort(f)
            local class = readushort(f)
            if class < 0xFFFF then
                class = class + 1
                if class > maxclass then
                    maxclass = class
                end
            end
            layerrecords[i] = {
                slot  = slot,
                class = class,
            }
        end
        fontdata.maxcolorclass = maxclass
        setposition(f,tableoffset + baseoffset)
        for i=0,nofglyphs-1 do
            local glyphindex = readushort(f)
            local firstlayer = readushort(f)
            local noflayers  = readushort(f)
            local t = { }
            for i=1,noflayers do
                t[i] = layerrecords[firstlayer+i]
            end
            glyphs[glyphindex].colors = t
        end
    end
    fontdata.hascolor = true
end

function readers.cpal(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"cpal",specification.glyphs)
    if tableoffset then
        local version = readushort(f)
     -- if version > 1 then
     --     report("table version %a of %a is not supported (yet), maybe font %s is bad",version,"cpal",fontdata.filename)
     --     return
     -- end
        local nofpaletteentries  = readushort(f)
        local nofpalettes        = readushort(f)
        local nofcolorrecords    = readushort(f)
        local firstcoloroffset   = readulong(f)
        local colorrecords       = { }
        local palettes           = readcardinaltable(f,nofpalettes,ushort)
        if version == 1 then
            -- used for guis
            local palettettypesoffset = readulong(f)
            local palettelabelsoffset = readulong(f)
            local paletteentryoffset  = readulong(f)
        end
        setposition(f,tableoffset+firstcoloroffset)
        for i=1,nofcolorrecords do
            local b, g, r, a = readbytes(f,4)
            colorrecords[i] = {
                r, g, b, a ~= 255 and a or nil,
            }
        end
        for i=1,nofpalettes do
            local p = { }
            local o = palettes[i]
            for j=1,nofpaletteentries do
                p[j] = colorrecords[o+j]
            end
            palettes[i] = p
        end
        fontdata.colorpalettes = palettes
    end
end

local compress   = gzip and gzip.compress
local compressed = compress and gzip.compressed

-- At some point I will delay loading and only store the offsets (in context lmtx
-- only).

-- compressed = false

function readers.svg(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"svg",specification.glyphs)
    if tableoffset then
        local version = readushort(f)
     -- if version ~= 0 then
     --     report("table version %a of %a is not supported (yet), maybe font %s is bad",version,"svg",fontdata.filename)
     --     return
     -- end
        local glyphs      = fontdata.glyphs
        local indexoffset = tableoffset + readulong(f)
        local reserved    = readulong(f)
        setposition(f,indexoffset)
        local nofentries  = readushort(f)
        local entries     = { }
        for i=1,nofentries do
            entries[i] = {
                first  = readushort(f),
                last   = readushort(f),
                offset = indexoffset + readulong(f),
                length = readulong(f),
            }
        end
        for i=1,nofentries do
            local entry = entries[i]
            setposition(f,entry.offset)
            local data = readstring(f,entry.length)
            if compressed and not compressed(data) then
                data = compress(data)
            end
            entries[i] = {
                first = entry.first,
                last  = entry.last,
                data  = data
            }
        end
        fontdata.svgshapes = entries
    end
    fontdata.hascolor = true
end

function readers.sbix(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"sbix",specification.glyphs)
    if tableoffset then
        local version    = readushort(f)
        local flags      = readushort(f)
        local nofstrikes = readulong(f)
        local strikes    = { }
        local nofglyphs  = fontdata.nofglyphs
        for i=1,nofstrikes do
            strikes[i] = readulong(f)
        end
        local shapes = { }
        local done   = 0
        for i=1,nofstrikes do
            local strikeoffset = strikes[i] + tableoffset
            setposition(f,strikeoffset)
            strikes[i] = {
                ppem   = readushort(f),
                ppi    = readushort(f),
                offset = strikeoffset
            }
        end
        -- highest first
        sort(strikes,function(a,b)
            if b.ppem == a.ppem then
                return b.ppi < a.ppi
            else
                return b.ppem < a.ppem
            end
        end)
        local glyphs  = { }
        local delayed = CONTEXTLMTXMODE and CONTEXTLMTXMODE > 0 or fonts.handlers.typethree
        for i=1,nofstrikes do
            local strike       = strikes[i]
            local strikeppem   = strike.ppem
            local strikeppi    = strike.ppi
            local strikeoffset = strike.offset
            setposition(f,strikeoffset)
            for i=0,nofglyphs do
                glyphs[i] = readulong(f)
            end
            local glyphoffset = glyphs[0]
            for i=0,nofglyphs-1 do
                local nextoffset = glyphs[i+1]
                if not shapes[i] then
                    local datasize = nextoffset - glyphoffset
                    if datasize > 0 then
                        setposition(f,strikeoffset + glyphoffset)
                        local x      = readshort(f)
                        local y      = readshort(f)
                        local tag    = readtag(f) -- or just skip, we never needed it till now
                        local size   = datasize - 8
                        local data   = nil
                        local offset = nil
                        if delayed then
                            offset = getposition(f)
                            data   = nil
                        else
                            data   = readstring(f,size)
                            size   = nil
                        end
                        shapes[i] = {
                            x    = x,
                            y    = y,
                            o    = offset,
                            s    = size,
                            data = data,
                         -- tag  = tag, -- maybe for tracing
                         -- ppem = strikeppem, -- not used, for tracing
                         -- ppi  = strikeppi,  -- not used, for tracing
                        }
                        done = done + 1
                        if done == nofglyphs then
                            break
                        end
                    end
                end
                glyphoffset = nextoffset
            end
        end
        fontdata.pngshapes = shapes
    end
end

-- Another bitmap (so not that useful) format. But Luigi found a font that
-- has them , so ...

do

    local function getmetrics(f)
        return {
            ascender              = readinteger(f),
            descender             = readinteger(f),
            widthmax              = readuinteger(f),
            caretslopedumerator   = readinteger(f),
            caretslopedenominator = readinteger(f),
            caretoffset           = readinteger(f),
            minorigin             = readinteger(f),
            minadvance            = readinteger(f),
            maxbefore             = readinteger(f),
            minafter              = readinteger(f),
            pad1                  = readinteger(f),
            pad2                  = readinteger(f),
        }
    end

    -- bad names

    local function getbigmetrics(f)
        -- bigmetrics, maybe just skip 9 bytes
        return {
            height       = readuinteger(f),
            width        = readuinteger(f),
            horiBearingX = readinteger(f),
            horiBearingY = readinteger(f),
            horiAdvance  = readuinteger(f),
            vertBearingX = readinteger(f),
            vertBearingY = readinteger(f),
            vertAdvance  = readuinteger(f),
        }
    end

    local function getsmallmetrics(f)
        -- smallmetrics, maybe just skip 5 bytes
        return {
            height   = readuinteger(f),
            width    = readuinteger(f),
            bearingX = readinteger(f),
            bearingY = readinteger(f),
            advance  = readuinteger(f),
        }
    end

    function readers.cblc(f,fontdata,specification)
        -- should we delay this ?
        local ctdttableoffset = gotodatatable(f,fontdata,"cbdt",specification.glyphs)
        if not ctdttableoffset then
            return
        end
        local cblctableoffset = gotodatatable(f,fontdata,"cblc",specification.glyphs)
        if cblctableoffset then
            local majorversion  = readushort(f)
            local minorversion  = readushort(f)
            local nofsizetables = readulong(f)
            local sizetables    = { }
            local shapes        = { }
            local subtables     = { }
            for i=1,nofsizetables do
                sizetables[i] = {
                    subtables    = readulong(f),
                    indexsize    = readulong(f),
                    nofsubtables = readulong(f),
                    colorref     = readulong(f),
                    hormetrics   = getmetrics(f),
                    vermetrics   = getmetrics(f),
                    firstindex   = readushort(f),
                    lastindex    = readushort(f),
                    ppemx        = readbyte(f),
                    ppemy        = readbyte(f),
                    bitdepth     = readbyte(f),
                    flags        = readbyte(f),
                }
            end
            sort(sizetables,function(a,b)
                if b.ppemx == a.ppemx then
                    return b.bitdepth < a.bitdepth
                else
                    return b.ppemx < a.ppemx
                end
            end)
            for i=1,nofsizetables do
                local s = sizetables[i]
                local d = false
                for j=s.firstindex,s.lastindex do
                    if not shapes[j] then
                        shapes[j] = i
                        d = true
                    end
                end
                if d then
                    s.used = true
                end
            end
            for i=1,nofsizetables do
                local s = sizetables[i]
                if s.used then
                    local offset = s.subtables
                    setposition(f,cblctableoffset+offset)
                    for j=1,s.nofsubtables do
                        local firstindex  = readushort(f)
                        local lastindex   = readushort(f)
                        local tableoffset = readulong(f) + offset
                        for k=firstindex,lastindex do
                            if shapes[k] == i then
                                local s = subtables[tableoffset]
                                if not s then
                                    s = {
                                        firstindex = firstindex,
                                        lastindex  = lastindex,
                                    }
                                    subtables[tableoffset] = s
                                end
                                shapes[k] = s
                            end
                        end
                    end
                end
            end

            -- there is no need to sort in string stream but we have a nicer trace
            -- if needed

            for offset, subtable in sortedhash(subtables) do
                local tabletype  = readushort(f)
                subtable.format  = readushort(f)
                local baseoffset = readulong(f) + ctdttableoffset
                local offsets    = { }
                local metrics    = nil
                if tabletype == 1 then
                    -- we have the usual one more to get the size
                    for i=subtable.firstindex,subtable.lastindex do
                        offsets[i] = readulong(f) + baseoffset
                    end
                    skipbytes(f,4)
                elseif tabletype == 2 then
                    local size = readulong(f)
                    local done = baseoffset
                    metrics = getbigmetrics(f)
                    for i=subtable.firstindex,subtable.lastindex do
                        offsets[i] = done
                        done = done + size
                    end
                elseif tabletype == 3 then
                    -- we have the usual one more to get the size
                    local n = subtable.lastindex - subtable.firstindex + 2
                    for i=subtable.firstindex,subtable.lastindex do
                        offsets[i] = readushort(f) + baseoffset
                    end
                    if math.odd(n) then
                        skipbytes(f,4)
                    else
                        skipbytes(f,2)
                    end
                elseif tabletype == 4 then
                    for i=1,readulong(f) do
                        offsets[readushort(f)] = readushort(f) + baseoffset
                    end
                elseif tabletype == 5 then
                    local size = readulong(f)
                    local done = baseoffset
                    metrics = getbigmetrics(f)
                    local n = readulong(f)
                    for i=1,n do
                        offsets[readushort(f)] = done
                        done = done + size
                    end
                    if math.odd(n) then
                        skipbytes(f,2)
                    end
                else
                    return -- unsupported format
                end
                subtable.offsets = offsets
                subtable.metrics = metrics
            end

            -- we only support a few sensible types ... there are hardly any fonts so
            -- why are there so many variants ... not the best spec

            local default = { width = 0, height = 0 }
            local glyphs  = fontdata.glyphs
            local delayed = CONTEXTLMTXMODE and CONTEXTLMTXMODE > 0 or fonts.handlers.typethree

            for index, subtable in sortedhash(shapes) do
                if type(subtable) == "table" then
                    local data    = nil
                    local size    = nil
                    local metrics = default
                    local format  = subtable.format
                    local offset  = subtable.offsets[index]
                    setposition(f,offset)
                    if format == 17 then
                        metrics = getsmallmetrics(f)
                        size    = true
                    elseif format == 18 then
                        metrics = getbigmetrics(f)
                        size    = true
                    elseif format == 19 then
                        metrics = subtable.metrics
                        size    = true
                    else
                        -- forget about it
                    end
                    if size then
                        size = readulong(f)
                        if delayed then
                            offset = getposition(f)
                            data   = nil
                        else
                            offset = nil
                            data   = readstring(f,size)
                            size   = nil
                        end
                    else
                        offset = nil
                    end
                    local x = metrics.width
                    local y = metrics.height
                    shapes[index] = {
                        x    = x,
                        y    = y,
                        o    = offset,
                        s    = size,
                        data = data,
                    }
                    -- I'll look into this in more details when needed
                    -- as we can use the bearings to get better boxes.
                    local glyph = glyphs[index]
                    if not glyph.boundingbox then
                        local width  = glyph.width
                        local height = width * y/x
                        glyph.boundingbox = { 0, 0, width, height }
                    end
                else
                    shapes[index] = {
                        x    = 0,
                        y    = 0,
                        data = "", -- or just nil
                    }
                end
            end

            fontdata.pngshapes = shapes -- we cheat
        end
    end

    function readers.cbdt(f,fontdata,specification)
     -- local tableoffset = gotodatatable(f,fontdata,"ctdt",specification.glyphs)
     -- if tableoffset then
     --     local majorversion = readushort(f)
     --     local minorversion = readushort(f)
     -- end
    end

    -- function readers.ebdt(f,fontdata,specification)
    --     if specification.glyphs then
    --     end
    -- end

    -- function readers.ebsc(f,fontdata,specification)
    --     if specification.glyphs then
    --     end
    -- end

    -- function readers.eblc(f,fontdata,specification)
    --     if specification.glyphs then
    --     end
    -- end

end

-- + AVAR : optional
-- + CFF2 : otf outlines
-- - CVAR : ttf hinting, not needed
-- + FVAR : the variations
-- + GVAR : ttf outline changes
-- + HVAR : horizontal changes
-- + MVAR : metric changes
-- + STAT : relations within fonts
-- * VVAR : vertical changes
--
-- * BASE : extra baseline adjustments
-- - GASP : not needed
-- + GDEF : not needed (carets)
-- + GPOS : adapted device tables (needed?)
-- + GSUB : new table
-- + NAME : 25 added

function readers.stat(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"stat",true) -- specification.variable
    if tableoffset then
        local extras       = fontdata.extras
        local version      = readulong(f) -- 0x00010000
        local axissize     = readushort(f)
        local nofaxis      = readushort(f)
        local axisoffset   = readulong(f)
        local nofvalues    = readushort(f)
        local valuesoffset = readulong(f)
        local fallbackname = extras[readushort(f)] -- beta fonts mess up
        local axis         = { }
        local values       = { }
        setposition(f,tableoffset+axisoffset)
        for i=1,nofaxis do
            local tag = readtag(f)
            axis[i] = {
                tag      = tag,
                name     = lower(extras[readushort(f)] or tag),
                ordering = readushort(f), -- maybe gaps
                variants = { }
            }
        end
        -- flags:
        --
        -- 0x0001 : OlderSiblingFontAttribute
        -- 0x0002 : ElidableAxisValueName
        -- 0xFFFC : reservedFlags
        --
        setposition(f,tableoffset+valuesoffset)
        for i=1,nofvalues do
            values[i] = readushort(f)
        end
        for i=1,nofvalues do
            setposition(f,tableoffset + valuesoffset + values[i])
            local format  = readushort(f)
            local index   = readushort(f) + 1
            local flags   = readushort(f)
            local name    = lower(extras[readushort(f)] or "no name")
            local value   = readfixed(f)
            local variant
            if format == 1 then
                variant = {
                    flags = flags,
                    name  = name,
                    value = value,
                }
            elseif format == 2 then
                variant = {
                    flags   = flags,
                    name    = name,
                    value   = value,
                    minimum = readfixed(f),
                    maximum = readfixed(f),
                }
            elseif format == 3 then
                variant = {
                    flags = flags,
                    name  = name,
                    value = value,
                    link  = readfixed(f),
                }
            end
            insert(axis[index].variants,variant)
        end
        sort(axis,function(a,b)
            return a.ordering < b.ordering
        end)
        for i=1,#axis do
            local a = axis[i]
            sort(a.variants,function(a,b)
                return a.name < b.name
            end)
            a.ordering = nil
        end
        setvariabledata(fontdata,"designaxis",axis)
        setvariabledata(fontdata,"fallbackname",fallbackname)
    end
end

-- The avar table is optional and used in combination with fvar. Given the
-- detailed explanation about bad values we expect the worst and do some
-- checking.

function readers.avar(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"avar",true) -- specification.variable
    if tableoffset then

        local function collect()
            local nofvalues = readushort(f)
            local values    = { }
            local lastfrom  = false
            local lastto    = false
            for i=1,nofvalues do
                local from = read2dot14(f)
                local to   = read2dot14(f)
                if lastfrom and from <= lastfrom then
                    -- ignore
                elseif lastto and to >= lastto then
                    -- ignore
                else
                    values[#values+1] = { from, to }
                    lastfrom, lastto = from, to
                end
            end
            nofvalues = #values
            if nofvalues > 2 then
                local some = values[1]
                if some[1] == -1 and some[2] == -1 then
                    some = values[nofvalues]
                    if some[1] == 1 and some[2] == 1 then
                        for i=2,nofvalues-1 do
                            some = values[i]
                            if some[1] == 0 and some[2] == 0 then
                                return values
                            end
                        end
                    end
                end
            end
            return false
        end

        local version  = readulong(f) -- 0x00010000
        local reserved = readushort(f)
        local nofaxis  = readushort(f)
        local segments = { }
        for i=1,nofaxis do
            segments[i] = collect()
        end
        setvariabledata(fontdata,"segments",segments)
    end
end

function readers.fvar(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"fvar",true) -- specification.variable or specification.instancenames
    if tableoffset then
        local version         = readulong(f) -- 0x00010000
        local offsettoaxis    = tableoffset + readushort(f)
        local reserved        = skipshort(f)
        -- pair 1
        local nofaxis         = readushort(f)
        local sizeofaxis      = readushort(f)
        -- pair 2
        local nofinstances    = readushort(f)
        local sizeofinstances = readushort(f)
        --
        local extras    = fontdata.extras
        local axis      = { }
        local instances = { }
        --
        setposition(f,offsettoaxis)
        --
        for i=1,nofaxis do
            axis[i] = {
                tag     = readtag(f),   -- ital opsz slnt wdth wght
                minimum = readfixed(f),
                default = readfixed(f),
                maximum = readfixed(f),
                flags   = readushort(f),
                name    = lower(extras[readushort(f)] or "bad name"),
            }
            local n = sizeofaxis - 20
            if n > 0 then
                skipbytes(f,n)
            elseif n < 0 then
                -- error
            end
        end
        --
        local nofbytes   = 2 + 2 + 2 + nofaxis * 4
        local readpsname = nofbytes <= sizeofinstances
        local skippable  = sizeofinstances - nofbytes
        for i=1,nofinstances do
            local subfamid = readushort(f)
            local flags    = readushort(f) -- 0, not used yet
            local values   = { }
            for i=1,nofaxis do
                values[i] = {
                    axis  = axis[i].tag,
                    value = readfixed(f),
                }
            end
            local psnameid = readpsname and readushort(f) or 0xFFFF
            if subfamid == 2 or subfamid == 17 then
                -- okay
            elseif subfamid == 0xFFFF then
                subfamid = nil
            elseif subfamid <= 256 or subfamid >= 32768 then
                subfamid = nil -- actually an error
            end
            if psnameid == 6 then
                -- okay
            elseif psnameid == 0xFFFF then
                psnameid = nil
            elseif psnameid <= 256 or psnameid >= 32768 then
                psnameid = nil -- actually an error
            end
            instances[i] = {
             -- flags     = flags,
                subfamily = extras[subfamid],
                psname    = psnameid and extras[psnameid] or nil,
                values    = values,
            }
            if skippable > 0 then
                skipbytes(f,skippable)
            end
        end
        setvariabledata(fontdata,"axis",axis)
        setvariabledata(fontdata,"instances",instances)
    end
end

function readers.hvar(f,fontdata,specification)
    local factors = specification.factors
    if not factors then
        return
    end
    local tableoffset = gotodatatable(f,fontdata,"hvar",specification.variable)
    if not tableoffset then
     -- report("no hvar table, expect problems due to messy widths")
        return
    end

    local version         = readulong(f) -- 0x00010000
    local variationoffset = tableoffset + readulong(f) -- the store
    local advanceoffset   = tableoffset + readulong(f)
    local lsboffset       = tableoffset + readulong(f)
    local rsboffset       = tableoffset + readulong(f)

    local regions    = { }
    local variations = { }
    local innerindex = { } -- size is mapcount
    local outerindex = { } -- size is mapcount
    local deltas     = { }

    if variationoffset > 0 then
        regions, deltas = readvariationdata(f,variationoffset,factors)
    end
    if not regions then
        -- for now .. what to do ?
        return
    end

    if advanceoffset > 0 then
        --
        -- innerIndexBitCountMask = 0x000F
        -- mapEntrySizeMask       = 0x0030
        -- reservedFlags          = 0xFFC0
        --
        -- outerIndex = entry >>       ((entryFormat & innerIndexBitCountMask) + 1)
        -- innerIndex = entry & ((1 << ((entryFormat & innerIndexBitCountMask) + 1)) - 1)
        --
        setposition(f,advanceoffset)
        local format       = readushort(f) -- todo: check
        local mapcount     = readushort(f)
        local entrysize    = rshift(band(format,0x0030),4) + 1
        local nofinnerbits = band(format,0x000F) + 1 -- n of inner bits
        local innermask    = lshift(1,nofinnerbits) - 1
        local readcardinal = read_cardinal[entrysize] -- 1 upto 4 bytes
        for i=0,mapcount-1 do
            local mapdata = readcardinal(f)
            outerindex[i] = rshift(mapdata,nofinnerbits)
            innerindex[i] = band(mapdata,innermask)
        end
        -- use last entry when no match i
        setvariabledata(fontdata,"hvarwidths",true)
        local glyphs = fontdata.glyphs
        for i=0,fontdata.nofglyphs-1 do
            local glyph = glyphs[i]
            local width = glyph.width
            if width then
                local outer = outerindex[i] or 0
                local inner = innerindex[i] or i
                if outer and inner then -- not needed
                    local delta = deltas[outer+1]
                    if delta then
                        local d = delta.deltas[inner+1]
                        if d then
                            local scales = delta.scales
                            local deltaw = 0
                            for i=1,#scales do
                                local di = d[i]
                                if di then
                                    deltaw = deltaw + scales[i] * di
                                else
                                    break -- can't happen
                                end
                            end
-- report("index: %i, outer: %i, inner: %i, deltas: %|t, scales: %|t, width: %i, delta %i",
--     i,outer,inner,d,scales,width,round(deltaw))
                            glyph.width = width + round(deltaw)
                        end
                    end
                end
            end
        end

    end

 -- if lsboffset > 0 then
 --     -- we don't use left side bearings
 -- end

 -- if rsboffset > 0 then
 --     -- we don't use right side bearings
 -- end

 -- setvariabledata(fontdata,"hregions",regions)

end

function readers.vvar(f,fontdata,specification)
    if not specification.variable then
        return
    end
end

function readers.mvar(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"mvar",specification.variable)
    if tableoffset then
        local version       = readulong(f) -- 0x00010000
        local reserved      = skipshort(f,1)
        local recordsize    = readushort(f)
        local nofrecords    = readushort(f)
        local offsettostore = tableoffset + readushort(f)
        local dimensions    = { }
        local factors       = specification.factors
        if factors then
            local regions, deltas = readvariationdata(f,offsettostore,factors)
            for i=1,nofrecords do
                local tag = readtag(f)
                local var = variabletags[tag]
                if var then
                    local outer = readushort(f)
                    local inner = readushort(f)
                    local delta = deltas[outer+1]
                    if delta then
                        local d = delta.deltas[inner+1]
                        if d then
                            local scales = delta.scales
                            local dd = 0
                            for i=1,#scales do
                                dd = dd + scales[i] * d[i]
                            end
                            var(fontdata,round(dd))
                        end
                    end
                else
                    skipshort(f,2)
                end
                if recordsize > 8 then -- 4 + 2 + 2
                    skipbytes(recordsize-8)
                end
            end
        end
     -- setvariabledata(fontdata,"mregions",regions)
    end
end
