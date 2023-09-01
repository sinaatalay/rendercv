if not modules then modules = { } end modules ['util-str'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

utilities         = utilities or { }
utilities.strings = utilities.strings or { }
local strings     = utilities.strings

local format, gsub, rep, sub, find, char = string.format, string.gsub, string.rep, string.sub, string.find, string.char
local load, dump = load, string.dump
local tonumber, type, tostring, next, setmetatable = tonumber, type, tostring, next, setmetatable
local unpack, concat = table.unpack, table.concat
local P, V, C, S, R, Ct, Cs, Cp, Carg, Cc = lpeg.P, lpeg.V, lpeg.C, lpeg.S, lpeg.R, lpeg.Ct, lpeg.Cs, lpeg.Cp, lpeg.Carg, lpeg.Cc
local patterns, lpegmatch = lpeg.patterns, lpeg.match
local tsplitat = lpeg.tsplitat
local utfchar, utfbyte, utflen = utf.char, utf.byte, utf.len

----- loadstripped = utilities.lua.loadstripped
----- setmetatableindex = table.setmetatableindex

local loadstripped = function(str,shortcuts)
    if shortcuts then
        return load(dump(load(str),true),nil,nil,shortcuts)
    else
        return load(dump(load(str),true))
    end
end

-- todo: make a special namespace for the formatter

if not number then number = { } end -- temp hack for luatex-fonts

local stripzero   = patterns.stripzero
local stripzeros  = patterns.stripzeros
local newline     = patterns.newline
local endofstring = patterns.endofstring
local anything    = patterns.anything
local whitespace  = patterns.whitespace
local space       = patterns.space
local spacer      = patterns.spacer
local spaceortab  = patterns.spaceortab
local digit       = patterns.digit
local sign        = patterns.sign
local period      = patterns.period

-- local function points(n)
--     n = tonumber(n)
--     return (not n or n == 0) and "0pt" or lpegmatch(stripzeros,format("%.5fpt",n/65536))
-- end

-- local function basepoints(n)
--     n = tonumber(n)
--     return (not n or n == 0) and "0bp" or lpegmatch(stripzeros,format("%.5fbp", n*(7200/7227)/65536))
-- end

local ptf = 1 / 65536
local bpf = (7200/7227) / 65536

local function points(n)
    if n == 0 then
        return "0pt"
    end
    n = tonumber(n)
    if not n or n == 0 then
        return "0pt"
    end
    n = n * ptf
    if n % 1 == 0 then
        return format("%ipt",n)
    else
        return lpegmatch(stripzeros,format("%.5fpt",n)) -- plural as we need to keep the pt
    end
end

local function nupoints(n)
    if n == 0 then
        return "0"
    end
    n = tonumber(n)
    if not n or n == 0 then
        return "0"
    end
    n = n * ptf
    if n % 1 == 0 then
        return format("%i",n)
    else
        return format("%.5f",n) -- no strip
    end
end

local function basepoints(n)
    if n == 0 then
        return "0bp"
    end
    n = tonumber(n)
    if not n or n == 0 then
        return "0bp"
    end
    n = n * bpf
    if n % 1 == 0 then
        return format("%ibp",n)
    else
        return lpegmatch(stripzeros,format("%.5fbp",n)) -- plural as we need to keep the pt
    end
end

local function nubasepoints(n)
    if n == 0 then
        return "0"
    end
    n = tonumber(n)
    if not n or n == 0 then
        return "0"
    end
    n = n * bpf
    if n % 1 == 0 then
        return format("%i",n)
    else
        return format("%.5f",n) -- no strip
    end
end

number.points       = points
number.nupoints     = nupoints
number.basepoints   = basepoints
number.nubasepoints = nubasepoints

-- str = " \n \ntest  \n test\ntest "
-- print("["..string.gsub(string.collapsecrlf(str),"\n","+").."]")

local rubish     = spaceortab^0 * newline
local anyrubish  = spaceortab + newline
local stripped   = (spaceortab^1 / "") * newline
local leading    = rubish^0 / ""
local trailing   = (anyrubish^1 * endofstring) / ""
local redundant  = rubish^3 / "\n"

local pattern = Cs(leading * (trailing + redundant + stripped + anything)^0)

function strings.collapsecrlf(str)
    return lpegmatch(pattern,str)
end

-- The following functions might end up in another namespace.

local repeaters = { } -- watch how we also moved the -1 in depth-1 to the creator

function strings.newrepeater(str,offset)
    offset = offset or 0
    local s = repeaters[str]
    if not s then
        s = { }
        repeaters[str] = s
    end
    local t = s[offset]
    if t then
        return t
    end
    t = { }
    setmetatable(t, { __index = function(t,k)
        if not k then
            return ""
        end
        local n = k + offset
        local s = n > 0 and rep(str,n) or ""
        t[k] = s
        return s
    end })
    s[offset] = t
    return t
end

-- local dashes = strings.newrepeater("--",-1)
-- print(dashes[2],dashes[3],dashes[1])

local extra, tab, start = 0, 0, 4, 0

local nspaces = strings.newrepeater(" ")

string.nspaces = nspaces

local pattern =
    Carg(1) / function(t)
        extra, tab, start = 0, t or 7, 1
    end
  * Cs((
      Cp() * patterns.tab / function(position)
          local current = (position - start + 1) + extra
          local spaces = tab-(current-1) % tab
          if spaces > 0 then
              extra = extra + spaces - 1
              return nspaces[spaces] -- rep(" ",spaces)
          else
              return ""
          end
      end
    + newline * Cp() / function(position)
          extra, start = 0, position
      end
    + anything
  )^1)

function strings.tabtospace(str,tab)
    -- no real gain in first checking if a \t is there
    return lpegmatch(pattern,str,1,tab or 7)
end

function string.utfpadding(s,n)
    if not n or n == 0 then
        return ""
    end
    local l = utflen(s)
    if n > 0 then
        return nspaces[n-l]
    else
        return nspaces[-n-l]
    end
end

-- local t = {
--     "1234567123456712345671234567",
--     "\tb\tc",
--     "a\tb\tc",
--     "aa\tbb\tcc",
--     "aaa\tbbb\tccc",
--     "aaaa\tbbbb\tcccc",
--     "aaaaa\tbbbbb\tccccc",
--     "aaaaaa\tbbbbbb\tcccccc\n       aaaaaa\tbbbbbb\tcccccc",
--     "one\n	two\nxxx	three\nxx	four\nx	five\nsix",
-- }
-- for k=1,#t do
--     print(strings.tabtospace(t[k]))
-- end

-- todo: lpeg

-- function strings.striplong(str) -- strips all leading spaces
--     str = gsub(str,"^%s*","")
--     str = gsub(str,"[\n\r]+ *","\n")
--     return str
-- end

local optionalspace = spacer^0
local nospace       = optionalspace/""
local endofline     = nospace * newline

local stripend      = (whitespace^1 * endofstring)/""

local normalline    = (nospace * ((1-optionalspace*(newline+endofstring))^1) * nospace)

local stripempty    = endofline^1/""
local normalempty   = endofline^1
local singleempty   = endofline * (endofline^0/"")
local doubleempty   = endofline * endofline^-1 * (endofline^0/"")
local stripstart    = stripempty^0

local intospace     = whitespace^1/" "
local noleading     = whitespace^1/""
local notrailing    = noleading * endofstring

local p_prune_normal    = Cs ( stripstart * ( stripend   + normalline + normalempty )^0 )
local p_prune_collapse  = Cs ( stripstart * ( stripend   + normalline + doubleempty )^0 )
local p_prune_noempty   = Cs ( stripstart * ( stripend   + normalline + singleempty )^0 )
local p_prune_intospace = Cs ( noleading  * ( notrailing + intospace  + 1           )^0 )
local p_retain_normal   = Cs (              (              normalline + normalempty )^0 )
local p_retain_collapse = Cs (              (              normalline + doubleempty )^0 )
local p_retain_noempty  = Cs (              (              normalline + singleempty )^0 )
local p_collapse_all    = Cs ( stripstart * ( stripend   + ((whitespace+newline)^1/" ") + 1)^0 )

-- function striplines(str,prune,collapse,noempty)
--     if prune then
--         if noempty then
--             return lpegmatch(p_prune_noempty,str) or str
--         elseif collapse then
--             return lpegmatch(p_prune_collapse,str) or str
--         else
--             return lpegmatch(p_prune_normal,str) or str
--         end
--     else
--         if noempty then
--             return lpegmatch(p_retain_noempty,str) or str
--         elseif collapse then
--             return lpegmatch(p_retain_collapse,str) or str
--         else
--             return lpegmatch(p_retain_normal,str) or str
--         end
--     end
-- end

local striplinepatterns = {
    ["prune"]               = p_prune_normal,
    ["prune and collapse"]  = p_prune_collapse, -- default
    ["prune and no empty"]  = p_prune_noempty,
    ["prune and to space"]  = p_prune_intospace,
    ["retain"]              = p_retain_normal,
    ["retain and collapse"] = p_retain_collapse,
    ["retain and no empty"] = p_retain_noempty,
    ["collapse all"]        = p_collapse_all,
    ["collapse"]            = patterns.collapser,
}

setmetatable(striplinepatterns,{ __index = function(t,k) return p_prune_collapse end })

strings.striplinepatterns = striplinepatterns

function strings.striplines(str,how)
    return str and lpegmatch(striplinepatterns[how],str) or str
end

function strings.collapse(str) -- maybe also in strings
    return str and lpegmatch(p_prune_intospace,str) or str
end

-- local s = "\naa\n\naa\na   a\n\n"
-- print("["..strings.striplines(s,"collapse all").."]")

-- also see: string.collapsespaces

strings.striplong = strings.striplines -- for old times sake

-- local str = table.concat( {
-- "  ",
-- "    aap",
-- "  noot mies",
-- "  ",
-- "    ",
-- " zus    wim jet",
-- "zus    wim jet",
-- "       zus    wim jet",
-- "    ",
-- }, "\n")
--
-- local str = table.concat( {
-- "  aaaa",
-- "  bb",
-- "  cccccc",
-- " ",
-- }, "\n")
--
-- for k, v in table.sortedhash(utilities.strings.striplinepatterns) do
--     logs.report("stripper","method: %s, result: [[%s]]",k,utilities.strings.striplines(str,k))
-- end

-- inspect(strings.striplong([[
--   aaaa
--   bb
--   cccccc
-- ]]))

function strings.nice(str)
    str = gsub(str,"[:%-+_]+"," ") -- maybe more
    return str
end

-- Work in progress. Interesting is that compared to the built-in this is faster in
-- luatex than in luajittex where we have a comparable speed. It only makes sense
-- to use the formatter when a (somewhat) complex format is used a lot. Each formatter
-- is a function so there is some overhead and not all formatted output is worth that
-- overhead. Keep in mind that there is an extra function call involved. In principle
-- we end up with a string concatination so one could inline such a sequence but often
-- at the cost of less readabinity. So, it's a sort of (visual) compromise. Of course
-- there is the benefit of more variants. (Concerning the speed: a simple format like
-- %05fpt is better off with format than with a formatter, but as soon as you put
-- something in front formatters become faster. Passing the pt as extra argument makes
-- formatters behave better. Of course this is rather implementation dependent. Also,
-- when a specific format is only used a few times the overhead in creating it is not
-- compensated by speed.)
--
-- More info can be found in cld-mkiv.pdf so here I stick to a simple list.
--
-- integer            %...i   number
-- integer            %...d   number
-- unsigned           %...u   number -- not used
-- character          %...c   number
-- hexadecimal        %...x   number
-- HEXADECIMAL        %...X   number
-- octal              %...o   number
-- string             %...s   string number
-- float              %...f   number
-- checked float      %...F   number
-- exponential        %...e   number
-- exponential        %...E   number
-- stripped e         %...j   number
-- stripped E         %...J   number
-- autofloat          %...g   number
-- autofloat          %...G   number
-- utf character      %...c   number
-- force tostring     %...S   any
-- force tostring     %Q      any
-- force tonumber     %N      number (strip leading zeros)
-- signed number      %I      number
-- rounded number     %r      number
-- 0xhexadecimal      %...h   character number
-- 0xHEXADECIMAL      %...H   character number
-- U+hexadecimal      %...u   character number
-- U+HEXADECIMAL      %...U   character number
-- points             %p      number (scaled points)
-- nupoints           %P      number (scaled points) / without unit / always 5 decimals
-- basepoints         %b      number (scaled points)
-- nubasepoints       %B      number (scaled points) / without unit / always 5 decimals
-- table concat       %...t   table
-- table concat       %{.}t   table
-- serialize          %...T   sequenced (no nested tables)
-- serialize          %{.}T   sequenced (no nested tables)
-- boolean (logic)    %l      boolean
-- BOOLEAN            %L      boolean
-- whitespace         %...w   number
-- whitespace         %...W   (fixed)
-- automatic          %...a   'whatever' (string, table, ...)
-- automatic          %...A   "whatever" (string, table, ...)
-- zap                %...z   skip
-- stripped  %...N    %...N
-- comma/period real  %...m
-- period/comma real  %...M
-- formatted float    %...k   n.m

local n = 0

-- we are somewhat sloppy in parsing prefixes as it's not that critical

-- hard to avoid but we can collect them in a private namespace if needed

-- inline the next two makes no sense as we only use this in logging

local sequenced = table.sequenced

function string.autodouble(s,sep)
    if s == nil then
        return '""'
    end
    local t = type(s)
    if t == "number" then
        return tostring(s) -- tostring not really needed
    end
    if t == "table" then
        return ('"' .. sequenced(s,sep or ",") .. '"')
    end
    return ('"' .. tostring(s) .. '"')
end

function string.autosingle(s,sep)
    if s == nil then
        return "''"
    end
    local t = type(s)
    if t == "number" then
        return tostring(s) -- tostring not really needed
    end
    if t == "table" then
        return ("'" .. sequenced(s,sep or ",") .. "'")
    end
    return ("'" .. tostring(s) .. "'")
end

local tracedchars  = { [0] =
    -- the regular bunch
    "[null]", "[soh]", "[stx]", "[etx]", "[eot]", "[enq]", "[ack]", "[bel]",
    "[bs]",   "[ht]",  "[lf]",  "[vt]",  "[ff]",  "[cr]",  "[so]",  "[si]",
    "[dle]",  "[dc1]", "[dc2]", "[dc3]", "[dc4]", "[nak]", "[syn]", "[etb]",
    "[can]",  "[em]",  "[sub]", "[esc]", "[fs]",  "[gs]",  "[rs]",  "[us]",
    -- plus space
    "[space]", -- 0x20
}

string.tracedchars = tracedchars
strings.tracers    = tracedchars

function string.tracedchar(b)
    -- todo: table
    if type(b) == "number" then
        return tracedchars[b] or (utfchar(b) .. " (U+" .. format("%05X",b) .. ")")
    else
        local c = utfbyte(b)
        return tracedchars[c] or (b .. " (U+" .. (c and format("%05X",c) or "?????") .. ")")
    end
end

function number.signed(i)
    if i > 0 then
        return "+",  i
    else
        return "-", -i
    end
end

-- maybe to util-num

local two    = digit * digit
local three  = two * digit
local prefix = (Carg(1) * three)^1

local splitter = Cs (
    (((1 - (three^1 * period))^1 + C(three)) * prefix + C((1-period)^1))
  * (anything/"" * Carg(2)) * C(2)
)

local splitter3 = Cs (
    three * prefix * endofstring +
    two   * prefix * endofstring +
    digit * prefix * endofstring +
    three +
    two   +
    digit
)

patterns.formattednumber = splitter

function number.formatted(n,sep1,sep2)
    if sep1 == false then
        if type(n) == "number" then
            n = tostring(n)
        end
        return lpegmatch(splitter3,n,1,sep2 or ".")
    else
        if type(n) == "number" then
            n = format("%0.2f",n)
        end
        if sep1 == true then
            return lpegmatch(splitter,n,1,".",",")
        elseif sep1 == "." then
            return lpegmatch(splitter,n,1,sep1,sep2 or ",")
        elseif sep1 == "," then
            return lpegmatch(splitter,n,1,sep1,sep2 or ".")
        else
            return lpegmatch(splitter,n,1,sep1 or ",",sep2 or ".")
        end
    end
end

-- print(number.formatted(1))
-- print(number.formatted(12))
-- print(number.formatted(123))
-- print(number.formatted(1234))
-- print(number.formatted(12345))
-- print(number.formatted(123456))
-- print(number.formatted(1234567))
-- print(number.formatted(12345678))
-- print(number.formatted(12345678,true))
-- print(number.formatted(1,false))
-- print(number.formatted(12,false))
-- print(number.formatted(123,false))
-- print(number.formatted(1234,false))
-- print(number.formatted(12345,false))
-- print(number.formatted(123456,false))
-- print(number.formatted(1234567,false))
-- print(number.formatted(12345678,false))
-- print(number.formatted(1234.56,"!","?"))

local p = Cs(
        P("-")^0
      * (P("0")^1/"")^0
      * (1-period)^0
      * (period * P("0")^1 * endofstring/"" + period^0)
      * P(1-P("0")^1*endofstring)^0
    )

function number.compactfloat(n,fmt)
    if n == 0 then
        return "0"
    elseif n == 1 then
        return "1"
    end
    n = lpegmatch(p,format(fmt or "%0.3f",n))
    if n == "." or n == "" or n == "-" then
        return "0"
    end
    return n
end

local zero      = P("0")^1 / ""
local plus      = P("+")   / ""
local minus     = P("-")
local separator = period
local trailing  = zero^1 * #S("eE")
local exponent  = (S("eE") * (plus + Cs((minus * zero^0 * endofstring)/"") + minus) * zero^0 * (endofstring * Cc("0") + anything^1))
local pattern_a = Cs(minus^0 * digit^1 * (separator/"" * trailing + separator * (trailing + digit)^0) * exponent)
local pattern_b = Cs((exponent + anything)^0)

function number.sparseexponent(f,n)
    if not n then
        n = f
        f = "%e"
    end
    local tn = type(n)
    if tn == "string" then -- cast to number
        local m = tonumber(n)
        if m then
            return lpegmatch((f == "%e" or f == "%E") and pattern_a or pattern_b,format(f,m))
        end
    elseif tn == "number" then
        return lpegmatch((f == "%e" or f == "%E") and pattern_a or pattern_b,format(f,n))
    end
    return tostring(n)
end

local hf = { }
local hs = { }

setmetatable(hf, { __index = function(t,k)
    local v = "%." .. k .. "f"
    t[k] = v
    return v
end } )

setmetatable(hs, { __index = function(t,k)
    local v = "%" .. k .. "s"
    t[k] = v
    return v
end } )

function number.formattedfloat(n,b,a)
    local s = format(hf[a],n)
    local l = (b or 0) + (a or 0) + 1
    if #s < l then
        return format(hs[l],s)
    else
        return s
    end
end

local template = [[
%s
%s
return function(%s) return %s end
]]

-- We only use fast serialize in controlled cases.

local pattern = Cs(Cc('"') * (
    (1-S('"\\\n\r'))^1
  + P('"')  / '\\"'
  + P('\\') / '\\\\'
  + P('\n') / '\\n'
  + P('\r') / '\\r'
)^0 * Cc('"'))

-- -- I need to do more experiments with this:
--
-- local pattern = Cs(Cc('"') * (
--     (1-S('"\\\n\r'))^1
--   + P('"')  / '\\034'
--   + P('\\') / '\\092'
--   + P('\n') / '\\013'
--   + P('\r') / '\\010'
-- )^0 * Cc('"'))

patterns.escapedquotes = pattern

function string.escapedquotes(s)
    return lpegmatch(pattern,s)
end

local pattern = (1 - P("\\"))^1 ; pattern = Cs (
    pattern
 * ( (P("\\") / "" * (digit^-3 / function(s) return char(tonumber(s)) end)) + pattern )^1
)

patterns.unescapedquotes = pattern

function string.unescapedquotes(s)
    return lpegmatch(pattern,s) or s
end

-- function string.longifneeded(s)
--     if find(s,'["\\\n\r]') then
--         return "[===[" .. s .. "]===]"
--     else
--         return '"' .. s ..'"'
--     end
-- end

string.texnewlines = lpeg.replacer(patterns.newline,"\r",true)

-- print(string.escapedquotes('1\\23\n"'))

-- but for now here

local preamble = ""

local environment = {
    global          = global or _G,
    lpeg            = lpeg,
    type            = type,
    tostring        = tostring,
    tonumber        = tonumber,
    format          = string.format,
    concat          = table.concat,
    signed          = number.signed,
    points          = number.points,
    nupoints        = number.nupoints,
    basepoints      = number.basepoints,
    nubasepoints    = number.nubasepoints,
    utfchar         = utf.char,
    utfbyte         = utf.byte,
    lpegmatch       = lpeg.match,
    nspaces         = string.nspaces,
    utfpadding      = string.utfpadding,
    tracedchar      = string.tracedchar,
    autosingle      = string.autosingle,
    autodouble      = string.autodouble,
    sequenced       = table.sequenced,
    formattednumber = number.formatted,
    sparseexponent  = number.sparseexponent,
    formattedfloat  = number.formattedfloat,
    stripzero       = patterns.stripzero,
    stripzeros      = patterns.stripzeros,
    escapedquotes   = string.escapedquotes,

    FORMAT          = string.f6,
}

-- -- --

local arguments = { "a1" } -- faster than previously used (select(n,...))

setmetatable(arguments, { __index =
    function(t,k)
        local v = t[k-1] .. ",a" .. k
        t[k] = v
        return v
    end
})

local prefix_any = C((sign + space + period + digit)^0)
local prefix_sub = (C((sign + digit)^0) + Cc(0))
                 * period
                 * (C((sign + digit)^0) + Cc(0))
local prefix_tab = P("{") * C((1-P("}"))^0) * P("}") + C((1-R("az","AZ","09","%%"))^0)

-- we've split all cases as then we can optimize them (let's omit the fuzzy u)

