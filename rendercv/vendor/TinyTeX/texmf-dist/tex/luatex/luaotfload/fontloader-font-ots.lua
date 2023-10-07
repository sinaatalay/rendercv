if not modules then modules = { } end modules ['font-ots'] = { -- sequences
    version   = 1.001,
    optimize  = true,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files",
}

-- I need to check the description at the microsoft site ... it has been improved so
-- maybe there are some interesting details there. Most below is based on old and
-- incomplete documentation and involved quite a bit of guesswork (checking with the
-- abstract uniscribe of those days. But changing things is tricky!
--
-- This module is a bit more split up that I'd like but since we also want to test
-- with plain TeX it has to be so. This module is part of ConTeXt and discussion
-- about improvements and functionality mostly happens on the ConTeXt mailing list.
--
-- The specification of OpenType is (or at least decades ago was) kind of vague.
-- Apart from a lack of a proper free specifications there's also the problem that
-- Microsoft and Adobe may have their own interpretation of how and in what order to
-- apply features. In general the Microsoft website has more detailed specifications
-- and is a better reference. There is also some information in the FontForge help
-- files. In the end we rely most on the Microsoft specification.
--
-- Because there is so much possible, fonts might contain bugs and/or be made to
-- work with certain rederers. These may evolve over time which may have the side
-- effect that suddenly fonts behave differently. We don't want to catch all font
-- issues.
--
-- After a lot of experiments (mostly by Taco, me and Idris) the first
-- implementation was already quite useful. When it did most of what we wanted, a
-- more optimized version evolved. Of course all errors are mine and of course the
-- code can be improved. There are quite some optimizations going on here and
-- processing speed is currently quite acceptable and has been improved over time.
-- Many complex scripts are not yet supported yet, but I will look into them as soon
-- as ConTeXt users ask for it.
--
-- The specification leaves room for interpretation. In case of doubt the Microsoft
-- implementation is the reference as it is the most complete one. As they deal with
-- lots of scripts and fonts, Kai and Ivo did a lot of testing of the generic code
-- and their suggestions help improve the code. I'm aware that not all border cases
-- can be taken care of, unless we accept excessive runtime, and even then the
-- interference with other mechanisms (like hyphenation) are not trivial.
--
-- Especially discretionary handling has been improved much by Kai Eigner who uses
-- complex (latin) fonts. The current implementation is a compromis between his
-- patches and my code and in the meantime performance is quite ok. We cannot check
-- all border cases without compromising speed but so far we're okay. Given good
-- test cases we can probably improve it here and there. Especially chain lookups
-- are non trivial with discretionaries but things got much better over time thanks
-- to Kai.
--
-- Glyphs are indexed not by unicode but in their own way. This is because there is
-- no relationship with unicode at all, apart from the fact that a font might cover
-- certain ranges of characters. One character can have multiple shapes. However, at
-- the TeX end we use unicode so and all extra glyphs are mapped into a private
-- space. This is needed because we need to access them and TeX has to include then
-- in the output eventually.
--
-- The initial data table is rather close to the open type specification and also
-- not that different from the one produced by Fontforge but we uses hashes instead.
-- In ConTeXt that table is packed (similar tables are shared) and cached on disk so
-- that successive runs can use the optimized table (after loading the table is
-- unpacked).
--
-- This module is sparsely documented because it is has been a moving target. The
-- table format of the reader changed a bit over time and we experiment a lot with
-- different methods for supporting features. By now the structures are quite stable
--
-- Incrementing the version number will force a re-cache. We jump the number by one
-- when there's a fix in the reader or processing code that can result in different
-- results.
--
-- This code is also used outside ConTeXt but in ConTeXt it has to work with other
-- mechanisms. Both put some constraints on the code here.
--
-- Remark: We assume that cursives don't cross discretionaries which is okay because
-- it is only used in semitic scripts.
--
-- Remark: We assume that marks precede base characters.
--
-- Remark: When complex ligatures extend into discs nodes we can get side effects.
-- Normally this doesn't happen; ff\d{l}{l}{l} in lm works but ff\d{f}{f}{f}.
--
-- Todo: check if we copy attributes to disc nodes if needed.
--
-- Todo: it would be nice if we could get rid of components. In other places we can
-- use the unicode properties. We can just keep a lua table.
--
-- Remark: We do some disc juggling where we need to keep in mind that the pre, post
-- and replace fields can have prev pointers to a nesting node ... I wonder if that
-- is still needed.
--
-- Remark: This is not possible:
--
-- \discretionary {alpha-} {betagammadelta}
--   {\discretionary {alphabeta-} {gammadelta}
--      {\discretionary {alphabetagamma-} {delta}
--         {alphabetagammadelta}}}
--
-- Remark: Something is messed up: we have two mark / ligature indices, one at the
-- injection end and one here ... this is based on KE's patches but there is something
-- fishy there as I'm pretty sure that for husayni we need some connection (as it's much
-- more complex than an average font) but I need proper examples of all cases, not of
-- only some.
--
-- Remark: I wonder if indexed would be faster than unicoded. It would be a major
-- rewrite to have char being unicode + an index field in glyph nodes. Also more
-- assignments have to be made in order to keep things in sync. So, it's a no-go.
--
-- Remark: We can provide a fast loop when there are no disc nodes (tests show a 1%
-- gain). Smaller functions might perform better cache-wise. But ... memory becomes
-- faster anyway, so ...
--
-- Remark: Some optimizations made sense for 5.2 but seem less important for 5.3 but
-- anyway served their purpose.
--
-- Todo: just (0=l2r and 1=r2l) or maybe (r2l = true)

-- Experiments with returning the data with the ischar are positive for lmtx but
-- have a performance hit on mkiv because there we need to wrap ischardata (pending
-- extensions to luatex which is unlikely to happen for such an experiment because
-- we then can't remove it). Actually it might make generic slightly faster. Also,
-- there are some corner cases where a data check comes before a char fetch and
-- we're talking of millions of calls there. At some point I might make a version
-- for lmtx that does it slightly different anyway.

local type, next, tonumber = type, next, tonumber
local random = math.random
local formatters = string.formatters
local insert = table.insert

local registertracker      = trackers.register

local logs                 = logs
local trackers             = trackers
local nodes                = nodes
local attributes           = attributes
local fonts                = fonts

local otf                  = fonts.handlers.otf
local tracers              = nodes.tracers

local trace_singles        = false  registertracker("otf.singles",      function(v) trace_singles      = v end)
local trace_multiples      = false  registertracker("otf.multiples",    function(v) trace_multiples    = v end)
local trace_alternatives   = false  registertracker("otf.alternatives", function(v) trace_alternatives = v end)
local trace_ligatures      = false  registertracker("otf.ligatures",    function(v) trace_ligatures    = v end)
local trace_contexts       = false  registertracker("otf.contexts",     function(v) trace_contexts     = v end)
local trace_marks          = false  registertracker("otf.marks",        function(v) trace_marks        = v end)
local trace_kerns          = false  registertracker("otf.kerns",        function(v) trace_kerns        = v end)
local trace_cursive        = false  registertracker("otf.cursive",      function(v) trace_cursive      = v end)
local trace_preparing      = false  registertracker("otf.preparing",    function(v) trace_preparing    = v end)
local trace_bugs           = false  registertracker("otf.bugs",         function(v) trace_bugs         = v end)
local trace_details        = false  registertracker("otf.details",      function(v) trace_details      = v end)
local trace_steps          = false  registertracker("otf.steps",        function(v) trace_steps        = v end)
local trace_skips          = false  registertracker("otf.skips",        function(v) trace_skips        = v end)
local trace_plugins        = false  registertracker("otf.plugins",      function(v) trace_plugins      = v end)
local trace_chains         = false  registertracker("otf.chains",       function(v) trace_chains       = v end)

local trace_kernruns       = false  registertracker("otf.kernruns",     function(v) trace_kernruns     = v end)
----- trace_discruns       = false  registertracker("otf.discruns",     function(v) trace_discruns     = v end)
local trace_compruns       = false  registertracker("otf.compruns",     function(v) trace_compruns     = v end)
local trace_testruns       = false  registertracker("otf.testruns",     function(v) trace_testruns     = v end)

local forcediscretionaries = false
local forcepairadvance     = false -- for testing

local repeatablemultiples  = context or false

directives.register("otf.forcediscretionaries", function(v) forcediscretionaries = v end)
directives.register("otf.forcepairadvance",     function(v) forcepairadvance     = v end)

local report_direct      = logs.reporter("fonts","otf direct")
local report_subchain    = logs.reporter("fonts","otf subchain")
local report_chain       = logs.reporter("fonts","otf chain")
local report_process     = logs.reporter("fonts","otf process")
local report_warning     = logs.reporter("fonts","otf warning")
local report_run         = logs.reporter("fonts","otf run")

registertracker("otf.substitutions", "otf.singles","otf.multiples","otf.alternatives","otf.ligatures")
registertracker("otf.positions",     "otf.marks","otf.kerns","otf.cursive")
registertracker("otf.actions",       "otf.substitutions","otf.positions")
registertracker("otf.sample",        "otf.steps","otf.substitutions","otf.positions","otf.analyzing")
registertracker("otf.sample.silent", "otf.steps=silent","otf.substitutions","otf.positions","otf.analyzing")

local nuts               = nodes.nuts

local getnext            = nuts.getnext
local setnext            = nuts.setnext
local getprev            = nuts.getprev
local setprev            = nuts.setprev
local getboth            = nuts.getboth
local setboth            = nuts.setboth
local getid              = nuts.getid
local getstate           = nuts.getstate
local getsubtype         = nuts.getsubtype
local getchar            = nuts.getchar
local setchar            = nuts.setchar
local getdisc            = nuts.getdisc
local setdisc            = nuts.setdisc
local getreplace         = nuts.getreplace
local setlink            = nuts.setlink
local getwidth           = nuts.getwidth
local getattr            = nuts.getattr

local getglyphdata       = nuts.getglyphdata

---------------------------------------------------------------------------------------

-- Beware: In ConTeXt components no longer are real components. We only keep track of
-- their positions because some complex ligatures might need that. For the moment we
-- use an x_ prefix because for now generic follows the other approach.

local components         = nuts.components
local copynocomponents   = components.copynocomponents
local copyonlyglyphs     = components.copyonlyglyphs
local countcomponents    = components.count
local setcomponents      = components.set
local getcomponents      = components.get
local flushcomponents    = components.flush

---------------------------------------------------------------------------------------

local ischar             = nuts.ischar
local usesfont           = nuts.usesfont

local insertnodeafter    = nuts.insertafter
local copynode           = nuts.copy
local copynodelist       = nuts.copylist
local removenode         = nuts.remove
local findnodetail       = nuts.tail
local flushnodelist      = nuts.flushlist
local flushnode          = nuts.flushnode
local endofmath          = nuts.endofmath

local startofpar         = nuts.startofpar

local setmetatable       = setmetatable
local setmetatableindex  = table.setmetatableindex

local nextnode           = nuts.traversers.node

local nodecodes          = nodes.nodecodes
local glyphcodes         = nodes.glyphcodes

local glyph_code         = nodecodes.glyph
local glue_code          = nodecodes.glue
local disc_code          = nodecodes.disc
local math_code          = nodecodes.math
local dir_code           = nodecodes.dir
local par_code           = nodecodes.par

local lefttoright_code   = nodes.dirvalues.lefttoright
local righttoleft_code   = nodes.dirvalues.righttoleft

local discretionarydisc_code = nodes.disccodes.discretionary

local a_noligature       = attributes.private("noligature")

local injections         = nodes.injections
local setmark            = injections.setmark
local setcursive         = injections.setcursive
local setkern            = injections.setkern
local setmove            = injections.setmove
local setposition        = injections.setposition
local resetinjection     = injections.reset
local copyinjection      = injections.copy
local setligaindex       = injections.setligaindex
local getligaindex       = injections.getligaindex

local fontdata           = fonts.hashes.identifiers
local fontfeatures       = fonts.hashes.features

local otffeatures        = fonts.constructors.features.otf
local registerotffeature = otffeatures.register

local onetimemessage     = fonts.loggers.onetimemessage or function() end

local getrandom          = utilities and utilities.randomizer and utilities.randomizer.get

otf.defaultnodealternate = "none" -- first last

-- We use a few semi-global variables. The handler can be called nested but this assumes
-- that the same font is used.

local tfmdata            = false
local characters         = false
local descriptions       = false
local marks              = false
local classes            = false
local currentfont        = false
local factor             = 0
local threshold          = 0
local checkmarks         = false

local discs              = false
local spaces             = false

local sweepnode          = nil
local sweephead          = { } -- we don't nil entries but false them (no collection and such)

local notmatchpre        = { } -- to be checked: can we use false instead of nil / what if a == b tests
local notmatchpost       = { } -- to be checked: can we use false instead of nil / what if a == b tests
local notmatchreplace    = { } -- to be checked: can we use false instead of nil / what if a == b tests

local handlers           = { }

local isspace            = injections.isspace
local getthreshold       = injections.getthreshold

local checkstep          = (tracers and tracers.steppers.check)    or function() end
local registerstep       = (tracers and tracers.steppers.register) or function() end
local registermessage    = (tracers and tracers.steppers.message)  or function() end

local function logprocess(...)
    if trace_steps then
        registermessage(...)
        if trace_steps == "silent" then
            return
        end
    end
    report_direct(...)
end

local function logwarning(...)
    report_direct(...)
end

local gref  do

    local f_unicode = formatters["U+%X"]      -- was ["%U"]
    local f_uniname = formatters["U+%X (%s)"] -- was ["%U (%s)"]
    local f_unilist = formatters["% t"]

    gref = function(n) -- currently the same as in font-otb
        if type(n) == "number" then
            local description = descriptions[n]
            local name = description and description.name
            if name then
                return f_uniname(n,name)
            else
                return f_unicode(n)
            end
        elseif n then
            local t = { }
            for i=1,#n do
                local ni = n[i]
                if tonumber(ni) then -- later we will start at 2
                    local di = descriptions[ni]
                    local nn = di and di.name
                    if nn then
                        t[#t+1] = f_uniname(ni,nn)
                    else
                        t[#t+1] = f_unicode(ni)
                    end
                end
            end
            return f_unilist(t)
        else
            return "<error in node mode tracing>"
        end
    end

end

local function cref(dataset,sequence,index)
    if not dataset then
        return "no valid dataset"
    end
    local merged = sequence.merged and "merged " or ""
    if index and index > 1 then
        return formatters["feature %a, type %a, %schain lookup %a, index %a"](
            dataset[4],sequence.type,merged,sequence.name,index)
    else
        return formatters["feature %a, type %a, %schain lookup %a"](
            dataset[4],sequence.type,merged,sequence.name)
    end
end

local function pref(dataset,sequence)
    return formatters["feature %a, type %a, %slookup %a"](
        dataset[4],sequence.type,sequence.merged and "merged " or "",sequence.name)
end

local function mref(rlmode)
    if not rlmode or rlmode >= 0 then
        return "l2r"
    else
        return "r2l"
    end
end

-- The next code is somewhat complicated by the fact that some fonts can have ligatures made
-- from ligatures that themselves have marks. This was identified by Kai in for instance
-- arabtype:  KAF LAM SHADDA ALEF FATHA (0x0643 0x0644 0x0651 0x0627 0x064E). This becomes
-- KAF LAM-ALEF with a SHADDA on the first and a FATHA op de second component. In a next
-- iteration this becomes a KAF-LAM-ALEF with a SHADDA on the second and a FATHA on the
-- third component.

-- We can assume that languages that use marks are not hyphenated. We can also assume
-- that at most one discretionary is present.

-- We do need components in funny kerning mode but maybe I can better reconstruct then
-- as we do have the font components info available; removing components makes the
-- previous code much simpler. Also, later on copying and freeing becomes easier.
-- However, for arabic we need to keep them around for the sake of mark placement
-- and indices.

local function flattendisk(head,disc)
    local pre, post, replace, pretail, posttail, replacetail = getdisc(disc,true)
    local prev, next = getboth(disc)
    local ishead = head == disc
    setdisc(disc)
    flushnode(disc)
    if pre then
        flushnodelist(pre)
    end
    if post then
        flushnodelist(post)
    end
    if ishead then
        if replace then
            if next then
                setlink(replacetail,next)
            end
            return replace, replace
        elseif next then
            return next, next
        else
         -- return -- maybe warning
        end
    else
        if replace then
            if next then
                setlink(replacetail,next)
            end
            setlink(prev,replace)
            return head, replace
        else
            setlink(prev,next) -- checks for next anyway
            return head, next
        end
    end
end

local function appenddisc(disc,list)
    local pre, post, replace, pretail, posttail, replacetail = getdisc(disc,true)
    local posthead    = list
    local replacehead = copynodelist(list)
    if post then
        setlink(posttail,posthead)
    else
        post = posthead
    end
    if replace then
        setlink(replacetail,replacehead)
    else
        replace = replacehead
    end
    setdisc(disc,pre,post,replace)
end

local function markstoligature(head,start,stop,char)
    if start == stop and getchar(start) == char then
        return head, start
    else
        local prev = getprev(start)
        local next = getnext(stop)
        setprev(start)
        setnext(stop)
        local base = copynocomponents(start,copyinjection)
        if head == start then
            head = base
        end
        resetinjection(base)
        setchar(base,char)
        setcomponents(base,start)
        setlink(prev,base,next)
        flushcomponents(start)
        return head, base
    end
end

-- Remark for Kai: (some arabic fonts do mark + mark = other mark and such)
--
-- The hasmarks is needed for ligatures of marks that are part of a ligature in
-- which case we assume that we can delete the marks anyway (we can always become
-- more clever if needed) .. in fact the whole logic here should be redone. We're
-- in the not discfound branch then. We now have skiphash too so we can be more
-- selective if needed (todo).

-- we can have more granularity here but for now we only do a simple check

local no_left_ligature_code  = 1
local no_right_ligature_code = 2
local no_left_kern_code      = 4
local no_right_kern_code     = 8

local hasglyphoption = function(n,c)
    if c == no_left_ligature_code or c == no_right_ligature_code then
        return getattr(n,a_noligature) == 1
    else
        return false
    end
end

-- in lmtx we need to check the components and can be slightly more clever

local function toligature(head,start,stop,char,dataset,sequence,skiphash,discfound,hasmarks) -- brr head
    if hasglyphoption(start,no_right_ligature_code) then
        return head, start
    end
    if start == stop and getchar(start) == char then
        resetinjection(start)
        setchar(start,char)
        return head, start
    end
    local prev = getprev(start)
    local next = getnext(stop)
    local comp = start
    setprev(start)
    setnext(stop)
    local base = copynocomponents(start,copyinjection)
    if start == head then
        head = base
    end
    resetinjection(base)
    setchar(base,char)
    setcomponents(base,comp)
    setlink(prev,base,next)
    if not discfound then
        local deletemarks = not skiphash or hasmarks
        local components = start -- not used
        local baseindex = 0
        local componentindex = 0
        local head = base
        local current = base
        -- first we loop over the glyphs in start ... stop
        while start do
            local char = getchar(start)
            if not marks[char] then
                baseindex = baseindex + componentindex
                componentindex = countcomponents(start,marks)
             -- we can be more clever here: "not deletemarks or (skiphash and not skiphash[char])"
             -- and such:
            elseif not deletemarks then
                -- we can get a loop when the font expects otherwise (i.e. unexpected deletemarks)
                setligaindex(start,baseindex + getligaindex(start,componentindex))
                if trace_marks then
                    logwarning("%s: keep ligature mark %s, gets index %s",pref(dataset,sequence),gref(char),getligaindex(start))
                end
                local n = copynode(start)
                copyinjection(n,start) -- is this ok ? we position later anyway
                head, current = insertnodeafter(head,current,n) -- unlikely that mark has components
            elseif trace_marks then
                logwarning("%s: delete ligature mark %s",pref(dataset,sequence),gref(char))
            end
            start = getnext(start)
        end
        -- we can have one accent as part of a lookup and another following
        local start = getnext(current)
        while start do
            local char = ischar(start)
            if char then
                -- also something skiphash here?
                if marks[char] then
                    setligaindex(start,baseindex + getligaindex(start,componentindex))
                    if trace_marks then
                        logwarning("%s: set ligature mark %s, gets index %s",pref(dataset,sequence),gref(char),getligaindex(start))
                    end
                    start = getnext(start)
                else
                    break
                end
            else
                break
            end
        end
        flushcomponents(components)
    else
        -- discfound ... forget about marks .. probably no scripts that hyphenate and have marks
        local discprev, discnext = getboth(discfound)
        if discprev and discnext then
            -- we assume normalization in context, and don't care about generic ... especially
            -- \- can give problems as there we can have a negative char but that won't match
            -- anyway
            local pre, post, replace, pretail, posttail, replacetail = getdisc(discfound,true)
            if not replace then
                -- looks like we never come here as it's not okay
                local prev = getprev(base)
             -- local comp = getcomponents(base) -- already set
                local copied = copyonlyglyphs(comp)
                if pre then
                    setlink(discprev,pre)
                else
                    setnext(discprev) -- also blocks funny assignments
                end
                pre = comp -- is start
                if post then
                    setlink(posttail,discnext)
                    setprev(post) -- nil anyway
                else
                    post = discnext
                    setprev(discnext) -- also blocks funny assignments
                end
                setlink(prev,discfound,next)
                setboth(base)
                -- here components have a pointer so we can't free it!
                setcomponents(base,copied)
                replace = base
                if forcediscretionaries then
                    setdisc(discfound,pre,post,replace,discretionarydisc_code)
                else
                    setdisc(discfound,pre,post,replace)
                end
                base = prev
            end
        end
    end
    return head, base
end

local function multiple_glyphs(head,start,multiple,skiphash,what,stop) -- what to do with skiphash matches here
    local nofmultiples = #multiple
    if nofmultiples > 0 then
        local first = start
        resetinjection(start)
        setchar(start,multiple[1])
        if nofmultiples > 1 then
         -- local sn = getnext(start)
            for i=2,nofmultiples do
             -- untested:
             --
             -- while ignoremarks and marks[getchar(sn)] then
             --     local sn = getnext(sn)
             -- end
                local n = copynode(start) -- ignore components
                resetinjection(n)
                setchar(n,multiple[i])
                insertnodeafter(head,start,n)
                start = n
            end
        end
        if what ~= true and repeatablemultiples then
            -- This is just some experimental code; we might introduce gsub_extensible
            -- some day instead. Beware: when we have a feature that mixes alternates and
            -- multiples we need to make sure we don't handle the alternate string values
            -- here.
            local kind = type(what)
            local m, f, l
            if kind == "string" then
                local what, n = string.match(what,"^repeat(.-)[:=](%d+)$")
                if what == "middle" then
                    m = tonumber(n)
                elseif what == "first" then
                    f = tonumber(n)
                elseif what == "last" then
                    l = tonumber(n)
                end
            elseif kind == "table" then
                -- won't happen because currently we don't split these values
               m = what.middle
               f = what.first
               l = what.last
            end
            if f or m or l then
                if m and m > 1 and nofmultiples == 3 then
                    local middle = getnext(first)
                    for i=2,m do
                        local n = copynode(middle) -- ignore components
                        resetinjection(n)
                        insertnodeafter(head,first,n)
                    end
                end
                if f and f > 1 then
                    for i=2,f do
                        local n = copynode(first) -- ignore components
                        resetinjection(n)
                        insertnodeafter(head,first,n)
                    end
                end
                if l and l > 1 then
                    for i=2,l do
                        local n = copynode(start) -- ignore components
                        resetinjection(n)
                        insertnodeafter(head,start,n)
                        start = n
                    end
                end
            end
        end
        return head, start, true
    else
        if trace_multiples then
            logprocess("no multiple for %s",gref(getchar(start)))
        end
        return head, start, false
    end
end

local function get_alternative_glyph(start,alternatives,value)
    local n = #alternatives
    if n == 1 then
        -- we could actually change that into a gsub and save some memory in the
        -- font loader but it makes tracing more messy
        return alternatives[1], trace_alternatives and "1 (only one present)"
    elseif value == "random" then
        local r = getrandom and getrandom("glyph",1,n) or random(1,n)
        return alternatives[r], trace_alternatives and formatters["value %a, taking %a"](value,r)
    elseif value == "first" then
        return alternatives[1], trace_alternatives and formatters["value %a, taking %a"](value,1)
    elseif value == "last" then
        return alternatives[n], trace_alternatives and formatters["value %a, taking %a"](value,n)
    end
    value = value == true and 1 or tonumber(value)
    if type(value) ~= "number" then
        return alternatives[1], trace_alternatives and formatters["invalid value %s, taking %a"](value,1)
    end
 -- local a = alternatives[value]
 -- if a then
 --     -- some kind of hash
 --     return a, trace_alternatives and formatters["value %a, taking %a"](value,a)
 -- end
    if value > n then
        local defaultalt = otf.defaultnodealternate
        if defaultalt == "first" then
            return alternatives[n], trace_alternatives and formatters["invalid value %s, taking %a"](value,1)
        elseif defaultalt == "last" then
            return alternatives[1], trace_alternatives and formatters["invalid value %s, taking %a"](value,n)
        else
            return false, trace_alternatives and formatters["invalid value %a, %s"](value,"out of range")
        end
    elseif value == 0 then
        return getchar(start), trace_alternatives and formatters["invalid value %a, %s"](value,"no change")
    elseif value < 1 then
        return alternatives[1], trace_alternatives and formatters["invalid value %a, taking %a"](value,1)
    else
        return alternatives[value], trace_alternatives and formatters["value %a, taking %a"](value,value)
    end
end

-- handlers

function handlers.gsub_single(head,start,dataset,sequence,replacement)
    if trace_singles then
        logprocess("%s: replacing %s by single %s",pref(dataset,sequence),gref(getchar(start)),gref(replacement))
    end
    resetinjection(start)
    setchar(start,replacement)
    return head, start, true
end

function handlers.gsub_alternate(head,start,dataset,sequence,alternative)
    local kind  = dataset[4]
    local what  = dataset[1]
    local value = what == true and tfmdata.shared.features[kind] or what
    local choice, comment = get_alternative_glyph(start,alternative,value)
    if choice then
        if trace_alternatives then
            logprocess("%s: replacing %s by alternative %a to %s, %s",pref(dataset,sequence),gref(getchar(start)),gref(choice),comment)
        end
        resetinjection(start)
        setchar(start,choice)
    else
        if trace_alternatives then
            logwarning("%s: no variant %a for %s, %s",pref(dataset,sequence),value,gref(getchar(start)),comment)
        end
    end
    return head, start, true
end

function handlers.gsub_multiple(head,start,dataset,sequence,multiple,rlmode,skiphash)
    if trace_multiples then
        logprocess("%s: replacing %s by multiple %s",pref(dataset,sequence),gref(getchar(start)),gref(multiple))
    end
    return multiple_glyphs(head,start,multiple,skiphash,dataset[1])
end

-- Don't we deal with disc otherwise now? I need to check if the next one can be
-- simplified. Anyway, it can be way messier: marks that get removed as well as
-- marks that are kept.

function handlers.gsub_ligature(head,start,dataset,sequence,ligature,rlmode,skiphash)
    local current   = getnext(start)
    if not current then
        return head, start, false, nil
    end
    local stop      = nil
    local startchar = getchar(start)
    if skiphash and skiphash[startchar] then
        while current do
            local char = ischar(current,currentfont)
            if char then
                local lg = not tonumber(ligature) and ligature[char]
                if lg then
                    stop     = current
                    ligature = lg
                    current  = getnext(current)
                else
                    break
                end
            else
                break
            end
        end
        if stop then
            local ligature = tonumber(ligature) or ligature.ligature
            if ligature then
                if trace_ligatures then
                    local stopchar = getchar(stop)
                    head, start = markstoligature(head,start,stop,ligature)
                    logprocess("%s: replacing %s upto %s by ligature %s case 1",pref(dataset,sequence),gref(startchar),gref(stopchar),gref(getchar(start)))
                else
                    head, start = markstoligature(head,start,stop,ligature)
                end
                return head, start, true, false
            else
                -- ok, goto next lookup
            end
        end
    else
        local discfound = false
        local hasmarks  = marks[startchar]
        while current do
            local char, id = ischar(current,currentfont)
            if char then
                if skiphash and skiphash[char] then
                    current = getnext(current)
                else
                    local lg = not tonumber(ligature) and ligature[char]
                    if lg then
                        if marks[char] then
                            hasmarks = true
                        end
                        stop     = current -- needed for fake so outside then
                        ligature = lg
                        current  = getnext(current)
                    else
                        break
                    end
                end
            elseif char == false then
                -- kind of weird
                break
            elseif id == disc_code then
                discfound = current
                break
            else
                break
            end
        end
        -- of{f-}{}{f}e  o{f-}{}{f}fe  o{-}{}{ff}e (oe and ff ligature)
        -- we can end up here when we have a start run .. testruns start at a disc but
        -- so here we have the other case: char + disc
        --
        -- Challenge for Kai (latinmodern):  \hyphenation{fii-f-f-iif} fiiffiif
        --
        if discfound then
            -- don't assume marks in a disc and we don't run over a disc (for now)
            local pre, post, replace = getdisc(discfound)
            local match
            if replace then
                local char = ischar(replace,currentfont)
                if char and (not tonumber(ligature) and ligature[char]) then
                    match = true
                end
            end
            if not match and pre then
                local char = ischar(pre,currentfont)
                if char and (not tonumber(ligature) and ligature[char]) then
                    match = true
                end
            end
            if not match and not pre or not replace then
                local n    = getnext(discfound)
                local char = ischar(n,currentfont)
                if char and (not tonumber(ligature) and ligature[char]) then
                    match = true
                end
            end
            if match then
                -- we force a restart
                local ishead = head == start
                local prev   = getprev(start)
                if stop then
                    setnext(stop)
                    local copy = copynodelist(start)
                    local tail = stop -- was: getprev(stop) -- Kai: needs checking on your samples
                    local liat = findnodetail(copy)
                    if pre then
                        setlink(liat,pre)
                    end
                    if replace then
                        setlink(tail,replace)
                    end
                    pre     = copy
                    replace = start
                else
                    setnext(start)
                    local copy = copynode(start)
                    if pre then
                        setlink(copy,pre)
                    end
                    if replace then
                        setlink(start,replace)
                    end
                    pre     = copy
                    replace = start
                end
                setdisc(discfound,pre,post,replace)
                if prev then
                    setlink(prev,discfound)
                else
                    setprev(discfound)
                    head  = discfound
                end
                start = discfound
                return head, start, true, true
            end
        end
        local ligature = tonumber(ligature) or ligature.ligature
        if ligature then
            if stop then
                if trace_ligatures then
                    local stopchar = getchar(stop)
                 -- head, start = toligature(head,start,stop,ligature,dataset,sequence,skiphash,discfound,hasmarks)
                    head, start = toligature(head,start,stop,ligature,dataset,sequence,skiphash,false,hasmarks)
                    logprocess("%s: replacing %s upto %s by ligature %s case 2",pref(dataset,sequence),gref(startchar),gref(stopchar),gref(ligature))
                 -- we can have a rare case of multiple disc in a lig but that makes no sense language wise but if really
                 -- needed we could backtrack if we're in a disc node
                else
                 -- head, start = toligature(head,start,stop,ligature,dataset,sequence,skiphash,discfound,hasmarks)
                    head, start = toligature(head,start,stop,ligature,dataset,sequence,skiphash,false,hasmarks)
                end
            else
                -- weird but happens (in some arabic font)
                resetinjection(start)
                setchar(start,ligature)
                if trace_ligatures then
                    logprocess("%s: replacing %s by (no real) ligature %s case 3",pref(dataset,sequence),gref(startchar),gref(ligature))
                end
            end
            return head, start, true, false
        else
            -- weird but happens, pseudo ligatures ... just the components
        end
    end
    return head, start, false, false
end

function handlers.gpos_single(head,start,dataset,sequence,kerns,rlmode,skiphash,step,injection)
    if hasglyphoption(start,no_right_kern_code) then
        return head, start, false
    else
        local startchar = getchar(start)
        local format    = step.format
        if format == "single" or type(kerns) == "table" then -- the table check can go
            local dx, dy, w, h = setposition(0,start,factor,rlmode,kerns,injection)
            if trace_kerns then
                logprocess("%s: shifting single %s by %s xy (%p,%p) and wh (%p,%p)",pref(dataset,sequence),gref(startchar),format,dx,dy,w,h)
            end
        else
            local k = (format == "move" and setmove or setkern)(start,factor,rlmode,kerns,injection)
            if trace_kerns then
                logprocess("%s: shifting single %s by %s %p",pref(dataset,sequence),gref(startchar),format,k)
            end
        end
        return head, start, true
    end
end

function handlers.gpos_pair(head,start,dataset,sequence,kerns,rlmode,skiphash,step,injection)
    if hasglyphoption(start,no_right_kern_code) then
        return head, start, false
    else
        local snext = getnext(start)
        if not snext then
            return head, start, false
        else
            local prev = start
            while snext do
                local nextchar = ischar(snext,currentfont)
                if nextchar then
                    if skiphash and skiphash[nextchar] then -- includes marks too when flag
                        prev  = snext
                        snext = getnext(snext)
                    else
                        local krn = kerns[nextchar]
                        if not krn then
                            break
                        end
                        local format = step.format
                        if format == "pair" then
                            local a = krn[1]
                            local b = krn[2]
                            if a == true then
                                -- zero
                            elseif a then -- #a > 0
                                local x, y, w, h = setposition(1,start,factor,rlmode,a,injection)
                                if trace_kerns then
                                    local startchar = getchar(start)
                                    logprocess("%s: shifting first of pair %s and %s by xy (%p,%p) and wh (%p,%p) as %s",pref(dataset,sequence),gref(startchar),gref(nextchar),x,y,w,h,injection or "injections")
                                end
                            end
                            if b == true then
                                -- zero
                                start = snext -- cf spec
                            elseif b then -- #b > 0
                                local x, y, w, h = setposition(2,snext,factor,rlmode,b,injection)
                                if trace_kerns then
                                    local startchar = getchar(start)
                                    logprocess("%s: shifting second of pair %s and %s by xy (%p,%p) and wh (%p,%p) as %s",pref(dataset,sequence),gref(startchar),gref(nextchar),x,y,w,h,injection or "injections")
                                end
                                start = snext -- cf spec
                            elseif forcepairadvance then
                                start = snext -- for testing, not cf spec
                            end
                            return head, start, true
                        elseif krn ~= 0 then
                            local k = (format == "move" and setmove or setkern)(snext,factor,rlmode,krn,injection)
                            if trace_kerns then
                                logprocess("%s: inserting %s %p between %s and %s as %s",pref(dataset,sequence),format,k,gref(getchar(prev)),gref(nextchar),injection or "injections")
                            end
                            return head, start, true
                        else -- can't happen
                            break
                        end
                    end
                else
                    break
                end
            end
            return head, start, false
        end
    end
end

-- We get hits on a mark, but we're not sure if the it has to be applied so we need
-- to explicitly test for basechar, baselig and basemark entries.

function handlers.gpos_mark2base(head,start,dataset,sequence,markanchors,rlmode,skiphash)
    local markchar = getchar(start)
    if marks[markchar] then
        local base = getprev(start) -- [glyph] [start=mark]
        if base then
            local basechar = ischar(base,currentfont)
            if basechar then
                if marks[basechar] then
                    while base do
                        base = getprev(base)
                        if base then
                            basechar = ischar(base,currentfont)
                            if basechar then
                                if not marks[basechar] then
                                    break
                                end
                            else
                                if trace_bugs then
                                    logwarning("%s: no base for mark %s, case %i",pref(dataset,sequence),gref(markchar),1)
                                end
                                return head, start, false
                            end
                        else
                            if trace_bugs then
                                logwarning("%s: no base for mark %s, case %i",pref(dataset,sequence),gref(markchar),2)
                            end
                            return head, start, false
                        end
                    end
                end
                local ba = markanchors[1][basechar]
                if ba then
                    local ma = markanchors[2]
                    local dx, dy, bound = setmark(start,base,factor,rlmode,ba,ma,characters[basechar],false,checkmarks)
                    if trace_marks then
                        logprocess("%s, bound %s, anchoring mark %s to basechar %s => (%p,%p)",
                            pref(dataset,sequence),bound,gref(markchar),gref(basechar),dx,dy)
                    end
                    return head, start, true
                elseif trace_bugs then
                 -- onetimemessage(currentfont,basechar,"no base anchors")
                    logwarning("%s: mark %s is not anchored to %s",pref(dataset,sequence),gref(markchar),gref(basechar))
                end
            elseif trace_bugs then
                logwarning("%s: nothing preceding, case %i",pref(dataset,sequence),1)
            end
        elseif trace_bugs then
            logwarning("%s: nothing preceding, case %i",pref(dataset,sequence),2)
        end
    elseif trace_bugs then
        logwarning("%s: mark %s is no mark",pref(dataset,sequence),gref(markchar))
    end
    return head, start, false
end

function handlers.gpos_mark2ligature(head,start,dataset,sequence,markanchors,rlmode,skiphash)
    local markchar = getchar(start)
    if marks[markchar] then
        local base = getprev(start) -- [glyph] [optional marks] [start=mark]
        if base then
            local basechar = ischar(base,currentfont)
            if basechar then
                if marks[basechar] then
                    while base do
                        base = getprev(base)
                        if base then
                            basechar = ischar(base,currentfont)
                            if basechar then
                                if not marks[basechar] then
                                    break
                                end
                            else
                                if trace_bugs then
                                    logwarning("%s: no base for mark %s, case %i",pref(dataset,sequence),gref(markchar),1)
                                end
                                return head, start, false
                            end
                        else
                            if trace_bugs then
                                logwarning("%s: no base for mark %s, case %i",pref(dataset,sequence),gref(markchar),2)
                            end
                            return head, start, false
                        end
                    end
                end
                local ba = markanchors[1][basechar]
                if ba then
                    local ma = markanchors[2]
                    if ma then
                        local index = getligaindex(start)
                        ba = ba[index]
                        if ba then
                            local dx, dy, bound = setmark(start,base,factor,rlmode,ba,ma,characters[basechar],false,checkmarks)
                            if trace_marks then
                                logprocess("%s, index %s, bound %s, anchoring mark %s to baselig %s at index %s => (%p,%p)",
                                    pref(dataset,sequence),index,bound,gref(markchar),gref(basechar),index,dx,dy)
                            end
                            return head, start, true
                        else
                            if trace_bugs then
                                logwarning("%s: no matching anchors for mark %s and baselig %s with index %a",pref(dataset,sequence),gref(markchar),gref(basechar),index)
                            end
                        end
                    end
                elseif trace_bugs then
                --  logwarning("%s: char %s is missing in font",pref(dataset,sequence),gref(basechar))
                    onetimemessage(currentfont,basechar,"no base anchors")
                end
            elseif trace_bugs then
                logwarning("%s: prev node is no char, case %i",pref(dataset,sequence),1)
            end
        elseif trace_bugs then
            logwarning("%s: prev node is no char, case %i",pref(dataset,sequence),2)
        end
    elseif trace_bugs then
        logwarning("%s: mark %s is no mark",pref(dataset,sequence),gref(markchar))
    end
    return head, start, false
end

function handlers.gpos_mark2mark(head,start,dataset,sequence,markanchors,rlmode,skiphash)
    local markchar = getchar(start)
    if marks[markchar] then
        local base = getprev(start) -- [glyph] [basemark] [start=mark]
        local slc = getligaindex(start)
        if slc then -- a rather messy loop ... needs checking with husayni
            while base do
                local blc = getligaindex(base)
                if blc and blc ~= slc then
                    base = getprev(base)
                else
                    break
                end
            end
        end
        if base then
            local basechar = ischar(base,currentfont)
            if basechar then -- subtype test can go
                local ba = markanchors[1][basechar] -- slot 1 has been made copy of the class hash
                if ba then
                    local ma = markanchors[2]
                    local dx, dy, bound = setmark(start,base,factor,rlmode,ba,ma,characters[basechar],true,checkmarks)
                    if trace_marks then
                        logprocess("%s, bound %s, anchoring mark %s to basemark %s => (%p,%p)",
                            pref(dataset,sequence),bound,gref(markchar),gref(basechar),dx,dy)
                    end
                    return head, start, true
                end
            end
        end
    elseif trace_bugs then
        logwarning("%s: mark %s is no mark",pref(dataset,sequence),gref(markchar))
    end
    return head, start, false
end

function handlers.gpos_cursive(head,start,dataset,sequence,exitanchors,rlmode,skiphash,step) -- to be checked
    local startchar = getchar(start)
    if marks[startchar] then
        if trace_cursive then
            logprocess("%s: ignoring cursive for mark %s",pref(dataset,sequence),gref(startchar))
        end
    else
        local nxt = getnext(start)
        while nxt do
            local nextchar = ischar(nxt,currentfont)
            if not nextchar then
                break
            elseif marks[nextchar] then -- always sequence.flags[1]
                nxt = getnext(nxt)
            else
                local exit = exitanchors[3]
                if exit then
                    local entry = exitanchors[1][nextchar]
                    if entry then
                        entry = entry[2]
                        if entry then
                            local r2lflag = sequence.flags[4] -- mentioned in the standard
                            local dx, dy, bound = setcursive(start,nxt,factor,rlmode,exit,entry,characters[startchar],characters[nextchar],r2lflag)
                            if trace_cursive then
                                logprocess("%s: moving %s to %s cursive (%p,%p) using bound %s in %s mode",pref(dataset,sequence),gref(startchar),gref(nextchar),dx,dy,bound,mref(rlmode))
                            end
                            return head, start, true
                        end
                    end
                end
                break
            end
        end
    end
    return head, start, false
end

-- I will implement multiple chain replacements once I run into a font that uses it.
-- It's not that complex to handle.

local chainprocs = { }

local function logprocess(...)
    if trace_steps then
        registermessage(...)
        if trace_steps == "silent" then
            return
        end
    end
    report_subchain(...)
end

local logwarning = report_subchain

local function logprocess(...)
    if trace_steps then
        registermessage(...)
        if trace_steps == "silent" then
            return
        end
    end
    report_chain(...)
end

local logwarning = report_chain

-- We could share functions but that would lead to extra function calls with many
-- arguments, redundant tests and confusing messages.

-- The reversesub is a special case, which is why we need to store the replacements
-- in a bit weird way. There is no lookup and the replacement comes from the lookup
-- itself. It is meant mostly for dealing with Urdu.

local function reversesub(head,start,stop,dataset,sequence,replacements,rlmode,skiphash)
    local char        = getchar(start)
    local replacement = replacements[char]
    if replacement then
        if trace_singles then
            logprocess("%s: single reverse replacement of %s by %s",cref(dataset,sequence),gref(char),gref(replacement))
        end
        resetinjection(start)
        setchar(start,replacement)
        return head, start, true
    else
        return head, start, false
    end
end


chainprocs.reversesub = reversesub

-- This chain stuff is somewhat tricky since we can have a sequence of actions to be
-- applied: single, alternate, multiple or ligature where ligature can be an invalid
-- one in the sense that it will replace multiple by one but not neccessary one that
-- looks like the combination (i.e. it is the counterpart of multiple then). For
-- example, the following is valid:
--
--   xxxabcdexxx [single a->A][multiple b->BCD][ligature cde->E] xxxABCDExxx
--
-- Therefore we we don't really do the replacement here already unless we have the
-- single lookup case. The efficiency of the replacements can be improved by
-- deleting as less as needed but that would also make the code even more messy.
--
-- Here we replace start by a single variant.
--
-- To be done   : what if > 1 steps (example needed)
-- This is messy: do we need this disc checking also in alternates?

local function reportzerosteps(dataset,sequence)
    logwarning("%s: no steps",cref(dataset,sequence))
end

local function reportmoresteps(dataset,sequence)
    logwarning("%s: more than 1 step",cref(dataset,sequence))
end

-- local function reportbadsteps(dataset,sequence)
--     logwarning("%s: bad step, no proper return values",cref(dataset,sequence))
-- end

local function getmapping(dataset,sequence,currentlookup)
    local steps    = currentlookup.steps
    local nofsteps = currentlookup.nofsteps
    if nofsteps == 0 then
        reportzerosteps(dataset,sequence)
        currentlookup.mapping = false
        return false
    else
        if nofsteps > 1 then
            reportmoresteps(dataset,sequence)
        end
        local mapping = steps[1].coverage
        currentlookup.mapping = mapping
        currentlookup.format  = steps[1].format
        return mapping
    end
end

function chainprocs.gsub_remove(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    if trace_chains then
        logprocess("%s: removing character %s",cref(dataset,sequence,chainindex),gref(getchar(start)))
    end
    head, start = removenode(head,start,true)
    return head, getprev(start), true
end

function chainprocs.gsub_single(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    local mapping = currentlookup.mapping
    if mapping == nil then
        mapping = getmapping(dataset,sequence,currentlookup)
    end
    if mapping then
        local current = start
        while current do
            local currentchar = ischar(current)
            if currentchar then
                local replacement = mapping[currentchar]
                if not replacement or replacement == "" then
                    if trace_bugs then
                        logwarning("%s: no single for %s",cref(dataset,sequence,chainindex),gref(currentchar))
                    end
                else
                    if trace_singles then
                        logprocess("%s: replacing single %s by %s",cref(dataset,sequence,chainindex),gref(currentchar),gref(replacement))
                    end
                    resetinjection(current)
                    setchar(current,replacement)
                end
                return head, start, true
            elseif currentchar == false then
                -- can't happen
                break
            elseif current == stop then
                break
            else
                current = getnext(current)
            end
        end
    end
    return head, start, false
end

-- Here we replace start by new glyph. First we delete the rest of the match.

-- char_1 mark_1 -> char_x mark_1 (ignore marks)
-- char_1 mark_1 -> char_x

-- to be checked: do we always have just one glyph?
-- we can also have alternates for marks
-- marks come last anyway
-- are there cases where we need to delete the mark

function chainprocs.gsub_alternate(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    local mapping = currentlookup.mapping
    if mapping == nil then
        mapping = getmapping(dataset,sequence,currentlookup)
    end
    if mapping then
        local kind    = dataset[4]
        local what    = dataset[1]
        local value   = what == true and tfmdata.shared.features[kind] or what -- todo: optimize in ctx
        local current = start
        while current do
            local currentchar = ischar(current)
            if currentchar then
                local alternatives = mapping[currentchar]
                if alternatives then
                    local choice, comment = get_alternative_glyph(current,alternatives,value)
                    if choice then
                        if trace_alternatives then
                            logprocess("%s: replacing %s by alternative %a to %s, %s",cref(dataset,sequence),gref(currentchar),choice,gref(choice),comment)
                        end
                        resetinjection(start)
                        setchar(start,choice)
                    else
                        if trace_alternatives then
                            logwarning("%s: no variant %a for %s, %s",cref(dataset,sequence),value,gref(currentchar),comment)
                        end
                    end
                end
                return head, start, true
            elseif currentchar == false then
                -- can't happen
                break
            elseif current == stop then
                break
            else
                current = getnext(current)
            end
        end
    end
    return head, start, false
end

-- Here we replace start by a sequence of new glyphs.

function chainprocs.gsub_multiple(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    local mapping = currentlookup.mapping
    if mapping == nil then
        mapping = getmapping(dataset,sequence,currentlookup)
    end
    if mapping then
        local startchar   = getchar(start)
        local replacement = mapping[startchar]
        if not replacement or replacement == "" then
            if trace_bugs then
                logwarning("%s: no multiple for %s",cref(dataset,sequence),gref(startchar))
            end
        else
            if trace_multiples then
                logprocess("%s: replacing %s by multiple characters %s",cref(dataset,sequence),gref(startchar),gref(replacement))
            end
            return multiple_glyphs(head,start,replacement,skiphash,dataset[1],stop)
        end
    end
    return head, start, false
end

-- When we replace ligatures we use a helper that handles the marks. I might change
-- this function (move code inline and handle the marks by a separate function). We
-- assume rather stupid ligatures (no complex disc nodes).

-- compare to handlers.gsub_ligature which is more complex ... why

function chainprocs.gsub_ligature(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    local mapping = currentlookup.mapping
    if mapping == nil then
        mapping = getmapping(dataset,sequence,currentlookup)
    end
    if mapping then
        local startchar = getchar(start)
        local ligatures = mapping[startchar]
        if not ligatures then
            if trace_bugs then
                logwarning("%s: no ligatures starting with %s",cref(dataset,sequence,chainindex),gref(startchar))
            end
        else
            local hasmarks        = marks[startchar]
            local current         = getnext(start)
            local discfound       = false
            local last            = stop
            local nofreplacements = 1
            while current do
                -- todo: ischar ... can there really be disc nodes here?
                local id = getid(current)
                if id == disc_code then
                    if not discfound then
                        discfound = current
                    end
                    if current == stop then
                        break -- okay? or before the disc
                    else
                        current = getnext(current)
                    end
                else
                    local schar = getchar(current)
                    if skiphash and skiphash[schar] then -- marks
                        -- if current == stop then -- maybe add this
                        --     break
                        -- else
                            current = getnext(current)
                        -- end
                    else
                        local lg = not tonumber(ligatures) and ligatures[schar]
                        if lg then
                            ligatures       = lg
                            last            = current
                            nofreplacements = nofreplacements + 1
                            if marks[char] then
                                hasmarks = true
                            end
                            if current == stop then
                                break
                            else
                                current = getnext(current)
                            end
                        else
                            break
                        end
                    end
                end
            end
            local ligature = tonumber(ligatures) or ligatures.ligature
            if ligature then
                if chainindex then
                    stop = last
                end
                if trace_ligatures then
                    if start == stop then
                        logprocess("%s: replacing character %s by ligature %s case 3",cref(dataset,sequence,chainindex),gref(startchar),gref(ligature))
                    else
                        logprocess("%s: replacing character %s upto %s by ligature %s case 4",cref(dataset,sequence,chainindex),gref(startchar),gref(getchar(stop)),gref(ligature))
                    end
                end
                head, start = toligature(head,start,stop,ligature,dataset,sequence,skiphash,discfound,hasmarks)
                return head, start, true, nofreplacements, discfound
            elseif trace_bugs then
                if start == stop then
                    logwarning("%s: replacing character %s by ligature fails",cref(dataset,sequence,chainindex),gref(startchar))
                else
                    logwarning("%s: replacing character %s upto %s by ligature fails",cref(dataset,sequence,chainindex),gref(startchar),gref(getchar(stop)))
                end
            end
        end
    end
    return head, start, false, 0, false
end

function chainprocs.gpos_single(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    -- we actually should check no_left_kern_code with next
    if not hasglyphoption(start,no_right_kern_code) then
        local mapping = currentlookup.mapping
        if mapping == nil then
            mapping = getmapping(dataset,sequence,currentlookup)
        end
        if mapping then
            local startchar = getchar(start)
            local kerns     = mapping[startchar]
            if kerns then
                local format = currentlookup.format
                if format == "single" then
                    local dx, dy, w, h = setposition(0,start,factor,rlmode,kerns) -- currentlookup.flags ?
                    if trace_kerns then
                        logprocess("%s: shifting single %s by %s (%p,%p) and correction (%p,%p)",cref(dataset,sequence),gref(startchar),format,dx,dy,w,h)
                    end
                else -- needs checking .. maybe no kerns format for single
                    local k = (format == "move" and setmove or setkern)(start,factor,rlmode,kerns,injection)
                    if trace_kerns then
                        logprocess("%s: shifting single %s by %s %p",cref(dataset,sequence),gref(startchar),format,k)
                    end
                end
                return head, start, true
            end
        end
    end
    return head, start, false
end

function chainprocs.gpos_pair(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex) -- todo: injections ?
    -- we actually should check no_left_kern_code with next
    if not hasglyphoption(start,no_right_kern_code) then
        local mapping = currentlookup.mapping
        if mapping == nil then
            mapping = getmapping(dataset,sequence,currentlookup)
        end
        if mapping then
            local snext = getnext(start)
            if snext then
                local startchar = getchar(start)
                local kerns     = mapping[startchar] -- always 1 step
                if kerns then
                    local prev = start
                    while snext do
                        local nextchar = ischar(snext,currentfont)
                        if not nextchar then
                            break
                        end
                        if skiphash and skiphash[nextchar] then
                            prev  = snext
                            snext = getnext(snext)
                        else
                            local krn = kerns[nextchar]
                            if not krn then
                                break
                            end
                            local format = currentlookup.format
                            if format == "pair" then
                                local a = krn[1]
                                local b = krn[2]
                                if a == true then
                                    -- zero
                                elseif a then
                                    local x, y, w, h = setposition(1,start,factor,rlmode,a,"injections") -- currentlookups flags?
                                    if trace_kerns then
                                        local startchar = getchar(start)
                                        logprocess("%s: shifting first of pair %s and %s by (%p,%p) and correction (%p,%p)",cref(dataset,sequence),gref(startchar),gref(nextchar),x,y,w,h)
                                    end
                                end
                                if b == true then
                                    -- zero
                                    start = snext -- cf spec
                                elseif b then -- #b > 0
                                    local x, y, w, h = setposition(2,snext,factor,rlmode,b,"injections")
                                    if trace_kerns then
                                        local startchar = getchar(start)
                                        logprocess("%s: shifting second of pair %s and %s by (%p,%p) and correction (%p,%p)",cref(dataset,sequence),gref(startchar),gref(nextchar),x,y,w,h)
                                    end
                                    start = snext -- cf spec
                                elseif forcepairadvance then
                                    start = snext -- for testing, not cf spec
                                end
                                return head, start, true
                            elseif krn ~= 0 then
                                local k = (format == "move" and setmove or setkern)(snext,factor,rlmode,krn)
                                if trace_kerns then
                                    logprocess("%s: inserting %s %p between %s and %s",cref(dataset,sequence),format,k,gref(getchar(prev)),gref(nextchar))
                                end
                                return head, start, true
                            else
                                break
                            end
                        end
                    end
                end
            end
        end
    end
    return head, start, false
end

function chainprocs.gpos_mark2base(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    local mapping = currentlookup.mapping
    if mapping == nil then
        mapping = getmapping(dataset,sequence,currentlookup)
    end
    if mapping then
        local markchar = getchar(start)
        if marks[markchar] then
            local markanchors = mapping[markchar] -- always 1 step
            if markanchors then
                local base = getprev(start) -- [glyph] [start=mark]
                if base then
                    local basechar = ischar(base,currentfont)
                    if basechar then
                        if marks[basechar] then
                            while base do
                                base = getprev(base)
                                if base then
                                    local basechar = ischar(base,currentfont)
                                    if basechar then
                                        if not marks[basechar] then
                                            break
                                        end
                                    else
                                        if trace_bugs then
                                            logwarning("%s: no base for mark %s, case %i",pref(dataset,sequence),gref(markchar),1)
                                        end
                                        return head, start, false
                                    end
                                else
                                    if trace_bugs then
                                        logwarning("%s: no base for mark %s, case %i",pref(dataset,sequence),gref(markchar),2)
                                    end
                                    return head, start, false
                                end
                            end
                        end
                        local ba = markanchors[1][basechar]
                        if ba then
                            local ma = markanchors[2]
                            if ma then
                                local dx, dy, bound = setmark(start,base,factor,rlmode,ba,ma,characters[basechar],false,checkmarks)
                                if trace_marks then
                                    logprocess("%s, bound %s, anchoring mark %s to basechar %s => (%p,%p)",
                                        cref(dataset,sequence),bound,gref(markchar),gref(basechar),dx,dy)
                                end
                                return head, start, true
                            end
                        end
                    elseif trace_bugs then
                        logwarning("%s: prev node is no char, case %i",cref(dataset,sequence),1)
                    end
                elseif trace_bugs then
                    logwarning("%s: prev node is no char, case %i",cref(dataset,sequence),2)
                end
            elseif trace_bugs then
                logwarning("%s: mark %s has no anchors",cref(dataset,sequence),gref(markchar))
            end
        elseif trace_bugs then
            logwarning("%s: mark %s is no mark",cref(dataset,sequence),gref(markchar))
        end
    end
    return head, start, false
end

function chainprocs.gpos_mark2ligature(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    local mapping = currentlookup.mapping
    if mapping == nil then
        mapping = getmapping(dataset,sequence,currentlookup)
    end
    if mapping then
        local markchar = getchar(start)
        if marks[markchar] then
            local markanchors = mapping[markchar] -- always 1 step
            if markanchors then
                local base = getprev(start) -- [glyph] [optional marks] [start=mark]
                if base then
                    local basechar = ischar(base,currentfont)
                    if basechar then
                        if marks[basechar] then
                            while base do
                                base = getprev(base)
                                if base then
                                    local basechar = ischar(base,currentfont)
                                    if basechar then
                                        if not marks[basechar] then
                                            break
                                        end
                                    else
                                        if trace_bugs then
                                            logwarning("%s: no base for mark %s, case %i",cref(dataset,sequence),markchar,1)
                                        end
                                        return head, start, false
                                    end
                                else
                                    if trace_bugs then
                                        logwarning("%s: no base for mark %s, case %i",cref(dataset,sequence),markchar,2)
                                    end
                                    return head, start, false
                                end
                            end
                        end
                        local ba = markanchors[1][basechar]
                        if ba then
                            local ma = markanchors[2]
                            if ma then
                                local index = getligaindex(start)
                                ba = ba[index]
                                if ba then
                                    local dx, dy, bound = setmark(start,base,factor,rlmode,ba,ma,characters[basechar],false,checkmarks)
                                    if trace_marks then
                                        logprocess("%s, bound %s, anchoring mark %s to baselig %s at index %s => (%p,%p)",
                                            cref(dataset,sequence),a or bound,gref(markchar),gref(basechar),index,dx,dy)
                                    end
                                    return head, start, true
                                end
                            end
                        end
                    elseif trace_bugs then
                        logwarning("%s, prev node is no char, case %i",cref(dataset,sequence),1)
                    end
                elseif trace_bugs then
                    logwarning("%s, prev node is no char, case %i",cref(dataset,sequence),2)
                end
            elseif trace_bugs then
                logwarning("%s, mark %s has no anchors",cref(dataset,sequence),gref(markchar))
            end
        elseif trace_bugs then
            logwarning("%s, mark %s is no mark",cref(dataset,sequence),gref(markchar))
        end
    end
    return head, start, false
end

function chainprocs.gpos_mark2mark(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    local mapping = currentlookup.mapping
    if mapping == nil then
        mapping = getmapping(dataset,sequence,currentlookup)
    end
    if mapping then
        local markchar = getchar(start)
        if marks[markchar] then
            local markanchors = mapping[markchar] -- always 1 step
            if markanchors then
                local base = getprev(start) -- [glyph] [basemark] [start=mark]
                local slc = getligaindex(start)
                if slc then -- a rather messy loop ... needs checking with husayni
                    while base do
                        local blc = getligaindex(base)
                        if blc and blc ~= slc then
                            base = getprev(base)
                        else
                            break
                        end
                    end
                end
                if base then -- subtype test can go
                    local basechar = ischar(base,currentfont)
                    if basechar then
                        local ba = markanchors[1][basechar]
                        if ba then
                            local ma = markanchors[2]
                            if ma then
                                local dx, dy, bound = setmark(start,base,factor,rlmode,ba,ma,characters[basechar],true,checkmarks)
                                if trace_marks then
                                    logprocess("%s, bound %s, anchoring mark %s to basemark %s => (%p,%p)",
                                        cref(dataset,sequence),bound,gref(markchar),gref(basechar),dx,dy)
                                end
                                return head, start, true
                            end
                        end
                    elseif trace_bugs then
                        logwarning("%s: prev node is no mark, case %i",cref(dataset,sequence),1)
                    end
                elseif trace_bugs then
                    logwarning("%s: prev node is no mark, case %i",cref(dataset,sequence),2)
                end
            elseif trace_bugs then
                logwarning("%s: mark %s has no anchors",cref(dataset,sequence),gref(markchar))
            end
        elseif trace_bugs then
            logwarning("%s: mark %s is no mark",cref(dataset,sequence),gref(markchar))
        end
    end
    return head, start, false
end

function chainprocs.gpos_cursive(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash,chainindex)
    local mapping = currentlookup.mapping
    if mapping == nil then
        mapping = getmapping(dataset,sequence,currentlookup)
    end
    if mapping then
        local startchar   = getchar(start)
        local exitanchors = mapping[startchar] -- always 1 step
        if exitanchors then
            if marks[startchar] then
                if trace_cursive then
                    logprocess("%s: ignoring cursive for mark %s",pref(dataset,sequence),gref(startchar))
                end
            else
                local nxt = getnext(start)
                while nxt do
                    local nextchar = ischar(nxt,currentfont)
                    if not nextchar then
                        break
                    elseif marks[nextchar] then
                        -- should not happen (maybe warning)
                        nxt = getnext(nxt)
                    else
                        local exit = exitanchors[3]
                        if exit then
                            local entry = exitanchors[1][nextchar]
                            if entry then
                                entry = entry[2]
                                if entry then
                                    local r2lflag = sequence.flags[4] -- mentioned in the standard
                                    local dx, dy, bound = setcursive(start,nxt,factor,rlmode,exit,entry,characters[startchar],characters[nextchar],r2lflag)
                                    if trace_cursive then
                                        logprocess("%s: moving %s to %s cursive (%p,%p) using bound %s in %s mode",pref(dataset,sequence),gref(startchar),gref(nextchar),dx,dy,bound,mref(rlmode))
                                    end
                                    return head, start, true
                                end
                            end
                        elseif trace_bugs then
                            onetimemessage(currentfont,startchar,"no entry anchors")
                        end
                        break
                    end
                end
            end
        elseif trace_cursive and trace_details then
            logprocess("%s, cursive %s is already done",pref(dataset,sequence),gref(getchar(start)),alreadydone)
        end
    end
    return head, start, false
end

-- what pointer to return, spec says stop
-- to be discussed ... is bidi changer a space?
-- elseif char == zwnj and sequence[n][32] then -- brrr

local function show_skip(dataset,sequence,char,ck,class)
    logwarning("%s: skipping char %s, class %a, rule %a, lookuptype %a",cref(dataset,sequence),gref(char),class,ck[1],ck[8] or ck[2])
end

-- A previous version had disc collapsing code in the (single sub) handler plus some
-- checking in the main loop, but that left the pre/post sequences undone. The best
-- solution is to add some checking there and backtrack when a replace/post matches
-- but it takes a bit of work to figure out an efficient way (this is what the
-- sweep* names refer to). I might look into that variant one day again as it can
-- replace some other code too. In that approach we can have a special version for
-- gub and pos which gains some speed. This method does the test and passes info to
-- the handlers. Here collapsing is handled in the main loop which also makes code
-- elsewhere simpler (i.e. no need for the other special runners and disc code in
-- ligature building). I also experimented with pushing preceding glyphs sequences
-- in the replace/pre fields beforehand which saves checking afterwards but at the
-- cost of duplicate glyphs (memory) but it's too much overhead (runtime).
--
-- In the meantime Kai had moved the code from the single chain into a more general
-- handler and this one (renamed to chaindisk) is used now. I optimized the code a
-- bit and brought it in sycn with the other code. Hopefully I didn't introduce
-- errors. Note: this somewhat complex approach is meant for fonts that implement
-- (for instance) ligatures by character replacement which to some extend is not
-- that suitable for hyphenation. I also use some helpers. This method passes some
-- states but reparses the list. There is room for a bit of speed up but that will
-- be done in the context version. (In fact a partial rewrite of all code can bring
-- some more efficiency.)
--
-- I didn't test it with extremes but successive disc nodes still can give issues
-- but in order to handle that we need more complex code which also slows down even
-- more. The main loop variant could deal with that: test, collapse, backtrack.

local userkern = nuts.pool and nuts.pool.newkern -- context

do if not userkern then -- generic

    local thekern = nuts.new("kern",1) -- userkern
    local setkern = nuts.setkern       -- not injections.setkern

    userkern = function(k)
        local n = copynode(thekern)
        setkern(n,k)
        return n
    end

end end

local function checked(head)
    local current = head
    while current do
        if getid(current) == glue_code then
            local kern = userkern(getwidth(current))
            if head == current then
                local next = getnext(current)
                if next then
                    setlink(kern,next)
                end
                flushnode(current)
                head    = kern
                current = next
            else
                local prev, next = getboth(current)
                setlink(prev,kern,next)
                flushnode(current)
                current = next
            end
        else
            current = getnext(current)
        end
    end
    return head
end

local function setdiscchecked(d,pre,post,replace)
    if pre     then pre     = checked(pre)     end
    if post    then post    = checked(post)    end
    if replace then replace = checked(replace) end
    setdisc(d,pre,post,replace)
end

local noflags = { false, false, false, false }

local function chainrun(head,start,last,dataset,sequence,rlmode,skiphash,ck,where)

    local size         = ck[5] - ck[4] + 1
    local chainlookups = ck[6]
    local done         = false
    -- current match
    if chainlookups then
        -- Lookups can be like { 1, false, 3 } or { false, 2 } or basically anything and
        -- #lookups can be less than #current

        if size == 1 then

         -- if nofchainlookups > size then
         --     -- bad rules
         -- end
            local chainlookup = chainlookups[1]
            if chainlookup then
                for j=1,#chainlookup do
                    local chainstep = chainlookup[j]
                    if chainstep then
                        local chainkind = chainstep.type
                        local chainproc = chainprocs[chainkind]
                        if chainproc then
                            local ok
                         -- HH: chainindex 1 added here (for KAI to check too), there are weird ligatures e.g.
                         -- char + mark -> char where mark has to disappear
                            head, start, ok = chainproc(head,start,last,dataset,sequence,chainstep,rlmode,skiphash,1)
                            if ok then
                                done = true
                            end
                        else
                            logprocess("%s: %s is not yet supported (1)",cref(dataset,sequence),chainkind)
                        end
                    else
                        logprocess("%s: has an issue (1)",cref(dataset,sequence))
                    end
                end
            else
                -- whatever
            end

         else

            -- See LookupType 5: Contextual Substitution Subtable. Now it becomes messy. The
            -- easiest case is where #current maps on #lookups i.e. one-to-one. But what if
            -- we have a ligature. Cf the spec we then need to advance one character but we
            -- really need to test it as there are fonts out there that are fuzzy and have
            -- too many lookups:
            --
            -- U+1105 U+119E U+1105 U+119E : sourcehansansklight: script=hang ccmp=yes
            --
            -- Even worse are these family emoji shapes as they can have multiple lookups
            -- per slot (probably only for gpos).

            -- It's very unlikely that we will have skip classes here but still ... we seldom
            -- enter this branch anyway.

            local i = 1
            local laststart = start
            local nofchainlookups = #chainlookups -- useful?
            while start do
                if skiphash then -- hm, so we know we skip some
                    while start do
                        local char = ischar(start,currentfont)
                        if char then
                            if skiphash and skiphash[char] then
                                start = getnext(start)
                            else
                                break
                            end
                        else
                            break
                        end
                    end
                end
                local chainlookup = chainlookups[i]
                if chainlookup then
                    for j=1,#chainlookup do
                        local chainstep = chainlookup[j]
                        if chainstep then
                            local chainkind = chainstep.type
                            local chainproc = chainprocs[chainkind]
                            if chainproc then
                                local ok, n
                                head, start, ok, n = chainproc(head,start,last,dataset,sequence,chainstep,rlmode,skiphash,i)
                                -- messy since last can be changed !
                                if ok then
                                    done = true
                                    if n and n > 1 and i + n > nofchainlookups then
                                        -- this is a safeguard, we just ignore the rest of the lookups
                                        i = size -- prevents an advance
                                        break
                                    end
                                end
                            else
                                -- actually an error
                                logprocess("%s: %s is not yet supported (2)",cref(dataset,sequence),chainkind)
                            end
                        else
                            -- actually an error
                            logprocess("%s: has an issue (2)",cref(dataset,sequence))
                        end
                    end
                else
                    -- we skip but we could also delete as option .. what does an empty lookup actually mean
                    -- in opentype ... anyway, we could map it onto gsub_remove if needed
                end
                i = i + 1
                if i > size or not start then
                    break
                elseif start then
                    laststart = start
                    start = getnext(start)
                end
            end
            if not start then
                start = laststart
            end

        end
    else
        -- todo: needs checking for holes in the replacements
        local replacements = ck[7]
        if replacements then
            head, start, done = reversesub(head,start,last,dataset,sequence,replacements,rlmode,skiphash)
        else
            done = true
            if trace_contexts then
                logprocess("%s: skipping match @ %i",cref(dataset,sequence),where)
            end
        end
    end
    return head, start, done
end

local function chaindisk(head,start,dataset,sequence,rlmode,skiphash,ck)

    if not start then
        return head, start, false
    end

    local startishead   = start == head
    local seq           = ck[3]
    local f             = ck[4]
    local l             = ck[5]
    local s             = #seq
    local done          = false
    local sweepnode     = sweepnode
    local sweeptype     = sweeptype
    local sweepoverflow = false
    local checkdisc     = getprev(head)
    local keepdisc      = not sweepnode
    local lookaheaddisc = nil
    local backtrackdisc = nil
    local current       = start
    local last          = start
    local prev          = getprev(start)
    local hasglue       = false
    local useddisc      = nil   -- new 2022-09-25
    local usedstart     = start -- new 2022-09-25

    -- fishy: so we can overflow and then go on in the sweep?
    -- todo : id can also be glue_code as we checked spaces

    local i = f
    while i <= l do
        local id = getid(current)
        if id == glyph_code then
            i       = i + 1
            last    = current
            current = getnext(current)
        elseif id == glue_code then
            i       = i + 1
            last    = current
            current = getnext(current)
            hasglue = true
        elseif id == disc_code then
            if keepdisc then
                keepdisc      = false
                lookaheaddisc = current
                local replace = getreplace(current)
                if not replace then
                    sweepoverflow = true
                    sweepnode     = current
                    current       = getnext(current)
                else
                    -- we can use an iterator
                    while replace and i <= l do
                        if getid(replace) == glyph_code then
                            i = i + 1
                        end
                        replace = getnext(replace)
                    end
                    current = getnext(replace)
                end
                last = current
            else
                head, current = flattendisk(head,current)
            end
        else
            last    = current
            current = getnext(current)
        end
        if current then
            -- go on
        elseif sweepoverflow then
            -- we already are following up on sweepnode
            break
        elseif sweeptype == "post" or sweeptype == "replace" then
            current = getnext(sweepnode)
            if current then
                sweeptype     = nil
                sweepoverflow = true
            else
                break
            end
        else
            break -- added
        end
    end

    if sweepoverflow then
        local prev = current and getprev(current)
        if not current or prev ~= sweepnode then
            local head = getnext(sweepnode)
            local tail = nil
            if prev then
                tail = prev
                setprev(current,sweepnode)
            else
                tail = findnodetail(head)
            end
            setnext(sweepnode,current)
            setprev(head)
            setnext(tail)
            appenddisc(sweepnode,head)
        end
    end

    if l < s then
        local i = l
        local t = sweeptype == "post" or sweeptype == "replace"
        while current and i < s do
            local id = getid(current)
            if id == glyph_code then
                i       = i + 1
                current = getnext(current)
            elseif id == glue_code then
                i       = i + 1
                current = getnext(current)
                hasglue = true
            elseif id == disc_code then
                if keepdisc then
                    keepdisc = false
                    if notmatchpre[current] ~= notmatchreplace[current] then
                        lookaheaddisc = current
                    end
                    -- we assume a simple text only replace (we could use nuts.count)
                    local replace = getreplace(current)
                    while replace and i < s do
                        if getid(replace) == glyph_code then
                            i = i + 1
                        end
                        replace = getnext(replace)
                    end
                    current = getnext(current)
                elseif notmatchpre[current] ~= notmatchreplace[current] then
                    head, current = flattendisk(head,current)
                else
                    current = getnext(current) -- HH
                end
            else
                current = getnext(current)
            end
            if not current and t then
                current = getnext(sweepnode)
                if current then
                    sweeptype = nil
                end
            end
        end
    end

    if f > 1 then
        local current = prev
        local i       = f
        local t       = sweeptype == "pre" or sweeptype == "replace"
        if not current and t and current == checkdisc then
            current = getprev(sweepnode)
        end
        while current and i > 1 do -- missing getprev added / moved outside
            local id = getid(current)
            if id == glyph_code then
                i = i - 1
            elseif id == glue_code then
                i       = i - 1
                hasglue = true
            elseif id == disc_code then
                if keepdisc then
                    keepdisc = false
                    if notmatchpost[current] ~= notmatchreplace[current] then
                        backtrackdisc = current
                    end
                    -- we assume a simple text only replace (we could use nuts.count)
                    local replace = getreplace(current)
                    while replace and i > 1 do
                        if getid(replace) == glyph_code then
                            i = i - 1
                        end
                        replace = getnext(replace)
                    end
                elseif notmatchpost[current] ~= notmatchreplace[current] then
                    head, current = flattendisk(head,current)
                end
            end
            current = getprev(current)
            if t and current == checkdisc then
                current = getprev(sweepnode)
            end
        end
    end

    local done = false

    if lookaheaddisc then
        local cf            = start
        local cl            = getprev(lookaheaddisc)
        local cprev         = getprev(start)
        local insertedmarks = 0
        while cprev do
            local char = ischar(cf,currentfont)
            if char and marks[char] then
                insertedmarks = insertedmarks + 1
                cf            = cprev
                startishead   = cf == head
                cprev         = getprev(cprev)
            else
                break
            end
        end
        setlink(cprev,lookaheaddisc)
        setprev(cf)
        setnext(cl)
        if startishead then
            head = lookaheaddisc
        end
        local pre, post, replace = getdisc(lookaheaddisc)
        local new  = copynodelist(cf) -- br, how often does that happen
        local cnew = new
        if pre then
            setlink(findnodetail(cf),pre)
        end
        if replace then
            local tail = findnodetail(new)
            setlink(tail,replace)
        end
        for i=1,insertedmarks do
            cnew = getnext(cnew)
        end
        cl = start
        local clast = cnew
        for i=f,l do
            cl    = getnext(cl)
            clast = getnext(clast)
        end
        if not notmatchpre[lookaheaddisc] then
            local ok = false
            cf, start, ok = chainrun(cf,start,cl,dataset,sequence,rlmode,skiphash,ck,1)
            if ok then
                done = true
            end
        end
        if not notmatchreplace[lookaheaddisc] then
            local ok = false
            new, cnew, ok = chainrun(new,cnew,clast,dataset,sequence,rlmode,skiphash,ck,2)
            if ok then
                done = true
            end
        end
        if hasglue then
            setdiscchecked(lookaheaddisc,cf,post,new)
        else
            setdisc(lookaheaddisc,cf,post,new)
        end
        start          = getprev(lookaheaddisc)
        useddisc       = lookaheaddisc -- new 2022-09-25
        sweephead[cf]  = getnext(clast) or false
        sweephead[new] = getnext(cl) or false
    elseif backtrackdisc then
        local cf            = getnext(backtrackdisc)
        local cl            = start
        local cnext         = getnext(start)
        local insertedmarks = 0
        while cnext do
            local char = ischar(cnext,currentfont)
            if char and marks[char] then
                insertedmarks = insertedmarks + 1
                cl            = cnext
                cnext         = getnext(cnext)
            else
                break
            end
        end
        setlink(backtrackdisc,cnext)
        setprev(cf)
        setnext(cl)
        local pre, post, replace, pretail, posttail, replacetail = getdisc(backtrackdisc,true)
        local new  = copynodelist(cf)
        local cnew = findnodetail(new)
        for i=1,insertedmarks do
            cnew = getprev(cnew)
        end
        local clast = cnew
        for i=f,l do
            clast = getnext(clast)
        end
        if not notmatchpost[backtrackdisc] then
            local ok = false
            cf, start, ok = chainrun(cf,start,last,dataset,sequence,rlmode,skiphash,ck,3)
            if ok then
                done = true
            end
        end
        if not notmatchreplace[backtrackdisc] then
            local ok = false
            new, cnew, ok = chainrun(new,cnew,clast,dataset,sequence,rlmode,skiphash,ck,4)
            if ok then
                done = true
            end
        end
        if post then
            setlink(posttail,cf)
        else
            post = cf
        end
        if replace then
            setlink(replacetail,new)
        else
            replace = new
        end
        if hasglue then
            setdiscchecked(backtrackdisc,pre,post,replace)
        else
            setdisc(backtrackdisc,pre,post,replace)
        end
        start              = getprev(backtrackdisc)
        useddisc           = backtrackdisc -- new 2022-09-25
        sweephead[post]    = getnext(clast) or false
        sweephead[replace] = getnext(last) or false
    else

        local ok = false
        head, start, ok = chainrun(head,start,last,dataset,sequence,rlmode,skiphash,ck,5)
        if ok then
            done = true
        end

    end
    if useddisc and start ~= usedstart then -- make this option per font -- new 2022-09-25
       start = getnext(start)                                            -- new 2022-09-25
    end                                                                  -- new 2022-09-25
    return head, start, done, useddisc                                   -- new 2022-09-25
end

local chaintrac do

    local level = 0
    local last  = { }

    chaintrac = function(head,start,dataset,sequence,rlmode,skiphash,ck,match,discseen,sweepnode)
        if dataset then
            level = level + 1
            last[level] = start
            local rule       = ck[1]
            local lookuptype = ck[8] or ck[2]
            local nofseq     = #ck[3] -- ck[3].n
            local first      = ck[4]
            local last       = ck[5]
            local char       = getchar(start)
            logwarning("+ %i : %s: rule %s %s at char %s for (%s,%s,%s) chars, lookuptype %a, %sdisc seen, %ssweeping",
                level,cref(dataset,sequence),rule,match and "matches" or "nomatch",
                gref(char),first-1,last-first+1,nofseq-last,lookuptype,
                discseen and "" or "no ", sweepnode and "" or "not ")
        else
            -- (start,done)
            local what  = start and "done" or "continue"
            local where = head == last[level] and "same" or "different"
            local char  = getchar(head)
            if char then
                logwarning("- %i : %s at char %s, %s node",level,what,gref(char),where)
            else
                logwarning("- %i : %s, %s node",level,what,where)
            end
            level = level - 1
        end
    end

end

-- The next one is quite optimized but still somewhat slow, fonts like ebgaramond
-- are real torture tests because they have many steps with one context (having
-- multiple contexts makes more sense) also because we (can) reduce them. Instead of
-- a match boolean variable and check for that I decided to use a goto with labels
-- instead. This is one of the cases where it makes the code more readable and we
-- might even gain a bit performance.

-- when we have less replacements (lookups) then current matches we can push too much into
-- the previous disc .. such be it (<before><disc><current=fl><after> with only f done)

local function handle_contextchain(head,start,dataset,sequence,contexts,rlmode,skiphash)
    if not contexts then
        return head, start, false
    end
    -- optimizing for rlmode gains nothing
    local sweepnode    = sweepnode
    local sweeptype    = sweeptype
    local postreplace
    local prereplace
    local checkdisc
    local discseen  -- = false
    if sweeptype then
        if sweeptype == "replace" then
            postreplace = true
            prereplace  = true
        else
            postreplace = sweeptype == "post"
            prereplace  = sweeptype == "pre"
        end
        checkdisc = getprev(head)
    end
    local currentfont  = currentfont

    local skipped   -- = false

    local startprev,
          startnext    = getboth(start)
    local done      -- = false

    -- we can have multiple hits and as we scan (currently) all we need to check
    -- if we have a match ... contextchains have no real coverage table (with
    -- unique entries)

    -- fonts can have many steps (each doing one check) or many contexts

    -- todo: make a per-char cache so that we have small contexts (when we have a context
    -- n == 1 and otherwise it can be more so we can even distinguish n == 1 or more)

    local nofcontexts = contexts.n -- #contexts

    local startchar = nofcontext == 1 or ischar(start,currentfont) -- only needed in a chain

    for k=1,nofcontexts do -- does this disc mess work well with n > 1

        local ck   = contexts[k]
        local seq  = ck[3]
        local f    = ck[4] -- first current
        local last = start
        if not startchar or not seq[f][startchar] then
            -- report("no hit in %a at %i of %i contexts",sequence.type,k,nofcontexts)
            goto next
        end
        local s = seq.n -- or #seq
        if s == 1 then
            -- bit weird case: why use a chain, but it is a hit
        else
            local l       = ck[5] -- last current
            local current = start
         -- local last    = start

            -- current match

            if l > f then
                -- before/current/after | before/current | current/after
                local discfound -- = nil
                local n = f + 1
                last = startnext -- the second in current (first already matched)
                while n <= l do
                    if postreplace and not last then
                        last      = getnext(sweepnode)
                        sweeptype = nil
                    end
                    if last then
                        local char, id = ischar(last,currentfont)
                        if char then
                            if skiphash and skiphash[char] then
                                skipped = true
                                if trace_skips then
                                    show_skip(dataset,sequence,char,ck,classes[char])
                                end
                                last = getnext(last)
                            elseif seq[n][char] then
                                if n < l then
                                    last = getnext(last)
                                end
                                n = n + 1
                            elseif discfound then
                                notmatchreplace[discfound] = true
                                if notmatchpre[discfound] then
                                    goto next
                                else
                                    break
                                end
                            else
                                goto next
                            end
                        elseif char == false then
                            if discfound then
                                notmatchreplace[discfound] = true
                                if notmatchpre[discfound] then
                                    goto next
                                else
                                    break
                                end
                            else
                                goto next
                            end
                        elseif id == disc_code then
                     -- elseif id == disc_code and (not discs or discs[last]) then
                            discseen              = true
                            discfound             = last
                            notmatchpre[last]     = nil
                            notmatchpost[last]    = true
                            notmatchreplace[last] = nil
                            local pre, post, replace = getdisc(last)
                            if pre then
                                local n = n
                                while pre do
                                    if seq[n][getchar(pre)] then
                                        n = n + 1
                                        if n > l then
                                            break
                                        end
                                        pre = getnext(pre)
                                    else
                                        notmatchpre[last] = true
                                        break
                                    end
                                end
                                if n <= l then
                                    notmatchpre[last] = true
                                end
                            else
                                notmatchpre[last] = true
                            end
                            if replace then
                                -- so far we never entered this branch
                                while replace do
                                    if seq[n][getchar(replace)] then
                                        n = n + 1
                                        if n > l then
                                            break
                                        end
                                        replace = getnext(replace)
                                    else
                                        notmatchreplace[last] = true
                                        if notmatchpre[last] then
                                            goto next
                                        else
                                            break
                                        end
                                    end
                                end
                                -- why here again
                                if notmatchpre[last] then
                                    goto next
                                end
                            end
                            -- maybe only if match
                            last = getnext(last)
                        else
                            goto next
                        end
                    else
                        goto next
                    end
                end
            end

            -- before

            if f > 1 then
              -- if startprev then -- new 2022-09-25
                    local prev = startprev
                    if prereplace and prev == checkdisc then
                        prev = getprev(sweepnode)
                    end
                    if prev then
                        local discfound -- = nil
                        local n = f - 1
                        while n >= 1 do
                            if prev then
                                local char, id = ischar(prev,currentfont)
                                if char then
                                    if skiphash and skiphash[char] then
                                        skipped = true
                                        if trace_skips then
                                            show_skip(dataset,sequence,char,ck,classes[char])
                                        end
                                        prev = getprev(prev)
                                    elseif seq[n][char] then
                                        if n > 1 then
                                            prev = getprev(prev)
                                        end
                                        n = n - 1
                                    elseif discfound then
                                        notmatchreplace[discfound] = true
                                        if notmatchpost[discfound] then
                                            goto next
                                        else
                                            break
                                        end
                                    else
                                        goto next
                                    end
                                elseif char == false then
                                    if discfound then
                                        notmatchreplace[discfound] = true
                                        if notmatchpost[discfound] then
                                            goto next
                                        end
                                    else
                                        goto next
                                    end
                                    break
                                elseif id == disc_code then
                             -- elseif id == disc_code and (not discs or discs[prev]) then
                                    -- the special case: f i where i becomes dottless i ..
                                    discseen              = true
                                    discfound             = prev
                                    notmatchpre[prev]     = true
                                    notmatchpost[prev]    = nil
                                    notmatchreplace[prev] = nil
                                    local pre, post, replace, pretail, posttail, replacetail = getdisc(prev,true)
                                    -- weird test: needs checking
                                    if pre ~= start and post ~= start and replace ~= start then
                                        if post then
                                            local n = n
                                            while posttail do
                                                if seq[n][getchar(posttail)] then
                                                    n = n - 1
                                                    if posttail == post or n < 1 then
                                                        break
                                                    else
                                                        posttail = getprev(posttail)
                                                    end
                                                else
                                                    notmatchpost[prev] = true
                                                    break
                                                end
                                            end
                                            if n >= 1 then
                                                notmatchpost[prev] = true
                                            end
                                        else
                                            notmatchpost[prev] = true
                                        end
                                        if replace then
                                            -- we seldom enter this branch (e.g. on brill efficient)
                                            while replacetail do
                                                if seq[n][getchar(replacetail)] then
                                                    n = n - 1
                                                    if replacetail == replace or n < 1 then
                                                        break
                                                    else
                                                        replacetail = getprev(replacetail)
                                                    end
                                                else
                                                    notmatchreplace[prev] = true
                                                    if notmatchpost[prev] then
                                                        goto next
                                                    else
                                                        break
                                                    end
                                                end
                                            end
                                        else
                                         -- notmatchreplace[prev] = true -- not according to Kai
                                        end
                                    end
                                    prev = getprev(prev)
                             -- elseif id == glue_code and seq[n][32] and isspace(prev,threshold,id) then
                             -- elseif seq[n][32] and spaces[prev] then
                             --     n = n - 1
                             --     prev = getprev(prev)
                                elseif id == glue_code then
                                    local sn = seq[n]
                                    if (sn[32] and spaces[prev]) or sn[0xFFFC] then
                                        n = n - 1
                                        prev = getprev(prev)
                                    else
                                        goto next
                                    end
                                elseif seq[n][0xFFFC] then
                                    n = n - 1
                                    prev = getprev(prev)
                                else
                                    goto next
                                end
                            else
                                goto next
                            end
                        end
                    else
                        goto next
                    end
             -- else          -- new 2022-09-25
             --     goto next -- new 2022-09-25
             -- end           -- new 2022-09-25
            end

            -- after

            if s > l then
                local current = last and getnext(last)
                if not current and postreplace then
                    current = getnext(sweepnode)
                end
                if current then
                    local discfound -- = nil
                    local n = l + 1
                    while n <= s do
                        if current then
                            local char, id = ischar(current,currentfont)
                            if char then
                                if skiphash and skiphash[char] then
                                    skipped = true
                                    if trace_skips then
                                        show_skip(dataset,sequence,char,ck,classes[char])
                                    end
                                    current = getnext(current) -- was absent
                                elseif seq[n][char] then
                                    if n < s then -- new test
                                        current = getnext(current) -- was absent
                                    end
                                    n = n + 1
                                elseif discfound then
                                    notmatchreplace[discfound] = true
                                    if notmatchpre[discfound] then
                                        goto next
                                    else
                                        break
                                    end
                                else
                                    goto next
                                end
                            elseif char == false then
                                if discfound then
                                    notmatchreplace[discfound] = true
                                    if notmatchpre[discfound] then
                                        goto next
                                    else
                                        break
                                    end
                                else
                                    goto next
                                end
                            elseif id == disc_code then
                         -- elseif id == disc_code and (not discs or discs[current]) then
                                discseen                 = true
                                discfound                = current
                                notmatchpre[current]     = nil
                                notmatchpost[current]    = true
                                notmatchreplace[current] = nil
                                local pre, post, replace = getdisc(current)
                                if pre then
                                    local n = n
                                    while pre do
                                        if seq[n][getchar(pre)] then
                                            n = n + 1
                                            if n > s then
                                                break
                                            else
                                                pre = getnext(pre)
                                            end
                                        else
                                            notmatchpre[current] = true
                                            break
                                        end
                                    end
                                    if n <= s then
                                        notmatchpre[current] = true
                                    end
                                else
                                    notmatchpre[current] = true
                                end
                                if replace then
                                    -- so far we never entered this branch
                                    while replace do
                                        if seq[n][getchar(replace)] then
                                            n = n + 1
                                            if n > s then
                                                break
                                            else
                                                replace = getnext(replace)
                                            end
                                        else
                                            notmatchreplace[current] = true
                                            if notmatchpre[current] then
                                                goto next
                                            else
                                                break
                                            end
                                        end
                                    end
                                else
                                 -- notmatchreplace[current] = true -- not according to Kai
                                end
                                current = getnext(current)
                            elseif id == glue_code then
                                local sn = seq[n]
                                if (sn[32] and spaces[current]) or sn[0xFFFC] then
                                    n = n + 1
                                    current = getnext(current)
                                else
                                    goto next
                                end
                            elseif seq[n][0xFFFC] then
                                n = n + 1
                                current = getnext(current)
                            else
                                goto next
                            end
                        else
                            goto next
                        end
                    end
                else
                    goto next
                end
            end
        end
        if trace_contexts then
            chaintrac(head,start,dataset,sequence,rlmode,skipped and skiphash,ck,true,discseen,sweepnode)
        end
        if discseen or sweepnode then
            -- When we process a disc we can collapse and therefore we backtrack one node (start) and
            -- reprocess. This is needed because there might be more in the collapsed list.
            head, start, done = chaindisk(head,start,dataset,sequence,rlmode,skipped and skiphash,ck)
        else
            head, start, done = chainrun(head,start,last,dataset,sequence,rlmode,skipped and skiphash,ck,6)
        end
        if trace_contexts then
            chaintrac(start,done)
        end
        if done then
            break
     -- else
            -- next context
        end
      ::next::
    end
    if discseen then
        notmatchpre     = { }
        notmatchpost    = { }
        notmatchreplace = { }
     -- notmatchpre     = { a = 1, b = 1 }  notmatchpre    .a = nil notmatchpre    .b = nil
     -- notmatchpost    = { a = 1, b = 1 }  notmatchpost   .a = nil notmatchpost   .b = nil
     -- notmatchreplace = { a = 1, b = 1 }  notmatchreplace.a = nil notmatchreplace.b = nil
    end
    return head, start, done
end

handlers.gsub_context             = handle_contextchain
handlers.gsub_contextchain        = handle_contextchain
handlers.gsub_reversecontextchain = handle_contextchain
handlers.gpos_contextchain        = handle_contextchain
handlers.gpos_context             = handle_contextchain

-- local function chained_contextchain(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash)
--     local steps    = currentlookup.steps
--     local nofsteps = currentlookup.nofsteps
--     if nofsteps > 1 then
--         reportmoresteps(dataset,sequence)
--     end
--     -- probably wrong
--     local l = steps[1].coverage[getchar(start)]
--     if l then
--         return handle_contextchain(head,start,dataset,sequence,l,rlmode,skiphash)
--     else
--         return head, start, false
--     end
-- end

-- new 2022-09-25

local function chained_contextchain(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash)
    local steps    = currentlookup.steps
    local nofsteps = currentlookup.nofsteps
    local char     = getchar(start)
    if nofsteps == 1 then
        local s = steps[1]
        local l = s.coverage[char]
        if l then
            return handle_contextchain(head,start,dataset,sequence,l,rlmode,skiphash)
        end
    else
        for i=1,nofsteps do
            local s = steps[i]
            local l = s.coverage[char]
            if l then
                local h, s, d = handle_contextchain(head,start,dataset,sequence,l,rlmode,skiphash)
                if d then
                    return h, s, d
                end
            end
        end
    end
    return head, start, false
end

chainprocs.gsub_context             = chained_contextchain
chainprocs.gsub_contextchain        = chained_contextchain
chainprocs.gsub_reversecontextchain = chained_contextchain
chainprocs.gpos_contextchain        = chained_contextchain
chainprocs.gpos_context             = chained_contextchain

------------------------------

-- experiment (needs no handler in font-otc so not now):
--
-- function otf.registerchainproc(name,f)
--  -- chainprocs[name] = f
--     chainprocs[name] = function(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash)
--         local done = currentlookup.nofsteps > 0
--         if not done then
--             reportzerosteps(dataset,sequence)
--         else
--             head, start, done = f(head,start,stop,dataset,sequence,currentlookup,rlmode,skiphash)
--             if not head or not start then
--                 reportbadsteps(dataset,sequence)
--             end
--         end
--         return head, start, done
--     end
-- end

local missing    = setmetatableindex("table")
local logwarning = report_process
local resolved   = { } -- we only resolve a font,script,language pair once

local function logprocess(...)
    if trace_steps then
        registermessage(...)
        if trace_steps == "silent" then
            return
        end
    end
    report_process(...)
end

-- todo: pass all these 'locals' in a table

local sequencelists = setmetatableindex(function(t,font)
    local sequences = fontdata[font].resources.sequences
    if not sequences or not next(sequences) then
        sequences = false
    end
    t[font] = sequences
    return sequences
end)

-- fonts.hashes.sequences = sequencelists

do -- overcome local limit

    local autofeatures    = fonts.analyzers.features
    local featuretypes    = otf.tables.featuretypes
    local defaultscript   = otf.features.checkeddefaultscript
    local defaultlanguage = otf.features.checkeddefaultlanguage

    local wildcard        = "*"
    local default         = "dflt"

    local function initialize(sequence,script,language,enabled,autoscript,autolanguage)
        local features = sequence.features
        if features then
            local order = sequence.order
            if order then
                local featuretype = featuretypes[sequence.type or "unknown"]
                for i=1,#order do
                    local kind  = order[i]
                    local valid = enabled[kind]
                    if valid then
                        local scripts   = features[kind]
                        local languages = scripts and (
                            scripts[script] or
                            scripts[wildcard] or
                            (autoscript and defaultscript(featuretype,autoscript,scripts))
                        )
                        local enabled = languages and (
                            languages[language] or
                            languages[wildcard] or
                            (autolanguage and defaultlanguage(featuretype,autolanguage,languages))
                        )
                        if enabled then
                            return { valid, autofeatures[kind] or false, sequence, kind }
                        end
                    end
                end
            else
                -- can't happen
            end
        end
        return false
    end

    function otf.dataset(tfmdata,font) -- generic variant, overloaded in context
        local shared       = tfmdata.shared
        local properties   = tfmdata.properties
        local language     = properties.language or "dflt"
        local script       = properties.script   or "dflt"
        local enabled      = shared.features
        local autoscript   = enabled and enabled.autoscript
        local autolanguage = enabled and enabled.autolanguage
        local res = resolved[font]
        if not res then
            res = { }
            resolved[font] = res
        end
        local rs = res[script]
        if not rs then
            rs = { }
            res[script] = rs
        end
        local rl = rs[language]
        if not rl then
            rl = {
                -- indexed but we can also add specific data by key
            }
            rs[language] = rl
            local sequences = tfmdata.resources.sequences
            if sequences then
                for s=1,#sequences do
                    local v = enabled and initialize(sequences[s],script,language,enabled,autoscript,autolanguage)
                    if v then
                        rl[#rl+1] = v
                    end
                end
            end
        end
        return rl
    end

end

-- Functions like kernrun, comprun etc evolved over time and in the end look rather
-- complex. It's a bit of a compromise between extensive copying and creating subruns.
-- The logic has been improved a lot by Kai and Ivo who use complex fonts which
-- really helped to identify border cases on the one hand and get insight in the diverse
-- ways fonts implement features (not always that consistent and efficient). At the same
-- time I tried to keep the code relatively efficient so that the overhead in runtime
-- stays acceptable.

local function report_disc(what,n)
    report_run("%s: %s > %s",what,n,languages.serializediscretionary(n))
end

local function kernrun(disc,k_run,font,attr,...)
    --
    -- we catch <font 1><disc font 2>
    --
    if trace_kernruns then
        report_disc("kern",disc)
    end
    --
    local prev, next = getboth(disc)
    --
    local nextstart = next
    local done      = false
    --
    local pre, post, replace, pretail, posttail, replacetail = getdisc(disc,true)
    --
    local prevmarks = prev
    --
    -- can be optional, because why on earth do we get a disc after a mark (okay, maybe when a ccmp
    -- has happened but then it should be in the disc so basically this test indicates an error)
    --
    while prevmarks do
        local char = ischar(prevmarks,font)
        if char and marks[char] then
            prevmarks = getprev(prevmarks)
        else
            break
        end
    end
    --
    if prev and not ischar(prev,font) then  -- and (pre or replace)
        prev = false
    end
    if next and not ischar(next,font) then  -- and (post or replace)
        next = false
    end
    --
    -- we need to get rid of this nest mess some day .. has to be done otherwise
    --
    if pre then
        if k_run(pre,"injections",nil,font,attr,...) then
            done = true
        end
        if prev then
            setlink(prev,pre)
            if k_run(prevmarks,"preinjections",pre,font,attr,...) then -- or prev?
                done = true
            end
            setprev(pre)
            setlink(prev,disc)
        end
    end
    --
    if post then
        if k_run(post,"injections",nil,font,attr,...) then
            done = true
        end
        if next then
            setlink(posttail,next)
            if k_run(posttail,"postinjections",next,font,attr,...) then
                done = true
            end
            setnext(posttail)
            setlink(disc,next)
        end
    end
    --
    if replace then
        if k_run(replace,"injections",nil,font,attr,...) then
            done = true
        end
        if prev then
            setlink(prev,replace)
            if k_run(prevmarks,"replaceinjections",replace,font,attr,...) then -- getnext(replace))
                done = true
            end
            setprev(replace)
            setlink(prev,disc)
        end
        if next then
            setlink(replacetail,next)
            if k_run(replacetail,"replaceinjections",next,font,attr,...) then
                done = true
            end
            setnext(replacetail)
            setlink(disc,next)
        end
    elseif prev and next then
        setlink(prev,next)
        if k_run(prevmarks,"emptyinjections",next,font,attr,...) then
            done = true
        end
        setlink(prev,disc,next)
    end
    if done and trace_testruns then
        report_disc("done",disc)
    end
 -- return nextstart, done
    return nextstart
end

-- fonts like ebgaramond do ligatures this way (less efficient than e.g. dejavu which
-- will do the testrun variant)

local function comprun(disc,c_run,...) -- vararg faster than the whole list
    if trace_compruns then
        report_disc("comp",disc)
    end
    --
    local pre, post, replace = getdisc(disc)
    local renewed = false
    --
    if pre then
        sweepnode = disc
        sweeptype = "pre" -- in alternative code preinjections is used (also used then for properties, saves a variable)
        local new, done = c_run(pre,...)
        if done then
            pre     = new
            renewed = true
        end
    end
    --
    if post then
        sweepnode = disc
        sweeptype = "post"
        local new, done = c_run(post,...)
        if done then
            post    = new
            renewed = true
        end
    end
    --
    if replace then
        sweepnode = disc
        sweeptype = "replace"
        local new, done = c_run(replace,...)
        if done then
            replace = new
            renewed = true
        end
    end
    --
    sweepnode = nil
    sweeptype = nil
    if renewed then
        if trace_testruns then
            report_disc("done",disc)
        end
        setdisc(disc,pre,post,replace)
    end
    --
 -- return getnext(disc), renewed
    return getnext(disc)
end

-- if we can hyphenate in a lig then unlikely a lig so we
-- could have a option here to ignore lig

local test_flatten_start = 2 -- must start at 2 according to Kai

directives.register("otf.testrun.forceflatten", function(v)
    test_flatten_start = v and 1 or 2
end)

local function testrun(disc,t_run,c_run,...)
    if trace_testruns then
        report_disc("test",disc)
    end
    local prev, next = getboth(disc)
    if not next then
        -- weird discretionary
        return
    end
    local pre, post, replace, pretail, posttail, replacetail = getdisc(disc,true)
    local renewed = false
    if post or replace then -- and prev then -- hm, we can start with a disc
        if post then
            setlink(posttail,next)
        else
            post = next
        end
        if replace then
            setlink(replacetail,next)
        else
            replace = next
        end
        local d_post    = t_run(post,next,...)
        local d_replace = t_run(replace,next,...)
        if d_post > 0 or d_replace > 0 then
            local d = d_replace > d_post and d_replace or d_post
            local head = getnext(disc) -- is: next
            local tail = head
            for i=test_flatten_start,d do
                local nx = getnext(tail)
                local id = getid(nx)
                if id == disc_code then
                    head, tail = flattendisk(head,nx)
                elseif id == glyph_code then
                    tail = nx
                else
                    -- we can have overrun into a glue
                    break
                end
            end
            next = getnext(tail)
            setnext(tail)
            setprev(head)
            local new  = copynodelist(head)
            if posttail then
                setlink(posttail,head)
            else
                post = head
            end
            if replacetail then
                setlink(replacetail,new)
            else
                replace = new
            end
        else
            -- we stay inside the disc
            if posttail then
                setnext(posttail)
            else
                post = nil
            end
            if replacetail then
                setnext(replacetail)
            else
                replace = nil
            end
        end
        setlink(disc,next)
     -- pre, post, replace, pretail, posttail, replacetail = getdisc(disc,true)
    end
    --
    -- like comprun
    --
    if trace_testruns then
        report_disc("more",disc)
    end
    --
    if pre then
        sweepnode = disc
        sweeptype = "pre"
        local new, ok = c_run(pre,...)
        if ok then
            pre     = new
            renewed = true
        end
    end
    --
    if post then
        sweepnode = disc
        sweeptype = "post"
        local new, ok = c_run(post,...)
        if ok then
            post    = new
            renewed = true
        end
    end
    --
    if replace then
        sweepnode = disc
        sweeptype = "replace"
        local new, ok = c_run(replace,...)
        if ok then
            replace = new
            renewed = true
        end
    end
    --
    sweepnode = nil
    sweeptype = nil
    if renewed then
        setdisc(disc,pre,post,replace)
        if trace_testruns then
            report_disc("done",disc)
        end
    end
    -- next can have changed (copied list)
 -- return getnext(disc), renewed
    return getnext(disc)
end

--  1{2{\oldstyle\discretionary{3}{4}{5}}6}7\par
--  1{2\discretionary{3{\oldstyle3}}{{\oldstyle4}4}{5{\oldstyle5}5}6}7\par

local nesting = 0

local function c_run_single(head,font,attr,lookupcache,step,dataset,sequence,rlmode,skiphash,handler)
    local done  = false
    local sweep = sweephead[head]
    local start
    if sweep then
        start = sweep
     -- sweephead[head] = nil
        sweephead[head] = false
    else
        start = head
    end
    while start do
        local char, id = ischar(start,font)
        if char then
            local a -- happens often so no assignment is faster
            if attr then
                a = getglyphdata(start)
            end
            if not a or (a == attr) then
                local lookupmatch = lookupcache[char]
                if lookupmatch then
                    local ok
                    head, start, ok = handler(head,start,dataset,sequence,lookupmatch,rlmode,skiphash,step)
                    if ok then
                        done = true
                    end
                end
                if start then
                    start = getnext(start)
                end
            else
                -- go on can be a mixed one
                start = getnext(start)
            end
        elseif char == false then
            return head, done
        elseif sweep then
            -- else we loose the rest
            return head, done
        else
            -- in disc component
            start = getnext(start)
        end
    end
    return head, done
end

-- only replace?

local function t_run_single(start,stop,font,attr,lookupcache)
    local lastd = nil
    while start ~= stop do
        local char = ischar(start,font)
        if char then
            local a -- happens often so no assignment is faster
            if attr then
                a = getglyphdata(start)
            end
            local startnext = getnext(start)
            if not a or (a == attr) then
                local lookupmatch = lookupcache[char]
                if lookupmatch then -- hm, hyphens can match (tlig) so we need to really check
                    -- if we need more than ligatures we can outline the code and use functions
                    local s     = startnext
                    local ss    = nil
                    local sstop = s == stop
                    if not s then
                        s = ss
                        ss = nil
                    end
                    -- a bit weird: why multiple ... anyway we can't have a disc in a disc
                    -- how about post ... we can probably merge this into the while
                    while getid(s) == disc_code do
                        ss = getnext(s)
                        s  = getreplace(s)
                        if not s then
                            s = ss
                            ss = nil
                        end
                    end
                    local l = nil
                    local d = 0
                    while s do
                        local char = ischar(s,font)
                        if char then
                            local lg = not tonumber(lookupmatch) and lookupmatch[char]
                            if lg then
                                if sstop then
                                    d = 1
                                elseif d > 0 then
                                    d = d + 1
                                end
                                l = lg
                                s = getnext(s)
                                sstop = s == stop
                                if not s then
                                    s  = ss
                                    ss = nil
                                end
                                while getid(s) == disc_code do
                                    ss = getnext(s)
                                    s  = getreplace(s)
                                    if not s then
                                        s  = ss
                                        ss = nil
                                    end
                                end
                                lookupmatch = lg
                            else
                                break
                            end
                        else
                            break
                        end
                    end
                    if l and (tonumber(l) or l.ligature) then -- so we test for ligature
                        lastd = d
                    end
                    -- why not: if not l then break elseif l.ligature then return d end
                else
                    -- why not: break
                    -- no match (yet)
                end
            else
                -- go on can be a mixed one
                -- why not: break
            end
            if lastd then
                return lastd
            end
            start = startnext
        else
            break
        end
    end
    return 0
end

local function k_run_single(sub,injection,last,font,attr,lookupcache,step,dataset,sequence,rlmode,skiphash,handler)
    local a -- happens often so no assignment is faster
    if attr then
        a = getglyphdata(sub)
    end
    if not a or (a == attr) then
        for n in nextnode, sub do -- only gpos
            if n == last then
                break
            end
            local char = ischar(n,font)
            if char then
                local lookupmatch = lookupcache[char]
                if lookupmatch then
                    local h, d, ok = handler(sub,n,dataset,sequence,lookupmatch,rlmode,skiphash,step,injection)
                    if ok then
                        return true
                    end
                end
            end
        end
    end
end

local function c_run_multiple(head,font,attr,steps,nofsteps,dataset,sequence,rlmode,skiphash,handler)
    local done  = false
    local sweep = sweephead[head]
    local start
    if sweep then
        start = sweep
     -- sweephead[head] = nil
        sweephead[head] = false
    else
        start = head
    end
    while start do
        local char = ischar(start,font)
        if char then
            local a -- happens often so no assignment is faster
            if attr then
                a = getglyphdata(start)
            end
            if not a or (a == attr) then
                for i=1,nofsteps do
                    local step        = steps[i]
                    local lookupcache = step.coverage
                    local lookupmatch = lookupcache[char]
                    if lookupmatch then
                        -- we could move all code inline but that makes things even more unreadable
                        local ok
                        head, start, ok = handler(head,start,dataset,sequence,lookupmatch,rlmode,skiphash,step)
                        if ok then
                            done = true
                            break
                        elseif not start then
                            -- don't ask why ... shouldn't happen
                            break
                        end
                    end
                end
                if start then
                    start = getnext(start)
                end
            else
                -- go on can be a mixed one
                start = getnext(start)
            end
        elseif char == false then
            -- whatever glyph
            return head, done
        elseif sweep then
            -- else we loose the rest
            return head, done
        else
            -- in disc component
            start = getnext(start)
        end
    end
    return head, done
end

local function t_run_multiple(start,stop,font,attr,steps,nofsteps)
    local lastd = nil
    while start ~= stop do
        local char = ischar(start,font)
        if char then
            local a -- happens often so no assignment is faster
            if attr then
                a = getglyphdata(start)
            end
            local startnext = getnext(start)
            if not a or (a == attr) then
                for i=1,nofsteps do
                    local step = steps[i]
                    local lookupcache = step.coverage
                    local lookupmatch = lookupcache[char]
                    if lookupmatch then
                        -- if we need more than ligatures we can outline the code and use functions
                        local s     = startnext
                        local ss    = nil
                        local sstop = s == stop
                        if not s then
                            s  = ss
                            ss = nil
                        end
                        while getid(s) == disc_code do
                            ss = getnext(s)
                            s  = getreplace(s)
                            if not s then
                                s  = ss
                                ss = nil
                            end
                        end
                        local l = nil
                        local d = 0
                        while s do
                            local char = ischar(s)
                            if char then
                                local lg = not tonumber(lookupmatch) and lookupmatch[char]
                                if lg then
                                    if sstop then
                                        d = 1
                                    elseif d > 0 then
                                        d = d + 1
                                    end
                                    l = lg
                                    s = getnext(s)
                                    sstop = s == stop
                                    if not s then
                                        s  = ss
                                        ss = nil
                                    end
                                    while getid(s) == disc_code do
                                        ss = getnext(s)
                                        s  = getreplace(s)
                                        if not s then
                                            s  = ss
                                            ss = nil
                                        end
                                    end
                                    lookupmatch = lg
                                else
                                    break
                                end
                            else
                                break
                            end
                        end
                        if l and (tonumber(l) or l.ligature) then
                            lastd = d
                        end
                    end
                end
            else
                -- go on can be a mixed one
            end
            if lastd then
                return lastd
            end
            start = startnext
        else
            break
        end
    end
    return 0
end

local function k_run_multiple(sub,injection,last,font,attr,steps,nofsteps,dataset,sequence,rlmode,skiphash,handler)
    local a -- happens often so no assignment is faster
    if attr then
        a = getglyphdata(sub)
    end
    if not a or (a == attr) then
        for n in nextnode, sub do -- only gpos
            if n == last then
                break
            end
            local char = ischar(n)
            if char then
                for i=1,nofsteps do
                    local step        = steps[i]
                    local lookupcache = step.coverage
                    local lookupmatch = lookupcache[char]
                    if lookupmatch then
                        local h, d, ok = handler(sub,n,dataset,sequence,lookupmatch,rlmode,skiphash,step,injection) -- sub was head
                        if ok then
                            return true
                        end
                    end
                end
            end
        end
    end
end

local txtdirstate, pardirstate  do -- this might change (no need for nxt in pardirstate)

    local getdirection = nuts.getdirection

    txtdirstate = function(start,stack,top,rlparmode)
        local dir, pop = getdirection(start)
        if pop then
            if top == 1 then
                return 0, rlparmode
            else
                top = top - 1
                if stack[top] == righttoleft_code then
                    return top, -1
                else
                    return top, 1
                end
            end
        elseif dir == lefttoright_code then
            top = top + 1
            stack[top] = lefttoright_code
            return top, 1
        elseif dir == righttoleft_code then
            top = top + 1
            stack[top] = righttoleft_code
            return top, -1
        else
            return top, rlparmode
        end
    end

    pardirstate = function(start)
        local dir = getdirection(start)
        if dir == lefttoright_code then
            return 1, 1
        elseif dir == righttoleft_code then
            return -1, -1
        else
            return 0, 0
        end
    end

end

-- These are non public helpers that can change without notice!

otf.helpers             = otf.helpers or { }
otf.helpers.txtdirstate = txtdirstate
otf.helpers.pardirstate = pardirstate

-- This is the main loop. We run over the node list dealing with a specific font. The
-- attribute is a context specific thing. We could work on sub start-stop ranges instead
-- but I wonder if there is that much speed gain (experiments showed that it made not
-- much sense) and we need to keep track of directions anyway. Also at some point I
-- want to play with font interactions and then we do need the full sweeps. Apart from
-- optimizations the principles of processing the features hasn't changed much since
-- the beginning.

do

    -- This is a measurable experimental speedup (only with hyphenated text and multiple
    -- fonts per processor call), especially for fonts with lots of contextual lookups.

    local fastdisc = true
    local testdics = false

    directives.register("otf.fastdisc",function(v) fastdisc = v end) -- normally enabled

    -- using a merged combined hash as first test saves some 30% on ebgaramond and
    -- about 15% on arabtype .. then moving the a test also saves a bit (even when
    -- often a is not set at all so that one is a bit debatable

    local otfdataset = nil -- todo: make an installer

    local getfastdisc = { __index = function(t,k)
        local v = usesfont(k,currentfont)
        t[k] = v
        return v
    end }

    local getfastspace = { __index = function(t,k)
        -- we don't pass the id so that one can overload isspace
        local v = isspace(k,threshold) or false
        t[k] = v
        return v
    end }

    function otf.featuresprocessor(head,font,attr,direction,n)

        local sequences = sequencelists[font] -- temp hack

        nesting = nesting + 1

        if nesting == 1 then
            currentfont  = font
            tfmdata      = fontdata[font]
            descriptions = tfmdata.descriptions -- only needed in gref so we could pass node there instead
            characters   = tfmdata.characters   -- but this branch is not entered that often anyway
      local resources    = tfmdata.resources
            marks        = resources.marks
            classes      = resources.classes
            threshold,
            factor       = getthreshold(font)
            checkmarks   = tfmdata.properties.checkmarks

            if not otfdataset then
                otfdataset = otf.dataset
            end

            discs  = fastdisc and n and n > 1 and setmetatable({},getfastdisc) -- maybe inline
            spaces = setmetatable({},getfastspace)

        elseif currentfont ~= font then

            report_warning("nested call with a different font, level %s, quitting",nesting)
            nesting = nesting - 1
            return head, false

        end

        -- some 10% faster when no dynamics but hardly measureable on real runs .. but: it only
        -- works when we have no other dynamics as otherwise the zero run will be applied to the
        -- whole stream for which we then need to pass another variable which we won't

        -- if attr == 0 then
        --     attr = false
        -- end

        if trace_steps then
            checkstep(head)
        end

        local initialrl = 0

        if getid(head) == par_code and startofpar(head) then
            initialrl = pardirstate(head)
        elseif direction == righttoleft_code then
            initialrl = -1
        end

     -- local done      = false
        local datasets  = otfdataset(tfmdata,font,attr)
        local dirstack  = { nil } -- could move outside function but we can have local runs
        sweephead       = { }
     -- sweephead  = { a = 1, b = 1 } sweephead.a = nil sweephead.b = nil

        -- Keeping track of the headnode is needed for devanagari. (I generalized it a bit
        -- so that multiple cases are also covered.) We could prepend a temp node.

        -- We don't goto the next node when a disc node is created so that we can then treat
        -- the pre, post and replace. It's a bit of a hack but works out ok for most cases.

        for s=1,#datasets do
            local dataset      = datasets[s]
            local attribute    = dataset[2]
            local sequence     = dataset[3] -- sequences[s] -- also dataset[5]
            local rlparmode    = initialrl
            local topstack     = 0
            local typ          = sequence.type
            local gpossing     = typ == "gpos_single" or typ == "gpos_pair" -- store in dataset
            local forcetestrun = typ == "gsub_ligature" -- testrun is only for ligatures
            local handler      = handlers[typ] -- store in dataset
            local steps        = sequence.steps
            local nofsteps     = sequence.nofsteps
            local skiphash     = sequence.skiphash

            if not steps then
                -- This permits injection, watch the different arguments. Watch out, the arguments passed
                -- are not frozen as we might extend or change this. Is this used at all apart from some
                -- experiments?
                local h, ok = handler(head,dataset,sequence,initialrl,font,attr) -- less arguments now
             -- if ok then
             --     done = true
             -- end
                if h and h ~= head then
                    head = h
                end
            elseif typ == "gsub_reversecontextchain" then
                --
                -- This might need a check: if we have #before or #after > 0 then we might need to reverse
                -- the before and after lists in the loader. But first I need to see a font that uses multiple
                -- matches.
                --
                local start  = findnodetail(head)
                local rlmode = 0 -- how important is this .. do we need to check for dir?
                local merged = steps.merged
                while start do
                    local char = ischar(start,font)
                    if char then
                        local m = merged[char]
                        if m then
                            local a -- happens often so no assignment is faster
                            if attr then
                                a = getglyphdata(start)
                            end
                            if not a or (a == attr) then
                                for i=m[1],m[2] do
                                    local step = steps[i]
                             -- for i=1,#m do
                             --     local step = m[i]
                                    local lookupcache = step.coverage
                                    local lookupmatch = lookupcache[char]
                                    if lookupmatch then
                                        local ok
                                        head, start, ok = handler(head,start,dataset,sequence,lookupmatch,rlmode,skiphash,step)
                                        if ok then
                                         -- done = true
                                            break
                                        end
                                    end
                                end
                                if start then
                                    start = getprev(start)
                                end
                            else
                                start = getprev(start)
                            end
                        else
                            start = getprev(start)
                        end
                    else
                        start = getprev(start)
                    end
                end
            else
                local start  = head
                local rlmode = initialrl
                if nofsteps == 1 then -- happens often
                    local step = steps[1]
                    local lookupcache = step.coverage
                    while start do
                        local char, id = ischar(start,font)
                        if char then
                            if skiphash and skiphash[char] then -- we never needed it here but let's try
                                start = getnext(start)
                            else
                                local lookupmatch = lookupcache[char]
                                if lookupmatch then
                                    local a -- happens often so no assignment is faster
                                    if attr then
                                        if getglyphdata(start) == attr and (not attribute or getstate(start,attribute)) then
                                            a = true
                                        end
                                    elseif not attribute or getstate(start,attribute) then
                                        a = true
                                    end
                                    if a then
                                        local ok, df
                                        head, start, ok, df = handler(head,start,dataset,sequence,lookupmatch,rlmode,skiphash,step)
                                     -- if ok then
                                     --     done = true
                                     -- end
                                        if df then
-- print("restart 1",typ)
                                        elseif start then
                                            start = getnext(start)
                                        end
                                    else
                                        start = getnext(start)
                                    end
                                else
                                   start = getnext(start)
                                end
                            end
                        elseif char == false or id == glue_code then
                            -- a different font|state or glue (happens often)
                            start = getnext(start)
                        elseif id == disc_code then
                            if not discs or discs[start] == true then
                                if gpossing then
                                    start = kernrun(start,k_run_single,             font,attr,lookupcache,step,dataset,sequence,rlmode,skiphash,handler)
                                elseif forcetestrun then
                                    start = testrun(start,t_run_single,c_run_single,font,attr,lookupcache,step,dataset,sequence,rlmode,skiphash,handler)
                                else
                                    start = comprun(start,c_run_single,             font,attr,lookupcache,step,dataset,sequence,rlmode,skiphash,handler)
                                end
                            else
                                start = getnext(start)
                            end
                        elseif id == math_code then
                            start = getnext(endofmath(start))
                        elseif id == dir_code then
                            topstack, rlmode = txtdirstate(start,dirstack,topstack,rlparmode)
                            start = getnext(start)
                     -- elseif id == par_code and startofpar(start) then
                     --     rlparmode, rlmode = pardirstate(start)
                     --     start = getnext(start)
                        else
                            start = getnext(start)
                        end
                    end
                else
                    local merged = steps.merged
                    while start do
                        local char, id = ischar(start,font)
                        if char then
                            if skiphash and skiphash[char] then -- we never needed it here but let's try
                                start = getnext(start)
                            else
                                local m = merged[char]
                                if m then
                                    local a -- happens often so no assignment is faster
                                    if attr then
                                        if getglyphdata(start) == attr and (not attribute or getstate(start,attribute)) then
                                            a = true
                                        end
                                    elseif not attribute or getstate(start,attribute) then
                                        a = true
                                    end
                                    if a then
                                        local ok, df
                                        for i=m[1],m[2] do
                                            local step = steps[i]
                                     -- for i=1,#m do
                                     --     local step = m[i]
                                            local lookupcache = step.coverage
                                            local lookupmatch = lookupcache[char]
                                            if lookupmatch then
                                                -- we could move all code inline but that makes things even more unreadable
--                                                 local ok, df
                                                head, start, ok, df = handler(head,start,dataset,sequence,lookupmatch,rlmode,skiphash,step)
                                                if df then
                                                    break
                                                elseif ok then
                                                 -- done = true
                                                    break
                                                elseif not start then
                                                    -- don't ask why ... shouldn't happen
                                                    break
                                                end
                                            end
                                        end
                                        if df then
-- print("restart 2",typ)
                                        elseif start then
                                            start = getnext(start)
                                        end
                                    else
                                        start = getnext(start)
                                    end
                                else
                                    start = getnext(start)
                                end
                            end
                        elseif char == false or id == glue_code then
                            -- a different font|state or glue (happens often)
                            start = getnext(start)
                        elseif id == disc_code then
                            if not discs or discs[start] == true then
                                if gpossing then
                                    start = kernrun(start,k_run_multiple,               font,attr,steps,nofsteps,dataset,sequence,rlmode,skiphash,handler)
                                elseif forcetestrun then
                                    start = testrun(start,t_run_multiple,c_run_multiple,font,attr,steps,nofsteps,dataset,sequence,rlmode,skiphash,handler)
                                else
                                    start = comprun(start,c_run_multiple,               font,attr,steps,nofsteps,dataset,sequence,rlmode,skiphash,handler)
                                end
                            else
                                start = getnext(start)
                            end
                        elseif id == math_code then
                            start = getnext(endofmath(start))
                        elseif id == dir_code then
                            topstack, rlmode = txtdirstate(start,dirstack,topstack,rlparmode)
                            start = getnext(start)
                     -- elseif id == par_code and startofpar(start) then
                     --     rlparmode, rlmode = pardirstate(start)
                     --     start = getnext(start)
                        else
                            start = getnext(start)
                        end
                    end
                end
            end

            if trace_steps then -- ?
                registerstep(head)
            end

        end

        nesting = nesting - 1

     -- return head, done
        return head
    end

    -- This is not an official helper and used for tracing experiments. It can be changed as I like
    -- at any moment. At some point it might be used in a module that can help font development.

    function otf.datasetpositionprocessor(head,font,direction,dataset)

        currentfont     = font
        tfmdata         = fontdata[font]
        descriptions    = tfmdata.descriptions -- only needed in gref so we could pass node there instead
        characters      = tfmdata.characters   -- but this branch is not entered that often anyway
  local resources       = tfmdata.resources
        marks           = resources.marks
        classes         = resources.classes
        threshold,
        factor          = getthreshold(font)
        checkmarks      = tfmdata.properties.checkmarks

        if type(dataset) == "number" then
            dataset = otfdataset(tfmdata,font,0)[dataset]
        end

        local sequence  = dataset[3] -- sequences[s] -- also dataset[5]
        local typ       = sequence.type
     -- local gpossing  = typ == "gpos_single" or typ == "gpos_pair" -- store in dataset

     -- gpos_contextchain gpos_context

     -- if not gpossing then
     --     return head, false
     -- end

        local handler   = handlers[typ] -- store in dataset
        local steps     = sequence.steps
        local nofsteps  = sequence.nofsteps

        local done      = false
        local dirstack  = { nil } -- could move outside function but we can have local runs (maybe a few more nils)
        local start     = head
        local initialrl = (direction == righttoleft_code) and -1 or 0
        local rlmode    = initialrl
        local rlparmode = initialrl
        local topstack  = 0
        local merged    = steps.merged

     -- local matches   = false
        local position  = 0

        while start do
            local char, id = ischar(start,font)
            if char then
                position = position + 1
                local m = merged[char]
                if m then
                    if skiphash and skiphash[char] then -- we never needed it here but let's try
                        start = getnext(start)
                    else
                        for i=m[1],m[2] do
                            local step = steps[i]
                            local lookupcache = step.coverage
                            local lookupmatch = lookupcache[char]
                            if lookupmatch then
                                local ok
                                head, start, ok = handler(head,start,dataset,sequence,lookupmatch,rlmode,skiphash,step)
                                if ok then
                                 -- if matches then
                                 --     matches[position] = i
                                 -- else
                                 --     matches = { [position] = i }
                                 -- end
                                    break
                                elseif not start then
                                    break
                                end
                            end
                        end
                        if start then
                            start = getnext(start)
                        end
                    end
                else
                    start = getnext(start)
                end
            elseif char == false or id == glue_code then
                -- a different font|state or glue (happens often)
                start = getnext(start)
            elseif id == math_code then
                start = getnext(endofmath(start))
            elseif id == dir_code then
                topstack, rlmode = txtdirstate(start,dirstack,topstack,rlparmode)
                start = getnext(start)
         -- elseif id == par_code and startofpar(start) then
         --     rlparmode, rlmode = pardirstate(start)
         --     start = nxt
            else
                start = getnext(start)
            end
        end

        return head
    end

    -- end of experiment

end

-- so far

do

    local plugins = { }
    otf.plugins   = plugins

    local report  = logs.reporter("fonts")
    local warned  = false
    local okay    = { text = true }

    function otf.registerplugin(name,f)
        if type(name) == "string" and type(f) == "function" then
            plugins[name] = { name, f }
            if okay[name] then
                -- no warning (e.g. the diagnostic text plugin)
            else
                report("plugin %a has been loaded, please be aware of possible side effects",name)
                if not warned then
                    if logs.pushtarget then
                        logs.pushtarget("log")
                    end
                    report("Plugins are not officially supported unless stated otherwise. This is because")
                    report("they bypass the regular font handling and therefore some features in ConTeXt")
                    report("(especially those related to fonts) might not work as expected or might not work")
                    report("at all. Some plugins are for testing and development only and might change")
                    report("whenever we feel the need for it.")
                    report()
                    if logs.poptarget then
                        logs.poptarget()
                    end
                    warned = true
                end
            end
        end
    end

    function otf.plugininitializer(tfmdata,value)
        if type(value) == "string" then
            tfmdata.shared.plugin = plugins[value]
        end
    end

    function otf.pluginprocessor(head,font,dynamic,direction) -- n
        local s = fontdata[font].shared
        local p = s and s.plugin
        if p then
            if trace_plugins then
                report_process("applying plugin %a",p[1])
            end
            return p[2](head,font,dynamic,direction)
        else
            return head, false
        end
    end

end

function otf.featuresinitializer(tfmdata,value)
    -- nothing done here any more
end

registerotffeature {
    name         = "features",
    description  = "features",
    default      = true,
    initializers = {
        position = 1,
        node     = otf.featuresinitializer,
        plug     = otf.plugininitializer,
    },
    processors   = {
        node     = otf.featuresprocessor,
        plug     = otf.pluginprocessor,
    }
}

-- Moved here (up) a bit. This doesn't really belong in generic so it will move to a
-- context module some day.

local function markinitializer(tfmdata,value)
    local properties = tfmdata.properties
    properties.checkmarks = value
end

registerotffeature {
    name         = "checkmarks",
    description  = "check mark widths",
    default      = true,
    initializers = {
        node     = markinitializer,
    },
}

-- This can be used for extra handlers, but should be used with care! We implement one
-- here but some more can be found in the osd (script devanagary) file. Now watch out:
-- when a handler has steps, it is called as the other ones, but when we have no steps,
-- we use a different call:
--
--   function(head,dataset,sequence,initialrl,font,attr)
--       return head, done
--   end
--
-- Also see (!!).

otf.handlers = handlers

if context then
    return
else
    -- todo: move the following code someplace else
end

local setspacekerns = nodes.injections.setspacekerns if not setspacekerns then os.exit() end

local tag = "kern"

-- if fontfeatures then

--     function handlers.trigger_space_kerns(head,dataset,sequence,initialrl,font,attr)
--         local features = fontfeatures[font]
--         local enabled  = features and features.spacekern and features[tag]
--         if enabled then
--             setspacekerns(font,sequence)
--         end
--         return head, enabled
--     end

-- else -- generic (no hashes)

    function handlers.trigger_space_kerns(head,dataset,sequence,initialrl,font,attr)
        local shared   = fontdata[font].shared
        local features = shared and shared.features
        local enabled  = features and features.spacekern and features[tag]
        if enabled then
            setspacekerns(font,sequence)
        end
        return head, enabled
    end

-- end

-- There are fonts out there that change the space but we don't do that kind of
-- things in TeX.

local function hasspacekerns(data)
    local resources = data.resources
    local sequences = resources.sequences
    local validgpos = resources.features.gpos
    if validgpos and sequences then
        for i=1,#sequences do
            local sequence = sequences[i]
            local steps    = sequence.steps
            if steps and sequence.features[tag] then
                local kind = sequence.type
                if kind == "gpos_pair" or kind == "gpos_single" then
                    for i=1,#steps do
                        local step     = steps[i]
                        local coverage = step.coverage
                        local rules    = step.rules
                        if rules then
                            -- not now: analyze (simple) rules
                        elseif not coverage then
                            -- nothing to do
                        elseif kind == "gpos_single" then
                            -- maybe a message that we ignore
                        elseif kind == "gpos_pair" then
                            local format = step.format
                            if format == "move" or format == "kern" then
                                local kerns  = coverage[32]
                                if kerns then
                                    return true
                                end
                                for k, v in next, coverage do
                                    if v[32] then
                                        return true
                                    end
                                end
                            elseif format == "pair" then
                                local kerns  = coverage[32]
                                if kerns then
                                    for k, v in next, kerns do
                                        local one = v[1]
                                        if one and one ~= true then
                                            return true
                                        end
                                    end
                                end
                                for k, v in next, coverage do
                                    local kern = v[32]
                                    if kern then
                                        local one = kern[1]
                                        if one and one ~= true then
                                            return true
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end
    return false
end

otf.readers.registerextender {
    name   = "spacekerns",
    action = function(data)
        data.properties.hasspacekerns = hasspacekerns(data)
    end
}

local function spaceinitializer(tfmdata,value) -- attr
    local resources  = tfmdata.resources
    local spacekerns = resources and resources.spacekerns
    if value and spacekerns == nil then
        local rawdata    = tfmdata.shared and tfmdata.shared.rawdata
        local properties = rawdata.properties
        if properties and properties.hasspacekerns then
            local sequences = resources.sequences
            local validgpos = resources.features.gpos
            if validgpos and sequences then
                local left  = { }
                local right = { }
                local last  = 0
                local feat  = nil
                for i=1,#sequences do
                    local sequence = sequences[i]
                    local steps    = sequence.steps
                    if steps then
                        -- we don't support space kerns in other features
                        local kern = sequence.features[tag]
                        if kern then
                            local kind = sequence.type
                            if kind == "gpos_pair" or kind == "gpos_single" then
                                if feat then
                                    for script, languages in next, kern do
                                        local f = feat[script]
                                        if f then
                                            for l in next, languages do
                                                f[l] = true
                                            end
                                        else
                                            feat[script] = languages
                                        end
                                    end
                                else
                                    feat = kern
                                end
                                for i=1,#steps do
                                    local step     = steps[i]
                                    local coverage = step.coverage
                                    local rules    = step.rules
                                    if rules then
                                        -- not now: analyze (simple) rules
                                    elseif not coverage then
                                        -- nothing to do
                                    elseif kind == "gpos_single" then
                                        -- makes no sense in TeX
                                    elseif kind == "gpos_pair" then
                                        local format = step.format
                                        if format == "move" or format == "kern" then
                                            local kerns  = coverage[32]
                                            if kerns then
                                                for k, v in next, kerns do
                                                    right[k] = v
                                                end
                                            end
                                            for k, v in next, coverage do
                                                local kern = v[32]
                                                if kern then
                                                    left[k] = kern
                                                end
                                            end
                                        elseif format == "pair" then
                                            local kerns  = coverage[32]
                                            if kerns then
                                                for k, v in next, kerns do
                                                    local one = v[1]
                                                    if one and one ~= true then
                                                        right[k] = one[3]
                                                    end
                                                end
                                            end
                                            for k, v in next, coverage do
                                                local kern = v[32]
                                                if kern then
                                                    local one = kern[1]
                                                    if one and one ~= true then
                                                        left[k] = one[3]
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                                last = i
                            end
                        else
                            -- no steps ... needed for old one ... we could use the basekerns
                            -- instead
                        end
                    end
                end
                left  = next(left)  and left  or false
                right = next(right) and right or false
                if left or right then
                    spacekerns = {
                        left  = left,
                        right = right,
                    }
                    if last > 0 then
                        local triggersequence = {
                            -- no steps, see (!!)
                            features = { [tag] = feat or { dflt = { dflt = true, } } },
                            flags    = noflags,
                            name     = "trigger_space_kerns",
                            order    = { tag },
                            type     = "trigger_space_kerns",
                            left     = left,
                            right    = right,
                        }
                        insert(sequences,last,triggersequence)
                    end
                end
            end
        end
        resources.spacekerns = spacekerns
    end
    return spacekerns
end

registerotffeature {
    name         = "spacekern",
    description  = "space kern injection",
    default      = true,
    initializers = {
        node     = spaceinitializer,
    },
}
