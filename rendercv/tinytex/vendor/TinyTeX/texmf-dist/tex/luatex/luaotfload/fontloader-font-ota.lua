if not modules then modules = { } end modules ['font-ota'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- context only

local type = type
local setmetatableindex = table.setmetatableindex

if not trackers then trackers = { register = function() end } end

----- trace_analyzing = false  trackers.register("otf.analyzing",  function(v) trace_analyzing = v end)

local fonts, nodes, node = fonts, nodes, node

local allocate            = utilities.storage.allocate

local otf                 = fonts.handlers.otf

local analyzers           = fonts.analyzers
local initializers        = allocate()
local methods             = allocate()

analyzers.initializers    = initializers
analyzers.methods         = methods

local nuts                = nodes.nuts
local tonut               = nuts.tonut

local getnext             = nuts.getnext
local getprev             = nuts.getprev
local getprev             = nuts.getprev
local getprop             = nuts.getprop
local setprop             = nuts.setprop
local getsubtype          = nuts.getsubtype
local getchar             = nuts.getchar
local ischar              = nuts.ischar

local endofmath           = nuts.endofmath

local nodecodes           = nodes.nodecodes
----- glyph_code          = nodecodes.glyph
local disc_code           = nodecodes.disc
local math_code           = nodecodes.math

local fontdata            = fonts.hashes.identifiers
local categories          = characters and characters.categories or { } -- sorry, only in context
local chardata            = characters and characters.data

local otffeatures         = fonts.constructors.features.otf
local registerotffeature  = otffeatures.register

-- Analyzers run per script and/or language and are needed in order to process
-- features right.

local setstate = nuts.setstate
local getstate = nuts.getstate

if not setstate or not getstate then
    -- generic (might move to the nod lib)
    setstate = function(n,v)
        setprop(n,"state",v)
    end
    getstate = function(n,v)
        local s = getprop(n,"state")
        if v then
            return s == v
        else
            return s
        end
    end
    nuts.setstate = setstate
    nuts.getstate = getstate
end

-- never use these numbers directly

local s_init = 1    local s_rphf =  7
local s_medi = 2    local s_half =  8
local s_fina = 3    local s_pref =  9
local s_isol = 4    local s_blwf = 10
local s_mark = 5    local s_pstf = 11
local s_rest = 6

local states = allocate {
    init = s_init,
    medi = s_medi,
    med2 = s_medi,
    fina = s_fina,
    fin2 = s_fina,
    fin3 = s_fina,
    isol = s_isol,
    mark = s_mark,
    rest = s_rest,
    rphf = s_rphf,
    half = s_half,
    pref = s_pref,
    blwf = s_blwf,
    pstf = s_pstf,
}

local features = allocate {
    init = s_init,
    medi = s_medi,
    med2 = s_medi,
    fina = s_fina,
    fin2 = s_fina,
    fin3 = s_fina,
    isol = s_isol,
 -- mark = s_mark,
 -- rest = s_rest,
    rphf = s_rphf,
    half = s_half,
    pref = s_pref,
    blwf = s_blwf,
    pstf = s_pstf,
}

analyzers.states          = states
analyzers.features        = features
analyzers.useunicodemarks = false

-- todo: analyzers per script/lang, cross font, so we need an font id hash -> script
-- e.g. latin -> hyphenate, arab -> 1/2/3 analyze -- its own namespace

-- done can go away as can tonut

function analyzers.setstate(head,font)
    local useunicodemarks  = analyzers.useunicodemarks
    local tfmdata = fontdata[font]
    local descriptions = tfmdata.descriptions
    local first, last, current, n, done = nil, nil, head, 0, false -- maybe make n boolean
    current = tonut(current)
    while current do
        local char, id = ischar(current,font)
        if char and not getstate(current) then
            done = true
            local d = descriptions[char]
            if d then
                if d.class == "mark" then
                    done = true
                    setstate(current,s_mark)
                elseif useunicodemarks and categories[char] == "mn" then
                    done = true
                    setstate(current,s_mark)
                elseif n == 0 then
                    first, last, n = current, current, 1
                    setstate(current,s_init)
                else
                    last, n = current, n+1
                    setstate(current,s_medi)
                end
            else -- finish
                if first and first == last then
                    setstate(last,s_isol)
                elseif last then
                    setstate(last,s_fina)
                end
                first, last, n = nil, nil, 0
            end
        elseif char == false then
            -- other font
            if first and first == last then
                setstate(last,s_isol)
            elseif last then
                setstate(last,s_fina)
            end
            first, last, n = nil, nil, 0
            if id == math_code then
                current = endofmath(current)
            end
        elseif id == disc_code then
            -- always in the middle .. it doesn't make much sense to assign a property
            -- here ... we might at some point decide to flag the components when present
            -- but even then it's kind of bogus
            setstate(current,s_medi)
            last = current
        else -- finish
            if first and first == last then
                setstate(last,s_isol)
            elseif last then
                setstate(last,s_fina)
            end
            first, last, n = nil, nil, 0
            if id == math_code then
                current = endofmath(current)
            end
        end
        current = getnext(current)
    end
    if first and first == last then
        setstate(last,s_isol)
    elseif last then
        setstate(last,s_fina)
    end
    return head, done
end

-- in the future we will use language/script attributes instead of the
-- font related value, but then we also need dynamic features which is
-- somewhat slower; and .. we need a chain of them

local function analyzeinitializer(tfmdata,value) -- attr
    local script, language = otf.scriptandlanguage(tfmdata) -- attr
    local action = initializers[script]
    if not action then
        -- skip
    elseif type(action) == "function" then
        return action(tfmdata,value)
    else
        local action = action[language]
        if action then
            return action(tfmdata,value)
        end
    end
end

local function analyzeprocessor(head,font,attr)
    local tfmdata = fontdata[font]
    local script, language = otf.scriptandlanguage(tfmdata,attr)
    local action = methods[script]
    if not action then
        -- skip
    elseif type(action) == "function" then
        return action(head,font,attr)
    else
        action = action[language]
        if action then
            return action(head,font,attr)
        end
    end
    return head, false
end

registerotffeature {
    name         = "analyze",
    description  = "analysis of character classes",
    default      = true,
    initializers = {
        node     = analyzeinitializer,
    },
    processors = {
        position = 1,
        node     = analyzeprocessor,
    }
}

-- latin

methods.latn = analyzers.setstate
-------.dflt = analyzers.setstate % can be an option or just the default

local arab_warned = { }

local function warning(current,what)
    local char = getchar(current)
    if not arab_warned[char] then
        log.report("analyze","arab: character %C has no %a class",char,what)
        arab_warned[char] = true
    end
end

local mappers = allocate {
    l = s_init, -- left
    d = s_medi, -- double
    c = s_medi, -- joiner
    r = s_fina, -- right
    u = s_isol, -- nonjoiner
}

-- we can also use this trick for devanagari

local classifiers = characters.classifiers

if not classifiers then

    local f_arabic,  l_arabic  = characters.blockrange("arabic")
    local f_syriac,  l_syriac  = characters.blockrange("syriac")
    local f_mandiac, l_mandiac = characters.blockrange("mandiac")
    local f_nko,     l_nko     = characters.blockrange("nko")
    local f_ext_a,   l_ext_a   = characters.blockrange("arabicextendeda")

    classifiers = setmetatableindex(function(t,k)
        if type(k) == "number" then
            local c = chardata[k]
            local v = false
            if c then
                local arabic = c.arabic
                if arabic then
                    v = mappers[arabic]
                    if not v then
                        log.report("analyze","error in mapping arabic %C",k)
                        --  error
                        v = false
                    end
                elseif (k >= f_arabic  and k <= l_arabic)  or
                       (k >= f_syriac  and k <= l_syriac)  or
                       (k >= f_mandiac and k <= l_mandiac) or
                       (k >= f_nko     and k <= l_nko)     or
                       (k >= f_ext_a   and k <= l_ext_a)   then
                    if categories[k] == "mn" then
                        v = s_mark
                    else
                        v = s_rest
                    end
                end
            end
            t[k] = v
            return v
        end
    end)

    characters.classifiers = classifiers

end

function methods.arab(head,font,attr)
    local first, last, c_first, c_last
    local current = head
    local done    = false
    current = tonut(current)
    while current do
        local char, id = ischar(current,font)
        if char and not getstate(current) then
            done = true
            local classifier = classifiers[char]
            if not classifier then
                if last then
                    if c_last == s_medi or c_last == s_fina then
                        setstate(last,s_fina)
                    else
                        warning(last,"fina")
                        setstate(last,s_error)
                    end
                    first, last = nil, nil
                elseif first then
                    if c_first == s_medi or c_first == s_fina then
                        setstate(first,s_isol)
                    else
                        warning(first,"isol")
                        setstate(first,s_error)
                    end
                    first = nil
                end
            elseif classifier == s_mark then
                setstate(current,s_mark)
            elseif classifier == s_isol then
                if last then
                    if c_last == s_medi or c_last == s_fina then
                        setstate(last,s_fina)
                    else
                        warning(last,"fina")
                        setstate(last,s_error)
                    end
                    first, last = nil, nil
                elseif first then
                    if c_first == s_medi or c_first == s_fina then
                        setstate(first,s_isol)
                    else
                        warning(first,"isol")
                        setstate(first,s_error)
                    end
                    first = nil
                end
                setstate(current,s_isol)
            elseif classifier == s_medi then
                if first then
                    last = current
                    c_last = classifier
                    setstate(current,s_medi)
                else
                    setstate(current,s_init)
                    first = current
                    c_first = classifier
                end
            elseif classifier == s_fina then
                if last then
                    if getstate(last) ~= s_init then
                        setstate(last,s_medi)
                    end
                    setstate(current,s_fina)
                    first, last = nil, nil
                elseif first then
                 -- if getstate(first) ~= s_init then
                 --     -- needs checking
                 --     setstate(first,s_medi)
                 -- end
                    setstate(current,s_fina)
                    first = nil
                else
                    setstate(current,s_isol)
                end
            else -- classifier == s_rest
                setstate(current,s_rest)
                if last then
                    if c_last == s_medi or c_last == s_fina then
                        setstate(last,s_fina)
                    else
                        warning(last,"fina")
                        setstate(last,s_error)
                    end
                    first, last = nil, nil
                elseif first then
                    if c_first == s_medi or c_first == s_fina then
                        setstate(first,s_isol)
                    else
                        warning(first,"isol")
                        setstate(first,s_error)
                    end
                    first = nil
                end
            end
        else
            if last then
                if c_last == s_medi or c_last == s_fina then
                    setstate(last,s_fina)
                else
                    warning(last,"fina")
                    setstate(last,s_error)
                end
                first, last = nil, nil
            elseif first then
                if c_first == s_medi or c_first == s_fina then
                    setstate(first,s_isol)
                else
                    warning(first,"isol")
                    setstate(first,s_error)
                end
                first = nil
            end
            if id == math_code then -- a bit duplicate as we test for glyphs twice
                current = endofmath(current)
            end
        end
        current = getnext(current)
    end
    if last then
        if c_last == s_medi or c_last == s_fina then
            setstate(last,s_fina)
        else
            warning(last,"fina")
            setstate(last,s_error)
        end
    elseif first then
        if c_first == s_medi or c_first == s_fina then
            setstate(first,s_isol)
        else
            warning(first,"isol")
            setstate(first,s_error)
        end
    end
    return head, done
end

methods.syrc = methods.arab
methods.mand = methods.arab
methods.nko  = methods.arab

-- a quick first attemp .. more later

do

    -- https://github.com/n8willis/opentype-shaping-documents/blob/master/opentype-shaping-mongolian.md#joining-properties
    -- todo syrc

    local joining = setmetatableindex(function(t,k)
        if type(k) == "number" then
            local c = chardata[k]
            local v = false
            if c then
                local mongolian = c.mongolian
                --
                v = mongolian
            end
            t[k] = v
            return v
        end
    end)

    function methods.mong(head,font,attr)
        local first, last
        local current  = head
        local done     = false
        local prevjoin = nil
        local prestate = nil
        current = tonut(current)

        local function wrapup()
            if last then
                if last ~= first then
                    local s = getstate(last)
                    if s == s_medi then
                        setstate(last,s_fina)
                    elseif s == s_init then
                        setstate(last,s_isol)
                    end
                end
                last = nil
                first = nil
                prevjoin = nil
                prestate = nil
            end
        end

        while current do
            local char, id = ischar(current,font)
            if char and not getstate(current) then
                local currjoin = joining[char]
                done = true
                if not last then
                    setstate(current,s_isol)
                    prevjoin  = currjoin
                    first     = current
                    last      = current
                    prevstate = s_isol
                elseif currjoin == "t" then -- transparent
                    -- keep state
                    last = current
                elseif prevjoin == "d" or prevjoin == "jc" or prevjoin == "l" then
                    if currjoin == "d" or prevjoin == "jc" or prevjoin == "r" then
                        local s = getstate(last)
                        if s == s_isol then
                            setstate(last,s_init)
                        elseif s == s_fina then
                            setstate(last,s_medi)
                        end
                        setstate(current,s_fina)
                        prevstate = s_fina
                    elseif prevjoin == "nj" or prevjoin == "l" then
                        local s = getstate(last)
                        if s == s_medi then
                            setstate(last,s_fina)
                        elseif s == s_init then
                            setstate(last,s_isol)
                        end
                        setstate(current,s_isol)
                        prevstate = s_isol
                    end
                    prevjoin = currjoin
                    last = current
                elseif prevjoin == "nj" or prevjoin == "r" then
                    if s == s_medi then
                        setstate(last,s_fina)
                    elseif s == s_init then
                        setstate(last,s_isol)
                    end
                    setstate(current,s_isol)
                    prevjoin = currjoin
                    prevstate = s_isol
                    last = current
                elseif last then
                    wrapup()
                end
            else
                if last then
                    wrapup()
                end
                if id == math_code then -- a bit duplicate as we test for glyphs twice
                    current = endofmath(current)
                end
            end
            current = getnext(current)
        end
        if last then
            wrapup()
        end
        return head, done
    end

end

directives.register("otf.analyze.useunicodemarks",function(v)
    analyzers.useunicodemarks = v
end)
