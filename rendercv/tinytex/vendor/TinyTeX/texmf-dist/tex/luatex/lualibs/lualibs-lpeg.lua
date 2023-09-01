if not modules then modules = { } end modules ['l-lpeg'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- we can get too many captures (e.g. on largexml files) which makes me wonder
-- if P(foo)/"" can't be simplfied to N(foo) i.e. some direct instruction to the
-- lpeg virtual machine to ignore it

-- lpeg 12 vs lpeg 10: slower compilation, similar parsing speed (i need to check
-- if i can use new features like capture / 2 and .B (at first sight the xml
-- parser is some 5% slower)

-- lpeg.P("abc") is faster than lpeg.P("a") * lpeg.P("b") * lpeg.P("c")

-- a new lpeg fails on a #(1-P(":")) test and really needs a + P(-1)

-- move utf    -> l-unicode
-- move string -> l-string or keep it here

-- lpeg.B                                 : backward without consumption
-- lpeg.F = getmetatable(lpeg.P(1)).__len : forward  without consumption


lpeg = require("lpeg") -- does lpeg register itself global?

local lpeg = lpeg

-- The latest lpeg doesn't have print any more, and even the new ones are not
-- available by default (only when debug mode is enabled), which is a pitty as
-- as it helps nailing down bottlenecks. Performance seems comparable: some 10%
-- slower pattern compilation, same parsing speed, although,
--
-- local p = lpeg.C(lpeg.P(1)^0 * lpeg.P(-1))
-- local a = string.rep("123",100)
-- lpeg.match(p,a)
--
-- seems slower and is also still suboptimal (i.e. a match that runs from begin
-- to end, one of the cases where string matchers win).

if not lpeg.print then function lpeg.print(...) print(lpeg.pcode(...)) end end

-- tracing (only used when we encounter a problem in integration of lpeg in luatex)

-- some code will move to unicode and string

-- local lpmatch = lpeg.match
-- local lpprint = lpeg.print
-- local lpp     = lpeg.P
-- local lpr     = lpeg.R
-- local lps     = lpeg.S
-- local lpc     = lpeg.C
-- local lpb     = lpeg.B
-- local lpv     = lpeg.V
-- local lpcf    = lpeg.Cf
-- local lpcb    = lpeg.Cb
-- local lpcg    = lpeg.Cg
-- local lpct    = lpeg.Ct
-- local lpcs    = lpeg.Cs
-- local lpcc    = lpeg.Cc
-- local lpcmt   = lpeg.Cmt
-- local lpcarg  = lpeg.Carg

-- function lpeg.match(l,...) print("LPEG MATCH") lpprint(l) return lpmatch(l,...) end

-- function lpeg.P    (l) local p = lpp   (l) print("LPEG P =")    lpprint(l) return p end
-- function lpeg.R    (l) local p = lpr   (l) print("LPEG R =")    lpprint(l) return p end
-- function lpeg.S    (l) local p = lps   (l) print("LPEG S =")    lpprint(l) return p end
-- function lpeg.C    (l) local p = lpc   (l) print("LPEG C =")    lpprint(l) return p end
-- function lpeg.B    (l) local p = lpb   (l) print("LPEG B =")    lpprint(l) return p end
-- function lpeg.V    (l) local p = lpv   (l) print("LPEG V =")    lpprint(l) return p end
-- function lpeg.Cf   (l) local p = lpcf  (l) print("LPEG Cf =")   lpprint(l) return p end
-- function lpeg.Cb   (l) local p = lpcb  (l) print("LPEG Cb =")   lpprint(l) return p end
-- function lpeg.Cg   (l) local p = lpcg  (l) print("LPEG Cg =")   lpprint(l) return p end
-- function lpeg.Ct   (l) local p = lpct  (l) print("LPEG Ct =")   lpprint(l) return p end
-- function lpeg.Cs   (l) local p = lpcs  (l) print("LPEG Cs =")   lpprint(l) return p end
-- function lpeg.Cc   (l) local p = lpcc  (l) print("LPEG Cc =")   lpprint(l) return p end
-- function lpeg.Cmt  (l) local p = lpcmt (l) print("LPEG Cmt =")  lpprint(l) return p end
-- function lpeg.Carg (l) local p = lpcarg(l) print("LPEG Carg =") lpprint(l) return p end

local type, next, tostring = type, next, tostring
local byte, char, gmatch, format = string.byte, string.char, string.gmatch, string.format
----- mod, div = math.mod, math.div
local floor = math.floor

local P, R, S, V, Ct, C, Cs, Cc, Cp, Cmt = lpeg.P, lpeg.R, lpeg.S, lpeg.V, lpeg.Ct, lpeg.C, lpeg.Cs, lpeg.Cc, lpeg.Cp, lpeg.Cmt
local lpegtype, lpegmatch, lpegprint = lpeg.type, lpeg.match, lpeg.print

-- let's start with an inspector:

if setinspector then
    setinspector("lpeg",function(v) if lpegtype(v) then lpegprint(v) return true end end)
end

-- Beware, we predefine a bunch of patterns here and one reason for doing so
-- is that we get consistent behaviour in some of the visualizers.

lpeg.patterns  = lpeg.patterns or { } -- so that we can share
local patterns = lpeg.patterns

local anything         = P(1)
local endofstring      = P(-1)
local alwaysmatched    = P(true)

patterns.anything      = anything
patterns.endofstring   = endofstring
patterns.beginofstring = alwaysmatched
patterns.alwaysmatched = alwaysmatched

local sign             = S('+-')
local zero             = P('0')
local digit            = R('09')
local digits           = digit^1
local octdigit         = R("07")
local octdigits        = octdigit^1
local lowercase        = R("az")
local uppercase        = R("AZ")
local underscore       = P("_")
local hexdigit         = digit + lowercase + uppercase
local hexdigits        = hexdigit^1
local cr, lf, crlf     = P("\r"), P("\n"), P("\r\n")
----- newline          = crlf + S("\r\n") -- cr + lf
local newline          = P("\r") * (P("\n") + P(true)) + P("\n")  -- P("\r")^-1 * P("\n")^-1
local escaped          = P("\\") * anything
local squote           = P("'")
local dquote           = P('"')
local space            = P(" ")
local period           = P(".")
local comma            = P(",")

local utfbom_32_be     = P('\000\000\254\255') -- 00 00 FE FF
local utfbom_32_le     = P('\255\254\000\000') -- FF FE 00 00
local utfbom_16_be     = P('\254\255')         -- FE FF
local utfbom_16_le     = P('\255\254')         -- FF FE
local utfbom_8         = P('\239\187\191')     -- EF BB BF
local utfbom           = utfbom_32_be + utfbom_32_le
                       + utfbom_16_be + utfbom_16_le
                       + utfbom_8
local utftype          = utfbom_32_be * Cc("utf-32-be") + utfbom_32_le  * Cc("utf-32-le")
                       + utfbom_16_be * Cc("utf-16-be") + utfbom_16_le  * Cc("utf-16-le")
                       + utfbom_8     * Cc("utf-8")     + alwaysmatched * Cc("utf-8") -- assume utf8
local utfstricttype    = utfbom_32_be * Cc("utf-32-be") + utfbom_32_le  * Cc("utf-32-le")
                       + utfbom_16_be * Cc("utf-16-be") + utfbom_16_le  * Cc("utf-16-le")
                       + utfbom_8     * Cc("utf-8")
local utfoffset        = utfbom_32_be * Cc(4) + utfbom_32_le * Cc(4)
                       + utfbom_16_be * Cc(2) + utfbom_16_le * Cc(2)
                       + utfbom_8     * Cc(3) + Cc(0)

local utf8next         = R("\128\191")

patterns.utfbom_32_be  = utfbom_32_be
patterns.utfbom_32_le  = utfbom_32_le
patterns.utfbom_16_be  = utfbom_16_be
patterns.utfbom_16_le  = utfbom_16_le
patterns.utfbom_8      = utfbom_8

patterns.utf_16_be_nl  = P("\000\r\000\n") + P("\000\r") + P("\000\n") -- P("\000\r") * (P("\000\n") + P(true)) + P("\000\n")
patterns.utf_16_le_nl  = P("\r\000\n\000") + P("\r\000") + P("\n\000") -- P("\r\000") * (P("\n\000") + P(true)) + P("\n\000")

patterns.utf_32_be_nl  = P("\000\000\000\r\000\000\000\n") + P("\000\000\000\r") + P("\000\000\000\n")
patterns.utf_32_le_nl  = P("\r\000\000\000\n\000\000\000") + P("\r\000\000\000") + P("\n\000\000\000")

patterns.utf8one       = R("\000\127")
patterns.utf8two       = R("\194\223") * utf8next
patterns.utf8three     = R("\224\239") * utf8next * utf8next
patterns.utf8four      = R("\240\244") * utf8next * utf8next * utf8next
patterns.utfbom        = utfbom
patterns.utftype       = utftype
patterns.utfstricttype = utfstricttype
patterns.utfoffset     = utfoffset

local utf8char         = patterns.utf8one + patterns.utf8two + patterns.utf8three + patterns.utf8four
local validutf8char    = utf8char^0 * endofstring * Cc(true) + Cc(false)

local utf8character    = P(1) * R("\128\191")^0 -- unchecked but fast

patterns.utf8          = utf8char
patterns.utf8char      = utf8char
patterns.utf8character = utf8character -- this one can be used in most cases so we might use that one
patterns.validutf8     = validutf8char
patterns.validutf8char = validutf8char

local eol              = S("\n\r")
local spacer           = S(" \t\f\v")  -- + char(0xc2, 0xa0) if we want utf (cf mail roberto)
local whitespace       = eol + spacer
local nonspacer        = 1 - spacer
local nonwhitespace    = 1 - whitespace

patterns.eol           = eol
patterns.spacer        = spacer
patterns.whitespace    = whitespace
patterns.nonspacer     = nonspacer
patterns.nonwhitespace = nonwhitespace

local stripper         = spacer    ^0 * C((spacer    ^0 * nonspacer    ^1)^0)     -- from example by roberto
local fullstripper     = whitespace^0 * C((whitespace^0 * nonwhitespace^1)^0)

----- collapser        = Cs(spacer^0/"" * ((spacer^1 * endofstring / "") + (spacer^1/" ") + P(1))^0)
local collapser        = Cs(spacer^0/"" * nonspacer^0 * ((spacer^0/" " * nonspacer^1)^0))
local nospacer         = Cs((whitespace^1/"" + nonwhitespace^1)^0)

local b_collapser      = Cs( whitespace^0              /"" * (nonwhitespace^1 + whitespace^1/" ")^0)
local m_collapser      = Cs(                                 (nonwhitespace^1 + whitespace^1/" ")^0)
local e_collapser      = Cs((whitespace^1 * endofstring/"" +  nonwhitespace^1 + whitespace^1/" ")^0)
local x_collapser      = Cs(                                 (nonwhitespace^1 + whitespace^1/"" )^0)

local b_stripper       = Cs( spacer^0              /"" * (nonspacer^1 + spacer^1/" ")^0)
local m_stripper       = Cs(                             (nonspacer^1 + spacer^1/" ")^0)
local e_stripper       = Cs((spacer^1 * endofstring/"" +  nonspacer^1 + spacer^1/" ")^0)
local x_stripper       = Cs(                             (nonspacer^1 + spacer^1/"" )^0)

patterns.stripper      = stripper
patterns.fullstripper  = fullstripper
patterns.collapser     = collapser
patterns.nospacer      = nospacer

patterns.b_collapser   = b_collapser
patterns.m_collapser   = m_collapser
patterns.e_collapser   = e_collapser
patterns.x_collapser   = x_collapser

patterns.b_stripper    = b_stripper
patterns.m_stripper    = m_stripper
patterns.e_stripper    = e_stripper
patterns.x_stripper    = x_stripper

patterns.lowercase     = lowercase
patterns.uppercase     = uppercase
patterns.letter        = patterns.lowercase + patterns.uppercase
patterns.space         = space
patterns.tab           = P("\t")
patterns.spaceortab    = patterns.space + patterns.tab
patterns.newline       = newline
patterns.emptyline     = newline^1
patterns.equal         = P("=")
patterns.comma         = comma
patterns.commaspacer   = comma * spacer^0
patterns.period        = period
patterns.colon         = P(":")
patterns.semicolon     = P(";")
patterns.underscore    = underscore
patterns.escaped       = escaped
patterns.squote        = squote
patterns.dquote        = dquote
patterns.nosquote      = (escaped + (1-squote))^0
patterns.nodquote      = (escaped + (1-dquote))^0
patterns.unsingle      = (squote/"") * patterns.nosquote * (squote/"") -- will change to C in the middle
patterns.undouble      = (dquote/"") * patterns.nodquote * (dquote/"") -- will change to C in the middle
patterns.unquoted      = patterns.undouble + patterns.unsingle -- more often undouble
patterns.unspacer      = ((patterns.spacer^1)/"")^0

patterns.singlequoted  = squote * patterns.nosquote * squote
patterns.doublequoted  = dquote * patterns.nodquote * dquote
patterns.quoted        = patterns.doublequoted + patterns.singlequoted

patterns.digit         = digit
patterns.digits        = digits
patterns.octdigit      = octdigit
patterns.octdigits     = octdigits
patterns.hexdigit      = hexdigit
patterns.hexdigits     = hexdigits
patterns.sign          = sign
patterns.cardinal      = digits
patterns.integer       = sign^-1 * digits
patterns.unsigned      = digit^0 * period * digits
patterns.float         = sign^-1 * patterns.unsigned
patterns.cunsigned     = digit^0 * comma * digits
patterns.cpunsigned    = digit^0 * (period + comma) * digits
patterns.cfloat        = sign^-1 * patterns.cunsigned
patterns.cpfloat       = sign^-1 * patterns.cpunsigned
patterns.number        = patterns.float + patterns.integer
patterns.cnumber       = patterns.cfloat + patterns.integer
patterns.cpnumber      = patterns.cpfloat + patterns.integer
patterns.oct           = zero * octdigits -- hm is this ok
patterns.octal         = patterns.oct
patterns.HEX           = zero * P("X") * (digit+uppercase)^1
patterns.hex           = zero * P("x") * (digit+lowercase)^1
patterns.hexadecimal   = zero * S("xX") * hexdigits

patterns.hexafloat     = sign^-1
                       * zero * S("xX")
                       * (hexdigit^0 * period * hexdigits + hexdigits * period * hexdigit^0 + hexdigits)
                       * (S("pP") * sign^-1 * hexdigits)^-1
patterns.decafloat     = sign^-1
                       * (digit^0 * period * digits + digits * period * digit^0 + digits)
                       *  S("eE") * sign^-1 * digits

patterns.propername    = (uppercase + lowercase + underscore) * (uppercase + lowercase + underscore + digit)^0 * endofstring

patterns.somecontent   = (anything - newline - space)^1 -- (utf8char - newline - space)^1
patterns.beginline     = #(1-newline)

patterns.longtostring  = Cs(whitespace^0/"" * ((patterns.quoted + nonwhitespace^1 + whitespace^1/"" * (endofstring + Cc(" ")))^0))

-- local function anywhere(pattern) -- slightly adapted from website
--     return P { P(pattern) + 1 * V(1) }
-- end

local function anywhere(pattern) -- faster
    return (1-P(pattern))^0 * P(pattern)
end

lpeg.anywhere = anywhere

function lpeg.instringchecker(p)
    p = anywhere(p)
    return function(str)
        return lpegmatch(p,str) and true or false
    end
end

-- function lpeg.splitter(pattern, action)
--     return (((1-P(pattern))^1)/action+1)^0
-- end

-- function lpeg.tsplitter(pattern, action)
--     return Ct((((1-P(pattern))^1)/action+1)^0)
-- end

function lpeg.splitter(pattern, action)
    if action then
        return (((1-P(pattern))^1)/action+1)^0
    else
        return (Cs((1-P(pattern))^1)+1)^0
    end
end

function lpeg.tsplitter(pattern, action)
    if action then
        return Ct((((1-P(pattern))^1)/action+1)^0)
    else
        return Ct((Cs((1-P(pattern))^1)+1)^0)
    end
end

-- probleem: separator can be lpeg and that does not hash too well, but
-- it's quite okay as the key is then not garbage collected

local splitters_s, splitters_m, splitters_t = { }, { }, { }

local function splitat(separator,single)
    local splitter = (single and splitters_s[separator]) or splitters_m[separator]
    if not splitter then
        separator = P(separator)
        local other = C((1 - separator)^0)
        if single then
            local any = anything
            splitter = other * (separator * C(any^0) + "") -- ?
            splitters_s[separator] = splitter
        else
            splitter = other * (separator * other)^0
            splitters_m[separator] = splitter
        end
    end
    return splitter
end

local function tsplitat(separator)
    local splitter = splitters_t[separator]
    if not splitter then
        splitter = Ct(splitat(separator))
        splitters_t[separator] = splitter
    end
    return splitter
end

lpeg.splitat  = splitat
lpeg.tsplitat = tsplitat

function string.splitup(str,separator)
    if not separator then
        separator = ","
    end
    return lpegmatch(splitters_m[separator] or splitat(separator),str)
end

-- local p = splitat("->",false)  print(lpegmatch(p,"oeps->what->more"))  -- oeps what more
-- local p = splitat("->",true)   print(lpegmatch(p,"oeps->what->more"))  -- oeps what->more
-- local p = splitat("->",false)  print(lpegmatch(p,"oeps"))              -- oeps
-- local p = splitat("->",true)   print(lpegmatch(p,"oeps"))              -- oeps

local cache = { }

function lpeg.split(separator,str)
    local c = cache[separator]
    if not c then
        c = tsplitat(separator)
        cache[separator] = c
    end
    return lpegmatch(c,str)
end

function string.split(str,separator)
    if separator then
        local c = cache[separator]
        if not c then
            c = tsplitat(separator)
            cache[separator] = c
        end
        return lpegmatch(c,str)
    else
        return { str }
    end
end

local spacing  = patterns.spacer^0 * newline -- sort of strip
local empty    = spacing * Cc("")
local nonempty = Cs((1-spacing)^1) * spacing^-1
local content  = (empty + nonempty)^1

patterns.textline = content

local linesplitter = tsplitat(newline)

patterns.linesplitter = linesplitter

function string.splitlines(str)
    return lpegmatch(linesplitter,str)
end

-- lpeg.splitters = cache -- no longer public

local cache = { }

function lpeg.checkedsplit(separator,str)
    local c = cache[separator]
    if not c then
        separator = P(separator)
        local other = C((1 - separator)^1)
        c = Ct(separator^0 * other * (separator^1 * other)^0)
        cache[separator] = c
    end
    return lpegmatch(c,str)
end

function string.checkedsplit(str,separator)
    local c = cache[separator]
    if not c then
        separator = P(separator)
        local other = C((1 - separator)^1)
        c = Ct(separator^0 * other * (separator^1 * other)^0)
        cache[separator] = c
    end
    return lpegmatch(c,str)
end

-- from roberto's site:

local function f2(s) local c1, c2         = byte(s,1,2) return   c1 * 64 + c2                       -    12416 end
local function f3(s) local c1, c2, c3     = byte(s,1,3) return  (c1 * 64 + c2) * 64 + c3            -   925824 end
local function f4(s) local c1, c2, c3, c4 = byte(s,1,4) return ((c1 * 64 + c2) * 64 + c3) * 64 + c4 - 63447168 end

local utf8byte = patterns.utf8one/byte + patterns.utf8two/f2 + patterns.utf8three/f3 + patterns.utf8four/f4

patterns.utf8byte = utf8byte

--~ local str = " a b c d "

--~ local s = lpeg.stripper(lpeg.R("az"))   print("["..lpegmatch(s,str).."]")
--~ local s = lpeg.keeper(lpeg.R("az"))     print("["..lpegmatch(s,str).."]")
--~ local s = lpeg.stripper("ab")           print("["..lpegmatch(s,str).."]")
--~ local s = lpeg.keeper("ab")             print("["..lpegmatch(s,str).."]")

local cache = { }

function lpeg.stripper(str)
    if type(str) == "string" then
        local s = cache[str]
        if not s then
            s = Cs(((S(str)^1)/"" + 1)^0)
            cache[str] = s
        end
        return s
    else
        return Cs(((str^1)/"" + 1)^0)
    end
end

local cache = { }

function lpeg.keeper(str)
    if type(str) == "string" then
        local s = cache[str]
        if not s then
            s = Cs((((1-S(str))^1)/"" + 1)^0)
            cache[str] = s
        end
        return s
    else
        return Cs((((1-str)^1)/"" + 1)^0)
    end
end

function lpeg.frontstripper(str) -- or pattern (yet undocumented)
    return (P(str) + P(true)) * Cs(anything^0)
end

function lpeg.endstripper(str) -- or pattern (yet undocumented)
    return Cs((1 - P(str) * endofstring)^0)
end

-- Just for fun I looked at the used bytecode and
-- p = (p and p + pp) or pp gets one more (testset).

-- todo: cache when string

function lpeg.replacer(one,two,makefunction,isutf) -- in principle we should sort the keys but we have a better one anyway
    local pattern
    local u = isutf and utf8char or 1
    if type(one) == "table" then
        local no = #one
        local p = P(false)
        if no == 0 then
            for k, v in next, one do
                p = p + P(k) / v
            end
            pattern = Cs((p + u)^0)
        elseif no == 1 then
            local o = one[1]
            one, two = P(o[1]), o[2]
         -- pattern = Cs(((1-one)^1 + one/two)^0)
            pattern = Cs((one/two + u)^0)
        else
            for i=1,no do
                local o = one[i]
                p = p + P(o[1]) / o[2]
            end
            pattern = Cs((p + u)^0)
        end
    else
        pattern = Cs((P(one)/(two or "") + u)^0)
    end
    if makefunction then
        return function(str)
            return lpegmatch(pattern,str)
        end
    else
        return pattern
    end
end

-- local pattern1 = P(1-P(pattern))^0 * P(pattern)   : test for not nil
-- local pattern2 = (P(pattern) * Cc(true) + P(1))^0 : test for true (could be faster, but not much)

function lpeg.finder(lst,makefunction,isutf) -- beware: slower than find with 'patternless finds'
    local pattern
    if type(lst) == "table" then
        pattern = P(false)
        if #lst == 0 then
            for k, v in next, lst do
                pattern = pattern + P(k) -- ignore key, so we can use a replacer table
            end
        else
            for i=1,#lst do
                pattern = pattern + P(lst[i])
            end
        end
    else
        pattern = P(lst)
    end
    if isutf then
        pattern = ((utf8char or 1)-pattern)^0 * pattern
    else
        pattern = (1-pattern)^0 * pattern
    end
    if makefunction then
        return function(str)
            return lpegmatch(pattern,str)
        end
    else
        return pattern
    end
end

-- print(lpeg.match(lpeg.replacer("e","a"),"test test"))
-- print(lpeg.match(lpeg.replacer{{"e","a"}},"test test"))
-- print(lpeg.match(lpeg.replacer({ e = "a", t = "x" }),"test test"))

local splitters_f, splitters_s = { }, { }

function lpeg.firstofsplit(separator) -- always return value
    local splitter = splitters_f[separator]
    if not splitter then
        local pattern = P(separator)
        splitter = C((1 - pattern)^0)
        splitters_f[separator] = splitter
    end
    return splitter
end

function lpeg.secondofsplit(separator) -- nil if not split
    local splitter = splitters_s[separator]
    if not splitter then
        local pattern = P(separator)
        splitter = (1 - pattern)^0 * pattern * C(anything^0)
        splitters_s[separator] = splitter
    end
    return splitter
end

local splitters_s, splitters_p = { }, { }

function lpeg.beforesuffix(separator) -- nil if nothing but empty is ok
    local splitter = splitters_s[separator]
    if not splitter then
        local pattern = P(separator)
        splitter = C((1 - pattern)^0) * pattern * endofstring
        splitters_s[separator] = splitter
    end
    return splitter
end

function lpeg.afterprefix(separator) -- nil if nothing but empty is ok
    local splitter = splitters_p[separator]
    if not splitter then
        local pattern = P(separator)
        splitter = pattern * C(anything^0)
        splitters_p[separator] = splitter
    end
    return splitter
end

function lpeg.balancer(left,right)
    left, right = P(left), P(right)
    return P { left * ((1 - left - right) + V(1))^0 * right }
end

-- print(1,lpegmatch(lpeg.firstofsplit(":"),"bc:de"))
-- print(2,lpegmatch(lpeg.firstofsplit(":"),":de")) -- empty
-- print(3,lpegmatch(lpeg.firstofsplit(":"),"bc"))
-- print(4,lpegmatch(lpeg.secondofsplit(":"),"bc:de"))
-- print(5,lpegmatch(lpeg.secondofsplit(":"),"bc:")) -- empty
-- print(6,lpegmatch(lpeg.secondofsplit(":",""),"bc"))
-- print(7,lpegmatch(lpeg.secondofsplit(":"),"bc"))
-- print(9,lpegmatch(lpeg.secondofsplit(":","123"),"bc"))

-- this was slower but lpeg has been sped up in the meantime, so we no longer
-- use this (still seems somewhat faster on long strings)
--
-- local nany = utf8char/""
--
-- function lpeg.counter(pattern)
--     pattern = Cs((P(pattern)/" " + nany)^0)
--     return function(str)
--         return #lpegmatch(pattern,str)
--     end
-- end

function lpeg.counter(pattern,action)
    local n       = 0
    local pattern = (P(pattern) / function() n = n + 1 end + anything)^0
    ----- pattern = (P(pattern) * (P(true) / function() n = n + 1 end) + anything)^0
    ----- pattern = (P(pattern) * P(function() n = n + 1 end) + anything)^0
    if action then
        return function(str) n = 0 ; lpegmatch(pattern,str) ; action(n) end
    else
        return function(str) n = 0 ; lpegmatch(pattern,str) ; return n end
    end
end

-- lpeg.print(lpeg.R("ab","cd","gh"))
-- lpeg.print(lpeg.P("a","b","c"))
-- lpeg.print(lpeg.S("a","b","c"))

-- print(lpeg.counter(lpeg.P("á") + lpeg.P("à"))("äáàa"))
-- print(lpeg.counter(lpeg.UP("áà"))("äáàa"))
-- print(lpeg.counter(lpeg.US("àá"))("äáàa"))
-- print(lpeg.counter(lpeg.UR("aá"))("äáàa"))
-- print(lpeg.counter(lpeg.UR("àá"))("äáàa"))
-- print(lpeg.counter(lpeg.UR(0x0000,0xFFFF)))

function lpeg.is_lpeg(p)
    return p and lpegtype(p) == "pattern"
end

function lpeg.oneof(list,...) -- lpeg.oneof("elseif","else","if","then") -- assume proper order
    if type(list) ~= "table" then
        list = { list, ... }
    end
 -- table.sort(list) -- longest match first
    local p = P(list[1])
    for l=2,#list do
        p = p + P(list[l])
    end
    return p
end

-- For the moment here, but it might move to utilities. Beware, we need to
-- have the longest keyword first, so 'aaa' comes beforte 'aa' which is why we
-- loop back from the end cq. prepend.

local sort = table.sort

local function copyindexed(old)
    local new = { }
    for i=1,#old do
        new[i] = old
    end
    return new
end

local function sortedkeys(tab)
    local keys, s = { }, 0
    for key,_ in next, tab do
        s = s + 1
        keys[s] = key
    end
    sort(keys)
    return keys
end

function lpeg.append(list,pp,delayed,checked)
    local p = pp
    if #list > 0 then
        local keys = copyindexed(list)
        sort(keys)
        for i=#keys,1,-1 do
            local k = keys[i]
            if p then
                p = P(k) + p
            else
                p = P(k)
            end
        end
    elseif delayed then -- hm, it looks like the lpeg parser resolves anyway
        local keys = sortedkeys(list)
        if p then
            for i=1,#keys,1 do
                local k = keys[i]
                local v = list[k]
                p = P(k)/list + p
            end
        else
            for i=1,#keys do
                local k = keys[i]
                local v = list[k]
                if p then
                    p = P(k) + p
                else
                    p = P(k)
                end
            end
            if p then
                p = p / list
            end
        end
    elseif checked then
        -- problem: substitution gives a capture
        local keys = sortedkeys(list)
        for i=1,#keys do
            local k = keys[i]
            local v = list[k]
            if p then
                if k == v then
                    p = P(k) + p
                else
                    p = P(k)/v + p
                end
            else
                if k == v then
                    p = P(k)
                else
                    p = P(k)/v
                end
            end
        end
    else
        local keys = sortedkeys(list)
        for i=1,#keys do
            local k = keys[i]
            local v = list[k]
            if p then
                p = P(k)/v + p
            else
                p = P(k)/v
            end
        end
    end
    return p
end

-- inspect(lpeg.append({ a = "1", aa = "1", aaa = "1" } ,nil,true))
-- inspect(lpeg.append({ ["degree celsius"] = "1", celsius = "1", degree = "1" } ,nil,true))

-- function lpeg.exact_match(words,case_insensitive)
--     local pattern = concat(words)
--     if case_insensitive then
--         local pattern = S(upper(characters)) + S(lower(characters))
--         local list = { }
--         for i=1,#words do
--             list[lower(words[i])] = true
--         end
--         return Cmt(pattern^1, function(_,i,s)
--             return list[lower(s)] and i
--         end)
--     else
--         local pattern = S(concat(words))
--         local list = { }
--         for i=1,#words do
--             list[words[i]] = true
--         end
--         return Cmt(pattern^1, function(_,i,s)
--             return list[s] and i
--         end)
--     end
-- end

-- experiment:

local p_false = P(false)
local p_true  = P(true)

-- local function collapse(t,x)
--     if type(t) ~= "table" then
--         return t, x
--     else
--         local n = next(t)
--         if n == nil then
--             return t, x
--         elseif next(t,n) == nil then
--             -- one entry
--             local k = n
--             local v = t[k]
--             if type(v) == "table" then
--                 return collapse(v,x..k)
--             else
--                 return v, x .. k
--             end
--         else
--             local tt = { }
--             for k, v in next, t do
--                 local vv, kk = collapse(v,k)
--                 tt[kk] = vv
--             end
--             return tt, x
--         end
--     end
-- end

local lower = utf and utf.lower or string.lower
local upper = utf and utf.upper or string.upper

function lpeg.setutfcasers(l,u)
    lower = l or lower
    upper = u or upper
end

local function make1(t,rest)
    local p    = p_false
    local keys = sortedkeys(t)
    for i=1,#keys do
        local k = keys[i]
        if k ~= "" then
            local v = t[k]
            if v == true then
                p = p + P(k) * p_true
            elseif v == false then
                -- can't happen
            else
                p = p + P(k) * make1(v,v[""])
            end
        end
    end
    if rest then
        p = p + p_true
    end
    return p
end

local function make2(t,rest) -- only ascii
    local p    = p_false
    local keys = sortedkeys(t)
    for i=1,#keys do
        local k = keys[i]
        if k ~= "" then
            local v = t[k]
            if v == true then
                p = p + (P(lower(k))+P(upper(k))) * p_true
            elseif v == false then
                -- can't happen
            else
                p = p + (P(lower(k))+P(upper(k))) * make2(v,v[""])
            end
        end
    end
    if rest then
        p = p + p_true
    end
    return p
end

local function utfchartabletopattern(list,insensitive) -- goes to util-lpg
    local tree = { }
    local n = #list
    if n == 0 then
        for s in next, list do
            local t = tree
            local p, pk
            for c in gmatch(s,".") do
                if t == true then
                    t = { [c] = true, [""] = true }
                    p[pk] = t
                    p = t
                    t = false
                elseif t == false then
                    t = { [c] = false }
                    p[pk] = t
                    p = t
                    t = false
                else
                    local tc = t[c]
                    if not tc then
                        tc = false
                        t[c] = false
                    end
                    p = t
                    t = tc
                end
                pk = c
            end
            if t == false then
                p[pk] = true
            elseif t == true then
                -- okay
            else
                t[""] = true
            end
        end
    else
        for i=1,n do
            local s = list[i]
            local t = tree
            local p, pk
            for c in gmatch(s,".") do
                if t == true then
                    t = { [c] = true, [""] = true }
                    p[pk] = t
                    p = t
                    t = false
                elseif t == false then
                    t = { [c] = false }
                    p[pk] = t
                    p = t
                    t = false
                else
                    local tc = t[c]
                    if not tc then
                        tc = false
                        t[c] = false
                    end
                    p = t
                    t = tc
                end
                pk = c
            end
            if t == false then
                p[pk] = true
            elseif t == true then
                -- okay
            else
                t[""] = true
            end
        end
    end
 -- collapse(tree,"") -- needs testing, maybe optional, slightly faster because P("x")*P("X") seems slower than P"(xX") (why)
 -- inspect(tree)
    return (insensitive and make2 or make1)(tree)
end

lpeg.utfchartabletopattern = utfchartabletopattern

function lpeg.utfreplacer(list,insensitive)
    local pattern = Cs((utfchartabletopattern(list,insensitive)/list + utf8character)^0)
    return function(str)
        return lpegmatch(pattern,str) or str
    end
end

-- local t = { "start", "stoep", "staart", "paard" }
-- local p = lpeg.Cs((lpeg.utfchartabletopattern(t)/string.upper + 1)^1)

-- local t = { "a", "abc", "ac", "abe", "abxyz", "xy", "bef","aa" }
-- local p = lpeg.Cs((lpeg.utfchartabletopattern(t)/string.upper + 1)^1)

-- inspect(lpegmatch(p,"a")=="A")
-- inspect(lpegmatch(p,"aa")=="AA")
-- inspect(lpegmatch(p,"aaaa")=="AAAA")
-- inspect(lpegmatch(p,"ac")=="AC")
-- inspect(lpegmatch(p,"bc")=="bc")
-- inspect(lpegmatch(p,"zzbczz")=="zzbczz")
-- inspect(lpegmatch(p,"zzabezz")=="zzABEzz")
-- inspect(lpegmatch(p,"ab")=="Ab")
-- inspect(lpegmatch(p,"abc")=="ABC")
-- inspect(lpegmatch(p,"abe")=="ABE")
-- inspect(lpegmatch(p,"xa")=="xA")
-- inspect(lpegmatch(p,"bx")=="bx")
-- inspect(lpegmatch(p,"bax")=="bAx")
-- inspect(lpegmatch(p,"abxyz")=="ABXYZ")
-- inspect(lpegmatch(p,"foobarbefcrap")=="foobArBEFcrAp")

-- local t = { ["^"] = 1, ["^^"] = 2, ["^^^"] = 3, ["^^^^"] = 4 }
-- local p = lpeg.Cs((lpeg.utfchartabletopattern(t)/t + 1)^1)
-- inspect(lpegmatch(p," ^ ^^ ^^^ ^^^^ ^^^^^ ^^^^^^ ^^^^^^^ "))

-- local t = { ["^^"] = 2, ["^^^"] = 3, ["^^^^"] = 4 }
-- local p = lpeg.Cs((lpeg.utfchartabletopattern(t)/t + 1)^1)
-- inspect(lpegmatch(p," ^ ^^ ^^^ ^^^^ ^^^^^ ^^^^^^ ^^^^^^^ "))

-- lpeg.utfchartabletopattern {
--     utfchar(0x00A0), -- nbsp
--     utfchar(0x2000), -- enquad
--     utfchar(0x2001), -- emquad
--     utfchar(0x2002), -- enspace
--     utfchar(0x2003), -- emspace
--     utfchar(0x2004), -- threeperemspace
--     utfchar(0x2005), -- fourperemspace
--     utfchar(0x2006), -- sixperemspace
--     utfchar(0x2007), -- figurespace
--     utfchar(0x2008), -- punctuationspace
--     utfchar(0x2009), -- breakablethinspace
--     utfchar(0x200A), -- hairspace
--     utfchar(0x200B), -- zerowidthspace
--     utfchar(0x202F), -- narrownobreakspace
--     utfchar(0x205F), -- math thinspace
-- }

-- a few handy ones:
--
-- faster than find(str,"[\n\r]") when match and # > 7 and always faster when # > 3

patterns.containseol = lpeg.finder(eol) -- (1-eol)^0 * eol

-- The next pattern^n variant is based on an approach suggested
-- by Roberto: constructing a big repetition in chunks.
--
-- Being sparse is not needed, and only complicate matters and
-- the number of redundant entries is not that large.

local function nextstep(n,step,result)
    local m = n % step      -- mod(n,step)
    local d = floor(n/step) -- div(n,step)
    if d > 0 then
        local v = V(tostring(step))
        local s = result.start
        for i=1,d do
            if s then
                s = v * s
            else
                s = v
            end
        end
        result.start = s
    end
    if step > 1 and result.start then
        local v = V(tostring(step/2))
        result[tostring(step)] = v * v
    end
    if step > 0 then
        return nextstep(m,step/2,result)
    else
        return result
    end
end

function lpeg.times(pattern,n)
    return P(nextstep(n,2^16,{ "start", ["1"] = pattern }))
end

-- local p = lpeg.Cs((1 - lpeg.times(lpeg.P("AB"),25))^1)
-- local s = "12" .. string.rep("AB",20) .. "34" .. string.rep("AB",30) .. "56"
-- inspect(p)
-- print(lpeg.match(p,s))

-- moved here (before util-str)

do

    local trailingzeros = zero^0 * -digit -- suggested by Roberto
    local stripper      = Cs((
        digits * (
            period * trailingzeros / ""
          + period * (digit - trailingzeros)^1 * (trailingzeros / "")
        ) + 1
    )^0)

    lpeg.patterns.stripzeros = stripper -- multiple in string

    local nonzero       = digit - zero
    local trailingzeros = zero^1 * endofstring
    local stripper      = Cs( (1-period)^0 * (
        period *               trailingzeros/""
      + period * (nonzero^1 + (trailingzeros/"") + zero^1)^0
      + endofstring
    ))

    lpeg.patterns.stripzero  = stripper -- slightly more efficient but expects a float !

    -- local sample = "bla 11.00 bla 11 bla 0.1100 bla 1.00100 bla 0.00 bla 0.001 bla 1.1100 bla 0.100100100 bla 0.00100100100"
    -- collectgarbage("collect")
    -- str = string.rep(sample,10000)
    -- local ts = os.clock()
    -- lpegmatch(stripper,str)
    -- print(#str, os.clock()-ts, lpegmatch(stripper,sample))

end

-- for practical reasons we keep this here:

local byte_to_HEX = { }
local byte_to_hex = { }
local byte_to_dec = { } -- for md5
local hex_to_byte = { }

for i=0,255 do
    local H = format("%02X",i)
    local h = format("%02x",i)
    local d = format("%03i",i)
    local c = char(i)
    byte_to_HEX[c] = H
    byte_to_hex[c] = h
    byte_to_dec[c] = d
    hex_to_byte[h] = c
    hex_to_byte[H] = c
end

local hextobyte  = P(2)/hex_to_byte
local bytetoHEX  = P(1)/byte_to_HEX
local bytetohex  = P(1)/byte_to_hex
local bytetodec  = P(1)/byte_to_dec
local hextobytes = Cs(hextobyte^0)
local bytestoHEX = Cs(bytetoHEX^0)
local bytestohex = Cs(bytetohex^0)
local bytestodec = Cs(bytetodec^0)

patterns.hextobyte  = hextobyte
patterns.bytetoHEX  = bytetoHEX
patterns.bytetohex  = bytetohex
patterns.bytetodec  = bytetodec
patterns.hextobytes = hextobytes
patterns.bytestoHEX = bytestoHEX
patterns.bytestohex = bytestohex
patterns.bytestodec = bytestodec

function string.toHEX(s)
    if not s or s == "" then
        return s
    else
        return lpegmatch(bytestoHEX,s)
    end
end

function string.tohex(s)
    if not s or s == "" then
        return s
    else
        return lpegmatch(bytestohex,s)
    end
end

function string.todec(s)
    if not s or s == "" then
        return s
    else
        return lpegmatch(bytestodec,s)
    end
end

function string.tobytes(s)
    if not s or s == "" then
        return s
    else
        return lpegmatch(hextobytes,s)
    end
end

-- local h = "ADFE0345"
-- local b = lpegmatch(patterns.hextobytes,h)
-- print(h,b,string.tohex(b),string.toHEX(b))

local patterns = { } -- can be made weak

local function containsws(what)
    local p = patterns[what]
    if not p then
        local p1 = P(what) * (whitespace + endofstring) * Cc(true)
        local p2 = whitespace * P(p1)
        p = P(p1) + P(1-p2)^0 * p2 + Cc(false)
        patterns[what] = p
    end
    return p
end

lpeg.containsws = containsws

function string.containsws(str,what)
    return lpegmatch(patterns[what] or containsws(what),str)
end
