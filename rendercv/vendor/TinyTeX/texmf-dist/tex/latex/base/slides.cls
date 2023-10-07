%%
%% This is file `slides.cls',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% slides.dtx  (with options: `class')
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
\NeedsTeXFormat{LaTeX2e}[1997/06/01]
\ProvidesClass{slides}
              [2022/05/18 v2.4b
               Standard LaTeX document class]
\input{slides.def}
\InputIfFileExists{sfonts.cfg}
           {\typeout{**************************************^^J%
                     *^^J%
                     * Local config file sfonts.cfg used^^J%
                     *^^J%
                     **************************************}}%
           {\input{sfonts.def}}
\DeclareOption{a4paper}
   {\setlength\paperheight {297mm}%
    \setlength\paperwidth  {210mm}}
\DeclareOption{a5paper}
   {\setlength\paperheight {210mm}%
    \setlength\paperwidth  {148mm}}
\DeclareOption{b5paper}
   {\setlength\paperheight {250mm}%
    \setlength\paperwidth  {176mm}}
\DeclareOption{letterpaper}
   {\setlength\paperheight {11in}%
    \setlength\paperwidth  {8.5in}}
\DeclareOption{legalpaper}
   {\setlength\paperheight {14in}%
    \setlength\paperwidth  {8.5in}}
\DeclareOption{executivepaper}
   {\setlength\paperheight {10.5in}%
    \setlength\paperwidth  {7.25in}}
\DeclareOption{landscape}
   {\setlength\@tempdima   {\paperheight}%
    \setlength\paperheight {\paperwidth}%
    \setlength\paperwidth  {\@tempdima}}

