%%
%% This is file `proc.cls',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% proc.dtx  (with options: `class')
%% 
%% This is a generated file.
%% 
%% The source is maintained by the LaTeX Project team and bug
%% reports for it can be opened at https://latex-project.org/bugs.html
%% (but please observe conditions on bug reports sent to that address!)
%% 
%% 
%% Copyright (C) 1993-2023
%% The LaTeX Project and any individual authors listed elsewhere
%% in this file.
%% 
%% This file was generated from file(s) of the LaTeX base system.
%% --------------------------------------------------------------
%% 
%% It may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, either version 1.3c
%% of this license or (at your option) any later version.
%% The latest version of this license is in
%%    https://www.latex-project.org/lppl.txt
%% and version 1.3c or later is part of all distributions of LaTeX
%% version 2008 or later.
%% 
%% This file has the LPPL maintenance status "maintained".
%% 
%% This file may only be distributed together with a copy of the LaTeX
%% base system. You may however distribute the LaTeX base system without
%% such generated files.
%% 
%% The list of all files belonging to the LaTeX base distribution is
%% given in the file `manifest.txt'. See also `legal.txt' for additional
%% information.
%% 
%% The list of derived (unpacked) files belonging to the distribution
%% and covered by LPPL is defined by the unpacking scripts (with
%% extension .ins) which are part of the distribution.
\NeedsTeXFormat{LaTeX2e}[1995/12/01]
\ProvidesClass{proc}
              [2021/12/09 v1.3m
               Standard LaTeX document class]
\DeclareOption{a5paper}
    {\ClassError{proc}{Option `a5paper' not supported}{}}
\DeclareOption{b5paper}
    {\ClassError{proc}{Option `b5paper' not supported}{}}
\DeclareOption{onecolumn}%
    {\ClassError{proc}{Option `onecolumn' not supported}{}}
\DeclareOption{titlepage}%
    {\ClassError{proc}{Option `titlepage' not supported}{}}
\PassOptionsToClass{twocolumn}{article}
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions
\LoadClass{article}
\setlength\footskip{75\p@}
\if@compatibility
  \setlength\textwidth{6.75in}
\else
  \setlength\textwidth{\paperwidth}
  \addtolength\textwidth{-126\p@}
  \@settopoint\textwidth
\fi
\if@compatibility
\else
  \@settopoint\textwidth
\fi
\if@compatibility
  \setlength\textheight{9in}
\else
  \ifcase\@ptsize
    \setlength\textheight{53\baselineskip}
  \or
    \setlength\textheight{47\baselineskip}
  \or
    \setlength\textheight{44\baselineskip}
  \fi
\fi
\advance\textheight by \topskip
\setlength\oddsidemargin{-10\p@}
\setlength\evensidemargin{-10\p@}
\setlength\marginparwidth {\z@}
\setlength\topmargin{-47\p@}
\setlength\columnsep{.375in}
\let\@oddhead\@empty
\let\@evenhead\@empty
\def\@oddfoot{\rightmark \hfil \pagename{} \thepage}
\if@twoside
  \def\@evenfoot{\pagename{} \thepage \hfil \leftmark}
\else
  \def\@evenfoot{\@oddfoot}
\fi
\def\maketitle{\par
 \begingroup
   \renewcommand\thefootnote{\fnsymbol{footnote}}%
    \def\@makefnmark{\rlap{\@textsuperscript{\normalfont\@thefnmark}}}%
     \long\def\@makefntext##1{\parindent 1em\noindent
             \hb@xt@1.8em{%
                 \hss\@textsuperscript{\normalfont\@thefnmark}}##1}%
   \twocolumn[\@maketitle]%
   \@thanks
 \endgroup
 \setcounter{footnote}{0}%
 \let\maketitle\relax
 \let\@maketitle\relax
 \gdef\@thanks{}\gdef\@author{}\gdef\@title{}\let\thanks\relax}
\def\@maketitle{%
  \vbox to 2.25in{%
    \hsize\textwidth
    \linewidth\hsize
    \vfil
    \centering
    {\LARGE \@title \par}
    \vskip 2em
    {\large \begin{tabular}[t]{c}\@author \end{tabular}\par}
    \vfil}}
\def\copyrightspace{%
  \footnotetext[0]{\mbox{}\vrule \@height 97\p@ \@width \z@}}
\renewenvironment{abstract}%
  {\section*{\abstractname}}
  {\par}
\newcommand\pagename{Page}
\endinput
%%
%% End of file `proc.cls'.
