if not modules then modules = { } end modules ['l-number'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkxl",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local tostring, tonumber = tostring, tonumber
local format, match, rep = string.format, string.match, string.rep
local concat, insert = table.concat, table.insert
local lpegmatch = lpeg.match
local floor = math.floor

number       = number or { }
local number = number

-- print(number.tobitstring(8))
-- print(number.tobitstring(14))
-- print(number.tobitstring(66))
-- print(number.tobitstring(0x00))
-- print(number.tobitstring(0xFF))
-- print(number.tobitstring(46260767936,4))

if bit32 then

    local bextract = bit32.extract

    local t = {
        "0", "0", "0", "0", "0", "0", "0", "0",
        "0", "0", "0", "0", "0", "0", "0", "0",
        "0", "0", "0", "0", "0", "0", "0", "0",
        "0", "0", "0", "0", "0", "0", "0", "0",
    }

    function number.tobitstring(b,m,w)
        if not w then
            w = 32
        end
        local n = w
        for i=0,w-1 do
            local v = bextract(b,i)
            local k = w - i
            if v == 1 then
                n = k
                t[k] = "1"
            else
                t[k] = "0"
            end
        end
        if w then
            return concat(t,"",1,w)
        elseif m then
            m = 33 - m * 8
            if m < 1 then
                m = 1
            end
            return concat(t,"",1,m)
        elseif n < 8 then
            return concat(t)
        elseif n < 16 then
            return concat(t,"",9)
        elseif n < 24 then
            return concat(t,"",17)
        else
            return concat(t,"",25)
        end
    end

else

    function number.tobitstring(n,m)
        if n > 0 then
            local t = { }
            while n > 0 do
                insert(t,1,n % 2 > 0 and 1 or 0)
                n = floor(n/2)
            end
            local nn = 8 - #t % 8
            if nn > 0 and nn < 8 then
                for i=1,nn do
                    insert(t,1,0)
                end
            end
            if m then
                m = m * 8 - #t
                if m > 0 then
                    insert(t,1,rep("0",m))
                end
            end
            return concat(t)
        elseif m then
            rep("00000000",m)
        else
            return "00000000"
        end
    end

end

function number.valid(str,default)
    return tonumber(str) or default or nil
end

function number.toevenhex(n)
    local s = format("%X",n)
    if #s % 2 == 0 then
        return s
    else
        return "0" .. s
    end
end

-- -- a,b,c,d,e,f = number.toset(100101)
-- --
-- -- function number.toset(n)
-- --     return match(tostring(n),"(.?)(.?)(.?)(.?)(.?)(.?)(.?)(.?)")
-- -- end
-- --
-- -- -- the lpeg way is slower on 8 digits, but faster on 4 digits, some 7.5%
-- -- -- on
-- --
-- -- for i=1,1000000 do
-- --     local a,b,c,d,e,f,g,h = number.toset(12345678)
-- --     local a,b,c,d         = number.toset(1234)
-- --     local a,b,c           = number.toset(123)
-- --     local a,b,c           = number.toset("123")
-- -- end
--
-- local one = lpeg.C(1-lpeg.S('')/tonumber)^1
--
-- function number.toset(n)
--     return lpegmatch(one,tostring(n))
-- end
--
-- -- function number.bits(n,zero)
-- --     local t, i = { }, (zero and 0) or 1
-- --     while n > 0 do
-- --         local m = n % 2
-- --         if m > 0 then
-- --             insert(t,1,i)
-- --         end
-- --         n = floor(n/2)
-- --         i = i + 1
-- --     end
-- --     return t
-- -- end
-- --
-- -- -- a bit faster
--
-- local function bits(n,i,...)
--     if n > 0 then
--         local m = n % 2
--         local n = floor(n/2)
--         if m > 0 then
--             return bits(n, i+1, i, ...)
--         else
--             return bits(n, i+1,    ...)
--         end
--     else
--         return ...
--     end
-- end
--
-- function number.bits(n)
--     return { bits(n,1) }
-- end

function number.bytetodecimal(b)
    local d = floor(b * 100 / 255 + 0.5)
    if d > 100 then
        return 100
    elseif d < -100 then
        return -100
    else
        return d
    end
end

function number.decimaltobyte(d)
    local b = floor(d * 255 / 100 + 0.5)
    if b > 255 then
        return 255
    elseif b < -255 then
        return -255
    else
        return b
    end
end

function number.idiv(i,d)
    return floor(i/d) -- i//d in 5.3
end
