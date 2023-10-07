if not modules then modules = { } end modules ['luatex-fonts-tfm'] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- This is the generic tfm/vf loader. There are no fundamental differences with
-- the one used in ConTeXt but we save some byte(codes) this way.

local next, type = next, type
local match, format = string.match, string.format
local concat, sortedhash = table.concat, table.sortedhash
local idiv = number.idiv

local trace_defining           = false  trackers.register("fonts.defining", function(v) trace_defining = v end)
local trace_features           = false  trackers.register("tfm.features",   function(v) trace_features = v end)

local report_defining          = logs.reporter("fonts","defining")
local report_tfm               = logs.reporter("fonts","tfm loading")

local findbinfile              = resolvers.findbinfile
local setmetatableindex        = table.setmetatableindex

local fonts                    = fonts
local handlers                 = fonts.handlers
local helpers                  = fonts.helpers
local readers                  = fonts.readers
local constructors             = fonts.constructors
local encodings                = fonts.encodings

local tfm                      = constructors.handlers.tfm
tfm.version                    = 1.000
tfm.maxnestingdepth            = 5
tfm.maxnestingsize             = 65536*1024

local otf                      = fonts.handlers.otf
local otfenhancers             = otf.enhancers

local tfmfeatures              = constructors.features.tfm
local registertfmfeature       = tfmfeatures.register

local tfmenhancers             = constructors.enhancers.tfm
local registertfmenhancer      = tfmenhancers.register

local charcommand              = helpers.commands.char

constructors.resolvevirtualtoo = false -- wil be set in font-ctx.lua

fonts.formats.tfm              = "type1" -- we need to have at least a value here
fonts.formats.ofm              = "type1" -- we need to have at least a value here

function tfm.setfeatures(tfmdata,features)
    local okay = constructors.initializefeatures("tfm",tfmdata,features,trace_features,report_tfm)
    if okay then
        return constructors.collectprocessors("tfm",tfmdata,features,trace_features,report_tfm)
    else
        return { } -- will become false
    end
end

local depth = { } -- table.setmetatableindex("number")

local loadtfm = font.read_tfm
local loadvf  = font.read_vf

