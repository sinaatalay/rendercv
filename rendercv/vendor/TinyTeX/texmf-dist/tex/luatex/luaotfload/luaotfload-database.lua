-----------------------------------------------------------------------
--         FILE:  luaotfload-database.lua
--  DESCRIPTION:  part of luaotfload / luaotfload-tool / font database
-----------------------------------------------------------------------
do -- block to avoid to many local variables error
 assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
     name          = "luaotfload-database",
     version       = "3.26",       --TAGVERSION
     date          = "2023-08-31", --TAGDATE
     description   = "luaotfload submodule / database",
     license       = "GPL v2.0",
     author        = "Khaled Hosny, Elie Roux, Philipp Gesang, Marcel Krüger",
     copyright     = "Luaotfload Development Team",     
 }
end

--[[doc--

    With version 2.7 we killed of the Fontforge libraries in favor of
    the Lua implementation of the OT format reader. There were many
    reasons to do this on top of the fact that FF won’t be around at
    version 1.0 anymore: In addition to maintainability, memory safety
    and general code hygiene, the new reader shows an amazing
    performance: Scanning of the 3200 font files on my system takes
    around 23 s now, as opposed to 74 s with the Fontforge libs. Memory
    usage has improved drastically as well, as illustrated by these
    profiles:

       GB
   1.324^                                                   #
        |                                                   #
        |                                                 ::#
        |                                                 : #::
        |                                                @: #:
        |                                                @: #:
        |                                              @@@: #:
        |                                            @@@ @: #:
        |                           @@               @ @ @: #:
        |                           @             @@:@ @ @: #: :
        |                          @@ :           @ :@ @ @: #: :
        |          @@:           ::@@ :@@       ::@ :@ @ @: #: :            :::
        |         @@ :          :: @@ :@        : @ :@ @ @: #: :           :: :
        |         @@ :         ::: @@ :@      ::: @ :@ @ @: #: ::          :: :
        |       @@@@ ::       :::: @@ :@      : : @ :@ @ @: #: ::        :::: ::
        |      :@ @@ ::       :::: @@ :@ :   :: : @ :@ @ @: #: ::       :: :: ::
        |     @:@ @@ ::      ::::: @@ :@ : :::: : @ :@ @ @: #: ::::   :::: :: ::
        |    @@:@ @@ ::    ::::::: @@ :@ : : :: : @ :@ @ @: #: :::   @: :: :: ::@
        |   @@@:@ @@ ::   :: ::::: @@ :@ ::: :: : @ :@ @ @: #: :::   @: :: :: ::@
        | @@@@@:@ @@ ::::::: ::::: @@ :@ ::: :: : @ :@ @ @: #: ::: ::@: :: :: ::@
      0 +----------------------------------------------------------------------->GB
        0                                                                   16.29

    This is the memory usage during a complete database rebuild with
    the Fontforge libraries. The same action using the new
    ``getinfo()`` method gives a different picture:

        MB
    43.37^                                                                   #
         |                                                            @ @   @#
         |                                                  @@        @ @   @# :
         |                                                 @@@ :   @: @ @   @# :
         |                                          @      @@@ : : @: @ @: :@# :
         |                            @             @      @@@ : : @: @ @: :@# :
         |                            @ :        : :@      @@@:::: @::@ @: :@#:: :
         |               ::    :      @ :  @   : :::@   @ :@@@:::::@::@ @:::@#::::
         |         :  @  :    :: :   :@:: :@:  :::::@   @ :@@@:::::@::@:@:::@#::::
         |        :: :@  :  @ ::@:@:::@:: :@:  :::::@: :@ :@@@:::::@::@:@:::@#::::
         |        :: :@::: :@ ::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         |      :@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         |  :::::@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         |  ::: :@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         | :::: :@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         | :::: :@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         | :::: :@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         | :::: :@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         | :::: :@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
         | :::: :@::::@::: :@:::@:@: :@::::@::::::::@:::@::@@@:::::@::@:@:::@#::::
       0 +----------------------------------------------------------------------->GB
         0                                                                   3.231

    FF peaks at around 1.4 GB after 12.5 GB worth of allocations,
    whereas the Lua implementation arrives at around 45 MB after 3.2 GB
    total:

             impl           time(B)         total(B)   useful-heap(B) extra-heap(B)
        fontforge    12,496,407,184    1,421,150,144    1,327,888,638    93,261,506
              lua     3,263,698,960       45,478,640       37,231,892     8,246,748

    Much of the inefficiency of Fontforge is a direct consequence of
    having to parse the entire font to extract what essentially boils
    down to a couple hundred bytes of metadata per font. Since some
    information like design sizes (oh, Adobe!) is stuffed away in
    Opentype tables, the vastly more efficient approach of
    fontloader.info() proves insufficient for indexing. Thus, we ended
    up using fontloader.open() which causes even the character tables
    to be parsed, which incidentally are responsible for most of the
    allocations during that peak of 1.4 GB measured above, along with
    the encodings:

        20.67% (293,781,048B) 0x6A8F72: SplineCharCreate (splineutil.c:3878)
        09.82% (139,570,318B) 0x618ACD: _FontViewBaseCreate (fontviewbase.c:84)
        08.77% (124,634,384B) 0x6A8FB3: SplineCharCreate (splineutil.c:3885)
        04.53% (64,436,904B) in 80 places, all below massif's threshold (1.00%)
        02.68% (38,071,520B) 0x64E14E: addKernPair (parsettfatt.c:493)
        01.04% (14,735,320B) 0x64DE7D: addPairPos (parsettfatt.c:452)
        39.26% (557,942,484B) 0x64A4E0: PsuedoEncodeUnencoded (parsettf.c:5706)

    What gives? For 2.7 we expect a rougher transition than a year back
    due to the complete revamp of the OT loading code. Breakage of
    fragile aspects like font and style names has been anticipated and
    addressed prior to the 2016 pretest release. In contrast to the
    earlier approach of letting FF do a complete dump and then harvest
    identifiers from the output we now have to coordinate with upstream
    as to which fields are actually needed in order to provide a
    similarly acceptable name → file lookup. On the bright side, these
    things are a lot simpler to fix than the rather tedious work of
    having users update their Luatex binary =)

--doc]]--

local lpeg                     = require "lpeg"
local P, lpegmatch         = lpeg.P, lpeg.match

local log                      = luaotfload.log
local logreport                = log and log.report or print -- overriden later on
local report_status            = log.names_status
local report_status_start      = log.names_status_start
local report_status_stop       = log.names_status_stop


--- Luatex builtins
local load                     = load
local next                     = next
local require                  = require
local tonumber                 = tonumber
local unpack                   = table.unpack

local fonts                    = fonts              or { }
do
    local fontshandlers        = fonts.handlers     or { }
    fonts.handlers             = fontshandlers
end
local otfhandler               = fonts.handlers.otf or { }

local gzipopen                 = gzip.open
local iolines                  = io.lines
local ioopen                   = io.open
local kpseexpand_path          = kpse.expand_path
local kpsefind_file            = kpse.find_file
local kpselookup               = kpse.lookup
local kpsereadable_file        = kpse.readable_file
local lfsattributes            = lfs.attributes
local lfschdir                 = lfs.chdir
local lfscurrentdir            = lfs.currentdir
local lfsdir                   = lfs.dir
local mathabs                  = math.abs
local mathmin                  = math.min
local osgetenv                 = os.getenv
local osgettimeofday           = os.gettimeofday
local osremove                 = os.remove
local dump                     = string.dump
local stringfind               = string.find
local stringformat             = string.format
local stringgmatch             = string.gmatch
local stringgsub               = string.gsub
local stringlower              = string.lower
local stringsub                = string.sub
local tableconcat              = table.concat
local tablesort                = table.sort
local utf8len                  = utf8.len
local utf8offset               = utf8.offset

--- these come from Lualibs/Context
local context_environment      = luaotfload.fontloader
local caches                   = context_environment.caches
local filebasename             = file.basename
local filedirname              = file.dirname
local fileextname              = file.extname
local fileiswritable           = file.iswritable
local filejoin                 = file.join
local filenameonly             = file.nameonly
local filereplacesuffix        = file.replacesuffix
local filesplitpath            = file.splitpath or file.split_path
local filesuffix               = file.suffix
local getwritablepath          = caches.getwritablepath
local lfsisdir                 = lfs.isdir
local lfsisfile                = lfs.isfile
local lfsmkdirs                = lfs.mkdirs
local lpegsplitat              = lpeg.splitat
local stringis_empty           = string.is_empty
local stringsplit              = string.split
local stringstrip              = string.strip
local tableappend              = table.append
local tablecontains            = table.contains
local tablecopy                = table.copy
local tablefastcopy            = table.fastcopy
local tabletofile              = table.tofile
local tableserialize           = table.serialize
local names                    = fonts and fonts.names or { }
local resolversfindfile        = context_environment.resolvers.findfile

--- some of our own
local unicode                  = require'luaotfload-unicode'
local casefold                 = require'lua-uni-case'.casefold
local alphnum_only             = unicode.alphnum_only

local name_index               = nil --> upvalue for names.data
local lookup_cache             = nil --> for names.lookups

--- string -> (string * string)
local function make_luanames (path)
    return filereplacesuffix(path, "lua"),
           filereplacesuffix(path, "luc")
end

local format_precedence = {
    "otf",  "ttc", "ttf", "afm", "pfb"
}

local location_precedence = {
    "local", "system", "texmf",
}
local enabled_locations = {
    ['local'] = true,
    system = true,
    texmf = true,
}

local function set_location_precedence (precedence)
    location_precedence = precedence
    for location in next, enabled_locations do
        enabled_locations[location] = nil
    end
    for _, location in ipairs(location_precedence) do
        enabled_locations[location] = location ~= 'local' or config.luaotfload.db.scan_local == true
    end
end

--[[doc--

    Auxiliary functions

--doc]]--

--- fontnames contain all kinds of garbage; as a precaution we
--- lowercase and strip them of non alphanumerical characters

--- string -> string

local macroman2utf8 do
    local mapping = {
      [0x80] = 0x00C4, [0x81] = 0x00C5, [0x82] = 0x00C7, [0x83] = 0x00C9,
      [0x84] = 0x00D1, [0x85] = 0x00D6, [0x86] = 0x00DC, [0x87] = 0x00E1,
      [0x88] = 0x00E0, [0x89] = 0x00E2, [0x8A] = 0x00E4, [0x8B] = 0x00E3,
      [0x8C] = 0x00E5, [0x8D] = 0x00E7, [0x8E] = 0x00E9, [0x8F] = 0x00E8,
      [0x90] = 0x00EA, [0x91] = 0x00EB, [0x92] = 0x00ED, [0x93] = 0x00EC,
      [0x94] = 0x00EE, [0x95] = 0x00EF, [0x96] = 0x00F1, [0x97] = 0x00F3,
      [0x98] = 0x00F2, [0x99] = 0x00F4, [0x9A] = 0x00F6, [0x9B] = 0x00F5,
      [0x9C] = 0x00FA, [0x9D] = 0x00F9, [0x9E] = 0x00FB, [0x9F] = 0x00FC,
      [0xA0] = 0x2020, [0xA1] = 0x00B0, [0xA2] = 0x00A2, [0xA3] = 0x00A3,
      [0xA4] = 0x00A7, [0xA5] = 0x2022, [0xA6] = 0x00B6, [0xA7] = 0x00DF,
      [0xA8] = 0x00AE, [0xA9] = 0x00A9, [0xAA] = 0x2122, [0xAB] = 0x00B4,
      [0xAC] = 0x00A8, [0xAD] = 0x2260, [0xAE] = 0x00C6, [0xAF] = 0x00D8,
      [0xB0] = 0x221E, [0xB1] = 0x00B1, [0xB2] = 0x2264, [0xB3] = 0x2265,
      [0xB4] = 0x00A5, [0xB5] = 0x00B5, [0xB6] = 0x2202, [0xB7] = 0x2211,
      [0xB8] = 0x220F, [0xB9] = 0x03C0, [0xBA] = 0x222B, [0xBB] = 0x00AA,
      [0xBC] = 0x00BA, [0xBD] = 0x03A9, [0xBE] = 0x00E6, [0xBF] = 0x00F8,
      [0xC0] = 0x00BF, [0xC1] = 0x00A1, [0xC2] = 0x00AC, [0xC3] = 0x221A,
      [0xC4] = 0x0192, [0xC5] = 0x2248, [0xC6] = 0x2206, [0xC7] = 0x00AB,
      [0xC8] = 0x00BB, [0xC9] = 0x2026, [0xCA] = 0x00A0, [0xCB] = 0x00C0,
      [0xCC] = 0x00C3, [0xCD] = 0x00D5, [0xCE] = 0x0152, [0xCF] = 0x0153,
      [0xD0] = 0x2013, [0xD1] = 0x2014, [0xD2] = 0x201C, [0xD3] = 0x201D,
      [0xD4] = 0x2018, [0xD5] = 0x2019, [0xD6] = 0x00F7, [0xD7] = 0x25CA,
      [0xD8] = 0x00FF, [0xD9] = 0x0178, [0xDA] = 0x2044, [0xDB] = 0x20AC,
      [0xDC] = 0x2039, [0xDD] = 0x203A, [0xDE] = 0xFB01, [0xDF] = 0xFB02,
      [0xE0] = 0x2021, [0xE1] = 0x00B7, [0xE2] = 0x201A, [0xE3] = 0x201E,
      [0xE4] = 0x2030, [0xE5] = 0x00C2, [0xE6] = 0x00CA, [0xE7] = 0x00C1,
      [0xE8] = 0x00CB, [0xE9] = 0x00C8, [0xEA] = 0x00CD, [0xEB] = 0x00CE,
      [0xEC] = 0x00CF, [0xED] = 0x00CC, [0xEE] = 0x00D3, [0xEF] = 0x00D4,
      [0xF0] = 0xF8FF, [0xF1] = 0x00D2, [0xF2] = 0x00DA, [0xF3] = 0x00DB,
      [0xF4] = 0x00D9, [0xF5] = 0x0131, [0xF6] = 0x02C6, [0xF7] = 0x02DC,
      [0xF8] = 0x00AF, [0xF9] = 0x02D8, [0xFA] = 0x02D9, [0xFB] = 0x02DA,
      [0xFC] = 0x00B8, [0xFD] = 0x02DD, [0xFE] = 0x02DB, [0xFF] = 0x02C7,
    }
    function macroman2utf8(s)
        local bytes = {string.byte(s, 1, -1)}
        for i=1,#bytes do
            bytes[i] = mapping[bytes[i]] or bytes[i]
        end
        return utf8.char(table.unpack(bytes))
    end
