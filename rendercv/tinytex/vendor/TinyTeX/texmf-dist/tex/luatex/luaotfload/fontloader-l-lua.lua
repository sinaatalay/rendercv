if not modules then modules = { } end modules ['l-lua'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- potential issues with 5.3:

-- i'm not sure yet if the int/float change is good for luatex

-- math.min
-- math.max
-- tostring
-- tonumber
-- utf.*
-- bit32

local next, type, tonumber = next, type, tonumber

-- compatibility hacks and helpers

LUAMAJORVERSION, LUAMINORVERSION = string.match(_VERSION,"^[^%d]+(%d+)%.(%d+).*$")

LUAMAJORVERSION = tonumber(LUAMAJORVERSION) or 5
LUAMINORVERSION = tonumber(LUAMINORVERSION) or 1
LUAVERSION      = LUAMAJORVERSION + LUAMINORVERSION/10

if LUAVERSION < 5.2 and jit then
    --
    -- we want loadstring cum suis to behave like 5.2
    --
    MINORVERSION = 2
    LUAVERSION   = 5.2
end

-- this is lmtx only:

-- if lua and lua.openfile then
--     io.open = lua.openfile
-- end

-- lpeg

if not lpeg then
    lpeg = require("lpeg")
end

-- if utf8 then
--     utf8lua = utf8
--     utf8    = nil
-- end

-- basics:

if loadstring then

    local loadnormal = load

    function load(first,...)
        if type(first) == "string" then
            return loadstring(first,...)
        else
            return loadnormal(first,...)
        end
    end

else

    loadstring = load

end

-- table:

-- At some point it was announced that i[pairs would be dropped, which makes
-- sense. As we already used the for loop and # in most places the impact on
-- ConTeXt was not that large; the remaining ipairs already have been replaced.
-- Hm, actually ipairs was retained, but we no longer use it anyway (nor
-- pairs).
--
-- Just in case, we provide the fallbacks as discussed in Programming
-- in Lua (http://www.lua.org/pil/7.3.html):

if not ipairs then

    -- for k, v in ipairs(t) do                ... end
    -- for k=1,#t            do local v = t[k] ... end

    local function iterate(a,i)
        i = i + 1
        local v = a[i]
        if v ~= nil then
            return i, v --, nil
        end
    end

    function ipairs(a)
        return iterate, a, 0
    end

end

if not pairs then

    -- for k, v in pairs(t) do ... end
    -- for k, v in next, t  do ... end

    function pairs(t)
        return next, t -- , nil
    end

end

-- The unpack function has been moved to the table table, and for compatiility
-- reasons we provide both now.

if not table.unpack then

    table.unpack = _G.unpack

elseif not unpack then

    _G.unpack = table.unpack

end

-- package:

-- if not package.seachers then
--
--     package.searchers = package.loaders -- 5.2
--
-- elseif not package.loaders then
--
--     package.loaders = package.searchers
--
-- end

if not package.loaders then -- brr, searchers is a special "loadlib function" userdata type

    package.loaders = package.searchers

end

-- moved from util-deb to here:

local print, select, tostring = print, select, tostring

local inspectors = { }

function setinspector(kind,inspector) -- global function
    inspectors[kind] = inspector
end

function inspect(...) -- global function
    for s=1,select("#",...) do
        local value = select(s,...)
        if value == nil then
            print("nil")
        else
            local done  = false
            -- type driven (table)
            local kind      = type(value)
            local inspector = inspectors[kind]
            if inspector then
                done = inspector(value)
                if done then
                    break
                end
            end
            -- whatever driven (token, node, ...)
            for kind, inspector in next, inspectors do
                done = inspector(value)
                if done then
                    break
                end
            end
            if not done then
                print(tostring(value))
            end
        end
    end
end

--

local dummy = function() end

function optionalrequire(...)
    local ok, result = xpcall(require,dummy,...)
    if ok then
        return result
    end
end

local flush = io.flush

if flush then

    local execute = os.execute if execute then function os.execute(...) flush() return execute(...) end end
    local exec    = os.exec    if exec    then function os.exec   (...) flush() return exec   (...) end end
    local spawn   = os.spawn   if spawn   then function os.spawn  (...) flush() return spawn  (...) end end
    local popen   = io.popen   if popen   then function io.popen  (...) flush() return popen  (...) end end

end

-- new

FFISUPPORTED = type(ffi) == "table" and ffi.os ~= "" and ffi.arch ~= "" and ffi.load

if not FFISUPPORTED then

    -- Maybe we should check for LUATEXENGINE but that's also a bit tricky as we still
    -- can have a weird ffi library laying around. Checking for presence of 'jit' is
    -- also not robust. So for now we hope for the best.

    local okay ; okay, ffi = pcall(require,"ffi")

    FFISUPPORTED = type(ffi) == "table" and ffi.os ~= "" and ffi.arch ~= "" and ffi.load

end

if not FFISUPPORTED then
    ffi = nil
elseif not ffi.number then
    ffi.number = tonumber
end

-- if not bit32 then -- and utf8 then
--  -- bit32 = load ( [[ -- replacement code with 5.3 syntax so that 5.2 doesn't bark on it ]] )
--     bit32 = require("l-bit32")
-- end

-- We need this due a bug in luatex socket loading:

-- local loaded = package.loaded
--
-- if not loaded["socket"] then loaded["socket"] = loaded["socket.core"] end
-- if not loaded["mime"]   then loaded["mime"]   = loaded["mime.core"]   end
--
-- if not socket.mime then socket.mime = package.loaded["mime"] end
--
-- if not loaded["socket.mime"] then loaded["socket.mime"] = socket.mime end
-- if not loaded["socket.http"] then loaded["socket.http"] = socket.http end
-- if not loaded["socket.ftp"]  then loaded["socket.ftp"]  = socket.ftp  end
-- if not loaded["socket.smtp"] then loaded["socket.smtp"] = socket.smtp end
-- if not loaded["socket.tp"]   then loaded["socket.tp"]   = socket.tp   end
-- if not loaded["socket.url"]  then loaded["socket.url"]  = socket.url  end

if LUAVERSION > 5.3 then
 -- collectgarbage("collect")
 -- collectgarbage("generational") -- crashes on unix
end

if status and os.setenv then
    os.setenv("engine",string.lower(status.luatex_engine or "unknown"))
end
