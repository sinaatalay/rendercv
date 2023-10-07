if not modules then modules = { } end modules ['luatex-font-enc'] = {
    version   = 1.001,
    comment   = "companion to luatex-*.tex",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

if context then
    os.exit()
end

local fonts     = fonts
local encodings = { }
fonts.encodings = encodings
encodings.agl   = { }
encodings.known = { }

encodings.glyphlistfilename = "font-age.lua"

setmetatable(encodings.agl, { __index = function(t,k)
    if k == "unicodes" then
        logs.report("fonts","loading (extended) adobe glyph list")
        local foundname = resolvers.findfile(encodings.glyphlistfilename) or ""
        local unicodes = foundname ~= "" and dofile(foundname)
        if type(unicodes) ~= "table" then
            logs.report("fonts","missing or invalid (extended) adobe glyph list")
            -- no message
            unicodes = { }
        end
        encodings.agl = { unicodes = unicodes }
        return unicodes
    else
        return nil
    end
end })

-- adapted for generic

encodings.cache = containers.define("fonts", "enc", encodings.version, true)

function encodings.load(filename)
    local name = file.removesuffix(filename)
    local data = containers.read(encodings.cache,name)
    if data then
        return data
    end
    local vector, tag, hash, unicodes = { }, "", { }, { }
    local foundname = resolvers.findfile(filename,'enc')
    if foundname and foundname ~= "" then
        local ok, encoding, size = resolvers.loadbinfile(foundname)
        if ok and encoding then
            encoding = string.gsub(encoding,"%%(.-)\n","")
            local unicoding = encodings.agl.unicodes
            local tag, vec = string.match(encoding,"/(%w+)%s*%[(.*)%]%s*def")
            local i = 0
            for ch in string.gmatch(vec,"/([%a%d%.]+)") do
                if ch ~= ".notdef" then
                    vector[i] = ch
                    if not hash[ch] then
                        hash[ch] = i
                    else
                        -- duplicate, play safe for tex ligs and take first
                    end
                    local u = unicoding[ch]
                    if u then
                        unicodes[u] = i
                    end
                end
                i = i + 1
            end
        end
    end
    local data = {
        name     = name,
        tag      = tag,
        vector   = vector,
        hash     = hash,
        unicodes = unicodes
    }
    return containers.write(encodings.cache, name, data)
end

