-----------------------------------------------------------------------
--         FILE:  luaotfload-diagnostics.lua
--  DESCRIPTION:  part of luaotfload-tool / functionality accessible by the --diagnose option
-- REQUIREMENTS:  luaotfload-tool.lua
--       AUTHOR:  Philipp Gesang <phg@phi-gamma.net>
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-diagnostics",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload-tool submodule / diagnostics",
    license       = "GPL v2.0"
}

local names                    = fonts.names

local kpse                     = require "kpse"
local kpseexpand_path          = kpse.expand_path
local kpseexpand_var           = kpse.expand_var
local kpsefind_file            = kpse.find_file

local lfs                      = require "lfs"
local lfsattributes            = lfs.attributes
local lfsisfile                = lfs.isfile
local lfsreadlink              = lfs.readlink

local md5                      = require "md5"
local md5sumhexa               = md5.sumhexa

local ioopen                   = io.open

local osgetenv                 = os.getenv
local osname                   = os.name
local osremove                 = os.remove
local ostype                   = os.type
local stringformat             = string.format
local stringlower              = string.lower
local stringsub                = string.sub

local fileisreadable           = file.isreadable
local fileiswritable           = file.iswritable
local filesplitpath            = file.splitpath
local filesuffix               = file.suffix
local ioloaddata               = io.loaddata
local lua_of_json              = utilities.json.tolua
local tableconcat              = table.concat
local tablesortedkeys          = table.sortedkeys
local tabletohash              = table.tohash

local lpeg                     = require "lpeg"
local C, Cg, Ct                = lpeg.C, lpeg.Cg, lpeg.Ct
local lpegmatch                = lpeg.match

local report                   = luaotfload.log.report
local function out (...)
    report (false, 0, "diagnose", ...)
end

local parsers                  = luaotfload.parsers
local stripslashes             = parsers.stripslashes
local splitcomma               = parsers.splitcomma

