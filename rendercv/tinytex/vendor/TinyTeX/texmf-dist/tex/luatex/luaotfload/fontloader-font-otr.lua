if not modules then modules = { } end modules ['font-otr'] = {
    version   = 1.001,
    optimize  = true,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- When looking into a cid font relates issue in the ff library I wondered if
-- it made sense to use Lua to filter the information from the otf and ttf
-- files. Quite some ff code relates to special fonts and in practice we only
-- use rather normal opentype fonts.
--
-- The code here is based on the documentation (and examples) at the microsoft
-- website. The code will be extended and improved stepwise. After some experiments
-- I decided to convert to a format more suitable for the context font handler
-- because it makes no sense to rehash all those lookups again.
--
-- Currently we can use this code for getting basic info about the font, loading
-- shapes and loading the extensive table. I'm not sure if I will provide a ff
-- compatible output as well (We're not that far from it as currently I can load
-- all data reasonable fast.)

-- We can omit redundant glyphs names i.e. ones that match the agl or
-- are just a unicode string but it doesn't save that much. It will be an option
-- some day.

-- Optimizing the widths will be done anyway as it save quite some on a cjk font
-- and the existing (old) code if okay.

-- todo: more messages (only if really needed)
--
-- considered, in math:
--
-- start -> first (so we can skip the first same-size one)
-- end   -> last
--
-- Widths and weights are kind of messy: for instance lmmonolt has a pfmweight of
-- 400 while it should be 300. So, for now we mostly stick to the old compromis.

-- We don't really need all those language tables so they might be dropped some
-- day.

-- The new reader is faster on some aspects and slower on other. The memory footprint
-- is lower. The string reader is a  bit faster than the file reader. The new reader
-- gives more efficient tables and has bit more analysis. In practice these times are
-- not that relevant because we cache. The otf files take a it more time because we
-- need to calculate the boundingboxes. In theory the processing of text should be
-- somewhat faster especially for complex fonts with many lookups.
--
--                        old    new    str reader
-- lmroman12-regular.otf  0.103  0.203  0.195
-- latinmodern-math.otf   0.454  0.768  0.712
-- husayni.ttf            1.142  1.526  1.259
--
-- If there is demand I will consider making a ff compatible table dumper but it's
-- probably more fun to provide a way to show features applied.

-- I experimented a bit with f:readbyte(n) and f:readshort() and so and it is indeed
-- faster but it might not be the real bottleneck as we still need to juggle data. It
-- is probably more memory efficient as no intermediate strings are involved.

-- if not characters then
--     require("char-def")
--     require("char-ini")
-- end

local number = number
local next, type, tonumber, rawget = next, type, tonumber, rawget
local byte, lower, char, gsub = string.byte, string.lower, string.char, string.gsub
local fullstrip = string.fullstrip
local floor, round = math.floor, math.round
local P, R, S, C, Cs, Cc, Ct, Carg, Cmt = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.Cs, lpeg.Cc, lpeg.Ct, lpeg.Carg, lpeg.Cmt
local lpegmatch = lpeg.match
local rshift = bit32.rshift

local setmetatableindex  = table.setmetatableindex
local sortedkeys         = table.sortedkeys
local sortedhash         = table.sortedhash
local stripstring        = string.nospaces
local utf16_to_utf8_be   = utf.utf16_to_utf8_be

local report             = logs.reporter("otf reader")
local report_cmap        = logs.reporter("otf reader","cmap")

local trace_cmap         = false  trackers.register("otf.cmap",         function(v) trace_cmap         = v end)
local trace_cmap_details = false  trackers.register("otf.cmap.details", function(v) trace_cmap_details = v end)

fonts                    = fonts or { }
local handlers           = fonts.handlers or { }
fonts.handlers           = handlers
local otf                = handlers.otf or { }
handlers.otf             = otf
local readers            = otf.readers or { }
otf.readers              = readers

----- streamreader       = utilities.streams -- faster on big files (not true any longer)
local streamreader       = utilities.files   -- faster on identify (also uses less memory)
local streamwriter       = utilities.files

readers.streamreader     = streamreader
readers.streamwriter     = streamwriter

local openfile           = streamreader.open
local closefile          = streamreader.close
----- skipbytes          = streamreader.skip
local setposition        = streamreader.setposition
local skipshort          = streamreader.skipshort
local readbytes          = streamreader.readbytes
local readstring         = streamreader.readstring
local readbyte           = streamreader.readcardinal1  --  8-bit unsigned integer
local readushort         = streamreader.readcardinal2  -- 16-bit unsigned integer
local readuint           = streamreader.readcardinal3  -- 24-bit unsigned integer
local readulong          = streamreader.readcardinal4  -- 32-bit unsigned integer
----- readchar           = streamreader.readinteger1   --  8-bit   signed integer
local readshort          = streamreader.readinteger2   -- 16-bit   signed integer
local readlong           = streamreader.readinteger4   -- 32-bit unsigned integer
local readfixed          = streamreader.readfixed4
local read2dot14         = streamreader.read2dot14     -- 16-bit signed fixed number with the low 14 bits of fraction (2.14) (F2DOT14)
local readfword          = readshort                   -- 16-bit   signed integer that describes a quantity in FUnits
local readufword         = readushort                  -- 16-bit unsigned integer that describes a quantity in FUnits
local readoffset         = readushort
local readcardinaltable  = streamreader.readcardinaltable
local readintegertable   = streamreader.readintegertable

function streamreader.readtag(f)
    return lower(stripstring(readstring(f,4)))
end

local short  = 2
local ushort = 2
local ulong  = 4

directives.register("fonts.streamreader",function()

    streamreader      = utilities.streams

    openfile          = streamreader.open
    closefile         = streamreader.close
    setposition       = streamreader.setposition
    skipshort         = streamreader.skipshort
    readbytes         = streamreader.readbytes
    readstring        = streamreader.readstring
    readbyte          = streamreader.readcardinal1
    readushort        = streamreader.readcardinal2
    readuint          = streamreader.readcardinal3
    readulong         = streamreader.readcardinal4
    readshort         = streamreader.readinteger2
    readlong          = streamreader.readinteger4
    readfixed         = streamreader.readfixed4
    read2dot14        = streamreader.read2dot14
    readfword         = readshort
    readufword        = readushort
    readoffset        = readushort
    readcardinaltable = streamreader.readcardinaltable
    readintegertable  = streamreader.readintegertable

    function streamreader.readtag(f)
        return lower(stripstring(readstring(f,4)))
    end

end)

-- date represented in number of seconds since 12:00 midnight, January 1, 1904. The value is represented as a
-- signed 64-bit integer

local function readlongdatetime(f)
    local a, b, c, d, e, f, g, h = readbytes(f,8)
    return 0x100000000 * d + 0x1000000 * e + 0x10000 * f + 0x100 * g + h
end

local tableversion    = 0.004
readers.tableversion  = tableversion
local privateoffset   = fonts.constructors and fonts.constructors.privateoffset or 0xF0000 -- 0x10FFFF

-- We have quite some data tables. We are somewhat ff compatible with names but as I used
-- the information from the microsoft site there can be differences. Eventually I might end
-- up with a different ordering and naming.

local reservednames = { [0] =
    "copyright",
    "family",
    "subfamily",
    "uniqueid",
    "fullname",
    "version",
    "postscriptname",
    "trademark",
    "manufacturer",
    "designer",
    "description", -- descriptor in ff
    "vendorurl",
    "designerurl",
    "license",
    "licenseurl",
    "reserved",
    "typographicfamily",    -- preffamilyname
    "typographicsubfamily", -- prefmodifiers
    "compatiblefullname",   -- for mac
    "sampletext",
    "cidfindfontname",
    "wwsfamily",
    "wwssubfamily",
    "lightbackgroundpalette",
    "darkbackgroundpalette",
    "variationspostscriptnameprefix",
}

-- more at: https://www.microsoft.com/typography/otspec/name.htm

-- setmetatableindex(reservednames,function(t,k)
--     local v = "name_" .. k
--     t[k] =  v
--     return v
-- end)

local platforms = { [0] =
    "unicode",
    "macintosh",
    "iso",
    "windows",
    "custom",
}

local encodings = {
    -- these stay:
    unicode = { [0] =
        "unicode 1.0 semantics",
        "unicode 1.1 semantics",
        "iso/iec 10646",
        "unicode 2.0 bmp",             -- cmap subtable formats 0, 4, 6
        "unicode 2.0 full",            -- cmap subtable formats 0, 4, 6, 10, 12
        "unicode variation sequences", -- cmap subtable format 14).
        "unicode full repertoire",     -- cmap subtable formats 0, 4, 6, 10, 12, 13
    },
    -- these can go:
    macintosh = { [0] =
        "roman", "japanese", "chinese (traditional)", "korean", "arabic", "hebrew", "greek", "russian",
        "rsymbol", "devanagari", "gurmukhi", "gujarati", "oriya", "bengali", "tamil", "telugu", "kannada",
        "malayalam", "sinhalese", "burmese", "khmer", "thai", "laotian", "georgian", "armenian",
        "chinese (simplified)", "tibetan", "mongolian", "geez", "slavic", "vietnamese", "sindhi",
        "uninterpreted",
    },
    -- these stay:
    iso = { [0] =
        "7-bit ascii",
        "iso 10646",
        "iso 8859-1",
    },
    -- these stay:
    windows = { [0] =
        "symbol",
        "unicode bmp", -- this is utf16
        "shiftjis",
        "prc",
        "big5",
        "wansung",
        "johab",
        "reserved 7",
        "reserved 8",
        "reserved 9",
        "unicode ucs-4",
    },
    custom = {
        --custom: 0-255 : otf windows nt compatibility mapping
    }
}

local decoders = {
    unicode   = { },
    macintosh = { },
    iso       = { },
    windows   = {
        -- maybe always utf16
        ["unicode semantics"]           = utf16_to_utf8_be,
        ["unicode bmp"]                 = utf16_to_utf8_be,
        ["unicode full"]                = utf16_to_utf8_be,
        ["unicode 1.0 semantics"]       = utf16_to_utf8_be,
        ["unicode 1.1 semantics"]       = utf16_to_utf8_be,
        ["unicode 2.0 bmp"]             = utf16_to_utf8_be,
        ["unicode 2.0 full"]            = utf16_to_utf8_be,
        ["unicode variation sequences"] = utf16_to_utf8_be,
        ["unicode full repertoire"]     = utf16_to_utf8_be,
    },
    custom    = { },
}

-- This is bit over the top as we can just look for either windows, unicode or macintosh
-- names (in that order). A font with no english name is probably a weird one anyway.

