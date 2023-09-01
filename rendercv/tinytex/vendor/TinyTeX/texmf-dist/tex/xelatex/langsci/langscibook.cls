%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%      
%%      File: langscibook.cls
%%    Author: Language Science Press (http://langsci-press.org)
%%      Date: 2023-02-08 14:00 CET
%%   Purpose: This file defines the basic document class
%%            for books published with Language Science Press.
%%  Language: LaTeX
%%  Copyright 2012- Language Science Press
%%  Licence: This work may be distributed and/or modified under the
%%  conditions of the LaTeX Project Public License, either version 1.3
%%  of this license or (at your option) any later version.
%%  The latest version of this license is in
%%    http://www.latex-project.org/lppl.txt
%%  and version 1.3 or later is part of all distributions of LaTeX
%%  version 2005/12/01 or later.
%%% This work has the LPPL maintenance status `maintained'.
%%% The Current Maintainer of this work is Sebastian Nordhoff.
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Structure of this file:
%   \- Early load packages
%   \- Default values of variables
%   \- Definition of conditionals
%   \- Option handling
%   \- Output variables
%   \- MAIN CLASS
%   \- General packages
%   \- Covers
%   \- Output types (book, draft, cover)
%   \- Page geometry
%   \- Fonts
%   \- Colors
%   \- Book cover
%   \- Series history
%   \- Imprint
%   \- Dedication
%   \- Header and footer
%   \- Sectioning
%   \- Epigrams
%   \- Footnotes
%   \- Quotes
%   \- Languages
%   \- Citations
%   \- Floats
%   \- Appendices
%   \- Indexes
%   \- Hyperref
%   \- Edited volumes (Collection)
%   \- Localisation
%   \- Miscellaneous
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{langscibook}[2023/02/08 Language Science Press]

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Early load packages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\RequirePackage[]{silence}
\WarningsOff[hyperref]
\WarningsOff[microtype]
\WarningFilter{latex}{Command \mark} %markboth/markright
\WarningFilter{scrbook}{\float@addtolist}
\WarningFilter{biblatex}{Macro 'date+extradate}
\WarningFilter{microtype}{Unknown slot}
\WarningFilter{scrbook}{package incompatibility}
\WarningFilter{todonotes}{The length}
\WarningFilter{biblatex}{'babel/polyglossia'}
\hbadness=99999 % get rid of underfull box warnings
\typeout{Warnings are disabled in langscibook.cls for underfull boxes, hyperref, microtype and scrbook package incompatibility, todonotes length and babel/polyglossia csquotes}
\usepackage{etoolbox}
\RequirePackage{xparse}
\usepackage{langsci-affiliations}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Default values
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{xspace}
\newcommand{\lsp}{Language Science Press\xspace}
\newcommand{\lsSeriesNumber}{??}
\newcommand{\lsSeriesText}{\color{red}{No series description provided}}
\newcommand{\lsISSN}{??}
\newcommand{\lsISSNprint}{??}
\newcommand{\lsISSNelectronic}{??}
\newcommand{\lsISBNdigital}{000-0-000000-00-0}
\newcommand{\lsISBNhardcover}{000-0-000000-00-0}
\newcommand{\lsISBNsoftcover}{000-0-000000-00-0}
\newcommand{\lsISBNsoftcoverus}{000-0-000000-00-0}
\newcommand{\lsBookDOI}{??}
\newcommand{\lsChapterDOI}{??}
\newcommand{\lsID}{000}
\newcommand{\lsURL}{redefine \ lsURL}
\newcommand{\lsSeries}{eotms}
\newcommand{\lsOutput}{book}
\newcommand{\lsBookLanguage}{english}
\newcommand{\lsFontsize}{11pt}
\newcommand{\lsChapterFooterSize}{\small} %footers in editedvolumes
\newcommand{\lsCopyright}{CC-BY}
\newcommand{\lsSpinewidth}{20mm}
\newcommand{\lsBiblatexBackend}{biber}
\newcommand{\logotext}{{\color{red}no logo}}
\newcommand{\lsYear}{\the\year}

\newcommand{\lsBackBody}{Set blurb on back with {\textbackslash}BackBody\{my blurb\}}
\newcommand{\lsBackTitle}{\@title}
\newcommand{\BackTitle}[1]{\renewcommand{\lsBackTitle}{#1}}
\newcommand{\BackBody}[1]{\renewcommand{\lsBackBody}{#1}}

\newcommand{\newlineCover}{\\}  % \newline only on cover
\newcommand{\newlineSpine}{\\}  % \newline only on spine
\newcommand{\newlineTOC}{\\}    % \newline only in TOC entry
\newcommand{\affiliation}[1]{}     % A dummy command to process the affiliation info.

\newcommand{\lsSpineTitle}{\@title}
\newcommand{\lsSpineAuthor}
  {%
    \ResolveAffiliations[output affiliation=false, 
                         output authors font=\lsSpineAuthorFont]{\@author}%
  }
\newcommand{\SpineTitle}[1]{\renewcommand{\lsSpineTitle}{#1}}
\newcommand{\SpineAuthor}[1]{\renewcommand{\lsSpineAuthor}{#1}}

% Default commands for loaded graphics
\newcommand{\includespinelogo}{~}
\newcommand{\includestoragelogo}{~}
\newcommand{\includepublisherlogo}{~}
\newcommand{\includechapterfooterlogo}{~}
\newcommand{\lsLicenseInformation}[1]{~}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Conditionals
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newbool{cover}
\newbool{resetcapitals}
\newbool{draft}
\newbool{openreview}
\newbool{babel}
\newbool{babelshorthands}
\newbool{multiauthors}
\newbool{showindex}
\newbool{biblatex}
    \booltrue{biblatex}
\newbool{newtxmath}
\newbool{minimal}
\newbool{collection}
\newbool{collectiontoclong}
\newbool{uniformtopskip}
\newbool{oldstylenumbers}
\newbool{tblseight}%for chinesefonts in tbls series page
\newbool{lsISBNTwoDigitAddon}
\newbool{lsFloatCounterWithoutChapter}
    \booltrue{lsFloatCounterWithoutChapter}
\newbool{lsImportPackagesWhenStandalone}
\newbool{infn}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Option handling
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\RequirePackage{kvoptions}

\DeclareStringOption{output}[book]
	\define@key{langscibook}{output}{%
		\renewcommand{\lsOutput}{#1}}
\DeclareStringOption{booklanguage}[english]
	\define@key{langscibook}{booklanguage}{%
		\renewcommand{\lsBookLanguage}{#1}}
\DeclareStringOption{copyright}[CC-BY]
	\define@key{langscibook}{copyright}{%
		\renewcommand{\lsCopyright}{#1}}
\DeclareStringOption{biblatexbackend}[biber]
	\define@key{langscibook}{biblatexbackend}{%
		\renewcommand{\lsBiblatexBackend}{#1}}
\DeclareStringOption{spinewidth}[20mm]
	\define@key{langscibook}{spinewidth}{%
		\renewcommand{\lsSpinewidth}{#1}}
\DeclareVoidOption{smallfont}{\renewcommand{\lsFontsize}{10pt}}
\DeclareVoidOption{decapbib}{
        \booltrue{resetcapitals}
% 	\lsResetCapitalstrue
	}
\DeclareVoidOption{draftmode}{% 'draftmode' instead of 'draft' due to undesirable side efects
	 \booltrue{draft}
	 \overfullrule=5pt
	 }	% to indicate overfull hboxes
\DeclareVoidOption{openreview}{
	\booltrue{openreview}
	\AtBeginDocument{\renewcommand{\lsISBNdigital}{000-0-000000-00-0}}
	}
\DeclareVoidOption{nobabel}{\boolfalse{babel}}
\DeclareVoidOption{babelshorthands}{\booltrue{babelshorthands}}
\DeclareVoidOption{multiauthors}{\booltrue{multiauthors}}
\DeclareVoidOption{showindex}{\booltrue{showindex}}
\DeclareVoidOption{biblatex}{\booltrue{biblatex}}
\DeclareVoidOption{nonewtxmath}{\boolfalse{newtxmath}}
\DeclareVoidOption{newtxmath}{\booltrue{newtxmath}}
\DeclareVoidOption{minimal}{\booltrue{minimal}}
\DeclareVoidOption{collection}{\booltrue{collection}}
\DeclareVoidOption{proofs}
  {
    \AtEndPreamble{\usepackage[switch, pagewise]{lineno}}
    \AtBeginDocument{\linenumbers}
  }
\DeclareVoidOption{collectiontoclong}
  {
	\booltrue{collection}
	\booltrue{collectiontoclong}
  }
\DeclareVoidOption{uniformtopskip}{\booltrue{uniformtopskip}}
\DeclareVoidOption{oldstylenumbers}{\booltrue{oldstylenumbers}}
\DeclareVoidOption{classicfloatnumbers}{\boolfalse{lsFloatCounterWithoutChapter}}

\DeclareVoidOption{chinesefont}{
  \AtEndPreamble{
	\newfontfamily\cn
	  [
	    Scale=MatchLowercase,
	    BoldFont=SourceHanSerif-Bold.otf
      ]
      {SourceHanSerif-Regular.otf}
    \AdditionalFontImprint{Source Han Serif ZH}
	\XeTeXlinebreaklocale 'zh'
	\XeTeXlinebreakskip = 0pt plus 1pt
  }
}

\DeclareVoidOption{japanesefont}{
  \AtEndPreamble{
	\newfontfamily\jpn
	  [
	    Scale=MatchLowercase,
	    BoldFont=SourceHanSerif-Bold.otf
      ]
      {SourceHanSerif-Regular.otf}
    \AdditionalFontImprint{Source Han Serif JA}
    \XeTeXlinebreaklocale 'ja'
  }
}

\DeclareVoidOption{koreanfont}{
  \AtEndPreamble{
	\newfontfamily\krn
	  [
	    Scale=MatchLowercase,
	    BoldFont=SourceHanSerif-Bold.otf
      ]
      {SourceHanSerif-Regular.otf}
    \AdditionalFontImprint{Source Han Serif KO}
    \XeTeXlinebreaklocale 'ko'
  }
}


\DeclareVoidOption{arabicfont}
  {
  \AtEndPreamble{
        \newfontfamily\arabicfont[Script=Arabic,ItalicFont=*,Scale=1.4]{ScheherazadeRegOT_Jazm.ttf}
	\AdditionalFontImprint{Arabtype}
	\usepackage{langsci-bidi}
%         \newcommand{\textarab}[1]{\RL{\arabicfont #1}} %has to be moved to localcommands
  }
}
\DeclareVoidOption{hebrewfont}
  {
	\newfontfamily\hebrewfont[Script=Hebrew,ItalicFont=*, Scale=0.9]{SBLHebrew.ttf}
% 	\newcommand{\texthebrew}[1]{{\hebrewfont #1}}
	\AdditionalFontImprint{SBLHebrew}
  }

\DeclareVoidOption{syriacfont}
  {
	\newfontfamily\syriacfont[Script=Syriac]{EstrangeloEdessa.ttf}
% 	\newcommand{\textsyriac}[1]{{\syriacfont #1}}
	\AdditionalFontImprint{Estrangelo Edessa}
  }

\DeclareVoidOption{tblseight}{\booltrue{tblseight}}
\DeclareVoidOption{infn}{\booltrue{infn}}

\ProcessKeyvalOptions*

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Output variables
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newbool{book}
\newbool{paper}
\newbool{guidelines}
\newbool{coverBODhc}
\newbool{coverBODsc}
\newbool{coverCS}

\newcommand{\lsOutputPaper}{paper}
\newcommand{\lsOutputBook}{book}
\newcommand{\lsOutputGuidelines}{guidelines}
\newcommand{\lsOutputCoverBODhc}{coverbodhc}
\newcommand{\lsOutputCoverBODsc}{coverbodsc}
\newcommand{\lsOutputCoverCS}{amazoncover}

\ifx\lsOutput\lsOutputPaper{\global\booltrue{paper}}\fi
\ifx\lsOutput\lsOutputBook{\global\booltrue{book}}\fi
\ifx\lsOutput\lsOutputGuidelines{\global\booltrue{guidelines}}\fi
\ifx\lsOutput\lsOutputCoverBODhc{\global\booltrue{coverBODhc}}\fi
\ifx\lsOutput\lsOutputCoverBODsc{\global\booltrue{coverBODsc}}\fi
\ifx\lsOutput\lsOutputCoverCS{\global\booltrue{coverCS}}\fi

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Class
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


\LoadClass[
    fontsize=\lsFontsize,% default is 11pt
    footnotes=multiple,
    numbers=noenddot,% no point after last number of chapters/sections
    \notbool{collection}{
      toc=bib, % make bibliography appear in toc
    }{}
    index=totoc,
    headings=optiontohead,
    footnotes=multiple
    ]{scrbook}

\ifbool{collection}
  {% In collected volumes, write "Chapter n" instead of "n" in the header
    \KOMAoptions{chapterprefix=true}
  }
  {
    \ifbool{paper}
      {% The same is applied to papers.
        \KOMAoptions{chapterprefix=true}
        \booltrue{lsImportPackagesWhenStandalone}
      }
      {}
  }

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%     Packages
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% secret hook to insert package which want to be loaded before all other packages
\IfFileExists{./langsci-earlyload.def}{\input{langsci-earlyload.def}}{}

\usepackage{xstring}
\usepackage{graphicx}
\usepackage{hyphenat}

\usepackage{tikz} % Needed for covers and advert page
	\usetikzlibrary{positioning}
	\usetikzlibrary{calc}

\usepackage[hyphens]{url}
\urlstyle{same}

%% standard commands
% \usepackage{langsci-basic}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Covers
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\notbool{minimal}{
    % Basic cover commands, including PGF layers
    \newcommand{\coversetup}{
        \booltrue{cover}
        \renewcommand{\maketitle}{}  %no need for this
        \pagestyle{empty}
        \pgfdeclarelayer{lspcls_bg}    % Create a background layer that serves as the canvas for the coloured rectangles.
        \pgfsetlayers{lspcls_bg,main}  % Order the background layer behind the main layer of TikZ.
    }

    % Fill the canvas for the cover with coloured areas on back and front cover
    % Argument 1: White margin that encompasses the coloured title and backtitle form. Input: 12.34mm
    % Argument 2: Height of the coloured title and backtitle form and of the spine. Input: 12.45cm
    % Argument 3: Width  of the coloured title and backtitle form. Input: 12.45cm
    \newcommand{\covergeometry}[3]{%
        \begin{pgfonlayer}{lspcls_bg} % Draw on the background layer
        \node [ bg, % Draw the coloured background on the front cover
                left = #1 of current page.east,
                fill=\lsSeriesColor,
                minimum height=#2,
                minimum width=#3
                ] (CoverColouredRectangleFront) {}; % Die können wir noch dynamisch bestimmen % 7.5mm -> 10.675mm for bleed
        \node [ bg, % Draw the coloured background on the back cover
                right = #1 of current page.west,
                fill=\lsSeriesColor,
                minimum height=#2,
                minimum width=#3
                ] (CoverColouredRectangleBack) {};
        \node at (current page.center) [ % Create a reference node for the spine
                bg,
                minimum height=#2,
                minimum width=\spinewidth,dashed
                ] (CoverSpine) {}; % add [draw] option for preview mode
        \end{pgfonlayer}
    }

    % Generates the content of the back cover. The starred variant \backcover*
    % does not print the ISBN on the back. By default, we use \backcover if 
    % we are in a cover generation mode, and backcover* otherwise.
    % Mandatory argument: Text width, corresponding to Argument 1 of \frontcovertoptext
    \NewDocumentCommand \backcover {s m}
      {%
        \node [ font=\lsBackTitleFont,
                right,
                below right = 10mm and 7.5mm of CoverColouredRectangleBack.north west,
                text width=#2
                ] (lspcls_backtitle) {\color{white}\raggedright\lsBackTitle\par};
        \node [ font=\lsBackBodyFont,
                below = 10mm of lspcls_backtitle,
                text width=#2,
                align=justify
                ] {\color{white}\parindent=15pt\lsBackBody};
        \node [ above left = 10mm and 7.5mm of CoverColouredRectangleBack.south east ] {%
          \IfBooleanF {#1}
            {%
              \colorbox{white}{%
                \ifbool{lsISBNTwoDigitAddon}{%
                  \begin{pspicture}(0,0)(5.25,1in)
                    \psbarcode[transx=.4,transy=.3]
                              {\lsISBNcover\ \lsISBNhardcoverTwoDigitAddon}
                              {includetext guardwhitespace height=.7}{isbn}
                  \end{pspicture}%
                }{%
                  \begin{pspicture}(0,0)(4.15,1in)
                      \psbarcode[transx=.4,transy=.3]
                                {\lsISBNcover}
                                {includetext height=.7}{isbn}%
                  \end{pspicture}%
                }%
              }%
            }};
      }

    % Generates the content on the front cover, including title, author, subtitle. See below for remaining commands
    % Argument 1: Text width on the front cover. Input: 12.34mm
    % Argument 2: Font size on the front cover. Adjust to compensate varying text width. Input: 12.34pt
    \newcommand{\frontcovertoptext}[3][white]{%
    \renewcommand{\newlineCover}{\\}
    \node [ font=\lsCoverTitleFont,
            below right = 10mm and 7.5mm of CoverColouredRectangleFront.north west,
            text width=#2,
            align=left
            ] (lspcls_covertitle) {\color{#1}\raggedright\@title\par};

    \ifx\@subtitle\empty  % Is there a subtitle? If no, just print the author.
    \node [ font=\lsCoverAuthorFont,
            right,
            below = 11.2mm of lspcls_covertitle.south,
            text width=#2
            ] {\color{#1}\nohyphens{%
            \lsEditorPrefix%
            \ResolveAffiliations[output in groups=false, 
                                 output affiliation=false, 
                                 output authors font=\lsCoverAuthorFont,
                                 separator between two=\\,
                                 separator between multiple=\\,
                                 separator between final two=\\]
                                 {\@author}\par}};
    \else % If yes, create a node for subtitle and author
    \node [ font=\lsCoverSubTitleFont,
            below = 8mm of lspcls_covertitle.south,
            text width=#2,
            align=left
            ] (lspcls_coversubtitle) {\color{#1}\raggedright\@subtitle\par};
    \node [
            font=\lsCoverAuthorFont,
            right,
            below = 11.2mm of lspcls_coversubtitle.south,
            text width=#2
            ] {\color{#1}\nohyphens{%
            \lsEditorPrefix%
            \ResolveAffiliations[output in groups=false, 
                                 output affiliation=false, 
                                 output authors font=\lsCoverAuthorFont,
                                 separator between two=\\,
                                 separator between multiple=\\,
                                 separator between final two=\\]
                                 {\@author}\par}};
    \fi
    }

    % Generates the bottom half of the front cover content: series, series number, logo.
    \newcommand{\coverbottomtext}[1][white]{%
    \node [ above right = 18.5mm and -.1mm of CoverColouredRectangleFront.south west,
            rectangle,
            fill=white,
            minimum size=17pt] (lspcls_square) {}; % This is the white square at the bottom left of the front cover
    \node [ above left = 10mm and 7.5mm of CoverColouredRectangleFront.south east] {\color{#1}\includepublisherlogo}; % Print the Language Science press Logo
    \path let \p1 = (lspcls_square.north east), % Calculate the exact coordinates for the Series Title to print.
                \p2 = (lspcls_covertitle.west)
                in node at (\x2,\y1) (lspcls_seriesinfo) [
                    font=\lsCoverSeriesFont,
                    right,
                    text width=95mm,
                    anchor=north west]
                {\color{#1}\lsSeriesTitle~\lsSeriesNumber\par};
    }
}{}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%      Output types
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


%% Output types are defined with \newcommand above so they can be used with geometry.

%we define a command to better encapsulate the logic
\newcommand{\setuptitle}{%
    \renewcommand{\maketitle}{%first we treat covers to get them out of the way

        \ifbool{coverBODhc}{%
            \bodHCcover
            \end{document}
        }{}

        \ifbool{coverBODsc}{%
            \bodSCcover
            \end{document}
        }{}

        \ifbool{coverCS}{%
           \amazonKindleCover
            \end{document}
        }{}

        \ifbool{book}{
            \begin{titlepage}
            \thispagestyle{empty}
            \setcounter{page}{-1}
            %% First titlepage:
            {\lsFrontPage}
            %%%%%%%%%%%%%%%%%%%
            \pagenumbering{roman}\clearpage\thispagestyle{empty} % We use roman pagenumbering here instead of \frontmatter because scrbook's frontmatter command issues a \clear(double)page, which is unnec. in digital publications.
            %% Series information:
            {\lsSeriesHistory}
            %%%%%%%%%%%%%%%%%%%%%
            \clearpage%\thispagestyle{empty}
            %% Schmutztitel:
            {\renewcommand{\lsCoverBlockColor}{white}
            \renewcommand{\lsCoverFontColor}{\lsSeriesColor}
            \lsSchmutztitel}
            %%%%%%%%%%%%%%%%%%%%
            \AtEndDocument{
                \lsPageStyleEmpty
                \null\newpage\thispagestyle{empty} % add a final blank page
                    %% Back page:
                {\lsBackPage}
                \null\newpage\thispagestyle{empty}
            }
            \end{titlepage}
        }{} %end book

        \ifbool{guidelines}{%
            \begin{titlepage}
            \thispagestyle{empty}
            {\setcounter{page}{-1}
            {\lsFrontPage}
            }
            \end{titlepage}
        }{} %end guidelines

        \color{black}
        \lsInsideFont

        %% Imprint:
        \notbool{guidelines}{
            {\lsImpressum}
        }{} %end guidlines
        %%%%%%%%%%%%%

        % \null\newpage\thispagestyle{plain}
        %\pagenumbering{roman}    % or \frontmatter

        %% Dedication:
        \ifx\@dedication\empty{}
        \else{\newpage\lsDedication}
        \fi
        %%%%%%%%%%%%%%%%
    } %% \maketitle
} %\setuptitle


\notbool{paper}{
    % A paper differs in title generation from the other
    % output types, and it needs more input to produce
    % its title. This is why \maketitle for output==paper
    % is deferred until later. See the call to \includepaper@body.
    \AtBeginDocument{%
        \ifbool{minimal}
          {% The minimal mode skips cover generation
            \renewcommand{\maketitle}{You are using the minimal mode.} 
          }
          {% else minimal
            \setuptitle
          }

        %% for those who like the example in numbered example sentences to be typeset in italics
        %% this is possible for a complete series only.
        \ifx\lsSeries\sidl
        %\def\exfont{\normalsize\itshape}
        \let\eachwordone=\itshape % only \gll

        \let\oldtable\table   % footnotes in tables without horizontal line
        \let\endoldtable\endtable
        \renewenvironment{table}{\setfootnoterule{0pt}\oldtable}{\endoldtable}
        \fi

        \ifx\lsSeries\pmwe
        \let\eachwordone=\normalfont
        \fi

        \ifx\lsSeries\nc
        \let\eachwordone=\itshape
        \fi
        
        \ifx\lsSeries\cogl
        \let\eachwordone=\itshape
        \fi
        
        \ifx\lsSeries\rcg
        \let\eachwordone=\itshape
        \fi
        
        \ifx\lsSeries\eotms
        \renewcommand{\sectref}[1]{Section~\ref{#1}}
        \fi
    } %% \AtBeginDocument
}{} %notbool paper


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   Geometry
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% For output type cover
% CS spine width algorithm, when page count is known:  Total Page Number (excluding cover), usually (Total Page - 3) * 0.0572008 mm
% BoD spine width algorithm located at http://www.bod.de/hilfe/coverberechnung.html (German only, please contact LangSci for help)
\newlength{\bleed}
\newlength{\seitenbreite}
\newlength{\seitenhoehe}
\newlength{\spinewidth}
\newlength{\totalwidth}
\newlength{\totalheight}
\setlength{\bleed}{3.175mm}
\setlength{\spinewidth}{\lsSpinewidth} % Create Space Version
\usepackage{calc}

\ifbool{coverCS}{
  \booltrue{cover}
  \usepackage{langsci-pod}
  \csgeometry
} %end covercs

\ifbool{coverBODhc}{
  \booltrue{cover}
  \usepackage{langsci-pod}
  \bodhcgeometry
}{}

\ifbool{coverBODsc}{
  \booltrue{cover}
  \usepackage{langsci-pod}
  \bodscgeometry
}{}

%Page size and text area if not cover

\notbool{cover}{
%output types cover have already been handled
  \usepackage[
  papersize={170mm,240mm}
  ,top=27.4mm % TODO nachgemessen, nach Vermassung eigentlich 30mm-16pt = 25.8mm
  ,inner=20.5mm,
  ,outer=24.5mm
  %,showframe,pass
  ,marginparwidth=50pt
  ]{geometry}
}{}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Fonts
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{ifxetex}
\ifxetex\else\ClassError{langscibook}{Please use XeLaTeX!}{}\fi

%% Typesetting of mathematical formulas
\usepackage{amssymb} % has to be loaded before other stuff
\usepackage{amsmath} % has to be loaded before mathspec/unicode-math

\notbool{minimal}{% The minimal mode skips font loading
    \notbool{newtxmath}{
    %% There is a known problem in the interplay between \binom, unicode-math, and OTF
    %% https://tex.stackexchange.com/questions/269980/wrong-parentheses-size-in-binom-with-xelatex-and-unicode-math-in-displaystyle
    \ifx\Umathcode\@undefined\else
        \DeclareRobustCommand{\genfrac}[6]{%
        \def\@tempa{#1#2}%
        \edef\@tempb{\@nx\@genfrac\@mathstyle{#4}%
            % just \over or \above never withdelims versions
            \ifx @#3@\@@over\else\@@above\fi
        }%
        \ifx\@tempa\@empty \else
            \bgroup % so mathord not mathinner
            \left\ifx\relax#1\relax.\else#1\fi % assumes . is null delimiter
            % otherwise add specified delimiter
            \kern-\nulldelimiterspace % fractions add extra nulldelimiter space
        \fi
        \@tempb{#3}{\mathstrut{#5}}{\mathstrut{#6}}%
        \ifx\@tempa\@empty \else
            \kern-\nulldelimiterspace
            \right\ifx\relax#2\relax.\else#2\fi
            \egroup
        \fi
        }
    \fi%umathcode
    %% Provides \setmathfont
    \usepackage{unicode-math}
    }{%else newtxmath
    %% Deprecated:
    \PassOptionsToPackage{no-math}{fontspec} % must appear before metalogo or any fontspec stuff; deactivates fontspec's math settings, which is necessary to let newtxmath do the job
    }

    \usepackage{metalogo}\newcommand{\xelatex}{\XeLaTeX\xspace}

    \setmonofont[
    %   Ligatures={TeX},% not supported by ttf
    Scale=MatchLowercase,
    BoldFont = DejaVuSansMono-Bold.ttf ,
    SlantedFont = DejaVuSansMono-Oblique.ttf ,
    BoldSlantedFont = DejaVuSansMono-BoldOblique.ttf
    ]{DejaVuSansMono.ttf}

    \setsansfont[
    %Ligatures={TeX,Common},% not supported by ttf
    Scale=MatchLowercase,
    BoldFont = Arimo-Bold.ttf,
    ItalicFont = Arimo-Italic.ttf,
    BoldItalicFont = Arimo-BoldItalic.ttf
    ]{Arimo-Regular.ttf}

    \notbool{newtxmath}{
    \setmathfont[AutoFakeBold]{LibertinusMath-Regular.otf}
    \setmathfont[range={cal},StylisticSet=1]{XITSMath-Regular.otf}
    \setmathfont[range={bfcal},StylisticSet=1]{XITSMath-Bold.otf}
    }{}

    \ifbool{oldstylenumbers}{
    \defaultfontfeatures[LibertinusSerif-Semibold.otf,LibertinusSerif-Italic.otf,LibertinusSerif-SemiboldItalic.otf,LibertinusSerif-Regular.otf]{SmallCapsFeatures={Numbers=OldStyle}}
    }{}
    \setmainfont
      [
        Ligatures={TeX,Common},
        PunctuationSpace=0,
        Numbers={Proportional},
        BoldFont = LibertinusSerif-Semibold.otf,
        ItalicFont = LibertinusSerif-Italic.otf,
        BoldItalicFont = LibertinusSerif-SemiboldItalic.otf,
        BoldSlantedFont = LibertinusSerif-Semibold.otf,
        SlantedFont    = LibertinusSerif-Regular.otf,
        SlantedFeatures = {FakeSlant=0.25},
        BoldSlantedFeatures = {FakeSlant=0.25},
        SmallCapsFeatures = {FakeSlant=0},
      ]
      {LibertinusSerif-Regular.otf}

    %% Deprecated:
    \ifbool{newtxmath}{
            \usepackage[libertine]{newtxmath}
            %% following http://tex.stackexchange.com/questions/297328/xelatex-does-not-load-newtxmath-with-linuxlibertine-sometimes
            %% due to a bug in XeTeX. This also seems to fix an issue with \url in footnotes.
    %% Unfortunately, this is NOT extensively tested!
            \usepackage{xpatch}
            \xpretocmd{\textsuperscript}
            {{\sbox0{$\textstyle x$}}}
            {}{}
            \AtBeginDocument{%
            \DeclareSymbolFont{operators}{\encodingdefault}{\familydefault}{m}{n}%
            \SetSymbolFont{operators}{bold}{\encodingdefault}{\familydefault}{b}{n}%
            }
    }{}
    % Improve the appearance of numbers in tables and the TOC 
    % In those places, they should come out monospaced, unlike in main text.
    \AtBeginEnvironment{tabular}{\addfontfeatures{Numbers={Monospaced,Lining}}\selectfont}
    \AtBeginEnvironment{tabularx}{\addfontfeatures{Numbers={Monospaced,Lining}}\selectfont}
    \AtBeginEnvironment{longtable}{\addfontfeatures{Numbers={Monospaced,Lining}}\selectfont}
    
    \DeclareTOCStyleEntry
      [  
        entrynumberformat=\addfontfeature{Numbers={Monospaced,Lining}},
        pagenumberformat=\addfontfeature{Numbers={Monospaced,Lining}}\bfseries,
        raggedentrytext=true
      ]
      {tocline}
      {chapter}
      
    \DeclareTOCStyleEntries
      [
        entrynumberformat=\addfontfeature{Numbers={Monospaced,Lining}},
        pagenumberformat=\addfontfeature{Numbers={Monospaced,Lining}},
        raggedentrytext=true
      ]
      {tocline}
      {section,subsection,subsubsection,paragraph,subparagraph}
    
    % In collected volumes, adjust the spacing for unnumbered chapters
    \ifbool{collection}{
    \BeforeStartingTOC[toc]{\SetupAffiliations{output affiliation=false,
                                               output authors font=\normalfont,
                                               separator between two={~\&~},
                                               separator between multiple={,~},
                                               separator between final two={~\&~}}
                                               }
      \renewcommand{\addtocentrydefault}[3]{%
        \Ifstr{#2}{}{%
          \addcontentsline{toc}{#1}{\protect\numberline{~}#3}%
        }{%
          \addcontentsline{toc}{#1}{\protect\numberline{#2}#3}%
          }%
      }%
    }{}
    \frenchspacing	%see https://en.wikipedia.org/wiki/Sentence_spacing#Typography
    \usepackage[final]{microtype}

    \newcommand{\lsCoverTitleFontSize}{52pt}
    \newcommand{\lsCoverTitleFontBaselineskip}{17.25mm}
    \newcommand{\lsCoverTitleSizes}[2]{\renewcommand{\lsCoverTitleFontSize}{#1}\renewcommand{\lsCoverTitleFontBaselineskip}{#2}}
    \newcommand{\lsCoverTitleFont}[1]{\sffamily\addfontfeatures{Scale=MatchUppercase}\fontsize{\lsCoverTitleFontSize}{\lsCoverTitleFontBaselineskip}\selectfont #1}
    \newcommand{\lsCoverSubTitleFont}{\sffamily\addfontfeatures{Scale=MatchUppercase}\fontsize{25pt}{10mm}\selectfont}
    \newcommand{\lsCoverAuthorFont}{\fontsize{25pt}{12.5mm}\selectfont}
    \newcommand{\lsCoverSeriesFont}{\sffamily\fontsize{17pt}{7.5mm}\selectfont}			% fontsize?
    \newcommand{\lsCoverSeriesHistoryFont}{\sffamily\fontsize{10pt}{5mm}\selectfont}
    \newcommand{\lsInsideFont}{}	% obsolete, see \setmainfont
    \newcommand{\lsDedicationFont}{\fontsize{15pt}{10mm}\selectfont}
    \newcommand{\lsBackTitleFont}{\sffamily\addfontfeatures{Scale=MatchUppercase}\fontsize{25pt}{10mm}\selectfont}
    \newcommand{\lsBackBodyFont}{\lsInsideFont}
    \newcommand{\lsSpineAuthorFont}{\bfseries\fontsize{16pt}{14pt}\selectfont}
    \newcommand{\lsSpineTitleFont}{\sffamily\bfseries\fontsize{18pt}{14pt}\selectfont}
}{} %end else minimal

\setkomafont{sectioning}{\normalcolor\bfseries}
\setkomafont{descriptionlabel}{\normalfont\itshape}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Colors
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{xcolor}

\definecolor{lsLightBlue}{cmyk}{0.6,0.05,0.05,0}
\definecolor{lsMidBlue}{cmyk}{0.75,0.15,0,0}
\definecolor{lsMidDarkBlue}{cmyk}{0.9,0.4,0.05,0}
\definecolor{lsDarkBlue}{cmyk}{0.9,0.5,0.15,0.3}
\definecolor{lsNightBlue}{cmyk}{1,0.47,0.22,0.68}

\definecolor{lsYellow}{cmyk}{0,0.25,1,0}
\definecolor{lsLightOrange}{cmyk}{0,0.50,1,0}
\definecolor{lsMidOrange}{cmyk}{0,0.64,1,0}
\definecolor{lsDarkOrange}{cmyk}{0,0.78,1,0}
\definecolor{lsRed}{cmyk}{0.05,1,0.8,0}

\definecolor{lsLightWine}{cmyk}{0.3,1,0.6,0}
\definecolor{lsMidWine}{cmyk}{0.54,1,0.65,0.1}
\definecolor{lsDarkWine}{cmyk}{0.58,1,0.70,0.35}
\definecolor{lsSoftGreen}{cmyk}{0.32,0.02,0.72,0}
\definecolor{lsLightGreen}{cmyk}{0.4,0,1,0}

\definecolor{lsMidGreen}{cmyk}{0.55,0,0.9,0.1}
\definecolor{lsRichGreen}{cmyk}{0.6,0,0.9,0.35}
\definecolor{lsDarkGreenOne}{cmyk}{0.85,0.02,0.95,0.38}
\definecolor{lsDarkGreenTwo}{cmyk}{0.85,0.05,1,0.5}
\definecolor{lsNightGreen}{cmyk}{0.88,0.15,1,0.66}

\definecolor{lsLightGray}{cmyk}{0,0,0,0.17}
\definecolor{lsGuidelinesGray}{cmyk}{0,0.04,0,0.45}

\definecolor{lsDOIGray}{cmyk}{0,0,0,0.45}
\definecolor{RED}{cmyk}{0.05,1,0.8,0}

\definecolor{langscicol1}{cmyk}{0.6,0.05,0.05,0}
\definecolor{langscicol2}{cmyk}{0.75,0.15,0,0}
\definecolor{langscicol3}{cmyk}{0.9,0.4,0.05,0}
\definecolor{langscicol4}{cmyk}{0.9,0.5,0.15,0.3}
\definecolor{langscicol5}{cmyk}{1,0.47,0.22,0.68}
\definecolor{langscicol6}{cmyk}{0,0.25,1,0}
\definecolor{langscicol7}{cmyk}{0,0.50,1,0}
\definecolor{langscicol8}{cmyk}{0,0.64,1,0}
\definecolor{langscicol9}{cmyk}{0,0.78,1,0}
\definecolor{langscicol10}{cmyk}{0.05,1,0.8,0}
\definecolor{langscicol11}{cmyk}{0.3,1,0.6,0}
\definecolor{langscicol12}{cmyk}{0.54,1,0.65,0.1}
\definecolor{langscicol13}{cmyk}{0.58,1,0.70,0.35}
\definecolor{langscicol14}{cmyk}{0.32,0.02,0.72,0}
\definecolor{langscicol15}{cmyk}{0.4,0,1,0}
\definecolor{langscicol16}{cmyk}{0.55,0,0.9,0.1}
\definecolor{langscicol17}{cmyk}{0.6,0,0.9,0.35}
\definecolor{langscicol18}{cmyk}{0.85,0.02,0.95,0.38}
\definecolor{langscicol19}{cmyk}{0.85,0.05,1,0.5}
\definecolor{langscicol20}{cmyk}{0.88,0.15,1,0.66}

% \newcommand{\lsptable}[2]{
% \resizebox{#1}{!}{
% \begin{tabularx}{\textwidth}{XXXXXXXXXXXXXXXXXXXX}
%  \cellcolor{langscicol1}&\cellcolor{langscicol2}&\cellcolor{langscicol3}&\cellcolor{langscicol4}&\cellcolor{langscicol5}&\cellcolor{langscicol6}&\cellcolor{langscicol7}&\cellcolor{langscicol8}&\cellcolor{langscicol9}&\cellcolor{langscicol10}&\cellcolor{langscicol11}&\cellcolor{langscicol12}&\cellcolor{langscicol13}&\cellcolor{langscicol14}&\cellcolor{langscicol15}&\cellcolor{langscicol16}&\cellcolor{langscicol17}&\cellcolor{langscicol18}&\cellcolor{langscicol19}&\cellcolor{langscicol20}
%  \rule{0pt}{#2}
% \end{tabularx}
% }
% }

\input{langsci-series.def}
\ifbool{guidelines}
  {\let\lsSeries\guidelines}
  {}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Cover
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{pst-barcode} % generates ISBN bar codes
\newcommand{\lsCoverFontColor}{white}
\newcommand{\lsCoverBlockColor}{\lsSeriesColor}

\ExplSyntaxOn
\NewDocumentCommand{\lsDetermineMultiauthors}{}
  {%
    \int_compare:nNnTF
        {\g__affiliations_num_authors_int} > {1}
        {\booltrue{multiauthors}} {}
  }
\ExplSyntaxOff

\newcommand{\lsEditorPrefix}{}
\newcommand{\lsEditorSuffix}{}
\ifbool{collection}{
  \AtBeginDocument{
    \renewcommand{\newlineCover}{}
    \renewcommand{\newlineSpine}{}
    \renewcommand{\lsEditorPrefix}{{\Large Edited by\\}}
    \renewcommand{\lsEditorSuffix}{(ed.)}
    \CountAuthorsFromAffiliations{\@author}
    \lsDetermineMultiauthors{}
    \ifbool{multiauthors}{\renewcommand{\lsEditorSuffix}{(eds.)}}{}
  } %end AtBeginDocument
}{} %end collection

\pgfdeclarelayer{lspcls_bg}    % Create a background layer that serves as the canvas for the coloured rectangles.
\pgfsetlayers{lspcls_bg,main}  % Order the background layer behind the main layer of TikZ.

\newcommand{\lsFrontPage}{% Front page
    \ifcsname tikz@library@external@loaded\endcsname\tikzexternaldisable\fi
    \pgfdeclarelayer{lspcls_bg}    % Create a background layer that serves as the canvas for the coloured rectangles.
    \pgfsetlayers{lspcls_bg,main}  % Order the background layer behind the main layer of TikZ.
    \thispagestyle{empty}
    \begin{tikzpicture}[remember picture, overlay,bg/.style={outer sep=0}]
        \begin{pgfonlayer}{lspcls_bg}
            \node [ bg,
                    left=7.5mm of current page.east,
                    fill=\lsSeriesColor,
                    minimum width=155mm,
                    minimum height=225mm
                    ] (CoverColouredRectangleFront) {};
        \end{pgfonlayer}
        \frontcovertoptext{140mm}{51pt}
        \coverbottomtext
        \ifbool{draft}{\node [rotate=45,align=center,scale=3,color=white,text opacity=.75] at (current page.center) {\lsCoverTitleFont Draft\\of \today, \currenttime};}{}
        \ifbool{openreview}{
        \node [rotate=45,align=center,scale=1.5,color=white,text opacity=.75] at (current page.center) {\lsCoverTitleFont Open Review\\Version of \today, \currenttime};}{}
    \end{tikzpicture}
    \ifcsname tikz@library@external@loaded\endcsname\tikzexternalenable\fi
} % end lsFrontPage

\newcommand{\lsSchmutztitel}{% Schmutztitel
    \ifcsname tikz@library@external@loaded\endcsname\tikzexternaldisable\fi
    \pgfdeclarelayer{lspcls_bg}    % Create a background layer that serves as the canvas for the coloured rectangles.
    \pgfsetlayers{lspcls_bg,main}  % Order the background layer behind the main layer of TikZ.
    \thispagestyle{empty}
    \begin{tikzpicture}[remember picture, overlay,bg/.style={outer sep=0}]
        \begin{pgfonlayer}{lspcls_bg}
            \node [ bg,
                    left=7.5mm of current page.east,
                    fill=white,
                    minimum width=155mm,
                    minimum height=225mm
                    ] (CoverColouredRectangleFront) {};
        \end{pgfonlayer}
        \frontcovertoptext[\lsSeriesColor]{140mm}{51pt}
        \node [ above left = 10mm and 7.5mm of CoverColouredRectangleFront.south east] {\color{\lsSeriesColor}\includepublisherlogo}; % Print the Language Science press Logo
    \end{tikzpicture}
    \ifcsname tikz@library@external@loaded\endcsname\tikzexternalenable\fi
} %end Schmutztitel

\newcommand{\lsBackPage}{%
    \ifcsname tikz@library@external@loaded\endcsname\tikzexternaldisable\fi
    \pgfdeclarelayer{lspcls_bg}    % Create a background layer that serves as the canvas for the coloured rectangles.
    \pgfsetlayers{lspcls_bg,main}  % Order the background layer behind the main layer of TikZ.
    \pagestyle{empty}
    \newcommand{\lsISBNcover}{\lsISBNdigital}
        \begin{tikzpicture}[remember picture, overlay,bg/.style={outer sep=0}]
        \begin{pgfonlayer}{lspcls_bg}
            \node [ bg,
                    right=7.5mm of current page.west,
                    fill=\lsSeriesColor,
                    minimum width=155mm,
                    minimum height=225mm
                    ] (CoverColouredRectangleBack) {};
        \end{pgfonlayer}
        \ifbool{cover}{\backcover{137mm}}{\backcover*{137mm}}
    \end{tikzpicture}
  \ifcsname tikz@library@external@loaded\endcsname\tikzexternalenable\fi
  }

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Series history
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand{\tblseight}{{\color{red}Chinese fonts for TBLS 8 not loaded! Please set the option \textsc{tblseight} in main.tex for final production}}

\ifbool{tblseight}
  {
    \newfontfamily\cn
      [
        Scale=MatchLowercase,
        BoldFont=SourceHanSerifSC-Bold.otf
      ]
      {SourceHanSerifSC-Regular.otf}

    \renewcommand{\tblseight}{{\cn 语法理论: 从转换语法到基于约束的理论}}
  }{}
  
\ExplSyntaxOn
% A command to output a limited number of items on the series history page.
% This is useful in case there are too many items in a series history.
% The number of maximum items are passed to the first, optional argument
% to the command. Its default is 15.
\NewDocumentCommand{\lsSeriesHistoryWheel}{O{15} m}
  {%
    \begin{enumerate}
    \langsci_wheel:nn {#1} {#2}
    \end{enumerate}
  }

% Setup of data
\seq_new:N \langsci_wheel_seq
\int_new:N \langsci_wheel_loop_count_int
\int_new:N \langsci_wheel_output_difference_int
\tl_new:N \langsci__wheel_wastebin_tl
\cs_new:Npn \langsci_wheel:nn #1#2
  {
    % Let's split the input at each \item. From the result, remove the 
    % first item, which will be empty.
    \seq_set_split:Nnn \langsci_wheel_seq {\item} {#2}
    \seq_pop_left:NNTF \langsci_wheel_seq \langsci__wheel_wastebin_tl {} {}
    % The offset is calculated by (length of input - maximum output)
    \int_set:Nn \langsci_wheel_output_difference_int 
      {
        \seq_count:N \langsci_wheel_seq - #1
      }
    % An integer used for counting inside the loop.
    \int_zero:N \langsci_wheel_loop_count_int
    % Loop over the input and determine, for each item, whether to output
    % it. The item is output when its number is greater than the difference 
    % between actual length and maximum.
    \seq_map_inline:Nn \langsci_wheel_seq 
      {
        \int_incr:N \langsci_wheel_loop_count_int
        \int_compare:nNnTF 
          \langsci_wheel_loop_count_int > \langsci_wheel_output_difference_int
          {\item[\int_use:N \langsci_wheel_loop_count_int.] ##1}
          {}
      }
  }
\ExplSyntaxOff

\newcommand{\lsSeriesHistory}{
    \color{black}
    \raggedright\lsCoverSeriesHistoryFont

    % \IfFileExists{./\lsSeries-info.tex}{\input{./\lsSeries-info}}{
    %   Series information:  \lsSeries-info.tex not found!}

    {\lsSeriesText}
    \IfStrEq{\lsISSNprint}{??}   % \IfStrEq from xstring
    {}
    {\vfill\hfill ISSN (print): \lsISSNprint\\
            \hfill ISSN (electronic): \lsISSNelectronic\\}
    \IfStrEq{\lsISSN}{??}   % \IfStrEq from xstring
    {}
    {\vfill\hfill ISSN: \lsISSN}
} %end lsSeriesHistory

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Imprint
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% for imprint:
\def\translator#1{\gdef\@translator{#1}}
\translator{}

\def\typesetter#1{\gdef\@typesetter{#1}}
\typesetter{}

\def\proofreader#1{\gdef\@proofreader{#1}}
\proofreader{}

\def\openreviewer#1{\gdef\@openreviewer{#1}}
\openreviewer{}

\def\illustrator#1{\gdef\@illustrator{#1}}
\illustrator{}

\newcommand{\lsAdditionalFontsImprint}{}
\newcommand{\AdditionalFontImprint}[1]
  {
    \edef\fontstemp{\lsAdditionalFontsImprint}
    \renewcommand{\lsAdditionalFontsImprint}{\fontstemp, #1}
  }

%\def\@author{\@latex@warning@no@line{No \noexpand\author given}}
\newcommand{\ISBNdigital}[1]{\renewcommand{\lsISBNdigital}{#1}}
\newcommand{\ISBNsoftcover}[1]{\renewcommand{\lsISBNsoftcover}{#1}}
\newcommand{\ISBNsoftcoverus}[1]{\renewcommand{\lsISBNsoftcoverus}{#1}}
\NewDocumentCommand { \ISBNhardcover } { o m }
  {%
    \renewcommand{\lsISBNhardcover}{#2}%
    \IfValueT{#1}
    {%
      \booltrue{lsISBNTwoDigitAddon}
      \newcommand{\lsISBNhardcoverTwoDigitAddon}{#1}
    }
  }

\newcommand{\URL}[1]{\renewcommand{\lsURL}{#1}}
\newcommand{\Series}[1]{\renewcommand{\lsSeries}{#1}}
\newcommand{\SeriesNumber}[1]{\renewcommand{\lsSeriesNumber}{#1}}
\newcommand{\BookDOI}[1]{\renewcommand{\lsBookDOI}{#1}}

\ifbool{paper}
  {}
  {%
    \AtBeginDocument
      {%
        \bgroup
        \renewcommand{\newlineCover}{}
        \renewcommand{\newlineSpine}{}
        \newwrite\metadatafile
        \immediate\openout\metadatafile=langscitmp.bib
        \immediate\write\metadatafile{%
          @book{langsci-current-book,
            \ifbool{collection}
              {editor = {\unexpanded\expandafter{\@author}},}
              {author = {\unexpanded\expandafter{\@author}},}
            title = {{\unexpanded\expandafter{\@title}}},
            \if\@subtitle\empty\else subtitle = {{\unexpanded\expandafter{\@subtitle}}},\fi
            year = {\lsYear},
            series = {\lsSeriesTitle},
            number = {\lsSeriesNumber},
            location = {Berlin},
            publisher = {Language Science Press},
            options = {dataonly=true}
          }
        }
        \immediate\closeout\metadatafile
        \egroup
        \addbibresource{langscitmp.bib}
      }
  }

\newcommand{\lsImpressumCitationText}
  {%
    \renewcommand{\newlineCover}{}%
    \renewcommand{\newlineSpine}{}%
    \fullciteImprint{langsci-current-book}
  }

\newcommand{\lsImpressumExtra}{}%for legal notes required for revised theses ("... in fulfillment of ... ")

\newcommand{\publisherstreetaddress}
  {redefine \textbackslash publisherstreetaddress}

\newcommand{\publisherurl}{redefine \textbackslash publisherurl}

\newcommand{\storageinstitution}{redefine \textbackslash storageinstitution}
\newcommand{\githubtext}{~}
\newcommand{\paperhivetext}{~}

\newcommand{\lsImpressum}{%
\thispagestyle{empty}
\raggedright

\lsImpressumCitationText

\vfill

This title can be downloaded at:\\
\url{\lsURL}

© \lsYear,
\ifbool{collection}{%
    the authors}{%
    % \else
    \CiteFullAuthorList{langsci-current-book}
}

\newcommand{\ccby}{CC-BY}
\newcommand{\ccbynd}{CC-BY-ND}
\newcommand{\ccbysa}{CC-BY-SA}
\ifx\lsCopyright\ccby
Published under the Creative Commons Attribution 4.0 Licence (CC BY 4.0):
http://creativecommons.org/licenses/by/4.0/ \lsLicenseInformation{ccby}
\fi
\ifx\lsCopyright\ccbynd
Published under the Creative Commons Attribution-NoDerivatives 4.0 Licence (CC BY-ND 4.0):
http://creativecommons.org/licenses/by-nd/4.0/ \lsLicenseInformation{ccbynd}
\fi
\ifx\lsCopyright\ccbysa
Published under the Creative Commons Attribution-ShareAlike 4.0 Licence (CC BY-SA 4.0):
http://creativecommons.org/licenses/by-sa/4.0/ \lsLicenseInformation{ccbysa}
\fi

{\lsImpressumExtra}

\ifx\lsSeries\sidl
Indexed in EBSCO\smallskip
\fi

\begin{tabular}{@{}l@{~}l}
ISBN: &
\IfStrEq{\lsISBNdigital}{000-0-000000-00-0}{%no digital ISBN, issue warning
    \color{red}no digital ISBN
}{%digital ISBN present, write ISBN
    \lsISBNdigital~(Digital)
}
\\
\IfStrEq{\lsISBNhardcover}{000-0-000000-00-0}{ %hardcover ISBN not present
}{%hardcover ISBN present, write ISBN
  &\lsISBNhardcover~(Hardcover)\\
}

\IfStrEq{\lsISBNsoftcover}{000-0-000000-00-0}{ %softcover ISBN not present
    \IfStrEq{\lsISBNhardcover}{000-0-000000-00-0}{ %neither hardcover nor softcover, issue warning
        \color{red} no print ISBNs!
    }{%hardcover present, no warning
    }
}{%only softcover present, write ISBN
    &\lsISBNsoftcover~(Softcover)\\
}
\end{tabular}

\IfStrEq{\lsISSNprint}{??}   % \IfStrEq from xstring
  {}
  {%else
    ISSN (print): \lsISSNprint\\
    ISSN (electronic): \lsISSNelectronic\\
  }
\IfStrEq{\lsISSN}{??}
  {}
  {%else
    ISSN: \lsISSN
  }

\IfStrEq{\lsBookDOI}{??}{
    {\color{red} no DOI}
}{ %else
    DOI: \href{https://doi.org/\lsBookDOI}{\nolinkurl{\lsBookDOI}}
}\\
\IfStrEq{\lsID}{000}{
    \color{red} ID not assigned!
}{%else
    \githubtext\\
    \paperhivetext
}%
\bigskip

Cover and concept of design:
Ulrike Harbort \\
\if\@translator\empty\else
Translation:
\@translator \\
\fi
\if\@typesetter\empty\else
Typesetting:
\@typesetter \\
\fi
\if\@illustrator\empty\else
Illustration:
\@illustrator \\
\fi
\if\@proofreader\empty\else
Proofreading:
\@proofreader \\
\fi
\if\@openreviewer\empty\else
Open reviewing:
\@openreviewer \\
\fi
Fonts: Libertinus, Arimo, DejaVu Sans Mono\lsAdditionalFontsImprint\\
Typesetting software: \XeLaTeX

\bigskip

\publisherstreetaddress\\
\publisherurl

\vfill

Storage and cataloguing done by \storageinstitution\\[3ex]

\includestoragelogo\\[3ex]


% \vfill

% \noindent
% \lsp has no responsibility for the persistence or accuracy of URLs for
% external or third-party Internet websites referred to in this
% publication, and does not guarantee that any content on such websites
% is, or will remain, accurate or appropriate.
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Dedication
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand{\lsDedication}
  {%
    \thispagestyle{empty}
	\vspace*{\fill}
	\begin{center}
	{\lsDedicationFont
	\@dedication\par}
	\end{center}
	\vspace*{\fill}
	\clearpage
  }

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Header and footer
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{datetime}
\usepackage[autoenlargeheadfoot=off, draft=false]{scrlayer-scrpage}
% This option explicitely increases the size of the footer in plain pages.
% This ensures there is enough space to print the citation in collected vols.
% This setting does not influence the composition of the typearea.
\AddToLayerPageStyleOptions{plain.scrheadings}
    {onselect={\setlength{\footheight}{3\baselineskip}}}
    
\ohead{\headmark}
\ihead{}
\cfoot{}
\ofoot[]{\pagemark}
\ifbool{draft}{
  \ifoot{Draft of \today, \currenttime}
}{}
\ifbool{openreview}{
  \ifoot{{\color{lsRed}Open review version}. Final version at \url{\lsURL}.}
}{}

\newcommand{\lsPageStyleEmpty}{
  \ohead{}
  \ihead{}
  \cfoot{}
  \ofoot[]{}
}

\renewcommand*{\partpagestyle}{empty}

\pagestyle{scrheadings}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Sectioning
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\setcounter{secnumdepth}{4}

\def\subsubsubsection{\@startsection{paragraph}{3}{\z@}{-3.25ex plus
-1ex minus-.2ex}{1.5ex plus.2ex}{\reset@font\normalsize}}

\let\subsubsubsectionmark\@gobble%

\def\subsubsubsubsection{\@startsection{subparagraph}{3}{\z@}{-3.25ex plus
-1ex minus-.2ex}{1.5ex plus.2ex}{\reset@font\normalsize}}

\let\subsubsubsubsectionmark\@gobble

%% needed for hyperref
\def\toclevel@subsubsubsection{4}

% Commands for Sections in Appendices:
% Use as \appendixsection and \appendixsubsection. 
% Further commands for lower levels can be defined following this pattern.
\DeclareNewSectionCommand
  [
    counterwithin = chapter,
    afterskip = 2.3ex plus .2ex,
    beforeskip = -3.5ex plus -1ex minus -.2ex,
    indent = 0pt,
    font = \usekomafont{section},
    level = 1,
    tocindent = 1.5em,
    toclevel = 1,
    tocnumwidth = 2.3em,
    tocstyle = section,
    style = section
  ]
  {appendixsection}

\renewcommand*\theappendixsection{\Alph{appendixsection}}
\renewcommand*{\appendixsectionformat}
              {\appendixname~\theappendixsection\autodot\enskip}
\renewcommand*{\appendixsectionmarkformat}
              {\appendixname~\theappendixsection\autodot\enskip}

\DeclareNewSectionCommand
  [
    counterwithin = appendixsection,
    beforeskip=-10pt,
    afterskip=1sp,
    indent = 0pt,
    font = \usekomafont{subsection},
    level = 2,
    tocindent = 3.8em,
    toclevel = 2,
    tocnumwidth = 3.2em,
    tocstyle = section,
    style = section
  ]
  {appendixsubsection}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Epigrams
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\def\epigram#1{\gdef\@epigram{#1}}      % needs to be defined this way to check emptiness
\epigram{}
\def\epigramsource#1{\gdef\@epigramsource{#1}}
\epigramsource{}

\usepackage{epigraph}
\setlength{\epigraphrule}{0pt}
\renewcommand{\textflush}{flushepinormal}
\setlength{\epigraphwidth}{.618\textwidth}% Set to the longer part of golden ratio
\setlength{\afterepigraphskip}{0\baselineskip}
\setlength{\beforeepigraphskip}{0\baselineskip}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Footnotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\ifxetex
\notbool{minimal}{
    \addtokomafont{footnote}{\addfontfeatures{Numbers=Lining}}      % numbers in footnotes
    %\addtokomafont{footnotelabel}{\addfontfeatures{Numbers=Lining}}  % numbers in footnote labels
    %\addtokomafont{footnotereference}{\addfontfeatures{Numbers=Lining}}  % numbers in footnote references
}{}
\fi

\raggedbottom
\deffootnote[1.5em]{1.5em}{\normalparindent}{\textsuperscript{\thefootnotemark}} % putting a space after footnotemark has undesirable side effects with footnotes that start with an empty line; instead use \xspace in the footnote definition below
\newlength{\normalparindent}
\AtBeginDocument{\setlength{\normalparindent}{\parindent}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Quotes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% quotes are indented at one side only.
\renewenvironment{quote}{\list{}{\rightmargin0pt\leftmargin8mm}%{\rightmargin\leftmargin}%
\item\relax}
{\endlist}

%% quotations are indented at one side only
%% there is no indentation at the beginning of the quote
\renewenvironment{quotation}
{\list{}{\listparindent 1.5em%\itemindent    \listparindent
%\rightmargin   \leftmargin
\parsep        \z@ \@plus\p@}%
\item\relax}
{\endlist}

\newenvironment{modquote}[1][6mm]% slightly less indented quote for hyphenation issues
  {\list{}{\leftmargin=#1\rightmargin=0mm}\item[]}%
  {\endlist}



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%
%    Language-specific settings
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% Must apear before biblatex and hyperref.

%% languages
\newcommand{\lsBookLanguageEnglish}{english}
\newcommand{\lsBookLanguageFrench}{french}
\newcommand{\lsBookLanguageSpanish}{spanish}
\newcommand{\lsBookLanguagePortuguese}{portuguese}
\newcommand{\lsBookLanguageGerman}{german}
\newcommand{\lsBookLanguageChinese}{chinese}

\notbool{babel}{
  \ifx\lsBookLanguage\lsBookLanguageChinese
	    \usepackage{xeCJK}%Chinese doesn't load babel, but xeCJK.
	\else
	 \ifbool{babelshorthands}{
	    \ifx\lsBookLanguage\lsBookLanguageEnglish
	            \usepackage[ngerman,main=\lsBookLanguage]{babel}
				\addto\extrasenglish{\languageshorthands{german}\useshorthands{"}}
	        \fi
		\ifx\lsBookLanguage\lsBookLanguageFrench
                    \usepackage[ngerman,main=\lsBookLanguage]{babel}
					\addto\extrasfrench{\languageshorthands{german}\useshorthands{"}}
                \fi
		\ifx\lsBookLanguage\lsBookLanguageSpanish
                    \usepackage[ngerman,main=\lsBookLanguage,es-minimal]{babel}
					\addto\extrasspanish{\languageshorthands{german}\useshorthands{"}}
                \fi
		\ifx\lsBookLanguage\lsBookLanguageGerman
                    \usepackage[ngerman]{babel}
                \fi
		\ifx\lsBookLanguage\lsBookLanguagePortuguese
                    \usepackage[ngerman,main=\lsBookLanguage]{babel}
                    \addto\extrasportuges{\languageshorthands{german}\useshorthands{"}}
                \fi
	   }{%else babelshorthands
		\ifx\lsBookLanguage\lsBookLanguageSpanish
                    %the Spanish option does not work out of the box
                    \usepackage[\lsBookLanguage,es-minimal]{babel}
                \else
                    \usepackage[\lsBookLanguage]{babel}
            }
     \fi%Close language=chinese
}{}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Citations
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage[
	natbib=true,
	style=langsci-unified,
	%refsection=chapter,
	maxbibnames=99,
	uniquename=false,
	mincrossrefs=99,
	maxcitenames=2,
	isbn=false,
	autolang=hyphen,
	\ifbool{resetcapitals}{language=english,}{}
	backend=\lsBiblatexBackend,
	indexing=cite
]{biblatex}

%% DOIs are handled after hyperref.
\defbibheading{references}{\chapter{References}\sloppy}
\defbibheading{english}{\chapter{References}\sloppy}
\defbibheading{french}{\chapter{Références bibliographiques}\sloppy}
\defbibheading{spanish}{\chapter{Referencias bibliográficas}\sloppy}
\defbibheading{german}{\chapter{Literaturverzeichnis}\sloppy}
\defbibheading{portuguese}{\chapter{Referências}\sloppy}
\defbibheading{chinese}{\chapter{参考文献}\sloppy}

%% penalties against widows and orphans in bibliography
%% http://tex.stackexchange.com/questions/297705/atbeginenvironment-does-not-work-with-natbib/297721#297721
\apptocmd{\thebibliography}{%
\clubpenalty\@M
\@clubpenalty\clubpenalty
\widowpenalty\@M
}
{}{}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Floats
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{floatrow}	% For adjusting the position of the caption (default is below).
\floatsetup[table]{capposition=top} 	% As for tables, the caption appears above.
%% This sets the default for the positioning of floats
\usepackage[figuresright]{rotating}
\usepackage{booktabs} % for nicer lines

\renewcommand{\fps@figure}{htbp}
\renewcommand{\fps@table}{htbp}

%% floats
%% http://mintaka.sdsu.edu/GF/bibliog/latex/floats.html
%% Alter some LaTeX defaults for better treatment of figures:

%% See p.105 of "TeX Unbound" for suggested values.
%% See pp. 199-200 of Lamport's "LaTeX" book for details.
%% General parameters, for ALL pages:
\renewcommand{\topfraction}{0.9}	% max fraction of floats at top
\renewcommand{\bottomfraction}{0.8}	% max fraction of floats at bottom
%% Parameters for TEXT pages (not float pages):
\setcounter{topnumber}{2}
\setcounter{bottomnumber}{2}
\setcounter{totalnumber}{4} % 2 may work better
\setcounter{dbltopnumber}{2} % for 2-column pages
\renewcommand{\dbltopfraction}{0.9}	% fit big float above 2-col. text
\renewcommand{\textfraction}{0.07}	% allow minimal text w. figs
%% Parameters for FLOAT pages (not text pages):
\renewcommand{\floatpagefraction}{0.7}	% require fuller float pages
%% N.B.: floatpagefraction MUST be less than topfraction !!
\renewcommand{\dblfloatpagefraction}{0.7}	% require fuller float pages

\usepackage{setspace}
\usepackage{caption}
\captionsetup{font={stretch=.8,small},width=.8\textwidth}
\setcapindent{0pt}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Appendices
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\appto\appendix{%
	%% format of the appendix title page
	\renewcommand*{\chapterformat}{%
		\mbox{\chapapp~\thechapter\autodot:\enskip}%
	}
	%% format of the TOC entry
	\renewcommand{\addchaptertocentry}[2]{
		\Ifstr{#1}{}{%
		\addtocentrydefault{chapter}{}{#2}%
		}{%
		\addtocentrydefault{chapter}{}{\chapapp~#1: #2}%
		}%
	}
}


% For papers that have appendices, a replacement for \appendix.
% Usage: \begin{paperappendix} \section{Title} ... \end{paperappendix}
\newenvironment{paperappendix}
  {%
    \let\section\appendixsection
    \let\subsection\appendixsubsection
  }
  {}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Indexes
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage{index} %% Wie im Stylefile, aber ohne \MakeUppercase
\renewenvironment{theindex}{%
  \edef\indexname{\the\@nameuse{idxtitle@\@indextype}}%
  \if@twocolumn
	  \@restonecolfalse
  \else
	  \@restonecoltrue
  \fi
  \columnseprule \z@
  \columnsep 35\p@
  \twocolumn[%
	  \@makeschapterhead{\indexname}%
	  \ifx\index@prologue\@empty\else
		  \index@prologue
		  \bigskip
	  \fi
  ]%        \@mkboth{\MakeUppercase\indexname}%                {\MakeUppercase\indexname}%
  \@mkboth{\indexname}%
		  {\indexname}%
  \thispagestyle{plain}%
  \parindent\z@
  \parskip\z@ \@plus .3\p@\relax
  \let\item\@idxitem
  \providecommand*\seealso[2]{\emph{\lsSeeAlsoTerm{}} ##1}
}{%
  \if@restonecol
	  \onecolumn
  \else
	  \clearpage
  \fi
}

% \AtBeginDocument{% FK 16-Jan-19: It is unclear why this was set. It conflicts with TikZ externalisation.
	\makeindex
	\newindex{lan}{ldx}{lnd}{\lsLanguageIndexTitle}
	\newindex{sbj}{sdx}{snd}{\lsSubjectIndexTitle}
	\renewindex{default}{adx}{and}{\lsNameIndexTitle} %biblatex can only deal with the default index
% 	\newindex{wrd}{wdx}{wnd}{Expression index}
% 	\newindex{rwrd}{rdx}{rnd}{Reverse expression index}
% }

\indexproofstyle{\setlength{\overfullrule}{0pt}\raggedright\footnotesize}

%% \index inside footnote
\ifbool{infn}{
  \def\infn#1#2{% 	\hyperpage{#2}n#1%  99n2
  % 	\hyperpage{#2}*%   99*
          \hyperpage{#2}\textsuperscript{#1}%  99²
  }%
  \newcommand{\footnoteindex}[2]{\index{#2|infn{#1}}}
  \newcommand{\footnoteindex@sbj}[2]{\index[sbj]{#2|infn{#1}}}
  \newcommand{\footnoteindex@lan}[2]{\index[lan]{#2|infn{#1}}}
  \newcommand{\footnoteindex@wrd}[2]{\index[wrd]{#2|infn{#1}}}
}{%else
  \def\infn#1#2{% 	\hyperpage{#2}n#1%  99n2
  % 	\hyperpage{#2}*%   99*
          \hyperpage{#2}\textsuperscript{#1}%  99²
  }%
  \newcommand{\footnoteindex}[2]{\index{#2}}
  \newcommand{\footnoteindex@sbj}[2]{\index[sbj]{#2}}
  \newcommand{\footnoteindex@lan}[2]{\index[lan]{#2}}
  \newcommand{\footnoteindex@wrd}[2]{\index[wrd]{#2}}
}

% Author index
\newcommand{\ia}[1]{%
  \if@noftnote%
    \index{#1}%
    \else%
    \edef\tempnumber{\thefootnote}%
    \expandafter\footnoteindex\expandafter{\tempnumber}{#1}%
    % \index{#1|fn{\thefootnote}}%
  \fi%
}

% Subject index
\newcommand{\is}[1]{%
  \if@noftnote%
    \index[sbj]{#1}%
    \else%
    \edef\tempnumber{\thefootnote}%
    \expandafter\footnoteindex@sbj\expandafter{\tempnumber}{#1}%
    %\indexftn{#1}{\value{footnotemark}}%
  \fi%
}

% Language index
\newcommand{\il}[1]{%
  \if@noftnote
    \index[lan]{#1}%
    \else%
    \edef\tempnumber{\thefootnote}%
    \expandafter\footnoteindex@lan\expandafter{\tempnumber}{#1}%
  \fi%
}

% \iflsDraft
%   \usepackage{showidx} 	% Doesn't work with multiple indexes?
% \fi

%% this is required by authorindex
% \newif\ifshowindex \showindexfalse
\usepackage{authorindex}

\providecommand{\isi}[1]{\is{#1}#1}
\providecommand{\iai}[1]{\ia{#1}#1}
\providecommand{\ili}[1]{\il{#1}#1}

\ifbool{showindex}{
    \RequirePackage{soul}
%     \RequirePackage[noadjust]{marginnote}
    \renewcommand{\marginpar}{\marginnote}
    \let\isold\is
    \let\ilold\il
    \let\iaold\ia
    \renewcommand{\isi}[1]{\sethlcolor{lsSoftGreen}\hl{#1}\isold{#1}}
    \renewcommand{\is}[1]{{\tikzstyle{notestyleraw} += [text width=1.5cm]\todo[color=lsSoftGreen,size=\scriptsize]{\tiny#1}\isold{#1}}}
    \renewcommand{\ili}[1]{\sethlcolor{yellow}\hl{#1}\ilold{#1}}
    \renewcommand{\il}[1]{{\tikzstyle{notestyleraw} += [text width=1.5cm]\todo[color=yellow,size=\scriptsize]{\tiny#1}\ilold{#1}}}
    \renewcommand{\iai}[1]{\sethlcolor{pink}\hl{#1}\iaold{#1}}
    \renewcommand{\ia}[1]{{\tikzstyle{notestyleraw} += [text width=1.5cm]\todo[color=pink,size=\scriptsize]{\tiny#1}\iaold{#1}}}
}{}

% integrate see also in multiple indexes
\def\igobble#1 {}
\newcommand{\langsciseealso}{\par\addvspace{.1\baselineskip}\hspace*{1.4cm}\hangindent=1.4cm\seealso}
\newcommand{\ilsa}[2]{\il{#1@\igobble | langsciseealso{#2}}}
\newcommand{\issa}[2]{\is{#1@\igobble | langsciseealso{#2}}}
\newcommand{\iasa}[2]{\ia{#1{}@\igobble | langsciseealso{#2}}}


\newcommand{\name}[3][]{%add person names to text and author index
#2 %output first name
\ifstrempty{#1}{%if no optional argument present
\ia{#3, #2}%add lastname, firstname to index
}{%if optional argument present
\ia{#1}% add optional argument to index
}%
#3}%output last name in text

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Hyperref
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\usepackage[
	bookmarks=true,bookmarksopen=true,bookmarksopenlevel=1,
	bookmarksdepth=5,
	bookmarksnumbered=true,
	hyperindex=true,
	breaklinks=true,
	draft=false,
	plainpages=false,
	pdfborder={0 0 0},
	pdfusetitle=true,
	pdfkeywords={},
	pdfpagelayout=TwoPageRight,% first page is separate
	hyperfootnotes=false,
	%ps2pdf=true
	]{hyperref}

%% gets rid of the warnings:
%% Failed to convert input string to UTF16
%% http://tex.stackexchange.com/questions/66722/tex-live-2012-xelatex-moderncv-error-failed-to-convert-input-string-to-utf1
\hypersetup{unicode,pdfencoding=auto,bookmarksopenlevel=0}

%% Reset sections in the Backmatter to the top level.
\usepackage{bookmark}
\apptocmd{\backmatter}
         {\bookmarksetup{startatroot}}
         {}
         {%
           \AtEndDocument{\typeout{langscibook Warning:}
                          \typeout{It was not possible to set option 'staratroot'}
                          \typeout{for bookmarks in the backmatter.}}
         }

%% autoref (part of hyperref)
\ifx\lsBookLanguage\lsBookLanguageEnglish
\renewcommand{\partautorefname}{Part}%
\renewcommand{\chapterautorefname}{Chapter}%
\renewcommand{\sectionautorefname}{Section}%
\renewcommand{\subsectionautorefname}{Section}%
\renewcommand{\subsubsectionautorefname}{Section}%
\renewcommand{\figureautorefname}{Figure}%
\renewcommand{\tableautorefname}{Table}%
\renewcommand{\Hfootnoteautorefname}{Footnote}%
\fi

\providecommand{\sectref}[1]{§\ref{#1}}
\providecommand{\chapref}[1]{Chapter~\ref{#1}}
\providecommand{\partref}[1]{Part~\ref{#1}}
\providecommand{\tabref}[1]{Table~\ref{#1}}
\providecommand{\figref}[1]{Figure~\ref{#1}}
\providecommand{\lsSeeAlsoTerm}{see also}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Collection (edited volume):
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%% for papers of collections:
\newcommand{\lsCollectionPaperAbstract}{Put abstract here with \string\abstract.}
\newcommand{\abstract}[1]{\renewcommand{\lsCollectionPaperAbstract}{#1}}
\newcommand{\ChapterDOI}[1]{\renewcommand{\lsChapterDOI}{#1}}

%% to be used below chapter titles
\newcommand{\chaptersubtitle}[1]{
  \vspace*{-2ex}
  {\Large #1}
  \chapterheadendvskip
  \@afterindentfalse
  \@afterheading
}

\ifbool{collection}{
    \notbool{biblatex}{
            \ClassError{langsci/langscibook}{Collection option not compatible with plain BibTeX. Please use biblatex option}{}
    }{}

    \AtBeginDocument{% for the citation in the footer
            \renewcommand{\newlineCover}{}
            \renewcommand{\newlineSpine}{}
            \edef\lsCollectionTitle{\@title\ifx\@subtitle\empty\else{: \@subtitle}\fi}% \edef immediately expands \@title
            \edef\lsCollectionEditor{\@author}
            \addbibresource{collection_tmp.bib}
            \if@partsw\AfterEndDocument{\typeout{langscibook Warning: You are in includeonly mode.}\typeout{The bibliographical information for the chapters in this volume have not been updated}}\else% Check for \includeonly mode
            \newwrite\tempfile% open temporary bib file
            \immediate\openout\tempfile=collection_tmp.bib
            \fi
    }%end AtBeginDocument
    % Only touch the \tempfile if we are NOT in \includeonly mode, prevent flushing of the file
    \AtEndDocument{\if@partsw\else\immediate\closeout\tempfile\fi}% close temporary bib file

    %% customize \tableofcontents
    \renewcommand{\@dotsep}{2.5}		% space between dots
    \renewcommand{\@tocrmarg}{1.5em}	% right margin for leader
    \renewcommand{\@pnumwidth}{1.5em}	% width of page numbers
    \ifbool{collectiontoclong}{}{\setcounter{tocdepth}{0}}
    \DeclareTOCStyleEntry%Settings for parts in the TOC of collected volumes
      [
        pagenumberbox={\csname @gobble\endcsname},
        raggedentrytext=true,
        linefill={\hfill}
      ]{tocline}{part}

    \usepackage{chngcntr}
    \counterwithin{figure}{chapter}
    \counterwithin{table}{chapter}
    \ifbool{lsFloatCounterWithoutChapter}{
      \renewcommand{\thefigure}{\arabic{figure}}
      \renewcommand{\thetable}{\arabic{table}}
      \renewcommand{\theequation}{\arabic{equation}}
    }{}

    \NewDocumentCommand{\includepaper}{m}{%
        \bgroup
		  \renewcommand{\newlineCover}{\\}
          \renewcommand{\documentclass}[2][]{}%
          \renewcommand{\usepackage}[2][]{}%
          \renewenvironment{document}{\begingroup}{\endgroup}
          \includepaper@body
          \begin{refsection}
            \renewcommand{\lsCollectionPaperCitationText}{\fullciteFooter{#1footer}}
            \include{#1}%
            \if@partsw\relax\else% This switch controls whether the included chapter is in the range of \includeonly. It's from source2e.
              \addtocounter{page}{-1}
              \edef\lsCollectionPaperLastPage{\thepage}	% \lsCollectionPaperFirstPage is defined in \includepaper@body
              \addtocounter{page}{1}
              \lsCollectionMetadataToBibliography{#1}
            \fi% If the paper is not within \includeonly, don't do anything.
          \end{refsection}
        \egroup
    } %end NewDocumentCommand
}{}

\newcommand{\lsCollectionMetadataToBibliography}[1]{%
  \renewcommand{\newlineCover}{}
  \renewcommand{\newlineSpine}{}
  \renewcommand{\newlineTOC}{}  
  %% write bib entry to file
  \immediate\write\tempfile{@incollection{#1,author={\authorToBib},title={{\expandonce{\titleTemp}}},booktitle={{\expandonce{\lsCollectionTitle}}},editor={\lsCollectionEditor},publisher={Language Science Press.},Address={Berlin},year={\lsYear},pages={\lsCollectionPaperFirstPage --\lsCollectionPaperLastPage},doi={\lsChapterDOI},keywords={withinvolume}}}
  \immediate\write\tempfile{@incollection{#1footer,author={\authorToBib},title={{\expandonce{\titleTemp}}},booktitle={{\expandonce{\lsCollectionTitle}}},editor={\lsCollectionEditor},publisher={Language Science Press.},Address={Berlin},year={\lsYear},pages={\lsCollectionPaperFirstPage --\lsCollectionPaperLastPage},doi={\lsChapterDOI},options={dataonly=true}}}
}

\newcommand{\titleToHead}{}
\newcommand{\titleTemp}{}
\newcommand{\titleToToC}{}
\newcommand{\authorToBib}{}

\newcommand{\lsCollectionPaperHeaderTitle}{%
  \renewcommand{\newlineCover}{}
  \renewcommand{\newlineTOC}{}
  \if@mainmatter%Only send the chapter num to head if in mainmatter.
    \thechapter\hspace{0.5em}\titleToHead\else\titleToHead
  \fi
}

\newcommand{\includepaper@body}{%
        \RenewDocumentCommand{\title}{O{##2} m O{##2}}{
            \renewcommand{\titleToHead}{##1}
            \renewcommand{\titleTemp}{##2}
            \renewcommand{\titleToToC}{##3}
        }
        \RenewDocumentCommand{\author}{O{##2} m}{
          \renewcommand{\authorToBib}{##1}
          \renewcommand{\@author}{##2}
        }
        \renewcommand*{\thesection}{\arabic{section}}
        \RedeclareSectionCommand
            [afterskip=1.15\baselineskip plus .1\baselineskip minus .167\baselineskip]
            {chapter}
        \renewcommand{\maketitle}{%
            % With \setchapterpreamble from scrbook, we ensure that the author(s)
            % and their affiliation(s) are part of the \chapter block.
            \setchapterpreamble[u]{\ResolveAffiliations{\@author}\\}
            \chapter
            [tocentry={\titleToToC~\newline{\normalfont\ResolveAffiliations{\@author}}}]
            {\titleTemp}
            \begin{quote}
                \small\lsCollectionPaperAbstract
            \end{quote}
            % Save the current page for the bibliographical information in the 
            % chapter footer
            \global\edef\lsCollectionPaperFirstPage{\thepage}
            \renewcommand{\newlineCover}{}
            \renewcommand{\newlineTOC}{\\}
            \ifoot[\lsCollectionPaperCitation]{%
                \ifbool{draft}{Draft of \today, \currenttime}{}
                    }
            \ifx\@epigram\empty
              \else {\epigraph{\@epigram\\[-2\baselineskip]}{\@epigramsource}
                \epigram{}\epigramsource{}}
            \fi
            \enlargethispage{-1\baselineskip}
        }
        \ohead{}
        \lehead{\ResolveAffiliations[output affiliation=false,
                                     output authors font=\normalfont\slshape,
                                     separator between two={~\&~},
                                     separator between multiple={,~},
                                     separator between final two={~\&~}
                                    ]{\@author}}
        \rohead{\lsCollectionPaperHeaderTitle}
        % The following ensure that a chapter is treated as a heading, which
        % controls page break penalties and indentation following the heading.
        \@afterindentfalse\@afterheading
}

\newcommand{\lsCollectionPaperFooterTitle}{\titleTemp}

\newcommand{\lsCollectionPaperAuthor}{{%
    \renewcommand{\newlineTOC}{}
    \renewcommand{\newlineCover}{\\[0.5ex]}
    \AuthorAffiliation\Large\@author}
}

\newcommand{\lsCollectionPaperCitation}{\scalebox{1.2}{%
    \includechapterfooterlogo}%
    % \hspace{0.8em}%
    \hfill%
    \parbox[b]{.87\textwidth}{\linespread{0.8}\lsChapterFooterSize\normalfont\lsCollectionPaperCitationText \lsLicenseInformation{ccby}}
}

\ifbool{paper}{
	\renewcommand{\lsCollectionPaperCitation}{Change with \string\papernote}
}{} %end paper

\newcommand{\lsCollectionPaperCitationText}{\string\lsCollectionPaperCitationText.}

\newcommand{\papernote}[1]{
    \renewcommand{\lsCollectionPaperCitation}{#1}
}

\providecommand\shorttitlerunninghead[1]{\rohead{\thechapter\hspace{.5em} #1}}

% In output==paper, the title is generated with the info
% collected by the commands above.
\ifbool{paper}{
    \usepackage{chngcntr}
    \counterwithout{figure}{chapter}
    \counterwithout{table}{chapter}
    \includepaper@body
}{} %end paper


% A command that imports the files localpackages.tex, but only if output==paper
\NewDocumentCommand{\lsConditionalSetupForPaper}{O{localbibliography.bib}}
  {%
    \ifbool{lsImportPackagesWhenStandalone}
           {\input{localpackages.tex}
            \input{localhyphenation.tex}
            \input{localcommands.tex}
            \addbibresource{#1}}
           {}
  }


%writeout page numbers for separation of chapters

% \usepackage{newfile}
% \newoutputstream{pages}
% \openoutputfile{\jobname.pgs}{pages}
% \newcommand{\writechapterpages}{\addtostream{pages}{\thepage}}
% \AtEndDocument{
%  \closeoutputstream{pages}
% }



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Localisation
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\ifx\lsBookLanguage\lsBookLanguageFrench
    \renewcommand{\chapref}[1]{Chapitre~\ref{#1}}
    \renewcommand{\partref}[1]{Partie~\ref{#1}}
    \renewcommand{\tabref}[1]{Tableau~\ref{#1}}
    \renewcommand{\figref}[1]{Figure~\ref{#1}}
    \renewcommand{\lsSeeAlsoTerm}{voir aussi}
\fi

\ifx\lsBookLanguage\lsBookLanguageSpanish
    \renewcommand{\chapref}[1]{Capítulo~\ref{#1}}
    \renewcommand{\partref}[1]{Parte~\ref{#1}}
    \renewcommand{\tabref}[1]{Tabla~\ref{#1}}
    \renewcommand{\figref}[1]{Figura~\ref{#1}}
    \renewcommand{\lsSeeAlsoTerm}{véase también}
\fi

\ifx\lsBookLanguage\lsBookLanguageGerman
    \renewcommand{\chapref}[1]{Kapitel~\ref{#1}}
    \renewcommand{\partref}[1]{Teil~\ref{#1}}
    \renewcommand{\tabref}[1]{Tabelle~\ref{#1}}
    \renewcommand{\figref}[1]{Abbildung~\ref{#1}}
    \renewcommand{\lsSeeAlsoTerm}{siehe auch}
\fi

\ifx\lsBookLanguage\lsBookLanguagePortuguese
    \renewcommand{\chapref}[1]{Capítulo~\ref{#1}}
    \renewcommand{\partref}[1]{Parte~\ref{#1}}
    \renewcommand{\tabref}[1]{Tabela~\ref{#1}}
    \renewcommand{\figref}[1]{Figura~\ref{#1}}
    \renewcommand{\lsSeeAlsoTerm}{ver tambem}
\fi

\ifx\lsBookLanguage\lsBookLanguageChinese
    %%Fonts for Chinese typesetting. If booklanguage=chinese, then 
    %%xeCJK is loaded, which provides the font commands below.
    \setCJKmainfont[BoldFont = SourceHanSerifSC-Semibold.otf]{SourceHanSerifSC-Regular.otf}

    \setCJKsansfont[BoldFont = SourceHanSansSC-Bold.otf]{SourceHanSansSC-Regular.otf}
      
      %% Settings for Punctuation
      \xeCJKsetup{CheckFullRight=true}
      \xeCJKsetup{PunctStyle=CCT}
	
      %% Localisation strings
      \renewcommand{\sectionname}{节}  
      \renewcommand{\figurename}{图}  
      \renewcommand{\tablename}{表}
      \renewcommand{\contentsname}{目\hspace{1em}录}
      \renewcommand{\appendixname}{附录}
      %   \renewcommand{\chapref}[1]{}
      %   \renewcommand{\partref}[1]{}
      \renewcommand{\tabref}[1]{表~\ref{#1}}
      \renewcommand{\figref}[1]{图~\ref{#1}}
      \renewcommand{\sectref}[1]{节~\ref{#1}}
      \renewcommand*{\partformat}{第\zhdig{part}部分\hspace{20pt}}
      \renewcommand*{\partheadmidvskip}{}
      \renewcommand*{\chapterformat}{第\zhnum{chapter}章\hspace{20pt}}
      \renewcommand*{\raggedchapter}{\centering}
      \renewcommand*{\sectionformat}{\thesection\hspace{10pt}}
\fi

\newcommand{\lsIndexTitle}{Index}
\newcommand{\lsLanguageIndexTitle}{Language index}	% This can be changed according to the language.
\newcommand{\lsSubjectIndexTitle}{Subject index}
\newcommand{\lsNameIndexTitle}{Name index}
\newcommand{\lsPrefaceTitle}{Preface}
\newcommand{\lsAcknowledgementTitle}{Acknowledgments}
\newcommand{\lsAbbreviationsTitle}{Abbreviations}
\newcommand{\lsReferencesTitle}{references} % This aligns with \defbibheading

\ifx\lsBookLanguage\lsBookLanguageFrench
    \renewcommand{\lsIndexTitle}{Index}
    \renewcommand{\lsNameIndexTitle}{Index des auteurs cités}
    \renewcommand{\lsSubjectIndexTitle}{Index des termes}
    \renewcommand{\lsLanguageIndexTitle}{Index des langues}
    \renewcommand{\lsPrefaceTitle}{Préface}
    \renewcommand{\lsAcknowledgementTitle}{Remerciements}
    \renewcommand{\lsAbbreviationsTitle}{Liste des abréviations utilisées dans les gloses des exemples}
    \renewcommand{\lsReferencesTitle}{french}
    \ifbool{babel}{
        \renewcommand\frenchfigurename{Figure}
        \renewcommand\frenchtablename{Table}
    }{}
\fi

\ifx\lsBookLanguage\lsBookLanguageSpanish
    \renewcommand{\lsIndexTitle}{Índices}
    \renewcommand{\lsNameIndexTitle}{Índice nominal}
    \renewcommand{\lsSubjectIndexTitle}{Índice temático}
    \renewcommand{\lsLanguageIndexTitle}{Índice de idiomas}
    \renewcommand{\lsPrefaceTitle}{Prefacio}
    \renewcommand{\lsAcknowledgementTitle}{Agradecimientos}
    \renewcommand{\lsAbbreviationsTitle}{Abreviaciones}
    \renewcommand{\lsReferencesTitle}{spanish}
\fi

\ifx\lsBookLanguage\lsBookLanguageGerman
    \renewcommand{\lsIndexTitle}{Register}
    \renewcommand{\lsNameIndexTitle}{Autorenregister}
    \renewcommand{\lsSubjectIndexTitle}{Sachregister}
    \renewcommand{\lsLanguageIndexTitle}{Sprachregister}
    \renewcommand{\lsPrefaceTitle}{Vorwort}
    \renewcommand{\lsAcknowledgementTitle}{Danksagung}
    \renewcommand{\lsAbbreviationsTitle}{Abkürzungsverzeichnis}
    \renewcommand{\lsReferencesTitle}{german}
\fi

\ifx\lsBookLanguage\lsBookLanguagePortuguese
    \renewcommand{\lsIndexTitle}{Índices}
    \renewcommand{\lsNameIndexTitle}{Índice remissivo de autores citados}
    \renewcommand{\lsSubjectIndexTitle}{Índice remissivo temático}
    \renewcommand{\lsLanguageIndexTitle}{Índice remissivo de línguas}
    \renewcommand{\lsPrefaceTitle}{Prefácio}
    \renewcommand{\lsAcknowledgementTitle}{Agradecimentos}
    \renewcommand{\lsAbbreviationsTitle}{\colorbox{red}{Translation info for Abbv missing}}
    \renewcommand{\lsReferencesTitle}{portugese}
\fi

\ifx\lsBookLanguage\lsBookLanguageChinese
    \renewcommand{\lsIndexTitle}{索引}
    \renewcommand{\lsNameIndexTitle}{人名索引}
    \renewcommand{\lsSubjectIndexTitle}{术语索引}
    \renewcommand{\lsLanguageIndexTitle}{语言索引}
    \renewcommand{\lsPrefaceTitle}{前言}
    \renewcommand{\lsAcknowledgementTitle}{致谢}
    \renewcommand{\lsAbbreviationsTitle}{\colorbox{red}{Translation info for Abbv missing}}
\fi


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%    Miscellaneous
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newlength{\LSPTmp}
\ifbool{uniformtopskip}{}{% Donald Arseneau's automatic handling of page breaking from comp.text.tex: https://groups.google.com/d/topic/comp.text.tex/3eehwzortPg/discussion
    % With the optimisations from the memoir class. The memoir class has relative instead of absolute values.
    \newlength{\lsSaveValueTopSkip}
    \lsSaveValueTopSkip=\topskip
    \let\lsSaveValueTextTop\@texttop
    \let\lsSaveValueTextBottom\@textbottom
    \def\restorebottom{%
      \topskip=\lsSaveValueTopSkip
      \let\@texttop\lsSaveValueTextTop
      \let\@textbottom\lsSaveValueTextBottom
    }
    
    \def\sloppybottom{%
      \def\@textbottom{\vskip \z@ \@plus.0001fil \@minus .95\topskip}%
      \topskip=1\topskip \@plus 0.625\topskip \@minus .95\topskip%
      \def\@texttop{\vskip \z@ \@plus -0.625\topskip \@minus -0.95\topskip}%
    }
    \sloppybottom
}

\endinput
