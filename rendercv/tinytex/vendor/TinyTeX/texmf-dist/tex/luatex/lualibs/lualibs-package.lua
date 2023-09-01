if not modules then modules = { } end modules ['l-package'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- Code moved from data-lua and changed into a plug-in.

-- We overload the regular loader. We do so because we operate mostly in
-- tds and use our own loader code. Alternatively we could use a more
-- extensive definition of package.path and package.cpath but even then
-- we're not done. Also, we now have better tracing.
--
-- -- local mylib = require("libtest")
-- -- local mysql = require("luasql.mysql")

local type, unpack = type, unpack
local gsub, format, find = string.gsub, string.format, string.find
local insert, remove = table.insert, table.remove

local P, S, Cs, lpegmatch = lpeg.P, lpeg.S, lpeg.Cs, lpeg.match

local package   = package
local searchers = package.searchers or package.loaders

-------.loaders = nil -- old stuff that we don't want
-------.seeall  = nil -- old stuff that we don't want

-- dummies

local filejoin   = file and file.join        or function(path,name)   return path .. "/" .. name end
local isreadable = file and file.is_readable or function(name)        local f = io.open(name) if f then f:close() return true end end
local addsuffix  = file and file.addsuffix   or function(name,suffix) return name .. "." .. suffix end

-- local separator, concatinator, placeholder, pathofexecutable, ignorebefore = string.match(package.config,"(.-)\n(.-)\n(.-)\n(.-)\n(.-)\n")
--
-- local config = {
--     separator        = separator,           -- \ or /
--     concatinator     = concatinator,        -- ;
--     placeholder      = placeholder,         -- ? becomes name
--     pathofexecutable = pathofexecutable,    -- ! becomes executables dir (on windows)
--     ignorebefore     = ignorebefore,        -- - remove all before this when making lua_open
-- }

local function cleanpath(path) -- hm, don't we have a helper for this?
    return path
end

local pattern = Cs((((1-S("\\/"))^0 * (S("\\/")^1/"/"))^0 * (P(".")^1/"/"+P(1))^1) * -1)

local function lualibfile(name)
    return lpegmatch(pattern,name) or name
end

local offset = luarocks and 1 or 0 -- todo: also check other extras ... we'll drop this luarocks anyway

local helpers = package.helpers or {
    cleanpath  = cleanpath,
    lualibfile = lualibfile,
    trace      = false,
    report     = function(...) print(format(...)) end,
    builtin    = {
        ["preload table"]       = searchers[1+offset], -- special case, built-in libs
        ["path specification"]  = searchers[2+offset],
        ["cpath specification"] = searchers[3+offset],
        ["all in one fallback"] = searchers[4+offset], -- special case, combined libs
    },
    methods    = {
    },
    sequence   = {
        "reset loaded",
        "already loaded",
        "preload table",
        "qualified path", -- beware, lua itself doesn't handle qualified paths (prepends ./)
        "lua extra list",
        "lib extra list",
        "path specification",
        "cpath specification",
        "all in one fallback",
        "not loaded",
    }
}

package.helpers  = helpers

local methods = helpers.methods
local builtin = helpers.builtin

-- extra tds/ctx paths ... a bit of overhead for efficient tracing

local extraluapaths = { }
local extralibpaths = { }
local checkedfiles  = { }
local luapaths      = nil -- delayed
local libpaths      = nil -- delayed
local oldluapath    = nil
local oldlibpath    = nil

local nofextralua   = -1
local nofextralib   = -1
local nofpathlua    = -1
local nofpathlib    = -1

local function listpaths(what,paths)
    local nofpaths = #paths
    if nofpaths > 0 then
        for i=1,nofpaths do
            helpers.report("using %s path %i: %s",what,i,paths[i])
        end
    else
        helpers.report("no %s paths defined",what)
    end
    return nofpaths
end

local function getextraluapaths()
    if helpers.trace and #extraluapaths ~= nofextralua then
        nofextralua = listpaths("extra lua",extraluapaths)
    end
    return extraluapaths
end

local function getextralibpaths()
    if helpers.trace and #extralibpaths ~= nofextralib then
        nofextralib = listpaths("extra lib",extralibpaths)
    end
    return extralibpaths
end

local function getluapaths()
    local luapath = package.path or ""
    if oldluapath ~= luapath then
        luapaths   = file.splitpath(luapath,";")
        oldluapath = luapath
        nofpathlua = -1
    end
    if helpers.trace and #luapaths ~= nofpathlua then
        nofpathlua = listpaths("builtin lua",luapaths)
    end
    return luapaths
end

local function getlibpaths()
    local libpath = package.cpath or ""
    if oldlibpath ~= libpath then
        libpaths   = file.splitpath(libpath,";")
        oldlibpath = libpath
        nofpathlib = -1
    end
    if helpers.trace and #libpaths ~= nofpathlib then
        nofpathlib = listpaths("builtin lib",libpaths)
    end
    return libpaths
end

package.luapaths      = getluapaths
package.libpaths      = getlibpaths
package.extraluapaths = getextraluapaths
package.extralibpaths = getextralibpaths

local hashes = {
    lua = { },
    lib = { },
}

local function registerpath(tag,what,target,...)
    local pathlist  = { ... }
    local cleanpath = helpers.cleanpath
    local trace     = helpers.trace
    local report    = helpers.report
    local hash      = hashes[what]
    --
    local function add(path)
        local path = cleanpath(path)
        if not hash[path] then
            target[#target+1] = path
            hash[path]        = true
            if trace then
                report("registered %s path %s: %s",tag,#target,path)
            end
        else
            if trace then
                report("duplicate %s path: %s",tag,path)
            end
        end
    end
    --
    for p=1,#pathlist do
        local path = pathlist[p]
        if type(path) == "table" then
            for i=1,#path do
                add(path[i])
            end
        else
            add(path)
        end
    end
end

local function pushpath(tag,what,target,path)
    local path = helpers.cleanpath(path)
    insert(target,1,path)
    if helpers.trace then
        helpers.report("pushing %s path in front: %s",tag,path)
    end
end

local function poppath(tag,what,target)
    local path = remove(target,1)
    if helpers.trace then
        if path then
            helpers.report("popping %s path from front: %s",tag,path)
        else
            helpers.report("no %s path to pop",tag)
        end
    end
end

helpers.registerpath = registerpath

function package.extraluapath(...)
    registerpath("extra lua","lua",extraluapaths,...)
end
function package.pushluapath(path)
    pushpath("extra lua","lua",extraluapaths,path)
end
function package.popluapath()
    poppath("extra lua","lua",extraluapaths)
end

function package.extralibpath(...)
    registerpath("extra lib","lib",extralibpaths,...)
end
function package.pushlibpath(path)
    pushpath("extra lib","lib",extralibpaths,path)
end
function package.poplibpath()
    poppath("extra lib","lua",extralibpaths)
end

-- lib loader (used elsewhere)

local function loadedaslib(resolved,rawname) -- todo: strip all before first -
    local base = gsub(rawname,"%.","_")
 -- so, we can do a require("foo/bar") and initialize bar
 -- local base = gsub(file.basename(rawname),"%.","_")
    local init = "luaopen_" .. gsub(base,"%.","_")
    local data = { resolved, init, "" }
    checkedfiles[#checkedfiles+1] = data
    if helpers.trace then
        helpers.report("calling loadlib with '%s' with init '%s'",resolved,init)
    end
    local a, b, c = package.loadlib(resolved,init)
    if not a and type(b) == "string" then
--         data[3] = gsub(b or "unknown error","[\n\r]","")
        data[3] = string.fullstrip(b or "unknown error")
    end
    return a, b, c -- c can be 'init'
end

helpers.loadedaslib = loadedaslib

-- wrapped and new loaders

local function loadedbypath(name,rawname,paths,islib,what)
    local trace = helpers.trace
    for p=1,#paths do
        local path     = paths[p]
        local resolved = filejoin(path,name)
        if trace then
            helpers.report("%s path, identifying '%s' on '%s'",what,name,path)
        end
        if isreadable(resolved) then
            if trace then
                helpers.report("%s path, '%s' found on '%s'",what,name,resolved)
            end
            if islib then
                return loadedaslib(resolved,rawname)
            else
                return loadfile(resolved)
            end
        end
    end
end

helpers.loadedbypath = loadedbypath

local function loadedbyname(name,rawname)
    if find(name,"^/") or find(name,"^[a-zA-Z]:/") then
        local trace=helpers.trace
        if trace then
            helpers.report("qualified name, identifying '%s'",what,name)
        end
        if isreadable(name) then
            if trace then
                helpers.report("qualified name, '%s' found",what,name)
            end
            return loadfile(name)
        end
    end
end

helpers.loadedbyname = loadedbyname

methods["reset loaded"] = function(name)
    checkedfiles = { }
    return false
end


methods["already loaded"] = function(name)
    return package.loaded[name]
end

methods["preload table"] = function(name)
    local f = builtin["preload table"]
    if f then
        return f(name)
    end
end

methods["qualified path"]=function(name)
  return loadedbyname(addsuffix(lualibfile(name),"lua"),name)
end

methods["lua extra list"] = function(name)
    return loadedbypath(addsuffix(lualibfile(name),"lua"),name,getextraluapaths(),false,"lua")
end

methods["lib extra list"] = function(name)
    return loadedbypath(addsuffix(lualibfile(name),os.libsuffix),name,getextralibpaths(),true, "lib")
end

methods["path specification"] = function(name)
    local f = builtin["path specification"]
    if f then
        getluapaths() -- triggers list building and tracing
        return f(name)
    end
end

methods["cpath specification"] = function(name)
    local f = builtin["cpath specification"]
    if f then
        getlibpaths() -- triggers list building and tracing
        return f(name)
    end
end

methods["all in one fallback"] = function(name)
    local f = builtin["all in one fallback"]
    if f then
        return f(name)
    end
end

methods["not loaded"] = function(name)
    if helpers.trace then
        helpers.report("unable to locate '%s'",name or "?")
        for i=1,#checkedfiles do
            helpers.report("checked file '%s', initializer '%s', message '%s'",unpack(checkedfiles[i]))
        end
    end
    return nil
end

local level = 0
local used  = { }

helpers.traceused = false

function helpers.loaded(name)
    local sequence = helpers.sequence
    level = level + 1
    for i=1,#sequence do
        local method = sequence[i]
        local lookup = method and methods[method]
        if type(lookup) == "function" then
            if helpers.trace then
                helpers.report("%s, level '%s', method '%s', name '%s'","locating",level,method,name)
            end
            local result, rest = lookup(name)
            if type(result) == "function" then
                if helpers.trace then
                    helpers.report("%s, level '%s', method '%s', name '%s'","found",level,method,name)
                end
                if helpers.traceused then
                    used[#used+1] = { level = level, name = name }
                end
                level = level - 1
                return result, rest
            end
        end
    end
    -- safeguard, we never come here
    level = level - 1
    return nil
end

function helpers.showused()
    local n = #used
    if n > 0 then
        helpers.report("%s libraries loaded:",n)
        helpers.report()
        for i=1,n do
            local u = used[i]
            helpers.report("%i %a",u.level,u.name)
        end
        helpers.report()
     end
end

function helpers.unload(name)
    if helpers.trace then
        if package.loaded[name] then
            helpers.report("unloading, name '%s', %s",name,"done")
        else
            helpers.report("unloading, name '%s', %s",name,"not loaded")
        end
    end
    package.loaded[name] = nil
end

-- overloading require does not work out well so we need to push it in
-- front ..

table.insert(searchers,1,helpers.loaded)

if context then
    package.path = ""
end