-- todo: replace outer formats in next by ..

local format_s = function(f)
    n = n + 1
    if f and f ~= "" then
        return format("format('%%%ss',a%s)",f,n)
    else -- best no tostring in order to stay compatible (.. does a selective tostring too)
        return format("(a%s or '')",n) -- goodie: nil check
    end
end

local format_S = function(f) -- can be optimized
    n = n + 1
    if f and f ~= "" then
        return format("format('%%%ss',tostring(a%s))",f,n)
    else
        return format("tostring(a%s)",n)
    end
end

local format_right = function(f)
    n = n + 1
    f = tonumber(f)
    if not f or f == 0 then
        return format("(a%s or '')",n)
    elseif f > 0 then
        return format("utfpadding(a%s,%i)..a%s",n,f,n)
    else
        return format("a%s..utfpadding(a%s,%i)",n,n,f)
    end
end

local format_left = function(f)
    n = n + 1
    f = tonumber(f)
    if not f or f == 0 then
        return format("(a%s or '')",n)
    end
    if f < 0 then
        return format("utfpadding(a%s,%i)..a%s",n,-f,n)
    else
        return format("a%s..utfpadding(a%s,%i)",n,n,-f)
    end
end

local format_q = JITSUPPORTED and function()
    n = n + 1
    -- lua 5.3 has a different q than lua 5.2 (which does a tostring on numbers)
 -- return format("(a%s ~= nil and format('%%q',a%s) or '')",n,n)
    return format("(a%s ~= nil and format('%%q',tostring(a%s)) or '')",n,n)
 -- return format("(a%s ~= nil and escapedquotes(tostring(a%s)) or '')",n,n)
