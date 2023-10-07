if not modules then modules = { } end modules ['l-io'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local io = io
local open, flush, write, read = io.open, io.flush, io.write, io.read
local byte, find, gsub, format = string.byte, string.find, string.gsub, string.format
local concat = table.concat
----- floor = math.floor
local type = type

if string.find(os.getenv("PATH") or "",";",1,true) then
    io.fileseparator, io.pathseparator = "\\", ";"
else
    io.fileseparator, io.pathseparator = "/" , ":"
end

-- local function readall(f)
--     return f:read("*all")
-- end

-- The next one is upto 50% faster on large files and less memory consumption due
-- to less intermediate large allocations. This phenomena was discussed on the
-- luatex dev list.

local large  = 0x01000000 -- 2^24 16.777.216
local medium = 0x00100000 -- 2^20  1.048.576
local small  = 0x00020000 -- 2^17    131.072

-- local function readall(f)
--     local size = f:seek("end")
--     if size == 0 then
--         return ""
--     end
--     f:seek("set",0)
--     if size < medium then
--         return f:read('*all')
--     else
--         local step = (size > large) and large or (floor(size/(medium)) * small)
--         local data = { }
--         while true do
--             local r = f:read(step)
--             if not r then
--                 return concat(data)
--             else
--                 data[#data+1] = r
--             end
--         end
--     end
-- end

local function readall(f)
 -- return f:read("*all")
    local size = f:seek("end")
    if size > 0 then
        f:seek("set",0)
        return f:read(size)
    else
        return ""
    end
end

io.readall = readall

function io.loaddata(filename,textmode) -- return nil if empty
    local f = open(filename,(textmode and 'r') or 'rb')
    if f then
        local size = f:seek("end")
        local data = nil
        if size > 0 then
         -- data = f:read("*all")
            f:seek("set",0)
            data = f:read(size)
        end
        f:close()
        return data
    end
end

-- function io.copydata(source,target,action)
--     local f = open(source,"rb")
--     if f then
--         local g = open(target,"wb")
--         if g then
--             local size = f:seek("end")
--             if size == 0 then
--                 -- empty
--             else
--                 f:seek("set",0)
--                 if size < medium then
--                     local data = f:read('*all')
--                     if action then
--                         data = action(data)
--                     end
--                     if data then
--                         g:write(data)
--                     end
--                 else
--                     local step = (size > large) and large or (floor(size/(medium)) * small)
--                     while true do
--                         local data = f:read(step)
--                         if data then
--                             if action then
--                                 data = action(data)
--                             end
--                             if data then
--                                 g:write(data)
--                             end
--                         else
--                             break
--                         end
--                     end
--                 end
--             end
--             g:close()
--         end
--         f:close()
--         flush()
--     end
-- end

function io.copydata(source,target,action)
    local f = open(source,"rb")
    if f then
        local g = open(target,"wb")
        if g then
            local size = f:seek("end")
            if size > 0 then
             -- local data = f:read('*all')
                f:seek("set",0)
                local data = f:read(size)
                if action then
                    data = action(data)
                end
                if data then
                    g:write(data)
                end
            end
            g:close()
        end
        f:close()
        flush()
    end
end

function io.savedata(filename,data,joiner,append)
    local f = open(filename,append and "ab" or "wb")
    if f then
        if append and joiner and f:seek("end") > 0 then
            f:write(joiner)
        end
        if type(data) == "table" then
            f:write(concat(data,joiner or ""))
        elseif type(data) == "function" then
            data(f)
        else
            f:write(data or "")
        end
        f:close()
        flush()
        return true
    else
        return false
    end
end

-- we can also chunk this one if needed: io.lines(filename,chunksize,"*l")

-- ffi.readline

if fio and fio.readline then

    local readline = fio.readline

    function io.loadlines(filename,n) -- return nil if empty
        local f = open(filename,'r')
        if not f then
            -- no file
        elseif n then
            local lines = { }
            for i=1,n do
                local line = readline(f)
                if line then
                    lines[i] = line
                else
                    break
                end
            end
            f:close()
            lines = concat(lines,"\n")
            if #lines > 0 then
                return lines
            end
        else
            local line = readline(f)
            f:close()
            if line and #line > 0 then
                return line
            end
        end
    end

else

    function io.loadlines(filename,n) -- return nil if empty
        local f = open(filename,'r')
        if not f then
            -- no file
        elseif n then
            local lines = { }
            for i=1,n do
                local line = f:read("*lines")
                if line then
                    lines[i] = line
                else
                    break
                end
            end
            f:close()
            lines = concat(lines,"\n")
            if #lines > 0 then
                return lines
            end
        else
            local line = f:read("*line") or ""
            f:close()
            if #line > 0 then
                return line
            end
        end
    end

end

function io.loadchunk(filename,n)
    local f = open(filename,'rb')
    if f then
        local data = f:read(n or 1024)
        f:close()
        if #data > 0 then
            return data
        end
    end
end

function io.exists(filename)
    local f = open(filename)
    if f == nil then
        return false
    else
        f:close()
        return true
    end
end

function io.size(filename)
    local f = open(filename)
    if f == nil then
        return 0
    else
        local s = f:seek("end")
        f:close()
        return s
    end
end

local function noflines(f)
    if type(f) == "string" then
        local f = open(filename)
        if f then
            local n = f and noflines(f) or 0
            f:close()
            return n
        else
            return 0
        end
    else
        -- todo: load and lpeg
        local n = 0
        for _ in f:lines() do
            n = n + 1
        end
        f:seek('set',0)
        return n
    end
end

io.noflines = noflines

-- inlined is faster ... beware, better use util-fil so these are obsolete
-- and will go

local nextchar = {
    [ 4] = function(f)
        return f:read(1,1,1,1)
    end,
    [ 2] = function(f)
        return f:read(1,1)
    end,
    [ 1] = function(f)
        return f:read(1)
    end,
    [-2] = function(f)
        local a, b = f:read(1,1)
        return b, a
    end,
    [-4] = function(f)
        local a, b, c, d = f:read(1,1,1,1)
        return d, c, b, a
    end
}

function io.characters(f,n)
    if f then
        return nextchar[n or 1], f
    end
end

local nextbyte = {
    [4] = function(f)
        local a, b, c, d = f:read(1,1,1,1)
        if d then
            return byte(a), byte(b), byte(c), byte(d)
        end
    end,
    [3] = function(f)
        local a, b, c = f:read(1,1,1)
        if b then
            return byte(a), byte(b), byte(c)
        end
    end,
    [2] = function(f)
        local a, b = f:read(1,1)
        if b then
            return byte(a), byte(b)
        end
    end,
    [1] = function (f)
        local a = f:read(1)
        if a then
            return byte(a)
        end
    end,
    [-2] = function (f)
        local a, b = f:read(1,1)
        if b then
            return byte(b), byte(a)
        end
    end,
    [-3] = function(f)
        local a, b, c = f:read(1,1,1)
        if b then
            return byte(c), byte(b), byte(a)
        end
    end,
    [-4] = function(f)
        local a, b, c, d = f:read(1,1,1,1)
        if d then
            return byte(d), byte(c), byte(b), byte(a)
        end
    end
}

function io.bytes(f,n)
    if f then
        return nextbyte[n or 1], f
    else
        return nil, nil
    end
end

function io.ask(question,default,options)
    while true do
        write(question)
        if options then
            write(format(" [%s]",concat(options,"|")))
        end
        if default then
            write(format(" [%s]",default))
        end
        write(format(" "))
        flush()
        local answer = read()
        answer = gsub(answer,"^%s*(.*)%s*$","%1")
        if answer == "" and default then
            return default
        elseif not options then
            return answer
        else
            for k=1,#options do
                if options[k] == answer then
                    return answer
                end
            end
            local pattern = "^" .. answer
            for k=1,#options do
                local v = options[k]
                if find(v,pattern) then
                    return v
                end
            end
        end
    end
end

local function readnumber(f,n,m) -- to be replaced
    if m then
        f:seek("set",n)
        n = m
    end
    if n == 1 then
        return byte(f:read(1))
    elseif n == 2 then
        local a, b = byte(f:read(2),1,2)
        return 0x100 * a + b
    elseif n == 3 then
        local a, b, c = byte(f:read(3),1,3)
        return 0x10000 * a + 0x100 * b + c
    elseif n == 4 then
        local a, b, c, d = byte(f:read(4),1,4)
        return 0x1000000 * a + 0x10000 * b + 0x100 * c + d
    elseif n == 8 then
        local a, b = readnumber(f,4), readnumber(f,4)
        return 0x100 * a + b
    elseif n == 12 then
        local a, b, c = readnumber(f,4), readnumber(f,4), readnumber(f,4)
        return 0x10000 * a + 0x100 * b + c
    elseif n == -2 then
        local b, a = byte(f:read(2),1,2)
        return 0x100 * a + b
    elseif n == -3 then
        local c, b, a = byte(f:read(3),1,3)
        return 0x10000 * a + 0x100 * b + c
    elseif n == -4 then
        local d, c, b, a = byte(f:read(4),1,4)
        return 0x1000000 * a + 0x10000 * b + 0x100*c + d
    elseif n == -8 then
        local h, g, f, e, d, c, b, a = byte(f:read(8),1,8)
        return 0x100000000000000 * a + 0x1000000000000 * b + 0x10000000000 * c + 0x100000000 * d +
                       0x1000000 * e +         0x10000 * f +         0x100 * g +               h
    else
        return 0
    end
end

io.readnumber = readnumber

function io.readstring(f,n,m)
    if m then
        f:seek("set",n)
        n = m
    end
    local str = gsub(f:read(n),"\000","")
    return str
end

-- This works quite ok:
--
-- function io.piped(command,writer)
--     local pipe = io.popen(command)
--  -- for line in pipe:lines() do
--  --     print(line)
--  -- end
--     while true do
--         local line = pipe:read(1)
--         if not line then
--             break
--         elseif line ~= "\n" then
--             writer(line)
--         end
--     end
--     return pipe:close() -- ok, status, (error)code
-- end