local function read_from_tfm(specification)
    local filename  = specification.filename
    local size      = specification.size
    depth[filename] = (depth[filename] or 0) + 1
    if trace_defining then
        report_defining("loading tfm file %a at size %s",filename,size)
    end
    local tfmdata = loadtfm(filename,size)
    if tfmdata then

        local features = specification.features and specification.features.normal or { }
        local features = constructors.checkedfeatures("tfm",features)
        specification.features.normal = features

        -- If reencode returns a new table, we assume that we're doing something
        -- special. An 'auto' reencode picks up its vector from the pfb file.

        local newtfmdata = (depth[filename] == 1) and tfm.reencode(tfmdata,specification)
        if newtfmdata then
             tfmdata = newtfmdata
        end

        local resources  = tfmdata.resources  or { }
        local properties = tfmdata.properties or { }
        local parameters = tfmdata.parameters or { }
        local shared     = tfmdata.shared     or { }
        --
        shared.features  = features
        shared.resources = resources
        --
        properties.name       = tfmdata.name           -- todo: fallback
        properties.fontname   = tfmdata.fontname       -- todo: fallback
        properties.psname     = tfmdata.psname         -- todo: fallback
        properties.fullname   = tfmdata.fullname       -- todo: fallback
        properties.filename   = specification.filename -- todo: fallback
        properties.format     = tfmdata.format or fonts.formats.tfm -- better than nothing
        properties.usedbitmap = tfmdata.usedbitmap
        --
        tfmdata.properties = properties
        tfmdata.resources  = resources
        tfmdata.parameters = parameters
        tfmdata.shared     = shared
        --
        shared.rawdata  = { resources = resources }
        shared.features = features
        --
        -- The next branch is only entered when we have a proper encoded file i.e.
        -- unicodes and such. It really nakes no sense to do feature juggling when
        -- we have no names and unicodes.
        --
        if newtfmdata then
            --
            -- Some opentype processing assumes these to be present:
            --
            if not resources.marks then
                resources.marks = { }
            end
            if not resources.sequences then
                resources.sequences = { }
            end
            if not resources.features then
                resources.features = {
                    gsub = { },
                    gpos = { },
                }
            end
            if not tfmdata.changed then
                tfmdata.changed = { }
            end
            if not tfmdata.descriptions then
                tfmdata.descriptions = tfmdata.characters
            end
            --
            -- It might be handy to have this:
            --
            otf.readers.addunicodetable(tfmdata)
            --
            -- We make a pseudo opentype font, e.g. kerns and ligatures etc:
            --
            tfmenhancers.apply(tfmdata,filename)
            --
            -- Now user stuff can kick in.
            --
            constructors.applymanipulators("tfm",tfmdata,features,trace_features,report_tfm)
            --
            -- As that can also mess with names and such, we are now ready for finalizing
            -- the unicode information. This is a different order that for instance type one
            -- (afm) files. First we try to deduce unicodes from already present information.
            --
            otf.readers.unifymissing(tfmdata)
            --
            -- Next we fill in the gaps, based on names from teh agl. Probably not much will
            -- happen here.
            --
            fonts.mappings.addtounicode(tfmdata,filename)
            --
            -- The tounicode data is passed to the backend that constructs the vectors for us.
            --
            tfmdata.tounicode = 1
            local tounicode   = fonts.mappings.tounicode
            for unicode, v in next, tfmdata.characters do
                local u = v.unicode
                if u then
                    v.tounicode = tounicode(u)
                end
            end
            --
            -- However, when we use a bitmap font those vectors can't be constructed because
            -- that information is not carried with those fonts (there is no name info, nor
            -- proper index info, nor unicodes at that end). So, we provide it ourselves.
            --
            if tfmdata.usedbitmap then
                tfm.addtounicode(tfmdata)
            end
        end
        --
        shared.processes = next(features) and tfm.setfeatures(tfmdata,features) or nil
        --
        if size < 0 then
            size = idiv(65536 * -size,100)
        end
        parameters.factor        = 1     -- already scaled
        parameters.units         = 1000  -- just in case
        parameters.size          = size
        parameters.slant         = parameters.slant          or parameters[1] or 0
        parameters.space         = parameters.space          or parameters[2] or 0
        parameters.space_stretch = parameters.space_stretch  or parameters[3] or 0
        parameters.space_shrink  = parameters.space_shrink   or parameters[4] or 0
        parameters.x_height      = parameters.x_height       or parameters[5] or 0
        parameters.quad          = parameters.quad           or parameters[6] or 0
        parameters.extra_space   = parameters.extra_space    or parameters[7] or 0
        --
        constructors.enhanceparameters(parameters) -- official copies for us
        --
        properties.private       =  properties.private or tfmdata.private or privateoffset
        --
        if newtfmdata then
            --
            -- We do nothing as we assume flat tfm files. It would become real messy
            -- otherwise and I don't have something for testing on my system anyway.
            --
        elseif constructors.resolvevirtualtoo then
            fonts.loggers.register(tfmdata,file.suffix(filename),specification) -- strange, why here
            local vfname = findbinfile(specification.name, 'ovf')
            if vfname and vfname ~= "" then
                local vfdata = loadvf(vfname,size)
                if vfdata then
                    local chars = tfmdata.characters
                    for k,v in next, vfdata.characters do
                        chars[k].commands = v.commands
                    end
                    properties.virtualized = true
                    tfmdata.fonts = vfdata.fonts
                    tfmdata.type = "virtual" -- else nested calls with cummulative scaling
                    local fontlist = vfdata.fonts
                    local name = file.nameonly(filename)
                    for i=1,#fontlist do
                        local n = fontlist[i].name
                        local s = fontlist[i].size
                        local d = depth[filename]
                        s = constructors.scaled(s,vfdata.designsize)
                        if d > tfm.maxnestingdepth then
                            report_defining("too deeply nested virtual font %a with size %a, max nesting depth %s",n,s,tfm.maxnestingdepth)
                            fontlist[i] = { id = 0 }
                        elseif (d > 1) and (s > tfm.maxnestingsize) then
                            report_defining("virtual font %a exceeds size %s",n,s)
                            fontlist[i] = { id = 0 }
                        else
                            local t, id = constructors.readanddefine(n,s)
                            fontlist[i] = { id = id }
                        end
                    end
                end
            end
        end
        --
        properties.haskerns     = true
        properties.hasligatures = true
        properties.hasitalics   = true
        resources.unicodes      = { }
        resources.lookuptags    = { }
        --
        depth[filename] = depth[filename] - 1
        --
        return tfmdata
    else
        depth[filename] = depth[filename] - 1
    end