end or function()
    n = n + 1
    return format("(a%s ~= nil and format('%%q',a%s) or '')",n,n)
end


local format_Q = function() -- fast escaping
    n = n + 1
--  return format("format('%%q',tostring(a%s))",n)
    return format("escapedquotes(tostring(a%s))",n)
end

local format_i = function(f)
    n = n + 1
    if f and f ~= "" then
        return format("format('%%%si',a%s)",f,n)
    else
        return format("format('%%i',a%s)",n) -- why not just tostring()
    end
end

local format_d = format_i

local format_I = function(f)
    n = n + 1
    return format("format('%%s%%%si',signed(a%s))",f,n)
end

local format_f = function(f)
    n = n + 1
    return format("format('%%%sf',a%s)",f,n)
end

-- The next one formats an integer as integer and very small values as zero. This is needed
-- for pdf backend code.
--
--   1.23 % 1 : 0.23
-- - 1.23 % 1 : 0.77
--
-- We could probably use just %s with integers but who knows what Lua 5.3 will do? So let's
-- for the moment use %i.

local format_F = function(f) -- beware, no cast to number
    n = n + 1
    if not f or f == "" then
        return format("(((a%s > -0.0000000005 and a%s < 0.0000000005) and '0') or format((a%s %% 1 == 0) and '%%i' or '%%.9f',a%s))",n,n,n,n)
    else
        return format("format((a%s %% 1 == 0) and '%%i' or '%%%sf',a%s)",n,f,n)
    end
