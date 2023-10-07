% ======================================================================
% scrstrip.inc
% Copyright (c) Markus Kohm, 2002-2022
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
% In particular, NO PERMISSION is granted to modify the contents of this
% file since it contains the legal notices that are placed in the files
% it generates.
%
% This work consists of all files listed in MANIFEST.md.
% ======================================================================
% This file will be included at startup of every KOMA-Script 
% docstrip batch file.
% ======================================================================
% $Id: scrstrip.inc 3965 2022-10-12 08:28:57Z kohm $

% ---------- start of docstrip -----------------------------------------

\KOMAdefVariable{AUTHOR}{Markus Kohm}
\KOMAdefVariable{EMAIL}{[komascript at gmx info]}
\KOMAdefVariable{COPYRIGHTFROM}{1994}
\KOMAdefVariable{COPYRIGHTTILL}{2022}

\ifToplevel{%
  \Msg{+======================================================================}
  \Msg{| KOMA-Script}
  \Msg{| a versatile LaTeX2e bundle}
  \Msg{+----------------------------------------------------------------------}
  \Msg{| This batchfile will unpack some or all parts of KOMA-Script.}
  \Msg{| On errors press either `h' or ask an expert for help after reading}
  \Msg{| `README'.}
  \Msg{+----------------------------------------------------------------------}
% ---------- some docstrip switchs -------------------------------------
  \keepsilent
  \askforoverwritefalse
}

% ---------- defining preambles ----------------------------------------

\preamble

\noexpand\KOMAuseVariable{COPYRIGHT}

This file was generated from file(s) of the KOMA-Script bundle.
---------------------------------------------------------------

It may be distributed under the conditions of the 
LaTeX Project Public License in the version distributed together
with KOMA-Script, see file `lppl.txt' or `lppl-de.txt'.

This file may only be distributed together with a copy of the
KOMA-Script bundle.  You may however distribute the 
KOMA-Script bundle without all such generated files.  See also
`lppl.txt' or `lppl-de.txt' for additional information.

The list of files belonging to KOMA-Script distribution is given in
the file `MANIFEST.md'.  See also `lppl.txt' or `lppl-de.txt' for 
additional information.

If this file is a beta version, you may not be allowed to distribute 
it.  Look at the comments below to see if this is the case.

English and German manuals are part of KOMA-Script bundle. 
----------------------------------------------------------

See `README'.

The KOMA-Script bundle (but maybe not this file) was based upon the
LaTeX 2.09 Script family created by Frank Neukam 1993 and the LaTeX2e
standard classes created by The LaTeX3 Project 1994-1996.  You can
find a complete unmodified copy of LaTeX2e at 
<http://mirror.ctan.org/tex-archive/macros/latex/base/>.

\endpreamble

\endinput

%%% Local Variables:
%%% mode: latex
%%% End:
