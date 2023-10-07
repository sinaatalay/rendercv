--
-- This is file `ltluatex.lua',
-- generated with the docstrip utility.
--
-- The original source files were:
--
-- ltluatex.dtx  (with options: `lua')
-- 
-- This is a generated file.
-- 
-- The source is maintained by the LaTeX Project team and bug
-- reports for it can be opened at https://latex-project.org/bugs.html
-- (but please observe conditions on bug reports sent to that address!)
-- 
-- 
-- Copyright (C) 2015-2023
-- The LaTeX Project and any individual authors listed elsewhere
-- in this file.
-- 
-- This file was generated from file(s) of the LaTeX base system.
-- --------------------------------------------------------------
-- 
-- It may be distributed and/or modified under the
-- conditions of the LaTeX Project Public License, either version 1.3c
-- of this license or (at your option) any later version.
-- The latest version of this license is in
--    https://www.latex-project.org/lppl.txt
-- and version 1.3c or later is part of all distributions of LaTeX
-- version 2008 or later.
-- 
-- This file has the LPPL maintenance status "maintained".
-- 
-- This file may only be distributed together with a copy of the LaTeX
-- base system. You may however distribute the LaTeX base system without
-- such generated files.
-- 
-- The list of all files belonging to the LaTeX base distribution is
-- given in the file `manifest.txt'. See also `legal.txt' for additional
-- information.
-- 
-- The list of derived (unpacked) files belonging to the distribution
-- and covered by LPPL is defined by the unpacking scripts (with
-- extension .ins) which are part of the distribution.
luatexbase       = luatexbase or { }
local luatexbase = luatexbase
local string_gsub      = string.gsub
local tex_count        = tex.count
local tex_setcount     = tex.setcount
local texio_write_nl   = texio.write_nl
local flush_list       = node.flush_list
local luatexbase_warning
local luatexbase_error
local modules = modules or { }
local function luatexbase_log(text)
  texio_write_nl("log", text)
end
local function provides_module(info)
  if not (info and info.name) then
    luatexbase_error("Missing module name for provides_module")
  end
  local function spaced(text)
    return text and (" " .. text) or ""
  end
  luatexbase_log(
    "Lua module: " .. info.name
      .. spaced(info.date)
      .. spaced(info.version)
      .. spaced(info.description)
  )
  modules[info.name] = info
end
luatexbase.provides_module = provides_module
local function msg_format(mod, msg_type, text)
  local leader = ""
  local cont
  local first_head
  if mod == "LaTeX" then
    cont = string_gsub(leader, ".", " ")
    first_head = leader .. "LaTeX: "
  else
    first_head = leader .. "Module "  .. msg_type
    cont = "(" .. mod .. ")"
      .. string_gsub(first_head, ".", " ")
    first_head =  leader .. "Module "  .. mod .. " " .. msg_type  .. ":"
  end
  if msg_type == "Error" then
    first_head = "\n" .. first_head
  end
  if string.sub(text,-1) ~= "\n" then
    text = text .. " "
  end
  return first_head .. " "
    .. string_gsub(
         text
 .. "on input line "
         .. tex.inputlineno, "\n", "\n" .. cont .. " "
      )
   .. "\n"
end
local function module_info(mod, text)
  texio_write_nl("log", msg_format(mod, "Info", text))
end
luatexbase.module_info = module_info
local function module_warning(mod, text)
  texio_write_nl("term and log",msg_format(mod, "Warning", text))
end
luatexbase.module_warning = module_warning
local function module_error(mod, text)
  error(msg_format(mod, "Error", text))
end
luatexbase.module_error = module_error
function luatexbase_warning(text)
  module_warning("luatexbase", text)
end
function luatexbase_error(text)
  module_error("luatexbase", text)