end

-- if string.f9 then
--     format_F = function(f) -- beware, no cast to number
--         n = n + 1
--         if not f or f == "" then
--             return format("(((a%s > -0.0000000005 and a%s < 0.0000000005) and '0') or FORMAT(a%s))",n,n,n,n,n)
--         else
--             return format("((a%s %% 1 == 0) and format('%%i',a%s) or FORMAT(a%s,'%%%sf'))",n,n,n,f)
--         end
--     end
-- end

local format_k = function(b,a) -- slow
    n = n + 1
    return format("formattedfloat(a%s,%s,%s)",n,b or 0,a or 0)
end

local format_g = function(f)
    n = n + 1
    return format("format('%%%sg',a%s)",f,n)
end

local format_G = function(f)
    n = n + 1
    return format("format('%%%sG',a%s)",f,n)
end

local format_e = function(f)
    n = n + 1
    return format("format('%%%se',a%s)",f,n)
end

local format_E = function(f)
    n = n + 1
    return format("format('%%%sE',a%s)",f,n)
end

local format_j = function(f)
    n = n + 1
    return format("sparseexponent('%%%se',a%s)",f,n)
end

local format_J = function(f)
    n = n + 1
    return format("sparseexponent('%%%sE',a%s)",f,n)
end

local format_x = function(f)
    n = n + 1
    return format("format('%%%sx',a%s)",f,n)
