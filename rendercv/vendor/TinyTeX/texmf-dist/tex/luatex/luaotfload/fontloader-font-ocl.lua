if not modules then modules = { } end modules ['font-ocl'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- todo : user list of colors

local tostring, tonumber, next = tostring, tonumber, next
local round, max = math.round, math.round
local gsub, find = string.gsub, string.find
local sortedkeys, sortedhash, concat = table.sortedkeys, table.sortedhash, table.concat
local setmetatableindex = table.setmetatableindex

local formatters   = string.formatters
local tounicode    = fonts.mappings.tounicode

local helpers      = fonts.helpers

local charcommand  = helpers.commands.char
local rightcommand = helpers.commands.right
local leftcommand  = helpers.commands.left
local downcommand  = helpers.commands.down

local otf          = fonts.handlers.otf
local otfregister  = otf.features.register

local f_color      = formatters["%.3f %.3f %.3f rg"]
local f_gray       = formatters["%.3f g"]

if context then

    local startactualtext = nil
    local stopactualtext  = nil

    function otf.getactualtext(s)
        if not startactualtext then
            startactualtext = backends.codeinjections.startunicodetoactualtextdirect
            stopactualtext  = backends.codeinjections.stopunicodetoactualtextdirect
        end
        return startactualtext(s), stopactualtext()
    end

else

    -- Actually we don't need a generic branch at all because (according the the
    -- internet) other macro packages rely on hb for emoji etc and never used this
    -- feature of the font loader. So maybe I should just remove this from generic.

    local tounicode = fonts.mappings.tounicode16

    function otf.getactualtext(s)
        return
            "/Span << /ActualText <feff" .. s .. "> >> BDC",
            "EMC"
    end

end

local sharedpalettes = { }

local hash = setmetatableindex(function(t,k)
    local v = { "pdf", "direct", k }
    t[k] = v
    return v
end)

if context then

    -- \definefontcolorpalette [emoji-r] [emoji-red,emoji-gray,textcolor] -- looks bad
    -- \definefontcolorpalette [emoji-r] [emoji-red,emoji-gray]           -- looks okay

    local colors          = attributes.list[attributes.private('color')] or { }
    local transparencies  = attributes.list[attributes.private('transparency')] or { }

    function otf.registerpalette(name,values)
        sharedpalettes[name] = values
        local color          = lpdf.color
        local transparency   = lpdf.transparency
        local register       = colors.register
        for i=1,#values do
            local v = values[i]
            if v == "textcolor" then
                values[i] = false
            else
                local c = nil
                local t = nil
                if type(v) == "table" then
                    c = register(name,"rgb",
                        max(round((v.r or 0)*255),255)/255,
                        max(round((v.g or 0)*255),255)/255,
                        max(round((v.b or 0)*255),255)/255
                    )
                else
                    c = colors[v]
                    t = transparencies[v]
                end
                if c and t then
                    values[i] = hash[color(1,c) .. " " .. transparency(t)]
                elseif c then
                    values[i] = hash[color(1,c)]
                elseif t then
                    values[i] = hash[color(1,t)]
                end
            end
        end
    end

else -- for generic

    function otf.registerpalette(name,values)
        sharedpalettes[name] = values
        for i=1,#values do
            local v = values[i]
            if v then
                values[i] = hash[f_color(
                    max(round((v.r or 0)*255),255)/255,
                    max(round((v.g or 0)*255),255)/255,
                    max(round((v.b or 0)*255),255)/255
                )]
            end
        end
    end

end

-- We need to force page first because otherwise the q's get outside the font switch and
-- as a consequence the next character has no font set (well, it has: the preceding one). As
-- a consequence these fonts are somewhat inefficient as each glyph gets the font set. It's
-- a side effect of the fact that a font is handled when a character gets flushed. Okay, from
-- now on we can use text as literal mode.

local function convert(t,k)
    local v = { }
    for i=1,#k do
        local p = k[i]
        local r, g, b = p[1], p[2], p[3]
        if r == g and g == b then
            v[i] = hash[f_gray(r/255)]
        else
            v[i] = hash[f_color(r/255,g/255,b/255)]
        end
    end
    t[k] = v
    return v
end

-- At some point 'font' mode was added to the engine and we can assume that most distributions
-- ship a luatex that has it; ancient versions are no longer supported anyway. Begin 2020 there
-- was an actualtext related mail exchange with RM etc. that might result in similar mode keys
-- in other tex->pdf programs because there is a bit of inconsistency in the way this is dealt
-- with. Best is not to touch this code too much.

