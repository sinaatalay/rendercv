--
-- This is file `expl3.lua',
-- generated with the docstrip utility.
--
-- The original source files were:
--
-- l3luatex.dtx  (with options: `package,lua')
-- l3names.dtx  (with options: `package,lua')
-- l3sys.dtx  (with options: `package,lua')
-- l3token.dtx  (with options: `package,lua')
-- l3intarray.dtx  (with options: `package,lua')
-- 
-- Copyright (C) 1990-2023 The LaTeX Project
-- 
-- It may be distributed and/or modified under the conditions of
-- the LaTeX Project Public License (LPPL), either version 1.3c of
-- this license or (at your option) any later version.  The latest
-- version of this license is in the file:
-- 
--    https://www.latex-project.org/lppl.txt
-- 
-- This file is part of the "l3kernel bundle" (The Work in LPPL)
-- and all files in that bundle must be distributed together.
-- 
-- File: l3luatex.dtx
ltx = ltx or {utils={}}
ltx.utils = ltx.utils or { }
local ltxutils = ltx.utils
local io       = io
local kpse     = kpse
local lfs      = lfs
local math     = math
local md5      = md5
local os       = os
local string   = string
local tex      = tex
local texio    = texio
local tonumber = tonumber
local abs        = math.abs
local byte       = string.byte
local floor      = math.floor
local format     = string.format
local gsub       = string.gsub
local lfs_attr   = lfs.attributes
local open       = io.open
local os_date    = os.date
local setcatcode = tex.setcatcode
local sprint     = tex.sprint
local cprint     = tex.cprint
local write      = tex.write
local write_nl   = texio.write_nl
local utf8_char  = utf8.char
local package_loaded    = package.loaded
local package_searchers = package.searchers
local table_concat      = table.concat

local scan_int     = token.scan_int or token.scan_integer
local scan_string  = token.scan_string
local scan_keyword = token.scan_keyword
local put_next     = token.put_next
local token_create = token.create
local token_new    = token.new
local set_macro    = token.set_macro
local token_create_safe
do
  local is_defined = token.is_defined
  local set_char   = token.set_char
  local runtoks    = tex.runtoks
  local let_token  = token_create'let'

  function token_create_safe(s)
    local orig_token = token_create(s)
    if is_defined(s, true) then
      return orig_token
    end
    set_char(s, 0)
    local new_token = token_create(s)
    runtoks(function()
      put_next(let_token, new_token, orig_token)
    end)
    return new_token
  end
end

local true_tok     = token_create_safe'prg_return_true:'
local false_tok    = token_create_safe'prg_return_false:'
local command_id   = token.command_id
if not command_id and tokens and tokens.commands then
  local id_map = tokens.commands
  function command_id(name)
    return id_map[name]
  end
end
local kpse_find = (resolvers and resolvers.findfile) or kpse.find_file
local function escapehex(str)
  return (gsub(str, ".",
    function (ch) return format("%02X", byte(ch)) end))
end
local function filedump(name,offset,length)
  local file = kpse_find(name,"tex",true)
  if not file then return end
  local f = open(file,"rb")
  if not f then return end
  if offset and offset > 0 then
    f:seek("set", offset)
  end
  local data = f:read(length or 'a')
  f:close()
  return escapehex(data)
end
ltxutils.filedump = filedump
local md5_HEX = md5.HEX
if not md5_HEX then
  local md5_sum = md5.sum
  function md5_HEX(data)
    return escapehex(md5_sum(data))
  end
  md5.HEX = md5_HEX
end
local function filemd5sum(name)
  local file = kpse_find(name, "tex", true) if not file then return end
  local f = open(file, "rb") if not f then return end

  local data = f:read("*a")
  f:close()
  return md5_HEX(data)
end
ltxutils.filemd5sum = filemd5sum
local filemoddate
if os_date'%z':match'^[+-]%d%d%d%d$' then
  local pattern = lpeg.Cs(16 *
      (lpeg.Cg(lpeg.S'+-' * '0000' * lpeg.Cc'Z')
    + 3 * lpeg.Cc"'" * 2 * lpeg.Cc"'"
    + lpeg.Cc'Z')
  * -1)
  function filemoddate(name)
    local file = kpse_find(name, "tex", true)
    if not file then return end
    local date = lfs_attr(file, "modification")
    if not date then return end
    return pattern:match(os_date("D:%Y%m%d%H%M%S%z", date))
  end
else
  local function filemoddate(name)
    local file = kpse_find(name, "tex", true)
    if not file then return end
    local date = lfs_attr(file, "modification")
    if not date then return end
    local d = os_date("*t", date)
    local u = os_date("!*t", date)
    local off = 60 * (d.hour - u.hour) + d.min - u.min
    if d.year ~= u.year then
      if d.year > u.year then
        off = off + 1440
      else
        off = off - 1440
      end
    elseif d.yday ~= u.yday then
      if d.yday > u.yday then
        off = off + 1440
      else
        off = off - 1440
      end
    end
    local timezone
    if off == 0 then
      timezone = "Z"
    else
      if off < 0 then
        timezone = "-"
        off = -off
      else
        timezone = "+"
      end
      timezone = format("%s%02d'%02d'", timezone, hours // 60, hours % 60)
    end
    return format("D:%04d%02d%02d%02d%02d%02d%s",
        d.year, d.month, d.day, d.hour, d.min, d.sec, timezone)
  end
end
ltxutils.filemoddate = filemoddate
local function filesize(name)
  local file = kpse_find(name, "tex", true)
  if file then
    local size = lfs_attr(file, "size")
    if size then
      return size
    end
  end
end
ltxutils.filesize = filesize
local luacmd do
  local set_lua = token.set_lua
  local undefined_cs = command_id'undefined_cs'

  if not context and not luatexbase then require'ltluatex' end
  if luatexbase then
    local new_luafunction = luatexbase.new_luafunction
    local functions = lua.get_functions_table()
    function luacmd(name, func, ...)
      local id
      local tok = token_create(name)
      if tok.command == undefined_cs then
        id = new_luafunction(name)
        set_lua(name, id, ...)
      else
        id = tok.index or tok.mode
      end
      functions[id] = func
    end
  elseif context then
    local register = context.functions.register
    local functions = context.functions.known
    function luacmd(name, func, ...)
      local tok = token_create(name)
      if tok.command == undefined_cs then
        token.set_lua(name, register(func), ...)
      else
        functions[tok.index or tok.mode] = func
      end
    end
  end
end
local function try_require(name)
  if package_loaded[name] then
    return true, package_loaded[name]
  end

  local failure_details = {}
  for _, searcher in ipairs(package_searchers) do
    local loader, data = searcher(name)
    if type(loader) == 'function' then
      package_loaded[name] = loader(name, data) or true
      return true, package_loaded[name]
    elseif type(loader) == 'string' then
      failure_details[#failure_details + 1] = loader
    end
  end

  return false, table_concat(failure_details, '\n')
end
local char_given   = command_id'char_given'
local c_true_bool  = token_create(1, char_given)
local c_false_bool = token_create(0, char_given)
local c_str_cctab  = token_create('c_str_cctab').mode

luacmd('__lua_load_module_p:n', function()
  local success, result = try_require(scan_string())
  if success then
    set_macro(c_str_cctab, 'l__lua_err_msg_str', '')
    put_next(c_true_bool)
  else
    set_macro(c_str_cctab, 'l__lua_err_msg_str', result)
    put_next(c_false_bool)
  end
end)
local register_luadata, get_luadata

if luatexbase then
  local register = token_create'@expl@luadata@bytecode'.index
  if status.ini_version then
    local luadata, luadata_order = {}, {}

    function register_luadata(name, func)
      if luadata[name] then
        error(format("LaTeX error: data name %q already in use", name))
      end
      luadata[name] = func
      luadata_order[#luadata_order + 1] = func and name
    end
    luatexbase.add_to_callback("pre_dump", function()
      if next(luadata) then
        local str = "return {"
        for i=1, #luadata_order do
          local name = luadata_order[i]
          str = format('%s[%q]=%s,', str, name, luadata[name]())
        end
        lua.bytecode[register] = assert(load(str .. "}"))
      end
    end, "ltx.luadata")
  else
    local luadata = lua.bytecode[register]
    if luadata then
      lua.bytecode[register] = nil
      luadata = luadata()
    end
    function get_luadata(name)
      if not luadata then return end
      local data = luadata[name]
      luadata[name] = nil
      return data
    end
  end
end
-- File: l3names.dtx
local minus_tok = token_new(string.byte'-', 12)
local zero_tok = token_new(string.byte'0', 12)
local one_tok = token_new(string.byte'1', 12)
luacmd('tex_strcmp:D', function()
  local first = scan_string()
  local second = scan_string()
  if first < second then
    put_next(minus_tok, one_tok)
  else
    put_next(first == second and zero_tok or one_tok)
  end
end, 'global')
local sprint = tex.sprint
local cprint = tex.cprint
luacmd('tex_Ucharcat:D', function()
  local charcode = scan_int()
  local catcode = scan_int()
  if catcode == 10 then
    sprint(token_new(charcode, 10))
  else
    cprint(catcode, utf8_char(charcode))
  end
end, 'global')
luacmd('tex_filesize:D', function()
  local size = filesize(scan_string())
  if size then write(size) end
end, 'global')
luacmd('tex_mdfivesum:D', function()
  local hash
  if scan_keyword"file" then
    hash = filemd5sum(scan_string())
  else
    hash = md5_HEX(scan_string())
  end
  if hash then write(hash) end
end, 'global')
luacmd('tex_filemoddate:D', function()
  local date = filemoddate(scan_string())
  if date then write(date) end
end, 'global')
luacmd('tex_filedump:D', function()
  local offset = scan_keyword'offset' and scan_int() or nil
  local length = scan_keyword'length' and scan_int()
          or not scan_keyword'whole' and 0 or nil
  local data = filedump(scan_string(), offset, length)
  if data then write(data) end
end, 'global')
-- File: l3sys.dtx
do
  local os_exec = os.execute

  local function shellescape(cmd)
    local status,msg = os_exec(cmd)
    if status == nil then
      write_nl("log","runsystem(" .. cmd .. ")...(" .. msg .. ")\n")
    elseif status == 0 then
      write_nl("log","runsystem(" .. cmd .. ")...executed\n")
    else
      write_nl("log","runsystem(" .. cmd .. ")...failed " .. (msg or "") .. "\n")
    end
  end
  luacmd("__sys_shell_now:e", function()
    shellescape(scan_string())
  end, "global", "protected")
  local new_latelua = nodes and nodes.nuts and nodes.nuts.pool and nodes.nuts.pool.latelua or (function()
    local whatsit_id = node.id'whatsit'
    local latelua_sub = node.subtype'late_lua'
    local node_new = node.direct.new
    local setfield = node.direct.setwhatsitfield or node.direct.setfield
    return function(f)
      local n = node_new(whatsit_id, latelua_sub)
      setfield(n, 'data', f)
      return n
    end
  end)()
  local node_write = node.direct.write

  luacmd("__sys_shell_shipout:e", function()
    local cmd = scan_string()
    node_write(new_latelua(function() shellescape(cmd) end))
  end, "global", "protected")
end
  local gettimeofday = os.gettimeofday
  local epoch = gettimeofday() - os.clock()
  local write = tex.write
  local tointeger = math.tointeger
  luacmd('__sys_elapsedtime:', function()
    write(tointeger((gettimeofday() - epoch)*65536 // 1))
  end, 'global')
-- File: l3token.dtx
do
  local get_next = token.get_next
  local get_command = token.get_command
  local get_index = token.get_index
  local get_mode = token.get_mode or token.get_index
  local cmd = command_id
  local set_font = cmd'get_font'
  local biggest_char = token.biggest_char and token.biggest_char()
                    or status.getconstants().max_character_code

  local mode_below_biggest_char = {}
  local index_not_nil = {}
  local mode_not_null = {}
  local non_primitive = {
    [cmd'left_brace'] = true,
    [cmd'right_brace'] = true,
    [cmd'math_shift'] = true,
    [cmd'mac_param' or cmd'parameter'] = mode_below_biggest_char,
    [cmd'sup_mark' or cmd'superscript'] = true,
    [cmd'sub_mark' or cmd'subscript'] = true,
    [cmd'endv' or cmd'ignore'] = true,
    [cmd'spacer'] = true,
    [cmd'letter'] = true,
    [cmd'other_char'] = true,
    [cmd'tab_mark' or cmd'alignment_tab'] = mode_below_biggest_char,
    [cmd'char_given'] = true,
    [cmd'math_given' or 'math_char_given'] = true,
    [cmd'xmath_given' or 'math_char_xgiven'] = true,
    [cmd'set_font'] = mode_not_null,
    [cmd'undefined_cs'] = true,
    [cmd'call'] = true,
    [cmd'long_call' or cmd'protected_call'] = true,
    [cmd'outer_call' or cmd'tolerant_call'] = true,
    [cmd'long_outer_call' or cmd'tolerant_protected_call'] = true,
    [cmd'assign_glue' or cmd'register_glue'] = index_not_nil,
    [cmd'assign_mu_glue' or cmd'register_mu_glue'] = index_not_nil,
    [cmd'assign_toks' or cmd'register_toks'] = index_not_nil,
    [cmd'assign_int' or cmd'register_int'] = index_not_nil,
    [cmd'assign_attr' or cmd'register_attribute'] = true,
    [cmd'assign_dimen' or cmd'register_dimen'] = index_not_nil,
  }

  luacmd("__token_if_primitive_lua:N", function()
    local tok = get_next()
    local is_non_primitive = non_primitive[get_command(tok)]
    return put_next(
           is_non_primitive == true
             and false_tok
        or is_non_primitive == nil
             and true_tok
        or is_non_primitive == mode_not_null
             and (get_mode(tok) == 0 and true_tok or false_tok)
        or is_non_primitive == index_not_nil
             and (get_index(tok) and false_tok or true_tok)
        or is_non_primitive == mode_below_biggest_char
             and (get_mode(tok) > biggest_char and true_tok or false_tok))
  end, "global")
end
-- File: l3intarray.dtx
luacmd('__intarray:w', function()
  scan_int()
  tex.error'LaTeX Error: Isolated intarray ignored'
end, 'protected', 'global')

local scan_token = token.scan_token
local put_next = token.put_next
local intarray_marker = token_create_safe'__intarray:w'
local use_none = token_create_safe'use_none:n'
local use_i = token_create_safe'use:n'
local expand_after_scan_stop = {token_create_safe'exp_after:wN',
                                token_create_safe'scan_stop:'}
local comma = token_create(string.byte',')
local __intarray_table do
  local tables = get_luadata and get_luadata'__intarray' or {[0] = {}}
  function __intarray_table()
    local t = scan_token()
    if t ~= intarray_marker then
      put_next(t)
      tex.error'LaTeX Error: intarray expected'
      return tables[0]
    end
    local i = scan_int()
    local current_table = tables[i]
    if current_table then return current_table end
    current_table = {}
    tables[i] = current_table
    return current_table
  end
  if register_luadata then
    register_luadata('__intarray', function()
      local t = "{[0]={},"
      for i=1, #tables do
        t = string.format("%s{%s},", t, table.concat(tables[i], ','))
      end
      return t .. "}"
    end)
  end
end

local sprint = tex.sprint

luacmd('__intarray_gset_count:Nw', function()
  local t = __intarray_table()
  local n = scan_int()
  for i=#t+1, n do t[i] = 0 end
end, 'protected', 'global')

luacmd('intarray_count:N', function()
  sprint(-2, #__intarray_table())
end, 'global')
luacmd('__intarray_gset:wF', function()
  local i = scan_int()
  local t = __intarray_table()
  if t[i] then
    t[i] = scan_int()
    put_next(use_none)
  else
    tex.count.l__intarray_bad_index_int = i
    scan_int()
    put_next(use_i)
  end
end, 'protected', 'global')

luacmd('__intarray_gset:w', function()
  local i = scan_int()
  local t = __intarray_table()
  t[i] = scan_int()
end, 'protected', 'global')
luacmd('intarray_gzero:N', function()
  local t = __intarray_table()
  for i=1, #t do
    t[i] = 0
  end
end, 'global', 'protected')
luacmd('__intarray_item:wF', function()
  local i = scan_int()
  local t = __intarray_table()
  local item = t[i]
  if item then
    put_next(use_none)
  else
    tex.l__intarray_bad_index_int = i
    put_next(use_i)
  end
  put_next(expand_after_scan_stop)
  scan_token()
  if item then
    sprint(-2, item)
  end
end, 'global')

luacmd('__intarray_item:w', function()
  local i = scan_int()
  local t = __intarray_table()
  sprint(-2, t[i])
end, 'global')
local concat = table.concat
luacmd('__intarray_to_clist:Nn', function()
  local t = __intarray_table()
  local sep = token.scan_string()
  sprint(-2, concat(t, sep))
end, 'global')
luacmd('__intarray_range_to_clist:w', function()
  local t = __intarray_table()
  local from = scan_int()
  local to = scan_int()
  sprint(-2, concat(t, ',', from, to))
end, 'global')
luacmd('__intarray_gset_range:w', function()
  local from = scan_int()
  local t = __intarray_table()
  while true do
    local tok = scan_token()
    if tok == comma then
      repeat
        tok = scan_token()
      until tok ~= comma
      break
    else
      put_next(tok)
    end
    t[from] = scan_int()
    scan_token()
    from = from + 1
  end
  end, 'global', 'protected')