end

local format_X = function(f)
    n = n + 1
    return format("format('%%%sX',a%s)",f,n)
end

local format_o = function(f)
    n = n + 1
    return format("format('%%%so',a%s)",f,n)
end

local format_c = function()
    n = n + 1
    return format("utfchar(a%s)",n)
end

local format_C = function()
    n = n + 1
    return format("tracedchar(a%s)",n)
end

local format_r = function(f)
    n = n + 1
    return format("format('%%%s.0f',a%s)",f,n)
end

local format_h = function(f)
    n = n + 1
    if f == "-" then
        f = sub(f,2)
        return format("format('%%%sx',type(a%s) == 'number' and a%s or utfbyte(a%s))",f == "" and "05" or f,n,n,n)
    else
        return format("format('0x%%%sx',type(a%s) == 'number' and a%s or utfbyte(a%s))",f == "" and "05" or f,n,n,n)
    end
end

local format_H = function(f)
    n = n + 1
    if f == "-" then
        f = sub(f,2)
        return format("format('%%%sX',type(a%s) == 'number' and a%s or utfbyte(a%s))",f == "" and "05" or f,n,n,n)
    else
        return format("format('0x%%%sX',type(a%s) == 'number' and a%s or utfbyte(a%s))",f == "" and "05" or f,n,n,n)
    end
end

local format_u = function(f)
    n = n + 1
    if f == "-" then
        f = sub(f,2)
        return format("format('%%%sx',type(a%s) == 'number' and a%s or utfbyte(a%s))",f == "" and "05" or f,n,n,n)
    else
        return format("format('u+%%%sx',type(a%s) == 'number' and a%s or utfbyte(a%s))",f == "" and "05" or f,n,n,n)
    end
end

local format_U = function(f)
    n = n + 1
    if f == "-" then
        f = sub(f,2)
        return format("format('%%%sX',type(a%s) == 'number' and a%s or utfbyte(a%s))",f == "" and "05" or f,n,n,n)
    else
        return format("format('U+%%%sX',type(a%s) == 'number' and a%s or utfbyte(a%s))",f == "" and "05" or f,n,n,n)
    end
end

local format_p = function()
    n = n + 1
    return format("points(a%s)",n)
end

local format_P = function()
    n = n + 1
    return format("nupoints(a%s)",n)
end

local format_b = function()
    n = n + 1
    return format("basepoints(a%s)",n)
end

local format_B = function()
    n = n + 1
    return format("nubasepoints(a%s)",n)
end

local format_t = function(f)
    n = n + 1
    if f and f ~= "" then
        return format("concat(a%s,%q)",n,f)
    else
        return format("concat(a%s)",n)
    end
end

local format_T = function(f)
    n = n + 1
    if f and f ~= "" then
        return format("sequenced(a%s,%q)",n,f)
    else
        return format("sequenced(a%s)",n)
    end
end

local format_l = function()
    n = n + 1
    return format("(a%s and 'true' or 'false')",n)
end

local format_L = function()
    n = n + 1
    return format("(a%s and 'TRUE' or 'FALSE')",n)
end

local format_n = function() -- strips leading and trailing zeros and removes .0, beware: can produce e notation
    n = n + 1
    return format("((a%s %% 1 == 0) and format('%%i',a%s) or tostring(a%s))",n,n,n)
end

-- local format_N = function() -- strips leading and trailing zeros (also accepts string)
--     n = n + 1
--     return format("tostring(tonumber(a%s) or a%s)",n,n)
-- end

-- local format_N = function(f) -- strips leading and trailing zeros
--     n = n + 1
--     -- stripzero (singular) as we only have a number
--     if not f or f == "" then
--         return format("(((a%s > -0.0000000005 and a%s < 0.0000000005) and '0') or ((a%s %% 1 == 0) and format('%%i',a%s)) or lpegmatch(stripzero,format('%%.9f',a%s)))",n,n,n,n,n)
--     else
--         return format("(((a%s %% 1 == 0) and format('%%i',a%s)) or lpegmatch(stripzero,format('%%%sf',a%s)))",n,n,f,n)
--     end
-- end

