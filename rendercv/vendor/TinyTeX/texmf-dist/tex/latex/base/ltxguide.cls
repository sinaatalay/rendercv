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
% Filename: ltxguide.cls
% Author: Alan Jeffrey
% Version: 0.14 1999/03/06

% This is the document class for the LaTeX guides `LaTeX2e for authors'
% and `LaTeX2e for class and package writers'.  The changes log is at
% the end of the file.

% Copyright 1994-1999 Alan Jeffrey and the LaTeX Project.

% This is a LaTeX2e document class.

\NeedsTeXFormat{LaTeX2e}[1994/12/01]
\ProvidesClass{ltxguide}[2001/05/28 Standard LaTeX class]

% Input any local configuration file.

\InputIfFileExists{ltxguide.cfg}
  {\typeout         {**********************************************^^J%
                     * Local configuration file ltxguide.cfg used *^^J%
                     **********************************************}}
  {\ClassInfo{ltxguide}{Local configuration file not found}}

% All options are passed to the article class.

\DeclareOption*{\PassOptionsToClass{\CurrentOption}{article}}
\ProcessOptions
\LoadClass{article}

% No paragraph indentation, space between paragraphs.

\setlength{\parindent}{0pt}
\setlength{\parskip}{\medskipamount}

% The names of some documents:

\newcommand{\clsguide}{\LaTeXe{} for Class and Package Writers}
\newcommand{\usrguide}{\LaTeXe{} for Authors}
\newcommand{\fntguide}{\LaTeXe{} Font Selection}
\newcommand{\cfgguide}{Configuration options for \LaTeXe}
\newcommand{\cyrguide}{Cyrillic languages support in \LaTeX}
\newcommand{\modguide}{Modifying \LaTeX}
\newcommand{\sourcecode}{\LaTeX: the program}
\newcommand{\LaTeXbook}{\LaTeX: A Document Preparation System}
\newcommand{\LaTeXcomp}{The \LaTeX{} Companion}
\newcommand\LaTeXGcomp{The \LaTeX{} Graphics Companion}
\newcommand\LaTeXWcomp{The \LaTeX{} Web Companion}

\newcommand{\babel}{\textsf{babel}}
\newcommand{\ctan}{\textsc{ctan}}

\newcommand{\eg}{e.g.,~}
\newcommand{\ie}{i.e.,~}

% The SliTeX logo:

\newcommand{\SLiTeX}{\textsc{Sli}\TeX}

% A declaration of a command, in a box, set out into the margin.
%
% Unfortunately, there is a bug with this command, which allows page
% breaks to happen after a \begin{decl}[DATE]: it is a bug with TeX that
% makes it very difficult to get page-breaks correct near marginals,
% especially at the end of a paragraph.