end

local function check_tfm(specification,fullname) -- we could split up like afm/otf
    local foundname = findbinfile(fullname, 'tfm') or ""
    if foundname == "" then
        foundname = findbinfile(fullname, 'ofm') or "" -- not needed in context
    end
    if foundname == "" then
        foundname = fonts.names.getfilename(fullname,"tfm") or ""
    end
    if foundname ~= "" then
        specification.filename = foundname
        specification.format   = "ofm"
        return read_from_tfm(specification)
    elseif trace_defining then
        report_defining("loading tfm with name %a fails",specification.name)
    end
end

readers.check_tfm = check_tfm

function readers.tfm(specification)
    local fullname = specification.filename or ""
    if fullname == "" then
        local forced = specification.forced or ""
        if forced ~= "" then
            fullname = specification.name .. "." .. forced
        else
            fullname = specification.name
        end
    end
    return check_tfm(specification,fullname)
end

readers.ofm = readers.tfm

-- The reencoding acts upon the 'reencode' feature which can have values 'auto' or
-- an enc file. You can also specify a 'pfbfile' feature (but it defaults to the
-- tfm filename) and a 'bitmap' feature. When no enc file is givven (auto) we will
-- get the vectors from the pfb file.

do

    local outfiles = { }

    local tfmcache = table.setmetatableindex(function(t,tfmdata)
        local id = font.define(tfmdata)
        t[tfmdata] = id
        return id
    end)

    local encdone  = table.setmetatableindex("table")

    function tfm.reencode(tfmdata,specification)

        local features = specification.features

        if not features then
            return
        end

        local features = features.normal

        if not features then
            return
        end

        local tfmfile = file.basename(tfmdata.name)
        local encfile = features.reencode -- or features.enc
        local pfbfile = features.pfbfile  -- or features.pfb
        local bitmap  = features.bitmap   -- or features.pk

        if not encfile then
            return
        end

        local pfbfile = outfiles[tfmfile]

        if pfbfile == nil then
            if bitmap then
                pfbfile = false
            elseif type(pfbfile) ~= "string" then
                pfbfile = tfmfile
            end
            if type(pfbfile) == "string" then
                pfbfile = file.addsuffix(pfbfile,"pfb")
             -- pdf.mapline(tfmfile .. "<" .. pfbfile)
                report_tfm("using type1 shapes from %a for %a",pfbfile,tfmfile)
            else
                report_tfm("using bitmap shapes for %a",tfmfile)
                pfbfile = false -- use bitmap
            end
            outfiles[tfmfile] = pfbfile
        end

        local encoding = false
        local vector   = false

        if type(pfbfile) == "string" then
            local pfb = constructors.handlers.pfb
            if pfb and pfb.loadvector then
                local v, e = pfb.loadvector(pfbfile)
                if v then
                    vector = v
                end
                if e then
                    encoding = e
                end
            end
        end
        if type(encfile) == "string" and encfile ~= "auto" then
            encoding = fonts.encodings.load(file.addsuffix(encfile,"enc"))
            if encoding then
                encoding = encoding.vector
            end
        end
        if not encoding then
            report_tfm("bad encoding for %a, quitting",tfmfile)
            return
        end

        local unicoding  = fonts.encodings.agl and fonts.encodings.agl.unicodes
        local virtualid  = tfmcache[tfmdata]
        local tfmdata    = table.copy(tfmdata) -- good enough for small fonts
        local characters = { }
        local originals  = tfmdata.characters
        local indices    = { }
        local parentfont = { "font", 1 }
        local private    = tfmdata.privateoffset or constructors.privateoffset
        local reported   = encdone[tfmfile][encfile]

        -- create characters table

        local backmap = vector and table.swapped(vector)
        local done    = { } -- prevent duplicate

        for index, name in sortedhash(encoding) do -- predictable order
            local unicode  = unicoding[name]
            local original = originals[index]
            if original then
                if unicode then
                    original.unicode = unicode
                else
                    unicode = private
                    private = private + 1
                    if not reported then
                        report_tfm("glyph %a in font %a with encoding %a gets unicode %U",name,tfmfile,encfile,unicode)
                    end
                end
                characters[unicode] = original
                indices[index]      = unicode
                original.name       = name -- so one can lookup weird names
                if backmap then
                    original.index = backmap[name]
                else -- probably bitmap
                    original.commands = { parentfont, charcommand[index] } -- or "slot"
                    original.oindex   = index
                end
                done[name] = true
            elseif not done[name] then
                report_tfm("bad index %a in font %a with name %a",index,tfmfile,name)
            end
        end

        encdone[tfmfile][encfile] = true

        -- redo kerns and ligatures

        for k, v in next, characters do
            local kerns = v.kerns
            if kerns then
                local t = { }
                for k, v in next, kerns do
                    local i = indices[k]
                    if i then
                        t[i] = v
                    end
                end
                v.kerns = next(t) and t or nil
            end
            local ligatures = v.ligatures
            if ligatures then
                local t = { }
                for k, v in next, ligatures do
                    local i = indices[k]
                    if i then
                        t[i] = v
                        v.char = indices[v.char]
                    end
                end
                v.ligatures = next(t) and t or nil
            end
        end

        -- wrap up

        tfmdata.fonts         = { { id = virtualid } }
        tfmdata.characters    = characters
        tfmdata.fullname      = tfmdata.fullname or tfmdata.name
        tfmdata.psname        = file.nameonly(pfbfile or tfmdata.name)
        tfmdata.filename      = pfbfile
        tfmdata.encodingbytes = 2
     -- tfmdata.format        = bitmap and "type3" or "type1"
        tfmdata.format        = "type1"
        tfmdata.tounicode     = 1
        tfmdata.embedding     = "subset"
        tfmdata.usedbitmap    = bitmap and virtualid
        tfmdata.private       = private

        return tfmdata
    end

