#!/usr/bin/env texlua

lualibs = lualibs or { }

local stringgsub  = string.gsub
local stringlower = string.lower
local next        = next
local Ct, splitat = lpeg.Ct, lpeg.splitat

--[[doc
Needed by legacy luat-dum.lua.
--doc]]--
table.reverse_hash = function (h)
    local r = { }
    for k,v in next, h do
        r[v] = stringlower(stringgsub(k," ",""))
    end
    return r
end

--[[doc
Needed by legacy font-otn.lua.
--doc]]--
lpeg.splitters = { [" "] = Ct(splitat" ") }

--[[doc
Needed by legacy font-nms.lua.
--doc]]--

file.split_path    = file.splitpath
file.collapse_path = file.collapsepath
