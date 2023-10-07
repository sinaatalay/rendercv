if not modules then modules = { } end modules ['util-dim'] = {
    version   = 1.001,
    comment   = "support for dimensions",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- Internally LuaTeX work with scaled point, which are represented by integers.
-- However, in practice, at east at the TeX end we work with more generic units like
-- points (pt). Going from scaled points (numbers) to one of those units can be done
-- by using the conversion factors collected in the following table.

local format, match, gsub, type, setmetatable = string.format, string.match, string.gsub, type, setmetatable
local P, S, R, Cc, C, lpegmatch = lpeg.P, lpeg.S, lpeg.R, lpeg.Cc, lpeg.C, lpeg.match

local allocate          = utilities.storage.allocate
local setmetatableindex = table.setmetatableindex
local formatters        = string.formatters

local texget            = tex and tex.get or function() return 65536*10*100 end

local p_stripzeros      = lpeg.patterns.stripzeros

--this might become another namespace

number = number or { }
local number = number

number.tonumberf = function(n) return lpegmatch(p_stripzeros,format("%.20f",n)) end
number.tonumberg = function(n) return format("%.20g",n) end

local dimenfactors = allocate {
    ["pt"] =             1/65536,
    ["in"] = (  100/ 7227)/65536,
    ["cm"] = (  254/ 7227)/65536,
    ["mm"] = ( 2540/ 7227)/65536,
    ["sp"] =                   1, -- 65536 sp in 1pt
    ["bp"] = ( 7200/ 7227)/65536,
    ["pc"] = (    1/   12)/65536,
    ["dd"] = ( 1157/ 1238)/65536,
    ["cc"] = ( 1157/14856)/65536,
 -- ["nd"] = (20320/21681)/65536,
 -- ["nc"] = ( 5080/65043)/65536,
    ["es"] = ( 9176/  129)/65536,
    ["ts"] = ( 4588/  645)/65536,
}

-- print(table.serialize(dimenfactors))
--
--  %.99g:
--
--  t={
--   ["bp"]=1.5201782378580324e-005,
--   ["cc"]=1.1883696112892098e-006,
--   ["cm"]=5.3628510057769479e-007,
--   ["dd"]=1.4260435335470516e-005,
--   ["em"]=0.000152587890625,
--   ["ex"]=6.103515625e-005,
--   ["in"]=2.1113586636917117e-007,
--   ["mm"]=5.3628510057769473e-008,
-- --["nc"]=1.1917446679504327e-006,
-- --["nd"]=1.4300936015405194e-005,
-- --["pc"]=1.2715657552083333e-006,
--   ["pt"]=1.52587890625e-005,
--   ["sp"]=1,
--  }
--
--  patched %s and tonumber
--
--  t={
--   ["bp"]=0.00001520178238,
--   ["cc"]=0.00000118836961,
--   ["cm"]=0.0000005362851,
--   ["dd"]=0.00001426043534,
--   ["em"]=0.00015258789063,
--   ["ex"]=0.00006103515625,
--   ["in"]=0.00000021113587,
--   ["mm"]=0.00000005362851,
-- --["nc"]=0.00000119174467,
-- --["nd"]=0.00001430093602,
--   ["pc"]=0.00000127156576,
--   ["pt"]=0.00001525878906,
--   ["sp"]=1,
--  }

-- A conversion function that takes a number, unit (string) and optional format
-- (string) is implemented using this table.

local f_none = formatters["%s%s"]
local f_true = formatters["%0.5F%s"]

local function numbertodimen(n,unit,fmt) -- will be redefined later !
    if type(n) == 'string' then
        return n
    else
        unit = unit or 'pt'
        n = n * dimenfactors[unit]
        if not fmt then
            fmt = f_none(n,unit)
        elseif fmt == true then
            fmt = f_true(n,unit)
        else
            return formatters[fmt](n,unit)
        end
    end
end

-- We collect a bunch of converters in the 'number' namespace.

number.maxdimen     = 1073741823
number.todimen      = numbertodimen
number.dimenfactors = dimenfactors

function number.topoints      (n,fmt) return numbertodimen(n,"pt",fmt) end
function number.toinches      (n,fmt) return numbertodimen(n,"in",fmt) end
function number.tocentimeters (n,fmt) return numbertodimen(n,"cm",fmt) end
function number.tomillimeters (n,fmt) return numbertodimen(n,"mm",fmt) end
-------- number.toscaledpoints(n,fmt) return numbertodimen(n,"sp",fmt) end
function number.toscaledpoints(n)     return            n .. "sp"      end
function number.tobasepoints  (n,fmt) return numbertodimen(n,"bp",fmt) end
function number.topicas       (n,fmt) return numbertodimen(n "pc",fmt) end
function number.todidots      (n,fmt) return numbertodimen(n,"dd",fmt) end
function number.tociceros     (n,fmt) return numbertodimen(n,"cc",fmt) end
-------- number.tonewdidots   (n,fmt) return numbertodimen(n,"nd",fmt) end
-------- number.tonewciceros  (n,fmt) return numbertodimen(n,"nc",fmt) end
function number.toediths      (n,fmt) return numbertodimen(n,"es",fmt) end
function number.totoves       (n,fmt) return numbertodimen(n,"ts",fmt) end

-- More interesting it to implement a (sort of) dimen datatype, one that permits
-- calculations too. First we define a function that converts a string to
-- scaledpoints. We use LPEG. We capture a number and optionally a unit. When no
-- unit is given a constant capture takes place.

local amount = (S("+-")^0 * R("09")^0 * P(".")^0 * R("09")^0) + Cc("0")
local unit   = R("az")^1 + P("%")

local dimenpair = amount/tonumber * (unit^1/dimenfactors + Cc(1)) -- tonumber is new

lpeg.patterns.dimenpair = dimenpair

local splitter = amount/tonumber * C(unit^1)

function number.splitdimen(str)
    return lpegmatch(splitter,str)
end

-- We use a metatable to intercept errors. When no key is found in the table with
-- factors, the metatable will be consulted for an alternative index function.

setmetatableindex(dimenfactors, function(t,s)
 -- error("wrong dimension: " .. (s or "?")) -- better a message
    return false
end)

-- We redefine the following function later on, so we comment it here (which saves
-- us bytecodes.

-- function string.todimen(str)
--     if type(str) == "number" then
--         return str
--     else
--         local value, unit = lpegmatch(dimenpair,str)
--         return value/unit
--     end
-- end
--
-- local stringtodimen = string.todimen

local stringtodimen -- assigned later (commenting saves bytecode)

local amount = S("+-")^0 * R("09")^0 * S(".,")^0 * R("09")^0
local unit   = P("pt") + P("cm") + P("mm") + P("sp") + P("bp")
             + P("es") + P("ts") + P("pc") + P("dd") + P("cc")
             + P("in")
          -- + P("nd") + P("nc")

local validdimen = amount * unit

lpeg.patterns.validdimen = validdimen

-- This converter accepts calls like:
--
--   string.todimen("10")
--   string.todimen(".10")
--   string.todimen("10.0")
--   string.todimen("10.0pt")
--   string.todimen("10pt")
--   string.todimen("10.0pt")
--
-- With this in place, we can now implement a proper datatype for dimensions, one
-- that permits us to do this:
--
--   s = dimen "10pt" + dimen "20pt" + dimen "200pt"
--           - dimen "100sp" / 10 + "20pt" + "0pt"
--
-- We create a local metatable for this new type:

local dimensions = { }

-- The main (and globally) visible representation of a dimen is defined next: it is
-- a one-element table. The unit that is returned from the match is normally a
-- number (one of the previously defined factors) but we also accept functions.
-- Later we will see why. This function is redefined later.

-- function dimen(a)
--     if a then
--         local ta= type(a)
--         if ta == "string" then
--             local value, unit = lpegmatch(pattern,a)
--             if type(unit) == "function" then
--                 k = value/unit()
--             else
--                 k = value/unit
--             end
--             a = k
--         elseif ta == "table" then
--             a = a[1]
--         end
--         return setmetatable({ a }, dimensions)
--     else
--         return setmetatable({ 0 }, dimensions)
--     end
-- end

-- This function return a small hash with a metatable attached. It is through this
-- metatable that we can do the calculations. We could have shared some of the code
-- but for reasons of speed we don't.

function dimensions.__add(a, b)
    local ta, tb = type(a), type(b)
    if ta == "string" then a = stringtodimen(a) elseif ta == "table" then a = a[1] end
    if tb == "string" then b = stringtodimen(b) elseif tb == "table" then b = b[1] end
    return setmetatable({ a + b }, dimensions)
end

function dimensions.__sub(a, b)
    local ta, tb = type(a), type(b)
    if ta == "string" then a = stringtodimen(a) elseif ta == "table" then a = a[1] end
    if tb == "string" then b = stringtodimen(b) elseif tb == "table" then b = b[1] end
    return setmetatable({ a - b }, dimensions)
end

function dimensions.__mul(a, b)
    local ta, tb = type(a), type(b)
    if ta == "string" then a = stringtodimen(a) elseif ta == "table" then a = a[1] end
    if tb == "string" then b = stringtodimen(b) elseif tb == "table" then b = b[1] end
    return setmetatable({ a * b }, dimensions)
end

function dimensions.__div(a, b)
    local ta, tb = type(a), type(b)
    if ta == "string" then a = stringtodimen(a) elseif ta == "table" then a = a[1] end
    if tb == "string" then b = stringtodimen(b) elseif tb == "table" then b = b[1] end
    return setmetatable({ a / b }, dimensions)
end

function dimensions.__unm(a)
    local ta = type(a)
    if ta == "string" then a = stringtodimen(a) elseif ta == "table" then a = a[1] end
    return setmetatable({ - a }, dimensions)
end

-- It makes no sense to implement the power and modulo function but
-- the next two do make sense because they permits is code like:
--
--   local a, b = dimen "10pt", dimen "11pt"
--   ...
--   if a > b then
--       ...
--   end
--
-- This also makes no sense: dimensions.__pow and dimensions.__mod.

function dimensions.__lt(a, b)
    return a[1] < b[1]
end

function dimensions.__eq(a, b)
    return a[1] == b[1]
end

-- We also need to provide a function for conversion to string (so that we can print
-- dimensions). We print them as points, just like TeX.

function dimensions.__tostring(a)
    return a[1]/65536 .. "pt" -- instead of todimen(a[1])
end

-- Since it does not take much code, we also provide a way to access a few accessors
--
--   print(dimen().pt)
--   print(dimen().sp)

function dimensions.__index(tab,key)
    local d = dimenfactors[key]
    if not d then
        error("illegal property of dimen: " .. key)
        d = 1
    end
    return 1/d
end

-- In the converter from string to dimension we support functions as factors. This
-- is because in TeX we have a few more units: 'ex' and 'em'. These are not constant
-- factors but depend on the current font. They are not defined by default, but need
-- an explicit function call. This is because at the moment that this code is
-- loaded, the relevant tables that hold the functions needed may not yet be
-- available.

   dimenfactors["ex"] =     4     /65536 --   4pt
   dimenfactors["em"] =    10     /65536 --  10pt
-- dimenfactors["%"]  =     4     /65536 -- 400pt/100
   dimenfactors["eu"] = (9176/129)/65536 --  1es

-- The previous code is rather efficient (also thanks to LPEG) but we can speed it
-- up by caching converted dimensions. On my machine (2008) the following loop takes
-- about 25.5 seconds.
--
--   for i=1,1000000 do
--       local s = dimen "10pt" + dimen "20pt" + dimen "200pt"
--           - dimen "100sp" / 10 + "20pt" + "0pt"
--   end
--
-- When we cache converted strings this becomes 16.3 seconds. In order not to waste
-- too much memory on it, we tag the values of the cache as being week which mean
-- that the garbage collector will collect them in a next sweep. This means that in
-- most cases the speed up is mostly affecting the current couple of calculations
-- and as such the speed penalty is small.
--
-- We redefine two previous defined functions that can benefit from this:

local known = { } setmetatable(known, { __mode = "v" })

function dimen(a)
    if a then
        local ta= type(a)
        if ta == "string" then
            local k = known[a]
            if k then
                a = k
            else
                local value, unit = lpegmatch(dimenpair,a)
                if value and unit then
                    k = value/unit -- to be considered: round
                else
                    k = 0
                end
                known[a] = k
                a = k
            end
        elseif ta == "table" then
            a = a[1]
        end
        return setmetatable({ a }, dimensions)
    else
        return setmetatable({ 0 }, dimensions)
    end
end

function string.todimen(str) -- maybe use tex.sp when available
    local t = type(str)
    if t == "number" then
        return str
    else
        local k = known[str]
        if not k then
            if t == "string" then
                local value, unit = lpegmatch(dimenpair,str)
                if value and unit then
                    k = value/unit -- to be considered: round
                else
                    k = 0
                end
            else
                k = 0
            end
            known[str] = k
        end
        return k
    end
end

-- local known = { }
--
-- function string.todimen(str) -- maybe use tex.sp
--     local k = known[str]
--     if not k then
--         k = tex.sp(str)
--         known[str] = k
--     end
--     return k
-- end

stringtodimen = string.todimen -- local variable defined earlier

function number.toscaled(d)
    return format("%0.5f",d/0x10000) -- 2^16
end

-- In a similar fashion we can define a glue datatype. In that case we probably use
-- a hash instead of a one-element table.
--
-- A goodie:

function number.percent(n,d) -- will be cleaned up once luatex 0.30 is out
    d = d or texget("hsize")
    if type(d) == "string" then
        d = stringtodimen(d)
    end
    return (n/100) * d
end

number["%"] = number.percent