local languages = {
    -- these stay:
    unicode = {
        [  0] = "english",
    },
    -- english can stay:
    macintosh = {
        [  0] = "english",
     -- [  1] = "french",
     -- [  2] = "german",
     -- [  3] = "italian",
     -- [  4] = "dutch",
     -- [  5] = "swedish",
     -- [  6] = "spanish",
     -- [  7] = "danish",
     -- [  8] = "portuguese",
     -- [  9] = "norwegian",
     -- [ 10] = "hebrew",
     -- [ 11] = "japanese",
     -- [ 12] = "arabic",
     -- [ 13] = "finnish",
     -- [ 14] = "greek",
     -- [ 15] = "icelandic",
     -- [ 16] = "maltese",
     -- [ 17] = "turkish",
     -- [ 18] = "croatian",
     -- [ 19] = "chinese (traditional)",
     -- [ 20] = "urdu",
     -- [ 21] = "hindi",
     -- [ 22] = "thai",
     -- [ 23] = "korean",
     -- [ 24] = "lithuanian",
     -- [ 25] = "polish",
     -- [ 26] = "hungarian",
     -- [ 27] = "estonian",
     -- [ 28] = "latvian",
     -- [ 29] = "sami",
     -- [ 30] = "faroese",
     -- [ 31] = "farsi/persian",
     -- [ 32] = "russian",
     -- [ 33] = "chinese (simplified)",
     -- [ 34] = "flemish",
     -- [ 35] = "irish gaelic",
     -- [ 36] = "albanian",
     -- [ 37] = "romanian",
     -- [ 38] = "czech",
     -- [ 39] = "slovak",
     -- [ 40] = "slovenian",
     -- [ 41] = "yiddish",
     -- [ 42] = "serbian",
     -- [ 43] = "macedonian",
     -- [ 44] = "bulgarian",
     -- [ 45] = "ukrainian",
     -- [ 46] = "byelorussian",
     -- [ 47] = "uzbek",
     -- [ 48] = "kazakh",
     -- [ 49] = "azerbaijani (cyrillic script)",
     -- [ 50] = "azerbaijani (arabic script)",
     -- [ 51] = "armenian",
     -- [ 52] = "georgian",
     -- [ 53] = "moldavian",
     -- [ 54] = "kirghiz",
     -- [ 55] = "tajiki",
     -- [ 56] = "turkmen",
     -- [ 57] = "mongolian (mongolian script)",
     -- [ 58] = "mongolian (cyrillic script)",
     -- [ 59] = "pashto",
     -- [ 60] = "kurdish",
     -- [ 61] = "kashmiri",
     -- [ 62] = "sindhi",
     -- [ 63] = "tibetan",
     -- [ 64] = "nepali",
     -- [ 65] = "sanskrit",
     -- [ 66] = "marathi",
     -- [ 67] = "bengali",
     -- [ 68] = "assamese",
     -- [ 69] = "gujarati",
     -- [ 70] = "punjabi",
     -- [ 71] = "oriya",
     -- [ 72] = "malayalam",
     -- [ 73] = "kannada",
     -- [ 74] = "tamil",
     -- [ 75] = "telugu",
     -- [ 76] = "sinhalese",
     -- [ 77] = "burmese",
     -- [ 78] = "khmer",
     -- [ 79] = "lao",
     -- [ 80] = "vietnamese",
     -- [ 81] = "indonesian",
     -- [ 82] = "tagalong",
     -- [ 83] = "malay (roman script)",
     -- [ 84] = "malay (arabic script)",
     -- [ 85] = "amharic",
     -- [ 86] = "tigrinya",
     -- [ 87] = "galla",
     -- [ 88] = "somali",
     -- [ 89] = "swahili",
     -- [ 90] = "kinyarwanda/ruanda",
     -- [ 91] = "rundi",
     -- [ 92] = "nyanja/chewa",
     -- [ 93] = "malagasy",
     -- [ 94] = "esperanto",
     -- [128] = "welsh",
     -- [129] = "basque",
     -- [130] = "catalan",
     -- [131] = "latin",
     -- [132] = "quenchua",
     -- [133] = "guarani",
     -- [134] = "aymara",
     -- [135] = "tatar",
     -- [136] = "uighur",
     -- [137] = "dzongkha",
     -- [138] = "javanese (roman script)",
     -- [139] = "sundanese (roman script)",
     -- [140] = "galician",
     -- [141] = "afrikaans",
     -- [142] = "breton",
     -- [143] = "inuktitut",
     -- [144] = "scottish gaelic",
     -- [145] = "manx gaelic",
     -- [146] = "irish gaelic (with dot above)",
     -- [147] = "tongan",
     -- [148] = "greek (polytonic)",
     -- [149] = "greenlandic",
     -- [150] = "azerbaijani (roman script)",
    },
    -- these can stay:
    iso = {
    },
    -- english can stay:
    windows = {
     -- [0x0436] = "afrikaans - south africa",
     -- [0x041c] = "albanian - albania",
     -- [0x0484] = "alsatian - france",
     -- [0x045e] = "amharic - ethiopia",
     -- [0x1401] = "arabic - algeria",
     -- [0x3c01] = "arabic - bahrain",
     -- [0x0c01] = "arabic - egypt",
     -- [0x0801] = "arabic - iraq",
     -- [0x2c01] = "arabic - jordan",
     -- [0x3401] = "arabic - kuwait",
     -- [0x3001] = "arabic - lebanon",
     -- [0x1001] = "arabic - libya",
     -- [0x1801] = "arabic - morocco",
     -- [0x2001] = "arabic - oman",
     -- [0x4001] = "arabic - qatar",
     -- [0x0401] = "arabic - saudi arabia",
     -- [0x2801] = "arabic - syria",
     -- [0x1c01] = "arabic - tunisia",
     -- [0x3801] = "arabic - u.a.e.",
     -- [0x2401] = "arabic - yemen",
     -- [0x042b] = "armenian - armenia",
     -- [0x044d] = "assamese - india",
     -- [0x082c] = "azeri (cyrillic) - azerbaijan",
     -- [0x042c] = "azeri (latin) - azerbaijan",
     -- [0x046d] = "bashkir - russia",
     -- [0x042d] = "basque - basque",
     -- [0x0423] = "belarusian - belarus",
     -- [0x0845] = "bengali - bangladesh",
     -- [0x0445] = "bengali - india",
     -- [0x201a] = "bosnian (cyrillic) - bosnia and herzegovina",
     -- [0x141a] = "bosnian (latin) - bosnia and herzegovina",
     -- [0x047e] = "breton - france",
     -- [0x0402] = "bulgarian - bulgaria",
     -- [0x0403] = "catalan - catalan",
     -- [0x0c04] = "chinese - hong kong s.a.r.",
     -- [0x1404] = "chinese - macao s.a.r.",
     -- [0x0804] = "chinese - people's republic of china",
     -- [0x1004] = "chinese - singapore",
     -- [0x0404] = "chinese - taiwan",
     -- [0x0483] = "corsican - france",
     -- [0x041a] = "croatian - croatia",
     -- [0x101a] = "croatian (latin) - bosnia and herzegovina",
     -- [0x0405] = "czech - czech republic",
     -- [0x0406] = "danish - denmark",
     -- [0x048c] = "dari - afghanistan",
     -- [0x0465] = "divehi - maldives",
     -- [0x0813] = "dutch - belgium",
     -- [0x0413] = "dutch - netherlands",
     -- [0x0c09] = "english - australia",
     -- [0x2809] = "english - belize",
     -- [0x1009] = "english - canada",
     -- [0x2409] = "english - caribbean",
     -- [0x4009] = "english - india",
     -- [0x1809] = "english - ireland",
     -- [0x2009] = "english - jamaica",
     -- [0x4409] = "english - malaysia",
     -- [0x1409] = "english - new zealand",
     -- [0x3409] = "english - republic of the philippines",
     -- [0x4809] = "english - singapore",
     -- [0x1c09] = "english - south africa",
     -- [0x2c09] = "english - trinidad and tobago",
     -- [0x0809] = "english - united kingdom",
        [0x0409] = "english - united states",
     -- [0x3009] = "english - zimbabwe",
     -- [0x0425] = "estonian - estonia",
     -- [0x0438] = "faroese - faroe islands",
     -- [0x0464] = "filipino - philippines",
     -- [0x040b] = "finnish - finland",
     -- [0x080c] = "french - belgium",
     -- [0x0c0c] = "french - canada",
     -- [0x040c] = "french - france",
     -- [0x140c] = "french - luxembourg",
     -- [0x180c] = "french - principality of monoco",
     -- [0x100c] = "french - switzerland",
     -- [0x0462] = "frisian - netherlands",
     -- [0x0456] = "galician - galician",
     -- [0x0437] = "georgian -georgia",
     -- [0x0c07] = "german - austria",
     -- [0x0407] = "german - germany",
     -- [0x1407] = "german - liechtenstein",
     -- [0x1007] = "german - luxembourg",
     -- [0x0807] = "german - switzerland",
     -- [0x0408] = "greek - greece",
     -- [0x046f] = "greenlandic - greenland",
     -- [0x0447] = "gujarati - india",
     -- [0x0468] = "hausa (latin) - nigeria",
     -- [0x040d] = "hebrew - israel",
     -- [0x0439] = "hindi - india",
     -- [0x040e] = "hungarian - hungary",
     -- [0x040f] = "icelandic - iceland",
     -- [0x0470] = "igbo - nigeria",
     -- [0x0421] = "indonesian - indonesia",
     -- [0x045d] = "inuktitut - canada",
     -- [0x085d] = "inuktitut (latin) - canada",
     -- [0x083c] = "irish - ireland",
     -- [0x0434] = "isixhosa - south africa",
     -- [0x0435] = "isizulu - south africa",
     -- [0x0410] = "italian - italy",
     -- [0x0810] = "italian - switzerland",
     -- [0x0411] = "japanese - japan",
     -- [0x044b] = "kannada - india",
     -- [0x043f] = "kazakh - kazakhstan",
     -- [0x0453] = "khmer - cambodia",
     -- [0x0486] = "k'iche - guatemala",
     -- [0x0487] = "kinyarwanda - rwanda",
     -- [0x0441] = "kiswahili - kenya",
     -- [0x0457] = "konkani - india",
     -- [0x0412] = "korean - korea",
     -- [0x0440] = "kyrgyz - kyrgyzstan",
     -- [0x0454] = "lao - lao p.d.r.",
     -- [0x0426] = "latvian - latvia",
     -- [0x0427] = "lithuanian - lithuania",
     -- [0x082e] = "lower sorbian - germany",
     -- [0x046e] = "luxembourgish - luxembourg",
     -- [0x042f] = "macedonian (fyrom) - former yugoslav republic of macedonia",
     -- [0x083e] = "malay - brunei darussalam",
     -- [0x043e] = "malay - malaysia",
     -- [0x044c] = "malayalam - india",
     -- [0x043a] = "maltese - malta",
     -- [0x0481] = "maori - new zealand",
     -- [0x047a] = "mapudungun - chile",
     -- [0x044e] = "marathi - india",
     -- [0x047c] = "mohawk - mohawk",
     -- [0x0450] = "mongolian (cyrillic) - mongolia",
     -- [0x0850] = "mongolian (traditional) - people's republic of china",
     -- [0x0461] = "nepali - nepal",
     -- [0x0414] = "norwegian (bokmal) - norway",
     -- [0x0814] = "norwegian (nynorsk) - norway",
     -- [0x0482] = "occitan - france",
     -- [0x0448] = "odia (formerly oriya) - india",
     -- [0x0463] = "pashto - afghanistan",
     -- [0x0415] = "polish - poland",
     -- [0x0416] = "portuguese - brazil",
     -- [0x0816] = "portuguese - portugal",
     -- [0x0446] = "punjabi - india",
     -- [0x046b] = "quechua - bolivia",
     -- [0x086b] = "quechua - ecuador",
     -- [0x0c6b] = "quechua - peru",
     -- [0x0418] = "romanian - romania",
     -- [0x0417] = "romansh - switzerland",
     -- [0x0419] = "russian - russia",
     -- [0x243b] = "sami (inari) - finland",
     -- [0x103b] = "sami (lule) - norway",
     -- [0x143b] = "sami (lule) - sweden",
     -- [0x0c3b] = "sami (northern) - finland",
     -- [0x043b] = "sami (northern) - norway",
     -- [0x083b] = "sami (northern) - sweden",
     -- [0x203b] = "sami (skolt) - finland",
     -- [0x183b] = "sami (southern) - norway",
     -- [0x1c3b] = "sami (southern) - sweden",
     -- [0x044f] = "sanskrit - india",
     -- [0x1c1a] = "serbian (cyrillic) - bosnia and herzegovina",
     -- [0x0c1a] = "serbian (cyrillic) - serbia",
     -- [0x181a] = "serbian (latin) - bosnia and herzegovina",
     -- [0x081a] = "serbian (latin) - serbia",
     -- [0x046c] = "sesotho sa leboa - south africa",
     -- [0x0432] = "setswana - south africa",
     -- [0x045b] = "sinhala - sri lanka",
     -- [0x041b] = "slovak - slovakia",
     -- [0x0424] = "slovenian - slovenia",
     -- [0x2c0a] = "spanish - argentina",
     -- [0x400a] = "spanish - bolivia",
     -- [0x340a] = "spanish - chile",
     -- [0x240a] = "spanish - colombia",
     -- [0x140a] = "spanish - costa rica",
     -- [0x1c0a] = "spanish - dominican republic",
     -- [0x300a] = "spanish - ecuador",
     -- [0x440a] = "spanish - el salvador",
     -- [0x100a] = "spanish - guatemala",
     -- [0x480a] = "spanish - honduras",
     -- [0x080a] = "spanish - mexico",
     -- [0x4c0a] = "spanish - nicaragua",
     -- [0x180a] = "spanish - panama",
     -- [0x3c0a] = "spanish - paraguay",
     -- [0x280a] = "spanish - peru",
     -- [0x500a] = "spanish - puerto rico",
     -- [0x0c0a] = "spanish (modern sort) - spain",
     -- [0x040a] = "spanish (traditional sort) - spain",
     -- [0x540a] = "spanish - united states",
     -- [0x380a] = "spanish - uruguay",
     -- [0x200a] = "spanish - venezuela",
     -- [0x081d] = "sweden - finland",
     -- [0x041d] = "swedish - sweden",
     -- [0x045a] = "syriac - syria",
     -- [0x0428] = "tajik (cyrillic) - tajikistan",
     -- [0x085f] = "tamazight (latin) - algeria",
     -- [0x0449] = "tamil - india",
     -- [0x0444] = "tatar - russia",
     -- [0x044a] = "telugu - india",
     -- [0x041e] = "thai - thailand",
     -- [0x0451] = "tibetan - prc",
     -- [0x041f] = "turkish - turkey",
     -- [0x0442] = "turkmen - turkmenistan",
     -- [0x0480] = "uighur - prc",
     -- [0x0422] = "ukrainian - ukraine",
     -- [0x042e] = "upper sorbian - germany",
     -- [0x0420] = "urdu - islamic republic of pakistan",
     -- [0x0843] = "uzbek (cyrillic) - uzbekistan",
     -- [0x0443] = "uzbek (latin) - uzbekistan",
     -- [0x042a] = "vietnamese - vietnam",
     -- [0x0452] = "welsh - united kingdom",
     -- [0x0488] = "wolof - senegal",
     -- [0x0485] = "yakut - russia",
     -- [0x0478] = "yi - prc",
     -- [0x046a] = "yoruba - nigeria",
    },
    custom = {
    },
}

