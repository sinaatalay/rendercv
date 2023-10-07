if not modules then modules = { } end modules ['font-onr'] = {
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

local fonts, logs, trackers, resolvers = fonts, logs, trackers, resolvers

local next, type, tonumber, rawset = next, type, tonumber, rawset
local match, lower, gsub, strip, find = string.match, string.lower, string.gsub, string.strip, string.find
local char, byte, sub = string.char, string.byte, string.sub
local abs = math.abs
local bxor, rshift = bit32.bxor, bit32.rshift
local P, S, R, V, Cmt, C, Ct, Cs, Carg, Cf, Cg, Cc = lpeg.P, lpeg.S, lpeg.R, lpeg.V, lpeg.Cmt, lpeg.C, lpeg.Ct, lpeg.Cs, lpeg.Carg, lpeg.Cf, lpeg.Cg, lpeg.Cc
local lpegmatch, patterns = lpeg.match, lpeg.patterns

local trace_indexing     = false  trackers.register("afm.indexing",   function(v) trace_indexing = v end)
local trace_loading      = false  trackers.register("afm.loading",    function(v) trace_loading  = v end)

local report_afm         = logs.reporter("fonts","afm loading")
local report_pfb         = logs.reporter("fonts","pfb loading")

local handlers           = fonts.handlers
local afm                = handlers.afm or { }
handlers.afm             = afm
local readers            = afm.readers or { }
afm.readers              = readers

afm.version              = 1.513 -- incrementing this number one up will force a re-cache

-- We start with the basic reader which we give a name similar to the built in TFM
-- and OTF reader. We use a PFB loader but I see no differences between the old and
-- new vectors (we actually had one bad vector with the old loader).

local get_indexes, get_shapes

do

    local decrypt

    do

        local r, c1, c2, n = 0, 0, 0, 0

        local function step(c)
            local cipher = byte(c)
            local plain  = bxor(cipher,rshift(r,8))
            r = ((cipher + r) * c1 + c2) % 65536
            return char(plain)
        end

        decrypt = function(binary,initial,seed)
            r, c1, c2, n = initial, 52845, 22719, seed
            binary       = gsub(binary,".",step)
            return sub(binary,n+1)
        end

     -- local pattern = Cs((P(1) / step)^1)
     --
     -- decrypt = function(binary,initial,seed)
     --     r, c1, c2, n = initial, 52845, 22719, seed
     --     binary = lpegmatch(pattern,binary)
     --     return sub(binary,n+1)
     -- end

    end

    local charstrings = P("/CharStrings")
    local subroutines = P("/Subrs")
    local encoding    = P("/Encoding")
    local dup         = P("dup")
    local put         = P("put")
    local array       = P("array")
    local name        = P("/") * C((R("az","AZ","09")+S("-_."))^1)
    local digits      = R("09")^1
    local cardinal    = digits / tonumber
    local spaces      = P(" ")^1
    local spacing     = patterns.whitespace^0

    local routines, vector, chars, n, m

    local initialize = function(str,position,size)
        n = 0
        m = size
        return position + 1
    end

    local setroutine = function(str,position,index,size,filename)
        if routines[index] then
            -- we have passed the end
            return false
        end
        local forward = position + size
        local stream  = decrypt(sub(str,position+1,forward),4330,4)
        routines[index] = { byte(stream,1,#stream) }
        n = n + 1
        if n >= m then
            -- m should be index now but can we assume ordering?
            return #str
        end
        return forward + 1
    end

    local setvector = function(str,position,name,size,filename)
        local forward = position + tonumber(size)
        if n >= m then
            return #str
        elseif forward < #str then
            if n == 0 and name ~= ".notdef" then
                report_pfb("reserving .notdef at index 0 in %a",filename) -- luatex needs that
                n = n + 1
            end
            vector[n] = name
            n = n + 1
            return forward
        else
            return #str
        end
    end

    local setshapes = function(str,position,name,size,filename)
        local forward = position + tonumber(size)
        local stream  = sub(str,position+1,forward)
        if n > m then
            return #str
        elseif forward < #str then
            if n == 0 and name ~= ".notdef" then
                report_pfb("reserving .notdef at index 0 in %a",filename) -- luatex needs that
                n = n + 1
            end
            vector[n] = name
            n = n + 1
            chars [n] = decrypt(stream,4330,4)
            return forward
        else
            return #str
        end
    end

    local p_rd = spacing * (P("RD") + P("-|"))
    local p_np = spacing * (P("NP") + P( "|"))
    local p_nd = spacing * (P("ND") + P( "|"))

    local p_filterroutines = -- dup <i> <n> RD or -| <n encrypted bytes> NP or |
        (1-subroutines)^0 * subroutines * spaces * Cmt(cardinal,initialize)
      * (Cmt(cardinal * spaces * cardinal * p_rd * Carg(1), setroutine) * p_np + (1-p_nd))^1

    local p_filtershapes = -- /foo <n> RD <n encrypted bytes> ND
        (1-charstrings)^0 * charstrings * spaces * Cmt(cardinal,initialize)
      * (Cmt(name * spaces * cardinal * p_rd * Carg(1) , setshapes) * p_nd + P(1))^1

    local p_filternames = Ct (
        (1-charstrings)^0 * charstrings * spaces * Cmt(cardinal,initialize)
        * (Cmt(name * spaces * cardinal * Carg(1), setvector) + P(1))^1
    )

    -- /Encoding 256 array
    -- 0 1 255 {1 index exch /.notdef put} for
    -- dup 0 /Foo put

    local p_filterencoding =
        (1-encoding)^0 * encoding * spaces * digits * spaces * array * (1-dup)^0
      * Cf(
            Ct("") * Cg(spacing * dup * spaces * cardinal * spaces * name * spaces * put)^1
        ,rawset)

    -- if one of first 4 not 0-9A-F then binary else hex

    local key = spacing * P("/") * R("az","AZ")
    local str = spacing * Cs { (P("(")/"") * ((1 - P("\\(") - P("\\)") - S("()")) + V(1))^0 * (P(")")/"") }
    local num = spacing * (R("09") + S("+-."))^1 / tonumber
    local arr = spacing * Ct (S("[{") * (num)^0 * spacing * S("]}"))
    local boo = spacing * (P("true") * Cc(true) + P("false") * Cc(false))
    local nam = spacing * P("/") * Cs(R("az","AZ")^1)

    local p_filtermetadata = (
        P("/") * Carg(1) * ( (
            C("version")            * str
          + C("Copyright")          * str
          + C("Notice")             * str
          + C("FullName")           * str
          + C("FamilyName")         * str
          + C("Weight")             * str
          + C("ItalicAngle")        * num
          + C("isFixedPitch")       * boo
          + C("UnderlinePosition")  * num
          + C("UnderlineThickness") * num
          + C("FontName")           * nam
          + C("FontMatrix")         * arr
          + C("FontBBox")           * arr
        ) ) / function(t,k,v) t[lower(k)] = v end
      + P(1)
    )^0 * Carg(1)

    -- cache this?

    local function loadpfbvector(filename,shapestoo,streams)
        -- for the moment limited to encoding only

        local data = io.loaddata(resolvers.findfile(filename))

        if not data then
            report_pfb("no data in %a",filename)
            return
        end

        if not (find(data,"!PS-AdobeFont-",1,true) or find(data,"%!FontType1",1,true)) then
            report_pfb("no font in %a",filename)
            return
        end

        local ascii, binary = match(data,"(.*)eexec%s+......(.*)")

        if not binary then
            report_pfb("no binary data in %a",filename)
            return
        end

        binary = decrypt(binary,55665,4)

        local names    = { }
        local encoding = lpegmatch(p_filterencoding,ascii)
        local metadata = lpegmatch(p_filtermetadata,ascii,1,{})
        local glyphs   = { }

        routines, vector, chars = { }, { }, { }
        if shapestoo or streams then
         -- io.savedata("foo.txt",binary)
            lpegmatch(p_filterroutines,binary,1,filename)
            lpegmatch(p_filtershapes,binary,1,filename)
            local data = {
                dictionaries = {
                    {
                        charstrings = chars,
                        charset     = vector,
                        subroutines = routines,
                    }
                },
            }
            -- only cff 1 in type 1 fonts
            fonts.handlers.otf.readers.parsecharstrings(false,data,glyphs,true,"cff",streams,true)
        else
            lpegmatch(p_filternames,binary,1,filename)
        end

        names = vector

        routines, vector, chars = nil, nil, nil

        return names, encoding, glyphs, metadata

    end

    local pfb      = handlers.pfb or { }
    handlers.pfb   = pfb
    pfb.loadvector = loadpfbvector

    get_indexes = function(data,pfbname)
        local vector = loadpfbvector(pfbname)
        if vector then
            local characters = data.characters
            if trace_loading then
                report_afm("getting index data from %a",pfbname)
            end
            for index=0,#vector do -- hm, zero, often space or notdef
                local name = vector[index]
                local char = characters[name]
                if char then
                    if trace_indexing then
                        report_afm("glyph %a has index %a",name,index)
                    end
                    char.index = index
                else
                    if trace_indexing then
                        report_afm("glyph %a has index %a but no data",name,index)
                    end
                end
            end
        end
    end

    get_shapes = function(pfbname)
        local vector, encoding, glyphs = loadpfbvector(pfbname,true)
        return glyphs
    end

end

-- We start with the basic reader which we give a name similar to the built in TFM
-- and OTF reader. We only need data that is relevant for our use. We don't support
-- more complex arrangements like multiple master (obsolete), direction specific
-- kerning, etc.

local spacer     = patterns.spacer
local whitespace = patterns.whitespace
local lineend    = patterns.newline
local spacing    = spacer^0
local number     = spacing * S("+-")^-1 * (R("09") + S("."))^1 / tonumber
local name       = spacing * C((1 - whitespace)^1)
local words      = spacing * ((1 - lineend)^1 / strip)
local rest       = (1 - lineend)^0
local fontdata   = Carg(1)
local semicolon  = spacing * P(";")
local plus       = spacing * P("plus") * number
local minus      = spacing * P("minus") * number

-- kern pairs

local function addkernpair(data,one,two,value)
    local chr = data.characters[one]
    if chr then
        local kerns = chr.kerns
        if kerns then
            kerns[two] = tonumber(value)
        else
            chr.kerns = { [two] = tonumber(value) }
        end
    end
end

local p_kernpair = (fontdata * P("KPX") * name * name * number) / addkernpair

-- char metrics

local chr = false
local ind = 0

local function start(data,version)
    data.metadata.afmversion = version
    ind = 0
    chr = { }
end

local function stop()
    ind = 0
    chr = false
end

local function setindex(i)
    if i < 0 then
        ind = ind + 1 -- ?
    else
        ind = i
    end
    chr = {
        index = ind
    }
end

local function setwidth(width)
    chr.width = width
end

local function setname(data,name)
    data.characters[name] = chr
end

local function setboundingbox(boundingbox)
    chr.boundingbox = boundingbox
end

local function setligature(plus,becomes)
    local ligatures = chr.ligatures
    if ligatures then
        ligatures[plus] = becomes
    else
        chr.ligatures = { [plus] = becomes }
    end
end

local p_charmetric = ( (
    P("C")  * number          / setindex
  + P("WX") * number          / setwidth
  + P("N")  * fontdata * name / setname
  + P("B")  * Ct((number)^4)  / setboundingbox
  + P("L")  * (name)^2        / setligature
  ) * semicolon )^1

local p_charmetrics = P("StartCharMetrics") * number * (p_charmetric + (1-P("EndCharMetrics")))^0 * P("EndCharMetrics")
local p_kernpairs   = P("StartKernPairs")   * number * (p_kernpair   + (1-P("EndKernPairs"  )))^0 * P("EndKernPairs"  )

local function set_1(data,key,a)     data.metadata[lower(key)] = a           end
local function set_2(data,key,a,b)   data.metadata[lower(key)] = { a, b }    end
local function set_3(data,key,a,b,c) data.metadata[lower(key)] = { a, b, c } end

-- Notice         string
-- EncodingScheme string
-- MappingScheme  integer
-- EscChar        integer
-- CharacterSet   string
-- Characters     integer
-- IsBaseFont     boolean
-- VVector        number number
-- IsFixedV       boolean

local p_parameters = P(false)
  + fontdata
  * ((P("FontName") + P("FullName") + P("FamilyName"))/lower)
  * words / function(data,key,value)
        data.metadata[key] = value
    end
  + fontdata
  * ((P("Weight") + P("Version"))/lower)
  * name / function(data,key,value)
        data.metadata[key] = value
    end
  + fontdata
  * P("IsFixedPitch")
  * name / function(data,pitch)
        data.metadata.monospaced = toboolean(pitch,true)
    end
  + fontdata
  * P("FontBBox")
  * Ct(number^4) / function(data,boundingbox)
        data.metadata.boundingbox = boundingbox
  end
  + fontdata
  * ((P("CharWidth") + P("CapHeight") + P("XHeight") + P("Descender") + P("Ascender") + P("ItalicAngle"))/lower)
  * number / function(data,key,value)
        data.metadata[key] = value
    end
  + P("Comment") * spacing * ( P(false)
      + (fontdata * C("DESIGNSIZE")     * number                   * rest) / set_1 -- 1
      + (fontdata * C("TFM designsize") * number                   * rest) / set_1
      + (fontdata * C("DesignSize")     * number                   * rest) / set_1
      + (fontdata * C("CODINGSCHEME")   * words                    * rest) / set_1 --
      + (fontdata * C("CHECKSUM")       * number * words           * rest) / set_1 -- 2
      + (fontdata * C("SPACE")          * number * plus * minus    * rest) / set_3 -- 3 4 5
      + (fontdata * C("QUAD")           * number                   * rest) / set_1 -- 6
      + (fontdata * C("EXTRASPACE")     * number                   * rest) / set_1 -- 7
      + (fontdata * C("NUM")            * number * number * number * rest) / set_3 -- 8 9 10
      + (fontdata * C("DENOM")          * number * number          * rest) / set_2 -- 11 12
      + (fontdata * C("SUP")            * number * number * number * rest) / set_3 -- 13 14 15
      + (fontdata * C("SUB")            * number * number          * rest) / set_2 -- 16 17
      + (fontdata * C("SUPDROP")        * number                   * rest) / set_1 -- 18
      + (fontdata * C("SUBDROP")        * number                   * rest) / set_1 -- 19
      + (fontdata * C("DELIM")          * number * number          * rest) / set_2 -- 20 21
      + (fontdata * C("AXISHEIGHT")     * number                   * rest) / set_1 -- 22
    )

local fullparser = ( P("StartFontMetrics") * fontdata * name / start )
                 * ( p_charmetrics + p_kernpairs + p_parameters + (1-P("EndFontMetrics")) )^0
                 * ( P("EndFontMetrics") / stop )

local infoparser = ( P("StartFontMetrics") * fontdata * name / start )
                 * ( p_parameters + (1-P("EndFontMetrics")) )^0
                 * ( P("EndFontMetrics") / stop )

--    infoparser = ( P("StartFontMetrics") * fontdata * name / start )
--               * ( p_parameters + (1-P("EndFontMetrics") - P("StartCharMetrics")) )^0
--               * ( (P("EndFontMetrics") + P("StartCharMetrics")) / stop )

local function read(filename,parser)
    local afmblob = io.loaddata(filename)
    if afmblob then
        local data = {
            resources = {
                filename = resolvers.unresolve(filename),
                version  = afm.version,
                creator  = "context mkiv",
            },
            properties = {
                hasitalics = false,
            },
            goodies = {
            },
            metadata   = {
                filename = file.removesuffix(file.basename(filename))
            },
            characters = {
                -- a temporary store
            },
            descriptions = {
                -- the final store
            },
        }
        if trace_loading then
            report_afm("parsing afm file %a",filename)
        end
        lpegmatch(parser,afmblob,1,data)
        return data
    else
        if trace_loading then
            report_afm("no valid afm file %a",filename)
        end
        return nil
    end
end

function readers.loadfont(afmname,pfbname)
    local data = read(resolvers.findfile(afmname),fullparser)
    if data then
        if not pfbname or pfbname == "" then
            pfbname = resolvers.findfile(file.replacesuffix(file.nameonly(afmname),"pfb"))
        end
        if pfbname and pfbname ~= "" then
            data.resources.filename = resolvers.unresolve(pfbname)
            get_indexes(data,pfbname)
            return data
        else -- if trace_loading then
            report_afm("no pfb file for %a",afmname)
            -- better than loading the afm file: data.resources.filename = rawname
            -- but that will still crash the backend so we just return nothing now
        end
    end
end

-- for now, todo: n and check with otf (no afm needed here)

function readers.loadshapes(filename)
    local fullname = resolvers.findfile(filename) or ""
    if fullname == "" then
        return {
            filename = "not found: " .. filename,
            glyphs   = { }
        }
    else
        return {
            filename = fullname,
            format   = "opentype",
            glyphs   = get_shapes(fullname) or { },
            units    = 1000,
        }
    end
end


function readers.getinfo(filename)
    local data = read(resolvers.findfile(filename),infoparser)
    if data then
        return data.metadata
    end
end
