#!/usr/bin/env texlua
--*-Lua-*-
-- $Id: pdf2ps.lua 65362 2022-12-26 19:12:37Z reinhardk $

-- Copyright (C) 2008-2022 Reinhard Kotucha.
-- You may freely use, modify and/or distribute this file.

doc = {
  invocation = '[options] <inputfile> [<outputfile>]',
  synopsis = 'Convert PDF tlo PostScript level 2.',
  details = [=[
    <inputfile> is a PDF file.  A single hyphen (-) denotes stdin.

    <outputfile> is required if <inputfile> is a PDF file
    or input is read from stdin.
]=]}

default_outfile_ext = '.ps'

dofile(arg[0]:match('(.*[/\\])')..'tlgs-common')

local command = {gsname()}

-- Doing an initial 'save' helps keep fonts from being flushed between pages.

addto(command,
      '-sDEVICE=ps2write',
      '-o'..file.output,
      options,
      '-c',
      'save',
      'pop',
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

