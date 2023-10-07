if not modules then modules = { } end modules ['font-cff'] = {
    version   = 1.001,
    optimize  = true,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- todo: option.outlines
-- todo: option.boundingbox
-- per charstring (less memory)

-- This is a heavy one as it is a rather packed format. We don't need al the information
-- now but we might need it later (who know what magic we can do with metapost). So at
-- some point this might become a module. We just follow Adobe Technical Notes #5176 and
-- #5177. In case of doubt I looked in the fontforge code that comes with LuaTeX but
-- it's not the easiest source to read (and doesn't cover cff2).

-- For now we save the segments in a list of segments with the operator last in an entry
-- because that reflects the original. But it might make more sense to use a single array
-- per segment. For pdf a simple concat works ok, but for other purposes a operator first
-- flush is nicer.
--
-- In retrospect I could have looked into the backend code of LuaTeX but it never
-- occurred to me that parsing charstrings was needed there (which has to to
-- with merging subroutines and flattening, not so much with calculations.) On
-- the other hand, we can now feed back cff2 stuff.

local next, type, tonumber, rawget = next, type, tonumber, rawget
local byte, char, gmatch, sub = string.byte, string.char, string.gmatch, string.sub
local concat, insert, remove, unpack = table.concat, table.insert, table.remove, table.unpack
local floor, abs, round, ceil, min, max = math.floor, math.abs, math.round, math.ceil, math.min, math.max
local P, C, R, S, C, Cs, Ct = lpeg.P, lpeg.C, lpeg.R, lpeg.S, lpeg.C, lpeg.Cs, lpeg.Ct
local lpegmatch = lpeg.match
local formatters = string.formatters
local bytetable = string.bytetable
local idiv = number.idiv
local rshift, band, extract = bit32.rshift, bit32.band, bit32.extract

local readers           = fonts.handlers.otf.readers
local streamreader      = readers.streamreader

local readstring        = streamreader.readstring
local readbyte          = streamreader.readcardinal1  --  8-bit unsigned integer
local readushort        = streamreader.readcardinal2  -- 16-bit unsigned integer
local readuint          = streamreader.readcardinal3  -- 24-bit unsigned integer
local readulong         = streamreader.readcardinal4  -- 32-bit unsigned integer
local setposition       = streamreader.setposition
local getposition       = streamreader.getposition
local readbytetable     = streamreader.readbytetable

directives.register("fonts.streamreader",function()

    streamreader  = utilities.streams

    readstring    = streamreader.readstring
    readbyte      = streamreader.readcardinal1
    readushort    = streamreader.readcardinal2
    readuint      = streamreader.readcardinal3
    readulong     = streamreader.readcardinal4
    setposition   = streamreader.setposition
    getposition   = streamreader.getposition
    readbytetable = streamreader.readbytetable

end)

local setmetatableindex = table.setmetatableindex

local trace_charstrings = false trackers.register("fonts.cff.charstrings",function(v) trace_charstrings = v end)
local report            = logs.reporter("otf reader","cff")

local parsedictionaries
local parsecharstring
local parsecharstrings
local resetcharstrings
local parseprivates
local startparsing
local stopparsing

local defaultstrings = { [0] = -- taken from ff
    ".notdef", "space", "exclam", "quotedbl", "numbersign", "dollar", "percent",
    "ampersand", "quoteright", "parenleft", "parenright", "asterisk", "plus",
    "comma", "hyphen", "period", "slash", "zero", "one", "two", "three", "four",
    "five", "six", "seven", "eight", "nine", "colon", "semicolon", "less",
    "equal", "greater", "question", "at", "A", "B", "C", "D", "E", "F", "G", "H",
    "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",
    "X", "Y", "Z", "bracketleft", "backslash", "bracketright", "asciicircum",
    "underscore", "quoteleft", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
    "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y",
    "z", "braceleft", "bar", "braceright", "asciitilde", "exclamdown", "cent",
    "sterling", "fraction", "yen", "florin", "section", "currency",
    "quotesingle", "quotedblleft", "guillemotleft", "guilsinglleft",
    "guilsinglright", "fi", "fl", "endash", "dagger", "daggerdbl",
    "periodcentered", "paragraph", "bullet", "quotesinglbase", "quotedblbase",
    "quotedblright", "guillemotright", "ellipsis", "perthousand", "questiondown",
    "grave", "acute", "circumflex", "tilde", "macron", "breve", "dotaccent",
    "dieresis", "ring", "cedilla", "hungarumlaut", "ogonek", "caron", "emdash",
    "AE", "ordfeminine", "Lslash", "Oslash", "OE", "ordmasculine", "ae",
    "dotlessi", "lslash", "oslash", "oe", "germandbls", "onesuperior",
    "logicalnot", "mu", "trademark", "Eth", "onehalf", "plusminus", "Thorn",
    "onequarter", "divide", "brokenbar", "degree", "thorn", "threequarters",
    "twosuperior", "registered", "minus", "eth", "multiply", "threesuperior",
    "copyright", "Aacute", "Acircumflex", "Adieresis", "Agrave", "Aring",
    "Atilde", "Ccedilla", "Eacute", "Ecircumflex", "Edieresis", "Egrave",
    "Iacute", "Icircumflex", "Idieresis", "Igrave", "Ntilde", "Oacute",
    "Ocircumflex", "Odieresis", "Ograve", "Otilde", "Scaron", "Uacute",
    "Ucircumflex", "Udieresis", "Ugrave", "Yacute", "Ydieresis", "Zcaron",
    "aacute", "acircumflex", "adieresis", "agrave", "aring", "atilde",
    "ccedilla", "eacute", "ecircumflex", "edieresis", "egrave", "iacute",
    "icircumflex", "idieresis", "igrave", "ntilde", "oacute", "ocircumflex",
    "odieresis", "ograve", "otilde", "scaron", "uacute", "ucircumflex",
    "udieresis", "ugrave", "yacute", "ydieresis", "zcaron", "exclamsmall",
    "Hungarumlautsmall", "dollaroldstyle", "dollarsuperior", "ampersandsmall",
    "Acutesmall", "parenleftsuperior", "parenrightsuperior", "twodotenleader",
    "onedotenleader", "zerooldstyle", "oneoldstyle", "twooldstyle",
    "threeoldstyle", "fouroldstyle", "fiveoldstyle", "sixoldstyle",
    "sevenoldstyle", "eightoldstyle", "nineoldstyle", "commasuperior",
    "threequartersemdash", "periodsuperior", "questionsmall", "asuperior",
    "bsuperior", "centsuperior", "dsuperior", "esuperior", "isuperior",
    "lsuperior", "msuperior", "nsuperior", "osuperior", "rsuperior", "ssuperior",
    "tsuperior", "ff", "ffi", "ffl", "parenleftinferior", "parenrightinferior",
    "Circumflexsmall", "hyphensuperior", "Gravesmall", "Asmall", "Bsmall",
    "Csmall", "Dsmall", "Esmall", "Fsmall", "Gsmall", "Hsmall", "Ismall",
    "Jsmall", "Ksmall", "Lsmall", "Msmall", "Nsmall", "Osmall", "Psmall",
    "Qsmall", "Rsmall", "Ssmall", "Tsmall", "Usmall", "Vsmall", "Wsmall",
    "Xsmall", "Ysmall", "Zsmall", "colonmonetary", "onefitted", "rupiah",
    "Tildesmall", "exclamdownsmall", "centoldstyle", "Lslashsmall",
    "Scaronsmall", "Zcaronsmall", "Dieresissmall", "Brevesmall", "Caronsmall",
    "Dotaccentsmall", "Macronsmall", "figuredash", "hypheninferior",
    "Ogoneksmall", "Ringsmall", "Cedillasmall", "questiondownsmall", "oneeighth",
    "threeeighths", "fiveeighths", "seveneighths", "onethird", "twothirds",
    "zerosuperior", "foursuperior", "fivesuperior", "sixsuperior",
    "sevensuperior", "eightsuperior", "ninesuperior", "zeroinferior",
    "oneinferior", "twoinferior", "threeinferior", "fourinferior",
    "fiveinferior", "sixinferior", "seveninferior", "eightinferior",
    "nineinferior", "centinferior", "dollarinferior", "periodinferior",
    "commainferior", "Agravesmall", "Aacutesmall", "Acircumflexsmall",
    "Atildesmall", "Adieresissmall", "Aringsmall", "AEsmall", "Ccedillasmall",
    "Egravesmall", "Eacutesmall", "Ecircumflexsmall", "Edieresissmall",
    "Igravesmall", "Iacutesmall", "Icircumflexsmall", "Idieresissmall",
    "Ethsmall", "Ntildesmall", "Ogravesmall", "Oacutesmall", "Ocircumflexsmall",
    "Otildesmall", "Odieresissmall", "OEsmall", "Oslashsmall", "Ugravesmall",
    "Uacutesmall", "Ucircumflexsmall", "Udieresissmall", "Yacutesmall",
    "Thornsmall", "Ydieresissmall", "001.000", "001.001", "001.002", "001.003",
    "Black", "Bold", "Book", "Light", "Medium", "Regular", "Roman", "Semibold",
}

local standardnames = { [0] = -- needed for seac
    false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false,
    "space", "exclam", "quotedbl", "numbersign", "dollar", "percent",
    "ampersand", "quoteright", "parenleft", "parenright", "asterisk", "plus",
    "comma", "hyphen", "period", "slash", "zero", "one", "two", "three", "four",
    "five", "six", "seven", "eight", "nine", "colon", "semicolon", "less",
    "equal", "greater", "question", "at", "A", "B", "C", "D", "E", "F", "G", "H",
    "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W",
    "X", "Y", "Z", "bracketleft", "backslash", "bracketright", "asciicircum",
    "underscore", "quoteleft", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j",
    "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y",
    "z", "braceleft", "bar", "braceright", "asciitilde", false, false, false,
    false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false,
    false, false, false, false, false, false, false, false, false, "exclamdown",
    "cent", "sterling", "fraction", "yen", "florin", "section", "currency",
    "quotesingle", "quotedblleft", "guillemotleft", "guilsinglleft",
    "guilsinglright", "fi", "fl", false, "endash", "dagger", "daggerdbl",
    "periodcentered", false, "paragraph", "bullet", "quotesinglbase",
    "quotedblbase", "quotedblright", "guillemotright", "ellipsis", "perthousand",
    false, "questiondown", false, "grave", "acute", "circumflex", "tilde",
    "macron", "breve", "dotaccent", "dieresis", false, "ring", "cedilla", false,
    "hungarumlaut", "ogonek", "caron", "emdash", false, false, false, false,
    false, false, false, false, false, false, false, false, false, false, false,
    false, "AE", false, "ordfeminine", false, false, false, false, "Lslash",
    "Oslash", "OE", "ordmasculine", false, false, false, false, false, "ae",
    false, false, false, "dotlessi", false, false, "lslash", "oslash", "oe",
    "germandbls", false, false, false, false
}

local cffreaders = {
    readbyte,
    readushort,
    readuint,
    readulong,
}

directives.register("fonts.streamreader",function()
    cffreaders = {
        readbyte,
        readushort,
        readuint,
        readulong,
    }
end)

-- The header contains information about its own size.

local function readheader(f)
    local offset = getposition(f)
    local major  = readbyte(f)
    local header = {
        offset = offset,
        major  = major,
        minor  = readbyte(f),
        size   = readbyte(f), -- headersize
    }
    if major == 1 then
        header.dsize = readbyte(f)   -- list of dict offsets
    elseif major == 2 then
        header.dsize = readushort(f) -- topdict size
    else
        -- I'm probably no longer around by then and we use AI's to
        -- handle this kind of stuff, if we typeset documents at all.
    end
    setposition(f,offset+header.size)
    return header
end

-- The indexes all look the same, so we share a loader. We could pass a handler
-- and run over the array but why bother, we only have a few uses.

local function readlengths(f,longcount)
    local count = longcount and readulong(f) or readushort(f)
    if count == 0 then
        return { }
    end
    local osize = readbyte(f)
    local read  = cffreaders[osize]
    if not read then
        report("bad offset size: %i",osize)
        return { }
    end
    local lengths  = { }
    local previous = read(f)
    for i=1,count do
        local offset = read(f)
        local length = offset - previous
        if length < 0 then
            report("bad offset: %i",length)
            length = 0
        end
        lengths[i] = length
        previous = offset
    end
    return lengths
end

-- There can be subfonts so names is an array. However, in our case it's always
-- one font. The same is true for the top dictionaries. Watch how we only load
-- the dictionary string as for interpretation we need to have the strings loaded
-- as well.

local function readfontnames(f)
    local names = readlengths(f)
    for i=1,#names do
        names[i] = readstring(f,names[i])
    end
    return names
end

local function readtopdictionaries(f)
    local dictionaries = readlengths(f)
    for i=1,#dictionaries do
        dictionaries[i] = readstring(f,dictionaries[i])
    end
    return dictionaries
end

-- Strings are added to a list of standard strings so we start the font specific
-- one with an offset. Strings are shared so we have one table.

local function readstrings(f)
    local lengths = readlengths(f)
    local strings = setmetatableindex({ }, defaultstrings)
    local index   = #defaultstrings
    for i=1,#lengths do
        index = index + 1
        strings[index] = readstring(f,lengths[i])
    end
    return strings
end

-- Parsing the dictionaries is delayed till we have the strings loaded. The parser
-- is stack based so the operands come before the operator (like in postscript).

-- local function delta(t)
--     local n = #t
--     if n > 1 then
--         local p = t[1]
--         for i=2,n do
--             local c = t[i]
--             t[i] = c + p
--             p = c
--         end
--     end
-- end

do

    -- We use a closure so that we don't need to pass too much around. For cff2 we can
    -- at some point use a simple version as there is less.

    local stack   = { }
    local top     = 0
    local result  = { }
    local strings = { }

    local p_single =
        P("\00") / function()
            result.version = strings[stack[top]] or "unset"
            top = 0
        end
      + P("\01") / function()
            result.notice = strings[stack[top]] or "unset"
            top = 0
        end
      + P("\02") / function()
            result.fullname = strings[stack[top]] or "unset"
            top = 0
        end
      + P("\03") / function()
            result.familyname = strings[stack[top]] or "unset"
            top = 0
        end
      + P("\04") / function()
            result.weight = strings[stack[top]] or "unset"
            top = 0
        end
      + P("\05") / function()
            result.fontbbox = { unpack(stack,1,4) }
            top = 0
        end
      + P("\06") / function()
            result.bluevalues = { unpack(stack,1,top) }
            top = 0
        end
      + P("\07") / function()
            result.otherblues = { unpack(stack,1,top) }
            top = 0
        end
      + P("\08") / function()
            result.familyblues = { unpack(stack,1,top) }
            top = 0
        end
      + P("\09") / function()
            result.familyotherblues = { unpack(stack,1,top) }
            top = 0
        end
      + P("\10") / function()
            result.stdhw = stack[top]
            top = 0
        end
      + P("\11") / function()
            result.stdvw = stack[top]
            top = 0
        end
      + P("\13") / function()
            result.uniqueid = stack[top]
            top = 0
        end
      + P("\14") / function()
            result.xuid = concat(stack,"",1,top)
            top = 0
        end
      + P("\15") / function()
            result.charset = stack[top]
            top = 0
        end
      + P("\16") / function()
            result.encoding = stack[top]
            top = 0
        end
      + P("\17") / function() -- valid cff2
            result.charstrings = stack[top]
            top = 0
        end
      + P("\18") / function()
            result.private = {
                size   = stack[top-1],
                offset = stack[top],
            }
            top = 0
        end
      + P("\19") / function()
            result.subroutines = stack[top]
            top = 0 -- new, forgotten ?
        end
      + P("\20") / function()
            result.defaultwidthx = stack[top]
            top = 0 -- new, forgotten ?
        end
      + P("\21") / function()
            result.nominalwidthx = stack[top]
            top = 0 -- new, forgotten ?
        end
   -- + P("\22") / function() -- reserved
   --   end
   -- + P("\23") / function() -- reserved
   --   end
      + P("\24") / function() -- new in cff2
            result.vstore = stack[top]
            top = 0
        end
      + P("\25") / function() -- new in cff2
            result.maxstack = stack[top]
            top = 0
        end
   -- + P("\26") / function() -- reserved
   --   end
   -- + P("\27") / function() -- reserved
   --   end

    local p_double = P("\12") * (
        P("\00") / function()
            result.copyright = stack[top]
            top = 0
        end
      + P("\01") / function()
            result.monospaced = stack[top] == 1 and true or false -- isfixedpitch
            top = 0
        end
      + P("\02") / function()
            result.italicangle = stack[top]
            top = 0
        end
      + P("\03") / function()
            result.underlineposition = stack[top]
            top = 0
        end
      + P("\04") / function()
            result.underlinethickness = stack[top]
            top = 0
        end
      + P("\05") / function()
            result.painttype = stack[top]
            top = 0
        end
      + P("\06") / function()
            result.charstringtype = stack[top]
            top = 0
        end
      + P("\07") / function() -- valid cff2
            result.fontmatrix = { unpack(stack,1,6) }
            top = 0
        end
      + P("\08") / function()
            result.strokewidth = stack[top]
            top = 0
        end
      + P("\09") / function()
            result.bluescale = stack[top]
            top = 0
        end
      + P("\10") / function()
            result.blueshift = stack[top]
            top = 0
        end
      + P("\11") / function()
            result.bluefuzz = stack[top]
            top = 0
        end
      + P("\12") / function()
            result.stemsnaph = { unpack(stack,1,top) }
            top = 0
        end
      + P("\13") / function()
            result.stemsnapv = { unpack(stack,1,top) }
            top = 0
        end
      + P("\20") / function()
            result.syntheticbase = stack[top]
            top = 0
        end
      + P("\21") / function()
            result.postscript = strings[stack[top]] or "unset"
            top = 0
        end
      + P("\22") / function()
            result.basefontname = strings[stack[top]] or "unset"
            top = 0
        end
      + P("\21") / function()
            result.basefontblend = stack[top]
            top = 0
        end
      + P("\30") / function()
            result.cid.registry   = strings[stack[top-2]] or "unset"
            result.cid.ordering   = strings[stack[top-1]] or "unset"
            result.cid.supplement = stack[top]
            top = 0
        end
      + P("\31") / function()
            result.cid.fontversion = stack[top]
            top = 0
        end
      + P("\32") / function()
            result.cid.fontrevision= stack[top]
            top = 0
        end
      + P("\33") / function()
            result.cid.fonttype = stack[top]
            top = 0
        end
      + P("\34") / function()
            result.cid.count = stack[top]
            top = 0
        end
      + P("\35") / function()
            result.cid.uidbase = stack[top]
            top = 0
        end
      + P("\36") / function() -- valid cff2
            result.cid.fdarray = stack[top]
            top = 0
        end
      + P("\37") / function() -- valid cff2
            result.cid.fdselect = stack[top]
            top = 0
        end
      + P("\38") / function()
            result.cid.fontname = strings[stack[top]] or "unset"
            top = 0
        end
    )

    -- Some lpeg fun ... a first variant split the byte and made a new string but
    -- the second variant is much faster. Not that it matters much as we don't see
    -- such numbers often.

    local remap_1 = {
        ["\x00"] = "00",  ["\x01"] = "01",  ["\x02"] = "02",  ["\x03"] = "03",  ["\x04"] = "04",  ["\x05"] = "05",  ["\x06"] = "06",  ["\x07"] = "07",  ["\x08"] = "08",  ["\x09"] = "09",  ["\x0A"] = "0.",  ["\x0B"] = "0E",  ["\x0C"] = "0E-",  ["\x0D"] = "0",  ["\x0E"] = "0-",  ["\x0F"] = "0",
        ["\x10"] = "10",  ["\x11"] = "11",  ["\x12"] = "12",  ["\x13"] = "13",  ["\x14"] = "14",  ["\x15"] = "15",  ["\x16"] = "16",  ["\x17"] = "17",  ["\x18"] = "18",  ["\x19"] = "19",  ["\x1A"] = "1.",  ["\x1B"] = "1E",  ["\x1C"] = "1E-",  ["\x1D"] = "1",  ["\x1E"] = "1-",  ["\x1F"] = "1",
        ["\x20"] = "20",  ["\x21"] = "21",  ["\x22"] = "22",  ["\x23"] = "23",  ["\x24"] = "24",  ["\x25"] = "25",  ["\x26"] = "26",  ["\x27"] = "27",  ["\x28"] = "28",  ["\x29"] = "29",  ["\x2A"] = "2.",  ["\x2B"] = "2E",  ["\x2C"] = "2E-",  ["\x2D"] = "2",  ["\x2E"] = "2-",  ["\x2F"] = "2",
        ["\x30"] = "30",  ["\x31"] = "31",  ["\x32"] = "32",  ["\x33"] = "33",  ["\x34"] = "34",  ["\x35"] = "35",  ["\x36"] = "36",  ["\x37"] = "37",  ["\x38"] = "38",  ["\x39"] = "39",  ["\x3A"] = "3.",  ["\x3B"] = "3E",  ["\x3C"] = "3E-",  ["\x3D"] = "3",  ["\x3E"] = "3-",  ["\x3F"] = "3",
        ["\x40"] = "40",  ["\x41"] = "41",  ["\x42"] = "42",  ["\x43"] = "43",  ["\x44"] = "44",  ["\x45"] = "45",  ["\x46"] = "46",  ["\x47"] = "47",  ["\x48"] = "48",  ["\x49"] = "49",  ["\x4A"] = "4.",  ["\x4B"] = "4E",  ["\x4C"] = "4E-",  ["\x4D"] = "4",  ["\x4E"] = "4-",  ["\x4F"] = "4",
        ["\x50"] = "50",  ["\x51"] = "51",  ["\x52"] = "52",  ["\x53"] = "53",  ["\x54"] = "54",  ["\x55"] = "55",  ["\x56"] = "56",  ["\x57"] = "57",  ["\x58"] = "58",  ["\x59"] = "59",  ["\x5A"] = "5.",  ["\x5B"] = "5E",  ["\x5C"] = "5E-",  ["\x5D"] = "5",  ["\x5E"] = "5-",  ["\x5F"] = "5",
        ["\x60"] = "60",  ["\x61"] = "61",  ["\x62"] = "62",  ["\x63"] = "63",  ["\x64"] = "64",  ["\x65"] = "65",  ["\x66"] = "66",  ["\x67"] = "67",  ["\x68"] = "68",  ["\x69"] = "69",  ["\x6A"] = "6.",  ["\x6B"] = "6E",  ["\x6C"] = "6E-",  ["\x6D"] = "6",  ["\x6E"] = "6-",  ["\x6F"] = "6",
        ["\x70"] = "70",  ["\x71"] = "71",  ["\x72"] = "72",  ["\x73"] = "73",  ["\x74"] = "74",  ["\x75"] = "75",  ["\x76"] = "76",  ["\x77"] = "77",  ["\x78"] = "78",  ["\x79"] = "79",  ["\x7A"] = "7.",  ["\x7B"] = "7E",  ["\x7C"] = "7E-",  ["\x7D"] = "7",  ["\x7E"] = "7-",  ["\x7F"] = "7",
        ["\x80"] = "80",  ["\x81"] = "81",  ["\x82"] = "82",  ["\x83"] = "83",  ["\x84"] = "84",  ["\x85"] = "85",  ["\x86"] = "86",  ["\x87"] = "87",  ["\x88"] = "88",  ["\x89"] = "89",  ["\x8A"] = "8.",  ["\x8B"] = "8E",  ["\x8C"] = "8E-",  ["\x8D"] = "8",  ["\x8E"] = "8-",  ["\x8F"] = "8",
        ["\x90"] = "90",  ["\x91"] = "91",  ["\x92"] = "92",  ["\x93"] = "93",  ["\x94"] = "94",  ["\x95"] = "95",  ["\x96"] = "96",  ["\x97"] = "97",  ["\x98"] = "98",  ["\x99"] = "99",  ["\x9A"] = "9.",  ["\x9B"] = "9E",  ["\x9C"] = "9E-",  ["\x9D"] = "9",  ["\x9E"] = "9-",  ["\x9F"] = "9",
        ["\xA0"] = ".0",  ["\xA1"] = ".1",  ["\xA2"] = ".2",  ["\xA3"] = ".3",  ["\xA4"] = ".4",  ["\xA5"] = ".5",  ["\xA6"] = ".6",  ["\xA7"] = ".7",  ["\xA8"] = ".8",  ["\xA9"] = ".9",  ["\xAA"] = "..",  ["\xAB"] = ".E",  ["\xAC"] = ".E-",  ["\xAD"] = ".",  ["\xAE"] = ".-",  ["\xAF"] = ".",
        ["\xB0"] = "E0",  ["\xB1"] = "E1",  ["\xB2"] = "E2",  ["\xB3"] = "E3",  ["\xB4"] = "E4",  ["\xB5"] = "E5",  ["\xB6"] = "E6",  ["\xB7"] = "E7",  ["\xB8"] = "E8",  ["\xB9"] = "E9",  ["\xBA"] = "E.",  ["\xBB"] = "EE",  ["\xBC"] = "EE-",  ["\xBD"] = "E",  ["\xBE"] = "E-",  ["\xBF"] = "E",
        ["\xC0"] = "E-0", ["\xC1"] = "E-1", ["\xC2"] = "E-2", ["\xC3"] = "E-3", ["\xC4"] = "E-4", ["\xC5"] = "E-5", ["\xC6"] = "E-6", ["\xC7"] = "E-7", ["\xC8"] = "E-8", ["\xC9"] = "E-9", ["\xCA"] = "E-.", ["\xCB"] = "E-E", ["\xCC"] = "E-E-", ["\xCD"] = "E-", ["\xCE"] = "E--", ["\xCF"] = "E-",
        ["\xD0"] = "-0",  ["\xD1"] = "-1",  ["\xD2"] = "-2",  ["\xD3"] = "-3",  ["\xD4"] = "-4",  ["\xD5"] = "-5",  ["\xD6"] = "-6",  ["\xD7"] = "-7",  ["\xD8"] = "-8",  ["\xD9"] = "-9",  ["\xDA"] = "-.",  ["\xDB"] = "-E",  ["\xDC"] = "-E-",  ["\xDD"] = "-",  ["\xDE"] = "--",  ["\xDF"] = "-",
    }
    local remap_2 = {
        ["\x0F"] = "0", ["\x1F"] = "1", ["\x2F"] = "2", ["\x3F"] = "3", ["\x4F"] = "4",
        ["\x5F"] = "5", ["\x6F"] = "6", ["\x7F"] = "7", ["\x8F"] = "8", ["\x9F"] = "9",
    }

    local p_last_1 = S("\x0F\x1F\x2F\x3F\x4F\x5F\x6F\x7F\x8F\x9F\xAF\xBF")
    local p_last_2 = R("\xF0\xFF")

    -- tricky, we don't want to append last

 -- local p_nibbles = P("\30") * Cs(((1-p_last)/remap)^0 * (P(1)/remap)) / function(n)
    local p_nibbles = P("\30") * Cs(((1-(p_last_1+p_last_2))/remap_1)^0 * (p_last_1/remap_2 + p_last_2/"")) / function(n)
        -- 0-9=digit a=. b=E c=E- d=reserved e=- f=finish
        top = top + 1
        stack[top] = tonumber(n) or 0
    end

    local p_byte = C(R("\32\246")) / function(b0)
        -- -107 .. +107
        top = top + 1
        stack[top] = byte(b0) - 139
    end

    local p_positive =  C(R("\247\250")) * C(1) / function(b0,b1)
        -- +108 .. +1131
        top = top + 1
        stack[top] = (byte(b0)-247)*256 + byte(b1) + 108
    end

    local p_negative = C(R("\251\254")) * C(1) / function(b0,b1)
        -- -1131 .. -108
        top = top + 1
        stack[top] = -(byte(b0)-251)*256 - byte(b1) - 108
    end

 -- local p_float = P("\255") * C(1) * C(1) * C(1) * C(1) / function(b0,b1,b2,b3)
 --     top = top + 1
 --     stack[top] = 0
 -- end

    local p_short = P("\28") * C(1) * C(1) / function(b1,b2)
        -- -32768 .. +32767 : b1<<8 | b2
        top = top + 1
        local n = 0x100 * byte(b1) + byte(b2)
        if n  >= 0x8000 then
            stack[top] = n - 0xFFFF - 1
        else
            stack[top] =  n
        end
    end

    local p_long = P("\29") * C(1) * C(1) * C(1) * C(1) / function(b1,b2,b3,b4)
        -- -2^31 .. +2^31-1 : b1<<24 | b2<<16 | b3<<8 | b4
        top = top + 1
        local n = 0x1000000 * byte(b1) + 0x10000 * byte(b2) + 0x100 * byte(b3) + byte(b4)
        if n >= 0x8000000 then
            stack[top] = n - 0xFFFFFFFF - 1
        else
            stack[top] = n
        end
    end

    local p_unsupported = P(1) / function(detail)
        top = 0
    end

    local p_dictionary = (
        p_byte
      + p_positive
      + p_negative
      + p_short
      + p_long
      + p_nibbles
      + p_single
      + p_double
   -- + p_float
      + p_unsupported
    )^1

    parsedictionaries = function(data,dictionaries,version)
        stack   = { }
        strings = data.strings
        if trace_charstrings then
            report("charstring format %a",version)
        end
        for i=1,#dictionaries do
            top    = 0
            result = version == "cff" and {
                monospaced         = false,
                italicangle        = 0,
                underlineposition  = -100,
                underlinethickness = 50,
                painttype          = 0,
                charstringtype     = 2,
                fontmatrix         = { 0.001, 0, 0, 0.001, 0, 0 },
                fontbbox           = { 0, 0, 0, 0 },
                strokewidth        = 0,
                charset            = 0,
                encoding           = 0,
                cid = {
                    fontversion     = 0,
                    fontrevision    = 0,
                    fonttype        = 0,
                    count           = 8720,
                }
            } or {
                charstringtype     = 2,
                charset            = 0,
                vstore             = 0,
                cid = {
                    -- nothing yet
                },
            }
            lpegmatch(p_dictionary,dictionaries[i])
            dictionaries[i] = result
        end
        --
        result = { }
        top    = 0
        stack  = { }
    end

    parseprivates = function(data,dictionaries)
        stack   = { }
        strings = data.strings
        for i=1,#dictionaries do
            local private = dictionaries[i].private
            if private and private.data then
                top     = 0
                result  = {
                    forcebold         = false,
                    languagegroup     = 0,
                    expansionfactor   = 0.06,
                    initialrandomseed = 0,
                    subroutines       = 0,
                    defaultwidthx     = 0,
                    nominalwidthx     = 0,
                    cid               = {
                        -- actually an error
                    },
                }
                lpegmatch(p_dictionary,private.data)
                private.data = result
            end
        end
        result = { }
        top    = 0
        stack  = { }
    end

    -- All bezier curves have 6 points with successive pairs relative to
    -- the previous pair. Some can be left out and are then copied or zero
    -- (optimization).
    --
    -- We are not really interested in all the details of a glyph because we
    -- only need to calculate the boundingbox. So, todo: a quick no result but
    -- calculate only variant.
    --
    -- The conversion is straightforward and the specification os clear once
    -- you understand that the x and y needs to be updates each step. It's also
    -- quite easy to test because in mp a shape will look bad when a few variables
    -- are swapped. But still there might be bugs down here because not all
    -- variants are seen in a font so far. We are less compact that the ff code
    -- because there quite some variants are done in one helper with a lot of
    -- testing for states.

    local x            = 0
    local y            = 0
    local width        = false
    local lsb          = 0
    local result       = { }
    local r            = 0
    local stems        = 0
    local globalbias   = 0
    local localbias    = 0
    local nominalwidth = 0
    local defaultwidth = 0
    local charset      = false
    local globals      = false
    local locals       = false
    local depth        = 1
    local xmin         = 0
    local xmax         = 0
    local ymin         = 0
    local ymax         = 0
    local checked      = false
    local keepcurve    = false
    local version      = 2
    local regions      = false
    local nofregions   = 0
    local region       = false
    local factors      = false
    local axis         = false
    local vsindex      = 0
    local justpass     = false
    local seacs        = { }
    local procidx      = nil

    local function showstate(where,i,n)
        if i then
            local j = i + n - 1
            report("%w%-10s : [%s] step",depth*2+2,where,concat(stack," ",i,j <= top and j or top))
        else
            report("%w%-10s : [%s] n=%i",depth*2,where,concat(stack," ",1,top),top)
        end
    end

    local function showvalue(where,value,showstack)
        if showstack then
            report("%w%-10s : %s : [%s] n=%i",depth*2,where,tostring(value),concat(stack," ",1,top),top)
        else
            report("%w%-10s : %s",depth*2,where,tostring(value))
        end
    end

    -- All these indirect calls make this run slower but it's cleaner this way
    -- and we cache the result. As we moved the boundingbox code inline we gain
    -- some back. I inlined some of then and a bit speed can be gained by more
    -- inlining but not that much.

    -- Maybe have several action tables:
    --
    -- keep curve / checked
    -- keep curve / not checked
    -- checked
    -- not checked

    local function xymoveto()
        if keepcurve then
            r = r + 1
            result[r] = { x, y, "m" }
        end
        if checked then
            if x > xmax then xmax = x elseif x < xmin then xmin = x end
            if y > ymax then ymax = y elseif y < ymin then ymin = y end
        else
            xmin = x
            ymin = y
            xmax = x
            ymax = y
            checked = true
        end
    end

    local function xmoveto() -- slight speedup
        if keepcurve then
            r = r + 1
            result[r] = { x, y, "m" }
        end
        if not checked then
            xmin = x
            ymin = y
            xmax = x
            ymax = y
            checked = true
        elseif x > xmax then
            xmax = x
        elseif x < xmin then
            xmin = x
        end
    end

    local function ymoveto() -- slight speedup
        if keepcurve then
            r = r + 1
            result[r] = { x, y, "m" }
        end
        if not checked then
            xmin = x
            ymin = y
            xmax = x
            ymax = y
            checked = true
        elseif y > ymax then
            ymax = y
        elseif y < ymin then
            ymin = y
        end
    end

    local function moveto()
        if trace_charstrings then
            showstate("moveto")
        end
        top = 0 -- forgotten
        xymoveto()
    end

    local function xylineto() -- we could inline, no blend
        if keepcurve then
            r = r + 1
            result[r] = { x, y, "l" }
        end
        if checked then
            if x > xmax then xmax = x elseif x < xmin then xmin = x end
            if y > ymax then ymax = y elseif y < ymin then ymin = y end
        else
            xmin = x
            ymin = y
            xmax = x
            ymax = y
            checked = true
        end
    end

    local function xlineto() -- slight speedup
        if keepcurve then
            r = r + 1
            result[r] = { x, y, "l" }
        end
        if not checked then
            xmin = x
            ymin = y
            xmax = x
            ymax = y
            checked = true
        elseif x > xmax then
            xmax = x
        elseif x < xmin then
            xmin = x
        end
    end

    local function ylineto() -- slight speedup
        if keepcurve then
            r = r + 1
            result[r] = { x, y, "l" }
        end
        if not checked then
            xmin = x
            ymin = y
            xmax = x
            ymax = y
            checked = true
        elseif y > ymax then
            ymax = y
        elseif y < ymin then
            ymin = y
        end
    end

    local function xycurveto(x1,y1,x2,y2,x3,y3,i,n) -- called local so no blend here
        if trace_charstrings then
            showstate("curveto",i,n)
        end
        if keepcurve then
            r = r + 1
            result[r] = { x1, y1, x2, y2, x3, y3, "c" }
        end
        if checked then
            if x1 > xmax then xmax = x1 elseif x1 < xmin then xmin = x1 end
            if y1 > ymax then ymax = y1 elseif y1 < ymin then ymin = y1 end
        else
            xmin = x1
            ymin = y1
            xmax = x1
            ymax = y1
            checked = true
        end
        if x2 > xmax then xmax = x2 elseif x2 < xmin then xmin = x2 end
        if y2 > ymax then ymax = y2 elseif y2 < ymin then ymin = y2 end
        if x3 > xmax then xmax = x3 elseif x3 < xmin then xmin = x3 end
        if y3 > ymax then ymax = y3 elseif y3 < ymin then ymin = y3 end
    end

    local function rmoveto()
        if not width then
            if top > 2 then
                width = stack[1]
                if trace_charstrings then
                    showvalue("backtrack width",width)
                end
            else
                width = true
            end
        end
        if trace_charstrings then
            showstate("rmoveto")
        end
        x = x + stack[top-1] -- dx1
        y = y + stack[top]   -- dy1
        top = 0
        xymoveto()
    end

    local function hmoveto()
        if not width then
            if top > 1 then
                width = stack[1]
                if trace_charstrings then
                    showvalue("backtrack width",width)
                end
            else
                width = true
            end
        end
        if trace_charstrings then
            showstate("hmoveto")
        end
        x = x + stack[top] -- dx1
        top = 0
        xmoveto()
    end

    local function vmoveto()
        if not width then
            if top > 1 then
                width = stack[1]
                if trace_charstrings then
                    showvalue("backtrack width",width)
                end
            else
                width = true
            end
        end
        if trace_charstrings then
            showstate("vmoveto")
        end
        y = y + stack[top] -- dy1
        top = 0
        ymoveto()
    end

    local function rlineto()
        if trace_charstrings then
            showstate("rlineto")
        end
        for i=1,top,2 do
            x = x + stack[i]   -- dxa
            y = y + stack[i+1] -- dya
            xylineto()
        end
        top = 0
    end

    local function hlineto() -- x (y,x)+ | (x,y)+
        if trace_charstrings then
            showstate("hlineto")
        end
        if top == 1 then
            x = x + stack[1]
            xlineto()
        else
            local swap = true
            for i=1,top do
                if swap then
                    x = x + stack[i]
                    xlineto()
                    swap = false
                else
                    y = y + stack[i]
                    ylineto()
                    swap = true
                end
            end
        end
        top = 0
    end

    local function vlineto() -- y (x,y)+ | (y,x)+
        if trace_charstrings then
            showstate("vlineto")
        end
        if top == 1 then
            y = y + stack[1]
            ylineto()
        else
            local swap = false
            for i=1,top do
                if swap then
                    x = x + stack[i]
                    xlineto()
                    swap = false
                else
                    y = y + stack[i]
                    ylineto()
                    swap = true
                end
            end
        end
        top = 0
    end

    local function rrcurveto()
        if trace_charstrings then
            showstate("rrcurveto")
        end
