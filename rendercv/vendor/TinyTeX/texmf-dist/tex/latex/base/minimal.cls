% \iffalse meta-comment
%
% Copyright (C) 1993-2023
% The LaTeX Project and any individual authors listed elsewhere
% in this file.
%
% This file is part of the LaTeX base system.
% -------------------------------------------
%
% It may be distributed and/or modified under the
% conditions of the LaTeX Project Public License, either version 1.3c
% of this license or (at your option) any later version.
% The latest version of this license is in
%    https://www.latex-project.org/lppl.txt
% and version 1.3c or later is part of all distributions of LaTeX
% version 2008 or later.
%
% This file has the LPPL maintenance status "maintained".
%
% The list of all files belonging to the LaTeX base distribution is
% given in the file `manifest.txt'. See also `legal.txt' for additional
% information.
%
% The list of derived (unpacked) files belonging to the distribution
% and covered by LPPL is defined by the unpacking scripts (with
% extension .ins) which are part of the distribution.
%
% \fi
%%
%% Minimal LaTeX class file.
%%

\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{minimal}[2001/05/25 Standard LaTeX minimal class]

\renewcommand\normalsize{\fontsize{10pt}{12pt}\selectfont}

\setlength{\textwidth}{6.5in}
\setlength{\textheight}{8in}

\pagenumbering{arabic}  % but no page numbers are printed because:
\pagestyle{empty}       % this is actually already in the kernel

% This documentclass is intended primarily for testing and reference
% purposes; loading it with \LoadClass{minimal} to use it as a base
% class for some other document class is probably a mistake. If you wish
% to start a new document class based on the minimal class, it is better
% to start by copying the *contents* of minimal.cls directly into your
% new class and making suitable modifications. You may, at that point
% also want to start documenting the code using the conventions of the
% doc package, rather than using simple ascii comments as used here.