end

-- This code adds a ToUnicode vector for bitmap fonts. We don't bother about
-- ranges because we have small fonts. it works ok with acrobat but fails with
-- the other viewers (they get confused by the bitmaps I guess).

do

    local template = [[
/CIDInit /ProcSet findresource begin
  12 dict begin
  begincmap
    /CIDSystemInfo << /Registry (TeX) /Ordering (bitmap-%s) /Supplement 0 >> def
    /CMapName /TeX-bitmap-%s def
    /CMapType 2 def
    1 begincodespacerange
      <00> <FF>
    endcodespacerange
    %s beginbfchar
%s
    endbfchar
  endcmap
CMapName currentdict /CMap defineresource pop end
end
end
]]

    local flushstreamobject = lpdf and lpdf.flushstreamobject -- context
    local setfontattributes = lpdf and lpdf.setfontattributes -- context

    if not flushstreamobject then
        flushstreamobject = function(data)
            return pdf.obj { immediate = true, type = "stream", string = data } -- generic
        end
    end

    if not setfontattributes then
        setfontattributes = function(id,data)
            return pdf.setfontattributes(id,data) -- generic
        end
    end

    function tfm.addtounicode(tfmdata)
        local id   = tfmdata.usedbitmap
        local map  = { }
        local char = { } -- no need for range, hardly used
        for k, v in next, tfmdata.characters do
            local index     = v.oindex
            local tounicode = v.tounicode
            if index and tounicode then
                map[index] = tounicode
            end
        end
        for k, v in sortedhash(map) do
            char[#char+1] = format("<%02X> <%s>",k,v)
        end
        char  = concat(char,"\n")
        local stream    = format(template,id,id,#char,char)
        local reference = flushstreamobject(stream,nil,true)
        setfontattributes(id,format("/ToUnicode %i 0 R",reference))
    end

end

-- Now we implement the regular features handlers. We need to convert the
-- tfm specific structures to opentype structures. In basemode they are
-- converted back so that is a bit of a waste but it's fast enough.

do

    local everywhere = { ["*"] = { ["*"] = true } } -- or: { ["*"] = { "*" } }
    local noflags    = { false, false, false, false }

    local function enhance_normalize_features(data)
        local ligatures  = setmetatableindex("table")
        local kerns      = setmetatableindex("table")
        local characters = data.characters
        for u, c in next, characters do
            local l = c.ligatures
            local k = c.kerns
            if l then
                ligatures[u] = l
                for u, v in next, l do
                    l[u] = { ligature = v.char }
                end
                c.ligatures = nil
            end
            if k then
                kerns[u] = k
                for u, v in next, k do
                    k[u] = v -- { v, 0 }
                end
                c.kerns = nil
            end
        end

        for u, l in next, ligatures do
            for k, v in next, l do
                local vl = v.ligature
                local dl = ligatures[vl]
                if dl then
                    for kk, vv in next, dl do
                        v[kk] = vv -- table.copy(vv)
                    end
                end
            end
        end

        local features = {
            gpos = { },
            gsub = { },
        }
        local sequences = {
            -- only filled ones
        }
        if next(ligatures) then
            features.gsub.liga = everywhere
            data.properties.hasligatures = true
            sequences[#sequences+1] = {
                features = {
                    liga = everywhere,
                },
                flags    = noflags,
                name     = "s_s_0",
                nofsteps = 1,
                order    = { "liga" },
                type     = "gsub_ligature",
                steps    = {
                    {
                        coverage = ligatures,
                    },
                },
            }
        end
        if next(kerns) then
            features.gpos.kern = everywhere
            data.properties.haskerns = true
            sequences[#sequences+1] = {
                features = {
                    kern = everywhere,
                },
                flags    = noflags,
                name     = "p_s_0",
                nofsteps = 1,
                order    = { "kern" },
                type     = "gpos_pair",
                steps    = {
                    {
                        format   = "kern",
                        coverage = kerns,
                    },
                },
            }
        end
        data.resources.features  = features
        data.resources.sequences = sequences
        data.shared.resources = data.shared.resources or resources
    end

    registertfmenhancer("normalize features",   enhance_normalize_features)
    registertfmenhancer("check extra features", otfenhancers.enhance)

end

-- As with type one (afm) loading, we just use the opentype ones:

registertfmfeature {
    name         = "mode",
    description  = "mode",
    initializers = {
        base = otf.modeinitializer,
        node = otf.modeinitializer,
    }
}

registertfmfeature {
    name         = "features",
    description  = "features",
    default      = true,
    initializers = {
        base     = otf.basemodeinitializer,
        node     = otf.nodemodeinitializer,
    },
    processors   = {
        node     = otf.featuresprocessor,
    }
}
