%%
%% This is file `amsdtx.cls',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% amsdtx.dtx  (with options: `amsdtx')
%% This is a generated file.
%% 
%% Copyright 1996, 1999, 2004, 2009 American Mathematical Society.
%% 
%% American Mathematical Society
%% Technical Support
%% Publications Technical Group
%% 201 Charles Street
%% Providence, RI 02904
%% USA
%% tel: (401) 455-4080
%%      (800) 321-4267 (USA and Canada only)
%% fax: (401) 331-3842
%% email: tech-support@ams.org
%% 
%% This work may be distributed and/or modified under the
%% conditions of the LaTeX Project Public License, either version 1.3c
%% of this license or (at your option) any later version.
%% The latest version of this license is in
%%   http://www.latex-project.org/lppl.txt
%% and version 1.3c or later is part of all distributions of LaTeX
%% version 2005/12/01 or later.
%% 
%% This work has the LPPL maintenance status `maintained'.
%% 
%% The Current Maintainer of this work is the American Mathematical
%% Society.
%% 
%% ========================================================================
%% 
\NeedsTeXFormat{LaTeX2e}% LaTeX 2.09 can't be used (nor non-LaTeX)
[1995/06/01]% LaTeX date must be June 1995 or later
\ProvidesClass{amsdtx}[2009/08/19 v2.07]
\DeclareOption*{\PassOptionsToClass{\CurrentOption}{book}}
\ProcessOptions
\LoadClass{book}
\IfFileExists{url.sty}{%
    \RequirePackage{url}\relax
    \@gobble
}{%
    \@firstofone
}
{
    \DeclareRobustCommand{\url}[1]{%
        \def\@tempa{#1}%
        \texttt{\urlsetup $\expandafter\strip@prefix\meaning\@tempa$}%
    }%
    \def\urlsetup{%
        \check@mathfonts \textfont\@ne\the\font \textfont\z@\the\font
        \urlfix +\urlfix\=\urlfix\:\urlfix\-\urlfix\.\urlfix\,\urlfix\;%
        \urlbreak\&\urlbreak\/\urlbreak\?%
    }%
    \def\urlbreak#1{%
        \mathcode`#1="8000
        \begingroup \lccode`\~=`#1 \lowercase{\endgroup \edef~}%
        {\mathchar\number`#1\penalty\hyphenpenalty}%
    }%
    \def\urlfix#1{%
        \mathcode`#1=`#1\relax
    }%
}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\providecommand{\qq}[1]{\textquotedblleft#1\/\textquotedblright}
\providecommand{\mdash}{\textemdash\penalty\exhyphenpenalty}
\providecommand{\ndash}{\textendash\penalty\exhyphenpenalty}
\let\@xp\expandafter
\newcommand*{\autoindex}[1]{%
    \index{#1\ifcodeline@index\encapchar usage\fi}%
}
\newcommand{\ntt}{\normalfont\ttfamily}
\newcommand*{\indexcs}[1]{%
    \@xp\@xp\@xp\@indexcs\@xp\@nobslash\string#1\@nil
}
\def\@indexcs#1\@nil{%
    \autoindex{#1\actualchar
        \string\verb\quotechar*\verbatimchar
            \@xp\@bothoftwo\string\ #1\@empty
        \verbatimchar
    }%
}
\def\@bothoftwo#1#2{#1#2}
\def\category@index#1#2{%
    {\ntt#2}%
    \@category@index{#1}{#2}%
}
\def\@category@index#1#2{%
    \autoindex{%
        #2\actualchar\string\texttt{#2}%
        \ifx\@nil#1\@nil\else\space#1\fi
    }%
}
\chardef\bslchar=`\\ % p. 424, TeXbook
\newcommand{\addbslash}{\expandafter\@addbslash\string}
\def\@addbslash#1{\bslchar\@nobslash#1}
\newcommand{\nobslash}{\expandafter\@nobslash\string}
\def\@nobslash#1{\ifnum`#1=\bslchar\else#1\fi}
\def\@boxorbreak{%
    \leavevmode
    \ifmmode\hbox\else\ifdim\lastskip=\z@\penalty9999 \fi\fi
}
\DeclareRobustCommand{\cs}[1]{%
    \@boxorbreak{%
        \ntt
        \addbslash#1\@empty
        \@xp\@xp\@xp\@indexcs\@xp\@nobslash\string#1\@nil
    }%
}
\let\cn\cs
\DeclareTextSymbol{\lbracechar}{OT1}{123}
\DeclareTextSymbolDefault{\lbracechar}{OT1}
\DeclareTextSymbol{\rbracechar}{OT1}{125}
\DeclareTextSymbolDefault{\rbracechar}{OT1}

\providecommand{\embrace}[1]{%
  \begingroup \ntt\lbracechar#1\rbracechar\endgroup}
\providecommand{\cnbreak}{\penalty999\hskip0pt\relax}
\providecommand{\cnm}[2]{\cn{#1}\cnbreak\embrace{#2}}
\providecommand{\cnmm}[3]{\cn{#1}\cnbreak\embrace{#2}\cnbreak\embrace{#3}}
\providecommand{\cnom}[1]{\cn{#1}\cnbreak\ommitude}
\providecommand{\ommitude}[2][]{{\ntt[#1]}\cnbreak\embrace{#2}}
\providecommand{\cnmsm}[4]{%
  \cn{#1}\cnbreak\embrace{#2}\cnbreak *\embrace{#4}}
\DeclareRobustCommand{\cls}{\category@index{class}}
\DeclareRobustCommand{\pkg}{\category@index{package}}
\DeclareRobustCommand{\opt}{\category@index{option}}
\DeclareRobustCommand{\env}[1]{{\ntt#1}\SpecialEnvIndex{#1}}
\DeclareRobustCommand{\fn}{\category@index{}}
\DeclareRobustCommand{\bst}{\category@index{\string\BibTeX{} style}}
\DeclareRobustCommand{\cnt}{\category@index{counter}}
\DeclareRobustCommand{\fnt}{\category@index{font}}
\def\allowtthyphens{\begingroup
  \fontencoding{OT1}\fontfamily{cmtt}%
  \expandafter\let\csname OT1+cmtt\endcsname\relax
  \try@load@fontshape
  \endgroup
  \expandafter\let\csname OT1+cmtt\endcsname\@empty
}
\hfuzz2pc
\vbadness9999 \hbadness5000
\def\AmS{{\protect\usefont{OMS}{cmsy}{m}{n}%
  A\kern-.1667em\lower.5ex\hbox{M}\kern-.125emS}}
\def\latex/{{\protect\LaTeX}}
\def\amslatex/{{\protect\AmS-\protect\LaTeX}}
\def\tex/{{\protect\TeX}}
\def\amstex/{{\protect\AmS-\protect\TeX}}
\def\bibtex/{{Bib\protect\TeX}}
\def\makeindx/{MakeIndex}
\def\xypic/{XY\mbox{-}pic}
\newcommand{\Textures}{\textit{Textures}}
\def\<#1>{\textit{$\langle$#1\/$\rangle$}}
\def\@listi{%
  \leftmargin\leftmargini
  \topsep 3\p@ \@plus2\p@ \@minus\p@
  \parsep \p@ \@plus\p@ \itemsep\parsep
}
\let\@listI\@listi
\@listi
\def\@listii{%
  \leftmargin\leftmarginii
  \labelwidth\leftmarginii \advance\labelwidth-\labelsep
  \topsep\p@\@plus\p@ \@minus\p@
  \parsep\z@skip \itemsep\z@skip
}
\def\@listiii{%
  \leftmargin\leftmarginiii
  \labelwidth\leftmarginiii \advance\labelwidth-\labelsep
  \topsep\z@skip \parsep\z@skip \itemsep\z@skip
}
\newenvironment{histnote}{%
  \trivlist\item[\hspace{\labelsep}\bfseries Historical Note:]%
}{%
  \endtrivlist
}
\def\@starttoc#1{\begingroup
  \let\autoindex\@gobble
  \makeatletter
  \@input{\jobname.#1}\if@filesw
  \expandafter\newwrite\csname tf@#1\endcsname
             \immediate\openout
                 \csname tf@#1\endcsname \jobname.#1\relax
  \fi \global\@nobreakfalse \endgroup}
\newcommand*{\secref}[1]{\S\ref{#1}}
\newcommand{\qc}[1]{}% check for prior definition
\edef\qc#1{\noexpand\protect\expandafter\noexpand\csname qc \endcsname
  \noexpand\protect#1}
\@namedef{qc }#1#2{\begingroup\ntt
  \ifx\ #2\char`\ \else\escapechar\m@ne\string#2\fi\endgroup}
\DeclareRobustCommand{\qcat}{\qc\@}%
\DeclareRobustCommand{\qcamp}{\qc\&}%
\DeclareRobustCommand{\qcbang}{\qc\!}%
\DeclareRobustCommand{\arg}[1]{{\ntt\##1}}
\def\ncn#1{{\let\index\@gobble\cn{#1}}}

\DeclareRobustCommand{\cnbang}{%
  \ncn{\!}\index{"!@{\ntt\bslchar\qcbang}}}
\DeclareRobustCommand{\cnat}{%
  \ncn{\!}\index{"@@{\ntt\bslchar\qcat}}}
\def\5{\penalty500 }
\newcommand{\errexa}{\par\noindent\textit{Example}:\ }
\newcommand{\errexpl}{\par\noindent\textit{Explanation}:\ }
\renewcommand\chapter{\par \@afterindentfalse
                    \secdef\@chapter\@schapter}
\def\@chapter[#1]#2{\ifnum \c@secnumdepth >\m@ne
                       \if@mainmatter
                         \refstepcounter{chapter}%
                         \typeout{\@chapapp\space\thechapter.}%
                         \addcontentsline{toc}{chapter}%
                                   {\protect\numberline{\thechapter}#1}%
                       \else
                         \addcontentsline{toc}{chapter}{#1}\fi
                    \else
                      \addcontentsline{toc}{chapter}{#1}
                    \fi
                    \chaptermark{#1}%
                    \addtocontents{lof}{\protect\addvspace{10\p@}}%
                    \addtocontents{lot}{\protect\addvspace{10\p@}}%
                    \if@twocolumn
                      \@topnewpage[\@makechapterhead{#2}]%
                    \else
                      \@makechapterhead{#2}%
                      \@afterheading
                    \fi}
\def\@makechapterhead#1{%
  \vspace{1.5\baselineskip}%
  {\parindent \z@ \raggedright \reset@font
    \ifnum \c@secnumdepth >\m@ne
      \large\bfseries \@chapapp\space\thechapter
      \par\nobreak
      \vskip.5\baselineskip\relax
    \fi
    #1\par\nobreak
    \vskip\baselineskip
  }}
\def\@schapter#1{\if@twocolumn
                   \@topnewpage[\@makeschapterhead{#1}]%
                 \else
                   \@makeschapterhead{#1}%
                   \@afterheading
                 \fi}
\def\@makeschapterhead#1{%
  \vspace*{1.5\baselineskip}%
  {\parindent \z@ \raggedright
    \reset@font
    \large \bfseries  #1\par\nobreak
    \vskip\baselineskip
  }}
\def\@removefromreset#1#2{\let\@tempb\@elt
   \expandafter\let\expandafter\@tempa\csname c@#1\endcsname
   \def\@elt##1{\expandafter\ifx\csname c@##1\endcsname\@tempa\else
         \noexpand\@elt{##1}\fi}%
   \expandafter\edef\csname cl@#2\endcsname{\csname cl@#2\endcsname}%
   \let\@elt\@tempb}
\@removefromreset{footnote}{chapter}
\def\ps@headings{%
  \let\@oddfoot\@empty\let\@evenfoot\@empty
  \def\@evenhead{\thepage\hfil{\footnotesize\leftmark{}{}}}%
  \def\@oddhead{{\footnotesize\rightmark{}{}}\hfil\thepage}%
  \let\@mkboth\markboth
  \def\chaptermark##1{%
    \markboth {\uppercase{\ifnum \c@secnumdepth >\m@ne
      \if@mainmatter
        \@chapapp\ \thechapter. \ \fi
      \fi
        ##1}}{}}%
  \def\sectionmark##1{%
    \markright {\uppercase{\ifnum \c@secnumdepth >\z@
        \thesection. \ \fi
        ##1}}}}
\renewcommand\maketitle{\par
  \begingroup
    \renewcommand\thefootnote{\fnsymbol{footnote}}%
    \def\@makefnmark{\hbox to\z@{$\m@th^{\@thefnmark}$\hss}}%
    \long\def\@makefntext##1{\parindent 1em\noindent
            \hbox to1.8em{\hss$\m@th^{\@thefnmark}$}##1}%
    \if@twocolumn
      \ifnum \col@number=\@ne
        \@maketitle
      \else
        \twocolumn[\@maketitle]%
      \fi
    \else
      \newpage
      \global\@topnum\z@   % Prevents figures from going at top of page.
      \@maketitle
    \fi
    \thispagestyle{plain}\@thanks
  \endgroup
  \setcounter{footnote}{0}%
  \let\thanks\relax
  \let\maketitle\relax\let\@maketitle\relax
  \gdef\@thanks{}\gdef\@author{}\gdef\@title{}}
\def\@maketitle{%
  \newpage
  \null
  \vskip 2em%
  \begin{center}%
    {\LARGE \@title \par}%
    \vskip 1.5em%
    {\large
      \lineskip .5em%
      \begin{tabular}[t]{c}%
        \@author
      \end{tabular}\par}%
    \vskip 1em%
    {\large \@date}%
  \end{center}%
  \par
  \uppercase\expandafter{\expandafter\toks@\expandafter{\@title}}%
  \edef\@tempa{\noexpand\markboth{\the\toks@}{\the\toks@}}%
  \@tempa
  \vskip 1.5em}
\renewcommand\tableofcontents{%
    \if@twocolumn
      \@restonecoltrue\onecolumn
    \else
      \@restonecolfalse
    \fi
    \subsection*{\contentsname}%
    \@starttoc{toc}%
    \if@restonecol\twocolumn\fi
    }
\renewcommand\section{\@startsection {section}{1}{\z@}%
                                   {-.6\baselineskip \@plus -3\p@}%
                                   {.4\baselineskip}
                          {\reset@font\Large\bfseries}}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
                                     {-.3\baselineskip\@plus -2\p@}%
                                     {.2\baselineskip}%
                          {\reset@font\large\bfseries}}
\renewcommand\subsubsection{\@startsection{subsubsection}{3}{\z@}%
                                     {-.2\baselineskip\@plus -2\p@}%
                                     {.2\baselineskip}%
                                     {\reset@font\normalsize\bfseries}}
\renewenvironment{theindex}{%
  \if@twocolumn \@restonecolfalse \else \@restonecoltrue \fi
  \columnseprule \z@ \columnsep 35\p@
  \let\autoindex\@gobble
  \twocolumn[\section*{\indexname}]%
  \addcontentsline{toc}{chapter}{\indexname}%
  \@mkboth{\uppercase{\indexname}}{\uppercase{\indexname}}%
  \thispagestyle{plain}\parindent\z@
  \parskip\z@ \@plus .3\p@\relax
  \let\item\@idxitem
}{%
  \if@restonecol\onecolumn\else\clearpage\fi
}
\renewcommand{\thesection}{\arabic{section}}
\long\def\@makecaption#1#2{%
  \addvspace\abovecaptionskip
  \begingroup
    \countdef\@parcycles=8 % local count register
    \@parcycles\z@
    \@setpar{\advance\@parcycles\@ne \ifnum\@parcycles>999
      \@@par\@parcycles\z@\fi
      \ifhmode \unskip\hskip\parfillskip\penalty-\@M\fi}%
    \@hangfrom{\textbf{#1.} }\vadjust{\penalty\m@ne}#2%
  \endgroup
  \ifhmode\unpenalty\fi\par
  \ifnum\lastpenalty=\m@ne % only one line in the caption
    \unpenalty \setbox\@tempboxa\lastbox
    \nointerlineskip
    \hbox to\hsize{\hfill\unhbox\@tempboxa\unskip\hfill}%
  \fi
  \nobreak\vskip\belowcaptionskip
}
\renewenvironment{table}{%
  \belowcaptionskip\abovecaptionskip \abovecaptionskip\z@skip
  \@float{table}%
}{%
  \end@float
}
\renewenvironment{table*}{%
  \belowcaptionskip\abovecaptionskip \abovecaptionskip\z@skip
  \@dblfloat{table}%
}{%
  \end@dblfloat
}
\setcounter{topnumber}{4}\setcounter{bottomnumber}{4}
\setcounter{totalnumber}{4}\setcounter{dbltopnumber}{4}
\renewcommand{\topfraction}{.97}\renewcommand{\bottomfraction}{.97}
\renewcommand{\textfraction}{.03}\renewcommand{\floatpagefraction}{.9}
\renewcommand{\dbltopfraction}{.97}
\renewcommand{\dblfloatpagefraction}{.9}
\setlength{\floatsep}{8pt plus6pt}
\setlength{\textfloatsep}{10pt plus8pt}
\setlength{\intextsep}{8pt plus6pt}
\setlength{\dblfloatsep}{8pt plus6pt}
\setlength{\dbltextfloatsep}{10pt plus8pt}
\setlength{\@fptop}{0pt}\setlength{\@fpsep}{8pt}%
\setlength{\@fpbot}{0pt plus 1fil}
\setlength{\@dblfptop}{0pt}\setlength{\@dblfpsep}{8pt}%
\setlength{\@dblfpbot}{0pt plus 1fil}

\pagestyle{headings}
\newcommand{\arrayargpatch}{%
  \let\@oldarray\@array
  \edef\@array[##1]##2{\catcode\number`\|=\number\catcode`\|
    \catcode\number`\@=\number\catcode`\@ \relax
    \let\noexpand\@array\noexpand\@oldarray
    \noexpand\@array[##1]{##2}}%
  \catcode`\|=12 \catcode`\@=12 \relax
}
\newenvironment{ctab}{%
  \par\topsep\medskipamount
  \trivlist\centering
  \item[]%
  \arrayargpatch
  \begin{tabular}%
}{%
  \end{tabular}%
  \endtrivlist
}
\RequirePackage{doc}
\def\AltMacroFont{\MacroFont}
\def\SpecialMainEnvIndex#1{%
    \@bsphack
    \special@index{%
        #1\actualchar\string\texttt{#1} environment\encapchar main%
    }%
    \special@index{%
        environments:\levelchar#1%
        \actualchar\string\texttt{#1}%
        \encapchar main}%
    \@esphack
}
\def\SpecialEnvIndex#1{%
    \@bsphack
    \index{#1\actualchar\string\texttt{#1} environment\encapchar usage}%
    \index{%
        environments:\levelchar#1%
        \actualchar\string\texttt{#1}%
        \encapchar usage}%
    \@esphack
}
\def\DescribeOption{%
    \leavevmode
    \@bsphack
    \begingroup
        \MakePrivateLetters
    \Describe@Option
}
\def\Describe@Option#1{%
    \endgroup
    \marginpar{\raggedleft\PrintDescribeOption{#1}}%
    \SpecialOptionIndex{#1}%
    \@esphack
    \ignorespaces
}
\def\PrintDescribeOption#1{\strut \MacroFont #1\ }
\def\option{%
    \let\SpecialMainEnvIndex\SpecialMainOptionIndex
\begingroup
   \catcode`\\12
   \MakePrivateLetters \m@cro@ \iffalse}
\def\SpecialMainOptionIndex#1{%
    \@bsphack
    \special@index{#1\actualchar\string\texttt{#1} option\encapchar main}%
    \@esphack
}
\def\SpecialOptionIndex{\@category@index{option}}
\def\hDocInput#1{\MakePercentIgnore
  \begingroup
  \begingroup \lccode`\~=`\@
  \lowercase{\endgroup\long\def ~}##1##{%
    \catcode`\==12 \skipfileheader{##1}}%
  \catcode`\@=\active \catcode`\==14 % comment
  \def\filename{#1}%
  \@@input#1 \MakePercentComment}
\def\skipfileheader#1#2 {\endgroup
  \hGetFileInfo#2 version = "??" date = "??"\@nil
  \begingroup\catcode`\==9 \catcode`\ =9 \futurelet\0\endgroup
}
\long\def\hGetFileInfo#1 version = "#2"#3 date = "#4"#5\@nil{%
  \def\fileversion{#2}\def\filedate{#4}}
\hyphenation{base-line-skip}
\DoNotIndex{\@xp,\@nx,\@empty,\newcommand,\renewcommand}
\DoNotIndex{\newenvironment,\renewenvironment,\providecommand}
\DoNotIndex{\if,\fi,\ifnum,\fi,\@let@token,\futurelet,\fsa@n}
\DoNotIndex{\ignorespaces,\@tempcnta,\@tempcntb,\count@}
\DoNotIndex{\toks@,\@ne,\advance}
\DoNotIndex{\!,\/,\?,\@,\^,\_}
\DoNotIndex{\@@par,\@M,\@auxout,\@bsphack,\@esphack,\@depth,\@ehc}
\DoNotIndex{\@for,\@flushglue,\@gobble,\@gobbletwo,\@height,\@idxitem}
\DoNotIndex{\@ifnextchar,\@ifstar,\@ifundefined,\@input,\@latexerr}
\DoNotIndex{\@makeschapterhead,\@namedef,\@nameuse,\@nil}
\DoNotIndex{\@nobreakfalse,\@restonecolfalse,\@restonecoltrue}
\DoNotIndex{\@tempa,\@tempb,\@tempc,\@tempf}
\DoNotIndex{\@temptokena,\@temptokenb}
\DoNotIndex{\@themark,\@width}
\DoNotIndex{\active,\aindex,\baselineskip,\begin,\begingroup,\box}
\DoNotIndex{\c@page,\catcode,\chapter,\char,\chardef,\closeout}
\DoNotIndex{\CodelineIndex,\sp,\sb,\label,\leavevmode,\mark}
\DoNotIndex{\mark,\newinsert,\newwrite,\newtoks,\xdef}
\DoNotIndex{\columnsep,\columnseprule,\columnwidth,\csname,\def}
\DoNotIndex{\dimen,\do,\DocInput,\documentstyle,\edef,\em}
\DoNotIndex{\EnableCrossrefs,\end,\endcsname,\endgroup,\endinput}
\DoNotIndex{\everypar,\expandafter,\filedate,\fileversion}
\DoNotIndex{\footnotesize,\gdef,\global,\glossary,\hangindent}
\DoNotIndex{\if@filesw,\else,\fi}
\DoNotIndex{\if@nobreak,\if@twocolumn,\if@twoside,\fi,\fi,\fi}
\DoNotIndex{\hsize,\hskip}
\DoNotIndex{\ifhmode,\ifmmode,\ifodd,\ifvmode,\ifx,\fi,\fi,\fi,\fi,\fi}
\DoNotIndex{\ifcase,\ifdim,\ifeof,\iffalse,\iftrue,\fi,\fi,\fi,\fi,\fi}
\DoNotIndex{\ifcat,\fi}
\DoNotIndex{\immediate,\insert,\item,\jobname,\long}
\DoNotIndex{\let,\lineskip,\marginparsep,\marginparwidth,\maxdimen}
\DoNotIndex{\makeatletter,\noexpand,\openout,\protect,\rlap}
\DoNotIndex{\min,\newpage,\nobreak,\normalbaselineskip}
\DoNotIndex{\normallineskip,\p@,\par,\parfillskip,\parindent,\parskip}
\DoNotIndex{\penalty,\relax,\section,\sin,\sloppy,\space,\string}
\DoNotIndex{\tableofcontents,\the,\thepage,\thispagestyle,\toks,\tt}
\DoNotIndex{\twocolumn,\uppercase,\vbox,\vrule,\vskip,\vss}
\DoNotIndex{\write,\z@,\z@skip}
\endinput
%%
%% End of file `amsdtx.cls'.