end
local luaregisterbasetable = { }
local registermap = {
  attributezero = "assign_attr"    ,
  charzero      = "char_given"     ,
  CountZero     = "assign_int"     ,
  dimenzero     = "assign_dimen"   ,
  mathcharzero  = "math_given"     ,
  muskipzero    = "assign_mu_skip" ,
  skipzero      = "assign_skip"    ,
  tokszero      = "assign_toks"    ,
}
local createtoken
if tex.luatexversion > 81 then
  createtoken = token.create
elseif tex.luatexversion > 79 then
  createtoken = newtoken.create
end
local hashtokens    = tex.hashtokens()
local luatexversion = tex.luatexversion
for i,j in pairs (registermap) do
  if luatexversion < 80 then
    luaregisterbasetable[hashtokens[i][1]] =
      hashtokens[i][2]
  else
    luaregisterbasetable[j] = createtoken(i).mode
  end
end
local registernumber
if luatexversion < 80 then
  function registernumber(name)
    local nt = hashtokens[name]
    if(nt and luaregisterbasetable[nt[1]]) then
      return nt[2] - luaregisterbasetable[nt[1]]
    else
      return false
    end
  end
else
  function registernumber(name)
    local nt = createtoken(name)
    if(luaregisterbasetable[nt.cmdname]) then
      return nt.mode - luaregisterbasetable[nt.cmdname]
    else
      return false
    end
  end
end
luatexbase.registernumber = registernumber
local attributes=setmetatable(
{},
{
__index = function(t,key)
return registernumber(key) or nil
end}
)
luatexbase.attributes = attributes
local attribute_count_name =
                     attribute_count_name or "e@alloc@attribute@count"
local function new_attribute(name)
  tex_setcount("global", attribute_count_name,
                          tex_count[attribute_count_name] + 1)
  if tex_count[attribute_count_name] > 65534 then
    luatexbase_error("No room for a new \\attribute")
  end
  attributes[name]= tex_count[attribute_count_name]
  luatexbase_log("Lua-only attribute " .. name .. " = " ..
                 tex_count[attribute_count_name])
  return tex_count[attribute_count_name]
end
luatexbase.new_attribute = new_attribute
local whatsit_count_name = whatsit_count_name or "e@alloc@whatsit@count"
local function new_whatsit(name)
  tex_setcount("global", whatsit_count_name,
                         tex_count[whatsit_count_name] + 1)
  if tex_count[whatsit_count_name] > 65534 then
    luatexbase_error("No room for a new custom whatsit")
  end
  luatexbase_log("Custom whatsit " .. (name or "") .. " = " ..
                 tex_count[whatsit_count_name])
  return tex_count[whatsit_count_name]
end
luatexbase.new_whatsit = new_whatsit
local bytecode_count_name =
                         bytecode_count_name or "e@alloc@bytecode@count"
local function new_bytecode(name)
  tex_setcount("global", bytecode_count_name,
                         tex_count[bytecode_count_name] + 1)
  if tex_count[bytecode_count_name] > 65534 then
    luatexbase_error("No room for a new bytecode register")
  end
  luatexbase_log("Lua bytecode " .. (name or "") .. " = " ..
                 tex_count[bytecode_count_name])
  return tex_count[bytecode_count_name]
end
luatexbase.new_bytecode = new_bytecode
local chunkname_count_name =
                        chunkname_count_name or "e@alloc@luachunk@count"
local function new_chunkname(name)
  tex_setcount("global", chunkname_count_name,
                         tex_count[chunkname_count_name] + 1)
  local chunkname_count = tex_count[chunkname_count_name]
  chunkname_count = chunkname_count + 1
  if chunkname_count > 65534 then
    luatexbase_error("No room for a new chunkname")
  end
  lua.name[chunkname_count]=name
  luatexbase_log("Lua chunkname " .. (name or "") .. " = " ..
                 chunkname_count .. "\n")
  return chunkname_count
end
luatexbase.new_chunkname = new_chunkname
local luafunction_count_name =
                         luafunction_count_name or "e@alloc@luafunction@count"
