if not modules then modules = { } end modules ['util-prs'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local lpeg, table, string = lpeg, table, string
local P, R, V, S, C, Ct, Cs, Carg, Cc, Cg, Cf, Cp = lpeg.P, lpeg.R, lpeg.V, lpeg.S, lpeg.C, lpeg.Ct, lpeg.Cs, lpeg.Carg, lpeg.Cc, lpeg.Cg, lpeg.Cf, lpeg.Cp
local lpegmatch, lpegpatterns = lpeg.match, lpeg.patterns
local concat, gmatch, find = table.concat, string.gmatch, string.find
local tonumber, tostring, type, next, rawset = tonumber, tostring, type, next, rawset
local mod, div = math.mod, math.div

utilities         = utilities or {}
local parsers     = utilities.parsers or { }
utilities.parsers = parsers
local patterns    = parsers.patterns or { }
parsers.patterns  = patterns

local setmetatableindex = table.setmetatableindex
local sortedhash        = table.sortedhash
local sortedkeys        = table.sortedkeys
local tohash            = table.tohash

local hashes            = { }
parsers.hashes          = hashes
-- we share some patterns

local digit       = R("09")
local space       = P(' ')
local equal       = P("=")
local colon       = P(":")
local comma       = P(",")
local lbrace      = P("{")
local rbrace      = P("}")
local lparent     = P("(")
local rparent     = P(")")
local lbracket    = P("[")
local rbracket    = P("]")
local period      = S(".")
local punctuation = S(".,:;")
local spacer      = lpegpatterns.spacer
local whitespace  = lpegpatterns.whitespace
local newline     = lpegpatterns.newline
local anything    = lpegpatterns.anything
local endofstring = lpegpatterns.endofstring

local nobrace     = 1 - (lbrace   + rbrace )
local noparent    = 1 - (lparent  + rparent)
local nobracket   = 1 - (lbracket + rbracket)

-- we could use a Cf Cg construct

local escape, left, right = P("\\"), P('{'), P('}')

-- lpegpatterns.balanced = P {
--     [1] = ((escape * (left+right)) + (1 - (left+right)) + V(2))^0,
--     [2] = left * V(1) * right
-- }
lpegpatterns.balanced = P {
    ((escape * (left+right)) + (1 - (left+right)) + V(2))^0,
    left * V(1) * right
}

local nestedbraces   = P { lbrace   * (nobrace   + V(1))^0 * rbrace }
local nestedparents  = P { lparent  * (noparent  + V(1))^0 * rparent }
local nestedbrackets = P { lbracket * (nobracket + V(1))^0 * rbracket }
local spaces         = space^0
local argument       = Cs((lbrace/"") * ((nobrace + nestedbraces)^0) * (rbrace/""))
local content        = (1-endofstring)^0

lpegpatterns.nestedbraces   = nestedbraces   -- no capture
lpegpatterns.nestedparents  = nestedparents  -- no capture
lpegpatterns.nestedbrackets = nestedbrackets -- no capture
lpegpatterns.nested         = nestedbraces   -- no capture
lpegpatterns.argument       = argument       -- argument after e.g. =
lpegpatterns.content        = content        -- rest after e.g =

local value     = lbrace * C((nobrace + nestedbraces)^0) * rbrace
                + C((nestedbraces + (1-comma))^0)

local key       = C((1-equal-comma)^1)
local pattern_a = (space+comma)^0 * (key * equal * value + key * C(""))
local pattern_c = (space+comma)^0 * (key * equal * value)
local pattern_d = (space+comma)^0 * (key * (equal+colon) * value + key * C(""))

local key       = C((1-space-equal-comma)^1)
local pattern_b = spaces * comma^0 * spaces * (key * ((spaces * equal * spaces * value) + C("")))

-- "a=1, b=2, c=3, d={a{b,c}d}, e=12345, f=xx{a{b,c}d}xx, g={}" : outer {} removes, leading spaces ignored

local hash = { }

local function set(key,value)
    hash[key] = value
end

local pattern_a_s = (pattern_a/set)^1
local pattern_b_s = (pattern_b/set)^1
local pattern_c_s = (pattern_c/set)^1
local pattern_d_s = (pattern_d/set)^1

patterns.settings_to_hash_a = pattern_a_s
patterns.settings_to_hash_b = pattern_b_s
patterns.settings_to_hash_c = pattern_c_s
patterns.settings_to_hash_d = pattern_d_s

function parsers.make_settings_to_hash_pattern(set,how)
    if how == "strict" then
        return (pattern_c/set)^1
    elseif how == "tolerant" then
        return (pattern_b/set)^1
    else
        return (pattern_a/set)^1
    end
end

function parsers.settings_to_hash(str,existing)
    if not str or str == "" then
        return { }
    elseif type(str) == "table" then
        if existing then
            for k, v in next, str do
                existing[k] = v
            end
            return exiting
        else
            return str
        end
    else
        hash = existing or { }
        lpegmatch(pattern_a_s,str)
        return hash
    end
end

function parsers.settings_to_hash_colon_too(str)
    if not str or str == "" then
        return { }
    elseif type(str) == "table" then
        return str
    else
        hash = { }
        lpegmatch(pattern_d_s,str)
        return hash
    end
end

function parsers.settings_to_hash_tolerant(str,existing)
    if not str or str == "" then
        return { }
    elseif type(str) == "table" then
        if existing then
            for k, v in next, str do
                existing[k] = v
            end
            return exiting
        else
            return str
        end
    else
        hash = existing or { }
        lpegmatch(pattern_b_s,str)
        return hash
    end
end

function parsers.settings_to_hash_strict(str,existing)
    if not str or str == "" then
        return nil
    elseif type(str) == "table" then
        if existing then
            for k, v in next, str do
                existing[k] = v
            end
            return exiting
        else
            return str
        end
    elseif str and str ~= "" then
        hash = existing or { }
        lpegmatch(pattern_c_s,str)
        return next(hash) and hash
    end
end

local separator = comma * space^0
local value     = lbrace * C((nobrace + nestedbraces)^0) * rbrace
                + C((nestedbraces + (1-comma))^0)
local pattern   = spaces * Ct(value*(separator*value)^0)

-- "aap, {noot}, mies" : outer {} removed, leading spaces ignored

patterns.settings_to_array = pattern

-- we could use a weak table as cache

function parsers.settings_to_array(str,strict)
    if not str or str == "" then
        return { }
    elseif type(str) == "table" then
        return str
    elseif strict then
        if find(str,"{",1,true) then
            return lpegmatch(pattern,str)
        else
            return { str }
        end
    elseif find(str,",",1,true) then
        return lpegmatch(pattern,str)
    else
        return { str }
    end
end

function parsers.settings_to_numbers(str)
    if not str or str == "" then
        return { }
    end
    if type(str) == "table" then
        -- fall through
    elseif find(str,",",1,true) then
        str = lpegmatch(pattern,str)
    else
        return { tonumber(str) }
    end
    for i=1,#str do
        str[i] = tonumber(str[i])
    end
    return str
end

local value     = lbrace * C((nobrace + nestedbraces)^0) * rbrace
                + C((nestedbraces + nestedbrackets + nestedparents + (1-comma))^0)
local pattern   = spaces * Ct(value*(separator*value)^0)

function parsers.settings_to_array_obey_fences(str)
    return lpegmatch(pattern,str)
end

-- inspect(parsers.settings_to_array_obey_fences("url(http://a,b.c)"))

-- this one also strips end spaces before separators
--
-- "{123} , 456  " -> "123" "456"

-- local separator = space^0 * comma * space^0
-- local value     = P(lbrace * C((nobrace + nestedbraces)^0) * rbrace)
--                 + C((nestedbraces + (1-(space^0*(comma+P(-1)))))^0)
-- local withvalue = Carg(1) * value / function(f,s) return f(s) end
-- local pattern_a = spaces * Ct(value*(separator*value)^0)
-- local pattern_b = spaces * withvalue * (separator*withvalue)^0

local cache_a = { }
local cache_b = { }

function parsers.groupedsplitat(symbol,withaction)
    if not symbol then
        symbol = ","
    end
    local pattern = (withaction and cache_b or cache_a)[symbol]
    if not pattern then
        local symbols   = S(symbol)
        local separator = space^0 * symbols * space^0
        local value     =
                        lbrace
                        * C((nobrace + nestedbraces)^0)
                     -- * rbrace
                        * (rbrace * (#symbols + P(-1))) -- new per 2023-03-11
                        +
                        C((nestedbraces + (1-(space^0*(symbols+P(-1)))))^0)
        if withaction then
            local withvalue = Carg(1) * value / function(f,s) return f(s) end
            pattern = spaces * withvalue * (separator*withvalue)^0
            cache_b[symbol] = pattern
        else
            pattern = spaces * Ct(value*(separator*value)^0)
            cache_a[symbol] = pattern
        end
    end
    return pattern
end

local pattern_a = parsers.groupedsplitat(",",false)
local pattern_b = parsers.groupedsplitat(",",true)

function parsers.stripped_settings_to_array(str)
    if not str or str == "" then
        return { }
    else
        return lpegmatch(pattern_a,str)
    end
end

function parsers.process_stripped_settings(str,action)
    if not str or str == "" then
        return { }
    else
        return lpegmatch(pattern_b,str,1,action)
    end
end

-- parsers.process_stripped_settings("{123} , 456  ",function(s) print("["..s.."]") end)
-- parsers.process_stripped_settings("123 , 456  ",function(s) print("["..s.."]") end)

local function set(t,v)
    t[#t+1] = v
end

local value   = P(Carg(1)*value) / set
local pattern = value*(separator*value)^0 * Carg(1)

function parsers.add_settings_to_array(t,str)
    return lpegmatch(pattern,str,nil,t)
end

function parsers.hash_to_string(h,separator,yes,no,strict,omit)
    if h then
        local t  = { }
        local tn = 0
        local s  = sortedkeys(h)
        omit = omit and tohash(omit)
        for i=1,#s do
            local key = s[i]
            if not omit or not omit[key] then
                local value = h[key]
                if type(value) == "boolean" then
                    if yes and no then
                        if value then
                            tn = tn + 1
                            t[tn] = key .. '=' .. yes
                        elseif not strict then
                            tn = tn + 1
                            t[tn] = key .. '=' .. no
                        end
                    elseif value or not strict then
                        tn = tn + 1
                        t[tn] = key .. '=' .. tostring(value)
                    end
                else
                    tn = tn + 1
                    t[tn] = key .. '=' .. value
                end
            end
        end
        return concat(t,separator or ",")
    else
        return ""
    end
end

function parsers.array_to_string(a,separator)
    if a then
        return concat(a,separator or ",")
    else
        return ""
    end
end

-- function parsers.settings_to_set(str,t) -- tohash? -- todo: lpeg -- duplicate anyway
--     if str then
--         t = t or { }
--         for s in gmatch(str,"[^, ]+") do -- space added
--             t[s] = true
--         end
--         return t
--     else
--         return { }
--     end
-- end

local pattern = Cf(Ct("") * Cg(C((1-S(", "))^1) * S(", ")^0 * Cc(true))^1,rawset)

function parsers.settings_to_set(str)
    return str and lpegmatch(pattern,str) or { }
end

hashes.settings_to_set =  table.setmetatableindex(function(t,k) -- experiment, not public
    local v = k and lpegmatch(pattern,k) or { }
    t[k] = v
    return v
end)

function parsers.settings_to_set(str)
    return str and lpegmatch(pattern,str) or { }
end

local pattern = Ct((C((1-S(", "))^1) * S(", ")^0)^1)

hashes.settings_to_list =  table.setmetatableindex(function(t,k) -- experiment, not public
    local v = k and lpegmatch(pattern,k) or { }
    t[k] = v
    return v
end)

-- inspect(hashes.settings_to_set["a,b, c, d"])
-- inspect(hashes.settings_to_list["a,b, c, d"])

-- as we use a next, we are not sure when the gc kicks in

getmetatable(hashes.settings_to_set ).__mode = "kv" -- could be an option (maybe sharing makes sense)
getmetatable(hashes.settings_to_list).__mode = "kv" -- could be an option (maybe sharing makes sense)

function parsers.simple_hash_to_string(h, separator)
    local t  = { }
    local tn = 0
    for k, v in sortedhash(h) do
        if v then
            tn = tn + 1
            t[tn] = k
        end
    end
    return concat(t,separator or ",")
end

-- for mtx-context etc: aaaa bbbb cccc=dddd eeee=ffff

local str      = Cs(lpegpatterns.unquoted) + C((1-whitespace-equal)^1)
local setting  = Cf( Carg(1) * (whitespace^0 * Cg(str * whitespace^0 * (equal * whitespace^0 * str + Cc(""))))^1,rawset)
local splitter = setting^1

function parsers.options_to_hash(str,target)
    return str and lpegmatch(splitter,str,1,target or { }) or { }
end

local splitter = lpeg.tsplitat(" ")

function parsers.options_to_array(str)
    return str and lpegmatch(splitter,str) or { }
end

-- for chem (currently one level)

local value     = P(lbrace * C((nobrace + nestedbraces)^0) * rbrace)
                + C(digit^1 * lparent * (noparent + nestedparents)^1 * rparent)
                + C((nestedbraces + (1-comma))^1)
local pattern_a = spaces * Ct(value*(separator*value)^0)

local function repeater(n,str)
    if not n then
        return str
    else
        local s = lpegmatch(pattern_a,str)
        if n == 1 then
            return unpack(s)
        else
            local t  = { }
            local tn = 0
            for i=1,n do
                for j=1,#s do
                    tn = tn + 1
                    t[tn] = s[j]
                end
            end
            return unpack(t)
        end
    end
end

local value     = P(lbrace * C((nobrace + nestedbraces)^0) * rbrace)
                + (C(digit^1)/tonumber * lparent * Cs((noparent + nestedparents)^1) * rparent) / repeater
                + C((nestedbraces + (1-comma))^1)
local pattern_b = spaces * Ct(value*(separator*value)^0)

function parsers.settings_to_array_with_repeat(str,expand) -- beware: "" =>  { }
    if expand then
        return lpegmatch(pattern_b,str) or { }
    else
        return lpegmatch(pattern_a,str) or { }
    end
end

--

local value   = lbrace * C((nobrace + nestedbraces)^0) * rbrace
local pattern = Ct((space + value)^0)

function parsers.arguments_to_table(str)
    return lpegmatch(pattern,str)
end

-- temporary here (unoptimized)

function parsers.getparameters(self,class,parentclass,settings)
    local sc = self[class]
    if not sc then
        sc = { }
        self[class] = sc
        if parentclass then
            local sp = self[parentclass]
            if not sp then
                sp = { }
                self[parentclass] = sp
            end
            setmetatableindex(sc,sp)
        end
    end
    parsers.settings_to_hash(settings,sc)
end

function parsers.listitem(str)
    return gmatch(str,"[^, ]+")
end

--

local pattern = Cs { "start",
    start    = V("one") + V("two") + V("three"),
    rest     = (Cc(",") * V("thousand"))^0 * (P(".") + endofstring) * anything^0,
    thousand = digit * digit * digit,
    one      = digit * V("rest"),
    two      = digit * digit * V("rest"),
    three    = V("thousand") * V("rest"),
}

lpegpatterns.splitthousands = pattern -- maybe better in the parsers namespace ?

function parsers.splitthousands(str)
    return lpegmatch(pattern,str) or str
end

-- print(parsers.splitthousands("11111111111.11"))

local optionalwhitespace = whitespace^0

lpegpatterns.words      = Ct((Cs((1-punctuation-whitespace)^1) + anything)^1)
lpegpatterns.sentences  = Ct((optionalwhitespace * Cs((1-period)^0 * period))^1)
lpegpatterns.paragraphs = Ct((optionalwhitespace * Cs((whitespace^1*endofstring/"" + 1 - (spacer^0*newline*newline))^1))^1)

-- local str = " Word1 word2. \n Word3 word4. \n\n Word5 word6.\n "
-- inspect(lpegmatch(lpegpatterns.paragraphs,str))
-- inspect(lpegmatch(lpegpatterns.sentences,str))
-- inspect(lpegmatch(lpegpatterns.words,str))

-- handy for k="v" [, ] k="v"

local dquote    = P('"')
local equal     = P('=')
local escape    = P('\\')
local separator = S(' ,')

local key       = C((1-equal)^1)
local value     = dquote * C((1-dquote-escape*dquote)^0) * dquote

----- pattern   = Cf(Ct("") * Cg(key * equal * value) * separator^0,rawset)^0 * P(-1) -- was wrong
local pattern   = Cf(Ct("") * (Cg(key * equal * value) * separator^0)^1,rawset)^0 * P(-1)

function parsers.keq_to_hash(str)
    if str and str ~= "" then
        return lpegmatch(pattern,str)
    else
        return { }
    end
end

-- inspect(lpeg.match(pattern,[[key="value" foo="bar"]]))

local defaultspecification = { separator = ",", quote = '"' }

-- this version accepts multiple separators and quotes as used in the
-- database module

function parsers.csvsplitter(specification)
    specification   = specification and setmetatableindex(specification,defaultspecification) or defaultspecification
    local separator = specification.separator
    local quotechar = specification.quote
    local numbers   = specification.numbers
    local separator = S(separator ~= "" and separator or ",")
    local whatever  = C((1 - separator - newline)^0)
    if quotechar and quotechar ~= "" then
        local quotedata = nil
        for chr in gmatch(quotechar,".") do
            local quotechar = P(chr)
            local quoteitem = (1 - quotechar)^0
            local quoteword = quotechar * (numbers and (quoteitem/tonumber) or C(quoteitem)) * quotechar
            if quotedata then
                quotedata = quotedata + quoteword
            else
                quotedata = quoteword
            end
        end
        whatever = quotedata + whatever
    end
    local parser = Ct((Ct(whatever * (separator * whatever)^0) * S("\n\r")^1)^0 )
    return function(data)
        return lpegmatch(parser,data)
    end
end

-- local crap = [[
-- first,second,third,fourth
-- "1","2","3","4"
-- "5","6","7","8"
-- ]]

-- local mycsvsplitter = parsers.csvsplitter { numbers = true }

-- local list = mycsvsplitter(crap) inspect(list)

-- and this is a slightly patched version of a version posted by Philipp Gesang

function parsers.rfc4180splitter(specification)
    specification     = specification and setmetatableindex(specification,defaultspecification) or defaultspecification
    local numbers     = specification.numbers
    local separator   = specification.separator --> rfc: COMMA
    local quotechar   = P(specification.quote)  -->      DQUOTE
    local dquotechar  = quotechar * quotechar   -->      2DQUOTE
                      / specification.quote
    local separator   = S(separator ~= "" and separator or ",")
    local whatever    = (dquotechar + (1 - quotechar))^0
    local escaped     = quotechar
                      * (numbers and (whatever/tonumber) or Cs(whatever))
                      * quotechar
    local non_escaped = C((1 - quotechar - newline - separator)^1)
    local field       = escaped + non_escaped + Cc("")
    local record      = Ct(field * (separator * field)^1)
    local headerline  = record * Cp()
    local morerecords = (newline^(specification.strict and -1 or 1) * record)^0
    local headeryes   = Ct(morerecords)
    local headernop   = Ct(record * morerecords)
    return function(data,getheader)
        if getheader then
            local header, position = lpegmatch(headerline,data)
            local data = lpegmatch(headeryes,data,position)
            return data, header
        else
            return lpegmatch(headernop,data)
        end
    end
end

-- local mycsvsplitter = parsers.rfc4180splitter { numbers = true }
--
-- local crap = [[
-- first,second,third,fourth
-- "1","2","3","4"
-- "a","b","c","d"
-- "foo","bar""baz","boogie","xyzzy"
-- ]]
--
-- local list, names = mycsvsplitter(crap,true)   inspect(list) inspect(names)
-- local list, names = mycsvsplitter(crap)        inspect(list) inspect(names)

local function ranger(first,last,n,action)
    if not first then
        -- forget about it
    elseif last == true then
        for i=first,n or first do
            action(i)
        end
    elseif last then
        for i=first,last do
            action(i)
        end
    else
        action(first)
    end
end

local cardinal    = (lpegpatterns.hexadecimal + lpegpatterns.cardinal) / tonumber
local spacers     = lpegpatterns.spacer^0
local endofstring = lpegpatterns.endofstring

local stepper  = spacers * ( cardinal * ( spacers * S(":-") * spacers * ( cardinal + Cc(true) ) + Cc(false) )
               * Carg(1) * Carg(2) / ranger * S(", ")^0 )^1

local stepper  = spacers * ( cardinal * ( spacers * S(":-") * spacers * ( cardinal + (P("*") + endofstring) * Cc(true) ) + Cc(false) )
               * Carg(1) * Carg(2) / ranger * S(", ")^0 )^1 * endofstring -- we're sort of strict (could do without endofstring)

function parsers.stepper(str,n,action)
    local ts = type(str)
    if type(n) == "function" then
        if ts == "number" then
            n(str)
        elseif ts == "table" then
            for i=1,#str do
                n(str[i])
            end
        else
            lpegmatch(stepper,str,1,false,n or print)
        end
    elseif ts == "string" then
        lpegmatch(stepper,str,1,n,action or print)
    end
end

-- parsers.stepper("1,7-",9,function(i) print(">>>",i) end)
-- parsers.stepper("1-3,7,8,9")
-- parsers.stepper("1-3,6,7",function(i) print(">>>",i) end)
-- parsers.stepper(" 1 : 3, ,7 ")
-- parsers.stepper("1:4,9:13,24:*",30)
-- parsers.stepper(1,print)
-- parsers.stepper({1,3,4},print)

local pattern_math = Cs((P("%")/"\\percent " +  P("^")           * Cc("{") * lpegpatterns.integer * Cc("}") + anything)^0)
local pattern_text = Cs((P("%")/"\\percent " + (P("^")/"\\high") * Cc("{") * lpegpatterns.integer * Cc("}") + anything)^0)

patterns.unittotex = pattern

function parsers.unittotex(str,textmode)
    return lpegmatch(textmode and pattern_text or pattern_math,str)
end

local pattern = Cs((P("^") / "<sup>" * lpegpatterns.integer * Cc("</sup>") + anything)^0)

function parsers.unittoxml(str)
    return lpegmatch(pattern,str)
end

-- print(parsers.unittotex("10^-32 %"),utilities.parsers.unittoxml("10^32 %"))

local cache   = { }
local spaces  = lpegpatterns.space^0
local dummy   = function() end

setmetatableindex(cache,function(t,k)
    local separator = S(k) -- was P
    local value     = (1-separator)^0
    local pattern   = spaces * C(value) * separator^0 * Cp()
    t[k] = pattern
    return pattern
end)

local commalistiterator = cache[","]

function parsers.iterator(str,separator)
    local n = #str
    if n == 0 then
        return dummy
    else
        local pattern = separator and cache[separator] or commalistiterator
        local p = 1
        return function()
            if p <= n then
                local s, e = lpegmatch(pattern,str,p)
                if e then
                    p = e
                    return s
                end
            end
        end
    end
end

-- for s in parsers.iterator("a b c,b,c") do
--     print(s)
-- end

local function initialize(t,name)
    local source = t[name]
    if source then
        local result = { }
        for k, v in next, t[name] do
            result[k] = v
        end
        return result
    else
        return { }
    end
end

local function fetch(t,name)
    return t[name] or { }
end

local function process(result,more)
    for k, v in next, more do
        result[k] = v
    end
    return result
end

local name   = C((1-S(", "))^1)
local parser = (Carg(1) * name / initialize) * (S(", ")^1 * (Carg(1) * name / fetch))^0
local merge  = Cf(parser,process)

function parsers.mergehashes(hash,list)
    return lpegmatch(merge,list,1,hash)
end

-- local t = {
--     aa = { alpha = 1, beta = 2, gamma = 3, },
--     bb = { alpha = 4, beta = 5, delta = 6, },
--     cc = { epsilon = 3 },
-- }
--
-- inspect(parsers.mergehashes(t,"aa, bb, cc"))

function parsers.runtime(time)
    if not time then
        time = os.runtime()
    end
    local days = div(time,24*60*60)
    time = mod(time,24*60*60)
    local hours = div(time,60*60)
    time = mod(time,60*60)
    local minutes = div(time,60)
    local seconds = mod(time,60)
    return days, hours, minutes, seconds
end

--

local spacing = whitespace^0
local apply   = P("->")
local method  = C((1-apply)^1)
local token   = lbrace * C((1-rbrace)^1) * rbrace + C(anything^1)

local pattern = spacing * (method * spacing * apply + Carg(1)) * spacing * token

function parsers.splitmethod(str,default)
    if str then
        return lpegmatch(pattern,str,1,default or false)
    else
        return default or false, ""
    end
end

-- print(parsers.splitmethod(" foo -> {bar} "))
-- print(parsers.splitmethod("foo->{bar}"))
-- print(parsers.splitmethod("foo->bar"))
-- print(parsers.splitmethod("foo"))
-- print(parsers.splitmethod("{foo}"))
-- print(parsers.splitmethod())

local p_year = lpegpatterns.digit^4 / tonumber

local pattern = Cf( Ct("") *
    (
        (              Cg(Cc("year")  * p_year)
          *  S("-/") * Cg(Cc("month") * cardinal)
          *  S("-/") * Cg(Cc("day")   * cardinal)
        ) +
        (              Cg(Cc("day")   * cardinal)
          *  S("-/") * Cg(Cc("month") * cardinal)
          *  S("-/") * Cg(Cc("year")  * p_year)
        ) +
        (              Cg(Cc("year")  * p_year)
          *  S("-/") * Cg(Cc("month") * cardinal)
        ) +
        (              Cg(Cc("month")  * cardinal)
          *  S("-/") * Cg(Cc("year")   * p_year)
        )
    )
      *  (
         P(" ")  * Cg(Cc("hour")   * cardinal)
      *  P(":")  * Cg(Cc("min")    * cardinal)
      * (P(":")  * Cg(Cc("sec")    * cardinal))^-1
      + P(-1) )

, rawset)

lpegpatterns.splittime = pattern

function parsers.totime(str)
    return lpegmatch(pattern,str)
end

-- inspect(parsers.totime("2019-03-05"))
-- inspect(parsers.totime("2019-03-05 12:12:12"))
-- print(os.time(parsers.totime("2019-03-05 12:12:12")))
-- print(os.time(parsers.totime("2019/03/05 12:12:12")))
-- print(os.time(parsers.totime("05-03-2019 12:12:12")))
-- print(os.time(parsers.totime("05/03/2019 12:12:12")))
