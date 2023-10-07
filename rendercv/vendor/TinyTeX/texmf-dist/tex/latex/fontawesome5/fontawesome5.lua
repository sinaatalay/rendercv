-- Copyright 2018--2022 Marcel Krueger
--
-- This work may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3c
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--   http://www.latex-project.org/lppl.txt
-- and version 1.3 or later is part of all distributions of LaTeX
-- version 2005/12/01 or later.
--
-- This work has the LPPL maintenance status `maintained'.
-- 
-- The Current Maintainer of this work is Marcel Krueger
--

function fontawesome5_analyze_current_font(fontid)
  local specialnames = {
    ["500px"]=true,
    h1=true,
    h2=true,
    h3=true,
    wifi=true,
    ["wifi-1"]=true,
    ["wifi-2"]=true,
    signal=true,
    ["signal-1"]=true,
    ["signal-2"]=true,
    ["signal-3"]=true,
    ["signal-4"]=true,
    ["signal-alt-1"]=true,
    ["signal-alt-2"]=true,
    ["signal-alt-3"]=true,
    stopwatch=true,
    ["stopwatch-20"]=true,
    transporter=true,
    ["transporter-1"]=true,
    ["transporter-2"]=true,
    ["transporter-3"]=true,
    ["repeat"]=true,
    ["repeat-1"]=true,
    ["dice-d4"]=true,
    ["dice-d6"]=true,
    ["dice-d8"]=true,
    ["dice-d10"]=true,
    ["dice-d12"]=true,
    ["dice-d20"]=true,
  }
  for name, value in pairs(font.getfont(fontid).resources.unicodes) do
    tex.sprint(
        luatexbase.catcodetables.expl,
        "\\exp_args:NNc\\tex_global:D\\tex_chardef:D{c__fontawesome_slot_" .. name .. '_char}' .. value .. '\\scan_stop:')
    if not (
          ('-alt' == string.sub(name, -4))
       or specialnames[name]
       or value < 256
    ) then
      tex.sprint(
          luatexbase.registernumber("CatcodeTableExpl"),
          "\\cs_gset_protected:Npn"
            .. string.gsub('\\fa-' .. name, '-(%w)', string.upper)
            .. "{\\faPreselectedIcon{" .. name .. "}}")
    end
  end
end