local standardromanencoding = { [0] = -- taken from wikipedia
    "notdef", ".null", "nonmarkingreturn", "space", "exclam", "quotedbl",
    "numbersign", "dollar", "percent", "ampersand", "quotesingle", "parenleft",
    "parenright", "asterisk", "plus", "comma", "hyphen", "period", "slash",
    "zero", "one", "two", "three", "four", "five", "six", "seven", "eight",
    "nine", "colon", "semicolon", "less", "equal", "greater", "question", "at",
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O",
    "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "bracketleft",
    "backslash", "bracketright", "asciicircum", "underscore", "grave", "a", "b",
    "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q",
    "r", "s", "t", "u", "v", "w", "x", "y", "z", "braceleft", "bar",
    "braceright", "asciitilde", "Adieresis", "Aring", "Ccedilla", "Eacute",
    "Ntilde", "Odieresis", "Udieresis", "aacute", "agrave", "acircumflex",
    "adieresis", "atilde", "aring", "ccedilla", "eacute", "egrave",
    "ecircumflex", "edieresis", "iacute", "igrave", "icircumflex", "idieresis",
    "ntilde", "oacute", "ograve", "ocircumflex", "odieresis", "otilde", "uacute",
    "ugrave", "ucircumflex", "udieresis", "dagger", "degree", "cent", "sterling",
    "section", "bullet", "paragraph", "germandbls", "registered", "copyright",
    "trademark", "acute", "dieresis", "notequal", "AE", "Oslash", "infinity",
    "plusminus", "lessequal", "greaterequal", "yen", "mu", "partialdiff",
    "summation", "product", "pi", "integral", "ordfeminine", "ordmasculine",
    "Omega", "ae", "oslash", "questiondown", "exclamdown", "logicalnot",
    "radical", "florin", "approxequal", "Delta", "guillemotleft",
    "guillemotright", "ellipsis", "nonbreakingspace", "Agrave", "Atilde",
    "Otilde", "OE", "oe", "endash", "emdash", "quotedblleft", "quotedblright",
    "quoteleft", "quoteright", "divide", "lozenge", "ydieresis", "Ydieresis",
    "fraction", "currency", "guilsinglleft", "guilsinglright", "fi", "fl",
    "daggerdbl", "periodcentered", "quotesinglbase", "quotedblbase",
    "perthousand", "Acircumflex", "Ecircumflex", "Aacute", "Edieresis", "Egrave",
    "Iacute", "Icircumflex", "Idieresis", "Igrave", "Oacute", "Ocircumflex",
    "apple", "Ograve", "Uacute", "Ucircumflex", "Ugrave", "dotlessi",
    "circumflex", "tilde", "macron", "breve", "dotaccent", "ring", "cedilla",
    "hungarumlaut", "ogonek", "caron", "Lslash", "lslash", "Scaron", "scaron",
    "Zcaron", "zcaron", "brokenbar", "Eth", "eth", "Yacute", "yacute", "Thorn",
    "thorn", "minus", "multiply", "onesuperior", "twosuperior", "threesuperior",
    "onehalf", "onequarter", "threequarters", "franc", "Gbreve", "gbreve",
    "Idotaccent", "Scedilla", "scedilla", "Cacute", "cacute", "Ccaron", "ccaron",
    "dcroat",
}

local weights = {
    [100] = "thin",
    [200] = "extralight",
    [300] = "light",
    [400] = "normal",
    [500] = "medium",
    [600] = "semibold", -- demi demibold
    [700] = "bold",
    [800] = "extrabold",
    [900] = "black",
}

local widths = {
    "ultracondensed",
    "extracondensed",
    "condensed",
    "semicondensed",
    "normal",
    "semiexpanded",
    "expanded",
    "extraexpanded",
    "ultraexpanded",
}

setmetatableindex(weights, function(t,k)
    local r = floor((k + 50) / 100) * 100
    local v = (r > 900 and "black") or rawget(t,r) or "normal"
    return v
end)

setmetatableindex(widths,function(t,k)
    return "normal"
end)

local panoseweights = { [0] =
    "normal",
    "normal",
    "verylight",
    "light",
    "thin",
    "book",
    "medium",
    "demi",
    "bold",
    "heavy",
    "black",
}

local panosewidths = { [0] =
    "normal",
    "normal",
    "normal",
    "normal",
    "normal",
    "expanded",
    "condensed",
    "veryexpanded",
    "verycondensed",
    "monospaced",
}

-- We implement a reader per table.

-- helper

local helpers   = { }
readers.helpers = helpers

local function gotodatatable(f,fontdata,tag,criterium)
    if criterium and f then
        local tables = fontdata.tables
        if tables then
            local datatable = tables[tag]
            if datatable then
                local tableoffset = datatable.offset
                setposition(f,tableoffset)
                return tableoffset
            end
        else
            report("no tables")
        end
    end
end

local function reportskippedtable(f,fontdata,tag,criterium)
    if criterium and f then
        local tables = fontdata.tables
        if tables then
            local datatable = tables[tag]
            if datatable then
                report("loading of table %a skipped",tag)
            end
        else
            report("no tables")
        end
    end
end

local function setvariabledata(fontdata,tag,data)
    local variabledata = fontdata.variabledata
    if variabledata then
        variabledata[tag] = data
    else
        fontdata.variabledata = { [tag] = data }
    end
end

helpers.gotodatatable      = gotodatatable
helpers.setvariabledata    = setvariabledata
helpers.reportskippedtable = reportskippedtable