-- local format_N = function(f) -- strips leading and trailing zeros
--     n = n + 1
--     -- stripzero (singular) as we only have a number
--     if not f or f == "" then
--         return format("(((a%s %% 1 == 0) and format('%%i',a%s)) or ((a%s > -0.0000000005 and a%s < 0.0000000005) and '0') or lpegmatch(stripzero,format('%%.9f',a%s)))",n,n,n,n,n)
--     else
--         return format("(((a%s %% 1 == 0) and format('%%i',a%s)) or lpegmatch(stripzero,format('%%%sf',a%s)))",n,n,f,n)
--     end
-- end

local format_N  if environment.FORMAT then

    format_N = function(f)
        n = n + 1
        if not f or f == "" then
            return format("FORMAT(a%s,'%%.9f')",n)
        elseif f == ".6" or f == "0.6" then
            return format("FORMAT(a%s)",n)
        else
            return format("FORMAT(a%s,'%%%sf')",n,f)
        end
    end

else

    format_N = function(f) -- strips leading and trailing zeros
        n = n + 1
        -- stripzero (singular) as we only have a number
        if not f or f == "" then
            f = ".9"
        end -- always a leading number !
        return format("(((a%s %% 1 == 0) and format('%%i',a%s)) or lpegmatch(stripzero,format('%%%sf',a%s)))",n,n,f,n)
    end

end

local format_a = function(f)
    n = n + 1
    if f and f ~= "" then
        return format("autosingle(a%s,%q)",n,f)
    else
        return format("autosingle(a%s)",n)
    end
end

local format_A = function(f)
    n = n + 1
    if f and f ~= "" then
        return format("autodouble(a%s,%q)",n,f)
    else
        return format("autodouble(a%s)",n)
    end
end

local format_w = function(f) -- handy when doing depth related indent
    n = n + 1
    f = tonumber(f)
    if f then -- not that useful
        return format("nspaces[%s+a%s]",f,n) -- no real need for tonumber
    else
        return format("nspaces[a%s]",n) -- no real need for tonumber
    end
end

local format_W = function(f) -- handy when doing depth related indent
    return format("nspaces[%s]",tonumber(f) or 0)
end

local format_m = function(f)
    n = n + 1
    if not f or f == "" then
        f = ","
    end
    if f == "0" then
        return format([[formattednumber(a%s,false)]],n)
    else
        return format([[formattednumber(a%s,%q,".")]],n,f)
    end
end

local format_M = function(f)
    n = n + 1
    if not f or f == "" then
        f = "."
    end
    if f == "0" then
        return format([[formattednumber(a%s,false)]],n)
    else
        return format([[formattednumber(a%s,%q,",")]],n,f)
    end
end

--

local format_z = function(f)
    n = n + (tonumber(f) or 1)
    return "''" -- okay, not that efficient to append '' but a special case anyway
end

--

-- local strip
--
-- local format_Z = function(f)
--     n = n + 1
--     if not f or f == "" then
--         f = ".9"
--     end
--     return format("(((a%s %% 1 == 0) and format('%%i',a%s)) or (strip and lpegmatch(stripzero,format('%%%sf',a%s))) or format('%%%sf',a%s))",n,n,f,n,f,n)
-- end
--
-- function strings.stripformatterzeros()
--     strip = true
-- end

-- add(formatters,"texexp", [[texexp(...)]], "local texexp = metapost.texexp")
--
-- add(formatters,"foo:bar",[[foo(...)]], { foo = function(...) print(...) return "!" end })
-- print(string.formatters["foo %3!foo:bar! bar"](1,2,3))


local format_rest = function(s)
    return format("%q",s) -- catches " and \n and such
end

