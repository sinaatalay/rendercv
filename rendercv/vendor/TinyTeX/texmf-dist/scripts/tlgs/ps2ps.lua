#!/usr/bin/env texlua
--*-Lua-*-
-- $Id: ps2ps.lua 65362 2022-12-26 19:12:37Z reinhardk $

-- Copyright (C) 2010-2022 Reinhard Kotucha.
-- You may freely use, modify and/or distribute this file.

doc = {
  invocation = '[options] <inputfile> <outputfile>',
  synopsis = 'Convert PDF or PS3 to PostScript Level 2',
  details = [=[
    <inputfile> can be either an EPS or PS file, or stdin.
    A single hyphen (-) denotes stdin.

    <outputfile> is a PostScript Level 2 file.
    A single hyphen (-) denotes stdout.
]=]}

dofile(arg[0]:match('(.*[/\\]).*$')..'tlgs-common')

local command = {gsname()}

addto(command,
     '-sDEVICE=ps2write',
     '-o'..file.output,
     options,
     '-f',
     file.input)

execute(command)


-- Local Variables:
--  mode: Lua
--  lua-indent-level: 2
--  indent-tabs-mode: nil
--  coding: utf-8-unix
-- End:
-- vim:set tabstop=2 expandtab:
