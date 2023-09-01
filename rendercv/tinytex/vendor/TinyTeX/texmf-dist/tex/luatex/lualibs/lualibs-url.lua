if not modules then modules = { } end modules ['l-url'] = {
    version   = 1.001,
    comment   = "companion to luat-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

local char, format, byte = string.char, string.format, string.byte
local concat = table.concat
local tonumber, type, next = tonumber, type, next
local P, C, R, S, Cs, Cc, Ct, Cf, Cg, V = lpeg.P, lpeg.C, lpeg.R, lpeg.S, lpeg.Cs, lpeg.Cc, lpeg.Ct, lpeg.Cf, lpeg.Cg, lpeg.V
local lpegmatch, lpegpatterns, replacer = lpeg.match, lpeg.patterns, lpeg.replacer
local sortedhash = table.sortedhash

-- from wikipedia:
--
--   foo://username:password@example.com:8042/over/there/index.dtb?type=animal;name=narwhal#nose
--   \_/   \_______________/ \_________/ \__/            \___/ \_/ \______________________/ \__/
--    |           |               |       |                |    |            |                |
--    |       userinfo         hostname  port              |    |          query          fragment
--    |    \________________________________/\_____________|____|/
-- scheme                  |                          |    |    |
--    |                authority                    path   |    |
--    |                                                    |    |
--    |            path                       interpretable as filename
--    |   ___________|____________                              |
--   / \ /                        \                             |
--   urn:example:animal:ferret:nose               interpretable as extension
--
-- also nice: http://url.spec.whatwg.org/ (maybe some day ...)

url       = url or { }
local url = url

local unescapes = { }
local escapes   = { }

setmetatable(unescapes, { __index = function(t,k)
    local v = char(tonumber(k,16))
    t[k] = v
    return v
end })

setmetatable(escapes, { __index = function(t,k)
    local v = format("%%%02X",byte(k))
    t[k] = v
    return v
end })

-- okay:

local colon       = P(":")
local qmark       = P("?")
local hash        = P("#")
local slash       = P("/")
local atsign      = P("@")
local percent     = P("%")
local endofstring = P(-1)
local hexdigit    = R("09","AF","af")
local plus        = P("+")
local nothing     = Cc("")
local okay        = R("09","AZ","az") + S("-_.,:=+*~!'()@&$")

local escapedchar   = (percent * C(hexdigit * hexdigit)) / unescapes
local unescapedchar = P(1) / escapes
local escaped       = (plus / " ") + escapedchar -- so no loc://foo++.tex
local noslash       = P("/") / ""
local plustospace   = P("+")/" "

local decoder = Cs( (
                    plustospace
                  + escapedchar
                  + P("\r\n")/"\n"
                  + P(1)
                )^0 )
local encoder = Cs( (
                    R("09","AZ","az")^1
                  + S("-./_")^1
                  + P(" ")/"+"
                  + P("\n")/"\r\n"
                  + unescapedchar
                )^0 )

lpegpatterns.urldecoder = decoder
lpegpatterns.urlencoder = encoder

function url.decode  (str) return str and lpegmatch(decoder,  str) or str end
function url.encode  (str) return str and lpegmatch(encoder,  str) or str end
function url.unescape(str) return str and lpegmatch(unescaper,str) or str end

-- we assume schemes with more than 1 character (in order to avoid problems with windows disks)
-- we also assume that when we have a scheme, we also have an authority
--
-- maybe we should already split the query (better for unescaping as = & can be part of a value

local schemestr    = Cs((escaped+(1-colon-slash-qmark-hash))^2)
local authoritystr = Cs((escaped+(1-      slash-qmark-hash))^0)
local pathstr      = Cs((escaped+(1-            qmark-hash))^0)
----- querystr     = Cs((escaped+(1-                  hash))^0)
local querystr     = Cs((        (1-                  hash))^0)
local fragmentstr  = Cs((escaped+(1-           endofstring))^0)

local scheme    =                 schemestr    * colon + nothing
local authority = slash * slash * authoritystr         + nothing
local path      = slash         * pathstr              + nothing
local query     = qmark         * querystr             + nothing
local fragment  = hash          * fragmentstr          + nothing

local validurl  = scheme * authority * path * query * fragment
local parser    = Ct(validurl)

lpegpatterns.url         = validurl
lpegpatterns.urlsplitter = parser

local escaper    = Cs((R("09","AZ","az")^1 + P(" ")/"%%20" + S("-./_:")^1 + P(1) / escapes)^0) -- space happens most
local unescaper  = Cs((escapedchar + 1)^0)
local getcleaner = Cs((P("+++")/"%%2B" + P("+")/"%%20" + P(1))^1)

lpegpatterns.urlunescaped  = escapedchar
lpegpatterns.urlescaper    = escaper
lpegpatterns.urlunescaper  = unescaper
lpegpatterns.urlgetcleaner = getcleaner

function url.unescapeget(str)
    return lpegmatch(getcleaner,str)
end

-- todo: reconsider Ct as we can as well have five return values (saves a table)
-- so we can have two parsers, one with and one without

local function split(str)
    return (type(str) == "string" and lpegmatch(parser,str)) or str
end

local isscheme = schemestr * colon * slash * slash -- this test also assumes authority

local function hasscheme(str)
    if str then
        local scheme = lpegmatch(isscheme,str) -- at least one character
        return scheme ~= "" and scheme or false
    else
        return false
    end
end

--~ print(hasscheme("home:"))
--~ print(hasscheme("home://"))

-- todo: cache them

local rootletter       = R("az","AZ")
                       + S("_-+")
local separator        = P("://")
local qualified        = P(".")^0 * P("/")
                       + rootletter * P(":")
                       + rootletter^1 * separator
                       + rootletter^1 * P("/")
local rootbased        = P("/")
                       + rootletter * P(":")

local barswapper       = replacer("|",":")
local backslashswapper = replacer("\\","/")

-- queries:

local equal = P("=")
local amp   = P("&")
local key   = Cs(((plustospace + escapedchar + 1) - equal              )^0)
local value = Cs(((plustospace + escapedchar + 1) - amp   - endofstring)^0)

local splitquery = Cf ( Ct("") * P { "sequence",
    sequence = V("pair") * (amp * V("pair"))^0,
    pair     = Cg(key * equal * value),
}, rawset)

-- hasher

local userpart       = (1-atsign-colon)^1
local serverpart     = (1-colon)^1
local splitauthority = ((Cs(userpart) * colon * Cs(userpart) + Cs(userpart) * Cc(nil)) * atsign + Cc(nil) * Cc(nil))
                     * Cs(serverpart) * (colon * (serverpart/tonumber) + Cc(nil))

local function hashed(str) -- not yet ok (/test?test)
    if not str or str == "" then
        return {
            scheme   = "invalid",
            original = str,
        }
    end
    local detailed   = split(str)
    local rawscheme  = ""
    local rawquery   = ""
    local somescheme = false
    local somequery  = false
    if detailed then
        rawscheme  = detailed[1]
        rawquery   = detailed[4]
        somescheme = rawscheme ~= ""
        somequery  = rawquery  ~= ""
    end
    if not somescheme and not somequery then
        return {
            scheme    = "file",
            authority = "",
            path      = str,
            query     = "",
            fragment  = "",
            original  = str,
            noscheme  = true,
            filename  = str,
        }
    end
    -- not always a filename but handy anyway
    local authority = detailed[2]
    local path      = detailed[3]
    local filename  -- = nil
    local username  -- = nil
    local password  -- = nil
    local host      -- = nil
    local port      -- = nil
    if authority ~= "" then
        -- these can be invalid
        username, password, host, port = lpegmatch(splitauthority,authority)
    end
    if authority == "" then
        filename = path
    elseif path == "" then
        filename = ""
    else
        -- this one can be can be invalid
        filename = authority .. "/" .. path
    end
    return {
        scheme    = rawscheme,
        authority = authority,
        path      = path,
        query     = lpegmatch(unescaper,rawquery),  -- unescaped, but possible conflict with & and =
        queries   = lpegmatch(splitquery,rawquery), -- split first and then unescaped
        fragment  = detailed[5],
        original  = str,
        noscheme  = false,
        filename  = filename,
        --
        host      = host,
        port      = port,
     -- usename   = username,
     -- password  = password,
    }
end

-- inspect(hashed())
-- inspect(hashed(""))
-- inspect(hashed("template:///test"))
-- inspect(hashed("template:///test++.whatever"))
-- inspect(hashed("template:///test%2B%2B.whatever"))
-- inspect(hashed("template:///test%x.whatever"))
-- inspect(hashed("tem%2Bplate:///test%x.whatever"))

-- Here we assume:
--
-- files: ///  = relative
-- files: //// = absolute (!)

--~ table.print(hashed("file://c:/opt/tex/texmf-local")) -- c:/opt/tex/texmf-local
--~ table.print(hashed("file://opt/tex/texmf-local"   )) -- opt/tex/texmf-local
--~ table.print(hashed("file:///opt/tex/texmf-local"  )) -- opt/tex/texmf-local
--~ table.print(hashed("file:////opt/tex/texmf-local" )) -- /opt/tex/texmf-local
--~ table.print(hashed("file:///./opt/tex/texmf-local" )) -- ./opt/tex/texmf-local

--~ table.print(hashed("c:/opt/tex/texmf-local"       )) -- c:/opt/tex/texmf-local
--~ table.print(hashed("opt/tex/texmf-local"          )) -- opt/tex/texmf-local
--~ table.print(hashed("/opt/tex/texmf-local"         )) -- /opt/tex/texmf-local

url.split     = split
url.hasscheme = hasscheme
url.hashed    = hashed

function url.addscheme(str,scheme) -- no authority
    if hasscheme(str) then
        return str
    elseif not scheme then
        return "file:///" .. str
    else
        return scheme .. ":///" .. str
    end
end

function url.construct(hash) -- dodo: we need to escape !
    local result, r = { }, 0
    local scheme    = hash.scheme
    local authority = hash.authority
    local path      = hash.path
    local queries   = hash.queries
    local fragment  = hash.fragment
    if scheme and scheme ~= "" then
        r = r + 1 ; result[r] = lpegmatch(escaper,scheme)
        r = r + 1 ; result[r] = "://"
    end
    if authority and authority ~= "" then
        r = r + 1 ; result[r] = lpegmatch(escaper,authority)
    end
    if path and path ~= "" then
        r = r + 1 ; result[r] = "/"
        r = r + 1 ; result[r] = lpegmatch(escaper,path)
    end
    if queries then
        local done = false
        for k, v in sortedhash(queries) do
            r = r + 1 ; result[r] = done and "&" or "?"
            r = r + 1 ; result[r] = lpegmatch(escaper,k) -- is this escaped
            r = r + 1 ; result[r] = "="
            r = r + 1 ; result[r] = lpegmatch(escaper,v) -- is this escaped
            done = true
        end
    end
    if fragment and fragment ~= "" then
        r = r + 1 ; result[r] = "#"
        r = r + 1 ; result[r] = lpegmatch(escaper,fragment)
    end
    return concat(result)
end

local pattern = Cs(slash^-1/"" * R("az","AZ") * ((S(":|")/":") + P(":")) * slash * P(1)^0)

function url.filename(filename)
    local spec = hashed(filename)
    local path = spec.path
    return (spec.scheme == "file" and path and lpegmatch(pattern,path)) or filename
end

-- print(url.filename("/c|/test"))
-- print(url.filename("/c/test"))
-- print(url.filename("file:///t:/sources/cow.svg"))

local function escapestring(str)
    return lpegmatch(escaper,str)
end

url.escape = escapestring

function url.query(str)
    if type(str) == "string" then
        return lpegmatch(splitquery,str) or ""
    else
        return str
    end
end

function url.toquery(data)
    local td = type(data)
    if td == "string" then
        return #str and escape(data) or nil -- beware of double escaping
    elseif td == "table" then
        if next(data) then
            local t = { }
            for k, v in next, data do
                t[#t+1] = format("%s=%s",k,escapestring(v))
            end
            return concat(t,"&")
        end
    else
        -- nil is a signal that no query
    end
end

-- /test/ | /test | test/ | test => test

local pattern = Cs(noslash^0 * (1 - noslash * P(-1))^0)

function url.barepath(path)
    if not path or path == "" then
        return ""
    else
        return lpegmatch(pattern,path)
    end
end

-- print(url.barepath("/test"),url.barepath("test/"),url.barepath("/test/"),url.barepath("test"))
-- print(url.barepath("/x/yz"),url.barepath("x/yz/"),url.barepath("/x/yz/"),url.barepath("x/yz"))

-- print(url.filename("file:///c:/oeps.txt"))
-- print(url.filename("c:/oeps.txt"))
-- print(url.filename("file:///oeps.txt"))
-- print(url.filename("file:///etc/test.txt"))
-- print(url.filename("/oeps.txt"))

-- from the spec on the web (sort of):

-- local function test(str)
--     local t = url.hashed(str)
--     t.constructed = url.construct(t)
--     print(table.serialize(t))
-- end

-- inspect(url.hashed("http://www.pragma-ade.com/test%20test?test=test%20test&x=123%3d45"))
-- inspect(url.hashed("http://www.pragma-ade.com/test%20test?test=test%20test&x=123%3d45"))

-- test("sys:///./colo-rgb")

-- test("/data/site/output/q2p-develop/resources/ecaboperception4_res/topicresources/58313733/figuur-cow.jpg")
-- test("file:///M:/q2p/develop/output/q2p-develop/resources/ecaboperception4_res/topicresources/58313733")
-- test("M:/q2p/develop/output/q2p-develop/resources/ecaboperception4_res/topicresources/58313733")
-- test("file:///q2p/develop/output/q2p-develop/resources/ecaboperception4_res/topicresources/58313733")
-- test("/q2p/develop/output/q2p-develop/resources/ecaboperception4_res/topicresources/58313733")

-- test("file:///cow%20with%20spaces")
-- test("file:///cow%20with%20spaces.pdf")
-- test("cow%20with%20spaces.pdf")
-- test("some%20file")
-- test("/etc/passwords")
-- test("http://www.myself.com/some%20words.html")
-- test("file:///c:/oeps.txt")
-- test("file:///c|/oeps.txt")
-- test("file:///etc/oeps.txt")
-- test("file://./etc/oeps.txt")
-- test("file:////etc/oeps.txt")
-- test("ftp://ftp.is.co.za/rfc/rfc1808.txt")
-- test("http://www.ietf.org/rfc/rfc2396.txt")
-- test("ldap://[2001:db8::7]/c=GB?objectClass?one#what")
-- test("mailto:John.Doe@example.com")
-- test("news:comp.infosystems.www.servers.unix")
-- test("tel:+1-816-555-1212")
-- test("telnet://192.0.2.16:80/")
-- test("urn:oasis:names:specification:docbook:dtd:xml:4.1.2")
-- test("http://www.pragma-ade.com/spaced%20name")

-- test("zip:///oeps/oeps.zip#bla/bla.tex")
-- test("zip:///oeps/oeps.zip?bla/bla.tex")

-- table.print(url.hashed("/test?test"))