\newenvironment{decl}[1][]%
    {\par\small\addvspace{4.5ex plus 1ex}%
     \vskip -\parskip
     \ifx\relax#1\relax
        \def\@decl@date{}%
     \else
        \def\@decl@date{\NEWfeature{#1}}%
     \fi
     \noindent\hspace{-\leftmargini}%
     \begin{tabular}{|l|}\hline\ignorespaces}%
    {\\\hline\end{tabular}\nobreak\@decl@date\par\nobreak
     \vspace{2.3ex}\vskip -\parskip}

% Run the toc tighter:

\def\@starttoc#1{\begingroup
  \makeatletter
  \parskip\z@\@plus\p@\relax         % <----
  \@input{\jobname.#1}\if@filesw
  \expandafter\newwrite\csname tf@#1\endcsname
             \immediate\openout
                 \csname tf@#1\endcsname \jobname.#1\relax
  \fi \global\@nobreakfalse \endgroup}

% Some hacks with verbatim... NB: this would be better done with the
% verbatim package, but this document has to run on any LaTeX
% installation.

\let\o@verbatim\verbatim
\def\verbatim{%
  \ifhmode\unskip\par\fi
% \nopagebreak              % Overridden by list penalty
  \ifx\@currsize\normalsize
     \small
  \fi
  \o@verbatim
}

% Here we extend the font-setting command to include making <> active
% (ie adjusting the input encoding).
\renewcommand \verbatim@font {%
  \normalfont \ttfamily
  \catcode`\<=\active
  \catcode`\>=\active
}

% Make |...| a synonym for \verb|...|.
\RequirePackage{shortvrb}
\MakeShortVerb{\|}


% Make active <...> produce italics surrounded by angle brackets
% (used in verbatim and \verb).
% << produces a less-than, and >> produces a greater-than.

\begingroup
  \catcode`\<=\active
  \catcode`\>=\active
  \gdef<{\@ifnextchar<\@lt\@meta}
  \gdef>{\@ifnextchar>\@gt\@gtr@err}
  \gdef\@meta#1>{\m{#1}}
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

% Various forms of argument:

\newcommand{\m}[1]{\mbox{$\langle$\it #1\/$\rangle$}}
\renewcommand{\arg}[1]{{\tt\string{}\m{#1}{\tt\string}}}
\newcommand{\oarg}[1]{{\tt[}\m{#1}{\tt]}}

% Logos.

\newcommand{\NFSS}{\textsf{NFSS}}

\newcommand{\AmS}{$${\protect\the\textfont2 A}\kern-.1667em\lower
         .5ex\hbox{\protect\the\textfont2 M}\kern
         -.125em{\protect\the\textfont2 S}}

\newcommand{\AmSLaTeX}{\mbox{\AmS-\LaTeX}}

% Table of contents is two deep.

\setcounter{tocdepth}{2}

% Allow more flexibility about bad paragraphs.

\tolerance500

% Marginal notes for new features and description:
% Changed to command and hacked by Chris to get better positioning and
% a better chance of printing:
\newcommand{\NEWfeature}[1]{%
   \hskip 1sp \marginpar{\small\sffamily\raggedright
     New feature\\#1}}
\newcommand{\NEWdescription}[1]{%
   \hskip 1sp \marginpar{\small\sffamily\raggedright
     New description\\#1}}

\newcommand{\URL}[1]{\texttt{#1}}

% That's it!

\endinput

% CHANGELOG
%
% 24 May 1994, ASAJ: Turned the collection of macros used by
%       usrguide and clsguide into a class.
%
% 27 May 1994, ASAJ: Added the SliTeX logo.
%
% 28 May 1994, ASAJ: Made << and >> produce < and > inside verbatim.
%    Added ltxguide.cfg.
%
% 29 May 1994, ASAJ: Added italic correction to <...>.
%    Added \sourcecode.
%
% 1 Jun 1994, ASAJ: Made toc run tighter, corrected bug with verbatim.
%
% 28 Jun 1994, CAR: Restricted active <> to verb(atim).
%    Removed ineffective \nopagebreak
%
% 23 Sep 1994, ASAJ: Replaced \PassOptionsToPackage{article} with
%    \PassOptionsToClass{article}.
%
% 30 Oct 1994, ASAJ: Added environments NEWfeature and NEWdescription.
%
% 20 Nov 1994, CAR: Changed NEWfeature and NEWdescription to improve
%    alignment: pagebreaking still not working.
%
% 14 Dec 1994, DPC: Add \par to verbatim redefinition.
%      Reported by Ulrik Vieth.
% 24 July 1995, CAR: Changed cfg messages.
%
% 21 Sept 1995, \RequirePackage{shortvrb} for latex/1875
%
% 22 Nov  1995, CAR: Corrected cfg loading.
%
% 28 Nov  1995, CAR: Added \cfgguide and \modguide.
%
% 29 Nov  1995, DPC: Make \small in verbatim conditional on \normalsize.
%
% 28 Feb  1999, CAR: Added some shorthand commands.
%
% 06 Mar  1999, RmS: Added \URL.
%
% 28 May  2001, CAR: Added some more shorthand commands (for books).
