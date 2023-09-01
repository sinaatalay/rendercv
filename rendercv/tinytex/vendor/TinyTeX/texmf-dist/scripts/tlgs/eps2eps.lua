#!/usr/bin/env texlua
--*-Lua-*-
-- $Id: eps2eps.lua 65362 2022-12-26 19:12:37Z reinhardk $

-- Copyright (C) 2008-2022 Reinhard Kotucha.
-- You may freely use, modify and/or distribute this file.

doc = {
  invocation = '[options] <inputfile> <outputfile>',
  synopsis = '"Distill" Encapsulated PostScript.',
  details = [=[
    <inputfile> can be either an EPS or PS file.  A single hyphen (-)
    denotes stdin.

    <outputfile> is an EPS file with a re-calculated BoundingBox. 
    A single hyphen (-) denotes stdout.
]=]}

dofile(arg[0]:match('(.*[/\\]).*$')..'tlgs-common') 

local command = {gsname()}

addto(command,
     '-sDEVICE=eps2write',
     '-dDEVICEWIDTH=250000', 
     '-dDEVICEHEIGHT=250000',
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