local format_extension = function(extensions,f,name)
    local extension = extensions[name] or "tostring(%s)"
    local f = tonumber(f) or 1
    local w = find(extension,"%.%.%.")
    if f == 0 then
        if w then
            extension = gsub(extension,"%.%.%.","")
        end
        return extension
    elseif f == 1 then
        if w then
            extension = gsub(extension,"%.%.%.","%%s")
        end
        n = n + 1
        local a = "a" .. n
        return format(extension,a,a) -- maybe more times?
    elseif f < 0 then
        if w then
            -- not supported
            extension = gsub(extension,"%.%.%.","")
            return extension
        else
            local a = "a" .. (n + f + 1)
            return format(extension,a,a)
        end
    else
        if w then
            extension = gsub(extension,"%.%.%.",rep("%%s,",f-1).."%%s")
        end
        -- we could fill an array and then n = n + 1 unpack(t,n,n+f) but as we
        -- cache we don't save much and there are hardly any extensions anyway
        local t = { }
        for i=1,f do
            n = n + 1
         -- t[#t+1] = "a" .. n
            t[i] = "a" .. n
        end
        return format(extension,unpack(t))
    end
end

-- aA b cC d eE f gG hH iI jJ lL mM N o p qQ r sS tT uU wW xX z

-- extensions : %!tag!

-- can be made faster but not called that often

local builder = Cs { "start",
    start = (
        (
            P("%") / ""
          * (
                V("!") -- new
              + V("s") + V("q")
              + V("i") + V("d")
              + V("f") + V("F") + V("g") + V("G") + V("e") + V("E")
              + V("x") + V("X") + V("o")
              --
              + V("c")
              + V("C")
              + V("S") -- new
              + V("Q") -- new
              + V("n") -- new
              + V("N") -- new
              + V("k") -- new
              --
              + V("r")
              + V("h") + V("H") + V("u") + V("U")
              + V("p") + V("P") + V("b") + V("B")
              + V("t") + V("T")
              + V("l") + V("L")
              + V("I")
              + V("w") -- new
              + V("W") -- new
              + V("a") -- new
              + V("A") -- new
              + V("j") + V("J") -- stripped e E
              + V("m") + V("M") -- new (formatted number)
              + V("z") -- new
              --
              + V(">") -- left padding
              + V("<") -- right padding
              --
           -- + V("?") -- ignored, probably messed up %
            )
          + V("*")
        )
     * (endofstring + Carg(1))
    )^0,
    --
    ["s"] = (prefix_any * P("s")) / format_s, -- %s => regular %s (string)
    ["q"] = (prefix_any * P("q")) / format_q, -- %q => regular %q (quoted string)
    ["i"] = (prefix_any * P("i")) / format_i, -- %i => regular %i (integer)
    ["d"] = (prefix_any * P("d")) / format_d, -- %d => regular %d (integer)
    ["f"] = (prefix_any * P("f")) / format_f, -- %f => regular %f (float)
    ["F"] = (prefix_any * P("F")) / format_F, -- %F => regular %f (float) but 0/1 check
    ["g"] = (prefix_any * P("g")) / format_g, -- %g => regular %g (float)
    ["G"] = (prefix_any * P("G")) / format_G, -- %G => regular %G (float)
    ["e"] = (prefix_any * P("e")) / format_e, -- %e => regular %e (float)
    ["E"] = (prefix_any * P("E")) / format_E, -- %E => regular %E (float)
    ["x"] = (prefix_any * P("x")) / format_x, -- %x => regular %x (hexadecimal)
    ["X"] = (prefix_any * P("X")) / format_X, -- %X => regular %X (HEXADECIMAL)
    ["o"] = (prefix_any * P("o")) / format_o, -- %o => regular %o (octal)
    --
    ["S"] = (prefix_any * P("S")) / format_S, -- %S => %s (tostring)
    ["Q"] = (prefix_any * P("Q")) / format_Q, -- %Q => %q (tostring)
    ["n"] = (prefix_any * P("n")) / format_n, -- %n => tonumber (strips leading and trailing zeros, as well as .0, expects number)
    ["N"] = (prefix_any * P("N")) / format_N, -- %N => tonumber (strips leading and trailing zeros, also takes string)
    ["k"] = (prefix_sub * P("k")) / format_k, -- %k => like f but with n.m
    ["c"] = (prefix_any * P("c")) / format_c, -- %c => utf character (extension to regular)
    ["C"] = (prefix_any * P("C")) / format_C, -- %c => U+.... utf character
    --
    ["r"] = (prefix_any * P("r")) / format_r, -- %r => round
    ["h"] = (prefix_any * P("h")) / format_h, -- %h => 0x0a1b2 (when - no 0x) was v
    ["H"] = (prefix_any * P("H")) / format_H, -- %H => 0x0A1B2 (when - no 0x) was V
    ["u"] = (prefix_any * P("u")) / format_u, -- %u => u+0a1b2 (when - no u+)
    ["U"] = (prefix_any * P("U")) / format_U, -- %U => U+0A1B2 (when - no U+)
    ["p"] = (prefix_any * P("p")) / format_p, -- %p => 12.345pt
    ["P"] = (prefix_any * P("P")) / format_P, -- %p => 12.345
    ["b"] = (prefix_any * P("b")) / format_b, -- %b => 12.342bp
    ["B"] = (prefix_any * P("B")) / format_B, -- %b => 12.342
    ["t"] = (prefix_tab * P("t")) / format_t, -- %t => concat
    ["T"] = (prefix_tab * P("T")) / format_T, -- %t => sequenced
    ["l"] = (prefix_any * P("l")) / format_l, -- %l => boolean
    ["L"] = (prefix_any * P("L")) / format_L, -- %L => BOOLEAN
    ["I"] = (prefix_any * P("I")) / format_I, -- %I => signed integer
    --
    ["w"] = (prefix_any * P("w")) / format_w, -- %w => n spaces (optional prefix is added)
    ["W"] = (prefix_any * P("W")) / format_W, -- %W => mandate prefix, no specifier
    --
    ["j"] = (prefix_any * P("j")) / format_j, -- %j => %e (float) stripped exponent (irrational)
    ["J"] = (prefix_any * P("J")) / format_J, -- %J => %E (float) stripped exponent (irrational)
    --
    ["m"] = (prefix_any * P("m")) / format_m, -- %m => xxx.xxx.xxx,xx (optional prefix instead of .)
    ["M"] = (prefix_any * P("M")) / format_M, -- %M => xxx,xxx,xxx.xx (optional prefix instead of ,)
    --
    ["z"] = (prefix_any * P("z")) / format_z, -- %z => skip n arguments
 -- ["Z"] = (prefix_any * P("Z")) / format_Z, -- %Z => optionally strip zeros
    --
    ["a"] = (prefix_any * P("a")) / format_a, -- %a => '...' (forces tostring)
    ["A"] = (prefix_any * P("A")) / format_A, -- %A => "..." (forces tostring)
    --
    ["<"] = (prefix_any * P("<")) / format_left,
    [">"] = (prefix_any * P(">")) / format_right,
    --
    ["*"] = Cs(((1-P("%"))^1 + P("%%")/"%%")^1) / format_rest, -- rest (including %%)
    ["?"] = Cs(((1-P("%"))^1               )^1) / format_rest, -- rest (including %%)
    --
    ["!"] = Carg(2) * prefix_any * P("!") * C((1-P("!"))^1) * P("!") / format_extension,
}

-- We can be clever and only alias what is needed:

local xx = setmetatable({ }, { __index = function(t,k) local v = format("%02x",k) t[k] = v return v end })
local XX = setmetatable({ }, { __index = function(t,k) local v = format("%02X",k) t[k] = v return v end })

local preset = {
    ["%02x"] = function(n) return xx[n] end,
    ["%02X"] = function(n) return XX[n] end,
}

local direct =
    P("%") * (sign + space + period + digit)^0 * S("sqidfgGeExXo") * endofstring
  / [[local format = string.format return function(str) return format("%0",str) end]]

local function make(t,str)
    local f = preset[str]
    if f then
        return f
    end
    local p = lpegmatch(direct,str)
    if p then
     -- print("builder 1 >",p)
        f = loadstripped(p)()
    else
        n = 0 -- used in patterns
     -- p = lpegmatch(builder,str,1,"..",t._extensions_) -- after this we know n
        p = lpegmatch(builder,str,1,t._connector_,t._extensions_) -- after this we know n
        if n > 0 then
            p = format(template,preamble,t._preamble_,arguments[n],p)
         -- print("builder 2 >",p)
            f = loadstripped(p,t._environment_)() -- t._environment is not populated (was experiment)
        else
            f = function() return str end
        end
    end
    t[str] = f
    return f
end

-- -- collect periodically
--
-- local threshold = 1000 -- max nof cached formats
--
-- local function make(t,str)
--     local f = rawget(t,str)
--     if f then
--         return f
--     end
--     local parent = t._t_
--     if parent._n_ > threshold then
--         local m = { _t_ = parent }
--         getmetatable(parent).__index = m
--         setmetatable(m, { __index = make })
--     else
--         parent._n_ = parent._n_ + 1
--     end
--     local f
--     local p = lpegmatch(direct,str)
--     if p then
--         f = loadstripped(p)()
--     else
--         n = 0
--         p = lpegmatch(builder,str,1,"..",parent._extensions_) -- after this we know n
--         if n > 0 then
--             p = format(template,preamble,parent._preamble_,arguments[n],p)
--          -- print("builder>",p)
--             f = loadstripped(p)()
--         else
--             f = function() return str end
--         end
--     end
--     t[str] = f
--     return f
-- end

local function use(t,fmt,...)
    return t[fmt](...)
end

strings.formatters = { }

-- we cannot make these tables weak, unless we start using an indirect
-- table (metatable) in which case we could better keep a count and
-- clear that table when a threshold is reached

-- _connector_ is an experiment

function strings.formatters.new(noconcat)
    local e = { } -- better make a copy as we can overload
    for k, v in next, environment do
        e[k] = v
    end
    local t = {
        _type_        = "formatter",
        _connector_   = noconcat and "," or "..",
        _extensions_  = { },
        _preamble_    = "",
        _environment_ = e,
    }
    setmetatable(t, { __index = make, __call = use })
    return t
end

local formatters   = strings.formatters.new() -- the default instance

string.formatters  = formatters -- in the main string namespace
string.formatter   = function(str,...) return formatters[str](...) end -- sometimes nicer name

local function add(t,name,template,preamble)
    if type(t) == "table" and t._type_ == "formatter" then
        t._extensions_[name] = template or "%s"
        if type(preamble) == "string" then
            t._preamble_ = preamble .. "\n" .. t._preamble_ -- so no overload !
        elseif type(preamble) == "table" then
            for k, v in next, preamble do
                t._environment_[k] = v
            end
        end
    end
end

strings.formatters.add = add

-- registered in the default instance (should we fall back on this one?)

patterns.xmlescape = Cs((P("<")/"&lt;" + P(">")/"&gt;" + P("&")/"&amp;" + P('"')/"&quot;" + anything)^0)
patterns.texescape = Cs((C(S("#$%\\{}"))/"\\%1" + anything)^0)
patterns.luaescape = Cs(((1-S('"\n'))^1 + P('"')/'\\"' + P('\n')/'\\n"')^0) -- maybe also \0
patterns.luaquoted = Cs(Cc('"') * ((1-S('"\n'))^1 + P('"')/'\\"' + P('\n')/'\\n"')^0 * Cc('"'))

-- escaping by lpeg is faster for strings without quotes, slower on a string with quotes, but
-- faster again when other q-escapables are found (the ones we don't need to escape)

add(formatters,"xml",[[lpegmatch(xmlescape,%s)]],{ xmlescape = patterns.xmlescape })
add(formatters,"tex",[[lpegmatch(texescape,%s)]],{ texescape = patterns.texescape })
add(formatters,"lua",[[lpegmatch(luaescape,%s)]],{ luaescape = patterns.luaescape })

-- -- yes or no:
--
-- local function make(t,str)
--     local f
--     local p = lpegmatch(direct,str)
--     if p then
--         f = loadstripped(p)()
--     else
--         n = 0
--         p = lpegmatch(builder,str,1,",") -- after this we know n
--         if n > 0 then
--             p = format(template,template_shortcuts,arguments[n],p)
--             f = loadstripped(p)()
--         else
--             f = function() return str end
--         end
--     end
--     t[str] = f
--     return f
-- end
--
-- local formatteds  = string.formatteds or { }
-- string.formatteds = formatteds
--
-- setmetatable(formatteds, { __index = make, __call = use })

-- This is a somewhat silly one used in commandline reconstruction but the older
-- method, using a combination of fine, gsub, quoted and unquoted was not that
-- reliable.
--
-- '"foo"bar \"and " whatever"' => "foo\"bar \"and \" whatever"
-- 'foo"bar \"and " whatever'   => "foo\"bar \"and \" whatever"

local dquote = patterns.dquote -- P('"')
local equote = patterns.escaped + dquote / '\\"' + 1
local cquote = Cc('"')

local pattern =
    Cs(dquote * (equote - P(-2))^0 * dquote)                    -- we keep the outer but escape unescaped ones
  + Cs(cquote * (equote - space)^0 * space * equote^0 * cquote) -- we escape unescaped ones

function string.optionalquoted(str)
    return lpegmatch(pattern,str) or str
end

local pattern = Cs((newline / (os.newline or "\r") + 1)^0)

function string.replacenewlines(str)
    return lpegmatch(pattern,str)
end

--

function strings.newcollector()
    local result, r = { }, 0
    return
        function(fmt,str,...) -- write
            r = r + 1
            result[r] = str == nil and fmt or formatters[fmt](str,...)
        end,
        function(connector) -- flush
            if result then
                local str = concat(result,connector)
                result, r = { }, 0
                return str
            end
        end
end

--

local f_16_16 = formatters["%0.5N"]

function number.to16dot16(n)
    return f_16_16(n/65536.0)
end

--

if not string.explode then

 -- local tsplitat = lpeg.tsplitat

    local p_utf   = patterns.utf8character
    local p_check = C(p_utf) * (P("+") * Cc(true))^0
    local p_split = Ct(C(p_utf)^0)
    local p_space = Ct((C(1-P(" ")^1) + P(" ")^1)^0)

    function string.explode(str,symbol)
        if symbol == "" then
            return lpegmatch(p_split,str)
        elseif symbol then
            local a, b = lpegmatch(p_check,symbol)
            if b then
                return lpegmatch(tsplitat(P(a)^1),str)
            else
                return lpegmatch(tsplitat(a),str)
            end
        else
            return lpegmatch(p_space,str)
        end
    end

end


do

    local p_whitespace = patterns.whitespace^1

    local cache = setmetatable({ }, { __index = function(t,k)
        local p = tsplitat(p_whitespace * P(k) * p_whitespace)
        local v = function(s)
            return lpegmatch(p,s)
        end
        t[k] = v
        return v
    end })

    function string.wordsplitter(s)
        return cache[s]
    end

end

