if not modules then modules = { } end modules ['l-string'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local string = string
local sub, gmatch, format, char, byte, rep, lower, find = string.sub, string.gmatch, string.format, string.char, string.byte, string.rep, string.lower, string.find
local lpegmatch, patterns = lpeg.match, lpeg.patterns
local P, S, C, Ct, Cc, Cs = lpeg.P, lpeg.S, lpeg.C, lpeg.Ct, lpeg.Cc, lpeg.Cs

-- Some functions are already defined in l-lpeg and maybe some from here will
-- move there (unless we also expose caches).

-- if not string.split then
--
--     function string.split(str,pattern)
--         local t = { }
--         if str ~= "" then
--             local n = 1
--             for s in gmatch(str..pattern,"(.-)"..pattern) do
--                 t[n] = s
--                 n = n + 1
--             end
--         end
--         return t
--     end
--
-- end

-- function string.unquoted(str)
--     return (gsub(str,"^([\"\'])(.*)%1$","%2")) -- interesting pattern
-- end

local unquoted = patterns.squote * C(patterns.nosquote) * patterns.squote
               + patterns.dquote * C(patterns.nodquote) * patterns.dquote

function string.unquoted(str)
    return lpegmatch(unquoted,str) or str
end

-- print(string.unquoted("test"))
-- print(string.unquoted([["t\"est"]]))
-- print(string.unquoted([["t\"est"x]]))
-- print(string.unquoted("\'test\'"))
-- print(string.unquoted('"test"'))
-- print(string.unquoted('"test"'))

function string.quoted(str)
    return format("%q",str) -- always double quote
end

-- function string.count(str,pattern) -- variant 3
--     local n = 0
--     for _ in gmatch(str,pattern) do -- not for utf
--         n = n + 1
--     end
--     return n
-- end

function string.count(str,pattern)
    local n = 0
    local i = 1
    local l = #pattern
    while true do
        i = find(str,pattern,i)
        if i then
            n = n + 1
            i = i + l
        else
            break
        end
    end
    return n
end

function string.limit(str,n,sentinel) -- not utf proof
    if #str > n then
        sentinel = sentinel or "..."
        return sub(str,1,(n-#sentinel)) .. sentinel
    else
        return str
    end
end

local stripper     = patterns.stripper
local fullstripper = patterns.fullstripper
local collapser    = patterns.collapser
local nospacer     = patterns.nospacer
local longtostring = patterns.longtostring

function string.strip(str)
    return str and lpegmatch(stripper,str) or ""
end

function string.fullstrip(str)
    return str and lpegmatch(fullstripper,str) or ""
end

function string.collapsespaces(str)
    return str and lpegmatch(collapser,str) or ""
end

function string.nospaces(str)
    return str and lpegmatch(nospacer,str) or ""
end

function string.longtostring(str)
    return str and lpegmatch(longtostring,str) or ""
end

-- function string.is_empty(str)
--     return not find(str,"%S")
-- end

local pattern = P(" ")^0 * P(-1) -- maybe also newlines

-- patterns.onlyspaces = pattern

function string.is_empty(str)
    if not str or str == "" then
        return true
    else
        return lpegmatch(pattern,str) and true or false
    end
end

-- if not string.escapedpattern then
--
--     local patterns_escapes = {
--         ["%"] = "%%",
--         ["."] = "%.",
--         ["+"] = "%+", ["-"] = "%-", ["*"] = "%*",
--         ["["] = "%[", ["]"] = "%]",
--         ["("] = "%(", [")"] = "%)",
--      -- ["{"] = "%{", ["}"] = "%}"
--      -- ["^"] = "%^", ["$"] = "%$",
--     }
--
--     local simple_escapes = {
--         ["-"] = "%-",
--         ["."] = "%.",
--         ["?"] = ".",
--         ["*"] = ".*",
--     }
--
--     function string.escapedpattern(str,simple)
--         return (gsub(str,".",simple and simple_escapes or patterns_escapes))
--     end
--
--     function string.topattern(str,lowercase,strict)
--         if str == "" then
--             return ".*"
--         else
--             str = gsub(str,".",simple_escapes)
--             if lowercase then
--                 str = lower(str)
--             end
--             if strict then
--                 return "^" .. str .. "$"
--             else
--                 return str
--             end
--         end
--     end
--
-- end

--- needs checking

local anything     = patterns.anything
local moreescapes  = Cc("%") * S(".-+%?()[]*$^{}")
local allescapes   = Cc("%") * S(".-+%?()[]*")   -- also {} and ^$ ?
local someescapes  = Cc("%") * S(".-+%()[]")     -- also {} and ^$ ?
local matchescapes = Cc(".") * S("*?")           -- wildcard and single match

local pattern_m = Cs ( ( moreescapes + anything )^0 )
local pattern_a = Cs ( ( allescapes  + anything )^0 )
local pattern_b = Cs ( ( someescapes + matchescapes + anything )^0 )
local pattern_c = Cs ( Cc("^") * ( someescapes + matchescapes + anything )^0 * Cc("$") )

function string.escapedpattern(str,simple)
    return lpegmatch(simple and pattern_b or pattern_a,str)
end

function string.topattern(str,lowercase,strict)
    if str == "" or type(str) ~= "string" then
        return ".*"
    elseif strict == "all" then
        str = lpegmatch(pattern_m,str)
    elseif strict then
        str = lpegmatch(pattern_c,str)
    else
        str = lpegmatch(pattern_b,str)
    end
    if lowercase then
        return lower(str)
    else
        return str
    end
end

-- print(string.escapedpattern("abc*234",true))
-- print(string.escapedpattern("12+34*.tex",false))
-- print(string.escapedpattern("12+34*.tex",true))
-- print(string.topattern     ("12+34*.tex",false,false))
-- print(string.topattern     ("12+34*.tex",false,true))

function string.valid(str,default)
    return (type(str) == "string" and str ~= "" and str) or default or nil
end

-- handy fallback

string.itself  = function(s) return s end

-- also handy (see utf variant)

local pattern_c = Ct( C(1)      ^0) -- string and not utf !
local pattern_b = Ct((C(1)/byte)^0)

function string.totable(str,bytes)
    return lpegmatch(bytes and pattern_b or pattern_c,str)
end

-- handy from within tex:

local replacer = lpeg.replacer("@","%%") -- Watch the escaped % in lpeg!

function string.tformat(fmt,...)
    return format(lpegmatch(replacer,fmt),...)
end

-- obsolete names:

string.quote   = string.quoted
string.unquote = string.unquoted

-- new

if not string.bytetable then -- used in font-cff.lua

    local limit = 5000 -- we can go to 8000 in luajit and much higher in lua if needed

    function string.bytetable(str) -- from a string
        local n = #str
        if n > limit then
            local t = { byte(str,1,limit) }
            for i=limit+1,n do
                t[i] = byte(str,i)
            end
            return t
        else
            return { byte(str,1,n) }
        end
    end

end