local function check_index (errcnt)

    out "================= font names =================="
    local namedata = names.data()

    if not namedata then
        namedata = names.load ()
    end

    local mappings = namedata.mappings

    if not namedata and namedata.formats and namedata.version then
        out "Database corrupt."
        return errcnt + 1
    end

    out ("Database version: %.3f.", namedata.meta.version)
    out ("Font formats indexed: %s.",
         tableconcat (namedata.meta.formats, ", "))
    out ("%d font files indexed.", #mappings)

    local by_format = { }
    for i = 1, #mappings do
        local record = mappings[i]
        local format = stringlower (filesuffix (record.filename))
        local count  = by_format[format]
        if count then
            by_format[format] = count + 1
        else
            by_format[format] = 1
        end
    end

    local formats = tablesortedkeys (by_format)
    for i = 1, #formats do
        local format = formats[i]
        out ("%20s: %5d", format, by_format[format])
    end
    return errcnt
end

local function verify_files (errcnt)
    out "================ verify files ================="
    local status = config.luaotfload.status
    local hashes = status.hashes
    local notes  = status.notes
    if not hashes or #hashes == 0 then
        out ("FAILED: cannot read checksums from %s.", status_file)
        return 1/0
    elseif not notes then
        out ("FAILED: cannot read commit metadata from %s.",
             status_file)
        return 1/0
    end

    out ("Luaotfload revision %s.", notes.revision)
    out ("Committed by %s.",        notes.committer)
    out ("Timestamp %s.",           notes.timestamp)

    local nhashes = #hashes
    out ("Testing %d files for integrity.", nhashes)
    for i = 1, nhashes do
        local fname, canonicalsum = unpack (hashes[i])
        local location = kpsefind_file (fname)
                      or kpsefind_file (fname, "texmfscripts")
        if not location then
            errcnt = errcnt + 1
            out ("FAILED: file %s missing.", fname)
        else
            out ("File: %s.", location)
            local raw = ioloaddata (location)
            if not raw then
                errcnt = errcnt + 1
                out ("FAILED: file %d not readable.", fname)
            else
                local sum = md5sumhexa (raw)
                if sum ~= canonicalsum then
                    errcnt = errcnt + 1
                    out ("FAILED: checksum mismatch for file %s.",
                         fname)
                    out ("Expected %s.", canonicalsum)
                    out ("Got      %s.", sum)
                else
                    out ("Ok, %s passed.", fname)
                end
            end
        end
    end
    return errcnt
end

local function get_tentative_attributes (file)
    if not lfsisfile (file) then
        local chan = ioopen (file, "w")
        if chan then
            chan:close ()
            local attributes = lfsattributes (file)
            os.remove (file)
            return attributes
        end
    end
end

local p_permissions = Ct(Cg(Ct(C(1) * C(1) * C(1)), "u")
                       * Cg(Ct(C(1) * C(1) * C(1)), "g")
                       * Cg(Ct(C(1) * C(1) * C(1)), "o"))

local function analyze_permissions (raw)
    return lpegmatch (p_permissions, raw)
end

local function get_permissions (t, location)
    if stringsub (location, #location) == "/" then
        --- strip trailing slashes (lfs idiosyncrasy on Win)
        location = lpegmatch (stripslashes, location)
    end
    local attributes = lfsattributes (location)
    if not attributes then
        print""
        print("attr", location, attributes)
        os.exit()
    end

    if not attributes and t == "f" then
        attributes = get_tentative_attributes (location)
        if not attributes then
            return false
        end
    end

    local permissions

    if fileisreadable (location) then
        --- link handling appears to be unnecessary because
        --- lfs.attributes() will return the information on
        --- the link target.
        if mode == "link" then --follow and repeat
            location = lfsreadlink (location)
            attributes = lfsattributes (location)
        end
    end

    permissions = analyze_permissions (attributes.permissions)

    return {
        location    = location,
        mode        = attributes.mode,
        owner       = attributes.uid, --- useless on windows
        permissions = permissions,
        attributes  = attributes,
    }
end

local function check_conformance (spec, permissions, errcnt)
    local uid = permissions.attributes.uid
    local gid = permissions.attributes.gid
    local raw = permissions.attributes.permissions

    out ("Owner: %d, group %d, permissions %s.", uid, gid, raw)
    if ostype == "unix" then
        if uid == 0 or gid == 0 then
            out "Owned by the superuser, permission conflict likely."
            errcnt = errcnt + 1
        end
    end

    local user = permissions.permissions.u
    if spec.r == true then
        if user[1] == "r" then
            out "Readable: ok."
        else
            out "Not readable: permissions need fixing."
            errcnt = errcnt + 1
        end
    end

    if spec.w == true then
        if user[2] == "w"
        or  fileiswritable (permissions.location) then
            out "Writable: ok."
        else
            out "Not writable: permissions need fixing."
            errcnt = errcnt + 1
        end
    end

    return errcnt
end

local function init_desired_permissions ()
    local paths = config.luaotfload.paths
    return {
        { "d", {"r","w"}, function () return caches.getwritablepath ("", "") end },
        { "d", {"r","w"}, paths.prefix },
        { "f", {"r","w"}, paths.index_path_lua .. ".gz" },
        { "f", {"r","w"}, paths.index_path_luc },
        { "f", {"r","w"}, paths.lookup_path_lua },
        { "f", {"r","w"}, paths.lookup_path_luc },
    }
end

local function check_permissions (errcnt)
    out [[=============== file permissions ==============]]
    local desired_permissions = init_desired_permissions ()
    for i = 1, #desired_permissions do
        local t, spec, path = unpack (desired_permissions[i])
        if type (path) == "function" then
            path = path ()
        end

        spec = tabletohash (spec)

        out ("Checking permissions of %s.", path)

        local permissions = get_permissions (t, path)
        if permissions then
            --inspect (permissions)
            errcnt = check_conformance (spec, permissions, errcnt)
        else
            errcnt = errcnt + 1
        end
    end
    return errcnt
end

local check_upstream

if kpsefind_file ("https.lua", "lua") == nil then
    function check_upstream (errcnt)
        out       [[============= upstream repository =============
                    WARNING: Cannot retrieve repository data.
                    Github API access requires the luasec library.
                    Grab it from <https://github.com/brunoos/luasec>
                    and retry.]]
        return errcnt
    end
else
--- github api stuff begin
    local https = require "ssl.https"

    local gh_api_root     = [[https://api.github.com]]
    local release_url     = [[https://github.com/latex3/luaotfload/releases]]
    local luaotfload_repo = [[latex3/luaotfload]]
    local user_agent      = [[latex3/luaotfload integrity check]]
    local shortbytes = 8

    local function gh_shortrevision (rev)
        return stringsub (rev, 1, shortbytes)
    end

    local function gh_encode_parameters (parameters)
        local acc = {}
        for field, value in next, parameters do
            --- unsafe, non-urlencoded coz it’s all ascii chars
            acc[#acc+1] = field .. "=" .. value
        end
        return "?" .. tableconcat (acc, "&")
    end

    local function gh_make_url (components, parameters)
        local url = tableconcat ({ gh_api_root,
                                   unpack (components) },
                                 "/")
        if parameters then
            url = url .. gh_encode_parameters (parameters)
        end
        return url
    end

    local alright = [[HTTP/1.1 200 OK]]

    local function gh_api_request (...)
        local args    = {...}
        local nargs   = #args
        local final   = args[nargs]
        local request = {
            url     = "",
            headers = { ["user-agent"] = user_agent },
        }
        if type (final) == "table" then
            args[nargs] = nil
            request = gh_make_url (args, final)
        else
            request = gh_make_url (args)
        end

        out ("Requesting <%s>.", request)
        local response, code, headers, status = https.request (request)
        if status ~= alright then
            out "Request failed!"
            return false
        end
        return response
    end

    local function gh_api_checklimit (headers)
        local rawlimit  = gh_api_request "rate_limit"
        local limitdata = lua_of_json (rawlimit)
        if not limitdata and limitdata.rate then
            out "Cannot parse API rate limit."
            return false
        end
        limitdata = limitdata.rate

        local limit = tonumber (limitdata.limit)
        local left  = tonumber (limitdata.remaining)
        local reset = tonumber (limitdata.reset)

        out ("%d of %d Github API requests left.", left, limit)
        if left == 0 then
            out ("Cannot make any more API requests.")
            if ostype == "unix" then
                out ("Try again later at %s.", osdate ("%F %T", reset))
            else --- windows doesn’t C99
                out ("Try again later at %s.",
                     osdate ("%Y-%m-%d %H:%M:%S", reset))
            end
        end
        return true
    end

    local function gh_tags ()
        out "Fetching tags from repository, please stand by."
        local rawtags = gh_api_request ("repos",
                                        luaotfload_repo,
                                        "tags")
        local taglist = lua_of_json (rawtags)
        if not taglist or #taglist == 0 then
            out "Cannot parse response."
            return false
        end

        local ntags = #taglist
        out ("Repository contains %d tags.", ntags)
        local _idx, latest = next (taglist)
        out ("The most recent release is %s (revision %s).",
             latest.name,
        gh_shortrevision (latest.commit.sha))
        return latest
    end

    local function gh_compare (head, base)
        if base == nil then
            base = "HEAD"
        end
        out ("Fetching comparison between %s and %s, \z
              please stand by.",
             gh_shortrevision (head),
             gh_shortrevision (base))
        local comparison = base .. "..." .. head
        local rawstatus = gh_api_request ("repos",
                                          luaotfload_repo,
                                          "compare",
                                          comparison)
        local status = lua_of_json (rawstatus)
        if not status then
            out "Cannot parse response for status request."
            return false
        end
        return status
    end

    local function gh_news (since)
        local compared  = gh_compare (since)
        if not compared then
            return false
        end
        local behind_by = compared.behind_by
        local ahead_by  = compared.ahead_by
        local status    = compared.status
        out ("Comparison state: %s.", status)
        if behind_by > 0 then
            out ("Your Luaotfload is %d \z
                  revisions behind upstream.",
                 behind_by)
            return behind_by
        elseif status == "ahead" then
            out "Since you are obviously from the future \z
                 I assume you already know the repository state."
        else
            out "Everything up to date. \z
                 Luaotfload is in sync with upstream."
        end
        return false
    end

    local function gh_catchup (current, latest)
        local compared = gh_compare (latest, current)
        local ahead_by = tonumber (compared.ahead_by)
        if ahead_by > 0 then
            local permalink_url = compared.permalink_url
            out ("Your Luaotfload is %d revisions \z
                  behind the most recent release.",
                 ahead_by)
            out ("To view the commit log, visit <%s>.",
                 permalink_url)
            out ("You can grab an up to date tarball at <%s>.",
                 release_url)
            return true
        else
            out "There weren't any new releases in the meantime."
            out "Luaotfload is up to date."
        end
        return false
    end

    function check_upstream (current)
        out "============= upstream repository ============="
        local _succ  = gh_api_checklimit ()
        local behind = gh_news (current)
        if behind then
            local latest  = gh_tags ()
            local _behind = gh_catchup (current,
                                        latest.commit.sha,
                                        latest.name)
        end
    end

    --- trivium: diff since the first revision as pushed by Élie
    --- in 2009
    --- local firstrevision = "c3ccb3ee07e0a67171c24960966ae974e0dd8e98"
    --- check_upstream (firstrevision)
end
--- github api stuff end

local function print_envvar (var)
    local val = osgetenv (var)
    if val then
        out ("%20s: %q", stringformat ("$%s", var), val)
        return val
    else
        out ("%20s: <unset>", stringformat ("$%s", var))
    end
end

local function print_path (var)
    local val = osgetenv (var)
    if val then
        local paths = filesplitpath (val)
        if paths then
            local npaths = #paths
            if npaths == 1 then
                out ("%20s: %q", stringformat ("$%s", var), val)
            elseif npaths > 1 then
                out ("%20s: <%d items>", stringformat ("$%s", var), npaths)
                for i = 1, npaths do
                    out ("                   +: %q", paths[i])
                end
            else
                out ("%20s: <empty>")
            end
        end
    else
        out ("%20s: <unset>", stringformat ("$%s", var))
    end
end

local function print_kpsevar (var)
    var = "$" .. var
    local val = kpseexpand_var (var)
    if val and val ~= var then
        out ("%20s: %q", var, val)
        return val
    else
        out ("%20s: <empty or unset>", var)
    end
end

local function print_kpsepath (var)
    var = "$" .. var
    local val = kpseexpand_path (var)
    if val and val ~= "" then
        local paths = filesplitpath (val)
        if paths then
            local npaths = #paths
            if npaths == 1 then
                out ("%20s: %q", var, paths[1])
            elseif npaths > 1 then
                out ("%20s: <%d items>", var, npaths)
                for i = 1, npaths do
                    out ("                   +: %q", paths[i])
                end
            else
                out ("%20s: <empty>")
            end
        end
    else
        out ("%20s: <empty or unset>", var)
    end
end

--- this test first if a variable is set and then expands the
--- paths; this is necessitated by the fact that expand-path will
--- return the empty string both if the variable is unset and if
--- the directory does not exist

local function print_kpsepathvar (var)
    local vvar = "$" .. var
    local val = kpseexpand_var (vvar)
    if val and val ~= vvar then
        out ("%20s: %q", vvar, val)
        print_kpsepath (var)
    else
        out ("%20s: <empty or unset>", var)
    end
end

local function check_environment (errcnt)
    out "============ environment settings ============="
    out ("system: %s/%s", ostype, osname)
    if ostype == "unix" and io.popen then
        local chan = io.popen ("uname -a", "r")
        if chan then
            out ("info: %s", chan:read "*all")
            chan:close ()
        end
    end

    out "1) *shell environment*"
    print_envvar "SHELL"
    print_path "PATH"
    print_path "OSFONTDIR"
    print_envvar "USER"
    if ostype == "windows" then
        print_envvar "WINDIR"
        print_envvar "CD"
        print_path "TEMP"
    elseif ostype == "unix" then
        print_envvar "HOME"
        print_envvar "PWD"
        print_path "TMPDIR"
    end

    out "2) *kpathsea*"
    print_kpsepathvar "OPENTYPEFONTS"
    print_kpsepathvar "TTFONTS"

    print_kpsepathvar "TEXMFCACHE"
    print_kpsepathvar "TEXMFVAR"

    --- the expansion of these can be quite large; as they aren’t
    --- usually essential to luaotfload, we won’t dump every single
    --- path
    print_kpsevar "LUAINPUTS"
    print_kpsevar "CLUAINPUTS"

    return errcnt
end

local anamneses   = {
    "environment",
    "files",
    "index",
    "repository",
    "permissions"
}

local function diagnose (job)
    local errcnt = 0
    local asked  = job.asked_diagnostics
    if asked == "all" or asked == "thorough" then
        asked = tabletohash (anamneses, true)
    else
        asked = lpegmatch (splitcomma, asked)
        asked = tabletohash (asked, true)
    end

    if asked.index == true then
        errcnt = check_index (errcnt)
        asked.index = nil
    end

    if asked.environment == true then
        errcnt = check_environment (errcnt)
        asked.environment = nil
    end

    if asked.files == true then
        errcnt = verify_files (errcnt)
        asked.files = nil
    end

    if asked.permissions == true then
        errcnt = check_permissions (errcnt)
        asked.permissions = nil
    end

    if asked.repository == true then
        local status = config.luaotfload.status
        check_upstream (status.notes.revision)
        asked.repository = nil
    end

    local rest = next (asked)
    if rest ~= nil then --> something unknown
        out ("Unknown diagnostic %q.", rest)
    end
    if errcnt == 0 then --> success
        out ("Everything appears to be in order, \z
              you may sleep well.")
        return true, false
    end
    out (             [[===============================================
                                            WARNING
                        ===============================================

                        The diagnostic detected %d errors.

                        This version of luaotfload may have been
                        tampered with. Modified versions of the
                        luaotfload source are unsupported. Read the log
                        carefully and get a clean version from CTAN or
                        github:

                            × http://www.ctan.org/pkg/luaotfload 
                            × https://github.com/latex3/luaotfload/releases

                        If you are uncertain as to how to proceed, then
                        ask on the lualatex mailing list:

                            http://www.tug.org/mailman/listinfo/lualatex-dev

                        ===============================================
]],          errcnt)
    return true, false
end

return diagnose

-- vim:tw=71:sw=4:ts=4:expandtab
