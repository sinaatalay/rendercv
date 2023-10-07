if not modules then modules = { } end modules ['luatex-fonts-syn'] = {
    version   = 1.001,
    comment   = "companion to luatex-*.tex",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

if context then
    os.exit()
end

-- Generic font names support.
--
-- Watch out, the version number is the same as the one used in
-- the mtx-fonts.lua function scripts.fonts.names as we use a
-- simplified font database in the plain solution and by using
-- a different number we're less dependent on context.
--
-- mtxrun --script font --reload --simple
--
-- The format of the file is as follows:
--
-- return {
--     ["version"]       = 1.001,
--     ["cache_version"] = 1.001,
--     ["mappings"]      = {
--         ["somettcfontone"] = { "Some TTC Font One", "SomeFontA.ttc", 1 },
--         ["somettcfonttwo"] = { "Some TTC Font Two", "SomeFontA.ttc", 2 },
--         ["somettffont"]    = { "Some TTF Font",     "SomeFontB.ttf"    },
--         ["someotffont"]    = { "Some OTF Font",     "SomeFontC.otf"    },
--     },
-- }

local fonts = fonts
fonts.names = fonts.names or { }

fonts.names.version  = 1.001 -- not the same as in context but matches mtx-fonts --simple
fonts.names.basename = "luatex-fonts-names"
fonts.names.cache    = containers.define("fonts","data",fonts.names.version,true)

local data           = nil
local loaded         = false

local fileformats    = { "lua", "tex", "other text files" }

function fonts.names.reportmissingbase()
    logs.report("fonts","missing font database, run: mtxrun --script fonts --reload --simple")
    fonts.names.reportmissingbase = nil
end

function fonts.names.reportmissingname()
    logs.report("fonts","unknown font in font database, run: mtxrun --script fonts --reload --simple")
    fonts.names.reportmissingname = nil
end

function fonts.names.resolve(name,sub)
    if not loaded then
        local basename = fonts.names.basename
        if basename and basename ~= "" then
            data = containers.read(fonts.names.cache,basename)
            if not data then
                basename = file.addsuffix(basename,"lua")
                for i=1,#fileformats do
                    local format = fileformats[i]
                    local foundname = resolvers.findfile(basename,format) or ""
                    if foundname ~= "" then
                        data = dofile(foundname)
                        logs.report("fonts","font database '%s' loaded",foundname)
                        break
                    end
                end
            end
        end
        loaded = true
    end
    if type(data) == "table" and data.version == fonts.names.version then
        local condensed = string.gsub(string.lower(name),"[^%a%d]","")
        local found = data.mappings and data.mappings[condensed]
        if found then
            local fontname, filename, subfont = found[1], found[2], found[3]
            if subfont then
                return filename, fontname
            else
                return filename, false
            end
        elseif fonts.names.reportmissingname then
            fonts.names.reportmissingname()
            return name, false -- fallback to filename
        end
    elseif fonts.names.reportmissingbase then
        fonts.names.reportmissingbase()
    end
end

fonts.names.resolvespec = fonts.names.resolve -- only supported in mkiv

function fonts.names.getfilename(askedname,suffix)  -- only supported in mkiv
    return ""
end

function fonts.names.ignoredfile(filename) -- only supported in mkiv
    return false -- will be overloaded
end
