#!/usr/bin/env texlua
--*-Lua-*-
-- $Id: ps2pdf13.lua 65362 2022-12-26 19:12:37Z reinhardk $

-- Copyright (C) 2008-2022 Reinhard Kotucha.
-- You may freely use, modify and/or distribute this file.

doc = {
  invocation = '[options] <inputfile> [<outputfile>]',
  synopsis = 'Convert PostScript to PDF version @PDF_level@.',
  details = [=[
    <inputfile> can be either a PS, EPS, or PDF file.
    A single hyphen (-) denotes stdin.

    <outputfile> is required if <inputfile> is a PDF file
    or input is read from stdin.
]=]}

default_outfile_ext = '.pdf'

dofile(arg[0]:match('(.*[/\\])')..'tlgs-common')

local command = {gsname()}

addto(command,
     '-sDEVICE=pdfwrite',
     '-dCompatibilityLevel='..PDF_level(progname),
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