if top == 6 then
    local ax = x  + stack[1] -- dxa
    local ay = y  + stack[2] -- dya
    local bx = ax + stack[3] -- dxb
    local by = ay + stack[4] -- dyb
    x = bx + stack[5]        -- dxc
    y = by + stack[6]        -- dyc
    xycurveto(ax,ay,bx,by,x,y,1,6)
else
-- print("rr",top==6,top)
        for i=1,top,6 do
            local ax = x  + stack[i]   -- dxa
            local ay = y  + stack[i+1] -- dya
            local bx = ax + stack[i+2] -- dxb
            local by = ay + stack[i+3] -- dyb
            x = bx + stack[i+4]        -- dxc
            y = by + stack[i+5]        -- dyc
            xycurveto(ax,ay,bx,by,x,y,i,6)
        end
end
        top = 0
    end

    local function hhcurveto()
        if trace_charstrings then
            showstate("hhcurveto")
        end
        local s = 1
        if top % 2 ~= 0 then
            y = y + stack[1]           -- dy1
            s = 2
        end
if top == 4 then
            local ax = x + stack[1]  -- dxa
            local ay = y
            local bx = ax + stack[2] -- dxb
            local by = ay + stack[3] -- dyb
            x = bx + stack[4]        -- dxc
            y = by
            xycurveto(ax,ay,bx,by,x,y,1,4)
else
        for i=s,top,4 do
            local ax = x + stack[i]    -- dxa
            local ay = y
            local bx = ax + stack[i+1] -- dxb
            local by = ay + stack[i+2] -- dyb
            x = bx + stack[i+3]        -- dxc
            y = by
            xycurveto(ax,ay,bx,by,x,y,i,4)
        end
end
        top = 0
    end

    local function vvcurveto()
        if trace_charstrings then
            showstate("vvcurveto")
        end
        local s = 1
        local d = 0
        if top % 2 ~= 0 then
            d = stack[1]               -- dx1
            s = 2
        end
if top == 4 then
    local ax = x + d
    local ay = y + stack[1]  -- dya
    local bx = ax + stack[2] -- dxb
    local by = ay + stack[3] -- dyb
    x = bx
    y = by + stack[4]        -- dyc
    xycurveto(ax,ay,bx,by,x,y,1,4)
    d = 0
else
        for i=s,top,4 do
            local ax = x + d
            local ay = y + stack[i]    -- dya
            local bx = ax + stack[i+1] -- dxb
            local by = ay + stack[i+2] -- dyb
            x = bx
            y = by + stack[i+3]        -- dyc
            xycurveto(ax,ay,bx,by,x,y,i,4)
            d = 0
        end
end
        top = 0
    end

    local function xxcurveto(swap)
        local last = top % 4 ~= 0 and stack[top]
        if last then
            top = top - 1
        end
if top == 4 then
        local ax, ay, bx, by
        if swap then
            ax = x  + stack[1]
            ay = y
            bx = ax + stack[2]
            by = ay + stack[3]
            y  = by + stack[4]
            if last then
                x = bx + last
            else
                x = bx
            end
        else
            ax = x
            ay = y  + stack[1]
            bx = ax + stack[2]
            by = ay + stack[3]
            x  = bx + stack[4]
            if last then
                y = by + last
            else
                y = by
            end
        end
        xycurveto(ax,ay,bx,by,x,y,1 ,4)
else
        for i=1,top,4 do
            local ax, ay, bx, by
            if swap then
                ax = x  + stack[i]
                ay = y
                bx = ax + stack[i+1]
                by = ay + stack[i+2]
                y  = by + stack[i+3]
                if last and i+3 == top then
                    x = bx + last
                else
                    x = bx
                end
                swap = false
            else
                ax = x
                ay = y  + stack[i]
                bx = ax + stack[i+1]
                by = ay + stack[i+2]
                x  = bx + stack[i+3]
                if last and i+3 == top then
                    y = by + last
                else
                    y = by
                end
                swap = true
            end
            xycurveto(ax,ay,bx,by,x,y,i,4)
        end