-- The name table is probably the first one to load. After all this one provides
-- useful information about what we deal with. The complication is that we need
-- to filter the best one available.

local platformnames = {
    postscriptname       = true,
    fullname             = true,
    family               = true,
    subfamily            = true,
    typographicfamily    = true,
    typographicsubfamily = true,
    compatiblefullname   = true,
}

local platformextras = {
    uniqueid     = true,
    version      = true,
    copyright    = true,
    license      = true,
    licenseurl   = true,
    manufacturer = true,
    vendorurl    = true,
}

function readers.name(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"name",true)
    if tableoffset then
        local format   = readushort(f)
        local nofnames = readushort(f)
        local offset   = readushort(f)
        -- we can also provide a raw list as extra, todo as option
        local start    = tableoffset + offset
        local namelists = {
            unicode   = { },
            windows   = { },
            macintosh = { },
         -- iso       = { },
         -- windows   = { },
        }
        for i=1,nofnames do
            local platform = platforms[readushort(f)]
            if platform then
                local namelist = namelists[platform]
                if namelist then
                    local encoding  = readushort(f)
                    local language  = readushort(f)
                    local encodings = encodings[platform]
                    local languages = languages[platform]
                    if encodings and languages then
                        local encoding = encodings[encoding]
                        local language = languages[language]
                        if encoding and language then
                            local index = readushort(f)
                            local name  = reservednames[index]
                            namelist[#namelist+1] = {
                                platform = platform,
                                encoding = encoding,
                                language = language,
                                name     = name,
                                index    = index,
                                length   = readushort(f),
                                offset   = start + readushort(f),
                            }
                        else
                            skipshort(f,3)
                        end
                    else
                        skipshort(f,3)
                    end
                else
                    skipshort(f,5)
                end
            else
                skipshort(f,5)
            end
        end
     -- if format == 1 then
     --     local noftags = readushort(f)
     --     for i=1,noftags do
     --        local length = readushort(f)
     --        local offset = readushort(f)
     --     end
     -- end
        --
        -- we need to choose one we like, for instance an unicode one
        --
        local names  = { }
        local done   = { }
        local extras = { }
        --
        -- there is quite some logic in ff ... hard to follow so we start simple
        -- and extend when we run into it (todo: proper reverse hash) .. we're only
        -- interested in english anyway
        --
        local function decoded(platform,encoding,content)
            local decoder = decoders[platform]
            if decoder then
                decoder = decoder[encoding]
            end
            if decoder then
                return decoder(content)
            else
                return content
            end
        end
        --
        local function filter(platform,e,l)
            local namelist = namelists[platform]
            for i=1,#namelist do
                local name    = namelist[i]
                local nametag = name.name
                local index = name.index
                if not done[nametag or i] then
                    local encoding = name.encoding
                    local language = name.language
                    if (not e or encoding == e) and (not l or language == l) then
                        setposition(f,name.offset)
                        local content = decoded(platform,encoding,readstring(f,name.length))
                        if nametag then
                            names[nametag] = {
                                content  = content,
                                platform = platform,
                                encoding = encoding,
                                language = language,
                            }
                        end
                        extras[index] = content
                        done[nametag or i] = true
                    end
                end
            end
        end
        --
        filter("windows","unicode bmp","english - united states")
     -- filter("unicode") -- which one ?
        filter("macintosh","roman","english")
        filter("windows")
        filter("macintosh")
        filter("unicode")
        --
        fontdata.names  = names
        fontdata.extras = extras
        --
        if specification.platformnames then
            local collected      = { }
            local platformextras = specification.platformextras and platformextras
            for platform, namelist in next, namelists do
                local filtered = false
                for i=1,#namelist do
                    local entry = namelist[i]
                    local name  = entry.name
                    if platformnames[name] or (platformextras and platformextras[name]) then
                        setposition(f,entry.offset)
                        local content = decoded(platform,entry.encoding,readstring(f,entry.length))
                        if filtered then
                            filtered[name] = content
                        else
                            filtered = { [name] = content }
                        end
                    end
                end
                if filtered then
                    collected[platform] = filtered
                end
            end
            fontdata.platformnames = collected
        end
    else
        fontdata.names = { }
    end
end

----- validutf = lpeg.patterns.utf8character^0 * P(-1)
local validutf = lpeg.patterns.validutf8

local function getname(fontdata,key)
    local names = fontdata.names
    if names then
        local value = names[key]
        if value then
            local content = value.content
            return lpegmatch(validutf,content) and content or nil
        end
    end
end

-- This table is an original windows (with its precursor os/2) table. In ff this one is
-- part of the pfminfo table but here we keep it separate (for now). We will create a
-- properties table afterwards.

readers["os/2"] = function(f,fontdata)
    local tableoffset = gotodatatable(f,fontdata,"os/2",true)
    if tableoffset then
        local version = readushort(f)
        local windowsmetrics = {
            version            = version,
            averagewidth       = readshort(f), -- ushort?
            weightclass        = readushort(f),
            widthclass         = readushort(f),
            fstype             = readushort(f),
            subscriptxsize     = readshort(f),
            subscriptysize     = readshort(f),
            subscriptxoffset   = readshort(f),
            subscriptyoffset   = readshort(f),
            superscriptxsize   = readshort(f),
            superscriptysize   = readshort(f),
            superscriptxoffset = readshort(f),
            superscriptyoffset = readshort(f),
            strikeoutsize      = readshort(f),
            strikeoutpos       = readshort(f),
            familyclass        = readshort(f),
            panose             = { readbytes(f,10) },
            unicoderanges      = { readulong(f), readulong(f), readulong(f), readulong(f) },
            vendor             = readstring(f,4),
            fsselection        = readushort(f),
            firstcharindex     = readushort(f),
            lastcharindex      = readushort(f),
            typoascender       = readshort(f),
            typodescender      = readshort(f),
            typolinegap        = readshort(f),
            winascent          = readushort(f),
            windescent         = readushort(f),
        }
        if version >= 1 then
            windowsmetrics.codepageranges = { readulong(f), readulong(f) }
        end
        if version >= 2 then
            windowsmetrics.xheight               = readshort(f)
            windowsmetrics.capheight             = readshort(f)
            windowsmetrics.defaultchar           = readushort(f)
            windowsmetrics.breakchar             = readushort(f)
         -- windowsmetrics.maxcontexts           = readushort(f)
         -- windowsmetrics.loweropticalpointsize = readushort(f)
         -- windowsmetrics.upperopticalpointsize = readushort(f)
        end
        --
        -- todo: unicoderanges
        --
        windowsmetrics.weight = windowsmetrics.weightclass and weights[windowsmetrics.weightclass]
        windowsmetrics.width  = windowsmetrics.widthclass and  widths [windowsmetrics.widthclass]
        --
        windowsmetrics.panoseweight = panoseweights[windowsmetrics.panose[3]]
        windowsmetrics.panosewidth  = panosewidths [windowsmetrics.panose[4]]
        --
        fontdata.windowsmetrics = windowsmetrics
    else
        fontdata.windowsmetrics = { }
    end
end

readers.head = function(f,fontdata)
    local tableoffset = gotodatatable(f,fontdata,"head",true)
    if tableoffset then
        local version     = readulong(f)
        local fontversion = readulong(f)
        local fontheader = {
            version           = version,
            fontversion       = number.to16dot16(fontversion),
            fontversionnumber = fontversion,
         -- checksum          = readulong(f),
            checksum          = readushort(f) * 0x10000 + readushort(f),
            magic             = readulong(f),
            flags             = readushort(f),
            units             = readushort(f),
            created           = readlongdatetime(f),
            modified          = readlongdatetime(f),
            xmin              = readshort(f),
            ymin              = readshort(f),
            xmax              = readshort(f),
            ymax              = readshort(f),
            macstyle          = readushort(f),
            smallpixels       = readushort(f),
            directionhint     = readshort(f),
            indextolocformat  = readshort(f),
            glyphformat       = readshort(f),
        }
        fontdata.fontheader = fontheader
    else
        fontdata.fontheader = { }
    end
    fontdata.nofglyphs = 0
end

-- This table is a rather simple one. No treatment of values is needed here. Most
-- variables are not used but nofmetrics is quite important.

readers.hhea = function(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"hhea",specification.details)
    if tableoffset then
        fontdata.horizontalheader = {
            version             = readulong(f),
            ascender            = readfword(f),
            descender           = readfword(f),
            linegap             = readfword(f),
            maxadvancewidth     = readufword(f),
            minleftsidebearing  = readfword(f),
            minrightsidebearing = readfword(f),
            maxextent           = readfword(f),
            caretsloperise      = readshort(f),
            caretsloperun       = readshort(f),
            caretoffset         = readshort(f),
            reserved_1          = readshort(f),
            reserved_2          = readshort(f),
            reserved_3          = readshort(f),
            reserved_4          = readshort(f),
            metricdataformat    = readshort(f),
            nofmetrics          = readushort(f),
        }
    else
        fontdata.horizontalheader = {
            nofmetrics = 0,
        }
    end
end

readers.vhea = function(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"vhea",specification.details)
    if tableoffset then
        fontdata.verticalheader = {
            version              = readulong(f),
            ascender             = readfword(f),
            descender            = readfword(f),
            linegap              = readfword(f),
            maxadvanceheight     = readufword(f),
            mintopsidebearing    = readfword(f),
            minbottomsidebearing = readfword(f),
            maxextent            = readfword(f),
            caretsloperise       = readshort(f),
            caretsloperun        = readshort(f),
            caretoffset          = readshort(f),
            reserved_1           = readshort(f),
            reserved_2           = readshort(f),
            reserved_3           = readshort(f),
            reserved_4           = readshort(f),
            metricdataformat     = readshort(f),
            nofmetrics           = readushort(f),
        }
    else
        fontdata.verticalheader = {
            nofmetrics = 0,
        }
    end
end

-- We probably never need all these variables, but we do need the nofglyphs when loading other
-- tables. Again we use the microsoft names but see no reason to have "max" in each name.

-- fontdata.maximumprofile can be bad

readers.maxp = function(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"maxp",specification.details)
    if tableoffset then
        local version      = readulong(f)
        local nofglyphs    = readushort(f)
        fontdata.nofglyphs = nofglyphs
        if version == 0x00005000 then
            fontdata.maximumprofile = {
                version   = version,
                nofglyphs = nofglyphs,
            }
        elseif version == 0x00010000 then
            fontdata.maximumprofile = {
                version            = version,
                nofglyphs          = nofglyphs,
                points             = readushort(f),
                contours           = readushort(f),
                compositepoints    = readushort(f),
                compositecontours  = readushort(f),
                zones              = readushort(f),
                twilightpoints     = readushort(f),
                storage            = readushort(f),
                functiondefs       = readushort(f),
                instructiondefs    = readushort(f),
                stackelements      = readushort(f),
                sizeofinstructions = readushort(f),
                componentelements  = readushort(f),
                componentdepth     = readushort(f),
            }
        else
            fontdata.maximumprofile = {
                version   = version,
                nofglyphs = 0,
            }
        end
    end
