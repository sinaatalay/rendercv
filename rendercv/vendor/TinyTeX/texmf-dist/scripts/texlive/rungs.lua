#!/usr/bin/env texlua
--*-Lua-*-

-- $Id: rungs.lua 64342 2022-09-11 19:08:51Z reinhardk $

-- rungs - Run Ghostscript (gs on Unix, gswin(32|64)c on Windows)

-- Copyright (C) 2008-2022 Reinhard Kotucha.
-- You may freely use, modify and/or distribute this file.

-- Maintained in TeX Live:Master/texmf-dist/scripts/texlive.


function fixwindows (args_unix)
   -- Windows converts the argument vector specified by execv*() to a
   -- string and then back to a vector (argv).  In order to support
   -- spaces in filenames each argument has to be quoted explicitly.
   
   if os.type == 'windows' then
      local args_windows = {}  -- new table
      args_windows[0] = args_unix[1]
      for i=1, #args_unix do  
	 args_windows[i] = '"'..args_unix[i]..'"'
      end
      return args_windows
   else
      return args_unix
   end
end


if os.type == 'windows' then
   if os.getenv('PROCESSOR_ARCHITECTURE') == 'AMD64' or
      os.getenv('PROCESSOR_ARCHITEW6432') == 'AMD64'
   then
      command = {'gswin64c'}
   else
      command = {'gswin32c'}
   end
else
   command = {'gs'}
end

for i=1, #arg do
   command[#command+1] = arg[i]
end

command = fixwindows (command)

--[[ prepend an additional hyphen to activate this code
for i=0, #command do
   print (command[i])
end
os.exit(ret)
--]]

ret = os.spawn(command)
os.exit(ret)
