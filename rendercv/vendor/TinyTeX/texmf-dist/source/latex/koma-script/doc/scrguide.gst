% ======================================================================
% scrguide.gst
% Copyright (c) Markus Kohm, 2002-2012
%
% This file is part of the LaTeX2e KOMA-Script bundle.
%
% This work may be distributed and/or modified under the conditions of
% the LaTeX Project Public License, version 1.3c of the license.
% The latest version of this license is in
%   http://www.latex-project.org/lppl.txt
% and version 1.3c or later is part of all distributions of LaTeX 
% version 2005/12/01 or later and of this work.
%
% This work has the LPPL maintenance status "author-maintained".
%
% The Current Maintainer and author of this work is Markus Kohm.
%
% This work consists of all files listed in MANIFEST.md.
% ----------------------------------------------------------------------
% scrguide.gst
% Copyright (c) Markus Kohm, 2002-2012
%
% Dieses Werk darf nach den Bedingungen der LaTeX Project Public Lizenz,
% Version 1.3c, verteilt und/oder veraendert werden.
% Die neuste Version dieser Lizenz ist
%   http://www.latex-project.org/lppl.txt
% und Version 1.3c ist Teil aller Verteilungen von LaTeX
% Version 2005/12/01 oder spaeter und dieses Werks.
%
% Dieses Werk hat den LPPL-Verwaltungs-Status "author-maintained"
% (allein durch den Autor verwaltet).
%
% Der Aktuelle Verwalter und Autor dieses Werkes ist Markus Kohm.
% 
% Dieses Werk besteht aus den in MANIFEST.md aufgefuehrten Dateien.
% ======================================================================
% MakeIndex style for change log generation based on `scrguide.ist'.
%
% Usage: makeindex -r -s scrguide.gst -o scrguide.chn scrguide.glo
% ----------------------------------------------------------------------
% MakeIndex-Style fuer die Aenderungsliste der KOMA-Script-Anleitung
% Dies basiert auf "scrguide.ist"
% 
% Verwendung: makeindx -r -s scrguide.gst -o scrguide.chn scrguide.glo
% ======================================================================
%
level  '>'
actual '='
encap  '|'
quote  '~'
%
preamble  "\\begin{thechangelog}\n"
postamble "\n\\end{thechangelog}\n"
%
delim_0 "~\\dotfill~"
delim_1 "~\\dotfill~"
delim_2 "~\\dotfill~"
%
headings_flag    0
%
keyword "\\glossaryentry"
%
% Ende der Datei `scrguide.gst'