end

-- Here we filter the (advance) widths (that can be different from the boundingbox width of
-- course).

readers.hmtx = function(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"hmtx",specification.glyphs)
    if tableoffset then
        local horizontalheader = fontdata.horizontalheader
        local nofmetrics       = horizontalheader.nofmetrics
        local glyphs           = fontdata.glyphs
        local nofglyphs        = fontdata.nofglyphs
        local width            = 0 -- advance
        local leftsidebearing  = 0
        for i=0,nofmetrics-1 do
            local glyph     = glyphs[i]
            width           = readshort(f) -- readushort
            leftsidebearing = readshort(f)
            if width ~= 0 then
                glyph.width = width
            end
         -- if leftsidebearing ~= 0 then
         --     glyph.lsb = leftsidebearing
         -- end
-- if leftsidebearing ~= 0 then
--     glyph.lsb = leftsidebearing
-- end
        end
        -- The next can happen in for instance a monospace font or in a cjk font
        -- with fixed widths.
        for i=nofmetrics,nofglyphs-1 do
            local glyph = glyphs[i]
            if width ~= 0 then
                glyph.width = width
            end
         -- if leftsidebearing ~= 0 then
         --     glyph.lsb = leftsidebearing
         -- end
        end
    end
end

readers.vmtx = function(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"vmtx",specification.glyphs)
    if tableoffset then
        local verticalheader = fontdata.verticalheader
        local nofmetrics     = verticalheader.nofmetrics
        local glyphs         = fontdata.glyphs
        local nofglyphs      = fontdata.nofglyphs
        local vheight        = 0
        local vdefault       = verticalheader.ascender - verticalheader.descender
        local topsidebearing = 0
        for i=0,nofmetrics-1 do
            local glyph     = glyphs[i]
            vheight         = readushort(f)
            topsidebearing  = readshort(f)
            if vheight ~= 0 and vheight ~= vdefault then
                glyph.vheight = vheight
            end
            if topsidebearing ~= 0 then
                glyph.tsb = topsidebearing
            end
        end
        -- The next can happen in for instance a monospace font or in a cjk font
        -- with fixed heights.
        for i=nofmetrics,nofglyphs-1 do
            local glyph = glyphs[i]
            if vheight ~= 0 and vheight ~= vdefault then
                glyph.vheight = vheight
            end
        end
    end
end

readers.vorg = function(f,fontdata,specification)
    reportskippedtable(f,fontdata,"vorg",specification.glyphs)
end

-- The post table relates to postscript (printing) but has some relevant properties for other
-- usage as well. We just use the names from the microsoft specification. The version 2.0
-- description is somewhat fuzzy but it is a hybrid with overloads.

readers.post = function(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"post",true)
    if tableoffset then
        local version = readulong(f)
        fontdata.postscript = {
            version            = version,
            italicangle        = readfixed(f),
            underlineposition  = readfword(f),
            underlinethickness = readfword(f),
            monospaced         = readulong(f),
            minmemtype42       = readulong(f),
            maxmemtype42       = readulong(f),
            minmemtype1        = readulong(f),
            maxmemtype1        = readulong(f),
        }
        if not specification.glyphs then
            -- enough done
        elseif version == 0x00010000 then
            -- mac encoding (258 glyphs)
            for index=0,#standardromanencoding do
                glyphs[index].name = standardromanencoding[index]
            end
        elseif version == 0x00020000 then
            local glyphs    = fontdata.glyphs
            local nofglyphs = readushort(f)
            local indices   = { }
            local names     = { }
            local maxnames  = 0
            for i=0,nofglyphs-1 do
                local nameindex = readushort(f)
                if nameindex >= 258 then
                    maxnames  = maxnames + 1
                    nameindex = nameindex - 257
                    indices[nameindex] = i
                else
                    glyphs[i].name = standardromanencoding[nameindex]
                end
            end
            for i=1,maxnames do
                local mapping = indices[i]
                if not mapping then
                    report("quit post name fetching at %a of %a: %s",i,maxnames,"no index")
                    break
                else
                    local length = readbyte(f)
                    if length > 0 then
                        glyphs[mapping].name = readstring(f,length)
                    else
                     -- report("quit post name fetching at %a of %a: %s",i,maxnames,"overflow")
                     -- break
                    end
                end
            end
        end
    else
        fontdata.postscript = { }
    end
end

readers.cff = function(f,fontdata,specification)
    reportskippedtable(f,fontdata,"cff",specification.glyphs)
end

-- Not all cmaps make sense .. e.g. dfont is obsolete and probably more are not relevant. Let's see
-- what we run into. There is some weird calculation going on here because we offset in a table
-- being a blob of memory or file. Anyway, I can't stand lunatic formats like this esp when there
-- is no real gain.

local formatreaders = { }
local duplicatestoo = true

local sequence = {
    -- these is some provision against redundant loading
    { 3,  1,  4 },
    { 3, 10, 12 },
    { 0,  3,  4 },
    { 0,  3, 12 },
    { 0,  1,  4 },
    { 0,  1, 12 }, -- for some old mac fonts
    { 0,  0,  6 },
    { 3,  0,  6 },
    { 3,  0,  4 }, -- for (likely) old crap
    -- variants
    { 0,  5, 14 },
    -- last resort ranges
    { 0,  4, 12 },
    { 3, 10, 13 },
}

local supported = {  }

for i=1,#sequence do
    local si = sequence[i]
    local sp, se, sf = si[1], si[2], si[3]
    local p = supported[sp]
    if not p then
        p = { }
        supported[sp] = p
    end
    local e = p[se]
    if not e then
        e = { }
        p[se] = e
    end
    e[sf] = true
end

formatreaders[4] = function(f,fontdata,offset)
    setposition(f,offset+2) -- skip format
    --
    local length      = readushort(f) -- in bytes of subtable
    local language    = readushort(f)
    local nofsegments = readushort(f) / 2
    --
    skipshort(f,3) -- searchrange entryselector rangeshift
    --
    local mapping    = fontdata.mapping
    local glyphs     = fontdata.glyphs
    local duplicates = fontdata.duplicates
    local nofdone    = 0
    local endchars   = readcardinaltable(f,nofsegments,ushort)
    local reserved   = readushort(f) -- 0
    local startchars = readcardinaltable(f,nofsegments,ushort)
    local deltas     = readcardinaltable(f,nofsegments,ushort)
    local offsets    = readcardinaltable(f,nofsegments,ushort)
    -- format length language nofsegments searchrange entryselector rangeshift 4-tables
    local size       = (length - 2 * 2 - 5 * 2 - 4 * 2 * nofsegments) / 2
    local indices    = readcardinaltable(f,size-1,ushort)
    --
    for segment=1,nofsegments do
        local startchar = startchars[segment]
        local endchar   = endchars[segment]
        local offset    = offsets[segment]
        local delta     = deltas[segment]
        if startchar == 0xFFFF and endchar == 0xFFFF then
            -- break
        elseif startchar == 0xFFFF and offset == 0 then
            -- break
        elseif offset == 0xFFFF then
            -- bad encoding
        elseif offset == 0 then
            if trace_cmap_details then
                report("format 4.%i segment %2i from %C upto %C at index %H",1,segment,startchar,endchar,(startchar + delta) % 65536)
            end
            for unicode=startchar,endchar do
                local index = (unicode + delta) % 65536
                if index and index > 0 then
                    local glyph = glyphs[index]
                    if glyph then
                        local gu = glyph.unicode
                        if not gu then
                            glyph.unicode = unicode
                            nofdone = nofdone + 1
                        elseif gu ~= unicode then
                            if duplicatestoo then
                                local d = duplicates[gu]
                                if d then
                                    d[unicode] = true
                                else
                                    duplicates[gu] = { [unicode] = true }
                                end
                            else
                                -- no duplicates ... weird side effects in lm
                                report("duplicate case 1: %C %04i %s",unicode,index,glyphs[index].name)
                            end
                        end
                        if not mapping[index] then
                            mapping[index] = unicode
                        end
                    end
                end
            end
        else
            local shift = (segment-nofsegments+offset/2) - startchar
            if trace_cmap_details then
                report_cmap("format 4.%i segment %2i from %C upto %C at index %H",0,segment,startchar,endchar,(startchar + delta) % 65536)
            end
            for unicode=startchar,endchar do
                local slot  = shift + unicode
                local index = indices[slot]
                if index and index > 0 then
                    index = (index + delta) % 65536
                    local glyph = glyphs[index]
                    if glyph then
                        local gu = glyph.unicode
                        if not gu then
                            glyph.unicode = unicode
                            nofdone = nofdone + 1
                        elseif gu ~= unicode then
                            if duplicatestoo then
                                local d = duplicates[gu]
                                if d then
                                    d[unicode] = true
                                else
                                    duplicates[gu] = { [unicode] = true }
                                end
                            else
                                -- no duplicates ... weird side effects in lm
                                report("duplicate case 2: %C %04i %s",unicode,index,glyphs[index].name)
                            end
                        end
                        if not mapping[index] then
                            mapping[index] = unicode
                        end
                    end
                end
            end
        end
    end
    return nofdone
end

formatreaders[6] = function(f,fontdata,offset)
    setposition(f,offset) -- + 2 + 2 + 2 -- skip format length language
    local format     = readushort(f)
    local length     = readushort(f)
    local language   = readushort(f)
    local mapping    = fontdata.mapping
    local glyphs     = fontdata.glyphs
    local duplicates = fontdata.duplicates
    local start      = readushort(f)
    local count      = readushort(f)
    local stop       = start+count-1
    local nofdone    = 0
    if trace_cmap_details then
        report_cmap("format 6 from %C to %C",2,start,stop)
    end
    for unicode=start,stop do
        local index = readushort(f)
        if index > 0 then
            local glyph = glyphs[index]
            if glyph then
                local gu = glyph.unicode
                if not gu then
                    glyph.unicode = unicode
                    nofdone = nofdone + 1
                elseif gu ~= unicode then
                    -- report("format 6 overloading %C to %C",gu,unicode)
                    -- glyph.unicode = unicode
                    -- no duplicates ... weird side effects in lm
                end
                if not mapping[index] then
                    mapping[index] = unicode
                end
            end
        end
    end
    return nofdone
