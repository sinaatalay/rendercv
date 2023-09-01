if not modules then modules = { } end modules ['l-set'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- This will become obsolete when we have the bitset library embedded.

set = set or { }

local nums   = { }
local tabs   = { }
local concat = table.concat
local next, type = next, type

set.create = table.tohash

function set.tonumber(t)
    if next(t) then
        local s = ""
    --  we could save mem by sorting, but it slows down
        for k, v in next, t do
            if v then
            --  why bother about the leading space
                s = s .. " " .. k
            end
        end
        local n = nums[s]
        if not n then
            n = #tabs + 1
            tabs[n] = t
            nums[s] = n
        end
        return n
    else
        return 0
    end
end

function set.totable(n)
    if n == 0 then
        return { }
    else
        return tabs[n] or { }
    end
end

function set.tolist(n)
    if n == 0 or not tabs[n] then
        return ""
    else
        local t, n = { }, 0
        for k, v in next, tabs[n] do
            if v then
                n = n + 1
                t[n] = k
            end
        end
        return concat(t," ")
    end
end

function set.contains(n,s)
    if type(n) == "table" then
        return n[s]
    elseif n == 0 then
        return false
    else
        local t = tabs[n]
        return t and t[s]
    end
end

--~ local c = set.create{'aap','noot','mies'}
--~ local s = set.tonumber(c)
--~ local t = set.totable(s)
--~ print(t['aap'])
--~ local c = set.create{'zus','wim','jet'}
--~ local s = set.tonumber(c)
--~ local t = set.totable(s)
--~ print(t['aap'])
--~ print(t['jet'])
--~ print(set.contains(t,'jet'))
--~ print(set.contains(t,'aap'))

