--
-- This is file `babel-data-cjk.lua',
-- generated with the docstrip utility.
--
-- The original source files were:
--
-- babel.dtx  (with options: `cjkdata')
-- 
--
-- Copyright (C) 2012-2023 Javier Bezos and Johannes L. Braams.
-- Copyright (C) 1989-2012 Johannes L. Braams and
--           any individual authors listed elsewhere in this file.
-- All rights reserved.
--
--
-- This file is part of the Babel system.
-- --------------------------------------
--
-- It may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--   http://www.latex-project.org/lppl.txt
-- and version 1.3 or later is part of all distributions of LaTeX
-- version 2003/12/01 or later.
--
-- This work has the LPPL maintenance status "maintained".
--
-- The Current Maintainer of this work is Javier Bezos.
--
-- The list of derived (unpacked) files belonging to the distribution
-- and covered by LPPL is defined by the unpacking scripts (with
-- extension |.ins|) which are part of the distribution.
--

Babel = Babel or {}

Babel.cjk_characters = {
  [0x0021]={c='ex'},
  [0x0022]={c='qu'},
  [0x0024]={c='pr'},
  [0x0025]={c='po'},
  [0x0027]={c='qu'},
  [0x0028]={c='op'},
  [0x0029]={c='cp'},
  [0x002B]={c='pr'},
  [0x002C]={c='is'},
  [0x002D]={c='hy'},
  [0x002E]={c='is'},
  [0x002F]={c='sy'},
  [0x003A]={c='is'},
  [0x003B]={c='is'},
  [0x003F]={c='ex'},
  [0x005B]={c='op'},
  [0x005C]={c='pr'},
  [0x005D]={c='cp'},
  [0x007B]={c='op'},
  [0x007D]={c='cl'},
  [0x00A1]={c='op'},
  [0x00A2]={c='po'},
  [0x00A3]={c='pr'},
  [0x00A4]={c='pr'},
  [0x00A5]={c='pr'},
  [0x00AB]={c='qu'},
  [0x00B0]={c='po'},
  [0x00B1]={c='pr'},
  [0x00BB]={c='qu'},
  [0x2018]={c='qu'},
  [0x2019]={c='qu'},
  [0x201A]={c='op'},
  [0x201B]={c='qu'},
  [0x201C]={c='qu'},
  [0x201D]={c='qu'},
  [0x201E]={c='op'},
  [0x201F]={c='qu'},
  [0x2024]={c='in'},
  [0x2025]={c='in'},
  [0x2026]={c='in'},
  [0x2030]={c='po'},
  [0x2031]={c='po'},
  [0x2032]={c='po'},
  [0x2033]={c='po'},
  [0x2034]={c='po'},
  [0x2035]={c='po'},
  [0x2036]={c='po'},
  [0x2037]={c='po'},
  [0x2039]={c='qu'},
  [0x203A]={c='qu'},
  [0x203C]={c='ns'},
  [0x203D]={c='ns'},
  [0x2044]={c='is'},
  [0x2045]={c='op'},
  [0x2046]={c='cl'},
  [0x2047]={c='ns'},
  [0x2048]={c='ns'},
  [0x2049]={c='ns'},
  [0x207D]={c='op'},
  [0x207E]={c='cl'},
  [0x208D]={c='op'},
  [0x208E]={c='cl'},
  [0x20A7]={c='po'},
  [0x20B6]={c='po'},
  [0x20BB]={c='po'},
  [0x20BE]={c='po'},
  [0x2103]={c='po'},
  [0x2109]={c='po'},
  [0x2116]={c='pr'},
  [0x2212]={c='pr'},
  [0x2213]={c='pr'},
  [0x22EF]={c='in'},
  [0x2308]={c='op'},
  [0x2309]={c='cl'},
  [0x230A]={c='op'},
  [0x230B]={c='cl'},
  [0x2329]={c='op'},
  [0x232A]={c='cl'},
  [0x2983]={c='op'},
  [0x2984]={c='cl'},
  [0x2985]={c='op'},
  [0x2986]={c='cl'},
  [0x2987]={c='op'},
  [0x2988]={c='cl'},
  [0x2989]={c='op'},
  [0x298A]={c='cl'},
  [0x298B]={c='op'},
  [0x298C]={c='cl'},
  [0x298D]={c='op'},
  [0x298E]={c='cl'},
  [0x298F]={c='op'},
  [0x2990]={c='cl'},
  [0x2991]={c='op'},
  [0x2992]={c='cl'},
  [0x2993]={c='op'},
  [0x2994]={c='cl'},
  [0x2995]={c='op'},
  [0x2996]={c='cl'},
  [0x2997]={c='op'},
  [0x2998]={c='cl'},
  [0x29D8]={c='op'},
  [0x29D9]={c='cl'},
  [0x29DA]={c='op'},
  [0x29DB]={c='cl'},
  [0x29FC]={c='op'},
  [0x29FD]={c='cl'},
  [0x2CF9]={c='ex'},
  [0x2CFE]={c='ex'},
  [0x2E02]={c='qu'},
  [0x2E03]={c='qu'},
  [0x2E04]={c='qu'},
  [0x2E05]={c='qu'},
  [0x2E06]={c='qu'},
  [0x2E07]={c='qu'},
  [0x2E08]={c='qu'},
  [0x2E09]={c='qu'},
  [0x2E0A]={c='qu'},
  [0x2E0B]={c='qu'},
  [0x2E0C]={c='qu'},
  [0x2E0D]={c='qu'},
  [0x2E18]={c='op'},
  [0x2E1C]={c='qu'},
  [0x2E1D]={c='qu'},
  [0x2E20]={c='qu'},
  [0x2E21]={c='qu'},
  [0x2E22]={c='op'},
  [0x2E23]={c='cl'},
  [0x2E24]={c='op'},
  [0x2E25]={c='cl'},
  [0x2E26]={c='op'},
  [0x2E27]={c='cl'},
  [0x2E28]={c='op'},
  [0x2E29]={c='cl'},
  [0x2E2E]={c='ex'},
  [0x2E42]={c='op'},
  [0x3001]={c='cl'},
  [0x3002]={c='cl'},
  [0x3005]={c='ns'},
  [0x3008]={c='op'},
  [0x3009]={c='cl'},
  [0x300A]={c='op'},
  [0x300B]={c='cl'},
  [0x300C]={c='op'},
  [0x300D]={c='cl'},
  [0x300E]={c='op'},
  [0x300F]={c='cl'},
  [0x3010]={c='op'},
  [0x3011]={c='cl'},
  [0x3014]={c='op'},
  [0x3015]={c='cl'},
  [0x3016]={c='op'},
  [0x3017]={c='cl'},
  [0x3018]={c='op'},
  [0x3019]={c='cl'},
  [0x301A]={c='op'},
  [0x301B]={c='cl'},
  [0x301C]={c='ns'},
  [0x301D]={c='op'},
  [0x301E]={c='cl'},
  [0x301F]={c='cl'},
  [0x303B]={c='ns'},
  [0x303C]={c='ns'},
  [0x309B]={c='ns'},
  [0x309C]={c='ns'},
  [0x309D]={c='ns'},
  [0x309E]={c='ns'},
  [0x30A0]={c='ns'},
  [0x30FB]={c='ns'},
  [0x30FD]={c='ns'},
  [0x30FE]={c='ns'},
  [0xA015]={c='ns'},
  [0xA60E]={c='ex'},
  [0xA838]={c='po'},
  [0xFD3E]={c='cl'},
  [0xFD3F]={c='op'},
  [0xFDFC]={c='po'},
  [0xFE10]={c='is'},
  [0xFE11]={c='cl'},
  [0xFE12]={c='cl'},
  [0xFE13]={c='is'},
  [0xFE14]={c='is'},
  [0xFE15]={c='ex'},
  [0xFE16]={c='ex'},
  [0xFE17]={c='op'},
  [0xFE18]={c='cl'},
  [0xFE19]={c='in'},
  [0xFE35]={c='op'},
  [0xFE36]={c='cl'},
  [0xFE37]={c='op'},
  [0xFE38]={c='cl'},
  [0xFE39]={c='op'},
  [0xFE3A]={c='cl'},
  [0xFE3B]={c='op'},
  [0xFE3C]={c='cl'},
  [0xFE3D]={c='op'},
  [0xFE3E]={c='cl'},
  [0xFE3F]={c='op'},
  [0xFE40]={c='cl'},
  [0xFE41]={c='op'},
  [0xFE42]={c='cl'},
  [0xFE43]={c='op'},
  [0xFE44]={c='cl'},
  [0xFE47]={c='op'},
  [0xFE48]={c='cl'},
  [0xFE50]={c='cl'},
  [0xFE52]={c='cl'},
  [0xFE54]={c='ns'},
  [0xFE55]={c='ns'},
  [0xFE56]={c='ex'},
  [0xFE57]={c='ex'},
  [0xFE59]={c='op'},
  [0xFE5A]={c='cl'},
  [0xFE5B]={c='op'},
  [0xFE5C]={c='cl'},
  [0xFE5D]={c='op'},
  [0xFE5E]={c='cl'},
  [0xFE69]={c='pr'},
  [0xFE6A]={c='po'},
  [0xFF01]={c='ex', w='f'},
  [0xFF04]={c='pr', w='f'},
  [0xFF05]={c='po', w='f'},
  [0xFF08]={c='op', w='f'},
  [0xFF09]={c='cl', w='f'},
  [0xFF0C]={c='cl', w='f'},
  [0xFF0E]={c='cl', w='f'},
  [0xFF1A]={c='ns', w='f'},
  [0xFF1B]={c='ns', w='f'},
  [0xFF1F]={c='ex', w='f'},
  [0xFF3B]={c='op', w='f'},
  [0xFF3D]={c='cl', w='f'},
  [0xFF5B]={c='op', w='f'},
  [0xFF5D]={c='cl', w='f'},
  [0xFF5F]={c='op', w='f'},
  [0xFF60]={c='cl', w='f'},
  [0xFF61]={c='cl', w='h'},
  [0xFF62]={c='op', w='h'},
  [0xFF63]={c='cl', w='h'},
  [0xFF64]={c='cl', w='h'}
}

