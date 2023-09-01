if not modules then modules = { } end modules ['l-boolean'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local type, tonumber = type, tonumber

boolean = boolean or { }
local boolean = boolean

function boolean.tonumber(b)
    if b then return 1 else return 0 end -- test and return or return
end

function toboolean(str,tolerant) -- global
    if  str == nil then
        return false
    elseif str == false then
        return false
    elseif str == true then
        return true
    elseif str == "true" then
        return true
    elseif str == "false" then
        return false
    elseif not tolerant then
        return false
    elseif str == 0 then
        return false
    elseif (tonumber(str) or 0) > 0 then
        return true
    else
        return str == "yes" or str == "on" or str == "t"
    end
end

string.toboolean = toboolean

function string.booleanstring(str)
    if str == "0" then
        return false
    elseif str == "1" then
        return true
    elseif str == "" then
        return false
    elseif str == "false" then
        return false
    elseif str == "true" then
        return true
    elseif (tonumber(str) or 0) > 0 then
        return true
    else
        return str == "yes" or str == "on" or str == "t"
    end
end

function string.is_boolean(str,default,strict)
    if type(str) == "string" then
        if str == "true" or str == "yes" or str == "on" or str == "t" or (not strict and str == "1") then
            return true
        elseif str == "false" or str == "no" or str == "off" or str == "f" or (not strict and str == "0") then
            return false
        end
    end
    return default
end
