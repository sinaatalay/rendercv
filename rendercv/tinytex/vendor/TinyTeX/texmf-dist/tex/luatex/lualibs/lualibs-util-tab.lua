if not modules then modules = { } end modules ['util-tab'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

utilities        = utilities or {}
utilities.tables = utilities.tables or { }
local tables     = utilities.tables

local format, gmatch, gsub, sub = string.format, string.gmatch, string.gsub, string.sub
local concat, insert, remove, sort = table.concat, table.insert, table.remove, table.sort
local setmetatable, getmetatable, tonumber, tostring, rawget = setmetatable, getmetatable, tonumber, tostring, rawget
local type, next, rawset, tonumber, tostring, load, select = type, next, rawset, tonumber, tostring, load, select
local lpegmatch, P, Cs, Cc = lpeg.match, lpeg.P, lpeg.Cs, lpeg.Cc
local sortedkeys, sortedpairs = table.sortedkeys, table.sortedpairs
local formatters = string.formatters
local utftoeight = utf.toeight

local splitter = lpeg.tsplitat(".")

function utilities.tables.definetable(target,nofirst,nolast) -- defines undefined tables
    local composed = nil
    local t        = { }
    local snippets = lpegmatch(splitter,target)
    for i=1,#snippets - (nolast and 1 or 0) do
        local name = snippets[i]
        if composed then
            composed = composed .. "." .. name
                t[#t+1] = formatters["if not %s then %s = { } end"](composed,composed)
        else
            composed = name
            if not nofirst then
                t[#t+1] = formatters["%s = %s or { }"](composed,composed)
            end
        end
    end
    if composed then
        if nolast then
            composed = composed .. "." .. snippets[#snippets]
        end
        return concat(t,"\n"), composed -- could be shortcut
    else
        return "", target
    end
end

-- local t = tables.definedtable("a","b","c","d")

function tables.definedtable(...)
    local t = _G
    for i=1,select("#",...) do
        local li = select(i,...)
        local tl = t[li]
        if not tl then
            tl = { }
            t[li] = tl
        end
        t = tl
    end
    return t
end

function tables.accesstable(target,root)
    local t = root or _G
    for name in gmatch(target,"([^%.]+)") do
        t = t[name]
        if not t then
            return
        end
    end
    return t
end

function tables.migratetable(target,v,root)
    local t = root or _G
    local names = lpegmatch(splitter,target)
    for i=1,#names-1 do
        local name = names[i]
        t[name] = t[name] or { }
        t = t[name]
        if not t then
            return
        end
    end
    t[names[#names]] = v
end

function tables.removevalue(t,value) -- todo: n
    if value then
        for i=1,#t do
            if t[i] == value then
                remove(t,i)
                -- remove all, so no: return
            end
        end
    end
end

function tables.replacevalue(t,oldvalue,newvalue)
    if oldvalue and newvalue then
        for i=1,#t do
            if t[i] == oldvalue then
                t[i] = newvalue
                -- replace all, so no: return
            end
        end
    end
end

function tables.insertbeforevalue(t,value,extra)
    for i=1,#t do
        if t[i] == extra then
            remove(t,i)
        end
    end
    for i=1,#t do
        if t[i] == value then
            insert(t,i,extra)
            return
        end
    end
    insert(t,1,extra)
end

function tables.insertaftervalue(t,value,extra)
    for i=1,#t do
        if t[i] == extra then
            remove(t,i)
        end
    end
    for i=1,#t do
        if t[i] == value then
            insert(t,i+1,extra)
            return
        end
    end
    insert(t,#t+1,extra)
end

-- experimental

local escape = Cs(Cc('"') * ((P('"')/'""' + P(1))^0) * Cc('"'))

function table.tocsv(t,specification)
    if t and #t > 0 then
        local result = { }
        local r = { }
        specification = specification or { }
        local fields = specification.fields
        if type(fields) ~= "string" then
            fields = sortedkeys(t[1])
        end
        local separator = specification.separator or ","
        local noffields = #fields
        if specification.preamble == true then
            for f=1,noffields do
                r[f] = lpegmatch(escape,tostring(fields[f]))
            end
            result[1] = concat(r,separator)
        end
        for i=1,#t do
            local ti = t[i]
            for f=1,noffields do
                local field = ti[fields[f]]
                if type(field) == "string" then
                    r[f] = lpegmatch(escape,field)
                else
                    r[f] = tostring(field)
                end
            end
         -- result[#result+1] = concat(r,separator)
            result[i+1] = concat(r,separator)
        end
        return concat(result,"\n")
    else
        return ""
    end
end

-- local nspaces = utilities.strings.newrepeater(" ")
-- local escape  = Cs((P("<")/"&lt;" + P(">")/"&gt;" + P("&")/"&amp;" + P(1))^0)
--
-- local function toxml(t,d,result,step)
--     for k, v in sortedpairs(t) do
--         local s = nspaces[d]
--         local tk = type(k)
--         local tv = type(v)
--         if tv == "table" then
--             if tk == "number" then
--                 result[#result+1] = format("%s<entry n='%s'>",s,k)
--                 toxml(v,d+step,result,step)
--                 result[#result+1] = format("%s</entry>",s,k)
--             else
--                 result[#result+1] = format("%s<%s>",s,k)
--                 toxml(v,d+step,result,step)
--                 result[#result+1] = format("%s</%s>",s,k)
--             end
--         elseif tv == "string" then
--             if tk == "number" then
--                 result[#result+1] = format("%s<entry n='%s'>%s</entry>",s,k,lpegmatch(escape,v),k)
--             else
--                 result[#result+1] = format("%s<%s>%s</%s>",s,k,lpegmatch(escape,v),k)
--             end
--         elseif tk == "number" then
--             result[#result+1] = format("%s<entry n='%s'>%s</entry>",s,k,tostring(v),k)
--         else
--             result[#result+1] = format("%s<%s>%s</%s>",s,k,tostring(v),k)
--         end
--     end
-- end
--
-- much faster

local nspaces = utilities.strings.newrepeater(" ")

local function toxml(t,d,result,step)
    local r = #result
    for k, v in sortedpairs(t) do
        local s = nspaces[d] -- inlining this is somewhat faster but gives more formatters
        local tk = type(k)
        local tv = type(v)
        if tv == "table" then
            if tk == "number" then
                r = r + 1 result[r] = formatters["%s<entry n='%s'>"](s,k)
                toxml(v,d+step,result,step)
                r = r + 1 result[r] = formatters["%s</entry>"](s,k)
            else
                r = r + 1 result[r] = formatters["%s<%s>"](s,k)
                toxml(v,d+step,result,step)
                r = r + 1 result[r] = formatters["%s</%s>"](s,k)
            end
        elseif tv == "string" then
            if tk == "number" then
                r = r + 1 result[r] = formatters["%s<entry n='%s'>%!xml!</entry>"](s,k,v,k)
            else
                r = r + 1 result[r] = formatters["%s<%s>%!xml!</%s>"](s,k,v,k)
            end
        elseif tk == "number" then
            r = r + 1 result[r] = formatters["%s<entry n='%s'>%S</entry>"](s,k,v,k)
        else
            r = r + 1 result[r] = formatters["%s<%s>%S</%s>"](s,k,v,k)
        end
    end
end

-- function table.toxml(t,name,nobanner,indent,spaces)
--     local noroot = name == false
--     local result = (nobanner or noroot) and { } or { "<?xml version='1.0' standalone='yes' ?>" }
--     local indent = rep(" ",indent or 0)
--     local spaces = rep(" ",spaces or 1)
--     if noroot then
--         toxml( t, inndent, result, spaces)
--     else
--         toxml( { [name or "root"] = t }, indent, result, spaces)
--     end
--     return concat(result,"\n")
-- end

function table.toxml(t,specification)
    specification = specification or { }
    local name   = specification.name
    local noroot = name == false
    local result = (specification.nobanner or noroot) and { } or { "<?xml version='1.0' standalone='yes' ?>" }
    local indent = specification.indent or 0
    local spaces = specification.spaces or 1
    if noroot then
        toxml( t, indent, result, spaces)
    else
        toxml( { [name or "data"] = t }, indent, result, spaces)
    end
    return concat(result,"\n")
end

-- also experimental

-- encapsulate(table,utilities.tables)
-- encapsulate(table,utilities.tables,true)
-- encapsulate(table,true)

function tables.encapsulate(core,capsule,protect)
    if type(capsule) ~= "table" then
        protect = true
        capsule = { }
    end
    for key, value in next, core do
        if capsule[key] then
            print(formatters["\ninvalid %s %a in %a"]("inheritance",key,core))
            os.exit()
        else
            capsule[key] = value
        end
    end
    if protect then
        for key, value in next, core do
            core[key] = nil
        end
        setmetatable(core, {
            __index = capsule,
            __newindex = function(t,key,value)
                if capsule[key] then
                    print(formatters["\ninvalid %s %a' in %a"]("overload",key,core))
                    os.exit()
                else
                    rawset(t,key,value)
                end
            end
        } )
    end
end

-- best keep [%q] keys (as we have some in older applications i.e. saving user data (otherwise
-- we also need to check for reserved words)

if JITSUPPORTED then

    local f_hashed_string   = formatters["[%Q]=%Q,"]
    local f_hashed_number   = formatters["[%Q]=%s,"]
    local f_hashed_boolean  = formatters["[%Q]=%l,"]
    local f_hashed_table    = formatters["[%Q]="]

    local f_indexed_string  = formatters["[%s]=%Q,"]
    local f_indexed_number  = formatters["[%s]=%s,"]
    local f_indexed_boolean = formatters["[%s]=%l,"]
    local f_indexed_table   = formatters["[%s]="]

    local f_ordered_string  = formatters["%Q,"]
    local f_ordered_number  = formatters["%s,"]
    local f_ordered_boolean = formatters["%l,"]

    function table.fastserialize(t,prefix) -- todo, move local function out

        -- prefix should contain the =
        -- not sorted
        -- only number and string indices (currently)

        local r = { type(prefix) == "string" and prefix or "return" }
        local m = 1
        local function fastserialize(t,outer) -- no mixes
            local n = #t
            m = m + 1
            r[m] = "{"
            if n > 0 then
                local v = t[0]
                if v then
                    local tv = type(v)
                    if tv == "string" then
                        m = m + 1 r[m] = f_indexed_string(0,v)
                    elseif tv == "number" then
                        m = m + 1 r[m] = f_indexed_number(0,v)
                    elseif tv == "table" then
                        m = m + 1 r[m] = f_indexed_table(0)
                        fastserialize(v)
                        m = m + 1 r[m] = f_indexed_table(0)
                    elseif tv == "boolean" then
                        m = m + 1 r[m] = f_indexed_boolean(0,v)
                    end
                end
                for i=1,n do
                    local v  = t[i]
                    local tv = type(v)
                    if tv == "string" then
                        m = m + 1 r[m] = f_ordered_string(v)
                    elseif tv == "number" then
                        m = m + 1 r[m] = f_ordered_number(v)
                    elseif tv == "table" then
                        fastserialize(v)
                    elseif tv == "boolean" then
                        m = m + 1 r[m] = f_ordered_boolean(v)
                    end
                end
            end
            -- hm, can't we avoid this ... lua should have a way to check if there
            -- is a hash part
            for k, v in next, t do
                local tk = type(k)
                if tk == "number" then
                    if k > n or k < 0 then
                        local tv = type(v)
                        if tv == "string" then
                            m = m + 1 r[m] = f_indexed_string(k,v)
                        elseif tv == "number" then
                            m = m + 1 r[m] = f_indexed_number(k,v)
                        elseif tv == "table" then
                            m = m + 1 r[m] = f_indexed_table(k)
                            fastserialize(v)
                        elseif tv == "boolean" then
                            m = m + 1 r[m] = f_indexed_boolean(k,v)
                        end
                    end
                else
                    local tv = type(v)
                    if tv == "string" then
                        m = m + 1 r[m] = f_hashed_string(k,v)
                    elseif tv == "number" then
                        m = m + 1 r[m] = f_hashed_number(k,v)
                    elseif tv == "table" then
                        m = m + 1 r[m] = f_hashed_table(k)
                        fastserialize(v)
                    elseif tv == "boolean" then
                        m = m + 1 r[m] = f_hashed_boolean(k,v)
                    end
                end
            end
            m = m + 1
            if outer then
                r[m] = "}"
            else
                r[m] = "},"
            end
            return r
        end
        return concat(fastserialize(t,true))
    end

else

 -- local f_v = formatters["[%q]=%q,"]
 -- local f_t = formatters["[%q]="]
 -- local f_q = formatters["%q,"]

    function table.fastserialize(t,prefix) -- todo, move local function out
        local r = { type(prefix) == "string" and prefix or "return" }
        local m = 1
        local function fastserialize(t,outer) -- no mixes
            local n = #t
            m = m + 1
            r[m] = "{"
            if n > 0 then
                local v = t[0]
                if v then
                    m = m + 1
                    r[m] = "[0]="
                    if type(v) == "table" then
                        fastserialize(v)
                    else
                        r[m] = format("%q,",v)
                    end
                end
                for i=1,n do
                    local v = t[i]
                    m = m + 1
                    if type(v) == "table" then
                        r[m] = format("[%i]=",i)
                        fastserialize(v)
                    else
                        r[m] = format("[%i]=%q,",i,v)
                    end
                end
            end
            -- hm, can't we avoid this ... lua should have a way to check if there
            -- is a hash part
            for k, v in next, t do
                local tk = type(k)
                if tk == "number" then
                    if k > n or k < 0 then
                        m = m + 1
                        if type(v) == "table" then
                            r[m] = format("[%i]=",k)
                            fastserialize(v)
                        else
                            r[m] = format("[%i]=%q,",k,v)
                        end
                    end
                else
                    m = m + 1
                    if type(v) == "table" then
                        r[m] = format("[%q]=",k)
                        fastserialize(v)
                    else
                        r[m] = format("[%q]=%q,",k,v)
                    end
                end
            end
            m = m + 1
            if outer then
                r[m] = "}"
            else
                r[m] = "},"
            end
            return r
        end
        return concat(fastserialize(t,true))
    end

end

function table.deserialize(str)
    if not str or str == "" then
        return
    end
    local code = load(str)
    if not code then
        return
    end
    code = code()
    if not code then
        return
    end
    return code
end

-- inspect(table.fastserialize { a = 1, b = { [0]=4, { 5, 6 } }, c = { d = 7, e = 'f"g\nh' } })

function table.load(filename,loader)
    if filename then
        local t = (loader or io.loaddata)(filename)
        if t and t ~= "" then
            local t = utftoeight(t)
            t = load(t)
            if type(t) == "function" then
                t = t()
                if type(t) == "table" then
                    return t
                end
            end
        end
    end
end

function table.save(filename,t,n,...)
    io.savedata(filename,table.serialize(t,n == nil and true or n,...)) -- no frozen table.serialize
end

local f_key_value    = formatters["%s=%q"]
local f_add_table    = formatters[" {%t},\n"]
local f_return_table = formatters["return {\n%t}"]

local function slowdrop(t) -- maybe less memory (intermediate concat)
    local r = { }
    local l = { }
    for i=1,#t do
        local ti = t[i]
        local j = 0
        for k, v in next, ti do
            j = j + 1
            l[j] = f_key_value(k,v)
        end
        r[i] = f_add_table(l)
    end
    return f_return_table(r)
end

local function fastdrop(t)
    local r = { "return {\n" }
    local m = 1
    for i=1,#t do
        local ti = t[i]
        m = m + 1 r[m] = " {"
        for k, v in next, ti do
            m = m + 1 r[m] = f_key_value(k,v)
        end
        m = m + 1 r[m] = "},\n"
    end
    m = m + 1
    r[m] = "}"
    return concat(r)
end

function table.drop(t,slow) -- only { { a=2 }, {a=3} } -- for special cases
    if #t == 0 then
        return "return { }"
    elseif slow == true then
        return slowdrop(t) -- less memory
    else
        return fastdrop(t) -- some 15% faster
    end
end

-- inspect(table.drop({ { a=2 }, {a=3} }))
-- inspect(table.drop({ { a=2 }, {a=3} },true))

-- function table.autokey(t,k) -- replaced
--     local v = { }
--     t[k] = v
--     return v
-- end

local selfmapper = { __index = function(t,k) t[k] = k return k end }

function table.twowaymapper(t)    -- takes a 0/1 .. n indexed table and returns
    if not t then                 -- it with  string-numbers as indices + reverse
        t = { }                   -- mapping (all strings) .. used in cvs etc but
    else                          -- typically a helper that one forgets about
        local zero = rawget(t,0)  -- so it might move someplace else
        for i=zero and 0 or 1,#t do
            local ti = t[i]       -- t[1]     = "one"
            if ti then
                local i = tostring(i)
                t[i]    = ti      -- t["1"]   = "one"
                t[ti]   = i       -- t["one"] = "1"
            end
        end
    end
 -- setmetatableindex(t,"key")
    setmetatable(t,selfmapper)
    return t
end

-- The next version is somewhat faster, although in practice one will seldom
-- serialize a lot using this one. Often the above variants are more efficient.
-- If we would really need this a lot, we could hash q keys, or just not used
-- indented code.

-- char-def.lua : 0.53 -> 0.38
-- husayni.tma  : 0.28 -> 0.19

local f_start_key_idx     = formatters["%w{"]
local f_start_key_num     = JITSUPPORTED and formatters["%w[%s]={"] or formatters["%w[%q]={"]
local f_start_key_str     = formatters["%w[%q]={"]
local f_start_key_boo     = formatters["%w[%l]={"]
local f_start_key_nop     = formatters["%w{"]

local f_stop              = formatters["%w},"]

local f_key_num_value_num = JITSUPPORTED and formatters["%w[%s]=%s,"] or formatters["%w[%s]=%q,"]
local f_key_str_value_num = JITSUPPORTED and formatters["%w[%Q]=%s,"] or formatters["%w[%Q]=%q,"]
local f_key_boo_value_num = JITSUPPORTED and formatters["%w[%l]=%s,"] or formatters["%w[%l]=%q,"]

local f_key_num_value_str = JITSUPPORTED and formatters["%w[%s]=%Q,"] or formatters["%w[%q]=%Q,"]
local f_key_str_value_str = formatters["%w[%Q]=%Q,"]
local f_key_boo_value_str = formatters["%w[%l]=%Q,"]

local f_key_num_value_boo = JITSUPPORTED and formatters["%w[%s]=%l,"] or formatters["%w[%q]=%l,"]
local f_key_str_value_boo = formatters["%w[%Q]=%l,"]
local f_key_boo_value_boo = formatters["%w[%l]=%l,"]

local f_key_num_value_not = JITSUPPORTED and formatters["%w[%s]={},"] or formatters["%w[%q]={},"]
local f_key_str_value_not = formatters["%w[%Q]={},"]
local f_key_boo_value_not = formatters["%w[%l]={},"]

local f_key_num_value_seq = JITSUPPORTED and formatters["%w[%s]={ %, t },"] or formatters["%w[%q]={ %, t },"]
local f_key_str_value_seq = formatters["%w[%Q]={ %, t },"]
local f_key_boo_value_seq = formatters["%w[%l]={ %, t },"]

local f_val_num           = JITSUPPORTED and formatters["%w%s,"] or formatters["%w%q,"]
local f_val_str           = formatters["%w%Q,"]
local f_val_boo           = formatters["%w%l,"]
local f_val_not           = formatters["%w{},"]
local f_val_seq           = formatters["%w{ %, t },"]
local f_fin_seq           = formatters[" %, t }"]

local f_table_return      = formatters["return {"]
local f_table_name        = formatters["%s={"]
local f_table_direct      = formatters["{"]
local f_table_entry       = formatters["[%Q]={"]
local f_table_finish      = formatters["}"]

local spaces = utilities.strings.newrepeater(" ")

local original_serialize = table.serialize -- the extensive one, the one we started with

-- there is still room for optimization: index run, key run, but i need to check with the
-- latest lua for the value of #n (with holes) .. anyway for tracing purposes we want
-- indices / keys being sorted, so it will never be real fast

local is_simple_table = table.is_simple_table

-- local function is_simple_table(t)
--     local nt = #t
--     if nt > 0 then
--         local n = 0
--         for _, v in next, t do
--             n = n + 1
--             if type(v) == "table" then
--                 return nil
--             end
--         end
--      -- local haszero = t[0]
--         local haszero = rawget(t,0) -- don't trigger meta
--         if n == nt then
--             local tt = { }
--             for i=1,nt do
--                 local v = t[i]
--                 local tv = type(v)
--                 if tv == "number" then
--                     tt[i] = v -- not needed tostring(v)
--                 elseif tv == "string" then
--                     tt[i] = format("%q",v) -- f_string(v)
--                 elseif tv == "boolean" then
--                     tt[i] = v and "true" or "false"
--                 else
--                     return nil
--                 end
--             end
--             return tt
--         elseif haszero and (n == nt + 1) then
--             local tt = { }
--             for i=0,nt do
--                 local v = t[i]
--                 local tv = type(v)
--                 if tv == "number" then
--                     tt[i+1] = v -- not needed tostring(v)
--                 elseif tv == "string" then
--                     tt[i+1] = format("%q",v) -- f_string(v)
--                 elseif tv == "boolean" then
--                     tt[i+1] = v and "true" or "false"
--                 else
--                     return nil
--                 end
--             end
--             tt[1] = "[0] = " .. tt[1]
--             return tt
--         end
--     end
--     return nil
-- end

-- In order to overcome the luajit (65K constant) limitation I tried a split approach,
-- i.e. outputting the first level tables as locals but that failed with large cjk
-- fonts too so I removed that ... just use luatex instead.

local function serialize(root,name,specification)

    if type(specification) == "table" then
        return original_serialize(root,name,specification) -- the original one
    end

    local t    -- = { }
    local n       = 1
 -- local m       = 0 -- no gain
    local unknown = false

    local function do_serialize(root,name,depth,level,indexed)
        if level > 0 then
            n = n + 1
            if indexed then
                t[n] = f_start_key_idx(depth)
            else
                local tn = type(name)
                if tn == "number" then
                    t[n] = f_start_key_num(depth,name)
                elseif tn == "string" then
                    t[n] = f_start_key_str(depth,name)
                elseif tn == "boolean" then
                    t[n] = f_start_key_boo(depth,name)
                else
                    t[n] = f_start_key_nop(depth)
                end
            end
            depth = depth + 1
        end
        -- we could check for k (index) being number (cardinal)
        if root and next(root) ~= nil then
            local first = nil
            local last  = #root
            if last > 0 then
                for k=1,last do
                    if rawget(root,k) == nil then
                 -- if root[k] == nil then
                        last = k - 1
                        break
                    end
                end
                if last > 0 then
                    first = 1
                end
            end
            local sk = sortedkeys(root)
            for i=1,#sk do
                local k  = sk[i]
                local v  = root[k]
                local tv = type(v)
                local tk = type(k)
                if first and tk == "number" and k <= last and k >= first then
                    if tv == "number" then
                        n = n + 1 t[n] = f_val_num(depth,v)
                    elseif tv == "string" then
                        n = n + 1 t[n] = f_val_str(depth,v)
                    elseif tv == "table" then
                        if next(v) == nil then -- tricky as next is unpredictable in a hash
                            n = n + 1 t[n] = f_val_not(depth)
                        else
                            local st = is_simple_table(v)
                            if st then
                                n = n + 1 t[n] = f_val_seq(depth,st)
                            else
                                do_serialize(v,k,depth,level+1,true)
                            end
                        end
                    elseif tv == "boolean" then
                        n = n + 1 t[n] = f_val_boo(depth,v)
                    elseif unknown then
                        n = n + 1 t[n] = f_val_str(depth,tostring(v))
                    end
                elseif tv == "number" then
                    if tk == "number" then
                        n = n + 1 t[n] = f_key_num_value_num(depth,k,v)
                    elseif tk == "string" then
                        n = n + 1 t[n] = f_key_str_value_num(depth,k,v)
                    elseif tk == "boolean" then
                        n = n + 1 t[n] = f_key_boo_value_num(depth,k,v)
                    elseif unknown then
                        n = n + 1 t[n] = f_key_str_value_num(depth,tostring(k),v)
                    end
                elseif tv == "string" then
                    if tk == "number" then
                        n = n + 1 t[n] = f_key_num_value_str(depth,k,v)
                    elseif tk == "string" then
                        n = n + 1 t[n] = f_key_str_value_str(depth,k,v)
                    elseif tk == "boolean" then
                        n = n + 1 t[n] = f_key_boo_value_str(depth,k,v)
                    elseif unknown then
                        n = n + 1 t[n] = f_key_str_value_str(depth,tostring(k),v)
                    end
                elseif tv == "table" then
                    if next(v) == nil then
                        if tk == "number" then
                            n = n + 1 t[n] = f_key_num_value_not(depth,k)
                        elseif tk == "string" then
                            n = n + 1 t[n] = f_key_str_value_not(depth,k)
                        elseif tk == "boolean" then
                            n = n + 1 t[n] = f_key_boo_value_not(depth,k)
                        elseif unknown then
                            n = n + 1 t[n] = f_key_str_value_not(depth,tostring(k))
                        end
                    else
                        local st = is_simple_table(v)
                        if not st then
                            do_serialize(v,k,depth,level+1)
                        elseif tk == "number" then
                            n = n + 1 t[n] = f_key_num_value_seq(depth,k,st)
                        elseif tk == "string" then
                            n = n + 1 t[n] = f_key_str_value_seq(depth,k,st)
                        elseif tk == "boolean" then
                            n = n + 1 t[n] = f_key_boo_value_seq(depth,k,st)
                        elseif unknown then
                            n = n + 1 t[n] = f_key_str_value_seq(depth,tostring(k),st)
                        end
                    end
                elseif tv == "boolean" then
                    if tk == "number" then
                        n = n + 1 t[n] = f_key_num_value_boo(depth,k,v)
                    elseif tk == "string" then
                        n = n + 1 t[n] = f_key_str_value_boo(depth,k,v)
                    elseif tk == "boolean" then
                        n = n + 1 t[n] = f_key_boo_value_boo(depth,k,v)
                    elseif unknown then
                        n = n + 1 t[n] = f_key_str_value_boo(depth,tostring(k),v)
                    end
                else
                    if tk == "number" then
                        n = n + 1 t[n] = f_key_num_value_str(depth,k,tostring(v))
                    elseif tk == "string" then
                        n = n + 1 t[n] = f_key_str_value_str(depth,k,tostring(v))
                    elseif tk == "boolean" then
                        n = n + 1 t[n] = f_key_boo_value_str(depth,k,tostring(v))
                    elseif unknown then
                        n = n + 1 t[n] = f_key_str_value_str(depth,tostring(k),tostring(v))
                    end
                end
             -- if n > 100000 then -- no gain
             --     local k = m + 1
             --     t[k] = concat(t,"\n",k,n)
             --     n = k
             --     m = k
             -- end
            end
        end
        if level > 0 then
            n = n + 1 t[n] = f_stop(depth-1)
        end
    end

    local tname = type(name)

    if tname == "string" then
        if name == "return" then
            t = { f_table_return() }
        else
            t = { f_table_name(name) }
        end
    elseif tname == "number" then
        t = { f_table_entry(name) }
    elseif tname == "boolean" then
        if name then
            t = { f_table_return() }
        else
            t = { f_table_direct() }
        end
    else
        t = { f_table_name("t") }
    end

    if root then
        -- The dummy access will initialize a table that has a delayed initialization
        -- using a metatable. (maybe explicitly test for metatable). This can crash on
        -- metatables that check the index against a number.
        if getmetatable(root) then -- todo: make this an option, maybe even per subtable
            local dummy = root._w_h_a_t_e_v_e_r_ -- needed
            root._w_h_a_t_e_v_e_r_ = nil
        end
        -- Let's forget about empty tables.
        if next(root) ~= nil then
            local st = is_simple_table(root)
            if st then
                return t[1] .. f_fin_seq(st) -- todo: move up and in one go
            else
                do_serialize(root,name,1,0)
            end
        end
    end
    n = n + 1
    t[n] = f_table_finish()
    return concat(t,"\n")
 -- return concat(t,"\n",1,n) -- no gain
end

table.serialize = serialize

if setinspector then
    setinspector("table",function(v)
        if type(v) == "table" then
            print(serialize(v,"table",{ metacheck = false }))
            return true
        end
    end)
end

-- ordered hashes (for now here but in the table namespace):

-- local t = table.orderedhash()
--
-- t["1"]  = { "a", "b" }
-- t["2"]  = { }
-- t["2a"] = { "a", "c", "d" }
--
-- for k, v in table.ordered(t) do
--     ...
-- end

local mt = {
    __newindex = function(t,k,v)
        local n = t.last + 1
        t.last    = n
        t.list[n] = k
        t.hash[k] = v
    end,
    __index = function(t,k)
        return t.hash[k]
    end,
    __len = function(t)
        return t.last
    end,
}

function table.orderedhash()
    return setmetatable({ list = { }, hash = { }, last = 0 }, mt)
end

function table.ordered(t)
    local n = t.last
    if n > 0 then
        local l = t.list
        local i = 1
        local h = t.hash
        local f = function()
            if i <= n then
                local k = i
                local v = h[l[k]]
                i = i + 1
                return k, v
            end
        end
        return f, 1, h[l[1]]
    else
        return function() end
    end
end

-- function table.randomremove(t,n)
--     if not n then
--         n = #t
--     end
--     if n > 0 then
--         return remove(t,random(1,n))
--     end
-- end

function combine(target,source)
    -- no copy so if that is needed one needs to deepcopy source first
    if target then
        for k, v in next, source do
            if type(v) == "table" then
               target[k] = combine(target[k],source[k])
            else
               target[k] = v
            end
        end
        return target
    else
        return source
    end
end

table.combine = combine

-- If needed we can add something (some discussion on the list but I'm not sure if
-- it makes sense because merging such mixed tables is quite unusual.
--
-- function table.himerged(...)
--     local result = { }
--     local r      = 0
--     for i=1,select("#",...) do
--         local s = select(i,...)
--         if s then
--             for k, v in next, s do
--                 if type(k) == "number"  then
--                     r = r + 1
--                     result[r] = v
--                 else
--                     result[k] = v
--                 end
--             end
--         end
--     end
--     return result
-- end
