if not modules then modules = { } end modules ['font-map'] = {
    version   = 1.001,
    optimize  = true,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local tonumber, next, type = tonumber, next, type

local match, format, find, concat, gsub, lower = string.match, string.format, string.find, table.concat, string.gsub, string.lower
local P, R, S, C, Ct, Cc, lpegmatch = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.Ct, lpeg.Cc, lpeg.match
local formatters = string.formatters
local sortedhash, sortedkeys = table.sortedhash, table.sortedkeys
local idiv = number.idiv

local trace_loading = false  trackers.register("fonts.loading", function(v) trace_loading = v end)
local trace_mapping = false  trackers.register("fonts.mapping", function(v) trace_mapping = v end)

local report_fonts  = logs.reporter("fonts","loading") -- not otf only

-- force_ligatures was true for a while so that these emoji's with bad names work too

local force_ligatures = false  directives.register("fonts.mapping.forceligatures",function(v) force_ligatures = v end)

local fonts    = fonts or { }
local mappings = fonts.mappings or { }
fonts.mappings = mappings

local allocate = utilities.storage.allocate

local hex      = R("AF","af","09")
local hexfour  = (hex*hex*hex^-2) / function(s) return tonumber(s,16) end
local hexsix   = (hex*hex*hex^-4) / function(s) return tonumber(s,16) end
local dec      = (R("09")^1) / tonumber
local period   = P(".")
local unicode  = (P("uni") + P("UNI")) * (hexfour * (period + P(-1)) * Cc(false) + Ct(hexfour^1) * Cc(true)) -- base planes
local ucode    = (P("u")   + P("U")  ) * (hexsix  * (period + P(-1)) * Cc(false) + Ct(hexsix ^1) * Cc(true)) -- extended
local index    = P("index") * dec * Cc(false)

local parser   = unicode + ucode + index
local parsers  = { }

local function makenameparser(str)
    if not str or str == "" then
        return parser
    else
        local p = parsers[str]
        if not p then
            p = P(str) * period * dec * Cc(false)
            parsers[str] = p
        end
        return p
    end
end

local f_single  = formatters["%04X"]
local f_double  = formatters["%04X%04X"]
local s_unknown = "FFFD"

local function tounicode16(unicode)
    if unicode < 0xD7FF or (unicode > 0xDFFF and unicode <= 0xFFFF) then
        return f_single(unicode)
    elseif unicode >= 0x00E000 and unicode <= 0x00F8FF then
        return s_unknown
    elseif unicode >= 0x0F0000 and unicode <= 0x0FFFFF then
        return s_unknown
    elseif unicode >= 0x100000 and unicode <= 0x10FFFF then
        return s_unknown
    elseif unicode >= 0x00D800 and unicode <= 0x00DFFF then
        return s_unknown
    else
        unicode = unicode - 0x10000
        return f_double(idiv(k,0x400)+0xD800,unicode%0x400+0xDC00)
    end
end

local function tounicode16sequence(unicodes)
    local t = { }
    for l=1,#unicodes do
        local u = unicodes[l]
        if u < 0xD7FF or (u > 0xDFFF and u <= 0xFFFF) then
            t[l] = f_single(u)
        elseif unicode >= 0x00E000 and unicode <= 0x00F8FF then
            t[l] = s_unknown
        elseif unicode >= 0x0F0000 and unicode <= 0x0FFFFF then
            t[l] = s_unknown
        elseif unicode >= 0x100000 and unicode <= 0x10FFFF then
            t[l] = s_unknown
     -- elseif unicode >= 0x00D800 and unicode <= 0x00DFFF then
        elseif unicode >= 0x00D7FF and unicode <= 0x00DFFF then
            t[l] = s_unknown
        else
            u = u - 0x10000
            t[l] = f_double(idiv(k,0x400)+0xD800,u%0x400+0xDC00)
        end
    end
    return concat(t)
end


local hash = { }
local conc = { }

table.setmetatableindex(hash,function(t,k)
    local v
    if k < 0xD7FF or (k > 0xDFFF and k <= 0xFFFF) then
        v = f_single(k)
    else
        local k = k - 0x10000
        v = f_double(idiv(k,0x400)+0xD800,k%0x400+0xDC00)
    end
    t[k] = v
    return v
end)

local function tounicode(k)
    if type(k) == "table" then
        local n = #k
        for l=1,n do
            conc[l] = hash[k[l]]
        end
        return concat(conc,"",1,n)
    elseif k >= 0x00E000 and k <= 0x00F8FF then
        return s_unknown
    elseif k >= 0x0F0000 and k <= 0x0FFFFF then
        return s_unknown
    elseif k >= 0x100000 and k <= 0x10FFFF then
        return s_unknown
 -- elseif k >= 0x00D800 and k <= 0x00DFFF then
    elseif k >= 0x00D7FF and k <= 0x00DFFF then
        return s_unknown
    else
        return hash[k]
    end
end

local function fromunicode16(str)
    if #str == 4 then
        return tonumber(str,16)
    else
        local l, r = match(str,"(....)(....)")
        return 0x10000 + (tonumber(l,16)-0xD800)*0x400  + tonumber(r,16) - 0xDC00
    end
end

-- Slightly slower:
--
-- local p = C(4) * (C(4)^-1) / function(l,r)
--     if r then
--         return (tonumber(l,16))*0x400  + tonumber(r,16) - 0xDC00
--     else
--         return tonumber(l,16)
--     end
-- end
--
-- local function fromunicode16(str)
--     return lpegmatch(p,str)
-- end

mappings.makenameparser      = makenameparser
mappings.tounicode           = tounicode
mappings.tounicode16         = tounicode16
mappings.tounicode16sequence = tounicode16sequence
mappings.fromunicode16       = fromunicode16

-- mozilla emoji has bad lig names: name = gsub(name,"(u[a-f0-9_]+)%-([a-f0-9_]+)","%1_%2")

local ligseparator = P("_")
local varseparator = P(".")
local namesplitter = Ct(C((1 - ligseparator - varseparator)^1) * (ligseparator * C((1 - ligseparator - varseparator)^1))^0)

-- maybe: ff fi fl ffi ffl => f_f f_i f_l f_f_i f_f_l

-- local function test(name)
--     local split = lpegmatch(namesplitter,name)
--     print(string.formatters["%s: [% t]"](name,split))
-- end

-- test("i.f_")
-- test("this")
-- test("this.that")
-- test("japan1.123")
-- test("such_so_more")
-- test("such_so_more.that")

-- to be completed .. for fonts that use unicodes for ligatures which
-- is a actually a bad thing and should be avoided in the first place

do

    local overloads = {
        IJ  = { name = "I_J",   unicode = { 0x49, 0x4A },       mess = 0x0132 },
        ij  = { name = "i_j",   unicode = { 0x69, 0x6A },       mess = 0x0133 },
        ff  = { name = "f_f",   unicode = { 0x66, 0x66 },       mess = 0xFB00 },
        fi  = { name = "f_i",   unicode = { 0x66, 0x69 },       mess = 0xFB01 },
        fl  = { name = "f_l",   unicode = { 0x66, 0x6C },       mess = 0xFB02 },
        ffi = { name = "f_f_i", unicode = { 0x66, 0x66, 0x69 }, mess = 0xFB03 },
        ffl = { name = "f_f_l", unicode = { 0x66, 0x66, 0x6C }, mess = 0xFB04 },
        fj  = { name = "f_j",   unicode = { 0x66, 0x6A } },
        fk  = { name = "f_k",   unicode = { 0x66, 0x6B } },

     -- endash = { name = "endash", unicode = 0x2013, mess = 0x2013 },
     -- emdash = { name = "emdash", unicode = 0x2014, mess = 0x2014 },
    }

    local o = allocate { }

    for k, v in next, overloads do
        local name = v.name
        local mess = v.mess
        if name then
            o[name] = v
        end
        if mess then
            o[mess] = v
        end
        o[k] = v
    end

    mappings.overloads = o

end

function mappings.addtounicode(data,filename,checklookups,forceligatures)
    local resources = data.resources
    local unicodes  = resources.unicodes
    if not unicodes then
        if trace_mapping then
            report_fonts("no unicode list, quitting tounicode for %a",filename)
        end
        return
    end
    local properties    = data.properties
    local descriptions  = data.descriptions
    local overloads     = mappings.overloads
    -- we need to move this code
    unicodes['space']   = unicodes['space']  or 32
    unicodes['hyphen']  = unicodes['hyphen'] or 45
    unicodes['zwj']     = unicodes['zwj']    or 0x200D
    unicodes['zwnj']    = unicodes['zwnj']   or 0x200C
    --
    local private       = fonts.constructors and fonts.constructors.privateoffset or 0xF0000 -- 0x10FFFF
    local unicodevector = fonts.encodings.agl.unicodes or { } -- loaded runtime in context
    local contextvector = fonts.encodings.agl.ctxcodes or { } -- loaded runtime in context
    local missing       = { }
    local nofmissing    = 0
    local oparser       = nil
    local cidnames      = nil
    local cidcodes      = nil
    local cidinfo       = properties.cidinfo
    local usedmap       = cidinfo and fonts.cid.getmap(cidinfo)
    local uparser       = makenameparser() -- hm, every time?
    if usedmap then
        oparser  = usedmap and makenameparser(cidinfo.ordering)
        cidnames = usedmap.names
        cidcodes = usedmap.unicodes
    end
    local ns = 0
    local nl = 0
    --
    -- in order to avoid differences between runs due to hash randomization we
    -- run over a sorted list
    --
    local dlist = sortedkeys(descriptions)
    --
 -- for du, glyph in next, descriptions do
    for i=1,#dlist do
        local du    = dlist[i]
        local glyph = descriptions[du]
        local name  = glyph.name
        if name then
            local overload = overloads[name] or overloads[du]
            if overload then
                -- get rid of weird ligatures
             -- glyph.name    = overload.name
                glyph.unicode = overload.unicode
            else
                local gu = glyph.unicode -- can already be set (number or table)
                if not gu or gu == -1 or du >= private or (du >= 0xE000 and du <= 0xF8FF) or du == 0xFFFE or du == 0xFFFF then
                    local unicode = unicodevector[name] or contextvector[name]
                    if unicode then
                        glyph.unicode = unicode
                        ns            = ns + 1
                    end
                    -- cidmap heuristics, beware, there is no guarantee for a match unless
                    -- the chain resolves
                    if (not unicode) and usedmap then
                        local foundindex = lpegmatch(oparser,name)
                        if foundindex then
                            unicode = cidcodes[foundindex] -- name to number
                            if unicode then
                                glyph.unicode = unicode
                                ns            = ns + 1
                            else
                                local reference = cidnames[foundindex] -- number to name
                                if reference then
                                    local foundindex = lpegmatch(oparser,reference)
                                    if foundindex then
                                        unicode = cidcodes[foundindex]
                                        if unicode then
                                            glyph.unicode = unicode
                                            ns            = ns + 1
                                        end
                                    end
                                    if not unicode or unicode == "" then
                                        local foundcodes, multiple = lpegmatch(uparser,reference)
                                        if foundcodes then
                                            glyph.unicode = foundcodes
                                            if multiple then
                                                nl      = nl + 1
                                                unicode = true
                                            else
                                                ns      = ns + 1
                                                unicode = foundcodes
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                    -- a.whatever or a_b_c.whatever or a_b_c (no numbers) a.b_
                    --
                    -- It is not trivial to find a solution that suits all fonts. We tried several alternatives
                    -- and this one seems to work reasonable also with fonts that use less standardized naming
                    -- schemes. The extra private test is tested by KE and seems to work okay with non-typical
                    -- fonts as well.
                    --
                    if not unicode or unicode == "" then
                        local split  = lpegmatch(namesplitter,name)
                        local nsplit = split and #split or 0 -- add if
                        if nsplit == 0 then
                            -- skip
                        elseif nsplit == 1 then
                            local base = split[1]
                            local u = unicodes[base] or unicodevector[base] or contextvector[name]
                            if not u then
                                -- skip
                            elseif type(u) == "table" then
                                -- unlikely
                                if u[1] < private then
                                    unicode = u
                                    glyph.unicode = unicode
                                end
                            elseif u < private then
                                unicode = u
                                glyph.unicode = unicode
                            end
                        else
                            local t = { }
                            local n = 0
                            for l=1,nsplit do
                                local base = split[l]
                                local u = unicodes[base] or unicodevector[base] or contextvector[name]
                                if not u then
                                    break
                                elseif type(u) == "table" then
                                    if u[1] >= private then
                                        break
                                    end
                                    n = n + 1
                                    t[n] = u[1]
                                else
                                    if u >= private then
                                        break
                                    end
                                    n = n + 1
                                    t[n] = u
                                end
                            end
                            if n > 0 then
                                if n == 1 then
                                    unicode = t[1]
                                else
                                    unicode = t
                                end
                                glyph.unicode = unicode
                            end
                        end
                        nl = nl + 1
                    end
                    -- last resort (we might need to catch private here as well)
                    if not unicode or unicode == "" then
                        local foundcodes, multiple = lpegmatch(uparser,name)
                        if foundcodes then
                            glyph.unicode = foundcodes
                            if multiple then
                                nl      = nl + 1
                                unicode = true
                            else
                                ns      = ns + 1
                                unicode = foundcodes
                            end
                        end
                    end
                    -- check using substitutes and alternates
                    local r = overloads[unicode]
                    if r then
                        unicode = r.unicode
                        glyph.unicode = unicode
                    end
                    --
                    if not unicode then
                        missing[du] = true
                        nofmissing  = nofmissing + 1
                    end
                else
                     -- maybe a message or so
                end
            end
        else
            local overload = overloads[du]
            if overload then
                glyph.unicode = overload.unicode
            elseif not glyph.unicode then
                missing[du] = true
                nofmissing  = nofmissing + 1
            end
        end
    end
    if type(checklookups) == "function" then
        checklookups(data,missing,nofmissing)
    end

    local unicoded  = 0
    local collected = fonts.handlers.otf.readers.getcomponents(data) -- neglectable overhead

    local function resolve(glyph,u)
        local n = #u
        for i=1,n do
            if u[i] > private then
                n = 0
                break
            end
        end
        if n > 0 then
            if n > 1 then
                glyph.unicode = u
            else
                glyph.unicode = u[1]
            end
            unicoded = unicoded + 1
        end
    end

    if not collected then
        -- move on
    elseif forceligatures or force_ligatures then
        for i=1,#dlist do
            local du = dlist[i]
            if du >= private or (du >= 0xE000 and du <= 0xF8FF) then
                local u  = collected[du] -- always tables
                if u then
                    resolve(descriptions[du],u)
                end
            end
        end
    else
        for i=1,#dlist do
            local du = dlist[i]
            if du >= private or (du >= 0xE000 and du <= 0xF8FF) then
                local glyph = descriptions[du]
                if glyph.class == "ligature" and not glyph.unicode then
                    local u = collected[du] -- always tables
                    if u then
                         resolve(glyph,u)
                    end
                end
            end
        end
    end

    if trace_mapping and unicoded > 0 then
        report_fonts("%n ligature tounicode mappings deduced from gsub ligature features",unicoded)
    end
    if trace_mapping then
     -- for unic, glyph in sortedhash(descriptions) do
        for i=1,#dlist do
            local du      = dlist[i]
            local glyph   = descriptions[du]
            local name    = glyph.name or "-"
            local index   = glyph.index or 0
            local unicode = glyph.unicode
            if unicode then
                if type(unicode) == "table" then
                    local unicodes = { }
                    for i=1,#unicode do
                        unicodes[i] = formatters("%U",unicode[i])
                    end
                    report_fonts("internal slot %U, name %a, unicode %U, tounicode % t",index,name,du,unicodes)
                else
                    report_fonts("internal slot %U, name %a, unicode %U, tounicode %U",index,name,du,unicode)
                end
            else
                report_fonts("internal slot %U, name %a, unicode %U",index,name,du)
            end
        end
    end
    if trace_loading and (ns > 0 or nl > 0) then
        report_fonts("%s tounicode entries added, ligatures %s",nl+ns,ns)
    end
end

-- local parser = makenameparser("Japan1")
-- local parser = makenameparser()
-- local function test(str)
--     local b, a = lpegmatch(parser,str)
--     print((a and table.serialize(b)) or b)
-- end
-- test("a.sc")
-- test("a")
-- test("uni1234")
-- test("uni1234.xx")
-- test("uni12349876")
-- test("u123400987600")
-- test("index1234")
-- test("Japan1.123")