end

formatreaders[12] = function(f,fontdata,offset)
    setposition(f,offset+2+2+4+4) -- skip format reserved length language
    local mapping    = fontdata.mapping
    local glyphs     = fontdata.glyphs
    local duplicates = fontdata.duplicates
    local nofgroups  = readulong(f)
    local nofdone    = 0
    for i=1,nofgroups do
        local first = readulong(f)
        local last  = readulong(f)
        local index = readulong(f)
        if trace_cmap_details then
            report_cmap("format 12 from %C to %C starts at index %i",first,last,index)
        end
        for unicode=first,last do
            local glyph = glyphs[index]
            if glyph then
                local gu = glyph.unicode
                if not gu then
                    glyph.unicode = unicode
                    nofdone = nofdone + 1
                elseif gu ~= unicode then
                    -- e.g. sourcehan fonts need this
                    local d = duplicates[gu]
                    if d then
                        d[unicode] = true
                    else
                        duplicates[gu] = { [unicode] = true }
                    end
                end
                if not mapping[index] then
                    mapping[index] = unicode
                end
            end
            index = index + 1
        end
    end
    return nofdone
end

formatreaders[13] = function(f,fontdata,offset)
    --
    -- this vector is only used for simple fallback fonts
    --
    setposition(f,offset+2+2+4+4) -- skip format reserved length language
    local mapping    = fontdata.mapping
    local glyphs     = fontdata.glyphs
    local duplicates = fontdata.duplicates
    local nofgroups  = readulong(f)
    local nofdone    = 0
    for i=1,nofgroups do
        local first = readulong(f)
        local last  = readulong(f)
        local index = readulong(f)
        if first < privateoffset then
            if trace_cmap_details then
                report_cmap("format 13 from %C to %C get index %i",first,last,index)
            end
            local glyph   = glyphs[index]
            local unicode = glyph.unicode
            if not unicode then
                unicode = first
                glyph.unicode = unicode
                first = first + 1
            end
            local list     = duplicates[unicode]
            mapping[index] = unicode
            if not list then
                list = { }
                duplicates[unicode] = list
            end
            if last >= privateoffset then
                local limit = privateoffset - 1
                report("format 13 from %C to %C pruned to %C",first,last,limit)
                last = limit
            end
            for unicode=first,last do
                list[unicode] = true
            end
            nofdone = nofdone + last - first + 1
        else
            report("format 13 from %C to %C ignored",first,last)
        end
    end
    return nofdone
end

formatreaders[14] = function(f,fontdata,offset)
    if offset and offset ~= 0 then
        setposition(f,offset)
        local format      = readushort(f)
        local length      = readulong(f)
        local nofrecords  = readulong(f)
        local records     = { }
        local variants    = { }
        local nofdone     = 0
        fontdata.variants = variants
        for i=1,nofrecords do
            records[i] = {
                selector = readuint(f),
                default  = readulong(f), -- default offset
                other    = readulong(f), -- non-default offset
            }
        end
        for i=1,nofrecords do
            local record   = records[i]
            local selector = record.selector
            local default  = record.default
            local other    = record.other
            --
            -- there is no need to map the defaults to themselves
            --
         -- if default ~= 0 then
         --     setposition(f,offset+default)
         --     local nofranges = readulong(f)
         --     for i=1,nofranges do
         --         local start = readuint(f)
         --         local extra = readbyte(f)
         --         for i=start,start+extra do
         --             mapping[i] = i
         --         end
         --     end
         -- end
            local other = record.other
            if other ~= 0 then
                setposition(f,offset+other)
                local mapping = { }
                local count   = readulong(f)
                for i=1,count do
                    mapping[readuint(f)] = readushort(f)
                end
                nofdone = nofdone + count
                variants[selector] = mapping
            end
        end
        return nofdone
    else
        return 0
    end
end

local function checkcmap(f,fontdata,records,platform,encoding,format)
    local pdata = records[platform]
    if not pdata then
        if trace_cmap_details then
            report_cmap("skipped, %s, p=%i e=%i f=%i","no platform",platform,encoding,format)
        end
        return 0
    end
    local edata = pdata[encoding]
    if not edata then
        if trace_cmap_details then
            report_cmap("skipped, %s, p=%i e=%i f=%i","no encoding",platform,encoding,format)
        end
        return 0
    end
    local fdata = edata[format]
    if not fdata then
        if trace_cmap_details then
            report_cmap("skipped, %s, p=%i e=%i f=%i","no format",platform,encoding,format)
        end
        return 0
    elseif type(fdata) ~= "number" then
        if trace_cmap_details then
            report_cmap("skipped, %s, p=%i e=%i f=%i","already done",platform,encoding,format)
        end
        return 0
    end
    edata[format] = true -- done
    local reader = formatreaders[format]
    if not reader then
        if trace_cmap_details then
            report_cmap("skipped, %s, p=%i e=%i f=%i","unsupported format",platform,encoding,format)
        end
        return 0
    end
    local n = reader(f,fontdata,fdata) or 0
    if trace_cmap_details or trace_cmap then
        local p = platforms[platform]
        local e = encodings[p]
        report_cmap("checked, platform %i (%s), encoding %i (%s), format %i, new unicodes %i",
            platform,p,encoding,e and e[encoding] or "?",format,n)
    end
    return n
end

