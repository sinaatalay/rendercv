if not modules then modules = { } end modules ['util-jsn'] = {
    version   = 1.001,
    comment   = "companion to m-json.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- Of course we could make a nice complete parser with proper error messages but
-- as json is generated programmatically errors are systematic and we can assume
-- a correct stream. If not, we have some fatal error anyway. So, we can just rely
-- on strings being strings (apart from the unicode escape which is not in 5.1) and
-- as we first catch known types we just assume that anything else is a number.
--
-- Reminder for me: check usage in framework and extend when needed. Also document
-- it in the cld lib documentation.
--
-- Upgraded for handling the somewhat more fax server templates.

if utilities and utilities.json then
    return json
end

local P, V, R, S, C, Cc, Cs, Ct, Cf, Cg = lpeg.P, lpeg.V, lpeg.R, lpeg.S, lpeg.C, lpeg.Cc, lpeg.Cs, lpeg.Ct, lpeg.Cf, lpeg.Cg
local lpegmatch = lpeg.match
local format, gsub = string.format, string.gsub
local formatters = string.formatters
local utfchar = utf.char
local concat, sortedkeys = table.concat, table.sortedkeys

local tonumber, tostring, rawset, type, next = tonumber, tostring, rawset, type, next

local json      = utilities.json or { }
utilities.json  = json

do

    -- \\ \/ \b \f \n \r \t \uHHHH

    local lbrace     = P("{")
    local rbrace     = P("}")
    local lparent    = P("[")
    local rparent    = P("]")
    local comma      = P(",")
    local colon      = P(":")
    local dquote     = P('"')

    local whitespace = lpeg.patterns.whitespace
    local optionalws = whitespace^0

    local escapes    = {
        ["b"] = "\010",
        ["f"] = "\014",
        ["n"] = "\n",
        ["r"] = "\r",
        ["t"] = "\t",
    }

    -- todo: also handle larger utf16

    local escape_un  = P("\\u")/"" * (C(R("09","AF","af")^-4) / function(s)
        return utfchar(tonumber(s,16))
    end)

    local escape_bs  = P([[\]]) / "" * (P(1) / escapes) -- if not found then P(1) is returned i.e. the to be escaped char

    local jstring    = dquote * Cs((escape_un + escape_bs + (1-dquote))^0) * dquote
    local jtrue      = P("true")  * Cc(true)
    local jfalse     = P("false") * Cc(false)
    local jnull      = P("null")  * Cc(nil)
    local jnumber    = (1-whitespace-rparent-rbrace-comma)^1 / tonumber

    local key        = jstring

    local jsonconverter = { "value",
        hash  = lbrace * Cf(Ct("") * (V("pair") * (comma * V("pair"))^0 + optionalws),rawset) * rbrace,
        pair  = Cg(optionalws * key * optionalws * colon * V("value")),
        array = Ct(lparent * (V("value") * (comma * V("value"))^0 + optionalws) * rparent),
    --  value = optionalws * (jstring + V("hash") + V("array") + jtrue + jfalse + jnull + jnumber + #rparent) * optionalws,
        value = optionalws * (jstring + V("hash") + V("array") + jtrue + jfalse + jnull + jnumber) * optionalws,
    }

    -- local jsonconverter = { "value",
    --     hash   = lbrace * Cf(Ct("") * (V("pair") * (comma * V("pair"))^0 + optionalws),rawset) * rbrace,
    --     pair   = Cg(optionalws * V("string") * optionalws * colon * V("value")),
    --     array  = Ct(lparent * (V("value") * (comma * V("value"))^0 + optionalws) * rparent),
    --     string = jstring,
    --     value  = optionalws * (V("string") + V("hash") + V("array") + jtrue + jfalse + jnull + jnumber) * optionalws,
    -- }

    -- lpeg.print(jsonconverter) -- size 181

    function json.tolua(str)
        return lpegmatch(jsonconverter,str)
    end

    function json.load(filename)
        local data = io.loaddata(filename)
        if data then
            return lpegmatch(jsonconverter,data)
        end
    end

end

do

    -- It's pretty bad that JSON doesn't allow the trailing comma ... it's a
    -- typical example of a spec that then forces all generators to check for
    -- this. It's a way to make sure programmers keep jobs.

    local escaper

    local f_start_hash      = formatters[         '%w{' ]
    local f_start_array     = formatters[         '%w[' ]
    local f_start_hash_new  = formatters[ "\n" .. '%w{' ]
    local f_start_array_new = formatters[ "\n" .. '%w[' ]
    local f_start_hash_key  = formatters[ "\n" .. '%w"%s" : {' ]
    local f_start_array_key = formatters[ "\n" .. '%w"%s" : [' ]

    local f_stop_hash       = formatters[ "\n" .. '%w}' ]
    local f_stop_array      = formatters[ "\n" .. '%w]' ]

    local f_key_val_seq     = formatters[ "\n" .. '%w"%s" : %s'    ]
    local f_key_val_str     = formatters[ "\n" .. '%w"%s" : "%s"'  ]
    local f_key_val_num     = f_key_val_seq
    local f_key_val_yes     = formatters[ "\n" .. '%w"%s" : true'  ]
    local f_key_val_nop     = formatters[ "\n" .. '%w"%s" : false' ]
    local f_key_val_null    = formatters[ "\n" .. '%w"%s" : null'  ]

    local f_val_num         = formatters[ "\n" .. '%w%s'    ]
    local f_val_str         = formatters[ "\n" .. '%w"%s"'  ]
    local f_val_yes         = formatters[ "\n" .. '%wtrue'  ]
    local f_val_nop         = formatters[ "\n" .. '%wfalse' ]
    local f_val_null        = formatters[ "\n" .. '%wnull'  ]
    local f_val_empty       = formatters[ "\n" .. '%w{ }'  ]
    local f_val_seq         = f_val_num

    -- no empty tables because unknown if table or hash

    local t = { }
    local n = 0

    local function is_simple_table(tt) -- also used in util-tab so maybe public
        local l = #tt
        if l > 0 then
            for i=1,l do
                if type(tt[i]) == "table" then
                    return false
                end
            end
            local nn = n
            n = n + 1 t[n] = "[ "
            for i=1,l do
                if i > 1 then
                    n = n + 1 t[n] = ", "
                end
                local v = tt[i]
                local tv = type(v)
                if tv == "number" then
                    n = n + 1 t[n] = v
                elseif tv == "string" then
                    n = n + 1 t[n] = '"'
                    n = n + 1 t[n] = lpegmatch(escaper,v) or v
                    n = n + 1 t[n] = '"'
                elseif tv == "boolean" then
                    n = n + 1 t[n] = v and "true" or "false"
                elseif v then
                    n = n + 1 t[n] = tostring(v)
                else
                    n = n + 1 t[n] = "null"
                end
            end
            n = n + 1 t[n] = " ]"
            local s = concat(t,"",nn+1,n)
            n = nn
            return s
        end
        return false
    end

    local function tojsonpp(root,name,depth,level,size)
        if root then
            local indexed = size > 0
            n = n + 1
            if level == 0 then
                if indexed then
                    t[n] = f_start_array(depth)
                else
                    t[n] = f_start_hash(depth)
                end
            elseif name then
                if tn == "string" then
                    name = lpegmatch(escaper,name) or name
                elseif tn ~= "number" then
                    name = tostring(name)
                end
                if indexed then
                    t[n] = f_start_array_key(depth,name)
                else
                    t[n] = f_start_hash_key(depth,name)
                end
            else
                if indexed then
                    t[n] = f_start_array_new(depth)
                else
                    t[n] = f_start_hash_new(depth)
                end
            end
            depth = depth + 1
            if indexed then -- indexed
                for i=1,size do
                    if i > 1 then
                        n = n + 1 t[n] = ","
                    end
                    local v  = root[i]
                    local tv = type(v)
                    if tv == "number" then
                        n = n + 1 t[n] = f_val_num(depth,v)
                    elseif tv == "string" then
                        v = lpegmatch(escaper,v) or v
                        n = n + 1 t[n] = f_val_str(depth,v)
                    elseif tv == "table" then
                        if next(v) then
                            local st = is_simple_table(v)
                            if st then
                                n = n + 1 t[n] = f_val_seq(depth,st)
                            else
                                tojsonpp(v,nil,depth,level+1,#v)
                            end
                        else
                            n = n + 1
                            t[n] = f_val_empty(depth)
                        end
                    elseif tv == "boolean" then
                        n = n + 1
                        if v then
                            t[n] = f_val_yes(depth,v)
                        else
                            t[n] = f_val_nop(depth,v)
                        end
                    else
                        n = n + 1
                        t[n] = f_val_null(depth)
                    end
                end
            elseif next(root) then
                local sk = sortedkeys(root)
                for i=1,#sk do
                    if i > 1 then
                        n = n + 1 t[n] = ","
                    end
                    local k  = sk[i]
                    local v  = root[k]
                    local tv = type(v)
                    local tk = type(k)
                    if tv == "number" then
                        if tk == "number" then
                            n = n + 1 t[n] = f_key_val_num(depth,k,v)
                        elseif tk == "string" then
                            k = lpegmatch(escaper,k) or k
                            n = n + 1 t[n] = f_key_val_num(depth,k,v)
                        end
                    elseif tv == "string" then
                        if tk == "number" then
                            v = lpegmatch(escaper,v) or v
                            n = n + 1 t[n] = f_key_val_str(depth,k,v)
                        elseif tk == "string" then
                            k = lpegmatch(escaper,k) or k
                            v = lpegmatch(escaper,v) or v
                            n = n + 1 t[n] = f_key_val_str(depth,k,v)
                        elseif i > 1 then
                            n = n - 1
                        end
                    elseif tv == "table" then
                        local l = #v
                        if l > 0 then
                            local st = is_simple_table(v)
                            if not st then
                                tojsonpp(v,k,depth,level+1,l)
                            elseif tk == "number" then
                                n = n + 1 t[n] = f_key_val_seq(depth,k,st)
                            elseif tk == "string" then
                                k = lpegmatch(escaper,k) or k
                                n = n + 1 t[n] = f_key_val_seq(depth,k,st)
                            end
                        elseif next(v) then
                            tojsonpp(v,k,depth,level+1,0)
                        elseif i > 1 then
                            n = n - 1
                            -- we don't know if we have a hash or string
                        end
                    elseif tv == "boolean" then
                        if tk == "number" then
                            n = n + 1
                            if v then
                                t[n] = f_key_val_yes(depth,k)
                            else
                                t[n] = f_key_val_nop(depth,k)
                            end
                        elseif tk == "string" then
                            k = lpegmatch(escaper,k) or k
                            n = n + 1
                            if v then
                                t[n] = f_key_val_yes(depth,k)
                            else
                                t[n] = f_key_val_nop(depth,k)
                            end
                        elseif i > 1 then
                            n = n - 1
                        end
                    else
                        if tk == "number" then
                            n = n + 1
                            t[n] = f_key_val_null(depth,k)
                        elseif tk == "string" then
                            k = lpegmatch(escaper,k) or k
                            n = n + 1
                            t[n] = f_key_val_null(depth,k)
                        elseif i > 1 then
                            n = n - 1
                        end
                    end
                end
            end
            n = n + 1
            if indexed then
                t[n] = f_stop_array(depth-1)
            else
                t[n] = f_stop_hash(depth-1)
            end
        end
    end

    local function tojson(value,n)
        local kind = type(value)
        if kind == "table" then
            local done = false
            local size = #value
            if size == 0 then
                for k, v in next, value do
                    if done then
                     -- n = n + 1 ; t[n] = ","
                        n = n + 1 ; t[n] = ',"'
                    else
                     -- n = n + 1 ; t[n] = "{"
                        n = n + 1 ; t[n] = '{"'
                        done = true
                    end
                    n = n + 1 ; t[n] = lpegmatch(escaper,k) or k
                    n = n + 1 ; t[n] = '":'
                    t, n = tojson(v,n)
                end
                if done then
                    n = n + 1 ; t[n] = "}"
                else
                    n = n + 1 ; t[n] = "{}"
                end
            elseif size == 1 then
                -- we can optimize for non tables
                n = n + 1 ; t[n] = "["
                t, n = tojson(value[1],n)
                n = n + 1 ; t[n] = "]"
            else
                for i=1,size do
                    if done then
                        n = n + 1 ; t[n] = ","
                    else
                        n = n + 1 ; t[n] = "["
                        done = true
                    end
                    t, n = tojson(value[i],n)
                end
                n = n + 1 ; t[n] = "]"
            end
        elseif kind == "string"  then
            n = n + 1 ; t[n] = '"'
            n = n + 1 ; t[n] = lpegmatch(escaper,value) or value
            n = n + 1 ; t[n] = '"'
        elseif kind == "number" then
            n = n + 1 ; t[n] = value
        elseif kind == "boolean" then
            n = n + 1 ; t[n] = tostring(value)
        else
            n = n + 1 ; t[n] = "null"
        end
        return t, n
    end

    -- escaping keys can become an option

    local function jsontostring(value,pretty)
        -- todo optimize for non table
        local kind = type(value)
        if kind == "table" then
            if not escaper then
                local escapes = {
                    ["\\"] = "\\u005C",
                    ["\""] = "\\u0022",
                }
                for i=0,0x1F do
                    escapes[utfchar(i)] = format("\\u%04X",i)
                end
                escaper = Cs( (
                    (R('\0\x20') + S('\"\\')) / escapes
                  + P(1)
                )^1 )

            end
            -- local to the closure (saves wrapping and local functions)
            t = { }
            n = 0
            if pretty then
                tojsonpp(value,name,0,0,#value)
                value = concat(t,"",1,n)
            else
                t, n = tojson(value,0)
                value = concat(t,"",1,n)
            end
            t = nil
            n = 0
            return value
        elseif kind == "string" or kind == "number" then
            return lpegmatch(escaper,value) or value
        else
            return tostring(value)
        end
    end

    json.tostring = jsontostring

    function json.tojson(value)
        return jsontostring(value,true)
    end

end

-- local tmp = [[ { "t\nt t" : "foo bar", "a" : true, "b" : [ 123 , 456E-10, { "a" : true, "b" : [ 123 , 456 ] } ] } ]]
-- tmp = json.tolua(tmp)
-- inspect(tmp)
-- tmp = json.tostring(tmp,true)
-- inspect(tmp)
-- tmp = json.tolua(tmp)
-- inspect(tmp)
-- tmp = json.tostring(tmp)
-- inspect(tmp)
-- inspect(json.tostring(true))

-- local s = [[\foo"bar"]]
-- local j = json.tostring { s = s }
-- local l = json.tolua(j)
-- inspect(j)
-- inspect(l)
-- print(s==l.s)

-- if not package.loaded.json then
--     package.loaded.json = json
-- end

-- return json
