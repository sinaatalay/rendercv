if not modules then modules = { } end modules ['trac-inf'] = {
    version   = 1.001,
    comment   = "companion to trac-inf.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- As we want to protect the global tables, we no longer store the timing
-- in the tables themselves but in a hidden timers table so that we don't
-- get warnings about assignments. This is more efficient than using rawset
-- and rawget.

local type, tonumber, select = type, tonumber, select
local format, lower, find = string.format, string.lower, string.find
local concat = table.concat
local clock  = os.gettimeofday or os.clock -- should go in environment

local setmetatableindex = table.setmetatableindex
local serialize         = table.serialize
local formatters        = string.formatters

statistics              = statistics or { }
local statistics        = statistics

statistics.enable       = true
statistics.threshold    = 0.01

local statusinfo, n, registered, timers = { }, 0, { }, { }

setmetatableindex(timers,function(t,k)
    local v = { timing = 0, loadtime = 0, offset = 0 }
    t[k] = v
    return v
end)

local function hastiming(instance)
    return instance and timers[instance]
end

local function resettiming(instance)
    timers[instance or "notimer"] = { timing = 0, loadtime = 0, offset = 0 }
end

local ticks   = clock
local seconds = function(n) return n or 0 end

if os.type ~= "windows" then

    -- doesn't work well yet on unix (system time vs process time so a mtxrun
    -- timing with nested call gives the wrong result)

elseif lua.getpreciseticks then

    ticks   = lua.getpreciseticks
    seconds = lua.getpreciseseconds

elseif FFISUPPORTED then

    -- Do we really care when not in luametatex? For now we do, so:

    local okay, kernel = pcall(ffi.load,"kernel32")

    if kernel then

        local tonumber = ffi.number or tonumber

        ffi.cdef[[
            int QueryPerformanceFrequency(int64_t *lpFrequency);
            int QueryPerformanceCounter(int64_t *lpPerformanceCount);
        ]]

        local target = ffi.new("__int64[1]")

        ticks = function()
            if kernel.QueryPerformanceCounter(target) == 1 then
                return tonumber(target[0])
            else
                return 0
            end
        end

        local target = ffi.new("__int64[1]")

        seconds = function(ticks)
            if kernel.QueryPerformanceFrequency(target) == 1 then
                return ticks / tonumber(target[0])
            else
                return 0
            end
        end

    end

else

    -- excessive timing costs some 1-2 percent runtime

end


local function starttiming(instance,reset)
    local timer = timers[instance or "notimer"]
    local it = timer.timing
    if reset then
        it = 0
        timer.loadtime = 0
    end
    if it == 0 then
        timer.starttime = ticks()
        if not timer.loadtime then
            timer.loadtime = 0
        end
    end
    timer.timing = it + 1
end

local function stoptiming(instance)
    local timer = timers[instance or "notimer"]
    local it = timer.timing
    if it > 1 then
        timer.timing = it - 1
    else
        local starttime = timer.starttime
        if starttime and starttime > 0 then
            local stoptime  = ticks()
            local loadtime  = stoptime - starttime
            timer.stoptime  = stoptime
            timer.loadtime  = timer.loadtime + loadtime
            timer.timing    = 0
            timer.starttime = 0
        end
    end
end

local function benchmarktimer(instance)
    local timer = timers[instance or "notimer"]
    local it = timer.timing
    if it > 1 then
        timer.timing = it - 1
    else
        local starttime = timer.starttime
        if starttime and starttime > 0 then
            timer.offset = ticks() - starttime
        else
            timer.offset = 0
        end
    end
end

local function elapsed(instance)
    if type(instance) == "number" then
        return instance
    else
        local timer = timers[instance or "notimer"]
        return timer and seconds(timer.loadtime - 2*(timer.offset or 0)) or 0
    end
end

local function currenttime(instance)
    if type(instance) == "number" then
        return instance
    else
        local timer = timers[instance or "notimer"]
        local it = timer.timing
        if it > 1 then
            -- whatever
        else
            local starttime = timer.starttime
            if starttime and starttime > 0 then
                return seconds(timer.loadtime + ticks() - starttime -  2*(timer.offset or 0))
            end
        end
        return 0
    end
end

local function elapsedtime(instance)
    return format("%0.3f",elapsed(instance))
end

local function elapsedindeed(instance)
    return elapsed(instance) > statistics.threshold
end

local function elapsedseconds(instance,rest) -- returns nil if 0 seconds
    if elapsedindeed(instance) then
        return format("%0.3f seconds %s", elapsed(instance),rest or "")
    end