end
        top = 0
    end

    local function hvcurveto()
        if trace_charstrings then
            showstate("hvcurveto")
        end
        xxcurveto(true)
    end

    local function vhcurveto()
        if trace_charstrings then
            showstate("vhcurveto")
        end
        xxcurveto(false)
    end

    local function rcurveline()
        if trace_charstrings then
            showstate("rcurveline")
        end
        for i=1,top-2,6 do
            local ax = x  + stack[i]   -- dxa
            local ay = y  + stack[i+1] -- dya
            local bx = ax + stack[i+2] -- dxb
            local by = ay + stack[i+3] -- dyb
            x = bx + stack[i+4] -- dxc
            y = by + stack[i+5] -- dyc
            xycurveto(ax,ay,bx,by,x,y,i,6)
        end
        x = x + stack[top-1] -- dxc
        y = y + stack[top]   -- dyc
        xylineto()
        top = 0
    end

    local function rlinecurve()
        if trace_charstrings then
            showstate("rlinecurve")
        end
        if top > 6 then
            for i=1,top-6,2 do
                x = x + stack[i]
                y = y + stack[i+1]
                xylineto()
            end
        end
        local ax = x  + stack[top-5]
        local ay = y  + stack[top-4]
        local bx = ax + stack[top-3]
        local by = ay + stack[top-2]
        x = bx + stack[top-1]
        y = by + stack[top]
        xycurveto(ax,ay,bx,by,x,y)
        top = 0
    end

    -- flex is not yet tested! no loop

    local function flex() -- fd not used
        if trace_charstrings then
            showstate("flex")
        end
        local ax = x  + stack[1]  -- dx1
        local ay = y  + stack[2]  -- dy1
        local bx = ax + stack[3]  -- dx2
        local by = ay + stack[4]  -- dy2
        local cx = bx + stack[5]  -- dx3
        local cy = by + stack[6]  -- dy3
        xycurveto(ax,ay,bx,by,cx,cy)
        local dx = cx + stack[7]  -- dx4
        local dy = cy + stack[8]  -- dy4
        local ex = dx + stack[9]  -- dx5
        local ey = dy + stack[10] -- dy5
        x = ex + stack[11]        -- dx6
        y = ey + stack[12]        -- dy6
        xycurveto(dx,dy,ex,ey,x,y)
        top = 0
    end

    local function hflex()
        if trace_charstrings then
            showstate("hflex")
        end
        local ax = x  + stack[1] -- dx1
        local ay = y
        local bx = ax + stack[2] -- dx2
        local by = ay + stack[3] -- dy2
        local cx = bx + stack[4] -- dx3
        local cy = by
        xycurveto(ax,ay,bx,by,cx,cy)
        local dx = cx + stack[5] -- dx4
        local dy = by
        local ex = dx + stack[6] -- dx5
        local ey = y
        x = ex + stack[7]        -- dx6
        xycurveto(dx,dy,ex,ey,x,y)
        top = 0
    end

    local function hflex1()
        if trace_charstrings then
            showstate("hflex1")
        end
        local ax = x  + stack[1] -- dx1
        local ay = y  + stack[2] -- dy1
        local bx = ax + stack[3] -- dx2
        local by = ay + stack[4] -- dy2
        local cx = bx + stack[5] -- dx3
        local cy = by
        xycurveto(ax,ay,bx,by,cx,cy)
        local dx = cx + stack[6] -- dx4
        local dy = by
        local ex = dx + stack[7] -- dx5
        local ey = dy + stack[8] -- dy5
        x = ex + stack[9]        -- dx6
        xycurveto(dx,dy,ex,ey,x,y)
        top = 0
    end

    local function flex1()
        if trace_charstrings then
            showstate("flex1")
        end
        local ax = x  + stack[1]  --dx1
        local ay = y  + stack[2]  --dy1
        local bx = ax + stack[3]  --dx2
        local by = ay + stack[4]  --dy2
        local cx = bx + stack[5]  --dx3
        local cy = by + stack[6]  --dy3
        xycurveto(ax,ay,bx,by,cx,cy)
        local dx = cx + stack[7]  --dx4
        local dy = cy + stack[8]  --dy4
        local ex = dx + stack[9]  --dx5
        local ey = dy + stack[10] --dy5
        if abs(ex - x) > abs(ey - y) then -- spec: abs(dx) > abs(dy)
            x = ex + stack[11]
        else
            y = ey + stack[11]
        end
        xycurveto(dx,dy,ex,ey,x,y)
        top = 0
    end

    local function getstem()
        if top == 0 then
            -- bad
        elseif top % 2 ~= 0 then
            if width then
                remove(stack,1)
            else
                width = remove(stack,1)
                if trace_charstrings then
                    showvalue("width",width)
                end
            end
            top = top - 1
        end
        if trace_charstrings then
            showstate("stem")
        end
        stems = stems + idiv(top,2)
        top   = 0
    end

    local function getmask()
        if top == 0 then
            -- bad
        elseif top % 2 ~= 0 then
            if width then
                remove(stack,1)
            else
                width = remove(stack,1)
                if trace_charstrings then
                    showvalue("width",width)
                end
            end
            top = top - 1
        end
        if trace_charstrings then
            showstate(operator == 19 and "hintmark" or "cntrmask")
        end
        stems = stems + idiv(top,2)
        top   = 0
        if stems == 0 then
            -- forget about it
        elseif stems <= 8 then
            return 1
        else
         -- return floor((stems+7)/8)
            return idiv(stems+7,8)
        end
    end

    local function unsupported(t)
        if trace_charstrings then
            showstate("unsupported " .. t)
        end
        top = 0
    end

    local function unsupportedsub(t)
        if trace_charstrings then
            showstate("unsupported sub " .. t)
        end
        top = 0
    end

    -- type 1 (not used in type 2)

    local function getstem3()
        if trace_charstrings then
            showstate("stem3")
        end
        top = 0
    end

    local function divide()
        if version == "cff" then
            local d = stack[top]
            top = top - 1
            stack[top] = stack[top] / d
        end
    end

    local function closepath()
        if version == "cff" then
            if trace_charstrings then
                showstate("closepath")
            end
        end
        top = 0
    end

    local function hsbw()
        if version == "cff" then
            if trace_charstrings then
                showstate("hsbw")
            end
            lsb   = stack[top-1] or 0
            width = stack[top]
        end
        top = 0
    end

    local function sbw()
        if version == "cff" then
            if trace_charstrings then
                showstate("sbw")
            end
            lsb   = stack[top-3]
            width = stack[top-1]
        end
        top = 0
    end

    -- asb adx ady bchar achar seac (accented characters)

    local function seac()
        if version == "cff" then
            if trace_charstrings then
                showstate("seac")
            end
        end
        top = 0
    end

    -- These are probably used for special cases i.e. call out to the
    -- postscript interpreter (p 61 of the spec as well as chapter 8).
    --
    -- This needs checking (I have to ask Taco next time we meet.)

    local popped = 3
    local hints  = 3

    -- arg1 ... argn n othersubr# <callothersubr> (on postscript stack)

    local function callothersubr()
        if version == "cff" then
            if trace_charstrings then
                showstate("callothersubr")
            end
            if stack[top] == hints then
                popped = stack[top-2]
            else
                popped = 3
            end
            local t = stack[top-1]
            if t then
                top = top - (t + 2)
                if top < 0 then
                    top = 0
                end
            else
                top = 0
            end
        else
            top = 0
        end
    end

    -- <pop> number (from postscript stack)

    local function pop()
        if version == "cff" then
            if trace_charstrings then
                showstate("pop")
            end
            top = top + 1
            stack[top] = popped
        else
            top = 0
        end
    end

    local function setcurrentpoint()
        if version == "cff" then
            if trace_charstrings then
                showstate("setcurrentpoint (unsupported)")
            end
            x = x + stack[top-1]
            y = y + stack[top]
        end
        top = 0
    end

    -- So far for unsupported postscript. Now some cff2 magic. As I still need
    -- to wrap my head around the rather complex variable font specification
    -- with regions and axis, the following approach kind of works but is more
    -- some trial and error trick. It's still not clear how much of the complex
    -- truetype description applies to cff. Once there are fonts out there we'll
    -- get there. (Marcel and friends did some tests with recent cff2 fonts so
    -- the code has been adapted accordingly.)

    local reginit = false

    local function updateregions(n) -- n + 1
        if regions then
            local current = regions[n+1] or regions[1]
            nofregions = #current
            if axis and n ~= reginit then
                factors = { }
                for i=1,nofregions do
                    local region = current[i]
                    local s = 1
                    for j=1,#axis do
                        local f = axis[j]
                        local r = region[j]
                        local start = r.start
                        local peak  = r.peak
                        local stop  = r.stop
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
                            s = s * (f - start) / (peak - start)
                        elseif f > peak then
                            s = s * (stop - f) / (stop - peak)
                        else
                            -- * 1
                        end
                    end
                    factors[i] = s
                end
            end
        end
        reginit = n
    end

    local function setvsindex()
        local vsindex = stack[top]
        if trace_charstrings then
            showstate(formatters["vsindex %i"](vsindex))
        end
        updateregions(vsindex)
        top = top - 1
    end

    local function blend()
        local n = stack[top]
        top = top - 1
        if axis then
            --  x    (r1x,r2x,r3x)
            -- (x,y) (r1x,r2x,r3x) (r1y,r2y,r3y)
            if trace_charstrings then
                local t = top - nofregions * n
                local m = t - n
                for i=1,n do
                    local k   = m + i
                    local d   = m + n + (i-1)*nofregions
                    local old = stack[k]
                    local new = old
                    for r=1,nofregions do
                        new = new + stack[d+r] * factors[r]
                    end
                    stack[k] = new
                    showstate(formatters["blend %i of %i: %s -> %s"](i,n,old,new))
                end
                top = t
            elseif n == 1 then
                top = top - nofregions
                local v = stack[top]
                for r=1,nofregions do
                    v = v + stack[top+r] * factors[r]
                end
                stack[top] = v
            else
                top = top - nofregions * n
                local d = top
                local k = top - n
                for i=1,n do
                    k = k + 1
                    local v = stack[k]
                    for r=1,nofregions do
                        v = v + stack[d+r] * factors[r]
                    end
                    stack[k] = v
                    d = d + nofregions
                end
            end
        else
            top = top - nofregions * n
        end
    end

    -- Bah, we cannot use a fast lpeg because a hint has an unknown size and a
    -- runtime capture cannot handle that well.

    local actions = { [0] =
        unsupported,  --  0
        getstem,      --  1 -- hstem
        unsupported,  --  2
        getstem,      --  3 -- vstem
        vmoveto,      --  4
        rlineto,      --  5
        hlineto,      --  6
        vlineto,      --  7
        rrcurveto,    --  8
        unsupported,  --  9 -- closepath
        unsupported,  -- 10 -- calllocal,
        unsupported,  -- 11 -- callreturn,
        unsupported,  -- 12 -- elsewhere
        hsbw,         -- 13 -- hsbw (type 1 cff)
        unsupported,  -- 14 -- endchar,
        setvsindex,   -- 15 -- cff2
        blend,        -- 16 -- cff2
        unsupported,  -- 17
        getstem,      -- 18 -- hstemhm
        getmask,      -- 19 -- hintmask
        getmask,      -- 20 -- cntrmask
        rmoveto,      -- 21
        hmoveto,      -- 22
        getstem,      -- 23 -- vstemhm
        rcurveline,   -- 24
        rlinecurve,   -- 25
        vvcurveto,    -- 26
        hhcurveto,    -- 27
        unsupported,  -- 28 -- elsewhere
        unsupported,  -- 29 -- elsewhere
        vhcurveto,    -- 30
        hvcurveto,    -- 31
    }

    local reverse = { [0] =
        "unsupported",
        "getstem",
        "unsupported",
        "getstem",
        "vmoveto",
        "rlineto",
        "hlineto",
        "vlineto",
        "rrcurveto",
        "unsupported",
        "unsupported",
        "unsupported",
        "unsupported",
        "hsbw",
        "unsupported",
        "setvsindex",
        "blend",
        "unsupported",
        "getstem",
        "getmask",
        "getmask",
        "rmoveto",
        "hmoveto",
        "getstem",
        "rcurveline",
        "rlinecurve",
        "vvcurveto",
        "hhcurveto",
        "unsupported",
        "unsupported",
        "vhcurveto",
        "hvcurveto",
    }

    local subactions = {
        -- cff 1
        [000] = dotsection,
        [001] = getstem3,
        [002] = getstem3,
        [006] = seac,
        [007] = sbw,
        [012] = divide,
        [016] = callothersubr,
        [017] = pop,
        [033] = setcurrentpoint,
        -- cff 2
        [034] = hflex,
        [035] = flex,
        [036] = hflex1,
        [037] = flex1,
    }

    local chars = setmetatableindex(function (t,k)
        local v = char(k)
        t[k] = v
        return v
    end)

    local c_endchar = chars[14]

    -- todo: round in blend

    local encode  = { }
    local typeone = false

    -- this eventually can become a helper

    setmetatableindex(encode,function(t,i)
        for i=-2048,-1130 do
            t[i] = char(28,band(rshift(i,8),0xFF),band(i,0xFF))
        end
        for i=-1131,-108 do
            local v = 0xFB00 - i - 108
            t[i] = char(band(rshift(v,8),0xFF),band(v,0xFF))
        end
        for i=-107,107 do
            t[i] = chars[i + 139]
        end
        for i=108,1131 do
            local v = 0xF700 + i - 108
            t[i] = char(extract(v,8,8),extract(v,0,8))
        end
        for i=1132,2048 do
            t[i] = char(28,band(rshift(i,8),0xFF),band(i,0xFF))
        end
        setmetatableindex(encode,function(t,k)
            -- as we're cff2 we write 16.16-bit signed fixed value
            local r = round(k)
            local v = rawget(t,r)
            if v then
                return v
            end
            local v1 = floor(k)
            local v2 = floor((k - v1) * 0x10000)
            return char(255,extract(v1,8,8),extract(v1,0,8),extract(v2,8,8),extract(v2,0,8))
        end)
        return t[i]
    end)

    readers.cffencoder = encode

    local function p_setvsindex()
        local vsindex = stack[top]
        updateregions(vsindex)
        top = top - 1
    end

    local function p_blend()
        -- leaves n values on stack
        local n = stack[top]
        top = top - 1
        if not axis then
            -- fatal error
        elseif n == 1 then
            top = top - nofregions
            local v = stack[top]
            for r=1,nofregions do
                v = v + stack[top+r] * factors[r]
            end
            stack[top] = round(v)
        else
            top = top - nofregions * n
            local d = top
            local k = top - n
            for i=1,n do
                k = k + 1
                local v = stack[k]
                for r=1,nofregions do
                    v = v + stack[d+r] * factors[r]
                end
                stack[k] = round(v)
                d = d + nofregions
            end
        end
    end

    local function p_getstem()
        local n = 0
        if top % 2 ~= 0 then
            n = 1
        end
        if top > n then
            stems = stems + idiv(top-n,2)
        end
    end

    local function p_getmask()
        local n = 0
        if top % 2 ~= 0 then
            n = 1
        end
        if top > n then
            stems = stems + idiv(top-n,2)
        end
        if stems == 0 then
            return 0
        elseif stems <= 8 then
            return 1
        else
            return idiv(stems+7,8)
        end
    end

    -- end of experiment

    local process

    local function call(scope,list,bias) -- ,process)
        depth = depth + 1
        if top == 0 then
            showstate(formatters["unknown %s call %s, case %s"](scope,"?",1))
            top = 0
        else
            local index = stack[top] + bias
            top = top - 1
            if trace_charstrings then
                showvalue(scope,index,true)
            end
            local tab = list[index]
            if tab then
                process(tab)
            else
                showstate(formatters["unknown %s call %s, case %s"](scope,index,2))
                top = 0
            end
        end
        depth = depth - 1
    end

    -- precompiling and reuse is much slower than redoing the calls

    process = function(tab)
        local i = 1
        local n = #tab
        while i <= n do
            local t = tab[i]
            if t >= 32 then
                top = top + 1
                if t <= 246 then
                    -- -107 .. +107
                    stack[top] = t - 139
                    i = i + 1
                elseif t <= 250 then
                    -- +108 .. +1131
                 -- stack[top] = (t-247)*256 + tab[i+1] + 108
                 -- stack[top] = t*256 - 247*256 + tab[i+1] + 108
                    stack[top] = t*256 - 63124 + tab[i+1]
                    i = i + 2
                elseif t <= 254 then
                    -- -1131 .. -108
                 -- stack[top] = -(t-251)*256 - tab[i+1] - 108
                 -- stack[top] = -t*256 + 251*256 - tab[i+1] - 108
                    stack[top] = -t*256 + 64148 - tab[i+1]
                    i = i + 2
                elseif typeone then
                    local n = 0x1000000 * tab[i+1] + 0x10000 * tab[i+2] + 0x100 * tab[i+3] + tab[i+4]
                    if n >= 0x8000000 then
                        n = n - 0xFFFFFFFF - 1
                    end
                    stack[top] = n
                    i = i + 5
                else
                    local n1 = 0x100 * tab[i+1] + tab[i+2]
                    local n2 = 0x100 * tab[i+3] + tab[i+4]
                    if n1 >= 0x8000 then
                        n1 = n1 - 0x10000
                    end
                    stack[top] = n1 + n2/0xFFFF
                    i = i + 5
                end
            elseif t == 28 then
                -- -32768 .. +32767 : b1<<8 | b2
                top = top + 1
                local n = 0x100 * tab[i+1] + tab[i+2]
                if n  >= 0x8000 then
                 -- stack[top] = n - 0xFFFF - 1
                    stack[top] = n - 0x10000
                else
                    stack[top] = n
                end
                i = i + 3
            elseif t == 11 then -- not in cff2
                if trace_charstrings then
                    showstate("return")
                end
                return
            elseif t == 10 then
                call("local",locals,localbias) -- ,process)
                i = i + 1
            elseif t == 14 then -- not in cff2
                if width then
                    -- okay
                elseif top > 0 then
                    width = stack[1]
                    if trace_charstrings then
                        showvalue("width",width)
                    end
                else
                    width = true
                end
                if trace_charstrings then
                    showstate("endchar")
                end
                return
            elseif t == 29 then
                call("global",globals,globalbias) -- ,process)
                i = i + 1
            elseif t == 12 then
                i = i + 1
                local t = tab[i]
                if justpass then
                    if t >= 34 and t <= 37 then -- flexes
                        for i=1,top do
                            r = r + 1 ; result[r] = encode[stack[i]]
                        end
                        r = r + 1 ; result[r] = chars[12]
                        r = r + 1 ; result[r] = chars[t]
                        top = 0
                    elseif t == 6 then
                        seacs[procidx] = {
                            asb    = stack[1],
                            adx    = stack[2],
                            ady    = stack[3],
                            base   = stack[4],
                            accent = stack[5],
                            width  = width,
                            lsb    = lsb,
                        }
                        top = 0
                    else
                        local a = subactions[t]
                        if a then
                            a(t)
                        else
                            top = 0
                        end
                    end
                else
                    local a = subactions[t]
                    if a then
                        a(t)
                    else
                        if trace_charstrings then
                            showvalue("<subaction>",t)
                        end
                        top = 0
                    end
                end
                i = i + 1
            elseif justpass then
                -- todo: local a = passactions
                if t == 15 then
                    p_setvsindex()
                    i = i + 1
                elseif t == 16 then
                    local s = p_blend() or 0
                    i = i + s + 1
                -- cff 1: (when cff2 strip them)
                elseif t == 1 or t == 3 or t == 18 or operation == 23 then
                    p_getstem() -- at the start
                    if version == "cff" then
