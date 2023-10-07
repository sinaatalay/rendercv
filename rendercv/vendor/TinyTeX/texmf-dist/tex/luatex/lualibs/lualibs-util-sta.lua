if not modules then modules = { } end modules ['util-sta'] = {
    version   = 1.001,
    comment   = "companion to util-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local insert, remove, fastcopy, concat = table.insert, table.remove, table.fastcopy, table.concat
local format = string.format
local select, tostring = select, tostring

local trace_stacker = false  trackers.register("stacker.resolve", function(v) trace_stacker = v end)

local stacker = stacker or { }

utilities.stacker = stacker

local function start(s,t,first,last)
    if s.mode == "switch" then
        local n = tostring(t[last])
        if trace_stacker then
            s.report("start: %s",n)
        end
        return n
    else
        local r = { }
        for i=first,last do
            r[#r+1] = tostring(t[i])
        end
        local n = concat(r," ")
        if trace_stacker then
            s.report("start: %s",n)
        end
        return n
    end
end

local function stop(s,t,first,last)
    if s.mode == "switch" then
        local n = tostring(false)
        if trace_stacker then
            s.report("stop: %s",n)
        end
        return n
    else
        local r = { }
        for i=last,first,-1 do
            r[#r+1] = tostring(false)
        end
        local n = concat(r," ")
        if trace_stacker then
            s.report("stop: %s",n)
        end
        return n
    end
end

local function change(s,t1,first1,last1,t2,first2,last2)
    if s.mode == "switch" then
        local n = tostring(t2[last2])
        if trace_stacker then
            s.report("change: %s",n)
        end
        return n
    else
        local r = { }
        for i=last1,first1,-1 do
            r[#r+1] = tostring(false)
        end
        local n = concat(r," ")
        for i=first2,last2 do
            r[#r+1] = tostring(t2[i])
        end
        if trace_stacker then
            s.report("change: %s",n)
        end
        return n
    end
end

function stacker.new(name)

    -- to be sped up, mmaybe foo:bar syntax here but then quite some access

    local report = logs.reporter("stacker",name or nil)

    local s

    local stack = { }
    local list  = { }
    local ids   = { }
    local hash  = { }

    local hashing = true

    local function push(...)
        -- todo check if more than 1 argument
        for i=1,select("#",...) do
            insert(stack,(select(i,...))) -- watch the ()
        end
        if hashing then
            local c = concat(stack,"|")
            local n = hash[c]
            if not n then
                n = #list+1
                hash[c] = n
                list[n] = fastcopy(stack)
            end
            insert(ids,n)
            return n
        else
            local n = #list+1
            list[n] = fastcopy(stack)
            insert(ids,n)
            return n
        end
    end

    local function pop()
        remove(stack)
        remove(ids)
        return ids[#ids] or s.unset or -1
    end

    local function clean()
        if #stack == 0 then
            if trace_stacker then
                s.report("%s list entries, %s stack entries",#list,#stack)
            end
        end
    end

    local tops   = { }
    local top    = nil
    local switch = nil

    local function resolve_reset(mode)
        if #tops > 0 then
            report("resetting %s left-over states of %a",#tops,name)
        end
        tops   = { }
        top    = nil
        switch = nil
    end

    local function resolve_begin(mode)
        if mode then
            switch = mode == "switch"
        else
            switch = s.mode == "switch"
        end
        top = { switch = switch }
        insert(tops,top)
    end

    local function resolve_step(ti) -- keep track of changes outside function !
        -- todo: optimize for n=1 etc
        if not top then
         -- report("messed op stacker %a",name)
            return
        end
        local result = nil
        local noftop = #top
        if ti > 0 then
            local current = list[ti]
            if current then
                local noflist = #current
                local nofsame = 0
                if noflist > noftop then
                    for i=1,noflist do
                        if current[i] == top[i] then
                            nofsame = i
                        else
                            break
                        end
                    end
                else
                    for i=1,noflist do
                        if current[i] == top[i] then
                            nofsame = i
                        else
                            break
                        end
                    end
                end
                local plus = nofsame + 1
                if plus <= noftop then
                    if plus <= noflist then
                        if switch then
                            result = s.change(s,top,plus,noftop,current,nofsame,noflist)
                        else
                            result = s.change(s,top,plus,noftop,current,plus,noflist)
                        end
                    else
                        if switch then
                            result = s.change(s,top,plus,noftop,current,nofsame,noflist)
                        else
                            result = s.stop(s,top,plus,noftop)
                        end
                    end
                elseif plus <= noflist then
                    if switch then
                        result = s.start(s,current,nofsame,noflist)
                    else
                        result = s.start(s,current,plus,noflist)
                    end
                end
                top = current
            else
                if 1 <= noftop then
                    result = s.stop(s,top,1,noftop)
                end
                top = { }
            end
            return result
        else
            if 1 <= noftop then
                result = s.stop(s,top,1,noftop)
            end
            top = { }
            return result
        end
    end

    local function resolve_end()
     -- resolve_step(s.unset)
        if #tops > 0 then -- was #top brrr
            local result = s.stop(s,top,1,#top)
            remove(tops)
            top = tops[#tops]
            switch = top and top.switch
            return result
        end
    end

    local function resolve(t)
        resolve_begin()
        for i=1,#t do
            resolve_step(t[i])
        end
        resolve_end()
    end

    s = {
        name          = name or "unknown",
        unset         = -1,
        report        = report,
        start         = start,
        stop          = stop,
        change        = change,
        push          = push,
        pop           = pop,
        clean         = clean,
        resolve       = resolve,
        resolve_begin = resolve_begin,
        resolve_step  = resolve_step,
        resolve_end   = resolve_end,
        resolve_reset = resolve_reset,
    }

    return s -- we can overload functions

end

-- local s = utilities.stacker.new("demo")
--
-- local unset = s.unset
-- local push  = s.push
-- local pop   = s.pop
--
-- local t = {
--     unset,
--     unset,
--     push("a"),     -- a
--     push("b","c"), -- a b c
--     pop(),         -- a b
--     push("d"),     -- a b d
--     pop(),         -- a b
--     unset,
--     pop(),         -- a
--     pop(),         -- b
--     unset,
--     unset,
-- }
--
-- s.resolve(t)

-- demostacker = utilities.stacker.new("demos")
--
-- local whatever = {
--     one     = "1 0 0 RG 1 0 0 rg",
--     two     = "1 1 0 RG 1 1 0 rg",
--     [false] = "0 G 0 g",
-- }
--
-- local concat = table.concat
--
-- local pageliteral = nodes.pool.pageliteral
--
-- function demostacker.start(s,t,first,last)
--     local n = whatever[t[last]]
--  -- s.report("start: %s",n)
--     return pageliteral(n)
-- end
--
-- function demostacker.stop(s,t,first,last)
--     local n = whatever[false]
--  -- s.report("stop: %s",n)
--     return pageliteral(n)
-- end
--
-- function demostacker.change(s,t1,first1,last1,t2,first2,last2)
--     local n = whatever[t2[last2]]
--  -- s.report("change: %s",n)
--     return pageliteral(n)
-- end
--
-- demostacker.mode = "switch"
--
-- local whatever = {
--     one     = "/OC /test1 BDC",
--     two     = "/OC /test2 BDC",
--     [false] = "EMC",
-- }
--
-- demostacker = utilities.stacker.new("demos")
--
-- function demostacker.start(s,t,first,last)
--     local r = { }
--     for i=first,last do
--         r[#r+1] = whatever[t[i]]
--     end
--  -- s.report("start: %s",concat(r," "))
--     return pageliteral(concat(r," "))
-- end
--
-- function demostacker.stop(s,t,first,last)
--     local r = { }
--     for i=last,first,-1 do
--         r[#r+1] = whatever[false]
--     end
--  -- s.report("stop: %s",concat(r," "))
--     return pageliteral(concat(r," "))
-- end
--
-- function demostacker.change(s,t1,first1,last1,t2,first2,last2)
--     local r = { }
--     for i=last1,first1,-1 do
--         r[#r+1] = whatever[false]
--     end
--     for i=first2,last2 do
--         r[#r+1] = whatever[t2[i]]
--     end
--  -- s.report("change: %s",concat(r," "))
--     return pageliteral(concat(r," "))
-- end
--
-- demostacker.mode = "stack"
