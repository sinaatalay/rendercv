if not modules then modules = { } end modules ['l-file'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- needs a cleanup

file       = file or { }
local file = file

if not lfs then
    lfs = optionalrequire("lfs")
end

-- -- see later
--
-- if not lfs then
--
--     lfs = {
--         getcurrentdir = function()
--             return "."
--         end,
--         attributes = function()
--             return nil
--         end,
--         isfile = function(name)
--             local f = io.open(name,'rb')
--             if f then
--                 f:close()
--                 return true
--             end
--         end,
--         isdir = function(name)
--             print("you need to load lfs")
--             return false
--         end
--     }
--
-- elseif not lfs.isfile then
--
--     local attributes = lfs.attributes
--
--     function lfs.isdir(name)
--         return attributes(name,"mode") == "directory"
--     end
--
--     function lfs.isfile(name)
--         return attributes(name,"mode") == "file"
--     end
--
--  -- function lfs.isdir(name)
--  --     local a = attributes(name)
--  --     return a and a.mode == "directory"
--  -- end
--
--  -- function lfs.isfile(name)
--  --     local a = attributes(name)
--  --     return a and a.mode == "file"
--  -- end
--
-- end

local insert, concat = table.insert, table.concat
local match, find, gmatch = string.match, string.find, string.gmatch
local lpegmatch = lpeg.match
local getcurrentdir, attributes = lfs.currentdir, lfs.attributes
local checkedsplit = string.checkedsplit

local P, R, S, C, Cs, Cp, Cc, Ct = lpeg.P, lpeg.R, lpeg.S, lpeg.C, lpeg.Cs, lpeg.Cp, lpeg.Cc, lpeg.Ct

-- better this way:

local attributes = lfs.attributes

function lfs.isdir(name)
    if name then
        return attributes(name,"mode") == "directory"
    end
end

function lfs.isfile(name)
    if name then
        local a = attributes(name,"mode")
        return a == "file" or a == "link" or nil
    end
end

function lfs.isfound(name)
    if name then
        local a = attributes(name,"mode")
        return (a == "file" or a == "link") and name or nil
    end
end

function lfs.modification(name)
    return name and attributes(name,"modification") or nil
end

if sandbox then
    sandbox.redefine(lfs.isfile,"lfs.isfile")
    sandbox.redefine(lfs.isdir, "lfs.isdir")
    sandbox.redefine(lfs.isfound, "lfs.isfound")
end

local colon     = P(":")
local period    = P(".")
local periods   = P("..")
local fwslash   = P("/")
local bwslash   = P("\\")
local slashes   = S("\\/")
local noperiod  = 1-period
local noslashes = 1-slashes
local name      = noperiod^1
local suffix    = period/"" * (1-period-slashes)^1 * -1

----- pattern = C((noslashes^0 * slashes^1)^1)
local pattern = C((1 - (slashes^1 * noslashes^1 * -1))^1) * P(1) -- there must be a more efficient way

local function pathpart(name,default)
    return name and lpegmatch(pattern,name) or default or ""
end

local pattern = (noslashes^0 * slashes)^1 * C(noslashes^1) * -1

local function basename(name)
    return name and lpegmatch(pattern,name) or name
end

-- print(pathpart("file"))
-- print(pathpart("dir/file"))
-- print(pathpart("/dir/file"))
-- print(basename("file"))
-- print(basename("dir/file"))
-- print(basename("/dir/file"))

local pattern = (noslashes^0 * slashes^1)^0 * Cs((1-suffix)^1) * suffix^0

local function nameonly(name)
    return name and lpegmatch(pattern,name) or name
end

local pattern = (noslashes^0 * slashes)^0 * (noperiod^1 * period)^1 * C(noperiod^1) * -1

local function suffixonly(name)
    return name and lpegmatch(pattern,name) or ""
end

local pattern = (noslashes^0 * slashes)^0 * noperiod^1 * ((period * C(noperiod^1))^1) * -1 + Cc("")

local function suffixesonly(name)
    if name then
        return lpegmatch(pattern,name)
    else
        return ""
    end
end

file.pathpart     = pathpart
file.basename     = basename
file.nameonly     = nameonly
file.suffixonly   = suffixonly
file.suffix       = suffixonly
file.suffixesonly = suffixesonly
file.suffixes     = suffixesonly

file.dirname      = pathpart   -- obsolete
file.extname      = suffixonly -- obsolete

-- actually these are schemes

local drive  = C(R("az","AZ")) * colon
local path   = C((noslashes^0 * slashes)^0)
local suffix = period * C(P(1-period)^0 * P(-1))
local base   = C((1-suffix)^0)
local rest   = C(P(1)^0)

drive  = drive  + Cc("")
path   = path   + Cc("")
base   = base   + Cc("")
suffix = suffix + Cc("")

local pattern_a =   drive * path  *   base * suffix
local pattern_b =           path  *   base * suffix
local pattern_c = C(drive * path) * C(base * suffix) -- trick: two extra captures
local pattern_d =           path  *   rest

function file.splitname(str,splitdrive)
    if not str then
        -- error
    elseif splitdrive then
        return lpegmatch(pattern_a,str) -- returns drive, path, base, suffix
    else
        return lpegmatch(pattern_b,str) -- returns path, base, suffix
    end
end

function file.splitbase(str)
    if str then
        return lpegmatch(pattern_d,str) -- returns path, base+suffix (path has / appended, might change at some point)
    else
        return "", str -- assume no path
    end
end

---- stripslash = C((1 - P("/")^1*P(-1))^0)

function file.nametotable(str,splitdrive)
    if str then
        local path, drive, subpath, name, base, suffix = lpegmatch(pattern_c,str)
     -- if path ~= "" then
     --     path = lpegmatch(stripslash,path) -- unfortunate hack, maybe this becomes default
     -- end
        if splitdrive then
            return {
                path    = path,
                drive   = drive,
                subpath = subpath,
                name    = name,
                base    = base,
                suffix  = suffix,
            }
        else
            return {
                path    = path,
                name    = name,
                base    = base,
                suffix  = suffix,
            }
        end
    end
end

-- print(file.splitname("file"))
-- print(file.splitname("dir/file"))
-- print(file.splitname("/dir/file"))
-- print(file.splitname("file"))
-- print(file.splitname("dir/file"))
-- print(file.splitname("/dir/file"))

-- inspect(file.nametotable("file.ext"))
-- inspect(file.nametotable("dir/file.ext"))
-- inspect(file.nametotable("/dir/file.ext"))
-- inspect(file.nametotable("file.ext"))
-- inspect(file.nametotable("dir/file.ext"))
-- inspect(file.nametotable("/dir/file.ext"))

----- pattern = Cs(((period * noperiod^1 * -1) / "" + 1)^1)
local pattern = Cs(((period * (1-period-slashes)^1 * -1) / "" + 1)^1)

function file.removesuffix(name)
    return name and lpegmatch(pattern,name)
end

-- local pattern = (noslashes^0 * slashes)^0 * (noperiod^1 * period)^1 * Cp() * noperiod^1 * -1
--
-- function file.addsuffix(name, suffix)
--     local p = lpegmatch(pattern,name)
--     if p then
--         return name
--     else
--         return name .. "." .. suffix
--     end
-- end

local suffix  = period/"" * (1-period-slashes)^1 * -1
local pattern = Cs((noslashes^0 * slashes^1)^0 * ((1-suffix)^1)) * Cs(suffix)

function file.addsuffix(filename,suffix,criterium)
    if not filename or not suffix or suffix == "" then
        return filename
    elseif criterium == true then
        return filename .. "." .. suffix
    elseif not criterium then
        local n, s = lpegmatch(pattern,filename)
        if not s or s == "" then
            return filename .. "." .. suffix
        else
            return filename
        end
    else
        local n, s = lpegmatch(pattern,filename)
        if s and s ~= "" then
            local t = type(criterium)
            if t == "table" then
                -- keep if in criterium
                for i=1,#criterium do
                    if s == criterium[i] then
                        return filename
                    end
                end
            elseif t == "string" then
                -- keep if criterium
                if s == criterium then
                    return filename
                end
            end
        end
        return (n or filename) .. "." .. suffix
    end
end

-- print("1 " .. file.addsuffix("name","new")                   .. " -> name.new")
-- print("2 " .. file.addsuffix("name.old","new")               .. " -> name.old")
-- print("3 " .. file.addsuffix("name.old","new",true)          .. " -> name.old.new")
-- print("4 " .. file.addsuffix("name.old","new","new")         .. " -> name.new")
-- print("5 " .. file.addsuffix("name.old","new","old")         .. " -> name.old")
-- print("6 " .. file.addsuffix("name.old","new","foo")         .. " -> name.new")
-- print("7 " .. file.addsuffix("name.old","new",{"foo","bar"}) .. " -> name.new")
-- print("8 " .. file.addsuffix("name.old","new",{"old","bar"}) .. " -> name.old")

local suffix  = period * (1-period-slashes)^1 * -1
local pattern = Cs((1-suffix)^0)

function file.replacesuffix(name,suffix)
    if name and suffix and suffix ~= "" then
        return lpegmatch(pattern,name) .. "." .. suffix
    else
        return name
    end
end

--

local reslasher = lpeg.replacer(P("\\"),"/")

function file.reslash(str)
    return str and lpegmatch(reslasher,str)
end

-- We should be able to use:
--
-- local writable = P(1) * P("w") * Cc(true)
--
-- function file.is_writable(name)
--     local a = attributes(name) or attributes(pathpart(name,"."))
--     return a and lpegmatch(writable,a.permissions) or false
-- end
--
-- But after some testing Taco and I came up with the more robust
-- variant:

if lfs.isreadablefile and lfs.iswritablefile then

    file.is_readable = lfs.isreadablefile
    file.is_writable = lfs.iswritablefile

else

    function file.is_writable(name)
        if not name then
            -- error
        elseif lfs.isdir(name) then
            name = name .. "/m_t_x_t_e_s_t.tmp"
            local f = io.open(name,"wb")
            if f then
                f:close()
                os.remove(name)
                return true
            end
        elseif lfs.isfile(name) then
            local f = io.open(name,"ab")
            if f then
                f:close()
                return true
            end
        else
            local f = io.open(name,"ab")
            if f then
                f:close()
                os.remove(name)
                return true
            end
        end
        return false
    end

    local readable = P("r") * Cc(true)

    function file.is_readable(name)
        if name then
            local a = attributes(name)
            return a and lpegmatch(readable,a.permissions) or false
        else
            return false
        end
    end

end

file.isreadable = file.is_readable -- depricated
file.iswritable = file.is_writable -- depricated

function file.size(name)
    if name then
        local a = attributes(name)
        return a and a.size or 0
    else
        return 0
    end
end

function file.splitpath(str,separator) -- string .. reslash is a bonus (we could do a direct split)
    return str and checkedsplit(lpegmatch(reslasher,str),separator or io.pathseparator)
end

function file.joinpath(tab,separator) -- table
    return tab and concat(tab,separator or io.pathseparator) -- can have trailing //
end

local someslash = S("\\/")
local stripper  = Cs(P(fwslash)^0/"" * reslasher)
local isnetwork = someslash * someslash * (1-someslash)
                + (1-fwslash-colon)^1 * colon
local isroot    = fwslash^1 * -1
local hasroot   = fwslash^1

local reslasher = lpeg.replacer(S("\\/"),"/")
local deslasher = lpeg.replacer(S("\\/")^1,"/")

-- If we have a network or prefix then there is a change that we end up with two
-- // in the middle ... we could prevent this if we (1) expand prefixes: and (2)
-- split and rebuild as url. Of course we could assume no network paths (which
-- makes sense) adn assume either mapped drives (windows) or mounts (unix) but
-- then we still have to deal with urls ... anyhow, multiple // are never a real
-- problem but just ugly.

-- function file.join(...)
--     local lst = { ... }
--     local one = lst[1]
--     if lpegmatch(isnetwork,one) then
--         local one = lpegmatch(reslasher,one)
--         local two = lpegmatch(deslasher,concat(lst,"/",2))
--         if lpegmatch(hasroot,two) then
--             return one .. two
--         else
--             return one .. "/" .. two
--         end
--     elseif lpegmatch(isroot,one) then
--         local two = lpegmatch(deslasher,concat(lst,"/",2))
--         if lpegmatch(hasroot,two) then
--             return two
--         else
--             return "/" .. two
--         end
--     elseif one == "" then
--         return lpegmatch(stripper,concat(lst,"/",2))
--     else
--         return lpegmatch(deslasher,concat(lst,"/"))
--     end
-- end

function file.join(one, two, three, ...)
    if not two then
        return one == "" and one or lpegmatch(reslasher,one)
    end
    if not one or one == "" then
        return lpegmatch(stripper,three and concat({ two, three, ... },"/") or two)
    end
    if lpegmatch(isnetwork,one) then
        local one = lpegmatch(reslasher,one)
        local two = lpegmatch(deslasher,three and concat({ two, three, ... },"/") or two)
        if lpegmatch(hasroot,two) then
            return one .. two
        else
            return one .. "/" .. two
        end
    elseif lpegmatch(isroot,one) then
        local two = lpegmatch(deslasher,three and concat({ two, three, ... },"/") or two)
        if lpegmatch(hasroot,two) then
            return two
        else
            return "/" .. two
        end
    else
        return lpegmatch(deslasher,concat({  one, two, three, ... },"/"))
    end
end

-- or we can use this:
--
-- function file.join(...)
--     local n = select("#",...)
--     local one = select(1,...)
--     if n == 1 then
--         return one == "" and one or lpegmatch(stripper,one)
--     end
--     if one == "" then
--         return lpegmatch(stripper,n > 2 and concat({ ... },"/",2) or select(2,...))
--     end
--     if lpegmatch(isnetwork,one) then
--         local one = lpegmatch(reslasher,one)
--         local two = lpegmatch(deslasher,n > 2 and concat({ ... },"/",2) or select(2,...))
--         if lpegmatch(hasroot,two) then
--             return one .. two
--         else
--             return one .. "/" .. two
--         end
--     elseif lpegmatch(isroot,one) then
--         local two = lpegmatch(deslasher,n > 2 and concat({ ... },"/",2) or select(2,...))
--         if lpegmatch(hasroot,two) then
--             return two
--         else
--             return "/" .. two
--         end
--     else
--         return lpegmatch(deslasher,concat({ ... },"/"))
--     end
-- end

-- print(file.join("c:/whatever"))
-- print(file.join("c:/whatever","name"))
-- print(file.join("//","/y"))
-- print(file.join("/","/y"))
-- print(file.join("","/y"))
-- print(file.join("/x/","/y"))
-- print(file.join("x/","/y"))
-- print(file.join("http://","/y"))
-- print(file.join("http://a","/y"))
-- print(file.join("http:///a","/y"))
-- print(file.join("//nas-1","/y"))
-- print(file.join("//nas-1/a/b/c","/y"))
-- print(file.join("\\\\nas-1\\a\\b\\c","\\y"))

-- The previous one fails on "a.b/c"  so Taco came up with a split based
-- variant. After some skyping we got it sort of compatible with the old
-- one. After that the anchoring to currentdir was added in a better way.
-- Of course there are some optimizations too. Finally we had to deal with
-- windows drive prefixes and things like sys://. Eventually gsubs and
-- finds were replaced by lpegs.

local drivespec    = R("az","AZ")^1 * colon
local anchors      = fwslash
                   + drivespec
local untouched    = periods
                   + (1-period)^1 * P(-1)
local mswindrive   = Cs(drivespec * (bwslash/"/" + fwslash)^0)
local mswinuncpath = (bwslash + fwslash) * (bwslash + fwslash) * Cc("//")
local splitstarter = (mswindrive + mswinuncpath + Cc(false))
                   * Ct(lpeg.splitat(S("/\\")^1))
local absolute     = fwslash

function file.collapsepath(str,anchor) -- anchor: false|nil, true, "."
    if not str then
        return
    end
    if anchor == true and not lpegmatch(anchors,str) then
        str = getcurrentdir() .. "/" .. str
    end
    if str == "" or str =="." then
        return "."
    elseif lpegmatch(untouched,str) then
        return lpegmatch(reslasher,str)
    end
    local starter, oldelements = lpegmatch(splitstarter,str)
    local newelements = { }
    local i = #oldelements
    while i > 0 do
        local element = oldelements[i]
        if element == '.' then
            -- do nothing
        elseif element == '..' then
            local n = i - 1
            while n > 0 do
                local element = oldelements[n]
                if element ~= '..' and element ~= '.' then
                    oldelements[n] = '.'
                    break
                else
                    n = n - 1
                end
             end
            if n < 1 then
               insert(newelements,1,'..')
            end
        elseif element ~= "" then
            insert(newelements,1,element)
        end
        i = i - 1
    end
    if #newelements == 0 then
        return starter or "."
    elseif starter then
        return starter .. concat(newelements, '/')
    elseif lpegmatch(absolute,str) then
        return "/" .. concat(newelements,'/')
    else
        newelements = concat(newelements, '/')
        if anchor == "." and find(str,"^%./") then
            return "./" .. newelements
        else
            return newelements
        end
    end
end

-- local function test(str,...)
--    print(string.format("%-20s %-15s %-30s %-20s",str,file.collapsepath(str),file.collapsepath(str,true),file.collapsepath(str,".")))
-- end
-- test("a/b.c/d") test("b.c/d") test("b.c/..")
-- test("/") test("c:/..") test("sys://..")
-- test("") test("./") test(".") test("..") test("./..") test("../..")
-- test("a") test("./a") test("/a") test("a/../..")
-- test("a/./b/..") test("a/aa/../b/bb") test("a/.././././b/..") test("a/./././b/..")
-- test("a/b/c/../..") test("./a/b/c/../..") test("a/b/c/../..")
-- test("./a")
-- test([[\\a.b.c\d\e]])

local validchars = R("az","09","AZ","--","..")
local pattern_a  = lpeg.replacer(1-validchars)
local pattern_a  = Cs((validchars + P(1)/"-")^1)
local whatever   = P("-")^0 / ""
local pattern_b  = Cs(whatever * (1 - whatever * -1)^1)

function file.robustname(str,strict)
    if str then
        str = lpegmatch(pattern_a,str) or str
        if strict then
            return lpegmatch(pattern_b,str) or str -- two step is cleaner (less backtracking)
        else
            return str
        end
    end
end

local loaddata = io.loaddata
local savedata = io.savedata

file.readdata  = loaddata
file.savedata  = savedata

function file.copy(oldname,newname)
    if oldname and newname then
        local data = loaddata(oldname)
        if data and data ~= "" then
            savedata(newname,data)
        end
    end
end

-- also rewrite previous

local letter    = R("az","AZ") + S("_-+")
local separator = P("://")

local qualified = period^0 * fwslash
                + letter   * colon
                + letter^1 * separator
                + letter^1 * fwslash
local rootbased = fwslash
                + letter * colon

lpeg.patterns.qualified = qualified
lpeg.patterns.rootbased = rootbased

-- ./name ../name  /name c: :// name/name

function file.is_qualified_path(filename)
    return filename and lpegmatch(qualified,filename) ~= nil
end

function file.is_rootbased_path(filename)
    return filename and lpegmatch(rootbased,filename) ~= nil
end

-- function test(t) for k, v in next, t do print(v, "=>", file.splitname(v)) end end
--
-- test { "c:", "c:/aa", "c:/aa/bb", "c:/aa/bb/cc", "c:/aa/bb/cc.dd", "c:/aa/bb/cc.dd.ee" }
-- test { "c:", "c:aa", "c:aa/bb", "c:aa/bb/cc", "c:aa/bb/cc.dd", "c:aa/bb/cc.dd.ee" }
-- test { "/aa", "/aa/bb", "/aa/bb/cc", "/aa/bb/cc.dd", "/aa/bb/cc.dd.ee" }
-- test { "aa", "aa/bb", "aa/bb/cc", "aa/bb/cc.dd", "aa/bb/cc.dd.ee" }

-- -- maybe:
--
-- if os.type == "windows" then
--     local currentdir = getcurrentdir
--     function getcurrentdir()
--         return lpegmatch(reslasher,currentdir())
--     end
-- end

-- for myself:

function file.strip(name,dir)
    if name then
        local b, a = match(name,"^(.-)" .. dir .. "(.*)$")
        return a ~= "" and a or name
    end
end

-- local debuglist = {
--     "pathpart", "basename", "nameonly", "suffixonly", "suffix", "dirname", "extname",
--     "addsuffix", "removesuffix", "replacesuffix", "join",
--     "strip","collapsepath", "joinpath", "splitpath",
-- }

-- for i=1,#debuglist do
--     local name = debuglist[i]
--     local f = file[name]
--     file[name] = function(...)
--         print(name,f(...))
--         return f(...)
--     end
-- end

-- a goodie: a dumb version of mkdirs (not used in context itself, only
-- in generic usage)

function lfs.mkdirs(path)
    local full = ""
    for sub in gmatch(path,"(/*[^\\/]+)") do -- accepts leading c: and /
        full = full .. sub
        -- lfs.isdir("/foo") mistakenly returns true on windows so
        -- so we don't test and just make as that one is not too picky
        lfs.mkdir(full)
    end
end

-- here is oen i ran into when messign around with xavante code (keppler project)
-- where it's called in_base .. no gain in using lpeg here

function file.withinbase(path) -- don't go beyond root
    local l = 0
    if not find(path,"^/") then
        path = "/" .. path
    end
    for dir in gmatch(path,"/([^/]+)") do
        if dir == ".." then
            l = l - 1
        elseif dir ~= "." then
            l = l + 1
        end
        if l < 0 then
            return false
        end
    end
    return true
end

-- not used in context but was in luatex once:

do

    local symlinktarget     = lfs.symlinktarget     -- luametatex (always returns string)
    local symlinkattributes = lfs.symlinkattributes -- luatex     (can return nil)

    if symlinktarget then
        function lfs.readlink(name)
            local target = symlinktarget(name)
            return name ~= target and name or nil
        end
    elseif symlinkattributes then
        function lfs.readlink(name)
            return symlinkattributes(name,"target") or nil
        end
    else
        function lfs.readlink(name)
            return nil
        end
    end

end