--                     if true then
                        if top > 0 then
                            for i=1,top do
                                r = r + 1 ; result[r] = encode[stack[i]]
                            end
                            top = 0
                        end
                        r = r + 1 ; result[r] = chars[t]
                    else
                        top = 0
                    end
                    i = i + 1
                -- cff 1: (when cff2 strip them)
                elseif t == 19 or t == 20 then
                    local s = p_getmask() or 0 -- after the stems
--                     if version == "cff" then
                    if true then
                        if top > 0 then
                            for i=1,top do
                                r = r + 1 ; result[r] = encode[stack[i]]
                            end
                            top = 0
                        end
                        r = r + 1 ; result[r] = chars[t]
                        for j=1,s do
                            i = i + 1
                            r = r + 1 ; result[r] = chars[tab[i]]
                        end
                    else
                        i = i + s
                        top = 0
                    end
                    i = i + 1
                -- cff 1: closepath
                elseif t == 9 then
                    top = 0
                    i = i + 1
                elseif t == 13 then
                    hsbw()
--                     if version == "cff" then
                    if true then
                        -- we do a moveto over lsb
                        r = r + 1 ; result[r] = encode[lsb]
                        r = r + 1 ; result[r] = chars[22]
                    else
                        -- lsb is supposed to be zero
                    end
                    i = i + 1
                else
                    if trace_charstrings then
                        showstate(reverse[t] or "<action>")
                    end
                    if top > 0 then
                     -- if t == 8 and top > 42 then
                        if t == 8 and top > 48 then
                            -- let's assume this only happens for rrcurveto .. the other ones would need some more
                            -- complex handling (cff2 stuff)
                            --
                            -- dx1 dy1 (dx1+dx2) (dy1+dy2) (dx1+dx2+dx3) (dy1+dy2+dy3) rcurveto.
                            local n = 0
                            for i=1,top do
                             -- if n == 42 then
                                if n == 48 then
