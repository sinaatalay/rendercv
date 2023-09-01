-----------------------------------------------------------------------
--         FILE:  luaotfload-resolvers.lua
--        USAGE:  ./luaotfload-resolvers.lua 
--  DESCRIPTION:  Resolvers for hooking into the fontloader
-- REQUIREMENTS:  Luaotfload and a decent bit of courage
--       AUTHOR:  Philipp Gesang (Phg), <phg@phi-gamma.net>
-----------------------------------------------------------------------
--
--- The bare fontloader uses a set of simplistic file name resolvers
--- that must be overloaded by the user (i. e. us).

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-resolvers",
    version       = "3.24",       --TAGVERSION
    date          = "2023-08-19", --TAGDATE
    description   = "luaotfload submodule / resolvers",
    license       = "GPL v2.0"
}

if not lualibs    then error "this module requires Luaotfload" end
if not luaotfload then error "this module requires Luaotfload" end

--[[doc--

    Relying on the \verb|name:| resolver for everything has been the
    source of permanent trouble with the database.
    With the introduction of the new syntax parser we now have enough
    granularity to distinguish between the \XETEX emulation layer and
    the genuine \verb|name:| and \verb|file:| lookups of \LUATEX-Fonts.
    Another benefit is that we can now easily plug in or replace new
    lookup behaviors if necessary.
    The name resolver remains untouched, but it calls
    \luafunction{fonts.names.resolve()} internally anyways (see
    \fileent{luaotfload-database.lua}).

--doc]]--

local next                = next
local tableconcat         = table.concat
local kpsefind_file       = kpse.find_file
local lfsisfile           = lfs.isfile
local stringlower         = string.lower
local stringformat        = string.format
local filesuffix          = file.suffix
local fileremovesuffix    = file.removesuffix
local luatexbase          = luatexbase
local logreport           = luaotfload.log.report

--[[doc--

    \identifier{luaotfload} promises easy access to system fonts.
    Without additional precautions, this cannot be achieved by
    \identifier{kpathsea} alone, because it searches only the
    \fileent{texmf} directories by default.
    Although it is possible for \identifier{kpathsea} to include extra
    paths by adding them to the \verb|OSFONTDIR| environment variable,
    this is still short of the goal »\emphasis{it just works!}«.
    When building the font database \identifier{luaotfload} scans
    system font directories anyways, so we already have all the
    information for looking sytem fonts.
    With the release version 2.2 the file names are indexed in the
    database as well and we are ready to resolve \verb|file:| lookups
    this way.
    Thus we no longer need to call the \identifier{kpathsea} library in
    most cases when looking up font files, only when generating the
    database, and when verifying the existence of a file in the
    \fileent{texmf} tree.

--doc]]--

local function resolve_file (specification)
    local name, _format, success = fonts.names.lookup_font_file (specification.name)
    if success then return name end
    logreport ("log", 1, "resolve", "file lookup of %q unsuccessful", name)
end

--[[doc--

    Prior to version 2.2, \identifier{luaotfload} did not distinguish
    \verb|file:| and \verb|path:| lookups, causing complications with
    the resolver.
    Now we test if the requested name is an absolute path in the file
    system, otherwise we fall back to the \verb|file:| lookup.

--doc]]--

local function resolve_path (specification)
    local name = specification.name
    if lfsisfile (name) then return name end
    logreport ("log", 1, "resolve",
               "path lookup of %q unsuccessful, falling back to file:",
               name)
    return resolve_file (specification)
end

--[[doc--

    The \verb|name:| resolver.

--doc]]--

--- fonts.names.resolvers.name -- Customized version of the
--- generic name resolver.

local function resolve_name (specification)
    local resolver = fonts.names.lookup_font_name_cached
    if config.luaotfload.run.resolver == "normal" then
        resolver = fonts.names.lookup_font_name
    end
    local resolved, subfont = resolver (specification)
    if resolved then
        logreport ("log", 1, "resolve", "name lookup %q -> %q",
                   specification.name, resolved ..
                   (subfont and stringformat ("(%d)", subfont) or ""))
        return resolved, tonumber(subfont)
    end
    return resolve_file (specification)
end

