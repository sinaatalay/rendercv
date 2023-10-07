if not modules then modules = { } end modules ['l-os'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- This file deals with some operating system issues. Please don't bother me
-- with the pros and cons of operating systems as they all have their flaws
-- and benefits. Bashing one of them won't help solving problems and fixing
-- bugs faster and is a waste of time and energy.
--
-- path separators: / or \ ... we can use / everywhere
-- suffixes       : dll so exe <none> ... no big deal
-- quotes         : we can use "" in most cases
-- expansion      : unless "" are used * might give side effects
-- piping/threads : somewhat different for each os
-- locations      : specific user file locations and settings can change over time
--
-- os.type     : windows | unix (new, we already guessed os.platform)
-- os.name     : windows | msdos | linux | macosx | solaris | .. | generic (new)
-- os.platform : extended os.name with architecture

-- os.sleep() => socket.sleep()
-- math.randomseed(tonumber(string.sub(string.reverse(tostring(math.floor(socket.gettime()*10000))),1,6)))

local os = os
local date, time, difftime = os.date, os.time, os.difftime
local find, format, gsub, upper, gmatch = string.find, string.format, string.gsub, string.upper, string.gmatch
local concat = table.concat
local random, ceil, randomseed, modf = math.random, math.ceil, math.randomseed, math.modf
local type, setmetatable, tonumber, tostring = type, setmetatable, tonumber, tostring

-- This check needs to happen real early on. Todo: we can pick it up from the commandline
-- if we pass --binpath= (which is useful anyway)

do

    local selfdir = os.selfdir

    if selfdir == "" then
        selfdir = nil
    end

    if not selfdir then

        -- We need a fallback plan so let's see what we get.

        if arg then
            -- passed by mtx-context ... saves network access
            for i=1,#arg do
                local a = arg[i]
                if find(a,"^%-%-[c:]*texmfbinpath=") then
                    selfdir = gsub(a,"^.-=","")
                    break
                end
            end
        end

        if not selfdir then
            selfdir = os.selfbin or "luatex"
            if find(selfdir,"[/\\]") then
                selfdir = gsub(selfdir,"[/\\][^/\\]*$","")
            elseif os.getenv then
                local path = os.getenv("PATH")
                local name = gsub(selfdir,"^.*[/\\][^/\\]","")
                local patt = "[^:]+"
                if os.type == "windows" then
                    patt = "[^;]+"
                    name = name .. ".exe"
                end
                local isfile
                if lfs then
                    -- we're okay as lfs is assumed present
                    local attributes = lfs.attributes
                    isfile = function(name)
                        local a = attributes(name,"mode")
                        return a == "file" or a == "link" or nil
                    end
                else
                    -- we're not okay and much will not work as we miss lfs
                    local open = io.open
                    isfile = function(name)
                        local f = open(name)
                        if f then
                            f:close()
                            return true
                        end
                    end
                end
                for p in gmatch(path,patt) do
                    -- possible speedup: there must be tex in 'p'
                    if isfile(p .. "/" .. name) then
                        selfdir = p
                        break
                    end
                end
            end
        end

        -- let's hope we're okay now

        os.selfdir = selfdir or "."

    end

    -- print(os.selfdir) os.exit()

end

-- The following code permits traversing the environment table, at least in luatex. Internally all
-- environment names are uppercase.

-- The randomseed in Lua is not that random, although this depends on the operating system as well
-- as the binary (Luatex is normally okay). But to be sure we set the seed anyway. It will be better
-- in Lua 5.4 (according to the announcements.)

math.initialseed = tonumber(string.sub(string.reverse(tostring(ceil(socket and socket.gettime()*10000 or time()))),1,6))

randomseed(math.initialseed)

if not os.__getenv__ then

    os.__getenv__ = os.getenv
    os.__setenv__ = os.setenv

    if os.env then

        local osgetenv  = os.getenv
        local ossetenv  = os.setenv
        local osenv     = os.env      local _ = osenv.PATH -- initialize the table

        function os.setenv(k,v)
            if v == nil then
                v = ""
            end
            local K = upper(k)
            osenv[K] = v
            if type(v) == "table" then
                v = concat(v,";") -- path
            end
            ossetenv(K,v)
        end

        function os.getenv(k)
            local K = upper(k)
            local v = osenv[K] or osenv[k] or osgetenv(K) or osgetenv(k)
            if v == "" then
                return nil
            else
                return v
            end
        end

    else

        local ossetenv  = os.setenv
        local osgetenv  = os.getenv
        local osenv     = { }

        function os.setenv(k,v)
            if v == nil then
                v = ""
            end
            local K = upper(k)
            osenv[K] = v
        end

        function os.getenv(k)
            local K = upper(k) -- hm utf
            local v = osenv[K] or osgetenv(K) or osgetenv(k)
            if v == "" then
                return nil
            else
                return v
            end
        end

        local function __index(t,k)
            return os.getenv(k)
        end
        local function __newindex(t,k,v)
            os.setenv(k,v)
        end

        os.env = { }

        setmetatable(os.env, { __index = __index, __newindex = __newindex } )

    end

end

-- end of environment hack

if not io.fileseparator then

    if find(os.getenv("PATH"),";",1,true) then
        io.fileseparator, io.pathseparator, os.type = "\\", ";", os.type or "windows"
    else
        io.fileseparator, io.pathseparator, os.type = "/" , ":", os.type or "unix"
    end

end

os.type = os.type or (io.pathseparator == ";"       and "windows") or "unix"
os.name = os.name or (os.type          == "windows" and "mswin"  ) or "linux"

if os.type == "windows" then
    os.libsuffix, os.binsuffix, os.binsuffixes = 'dll', 'exe', { 'exe', 'cmd', 'bat' }
else
    os.libsuffix, os.binsuffix, os.binsuffixes = 'so', '', { '' }
end

do

    local execute = os.execute
    local iopopen = io.popen
    local ostype  = os.type

    local function resultof(command)
        -- already has flush, b is new and we need it to pipe xz output
        local handle = iopopen(command,ostype == "windows" and "rb" or "r")
        if handle then
            local result = handle:read("*all") or ""
            handle:close()
            return result
        else
            return ""
        end
    end

    os.resultof = resultof

    function os.pipeto(command)
        return iopopen(command,"w") -- already has flush
    end

    local launchers = {
        windows = "start %s",
        macosx  = "open %s",
        unix    = "xdg-open %s &> /dev/null &",
    }

    function os.launch(str)
        local command = format(launchers[os.name] or launchers.unix,str)
        -- todo: pcall
    --     print(command)
        execute(command)
    end

end

do

    local gettimeofday = os.gettimeofday or os.clock
    os.gettimeofday    = gettimeofday

    local startuptime = gettimeofday()

    function os.runtime()
        return gettimeofday() - startuptime
    end

    -- print(os.gettimeofday()-os.time())
    -- os.sleep(1.234)
    -- print (">>",os.runtime())
    -- print(os.date("%H:%M:%S",os.gettimeofday()))
    -- print(os.date("%H:%M:%S",os.time()))

end

-- We can use HOSTTYPE on some platforms (but not consistently on e.g. Linux).
--
-- os.bits = 32 | 64
--
-- os.uname() : return {
--     machine  = "x86_64",
--     nodename = "MYLAPTOP",
--     release  = "build 9200",
--     sysname  = "Windows",
--     version  = "6.02",
-- }

do

    local name         = os.name or "linux"
    local platform     = os.getenv("MTX_PLATFORM") or ""
    local architecture = os.uname and os.uname().machine -- lmtx
    local bits         = os.getenv("MTX_BITS") or find(platform,"64") and 64 or 32

    if platform ~= "" then

        -- we're okay already

    elseif os.type == "windows" then

        -- PROCESSOR_ARCHITECTURE : binary platform
        -- PROCESSOR_ARCHITEW6432 : OS platform

        architecture = string.lower(architecture or os.getenv("PROCESSOR_ARCHITECTURE") or "")
        if architecture == "x86_64" then
            bits, platform = 64, "win64"
        elseif find(architecture,"amd64") then
            bits, platform = 64, "win64"
        elseif find(architecture,"arm64") then
            bits, platform = 64, "windows-arm64"
        elseif find(architecture,"arm32") then
            bits, platform = 32, "windows-arm32"
        else
            bits, platform = 32, "mswin"
        end

    elseif name == "linux" then

        -- There is no way to detect if musl is used because there is no __MUSL__
        -- and it looks like there never will be. Folks don't care about cases where
        -- one ships multipe binaries (as with TeX distibutions) and want to select
        -- the right one. So probably it expects users to compile locally in which
        -- case we don't care to much as they can then sort it out.

        architecture = architecture or os.getenv("HOSTTYPE") or resultof("uname -m") or ""
        local musl = find(os.selfdir or "","linuxmusl")
        if find(architecture,"x86_64") then
            bits, platform = 64, musl and "linuxmusl" or "linux-64"
        elseif find(architecture,"ppc") then
            bits, platform = 32, "linux-ppc" -- this will be dropped
        else
            bits, platform = 32, musl and "linuxmusl" or "linux"
        end

    elseif name == "macosx" then

        -- Identifying the architecture of OSX is quite a mess and this is the best
        -- we can come up with. For some reason $HOSTTYPE is a kind of pseudo
        -- environment variable, not known to the current environment. And yes,
        -- uname cannot be trusted either, so there is a change that you end up with
        -- a 32 bit run on a 64 bit system. Also, some proper 64 bit intel macs are
        -- too cheap (low-end) and therefore not permitted to run the 64 bit kernel.

        architecture = architecture or resultof("echo $HOSTTYPE") or ""
        if architecture == "" then
            bits, platform = 64, "osx-intel"
        elseif find(architecture,"i386") then
            bits, platform = 64, "osx-intel"
        elseif find(architecture,"x86_64") then
            bits, platform = 64, "osx-64"
        elseif find(architecture,"arm64") then
            bits, platform = 64, "osx-arm"
        else
            bits, platform = 32, "osx-ppc"
        end

    elseif name == "sunos" then

        architecture = architecture or resultof("uname -m") or ""
        if find(architecture,"sparc") then
            bits, platform = 32, "solaris-sparc"
        else -- if architecture == 'i86pc'
            bits, platform = 32, "solaris-intel"
        end

    elseif name == "freebsd" then

        architecture = architecture or os.getenv("MACHTYPE") or resultof("uname -m") or ""
        if find(architecture,"amd64") or find(architecture,"AMD64") then
            bits, platform = 64, "freebsd-amd64"
        else
            bits, platform = 32, "freebsd"
        end

    elseif name == "kfreebsd" then

        architecture = architecture or os.getenv("HOSTTYPE") or resultof("uname -m") or ""
        if architecture == "x86_64" then
            bits, platform = 64, "kfreebsd-amd64"
        else
            bits, platform = 32, "kfreebsd-i386"
        end

    else

        architecture = architecture or resultof("uname -m") or ""

        if find(architecture,"aarch64") then
            bits, platform = "linux-aarch64"
        elseif find(architecture,"armv7l") then
            -- linux-armel
            bits, platform = 32, "linux-armhf"
        elseif find(architecture,"mips64") or find(architecture,"mips64el") then
            bits, platform = 64, "linux-mipsel"
        elseif find(architecture,"mipsel") or find(architecture,"mips") then
            bits, platform = 32, "linux-mipsel"
        else
            bits, platform = 64, "linux-64" -- was 32, "linux"
        end

    end

    os.setenv("MTX_PLATFORM",platform)
    os.setenv("MTX_BITS",    bits)

    os.platform = platform
    os.bits     = bits
    os.newline  = name == "windows" and "\013\010" or "\010" -- crlf or lf

end

-- beware, we set the randomseed

-- From wikipedia: Version 4 UUIDs use a scheme relying only on random numbers. This
-- algorithm sets the version number as well as two reserved bits. All other bits
-- are set using a random or pseudorandom data source. Version 4 UUIDs have the form
-- xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx with hexadecimal digits x and hexadecimal
-- digits 8, 9, A, or B for y. e.g. f47ac10b-58cc-4372-a567-0e02b2c3d479. As we don't
-- call this function too often there is not so much risk on repetition.

do

    local t = { 8, 9, "a", "b" }

    function os.uuid()
        return format("%04x%04x-4%03x-%s%03x-%04x-%04x%04x%04x",
            random(0xFFFF),random(0xFFFF),
            random(0x0FFF),
            t[ceil(random(4))] or 8,random(0x0FFF),
            random(0xFFFF),
            random(0xFFFF),random(0xFFFF),random(0xFFFF)
        )
    end

end

do

    -- this is fragile because it depends on time and so we only check once during
    -- a run (the computer doesn't move zones) .. Michal Vlasák made a better one

 -- local d
 --
 -- function os.timezone()
 --     d = d or ((tonumber(date("%H")) or 0) - (tonumber(date("!%H")) or 0))
 --     if d > 0 then
 --         return format("+%02i:00",d)
 --     else
 --         return format("-%02i:00",-d)
 --     end
 -- end

    local hour, min

    function os.timezone(difference)
        if not hour then
            -- somehow looks too complex:
            local current   = time()
            local utcdate   = date("!*t", current)
            local localdate = date("*t", current)
            localdate.isdst = false
            local timediff  = difftime(time(localdate), time(utcdate))
            hour, min = modf(timediff / 3600)
            min = min * 60
        end
        if difference then
            return hour, min
        else
            return format("%+03d:%02d",hour,min) -- %+ means: always show sign
        end
    end

    -- localtime with timezone: 2021-10-22 10:22:54+02:00

    local timeformat = format("%%s%s",os.timezone())
    local dateformat = "%Y-%m-%d %H:%M:%S"
    local lasttime   = nil
    local lastdate   = nil

    function os.fulltime(t,default)
        t = t and tonumber(t) or 0
        if t > 0 then
            -- valid time
        elseif default then
            return default
        else
            t = time()
        end
        if t ~= lasttime then
            lasttime = t
            lastdate = format(timeformat,date(dateformat))
        end
        return lastdate
    end

    -- localtime without timezone: 2021-10-22 10:22:54

    local dateformat = "%Y-%m-%d %H:%M:%S"
    local lasttime   = nil
    local lastdate   = nil

    function os.localtime(t,default)
        t = t and tonumber(t) or 0
        if t > 0 then
            -- valid time
        elseif default then
            return default
        else
            t = time()
        end
        if t ~= lasttime then
            lasttime = t
            lastdate = date(dateformat,t)
        end
        return lastdate
    end

    function os.converttime(t,default)
        local t = tonumber(t)
        if t and t > 0 then
            return date(dateformat,t)
        else
            return default or "-"
        end
    end

    -- table with values

    function os.today()
        return date("!*t")
    end

    -- utc time without timezone: 2021-10-22 08:22:54

    function os.now()
        return date("!%Y-%m-%d %H:%M:%S")
    end

end

do

    local cache = { }

    local function which(filename)
        local fullname = cache[filename]
        if fullname == nil then
            local suffix = file.suffix(filename)
            local suffixes = suffix == "" and os.binsuffixes or { suffix }
            for directory in gmatch(os.getenv("PATH"),"[^" .. io.pathseparator .."]+") do
                local df = file.join(directory,filename)
                for i=1,#suffixes do
                    local dfs = file.addsuffix(df,suffixes[i])
                    if io.exists(dfs) then
                        fullname = dfs
                        break
                    end
                end
            end
            if not fullname then
                fullname = false
            end
            cache[filename] = fullname
        end
        return fullname
    end

    os.which = which
    os.where = which

    -- print(os.which("inkscape.exe"))
    -- print(os.which("inkscape"))
    -- print(os.which("gs.exe"))
    -- print(os.which("ps2pdf"))

end

if not os.sleep then

    local socket = socket

    function os.sleep(n)
        if not socket then
            -- so we delay ... if os.sleep is really needed then one should also
            -- be sure that socket can be found
            socket = require("socket")
        end
        socket.sleep(n)
    end

end

-- These are moved from core-con.lua (as I needed them elsewhere).

do

    local function isleapyear(year) -- timed for bram's cs practicum
     -- return (year % 400 == 0) or (year % 100 ~= 0 and year % 4 == 0) -- 3:4:1600:1900 = 9.9 : 8.2 : 5.0 :  6.8 (29.9)
        return (year % 4 == 0) and (year % 100 ~= 0 or year % 400 == 0) -- 3:4:1600:1900 = 5.1 : 6.5 : 8.1 : 10.2 (29.9)
     -- return (year % 4 == 0) and (year % 400 == 0 or year % 100 ~= 0) -- 3:4:1600:1900 = 5.2 : 8.5 : 6.8 : 10.1 (30.6)
    end

    os.isleapyear = isleapyear

    -- nicer:
    --
    -- local days = {
    --     [false] = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 },
    --     [true]  = { 31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }
    -- }
    --
    -- local function nofdays(year,month)
    --     return days[isleapyear(year)][month]
    --     return month == 2 and isleapyear(year) and 29 or days[month]
    -- end
    --
    -- more efficient:

    local days = { 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31 }

    local function nofdays(year,month,day)
        if not month then
            return isleapyear(year) and 365 or 364
        elseif not day then
            return month == 2 and isleapyear(year) and 29 or days[month]
        else
            for i=1,month-1 do
                day = day + days[i]
            end
            if month > 2 and isleapyear(year) then
                day = day + 1
            end
            return day
        end
    end

    os.nofdays = nofdays

    function os.weekday(day,month,year)
        return date("%w",time { year = year, month = month, day = day }) + 1
    end

    function os.validdate(year,month,day)
        -- we assume that all three values are set
        -- year is always ok, even if lua has a 1970 time limit
        if month < 1 then
            month = 1
        elseif month > 12 then
            month = 12
        end
        if day < 1 then
            day = 1
        else
            local max = nofdays(year,month)
            if day > max then
                day = max
            end
        end
        return year, month, day
    end

    function os.date(fmt,...)
        if not fmt then
            -- otherwise differences between unix, mingw and msvc
            fmt = "%Y-%m-%d %H:%M"
        end
        return date(fmt,...)
    end

end

do

    local osexit   = os.exit
    local exitcode = nil

    function os.setexitcode(code)
        exitcode = code
    end

    function os.exit(c)
        if exitcode ~= nil then
            return osexit(exitcode)
        end
        if c ~= nil then
            return osexit(c)
        end
        return osexit()
    end

end