\newif\if@clock \@clockfalse
\DeclareOption{clock}{\@clocktrue
  \AtEndDocument{\typeout{\@arabic\c@minutes\space minutes}}
}%
\newcounter{minutes}%
\newcounter{seconds}%
\newcommand*{\settime}[1]{\setcounter{seconds}{0}\addtime{#1}}%
\newcommand*{\addtime}[1]{\addtocounter{seconds}{#1}%
  \setcounter{minutes}{\value{seconds}}%
  \global \divide \value{minutes} by 60\relax}

\@twosidefalse
\DeclareOption{draft}{\setlength\overfullrule{5pt}}
\DeclareOption{final}{\setlength\overfullrule{0pt}}
\newif\if@titlepage
\@titlepagetrue
\DeclareOption{titlepage}{\@titlepagetrue}
\DeclareOption{notitlepage}{\@titlepagefalse}
\DeclareOption{onecolumn}{}
\DeclareOption{twocolumn}{%
    \ClassWarning{slides}{No 'twocolumn' layout for slides}}
\DeclareOption{leqno}{\input{leqno.clo}}
\DeclareOption{fleqn}{\input{fleqn.clo}}
\ExecuteOptions{letterpaper,final}
\ProcessOptions
\def\rmdefault{lcmss}        % no roman
\def\sfdefault{lcmss}
\def\ttdefault{lcmtt}
\def\itdefault{sl}
\def\sldefault{sl}
\def\bfdefault{bx}
\def\updefault{n}
\def\ifourteenpt{13.82}
\def\iseventeenpt{16.59}
\def\itwentypt{19.907}
\def\itwentyfourpt{23.89}
\def\itwentyninept{28.66}
\def\ithirtyfourpt{34.4}
\def\ifortyonept{41.28}
\def\@setfontsize@parms#1#2#3#4#5#6#7#8{%
   \lineskip #1\relax%
   \parskip #2\relax
   \abovedisplayskip #3\relax
   \belowdisplayskip #4\relax
   \abovedisplayshortskip #5\relax
   \belowdisplayshortskip #6\relax
  \setbox\strutbox=\hbox{\vrule \@height#7\p@\@depth#8\p@\@width\z@}%
  \baselineskip\baselinestretch\baselineskip
  \normalbaselineskip\baselineskip}
\DeclareMathSizes{13.82}{13.82}{10}{7}
\DeclareMathSizes{16.59}{16.59}{12}{7}
\DeclareMathSizes{19.907}{19.907}{16.59}{13.82}
\DeclareMathSizes{23.89}{23.89}{19.907}{16.59}
\DeclareMathSizes{28.66}{28.66}{23.89}{19.907}
\DeclareMathSizes{34.4}{34.4}{28.66}{23.89}
\DeclareMathSizes{41.28}{41.28}{34.4}{28.66}
\def\normalsize{%
      \@setfontsize\normalsize\itwentypt{28\p@ plus3\p@ minus4\p@}%
      \@setfontsize@parms
            {2pt}%
            {30\p@ plus18\p@ minus9\p@}%
            {15\p@ plus3\p@ minus3\p@}%
            {10\p@ plus3\p@ minus3\p@}%
            {10\p@ plus3\p@}
            \abovedisplayshortskip
            {17}{7}}
\normalsize
\def\small{\@setfontsize\small\iseventeenpt{19\p@ plus3\p@ minus\p@}%
           \@setfontsize@parms
            {2\p@}%
            {15\p@ plus15\p@ minus7\p@}%
            {12\p@ plus3\p@ minus3\p@}%
            {9\p@ plus3\p@ minus3\p@}%
            {6\p@ plus3\p@}%
            \abovedisplayshortskip
            {13.5}{5.6}}
\let\footnotesize=\small
\let\scriptsize=\small
\def\tiny{\@setfontsize\tiny\ifourteenpt{16\p@ plus2\p@ minus\p@}%
          \@setfontsize@parms
            {2pt}%
            {14\p@ plus3\p@ minus10\p@}%
            {11\p@ plus3\p@ minus10\p@}%
            \abovedisplayskip
            {8\p@ plus3\p@ minus5\p@}%
            {\z@ plus3\p@}%
            {10}{4}}
\def\large{\@setfontsize\large\itwentyfourpt{42\p@ plus8\p@ minus5\p@}%
           \@setfontsize@parms
            {2\p@}%
            {40\p@ plus20\p@ minus4\p@}%
            {20\p@ plus8\p@ minus3\p@}%
            \abovedisplayskip
            {10\p@ plus5\p@}%
            \abovedisplayshortskip
            {20}{8.5}}

\def\Large{\@setfontsize\Large\itwentyninept{48\p@ plus10\p@ minus6\p@}%
           \@setfontsize@parms
            {2\p@}%
            {48\p@ plus30\p@ minus6\p@}%
            {24\p@ plus10\p@ minus6\p@}%
            \abovedisplayskip
            {12\p@ plus8\p@}%
            \abovedisplayshortskip
            {27}{11}}

\def\LARGE{\@setfontsize\LARGE\ithirtyfourpt{52\p@ plus10\p@ minus6\p@}%
           \@setfontsize@parms
            {2\p@}%
            {52\p@ plus30\p@ minus6\p@}%
            {24\p@ plus10\p@ minus6\p@}%
            \abovedisplayskip
            {12\p@ plus8\p@}%
            \abovedisplayshortskip
            {27}{11}}

\def\huge{\@setfontsize\huge\ifortyonept{60\p@ plus10\p@ minus6\p@}%
           \@setfontsize@parms
            {2\p@}%
            {60\p@ plus30\p@ minus6\p@}%
            {24\p@ plus10\p@ minus6\p@}%
            \abovedisplayskip
            {12\p@ plus8\p@}%
            \abovedisplayshortskip
            {27}{11}}

\let\Huge\huge
\renewcommand\baselinestretch{}
\setlength\parindent{\z@}
\@lowpenalty   51
\@medpenalty  151
\@highpenalty 301
\setlength\headheight{14\p@}
\setlength\headsep   {15\p@}
\setlength\topskip   {30\p@}
\setlength\footskip{25\p@}   %
\if@compatibility
  \setlength\maxdepth{4\p@}
\else
  \setlength\maxdepth{.5\topskip}
\fi
\setlength\@maxdepth\maxdepth
\if@compatibility
  \setlength\textwidth{460\p@}
\else
  \setlength\@tempdima{\paperwidth}
  \addtolength\@tempdima{-2in}
  \setbox\@tempboxa\hbox{\rmfamily im}
  \setlength\@tempdimb{.5\wd\@tempboxa}
  \setlength\@tempdimb{65\@tempdimb}
  \ifdim\@tempdima>\@tempdimb\relax
    \setlength\textwidth{\@tempdimb}
  \else
    \setlength\textwidth{\@tempdima}
  \fi
\fi
\@settopoint\textwidth
\columnwidth \textwidth
\columnsep 10pt
\columnseprule \z@
\if@compatibility
  \setlength\textheight{600\p@}
\else
  \setlength\@tempdima{\paperheight}
  \addtolength\@tempdima{-2in}
  \addtolength\@tempdima{-1in}
  \divide\@tempdima\baselineskip
  \@tempcnta=\@tempdima
  \setlength\textheight{\@tempcnta\baselineskip}
\fi
\advance\textheight by \topskip
\if@compatibility
   \setlength\oddsidemargin  {17\p@}
   \setlength\evensidemargin {17\p@}
   \setlength\marginparwidth {20\p@}
\else
  \setlength\@tempdima        {\paperwidth}
  \addtolength\@tempdima      {-2in}
  \addtolength\@tempdima      {-\textwidth}
  \setlength\oddsidemargin    {.5\@tempdima}
  \setlength\marginparwidth   {.8in}
  \addtolength\marginparwidth {.5\@tempdima}
\setlength\evensidemargin  {\paperwidth}
\addtolength\evensidemargin{-2in}
\addtolength\evensidemargin{-\textwidth}
\addtolength\evensidemargin{-\oddsidemargin}
\fi
\setlength\marginparsep {5\p@}
\setlength\marginparpush{5\p@}
\if@compatibility
  \setlength\topmargin{-10pt}
\else
  \setlength\topmargin{\paperheight}
  \addtolength\topmargin{-2in}
  \addtolength\topmargin{-\headheight}
  \addtolength\topmargin{-\headsep}
  \addtolength\topmargin{-\textheight}
  \addtolength\topmargin{-\footskip}     % this might be wrong!
  \addtolength\topmargin{-.5\topmargin}
\fi
\@settopoint\topmargin
\setlength\footnotesep{20\p@}
\setlength{\skip\footins}{10\p@ \@plus 2\p@ \@minus 4\p@}
\if@compatibility
\def\ps@headings{%
\def\ps@slide{\def\@oddfoot{\@mainsize +\hfil\hb@xt@3em{\theslide
                                                          \hss}}%
 \def\@oddhead{\@mainsize +\hfil +}%
 \def\@evenfoot{\@mainsize +\hfil\hb@xt@3em{\theslide\hss}}%
 \def\@evenhead{\@mainsize +\hfil +}}

\def\ps@overlay{\def\@oddfoot{\@mainsize +\hfil\hb@xt@3em{\theoverlay
                                                           \hss}}%
 \def\@oddhead{\@mainsize +\hfil +}%
 \def\@evenfoot{\@mainsize +\hfil\hb@xt@3em{\theoverlay\hss}}%
 \def\@evenhead{\@mainsize +\hfil +}}
\def\ps@note{\def\@oddfoot{\@mainsize \hbox{}\hfil\thenote}%
 \def\@oddhead{}%
 \def\@evenfoot{\@mainsize \hbox{}\hfil\thenote}%
 \def\@evenhead{}}}
\else %%if@compatibility
\def\ps@headings{%
  \def\ps@slide{%
    \def\@oddfoot{\@mainsize \mbox{}\hfil\hb@xt@3em{\theslide\hss}}%
    \def\@oddhead{}%
    \def\@evenfoot{\@mainsize \mbox{}\hfil\hb@xt@3em{\theslide\hss}}%
    \def\@evenhead{}}

  \def\ps@overlay{%
    \def\@oddfoot{\@mainsize \mbox{}\hfil\hb@xt@3em{\theoverlay\hss}}%
    \def\@oddhead{}%
    \def\@evenfoot{\@mainsize \mbox{}\hfil\hb@xt@3em{\theoverlay\hss}}%
    \def\@evenhead{}}

  \def\ps@note{%
    \def\@oddfoot{%
      \@mainsize
      \if@clock
        \fbox{\large \@arabic\c@minutes\space min}%
      \else
        \null
      \fi
      \hfil\thenote}%
    \def\@oddhead{}%
    \def\@evenfoot{%
      \@mainsize
      \if@clock
        \fbox{\large \@arabic\c@minutes\space min}%
      \else
        \null
      \fi
      \hfil\thenote}%
    \def\@evenhead{}}}
\fi  %% if@compatibility
\def\ps@plain{\def\ps@slide{%
 \def\@oddfoot{\@mainsize \mbox{}\hfil\hb@xt@3em{\theslide\hss}}%
 \def\@oddhead{}%
 \def\@evenfoot{\@mainsize \mbox{}\hfil\hb@xt@3em{\theslide\hss}}%
 \def\@evenhead{}}
\def\ps@overlay{\def\@oddfoot{\@mainsize
   \mbox{}\hfil\hb@xt@3em{\theoverlay\hss}}%
 \def\@oddhead{}%
 \def\@evenfoot{\@mainsize \mbox{}\hfil\hb@xt@3em{\theoverlay\hss}}%
 \def\@evenhead{}}
\def\ps@note{\def\@oddfoot{\@mainsize \hbox{}\hfil\thenote}%
 \def\@oddhead{}%
 \def\@evenfoot{\@mainsize \hbox{}\hfil\thenote}%
 \def\@evenhead{}}}
\def\ps@empty{%
\def\ps@slide{\def\@oddhead{}\def\@oddfoot{}%
\def\@evenhead{}\def\@evenfoot{}}%
\def\ps@overlay{\def\@oddhead{}\def\@oddfoot{}%
\def\@evenhead{}\def\@evenfoot{}}%
\def\ps@note{\def\@oddhead{}\def\@oddfoot{}%
\def\@evenhead{}\def\@evenfoot{}}}
\ps@headings
\let\@oddhead\@empty\let\@oddfoot\@empty
\let\@evenhead\@empty\let\@evenfoot\@empty
\DeclareMathVersion{invisible}
\SetSymbolFont{operators}{normal}
                 {OT1}{lcmss}{m}{n}

\SetSymbolFont{letters}{normal}
                 {OML}{lcmm}{m}{it}
\SetSymbolFont{symbols}{normal}
                 {OMS}{lcmsy}{m}{n}
\SetSymbolFont{largesymbols}{normal}
                 {OMX}{lcmex}{m}{n}

\SetSymbolFont{operators}{invisible}
                 {OT1}{lcmss}{m}{In}
\SetSymbolFont{letters}{invisible}
                 {OML}{lcmm}{m}{Iit}
\SetSymbolFont{symbols}{invisible}
                 {OMS}{lcmsy}{m}{In}
\SetSymbolFont{largesymbols}{invisible}
                  {OMX}{lcmex}{m}{In}

\def\@mainsize{\visible\tiny}
\newenvironment{titlepage}
     {\newpage
      \thispagestyle{empty}%
      \setcounter{page}{\z@}}
     {\newpage}
\setlength\leftmargini   {38\p@}
\setlength\leftmarginii  {30\p@}
\setlength\leftmarginiii {20\p@}
\setlength\leftmarginiv  {15\p@}
\setlength\leftmarginv   {15\p@}
\setlength\leftmarginvi  {10\p@}
\def\@listi{\leftmargin\leftmargini
            \parsep .5\parskip
            \topsep \parsep
            \itemsep\parskip
            \partopsep \z@}

\def\@listii{\leftmargin\leftmarginii
             \labelwidth\leftmarginii
             \advance\labelwidth-\labelsep
             \parsep .5\parskip
             \topsep \parsep
             \itemsep\parskip}
\def\@listiii{\leftmargin\leftmarginiii
              \labelwidth\leftmarginiii
              \advance\labelwidth-\labelsep}
\def\@listiv{\leftmargin\leftmarginiv
             \labelwidth\leftmarginiv
             \advance\labelwidth-\labelsep}
\def\@listv{\leftmargin\leftmarginv
            \labelwidth\leftmarginv
            \advance\labelwidth-\labelsep}
\def\@listvi{\leftmargin\leftmarginvi
             \labelwidth\leftmarginvi
             \advance\labelwidth-\labelsep}
\leftmargin\leftmargini
\labelwidth\leftmargini\advance\labelwidth-\labelsep
\newenvironment{verse}{\let\\=\@centercr
                       \list{}{\itemsep       \z@
                               \itemindent    -15\p@
                               \listparindent \itemindent
                               \rightmargin   \leftmargin
                               \advance\leftmargin 15\p@}%
                       \item[]}
                      {\endlist}
\newenvironment{quotation}{\list{}{\listparindent 20\p@
                                   \itemindent\listparindent
                                   \rightmargin\leftmargin}%
                           \item[]}
                          {\endlist}
\newenvironment{quote}{\list{}{\rightmargin\leftmargin}\item[]}
                      {\endlist}
\newenvironment{description}{\list{}{\labelwidth\z@
                                     \itemindent-\leftmargin
                                     \let\makelabel\descriptionlabel}}
                            {\endlist}
\newcommand*{\descriptionlabel}[1]{\hspace\labelsep
                                \normalfont\bfseries #1}

\renewcommand\theenumi{\@arabic\c@enumi}
\renewcommand\theenumii{\@alph\c@enumii}
\renewcommand\theenumiii{\@roman\c@enumiii}
\renewcommand\theenumiv{\@Alph\c@enumiv}
\newcommand\labelenumi{\theenumi.}
\newcommand\labelenumii{(\theenumii)}
\newcommand\labelenumiii{\theenumiii.}
\newcommand\labelenumiv{\theenumiv.}
\renewcommand\p@enumii{\theenumi}
\renewcommand\p@enumiii{\theenumi(\theenumii)}
\renewcommand\p@enumiv{\p@enumiii\theenumiii}
\newcommand\labelitemi{$\m@th\bullet$}
\newcommand\labelitemii{\normalfont\bfseries \textendash}
\newcommand\labelitemiii{$\m@th\ast$}
\newcommand\labelitemiv{$\m@th\cdot$}
\setlength\arraycolsep{8\p@}
\setlength\tabcolsep{10\p@}
\setlength\arrayrulewidth{.6\p@}
\setlength\doublerulesep{3\p@}
\labelsep 10pt
\setlength\tabbingsep{\labelsep}
\skip\@mpfootins = \skip\footins
\setlength\fboxsep{5\p@}
\setlength\fboxrule{.6\p@}
\def\theequation{\@arabic\c@equation}
\DeclareOldFontCommand{\rm}{\normalfont\rmfamily}{\mathrm}
\DeclareOldFontCommand{\sf}{\normalfont\sffamily}{\mathsf}
\DeclareOldFontCommand{\tt}{\normalfont\ttfamily}{\mathtt}
\DeclareOldFontCommand{\bf}{\normalfont\bfseries}{\mathbf}
\DeclareOldFontCommand{\it}{\normalfont\itshape}{\mathit}
\DeclareOldFontCommand{\sl}{\normalfont\slshape}{\relax}
\DeclareOldFontCommand{\sc}{\normalfont\scshape}{\relax}
\DeclareRobustCommand*{\cal}{\@fontswitch{\relax}{\mathcal}}
\DeclareRobustCommand*{\mit}{\@fontswitch{\relax}{\mathnormal}}
\renewcommand\footnoterule{}
\def\thefootnote{\fnsymbol{footnote}}
\@addtoreset{footnote}{slide}
\@addtoreset{footnote}{overlay}
\@addtoreset{footnote}{note}
\long\def\@makefntext#1{
    \noindent
    \hangindent 10\p@
    \hb@xt@10\p@{\hss\@makefnmark}#1}
\newcommand\maketitle{{\centering {\Large \@title \par}%
     \@author \par \@date\par}%
     \if@titlepage \break \fi}

\newcommand\today{\ifcase\month\or
  January\or February\or March\or April\or May\or June\or
  July\or August\or September\or October\or November\or December\fi
  \space\number\day, \number\year}
\pagenumbering{arabic}
\onecolumn
\endinput
%%
%% End of file `slides.cls'.
