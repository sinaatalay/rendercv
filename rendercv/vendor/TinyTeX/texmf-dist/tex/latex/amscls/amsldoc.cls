%%
%% This is file `amsldoc.cls',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% amsdtx.dtx  (with options: `amsldoc')
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
\ProvidesClass{amsldoc}[2009/08/19 v2.07]
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
\def\actualchar{@}
\def\quotechar{"}
\def\levelchar{!}
\def\encapchar{|}
\def\verbatimchar{+}
\newif\ifcodeline@index
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
\DeclareRobustCommand{\env}{\category@index{environment}}
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
\newcommand{\gloss}[1]{}
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
\newcommand{\openbox}{\leavevmode
  \hbox to.77778em{%
  \hfil\vrule
  \vbox to.675em{\hrule width.6em\vfil\hrule}%
  \vrule\hfil}}
\newcommand{\qedsymbol}{\openbox}
\def\mail{\texttt}
\def\*#1{\def\@tempa{#1}\def\@tempb{*}%
  \ifx\@tempa\@tempb \expandafter\index
  \else #1\index{#1}\fi}
\def\ncn#1{{\let\index\@gobble\cn{#1}}}

\DeclareRobustCommand{\cnbang}{%
  \ncn{\!}\index{"!@{\ntt\bslchar\qcbang}}}
\DeclareRobustCommand{\cnat}{%
  \ncn{\!}\index{"@@{\ntt\bslchar\qcat}}}
\def\5{\penalty500 }
\newenvironment{error}{%
  \begingroup\catcode`\\=12 \expandafter\endgroup\errora
}{%
  \endtrivlist
}
\newcommand{\errora}[1]{%
  \trivlist
  \item[\hskip\labelsep\errorbullet\enspace
    \ntt\frenchspacing\def\@tempa{#1}%
    \expandafter\strip@prefix\meaning\@tempa]\leavevmode\par
}
\newcommand{\errorbullet}{\rule[-.5pt]{2.5pt}{7.5pt}%
  \rule[-.5pt]{5pt}{2.5pt}\kern-2.5pt%
  \rule[4.5pt]{2.5pt}{2.5pt}}
\newcommand{\errexa}{\par\noindent\textit{Example}:\ }
\newcommand{\errexpl}{\par\noindent\textit{Explanation}:\ }
\renewcommand\frontmatter{\clearpage
            \@mainmatterfalse\pagenumbering{roman}}
\renewcommand\mainmatter{\clearpage
       \@mainmattertrue\pagenumbering{arabic}}
\renewcommand\backmatter{\clearpage \@mainmatterfalse}
\renewcommand\part{\clearpage
                 \thispagestyle{plain}%
                 \if@twocolumn
                     \onecolumn
                     \@tempswatrue
                   \else
                     \@tempswafalse
                 \fi
                 \hbox{}\vfil
                 \secdef\@part\@spart}
\def\@part[#1]#2{%
    \ifnum \c@secnumdepth >-2\relax
      \refstepcounter{part}%
      \addcontentsline{toc}{part}{\thepart\hspace{1em}#1}%
    \else
      \addcontentsline{toc}{part}{#1}%
    \fi
    \markboth{}{}%
    {\centering
     \interlinepenalty \@M
     \reset@font
     \ifnum \c@secnumdepth >-2\relax
       \Large\bfseries \partname~\thepart
       \par
       \vskip 20\p@
     \fi
     \Large \bfseries #2\par}%
    \@endpart}
\def\@spart#1{%
    {\centering
     \interlinepenalty \@M
     \reset@font
     \Large \bfseries #1\par}%
    \@endpart}
\def\@endpart{\vfil\newpage
              \if@twoside
                \hbox{}%
                \thispagestyle{empty}%
                \newpage
              \fi
              \if@tempswa
                \twocolumn
              \fi}
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
\renewcommand\section{\@startsection {section}{1}{\z@}%
                                   {-.6\baselineskip \@plus -3\p@}%
                                   {.4\baselineskip}
                         {\reset@font\normalsize\bfseries}}
\renewcommand\subsection{\@startsection{subsection}{2}{\z@}%
                                     {-.3\baselineskip\@plus -2\p@}%
                                     {.2\baselineskip}%
                         {\reset@font\normalsize\bfseries}}
\renewcommand\subsubsection{\@startsection{subsubsection}{3}{\z@}%
                                     {-.2\baselineskip\@plus -2\p@}%
                                     {.2\baselineskip}%
                                     {\reset@font\normalsize\bfseries}}
\renewenvironment{theindex}{%
  \if@twocolumn \@restonecolfalse \else \@restonecoltrue \fi
  \columnseprule \z@ \columnsep 35\p@
  \let\autoindex\@gobble
  \twocolumn[\@makeschapterhead{\indexname}]%
  \addcontentsline{toc}{chapter}{\indexname}%
  \@mkboth{\uppercase{\indexname}}{\uppercase{\indexname}}%
  \thispagestyle{plain}\parindent\z@
  \parskip\z@ \@plus .3\p@\relax
  \let\item\@idxitem
}{%
  \if@restonecol\onecolumn\else\clearpage\fi
}
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
\AtBeginDocument{\catcode`\|=\active }
\def\activevert{\verb|}
\expandafter\gdef\expandafter\dospecials\expandafter
  {\dospecials \do\|}%
\expandafter\gdef\expandafter\@sanitize\expandafter
  {\@sanitize \@makeother\|}
\begingroup\catcode`\|=\active \gdef|{\protect\activevert{}}\endgroup
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
\hyphenation{base-line-skip}
\endinput
%%
%% End of file `amsldoc.cls'.