end

statistics.hastiming      = hastiming
statistics.resettiming    = resettiming
statistics.starttiming    = starttiming
statistics.stoptiming     = stoptiming
statistics.currenttime    = currenttime
statistics.elapsed        = elapsed
statistics.elapsedtime    = elapsedtime
statistics.elapsedindeed  = elapsedindeed
statistics.elapsedseconds = elapsedseconds
statistics.benchmarktimer = benchmarktimer

-- general function .. we might split this module

function statistics.register(tag,fnc)
    if statistics.enable and type(fnc) == "function" then
        local rt = registered[tag] or (#statusinfo + 1)
        statusinfo[rt] = { tag, fnc }
        registered[tag] = rt
        if #tag > n then n = #tag end
    end
end

local report = logs.reporter("mkiv lua stats")

function statistics.show()
    if statistics.enable then
        -- this code will move
        local register = statistics.register
        register("used platform", function()
            return format("%s, type: %s, binary subtree: %s",
                os.platform or "unknown",os.type or "unknown", environment.texos or "unknown")
        end)
        register("used engine", function()
            return format("%s version: %s, functionality level: %s, banner: %s",
                LUATEXENGINE, LUATEXVERSION, LUATEXFUNCTIONALITY, lower(status.banner))
        end)
        register("used hash slots", function()
            return format("%s of %s + %s", status.cs_count, status.hash_size,status.hash_extra)
        end)
        register("callbacks", statistics.callbacks)
        if JITSUPPORTED then
            local jitstatus = jit.status
            if jitstatus then
                local jitstatus = { jitstatus() }
                if jitstatus[1] then
                    register("luajit options", concat(jitstatus," ",2))
                end
            end
        end
        -- so far
        register("lua properties",function()
            local hash = 2^status.luatex_hashchars
            local mask = load([[τεχ = 1]]) and "utf" or "ascii"
            return format("engine: %s %s, used memory: %s, hash chars: min(%i,40), symbol mask: %s (%s)",
                jit and "luajit" or "lua", LUAVERSION, statistics.memused(), hash, mask, mask == "utf" and "τεχ" or "tex")
        end)
        register("runtime",statistics.runtime)
        logs.newline() -- initial newline
        for i=1,#statusinfo do
            local s = statusinfo[i]
            local r = s[2]()
            if r then
                report("%s: %s",s[1],r)
            end
        end
     -- logs.newline() -- final newline
        statistics.enable = false
    end
end

function statistics.memused() -- no math.round yet -)
    local round = math.round or math.floor
    return format("%s MB, ctx: %s MB, max: %s MB",
        round(collectgarbage("count")/1000),
        round(status.luastate_bytes/1000000),
        status.luastate_bytes_max and round(status.luastate_bytes_max/1000000) or "unknown"
    )
end

starttiming(statistics)

function statistics.formatruntime(runtime) -- indirect so it can be overloaded and
    return format("%s seconds", runtime)   -- indeed that happens in cure-uti.lua
end

function statistics.runtime()
    stoptiming(statistics)
 -- stoptiming(statistics) -- somehow we can start the timer twice, but where
    local runtime = lua.getruntime and lua.getruntime() or elapsedtime(statistics)
    return statistics.formatruntime(runtime)
end

local report = logs.reporter("system")

function statistics.timed(action,all)
    starttiming("run")
    action()
    stoptiming("run")
    local runtime = tonumber(elapsedtime("run"))
    if all then
        local alltime = tonumber(lua.getruntime and lua.getruntime() or elapsedtime(statistics))
        if alltime and alltime > 0 then
            report("total runtime: %0.3f seconds of %0.3f seconds",runtime,alltime)
            return
        end
    end
    report("total runtime: %0.3f seconds",runtime)
end

-- goodie

function statistics.tracefunction(base,tag,...)
    for i=1,select("#",...) do
        local name = select(i,...)
        local stat = { }
        local func = base[name]
        setmetatableindex(stat,function(t,k) t[k] = 0 return 0 end)
        base[name] = function(n,k,v) stat[k] = stat[k] + 1 return func(n,k,v) end
        statistics.register(formatters["%s.%s"](tag,name),function() return serialize(stat,"calls") end)
    end
end

function status.getreadstate()
    return {
        filename   = status.filename   or "?",
        linenumber = status.linenumber or 0,
        iocode     = status.inputid    or 0,
    }
end