local function new_luafunction(name)
  tex_setcount("global", luafunction_count_name,
                         tex_count[luafunction_count_name] + 1)
  if tex_count[luafunction_count_name] > 65534 then
    luatexbase_error("No room for a new luafunction register")
  end
  luatexbase_log("Lua function " .. (name or "") .. " = " ..
                 tex_count[luafunction_count_name])
  return tex_count[luafunction_count_name]
end
luatexbase.new_luafunction = new_luafunction
local realcallbacklist = {}
local callbackrules = {}
local callbacklist = setmetatable({}, {
  __index = function(t, name)
    local list = realcallbacklist[name]
    local rules = callbackrules[name]
    if list and rules then
      local meta = {}
      for i, entry in ipairs(list) do
        local t = {value = entry, count = 0, pos = i}
        meta[entry.description], list[i] = t, t
      end
      local count = #list
      local pos = count
      for i, rule in ipairs(rules) do
        local rule = rules[i]
        local pre, post = meta[rule[1]], meta[rule[2]]
        if pre and post then
          if rule.type then
            if not rule.hidden then
              assert(rule.type == 'incompatible-warning' and luatexbase_warning
                or rule.type == 'incompatible-error' and luatexbase_error)(
                  "Incompatible functions \"" .. rule[1] .. "\" and \"" .. rule[2]
                  .. "\" specified for callback \"" .. name .. "\".")
              rule.hidden = true
            end
          else
            local post_count = post.count
            post.count = post_count+1
            if post_count == 0 then
              local post_pos = post.pos
              if post_pos ~= pos then
                local new_post_pos = list[pos]
                new_post_pos.pos = post_pos
                list[post_pos] = new_post_pos
              end
              list[pos] = nil
              pos = pos - 1
            end
            pre[#pre+1] = post
          end
        end
      end
      for i=1, count do -- The actual sort begins
        local current = list[i]
        if current then
          meta[current.value.description] = nil
          for j, cur in ipairs(current) do
            local count = cur.count
            if count == 1 then
              pos = pos + 1
              list[pos] = cur
            else
              cur.count = count - 1
            end
          end
          list[i] = current.value
        else
          -- Cycle occured. TODO: Show cycle for debugging
          -- list[i] = ...
          local remaining = {}
          for name, entry in next, meta do
            local value = entry.value
            list[#list + 1] = entry.value
            remaining[#remaining + 1] = name
          end
          table.sort(remaining)
          local first_name = remaining[1]
          for j, name in ipairs(remaining) do
            local entry = meta[name]
            list[i + j - 1] = entry.value
            for _, post_entry in ipairs(entry) do
              local post_name = post_entry.value.description
              if not remaining[post_name] then
                remaining[post_name] = name
              end
            end
          end
          local cycle = {first_name}
          local index = 1
          local last_name = first_name
          repeat
            cycle[last_name] = index
            last_name = remaining[last_name]
            index = index + 1
            cycle[index] = last_name
          until cycle[last_name]
          local length = index - cycle[last_name] + 1
          table.move(cycle, cycle[last_name], index, 1)
          for i=2, length//2 do
            cycle[i], cycle[length + 1 - i] = cycle[length + 1 - i], cycle[i]
          end
          error('Cycle occured at ' .. table.concat(cycle, ' -> ', 1, length))
        end
      end
    end
    realcallbacklist[name] = list
    t[name] = list
    return list
  end
})
local list, data, exclusive, simple, reverselist = 1, 2, 3, 4, 5
local types   = {
  list        = list,
  data        = data,
  exclusive   = exclusive,
  simple      = simple,
  reverselist = reverselist,
}
local callbacktypes = callbacktypes or {
  find_read_file     = exclusive,
  find_write_file    = exclusive,
  find_font_file     = data,
  find_output_file   = data,
  find_format_file   = data,
  find_vf_file       = data,
  find_map_file      = data,
  find_enc_file      = data,
  find_pk_file       = data,
  find_data_file     = data,
  find_opentype_file = data,
  find_truetype_file = data,
  find_type1_file    = data,
  find_image_file    = data,
  open_read_file     = exclusive,
  read_font_file     = exclusive,
  read_vf_file       = exclusive,
  read_map_file      = exclusive,
  read_enc_file      = exclusive,
  read_pk_file       = exclusive,
  read_data_file     = exclusive,
  read_truetype_file = exclusive,
  read_type1_file    = exclusive,
  read_opentype_file = exclusive,
  find_cidmap_file   = data,
  read_cidmap_file   = exclusive,
  process_input_buffer  = data,
  process_output_buffer = data,
  process_jobname       = data,
  contribute_filter      = simple,
  buildpage_filter       = simple,
  build_page_insert      = exclusive,
  pre_linebreak_filter   = list,
  linebreak_filter       = exclusive,
  append_to_vlist_filter = exclusive,
  post_linebreak_filter  = reverselist,
  hpack_filter           = list,
  vpack_filter           = list,
  hpack_quality          = exclusive,
  vpack_quality          = exclusive,
  pre_output_filter      = list,
  process_rule           = exclusive,
  hyphenate              = simple,
  ligaturing             = simple,
  kerning                = simple,
  insert_local_par       = simple,
  new_graf               = exclusive,
  pre_dump             = simple,
  start_run            = simple,
  stop_run             = simple,
  start_page_number    = simple,
  stop_page_number     = simple,
  show_error_hook      = simple,
  show_warning_message = simple,
  show_error_message   = simple,
  show_lua_error_hook  = simple,
  start_file           = simple,
  stop_file            = simple,
  call_edit            = simple,
  finish_synctex       = simple,
  wrapup_run           = simple,
  finish_pdffile            = data,
  finish_pdfpage            = data,
  page_objnum_provider      = data,
  page_order_index          = data,
  process_pdf_image_content = data,
  define_font                     = exclusive,
  glyph_info                      = exclusive,
  glyph_not_found                 = exclusive,
  glyph_stream_provider           = exclusive,
  make_extensible                 = exclusive,
  font_descriptor_objnum_provider = exclusive,
  input_level_string              = exclusive,
  provide_charproc_data           = exclusive,
}
luatexbase.callbacktypes=callbacktypes
local shared_callbacks = {
  mlist_to_hlist = {
    callback = "mlist_to_hlist",
    count = 0,
    handler = nil,
  },
}
shared_callbacks.pre_mlist_to_hlist_filter = shared_callbacks.mlist_to_hlist
shared_callbacks.post_mlist_to_hlist_filter = shared_callbacks.mlist_to_hlist
local callback_register = callback_register or callback.register
function callback.register()
  luatexbase_error("Attempt to use callback.register() directly\n")
end
local function data_handler(name)
  return function(data, ...)
    for _,i in ipairs(callbacklist[name]) do
      data = i.func(data,...)
    end
    return data
  end
end
local function data_handler_default(value)
  return value
end
local function exclusive_handler(name)
  return function(...)
    return callbacklist[name][1].func(...)
  end
end
local function list_handler(name)
  return function(head, ...)
    local ret
    for _,i in ipairs(callbacklist[name]) do
      ret = i.func(head, ...)
      if ret == false then
        luatexbase_warning(
          "Function `" .. i.description .. "' returned false\n"
            .. "in callback `" .. name .."'"
         )
        return false
      end
      if ret ~= true then
        head = ret
      end
    end
    return head
  end
end
local function list_handler_default(head)
return head
end
local function reverselist_handler(name)
  return function(head, ...)
    local ret
    local callbacks = callbacklist[name]
    for i = #callbacks, 1, -1 do
      local cb = callbacks[i]
      ret = cb.func(head, ...)
      if ret == false then
        luatexbase_warning(
          "Function `" .. cb.description .. "' returned false\n"
            .. "in callback `" .. name .."'"
         )
        return false
      end
      if ret ~= true then
        head = ret
      end
    end
    return head
  end
end
local function simple_handler(name)
  return function(...)
    for _,i in ipairs(callbacklist[name]) do
      i.func(...)
    end
  end
end
local function simple_handler_default()
end
local handlers  = {
  [data]        = data_handler,
  [exclusive]   = exclusive_handler,
  [list]        = list_handler,
  [reverselist] = reverselist_handler,
  [simple]      = simple_handler,
}
local defaults = {
  [data]        = data_handler_default,
  [exclusive]   = nil,
  [list]        = list_handler_default,
  [reverselist] = list_handler_default,
  [simple]      = simple_handler_default,
}
local user_callbacks_defaults = {}
local function create_callback(name, ctype, default)
  local ctype_id = types[ctype]
  if not name  or name  == ""
  or not ctype_id
  then
    luatexbase_error("Unable to create callback:\n" ..
                     "valid callback name and type required")
  end
  if callbacktypes[name] then
    luatexbase_error("Unable to create callback `" .. name ..
                     "':\ncallback is already defined")
  end
  default = default or defaults[ctype_id]
  if not default then
    luatexbase_error("Unable to create callback `" .. name ..
                     "':\ndefault is required for `" .. ctype ..
                     "' callbacks")
  elseif type (default) ~= "function" then
    luatexbase_error("Unable to create callback `" .. name ..
                     "':\ndefault is not a function")
  end
  user_callbacks_defaults[name] = default
  callbacktypes[name] = ctype_id
end
luatexbase.create_callback = create_callback
local function call_callback(name,...)
  if not name or name == "" then
    luatexbase_error("Unable to create callback:\n" ..
                     "valid callback name required")
  end
  if user_callbacks_defaults[name] == nil then
    luatexbase_error("Unable to call callback `" .. name
                     .. "':\nunknown or empty")
   end
  local l = callbacklist[name]
  local f
  if not l then
    f = user_callbacks_defaults[name]
  else
    f = handlers[callbacktypes[name]](name)
  end
  return f(...)
end
luatexbase.call_callback=call_callback
local function add_to_callback(name, func, description)
  if not name or name == "" then
    luatexbase_error("Unable to register callback:\n" ..
                     "valid callback name required")
  end
  if not callbacktypes[name] or
    type(func) ~= "function" or
    not description or
    description == "" then
    luatexbase_error(
      "Unable to register callback.\n\n"
        .. "Correct usage:\n"
        .. "add_to_callback(<callback>, <function>, <description>)"
    )
  end
  local l = realcallbacklist[name]
  if l == nil then
    l = { }
    realcallbacklist[name] = l
    local shared = shared_callbacks[name]
    if shared then
      shared.count = shared.count + 1
      if shared.count == 1 then
        callback_register(shared.callback, shared.handler)
      end
    elseif user_callbacks_defaults[name] == nil then
      callback_register(name, handlers[callbacktypes[name]](name))
    end
  end
  local f = {
    func        = func,
    description = description,
  }
  if callbacktypes[name] == exclusive then
    if #l == 1 then
      luatexbase_error(
        "Cannot add second callback to exclusive function\n`" ..
        name .. "'")
    end
  end
  table.insert(l, f)
  callbacklist[name] = nil
  luatexbase_log(
    "Inserting `" .. description .. "' in `" .. name .. "'."
  )
end
luatexbase.add_to_callback = add_to_callback
local function declare_callback_rule(name, desc1, relation, desc2)
  if not callbacktypes[name] or
    not desc1 or not desc2 or
    desc1 == "" or desc2 == "" then
    luatexbase_error(
      "Unable to create ordering constraint. "
        .. "Correct usage:\n"
        .. "declare_callback_rule(<callback>, <description_a>, <description_b>)"
    )
  end
  if relation == 'before' then
    relation = nil
  elseif relation == 'after' then
    desc2, desc1 = desc1, desc2
    relation = nil
  elseif relation == 'incompatible-warning' or relation == 'incompatible-error' then
  elseif relation == 'unrelated' then
  else
    luatexbase_error(
      "Unknown relation type in declare_callback_rule"
    )
  end
  callbacklist[name] = nil
  local rules = callbackrules[name]
  if rules then
    for i, rule in ipairs(rules) do
      if rule[1] == desc1 and rule[2] == desc2 or rule[1] == desc2 and rule[2] == desc1 then
        if relation == 'unrelated' then
          table.remove(rules, i)
        else
          rule[1], rule[2], rule.type = desc1, desc2, relation
        end
        return
      end
    end
    if relation ~= 'unrelated' then
      rules[#rules + 1] = {desc1, desc2, type = relation}
    end
  elseif relation ~= 'unrelated' then
    callbackrules[name] = {{desc1, desc2, type = relation}}
  end
end
luatexbase.declare_callback_rule = declare_callback_rule
local function remove_from_callback(name, description)
  if not name or name == "" then
    luatexbase_error("Unable to remove function from callback:\n" ..
                     "valid callback name required")
  end
  if not callbacktypes[name] or
    not description or
    description == "" then
    luatexbase_error(
      "Unable to remove function from callback.\n\n"
        .. "Correct usage:\n"
        .. "remove_from_callback(<callback>, <description>)"
    )
  end
  local l = realcallbacklist[name]
  if not l then
    luatexbase_error(
      "No callback list for `" .. name .. "'\n")
  end
  local index = false
  for i,j in ipairs(l) do
    if j.description == description then
      index = i
      break
    end
  end
  if not index then
    luatexbase_error(
      "No callback `" .. description .. "' registered for `" ..
      name .. "'\n")
  end
  local cb = l[index]
  table.remove(l, index)
  luatexbase_log(
    "Removing  `" .. description .. "' from `" .. name .. "'."
  )
  if #l == 0 then
    realcallbacklist[name] = nil
    callbacklist[name] = nil
    local shared = shared_callbacks[name]
    if shared then
      shared.count = shared.count - 1
      if shared.count == 0 then
        callback_register(shared.callback, nil)
      end
    elseif user_callbacks_defaults[name] == nil then
      callback_register(name, nil)
    end
  end
  return cb.func,cb.description
end
luatexbase.remove_from_callback = remove_from_callback
local function in_callback(name, description)
  if not name
    or name == ""
    or not realcallbacklist[name]
    or not callbacktypes[name]
    or not description then
      return false
  end
  for _, i in pairs(realcallbacklist[name]) do
    if i.description == description then
      return true
    end
  end
  return false
end
luatexbase.in_callback = in_callback
local function disable_callback(name)
  if(realcallbacklist[name] == nil) then
    callback_register(name, false)
  else
    luatexbase_error("Callback list for " .. name .. " not empty")
  end
end
luatexbase.disable_callback = disable_callback
local function callback_descriptions (name)
  local d = {}
  if not name
    or name == ""
    or not realcallbacklist[name]
    or not callbacktypes[name]
    then
    return d
  else
  for k, i in pairs(callbacklist[name]) do
    d[k]= i.description
    end
  end
  return d
end
luatexbase.callback_descriptions =callback_descriptions
local function uninstall()
  module_info(
    "luatexbase",
    "Uninstalling kernel luatexbase code"
  )
  callback.register = callback_register
  luatexbase = nil
end
luatexbase.uninstall = uninstall
create_callback('pre_mlist_to_hlist_filter', 'list')
create_callback('mlist_to_hlist', 'exclusive', node.mlist_to_hlist)
create_callback('post_mlist_to_hlist_filter', 'list')
function shared_callbacks.mlist_to_hlist.handler(head, display_type, need_penalties)
  local current = call_callback("pre_mlist_to_hlist_filter", head, display_type, need_penalties)
  if current == false then
    flush_list(head)
    return nil
  end
  current = call_callback("mlist_to_hlist", current, display_type, need_penalties)
  local post = call_callback("post_mlist_to_hlist_filter", current, display_type, need_penalties)
  if post == false then
    flush_list(current)
    return nil
  end
  return post
end
