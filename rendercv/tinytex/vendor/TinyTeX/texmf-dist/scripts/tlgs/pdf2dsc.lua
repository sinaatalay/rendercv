#!/usr/bin/env texlua
--*-Lua-*-
-- $Id: pdf2dsc.lua 65362 2022-12-26 19:12:37Z reinhardk $

-- Copyright (C) 2007-2022 Reinhard Kotucha.
-- You may freely use, modify and/or distribute this file.

doc = {
  invocation = '[options] <inputfile> [<outputfile>]',
  synopsis = 'Extract DSCs from PDF files',
  details = [=[
    <inputfile> is a PDF file.  <outputfile> is a DSC file.
]=]}

default_outfile_ext = '.dsc'

dofile(arg[0]:match('(.*[/\\]).*$')..'tlgs-common')

local command = {gsname()}

addto(command,
     '-dDELAYSAFER',
     '-dNODISPLAY', 
     '-sPDFname='..file.input,
     '-sDSCname='..file.output,
     'pdf2dsc.ps')

execute(command)

-- Local Variables:
--  mode: Lua
--  lua-indent-level: 2
--  indent-tabs-mode: nil
--  coding: utf-8-unix
-- End:
-- vim:set tabstop=2 expandtab:
