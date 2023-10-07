if not modules then modules = { } end modules ['l-table'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local type, next, tostring, tonumber, select, rawget = type, next, tostring, tonumber, select, rawget
local table, string = table, string
local concat, sort = table.concat, table.sort
local format, lower, dump = string.format, string.lower, string.dump
local getmetatable, setmetatable = getmetatable, setmetatable
local lpegmatch, patterns = lpeg.match, lpeg.patterns
local floor = math.floor

-- extra functions, some might go (when not used)
--
-- we could serialize using %a but that won't work well is in the code we mostly use
-- floats and as such we get unequality e.g. in version comparisons

local stripper = patterns.stripper

function table.getn(t)
    return t and #t -- for very old times sake
end

function table.strip(tab)
    local lst = { }
    local l   = 0
    for i=1,#tab do
        local s = lpegmatch(stripper,tab[i]) or ""
        if s == "" then
            -- skip this one
        else
            l = l + 1
            lst[l] = s
        end
    end
    return lst
end

function table.keys(t)
    if t then
        local keys = { }
        local k    = 0
        for key in next, t do
            k = k + 1
            keys[k] = key
        end
        return keys
    else
        return { }
    end
end

-- local function compare(a,b)
--     local ta = type(a) -- needed, else 11 < 2
--     local tb = type(b) -- needed, else 11 < 2
--     if ta == tb and ta == "number" then
--         return a < b
--     else
--         return tostring(a) < tostring(b) -- not that efficient
--     end
-- end

-- local function compare(a,b)
--     local ta = type(a) -- needed, else 11 < 2
--     local tb = type(b) -- needed, else 11 < 2
--     if ta == tb and (ta == "number" or ta == "string") then
--         return a < b
--     else
--         return tostring(a) < tostring(b) -- not that efficient
--     end
-- end

-- local function sortedkeys(tab)
--     if tab then
--         local srt, category, s = { }, 0, 0 -- 0=unknown 1=string, 2=number 3=mixed
--         for key in next, tab do
--             s = s + 1
--             srt[s] = key
--             if category == 3 then
--                 -- no further check
--             else
--                 local tkey = type(key)
--                 if tkey == "string" then
--                     category = (category == 2 and 3) or 1
--                 elseif tkey == "number" then
--                     category = (category == 1 and 3) or 2
--                 else
--                     category = 3
--                 end
--             end
--         end
--         if category == 0 or category == 3 then
--             sort(srt,compare)
--         else
--             sort(srt)
--         end
--         return srt
--     else
--         return { }
--     end
-- end

-- local function compare(a,b)
--     local ta = type(a) -- needed, else 11 < 2
--     local tb = type(b) -- needed, else 11 < 2
--     if ta == tb and (ta == "number" or ta == "string") then
--         return a < b
--     else
--         return tostring(a) < tostring(b) -- not that efficient
--     end
-- end

-- local function compare(a,b)
--     local ta = type(a) -- needed, else 11 < 2
--     if ta == "number" or ta == "string" then
--         local tb = type(b) -- needed, else 11 < 2
--         if ta == tb then
--             return a < b
--         end
--     end
--     return tostring(a) < tostring(b) -- not that efficient
-- end

local function compare(a,b)
    local ta = type(a) -- needed, else 11 < 2
    if ta == "number" then
        local tb = type(b) -- needed, else 11 < 2
        if ta == tb then
            return a < b
        elseif tb == "string" then
            return tostring(a) < b
        end
    elseif ta == "string" then
        local tb = type(b) -- needed, else 11 < 2
        if ta == tb then
            return a < b
        else
            return a < tostring(b)
        end
    end
    return tostring(a) < tostring(b) -- not that efficient
end

local function sortedkeys(tab)
    if tab then
        local srt      = { }
        local category = 0 -- 0=unknown 1=string, 2=number 3=mixed
        local s        = 0
        for key in next, tab do
            s = s + 1
            srt[s] = key
            if category ~= 3 then
                local tkey = type(key)
                if category == 1 then
                    if tkey ~= "string" then
                        category = 3
                    end
                elseif category == 2 then
                    if tkey ~= "number" then
                        category = 3
                    end
                else
                    if tkey == "string" then
                        category = 1
                    elseif tkey == "number" then
                        category = 2
                    else
                        category = 3
                    end
                end
            end
        end
        if s < 2 then
            -- nothing to sort
        elseif category == 3 then
            sort(srt,compare)
        else
            sort(srt)
        end
        return srt
    else
        return { }
    end
end

local function sortedhashonly(tab)
    if tab then
        local srt = { }
        local s   = 0
        for key in next, tab do
            if type(key) == "string" then
                s = s + 1
                srt[s] = key
            end
        end
        if s > 1 then
            sort(srt)
        end
        return srt
    else
        return { }
    end
end

local function sortedindexonly(tab)
    if tab then
        local srt = { }
        local s   = 0
        for key in next, tab do
            if type(key) == "number" then
                s = s + 1
                srt[s] = key
            end
        end
        if s > 1 then
            sort(srt)
        end
        return srt
    else
        return { }
    end
end

local function sortedhashkeys(tab,cmp) -- fast one
    if tab then
        local srt = { }
        local s   = 0
        for key in next, tab do
            if key then
                s= s + 1
                srt[s] = key
            end
        end
        if s > 1 then
            sort(srt,cmp)
        end
        return srt
    else
        return { }
    end
end

function table.allkeys(t)
    local keys = { }
    for k, v in next, t do
        for k in next, v do
            keys[k] = true
        end
    end
    return sortedkeys(keys)
end

table.sortedkeys      = sortedkeys
table.sortedhashonly  = sortedhashonly
table.sortedindexonly = sortedindexonly
table.sortedhashkeys  = sortedhashkeys

local function nothing() end

local function sortedhash(t,cmp)
    if t then
        local s
        if cmp then
            -- it would be nice if the sort function would accept a third argument (or nicer, an optional first)
            s = sortedhashkeys(t,function(a,b) return cmp(t,a,b) end)
        else
            s = sortedkeys(t) -- the robust one
        end
        local m = #s
        if m == 1 then
            return next, t
        elseif m > 0 then
            local n = 0
            return function()
                if n < m then
                    n = n + 1
                    local k = s[n]
                    return k, t[k]
                end
            end
        end
    end
    return nothing
end

-- local function iterate(t,i)
--     local i = i + 1
--     if i <= t.n then
--         local k = t[i]
--         return i, k, t.t[k]
--     end
-- end
--
-- local function indexedhash(t,cmp)
--     if t then
--         local s
--         if cmp then
--             -- it would be nice if the sort function would accept a third argument (or nicer, an optional first)
--             s = sortedhashkeys(t,function(a,b) return cmp(t,a,b) end)
--         else
--             s = sortedkeys(t) -- the robust one
--         end
--         local m = #s
--         if m == 1 then
--             return next, t
--         elseif m > 0 then
--             s.n = m
--             s.t = t
--             return iterate, s, 0
--         end
--     end
--     return nothing
-- end
--
-- -- for i, k, v in indexedhash(t) do print(k,v,s) end

table.sortedhash  = sortedhash
table.sortedpairs = sortedhash -- obsolete

function table.append(t,list)
    local n = #t
    for i=1,#list do
        n = n + 1
        t[n] = list[i]
    end
    return t
end

function table.prepend(t, list)
    local nl = #list
    local nt = nl + #t
    for i=#t,1,-1 do
        t[nt] = t[i]
        nt = nt - 1
    end
    for i=1,#list do
        t[i] = list[i]
    end
    return t
end

-- function table.merge(t, ...) -- first one is target
--     t = t or { }
--     local lst = { ... }
--     for i=1,#lst do
--         for k, v in next, lst[i] do
--             t[k] = v
--         end
--     end
--     return t
-- end

function table.merge(t, ...) -- first one is target
    if not t then
        t = { }
    end
    for i=1,select("#",...) do
        for k, v in next, (select(i,...)) do
            t[k] = v
        end
    end
    return t
end

-- function table.merged(...)
--     local tmp, lst = { }, { ... }
--     for i=1,#lst do
--         for k, v in next, lst[i] do
--             tmp[k] = v
--         end
--     end
--     return tmp
-- end

function table.merged(...)
    local t = { }
    for i=1,select("#",...) do
        for k, v in next, (select(i,...)) do
            t[k] = v
        end
    end
    return t
end

-- function table.imerge(t, ...)
--     local lst, nt = { ... }, #t
--     for i=1,#lst do
--         local nst = lst[i]
--         for j=1,#nst do
--             nt = nt + 1
--             t[nt] = nst[j]
--         end
--     end
--     return t
-- end

function table.imerge(t, ...)
    local nt = #t
    for i=1,select("#",...) do
        local nst = select(i,...)
        for j=1,#nst do
            nt = nt + 1
            t[nt] = nst[j]
        end
    end
    return t
end

-- function table.imerged(...)
--     local tmp, ntmp, lst = { }, 0, {...}
--     for i=1,#lst do
--         local nst = lst[i]
--         for j=1,#nst do
--             ntmp = ntmp + 1
--             tmp[ntmp] = nst[j]
--         end
--     end
--     return tmp
-- end

function table.imerged(...)
    local tmp  = { }
    local ntmp = 0
    for i=1,select("#",...) do
        local nst = select(i,...)
        for j=1,#nst do
            ntmp = ntmp + 1
            tmp[ntmp] = nst[j]
        end
    end
    return tmp
end

local function fastcopy(old,metatabletoo) -- fast one
    if old then
        local new = { }
        for k, v in next, old do
            if type(v) == "table" then
                new[k] = fastcopy(v,metatabletoo) -- was just table.copy
            else
                new[k] = v
            end
        end
        if metatabletoo then
            -- optional second arg
            local mt = getmetatable(old)
            if mt then
                setmetatable(new,mt)
            end
        end
        return new
    else
        return { }
    end
end

-- todo : copy without metatable

local function copy(t,tables) -- taken from lua wiki, slightly adapted
    if not tables then
        tables = { }
    end
    local tcopy = { }
    if not tables[t] then
        tables[t] = tcopy
    end
    for i,v in next, t do -- brrr, what happens with sparse indexed
        if type(i) == "table" then
            if tables[i] then
                i = tables[i]
            else
                i = copy(i,tables)
            end
        end
        if type(v) ~= "table" then
            tcopy[i] = v
        elseif tables[v] then
            tcopy[i] = tables[v]
        else
            tcopy[i] = copy(v,tables)
        end
    end
    local mt = getmetatable(t)
    if mt then
        setmetatable(tcopy,mt)
    end
    return tcopy
end

table.fastcopy = fastcopy
table.copy     = copy

function table.derive(parent) -- for the moment not public
    local child = { }
    if parent then
        setmetatable(child,{ __index = parent })
    end
    return child
end

function table.tohash(t,value)
    local h = { }
    if t then
        if value == nil then value = true end
        for _, v in next, t do
            h[v] = value
        end
    end
    return h
end

function table.fromhash(t)
    local hsh = { }
    local h   = 0
    for k, v in next, t do
        if v then
            h = h + 1
            hsh[h] = k
        end
    end
    return hsh
end

local noquotes, hexify, handle, compact, inline, functions, metacheck, accurate

local reserved = table.tohash { -- intercept a language inconvenience: no reserved words as key
    'and', 'break', 'do', 'else', 'elseif', 'end', 'false', 'for', 'function', 'if',
    'in', 'local', 'nil', 'not', 'or', 'repeat', 'return', 'then', 'true', 'until', 'while',
    'NaN', 'goto', 'const',
}

local function is_simple_table(t,hexify,accurate) -- also used in util-tab so maybe public
    local nt = #t
    if nt > 0 then
        local n = 0
        for _, v in next, t do
            n = n + 1
            if type(v) == "table" then
                return nil
            end
        end
     -- local haszero = t[0]
        local haszero = rawget(t,0) -- don't trigger meta
        if n == nt then
            local tt = { }
            for i=1,nt do
                local v = t[i]
                local tv = type(v)
                if tv == "number" then
                 -- tt[i] = v -- not needed tostring(v)
                    if hexify then
                        tt[i] = format("0x%X",v)
                    elseif accurate then
                        tt[i] = format("%q",v)
                    else
                        tt[i] = v -- not needed tostring(v)
                    end
                elseif tv == "string" then
                    tt[i] = format("%q",v) -- f_string(v)
                elseif tv == "boolean" then
                    tt[i] = v and "true" or "false"
                else
                    return nil
                end
            end
            return tt
        elseif haszero and (n == nt + 1) then
            local tt = { }
            for i=0,nt do
                local v = t[i]
                local tv = type(v)
                if tv == "number" then
                 -- tt[i+1] = v -- not needed tostring(v)
                    if hexify then
                        tt[i+1] = format("0x%X",v)
                    elseif accurate then
                        tt[i+1] = format("%q",v)
                    else
                        tt[i+1] = v -- not needed tostring(v)
                    end
                elseif tv == "string" then
                    tt[i+1] = format("%q",v) -- f_string(v)
                elseif tv == "boolean" then
                    tt[i+1] = v and "true" or "false"
                else
                    return nil
                end
            end
            tt[1] = "[0] = " .. tt[1]
            return tt
        end
    end
    return nil
end

table.is_simple_table = is_simple_table

-- Because this is a core function of mkiv I moved some function calls
-- inline.
--
-- twice as fast in a test:
--
-- local propername = lpeg.P(lpeg.R("AZ","az","__") * lpeg.R("09","AZ","az", "__")^0 * lpeg.P(-1) )

-- problem: there no good number_to_string converter with the best resolution

-- probably using .. is faster than format
-- maybe split in a few cases (yes/no hexify)

-- todo: %g faster on numbers than %s

-- we can speed this up with repeaters and formatters but we haven't defined them
-- yet

local propername = patterns.propername -- was find(name,"^%a[%w%_]*$")

local function dummy() end

local function do_serialize(root,name,depth,level,indexed)
    if level > 0 then
        depth = depth .. " "
        if indexed then
            handle(format("%s{",depth))
        else
            local tn = type(name)
            if tn == "number" then
                if hexify then
                    handle(format("%s[0x%X]={",depth,name))
                else
                    handle(format("%s[%s]={",depth,name))
                end
            elseif tn == "string" then
                if noquotes and not reserved[name] and lpegmatch(propername,name) then
                    handle(format("%s%s={",depth,name))
                else
                    handle(format("%s[%q]={",depth,name))
                end
            elseif tn == "boolean" then
                handle(format("%s[%s]={",depth,name and "true" or "false"))
            else
                handle(format("%s{",depth))
            end
        end
    end
    -- we could check for k (index) being number (cardinal)
    if root and next(root) ~= nil then
        local first = nil
        local last  = 0
        if compact then
            last = #root
            for k=1,last do
             -- if root[k] == nil then
                if rawget(root,k) == nil then
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
            if compact and first and tk == "number" and k >= first and k <= last then
                if tv == "number" then
                    if hexify then
                        handle(format("%s 0x%X,",depth,v))
                    elseif accurate then
                        handle(format("%s %q,",depth,v))
                    else
                        handle(format("%s %s,",depth,v)) -- %.99g
                    end
                elseif tv == "string" then
                    handle(format("%s %q,",depth,v))
                elseif tv == "table" then
                    if next(v) == nil then
                        handle(format("%s {},",depth))
                    elseif inline then -- and #t > 0
                        local st = is_simple_table(v,hexify,accurate)
                        if st then
                            handle(format("%s { %s },",depth,concat(st,", ")))
                        else
                            do_serialize(v,k,depth,level+1,true)
                        end
                    else
                        do_serialize(v,k,depth,level+1,true)
                    end
                elseif tv == "boolean" then
                    handle(format("%s %s,",depth,v and "true" or "false"))
                elseif tv == "function" then
                    if functions then
                        handle(format('%s load(%q),',depth,dump(v))) -- maybe strip
                    else
                        handle(format('%s "function",',depth))
                    end
                else
                    handle(format("%s %q,",depth,tostring(v)))
                end
            elseif k == "__p__" then -- parent
                if false then
                    handle(format("%s __p__=nil,",depth))
                end
            elseif tv == "number" then
                if tk == "number" then
                    if hexify then
                        handle(format("%s [0x%X]=0x%X,",depth,k,v))
                    elseif accurate then
                        handle(format("%s [%s]=%q,",depth,k,v))
                    else
                        handle(format("%s [%s]=%s,",depth,k,v)) -- %.99g
                    end
                elseif tk == "boolean" then
                    if hexify then
                        handle(format("%s [%s]=0x%X,",depth,k and "true" or "false",v))
                    elseif accurate then
                        handle(format("%s [%s]=%q,",depth,k and "true" or "false",v))
                    else
                        handle(format("%s [%s]=%s,",depth,k and "true" or "false",v)) -- %.99g
                    end
                elseif tk ~= "string" then
                    -- ignore
                elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
                    if hexify then
                        handle(format("%s %s=0x%X,",depth,k,v))
                    elseif accurate then
                        handle(format("%s %s=%q,",depth,k,v))
                    else
                        handle(format("%s %s=%s,",depth,k,v)) -- %.99g
                    end
                else
                    if hexify then
                        handle(format("%s [%q]=0x%X,",depth,k,v))
                    elseif accurate then
                        handle(format("%s [%q]=%q,",depth,k,v))
                    else
                        handle(format("%s [%q]=%s,",depth,k,v)) -- %.99g
                    end
                end
            elseif tv == "string" then
                if tk == "number" then
                    if hexify then
                        handle(format("%s [0x%X]=%q,",depth,k,v))
                    elseif accurate then
                        handle(format("%s [%q]=%q,",depth,k,v))
                    else
                        handle(format("%s [%s]=%q,",depth,k,v))
                    end
                elseif tk == "boolean" then
                    handle(format("%s [%s]=%q,",depth,k and "true" or "false",v))
                elseif tk ~= "string" then
                    -- ignore
                elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
                    handle(format("%s %s=%q,",depth,k,v))
                else
                    handle(format("%s [%q]=%q,",depth,k,v))
                end
            elseif tv == "table" then
                if next(v) == nil then
                    if tk == "number" then
                        if hexify then
                            handle(format("%s [0x%X]={},",depth,k))
                        elseif accurate then
                            handle(format("%s [%q]={},",depth,k))
                        else
                            handle(format("%s [%s]={},",depth,k))
                        end
                    elseif tk == "boolean" then
                        handle(format("%s [%s]={},",depth,k and "true" or "false"))
                    elseif tk ~= "string" then
                        -- ignore
                    elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
                        handle(format("%s %s={},",depth,k))
                    else
                        handle(format("%s [%q]={},",depth,k))
                    end
                elseif inline then
                    local st = is_simple_table(v,hexify,accurate)
                    if st then
                        if tk == "number" then
                            if hexify then
                                handle(format("%s [0x%X]={ %s },",depth,k,concat(st,", ")))
                            elseif accurate then
                                handle(format("%s [%q]={ %s },",depth,k,concat(st,", ")))
                            else
                                handle(format("%s [%s]={ %s },",depth,k,concat(st,", ")))
                            end
                        elseif tk == "boolean" then
                            handle(format("%s [%s]={ %s },",depth,k and "true" or "false",concat(st,", ")))
                        elseif tk ~= "string" then
                            -- ignore
                        elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
                            handle(format("%s %s={ %s },",depth,k,concat(st,", ")))
                        else
                            handle(format("%s [%q]={ %s },",depth,k,concat(st,", ")))
                        end
                    else
                        do_serialize(v,k,depth,level+1)
                    end
                else
                    do_serialize(v,k,depth,level+1)
                end
            elseif tv == "boolean" then
                if tk == "number" then
                    if hexify then
                        handle(format("%s [0x%X]=%s,",depth,k,v and "true" or "false"))
                    elseif accurate then
                        handle(format("%s [%q]=%s,",depth,k,v and "true" or "false"))
                    else
                        handle(format("%s [%s]=%s,",depth,k,v and "true" or "false"))
                    end
                elseif tk == "boolean" then
                    handle(format("%s [%s]=%s,",depth,tostring(k),v and "true" or "false"))
                elseif tk ~= "string" then
                    -- ignore
                elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
                    handle(format("%s %s=%s,",depth,k,v and "true" or "false"))
                else
                    handle(format("%s [%q]=%s,",depth,k,v and "true" or "false"))
                end
            elseif tv == "function" then
                if functions then
                    local getinfo = debug and debug.getinfo
                    if getinfo then
                        local f = getinfo(v).what == "C" and dump(dummy) or dump(v) -- maybe strip
                     -- local f = getinfo(v).what == "C" and dump(function(...) return v(...) end) or dump(v) -- maybe strip
                        if tk == "number" then
                            if hexify then
                                handle(format("%s [0x%X]=load(%q),",depth,k,f))
                            elseif accurate then
                                handle(format("%s [%q]=load(%q),",depth,k,f))
                            else
                                handle(format("%s [%s]=load(%q),",depth,k,f))
                            end
                        elseif tk == "boolean" then
                            handle(format("%s [%s]=load(%q),",depth,k and "true" or "false",f))
                        elseif tk ~= "string" then
                            -- ignore
                        elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
                            handle(format("%s %s=load(%q),",depth,k,f))
                        else
                            handle(format("%s [%q]=load(%q),",depth,k,f))
                        end
                    end
                end
            else
                if tk == "number" then
                    if hexify then
                        handle(format("%s [0x%X]=%q,",depth,k,tostring(v)))
                    elseif accurate then
                        handle(format("%s [%q]=%q,",depth,k,tostring(v)))
                    else
                        handle(format("%s [%s]=%q,",depth,k,tostring(v)))
                    end
                elseif tk == "boolean" then
                    handle(format("%s [%s]=%q,",depth,k and "true" or "false",tostring(v)))
                elseif tk ~= "string" then
                    -- ignore
                elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
                    handle(format("%s %s=%q,",depth,k,tostring(v)))
                else
                    handle(format("%s [%q]=%q,",depth,k,tostring(v)))
                end
            end
        end
    end
    if level > 0 then
        handle(format("%s},",depth))
    end
end

-- replacing handle by a direct t[#t+1] = ... (plus test) is not much
-- faster (0.03 on 1.00 for zapfino.tma)

local function serialize(_handle,root,name,specification) -- handle wins
    local tname = type(name)
    if type(specification) == "table" then
        noquotes  = specification.noquotes
        hexify    = specification.hexify
        accurate  = specification.accurate
        handle    = _handle or specification.handle or print
        functions = specification.functions
        compact   = specification.compact
        inline    = specification.inline and compact
        metacheck = specification.metacheck
        if functions == nil then
            functions = true
        end
        if compact == nil then
            compact = true
        end
        if inline == nil then
            inline = compact
        end
        if metacheck == nil then
            metacheck = true
        end
    else
        noquotes  = false
        hexify    = false
        handle    = _handle or print
        compact   = true
        inline    = true
        functions = true
        metacheck = true
    end
    if tname == "string" then
        if name == "return" then
            handle("return {")
        else
            handle(name .. "={")
        end
    elseif tname == "number" then
        if hexify then
            handle(format("[0x%X]={",name))
        else
            handle("[" .. name .. "]={")
        end
    elseif tname == "boolean" then
        if name then
            handle("return {")
        else
            handle("{")
        end
    else
        handle("t={")
    end
    if root then
        -- The dummy access will initialize a table that has a delayed initialization
        -- using a metatable. (maybe explicitly test for metatable). This can crash on
        -- metatables that check the index against a number.
        if metacheck and getmetatable(root) then
            local dummy = root._w_h_a_t_e_v_e_r_
            root._w_h_a_t_e_v_e_r_ = nil
        end
        -- Let's forget about empty tables.
        if next(root) ~= nil then
            do_serialize(root,name,"",0)
        end
    end
    handle("}")
end

-- A version with formatters is some 20% faster than using format (because formatters are
-- much faster) but of course, inlining the format using .. is then again faster .. anyway,
-- as we do some pretty printing as well there is not that much to gain unless we make a
-- 'fast' ugly variant as well. But, we would have to move the formatter to l-string then.

-- name:
--
-- true     : return     { }
-- false    :            { }
-- nil      : t        = { }
-- string   : string   = { }
-- "return" : return     { }
-- number   : [number] = { }

function table.serialize(root,name,specification)
    local t = { }
    local n = 0
    local function flush(s)
        n = n + 1
        t[n] = s
    end
    serialize(flush,root,name,specification)
    return concat(t,"\n")
end

--   local a = { e = { 1,2,3,4,5,6}, a = 1, b = 2, c = "ccc", d = { a = 1, b = 2, c = "ccc", d = { a = 1, b = 2, c = "ccc" } } }
--   local t = os.clock()
--   for i=1,10000 do
--       table.serialize(a)
--   end
--   print(os.clock()-t,table.serialize(a))

table.tohandle = serialize

local maxtab = 2*1024

function table.tofile(filename,root,name,specification)
    local f = io.open(filename,'w')
    if f then
        if maxtab > 1 then
            local t = { }
            local n = 0
            local function flush(s)
                n = n + 1
                t[n] = s
                if n > maxtab then
                    f:write(concat(t,"\n"),"\n") -- hm, write(sometable) should be nice
                    t = { } -- we could recycle t if needed
                    n = 0
                end
            end
            serialize(flush,root,name,specification)
            f:write(concat(t,"\n"),"\n")
        else
            local function flush(s)
                f:write(s,"\n")
            end
            serialize(flush,root,name,specification)
        end
        f:close()
        io.flush()
    end
end

local function flattened(t,f,depth) -- also handles { nil, 1, nil, 2 }
    if f == nil then
        f     = { }
        depth = 0xFFFF
    elseif tonumber(f) then
        -- assume that only two arguments are given
        depth = f
        f     = { }
    elseif not depth then
        depth = 0xFFFF
    end
    for k, v in next, t do
        if type(k) ~= "number" then
            if depth > 0 and type(v) == "table" then
                flattened(v,f,depth-1)
            else
                f[#f+1] = v
            end
        end
    end
    for k=1,#t do
        local v = t[k]
        if depth > 0 and type(v) == "table" then
            flattened(v,f,depth-1)
        else
            f[#f+1] = v
        end
    end
    return f
end

table.flattened = flattened

local function collapsed(t,f,h)
    if f == nil then
        f = { }
        h = { }
    end
    for k=1,#t do
        local v = t[k]
        if type(v) == "table" then
            collapsed(v,f,h)
        elseif not h[v] then
            f[#f+1] = v
            h[v] = true
        end
    end
    return f
end

local function collapsedhash(t,h)
    if h == nil then
        h = { }
    end
    for k=1,#t do
        local v = t[k]
        if type(v) == "table" then
            collapsedhash(v,h)
        else
            h[v] = true
        end
    end
    return h
end

table.collapsed     = collapsed     -- 20% faster than unique(collapsed(t))
table.collapsedhash = collapsedhash

local function unnest(t,f) -- only used in mk, for old times sake
    if not f then          -- and only relevant for token lists
        f = { }            -- this one can become obsolete
    end
    for i=1,#t do
        local v = t[i]
        if type(v) == "table" then
            if type(v[1]) == "table" then
                unnest(v,f)
            else
                f[#f+1] = v
            end
        else
            f[#f+1] = v
        end
    end
    return f
end

function table.unnest(t) -- bad name
    return unnest(t)
end

local function are_equal(a,b,n,m) -- indexed
    if a == b then
        return true
    elseif a and b and #a == #b then
        if not n then
            n = 1
        end
        if not m then
            m = #a
        end
        for i=n,m do
            local ai, bi = a[i], b[i]
            if ai==bi then
                -- same
            elseif type(ai) == "table" and type(bi) == "table" then
                if not are_equal(ai,bi) then
                    return false
                end
            else
                return false
            end
        end
        return true
    else
        return false
    end
end

local function identical(a,b) -- assumes same structure
    if a ~= b then
        for ka, va in next, a do
            local vb = b[ka]
            if va == vb then
                -- same
            elseif type(va) == "table" and  type(vb) == "table" then
                if not identical(va,vb) then
                    return false
                end
            else
                return false
            end
        end
    end
    return true
end

table.identical = identical
table.are_equal = are_equal

local function sparse(old,nest,keeptables)
    local new  = { }
    for k, v in next, old do
        if not (v == "" or v == false) then
            if nest and type(v) == "table" then
                v = sparse(v,nest)
                if keeptables or next(v) ~= nil then
                    new[k] = v
                end
            else
                new[k] = v
            end
        end
    end
    return new
end

table.sparse = sparse

function table.compact(t)
    return sparse(t,true,true)
end

function table.contains(t, v)
    if t then
        for i=1, #t do
            if t[i] == v then
                return i
            end
        end
    end
    return false
end

function table.count(t)
    local n = 0
    for k, v in next, t do
        n = n + 1
    end
    return n
end

function table.swapped(t,s) -- hash, we need to make sure we don't mess up next
    local n = { }
    if s then
        for k, v in next, s do
            n[k] = v
        end
    end
    for k, v in next, t do
        n[v] = k
    end
    return n
end

function table.hashed(t) -- list, add hash to index (save because we are not yet mixed
    for i=1,#t do
        t[t[i]] = i
    end
    return t
end

function table.mirrored(t) -- hash, we need to make sure we don't mess up next
    local n = { }
    for k, v in next, t do
        n[v] = k
        n[k] = v
    end
    return n
end

function table.reversed(t)
    if t then
        local tt = { }
        local tn = #t
        if tn > 0 then
            local ttn = 0
            for i=tn,1,-1 do
                ttn = ttn + 1
                tt[ttn] = t[i]
            end
        end
        return tt
    end
end

function table.reverse(t) -- check with 5.3 ?
    if t then
        local n = #t
        local m = n + 1
        for i=1,floor(n/2) do -- maybe just n//2
            local j = m - i
            t[i], t[j] = t[j], t[i]
        end
        return t
    end
end

-- This one is for really simple cases where need a hash from a table.

local function sequenced(t,sep,simple)
    if not t then
        return ""
    elseif type(t) ~= "table" then
        return t -- handy fallback
    end
    local n = #t
    local s = { }
    if n > 0 then
        -- indexed
        for i=1,n do
            local v = t[i]
            if type(v) == "table" then
                s[i] = "{" .. sequenced(v,sep,simple) .. "}"
            else
                s[i] = tostring(t[i])
            end
        end
    else
        -- hashed
        n = 0
        for k, v in sortedhash(t) do
            if simple then
                if v == true then
                    n = n + 1
                    s[n] = k
                elseif v and v~= "" then
                    n = n + 1
                    if type(v) == "table" then
                        s[n] = k .. "={" .. sequenced(v,sep,simple) .. "}"
                    else
                        s[n] = k .. "=" .. tostring(v)
                    end
                end
            else
                n = n + 1
                if type(v) == "table" then
                    s[n] = k .. "={" .. sequenced(v,sep,simple) .. "}"
                else
                    s[n] = k .. "=" .. tostring(v)
                end
            end
        end
    end
    if sep == true then
        return "{ " .. concat(s,", ") .. " }"
    else
        return concat(s,sep or " | ")
    end
end

table.sequenced = sequenced

function table.print(t,...)
    if type(t) ~= "table" then
        print(tostring(t))
    else
        serialize(print,t,...)
    end
end

if setinspector then
    setinspector("table",function(v) if type(v) == "table" then serialize(print,v,"table") return true end end)
end

-- -- -- obsolete but we keep them for a while and might comment them later -- -- --

-- roughly: copy-loop : unpack : sub == 0.9 : 0.4 : 0.45 (so in critical apps, use unpack)

function table.sub(t,i,j)
    return { unpack(t,i,j) }
end

-- slower than #t on indexed tables (#t only returns the size of the numerically indexed slice)

function table.is_empty(t)
    return not t or next(t) == nil
end

function table.has_one_entry(t)
    return t and next(t,next(t)) == nil
end

-- new (rather basic, not indexed and nested)

function table.loweredkeys(t) -- maybe utf
    local l = { }
    for k, v in next, t do
        l[lower(k)] = v
    end
    return l
end

-- new, might move (maybe duplicate)

function table.unique(old)
    local hash = { }
    local new  = { }
    local n    = 0
    for i=1,#old do
        local oi = old[i]
        if not hash[oi] then
            n = n + 1
            new[n] = oi
            hash[oi] = true
        end
    end
    return new
end

function table.sorted(t,...)
    sort(t,...)
    return t -- still sorts in-place
end

--

function table.values(t,s) -- optional sort flag
    if t then
        local values = { }
        local keys   = { }
        local v      = 0
        for key, value in next, t do
            if not keys[value] then
                v = v + 1
                values[v] = value
                keys[k]   = key
            end
        end
        if s then
            sort(values)
        end
        return values
    else
        return { }
    end
end

-- maybe this will move to util-tab.lua

-- for k, v in table.filtered(t,pattern)          do ... end
-- for k, v in table.filtered(t,pattern,true)     do ... end
-- for k, v in table.filtered(t,pattern,true,cmp) do ... end

function table.filtered(t,pattern,sort,cmp)
    if t and type(pattern) == "string" then
        if sort then
            local s
            if cmp then
                -- it would be nice if the sort function would accept a third argument (or nicer, an optional first)
                s = sortedhashkeys(t,function(a,b) return cmp(t,a,b) end)
            else
                s = sortedkeys(t) -- the robust one
            end
            local n = 0
            local m = #s
            local function kv(s)
                while n < m do
                    n = n + 1
                    local k = s[n]
                    if find(k,pattern) then
                        return k, t[k]
                    end
                end
            end
            return kv, s
        else
            local n = next(t)
            local function iterator()
                while n ~= nil do
                    local k = n
                    n = next(t,k)
                    if find(k,pattern) then
                        return k, t[k]
                    end
                end
            end
            return iterator, t
        end
    else
        return nothing
    end
end

-- lua 5.3:

if not table.move then

    function table.move(a1,f,e,t,a2)
        if a2 and a1 ~= a2 then
            for i=f,e do
                a2[t] = a1[i]
                t = t + 1
            end
            return a2
        else
            t = t + e - f
            for i=e,f,-1 do
                a1[t] = a1[i]
                t = t - 1
            end
            return a1
        end
    end

end