--                                     local zero = encode[0]
--                                     local res3 = result[r-3]
--                                     local res2 = result[r-2]
--                                     local res1 = result[r-1]
--                                     local res0 = result[r]
--                                     result[r-3] = zero
--                                     result[r-2] = zero
                                    r = r + 1 ; result[r] = chars[t]
--                                     r = r + 1 ; result[r] = zero
--                                     r = r + 1 ; result[r] = zero
--                                     r = r + 1 ; result[r] = res3
--                                     r = r + 1 ; result[r] = res2
--                                     r = r + 1 ; result[r] = res1
--                                     r = r + 1 ; result[r] = res0
                                    n = 1
                                else
                                    n = n + 1
                                end
                                r = r + 1 ; result[r] = encode[stack[i]]
                            end
                        else
                            for i=1,top do
                                r = r + 1 ; result[r] = encode[stack[i]]
                            end
                        end
                        top = 0
                    end
                    r = r + 1 ; result[r] = chars[t]
                    i = i + 1
                end
            else
                local a = actions[t]
                if a then
                    local s = a(t)
                    if s then
                        i = i + s + 1
                    else
                        i = i + 1
                    end
                else
                    if trace_charstrings then
                        showstate(reverse[t] or "<action>")
                    end
                    top = 0
                    i = i + 1
                end
            end
        end
    end

 -- local function calculatebounds(segments,x,y)
 --     local nofsegments = #segments
 --     if nofsegments == 0 then
 --         return { x, y, x, y }
 --     else
 --         local xmin =  10000
 --         local xmax = -10000
 --         local ymin =  10000
 --         local ymax = -10000
 --         if x < xmin then xmin = x end
 --         if x > xmax then xmax = x end
 --         if y < ymin then ymin = y end
 --         if y > ymax then ymax = y end
 --         -- we now have a reasonable start so we could
 --         -- simplify the next checks
 --         for i=1,nofsegments do
 --             local s = segments[i]
 --             local x = s[1]
 --             local y = s[2]
 --             if x < xmin then xmin = x end
 --             if x > xmax then xmax = x end
 --             if y < ymin then ymin = y end
 --             if y > ymax then ymax = y end
 --             if s[#s] == "c" then -- "curveto"
 --                 local x = s[3]
 --                 local y = s[4]
 --                 if x < xmin then xmin = x elseif x > xmax then xmax = x end
 --                 if y < ymin then ymin = y elseif y > ymax then ymax = y end
 --                 local x = s[5]
 --                 local y = s[6]
 --                 if x < xmin then xmin = x elseif x > xmax then xmax = x end
 --                 if y < ymin then ymin = y elseif y > ymax then ymax = y end
 --             end
 --         end
 --         return { round(xmin), round(ymin), round(xmax), round(ymax) } -- doesn't make ceil more sense
 --     end
 -- end

    local function setbias(globals,locals,nobias)
        if nobias then
            return 0, 0
        else
            local g = #globals
            local l = #locals
            return
                ((g < 1240 and 107) or (g < 33900 and 1131) or 32768) + 1,
                ((l < 1240 and 107) or (l < 33900 and 1131) or 32768) + 1
        end
    end

    local function processshape(glyphs,tab,index,hack)

        if not tab then
            glyphs[index] = {
                boundingbox = { 0, 0, 0, 0 },
                width       = 0,
                name        = charset and charset[index] or nil,
            }
            return
        end

        tab     = bytetable(tab)

        x       = 0
        y       = 0
        width   = false
        lsb     = 0
        r       = 0
        top     = 0
        stems   = 0
        result  = { } -- we could reuse it when only boundingbox calculations are needed
        popped  = 3
        procidx = index

        xmin    = 0
        xmax    = 0
        ymin    = 0
        ymax    = 0
        checked = false
        if trace_charstrings then
            report("glyph: %i",index)
            report("data : % t",tab)
        end

        if regions then
            updateregions(vsindex)
        end

        process(tab)
        if hack then
            return x, y
        end

        local boundingbox = {
            round(xmin),
            round(ymin),
            round(xmax),
            round(ymax),
        }

        if width == true or width == false then
            width = defaultwidth
        else
            width = nominalwidth + width
        end

        local glyph = glyphs[index] -- can be autodefined in otr
        if justpass then
            r = r + 1
            result[r] = c_endchar
            local stream = concat(result)
result = nil
         -- if trace_charstrings then
         --     report("vdata: %s",stream)
         -- end
            if glyph then
                glyph.stream = stream
                glyph.width  = width
            else
                glyphs[index] = { stream = stream, width = width }
            end
        elseif glyph then
            glyph.segments    = keepcurve ~= false and result or nil
            glyph.boundingbox = boundingbox
            if not glyph.width then
                glyph.width = width
            end
            if charset and not glyph.name then
                glyph.name = charset[index]
            end
         -- glyph.sidebearing = 0 -- todo
        elseif keepcurve then
            glyphs[index] = {
                segments    = result,
                boundingbox = boundingbox,
                width       = width,
                name        = charset and charset[index] or nil,
             -- sidebearing = 0,
            }
result = nil
        else
            glyphs[index] = {
                boundingbox = boundingbox,
                width       = width,
                name        = charset and charset[index] or nil,
            }
        end
        if trace_charstrings then
            report("width      : %s",tostring(width))
            report("boundingbox: % t",boundingbox)
        end

    end

    startparsing = function(fontdata,data,streams)
        reginit  = false
        axis     = false
        regions  = data.regions
        justpass = streams == true
        popped   = 3
        seacs    = { }
        if regions then
            -- this was:
         -- regions = { regions } -- needs checking
            -- and is now (MFC):
            regions = { }
            local deltas = data.deltas
            for i = 1, #deltas do
                regions[i] = deltas[i].regions
            end
            axis = data.factors or false
        end
    end

    stopparsing = function(fontdata,data)
        stack   = { }
        glyphs  = false
        result  = { }
        top     = 0
        locals  = false
        globals = false
        strings = false
        popped  = 3
        seacs   = { }
    end

    local function setwidths(private)
        if not private then
            return 0, 0
        end
        local privatedata  = private.data
        if not privatedata then
            return 0, 0
        end
        return privatedata.nominalwidthx or 0, privatedata.defaultwidthx or 0
    end

    parsecharstrings = function(fontdata,data,glphs,doshapes,tversion,streams,nobias,istypeone)

        local dictionary  = data.dictionaries[1]
        local charstrings = dictionary.charstrings

        keepcurve = doshapes
        version   = tversion
        typeone   = istypeone or false
        strings   = data.strings
        globals   = data.routines or { }
        locals    = dictionary.subroutines or { }
        charset   = dictionary.charset
        vsindex   = dictionary.vsindex or 0

        local glyphs = glphs or { }

        globalbias,   localbias    = setbias(globals,locals,nobias)
        nominalwidth, defaultwidth = setwidths(dictionary.private)

        if charstrings then
            startparsing(fontdata,data,streams)
            for index=1,#charstrings do
                processshape(glyphs,charstrings[index],index-1)
            end
            if justpass and next(seacs) then
                -- old type 1 stuff ... seacs
                local charset = data.dictionaries[1].charset
                if charset then
                    local lookup = table.swapped(charset)
                    for index, v in next, seacs do
                        local bindex = lookup[standardnames[v.base]]
                        local aindex = lookup[standardnames[v.accent]]
                        local bglyph = bindex and glyphs[bindex]
                        local aglyph = aindex and glyphs[aindex]
                        if bglyph and aglyph then
                            -- this is a real ugly hack but we seldom enter this branch (e.g. old lbr)
                            local jp = justpass
                            justpass = false
                            local x, y = processshape(glyphs,charstrings[bindex+1],bindex,true)
                            justpass = jp
                            --
                            local base   = bglyph.stream
                            local accent = aglyph.stream
                            local moveto = encode[-x-v.asb+v.adx] .. chars[22]
                                        .. encode[-y      +v.ady] .. chars[ 4]
                            -- prune an endchar
                            base = sub(base,1,#base-1)
                            -- combine them
                            glyphs[index].stream = base .. moveto .. accent
                        end
                    end
                end
            end
            stopparsing(fontdata,data)
        else
            report("no charstrings")
        end
        return glyphs
    end

    parsecharstring = function(fontdata,data,dictionary,tab,glphs,index,doshapes,tversion,streams)

        keepcurve = doshapes
        version   = tversion
        strings   = data.strings
        globals   = data.routines or { }
        locals    = dictionary.subroutines or { }
        charset   = false
        vsindex   = dictionary.vsindex or 0

        local glyphs = glphs or { }

        justpass = streams == true
        seacs    = { }

        globalbias,   localbias    = setbias(globals,locals,nobias)
        nominalwidth, defaultwidth = setwidths(dictionary.private)

        processshape(glyphs,tab,index-1)

        return glyphs[index]
    end

end

local function readglobals(f,data,version)
    local routines = readlengths(f,version == "cff2")
    for i=1,#routines do
        routines[i] = readbytetable(f,routines[i])
    end
    data.routines = routines
end

local function readencodings(f,data)
    data.encodings = { }
end

local function readcharsets(f,data,dictionary)
    local header        = data.header
    local strings       = data.strings
    local nofglyphs     = data.nofglyphs
    local charsetoffset = dictionary.charset
    if charsetoffset and charsetoffset ~= 0 then
        setposition(f,header.offset+charsetoffset)
        local format       = readbyte(f)
        local charset      = { [0] = ".notdef" }
        dictionary.charset = charset
        if format == 0 then
            for i=1,nofglyphs do
                charset[i] = strings[readushort(f)]
            end
        elseif format == 1 or format == 2 then
            local readcount = format == 1 and readbyte or readushort
            local i = 1
            while i <= nofglyphs do
                local sid = readushort(f)
                local n   = readcount(f)
                for s=sid,sid+n do
                    charset[i] = strings[s]
                    i = i + 1
                    if i > nofglyphs then
                        break
                    end
                end
            end
        else
            report("cff parser: unsupported charset format %a",format)
        end
    else
        dictionary.nocharset = true
        dictionary.charset   = nil
    end
end

local function readprivates(f,data)
    local header       = data.header
    local dictionaries = data.dictionaries
    local private      = dictionaries[1].private
    if private then
        setposition(f,header.offset+private.offset)
        private.data = readstring(f,private.size)
    end
end

local function readlocals(f,data,dictionary,version)
    local header  = data.header
    local private = dictionary.private
    if private then
        local subroutineoffset = private.data.subroutines
        if subroutineoffset ~= 0 then
            setposition(f,header.offset+private.offset+subroutineoffset)
            local subroutines = readlengths(f,version == "cff2")
            for i=1,#subroutines do
                subroutines[i] = readbytetable(f,subroutines[i])
            end
            dictionary.subroutines = subroutines
            private.data.subroutines = nil
        else
            dictionary.subroutines = { }
        end
    else
        dictionary.subroutines = { }
    end
end

-- These charstrings are little programs and described in: Technical Note #5177. A truetype
-- font has only one dictionary.

local function readcharstrings(f,data,version)
    local header       = data.header
    local dictionaries = data.dictionaries
    local dictionary   = dictionaries[1]
    local stringtype   = dictionary.charstringtype
    local offset       = dictionary.charstrings
    if type(offset) ~= "number" then
        -- weird
    elseif stringtype == 2 then
        setposition(f,header.offset+offset)
        -- could be a metatable .. delayed loading
        local charstrings = readlengths(f,version=="cff2")
        local nofglyphs   = #charstrings
        for i=1,nofglyphs do
            charstrings[i] = readstring(f,charstrings[i])
        end
        data.nofglyphs         = nofglyphs
        dictionary.charstrings = charstrings
    else
        report("unsupported charstr type %i",stringtype)
        data.nofglyphs         = 0
        dictionary.charstrings = { }
    end
end

-- cid (maybe do this stepwise so less mem) -- share with above

local function readcidprivates(f,data)
    local header       = data.header
    local dictionaries = data.dictionaries[1].cid.dictionaries
    for i=1,#dictionaries do
        local dictionary = dictionaries[i]
        local private    = dictionary.private
        if private then
            setposition(f,header.offset+private.offset)
            private.data = readstring(f,private.size)
        end
    end
    parseprivates(data,dictionaries)
end

readers.parsecharstrings = parsecharstrings -- used in font-onr.lua (type 1)

local function readnoselect(f,fontdata,data,glyphs,doshapes,version,streams)
    local dictionaries = data.dictionaries
    local dictionary   = dictionaries[1]
    local cid          = not dictionary.private and dictionary.cid
    readglobals(f,data,version)
    readcharstrings(f,data,version)
    if version == "cff2" then
        dictionary.charset = nil
    else
        readencodings(f,data)
        readcharsets(f,data,dictionary)
    end
    if cid then
        local fdarray = cid.fdarray
        if fdarray then
            setposition(f,data.header.offset + fdarray)
            local dictionaries    = readlengths(f,version=="cff2")
            local nofdictionaries = #dictionaries
            if nofdictionaries > 0 then
                for i=1,nofdictionaries do
                    dictionaries[i] = readstring(f,dictionaries[i])
                end
                parsedictionaries(data,dictionaries)
                dictionary.private = dictionaries[1].private
                if nofdictionaries > 1 then
                    report("ignoring dictionaries > 1 in cid font")
                end
            end
        end
    end
    readprivates(f,data)
    parseprivates(data,data.dictionaries)
    readlocals(f,data,dictionary,version)
    startparsing(fontdata,data,streams)
    parsecharstrings(fontdata,data,glyphs,doshapes,version,streams,false)
    stopparsing(fontdata,data)
end

local function readfdselect(f,fontdata,data,glyphs,doshapes,version,streams)
    local header       = data.header
    local dictionaries = data.dictionaries
    local dictionary   = dictionaries[1]
    local cid          = dictionary.cid
    local cidselect    = cid and cid.fdselect
    readglobals(f,data,version)
    readcharstrings(f,data,version)
    if version ~= "cff2" then
        readencodings(f,data)
    end
    local charstrings  = dictionary.charstrings
    local fdindex      = { }
    local nofglyphs    = data.nofglyphs
    local maxindex     = -1
    setposition(f,header.offset+cidselect)
    local format       = readbyte(f)
    if format == 1 then
        for i=0,nofglyphs do -- notdef included (needs checking)
            local index = readbyte(f)
            fdindex[i] = index
            if index > maxindex then
                maxindex = index
            end
        end
    elseif format == 3 then
        local nofranges = readushort(f)
        local first     = readushort(f)
        local index     = readbyte(f)
        while true do
            local last = readushort(f)
            if index > maxindex then
                maxindex = index
            end
            for i=first,last do
                fdindex[i] = index
            end
            if last >= nofglyphs then
                break
            else
                first = last + 1
                index = readbyte(f)
            end
        end
    else
        report("unsupported fd index format %i",format)
    end
    -- hm, always
    if maxindex >= 0 then
        local cidarray = cid.fdarray
        if cidarray then
            setposition(f,header.offset+cidarray)
            local dictionaries = readlengths(f,version == "cff2")
            if #dictionaries > 0 then
                for i=1,#dictionaries do
                    dictionaries[i] = readstring(f,dictionaries[i])
                end
                parsedictionaries(data,dictionaries)
                cid.dictionaries = dictionaries
                readcidprivates(f,data)
                for i=1,#dictionaries do
                    readlocals(f,data,dictionaries[i],version)
                end
                startparsing(fontdata,data,streams)
                for i=1,#charstrings do
                    local dictionary = dictionaries[fdindex[i]+1]
                    if dictionary then
                        parsecharstring(fontdata,data,dictionary,charstrings[i],glyphs,i,doshapes,version,streams)
                    else
                     -- report("no dictionary for %a : %a => %a",version,i,fdindex[i]+1)
                    end
                 -- charstrings[i] = false
                end
                stopparsing(fontdata,data)
            else
                report("no cid dictionaries")
            end
        else
            report("no cid array")
        end
    end
end

local gotodatatable = readers.helpers.gotodatatable

local function cleanup(data,dictionaries)
 -- for i=1,#dictionaries do
 --     local d = dictionaries[i]
 --     d.subroutines = nil
 -- end
 -- data.strings = nil
 -- if data then
 --     data.charstrings  = nil
 --     data.routines     = nil
 -- end
end

function readers.cff(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"cff",specification.details or specification.glyphs)
    if tableoffset then
        local header = readheader(f)
        if header.major ~= 1 then
            report("only version %s is supported for table %a",1,"cff")
            return
        end
        local glyphs       = fontdata.glyphs
        local names        = readfontnames(f)
        local dictionaries = readtopdictionaries(f)
        local strings      = readstrings(f)
        local data = {
            header       = header,
            names        = names,
            dictionaries = dictionaries,
            strings      = strings,
            nofglyphs    = fontdata.nofglyphs,
        }
        --
        parsedictionaries(data,dictionaries,"cff")
        --
        local dic = dictionaries[1]
        local cid = dic.cid
        --
        local cffinfo = {
            familyname         = dic.familyname,
            fullname           = dic.fullname,
            boundingbox        = dic.boundingbox,
            weight             = dic.weight,
            italicangle        = dic.italicangle,
            underlineposition  = dic.underlineposition,
            underlinethickness = dic.underlinethickness,
            defaultwidth       = dic.defaultwidthx,
            nominalwidth       = dic.nominalwidthx,
            monospaced         = dic.monospaced,
        }
        fontdata.cidinfo = cid and {
            registry   = cid.registry,
            ordering   = cid.ordering,
            supplement = cid.supplement,
        }
        fontdata.cffinfo = cffinfo
        --
        local all = specification.shapes or specification.streams or false
        if specification.glyphs or all then
            if cid and cid.fdselect then
                readfdselect(f,fontdata,data,glyphs,all,"cff",specification.streams)
            else
                readnoselect(f,fontdata,data,glyphs,all,"cff",specification.streams)
            end
        end
        local private = dic.private
        if private then
            local data = private.data
            if type(data) == "table" then
                cffinfo.defaultwidth     = data.defaultwidthx or cffinfo.defaultwidth
                cffinfo.nominalwidth     = data.nominalwidthx or cffinfo.nominalwidth
                cffinfo.bluevalues       = data.bluevalues
                cffinfo.otherblues       = data.otherblues
                cffinfo.familyblues      = data.familyblues
                cffinfo.familyotherblues = data.familyotherblues
                cffinfo.bluescale        = data.bluescale
                cffinfo.blueshift        = data.blueshift
                cffinfo.bluefuzz         = data.bluefuzz
                cffinfo.stdhw            = data.stdhw
                cffinfo.stdvw            = data.stdvw
                cffinfo.stemsnaph        = data.stemsnaph
                cffinfo.stemsnapv        = data.stemsnapv
            end
        end
        cleanup(data,dictionaries)
    end
end

function readers.cff2(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"cff2",specification.glyphs)
    if tableoffset then
        local header = readheader(f)
        if header.major ~= 2 then
            report("only version %s is supported for table %a",2,"cff2")
            return
        end
        local glyphs       = fontdata.glyphs
        local dictionaries = { readstring(f,header.dsize) }
        local data = {
            header       = header,
            dictionaries = dictionaries,
            nofglyphs    = fontdata.nofglyphs,
        }
        --
        parsedictionaries(data,dictionaries,"cff2")
        --
        local offset = dictionaries[1].vstore
        if offset > 0 then
            local storeoffset = dictionaries[1].vstore + data.header.offset + 2 -- cff has a preceding size field
            local regions, deltas = readers.helpers.readvariationdata(f,storeoffset,factors)
            --
            data.regions  = regions
            data.deltas   = deltas
        else
            data.regions  = { }
            data.deltas   = { }
        end
        data.factors  = specification.factors
        --
        local cid = data.dictionaries[1].cid
        local all = specification.shapes or specification.streams or false
        if cid and cid.fdselect then
            readfdselect(f,fontdata,data,glyphs,all,"cff2",specification.streams)
        else
            readnoselect(f,fontdata,data,glyphs,all,"cff2",specification.streams)
        end
        cleanup(data,dictionaries)
    end
end

-- temporary helper needed for checking backend patches

-- function readers.cffcheck(filename)
--     local f = io.open(filename,"rb")
--     if f then
--         local fontdata = {
--             glyphs = { },
--         }
--         local header = readheader(f)
--         if header.major ~= 1 then
--             report("only version %s is supported for table %a",1,"cff")
--             return
--         end
--         local names        = readfontnames(f)
--         local dictionaries = readtopdictionaries(f)
--         local strings      = readstrings(f)
--         local glyphs       = { }
--         local data = {
--             header       = header,
--             names        = names,
--             dictionaries = dictionaries,
--             strings      = strings,
--             glyphs       = glyphs,
--             nofglyphs    = 0,
--         }
--         --
--         parsedictionaries(data,dictionaries,"cff")
--         --
--         local cid = data.dictionaries[1].cid
--         if cid and cid.fdselect then
--             readfdselect(f,fontdata,data,glyphs,false)
--         else
--             readnoselect(f,fontdata,data,glyphs,false)
--         end
--         return data
--     end
-- end
