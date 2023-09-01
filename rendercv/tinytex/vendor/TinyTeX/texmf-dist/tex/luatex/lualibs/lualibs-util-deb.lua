if not modules then modules = { } end modules ['util-deb'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- the <anonymous> tag is kind of generic and used for functions that are not
-- bound to a variable, like node.new, node.copy etc (contrary to for instance
-- node.has_attribute which is bound to a has_attribute local variable in mkiv)

local type, next, tostring, tonumber = type, next, tostring, tonumber
local format, find, sub, gsub = string.format, string.find, string.sub, string.gsub
local insert, remove, sort = table.insert, table.remove, table.sort
local setmetatableindex = table.setmetatableindex

utilities          = utilities or { }
local debugger     = utilities.debugger or { }
utilities.debugger = debugger

local report       = logs.reporter("debugger")

local ticks        = os.gettimeofday or os.clock
local seconds      = function(n) return n or 0 end
local overhead     = 0
local dummycalls   = 10*1000
local nesting      = 0
local names        = { }

local initialize = false

if lua.getpreciseticks then

    initialize = function()
        ticks      = lua.getpreciseticks
        seconds    = lua.getpreciseseconds
        initialize = false
    end

elseif not (FFISUPPORTED and ffi) then

    -- we have no precise timer

elseif os.type == "windows" then

    initialize = function()
        local kernel = ffilib("kernel32","system") -- no checking
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
        initialize = false
    end

elseif os.type == "unix" then

    -- for the values: echo '#include <time.h>' > foo.h; gcc -dM -E foo.h

    initialize = function()
        local C        = ffi.C
        local tonumber = ffi.number or tonumber
        ffi.cdef [[
            /* what a mess */
            typedef int clk_id_t;
            typedef enum { CLOCK_REALTIME, CLOCK_MONOTONIC, CLOCK_PROCESS_CPUTIME_ID } clk_id;
            typedef struct timespec { long sec; long nsec; } ctx_timespec;
            int clock_gettime(clk_id_t timerid, struct timespec *t);
        ]]
        local target = ffi.new("ctx_timespec[?]",1)
        local clock  = C.CLOCK_PROCESS_CPUTIME_ID
        ticks = function ()
            C.clock_gettime(clock,target)
            return tonumber(target[0].sec*1000000000 + target[0].nsec)
        end
        seconds = function(ticks)
            return ticks/1000000000
        end
        initialize = false
    end

end

setmetatableindex(names,function(t,name)
    local v = setmetatableindex(function(t,source)
        local v = setmetatableindex(function(t,line)
            local v = { total = 0, count = 0, nesting = 0 }
            t[line] = v
            return v
        end)
        t[source] = v
        return v
    end)
    t[name] = v
    return v
end)

local getinfo = nil
local sethook = nil

local function hook(where)
    local f = getinfo(2,"nSl")
    if f then
        local source = f.short_src
        if not source then
            return
        end
        local line = f.linedefined or 0
        local name = f.name
        if not name then
            local what = f.what
            if what == "C" then
                name = "<anonymous>"
            else
                name = f.namewhat or what or "<unknown>"
            end
        end
        local data = names[name][source][line]
        if where == "call" then
            local nesting = data.nesting
            if nesting == 0 then
                data.count = data.count + 1
                insert(data,ticks())
                data.nesting = 1
            else
                data.nesting = nesting + 1
            end
        elseif where == "return" then
            local nesting = data.nesting
            if nesting == 1 then
                local t = remove(data)
                if t then
                    data.total = data.total + ticks() - t
                end
                data.nesting = 0
            else
                data.nesting = nesting - 1
            end
        end
    end
end

function debugger.showstats(printer,threshold)
    local printer   = printer or report
    local calls     = 0
    local functions = 0
    local dataset   = { }
    local length    = 0
    local realtime  = 0
    local totaltime = 0
    local threshold = threshold or 0
    for name, sources in next, names do
        for source, lines in next, sources do
            for line, data in next, lines do
                local count = data.count
                if count > threshold then
                    if #name > length then
                        length = #name
                    end
                    local total = data.total
                    local real  = total
                    if real > 0 then
                        real = total - (count * overhead / dummycalls)
                        if real < 0 then
                            real = 0
                        end
                        realtime = realtime + real
                    end
                    totaltime = totaltime + total
                    if line < 0 then
                        line = 0
                    end
                 -- if name = "a" then
                 --     -- weird name
                 -- end
                    dataset[#dataset+1] = { real, total, count, name, source, line }
                end
            end
        end
    end
    sort(dataset,function(a,b)
        if a[1] == b[1] then
            if a[2] == b[2] then
                if a[3] == b[3] then
                    if a[4] == b[4] then
                        if a[5] == b[5] then
                            return a[6] < b[6]
                        else
                            return a[5] < b[5]
                        end
                    else
                        return a[4] < b[4]
                    end
                else
                    return b[3] < a[3]
                end
            else
                return b[2] < a[2]
            end
        else
            return b[1] < a[1]
        end
    end)
    if length > 50 then
        length = 50
    end
    local fmt = string.formatters["%4.9k s  %3.3k %%  %4.9k s  %3.3k %%  %8i #  %-" .. length .. "s  %4i  %s"]
    for i=1,#dataset do
        local data   = dataset[i]
        local real   = data[1]
        local total  = data[2]
        local count  = data[3]
        local name   = data[4]
        local source = data[5]
        local line   = data[6]
        calls     = calls + count
        functions = functions + 1
        name = gsub(name,"%s+"," ")
        if #name > length then
            name = sub(name,1,length)
        end
        printer(fmt(seconds(total),100*total/totaltime,seconds(real),100*real/realtime,count,name,line,source))
    end
    printer("")
    printer(format("functions : %i", functions))
    printer(format("calls     : %i", calls))
    printer(format("overhead  : %f", seconds(overhead/1000)))

 -- table.save("luatex-profile.lua",names)
end

local function getdebug()
    if sethook and getinfo then
        return
    end
    if not debug then
        local okay
        okay, debug = pcall(require,"debug")
    end
    if type(debug) ~= "table" then
        return
    end
    getinfo = debug.getinfo
    sethook = debug.sethook
    if type(getinfo) ~= "function" then
        getinfo = nil
    end
    if type(sethook) ~= "function" then
        sethook = nil
    end
end

function debugger.savestats(filename,threshold)
    local f = io.open(filename,'w')
    if f then
        debugger.showstats(function(str) f:write(str,"\n") end,threshold)
        f:close()
    end
end

function debugger.enable()
    getdebug()
    if sethook and getinfo and nesting == 0 then
        running = true
        if initialize then
            initialize()
        end
        sethook(hook,"cr")
        local function dummy() end
        local t = ticks()
        for i=1,dummycalls do
            dummy()
        end
        overhead = ticks() - t
    end
    if nesting > 0 then
        nesting = nesting + 1
    end
end

function debugger.disable()
    if nesting > 0 then
        nesting = nesting - 1
    end
    if sethook and getinfo and nesting == 0 then
        sethook()
    end
end

-- debugger.enable()
--
-- print(math.sin(1*.5))
-- print(math.sin(1*.5))
-- print(math.sin(1*.5))
-- print(math.sin(1*.5))
-- print(math.sin(1*.5))
--
-- debugger.disable()
--
-- print("")
-- debugger.showstats()
-- print("")
-- debugger.showstats(print,3)
--
-- from the lua book:

local function showtraceback(rep) -- from lua site / adapted
    getdebug()
    if getinfo then
        local level = 2 -- we don't want this function to be reported
        local reporter = rep or report
        while true do
            local info = getinfo(level, "Sl")
            if not info then
                break
            elseif info.what == "C" then
                reporter("%2i : %s",level-1,"C function")
            else
                reporter("%2i : %s : %s",level-1,info.short_src,info.currentline)
            end
            level = level + 1
        end
    end
end

debugger.showtraceback = showtraceback
-- debug.showtraceback = showtraceback

-- showtraceback()

-- For now also here because we want it in mtxrun (taken from lmt file):

if luac then

    local show, dump = luac.print, string.dump

    function luac.inspect(v)
        if type(v) == "function" then
            local ok, str = xpcall(dump,function() end,v)
            if ok then
                v = str
            end
        end
        if type(v) == "string" then
            show(v,true)
        else
            print(v)
        end
    end

end
