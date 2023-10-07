if not modules then modules = { } end modules ['l-math'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

if not math.ceiling then

    math.ceiling = math.ceil

end

if not math.round then

    if xmath then

        math.round = xmath.round

    else

        local floor = math.floor

        function math.round(x)
            return x < 0 and -floor(-x + 0.5) or floor(x + 0.5)
        end

    end

end

if not math.div then

    local floor = math.floor

    function math.div(n,m) return floor(n/m) end

end

if not math.mod then

    function math.mod(n,m) return n % m end

end

if not math.sind then

    local sin, cos, tan = math.sin, math.cos, math.tan

    local pipi = 2*math.pi/360

    function math.sind(d) return sin(d*pipi) end
    function math.cosd(d) return cos(d*pipi) end
    function math.tand(d) return tan(d*pipi) end

end

if not math.odd then

    function math.odd (n) return n % 2 ~= 0 end
    function math.even(n) return n % 2 == 0 end

end

if not math.cosh then

    local exp = math.exp

    function math.cosh(x)
        local xx = exp(x)
        return (xx+1/xx)/2
    end
    function math.sinh(x)
        local xx = exp(x)
        return (xx-1/xx)/2
    end
    function math.tanh(x)
        local xx = exp(x)
        return (xx-1/xx)/(xx+1/xx)
    end

end

if not math.pow then

    function math.pow(x,y)
        return x^y
    end

end

if not math.atan2 then

    math.atan2 = math.atan

end

if not math.ldexp then

    function math.ldexp(x,e)
        return x * 2.0^e
    end

end

-- if not math.frexp then
--
--     -- not a oneliner so use a math library instead
--
--     function math.frexp(x,e)
--         -- returns m and e such that x = m2e, e is an integer and the absolute
--         -- value of m is in the range [0.5, 1) (or zero when x is zero)
--     end
--
-- end

if not math.log10 then

    local log = math.log

    function math.log10(x)
        return log(x,10)
    end

end

if not math.type then

    function math.type()
        return "float"
    end

end

if not math.tointeger then

    math.mininteger = -0x4FFFFFFFFFFF
    math.maxinteger =  0x4FFFFFFFFFFF

    local floor = math.floor

    function math.tointeger(n)
        local f = floor(n)
        return f == n and f or nil
    end

end

if not math.ult then

    local floor = math.floor

    function math.ult(m,n)
        -- not ok but i'm not motivated to look into it now
        return floor(m) < floor(n) -- unsigned comparison needed
    end

end