end
local function sanitize_fontname (str)
    if str ~= nil then
        str = utf8len(str) and str or macroman2utf8(str)
        str = alphnum_only(casefold(str, true))
        return str
    end
    return nil
end

local function sanitize_fontnames (rawnames)
    local result = { }
    for category, namedata in next, rawnames do

        if type (namedata) == "string" then
            namedata = utf8len(namedata) and namedata or macroman2utf8(namedata)
            result [category] = alphnum_only(casefold(namedata, true))
        else
            local target = { }
            for field, name in next, namedata do
                name = utf8len(name) and name or macroman2utf8(name)
                target [field] = alphnum_only(casefold(name, true))
            end
            result [category] = target
        end
    end
    return result
end

local function find_files_indeed (acc, dirs, filter)
    if not next (dirs) then --- done
        return acc
    end

    local pwd   = lfscurrentdir ()
    local dir   = dirs[#dirs]
    dirs[#dirs] = nil

    if lfschdir (dir) then
        lfschdir (pwd)

        local newfiles = { }
        for ent in lfsdir (dir) do
            if ent ~= "." and ent ~= ".." then
                local fullpath = dir .. "/" .. ent
                if filter (fullpath) == true then
                    if lfsisdir (fullpath) then
                        dirs[#dirs+1] = fullpath
                    elseif lfsisfile (fullpath) then
                        newfiles[#newfiles+1] = fullpath
                    end
                end
            end
        end
        return find_files_indeed (tableappend (acc, newfiles),
                                  dirs, filter)
    end
    --- could not cd into, so we skip it
    return find_files_indeed (acc, dirs, filter)
end

local function dummyfilter () return true end

--- the optional filter function receives the full path of a file
--- system entity. a filter applies if the first argument it returns is
--- true.

--- string -> function? -> string list
local function find_files (root, filter)
    if lfsisdir (root) then
        return find_files_indeed ({}, { root }, filter or dummyfilter)
    end
end


--[[doc--
This is a sketch of the luaotfload db:

    type dbobj = {
        families    : familytable;
        fontnames   : fontnametable;
        files       : filemap;
        status      : filestatus;
        mappings    : fontentry list;
        meta        : metadata;
    }
    and familytable = {
        local  : (format, familyentry) hash; // specified with include dir
        texmf  : (format, familyentry) hash;
        system : (format, familyentry) hash;
    }
    and familyentry = {
        r  : sizes; // regular
        i  : sizes; // italic
        b  : sizes; // bold
        bi : sizes; // bold italic
    }
    and sizes = {
        default : int;              // points into mappings or names
        optical : (int, int) list;  // design size -> index entry
    }
    and fontnametable = {
        local  : (format, index) hash;
        texmf  : (format, index) hash;
        system : (format, index) hash;
    }
    and metadata = {
        created     : string       // creation time
        formats     : string list; // { "otf", "ttf", "ttc" }
        local       : bool;        (* set if local fonts were added to the db *)
        modified    : string       // modification time
        statistics  : TODO;        // created when built with "--stats"
        version     : float;       // index version
    }
    and filemap = { // created by generate_filedata()
        base : {
            local  : (string, int) hash; // basename -> idx
            system : (string, int) hash;
            texmf  : (string, int) hash;
        };
        bare : {
            local  : (string, (string, int) hash) hash; // location -> (barename -> idx)
            system : (string, (string, int) hash) hash;
            texmf  : (string, (string, int) hash) hash;
        };
        full : (int, string) hash; // idx -> full path
    }
    and fontentry = { // finalized by collect_families()
        basename             : string;   // file name without path "foo.otf"
        conflicts            : { barename : int; basename : int }; // filename conflict with font at index; happens with subfonts
        familyname           : string;   // sanitized name of the font family the font belongs to, usually from the names table
        fontname             : string;   // sanitized name of the font
        format               : string;   // "otf" | "ttf" | "afm" (* | "pfb" *)
        fullname             : string;   // sanitized full name of the font including style modifiers
        fullpath             : string;   // path to font in filesystem
        index                : int;      // index in the mappings table
        italicangle          : float;    // italic angle; non-zero with oblique faces
        location             : string;   // "texmf" | "system" | "local"
        plainname            : string;   // unsanitized font name
        typographicsubfamily : string;   // sanitized preferred subfamily (names table 14)
        psname               : string;   // PostScript name
        size                 : (false | float * float * float);  // if available, size info from the size table converted from decipoints
        subfamily            : string;   // sanitized subfamily (names table 2)
        subfont              : (int | bool);     // integer if font is part of a TrueType collection ("ttc")
        version              : string;   // font version string
        weight               : int;      // usWeightClass
    }
    and filestatus = (string,       // fullname
                      { index       : int list; // pointer into mappings
                        timestamp   : int;      }) dict

beware that this is a reconstruction and may be incomplete or out of
date. Last update: 2014-04-06, describing version 2.51.

mtx-fonts has in names.tma:

    type names = {
        cache_uuid    : uuid;
        cache_version : float;
        datastate     : uuid list;
        fallbacks     : (filetype, (basename, int) hash) hash;
        families      : (basename, int list) hash;
        files         : (filename, fullname) hash;
        indices       : (fullname, int) hash;
        mappings      : (filetype, (basename, int) hash) hash;
        names         : ? (empty hash) ?;
        rejected      : (basename, int) hash;
        specifications: fontentry list;
    }
    and fontentry = {
        designsize    : int;
        familyname    : string;
        filename      : string;
        fontname      : string;
        format        : string;
        fullname      : string;
        maxsize       : int;
        minsize       : int;
        modification  : int;
        rawname       : string;
        style         : string;
        subfamily     : string;
        variant       : string;
        weight        : string;
        width         : string;
    }

--doc]]--

--- string list -> string option -> dbobj

local function initialize_namedata (formats, created)
    local now = os.date "%Y-%m-%d %H:%M:%S" --- i. e. "%F %T" on POSIX systems
    return {
        status          = { }, -- was: status; map abspath -> mapping
        mappings        = { }, -- TODO: check if still necessary after rewrite
        files           = { }, -- created later
        meta            = {
            created    = created or now,
            formats    = formats,
            ["local"]  = false,
            modified   = now,
            statistics = { },
            version    = names.version,
        },
    }
end

-- A helper to load a file which might be gziped
local function load_maybe_gzip (path, binary)
    local gzippath = path .. '.gz'
    local f = ioopen (gzippath, 'rb')
    if f then
        path = gzippath
        local result = f:read'*a'
        result = gzip.decompress(result, 31)
        f:close()
        return path, result
    else
        f, msg = ioopen (path, binary and 'rb' or 'r')
        if f then
            local result = f:read'*a'
            f:close()
            return path, result
        end
    end

    return nil, msg
end

--- When loading a lua file we try its binary complement first, which
--- is assumed to be located at an identical path, carrying the suffix
--- .luc.

--- string -> string -> (string * table)
local function load_lua_file (path_lua, path_luc)
    local foundname, chunk = load_maybe_gzip (path_luc, true)
    if foundname then
        chunk = load (chunk, 'b')
    else
        chunk = nil
    end
    if not chunk then
        foundname, chunk = load_maybe_gzip (path_lua, false)
        if foundname then
            chunk = assert (load (chunk, 't'))
        else
            return nil
        end
    end

    return foundname, chunk()
end

--- define locals in scope
local get_font_filter
local lookup_font_name
local reload_db
local lookup_fullpath
local save_lookups
local save_names
local set_font_filter
local update_names

--- state of the database
local fonts_reloaded = false

--- limit output when approximate font matching (luaotfload-tool -F)
local fuzzy_limit = 1 --- display closest only

--- bool? -> -> bool? -> dbobj option
local function load_names (dry_run, no_rebuild)
    local starttime = osgettimeofday ()
    local foundname, data = load_lua_file (config.luaotfload.paths.index_path_lua,
                                           config.luaotfload.paths.index_path_luc)

    if data then
        logreport ("log", 0, "db",
                   "Font names database loaded from %s", foundname)
        logreport ("term", 3, "db",
                   "Font names database loaded from %s", foundname)
        logreport ("info", 3, "db", "Loading took %0.f ms.",
                   1000 * (osgettimeofday () - starttime))

        local db_version, names_version
        if data.meta then
            db_version = data.meta.version
        else
            --- Compatibility branch; the version info used to be
            --- stored in the table root which is why updating from
            --- an earlier index version broke.
            db_version = data.version or -42 --- invalid
        end
        names_version = names.version
        if db_version ~= names_version then
            if math.tointeger(db_version) then
                logreport ("both", 0, "db",
                           [[Version mismatch; expected %d, got %d.]],
                           names_version, db_version)
            else
                logreport ("both", 0, "db",
                           [[Version mismatch; expected %d, got invalid data.]],
                           names_version, db_version)
            end
            if not fonts_reloaded then
                logreport ("both", 0, "db", [[Force rebuild.]])
                data = update_names (initialize_namedata (get_font_filter ()),
                                     true, false)
                if not data then
                    logreport ("both", 0, "db",
                               "Database creation unsuccessful.")
                end
            end
        end
    else
        if no_rebuild == true then
            logreport ("both", 2, "db",
                       [[Database does not exist, skipping rebuild though.]])
            return false
        end
        logreport ("both", 0, "db",
                   [[Font names database not found, generating new one.]])
        logreport ("both", 0, "db",
                   [[This can take several minutes; please be patient.]])
        data = update_names (initialize_namedata (get_font_filter ()),
                             nil, dry_run)
        if not data then
            logreport ("both", 0, "db", "Database creation unsuccessful.")
        end
    end
    return data
end

--[[doc--

    access_font_index -- Provide a reference of the index table. Will
    cause the index to be loaded if not present.

--doc]]--

local function access_font_index ()
    if not name_index then name_index = load_names () end
    return name_index
end

local function getmetadata ()
    if not name_index then
        name_index = load_names (false, true)
        if name_index then return tablefastcopy (name_index.meta) end
    end
    return false
end

--- unit -> unit
local function load_lookups ( )
    local foundname, data = load_lua_file(config.luaotfload.paths.lookup_path_lua,
                                          config.luaotfload.paths.lookup_path_luc)
    if data then
        logreport ("log", 0, "cache", "Lookup cache loaded from %s.", foundname)
        logreport ("term", 3, "cache",
                   "Lookup cache loaded from %s.", foundname)
    else
        logreport ("both", 1, "cache",
                   "No lookup cache, creating empty.")
        data = { }
    end
    lookup_cache = data
end

local regular_synonym = {
    book    = 0,
    normal  = 0,
    plain   = 0,
    regular = 0,
    roman   = 0,
    medium  = 1000, -- Some font authors haven't got the memo that medium is not regular
}

local style_synonym = {
    oblique = 'i',
    slanted = 'i',
    italic  = 'i',
    boldoblique = 'bi',
    boldslanted = 'bi',
    bolditalic  = 'bi',
    bold = 'b',
}

-- MK Determine if casefold search is requested
local casefold_search =
    not ({['0'] = true, ['f'] = true, [''] = true})
        [(kpse.var_value'texmf_casefold_search' or '1'):sub(1,1)]
-- /MK

local function lookup_filename (filename)
    if not name_index then name_index = load_names () end
    local files    = name_index.files
    local basedata = files.base
    local baredata = files.bare
    for i = 1, #location_precedence do
        local location = location_precedence [i]
        local basenames = basedata [location]
        local barenames = baredata [location]
        local idx
        if basenames ~= nil then
            -- MK Added fallback
            idx = basenames [filename]
               or casefold_search and basenames [stringlower(filename)]
            -- /MK
            if idx then
                goto done
            end
        end
        if barenames ~= nil then
            for j = 1, #format_precedence do
                local format  = format_precedence [j]
                local filemap = barenames [format]
                if filemap then
                    -- MK Added fallback
                    idx = barenames [format] [filename]
                       or casefold_search and barenames [format] [stringlower(filename)]
                    -- /MK
                    if idx then
                        break
                    end
                end
            end
        end
::done::
        if idx then
            return files.full [idx]
        end
    end
end

--[[doc--

    lookup_font_file -- The ``file:`` are ultimately delegated here.
    The lookups are kind of a blunt instrument since they try locating
    the file using every conceivable method, which is quite
    inefficient. Nevertheless, resolving files that way is rarely the
    bottleneck.

--doc]]--

--- string -> string * string * bool
local lookup_font_file

-- MK Added mini scope to avoid variable limit
do
local type1_metrics = { "tfm", "ofm", }
-- /MK

function lookup_font_file (filename)
    local found = lookup_filename (filename)

    if found and not lfsisfile(found) then
        found = nil
    end

    if not found then
        local type = file.suffix(filename)
        if type ~= "" then
            found = resolversfindfile(filename, type)
        end
    end

    if found then
        return found, nil, true
    end

    for i=1, #type1_metrics do
        local format = type1_metrics[i]
        if resolversfindfile(filename, format) then
            return file.addsuffix(filename, format), format, true
        end
    end

    if not fonts_reloaded and config.luaotfload.db.update_live == true then
        return reload_db (stringformat ("File not found: %q.", filename),
                          lookup_font_file,
                          filename)
    end
    return filename, nil, false
end
-- MK
end
-- /MK

--[[doc--

    get_font_file -- Look up the file of an entry in the mappings
    table. If the index is valid, pass on the name and subfont index
    after verifing the existence of the resolved file. This
    verification differs depending the index entry’s ``location``
    field:

        * ``texmf`` fonts are verified using the (slow) function
          ``kpse.lookup()``;
        * other locations are tested by resolving the full path and
          checking for the presence of a file there.

--doc]]--

--- int -> bool * (string * int) option
local function get_font_file (index)
    local entry = name_index.mappings [index]
    if not entry then
        return false
    end
    local basename = entry.basename
    if entry.location == "texmf" then
        local fullname = resolversfindfile(basename, entry.format)
        if fullname then
            return true, fullname, entry.subfont
        end
    else --- system, local
        local fullname = name_index.files.full [index]
        if lfsisfile (fullname) then
            return true, fullname, entry.subfont
        end
    end
    return false
end

--[[doc--
We need to verify if the result of a cached lookup actually exists in
the texmf or filesystem. Again, due to the schizoprenic nature of the
font managment we have to check both the system path and the texmf.
--doc]]--

local function verify_font_file (basename)
    local path = lookup_fullpath (basename)
    if path and lfsisfile(path) then
        return true
    end
    if resolversfindfile(basename) then
        return true
    end
    return false
end

--[[doc--
Lookups can be quite costly, more so the less specific they are.
Even if we find a matching font eventually, the next time the
user compiles Eir document E will have to stand through the delay
again.
Thus, some caching of results -- even between runs -- is in order.
We’ll just store successful name: lookups in a separate cache file.

type lookup_cache = (string, (string * num)) dict

The spec is expected to be modified in place (ugh), so we’ll have to
catalogue what fields actually influence its behavior.

Idk what the “spec” resolver is for.

        lookup      inspects            modifies
        ----------  -----------------   ---------------------------
        file:       name                forced, name
        name:[*]    name, style, sub,   resolved, sub, name, forced
                    optsize, size
        spec:       name, sub           resolved, sub, name, forced

[*] name: contains both the name resolver from luatex-fonts and
    lookup_font_name () below

From my reading of font-def.lua, what a resolver does is
basically rewrite the “name” field of the specification record
with the resolution.
Also, the fields “resolved”, “sub”, “force” etc. influence the outcome.

--doc]]--

local hash_request do
    local concat_char = "#"
    local hash_fields = {
        --- order is important
        "specification", "style", "sub", "optsize", "size",
    }
    local n_hash_fields = #hash_fields

    --- spec -> string
    function hash_request (specification)
        local key = { } --- segments of the hash
        for i=1, n_hash_fields do
            local field = specification[hash_fields[i]]
            if field then
                key[#key+1] = field
            end
        end
        return tableconcat(key, concat_char)
    end
end

--- 'a -> 'a -> table -> (string * int|boolean * boolean)
local function lookup_font_name_cached (specification)
    if not lookup_cache then load_lookups () end
    local request = hash_request(specification)
    logreport ("both", 4, "cache", "Looking for %q in cache ...",
               request)

    local found = lookup_cache [request]

    --- case 1) cache positive ----------------------------------------
    if found then --- replay fields from cache hit
        logreport ("info", 4, "cache", "Found!")
        local basename = found[1]
        --- check the presence of the file in case it’s been removed
        local success = verify_font_file (basename)
        if success == true then
            return basename, found[2], true
        end
        logreport ("both", 4, "cache",
                   "Cached file not found; resolving again.")
    else
        logreport ("both", 4, "cache", "Not cached; resolving.")
    end

    --- case 2) cache negative ----------------------------------------
    --- first we resolve normally ...
    local filename, subfont = lookup_font_name (specification)
    if not filename then
        return nil, nil
    end
    --- ... then we add the fields to the cache ... ...
    local entry = { filename, subfont }
    logreport ("both", 4, "cache", "New entry: %s.", request)
    lookup_cache [request] = entry

    --- obviously, the updated cache needs to be stored.
    --- TODO this should trigger a save only once the
    ---      document is compiled (finish_pdffile callback?)
    logreport ("both", 5, "cache", "Saving updated cache.")
    local success = save_lookups ()
    if not success then --- sad, but not critical
        logreport ("both", 0, "cache", "Error writing cache.")
    end
    return filename, subfont
end

--- this used to be inlined; with the lookup cache we don’t
--- have to be parsimonious wrt function calls anymore
--- “found” is the match accumulator
local function add_to_match (found, size, face)

    local continue = true

    local optsize = face.size

    if optsize and next (optsize) then
        local dsnsize, maxsize, minsize
        dsnsize = optsize[1]
        maxsize = optsize[2]
        minsize = optsize[3]

        if size ~= nil
        and (dsnsize == size or (size > minsize and size <= maxsize))
        then
            found[1] = face
            continue = false ---> break
        else
            found[#found+1] = face
        end
    else
        found[1] = face
        continue = false ---> break
    end

    return found, continue
end

local function choose_closest (distances)
    local closest = 2^51
    local match
    for i = 1, #distances do
        local d, index = unpack (distances [i])
        if d < closest then
            closest = d
            match   = index
        end
    end
    return match
end

--[[doc--

    choose_size -- Pick a font face of appropriate size (in sp) from
    the list of family members with matching style. There are three
    categories:

        1. exact matches: if there is a face whose design size equals
           the asked size, it is returned immediately and no further
           candidates are inspected.

        2. range matches: of all faces in whose design range the
           requested size falls the one whose center the requested
           size is closest to is returned.

        3. out-of-range matches: of all other faces (i. e. whose range
           is above or below the asked size) the one is chosen whose
           boundary (upper or lower) is closest to the requested size.

        4. default matches: if no design size or a design size of zero
           is requested, the face with the default size is returned.

--doc]]--

--- int * int * int * int list -> int -> int
local function choose_size (sizes, askedsize)
    local inrange  = { } --- distance * index list
    local norange  = { } --- distance * index list
    if askedsize ~= 0 then
        --- firstly, look for an exactly matching design size or
        --- matching range
        for i = 1, #sizes do
            local dsnsize, high, low, index = unpack (sizes [i])
            if dsnsize == askedsize then
                --- exact match, this is what we were looking for
                return index
            elseif askedsize <= low then
                --- below range, add to the norange table
                local d = low - askedsize
                norange [#norange + 1] = { d, index }
            elseif askedsize > high then
                --- beyond range, add to the norange table
                local d = askedsize - high
                norange [#norange + 1] = { d, index }
            else
                --- range match
                local d = 0

                -- should always be true. Just in case there's some
                -- weried fonts out there
                if dsnsize > low and dsnsize < high then
                    d = dsnsize - askedsize
                else
                    d = ((low + high) / 2) - askedsize
                end
                if d < 0 then
                    d = -d
                end

                inrange [#inrange + 1] = { d, index }
            end
        end
    end
::skip::
    if #inrange > 0 then
        return choose_closest (inrange)
    elseif #norange > 0 then
        return choose_closest (norange)
    elseif sizes.default then
        return sizes.default
    elseif askedsize == 0 then
        return choose_size(sizes, 655360) -- If there is no default size and no size specified, just guess
    end
end

--[[doc--

    lookup_familyname -- Query the families table for an entry
    matching the specification.
    The parameters “name” and “style” are pre-sanitized.

--doc]]--
--- spec -> string -> string -> int -> string * int * bool
local function lookup_familyname (specification, name, style, askedsize)
    local families   = name_index.families
    local candidates = nil
    local fallback   = true
    --- arrow code alert
    for i = 1, #location_precedence do
        local location = location_precedence [i]
        local locgroup = families [location]
        for j = 1, #format_precedence do
            local format       = format_precedence [j]
            local fmtgroup     = locgroup [format]
            if fmtgroup then
                local familygroup  = fmtgroup [name]
                if familygroup then
                    local stylegroup = familygroup [style]
                    if stylegroup then --- suitable match
                        candidates = stylegroup
                        fallback = false
                        goto done
                    elseif not candidates then
                        candidates = familygroup.r
                    end
                end
            end
        end
    end
    if not candidates then
        return nil, nil
    end
::done::
    index = choose_size (candidates, askedsize)
    local success, resolved, subfont = get_font_file (index)
    if not success then
        return nil, nil
    end
    logreport ("info", 2, "db", "Match found: %s(%d).",
               resolved, subfont or 0)
    return resolved, subfont, fallback
end

local function lookup_fontname (specification, name)
    local fontnames  = name_index.fontnames
    --- arrow code alert
    for i = 1, #location_precedence do
        local location = location_precedence [i]
        local locgroup = fontnames [location]
        for j = 1, #format_precedence do
            local format   = format_precedence [j]
            local fmtgroup = locgroup [format]
            if fmtgroup then
                local index = fmtgroup [name]
                if index then
                    local success, resolved, subfont = get_font_file (index)
                    if success then
                        return resolved, subfont
                    end
                end
            end
        end
    end
end

local design_size_dimension  --- scale asked size if not using bp
local set_size_dimension     --- called from config
do

    --- cf. TeXbook p. 57; the index stores sizes pre-scaled from bp to
    --- sp. This allows requesting sizes we got from the TeX end
    --- without further conversion. For the other options *pt* and *dd*
    --- we scale the requested size as though the value in the font was
    --- specified in the requested unit.

    --- From @zhouyan:

    --- Let P be the asked size in pt, and Aᵤ = CᵤP, where u is the
    --- designed unit, pt, bp, or dd, and
    --- 
    ---        Cpt = 1,    Cbp = 7200/7227,      Cdd = 1157/1238.
    --- 
    --- That is, Aᵤ is the asked size in the desired unit. Let D be the
    --- de-sign size (assumed to be in the unit of bp) as reported by
    --- the font (divided by 10; in all the following we ignore the
    --- factor 2^16 ).
    --- 
    --- For simplicity, consider only the case of exact match to the
    --- design size. That is, we would like to have Aᵤ = D. Let A′ᵤ = αᵤP
    --- and D′ = βD be the scaled values used in comparisons. For the
    --- comparison to work correctly, we need,
    --- 
    ---         Aᵤ = D  ⟺  A′ᵤ = D′ ,
    --- 
    --- and thus αᵤ = βCᵤ. The fix in PR 400 is the case of β = 1. The
    --- fix for review is β = 7227/7200, and the value of αᵤ is thus
    --- correct for pt, bp, but not for dd.

    local dimens = {
        bp = false,
        pt = 7227 / 7200,
        dd = (7227 / 7200) * (1157 / 1238),
    }

    design_size_dimension = dimens.bp

    function set_size_dimension (dim)
        local conv = dimens [dim]
        if conv ~= nil then
            logreport ("both", 4, "db",
                       "Interpreting design sizes as %q, factor %.6f.",
                       dim, conv or 1)
            design_size_dimension = conv
            return
        end
        logreport ("both", 0, "db",
                   "Invalid dimension %q requested for design sizes; \z
                    ignoring.")
    end
end


--[[doc--

    lookup_font_name -- Perform a name: lookup. This first queries the
    font families table and, if there is no match for the spec, the
    font names table.
    The return value is a pair consisting of the file name and the
    subfont index if appropriate..

    the request specification has the fields:

      · features: table
        · normal: set of { ccmp clig itlc kern liga locl mark mkmk rlig }
        · ???
      · forced:   string
      · lookup:   "name"
      · method:   string
      · name:     string
      · resolved: string
      · size:     int
      · specification: string (== <lookup> ":" <name>)
      · sub:      string

    The “size” field deserves special attention: if its value is
    negative, then it actually specifies a scalefactor of the
    design size of the requested font. This happens e.g. if a font is
    requested without an explicit “at size”. If the font is part of a
    larger collection with different design sizes, this complicates
    matters a bit: Normally, the resolver prefers fonts that have a
    design size as close as possible to the requested size. If no
    size specified, then the design size is implied. But which design
    size should that be? Xetex appears to pick the “normal” (unmarked)
    size: with Adobe fonts this would be the one that is neither
    “caption” nor “subhead” nor “display” &c ... For fonts by Adobe this
    seems to be the one that does not receive a “typographicsubfamily”
    field. (IOW Adobe uses the “typographicsubfamily” field to encode
    the design size in more or less human readable format.) However,
    this is not true of LM and EB Garamond. As this matters only where
    there are multiple design sizes to a given font/style combination,
    we put a workaround in place that chooses that unmarked version.

    The first return value of “lookup_font_name” is the file name of the
    requested font (string). It can be passed to the fullname resolver
    get_font_file().
    The second value is either “false” or an integer indicating the
    subfont index in a TTC.

--doc]]--

--- table -> string * (int | bool)
function lookup_font_name (specification)
    if not name_index then name_index = load_names () end
    local name      = sanitize_fontname (specification.name)
    local style     = sanitize_fontname (specification.style) or "r"
    local askedsize = specification.optsize

    if askedsize then
        askedsize = tonumber (askedsize) * 65536
    else
        askedsize = specification.size
        if not askedsize or askedsize < 0 then
            askedsize = 0
        end
    end

    if design_size_dimension ~= false then
        askedsize = design_size_dimension * askedsize
    end

    local resolved, subfont, fallback = lookup_familyname (specification,
                                                           name,
                                                           style,
                                                           askedsize)
    if not resolved or fallback then
        local new_resolved, new_subfont = lookup_fontname (specification,
                                                           name,
                                                           style)
        if new_resolved then
            resolved, subfont = new_resolved, new_subfont
        end
    end

    if not resolved then
        if not fonts_reloaded and config.luaotfload.db.update_live == true then
            return reload_db (stringformat ("Font %q not found.",
                                            specification.name or "<?>"),
                              lookup_font_name,
                              specification)
        end
    end
    return resolved, subfont
end

function lookup_fullpath (fontname, ext) --- getfilename()
    if not name_index then name_index = load_names () end
    local files = name_index.files
    local basedata = files.base
    local baredata = files.bare
    for i = 1, #location_precedence do
        local location = location_precedence [i]
        local basenames = basedata [location]
        local idx
        if basenames ~= nil then
            -- MK Added fallback
            idx = basenames [fontname]
               or casefold_search and basenames [stringlower(fontname)]
            -- /MK
        end
        if ext then
            local barenames = baredata [location] [ext]
            if not idx and barenames ~= nil then
                -- MK Added fallback
                idx = barenames [fontname]
                   or casefold_search and barenames [stringlower(fontname)]
                -- /MK
            end
        end
        if idx then
            return files.full [idx]
        end
    end
    return ""
end

--- when reload is triggered we update the database
--- and then re-run the caller with the arg list

--- string -> ('a -> 'a) -> 'a list -> 'a
function reload_db (why, caller, ...)
    local namedata  = name_index
    local formats   = tableconcat (namedata.meta.formats, ",")

    logreport ("both", 0, "db",
               "Reload initiated (formats: %s); reason: %s",
               formats, why)

    set_font_filter (formats)
    namedata = update_names (namedata, false, false)

    if namedata then
        fonts_reloaded = true
        name_index = namedata
        return caller (...)
    end

    logreport ("both", 0, "db", "Database update unsuccessful.")
end

--- string -> string -> int
local function iterative_levenshtein (s1, s2)

  local costs = { }
  local len1, len2 = #s1, #s2

  for i = 0, len1 do
    local last = i
    for j = 0, len2 do
      if i == 0 then
        costs[j] = j
      else
        if j > 0 then
          local current = costs[j-1]
          if stringsub(s1, i, i) ~= stringsub(s2, j, j) then
            current = mathmin(current, last, costs[j]) + 1
          end
          costs[j-1] = last
          last = current
        end
      end
    end
    if i > 0 then costs[len2] = last end
  end

  return costs[len2]--- lower right has the distance
end

--- string list -> string list
local function delete_dupes (lst)
    local n0 = #lst
    if n0 == 0 then return lst end
    tablesort (lst)
    local ret = { }
    local last
    for i = 1, n0 do
        local cur = lst[i]
        if cur ~= last then
            last = cur
            ret[#ret + 1] = cur
        end
    end
    logreport (false, 8, "query",
               "Removed %d duplicate names.", n0 - #ret)
    return ret
end

--- string -> int -> bool
local function find_closest (name, limit)
    local name     = sanitize_fontname (name)
    limit          = limit or fuzzy_limit

    if not name_index then name_index = load_names () end
    if not name_index or type (name_index) ~= "table" then
        if not fonts_reloaded then
            return reload_db("Font index missing.", find_closest, name)
        end
        return false
    end

    local by_distance   = { } --- (int, string list) dict
    local distances     = { } --- int list
    local cached        = { } --- (string, int) dict
    local mappings      = name_index.mappings
    local n_fonts       = #mappings

    for n = 1, n_fonts do
        local current    = mappings[n]
        --[[
            This is simplistic but surpisingly fast.
            Matching is performed against the “fullname” field
            of a db record in preprocessed form. We then store the
            raw “fullname” at its edit distance.
            We should probably do some weighting over all the
            font name categories as well as whatever agrep
            does.
        --]]
        local fullname  = current.plainname
        local sfullname = current.fullname
        local dist      = cached[sfullname]--- maybe already calculated

        if not dist then
            dist = iterative_levenshtein(name, sfullname)
            cached[sfullname] = dist
        end
        local namelst = by_distance[dist]
        if not namelst then --- first entry
            namelst = { fullname }
            distances[#distances+1] = dist
        else --- append
            namelst[#namelst+1] = fullname
        end

        by_distance[dist] = namelst
    end

    --- print the matches according to their distance
    local n_distances = #distances
    if n_distances > 0 then --- got some data
        tablesort(distances)
        limit = mathmin(n_distances, limit)
        logreport (false, 1, "query",
                   "Displaying %d distance levels.", limit)

        for i = 1, limit do
            local dist     = distances[i]
            local namelst  = delete_dupes (by_distance[dist])
            logreport (false, 0, "query",
                       "Distance from %q: %s\n    "
                       .. tableconcat (namelst, "\n    "),
                       name, dist)
        end

        return true
    end
    return false
end --- find_closest()

--- string -> uint -> bool * (string | rawdata)
local function read_font_file (filename, subfont)
    local fontdata = otfhandler.readers.getinfo (filename,
                                                 { subfont        = subfont
                                                 , platformnames  = true
                                                 , rawfamilynames = true
                                                 })
    local msg = fontdata.comment
    if msg then
        return false, msg
    end
    return true, fontdata
end

local function load_font_file (filename, subfont)
    local err, ret = read_font_file (filename, subfont)
    if err == false then
        logreport ("both", 1, "db", "ERROR: failed to open %q: %q.",
                   tostring (filename), tostring (ret))
        return
    end
    return ret
end

--- Design sizes in the fonts are specified in decipoints. For the
--- index these values are prescaled to sp which is what we’re dealing
--- with at the TeX end.

local get_size_info do --- too many upvalues :/
    --- rawdata -> (int * int * int | bool)

    local sp = 2^16        -- pt
    local bp = 7227 / 7200 -- pt

    function get_size_info (rawinfo)
        local design_size         = rawinfo.design_size
        local design_range_top    = rawinfo.design_range_top
        local design_range_bottom = rawinfo.design_range_bottom

        local fallback_size = design_size         ~= 0 and design_size
                           or design_range_bottom ~= 0 and design_range_bottom
                           or design_range_top    ~= 0 and design_range_top

        if fallback_size then
            design_size         = ((design_size         or fallback_size) * sp) / 10
            design_range_top    = ((design_range_top    or fallback_size) * sp) / 10
            design_range_bottom = ((design_range_bottom or fallback_size) * sp) / 10

            design_size         = design_size         * bp
            design_range_top    = design_range_top    * bp
            design_range_bottom = design_range_bottom * bp

            return {
                design_size, design_range_top, design_range_bottom,
            }
        end

        return false
    end
end ---[local get_size_info]

--[[doc--
    map_enlish_names -- Names-table for Lua fontloader objects. This
    may vanish eventually once we ditch Fontforge completely. Only
    subset of entries of that table are actually relevant so we’ll
    stick to that part.
--doc]]--

local function get_english_names (metadata)
    local namesource
    local platformnames = metadata.platformnames
    --[[--
        Hans added the “platformnames” option for us to access parts of
        the original name table. The names are unreliable and
        completely disorganized, sure, but the Windows variant of the
        field often contains the superior information. Case in point:

          ["platformnames"]={
           ["macintosh"]={
            ["compatiblefullname"]="Garamond Premr Pro Smbd It",
            ["family"]="Garamond Premier Pro",
            ["fullname"]="Garamond Premier Pro Semibold Italic",
            ["postscriptname"]="GaramondPremrPro-SmbdIt",
            ["subfamily"]="Semibold Italic",
           },
           ["windows"]={
            ["family"]="Garamond Premr Pro Smbd",
            ["fullname"]="GaramondPremrPro-SmbdIt",
            ["postscriptname"]="GaramondPremrPro-SmbdIt",
            ["subfamily"]="Italic",
            ["typographicfamily"]="Garamond Premier Pro",
            ["typographicsubfamily"]="Semibold Italic",
           },
          },

        The essential bit is contained as “typographicfamily” (which we
        call for historical reasons the “preferred family”) and the
        “subfamily”. Only  Why this is the case, only Adobe knows for
        certain.
    --]]--
    if platformnames then
        if platformnames.windows and platformnames.macintosh then
            return table.merge(platformnames.macintosh, platformnames.windows)
        end
        namesource = platformnames.windows or platformnames.macintosh
    end
    return namesource or metadata
end

--[[--
    In case of broken PS names we set some dummies.

    For this reason we copy what is necessary whilst keeping the table
    structure the same as in the tfmdata.
--]]--
local function get_raw_info (metadata, basename)
    local fontname = metadata.fontname
    local fullname = metadata.fullname

    if not fontname or not fullname then
        --- Broken names table, e.g. avkv.ttf with UTF-16 strings;
        --- we put some dummies in place like the fontloader
        --- (font-otf.lua) does.
        logreport ("both", 3, "db",
                   "Invalid names table of font %s, using dummies. \z
                    Reported: fontname=%q, fullname=%q.",
                   tostring (basename), tostring (fontname),
                   tostring (fullname))
        fontname = "bad-fontname-" .. basename
        fullname = "bad-fullname-" .. basename
    end

    return {
        familyname          = metadata.familyname,
        fontname            = fontname,
        fullname            = fullname,
        italicangle         = metadata.italicangle,
        names               = metadata.names,
        units_per_em        = metadata.units_per_em,
        version             = metadata.version,
        design_size         = metadata.design_size         or metadata.designsize,
        design_range_top    = metadata.design_range_top    or metadata.maxsize,
        design_range_bottom = metadata.design_range_bottom or metadata.minsize,
    }
end

local function organize_namedata (rawinfo,
                                  nametable,
                                  basename,
                                  info)
    local default_name = nametable.compatiblefullname
                      or nametable.fullname
                      or nametable.postscriptname
                      or rawinfo.fullname
                      or rawinfo.fontname
                      or info.fullname
                      or info.fontname
    local default_family = nametable.typographicfamily
                        or nametable.family
                        or rawinfo.familyname
                        or info.familyname
    local fontnames = {
        --- see
        --- https://developer.apple.com/fonts/TTRefMan/RM06/Chap6name.html
        --- http://www.microsoft.com/typography/OTSPEC/name.htm#NameIDs
        english = {
            --- where a “compatiblefullname” field is given, the value
            --- of “fullname” is either identical or differs by
            --- separating the style with a hyphen and omitting spaces.
            --- (According to the spec, “compatiblefullname” is
            --- “Macintosh only”.) Of the three “fullname” fields, this
            --- one appears to be the one with the entire name given in
            --- a legible, non-abbreviated fashion, for most fonts at
            --- any rate. However, in some fonts (e.g. CMU) all three
            --- fields are identical.
            fullname      = --[[ 18 ]] nametable.compatiblefullname
                         or --[[  4 ]] nametable.fullname
                         or default_name,
            --- we keep both the “preferred family” and the “family”
            --- values around since both are valid but can turn out
            --- quite differently, e.g. with Latin Modern:
            ---     typographicfamily: “Latin Modern Sans”,
            ---     family:     “LM Sans 10”
            family               = --[[  1 ]] nametable.family or default_family,
            subfamily            = --[[  2 ]] nametable.subfamily or rawinfo.subfamilyname,
            psname               = --[[  6 ]] nametable.postscriptname,
            typographicfamily    = --[[ 16 ]] nametable.typographicfamily,
            typographicsubfamily = --[[ 17 ]] nametable.typographicsubfamily,
        },

        metadata = {
            fullname      = rawinfo.fullname,
            fontname      = rawinfo.fontname,
            familyname    = rawinfo.familyname,
        },

        info = {
            fullname      = info.fullname,
            familyname    = info.familyname,
            fontname      = info.fontname,
        },
    }

    return {
        sanitized     = sanitize_fontnames (fontnames),
        fontname      = rawinfo.fontname,
        fullname      = rawinfo.fullname,
        familyname    = rawinfo.familyname,
    }
end


local dashsplitter = lpegsplitat "-"

local function split_fontname (fontname)
    --- sometimes the style hides in the latter part of the
    --- fontname, separated by a dash, e.g. “Iwona-Regular”,
    --- “GFSSolomos-Regular”
    local splitted = { lpegmatch (dashsplitter, fontname) }
    if next (splitted) then
        return sanitize_fontname (splitted [#splitted])
    end
end

local function organize_styledata (metadata, rawinfo)
    local pfminfo   = metadata.pfminfo
    local names     = rawinfo.names
    return {
    --- see http://www.microsoft.com/typography/OTSPEC/features_pt.htm#size
        size            = get_size_info (rawinfo),
        pfmweight       = pfminfo and pfminfo.weight or metadata.pfmweight or 400,
        weight          = rawinfo.weight or metadata.weight or "unspecified",
        split           = split_fontname (rawinfo.fontname),
        width           = pfminfo and pfminfo.width or metadata.pfmwidth,
        italicangle     = metadata.italicangle,
    --- this is for querying, see www.ntg.nl/maps/40/07.pdf for details
        units_per_em    = metadata.units_per_em or metadata.units,
        version         = metadata.version,
    }
end

--[[doc--
The data inside an Opentype font file can be quite heterogeneous.
Thus in order to get the relevant information, parts of the original
table as returned by the font file reader need to be relocated.
--doc]]--

--- string -> int -> bool -> string -> fontentry

local function ot_fullinfo (filename,
                        subfont,
                        location,
                        basename,
                        format,
                        info)

    local metadata = load_font_file (filename, subfont)
    if not metadata then
        return nil
    end

    local rawinfo       = get_raw_info (metadata, basename)
    local nametable     = get_english_names (metadata)
    local namedata      = organize_namedata (rawinfo,
                                             nametable,
                                             basename,
                                             info)
    local style         = organize_styledata (metadata,
                                              rawinfo)
    local res = {
        file            = { base        = basename,
                            full        = filename,
                            subfont     = subfont,
                            location    = location or "system" },
        format          = format,
        names           = namedata,
        style           = style,
        version         = rawinfo.version,
    }
    return res
end

--[[doc--

    Type1 font inspector. In comparison with OTF, PFB’s contain a good
    deal less name fields which makes it tricky in some parts to find a
    meaningful representation for the database.

    Good read: http://www.adobe.com/devnet/font/pdfs/5004.AFM_Spec.pdf

--doc]]--

--- string -> int -> bool -> string -> fontentry

local function t1_fullinfo (filename, _subfont, location, basename, format)
    local sanitized
    local metadata      = load_font_file (filename)
    local fontname      = metadata.fontname
    local fullname      = metadata.fullname
    local familyname    = metadata.familyname
    local italicangle   = metadata.italicangle
    local style         = ""
    local weight

    sanitized = sanitize_fontnames ({
        fontname              = fontname,
        psname                = fullname,
        familyname            = familyname,
        weight                = metadata.weight, --- string identifier
        typographicsubfamily  = style,
    })

    weight = sanitized.weight

    if weight == "bold" then
        style = weight
    end

    if italicangle ~= 0 then
        style = style .. "italic"
    end

    return {
        basename              = basename,
        fullpath              = filename,
        subfont               = false,
        location              = location or "system",
        format                = format,
        fullname              = sanitized.fullname,
        fontname              = sanitized.fontname,
        familyname            = sanitized.familyname,
        plainname             = fullname,
        psname                = sanitized.fontname,
        version               = metadata.version,
        size                  = false,
        typographicsubfamily  = style ~= "" and style or weight,
        weight                = metadata.pfminfo and pfminfo.weight or 400,
        italicangle           = italicangle,
    }
end

local loaders = {
    otf     = ot_fullinfo,
    ttc     = ot_fullinfo,
    ttf     = ot_fullinfo,
    afm     = t1_fullinfo,
    pfb     = t1_fullinfo,
}

--- not side-effect free!

local function compare_timestamps (fullname,
                                   currentstatus,
                                   currententrystatus,
                                   currentmappings,
                                   targetstatus,
                                   targetentrystatus,
                                   targetmappings)

    local currenttimestamp = currententrystatus
                         and currententrystatus.timestamp
    local targettimestamp  = lfsattributes (fullname, "modification")

    if targetentrystatus ~= nil
    and targetentrystatus.timestamp == targettimestamp then
        logreport ("log", 3, "db", "Font %q already read.", fullname)
        return false
    end

    targetentrystatus.timestamp = targettimestamp
    targetentrystatus.index     = targetentrystatus.index or { }

    if  currenttimestamp == targettimestamp
    and not targetentrystatus.index [1]
    then
        --- copy old namedata into new

        for _, currentindex in next, currententrystatus.index do

            local targetindex   = #targetentrystatus.index
            local fullinfo      = currentmappings [currentindex]
            local location      = #targetmappings + 1

            targetmappings [location]                 = fullinfo
            targetentrystatus.index [targetindex + 1] = location
        end

        logreport ("log", 3, "db", "Font %q already indexed.", fullname)

        return false
    end

    return true
end

local function insert_fullinfo (fullname,
                                basename,
                                n_font,
                                loader,
                                format,
                                location,
                                targetmappings,
                                targetentrystatus,
                                info)

    local fullinfo = loader (fullname, n_font,
                             location, basename,
                             format, info)

    if not fullinfo then
        return false
    end

    local index = targetentrystatus.index [n_font]

    if not index then
        index = #targetmappings + 1
    end

    targetmappings [index]            = fullinfo
    targetentrystatus.index [n_font]  = index

    return true
end



--- we return true if the font is new or re-indexed
--- string -> dbobj -> dbobj -> bool

local function read_font_names (fullname,
                                currentnames,
                                targetnames,
                                location)

    local targetmappings        = targetnames.mappings
    local targetstatus          = targetnames.status --- by full path
    local targetentrystatus     = targetstatus [fullname]

    if targetentrystatus == nil then
        targetentrystatus        = { }
        targetstatus [fullname]  = targetentrystatus
    end

    local currentmappings       = currentnames.mappings
    local currentstatus         = currentnames.status
    local currententrystatus    = currentstatus [fullname]

    local basename              = filebasename (fullname)
    local barename              = filenameonly (fullname)
    local entryname             = fullname

    if location == "texmf" then
        entryname = basename
    end

    --- 1) skip if blacklisted

    if names.blacklist[fullname] or names.blacklist[basename] then
        logreport ("log", 2, "db",
                   "Ignoring blacklisted font %q.", fullname)
        return false
    end

    --- 2) skip if known with same timestamp

    if not compare_timestamps (fullname,
                               currentstatus,
                               currententrystatus,
                               currentmappings,
                               targetstatus,
                               targetentrystatus,
                               targetmappings)
    then
        return false
    end

    --- 3) new font; choose a loader, abort if unknown

    local format    = stringlower (filesuffix (basename))
    local loader    = loaders [format] --- ot_fullinfo, t1_fullinfo

    if not loader then
        logreport ("both", 0, "db",
                   "Unknown format: %q, skipping.", format)
        return false
    end

    --- 4) get basic info, abort if fontloader can’t read it

    local err, info = read_font_file (fullname)

    if err == false then
        logreport ("log", 1, "db",
                   "Failed to read basic information from %q: %q",
                    basename, tostring (info))
        return false
    end


    --- 5) check for subfonts and process each of them

    if type (info) == "table" and #info >= 1 then --- ttc

        local success = false --- true if at least one subfont got read

        for n_font = 1, #info do
            if insert_fullinfo (fullname, basename, n_font,
                                loader, format, location,
                                targetmappings, targetentrystatus,
                                info[n_font])
            then
                success = true
            end
        end

        return success
    end

    return insert_fullinfo (fullname, basename, false,
                            loader, format, location,
                            targetmappings, targetentrystatus,
                            info)
end

local path_normalize
do
    --- os.type and os.name are constants so we
    --- choose a normalization function in advance
    --- instead of testing with every call
    local os_type, os_name = os.type, os.name
    local filecollapsepath = file.collapsepath or file.collapse_path

    --- windows and dos
    if os_type == "windows" or os_type == "msdos" then
        --- ms platfom specific stuff
        function path_normalize (path)
            path = stringgsub(path, '\\', '/')
            path = stringlower(path)
            path = filecollapsepath(path)
            return path
        end
--[[doc--
    The special treatment for cygwin was removed with a patch submitted
    by Ken Brown.
    Reference: http://cygwin.com/ml/cygwin/2013-05/msg00006.html
--doc]]--

    else -- posix
        path_normalize = filecollapsepath
    end
end

local blacklist = { }
local p_blacklist --- prefixes of dirs

--- string list -> string list
local function collapse_prefixes (lst)
    --- avoid redundancies in blacklist
    if #lst < 2 then
        return lst
    end

    tablesort(lst)
    local cur = lst[1]
    local result = { cur }
    for i=2, #lst do
        local elm = lst[i]
        if stringsub(elm, 1, #cur) ~= cur then
            --- different prefix
            cur = elm
            result[#result+1] = cur
        end
    end
    return result
end

--- string list -> string list -> (string, bool) hash_t
local function create_blacklist (blacklist, whitelist)
    local result = { }
    local dirs   = { }

    logreport ("info", 2, "db", "Blacklisting %d files and directories.",
               #blacklist)
    for i=1, #blacklist do
        local entry = blacklist[i]
        if lfsisdir(entry) then
            dirs[#dirs+1] = entry
        else
            result[blacklist[i]] = true
        end
    end

    logreport ("info", 2, "db", "Whitelisting %d files.", #whitelist)
    for i=1, #whitelist do
        result[whitelist[i]] = nil
    end

    dirs = collapse_prefixes(dirs)

    --- build the disjunction of the blacklisted directories
    for i=1, #dirs do
        local p_dir = P(dirs[i])
        if p_blacklist then
            p_blacklist = p_blacklist + p_dir
        else
            p_blacklist = p_dir
        end
    end

    if p_blacklist == nil then
        --- always return false
        p_blacklist = lpeg.Cc(false)
    end

    return result
end

--- unit -> unit
local function read_blacklist ()
    local files = {
        kpselookup ("luaotfload-blacklist.cnf",
                    {all=true, format="tex"})
    }
    local blacklist = { }
    local whitelist = { }

    if files and type(files) == "table" then
        for _, path in next, files do
            for line in iolines (path) do
                line = stringstrip(line) -- to get rid of lines like " % foo"
                local first_chr = stringsub(line, 1, 1)
                if first_chr == "%" or stringis_empty(line) then
                    -- comment or empty line
                elseif first_chr == "-" then
                    logreport ("both", 3, "db",
                               "Whitelisted file %q via %q.",
                               line, path)
                    whitelist[#whitelist+1] = stringsub(line, 2, -1)
                else
                    local cmt = stringfind(line, "%%")
                    if cmt then
                        line = stringsub(line, 1, cmt - 1)
                    end
                    line = stringstrip(line)
                    logreport ("both", 3, "db",
                               "Blacklisted file %q via %q.",
                               line, path)
                    blacklist[#blacklist+1] = line
                end
            end
        end
    end
    names.blacklist = create_blacklist(blacklist, whitelist)
end

local p_font_filter

do
    local function extension_pattern (list)
        if type (list) ~= "table" or #list == 0 then return P(-1) end
        local pat
        for i=#list, 1, -1 do
            local e = list[i]
            if not pat then
                pat = P(e)
            else
                pat = pat + P(e)
            end
        end
        pat = pat * P(-1)
        return (1 - pat)^1 * pat
    end

    --- small helper to adjust the font filter pattern (--formats
    --- option)

    local current_formats = { }

    local splitcomma = luaotfload.parsers.splitcomma
    function set_font_filter (formats)

        if not formats or type (formats) ~= "string" then
            return
        end

        if stringsub (formats, 1, 1) == "+" then -- add
            formats = lpegmatch (splitcomma, stringsub (formats, 2))
            if formats then
                current_formats = tableappend (current_formats, formats)
            end
        elseif stringsub (formats, 1, 1) == "-" then -- remove
            formats = lpegmatch (splitcomma, stringsub (formats, 2))
            if formats then
                local newformats = { }
                for i = 1, #current_formats do
                    local fmt     = current_formats[i]
                    for j = 1, #formats do
                        if current_formats[i] == formats[j] then
                            goto skip
                        end
                    end
                    newformats[#newformats+1] = fmt
                    ::skip::
                end
                current_formats = newformats
            end
        else -- set
            formats = lpegmatch (splitcomma, formats)
            if formats then
                current_formats = formats
            end
        end

        p_font_filter = extension_pattern (current_formats)
    end

    function get_font_filter (formats)
        return tablefastcopy (current_formats)
    end
end

local function locate_matching_pfb (afmfile, dir)
    local pfbname = filereplacesuffix (afmfile, "pfb")
    local pfbpath = dir .. "/" .. pfbname
    if lfsisfile (pfbpath) then
        return pfbpath
    end
    --- Check for match in texmf too
    return kpsefind_file (pfbname, "type1 fonts")
end

local function process_dir_tree (acc, dirs, done)
    if not next (dirs) then --- done
        return acc
    end

    local pwd   = lfscurrentdir ()
    local dir   = dirs[#dirs]
    dirs[#dirs] = nil

    if not lfschdir (dir) then
        --- Cannot cd; skip.
        return process_dir_tree (acc, dirs, done)
    end

    dir = lfscurrentdir () --- resolve symlinks
    lfschdir (pwd)
    if tablecontains (done, dir) then
        --- Already traversed. Note that it’d be unsafe to rely on the
        --- hash part above due to Lua only processing up to 32 bytes
        --- of string data. The lookup shouldn’t impact performance too
        --- much but we could check the performance of alternative data
        --- structures at some point.
        return process_dir_tree (acc, dirs, done)
    end

    local newfiles = { }
    local blacklist = names.blacklist
    for ent in lfsdir (dir) do
        --- filter right away
        if ent ~= "." and ent ~= ".." and not blacklist[ent] then
            local fullpath = dir .. "/" .. ent
            if lfsisdir (fullpath)
            and not lpegmatch (p_blacklist, fullpath)
            then
                dirs[#dirs+1] = fullpath
            elseif lfsisfile (fullpath) then
                ent = stringlower (ent)
                if lpegmatch (p_font_filter, ent) then
                    if filesuffix (ent) == "afm" then
                        local pfbpath = locate_matching_pfb (ent, dir)
                        if pfbpath then
                            newfiles[#newfiles+1] = pfbpath
                        end
                    end
                    newfiles[#newfiles+1] = fullpath
                end
            end
        end
    end
    done [#done + 1] = dir
    return process_dir_tree (tableappend (acc, newfiles), dirs, done)
end

local function process_dir (dir)
    local pwd = lfscurrentdir ()
    if lfschdir (dir) then
        dir = lfscurrentdir () --- resolve symlinks
        lfschdir (pwd)

        local files = { }
        local blacklist = names.blacklist
        for ent in lfsdir (dir) do
            if ent ~= "." and ent ~= ".." and not blacklist[ent] then
                local fullpath = dir .. "/" .. ent
                if lfsisfile (fullpath) then
                    ent = stringlower (ent)
                    if lpegmatch (p_font_filter, ent)
                    then
                        if filesuffix (ent) == "afm" then
                            local pfbpath = locate_matching_pfb (ent, dir)
                            if pfbpath then
                                files[#files+1] = pfbpath
                            end
                        else
                            files[#files+1] = fullpath
                        end
                    end
                end
            end
        end
        return files
    end
    return { }
end

--- string -> bool -> string list
local function find_font_files (root, recurse)
    if lfsisdir (root) then
        if recurse == true then
            return process_dir_tree ({}, { root }, {})
        else --- kpathsea already delivered the necessary subdirs
            return process_dir (root)
        end
    end
end

--- truncate_string -- Cut the first part of a string to fit it
--- into a given terminal width. The parameter “restrict” (int)
--- indicates the number of characters already consumed on the
--- line.
local function truncate_string (str, restrict)
    local tw  = config.luaotfload.misc.termwidth
    local wd  = tw - restrict
    local len = utf8len (str)
    if not len then
        -- str is not valid UTF-8... We will assume a 8-bit
        -- encoding and forward it verbatim to the output.
        len = #str
        if wd - len < 0 then
            str = ".." .. stringsub(str, len - wd + 2)
        end
    elseif wd - len < 0 then
        --- combined length exceeds terminal,
        str = ".." .. stringsub(str, utf8offset(str, - wd + 2))
    end
    return str
end


--[[doc--

    collect_font_filenames_dir -- Traverse the directory root at
    ``dirname`` looking for font files. Returns a list of {*filename*;
    *location*} pairs.

--doc]]--

--- string -> string -> string * string list
local function collect_font_filenames_dir (dirname, location)
    if lpegmatch (p_blacklist, dirname) then
        logreport ("both", 4, "db",
                   "Skipping blacklisted directory %s.", dirname)
        --- ignore
        return { }
    end
    local found = find_font_files (dirname, location ~= "texmf" and location ~= "local")
    if not found then
        logreport ("both", 4, "db",
                   "No such directory: %q; skipping.", dirname)
        return { }
    end

    local nfound = #found
    local files  = { }

    logreport ("both", 4, "db",
               "%d font files detected in %s.",
               nfound, dirname)
    for j = 1, nfound do
        local fullname = found[j]
        files[#files + 1] = { path_normalize (fullname), location }
    end
    return files
end

local stripslashes = luaotfload.parsers.stripslashes
--- string list -> string list
local function filter_out_pwd (dirs)
    local result = { }
    local pwd = path_normalize (lpegmatch (stripslashes,
                                           lfscurrentdir ()))
    for i = 1, #dirs do
        --- better safe than sorry
        local dir = path_normalize (lpegmatch (stripslashes, dirs[i]))
        if dir == "." or dir == pwd then
            logreport ("both", 3, "db",
                       "Path %q matches $PWD (%q), skipping.",
                       dir, pwd)
        else
            result[#result+1] = dir
        end
    end
    return result
end

local path_separator = os.type == "windows" and ";" or ":"

--[[doc--

    collect_font_filenames_texmf -- Scan texmf tree for font files
    relying on kpathsea search paths for the respective file types.
    The current working directory comes as “.” (texlive) or absolute
    path (miktex) and will always be filtered out.

    Returns a list of { *filename*; *location* } pairs.

--doc]]--

--- unit -> string * string list
local function collect_font_filenames_texmf ()

    local osfontdir = kpseexpand_path "$OSFONTDIR"

    if stringis_empty (osfontdir) then
        logreport ("both", 1, "db", "Scanning TEXMF for fonts...")
    else
        logreport ("both", 1, "db", "Scanning TEXMF and $OSFONTDIR for fonts...")
        if log.get_loglevel () > 3 then
            local osdirs = filesplitpath (osfontdir)
            logreport ("both", 0, "db", "$OSFONTDIR has %d entries:", #osdirs)
            for i = 1, #osdirs do
                logreport ("both", 0, "db", "[%d] %s", i, osdirs[i])
            end
        end
    end

    local show_path = kpse.show_path

    local function expanded_path (file_type)
        return kpseexpand_path (show_path (file_type))
    end

    local fontdirs = expanded_path "opentype fonts"
    fontdirs = fontdirs .. path_separator .. expanded_path "truetype fonts"
    fontdirs = fontdirs .. path_separator .. expanded_path "type1 fonts"
    fontdirs = fontdirs .. path_separator .. expanded_path "afm"

    fontdirs = filesplitpath (fontdirs) or { }

    local tasks = filter_out_pwd (fontdirs)
    logreport ("both", 3, "db",
               "Initiating scan of %d directories.", #tasks)

    local files = { }
    for _, dir in next, tasks do
        files = tableappend (files, collect_font_filenames_dir (dir, "texmf"))
    end
    logreport ("both", 3, "db", "Collected %d files.", #files)
    return files
end

--- unit -> string list
local function get_os_dirs ()
    if os.name == 'macosx' then
        return {
            filejoin(kpseexpand_path('~'), "Library/Fonts"),
            "/Library/Fonts",
            "/System/Library/Fonts",
            "/Network/Library/Fonts",
        }
    elseif os.type == "windows" or os.type == "msdos" then
        local windir = osgetenv("WINDIR")
        local appdata = osgetenv("LOCALAPPDATA")
        if chgstrcp and kpse.var_value('command_line_encoding') ~= nil then
            return { filejoin(windir, 'Fonts'), chgstrcp.syscptoutf8(filejoin(appdata, 'Microsoft/Windows/Fonts')) }
        else
            return { filejoin(windir, 'Fonts'), filejoin(appdata, 'Microsoft/Windows/Fonts') }
        end
    else
        local fonts_conves = { --- plural, much?
            "/usr/local/etc/fonts/fonts.conf",
            "/etc/fonts/fonts.conf",
        }
        local os_dirs = luaotfload.parsers.read_fonts_conf(fonts_conves, find_files)
        return os_dirs
    end
    return {}
end

--[[doc--

    count_removed -- Count paths that do not exist in the file system.

--doc]]--

--- string list -> size_t
local function count_removed (files)
    if not files or not files.full then
        logreport ("log", 4, "db", "Empty file store; no data to work with.")
        return 0
    end
    local old = files.full
    logreport ("log", 4, "db", "Checking removed files.")
    local nrem = 0
    local nold = #old
    for i = 1, nold do
        local f = old[i]
        if not kpsereadable_file (f) then
            logreport ("log", 2, "db",
                      "File %q does not exist in file system.", f)
            nrem = nrem + 1
        end
    end
    return nrem
end

--[[doc--

    retrieve_namedata -- Scan the list of collected fonts and populate
    the list of namedata.

        · dirname       : name of the directory to scan
        · currentnames  : current font db object
        · targetnames   : font db object to fill
        · dry_run       : don’t touch anything

    Returns the number of fonts that were actually added to the index.

--doc]]--

--- string * string list -> dbobj -> dbobj -> bool? -> int * int
local function retrieve_namedata (files, currentnames, targetnames, dry_run)

    local nfiles    = #files
    local nnew      = 0

    logreport ("info", 1, "db", "Scanning %d collected font files ...", nfiles)

    local bylocation = { texmf     = { 0, 0 }
                       , ["local"] = { 0, 0 }
                       , system    = { 0, 0 }
                       }
    report_status_start (2, 4)
    for i = 1, nfiles do
        local fullname, location   = unpack (files[i])
        local count                = bylocation[location]
        count[1]                   = count[1] + 1
        if dry_run == true then
            local truncated = truncate_string (fullname, 43)
            logreport ("log", 2, "db", "Would have been loading %s.", fullname)
            report_status ("term", "db", "Would have been loading %s", truncated)
            --- skip the read_font_names part
        else
            local truncated = truncate_string (fullname, 32)
            logreport ("log", 2, "db", "Loading font %s.", fullname)
            report_status ("term", "db", "Loading font %s", truncated)
            local new = read_font_names (fullname, currentnames,
                                         targetnames, location)
            if new == true then
                nnew     = nnew + 1
                count[2] = count[2] + 1
            end
        end
    end
    report_status_stop ("term", "db", "Scanned %d files, %d new.", nfiles, nnew)
    for location, count in next, bylocation do
        logreport ("term", 4, "db", "   * %s: %d files, %d new",
                   location, count[1], count[2])
    end
    return nnew
end

--- unit -> string * string list
local function collect_font_filenames_system ()

    local n_scanned, n_new = 0, 0
    logreport ("info", 1, "db", "Scanning system fonts...")
    logreport ("info", 2, "db",
               "Searching in static system directories...")

    local files = { }
    for _, dir in next, get_os_dirs () do
        tableappend (files, collect_font_filenames_dir (dir, "system"))
    end
    logreport ("term", 3, "db", "Collected %d files.", #files)
    return files
end

--- unit -> bool
local function flush_lookup_cache ()
    lookup_cache = { }
    collectgarbage "collect"
    return true
end

--[[doc--

    collect_font_filenames_local -- Scan $PWD (during a TeX run)
    for font files.

    Side effect: This sets the “local” flag in the subtable “meta” to
    prevent the merged table from being saved to disk.

    TODO the local tree could be cached in $PWD.

--doc]]--

--- unit -> string * string list
local function collect_font_filenames_local ()
    local pwd = lfscurrentdir ()
    logreport ("both", 1, "db", "Scanning for fonts in $PWD (%q) ...", pwd)

    local files  = collect_font_filenames_dir (pwd, "local")
    local nfiles = #files
    if nfiles > 0 then
        logreport ("term", 1, "db", "Found %d files.", pwd)
    else
        logreport ("term", 1, "db",
                   "Couldn’t find a thing here. What a waste.", pwd)
    end
    logreport ("term", 3, "db", "Collected %d files.", #files)
    return files, nfiles > 0
end

--- fontentry list -> filemap
local function generate_filedata (mappings)

    logreport ("both", 2, "db", "Creating filename map.")

    local nmappings  = #mappings

    local files  = {
        bare = {
            ["local"]   = { },
            system      = { }, --- mapped to mapping format -> index in full
            texmf       = { }, --- mapped to mapping format -> “true”
        },
        base = {
            ["local"]   = { },
            system      = { }, --- mapped to index in “full”
            texmf       = { }, --- set; all values are “true”
        },
        full = { }, --- non-texmf
    }

    local base = files.base
    local bare = files.bare
    local full = files.full

    local conflicts = {
        basenames = 0,
        barenames = 0,
    }

    for index = 1, nmappings do
        local entry    = mappings [index]
        local filedata = entry.file
        local format
        local location
        local fullpath
        local basename
        local barename
        local subfont

        if filedata then --- new entry
            format   = entry.format   --- otf, afm, ...
            location = filedata.location --- texmf, system, ...
            fullpath = filedata.full
            basename = filedata.base
            barename = filenameonly (fullpath)
            subfont  = filedata.subfont
        else
            format   = entry.format   --- otf, afm, ...
            location = entry.location --- texmf, system, ...
            fullpath = entry.fullpath
            basename = entry.basename
            barename = filenameonly (fullpath)
            subfont  = entry.subfont
        end

        entry.index    = index

        --- 1) add to basename table

        local inbase = base [location] --- no format since the suffix is known

        -- MK Added lowercase versions for case-insensitive fallback
        if inbase then
            local present = inbase [basename]
            if present then
                logreport ("both", 4, "db",
                           "Conflicting basename: %q already indexed \z
                            in category %s, ignoring.",
                           barename, location)
                conflicts.basenames = conflicts.basenames + 1

                --- track conflicts per font
                local conflictdata = entry.conflicts

                if not conflictdata then
                    entry.conflicts = { basename = present }
                else -- some conflicts already detected
                    conflictdata.basename = present
                end

            else
                local lowerbasename = stringlower (basename)
                if basename ~= lowerbasename then
                    present = inbase [lowerbasename]
                    if present then
                        logreport ("both", 4, "db",
                                   "Conflicting basename: %q already indexed \z
                                    as %s.",
                                   barename, mappings[present].basename)
                        conflicts.basenames = conflicts.basenames + 1

                        --- track conflicts per font
                        local conflictdata = entry.conflicts

                        if not conflictdata then
                            entry.conflicts = { basename = present }
                        else -- some conflicts already detected
                            conflictdata.basename = present
                        end

                    else
                        inbase [lowerbasename] = index
                    end
                end
                inbase [basename] = index
            end
        else
            inbase = { basename = index }
            base [location] = inbase
            local lowerbasename = stringlower (basename)
            if basename ~= lowerbasename then
                inbase [lowerbasename] = index
            end
        end

        --- 2) add to barename table

        local inbare = bare [location] [format]

        if inbare then
            local present = inbare [barename]
            if present then
                logreport ("both", 4, "db",
                           "Conflicting barename: %q already indexed \z
                            in category %s/%s, ignoring.",
                           barename, location, format)
                conflicts.barenames = conflicts.barenames + 1

                --- track conflicts per font
                local conflictdata = entry.conflicts

                if not conflictdata then
                    entry.conflicts = { barename = present }
                else -- some conflicts already detected
                    conflictdata.barename = present
                end
            else
                local lowerbarename = stringlower (barename)
                if barename ~= lowerbarename then
                    present = inbare [lowerbarename]
                    if present then
                        logreport ("both", 4, "db",
                                   "Conflicting barename: %q already indexed \z
                                    as %s.",
                                   barename, mappings[present].basename)
                        conflicts.barenames = conflicts.barenames + 1

                        --- track conflicts per font
                        local conflictdata = entry.conflicts

                        if not conflictdata then
                            entry.conflicts = { barename = present }
                        else -- some conflicts already detected
                            conflictdata.barename = present
                        end
                    else
                        inbare [lowerbarename] = index
                    end
                end
                inbare [barename] = index
            end
        else
            inbare = { [barename] = index }
            bare [location] [format] = inbare
            local lowerbarename = stringlower (barename)
            if barename ~= lowerbarename then
                inbare [lowerbarename] = index
            end
        end
        -- /MK

        --- 3) add to fullpath map

        full [index] = fullpath
    end --- mapping traversal

    return files
end

local function regular_score(entry)
    return 10000 * (entry.italicangle or 0)^2 -- We really don't want italic fonts here (italic font have an angle around 10)
         +   .01 * ((entry.pfmweight or 400) - 400)^2 -- weights are normally multiples of 100, so they are still quite large after .01
         +         ((entry.width or 5) - 5)^2
         + (regular_synonym[entry.subfamily or entry.typographicsubfamily] or 1000000)
         + (entry.pfmweight > 500 and 1000 or 0)
end
local function italic_score(entry, regular_entry)
    local regularangle = regular_entry.italicangle or 0
    local angle = entry.italicangle or 0
    if (angle == 0 or angle == regularangle)
            and (entry.subfamily == regular_entry.subfamily or style_synonym[entry.subfamily] ~= 'i') then
        return -- This font is not italic in any way
    end
    return  .1 * (angle - regularangle - 10)^2 -- Should there ever be multiple levels of italicness...
         + 0.1 * ((entry.pfmweight or 400) - (regular_entry.pfmweight or 400))^2 -- weights are normally multiples of 100, so they are still quite large after .01
         +       ((entry.width or 5) - regular_entry.width)^2
         + (style_synonym[entry.subfamily or entry.typographicsubfamily] == 'i' and 0 or 1000000)
end
local function bold_score(entry, regular_entry)
    local regularweight = regular_entry.pfmweight or 400
    local weight = entry.pfmweight
    if weight < regularweight + 100
            and (entry.subfamily == regular_entry.subfamily or style_synonym[entry.subfamily] ~= 'b') then
        return -- This font is not bold in any way
    end
    return 10000 * (entry.italicangle or 0)^2 -- We really don't want italic fonts here (italic font have an angle around 10)
         +   .01 * ((entry.pfmweight or 400) - (regularweight + 200))^2 -- weights are normally multiples of 100, so they are still quite large after .01
         +         ((entry.width or 5) - regular_entry.width)^2
         + (style_synonym[entry.subfamily or entry.typographicsubfamily] == 'b' and 0 or 1000000)
         + (entry.pfmweight > 500 and 0 or 10000)
end
local function bolditalic_score(entry, bold_entry, italic_entry)
    local italicangle = italic_entry.italicangle or 0
    local angle = entry.italicangle or 0
    local boldweight = bold_entry.pfmweight or 400
    local weight = entry.pfmweight or 400
    if (angle == 0 or weight < boldweight)
            and (entry.subfamily == bold_entry.subfamily or entry.subfamily == italic_entry.subfamily or style_synonym[entry.subfamily] ~= 'bi') then
        return -- This font is not italic in any way
    end
    return 100 * (angle - italicangle)^2
         +       (weight - boldweight)^2
         +       ((entry.width or 5) - bold_entry.width)^2
         + (style_synonym[entry.subfamily or entry.typographicsubfamily] == 'bi' and 0 or 1000000)
end

local function pull_values (entry)
    local file              = entry.file
    local names             = entry.names
    local style             = entry.style
    local sanitized         = names.sanitized
    local english           = sanitized.english
    local info              = sanitized.info
    local metadata          = sanitized.metadata

    --- pull file info ...
    entry.basename          = file.base
    entry.fullpath          = file.full
    entry.location          = file.location
    entry.subfont           = file.subfont

    --- pull name info ...
    entry.psname               = english.psname
    entry.fontname             = info.fontname or metadata.fontname
    entry.fullname             = english.fullname or info.fullname
    entry.typographicsubfamily = english.typographicsubfamily
    entry.familyname           = metadata.familyname or english.typographicfamily or english.family
    entry.plainname            = names.fullname
    entry.subfamily            = english.subfamily

    --- pull style info ...
    entry.italicangle       = style.italicangle
    entry.size              = style.size
    entry.weight            = style.weight
    entry.width             = style.width
    entry.pfmweight         = style.pfmweight

    if config.luaotfload.db.strip == true then
        entry.file  = nil
        entry.names = nil
        entry.style = nil
    end
end

local function add_family (name, subtable, entry)
    if not name then --- probably borked font
        return
    end
    local familytable = subtable [name]
    if not familytable then
        familytable = { }
        subtable [name] = familytable
    end

    familytable [#familytable + 1] = {
        index    = entry.index,
    }
end

local function get_subtable (families, entry)
    local location  = entry.location
    local format    = entry.format
    local subtable  = families [location] [format]
    if not subtable then
        subtable  = { }
        families [location] [format] = subtable
    end
    return subtable
end

local function collect_families (mappings)

    logreport ("info", 2, "db", "Analyzing families.")

    local families = {
        ["local"]  = { },
        system     = { },
        texmf      = { },
    }

    for i = 1, #mappings do

        local entry = mappings [i]

        if entry.file then
            pull_values (entry)
        end

        local subtable             = get_subtable (families, entry)
        local familyname           = entry.familyname
        local typographicsubfamily = entry.typographicsubfamily
        local subfamily            = entry.subfamily
        local weight               = entry.weight
        local width                = entry.width
        local pfmweight            = entry.pfmweight
        local italicangle          = entry.italicangle
        add_family (familyname, subtable, entry)
    end

    collectgarbage "collect"
    return families
end

local function collect_fontnames (mappings)

    logreport ("info", 2, "db", "Collecting fontnames.")

    local fontnames = {
        ["local"]  = { },
        system     = { },
        texmf      = { },
    }

    for i = 1, #mappings do
        local entry = mappings [i]

        local subtable          = get_subtable (fontnames, entry)
        if entry.fontname then subtable[entry.fontname] = i end
        if entry.fullname then subtable[entry.fullname] = i end
        if entry.psname then subtable[entry.psname] = i end
    end

    collectgarbage "collect"
    return fontnames
end

--[[doc--

    group_modifiers -- For not-quite-bold faces, determine whether
    they can fill in for a missing bold face slot in a matching family.

    Some families like Lucida do not contain real bold / bold italic
    members. Instead, they have semibold variants at weight 600 which
    we must add in a separate pass.

--doc]]--

local style_categories   = { "r", "b", "i", "bi" }
local bold_categories    = {      "b",      "bi" }

local huge = math.huge
local function group_modifiers (mappings, families)
    logreport ("info", 2, "db", "Analyzing shapes, weights, and styles.")
    for location, location_data in next, families do
        for format, format_data in next, location_data do
            for familyname, collected in next, format_data do
                local best_score = huge
                local best_match
                for i=1,#collected do
                    local v = collected[i]
                    local entry = mappings[v.index]
                    local score = regular_score(entry)
                    if score <= best_score then
                        v.prev = best_score == score and best_match or nil
                        best_score = score
                        best_match = v
                    end
                end
                local regular = {}
                repeat
                    local index = best_match.index
                    local entry = mappings[index]
                    local size = entry.size
                    if size then
                        regular [#regular + 1] = {
                            size [1],
                            size [2],
                            size [3],
                            index,
                        }
                    else
                        regular.default = index
                    end
                    best_match = best_match.prev
                until not best_match
                local regular_entry = mappings[regular.default or regular[1][4]]
                local best_match_i, best_match_b
                local best_score_i, best_score_b = 10000000000, 10000000000
                for i=1,#collected do
                    local v = collected[i]
                    local entry = mappings[v.index]
                    local score_i = italic_score(entry, regular_entry)
                    local score_b = bold_score(entry, regular_entry)
                    if score_i and score_i <= best_score_i then
                        v.prev = best_score_i == score_i and best_match_i or nil
                        best_score_i = score_i
                        best_match_i = v
                    end
                    if score_b and score_b <= best_score_b then
                        v.prev = best_score_b == score_b and best_match_b or nil
                        best_score_b = score_b
                        best_match_b = v
                    end
                end
                local italic, bold
                if best_match_i then
                    italic = {}
                    repeat
                        local index = best_match_i.index
                        local entry = mappings[index]
                        local size = entry.size
                        if size then
                            italic [#italic + 1] = {
                                size [1],
                                size [2],
                                size [3],
                                index,
                            }
                        else
                            italic.default = index
                        end
                        best_match_i = best_match_i.prev
                    until not best_match_i
                end
                if best_match_b then
                    bold = {}
                    repeat
                        local index = best_match_b.index
                        local entry = mappings[index]
                        local size = entry.size
                        if size then
                            bold [#bold + 1] = {
                                size [1],
                                size [2],
                                size [3],
                                index,
                            }
                        else
                            bold.default = index
                        end
                        best_match_b = best_match_b.prev
                    until not best_match_b
                end
                local bolditalic
                if bold and italic then
                    best_score = 1000000000000
                    local bold_entry = mappings[bold.default or bold[1][4]]
                    local italic_entry = mappings[italic.default or italic[1][4]]
                    for i=1,#collected do
                        local v = collected[i]
                        local entry = mappings[v.index]
                        local score = bolditalic_score(entry, bold_entry, italic_entry)
                        if score and score <= best_score then
                            v.prev = best_score == score and best_match or nil
                            best_score = score
                            best_match = v
                        end
                    end
                    if best_match then
                        bolditalic = {}
                        repeat
                            local index = best_match.index
                            local entry = mappings[index]
                            local size = entry.size
                            if size then
                                bolditalic [#bolditalic + 1] = {
                                    size [1],
                                    size [2],
                                    size [3],
                                    index,
                                }
                            else
                                bolditalic.default = index
                            end
                            best_match = best_match.prev
                        until not best_match
                    end
                end
                format_data [familyname] = { r = regular, b = bold, i = italic, bi = bolditalic }
            end
        end
    end
    return families
end

local function cmp_sizes (a, b)
    return a [1] < b [1]
end

local function order_design_sizes (families)

    logreport ("info", 2, "db", "Ordering design sizes.")

    for location, data in next, families do
        for format, data in next, data do
            for familyname, data in next, data do
                for style, data in next, data do
                    tablesort (data, cmp_sizes)
                end
            end
        end
    end

    return families
end

--[[doc--

    Get the subfont index corresponding to a given psname in a
    font collection

--doc]]--

local function lookup_subfont_index(filepath, psname)
    assert(name_index)
    -- if not name_index then name_index = load_names () end
    local filestatus = name_index.status[filepath]
    local mappings = name_index.mappings
    if filestatus then
        for subfont, idx in next, filestatus.index do
            if mappings[idx].psname == psname then
                return subfont or 1
            end
        end
    end

    -- If that didn't work, we do a manual search
    psname = sanitize_fontname(psname)
    local err, info = read_font_file (filepath)
    if #info == 0 then return 1 end
    for i = 1, #info do
        for _, names in next, info[i].platformnames do
            if psname == sanitize_fontname(names.postscriptname) then
                return i
            end
        end
    end
end

--[[doc--

    collect_font_filenames -- Scan the three search path categories for
    font files. This constitutes the first pass of the update mode.

--doc]]--

--- unit -> string * string list
local function collect_font_filenames ()

    logreport ("info", 4, "db", "Scanning the filesystem for font files.")

    local filenames = { }
    local bisect    = config.luaotfload.misc.bisect
    local max_fonts = config.luaotfload.db.max_fonts --- XXX revisit for lua 5.3 wrt integers

    -- We can't just scan in the order of location_precedence here since
    -- the order is important. In the common situation of having texmf
    -- added to the system font path, scanning system first would
    -- classify all texmf fonts as system fonts.
    if enabled_locations.texmf then
        tableappend (filenames, collect_font_filenames_texmf  ())
    end
    if enabled_locations.system then
        tableappend (filenames, collect_font_filenames_system ())
    end
    if enabled_locations['local'] then
        local localfonts, found = collect_font_filenames_local()
        if found then
            tableappend (filenames, localfonts)
        else
            scan_local = false
        end
    end
    --- Now drop everything above max_fonts.
    if max_fonts < #filenames then
        filenames = { unpack (filenames, 1, max_fonts) }
    end
    --- And choose the requested slice if in bisect mode.
    if bisect then
        return { unpack (filenames, bisect[1], bisect[2]) }
    end
    return filenames
end

--[[doc--

    nth_font_file -- Return the filename of the nth font.

--doc]]--

--- int -> string
local function nth_font_filename (n)
    logreport ("info", 4, "db", "Picking font file no. %d.", n)
    if not p_blacklist then
        read_blacklist ()
    end
    local filenames = collect_font_filenames ()
    return filenames[n] and filenames[n][1] or "<error>"
end

--[[doc--

    font_slice -- Return the fonts in the range from lo to hi.

--doc]]--

local function font_slice (lo, hi)
    logreport ("info", 4, "db", "Retrieving font files nos. %d--%d.", lo, hi)
    if not p_blacklist then
        read_blacklist ()
    end
    local filenames = collect_font_filenames ()
    local result    = { }
    for i = lo, hi do
        result[#result + 1] = filenames[i][1]
    end
    return result
end

--[[doc

    count_font_files -- Return the number of files found by
    collect_font_filenames. This function is exported primarily
    for use with luaotfload-tool.lua in bisect mode.

--doc]]--

--- unit -> int
local function count_font_files ()
    logreport ("info", 4, "db", "Counting font files.")
    if not p_blacklist then
        read_blacklist ()
    end
    return #collect_font_filenames ()
end

--- dbobj -> stats

local function collect_statistics (mappings)
    local sum_dsnsize, n_dsnsize = 0, 0

    local fullname, family, families = { }, { }, { }
    local subfamily, typographicsubfamily = { }, { }

    local function addtohash (hash, item)
        if item then
            local times = hash [item]
            if times then
                hash [item] = times + 1
            else
                hash [item] = 1
            end
        end
    end

    local function appendtohash (hash, key, value)
        if key and value then
            local entry = hash [key]
            if entry then
                entry [#entry + 1] = value
            else
                hash [key] = { value }
            end
        end
    end

    local function addtoset (hash, key, value)
        if key and value then
            local set = hash [key]
            if set then
                set [value] = true
            else
                hash [key] = { [value] = true }
            end
        end
    end

    local function setsize (set)
        local n = 0
        for _, _ in next, set do
            n = n + 1
        end
        return n
    end

    local function hashsum (hash)
        local n = 0
        for _, m in next, hash do
            n = n + m
        end
        return n
    end

    for _, entry in next, mappings do
        local style        = entry.style
        local names        = entry.names.sanitized
        local englishnames = names.english

        addtohash (fullname,             englishnames.fullname)
        addtohash (family,               englishnames.family)
        addtohash (subfamily,            englishnames.subfamily)
        addtohash (typographicsubfamily, englishnames.typographicsubfamily)

        addtoset (families, englishnames.family, englishnames.fullname)

        local sizeinfo = entry.style.size
        if sizeinfo then
            sum_dsnsize = sum_dsnsize + sizeinfo [1]
            n_dsnsize = n_dsnsize + 1
        end
    end

    --inspect (families)

    local n_fullname = setsize (fullname)
    local n_family   = setsize (family)

    if log.get_loglevel () > 1 then
        local function pprint_top (hash, n, set)

            local freqs = { }
            local items = { }

            for item, value in next, hash do
                if set then
                    freq = setsize (value)
                else
                    freq = value
                end
                local ifreq = items [freq]
                if ifreq then
                    ifreq [#ifreq + 1] = item
                else
                    items [freq] = { item }
                    freqs [#freqs + 1] = freq
                end
            end

            tablesort (freqs)

            local from = #freqs
            local to   = from - (n - 1)
            if to < 1 then
                to = 1
            end

            for i = from, to, -1 do
                local freq     = freqs [i]
                local itemlist = items [freq]

                if type (itemlist) == "table" then
                    itemlist = tableconcat (itemlist, ", ")
                end

                logreport ("both", 0, "db",
                           "       · %4d × %s.",
                           freq, itemlist)
            end
        end

        logreport ("both", 0, "", "~~~~ font index statistics ~~~~")
        logreport ("both", 0, "db",
                   "   · Collected %d fonts (%d names) in %d families.",
                   #mappings, n_fullname, n_family)
        pprint_top (families, 4, true)

        logreport ("both", 0, "db",
                   "   · %d different \"subfamily\" kinds.",
                   setsize (subfamily))
        pprint_top (subfamily, 4)

        logreport ("both", 0, "db",
                   "   · %d different \"typographicsubfamily\" kinds.",
                   setsize (typographicsubfamily))
        pprint_top (typographicsubfamily, 4)

    end

    local mean_dsnsize = 0
    if n_dsnsize > 0 then
        mean_dsnsize = sum_dsnsize / n_dsnsize
    end

    return {
        mean_dsnsize = mean_dsnsize,
        names = {
            fullname = n_fullname,
            families = n_family,
        },
--        style = {
--            subfamily = subfamily,
--            typographicsubfamily = typographicsubfamily,
--        },
    }
end

--- force:      dictate rebuild from scratch
--- dry_dun:    don’t write to the db, just scan dirs

--- dbobj? -> bool? -> bool? -> dbobj
function update_names (currentnames, force, dry_run)
    local targetnames
    local n_new = 0
    local n_rem = 0

    local conf = config.luaotfload
    if conf.run.live ~= false and conf.db.update_live == false then
        logreport ("info", 2, "db", "Skipping database update.")
        --- skip all db updates
        return currentnames or name_index
    end

    local starttime = osgettimeofday ()

    --[[
    The main function, scans everything
    - “targetnames” is the final table to return
    - force is whether we rebuild it from scratch or not
    ]]
    logreport ("both", 1, "db",
               "Updating the font names database"
               .. (force and " forcefully." or "."))

    if config.luaotfload.db.skip_read == true then
        --- the difference to a “dry run” is that we don’t search
        --- for font files entirely. we also ignore the “force”
        --- parameter since it concerns only the font files.
        logreport ("info", 2, "db",
                   "Ignoring font files, reusing old data.")
        currentnames = load_names (false)
        targetnames  = currentnames
    else
        if force then
            currentnames = initialize_namedata (get_font_filter ())
        else
            if not currentnames or not next (currentnames) then
                currentnames = load_names (dry_run)
            end
            if currentnames.meta.version ~= names.version then
                logreport ("both", 1, "db",
                           "No font names database or old \z
                            one found; generating new one.")
                currentnames = initialize_namedata (get_font_filter ())
            end
        end

        targetnames = initialize_namedata (get_font_filter (),
                                           currentnames.meta and currentnames.meta.created)

        read_blacklist ()

        --- pass 1: Collect the names of all fonts we are going to process.
        local font_filenames = collect_font_filenames ()
        if enabled_locations['local'] then
            targetnames.meta['local'] = true
        end

        --- pass 2: read font files (normal case) or reuse information
        --- present in index

        n_rem = count_removed (currentnames.files)

        n_new = retrieve_namedata (font_filenames,
                                   currentnames,
                                   targetnames,
                                   dry_run)

        logreport ("info", 3, "db",
                   "Found %d font files; %d new, %d stale entries.",
                   #font_filenames, n_new, n_rem)
    end

    --- pass 3 (optional): collect some stats about the raw font info
    if config.luaotfload.misc.statistics == true then
        targetnames.meta.statistics = collect_statistics
                                            (targetnames.mappings)
    end

    --- we always generate the file lookup tables because
    --- non-texmf entries are redirected there and the mapping
    --- needs to be 100% consistent

    --- pass 4: build filename table
    targetnames.files       = generate_filedata (targetnames.mappings)

    --- pass 5: build family lookup table
    targetnames.families    = collect_families (targetnames.mappings)

    --- pass 6: arrange style and size info
    targetnames.families    = group_modifiers (targetnames.mappings,
                                               targetnames.families)
    --- pass 7: order design size tables
    targetnames.families    = order_design_sizes (targetnames.families)

    --- pass 8: build family lookup table
    targetnames.fontnames   = collect_fontnames (targetnames.mappings)

    logreport ("info", 3, "db",
               "Rebuilt in %0.f ms.",
               1000 * (osgettimeofday () - starttime))
    name_index = targetnames

    if dry_run ~= true then

        if n_new + n_rem == 0 then
            logreport ("info", 2, "db",
                       "No new or removed fonts, skip saving to disk.")
        else
            local success, reason = save_names ()
            if not success then
                logreport ("both", 0, "db",
                           "Failed to save database to disk: %s",
                           reason)
            end
        end

        if flush_lookup_cache () and save_lookups () then
            logreport ("both", 2, "cache", "Lookup cache emptied.")
            return targetnames
        end
    end
    return targetnames
end

local function compress_dummy(data) return data end
--- string -> string -> (string * table)
local function save_lua_table (data, path_lua, path_luc, compress)
    if compress then
        osremove(path_lua)
        osremove(path_luc)
        path_lua, path_luc = path_lua .. '.gz', path_luc .. '.gz'
    else
        osremove(path_lua .. '.gz')
        osremove(path_luc .. '.gz')
    end
    local file_lua, msg = ioopen(path_lua, compress and 'wb' or 'w')
    if not file_lua then
        logreport ("info", 0, "cache", "Failed to write %q: %s", path_lua, msg)
    end
    local file_luc file_luc, msg = ioopen(path_luc, 'wb')
    if not file_luc then
        logreport ("info", 0, "cache", "Failed to write %q: %s", path_luc, msg)
    end
    if not (file_lua or file_luc) then
        return
    end
    -- If we can only write one of the files, try to remove the other
    -- one to avoid them beiing inconsistent. This will probably fail,
    -- but in some situations we might be allowed to delete a file we
    -- can't write to.
    if not file_lua then
        osremove(path_lua)
    elseif not file_luc then
        osremove(path_luc)
    end
    local serialized = tableserialize (data, true)
    if file_lua then
        file_lua:write(compress and gzip.compress(serialized, 31) or serialized)
        file_lua:close()
    end
    if file_luc then
        local compiled = dump(assert(load(serialized, 't')), true)
        file_luc:write(compress and gzip.compress(compiled, 31) or compiled)
        file_luc:close()
    end
    -- Even if we could write one file but not the other one it's still an
    -- error since reloading is then unreliable.
    return file_lua and path_lua or nil, file_luc and path_luc or nil
end

--- unit -> bool
function save_lookups ( )
    local paths = config.luaotfload.paths
    local luaname, lucname = paths.lookup_path_lua, paths.lookup_path_luc
    luaname, lucname = save_lua_table(lookup_cache, luaname, lucname)
    if luaname and lucname then
        logreport ("both", 3, "cache", "Lookup cache saved.")
        return true
    else
        logreport ("info", 0, "cache", "Lookup cache file not writable.")
    end
    return false
end

--- save_names() is usually called without the argument
--- dbobj? -> bool * string option
function save_names (currentnames)
    if not currentnames then
        currentnames = name_index
    end
    if not currentnames or type (currentnames) ~= "table" then
        return false, "invalid names table"
    elseif currentnames.meta and currentnames.meta["local"] then
        return false, "table contains local entries"
    end
    local paths = config.luaotfload.paths
    local luaname, lucname = paths.index_path_lua, paths.index_path_luc
    local compress = config.luaotfload.db.compress
    luaname, lucname = save_lua_table(currentnames, luaname, lucname, compress)
    if luaname and lucname then
        logreport ("info", 2, "db", "Font index saved at ...")
        logreport ("info", 2, "db", "Text: " .. luaname)
        logreport ("info", 2, "db", "Byte: " .. lucname)
        return true
    end
    logreport ("info", 0, "db", "Index file not writable")
    return false
end

--[[doc--

    Below set of functions is modeled after mtx-cache.

--doc]]--

--- string -> string -> string list -> string list -> string list -> unit
local function print_cache (category, path, luanames, lucnames, rest)
    local function report_indeed (...)
        logreport ("info", 0, "cache", ...)
    end
    report_indeed("Luaotfload cache: %s", category)
    report_indeed("location: %s", path)
    report_indeed("[raw]       %4i", #luanames)
    report_indeed("[compiled]  %4i", #lucnames)
    report_indeed("[other]     %4i", #rest)
    report_indeed("[total]     %4i", #luanames + #lucnames + #rest)
end

--- string -> string -> string list -> bool -> bool
local function purge_from_cache (category, path, list, all)
    logreport ("info", 1, "cache", "Luaotfload cache: %s %s",
               (all and "erase" or "purge"), category)
    logreport ("info", 1, "cache", "location: %s", path)
    local n = 0
    for i=1,#list do
        local filename = list[i]
        if stringfind(filename,"luatex%-cache") then -- safeguard
            if all then
                logreport ("info", 5, "cache", "Removing %s.", filename)
                osremove(filename)
                n = n + 1
            else
                local suffix = filesuffix(filename)
                if suffix == "lua" then
                    local checkname = file.replacesuffix(
                        filename, "lua", "luc")
                    if lfsisfile(checkname) then
                        logreport ("info", 5, "cache", "Removing %s.", filename)
                        osremove(filename)
                        n = n + 1
                    end
                end
            end
        end
    end
    logreport ("info", 1, "cache", "Removed lua files : %i", n)
    return true
end

--- string -> string list -> int -> string list -> string list -> string list ->
---     (string list * string list * string list * string list)
local function collect_cache (path, all, n, luanames, lucnames, rest)
    if not all then
        local all = find_files (path)

        local luanames, lucnames, rest = { }, { }, { }
        return collect_cache(nil, all, 1, luanames, lucnames, rest)
    end

    local filename = all[n]
    if filename then
        local suffix = filesuffix(filename)
        if suffix == "lua" then
            luanames[#luanames+1] = filename
        elseif suffix == "luc" then
            lucnames[#lucnames+1] = filename
        else
            rest[#rest+1] = filename
        end
        return collect_cache(nil, all, n+1, luanames, lucnames, rest)
    end
    return luanames, lucnames, rest, all
end

local function getwritablecachepath ( )
    --- fonts.handlers.otf doesn’t exist outside a Luatex run,
    --- so we have to improvise
    local writable = getwritablepath (config.luaotfload.paths.cache_dir, "")
    if writable then
        return writable
    end
end

local function getreadablecachepaths ( )
    local readables = caches.getreadablepaths
                        (config.luaotfload.paths.cache_dir)
    local result    = { }
    if readables then
        for i=1, #readables do
            local readable = readables[i]
            if lfsisdir (readable) then
                result[#result+1] = readable
            end
        end
    end
    return result
end

--- unit -> unit
local function purge_cache ( )
    local writable_path = getwritablecachepath ()
    local luanames, lucnames, rest = collect_cache(writable_path)
    if log.get_loglevel() > 1 then
        print_cache("writable path", writable_path, luanames, lucnames, rest)
    end
    local success = purge_from_cache("writable path", writable_path, luanames, false)
    return success
end

--- unit -> unit
local function erase_cache ( )
    local writable_path = getwritablecachepath ()
    local luanames, lucnames, rest, all = collect_cache(writable_path)
    if log.get_loglevel() > 1 then
        print_cache("writable path", writable_path, luanames, lucnames, rest)
    end
    local success = purge_from_cache("writable path", writable_path, all, true)
    return success
end

local function separator ( )
    logreport ("info", 0, string.rep("-", 67))
end

--- unit -> unit
local function show_cache ( )
    local readable_paths = getreadablecachepaths ()
    local writable_path  = getwritablecachepath ()
    local luanames, lucnames, rest = collect_cache(writable_path)

    separator ()
    print_cache ("writable path", writable_path,
                 luanames, lucnames, rest)
    texio.write_nl""
    for i=1,#readable_paths do
        local readable_path = readable_paths[i]
        if readable_path ~= writable_path then
            local luanames, lucnames = collect_cache (readable_path)
            print_cache ("readable path",
                         readable_path, luanames, lucnames, rest)
        end
    end
    separator()
    return true
end

-----------------------------------------------------------------------
--- API assumptions of the fontloader
-----------------------------------------------------------------------
--- PHG: we need to investigate these, maybe they’re useful as early
---      hooks

local function reportmissingbase ()
    logreport ("info", 0, "db", --> bug‽
               "Font name database not found but expected by fontloader.")
    fonts.names.reportmissingbase = nil
end

local function reportmissingname ()
    logreport ("info", 0, "db", --> bug‽
               "Fontloader attempted to lookup name before Luaotfload \z
                was initialized.")
    fonts.names.reportmissingname = nil
end

local function getfilename (a1, a2)
    logreport ("info", 6, "db", --> bug‽
               "Fontloader looked up font file (%s, %s) before Luaotfload \z
                was initialized.", tostring(a1), tostring(a2))
    return lookup_fullpath (a1, a2)
end

local function resolve (name, subfont)
    logreport ("info", 6, "db", --> bug‽
               "Fontloader attempted to resolve name (%s, %s) before \z
                Luaotfload was initialized.", tostring(name), tostring(subfont))
    return lookup_font_name { name = name, sub = subfont }
end

local api = {
    ignoredfile       = function() return false end,
    reportmissingbase = reportmissingbase,
    reportmissingname = reportmissingname,
    getfilename       = getfilename,
    resolve           = resolve,
}

-----------------------------------------------------------------------
--- export functionality to the namespace “fonts.names”
-----------------------------------------------------------------------

local export = {
    set_font_filter             = set_font_filter,
    set_size_dimension          = set_size_dimension,
    flush_lookup_cache          = flush_lookup_cache,
    save_lookups                = save_lookups,
    load                        = load_names,
    access_font_index           = access_font_index,
    data                        = function () return name_index end,
    save                        = save_names,
    update                      = update_names,
    lookup_font_file            = lookup_font_file,
    lookup_font_name            = lookup_font_name,
    lookup_font_name_cached     = lookup_font_name_cached,
    getfilename                 = lookup_fullpath,
    lookup_fullpath             = lookup_fullpath,
    read_blacklist              = read_blacklist,
    sanitize_fontname           = sanitize_fontname,
    getmetadata                 = getmetadata,
    set_location_precedence     = set_location_precedence,
    count_font_files            = count_font_files,
    nth_font_filename           = nth_font_filename,
    font_slice                  = font_slice,
    lookup_subfont_index        = lookup_subfont_index,
    --- font cache
    purge_cache                 = purge_cache,
    erase_cache                 = erase_cache,
    show_cache                  = show_cache,
    find_closest                = find_closest,
}

return function ()
    --- the font loader namespace is “fonts”, same as in Context
    --- we need to put some fallbacks into place for when running
    --- as a script
    if not fonts then return false end
    logreport       = luaotfload.log.report
    local fonts     = fonts
    fonts.names     = fonts.names or names
    fonts.formats   = fonts.formats or { }
    fonts.definers  = fonts.definers or { resolvers = { } }

    names.blacklist = blacklist
    names.version   = 6        --- increase monotonically
    names.data      = nil      --- contains the loaded database
    names.lookups   = nil      --- contains the lookup cache

    enabled_locations['local'] = enabled_locations['local'] and config.luaotfload.db.scan_local == true
    for sym, ref in next, export do names[sym] = ref end
    for sym, ref in next, api    do names[sym] = names[sym] or ref end
    return true
end

-- vim:tw=71:sw=4:ts=4:expandtab
