#!/usr/bin/env texlua
--*-Lua-*-
-- $Id: ps2ascii.lua 65362 2022-12-26 19:12:37Z reinhardk $

-- Copyright (C) 2008-2022 Reinhard Kotucha.
-- You may freely use, modify and/or distribute this file.

doc = {
  invocation = '[options] <inputfile> <outputfile>',
  synopsis = 'Extract ASCII text from a PostScript file.',
  details = [=[
    <inputfile> can be either a PS or PDF file.  A single hyphen (-)
    denotes stdin.

    <outputfile> contains plain text.  A single hyphen (-) denotes stdout.
]=]}

default_outfile_ext = '.txt'

dofile(arg[0]:match('(.*[/\\]).*$')..'tlgs-common')

local command = {gsname()}

addto(command,
     '-sDEVICE=txtwrite',
     '-o'..file.output,
     '-f',
     file.input
)

execute(command)

-- Local Variables:
--  mode: Lua
--  lua-indent-level: 2
--  indent-tabs-mode: nil
--  coding: utf-8-unix
-- End:
-- vim:set tabstop=2 expandtab:
