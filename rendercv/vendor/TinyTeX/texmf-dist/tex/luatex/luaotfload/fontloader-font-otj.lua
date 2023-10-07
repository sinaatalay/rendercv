if not modules then modules = { } end modules ['font-otj'] = {
    version   = 1.001,
    optimize  = true,
    comment   = "companion to font-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files",
}

-- This property based variant is not faster but looks nicer than the attribute one. We
-- need to use rawget (which is about 4 times slower than a direct access but we cannot
-- get/set that one for our purpose! This version does a bit more with discretionaries
-- (and Kai has tested it with his collection of weird fonts.)

-- There is some duplicate code here (especially in the the pre/post/replace branches) but
-- we go for speed. We could store a list of glyph and mark nodes when registering but it's
-- cleaner to have an identification pass here. Also, I need to keep tracing in mind so
-- being too clever here is dangerous.

-- As we have a rawget on properties we don't need one on injections.

-- The use_advance code was just a test and is meant for testing and manuals. There is no
-- performance (or whatever) gain and using kerns is somewhat cleaner (at least for now).

-- An alternative is to have a list per base of all marks and then do a run over the node
-- list that resolves the accumulated l/r/x/y and then do an inject pass.

-- if needed we can flag a kern node as immutable

-- The thing with these positioning options is that it is not clear what Uniscribe does with
-- the 2rl flag and we keep oscillating a between experiments.

if not nodes.properties then return end

local next, rawget, tonumber = next, rawget, tonumber
local fastcopy = table.fastcopy

local registertracker   = trackers.register
local registerdirective = directives.register

local trace_injections  = false  registertracker("fonts.injections",         function(v) trace_injections = v end)
local trace_marks       = false  registertracker("fonts.injections.marks",   function(v) trace_marks      = v end)
local trace_cursive     = false  registertracker("fonts.injections.cursive", function(v) trace_cursive    = v end)
local trace_spaces      = false  registertracker("fonts.injections.spaces",  function(v) trace_spaces  = v end)

-- local fix_cursive_marks = false
--
-- registerdirective("fonts.injections.fixcursivemarks", function(v)
--     fix_cursive_marks = v
-- end)

local report_injections = logs.reporter("fonts","injections")
local report_spaces     = logs.reporter("fonts","spaces")

local attributes, nodes, node = attributes, nodes, node

fonts                    = fonts
local hashes             = fonts.hashes
local fontdata           = hashes.identifiers
local fontmarks          = hashes.marks
----- parameters         = fonts.hashes.parameters -- not in generic
----- resources          = fonts.hashes.resources  -- not in generic

nodes.injections         = nodes.injections or { }
local injections         = nodes.injections

local tracers            = nodes.tracers
local setcolor           = tracers and tracers.colors.set
local resetcolor         = tracers and tracers.colors.reset

local nodecodes          = nodes.nodecodes
local glyph_code         = nodecodes.glyph
local disc_code          = nodecodes.disc
local kern_code          = nodecodes.kern
local glue_code          = nodecodes.glue

local nuts               = nodes.nuts
local nodepool           = nuts.pool

local tonode             = nuts.tonode
local tonut              = nuts.tonut

local setfield           = nuts.setfield
local getnext            = nuts.getnext
local getprev            = nuts.getprev
local getid              = nuts.getid
local getfont            = nuts.getfont
local getchar            = nuts.getchar
local getoffsets         = nuts.getoffsets
local getboth            = nuts.getboth
local getdisc            = nuts.getdisc
local setdisc            = nuts.setdisc
local getreplace         = nuts.getreplace
local setreplace         = nuts.setreplace
local setoffsets         = nuts.setoffsets
local ischar             = nuts.ischar
local getkern            = nuts.getkern
local setkern            = nuts.setkern
local setlink            = nuts.setlink
local setwidth           = nuts.setwidth
local getwidth           = nuts.getwidth

local nextchar           = nuts.traversers.char
local nextglue           = nuts.traversers.glue

local insertnodebefore   = nuts.insertbefore
local insertnodeafter    = nuts.insertafter

local properties         = nodes.properties.data

local fontkern           = nuts.pool and nuts.pool.fontkern   -- context
local italickern         = nuts.pool and nuts.pool.italickern -- context

local useitalickerns     = false -- context only

directives.register("fonts.injections.useitalics", function(v)
    if v then
        report_injections("using italics for space kerns (tracing only)")
    end
    useitalickerns = v
end)

if not fontkern then -- generic

    local thekern   = nuts.new("kern",0) -- fontkern
    local setkern   = nuts.setkern
    local copy_node = nuts.copy

    fontkern = function(k)
        local n = copy_node(thekern)
        setkern(n,k)
        return n
    end

end

if not italickern then -- generic

    local thekern   = nuts.new("kern",3) -- italiccorrection
    local setkern   = nuts.setkern
    local copy_node = nuts.copy

    italickern = function(k)
        local n = copy_node(thekern)
        setkern(n,k)
        return n
    end

end

function injections.installnewkern() end -- obsolete

local nofregisteredkerns     = 0
local nofregisteredpositions = 0
local nofregisteredmarks     = 0
local nofregisteredcursives  = 0
local keepregisteredcounts   = false

function injections.keepcounts()
    keepregisteredcounts = true
end

function injections.resetcounts()
    nofregisteredkerns     = 0
    nofregisteredpositions = 0
    nofregisteredmarks     = 0
    nofregisteredcursives  = 0
    keepregisteredcounts   = false
end

-- We need to make sure that a possible metatable will not kick in unexpectedly.

function injections.reset(n)
    local p = rawget(properties,n)
    if p then
        p.injections = false -- { } -- nil should work too as we use rawget
    else
        properties[n] = false -- { injections = { } } -- nil should work too as we use rawget
    end
end

function injections.copy(target,source)
    local sp = rawget(properties,source)
    if sp then
        local tp = rawget(properties,target)
        local si = sp.injections
        if si then
            si = fastcopy(si)
            if tp then
                tp.injections = si
            else
                properties[target] = {
                    injections = si,
                }
            end
        elseif tp then
            tp.injections = false -- { }
        else
            properties[target] = { injections = { } }
        end
    else
        local tp = rawget(properties,target)
        if tp then
            tp.injections = false -- { }
        else
            properties[target] = false -- { injections = { } }
        end
    end
end

function injections.setligaindex(n,index) -- todo: don't set when 0
    local p = rawget(properties,n)
    if p then
        local i = p.injections
        if i then
            i.ligaindex = index
        else
            p.injections = {
                ligaindex = index
            }
        end
    else
        properties[n] = {
            injections = {
                ligaindex = index
            }
        }
    end
end

function injections.getligaindex(n,default)
    local p = rawget(properties,n)
    if p then
        local i = p.injections
        if i then
            return i.ligaindex or default
        end
    end
    return default
end

function injections.setcursive(start,nxt,factor,rlmode,exit,entry,tfmstart,tfmnext,r2lflag)

    -- The standard says something about the r2lflag related to the first in a series:
    --
    --   When this bit is set, the last glyph in a given sequence to which the cursive
    --   attachment lookup is applied, will be positioned on the baseline.
    --
    -- But it looks like we don't need to consider it.

    local dx =  factor*(exit[1]-entry[1])
    local dy = -factor*(exit[2]-entry[2])
    local ws = tfmstart.width
    local wn = tfmnext.width
    nofregisteredcursives = nofregisteredcursives + 1
    if rlmode < 0 then
        dx = -(dx + wn)
    else
        dx = dx - ws
    end
    if dx == 0 then
     -- get rid of funny -0
        dx = 0
    end
    --
    local p = rawget(properties,start)
    if p then
        local i = p.injections
        if i then
            i.cursiveanchor = true
        else
            p.injections = {
                cursiveanchor = true,
            }
        end
    else
        properties[start] = {
            injections = {
                cursiveanchor = true,
            },
        }
    end
    local p = rawget(properties,nxt)
    if p then
        local i = p.injections
        if i then
            i.cursivex = dx
            i.cursivey = dy
        else
            p.injections = {
                cursivex = dx,
                cursivey = dy,
            }
        end
    else
        properties[nxt] = {
            injections = {
                cursivex = dx,
                cursivey = dy,
            },
        }
    end
    return dx, dy, nofregisteredcursives
end

-- kind: 0=single 1=first of pair, 2=second of pair

function injections.setposition(kind,current,factor,rlmode,spec,injection)
    local x = factor * (spec[1] or 0)
    local y = factor * (spec[2] or 0)
    local w = factor * (spec[3] or 0)
    local h = factor * (spec[4] or 0)
    if x ~= 0 or w ~= 0 or y ~= 0 or h ~= 0 then -- okay?
        local yoffset   = y - h
        local leftkern  = x      -- both kerns are set in a pair kern compared
        local rightkern = w - x  -- to normal kerns where we set only leftkern
        if leftkern ~= 0 or rightkern ~= 0 or yoffset ~= 0 then
            nofregisteredpositions = nofregisteredpositions + 1
            if rlmode and rlmode < 0 then
                leftkern, rightkern = rightkern, leftkern
            end
            if not injection then
                injection = "injections"
            end
            local p = rawget(properties,current)
            if p then
                local i = p[injection]
                if i then
                    if leftkern ~= 0 then
                        i.leftkern  = (i.leftkern  or 0) + leftkern
                    end
                    if rightkern ~= 0 then
                        i.rightkern = (i.rightkern or 0) + rightkern
                    end
                    if yoffset ~= 0 then
                        i.yoffset = (i.yoffset or 0) + yoffset
                    end
                elseif leftkern ~= 0 or rightkern ~= 0 then
                    p[injection] = {
                        leftkern  = leftkern,
                        rightkern = rightkern,
                        yoffset   = yoffset,
                    }
                else
                    p[injection] = {
                        yoffset = yoffset,
                    }
                end
            elseif leftkern ~= 0 or rightkern ~= 0 then
                properties[current] = {
                    [injection] = {
                        leftkern  = leftkern,
                        rightkern = rightkern,
                        yoffset   = yoffset,
                    },
                }
            else
                properties[current] = {
                    [injection] = {
                        yoffset = yoffset,
                    },
                }
            end
            return x, y, w, h, nofregisteredpositions
         end
    end
    return x, y, w, h -- no bound
end

-- The next one is used for simple kerns coming from a truetype kern table. The r2l
-- variant variant needs checking but it is unlikely that a r2l script uses thsi
-- feature.

function injections.setkern(current,factor,rlmode,x,injection)
    local dx = factor * x
    if dx ~= 0 then
        nofregisteredkerns = nofregisteredkerns + 1
        local p = rawget(properties,current)
        if not injection then
            injection = "injections"
        end
        if p then
            local i = p[injection]
            if i then
                i.leftkern = dx + (i.leftkern or 0)
            else
                p[injection] = {
                    leftkern = dx,
                }
            end
        else
            properties[current] = {
                [injection] = {
                    leftkern = dx,
                },
            }
        end
        return dx, nofregisteredkerns
    else
        return 0, 0
    end
end

-- This one is an optimization of pairs where we have only a "w" entry. This one is
-- potentially different from the previous one wrt r2l. It needs checking. The
-- optimization relates to smaller tma files.

function injections.setmove(current,factor,rlmode,x,injection)
    local dx = factor * x
    if dx ~= 0 then
        nofregisteredkerns = nofregisteredkerns + 1
        local p = rawget(properties,current)
        if not injection then
            injection = "injections"
        end
        if rlmode and rlmode < 0 then
            -- we need to swap with a single so then we also need to to it here
            -- as move is just a simple single
            if p then
                local i = p[injection]
                if i then
                    i.rightkern = dx + (i.rightkern or 0)
                else
                    p[injection] = {
                        rightkern = dx,
                    }
                end
            else
                properties[current] = {
                    [injection] = {
                        rightkern = dx,
                    },
                }
            end
        else
            if p then
                local i = p[injection]
                if i then
                    i.leftkern = dx + (i.leftkern or 0)
                else
                    p[injection] = {
                        leftkern = dx,
                    }
                end
            else
                properties[current] = {
                    [injection] = {
                        leftkern = dx,
                    },
                }
            end
        end
        return dx, nofregisteredkerns
    else
        return 0, 0
    end
end

function injections.setmark(start,base,factor,rlmode,ba,ma,tfmbase,mkmk,checkmark) -- ba=baseanchor, ma=markanchor
    local dx = factor*(ba[1]-ma[1])
    local dy = factor*(ba[2]-ma[2])
    nofregisteredmarks = nofregisteredmarks + 1
    if rlmode >= 0 then
        dx = tfmbase.width - dx -- see later commented ox
    end
    local p = rawget(properties,start)
    -- hm, dejavu serif does a sloppy mark2mark before mark2base
    if p then
        local i = p.injections
        if i then
            if i.markmark then
                -- out of order mkmk: yes or no or option
            else
             -- if dx ~= 0 then
             --     i.markx    = dx
             -- end
             -- if y ~= 0 then
             --     i.marky    = dy
             -- end
             -- if rlmode then
             --     i.markdir  = rlmode
             -- end
                i.markx        = dx
                i.marky        = dy
                i.markdir      = rlmode or 0
                i.markbase     = nofregisteredmarks
                i.markbasenode = base
                i.markmark     = mkmk
                i.checkmark    = checkmark
            end
        else
            p.injections = {
                markx        = dx,
                marky        = dy,
                markdir      = rlmode or 0,
                markbase     = nofregisteredmarks,
                markbasenode = base,
                markmark     = mkmk,
                checkmark    = checkmark,
            }
        end
    else
        properties[start] = {
            injections = {
                markx        = dx,
                marky        = dy,
                markdir      = rlmode or 0,
                markbase     = nofregisteredmarks,
                markbasenode = base,
                markmark     = mkmk,
                checkmark    = checkmark,
            },
        }
    end
    return dx, dy, nofregisteredmarks
end

local function dir(n)
    return (n and n<0 and "r-to-l") or (n and n>0 and "l-to-r") or "unset"
end

local function showchar(n,nested)
    local char = getchar(n)
    report_injections("%wfont %s, char %U, glyph %c",nested and 2 or 0,getfont(n),char,char)
end

local function show(n,what,nested,symbol)
    if n then
        local p = rawget(properties,n)
        if p then
            local i = p[what]
            if i then
                local leftkern  = i.leftkern  or 0
                local rightkern = i.rightkern or 0
                local yoffset   = i.yoffset   or 0
                local markx     = i.markx     or 0
                local marky     = i.marky     or 0
                local markdir   = i.markdir   or 0
                local markbase  = i.markbase  or 0
                local cursivex  = i.cursivex  or 0
                local cursivey  = i.cursivey  or 0
                local ligaindex = i.ligaindex or 0
                local cursbase  = i.cursiveanchor
                local margin    = nested and 4 or 2
                --
                if rightkern ~= 0 or yoffset ~= 0 then
                    report_injections("%w%s pair: lx %p, rx %p, dy %p",margin,symbol,leftkern,rightkern,yoffset)
                elseif leftkern ~= 0 then
                    report_injections("%w%s kern: dx %p",margin,symbol,leftkern)
                end
                if markx ~= 0 or marky ~= 0 or markbase ~= 0 then
                    report_injections("%w%s mark: dx %p, dy %p, dir %s, base %s",margin,symbol,markx,marky,markdir,markbase ~= 0 and "yes" or "no")
                end
                if cursivex ~= 0 or cursivey ~= 0 then
                    if cursbase then
                        report_injections("%w%s curs: base dx %p, dy %p",margin,symbol,cursivex,cursivey)
                    else
                        report_injections("%w%s curs: dx %p, dy %p",margin,symbol,cursivex,cursivey)
                    end
                elseif cursbase then
                    report_injections("%w%s curs: base",margin,symbol)
                end
                if ligaindex ~= 0 then
                    report_injections("%w%s liga: index %i",margin,symbol,ligaindex)
                end
            end
        end
    end
end

local function showsub(n,what,where)
    report_injections("begin subrun: %s",where)
    for n in nextchar, n do
        showchar(n,where)
        show(n,what,where," ")
    end
    report_injections("end subrun")
end

local function trace(head,where)
    report_injections()
    report_injections("begin run %s: %s kerns, %s positions, %s marks and %s cursives registered",
        where or "",nofregisteredkerns,nofregisteredpositions,nofregisteredmarks,nofregisteredcursives)
    local n = head
    while n do
        local id = getid(n)
        if id == glyph_code then
            showchar(n)
            show(n,"injections",false," ")
            show(n,"preinjections",false,"<")
            show(n,"postinjections",false,">")
            show(n,"replaceinjections",false,"=")
            show(n,"emptyinjections",false,"*")
        elseif id == disc_code then
            local pre, post, replace = getdisc(n)
            if pre then
                showsub(pre,"preinjections","pre")
            end
            if post then
                showsub(post,"postinjections","post")
            end
            if replace then
                showsub(replace,"replaceinjections","replace")
            end
            show(n,"emptyinjections",false,"*")
        end
        n = getnext(n)
    end
    report_injections("end run")
end

local function show_result(head)
    local current  = head
    local skipping = false
    while current do
        local id = getid(current)
        if id == glyph_code then
            local w = getwidth(current)
            local x, y = getoffsets(current)
            report_injections("char: %C, width %p, xoffset %p, yoffset %p",getchar(current),w,x,y)
            skipping = false
        elseif id == kern_code then
            report_injections("kern: %p",getkern(current))
            skipping = false
        elseif not skipping then
            report_injections()
            skipping = true
        end
        current = getnext(current)
    end
    report_injections()
end

-- G  +D-pre        G
--     D-post+
--    +D-replace+
--
-- G  +D-pre       +D-pre
--     D-post      +D-post
--    +D-replace   +D-replace

local function inject_kerns_only(head,where)
    if trace_injections then
        trace(head,"kerns")
    end
    local current     = head
    local prev        = nil
    local next        = nil
    local prevdisc    = nil
 -- local prevglyph   = nil
    local pre         = nil -- saves a lookup
    local post        = nil -- saves a lookup
    local replace     = nil -- saves a lookup
    local pretail     = nil -- saves a lookup
    local posttail    = nil -- saves a lookup
    local replacetail = nil -- saves a lookup
    while current do
        local next = getnext(current)
        local char, id = ischar(current)
        if char then
            local p = rawget(properties,current)
            if p then
                local i = p.injections
                if i then
                    -- left|glyph|right
                    local leftkern = i.leftkern
                    if leftkern and leftkern ~= 0 then
                        if prev and getid(prev) == glue_code then
                            if useitalickerns then
                                head = insertnodebefore(head,current,italickern(leftkern))
                            else
                                setwidth(prev, getwidth(prev) + leftkern)
                            end
                        else
                            head = insertnodebefore(head,current,fontkern(leftkern))
                        end
                    end
                end
                if prevdisc then
                    local done = false
                    if post then
                        local i = p.postinjections
                        if i then
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                setlink(posttail,fontkern(leftkern))
                                done = true
                            end
                        end
                    end
                    if replace then
                        local i = p.replaceinjections
                        if i then
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                setlink(replacetail,fontkern(leftkern))
                                done = true
                            end
                        end
                    else
                        local i = p.emptyinjections
                        if i then
                            -- glyph|disc|glyph (special case)
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                replace = fontkern(leftkern)
                                done    = true
                            end
                        end
                    end
                    if done then
                        setdisc(prevdisc,pre,post,replace)
                    end
                end
            end
            prevdisc  = nil
         -- prevglyph = current
        elseif char == false then
            -- other font
            prevdisc  = nil
         -- prevglyph = current
        elseif id == disc_code then
            pre, post, replace, pretail, posttail, replacetail = getdisc(current,true)
            local done = false
            if pre then
                -- left|pre glyphs|right
                for n in nextchar, pre do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.preinjections
                        if i then
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                pre  = insertnodebefore(pre,n,fontkern(leftkern))
                                done = true
                            end
                        end
                    end
                end
            end
            if post then
                -- left|post glyphs|right
                for n in nextchar, post do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.postinjections
                        if i then
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                post = insertnodebefore(post,n,fontkern(leftkern))
                                done = true
                            end
                        end
                    end
                end
            end
            if replace then
                -- left|replace glyphs|right
                for n in nextchar, replace do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.replaceinjections
                        if i then
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                replace = insertnodebefore(replace,n,fontkern(leftkern))
                                done    = true
                            end
                        end
                    end
                end
            end
            if done then
                setdisc(current,pre,post,replace)
            end
         -- prevglyph = nil
            prevdisc  = current
        else
         -- prevglyph = nil
            prevdisc  = nil
        end
        prev    = current
        current = next
    end
    --
    if keepregisteredcounts then
        keepregisteredcounts = false
    else
        nofregisteredkerns   = 0
    end
    if trace_injections then
        show_result(head)
    end
    return head
end

local function inject_positions_only(head,where)
    if trace_injections then
        trace(head,"positions")
    end
    local current     = head
    local prev        = nil
    local next        = nil
    local prevdisc    = nil
    local prevglyph   = nil
    local pre         = nil -- saves a lookup
    local post        = nil -- saves a lookup
    local replace     = nil -- saves a lookup
    local pretail     = nil -- saves a lookup
    local posttail    = nil -- saves a lookup
    local replacetail = nil -- saves a lookup
    while current do
        local next = getnext(current)
        local char, id = ischar(current)
        if char then
            local p = rawget(properties,current)
            if p then
                local i = p.injections
                if i then
                    -- left|glyph|right
                    local yoffset = i.yoffset
                    if yoffset and yoffset ~= 0 then
                        setoffsets(current,false,yoffset)
                    end
                    local leftkern  = i.leftkern
                    local rightkern = i.rightkern
                    if leftkern and leftkern ~= 0 then
                        if rightkern and leftkern == -rightkern then
                            setoffsets(current,leftkern,false)
                            rightkern = 0
                        elseif prev and getid(prev) == glue_code then
                            if useitalickerns then
                                head = insertnodebefore(head,current,italickern(leftkern))
                            else
                                setwidth(prev, getwidth(prev) + leftkern)
                            end
                        else
                            head = insertnodebefore(head,current,fontkern(leftkern))
                        end
                    end
                    if rightkern and rightkern ~= 0 then
                        if next and getid(next) == glue_code then
                            if useitalickerns then
                                insertnodeafter(head,current,italickern(rightkern))
                            else
                                setwidth(next, getwidth(next) + rightkern)
                            end
                        else
                            insertnodeafter(head,current,fontkern(rightkern))
                        end
                    end
                elseif next then
                    local i = p.emptyinjections
                    if i then
                        -- glyph|disc|glyph (special case)
                        local rightkern = i.rightkern
                        if rightkern and rightkern ~= 0 and getid(next) == disc_code then
                            local replace = getreplace(next)
                            if replace then
                                -- can't happen
                            else
                                setreplace(next,fontkern(rightkern))
                            end
                        end
                    end
                end
                if prevdisc then
                    local done = false
                    if post then
                        local i = p.postinjections
                        if i then
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                setlink(posttail,fontkern(leftkern))
                                done = true
                            end
                        end
                    end
                    if replace then
                        local i = p.replaceinjections
                        if i then
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                setlink(replacetail,fontkern(leftkern))
                                done = true
                            end
                        end
                    else
                        local i = p.emptyinjections
                        if i then
                            -- new .. okay?
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                replace = fontkern(leftkern)
                                done = true
                            end
                        end
                    end
                    if done then
                        setdisc(prevdisc,pre,post,replace)
                    end
                end
            end
            prevdisc  = nil
            prevglyph = current
        elseif char == false then
            prevdisc  = nil
            prevglyph = current
        elseif id == disc_code then
            pre, post, replace, pretail, posttail, replacetail = getdisc(current,true)
            local done = false
            if pre then
                -- left|pre glyphs|right
                for n in nextchar, pre do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.preinjections
                        if i then
                            local yoffset = i.yoffset
                            if yoffset and yoffset ~= 0 then
                                setoffsets(n,false,yoffset)
                            end
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                pre  = insertnodebefore(pre,n,fontkern(leftkern))
                                done = true
                            end
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                insertnodeafter(pre,n,fontkern(rightkern))
                                done = true
                            end
                        end
                    end
                end
            end
            if post then
                -- left|post glyphs|right
                for n in nextchar, post do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.postinjections
                        if i then
                            local yoffset = i.yoffset
                            if yoffset and yoffset ~= 0 then
                                setoffsets(n,false,yoffset)
                            end
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                post = insertnodebefore(post,n,fontkern(leftkern))
                                done = true
                            end
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                insertnodeafter(post,n,fontkern(rightkern))
                                done = true
                            end
                        end
                    end
                end
            end
            if replace then
                -- left|replace glyphs|right
                for n in nextchar, replace do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.replaceinjections
                        if i then
                            local yoffset = i.yoffset
                            if yoffset and yoffset ~= 0 then
                                setoffsets(n,false,yoffset)
                            end
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                replace = insertnodebefore(replace,n,fontkern(leftkern))
                                done    = true
                            end
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                insertnodeafter(replace,n,fontkern(rightkern))
                                done = true
                            end
                        end
                    end
                end
            end
            if prevglyph then
                if pre then
                    local p = rawget(properties,prevglyph)
                    if p then
                        local i = p.preinjections
                        if i then
                            -- glyph|pre glyphs
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                pre  = insertnodebefore(pre,pre,fontkern(rightkern))
                                done = true
                            end
                        end
                    end
                end
                if replace then
                    local p = rawget(properties,prevglyph)
                    if p then
                        local i = p.replaceinjections
                        if i then
                            -- glyph|replace glyphs
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                replace = insertnodebefore(replace,replace,fontkern(rightkern))
                                done    = true
                            end
                        end
                    end
                end
            end
            if done then
                setdisc(current,pre,post,replace)
            end
            prevglyph = nil
            prevdisc  = current
        else
            prevglyph = nil
            prevdisc  = nil
        end
        prev    = current
        current = next
    end
    --
    if keepregisteredcounts then
        keepregisteredcounts = false
    else
        nofregisteredpositions = 0
    end
    if trace_injections then
        show_result(head)
    end
    return head
end

local function showoffset(n,flag)
    local x, y = getoffsets(n)
    if x ~= 0 or y ~= 0 then
        setcolor(n,"darkgray")
    end
end

local function inject_everything(head,where)
    if trace_injections then
        trace(head,"everything")
    end
    local hascursives   = nofregisteredcursives > 0
    local hasmarks      = nofregisteredmarks    > 0
    --
    local current       = head
    local last          = nil
    local prev          = nil
    local next          = nil
    local prevdisc      = nil
    local prevglyph     = nil
    local pre           = nil -- saves a lookup
    local post          = nil -- saves a lookup
    local replace       = nil -- saves a lookup
    local pretail       = nil -- saves a lookup
    local posttail      = nil -- saves a lookup
    local replacetail   = nil -- saves a lookup
    --
    local cursiveanchor = nil
    local minc          = 0
    local maxc          = 0
    local glyphs        = { }
    local marks         = { }
    local nofmarks      = 0
    --
 -- local applyfix      = hascursives and fix_cursive_marks
    --
    -- move out
    --
    local function processmark(p,n,pn) -- p = basenode
        local px, py = getoffsets(p)
        local nx, ny = getoffsets(n)
        local ox = 0
        local rightkern = nil
        local pp = rawget(properties,p)
        if pp then
            pp = pp.injections
            if pp then
                rightkern = pp.rightkern
            end
        end
        local markdir = pn.markdir
        if rightkern then -- x and w ~= 0
            ox = px - (pn.markx or 0) - rightkern
            if markdir and markdir < 0 then
                -- kern(w-x) glyph(p) kern(x) mark(n)
                if not pn.markmark then
                    ox = ox + (pn.leftkern or 0)
                end
            else
                -- kern(x) glyph(p) kern(w-x) mark(n)
                --
                -- According to Kai we don't need to handle leftkern here but I'm
                -- pretty sure I've run into a case where it was needed so maybe
                -- some day we need something more clever here.
                --
                -- maybe we need to apply both then
                --
                if false then
                    -- a mark with kerning (maybe husayni needs it )
                    local leftkern = pp.leftkern
                    if leftkern then
                        ox = ox - leftkern
                    end
                end
            end
        else
            ox = px - (pn.markx or 0)
            if markdir and markdir < 0 then
                if not pn.markmark then
                    local leftkern = pn.leftkern
                    if leftkern then
                        ox = ox + leftkern -- husayni needs it
                    end
                end
            end
            if pn.checkmark then
                local wn = getwidth(n) -- in arial marks have widths
                if wn and wn ~= 0 then
                    wn = wn/2
                    if trace_injections then
                        report_injections("correcting non zero width mark %C",getchar(n))
                    end
                    -- -- bad: we should center
                    --
                    -- pn.leftkern  = -wn
                    -- pn.rightkern = -wn
                    --
                    -- -- we're too late anyway as kerns are already injected so we do it the
                    -- -- ugly way (no checking if the previous is already a kern) .. maybe we
                    -- -- should fix the font instead
                    --
                    -- todo: head and check for prev / next kern
                    --
                    insertnodebefore(n,n,fontkern(-wn))
                    insertnodeafter(n,n,fontkern(-wn))
                end
            end
        end
        local oy = ny + py + (pn.marky or 0)
        if not pn.markmark then
            local yoffset = pn.yoffset
            if yoffset then
                oy = oy + yoffset -- husayni needs it
            end
        end
        setoffsets(n,ox,oy)
        if trace_marks then
            showoffset(n,true)
        end
    end
    -- begin of temp fix --
 -- local base = nil -- bah, some arabic fonts have no mark anchoring
    -- end of temp fix --
    while current do
        local next = getnext(current)
        local char, id = ischar(current)
        if char then
            local p = rawget(properties,current)
            -- begin of temp fix --
         -- if applyfix then
         --     if not p then
         --         local m = fontmarks[getfont(current)]
         --         if m and m[char] then
         --             if base then
         --                 p = { injections = { markbasenode = base } }
         --                 nofmarks = nofmarks + 1
         --                 marks[nofmarks] = current
         --                 properties[current] = p
         --                 hasmarks = true
         --             end
         --         else
         --             base = current
         --         end
         --     end
         -- end
            -- end of temp fix
            if p then
                local i = p.injections
                -- begin of temp fix --
             -- if applyfix then
             --     if not i then
             --         local m = fontmarks[getfont(current)]
             --         if m and m[char] then
             --             if base then
             --                 i = { markbasenode = base }
             --                 nofmarks = nofmarks + 1
             --                 marks[nofmarks] = current
             --                 p.injections = i
             --                 hasmarks = true
             --             end
             --         else
             --             base = current
             --         end
             --     end
             -- end
                -- end of temp fix --
                if i then
                    local pm = i.markbasenode
                    -- begin of temp fix --
                 -- if applyfix then
                 --     if not pm then
                 --         local m = fontmarks[getfont(current)]
                 --         if m and m[char] then
                 --             if base then
                 --                 pm = base
                 --                 i.markbasenode = pm
                 --                 hasmarks = true
                 --             end
                 --         else
                 --             base = current
                 --         end
                 --     else
                 --         base = current
                 --     end
                 -- end
                    -- end of temp fix --
                    if pm then
                        nofmarks = nofmarks + 1
                        marks[nofmarks] = current
                    else
                        local yoffset = i.yoffset
                        if yoffset and yoffset ~= 0 then
                            setoffsets(current,false,yoffset)
                        end
                        if hascursives then
                            local cursivex = i.cursivex
                            if cursivex then
                                if cursiveanchor then
                                    if cursivex ~= 0 then
                                        i.leftkern = (i.leftkern or 0) + cursivex
                                    end
                                    if maxc == 0 then
                                        minc = 1
                                        maxc = 1
                                        glyphs[1] = cursiveanchor
                                    else
                                        maxc = maxc + 1
                                        glyphs[maxc] = cursiveanchor
                                    end
                                    properties[cursiveanchor].cursivedy = i.cursivey -- cursiveprops
                                    last = current
                                else
                                    maxc = 0
                                end
                            elseif maxc > 0 then
                                local nx, ny = getoffsets(current)
                                for i=maxc,minc,-1 do
                                    local ti = glyphs[i]
                                    ny = ny + properties[ti].cursivedy
                                    setoffsets(ti,false,ny) -- why not add ?
                                    if trace_cursive then
                                        showoffset(ti)
                                    end
                                end
                                maxc = 0
                                cursiveanchor = nil
                            end
                            if i.cursiveanchor then
                                cursiveanchor = current -- no need for both now
                            else
                                if maxc > 0 then
                                    local nx, ny = getoffsets(current)
                                    for i=maxc,minc,-1 do
                                        local ti = glyphs[i]
                                        ny = ny + properties[ti].cursivedy
                                        setoffsets(ti,false,ny) -- why not add ?
                                        if trace_cursive then
                                            showoffset(ti)
                                        end
                                    end
                                    maxc = 0
                                end
                                cursiveanchor = nil
                            end
                        end
                        -- left|glyph|right
                        local leftkern  = i.leftkern
                        local rightkern = i.rightkern
                        if leftkern and leftkern ~= 0 then
                            if rightkern and leftkern == -rightkern then
                                setoffsets(current,leftkern,false)
                                rightkern = 0
                            elseif prev and getid(prev) == glue_code then
                                if useitalickerns then
                                    head = insertnodebefore(head,current,italickern(leftkern))
                                else
                                    setwidth(prev, getwidth(prev) + leftkern)
                                end
                            else
                                head = insertnodebefore(head,current,fontkern(leftkern))
                            end
                        end
                        if rightkern and rightkern ~= 0 then
                            if next and getid(next) == glue_code then
                                if useitalickerns then
                                    insertnodeafter(head,current,italickern(rightkern))
                                else
                                    setwidth(next, getwidth(next) + rightkern)
                                end
                            else
                                insertnodeafter(head,current,fontkern(rightkern))
                            end
                        end
                    end
                elseif next then
                    local i = p.emptyinjections
                    if i then
                        -- glyph|disc|glyph (special case)
                        local rightkern = i.rightkern
                        if rightkern and rightkern ~= 0 and getid(next) == disc_code then
                            local replace = getreplace(next)
                            if replace then
                                -- can't happen
                            else
                                setreplace(next,fontkern(rightkern))
                            end
                        end
                    end
                end
                if prevdisc then
                    if p then
                        local done = false
                        if post then
                            local i = p.postinjections
                            if i then
                                local leftkern = i.leftkern
                                if leftkern and leftkern ~= 0 then
                                    setlink(posttail,fontkern(leftkern))
                                    done = true
                                end
                            end
                        end
                        if replace then
                            local i = p.replaceinjections
                            if i then
                                local leftkern = i.leftkern
                                if leftkern and leftkern ~= 0 then
                                    setlink(replacetail,fontkern(leftkern))
                                    done = true
                                end
                            end
                        else
                            local i = p.emptyinjections
                            if i then
                                local leftkern = i.leftkern
                                if leftkern and leftkern ~= 0 then
                                    replace = fontkern(leftkern)
                                    done    = true
                                end
                            end
                        end
                        if done then
                            setdisc(prevdisc,pre,post,replace)
                        end
                    end
                end
            else
                -- cursive
                if hascursives and maxc > 0 then
                    local nx, ny = getoffsets(current)
                    for i=maxc,minc,-1 do
                        local ti = glyphs[i]
                        ny = ny + properties[ti].cursivedy
                        local xi, yi = getoffsets(ti)
                        setoffsets(ti,xi,yi + ny) -- can be mark, we could use properties
                    end
                    maxc = 0
                    cursiveanchor = nil
                end
            end
            prevdisc  = nil
            prevglyph = current
        elseif char == false then
         -- base = nil
            prevdisc  = nil
            prevglyph = current
        elseif id == disc_code then
         -- base = nil
            pre, post, replace, pretail, posttail, replacetail = getdisc(current,true)
            local done = false
            if pre then
                -- left|pre glyphs|right
                for n in nextchar, pre do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.preinjections
                        if i then
                            local yoffset = i.yoffset
                            if yoffset and yoffset ~= 0 then
                                setoffsets(n,false,yoffset)
                            end
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                pre  = insertnodebefore(pre,n,fontkern(leftkern))
                                done = true
                            end
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                insertnodeafter(pre,n,fontkern(rightkern))
                                done = true
                            end
                            if hasmarks then
                                local pm = i.markbasenode
                                if pm then
                                    processmark(pm,n,i)
                                end
                            end
                        end
                    end
                end
            end
            if post then
                -- left|post glyphs|right
                for n in nextchar, post do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.postinjections
                        if i then
                            local yoffset = i.yoffset
                            if yoffset and yoffset ~= 0 then
                                setoffsets(n,false,yoffset)
                            end
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                post = insertnodebefore(post,n,fontkern(leftkern))
                                done = true
                            end
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                insertnodeafter(post,n,fontkern(rightkern))
                                done = true
                            end
                            if hasmarks then
                                local pm = i.markbasenode
                                if pm then
                                    processmark(pm,n,i)
                                end
                            end
                        end
                    end
                end
            end
            if replace then
                -- left|replace glyphs|right
                for n in nextchar, replace do
                    local p = rawget(properties,n)
                    if p then
                        local i = p.injections or p.replaceinjections
                        if i then
                            local yoffset = i.yoffset
                            if yoffset and yoffset ~= 0 then
                                setoffsets(n,false,yoffset)
                            end
                            local leftkern = i.leftkern
                            if leftkern and leftkern ~= 0 then
                                replace = insertnodebefore(replace,n,fontkern(leftkern))
                                done    = true
                            end
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                insertnodeafter(replace,n,fontkern(rightkern))
                                done = true
                            end
                            if hasmarks then
                                local pm = i.markbasenode
                                if pm then
                                    processmark(pm,n,i)
                                end
                            end
                        end
                    end
                end
            end
            if prevglyph then
                if pre then
                    local p = rawget(properties,prevglyph)
                    if p then
                        local i = p.preinjections
                        if i then
                            -- glyph|pre glyphs
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                pre  = insertnodebefore(pre,pre,fontkern(rightkern))
                                done = true
                            end
                        end
                    end
                end
                if replace then
                    local p = rawget(properties,prevglyph)
                    if p then
                        local i = p.replaceinjections
                        if i then
                            -- glyph|replace glyphs
                            local rightkern = i.rightkern
                            if rightkern and rightkern ~= 0 then
                                replace = insertnodebefore(replace,replace,fontkern(rightkern))
                                done    = true
                            end
                        end
                    end
                end
            end
            if done then
                setdisc(current,pre,post,replace)
            end
            prevglyph = nil
            prevdisc  = current
        else
         -- base      = nil
            prevglyph = nil
            prevdisc  = nil
        end
        prev    = current
        current = next
    end
    -- cursive
    if hascursives and maxc > 0 then
        local nx, ny = getoffsets(last)
        for i=maxc,minc,-1 do
            local ti = glyphs[i]
            ny = ny + properties[ti].cursivedy
            setoffsets(ti,false,ny) -- why not add ?
            if trace_cursive then
                showoffset(ti)
            end
        end
    end
    --
    if nofmarks > 0 then
        for i=1,nofmarks do
            local m = marks[i]
            local p = rawget(properties,m)
            local i = p.injections
            local b = i.markbasenode
            processmark(b,m,i)
        end
    elseif hasmarks then
        -- sometyhing bad happened
    end
    --
    if keepregisteredcounts then
        keepregisteredcounts = false
    else
        nofregisteredkerns     = 0
        nofregisteredpositions = 0
        nofregisteredmarks     = 0
        nofregisteredcursives  = 0
    end
    if trace_injections then
        show_result(head)
    end
    return head
end

-- space triggers

local triggers = false

function nodes.injections.setspacekerns(font,sequence)
    if triggers then
        triggers[font] = sequence
    else
        triggers = { [font] = sequence }
    end
end

local getthreshold

if context then

    local threshold  =  1 -- todo: add a few methods for context
    local parameters = fonts.hashes.parameters

    directives.register("otf.threshold", function(v) threshold = tonumber(v) or 1 end)

    getthreshold  = function(font)
        local p = parameters[font]
        local f = p.factor
        local s = p.spacing
        local t = threshold * (s and s.width or p.space or 0) - 2
        return t > 0 and t or 0, f
    end

else

    injections.threshold = 0

    getthreshold  = function(font)
        local p = fontdata[font].parameters
        local f = p.factor
        local s = p.spacing
        local t = injections.threshold * (s and s.width or p.space or 0) - 2
        return t > 0 and t or 0, f
    end

end

injections.getthreshold = getthreshold

function injections.isspace(n,threshold,id)
    if (id or getid(n)) == glue_code then
        local w = getwidth(n)
        if threshold and w > threshold then -- was >=
            return 32
        end
    end
end

-- We have a plugin so that Kai can use the next in plain. Such a plugin is rather application
-- specific.
--
-- local getboth = nodes.direct.getboth
-- local getid   = nodes.direct.getid
-- local getprev = nodes.direct.getprev
-- local getnext = nodes.direct.getnext
--
-- local whatsit_code = nodes.nodecodes.whatsit
-- local glyph_code   = nodes.nodecodes.glyph
--
-- local function getspaceboth(n) -- fragile: what it prev/next has no width field
--     local prev, next = getboth(n)
--     while prev and (getid(prev) == whatsit_code or (getwidth(prev) == 0 and getid(prev) ~= glyph_code)) do
--         prev = getprev(prev)
--     end
--     while next and (getid(next) == whatsit_code or (getwidth(next) == 0 and getid(next) ~= glyph_code)) do
--         next = getnext(next)
--     end
-- end
--
-- injections.installgetspaceboth(getspaceboth)

local getspaceboth = getboth

function injections.installgetspaceboth(gb)
    getspaceboth = gb or getboth
end

local function injectspaces(head)

    if not triggers then
        return head
    end
    local lastfont   = nil
    local spacekerns = nil
    local leftkerns  = nil
    local rightkerns = nil
    local factor     = 0
    local threshold  = 0
    local leftkern   = false
    local rightkern  = false

    local function updatefont(font,trig)
        leftkerns  = trig.left
        rightkerns = trig.right
        lastfont   = font
        threshold,
        factor     = getthreshold(font)
    end

    for n in nextglue, head do
        local prev, next = getspaceboth(n)
        local prevchar = prev and ischar(prev)
        local nextchar = next and ischar(next)
        if nextchar then
            local font = getfont(next)
            local trig = triggers[font]
            if trig then
                if lastfont ~= font then
                    updatefont(font,trig)
                end
                if rightkerns then
                    rightkern = rightkerns[nextchar]
                end
            end
        end
        if prevchar then
            local font = getfont(prev)
            local trig = triggers[font]
            if trig then
                if lastfont ~= font then
                    updatefont(font,trig)
                end
                if leftkerns then
                    leftkern = leftkerns[prevchar]
                end
            end
        end
        if leftkern then
            local old = getwidth(n)
            if old > threshold then
                if rightkern then
                    if useitalickerns then
                        local lnew = leftkern  * factor
                        local rnew = rightkern * factor
                        if trace_spaces then
                            report_spaces("%C [%p + %p + %p] %C",prevchar,lnew,old,rnew,nextchar)
                        end
                        head = insertnodebefore(head,n,italickern(lnew))
                        insertnodeafter(head,n,italickern(rnew))
                    else
                        local new = old + (leftkern + rightkern) * factor
                        if trace_spaces then
                            report_spaces("%C [%p -> %p] %C",prevchar,old,new,nextchar)
                        end
                        setwidth(n,new)
                    end
                    rightkern = false
                else
                    if useitalickerns then
                        local new = leftkern * factor
                        if trace_spaces then
                            report_spaces("%C [%p + %p]",prevchar,old,new)
                        end
                        insertnodeafter(head,n,italickern(new)) -- tricky with traverse but ok
                    else
                        local new = old + leftkern * factor
                        if trace_spaces then
                            report_spaces("%C [%p -> %p]",prevchar,old,new)
                        end
                        setwidth(n,new)
                    end
                end
            end
            leftkern  = false
        elseif rightkern then
            local old = getwidth(n)
            if old > threshold then
                if useitalickerns then
                    local new = rightkern * factor
                    if trace_spaces then
                        report_spaces("[%p + %p] %C",old,new,nextchar)
                    end
                    insertnodeafter(head,n,italickern(new))
                else
                    local new = old + rightkern * factor
                    if trace_spaces then
                        report_spaces("[%p -> %p] %C",old,new,nextchar)
                    end
                    setwidth(n,new)
                end
            else
                -- message
            end
            rightkern = false
        end
    end

    triggers = false

    return head
end

--

function injections.handler(head,where)
    if triggers then
        head = injectspaces(head)
    end
    -- todo: marks only run too
    if nofregisteredmarks > 0 or nofregisteredcursives > 0 then
        if trace_injections then
            report_injections("injection variant %a","everything")
        end
        return inject_everything(head,where)
    elseif nofregisteredpositions > 0 then
        if trace_injections then
            report_injections("injection variant %a","positions")
        end
        return inject_positions_only(head,where)
    elseif nofregisteredkerns > 0 then
        if trace_injections then
            report_injections("injection variant %a","kerns")
        end
        return inject_kerns_only(head,where)
    else
        return head
    end
end

