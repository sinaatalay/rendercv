if not modules then modules = { } end modules ['luat-basics-gen'] = {
    version   = 1.100,
    comment   = "companion to luatex-*.tex",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

if context then
    os.exit()
end

-- We could load a few more of the general context libraries but it would
-- not make plain / latex users more happy I guess. So, we stick to some
-- placeholders.

local match, gmatch, gsub, lower = string.match, string.gmatch, string.gsub, string.lower
local formatters, split, format, dump = string.formatters, string.split, string.format, string.dump
local loadfile, type = loadfile, type
local setmetatable, getmetatable, collectgarbage = setmetatable, getmetatable, collectgarbage
local floor = math.floor

local dummyfunction = function()
end

local dummyreporter = function(c)
    return function(f,...)
        local r = texio.reporter or texio.write_nl
        if f then
            r(c .. " : " .. (formatters or format)(f,...))
        else
            r("")
        end
    end
end

local dummyreport = function(c,f,...)
    local r = texio.reporter or texio.write_nl
    if f then
        r(c .. " : " .. (formatters or format)(f,...))
    else
        r("")
    end
end

statistics = {
    register      = dummyfunction,
    starttiming   = dummyfunction,
    stoptiming    = dummyfunction,
    elapsedtime   = nil,
}

directives = {
    register      = dummyfunction,
    enable        = dummyfunction,
    disable       = dummyfunction,
}

trackers = {
    register      = dummyfunction,
    enable        = dummyfunction,
    disable       = dummyfunction,
}

experiments = {
    register      = dummyfunction,
    enable        = dummyfunction,
    disable       = dummyfunction,
}

storage = { -- probably no longer needed
    register      = dummyfunction,
    shared        = { },
}

logs = {
    new           = dummyreporter,
    reporter      = dummyreporter,
    messenger     = dummyreporter,
    report        = dummyreport,
}

callbacks = {
    register = function(n,f)
        return callback.register(n,f)
    end,
}

utilities = utilities or { }

utilities.storage = utilities.storage or {
    allocate = function(t)
        return t or { }
    end,
    mark     = function(t)
        return t or { }
    end,
}

utilities.parsers = utilities.parsers or {
    -- these are less flexible than in context but ok
    -- for generic purpose
    settings_to_array = function(s)
        return split(s,",")
    end,
    settings_to_hash  = function(s)
        local t = { }
        for k, v in gmatch((gsub(s,"^{(.*)}$", "%1")),"([^%s,=]+)=([^%s,]+)") do
            t[k] = v
        end
        return t
    end,
    settings_to_hash_colon_too  = function(s)
        local t = { }
        for k, v in gmatch((gsub(s,"^{(.*)}$", "%1")),"([^%s,=:]+)[=:]([^%s,]+)") do
            t[k] = v
        end
        return t
    end,
}

characters = characters or {
    data = { }
}

-- we need to cheat a bit here

texconfig.kpse_init = true

resolvers = resolvers or { } -- no fancy file helpers used

local remapper = {
    otf    = "opentype fonts",
    ttf    = "truetype fonts",
    ttc    = "truetype fonts",
    cid    = "cid maps",
    cidmap = "cid maps",
 -- fea    = "font feature files", -- no longer supported
    pfb    = "type1 fonts",        -- needed for vector loading
    afm    = "afm",
    enc    = "enc files",
    lua    = "tex",
}

function resolvers.findfile(name,fileformat)
    name = gsub(name,"\\","/")
    if not fileformat or fileformat == "" then
        fileformat = file.suffix(name)
        if fileformat == "" then
            fileformat = "tex"
        end
    end
    fileformat = lower(fileformat)
    fileformat = remapper[fileformat] or fileformat
    local found = kpse.find_file(name,fileformat)
    if not found or found == "" then
        found = kpse.find_file(name,"other text files")
    end
    return found
end

resolvers.findbinfile = resolvers.findfile

function resolvers.loadbinfile(filename,filetype)
    local data = io.loaddata(filename)
    return true, data, #data
end

function resolvers.resolve(s)
    return s
end

function resolvers.unresolve(s)
    return s
end

-- Caches ... I will make a real stupid version some day when I'm in the
-- mood. After all, the generic code does not need the more advanced
-- ConTeXt features. Cached data is not shared between ConTeXt and other
-- usage as I don't want any dependency at all. Also, ConTeXt might have
-- different needs and tricks added.

--~ containers.usecache = true

caches = { }

local writable  = nil
local readables = { }
local usingjit  = jit

if not caches.namespace or caches.namespace == "" or caches.namespace == "context" then
    caches.namespace = 'generic'
end

do

    -- standard context tree setup

    local cachepaths = kpse.expand_var('$TEXMFCACHE') or ""

    -- quite like tex live or so (the weird $TEXMFCACHE test seems to be needed on miktex)

    if cachepaths == "" or cachepaths == "$TEXMFCACHE" then
        cachepaths = kpse.expand_var('$TEXMFVAR') or ""
    end

    -- this also happened to be used (the weird $TEXMFVAR test seems to be needed on miktex)

    if cachepaths == "" or cachepaths == "$TEXMFVAR" then
        cachepaths = kpse.expand_var('$VARTEXMF') or ""
    end

    -- and this is a last resort (hm, we could use TEMP or TEMPDIR)

    if cachepaths == "" then
        local fallbacks = { "TMPDIR", "TEMPDIR", "TMP", "TEMP", "HOME", "HOMEPATH" }
        for i=1,#fallbacks do
            cachepaths = os.getenv(fallbacks[i]) or ""
            if cachepath ~= "" and lfs.isdir(cachepath) then
                break
            end
        end
    end

    if cachepaths == "" then
        cachepaths = "."
    end

    cachepaths = split(cachepaths,os.type == "windows" and ";" or ":")

    for i=1,#cachepaths do
        local cachepath = cachepaths[i]
        if not lfs.isdir(cachepath) then
            lfs.mkdirs(cachepath) -- needed for texlive and latex
            if lfs.isdir(cachepath) then
                logs.report("system","creating cache path '%s'",cachepath)
            end
        end
        if file.is_writable(cachepath) then
            writable = file.join(cachepath,"luatex-cache")
            lfs.mkdir(writable)
            writable = file.join(writable,caches.namespace)
            lfs.mkdir(writable)
            break
        end
    end

    for i=1,#cachepaths do
        if file.is_readable(cachepaths[i]) then
            readables[#readables+1] = file.join(cachepaths[i],"luatex-cache",caches.namespace)
        end
    end

    if not writable then
        logs.report("system","no writeable cache path, quiting")
        os.exit()
    elseif #readables == 0 then
        logs.report("system","no readable cache path, quiting")
        os.exit()
    elseif #readables == 1 and readables[1] == writable then
        logs.report("system","using cache '%s'",writable)
    else
        logs.report("system","using write cache '%s'",writable)
        logs.report("system","using read cache '%s'",table.concat(readables," "))
    end

end

function caches.getwritablepath(category,subcategory)
    local path = file.join(writable,category)
    lfs.mkdir(path)
    path = file.join(path,subcategory)
    lfs.mkdir(path)
    return path
end

function caches.getreadablepaths(category,subcategory)
    local t = { }
    for i=1,#readables do
        t[i] = file.join(readables[i],category,subcategory)
    end
    return t
end

local function makefullname(path,name)
    if path and path ~= "" then
        return file.addsuffix(file.join(path,name),"lua"), file.addsuffix(file.join(path,name),usingjit and "lub" or "luc")
    end
end

function caches.is_writable(path,name)
    local fullname = makefullname(path,name)
    return fullname and file.is_writable(fullname)
end

function caches.loaddata(readables,name,writable)
    for i=1,#readables do
        local path   = readables[i]
        local loader = false
        local luaname, lucname = makefullname(path,name)
        if lfs.isfile(lucname) then
            logs.report("system","loading luc file '%s'",lucname)
            loader = loadfile(lucname)
        end
        if not loader and lfs.isfile(luaname) then
            -- can be different paths when we read a file database from disk
            local luacrap, lucname = makefullname(writable,name)
            logs.report("system","compiling luc file '%s'",lucname)
            if lfs.isfile(lucname) then
                loader = loadfile(lucname)
            end
            caches.compile(data,luaname,lucname)
            if lfs.isfile(lucname) then
                logs.report("system","loading luc file '%s'",lucname)
                loader = loadfile(lucname)
            else
                logs.report("system","error in loading luc file '%s'",lucname)
            end
            if not loader then
                logs.report("system","loading lua file '%s'",luaname)
                loader = loadfile(luaname)
            else
                logs.report("system","error in loading lua file '%s'",luaname)
            end
        end
        if loader then
            loader = loader()
            collectgarbage("step")
            return loader
        end
    end
    return false
end

function caches.savedata(path,name,data)
    local luaname, lucname = makefullname(path,name)
    if luaname then
        logs.report("system","saving lua file '%s'",luaname)
        table.tofile(luaname,data,true)
        if lucname and type(caches.compile) == "function" then
            os.remove(lucname) -- better be safe
            logs.report("system","saving luc file '%s'",lucname)
            caches.compile(data,luaname,lucname)
        end
    end
end

-- The method here is slightly different from the one we have in context. We
-- also use different suffixes as we don't want any clashes (sharing cache
-- files is not that handy as context moves on faster.)

function caches.compile(data,luaname,lucname)
    local d = io.loaddata(luaname)
    if not d or d == "" then
        d = table.serialize(data,true) -- slow
    end
    if d and d ~= "" then
        local f = io.open(lucname,'wb')
        if f then
            local s = loadstring(d)
            if s then
                f:write(dump(s,true))
            end
            f:close()
        end
    end
end

-- simplfied version:

function table.setmetatableindex(t,f)
    if type(t) ~= "table" then
        f, t = t, { }
    end
    local m = getmetatable(t)
    if f == "table" then
        f = function(t,k) local v = { } t[k] = v return v end
    end
    if m then
        m.__index = f
    else
        setmetatable(t,{ __index = f })
    end
    return t
end

function table.makeweak(t)
    local m = getmetatable(t)
    if m then
        m.__mode = "v"
    else
        setmetatable(t,{ __mode = "v" })
    end
    return t
end

-- helper for plain:

arguments = { }

if arg then
    for i=1,#arg do
        local k, v = match(arg[i],"^%-%-([^=]+)=?(.-)$")
        if k and v then
            arguments[k] = v
        end
    end
end

-- another one

if not number.idiv then
    function number.idiv(i,d)
        return floor(i/d) -- i//d in 5.3
    end
end

-- hook into unicode

local u = unicode and unicode.utf8

if u then

    utf.lower = u.lower
    utf.upper = u.upper
    utf.char  = u.char
    utf.byte  = u.byte
    utf.len   = u.len

    -- needed on font-*

    if lpeg.setutfcasers then
        lpeg.setutfcasers(u.lower,u.upper)
    end

    -- needed on font-otr

    local bytepairs = string.bytepairs
    local utfchar   = utf.char
    local concat    = table.concat

    function utf.utf16_to_utf8_be(s)
        if not s then
            return nil
        elseif s == "" then
            return ""
        end
        local result, r, more = { }, 0, 0
        for left, right in bytepairs(s) do
            if right then
                local now = 256*left + right
                if more > 0 then
                    now = (more-0xD800)*0x400 + (now-0xDC00) + 0x10000
                    more = 0
                    r = r + 1
                    result[r] = utfchar(now)
                elseif now >= 0xD800 and now <= 0xDBFF then
                    more = now
                else
                    r = r + 1
                    result[r] = utfchar(now)
                end
            end
        end
        return concat(result)
    end

    local characters = string.utfcharacters

    function utf.split(str)
        local t, n = { }, 0
        for s in characters(str) do
            n = n + 1
            t[n] = s
        end
        return t
    end

end
