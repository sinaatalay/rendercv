if not modules then modules = { } end modules ['util-tpl'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- This is experimental code. Coming from dos and windows, I've always used %whatever%
-- as template variables so let's stick to it. After all, it's easy to parse and stands
-- out well. A double %% is turned into a regular %.

utilities.templates = utilities.templates or { }
local templates     = utilities.templates

local trace_template  = false  trackers.register("templates.trace",function(v) trace_template = v end)
local report_template = logs.reporter("template")

local tostring, next = tostring, next
local format, sub, byte = string.format, string.sub, string.byte
local P, C, R, Cs, Cc, Carg, lpegmatch, lpegpatterns = lpeg.P, lpeg.C, lpeg.R, lpeg.Cs, lpeg.Cc, lpeg.Carg, lpeg.match, lpeg.patterns

local formatters = string.formatters

-- todo: make installable template.new

local replacer

local function replacekey(k,t,how,recursive)
    local v = t[k]
    if not v then
        if trace_template then
            report_template("unknown key %a",k)
        end
        return ""
    else
        v = tostring(v)
        if trace_template then
            report_template("setting key %a to value %a",k,v)
        end
        if recursive then
            return lpegmatch(replacer,v,1,t,how,recursive)
        else
            return v
        end
    end
end

local sqlescape = lpeg.replacer {
    { "'",    "''"   },
    { "\\",   "\\\\" },
    { "\r\n", "\\n"  },
    { "\r",   "\\n"  },
 -- { "\t",   "\\t"  },
}

local sqlquoted = Cs(Cc("'") * sqlescape * Cc("'"))

lpegpatterns.sqlescape = sqlescape
lpegpatterns.sqlquoted = sqlquoted

-- escapeset  : \0\1\2\3\4\5\6\7\8\9\10\11\12\13\14\15\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31\"\\\127
-- test string: [[1\0\31test23"\\]] .. string.char(19) .. "23"
--
-- slow:
--
-- local luaescape = lpeg.replacer {
--     { '"',  [[\"]]   },
--     { '\\', [[\\]]   },
--     { R("\0\9")   * #R("09"), function(s) return "\\00" .. byte(s) end },
--     { R("\10\31") * #R("09"), function(s) return "\\0"  .. byte(s) end },
--     { R("\0\31")            , function(s) return "\\"   .. byte(s) end },
--     }
--
-- slightly faster:

-- local luaescape = Cs ((
--     P('"' ) / [[\"]] +
--     P('\\') / [[\\]] +
--     Cc("\\00") * (R("\0\9")   / byte) * #R("09") +
--     Cc("\\0")  * (R("\10\31") / byte) * #R("09") +
--     Cc("\\")   * (R("\0\31")  / byte)                 +
--     P(1)
-- )^0)

----- xmlescape = lpegpatterns.xmlescape
----- texescape = lpegpatterns.texescape
local luaescape = lpegpatterns.luaescape
----- sqlquoted = lpegpatterns.sqlquoted
----- luaquoted = lpegpatterns.luaquoted

local escapers = {
    lua = function(s)
     -- return sub(format("%q",s),2,-2)
        return lpegmatch(luaescape,s)
    end,
    sql = function(s)
        return lpegmatch(sqlescape,s)
    end,
}

local quotedescapers = {
    lua = function(s)
     -- return lpegmatch(luaquoted,s)
        return format("%q",s)
    end,
    sql = function(s)
        return lpegmatch(sqlquoted,s)
    end,
}

local luaescaper       = escapers.lua
local quotedluaescaper = quotedescapers.lua

local function replacekeyunquoted(s,t,how,recurse) -- ".. \" "
    if how == false then
        return replacekey(s,t,how,recurse)
    else
        local escaper = how and escapers[how] or luaescaper
        return escaper(replacekey(s,t,how,recurse))
    end
end

local function replacekeyquoted(s,t,how,recurse) -- ".. \" "
    if how == false then
        return replacekey(s,t,how,recurse)
    else
        local escaper = how and quotedescapers[how] or quotedluaescaper
        return escaper(replacekey(s,t,how,recurse))
    end
end

local function replaceoptional(l,m,r,t,how,recurse)
    local v = t[l]
    return v and v ~= "" and lpegmatch(replacer,r,1,t,how or "lua",recurse or false) or ""
end

local function replaceformatted(l,m,r,t,how,recurse)
    local v = t[r]
    return v and formatters[l](v)
end

local single       = P("%")  -- test %test% test     : resolves test
local double       = P("%%") -- test 10%% test       : %% becomes %
local lquoted      = P("%[") -- test '%[test]%' test : resolves to test with escaped "'s
local rquoted      = P("]%") --
local lquotedq     = P("%(") -- test %(test)% test   : resolves to 'test' with escaped "'s
local rquotedq     = P(")%") --

local escape       = double   / '%%'
local nosingle     = single   / ''
local nodouble     = double   / ''
local nolquoted    = lquoted  / ''
local norquoted    = rquoted  / ''
local nolquotedq   = lquotedq / ''
local norquotedq   = rquotedq / ''

local nolformatted = P(":") / "%%"
local norformatted = P(":") / ""

local noloptional  = P("%?") / ''
local noroptional  = P("?%") / ''
local nomoptional  = P(":")  / ''

local args         = Carg(1) * Carg(2) * Carg(3)
local key          = nosingle * ((C((1-nosingle)^1) * args) / replacekey) * nosingle
local quoted       = nolquotedq * ((C((1-norquotedq)^1) * args) / replacekeyquoted) * norquotedq
local unquoted     = nolquoted * ((C((1-norquoted)^1) * args) / replacekeyunquoted) * norquoted
local optional     = noloptional * ((C((1-nomoptional)^1) * nomoptional * C((1-noroptional)^1) * args) / replaceoptional) *  noroptional
local formatted    = nosingle * ((Cs(nolformatted * (1-norformatted )^1) * norformatted * C((1-nosingle)^1) * args) / replaceformatted) * nosingle
local any          = P(1)

      replacer     = Cs((unquoted + quoted + formatted + escape + optional + key + any)^0)

local function replace(str,mapping,how,recurse)
    if mapping and str then
        return lpegmatch(replacer,str,1,mapping,how or "lua",recurse or false) or str
    else
        return str
    end
end

-- print(replace("test '%[x]%' test",{ x = [[a 'x'  a]] }))
-- print(replace("test '%x%' test",{ x = [[a "x"  a]] }))
-- print(replace([[test "%[x]%" test]],{ x = [[a "x"  a]] }))
-- print(replace("test '%[x]%' test",{ x = true }))
-- print(replace("test '%[x]%' test",{ x = [[a 'x'  a]], y = "oeps" },'sql'))
-- print(replace("test '%[x]%' test",{ x = [[a '%y%'  a]], y = "oeps" },'sql',true))
-- print(replace([[test %[x]% test]],{ x = [[a "x"  a]]}))
-- print(replace([[test %(x)% test]],{ x = [[a "x"  a]]}))
-- print(replace([[convert %?x: -x "%x%" ?% %?y: -y "%y%" ?%]],{ x = "yes" }))
-- print(replace("test %:0.3N:x% test",{ x = 123.45 }))
-- print(replace("test %:0.3N:x% test",{ x = 12345 }))

templates.replace = replace

function templates.replacer(str,how,recurse) -- reads nicer
    return function(mapping)
        return lpegmatch(replacer,str,1,mapping,how or "lua",recurse or false) or str
    end
end

-- local cmd = templates.replacer([[foo %bar%]]) print(cmd { bar = "foo" })

function templates.load(filename,mapping,how,recurse)
    local data = io.loaddata(filename) or ""
    if mapping and next(mapping) then
        return replace(data,mapping,how,recurse)
    else
        return data
    end
end

function templates.resolve(t,mapping,how,recurse)
    if not mapping then
        mapping = t
    end
    for k, v in next, t do
        t[k] = replace(v,mapping,how,recurse)
    end
    return t
end

-- inspect(utilities.templates.replace("test %one% test", { one = "%two%", two = "two" }))
-- inspect(utilities.templates.resolve({ one = "%two%", two = "two", three = "%three%" }))
-- inspect(utilities.templates.replace("test %one% test", { one = "%two%", two = "two" },false,true))
-- inspect(utilities.templates.replace("test %one% test", { one = "%two%", two = "two" },false))