--[[doc--

    We classify as \verb|anon:| those requests that have neither a
    prefix nor brackets. According to Khaled\footnote{%
        % XXX dead link‽
        \url{https://github.com/phi-gamma/luaotfload/issues/4#issuecomment-17090553}.
    }
    they are the \XETEX equivalent of a \verb|name:| request, so we
    will be treating them as such or, at least, in a similar fashion.

    Not distinguishing between “anon” and “name” requests has a serious
    drawback: The syntax is overloaded for requesting fonts in
    \identifier{Type1} (\abbrev{tfm}, \abbrev{ofm}) format.
    These are essentially \verb|file:| lookups and must be caught
    before the \verb|name:| resolver kicks in, lest they cause the
    database to update.
    Even if we were to require the \verb|file:| prefix for all
    \identifier{Type1} requests, tests have shown that certain fonts
    still include further fonts (e.~g. \fileent{omlgcb.ofm} will ask
    for \fileent{omsecob.tfm}) \emphasis{using the old syntax}.
    For this reason, we introduce an extra check with an early return.

--doc]]--

local tex_formats = { "tfm", "ofm" }

local resolvers_findfile = luaotfload.fontloader.resolvers.findfile
local function resolve_tex_format (specification)
    local name = specification.name
    for i=1, #tex_formats do
        local format = tex_formats [i]
        local name = name
        if name:sub(-#format-1) ~= '.' .. format then -- Add an explicit extension to avoid finding local fonts in other formats
            name = name .. '.' .. format
        end
        local resolved = resolvers_findfile(name, format)
        if resolved then
            return resolved, format
        end
    end
end

local function resolve_path_if_exists (specification)
    local spec = specification.specification
    local exists = lfsisfile (spec)
    if exists then
        --- If this path is taken a file matching the specification
        --- literally was found. In this situation, Luaotfload is
        --- expected to load that file directly, even though we provide
        --- explicit “file” and “path” lookups to address exactly this
        --- situation.
        logreport ("log", 1, "resolve",
                   "file %q exists, performing path lookup", spec)
        return spec
    end
end

--[[doc--
    Custom file resolvers via callback.
--doc]]--

local function resolve_my (specification)
    return luatexbase.call_callback ("luaotfload.resolve_font", specification)
end

local resolve_methods = {
    tex  = resolve_tex_format,
    path = resolve_path_if_exists,
    name = resolve_name,
    file = resolve_file,
    my   = resolve_my,
}

local function resolve_sequence (seq, specification)
    for i = 1, #seq do
        local id  = seq [i]
        local mth = resolve_methods [id]
        if not mth then
            logreport ("both", 0, "resolve",
                       "step %d: invalid lookup method %q", i, id)
        else
            logreport ("both", 3, "resolve", "step %d: apply method %q (%s)", i, id, mth)
            local result, t = mth (specification)
            if result then
                logreport ("both", 3, "resolve",
                           "%d: method %q resolved %q -> %s.",
                           i, id, specification.specification, result)
                return result, t
            end
        end
    end
    logreport ("both", 0, "resolve",
               "sequence of %d lookups yielded nothing appropriate.", #seq)
end

local default_anon_sequence = {
    "tex", "path", "name",
}

local function resolve_anon (specification)
    return resolve_sequence (config.luaotfload.run.anon_sequence, specification)
end

--[[doc--

    {\bfseries EXPERIMENTAL}:
    \identifier{kpse}-only resolver, for those who can do without
    system fonts.

--doc]]--

local function resolve_kpse (specification)
    local name       = specification.name
    local suffix     = stringlower (filesuffix (name))
    if suffix and fonts.formats[suffix] then
        local resolved = resolvers_findfile(name, suffix)
        if resolved then return resolved end
    end
    for _, t in ipairs{'otf', 'ttf', 'pfb', 'lua', 'afm'} do --- brute force
        local resolved = resolvers_findfile (name, t)
        if resolved then return resolved, t end
    end
end

local lookup_subfont_index = fonts.names.lookup_subfont_index
local function wrap_resolver(resolver)
    return function (specification)
        local filename, sub, forced = resolver(specification)
        if type(sub) ~= "number" then
            forced = sub
            sub = nil
        end
        if filename then
            specification.resolved = filename
            specification.filename = filename
            specification.name = filename
            specification.sub = sub or specification.sub
            if type(specification.sub) == "string" then
                specification.sub =
                    lookup_subfont_index(filename, specification.sub)
            end
            specification.forced = specification.forced or forced
            if not specification.forced then
                local suffix = stringlower (filesuffix (filename))
                if suffix and fonts.formats[suffix] then
                    specification.forced = suffix
                end
            end
            if specification.forced then
                specification.forcedname = filename
            end
            return true
        end
        return false
    end
end

local resolvers = table.merge(luaotfload.resolvers, {
    path = resolve_path,
    name = resolve_name,
    anon = resolve_anon,
    file = resolve_file,
    kpse = resolve_kpse,
    my   = resolve_my,
})
luaotfload.resolvers = resolvers

return function()
    if luatexbase and luatexbase.create_callback then
        luatexbase.create_callback ("luaotfload.resolve_font",
                                    "exclusive", function () end)
    end
    logreport ("log", 5, "resolvers", "installing font resolvers", name)
    local request_resolvers = fonts.definers.resolvers
    for k, _ in pairs(request_resolvers) do
        request_resolvers[k] = nil
    end
    setmetatable(request_resolvers, {__index = function(t, n)
        if not resolvers[n] then return end
        local wrapped = wrap_resolver(resolvers[n])
        t[n] = wrapped
        return wrapped
    end})
    fonts.formats.ofm      = "type1"
    fonts.encodings        = fonts.encodings       or { }
    fonts.encodings.known  = fonts.encodings.known or { }
    return true
end
--- vim:ft=lua:ts=8:sw=4:et:tw=79
