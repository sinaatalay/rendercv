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
% Filename: ltnews.cls
% Author: Alan Jeffrey et al

% This is the LaTeX2e document class for the `LaTeX News' information
% sheet which comes with every LaTeX release.  It may be useful for
% newsletters, or as an example of how simple newsletters can be set
% with LaTeX.  The changes log is at the end of the file.

% Copyright 1994-2004
% Alan Jeffrey and the LaTeX Project.

% This is a LaTeX2e document class.

\NeedsTeXFormat{LaTeX2e}

\ProvidesClass{ltnews}[2023/05/28 v1.08  Standard LaTeX class]

% The configuration file, used for passing options.

\InputIfFileExists{ltnews.cfg}{%
   \ClassInfo{ltnews}{Using local configuration file}%
}{%
   \ClassInfo{ltnews}{No local configuration file}%
}

% The lw35fonts option uses the fonts:
%
%    Adobe Palatino          (main text)
%    Adobe Helvetica Bold    (headings)
%    Courier                 (program listings)
%    Mathptm math italic     (2e logo)
%    Mathptm symbol font     (AMS logo)
%
% The type1fonts option uses the fonts:
%
%    Adobe Utopia            (main text)
%    URW Grotesk-T Bold      (headings)
%    Lucida Sans typewriter  (program listings)
%    Mathptm math italic     (2e logo)
%    Mathptm symbol font     (AMS logo)

% The Adobe Palatino fonts:

\DeclareFontFamily{OT1}{ppl}{}
\DeclareFontShape{OT1}{ppl}{m}{n}{<-> pplr7t}{}
\DeclareFontShape{OT1}{ppl}{bx}{n}{<-> pplb7t}{}
\DeclareFontShape{OT1}{ppl}{m}{sc}{<-> pplrc7t}{}
\DeclareFontShape{OT1}{ppl}{m}{it}{<-> pplri7t}{}
\DeclareFontShape{OT1}{ppl}{m}{sl}{<-> pplro7t}{}

\DeclareFontFamily{T1}{ppl}{}
\DeclareFontShape{T1}{ppl}{m}{n}{<-> pplr8t}{}
\DeclareFontShape{T1}{ppl}{bx}{n}{<-> pplb8t}{}
\DeclareFontShape{T1}{ppl}{m}{sc}{<-> pplrc8t}{}
\DeclareFontShape{T1}{ppl}{m}{it}{<-> pplri8t}{}
\DeclareFontShape{T1}{ppl}{m}{sl}{<-> pplro8t}{}

% The Adobe Helvetica fonts:

\DeclareFontFamily{OT1}{phv}{}
\DeclareFontShape{OT1}{phv}{m}{n}{<-> s*[0.86] phvr7t}{}
\DeclareFontShape{OT1}{phv}{b}{n}{<-> phvb7t}{}

\DeclareFontFamily{T1}{phv}{}
\DeclareFontShape{T1}{phv}{m}{n}{<-> s*[0.86] phvr8t}{}
\DeclareFontShape{T1}{phv}{b}{n}{<-> phvb8t}{}

% The Adobe Courier fonts:

\DeclareFontFamily{OT1}{pcr}{\hyphenchar\font=-1}
\DeclareFontShape{OT1}{pcr}{m}{n}{<-> s*[0.89] pcrr7t}{}

\DeclareFontFamily{T1}{pcr}{\hyphenchar\font=-1}
\DeclareFontShape{T1}{pcr}{m}{n}{<-> s*[0.89] pcrr8t}{}

% The Utopia fonts:

\DeclareFontFamily{OT1}{put}{}
\DeclareFontShape{OT1}{put}{m}{n}{<-> putr7t}{}
\DeclareFontShape{OT1}{put}{m}{sc}{<-> putrc7t}{}
\DeclareFontShape{OT1}{put}{m}{it}{<-> putri7t}{}

% The URW Grotesk fonts:

\DeclareFontFamily{OT1}{ugq}{}
\DeclareFontShape{OT1}{ugq}{b}{n}{<-> ugqb7t}{}

% The Lucida Sans Typewriter fonts:

\DeclareFontFamily{OT1}{hlct}{\hyphenchar\font=-1}
\DeclareFontShape{OT1}{hlct}{m}{n}{<-> hlct7t}{}

% The mathptm math italic:

\DeclareFontFamily{OML}{ptmcm}{\skewchar\font=127}
\DeclareFontShape{OML}{ptmcm}{m}{it}{<-> zptmcmrm}{}

% The mathptm symbol font:

\DeclareFontFamily{OMS}{pzccm}{}
\DeclareFontShape{OMS}{pzccm}{m}{n}{<-> zpzccmry}{}

% The TeX logo for use with Palatino.

\def\pplTeX{T\kern-.15em\lower.4ex\hbox{E}\kern-.1emX\@}

% The LaTeX logo for use with Palatino.

\DeclareRobustCommand{\pplLaTeX}{L\kern-.3em
        {\setbox0\hbox{T}%
         \vbox to\ht0{\hbox{%
                            \csname S@\f@size\endcsname
                            \fontsize\sf@size\z@
                            \math@fontsfalse\selectfont
                            A}%
                      \vss}%
        }%
        \kern-.07em
        \TeX}

% The TeX logo for use with Utopia.

\def\putTeX{T\kern-.1667em\lower.4ex\hbox{E}\kern-.075emX\@}

% The LaTeX logo for use with Utopia.

\DeclareRobustCommand{\putLaTeX}{L\kern-.2em
        {\setbox0\hbox{T}%
         \vbox to\ht0{\hbox{%
                            \csname S@\f@size\endcsname
                            \fontsize\sf@size\z@
                            \math@fontsfalse\selectfont
                            A}%
                      \vss}%
        }%
        \kern-.05em
        \TeX}

% The TeX logo for use with Helvetica.

\def\phvTeX{T\kern-.1em\lower.4ex\hbox{E}\kern-.05emX\@}

% The LaTeX logo for use with Helvetica.

\DeclareRobustCommand{\phvLaTeX}{L\kern-.3em
        {\calculate@math@sizes
         \setbox0\hbox{T}%
         \vbox to\ht0{\hbox{%
                            \csname S@\f@size\endcsname
                            \fontsize\sf@size\z@
                            \math@fontsfalse\selectfont
                            A}%
                      \vss}%
        }%
        \kern-.05em
        \TeX}

% The TeX logo for use with Grotesk.

\def\ugqTeX{T\kern-.1em\lower.4ex\hbox{E}\kern-.05emX\@}

% The LaTeX logo for use with Grotesk.

\DeclareRobustCommand{\ugqLaTeX}{L\kern-.15em
        {\calculate@math@sizes
         \setbox0\hbox{T}%
         \vbox to\ht0{\hbox{%
                            \csname S@\f@size\endcsname
                            \fontsize\sf@size\z@
                            \math@fontsfalse\selectfont
                            A}%
                      \vss}%
        }%
        \kern-.01em
        \TeX}

% The TeX logo for use with CMSS.

\def\cmssTeX{T\kern-.2em\lower.4ex\hbox{E}\kern-.05emX\@}

% The LaTeX logo for use with CMSS.

\DeclareRobustCommand{\cmssLaTeX}{L\kern-.22em
        {\setbox0\hbox{T}%
         \vbox to\ht0{\hbox{%
                            \csname S@\f@size\endcsname
                            \fontsize\sf@size\z@
                            \math@fontsfalse\selectfont
                            A}%
                      \vss}%
        }%
        \kern-.17em
        \TeX}

% The eTeX logo.

\DeclareRobustCommand\eTeX{\ensuremath{\varepsilon}-\kern-.125em\TeX}

% Switch off some of the article options.

\DeclareOption{a4paper}{\OptionNotUsed}
\DeclareOption{a5paper}{\OptionNotUsed}
\DeclareOption{b5paper}{\OptionNotUsed}
\DeclareOption{letterpaper}{\OptionNotUsed}
\DeclareOption{legalpaper}{\OptionNotUsed}
\DeclareOption{executivepaper}{\OptionNotUsed}
\DeclareOption{landscape}{\OptionNotUsed}
\DeclareOption{twoside}{\OptionNotUsed}
\DeclareOption{titlepage}{\OptionNotUsed}
\DeclareOption{onecolumn}{\OptionNotUsed}

% The CM fonts

\newcommand{\@titlefont}{\normalfont\Huge}
\newcommand{\@indiciafont}{\normalfont\footnotesize}
\newcommand{\@headingfont}{%
   \large\sffamily\slshape
   \let\LaTeX\cmssLaTeX\let\TeX\cmssTeX
}
\newcommand{\@subheadingfont}{%
   \normalsize\sffamily\slshape
   \let\LaTeX\cmssLaTeX\let\TeX\cmssTeX
}

% The LW 35 fonts option

%% The size of the haeding font was reduced (from 14pt) here to
%%   try and ensure that the pagination does not change whilst the
%%   line count remains the same.
\DeclareOption{lw35fonts}{%
   \renewcommand{\rmdefault}{ppl}%
   \renewcommand{\ttdefault}{pcr}%
   \renewcommand{\sfdefault}{phv}%
   \renewcommand{\@titlefont}{%
      \fontsize{50}{60}\fontfamily{phv}\fontseries{b}\selectfont
      \let\LaTeX\phvLaTeX\let\TeX\phvTeX
   }%
   \renewcommand{\@indiciafont}{%
      \fontsize{8}{10}\fontfamily{ppl}\fontshape{it}\selectfont
   }%
   \renewcommand{\@headingfont}{%
      \fontsize{12}{13.5}\fontfamily{phv}\fontseries{b}\selectfont
      \let\LaTeX\phvLaTeX\let\TeX\phvTeX
   }%
   \renewcommand{\@subheadingfont}{%
      \fontsize{10}{12}\fontfamily{phv}\fontseries{b}\selectfont
      \let\LaTeX\phvLaTeX\let\TeX\phvTeX
   }%
   \DeclareSymbolFont{letters}{OML}{ptmcm}{m}{it}%
   \DeclareSymbolFont{symbols}{OMS}{pzccm}{m}{n}%
   \let\LaTeX\pplLaTeX
   \let\TeX\pplTeX
   \AtEndOfClass{\addtolength\textheight\baselineskip}%
   }

% The type 1 fonts option

\DeclareOption{type1fonts}{%
   \renewcommand{\rmdefault}{put}%
   \renewcommand{\ttdefault}{hlct}%
   \renewcommand{\sfdefault}{ugq}%
   \renewcommand{\@titlefont}{%
      \fontsize{50}{60}\fontfamily{ugq}\fontseries{b}\selectfont
      \let\LaTeX\ugqLaTeX\let\TeX\ugqTeX
   }%
   \renewcommand{\@indiciafont}{%
      \fontsize{8}{10}\fontfamily{put}\fontshape{it}\selectfont
   }%
   \renewcommand{\@headingfont}{%
      \fontsize{12}{14}\fontfamily{ugq}\fontseries{b}\selectfont
      \let\LaTeX\ugqLaTeX\let\TeX\ugqTeX
   }%
   \renewcommand{\@subheadingfont}{%
      \fontsize{10}{12}\fontfamily{ugq}\fontseries{b}\selectfont
      \let\LaTeX\ugqLaTeX\let\TeX\ugqTeX
   }%
   \renewcommand{\verbatim@font}{%
      \fontsize{9}{12}\fontfamily{hlct}\selectfont
   }%
   \DeclareSymbolFont{letters}{OML}{ptmcm}{m}{it}%
   \DeclareSymbolFont{symbols}{OMS}{pzccm}{m}{n}%
   \let\LaTeX\putLaTeX
   \let\TeX\putTeX
}

% The default action for any option is to pass it to the article
% class.

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}

% Execute the options.

\ProcessOptions

% Load the article class.

\LoadClass[twocolumn,oneside]{article}

%
% The package url.sty takes care of breaking url's that are too long
% to fit in a two-column design
% but it might not be available on all installations.
% Therefore we need to check if the file url.sty can be found.
%
% Also, it uses a verbatim input mode so Chris does not use it for
% urls as he wants to control layout and use macros within it.  Also
% he usuually wants to hand-craft the line-breaks in such text.
%
\IfFileExists{url.sty}{%
  \RequirePackage{url}
  \newcommand\email{\begingroup \Url}}{%
  \newcommand*{\url}[1]{\texttt{##1}}
  \newcommand*{\email}[1]{\texttt{##1}}
  }
%
% The package html.sty defines a number of things needed for the LaTeX
% to HTML conversion; noticeable the latexonly and htmlonly
% environments.
% Again, let's check if it exists and if not provide necessary stubs
%
\IfFileExists{html.sty}{%
  \RequirePackage{html}}{%
  % When it couldn't be found, provide some necessary stuff...
  \newenvironment{latexonly}{}{}
  \newcommand{\latex}[1]{##1}
%
%  Code for excludecomment from html.sty
%  by Robin Fairbairns, 22 September 1997
%
  \newcommand\@gobbleenv{\let\reserved@a\@currenvir\@gobble@nv}
  \long\def\@gobble@nv##1\end##2{%
    \def\reserved@b{##2}%
    \ifx\reserved@a\reserved@b
      \edef\reserved@a{\noexpand\end{\reserved@a}}%
      \expandafter\reserved@a
    \else
      \expandafter\@gobble@nv
    \fi
    }
  \newcommand{\excludecomment}[1]{%
    \csname newenvironment\endcsname{##1}{\@gobbleenv}{}}
  \excludecomment{htmlonly}
  }

%
% If pdf is being produced add some info to the pdf file and use hyperref.
% But move this after other packages are, possibly, loaded.
% LuaTeX support.
\ifx\pdfoutput\@undefined
  \let\pdfoutput\outputmode
  \protected\def\pdfinfo{\pdfextension info }
\fi
\ifx\pdfoutput\@undefined\else
  \ifx\pdfoutput\relax\else
    \ifcase\pdfoutput\else
      \pdfinfo{%
        /Title (LaTeX News)
        /Author (The LaTeX Project)
      }
\IfFileExists{hyperref.sty}{%
  \RequirePackage[hidelinks]{hyperref}}{}
    \fi
  \fi
\fi
% This should be further enhanced so that links other than those
% naively generated by \url can be produced in the pdf file.

%% Please DO NOT load any packages after this point.
%%


% The page style.

\pagestyle{empty}
\renewcommand{\@oddfoot}{\@indiciafont\mbox{}\hfill --\thepage}%
\renewcommand{\@evenfoot}{\@indiciafont\mbox{}\hfill --\thepage}%

\setlength{\parindent}{1em}
% Why \textwidth?
\setlength{\rightskip}{0pt plus \textwidth}
\setlength{\@rightskip}{\rightskip}
\setlength{\parfillskip}{0pt plus 2\textwidth}
\setlength{\columnsep}{2em}

% The text size, which tries to work with both A4 and letter paper
% sizes.

\setlength{\textheight}{230mm}
\setlength{\topmargin}{-10mm}

\setlength{\textwidth}{180mm}
\setlength{\oddsidemargin}{-10mm}

% \maketitle parameters.

\newcommand{\publicationmonth}{\renewcommand{\@month}}
\newcommand{\@month}{\ClassError{ltnews}
   {No \protect\publicationmonth~given}\@eha}

\newcommand{\publicationyear}{\renewcommand{\@year}}
\newcommand{\@year}{\ClassError{ltnews}
   {No \protect\publicationyear~given}\@eha}

\newcommand{\publicationday}{\renewcommand{\@day}}
\newcommand{\@day}{01} % most releases happen on 1st of a month

\newcommand{\publicationdate}{%
  % support draft ltnews, \publicationyear{2023 --- DRAFT ...}
  \expandafter\@gobblenonyear\@year\@nil
  -\@julianmonthtonum\@month-\two@digits\@day}

\newcommand{\@julianmonthtonum}[1]{\@nameuse{@juliantonum#1}}
\def\@juliantonumJanuary  {01}
\def\@juliantonumFebruary {02}
\def\@juliantonumMarch    {03}
\def\@juliantonumApril    {04}
\def\@juliantonumMay      {05}
\def\@juliantonumJune     {06}
\def\@juliantonumJuly     {07}
\def\@juliantonumAugust   {08}
\def\@juliantonumSeptember{09}
\def\@juliantonumOctober  {10}
\def\@juliantonumNovember {11}
\def\@juliantonumDecember {12}

\long\def\@gobblenonyear#1#2#3#4#5\@nil{#1#2#3#4}

\newcommand{\publicationissue}{\renewcommand{\@issue}}
\newcommand{\@issue}{\ClassError{ltnews}
   {No \protect\publicationissue~given}\@eha}
\newcommand{\issuename}{Issue}

\newcommand{\indicia}{\renewcommand{\@indicia}}
\newcommand{\@indicia}{%
   \LaTeXNews, and the \LaTeX{} software,
   are brought to you by the \LaTeX\ Project Team;
   Copyright \@year, all rights reserved.
}

\title{\LaTeXNews}

% The \maketitle for the LaTeX News.

\renewcommand{\maketitle}{%
   \twocolumn[{%
      \parbox[t][7\baselineskip]{\textwidth}{%
         \@titlefont\@title\\[\medskipamount]
         \normalfont\normalsize\issuename~\@issue,
         \@month~\@year~(\LaTeX\ release \publicationdate)%
      }%
   }]%
   \thispagestyle{titlepage}
}

\newcommand{\ps@titlepage}{%
   \renewcommand{\@oddhead}{\hfill}%
   \renewcommand{\@evenhead}{\hfill}%
   \renewcommand{\@oddfoot}{\@indiciafont\@indicia\hfill}%
   \renewcommand{\@evenfoot}{\@indiciafont\@indicia\hfill}%
}
%
% When PostScript fonts are use we want the first section heading
% to come out a little bit higher on the page.

\newcommand{\raisefirstsection}{%
  \ifx\TeX\pplTeX
    \vspace*{-30pt}           % typesetting with lw35fonts
    \setlength{\topskip}{18pt}
  \else
    \vspace*{-36pt}
  \fi
}
% Sectioning commands.

\renewcommand{\section}{%
   \@startsection
      {section}{1}{\z@}{-1.5ex \@plus -1ex \@minus -.2ex}%
      {1ex \@plus.2ex}{\@headingfont}%
}

\renewcommand{\subsection}{%
   \@startsection
      {subsection}{1}{\z@}{-1.5ex \@plus -1ex \@minus -.2ex}%
      {1sp}{\@subheadingfont}%
}

% maybe not the greatest design but normally we wouldn't have subsubsections
\renewcommand{\subsubsection}{%
   \@startsection
      {subsubsection}{2}{\leftmargini}{-1.5ex \@plus -1ex \@minus -.2ex}%
      {1sp}{\@subheadingfont}%
}


% suggestion by Karl Berry (not integrated (yet))

\newcommand{\ltnewssectformat}{%
  \@headingfont
  \frenchspacing
  \raggedright
  \hyphenpenalty=10000
  \exhyphenpenalty=10000
}

% No section numbers.

\setcounter{secnumdepth}{0}

% Set lists tighter, but brought in by 1em (otherwise the first line
% always looks very wide).  Should this be done with \rightskip?
% It actually does nothing since after this \rightskip is set to
% \@rightskip: I think \rightmargin was intended but should we change
% it now?
% FMi 1999/12/11: in fact it needs to go as it would affect the
% paragraph before the list making it flush right and indented while
% the rest of the document is set ragged.

\renewcommand{\@listI}{%
   \setlength{\leftmargin}{\leftmargini}%
   \setlength{\topsep}{\medskipamount}%
   \setlength{\itemsep}{0pt}%
   \setlength{\listparindent}{1em}%
%   \setlength{\rightskip}{1em}%
}
\let \@listi \@listI

% set defaults so that trivlist eg verbatim use tighter spacing
\@listi
\setlength\topsep{4pt plus 1pt minus 2pt}

% But have a list type with no indentation on either side:
%
\renewenvironment{description}
               {\list{}{\labelwidth\z@
                   \leftmargin \z@
                   \rightmargin \z@
                   \itemindent-\leftmargin
                   \let\makelabel\descriptionlabel}}
               {\endlist}

\newenvironment{citations}{%
   \list{}{%
      \renewcommand{\makelabel}[1]{\itshape{##1},}%
   }%
}{%
   \endlist
}

% Some logos:

\newcommand{\NFSS}{NFSS}
\newcommand{\LaTeXNews}{\LaTeX~News}
\newcommand{\AW}{Addison Wesley}
\newcommand{\SLiTeX}{\textsc{Sli}\TeX}
\newcommand{\AmS}{$${\protect\the\textfont2 A}\kern-.1667em\lower
         .5ex\hbox{\protect\the\textfont2 M}\kern
         -.125em{\protect\the\textfont2 S}}
\newcommand{\AmSLaTeX}{\mbox{\AmS-\LaTeX}}
\newcommand{\ctan}{\textsc{CTAN}}
\newcommand{\PSNFSS}{\textsc{PSNFSS}}
\newcommand{\babel}{\textsf{babel}}

% Abbreviations:

\newcommand{\ctanhttp}{http://mirror.ctan.org/}

% Needed for 09:

\newcommand\cs[1]{\texttt{\textbackslash#1}}

% Some logical markup:

\newcommand*\class[1]{\texttt{#1}}
\newcommand*\package[1]{\textsf{#1}}
\let \pkg \package  % backward compatibility
\newcommand*\file[1]{\texttt{#1}}


% Hacking to make <...> produce italics in verbatim.  NB: this can be
% done more cleanly using the verbatim package.  But the ltnews class
% has  to run on any LaTeX installation, even those without the
% verbatim package.

% Here we extend the font-setting command to include making <> active
% (ie adjusting the input encoding).
\renewcommand \verbatim@font {%
  \normalfont \ttfamily
  \catcode`\<=\active
  \catcode`\>=\active
}

% Make active <...> produce italics surrounded by angle brackets
% (used in verbatim and \verb);
% << produces a less-than, and >> produces a greater-than.

\begingroup
  \catcode`\<=\active
  \catcode`\>=\active
  \gdef<{\@ifnextchar<\@lt\@meta}
  \gdef>{\@ifnextchar>\@gt\@gtr@err}
  \gdef\@meta#1>{{\reset@font\normalsize\itshape#1\/}}
  \gdef\@lt<{\char`\<}
  \gdef\@gt>{\char`\>}
\endgroup
\def\@gtr@err{%
   \ClassError{ltxguide}{%
      Isolated \protect>%
   }{%
      In this document class, \protect<...\protect>
      is used to indicate a parameter.\MessageBreak
      I've just found a \protect> on its own.
      Perhaps you meant to type \protect>\protect>?
   }%
}
\def\verbatim@nolig@list{\do\`\do\,\do\'\do\-}

% That's it!

%FMi temp addition until etoolbox is updated
%\RequirePackage{etoolbox-ltx}
%\AddToHook{env/document/begin}{\RemoveFromHook{env/document/begin}[*]} % done in \document

\endinput

% CHANGELOG
%
% 20 May 1994, v0.01: Created file.
%
% 21 May 1994, v0.02: Made <...> produce italics inside verbatim.
%    Added the indicia, \publicationyear, \publicationmonth and
%    \publicationissue.  Added the citations environment.  Switched off
%    some of the article class options.
%
% 21 May 1994, v0.03: Fixed a bug with ragged right.  Fixed a bug
%    which was causing underfull hbox messages.
%
% 27 May 1994, v0.04: Added SliTeX logo, and proper AMS LaTeX logo.
%    Added angle brackets to <...>.
%
% 31 May 1994, v0.05: Added downloaded PS fonts options.  Removed
%    angle brackets from <...> since these were the last remaining
%    bitmaps!  Added variants of the LaTeX logo.  Added the ltnews.cfg
%    file.  Added the lw35fonts option.
%
% 27 Jul 1994, v0.06: Corrected a typo `\PassOptionToClass' should
%    have been `\PassOptionsToClass'.  Manas Mandal pointed that one
%    out.
%
% 29 Nov 1994, v0.07: Made <...> only active in verbatim.
%
% 09 Dec 1995, v0.08: Upper case for Project Team.
%
% 20 Dec 1995, v0.09: Tidied up the list stuff.
%
% 03 Jun 1996, v0.10: Changed fonts for lw35 option, for logical and
%    aesthetic reasons.
%
% 06 Jun 1996, v0.11: Corrected grammar in footer.
%
% 10 June 1996 v0.12: Add extra line in lw35fonts option,
%    so 04 and 05 do not run over the page.
%    Make font scaling messages go to log only.
%
% 22 Nov 1997, v0.13: Added new form of description.
%    Found all sorts of strange things involving \rightskip
%
% 23 Feb 1999, v0.14: Added  some logos etc.
%
% 02 Jul 1999, v0.15: Added some logical markup
%
% 03 Jul 1999, v0.16: Amended \pkg and added \email
%
% 21 Dec 1999, v0.17: Added PDF info, load package url.sty
%
% 23 Dec 1999, v0.18: Don't depend on url.sty being present
%
% 21 Jul 2000, v0.19: Extra short-cuts, added to doc re v0.17;
%    and more fonts
%
% 31 Aug 2000, v0.20: Fixed typo in URL (JLB)
%
% 06 Jun 2001, v0.21: Corrected undocumented stubs for html.sty
%
% 12 Jul 2001, v0.22: Added eTeX logo (from ltugboat.cls)
%
% 26 Feb 2004, v1.00: If pdf is being produced, use hyperref.
%    But move this after other packages are, possibly, loaded.
%
% 28 Feb 2004  v1.01 Heading font in lw35, size change.
%
% 21 Oct 2004  v1.02 Improve check for PDF generation (taken from ifpdf.sty)
%
% 01 May 2014  v1.03 hidelinks option for hyperref
%
% BUGS
%
% Switching between logos like this is a mess.
%
% The last column should be set flush bottom.