Babel.cjk_class = setmetatable ( Babel.cjk_characters, {
  __index = function(_, k)
    if (k >= 0xAC00  and k <= 0xD7A3)      -- H2/H3
        or (k >= 0x2E80  and k <= 0x9FFF)
        or (k >= 0xA000  and k <= 0xA48F)  -- Yi
        or (k >= 0xA490  and k <= 0xA4CF)  -- Yi
        or (k >= 0xF900  and k <= 0xFAFF)
        or (k >= 0xFE10  and k <= 0xFE1F)
        or (k >= 0xFE30  and k <= 0xFE6F)
        or (k >= 0xFF00  and k <= 0xFFEF)
        or (k >= 0x1F000 and k <= 0x1FFFD)
        or (k >= 0x20000 and k <= 0x2FFFD)
        or (k >= 0x30000 and k <= 0x3FFFD) then
      return {c='I'}
    elseif (k >= 0x20A0  and k <= 0x20CF) then
      return {c='pr'}
    else
      return {c='O'}
    end
  end })

-- Note ns = ex = sy = is = po = hy. Here, 'I' and 'O' are
-- pseudo-classes for ideographic-like (id, h2, h3), and 'other',
-- respectively. Jamo is not considered yet, but very likely at least
-- jl must be.

Babel.cjk_breaks = {
  ['op'] = { },
  ['cl'] = { ['op']=1, ['pr']=1,           ['in']=1, ['I']=1 },
  ['ns'] = { ['op']=1, ['pr']=1, ['po']=1, ['in']=1, ['I']=1 },
  ['ex'] = { ['op']=1, ['pr']=1, ['po']=1, ['in']=1, ['I']=1 },
  ['sy'] = { ['op']=1, ['pr']=1, ['po']=1, ['in']=1, ['I']=1 },
  ['is'] = { ['op']=1, ['pr']=1, ['po']=1, ['in']=1, ['I']=1 },
  ['pr'] = {           ['pr']=1, ['po']=1, ['in']=1 },
  ['po'] = { ['op']=1, ['pr']=1, ['po']=1, ['in']=1, ['I']=1 },
  ['in'] = { ['op']=1, ['pr']=1, ['po']=1,           ['I']=1 },
  ['hy'] = { ['op']=1, ['pr']=1, ['po']=1, ['in']=1, ['I']=1 },
  ['qu'] = { },
  --
  ['I']  = { ['op']=1, ['pr']=1, ['I']=1, ['O']=1 },
  ['O']  = {                     ['I']=1 }
}