function readers.cmap(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"cmap",specification.glyphs)
    if tableoffset then
        local version      = readushort(f) -- check later versions
        local noftables    = readushort(f)
        local records      = { }
        local unicodecid   = false
        local variantcid   = false
        local variants     = { }
        local duplicates   = fontdata.duplicates or { }
        fontdata.duplicates = duplicates
        for i=1,noftables do
            local platform = readushort(f)
            local encoding = readushort(f)
            local offset   = readulong(f)
            local record   = records[platform]
            if not record then
                records[platform] = {
                    [encoding] = {
                        offsets = { offset },
                        formats = { },
                    }
                }
            else
                local subtables = record[encoding]
                if not subtables then
                    record[encoding] = {
                        offsets = { offset },
                        formats = { },
                    }
                else
                    local offsets = subtables.offsets
                    offsets[#offsets+1] = offset
                end
            end
        end
        if trace_cmap then
            report("found cmaps:")
        end
        for platform, record in sortedhash(records) do
            local p  = platforms[platform]
            local e  = encodings[p]
            local sp = supported[platform]
            local ps = p or "?"
            if trace_cmap then
                if sp then
                    report("  platform %i: %s",platform,ps)
                else
                    report("  platform %i: %s (unsupported)",platform,ps)
                end
            end
            for encoding, subtables in sortedhash(record) do
                local se = sp and sp[encoding]
                local es = e and e[encoding] or "?"
                if trace_cmap then
                    if se then
                        report("    encoding %i: %s",encoding,es)
                    else
                        report("    encoding %i: %s (unsupported)",encoding,es)
                    end
                end
                local offsets = subtables.offsets
                local formats = subtables.formats
                for i=1,#offsets do
                    local offset = tableoffset + offsets[i]
                    setposition(f,offset)
                    formats[readushort(f)] = offset
                end
                record[encoding] = formats
                if trace_cmap then
                    local list = sortedkeys(formats)
                    for i=1,#list do
                        if not (se and se[list[i]]) then
                            list[i] = list[i] .. " (unsupported)"
                        end
                    end
                    report("      formats: % t",list)
                end
            end
        end
        --
        local ok = false
        for i=1,#sequence do
            local si = sequence[i]
            local sp, se, sf = si[1], si[2], si[3]
            if checkcmap(f,fontdata,records,sp,se,sf) > 0 then
                ok = true
            end
        end
        if not ok then
            report("no useable unicode cmap found")
        end
        --
        fontdata.cidmaps = {
            version   = version,
            noftables = noftables,
            records   = records,
        }
    else
        fontdata.cidmaps = { }
    end
end

-- The glyf table depends on the loca table. We have one entry to much in the locations table (the
-- last one is a dummy) because we need to calculate the size of a glyph blob from the delta,
-- although we not need it in our usage (yet). We can remove the locations table when we're done.

function readers.loca(f,fontdata,specification)
    reportskippedtable(f,fontdata,"loca",specification.glyphs)
end

function readers.glyf(f,fontdata,specification) -- part goes to cff module
    reportskippedtable(f,fontdata,"glyf",specification.glyphs)
end

-- The MicroSoft variant is pretty clean and is supported (implemented elsewhere)
-- just because I wanted to see how such a font looks like.

function readers.colr(f,fontdata,specification)
    reportskippedtable(f,fontdata,"colr",specification.glyphs)
end
function readers.cpal(f,fontdata,specification)
    reportskippedtable(f,fontdata,"cpal",specification.glyphs)
end

-- This one is also supported, if only because I could locate a proper font for
-- testing.

function readers.svg(f,fontdata,specification)
    reportskippedtable(f,fontdata,"svg",specification.glyphs)
end

-- There is a font from apple to test the next one. Will there be more? Anyhow,
-- it's relatively easy to support, so I did it.

function readers.sbix(f,fontdata,specification)
    reportskippedtable(f,fontdata,"sbix",specification.glyphs)
end

-- I'm only willing to look into the next variant if I see a decent and complete (!)
-- font and more can show up. It makes no sense to waste time on ideas. Okay, the
-- apple font also has these tables.

function readers.cbdt(f,fontdata,specification)
    reportskippedtable(f,fontdata,"cbdt",specification.glyphs)
end
function readers.cblc(f,fontdata,specification)
    reportskippedtable(f,fontdata,"cblc",specification.glyphs)
end
function readers.ebdt(f,fontdata,specification)
    reportskippedtable(f,fontdata,"ebdt",specification.glyphs)
end
function readers.ebsc(f,fontdata,specification)
    reportskippedtable(f,fontdata,"ebsc",specification.glyphs)
end
function readers.eblc(f,fontdata,specification)
    reportskippedtable(f,fontdata,"eblc",specification.glyphs)
end

-- Here we have a table that we really need for later processing although a more advanced gpos table
-- can also be available. Todo: we need a 'fake' lookup for this (analogue to ff).

function readers.kern(f,fontdata,specification)
    local tableoffset = gotodatatable(f,fontdata,"kern",specification.kerns)
    if tableoffset then
        local version   = readushort(f)
        local noftables = readushort(f)
        for i=1,noftables do
            local version  = readushort(f)
            local length   = readushort(f)
            local coverage = readushort(f)
            -- bit 8-15 of coverage: format 0 or 2
            local format   = rshift(coverage,8) -- is this ok?
            if format == 0 then
                local nofpairs      = readushort(f)
                local searchrange   = readushort(f)
                local entryselector = readushort(f)
                local rangeshift    = readushort(f)
                local kerns  = { }
                local glyphs = fontdata.glyphs
                for i=1,nofpairs do
                    local left  = readushort(f)
                    local right = readushort(f)
                    local kern  = readfword(f)
                    local glyph = glyphs[left]
                    local kerns = glyph.kerns
                    if kerns then
                        kerns[right] = kern
                    else
                        glyph.kerns = { [right] = kern }
                    end
                end
            elseif format == 2 then
                report("todo: kern classes")
            else
                report("todo: kerns")
            end
        end
    end
end

function readers.gdef(f,fontdata,specification)
    reportskippedtable(f,fontdata,"gdef",specification.details)
end

function readers.gsub(f,fontdata,specification)
    reportskippedtable(f,fontdata,"gsub",specification.details)
end

function readers.gpos(f,fontdata,specification)
    reportskippedtable(f,fontdata,"gpos",specification.details)
end

function readers.math(f,fontdata,specification)
    reportskippedtable(f,fontdata,"math",specification.details)
end

-- Now comes the loader. The order of reading these matters as we need to know
-- some properties in order to read following tables. When details is true we also
-- initialize the glyphs data.

local function getinfo(maindata,sub,platformnames,rawfamilynames,metricstoo,instancenames)
    local fontdata = sub and maindata.subfonts and maindata.subfonts[sub] or maindata
    local names    = fontdata.names
    local info     = nil
    if names then
        local metrics        = fontdata.windowsmetrics or { }
        local postscript     = fontdata.postscript     or { }
        local fontheader     = fontdata.fontheader     or { }
        local cffinfo        = fontdata.cffinfo        or { }
        local verticalheader = fontdata.verticalheader or { }
        local filename       = fontdata.filename
        local weight         = getname(fontdata,"weight") or (cffinfo and cffinfo.weight) or (metrics and metrics.weight)
        local width          = getname(fontdata,"width")  or (cffinfo and cffinfo.width ) or (metrics and metrics.width )
        local fontname       = getname(fontdata,"postscriptname")
        local fullname       = getname(fontdata,"fullname")
        local family         = getname(fontdata,"family")
        local subfamily      = getname(fontdata,"subfamily")
        local familyname     = getname(fontdata,"typographicfamily")
        local subfamilyname  = getname(fontdata,"typographicsubfamily")
        local compatiblename = getname(fontdata,"compatiblefullname") -- kind of useless
        if rawfamilynames then
            -- for PG (for now, as i need to check / adapt context to catch a no-fallback case)
        else
            if not    familyname then    familyname =    family end
            if not subfamilyname then subfamilyname = subfamily end
        end
        if platformnames then
            platformnames = fontdata.platformnames
        end
        if instancenames then
            local variabledata = fontdata.variabledata
            if variabledata then
                local instances = variabledata and variabledata.instances
                if instances then
                    instancenames = { }
                    for i=1,#instances do
                        instancenames[i] = lower(stripstring(instances[i].subfamily))
                    end
                else
                    instancenames = nil
                end
            else
                instancenames = nil
            end
        end
        info = { -- we inherit some inconsistencies/choices from ff
            subfontindex   = fontdata.subfontindex or sub or 0,
         -- filename       = filename,
            version        = getname(fontdata,"version"),
         -- format         = fontdata.format,
            fontname       = fontname,
            fullname       = fullname,
         -- cfffullname    = cff.fullname,
            family         = family,
            subfamily      = subfamily,
            familyname     = familyname,
            subfamilyname  = subfamilyname,
            compatiblename = compatiblename,
            weight         = weight and lower(weight),
            width          = width and lower(width),
            pfmweight      = metrics.weightclass or 400, -- will become weightclass
            pfmwidth       = metrics.widthclass or 5, -- will become widthclass
            panosewidth    = metrics.panosewidth,
            panoseweight   = metrics.panoseweight,
            fstype         = metrics.fstype or 0, -- embedding, subsetting and editing
            italicangle    = postscript.italicangle or 0,
            units          = fontheader.units or 0,
            designsize     = fontdata.designsize,
            minsize        = fontdata.minsize,
            maxsize        = fontdata.maxsize,
            boundingbox    = fontheader and { fontheader.xmin or 0, fontheader.ymin or 0, fontheader.xmax or 0, fontheader.ymax or 0 } or nil,
            monospaced     = (tonumber(postscript.monospaced or 0) > 0) or metrics.panosewidth == "monospaced",
            averagewidth   = metrics.averagewidth,
            xheight        = metrics.xheight, -- can be missing
            capheight      = metrics.capheight or fontdata.maxy, -- can be missing
            ascender       = metrics.typoascender,
            descender      = metrics.typodescender,
            platformnames  = platformnames or nil,
            instancenames  = instancenames or nil,
            tableoffsets   = fontdata.tableoffsets,
            defaultvheight = (verticalheader.ascender or 0) - (verticalheader.descender or 0)
        }
        if metricstoo then
            local keys = {
                "version",
                "ascender", "descender", "linegap",
             -- "caretoffset", "caretsloperise", "caretsloperun",
                "maxadvancewidth", "maxadvanceheight", "maxextent",
             -- "metricdataformat",
                "minbottomsidebearing", "mintopsidebearing",
            }
            local h = fontdata.horizontalheader or { }
            local v = fontdata.verticalheader   or { }
            if h then
                local th = { }
                local tv = { }
                for i=1,#keys do
                    local key = keys[i]
                    th[key] = h[key] or 0
                    tv[key] = v[key] or 0
                end
                info.horizontalmetrics = th
                info.verticalmetrics   = tv
            end
        end
    elseif n then
        info = {
            filename = fontdata.filename,
            comment  = "there is no info for subfont " .. n,
        }
    else
        info = {
            filename = fontdata.filename,
            comment  = "there is no info",
        }
    end
 -- inspect(info)
    return info
end

local function loadtables(f,specification,offset)
    if offset then
        setposition(f,offset)
    end
    local tables   = { }
    local basename = file.basename(specification.filename)
    local filesize = specification.filesize
    local filetime = specification.filetime
    local fontdata = { -- some can/will go
        filename      = basename,
        filesize      = filesize,
        filetime      = filetime,
        version       = readstring(f,4),
        noftables     = readushort(f),
        searchrange   = readushort(f), -- not needed
        entryselector = readushort(f), -- not needed
        rangeshift    = readushort(f), -- not needed
        tables        = tables,
        foundtables   = false,
    }
    for i=1,fontdata.noftables do
        local tag      = lower(stripstring(readstring(f,4)))
     -- local checksum = readulong(f) -- not used
        local checksum = readushort(f) * 0x10000 + readushort(f)
        local offset   = readulong(f)
        local length   = readulong(f)
        if offset + length > filesize then
            report("bad %a table in file %a",tag,basename)
        end
        tables[tag] = {
            checksum = checksum,
            offset   = offset,
            length   = length,
        }
    end
-- inspect(tables)
    fontdata.foundtables = sortedkeys(tables)
    if tables.cff or tables.cff2 then
        fontdata.format = "opentype"
    else
        fontdata.format = "truetype"
    end
    return fontdata, tables
end

local function prepareglyps(fontdata)
    local glyphs = setmetatableindex(function(t,k)
        local v = {
            -- maybe more defaults
            index = k,
        }
        t[k] = v
        return v
    end)
    fontdata.glyphs  = glyphs
    fontdata.mapping = { }
end

local function readtable(tag,f,fontdata,specification,...)
    local reader = readers[tag]
    if reader then
        reader(f,fontdata,specification,...)
    end
end

local function readdata(f,offset,specification)

    local fontdata, tables = loadtables(f,specification,offset)

    if specification.glyphs then
        prepareglyps(fontdata)
    end

    fontdata.temporary = { }

    readtable("name",f,fontdata,specification)

    local askedname = specification.askedname
    if askedname then
        local fullname  = getname(fontdata,"fullname") or ""
        local cleanname = gsub(askedname,"[^a-zA-Z0-9]","")
        local foundname = gsub(fullname,"[^a-zA-Z0-9]","")
        if lower(cleanname) ~= lower(foundname) then
            return -- keep searching
        end
    end

    readtable("stat",f,fontdata,specification)
    readtable("avar",f,fontdata,specification)
    readtable("fvar",f,fontdata,specification)

    local variabledata = fontdata.variabledata

    if variabledata then
        local instances = variabledata.instances
        local axis      = variabledata.axis
        if axis and (not instances or #instances == 0) then
            instances = { }
            variabledata.instances = instances
            local function add(n,subfamily,value)
                local values = { }
                for i=1,#axis do
                    local a = axis[i]
                    values[i] = {
                        axis  = a.tag,
                        value = i == n and value or a.default,
                    }
                end
                instances[#instances+1] = {
                    subfamily = subfamily,
                    values    = values,
                }
            end
            for i=1,#axis do
                local a   = axis[i]
                local tag = a.tag
                add(i,"default"..tag,a.default)
                add(i,"minimum"..tag,a.minimum)
                add(i,"maximum"..tag,a.maximum)
            end
         -- report("%i fake instances added",#instances)
        end
    end
    if not specification.factors then
        local instance = specification.instance
        if type(instance) == "string" then
            local factors = helpers.getfactors(fontdata,instance)
            if factors then
                specification.factors = factors
                fontdata.factors  = factors
                fontdata.instance = instance
                report("user instance: %s, factors: % t",instance,factors)
            else
                report("user instance: %s, bad factors",instance)
            end
        end
    end

    if not fontdata.factors then
        if fontdata.variabledata then
            local factors = helpers.getfactors(fontdata,true)
            if factors then
                specification.factors = factors
                fontdata.factors = factors
         --     report("factors: % t",factors)
         -- else
         --     report("bad factors")
            end
        else
         -- report("unknown instance")
        end
    end

    readtable("os/2",f,fontdata,specification)
    readtable("head",f,fontdata,specification)
    readtable("maxp",f,fontdata,specification)
    readtable("hhea",f,fontdata,specification)
    readtable("vhea",f,fontdata,specification)
    readtable("hmtx",f,fontdata,specification)
    readtable("vmtx",f,fontdata,specification)
    readtable("vorg",f,fontdata,specification)
    readtable("post",f,fontdata,specification)

    readtable("mvar",f,fontdata,specification)
    readtable("hvar",f,fontdata,specification)
    readtable("vvar",f,fontdata,specification)

    readtable("gdef",f,fontdata,specification)

    readtable("cff" ,f,fontdata,specification)
    readtable("cff2",f,fontdata,specification)

    readtable("cmap",f,fontdata,specification)
    readtable("loca",f,fontdata,specification) -- maybe load it in glyf
    readtable("glyf",f,fontdata,specification) -- loads gvar

    readtable("colr",f,fontdata,specification)
    readtable("cpal",f,fontdata,specification)

    readtable("svg" ,f,fontdata,specification)

    readtable("sbix",f,fontdata,specification)

    readtable("cbdt",f,fontdata,specification)
    readtable("cblc",f,fontdata,specification)
    readtable("ebdt",f,fontdata,specification)
    readtable("eblc",f,fontdata,specification)

    readtable("kern",f,fontdata,specification)
    readtable("gsub",f,fontdata,specification)
    readtable("gpos",f,fontdata,specification)

    readtable("math",f,fontdata,specification)

    fontdata.locations    = nil
    fontdata.cidmaps      = nil
    fontdata.dictionaries = nil
 -- fontdata.cff          = nil

    if specification.tableoffsets then
        fontdata.tableoffsets = tables
        setmetatableindex(tables, {
            version       = fontdata.version,
            noftables     = fontdata.noftables,
            searchrange   = fontdata.searchrange,
            entryselector = fontdata.entryselector,
            rangeshift    = fontdata.rangeshift,
        })
    end
    return fontdata
end

local function loadfontdata(specification)
    local filename = specification.filename
    local fileattr = lfs.attributes(filename)
    local filesize = fileattr and fileattr.size or 0
    local filetime = fileattr and fileattr.modification or 0
    local f = openfile(filename,true) -- zero based
    if not f then
        report("unable to open %a",filename)
    elseif filesize == 0 then
        report("empty file %a",filename)
        closefile(f)
    else
        specification.filesize = filesize
        specification.filetime = filetime
        local version  = readstring(f,4)
        local fontdata = nil
        if version == "OTTO" or version == "true" or version == "\0\1\0\0" then
            fontdata = readdata(f,0,specification)
        elseif version == "ttcf" then
            local subfont     = tonumber(specification.subfont)
            local ttcversion  = readulong(f)
            local nofsubfonts = readulong(f)
            local offsets     = readcardinaltable(f,nofsubfonts,ulong)
            if subfont then -- a number of not
                if subfont >= 1 and subfont <= nofsubfonts then
                    fontdata = readdata(f,offsets[subfont],specification)
                else
                    report("no subfont %a in file %a",subfont,filename)
                end
            else
                subfont = specification.subfont
                if type(subfont) == "string" and subfont ~= "" then
                    specification.askedname = subfont
                    for i=1,nofsubfonts do
                        fontdata = readdata(f,offsets[i],specification)
                        if fontdata then
                            fontdata.subfontindex = i
                            report("subfont named %a has index %a",subfont,i)
                            break
                        end
                    end
                    if not fontdata then
                        report("no subfont named %a",subfont)
                    end
                else
                    local subfonts = { }
                    fontdata = {
                        filename    = filename,
                        filesize    = filesize,
                        filetime    = filetime,
                        version     = version,
                        subfonts    = subfonts,
                        ttcversion  = ttcversion,
                        nofsubfonts = nofsubfonts,
                    }
                    for i=1,nofsubfonts do
                        subfonts[i] = readdata(f,offsets[i],specification)
                    end
                end
            end
        else
            report("unknown version %a in file %a",version,filename)
        end
        closefile(f)
        return fontdata or { }
    end
end

local function loadfont(specification,n,instance)
    if type(specification) == "string" then
        specification = {
            filename    = specification,
            info        = true, -- always true (for now)
            details     = true,
            glyphs      = true,
            shapes      = true,
            kerns       = true,
            variable    = true,
            globalkerns = true,
            lookups     = true,
            -- true or number:
            subfont     = n or true,
            tounicode   = false,
            instance    = instance
        }
    end
    -- if shapes only then
    if specification.shapes or specification.lookups or specification.kerns then
        specification.glyphs = true
    end
    if specification.glyphs then
        specification.details = true
    end
    if specification.details then
        specification.info = true -- not really used any more
    end
    if specification.platformnames then
        specification.platformnames = true -- not really used any more
    end
    if specification.instance or instance then
        specification.variable = true
        specification.instance = specification.instance or instance
    end
    local function message(str)
        report("fatal error in file %a: %s\n%s",specification.filename,str,debug and debug.traceback())
    end
    local ok, result = xpcall(loadfontdata,message,specification)
    if ok then
        return result
    end
--     return loadfontdata(specification)
end

-- we need even less, but we can have a 'detail' variant

function readers.loadshapes(filename,n,instance,streams)
    local fontdata = loadfont {
        filename = filename,
        shapes   = true,
        streams  = streams,
        variable = true,
        subfont  = n,
        instance = instance,
    }
    if fontdata then
        -- easier on luajit but still we can hit the 64 K stack constants issue
        for k, v in next, fontdata.glyphs do
            v.class = nil
            v.index = nil
            v.math  = nil
         -- v.name  = nil
        end
        local names = fontdata.names
        if names then
            for k, v in next, names do
                names[k] = fullstrip(v.content)
            end
        end
    end
    return fontdata and {
     -- version          = 0.123 -- todo
        filename         = filename,
        format           = fontdata.format,
        glyphs           = fontdata.glyphs,
        units            = fontdata.fontheader.units,
        cffinfo          = fontdata.cffinfo,
        fontheader       = fontdata.fontheader,
        horizontalheader = fontdata.horizontalheader,
        verticalheader   = fontdata.verticalheader,
        maximumprofile   = fontdata.maximumprofile,
        names            = fontdata.names,
        postscript       = fontdata.postscript,
    } or {
        filename = filename,
        format   = "unknown",
        glyphs   = { },
        units    = 0,
    }
end

function readers.loadfont(filename,n,instance)
    local fontdata = loadfont {
        filename    = filename,
        glyphs      = true,
        shapes      = false,
        lookups     = true,
        variable    = true,
     -- kerns       = true,
     -- globalkerns = true, -- only for testing, e.g. cambria has different gpos and kern
        subfont     = n,
        instance    = instance,
    }
    if fontdata then
        return {
            tableversion  = tableversion,
            creator       = "context mkiv",
            size          = fontdata.filesize,
            time          = fontdata.filetime,
            glyphs        = fontdata.glyphs,
            descriptions  = fontdata.descriptions,
            format        = fontdata.format,
            goodies       = { },
            metadata      = getinfo(fontdata,n,false,false,true,true), -- no platformnames here !
            properties    = {
                hasitalics    = fontdata.hasitalics or false,
                maxcolorclass = fontdata.maxcolorclass,
                hascolor      = fontdata.hascolor or false,
                instance      = fontdata.instance,
                factors       = fontdata.factors,
                nofsubfonts   = fontdata.subfonts and #fontdata.subfonts or nil,
            },
            resources     = {
             -- filename        = fontdata.filename,
                filename        = filename,
                private         = privateoffset,
                duplicates      = fontdata.duplicates  or { },
                features        = fontdata.features    or { }, -- we need to add these in the loader
                sublookups      = fontdata.sublookups  or { }, -- we need to add these in the loader
                marks           = fontdata.marks       or { }, -- we need to add these in the loader
                markclasses     = fontdata.markclasses or { }, -- we need to add these in the loader
                marksets        = fontdata.marksets    or { }, -- we need to add these in the loader
                sequences       = fontdata.sequences   or { }, -- we need to add these in the loader
                variants        = fontdata.variants, -- variant -> unicode -> glyph
                version         = getname(fontdata,"version"),
                cidinfo         = fontdata.cidinfo,
                mathconstants   = fontdata.mathconstants,
                colorpalettes   = fontdata.colorpalettes,
                colorpaintdata  = fontdata.colorpaintdata,
                colorpaintlist  = fontdata.colorpaintlist,
                colorlinesdata  = fontdata.colorlinesdata,
                coloraffinedata = fontdata.coloraffinedata,
                svgshapes       = fontdata.svgshapes,
                pngshapes       = fontdata.pngshapes,
                variabledata    = fontdata.variabledata,
                foundtables     = fontdata.foundtables,
            },
        }
    end
end

function readers.getinfo(filename,specification) -- string, nil|number|table
    -- platformnames is optional and not used by context (a too unpredictable mess
    -- that only add to the confusion) .. so it's only for checking things
    local subfont        = nil
    local platformnames  = false
    local rawfamilynames = false
    local instancenames  = true
    local tableoffsets   = false
    if type(specification) == "table" then
        subfont        = tonumber(specification.subfont)
        platformnames  = specification.platformnames
        rawfamilynames = specification.rawfamilynames
        tableoffsets   = specification.tableoffsets
    else
        subfont       = tonumber(specification)
    end
    local fontdata = loadfont {
        filename       = filename,
        details        = true,
        platformnames  = platformnames,
        instancenames  = true,
        tableoffsets   = tableoffsets,
     -- rawfamilynames = rawfamilynames,
    }
    if fontdata then
        local subfonts = fontdata.subfonts
        if not subfonts then
            return getinfo(fontdata,nil,platformnames,rawfamilynames,false,instancenames)
        elseif not subfont then
            local info = { }
            for i=1,#subfonts do
                info[i] = getinfo(fontdata,i,platformnames,rawfamilynames,false,instancenames)
            end
            return info
        elseif subfont >= 1 and subfont <= #subfonts then
            return getinfo(fontdata,subfont,platformnames,rawfamilynames,false,instancenames)
        else
            return {
                filename = filename,
                comment  = "there is no subfont " .. subfont .. " in this file"
            }
        end
    else
        return {
            filename = filename,
            comment  = "the file cannot be opened for reading",
        }
    end
end

function readers.rehash() -- fontdata,hashmethod
    report("the %a helper is not yet implemented","rehash")
end

function readers.checkhash() --fontdata
    report("the %a helper is not yet implemented","checkhash")
end

function readers.pack() -- fontdata,hashmethod
    report("the %a helper is not yet implemented","pack")
end

function readers.unpack(fontdata)
    report("the %a helper is not yet implemented","unpack")
end

function readers.expand(fontdata)
    report("the %a helper is not yet implemented","unpack")
end

function readers.compact(fontdata)
    report("the %a helper is not yet implemented","compact")
end

function readers.condense(fontdata)
    report("the %a helper is not yet implemented","condense")
end

-- plug in

local extenders = { }

function readers.registerextender(extender)
    extenders[#extenders+1] = extender
end

function readers.extend(fontdata)
    for i=1,#extenders do
        local extender = extenders[i]
        local name     = extender.name or "unknown"
        local action   = extender.action
        if action then
            action(fontdata)
        end
    end
end