local mode = { "pdf", "mode", "font" }
local push = { "pdf", "page", "q" }
local pop  = { "pdf", "page", "Q" }

-- see context git repository for older variant (pre 20200501 cleanup)

local function initializeoverlay(tfmdata,kind,value)
    if value then
        local resources = tfmdata.resources
        local palettes  = resources.colorpalettes
        if palettes then
            --
            local converted = resources.converted
            if not converted then
                converted = setmetatableindex(convert)
                resources.converted = converted
            end
            local colorvalues = sharedpalettes[value]
            local default     = false -- so the text color (bad for icon overloads)
            if colorvalues then
                default = colorvalues[#colorvalues]
            else
                colorvalues = converted[palettes[tonumber(value) or 1] or palettes[1]] or { }
            end
            local classes = #colorvalues
            if classes == 0 then
                return
            end
            --
            local characters   = tfmdata.characters
            local descriptions = tfmdata.descriptions
            local properties   = tfmdata.properties
            --
            properties.virtualized = true
            tfmdata.fonts = {
                { id = 0 }
            }
            --
            local getactualtext = otf.getactualtext
            local b, e          = getactualtext(tounicode(0xFFFD))
            local actualb       = { "pdf", "page", b } -- saves tables
            local actuale       = { "pdf", "page", e } -- saves tables
            --
            for unicode, character in next, characters do
                local description = descriptions[unicode]
                if description then
                    local colorlist = description.colors
                    if colorlist then
                        local u = description.unicode or characters[unicode].unicode
                        local w = character.width or 0
                        local s = #colorlist
                        local goback = w ~= 0 and leftcommand[w] or nil -- needs checking: are widths the same
                        local t = {
                            mode,
                            not u and actualb or { "pdf", "page", (getactualtext(tounicode(u))) },
                            push,
                        }
                        local n = 3
                        local l = nil
                        for i=1,s do
                            local entry = colorlist[i]
                            local v = colorvalues[entry.class] or default
                            if v and l ~= v then
                                n = n + 1 t[n] = v
                                l = v
                            end
                            n = n + 1 t[n] = charcommand[entry.slot]
                            if s > 1 and i < s and goback then
                                n = n + 1 t[n] = goback
                            end
                        end
                        n = n + 1 t[n] = pop
                        n = n + 1 t[n] = actuale
                        character.commands = t
                    end
                end
            end
            return true
        end
    end
end

otfregister {
    name         = "colr",
    description  = "color glyphs",
    manipulators = {
        base = initializeoverlay,
        node = initializeoverlay,
    }
}

do

    local nofstreams = 0
    local f_name     = formatters[ [[pdf-glyph-%05i]] ]
    local f_used     = context and formatters[ [[original:///%s]] ] or formatters[ [[%s]] ]
    local hashed     = { }
    local cache      = { }

    local openpdf = pdfe.new
    ----- prefix  = "data:application/pdf,"

    function otf.storepdfdata(pdf)
        local done = hashed[pdf]
        if not done then
            nofstreams = nofstreams + 1
            local f = f_name(nofstreams)
            local n = openpdf(pdf,#pdf,f)
            done = f_used(n)
            hashed[pdf] = done
        end
        return done
    end

end

-- I'll probably make a variant for context as we can do it more efficient there than in
-- generic.

local function pdftovirtual(tfmdata,pdfshapes,kind) -- kind = png|svg
    if not tfmdata or not pdfshapes or not kind then
        return
    end
    --
    local characters = tfmdata.characters
    local properties = tfmdata.properties
    local parameters = tfmdata.parameters
    local hfactor    = parameters.hfactor
    --
    properties.virtualized = true
    --
    tfmdata.fonts = {
        { id = 0 } -- not really needed
    }
        --
    local getactualtext = otf.getactualtext
    local storepdfdata  = otf.storepdfdata
    --
    local b, e          = getactualtext(tounicode(0xFFFD))
    local actualb       = { "pdf", "page", b } -- saves tables
    local actuale       = { "pdf", "page", e } -- saves tables
    --
    local vfimage = lpdf and lpdf.vfimage or function(wd,ht,dp,data,name)
        local name = storepdfdata(data)
        return { "image", { filename = name, width = wd, height = ht, depth = dp } }
    end
    --
    for unicode, character in sortedhash(characters) do  -- sort is nicer for svg
        local index = character.index
        if index then
            local pdf   = pdfshapes[index]
            local typ   = type(pdf)
            local data  = nil
            local dx    = nil
            local dy    = nil
            local scale = 1
            if typ == "table" then
                data  = pdf.data
                dx    = pdf.x or pdf.dx or 0
                dy    = pdf.y or pdf.dy or 0
                scale = pdf.scale or 1
            elseif typ == "string" then
                data = pdf
                dx   = 0
                dy   = 0
            elseif typ == "number" then
                data = pdf
                dx   = 0
                dy   = 0
            end
            if data then
                -- We can delay storage by a lua function in commands: but then we need to
                -- be able to provide our own mem stream name (so that we can reserve it).
                -- Anyway, we will do this different in a future version of context.
                local bt = unicode and getactualtext(unicode)
                local wd = character.width  or 0
                local ht = character.height or 0
                local dp = character.depth  or 0
                -- The down and right will change too (we can move that elsewhere). We have
                -- a different treatment in lmtx but the next kind of works. These images are
                -- a mess anyway as in svg the bbox can be messed up absent). A png image
                -- needs the x/y. I might normalize this once we move to lmtx exlusively.
                character.commands = {
                    not unicode and actualb or { "pdf", "page", (getactualtext(unicode)) },
                    -- lmtx (when we deal with depth in vfimage, currently disabled):
                 -- downcommand [dy * hfactor],
                 -- rightcommand[dx * hfactor],
                 -- vfimage(wd,ht,dp,data,name),
                    -- mkiv
                    downcommand [dp + dy * hfactor],
                    rightcommand[     dx * hfactor],
                    vfimage(scale*wd,ht,dp,data,pdfshapes.filename or ""),
                    actuale,
                }
                character[kind] = true
            end
        end
    end
end

local otfsvg   = otf.svg or { }
otf.svg        = otfsvg
otf.svgenabled = true

do

    local report_svg = logs.reporter("fonts","svg conversion")

    local loaddata   = io.loaddata
    local savedata   = io.savedata
    local remove     = os.remove

if context then

        local xmlconvert = xml.convert
        local xmlfirst   = xml.first

     -- function otfsvg.filterglyph(entry,index)
     --     -- we only support decompression in lmtx, so one needs to wipe the
     --     -- cache when invalid xml is reported
     --     local svg  = xmlconvert(entry.data)
     --     local root = svg and xmlfirst(svg,"/svg[@id='glyph"..index.."']")
     --     local data = root and tostring(root)
     --  -- report_svg("data for glyph %04X: %s",index,data)
     --     return data
     -- end

        function otfsvg.filterglyph(entry,index)
            local d = entry.data
            if gzip.compressed(d) then
                d = gzip.decompress(d) or d
            end
            local svg  = xmlconvert(d)
            local root = svg and xmlfirst(svg,"/svg[@id='glyph"..index.."']")
            local data = root and tostring(root)
            return data
        end

else

        function otfsvg.filterglyph(entry,index) -- can be overloaded
            return entry.data
        end

end

    local runner = sandbox and sandbox.registerrunner {
        name     = "otfsvg",
        program  = "inkscape",
        method   = "pipeto",
        template = "--export-area-drawing --shell > temp-otf-svg-shape.log",
        reporter = report_svg,
    }

    if not runner then
        --
        -- poor mans variant for generic:
        --
        runner = function()
            return io.popen("inkscape --export-area-drawing --shell > temp-otf-svg-shape.log","w")
        end
    end

    -- There are svg out there with bad viewBox specifications where shapes lay outside that area,
    -- but trying to correct that didn't work out well enough so I discarded that code. BTW, we
    -- decouple the inskape run and the loading run because inkscape is working in the background
    -- in the files so we need to have unique files.
    --
    -- Because a generic setup can be flawed we need to catch bad inkscape runs which add a bit of
    -- ugly overhead. Bah.
    --
    -- In the long run this method is a dead end because we cannot rely on command line arguments
    -- etc to be upward compatible (so no real batch tool).

    local new = nil

    local function inkscapeformat(suffix)
        if new == nil then
            new = os.resultof("inkscape --version") or ""
            new = new == "" or not find(new,"Inkscape%s*0")
        end
        return new and "filename" or suffix
    end

    function otfsvg.topdf(svgshapes,tfmdata)
        local pdfshapes = { }
        local inkscape  = runner()
        if inkscape then
         -- local indices      = fonts.getindices(tfmdata)
            local descriptions = tfmdata.descriptions
            local nofshapes    = #svgshapes
            local s_format     = inkscapeformat("pdf") -- hack, this will go away when is >= 0 is everywhere
            local f_svgfile    = formatters["temp-otf-svg-shape-%i.svg"]
            local f_pdffile    = formatters["temp-otf-svg-shape-%i.pdf"]
            local f_convert    = formatters[new and "file-open:%s; export-%s:%s; export-do\n" or "%s --export-%s=%s\n"]
            local filterglyph  = otfsvg.filterglyph
            local nofdone      = 0
            local processed    = { }
            report_svg("processing %i svg containers",nofshapes)
            statistics.starttiming()
            for i=1,nofshapes do
                local entry = svgshapes[i]
                for index=entry.first,entry.last do
                    local data = filterglyph(entry,index)
                    if data and data ~= "" then
                        local svgfile = f_svgfile(index)
                        local pdffile = f_pdffile(index)
                        savedata(svgfile,data)
                        inkscape:write(f_convert(svgfile,s_format,pdffile))
                        processed[index] = true
                        nofdone = nofdone + 1
                        if nofdone % 25 == 0 then
                            report_svg("%i shapes submitted",nofdone)
                        end
                    end
                end
            end
            if nofdone % 25 ~= 0 then
                report_svg("%i shapes submitted",nofdone)
            end
            report_svg("processing can be going on for a while")
            inkscape:write("quit\n")
            inkscape:close()
            report_svg("processing %i pdf results",nofshapes)
            for index in next, processed do
                local svgfile = f_svgfile(index)
                local pdffile = f_pdffile(index)
             -- local fntdata = descriptions[indices[index]]
             -- local bounds  = fntdata and fntdata.boundingbox
                local pdfdata = loaddata(pdffile)
                if pdfdata and pdfdata ~= "" then
                    pdfshapes[index] = {
                        data = pdfdata,
                     -- x    = bounds and bounds[1] or 0,
                     -- y    = bounds and bounds[2] or 0,
                    }
                end
                remove(svgfile)
                remove(pdffile)
            end
            local characters = tfmdata.characters
            for k, v in next, characters do
                local d = descriptions[k]
                local i = d.index
                if i then
                    local p = pdfshapes[i]
                    if p then
                        local w = d.width
                        local l = d.boundingbox[1]
                        local r = d.boundingbox[3]
                        p.scale = (r - l) / w
                        p.x     = l
                    end
                end
            end
            if not next(pdfshapes) then
                report_svg("there are no converted shapes, fix your setup")
            end
            statistics.stoptiming()
            if statistics.elapsedseconds then
                report_svg("svg conversion time %s",statistics.elapsedseconds() or "-")
            end
        end
        return pdfshapes
    end

end

local function initializesvg(tfmdata,kind,value) -- hm, always value
    if value and otf.svgenabled then
        local svg       = tfmdata.properties.svg
        local hash      = svg and svg.hash
        local timestamp = svg and svg.timestamp
        if not hash then
            return
        end
        local pdffile   = containers.read(otf.pdfcache,hash)
        local pdfshapes = pdffile and pdffile.pdfshapes
        if not pdfshapes or pdffile.timestamp ~= timestamp or not next(pdfshapes) then
            -- the next test tries to catch errors in generic usage but of course can result
            -- in running again and again
            local svgfile   = containers.read(otf.svgcache,hash)
            local svgshapes = svgfile and svgfile.svgshapes
            pdfshapes = svgshapes and otfsvg.topdf(svgshapes,tfmdata,otf.pdfcache.writable,hash) or { }
            containers.write(otf.pdfcache, hash, {
                pdfshapes = pdfshapes,
                timestamp = timestamp,
            })
        end
        pdftovirtual(tfmdata,pdfshapes,"svg")
        return true
    end
end

otfregister {
    name         = "svg",
    description  = "svg glyphs",
    manipulators = {
        base = initializesvg,
        node = initializesvg,
    }
}

-- This can be done differently e.g. with ffi and gm and we can share code anway. Using
-- batchmode in gm is not faster and as it accumulates we would need to flush all
-- individual shapes. But ... in context lmtx (and maybe the backport) we will use
-- a different and more efficient method anyway. I'm still wondering if I should
-- keep color code in generic. Maybe it should be optional.

local otfpng   = otf.png or { }
otf.png        = otfpng
otf.pngenabled = true

do

    local report_png = logs.reporter("fonts","png conversion")

    local loaddata   = io.loaddata
    local savedata   = io.savedata
    local remove     = os.remove

    local runner = sandbox and sandbox.registerrunner {
        name     = "otfpng",
        program  = "gm",
        template = "convert -quality 100 temp-otf-png-shape.png temp-otf-png-shape.pdf > temp-otf-svg-shape.log",
     -- reporter = report_png,
    }

    if not runner then
        --
        -- poor mans variant for generic:
        --
        runner = function()
            return os.execute("gm convert -quality 100 temp-otf-png-shape.png temp-otf-png-shape.pdf > temp-otf-svg-shape.log")
        end
    end

    -- Alternatively we can create a single pdf file with -adjoin and then pick up pages from
    -- that file but creating thousands of small files is no fun either.

    function otfpng.topdf(pngshapes)
        local pdfshapes  = { }
        local pngfile    = "temp-otf-png-shape.png"
        local pdffile    = "temp-otf-png-shape.pdf"
        local nofdone    = 0
        local indices    = sortedkeys(pngshapes) -- can be sparse
        local nofindices = #indices
        report_png("processing %i png containers",nofindices)
        statistics.starttiming()
        for i=1,nofindices do
            local index = indices[i]
            local entry = pngshapes[index]
            local data  = entry.data -- or placeholder
            local x     = entry.x
            local y     = entry.y
            savedata(pngfile,data)
            runner()
            pdfshapes[index] = {
                x     = x ~= 0 and x or nil,
                y     = y ~= 0 and y or nil,
                data  = loaddata(pdffile),
            }
            nofdone = nofdone + 1
            if nofdone % 100 == 0 then
                report_png("%i shapes processed",nofdone)
            end
        end
        report_png("processing %i pdf results",nofindices)
        remove(pngfile)
        remove(pdffile)
        statistics.stoptiming()
        if statistics.elapsedseconds then
            report_png("png conversion time %s",statistics.elapsedseconds() or "-")
        end
        return pdfshapes
    end

end

-- This will change in a future version of context. More direct.

local function initializepng(tfmdata,kind,value) -- hm, always value
    if value and otf.pngenabled then
        local png       = tfmdata.properties.png
        local hash      = png and png.hash
        local timestamp = png and png.timestamp
        if not hash then
            return
        end
        local pdffile   = containers.read(otf.pdfcache,hash)
        local pdfshapes = pdffile and pdffile.pdfshapes
        if not pdfshapes or pdffile.timestamp ~= timestamp then
            local pngfile   = containers.read(otf.pngcache,hash)
            local pngshapes = pngfile and pngfile.pngshapes
            pdfshapes = pngshapes and otfpng.topdf(pngshapes) or { }
            containers.write(otf.pdfcache, hash, {
                pdfshapes = pdfshapes,
                timestamp = timestamp,
            })
        end
        --
        pdftovirtual(tfmdata,pdfshapes,"png")
        return true
    end
end

otfregister {
    name         = "sbix",
    description  = "sbix glyphs",
    manipulators = {
        base = initializepng,
        node = initializepng,
    }
}

otfregister {
    name         = "cblc",
    description  = "cblc glyphs",
    manipulators = {
        base = initializepng,
        node = initializepng,
    }
}

if context then

    -- untested in generic and might clash with other color trickery
    -- anyway so let's stick to context only

    local function initializecolor(tfmdata,kind,value)
        if value == "auto" then
            return
                initializeoverlay(tfmdata,kind,value) or
                initializesvg(tfmdata,kind,value) or
                initializepng(tfmdata,kind,value)
        elseif value == "overlay" then
            return initializeoverlay(tfmdata,kind,value)
        elseif value == "svg" then
            return initializesvg(tfmdata,kind,value)
        elseif value == "png" or value == "bitmap" then
            return initializepng(tfmdata,kind,value)
        else
            -- forget about it
        end
    end

    otfregister {
        name         = "color",
        description  = "color glyphs",
        manipulators = {
            base = initializecolor,
            node = initializecolor,
        }
    }

end
