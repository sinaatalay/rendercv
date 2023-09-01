-- 
--  This is file `fontspec.lua',
--  generated with the docstrip utility.
-- 
--  The original source files were:
-- 
--  fontspec.dtx  (with options: `lua')
--  fontspec-lua.dtx  (with options: `lua')
--  ------------------------------------------------
--  The FONTSPEC package  <wspr.io/fontspec>
--  ------------------------------------------------
--  Copyright  2004-2017  Will Robertson, LPPL "maintainer"
--  Copyright  2009-2013  Khaled Hosny
--  ------------------------------------------------
--  This package is free software and may be redistributed and/or modified under
--  the conditions of the LaTeX Project Public License, version 1.3c or higher
--  (your choice): <http://www.latex-project.org/lppl/>.
--  ------------------------------------------------
-- ^^A%%  fontspec.dtx -- part of FONTSPEC <wspr.io/fontspec>
-- ^^A%%  Metadata for the package, including files and versioning

fontspec          = fontspec or {}
local fontspec    = fontspec
fontspec.module   = {
    name          = "fontspec",
    version       = "2.8a",
    date          = "2022/01/15",
    description   = "Font selection for XeLaTeX and LuaLaTeX",
    author        = "Khaled Hosny, Philipp Gesang, Will Robertson",
    copyright     = "Khaled Hosny, Philipp Gesang, Will Robertson",
    license       = "LPPL v1.3c"
}

-- ^^A%%  fontspec-lua.dtx -- part of FONTSPEC <wspr.io/fontspec>
local err, warn, info, log = luatexbase.provides_module(fontspec.module)
fontspec.log     = log  or (function (s) luatexbase.module_info("fontspec", s)    end)
fontspec.warning = warn or (function (s) luatexbase.module_warning("fontspec", s) end)
fontspec.error   = err  or (function (s) luatexbase.module_error("fontspec", s)   end)
local latex
if luatexbase.registernumber then
    latex = luatexbase.registernumber("catcodetable@latex")
else
    latex = luatexbase.catcodetables.CatcodeTableLaTeX
end
local function tempswatrue()  tex.sprint(latex,[[\FontspecSetCheckBoolTrue ]]) end
local function tempswafalse() tex.sprint(latex,[[\FontspecSetCheckBoolFalse]]) end
function fontspec.check_ot_script(fnt, script)
    if luaotfload.aux.provides_script(font.id(fnt), script) then
        tempswatrue()
    else
        tempswafalse()
    end
end
function fontspec.check_ot_lang(fnt, lang, script)
    if luaotfload.aux.provides_language(font.id(fnt), script, lang) then
        tempswatrue()
    else
        tempswafalse()
    end
end
function fontspec.check_ot_feat(fnt, feat, lang, script)
    for _, f in ipairs { "+trep", "+tlig", "+anum" } do
        if feat == f then
            tempswatrue()
            return
        end
    end
    if luaotfload.aux.provides_feature(font.id(fnt), script, lang, feat) then
        tempswatrue()
    else
        tempswafalse()
    end
end
function fontspec.mathfontdimen(fnt, str)
    local mathdimens = luaotfload.aux.get_math_dimension(fnt, str)
    if mathdimens then
        tex.sprint(-2,mathdimens)
        tex.sprint(-2,"sp")
    else
        tex.sprint(-2,"0pt")
    end
end

