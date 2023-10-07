-------------------------------------------------------------------------------
--         FILE:  luaotfload-filelist.lua
--  DESCRIPTION:  part of luaotfload / list of files
--       AUTHOR:  Ulrike Fischer, <fischer@troubleshooting-tex.de>
-----------------------------------------------------------------------

if luaotfload_module then luaotfload_module {
    name          = "luaotfload-filelist",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / filelist",
    license       = "GPL v2.0"
} end

--[[doc-- 

luaotfload has tables with files list in many places: In the import scripts, 
in the init file, in the documentation. This makes maintenance difficult. 
This here is a try to get everything in one place. As the order how files are 
loaded during the merge matters the table is an array. Lists with other 
sorting should be created with functions. Ditto for subtables.  

Some redundancy can not be avoided for now if one want to avoid to have to change all sort of functions. 
 
## locations
files can reside in up to three location (with perhaps different names)
- context     ctxdir
- git         gitdir
- texmf       texdir

files don't need to exist in all locations but the direction of the flow is 
always from context over git to texmf:
  context-> git -> texmf 
so the "stations" of a file and its source can be deduced by the dirs recorded in the entries 


## "kind"
the first four entries are from the original mkimport code and are important for the imports.
the others are new.

   · *essential*:     Files required at runtime.
   · *merged*:        Files merged into the fontloader package.
   · *ignored*:       Lua files not merged, but part of the format.
   · *tex*:           TeX code, i.e. format and examples.
   · *lualibs*:       Files imported, but also provided by the Lualibs package.
   · *library*:       native luaotfload-files of type library
   · *core*:          native core luaotfload files
   · *generated*:     generated luaotfload files
   · *scripts*:       scripts (mk-...)
   · *docu*:          documentation (should perhaps be more refined

## names

The "real" name of a file in a location can be build 

- in the context location:  ctxpref + name + ext
- in the git location:     (gitpref or "fontloader-") + (ours or name ) + ext
- in the tex location:     (gitpref or "fontloader-") + (texname or ours or name ) + ext 

## fields
 mkstatus: used to ignore some files in mkstatus
  
 
## files which use the file names

### mkimport

 mkimports needs an 
 --> "import" table with two subtables:
  --> fontloader, with the files to get from generic, cond: ctxtype = "ctxgene"
  --> context, with the files to get from context,    cond: ctxtype = "ctxbase"
  entries are subtables with {name=, ours=, kind= }

and a 
 --> "package" table with 
  --> optional (probably unused)
  --> required = files of type kind_merged
  entries are the values of name
  
### mkstatus

this script has been already changed to use luaotfload-filelist.lua
   
### luaotfload-init.lua

luaotfload-init.lua needs a table
--> context_modules
with the (ordered) entries

{false, "name"}            -- kind_lualibs
{ctxdir,"ctxprefix+name"} -- kind_essential or kind_merged 

The same list should be used in local init_main = function ()
but only without the prefix.
it is unclear how fonts_syn should be handled!!!!
   
### filegraph.tex
has been already adapted

### luaotfload-latex.tex/luaotfload-main.tex
has been already adapted

### build.lua
???
   
--doc]]--


local kind_essential = 0
local kind_merged    = 1
local kind_tex       = 2
local kind_ignored   = 3
local kind_lualibs   = 4
local kind_library   = 5
local kind_core      = 6
local kind_generated = 7
local kind_script   = 8
local kind_docu      = 9

local kind_name = {
  [0] = "essential",
  [1] = "merged"   ,
  [2] = "tex"      ,
  [3] = "ignored"  ,
  [4] = "lualibs"  ,
  [5] = "library"  ,
  [6] = "core",
  [7] = "generated",
  [8] = "script",
  [9] = "docu"
}


local   ctxdirbas = "tex/context/base/mkiv/"
local   ctxdirgen = "tex/generic/context/luatex/"

local   gitdirimp  = "src/fontloader/misc/" -- imp=imported
local   gitdirsrc  = "src/"
local   gitdiress =  "src/fontloader/runtime/"
local   gitdirgen =  "src/fontloader/auto/"
local   gitdirdoc =  "doc/"
local   gitdirscr =  "scripts/" 
local   gitdirmain = "./"

-- these here a not really pathes
local   texdirtex  = "tex"
local   texdirscr  = "scripts"
local   texdirdoc  = "doc"
local   texdirman  = "man" 

luaotfload = luaotfload or {}
luaotfload.filelist = luaotfload.filelist or {}
  
luaotfload.filelist.data =  
 {
  -- at first the source files from context
    { name = "l-lua"             , ours = "l-lua"             , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-lpeg"            , ours = "l-lpeg"            , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-function"        , ours = "l-function"        , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-string"          , ours = "l-string"          , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-table"           , ours = "l-table"           , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-io"              , ours = "l-io"              , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-file"            , ours = "l-file"            , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-boolean"         , ours = "l-boolean"         , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-math"            , ours = "l-math"            , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "l-unicode"         , ours = "l-unicode"         , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" }, 

    { name = "util-str"          , ours = "util-str"          , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "util-fil"          , ours = "util-fil"          , ext = ".lua", kind = kind_lualibs   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },

    { name = "basics-gen"        , ours = nil                 , ext = ".lua", kind = kind_essential , gitdir=gitdiress, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" },
-- files merged in the fontloader. One file is ignored
    { name = "data-con"          , ours = "data-con"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "basics-nod"        , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" },
    { name = "basics-chr"        , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" }, 
    { name = "font-ini"          , ours = "font-ini"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "fonts-mis"         , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" }, 
    { name = "font-con"          , ours = "font-con"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "fonts-enc"         , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" },
    { name = "font-cid"          , ours = "font-cid"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-map"          , ours = "font-map"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "fonts-syn"         , ours = nil                 , ext = ".lua", kind = kind_ignored   , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" },
    { name = "font-vfc"          , ours = "font-vfc"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" }, 
    { name = "font-otr"          , ours = "font-otr"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-cff"          , ours = "font-cff"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-ttf"          , ours = "font-ttf"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-dsp"          , ours = "font-dsp"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-oti"          , ours = "font-oti"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-ott"          , ours = "font-ott"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" }, 
    { name = "font-otl"          , ours = "font-otl"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-oto"          , ours = "font-oto"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-otj"          , ours = "font-otj"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-oup"          , ours = "font-oup"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-ota"          , ours = "font-ota"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-ots"          , ours = "font-ots"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-otc"          , ours = "font-otc"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-osd"          , ours = "font-osd"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-ocl"          , ours = "font-ocl"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-onr"          , ours = "font-onr"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-one"          , ours = "font-one"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-afk"          , ours = "font-afk"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "fonts-tfm"         , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxgene" , ctxpref = "luatex-" },    
    { name = "font-lua"          , ours = "font-lua"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-def"          , ours = "font-def"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" }, 
    { name = "font-shp"          , ours = "font-shp"          , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" }, 
    { name = "fonts-def"         , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" }, 
    { name = "fonts-ext"         , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" },
    { name = "font-imp-tex"      , ours = "font-imp-tex"      , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-imp-ligatures", ours = "font-imp-ligatures", ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-imp-italics"  , ours = "font-imp-italics"  , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "font-imp-effects"  , ours = "font-imp-effects"  , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirbas, ctxtype = "ctxbase" },
    { name = "fonts-lig"         , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" }, 
    { name = "fonts-gbn"         , ours = nil                 , ext = ".lua", kind = kind_merged    , gitdir=gitdirimp, texdir = texdirtex , ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" }, 
-- end of files merged

    { name = "fonts-merged"      , ours = "reference"         , ext = ".lua", kind = kind_essential , gitdir=gitdiress, texdir = texdirtex , ctxdir= ctxdirgen ,ctxtype = "ctxgene" , ctxpref = "luatex-" },


 
--  this two files are useful as reference for the load order but should not be installed                                                              
    { name = "fonts"             , ours = "load-order-reference", ext = ".lua", kind = kind_ignored , gitdir=gitdirimp, ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" }, 
    { name = "fonts"             , ours = "load-order-reference", ext = ".tex", kind = kind_tex     , gitdir=gitdirimp, ctxdir= ctxdirgen, ctxtype = "ctxgene" , ctxpref = "luatex-" },

-- the default fontloader. How to code the name??
    { name = "YYYY-MM-DD"        , ext = ".lua", kind = kind_generated , gitdir = gitdirgen, texdir = texdirtex,mkstatus="auto" },

-- the luaotfload files
    { name = "luaotfload"        ,kind = kind_core, ext =".sty", gitdir=gitdirsrc, texdir=texdirtex, gitpref="",},
    { name = "main"              ,kind = kind_core, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "init"              ,kind = kind_core, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "log"               ,kind = kind_core, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "diagnostics"       ,kind = kind_core, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    
    { name = "tool"              ,kind = kind_core, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "blacklist"         ,kind = kind_core, ext =".cnf", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },

    { name = "filelist"          ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "auxiliary"         ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "colors"            ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "configuration"     ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "database"          ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "features"          ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" }, 
    { name = "letterspace"       ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" }, 
    { name = "embolden"          ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "notdef"            ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "harf-define"       ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "harf-plug"         ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "loaders"           ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" }, 
    { name = "multiscript"       ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" }, 
    { name = "scripts"           ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "szss"              ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "fallback"          ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" }, 
    { name = "parsers"           ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" }, 
    { name = "resolvers"         ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" }, 
    { name = "unicode"           ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "tounicode"         ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },
    { name = "dvi"               ,kind = kind_library, ext =".lua", gitdir=gitdirsrc, texdir=texdirtex, gitpref = "luaotfload-" },

    { name = "characters"        ,kind = kind_generated, ext =".lua", gitdir=gitdirgen, texdir=texdirtex, gitpref = "luaotfload-", script="mkcharacter" },
    { name = "glyphlist"         ,kind = kind_generated, ext =".lua", gitdir=gitdirgen, texdir=texdirtex, gitpref = "luaotfload-", script="mkglyphlist" },
    { name = "status"            ,kind = kind_generated, ext =".lua", gitdir=gitdirgen, texdir=texdirtex, gitpref = "luaotfload-", script="mkstatus",mkstatus="ignore" },
     


-- scripts
    { name = "mkimport"       ,kind = kind_script, gitdir = gitdirscr, gitpref = "", ext=""},
    { name = "mkglyphlist"   ,kind = kind_script, gitdir = gitdirscr, gitpref = "", ext=""}, 
    { name = "mkcharacters"   ,kind = kind_script, gitdir = gitdirscr, gitpref = "", ext=""},
    { name = "mkstatus"       ,kind = kind_script, gitdir = gitdirscr, gitpref = "", ext=""},
    { name = "mktests"         ,kind = kind_script, gitdir = gitdirscr, gitpref = "", ext=""},
    
-- documentation (source dirs need perhaps coding ...) but don't overdo for now

   { name = "latex"      , kind= kind_docu, ext = ".tex", gitpref = "luaotfload-", gitdir = gitdirdoc, texdir= texdirdoc,  typeset = true },
   { name = "main"       , kind= kind_docu, ext = ".tex", gitpref = "luaotfload-", gitdir = gitdirdoc, texdir= texdirdoc,  typeset = false },
   { name = "conf"       , kind= kind_docu, ext = ".tex", gitpref = "luaotfload-", gitdir = gitdirdoc, texdir= texdirdoc,  typeset = true , generated = true},
   { name = "tool"       , kind= kind_docu, ext = ".tex", gitpref = "luaotfload-", gitdir = gitdirdoc, texdir= texdirdoc,  typeset = true , generated = true},
   { name = "filegraph"  , kind= kind_docu, ext = ".tex", gitpref ="",             gitdir = gitdirdoc, texdir= texdirdoc,  typeset = true , generated = true},
   { name = "conf"       , kind= kind_docu, ext = ".rst", gitpref = "luaotfload.", gitdir = gitdirdoc, texdir= texdirdoc },
   { name = "conf"       , kind= kind_docu, ext = ".5"  , gitpref = "luaotfload.", gitdir = gitdirdoc, texdir= texdirman},  
   { name = "tool"       , kind= kind_docu, ext = ".rst", gitpref = "luaotfload-", gitdir = gitdirdoc, texdir= texdirdoc},       
   { name = "tool"       , kind= kind_docu, ext = ".1"  , gitpref = "luaotfload-", gitdir = gitdirdoc, texdir= texdirman },
   { name = "README"     , kind= kind_docu, texname = "README", gitpref="", ext = ".md" , gitdir = gitdirdoc,  texdir= texdirdoc},
   { name = "COPYING"    , kind= kind_docu, ext = ""    , gitpref="", gitdir = gitdirmain,   texdir= texdirdoc},
   { name = "NEWS"       , kind= kind_docu, ext = ""    , gitpref="", gitdir = gitdirmain ,  texdir= texdirdoc},
   { name = "README"     , kind= kind_docu, gitpref="", ext = ".md" , gitdir = gitdirmain}, -- github readme
   
}



-- functions
-- list of kind:
--local kind_essential = 0
--local kind_merged    = 1
--local kind_tex       = 2
--local kind_ignored   = 3
--local kind_lualibs   = 4
--local kind_library   = 5
--local kind_core      = 6
--local kind_generated = 7
--local kind_script    = 8
--local kind_docu      = 9


-- some selections
-- due to the history and setup of the other files, there are not always simple "kind" selections.
-- ctx base files are splitted in two sets:
-- 1. font & node
function luaotfload.filelist.selectctxfontentries ( filetable )
  local result = {}
  for i,v in ipairs (filetable) do
   if v.ctxtype == "ctxbase" and v.kind==1 then
    table.insert(result,v)
   end
  end
  return result
end

-- 2. lualibs libraries
function luaotfload.filelist.selectctxlibsentries ( filetable )
  local result = {}
  for i,v in ipairs (filetable) do
   if v.ctxtype == "ctxbase" and v.kind==4 then
    table.insert(result,v)
   end
  end
  return result
end

-- ctx generic files 
-- 1. ignored files are not in the list ...
function luaotfload.filelist.selectctxgeneusedentries ( filetable )
  local result = {}
  for i,v in ipairs (filetable) do
   if v.ctxtype == "ctxgene" and v.kind==1 then
    table.insert(result,v)
   end
  end
  return result
end

-- 2. ignored files are in the list
function luaotfload.filelist.selectctxgeneentries ( filetable )
  local result = {}
  for i,v in ipairs (filetable) do
   if v.ctxtype == "ctxgene" and (v.kind==1  or v.kind== 3) then
    table.insert(result,v)
   end
  end
  return result
end

-- luaotfload-files (lol) are splitted in essential (0), core (6), lib (5) and gene (7) and scr (scripts):
-- luaoftload libraries

function luaotfload.filelist.selectlolessentries (filetable)
 local result = {}  
 for i,v in ipairs (filetable) do
  if v.kind == 0 then
   table.insert (result,v)
  end
 end
 return result
end   


function luaotfload.filelist.selectlollibentries (filetable)
 local result = {}  
 for i,v in ipairs (filetable) do
  if v.kind == 5 then
   table.insert (result,v)
  end
 end
 return result
end   

-- luaoftload core

function luaotfload.filelist.selectlolcoreentries (filetable)
 local result = {}  
 for i,v in ipairs (filetable) do
  if v.kind == 6 then
   table.insert (result,v)
  end
 end
 return result
end   

-- core and lib  lua-files

function luaotfload.filelist.selectlolsrcluaentries (filetable)
 local result = {}  
 for i,v in ipairs (filetable) do
  if (v.kind == 5 or  v.kind==6) and v.ext==".lua" then
   table.insert (result,v)
  end
 end
 return result
end   



-- luaoftload generated

function luaotfload.filelist.selectlolgeneentries (filetable)
 local result = {}  
 for i,v in ipairs (filetable) do
  if v.kind == 7 then
   table.insert (result,v)
  end
 end
 return result
end   



-- scripts
function luaotfload.filelist.selectlolscrentries ( filetable )
  local result = {}
  for i,v in ipairs (filetable) do
   if  v.kind==8 then
    table.insert(result,v)
   end
  end
  return result
end






