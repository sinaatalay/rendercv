if not modules then modules = { } end modules ['font-cid'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local format, match, lower = string.format, string.match, string.lower
local tonumber = tonumber
local P, S, R, C, V, lpegmatch = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.V, lpeg.match

local fonts, logs, trackers = fonts, logs, trackers

local trace_loading = false  trackers.register("otf.loading", function(v) trace_loading = v end)

local report_otf    = logs.reporter("fonts","otf loading")

local cid           = { }
fonts.cid           = cid

local cidmap        = { }
local cidmax        = 10

-- original string parser: 0.109, lpeg parser: 0.036 seconds for Adobe-CNS1-4.cidmap
--
-- 18964 18964 (leader)
-- 0 /.notdef
-- 1..95 0020
-- 99 3000

local number  = C(R("09","af","AF")^1)
local space   = S(" \n\r\t")
local spaces  = space^0
local period  = P(".")
local periods = period * period
local name    = P("/") * C((1-space)^1)

local unicodes, names = { }, { } -- we could use Carg now

local function do_one(a,b)
    unicodes[tonumber(a)] = tonumber(b,16)
end

local function do_range(a,b,c)
    c = tonumber(c,16)
    for i=tonumber(a),tonumber(b) do
        unicodes[i] = c
        c = c + 1
    end
end

local function do_name(a,b)
    names[tonumber(a)] = b
end

local grammar = P { "start",
    start  = number * spaces * number * V("series"),
    series = (spaces * (V("one") + V("range") + V("named")))^1,
    one    = (number * spaces  * number) / do_one,
    range  = (number * periods * number * spaces * number) / do_range,
    named  = (number * spaces  * name) / do_name
}

local function loadcidfile(filename)
    local data = io.loaddata(filename)
    if data then
        unicodes, names = { }, { }
        lpegmatch(grammar,data)
        local supplement, registry, ordering = match(filename,"^(.-)%-(.-)%-()%.(.-)$")
        return {
            supplement = supplement,
            registry   = registry,
            ordering   = ordering,
            filename   = filename,
            unicodes   = unicodes,
            names      = names,
        }
    end
end

cid.loadfile   = loadcidfile -- we use the frozen variant
local template = "%s-%s-%s.cidmap"

local function locate(registry,ordering,supplement)
    local filename = format(template,registry,ordering,supplement)
    local hashname = lower(filename)
    local found    = cidmap[hashname]
    if not found then
        if trace_loading then
            report_otf("checking cidmap, registry %a, ordering %a, supplement %a, filename %a",registry,ordering,supplement,filename)
        end
        local fullname = resolvers.findfile(filename,'cid') or ""
        if fullname ~= "" then
            found = loadcidfile(fullname)
            if found then
                if trace_loading then
                    report_otf("using cidmap file %a",filename)
                end
                cidmap[hashname] = found
                found.usedname = file.basename(filename)
            end
        end
    end
    return found
end

-- cf Arthur R. we can safely scan upwards since cids are downward compatible

function cid.getmap(specification)
    if not specification then
        report_otf("invalid cidinfo specification, table expected")
        return
    end
    local registry   = specification.registry
    local ordering   = specification.ordering
    local supplement = specification.supplement
    local filename   = format(registry,ordering,supplement)
    local lowername  = lower(filename)
    local found      = cidmap[lowername]
    if found then
        return found
    end
    if ordering == "Identity" then
        local found = {
            supplement = supplement,
            registry   = registry,
            ordering   = ordering,
            filename   = filename,
            unicodes   = { },
            names      = { },
        }
        cidmap[lowername] = found
        return found
    end
    -- check for already loaded file
    if trace_loading then
        report_otf("cidmap needed, registry %a, ordering %a, supplement %a",registry,ordering,supplement)
    end
    found = locate(registry,ordering,supplement)
    if not found then
        local supnum = tonumber(supplement)
        local cidnum = nil
        -- next highest (alternatively we could start high)
        if supnum < cidmax then
            for s=supnum+1,cidmax do
                local c = locate(registry,ordering,s)
                if c then
                    found, cidnum = c, s
                    break
                end
            end
        end
        -- next lowest (least worse fit)
        if not found and supnum > 0 then
            for s=supnum-1,0,-1 do
                local c = locate(registry,ordering,s)
                if c then
                    found, cidnum = c, s
                    break
                end
            end
        end
        -- prevent further lookups -- somewhat tricky
        registry = lower(registry)
        ordering = lower(ordering)
        if found and cidnum > 0 then
            for s=0,cidnum-1 do
                local filename = format(template,registry,ordering,s)
                if not cidmap[filename] then
                    cidmap[filename] = found
                end
            end
        end
    end
    return found
end
