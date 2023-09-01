if not modules then modules = { } end modules ['l-dir'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- todo: dir.expandname will be sped up and merged with cleanpath and collapsepath
-- todo: keep track of currentdir (chdir, pushdir, popdir)

local type, select = type, select
local find, gmatch, match, gsub, sub = string.find, string.gmatch, string.match, string.gsub, string.sub
local concat, insert, remove, unpack = table.concat, table.insert, table.remove, table.unpack
local lpegmatch = lpeg.match

local P, S, R, C, Cc, Cs, Ct, Cv, V = lpeg.P, lpeg.S, lpeg.R, lpeg.C, lpeg.Cc, lpeg.Cs, lpeg.Ct, lpeg.Cv, lpeg.V

dir = dir or { }
local dir = dir
local lfs = lfs

local attributes = lfs.attributes
----- walkdir    = lfs.dir
local scandir    = lfs.dir
local isdir      = lfs.isdir  -- not robust, will be overloaded anyway
local isfile     = lfs.isfile -- not robust, will be overloaded anyway
local currentdir = lfs.currentdir
local chdir      = lfs.chdir
local mkdir      = lfs.mkdir

local onwindows  = os.type == "windows" or find(os.getenv("PATH"),";",1,true)

-- in case we load outside luatex

if onwindows then

    -- lfs.isdir does not like trailing /
    -- lfs.dir accepts trailing /

    local tricky = S("/\\") * P(-1)

    isdir = function(name)
        if lpegmatch(tricky,name) then
            return attributes(name,"mode") == "directory"
        else
            return attributes(name.."/.","mode") == "directory"
        end
    end

    isfile = function(name)
        return attributes(name,"mode") == "file"
    end

    lfs.isdir  = isdir
    lfs.isfile = isfile

else

    isdir = function(name)
        return attributes(name,"mode") == "directory"
    end

    isfile = function(name)
        return attributes(name,"mode") == "file"
    end

    lfs.isdir  = isdir
    lfs.isfile = isfile

end

-- safeguard

local isreadable = file.isreadable

local walkdir = function(p,...)
    if isreadable(p.."/.") then
        return scandir(p,...)
    else
        return function() end
    end
end

lfs.walkdir = walkdir

-- handy

function dir.current()
    return (gsub(currentdir(),"\\","/"))
end

-- The next one is somewhat optimized but still slow but it's a pitty that the iterator
-- doesn't return a mode too.

local function glob_pattern_function(path,patt,recurse,action)
    if isdir(path) then
        local usedpath
        if path == "/" then
            usedpath = "/."
        elseif not find(path,"/$") then
            usedpath = path .. "/."
            path = path .. "/"
        else
            usedpath = path
        end
        local dirs
        local nofdirs  = 0
        for name, mode, size, time in walkdir(usedpath) do
            if name ~= "." and name ~= ".." then
                local full = path .. name
                if mode == nil then
                    mode = attributes(full,'mode')
                end
                if mode == 'file' then
                    if not patt or find(full,patt) then
                        action(full,size,time)
                    end
                elseif recurse and mode == "directory" then
                    if dirs then
                        nofdirs = nofdirs + 1
                        dirs[nofdirs] = full
                    else
                        nofdirs = 1
                        dirs    = { full }
                    end
                end
            end
        end
        if dirs then
            for i=1,nofdirs do
                glob_pattern_function(dirs[i],patt,recurse,action)
            end
        end
    end
end

local function glob_pattern_table(path,patt,recurse,result)
    if not result then
        result = { }
    end
    local usedpath
    if path == "/" then
        usedpath = "/."
    elseif not find(path,"/$") then
        usedpath = path .. "/."
        path = path .. "/"
    else
        usedpath = path
    end
    local dirs
    local nofdirs  = 0
    local noffiles = #result
    for name, mode in walkdir(usedpath) do
        if name ~= "." and name ~= ".." then
            local full = path .. name
            if mode == nil then
                mode = attributes(full,'mode')
            end
            if mode == 'file' then
                if not patt or find(full,patt) then
                    noffiles = noffiles + 1
                    result[noffiles] = full
                end
            elseif recurse and mode == "directory" then
                if dirs then
                    nofdirs = nofdirs + 1
                    dirs[nofdirs] = full
                else
                    nofdirs = 1
                    dirs    = { full }
                end
            end
        end
    end
    if dirs then
        for i=1,nofdirs do
            glob_pattern_table(dirs[i],patt,recurse,result)
        end
    end
    return result
end

local function globpattern(path,patt,recurse,method)
    local kind = type(method)
    if patt and sub(patt,1,-3) == path then
        patt = false
    end
    local okay = isdir(path)
    if kind == "function" then
        return okay and glob_pattern_function(path,patt,recurse,method) or { }
    elseif kind == "table" then
        return okay and glob_pattern_table(path,patt,recurse,method) or method
    else
        return okay and glob_pattern_table(path,patt,recurse,{ }) or { }
    end
end

dir.globpattern = globpattern

-- never or seldom used so far:

local function collectpattern(path,patt,recurse,result)
    local ok, scanner
    result = result or { }
    if path == "/" then
        ok, scanner, first = xpcall(function() return walkdir(path..".") end, function() end) -- kepler safe
    else
        ok, scanner, first = xpcall(function() return walkdir(path)      end, function() end) -- kepler safe
    end
    if ok and type(scanner) == "function" then
        if not find(path,"/$") then
            path = path .. '/'
        end
        for name in scanner, first do -- can be optimized
            if name == "." then
                -- skip
            elseif name == ".." then
                -- skip
            else
                local full = path .. name
                local attr = attributes(full)
                local mode = attr.mode
                if mode == 'file' then
                    if find(full,patt) then
                        result[name] = attr
                    end
                elseif recurse and mode == "directory" then
                    attr.list = collectpattern(full,patt,recurse)
                    result[name] = attr
                end
            end
        end
    end
    return result
end

dir.collectpattern = collectpattern

local separator, pattern

if onwindows then -- we could sanitize here

    local slash = S("/\\") / "/"

--     pattern = Ct {
    pattern = {
        (Cs(P(".") + slash^1) + Cs(R("az","AZ") * P(":") * slash^0) + Cc("./")) * V(2) * V(3),
        Cs(((1-S("*?/\\"))^0 * slash)^0),
        Cs(P(1)^0)
    }

else -- assume unix

--     pattern = Ct {
    pattern = {
        (C(P(".") + P("/")^1) + Cc("./")) * V(2) * V(3),
        C(((1-S("*?/"))^0 * P("/"))^0),
        C(P(1)^0)
    }

end

local filter = Cs ( (
    P("**") / ".*" +
    P("*")  / "[^/]*" +
    P("?")  / "[^/]" +
    P(".")  / "%%." +
    P("+")  / "%%+" +
    P("-")  / "%%-" +
    P(1)
)^0 )

local function glob(str,t)
    if type(t) == "function" then
        if type(str) == "table" then
            for s=1,#str do
                glob(str[s],t)
            end
        elseif isfile(str) then
            t(str)
        else
            local root, path, base = lpegmatch(pattern,str) -- we could use the file splitter
            if root and path and base then
                local recurse = find(base,"**",1,true) -- find(base,"%*%*")
                local start   = root .. path
                local result  = lpegmatch(filter,start .. base)
                globpattern(start,result,recurse,t)
            end
        end
    else
        if type(str) == "table" then
            local t = t or { }
            for s=1,#str do
                glob(str[s],t)
            end
            return t
        elseif isfile(str) then
            if t then
                t[#t+1] = str
                return t
            else
                return { str }
            end
        else
            local root, path, base = lpegmatch(pattern,str) -- we could use the file splitter
            if root and path and base then
                local recurse = find(base,"**",1,true) -- find(base,"%*%*")
                local start   = root .. path
                local result  = lpegmatch(filter,start .. base)
                return globpattern(start,result,recurse,t)
            else
                return { }
            end
        end
    end
end

dir.glob = glob

-- local c = os.clock()
-- local t = dir.glob("e:/**")
-- local t = dir.glob("t:/sources/**")
-- local t = dir.glob("t:/**")
-- print(os.clock()-c,#t)

-- for i=1,3000 do print(t[i]) end
-- for i=1,10 do print(t[i]) end

-- list = dir.glob("**/*.tif")
-- list = dir.glob("/**/*.tif")
-- list = dir.glob("./**/*.tif")
-- list = dir.glob("oeps/**/*.tif")
-- list = dir.glob("/oeps/**/*.tif")

local function globfiles(path,recurse,func,files) -- func == pattern or function
    if type(func) == "string" then
        local s = func
        func = function(name) return find(name,s) end
    end
    files = files or { }
    local noffiles = #files
    for name, mode in walkdir(path) do
        if find(name,"^%.") then
            --- skip
        else
            if mode == nil then
                mode = attributes(name,'mode')
            end
            if mode == "directory" then
                if recurse then
                    globfiles(path .. "/" .. name,recurse,func,files)
                end
            elseif mode == "file" then
                if not func or func(name) then
                    noffiles = noffiles + 1
                    files[noffiles] = path .. "/" .. name
                end
            end
        end
    end
    return files
end

dir.globfiles = globfiles

local function globdirs(path,recurse,func,files) -- func == pattern or function
    if type(func) == "string" then
        local s = func
        func = function(name) return find(name,s) end
    end
    files = files or { }
    local noffiles = #files
    for name, mode in walkdir(path) do
        if find(name,"^%.") then
            --- skip
        else
            if mode == nil then
                mode = attributes(name,'mode')
            end
            if mode == "directory" then
                if not func or func(name) then
                    noffiles = noffiles + 1
                    files[noffiles] = path .. "/" .. name
                    if recurse then
                        globdirs(path .. "/" .. name,recurse,func,files)
                    end
                end
            end
        end
    end
    return files
end

dir.globdirs = globdirs

-- inspect(globdirs("e:/tmp"))

-- t = dir.glob("c:/data/develop/context/sources/**/????-*.tex")
-- t = dir.glob("c:/data/develop/tex/texmf/**/*.tex")
-- t = dir.glob("c:/data/develop/context/texmf/**/*.tex")
-- t = dir.glob("f:/minimal/tex/**/*")
-- print(dir.ls("f:/minimal/tex/**/*"))
-- print(dir.ls("*.tex"))

function dir.ls(pattern)
    return concat(glob(pattern),"\n")
end

-- mkdirs("temp")
-- mkdirs("a/b/c")
-- mkdirs(".","/a/b/c")
-- mkdirs("a","b","c")

local make_indeed = true -- false

if onwindows then

    function dir.mkdirs(...)
        local n = select("#",...)
        local str
        if n == 1 then
            str = select(1,...)
            if isdir(str) then
                return str, true
            end
        else
            str = ""
            for i=1,n do
                local s = select(i,...)
                if s == "" then
                    -- skip
                elseif str == "" then
                    str = s
                else
                    str = str .. "/" .. s
                end
            end
        end
        local pth = ""
        local drive = false
        local first, middle, last = match(str,"^(//)(//*)(.*)$")
        if first then
            -- empty network path == local path
        else
            first, last = match(str,"^(//)/*(.-)$")
            if first then
                middle, last = match(str,"([^/]+)/+(.-)$")
                if middle then
                    pth = "//" .. middle
                else
                    pth = "//" .. last
                    last = ""
                end
            else
                first, middle, last = match(str,"^([a-zA-Z]:)(/*)(.-)$")
                if first then
                    pth, drive = first .. middle, true
                else
                    middle, last = match(str,"^(/*)(.-)$")
                    if not middle then
                        last = str
                    end
                end
            end
        end
        for s in gmatch(last,"[^/]+") do
            if pth == "" then
                pth = s
            elseif drive then
                pth, drive = pth .. s, false
            else
                pth = pth .. "/" .. s
            end
            if make_indeed and not isdir(pth) then
                mkdir(pth)
            end
        end
        return pth, (isdir(pth) == true)
    end

    -- print(dir.mkdirs("","","a","c"))
    -- print(dir.mkdirs("a"))
    -- print(dir.mkdirs("a:"))
    -- print(dir.mkdirs("a:/b/c"))
    -- print(dir.mkdirs("a:b/c"))
    -- print(dir.mkdirs("a:/bbb/c"))
    -- print(dir.mkdirs("/a/b/c"))
    -- print(dir.mkdirs("/aaa/b/c"))
    -- print(dir.mkdirs("//a/b/c"))
    -- print(dir.mkdirs("///a/b/c"))
    -- print(dir.mkdirs("a/bbb//ccc/"))

else

    function dir.mkdirs(...)
        local n = select("#",...)
        local str, pth
        if n == 1 then
            str = select(1,...)
            if isdir(str) then
                return str, true
            end
        else
            str = ""
            for i=1,n do
                local s = select(i,...)
                if s and s ~= "" then -- we catch nil and false
                    if str ~= "" then
                        str = str .. "/" .. s
                    else
                        str = s
                    end
                end
            end
        end
        str = gsub(str,"/+","/")
        if find(str,"^/") then
            pth = "/"
            for s in gmatch(str,"[^/]+") do
                local first = (pth == "/")
                if first then
                    pth = pth .. s
                else
                    pth = pth .. "/" .. s
                end
                if make_indeed and not first and not isdir(pth) then
                    mkdir(pth)
                end
            end
        else
            pth = "."
            for s in gmatch(str,"[^/]+") do
                pth = pth .. "/" .. s
                if make_indeed and not isdir(pth) then
                    mkdir(pth)
                end
            end
        end
        return pth, (isdir(pth) == true)
    end

    -- print(dir.mkdirs("","","a","c"))
    -- print(dir.mkdirs("a"))
    -- print(dir.mkdirs("/a/b/c"))
    -- print(dir.mkdirs("/aaa/b/c"))
    -- print(dir.mkdirs("//a/b/c"))
    -- print(dir.mkdirs("///a/b/c"))
    -- print(dir.mkdirs("a/bbb//ccc/"))

end

dir.makedirs = dir.mkdirs


do

    -- we can only define it here as it uses dir.chdir and we also need to
    -- make sure we use the non sandboxed variant because otherwise we get
    -- into a recursive loop due to usage of expandname in the file resolver

    local chdir = sandbox and sandbox.original(chdir) or chdir

    if onwindows then

        local xcurrentdir = dir.current

        function dir.expandname(str) -- will be merged with cleanpath and collapsepath\
            local first, nothing, last = match(str,"^(//)(//*)(.*)$")
            if first then
                first = xcurrentdir() .. "/" -- xcurrentdir sanitizes
            end
            if not first then
                first, last = match(str,"^(//)/*(.*)$")
            end
            if not first then
                first, last = match(str,"^([a-zA-Z]:)(.*)$")
                if first and not find(last,"^/") then
                    local d = currentdir() -- push / pop
                    if chdir(first) then
                        first = xcurrentdir() -- xcurrentdir sanitizes
                    end
                    chdir(d)
                end
            end
            if not first then
                first, last = xcurrentdir(), str
            end
            last = gsub(last,"//","/")
            last = gsub(last,"/%./","/")
            last = gsub(last,"^/*","")
            first = gsub(first,"/*$","")
            if last == "" or last == "." then
                return first
            else
                return first .. "/" .. last
            end
        end

    else

        function dir.expandname(str) -- will be merged with cleanpath and collapsepath
            if not find(str,"^/") then
                str = currentdir() .. "/" .. str
            end
            str = gsub(str,"//","/")
            str = gsub(str,"/%./","/")
            str = gsub(str,"(.)/%.$","%1")
            return str
        end

    end

    -- This go there anc check works okay in tricky situation as we encounter
    -- on osx, where tex installations use rather complex chains of links.

    function dir.expandlink(dir,report)
        local curdir = currentdir()
        local trace  = type(report) == "function"
        if chdir(dir) then
            local newdir = currentdir()
            if newdir ~= dir and trace then
                report("following symlink %a to %a",dir,newdir)
            end
            chdir(curdir)
            return newdir
        else
            if trace then
                report("unable to check path %a",dir)
            end
            return dir
        end
    end

end

file.expandname = dir.expandname -- for convenience

local stack = { }

function dir.push(newdir)
    local curdir = currentdir()
    insert(stack,curdir)
    if newdir and newdir ~= "" and chdir(newdir) then
        return newdir
    else
        return curdir
    end
end

function dir.pop()
    local d = remove(stack)
    if d then
        chdir(d)
    end
    return d
end

local function found(...) -- can have nil entries
    for i=1,select("#",...) do
        local path = select(i,...)
        local kind = type(path)
        if kind == "string" then
            if isdir(path) then
                return path
            end
        elseif kind == "table" then
            -- here we asume no holes, i.e. an indexed table
            local path = found(unpack(path))
            if path then
                return path
            end
        end
    end
 -- return nil -- if we want print("crappath") to show something
end

dir.found = found
