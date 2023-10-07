-- 
--  This is file `pdftexcmds.lua',
--  generated with the docstrip utility.
-- 
--  The original source files were:
-- 
--  pdftexcmds.dtx  (with options: `lua')
--  
--  This is a generated file.
--  
--  Project: pdftexcmds
--  Version: 2020-06-27 v0.33
--  
--  Copyright (C)
--     2007, 2009-2011  Heiko Oberdiek
--     2016-2019        Oberdiek Package Support Group
--  
--  This work may be distributed and/or modified under the
--  conditions of the LaTeX Project Public License, either
--  version 1.3c of this license or (at your option) any later
--  version. This version of this license is in
--     https://www.latex-project.org/lppl/lppl-1-3c.txt
--  and the latest version of this license is in
--     https://www.latex-project.org/lppl.txt
--  and version 1.3 or later is part of all distributions of
--  LaTeX version 2005/12/01 or later.
--  
--  This work has the LPPL maintenance status "maintained".
--  
--  The Current Maintainers of this work are
--  Heiko Oberdiek and the Oberdiek Package Support Group
--  https://github.com/ho-tex/pdftexcmds/issues
--  
--  The Base Interpreter refers to any `TeX-Format',
--  because some files are installed in TDS:tex/generic//.
--  
--  This work consists of the main source file pdftexcmds.dtx
--  and the derived files
--     pdftexcmds.sty, pdftexcmds.pdf, pdftexcmds.ins, pdftexcmds.drv,
--     pdftexcmds.lua.
--  
oberdiek = oberdiek or {}
local pdftexcmds = oberdiek.pdftexcmds or {}
oberdiek.pdftexcmds = pdftexcmds
local systemexitstatus
function pdftexcmds.getversion()
  tex.write("2020-06-27 v0.33")
end
function pdftexcmds.strcmp(A, B)
  if A == B then
    tex.write("0")
  elseif A < B then
    tex.write("-1")
  else
    tex.write("1")
  end
end
local function utf8_to_byte(str)
  local i = 0
  local n = string.len(str)
  local t = {}
  while i < n do
    i = i + 1
    local a = string.byte(str, i)
    if a < 128 then
      table.insert(t, string.char(a))
    else
      if a >= 192 and i < n then
        i = i + 1
        local b = string.byte(str, i)
        if b < 128 or b >= 192 then
          i = i - 1
        elseif a == 194 then
          table.insert(t, string.char(b))
        elseif a == 195 then
          table.insert(t, string.char(b + 64))
        end
      end
    end
  end
  return table.concat(t)
end
function pdftexcmds.escapehex(str, mode)
  if mode == "byte" then
    str = utf8_to_byte(str)
  end
  tex.write((string.gsub(str, ".",
    function (ch)
      return string.format("%02X", string.byte(ch))
    end
  )))
end
function pdftexcmds.unescapehex(str, mode, patch)
  local a = 0
  local first = true
  local result = {}
  for i = 1, string.len(str), 1 do
    local ch = string.byte(str, i)
    if ch >= 48 and ch <= 57 then
      ch = ch - 48
    elseif ch >= 65 and ch <= 70 then
      ch = ch - 55
    elseif ch >= 97 and ch <= 102 then
      ch = ch - 87
    else
      ch = nil
    end
    if ch then
      if first then
        a = ch * 16
        first = false
      else
        table.insert(result, a + ch)
        first = true
      end
    end
  end
  if not first then
    table.insert(result, a)
  end
  if patch == 1 then
    local temp = {}
    for i, a in ipairs(result) do
      if a == 0 then
        table.insert(temp, 1)
        table.insert(temp, 1)
      else
        if a == 1 then
          table.insert(temp, 1)
          table.insert(temp, 2)
        else
          table.insert(temp, a)
        end
      end
    end
    result = temp
  end
  if mode == "byte" then
    local utf8 = {}
    for i, a in ipairs(result) do
      if a < 128 then
        table.insert(utf8, a)
      else
        if a < 192 then
          table.insert(utf8, 194)
          a = a - 128
        else
          table.insert(utf8, 195)
          a = a - 192
        end
        table.insert(utf8, a + 128)
      end
    end
    result = utf8
  end
  local unpack = _G["unpack"] or table.unpack
  tex.settoks(pdftexcmds.toks, string.char(unpack(result)))
end
function pdftexcmds.escapestring(str, mode)
  if mode == "byte" then
    str = utf8_to_byte(str)
  end
  tex.write((string.gsub(str, ".",
    function (ch)
      local b = string.byte(ch)
      if b < 33 or b > 126 then
        return string.format("\\%.3o", b)
      end
      if b == 40 or b == 41 or b == 92 then
        return "\\" .. ch
      end
      return nil
    end
  )))
end
function pdftexcmds.escapename(str, mode)
  if mode == "byte" then
    str = utf8_to_byte(str)
  end
  tex.write((string.gsub(str, ".",
    function (ch)
      local b = string.byte(ch)
      if b == 0 then
        return ""
      end
      if b <= 32 or b >= 127
          or b == 35 or b == 37 or b == 40 or b == 41
          or b == 47 or b == 60 or b == 62 or b == 91
          or b == 93 or b == 123 or b == 125 then
        return string.format("#%.2X", b)
      else
        return nil
      end
    end
  )))
end
function pdftexcmds.filesize(filename)
  local foundfile = kpse.find_file(filename, "tex", true)
  if foundfile then
    local size = lfs.attributes(foundfile, "size")
    if size then
      tex.write(size)
    end
  end
end
function pdftexcmds.filemoddate(filename)
  local foundfile = kpse.find_file(filename, "tex", true)
  if foundfile then
    local date = lfs.attributes(foundfile, "modification")
    if date then
      local d = os.date("*t", date)
      if d.sec >= 60 then
        d.sec = 59
      end
      local u = os.date("!*t", date)
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
        local hours = math.floor(off / 60)
        local mins = math.abs(off - hours * 60)
        timezone = string.format("%+03d'%02d'", hours, mins)
      end
      tex.write(string.format("D:%04d%02d%02d%02d%02d%02d%s",
          d.year, d.month, d.day, d.hour, d.min, d.sec, timezone))
    end
  end
end
function pdftexcmds.filedump(offset, length, filename)
  length = tonumber(length)
  if length and length > 0 then
    local foundfile = kpse.find_file(filename, "tex", true)
    if foundfile then
      offset = tonumber(offset)
      if not offset then
        offset = 0
      end
      local filehandle = io.open(foundfile, "rb")
      if filehandle then
        if offset > 0 then
          filehandle:seek("set", offset)
        end
        local dump = filehandle:read(length)
        pdftexcmds.escapehex(dump)
        filehandle:close()
      end
    end
  end
end
function pdftexcmds.mdfivesum(str, mode)
  if mode == "byte" then
    str = utf8_to_byte(str)
  end
  pdftexcmds.escapehex(md5.sum(str))
end
function pdftexcmds.filemdfivesum(filename)
  local foundfile = kpse.find_file(filename, "tex", true)
  if foundfile then
    local filehandle = io.open(foundfile, "rb")
    if filehandle then
      local contents = filehandle:read("*a")
      pdftexcmds.escapehex(md5.sum(contents))
      filehandle:close()
    end
  end
end
local basetime = 0
function pdftexcmds.resettimer()
  basetime = os.clock()
end
function pdftexcmds.elapsedtime()
  local val = (os.clock() - basetime) * 65536 + .5
  if val > 2147483647 then
    val = 2147483647
  end
  tex.write(string.format("%d", math.floor(val)))
end
function pdftexcmds.shellescape()
  if os.execute then
    if status
        and status.luatex_version
        and status.luatex_version >= 68 then
      tex.write(os.execute())
    else
      local result = os.execute()
      if result == 0 then
        tex.write("0")
      else
        if result == nil then
          tex.write("0")
        else
          tex.write("1")
        end
      end
    end
  else
    tex.write("0")
  end
end
function pdftexcmds.system(cmdline)
  systemexitstatus = nil
  texio.write_nl("log", "system(" .. cmdline .. ") ")
  if os.execute then
    texio.write("log", "executed.")
    systemexitstatus = os.execute(cmdline)
  else
    texio.write("log", "disabled.")
  end
end
function pdftexcmds.lastsystemstatus()
  local result = tonumber(systemexitstatus)
  if result then
    local x = math.floor(result / 256)
    tex.write(result - 256 * math.floor(result / 256))
  end
end
function pdftexcmds.lastsystemexit()
  local result = tonumber(systemexitstatus)
  if result then
    tex.write(math.floor(result / 256))
  end
end
function pdftexcmds.pipe(cmdline, patch)
  local result
  systemexitstatus = nil
  texio.write_nl("log", "pipe(" .. cmdline ..") ")
  if io.popen then
    texio.write("log", "executed.")
    local handle = io.popen(cmdline, "r")
    if handle then
      result = handle:read("*a")
      handle:close()
    end
  else
    texio.write("log", "disabled.")
  end
  if result then
    if patch == 1 then
      local temp = {}
      for i, a in ipairs(result) do
        if a == 0 then
          table.insert(temp, 1)
          table.insert(temp, 1)
        else
          if a == 1 then
            table.insert(temp, 1)
            table.insert(temp, 2)
          else
            table.insert(temp, a)
          end
        end
      end
      result = temp
    end
    tex.settoks(pdftexcmds.toks, result)
  else
    tex.settoks(pdftexcmds.toks, "")
  end
end
-- 
--  End of File `pdftexcmds.lua'.
