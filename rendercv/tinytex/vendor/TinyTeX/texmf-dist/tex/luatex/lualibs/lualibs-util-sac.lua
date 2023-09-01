if not modules then modules = { } end modules ['util-sac'] = {
    version   = 1.001,
    optimize  = true,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- experimental string access (some 3 times faster than file access when messing
-- with bytes)

local byte, sub = string.byte, string.sub
local tonumber = tonumber

utilities         = utilities or { }
local streams     = { }
utilities.streams = streams

function streams.open(filename,zerobased)
    local f = filename and io.loaddata(filename)
    if f then
        return { f, 1, #f, zerobased or false }
    end
end

function streams.openstring(f,zerobased)
    if f then
        return { f, 1, #f, zerobased or false }
    end
end

function streams.getstring(f)
    if f then
        return f[1]
    end
end

function streams.close()
    -- dummy
end

function streams.size(f)
    return f and f[3] or 0
end

streams.getsize = streams.size

function streams.setposition(f,i)
    if f[4] then
        -- zerobased
        if i <= 0 then
            f[2] = 1
        else
            f[2] = i + 1
        end
    else
        if i <= 1 then
            f[2] = 1
        else
            f[2] = i
        end
    end
end

function streams.getposition(f)
    if f[4] then
        -- zerobased
        return f[2] - 1
    else
        return f[2]
    end
end

function streams.look(f,n,chars)
    local b = f[2]
    local e = b + n - 1
    if chars then
        return sub(f[1],b,e)
    else
        return byte(f[1],b,e)
    end
end

function streams.skip(f,n)
    f[2] = f[2] + n
end

function streams.readbyte(f)
    local i = f[2]
    f[2] = i + 1
    return byte(f[1],i)
end

function streams.readbytes(f,n)
    local i = f[2]
    local j = i + n
    f[2] = j
    return byte(f[1],i,j-1)
end

function streams.readbytetable(f,n)
    local i = f[2]
    local j = i + n
    f[2] = j
    return { byte(f[1],i,j-1) }
end

function streams.skipbytes(f,n)
    f[2] = f[2] + n
end

function streams.readchar(f)
    local i = f[2]
    f[2] = i + 1
    return sub(f[1],i,i)
end

function streams.readstring(f,n)
    local i = f[2]
    local j = i + n
    f[2] = j
    return sub(f[1],i,j-1)
end

function streams.readinteger1(f)  -- one byte
    local i = f[2]
    f[2] = i + 1
    local n = byte(f[1],i)
    if n  >= 0x80 then
        return n - 0x100
    else
        return n
    end
end

streams.readcardinal1 = streams.readbyte  -- one byte
streams.readcardinal  = streams.readcardinal1
streams.readinteger   = streams.readinteger1

function streams.readcardinal2(f)
    local i = f[2]
    local j = i + 1
    f[2] = j + 1
    local a, b = byte(f[1],i,j)
    return 0x100 * a + b
end

function streams.readcardinal2le(f)
    local i = f[2]
    local j = i + 1
    f[2] = j + 1
    local b, a = byte(f[1],i,j)
    return 0x100 * a + b
end

function streams.readinteger2(f)
    local i = f[2]
    local j = i + 1
    f[2] = j + 1
    local a, b = byte(f[1],i,j)
    if a >= 0x80 then
        return 0x100 * a + b - 0x10000
    else
        return 0x100 * a + b
    end
end

function streams.readinteger2le(f)
    local i = f[2]
    local j = i + 1
    f[2] = j + 1
    local b, a = byte(f[1],i,j)
    if a >= 0x80 then
        return 0x100 * a + b - 0x10000
    else
        return 0x100 * a + b
    end
end

function streams.readcardinal3(f)
    local i = f[2]
    local j = i + 2
    f[2] = j + 1
    local a, b, c = byte(f[1],i,j)
    return 0x10000 * a + 0x100 * b + c
end

function streams.readcardinal3le(f)
    local i = f[2]
    local j = i + 2
    f[2] = j + 1
    local c, b, a = byte(f[1],i,j)
    return 0x10000 * a + 0x100 * b + c
end

function streams.readinteger3(f)
    local i = f[2]
    local j = i + 3
    f[2] = j + 1
    local a, b, c = byte(f[1],i,j)
    if a >= 0x80 then
        return 0x10000 * a + 0x100 * b + c - 0x1000000
    else
        return 0x10000 * a + 0x100 * b + c
    end
end

function streams.readinteger3le(f)
    local i = f[2]
    local j = i + 3
    f[2] = j + 1
    local c, b, a = byte(f[1],i,j)
    if a >= 0x80 then
        return 0x10000 * a + 0x100 * b + c - 0x1000000
    else
        return 0x10000 * a + 0x100 * b + c
    end
end

function streams.readcardinal4(f)
    local i = f[2]
    local j = i + 3
    f[2] = j + 1
    local a, b, c, d = byte(f[1],i,j)
    return 0x1000000 * a + 0x10000 * b + 0x100 * c + d
end

function streams.readcardinal4le(f)
    local i = f[2]
    local j = i + 3
    f[2] = j + 1
    local d, c, b, a = byte(f[1],i,j)
    return 0x1000000 * a + 0x10000 * b + 0x100 * c + d
end

function streams.readinteger4(f)
    local i = f[2]
    local j = i + 3
    f[2] = j + 1
    local a, b, c, d = byte(f[1],i,j)
    if a >= 0x80 then
        return 0x1000000 * a + 0x10000 * b + 0x100 * c + d - 0x100000000
    else
        return 0x1000000 * a + 0x10000 * b + 0x100 * c + d
    end
end

function streams.readinteger4le(f)
    local i = f[2]
    local j = i + 3
    f[2] = j + 1
    local d, c, b, a = byte(f[1],i,j)
    if a >= 0x80 then
        return 0x1000000 * a + 0x10000 * b + 0x100 * c + d - 0x100000000
    else
        return 0x1000000 * a + 0x10000 * b + 0x100 * c + d
    end
end

function streams.readfixed2(f)
    local i = f[2]
    local j = i + 1
    f[2] = j + 1
    local n1, n2 = byte(f[1],i,j)
    if n1 >= 0x80 then
        n1 = n1 - 0x100
    end
    return n1 + n2/0xFF
end

function streams.readfixed4(f)
    local i = f[2]
    local j = i + 3
    f[2] = j + 1
    local a, b, c, d = byte(f[1],i,j)
    local n1 = 0x100 * a + b
    local n2 = 0x100 * c + d
    if n1 >= 0x8000 then
        n1 = n1 - 0x10000
    end
    return n1 + n2/0xFFFF
end

if bit32 then

    local extract = bit32.extract
    local band    = bit32.band

    function streams.read2dot14(f)
        local i = f[2]
        local j = i + 1
        f[2] = j + 1
        local a, b = byte(f[1],i,j)
        if a >= 0x80 then
            local n = -(0x100 * a + b)
            return - (extract(n,14,2) + (band(n,0x3FFF) / 16384.0))
        else
            local n =   0x100 * a + b
            return   (extract(n,14,2) + (band(n,0x3FFF) / 16384.0))
        end
    end

end

function streams.skipshort(f,n)
    f[2] = f[2] + 2*(n or 1)
end

function streams.skiplong(f,n)
    f[2] = f[2] + 4*(n or 1)
end

if sio and sio.readcardinal2 then

    local readcardinal1  = sio.readcardinal1
    local readcardinal2  = sio.readcardinal2
    local readcardinal3  = sio.readcardinal3
    local readcardinal4  = sio.readcardinal4
    local readinteger1   = sio.readinteger1
    local readinteger2   = sio.readinteger2
    local readinteger3   = sio.readinteger3
    local readinteger4   = sio.readinteger4
    local readfixed2     = sio.readfixed2
    local readfixed4     = sio.readfixed4
    local read2dot14     = sio.read2dot14
    local readbytes      = sio.readbytes
    local readbytetable  = sio.readbytetable

    function streams.readcardinal1(f)
        local i = f[2]
        f[2] = i + 1
        return readcardinal1(f[1],i)
    end
    function streams.readcardinal2(f)
        local i = f[2]
        f[2] = i + 2
        return readcardinal2(f[1],i)
    end
    function streams.readcardinal3(f)
        local i = f[2]
        f[2] = i + 3
        return readcardinal3(f[1],i)
    end
    function streams.readcardinal4(f)
        local i = f[2]
        f[2] = i + 4
        return readcardinal4(f[1],i)
    end
    function streams.readinteger1(f)
        local i = f[2]
        f[2] = i + 1
        return readinteger1(f[1],i)
    end
    function streams.readinteger2(f)
        local i = f[2]
        f[2] = i + 2
        return readinteger2(f[1],i)
    end
    function streams.readinteger3(f)
        local i = f[2]
        f[2] = i + 3
        return readinteger3(f[1],i)
    end
    function streams.readinteger4(f)
        local i = f[2]
        f[2] = i + 4
        return readinteger4(f[1],i)
    end
    function streams.readfixed2(f) -- needs recent luatex
        local i = f[2]
        f[2] = i + 2
        return readfixed2(f[1],i)
    end
    function streams.readfixed4(f) -- needs recent luatex
        local i = f[2]
        f[2] = i + 4
        return readfixed4(f[1],i)
    end
    function streams.read2dot14(f)
        local i = f[2]
        f[2] = i + 2
        return read2dot14(f[1],i)
    end
    function streams.readbytes(f,n)
        local i = f[2]
        local s = f[3]
        local p = i + n
        if p > s then
            f[2] = s + 1
        else
            f[2] = p
        end
        return readbytes(f[1],i,n)
    end
    function streams.readbytetable(f,n)
        local i = f[2]
        local s = f[3]
        local p = i + n
        if p > s then
            f[2] = s + 1
        else
            f[2] = p
        end
        return readbytetable(f[1],i,n)
    end

    streams.readbyte       = streams.readcardinal1
    streams.readsignedbyte = streams.readinteger1
    streams.readcardinal   = streams.readcardinal1
    streams.readinteger    = streams.readinteger1

end

if sio and sio.readcardinaltable then

    local readcardinaltable = sio.readcardinaltable
    local readintegertable  = sio.readintegertable

    function utilities.streams.readcardinaltable(f,n,b)
        local i = f[2]
        local s = f[3]
        local p = i + n * b
        if p > s then
            f[2] = s + 1
        else
            f[2] = p
        end
        return readcardinaltable(f[1],i,n,b)
    end

    function utilities.streams.readintegertable(f,n,b)
        local i = f[2]
        local s = f[3]
        local p = i +  n * b
        if p > s then
            f[2] = s + 1
        else
            f[2] = p
        end
        return readintegertable(f[1],i,n,b)
    end

else

    local readcardinal1 = streams.readcardinal1
    local readcardinal2 = streams.readcardinal2
    local readcardinal3 = streams.readcardinal3
    local readcardinal4 = streams.readcardinal4

    function streams.readcardinaltable(f,n,b)
        local i = f[2]
        local s = f[3]
        local p = i + n * b
        if p > s then
            f[2] = s + 1
        else
            f[2] = p
        end
        local t = { }
            if b == 1 then for i=1,n do t[i] = readcardinal1(f[1],i) end
        elseif b == 2 then for i=1,n do t[i] = readcardinal2(f[1],i) end
        elseif b == 3 then for i=1,n do t[i] = readcardinal3(f[1],i) end
        elseif b == 4 then for i=1,n do t[i] = readcardinal4(f[1],i) end end
        return t
    end

    local readinteger1 = streams.readinteger1
    local readinteger2 = streams.readinteger2
    local readinteger3 = streams.readinteger3
    local readinteger4 = streams.readinteger4

    function streams.readintegertable(f,n,b)
        local i = f[2]
        local s = f[3]
        local p = i + n * b
        if p > s then
            f[2] = s + 1
        else
            f[2] = p
        end
        local t = { }
            if b == 1 then for i=1,n do t[i] = readinteger1(f[1],i) end
        elseif b == 2 then for i=1,n do t[i] = readinteger2(f[1],i) end
        elseif b == 3 then for i=1,n do t[i] = readinteger3(f[1],i) end
        elseif b == 4 then for i=1,n do t[i] = readinteger4(f[1],i) end end
        return t
    end

end

-- For practical reasons we put this here. It's less efficient but ok when we don't
-- have much access.

do

    local files = utilities.files

    if files then

        local openfile     = files.open
        local openstream   = streams.open
        local openstring   = streams.openstring

        local setmetatable = setmetatable

        function io.newreader(str,method)
            local f, m
            if method == "string" then
                f = openstring(str,true)
                m = streams
            elseif method == "stream" then
                f = openstream(str,true)
                m = streams
            else
                f = openfile(str,"rb")
                m = files
            end
            if f then
                local t = { }
                setmetatable(t, {
                    __index = function(t,k)
                        local r = m[k]
                        if k == "close" then
                            -- maybe use __toclose
                            if f then
                                m.close(f)
                                f = nil
                            end
                            return function() end
                        elseif r then
                            local v = function(_,a,b) return r(f,a,b) end
                            t[k] = v
                            return v
                        else
                            print("unknown key",k)
                        end
                    end
                } )
                return t
            end
        end

    end

end

if bit32 and not streams.tocardinal1 then

    local extract = bit32.extract
    local char    = string.char

             streams.tocardinal1           = char
    function streams.tocardinal2(n)   return char(extract(n, 8,8),extract(n, 0,8)) end
    function streams.tocardinal3(n)   return char(extract(n,16,8),extract(n, 8,8),extract(n,0,8)) end
    function streams.tocardinal4(n)   return char(extract(n,24,8),extract(n,16,8),extract(n,8,8),extract(n,0,8)) end

             streams.tocardinal1le         = char
    function streams.tocardinal2le(n) return char(extract(n,0,8),extract(n,8,8)) end
    function streams.tocardinal3le(n) return char(extract(n,0,8),extract(n,8,8),extract(n,16,8)) end
    function streams.tocardinal4le(n) return char(extract(n,0,8),extract(n,8,8),extract(n,16,8),extract(n,24,8)) end

end

if not streams.readcstring then

    local readchar = streams.readchar
    local concat   = table.concat

    function streams.readcstring(f)
        local t = { }
        while true do
            local c = readchar(f)
            if c and c ~= "\0" then
                t[#t+1] = c
            else
                return concat(t)
            end
        end
    end

end
