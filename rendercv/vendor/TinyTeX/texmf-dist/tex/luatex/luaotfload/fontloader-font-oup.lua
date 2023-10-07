if not modules then modules = { } end modules ['font-oup'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local next, type = next, type
local P, R, S = lpeg.P, lpeg.R, lpeg.S
local lpegmatch = lpeg.match
local insert, remove, copy, unpack = table.insert, table.remove, table.copy, table.unpack
local find = string.find

local formatters           = string.formatters
local sortedkeys           = table.sortedkeys
local sortedhash           = table.sortedhash
local tohash               = table.tohash
local setmetatableindex    = table.setmetatableindex

local report_error         = logs.reporter("otf reader","error")
local report_markwidth     = logs.reporter("otf reader","markwidth")
local report_cleanup       = logs.reporter("otf reader","cleanup")
local report_optimizations = logs.reporter("otf reader","merges")
local report_unicodes      = logs.reporter("otf reader","unicodes")

local trace_markwidth      = false  trackers.register("otf.markwidth",     function(v) trace_markwidth     = v end)
local trace_cleanup        = false  trackers.register("otf.cleanups",      function(v) trace_cleanups      = v end)
local trace_optimizations  = false  trackers.register("otf.optimizations", function(v) trace_optimizations = v end)
local trace_unicodes       = false  trackers.register("otf.unicodes",      function(v) trace_unicodes      = v end)

local readers              = fonts.handlers.otf.readers
local privateoffset        = fonts.constructors and fonts.constructors.privateoffset or 0xF0000 -- 0x10FFFF

local f_private            = formatters["P%05X"]
local f_unicode            = formatters["U%05X"]
local f_index              = formatters["I%05X"]
local f_character_y        = formatters["%C"]
local f_character_n        = formatters["[ %C ]"]

local check_duplicates     = true    -- can become an option (pseudo feature) / always needed anyway
local check_soft_hyphen    = context -- only in context

directives.register("otf.checksofthyphen",function(v)
    check_soft_hyphen = v -- only for testing
end)

-- After (!) the unicodes have been resolved we compact ligature tables so before that happens
-- we don't need to check for numbers.

local function replaced(list,index,replacement)
    if type(list) == "number" then
        return replacement
    elseif type(replacement) == "table" then
        local t = { }
        local n = index-1
        for i=1,n do
            t[i] = list[i]
        end
        for i=1,#replacement do
            n = n + 1
            t[n] = replacement[i]
        end
        for i=index+1,#list do
            n = n + 1
            t[n] = list[i]
        end
    else
        list[index] = replacement
        return list
    end
end

local function unifyresources(fontdata,indices)
    local descriptions = fontdata.descriptions
    local resources    = fontdata.resources
    if not descriptions or not resources then
        return
    end
    --
    local nofindices = #indices
    --
    local variants = fontdata.resources.variants
    if variants then
        for selector, unicodes in next, variants do
            for unicode, index in next, unicodes do
                unicodes[unicode] = indices[index]
            end
        end
    end
    --
    local function remark(marks)
        if marks then
            local newmarks = { }
            for k, v in next, marks do
                local u = indices[k]
                if u then
                    newmarks[u] = v
                elseif trace_optimizations then
                    report_optimizations("discarding mark %i",k)
                end
            end
            return newmarks
        end
    end
    --
    local marks = resources.marks
    if marks then
        resources.marks  = remark(marks)
    end
    --
    local markclasses = resources.markclasses
    if markclasses then
        for class, marks in next, markclasses do
            markclasses[class] = remark(marks)
        end
    end
    --
    local marksets = resources.marksets
    if marksets then
        for class, marks in next, marksets do
            marksets[class] = remark(marks)
        end
    end
    --
    local done = { } -- we need to deal with shared !
    --
    local duplicates = check_duplicates and resources.duplicates
    if duplicates and not next(duplicates) then
        duplicates = false
    end
    --
    local function recover(cover) -- can be packed
        for i=1,#cover do
            local c = cover[i]
            if not done[c] then
                local t = { }
                for k, v in next, c do
                    local ug = indices[k]
                    if ug then
                        t[ug] = v
                    else
                        report_error("case %i, bad index in unifying %s: %s of %s",1,"coverage",k,nofindices)
                    end
                end
                cover[i] = t
                done[c]  = d
            end
        end
    end
    --
    local function recursed(c,kind) -- ligs are not packed
        local t = { }
        for g, d in next, c do
            if type(d) == "table" then
                local ug = indices[g]
                if ug then
                    t[ug] = recursed(d,kind)
                else
                    report_error("case %i, bad index in unifying %s: %s of %s",1,kind,g,nofindices)
                end
            else
                t[g] = indices[d] -- ligature
            end
        end
        return t
    end
    --
    -- the duplicates need checking (probably only in cjk fonts): currently we only check
    -- gsub_single, gsub_alternate, gsub_multiple, gpos_single and gpos_cursive
    --
    local function unifythem(sequences)
        if not sequences then
            return
        end
        for i=1,#sequences do
            local sequence  = sequences[i]
            local kind      = sequence.type
            local steps     = sequence.steps
            local features  = sequence.features
            if steps then
                for i=1,#steps do
                    local step = steps[i]
                    if kind == "gsub_single" then
                        local c = step.coverage
                        if c then
                            local t1 = done[c]
                            if not t1 then
                                t1 = { }
                                if duplicates then
                                    for g1, d1 in next, c do
                                        local ug1 = indices[g1]
                                        if ug1 then
                                            local ud1 = indices[d1]
                                            if ud1 then
                                                t1[ug1] = ud1
                                                local dg1 = duplicates[ug1]
                                                if dg1 then
                                                    for u in next, dg1 do
                                                        t1[u] = ud1
                                                    end
                                                end
                                            else
                                                report_error("case %i, bad index in unifying %s: %s of %s",3,kind,d1,nofindices)
                                            end
                                        else
                                            report_error("case %i, bad index in unifying %s: %s of %s",1,kind,g1,nofindices)
                                        end
                                    end
                                else
                                    for g1, d1 in next, c do
                                        local ug1 = indices[g1]
                                        if ug1 then
                                            t1[ug1] = indices[d1]
                                        else
                                            report_error("fuzzy case %i in unifying %s: %i",2,kind,g1)
                                        end
                                    end
                                end
                                done[c] = t1
                            end
                            step.coverage = t1
                        end
                    elseif kind == "gpos_pair" then
                        local c = step.coverage
                        if c then
                            local t1 = done[c]
                            if not t1 then
                                t1 = { }
                                for g1, d1 in next, c do
                                    local ug1 = indices[g1]
                                    if ug1 then
                                        local t2 = done[d1]
                                        if not t2 then
                                            t2 = { }
                                            for g2, d2 in next, d1 do
                                                local ug2 = indices[g2]
                                                if ug2 then
                                                    t2[ug2] = d2
                                                else
                                                    report_error("case %i, bad index in unifying %s: %s of %s",1,kind,g2,nofindices,nofindices)
                                                end
                                            end
                                            done[d1] = t2
                                        end
                                        t1[ug1] = t2
                                    else
                                        report_error("case %i, bad index in unifying %s: %s of %s",2,kind,g1,nofindices)
                                    end
                                end
                                done[c] = t1
                            end
                            step.coverage = t1
                        end
                    elseif kind == "gsub_ligature" then
                        local c = step.coverage
                        if c then
                            step.coverage = recursed(c,kind)
                        end
                    elseif kind == "gsub_alternate" or kind == "gsub_multiple" then
                        local c = step.coverage
                        if c then
                            local t1 = done[c]
                            if not t1 then
                                t1 = { }
                                if duplicates then
                                    for g1, d1 in next, c do
                                        for i=1,#d1 do
                                            local d1i = d1[i]
                                            local d1u = indices[d1i]
                                            if d1u then
                                                d1[i] = d1u
                                            else
                                                report_error("case %i, bad index in unifying %s: %s of %s",1,kind,i,d1i,nofindices)
                                            end
                                        end
                                        local ug1 = indices[g1]
                                        if ug1 then
                                            t1[ug1] = d1
                                            local dg1 = duplicates[ug1]
                                            if dg1 then
                                                for u in next, dg1 do
                                                    t1[u] = copy(d1)
                                                end
                                            end
                                        else
                                            report_error("case %i, bad index in unifying %s: %s of %s",2,kind,g1,nofindices)
                                        end
                                    end
                                else
                                    for g1, d1 in next, c do
                                        for i=1,#d1 do
                                            local d1i = d1[i]
                                            local d1u = indices[d1i]
                                            if d1u then
                                                d1[i] = d1u
                                            else
                                                report_error("case %i, bad index in unifying %s: %s of %s",2,kind,d1i,nofindices)
                                            end
                                        end
                                        t1[indices[g1]] = d1
                                    end
                                end
                                done[c] = t1
                            end
                            step.coverage = t1
                        end
                    elseif kind == "gpos_single" then
                        local c = step.coverage
                        if c then
                            local t1 = done[c]
                            if not t1 then
                                t1 = { }
                                if duplicates then
                                    for g1, d1 in next, c do
                                        local ug1 = indices[g1]
                                        if ug1 then
                                            t1[ug1] = d1
                                            local dg1 = duplicates[ug1]
                                            if dg1 then
                                                for u in next, dg1 do
                                                    t1[u] = d1
                                                end
                                            end
                                        else
                                            report_error("case %i, bad index in unifying %s: %s of %s",1,kind,g1,nofindices)
                                        end
                                    end
                                else
                                    for g1, d1 in next, c do
                                        local ug1 = indices[g1]
                                        if ug1 then
                                            t1[ug1] = d1
                                        else
                                            report_error("case %i, bad index in unifying %s: %s of %s",2,kind,g1,nofindices)
                                        end
                                    end
                                end
                                done[c] = t1
                            end
                            step.coverage = t1
                        end
                    elseif kind == "gpos_mark2base" or kind == "gpos_mark2mark" or kind == "gpos_mark2ligature" then
                        local c = step.coverage
                        if c then
                            local t1 = done[c]
                            if not t1 then
                                t1 = { }
                                for g1, d1 in next, c do
                                    local ug1 = indices[g1]
                                    if ug1 then
                                        t1[ug1] = d1
                                    else
                                        report_error("case %i, bad index in unifying %s: %s of %s",1,kind,g1,nofindices)
                                    end
                                end
                                done[c] = t1
                            end
                            step.coverage = t1
                        end
                        local c = step.baseclasses
                        if c then
                            local t1 = done[c]
                            if not t1 then
                                for g1, d1 in next, c do
                                    local t2 = done[d1]
                                    if not t2 then
                                        t2 = { }
                                        for g2, d2 in next, d1 do
                                            local ug2 = indices[g2]
                                            if ug2 then
                                                t2[ug2] = d2
                                            else
                                                report_error("case %i, bad index in unifying %s: %s of %s",2,kind,g2,nofindices)
                                            end
                                        end
                                        done[d1] = t2
                                    end
                                    c[g1] = t2
                                end
                                done[c] = c
                            end
                        end
                    elseif kind == "gpos_cursive" then
                        local c = step.coverage
                        if c then
                            local t1 = done[c]
                            if not t1 then
                                t1 = { }
                                if duplicates then
                                    for g1, d1 in next, c do
                                        local ug1 = indices[g1]
                                        if ug1 then
                                            t1[ug1] = d1
                                            --
                                            local dg1 = duplicates[ug1]
                                            if dg1 then
                                                -- probably needs a bit more
                                                for u in next, dg1 do
                                                    t1[u] = copy(d1)
                                                end
                                            end
                                        else
                                            report_error("case %i, bad index in unifying %s: %s of %s",1,kind,g1,nofindices)
                                        end
                                    end
                                else
                                    for g1, d1 in next, c do
                                        local ug1 = indices[g1]
                                        if ug1 then
                                            t1[ug1] = d1
                                        else
                                            report_error("case %i, bad index in unifying %s: %s of %s",2,kind,g1,nofindices)
                                        end
                                    end
                                end
                                done[c] = t1
                            end
                            step.coverage = t1
                        end
                    end
                    --
                    local rules = step.rules
                    if rules then
                        for i=1,#rules do
                            local rule = rules[i]
                            --
                            local before   = rule.before   if before  then recover(before)  end
                            local after    = rule.after    if after   then recover(after)   end
                            local current  = rule.current  if current then recover(current) end
                            --
                            local replacements = rule.replacements
                            if replacements then
                                if not done[replacements] then
                                    local r = { }
                                    for k, v in next, replacements do
                                        r[indices[k]] = indices[v]
                                    end
                                    rule.replacements = r
                                    done[replacements] = r
                                end
                            end
                        end
                    end
                end
            end
       end
    end
    --
    unifythem(resources.sequences)
    unifythem(resources.sublookups)
end

local function copyduplicates(fontdata)
    if check_duplicates then
        local descriptions = fontdata.descriptions
        local resources    = fontdata.resources
        local duplicates   = resources.duplicates
        if check_soft_hyphen then
         -- ebgaramond has a zero width empty soft hyphen
         -- antykwatorunska lacks a soft hyphen
         -- lucidaot has a halfwidth soft hyphen

         -- local dh = descriptions[0x2D]
         -- if dh then
         --     descriptions[0xAD] = nil
         --     local d = duplicates[0x2D]
         --     if d then
         --         d[#d+1] = { [0xAD] = true }
         --     else
         --         duplicates[0x2D] = { [0xAD] = true }
         --     end
         -- end

            local dh = descriptions[0x2D]
            if dh then
                local ds = descriptions[0xAD]
                if not ds or ds.width ~= dh.width then
                    descriptions[0xAD] = nil
                    if ds then
                        if trace_unicodes then
                            report_unicodes("patching soft hyphen")
                        end
                    else
                        if trace_unicodes then
                            report_unicodes("adding soft hyphen")
                        end
                    end
                    if not duplicates then
                        duplicates = { }
                        resources.duplicates = duplicates
                    end
                    local d = duplicates[0x2D]
                    if d then
                        d[0xAD] = true
                    else
                        duplicates[0x2D] = { [0xAD] = true }
                    end
                end
            end

        end
        if duplicates then
           for u, d in next, duplicates do
                local du = descriptions[u]
                if du then
                    local t = { f_character_y(u), "@", f_index(du.index), "->" }
                    local n = 0
                    local m = 25
                    for u in next, d do
                        if descriptions[u] then
                            if n < m then
                                t[n+4] = f_character_n(u)
                            end
                        else
                            local c = copy(du)
                            c.unicode = u -- better this way
                            descriptions[u] = c
                            if n < m then
                                t[n+4] = f_character_y(u)
                            end
                        end
                        n = n + 1
                    end
                    if trace_unicodes then
                        if n <= m then
                            report_unicodes("%i : % t",n,t)
                        else
                            report_unicodes("%i : % t ...",n,t)
                        end
                    end
                else
                    -- what a mess
                end
            end
        end
    end
end

local ignore = { -- should we fix them?
    ["notdef"]            = true,
    [".notdef"]           = true,
    ["null"]              = true,
    [".null"]             = true,
    ["nonmarkingreturn"]  = true,
}


local function checklookups(fontdata,missing,nofmissing)
    local descriptions = fontdata.descriptions
    local resources    = fontdata.resources
    if missing and nofmissing and nofmissing <= 0 then
        return
    end
    --
    local singles    = { }
    local alternates = { }
    local ligatures  = { }

    if not missing then
        missing    = { }
        nofmissing = 0
        for u, d in next, descriptions do
            if not d.unicode then
                nofmissing = nofmissing + 1
                missing[u] = true
            end
        end
    end
    local function collectthem(sequences)
        if not sequences then
            return
        end
        for i=1,#sequences do
            local sequence = sequences[i]
            local kind     = sequence.type
            local steps    = sequence.steps
            if steps then
                for i=1,#steps do
                    local step = steps[i]
                    if kind == "gsub_single" then
                        local c = step.coverage
                        if c then
                            singles[#singles+1] = c
                        end
                    elseif kind == "gsub_alternate" then
                        local c = step.coverage
                        if c then
                            alternates[#alternates+1] = c
                        end
                    elseif kind == "gsub_ligature" then
                        local c = step.coverage
                        if c then
                            ligatures[#ligatures+1] = c
                        end
                    end
                end
            end
        end
    end

    collectthem(resources.sequences)
    collectthem(resources.sublookups)

    local loops = 0
    while true do
        loops = loops + 1
        local old = nofmissing
        for i=1,#singles do
            local c = singles[i]
            for g1, g2 in next, c do
                if missing[g1] then
                    local u2 = descriptions[g2].unicode
                    if u2 then
                        missing[g1] = false
                        descriptions[g1].unicode = u2
                        nofmissing = nofmissing - 1
                    end
                end
                if missing[g2] then
                    local u1 = descriptions[g1].unicode
                    if u1 then
                        missing[g2] = false
                        descriptions[g2].unicode = u1
                        nofmissing = nofmissing - 1
                    end
                end
            end
        end
        for i=1,#alternates do
            local c = alternates[i]
            -- maybe first a g1 loop and then a g2
            for g1, d1 in next, c do
                if missing[g1] then
                    for i=1,#d1 do
                        local g2 = d1[i]
                        local u2 = descriptions[g2].unicode
                        if u2 then
                            missing[g1] = false
                            descriptions[g1].unicode = u2
                            nofmissing = nofmissing - 1
                        end
                    end
                end
                if not missing[g1] then
                    for i=1,#d1 do
                        local g2 = d1[i]
                        if missing[g2] then
                            local u1 = descriptions[g1].unicode
                            if u1 then
                                missing[g2] = false
                                descriptions[g2].unicode = u1
                                nofmissing = nofmissing - 1
                            end
                        end
                    end
                end
            end
        end
        if nofmissing <= 0 then
            if trace_unicodes then
                report_unicodes("all missings done in %s loops",loops)
            end
            return
        elseif old == nofmissing then
            break
        end
    end

    local t, n -- no need to insert/remove and allocate many times

    local function recursed(c)
        for g, d in next, c do
            if g ~= "ligature" then
                local u = descriptions[g].unicode
                if u then
                    n = n + 1
                    t[n] = u
                    recursed(d)
                    n = n - 1
                end
            elseif missing[d] then
                local l = { }
                local m = 0
                for i=1,n do
                    local u = t[i]
                    if type(u) == "table" then
                        for i=1,#u do
                            m = m + 1
                            l[m] = u[i]
                        end
                    else
                        m = m + 1
                        l[m] = u
                    end
                end
                missing[d] = false
                descriptions[d].unicode = l
                nofmissing = nofmissing - 1
            end
        end
    end

    if nofmissing > 0 then
        t = { }
        n = 0
        local loops = 0
        while true do
            loops = loops + 1
            local old = nofmissing
            for i=1,#ligatures do
                recursed(ligatures[i])
            end
            if nofmissing <= 0 then
                if trace_unicodes then
                    report_unicodes("all missings done in %s loops",loops)
                end
                return
            elseif old == nofmissing then
                break
            end
        end
        t = nil
        n = 0
    end

    if trace_unicodes and nofmissing > 0 then
        local done = { }
        for i, r in next, missing do
            if r then
                local data = descriptions[i]
                local name = data and data.name or f_index(i)
                if not ignore[name] then
                    done[name] = true
                end
            end
        end
        if next(done) then
            report_unicodes("not unicoded: % t",sortedkeys(done))
        end
    end
end

local firstprivate = fonts.privateoffsets and fonts.privateoffsets.textbase or 0xF0000
local puafirst     = 0xE000
local pualast      = 0xF8FF

local function unifymissing(fontdata)
    if not fonts.mappings then
        require("font-map")
        require("font-agl")
    end
    local unicodes     = { }
    local resources    = fontdata.resources
    resources.unicodes = unicodes
    for unicode, d in next, fontdata.descriptions do
        if unicode < privateoffset then
            if unicode >= puafirst and unicode <= pualast then
                -- report_unicodes("resolving private unicode %U",unicode)
            else
                local name = d.name
                if name then
                    unicodes[name] = unicode
                end
            end
        else
            -- report_unicodes("resolving private unicode %U",unicode)
        end
    end
    fonts.mappings.addtounicode(fontdata,fontdata.filename,checklookups)
    resources.unicodes = nil
end

local function unifyglyphs(fontdata,usenames)
    local private      = fontdata.private or privateoffset
    local glyphs       = fontdata.glyphs
    local indices      = { }
    local descriptions = { }
    local names        = usenames and { }
    local resources    = fontdata.resources
    local zero         = glyphs[0]
    local zerocode     = zero.unicode
    local nofglyphs    = #glyphs
    if not zerocode then
        zerocode       = private
        zero.unicode   = zerocode
        private        = private + 1
    end
    descriptions[zerocode] = zero
    if names then
        local name  = glyphs[0].name or f_private(zerocode)
        indices[0]  = name
        names[name] = zerocode
    else
        indices[0] = zerocode
    end
    --
    if names then
        -- seldom uses, we don't issue message ... this branch might even go away
        for index=1,nofglyphs do
            local glyph   = glyphs[index]
            local unicode = glyph.unicode -- this is the primary one
            if not unicode then
                unicode        = private
                local name     = glyph.name or f_private(unicode)
                indices[index] = name
                names[name]    = unicode
                private        = private + 1
            elseif unicode >= firstprivate then
                unicode        = private
                local name     = glyph.name or f_private(unicode)
                indices[index] = name
                names[name]    = unicode
                private        = private + 1
            elseif unicode >= puafirst and unicode <= pualast then
                local name     = glyph.name or f_private(unicode)
                indices[index] = name
                names[name]    = unicode
            elseif descriptions[unicode] then
                unicode        = private
                local name     = glyph.name or f_private(unicode)
                indices[index] = name
                names[name]    = unicode
                private        = private + 1
            else
                local name     = glyph.name or f_unicode(unicode)
                indices[index] = name
                names[name]    = unicode
            end
            descriptions[unicode] = glyph
        end
    elseif trace_unicodes then
        for index=1,nofglyphs do
            local glyph   = glyphs[index]
            local unicode = glyph.unicode -- this is the primary one
            if not unicode then
                unicode        = private
                indices[index] = unicode
                private        = private + 1
            elseif unicode >= firstprivate then
                local name = glyph.name
                if name then
                    report_unicodes("moving glyph %a indexed %05X from private %U to %U ",name,index,unicode,private)
                else
                    report_unicodes("moving glyph indexed %05X from private %U to %U ",index,unicode,private)
                end
                unicode        = private
                indices[index] = unicode
                private        = private + 1
            elseif unicode >= puafirst and unicode <= pualast then
                local name = glyph.name
                if name then
                    report_unicodes("keeping private unicode %U for glyph %a indexed %05X",unicode,name,index)
                else
                    report_unicodes("keeping private unicode %U for glyph indexed %05X",unicode,index)
                end
                indices[index] = unicode
            elseif descriptions[unicode] then
                local name = glyph.name
                if name then
                    report_unicodes("assigning duplicate unicode %U to %U for glyph %a indexed %05X ",unicode,private,name,index)
                else
                    report_unicodes("assigning duplicate unicode %U to %U for glyph indexed %05X ",unicode,private,index)
                end
                unicode        = private
                indices[index] = unicode
                private        = private + 1
            else
                indices[index] = unicode
            end
            descriptions[unicode] = glyph
        end
    else
        for index=1,nofglyphs do
            local glyph   = glyphs[index]
            local unicode = glyph.unicode -- this is the primary one
            if not unicode then
                unicode        = private
                indices[index] = unicode
                private        = private + 1
            elseif unicode >= firstprivate then
                local name = glyph.name
                unicode        = private
                indices[index] = unicode
                private        = private + 1
            elseif unicode >= puafirst and unicode <= pualast then
                local name = glyph.name
                indices[index] = unicode
            elseif descriptions[unicode] then
                local name = glyph.name
                unicode        = private
                indices[index] = unicode
                private        = private + 1
            else
                indices[index] = unicode
            end
            descriptions[unicode] = glyph
        end
    end
    --
    if LUATEXENGINE == "luametatex" then
        for index=1,nofglyphs do
            local math = glyphs[index].math
            if math then
                local list = math.parts
                if list then
                    for i=1,#list do local l = list[i] l.glyph = indices[l.glyph] end
                end
                local list = math.variants
                if list then
                    for i=1,#list do list[i] = indices[list[i]] end
                end
            end
        end
    else
        for index=1,nofglyphs do
            local math = glyphs[index].math
            if math then
                local list = math.vparts
                if list then
                    for i=1,#list do local l = list[i] l.glyph = indices[l.glyph] end
                end
                local list = math.hparts
                if list then
                    for i=1,#list do local l = list[i] l.glyph = indices[l.glyph] end
                end
                local list = math.vvariants
                if list then
                 -- for i=1,#list do local l = list[i] l.glyph = indices[l.glyph] end
                    for i=1,#list do list[i] = indices[list[i]] end
                end
                local list = math.hvariants
                if list then
                 -- for i=1,#list do local l = list[i] l.glyph = indices[l.glyph] end
                    for i=1,#list do list[i] = indices[list[i]] end
                end
            end
        end
    end
    --
    local colorpalettes = resources.colorpalettes
    if colorpalettes then
        for index=1,nofglyphs do
            local colors = glyphs[index].colors
            if colors then
                for i=1,#colors do
                    local c = colors[i]
                    if c then -- safeguard
                        c.slot = indices[c.slot]
                    end
                end
            end
        end
    end
    --
    fontdata.private      = private
    fontdata.glyphs       = nil
    fontdata.names        = names
    fontdata.descriptions = descriptions
    fontdata.hashmethod   = hashmethod
    fontdata.nofglyphs    = nofglyphs
    --
    return indices, names
end

local stripredundant  do

    local p_hex   = R("af","AF","09")
    local p_digit = R("09")
    local p_done  = S("._-")^0 + P(-1)
 -- local p_style = P(".ss") * p_digit * p_digit * P(-1)
    local p_style = P(".")
    local p_alpha = R("az","AZ")
    local p_ALPHA = R("AZ")

    local p_crappyname = (
    -- (P("uni") + P("UNI") + P("Uni") + P("U") + P("u"))
        lpeg.utfchartabletopattern({ "uni", "u" },true)
      * S("Xx_")^0
      * p_hex^1
   -- + (P("identity") + P("Identity") + P("IDENTITY") + P("glyph") + P("jamo"))
      + lpeg.utfchartabletopattern({ "identity", "glyph", "jamo" },true)
      * p_hex^1
   -- + (P("index") + P("Index") + P("INDEX")+ P("afii"))
      + lpeg.utfchartabletopattern({ "index", "afii" }, true)
      * p_digit^1
      -- also happens l
      + p_digit
      * p_hex^3
      + p_alpha
      * p_digit^1
      -- sort of special
      + P("aj")
      * p_digit^1
      + P("eh_")
      * (p_digit^1 + p_ALPHA * p_digit^1)
      + (1-P("_"))^1
      * P("_uni")
      * p_hex^1
      + P("_")
      * P(1)^1
    ) * p_done

    -- In context we only keep glyph names because of tracing and access by name
    -- so weird names make no sense.

    if context then

        local forcekeep = false -- only for testing something
--         local forcekeep = true

        directives.register("otf.keepnames",function(v)
            report_cleanup("keeping weird glyph names, expect larger files and more memory usage")
            forcekeep = v
        end)

     -- local p_lesscrappyname =
     --     lpeg.utfchartabletopattern({ "uni", "u" },true)
     --   * S("Xx")^0
     --   * p_hex^1
     --   * p_style

        local function stripvariants(descriptions,list)
            local n = list and #list or 0
            if n > 0 then
                for i=1,n do
                    local g = list[i]
                    if g then
                        local d = descriptions[g]
                        if d and d.name then
                            d.name = nil
                            n = n + 1
                        end
                    end
                end
            end
            return n
        end

        local function stripparts(descriptions,list)
            local n = list and #list or 0
            if n > 0 then
                for i=1,n do
                    local g = list[i].glyph
                    if g then
                        local d = descriptions[g]
                        if d and d.name then
                            d.name = nil
                            n = n + 1
                        end
                    end
                end
            end
            return n
        end

     -- local function collectsimple(fontdata)
     --     local resources = fontdata.resources
     --     local sequences = resources and resources.sequences
     --     if sequences then
     --         local keeplist = { }
     --         for i=1,#sequences do
     --             local s = sequences[i]
     --             if s.type == "gsub_single" then
     --                 -- only simple ones
     --                 local features = s.features
     --                 local steps    = s.steps
     --                 if features and steps then
     --                     local okay = false
     --                     for k, v in next, features do
     --                         if find(k,"^ss%d%d") then
     --                             okay = true
     --                             break
     --                         end
     --                     end
     --                     if okay then
     --                         for i=1,#steps do
     --                             local coverage = steps[i].coverage
     --                             if coverage then
     --                                 for k, v in next, coverage do
     --                                     keeplist[k] = v
     --                                 end
     --                             end
     --                         end
     --                     end
     --                 end
     --             end
     --         end
     --         return next(keeplist) and keeplist or nil
     --     end
     -- end

        local function collectsimple(fontdata)
            return nil
        end

        stripredundant = function(fontdata)
            local descriptions = fontdata.descriptions
            if descriptions then
                local n = 0
                local c = 0
                for unicode, d in next, descriptions do
                    local m = d.math
                    if m then
                        n = n + stripvariants(descriptions,m.vvariants)
                        n = n + stripvariants(descriptions,m.hvariants)
                        n = n + stripparts   (descriptions,m.vparts)
                        n = n + stripparts   (descriptions,m.hparts)
                    end
                end
                if forcekeep then
                    for unicode, d in next, descriptions do
                        if d.class == "base" then
                            d.class = nil
                            c = c + 1
                        end
                    end
                else
                    local keeplist = collectsimple(fontdata)
                    for unicode, d in next, descriptions do
                        local name = d.name
                        if name then
                         -- if lpegmatch(p_lesscrappyname,name) then
                            if keeplist and keeplist[name] then
                                -- keep name
                            elseif lpegmatch(p_crappyname,name) then
                                d.name = nil
                                n = n + 1
                            end
                        end
                        if d.class == "base" then
                            d.class = nil
                            c = c + 1
                        end
                    end
                end
                if trace_cleanup then
                    if n > 0 then
                        report_cleanup("%s bogus names removed (verbose unicode)",n)
                    end
                    if c > 0 then
                        report_cleanup("%s base class tags removed (default is base)",c)
                    end
                end
            end
        end

    else

        stripredundant = function(fontdata)
            local descriptions = fontdata.descriptions
            if descriptions then
                if fonts.privateoffsets.keepnames then
                    for unicode, d in next, descriptions do
                        if d.class == "base" then
                            d.class = nil
                        end
                    end
                else
                    for unicode, d in next, descriptions do
                        local name = d.name
                        if name then
                            if lpegmatch(p_crappyname,name) then
                                d.name = nil
                            end
                        end
                        if d.class == "base" then
                            d.class = nil
                        end
                    end
                end
            end
        end

    end

    readers.stripredundant = stripredundant

end

function readers.getcomponents(fontdata) -- handy for resolving ligatures when names are missing
    local resources = fontdata.resources
    if resources then
        local sequences = resources.sequences
        if sequences then
            local collected = { }
            for i=1,#sequences do
                local sequence = sequences[i]
                if sequence.type == "gsub_ligature" then
                    local steps  = sequence.steps
                    if steps then
                        local l = { }
                        local function traverse(p,k,v)
                            if k == "ligature" then
                                collected[v] = { unpack(l) }
                            elseif tonumber(v) then
                                insert(l,k)
                                collected[v] = { unpack(l) }
                                remove(l)
                            else
                                insert(l,k)
                                for k, vv in next, v do
                                    traverse(p,k,vv)
                                end
                                remove(l)
                            end
                        end
                        for i=1,#steps do
                         -- we actually had/have this in base mode
                            local c = steps[i].coverage
                            if c then
                                for k, v in next, c do
                                    traverse(k,k,v)
                                end
                            end
                        end
                    end
                end
            end
            if next(collected) then
                -- remove self referring
             -- for k, v in next, collected do
             --     for i=1,#v do
             --         local vi = v[i]
             --         if vi == k then
             --          -- report("removing self referring ligature @ slot %5X from collected (1)",k)
             --             collected[k] = nil
             --         end
             --     end
             -- end
                while true do
                    local done = false
                    for k, v in next, collected do
                        for i=1,#v do
                            local vi = v[i]
                            if vi == k then
                             -- report("removing self referring ligature @ slot %5X from collected (2)",k)
                                collected[k] = nil
                                break
                            else
                                local c = collected[vi]
                                if c then
                                    done = true
                                    local t = { }
                                    local n = i - 1
                                    for j=1,n do
                                        t[j] = v[j]
                                    end
                                    for j=1,#c do
                                        n = n + 1
                                        t[n] = c[j]
                                    end
                                    for j=i+1,#v do
                                        n = n + 1
                                        t[n] = v[j]
                                    end
                                    collected[k] = t
                                    break
                                end
                            end
                        end
                    end
                    if not done then
                        break
                    end
                end
                return collected
            end
        end
    end
end

readers.unifymissing = unifymissing

function readers.rehash(fontdata,hashmethod) -- TODO: combine loops in one
    if not (fontdata and fontdata.glyphs) then
        return
    elseif hashmethod == "indices" then
        fontdata.hashmethod = "indices"
    elseif hashmethod == "names" then
        fontdata.hashmethod = "names"
        local indices = unifyglyphs(fontdata,true)
        unifyresources(fontdata,indices)
        copyduplicates(fontdata)
        unifymissing(fontdata)
    else
        fontdata.hashmethod = "unicodes"
        local indices = unifyglyphs(fontdata)
        unifyresources(fontdata,indices)
        copyduplicates(fontdata)
        unifymissing(fontdata)
        stripredundant(fontdata)
    end
    -- maybe here components
end

function readers.checkhash(fontdata)
    local hashmethod = fontdata.hashmethod
    if hashmethod == "unicodes" then
        fontdata.names = nil -- just to be sure
    elseif hashmethod == "names" and fontdata.names then
        unifyresources(fontdata,fontdata.names)
        copyduplicates(fontdata)
        fontdata.hashmethod = "unicodes"
        fontdata.names = nil -- no need for it
    else
        readers.rehash(fontdata,"unicodes")
    end
end

function readers.addunicodetable(fontdata)
    local resources = fontdata.resources
    local unicodes  = resources.unicodes
    if not unicodes then
        local descriptions = fontdata.descriptions
        if descriptions then
            unicodes = { }
            resources.unicodes = unicodes
            for u, d in next, descriptions do
                local n = d.name
                if n then
                    unicodes[n] = u
                end
            end
        end
    end
end

-- for the moment here:

local concat, sort = table.concat, table.sort
local next, type, tostring = next, type, tostring

local criterium     = 1
local threshold     = 0

local trace_packing = false  trackers.register("otf.packing", function(v) trace_packing = v end)
local trace_loading = false  trackers.register("otf.loading", function(v) trace_loading = v end)

local report_otf    = logs.reporter("fonts","otf loading")

local function tabstr_normal(t)
    local s = { }
    local n = 0
    for k, v in next, t do
        n = n + 1
        if type(v) == "table" then
            s[n] = k .. ">" .. tabstr_normal(v)
        elseif v == true then
            s[n] = k .. "+" -- "=true"
        elseif v then
            s[n] = k .. "=" .. v
        else
            s[n] = k .. "-" -- "=false"
        end
    end
    if n == 0 then
        return ""
    elseif n == 1 then
        return s[1]
    else
        sort(s) -- costly but needed (occasional wrong hit otherwise)
        return concat(s,",")
    end
end

local function tabstr_flat(t)
    local s = { }
    local n = 0
    for k, v in next, t do
        n = n + 1
        s[n] = k .. "=" .. v
    end
    if n == 0 then
        return ""
    elseif n == 1 then
        return s[1]
    else
        sort(s) -- costly but needed (occasional wrong hit otherwise)
        return concat(s,",")
    end
end

local function tabstr_mixed(t) -- indexed
    local n = #t
    if n == 0 then
        return ""
    elseif n == 1 then
        local k = t[1]
        if k == true then
            return "++" -- we need to distinguish from "true"
        elseif k == false then
            return "--" -- we need to distinguish from "false"
        else
            return tostring(k) -- number or string
        end
    else
        local s = { }
        for i=1,n do
            local k = t[i]
            if k == true then
                s[i] = "++" -- we need to distinguish from "true"
            elseif k == false then
                s[i] = "--" -- we need to distinguish from "false"
            else
                s[i] = k -- number or string
            end
        end
        return concat(s,",")
    end
end

local function tabstr_boolean(t)
    local s = { }
    local n = 0
    for k, v in next, t do
        n = n + 1
        if v then
            s[n] = k .. "+"
        else
            s[n] = k .. "-"
        end
    end
    if n == 0 then
        return ""
    elseif n == 1 then
        return s[1]
    else
        sort(s) -- costly but needed (occasional wrong hit otherwise)
        return concat(s,",")
    end
end

-- beware: we cannot unpack and repack the same table because then sharing
-- interferes (we could catch this if needed) .. so for now: save, reload
-- and repack in such cases (never needed anyway) .. a tricky aspect is that
-- we then need to sort more thanks to random hashing

function readers.pack(data)

    if data then

        local h, t, c = { }, { }, { }
        local hh, tt, cc = { }, { }, { }
        local nt, ntt = 0, 0

        local function pack_normal(v)
            local tag = tabstr_normal(v)
            local ht = h[tag]
            if ht then
                c[ht] = c[ht] + 1
                return ht
            else
                nt = nt + 1
                t[nt] = v
                h[tag] = nt
                c[nt] = 1
                return nt
            end
        end

        local function pack_normal_cc(v)
            local tag = tabstr_normal(v)
            local ht = h[tag]
            if ht then
                c[ht] = c[ht] + 1
                return ht
            else
                v[1] = 0
                nt = nt + 1
                t[nt] = v
                h[tag] = nt
                c[nt] = 1
                return nt
            end
        end

        local function pack_flat(v)
            local tag = tabstr_flat(v)
            local ht = h[tag]
            if ht then
                c[ht] = c[ht] + 1
                return ht
            else
                nt = nt + 1
                t[nt] = v
                h[tag] = nt
                c[nt] = 1
                return nt
            end
        end

        local function pack_indexed(v)
            local tag = concat(v," ")
            local ht = h[tag]
            if ht then
                c[ht] = c[ht] + 1
                return ht
            else
                nt = nt + 1
                t[nt] = v
                h[tag] = nt
                c[nt] = 1
                return nt
            end
        end

     -- local function pack_indexed(v) -- less code
     --     local tag = concat(v," ")
     --     local ht = h[tag]
     --     if ht then
     --         c[ht] = c[ht] + 1
     --     else
     --         ht = nt + 1
     --         t[ht] = v
     --         c[ht] = 1
     --         h[tag] = ht
     --         nt = ht
     --     end
     --     return ht
     -- end

        local function pack_mixed(v)
            local tag = tabstr_mixed(v)
            local ht = h[tag]
            if ht then
                c[ht] = c[ht] + 1
                return ht
            else
                nt = nt + 1
                t[nt] = v
                h[tag] = nt
                c[nt] = 1
                return nt
            end
        end

        -- saves a lot on noto sans

        -- can be made more clever

        local function pack_boolean(v)
            local tag = tabstr_boolean(v)
            local ht = h[tag]
            if ht then
                c[ht] = c[ht] + 1
                return ht
            else
                nt = nt + 1
                t[nt] = v
                h[tag] = nt
                c[nt] = 1
                return nt
            end
        end

        local function pack_final(v)
            -- v == number
            if c[v] <= criterium then
                return t[v]
            else
                -- compact hash
                local hv = hh[v]
                if hv then
                    return hv
                else
                    ntt = ntt + 1
                    tt[ntt] = t[v]
                    hh[v] = ntt
                    cc[ntt] = c[v]
                    return ntt
                end
            end
        end

        local function pack_final_cc(v)
            -- v == number
            if c[v] <= criterium then
                return t[v]
            else
                -- compact hash
                local hv = hh[v]
                if hv then
                    return hv
                else
                    ntt = ntt + 1
                    tt[ntt] = t[v]
                    hh[v] = ntt
                    cc[ntt] = c[v]
                    return ntt
                end
            end
        end

        local function success(stage,pass)
            if nt == 0 then
                if trace_loading or trace_packing then
                    report_otf("pack quality: nothing to pack")
                end
                return false
            elseif nt >= threshold then
                local one  = 0
                local two  = 0
                local rest = 0
                if pass == 1 then
                    for k,v in next, c do
                        if v == 1 then
                            one = one + 1
                        elseif v == 2 then
                            two = two + 1
                        else
                            rest = rest + 1
                        end
                    end
                else
                    for k,v in next, cc do
                        if v > 20 then
                            rest = rest + 1
                        elseif v > 10 then
                            two = two + 1
                        else
                            one = one + 1
                        end
                    end
                    data.tables = tt
                end
                if trace_loading or trace_packing then
                    report_otf("pack quality: stage %s, pass %s, %s packed, 1-10:%s, 11-20:%s, rest:%s (criterium: %s)",
                        stage, pass, one+two+rest, one, two, rest, criterium)
                end
                return true
            else
                if trace_loading or trace_packing then
                    report_otf("pack quality: stage %s, pass %s, %s packed, aborting pack (threshold: %s)",
                        stage, pass, nt, threshold)
                end
                return false
            end
        end

        local function packers(pass)
            if pass == 1 then
                return pack_normal, pack_indexed, pack_flat, pack_boolean, pack_mixed, pack_normal_cc
            else
                return pack_final, pack_final, pack_final, pack_final, pack_final, pack_final_cc
            end
        end

        local resources  = data.resources
        local sequences  = resources.sequences
        local sublookups = resources.sublookups
        local features   = resources.features
        local palettes   = resources.colorpalettes
        local variable   = resources.variabledata

        local chardata     = characters and characters.data
        local descriptions = data.descriptions or data.glyphs

        if not descriptions then
            return
        end

        for pass=1,2 do

            if trace_packing then
                report_otf("start packing: stage 1, pass %s",pass)
            end

            local pack_normal, pack_indexed, pack_flat, pack_boolean, pack_mixed, pack_normal_cc = packers(pass)

            for unicode, description in next, descriptions do
                local boundingbox = description.boundingbox
                if boundingbox then
                    description.boundingbox = pack_indexed(boundingbox)
                end
                local math = description.math
                if math then
                    local kerns = math.kerns
                    if kerns then
                        for tag, kern in next, kerns do
                            kerns[tag] = pack_normal(kern)
                        end
                    end
                end
             -- if palettes then
             --     local color = description.color
             --     if color then
             --         for i=1,#color do
             --             color[i] = pack_normal(color[i])
             --         end
             --     end
             -- end
            end

            local function packthem(sequences)
                for i=1,#sequences do
                    local sequence = sequences[i]
                    local kind     = sequence.type
                    local steps    = sequence.steps
                    local order    = sequence.order
                    local features = sequence.features
                    local flags    = sequence.flags
                    if steps then
                        for i=1,#steps do
                            local step = steps[i]
                            if kind == "gpos_pair" then
                                local c = step.coverage
                                if c then
                                    if step.format ~= "pair" then
                                        for g1, d1 in next, c do
                                            c[g1] = pack_normal(d1)
                                        end
                                    elseif step.shared then
                                        -- This branch results from classes. We already share at the reader end. Maybe
                                        -- the sharing should be moved there altogether but it becomes kind of messy
                                        -- then. Here we're still wasting time because in the second pass we serialize
                                        -- and hash. So we compromise. We could merge the two passes ...
                                        local shared = { }
                                        for g1, d1 in next, c do
                                            for g2, d2 in next, d1 do
                                                if not shared[d2] then
                                                    local f = d2[1] if f and f ~= true then d2[1] = pack_indexed(f) end
                                                    local s = d2[2] if s and s ~= true then d2[2] = pack_indexed(s) end
                                                    shared[d2] = true
                                                end
                                            end
                                        end
                                        if pass == 2 then
                                            step.shared = nil -- weird, so dups
                                        end
                                    else
                                        for g1, d1 in next, c do
                                            for g2, d2 in next, d1 do
                                                local f = d2[1] if f and f ~= true then d2[1] = pack_indexed(f) end
                                                local s = d2[2] if s and s ~= true then d2[2] = pack_indexed(s) end
                                            end
                                        end
                                    end
                                end
                            elseif kind == "gpos_single" then
                                local c = step.coverage
                                if c then
                                    if step.format == "single" then
                                        for g1, d1 in next, c do
                                            if d1 and d1 ~= true then
                                                c[g1] = pack_indexed(d1)
                                            end
                                        end
                                    else
                                        step.coverage = pack_normal(c)
                                    end
                                end
                            elseif kind == "gpos_cursive" then
                                local c = step.coverage
                                if c then
                                    for g1, d1 in next, c do
                                        local f = d1[2] if f then d1[2] = pack_indexed(f) end
                                        local s = d1[3] if s then d1[3] = pack_indexed(s) end
                                    end
                                end
                            elseif kind == "gpos_mark2base" or kind == "gpos_mark2mark" then
                                local c = step.baseclasses
                                if c then
                                    for g1, d1 in next, c do
                                        for g2, d2 in next, d1 do
                                            d1[g2] = pack_indexed(d2)
                                        end
                                    end
                                end
                                local c = step.coverage
                                if c then
                                    for g1, d1 in next, c do
                                        d1[2] = pack_indexed(d1[2])
                                    end
                                end
                            elseif kind == "gpos_mark2ligature" then
                                local c = step.baseclasses
                                if c then
                                    for g1, d1 in next, c do
                                        for g2, d2 in next, d1 do
                                            for g3, d3 in next, d2 do
                                                d2[g3] = pack_indexed(d3)
                                            end
                                        end
                                    end
                                end
                                local c = step.coverage
                                if c then
                                    for g1, d1 in next, c do
                                        d1[2] = pack_indexed(d1[2])
                                    end
                                end
                            end
                            -- if ... chain ...
                            local rules = step.rules
                            if rules then
                                for i=1,#rules do
                                    local rule = rules[i]
                                    local r = rule.before       if r then for i=1,#r do r[i] = pack_boolean(r[i]) end end
                                    local r = rule.after        if r then for i=1,#r do r[i] = pack_boolean(r[i]) end end
                                    local r = rule.current      if r then for i=1,#r do r[i] = pack_boolean(r[i]) end end
                                 -- local r = rule.lookups      if r then rule.lookups       = pack_mixed  (r)    end
                                    local r = rule.replacements if r then rule.replacements  = pack_flat   (r)    end
                                end
                            end
                        end
                    end
                    if order then
                        sequence.order = pack_indexed(order)
                    end
                    if features then
                        for script, feature in next, features do
                            features[script] = pack_normal(feature)
                        end
                    end
                    if flags then
                        sequence.flags = pack_normal(flags)
                    end
               end
            end

            if sequences then
                packthem(sequences)
            end

            if sublookups then
                packthem(sublookups)
            end

            if features then
                for k, list in next, features do
                    for feature, spec in next, list do
                        list[feature] = pack_normal(spec)
                    end
                end
            end

            if palettes then
                for i=1,#palettes do
                    local p = palettes[i]
                    for j=1,#p do
                        p[j] = pack_indexed(p[j])
                    end
                end

            end

            if variable then

                -- todo: segments

                local instances = variable.instances
                if instances then
                    for i=1,#instances do
                        local v = instances[i].values
                        for j=1,#v do
                            v[j] = pack_normal(v[j])
                        end
                    end
                end

                local function packdeltas(main)
                    if main then
                        local deltas = main.deltas
                        if deltas then
                            for i=1,#deltas do
                                local di = deltas[i]
                                local d  = di.deltas
                             -- local r  = di.regions
                                for j=1,#d do
                                    d[j] = pack_indexed(d[j])
                                end
                                di.regions = pack_indexed(di.regions)
                            end
                        end
                        local regions = main.regions
                        if regions then
                            for i=1,#regions do
                                local r = regions[i]
                                for j=1,#r do
                                    r[j] = pack_normal(r[j])
                                end
                            end
                        end
                    end
                end

                packdeltas(variable.global)
                packdeltas(variable.horizontal)
                packdeltas(variable.vertical)
                packdeltas(variable.metrics)

            end

            if not success(1,pass) then
                return
            end

        end

        if nt > 0 then

            for pass=1,2 do

                if trace_packing then
                    report_otf("start packing: stage 2, pass %s",pass)
                end

                local pack_normal, pack_indexed, pack_flat, pack_boolean, pack_mixed, pack_normal_cc = packers(pass)

                for unicode, description in next, descriptions do
                    local math = description.math
                    if math then
                        local kerns = math.kerns
                        if kerns then
                            math.kerns = pack_normal(kerns)
                        end
                    end
                end

                local function packthem(sequences)
                    for i=1,#sequences do
                        local sequence = sequences[i]
                        local kind     = sequence.type
                        local steps    = sequence.steps
                        local features = sequence.features
                        if steps then
                            for i=1,#steps do
                                local step = steps[i]
                                if kind == "gpos_pair" then
                                    local c = step.coverage
                                    if c then
                                        if step.format == "pair" then
                                            for g1, d1 in next, c do
                                                for g2, d2 in next, d1 do
                                                    d1[g2] = pack_normal(d2)
                                                end
                                            end
                                        end
                                    end
                             -- elseif kind == "gpos_cursive" then
                             --     local c = step.coverage -- new
                             --     if c then
                             --         for g1, d1 in next, c do
                             --             c[g1] = pack_normal_cc(d1)
                             --         end
                             --     end
                                elseif kind == "gpos_mark2ligature" then
                                    local c = step.baseclasses -- new
                                    if c then
                                        for g1, d1 in next, c do
                                            for g2, d2 in next, d1 do
                                                d1[g2] = pack_normal(d2)
                                            end
                                        end
                                    end
                                end
                                local rules = step.rules
                                if rules then
                                    for i=1,#rules do
                                        local rule = rules[i]
                                        local r = rule.before  if r then rule.before  = pack_normal(r) end
                                        local r = rule.after   if r then rule.after   = pack_normal(r) end
                                        local r = rule.current if r then rule.current = pack_normal(r) end
                                    end
                                end
                            end
                        end
                        if features then
                            sequence.features = pack_normal(features)
                        end
                   end
                end
                if sequences then
                    packthem(sequences)
                end
                if sublookups then
                    packthem(sublookups)
                end
                if variable then
                    local function unpackdeltas(main)
                        if main then
                            local regions = main.regions
                            if regions then
                                main.regions = pack_normal(regions)
                            end
                        end
                    end
                    unpackdeltas(variable.global)
                    unpackdeltas(variable.horizontal)
                    unpackdeltas(variable.vertical)
                    unpackdeltas(variable.metrics)
                end
             -- if not success(2,pass) then
             --  -- return
             -- end
            end

            for pass=1,2 do
                if trace_packing then
                    report_otf("start packing: stage 3, pass %s",pass)
                end

                local pack_normal, pack_indexed, pack_flat, pack_boolean, pack_mixed, pack_normal_cc = packers(pass)

                local function packthem(sequences)
                    for i=1,#sequences do
                        local sequence = sequences[i]
                        local kind     = sequence.type
                        local steps    = sequence.steps
                        local features = sequence.features
                        if steps then
                            for i=1,#steps do
                                local step = steps[i]
                                if kind == "gpos_pair" then
                                    local c = step.coverage
                                    if c then
                                        if step.format == "pair" then
                                            for g1, d1 in next, c do
                                                c[g1] = pack_normal(d1)
                                            end
                                        end
                                    end
                                elseif kind == "gpos_cursive" then
                                    local c = step.coverage
                                    if c then
                                        for g1, d1 in next, c do
                                            c[g1] = pack_normal_cc(d1)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                if sequences then
                    packthem(sequences)
                end
                if sublookups then
                    packthem(sublookups)
                end

            end

        end

    end
end

local unpacked_mt = {
    __index =
        function(t,k)
            t[k] = false
            return k -- next time true
        end
}

function readers.unpack(data)

    if data then
        local tables = data.tables
        if tables then
            local resources    = data.resources
            local descriptions = data.descriptions or data.glyphs
            local sequences    = resources.sequences
            local sublookups   = resources.sublookups
            local features     = resources.features
            local palettes     = resources.colorpalettes
            local variable     = resources.variabledata
            local unpacked     = { }
            setmetatable(unpacked,unpacked_mt)
            for unicode, description in next, descriptions do
                local tv = tables[description.boundingbox]
                if tv then
                    description.boundingbox = tv
                end
                local math = description.math
                if math then
                    local kerns = math.kerns
                    if kerns then
                        local tm = tables[kerns]
                        if tm then
                            math.kerns = tm
                            kerns = unpacked[tm]
                        end
                        if kerns then
                            for k, kern in next, kerns do
                                local tv = tables[kern]
                                if tv then
                                    kerns[k] = tv
                                end
                            end
                        end
                    end
                end
             -- if palettes then
             --     local color = description.color
             --     if color then
             --         for i=1,#color do
             --             local tv = tables[color[i]]
             --             if tv then
             --                 color[i] = tv
             --             end
             --         end
             --     end
             -- end
            end

         -- local function expandranges(t,ranges)
         --     for i=1,#ranges do
         --         local r = ranges[i]
         --         for k=r[1],r[2] do
         --             t[k] = true
         --         end
         --     end
         -- end

            local function unpackthem(sequences)
                for i=1,#sequences do
                    local sequence  = sequences[i]
                    local kind      = sequence.type
                    local steps     = sequence.steps
                    local order     = sequence.order
                    local features  = sequence.features
                    local flags     = sequence.flags
                    local markclass = sequence.markclass
                    if features then
                        local tv = tables[features]
                        if tv then
                            sequence.features = tv
                            features = tv
                        end
                        for script, feature in next, features do
                            local tv = tables[feature]
                            if tv then
                                features[script] = tv
                            end
                        end
                    end
                    if steps then
                        for i=1,#steps do
                            local step = steps[i]
                            if kind == "gpos_pair" then
                                local c = step.coverage
                                if c then
                                    if step.format == "pair" then
                                        for g1, d1 in next, c do
                                            local tv = tables[d1]
                                            if tv then
                                                c[g1] = tv
                                                d1 = tv
                                            end
                                            for g2, d2 in next, d1 do
                                                local tv = tables[d2]
                                                if tv then
                                                    d1[g2] = tv
                                                    d2 = tv
                                                end
                                                local f = tables[d2[1]] if f then d2[1] = f end
                                                local s = tables[d2[2]] if s then d2[2] = s end
                                            end
                                        end
                                    else
                                        for g1, d1 in next, c do
                                            local tv = tables[d1]
                                            if tv then
                                                c[g1] = tv
                                            end
                                        end
                                    end
                                end
                            elseif kind == "gpos_single" then
                                local c = step.coverage
                                if c then
                                    if step.format == "single" then
                                        for g1, d1 in next, c do
                                            local tv = tables[d1]
                                            if tv then
                                                c[g1] = tv
                                            end
                                        end
                                    else
                                        local tv = tables[c]
                                        if tv then
                                            step.coverage = tv
                                        end
                                    end
                                end
                            elseif kind == "gpos_cursive" then
                                local c = step.coverage
                                if c then
                                    for g1, d1 in next, c do
                                        local tv = tables[d1]
                                        if tv then
                                            d1 = tv
                                            c[g1] = d1
                                        end
                                        local f = tables[d1[2]] if f then d1[2] = f end
                                        local s = tables[d1[3]] if s then d1[3] = s end
                                    end
                                end
                            elseif kind == "gpos_mark2base" or kind == "gpos_mark2mark" then
                                local c = step.baseclasses
                                if c then
                                    for g1, d1 in next, c do
                                        for g2, d2 in next, d1 do
                                            local tv = tables[d2]
                                            if tv then
                                                d1[g2] = tv
                                            end
                                        end
                                    end
                                end
                                local c = step.coverage
                                if c then
                                    for g1, d1 in next, c do
                                        local tv = tables[d1[2]]
                                        if tv then
                                            d1[2] = tv
                                        end
                                    end
                                end
                            elseif kind == "gpos_mark2ligature" then
                                local c = step.baseclasses
                                if c then
                                    for g1, d1 in next, c do
                                        for g2, d2 in next, d1 do
                                            local tv = tables[d2] -- new
                                            if tv then
                                                d2 = tv
                                                d1[g2] = d2
                                            end
                                            for g3, d3 in next, d2 do
                                                local tv = tables[d2[g3]]
                                                if tv then
                                                    d2[g3] = tv
                                                end
                                            end
                                        end
                                    end
                                end
                                local c = step.coverage
                                if c then
                                    for g1, d1 in next, c do
                                        local tv = tables[d1[2]]
                                        if tv then
                                            d1[2] = tv
                                        end
                                    end
                                end
                            end
                            local rules = step.rules
                            if rules then
                                for i=1,#rules do
                                    local rule = rules[i]
                                    local before = rule.before
                                    if before then
                                        local tv = tables[before]
                                        if tv then
                                            rule.before = tv
                                            before = tv
                                        end
                                        for i=1,#before do
                                            local tv = tables[before[i]]
                                            if tv then
                                                before[i] = tv
                                            end
                                        end
                                     -- for i=1,#before do
                                     --     local bi = before[i]
                                     --     local tv = tables[bi]
                                     --     if tv then
                                     --         bi = tv
                                     --         before[i] = bi
                                     --     end
                                     --     local ranges = bi.ranges
                                     --     if ranges then
                                     --         expandranges(bi,ranges)
                                     --     end
                                     -- end
                                    end
                                    local after = rule.after
                                    if after then
                                        local tv = tables[after]
                                        if tv then
                                            rule.after = tv
                                            after = tv
                                        end
                                        for i=1,#after do
                                            local tv = tables[after[i]]
                                            if tv then
                                                after[i] = tv
                                            end
                                        end
                                     -- for i=1,#after do
                                     --     local ai = after[i]
                                     --     local tv = tables[ai]
                                     --     if tv then
                                     --         ai = tv
                                     --         after[i] = ai
                                     --     end
                                     --     local ranges = ai.ranges
                                     --     if ranges then
                                     --         expandranges(ai,ranges)
                                     --     end
                                     -- end
                                    end
                                    local current = rule.current
                                    if current then
                                        local tv = tables[current]
                                        if tv then
                                            rule.current = tv
                                            current = tv
                                        end
                                        for i=1,#current do
                                            local tv = tables[current[i]]
                                            if tv then
                                                current[i] = tv
                                            end
                                        end
                                     -- for i=1,#current do
                                     --     local ci = current[i]
                                     --     local tv = tables[ci]
                                     --     if tv then
                                     --         ci = tv
                                     --         current[i] = ci
                                     --     end
                                     --     local ranges = ci.ranges
                                     --     if ranges then
                                     --         expandranges(ci,ranges)
                                     --     end
                                     -- end
                                    end
                                 -- local lookups = rule.lookups
                                 -- if lookups then
                                 --     local tv = tables[lookups]
                                 --     if tv then
                                 --         rule.lookups = tv
                                 --     end
                                 -- end
                                    local replacements = rule.replacements
                                    if replacements then
                                        local tv = tables[replacements]
                                        if tv then
                                            rule.replacements = tv
                                        end
                                    end
                                end
                            end
                        end
                    end
                    if order then
                        local tv = tables[order]
                        if tv then
                            sequence.order = tv
                        end
                    end
                    if flags then
                        local tv = tables[flags]
                        if tv then
                            sequence.flags = tv
                        end
                    end
               end
            end

            if sequences then
                unpackthem(sequences)
            end

            if sublookups then
                unpackthem(sublookups)
            end

            if features then
                for k, list in next, features do
                    for feature, spec in next, list do
                        local tv = tables[spec]
                        if tv then
                            list[feature] = tv
                        end
                    end
                end
            end

            if palettes then
                for i=1,#palettes do
                    local p = palettes[i]
                    for j=1,#p do
                        local tv = tables[p[j]]
                        if tv then
                            p[j] = tv
                        end
                    end
                end
            end

            if variable then

                -- todo: segments

                local instances = variable.instances
                if instances then
                    for i=1,#instances do
                        local v = instances[i].values
                        for j=1,#v do
                            local tv = tables[v[j]]
                            if tv then
                                v[j] = tv
                            end
                        end
                    end
                end

                local function unpackdeltas(main)
                    if main then
                        local deltas = main.deltas
                        if deltas then
                            for i=1,#deltas do
                                local di = deltas[i]
                                local d  = di.deltas
                                local r  = di.regions
                                for j=1,#d do
                                    local tv = tables[d[j]]
                                    if tv then
                                        d[j] = tv
                                    end
                                end
                                local tv = di.regions
                                if tv then
                                    di.regions = tv
                                end
                            end
                        end
                        local regions = main.regions
                        if regions then
                            local tv = tables[regions]
                            if tv then
                                main.regions = tv
                                regions = tv
                            end
                            for i=1,#regions do
                                local r = regions[i]
                                for j=1,#r do
                                    local tv = tables[r[j]]
                                    if tv then
                                        r[j] = tv
                                    end
                                end
                            end
                        end
                    end
                end

                unpackdeltas(variable.global)
                unpackdeltas(variable.horizontal)
                unpackdeltas(variable.vertical)
                unpackdeltas(variable.metrics)

            end

            data.tables = nil
        end
    end
end

local mt = {
    __index = function(t,k) -- maybe set it
        if k == "height" then
            local ht = t.boundingbox[4]
            return ht < 0 and 0 or ht
        elseif k == "depth" then
            local dp = -t.boundingbox[2]
            return dp < 0 and 0 or dp
        elseif k == "width" then
            return 0
        elseif k == "name" then -- or maybe uni*
            return forcenotdef and ".notdef"
        end
    end
}

local function sameformat(sequence,steps,first,nofsteps,kind)
    return true
end

local function mergesteps_1(lookup,strict)
    local steps    = lookup.steps
    local nofsteps = lookup.nofsteps
    local first    = steps[1]
    if strict then
        local f = first.format
        for i=2,nofsteps do
            if steps[i].format ~= f then
                if trace_optimizations then
                    report_optimizations("not merging %a steps of %a lookup %a, different formats",nofsteps,lookup.type,lookup.name)
                end
                return 0
            end
        end
    end
    if trace_optimizations then
        report_optimizations("merging %a steps of %a lookup %a",nofsteps,lookup.type,lookup.name)
    end
    local target = first.coverage
    for i=2,nofsteps do
        local c = steps[i].coverage
        if c then
            for k, v in next, c do
                if not target[k] then
                    target[k] = v
                end
            end
        end
    end
    lookup.nofsteps = 1
    lookup.merged   = true
    lookup.steps    = { first }
    return nofsteps - 1
end

local function mergesteps_2(lookup) -- pairs
    -- this can be tricky as we can have a match on a mark with no marks skip flag
    -- in which case with multiple steps a hit can prevent a next step while in the
    -- merged case we can hit differently (a messy font then anyway)
    local steps    = lookup.steps
    local nofsteps = lookup.nofsteps
    local first    = steps[1]
    if strict then
        local f = first.format
        for i=2,nofsteps do
            if steps[i].format ~= f then
                if trace_optimizations then
                    report_optimizations("not merging %a steps of %a lookup %a, different formats",nofsteps,lookup.type,lookup.name)
                end
                return 0
            end
        end
    end
    if trace_optimizations then
        report_optimizations("merging %a steps of %a lookup %a",nofsteps,lookup.type,lookup.name)
    end
    local target = first.coverage
    for i=2,nofsteps do
        local c = steps[i].coverage
        if c then
            for k, v in next, c do
                local tk = target[k]
                if tk then
                    for kk, vv in next, v do
                        if tk[kk] == nil then
                            tk[kk] = vv
                        end
                    end
                else
                    target[k] = v
                end
            end
        end
    end
    lookup.nofsteps = 1
    lookup.merged   = true
    lookup.steps    = { first }
    return nofsteps - 1
end

-- we could have a coverage[first][second] = { } already here (because eventually
-- we also have something like that after loading)

local function mergesteps_3(lookup,strict) -- marks
    local steps    = lookup.steps
    local nofsteps = lookup.nofsteps
    if trace_optimizations then
        report_optimizations("merging %a steps of %a lookup %a",nofsteps,lookup.type,lookup.name)
    end
    -- check first
    local coverage = { }
    for i=1,nofsteps do
        local c = steps[i].coverage
        if c then
            for k, v in next, c do
                local tk = coverage[k] -- { class, { x, y } }
                if tk then
                    if trace_optimizations then
                        report_optimizations("quitting merge due to multiple checks")
                    end
                    return nofsteps
                else
                    coverage[k] = v
                end
            end
        end
    end
    -- merge indeed
    local first       = steps[1]
    local baseclasses = { } -- let's assume sparse step.baseclasses
    for i=1,nofsteps do
        local offset = i*10  -- we assume max 10 classes per step
        local step   = steps[i]
        for k, v in sortedhash(step.baseclasses) do
            baseclasses[offset+k] = v
        end
        for k, v in next, step.coverage do
            v[1] = offset + v[1]
        end
    end
    first.baseclasses = baseclasses
    first.coverage    = coverage
    lookup.nofsteps   = 1
    lookup.merged     = true
    lookup.steps      = { first }
    return nofsteps - 1
end

local function nested(old,new)
    for k, v in next, old do
        if k == "ligature" then
            if not new.ligature then
                new.ligature = v
            end
        else
            local n = new[k]
            if n then
                nested(v,n)
            else
                new[k] = v
            end
        end
    end
end

local function mergesteps_4(lookup) -- ligatures
    local steps    = lookup.steps
    local nofsteps = lookup.nofsteps
    local first    = steps[1]
    if trace_optimizations then
        report_optimizations("merging %a steps of %a lookup %a",nofsteps,lookup.type,lookup.name)
    end
    local target = first.coverage
    for i=2,nofsteps do
        local c = steps[i].coverage
        if c then
            for k, v in next, c do
                local tk = target[k]
                if tk then
                    nested(v,tk)
                else
                    target[k] = v
                end
            end
        end
    end
    lookup.nofsteps = 1
    lookup.steps = { first }
    return nofsteps - 1
end

-- so we assume only one cursive entry and exit and even then the first one seems
-- to win anyway: no exit or entry quite the lookup match and then we take the
-- next step; this means that we can as well merge them

local function mergesteps_5(lookup) -- cursive
    local steps    = lookup.steps
    local nofsteps = lookup.nofsteps
    local first    = steps[1]
    if trace_optimizations then
        report_optimizations("merging %a steps of %a lookup %a",nofsteps,lookup.type,lookup.name)
    end
    local target = first.coverage
    local hash   = nil
    for k, v in next, target do
        hash = v[1]
        break
    end
    for i=2,nofsteps do
        local c = steps[i].coverage
        if c then
            for k, v in next, c do
                local tk = target[k]
                if tk then
                    if not tk[2] then
                        tk[2] = v[2]
                    end
                    if not tk[3] then
                        tk[3] = v[3]
                    end
                else
                    target[k] = v
                    v[1] = hash
                end
            end
        end
    end
    lookup.nofsteps = 1
    lookup.merged   = true
    lookup.steps    = { first }
    return nofsteps - 1
end

local function checkkerns(lookup)
    local steps    = lookup.steps
    local nofsteps = lookup.nofsteps
    local kerned   = 0
    for i=1,nofsteps do
        local step = steps[i]
        if step.format == "pair" then
            local coverage = step.coverage
            local kerns    = true
            for g1, d1 in next, coverage do
                if d1 == true then
                    -- all zero
                elseif not d1 then
                    -- null
                elseif d1[1] ~= 0 or d1[2] ~= 0 or d1[4] ~= 0 then
                    kerns = false
                    break
                end
            end
            if kerns then
                if trace_optimizations then
                    report_optimizations("turning pairs of step %a of %a lookup %a into kerns",i,lookup.type,lookup.name)
                end
                local c = { }
                for g1, d1 in next, coverage do
                    if d1 and d1 ~= true then
                        c[g1] = d1[3]
                    end
                end
                step.coverage = c
                step.format = "move"
                kerned = kerned + 1
            end
        end
    end
    return kerned
end

-- There are several options to optimize but we have this somewhat fuzzy aspect of
-- advancing (depending on the second of a pair) so we need to retain that information.
--
-- We can have:
--
--     true, nil|false
--
-- which effectively means: nothing to be done and advance to next (so not next of
-- next) and because coverage should be not overlapping we can wipe these. However,
-- checking for (true,nil) (false,nil) and omitting them doesn't gain much.

-- Because we pack we cannot mix tables and numbers so we can only turn a whole set in
-- format kern instead of pair.

local strip_pairs         = true

local compact_pairs       = true
local compact_singles     = true

local merge_pairs         = true
local merge_singles       = true
local merge_substitutions = true
local merge_alternates    = true
local merge_multiples     = true
local merge_ligatures     = true
local merge_cursives      = true
local merge_marks         = true

directives.register("otf.strip.pairs",         function(v) strip_pairs     = v end)

directives.register("otf.compact.pairs",       function(v) compact_pairs   = v end)
directives.register("otf.compact.singles",     function(v) compact_singles = v end)

directives.register("otf.merge.pairs",         function(v) merge_pairs         = v end)
directives.register("otf.merge.singles",       function(v) merge_singles       = v end)
directives.register("otf.merge.substitutions", function(v) merge_substitutions = v end)
directives.register("otf.merge.alternates",    function(v) merge_alternates    = v end)
directives.register("otf.merge.multiples",     function(v) merge_multiples     = v end)
directives.register("otf.merge.ligatures",     function(v) merge_ligatures     = v end)
directives.register("otf.merge.cursives",      function(v) merge_cursives      = v end)
directives.register("otf.merge.marks",         function(v) merge_marks         = v end)

local function checkpairs(lookup)
    local steps    = lookup.steps
    local nofsteps = lookup.nofsteps
    local kerned   = 0

    local function onlykerns(step)
        local coverage = step.coverage
        for g1, d1 in next, coverage do
            for g2, d2 in next, d1 do
                if d2[2] then
                    --- true or { a, b, c, d }
                    return false
                else
                    local v = d2[1]
                    if v == true then
                        -- all zero
                    elseif v and (v[1] ~= 0 or v[2] ~= 0 or v[4] ~= 0) then
                        -- complex kerns
                        return false
                    end
                end
            end
        end
        return coverage
    end

    for i=1,nofsteps do
        local step = steps[i]
        if step.format == "pair" then
            local coverage = onlykerns(step)
            if coverage then
                if trace_optimizations then
                    report_optimizations("turning pairs of step %a of %a lookup %a into kerns",i,lookup.type,lookup.name)
                end
                for g1, d1 in next, coverage do
                    local d = { }
                    for g2, d2 in next, d1 do
                        local v = d2[1]
                        if v == true then
                            -- ignore    -- d1[g2] = nil
                        elseif v then
                            d[g2] = v[3] -- d1[g2] = v[3]
                        end
                    end
                    coverage[g1] = d
                end
                step.format = "move"
                kerned = kerned + 1
            end
        end
    end
    return kerned
end

local function strippairs(lookup)
    local steps    = lookup.steps
    local nofsteps = lookup.nofsteps
    local stripped = 0

    for i=1,nofsteps do
        local step = steps[i]
        if step.format == "pair" then
            local coverage = step.coverage
            for g1, d1 in next, coverage do
                for g2, d2 in next, d1 do
                    if d2[2] then
                        --- true or { a, b, c, d }
                 -- else
                 --     local v = d2[1]
                 --     if v == true then
                 --         d1[g2] = nil
                 --         stripped = stripped + 1
                 --     elseif v and (v[1] == 0 and v[2] == 0 and v[4] == 0) then -- vkrn can have v[3] ~= 0
                 --         d1[g2] = nil
                 --         stripped = stripped + 1
                 --     end
                 -- end
                    elseif d2[1] == true then
                        d1[g2] = nil
                        stripped = stripped + 1
                    end
                end
            end
        end
    end
    return stripped
end

function readers.compact(data)
    if not data or data.compacted then
        return
    else
        data.compacted = true
    end
    local resources = data.resources
    local stripped  = 0
    local merged    = 0
    local kerned    = 0
    local allsteps  = 0
    local function compact(what)
        local lookups = resources[what]
        if lookups then
            for i=1,#lookups do
                local lookup   = lookups[i]
                local nofsteps = lookup.nofsteps
                local kind     = lookup.type
                allsteps = allsteps + nofsteps
                if nofsteps > 1 then
                    local merg = merged
                    if kind == "gsub_single" then
                        if merge_substitutions then
                            merged = merged + mergesteps_1(lookup)
                        end
                    elseif kind == "gsub_alternate" then
                        if merge_alternates then
                            merged = merged + mergesteps_1(lookup)
                        end
                    elseif kind == "gsub_multiple" then
                        if merge_multiples then
                            merged = merged + mergesteps_1(lookup)
                        end
                    elseif kind == "gsub_ligature" then
                        if merge_ligatures then
                            merged = merged + mergesteps_4(lookup)
                        end
                    elseif kind == "gpos_single" then
                        -- maybe also strip zeros here
                        if merge_singles then
                            merged = merged + mergesteps_1(lookup,true)
                        end
                        if compact_singles then
                            kerned = kerned + checkkerns(lookup)
                        end
                    elseif kind == "gpos_pair" then
                        if strip_pairs then
                            stripped = stripped + strippairs(lookup) -- noto cjk from 24M -> 8 M
                        end
                        if merge_pairs then
                            merged = merged + mergesteps_2(lookup)
                        end
                        if compact_pairs then
                            kerned = kerned + checkpairs(lookup)
                        end
                    elseif kind == "gpos_cursive" then
                        if merge_cursives then
                            merged = merged + mergesteps_5(lookup)
                        end
                    elseif kind == "gpos_mark2mark" or kind == "gpos_mark2base" or kind == "gpos_mark2ligature" then
                        if merge_marks then
                            merged = merged + mergesteps_3(lookup)
                        end
                    end
                    if merg ~= merged then
                        lookup.merged = true
                    end
                elseif nofsteps == 1 then
                    local kern = kerned
                    if kind == "gpos_single" then
                        if compact_singles then
                            kerned = kerned + checkkerns(lookup)
                        end
                    elseif kind == "gpos_pair" then
                        if compact_pairs then
                            kerned = kerned + checkpairs(lookup)
                        end
                    end
                    if kern ~= kerned then
                     -- lookup.kerned = true
                    end
                end
            end
        elseif trace_optimizations then
            report_optimizations("no lookups in %a",what)
        end
    end
    compact("sequences")
    compact("sublookups")
    if trace_optimizations then
        if stripped > 0 then
            report_optimizations("%i zero positions stripped before merging",stripped)
        end
        if merged > 0 then
            report_optimizations("%i steps of %i removed due to merging",merged,allsteps)
        end
        if kerned > 0 then
            report_optimizations("%i steps of %i steps turned from pairs into kerns",kerned,allsteps)
        end
    end
end

if CONTEXTLMTXMODE and CONTEXTLMTXMODE > 0 then

    local done = 0

    local function condense_1(k,v,t)
        if type(v) == "table" then
            local u = false
            local l = false
            for k, v in next, v do
                if k == "ligature" then
                    l = v
                    if u then
                        break
                    end
                elseif u then
                    break
                else
                    u = true
                end
            end
            if l and not u then
                t[k] = l
                done = done + 1
            end
            if u then
                for k, vv in next, v do
                    if k ~= "ligature" then
                        condense_1(k,vv,v)
                    end
                end
            end
        end
    end

    local function condensesteps_1(lookup)
        done = 0
        if lookup.type == "gsub_ligature" then
            local steps = lookup.steps
            if steps then
                for i=1,#steps do
                    local step     = steps[i]
                    local coverage = step.coverage
                    if coverage then
                        for k, v in next, coverage do
                            if condense_1(k,v,coverage) then
                                coverage[k] = v.ligature
                                done = done + 1
                            end
                        end
                    end
                end
            end
        end
        return done
    end

    function readers.condense(data)
        if not data or data.condensed then
            return
        else
            data.condensed = true
        end
        local resources = data.resources
        local condensed = 0
        local function condense(what)
            local lookups = resources[what]
            if lookups then
                for i=1,#lookups do
                    condensed = condensed + condensesteps_1(lookups[i])
                end
            elseif trace_optimizations then
                report_optimizations("no lookups in %a",what)
            end
        end
        condense("sequences")
        condense("sublookups")
        if trace_optimizations then
            if condensed > 0 then
                report_optimizations("%i ligatures condensed",condensed)
            end
        end
    end

end

local function mergesteps(t,k)
    if k == "merged" then
        local merged = { }
        for i=1,#t do
            local step     = t[i]
            local coverage = step.coverage
            for k in next, coverage do
                local m = merged[k]
                if m then
                    m[2] = i
                 -- m[#m+1] = step
                else
                    merged[k] = { i, i }
                 -- merged[k] = { step }
                end
            end
        end
        t.merged = merged
        return merged
    end
end

local function checkmerge(sequence)
    local steps = sequence.steps
    if steps then
        setmetatableindex(steps,mergesteps)
    end
end

local function checkflags(sequence,resources)
    if not sequence.skiphash then
        local flags = sequence.flags
        if flags then
            local skipmark     = flags[1]
            local skipligature = flags[2]
            local skipbase     = flags[3]
            local markclass    = sequence.markclass
            local skipsome     = skipmark or skipligature or skipbase or markclass or false
            if skipsome then
                sequence.skiphash = setmetatableindex(function(t,k)
                    local c = resources.classes[k] -- delayed table
                    local v = c == skipmark
                           or (markclass and c == "mark" and not markclass[k])
                           or c == skipligature
                           or c == skipbase
                           or false
                    t[k] = v
                    return v
                end)
            else
                sequence.skiphash = false
            end
        else
            sequence.skiphash = false
        end
    end
end

local function checksteps(sequence)
    local steps = sequence.steps
    if steps then
        for i=1,#steps do
            steps[i].index = i
        end
    end
end

if fonts.helpers then
    fonts.helpers.checkmerge = checkmerge
    fonts.helpers.checkflags = checkflags
    fonts.helpers.checksteps = checksteps -- has to happen last
end

function readers.expand(data)
    if not data or data.expanded then
        return
    else
        data.expanded = true
    end
    local resources    = data.resources
    local sublookups   = resources.sublookups
    local sequences    = resources.sequences -- were one level up
    local markclasses  = resources.markclasses
    local descriptions = data.descriptions
    if descriptions then
        local defaultwidth  = resources.defaultwidth  or 0
        local defaultheight = resources.defaultheight or 0
        local defaultdepth  = resources.defaultdepth  or 0
        local basename      = trace_markwidth and file.basename(resources.filename)
        for u, d in next, descriptions do
            local bb = d.boundingbox
            local wd = d.width
            if not wd then
                -- or bb?
                d.width = defaultwidth
            elseif trace_markwidth and wd ~= 0 and d.class == "mark" then
                report_markwidth("mark %a with width %b found in %a",d.name or "<noname>",wd,basename)
            end
            if bb then
                local ht =  bb[4]
                local dp = -bb[2]
                if ht == 0 or ht < 0 then
                    -- not set
                else
                    d.height = ht
                end
                if dp == 0 or dp < 0 then
                    -- not set
                else
                    d.depth  = dp
                end
            end
        end
    end

    -- using a merged combined hash as first test saves some 30% on ebgaramond and
    -- about 15% on arabtype .. then moving the a test also saves a bit (even when
    -- often a is not set at all so that one is a bit debatable

    local function expandlookups(sequences,whatever)
        if sequences then
            -- we also need to do sublookups
            for i=1,#sequences do
                local sequence = sequences[i]
                local steps    = sequence.steps
                if steps then
                    local nofsteps = sequence.nofsteps

                    local kind = sequence.type
                    local markclass = sequence.markclass
                    if markclass then
                        if not markclasses then
                            report_warning("missing markclasses")
                            sequence.markclass = false
                        else
                            sequence.markclass = markclasses[markclass]
                        end
                    end

                    for i=1,nofsteps do
                        local step = steps[i]
                        local baseclasses = step.baseclasses
                        if baseclasses then
                            local coverage = step.coverage
                            for k, v in next, coverage do
                                v[1] = baseclasses[v[1]] -- slot 1 is a placeholder
                            end
                        elseif kind == "gpos_cursive" then
                            local coverage = step.coverage
                            for k, v in next, coverage do
                                v[1] = coverage -- slot 1 is a placeholder
                            end
                        end
                        local rules = step.rules
                        if rules then
                            local rulehash   = { n = 0 } -- is contexts in font-ots
                            local rulesize   = 0
                            local coverage   = { }
                            local lookuptype = sequence.type
                            local nofrules   = #rules
                            step.coverage    = coverage -- combined hits
                            for currentrule=1,nofrules do
                                local rule         = rules[currentrule]
                                local current      = rule.current
                                local before       = rule.before
                                local after        = rule.after
                                local replacements = rule.replacements or false
                                local sequence     = { }
                                local nofsequences = 0
                                if before then
                                    for n=1,#before do
                                        nofsequences = nofsequences + 1
                                        sequence[nofsequences] = before[n]
                                    end
                                end
                                local start = nofsequences + 1
                                for n=1,#current do
                                    nofsequences = nofsequences + 1
                                    sequence[nofsequences] = current[n]
                                end
                                local stop = nofsequences
                                if after then
                                    for n=1,#after do
                                        nofsequences = nofsequences + 1
                                        sequence[nofsequences] = after[n]
                                    end
                                end
                                local lookups = rule.lookups or false
                                local subtype = nil
                                if lookups then
                                    for i=1,#lookups do
                                        local lookups = lookups[i]
                                        if lookups then
                                            for k, v in next, lookups do -- actually this one is indexed
                                                local lookup = sublookups[v]
if not lookup and whatever then
    lookup = whatever[v]
end
                                                if lookup then
                                                    lookups[k] = lookup
                                                    if not subtype then
                                                        subtype = lookup.type
                                                    end
                                                else
                                                    -- already expanded
                                                end
                                            end
                                        end
                                    end
                                end
                                if sequence[1] then -- we merge coverage into one
                                    sequence.n = #sequence -- tiny speedup
                                    local ruledata = {
                                        currentrule,  -- 1 -- original rule number, only use this for tracing!
                                        lookuptype,   -- 2
                                        sequence,     -- 3
                                        start,        -- 4
                                        stop,         -- 5
                                        lookups,      -- 6 (6/7 also signal of what to do)
                                        replacements, -- 7
                                        subtype,      -- 8
                                    }
                                    --
                                    -- possible optimization: per [unic] a rulehash, but beware:
                                    -- contexts have unique coverage and chains can have multiple
                                    -- hits (rules) per coverage entry
                                    --
                                    -- so: we can combine multiple steps as well as multiple rules
                                    -- but that takes careful checking, in which case we can go the
                                    -- step list approach and turn contexts into steps .. in fact,
                                    -- if we turn multiple contexts into steps we're already ok as
                                    -- steps gets a coverage hash by metatable
                                    --
                                    rulesize = rulesize + 1
                                    rulehash[rulesize] = ruledata
                                    rulehash.n = rulesize -- tiny speedup
                                    --
                                    if true then -- nofrules > 1

                                        for unic in next, sequence[start] do
                                            local cu = coverage[unic]
                                            if cu then
                                                local n = #cu+1
                                                cu[n] = ruledata
                                                cu.n = n
                                            else
                                                coverage[unic] = { ruledata, n = 1 }
                                            end
                                        end

                                    else

                                        for unic in next, sequence[start] do
                                            local cu = coverage[unic]
                                            if cu then
                                                -- we can have a contextchains with many matches which we
                                                -- can actually optimize
                                            else
                                                coverage[unic] = rulehash
                                            end
                                        end

                                    end
                                end
                            end
                        end
                    end

                    checkmerge(sequence)
                    checkflags(sequence,resources)
                    checksteps(sequence)

                end
            end
        end
    end

    expandlookups(sequences)
    expandlookups(sublookups,sequences)
end
