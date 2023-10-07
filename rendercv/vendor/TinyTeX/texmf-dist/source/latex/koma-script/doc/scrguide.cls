% ======================================================================
% scrguide.cls
% Copyright (c) Markus Kohm, 2005-2022
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
% scrguide.cls
% Copyright (c) Markus Kohm, 2005-2022
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
%
% \section{Identification}
%
%    \begin{macrocode}
\ProvidesClass{scrguide}[2022/07/17 v1.28 internal KOMA-Script guide class]
%    \end{macrocode}
%
%
% \section{Options on my own}
%
% This class also has options.
%
% The class knows two language options (and some aliases)
% \begin{option}{english}
%    \begin{macrocode}
\DeclareOption{english}{\def\languagename{english}}
\DeclareOption{UKenglish}{%
  \ClassWarning{scrguide}{Language `english' will be used instead of
    `\CurrentOption'}%
  \def\languagename{english}%
}
\DeclareOption{USenglish}{%
  \ClassWarning{scrguide}{Language `english' will be used instead of
    `\CurrentOption'}%
  \def\languagename{english}%
}
\DeclareOption{british}{%
  \ClassWarning{scrguide}{Language `english' will be used instead of
    `\CurrentOption'}%
  \def\languagename{english}%
}
\DeclareOption{american}{%
  \ClassWarning{scrguide}{Language `english' will be used instead of
    `\CurrentOption'}%
  \def\languagename{english}%
}
\DeclareOption{ngerman}{\def\languagename{ngerman}}
\DeclareOption{german}{%
  \ClassWarning{scrguide}{Language `ngerman will be used instead of
    `\CurrentOption'}%
  \def\languagename{ngerman}%
}
%    \end{macrocode}
% \end{option}
%
% \begin{option}{pagereftolabel}
%   |\autopageref| should reference the label not the page.
% \begin{option}{pagereftopage}
%   |\autopageref| should reference the page not the label.
% \begin{macro}{\if@pagereftolabel}
%    \begin{macrocode}
\newif\if@pagereftolabel\@pagereftolabeltrue
\DeclareOption{pagereftolabel}{\@pagereftolabeltrue}
\DeclareOption{pagereftopage}{\@pagereftolabelfalse}
%    \end{macrocode}
% \end{macro}
% \end{option}
% \end{option}
%
% \begin{option}{moreindexnotes}
%   Show more notes at the index.
% \begin{option}{lessindexnotes}
%   Show less notes at the index.
% \begin{macro}{\if@moreindexnotes}
%    \begin{macrocode}
\newif\if@moreindexnotes\@moreindexnotesfalse
\DeclareOption{moreindexnotes}{\@moreindexnotestrue}
\DeclareOption{lessindexnotes}{\@moreindexnotesfalse}
%    \end{macrocode}
% \end{macro}
% \end{option}
% \end{option}
%
% Note: You have to pass options to class \textsf{scrguide}, because only
% these options will be processed by |\LoadClassWithOptions| below.
%    \begin{macrocode}
\ExecuteOptions{pagereftolabel,lessindexnotes}
\PassOptionsToClass{%
  bibliography=totoc,
  index=totoc,
  captions=tableabove,
  headings=small,
  headings=optiontoheadandtoc,
  version=last,
}{scrguide}
\ProcessOptions\relax
%    \end{macrocode}
%
%
% \section{Load the Base Class and Packages}
%
% \begin{macro}{\KOMAProvidesFile}
% \begin{macro}{\@KOMAProvidesFile}
% \changes{v1.22b}{2019/11/18}{\cs{ifstr} umbenannt in \cs{Ifstr}}%^^A
%   Extended version of |\ProvidesFile|, that uses the date from the
%   repository.
%    \begin{macrocode}
\newcommand*{\KOMAProvidesFile}{}
\def\KOMAProvidesFile#1{%
  \@ifnextchar [%]
  {\@KOMAProvidesFile{#1}}{\ProvidesFile{#1}\relax}%
}
\newcommand*{\@KOMAProvidesFile}{}
\def\@KOMAProvidesFile#1[$#2: #3-#4-#5 #6$#7]{%
  \Ifstr{#2}{Date}{%
    \ProvidesFile{#1}[#3/#4/#5 \detokenize{#6 #7}]\relax
  }{%
    \ClassError{scrguide}{missmatch repository date string}{%
      It seams, that you haven't used $%
      Date: YYYY-MM-DD $ for the date of \string\KOMAProvidesFile.}%
    \ProvidesFile{#1}[$#2: #3/#4/#5 \detokenize{#6}$\detokenize{#7}]\relax
  }%
}
%    \end{macrocode}
% \end{macro}
% \end{macro}
%    \begin{macrocode}
\LoadClassWithOptions{scrbook}
\RequirePackage[TS1,T1]{fontenc}
\newcommand*{\strngerman}{ngerman}
\newcommand*{\strenglish}{english}
\edef\reserved@a{\languagename}%
\@onelevel@sanitize\reserved@a
\@onelevel@sanitize\strngerman
\@onelevel@sanitize\strenglish
\edef\languages{\ifx\reserved@a\strngerman main=\fi ngerman,%
  \ifx\reserved@a\strenglish main=\fi english}
\edef\uselanguage{\languagename}
\expandafter\RequirePackage\expandafter[\languages]{babel}%
\AtBeginDocument{%
  \edef\reserved@a{\languagename}%
  \@onelevel@sanitize\reserved@a
  \typeout{TRACE: Current language is `\reserved@a`.}%
  \ifx\reserved@a\strngerman
    \newcommand*{\shortlang}{de}%
  \else
    \newcommand*{\shortlang}{en}%
  \fi
}
\newcommand*{\linclude}[1]{\include{#1-\shortlang}}
%    \end{macrocode}
% In future we should use biblatex instead of babelbib, but currently some
% things are still missing:
% \begin{itemize}
% \item line breaks after the author (but not full \texttt{openbib} style like
%   \texttt{block=nbpar}),
% \item removing language tag \texttt{ngerman} from output.
% \end{itemize}
% So currently we still use babelbib.
%    \begin{macrocode}
\newif\ifusebabelbib\usebabelbibtrue % Should be deactivated soon
\ifusebabelbib
  \RequirePackage[fixlanguage]{babelbib}
  \newcommand*{\printbibliography}[1][]{\bibliography{scrguide}}
\else
  \RequirePackage[backend=bibtex,style=alphabetic,block=ragged]{biblatex}
  \DeclareSourcemap{
    \maps[datatype=bibtex]{
      \map{
        \step[fieldsource=url, final=true]
        \step[fieldset=verba, origfieldval, final=true]
        \step[fieldsource=verba, match=\regexp{CTAN:\/\/}, replace={https://www.ctan.org/}]
      }
    }
  }
  \DeclareFieldFormat{url}{%
    \href{\thefield{verba}}{\nolinkurl{#1}}%
  }
\fi  
\RequirePackage{afterpage}
\RequirePackage{makeidx}
\RequirePackage{scrdate}
\RequirePackage{scrtime}
\RequirePackage{picture}
\RequirePackage{graphicx}
\RequirePackage{booktabs}
\RequirePackage{longtable}
\RequirePackage{amsmath}
\RequirePackage{listings}
\RequirePackage{multicol}
\RequirePackage{marginnote}
\RequirePackage{tabularx}
\RequirePackage{scrhack}%
\RequirePackage{mparhack}%
%    \end{macrocode}
%
% \section{Dependence from \KOMAScript{} Version}
%
% \begin{macro}{currentversionlt}
\newcommand*{\currentversionlt}[1]{%
  \expandafter\ifx\csname scr@v@#1\endcsname\relax \maxdimen
  \else\csname scr@v@#1\endcsname\fi >\scr@compatibility\relax
}
%    \end{macrocode}
% \end{macro}
%
% \section{Free or Non-Free Version}
%
%    \begin{macrocode}
\newif\ifshortversion\shortversionfalse
\InputIfFileExists{scrnonfree.tex}{}{%
  \RequirePackage[svgnames]{xcolor}%
  \RequirePackage{tikz}%
  \usetikzlibrary{decorations}%
  \usetikzlibrary{arrows}%
  \usetikzlibrary{calc}%
  \RequirePackage[\uselanguage]{hyperref}%
  \RequirePackage[open,openlevel=0]{bookmark}% improved pdf bookmarks
  \typeout{^^J
    ----------------------------------------------------------------------^^J
    FREE VERSION OF THE KOMA-SCRIPT GUIDE.^^J
    NOTE THAT THIS VERSION MAY BE FULL OF UGLY PARAGRAPH AND PAGE BREAKS.^^J
    THIS IS BECAUSE THIS VERSION OF THE KOMA-SCRIPT GUIDE IS UNDER^^J
    CONSTRUCTION FOREVER.^^J
    ----------------------------------------------------------------------^^J
    ^^J%
  }%
  \newcommand*{\iffree}{\@firstoftwo}%
  \newcommand*{\important}[2][]{}%
  \newcommand*{\textnote}[2][]{}%
  \shortversiontrue
  \newcommand*{\LoadNonFree}[2]{\par\GuideLoadNonFree\par}%
  \AtBeginDocument{\InputIfFileExists{linkalias.tex}{}{}}%
  \usepackage{lmodern}%
  \@twosidefalse\@openrightfalse\@mparswitchfalse
  \RequirePackage{geometry}%
  \geometry{papersize={180mm,210mm},%
    includehead,includemp,reversemp,marginparwidth=4em,%
    vmargin={1.5mm,3mm},hmargin=1.75mm}%
  \RequirePackage{scrlayer-scrpage}%
  \clearpairofpagestyles
  \ihead{%
    \smash{%
      \hspace*{.5em}\rule[-\dp\strutbox]{0pt}{\headheight}\headmark
    }%
  }%
  \ohead*{\smash{\pagemark\hspace{2mm}}}%
  \colorlet{headbackground}{DarkBlue}%
  \colorlet{headline}{white}%
  \setkomafont{pageheadfoot}{\small\sffamily\bfseries\color{headline}}%
  \setkomafont{pagenumber}{}%
  \DeclareNewLayer[head,background,
    hoffset=0pt,
    width=\paperwidth,
    addheight=\dimexpr \topmargin+1in+\dp\strutbox\relax,
    addvoffset=2\dp\strutbox,
    contents={%
      \color{headbackground}\rule{\layerwidth}{\layerheight}}]
  {headbackground}%
  \AddLayersAtBeginOfPageStyle{scrheadings}{headbackground}%
  \renewcommand*{\chaptermark}[1]{%
    \@mkdouble{\Ifnumbered{chapter}{\chaptermarkformat}{}##1}%
  }%
  \renewcommand*{\chaptermarkformat}{%
    \makebox[\dimexpr \oddsidemargin+1in-.5em][r]{%
      \chapapp~\thechapter:~%
    }%
  }%
  \renewcommand*{\chapterformat}{}%
  \renewcommand*{\chapterpagestyle}{scrheadings}%
  \setlength{\@tempdimc}{\oddsidemargin}%
  \addtolength{\@tempdimc}{1in}%
  \KOMAoptions{headwidth=paper:-\@tempdimc}%
  % Entweder:
  \hypersetup{colorlinks,citecolor=Green,linkcolor=Crimson,urlcolor=Blue}% 
  % oder:
%    \hypersetup{pdfborderstyle={/S/U/W 1}}%
  \let\orig@maketitle\maketitle
  \def\maketitle{%
    \begingroup
      \@twosidetrue
      \let\cleardoublepage\clearpage
      \addtolength{\oddsidemargin}{\evensidemargin}%
      \setlength{\evensidemargin}{.5\oddsidemargin}%
      \setlength{\oddsidemargin}{\evensidemargin}%
      \orig@maketitle\relax
    \endgroup
  }%
  \renewcommand*{\chapterheadstartvskip}{}%
  \raggedbottom
  \sloppy
  \lstset{breaklines,prebreak=\mbox{$\hookleftarrow$}}%
}%
%    \end{macrocode}
%
% Now loading the last package (better do it late than never):
%    \begin{macrocode}
\RequirePackage{textcomp}
%    \end{macrocode}
%
% \section{Load common paragraphs}
%
% \begin{macrocode}
\newcommand*{\ThisCommonFile}{}%
\newcommand*{\ThisCommonLabelBase}{}
\newcommand*{\IfThisCommonLabelBase}[1]{%
  \expandafter\Ifstr\expandafter{\ThisCommonLabelBase}{#1}%
  \@firstoftwo\@secondoftwo
}
\newcommand*{\IfThisCommonLabelBaseOneOf}[1]{%
  \begingroup
    \@tempswafalse
    \@for \reserved@a:=#1\do{%
      \expandafter\IfThisCommonLabelBase\expandafter{\reserved@a}%
      {\@tempswatrue}{}%
    }%
    \if@tempswa
      \aftergroup\@firstoftwo
    \else
      \aftergroup\@secondoftwo
    \fi
  \endgroup
}
\newcommand*{\IfThisCommonLabelBaseNotOneOf}[1]{%
  \begingroup
    \@tempswafalse
    \@for \reserved@a:=#1\do{%
      \expandafter\IfThisCommonLabelBase\expandafter{\reserved@a}%
      {\@tempswatrue}{}%
    }%
    \if@tempswa
      \aftergroup\@secondoftwo
    \else
      \aftergroup\@firstoftwo
    \fi
  \endgroup
}
\newcommand*{\ThisCommonFirstLabelBase}{%
  \@nameuse{CommonFile@\ThisCommonFile @LabelBase}%
}
\newif\ifthiscommonfirst
\newcommand*{\IfThisCommonFirstRun}{%
  \ifthiscommonfirst \expandafter\@firstoftwo
  \else \expandafter\@secondoftwo \fi
}
\newcommand*{\LoadCommonFile}[1]{%
  \Ifstr{\ThisCommonFile}{}{%
    \def\ThisCommonFile{#1}%
    \let\ThisCommonLabelBase\label@base
    \@ifundefined{CommonFile@\ThisCommonFile @LabelBase}{%
      \expandafter\let\csname CommonFile@\ThisCommonFile @LabelBase\endcsname
      \ThisCommonLabelBase
      \thiscommonfirsttrue
    }{\thiscommonfirstfalse}%
    \input{common-\ThisCommonFile-\shortlang.tex}%
    \thiscommonfirstfalse
    \let\ThisCommonLabelBase\@empty
    \let\ThisCommonFile\@empty
  }{%
    \ClassError{scrguide}{recursive \string\LoadCommon}{%
      You can not use \string\LoadCommon\space inside another
      common file.%
    }%
  }%
}
\newcommand*{\InternalCommonFileUsageError}{%
  \GenericError{%
    (common-\ThisCommonFile-\shortlang.tex)\@spaces
  }{%
    Common File common-\ThisCommonFile-\shortlang.tex Error: Unprepared usage%
  }{%
    You have to prepare the file for the label base \ThisCommonLabelBase.%
  }{}%
}
% \end{macrocode}
%
% \section{Language Dependencies}
%
% We load the language dependency file at |\begin{document}| and add some
% of the extensions to the language.
%    \begin{macrocode}
\AtBeginDocument{%
  \InputIfFileExists{terms-\shortlang.tex}{%
    \ClassInfo{scrguide}{Loading language dependencies for \languagename}%
  }{%
    \ClassError{scrguide}{\languagename\space not supported}{%
      You've tried to generate a guide for language `\languagename' but
      language\MessageBreak
      dependency file `terms-\shortlang.tex' was not found.\MessageBreak
      This may result in a lot of errors and warnings, if you'll continue}%
  }%
  \expandafter\addto\csname extras\uselanguage\endcsname
  \GuideLanguageExtensions\GuideLanguageExtensions
}
%    \end{macrocode}
%
%
% \section{Breaking of Paragraphs and Pages}
%
% There are several parameters to configure the breaking. I've tried to find
% good values. First of all the placement of floats and text.
%    \begin{macrocode}
\renewcommand*{\floatpagefraction}{.75}% was .6
\renewcommand*{\textfraction}{.2}% original
\renewcommand*{\topfraction}{.75}% was .7
\renewcommand*{\bottomfraction}{.33}% was .3
\setcounter{topnumber}{1}% was 2
\setcounter{bottomnumber}{1}% original
\setcounter{totalnumber}{3}% original
%    \end{macrocode}
%
%
% \section{Find the Date of the Newest Documentation File}
%
% \begin{macro}{\newestfiledate}
%    The latex date of the newest used file.
%    \begin{macrocode}
\newcommand*{\newestfiledate}{0001-01-01}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\@notonlypreamble}
%    Remove commands from to be \@onlypreamble commands.
%    \begin{macrocode}
\newcommand*{\@notonlypreamble}[1]{%
  \begingroup
    \let\new@preamblecmds\@empty%
    \def\do##1{\ifx ##1#1\else
      \expandafter\def\expandafter\new@preamblecmds\expandafter{%
        \new@preamblecmds\do##1}\fi}%
    \@preamblecmds
    \global\let\@preamblecmds\new@preamblecmds
  \endgroup
}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\@ifl@t@r}
%    Not longer a |\@onlypreamble| command.
%    \begin{macrocode}
\@notonlypreamble\@ifl@t@r
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\@parse@version}
%    Not longer a |\@onlypreamble| command.
%    \begin{macrocode}
\@notonlypreamble\@parse@version
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\@latex@version}
%    Like |\@parse@version| but returns a \LaTeX{} date.
%    \begin{macrocode}
\newcommand*{\@latex@version}{}
\def\@latex@version#1/#2/#3#4#5\@nil{#1/#2/#3#4}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\@iso@version}
%    Like |\@parse@version| but returns an iso date.
%    \begin{macrocode}
\newcommand*{\@iso@version}{}
\def\@iso@version#1/#2/#3#4#5\@nil{#1-#2-#3#4}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\IsoDate}
%    Converts \LaTeX{} date #1 into an iso date.
%    \begin{macrocode}
\newcommand*{\IsoDate}[1]{\expandafter\@iso@version#1//00\@nil}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\@CheckDate}
%    Check if the provided date of file #1.tex is newer than
%    \@newestfiledate. If so, write the new date to the aux file.
%    \begin{macrocode}
\newcommand*{\@CheckDate}[1]{%
  \begingroup
    \expandafter\ifx\csname ver@#1.tex\endcsname\relax\else
      \typeout{\csname ver@#1.tex\endcsname}%
      \expandafter\@ifl@t@r\csname ver@#1.tex\endcsname\newestfiledate{%
        \xdef\newestfiledate{%
          \expandafter\expandafter\expandafter\@latex@version
          \csname ver@#1.tex\endcsname//00\@nil%
        }%
        \write\@auxout{\noexpand\gdef\noexpand\newestfiledate{%
            \newestfiledate}\@percentchar\space #1.tex}%
     }{}%
    \fi
  \endgroup
}
%    \end{macrocode}
% \end{macro}
%
% Check the date of the jobfile:
%    \begin{macrocode}
\@CheckDate\jobname
%    \end{macrocode}
%
% \begin{macro}{\@providesfile}
% \begin{macro}{\SCR@providesfile}
%    Redefine |\ProvidesFile| to also check the date.
%    \begin{macrocode}
\newcommand*{\SCR@providesfile}{}
\AtBeginDocument{%
  \let\SCR@providesfile\@providesfile
  \def\@providesfile#1[#2]{%
    \SCR@providesfile#1[#2]%
    \expandafter\@CheckDate\expandafter{\expandafter\@BaseFileName#1.\@nil}%
  }%
}
%    \end{macrocode}
% \begin{macro}{\@BaseFileName}
%    Split of extension of the file name.
%    \begin{macrocode}
\newcommand*{\@BaseFileName}{}
\def\@BaseFileName#1.#2\@nil{#1}
%    \end{macrocode}
% \end{macro}
% \end{macro}
% \end{macro}
%
% Predefine current date:
%    \begin{macrocode}
\AtBeginDocument{\date{\IsoDate\newestfiledate}}
%    \end{macrocode}
%
%
% \section{Collect All Translators}
%
% At the translated guides, the translators should also be shown somewhere at
% the title.
%
% \begin{macro}{\translator}
%   \changes{v0.9d}{2007/09/18}{new}
% This macro is used, so save one or more translators into the aux file.
%    \begin{macrocode}
\newcommand*{\translator}[1]{%
  \protected@write\@auxout{\def\and{,}}{%
    \protect\@addtranslators{#1}%
  }%
}
%    \end{macrocode}
% \begin{macro}{\@translator}
% \begin{macro}{\@addtranslator}
% And we need macros so store the translators
%    \begin{macrocode}
\newcommand*{\@translator}{}
%    \end{macrocode}
% and to read the translators from the aux file.
%    \begin{macrocode}
\newcommand*{\@addtranslators}[1]{%
  \ifx\@translator\@empty\else\g@addto@macro\@translator{,}\fi
  \g@addto@macro\@translator{#1}%
}
%    \end{macrocode}
% \end{macro}
% \end{macro}
% \end{macro}
%
%
% \begin{macro}{\settranslator}
%   \changes{v0.9d}{2007/09/18}{new}
% Last but not least, we need a macro to set the list of translators.
%    \begin{macrocode}
\newcommand{\settranslator}[2]{%
  \ifx\@translator\@empty\else
    #1%
    \begingroup
%    \end{macrocode}
% Run through all translators, but store each once only.
%    \begin{macrocode}
      \let\@tempb\@empty
      \@tempcnta=\z@
      \expandafter\@for \expandafter\@tempa\expandafter:\expandafter=%
      \@translator\do {%
        \ifx\@tempa\@empty\else
%<trace>          \typeout{Test: `,\@tempa,' at `,\@tempb,'}%
          \@expandtwoargs\in@{,\@tempa,}{,\@tempb,}%
          \ifin@\else
            \edef\@tempb{\@tempb\@tempa,}%
            \advance\@tempcnta by 1\relax
          \fi
        \fi
      }%
%    \end{macrocode}
% Set each of the stored translators.
%    \begin{macrocode}
      \@tempcntb=\z@
      \expandafter\@for \expandafter\@tempa\expandafter:\expandafter=%
      \@tempb\do {%
        \ifx\@tempa\@empty\else
          \advance\@tempcntb by 1\relax
          \typeout{Translator \the\@tempcntb: \@tempa}%
          \ifnum\@tempcntb >\@ne\relax
            \ifnum\@tempcntb=\@tempcnta\relax
              \ifnum\@tempcntb=\tw@\relax
                \GuideAnd
              \else
                \GuideListAnd
              \fi
            \else
              ,
            \fi
          \fi
          \@tempa
        \fi
      }%
    \endgroup
    #2%
  \fi
}
%    \end{macrocode}
% \end{macro}
%
% \section{Emphasization and Fonts}
%
% The \KOMAScript{} guide uses a lot of emphasizations. Most of them are
% declared robustly to avoid problems at index, change log etc.
%
% We need some colors for emphasizing in images:
%    \begin{macrocode}
\colorlet{ImageRed}{Crimson}%
\colorlet{ImageBlue}{Blue}%
\colorlet{ImageGreen}{Green}%
\colorlet{ImageYellow}{Yellow}%
%    \end{macrocode}
%
% \begin{macro}{\textsfrm}
%   Something like |\emph| using |\textsf| and |\textrm| instead of |\textit|
%   and |\textup|.
%    \begin{macrocode}
\newcommand*{\textsfrm}[1]{%
  \begingroup
    \edef\@tempa{\sfdefault}%
    \ifx\@tempa\f@family\textrm{#1}\else\textsf{#1}\fi
  \endgroup
}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\File}
%   \changes{v1.25}{2021/02/11}{usage of \cs{texorpdfstring}}
% \begin{macro}{\Class}
%   \changes{v1.25}{2021/02/11}{usage of \cs{texorpdfstring}}
% \begin{macro}{\Package}
%   \changes{v1.25}{2021/02/11}{usage of \cs{texorpdfstring}}
%   Some markup macros for files with special meanings.
\DeclareRobustCommand*{\File}[1]{\texorpdfstring{\mbox{\texttt{#1}}}{#1}}
\DeclareRobustCommand*{\Class}[1]{\texorpdfstring{\mbox{\textsfrm{#1}}}{#1}}
\DeclareRobustCommand*{\Package}[1]{\texorpdfstring{\mbox{\textsfrm{#1}}}{#1}}
% \end{macro}
% \end{macro}
% \end{macro}
%
% \begin{macro}{\DeclareSpecialMarkup}
%   Command to declare special markup commands, that behave different in- and
%   outside |Description| environment. Parameters are:
%   \begin{declaration}
%     \item[\arg{command}:] The the markup command, that should be defined.
%     \item[\arg{outside definition}:] Definition of the markup command
%       outside |Description| environment.
%     \item[\arg{inside definition}:] Definition of the markup command inside
%       |Description| environment.
%     \item{\oarg{inside end definition}:] Definition of the \cs{end} command,
%       if inside |Description| an markup environment instead of an markup
%       command would be used.
%   \end{declaration}
%   At the end color \meta{command name} will be black and \cs{\meta{command
%   name}}, \cs{text\meta{command name}, \cs{Desc\meta{command name}}, and
%   optionally \cs{endDesc\meta{command name} will be defined, with
%   \cs{\meta{command name}} is \meta{command}.
%    \begin{macrocode}
\newcommand\DeclareSpecialMarkup[3]{%
  \newcommand*#1{}%
  \expandafter\colorlet\expandafter{\expandafter\@gobble\string#1}{black}%
  \expandafter\newcommand\expandafter*%
  \csname text\expandafter\@gobble\string #1\endcsname[1]{#2}%
  \expandafter\DeclareRobustCommand\expandafter*\expandafter#1\expandafter{%
    \csname text\expandafter\@gobble\string #1\endcsname}%
  \expandafter\newcommand\expandafter*%
  \csname Desc\expandafter\@gobble\string #1\endcsname[1]{#3}%
  \kernel@ifnextchar [%
    {\expandafter\@optdef
     \csname endDesc\expandafter\@gobble\string #1\endcsname}%
    {}%]
}
%    \end{macrocode}
% \begin{macro}{\@optdef}
%   Helper to define a macro via optional instead of mandatory argument
\newcommand*{\@optdef}{}
\long\def\@optdef#1[#2]{\def#1{#2}}
%    \end{macrocode}
% \end{macro}
% \end{macro}
%
% \begin{macro}{\Macro}
%   \changes{v1.25}{2021/02/11}{usage of \cs{texorpdfstring}}
% \begin{macro}{\Option}
% \begin{macro}{\KOption}
% \begin{macro}{\OptionValue}
% \begin{macro}{\Environment}
% \begin{macro}{\Counter}
% \begin{macro}{\Length}
%   \changes{v1.25}{2021/02/11}{usage of \cs{texorpdfstring}}
% \begin{macro}{\PLength}
% \changes{v1.17}{2019/10/24}{\cs{setplength} verschoben}%^^A
% \begin{macro}{\FloatStyle}
% \begin{macro}{\PageStyle}
% \begin{macro}{\Variable}
% \begin{macro}{\FontElement}
% \begin{macro}{\DoHook}
% \changes{v1.14}{2019/02/20}{neu}%^^A
% \begin{macro}{\PName}
% \begin{macro}{\PValue}
% \begin{macro}{\Parameter}
% \begin{macro}{\OParameter}
% \begin{macro}{\AParameter}
% \begin{macro}{\PParameter}
% \begin{macro}{\POParameter}
%   \begin{description}
%   \item[\cs{Macro}] \LaTeX{} or \TeX{} macro
%   \item[\cs{Option}] class or package option
%   \item[\cs{KOption}] |\KOMAoptions| option
%   \item[\cs{Environment}] \LaTeX{} environment
%   \item[\cs{Counter}] \LaTeX{} counter
%   \item[\cs{Length}] \LaTeX{} length
%   \item[\cs{PLength}] \KOMAScript{} pseudo length
%   \item[\cs{Variable}] \KOMAScript{} variable
%   \item[\cs{FontElement}] \KOMAScript{} element that has its own font
%     selection
%   \item[\cs{PName}] name of a parameter of a macro or environment
%   \item[\cs{PValue}] value of a parameter of a macro or environment
%   \item[\cs{Parameter}] the mandatory parameter of a macro or environment
%   \item[\cs{OParameter}] the optional parameter of a macro or environment
%   \item[\cs{AParameter}] the alternativ parameter of a macro or environment
%   \item[\cs{PParameter}] the part-of-command parameter of a macro or
%     environment
%   \end{description}
%    \begin{macrocode}
\newcommand*{\LabelMacro}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\Macro{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.cmd.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.cmd.#2#1}%
  \endgroup
}
\DeclareRobustCommand*{\DescRef}{%
  \kernel@ifstar {\@DescRef*}{\@DescRef\@empty}%
}
\newcommand*{\@DescRef}[2]{\expandafter\ref#1{\label@desc@prefix#2}}
\DeclareRobustCommand*{\DescPageRef}{%
  \kernel@ifstar {\@DescPageRef*}{\@DescPageRef\space}%
}
\newcommand*{\@DescPageRef}[2]{\expandafter\autopageref#1{\label@desc@prefix#2}}
\DeclareSpecialMarkup{\Macro}{%
  \texorpdfstring{\mbox{\texttt{\char`\\#1}}}{\textbackslash#1}%
}{%
  \par
  \settowidth{\leftskip}{\textMacro{#1}}% indent from left
  \hskip-\leftskip
  \BeginIndex{Cmd}{#1}% index entry
  \LabelMacro{#1}%
  \textMacro{#1}%
}
\newcommand*{\LabelOption}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\Option{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.option.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \expandafter\gdef
    \csname \label@desc@prefix\label@base.option.#2#1\endcsname{}%
    \label{\label@desc@prefix\label@base.option.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\Option}{\mbox{\texttt{#1}}}{%
  \par
  \leftskip\z@
  \BeginIndex{Option}{#1}% index entry
  \LabelOption{#1}%
  \textOption{#1}%
}
\DeclareSpecialMarkup{\KOption}{%
  \mbox{\textOption{#1=}}\linebreak[0]%
}{%
  \ClassWarning{scrguide}{You should replace
    \string\KOption{#1}\string\PName{...}\MessageBreak
    by \string\OptionVName{#1}{...}}%
  \par
  \leftskip\z@
  \BeginIndex{Option}{#1}% index entry
  \begingroup
    \@nameuse{phantomsection}%
    \label@sanitize
    \expandafter\gdef
    \csname \label@desc@prefix\label@base.option.#1\label@suffix\endcsname{}%
    \label{\label@desc@prefix\label@base.option.#1\label@suffix}%
  \endgroup
  \textOption{#1=}%
}
\newcommand*{\maybelinebreak}{%
  \ifvmode\else
    \ifnum\lastpenalty<\z@\else
      \ifnum\lastpenalty<\@medpenalty
        \hskip\z@skip
      \fi
    \fi
  \fi
}
\DeclareRobustCommand*{\textKValue}[1]{\maybelinebreak\mbox{\texttt{#1}}}
\newcommand*{\KValue}{}
\let\KValue\textKValue
\newcommand*{\textOptionValue}[2]{%
  \textKOption{#1}\textKValue{#2}%
}
\DeclareRobustCommand*{\OptionValue}{\textOptionValue}%
\newcommand*{\LabelOptionValue}[3][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabellong{\OptionValue{#2}{#3}}%
    \protected@edef\@currentlabelshort{\Option{#2}}%
    \label@sanitize
    \scr@ifundefinedorrelax{%
      \label@desc@prefix\label@base.option.#2\label@suffix
    }{%
      \expandafter\gdef
      \csname \label@desc@prefix\label@base.option.#2\label@suffix\endcsname{}%
      \Hy@MakeCurrentHref{\label@desc@prefix\label@base.option.#2#1}%
      \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
      \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
      \let\@currentlabel\@currentlabelshort
      \label{\label@desc@prefix\label@base.option.#2#1}%
    }{}%
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.option.#2.#3#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \let\@currentlabel\@currentlabellong
    \label{\label@desc@prefix\label@base.option.#2.#3#1}%
  \endgroup
}
%    \end{macrocode}
% \begin{macro}{\OptionValueRef}
%   \cs{OptionValue} by reference. Use it like
%   |\OptionValueRef[suffix]{maincls}{version}{3.20}|.
%    \begin{macrocode}
\newcommand*{\OptionValueRef}{%
  \kernel@ifstar {\@RefOptionValue0}{\@RefOptionValue1}%
}
\newcommand*{\@RefOptionValue}[1]{%
  \kernel@ifnextchar [%]
  {\@@RefOptionValue#1}{\@@RefOptionValue#1[]}%
}
\newcommand*{\@@RefOptionValue}{}
\def\@@RefOptionValue#1[#2]#3#4#5{%
  \scr@ifundefinedorrelax{r@\label@desc@prefix#3.option.#4.#5#2}{%
    \ifcase #1
      \expandafter\scr@no@hyperref
    \else
      \expandafter\hyperref
    \fi
    [\label@desc@prefix#3.option.#4#2]%
    {\OptionValue{\ref*{\label@desc@prefix#3.option.#4#2}}{#5}}%
  }{%
    \expandafter\ref\ifcase #1 *\fi{\label@desc@prefix#3.option.#4.#5#2}%
  }%
}
\newcommand*{\scr@no@hyperref}[2][]{#2}
%    \end{macrocode}
% \end{macro}
%    \begin{macrocode}
\newcommand*{\DescOptionValue}[2]{%
  \par
  \leftskip\z@
  \BeginIndex{Option}{#1}%
  \BeginIndex{Option}{#1~=\KValue{#2}}%
  \LabelOptionValue{#1}{#2}%
  \textOptionValue{#1}{#2}%
}
\newcommand*{\textOptionVName}[2]{%
  \textKOption{#1}\PName{#2}%
}
\DeclareRobustCommand*{\OptionVName}{\textOptionVName}%
\newcommand*{\LabelOptionVName}[3][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabellong{\OptionVName{#2}{#3}}%
    \protected@edef\@currentlabelshort{\Option{#2}}%
    \label@sanitize
    \scr@ifundefinedorrelax{%
      \label@desc@prefix\label@base.option.#2\label@suffix
    }{%
      \expandafter\gdef
      \csname \label@desc@prefix\label@base.option.#2\label@suffix\endcsname{}%
      \Hy@MakeCurrentHref{\label@desc@prefix\label@base.option.#2#1}%
      \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
      \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
      \let\@currentlabel\@currentlabelshort
      \label{\label@desc@prefix\label@base.option.#2#1}%
    }{}%
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.option.#2=#3#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \let\@currentlabel\@currentlabellong
    \label{\label@desc@prefix\label@base.option.#2=#3#1}%
  \endgroup
}
%    \end{macrocode}
% \begin{macro}{\OptionVNameRef}
%   \cs{OptionVName} by reference. Use it like
%   |\OptionVNameRef[suffix]{maincls}{version}{value}|.
%    \begin{macrocode}
\newcommand*{\OptionVNameRef}{%
  \kernel@ifstar {\@RefOptionVName0}{\@RefOptionVName1}%
}
\newcommand*{\@RefOptionVName}[1]{%
  \kernel@ifnextchar [%]
  {\@@RefOptionVName#1}{\@@RefOptionVName#1[]}%
}
\newcommand*{\@@RefOptionVName}{}
\def\@@RefOptionVName#1[#2]#3#4#5{%
  \scr@ifundefinedorrelax{r@\label@desc@prefix#3.option.#4=#5#2}{%
    \ifcase #1
      \expandafter\scr@no@hyperref
    \else
      \expandafter\hyperref
    \fi
    [\label@desc@prefix#3.option.#4#2]%
    {\OptionVName{\ref*{\label@desc@prefix#3.option.#4#2}}{#5}}%
  }{%
    \expandafter\ref\ifcase #1 *\fi{\label@desc@prefix#3.option.#4=#5#2}%
  }%
}
%    \end{macrocode}
% \end{macro}
%    \begin{macrocode}
\newcommand*{\DescOptionVName}[2]{%
  \par
  \leftskip\z@
%  \BeginIndex{Option}{#1}%
  \BeginIndex{Option}{#1~=\PName{#2}}%
  \LabelOptionVName{#1}{#2}%
  \textOptionVName{#1}{#2}%
}
\newcommand*{\LabelFloatStyle}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\FloatStyle{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.floatstyle.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.floatstyle.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\FloatStyle}{\mbox{\texttt{#1}}}{%
  \par
  \leftskip\z@
  \BeginIndex{Floatstyle}{#1}%
  \LabelFloatStyle{#1}%
  \textFloatStyle{#1}%
}
\newcommand*{\LabelPageStyle}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\PageStyle{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.pagestyle.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.pagestyle.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\PageStyle}{\mbox{\texttt{#1}}}{%
  \par
  \leftskip\z@
  \BeginIndex{Pagestyle}{#1}%
  \LabelPageStyle{#1}%
  \scr@ifundefinedorrelax{r@\label@desc@prefix maincls.cmd.pagestyle}{%
    \textMacro{pagestyle}%
  }{%
    \begingroup
      \let\Macro\textMacro
      \DescRef{maincls.cmd.pagestyle}%
    \endgroup
  }\PParameter{#1}%
}
\newcommand*{\LabelEnvironment}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\Environment{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.env.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.env.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\Environment}{\mbox{\texttt{#1}}}{%
  \par
  \settowidth{\leftskip}{\textMacro{begin}\PParameter{#1}}% siehe Macro
  \hskip-\leftskip
  \BeginIndex{Env}{#1}%
  \LabelEnvironment{#1}%
  \textMacro{begin}\PParameter{#1}%
  \def\d@EnvironmentName{#1}% Umgebungsnamen merken für das Ende
}[{%
  \ifvmode\hskip-\leftskip\else \unskip\,\dots\fi% \begin{…}…\end{…}
  \textMacro{end}\expandafter\PParameter\expandafter{\d@EnvironmentName}\par
}]%
\newcommand*{\LabelCounter}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\Counter{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.counter.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.counter.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\Counter}{\mbox{\texttt{#1}}}{%
  \par
  \leftskip\z@
  \BeginIndex{Counter}{#1}%
  \LabelCounter{#1}%
  \textCounter{#1}%
}
\newcommand*{\LabelLength}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\Length{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.length.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.length.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\Length}{%
  \texorpdfstring{\mbox{\texttt{\char`\\#1}}}{\textbackslash#1}%
}{%
  \par
  \leftskip\z@
  \BeginIndex{Length}{#1}% index entry
  \LabelLength{#1}%
  \textLength{#1}%
}
\newcommand*{\LabelPLength}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\PLength{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.plength.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.plength.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\PLength}{\mbox{\texttt{#1}}}{%
  \par
  \leftskip\z@
  \BeginIndex{PLength}{#1}%
  \LabelPLength{#1}%
  \scr@ifundefinedorrelax{%
    r@\label@desc@prefix scrlttr2.cmd.setplength}{%
    \textMacro{setplength}%
  }{%
    \begingroup
      \let\Macro\textMacro
      \DescRef{scrlttr2.cmd.setplength}%
    \endgroup
  }%
  \PParameter{#1}\Parameter{\lengthname}%
}
\newcommand*{\LabelVariable}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\Variable{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.variable.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.variable.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\Variable}{\mbox{\texttt{#1}}}{%
  \par
  \leftskip\z@
  \BeginIndex{Variable}{#1}%
  \LabelVariable{#1}%
  \scr@ifundefinedorrelax{r@\label@desc@prefix scrlttr2.cmd.setkomavar}{%
    \textMacro{setkomavar}%
  }{%
    \begingroup
      \let\Macro\textMacro
      \DescRef{scrlttr2.cmd.setkomavar}%
    \endgroup
  }%
  \PParameter{#1}\OParameter{\descriptionname}%
  \Parameter{\contentname}%
}
\newcommand*{\LabelFontElement}[2][\label@suffix]{%
  \begingroup
    \protected@edef\@currentlabel{\FontElement{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.fontelement.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.fontelement.#2#1}%
  \endgroup
}
\DeclareSpecialMarkup{\FontElement}{\mbox{\texttt{#1}}}{%
  \par
  \leftskip\z@
  \BeginIndex{FontElement}{#1}%
  \LabelFontElement{#1}%
  \scr@ifundefinedorrelax{r@\label@desc@prefix\LabelBase.cmd.setkomafont}{%
    \scr@ifundefinedorrelax{r@\label@desc@prefix maincls.cmd.setkomafont}{%
      \textMacro{setkomafont}%
    }{%
      \begingroup
        \let\Macro\textMacro
        \DescRef{maincls.cmd.setkomafont}%
      \endgroup
    }%
  }{%
    \begingroup
      \let\Macro\textMacro
      \DescRef{\LabelBase.cmd.setkomafont}%
    \endgroup
  }%
  \PParameter{#1}\OParameter{\fontsettingname}%
}
\newcommand*{\LabelDoHook}[2][\label@suffix]{%
  \begingroup
    \renewcommand*{\PName}[1]{=##1=}%
    \ForDoHook{#2}{\Label@DoHook{#1}}%
  \endgroup
}
\newcommand*{\Label@DoHook}[3]{%
  \IfArgIsEmpty{#3}{\@firstofone}{%
    \scr@ifundefinedorrelax{dhr@\label@desc@prefix\label@base.dohook.#2#1}{%
      \@firstofone
    }{%
      \@gobble
    }%
  }{%
    \protected@edef\@currentlabel{\DoHook{#2}}%
    \label@sanitize
    \Hy@MakeCurrentHref{\label@desc@prefix\label@base.dohook.#2#1}%
    \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
    \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
    \label{\label@desc@prefix\label@base.dohook.#2#1}%
    \expandafter\gdef
    \csname dhr@\label@desc@prefix\label@base.dohook.#2#1\endcsname{#3}%
  }%
}  
\DeclareSpecialMarkup{\DoHook}{\mbox{\texttt{#1}}}{%
  \par
  \leftskip\z@
  \BeginIndex{DoHook}{#1}%
  \LabelDoHook{#1}%
  \scr@ifundefinedorrelax{r@scrbase.cmd.ExecuteDoHook}{%
    \textMacro{ExecuteDoHook}%
  }{%
    \begingroup
      \let\Macro\textMacro
      \DescRef{scrbase.cmd.ExecuteDoHook}%
    \endgroup
  }%
  \PParameter{#1}%
}
\DeclareRobustCommand*{\PName}[1]{\texttt{\textit{#1}}}
\DeclareRobustCommand*{\PValue}[1]{\texttt{#1}}
\DeclareRobustCommand*{\Parameter}[1]{%
  \maybelinebreak\texttt{\{}\PName{#1}\texttt{\}}}
\DeclareRobustCommand*{\OParameter}[1]{%
  \maybelinebreak\texttt{[%]
  }\PName{#1}\texttt{%[
    ]}}
\DeclareRobustCommand*{\AParameter}[1]{%
  \maybelinebreak\texttt{(%)
  }\PName{#1}\texttt{%(
    )}}
\DeclareRobustCommand*{\PParameter}[1]{\maybelinebreak\texttt{\{#1\}}}
\DeclareRobustCommand*{\POParameter}[1]{\maybelinebreak\texttt{[#1]}}
\newcommand\label@sanitize{%
  \renewcommand*{\"}[1]{##1e}%
  \renewcommand*{\IeC}[1]{\expandafter\@gobble\string##1}%
  \renewcommand*{\textup}[1]{##1}%
  \renewcommand*{\PName}[1]{/##1/}%
}
\newcommand*{\label@desc@prefix}{desc:}
\newcommand*{\label@suffix}{}
\newcommand*{\labelsuffix}[1][]{% Werden Dinge mehrfach dokumentiert benötigen
                                % sie ein zusätzliches Unterscheidungsmerkmal
                                % beim gesetzten Label.
  \IfArgIsEmpty{#1}{\let\label@suffix\@empty}{\edef\label@suffix{.#1}}%
}
%    \end{macrocode}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
%
% \begin{macro}{\EMail}
%   An email adress.
%    \begin{macrocode}
\DeclareRobustCommand*{\EMail}[1]{\textless #1\textgreater}
%    \end{macrocode}
% \end{macro}
% \begin{macro}{\TextEMail}
%   EMail address at the text.
%    \begin{macrocode}
\DeclareRobustCommand*{\TextEMail}[1]{{\small\EMail{#1}}}
%    \end{macrocode}
% \end{macro}
%
% Setup fonts for table and figure captions:
%    \begin{macrocode}
\setkomafont{caption}{\normalcolor\small}
%    \end{macrocode}
%
%
% \section{Footnotes}
%
% \begin{macro}{\thempfootnote}
%    \begin{macrocode}
\renewcommand*{\thempfootnote}{\textit{\@arabic{\c@mpfootnote}}}
%    \end{macrocode}
% \end{macro}
%
% \section{Math}
%
% I will not use real math. But there will be some »pseudo math code«. So I
% need some macros for this.
%
% \begin{macro}{\Var}
%   Variables (in real math simply |$a$| will be |\Var{a}| in my math:
%    \begin{macrocode}
\newcommand*{\Var}[1]{\ensuremath{\textit{#1}}}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\Unit}
%   The unit of a length.
%    \begin{macrocode}
\newcommand*{\Unit}[1]{\,\ifmmode \textrm{#1}\else #1\fi}
%    \end{macrocode}
% \end{macro}
%
% Wie allow page breaks at display math.
%    \begin{macrocode}
\allowdisplaybreaks[1]
%    \end{macrocode}
%
%
% \section{Acronyms}
%
% \begin{macro}{\Script}
% \begin{macro}{\ScriptII}
%    \begin{macrocode}
\DeclareRobustCommand{\Script}{\Package{Script}}
\DeclareRobustCommand{\ScriptII}{\Package{Script-2}}
%    \end{macrocode}
% \end{macro}
% \end{macro}
%
% \begin{macro}{\eTeX}
% \changes{v1.25}{2021/02/16}{workaround for (temporary) changes in
%   \textsf{hyperref}}
% This may already be defined.
%    \begin{macrocode}
\providecommand*{\eTeX}{\ensuremath{\varepsilon}-\TeX}
\AtBeginDocument{%
  \@ifundefined{textepsilon}{%
    \@ifundefined{pdfstringdef}{}{%
      \pdfstringdef{\textepsilon}{\ifHy@unicode\83\265\else e\fi}%
    }%%
  }{}%
}
\providecommand*{\NTS}{%
  \leavevmode\hbox{$\cal N\kern-0.35em\lower0.5ex\hbox{$\cal T$}%
  \kern-0.2emS$}}
%    \end{macrocode}
% \end{macro}
%
%
% \section{Identification}
%
% \begin{macro}{\LabelBase}
% \begin{macro}{\labelbase}
% \changes{v1.22b}{2019/11/18}{\cs{ifstr} umbenannt in \cs{Ifstr}}%^^A
%    \begin{macrocode}
\newcommand*{\labelbase}[1]{%
  \Ifstr{\label@base@sec}{unknown}{}{%
    \labelofbase[sec]{\label@base@sec.next}%
    \gdef\label@base@sec{}%
  }%
  \renewcommand*{\label@base}{#1}%
  \label{cha:#1}%
}
%    \end{macrocode}
% \begin{macro}{\label@base}
% \begin{macro}{\label@base.sec}
%    \begin{macrocode}
\newcommand*{\label@base}{unknown}
\newcommand*{\label@base@sec}{}
%    \end{macrocode}
% \end{macro}
% \end{macro}
% \end{macro}
% \begin{macro}{\labelofbase}
% Sets a label depending on \cs{label@base}. First optional argument is the
% label prefix, second is the the label postfix.
%    \begin{macrocode}
\newcommand*{\labelofbase}[2][lab]{%
  \label{#1:\label@base.#2}%
}
%    \end{macrocode}
% \begin{macro}{\prefix@ref}
% Internal command to set a \cs{ref}, \cs{pageref}, or \cs{autoref} to an
% label with prefix. Use it, e.g., like
% |\label@base@ref{\autoref}{sec}{maincls.cmd.foo}|.
%    \begin{macrocode}
\newcommand*{\prefix@ref}[3]{%
  #1{#2:#3}%
}
%    \end{macrocode}
% \end{macro}
% \begin{macro}{\seclabel}
% Sets a label of type section.
%    \begin{macrocode}
\newcommand*{\seclabel}[1]{%
  \ifx\label@base@sec\@empty\else
    \labelofbase[sec]{\label@base@sec.next}%
  \fi
  \xdef\label@base@sec{#1}%
  \labelofbase[sec]{#1}%
}
%    \end{macrocode}
% \end{macro}
% \begin{macro}{\xmpllabel}
% \begin{macro}{\Refxmpl}
% \begin{macro}{\PageRefxmpl}
% Sets a label of type example.
%    \begin{macrocode}
\newcommand*{\xmpllabel}[1]{%
  \labelofbase[xmpl]{#1}%
}
\newcommand*{\Refxmpl}{%
  \kernel@ifstar {\prefix@ref{\autoref*}{xmpl}}%
                 {\prefix@ref{\autoref}{xmpl}}%
}
\newcommand*{\PageRefxmpl}{%
  \kernel@ifstar {\prefix@ref{\autopageref*}{xmpl}}%
                 {\prefix@ref{\autopageref}{xmpl}}%
}
%    \end{macrocode}
% \end{macro}
% \end{macro}
% \end{macro}
% User command to get the current label base.
%    \begin{macrocode}
\newcommand*{\LabelBase}{\@nameuse{label@base}} 
%    \end{macrocode}
% \end{macro}
%
% \section{Special Environments}
%
% \begin{environment}{Declaration}
%   Declaration of macros, environments, options, lengths, counters, pseudo
%   length, variables etc.\footnote{TODO: Redefining most declaration commands
%     to also write labels.}
%    \begin{macrocode}
\colorlet{Declaration}{PaleTurquoise}
\newsavebox\Declaration@Box
\newcommand*{\Declaration@Width}{\linewidth}
\newcommand*{\Declaration@LeftIndent}{-2\fboxsep}
\newcommand*{\Declaration@UseBox}[1]{%
  \colorbox{Declaration}{\usebox\Declaration@Box}%
}
\newenvironment{Declaration}[1][2]{%
  \def\Declare@Lines{#1\baselineskip}%
  % Als erstes wird eine neue Index-Gruppe begonnen. Dagegen darf die
  % vorherige Index-Gruppe hier nicht automatisch geschlossen werden, weil
  % beispielsweise ein Abschnitt oder ein Kapitel ebenfalls eine Index-Gruppe
  % sein könnte (aber nicht muss).
  \BeginIndexGroup
  % Die Absatzformatierung anpassen. Eigentlich hier noch nicht notwendig,
  % schadet aber auch nichts.
  \parindent\z@
  \parfillskip\@flushglue
  \parskip\z@
  % \Macro, \Environment, etc. so umdefinieren, dass sie passend für die
  % Umgebung formatiert werden und auch gleich Label und Index-Einträge
  % erzeugt werden.
  \scr@Desc@let\Macro
  \scr@Desc@let\Option
  \scr@Desc@let\KOption
  \scr@Desc@let\OptionValue
  \scr@Desc@let\OptionVName
  \scr@Desc@let\Variable
  \scr@Desc@let\Environment
  \let\endEnvironment\endDescEnvironment
  \scr@Desc@let\Counter
  \scr@Desc@let\Length
  \scr@Desc@let\PageStyle
  \scr@Desc@let\PLength
  \scr@Desc@let\FontElement
  \scr@Desc@let\FloatStyle
  \scr@Desc@let\DoHook
  % Todo: Replace the following by the correct definitions:
  \let\XMacro\textMacro
  \let\XEnvironment\textEnvironment
  \let\XOption\textOption
  \let\XOptionValue\textOptionValue
  \newenvironment{Body}{% Umgebung für den (vertikalen) Inhalt einer Umgebung
    \\
    \setlength{\leftskip}{1em}%
    \minipage{\dimexpr\linewidth-\leftskip}%
      \raggedright
      \newcommand*{\BodyDots}{%
        \par
        \hskip-\leftskip
        \raisebox{0pt}[1.1\ht\strutbox][.5\dp\strutbox]{$\vdots$}%
        \par
      }%
  }{%
      \par
    \endminipage
    \\
  }%
  % Todo: Behandlung für Optionen, Längen, Zähler, Font-Elemente, Seitenstile,
  %       etc.
  % Maybe: Vielleicht wäre es besser, die \X…-Definitionen von hier direkt zur
  %        Definition der entsprechenden Elemente zu verlagern und sie \D… zu
  %        nennen. Das wird dann eventuell übersichtlicher als alles hier zu
  %        machen. Hier gäbe es dann nur noch für jedes Element genau ein
  %        \let\…\D….
  % Jetzt wird der ganze Inhalt der Umgebung linksbündig in eine Box gepackt
  \begin{lrbox}{\Declaration@Box}%
    \minipage{\Declaration@Width}%
    \raggedright
    \parskip\baselineskip
    \small
    \addtolength{\parskip}{-\baselineskip}%
    \catcode`\^^M=9 % ignore line ends
}{%
    \par
    \endminipage
  \end{lrbox}
  \vskip 1\baselineskip \@plus .75\baselineskip \@minus .25\baselineskip
  % Hier darf ein Seitenumbruch ohne vertikalen Ausgleich erfolgen, wenn nicht
  % mindestens für die Deklaration und einige Zeilen Platz ist.
  \vskip \dimexpr\ht\Declaration@Box+\dp\Declaration@Box+\Declare@Lines\relax
  \penalty-\@medpenalty
  \vskip -\dimexpr\ht\Declaration@Box+\dp\Declaration@Box+\Declare@Lines\relax
  \begingroup% Dann wird die erzeugte Box farbig hinterlegt leicht im linken
             % Rand ausgegeben.
    \parfillskip\@flushglue
    \parindent\z@
    \leavevmode
    \hspace*{\Declaration@LeftIndent}%
    \Declaration@UseBox{\Declaration@Box}%
    \par\nobreak\vskip\fboxsep
  \endgroup\nobreak
  % Der nachfolgende Text soll wie bei einer Überschrift behandelt werden.
  \aftergroup\@afterindentfalse\aftergroup\@afterheading
}
%    \end{macrocode}
% \begin{macro}{\scr@Desc@let}
% Redefine the internal command of a robust command.
%    \begin{macrocode}
\newcommand*{\scr@Desc@let}[1]{%
  \expandafter\def
  \csname \expandafter\@gobble\string #1 \expandafter\endcsname\expandafter{%
    \csname Desc\expandafter\@gobble\string #1\endcsname}%
}
%    \end{macrocode}
% \end{macro}
% \end{environment}
%
% \begin{environment}{Example}
% \changes{v1.15a}{2019/10/17}{Space removed}%
% This environment is used for all examples at the \KOMAScript{} guide.
%    \begin{macrocode}
\newenvironment{Example}{%
  \lstset{belowskip=0pt plus 1pt minus .5pt}%
  \labeling{{\usekomafont{disposition}\GuideExample:}}
  \item[{\usekomafont{disposition}\GuideExample:}]%
}{%
  \endlabeling
}
%    \end{macrocode}
% \end{environment}
% \begin{macro}{\ExampleEndFix}
% \changes{v1.18}{2019/10/25}{New}%^^A
% If an example is at the end of a description and before a new description
% the vertical spacing is suboptimal. Sorry, but this cannot be fixed
% automatically currently. But here is a manual fix:
%    \begin{macrocode}
\newcommand*{\ExampleEndFix}{\vskip -1\ht\strutbox plus .75\strutbox}
%    \end{macrocode}
% \end{macro}
%
% \begin{environment}{ShowOutput}
%   This environment is used for the output of examples. It shows the middle
%   part of a page\footnote{TODO: optional arguments for printing a top or
%     bottom part of a page}. It uses |\scalebox| so you should never use a
%   DVI preview or a raw DVI printing.
%    \begin{macrocode}
\newsavebox\ShowOutputBox
\newenvironment{ShowOutput}[1][0pt]{\par
  \begin{lrbox}{\ShowOutputBox}%
    \minipage{.9\linewidth}%
      \vspace*{\baselineskip}\vspace{-#1}%
}{%
    \endminipage
  \end{lrbox}%
  \setlength{\unitlength}{1pt}%
  \setlength{\@tempdima}{\ht\ShowOutputBox}%
  \addtolength{\@tempdima}{\dp\ShowOutputBox}%
  \setlength{\@tempdima}{.75\@tempdima}%
  \edef\MidY{\strip@pt\@tempdima}%
  \addtolength{\@tempdima}{5pt}%
  \edef\HighY{\strip@pt\@tempdima}%
  \addtolength{\@tempdima}{-10pt}%
  \edef\LowY{\strip@pt\@tempdima}%
  \addtolength{\@tempdima}{5pt}%
  \setlength{\@tempdima}{.9\linewidth}\edef\QuadIV{\strip@pt\@tempdima}%
  \setlength{\@tempdima}{.675\linewidth}\edef\QuadIII{\strip@pt\@tempdima}%
  \setlength{\@tempdima}{.45\linewidth}\edef\QuadII{\strip@pt\@tempdima}%
  \setlength{\@tempdima}{.225\linewidth}\edef\QuadI{\strip@pt\@tempdima}%
  \centering
  \begin{picture}(\QuadIV,\MidY)
     \qbezier(0,\MidY)(\QuadI,\HighY)(\QuadII,\MidY)%
     \qbezier(\QuadII,\MidY)(\QuadIII,\LowY)(\QuadIV,\MidY)
     \put(0,0){\makebox(\QuadIV,\MidY)[c]{%
         \scalebox{.75}{\usebox{\ShowOutputBox}}%
       }%
     }%
     \put(0,-5){\line(0,1){\HighY}}%
     \put(\QuadIV,-5){\line(0,1){\HighY}}%
     \qbezier(0,-5)(\QuadI,0)(\QuadII,-5)%
     \qbezier(\QuadII,-5)(\QuadIII,-10)(\QuadIV,-5)
  \end{picture}\par  
  \vspace{1ex plus 1ex minus .5ex}%
}
%    \end{macrocode}
% \end{environment}
%
% \begin{environment}{Explain}
%   Some parts of the documentation are importing for understanding
%   \KOMAScript{} but not important for using \KOMAScript.
%    \begin{macrocode}
\newenvironment{Explain}{%
  \par\sffamily\ignorespaces
}{%
  \par
}
%    \end{macrocode}
% \end{environment}
%
%
% \subsection{Used by Jens-Uwe only}
%
% There are some example visualizations used only by Jens-Uwe.\footnote{TODO:
%   All these should be merged with \texttt{ShowOutputBox}.}
%
% \begin{environment}{XmpTopPage}
%   Output of the top of a page.
%    \begin{macrocode}
\newenvironment{XmpTopPage}
 {%
   \begin{center}
     \iffree{\setlength{\unitlength}{1mm}}{\setlength{\unitlength}{.833mm}}%
     \begin{picture}(100,39)
       \thinlines
       \qbezier(0,5)(25,7)(50,5)\qbezier(50,5)(75,3)(100,5)
       \put(0,5){\line(0,1){34}}
       \thicklines
       \put(100,5){\line(0,1){34}}\put(0,39){\line(1,0){100}}
       \footnotesize
 }{%
     \end{picture}
   \end{center}\vspace{-1.5\baselineskip}%
}
%    \end{macrocode}
% \end{environment}
%
% \begin{environment}{XmpBotPage}
%   Output of the bottom of a page.
%    \begin{macrocode}
\newenvironment{XmpBotPage}
 {\begin{center}
     \iffree{\setlength{\unitlength}{1mm}}{\setlength{\unitlength}{.833mm}}%
     \begin{picture}(100,40)%
       \thinlines
       \qbezier(0,38)(25,40)(50,38)\qbezier(50,38)(75,36)(100,38)
       \put(0,5){\line(0,1){33}}
       \thicklines
       \put(100,5){\line(0,1){33}}\put(0,5){\line(1,0){100}}
       \footnotesize
}{%
  \end{picture}\end{center}\vspace{-1.5\baselineskip}%
}
%    \end{macrocode}
% \end{environment}
%
% \begin{macro}{\XmpSetText}
%   Output some text at \texttt{XmpTopPage} or \texttt{XmpBotPage}.
%    \begin{macrocode}
\newcommand{\XmpSetText}[2][\XmpText]{%
        \put(#2){\makebox(0,0)[tl]{\parbox{70\unitlength}{\parfillskip=0pt 
              #1}}}}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\XmpMarginNote}
%   Output a margin note at \texttt{XmpTopPage} or \texttt{XmpBotPage}.
%    \begin{macrocode}
\newcommand{\XmpMarginNote}[1]{%
        \put(#1){\makebox(0,5)[tl]{\scriptsize\XmpMarginTextA}}
        \put(#1){\makebox(0,5)[bl]{\scriptsize\XmpMarginTextB}}}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\XmpRule}
%   Output a horizonal rule at a \texttt{XmpTopPage} or \texttt{XmpBotPage}.
%    \begin{macrocode}
\newcommand{\XmpRule}[2]{\put(#1){\line(1,0){#2}}}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\XmpHeading}
%   Output a head line at a \texttt{XmpTopPage} or \texttt{XmpBotPage}.
%    \begin{macrocode}
\newcommand{\XmpHeading}[3][\KOMAScript\hfill 3]{%
        \put(#2){\makebox(#3,0)[l]{#1}}}
%    \end{macrocode}
% \end{macro}
%
%
% \section{Margin Notes}
%
% \begin{macro}{\OnlyAt}
%   Some things are not available at every \KOMAScript{} class. To show the
%   differences we'll put a margin note. If more than one class or package
%   should be noted, |\and| will be used to separate them.
%    \begin{macrocode}
\newcommand*{\OnlyAt}[1]{%
  \marginline{\def\and{,\\}\footnotesize #1\par}%
}
%    \end{macrocode}
% \end{macro}
%
%
% \section{Change Log}
%
% Not all features are part of every old \KOMAScript{} release. New features
% will be marked and these marks are referenced at a kind of index.
%
% \begin{macro}{\ChangedAt}
% \changes{v1.22b}{2019/11/18}{\cs{ifstr} umbenannt in \cs{Ifstr}}%^^A
%   Set the margin note and write an entry to the change log.\footnote{TODO:
%     Don't use the glossary, use a file by my own.}
%    \begin{macrocode}
\providecommand*{\ChangedAt}[3][]{%
  \Ifstr{#1}{}{%
    \marginnote{\tiny\fbox{\strut#2}}%
  }{%
    \def\reserved@a##1/##2\@nil{%
      \count@\year
      \advance\count@-##1\relax
      \multiply\count@ by 12\relax
      \advance\count@\month
      \advance\count@-##2\relax
    }\reserved@a#1\@nil
    \ifnum\count@<13
      \marginnote{\tiny Beta-Feature}%
    \else
      \marginnote{\tiny\fbox{\strut #2}}%
    \fi
  }%
  \begingroup
    \let\@tempa\@empty
    \Ifstr{#2}{v2.9i}{\def\@tempa{v2.90i=}}{}%
    \Ifstr{#2}{v2.9t}{\def\@tempa{v2.90t=}}{}%
    \let\and\ignorespaces
    \def\Package##1{%
      \glossary{##1=\string\Package{##1}>\@tempa#2|indexrm}%
      \glossary{\@tempa#2>##1=\string\Package{##1}|indexrm}%
      \ignorespaces
    }%
    \def\Class##1{%
      \glossary{##1=\string\Class{##1}>\@tempa#2|indexrm}%
      \glossary{\@tempa#2>##1=\string\Class{##1}|indexrm}%
      \ignorespaces
    }%
    \ignorespaces #3%
  \endgroup
}
%    \end{macrocode}
% \end{macro}
% 
% While I currently use the glossary, we have to make it:
%    \begin{macrocode}
\makeglossary
%    \end{macrocode}
%
% \begin{macro}{\printchangelog}
%   We don't want to generate the change log only. We also have to print it.
%    \begin{macrocode}
\newcommand*{\printchangelog}{\@input@{\jobname.gls}}
%    \end{macrocode}
% \end{macro}
% \begin{environment}{thechangelog}
%   And this will be used at the \texttt{gls} file. The change log index will
%   always generate an entry to the table of contents.
%    \begin{macrocode}
\newenvironment{thechangelog}{%
  \setchapterpreamble{\GuideChangeLogPreamble\par\bigskip}%
  \addchap{\changelogname}%
  \markboth{\changelogname}{\changelogname}%
  \setlength{\parindent}{0pt}%
  \setlength{\parskip}{0pt plus .3pt}%
  \setlength{\parfillskip}{0pt plus 1fil}%
  \def\and{,\ }%
  \let\item\@idxitem
}{%
  \clearpage
}
%    \end{macrocode}
%   The macros |\GuideChangeLogPreamble| and |\changelogname| have to be
%   defined at the language file.
% \end{environment}
%
%
% \section{Special Tabulars and Tables}
%
% I need some special tabulars and tables. These are used for describing
% single topics.
%
% \begin{environment}{desctabular}
%   \changes{v1.13d}{2019/02/01}{\cs{addlinespace} removed from end code}^^A
%   This kind of tabluar has primary one column but uses two columns in
%   declaration. It's something like a \texttt{description} environment with
%   line break after the item. I've used a \texttt{tabular} at the definition
%   because of full compatibitlity with \texttt{desctable}.
% \begin{length}{\descwidth}
%   I need a length of local usage. I could have used |\@tempdima| or
%   another local length from kernel. But I've decided not to try to find a
%   unused length at \texttt{tabular} environment.
% \begin{length}{\descdefaultindent}
%   And I need a length of global usage.
%    \begin{macrocode}
\newlength{\descwidth}
\newlength{\descdefaultindent}\setlength{\descdefaultindent}{2em}
%    \end{macrocode}
% \end{length}
% \end{length}
%   The definition of \texttt{desctabular} is very simple, because the main
%   work will be done by a \emph{worker} macro that will be defined later.
%    \begin{macrocode}
\newenvironment{desctabular}[1][c]{%
  \start@desctab{\descdefaultindent}%
  \tabular[#1]{lp{\descwidth}}
  \toprule
}{%
  \bottomrule
  \endtabular
}
%    \end{macrocode}
% \end{environment}
%
% \begin{environment}{desctable}
%   \textbf{Deprecated! Use \texttt{desclist} instead of!}
%   This is almost the same like \texttt{desctabular} but it uses a longtable
%   to allow page breaks.
%    \begin{macrocode}
\newenvironment{desctable}[1][\descdefaultindent]{%
  \ClassError{scrguide}{deprecated environment}{%
    please replace desctable by desclist}%
  \onelinecaptionsfalse
  \start@desctab{#1}%
  \newcommand{\Endfirsthead}{\toprule\endfirsthead}%
  \newcommand{\Endhead}{\midrule\endhead}%
  \newcommand*{\standardfoot}{%
    \addlinespace[-.5\normalbaselineskip]\midrule
    \multicolumn{2}{r@{}}{\dots}\\
    \endfoot
    \addlinespace[-.5\normalbaselineskip]\bottomrule
    \endlastfoot
  }%
  \longtable{lp{\descwidth}}%
}{%
  \endlongtable
}
%    \end{macrocode}
% \end{environment}
%
% \begin{macro}{\start@desctab}
% \changes{v1.7c}{2013/10/13}{\cs{leavevmode}\cs{ignorespaces} added to
%   \cs{nentry}}%^^A
% \changes{v1.16}{2019/10/23}{links for plengths added}%^^A
% \changes{v1.17}{2019/10/23}{links for variables added}%^^A
% This is the \emph{worker} macro of \texttt{desctable} and
% \texttt{desctabular}. It does the complete calculations and definition of
% the entry (something like |\item|) commands.
%    \begin{macrocode}
\newcommand*{\start@desctab}[1]{%
  \setlength{\descwidth}{\linewidth}%
  \addtolength{\descwidth}{-4\tabcolsep}%
  \addtolength{\descwidth}{-#1}%
  \setlength{\labelwidth}{\linewidth}%
  \addtolength{\labelwidth}{-2\tabcolsep}%
  \newcommand{\nentry}[2]{%
    \multicolumn{2}{p{\labelwidth}}{\raggedright##1}\tabularnewline*%
    \hspace*{#1} & \leavevmode\ignorespaces ##2\tabularnewline%
  }%
  \newcommand{\entry}[2]{\nentry{##1}{##2}[.5\baselineskip]}%
  \newcommand*{\pentry}[1]{%
    \entry{%
      \scr@ifundefinedorrelax{r@\label@desc@prefix\LabelBase.plength.##1}{%
        \ClassWarning{scrguide}{%
          Reference `\label@desc@prefix\LabelBase.plength.##1' undefined}%
        \PLength{##1}%
      }{%
        \DescRef{\LabelBase.plength.##1}%
      }%
      \IndexPLength[indexmain]{##1}}}%
  \newcommand*{\pventry}[1]{\entry{\PValue{##1}}}%
  \newcommand*{\mentry}[1]{\entry{\Macro{##1}}}%
  \newcommand*{\ventry}[1]{%
    \entry{%
      \scr@ifundefinedorrelax{r@\label@desc@prefix\LabelBase.variable.##1}{%
        \ClassWarning{scrguide}{%
          Reference `\label@desc@prefix\LabelBase.variable.##1 undefined}%
        \Variable{##1}%
      }{%
        \DescRef{\LabelBase.variable.##1}%
      }%
      \IndexVariable[indexmain]{##1}%
    }%
  }%
  \newcommand*{\feentry}[1]{%
    \entry{%
      \scr@ifundefinedorrelax{r@\label@desc@prefix\LabelBase.fontelement.##1}{%
        \ClassWarning{scrguide}{%
          Reference `\label@desc@prefix\LabelBase.fontelement.##1' undefined}%
        \FontElement{##1}%
      }{%
        \DescRef{\LabelBase.fontelement.##1}%
      }%
      \IndexFontElement[indexmain]{##1}}%
  }%
  \newcommand*{\oentry}[1]{%
    \entry{\Option{##1}\IndexOption[indexmain]{##1}}%
  }%
}
% \end{macro}
%
% \begin{environment}{desclist}
%   This is similar to \texttt{desctable} but it has been build by single
%   tabulars instead of longtable.
% \begin{macro}{\desccaptionb@xfirst}
% \begin{macro}{\desccaptionb@xother}
% \begin{macro}{\descfootb@x}
% \begin{macro}{\descentryb@x}
% \begin{macro}{\desccaptiob@xnext}
%    \begin{macrocode}
\newsavebox\desccaptionb@xfirst
\newsavebox\desccaptionb@xother
\newsavebox\descfootb@x
\newsavebox\descentryb@x
\newif\ifdescpage@dd
\newcommand*{\desccaptionb@xnext}{}
\newcommand*{\abovecaptionskipcorrection}{}
\newenvironment{desclist}[1][\descdefaultindent]{%
  \par
  \setparsizes{\z@}{\z@}{\z@\@plus 1fil}\selectfont%
  \vskip\intextsep
  \start@desctab{#1}%
  \csname @desclistinithook\endcsname
  \def\@captype{table}%
  \newcommand{\desccaption}{\@dblarg{\@desccaption}}%
  \newcommand{\@desccaption}[3][]{%
    \setbox\desccaptionb@xfirst\vbox{%
      \tabular{p{\labelwidth}}%
        \multicolumn{1}{@{}p{\dimexpr\labelwidth+2\tabcolsep}@{}}{%
          \captionaboveof{table}[##1]{##2\unskip\strut}%
        }\tabularnewline[%
        \dimexpr \abovecaptionskip-\normalbaselineskip\relax
%        \dimexpr \abovecaptionskip-\abovecaptionskipcorrection\relax
        ]
        \toprule\tabularnewline
      \endtabular
      \vskip -\baselineskip
    }%
    \let\abovecaptionskipcorrection\@empty
    \setbox\desccaptionb@xother\vbox{%
      \tabular{p{\labelwidth}}
      \multicolumn{1}{@{}p{\dimexpr\labelwidth+2\tabcolsep}@{}}{%
        \@@makecaption\@firstofone{\fnum@table}{\ignorespaces ##3}%
      }\tabularnewline[-\normalbaselineskip]
      \addlinespace[\abovecaptionskip]
        \toprule\tabularnewline
      \endtabular
      \vskip -\baselineskip
    }%
    \let\desccaptionb@xnext\desccaptionb@xfirst
  }%
  \setbox\descfootb@x\vbox{%
    \tabular{p{\labelwidth}}%
      \addlinespace[-.5\normalbaselineskip]\midrule
      \addlinespace[-\dp\strutbox]
      \raggedleft\dots\hspace*{-\tabcolsep}\tabularnewline
    \endtabular
  }%
  \newcommand*{\entryskip}[1][]{%
    \ifx\relax##1\relax\else\vskip##1\relax\fi
  }%
  \renewcommand{\nentry}[2]{%
    \typeout{TRACE: Generate entry}%
    \setbox\descentryb@x\vbox{%
      \ifx\desccaptionb@xnext\desccaptionb@xfirst\copy\desccaptionb@xnext\fi
      \makebox[\linewidth][l]{\begin{tabular}{lp{\descwidth}}%
        \multicolumn{2}{p{\labelwidth}}{\raggedright##1}\tabularnewline
        \hspace*{#1} & ##2\tabularnewline
      \end{tabular}}%
    }%
    \typeout{TRACE: entry done}%
    \begingroup
      \dimen@ \ht\descentryb@x
      \advance \dimen@ \dp\descentryb@x
      \ifdim \ht\descfootb@x>\ht\strutbox
        \advance \dimen@ \ht\descfootb@x
      \else
        \advance \dimen@ \ht\strutbox
      \fi
      \ifdim \dp\descfootb@x>\dp\strutbox
        \advance \dimen@ \dp\descfootb@x
      \else
        \advance \dimen@ \dp\strutbox
      \fi
      \advance \dimen@ \baselineskip
      \dimen@ii \pagegoal \advance \dimen@ii -\pagetotal
      \typeout{TRACE: \the\dimen@>\the\dimen@ii\space (footbox
        ht=\the\ht\descfootb@x, dp=\the\dp\descfootb@x; strutbox
        ht=\the\ht\strutbox, dp=\the\dp\strutbox)?}%
      \ifdim \dimen@>\dimen@ii
        \typeout{TRACE: Break table \thetable}%
        \ifx\desccaptionb@xnext\@empty
          \csname @desclistentryhook\endcsname
          {\copy\descfootb@x}%
        \fi
        \newpage
        \ifx\desccaptionb@xnext\@empty
          \typeout{TRACE: switch page}%
          \ifdescpage@dd
            \aftergroup\descpage@ddfalse
            \expandafter\descpage@ddfalse
          \else
            \aftergroup\descpage@ddtrue
            \expandafter\descpage@ddtrue
          \fi
          \csname @desclistentryhook\endcsname
          {\copy\desccaptionb@xother}%
         \fi
      \fi
    \endgroup
    \ifx\desccaptionb@xnext\desccaptionb@xfirst
      \Ifthispageodd{\descpage@ddtrue}{\descpage@ddfalse}%
    \fi
    \csname @desclistentryhook\endcsname
    {\copy\descentryb@x}%
    \let\desccaptionb@xnext\@empty
   \entryskip
  }%
}{%
  \vskip -.5\baselineskip
  \setbox\descfootb@x\vbox{%
    \tabular{p{\labelwidth}}
    \bottomrule\tabularnewline
    \endtabular
  }%
  \csname @desclistentryhook\endcsname
  {\copy\descfootb@x}%
  \par\nobreak
  \vskip -\baselineskip \vskip \intextsep
}
%    \end{macrocode}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{environment}
%
%
% \section{Listings}
%
% Setup listings:
%    \begin{macrocode}
\lstset{%
  basicstyle=\ttfamily,%
  columns=fullflexible,keepspaces,%
  aboveskip=.4\baselineskip,%
  belowskip=\dp\strutbox plus 1pt minus .5pt,%
  literate=%
    {Ö}{{\"O}}1
    {Ä}{{\"A}}1
    {Ü}{{\"U}}1
    {ß}{{\ss}}1
    {ü}{{\"u}}1
    {ä}{{\"a}}1
    {ö}{{\"o}}1
    {»}{{\guillemetright}}1
    {«}{{\guillemetleft}}1
}%
\lstdefinestyle{code}{%
  language=[LaTeX]TeX,%
  moretexcs={%
    @auxout,@currext,@dottedtocline,@empty,@float,
    @gobble,@gobbletwo,
    @hangfrom,@ifpackagelater,
    @ifundefined,@mkboth,
    @rightmark,@secondoftwo,
    @tempskipa,@tempdima,@tempswafalse,@tempswatrue,
    @undefined,
    AtBeginDocument,AtEndDocument, appendix, ClassWarningNoLine,CurrentOption,
    color,colorbox,
    DeclareOption,DeclareRobustCommand,dimexpr,end@float,ExecuteOptions,
    gluexpr,
    if@filesw,if@tempswa,if@twoside,includegraphics,
    labelformat,
    MessageBreak,
    numexpr,
    onehalfspacing,
    PackageError,PackageInfo,PackageWarning,PassOptionsToPackage,
    ProcessOptions,protected@edef,protected@write,
    ProvidesFile,ProvidesPackage,
    providecommand,
    RequirePackage,RequirePackageWithOptions,setkey,setlength,
    SelectInputMappings,setkeys,
    textsuperscript}%
}%
\lstdefinestyle{output}{%
  breaklines,prebreak=\mbox{$\hookleftarrow$}%
}%
\lstdefinestyle{KOMA}{%
  style=code,%
  moretexcs={%
    @addtoplength,@setplength,@newplength, activateareas,
    addchap,addrentry,Address,addcontentslinetoeachtocfile,
    addxcontentslinetoeachtocfile,addsec,
    addtoeachtocfile,
    addtokomafont,addtolengthplength,addtoplength,addtoreffields,addtotoclist,
    addxcontentsline,
    adrchar,adrentry,
    AddLayersAtBeginOfPageStyle,AddLayersToPageStyle,
    AddtoDoHook,AddtoOneTimeDoHook,
    AfterBibliographyPreamble,AfterCalculatingTypearea,
    AfterFile,AfterPackage,AfterStartingTOC,AfterTOCHead,
    appendixmore,appendixname,areaset,autodot,automark,AtAddToTocList,
    AtBeginLetter,At@startsection,
    Before@sect,Before@ssect,
    BeforeFamilyProcessOptions,
    BeforeClosingMainAux,BeforePackage,BeforeStartingTOC,
    bib@beginhook,bib@endhook,
    blinddocument,blindtext,Blinddocument,Blindtext,
    cc,captionabove,captionaboveof,captionbelow,captionbelowof,captionformat,
    captionof,cefoot,cfoot,chapapp, chapappifchapterprefix,
    chapterheadstartvskip,chapterheadmidvskip,chapterheadendvskip,
    chapter,chapterlinesformat,chapterlineswithprefixformat,
    chapterformat,chaptermarkformat,chapternumdepth,chaptertocdepth,
    chapterpagestyle,chead,
    Clause,
    cleardoubleevenemptypage,cleardoubleoddpage,
    clearscrheadfoot,closing,cofoot,Comment,
    CloneTOCEntryStyle,
    DeclareNewJuraEnvironment,
    DeclareLayer,DeclareNewLayer,DeclareNewPageStyleByLayers,
    DeclarePageStyleByLayers,
    DeclareTOCStyleEntry,DeclareTOCEntryStyle,
    DeclareNewNoteColumn,DeclareNewPageStyleAlias,
    DeclareNewTOC,DeclareSectionCommand,DeclareNewSectionCommand,
    RedeclareSectionCommand,ProvideSectionCommand,
    dedication,defcaptionname,deffootnote,deffootnotemark,
    DefineFamily,DefineFamilyKey,DefineFamilyMember,
    DefineTOCEntryOption,DefineTOCEntryBooleanOption,
    DefineTOCEntryCommandOption,DefintTOCEntryIfOption,
    DefineTOCEntryLengthOption,DefineTOCEntryNumberOption,
    DestroyLayer,defpagestyle,deftripstyle,
    dictum,dictumauthorformat,dictumrule,dictumwidth,doforeachtocfile,
    ellipsispar,
    encl,ExecuteDoHook,extratitle,FamilyBoolKey,FamilyExecuteOptions,
    FamilyKeyState,FamilyKeyStateUnknown,FamilyKeyStateProcessed,
    FamilyKeyStateUnknownValue,FamilyKeyStateNeedValue,
    FamilyNumericalKey,%
    FamilyOption,FamilyOptions,FamilyProcessOptions,FamilySetBool,
    FamilyStringKey,FamilyUnknownKeyValue,
    figureformat,figurename,firstfoot,firsthead,FirstName,footfont,footref,
    ForDoHook,ForEachLayerOfPageStyle,
    FreeI,FreeII,FreeIII,FreeIV,
    GenericMarkFormat,
    headfont,headmark,
    Ifattoclist,Ifkomavar,Ifkomavarempty,Ifstr,Ifstrstart,Ifthispageodd,
    Ifundefinedorrelax,IfUsePrefixLine,
    ifundefinedorrelax,
    ifattoclist,ifoot,ihead,ifkomavarempty,ifstr,ifthispageodd,
    IfActiveMkBoth,InputAddressFile,
    KOMAoption,KOMAoptions,KOMAScript, l@addto@macro,
    LastName,layerwidth,layerheight,lefoot,lefttopmark,leftbotmark,
    leftfirstmark,lehead,LetterOptionNeedsPapersize,
    LenToUnit,
    lipsum,listoffigures,
    listoftables,listoftoc,LoadLetterOption,lofoot,lohead,lowertitleback,
    MakeMarkcase,makenote,maketitle,manualmark,marginline,markleft,markdouble,
    minisec,
    multfootsep,multiplefootnoteseparator,
    Name,nameday,newbibstyle,newcaptionname,newkomavar,nexthead,
    ofoot,ohead,opening,othersectionlevelsformat,
    p@section,pagemark,paragraphformat,subparagraphformat,
    paragraphnumdepth,paragraphtocdepth,
    subparagraphnumdepth,subparagraphtocdepth,
    parellipsis,parformat,parname,parshortname,
    part,partformat,partlineswithprefixformat,
    partname,partnumdepth,partpagestyle,partnumdepth,
    partheadstartvskip,partheadmidvskip,partheadendvskip,
    pnumfont,
    PreventPackageFromLoading,providecaptionname,publishers,ps,
    putLL,putLR,putUL,putUR,putC,
    raggedcaption,raggedchapter,raggedfootnote,raggedsection,raggedpart,
    raggedsignature,
    recalctypearea,
    refL,refS,refN,refoot,
    refParagraph,refParagraphN,refPar,refParL,refParS,refParN,
    refSentence,refSentenceL,refSentenceS,refSentenceN,rehead,
    RelaxFamilyKey,
    removereffields,renewcaptionname,
    RedeclarePageStyleAlias,RedeclareTOCStyleEntry,
    ReplaceInput,ReplacePackage,ResetPreventPackageFromLoading,
    rightbotmark,righttopmark,rightfirstmark,
    rohead,
    sectionformat,subsectionformat,subsubsectionformat,
    sectionnumdepth,sectiontocdepth,
    subsectionnumdepth,subsectiontocdepth,
    subsubsectionnumdepth,subsubsectiontocdepth,
    sectionmarkformat,sectioncatchphraseformat,sectionlinesformat,
    Sentence,sentencename,sentenceshortname,
    setbibpreamble,setcapindent,setcapwidth,setcaptionalignment,
    setchapterpreamble,setfootbotline,setfootsepline,setfootwidth,
    setheadsepline,setheadtopline,setheadwidth,setindexpreamble,setkomafont,
    setkomavar,setlengthtoplength,setparsizes,setpartpreamble,
    setplength,setuptoc,
    showfields,showenvelope,showISOenvelope,showUScommercial,showUScheck,
    SplitDoHook,
    storeareas,StorePreventPackageFromLoading,
    subject,SubClause,subsectionmarkformat,subtitle,syncwithnotecolumn,
    tableformat,tablename,tableofcontents,textsubscript,thechapter,thefigure,
    thefootnotemark,thepar,thepart,thesection,thesentence,thesubsection,
    thesubsubsection,theparagraph,thesubparagraph,
    thetable,thistime,
    titlehead,tocbasic@extend@babel,TOCclone,todaysname,typearea,%
    TOCEntryStyleInitCode,TOCEntryStyleStartInitCode,TOCLineLeaderFill,
    UnPreventPackageFromLoading,unitfactor,
    unsettoc,usekomafont,useplength,usekomavar,uppertitleback% 
  }%
}%
\lstnewenvironment{lstoutput}[1][]{%
  \lstset{style=output,basicstyle=\ttfamily\codesize,#1}%
}{}%
\lstnewenvironment{lstcode}[1][]{%
  \lstset{style=KOMA,basicstyle=\ttfamily\codesize,#1}%
}{}%
\newcommand*{\lstinputcode}[1][]{%
  \lstinputlisting[style=KOMA,basicstyle=\ttfamily\codesize,#1]%
}
\newcommand*{\codesize}{\small}
%    \end{macrocode}
%
%
% \section{hyperref Addons}
%
% \begin{macro}{\KOMAScript}
% \begin{macro}{\Guide@KOMAScript}
%   We need some additions to \textsf{hyperref}.
%    \begin{macrocode}
\newcommand*{\Guide@KOMAScript}{}
\expandafter\let\csname Guide@KOMAScript\expandafter\endcsname\csname
KOMAScript \endcsname
\DeclareRobustCommand*{\KOMAScript}{%
  \texorpdfstring{\Guide@KOMAScript}{KOMA-Script}%
}
%    \end{macrocode}
% \end{macro}
% \end{macro}
%
% \begin{macro}{\url@}
% \changes{v1.9b}{2015/09/30}{\cs{GuideCTANserver} not needed and removed}%^^A
% \changes{v1.22a}{2019/11/18}{https instead of http}%^^A
% Redefine to make \texttt{CTAN://} be an alias for
% \texttt{https://mirror.ctan.org/}.
%    \begin{macrocode}
\def\url@#1{\expandafter\url@@#1\@nil}
\def\url@@#1://#2\@nil{%
  \def\@tempa{#1}\def\@tempb{CTAN}\ifx\@tempa\@tempb
    \hyper@linkurl{\Hurl{#1://#2}}{https://mirror.ctan.org/#2}%
  \else
    \hyper@linkurl{\Hurl{#1://#2}}{#1://#2}%
  \fi
}
%    \end{macrocode}
% \end{macro}
%
% We have to setup \textsf{hyperref}:
%    \begin{macrocode}
\AtBeginDocument{%
  \iffree{%
    \hypersetup{%
      plainpages=false,
      pdftitle={\GuideTitle},
      pdfauthor={Markus Kohm},
      pdfsubject={\GuideSubject},
      pdfkeywords={\KOMAScript, scrbook, scrreprt, scrartcl, 
        typearea, scrlfile, scrlayer, scrlayer-scrpage, scrlayer-notecolumn,
        scrletter, scrlttr2, scraddr, scrtime, scrdate, scrwfile},
      pdfcreator={\KOMAScript, hyperref}
    }%
  }{}%
}
%    \end{macrocode}
%
% \begin{macro}{\autopageref}
%   This is something like |\autoref| but with page reference. A simple
%   definition would use |\hyperref| and |\pageref*|. But I want to allow to
%   decide if the reference is the page or the label. So this definition is
%   more like |\autoref|.
%    \begin{macrocode}
\DeclareRobustCommand{\autopageref}[1]{%
  \expandafter\auto@setpageref\csname r@#1\endcsname
  \@secondoffive
  {#1}%
}
%    \end{macrocode}
% \begin{macro}{\auto@setpageref}
%   This is the \emph{worker} macro. It checks for the label and trys to set
%   either a reference to the page or a reference to the label.
%    \begin{macrocode}
\newcommand*{\auto@setpageref}[3]{%
  \@safe@activestrue
  \ifx#1\relax
    \protect\G@refundefinedtrue
    \nfss@text{\reset@font\bfseries ??}%
    \@latex@warning{%
      Reference `#3' on page \thepage \space undefined%
    }%
  \else
    \def\@currentHtag{\pageautorefname~}%
    \if@pagereftolabel
      \hyper@@link
      {\expandafter\@fifthoffive#1}%
      {\expandafter\@fourthoffive#1\@empty\@empty}%
      {\@currentHtag\expandafter#2#1\@empty\@empty\null}%
    \else
      \hyper@@link
      {\expandafter\@fifthoffive#1}%
      {page.\expandafter\@secondoffive#1\@empty\@empty}%
      {\@currentHtag\expandafter#2#1\@empty\@empty\null}%
    \fi
  \fi
  \@safe@activesfalse
}
%    \end{macrocode}
% \end{macro}
% \end{macro}
%
%
% \section{Entries to \contentsname, \figurelistname, etc.}
%
% We have large page numbers, so better setup the needed width. And we like
% other dot seperation.
%    \begin{macrocode}
\RedeclareSectionCommand[%
  tocdynnumwidth,%
  tocbreakafternumber=true,%
  tocentrynumberformat=\partnumberwithprefix,%
  tocpagenumberformat=\@firstofone
]{part}%
\newcommand*{\partnumberwithprefix}[1]{\let\autodot:\partname~#1}%
\RedeclareSectionCommand[%
  tocnumwidth=21pt,%
  tocpagenumberformat=\@firstofone,%
  tocraggedentrytext=true%
]{chapter}%
\RedeclareSectionCommand[tocindent=21pt,tocnumwidth=34pt]{section}%
\RedeclareSectionCommand[tocindent=55pt,tocnumwidth=36pt]{subsection}%
\DeclareTOCStyleEntries[dynnumwidth]{default}{figure,table}%
\renewcommand*{\@pnumwidth}{1.8em}% 1.67
\renewcommand*\@tocrmarg {2.70em}% 2.55em
\renewcommand*\@dotsep{2.5}%
%    \end{macrocode}
%
% \section{Part}
%
% We want another vertical spacing at part headings.
%    \begin{macrocode}
\renewcommand*{\partheadstartvskip}{\vspace*{.1\textheight}}
\renewcommand*{\partheadmidvskip}{\par\nobreak\vspace{.5\baselineskip}}
\renewcommand*{\partpagestyle}{empty}
%    \end{macrocode}
%
%
% \section{Logos}
%
% I don't want to use package \textsf{hologo} for only one logo:
% \changes{v1.28}{2022/07/17}{\cs{LuaTeX} and \cs{LuaLaTeX} added}
%    \begin{macrocode}
\DeclareRobustCommand{\XeTeX}{%
  X\kern-.125em\lower.5ex\hbox{\reflectbox{E}}\kern-.10em\TeX
}%
\DeclareRobustCommand{\XeLaTeX}{%
  X\kern-.125em\lower.5ex\hbox{\reflectbox{E}}\kern-.10em\LaTeX
}%
\DeclareRobustCommand{\LuaTeX}{%
  Lua\TeX
}
\DeclareRobustCommand{\LuaLaTeX}{%
  Lua\LaTeX
}
%    \end{macrocode}
%
% \section{Appendix}
%
% \begin{macro}{\appendix}
% Use only first if used more than once. With this, every appendix file may
% start with |\appendix|.
%    \begin{macrocode}
\g@addto@macro\appendix{\global\let\appendix\relax}
%    \end{macrocode}
% \end{macro}
%
% \section{Bibliography}
%
% \begin{macro}{\BibTeX}
%   I use the same hack like the \LaTeX{} team uses at \texttt{ltlogos.dtx}
%   for |\LaTeX|:
%    \begin{macrocode}
\DeclareRobustCommand{\BibTeX}{B\kern-.05em%
  \hbox{$\m@th$%
    \csname S@\f@size\endcsname \fontsize\sf@size\z@
    \math@fontsfalse\selectfont
    I\kern-.025emB}%
  \kern-.08em%
  \-\TeX%
}
%    \end{macrocode}
% \end{macro}
%
% Use of a preamble and sime other usefull changes.
%    \begin{macrocode}
\ifusebabelbib
  \AtBeginDocument{%
    \setbibpreamble{\GuideBibPreamble\bigskip}%
    \bibliographystyle{babalpha-fl}%
    \nocite{homepage}% added because of l3build
    \renewcommand*{\@openbib@code}{%
      \setlength{\parsep}{0pt}%
      \renewcommand*{\btxauthorcolon}[1]{:\par\nobreak}%
      \renewcommand*{\btxurlfont}{\par\nobreak\url}%
      \raggedright
    }%
  }
%    \end{macrocode}
%
% The generated argument of thebibliography is to short:
%    \begin{macrocode}
  \newcommand*{\OrigTheBibliography}{}
  \let\OrigTheBibliography\thebibliography
  \renewcommand*{\thebibliography}[1]{%
    \selectbiblanguage{\languagename}%
    \OrigTheBibliography{XXXX99}%
  }
\else
  \AtBeginDocument{%
    \defbibnote{bibpreamble}{\GuideBibPreamble}%
  }%
  \addbibresource{guide.bib}
\fi
%    \end{macrocode}
%
%
% \section{Index}
%
% This is realy tricky. The index depends on an external perl script, which
% splits the one index into several indexes. But first of all, we need to make
% the raw index.
%    \begin{macrocode}
\makeindex
%    \end{macrocode}
%
% Use of a preamble:
%    \begin{macrocode}
\AtBeginDocument{\setindexpreamble{\GuideIndexPreamble\bigskip}}
%    \end{macrocode}
%
% \begin{macro}{\ifusemultiindex}
%   Now let's decide wether to use one index or to use a multi part index.
%    \begin{macrocode}
\newif\ifusemultiindex
\IfFileExists{\jobname-gen.ind}{\usemultiindextrue}{\usemultiindexfalse}
\ifusemultiindex
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\printmultiindex}
%   \changes{v1.11a}{2016/11/02}{index label generation delayed}^^A
%   Print one part of the multi part index.
%    \begin{macrocode}
  \newcommand*{\printmultiindex}[3][]{%
    \begingroup
      \def\indexname{#2}%
%    \end{macrocode}
% \begin{macro}{\CrossIndex}
%   Produce a reference from one index to another. The macro |\UseIndex| tells
%   the external splitt processor the index to be used for that entry. The
%   first argument is the entry to the index. The second is the shortcut of
%   the source index and the third is the shortcut of the index with the main
%   entry for the entry from first argument. This macro should be used at the
%   preamble of one part of the multi part index only. Because of this, it's
%   defined here only.
%    \begin{macrocode}
      \newcommand*{\CrossIndex}[3]{%
        \Index{##1=\UseIndex{##2}\protect##1>##3=\UseIndex{##2}\SeeSign
          \protect##3}%
      }%
%    \end{macrocode}
% \end{macro}
%    \begin{macrocode}
      \ifx\relax#1\relax\let\index@preamble=\relax
      \else\def\index@preamble{#1}%
      \fi
      \def\index@setlabel{\label{idx:#3}}%
      \@input@{\jobname-#3.ind}%
    \endgroup
  }
%    \end{macrocode}
% \begin{environment}{theindex}
%   I don't want every part of the index starting a new page. So I'll use the
%   \textsf{multicol} package to generate the two columns instead of
%   |\twocolumn|.
%    \begin{macrocode}
  \renewenvironment{theindex}{%
    \setchapterpreamble{\index@preamble}
    \begin{multicols}{2}[\idx@heading\vspace{-1\baselineskip}][.2\textheight]%
    \parindent\z@
    \setlength{\parskip}{\z@ \@plus .3\p@}%
    \setlength{\parfillskip}{\z@ \@plus 1fil}%
    \let\item\@idxitem
    \small\csname index@setlabel\endcsname
  }{%
    \end{multicols}%
  }
%    \end{macrocode}
% \end{environment}
% \end{macro}
%
% \begin{macro}{\printindex}
%   Print the full index.
%    \begin{macrocode}
  \renewcommand*{\printindex}{%
    \setchapterpreamble{\index@preamble}%
    \addchap{\indexname}%
    \let\index@preamble=\relax
    \renewcommand*\idx@heading{%
      \addsec{\indexname}%
      \ifx\index@preamble\relax
      \else\index@preamble\let\index@preamble=\relax\fi
    }%
    \printmultiindex{\GuidegenIndex}{gen}%
    \printmultiindex[%
      \CrossIndex{\GuideMacro}{gen}{\GuidecmdIndexShort}%
      \CrossIndex{\GuideEnvironment}{gen}{\GuidecmdIndexShort}%
      \CrossIndex{\GuideCounter}{gen}{\GuidecmdIndexShort}%
      \CrossIndex{\GuideLength}{gen}{\GuidecmdIndexShort}%
    ]{\GuidecmdIndex}{cmd}%
    \printmultiindex[%
      \CrossIndex{\GuideLength}{gen}{\GuidelenIndexShort}%
      \CrossIndex{\GuidePLength}{gen}{\GuidelenIndexShort}%
      \CrossIndex{\GuideCounter}{gen}{\GuidelenIndexShort}%
    ]{\GuidelenIndex}{len}%
    \printmultiindex[%
      \CrossIndex{\GuideFontElement}{gen}{\GuideelmIndexShort}%
    ]{\GuideelmIndex}{elm}%
    \printmultiindex[%
      \CrossIndex{\GuideFile}{gen}{\GuidefilIndexShort}%
      \CrossIndex{\GuidePackage}{gen}{\GuidefilIndexShort}%
      \CrossIndex{\GuideClass}{gen}{\GuidefilIndexShort}%
    ]{\GuidefilIndex}{fil}%
    \printmultiindex[%
      \CrossIndex{\GuideOption}{gen}{\GuideoptIndexShort}%
    ]{\GuideoptIndex}{opt}%
    \printmultiindex[%
      \CrossIndex{\GuideHook}{gen}{\GuidehokIndexShort}%
    ]{\GuidehokIndex}{hok}
  }
\fi
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\indexsection}
%   Heading of the next section (e.g. the next character) at an index.
%    \begin{macrocode}
\newcommand*{\indexsection}[1]{%
  \ifx\empty#1\empty\else
  \hspace{0pt plus 2fil}{{\usekomafont{disposition} #1}}\hspace{0pt plus
    1fil}\nopagebreak
  \fi
}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\indexdelim}
% \begin{macro}{\indexdelimi}
% \begin{macro}{\indexdelimii}
%   The delimiter after the index topic but before the page number. There are
%   three index levels, so there are three delimiters too.
%    \begin{macrocode}
\newcommand*{\indexdelim}{\ \hspace{0pt plus 1fil}\penalty0\null\nobreak
  \dotfill~}
\newcommand*{\indexdelimi}{~\dotfill\penalty0\ }
\newcommand*{\indexdelimii}{~\dotfill\penalty0\ }
%    \end{macrocode}
% \end{macro}
% \end{macro}
%
% \begin{macro}{\UseIndex}
%   This macro does nothing but shows the external index split processor the
%   destination index.
%    \begin{macrocode}
\DeclareRobustCommand*{\UseIndex}[1]{\ignorespaces}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\SeeSign}
%   The symbol used to sign a reference at an index.
%    \begin{macrocode}
\DeclareRobustCommand*{\SeeSign}{\ensuremath{\protect\rightarrow}~}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\AddSeeIndex}
%   Add »\emph{see another index}« entry to an index. First argument is an
%   index entry to the index with shortcut of second argument. The third
%   argument is the name of another index given also by the shortcut at the
%   fourth argument.
%    \begin{macrocode}
\newcommand*{\AddSeeIndex}[4]{%
  \ifusemultiindex
    \Index[seeindex{#4}]{#1=\UseIndex{#2}#1>#3=\UseIndex{#2}\SeeSign#3}%
  \fi
}
%    \end{macrocode}
% \begin{macro}{\seeindex}
%   Page number style of references to another index. This eats the page
%   number of the index entry and set's a page number reference to the label
%   of the other index. Don't use this on your own. This is need by
%   |\AddSeeIndex|.
%    \begin{macrocode}
\newcommand*{\seeindex}[2]{\pageref{idx:#1}}
%    \end{macrocode}
% \end{macro}
% \end{macro}
%
% \begin{macro}{\IndexSeeAt}
%   A more general version of |\AddSeeIndex|. First (optional) argument is a
%   entry note (e.g. |\GuidePagestyle|). This is only used if option
%   \texttt{moreindexnotes} was set.  Second argument is the entry. Third is
%   the shortcut of the source index, the index the entry should be set.
%   Fourth is the shortcut of the destination index, the index the entry
%   should reference. Fifth is the name of that index. Sixth is the output
%   command (e.g. |\Macro|) for the entry.
%    \begin{macrocode}
\newcommand*{\IndexSeeAt}[6][\relax]{%
  \ifusemultiindex
    \if@moreindexnotes
      \edef\@tempa{idx@f@\string#1.\string#2.#3.#4}%
    \else
      \edef\@tempa{idx@f@\string#2.#3.#4}%
    \fi
    \expandafter\ifx\csname \@tempa\endcsname\relax
      \expandafter\gdef\csname \@tempa\endcsname{}%
      \begingroup
        \@tempswatrue
        \if@moreindexnotes
          \ifx\relax#1\relax\else\@tempswafalse
            \Index[seeindex{#4}]{%
              #2 (#1)=\UseIndex{#3}#6{#2} (\protect#1)>%
              #5=\UseIndex{#3}\SeeSign\protect#5}%
          \fi
        \fi
        \if@tempswa
          \Index[seeindex{#4}]{%
            #2=\UseIndex{#3}#6{#2}>#5=\UseIndex{#3}\SeeSign\protect#5}%
        \fi
      \endgroup
    \fi
  \fi
}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\Index}
%   Primary index command. First (optional) argument is the page number style
%   of the entry. Second argument is the entry. The page number style should
%   be either \texttt{indexother} or \texttt{indexmain}. Default is
%   \texttt{indexother}.
%    \begin{macrocode}
\newcommand*{\Index}[2][indexother]{\index{#2|#1}}
%    \end{macrocode}
% \end{macro}
%
% \begin{macro}{\BeginIndex}
% \begin{macro}{\EndIndex}
% \changes{v1.22b}{2019/11/18}{\cs{ifstr} umbenannt in \cs{Ifstr}}%^^A
%   Its also usefull to define index range entries. These have three
%   arguments. First (optiona) argument is the page number style. Default of
%   this parameter is \texttt{indexmain}. See |\Index| for more information
%   about this parameter. The second parameter is the kind of index
%   entry. This is not the same like the name or shortcut of an index! See
%   |\Define|\dots|Index| for more information about the kind of an index
%   entry. The third argument is the index entry.
%    \begin{macrocode}
\newif\ifnolabel
\def\nolabelfalse{\global\let\ifnolabel\iffalse}%
\def\nolabeltrue{\global\let\ifnolabel\iftrue}%
\newcommand*{\BeginIndex}[3][indexmain]{%
  \expandafter\ifx\csname Index#2\endcsname\relax
    \GenericError{(scrguide)\@spaces\@spaces\@spaces\@spaces}{%
      Document scrguide Error: \string\BeginIndex\space with unknown
      index%
    }{Check the \string\BeginIndex-command or add a new index type
      ``#2''.}{%
      See scrguide.cls for more information.}%
  \else
    \csname Index#2\endcsname[(%)
      #1]{#3}%
    \push@IndexStack{{\do{#1}{#2}{#3}}}%
  \fi
  % \ifnolabel\nolabelfalse\else
  %   \ifx\relax#2\relax\else
  %       \begingroup
  %       \def\SplitIndexValue##1~=##2~=##3\@nil{%
  %         ##1\expandafter\ifx\expandafter\relax##2\relax\else.##2\fi
  %       }%
  %       \let\PName\@gobble
  %       \let\PValue\@firstofone
  %       \let\ensuremath\@firstofone
  %       \let\textit\@firstofone
  %       \def~{\string~}%
  %       \lowercase{\def\@tempa{#2}}%
  %       \edef\@tempa{\label@base.\@tempa.\SplitIndexValue#3~=~=\@nil}%
  %       \pdfstringdef\@tempb{\@tempa}%
  %       \expandafter\ifx\csname \@tempb\endcsname\relax
  %         \expandafter\xdef\csname \@tempb\endcsname{\the\inputlineno}%
  %         \xdef\@currentHref{\@tempb}%
  %         \ClassInfo{scrguide}{Anchor: `\@currentHref'}%
  %         \Hy@raisedlink{\hyper@anchorstart{\@currentHref}\hyper@anchorend}%
  %         \label{desc:\@tempa}%
  %       \else
  %         \ClassWarning{scrguide}{%
  %           Label \@tempa\space already defined at \csname
  %           \@tempb\endcsname,\MessageBreak
  %           ignored}%
  %       \fi
  %     \endgroup
  %   \fi
  % \fi
  \penalty\@M\ignorespaces
}
\newlength\PreserveSkip
\newcount\PreservePenalty
\newcommand*{\CloseIndex}[3][indexmain]{%
  \PreservePenalty\lastpenalty
  \ifvmode\PreserveSkip\lastskip\else\unskip\PreserveSkip\z@\fi
  \ifdim \PreserveSkip>\z@
    \vskip -\PreserveSkip
  \fi
  \penalty\@M
  \expandafter\ifx\csname Index#2\endcsname\relax
    \GenericError{(scrguide)\@spaces\@spaces\@spaces\@spaces}{%
      Document scrguide Error: \string\EndIndex\space with unknown
      index%
    }{Check the \string\BeginIndex-command or add a new index type
      ``#2''.}{%
      See scrguide.cls for more information.}%
  \else
    \csname Index#2\endcsname[%(
      )#1]{#3}%
  \fi
  \ifdim\PreserveSkip >\z@
    \vskip\PreserveSkip
  \fi
  \penalty\PreservePenalty
}
\newcommand*{\EndIndex}[3][indexmain]{%
  \begingroup
    \@tempswatrue
    \def\do##1##2##3{%
      \Ifstr{#1}{##1}{%
        \Ifstr{#2}{##2}{%
          \Ifstr{\detokenize{#3}}{\detokenize{##3}}{}{\@tempswafalse}%
        }{\@tempswafalse}%
      }{\@tempswafalse}%
      \if@tempswa
      \else
        \ClassError{scrguide}{Index stack error}{%
          Should pop \string\do{#1}{#2}{\detokenize{#3}}\MessageBreak
          but have \string\do{##1}{##2}{\detokenize{##3}}%
        }%
        \push@IndexStack{{\do{##1}{##2}{##3}}}%
      \fi
    }%
    \def\StopIndexGroup{%
      \ClassError{scrguide}{Index stack error}{%
        Should pop \string\do{#1}{#2}{\detokenize{#3}}\MessageBreak
        but have \string\StopIndexGroup
      }%
      \push@IndexStack{\StopIndexGroup}%
    }%
    \expandafter\pop@IndexStack\@IndexStack\@nil
  \endgroup
  \CloseIndex[#1]{#2}{#3}%
}
%    \end{macrocode}
% \end{macro}
% \end{macro}
\let\@IndexStack\@empty
\newcommand*{\push@IndexStack}[1]{% Einen Eintrag auf den Index Stapel werfen.
  \xdef\@IndexStack{\unexpanded{#1}\unexpanded\expandafter{\@IndexStack}}%
}
\newcommand*{\BeginIndexGroup}{% Am Anfang einer Gruppe auf den Stack die
                               % Index-Gruppen-Trennmarke packen.
  \push@IndexStack{\StopIndexGroup}%
}
\newcommand*{\EndIndexGroup}{% Den Stapel bis zur nächsten Stop-Marke
                             % verarbeiten.
  \ifx\@IndexStack\@empty
    \ClassError{scrguide}{cannot end index group}{%
      You've told me to end the current index group,\MessageBreak
      but there is no more index group open%
    }%
  \else
    \begingroup
      \let\StopIndexGroup\@tempswafalse
      \@tempswatrue%(
      \def\do##1##2##3{%
        \CloseIndex[##1]{##2}{##3}%
      }%
      \@whilesw \if@tempswa \fi {%
        \expandafter\pop@IndexStack\@IndexStack\@nil
      }%
    \endgroup
  \fi
}
\def\pop@IndexStack#1#2\@nil{% Ein Argument von Stapel holen und verarbeiten.
  \gdef\@IndexStack{#2}#1%
}
\newcommand*\CleanUpIndexStack{%
  \ifx\@IndexStack\@empty\else
    \ClassError{scrguide}{Index stack error}{%
      The index stack should be empty\MessageBreak
      but it still contains: \MessageBreak
      \expandafter\detokenize\expandafter{\@IndexStack}%
    }%
    \begingroup
      \let\StopIndexGroup\relax
      \def\do##1##2##3{%
        \CloseIndex[##1]{##2}{##3}%
      }%
      \@IndexStack
      \global\let\@IndexStack\@empty
    \endgroup
  \fi
}
\AtEndDocument{\CleanUpIndexStack}
\l@preto@macro\chapter{\CleanUpIndexStack}
\l@preto@macro\part{\CleanUpIndexStack}
%
% Now we have to define different kinds of index entries. We have entries that
% will be added to only one index. We have entries that will be added to one
% index with reference to that index at another index. And there are even
% entries that will be added to one index with reference to that index from
% another index and from the main index.
% \begin{macro}{\DefineSingleIndex}
%   \changes{v1.22}{2019/11/14}{support \cs{PName} in second argument}%^^A
%   This defines a single index entry, e.g. of commands. A macro will be
%   defined that addes the entry only to one index. First (optional)
%   agrument is a not, which shows the kind of entry (e.g. |\GuideMacro|). The
%   second is the macro postfix (e.g. \texttt{Cmd} would define |\IndexCmd|).
%   The third is the shortcut of the index to bee used
%   (e.g. \texttt{cmd}). The fourth argument is the command to be used to
%   output (format) the index entries (e.g. |\Macro|).
%    \begin{macrocode}
\newcommand*{\DefineSingleIndex}[4][\relax]{%
  \ifx\relax#1\relax
    \expandafter\newcommand\expandafter*%
    \csname Index#2\endcsname[2][indexother]{%
      \begingroup
        \let\PName\@firstofone
        \protected@edef\reserved@a{%
          \unexpanded{\endgroup\Index[##1]}%
          {##2\unexpanded{=\UseIndex{#3}#4{##2}}}%
        }%
      \reserved@a
    }%
  \else
    \expandafter\newcommand\expandafter*%
    \csname Index#2\endcsname[2][indexother]{%
      \begingroup
        \let\PName\@firstofone
        \protected@edef\reserved@a{%
          \unexpanded{\endgroup\Index[##1]}%
          {##2 \unexpanded{(#1)=\UseIndex{#3}#4{##2} (\protect #1)}}%
        }%
      \reserved@a
    }%
  \fi
}
%    \end{macrocode}
% \end{macro}
% \begin{macro}{\DefineDoubleIndex}
%   This defines a double index entry, e.g. of page styles. A macro will be
%   defined that adds the entry to an index and also adds a reference entry to
%   the main index. See |\DefineSingleIndex| for informations about the
%   parameters. If a note was given (first optional argument) it will be used
%   to make a top level entry to the main index with the corresponding
%   subentry.
%    \begin{macrocode}
\newcommand*{\DefineDoubleIndex}[4][\relax]{%
                                % #1 = optional entry note (\GuidePagestyle)
                                % #2 = index macro postfix (Pagestyle)
                                % #3 = see-from-index to be used (cmd)
                                % #4 = output command (\Macro)
  \ifx\relax#1\relax
    \expandafter\newcommand\expandafter*%
    \csname Index#2\endcsname[2][indexother]{%
      \Index[##1]{##2=\UseIndex{gen}#4{##2}}%
      \IndexSeeAt{##2}{#3}{gen}{\GuidegenIndex}{#4}%
    }%
  \else
    \expandafter\newcommand\expandafter*%
    \csname Index#2\endcsname[2][indexother]{%
      \Index[##1]{##2 (#1)=\UseIndex{gen}#4{##2} (\protect #1)}%
      \Index[##1]{\csname Guide#2IndexCategoryExpanded\endcsname=\UseIndex{gen}\expandafter\protect\csname Guide#2IndexCategory\endcsname>##2=\UseIndex{gen}#4{##2}}%
      \IndexSeeAt[#1]{##2}{#3}{gen}{\GuidegenIndex}{#4}%
    }%
  \fi
}
%    \end{macrocode}
% \end{macro}
% \begin{macro}{\DefineTripleIndex}
%   This defines a triple index entry, e.g. of lengths. A macro will be
%   defined that adds the entry to an index and also adds a reference entry to
%   another index and the main index. The first (optional) argument is a note
%   (e.g. (|\GuideLength|) that will be used to generate a top level index
%   entry to the main index. The second argument is the macro postfix
%   (e.g. \texttt{Length} to define |\IndexLength|). The third argument is the
%   shortcut of the primary index (e.g. \texttt{len}). The fourth argument is
%   the short name of that index (e.g. |\GuidelenIndexShort|). The fifth
%   argument is the shortcut of the index to put the reference into
%   (e.g. \texttt{cmd}). The sixth argument is the output command of the index
%   entry (e.g. |\Length|).
%    \begin{macrocode}
\newcommand*{\DefineTripleIndex}[6][\relax]{%
                                % #1 = optional entry note (\GuideLength)
                                % #2 = index macro postfix (Length)
                                % #3 = index to be used (len)
                                % #4 = index name (\GuidelenIndexShort)
                                % #5 = also-from-index to be used (cmd)
                                % #6 = output command (\Macro)
  \ifx\relax#1\relax
    \expandafter\newcommand\expandafter*%
    \csname Index#2\endcsname[2][indexother]{%
      \IndexSeeAt{##2}{gen}{#3}{#4}{#6}%
      \IndexSeeAt{##2}{#5}{#3}{#4}{#6}%
      \Index[##1]{##2=\UseIndex{#3}#6{##2}}%
      \IndexSeeAt{##2}{#3}{gen}{\GuidegenIndex}{#4}%
    }%
  \else
    \expandafter\newcommand\expandafter*%
    \csname Index#2\endcsname[2][indexother]{%
%      \IndexSeeAt[#1]{##2}{gen}{#3}{#4}{#6}%
%      \Index[##1]{#1=\UseIndex{gen}\protect#1>##2=\UseIndex{gen}#6{##2}}%
      \IndexSeeAt[#1]{##2}{#5}{#3}{#4}{#6}%
      \Index[##1]{##2 (#1)=\UseIndex{#3}#6{##2} (\protect #1)}%
    }%
  \fi
}
%    \end{macrocode}
% \end{macro}
%
% After this, let's define all used kinds of index entries:
%    \begin{macrocode}
\DefineSingleIndex{Cmd}{cmd}{\Macro}
\DefineDoubleIndex[\GuidePagestyle]{Pagestyle}{cmd}{\PValue}
\DefineDoubleIndex[\GuideFloatstyle]{Floatstyle}{cmd}{\PValue}
\DefineTripleIndex[\GuideCounter]{Counter}
  {len}{\GuidelenIndexShort}{cmd}{\Counter}
\DefineTripleIndex[\GuideLength]{Length}
  {len}{\GuidelenIndexShort}{cmd}{\Length}
\ifusemultiindex
  \DefineSingleIndex[\GuideEnvironment]{Env}{cmd}{\Environment}
  \DefineSingleIndex{Option}{opt}{\Option}
  \DefineSingleIndex[\GuidePackage]{Package}{fil}{\Package}
  \DefineSingleIndex[\GuideClass]{Class}{fil}{\Class}
  \DefineSingleIndex{File}{fil}{\File}
  \DefineSingleIndex[\GuideVariable]{Variable}{cmd}{\Variable}
  \DefineSingleIndex{FontElement}{elm}{\FontElement}
  \DefineSingleIndex{PLength}{len}{\PLength}
  \DefineSingleIndex{DoHook}{hok}{\DoHook}
\else
  \DefineDoubleIndex[\GuideEnvironment]{Env}{cmd}{\Environment}
  \DefineDoubleIndex{Option}{opt}{\Option}
  \DefineDoubleIndex[\GuidePackage]{Package}{fil}{\Package}
  \DefineDoubleIndex[\GuideClass]{Class}{fil}{\Class}
  \DefineDoubleIndex{File}{fil}{\File}
  \DefineDoubleIndex[\GuideVariable]{Variable}{cmd}{\Variable}
  \DefineDoubleIndex{FontElement}{elm}{\FontElement}
  \DefineDoubleIndex{PLength}{len}{\PLength}
  \DefineDoubleIndex{DoHook}{hok}{\DoHook}
\fi
%    \end{macrocode}
%
% \begin{macro}{\indexrm}
% \begin{macro}{\indexother}
% \begin{macro}{\indexit}
% \begin{macro}{\indexbf}
% \begin{macro}{\indexmain}
% \begin{macro}{\indexsl}
% \begin{macro}{\indexsf}
% \begin{macro}{\indexsc}
%   Some helpers to get page numbers with different fontification but hyper
%   links.
%    \begin{macrocode}
\newcommand*{\indexrm}[1]{\textrm{\hyperpage{#1}}}
\newcommand*{\indexother}{}\let\indexother\indexrm
\newcommand*{\indexit}[1]{\textit{\hyperpage{#1}}}
\newcommand*{\indexbf}[1]{\textbf{\hyperpage{#1}}}
\newcommand*{\indexmain}{}\let\indexmain\indexbf
\newcommand*{\indexsl}[1]{\textsl{\hyperpage{#1}}}
\newcommand*{\indexsf}[1]{\textsf{\hyperpage{#1}}}
\newcommand*{\indexsc}[1]{\textsc{\hyperpage{#1}}}
%    \end{macrocode}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
% \end{macro}
%
%
\endinput
%
%%% Local Variables: 
%%% mode: doctex
%%% coding: utf-8
%%% ispell-local-dictionary: "en_US"
%%% eval: (flyspell-mode 1)
%%% End: 
