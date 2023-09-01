%%
%% This is file `memoir.cls',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% memoir.dtx  (with options: `class')
%% 
%%   Author: Peter Wilson  (herries dot press at earthlink dot net)
%%           Herries Press
%%   Copyright 2001--2011 Peter R. Wilson
%%   Copyright 2013--     Lars Madsen
%%   Maintainer: Lars Madsen (daleif at math dot au dot dk)
%% 
%% 
%%   This work may be distributed and/or modified under the
%%   conditions of the LaTeX Project Public License, either
%%   version 1.3 of this license or (at your option) any
%%   later version.
%%   The latest version of the license is in
%%      http://www.latex-project.org/lppl.txt
%%   and version 1.3 or later is part of all distributions of
%%   LaTeX version 2003/06/01 or later.
%% 
%%   This work has the LPPL maintenance status "maintained".
%% 
%%   This work consists of the files listed in the README file.
%% 
\def\mem@atleast@kernel{2021/06/01}
\NeedsTeXFormat{LaTeX2e}[\mem@atleast@kernel]
\ProvidesClass{memoir}%
  [2023/08/21 v3.8.1 configurable book, report, article document class]
\newcommand\memversion{v3.8.1, 2023/08/21}
\providecommand\IfFormatAtLeastTF{\@ifl@t@r\fmtversion}
\IfFormatAtLeastTF{\mem@atleast@kernel}{}{
  \ClassError{memoir}{%
    Your LaTeX release is too old.\MessageBreak
    The memoir class requires at LaTeX format\MessageBreak
    from at least \mem@atleast@kernel\space  onwards. Please update your\MessageBreak
    entire LaTeX installation instead of manually updating\MessageBreak
    just memoir}{}
    \batchmode\read-1to\@tempa% evil mode engaged
}
\RequirePackage{xpatch}
\newcommand*{\@ptsize}{}
\newcommand*{\@memptsize}{}
\newlength{\onelineskip}
\newlength{\lxvchars}
\newlength{\xlvchars}
\newcount\@memcnta
\newcounter{@memmarkcntra}
\newif\if@restonecol
\newif\if@openright
  \@openrighttrue

\newif\if@openleft
  \@openleftfalse

\newif\if@mainmatter
  \@mainmattertrue

\newif\if@memoldfont
  \@memoldfontfalse

\newif\ifextrafontsizes
  \extrafontsizesfalse

\newcommand*{\@memerror}{\ClassError{memoir}}
\newcommand*{\@memwarn}{\ClassWarning{memoir}}

\newif\ifsamename
\newcommand{\nametest}[2]{%
  \samenamefalse%
  \begingroup%
  \def\@memtempa{#1}\def\@memtempb{#2}%
  \ifx \@memtempa\@memtempb%
    \endgroup%
    \samenametrue%
  \else%
    \endgroup%
  \fi}

\newif\ifm@m@And
\newif\ifm@m@Or
\newif\ifm@m@Xor

\newcommand{\kill@lastcounter}[1]{%
  \count\count10 \z@
  \advance\count10 \m@ne
  \expandafter\let\csname c@#1\endcsname\relax}

\newcommand{\@name@p@xdef}[1]{%
  \expandafter\protected@xdef\csname #1\endcsname}
\newcommand{\@name@unresp@xdef}[1]{%
  \expandafter\unrestored@protected@xdef\csname #1\endcsname}
\newcommand{\@namelet}[1]{%
  \expandafter\let\csname #1\endcsname}
\newcommand{\@namelongdef}[1]{%
  \long\expandafter\def\csname #1\endcsname}
\newcommand*{\memletcmdtxt}[2]{\expandafter\let\expandafter#1\csname#2\endcsname}
\newcommand*{\memlettxttxt}[1]{\expandafter\memletcmdtxt\csname#1\endcsname}
\newcommand*{\memlettxtcmd}[2]{\expandafter\let\csname#1\endcsname#2}
\newcommand{\@nameedef}[1]{%
  \expandafter\protected@edef\csname #1\endcsname}

\newcommand{\memjustarg}[1]{#1}
\newcommand{\memgobble}[1]{}

\newcommand\memsetmacroused[1]{%
  \@namedef{mem@macro@used@\expandafter\@gobble\string#1}{00}}
\newcommand\memsetmacrounused[1]{%
  \@namedef{mem@macro@used@\expandafter\@gobble\string#1}{01}}
\newcommand\memifmacroused[1]{%
  \if\@nameuse{mem@macro@used@\expandafter\@gobble\string#1}%
  \expandafter\@firstoftwo\else\expandafter\@secondoftwo\fi}

\newcommand\memsetlengthmin[3]{\ifdim#2<#3\setlength{#1}{#2}\else\setlength{#1}{#3}\fi}
\newcommand\memsetlengthmax[3]{\ifdim#2>#3\setlength{#1}{#2}\else\setlength{#1}{#3}\fi}

\ExplSyntaxOn
\IfFormatAtLeastTF{ 2022-06-01 }
{}
{
  \RequirePackage { xparse }
  \providecommand \ExpandArgs [1]
  { \cs_if_exist_use:c { exp_args:N #1 } }
}
\ExplSyntaxOff

\providecommand\NewHookWithArguments[2]{}
\ExplSyntaxOn
\@ifundefined{UseHookWithArguments}{
  \cs_new:Npn \UseHookWithArguments #1 #2 {
    \cs:w use_none: \prg_replicate:nn {#2} { n } \cs_end:
  }
}{}
\ExplSyntaxOff
\NewHook{memoir/subcaption/aftercounter}

\newcommand*{\@memfakeusepackage}[1]{%
  \@namelet{ver@#1.sty}\@empty}

\providecommand*{\EmulatedPackage}{}
\renewcommand*{\EmulatedPackage}[1]{%
  \@ifnextchar[{\@emulated@package{#1}}%
               {\@emulated@package{#1}[\@empty]}%]
}
\providecommand*{\EmulatedPackageWithOptions}{}
\renewcommand*{\EmulatedPackageWithOptions}[2]{%
  \PassOptionsToPackage{#1}{#2}%
  \EmulatedPackage{#2}%
}
\def\@emulated@package#1[#2]{%
  \expandafter\xdef\csname ver@#1.\@pkgextension\endcsname{#2}%
  \@ifundefined{opt@#1.\@pkgextension}%
    {\@namedef{opt@#1.\@pkgextension}{}}{}%
  \wlog{Package #1 \ifx\@empty#2\else[#2] \fi
        \if,\csname opt@#1.\@pkgextension\endcsname,\else
        (with options \csname opt@#1.\@pkgextension\endcsname) \fi
        emulated by \@currname.}%
}
\@onlypreamble\EmulatedPackage
\@onlypreamble\EmulatedPackageWithOptions
\@onlypreamble\@emulated@package

\newcommand*{\DisemulatePackage}[1]{%
  \@namelet{ver@#1.\@pkgextension}\relax}
\@onlypreamble\DisemulatePackage

\IfFormatAtLeastTF{2020/10/01}{
  \newcommand\AtBeginFile[2]{\def\temp{\AddToHook{file/#1/before}{#2}}\temp}
  \newcommand\AtEndFile[2]{\def\temp{\AddToHook{file/#1/after}{#2}}\temp}

  \newcommand\AtBeginPackage[2]{\def\temp{\AddToHook{package/#1/before}{#2}}\temp}
  \newcommand\AtEndPackage[2]{\def\temp{\AddToHook{package/#1/after}{#2}}\temp}
  \newcommand{\RequireAtEndPackage}[2]{%
    \@ifpackageloaded{#1}{#2}{\AtEndPackage{#1}{#2}}}

  \newcommand\AtBeginClass[2]{\def\temp{\AddToHook{class/#1/before}{#2}}\temp}
  \newcommand\AtEndClass[2]{\def\temp{\AddToHook{class/#1/after}{#2}}\temp}
  \newcommand{\RequireAtEndClass}[2]{%
    \@ifclassloaded{#1}{#2}{\AtEndClass{#1}{#2}}}

}{% back to the code for older formats
  \ifcsname InputIfFileExists \endcsname% looking for an explicit space
                                  % here aka the robust version
    \DeclareRobustCommand \InputIfFileExists[2]{%
      \IfFileExists{#1}%
      {%
        \expandafter\@swaptwoargs\expandafter
        {\@filef@und\m@matendf{#1}\killm@matf{#1}}{%
          #2\@addtofilelist{#1}\m@matbeginf{#1}\@@input%
        }%
      }%
    }
  \else
    % Old definition
    \renewcommand{\InputIfFileExists}[2]{%
      \IfFileExists{#1}%
      {#2\@addtofilelist{#1}\m@matbeginf{#1}%
        \@@input \@filef@und
        \m@matendf{#1}%
        \killm@matf{#1}}}
  \fi

  \newcommand{\m@matbeginf}[1]{\@ifundefined{#1-m@mfb}{}%
    {\@nameuse{#1-m@mfb}}}
  \newcommand{\m@matendf}[1]{\@ifundefined{#1-m@mfe}{}%
    {\@nameuse{#1-m@mfe}}}

 %% \ifetex
  \newcommand*{\killm@matf}[1]{%
    \ifnum 6=\currentgrouptype
      \ifvmode
        \expandafter\expandafter\expandafter\@firstoftwo
        \expandafter\expandafter\expandafter\noalign
      \fi
    \fi
    \@firstofone
    {\@namelet{#1-m@mfb}\relax
     \@namelet{#1-m@mfe}\relax
    }%
  }
 %% \fi

  \newcommand{\AtBeginFile}[2]{\@ifundefined{#1-m@mfb}%
    {\@namedef{#1-m@mfb}{#2}}%
    {\expandafter\addtodef\csname #1-m@mfb\endcsname{}{#2}}}
  \newcommand{\AtEndFile}[2]{\@ifundefined{#1-m@mfe}%
    {\@namedef{#1-m@mfe}{#2}}%
    {\expandafter\addtodef\csname #1-m@mfe\endcsname{}{#2}}}

  \newcommand{\AtBeginPackage}[2]{%
    \AtBeginFile{#1.\@pkgextension}{#2}}
  \newcommand{\AtEndPackage}[2]{%
    \AtEndFile{#1.\@pkgextension}{#2}}
  \newcommand{\RequireAtEndPackage}[2]{%
    \@ifpackageloaded{#1}{#2}%
    {\AtEndFile{#1.\@pkgextension}{#2}}}

  \newcommand{\AtBeginClass}[2]{%
    \AtBeginFile{#1.\@clsextension}{#2}}
  \newcommand{\AtEndClass}[2]{%
    \AtEndFile{#1.\@clsextension}{#2}}
  \newcommand{\RequireAtEndClass}[2]{%
    \@ifclassloaded{#1}{#2}%
    {\AtEndFile{#1.\@clsextension}{#2}}}


 % end of else part of format check
}

\newcommand{\phantomsection}{}

 \renewcommand*{\nofiles}{%
   \@fileswfalse%  flag for suppressing \immediate \writes
   \typeout{No auxiliary output files.^^J}%
   \long\def\protected@write##1##2##3%
     {\write\m@ne{}\if@nobreak\ifvmode\nobreak\fi\fi}%
   }

\newcommand*{\memsetcounter}[2]{\setcounter{#1}{#2}}
\AtBeginDocument{\immediate\write\@mainaux{%
  \string\providecommand*{\string\memsetcounter}[2]{}}}

\def\bs{\texttt{\char`\\}}
\ifx\l@nohyphenation\undefined
  \newlanguage\l@nohyphenation
\fi
\DeclareRobustCommand{\meta}[1]{%
  \ensuremath\langle
  \ifmmode \expandafter \nfss@text \fi
  {%
    \meta@font@select
    \edef\meta@hyphen@restore
      {\hyphenchar\the\font\the\hyphenchar\font}%
    \hyphenchar\font\m@ne
    \language\l@nohyphenation
    #1\/%
    \meta@hyphen@restore
  }\ensuremath\rangle
}
\def\meta@font@select{\itshape}

\DeclareRobustCommand{\marg}[1]{%
  {\ttfamily\char`\{}\meta{#1}{\ttfamily\char`\}}}
\DeclareRobustCommand{\oarg}[1]{%
  {\ttfamily\char`\[}\meta{#1}{\ttfamily\char`\]}}
\DeclareRobustCommand{\parg}[1]{%
  {\ttfamily\char`\(}\meta{#1}{\ttfamily\char`\)}}
\DeclareRobustCommand{\cs}[1]{\texttt{\char`\\#1}}
\newcommand{\cmdprint}[1]{\texttt{\string#1}}
\newcommand{\cmd}[1]{\cmdprint{#1}%
  \index{\expandafter\@gobble\string#1?\string\cmdprint{\string#1}}}

\RequirePackage{iftex}[2019/11/07]
\edef\wo@dmacro{%
  \string m\string a\string c\string r\string o\string :%
}

\def\wo@difmacro@begingroup#1{%
  \begingroup
    \edef\x{%
      \noexpand\wo@dparsemacro\meaning#1\wo@dmacro\string -%
    }%
    \x\@nil{#1}%
}

\begingroup
  \edef\x{\endgroup
    \def\noexpand\wo@dparsemacro##1\wo@dmacro##2\string -}%
\x#3\@nil#4{%
  \ifx\\#3\\%
    \endgroup
    \@memwarn{\string `\string #4\string ' is not a macro}%
    \expandafter\@gobble
  \else
    \expandafter\@firstofone
  \fi
}

\def\addtodef{\@star@or@long\wo@daddtodef}
\long\def\wo@daddtodef#1#2#3{%
  \wo@difmacro@begingroup{#1}{%
    \@temptokena{#2}%
    \toks@\expandafter{#1#3}%
    \edef\x{\endgroup
         \l@ngrel@x\def\noexpand#1{\the\@temptokena \the\toks@}}%
    \x
  }%
}

\def\addtoiargdef{\@star@or@long\wo@daddtoiargdef}
\long\def\wo@daddtoiargdef#1#2#3{%
  \wo@difmacro@begingroup{#1}{%
    \@temptokena{#2}%
    \toks@\expandafter{#1{##1}#3}%
    \edef\x{\endgroup
       \l@ngrel@x\def\noexpand#1####1{\the\@temptokena \the\toks@}}%
    \x
  }%
}

%%%%%%%%%%%%%%%% Michael Downes' patchcmd 2000/07/31 v1.03 %%%%%%%%
\newcommand{\patchcommand}[1]{%
  \expandafter\patchcmd@a\meaning#1??->@\@nil#1%
}
\long\def\patchcmd@a#1#2#3->#4#5\@nil#6{%
  \ifx @#4\relax \patchcmdError#6#1%
    \expandafter\@gobbletwo % discard the other two arguments
  \else
    \if l#2\toks@{\patchcmd@e{}#6}% l in this position means \long
    \else \toks@{\patchcmd@e*#6}%   not \long
    \fi
    \patchcmd@b #3@#4#5 ? ? ? \@nil#6%
    \expandafter\the\expandafter\toks@
  \fi}
\def\patchcmd@b#1:#2@#3#4 #5#6 #7 #8\@nil#9{%
  \if \ifx @#7@\expandafter
      \ifx\csname #6\endcsname#9T\else F\fi\else F\fi T%
    \toks@\expandafter{\expandafter\patchcommand\csname #6 \endcsname}%
  \else
    \ifx @#2@% No arguments
      \toks@\expandafter{\the\toks@ 0}%
    \else
      \patchcmd@c 0#2{\string##}0%
    \fi
  \fi}
\def\patchcmd@c#1#2#3{%
  \if\string###2%      % yes it's a # token
    \ifodd 0#31 % and it's followed by a number
      \if 0#3\patchcmd@d#1\fi % number=0? then we're done
    \else \patchcmd@d D% # not a number: must be a delimited arg
    \fi
  \else \patchcmd@d D% not a # token: must be a delmited arg
  \fi
  \patchcmd@c#3}
\def\patchcmd@d#1{%
  \if D#1%
%%%    \PackageError{patchcmd}{Cannot change a macro that has
%%%      delimited arguments}\@ehd
    \@memerror{%
      Cannot change a macro that has delimited arguments}{\@ehd}
  \else
    \toks@\expandafter{\the\toks@ #1}%
  \fi
  \begingroup
  \aftergroup\@gobble
  \let\patchcmd@c\endgroup}
\def\patchcmd@e#1#2#3#4#5{%
  \begingroup
  \edef\@##1{%
    \@temptokena\noexpand\expandafter{%
      \noexpand#2%
        \ifnum#3>0 {####1}\ifnum#3>1 {####2}\ifnum#3>2 {####3}%
        \ifnum#3>3 {####4}\ifnum#3>4 {####5}\ifnum#3>5 {####6}%
        \ifnum#3>6 {####7}\ifnum#3>7 {####8}\ifnum#3>8 {####9}%
        \fi\fi\fi\fi\fi\fi\fi\fi\fi
      ##1%
    }%
  }
  \@{#5}%
  \edef\@##1{\endgroup
    \noexpand\renewcommand#1\noexpand#2\ifcase#3 \else [#3]\fi
    {##1\the\@temptokena}}%
  \@{#4}%
}
\long\def\patchcmdError#1#2{%
  \begingroup
  \toks@{Not redefinable}%
  \ifcat\relax\noexpand#1% Is it a control sequence?
    \begingroup
    \let#1=?\ifx ?\relax % Is it "\relax"?
      \endgroup % accept current value of \toks@
    \else \endgroup
      \if\ifx\relax#1u\else #2\fi u%
        \toks@{Not defined}%
      \fi
    \fi
  \fi
  \edef\@{\endgroup
%%%    \noexpand\PackageError{patchcmd}{%
%%%      \the\toks@: \string#1}\noexpand\@ehd}%
    \noexpand\@memerror{%
      \the\toks@: \string#1}\noexpand\@ehd}%
  \@}

%%%%%%%%%%%%%%%%%%%%% end of patchcmd code %%%%%%%%%%%%%%%%%%%%%%%%%%%

%%\@memfakeusepackage{patchcmd}

\newcommand*{\memRTLleftskip}{\leftskip}
\newcommand*{\memRTLrightskip}{\rightskip}
\newcommand*{\memRTLvleftskip}{\vleftskip}
\newcommand*{\memRTLvrightskip}{\vrightskip}
\newcommand*{\memRTLraggedright}{\raggedright}
\newcommand*{\memRTLraggedleft}{\raggedleft}
\newcommand*{\memRTLmainraggedright}{\raggedright}
\newcommand*{\memRTLmainraggedleft}{\raggedleft}

 % secret extra option for testing stuff in the wild
 % caution 1: patching inside \ifmem@devmode ... \fi requires that all
 % if statements in the patch are blanced
 % caution 2: pathing inside \mem@devmode@run{ ... }{} does not work
 % if the search pattern contains #<num>
 % thus added both variants
\newif\ifmem@devmode
\let\mem@devmode@run\@secondoftwo
\DeclareOption{dev-mode}{\let\mem@devmode@run\@firstoftwo\mem@devmodetrue}

\@ifundefined{stockwidth}{\newdimen{\stockheight}}{}
\@ifundefined{stockwidth}{\newdimen{\stockwidth}}{}
\newlength{\trimtop}
\newlength{\trimedge}

\newcommand*{\stockdbill}     {\stockheight=7in    \stockwidth=3in}
\newcommand*{\stockstatement} {\stockheight=8.5in  \stockwidth=5.5in}
\newcommand*{\stockexecutive} {\stockheight=10.5in \stockwidth=7.25in}
\newcommand*{\stockletter}    {\stockheight=11in   \stockwidth=8.5in}
\newcommand*{\stockold}       {\stockheight=12in   \stockwidth=9in}
\newcommand*{\stocklegal}     {\stockheight=14in   \stockwidth=8.5in}
\newcommand*{\stockledger}    {\stockheight=17in   \stockwidth=11in}
\newcommand*{\stockbroadsheet}{\stockheight=22in   \stockwidth=17in}

\newcommand*{\stockpottvo}      {\stockheight=6.25in \stockwidth=4in}
\newcommand*{\stockfoolscapvo}  {\stockheight=6.75in \stockwidth=4.25in}
\newcommand*{\stockcrownvo}     {\stockheight=7.5in  \stockwidth=5in}
\newcommand*{\stockpostvo}      {\stockheight=8in    \stockwidth=5in}
\newcommand*{\stocklargecrownvo}{\stockheight=8in    \stockwidth=5.25in}
\newcommand*{\stocklargepostvo} {\stockheight=8.25in \stockwidth=5.25in}
\newcommand*{\stocksmalldemyvo} {\stockheight=8.5in  \stockwidth=5.675in}
\newcommand*{\stockdemyvo}      {\stockheight=8.75in  \stockwidth=5.675in}
\newcommand*{\stockmediumvo}    {\stockheight=9in     \stockwidth=5.75in}
\newcommand*{\stocksmallroyalvo}{\stockheight=9.25in  \stockwidth=6.175in}
\newcommand*{\stockroyalvo}     {\stockheight=10in    \stockwidth=6.25in}
\newcommand*{\stocksuperroyalvo}{\stockheight=10.25in \stockwidth=6.75in}
\newcommand*{\stockimperialvo}  {\stockheight=11in    \stockwidth=7.5in}

\newcommand*{\stockmcrownvo}      {\stockheight=186mm \stockwidth=123mm}
\newcommand*{\stockmlargecrownvo} {\stockheight=198mm \stockwidth=129mm}
\newcommand*{\stockmdemyvo}       {\stockheight=216mm \stockwidth=138mm}
\newcommand*{\stockmsmallroyalvo} {\stockheight=234mm \stockwidth=156mm}

\newcommand*{\stockao}  {\stockheight=1189mm \stockwidth=841mm}
\newcommand*{\stockai}  {\stockheight=841mm \stockwidth=594mm}
\newcommand*{\stockaii} {\stockheight=594mm \stockwidth=420mm}
\newcommand*{\stockaiii}{\stockheight=420mm \stockwidth=297mm}
\newcommand*{\stockaiv} {\stockheight=297mm \stockwidth=210mm}
\newcommand*{\stockav}  {\stockheight=210mm \stockwidth=148mm}
\newcommand*{\stockavi} {\stockheight=148mm \stockwidth=105mm}
\newcommand*{\stockavii}{\stockheight=105mm \stockwidth=74mm}

\newcommand*{\stockbo}  {\stockheight=1414mm \stockwidth=1000mm}
\newcommand*{\stockbi}  {\stockheight=1000mm \stockwidth=707mm}
\newcommand*{\stockbii} {\stockheight=707mm \stockwidth=500mm}
\newcommand*{\stockbiii}{\stockheight=500mm \stockwidth=353mm}
\newcommand*{\stockbiv} {\stockheight=353mm \stockwidth=250mm}
\newcommand*{\stockbv}  {\stockheight=250mm \stockwidth=176mm}
\newcommand*{\stockbvi} {\stockheight=176mm \stockwidth=125mm}
\newcommand*{\stockbvii}{\stockheight=125mm \stockwidth=88mm}

\newcommand*{\pagedbill}     {\paperheight=7in    \paperwidth=3in}
\newcommand*{\pagestatement} {\paperheight=8.5in  \paperwidth=5.5in}
\newcommand*{\pageexecutive} {\paperheight=10.5in \paperwidth=7.25in}
\newcommand*{\pageletter}    {\paperheight=11in   \paperwidth=8.5in}
\newcommand*{\pageold}       {\paperheight=12in   \paperwidth=9in}
\newcommand*{\pagelegal}     {\paperheight=14in   \paperwidth=8.5in}
\newcommand*{\pageledger}    {\paperheight=17in   \paperwidth=11in}
\newcommand*{\pagebroadsheet}{\paperheight=22in   \paperwidth=17in}

\newcommand*{\pagepottvo}      {\paperheight=6.25in \paperwidth=4in}
\newcommand*{\pagefoolscapvo}  {\paperheight=6.75in \paperwidth=4.25in}
\newcommand*{\pagecrownvo}     {\paperheight=7.5in  \paperwidth=5in}
\newcommand*{\pagepostvo}      {\paperheight=8in    \paperwidth=5in}
\newcommand*{\pagelargecrownvo}{\paperheight=8in    \paperwidth=5.25in}
\newcommand*{\pagelargepostvo} {\paperheight=8.25in \paperwidth=5.25in}
\newcommand*{\pagesmalldemyvo} {\paperheight=8.5in  \paperwidth=5.675in}
\newcommand*{\pagedemyvo}      {\paperheight=8.75in  \paperwidth=5.675in}
\newcommand*{\pagemediumvo}    {\paperheight=9in     \paperwidth=5.75in}
\newcommand*{\pagesmallroyalvo}{\paperheight=9.25in  \paperwidth=6.175in}
\newcommand*{\pageroyalvo}     {\paperheight=10in    \paperwidth=6.25in}
\newcommand*{\pagesuperroyalvo}{\paperheight=10.25in \paperwidth=6.75in}
\newcommand*{\pageimperialvo}  {\paperheight=11in    \paperwidth=7.5in}

\newcommand*{\pagemcrownvo}      {\paperheight=186mm \paperwidth=123mm}
\newcommand*{\pagemlargecrownvo} {\paperheight=198mm \paperwidth=129mm}
\newcommand*{\pagemdemyvo}       {\paperheight=216mm \paperwidth=138mm}
\newcommand*{\pagemsmallroyalvo} {\paperheight=234mm \paperwidth=156mm}

\newcommand*{\pageao}  {\paperheight=1189mm \paperwidth=841mm}
\newcommand*{\pageai}  {\paperheight=841mm \paperwidth=594mm}
\newcommand*{\pageaii} {\paperheight=594mm \paperwidth=420mm}
\newcommand*{\pageaiii}{\paperheight=420mm \paperwidth=297mm}
\newcommand*{\pageaiv} {\paperheight=297mm \paperwidth=210mm}
\newcommand*{\pageav}  {\paperheight=210mm \paperwidth=148mm}
\newcommand*{\pageavi} {\paperheight=148mm \paperwidth=105mm}
\newcommand*{\pageavii}{\paperheight=105mm \paperwidth=74mm}

\newcommand*{\pagebo}  {\paperheight=1414mm \paperwidth=1000mm}
\newcommand*{\pagebi}  {\paperheight=1000mm \paperwidth=707mm}
\newcommand*{\pagebii} {\paperheight=707mm \paperwidth=500mm}
\newcommand*{\pagebiii}{\paperheight=500mm \paperwidth=353mm}
\newcommand*{\pagebiv} {\paperheight=353mm \paperwidth=250mm}
\newcommand*{\pagebv}  {\paperheight=250mm \paperwidth=176mm}
\newcommand*{\pagebvi} {\paperheight=176mm \paperwidth=125mm}
\newcommand*{\pagebvii}{\paperheight=125mm \paperwidth=88mm}

\DeclareOption{a0paper}{\stockao}
\DeclareOption{a1paper}{\stockai}
\DeclareOption{a2paper}{\stockaii}
\DeclareOption{a3paper}{\stockaiii}
\DeclareOption{a4paper}{\stockaiv}
\DeclareOption{a5paper}{\stockav}
\DeclareOption{a6paper}{\stockavi}
\DeclareOption{a7paper}{\stockavii}
\DeclareOption{b0paper}{\stockbo}
\DeclareOption{b1paper}{\stockbi}
\DeclareOption{b2paper}{\stockbii}
\DeclareOption{b3paper}{\stockbiii}
\DeclareOption{b4paper}{\stockbiv}
\DeclareOption{b5paper}{\stockbv}
\DeclareOption{b6paper}{\stockbvi}
\DeclareOption{b7paper}{\stockbvii}
\DeclareOption{mcrownvopaper}{\stockmcrownvo}
\DeclareOption{mlargecrownvopaper}{\stockmlargecrownvo}
\DeclareOption{mdemyvopaper}{\stockmdemyvo}
\DeclareOption{msmallroyalvopaper}{\stockmsmallroyalvo}

\DeclareOption{dbillpaper}{\stockdbill}
\DeclareOption{statementpaper}{\stockstatement}
\DeclareOption{executivepaper}{\stockexecutive}
\DeclareOption{letterpaper}{\stockletter}
\DeclareOption{oldpaper}{\stockold}
\DeclareOption{legalpaper}{\stocklegal}
\DeclareOption{ledgerpaper}{\stockledger}
\DeclareOption{broadsheetpaper}{\stockbroadsheet}

\DeclareOption{pottvopaper}{\stockpottvo}
\DeclareOption{foolscapvopaper}{\stockfoolscapvo}
\DeclareOption{crownvopaper}{\stockcrownvo}
\DeclareOption{postvopaper}{\stockpostvo}
\DeclareOption{largecrownvopaper}{\stocklargecrownvo}
\DeclareOption{largepostvopaper}{\stocklargepostvo}
\DeclareOption{smalldemyvopaper}{\stocksmalldemyvo}
\DeclareOption{demyvopaper}{\stockdemyvo}
\DeclareOption{mediumvopaper}{\stockmediumvo}
\DeclareOption{smallroyalvopaper}{\stocksmallroyalvo}
\DeclareOption{royalvopaper}{\stockroyalvo}
\DeclareOption{superroyalvopaper}{\stocksuperroyalvo}
\DeclareOption{imperialvopaper}{\stockimperialvo}

\DeclareOption{ebook}
   {\setlength\stockheight {9in}%
    \setlength\stockwidth  {6in}}

\newif\ifmemlandscape
  \memlandscapefalse
\DeclareOption{landscape}{\memlandscapetrue}
\DeclareOption{portrait}{\memlandscapefalse}

\renewcommand*{\@ptsize}{0}
\renewcommand*{\@memptsize}{10}
\DeclareOption{9pt}{\renewcommand*{\@ptsize}{9}\renewcommand*{\@memptsize}{9}}
\DeclareOption{10pt}{\renewcommand*{\@ptsize}{0}\renewcommand*{\@memptsize}{10}}
\DeclareOption{11pt}{\renewcommand*{\@ptsize}{1}\renewcommand*{\@memptsize}{11}}
\DeclareOption{12pt}{\renewcommand*{\@ptsize}{2}\renewcommand*{\@memptsize}{12}}
\DeclareOption{14pt}{\renewcommand*{\@ptsize}{4}\renewcommand*{\@memptsize}{14}}
\DeclareOption{17pt}{\renewcommand*{\@ptsize}{7}\renewcommand*{\@memptsize}{17}}
\DeclareOption{20pt}{\renewcommand*{\@ptsize}{20}\renewcommand*{\@memptsize}{20}}
\DeclareOption{25pt}{\renewcommand*{\@ptsize}{25}\renewcommand*{\@memptsize}{25}}
\DeclareOption{30pt}{\renewcommand*{\@ptsize}{30}\renewcommand*{\@memptsize}{30}}
\DeclareOption{36pt}{\renewcommand*{\@ptsize}{36}\renewcommand*{\@memptsize}{36}}
\DeclareOption{48pt}{\renewcommand*{\@ptsize}{48}\renewcommand*{\@memptsize}{48}}
\DeclareOption{60pt}{\renewcommand*{\@ptsize}{60}\renewcommand*{\@memptsize}{60}}

\newif\if@nyptsizeopt
  \@nyptsizeoptfalse
\providecommand*{\anyptfilebase}{mem}
\providecommand*{\anyptsize}{10}
\DeclareOption{*pt}{\@nyptsizeopttrue}

\DeclareOption{twoside}{\@twosidetrue  \@mparswitchtrue}
\DeclareOption{oneside}{\@twosidefalse \@mparswitchfalse}
\DeclareOption{onecolumn}{\@twocolumnfalse}
\DeclareOption{twocolumn}{\@twocolumntrue}
\newif\ifdraftdoc\draftdocfalse
\setlength{\overfullrule}{\z@}
\DeclareOption{final}{\setlength{\overfullrule}{\z@}
                      \draftdocfalse
                      \msdocfalse}
\DeclareOption{draft}{\setlength\overfullrule{5pt}%
                      \draftdoctrue
                      \msdocfalse}
\newif\ifmsdoc
  \msdocfalse
\DeclareOption{ms}{%
  \msdoctrue
  \draftdocfalse
  \setlength\overfullrule{\z@}
}

\newif\ifshowtrims
  \showtrimsfalse
\DeclareOption{showtrims}{\showtrimstrue}

\newif\ifartopt
  \artoptfalse
\DeclareOption{article}{\artopttrue}

\DeclareOption{openright}{\@openrighttrue}
\DeclareOption{openany}{\@openrightfalse}
\DeclareOption{openleft}{\@openlefttrue}
\newcommand{\openright}{\@openrighttrue\@openleftfalse%
  \gdef\clearforchapter{\cleartorecto}}
\newcommand{\openany}{\@openrightfalse\@openleftfalse%
  \gdef\clearforchapter{\clearpage}}
\newcommand{\openleft}{\@openlefttrue
  \gdef\clearforchapter{\cleartoverso}}

\DeclareOption{leqno}{\input{leqno.clo}}
\DeclareOption{fleqn}{\input{fleqn.clo}}
\DeclareOption{openbib}{%
  \AtEndOfClass{%
    \renewcommand\@openbib@code{%
      \advance\leftmargin\bibindent
      \itemindent -\bibindent
      \listparindent \itemindent
      \parsep \z@
     }%
    \renewcommand\newblock{\par}}}

\DeclareOption{oldfontcommands}{\@memoldfonttrue}
\DeclareOption{extrafontsizes}{\extrafontsizestrue}

\newcommand\mem@settopoint[1]{\@settopoint{#1}}
\DeclareOption{fullptlayout}{\renewcommand\mem@settopoint{\@gobble}}

\ExecuteOptions{final,letterpaper,10pt,onecolumn,openright,twoside,
                portrait}
\ProcessOptions*

\ifmemlandscape
  \setlength\@tempdima  {\stockheight}
  \setlength\stockheight{\stockwidth}
  \setlength\stockwidth {\@tempdima}
\fi


\providecommand*{\memoirpostopthook}{}
  \memoirpostopthook

\def\cleartorecto{\clearpage\if@twoside \ifodd\c@page\else
  \hbox{}\thispagestyle{cleared}%
  \newpage\if@twocolumn\hbox{}\newpage\fi\fi\fi}

\def\cleartoverso{\clearpage\if@twoside
  \ifodd\c@page\hbox{}\thispagestyle{cleared}%
  \newpage\if@twocolumn\hbox{}\newpage\fi\fi\fi}


\if@openleft
  \openleft
\else
  \if@openright
    \openright
  \else
    \openany
  \fi
\fi

\newcommand*{\@ivpt}{4}
\newcommand*{\@xxxpt}{30}
\newcommand*{\@xxxvipt}{36}
\newcommand*{\@xlviiipt}{48}
\newcommand*{\@lxpt}{60}
\newcommand*{\@lxxiipt}{72}
\newcommand*{\@lxxxivpt}{84}
\newcommand*{\@xcvipt}{96}
\newcommand*{\@cviiipt}{108}
\newcommand*{\@cxxpt}{120}
\newcommand*{\@cxxxiipt}{132}

\providecommand*{\memfontfamily}{lmr}
\providecommand*{\memfontenc}{T1}
\providecommand*{\memfontpack}{lmodern}

\if@nyptsizeopt
  \newcommand*{\@nyptclofile}{\anyptfilebase\anyptsize.clo}
  \IfFileExists{\@nyptclofile}{\def\@memptsize{\anyptsize}}{%
    \@memerror{You have used the `*pt' option but \MessageBreak
               file \@nyptclofile\space can't be found}%
              {I'll use mem10.clo instead}
    \renewcommand*{\@nyptclofile}{mem10.clo}%
    \def\@memptsize{10}%
  }
  \renewcommand*{\@ptsize}{\@memptsize}
  \usefont{\memfontenc}{\memfontfamily}{m}{n}
  \input{\@nyptclofile}
  \usepackage{\memfontpack}\usepackage[\memfontenc]{fontenc}
\else
  \ifextrafontsizes
    \usefont{\memfontenc}{\memfontfamily}{m}{n}
    \input{mem\@memptsize.clo}
    \usepackage{\memfontpack}\usepackage[\memfontenc]{fontenc}
  \else
    \ifnum\@memptsize > 17\relax
      \@memerror{The `extrafontsizes' option is required to use \MessageBreak
                 the `\@memptsize pt' option}%
                {The 17pt option will be used instead}
      \input{mem17.clo}
    \else
      \ifnum\@ptsize = 9\relax
        \input{mem\@ptsize.clo}
      \else
        \input{mem1\@ptsize.clo}
      \fi
    \fi
  \fi
\fi

\newcommand{\captionsize}{\normalsize}
\setlength\lineskip{1\p@}
\setlength\normallineskip{1\p@}
\renewcommand{\baselinestretch}{}
\setlength\parskip{0\p@ \@plus \p@}
\@lowpenalty   51
\@medpenalty  151
\@highpenalty 301
\clubpenalty  1000
\widowpenalty 1000
\newcommand*{\setlxvchars}[1][\normalfont]{\begingroup
  #1
  \settowidth{\lxvchars}{abcdefghijklmnopqrstuvwxyz}%
  \setlength{\lxvchars}{2.042\lxvchars}%
  \addtolength{\lxvchars}{33.41pt}%
  \global\lxvchars=\lxvchars
  \endgroup}
\newcommand*{\setxlvchars}[1][\normalfont]{\begingroup
  #1
  \settowidth{\xlvchars}{abcdefghijklmnopqrstuvwxyz}%
  \setlength{\xlvchars}{1.415\xlvchars}%
  \addtolength{\xlvchars}{23.03pt}%
  \global\xlvchars=\xlvchars
  \endgroup}

\newcommand*{\setrectanglesize}[3]{%
  \nametest{#1}{*}%
  \ifsamename                           % H = *
    \nametest{#2}{*}%
    \ifsamename                         % W = *
      \@memerror{%
        The combination of argument values is ambiguous.\MessageBreak
        The lengths will be set to zero}{\@ehd}%
      \setlength{\@tempdima}{0pt}%
      \setlength{\@tempdimb}{0pt}%
    \else                               % W
      \nametest{#3}{*}%
      \ifsamename                       % r = *
        \setlength{\@tempdimb}{#2}%
        \setlength{\@tempdima}{\@tempdimb}%
      \else                             % r
        \setlength{\@tempdimb}{#2}%
        \setlength{\@tempdima}{#3\@tempdimb}%
      \fi
    \fi
  \else                                 % H
    \nametest{#2}{*}%
    \ifsamename                         % W = *
      \nametest{#3}{*}%
      \ifsamename                       % r = *
        \setlength{\@tempdima}{#1}%
        \setlength{\@tempdimb}{\@tempdima}%
      \else                             % r
        \setlength{\@tempdima}{#1}%
        \setlength{\@tempdimb}{#3\@tempdima}%
      \fi
    \else                               % W
      \setlength{\@tempdima}{#1}%
      \setlength{\@tempdimb}{#2}%
    \fi
  \fi}

\newcommand*{\setfillsize}[5]{%
  \nametest{#2}{*}%
  \ifsamename                                % C = *
    \nametest{#3}{*}%
    \ifsamename                              % L = *
      \nametest{#4}{*}%
      \ifsamename                            % R = *
        \@memerror{%
          The combination of argument values is ambiguous.\MessageBreak
          The lengths will be set to zero}{\@ehd}
        \setlength{\@tempdima}{0pt}%
        \setlength{\@tempdimb}{0pt}%
        \setlength{\@tempdimc}{0pt}%
      \else                                  % R
        \nametest{#5}{*}%
        \ifsamename                          % r = *
          \setlength{\@tempdimb}{#4}%
          \setlength{\@tempdima}{\@tempdimb}%
          \setlength{\@tempdimc}{#1}%
          \advance\@tempdimc -\@tempdima
          \advance\@tempdimc -\@tempdimb
        \else                                % r
          \setlength{\@tempdimb}{#4}%
          \setlength{\@tempdima}{#5\@tempdimb}%
          \setlength{\@tempdimc}{#1}%
          \advance\@tempdimc -\@tempdima
          \advance\@tempdimc -\@tempdimb
        \fi
      \fi
    \else                                    % L
      \nametest{#4}{*}%
      \ifsamename                            % R = *
        \nametest{#5}{*}%
        \ifsamename                          % r = *
          \setlength{\@tempdima}{#3}%
          \setlength{\@tempdimb}{\@tempdima}
          \setlength{\@tempdimc}{#1}%
          \advance\@tempdimc -\@tempdima
          \advance\@tempdimc -\@tempdimb
        \else                                % r
          \setlength{\@tempdima}{#3}%
          \setlength{\@tempdimb}{#5\@tempdima}
          \setlength{\@tempdimc}{#1}%
          \advance\@tempdimc -\@tempdima
          \advance\@tempdimc -\@tempdimb
        \fi
      \else                                  % R
        \setlength{\@tempdima}{#3}%
        \setlength{\@tempdimb}{#4}%
        \setlength{\@tempdimc}{#1}%
        \advance\@tempdimc -\@tempdima
        \advance\@tempdimc -\@tempdimb
      \fi
    \fi
  \else                                      % C is valued
    \nametest{#3}{*}%
    \ifsamename                              % L = *
      \nametest{#4}{*}%
      \ifsamename                            % R = *
        \nametest{#5}{*}%
        \ifsamename                          % r = *
          \setlength{\@tempdimc}{#2}%
          \setlength{\@tempdima}{#1}%
          \advance\@tempdima -\@tempdimc
          \@tempdima = 0.5\@tempdima
          \@tempdimb = \@tempdima
        \else                                % r (CODE PERHAPS FIXED)
          \setlength{\@tempdimc}{#2}         % C
          \setlength{\@tempdimb}{#1}         % T
          \advance\@tempdimb -\@tempdimc % T - C
          \@tempdima = 1000sp
          \setlength{\@tempdima}{#5\@tempdima}        % 1000r sp
          \advance\@tempdima by 1000sp   % 1000(1+r)sp
          \@tempcnta = \@tempdima        % 1000(1+r)
          \@tempdima = \@tempdimb        % T - C
          \divide\@tempdima by \@tempcnta  % (T-C)/1000(1+r) pts
          \@tempdima = 1000\@tempdima      % (T-C)/(1+r)  pts = L
          \advance\@tempdimb by -\@tempdima % = R
        \fi
      \else                                  % R
        \setlength{\@tempdimc}{#2}%
        \setlength{\@tempdimb}{#4}%
        \setlength{\@tempdima}{#1}%
        \advance\@tempdima -\@tempdimc
        \advance\@tempdima -\@tempdimb
      \fi
    \else                                    % L
      \nametest{#4}{*}%
      \ifsamename                            % R = *
        \setlength{\@tempdimc}{#2}%
        \setlength{\@tempdima}{#3}%
        \setlength{\@tempdimb}{#1}%
        \advance\@tempdimb -\@tempdimc
        \advance\@tempdimb -\@tempdima
      \else                                  % R
        \@memerror{%
          The combination of argument values is ambiguous.\MessageBreak
          The lengths will be set to zero}{\@ehd}%
        \setlength{\@tempdima}{0pt}%
        \setlength{\@tempdimb}{0pt}%
        \setlength{\@tempdimc}{#2}%
      \fi
    \fi
  \fi}

\newcommand{\setstocksize}[2]{%
  \setlength{\stockheight}{#1}%
  \setlength{\stockwidth}{#2}}
\newcommand{\settrims}[2]{%
  \setlength{\trimtop}{#1}%
  \setlength{\trimedge}{#2}}
\newcommand{\settrimmedsize}[3]{%
  \setrectanglesize{#1}{#2}{#3}%
  \setlength{\paperheight}{\@tempdima}%
  \setlength{\paperwidth}{\@tempdimb}}

\newcommand{\settypeblocksize}[3]{%
  \memsetmacroused\settypeblocksize%
  \setrectanglesize{#1}{#2}{#3}%
  \setlength{\textheight}{\@tempdima}%
  \setlength{\textwidth}{\@tempdimb}}

\newlength{\binding}
\newcommand*{\setbinding}[1]{\setlength{\binding}{#1}}
  \setbinding{0pt}

\newlength{\spinemargin}
\newlength{\foremargin}
\newcommand{\setlrmargins}[3]{%
  \memsetmacroused\setlrmargins%
  \advance\paperwidth -\binding
  \setfillsize{\paperwidth}{\textwidth}{#1}{#2}{#3}%
  \setlength{\textwidth}{\@tempdimc}%
  \setlength{\spinemargin}{\@tempdima}%
  \setlength{\foremargin}{\@tempdimb}%
  \advance\paperwidth \binding
  \advance\spinemargin \binding}

\newcommand{\setlrmarginsandblock}[3]{%
  \advance\paperwidth -\binding
  \setfillsize{\paperwidth}{*}{#1}{#2}{#3}%
  \setlength{\textwidth}{\@tempdimc}%
  \setlength{\spinemargin}{\@tempdima}%
  \setlength{\foremargin}{\@tempdimb}%
  \advance\paperwidth \binding
  \advance\spinemargin \binding}

\newlength{\uppermargin}
\newlength{\lowermargin}
\newcommand{\setulmargins}[3]{%
  \memsetmacroused\setulmargins%
  \setfillsize{\paperheight}{\textheight}{#1}{#2}{#3}%
  \setlength{\textheight}{\@tempdimc}%
  \setlength{\uppermargin}{\@tempdima}%
  \setlength{\lowermargin}{\@tempdimb}}

\newcommand{\setulmarginsandblock}[3]{%
  \setfillsize{\paperheight}{*}{#1}{#2}{#3}%
  \setlength{\textheight}{\@tempdimc}%
  \setlength{\uppermargin}{\@tempdima}%
  \setlength{\lowermargin}{\@tempdimb}}

\newlength{\headdrop}
\newcommand{\setheaderspaces}[3]{%
  \setfillsize{\uppermargin}{\headheight}{#1}{#2}{#3}%
  \setlength{\headheight}{\@tempdimc}%
  \setlength{\headdrop}{\@tempdima}%
  \setlength{\headsep}{\@tempdimb}}

\newcommand{\setheadfoot}[2]{%
  \setlength{\headheight}{#1}%
  \setlength{\footskip}{#2}}

\newcommand{\setcolsepandrule}[2]{%
  \setlength{\columnsep}{#1}%
  \setlength{\columnseprule}{#2}}

\newcommand{\setmarginnotes}[3]{%
  \memsetmacroused\setmarginnotes%
  \setlength{\marginparsep}{#1}%
  \setlength{\marginparwidth}{#2}%
  \setlength{\marginparpush}{#3}}

\newcommand\setfootins[2]{
  \setlength{\skip\footins}{#1}
  \setlength{\skip\footinsv@r}{#1}
  \setlength{\skip\@mpfootins}{#2}
  % not explicitly used
  \setlength{\skip\@mpfootinsv@r}{#2}
}

\settrimmedsize{\stockheight}{\stockwidth}{*}
\settrims{\z@}{\z@}

\setlength{\@tempdimb}{1.14\lxvchars}
\setlength\@tempdima{\paperwidth}
  \addtolength\@tempdima{-2in}
\if@twocolumn
  \ifdim\@tempdima>2\@tempdimb\relax
    \setlength\textwidth{2\@tempdimb}
  \else
    \setlength\textwidth{\@tempdima}
  \fi
\else
  \ifdim\@tempdima>\@tempdimb\relax
    \setlength\textwidth{\@tempdimb}
  \else
    \setlength\textwidth{\@tempdima}
  \fi
\fi
\mem@settopoint\textwidth

\setlength\@tempdima{\paperheight}
  \addtolength\@tempdima{-3.5in}
  \divide\@tempdima\baselineskip
\@tempcnta=\@tempdima
\setlength\textheight{\@tempcnta\baselineskip}
  \addtolength\textheight{\topskip}

\if@twoside
  \setlength\@tempdima       {\paperwidth}
  \addtolength\@tempdima     {-\textwidth}
  \setlength\oddsidemargin   {.4\@tempdima}
  \addtolength\oddsidemargin {-1in}
  \setlength\marginparwidth  {.6\@tempdima}
  \addtolength\marginparwidth{-\marginparsep}
  \addtolength\marginparwidth{-0.4in}
\else
  \setlength\@tempdima       {\paperwidth}
  \addtolength\@tempdima     {-\textwidth}
  \setlength\oddsidemargin   {.5\@tempdima}
  \addtolength\oddsidemargin {-1in}
  \setlength\marginparwidth  {.5\@tempdima}
  \addtolength\marginparwidth{-\marginparsep}
  \addtolength\marginparwidth{-0.8in} % don't know why this isn't .4
\fi
\ifdim\marginparwidth>2in
  \setlength\marginparwidth{2in}%
\fi
\mem@settopoint\oddsidemargin
\mem@settopoint\marginparwidth
\ifdim\marginparwidth<1pt \setlength\marginparwidth{1pt}\fi

\setlength\evensidemargin  {\paperwidth}
\addtolength\evensidemargin{-2in}
\addtolength\evensidemargin{-\textwidth}
\addtolength\evensidemargin{-\oddsidemargin}
\mem@settopoint\evensidemargin
\setlength\topmargin  {\paperheight}
\addtolength\topmargin{-2in}
\addtolength\topmargin{-\headheight}
\addtolength\topmargin{-\headsep}
\addtolength\topmargin{-\textheight}
\addtolength\topmargin{-\footskip}
\addtolength\topmargin{-.5\topmargin}
\mem@settopoint\topmargin

\setlength{\spinemargin}{\oddsidemargin}
\addtolength{\spinemargin}{1in}
\setlrmargins{\spinemargin}{*}{*}

\setlength{\uppermargin}{\topmargin}
\addtolength{\uppermargin}{1in}
\addtolength{\uppermargin}{\headheight}
\addtolength{\uppermargin}{\headsep}
\setulmargins{\uppermargin}{*}{*}

\newcommand*{\@memznegtest}[1]{%
  \ifdim#1>\z@\else
 %%%%   \@memerror{\protect#1\space is zero or negative}{\@ehd}%
    \@memwarn{\protect#1\space is zero or negative}%
  \fi}
\newcommand*{\@memnegtest}[1]{%
  \ifdim#1<\z@
%%%%    \@memerror{\protect#1\space is negative}{\@ehd}%
    \@memwarn{\protect#1\space is negative}%
  \fi}

\newcommand*{\m@mclassicht}{%
  \setlength{\@tempdima}{\textheight}%
  \divide\@tempdima \baselineskip
  \@tempcnta=\@tempdima
  \setlength{\textheight}{\@tempcnta\baselineskip}%
  \addtolength{\textheight}{\topskip}}

\newcommand*{\m@mlinesht}{%
  \setlength{\@tempdima}{\textheight}%
  \advance\@tempdima -\baselineskip
  \divide\@tempdima \baselineskip
  \@tempcnta=\@tempdima
  \setlength{\textheight}{\@tempcnta\baselineskip}%
  \addtolength{\textheight}{\topskip}}

\newcommand*{\m@mnearestht}{%
  \setlength{\@tempdima}{\textheight}%
  \advance\@tempdima -\topskip
  \advance\@tempdima 0.5\baselineskip
  \divide\@tempdima \baselineskip
  \@tempcnta=\@tempdima
  \setlength{\textheight}{\@tempcnta\baselineskip}%
  \addtolength{\textheight}{\topskip}}

\newcommand\mem@autoadjust@marginparwidth{%
  \if@twocolumn
    \memsetlengthmin\marginparwidth\spinemargin\foremargin
  \else
    \if@twoside
      \ifcase\m@mmpar@margin\relax% 0 - left
        \memsetlengthmin\marginparwidth\spinemargin\foremargin
      \or% 1 - right
        \memsetlengthmin\marginparwidth\spinemargin\foremargin
      \or% 2 - outer
        \setlength\marginparwidth{\foremargin}
      \or% 3 - inner
        \setlength\marginparwidth{\spinemargin}
      \fi
    \else % oneside
      \ifnum\m@mmpar@margin=0% left
        \setlength\marginparwidth{\spinemargin}
      \else% right
        \setlength\marginparwidth{\foremargin}
      \fi
    \fi
  \fi
  \addtolength\marginparwidth{-2\marginparsep}
  \ifdim\marginparwidth<1pt\setlength\marginparwidth{1pt}\fi%
}

\newcommand\mem@reset@used@macros{%
  \memsetmacrounused\setmarginnotes
  \memsetmacrounused\settypeblocksize
  \memsetmacrounused\setulmargins
  \memsetmacrounused\setlrmargins
}

\newcommand*{\checkthelayout}[1][classic]{%
  \@memnegtest{\trimedge}
  \@memnegtest{\trimtop}
  \@memznegtest{\stockwidth}
  \@memznegtest{\paperwidth}
  \@memznegtest{\textwidth}
%%%  \@memznegtest{\spinemargin}
  \@memnegtest{\spinemargin}
%%%  \@memznegtest{\foremargin}
  \@memnegtest{\foremargin}
  \@memznegtest{\marginparsep}
  \@memznegtest{\marginparwidth}
  \@memznegtest{\stockheight}
  \@memznegtest{\paperheight}
  \@memznegtest{\textheight}
%%%  \@memznegtest{\uppermargin}
  \@memnegtest{\uppermargin}
%%%  \@memznegtest{\lowermargin}
  \@memnegtest{\lowermargin}
%%%  \@memznegtest{\headheight}
  \@memnegtest{\headheight}
%%%  \@memznegtest{\headsep}
  \@memnegtest{\headsep}
%%%  \@memznegtest{\footskip}
  \@memnegtest{\footskip}
  \nametest{#1}{classic}%
  \ifsamename
    \m@mclassicht
  \else
    \nametest{#1}{lines}%
    \ifsamename
      \m@mlinesht
    \else
      \nametest{#1}{nearest}%
      \ifsamename
        \m@mnearestht
      \else
        \nametest{#1}{fixed}
        \ifsamename
        \else%    not classic, lines, nearest, or fixed
          \@memerror{Optional argument is not one of:\MessageBreak
                     classic, fixed, lines, or nearest. \MessageBreak
                     I will assume the default}%
                    {\@ehc}%
        \fi
      \fi
    \fi
  \fi
  \setulmargins{\uppermargin}{*}{*}
  \@tempdimb = -1pt
  \@tempdima=\stockwidth
  \advance\@tempdima -\trimedge
  \advance\@tempdima -\paperwidth
  \ifdim\@tempdima<\@tempdimb
    \@tempdima = -\@tempdima
    \@memerror{\protect\paperwidth\space (\the\paperwidth) and/or
                        \protect\trimedge\space (\the\trimedge)
                        are too large for \protect\stockwidth\space (\the\stockwidth)
                        by \the\@tempdima}%
                       {\@ehd}
  \fi
  \@tempdima = \paperwidth
  \advance\@tempdima -\foremargin
  \advance\@tempdima -\textwidth
  \advance\@tempdima -\spinemargin
  \ifdim\@tempdima<\@tempdimb
    \@tempdima = -\@tempdima
    \@memerror{\protect\spinemargin\space (\the\spinemargin) and/or
                        \protect\textwidth\space (\the\textwidth) and/or
                        \protect\foremargin\space (\the\foremargin)
                        are too large for \protect\paperwidth\space (\the\paperwidth)
                        by \the\@tempdima}%
                       {\@ehd}
  \fi
  \@tempdima = \stockheight
  \advance\@tempdima -\trimtop
  \advance\@tempdima -\paperheight
  \ifdim\@tempdima<\@tempdimb
    \@tempdima = -\@tempdima
    \@memerror{\protect\paperheight\space (\the\paperheight) and/or
                        \protect\trimtop\space (\the\trimtop)
                        are too large for \protect\stockheight\space (\the\stockheight)
                        by \the\@tempdima}%
                       {\@ehd}
  \fi
  \@tempdima = \paperheight
  \advance\@tempdima -\uppermargin
  \advance\@tempdima -\textheight
  \advance\@tempdima -\lowermargin
  \ifdim\@tempdima<\@tempdimb
    \@tempdima = -\@tempdima
    \@memerror{\protect\uppermargin\space (\the\uppermargin) and/or
                        \protect\textheight\space (\the\textheight) and/or
                        \protect\lowermargin\space (\the\lowermargin)
                        are too large for \protect\paperheight\space (\the\paperheight)
                        by \the\@tempdima}%
                       {\@ehd}
  \fi
  \@tempdima = \uppermargin
  \advance\@tempdima -\headheight
  \advance\@tempdima -\headsep
  \ifdim\@tempdima<\@tempdimb
    \@tempdima = -\@tempdima
    \@memerror{\protect\headheight\space (\the\headheight) and/or
                        \protect\headsep\space (\the\headsep)
                        are too large for \protect\uppermargin\space (\the\uppermargin)
                        by \the\@tempdima}%
                       {\@ehd}
  \fi
  \@tempdima = \lowermargin
  \advance\@tempdima -\footskip
  \ifdim\@tempdima<\z@
    \@tempdima = -\@tempdima
    \@memerror{\protect\footskip\space (\the\footskip)
                        is too large for \protect\lowermargin\space (\the\lowermargin)
                        by \the\@tempdima}%
                       {\@ehd}
  \fi}

\newcommand*{\fixthelayout}{%
  \topmargin = \trimtop
    \advance\topmargin \uppermargin
    \advance\topmargin -\headsep
    \advance\topmargin -\headheight
    \advance\topmargin -1in\relax
  \oddsidemargin = \stockwidth
    \advance\oddsidemargin -\trimedge
    \advance\oddsidemargin -\paperwidth
    \advance\oddsidemargin \spinemargin
    \advance\oddsidemargin -1in\relax
  \evensidemargin = \trimedge
    \advance\evensidemargin \foremargin
    \advance\evensidemargin -1in\relax
  \mem@settopoint\textwidth
  \mem@settopoint\oddsidemargin
  \mem@settopoint\evensidemargin
  \fixheaderwidths
  \memifmacroused\setmarginnotes{}{\mem@autoadjust@marginparwidth}
  \mem@reset@used@macros
}

\newcommand\settypeoutlayoutunit[1]{
  \nametest{#1}{pt}
  \ifsamename
    \def\mem@tl@unit{#1}
    \def\mem@tl@unitperpt{1.0}
  \else
    \nametest{#1}{pc}
    \ifsamename
      \def\mem@tl@unit{#1}
      \def\mem@tl@unitperpt{0.083333}
    \else
      \nametest{#1}{in}
      \ifsamename
        \def\mem@tl@unit{#1}
        \def\mem@tl@unitperpt{0.013837}
      \else
        \nametest{#1}{mm}
        \ifsamename
          \def\mem@tl@unit{#1}
          \def\mem@tl@unitperpt{0.351459}
        \else
          \nametest{#1}{cm}
          \ifsamename
            \def\mem@tl@unit{#1}
            \def\mem@tl@unitperpt{0.0351459}
          \else
            \nametest{#1}{bp}
            \ifsamename
              \def\mem@tl@unit{#1}
              \def\mem@tl@unitperpt{0.996264}
            \else
              \nametest{#1}{dd}
              \ifsamename
                \def\mem@tl@unit{#1}
                \def\mem@tl@unitperpt{0.9345718}
              \else
                \nametest{#1}{cc}
                \ifsamename
                  \def\mem@tl@unit{#1}
                  \def\mem@tl@unitperpt{0.0778809}
                \else
                  \@memerror{Unknown unit '#1' not suitable for layout listing}{}
                \fi
              \fi
            \fi
          \fi
        \fi
      \fi
    \fi
  \fi
}
\settypeoutlayoutunit{pt}
\newcommand\mem@typeouttwolengths[4]{
  % #1 = text before
  % #2 = first length
  % #3 = text between
  % #4 = second length
  \setlength\@tempdimc{\mem@tl@unitperpt #2}
  \edef\l@first{\strip@pt\@tempdimc}%
  \setlength\@tempdimc{\mem@tl@unitperpt #4}
  \edef\l@second{\strip@pt\@tempdimc}%
  \typeout{#1: \l@first\mem@tl@unit\space#3\space\l@second\mem@tl@unit}
}
\newcommand\mem@typeoutonelength[2]{
  % #1 = text before
  % #2 = first length
  \setlength\@tempdimc{\mem@tl@unitperpt #2}
  \edef\l@first{\strip@pt\@tempdimc}%
  \typeout{#1: \l@first\mem@tl@unit}
}
\newcommand*{\typeoutlayout}{%
  \typeout{}
  \typeout{******************************************************}
 %   \typeout{Stock height and width:
 %                  \the\stockheight\space by \the\stockwidth}
 %   \typeout{Top and edge trims:
 %                  \the\trimtop\space and \the\trimedge}
 %   \typeout{Page height and width:
 %                  \the\paperheight\space by \the\paperwidth}
 %   \typeout{Text height and width:
 %                  \the\textheight\space by \the\textwidth}
 %   \typeout{Spine and edge margins:
 %                  \the\spinemargin\space and \the\foremargin}
 %   \typeout{Upper and lower margins:
 %                  \the\uppermargin\space and \the\lowermargin}
 %   \typeout{Headheight and headsep:
 %                  \the\headheight\space and \the\headsep}
 %   \typeout{Footskip:
 %                  \the\footskip}
 %   \typeout{Columnsep and columnseprule:
 %                  \the\columnsep\space and \the\columnseprule}
 %   \typeout{Marginparsep and marginparwidth:
 %                  \the\marginparsep\space and \the\marginparwidth}
 %   \typeout{Sidecapsep and sidecapwidth:
 %                   \the\sidecapsep\space and \the\sidecapwidth}
 %   \typeout{Sidebarhsep and sidebarwidth:
 %                   \the\sidebarhsep\space and \the\sidebarwidth}
 %   \typeout{Sidebarvsep and sidebartopsep:
 %                   \the\sidebarvsep\space and \the\sidebartopsep}
 %   \typeout{Sidebarheight:
 %                   \the\dimen\sideins}
 %   \typeout{Sidefoothsep and sidefootwidth:
 %                   \the\sidefoothsep\space and \the\sidefootwidth}
 %   \typeout{Sidefootvsep and sidefootheight:
 %                   \the\sidefootvsep\space and \the\sidefootheight}
  \mem@typeouttwolengths{Stock height and width}{\stockheight}{by}{\stockwidth}
  \mem@typeouttwolengths{Top and edge trims}{\trimtop}{and}{\trimedge}
  \mem@typeouttwolengths{Page height and width}{\paperheight}{by}{\paperwidth}
  \mem@typeouttwolengths{Text height and width}{\textheight}{by}{\textwidth}
  \mem@typeouttwolengths{Spine and edge margins}{\spinemargin}{and}{\foremargin}
  \mem@typeouttwolengths{Upper and lower margins}{\uppermargin}{and}{\lowermargin}
  \mem@typeouttwolengths{Headheight and headsep}{\headheight}{and}{\headsep}
  \mem@typeoutonelength{Footskip}{\footskip}
  \mem@typeouttwolengths{Columnsep and columnseprule}{\columnsep}{and}{\columnseprule}
  \mem@typeouttwolengths{Marginparsep and marginparwidth}{\marginparsep}{and}{\marginparwidth}
  \mem@typeouttwolengths{Sidecapsep and sidecapwidth}{\sidecapsep}{and}{\sidecapwidth}
  \mem@typeouttwolengths{Sidebarhsep and sidebarwidth}{\sidebarhsep}{and}{\sidebarwidth}
  \mem@typeouttwolengths{Sidebarvsep and sidebartopsep}{\sidebarvsep}{and}{\sidebartopsep}
  \mem@typeoutonelength{Sidebarheight}{\dimen\sideins}
  \mem@typeouttwolengths{Sidefoothsep and sidefootwidth}{\sidefoothsep}{and}{\sidefootwidth}
  \mem@typeouttwolengths{Sidefootvsep and sidefootheight}{\sidefootvsep}{and}{\sidefootheight}
  \typeout{******************************************************}
  \typeout{}}

\newcommand*{\checkandfixthelayout}[1][classic]{%
  \checkthelayout[#1]%
  \fixthelayout
  \typeoutlayout}

\newcommand\mem@fixpagelayout{%
  \@ifundefined{pdfpageheight}{}{\pdfpageheight=\the\stockheight}
  \@ifundefined{pdfpagewidth}{}{\pdfpagewidth=\the\stockwidth}
  \@ifundefined{pageheight}{}{\pageheight=\the\stockheight}
  \@ifundefined{pagewidth}{}{\pagewidth=\the\stockwidth}
  \@ifundefined{pdfvorigin}{}{\ifdim\pdfvorigin=0pt\pdfvorigin=1in\fi}
  \@ifundefined{pdfhorigin}{}{\ifdim\pdfhorigin=0pt\pdfhorigin=1in\fi}
  \ifluatex\else
    \ifxetex\else
      \ifpdf\else
        \AtBeginDvi{\special{papersize=\the\stockwidth,\the\stockheight}}
      \fi
    \fi
  \fi
}

\AtBeginDocument{\mem@fixpagelayout}
\let\refixpagelayout\mem@fixpagelayout

\newcommand*{\fixpdflayout}{%
  \ClassWarning{memoir}{As of 2018, \string\fixpdflayout\ is no longer used}
 % \pdfpageheight=\the\stockheight
 % \pdfpagewidth=\the\stockwidth
 % \ifxetex\else
 % \ifdim\pdfvorigin=0pt\pdfvorigin=1in\fi
 % \ifdim\pdfhorigin=0pt\pdfhorigin=1in\fi
 % \fi
}
\newcommand*{\fixdvipslayout}{%
  \ClassWarning{memoir}{As of 2018, \string\fixdvipslayout\ is no longer used}
  %\AtBeginDvi{\special{papersize=\the\stockwidth,\the\stockheight}}
}


\newcommand{\typeoutstandardlayout}{%
  \typeout{}
  \typeout{******************************************************}
 %   \typeout{Page height and width:
 %                 \the\paperheight\space by \the\paperwidth}
 \mem@typeouttwolengths{Page height and width}{\paperheight}{by}{\paperwidth}
 %   \typeout{Text height and width:
 %                \the\textheight\space by \the\textwidth}
 \mem@typeouttwolengths{Text height and width}{\textheight}{by}{\textwidth}
 %   \typeout{Oddside and evenside margins:
 %                 \the\oddsidemargin\space and \the\evensidemargin}
 \mem@typeouttwolengths{Oddside and evenside margins}{\oddsidemargin}{and}{\evensidemargin}
 %   \typeout{Topmargin and footskip:
 %                 \the\topmargin\space and \the\footskip}
 \mem@typeouttwolengths{Topmargin and footskip}{\topmargin}{and}{\footskip}
 %   \typeout{Headheight and headsep:
 %                 \the\headheight\space and \the\headsep}
 \mem@typeouttwolengths{Headheight and headsep}{\headheight}{and}{\headsep}
 %   \typeout{Columnsep and columnseprule:
 %                 \the\columnsep\space and \the\columnseprule}
 \mem@typeouttwolengths{Columnsep and columnseprule}{\columnsep}{and}{\columnseprule}
 %   \typeout{Marginparsep and marginparwidth:
 %                 \the\marginparsep\space and \the\marginparwidth}
 \mem@typeouttwolengths{Marginparsep and marginparwidth}{\marginparsep}{and}{\marginparwidth}
  \typeout{******************************************************}
  \typeout{}
}

%%%% s = w/#1, t = 1.5s, e = 2s, f = 3s
\newcommand*{\medievalpage}[1][9]{%
  \spinemargin=\paperwidth
  \divide\spinemargin #1\relax
  \uppermargin = 1.5\spinemargin
  \setlrmarginsandblock{\spinemargin}{*}{2}
  \setulmarginsandblock{\uppermargin}{*}{2}}

\newcommand*{\isopage}[1][9]{%
  \spinemargin=\paperwidth
  \divide\spinemargin #1\relax
  \uppermargin=\paperheight
  \divide\uppermargin #1\relax
  \setlrmarginsandblock{\spinemargin}{*}{2}
  \setulmarginsandblock{\uppermargin}{*}{2}}

%%% s = w/#1, t = s, e = 2s, f = e
\newcommand*{\semiisopage}[1][9]{%
  \spinemargin=\paperwidth
  \divide\spinemargin #1\relax
  \uppermargin=\spinemargin
  \setlrmarginsandblock{\spinemargin}{*}{2}
  \setulmarginsandblock{\uppermargin}{*}{2}}

\newcommand*{\setpagebl}[3]{%
  \settrimmedsize{#1}{#2}{#3}%
  \trimtop=\stockheight \advance\trimtop -\paperheight
  \trimedge=\stockwidth \advance\trimedge -\paperwidth}
\newcommand*{\setpageml}[3]{%
  \settrimmedsize{#1}{#2}{#3}
  \trimtop=\stockheight \advance\trimtop -\paperheight
    \advance\trimtop -0.5\trimtop
  \trimedge=\stockwidth \advance\trimedge -\paperwidth}
\newcommand*{\setpagetl}[3]{%
  \settrimmedsize{#1}{#2}{#3}
  \trimtop=0pt
  \trimedge=\stockwidth \advance\trimedge -\paperwidth}
\newcommand*{\setpagetm}[3]{%
  \settrimmedsize{#1}{#2}{#3}%
  \trimtop=0pt
  \trimedge=\stockwidth \advance\trimedge -\paperwidth
  \advance\trimedge -0.5\trimedge}

\newcommand*{\setpagetr}[3]{%
  \settrimmedsize{#1}{#2}{#3}%
  \trimtop=0pt
  \trimedge=0pt}
\newcommand*{\setpagemr}[3]{%
  \settrimmedsize{#1}{#2}{#3}%
  \trimtop=\stockheight \advance\trimtop -\paperheight
    \advance\trimtop -0.5\trimtop
  \trimedge=0pt}
\newcommand*{\setpagebr}[3]{%
  \settrimmedsize{#1}{#2}{#3}%
  \trimtop=\stockheight  \advance\trimtop -\paperheight
  \trimedge=0pt}
\newcommand*{\setpagebm}[3]{%
  \settrimmedsize{#1}{#2}{#3}%
  \trimtop=\stockheight \advance\trimtop -\paperheight
  \trimedge=\stockwidth \advance\trimedge -\paperwidth
    \advance\trimedge -0.5\trimedge}
\newcommand*{\setpagecc}[3]{%
  \settrimmedsize{#1}{#2}{#3}%
  \trimtop=\stockheight \advance\trimtop -\paperheight
    \advance\trimtop -0.5\trimtop
  \trimedge=\stockwidth \advance\trimedge -\paperwidth
    \advance\trimedge -0.5\trimedge}
\let\setpagemm\setpagecc

\setcounter{topnumber}{3}
\renewcommand{\topfraction}{.85}
\setcounter{bottomnumber}{2}
\renewcommand{\bottomfraction}{.5}
\setcounter{totalnumber}{4}
\renewcommand{\textfraction}{.1}
\renewcommand{\floatpagefraction}{.7}
\setcounter{dbltopnumber}{3}
\renewcommand{\dbltopfraction}{.85}
\renewcommand{\dblfloatpagefraction}{.7}
\newcommand\mem@set@ps@xtra@info[3]{%
  \@namedef{ps@#1@aliasfor}{#2}%
  \@namedef{ps@#1@isalias}{#3}}

\newcommand\mem@ps@find@real[1]{%
  \if\@nameuse{ps@#1@isalias}\relax
  \mem@ps@find@real{\@nameuse{ps@#1@aliasfor}}
  \else\def\@tempa{#1}\fi}

\newcommand\mem@ps@safe@change[1]{%
 \@ifundefined{ps@#1}{%
    \@memerror{Undefined pagestyle '#1', so I cannot change it}{}}{}
  \if\@nameuse{ps@#1@isalias}\relax \mem@ps@find@real{#1}
  \@memerror{The pagestyle '#1' is marked as an alias page style.^^J
    Modifying an alias page style may give unexpected results.^^J The
    alias chain resolves to the real page style '\@tempa', so try
    issuing^^J \string\copypagestyle{#1}{\@tempa}^^J
    before modifying '#1'}{} \fi }

\newcommand{\makeevenhead}[4]{%
  \mem@ps@safe@change{#1}
  \@namedef{#1eheadl}{#2}
  \@namedef{#1eheadc}{#3}
  \@namedef{#1eheadr}{#4}
}
\newcommand{\makeoddhead}[4]{%
  \mem@ps@safe@change{#1}
  \@namedef{#1oheadl}{#2}
  \@namedef{#1oheadc}{#3}
  \@namedef{#1oheadr}{#4}
}
\newcommand{\makeevenfoot}[4]{%
  \mem@ps@safe@change{#1}
  \@namedef{#1efootl}{#2}
  \@namedef{#1efootc}{#3}
  \@namedef{#1efootr}{#4}
}
\newcommand{\makeoddfoot}[4]{%
  \mem@ps@safe@change{#1}
  \@namedef{#1ofootl}{#2}
  \@namedef{#1ofootc}{#3}
  \@namedef{#1ofootr}{#4}
}

\newcommand*{\makerunningwidth}[1]{%
  \mem@ps@safe@change{#1}%
  \def\m@mhfstyle{#1}%
  \m@mopthfwidth}
\newcommand*{\m@mopthfwidth}[2][\@mpty]{%
  \@namedef{\m@mhfstyle headrunwidth}{#2}%
  \ifx\@mpty #1
    \@namedef{\m@mhfstyle footrunwidth}{#2}%
  \else
    \@namedef{\m@mhfstyle footrunwidth}{#1}%
  \fi}
\newcommand*{\makerunningheadwidth}[2]{%
  \mem@ps@safe@change{#1}%
  \@namedef{#1headrunwidth}{#2}%
}
\newcommand*{\makerunningfootwidth}[2]{%
  \mem@ps@safe@change{#1}%
  \@namedef{#1footrunwidth}{#2}%
}

\newlength{\normalrulethickness}
  \setlength{\normalrulethickness}{0.4pt}
\newcommand{\footruleheight}{0pt}
\newcommand{\footruleskip}{0.3\normalbaselineskip}
\newcommand{\makeheadrule}[3]{%
  \mem@ps@safe@change{#1}%
  \@namedef{#1headrule}{%
    \hrule\@width #2\@height #3 \vskip-#3}}
\newcommand{\makefootrule}[4]{%
  \mem@ps@safe@change{#1}%
  \@namedef{#1footrule}{%
    \vskip-#4\vskip-#3%
    \hrule\@width #2\@height #3 \vskip #4}}

\newcommand\makeheadfootruleprefix[3]{%
  \@namedef{#1headruleprefix}{#2}%
  \@namedef{#1footruleprefix}{#3}%
}
\newcommand{\makeheadposition}[5]{%
  \mem@ps@safe@change{#1}%
  \nametest{flushleft}{#2}
  \ifsamename
    \@namedef{#1evenheadpl}{\relax} \@namedef{#1evenheadpr}{\hss}
  \else
    \nametest{flushright}{#2}
    \ifsamename
      \@namedef{#1evenheadpl}{\hss} \@namedef{#1evenheadpr}{\relax}
    \else
      \@namedef{#1evenheadpl}{\hss} \@namedef{#1evenheadpr}{\hss}
    \fi
  \fi
  \nametest{flushleft}{#3}
  \ifsamename
    \@namedef{#1oddheadpl}{\relax} \@namedef{#1oddheadpr}{\hss}
  \else
    \nametest{flushright}{#3}
    \ifsamename
      \@namedef{#1oddheadpl}{\hss} \@namedef{#1oddheadpr}{\relax}
    \else
      \@namedef{#1oddheadpl}{\hss} \@namedef{#1oddheadpr}{\hss}
    \fi
  \fi
  \nametest{flushleft}{#4}
  \ifsamename
    \@namedef{#1evenfootpl}{\relax} \@namedef{#1evenfootpr}{\hss}
  \else
    \nametest{flushright}{#4}
    \ifsamename
      \@namedef{#1evenfootpl}{\hss} \@namedef{#1evenfootpr}{\relax}
    \else
      \@namedef{#1evenfootpl}{\hss} \@namedef{#1evenfootpr}{\hss}
    \fi
  \fi
  \nametest{flushleft}{#5}
  \ifsamename
    \@namedef{#1oddfootpl}{\relax} \@namedef{#1oddfootpr}{\hss}
  \else
    \nametest{flushright}{#5}
    \ifsamename
      \@namedef{#1oddfootpl}{\hss} \@namedef{#1oddfootpr}{\relax}
    \else
      \@namedef{#1oddfootpl}{\hss} \@namedef{#1oddfootpr}{\hss}
    \fi
  \fi}

\newcommand{\makepsmarks}[2]{\mem@ps@safe@change{#1}\@namedef{#1pshook}{#2}}

\newcommand*{\m@mhe@dreset}{\def\baselinestretch{1}\normalsize}

\newcommand*\makeheadfootvposition[3]{%
  \mem@ps@safe@change{#1}%
  \@namedef{#1headvplacement}{#2}\@namedef{#1footvplacement}{#3}}

\newlength\mem@maxheadheight
\newlength\mem@maxfootheight
\newcommand\mem@sayonce@head{00}
\newcommand\mem@sayonce@foot{00}
\newcommand\mem@hf@measure@vbox[4]{%
  \setbox0\vbox{#4}%
  \ifdim\ht0>#1\relax%
    \setlength\@tempdima{\@nameuse{mem@max#2height}}%
    \ifdim\ht0>\@tempdima\relax%
      \expandafter\global\@nameuse{mem@max#2height}=\ht0%
      \expandafter\if\@nameuse{mem@sayonce@#2}\relax%
        \@memwarn{#3}%
          \global\@namedef{mem@sayonece@#2}{01}%
      \fi%
    \fi%
  \fi%
  \box0%
}
\newcommand\mem@toolarge@header@message{%
  The material used in the headers is too large^^J%
  (\the\mem@maxheadheight) for the given head height
  (\the\headheight), it is recommended to^^J%
  either increase the head height or redesign the header^^J%
  (in both cases you will find help in the memoir manual).%
}
\newcommand\mem@toolarge@footer@message{%
  The material used in the footer is too large^^J%
  (\the\mem@maxfootheight) for the given foot skip
  (\the\footskip), it is recommended to^^J%
  either increase the foot skip or redesign the footer^^J%
  (in both cases you will find help in the memoir manual).%
}
\newcommand\mem@hvboxm[1]{%
  \mem@hf@measure@vbox\headheight{head}\mem@toolarge@header@message{#1}}
\newcommand\mem@fvboxm[1]{%
  \mem@hf@measure@vbox\footskip{foot}\mem@toolarge@footer@message{#1}}
\AtEndDocument{
  \ifdim\mem@maxheadheight>\headheight
    \@memwarn{\mem@toolarge@header@message}
  \fi
  \ifdim\mem@maxfootheight>\footskip
    \@memwarn{\mem@toolarge@footer@message}
  \fi
}
\newcommand\mem@ps@entry@wrap{}
\newcommand\mem@ps@HLH[4]{%
  % #1 ps name
  % #2 type: head, foot
  % #3 odd/even
  % #4 odd/even short (o,e)
  \@namedef{#1@#3#2}{%
    \@nameuse{#1#3#2pl}\hb@xt@\@nameuse{#1#2runwidth}{\m@mhe@dreset%
      \nametest{#2}{head}\ifsamename\let\mem@hfboxer\mem@hvboxm\else\let\mem@hfboxer\mem@fvboxm\fi%
      \mem@hfboxer{\nametest{#2}{foot}\ifsamename%
          \begingroup% to prevent colors from bleeding into the footer
          \@nameuse{#1#2ruleprefix}%
          \@nameuse{#1#2rule}%
          \endgroup%
        \fi%
        \hbox{%
          \rlap{%
            \parbox[\@nameuse{#1#2vplacement}]{\@nameuse{#1#2runwidth}}{%
              \memRTLmainraggedright\@nameuse{#1ps#2strut}%
              \mem@ps@entry@wrap{\@nameuse{#1#4#2l}}%
              \@nameuse{#1ps#2strut}}}\hfill
          \parbox[\@nameuse{#1#2vplacement}]{\@nameuse{#1#2runwidth}}{%
            \centering\@nameuse{#1ps#2strut}%
            \mem@ps@entry@wrap{\@nameuse{#1#4#2c}}%
            \@nameuse{#1ps#2strut}}\hfill
          \llap{%
            \parbox[\@nameuse{#1#2vplacement}]{\@nameuse{#1#2runwidth}}{%
              \memRTLmainraggedleft\@nameuse{#1ps#2strut}%
              \mem@ps@entry@wrap{\@nameuse{#1#4#2r}}%
              \@nameuse{#1ps#2strut}}}%
        }%
        \nametest{#2}{head}\ifsamename%
          \@nameuse{#1#2ruleprefix}%
          \@nameuse{#1#2rule}%
        \fi%
      }}\@nameuse{#1#3#2pr}}%
  \@namedef{@#3#2}{\@nameuse{#1@#3#2}}%
}
\newcommand{\makepagestyle}[1]{%
  \mem@set@ps@xtra@info{#1}{}{01}%
  \@namedef{ps@#1}{%
      \mem@ps@HLH{#1}{head}{even}{e}%
      \mem@ps@HLH{#1}{head}{odd}{o}%
      \mem@ps@HLH{#1}{foot}{even}{e}%
      \mem@ps@HLH{#1}{foot}{odd}{o}%
 %    \@namedef{#1@evenhead}{%
 %      \@nameuse{#1evenhpl}\hb@xt@\@nameuse{#1headrunwidth}{\m@mhe@dreset%
 %        \vbox{\hbox{%
 %        \rlap{\parbox[\@nameuse{#1headvplacement}]{\@nameuse{#1headrunwidth}}{%
 %          \raggedright\@nameuse{#1eheadl}\strut}}\hfill
 %               \parbox[\@nameuse{#1headvplacement}]{\@nameuse{#1headrunwidth}}{%
 %           \centering\@nameuse{#1eheadc}\strut}\hfill
 %        \llap{\parbox[\@nameuse{#1headvplacement}]{\@nameuse{#1headrunwidth}}{%
 %         \raggedleft\@nameuse{#1eheadr}\strut}}}%
 %       \@nameuse{#1headrule}}}\@nameuse{#1evenhpr}}%
 %   \@namedef{#1@oddhead}{%
 %     \@nameuse{#1oddhpl}\hb@xt@\@nameuse{#1headrunwidth}{\m@mhe@dreset%
 %       \vbox{\hbox{%
 %       \rlap{\parbox[\@nameuse{#1headvplacement}]{\@nameuse{#1headrunwidth}}{%
 %         \raggedright\@nameuse{#1oheadl}\strut}}\hfill
 %             \parbox[\@nameuse{#1headvplacement}]{\@nameuse{#1headrunwidth}}{%
 %         \centering\@nameuse{#1oheadc}\strut}\hfill
 %       \llap{\parbox[\@nameuse{#1headvplacement}]{\@nameuse{#1headrunwidth}}{%
 %         \raggedleft\@nameuse{#1oheadr}\strut}}}%
 %       \@nameuse{#1headrule}}}\@nameuse{#1oddhpr}}%
 %   \@namedef{#1@evenfoot}{%
 %     \@nameuse{#1evenfpl}\hb@xt@\@nameuse{#1footrunwidth}{\m@mhe@dreset%
 %       \vbox{\@nameuse{#1footrule}\hbox{%
 %       \rlap{\parbox[\@nameuse{#1footvplacement}]{\@nameuse{#1footrunwidth}}{%
 %         \raggedright\@nameuse{#1efootl}\strut}}\hfill
 %             \parbox[\@nameuse{#1footvplacement}]{\@nameuse{#1footrunwidth}}{%
 %         \centering\@nameuse{#1efootc}\strut}\hfill
 %       \llap{\parbox[\@nameuse{#1footvplacement}]{\@nameuse{#1footrunwidth}}{%
 %         \raggedleft\@nameuse{#1efootr}\strut}}}%
 %       }}\@nameuse{#1evenfpr}}%
 %   \@namedef{#1@oddfoot}{%
 %     \@nameuse{#1oddfpl}\hb@xt@\@nameuse{#1footrunwidth}{\m@mhe@dreset%
 %       \vbox{\@nameuse{#1footrule}\hbox{%
 %       \rlap{\parbox[\@nameuse{#1footvplacement}]{\@nameuse{#1footrunwidth}}{%
 %         \raggedright\@nameuse{#1ofootl}\strut}}\hfill
 %             \parbox[\@nameuse{#1footvplacement}]{\@nameuse{#1footrunwidth}}{%
 %         \centering\@nameuse{#1ofootc}\strut}\hfill
 %       \llap{\parbox[\@nameuse{#1footvplacement}]{\@nameuse{#1footrunwidth}}{%
 %         \raggedleft\@nameuse{#1ofootr}\strut}}}%
 %       }}\@nameuse{#1oddfpr}}%
 %    \def\@evenhead{\@nameuse{#1@evenhead}}%
 %    \def\@oddhead{\@nameuse{#1@oddhead}}%
 %    \def\@evenfoot{\@nameuse{#1@evenfoot}}%
 %    \def\@oddfoot{\@nameuse{#1@oddfoot}}%
    \@nameuse{#1pshook}}%
    \nametest{#1}{empty}%
    \ifsamename%
      \@namedef{#1psheadstrut}{}\@namedef{#1psfootstrut}{}%
    \else%
      \@namedef{#1psheadstrut}{\strut}\@namedef{#1psfootstrut}{\strut}%
    \fi%
  \makeevenhead{#1}{}{}{}%
  \makeoddhead{#1}{}{}{}%
  \makeevenfoot{#1}{}{}{}%
  \makeoddfoot{#1}{}{}{}%
  \makerunningwidth{#1}{\textwidth}%
  \makeheadposition{#1}{}{}{}{}%
  \makeheadrule{#1}{\textwidth}{0pt}%
  \makefootrule{#1}{\textwidth}{\footruleheight}{\footruleskip}%
  \makeheadfootruleprefix{#1}{}{}
  \makeheadfootvposition{#1}{b}{b}%
  \makepsmarks{#1}{}}

\newcommand{\aliaspagestyle}[2]{%
  \mem@set@ps@xtra@info{#1}{#2}{00}%
  \@namedef{ps@#1}{\@nameuse{ps@#2}}}

\newcommand{\copypagestyle}[2]{%
  \makepagestyle{#1}%
  \makeevenhead{#1}{\@nameuse{#2eheadl}}%
               {\@nameuse{#2eheadc}}{\@nameuse{#2eheadr}}%
  \makeoddhead{#1}{\@nameuse{#2oheadl}}%
               {\@nameuse{#2oheadc}}{\@nameuse{#2oheadr}}%
  \makeevenfoot{#1}{\@nameuse{#2efootl}}%
               {\@nameuse{#2efootc}}{\@nameuse{#2efootr}}%
  \makeoddfoot{#1}{\@nameuse{#2ofootl}}%
              {\@nameuse{#2ofootc}}{\@nameuse{#2ofootr}}%
  \makerunningwidth{#1}[\@nameuse{#2footrunwidth}]{\@nameuse{#2headrunwidth}}%
  \@namedef{#1evenheadpl}{\@nameuse{#2evenheadpl}}%
  \@namedef{#1oddheadpl}{\@nameuse{#2oddheadpl}}%
  \@namedef{#1evenheadpr}{\@nameuse{#2evenheadpr}}%
  \@namedef{#1oddheadpr}{\@nameuse{#2oddheadpr}}%
  \makeheadfootvposition{#1}{\@nameuse{#2headvplacement}}{\@nameuse{#2footvplacement}}%
  \@namedef{#1evenfootpl}{\@nameuse{#2evenfootpl}}%
  \@namedef{#1oddfootpl}{\@nameuse{#2oddfootpl}}%
  \@namedef{#1evenfootpr}{\@nameuse{#2evenfootpr}}%
  \@namedef{#1oddfootpr}{\@nameuse{#2oddfootpr}}%
  \@namedef{#1headrule}{\@nameuse{#2headrule}}%
  \@namedef{#1footrule}{\@nameuse{#2footrule}}%
  \@namedef{#1headruleprefix}{\@nameuse{#2headruleprefix}}%
  \@namedef{#1footruleprefix}{\@nameuse{#2footruleprefix}}%
  \@namedef{#1psheadstrut}{\@nameuse{#2psheadstrut}}
  \@namedef{#1psfootstrut}{\@nameuse{#2psfootstrut}}
  \makepsmarks{#1}{\@nameuse{#2pshook}}}

\newcommand{\ifonlyfloats}[2]{\if@fcolmade #1\else #2\fi}

\newcommand{\mergepagefloatstyle}[3]{%
  \@nameuse{ps@#3}\@nameuse{ps@#2}%
  \@namedef{ps@#1}{%
  \def\@evenhead{\ifonlyfloats{\@nameuse{#3@evenhead}}%
                {\@nameuse{#2@evenhead}}}%
  \def\@oddhead{\ifonlyfloats{\@nameuse{#3@oddhead}}%
               {\@nameuse{#2@oddhead}}}%
  \def\@evenfoot{\ifonlyfloats{\@nameuse{#3@evenfoot}}%
                {\@nameuse{#2@evenfoot}}}%
  \def\@oddfoot{\ifonlyfloats{\@nameuse{#3@oddfoot}}%
               {\@nameuse{#2@oddfoot}}}%
  \@namedef{#1pshook}{\@nameuse{#2pshook}}%
}}

\newcommand*\makeheadfootstrut[3]{%
  \@namedef{#1psheadstrut}{#2}\@namedef{#1psfootstrut}{#3}}
\makepagestyle{empty}

\makepagestyle{plain}
  \makeevenfoot{plain}{}{\thepage}{}
  \makeoddfoot{plain}{}{\thepage}{}

\makepagestyle{simple}
  \makeevenhead{simple}{\thepage}{}{}
  \makeoddhead{simple}{}{}{\thepage}

\newcommand*{\nouppercaseheads}{\def\memUChead{}}
\newcommand*{\uppercaseheads}{\def\memUChead{\MakeTextUppercase}}
\uppercaseheads

\newcommand*{\createplainmark}[3]{%
  \nametest{#2}{left}%
  \ifsamename
    \@namedef{#1mark}{\markboth{\memUChead{#3}}{}}%
  \else
    \nametest{#2}{right}%
    \ifsamename
      \@namedef{#1mark}{\markright{\memUChead{#3}}}%
    \else
      \nametest{#2}{both}%
      \ifsamename\else
        \@memerror{%
          Unknown mark setting type `#2' for #1mark}{%
          I expected `left', `both' or `right'. \MessageBreak
          I will assume you meant `both'}% 
      \fi
      \@namedef{#1mark}{\markboth{\memUChead{#3}}{\memUChead{#3}}}%
    \fi
  \fi}

\newcommand\createmark[5]{%
  % \def\@tempa{00}
  % \nametest{#3}{nonumber}%
  % \ifsamename
  %   \def\@tempa{01}%
  % \else
  %   \nametest{#3}{shownumber}
  %   \ifsamename\else
  %     \@memerror{Unknown numbering value `#3' for #1mark}%
  %     {I expected `shownumber' or `nonumber'.\MessageBreak
  %      I will assume you meant `shownumber'}%
  %   \fi
  % \fi
  % \expandafter\if\@tempa%          compares the two \@tempa digits
  %   \@namedef{#1marksn}##1{##1}%
  % \else
  %   \@namedef{#1marksn}{\@gobble}%
  %   \fi
  \def\@tempa{1}
  \nametest{#3}{nonumber}%
  \ifsamename
    \def\@tempa{0}
  \else
    \nametest{#3}{shownumber}
    \ifsamename
      \def\@tempa{1}
    \else
      \nametest{#3}{notitle}
      \ifsamename
        \def\@tempa{2}
      \else
        \@memerror{Unknown numbering value `#3' for
          #1mark,\MessageBreak
          please use   one of 'shownumber', 'nonumber' or 'notitle'}%
        {I expected `shownumber', `nonumber' or 'notitle'.\MessageBreak
          I will assume you meant `shownumber'}%
      \fi
    \fi
  \fi
  \@namedef{#1markst}##1{##1}
  \ifcase\@tempa\relax
    % nonumber
    \@namedef{#1marksn}{\@gobble}%
  \or % 1
    % shownumber
    \@namedef{#1marksn}##1{##1}
  \or % 2, 2 implies shownumber
    % shownumber
    \@namedef{#1marksn}##1{##1}
    \@namedef{#1markst}{\@gobble}
  \fi
  \nametest{#2}{left}%
  \ifsamename
    \@namedef{#1mark}##1{%
      \@setclcnt{#1}{@memmarkcntra}%
      \advance\c@@memmarkcntra\m@ne
      \markboth{%
        \memUChead{%
          \ifnum \c@secnumdepth > \c@@memmarkcntra
            \if@mainmatter
              \@nameuse{#1marksn}{#4\@nameuse{the#1}#5}%
            \fi
          \fi
          \@nameuse{#1markst}{##1}%
        }%
      }%
      {}% just left
    }%
  \else
    \nametest{#2}{right}
    \ifsamename
      \@namedef{#1mark}##1{%
        \@setclcnt{#1}{@memmarkcntra}%
        \advance\c@@memmarkcntra\m@ne
        \markright{%
          \memUChead{%
            \ifnum \c@secnumdepth > \c@@memmarkcntra
              \if@mainmatter%
                \@nameuse{#1marksn}{#4\@nameuse{the#1}#5}%
              \fi%
            \fi%
            \@nameuse{#1markst}{##1}%
          }%
        }%
      }%
    \else
      \nametest{#2}{both}%
      \ifsamename\else
        \@memerror{%
        Unknown mark setting type `#2' for #1mark}{%
        I expected `left', `both' or `right'. \MessageBreak
        I will assume you meant `both'}% 
      \fi
    \@namedef{#1mark}##1{%
      \@setclcnt{#1}{@memmarkcntra}%
      \advance\c@@memmarkcntra\m@ne
      \markboth{%
        \memUChead{%
          \ifnum \c@secnumdepth > \c@@memmarkcntra
            \if@mainmatter
              \@nameuse{#1marksn}{#4\@nameuse{the#1}#5}%
            \fi
          \fi
          \@nameuse{#1markst}{##1}%
        }%
      }{%
        \memUChead{%
          \ifnum \c@secnumdepth > \c@@memmarkcntra
            \if@mainmatter
              \@nameuse{#1marksn}{#4\@nameuse{the#1}#5}%
            \fi
          \fi
          \@nameuse{#1markst}{##1}%
        }%
      }%
    }%
    \fi
  \fi
}

\newcommand\addtopsmarks[3]{%
  \mem@ps@safe@change{#1}%
  \expandafter\addtodef\expandafter{\csname #1pshook\endcsname}{#2}{#3}}
\newcommand\clearplainmark[1]{%
  \@namedef{#1mark}{}}
\newcommand\clearmark[1]{%
  \@namedef{#1mark}{\@gobble}}
\if@twoside
  \makepagestyle{headings}
    \makepsmarks{headings}{%
      \def\chaptermark##1{%
        \markboth{\memUChead{%
          \ifnum \c@secnumdepth >\m@ne
            \if@mainmatter
              \@chapapp\ \thechapter. \ %
            \fi
          \fi
          ##1}}{}}%
      \def\tocmark{\markboth{\memUChead{\contentsname}}{\memUChead{\contentsname}}}%
      \def\lofmark{\markboth{\memUChead{\listfigurename}}{\memUChead{\listfigurename}}}%
      \def\lotmark{\markboth{\memUChead{\listtablename}}{\memUChead{\listtablename}}}%
      \def\bibmark{\markboth{\memUChead{\bibname}}{\memUChead{\bibname}}}%
      \def\indexmark{\markboth{\memUChead{\indexname}}{\memUChead{\indexname}}}%
      \def\sectionmark##1{%
        \markright{\memUChead{%
          \ifnum \c@secnumdepth > \z@
            \thesection. \ %
          \fi
          ##1}}}}
    \makepsmarks{headings}{%
      \createmark{chapter}{left}{shownumber}{\@chapapp\ }{. \ }
      \createmark{section}{right}{shownumber}{}{. \ }
      \createplainmark{toc}{both}{\contentsname}
      \createplainmark{lof}{both}{\listfigurename}
      \createplainmark{lot}{both}{\listtablename}
      \createplainmark{bib}{both}{\bibname}
      \createplainmark{index}{both}{\indexname}
      \createplainmark{glossary}{both}{\glossaryname}
    }
    \makeevenhead{headings}{\thepage}{}{\slshape\leftmark}
    \makeoddhead{headings}{\slshape\rightmark}{}{\thepage}
\else
  \makepagestyle{headings}
    \makepsmarks{headings}{%
      \def\chaptermark##1{%
        \markright{\memUChead{%
          \ifnum \c@secnumdepth >\m@ne
            \if@mainmatter
              \@chapapp\ \thechapter. \ %
            \fi
          \fi
          ##1}}}%
      \def\tocmark{\markright{\memUChead{\contentsname}}}%
      \def\lofmark{\markright{\memUChead{\listfigurename}}}%
      \def\lotmark{\markright{\memUChead{\listtablename}}}%
      \def\bibmark{\markright{\memUChead{\bibname}}}%
      \def\indexmark{\markright{\memUChead{\indexname}}}}
    \makepsmarks{headings}{%
      \createmark{chapter}{right}{shownumber}{\@chapapp\ }{. \ }
      \createplainmark{toc}{right}{\contentsname}
      \createplainmark{lof}{right}{\listfigurename}
      \createplainmark{lot}{right}{\listtablename}
      \createplainmark{bib}{right}{\bibname}
      \createplainmark{index}{right}{\indexname}
      \createplainmark{glossary}{right}{\glossaryname}
    }
    \makeoddhead{headings}{\slshape\rightmark}{}{\thepage}
\fi

\makepagestyle{myheadings}
  \makepsmarks{myheadings}{%
    \let\chaptermark\@gobble
    \let\sectionmark\@gobble
    \def\tocmark{}%
    \def\lofmark{}%
    \def\lotmark{}%
    \def\bibmark{}%
    \def\indexmark{}%
    \def\glossarymark{}}
  \makeevenhead{myheadings}{\thepage}{}{\slshape\leftmark}
  \makeoddhead{myheadings}{\slshape\rightmark}{}{\thepage}

\aliaspagestyle{chapter}{plain}
\aliaspagestyle{part}{plain}
\aliaspagestyle{cleared}{empty}

\def\cleardoublepage{\clearpage\if@twoside \ifodd\c@page\else
  \hbox{}\thispagestyle{cleared}%
  \newpage\if@twocolumn\hbox{}\newpage\fi\fi\fi}

\makepagestyle{ruled}
\makeevenfoot{ruled}{\thepage}{}{}
\makeoddfoot{ruled}{}{}{\thepage}
\makeheadrule{ruled}{\textwidth}{\normalrulethickness}
\newcommand{\@ruledmarks}{%
  \def\chaptermark##1{%
    \markboth{%
      \ifnum \c@secnumdepth >\m@ne
        \if@mainmatter
          \thechapter. \ %
        \fi
      \fi
      ##1}{}}
  \def\sectionmark##1{\markright{##1}}
  \def\tocmark{\markboth{\contentsname}{}}
  \def\lofmark{\markboth{\listfigurename}{}}
  \def\lotmark{\markboth{\listtablename}{}}
  \def\bibmark{\markboth{\bibname}{}}
  \def\indexmark{\markboth{\indexname}{}}
  \def\glossarymark{\markboth{\glossaryname}{}}
}
\renewcommand*{\@ruledmarks}{%
  \nouppercaseheads
  \createmark{chapter}{left}{shownumber}{}{. \space}
  \createmark{section}{right}{shownumber}{}{. \space}
  \createplainmark{toc}{both}{\contentsname}
  \createplainmark{lof}{both}{\listfigurename}
  \createplainmark{lot}{both}{\listtablename}
  \createplainmark{bib}{both}{\bibname}
  \createplainmark{index}{both}{\indexname}
  \createplainmark{glossary}{both}{\glossaryname}}
\makepsmarks{ruled}{\@ruledmarks}
\makeevenhead{ruled}{\scshape\leftmark}{}{}
\makeoddhead{ruled}{}{}{\rightmark}

\makepagestyle{Ruled}
\makerunningwidth{Ruled}{1.1\textwidth}
\makeheadposition{Ruled}{flushright}{flushleft}{flushright}{flushleft}
\makeevenfoot{Ruled}{\thepage}{}{}
\makeoddfoot{Ruled}{}{}{\thepage}
\makeheadrule{Ruled}{1.1\textwidth}{\normalrulethickness}
\makepsmarks{Ruled}{\@ruledmarks}
\makeevenhead{Ruled}{\scshape\leftmark}{}{}
\makeoddhead{Ruled}{}{}{\rightmark}

\newlength{\headwidth}

\makepagestyle{companion}
\setlength{\headwidth}{\textwidth}
  \addtolength{\headwidth}{\marginparsep}
  \addtolength{\headwidth}{\marginparwidth}
\makerunningwidth{companion}{\headwidth}
\makeheadrule{companion}{\headwidth}{\normalrulethickness}
\makeheadposition{companion}{flushright}{flushleft}{}{}
\makepsmarks{companion}{%
  \def\chaptermark##1{\markboth{##1}{##1}}    % left mark & right marks
  \def\sectionmark##1{\markright{%
    \ifnum \c@secnumdepth>\z@
      \thesection. \ %
    \fi
    ##1}}
  \def\tocmark{\markboth{\contentsname}{\contentsname}}
  \def\lofmark{\markboth{\listfigurename}{\listfigurename}}
  \def\lotmark{\markboth{\listtablename}{\listtablename}}
  \def\bibmark{\markboth{\bibname}{\bibname}}
  \def\indexmark{\markboth{\indexname}{\indexname}}}
\makepsmarks{companion}{%
  \nouppercaseheads
  \createmark{chapter}{both}{nonumber}{}{}
  \createmark{section}{right}{shownumber}{}{. \space}
  \createplainmark{toc}{both}{\contentsname}
  \createplainmark{lof}{both}{\listfigurename}
  \createplainmark{lot}{both}{\listtablename}
  \createplainmark{bib}{both}{\bibname}
  \createplainmark{index}{both}{\indexname}
  \createplainmark{glossary}{both}{\glossaryname}}
\makeevenhead{companion}{\normalfont\bfseries\thepage}{}%
                        {\normalfont\bfseries\leftmark}
\makeoddhead{companion}{\normalfont\bfseries\rightmark}{}%
                       {\normalfont\bfseries\thepage}

\newif\ifshowheadfootloc
  \showheadfootloctrue
\newcommand*{\showheadfootlocon}{\showheadfootloctrue}
\newcommand*{\showheadfootlocoff}{\showheadfootlocfalse}
\newif\ifshowtextblockloc
  \showtextblockloctrue
\newcommand*{\showtextblocklocon}{\showtextblockloctrue}
\newcommand*{\showtextblocklocoff}{\showtextblocklocfalse}

\newcommand\framepichook{}
\newcommand*{\framepichead}{%
\ifshowheadfootloc
  \begin{picture}(0,0)
    \framepichook
    \unitlength 1pt
    \put(0,0){\line(1,0){\strip@pt\textwidth}}
  \end{picture}%
\fi}

\newcommand*{\framepictextfoot}{%
  \begin{picture}(0,0)
    \framepichook
    \unitlength 1pt
    \ifshowheadfootloc
      \put(0,0){\line(1,0){\strip@pt\textwidth}}
    \fi
    \ifshowtextblockloc
      \put(0,\strip@pt\footskip)%
        {\framebox(\strip@pt\textwidth,\strip@pt\textheight){}}
    \fi
  \end{picture}}

\makepagestyle{showlocs}
\makeevenhead{showlocs}{\framepichead\thepage}{\thepage}{\thepage}
\makeoddhead{showlocs}{\framepichead\thepage}{\thepage}{\thepage}
\makeevenfoot{showlocs}{\framepictextfoot\thepage}{\thepage}{\thepage}
\makeoddfoot{showlocs}{\framepictextfoot\thepage}{\thepage}{\thepage}

\newcommand*{\fixheaderwidths}{%
  % companion pagestyle
  \setlength{\headwidth}{\textwidth}
    \addtolength{\headwidth}{\marginparsep}
    \addtolength{\headwidth}{\marginparwidth}
  \makerunningwidth{companion}{\headwidth}
  \makeheadrule{companion}{\headwidth}{\normalrulethickness}
  \makefootrule{companion}{\textwidth}{\footruleheight}{\footruleskip}
}

\RenewDocumentCommand\pagenumbering{sm}{%
  \gdef\thepage{\csname @#2\endcsname \c@page}%
  \IfBooleanF{#1}{\global\c@page \@ne}% reset counter unless starred
}

\newcounter{storedpagenumber}
  \setcounter{storedpagenumber}{1}
\newcommand{\savepagenumber}{\global\c@storedpagenumber \c@page}
\newcommand{\restorepagenumber}{\global\c@page \c@storedpagenumber}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newcommand*{\setSpacing}[1]{%
  \def\baselinestretch{#1}%
  \@currsize}

\newcommand*{\setSingleSpace}[1]{%
  \def\m@m@singlespace{#1}%
  \def\m@m@footnote@spacing{#1}%
  \def\m@m@float@spacing{#1} %
}
\setSingleSpace{1}
\newcommand*\setPagenoteSpacing[1]{\def\m@m@footnote@spacing{#1}}
\newcommand*\setFloatSpacing[1]   {\def\m@m@float@spacing{#1}}

\newcommand*{\SingleSpacing}{%
  \setSpacing{\m@m@singlespace}%
  \edef\m@m@footnote@spacing{\baselinestretch}%
  \edef\m@m@float@spacing{\baselinestretch}%
  \@ifstar{}{\ifx\@nodocument\relax\vskip\baselineskip\fi}% correction for coming into single spacing
}
\SingleSpacing

\newcommand*{\@OnehalfSpacing}{
  \setSpacing{1.25}% default (10pt)
  \ifcase \@ptsize \relax   % 10pt
    \setSpacing{1.25}%
  \or%  11pt
    \setSpacing{1.213}%
  \or%  12pt
    \setSpacing{1.241}%
  \or\or% 14pt
    \setSpacing{1.20}%
  \or\or\or% 17pt
    \setSpacing{1.16}%
  \or\or% 9pt
    \setSpacing{1.35}%
  \else% the extended sizes
    \setSpacing{1.16}%
  \fi}
\newcommand*\OnehalfSpacing{%
  \@ifstar{%
    \@OnehalfSpacing%
    \edef\m@m@footnote@spacing{\baselinestretch}%
    \edef\m@m@float@spacing{\baselinestretch}%
  }{\@OnehalfSpacing}%
}

\newcommand*{\@DoubleSpacing}{
  \setSpacing{1.667}% default (10pt)
  \ifcase \@ptsize \relax   % 10pt
    \setSpacing{1.667}%
  \or%  11pt
    \setSpacing{1.618}%
  \or%  12pt
    \setSpacing{1.655}%
  \or\or% 14pt
    \setSpacing{1.60}%
  \or\or\or% 17pt
    \setSpacing{1.545}%
  \or\or% 9pt
    \setSpacing{1.8}%
  \else%       larger sizes
    \setSpacing{1.5}%
  \fi}
\newcommand*\DoubleSpacing{%
  \@ifstar{%
    \@DoubleSpacing%
    \edef\m@m@footnote@spacing{\baselinestretch}%
    \edef\m@m@float@spacing{\baselinestretch}%
  }{\@DoubleSpacing}%
}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% check what this does!!!!!!!!
 % \renewcommand*{\@setsize}[4]{%
 %   \@nomath#1%
 %   \let\@currsize#1%
 %   \baselineskip #2%
 %   \baselineskip \baselinestretch\baselineskip
 %   \parskip \baselinestretch\parskip
 %   \setbox\strutbox \hbox{%
 %     \vrule height.7\baselineskip
 %            depth .3\baselineskip
 %            width \z@}%
 %   \skip\footins \baselinestretch\skip\footins
 %   \normalbaselineskip\baselineskip#3#4}

\newenvironment{SingleSpace}{%
  \vskip\baselineskip
  \setSpacing{\m@m@singlespace}%
  \vskip -\baselineskip
}{\par}

\newenvironment{SingleSpace*}{%
%%  \vskip\baselineskip
  \setSpacing{\m@m@singlespace}%
  \vskip 0.5\baselineskip
}{\vskip -0.5\baselineskip}

\newcommand*{\m@mrestore@spacing}{%
  \par
  \vskip \parskip
  \vskip \baselineskip
  \endgroup
  \vskip -\parskip
  \vskip -\baselineskip}

\newenvironment{Spacing}[1]{%
  \par
  \begingroup
    \setSpacing{#1}}{\m@mrestore@spacing}

\newenvironment{OnehalfSpace}{%
  \begingroup
    \OnehalfSpacing}{\m@mrestore@spacing}
\newenvironment{OnehalfSpace*}{%
  \begingroup
    \OnehalfSpacing*}{\m@mrestore@spacing}

\newenvironment{DoubleSpace}{%
  \begingroup
    \DoubleSpacing}{\m@mrestore@spacing}
\newenvironment{DoubleSpace*}{%
  \begingroup
    \DoubleSpacing}{\m@mrestore@spacing}

\newcommand*{\memdskipstretch}{0.0}
\newcommand*{\setDisplayskipStretch}[1]{%
  \renewcommand*{\memdskipstretch}{#1}}
\newcommand*{\noDisplayskipStretch}{\setDisplayskipStretch{0.0}}

\newcommand*{\memdskips}{%
  \advance\abovedisplayskip \memdskipstretch\abovedisplayskip
  \advance\belowdisplayskip \memdskipstretch\belowdisplayskip
  \advance\abovedisplayshortskip \memdskipstretch\abovedisplayshortskip
  \advance\belowdisplayshortskip \memdskipstretch\belowdisplayshortskip}
\everydisplay\expandafter{%
  \the\everydisplay
  \memdskips}

\IfFormatAtLeastTF{2021/04/20}{%
  \AddToHook{cmd/@floatboxreset/after}{%
    \def\baselinestretch{\m@m@float@spacing}%
    \normalsize%
    \@nameuse{\@captype adjustment}%
  }
}{%
  \AtBeginDocument{%
    % \typeout{Old kernel, redefining \string\@xfloat\ instead of using a hook}
    \let\m@m@xfloat\@xfloat%
    \def\@xfloat #1[#2]{%
      \m@m@xfloat #1[#2]%
      \def\baselinestretch{\m@m@float@spacing}%
      \normalsize%
      \@nameuse{#1adjustment}%
    }%
  }%
}

\newdimen\memPD
\newenvironment{vminipage}{%
  \par
  \@ifnextchar[%]
    \@ivminipage
    {\@iiiminipage t\relax[s]}
}{%
  \par\global\memPD=\prevdepth
  \endminipage
  \par
  \kern-\memPD%     no pagebreak allowed here
  \hbox{\vrule depth \memPD width \z@}}

 \def\@ivminipage[#1]{%
  \@ifnextchar[%]
    {\@iiminipage{t}}{\@iiiminipage{t}\relax[s]}}
\newif\ifm@mnzpskip
\newcommand*{\traditionalparskip}{%
  \setlength\parskip{0\p@ \@plus \p@}
  \m@mnzpskipfalse}
\newskip\m@mabparskip
\newcommand*{\abnormalparskip}[1]{%
  \setlength{\parskip}{#1}\m@mabparskip=#1\relax
  \m@mnzpskiptrue}
\newcommand*{\nonzeroparskip}{\abnormalparskip{%
  0.5\baselineskip
  \@plus .1\baselineskip \@minus .1\baselineskip% NTG
%%  0.5/baselineskip \@plus 2pt% RF
}}
\traditionalparskip

\newcommand{\pretitle}[1]{\def\@bspretitle{#1}}
\newcommand{\posttitle}[1]{\def\@bsposttitle{#1}}
\newcommand{\preauthor}[1]{\def\@bspreauthor{#1}}
\newcommand{\postauthor}[1]{\def\@bspostauthor{#1}}
\newcommand{\predate}[1]{\def\@bspredate{#1}}
\newcommand{\postdate}[1]{\def\@bspostdate{#1}}

  \pretitle{\begin{center}\LARGE}
  \posttitle{\par\end{center}\vskip 0.5em}
  \preauthor{\begin{center}
    \large \lineskip .5em%
    \begin{tabular}[t]{c}}
  \postauthor{\end{tabular}\par\end{center}}
  \predate{\begin{center}\large}
  \postdate{\par\end{center}}

\newcommand{\maketitlehooka}{}
\newcommand{\maketitlehookb}{}
\newcommand{\maketitlehookc}{}
\newcommand{\maketitlehookd}{}

\newcommand{\thanksmarkseries}[1]{%
  \def\@bsmarkseries{\renewcommand{\thefootnote}%
                     {\@nameuse{#1}{footnote}}}}
\newcommand{\symbolthanksmark}{\thanksmarkseries{\fnsymbol}}
\newcommand{\@bscontmark}{\setcounter{footnote}{0}}
\newcommand{\continuousmarks}{\def\@bscontmark{}}
\newcommand{\thanksheadextra}[2]{%
  \def\@bsthanksheadpre{#1}%
  \def\@bsthanksheadpost{#2}}
\DeclareRobustCommand{\thanksmark}[1]{\footnotemark[#1]}
\newcommand{\thanksgap}[1]{\hspace{#1}}
\newcommand{\tamark}{\@thefnmark}

\newlength{\thanksmarkwidth}
\newlength{\thanksmarksep}
\newcommand{\thanksmarkstyle}[1]{\def\thanksscript##1{#1}}
\thanksmarkstyle{\textsuperscript{#1}}
\newcommand{\makethanksmarkhook}{}

\newcommand{\thanksfootmark}{%
  \ifdim\thanksmarkwidth < \z@
    \llap{\hb@xt@ -\thanksmarkwidth{%
          \hss\normalfont\thanksscript{\tamark}}%
          \hspace*{-\thanksmarkwidth}}%
  \else
    \ifdim\thanksmarkwidth = \z@
      {\normalfont\thanksscript{\tamark}}%
    \else
      \hb@xt@\thanksmarkwidth{\hss\normalfont\thanksscript{\tamark}}%
    \fi
  \fi}

\newcommand{\makethanksmark}{%
  \leavevmode%
  \parindent 1em\noindent
  \memRTLleftskip\thanksmarksep\relax
  \advance\memRTLleftskip\thanksmarkwidth
  \null\nobreak\hskip-\memRTLleftskip\relax
  \makethanksmarkhook\relax
  \thanksfootmark}

\newcommand{\usethanksrule}{\let\footnoterule\thanksrule}
\newcommand{\cancelthanksrule}{\let\footnoterule\@bsfootnoterule}

\thanksmarkseries{fnsymbol}  % symbols
\thanksheadextra{}{}
\setlength{\thanksmarkwidth}{1.8em}
\setlength{\thanksmarksep}{-\thanksmarkwidth}

\AtBeginDocument{%
  \let\thanksrule\footnoterule
  \let\@bsfootnoterule\footnoterule
}

\newlength{\droptitle}
\setlength{\droptitle}{0pt}

\newcommand{\maketitle}{\par
  \begingroup
    \@bsmarkseries
    \def\@makefnmark{\@textsuperscript{%
       \normalfont\@bsthanksheadpre \tamark \@bsthanksheadpost}}%
    \long\def\@makefntext##1{\makethanksmark ##1}
    \if@twocolumn
      \ifnum \col@number=\@ne
        \@maketitle
      \else
        \twocolumn[\@maketitle]%
      \fi
    \else
      \ifdim\pagetotal>\z@
        \newpage
      \fi
      \global\@topnum\z@
      \@maketitle
    \fi
    \thispagestyle{title}\@thanks
  \endgroup
  \@bscontmark  %  \setcounter{footnote}{0}%
  }
\aliaspagestyle{title}{plain}

\newcommand*{\@mem@titlefootkill}[1]{%
  \@memwarn{Do not use \string\footnote\space in
            \string\maketitle.\MessageBreak
            Use \protect\thanks\space instead}}

\newcommand{\@maketitle}{%
  \let\footnote\@mem@titlefootkill
  \ifdim\pagetotal>\z@
    \newpage
  \fi
  \null
  \vskip 2em%
        \vspace*{\droptitle}
  \maketitlehooka
  {\@bspretitle \@title \@bsposttitle}
  \maketitlehookb
  {\@bspreauthor \@author \@bspostauthor}
  \maketitlehookc
  {\@bspredate \@date \@bspostdate}
  \maketitlehookd
  \par
  \vskip 1.5em}

\newcommand\titlingpageend[2]{%
  \def\mem@titlingpage@clear@for@twoside{#1}%
  \def\mem@titlingpage@clear@for@oneside{#2}%
}
 % default
\titlingpageend{\cleardoublepage}{\clearpage}
\newenvironment{mem@titlingpage}%
  {\let\footnoterule\relax
   \let\footnotesize\small
   \if@twocolumn
     \@restonecoltrue\onecolumn
   \else
     \@restonecolfalse
   \fi
   \thispagestyle{titlingpage}%
   \if\mem@titlpg@reset\setcounter{page}{\@ne}\fi%
  }{%
   \thispagestyle{titlingpage}%
   \if@restonecol \twocolumn \fi
   % \if@twoside \cleardoublepage \else \clearpage \fi
   \if@twoside \mem@titlingpage@clear@for@twoside \else \mem@titlingpage@clear@for@oneside \fi
   \if\mem@titlpg@reset\setcounter{page}{\@ne}\fi}
\newenvironment{titlingpage}{%
  \def\mem@titlpg@reset{00}%
  \begin{mem@titlingpage}}{%
  \end{mem@titlingpage}}
\newenvironment{titlingpage*}{%
  \def\mem@titlpg@reset{01}%
  \begin{mem@titlingpage}}{%
  \end{mem@titlingpage}}
\aliaspagestyle{titlingpage}{empty}

\newcommand{\emptythanks}{\global\let\@thanks\@empty}

\newcommand*{\andnext}{%
  \end{tabular}\\ \begin{tabular}[t]{c}}

\newcommand{\@bsmtitlempty}{%
  \global\let\maketitle\relax
  \global\let\@maketitle\relax
  \global\let\title\relax
  \global\let\author\relax
  \global\let\date\relax
  \global\let\thanksmarkseries\relax
  \global\let\thanksfootextra\relax
  \global\let\thanksmark\relax
  \global\let\thanksgap\relax}

\newcommand{\keepthetitle}{%
  \@bsmtitlempty
  \global\let\thanks\relax
  \global\let\and\relax
  \global\let\andnext\relax
  \global\let\@thanks\@empty
  \global\let\@title\@empty
  \global\let\@author\@empty
  \global\let\@date\@empty}

\newcommand{\killtitle}{%
  \keepthetitle
  \global\let\thetitle\relax
  \global\let\theauthor\relax
  \global\let\thedate\relax}

\addtoiargdef{\title}{%
  \begingroup\let\footnote\@gobble}{%
  \begingroup
    \renewcommand{\thanks}[1]{}
    \renewcommand{\thanksmark}[1]{}
    \renewcommand{\thanksgap}[1]{}
    \protected@xdef\thetitle{#1}
  \endgroup\endgroup}
\addtoiargdef{\author}{%
  \begingroup\let\footnote\@gobble}{%
  \begingroup
    \renewcommand{\thanks}[1]{}
    \renewcommand{\and}{\unskip, }
    \renewcommand{\andnext}{\unskip, }
    \renewcommand{\thanksmark}[1]{}
    \renewcommand{\thanksgap}[1]{}
    \protected@xdef\theauthor{#1}
  \endgroup\endgroup}
\addtoiargdef{\date}{%
  \begingroup\let\footnote\@gobble}{%
  \begingroup
    \renewcommand{\thanks}[1]{}
    \renewcommand{\thanksmark}[1]{}
    \renewcommand{\thanksgap}[1]{}
    \protected@xdef\thedate{#1}
  \endgroup\endgroup}

\newcommand*{\bookpagemark}[1]{}
\newcommand*{\partmark}[1]{}
\newcommand*{\chaptermark}[1]{}

\newcommand*{\bibmark}{}
\newcommand*{\indexmark}{}
\newcommand*{\glossarymark}{}

\setcounter{secnumdepth}{2}
\newcounter{book}    \setcounter{book}{0}
\newcounter{part}    \setcounter{part}{0}
\newcounter{chapter} \setcounter{chapter}{0}
\newcounter{section}[chapter]
\newcounter{subsection}[section]
\newcounter{subsubsection}[subsection]
\newcounter{paragraph}[subsubsection]
\newcounter{subparagraph}[paragraph]
\renewcommand*{\thebook}{\@Roman\c@book}
\renewcommand*{\thepart}{\@Roman\c@part}
\renewcommand*{\thechapter}{\@arabic\c@chapter}
\renewcommand*{\thesection}{\thechapter.\@arabic\c@section}
\renewcommand*{\thesubsection}{%
              \thesection.\@arabic\c@subsection}
\renewcommand*{\thesubsubsection}{%
              \thesubsection.\@arabic\c@subsubsection}
\renewcommand*{\theparagraph}{%
              \thesubsubsection.\@arabic\c@paragraph}
\renewcommand*{\thesubparagraph}{%
              \theparagraph.\@arabic\c@subparagraph}
\newcommand{\@chapapp}{\chaptername}

\newcommand{\frontmatter}{%
  \@ifstar{\@smemfront}{\@memfront}}
\newcommand\@memfront@floats{%
  \counterwithout{figure}{chapter}
  \counterwithout{table}{chapter}
}
\newcommand{\@smemfront}{%
  \cleardoublepage
  \@mainmatterfalse
  \setcounter{secnumdepth}{-10}
  \@memfront@floats
}
\newcommand{\@memfront}{%
  \@smemfront\pagenumbering{roman}}

\newcommand{\mainmatter}{%
  \@ifstar{\@smemmain}{\@memmain}}
\newcommand\@memmain@floats{%
   \counterwithin{figure}{chapter}
   \counterwithin{table}{chapter}
}
\newcommand*{\@smemmain}{%
  \@mainmattertrue
  \setcounter{secnumdepth}{\value{maxsecnumdepth}}
  \ifartopt
    \if@twoside
      \cleardoublepage
    \else
      \clearpage
    \fi
  \else
    \cleardoublepage
    \@memmain@floats
  \fi}
\newcommand{\@memmain}{%
  \@smemmain\pagenumbering{arabic}}

\newcommand\@memback@floats{%
    \counterwithout{figure}{chapter}
    \counterwithout{table}{chapter}
    \setcounter{figure}{0}
    \setcounter{table}{0}
}
\newcommand{\backmatter}{%
  \ifartopt
    \clearpage
  \else
    \if@openright
      \cleardoublepage
    \else
      \clearpage
    \fi
  \fi
  \@mainmatterfalse
  \setcounter{secnumdepth}{-10}
  \ifartopt\else
    \@memback@floats
  \fi}

\def\theHbook{\the\value{book}}
\def\toclevel@book{-2}

\newcommand*{\book}{%
  \@setupbook
  \secdef\@book\@sbook}
\newcommand*{\beforebookskip}{\null\vfil}
\newcommand*{\midbookskip}{\par\vskip 2\onelineskip}
\newcommand*{\afterbookskip}{\vfil\newpage}

\newcommand{\@setupbook}{%
  \if@openright
    \cleardoublepage
  \else
    \clearpage
  \fi
  \thispagestyle{book}%
  \if@twocolumn
    \onecolumn
    \@tempswatrue
  \else
    \@tempswafalse
  \fi
  \beforebookskip}

\newcommand*{\booknamefont}{\normalfont\huge\bfseries}
\newcommand*{\booknumfont}{\normalfont\huge\bfseries}
\newcommand*{\booktitlefont}{\normalfont\Huge\bfseries}

\newcommand*{\printbookname}{\booknamefont \bookname}
\newcommand*{\booknamenum}{\space}
\newcommand*{\printbooknum}{\booknumfont \thebook}
\newcommand*{\printbooktitle}[1]{\booktitlefont #1}

\newcommand{\membookinfo}[3]{}
\newcommand{\membookstarinfo}[1]{}

\long\def\@book[#1]#2{%
  \M@gettitle{#1}%
  \def\f@rtoc{#1}%
  \@nameuse{book@f@rtoc@before@write@hook}%
  \phantomsection
  \mempreaddbooktotochook
  \ifnum \c@secnumdepth >-3\relax
    \refstepcounter{book}%
    \addcontentsline{toc}{book}%
      {\protect\booknumberline{\thebook}\f@rtoc}%
    \membookinfo{\thebook}{\f@rtoc}{#2}%
  \else
    \addcontentsline{toc}{book}{\f@rtoc}%
    \membookinfo{}{\f@rtoc}{#2}%
  \fi
  \mempostaddbooktotochook
  \bookpagemark{#1}%
  {\centering
   \interlinepenalty \@M
   \parskip\z@
   \normalfont
   \ifnum \c@secnumdepth >-3\relax
     \printbookname \booknamenum \printbooknum
     \midbookskip
   \fi
   \printbooktitle{#2}\par}%
  \@endbook}

\newcommand\mempreaddbooktotochook{}
\newcommand\mempostaddbooktotochook{}

\long\def\@sbook#1{%
  \M@gettitle{#1}%
  \phantomsection
  \membookstarinfo{#1}%
  {\centering
   \interlinepenalty \@M
   \parskip\z@
   \normalfont
   \printbooktitle{#1}\par}%
  \@endbook}

\newif\ifm@mnobooknewpage
  \m@mnobooknewpagefalse
\newcommand*{\bookblankpage}{\m@mnobooknewpagefalse}
\newcommand*{\nobookblankpage}{\m@mnobooknewpagetrue}

\newcommand*{\bookpageend}{\afterbookskip
  \ifm@mnobooknewpage
  \else
    \if@twoside
      \if@openright
        \null
        \thispagestyle{afterbook}%
        \newpage
      \fi
    \fi
  \fi
  \if@tempswa
    \twocolumn
  \fi}
\def\@endbook{\bookpageend}

\aliaspagestyle{book}{empty}
\aliaspagestyle{afterbook}{empty}

\newcommand{\part}{%
  \@setuppart
  \secdef\@part\@spart}
\newcommand{\beforepartskip}{\null\vfil}
\newcommand{\midpartskip}{\par\vskip 2\onelineskip}
\newcommand{\afterpartskip}{\vfil\newpage}

\newcommand{\@setuppart}{%
  \if@openright
    \cleardoublepage
  \else
    \clearpage
  \fi
  \thispagestyle{part}%
  \if@twocolumn
    \onecolumn
    \@tempswatrue
  \else
    \@tempswafalse
  \fi
  \beforepartskip}

\newcommand{\partnamefont}{\normalfont\huge\bfseries}
\newcommand{\partnumfont}{\normalfont\huge\bfseries}
\newcommand{\parttitlefont}{\normalfont\Huge\bfseries}

\newcommand{\printpartname}{\partnamefont \partname}
\newcommand{\partnamenum}{\space}
\newcommand{\printpartnum}{\partnumfont \thepart}
\newcommand{\printparttitle}[1]{\parttitlefont #1}

\newcommand{\mempartinfo}[3]{}
\newcommand{\mempartstarinfo}[1]{}

\long\def\@part[#1]#2{%
  \M@gettitle{#1}%
  \def\f@rtoc{#1}%
  \@nameuse{part@f@rtoc@before@write@hook}%
  \phantomsection
  \mempreaddparttotochook
  \ifnum \c@secnumdepth >-2\relax
    \refstepcounter{part}%
    \addcontentsline{toc}{part}%
      {\protect\partnumberline{\thepart}\f@rtoc}%
    \mempartinfo{\thepart}{\f@rtoc}{#2}%
  \else
    \addcontentsline{toc}{part}{\f@rtoc}%
    \mempartinfo{}{\f@rtoc}{#2}%
  \fi
  \mempostaddparttotochook
  \partmark{#1}%
  {\centering
   \interlinepenalty \@M
   \parskip\z@
   \normalfont
   \ifnum \c@secnumdepth >-2\relax
     \printpartname \partnamenum \printpartnum
     \midpartskip
   \fi
   \printparttitle{#2}\par}%
  \@endpart}

\newcommand\mempreaddparttotochook{}
\newcommand\mempostaddparttotochook{}

\long\def\@spart#1{%
  \M@gettitle{#1}%
  \phantomsection
  \mempartstarinfo{#1}%
  {\centering
   \interlinepenalty \@M
   \parskip\z@
   \normalfont
   \printparttitle{#1}\par}%
  \@endpart}

\newif\ifm@mnopartnewpage
  \m@mnopartnewpagefalse
\newcommand*{\partblankpage}{\m@mnopartnewpagefalse}
\newcommand*{\nopartblankpage}{\m@mnopartnewpagetrue}

\newcommand*{\partpageend}{\afterpartskip
  \ifm@mnopartnewpage
  \else
    \if@twoside
      \if@openright
        \null
        \thispagestyle{afterpart}%
        \newpage
      \fi
    \fi
  \fi
  \if@tempswa
    \twocolumn
  \fi}
\def\@endpart{\partpageend}

\aliaspagestyle{afterpart}{empty}

\newcommand\chapter{%
  \ifartopt\par\@nameuse{chapterblock}\else
    \clearforchapter
    \thispagestyle{chapter}
    \global\@topnum\z@
  \fi
  \m@mindentafterchapter
  \@ifstar{\@m@mschapter}{\@m@mchapter}}

\newcommand*\indentafterchapter{\def\m@mindentafterchapter{\@afterindenttrue}}
\newcommand*\noindentafterchapter{\def\m@mindentafterchapter{\@afterindentfalse}}
\noindentafterchapter

\newcommand{\@m@mchapter}[1][]{%
  \def\ch@pt@c{#1}% capture first optional arg
  \@ifnextchar[{\@chapter}{\@chapter[]}%
}
\def\m@m@empty{\@empty}

\newcommand{\memchapinfo}[4]{}
\newcommand{\memchapstarinfo}[2]{}
\newcommand{\memappchapinfo}[4]{}
\newcommand{\memappchapstarinfo}[2]{}

\newif\ifm@mpn@new@chap
  \m@mpn@new@chapfalse
\newif\ifm@mpn@new@schap
  \m@mpn@new@schapfalse

\def\@chapter[#1]#2{%
  \m@mpn@new@chaptrue%
  \m@mpn@new@schapfalse%
  \def\f@rbdy{#2}%
  \ifx\ch@pt@c\@empty % no optional args
    \def\f@rtoc{#2}%
    \def\f@rhdr{#2}%
  \else                  % at least one opt arg
    \let\f@rtoc\ch@pt@c
    \ifx\@empty#1\@empty
      \let\f@rhdr\ch@pt@c
    \else
      \def\f@rhdr{#1}%
    \fi
  \fi
  \m@m@Andfalse
  \ifnum \c@secnumdepth >\m@ne
    \if@mainmatter
      \m@m@Andtrue
    \fi
  \fi
  \ifm@m@And
    \refstepcounter{chapter}%
  \fi
  \ifartopt
    \@makechapterhead{#2}%
    \@afterheading
    \chaptermark{\f@rhdr}%
  \else
    \chaptermark{\f@rhdr}
    \insertchapterspace
    \if@twocolumn
      \@topnewpage[\@makechapterhead{#2}]%
    \else
      \@makechapterhead{#2}%
    \fi
    \@afterheading
  \fi
  \@nameuse{chapter@f@rtoc@before@write@hook}%
  \mempreaddchaptertotochook%
  \ifm@m@And
    \ifanappendix
      \addcontentsline{toc}{appendix}{%
        \protect\chapternumberline{\thechapter}\f@rtoc}%
      \memappchapinfo{\thechapter}{\f@rtoc}{\f@rhdr}{#2}%
    \else
      \addcontentsline{toc}{chapter}{%
        \protect\chapternumberline{\thechapter}\f@rtoc}%
      \memchapinfo{\thechapter}{\f@rtoc}{\f@rhdr}{#2}%
    \fi
  \else
    \addcontentsline{toc}{chapter}{\f@rtoc}%
    \ifanappendix
      \memappchapinfo{}{\f@rtoc}{\f@rhdr}{#2}%
    \else
      \memchapinfo{}{\f@rtoc}{\f@rhdr}{#2}%
    \fi
  \fi
  \mempostaddchaptertotochook%
  \ifheadnameref\ExpandArgs{V}\M@gettitle\f@rhdr\else\ExpandArgs{V}\M@gettitle\f@rtoc\fi%
  \memendofchapterhook%
}

\newcommand\mempreaddchaptertotochook{}
\newcommand\mempostaddchaptertotochook{}
\newcommand\memendofchapterhook{}
\newcommand\settocpreprocessor[2]{%
  \@namedef{#1@f@rtoc@before@write@hook}{#2}}
\def\@makechapterhead#1{%
  \chapterheadstart%
  {%
   \parskip \z@
   \parindent \z@ \memRTLraggedright \normalfont
   \ifm@m@And
     \printchaptername \chapternamenum \printchapternum
     \afterchapternum %
   \else
     \printchapternonum
   \fi
   \interlinepenalty\@M
   \printchaptertitle{#1} %
   \afterchaptertitle %
  }}

\newcommand*{\insertchapterspace}{%
  \addtocontents{lof}{\protect\addvspace{10pt}}%
  \addtocontents{lot}{\protect\addvspace{10pt}}}

\newlength{\beforechapskip} \setlength{\beforechapskip}{50pt}
\newlength{\midchapskip}    \setlength{\midchapskip}{20pt}
\newlength{\afterchapskip}  \setlength{\afterchapskip}{40pt}

\newcommand{\@chs@def@ult}{%
  \def\chapterheadstart{\vspace*{\beforechapskip}}%
  \def\printchaptername{\chapnamefont \@chapapp}%
  \def\chapternamenum{\space}%
  \def\printchapternum{\chapnumfont \thechapter}%
  \def\afterchapternum{\par\nobreak\vskip \midchapskip}%
  \def\printchapternonum{}%
  \def\printchaptertitle##1{\chaptitlefont ##1}%
  \def\afterchaptertitle{\par\nobreak\vskip \afterchapskip}%
  \def\chapnamefont{\normalfont\huge\bfseries}%
  \def\chapnumfont{\normalfont\huge\bfseries}%
  \def\chaptitlefont{\normalfont\Huge\bfseries}%
  \setlength{\beforechapskip}{50pt}%
  \setlength{\midchapskip}{20pt}%
  \setlength{\afterchapskip}{40pt}}

\newcommand{\@m@mschapter}[2][\@empty]{%
  \@schapter{#2}%
  \ifx \@empty#1
    \def\f@rhdr{#2}%
  \else%                    opt arg
    \def\f@rhdr{#1}%
    \setcounter{secnumdepth}{-10}%
    \chaptermark{#1}%
    \setcounter{secnumdepth}{\value{maxsecnumdepth}}%
  \fi
  \ifanappendix
    \memappchapstarinfo{\f@rhdr}{#2}%
  \else
    \memchapstarinfo{\f@rhdr}{#2}%
  \fi
  \ifheadnameref\ExpandArgs\M@gettitle\f@rhdr\else\M@gettitle{#2}\fi}

\newcommand{\@schapter}[1]{%
  \m@mpn@new@schaptrue%
  \m@mpn@new@chapfalse%
  \def\f@rbdy{#1}%
  \ifartopt
    \@makeschapterhead{#1}%
  \else
    \if@twocolumn
      \@topnewpage[\@makeschapterhead{#1}]%
    \else
      \@makeschapterhead{#1}%
    \fi
  \fi
  \@afterheading}

\def\@makeschapterhead#1{%
  \chapterheadstart
  {%
   \parskip \z@%
   \parindent \z@ \memRTLraggedright \normalfont
   \printchapternonum
   \interlinepenalty\@M
   \printchaptertitle{#1}%
   \afterchaptertitle}%
}

\newcommand{\makechapterstyle}[2]{\@namedef{chs@#1}{\@chs@def@ult #2}}
\newcommand{\chapterstyle}[1]{\@nameuse{chs@#1}}

\makechapterstyle{default}{}%
 %%  \setlength{\beforechapskip}{50pt}
 %%  \def\chapterheadstart{\vspace*{\beforechapskip}}
 %%  \def\chapnamefont{\normalfont\huge\bfseries}
 %%  \def\printchaptername{\chapnamefont \@chapapp}
 %%  \def\chapternamenum{\space}
 %%  \def\chapnumfont{\normalfont\huge\bfseries}
 %%  \def\printchapternum{\chapnumfont \thechapter}
 %%  \setlength{\midchapskip}{20pt}
 %%  \def\afterchapternum{\par\nobreak\vskip \midchapskip}
 %%  \def\printchapternonum{}
 %%  \def\chaptitlefont{\normalfont\Huge\bfseries}
 %%  \def\printchaptertitle##1{\chaptitlefont ##1}
 %%  \setlength{\afterchapskip}{40pt}
 %%  \def\afterchaptertitle{\par\nobreak\vskip \afterchapskip}
\chapterstyle{default}

\makechapterstyle{section}{%
  \chapterstyle{default}
  \renewcommand{\printchaptername}{}
  \renewcommand{\chapternamenum}{}
  \renewcommand{\chapnumfont}{\normalfont\Huge\bfseries}
  \renewcommand{\printchapternum}{\chapnumfont \thechapter\space}
  \renewcommand{\afterchapternum}{}}

\makechapterstyle{article}{%
  \chapterstyle{default}
  \setlength{\beforechapskip}{3.5ex \@plus 1ex \@minus .2ex}
  \renewcommand*{\chapterheadstart}{\vspace{\beforechapskip}}
  \setlength{\afterchapskip}{2.3ex \@plus .2ex}
  \renewcommand{\printchaptername}{}
  \renewcommand{\chapternamenum}{}
  \renewcommand{\chaptitlefont}{\normalfont\Large\bfseries}
  \renewcommand{\chapnumfont}{\chaptitlefont}
  \renewcommand{\printchapternum}{\chapnumfont \thechapter\quad}
  \renewcommand{\afterchapternum}{}}

\makechapterstyle{reparticle}{%
  \chapterstyle{default}
  \setlength{\beforechapskip}{3.5ex \@plus 1ex \@minus .2ex}
  \renewcommand*{\chapterheadstart}{\vspace{\beforechapskip}}
  \setlength{\afterchapskip}{2.3ex \@plus .2ex}
  \renewcommand*{\printchaptername}{}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\chaptitlefont}{\normalfont\Large\bfseries}
  \renewcommand*{\chapnumfont}{\chaptitlefont}
  \renewcommand*{\printchapternum}{\@hangfrom{\chapnumfont \thechapter\quad}}%
  \renewcommand*{\afterchapternum}{}}

\newcommand*{\reparticle}{%
  \chapterstyle{reparticle}
  \setsecheadstyle{\normalfont\large\bfseries\memRTLraggedright}%
  \setsubsecheadstyle{\normalfont\bfseries\memRTLraggedright}%
}

\makechapterstyle{hangnum}{%
  \chapterstyle{default}
  \renewcommand*{\chapnumfont}{\chaptitlefont}
  \settowidth{\chapindent}{\chapnumfont 999}
  \renewcommand*{\printchaptername}{}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\printchapternum}{%
    \noindent\llap{\makebox[\chapindent][l]{\chapnumfont \thechapter}}}
  \renewcommand*{\afterchapternum}{}}

\newlength{\chapindent}

\makechapterstyle{companion}{%
  \chapterstyle{default}
  \renewcommand*{\chapnamefont}{\normalfont\LARGE\scshape}
  \renewcommand*{\printchaptername}{\raggedleft\chapnamefont \@chapapp}
  \renewcommand*{\chapnumfont}{\normalfont\Huge}
  \setlength{\chapindent}{\marginparsep}
  \addtolength{\chapindent}{\marginparwidth}
  \renewcommand*{\printchaptertitle}[1]{%
    \begin{adjustwidth}{}{-\chapindent}
      \raggedleft \chaptitlefont ##1\par\nobreak
    \end{adjustwidth}}}

\makechapterstyle{demo}{%
  \chapterstyle{default}
  \renewcommand*{\printchaptername}{\centering}
  \renewcommand*{\printchapternum}{\chapnumfont \numtoName{\c@chapter}}
  \renewcommand*{\chaptitlefont}{\normalfont\Huge\sffamily}
  \renewcommand*{\printchaptertitle}[1]{%
    \hrule\vskip\onelineskip \raggedleft \chaptitlefont ##1}
  \renewcommand*{\afterchaptertitle}%
               {\vskip\onelineskip \hrule\vskip \afterchapskip}}

\makechapterstyle{bianchi}{%
  \chapterstyle{default}
  \renewcommand*{\chapnamefont}{\normalfont\Large\sffamily\itshape}
  \renewcommand*{\chapnumfont}{\normalfont\huge}
  \renewcommand*{\printchaptername}{%
    \chapnamefont\centering\@chapapp}
  \renewcommand*{\printchapternum}{\chapnumfont \textit{\thechapter}}
  \renewcommand*{\chaptitlefont}{\normalfont\Huge\sffamily}
  \renewcommand*{\printchaptertitle}[1]{%
    \hrule\vskip\onelineskip \centering \chaptitlefont\textbf{##1}\par}
  \renewcommand*{\afterchaptertitle}{\vskip\onelineskip \hrule\vskip
    \afterchapskip}
  \renewcommand*{\printchapternonum}{%
    \vphantom{\chapnumfont \textit{9}}\afterchapternum}}

\makechapterstyle{bringhurst}{%
  \chapterstyle{default}
  \renewcommand*{\chapterheadstart}{}
  \renewcommand*{\printchaptername}{}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\printchapternum}{}
  \renewcommand*{\afterchapternum}{}
  \renewcommand*{\printchaptertitle}[1]{%
    \memRTLraggedright\Large\scshape\MakeTextLowercase{##1}}
  \renewcommand*{\afterchaptertitle}{%
  \vskip\onelineskip \hrule\vskip\onelineskip}}

\makechapterstyle{brotherton}{%
  \chapterstyle{default}
  \renewcommand*{\printchapternum}{\chapnumfont
    \ifanappendix \thechapter \else \numtoName{\c@chapter}\fi}}

\makechapterstyle{chappell}{%
  \chapterstyle{default}
  \setlength{\beforechapskip}{0pt}
  \renewcommand*{\chapnamefont}{\large\centering}
  \renewcommand*{\chapnumfont}{\large}
  \renewcommand*{\printchapternonum}{%
    \vphantom{\printchaptername \chapnumfont 1}
    \afterchapternum
    \vskip \onelineskip \vskip -\topskip}
  \renewcommand*{\chaptitlefont}{\Large\itshape}
  \renewcommand*{\printchaptertitle}[1]{%
    \hrule\vskip\onelineskip \centering\chaptitlefont ##1}}

\makechapterstyle{culver}{%
  \chapterstyle{default}
  \chapterstyle{article}%
  \renewcommand*{\thechapter}{\Roman{chapter}}
  \renewcommand*{\printchapternum}{% center number/title
    \centering\chapnumfont \thechapter\space\space}%
  \renewcommand*{\printchapternonum}{\centering}
  \renewcommand*{\clearforchapter}{}% no new page
  \aliaspagestyle{chapter}{headings}}% no special pagestyle

\makechapterstyle{dash}{%
  \chapterstyle{default}
  \setlength{\beforechapskip}{5\onelineskip}
  \renewcommand*{\printchaptername}{}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\chapnumfont}{\normalfont\large}
  \settoheight{\midchapskip}{\chapnumfont 1}
  \renewcommand*{\printchapternum}{\centering \chapnumfont
    \rule[0.5\midchapskip]{1em}{0.4pt} \thechapter\
    \rule[0.5\midchapskip]{1em}{0.4pt}}
  \renewcommand*{\afterchapternum}{\par\nobreak\vskip 0.5\onelineskip}
  \renewcommand*{\printchapternonum}{\centering
                 \vphantom{\chapnumfont 1}\afterchapternum}
  \renewcommand*{\chaptitlefont}{\normalfont\Large}
  \renewcommand*{\printchaptertitle}[1]{\centering \chaptitlefont ##1}
  \setlength{\afterchapskip}{2.5\onelineskip}}

\makechapterstyle{demo2}{%
  \chapterstyle{default}
  \renewcommand*{\printchaptername}{\centering}
  \renewcommand*{\printchapternum}{\chapnumfont
     \ifanappendix \thechapter \else \numtoName{\c@chapter}\fi}
  \renewcommand*{\chaptitlefont}{\normalfont\Huge\sffamily}
  \renewcommand*{\printchaptertitle}[1]{%
    \hrule\vskip\onelineskip \raggedleft \chaptitlefont ##1}
  \renewcommand*{\afterchaptertitle}{%
    \vskip\onelineskip \hrule\vskip \afterchapskip}
  \setlength{\beforechapskip}{3\baselineskip}
  \renewcommand*{\printchapternonum}{%
    \vphantom{\chapnumfont One}
    \afterchapternum%
    \vskip\topskip}
  \setlength{\beforechapskip}{2\onelineskip}}

\makechapterstyle{demo3}{%
  \chapterstyle{default}
  \renewcommand*{\printchaptername}{\centering}
  \renewcommand*{\chapnumfont}{\normalfont\HUGE\itshape}
  \renewcommand*{\printchapternum}{\chapnumfont
     \ifanappendix \thechapter \else \numtoName{\c@chapter}\fi}
  \renewcommand*{\chaptitlefont}{\normalfont\Huge\sffamily}
  \renewcommand*{\printchaptertitle}[1]{%
    \hrule\vskip\onelineskip \raggedleft \chaptitlefont ##1}
  \renewcommand*{\afterchaptertitle}{%
    \vskip\onelineskip \hrule\vskip \afterchapskip}
  \setlength{\beforechapskip}{0pt}
  \setlength{\midchapskip}{2\onelineskip}
  \setlength{\afterchapskip}{2\onelineskip}
  \renewcommand*{\printchapternonum}{%
    \vphantom{\chapnumfont One}
    \afterchapternum%
    \vskip\topskip}}

\newcommand\chs@ell@helper[1]{%
  \par%
    \begin{adjustwidth}{}{-\chapindent}
      \begin{tabularx}{\linewidth}{>{\raggedleft\arraybackslash}X|}%|emacs
        \leavevmode\chapnumfont #1\vphantom{1}%
        \hspace*{3.6pt}%
        \rule[-13.5pt]{0pt}{14.8mm}%
        \\%
        \hline%
      \end{tabularx}%
    \end{adjustwidth}%
    \par%
  }%

\makechapterstyle{ell}{%
  \chapterstyle{default}
  \renewcommand*{\chapnumfont}{\normalfont\HUGE\sffamily}
  \renewcommand*{\chaptitlefont}{\normalfont\huge\sffamily}
  \settowidth{\chapindent}{\chapnumfont 111}
  % \renewcommand*{\chapterheadstart}{\begingroup
  %   \vspace*{\beforechapskip}%
  %   \begin{adjustwidth}{}{-\chapindent}%
  %   \hrulefill
  %   \smash{\rule{0.4pt}{15mm}}
  %   \end{adjustwidth}\endgroup}
  \renewcommand*{\printchaptername}{}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\printchapternum}{%
    % \begin{adjustwidth}{}{-\chapindent}
    % \hfill
    % \raisebox{10mm}[0pt][0pt]{\chapnumfont \thechapter}%
    %                           \hspace*{1em}
    % \end{adjustwidth}\vspace*{-3.0\onelineskip}
    \chs@ell@helper{\thechapter}%
  }
  \renewcommand\printchapternonum{%
    \chs@ell@helper{}\afterchapternum}
  \renewcommand*{\printchaptertitle}[1]{%
    %\vskip\onelineskip
    \raggedleft {\chaptitlefont ##1}\par\nobreak}}

\makechapterstyle{ger}{%
  \chapterstyle{default}
  \renewcommand*{\chapterheadstart}{\vspace*{\beforechapskip}
  \mbox{}\\\mbox{}\rule[0pt]{\textwidth}{0.4pt}\par}
  \setlength{\midchapskip}{20pt}
  \renewcommand*{\printchaptertitle}[1]{\chaptitlefont ##1
    \\\mbox{}\rule[5pt]{\textwidth}{0.4pt}}}

\makechapterstyle{lyhne}{%  needs graphicx package
  \chapterstyle{default}
  \setlength{\beforechapskip}{1.5cm}
  \setlength{\afterchapskip}{1cm}
  \setlength{\midchapskip}{2cm}
  \renewcommand*{\chapnamefont}{\normalfont\normalsize\scshape\raggedleft}
  \renewcommand*{\chaptitlefont}{\normalfont\normalsize\bfseries\sffamily\raggedleft}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\printchapternum}{\makebox[0pt][l]{\hspace{0.2em}%
    \resizebox{!}{2ex}{\chapnamefont\bfseries\sffamily\thechapter}}}
  \renewcommand*{\afterchapternum}{\par\hspace{1.5cm}\hrule\vspace{0.2cm}}
 \renewcommand*{\printchapternonum}{\vphantom{\chapnamefont 1}\afterchapternum}
  \renewcommand*{\afterchaptertitle}{\vskip 0.2cm
    \hrule\vskip\afterchapskip}}

\makechapterstyle{madsen}{% requires graphicx package
  \chapterstyle{default}
  \renewcommand*{\chapnamefont}{%
    \normalfont\Large\scshape\raggedleft}
  \renewcommand*{\chaptitlefont}{%
    \normalfont\Huge\bfseries\sffamily\raggedleft}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\printchapternum}{%
    \makebox[0pt][l]{\hspace{0.4em}%
      \resizebox{!}{4ex}{%
        \chapnamefont\bfseries\sffamily\thechapter}%
    }%
  }%
  \renewcommand*{\printchapternonum}{%
    \chapnamefont \phantom{\printchaptername \chapternamenum%
      \makebox[0pt][l]{\hspace{0.4em}%
        \resizebox{!}{4ex}{%
          \chapnamefont\bfseries\sffamily 1}%
      }%
    }%
    \afterchapternum %
  }%
  \renewcommand*{\afterchapternum}{%
    \par\hspace{1.5cm}\hrule\vskip\midchapskip}}

\newcommand*{\colorchapnum}{}
\newcommand*{\colorchaptitle}{}
\makechapterstyle{pedersen}{%
  \chapterstyle{default}
  \setlength{\beforechapskip}{-20pt}
  \setlength{\afterchapskip}{10pt}
  \renewcommand*{\chapnamefont}{\normalfont\LARGE\itshape}
  \renewcommand*{\chapnumfont}{\normalfont\HUGE\itshape\colorchapnum}
  \renewcommand*{\chaptitlefont}{\normalfont\huge\itshape\colorchaptitle}
  \renewcommand*{\afterchapternum}{}
  \renewcommand*{\printchaptername}{}
  \setlength{\midchapskip}{20mm}% was \numberheight
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\printchapternum}{%
    \sidebar{\raisebox{0pt}[0pt][0pt]{\makebox[0pt][l]{%
      \resizebox{!}{\midchapskip}{\chapnumfont\thechapter}}}}}
  \renewcommand*{\printchaptertitle}[1]{\chaptitlefont ##1}}

%% Thomas Dye's southall chapter style
\makechapterstyle{southall}{%
  \chapterstyle{default}
  \setlength{\afterchapskip}{5\baselineskip}
  \setlength{\beforechapskip}{36pt}%    \headindent
  \setlength{\midchapskip}{\textwidth}% \rightblock
  \addtolength{\midchapskip}{-\beforechapskip}
  \renewcommand*{\chapterheadstart}{\vspace*{2\baselineskip}}
  \renewcommand*{\chaptitlefont}{\huge\rmfamily\memRTLraggedright}
  \renewcommand*{\chapnumfont}{\chaptitlefont}
  \renewcommand*{\printchaptername}{}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\afterchapternum}{}
  \renewcommand*{\printchapternum}{%
    \begin{minipage}[t][\baselineskip][b]{\beforechapskip}
      {\vspace{0pt}\chapnumfont%%%\figureversion{lining}
                   \thechapter}
    \end{minipage}}
  \renewcommand*{\printchaptertitle}[1]{%
    \hfill\begin{minipage}[t]{\midchapskip}
      {\vspace{0pt}\chaptitlefont ##1\par}\end{minipage}}
  \renewcommand*{\afterchaptertitle}{%
    \par\vspace{\baselineskip}%
    \hrulefill \par\nobreak\noindent \vskip \afterchapskip}}

\makechapterstyle{thatcher}{%
  \chapterstyle{default}
  \renewcommand*{\chapterheadstart}{}
  \renewcommand*{\printchaptername}{%
    \centerline{\chapnumfont{\@chapapp\ \thechapter}}}
  \renewcommand*{\chapternamenum}{}
  \renewcommand*{\chapnumfont}{\normalfont\scshape\MakeTextLowercase}
  \renewcommand*{\printchapternum}{}
  \renewcommand*{\afterchapternum}{%
    \par\centerline{\parbox{0.5in}{\hrulefill}}\par}
  \renewcommand*{\printchapternonum}{%
    \vphantom{\chapnumfont \@chapapp 1}\par
    \parbox{0.5in}{}\par}
  \renewcommand*{\chaptitlefont}{\normalfont\large}
  \renewcommand*{\printchaptertitle}[1]{%
    \centering \chaptitlefont\MakeTextUppercase{##1}}}

\makechapterstyle{veelo}{%
   \setlength{\afterchapskip}{40pt}
  \renewcommand*{\chapterheadstart}{\vspace*{40pt}}
  \renewcommand*{\afterchapternum}{\par\nobreak\vskip 25pt}
   \renewcommand*{\chapnamefont}{\normalfont\LARGE\flushright}
   \renewcommand*{\chapnumfont}{\normalfont\HUGE}
   \renewcommand*{\chaptitlefont}{\normalfont\HUGE\bfseries\flushright}
   \renewcommand*{\printchaptername}{%
     \chapnamefont\MakeTextUppercase{\@chapapp}}
   \renewcommand*{\chapternamenum}{}
  \setlength{\beforechapskip}{18mm}%  \numberheight
  \setlength{\midchapskip}{\paperwidth}% \barlength
  \addtolength{\midchapskip}{-\textwidth}
  \addtolength{\midchapskip}{-\spinemargin}
   \renewcommand*{\printchapternum}{%
     \makebox[0pt][l]{%
       \hspace{.8em}%
       \resizebox{!}{\beforechapskip}{\chapnumfont \thechapter}%
       \hspace{.8em}%
       \rule{\midchapskip}{\beforechapskip}%
     }%
   }%
   \makeoddfoot{plain}{}{}{\thepage}}

\makechapterstyle{verville}{%
 % \chapterstyle{default}
  \setlength{\beforechapskip}{0pt}
  \renewcommand*{\printchaptername}{}
  \renewcommand*{\printchapternum}{%
    \hrule \vskip 0.5\onelineskip
    \Huge \centering \thechapter.\ }
  \renewcommand*{\printchapternonum}{%
    \hrule \vskip 0.5\onelineskip
    \Huge \centering}
  \renewcommand*{\afterchapternum}{}
  \setlength{\midchapskip}{0pt}
  \renewcommand*{\printchaptertitle}[1]{%
    ##1 \par
    \vskip 0.5\onelineskip
   \hrule}}

\makechapterstyle{crosshead}{%
  \setlength{\beforechapskip}{2\onelineskip}%
  \renewcommand*{\chapterheadstart}{\vspace{\beforechapskip}}%
  \setlength{\afterchapskip}{2\onelineskip \@plus .2\onelineskip
                             \@minus 0.2\onelineskip}%
  \renewcommand*{\printchaptername}{}%
  \renewcommand*{\chapternamenum}{}%
  \renewcommand*{\chapnumfont}{\normalfont\LARGE\bfseries}%
  \renewcommand*{\chaptitlefont}{\chapnumfont}%
  \renewcommand*{\printchapternum}{%
    \centering\chapnumfont \thechapter\quad}%
  \renewcommand{\afterchapternum}{}%
  \renewcommand*{\printchapternonum}{\centering}}

\makechapterstyle{dowding}{%
  \setlength{\beforechapskip}{2\onelineskip}%
  \setlength{\afterchapskip}{1.5\onelineskip \@plus .1\onelineskip
                            \@minus 0.167\onelineskip}%
  \renewcommand*{\chapnamefont}{\normalfont}%
  \renewcommand*{\chapnumfont}{\chapnamefont}%
  \renewcommand*{\printchapternum}{\centering\chapnumfont \ifanappendix \thechapter
                 \else \numtoName{\c@chapter}\fi}%
  \renewcommand*{\chaptitlefont}{\normalfont\itshape\huge\centering}%
  \renewcommand*{\printchapternonum}{%
    \vphantom{\printchaptername}\vskip\midchapskip}}

\makechapterstyle{komalike}{%
  \setlength{\beforechapskip}{2\onelineskip}%
  \setlength{\afterchapskip}{1.5\onelineskip \@plus .1\onelineskip
                             \@minus 0.167\onelineskip}%
  \renewcommand*{\printchaptername}{}%
  \renewcommand*{\chapternamenum}{}%
  \renewcommand*{\chapnumfont}{\normalfont\LARGE\sffamily\bfseries}%
  \renewcommand*{\printchapternum}{\chapnumfont \thechapter\space}%
  \renewcommand*{\afterchapternum}{}%
  \renewcommand*{\chaptitlefont}{\normalfont\LARGE\sffamily\bfseries}}

\makechapterstyle{ntglike}{%
  \setlength{\beforechapskip}{50pt \@plus 20pt}%
  \renewcommand*{\chapnamefont}{\normalfont\Large\bfseries}%
  \renewcommand*{\chapnumfont}{\normalfont\Large\bfseries}%
  \renewcommand*{\chaptitlefont}{\normalfont\Large\bfseries}}

\makechapterstyle{tandh}{%
  \setlength{\beforechapskip}{1\onelineskip}%
  \setlength{\afterchapskip}{2\onelineskip \@plus .1\onelineskip
                            \@minus 0.167\onelineskip}%
  \renewcommand*{\printchaptername}{}%
  \renewcommand*{\chapternamenum}{}%
  \renewcommand*{\chapnumfont}{\normalfont\huge\bfseries}%
  \renewcommand*{\printchapternum}{\chapnumfont \thechapter\quad}%
  \renewcommand*{\afterchapternum}{}%
  \renewcommand*{\chaptitlefont}{\chapnumfont\memRTLraggedright}}

\makechapterstyle{wilsondob}{%
  \setlength{\beforechapskip}{2\onelineskip}%
  \setlength{\afterchapskip}{4\onelineskip \@plus .1\onelineskip
                             \@minus 0.167\onelineskip}%
  \renewcommand*{\printchaptername}{}%
  \renewcommand*{\chapternamenum}{}%
  \renewcommand*{\chapnumfont}{\normalfont\Huge\itshape}%
  \renewcommand*{\printchapternum}{\raggedleft\chapnumfont \thechapter\quad}%
  \renewcommand*{\afterchapternum}{}%
  \renewcommand*{\chaptitlefont}{\chapnumfont}%
  \renewcommand*{\printchapternonum}{\raggedleft}}

\newif\ifraggedbottomsection
  \raggedbottomsectionfalse
\newcommand*{\raggedbottomsection}{\raggedbottomsectiontrue}
\newcommand*{\normalbottomsection}{\raggedbottomsectionfalse}
\newcommand*{\bottomsectionpenalty}{\z@}

\newlength{\bottomsectionskip}
  \setlength{\bottomsectionskip}{10mm}

\newcommand{\@trplargomm}[1]{%
  \@ifnextchar[{\@xtrplargomm{#1}}%
               {\@xxtrplarg{#1}}}
\long\def\@xtrplargomm#1[#2]{\@dblarg{#1[#2]}}
\newcommand{\@xxtrplarg}[2]{#1[{#2}][{#2}]{#2}}
\newcommand{\@trplargoom}[1]{%
  \@ifnextchar[{\@xtrplargoom{#1}}%
               {\@xxtrplarg{#1}}}
\long\def\@xtrplargoom#1[#2]{%
  \@ifnextchar[{#1[{#2}]}%
               {#1[{#2}][{#2}]}}

\newcommand{\memsecinfo}[5]{}
\newcommand{\memsecstarinfo}[2]{}

\renewcommand{\@startsection}[6]{%
  \@nameuse{#1block}%
  \ifraggedbottomsection\if@nobreak\else
    \vskip\z@\@plus\bottomsectionskip
    \penalty\bottomsectionpenalty
    \vskip\z@\@plus -\bottomsectionskip
  \fi\fi
  \def\m@msecn@me{#1}%
  \if@noskipsec \leavevmode \fi
  \par
  \@tempskipa #4\relax
  \@afterindenttrue
  \ifdim \@tempskipa <\z@
    \@tempskipa -\@tempskipa \@afterindentfalse
  \fi
  \if@nobreak
    \everypar{}%
  \else
    \addpenalty\@secpenalty\addvspace\@tempskipa
    \addvspace{-\parskip}% <--- added 2011/03/02
  \fi
  \@ifstar
    {\@ssect{#3}{#4}{#5}{#6}}%
    {\@trplargoom{\M@sect{#1}{#2}{#3}{#4}{#5}{#6}}}}

\def\@xsect#1{%
  \@tempskipa #1\relax
  \ifdim \@tempskipa>\z@
    \par \nobreak
    \vskip \@tempskipa
    \vskip-\parskip%<--- added 2011/03/02
    \@afterheading
  \else
    \@nobreakfalse
    \global\@noskipsectrue
    \everypar{%
      \if@noskipsec
        \global\@noskipsecfalse
       {\setbox\z@\lastbox}%
        \clubpenalty\@M
        \begingroup \@svsechd \endgroup
        \unskip
        \@tempskipa #1\relax
        \hskip -\@tempskipa
      \else
        \clubpenalty \@clubpenalty
        \everypar{}%
      \fi}%
  \fi
  \ignorespaces}

\def\M@sect#1#2#3#4#5#6[#7][#8]#9{%
  \ifheadnameref\M@gettitle{#8}\else\M@gettitle{#7}\fi
  \ifnum #2>\c@secnumdepth
    \let\@svsec\@empty
    \memsecinfo{#1}{}{#7}{#8}{#9}%
  \else
    \refstepcounter{#1}%
    \protected@edef\@svsec{\@seccntformat{#1}\relax}%
    \memsecinfo{#1}{\@nameuse{the#1}}{#7}{#8}{#9}%
  \fi
  \@tempskipa #5\relax
  \ifdim \@tempskipa>\z@
    \begingroup
      #6{%
      \@hangfrom{\hskip #3\relax\@svsec}%
        \interlinepenalty \@M #9\@@par}%
    \endgroup
    \csname #1mark\endcsname{#8}%
    \addcontentsline{toc}{#1}{%
      \ifnum #2>\c@secnumdepth \else
        \protect\numberline{\csname the#1\endcsname}%
      \fi
      #7}%
  \else
    \def\@svsechd{%
      #6{\hskip #3\relax
     \@svsec #9}%
     \csname #1mark\endcsname{#8}%
     \addcontentsline{toc}{#1}{%
       \ifnum #2>\c@secnumdepth \else
        \protect\numberline{\csname the#1\endcsname}%
       \fi
       #7}}%
  \fi
  \@xsect{#5}}

\def\@sect#1#2#3#4#5#6[#7]#8{\M@sect{#1}{#2}{#3}{#4}{#5}{#6}[{#7}][{#7}]{#8}}

\let\@mem@old@ssect\@ssect
\def\@ssect#1#2#3#4#5{%
  \M@gettitle{#5}%
  \memsecstarinfo{\m@msecn@me}{#5}%
  \@mem@old@ssect{#1}{#2}{#3}{#4}{#5}}

\newcommand{\section}{%
  \sechook%
  \@startsection{section}{1}%  level 1
      {\secindent}%            heading indent
      {\beforesecskip}%        skip before the heading
      {\aftersecskip}%         skip after the heading
      {\normalfont\secheadstyle}} % font
\newcommand{\sechook}{}
\newcommand{\setsechook}[1]{\renewcommand{\sechook}{#1}}
\newlength{\secindent}
\newcommand{\setsecindent}[1]{\setlength{\secindent}{#1}}
  \setsecindent{\z@}
\newskip\beforesecskip
\newcommand{\setbeforesecskip}[1]{\setlength{\beforesecskip}{#1}}
  \setbeforesecskip{-3.5ex \@plus -1ex \@minus -.2ex}
\newskip\aftersecskip
\newcommand{\setaftersecskip}[1]{\setlength{\aftersecskip}{#1}}
  \setaftersecskip{2.3ex \@plus .2ex}
\newcommand{\secheadstyle}{}
\newcommand{\setsecheadstyle}[1]{\renewcommand{\secheadstyle}{#1}}
  \setsecheadstyle{\Large\bfseries\memRTLraggedright}

\newcommand{\subsection}{%
  \subsechook%
  \@startsection{subsection}{2}%  level 2
      {\subsecindent}%            heading indent
      {\beforesubsecskip}%        skip before the heading
      {\aftersubsecskip}%         skip after the heading
      {\normalfont\subsecheadstyle}} % font
\newcommand{\subsechook}{}
\newcommand{\setsubsechook}[1]{\renewcommand{\subsechook}{#1}}
\newlength{\subsecindent}
\newcommand{\setsubsecindent}[1]{\setlength{\subsecindent}{#1}}
  \setsubsecindent{\z@}
\newskip\beforesubsecskip
\newcommand{\setbeforesubsecskip}[1]{\setlength{\beforesubsecskip}{#1}}
  \setbeforesubsecskip{-3.25ex \@plus -1ex \@minus -.2ex}
\newskip\aftersubsecskip
\newcommand{\setaftersubsecskip}[1]{\setlength{\aftersubsecskip}{#1}}
  \setaftersubsecskip{1.5ex \@plus .2ex}
\newcommand{\subsecheadstyle}{}
\newcommand{\setsubsecheadstyle}[1]{\renewcommand{\subsecheadstyle}{#1}}
  \setsubsecheadstyle{\large\bfseries\memRTLraggedright}

\newcommand{\subsubsection}{%
  \subsubsechook%
  \@startsection{subsubsection}{3}%  level 3
      {\subsubsecindent}%            heading indent
      {\beforesubsubsecskip}%        skip before the heading
      {\aftersubsubsecskip}%         skip after the heading
      {\normalfont\subsubsecheadstyle}} % font
\newcommand{\subsubsechook}{}
\newcommand{\setsubsubsechook}[1]{\renewcommand{\subsubsechook}{#1}}
\newlength{\subsubsecindent}
\newcommand{\setsubsubsecindent}[1]{%
            \setlength{\subsubsecindent}{#1}}
\setsubsubsecindent{\z@}
\newskip\beforesubsubsecskip
\newcommand{\setbeforesubsubsecskip}[1]{%
            \setlength{\beforesubsubsecskip}{#1}}
\setbeforesubsubsecskip{-3.25ex \@plus -1ex \@minus -.2ex}
\newskip\aftersubsubsecskip
\newcommand{\setaftersubsubsecskip}[1]{%
            \setlength{\aftersubsubsecskip}{#1}}
\setaftersubsubsecskip{1.5ex \@plus .2ex}
\newcommand{\subsubsecheadstyle}{}
\newcommand{\setsubsubsecheadstyle}[1]{%
            \renewcommand{\subsubsecheadstyle}{#1}}
\setsubsubsecheadstyle{\normalsize\bfseries\memRTLraggedright}

\newcommand{\paragraph}{%
  \parahook%
  \@startsection{paragraph}{4}%  level 4
      {\paraindent}%            heading indent
      {\beforeparaskip}%        skip before the heading
      {\afterparaskip}%         skip after the heading
      {\normalfont\paraheadstyle}} % font
\newcommand{\parahook}{}
\newcommand{\setparahook}[1]{\renewcommand{\parahook}{#1}}
\newlength{\paraindent}
\newcommand{\setparaindent}[1]{\setlength{\paraindent}{#1}}
  \setparaindent{\z@}
\newskip\beforeparaskip
\newcommand{\setbeforeparaskip}[1]{\setlength{\beforeparaskip}{#1}}
  \setbeforeparaskip{3.25ex \@plus 1ex \@minus .2ex}
\newskip\afterparaskip
\newcommand{\setafterparaskip}[1]{\setlength{\afterparaskip}{#1}}
  \setafterparaskip{-1em}
\newcommand{\paraheadstyle}{}
\newcommand{\setparaheadstyle}[1]{\renewcommand{\paraheadstyle}{#1}}
  \setparaheadstyle{\normalsize\bfseries}

\newcommand{\subparagraph}{%
  \subparahook%
  \@startsection{subparagraph}{5}%  level 5
      {\subparaindent}%            heading indent
      {\beforesubparaskip}%        skip before the heading
      {\aftersubparaskip}%         skip after the heading
      {\normalfont\subparaheadstyle}} % font
\newcommand{\subparahook}{}
\newcommand{\setsubparahook}[1]{\renewcommand{\subparahook}{#1}}
\newlength{\subparaindent}
\newcommand{\setsubparaindent}[1]{%
            \setlength{\subparaindent}{#1}}
  \setsubparaindent{\parindent}
\newskip\beforesubparaskip
\newcommand{\setbeforesubparaskip}[1]{%
            \setlength{\beforesubparaskip}{#1}}
  \setbeforesubparaskip{3.25ex \@plus 1ex \@minus .2ex}
\newskip\aftersubparaskip
\newcommand{\setaftersubparaskip}[1]{%
            \setlength{\aftersubparaskip}{#1}}
  \setaftersubparaskip{-1em}
\newcommand{\subparaheadstyle}{}
\newcommand{\setsubparaheadstyle}[1]{%
            \renewcommand{\subparaheadstyle}{#1}}
  \setsubparaheadstyle{\normalsize\bfseries}

\newcommand{\sethangfrom}[1]{\renewcommand{\@hangfrom}[1]{#1}}
\newcommand{\setsecnumformat}[1]{\renewcommand{\@seccntformat}[1]{#1}}
\newcommand{\hangsecnum}{%
  \def\@seccntformat##1{\llap{\csname the##1\endcsname\quad}}}
\newcommand{\defaultsecnum}{%
  \def\@seccntformat##1{\csname the##1\endcsname\quad}}

\newcommand{\plainbreak}{\@ifstar{\@spbreak}{\@pbreak}}
\newcommand*{\@pbreak}[1]{\par
  \penalty -100
  \vskip #1\onelineskip \@plus 2\onelineskip
  \penalty -20
  \vskip \z@ \@plus -2\onelineskip
  \@afterindentfalse
  \@afterheading}
\newcommand*{\@spbreak}[1]{\par
  \penalty -100
  \vskip #1\onelineskip \@plus 2\onelineskip
  \penalty -20
  \vskip \z@ \@plus -2\onelineskip
  \@afterindenttrue
  \@afterheading}

\newcommand{\fancybreak}{\@ifstar{\@sfbreak}{\@fbreak}}
\newcommand{\@fbreak}[1]{\par
  \penalty -100
  \noindent\parbox{\linewidth}{\centering #1}%%\null
  \par
%%  \penalty -20
%%  \vskip -\onelineskip
  \@afterindentfalse
  \@afterheading}
\newcommand{\@sfbreak}[1]{\par
  \penalty -100
  \noindent\parbox{\linewidth}{\centering #1}%%\null
  \par
%%  \penalty -20
%%  \vskip -\onelineskip
  \@afterindenttrue
  \@afterheading}

\newcommand{\plainfancybreak}{\@ifstar{\@spfbreak}{\@pfbreak}}
\newcommand{\@pfbreak}[3]{\par
  \@tempdimc\pagegoal \advance\@tempdimc-\pagetotal
  \ifdim #1>\@tempdimc \@fbreak{#3}\else \@pbreak{#2}\fi}
\newcommand{\@spfbreak}[3]{\par
  \@tempdimc\pagegoal \advance\@tempdimc-\pagetotal
  \ifdim #1>\@tempdimc \@sfbreak{#3}\else \@spbreak{#2}\fi}

\newcommand*{\pen@ltyabovepfbreak}{2}
\newcommand*{\pen@ltybelowpfbreak}{-4}

\newlength{\pfbreakskip}
  \setlength{\pfbreakskip}{2\baselineskip}
\newcommand{\pfbreakdisplay}{*\quad*\quad*}

\def\pfbre@kdispl@y{\vbox to 1\pfbreakskip{\vss
  \hb@xt@ \columnwidth{\hss \pfbreakdisplay \hss}%
  \vss}}

\edef\nopfbreakOutput{\the\output}
\def\pfbreakOutput{%
  \ifnum\outputpenalty=\pen@ltyabovepfbreak
    \nopfbreakOutput
    \pfbre@kdispl@y
    \nobreak
    \vskip-\pfbreakskip
  \else\ifnum\outputpenalty=\pen@ltybelowpfbreak
    \unvbox 255\relax
    \nobreak
    \vskip-\pfbreakskip
    \pfbre@kdispl@y
    \break
  \else
    \nopfbreakOutput
  \fi
  \fi}
\output={\pfbreakOutput}

\newcommand{\pfbreak}{\@ifstar{\@spfbreakgap}{\@pfbreakgap}}
\newcommand{\@pfbreakgap}{%
  \par {%
  \skip@\lastskip
  \nobreak
  \vskip -\ifdim\prevdepth>\maxdepth \maxdepth
          \else\ifdim\prevdepth>-1000pt\prevdepth
            \else\ifinner 0pt
              \else \pagedepth
          \fi \fi \fi
  \vskip -\skip@
  \ifdim\skip@<\pfbreakskip
    \advance\skip@ -1\skip@ \advance\skip@ 1\pfbreakskip
  \fi
  \penalty\pen@ltyabovepfbreak
  \prevdepth\z@ % added
  \vskip\skip@
  \penalty\pen@ltybelowpfbreak
  }
  \@afterindentfalse
  \@afterheading
}
\newcommand{\@spfbreakgap}{%
  \par {%
  \skip@\lastskip
  \nobreak
  \vskip -\ifdim\prevdepth>\maxdepth \maxdepth
          \else\ifdim\prevdepth>-1000pt\prevdepth
            \else\ifinner 0pt
              \else \pagedepth
          \fi \fi \fi
  \vskip -\skip@
  \ifdim\skip@<\pfbreakskip
    \advance\skip@ -1\skip@ \advance\skip@ 1\pfbreakskip
  \fi
  \penalty\pen@ltyabovepfbreak
  \prevdepth\z@ % added
  \vskip\skip@
  \penalty\pen@ltybelowpfbreak
  }
  \@afterindenttrue
  \@afterheading
}

\newcommand*{\noprelistbreak}{\@nobreaktrue\nopagebreak}

\newcommand{\makeheadstyles}[2]{%
  \@namedef{hds@#1}{\@hds@def@ult #2}}
\newcommand*{\headstyles}[1]{\@nameuse{hds@#1}}
\newcommand*{\@hds@def@ult}{%
  \renewcommand*{\beforebookskip}{\null\vfil}%
  \renewcommand*{\midbookskip}{\par\vskip 20pt}%
  \renewcommand*{\afterbookskip}{\vfil\newpage}%
  \renewcommand*{\booknamefont}{\normalfont\huge\bfseries}%
  \renewcommand*{\booknumfont}{\normalfont\huge\bfseries}%
  \renewcommand*{\booktitlefont}{\normalfont\Huge\bfseries}%
  \renewcommand*{\printbookname}{\booknamefont \bookname}%
  \renewcommand*{\booknamenum}{\space}%
  \renewcommand*{\printbooknum}{\booknumfont \thebook}%
  \renewcommand*{\printbooktitle}[1]{\booktitlefont{##1}}%
  \renewcommand*{\beforepartskip}{\null\vfil}%
  \renewcommand*{\midpartskip}{\par\vskip 20pt}%
  \renewcommand*{\afterpartskip}{\vfil\newpage}%
  \renewcommand*{\partnamefont}{\normalfont\huge\bfseries}%
  \renewcommand*{\partnumfont}{\normalfont\huge\bfseries}%
  \renewcommand*{\parttitlefont}{\normalfont\Huge\bfseries}%
  \renewcommand*{\printpartname}{\partnamefont \partname}%
  \renewcommand*{\partnamenum}{\space}%
  \renewcommand*{\printpartnum}{\partnumfont \thepart}%
  \renewcommand*{\printparttitle}[1]{\parttitlefont{##1}}%
  \@chs@def@ult%               default chapterstyle
  \setsechook{}
  \setsecindent{\z@}%
  \setbeforesecskip{-3.5ex \@plus -1ex \@minus -.2ex}%
  \setaftersecskip{2.3ex \@plus .2ex}%
  \setsecheadstyle{\Large\bfseries\memRTLraggedright}%
  \setsubsechook{}%
  \setsubsecindent{\z@}%
  \setbeforesubsecskip{-3.25ex \@plus -1ex \@minus -.2ex}%
  \setaftersubsecskip{1.5ex \@plus .2ex}%
  \setsubsecheadstyle{\large\bfseries\memRTLraggedright}%
  \setsubsubsechook{}%
  \setsubsubsecindent{\z@}%
  \setbeforesubsubsecskip{-3.25ex \@plus -1ex \@minus -.2ex}%
  \setaftersubsubsecskip{1.5ex \@plus .2ex}%
  \setsubsubsecheadstyle{\normalsize\bfseries\memRTLraggedright}%
  \setparahook{}%
  \setparaindent{\z@}%
  \setbeforeparaskip{3.25ex \@plus 1ex \@minus .2ex}%
  \setafterparaskip{-1em}%
  \setparaheadstyle{\normalsize\bfseries}%
  \setsubparahook{}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{3.25ex \@plus 1ex \@minus .2ex}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalsize\bfseries}}

\makeheadstyles{default}{}
\headstyles{default}

\newcommand*{\addperiod}[1]{#1.}

\makeheadstyles{memman}{%
  \renewcommand*{\booknamefont}{\normalfont\huge\sffamily}
  \renewcommand*{\booknumfont}{\normalfont\huge\sffamily}
  \renewcommand*{\booktitlefont}{\normalfont\Huge\sffamily}
  \renewcommand*{\midbookskip}{\par\vskip 2\onelineskip}%
  \renewcommand*{\partnamefont}{\normalfont\huge\sffamily}
  \renewcommand*{\partnumfont}{\normalfont\huge\sffamily}
  \renewcommand*{\parttitlefont}{\normalfont\Huge\sffamily}
  \renewcommand*{\midpartskip}{\par\vskip 2\onelineskip}%
  \chapterstyle{demo3}
  \setbeforesecskip{-1.333\onelineskip
                    \@plus -0.5\onelineskip \@minus -.5\onelineskip}%
  \setaftersecskip{0.667\onelineskip \@plus 0.1\onelineskip}%
  \setsecheadstyle{\normalfont\scshape\memRTLraggedright}%
  \setbeforesubsecskip{-0.667\onelineskip
                       \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsecskip{0.333\onelineskip \@plus 0.1\onelineskip}%
  \setsubsecheadstyle{\normalfont\bfseries\memRTLraggedright}%
  \setbeforesubsubsecskip{-0.667\onelineskip
                          \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsubsecskip{0.333\onelineskip \@plus 0.1\onelineskip}%
  \setsubsubsecheadstyle{\normalfont\normalsize\itshape\memRTLraggedright}%
  \setbeforeparaskip{1.0\onelineskip
                     \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setafterparaskip{-1em}%
  \setparaheadstyle{\normalfont\normalsize\itshape\addperiod}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{1.0\onelineskip
                        \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalfont\normalsize\itshape\addperiod}}

\makeheadstyles{bringhurst}{%
\chapterstyle{bringhurst}
  \setbeforesecskip{-1\onelineskip
                    \@plus -0.5\onelineskip \@minus -.5\onelineskip}%
  \setaftersecskip{1\onelineskip \@plus 0.1\onelineskip}%
  \setsecheadstyle{\normalfont\memRTLraggedright\scshape\MakeTextLowercase}%
  \setbeforesubsecskip{-1.0\onelineskip
                       \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsecskip{1.0\onelineskip \@plus 0.1\onelineskip}%
  \setsubsecheadstyle{\sethangfrom{\noindent ####1}\normalfont\itshape\memRTLraggedright}%
  \setbeforesubsubsecskip{1.0\onelineskip
                          \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setaftersubsubsecskip{-1em}%
  \setsubsubsecheadstyle{\normalfont\normalsize\scshape\MakeTextLowercase}%
  \setbeforeparaskip{1.0\onelineskip
                     \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setafterparaskip{-1em}%
  \setparaheadstyle{\normalfont\normalsize\itshape\addperiod}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{1.0\onelineskip
                        \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalfont\normalsize\itshape\addperiod}}

\makeheadstyles{crosshead}{%
  \chapterstyle{crosshead}
  \setbeforesecskip{-1.25\onelineskip
                    \@plus -0.5\onelineskip \@minus -.5\onelineskip}%
  \setaftersecskip{0.75\onelineskip \@plus 0.1\onelineskip}%
  \setsecheadstyle{\normalfont\centering\MakeTextUppercase}%
  \setbeforesubsecskip{-1.25\onelineskip
                       \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsecskip{0.75\onelineskip \@plus 0.1\onelineskip}%
  \setsubsecheadstyle{\normalfont\centering\bfseries}%
  \setbeforesubsubsecskip{-.667\onelineskip
                          \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsubsecskip{.333\onelineskip \@plus 0.1\onelineskip}%
  \setsubsubsecheadstyle{\normalfont\normalsize\centering\scshape\MakeTextLowercase}%
  \setbeforeparaskip{-.667\onelineskip
                     \@plus -02.5\onelineskip \@minus -0.25\onelineskip}%
  \setafterparaskip{.333\onelineskip \@plus 0.1\onelineskip}%
  \setparaheadstyle{\normalfont\normalsize\centering\itshape}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{1.0\onelineskip
                        \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalfont\normalsize\scshape\MakeTextLowercase}}

\makeheadstyles{dowding}{%
  \chapterstyle{dowding}
  \setbeforesecskip{-2\onelineskip
                    \@plus -0.5\onelineskip \@minus -.5\onelineskip}%
  \setaftersecskip{1\onelineskip \@plus 0.1\onelineskip}%
  \setsecheadstyle{\normalfont\centering\MakeTextUppercase}%
  \setbeforesubsecskip{-1.2\onelineskip
                       \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsecskip{0.8\onelineskip \@plus 0.1\onelineskip}%
  \setsubsecheadstyle{\normalfont\scshape\centering\MakeTextLowercase}%
  \setbeforesubsubsecskip{-0.667\onelineskip
                          \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsubsecskip{0.333\onelineskip \@plus 0.1\onelineskip}%
  \setsubsubsecheadstyle{\normalfont\normalsize\centering\itshape}%
  \setbeforeparaskip{1.0\onelineskip
                     \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setafterparaskip{-1em}%
  \setparaheadstyle{\normalfont\normalsize\itshape\addperiod}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{1.0\onelineskip
                        \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalfont\normalsize\itshape\addperiod}}

\makeheadstyles{komalike}{%
  \renewcommand*{\partnamefont}{\huge\sffamily\bfseries}%
  \renewcommand*{\partnumfont}{\huge\sffamily\bfseries}%
  \renewcommand*{\parttitlefont}{\huge\sffamily\bfseries}%
  \chapterstyle{komalike}
  \setbeforesecskip{-3.5ex \@plus -1ex \@minus -.2ex}%
  \setaftersecskip{2.3ex \@plus .2ex}%
  \setsecheadstyle{\normalfont\Large\sffamily\bfseries\memRTLraggedright}%
  \setbeforesubsecskip{-3.25ex \@plus -1ex \@minus -.2ex}%
  \setaftersubsecskip{1.5ex \@plus .2ex}%
  \setsubsecheadstyle{\normalfont\large\sffamily\bfseries\memRTLraggedright}%
  \setbeforesubsubsecskip{-3.25ex \@plus -1ex \@minus -.2ex}%
  \setaftersubsubsecskip{1.5ex \@plus .2ex}%
  \setsubsubsecheadstyle{\normalfont\normalsize\sffamily\bfseries\memRTLraggedright}%
  \setbeforeparaskip{3.25ex \@plus 1ex \@minus .2ex}%
  \setafterparaskip{-1em}%
  \setparaheadstyle{\normalfont\normalsize\sffamily\bfseries}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{3.25ex \@plus 1ex \@minus .2ex}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalfont\normalsize\sffamily\bfseries}}

\makeheadstyles{ntglike}{%
  \renewcommand*{\partnamefont}{\Large\bfseries\MakeTextUppercase}%
  \renewcommand*{\partnumfont}{\Large\bfseries}%
  \renewcommand*{\parttitlefont}{\Large\MakeTextUppercase}%
  \chapterstyle{ntglike}
  \setbeforesecskip{-2\onelineskip
                    \@plus -1\onelineskip \@minus -.5\onelineskip}%
  \setaftersecskip{0.5\onelineskip}%
  \setsecheadstyle{\normalfont\large\bfseries}%
  \setbeforesubsecskip{-1\onelineskip
                       \@plus -.5\onelineskip \@minus -.25\onelineskip}%
  \setaftersubsecskip{0.01\onelineskip}%
  \setsubsecheadstyle{\normalfont\normalsize\bfseries}%
  \setbeforesubsubsecskip{-1\onelineskip
                          \@plus -.5\onelineskip \@minus -.25\onelineskip}%
  \setaftersubsubsecskip{0.01\onelineskip}%
  \setsubsubsecheadstyle{\normalfont\normalsize\slshape}%
  \setbeforeparaskip{3.25ex \@plus 1ex \@minus .2ex}%
  \setafterparaskip{-1em}%
  \setparaheadstyle{\normalfont\normalsize\slshape}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{3.25ex \@plus 1ex \@minus .2ex}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalfont\normalsize\slshape}}

\makeheadstyles{tandh}{%
  \chapterstyle{tandh}
  \setbeforesecskip{-2\onelineskip
                    \@plus -0.5\onelineskip \@minus -.5\onelineskip}%
  \setaftersecskip{1\onelineskip \@plus 0.1\onelineskip}%
  \setsecheadstyle{\normalfont\memRTLraggedright\MakeTextUppercase}%
  \setbeforesubsecskip{-1.2\onelineskip
                       \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsecskip{0.8\onelineskip \@plus 0.1\onelineskip}%
  \setsubsecheadstyle{\normalfont\Large\itshape\memRTLraggedright}%
  \setbeforesubsubsecskip{-0.667\onelineskip
                          \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsubsecskip{0.333\onelineskip \@plus 0.1\onelineskip}%
  \setsubsubsecheadstyle{\normalfont\normalsize\bfseries\memRTLraggedright}%
  \setbeforeparaskip{1.0\onelineskip
                     \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setafterparaskip{-1em}%
  \setparaheadstyle{\normalfont\normalsize\itshape\addperiod}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{1.0\onelineskip
                        \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalfont\normalsize\itshape\addperiod}}

\makeheadstyles{wilsondob}{%
  \chapterstyle{wilsondob}
  \setbeforesecskip{-1.333\onelineskip
                    \@plus -0.5\onelineskip \@minus -.5\onelineskip}%
  \setaftersecskip{0.667\onelineskip \@plus 0.1\onelineskip}%
  \setsecheadstyle{\normalfont\memRTLraggedright\MakeTextUppercase}%
  \setbeforesubsecskip{-0.667\onelineskip
                       \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsecskip{0.333\onelineskip \@plus 0.1\onelineskip}%
  \setsubsecheadstyle{\normalfont\Large\itshape\memRTLraggedright}%
  \setbeforesubsubsecskip{-0.667\onelineskip
                          \@plus -0.25\onelineskip \@minus -0.25\onelineskip}%
  \setaftersubsubsecskip{0.333\onelineskip \@plus 0.1\onelineskip}%
  \setsubsubsecheadstyle{\normalfont\normalsize\memRTLraggedright\scshape\MakeTextLowercase}%
  \setbeforeparaskip{1.0\onelineskip
                     \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setafterparaskip{-1em}%
  \setparaheadstyle{\normalfont\normalsize\itshape\addperiod}%
  \setsubparaindent{\parindent}%
  \setbeforesubparaskip{1.0\onelineskip
                        \@plus 0.5\onelineskip \@minus 0.2\onelineskip}%
  \setaftersubparaskip{-1em}%
  \setsubparaheadstyle{\normalfont\normalsize\itshape\addperiod}}

\newif\ifanappendix
  \anappendixfalse
\newcommand{\appendix}{\par
  \setcounter{chapter}{0}%
  \setcounter{section}{0}%
  \gdef\@chapapp{\appendixname}%
  \gdef\thechapter{\@Alph\c@chapter}%
  \anappendixtrue}

\newcommand{\appendixpage}{%
  \@ifstar{\@sapppage}{\@apppage}}
\newcommand{\memapppageinfo}[1]{}
\newcommand{\memapppagestarinfo}[1]{}

\def\@apppage{%
  \@setuppart
  \mempreaddapppagetotochook
  \addappheadtotoc
  \mempostaddapppagetotochook
  \partmark{\appendixpagename}%
  \memapppageinfo{\appendixpagename}%
  {\centering
   \interlinepenalty \@M
   \normalfont
   \printparttitle{\appendixpagename}\par}%
  \@endpart}
\newcommand\mempreaddapppagetotochook{}
\newcommand\mempostaddapppagetotochook{}

\def\@sapppage{%
  \@setuppart
  \partmark{\appendixpagename}%
  \memapppagestarinfo{\appendixpagename}%
  {\centering
   \interlinepenalty \@M
   \normalfont
   \printparttitle{\appendixpagename}\par}%
  \@endpart}

\def\addappheadtotoc{%
  \phantomsection\addcontentsline{toc}{chapter}{\appendixtocname}}
\newcounter{@ppsavesec}
\newcounter{@ppsaveapp}
\setcounter{@ppsaveapp}{0}
\newcommand{\@ppsavesec}{%
  \setcounter{@ppsavesec}{\value{chapter}}}
\newcommand{\@pprestoresec}{%
  \setcounter{chapter}{\value{@ppsavesec}}}
\newcommand{\@ppsaveapp}{%
  \setcounter{@ppsaveapp}{\value{chapter}}}
\newcommand{\restoreapp}{%
  \setcounter{chapter}{\value{@ppsaveapp}}}

\newcommand{\@resets@pp}{%
  \par
  \@ppsavesec
  \setcounter{section}{0}%
  \setcounter{chapter}{0}%
  \renewcommand\@chapapp{\appendixname}%
  \renewcommand\thechapter{\@Alph\c@chapter}%
  \restoreapp
  \def\theHchapter{\Alph{chapter}}
}

\newenvironment{appendices}%
  {\@resets@pp\anappendixtrue}%
  {\@ppsaveapp\@pprestoresec\anappendixfalse}

\newcommand{\setthesection}{\thechapter.\Alph{section}}

\newcommand{\@resets@ppsub}{
  \par
  \setcounter{section}{0}
  \renewcommand{\thesection}{\setthesection}
  \def\theHsection{\theHchapter.\Alph{section}}
}

\newif\ifnamesubappendix
  \namesubappendixfalse
\newcommand*{\namedsubappendices}{\namesubappendixtrue}
\newcommand*{\unnamedsubappendices}{\namesubappendixfalse}

\newenvironment{subappendices}{%
  \@resets@ppsub
  \def\addappheadtotoc{\phantomsection
    \addcontentsline{toc}{section}{\appendixtocname}}
  \ifnamesubappendix
    \def\sectionname{\appendixname}
    \def\@seccntformat##1{\@ifundefined{##1name}%
                         {}{\csname ##1name\endcsname\ }%
        \csname the##1\endcsname\quad}
  \fi
}{%
  \def\theHsection{\theHchapter.\the\value{section}}
}

\newcommand*{\leadpagetoclevel}{chapter}
\newcommand*{\newleadpage}[3][empty]{%
  \@namedef{#2}{\@ifstar{\dlfm@msapppage{#1}{#2}{#3}}%
                        {\dlfm@mapppage{#1}{#2}{#3}}}}
\newcommand*{\renewleadpage}[3][empty]{%
  \@namedef{#2}{\@ifstar{\dlfm@msapppage{#1}{#2}{#3}}%
                        {\dlfm@mapppage{#1}{#2}{#3}}}}

\newcommand{\memleadpageinfo}[3]{}
\newcommand{\memleadpagestarinfo}[3]{}

\newcommand*{\dlfm@msapppage}[3]{%
  \@setuppart
  \partmark{#3}%
  \memleadpagestarinfo{#1}{#2}{#3}%
  {\centering
  \interlinepenalty \@M
  \normalfont
  \printparttitle{#3}\par
  \thispagestyle{#1}}%
  \dlfm@m@endpart{#1}}
\newcommand*{\dlfm@mapppage}[3]{%
  \@setuppart
  \phantomsection
  \addcontentsline{toc}{\leadpagetoclevel}{#3}%
  \partmark{#3}%
  \memleadpageinfo{#1}{#2}{#3}%
  {\centering
  \interlinepenalty \@M
  \normalfont
  \printparttitle{#3}\par
  \thispagestyle{#1}}%
  \dlfm@m@endpart{#1}}

\newcommand*{\dlfm@m@endpart}[1]{%
  \if@twoside
    \if@openright
      \null
      \thispagestyle{#1}%
      \newpage
    \fi
  \fi
  \if@tempswa
    \twocolumn
  \fi}

\let\memorigdbs\\
\let\memorigpar\par
\let\atcentercr\@centercr

\newcommand*{\flushleftright}{%
  \let\\\memorigdbs
  \leftskip\z@skip
  \rightskip\leftskip
  \parfillskip\@flushglue
  \everypar{}}

\newcommand*{\linenottooshort}[1][4em]{%
  \@tempdima=\hsize
  \advance\@tempdima -#1
  \leftskip\z@skip
  \rightskip\leftskip
  \parfillskip=\@tempdima \@minus \@tempdima}

\newcommand*{\russianpar}{\ifhmode\unskip
  \strut\vadjust{}\nobreak
  \discretionary{}%
  {\hbox{\hskip2\parindent
         \vrule depth 273sp width 0sp height \ht\strutbox}}%
  {\hbox{\hskip\parindent}}%
  \hskip-2\parindent \@minus 2\parindent
  \hskip\hsize \@minus \hsize
  \kern\z@ \parfillskip\z@
  \memorigpar
  \ifdim\prevdepth=273sp
    \nobreak
    \vskip-2\baselineskip
    \hbox{\strut}%
  \fi\fi}

\newcommand*{\lastlineparrule}{%
  \hrule height 0.5ex depth \@tempdimb\relax}
\newcommand*{\lastlinerulefill}{%
  \let\\\@centercr
  \@tempdimb=-0.5ex \advance\@tempdimb 0.4pt
  \unskip\nobreak\space
  \leaders\lastlineparrule\hskip\@flushglue
  \vadjust{}{\parfillskip\z@\memorigpar}}

\newcommand*{\centerlastline}{%
  \memRTLleftskip\@flushglue
  \memRTLrightskip=\z@ plus -1fil
  \parfillskip=\z@ plus 2fil}

\newcommand*{\leftcenterright}{%;
  \let\\\break
  \parindent\z@
  \leftskip\@flushglue
  \rightskip\leftskip
  \parfillskip \z@ \@plus -1fil
  \everypar={\hskip \z@ \@plus -1fil}}

\newcommand*{\centerfloat}{%
  \parindent \z@
  \leftskip \z@ \@plus 1fil \@minus \textwidth
  \rightskip\leftskip
  \parfillskip \z@skip}

\newdimen\ragrparindent
  \setlength{\ragrparindent}{\parindent}
\newcommand{\raggedyright}[1][2em]{%
  \let\\\@centercr\@rightskip \z@ \@plus #1\relax
  \memRTLrightskip\@rightskip
  \memRTLleftskip\z@skip
  \parindent\ragrparindent}

\newcommand*{\justlastraggedleft}{%
  \memRTLleftskip\@flushglue
  \memRTLrightskip-\memRTLleftskip
  \parfillskip\leftskip
  \parindent \z@}

\newcommand*{\raggedrightthenleft}{%
  \parindent \z@
  \memRTLleftskip \z@ \@plus 1fill
  \memRTLrightskip\@flushglue
  \parfillskip \z@
  \everypar{\hskip \z@ \@plus -1fill}}

\newcommand{\hangfrom}[1]{%
  \setbox\@tempboxa\hbox{{#1}}%
  \hangindent \wd\@tempboxa\noindent\box\@tempboxa}

\newcommand{\hangpara}[2]{\hangindent#1\hangafter#2\noindent}
\newenvironment{hangparas}[2]{\setlength{\parindent}{\z@}
  \everypar={\hangpara{#1}{#2}}}{\par}

\newcommand{\leftspringright}[4]{%
  \@tempdimb=\hsize
  \par\noindent\hbox to\@tempdimb{%
    \vtop{\hsize=#1\@tempdimb \flushleft#3\par}\hss
    \vtop{\hsize=#2\@tempdimb \flushright#4\par}}}

\newcommand*{\sourceatright}[2][2em]{{%
  \unskip\nobreak\hfil\penalty50
  \hskip#1\hbox{}\nobreak\hfil{#2}
  \parfillskip\z@\finalhyphendemerits=0\par}}

\if@twocolumn
  \setlength{\leftmargini}{2em}
\else
  \setlength{\leftmargini}{2.5em}
\fi
\leftmargin \leftmargini
\setlength{\leftmarginii}{2.2em}
\setlength{\leftmarginiii}{1.87em}
\setlength{\leftmarginiv}{1.7em}
\if@twocolumn
  \setlength{\leftmarginv}{.5em}
  \setlength{\leftmarginvi}{.5em}
\else
  \setlength{\leftmarginv}{1em}
  \setlength{\leftmarginvi}{1em}
\fi
\setlength{\itemindent}{\z@}
\setlength{\labelsep}{0.5em}
\setlength{\labelwidth}{\leftmargini}
  \addtolength{\labelwidth}{-\labelsep}
\@beginparpenalty -\@lowpenalty
\@endparpenalty   -\@lowpenalty
\@itempenalty     -\@lowpenalty

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newdimen\everylistparindent
  \everylistparindent \z@
\renewcommand*{\list}[2]{%
  \ifnum \@listdepth >5\relax
    \@toodeep
  \else
    \global\advance\@listdepth\@ne
  \fi
  \rightmargin\z@
  \listparindent\everylistparindent
  \itemindent\z@
  \csname @list\romannumeral\the\@listdepth\endcsname
  \def\@itemlabel{#1}%
  \let\makelabel\@mklab
  \@nmbrlistfalse
  #2\relax
  \@trivlist
  \parskip\parsep
  \parindent\listparindent
  \advance\linewidth -\rightmargin
  \advance\linewidth -\leftmargin
  \advance\@totalleftmargin \leftmargin
  \parshape \@ne \@totalleftmargin \linewidth
  \ignorespaces}

\newlength{\parsepi}
\newlength{\topsepi}
\newlength{\itemsepi}
\newlength{\parsepii}
\newlength{\topsepii}
\newlength{\topsepiii}

\newlength{\itemsepii}
\newlength{\itemsepiii}
\newlength{\partopsepii}
\newlength{\partopsepiii}
\newcommand*{\setnzplist}{%
  \partopsep \p@ \@plus\z@ \@minus\p@
  \topsepi\z@
  \parsepi\parskip
  \itemsepi\z@
  \topsepii\z@
  \parsepii\parskip
  \itemsepii\z@
  \topsepiii\z@
%%    \parsepiii\parskip
  \itemsepiii\z@}

\newcommand*{\defaultlists}{%
  \setlength{\partopsep}{0.2\onelineskip \@plus 0.1\onelineskip
                                         \@minus 0.1\onelineskip}%
  \parsepi = 0.3333\onelineskip \@plus 0.1667\onelineskip \@minus \p@
  \itemsepi = \parsepi
  \topsepi = 0.6667\onelineskip \@plus 0.3333\onelineskip
                                \@minus 0.2\onelineskip
  \parsepii = 0.1667\onelineskip \@plus \p@ \@minus \p@
  \topsepii = \parsepi
  \topsepiii = \parsepii
  \everylistparindent \listparindent
  \itemsepii\parsepii
  \itemsepiii\topsepiii
  \partopsepiii \p@ \@plus\z@ \@minus\p@
  \ifm@mnzpskip
    \setnzplist
  \fi}
\defaultlists

\newcommand*{\firmlists}{%
  \@ifstar{\m@msfirmlists}{\m@mfirmlists}}

\newcommand*{\m@msfirmlists}{
  \setlength{\partopsep}{\z@ \@plus \p@ \@minus \p@}%
  \parsepi = 0.1667\onelineskip \@plus 0.0833\onelineskip \@minus \p@
  \itemsepi = \parsepi
  \topsepi = \parsepi
  \parsepii = 0.0833\onelineskip \@plus \p@ \@minus \p@
  \topsepii = \parsepi
  \topsepiii = \parsepii
  \everylistparindent\listparindent}

\newcommand*{\m@mfirmlists}{
  \setlength{\partopsep}{0.1\onelineskip \@plus 0.05\onelineskip
                                         \@minus 0.05\onelineskip}%
  \parsepi = 0.1667\onelineskip \@plus 0.0833\onelineskip \@minus \p@
  \itemsepi = \parsepi
  \topsepi = \parsepi
  \parsepii = 0.0833\onelineskip \@plus \p@ \@minus \p@
  \topsepii = \parsepi
  \topsepiii = \parsepii
  \everylistparindent\listparindent}

\newcommand*{\tightlists}{%
  \@ifstar{\m@mstightlists}{\m@mtightlists}}

\newcommand*{\m@mstightlists}{%
  \setlength{\partopsep}{\z@ \@plus \p@ \@minus \p@}%
  \parsepi = \z@ \@plus \p@ \@minus \p@
  \itemsepi = \parsepi
  \topsepi = \z@ \@plus \p@ \@minus \p@
  \parsepii = \z@ \@plus \p@ \@minus \p@
  \topsepii = \parsepi
  \topsepiii = \parsepii
  \everylistparindent\parindent
  \ifm@mnzpskip
    \setnzplist
    \partopsepiii\partopsep
  \fi}

\newcommand*{\m@mtightlists}{%
  \setlength{\partopsep}{0.5\onelineskip \@plus \p@ \@minus \p@}%
  \parsepi = \z@ \@plus \p@ \@minus \p@
  \itemsepi = \parsepi
  \topsepi = \z@ \@plus \p@ \@minus \p@
  \parsepii = \z@ \@plus \p@ \@minus \p@
  \topsepii = \parsepi
  \topsepiii = \parsepii
  \everylistparindent\parindent
  \ifm@mnzpskip
    \setnzplist
    \partopsepiii\partopsep
  \fi}

\newcommand{\firmlist}{%
  \setlength{\itemsep}{0.5\itemsep}\setlength{\parskip}{0.5\parskip}}
\newcommand{\tightlist}{%
  \setlength{\itemsep}{0pt}\setlength{\parskip}{0pt}}

\newskip\m@msavetopsep
\newskip\m@msavepartopsep
\newcommand*{\savetrivseps}{%
  \m@msavetopsep\topsep
  \m@msavepartopsep\partopsep}
\newcommand*{\restoretrivseps}{%
  \topsep\m@msavetopsep
  \partopsep\m@msavepartopsep}
\savetrivseps

\newcommand*{\zerotrivseps}{%
  \topsep\z@
  \partopsep\z@}

\def\@listi{\leftmargin\leftmargini
  \parsep\parsepi
  \topsep\topsepi
  \itemsep\itemsepi}
\let\@listI\@listi
\defaultlists
\@listi

\def\@listii{\leftmargin\leftmarginii
             \labelwidth\leftmarginii
             \advance\labelwidth-\labelsep
             \topsep\topsepii
             \parsep\parsepii
             \itemsep\itemsepii}

\def\@listiii{\leftmargin\leftmarginiii
              \labelwidth\leftmarginiii
              \advance\labelwidth-\labelsep
              \topsep\topsepiii
              \parsep\z@
%%%              \itemsep\topsep
%%%              \partopsep \p@ \@plus\z@ \@minus\p@
              \itemsep\itemsepiii
              \partopsep\partopsepiii}

\def\@listiv{\leftmargin\leftmarginiv
             \labelwidth\leftmarginiv
             \advance\labelwidth-\labelsep}

\def\@listv{\leftmargin\leftmarginv
            \labelwidth\leftmarginv
            \advance\labelwidth-\labelsep}

\def\@listvi{\leftmargin\leftmarginvi
             \labelwidth\leftmarginvi
             \advance\labelwidth-\labelsep}

\renewcommand{\theenumi}{\@arabic\c@enumi}
\renewcommand{\theenumii}{\@alph\c@enumii}
\renewcommand{\theenumiii}{\@roman\c@enumiii}
\renewcommand{\theenumiv}{\@Alph\c@enumiv}
\newcommand{\labelenumi}{\theenumi.}
\newcommand{\labelenumii}{\theenumii)}
\newcommand{\labelenumiii}{\theenumiii.}
\newcommand{\labelenumiv}{\theenumiv.}
\renewcommand{\p@enumii}{\theenumi}
\renewcommand{\p@enumiii}{\theenumi(\theenumii)}
\renewcommand{\p@enumiv}{\p@enumiii\theenumiii}
\newtoks\@enLab
\def\@enQmark{?}
\def\@enLabel#1#2{%
  \edef\@enThe{\noexpand#1{\@enumctr}}%
  \@enLab\expandafter{\the\@enLab\csname the\@enumctr\endcsname}%
  \@enloop}
\def\@enSpace{\afterassignment\@enSp@ce\let\@memtempa= }
\def\@enSp@ce{\@enLab\expandafter{\the\@enLab\space}\@enloop}
\def\@enGroup#1{\@enLab\expandafter{\the\@enLab{#1}}\@enloop}
\def\@enOther#1{\@enLab\expandafter{\the\@enLab#1}\@enloop}
\def\@enloop{\futurelet\@entemp\@enloop@}
\def\@enloop@{%
  \ifx A\@entemp         \def\@memtempa{\@enLabel\Alph  }\else
  \ifx a\@entemp         \def\@memtempa{\@enLabel\alph  }\else
  \ifx i\@entemp         \def\@memtempa{\@enLabel\roman }\else
  \ifx I\@entemp         \def\@memtempa{\@enLabel\Roman }\else
  \ifx 1\@entemp         \def\@memtempa{\@enLabel\arabic}\else
  \ifx \@sptoken\@entemp \let\@memtempa\@enSpace         \else
  \ifx \bgroup\@entemp   \let\@memtempa\@enGroup         \else
  \ifx \@enum@\@entemp   \let\@memtempa\@gobble          \else
                         \let\@memtempa\@enOther
                         \@enhook
             \fi\fi\fi\fi\fi\fi\fi\fi
  \@memtempa}
%% \providecommand\@enhook{}
  \newcommand\@enhook{}
\def\enumerate{%
  \ifnum \@enumdepth >3 \@toodeep\else
      \advance\@enumdepth \@ne
      \edef\@enumctr{enum\romannumeral\the\@enumdepth}\fi
  \@ifnextchar[{\@@enum@}{\@enum@}}
\def\@@enum@[#1]{%
  \@enLab{}\let\@enThe\@enQmark
  \@enloop#1\@enum@
  \ifx\@enThe\@enQmark\@warning{The counter will not be printed.%
   ^^J\space\@spaces\@spaces\@spaces The label is: \the\@enLab}\fi
  \expandafter\edef\csname label\@enumctr\endcsname{\the\@enLab}%
  \expandafter\let\csname the\@enumctr\endcsname\@enThe
  \csname c@\@enumctr\endcsname7
  \expandafter\settowidth
            \csname leftmargin\romannumeral\@enumdepth\endcsname
            {\the\@enLab\hspace{\labelsep}}%
  \@enum@}
\def\@enum@{\list{\csname label\@enumctr\endcsname}%
           {\usecounter{\@enumctr}\def\makelabel##1{\hss\llap{##1}}}}

\newcommand{\labelitemi}{\textbullet}
\newcommand{\labelitemii}{\normalfont\bfseries \textendash}
\newcommand{\labelitemiii}{\textasteriskcentered}
\newcommand{\labelitemiv}{\textperiodcentered}
\renewcommand{\itemize}[1][\@empty]{%
  \ifnum \@itemdepth >\thr@@\@toodeep\else
    \advance\@itemdepth\@ne
    \ifx \@empty #1\else % optional argument
      \@namedef{labelitem\romannumeral\the\@itemdepth}{#1}%
    \fi
    \edef\@itemitem{labelitem\romannumeral\the\@itemdepth}%
    \expandafter
    \list
      \csname\@itemitem\endcsname
       {\def\makelabel##1{\hss\llap{##1}}}%
  \fi}
\let\enditemize =\endlist

\newenvironment{description}%
               {\list{}{\labelwidth\z@ \itemindent-\leftmargin
                        \let\makelabel\descriptionlabel}}%
               {\endlist}
\newcommand*{\descriptionlabel}[1]{\hspace\labelsep
                                   \normalfont\bfseries #1}
\newenvironment{blockdescription}%
               {\list{}{\labelwidth\z@ \itemindent 0.5em \labelsep 0.5em
                        \let\makelabel\blockdescriptionlabel}}%
               {\endlist}
\newcommand*{\blockdescriptionlabel}[1]{%%% \hspace\labelsep
                                   \normalfont\bfseries #1}
\newenvironment{labelled}[1]%
  {\list{}{\labelwidth\z@ \itemindent-\leftmargin
           \def\m@malabel{\@nameuse{#1}} \let\makelabel\m@malabel}}%
  {\endlist}

\newenvironment{flexlabelled}[6]%
  {\list{}{\nametest{#2}{*}%
           \ifsamename\else \labelwidth #2  \fi
           \nametest{#3}{*}%
           \ifsamename\else \labelsep #3 \fi
           \nametest{#4}{*}%
           \ifsamename\else \itemindent #4 \fi
           \nametest{#5}{*}%
           \ifsamename\else \leftmargin #5 \fi
           \nametest{#6}{*}%
           \ifsamename\else  \rightmargin #6 \fi
           \def\m@malabel{\@nameuse{#1}} \let\makelabel\m@malabel}}%
  {\endlist}

\newenvironment{quotation}%
               {\list{}{\listparindent 1.5em%
                        \itemindent    \listparindent
                        \rightmargin   \leftmargin
                        \parsep        \z@ \@plus\p@}%
                \item[]}%
               {\endlist}
\newenvironment{quote}%
               {\list{}{\rightmargin\leftmargin}%
                \item[]}%
               {\endlist}
\newcommand{\symbollabel}[1]{{#1 \hfill}}
\newenvironment{symbols}{\list{}%
    {\itemindent 0em \leftmargin 8em
     \labelsep 1em \labelwidth 5em
     \let\makelabel\symbollabel}}%
    {\endlist}
\newcommand{\symboldef}[2]{\item[#1] #2}
\newif\if@bsonecol
  \@bsonecoltrue
\newif\ifadd@bstotoc
  \add@bstotocfalse
\newif\ifnumber@bs
  \number@bsfalse
\newif\if@bsrunin
  \@bsruninfalse

\newcommand{\abstractcol}{\@bsonecolfalse}
\newcommand{\abstractintoc}{\add@bstotoctrue}
\newcommand{\abstractnum}{\number@bstrue\@bsruninfalse}
\newcommand{\abstractrunin}{\@bsrunintrue\number@bsfalse}

\newcommand{\abstractnamefont}{\normalfont\small\bfseries}
\newcommand{\abstracttextfont}{\normalfont\small}
\newcommand{\abscolnamefont}{\normalfont\Large\bfseries}
\newcommand{\abscoltextfont}{\normalfont}

\newcommand{\absnamepos}{center}
\newlength{\abstitleskip} \setlength{\abstitleskip}{-0.5em}
\newlength{\absleftindent}
  \absleftindent=\leftmargin
\newdimen\abs@leftindent
  \abs@leftindent=\leftmargin
\newlength{\absrightindent}
  \absrightindent=\leftmargin
\newlength{\absparindent}
\newlength{\absparsep}

\newcommand{\abslabeldelim}[1]{\def\@bslabeldelim{#1}}
\abslabeldelim{}
\newcommand{\@bsrunintitle}{%
  \hspace*{\abstitleskip}{\abstractnamefont\abstractname\@bslabeldelim}}

\newcommand{\setup@bstract}{%
  \abs@leftindent=\absleftindent
  \if@twocolumn
    \if@bsonecol
    \else
      \abs@leftindent=\z@
      \absrightindent=\z@
      \renewcommand*{\abstractnamefont}{\abscolnamefont}
      \renewcommand*{\abstracttextfont}{\abscoltextfont}
      \renewcommand*{\absnamepos}{flushleft}
      \setlength{\abstitleskip}{-2ex}
    \fi
  \fi}

\AtBeginDocument{\setlength{\absparindent}{\parindent}
                 \setlength{\absparsep}{\parskip}}

\newenvironment{@bstr@ctlist}{%
  \list{}{%
          %%\topsep        \z@
          \partopsep     \z@
          \listparindent \absparindent
          \itemindent    \listparindent
          \leftmargin    \abs@leftindent
          \rightmargin   \absrightindent
          \parsep        \absparsep}%
  \item\relax}
  {\endlist}

\newcommand{\put@bsintoc}{%
  \ifadd@bstotoc
    \ifnumber@bs\else
      \phantomsection
      \addcontentsline{toc}{chapter}{\abstractname}
    \fi
  \fi}

\newcommand{\num@bs}{\chapter{\abstractname}}

\newenvironment{abstract}{%
  \setup@bstract
  \if@bsrunin\else
    \ifnumber@bs \num@bs \else
      \begin{\absnamepos}\abstractnamefont\abstractname\end\absnamepos%
      \vspace{\abstitleskip}%
    \fi
  \fi
  \put@bsintoc%
  \begin{@bstr@ctlist}\if@bsrunin\@bsrunintitle\fi\abstracttextfont}%
  {\par\end{@bstr@ctlist}}

\newenvironment{onecolabstract}{%
  \begin{@twocolumnfalse}\begin{abstract}}{%
  \end{abstract}\end{@twocolumnfalse}}

\addtoiargdef{\thanks}{}{%
  \protected@xdef\@bs@thanks{\@bs@thanks
    \protect\footnotetext[\the\c@footnote]{#1}}%
}
\let\@bs@thanks\@empty

\newcommand{\saythanks}{\begingroup
  \renewcommand{\thefootnote}{\fnsymbol{footnote}}\@bs@thanks
  \endgroup\global\let\@bs@thanks\@empty}

\newcounter{vslineno}
\newcounter{poemline}
\newcounter{modulo@vs}
\newcounter{memfvsline}

%%%\newcommand{\poemlines}[1]{\linenumberfrequency{#1}%
%%%  \@memwarn{Use \string\linenumberfrequency\space
%%%                        instead of \string\poemlines}}

\newcommand{\linenumberfont}[1]{\def\vlvnumfont{#1}}
%%% \linenumberfont{\small\rmfamily}

\newif\ifbvcountlines%  TRUE to print line numbers of (boxed) verbatim lines
  \bvcountlinesfalse

\newcommand{\linenumberfrequency}[1]{%
  \ifnum #1< \@ne
    \def\linemodnum{0\relax}
    \bvcountlinesfalse
  \else
    \def\linemodnum{#1\relax}
    \bvcountlinestrue
  \fi}

%%%%\linenumberfrequency{0}

\newcommand*{\setverselinenums}[2]{%
  \c@poemline #1\relax \advance\c@poemline \m@ne
  \refstepcounter{poemline}%
  \ifnum\z@<\linemodnum%   we are printing line numbers
    \@tempcnta #2\relax
    \divide\@tempcnta\linemodnum
    \multiply\@tempcnta\linemodnum
    \c@memfvsline #2\relax
    \advance\c@memfvsline-\@tempcnta
  \fi}

\newcommand{\getthelinenumber}[2]{%
  \ifnum\@ne>\linemodnum%  no line numbers
  \else
    \ifnum\@ne=\linemodnum% every line numbered
      \@nameuse{the#1}%
    \else
      \@tempcnta=\@nameuse{c@#1}%
      \advance\@tempcnta -\@nameuse{c@#2}%
      \divide\@tempcnta \linemodnum
      \multiply\@tempcnta \linemodnum
      \advance\@tempcnta \@nameuse{c@#2}%
      \ifnum\@tempcnta=\@nameuse{c@#1}\@nameuse{the#1}\fi
    \fi
  \fi}

\newif\ifaltindent
  \altindentfalse
\newif\ifpattern
  \patternfalse
\newif\ifstarpattern
  \starpatternfalse

\newlength{\vleftskip}
  \setlength{\vleftskip}{3em}
\newlength{\vrightskip}
  \setlength{\vrightskip}{1em}

\newlength{\stanzaskip}
  \setlength{\stanzaskip}{\onelineskip}

\newcommand{\flagverse}[1]{%
%%%  \hskip-\vleftskip\llap{#1}\hskip\vleftskip\ignorespaces}
  \hskip-\memRTLvleftskip\llap{#1}\hskip\memRTLvleftskip\ignorespaces}

\newlength{\versewidth}
\newlength{\vgap} \setlength{\vgap}{1.5em}
\newcommand{\vin}{\hspace*{\vgap}}
\newlength{\vindent} \setlength{\vindent}{2\vgap}
\newcommand{\vinphantom}[1]{\leavevmode\phantom{#1}}
\newcommand*{\vleftofline}[1]{\leavevmode\llap{#1}}
\newdimen\vleftmargin
  \vleftmargin=\leftmargini

\newcommand{\verselinebreak}[1][\z@]{\newline\hspace*{#1}\ignorespaces}

\newcommand{\incr@vsline}{%
  \refstepcounter{poemline}%
  \stepcounter{vslineno}}

\newcommand{\@vsifbang}[1]{\@ifnextchar !{\@firstoftwo{#1}}}
\newcommand{\@vsifgt}[1]{\@ifnextchar >{\@firstoftwo{#1}}}

\newcommand*{\verselinenumbersright}{\def\@vstypelinenum{\@vslnumright}}
\newcommand*{\verselinenumbersleft}{\def\@vstypelinenum{\@vslnumleft}}
\verselinenumbersright

\newcommand*{\@vslnumright}{%
  \nobreak%
  \hfill\rlap{%\kern\vrightskip\kern\rightmargin%
              \kern\memRTLvrightskip\kern\rightmargin%
              \vlvnumfont\getthelinenumber{poemline}{memfvsline}}}
\newcommand*{\@vslnumleft}{%
  \nobreak%
  \hfill\rlap{%\kern-\textwidth\kern-\vrightskip%
              \kern-\textwidth\kern-\memRTLvrightskip%
              \vlvnumfont\getthelinenumber{poemline}{memfvsline}}}
\newcommand{\@vscentercr}{%
  \ifhmode \unskip\else \@nolnerr\fi
  \@vstypelinenum%
  \@vsifgt{\verselinebreak}{%
    \incr@vsline
    \par\@ifstar{\nobreak\@vsxcentercr}{%
      \@vsifbang{\@ifnextchar[ {\@vsicentercr}{}}{\@vsxcentercr}}}}
\newcommand{\@vsxcentercr}{\addvspace{-\parskip}%
  \@ifnextchar[ {\@vsicentercr}{\start@vsline}}
\def\@vsicentercr[#1]{\vskip #1\ignorespaces \start@vsline}
\newcommand{\start@vsline}{%
  \ifaltindent\ifodd\c@vslineno\else\vin\fi\fi%
  \ifpattern\get@vsindent\fi%
  \ifstarpattern\getstar@vsindent\fi}

\newcounter{verse}
\setcounter{verse}{0}
\def\theHpoemline{\theverse.\thepoemline}

\newenvironment{verse}[1][\linewidth]{%
  \refstepcounter{verse}%
  \setcounter{poemline}{0}\refstepcounter{poemline}%
  \setcounter{vslineno}{1}%
  \let\\=\@vscentercr
  \list{}{\itemsep     \z@
          \itemindent  -\vindent
          \listparindent\itemindent
          \leftmargin   \vleftmargin
          \parsep       \stanzaskip
          \ifdim #1<\linewidth%   %% short line
            \rightmargin        \z@
            \leftmargin         \linewidth
            \advance\leftmargin -#1\relax
            \advance\leftmargin -0.5\leftmargin
            \advance\leftmargin \vindent
          \else
            \ifdim #1>\linewidth%  %% long line
              \rightmargin \z@
              \leftmargin  \vindent
            \else%                   %% default
              \rightmargin \leftmargin
              \advance\leftmargin \vindent
            \fi
          \fi}
  \item[]}{\endlist}

\newenvironment{altverse}%
  {\starpatternfalse\patternfalse\altindenttrue
   \setcounter{vslineno}{1}}%
  {\altindentfalse}

\newif\ifbounderror
  \bounderrorfalse
\newif\ifinteger

\newcounter{chrsinstr}  % CHARactersINSTRing

\newcommand{\newarray}[3]{%
  \@nameedef{#1-low}{#2}%
  \@nameedef{#1-high}{#3}%
  \ifnum #3<#2
    \@memerror{Limits for array #1 are in reverse order}{\@ehc}%
  \fi}

\newcommand{\stringtoarray}[2]{%
  \def\@vsarrayname{#1}%
  \protected@edef\the@vsstring{#2}%
  \newarray{\@vsarrayname}{1}{1}%
  \@ifmtarg{#2}{%
    \c@chrsinstr \z@
    \@namedef{\@vsarrayname-1}{}
  }{%
    \c@chrsinstr \@ne
    \expandafter\@vsstringtoarray \the@vsstring\@vsend
  }}

\def\@vsstringtoarray #1#2\@vsend{%
  \@namedef{\@vsarrayname-\the\c@chrsinstr}{#1}
  \@nameedef{\@vsarrayname-high}{\the\c@chrsinstr}
  \@ifmtarg{#2}{%
    \def\@vsinext{}%
  }{%
    \advance\c@chrsinstr \@ne
    \def\@vsinext{%
      \@vsstringtoarray #2\@vsend%
    }%
  }
  \@vsinext}

\newcommand{\setarrayelement}[3]{%
  \checkarrayindex{#1}{#2}%
  \@nameedef{#1-#2}{#3}}
\newcommand{\getarrayelement}[3]{%
  \checkarrayindex{#1}{#2}%
  \protected@edef#3{\@nameuse{#1-#2}}}

\newcommand{\checkarrayindex}[2]{%
  \bounderrorfalse
  \expandafter\ifx\csname #1-low\endcsname\relax%
    \ifpattern\else
      \@memerror{No array called #1}{\@ehc}%
    \fi
    \bounderrortrue
  \fi
  \ifnum #2<\@nameuse{#1-low}\relax%
    \ifpattern\else
      \@memerror{Index #2 outside limits for array #1}{\@ehc}%
    \fi
    \bounderrortrue
  \fi
  \ifnum #2>\@nameuse{#1-high}\relax%
    \ifpattern\else
      \@memerror{Index #2 outside limits for array #1}{\@ehc}%
    \fi
    \bounderrortrue
  \fi}

\newcommand{\arraytostring}[2]{%
  \def#2{}%
  \c@chrsinstr = \@nameuse{#1-low}%
  \@vsarraytostring{#1}{#2}}

\newcommand{\@vsarraytostring}[2]{%
  \ifnum\c@chrsinstr>\@nameuse{#1-high}\else
    \protected@edef#2{#2\@nameuse{#1-\thechrsinstr}}%
    \advance\c@chrsinstr\@ne%
    \@vsarraytostring{#1}{#2}%
  \fi}

\newcommand{\checkifinteger}[1]{%
  \protected@edef\@vsa{#1}%
  \ifcat _\ifnum9<1\gobm{#1} _\else A\fi
    \integertrue%
  \else
    \integerfalse%
  \fi}
\newcommand{\gobm}[1]{#1}

\newcommand{\indentpattern}[1]{%
  \stringtoarray{Array@vs}{#1}}
\newcommand{\get@vsindent}{%
  \getarrayelement{Array@vs}{\number\value{vslineno}}{\@vspat}%
  \ifbounderror
    \arraytostring{Array@vs}{\@vsp@t}%
    \@memwarn{%
      Index `\thevslineno' for pattern `\@vsp@t' is out of bounds}%
    \def\@vspat{0}%
  \else
    \checkifinteger{\@vspat}%
    \ifinteger\else
      \arraytostring{Array@vs}{\@vsp@t}%
      \@memwarn{%
       `\@vspat' at index `\thevslineno' in pattern `\@vsp@t'
       is not a digit}%
      \def\@vspat{0}%
    \fi
  \fi
  \ifcase\@vspat\else\hspace*{\@vspat\vgap}\fi}
\newcommand{\getstar@vsindent}{%
  \expandafter\ifx\csname Array@vs-high\endcsname\relax
    \@memerror{A pattern has not been specified}{\@ehc}
  \else
    \ifnum\c@vslineno>\@nameuse{Array@vs-high}%
      \setcounter{vslineno}{1}%
     \fi
     \get@vsindent
  \fi}

\newenvironment{patverse}%
  {\starpatternfalse\patterntrue\altindentfalse
   \setcounter{vslineno}{1}}%
  {\patternfalse}

\newenvironment{patverse*}%
  {\starpatterntrue\patternfalse\altindentfalse
   \setcounter{vslineno}{1}}%
  {\starpatternfalse}

\newcommand{\poemtitle}{\par%
  \secdef\@vsptitle\@vssptitle}
\newcommand{\poemtoc}{section}

\newcommand{\mempoeminfo}[1]{}
\newcommand{\mempoemstarinfo}[1]{}

\long\def\@vsptitle[#1]#2{%
  \phantomsection
  \addcontentsline{toc}{\poemtoc}{#1}%
  \M@gettitle{#1}%
  \mempoeminfo{#1}%
  \poemtitlemark{#1}%
  \@vstypeptitle{#2}%
  \@afterheading}

\long\def\@vssptitle#1{%
  \M@gettitle{#1}%
  \mempoemstarinfo{#1}%
  \@vstypeptitle{#1}%
  \@afterheading}

\newcommand{\@vstypeptitle}[1]{%
  \vspace{\beforepoemtitleskip}%
  {\poemtitlefont #1\par}%
  \vspace{\afterpoemtitleskip}%
}

\newcommand{\poemtitlefont}{\normalfont\large\bfseries\centering}
\newcommand{\poemtitlemark}[1]{}

\newlength{\beforepoemtitleskip}
  \setlength{\beforepoemtitleskip}{3.5ex \@plus 1ex \@minus .2ex}
\newlength{\afterpoemtitleskip}
  \setlength{\afterpoemtitleskip}{2.3ex \@plus.2ex}

\newif\if@numptitle
\newcommand*{\NumberPoemTitle}{\@numptitletrue}
\newcommand*{\PlainPoemTitle}{\@numptitlefalse}
\NumberPoemTitle

\newcounter{poem}\setcounter{poem}{0}
\renewcommand*{\thepoem}{\@arabic\c@poem}
\providecommand*{\theHpoem}{\the\value{poem}}

\newcommand*{\poemtitlestarmark}[1]{}
\newcommand*{\poemtitlepstyle}{}
\newcommand*{\poemtitlestarpstyle}{}

\newcommand\PoemTitle{%
  \par
  \@afterindentfalse
  \@ifstar{\@m@msPoemTitle}{\@m@mPoemTitle}}

\newcommand{\@m@mPoemTitle}[1][]{%
  \def\poemt@c{#1}% capture first optional arg
  \@ifnextchar[{\@PoemTitle}{\@PoemTitle[]}%
}

\newcommand{\memPoemTitleinfo}[4]{}
\newcommand{\memPoemTitlestarinfo}[2]{}

\def\@PoemTitle[#1]#2{%
  \phantomsection
  \ifx\poemt@c\@empty % no optional args
    \def\poemf@rtoc{#2}%
    \def\poemf@rhdr{#2}%
  \else                  % at least one opt arg
    \let\poemf@rtoc\poemt@c
    \ifx\@empty#1\@empty
      \let\poemf@rhdr\poemt@c
    \else
      \def\poemf@rhdr{#1}%
    \fi
  \fi
  \m@m@Andfalse
  \if@numptitle
    \if@mainmatter
      \m@m@Andtrue
    \fi
  \fi
  \ifm@m@And
    \refstepcounter{poem}%
  \fi
  \@makePoemTitlehead{#2}%
  \@afterheading
  \poemtitlemark{\poemf@rhdr}%
  \poemtitlepstyle
  \ifm@m@And
    \addcontentsline{toc}{\poemtoc}{%
      \protect\numberline{\thepoem}\poemf@rtoc}%
    \memPoemTitleinfo{\thepoem}{\poemf@rtoc}{\poemf@rhdr}{#2}%
  \else
    \addcontentsline{toc}{\poemtoc}{\poemf@rtoc}%
    \memPoemTitleinfo{}{\poemf@rtoc}{\poemf@rhdr}{#2}%
  \fi
  \ifheadnameref\ExpandArgs{V}\M@gettitle\poemf@rhdr\else\ExpandArgs{V}\M@gettitle\poemf@rtoc\fi}

\def\@makePoemTitlehead#1{{%
  \PoemTitleheadstart
  \parindent \z@ \normalfont
   \ifm@m@And
     \printPoemTitlenum
     \afterPoemTitlenum
   \else
     \printPoemTitlenonum
   \fi
   \interlinepenalty\@M
   \printPoemTitletitle{#1}%
   \afterPoemTitle}}

\newcommand{\@PTchs@def@ult}{%
  \def\PoemTitleheadstart{\vspace{\beforePoemTitleskip}}
  \def\printPoemTitlenum{\PoemTitlenumfont \thepoem}
  \def\afterPoemTitlenum{\par\nobreak\vskip \midPoemTitleskip}
  \def\printPoemTitlenonum{}
  \def\printPoemTitletitle##1{\PoemTitlefont ##1}
  \def\afterPoemTitle{\par\nobreak\vskip \afterPoemTitleskip}}
\@PTchs@def@ult

\newcommand*{\PoemTitlenumfont}{\normalfont\large\centering}
\newcommand*{\PoemTitlefont}{\normalfont\large\centering}
\newlength{\beforePoemTitleskip}
  \setlength{\beforePoemTitleskip}{1\onelineskip}
\newlength{\midPoemTitleskip}
  \setlength{\midPoemTitleskip}{0pt}
\newlength{\afterPoemTitleskip}
  \setlength{\afterPoemTitleskip}{1\onelineskip}

\newcommand{\@m@msPoemTitle}[2][\@empty]{%
  \@sPoemTitle{#2}%
  \ifx \@empty#1
    \def\poemf@rhdr{#2}%
  \else   % opt arg
    \def\poemf@rhdr{#1}%
  \fi
  \poemtitlestarmark{\poemf@rhdr}%
  \poemtitlestarpstyle
  \memPoemTitlestarinfo{\poemf@rhdr}{#2}}

\newcommand{\@sPoemTitle}[1]{%
  \@makesPoemTitlehead{#1}%
  \@afterheading
  \M@gettitle{#1}}

\def\@makesPoemTitlehead#1{{%
  \PoemTitleheadstart
  \parindent \z@ \normalfont
  \printPoemTitlenonum
  \interlinepenalty\@M
  \printPoemTitletitle{#1}
  \afterPoemTitle}}

\setlength\arraycolsep{5\p@}
\setlength\tabcolsep{6\p@}
\setlength\arrayrulewidth{.4\p@}
\setlength\doublerulesep{2\p@}
\setlength\tabbingsep{\labelsep}

\newcommand{\@minipagerestore}{%
  \let\@verbfootnotetext\@verbmpfootnotetext
  \m@mdoextrafeetmini
  \ifm@mnzpskip \parskip=\m@mabparskip\fi}

\skip\@mpfootins = \skip\footins

\setlength\fboxsep{3\p@}
\setlength\fboxrule{.4\p@}

\@addtoreset{equation}{chapter}
\renewcommand{\theequation}{%
  \ifnum \c@chapter>\z@ \thechapter.\fi \@arabic\c@equation}

\RequirePackage{array}[2018/04/30]
\newif \@iffirstamp
\let\m@mold@addamp\@addamp
\newcommand*{\m@m@addamp}{%
  \if@firstamp
    \@firstampfalse
    \global\@curtab\@ne
  \else
    \@addtopreamble{&}%
    \global\advance\@curtab\@ne
  \fi}
\let\@addamp\m@m@addamp


\RequirePackage{dcolumn}[2014/10/28]
\RequirePackage{delarray}[2014/10/28]
\RequirePackage{tabularx}[2016/02/03]
\newcommand*{\bktabrule}[1]{%
  \hrule \@height#1}

\RequirePackage{booktabs}[2020/01/12]
\newskip\ctableftskip \ctableftskip=\fill
\newskip\ctabrightskip \ctabrightskip=\fill

\expandafter\def\csname ctabular*\endcsname{%
  \@ifnextchar[ {\@ctabularstar}{\@ctabularstar[c]}}
\def\@ctabularstar[#1]#2{\global\@curtab\@ne
  \ctableftskip\fill
  \ctabrightskip\fill
  \if l#1% left
    \ctableftskip\z@
  \else
    \if r#1% right
       \ctabrightskip\z@
    \fi
  \fi
  \setlength\dimen@{#2}%
  \xdef\@halignto{to\the\dimen@}\NC@tabular}
\newcommand*{\ctabular}[1][c]{\global\@curtab\@ne
  \ctableftskip\fill
  \ctabrightskip\fill
  \if l#1% left
    \ctableftskip\z@
  \else
    \if r#1% right
      \ctabrightskip\z@
    \fi
  \fi
  \gdef\@halignto{to\hsize}\NC@tabular}

\newcommand*{\NC@tabular}{%
  \par
  \addvspace{\topsep}
  \col@sep\tabcolsep
  \let\d@llarbegin\begingroup
  \let\d@llarend\endgroup
  \@NCtabarray}

\newcommand*{\@NCialign}{\everycr{}\tabskip\ctableftskip\halign}

\newcommand*{\@NCtabarray}[1]{%
  \@tempdima \ht\strutbox
  \advance\@tempdima\extrarowheight
  \setbox \@arstrutbox \hbox{\vrule
    \@height \arraystretch \@tempdima
    \@depth \arraystretch \dp\strutbox
    \@width\z@}%
  \begingroup
%%    \@mkpream{@{\hspace{\@totalleftmargin}}#1@{}}%
    \@mkpream{#1}%
    \xdef\@preamble{\@NCialign \@halignto
                    \bgroup & \tabskip\z@
                      \@arstrut
                      \@preamble
                      \tabskip\ctabrightskip
                      \cr}%
  \endgroup
  \let\@sharp ##\let\protect\relax
  \lineskip\z@
  \baselineskip\z@
  \let\\\@arraycr
  \let\tabularnewline\\%
  \let\par\@empty
  \ctabsetlines
  \@preamble
}

\def\endctabular{%
  \crcr \egroup
  \gdef\@preamble{}%
  \addvspace{\topsep}
  \noindent}
\expandafter\let\csname endctabular*\endcsname=\endctabular

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newcommand*{\memcline}[2]{\m@m@cline[#1]#2\@nil}
\def\m@m@cline[#1]#2-#3\@nil{%
  \omit
  \@multicnt#2%
  \advance\@multispan\m@ne
  \ifnum\@multicnt=\@ne\@firstofone{&\omit}\fi
  \@multicnt#3%
  \advance\@multicnt-#2%
  \advance\@multispan\@ne
  \leaders\hrule\@height #1\hfill  % <- variable \@height value
  \cr
  \noalign{\vskip- #1}}            % <- variable \@height value

\newcommand*{\memhline}[1][\arrayrulewidth]{\memcline{#1}{1-\@curtab}}
\newcommand*{\m@mhline}{\cline{1-\@curtab}}
\def\m@m@BTnormal{%
  \ifnum0=`{\fi}   % closes the \noalign
  \multispan{\@curtab} \leaders\bktabrule{\@thisrulewidth}\hfill\cr
  \noalign{\ifnum0=`}\fi
  \futurenonspacelet\@tempa\@BTendrule}

\def\ctabsetlines{%
  \let\hline\m@mhline
  \let\@BTnormal\m@m@BTnormal}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newcount\abovecolumnspenalty
  \abovecolumnspenalty=10000
\newcount\@linestogo           % lines remaining to be procesed
\newcount\@cellstogo           % cells remaining in column or row
\newcount\@cellsincolumn         % number of lines per column
\newtoks\crtok
  \crtok = {\cr}%

\newdimen\@mincolumnwidth
\let\c@lleftskip\hfil   % left skip within a column
\let\c@lrightskip\hfil % right skip within a column

\let\preautotab\relax
\let\postautotab\relax

\newcommand{\autocols}[5][0pt]{\par\begingroup
  \ctabsetlines
  \if l#2
    \raggedright
  \else
    \if r#2
      \raggedleft
    \else
      \centering
    \fi
  \fi
  \let\c@lleftskip\hfil
  \let\c@lrightskip\hfil
  \if l#4
    \let\c@lleftskip\relax
  \else
    \if r#4
      \let\c@lrightskip\relax
    \fi
  \fi
  \@mincolumnwidth\z@
  \TX@cols=#3
  \@curtab=#3
  \@linestogo\z@
  \@for\@tempa:=#5\do{
    \advance\@linestogo\@ne
    \settowidth{\@tempdima}{\@tempa}
    \ifdim\@tempdima>\@mincolumnwidth
      \@mincolumnwidth=\@tempdima
    \fi
  }
  \advance\@mincolumnwidth\tabcolsep
  \linespercol
  \def\@endcolumnactions{%
    \global\advance\@linestogo\m@ne
    \ifnum\@cellstogo<\tw@
      \global\advance\TX@cols\m@ne
      \ifnum\TX@cols>\z@\linespercol\fi
      \the\crtok
    \else
        &\global\advance\@cellstogo\m@ne
    \fi}%
  \ifdim #1 > \z@
    \TX@col@width=#1
    \divide\TX@col@width \TX@cols
  \else
    \TX@col@width=\@mincolumnwidth
  \fi
  \penalty\abovecolumnspenalty
  \noindent% usually not a paragraph
  \def\@preamble{}%
  \begingroup
    \let\@sharp\relax
    \ifnum\@cellsincolumn>\@ne
      \loop
        \g@addto@macro{\@preamble}{%
          \hb@xt@ \TX@col@width{%
               \c@lleftskip\strut\@sharp\c@lrightskip} &}%
        \advance\@cellsincolumn\m@ne
      \ifnum\@cellsincolumn>\@ne
      \repeat
    \fi
    \g@addto@macro{\@preamble}{%
      \hb@xt@ \TX@col@width{\c@lleftskip\strut\@sharp\c@lrightskip}}%
  \endgroup
  \let\@sharp ##
  \tabskip\ctableftskip
%%  \tabskip\z@
  \valign \bgroup
    \tabskip\z@
    \@preamble
    \tabskip\ctabrightskip\cr
    \@for\@tempa:=#5\do{
      \@tempa\unskip\space\@endcolumnactions}%
    \the\crtok \egroup \par \endgroup}

\newcommand*{\linespercol}{%
  \@cellsincolumn=\@linestogo
  \divide\@cellsincolumn \TX@cols
  \@cellstogo=\@cellsincolumn
  \multiply\@cellstogo \TX@cols
  \@tempcnta=\@linestogo
  \advance\@tempcnta -\@cellstogo
  \ifnum \@tempcnta>\z@
    \advance\@cellsincolumn \@ne
  \fi
  \global\@cellstogo=\@cellsincolumn}

\newcommand{\autorows}[5][0pt]{\par\begingroup
 \ctabsetlines
  \ctableftskip\fill
  \ctabrightskip\fill
  \if l#2
    \ctableftskip\z@
  \else
    \if r#2
      \ctabrightskip\z@
    \fi
  \fi
  \let\c@lleftskip\hfil
  \let\c@lrightskip\hfil
  \if l#4
    \let\c@lleftskip\relax
  \else
    \if r#4
      \let\c@lrightskip\relax
    \fi
  \fi
  \TX@cols=#3\relax
  \@curtab=#3\relax
  \@cellstogo = \TX@cols
  \@mincolumnwidth\z@
  \@linestogo\z@
  \@for\@tempa:=#5\do{%
    \advance\@linestogo\@ne
    \settowidth{\@tempdima}{\@tempa}
    \ifdim\@tempdima>\@mincolumnwidth
      \@mincolumnwidth=\@tempdima
    \fi}%
  \advance\@mincolumnwidth\tabcolsep
  \def\@endcolumnactions{%
    \global\advance\@linestogo\m@ne
    \global\advance\@cellstogo\m@ne
    \ifnum\@cellstogo<\@ne
      \global\@cellstogo=\TX@cols
      \the\crtok
    \else
      &
    \fi}%
  \ifdim #1>\z@
    \TX@col@width=#1
  \else
    \TX@col@width=\hsize
  \fi
  \divide\TX@col@width \TX@cols
  \ifdim #1=\z@
    \TX@col@width=\@mincolumnwidth
  \fi
  \penalty\abovecolumnspenalty
  \noindent % usually not a paragraph
  \vskip -\z@ % don't know why we need this, but looks bad without it
  \def\@preamble{}%
  \begingroup
    \let\@sharp\relax
    \ifnum\TX@cols>\@ne
      \loop
        \ifdim #1<\z@
          \g@addto@macro{\@preamble}{%
            \strut\c@lleftskip\@sharp\c@lrightskip &}%
        \else
          \g@addto@macro{\@preamble}{%
            \hb@xt@ \TX@col@width{%
                    \strut\c@lleftskip\@sharp\c@lrightskip} &}%
        \fi
        \advance\TX@cols\m@ne
      \ifnum\TX@cols>\@ne
      \repeat
    \fi
    \ifdim #1<\z@
      \g@addto@macro{\@preamble}{%
        \strut\c@lleftskip\@sharp\c@lrightskip}%
    \else
      \g@addto@macro{\@preamble}{%
        \hb@xt@ \TX@col@width{\strut\c@lleftskip\@sharp\c@lrightskip}}%
    \fi
  \endgroup
  \let\@sharp ##
  \tabskip\ctableftskip
  \halign to \hsize \bgroup
    \tabskip\z@
    \@preamble
%%    \tabskip\ctabrightskip\cr \preautotab
    \tabskip\ctabrightskip\cr
    \@for\@tempa:=#5\do{%
      \@tempa\unskip\space\@endcolumnactions}%
%%    \the\crtok \postautotab \the\crtok \egroup \endgroup \par
    \the\crtok \egroup \endgroup \par}

\newcounter{newflo@tctr}
  \setcounter{newflo@tctr}{1}

\newcommand{\newfloat}[4][\@empty]{%
%%%  \@namedef{ftype@#2}{\value{newflo@tctr}}
%%%  \addtocounter{newflo@tctr}{\value{newflo@tctr}}
  \expandafter\edef\csname ftype@#2\endcsname{\the\c@newflo@tctr}%
  \advance\c@newflo@tctr \c@newflo@tctr
  \@ifundefined{c@#2}{% counter is not defined
    \ifx \@empty#1\relax
      \newcounter{#2}
    \else
      \newcounter{#2}[#1]
      \expandafter\edef\csname the#2\endcsname{%
  \expandafter\noexpand\csname the#1\endcsname.\noexpand\arabic{#2}}
    \fi}{}
  \setcounter{#2}{0}

  \@namedef{ext@#2}{#3}%     file extension
  \@ifundefined{c@#3depth}{\newcounter{#3depth}}{}
  \setcounter{#3depth}{1}

  \@namedef{fps@#2}{tbp}                     % position
  \@namedef{fnum@#2}{#4~\@nameuse{the#2}}    % caption naming
  \@namedef{fleg#2}{#4}                      % legend naming
  \@namedef{flegtoc#2}##1{}                  % legend name in ToC

  \newenvironment{#2}{\@float{#2}}{\end@float}
  \newenvironment{#2*}{\@dblfloat{#2}}{\end@dblfloat}
} % end \newfloat

\newcommand*{\setfloatlocations}[2]{\@namedef{fps@#1}{#2}}

\newcommand*\setfloatadjustment[2]{\@namedef{#1adjustment}{#2}}

\newcommand{\newsubfloat}[1]{%
  \newlistentry[#1]{sub#1}{\@nameuse{ext@#1}}{1}
  \@namedef{ext@sub#1}{\csname ext@#1\endcsname}
  \@namedef{thesub#1}{(\alph{sub#1})}
  \@namedef{@thesub#1}{\@nameuse{thesub#1}%
            \if@tightsubcap\hskip\subfloatlabelskip\else\space\fi}
  \@namedef{@@thesub#1}{\@nameuse{thesub#1}}
  \@namedef{p@sub#1}{\csname the#1\endcsname}
  \@namedef{toclevel@sub#1}{1}}

\newif\ifdonemaincaption
  \donemaincaptionfalse

\let\@memoldfloat\@float
\renewcommand{\@float}[1]{\donemaincaptionfalse
  \@memresetsubcounter{#1}%
  \@memoldfloat{#1}}
\let\@memolddblfloat\@dblfloat
\renewcommand{\@dblfloat}[1]{\donemaincaptionfalse
  \@memresetsubcounter{#1}%
  \@memolddblfloat{#1}}
\newcommand{\@memresetsubcounter}[1]{%
  \@ifundefined{c@sub#1}{}{\csname c@sub#1\endcsname = 0\relax}}

\let\@memoldefloat\end@float
\def\end@float{%
  \@memlistsubcaptions{\@captype}\@memoldefloat}
\let\@memoldedblfloat\end@dblfloat
\def\end@dblfloat{%
  \@memlistsubcaptions{\@captype}\@memoldedblfloat}

\AtBeginDocument{%
  \@ifpackageloaded{fixltx2e}{%
    \@ifpackagelater{fixltx2e}{2014/01/01}{}{% package older than 2014/01/01
      \def\end@dblfloat{%
        \if@twocolumn
          \@endfloatbox
          \ifnum\@floatpenalty<\z@
            \@largefloatcheck
            \global\dp\@currbox1sp %
            \@cons\@deferlist\@currbox
          \fi
          \ifnum\@floatpenalty=-\@Mii \@Esphack\fi
        \else
          \end@float
        \fi}%
    }
  }{}
}

\def\mem@fb@botlist{\@botlist}
\def\mem@fb@topblock{\suppressfloats[t]}
\def\FloatBlock{\par\begingroup \let\@elt\relax
 \edef\@tempa{\mem@fb@botlist\@deferlist\@dbldeferlist}%
 \ifx\@tempa\@empty
 \else
    \ifx\@fltovf\relax % my indicator of recursion
       \if@firstcolumn
         \clearpage
       \else
         \null\newpage\FloatBlock
       \fi
    \else
       \newpage \let\@fltovf\relax
       \FloatBlock % recurse once only
 \fi\fi \endgroup
 \mem@fb@topblock}
\newcommand*\FloatBlockAllowAbove{\def\mem@fb@topblock{}}
\newcommand*\FloatBlockAllowBelow{\def\mem@fb@botlist{}}

\newcommand\setFloatBlockFor[1]{%
  \@namedef{#1block}{\FloatBlock}}
\newsavebox{\mem@margin@floatbox}
\newcommand\marginfloatmarginmacro{\marginpar}
\newenvironment{mem@margin@float}[2][-1.2ex]%
  {\FloatBlock%
  \begin{lrbox}{\mem@margin@floatbox}%
  \begin{minipage}{\marginparwidth}%
    \def\@captype{#2}%
    \hbox{}\vspace*{#1}%
    \@nameuse{margin#2adjustment}%
    \@nameuse{margin#2captionadjustment}%
    \noindent%
  }
  {\end{minipage}%
  \end{lrbox}%
  \marginfloatmarginmacro{\usebox{\mem@margin@floatbox}}%
  }
\newenvironment{marginfigure}[1][-1.2ex]{%
  \begin{mem@margin@float}[#1]{figure}}
  {\end{mem@margin@float}}
\newenvironment{margintable}[1][-1.2ex]{%
  \begin{mem@margin@float}[#1]{table}}
  {\end{mem@margin@float}}
\setfloatadjustment{marginfigure}{\centering}
\setfloatadjustment{margintable}{\centering}

\newcommand*\setmarginfloatcaptionadjustment[2]{%
  \@namedef{margin#1captionadjustment}{#2}}

\newcommand\setmpjustification[2]{%
  \@namedef{mem@mp@justification}{%
    \ifm@msetmp\else\@memerror{In order to use
      \string\marginCmdAdjust,^^J%
      please make sure to specify into which margin the^^J%
      \string\marginpar\space should go, using \string\marginparmargin}{}\fi
    \m@mwhich@margin{\m@mmpar@margin}%
     \ifmemtortm #2 \else #1\fi}%
}
\newcommand\mpjustification{%
  \@nameuse{mem@mp@justification}}
\setmpjustification{\raggedleft}{\raggedright}

\newif\if@contcw
\newif\if@conthang
\newif\if@contindent

\newcommand{\captiondelim}[1]{\def\@contdelim{#1}}
\captiondelim{: }

\newcommand{\captionnamefont}[1]{\def\@contnfont{#1}}
\captionnamefont{}

\newcommand{\captiontitlefont}[1]{\def\@conttfont{#1}}
\captiontitlefont{}

\newcommand*{\captionstyle}[1]{\def\@contcstyle{#1}}
\captionstyle{}

\renewcommand{\captionstyle}{%
  \@ifnextchar[{\@memcshort}{\@memcnorm}}
\def\@memcshort[#1]#2{%
  \def\@contcshortstyle{#1}%
  \def\@contcstyle{#2}}
\def\@memcnorm#1{%
  \def\@contcshortstyle{#1}%
  \def\@contcstyle{#1}}
\captionstyle{}

\newlength{\@contcwidth}
\newcommand{\captionwidth}[1]{\setlength{\@contcwidth}{#1}}
\captionwidth{\linewidth}
\newcommand{\changecaptionwidth}{\@contcwtrue}
\newcommand{\normalcaptionwidth}{\@contcwfalse}
\normalcaptionwidth

\newlength{\@contindw}
\newcommand{\hangcaption}{\@conthangtrue\@contindentfalse}
\newcommand{\indentcaption}[1]{\setlength{\@contindw}{#1}%
  \@conthangfalse\@contindenttrue}
\newcommand{\normalcaption}{\@conthangfalse\@contindentfalse}
\normalcaption

\newcommand{\precaption}[1]{\def\@contpre{#1}}
\precaption{}
\newcommand{\postcaption}[1]{\def\@contpost{#1}}
\postcaption{}
\newcommand{\midbicaption}[1]{\def\@contmidbi{#1}}
\midbicaption{}

\newcommand*{\captiontitlefinal}[1]{\def\@contfinal{#1}}
  \captiontitlefinal{}

\newlength{\abovecaptionskip}
  \setlength{\abovecaptionskip}{0.5\onelineskip}
\newlength{\belowcaptionskip}
  \setlength{\belowcaptionskip}{0.5\onelineskip}

\let\@memoldcaption\caption
\def\caption{\donemaincaptiontrue\@memoldcaption}

\newcommand{\memcaptioninfo}[4]{}

\let\@memold@caption\@caption
\long\def\@caption#1[#2]#3{%
  \M@gettitle{#2}%
  \memcaptioninfo{#1}{\csname the#1\endcsname}{#2}{#3}%
  \@memold@caption{#1}[{#2}]{#3}}

\long\def\@makecaption#1#2{\let\@memtempa\relax
  \ifdim\prevdepth>-99\p@ \vskip\abovecaptionskip
  \else \def\@memtempa{\vbox to\topskip{}}\fi
  \@@makecaption{#1}{#2}%
  \vskip\belowcaptionskip}

\long\def\@@makecaption#1#2{%
  \let\@contfnote\footnote \renewcommand{\footnote}[2][]{}
  \let\@contfmark\footnotemark \renewcommand{\footnotemark}[1][]{}
  \let\@contpnote\pagenote\renewcommand\pagenote[2][]{}
  \sbox\@tempboxa{{\@contnfont #1\@contdelim}\@conttfont #2\@contfinal}
  \let\footnote\@contfnote
  \let\footnotemark\@contfmark
  \let\pagenote\@contpnote
  \ifdim\wd\@tempboxa<\linewidth \centering \fi
  \if@contcw
    \centering
    \parbox[t]{\@contcwidth}{%
    \ifdim\wd\@tempboxa<\@contcwidth \centering \fi
  \fi
  \ifdim\wd\@tempboxa<\linewidth
    \@contpre
    {\@contnfont #1\@contdelim}\@memtempa
    {\@contcshortstyle \@conttfont #2\@contfinal\par}
  \else
    \if@conthang
      \sbox\@tempboxa{\@contnfont #1\@contdelim}
      \@contpre%
      {\@contcstyle\hangindent=\wd\@tempboxa
       \noindent\box\@tempboxa\@memtempa \@conttfont #2\@contfinal\par}
    \else
      \if@contindent
        \@contpre%
        {\@contnfont #1\@contdelim}\@memtempa
        {\@contcstyle\hangindent=\@contindw
                     \hangafter=\@ne\@conttfont #2\@contfinal\par}% <- v1.4
      \else
        \@contpre%
        {\@contnfont #1\@contdelim}\@memtempa
        {\@contcstyle \@conttfont #2\@contfinal\par}
      \fi
    \fi
  \fi
  \@contpost
  \if@contcw
    \par
    }  % end of the \parbox
  \fi
  }

\newcommand{\contcaption}{%
  \addtocounter{\@captype}{\m@ne}\refstepcounter{\@captype}%
  \@contcaption\@captype}

\long\def\@@contcaption#1#2{%
  \par
  \begingroup
     \@parboxrestore
     \if@minipage
       \@setminipage
     \fi
     \normalsize
     \@makecaption{\csname fnum@#1\endcsname}{\ignorespaces #2}\par
  \endgroup}

\long\def\@contcaption#1#2{%
  \if@contbotsub
    \@memlistsubcaptions{#1}%
    \@@contcaption{#1}{#2}%
  \else
    \@@contcaption{#1}{#2}%
    \@memlistsubcaptions{#1}%
  \fi}

\newcommand{\memlegendinfo}[1]{}
\newcommand{\legend}[1]{%
  \M@gettitle{#1}%
  \memlegendinfo{#1}%
  \par
  \begingroup
     \@parboxrestore
     \if@minipage
       \@setminipage
     \fi
     \normalsize
     \captiondelim{\mbox{}}
     \@makecaption{}{\ignorespaces #1}\par
  \endgroup}

\newcommand{\namedlegend}{\@dblarg{\@legend\@captype}}
\newcommand{\memnamedlegendinfo}[3]{}

\long\def\@legend#1[#2]#3{%
  \M@gettitle{#2}%
  \memnamedlegendinfo{#1}{#2}{#3}%
  \par
  \csname flegtoc#1\endcsname{#2}%
  \begingroup
    \@parboxrestore
    \if@minipage
      \@setminipage
    \fi
    \normalsize
    \@makecaption{\csname fleg#1\endcsname}{\ignorespaces #3}\par
  \endgroup}

\newcommand{\newfixedcaption}[3][\caption]{%
  \newcommand{#2}{\def\@captype{#3}#1}}
\newcommand{\renewfixedcaption}[3][\caption]{%
  \renewcommand{#2}{\def\@captype{#3}#1}}
\newcommand{\providefixedcaption}[3][\caption]{%
  \providecommand{#2}{\def\@captype{#3}#1}}

\newcommand{\membitwonumcaptioninfo}[7]{}
\newcommand{\membionenumcaptioninfo}[7]{}
\newcommand{\membicaptioninfo}[6]{}

\newcommand{\bitwonumcaption}[6][\@empty]{%
  \begingroup
  \let\memcaptioninfo\@gobblefour
  \@ifmtarg{#2}{\def\m@mscapi{#3}\caption{#3}}%
               {\def\m@mscapi{#2}\caption[#2]{#3}}%
  \ifx \@empty #1\else
    \label{#1}%
  \fi
  \setlength{\abovecaptionskip}{0pt}%
  \setlength{\belowcaptionskip}{0pt}%
  \edef\@memtempc{#4}%
  \expandafter\renewcommand\csname \@captype name\endcsname{\@memtempc}%
  \addtocounter{\@captype}{-1}%
  \@contmidbi
  \@ifmtarg{#5}{\def\m@mscapii{#6}\caption{#6}}%
               {\def\m@mscapii{#5}\caption[#5]{#6}}%
  \membitwonumcaptioninfo{\@captype}{\@nameuse{the\@captype}}%
                         {\m@mscapi}{#3}{#4}{\m@mscapii}{#6}%
  \endgroup}

\newcommand{\bionenumcaption}[6][\@empty]{%
  \begingroup
  \let\memcaptioninfo\@gobblefour
  \@ifmtarg{#2}{\def\m@mscapi{#3}\caption{#3}}%
               {\def\m@mscapi{#2}\caption[#2]{#3}}%
  \ifx \@empty #1\else
    \label{#1}%
  \fi
  \setlength{\abovecaptionskip}{0pt}%
  \setlength{\belowcaptionskip}{0pt}%
  \edef\@memtempc{#4}%
  \expandafter\renewcommand\csname \@captype name\endcsname{\@memtempc}
  \@contmidbi
  \contcaption{#6}%
  \@ifmtarg{#5}{%
    \def\m@mscapii{#6}%
    \addcontentsline{\csname ext@\@captype\endcsname}{\@captype}%
      {\protect\numberline{}{\ignorespaces #6}}}{%
    \def\m@mscapii{#5}%
    \addcontentsline{\csname ext@\@captype\endcsname}{\@captype}%
      {\protect\numberline{}{\ignorespaces #5}}}%
  \membionenumcaptioninfo{\@captype}{\@nameuse{the\@captype}}%
                         {\m@mscapi}{#3}{#4}{\m@mscapii}{#6}%
  \endgroup}

\newcommand{\bicaption}[5][\@empty]{%
  \begingroup
  \let\memcaptioninfo\@gobblefour
  \@ifmtarg{#2}{\def\m@mscapi{#3}\caption{#3}}%
               {\def\m@mscapi{#2}\caption[#2]{#3}}%
  \ifx \@empty #1\else
    \label{#1}%
  \fi
  \setlength{\abovecaptionskip}{0pt}%
  \setlength{\belowcaptionskip}{0pt}%
  \edef\@memtempc{#4}
  \expandafter\renewcommand\csname \@captype name\endcsname{\@memtempc}%
  \@contmidbi
  \contcaption{#5}%
  \membicaptioninfo{\@captype}{\@nameuse{the\@captype}}%
                   {\m@mscapi}{#3}{#4}{#5}%
  \endgroup}

\newcommand{\bicontcaption}[3]{%
  \begingroup
  \contcaption{#1}%
  \setlength{\abovecaptionskip}{0pt}%
  \setlength{\belowcaptionskip}{0pt}%
  \edef\@memtempc{#2}%
  \expandafter\renewcommand\csname \@captype name\endcsname{\@memtempc}%
  \@contmidbi
  \contcaption{#3}%
  \endgroup}

\newcommand{\subcaptionstyle}[1]{\def\@contsubcstyle{#1}}
\subcaptionstyle{}

\newif\if@shortsubcap
\newif\if@hangsubcap
\newcommand*{\shortsubcaption}{\@shortsubcaptrue}
\newcommand*{\hangsubcaption}{\@hangsubcaptrue}
\newcommand*{\normalsubcaption}{\@shortsubcapfalse\@hangsubcapfalse}
\normalsubcaption

\newskip\subfloattopskip
\newskip\subfloatcapskip
\newskip\subfloatcaptopadj
\newskip\subfloatbottomskip
\newskip\subfloatlabelskip
\newdimen\subfloatcapmargin
\newif\if@tightsubcap
\newcommand{\loosesubcaptions}{%
  \subfloattopskip = 10\p@
  \subfloatcapskip  = 10\p@
  \subfloatcaptopadj = \z@
  \subfloatbottomskip = 10\p@
  \subfloatlabelskip = 0.33em
  \subfloatcapmargin = 10\p@
  \@tightsubcapfalse
}

\newcommand{\tightsubcaptions}{%
  \subfloattopskip = 5\p@
  \subfloatcapskip  = \z@
  \subfloatcaptopadj = 3\p@
  \subfloatbottomskip = 5\p@
  \subfloatlabelskip = 0.33em \@plus 0.07em \@minus 0.03em
  \subfloatcapmargin = \z@
  \@tightsubcaptrue
}
\tightsubcaptions

\newcommand*{\subcaptionsize}[1]{\def\@subcapsize{#1}}
\newcommand*{\subcaptionlabelfont}[1]{\def\@subcaplabelfont{#1}}
\newcommand*{\subcaptionfont}[1]{\def\@subcapfont{#1}}
\subcaptionsize{\footnotesize}
\subcaptionlabelfont{\normalfont}
\subcaptionfont{\normalfont}

  \newcounter{@contsubnum}
  \newcommand{\@contkeep}{%
    \setcounter{@contsubnum}{\value{sub\@captype}}}
  \newcommand{\@contset}{%
    \setcounter{sub\@captype}{\value{@contsubnum}}}
  \newcommand{\subconcluded}{%
    \setcounter{sub\@captype}{0}}
\newif\if@contbotsub
  \@contbotsubtrue

\newcommand{\subcaption}{%
  \par
  \bgroup
    \let\label=\memsub@label
    \ifdonemaincaption\else
      \advance\csname c@\@captype\endcsname\@ne
    \fi
    \mem@step@subcounter%
    \@ifnextchar [%
      {\@memsubcap{sub\@captype}}%
      {\@memsubcap{sub\@captype}[\@empty]}}
\long\def\@memsubcap#1[#2]#3{%
  \@tempdima=\hsize
  \vskip\subfloatcapskip
  \ifx \@empty #2
    \@memsubcaption{#1}{#3}{#3}%
  \else
    \@memsubcaption{#1}{#2}{#3}%
  \fi
  \vskip\subfloatcapskip
  \egroup}
\newcommand{\@memsubcaption}[3]{%
  \ifx \relax#2\relax \else
    \bgroup
      \let\label\@gobble
      \let\protect\string
      \def\@memsubcaplabel{\@nameuse{@@the#1}}%
      \xdef\@memsubfigcaptionlist{%
        \@memsubfigcaptionlist,%
  {\protect\numberline{\@memsubcaplabel}\noexpand{\ignorespaces #2}}}%
    \egroup
  \fi
  \@makesubfloatcaption{\@nameuse{@the#1}}{#3}}

\newcommand{\contsubcaption}{%
  \bgroup%
    \let\label=\memsub@label
    \@contset%
    \mem@step@subcounter%
    \@ifnextchar [%
      {\@memsubcap{sub\@captype}}%
      {\@memsubcap{sub\@captype}[\@empty]}}
\newenvironment{subfloat}{}{}

\newcommand\mem@step@subcounter{%
  \refstepcounter{sub\@captype}\@contkeep%
  \UseHook{memoir/subcaption/aftercounter}%
}
\newcommand{\subbottom}{%
  \@contbotsubtrue
  \@memsubbody}

\newcommand{\@memsubbody}{%
  \bgroup
  \let\label=\memsub@label
  \ifdonemaincaption\else
    \advance\csname c@\@captype\endcsname\@ne
  \fi
  % \refstepcounter{sub\@captype}\@contkeep%
  \leavevmode
  \@ifnextchar [%
    {\@memsubfig}%
    {\@memsubfig[\@empty]}}

\newcommand{\contsubbottom}{%
  \@contbotsubtrue
  \@memcontsubbody}

\newcommand{\@memcontsubbody}{%
  \bgroup
  \let\label=\memsub@label
  \@contset
  % \refstepcounter{sub\@captype}\@contkeep%
  \leavevmode
  \@ifnextchar [%
    {\@memsubfig}%
    {\@memsubfig[\@empty]}}

\newcommand{\subtop}{%
  \@contbotsubfalse
  \@memsubbody}

\newcommand{\contsubtop}{%
  \@contbotsubfalse
  \@memcontsubbody}

\def\@memsubfig[#1]{%
  \@ifnextchar [%
    {\@memsubfloat{sub\@captype}[#1]}%
    {\@memsubfloat{sub\@captype}[\@empty #1][#1]}}

\long\def\@memsubfloat#1[#2][#3]#4{%
  \@tempcnta=\@ne
  \if@tightsubcap
    \if@minipage
      \@tempcnta=\z@
    \else
      \ifdim\lastskip=\z@
        \@tempcnta=\@ne
      \else
        \@tempcnta=\tw@
      \fi
    \fi
  \fi
  \if@contbotsub
    \def\subfig@top{\subfloattopskip}%
    \def\subfig@bottom{\subfloatbottomskip}%
  \else
    \def\subfig@top{\subfloatbottomskip}%
    \def\subfig@bottom{\subfloattopskip}%
  \fi
  \setbox\@tempboxa \hbox{#4}%
  \@tempdima=\wd\@tempboxa
  \vbox\bgroup%
    \mem@step@subcounter%
    \vbox\bgroup
    \ifcase\@tempcnta
      \@minipagefalse
    \or
      \vspace{\subfig@top}
    \or
      \ifdim \lastskip=\z@ \else
        \@tempskipb\subfig@top\@xaddvskip
      \fi
    \fi
    \if@contbotsub
      \box\@tempboxa\egroup
      \ifx \@empty#3\relax \else
        \vskip\subfloatcapskip
        \@memsubcaption{#1}{#2}{#3}%
      \fi
    \else
      \ifx \@empty#3\relax \else
        \@memsubcaption{#1}{#2}{#3}%
        \vskip\subfloatcapskip
        \vskip\subfloatcaptopadj
      \fi\egroup
      \box\@tempboxa
    \fi
    \vspace{\subfig@bottom}
  \egroup
\egroup}

\newcommand*{\@memsubfigcaptionlist}{}
\newcommand*{\memlistsubcaptions}{%
  \@ifstar
    {\gdef\@memsubfigcaptionlist{}}%
    {\@memlistsubcaptions{\@captype}}}

\newcommand*{\@memlistsubcaptions}[1]{%
  \@ifundefined{@captype}{}{%
    \@ifundefined{ext@sub#1}{}{%
      \@for \@tempa:=\@memsubfigcaptionlist \do {%
        \ifx \@empty\@tempa\relax \else
          \addcontentsline{\@nameuse{ext@sub#1}}{sub#1}{\@tempa}%
        \fi}}}%
  \gdef\@memsubfigcaptionlist{}}

\newcommand{\@makesubfloatcaption}[2]{%
  \setbox\@tempboxa\hbox{%
    \@subcapsize
    {\@subcaplabelfont #1}{\@subcapfont\ignorespaces #2}\unskip}%
  \@tempdimb=-\subfloatcapmargin
  \multiply\@tempdimb\tw@
  \advance\@tempdimb\@tempdima
  \hb@xt@\@tempdima{%
    \hss
    \ifdim \wd\@tempboxa >\@tempdimb
      \memsubfig@caption{#1}{#2}%
    \else
      \if@shortsubcap
        \memsubfig@caption{#1}{#2}%
      \else
        \box\@tempboxa
      \fi
    \fi
    \hss}}

\newcommand{\memsubfig@caption}[2]{%
  \if@hangsubcap
    \sbox{\@tempboxa}{\@subcapsize\@subcaplabelfont #1}%
    \addtolength{\@tempdimb}{-\wd\@tempboxa}%
    \usebox{\@tempboxa}%
    \memsubfig@captionpar{\@tempdimb}{%
      {\@subcapfont\ignorespaces #2}\unskip}%
  \else
    \memsubfig@captionpar{\@tempdimb}{{\@subcaplabelfont #1}%
      {\@subcapfont\ignorespaces #2}\unskip}%
  \fi}

\newcommand{\memsubfig@captionpar}[2]{%
  \parbox[t]{#1}{\@subcapsize\@contsubcstyle #2}}

\newcommand{\memsub@label}{%
  \@ifnextchar (%
    {\sf@memsub@label}%
    {\sf@memsub@label(Sub\@captype\space
                     \@nameuse{p@sub\@captype}%
                     \@nameuse{thesub\@captype})}}
\def\sf@memsub@label(#1)#2{%
  \protected@edef\@currentlabelname{#1}%
  % if available we can also use %  \ExpandArgs{x}\mem@set@cln{#1}
  \sf@@memsub@label{#2}}

\AtBeginDocument{
  \let\mem@kernel@label\label
}

\newcommand\sf@@memsub@label[1]{%
  \@bsphack%
  \mem@kernel@label{#1}% normal label
  \begingroup%
  % \ExpandArgs{x}\mem@set@cln{\@nameuse{@@thesub\@captype}}
  \protected@edef\@currentlabel{\@nameuse{@@thesub\@captype}}% sub@label
  \def\showkeyslabelformat##1{}% disable showkeys for this extra label
  \mem@kernel@label{sub@#1}% internally generated sub@label
  \endgroup%
  \@esphack%
}

\DeclareRobustCommand{\subcaptionref}{%
  \@ifstar{\ssc@ref}{\sc@ref}}
\newcommand*{\ssc@ref}[1]{\ref{sub@#1}}
\newcommand*{\sc@ref}[1]{{\@subcaplabelfont\ref{sub@#1}}}

\newsavebox{\m@mscap@capbox}
\newsavebox{\m@mscap@fbox}

\newdimen\sidecapsep
  \sidecapsep=\marginparsep
\newdimen\sidecapwidth
  \sidecapwidth=\marginparwidth
\newcommand*{\setsidecaps}[2]{%
  \setlength{\sidecapsep}{#1}\@memznegtest{\sidecapsep}%
  \setlength{\sidecapwidth}{#2}\@memznegtest{\sidecapwidth}}

\newdimen\m@m@tempdima
\newdimen\m@mscapraise
\newdimen\sidecapraise
  \sidecapraise \z@

\newcommand*{\setsidecappos}[1]{%
  \def\m@mscappos{#1}\def\@tempb{t}%
  \ifx\@tempb\m@mscappos
  \else
    \def\@tempb{b}%
    \ifx\@tempb\m@mscappos
    \else
      \def\@tempb{c}%
      \ifx\@tempb\m@mscappos
      \else
        \@memerror{Argument to \string\setsidecappos\space is not t or c or b.
                   \MessageBreak Set to c}{\@ehc}%
        \def\m@mscappos{c}%
      \fi
    \fi
  \fi}
\setsidecappos{c}

\newcommand{\sidecapmargin}[1]{%
  \def\@tempa{#1}\def\@tempb{left}%
    \ifx\@tempb\@tempa
      \def\m@mscapmarg{0}%   left
    \else
      \def\@tempb{right}%
      \ifx\@tempb\@tempa
        \def\m@mscapmarg{1}%  right
      \else
        \def\@tempb{outer}%
        \ifx\@tempb\@tempa
          \def\m@mscapmarg{2}%  outer
        \else
          \def\@tempb{inner}%
          \ifx\@tempb\@tempa
            \def\m@mscapmarg{3}%  inner
          \else
            \@memerror{Unrecognized argument for \string\sidecapmargin}%
                      {\@ehc}%
            \def\m@mscapmarg{-1}% error
          \fi
        \fi
      \fi
    \fi}
\sidecapmargin{left}

\newif\ifscapmargleft

\def\sidecapfloatwidth{\linewidth}
\newdimen\m@mscapmainwidth

\newdimen\m@mscaplkern
\newcommand*{\setm@mscaplkern}{%
  \m@mscaplkern=\sidecapwidth
  \advance\m@mscaplkern \sidecapsep
  \advance\m@mscaplkern \m@mscapmainwidth}

\newcommand*{\sidecapstyle}{%
  \ifscapmargleft
    \captionstyle{\raggedleft}%
  \else
    \captionstyle{\raggedright}%
  \fi}

\newcommand*{\sidecaption}{%
  \@ifnextchar [{\@sidecaption}{\@sidecaption[]}}
\def\@sidecaption[#1]#2{%
  \@ifnextchar [{\@@sidecaption{#1}{#2}}{\@@sidecaption{#1}{#2}[]}}
\newcommand\@mem@scap@beforehook{}
\newcommand\@mem@scap@afterhook{}

\def\@@sidecaption#1#2[#3]{%
  \ifx\@empty#1\@empty
    \def\m@mscap@fortoc{#2}%
  \else
    \def\m@mscap@fortoc{#1}%
  \fi
  \def\m@mscap@forcap{#2}%
  \ifx\@empty#3\@empty
    \def\m@mscaplabel{}%
  \else
    \def\m@mscaplabel{\@bsphack\label{#3}\@esphack}%
  \fi
  \m@mscapstart@fbox}

\newcommand*{\m@mscapstart@fbox}{%
  \@mem@scap@beforehook%
  \setlength{\m@mscapmainwidth}{\sidecapfloatwidth}%
  \setm@mscaplkern
  \begin{lrbox}{\m@mscap@fbox}%
    \begin{minipage}[c]{\m@mscapmainwidth}}
\newcommand*{\m@mscapend@fbox}{%
    \end{minipage}%
  \end{lrbox}}

\def\endsidecaption{%
  \m@mscapend@fbox
  \refstepcounter\@captype
  \m@mscaplabel
  \m@mscapcheckside %<--- added 2012/08/19
  \begin{lrbox}{\m@mscap@capbox}%
    \begin{minipage}[c]{\sidecapwidth}%
      \sidecapstyle
      \@caption\@captype[\m@mscap@fortoc]{\m@mscap@forcap}
    \end{minipage}%
  \end{lrbox}%
  \m@mscapopboxes}
\newcommand*{\m@mscapopboxes}{%
  \m@mcalcscapraise
  \usebox{\m@mscap@fbox}%\m@mscapcheckside
  \ifscapmargleft%
    \rlap{\kern-\m@mscaplkern
          \raisebox{\m@mscapraise}{\usebox{\m@mscap@capbox}}}%
  \else%
    \rlap{\kern\sidecapsep
          \raisebox{\m@mscapraise}{\usebox{\m@mscap@capbox}}}%
  \fi
  \gdef\m@mscapthisside{}%
  \@mem@scap@afterhook%
}

\newcommand*{\m@mcalcscapraise}{%
  \def\@tempb{t}%
  \ifx\m@mscappos\@tempb
    \settoheight{\m@m@tempdima}{\strut\usebox{\m@mscap@capbox}}%
    \settoheight{\m@mscapraise}{\usebox{\m@mscap@fbox}}%
    \advance\m@mscapraise -\m@m@tempdima
    \advance\m@mscapraise  0.5ex
  \else
    \def\@tempb{b}%
    \ifx\m@mscappos\@tempb
      \settodepth{\m@m@tempdima}{\usebox{\m@mscap@fbox}}%
      \settodepth{\m@mscapraise}{\strut\usebox{\m@mscap@capbox}}%
      \advance\m@mscapraise -\m@m@tempdima
    \else
      \m@mscapraise=\z@
      \advance\m@mscapraise 0.25ex
    \fi
  \fi
  \advance\m@mscapraise  \sidecapraise}

\newcommand*{\m@mscapcheckside}{%
  \if@twocolumn
    \ifdim\hsize=\textwidth%  float*
      \m@mscapcheckregside
    \else
      \if@firstcolumn
        \scapmarglefttrue
      \else
        \scapmargleftfalse
      \fi
    \fi
  \else
    \m@mscapcheckregside
  \fi
  \m@mscapthisside}
\newcommand*{\m@mscapcheckregside}{%
    \if@twoside
      \checkoddpage
      \ifnum\m@mscapmarg<\@ne%      % left
        \scapmarglefttrue
      \else
        \ifnum\m@mscapmarg=\@ne%    % right
          \scapmargleftfalse
        \else
          \ifnum\m@mscapmarg=\tw@%  % outer
            \scapmarglefttrue
            \ifoddpage
              \scapmargleftfalse
            \fi
          \else%                  % inner
            \scapmargleftfalse
            \ifoddpage
              \scapmarglefttrue
            \fi
          \fi
        \fi
      \fi
    \else%     oneside
      % \scapmarglefttrue% 0 and 3
      % \ifnum\m@mscapmarg>\@ne
      %   \ifnum\m@mscapmarg<\thr@@
      %     \scapmargleftfalse
      %   \fi
      % \fi
      \ifcase\m@mscapmarg\relax% 0
        \scapmarglefttrue%
      \or% 1
        \scapmargleftfalse%
      \or% 2
        \scapmargleftfalse%
      \or% 3
        \scapmarglefttrue%
      \fi%
    \fi}

\newcommand*{\overridescapmargin}[1]{%
  \def\@tempb{#1}\def\@tempa{left}%
  \ifx\@tempa\@tempb
    \def\m@mscapthisside{\scapmarglefttrue}%
  \else
    \def\@tempa{right}%
    \ifx\@tempa\@tempb
      \def\m@mscapthisside{\scapmargleftfalse}%
    \else
      \@memerror{Argument to \string\overridescapmargin\space neither
                 left nor right}{\@ehc}%
      \def\m@mscapthisside{}%
    \fi
  \fi}
\newcommand*{\m@mscapthisside}{}

\newcommand*{\sidecontcaption}{%
  \@sidecontcaption}
\def\@sidecontcaption#1{%
  \@ifnextchar [{\@@sidecontcaption{#1}}{\@@sidecontcaption{#1}[]}}
\def\@@sidecontcaption#1[#2]{%
  \def\m@mscap@forcap{#1}%
  \ifx\@empty#2\@empty
    \def\m@mscaplabel{}%
  \else
    \def\m@mscaplabel{\@bsphack\label{#2}\@esphack}%
  \fi
  \m@mscapstart@fbox}

\def\endsidecontcaption{%
  \m@mscapend@fbox
  \addtocounter{\@captype}{\m@ne}\refstepcounter\@captype
  \m@mscaplabel
  \m@mscapcheckside %<--- added 2013/05/30
  \begin{lrbox}{\m@mscap@capbox}%
    \begin{minipage}[c]{\sidecapwidth}%
      \sidecapstyle
      \@contcaption\@captype{\m@mscap@forcap}
    \end{minipage}%
  \end{lrbox}%
  \m@mscapopboxes}

\newcommand*{\sidenamedlegend}{%
  \@ifnextchar [{\@sidenamedlegend}{\@sidenamedlegend[]}}
\def\@sidenamedlegend[#1]#2{%
  \@@sidenamedlegend{#1}{#2}}
\def\@@sidenamedlegend#1#2{%
  \ifx\@empty#1\@empty
    \def\m@mscap@fortoc{#2}%
  \else
    \def\m@mscap@fortoc{#1}%
  \fi
  \def\m@mscap@forcap{#2}%
  \def\m@mscaplabel{}%
  \m@mscapstart@fbox}

\def\endsidenamedlegend{%
  \m@mscapend@fbox
  \begin{lrbox}{\m@mscap@capbox}%
    \begin{minipage}[c]{\sidecapwidth}%
      \sidecapstyle
      \@legend\@captype[\m@mscap@fortoc]{\m@mscap@forcap}
    \end{minipage}%
  \end{lrbox}%
  \m@mscapopboxes}

\newcommand*{\sidelegend}{%
  \@@sidelegend}
\def\@@sidelegend#1{%
  \def\m@mscap@forcap{#1}%
  \m@mscapstart@fbox}

\def\endsidelegend{%
  \m@mscapend@fbox
  \begin{lrbox}{\m@mscap@capbox}%
    \begin{minipage}[c]{\sidecapwidth}%
      \sidecapstyle
      \legend{\m@mscap@forcap}
    \end{minipage}%
  \end{lrbox}%
  \m@mscapopboxes}

\AtBeginDocument{
  \@ifpackageloaded{longtable}{
    \@ifpackageloaded{ltcaption}{}{%
      \def\LT@makecaption#1#2#3{%
        \LT@mcol\LT@cols c{\hbox to\z@{\hss\parbox[t]\LTcapwidth{%
           \let\@memtempa\relax%
           % starred form -> #1 = \@gobble
           \ifx#1\@gobble%
             \let\@contnfont\@empty%
             \let\@contdelim\@empty%
             \@@makecaption{}{#3}%
           \else%
             \@@makecaption{#2}{#3}%
           \fi%
           \endgraf\vskip\belowcaptionskip}%
         \hss}}}
    }
  }{}
}
\newlength{\beforeepigraphskip}
  \setlength{\beforeepigraphskip}{.5\baselineskip}
\newlength{\afterepigraphskip}
  \setlength{\afterepigraphskip}{.5\baselineskip}
\newlength{\epigraphwidth}
  \setlength{\epigraphwidth}{.4\textwidth}
\newlength{\epigraphrule}
  \setlength{\epigraphrule}{.4\p@}
\newcommand{\epigraphsize}{\small}
\newcommand{\epigraphflush}{flushright}
\newcommand{\textflush}{flushleft}
\newcommand{\sourceflush}{flushright}
\newcommand{\epigraphfontsize}[1]{\def\epigraphsize{#1}}
\newcommand{\epigraphposition}[1]{\long\def\epigraphflush{#1}}
\newcommand{\epigraphtextposition}[1]{\def\textflush{#1}}
\newcommand{\epigraphsourceposition}[1]{\def\sourceflush{#1}}

\newcommand{\@epirule}{\rule[.5ex]{\epigraphwidth}{\epigraphrule}}
\newcommand{\@epitext}[1]{%
  \begin{minipage}{\epigraphwidth}\begin{\textflush} #1\par
    \ifdim\epigraphrule>\z@ \@epirule \else \vspace*{1ex} \fi
  \end{\textflush}\end{minipage}}
\newcommand{\@episource}[1]{%
  \begin{minipage}{\epigraphwidth}
    \begin{\sourceflush} #1\par
  \end{\sourceflush}\end{minipage}}

\newcommand{\epigraph}[2]{\vspace{\beforeepigraphskip}
  {\epigraphsize\begin{\epigraphflush}\begin{minipage}{\epigraphwidth}
    \@epitext{#1}\\ \@episource{#2}
    \end{minipage}\end{\epigraphflush}
    \vspace{\afterepigraphskip}}}
\newcommand{\qitem}[2]{{%
  \raggedright\item \begin{minipage}{\epigraphwidth}
    \@epitext{#1}\\ \@episource{#2}
  \end{minipage}}}
\newcommand{\qitemlabel}[1]{\hfill}
\newenvironment{epigraphs}{%
  \vspace{\beforeepigraphskip}\begin{\epigraphflush}
  \epigraphsize
  \begin{minipage}{\epigraphwidth}
   \list{}%
    {\itemindent\z@ \labelwidth\z@ \labelsep\z@
     \leftmargin\z@ \rightmargin\z@
     \let\makelabel\qitemlabel}}%
  {\endlist\end{minipage}\end{\epigraphflush}
   \vspace{\afterepigraphskip}}
\newcommand{\dropchapter}[1]{%
  \let\@epichapapp\@chapapp
  \renewcommand{\@chapapp}{\vspace*{#1}\@epichapapp}}
\newcommand{\undodrop}{\let\@chapapp\@epichapapp}
\newif\if@epirhs     \@epirhstrue
\newif\if@epicenter  \@epicentertrue
\newcommand{\@epipos}{
  \long\def\@ept{flushleft}
  \ifx\epigraphflush\@ept
    \@epirhsfalse \@epicenterfalse
  \else
    \long\def\@ept{center}
    \ifx\epigraphflush\@ept
      \@epirhsfalse \@epicentertrue
    \else
      \@epirhstrue  \@epicenterfalse
    \fi
  \fi}
\newcommand{\epigraphhead}[2][95]{%
  \def\@epitemp{\begin{minipage}{\epigraphwidth}#2\end{minipage}}
  \def\ps@epigraph{\let\@mkboth\@gobbletwo
    \@epipos
    \if@epirhs
      \def\@oddhead{\hfil\begin{picture}(0,0)
                         \put(0,-#1){\makebox(0,0)[r]{\@epitemp}}
                         \end{picture}}
    \else
      \if@epicenter
        \def\@oddhead{\hfil\begin{picture}(0,0)
                           \put(0,-#1){\makebox(0,0)[b]{\@epitemp}}
                           \end{picture}\hfil}
      \else
        \def\@oddhead{\begin{picture}(0,0)
                           \put(0,-#1){\makebox(0,0)[l]{\@epitemp}}
                           \end{picture}\hfil}
      \fi
    \fi
    \let\@evenhead\@oddhead
    \def\@oddfoot{\reset@font\hfil\thepage\hfil}
    \let\@evenfoot\@oddfoot}
  \thispagestyle{epigraph}}

\newcommand{\the@epigraph}{}
\newcommand{\@epidrop}{95}
\newcommand{\epigraphforheader}[2][95]{%
  \def\@epidrop{#1}\long\def\the@epigraph{#2}}

\newcommand{\epigraphpicture}{%
  \def\@epitemp{%
    \begin{minipage}{\epigraphwidth}\the@epigraph\end{minipage}}%
  \@epipos
  \if@epirhs
    \begin{picture}(0,0)%
      \put(0,-\@epidrop){\makebox(0,0)[r]{\@epitemp}}%
    \end{picture}%
  \else
    \if@epicenter
      \begin{picture}(0,0)%
        \put(0,-\@epidrop){\makebox(0,0)[b]{\@epitemp}}%
      \end{picture}%
    \else
      \begin{picture}(0,0)%
        \put(0,-\@epidrop){\makebox(0,0)[l]{\@epitemp}}%
      \end{picture}%
    \fi
  \fi}

\newcommand*{\@memoldfonterr}[3]{%
  \@memerror{Font command \protect#1\space is not supported}{%
    Use \protect#2, or \protect#3{...}, or the oldfontcommands option}}
\newcommand*{\@memoldfontwarn}[3]{%
  \@memwarn{The \protect#1\space font command is deprecated.
    \MessageBreak Use \protect#2{...} or {\protect#3... } instead}}

\if@memoldfont
  \def\@mem@rmwarn{\@memoldfontwarn{\rm}{\textrm}{\rmfamily}}
  \DeclareOldFontCommand{\rm}{\@mem@rmwarn\gdef\@mem@rmwarn{}%
    \normalfont\rmfamily}{\mathrm}
\else
  \def\rm{\@memoldfonterr{\rm}{\textrm}{\rmfamily}}
\fi

\if@memoldfont
  \def\@mem@sfwarn{\@memoldfontwarn{\sf}{\textsf}{\sffamily}}
  \DeclareOldFontCommand{\sf}{\@mem@sfwarn\gdef\@mem@sfwarn{}%
    \normalfont\sffamily}{\mathsf}
\else
  \def\sf{\@memoldfonterr{\sf}{\textsf}{\sffamily}}
\fi

\if@memoldfont
  \def\@mem@ttwarn{\@memoldfontwarn{\tt}{\texttt}{\ttfamily}}
  \DeclareOldFontCommand{\tt}{\@mem@ttwarn\gdef\@mem@ttwarn{}%
    \normalfont\ttfamily}{\mathtt}
\else
  \def\tt{\@memoldfonterr{\tt}{\texttt}{\ttfamily}}
\fi

\if@memoldfont
  \def\@mem@bfwarn{\@memoldfontwarn{\bf}{\textbf}{\bfseries}}
  \DeclareOldFontCommand{\bf}{\@mem@bfwarn\gdef\@mem@bfwarn{}%
    \normalfont\bfseries}{\mathbf}
\else
  \def\bf{\@memoldfonterr{\bf}{\textbf}{\bfseries}}
\fi

\if@memoldfont
  \def\@mem@itwarn{\@memoldfontwarn{\it}{\textit}{\itshape}}
  \DeclareOldFontCommand{\it}{\@mem@itwarn\gdef\@mem@itwarn{}%
    \normalfont\itshape}{\mathit}
\else
  \def\it{\@memoldfonterr{\it}{\textit}{\itshape}}
\fi

\if@memoldfont
  \def\@mem@slwarn{\@memoldfontwarn{\sl}{\textsl}{\slshape}}
  \DeclareOldFontCommand{\sl}{\@mem@slwarn\gdef\@mem@slwarn{}%
    \normalfont\slshape}{\@nomath\sl}
\else
  \def\sl{\@memoldfonterr{\sl}{\textsl}{\slshape}}
\fi

\if@memoldfont
  \def\@mem@scwarn{\@memoldfontwarn{\sc}{\textsc}{\scshape}}
  \DeclareOldFontCommand{\sc}{\@mem@scwarn\gdef\@mem@scwarn{}%
    \normalfont\scshape}{\@nomath\sc}
\else
  \def\sc{\@memoldfonterr{\sc}{\textsc}{\scshape}}
\fi

\if@memoldfont
  \def\@mem@calwarn{%
    \@memwarn{The \protect\cal\space font command is deprecated.
    \MessageBreak Try to use \protect\mathcal\space instead}}
  \DeclareRobustCommand*\cal{\@mem@calwarn\gdef\@mem@calwarn{}%
    \@fontswitch\relax\mathcal}
\else
  \def\cal{%
    \@memerror{Font command \protect\cal\space is not supported}{%
    Use \protect\mathcal, or the oldfontcommands option}}
\fi

\if@memoldfont
  \def\@mem@mitwarn{%
    \@memwarn{The \protect\mit\space font command is deprecated.
    \MessageBreak Try to use \protect\mathnormal\space instead}}
  \DeclareRobustCommand*\mit{\@mem@mitwarn\gdef\@mem@mitwarn{}%
    \@fontswitch\relax\mathnormal}
\else
  \def\mit{%
  \@memerror{Font command \protect\mit\space is not supported}{%
             Use \protect\mathnormal, or the oldfontcommands option}}
\fi

\DeclareRobustCommand{\em}{%
  \@nomath\em
  \ifdim\fontdimen\@ne\font > \z@
    \eminnershape
  \else
    \itshape
  \fi}
\providecommand{\eminnershape}{\upshape}
\DeclareTextFontCommand{\emph}{\em}

\newcommand*{\fref}[1]{\figurerefname~\ref{#1}}
\newcommand*{\tref}[1]{\tablerefname~\ref{#1}}
\newcommand*{\pref}[1]{\pagerefname~\pageref{#1}}
\newcommand*{\Aref}[1]{\appendixrefname\ref{#1}}
\newcommand*{\Bref}[1]{\bookrefname\ref{#1}}
\newcommand*{\Pref}[1]{\partrefname\ref{#1}}
\newcommand*{\Cref}[1]{\chapterrefname\ref{#1}}
\newcommand*{\Sref}[1]{\sectionrefname\ref{#1}}

\def\NR@nopatch@sectioning{set}
\def\NR@nopatch@caption{set}
\RequirePackage{nameref}
\newcommand\titleref{\nameref}

\def\mem@set@cln{\NR@gettitle}
\newcommand\M@gettitle[1]{\mem@set@cln{#1}}
\newif\ifheadnameref
\newcommand*{\headnameref}{\headnamereftrue}
\newcommand*{\tocnameref}{\headnamereffalse}
  \tocnameref
\providecommand\namerefon{\@memwarn{\protect\namerefon\space no longer does anything}}
\providecommand\namerefoff{\@memwarn{\protect\namerefoff\space no longer does anything}}
\providecommand\currenttitle{%
  \@memerror{The \protect\currenttitle\space command is no longer\MessageBreak
    available}{%
    Place a label and use \protect\titleref{label} instead
  }
}
\providecommand\theTitleReference[2]{%
  \@memwarn{\protect\theTitleReference\space is no longer available}
}
\let\M@TitleReference\@gobbletwo
\newcommand{\@pnumwidth}{1.55em}
\newcommand{\@tocrmarg} {2.55em}
\newcommand{\@dotsep}{4.5}
\newlength{\tocentryskip} \setlength{\tocentryskip}{1em}
\newlength{\tocbaseline}  \setlength{\tocbaseline}{20pt}
\newcommand{\tocskip}[1]{%
    \addtocontents{toc}{\protect\vspace{#1}}}
\newcommand*{\onecoltocetc}{%
  \def\ensureonecol{%
    \if@twocolumn
      \@restonecoltrue\onecolumn
    \else
      \@restonecolfalse
    \fi}%
  \def\restorefromonecol{\if@restonecol\twocolumn\fi}}
\newcommand*{\twocoltocetc}{%
  \def\ensureonecol{%
    \if@twocolumn
      \@restonecoltrue
    \else
      \@restonecolfalse\twocolumn
    \fi}%
  \def\restorefromonecol{\if@restonecol\else\onecolumn\fi}}
\newcommand*{\doccoltocetc}{%
  \let\ensureonecol\relax
  \let\restorefromonecol\relax}
\onecoltocetc

\newlength{\cftparskip}
\setlength{\cftparskip}{0pt}

\newcommand{\newlistof}[3]{%
  \@namedef{ext@#2}{#2}
  \@ifundefined{c@#2depth}{\newcounter{#2depth}}{}
  \setcounter{#2depth}{1}
  \@namedef{#2mark}{\markboth{#3}{#3}}
   \@namedef{#1}{\@ifstar{\@nameuse{mem@#1}{01}}{\@nameuse{mem@#1}{00}}}
  \@namedef{cft#2beforelisthook}{}%
  \@namedef{cft#2afterlisthook}{}%
  \@namedef{mem@#1}##1{%
    \ensureonecol
    \par
    \begingroup
      \phantomsection
      \if##1
        \ifmem@em@starred@listof\else
          \addcontentsline{toc}{chapter}{#3}
        \fi
      \fi
      \@nameuse{@#2maketitle}
      \parskip\cftparskip
      \@nameuse{cft#2beforelisthook}%
      \@starttoc{#2}%
      \@nameuse{cft#2afterlisthook}%
    \endgroup
    \restorefromonecol}
  \@namedef{@#2maketitle}{%
    \@nameuse{#2headstart}
   {\parindent\z@
    \parskip\z@
%%%%  \parskip\cftparskip
    \interlinepenalty\@M
    \@nameuse{print#2nonum}%
    \@nameuse{print#2title}{#3}%
    \@nameuse{#2mark}%
    \thispagestyle{chapter}%
    \@nameuse{after#2title}
   }
    \@afterheading}
  \@namedef{#2headstart}{\chapterheadstart}
  \@namedef{after#2title}{\afterchaptertitle}
  \@namedef{print#2nonum}{\printchapternonum}
  \@namedef{print#2title}##1{\printchaptertitle{##1}}
} % end \newlistof

\newif\ifmem@em@starred@listof
\newcommand\KeepFromToc{\mem@em@starred@listoftrue}
\renewcommand{\@starttoc}[1]{%
  \begingroup\makeatletter
    \@input{\jobname.#1}%
    \if@filesw
      \AtEndDocument{%
        \expandafter\ifx\csname tf@#1\endcsname\relax
          \expandafter\newwrite\csname tf@#1\endcsname
          \immediate\openout \csname tf@#1\endcsname \jobname.#1\relax
        \fi
      }%
    \fi
  \@nobreakfalse
  \endgroup}

\newlistof{tableofcontents}{toc}{\contentsname}
\newcommand*{\setpnumwidth}[1]{\renewcommand{\@pnumwidth}{#1}}
\newcommand*{\setrmarg}[1]{\renewcommand{\@tocrmarg}{#1}}
\providecommand{\cftdot}{.}
\providecommand{\cftdotfill}[1]{%
  \leaders\hbox{$\m@th\mkern #1 mu\hbox{\cftdot}\mkern #1 mu$}\hfill}
\providecommand{\cftdotsep}{4.5}
\newcommand{\cftnodots}{2000}
\newcommand*{\cftparfillskip}{\parfillskip=0pt plus1fil}
\newcommand*{\@cftn@me}{}

\newcommand\mem@cft@hb@xt@[2]{\hb@xt@#1{#2\hfil}}
\let\numberlinebox\mem@cft@hb@xt@
\let\partnumberlinebox\mem@cft@hb@xt@
\let\chapternumberlinebox\mem@cft@hb@xt@
\let\booknumberlinebox\mem@cft@hb@xt@

\newcommand*\numberlinehook[1]{}
\renewcommand*{\numberline}[1]{%
  \numberlinehook{#1}%
  %\hb@xt@\@tempdima{\@cftn@me\@cftbsnum #1\@cftasnum\hfil}\@cftasnumb}
  \numberlinebox\@tempdima{\@cftn@me\@cftbsnum #1\@cftasnum}\@cftasnumb}
\newcommand{\@cftbsnum}{}
\newcommand{\@cftasnum}{}
\newcommand{\@cftasnumb}{}
\newcommand{\newlistentry}[4][\@empty]{%
  \@ifundefined{c@#2}{%    check & set the counter
    \ifx \@empty#1\relax
      \newcounter{#2}
    \else
      \newcounter{#2}[#1]%
      \expandafter\edef\csname the#2\endcsname{%
  \expandafter\noexpand\csname the#1\endcsname.\noexpand\arabic{#2}}
    \fi}{}
  \setcounter{#2}{0}
  \@namedef{l@#2}##1##2{%
    \ifnum \@nameuse{c@#3depth} > #4\relax
      \vskip \@nameuse{cftbefore#2skip}
      {%\leftskip \@nameuse{cft#2indent}\relax
       \newcommand*\cftwhatismyname{#2}%
       \memRTLleftskip \@nameuse{cft#2indent}\relax
%%%       \rightskip \@tocrmarg
       \memRTLrightskip \@tocrmarg
%%%       \parfillskip -\rightskip
       \parfillskip -\memRTLrightskip
       \parindent \@nameuse{cft#2indent}\relax\@afterindenttrue
       \interlinepenalty\@M
       \leavevmode
       \settowidth{\@tempdima}{\@nameuse{cft#2font}{\@nameuse{cft#2name}}}%
       \addtolength{\@tempdima}{\@nameuse{cft#2numwidth}}%
 \expandafter\let\expandafter\@cftbsnum\csname cft#2presnum\endcsname
 \expandafter\let\expandafter\@cftasnum\csname cft#2aftersnum\endcsname
 \expandafter\let\expandafter\@cftasnumb\csname cft#2aftersnumb\endcsname
 \expandafter\let\expandafter\@cftn@me\csname cft#2name\endcsname
%%%       \advance\leftskip\@tempdima \null\nobreak\hskip -\leftskip
       \advance\memRTLleftskip\@tempdima \null\nobreak\hskip -\memRTLleftskip
       {\@nameuse{cft#2font}{##1}}\nobreak
       \@nameuse{cft#2fillnum}{##2}}
    \fi
  }% end of \l@#2

  \expandafter\newlength\csname cftbefore#2skip\endcsname
    \setlength{\@nameuse{cftbefore#2skip}}{\z@ \@plus .2\p@}
  \expandafter\newlength\csname cft#2indent\endcsname
  \expandafter\newlength\csname cft#2numwidth\endcsname
  \ifcase #4\relax  % 0   (level 1)
    \setlength{\@nameuse{cft#2indent}}{0em}
    \setlength{\@nameuse{cft#2numwidth}}{2.3em}
  \or               % 1   (level 2)
    \setlength{\@nameuse{cft#2indent}}{2.3em}
    \setlength{\@nameuse{cft#2numwidth}}{3.2em}
  \or               % 2   (level 3)
    \setlength{\@nameuse{cft#2indent}}{5.5em}
    \setlength{\@nameuse{cft#2numwidth}}{4.1em}
  \or               % 3   (level 4)
    \setlength{\@nameuse{cft#2indent}}{8.5em}
    \setlength{\@nameuse{cft#2numwidth}}{5.0em}
  \else             % anything else
    \setlength{\@nameuse{cft#2indent}}{10.5em}
    \setlength{\@nameuse{cft#2numwidth}}{6.0em}
  \fi
  \@namedef{cft#2font}{\normalfont}
  \@namedef{cft#2name}{}
  \@namedef{cft#2presnum}{}
  \@namedef{cft#2aftersnum}{}
  \@namedef{cft#2aftersnumb}{}
  \@namedef{cft#2dotsep}{\cftdotsep}
  \@namedef{cft#2leader}{\normalfont\cftdotfill{\@nameuse{cft#2dotsep}}}
  \@namedef{cft#2pagefont}{\normalfont}
  \@namedef{cft#2afterpnum}{}
  \@namedef{toclevel@#2}{#4}
  \@namedef{cft#2formatpnumhook}##1{}
  \@namedef{cft#2formatpnum}##1{%
    \@nameuse{cft#2formatpnumhook}{##1}%
    \hb@xt@\@pnumwidth{\hfil\@nameuse{cft#2pagefont}##1}}
  \@namedef{cft#2fillnum}##1{%
    {\@nameuse{cft#2leader}}\nobreak
%%%    \hb@xt@\@pnumwidth{%
%%%      \hfil\@nameuse{cft#2pagefont}##1}
       \@nameuse{cft#2formatpnum}{##1}%
       \@nameuse{cft#2afterpnum}\par}
} % end \newlistentry

\newcommand*{\cftsetindents}[3]{%
  \setlength{\@nameuse{cft#1indent}}{#2}
  \setlength{\@nameuse{cft#1numwidth}}{#3}}

\newcommand*{\cftbookname}{}

\newcommand*{\cftbookbreak}{\addpenalty{-\@highpenalty}%
  \addvspace{\cftbeforebookskip}}
\newcommand*{\l@book}[2]{%
  \ifnum\c@tocdepth >-3\relax
    \cftbookbreak
    \begingroup
      {%\leftskip \cftbookindent\relax
       \memRTLleftskip \cftbookindent\relax
%%%       \rightskip \@tocrmarg
       \memRTLrightskip \@tocrmarg
%%%       \parfillskip -\rightskip
       \parfillskip -\memRTLrightskip
       \parindent \cftbookindent\relax\@afterindenttrue
       \interlinepenalty\@M
       \leavevmode
       \settowidth{\@tempdima}{\cftbookfont\cftbookname}%
       \addtolength{\@tempdima}{\cftbooknumwidth}%
       \let\@cftbsnum \cftbookpresnum
       \let\@cftasnum \cftbookaftersnum
       \let\@cftasnumb \cftbookaftersnumb
%%%       \advance\leftskip \@tempdima \null\nobreak\hskip -\leftskip
       \advance\memRTLleftskip \@tempdima \null\nobreak\hskip -\memRTLleftskip
       {\cftbookfont {#1}}%
       \cftbookfillnum{#2}}
      \nobreak
      \global\@nobreaktrue
      \everypar{\global\@nobreakfalse\everypar{}}%
    \endgroup
  \fi}
\newcommand*\booknumberlinehook[1]{}
\newcommand{\booknumberline}[1]{%
  \booknumberlinehook{#1}%
  % \hb@xt@\@tempdima{%
  %   \cftbookname\@cftbsnum #1\@cftasnum\hfil}\@cftasnumb}%%\space}
  \booknumberlinebox\@tempdima{%
    \cftbookname\@cftbsnum #1\@cftasnum}\@cftasnumb}%%\space}

\newlength{\cftbeforebookskip}
  \setlength{\cftbeforebookskip}{2.25em \@plus\p@}
\newdimen\cftbookindent
  \setlength{\cftbookindent}{0em}
\newdimen\cftbooknumwidth
  \setlength{\cftbooknumwidth}{1.5em}
\newcommand*{\cftbookfont}{\large\bfseries}
\newcommand*{\cftbookpresnum}{}
\newcommand*{\cftbookaftersnum}{}
\newcommand*{\cftbookaftersnumb}{}
\newcommand*{\cftbookleader}{%
  \large\bfseries\cftdotfill{\cftbookdotsep}}
\newcommand*{\cftbookdotsep}{\cftnodots}
\newcommand*{\cftbookpagefont}{\large\bfseries}
\newcommand{\cftbookafterpnum}{}
\newcommand{\cftbookfillnum}[1]{%
  {\cftbookleader}%
%%%%  {\hb@xt@\@pnumwidth{\hss {\cftbookpagefont #1}}}%
  \cftbookformatpnum{#1}%
  \cftbookafterpnum\par}
\newcommand{\cftbookformatpnumhook}[1]{}
\newcommand{\cftbookformatpnum}[1]{%
  \cftbookformatpnumhook{#1}%
  \hb@xt@\@pnumwidth{\hss {\cftbookpagefont #1}}}

\newcommand*{\cftpartname}{}

\newcommand*{\cftpartbreak}{\addpenalty{-\@highpenalty}%
  \addvspace{\cftbeforepartskip}}
\newcommand*{\l@part}[2]{%
  \ifnum \c@tocdepth >-2\relax
    \cftpartbreak
    \begingroup
      {%\leftskip \cftpartindent\relax
       \memRTLleftskip \cftpartindent\relax
%%%       \rightskip \@tocrmarg
       \memRTLrightskip \@tocrmarg
%%%       \parfillskip -\rightskip
       \parfillskip -\memRTLrightskip
       \parindent \cftpartindent\relax\@afterindenttrue
       \interlinepenalty\@M
       \leavevmode
       \settowidth{\@tempdima}{\cftpartfont\cftpartname}%
       \addtolength{\@tempdima}{\cftpartnumwidth}%
       \let\@cftbsnum \cftpartpresnum
       \let\@cftasnum \cftpartaftersnum
       \let\@cftasnumb \cftpartaftersnumb
%%%       \advance\leftskip \@tempdima \null\nobreak\hskip -\leftskip
       \advance\memRTLleftskip \@tempdima \null\nobreak\hskip -\memRTLleftskip
       {\cftpartfont {#1}}%
       \cftpartfillnum{#2}}
      \nobreak
        \global\@nobreaktrue
        \everypar{\global\@nobreakfalse\everypar{}}%
    \endgroup
  \fi}

\def\toclevel@part{-1}

\newcommand*\partnumberlinehook[1]{}
\newcommand{\partnumberline}[1]{%
  \partnumberlinehook{#1}%
  % \hb@xt@\@tempdima{%
  %   \cftpartname\@cftbsnum #1\@cftasnum\hfil}\@cftasnumb}%%\space}
  \partnumberlinebox\@tempdima{%
    \cftpartname\@cftbsnum #1\@cftasnum}\@cftasnumb}%%\space}

  \newlength{\cftbeforepartskip}
    \setlength{\cftbeforepartskip}{2.25em \@plus\p@}
  \newlength{\cftpartindent}
    \setlength{\cftpartindent}{0em}
  \newlength{\cftpartnumwidth}
    \setlength{\cftpartnumwidth}{1.5em}
  \newcommand{\cftpartfont}{\large\bfseries}
  \newcommand{\cftpartpresnum}{}
  \newcommand{\cftpartaftersnum}{}
  \newcommand{\cftpartaftersnumb}{}
  \newcommand{\cftpartleader}{%
              \large\bfseries\cftdotfill{\cftpartdotsep}}
  \newcommand{\cftpartdotsep}{\cftnodots}
  \newcommand{\cftpartpagefont}{\large\bfseries}
  \newcommand{\cftpartafterpnum}{}
  \newcommand{\cftpartformatpnumhook}[1]{}
  \newcommand*{\cftpartformatpnum}[1]{%
    \cftpartformatpnumhook{#1}%
    \hb@xt@\@pnumwidth{\hss {\cftpartpagefont #1}}}
  \newcommand{\cftpartfillnum}[1]{%
    {\cftpartleader}%
    {\cftpartformatpnum{#1}}%
     \cftpartafterpnum\par}

\newcommand*{\cftchaptername}{}

\newcommand*{\l@chapapp}[3]{%
  \ifnum \c@tocdepth >\m@ne
    \cftchapterbreak
    \vskip \cftbeforechapterskip
    {%\leftskip \cftchapterindent\relax
     \memRTLleftskip \cftchapterindent\relax
%%%     \rightskip \@tocrmarg
     \memRTLrightskip \@tocrmarg
%%%     \parfillskip -\rightskip
     \parfillskip -\memRTLrightskip
     \parindent \cftchapterindent\relax
     \@afterindenttrue
     \interlinepenalty\@M
     \leavevmode
     \let\@cftbsnum \cftchapterpresnum
     \let\@cftasnum \cftchapteraftersnum
     \let\@cftasnumb \cftchapteraftersnumb
     \def\@chapapp@head{#3}%
     \settowidth{\@tempdima}{\cftchapterfont\@chapapp@head}%
     \addtolength{\@tempdima}{\cftchapternumwidth}%
%%%     \advance\leftskip \@tempdima \null\nobreak\hskip -\leftskip
     \advance\memRTLleftskip \@tempdima \null\nobreak\hskip -\memRTLleftskip
     {\cftchapterfont {#1}}\nobreak
     \cftchapterfillnum{#2}}
  \fi}

\newcommand*{\l@chapter}[2]{%
  \l@chapapp{#1}{#2}{\cftchaptername}}

\def\toclevel@chapter{0}

\newcommand*{\cftappendixname}{}

\newcommand*{\l@appendix}[2]{%
  \l@chapapp{#1}{#2}{\cftappendixname}}
\def\toclevel@appendix{0}

\newcommand*\chapternumberlinehook[1]{}
\newcommand{\chapternumberline}[1]{%
  \chapternumberlinehook{#1}%
  % \hb@xt@\@tempdima{\@chapapp@head\@cftbsnum #1\@cftasnum\hfil}%
  % \@cftasnumb}
  \chapternumberlinebox\@tempdima{\@chapapp@head\@cftbsnum #1\@cftasnum}%
  \@cftasnumb}

  \newlength{\cftbeforechapterskip}
    \setlength{\cftbeforechapterskip}{1.0em \@plus\p@}
  \newlength{\cftchapterindent}
    \setlength{\cftchapterindent}{0em}
  \newlength{\cftchapternumwidth}
    \setlength{\cftchapternumwidth}{1.5em}
  \newcommand{\cftchapterfont}{\bfseries}
  \newcommand{\cftchapterpresnum}{}
  \newcommand{\cftchapteraftersnum}{}
  \newcommand{\cftchapteraftersnumb}{}
  \newcommand{\cftchapterleader}{%
              \bfseries\cftdotfill{\cftchapterdotsep}}
  \newcommand{\cftchapterdotsep}{\cftnodots}
  \newcommand{\cftchapterpagefont}{\bfseries}
  \newcommand{\cftchapterafterpnum}{}
  \newcommand{\cftchapterformatpnumhook}[1]{}
  \newcommand*{\cftchapterformatpnum}[1]{%
    \cftchapterformatpnumhook{#1}%
    \hb@xt@\@pnumwidth{\hfil\cftchapterpagefont #1}}
  \newcommand*{\cftchapterfillnum}[1]{%
    {\cftchapterleader}\nobreak
    \cftchapterformatpnum{#1}%
    \cftchapterafterpnum\par}
  \newcommand{\cftchapterbreak}{\addpenalty{-\@highpenalty}}

\newlistentry[chapter]{section}{toc}{0}
  \cftsetindents{section}{1.5em}{2.3em}
\newlistentry[section]{subsection}{toc}{1}
  \cftsetindents{subsection}{3.8em}{3.2em}
\newlistentry[subsection]{subsubsection}{toc}{2}
  \cftsetindents{subsubsection}{7.0em}{4.1em}
\newlistentry[subsubsection]{paragraph}{toc}{3}
  \cftsetindents{paragraph}{10.0em}{5.0em}
\newlistentry[paragraph]{subparagraph}{toc}{4}
  \cftsetindents{subparagraph}{12.0em}{6.0em}

\newcommand*{\@cftl@subfigtab}{
\newlistentry[figure]{subfigure}{lof}{1}
  \cftsetindents{subfigure}{2.3em}{2.5em}
\newlistentry[table]{subtable}{lot}{1}
  \cftsetindents{subtable}{2.3em}{2.5em}}
\renewcommand*{\@cftl@subfigtab}{}

\AtBeginDocument{\@ifpackageloaded{subfigure}{\@cftl@subfigtab}{}}

\DeclareRobustCommand{\cftpagenumbersoff}[1]{%
  \@namedef{cft#1fillnum}##1{%
    \cftparfillskip\@nameuse{cft#1afterpnum}\par}}

\DeclareRobustCommand{\cftpagenumberson}[1]{%
  \@namedef{cft#1fillnum}##1{%
    \@nameuse{cft#1leader}\nobreak
    \@nameuse{cft#1formatpnum}{##1}%
    \@nameuse{cft#1afterpnum}\par}}

\newcommand{\chapterprecis}[1]{%
  \chapterprecishere{#1}
  \chapterprecistoc{#1}}
\newcommand{\chapterprecishere}[1]{%
  \prechapterprecis #1\postchapterprecis}
\newdimen\prechapterprecisshift
\ifartopt
  \prechapterprecisshift=0pt
\else
  \prechapterprecisshift=-2\baselineskip
\fi
\newcommand*{\precisfont}{\normalfont\itshape}
\newcommand{\prechapterprecis}{%
  \vspace*{\prechapterprecisshift}%
  \begin{quote}\precisfont}
\newcommand*{\postchapterprecis}{%
  \end{quote}%
  \par\m@mindentafterchapter%
  \@afterheading}

\newcommand{\precistocfont}{\normalfont\itshape}
\newcommand{\precistocformat}{\noindent}
\newcommand{\chapterprecistoc}[1]{%
  \addtocontents{toc}{\precistoctext{#1}}}
\DeclareRobustCommand{\precistoctext}[1]{%
  {%\nopagebreak\leftskip \cftchapterindent\relax
   \nopagebreak\memRTLleftskip \cftchapterindent\relax
%%%   \advance\leftskip \cftchapternumwidth\relax
   \advance\memRTLleftskip \cftchapternumwidth\relax
%%%   \rightskip \@tocrmarg\relax
   \memRTLrightskip \@tocrmarg\relax
   \precistocformat\precistocfont #1\par}}
\newcommand{\cftlocalchange}[3]{%
  \addtocontents{#1}{\protect\setpnumwidth{#2} \protect\setrmarg{#3}}}
\newcommand{\cftaddtitleline}[4]{%
  \addtocontents{#1}{\protect\contentsline{#2}{#3}{#4}}}
\newcommand{\cftaddnumtitleline}[5]{%
  \addtocontents{#1}%
    {\protect\contentsline{#2}{\protect\numberline{#3}%
                              {\protect\ignorespaces #4}}{#5}}}
\newcommand*{\cftinsert}[1]{\@nameuse{cftinsert#1}}
\newcommand{\cftinsertcode}[2]{\@namedef{cftinsert#1}{#2}}
\newcommand*{\cftinserthook}[2]{%
  \addtocontents{#1}{\protect\cftinsert\protect{#2\protect}}}

\newcommand*{\@setclcnt}[2]{%
  \def\@setclcntok{0}% = false
  \nametest{#1}{none}%
  \ifsamename
    \setcounter{#2}{-10}%
    \def\@setclcntok{1}% = true
  \fi
  \nametest{#1}{book}%
  \ifsamename
    \setcounter{#2}{-2}%
    \def\@setclcntok{1}%
  \fi
  \nametest{#1}{part}%
  \ifsamename
    \setcounter{#2}{-1}%
    \def\@setclcntok{1}%
  \fi
  \nametest{#1}{chapter}%
  \ifsamename
    \setcounter{#2}{0}%
    \def\@setclcntok{1}%
  \fi
  \nametest{#1}{section}%
  \ifsamename
    \setcounter{#2}{1}%
    \def\@setclcntok{1}%
  \fi
  \nametest{#1}{subsection}%
  \ifsamename
    \setcounter{#2}{2}%
    \def\@setclcntok{1}%
  \fi
  \nametest{#1}{subsubsection}%
  \ifsamename
    \setcounter{#2}{3}%
    \def\@setclcntok{1}%
  \fi
  \nametest{#1}{paragraph}%
  \ifsamename
    \setcounter{#2}{4}%
    \def\@setclcntok{1}%
  \fi
  \nametest{#1}{subparagraph}%
  \ifsamename
    \setcounter{#2}{5}%
    \def\@setclcntok{1}%
  \fi
  \nametest{#1}{all}%
  \ifsamename
    \setcounter{#2}{50}%
    \def\@setclcntok{1}%
  \fi
%%  \if@tempswa\else
    \ifnum \@setclcntok = 0\relax
    \@memerror{%
      Unknown document division name (#1)
    }{%
     I'll ignore it.
     Type \space <return> and I'll continue.\MessageBreak
     If you haven't mistyped the name then use
     \protect\setcounter\space instead.}%
  \fi}

\newcommand*{\settocdepth}[1]{%
  \def\@chtodok{0}%   false
  \nametest{#1}{none}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{-10}}%
    \def\@chtodok{1}%   true
  \fi
  \nametest{#1}{book}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{-2}}%
    \def\@chtodok{1}%
  \fi
  \nametest{#1}{part}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{-1}}%
    \def\@chtocdok{1}%
  \fi
  \nametest{#1}{chapter}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{0}}%
    \def\@chtocdok{1}%
  \fi
  \nametest{#1}{section}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{1}}%
    \def\@chtocdok{1}%
  \fi
  \nametest{#1}{subsection}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{2}}%
    \def\@chtocdok{1}%
  \fi
  \nametest{#1}{subsubsection}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{3}}%
    \def\@chtocdok{1}%
  \fi
  \nametest{#1}{paragraph}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{4}}%
    \def\@chtocdok{1}%
  \fi
  \nametest{#1}{subparagraph}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{5}}%
    \def\@chtocdok{1}%
  \fi
  \nametest{#1}{all}%
  \ifsamename
    \addtocontents{toc}{\changetocdepth{50}}%
    \def\@chtocdok{1}%
  \fi
  \ifnum\@chtocdok=1\relax
    \@ifundefined{toclevel@#1}{%
      \@memwarn{Unknown toclevel for #1}%
    }{%
      \setcounter{tocdepth}{\@nameuse{toclevel@#1}}%
    }
  \else
    \@memerror{%
      Unknown document division name (#1)
    }{%
     I'll ignore it.
     Type \space <return> and I'll continue.}%
  \fi}

\def\toclevel@none{-10}
\def\toclevel@all{50}

\DeclareRobustCommand{\changetocdepth}[1]{\setcounter{tocdepth}{#1}}

\newcommand{\maxtocdepth}[1]{%
  \@setclcnt{#1}{tocdepth}}
\newcounter{maxsecnumdepth}
\newcommand{\maxsecnumdepth}[1]{%
  \@setclcnt{#1}{secnumdepth}\@setclcnt{#1}{maxsecnumdepth}}

\newcommand{\setsecnumdepth}[1]{%
  \ifx\@nodocument\relax%      after the preamble
    \@setclcnt{#1}{secnumdepth}%
  \else
    \@setclcnt{#1}{secnumdepth}%
    \@setclcnt{#1}{maxsecnumdepth}%
  \fi}
\setsecnumdepth{section}

\newdimen\bibindent
  \setlength\bibindent{1.5em}
\newlength{\bibitemsep}
  \setlength{\bibitemsep}{\itemsep}
\newcommand{\biblistextra}{\itemsep=\bibitemsep}

\newenvironment{bibitemlist}[1]{%
  \typeout{bibitemlist}
  \list{\@biblabel{\@arabic\c@enumiv}}%
       {\settowidth\labelwidth{\@biblabel{#1}}%
        \leftmargin\labelwidth
        \advance\leftmargin\labelsep
        \@openbib@code
        \usecounter{enumiv}%
        \let\p@enumiv\@empty
        \renewcommand\theenumiv{\@arabic\c@enumiv}%
        \biblistextra}%
  \sloppy
  \clubpenalty4000
  \@clubpenalty \clubpenalty
  \widowpenalty4000%
  \sfcode`\.\@m}%
  {\def\@noitemerr
    {\@latex@warning{Empty `thebibliography' environment}}%
    \endlist}

\newcommand{\newblock}{\hskip .11em\@plus.33em\@minus.07em}
\let\@openbib@code\@empty
\newcommand*{\setbiblabel}[1]{%
  \renewcommand*{\@biblabel}[1]{#1}}
\setbiblabel{[#1]\hfill}
\newcommand{\@memb@bchap}{%
  \chapter*{\bibname}%
  \bibmark
  \ifnobibintoc\else
    % \phantomsection
    \addcontentsline{toc}{chapter}{\bibname}%
  \fi
  \prebibhook}
\newcommand{\@memb@bsec}{\section{\bibname}\prebibhook}
\newcommand{\bibsection}{\@memb@bchap}

\newenvironment{thebibliography}[1]{%
  \bibsection
  \begin{bibitemlist}{#1}}{\end{bibitemlist}\postbibhook}
\newif\ifnobibintoc
\newcommand*{\bibintoc}{\nobibintocfalse}
\newcommand*{\nobibintoc}{\nobibintoctrue}
\bibintoc

\newcommand{\prebibhook}{}
\newcommand{\postbibhook}{}

\AtBeginDocument{%
  \@ifpackageloaded{natbib}{% natbib is loaded
    \addtodef{\endthebibliography}{}{\vskip-\lastskip\postbibhook}
    \@ifpackagewith{natbib}{sectionbib}{% with sectionbib option
      \renewcommand{\bibsection}{\@memb@bsec}}%
      {\renewcommand{\bibsection}{\@memb@bchap}}}%
  {}
  \@ifpackagewith{chapterbib}{sectionbib}{%
    \renewcommand{\sectionbib}[2]{}
    \renewcommand{\bibsection}{\@memb@bsec}}{}
}

\newif\ifonecolindex
  \onecolindexfalse

\newcommand*{\onecolindex}{\onecolindextrue}
\newcommand*{\twocolindex}{\onecolindexfalse}

\newenvironment{theindex}{%
  \clearforchapter
  \if@twocolumn
    \@restonecolfalse
  \else
    \@restonecoltrue
  \fi
  \ifonecolindex
    \onecolumn
    \chapter*{\indexname}
    \preindexhook
  \else
    \setlength{\columnseprule}{\indexrule}%
    \setlength{\columnsep}{\indexcolsep}%
    \twocolumn[\@makeschapterhead{\indexname}
               \preindexhook]%
  \fi
  \indexmark
  \ifnoindexintoc\else
    \phantomsection
    \addcontentsline{toc}{chapter}{\indexname}%
  \fi
  \thispagestyle{indextitlepagestyle}\parindent\z@
  \parskip\z@ \@plus .3\p@\relax
  \let\item\@idxitem}%
  {\if@restonecol\onecolumn\else\twocolumn\fi}

\aliaspagestyle{indextitlepagestyle}{chapter}

\newif\ifnoindexintoc
\newcommand*{\indexintoc}{\noindexintocfalse}
\newcommand*{\noindexintoc}{\noindexintoctrue}
\indexintoc

\newlength{\indexcolsep} \setlength{\indexcolsep}{35pt}
\newlength{\indexrule}   \setlength{\indexrule}{0pt}

\newcommand{\preindexhook}{}
\newcommand{\l@index}{\@dottedtocline{1}{0em}{0pt}}
\newcommand{\@idxitem}  {\par\hangindent 40\p@}
\newcommand{\subitem}   {\par\hangindent 40\p@ \hspace*{20\p@}}
\newcommand{\subsubitem}{\par\hangindent 40\p@ \hspace*{30\p@}}
\newcommand{\indexspace}{\par \vskip 10\p@ \@plus5\p@ \@minus3\p@\relax}

\newcommand*{\makememindexhook}{}
\providecommand*{\makeindex}{}
\renewcommand*{\makeindex}[1][\jobname]{%
  \if@filesw
    \def\index{\@bsphack%
      \@ifnextchar [{\@index}{\@index[\jobname]}}
    \def\specialindex{\@bsphack\@spindex}%
    \makememindexhook
    \expandafter\newwrite\csname #1@idxfile\endcsname
    \expandafter\immediate\openout \csname #1@idxfile\endcsname #1.idx\relax
    \typeout{Writing index file #1.idx }%
  \fi}

\renewcommand{\index}[2][\jobname]{\@bsphack\@esphack}
\newcommand{\specialindex}[3]{\@bsphack\@esphack}

\newcommand{\printindex}[1][\jobname]{\@input@{#1.ind}}

\newif\ifreportnoidxfile
\newcommand*{\reportnoidxfile}{\reportnoidxfiletrue}
\newcommand*{\ignorenoidxfile}{\reportnoidxfilefalse}
  \ignorenoidxfile
\newif\ifshowindexmark
\newcommand*{\showindexmarks}{\showindexmarktrue}
\newcommand*{\hideindexmarks}{\showindexmarkfalse}
  \hideindexmarks

\def\@index[#1]{%
  \@ifundefined{#1@idxfile}%
  {\ifreportnoidxfile
     \@memwarn{Undefined index file #1}%
    \fi
    \begingroup
    \@sanitize
    \@nowrindex}%
  {\def\@idxfile{#1}%
   \begingroup
   \@sanitize
   \@wrindexm@m}}
\newcommand{\@nowrindex}[1]{%
  \ifshowindexmark\@showidx{#1}\fi\endgroup\@esphack}

\newcommand{\@wrindexm@m}[1]{\@@wrindexhyp#1||\\}
\def\@@wrindexhyp#1|#2|#3\\{%
  \ifshowindexmark\@showidx{#1}\fi
  \ifx\\#2\\%
    \protected@write\@auxout{}%
      {\string\@@wrindexm@m{\@idxfile}{#1|hyperpage}{\thepage}}%
  \else
    \def\Hy@temp@A{#2}%
    \ifx\Hy@temp@A\HyInd@ParenLeft
      \protected@write\@auxout{}%
        {\string\@@wrindexm@m{\@idxfile}{#1|#2hyperpage}{\thepage}}%
    \else
      \ifx\Hy@temp@A\HyInd@ParenRight
        \protected@write\@auxout{}%
          {\string\@@wrindexm@m{\@idxfile}{#1|#2hyperpage}{\thepage}}%
      \else
        \protected@write\@auxout{}%
          {\string\@@wrindexm@m{\@idxfile}{#1|#2}{\thepage}}%
      \fi
    \fi
  \fi
  \endgroup
  \@esphack}
\newcommand{\hyperpage}[1]{#1}
\newcommand{\hyperlink}[2]{#2}

\newcommand{\@@wrindexm@m}[1]{\begingroup
  \def\@idxfile{\@nameuse{#1@idxfile}}
  \@sanitize
  \@@@wrindexm@m}

\newcommand{\@@@wrindexm@m}[2]{\endgroup}
\AtBeginDocument{%
  \def\@@@wrindexm@m#1#2{%
    \if@filesw
      %\immediate\write \@idxfile{\string\indexentry{#1}{#2}}%
      \immediate@protected@write\@idxfile{}{\string\indexentry{#1}{#2}}%
    \fi
    \endgroup}%
}
\newcommand{\@spindex}[2]{%
  \@ifundefined{#1@idxfile}%
  {\ifreportnoidxfile
     \@memwarn{Undefined index file #1}%
    \fi
    \begingroup
    \@sanitize
    \@nowrindex}%
  {\def\@idxfile{#1}%
   \def\@sptheidx{#2}%
   \begingroup
   \@sanitize
   \@wrspindex}}

\newcommand{\@wrspindex}[1]{\@@wrspindexhyp#1||\\}
\def\@@wrspindexhyp#1|#2|#3\\{%
  \ifshowindexmark\@showidx{#1}\fi
  \ifx\\#2\\%
    \protected@write\@auxout{}%
      {\string\@@wrindexm@m{\@idxfile}%
        {#1|hyperspindexpage(\thepage)}%
      {\@nameuse{the\@sptheidx}}}%
  \else
    \def\Hy@temp@A{#2}%
    \ifx\Hy@temp@A\HyInd@ParenLeft
      \protected@write\@auxout{}%
        {\string\@@wrindexm@m{\@idxfile}%
         {#1|#2hyperspindexpage(\thepage)}%
         {\@nameuse{the\@sptheidx}}}%
    \else
      \protected@write\@auxout{}%
        {\string\@@wrindexm@m{\@idxfile}{#1|#2}%
        {\@nameuse{the\@sptheidx}}}%
    \fi
  \fi
  \endgroup
  \@esphack}
\def\hyperspindexpage(#1)#2{\hyperlink{page.#1}{#2}}

\newif\ifmemhyperindex
  \memhyperindextrue

\newif\ifm@mxindy
\m@mxindyfalse
\newcommand*{\xindyindex}{\m@mxindytrue}
\def\@@wrspindexhyp#1|#2|#3\\{%
  \ifshowindexmark\@showidx{#1}\fi
  \ifx\\#2\\%
    \protected@write\@auxout{}%
      {\string\@@wrindexm@m{\@idxfile}%
        \ifm@mxindy{#1}\else{#1|hyperspindexpage(\thepage)}\fi
      {\@nameuse{the\@sptheidx}}}%
  \else
    \def\Hy@temp@A{#2}%
    \ifx\Hy@temp@A\HyInd@ParenLeft
      \protected@write\@auxout{}%
        {\string\@@wrindexm@m{\@idxfile}%
         \ifm@mxindy{#1|#2}\else{#1|#2hyperspindexpage(\thepage)}\fi
      {\@nameuse{the\@sptheidx}}}%
    \else
      \protected@write\@auxout{}%
        {\string\@@wrindexm@m{\@idxfile}{#1|#2}%
      {\@nameuse{the\@sptheidx}}}%
    \fi
  \fi
  \endgroup
  \@esphack}

\AtBeginDocument{%
  \@ifpackageloaded{hyperref}{}{\memhyperindexfalse}%
  \ifmemhyperindex\else
    \def\@@wrindexhyp#1||\\{%
      \ifshowindexmark\@showidx{#1}\fi
      \protected@write\@auxout{}%
        {\string\@@wrindexm@m{\@idxfile}{#1}{\thepage}}%
      \endgroup
      \@esphack}%
    \def\@@wrspindexhyp#1||\\{%
      \ifshowindexmark\@showidx{#1}\fi
      \protected@write\@auxout{}%
        {\string\@@wrindexm@m{\@idxfile}{#1}{\@nameuse{the\@sptheidx}}}%
      \endgroup
      \@esphack}%
  \fi
}

\newcommand*{\see}[2]{\emph{\seename} #1}
\newcommand*{\seename}{see}
\newcommand*{\seealso}[2]{\emph{\alsoname} #1}
\newcommand*{\alsoname}{see also}

\newcommand{\citeindexfile}{\jobname}
\AtBeginDocument{\@ifpackageloaded{natbib}{%
  \def\NAT@index{\index[\citeindexfile]{\NAT@idxtxt}}}{}}

\newtoks\indexmarkstyle
  \indexmarkstyle{\normalfont\footnotesize\ttfamily}
\newinsert\@indexbox
  \dimen\@indexbox\maxdimen

\begingroup
  \catcode`\@\active
  \expandafter\gdef\csname\string @sanitizeat\endcsname
  {\def @{\char`\@}}
\endgroup

\newcommand{\@showidx}[1]{%
  \insert\@indexbox{%
    \@sanitizeat
    \the\indexmarkstyle
    \hsize\marginparwidth
    \hangindent\marginparsep \parindent\z@
    \everypar{}\let\par\@@par \parfillskip\@flushglue
    \lineskip\normallineskip
    \baselineskip .8\normalbaselineskip\sloppy
    \raggedright \leavevmode
    \vrule \@height .7\normalbaselineskip \@width \z@\relax
      #1\relax
    \vrule \@height \z@ \@depth .3\normalbaselineskip \@width \z@\relax
  }%
  \ifhmode\penalty\@M \hskip\z@skip\fi}

\newcommand{\@leftidx}{\hskip-\marginparsep \hskip-\marginparwidth}
\newcommand{\@rightidx}{\hskip\columnwidth \hskip\marginparsep}

\newcommand{\@mkidx}{\vbox to \z@{%
  \rlap{%
    \if@twocolumn
      \if@firstcolumn \@leftidx \else \@rightidx \fi
    \else
      \if@twoside
        \ifodd\c@page \@rightidx \else \@leftidx \fi
      \else
        \@rightidx
      \fi
    \fi
    \box\@indexbox
  }%
  \vss}}

\DeclareRobustCommand{\raggedbottom}{%
  \def\mem@flshbot{01}%
  \def\@textbottom{\vskip\z@ plus.0001fil}%
  \let\@texttop\@mkidx}
\DeclareRobustCommand{\flushbottom}{%
  \def\mem@flshbot{00}%
  \let\@textbottom\relax
  \let\@texttop\@mkidx}
\let\@texttop\@mkidx
\flushbottom

\newcommand*{\sloppybottom}{%
  \def\mem@flshbot{01}%
  \def\@textbottom{\vskip \z@ \@plus.0001fil \@minus .95\topskip}%
  \topskip=1\topskip \@plus 0.625\topskip \@minus .95\topskip
  \def\@texttop{\vskip \z@ \@plus -0.625\topskip \@minus -0.95\topskip}}

\newif\ifonecolglossary
  \onecolglossarytrue
\newcommand*{\onecolglossary}{\onecolglossarytrue}
\newcommand*{\twocolglossary}{\onecolglossaryfalse}

\newenvironment{theglossary}{%
  \if@twocolumn
    \@restonecolfalse
  \else
    \@restonecoltrue
  \fi
  \ifonecolglossary
    \onecolumn
    \chapter*{\glossaryname}
    \preglossaryhook
  \else
    \setlength{\columnseprule}{\glossaryrule}
    \setlength{\columnsep}{\glossarycolsep}
    \twocolumn[\@makeschapterhead{\glossaryname}
               \preglossaryhook]%
  \fi
  \glossarymark
  \ifnoglossaryintoc\else
    \phantomsection
    \addcontentsline{toc}{chapter}{\glossaryname}
  \fi
  \thispagestyle{chapter}\parindent\z@
  \parskip\z@ \@plus .3\p@\relax
  \begintheglossaryhook}%
  {\atendtheglossaryhook\if@restonecol\onecolumn\else\twocolumn\fi}

\newcommand*{\begintheglossaryhook}{}
\newcommand*{\atendtheglossaryhook}{}
\newcommand*{\preglossaryhook}{}

\newif\ifnoglossaryintoc
\newcommand*{\glossaryintoc}{\noglossaryintocfalse}
\newcommand*{\noglossaryintoc}{\noglossaryintoctrue}
  \glossaryintoc

\newdimen\glossarycolsep \glossarycolsep=35\p@
\newdimen\glossaryrule \glossaryrule=0\p@
\newcommand*{\glossaryspace}{%
    \par \vskip 1.0\onelineskip \@plus 5\p@ \@minus3\p@\relax}

\providecommand*{\makeglossary}{}
\renewcommand*{\makeglossary}[1][\jobname]{%
  \makememglossaryhook
  \@namedef{memglsact#1}{@}%           actual
  \@namedef{memglsnx#1}{}%             no ref
  \@namedef{memglsn#1}{\thepage}%      num  by page
  \@namedef{memglsnf#1}{|memjustarg}%  no special number format | emacs
  \if@filesw \expandafter\newwrite\csname #1memglofile\endcsname
    \expandafter\immediate\openout \csname #1memglofile\endcsname #1.glo\relax
    \typeout{Writing glossary file #1.glo }%
  \fi}

\newcommand*{\makememglossaryhook}{}

  \def\glossary{\@bsphack%
    \@ifnextchar [{\@glossary}{\@glossary[\jobname]}}%
\def\@glossary[#1]{%
  \@ifnextchar ({\@@glossary[#1]}{\@@glossary[#1]()}}
\def\@@glossary[#1](#2)#3#4{%
  \@ifundefined{#1memglofile}{%
    \begingroup
    \@sanitize
    \endgroup
    \@esphack%
   }{%
    \def\memglofile{#1}%
    \begingroup
    \@sanitize
    \ifx\@empty#2\@empty
      \@wrglom@m{#3}{#3}{#4}%
    \else
      \@wrglom@m{#2}{#3}{#4}%
    \fi}}

\newcommand{\@wrglom@m}[3]{%
  \protected@write\@auxout{}%
    {\string\@@wrglom@m{\memglofile}{#1}{#2}{#3}{\@nameuse{memglsnx\memglofile}}{\@nameuse{memglsn\memglofile}}}%
  \endgroup
  \@esphack}

\newcommand{\@@wrglom@m}[1]{\begingroup
  \def\memglofile{\@nameuse{#1memglofile}}%
  \def\m@mgf{#1}%
  \@sanitize
  \memwritetoglo}

\newcommand{\memwritetoglo}[5]{\endgroup}
\newcommand{\@ctualm@mwritetoglo}[5]{%
  %\immediate\write \memglofile%
  \immediate@protected@write\memglofile{}%
        {\string\glossaryentry{#1\@nameuse{memglsact\m@mgf}
        {\string\memgloterm{#2}}{\string\memglodesc{#3}}
        {\string\memgloref{#4}}\@nameuse{memglsnf\m@mgf}}{#5}}%
  \endgroup}
\AtBeginDocument{%
  \let\memwritetoglo\@ctualm@mwritetoglo}

\newcommand*{\changeglossactual}[2][\jobname]{%
  \@namedef{memglsact#1}{#2}}
\newcommand*{\changeglossref}[2][\jobname]{%
  \@namedef{memglsnx#1}{#2}}
\newcommand*{\changeglossnum}[2][\jobname]{%
  \@namedef{memglsn#1}{#2}}
\newcommand*{\changeglossnumformat}[2][\jobname]{%
  \@namedef{memglsnf#1}{#2}}

\newcommand{\glossitem}[4]{#1 #2 #3 #4\par}

\newcommand*{\memgloterm}[1]{#1}
\newcommand*{\memglodesc}[1]{#1}
\newcommand*{\memgloref}[1]{#1}
\newcommand*{\memglonum}[1]{#1}

\newcommand*{\printglossary}[1][\jobname]{\@input@{#1.gls}}

\newcommand*{\m@msetm@argin}[1]{%
  \def\@tempa{#1}\def\@tempb{left}%
  \ifx\@tempa\@tempb
    \def\m@mm@argin{0}%
  \else
    \def\@tempb{right}%
    \ifx\@tempa\@tempb
      \def\m@mm@argin{1}%
    \else
      \def\@tempb{outer}%
      \ifx\@tempa\@tempb
        \def\m@mm@argin{2}%
      \else
        \def\@tempb{inner}%
        \ifx\@tempa\@tempb
          \def\m@mm@argin{3}%
        \else
          \def\m@mm@argin{-1}%
        \fi
      \fi
    \fi
  \fi}

\newif\ifmemtortm
  \memtortmtrue
\newcommand*{\m@mwhich@margin}[1]{%
  \memtortmtrue
  \if@twocolumn
    \if@firstcolumn% left
      \memtortmfalse
    \else%           right
      \memtortmtrue
    \fi
  \else
    \if@twoside
      \checkoddpage
      \ifcase #1\relax% 0 left
        \memtortmfalse
      \or%                   1 right
        \memtortmtrue
      \or%                   2 outer
        \ifoddpage
          \memtortmtrue
        \else
          \memtortmfalse
        \fi
      \or%                 3 inner
        \ifoddpage
          \memtortmfalse
        \else
          \memtortmtrue
        \fi
      \fi% end ifcase
    \else%           oneside
      \ifnum #1=\z@% 0   left, all else right
        \memtortmfalse
      \else
        \memtortmtrue
      \fi
    \fi% end if@twoside
  \fi}

\def\@addmarginpar{%
    \checkoddpage
    \@next\@marbox\@currlist{\@cons\@freelist\@marbox
    \@cons\@freelist\@currbox}\@latexbug\@tempcnta\@ne
    \if@twocolumn
        \if@firstcolumn \@tempcnta\m@ne \fi
    \else
      \ifm@msetmp%
        % \@tempcnta > 0 => right side of page
        % \@tempcnta < 0 => left side of page
        \m@mwhich@margin{\m@mmpar@margin}% set left or right margin
        \ifmemtortm%
          \@tempcnta\@ne\relax%
         \else%
          \@tempcnta\m@ne\relax%
        \fi%
      \else%
        \if@mparswitch
          \ifoddpage \else \@tempcnta\m@ne \fi%
        \fi%
        \if@reversemargin \@tempcnta -\@tempcnta \fi%
      \fi%
    \fi%
    \ifnum\@tempcnta <\z@  \global\setbox\@marbox\box\@currbox \fi
    \@tempdima\@mparbottom
    \advance\@tempdima -\@pageht
    \advance\@tempdima\ht\@marbox
    \ifdim\@tempdima >\z@
      \@latex@warning@no@line {Marginpar on page
                               \thepage\space moved by \the\@tempdima}%
    \else
      \@tempdima\z@
    \fi
    \global\@mparbottom\@pageht
    \global\advance\@mparbottom\@tempdima
    \global\advance\@mparbottom\dp\@marbox
    \global\advance\@mparbottom\marginparpush
    \advance\@tempdima -\ht\@marbox
    \global\setbox \@marbox
                   \vbox {\vskip \@tempdima
                          \box \@marbox}%
    \global \ht\@marbox \z@
    \global \dp\@marbox \z@
    \kern -\@pagedp
    \nointerlineskip
    \hb@xt@\columnwidth
      {\ifnum \@tempcnta >\z@
          \hskip\columnwidth \hskip\marginparsep
       \else
          \hskip -\marginparsep \hskip -\marginparwidth
       \fi
       \box\@marbox \hss}%
    \nointerlineskip
    \hbox{\vrule \@height\z@ \@width\z@ \@depth\@pagedp}%
}

\newif\ifm@msetmp
  \m@msetmpfalse
\newcommand*{\marginparmargin}[1]{%
  \m@msetmptrue
  \m@msetm@argin{#1}%
  \ifnum\m@mm@argin<\z@
    \@memwarn{Bad \string\marginparmargin\space argument `#1'\MessageBreak
              set to `outer'}%
    \gdef\m@mmpar@margin{2}%   set as outer
  \else
    \global\let\m@mmpar@margin\m@mm@argin
  \fi
  \setmpbools}

\if@twocolumn\else
  \if@twoside
    \def\m@mmpar@margin{2}
  \else
    \def\m@mmpar@margin{1}
  \fi
\fi

\newcommand*{\setmpbools}{%
  \if@twoside
    \@mparswitchtrue
  \else
    \@mparswitchfalse
  \fi
  \ifcase\m@mmpar@margin\relax% 0 left
    \@reversemargintrue%  \sideparswitchfalse \reversesidepartrue
  \or%                    1 right
    \@reversemarginfalse% \sideparswitchfalse \reversesideparfalse
  \or%                    2 outer
    \@reversemarginfalse% \sideparswitchtrue \reversesideparfalse
  \or%                    3 inner
    \@reversemargintrue% \sideparswitchtrue \reversesidepartrue
  \fi}

\newcommand*{\m@msetmpcodes}{%
  \if@mparswitch%  2 sided
    \if@reversemargin% inner
      \def\m@mmpar@margin{3}%
    \else% outer
      \def\m@mmpar@margin{2}%
    \fi
  \else% 1 sided
    \if@reversemargin% left
      \def\m@mmpar@margin{0}%
    \else% right
      \def\m@mmpar@margin{1}%
    \fi
  \fi}

\newcommand*{\parnopar}{{\parfillskip=0pt\par\parskip=0pt\noindent}}

\newif\ifreversesidepar
  \reversesidepartrue
\newif\ifsideparswitch
  \sideparswitchfalse
\if@twoside \sideparswitchtrue \fi

%% true if \sideparmargin used
\newif\ifm@msetsp
  \m@msetspfalse
\newcommand*{\sideparmargin}[1]{%
  \m@msetsptrue
  \m@msetm@argin{#1}%
  \ifnum\m@mm@argin<\z@
    \@memwarn{Bad \string\sideparmargin\space argument `#1'\MessageBreak
              set to `outer'}%
    \gdef\m@mspar@margin{2}%   set as outer
  \else
    \global\let\m@mspar@margin\m@mm@argin
  \fi}

\newcommand*{\m@msidepar@left}{%
  \@tempdimc\marginparwidth
  \advance\@tempdimc\marginparsep
  \kern-\@tempdimc}
\newcommand*{\m@msidepar@right}{%
  \@tempdimc\columnwidth
  \advance\@tempdimc\marginparsep
  \kern\@tempdimc}

\newcommand*{\setspbools}{%
    \ifcase\m@mspar@margin\relax% 0 left
      \sideparswitchfalse \reversesidepartrue
    \or%                    1 right
      \sideparswitchfalse \reversesideparfalse
    \or%                    2 outer
      \sideparswitchtrue \reversesideparfalse
    \or%                    3 inner
      \sideparswitchtrue \reversesidepartrue
    \fi}

\newcommand*{\setspcode}{%
  \ifsideparswitch
    \ifreversesidepar
      \def\m@mspar@margin{3}% inner
    \else
      \def\m@mspar@margin{2}% outer
    \fi
  \else
    \ifreversesidepar
      \def\m@mspar@margin{0}% left
    \else
      \def\m@mspar@margin{1}% right
    \fi
  \fi}

\newcommand*{\sideparfont}{\normalfont\normalsize}
\newcommand*{\sideparform}{\ifmemtortm\raggedright\else\raggedleft\fi}

\newcommand{\sidepar}{\@dblarg{\@sidepar}}
\long\def\@sidepar[#1]#2{\leavevmode\@bsphack\strut\vadjust{%
  \checkoddpage
  \ifm@msetsp% \sideparmargin used
%%%%    \setspbools
  \else% \sideparmargin not used, set the \m@mspar@margin code
    \setspcode
  \fi
  \rlap{\kern-\parindent
    \m@mwhich@margin{\m@mspar@margin}% set left or right margin
    \ifmemtortm
      \m@msidepar@right
    \else
      \m@msidepar@left
    \fi
  \setbox0=\vtop to 0pt{%
    \begin{minipage}[t]{\marginparwidth}%
      \def\baselinestretch{\m@m@footnote@spacing}%
      \sideparform\sideparfont%
      \ifmemtortm #2\else #1\fi
    \end{minipage}%
    \vss}%
  \vtop to 0pt{\kern\sideparvshift% default should be 0pt
    \kern-\dp\strutbox
    \kern-\ht0
    \box0 \vss}}}%
  \@esphack}

\newlength{\sideparvshift}
\setlength{\sideparvshift}{0pt}
%%%%  \setlength{\sideparvshift}{-2.08ex}% seems to work for all font sizes

\newinsert\sideins
  \skip\sideins=0pt
  \count\sideins=0

\newlength{\sidebartopsep}
  \setlength{\sidebartopsep}{0pt}
\newcommand{\setsidebarheight}[1]{%
  \setlength{\dimen\sideins}{#1}%
  \advance\dimen\sideins-\topskip
  \advance\dimen\sideins\ht\strutbox}

\newlength{\sidebarhsep}
\newlength{\sidebarvsep}
\newlength{\sidebarwidth}
\newcommand{\sidebarfont}{\normalfont\normalsize}
\newcommand*{\setsidebars}[6]{%
  \nametest{#1}{*}\ifsamename\else
    \setlength{\sidebarhsep}{#1}\@memznegtest{\sidebarhsep}%
  \fi
  \nametest{#2}{*}\ifsamename\else
    \setlength{\sidebarwidth}{#2}\@memznegtest{\sidebarwidth}%
  \fi
  \nametest{#3}{*}\ifsamename\else
    \setlength{\sidebarvsep}{#3}\@memnegtest{\sidebarvsep}%
  \fi
  \nametest{#4}{*}\ifsamename\else
    \setlength{\sidebartopsep}{#4}%
  \fi
  \nametest{#5}{*}\ifsamename\else
    \def\sidebarfont{#5}%
  \fi
  \nametest{#6}{*}\ifsamename\else
    \setsidebarheight{#6}%
    \ifdim\dimen\sideins>\z@\else
%%%%      \@memerror{\protect\sidebarheight\space is zero or negative}{\@ehd}%
      \@memwarn{\protect\sidebarheight\space is zero or negative}%
    \fi
  \fi}
\setsidebars{\marginparsep}%          sidebarhsep
            {\marginparwidth}%        sidebarwidth
            {\onelineskip}%           sidebarvsep
            {0pt}%                    sidebartopsep
            {\normalsize\normalfont}% sidebarfont
            {\textheight}%            sidebarheight

\newcommand{\sidebarform}{%\rightskip=\z@ \@plus 2em}
  %\memRTLrightskip=\z@ \@plus 2em
  \ifmemtortm\raggedright\else\raggedleft\fi%
  % \ifmemtortm\memRTLrightskip=\z@ \@plus 2em\else\memRTLleftskip=\z@ \@plus 2em\fi
}

\newif\ifsidebaroneside
  \if@twoside\sidebaronesidefalse\else\sidebaronesidetrue\fi

\newcommand*{\sidebarmargin}[1]{%
  \m@msetm@argin{#1}%
  \ifnum\m@mm@argin<\z@
    \@memwarn{Bad \string\sidebarmargin\space argument `#1'\MessageBreak
              set to `outer'}%
    \gdef\m@msidebar@margin{2}%   set as outer
  \else
    \global\let\m@msidebar@margin\m@mm@argin
  \fi}
%%%% default outer
\gdef\m@msidebar@margin{2}
\newcommand*{\m@sideb@left}{%
  \@tempdimc \sidebarwidth
  \advance\@tempdimc\sidebarhsep
  \kern-\@tempdimc}
\newcommand*{\m@sideb@right}{%
  \@tempdimc \columnwidth%  or \hsize
  \advance\@tempdimc\sidebarhsep
  \kern\@tempdimc}

\newcommand{\sidecontents}{\hbox to \z@{%
  \m@mwhich@margin{\m@msidebar@margin}%
  \ifmemtortm
    \m@sideb@right
  \else
    \m@sideb@left
  \fi
  \vtop to0pt{%
    \normalsize\normalfont\sidebarfont% select font so we know the strut size
    \vskip\topskip \vskip-\ht\strutbox
    \vskip\sidebartopsep% extra vertical shift
    \unvbox\sideins \vss}%
  \hss}}

\newcommand{\sidebar}[1]{%
  \insert\sideins{%
    \hsize\sidebarwidth
    \@parboxrestore
    \def\baselinestretch{\m@m@footnote@spacing}%
    \m@mwhich@margin{\m@msidebar@margin}%
    \sidebarform\sidebarfont
    \splittopskip=\ht\strutbox
    \splitmaxdepth=\dp\strutbox % doesn't do anything useful
    \allowbreak
    \prevdepth=\dp\strutbox    % supersedes a "top-strut"
    \vskip-\parskip
    #1%
    \ifvmode\else
      \unskip\@finalstrut\strutbox
    \fi\par
    \ifdim\prevdepth>\dp\strutbox \prevdepth=\dp\strutbox \fi
    \ifdim\prevdepth>99\p@
      \nobreak
      \vskip-\prevdepth
      \allowbreak
      \vskip\dp\strutbox
    \fi
    \vskip\sidebarvsep}}

\renewcommand{\footnoterule}{%
  \kern-3\p@
  \normalcolor% added 2013/05/08
  \hrule width .4\columnwidth
  \kern 2.6\p@}
\skip\footins=\bigskipamount
\@addtoreset{footnote}{chapter}
\newcommand*{\multfootsep}{\textsuperscript{\normalfont,}}
\newcommand*{\multiplefootnotemarker}{3sp}
\newcommand*{\m@mmf@prepare}{%
  \kern-\multiplefootnotemarker
  \kern\multiplefootnotemarker\relax}
\newcommand*{\m@mmf@check}{%
  \ifdim\lastkern=\multiplefootnotemarker\relax
    \edef\@x@sf{\the\spacefactor}%
    \unkern
    \multfootsep
    \spacefactor\@x@sf\relax
  \fi}

\renewcommand*{\@footnotemark}{%
  \leavevmode
  \ifhmode
    \edef\@x@sf{\the\spacefactor}%
    \m@mmf@check
    \nobreak
  \fi
  \@makefnmark
  \m@mmf@prepare
  \ifhmode\spacefactor\@x@sf\fi
  \relax}

\newcommand{\mem@pn@multiple@marker}[1]{%
  \leavevmode
  \ifhmode
    \edef\@x@sf{\the\spacefactor}%
    \m@mmf@check
    \nobreak
  \fi
  \@nameuse{mem@pnmm@start@hook}%
  #1%
  \@nameuse{mem@pnmm@end@hook}%
  \m@mmf@prepare
  \ifhmode\spacefactor\@x@sf\fi
  \relax}

\newlength{\footmarkwidth}
\newlength{\footmarksep}
\newlength{\footparindent}
\newcommand*{\footmarkstyle}[1]{\def\footscript##1{#1}}
\newcommand{\makefootmarkhook}{}

\newcommand{\footfootmark}{%
  \ifdim\footmarkwidth < \z@
    \llap{\hb@xt@ -\footmarkwidth{%
            \hss\normalfont\footscript{\@thefnmark}}%
          \hspace*{-\footmarkwidth}}%
  \else
    \ifdim\footmarkwidth = \z@
      {\normalfont\footscript{\@thefnmark}}%
    \else
      \hb@xt@\footmarkwidth{\hss\normalfont\footscript{\@thefnmark}}%
    \fi
  \fi}

\newcommand{\makefootmark}[1]{%
  \leavevmode
  \parindent \footparindent\noindent
  \leftskip\footmarksep\relax
  \advance\leftskip \footmarkwidth \null\nobreak\hskip -\leftskip\relax
  \makefootmarkhook\relax
  \footfootmark #1}
\newcommand{\@makefntext}[1]{\makefootmark #1}
\footmarkstyle{\textsuperscript{#1}}
\setlength{\footmarkwidth}{1.8em}
\setlength{\footmarksep}{-1.8em}
\setlength{\footparindent}{1em}

\providecommand{\footref}[1]{%
  \begingroup
    \unrestored@protected@xdef\@thefnmark{\ref{#1}}%
  \endgroup
  \@footnotemark}

\def\verbfootnote{\@ifnextchar[\@xverbfootnote{\stepcounter\@mpfn
  \protected@xdef\@thefnmark{\thempfn}%
  \@footnotemark\@verbfootnotetext}}

\def\@xverbfootnote[#1]{%
  \begingroup
    \csname c@\@mpfn\endcsname #1\relax
    \unrestored@protected@xdef\@thefnmark{\thempfn}%
  \endgroup
  \@footnotemark\@verbfootnotetext}

\long\def\@verbfootnotetext{%
  \insert\footins\bgroup
    \foottextfont%
    \interlinepenalty\interfootnotelinepenalty
    \splittopskip\footnotesep
    \splitmaxdepth \dp\strutbox \floatingpenalty \@MM
    \hsize\columnwidth \@parboxrestore
    \def\@currentcounter{footnote}%
    \edef\@currentlabel{\csname p@footnote\endcsname\@thefnmark}%
%%%%    \color@begingroup
    \@makefntext{\rule{\z@}{\footnotesep}\ignorespaces}%
    \futurelet\next\fo@t
}
\def\fo@t{\ifcat\bgroup\noexpand\next \let\next\f@@t
          \else \let\next\f@t\fi \next}
\def\f@@t{\bgroup\aftergroup\@foot\let\next}
\def\f@t#1{%
  \color@begingroup
  #1\@foot
  \color@endgroup}
\def\@foot{%
  \strut\egroup
%%%%  \color@endgroup
  \m@mmf@prepare
  }

\long\def\@verbmpfootnotetext{%
  \global\setbox\@mpfootins\vbox{%
    \reset@font\foottextfont
    \unvbox\@mpfootins
    \bgroup
    \hsize\columnwidth
    \@parboxrestore
    \def\@currentcounter{mpfootnote}%
    \edef\@currentlabel{\csname p@mpfootnote\endcsname\@thefnmark}%
    \color@begingroup
    \@makefntext{\rule{\z@}{\footnotesep}\ignorespaces}%
    }
    \futurelet\next\fo@t
}

%%%%%%%%%%%%%% major extension to footnoting

\newcommand*{\setfootnoterule}[4][]{%
  \def\footnoterule{\kern -#2\relax #1\relax
    \normalcolor% added 2013/05/08
    \hrule width #3\relax
    \kern #2\kern-#4}}
\setfootnoterule{3pt}{0.4\columnwidth}{\normalrulethickness}

\newcommand{\m@mdoextrafeet}{\extrafeetins}
\newcommand*{\extrafeetins}{%
  \setbox\@outputbox \vbox{%
    \boxmaxdepth \@maxdepth
    \unvbox\@outputbox
    \ifvoid\footinsv@r\else\@footstartv@r\@footgroupv@r\fi
    \extrafeetinshook}}
\newcommand{\extrafeetinshook}{}

\newcommand{\m@mdodoreinextrafeet}{%
  \ifvoid\footinsv@r\else\insert\footinsv@r{\unvbox\footinsv@r}\fi
  \extrafeetreinshook}
\newcommand{\extrafeetreinshook}{}

\newcommand{\foottextfont}{\footnotesize}
\newlength{\footinsdim}
  \setlength{\footinsdim}{8in}   % standard for \dimen\footins
\newcommand{\@preamfntext}{%
  \interlinepenalty\interfootnotelinepenalty
  \floatingpenalty \@MM
  \splittopskip=\footnotesep
  \splitmaxdepth=\dp\strutbox
  \@parboxrestore}

\renewcommand{\@mpfootnotetext}[1]{%
  \global\setbox\@mpfootins\vbox{%
    \unvbox\@mpfootins
    \def\baselinestretch{\m@m@footnote@spacing}%
    \foottextfont \hsize\columnwidth \@parboxrestore
    \def\@currentcounter{mpfootnote}%
    \protected@edef\@currentlabel{%
      \csname p@mpfootnote\endcsname\@thefnmark}%
  \color@begingroup
  \reset@font%
    \@makefntext{%
      \rule\z@\footnotesep\ignorespaces\foottextfont #1%
      \@finalstrut\strutbox}%
  \color@endgroup}}

\let\@plainmpfootnotetext\@mpfootnotetext

\newcommand{\m@mdoextrafeetmini}{%
  \extrafeetminihook}
\newcommand{\extrafeetminihook}{}
%%%%\renewcommand{\@minipagerestore}{\m@mdoextrafeetmini}

\newcommand{\extrafeetendmini}{%
  \ifvoid\@mpfootinsv@r\else
    \vskip\skip\@mpfootins
    \normalcolor\footnoterule\mp@footgroupv@r
  \fi
  \extrafeetendminihook}
\newcommand{\extrafeetendminihook}{}

\newcommand{\m@mdoextrafeetendmini}{\extrafeetendmini}
\def\endminipage{%
  \par
  \unskip
  \ifvoid\@mpfootins\else
    \vskip\skip\@mpfootins
    \normalcolor
    \footnoterule
    \unvbox\@mpfootins
  \fi
  \m@mdoextrafeetendmini
  \@minipagefalse
  \color@endgroup
  \egroup
  \expandafter\@iiiparbox\@mpargs{\unvbox\@tempboxa}}

\newcommand{\plainfootnotes}{%
  \let\@footnotetext\@plainfootnotetext
  \let\@mpfootnotetext\@plainmpfootnotetext}

\newcommand{\newfootnoteseries}[1]{%
  \expandafter\newinsert\csname footins#1\endcsname%  -> \footins#1
  \expandafter\skip\csname footins#1\endcsname \bigskipamount%
%%%                                      - > \skip\footins#1 % [RS]
  \newcounter{footnote#1}%                       -> \c@footnote#1
  \@nameuse{c@footnote#1} \z@%                   -> \c@footnote#1=0
  \global\@namelet{p@footnote#1} \@empty%        -> \p@footnote#1
  \@namedef{thefootnote#1}{\arabic{footnote#1}}% -> \thefootnote#1
  \@namedef{foottextfont#1}{\foottextfont}%      -> \foottextfont#1
  \m@makefootnote{#1}%                           -> \footnote#1
  \m@make@xfootnote{#1}%                         -> \@xfootnote#1
  \m@make@footnotetext{#1}%                      -> \@footnotetext#1
  \m@makefootnotemark{#1}%                       -> \footnotemark#1
  \m@make@xfootnotemark{#1}%                     -> \@xfootnotemark#1
  \m@make@footnotemark{#1}%                      -> \@footnotemark#1
  \m@makefootnotetext{#1}%                       -> \footnotetext#1
  \m@make@xfootnotenext{#1}%                     -> \@xfootnotenext#1
  \m@make@mpfn{#1}%                              -> \@mpfn#1
  \m@makethempfn{#1}%                            -> \thempfn#1
  \m@make@makefnmark{#1}%                        -> \@makefnmark#1
  \m@makefootref{#1}%                            -> \footref#1
  \m@makefootfootmark{#1}%                       -> \footfootmark#1
  \m@makemakefootmark{#1}%                       -> \makefootmark#1
  \m@makefootmarkstyle{#1}%                      -> \footmarkstyle#1
  \@namelongdef{@makefntext#1}##1{\@nameuse{makefootmark#1} ##1}%
  \m@make@footstart{#1}%                         -> \@footstart#1
  \m@make@footgroup{#1}%                         -> \@footgroup#1
  \expandafter\newinsert\csname @mpfootins#1\endcsname% -> \@mpfootins#1
  \newcounter{mpfootnote#1}%                     -> \c@mpfootnote#1
  \global\@namelet{p@mpfootnote#1}\@empty
  \@namedef{thempfootnote#1}{\itshape\alph{mpfootnote#1}}%
  \m@make@mpfootnotetext{#1}%                    -> \@mpfootnotetext#1
  \ifartopt\else%  [RS]
    \expandafter\@cons\csname cl@chapter\endcsname {{footnote#1}}%
  \fi
  \g@addto@macro{\extrafeetinshook}{%
    \ifvoid\@nameuse{footins#1}\else
      \@nameuse{@footstart#1}\@nameuse{@footgroup#1}\fi}
  \g@addto@macro{\extrafeetreinshook}{%
    \ifvoid\@nameuse{footins#1}\else
      \insert\@nameuse{footins#1}{\unvbox\@nameuse{footins#1}}\fi}
  \g@addto@macro{\extrafeetendminihook}{%
    \ifvoid\@nameuse{@mpfootins#1}\else
      \vskip\skip\@mpfootins
      \normalcolor\footnoterule\@nameuse{mp@footgroup#1}\fi}
  \g@addto@macro{\extrafeetminihook}{%
    \@namedef{@mpfn#1}{mpfootnote#1}
    \@namedef{thempfn#1}{\@nameuse{thempfootnote#1}}
    \csname c@mpfootnote#1\endcsname\z@
     \expandafter\let\expandafter\@t@mp \csname @mpfootnotetext#1\endcsname
     \expandafter\let \csname @footnotetext#1\endcsname \@t@mp}
  \g@addto@macro{\@mem@extranofeet}{%  % [RS]
    \ifvoid\@nameuse{footins#1}\else\@mem@nofootfalse\fi}
  \plainfootstyle{#1}%
}

\newcommand{\m@makefootnote}[1]{
  \@namedef{footnote#1}{\@ifnextchar[
    {\@nameuse{@xfootnote#1}}{%\advance \@nameuse{c@\@mpfn#1} by \@ne
                              \stepcounter{\@mpfn#1}%
      \@name@p@xdef{@thefnmark#1}{\@nameuse{thempfn#1}}%
      \@nameuse{@footnotemark#1}\@nameuse{@footnotetext#1}}}}

\newcommand{\m@make@xfootnote}[1]{
  \@namedef{@xfootnote#1}[##1]{%
  \begingroup
    \csname c@\@mpfn#1\endcsname ##1\relax
    \@name@unresp@xdef{@thefnmark#1}{\@nameuse{thempfn#1}}%
  \endgroup
  \@nameuse{@footnotemark#1}\@nameuse{@footnotetext#1}}}

\newcommand{\m@make@footnotetext}[1]{%
  \@namelongdef{@footnotetext#1}##1{%
  \insert\@nameuse{footins#1}{%
  \def\baselinestretch{\m@m@footnote@spacing}%
  \reset@font\@nameuse{foottextfont#1}%
  \@preamfntext
  \hsize\columnwidth
  \def\@currentcounter{footnote}%
  \protected@edef\@currentlabel{%
    \csname p@footnote#1\endcsname\@nameuse{@thefnmark#1}}%
  \color@begingroup
    \@nameuse{@makefntext#1}{%
      \rule\z@\footnotesep\ignorespaces\@nameuse{foottextfont#1 ##1}%
      \@finalstrut\strutbox}%
  \color@endgroup}%
  \m@mmf@prepare}}

\newcommand{\m@make@mpfootnotetext}[1]{%
  \@namelongdef{@mpfootnotetext#1}##1{%
    \global\setbox\@nameuse{@mpfootins#1}\vbox{%
      \unvbox\@nameuse{@mpfootins#1}%
      \def\baselinestretch{\m@m@footnote@spacing}%
      \reset@font\@nameuse{foottextfont#1}%
      \hsize\columnwidth \@parboxrestore
      \def\@currentcounter{mpfootnote}%
      \protected@edef\@currentlabel{%
        \csname p@mpfootnote#1\endcsname\@nameuse{@thefnmark#1}}%
    \color@begingroup
      \@nameuse{@makefntext#1}{%
        \rule\z@\footnotesep\ignorespaces\@nameuse{foottextfont#1}##1%
        \@finalstrut\strutbox}%
    \color@endgroup}%
    \m@mmf@prepare}}

\newcommand{\m@makefootnotemark}[1]{
\@namedef{footnotemark#1}{%
  \@ifnextchar[ {\@nameuse{@xfootnotemark#1}}
    {%\advance\@nameuse{c@footnote#1} by \@ne%
     \stepcounter{footnote#1}%
     \@name@p@xdef{@thefnmark#1}{\@nameuse{thefootnote#1}}%
     \@nameuse{@footnotemark#1}}}}

\newcommand{\m@make@xfootnotemark}[1]{%
  \@namedef{@xfootnotemark#1}[##1]{%
  \begingroup
    \@nameuse{c@footnote#1} ##1\relax
    \@name@unresp@xdef{@thefnmark#1}{\@nameuse{thefootnote#1}}%
  \endgroup
  \@nameuse{@footnotemark#1}}}

\newcommand{\m@make@footnotemark}[1]{%
\@namedef{@footnotemark#1}{%
  \leavevmode
  \ifhmode
    \edef\@x@sf{\the\spacefactor}%
    \m@mmf@check
    \nobreak
  \fi
  \@nameuse{@makefnmark#1}%
  \m@mmf@prepare
  \ifhmode\spacefactor\@x@sf\fi
  \relax}}

\newcommand{\m@makefootmarkstyle}[1]{%
 \@namedef{footmarkstyle#1}##1{%
    \@namedef{footscript#1}####1{##1}}}

\newcommand{\m@makefootnotetext}[1]{%
\@namedef{footnotetext#1}{%
  \@ifnextchar[  {\@nameuse{@xfootnotenext#1}}%
  {\@name@p@xdef{@thefnmark#1}{\@nameuse{thempfn#1}}%
  \@nameuse{@footnotetext#1}}}}

\newcommand{\m@make@xfootnotenext}[1]{
\@namedef{@xfootnotenext#1}[##1]{%
  \begingroup
    \csname c@\@mpfn#1\endcsname ##1\relax
    \@name@unresp@xdef{@thefnmark#1}{\@nameuse{thempfn#1}}%
  \endgroup
  \@nameuse{@footnotetext#1}}}

\newcommand{\m@make@mpfn}[1]{%
  \@namedef{@mpfn#1}{\@nameuse{footnote#1}}}

\newcommand{\m@makethempfn}[1]{%
  \@namedef{thempfn#1}{\@nameuse{thefootnote#1}}}

\newcommand{\m@make@makefnmark}[1]{%
  \@namedef{@makefnmark#1}{%
    \hbox{\@textsuperscript{\normalfont\@nameuse{@thefnmark#1}}}}}

\newcommand{\m@makefootref}[1]{%
  \@namedef{footref#1}##1{%
    \begingroup
      \@name@unresp@xdef{@thefnmark#1}{\ref{##1}}%
    \endgroup
    \@nameuse{@footnotemark#1}}}

\newcommand{\m@makefootfootmark}[1]{%
  \@namedef{footfootmark#1}{%
    \ifdim\footmarkwidth < \z@
      \llap{\hb@xt@ -\footmarkwidth{%
            \hss\normalfont\@nameuse{footscript#1}%
            {\@nameuse{@thefnmark#1}}}%
            \hspace*{-\footmarkwidth}}%
    \else
      \ifdim\footmarkwidth = \z@
        {\normalfont\@nameuse{footscript#1}{\@nameuse{@thefnmark#1}}}%
      \else
        \hb@xt@\footmarkwidth{%
            \hss\normalfont\@nameuse{footscript#1}%
            {\@nameuse{@thefnmark#1}}}%
      \fi
    \fi}}

\newcommand{\m@makemakefootmark}[1]{%
  \@namedef{makefootmark#1}##1{%
    \leavevmode
    \parindent \footparindent\noindent
    \leftskip\footmarksep\relax
    \advance\leftskip \footmarkwidth
    \null\nobreak\hskip -\leftskip\relax
    \makefootmarkhook\relax
    \@nameuse{footfootmark#1}##1}}

\newcommand{\m@make@footgroup}[1]{%
  \@namedef{@footgroup#1}{\unvbox\@nameuse{footins#1}}}

\newcommand{\m@makemp@footgroup}[1]{%
  \@namedef{mp@footgroup#1}{\unvbox\@nameuse{@mpfootins#1}}}

\newcommand{\m@make@footstart}[1]{%
  \@namedef{@footstart#1}{%
    %\vskip\bigskipamount
    \mem@if@flushbottomF\m@mopfn@bottom
    \vskip\skip\csname footins#1\endcsname
    \leftskip=\z@
    \rightskip=\z@
    \footnoterule}}

\newcommand{\plainfootstyle}[1]{%
  \m@make@footnotetext{#1}%
  \m@make@footgroup{#1}%
  \m@make@footstart{#1}%
  \m@make@mpfootnotetext{#1}%
  \m@makemp@footgroup{#1}%
  \@nameuse{footmarkstyle#1}{\textsuperscript{##1}}
  \expandafter\dimen\csname footins#1\endcsname=\footinsdim
  \expandafter\count\csname footins#1\endcsname=1000\relax}

\newinsert\footinsv@r
  \skip\footinsv@r\bigskipamount
  \count\footinsv@r=1000 % no magnifcation
  \dimen\footinsv@r=\footinsdim
\m@make@footstart{v@r}
\newcommand{\@footgroupv@r}{}

\newinsert\@mpfootinsv@r
\newcommand{\mp@footgroupv@r}{}

\newcount\m@m@k \newdimen\m@m@h
\newcommand*{\m@mrigidbalance}[3]{\setbox0=\box#1 \m@m@k=#2 \m@m@h=#3
  \@@line{\splittopskip=\m@m@h \vbadness=\@M \hfilneg
  \valign{##\vfill\cr\m@mdosplits}}}
\newcommand*{\m@mdosplits}{\ifnum\m@m@k>0 \noalign{\hfil}\m@msplitoff
  \global\advance\m@m@k-1\cr\m@mdosplits\fi}
\newcommand*{\m@msplitoff}{\dimen0=\ht0
  \divide\dimen0 by\m@m@k \advance\dimen0 by\m@m@h
  \setbox2 \vsplit0 to \dimen0
  \unvbox2 }

\newcommand{\twocolumnfootnotes}{%
  \@namedef{foottextfontv@r}{\foottextfont}%  % [RS]
  \let\@footnotetext\@twocolfootnotetext
  \dimen\footinsv@r=2\footinsdim
  \count\footinsv@r=500\relax
  \m@make@twocol@footgroup{v@r}%
  \let\@footgroupv@r\@twocol@footgroupv@r
  \let\@mpfootnotetext\@mptwocolfootnotetext
  \m@make@mptwocol@footgroup{v@r}%
  \let\mp@footgroupv@r\@mptwocol@footgroupv@r}

\newcommand{\@twocolfootnotetext}[1]{\insert\footinsv@r{%
  \def\baselinestretch{\m@m@footnote@spacing}%
  \reset@font\foottextfont
  \@preamfntext
  \def\@currentcounter{footnote}%
  \protected@edef\@currentlabel{%
    \csname p@footnote\endcsname\@thefnmark}%
  \color@begingroup
    \@twocolfootfmt{#1}%
  \color@endgroup}%
  \m@mmf@prepare}

\newcommand{\@preamtwofmt}{%
  \hsize .45\hsize
  \parindent=\z@
  \tolerance=5000\relax
  \raggedright
  \leavevmode}

\newcommand{\@twocolfootfmt}[1]{%
  \@preamtwofmt
  {\footfootmark\strut \foottextfont #1\strut\par}\allowbreak}

\newcommand{\@mptwocolfootnotetext}[1]{%
  \global\setbox\@mpfootinsv@r\vbox{%
    \unvbox\@mpfootinsv@r
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font\foottextfont
    \hsize\columnwidth \@parboxrestore
    \def\@currentcounter{mpfootnote}%
    \protected@edef\@currentlabel{%
      \csname p@mpfootnote\endcsname\@thefnmark}%
  \color@begingroup
    \@twocolfootfmt{#1}%
  \color@endgroup}%
  \m@mmf@prepare}

\newcommand{\twocolumnfootstyle}[1]{%
  \m@make@twocolfootnotetext{#1}%
  \m@make@mptwocolfootnotetext{#1}%
  \m@make@twocolfootfmt{#1}%
  \m@make@twocol@footgroup{#1}%
  \m@make@mptwocol@footgroup{#1}%
  \m@make@footstart{#1}%
  \@namelongdef{@footnotetext#1}##1{%
     \@nameuse{@twocolfootnotetext#1}{##1}}%
  \@namelongdef{@mpfootnotetext#1}##1{%
     \@nameuse{@mptwocolfootnotetext#1}{##1}}%
  \@namedef{@footgroup#1}{\@nameuse{@twocol@footgroup#1}}%
  \@namedef{mp@footgroup#1}{\@nameuse{@mptwocol@footgroup#1}}%
  \expandafter\dimen\csname footins#1\endcsname=2\footinsdim
  \expandafter\count\csname footins#1\endcsname=500\relax}

\newcommand{\m@make@twocolfootnotetext}[1]{%
  \@namelongdef{@twocolfootnotetext#1}##1{%
    \insert\@nameuse{footins#1}{%
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font\@nameuse{foottextfont#1}%
    \@preamfntext
    \def\@currentcounter{footnote}%
    \protected@edef\@currentlabel{%
      \csname p@footnote#1\endcsname \@nameuse{@thefnmark#1}}%
    \color@begingroup
      \@nameuse{@twocolfootfmt#1}{##1}%
    \color@endgroup}%
    \m@mmf@prepare}}

\newcommand{\m@make@mptwocolfootnotetext}[1]{%
\@namelongdef{@mptwocolfootnotetext#1}##1{%
  \global\setbox\@nameuse{@mpfootins#1}\vbox{%
    \unvbox\@nameuse{@mpfootins#1}
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font\@nameuse{foottextfont#1}%
    \hsize\columnwidth \@parboxrestore
    \def\@currentcounter{mpfootnote}%
    \protected@edef\@currentlabel{%
      \csname p@mpfootnote#1\endcsname\@nameuse{@thefnmark#1}}%
  \color@begingroup
    \@nameuse{@twocolfootfmt#1}{##1}%
  \color@endgroup}\m@mmf@prepare}}

\newcommand{\m@make@twocolfootfmt}[1]{%
  \@namedef{@twocolfootfmt#1}##1{%
    \@preamtwofmt
    {\@nameuse{footfootmark#1}\strut
      \@nameuse{foottextfont#1}##1\strut\par}\allowbreak}}

\newcommand{\m@make@twocol@footgroup}[1]{%
  \@namedef{@twocol@footgroup#1}{{%
    \@nameuse{foottextfont#1} \splittopskip=\ht\strutbox
     \m@mrigidbalance{\@nameuse{footins#1}}{\tw@}{\splittopskip}}}}

\newcommand{\m@make@mptwocol@footgroup}[1]{%
\@namedef{@mptwocol@footgroup#1}{{%
  \@nameuse{foottextfont#1} \splittopskip=\ht\strutbox
  \m@mrigidbalance{\@nameuse{@mpfootins#1}}{\tw@}{\splittopskip}}}}

\newcommand{\threecolumnfootnotes}{%
  \@namedef{foottextfontv@r}{\foottextfont}%  % [RS]
  \let\@footnotetext\@threecolfootnotetext
  \dimen\footinsv@r=3\footinsdim
  \count\footinsv@r=333\relax
  \m@make@threecol@footgroup{v@r}%
  \let\@footgroupv@r\@threecol@footgroupv@r
  \let\@mpfootnotetext\@mpthreecolfootnotetext
  \m@make@mpthreecol@footgroup{v@r}%
  \let\mp@footgroupv@r\@mpthreecol@footgroupv@r}

\newcommand{\@threecolfootnotetext}[1]{\insert\footinsv@r{%
  \def\baselinestretch{\m@m@footnote@spacing}%
  \reset@font\foottextfont
  \@preamfntext
  \def\@currentcounter{footnote}%
  \protected@edef\@currentlabel{%
    \csname p@footnote\endcsname\@thefnmark}%
  \color@begingroup
    \@threecolfootfmt{#1}%
  \color@endgroup}\m@mmf@prepare}

\newcommand{\@preamthreefmt}{%
  \hsize .3\hsize
  \parindent=\z@
  \tolerance=5000\relax
  \raggedright
  \leavevmode}

\newcommand{\@threecolfootfmt}[1]{%
  \@preamthreefmt
  {\footfootmark\strut \foottextfont #1\strut\par}\allowbreak}

\newcommand{\@mpthreecolfootnotetext}[1]{%
  \global\setbox\@mpfootinsv@r\vbox{%
    \unvbox\@mpfootinsv@r
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font\foottextfont
    \hsize\columnwidth \@parboxrestore
    \def\@currentcounter{mpfootnote}%
    \protected@edef\@currentlabel{%
      \csname p@mpfootnote\endcsname\@thefnmark}%
  \color@begingroup
    \@threecolfootfmt{#1}%
  \color@endgroup}\m@mmf@prepare}

\newcommand{\threecolumnfootstyle}[1]{%
  \m@make@threecolfootnotetext{#1}%
  \m@make@mpthreecolfootnotetext{#1}%
  \m@make@threecolfootfmt{#1}%
  \m@make@threecol@footgroup{#1}%
  \m@make@mpthreecol@footgroup{#1}%
  \m@make@footstart{#1}%
  \@namelongdef{@footnotetext#1}##1{%
    \@nameuse{@threecolfootnotetext#1}{##1}}%
  \@namelongdef{@mpfootnotetext#1}##1{%
    \@nameuse{@mpthreecolfootnotetext#1}{##1}}%
  \@namedef{@footgroup#1}{\@nameuse{@threecol@footgroup#1}}%
  \@namedef{mp@footgroup#1}{\@nameuse{@mpthreecol@footgroup#1}}%
  \expandafter\dimen\csname footins#1\endcsname=3\footinsdim
  \expandafter\count\csname footins#1\endcsname=333\relax}

\newcommand{\m@make@threecolfootnotetext}[1]{%
\@namelongdef{@threecolfootnotetext#1}##1{%
  \insert\@nameuse{footins#1}{%
  \def\baselinestretch{\m@m@footnote@spacing}%
  \reset@font\@nameuse{foottextfont#1}%
  \@preamfntext
  \def\@currentcounter{footnote}%
  \protected@edef\@currentlabel{%
    \csname p@footnote#1\endcsname \@nameuse{@thefnmark#1}}%
  \color@begingroup
    \@nameuse{@threecolfootfmt#1}{##1}%
  \color@endgroup}\m@mmf@prepare}}

\newcommand{\m@make@mpthreecolfootnotetext}[1]{%
\@namelongdef{@mpthreecolfootnotetext#1}##1{%
  \global\setbox\@nameuse{@mpfootins#1}\vbox{%
    \unvbox\@nameuse{@mpfootins#1}
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font\@nameuse{foottextfont#1}%
    \hsize\columnwidth \@parboxrestore
    \def\@currentcounter{mpfootnote}%
    \protected@edef\@currentlabel{%
      \csname p@mpfootnote#1\endcsname\@nameuse{@thefnmark#1}}%
  \color@begingroup
    \@nameuse{@threecolfootfmt#1}{##1}%
  \color@endgroup}\m@mmf@prepare}}

\newcommand{\m@make@threecolfootfmt}[1]{%
\@namelongdef{@threecolfootfmt#1}##1{%
  \@preamthreefmt
  {\@nameuse{footfootmark#1}\strut
    \@nameuse{foottextfont#1}##1\strut\par}\allowbreak}}

\newcommand{\m@make@threecol@footgroup}[1]{%
\@namedef{@threecol@footgroup#1}{{%
  \@nameuse{foottextfont#1} \splittopskip=\ht\strutbox
  \m@mrigidbalance{\@nameuse{footins#1}}{\thr@@}{\splittopskip}}}}

\newcommand{\m@make@mpthreecol@footgroup}[1]{%
\@namedef{@mpthreecol@footgroup#1}{{%
  \@nameuse{foottextfont#1} \splittopskip=\ht\strutbox
  \m@mrigidbalance{\@nameuse{@mpfootins#1}}{\thr@@}{\splittopskip}}}}

\newcommand{\m@munvxh}[1]{%
  \setbox0=\vbox{\unvbox#1%
    \global\setbox1=\lastbox}%
  \unhbox1
  \unskip
  \unskip
  \unpenalty
  \hskip\m@mipn@skip}

\newcommand{\m@mungebox}{%
  \setbox0=\hbox{\m@munvxh0}%
  \dp0=\z@
  \ht0=\footfudgefactor\wd0
  \box0
  \penalty0}

\newskip\m@mipn@skip
\newcommand*{\m@minterparanoteglue}[1]{%
  {\foottextfont\global\m@mipn@skip=#1\relax}}
\m@minterparanoteglue{1em plus.4em minus.4em}

\newcommand*{\m@mmakehboxofhboxes}{\setbox0=\hbox{}%
  \loop
    \unpenalty
    \setbox2=\lastbox
  \ifhbox2
    \setbox0=\hbox{\box2\unhbox0}
  \repeat}

\newcommand*{\m@mremovehboxes}{\setbox0=\lastbox
  \ifhbox0{\m@mremovehboxes}\unhbox0 \fi}

\newcommand*{\footfudgefiddle}{64}

\newcommand{\paragraphfootnotes}{%
  \@namedef{foottextfontv@r}{\foottextfont}%  % [RS]
  \let\@footnotetext\@parafootnotetext
  \dimen\footinsv@r=\footinsdim
  \count\footinsv@r=1000\relax
  \m@make@para@footgroup{v@r}%
  \let\@footgroupv@r\@para@footgroupv@r
  \let\@mpfootnotetext\@mpparafootnotetext
  \m@make@mppara@footgroup{v@r}%
  \let\mp@footgroupv@r\@mppara@footgroupv@r
  {\foottextfont
   \dimen0=\baselineskip
   %\multiply\dimen0 by 1024
   \multiply\dimen0 by 256
   \divide\dimen0   by \hsize
   \multiply\dimen0 by 4
   \multiply\dimen0 by \footfudgefiddle
   \xdef\footfudgefactor{\expandafter\strip@pt\dimen0 }}}

\newcommand{\@parafootnotetext}[1]{\insert\footinsv@r{
  \def\baselinestretch{\m@m@footnote@spacing}%
  \reset@font\foottextfont
  \@preamfntext
  \def\@currentcounter{footnote}%
  \protected@edef\@currentlabel{%
    \csname p@footnote\endcsname\@thefnmark}%
  \setbox0=\vbox{\hsize=\maxdimen
    \color@begingroup
      \noindent \@parafootfmt{#1}%
    \color@endgroup}%
  \m@mungebox}\m@mmf@prepare}

\newcommand{\@parafootfmt}[1]{%
  \parindent=\z@
  \parfillskip=0pt \@plus 1fil
  {\footfootmark\strut \foottextfont #1\penalty-10}}

\newcommand{\@mpparafootnotetext}[1]{%
  \global\setbox\@mpfootinsv@r\vbox{%
    \unvbox\@mpfootinsv@r
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font\foottextfont
    \hsize\columnwidth \@parboxrestore
    \def\@currentcounter{mpfootnote}%
    \protected@edef\@currentlabel{%
      \csname p@mpfootnote\endcsname\@thefnmark}%
    \setbox0=\vbox{\hsize=\maxdimen
      \color@begingroup
      \noindent \@parafootfmt{#1}%
      \color@endgroup}%
  \m@mungebox}\m@mmf@prepare}

\newcommand{\paragraphfootstyle}[1]{%
  \m@make@parafootnotetext{#1}%
  \m@make@mpparafootnotetext{#1}%
  \m@make@parafootfmt{#1}%
  \m@make@para@footgroup{#1}%
  \m@make@mppara@footgroup{#1}%
  \m@make@para@footstart{#1}%
  \@namelongdef{@footnotetext#1}##1{%
    \@nameuse{@parafootnotetext#1}{##1}}%
  \@namelongdef{@mpfootnotetext#1}##1{%
    \@nameuse{@mpparafootnotetext#1}{##1}}%
  \@namedef{@footgroup#1}{\@nameuse{@para@footgroup#1}}%
  \@namedef{mp@footgroup#1}{\@nameuse{@mppara@footgroup#1}}%
  \@namedef{@footstart#1}{\@nameuse{@para@footstart#1}}%
  \expandafter\dimen\csname footins#1\endcsname=\footinsdim
  \expandafter\count\csname footins#1\endcsname=1000\relax
  {\@nameuse{foottextfont#1}%
   \dimen0=\baselineskip
   %\multiply\dimen0 by 1024
   \multiply\dimen0 by 256
   \divide\dimen0   by \hsize
   \multiply\dimen0 by 4
   \multiply\dimen0 by \footfudgefiddle
   \xdef\footfudgefactor{\expandafter\strip@pt\dimen0 }}}

\newcommand{\m@make@parafootnotetext}[1]{%
\@namelongdef{@parafootnotetext#1}##1{%
  \insert\@nameuse{footins#1}{
  \def\baselinestretch{\m@m@footnote@spacing}%
  \reset@font\@nameuse{foottextfont#1}%
  \@preamfntext
  \def\@currentcounter{footnote}%
  \protected@edef\@currentlabel{%
    \csname p@footnote#1\endcsname \@nameuse{@thefnmark#1}}%
  \setbox0=\vbox{\hsize=\maxdimen
    \color@begingroup
      \noindent \@nameuse{@parafootfmt#1}{##1}%
    \color@endgroup}%
  \m@mungebox}\m@mmf@prepare}}

\newcommand{\m@make@mpparafootnotetext}[1]{%
\@namelongdef{@mpparafootnotetext#1}##1{%
  \global\setbox\@nameuse{@mpfootins#1}\vbox{%
    \unvbox\@nameuse{@mpfootins#1}
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font\@nameuse{foottextfont#1}%
    \hsize\columnwidth \@parboxrestore
    \def\@currentcounter{mpfootnote}%
    \protected@edef\@currentlabel{%
      \csname p@mpfootnote#1\endcsname\@nameuse{@thefnmark#1}}%
    \setbox0=\vbox{\hsize=\maxdimen
      \color@begingroup
        \noindent \@nameuse{@parafootfmt#1}{##1}%
      \color@endgroup}%
    \m@mungebox}\m@mmf@prepare}}

\newcommand{\m@make@parafootfmt}[1]{%
\@namelongdef{@parafootfmt#1}##1{%
  \parindent=\z@
  \parfillskip=0pt \@plus 1fil
  {\@nameuse{footfootmark#1}\strut
   \@nameuse{foottextfont#1}##1\penalty-10}}}

\newcommand{\m@make@para@footgroup}[1]{%
\@namedef{@para@footgroup#1}{%
  \unvbox\@nameuse{footins#1}
  \m@mmakehboxofhboxes
  \setbox0=\hbox{\unhbox0 \m@mremovehboxes}%
  \@nameuse{foottextfont#1}%
  \noindent\unhbox0\par}}

\newcommand{\m@make@mppara@footgroup}[1]{%
\@namedef{@mppara@footgroup#1}{%
  \unvbox\@nameuse{@mpfootins#1}
  \m@mmakehboxofhboxes
  \setbox0=\hbox{\unhbox0 \m@mremovehboxes}%
  \@nameuse{foottextfont#1}%
  \noindent\unhbox0\par}}

\newcommand{\m@make@para@footstart}[1]{%
\@namedef{@para@footstart#1}{%
  \vskip\bigskipamount
  \leftskip=\z@
  \rightskip=\z@
  \parindent=\z@
  \vskip\skip\@nameuse{footins#1}%
  \footnoterule}}

\newif\if@mem@nofoot
\newcommand*{\@mem@testifnofoot}{%
  \@mem@nofoottrue
  \ifvoid\footins\else\@mem@nofootfalse\fi
  \ifvoid\footinsv@r\else\@mem@nofootfalse\fi
  \ifvoid\sideins\else\@mem@nofootfalse\fi
  \@mem@extranofeet}
\newcommand*{\@mem@extranofeet}{}

\let\memold@doclearpage\@doclearpage
\newcommand{\mem@doclearpage}{%
  \@mem@testifnofoot
  \if@mem@nofoot
    \setbox\@tempboxa\vsplit\@cclv to\z@ \unvbox\@tempboxa
    \setbox\@tempboxa\box\@cclv
    \xdef\@deferlist{\@toplist\@botlist\@deferlist}%
    \global \let \@toplist \@empty
    \global \let \@botlist \@empty
    \global \@colroom \@colht
    \ifx \@currlist\@empty
    \else
       \@latexerr{Float(s) lost}\@ehb
       \global \let \@currlist \@empty
    \fi
    \@makefcolumn\@deferlist
    \@whilesw\if@fcolmade \fi{\@opcol\@makefcolumn\@deferlist}%
    \if@twocolumn
      \if@firstcolumn
        \xdef\@deferlist{\@dbltoplist\@deferlist}%
        \global \let \@dbltoplist \@empty
        \global \@colht \textheight
        \begingroup
           \@dblfloatplacement
           \@makefcolumn\@deferlist
           \@whilesw\if@fcolmade \fi{\@outputpage
                                     \@makefcolumn\@deferlist}%
         \endgroup
       \else
        \vbox{}\clearpage
      \fi
    \fi
    \ifx\@deferlist\@empty \else\clearpage \fi
  \else
    \setbox\@cclv\vbox{\box\@cclv\vfil}%
    \@makecol\@opcol
    \clearpage
  \fi
  % older version
  %   \setbox\@tempboxa\vsplit\@cclv to\z@ \unvbox\@tempboxa
  %   \setbox\@tempboxa\box\@cclv
  %   \xdef\@deferlist{\@toplist\@botlist\@deferlist}%
  %   \global\let\@toplist\@empty
  %   \global\let\@botlist\@empty
  %   \global\@colroom\@colht
  %   \ifx \@currlist\@empty
  %   \else
  %     \@latexerr{Float(s) lost}\@ehb
  %     \global\let\@currlist\@empty
  %   \fi
  %   \@makefcolumn\@deferlist
  %   \@whilesw\if@fcolmade \fi{\@opcol\@makefcolumn\@deferlist}%
  %   \if@twocolumn
  %     \if@firstcolumn
  %       \xdef\@dbldeferlist{\@dbltoplist\@dbldeferlist}%
  %       \global\let\@dbltoplist\@empty
  %       \global\@colht\textheight
  %       \begingroup
  %         \@dblfloatplacement
  %         \@makefcolumn\@dbldeferlist
  %         \@whilesw\if@fcolmade \fi{\@outputpage
  %                                   \@makefcolumn\@dbldeferlist}%
  %       \endgroup
  %     \else
  %       \vbox{}\clearpage
  %     \fi
  %   \fi
  % \else
  %   \setbox\@cclv\vbox{\box\@cclv\vfil}%
  %   \@makecol\@opcol
  %   \clearpage
  % \fi
}
\gdef\@doclearpage{\mem@doclearpage}

\newcommand*{\m@m@makecolfloats}{%
  \let\@elt\relax%
  \xdef\@freelist{\@freelist\@midlist}%
  \global\let\@midlist\@empty
  \@combinefloats}
\newcommand*{\m@m@makecoltext}{%
  \ifvbox\@kludgeins
    \@makespecialcolbox
  \else
    \setbox\@outputbox \vbox to\@colht{%
      \@texttop
      \dimen@ \dp\@outputbox
      \unvbox \@outputbox
      \vskip -\dimen@
      \@textbottom}%
  \fi}

\newcommand*{\m@m@makecolintro}{}

\newcommand*{\m@mopfootnote}{\setbox\@outputbox \vbox{%
  \boxmaxdepth\@maxdepth
  \@tempdima\dp\@cclv
  \unvbox\@cclv
  \vskip-\@tempdima
  \mem@if@flushbottomF\m@mopfn@bottom
  \vskip \skip\footins
  \color@begingroup
    \normalcolor
    \footnoterule
    \unvbox \footins
  \color@endgroup}}

\newcommand*{\m@mopfootnotebf}{%
  \setbox\@outputbox \vbox{%
  \boxmaxdepth\@maxdepth
  \unvbox\@outputbox
  \mem@if@flushbottomF\m@mopfn@bottom
  \vskip\skip\footins
  \color@begingroup
    \normalcolor
    \footnoterule
    \unvbox \footins
  \color@endgroup}}

\newcommand*{\m@mopsidebar}{%
  \ifvoid\sideins\else
    \setbox\@outputbox \vbox{%
      \sidecontents
      \unvbox\@outputbox}
  \fi}

 % \gdef\mem@makecol{%
 %   \m@m@makecolintro
 %   \ifvoid\footins
 %     \setbox\@outputbox \box\@cclv
 %   \else
 %     \m@mopfootnote
 %   \fi
 %   \m@mdoextrafeet
 %   \m@m@makecolfloats
 %   \m@mopsidebar
 %   \m@m@makecoltext
 %   \global \maxdepth \@maxdepth}

 % \gdef\mem@makecolbf{%
 %   \m@m@makecolintro
 %   \setbox\@outputbox \box\@cclv
 %   \m@m@makecolfloats
 %   \ifvoid\footins\else
 %     \m@mopfootnotebf
 %   \fi
 %   \m@mdoextrafeet
 %   \m@mopsidebar
 %   \m@m@makecoltext
 %   \global\maxdepth \@maxdepth}

\gdef\mem@makecoldblf{%
  \m@m@makecolintro
  \setbox\@outputbox \box\@cclv
  \m@m@makecolfloats
  \m@mopsidebar%    <- added
  \ifvoid\footins
  \else
    \m@mopfootnote
  \fi
  \m@mdoextrafeet
  \m@m@makecoltext
  \global \maxdepth \@maxdepth}

\newcommand{\feetabovefloat}{\gdef\@makecol{\mem@makecol}}
\newcommand{\feetbelowfloat}{\gdef\@makecol{\mem@makecolbf}}
\feetabovefloat

\newcommand\feetatbottom{\def\m@mopfn@bottom{\vfill\relax}}
\newcommand\feetbelowragged{\let\m@mopfn@bottom\relax}
\feetbelowragged
\newcommand\mem@if@flushbottomF[1]{%
  \if\mem@flshbot\else#1\fi%
}

 % \gdef\@reinserts{%
 % \ifvoid\footins\else\insert\footins{\unvbox\footins}\fi
 % \m@mdodoreinextrafeet
 % \ifvbox\@kludgeins\insert\@kludgeins{\unvbox\@kludgeins}\fi
 %  \ifvoid\sideins\else\insert\sideins{\unvbox\sideins}\fi}

\newif\ifm@mfnmargin
\newcommand*{\footnotesatfoot}{\m@mfnmarginfalse}
\newcommand*{\footnotesinmargin}{\m@mfnmargintrue}
\footnotesatfoot

\renewcommand{\@footnotetext}[1]{%
  \ifm@mfnmargin%   use marginpar
    \marginpar{%
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font
    \foottextfont
    \def\@currentcounter{footnote}%
    \protected@edef\@currentlabel{%
      \csname p@footnote\endcsname\@thefnmark}%
    \color@begingroup
      \@makefntext{\ignorespaces#1}%
    \color@endgroup}%
  \else% regular feet
    \insert\footins{%
    \def\baselinestretch{\m@m@footnote@spacing}%
    \reset@font
    \foottextfont
    \@preamfntext
    \hsize\columnwidth
    \def\@currentcounter{footnote}%
    \protected@edef\@currentlabel{%
      \csname p@footnote\endcsname\@thefnmark}%
    \color@begingroup
      \@makefntext{%
        \rule\z@\footnotesep\ignorespaces\foottextfont #1%
        \@finalstrut\strutbox}%
    \color@endgroup}%
  \fi%
  \m@mmf@prepare}
\let\@plainfootnotetext\@footnotetext

\newcommand*{\sidefootmargin}[1]{%
  \m@msetm@argin{#1}%
  \ifnum\m@mm@argin<\z@
    \@memwarn{Bad \string\sidefootmargin\space argument `#1'\MessageBreak
              set to `outer'}%
    \gdef\m@msidefoot@margin{2}%   set as outer
  \else
    \global\let\m@msidefoot@margin\m@mm@argin
  \fi}
\sidefootmargin{outer}

\newinsert\sidefootins
  \skip\sidefootins=0pt
  \count\sidefootins=0\relax

\newlength{\sidefootadjust}
  \setlength{\sidefootadjust}{0pt}
\newlength{\sidefootheight}
\newcommand*{\setsidefootheight}[1]{%
  \setlength{\dimen\sidefootins}{#1}%
  \advance\dimen\sidefootins -\topskip
  \advance\dimen\sidefootins \ht\strutbox
  \setlength{\sidefootheight}{\dimen\sidefootins}}
\setsidefootheight{\textheight}

\newlength{\sidefoothsep}
\newlength{\sidefootvsep}
\newlength{\sidefootwidth}

\newcommand*{\setsidefeet}[6]{%
  \nametest{#1}{*}\ifsamename\else
    \setlength{\sidefoothsep}{#1}\@memznegtest{\sidefoothsep}%
  \fi
  \nametest{#2}{*}\ifsamename\else
    \setlength{\sidefootwidth}{#2}\@memznegtest{\sidefootwidth}%
  \fi
  \nametest{#3}{*}\ifsamename\else
    \setlength{\sidefootvsep}{#3}\@memznegtest{\sidefootvsep}%
  \fi
  \nametest{#4}{*}\ifsamename\else
    \setlength{\sidefootadjust}{#4}%
  \fi
  \nametest{#5}{*}\ifsamename\else
    \def\sidefoottextfont{#5}%
  \fi
  \nametest{#6}{*}\ifsamename\else
    \setsidefootheight{#6}%
    \ifdim\dimen\sidefootins>\z@\else
      \@memerror{\protect\sidefootheight\space is zero or negative}{\@ehd}%
    \fi
  \fi}
\setsidefeet{\marginparsep}{\marginparwidth}%
            {\onelineskip}{0pt}%
            {\normalfont\footnotesize}{\textheight}%

\newcommand*{\sidefootform}{\rightskip=\z@ \@plus 2em}

\newcommand*{\m@sideft@left}{%
  \@tempdimc \sidefootwidth
  \advance\@tempdimc\sidefoothsep
  \kern-\@tempdimc}
\newcommand*{\m@sideft@right}{%
  \@tempdimc \columnwidth% or \hsize
  \advance\@tempdimc\sidefoothsep
  \kern\@tempdimc}

\newlength{\m@mdownsf}

\newcommand*{\sidefootcontents}{\hbox to \z@{%
  \m@mwhich@margin{\m@msidefoot@margin}%
  \ifmemtortm
    \m@sideft@right
  \else
    \m@sideft@left
  \fi
  \vtop to 0pt{%    original
    \normalsize\normalfont\sidefoottextfont
    \vskip\topskip \vskip-\ht\strutbox
    \vskip\sidefootadjust%    use this for minor vertical adjustment
    \m@mdownsf=\dimen\sidefootins
    \advance\m@mdownsf-\ht\sidefootins
    \advance\m@mdownsf-\dp\sidefootins
    \ifdim\m@mdownsf>\sidefootvsep
      \advance\m@mdownsf\sidefootvsep
      \advance\m@mdownsf 0.5\ht\strutbox
    \fi
    \vskip\m@mdownsf%     --- basically works
    \unvbox\sidefootins%
    \vss}%
  \hss}}

\newcommand*{\m@mopsidefoot}{%
  \ifvoid\sidefootins\else
    \setbox\@outputbox \vbox{%
      \sidefootcontents
      \unvbox\@outputbox}
  \fi}

\gdef\mem@makecol{%
  \m@m@makecolintro
  \ifvoid\footins
    \setbox\@outputbox \box\@cclv
  \else
    \m@mopfootnote
  \fi
  \m@mdoextrafeet
  \m@m@makecolfloats
  \m@mopsidebar
  \m@mopsidefoot
  \m@m@makecoltext
  \global \maxdepth \@maxdepth}

\IfFormatAtLeastTF{2021-06-01}{
  % adding to "hook" in footmisc
  \AddToHook{cmd/@makecol@appendblocks/after}{\m@mdoextrafeet\m@mopsidefoot\m@mopsidebar}
}{
  \AtBeginDocument{
    \@ifpackagelater{footmisc}{2011/06/07}{
      \@memerror{You seem to have manually updated both memoir and^^J
        footmisc on an older LaTeX kernel. Memoir is not compatible with
      footmisc^^J version 2022/02/14 v6.0b on LaTeX kernels from before
      2021/06/01. Please^^J update your LaTeX installation instead of
      manually updating classes^^J or packages}{Update your LaTeX installation}
    }{}
  }
}
\gdef\mem@makecolbf{%
  \m@m@makecolintro
  \setbox\@outputbox \box\@cclv
  \m@m@makecolfloats
  \ifvoid\footins
  \else
    \m@mopfootnotebf
  \fi
  \m@mdoextrafeet
  \m@mopsidebar
  \m@mopsidefoot
  \m@m@makecoltext
  \global \maxdepth \@maxdepth}

\gdef\@reinserts{%
  \ifvoid\footins\else\insert\footins{\unvbox\footins}\fi
  \m@mdodoreinextrafeet
  \ifvbox\@kludgeins\insert\@kludgeins{\unvbox\@kludgeins}\fi
  \ifvoid\sideins\else\insert\sideins{\unvbox\sideins}\fi
  \ifvoid\sidefootins\else\insert\sidefootins{\unvbox\sidefootins}\fi}

\renewcommand*{\@mem@testifnofoot}{%
  \@mem@nofoottrue
  \ifvoid\footins\else\@mem@nofootfalse\fi
  \ifvoid\footinsv@r\else\@mem@nofootfalse\fi
  \ifvoid\sideins\else\@mem@nofootfalse\fi
  \ifvoid\sidefootins\else\@mem@nofootfalse\fi
  \@mem@extranofeet}

\newcounter{sidefootnote}
  \renewcommand{\thesidefootnote}{\@arabic\c@sidefootnote}
\@addtoreset{sidefootnote}{chapter}


\newcommand*{\@sidempfn}{sidefootnote}
\newcommand*{\thesidempfn}{\thesidefootnote}

\newcommand*{\@makesidefnmark}{\hbox{\@textsuperscript{%
  \normalfont\@thesidefnmark}}}

\newcommand{\@preamsidefntext}{%
  \interlinepenalty\interfootnotelinepenalty
  \floatingpenalty \@MM
  \splittopskip=\footnotesep
  \splitmaxdepth=\dp\strutbox
  \@parboxrestore}

\newcommand{\@sidefootnotetext}[1]{\insert\sidefootins{%
  \hsize\sidefootwidth
  \@parboxrestore
    \def\baselinestretch{\m@m@footnote@spacing}%
  \sidefootform \normalsize\normalfont\sidefoottextfont
  \splittopskip=\ht\strutbox
  \splitmaxdepth=\dp\strutbox
  \allowbreak
  \prevdepth=\dp\strutbox
  \vskip-\parskip
  \def\@currentcounter{sidefootnote}%
  \protected@edef\@currentlabel{%
    \csname p@sidefootnote\endcsname\@thesidefnmark}%
\color@begingroup
\@makesidefntext{{\sidefoottextfont #1}}%
\color@endgroup
  \ifvmode\else
    \unskip\@finalstrut\strutbox
  \fi
  \par
  \ifdim\prevdepth>\dp\strutbox \prevdepth=\dp\strutbox\fi
  \ifdim\prevdepth>99\p@
    \nobreak
    \vskip-\prevdepth
    \allowbreak
    \vskip\dp\strutbox
  \fi
  \vskip\sidefootvsep}%
  \m@mmf@prepare}

\newcommand*{\@sidefootnotemark}{%
  \leavevmode
  \ifhmode
    \edef\@x@sf{\the\spacefactor}%
    \m@mmf@check
    \nobreak
  \fi
  \@makesidefnmark
  \m@mmf@prepare
  \ifhmode\spacefactor\@x@sf\fi
  \relax}

\newcommand*{\sidefootnote}{\@ifnextchar[
  \@xsidefootnote{\stepcounter\@sidempfn
  \protected@xdef\@thesidefnmark{\thesidempfn}%
  \@sidefootnotemark\@sidefootnotetext}}
\def\@xsidefootnote[#1]{%
  \begingroup
    \csname c@\@sidempfn\endcsname #1\relax
    \unrestored@protected@xdef\@thesidefnmark{\thesidempfn}%
  \endgroup
  \@sidefootnotemark\@sidefootnotetext}

\newcommand{\sidefootnotemark}{%
  \@ifnextchar[
    \@xsidefootnotemark
      {\stepcounter{sidefootnote}%
       \protected@xdef\@thesidefnmark{\thesidefootnote}%
       \@sidefootnotemark}}
\def\@xsidefootnotemark[#1]{%
  \begingroup
    \c@sidefootnote #1\relax
    \unrestored@protected@xdef\@thesidefnmark{\thesidefootnote}%
  \endgroup
  \@sidefootnotemark}

\newcommand*{\sidefootnotetext}{%
  \@ifnextchar[
    \@xsidefootnotetext
      {\protected@xdef\@thesidefnmark{\thesidempfn}%
       \@sidefootnotetext}}
\def\@xsidefootnotetext[#1]{%
  \begingroup
    \csname c@\@sidempfn\endcsname #1\relax
    \unrestored@protected@xdef\@thesidefnmark{\thesidempfn}%
  \endgroup
  \@sidefootnotetext}

\newcommand*{\sidefootmarkstyle}[1]{\def\sidefootscript##1{#1}}
\newcommand*{\makesidefootmarkhook}{}
\newcommand*{\sidefootfootmark}{%
  \ifdim\sidefootmarkwidth < \z@
    \llap{\hb@xt@ -\sidefootmarkwidth{%
          \hss\normalfont\sidefootscript{\@thesidefnmark}}%
         \hspace*{-\sidefootmarkwidth}}%
  \else
    \ifdim\sidefootmarkwidth = \z@
      {\normalfont\sidefootscript{\@thesidefnmark}}%
    \else
      \hb@xt@\sidefootmarkwidth{\hss\normalfont\sidefootscript{\@thesidefnmark}}%
    \fi
  \fi}

\newcommand{\makesidefootmark}[1]{%
  \leavevmode
  \parindent \sidefootparindent\noindent
  \leftskip\sidefootmarksep\relax
  \advance\leftskip \sidefootmarkwidth \null\nobreak\hskip -\leftskip\relax
  \makesidefootmarkhook\relax
  \sidefootfootmark #1}

\newcommand{\@makesidefntext}[1]{\makesidefootmark #1}

\newlength{\sidefootmarkwidth}
  \setlength{\sidefootmarkwidth}{0em}
\newlength{\sidefootmarksep}
  \setlength{\sidefootmarksep}{0em}
\newlength{\sidefootparindent}
  \setlength{\sidefootparindent}{1em}
\sidefootmarkstyle{\textsuperscript{#1}}

\newif\ifm@mpnpageopt
  \m@mpnpageoptfalse
\newif\ifm@mpncontopt
  \m@mpncontoptfalse
\newcounter{pagenote}[chapter]
\renewcommand{\thepagenote}{\arabic{pagenote}}
\setcounter{pagenote}{0}

\newcommand*{\notepageref}{\m@mpnpageopttrue}
\@onlypreamble\notepageref
\newcommand*{\continuousnotenums}{%
  \counterwithout{pagenote}{chapter}
  \renewcommand{\thepagenote}{\arabic{pagenote}}}
\@onlypreamble\continuousnotenums

\newif\ifmempagenotes
  \mempagenotesfalse

\newcommand*{\makepagenote}{%
  \newwrite\@notefile
  \immediate\openout\@notefile=\jobname.ent
  \mempagenotestrue
  \DeclareRobustCommand\pagenote{\@bsphack\begingroup
    \rem@special{\ }% <--- added
    \@sanitize
    \m@m@wrpnote}%
  \DeclareRobustCommand\mem@footto@pagenote{\@bsphack\begingroup
    \rem@special{\ }% <--- added
    \@sanitize
    \def\mem@pn@step{01}%
    \m@m@wrpnote}%
  \typeout{Writing note file \jobname.ent}%
  \let\makepagenote\@empty}

\providecommand{\immediate@protected@write}[3]{%
  \begingroup
  #2%
  \let\protect\@unexpandable@protect
  %\edef\reserved@a{\immediate\write#1{#3}}%
  %\reserved@a
  \immediate\write#1{#3}%
  \endgroup
  %\if@nobreak\ifvmode\nobreak\fi\fi%
}

\newcommand{\m@m@pnwrite}[3]{\immediate\write#1{#3}}
\newcommand{\m@m@pnwrited}[3]{\immediate\write#1{\detokenize{#3}\@percentchar}}

\newcommand*{\pnchap}{\f@rtoc}
\newcommand*{\pnschap}{\f@rbdy}

\newcounter{pagenoteshadow}
  \setcounter{pagenoteshadow}{0}
\newcommand\mem@pn@step{00} % i.e. true
\newlength\mem@pn@lastkern
\newcommand\m@m@pnwrite@fourtharg[1]{\m@m@pnwrited\@notefile{}{{}}}
\newcommand\m@m@pnwrite@fourtharg@hyperref[1]{%
  \@ifmtarg{#1}{%
    \m@m@pnwrite\@notefile{}{{\Hy@pagenote@currentHref}}%
  }{%
    \m@m@pnwrited\@notefile{}{{}}%
  }}

\newcommand{\m@m@wrpnote}[2][]{%
  \mem@pn@lastkern=\lastkern%
  \refstepcounter{pagenoteshadow}%
  \ifm@mpnpageopt%
    \phantomsection%
    \label{pagenote\thepagenoteshadow-\thesheetsequence}%
  \fi%
  \if\mem@pn@step%
    \@ifmtarg{#1}{\refstepcounter{pagenote}%
      % this enables the ^{1,2} feature
      \ifdim\mem@pn@lastkern=\multiplefootnotemarker%
        \m@mmf@prepare% rerun
      \fi%
      \mem@pn@multiple@marker{\notenumintext{\thepagenote}}%
    }{\m@mmf@prepare}%
  \fi%
  \ifm@mpn@new@chap%
    \global\m@mpn@new@chapfalse%
    \addtonotes{\string\pagenotesubhead{\@chapapp}{\thechapter}{\pnchap}}%
  \fi%
  \ifm@mpn@new@schap%
    \global\m@mpn@new@schapfalse%
    \addtonotes{\string\pagenotesubheadstarred{\@chapapp}{}{\pnschap}}%
  \fi%
  \m@m@pnwrite\@notefile{}%
    {\string\startnoteentry{\thepagenote}}%
  \m@m@pnwrited\@notefile{}{{#1}}%
  \m@m@pnwrite\@notefile{}%
    {{pagenote\thepagenoteshadow-\thesheetsequence}}%
  \m@m@pnwrite@fourtharg{#1}%
  \begingroup%
    \newlinechar='40%
    \m@m@pnwrited\@notefile{}{#2}%
  \endgroup%
  \m@m@pnwrite\@notefile{}%
  {\string\endnoteentry}%
  \endgroup%
  \@esphack}

\def\pagenote{\@bsphack\begingroup \@sanitize\m@m@pagenote}
\let\mem@footto@pagenote\pagenote
\newcommand{\m@m@pagenote}[2][]{\endgroup\@esphack}

\newcommand*{\pagetofootnote}{%
  \let\memsavepagenote\pagenote
  \renewcommand{\pagenote}[2][]{\footnote{##2}}
  \ifmempagenotes\else%
    \AtEndDocument{%
      \ifmempagenotes%
      \@memerror{The use of \string\pagetofootnote\space before
        \string\makepagenote\space^^Jdoes not make
        sense. \string\makepagenote\space make some redefinitions that
        are not picked up if \string\pagetofootnote\space is issued
        before \string\makepagenote
      }{}
    \fi
   }
   \fi
}
\newcommand*{\foottopagenote}{%
  \let\memsavefootnote\footnote
  \counterwithout{footnote}{chapter}
  \letcountercounter{footnote}{pagenote}
  \renewcommand\footnotetext[2][]{\mem@footto@pagenote{##2}}
  \renewcommand{\footnote}[2][]{\pagenote{##2}}
}

\newcommand{\addtonotes}[1]{\ifmempagenotes
 \IfFileExists{\jobname.ent}{\immediate@protected@write\@notefile{}{#1}}{\mempnofilewarn}%
\fi}

\newcommand{\notenumintext}[1]{%
  \textsuperscript{#1}}
\newcommand{\notenuminnotes}[1]{%
  {\normalfont #1.}\space}
 %\newcommand{\noteentry}[4]{} % not used any more!

\newcommand{\idtextinnotes}[1]{%
  [#1]\space}
\newcommand{\noteidinnotes}[2]{%
  \@ifmtarg{#2}{%
    \notenuminnotes{#1}}{\idtextinnotes{#2}}}
\newcommand{\pageinnotes}[1]{%
  \ifm@mpnpageopt \printpageinnotes{#1}\fi}
\newcommand*{\printpageinnotes}[1]{%
  (\pagerefname\ \pageref{#1})\space}
\newcommand\printpageinnoteshyperref[1]{%
(\hyperref[#1]{\pagerefname\ \pageref*{#1}})\space}
\newcommand{\noteinnotes}[1]{#1} % not used anymore!

\newcommand{\prenoteinnotes}{\par\noindent}
\newcommand{\postnoteinnotes}{\par}

\newcommand\prenotetext{}
\newcommand\postnotetext{}

\providecommand*{\notesname}{Notes}
\newcommand*{\notedivision}{\chapter{\notesname}}

\newcommand*{\printpagenotes}{\@ifstar{\mem@printpagenotes{00}}{\mem@printpagenotes{01}}}
\newcommand*{\mempnofilewarn}{%
  \ClassWarning{memoir}{There is no .ent file}}

\newcommand\startnoteentrystart[4]{% number; manual id; auto label; href anchor
  \prenoteinnotes%
  \noteidinnotes{#1}{#2}%
  \phantomsection%
  \@ifmtarg{#2}{\def\@currentlabel{#1}}{\def\@currentlabel{#2}}%
  \def\@currentcounter{pagenote}%
  \pagenoteanchor{#4}%
  \pageinnotes{#3}%
  \prenotetext%
}
\def\endnoteentryend{\postnotetext\postnoteinnotes}
\let\pagenoteanchor\@gobble
\newcommand\pagenotehyperanchor[1]{%
  \expandafter\@ifmtarg\expandafter{#1}{}{%
    \Hy@raisedlink{\hyper@@anchor{#1}{\relax}}}}%

\newcommand\mem@printpagenotes[1]{%
  \ifmempagenotes
    \notedivision
    \IfFileExists{\jobname.ent}{%
      \begingroup
      \long\def\startnoteentry####1####2####3####4{%
        \begingroup
        \startnoteentrystart{####1}{####2}{####3}{####4}%
      }
      \long\def\endnoteentry{\endnoteentryend\endgroup}
      \immediate\closeout\@notefile
      \input{\jobname.ent}%
      \if#1\immediate\openout\@notefile=\jobname.ent\fi%
      \endgroup
    }{%
      \mempnofilewarn
    }%
  \fi%
}

 % \newcommand*{\@sprintpagenotes}{%
 %   \ifmempagenotes
 %   \notedivision
 % \IfFileExists{\jobname.ent}{%
 %   \immediate\closeout\@notefile
 %   \input{\jobname.ent}%
 %   \immediate\openout\@notefile=\jobname.ent%
 %   }{%
 %   \mempnofilewarn
 % }%
 % \fi}

 % \newcommand*{\@printpagenotes}{%
 %   \ifmempagenotes
 %     \notedivision
 %     \IfFileExists{\jobname.ent}{%
 %       \immediate\closeout\@notefile
 %       \input{\jobname.ent}%
 %      }{%
 %        \mempnofilewarn
 %      }
 %   \fi}

\newcommand*{\pagenotesubhead}[3]{%
  \section*{#1 #2 #3}}
\newcommand\pagenotesubheadstarred{\pagenotesubhead}
\newif\ifchangemarks\changemarksfalse
\newcommand*{\changemarks}{\changemarkstrue}
\newcommand*{\nochangemarks}{\changemarksfalse}

\newcommand{\v@rid}[2]{%
  \@bsphack
  \ifchangemarks
     \ifdraftdoc
       \marginpar[#1]{#2}%
  \fi\fi
  \@esphack}

\newcommand{\added}[1]{%
  \@bsphack
  \ifchangemarks
    \v@rid{\small$\oplus$ #1}{\small$\oplus$ #1}%
  \fi
  \@esphack}
\newcommand{\deleted}[1]{%
  \@bsphack
  \ifchangemarks
    \v@rid{\small$\neq$ #1}{\small$\neq$ #1}%
  \fi
  \@esphack}
\newcommand{\changed}[1]{%
  \@bsphack
  \ifchangemarks
    \v@rid{\small$\Leftrightarrow$ #1}{\small$\Leftrightarrow$ #1}%
  \fi
  \@esphack}

\newcommand*{\showtrimsoff}{\showtrimsfalse}
\newcommand*{\showtrimson}{\showtrimstrue}

\newcommand*{\trimmark}{%
  \begin{picture}(0,0)
    \unitlength 1cm
    \thinlines
    \put(-2,0){\line(1,0){4}}
    \put(0,-2){\line(0,1){4}}
  \end{picture}}

\newcommand*{\Ltrimpictl}{%
  \begin{picture}(0,0)
    \unitlength 1mm
    \thinlines
    \put(-2,0){\line(-1,0){18}}
    \put(0,2){\line(0,1){18}}
  \end{picture}}
\newcommand*{\Ltrimpictr}{%
  \begin{picture}(0,0)
    \unitlength 1mm
    \thinlines
    \put(2,0){\line(1,0){18}}
    \put(0,2){\line(0,1){18}}
  \end{picture}}
\newcommand*{\Ltrimpicbl}{%
  \begin{picture}(0,0)
    \unitlength 1mm
    \thinlines
    \put(-2,0){\line(-1,0){18}}
    \put(0,-2){\line(0,-1){18}}
  \end{picture}}
\newcommand*{\Ltrimpicbr}{%
  \begin{picture}(0,0)
    \unitlength 1mm
    \thinlines
    \put(2,0){\line(1,0){18}}
    \put(0,-2){\line(0,-1){18}}
  \end{picture}}

\newcommand*{\Ftrimpicbl}{%
  \begin{picture}(0,0)
    \unitlength 1pt
    \thinlines
    \put(0,0){\framebox(\strip@pt\paperwidth,\strip@pt\paperheight){}}
  \end{picture}}

\newcommand*{\tmarktl}{\trimmark}
\newcommand*{\tmarktr}{\trimmark}
\newcommand*{\tmarkbl}{\trimmark}
\newcommand*{\tmarkbr}{\trimmark}

\newcommand*{\tmarktm}{%
  \begin{picture}(0,0)%
    \unitlength 1mm
    \thinlines
    \put(0,2){\line(0,1){10}}
  \end{picture}}
\newcommand*{\tmarkml}{%
  \begin{picture}(0,0)%
    \unitlength 1mm
    \thinlines
    \put(-2,0){\line(-1,0){10}}
  \end{picture}}
\newcommand*{\tmarkmr}{%
  \begin{picture}(0,0)%
    \unitlength 1mm
    \thinlines
    \put(2,0){\line(1,0){10}}
  \end{picture}}
\newcommand*{\tmarkbm}{%
  \begin{picture}(0,0)%
    \unitlength 1mm
    \thinlines
    \put(0,-12){\line(0,1){10}}
  \end{picture}}

\newcommand*{\trimXmarks}{%
  \let\tmarktl\trimmark
  \let\tmarktr\trimmark
  \let\tmarkbl\trimmark
  \let\tmarkbr\trimmark}
\newcommand*{\trimLmarks}{%
  \let\tmarktl\Ltrimpictl
  \let\tmarktr\Ltrimpictr
  \let\tmarkbl\Ltrimpicbl
  \let\tmarkbr\Ltrimpicbr}
\newcommand*{\trimFrame}{%
  \let\tmarktl\null
  \let\tmarktr\null
  \let\tmarkbl\Ftrimpicbl
  \let\tmarkbr\null}
\newcommand*{\trimNone}{%
  \let\tmarktl\relax
  \let\tmarktr\relax
  \let\tmarkbl\relax
  \let\tmarkbr\relax
  \let\tmarktm\relax
  \let\tmarkml\relax
  \let\tmarkmr\relax
  \let\tmarkbm\relax}

\newcommand*\trimmarkscolor{}
\newcommand\mem@trimmarks@initial@vskip{\vskip-1in}
\newcommand\mem@trimmarks@initial@hskip{\hskip-1in}
\newcommand*{\trimmarks}{%
  \vbox to \z@{%
    \mem@trimmarks@initial@vskip%
    \vskip\trimtop % top of logical page
    \hb@xt@\z@{%
      \mem@trimmarks@initial@hskip%
      \ifodd\c@page
        \hskip\stockwidth
        \hskip-\trimedge
        \hskip-\paperwidth
      \else
        \if@twoside
          \hskip\trimedge  % left of logical page
        \else
          \hskip\stockwidth
          \hskip-\trimedge
          \hskip-\paperwidth
        \fi
      \fi
      \vbox to \paperheight{%
        \let\protect\relax        % <- v1.4 addition
        \hb@xt@\paperwidth{\trimmarkscolor\tmarktl\hfil\tmarktm\hfil\tmarktr}%
        \vfil
        \hb@xt@\paperwidth{\trimmarkscolor\tmarkml\hfil\tmarkmr}%
        \vfil
        \hb@xt@\paperwidth{\trimmarkscolor\tmarkbl\hfil\tmarkbm\hfil\tmarkbr}}%
      \hss}%
    \vss}}

\newcommand*{\registrationColour}[1]{#1}
\newcommand*{\quarkmarks}{%
\renewcommand*{\tmarktl}{\registrationColour{%
  \begin{picture}(0,0)
    \setlength{\unitlength}{1bp}\thicklines
    \put(-36,0){\line(1,0){24}}
    \put(0,12){\line(0,1){24}}
    \put(3,27){\normalfont\ttfamily\fontsize{8bp}{10bp}\selectfont\jobname\ \
      \today\ \ \printtime\ \ Page \thepage}
  \end{picture}}}
\renewcommand*{\tmarktm}{\registrationColour{%
  \begin{picture}(0,0)
    \setlength{\unitlength}{1bp}\thicklines
    \put(-24,24){\line(1,0){48}}
    \put(0,12){\line(0,1){24}}
    \put(0,24){\oval(12,12)}
  \end{picture}}}
\renewcommand*{\tmarktr}{\registrationColour{%
  \begin{picture}(0,0)
    \setlength{\unitlength}{1bp}\thicklines
    \put(12,0){\line(1,0){24}}
    \put(0,12){\line(0,1){24}}
  \end{picture}}}
\renewcommand*{\tmarkmr}{\registrationColour{%
  \begin{picture}(0,0)
    \setlength{\unitlength}{1bp}\thicklines
    \put(12,0){\line(1,0){24}}
    \put(24,-24){\line(0,1){48}}
    \put(24,0){\oval(12,12)}
  \end{picture}}}
\renewcommand*{\tmarkbr}{\registrationColour{%
  \begin{picture}(0,0)
    \setlength{\unitlength}{1bp}\thicklines
    \put(12,0){\line(1,0){24}}
    \put(0,-36){\line(0,1){24}}
  \end{picture}}}
\renewcommand*{\tmarkbm}{\registrationColour{%
  \begin{picture}(0,0)
    \setlength{\unitlength}{1bp}\thicklines
    \put(-24,-24){\line(1,0){48}}
    \put(0,-36){\line(0,1){24}}
    \put(0,-24){\oval(12,12)}
  \end{picture}}}
\renewcommand*{\tmarkbl}{\registrationColour{%
  \begin{picture}(0,0)
    \setlength{\unitlength}{1bp}\thicklines
    \put(-36,0){\line(1,0){24}}
    \put(0,-36){\line(0,1){24}}
  \end{picture}}}
\renewcommand*{\tmarkml}{\registrationColour{%
  \begin{picture}(0,0)
    \setlength{\unitlength}{1bp}\thicklines
    \put(-36,0){\line(1,0){24}}
    \put(-24,-24){\line(0,1){48}}
    \put(-24,0){\oval(12,12)}
  \end{picture}}}
%% \renewcommand*{\trimmarks}{%
%% %%  \special{papersize=\the\stockwidth,\the\stockheight}
%%   {%
%%   \vbox to \z@{\vskip-1in \vskip\trimtop % top of logical page
%%     \hb@xt@\z@{\hskip-1in
%%       \ifodd\c@page
%%         \hskip\stockwidth \hskip-\trimedge \hskip-\paperwidth
%%       \else
%%         \if@twoside
%%           \hskip\trimedge % left of logical page
%%         \else
%%           \hskip\stockwidth \hskip-\trimedge \hskip-\paperwidth
%%         \fi
%%       \fi
%%       \vbox to \paperheight{%
%%         \let\protect\relax %      <- v1.4 addition
%%         \hb@xt@\paperwidth{\trimmarkscolor\tmarktl\hfil\tmarktm\hfil\tmarktr}%
%%         \vfil
%%         \hb@xt@\paperwidth{\trimmarkscolor\tmarkml\hfil\tmarkmr}%
%%         \vfil
%%         \hb@xt@\paperwidth{\trimmarkscolor\tmarkbl\hfil\tmarkbm\hfil\tmarkbr}}%
%%       \hss}%
%%     \vss}}%
%%   }
}

\IfFormatAtLeastTF{2020/10/01}{
  \renewcommand\mem@trimmarks@initial@vskip{}
  \renewcommand\mem@trimmarks@initial@hskip{}
  \ifshowtrims
    \AddToHook{shipout/background}[./trimmarks]{\ifshowtrims\put(0,0){\trimmarks}\fi}
  \fi
}{
  \let\mem@oldshipout\shipout
  \newcommand*{\mem@shipi}{%
    \ifvoid\@cclv\expandafter\aftergroup\fi\mem@shipii}
  \newcommand*\mem@shipii{%
    \ifvoid\@cclv
      \mem@oldshipout\box\@cclv
    \else
      \ifshowtrims
      \mem@oldshipout\vbox{%
          \trimmarks
          \nointerlineskip
          \box\@cclv
       }%
      \else
        \mem@oldshipout\box\@cclv
      \fi
    \fi}
  \ifshowtrims
    \renewcommand*{\shipout}{\afterassignment\mem@shipi\setbox\@cclv=}
  \fi
} % end format check, else part

\newtoks\every@verbatim
  \every@verbatim={}
\newtoks\afterevery@verbatim
  \afterevery@verbatim={}

\def\@makeother#1{\catcode`#112\relax}
\begingroup
 \catcode`\ =\active%
 \def\x{\def\@vobeyspaces{\catcode`\ \active\let \@xobeysp}}
 \expandafter\endgroup\x
\def\@xobeysp{\leavevmode\penalty\@M\ }
\newtoks\verbatim@line
\newcount\tab@position
\def\@xobeytab{%
  \loop
    \toks@\expandafter{\the\toks@\@xobeysp}%
    \advance\tab@position-1
  \ifnum\tab@position>0 \repeat
}
\begingroup
  \catcode`\^^I=\active
  \gdef\@vobeytabs{\catcode`\^^I\active\let^^I\@xobeytab}%
\endgroup
\def\verbatim@tabexpand#1{%
  \ifx#1\@nil
    \the\toks@
    \expandafter\par
  \else
    \ifx#1\@xobeytab
      \@xobeytab
    \else
      \toks@\expandafter{\the\toks@#1}%
      \advance\tab@position\m@ne
    \fi
    \ifnum\tab@position=0 \tab@position\tab@size \fi
    \expandafter\verbatim@tabexpand
  \fi
}

\newif\ift@bs
\newcommand{\tabson}[1][4]{%
  \ifnum\@ne > #1\relax
    \tabsoff
  \else
    \t@bstrue
    \def\tab@size{#1\relax}%
    \def\@maybeobeytabs{\@vobeytabs}%
  \fi
}
\newcommand{\tabsoff}{%
  \t@bsfalse
  \def\tab@size{\z@}%
  \def\@maybeobeytabs{}%
}
\tabsoff

\def\tabverbatim@processline{\tab@position\tab@size
  \toks@{}%
  \expandafter\verbatim@tabexpand\the\verbatim@line\@nil}
\def\notabverbatim@processline{\the\verbatim@line\par}

\def\verbatim@startline{\verbatim@line{}}
\def\verbatim@addtoline#1{%
  \verbatim@line\expandafter{\the\verbatim@line#1}}
\def\verbatim@processline{\notabverbatim@processline}
\def\verbatim@finish{\ifcat$\the\verbatim@line$\else
  \verbatim@processline\fi}
\newcommand{\setverbatimfont}[1]{\def\m@mverbfont{#1}}
\setverbatimfont{\normalfont\ttfamily}

\def\verbatim@font{\m@mverbfont
                   \hyphenchar\font\m@ne
                   \@noligs}

\def\@verbatim{\the\every@verbatim
  \trivlist \item \relax
  \if@minipage\else\vskip\parskip\fi
  \@beginparpenalty \predisplaypenalty
%%%  \leftskip\@totalleftmargin\rightskip\z@
  \memRTLleftskip\@totalleftmargin\memRTLrightskip\z@
  \parindent\z@\parfillskip\@flushglue\parskip\z@
  \@@par
  \def\par{%
    \if@tempswa
      \leavevmode\null\@@par\penalty\interlinepenalty
    \else
      \@tempswatrue
      \ifhmode\@@par\penalty\interlinepenalty\fi
    \fi}%
  \def\@noitemerr{\@warning{No verbatim text}}%
  \obeylines
  \let\do\@makeother \dospecials
  \verbatim@font
  \everypar \expandafter{\the\everypar \unpenalty}%
  \wrapright\the\afterevery@verbatim}
\def\verbatim{\begingroup
  \ift@bs
    \def\verbatim@processline{\tabverbatim@processline}%
  \fi
  \@verbatim \frenchspacing\@vobeyspaces\@maybeobeytabs\verbatim@start}
\@namedef{verbatim*}{\begingroup
  \ift@bs
    \def\verbatim@processline{\tabverbatim@processline}%
  \fi
  \@verbatim\@maybeobeytabs\verbatim@start}
\def\endverbatim{\endtrivlist\endgroup\@doendpe}
\@namelet{endverbatim*}\endverbatim

\newcommand{\setupcomment}{%
  \let\do\@makeother\dospecials\catcode`\^^M\active
  \let\verbatim@startline\relax
  \let\verbatim@addtoline\@gobble
  \let\verbatim@processline\relax
  \let\verbatim@finish\relax}
\newcommand{\newcomment}[1]{%
  \expandafter\def\csname #1\endcsname{\@bsphack\setupcomment\verbatim@}%
  \expandafter\let\csname end#1\endcsname=\@esphack}
\newcommand{\commentsoff}[1]{%
  \expandafter\def\csname #1\endcsname{}%
  \expandafter\def\csname end#1\endcsname{}}
\newcommand{\commentson}[1]{\newcomment{#1}}

\newcomment{comment}

\@ifundefined{vrb@catcodes}%
  {\def\vrb@catcodes{%
     \catcode`\!12\catcode`\[12\catcode`\]12}}{}
\begingroup
 \vrb@catcodes
 \lccode`\!=`\\ \lccode`\[=`\{ \lccode`\]=`\}
 \catcode`\~=\active \lccode`\~=`\^^M
 \lccode`\C=`\C
 \lowercase{\endgroup
    \def\verbatim@start#1{%
      \verbatim@startline
      \if\noexpand#1\noexpand~%
        \let\next\verbatim@
      \else \def\next{\verbatim@#1}\fi
      \next}%
    \def\verbatim@#1~{\verbatim@@#1!end\@nil}%
    \def\verbatim@@#1!end{%
       \verbatim@addtoline{#1}%
       \futurelet\next\verbatim@@@}%
    \def\verbatim@@@#1\@nil{%
       \ifx\next\@nil
         \verbatim@processline
         \verbatim@startline
         \let\next\verbatim@
       \else
         \def\@tempa##1!end\@nil{##1}%
         \@temptokena{!end}%
         \def\next{\expandafter\verbatim@test\@tempa#1\@nil~}%
       \fi \next}%
    \def\verbatim@test#1{%
           \let\next\verbatim@test
           \if\noexpand#1\noexpand~%
             \expandafter\verbatim@addtoline
               \expandafter{\the\@temptokena}%
             \verbatim@processline
             \verbatim@startline
             \let\next\verbatim@
           \else \if\noexpand#1
             \@temptokena\expandafter{\the\@temptokena#1}%
           \else \if\noexpand#1\noexpand[%
             \let\@tempc\@empty
             \let\next\verbatim@testend
           \else
             \expandafter\verbatim@addtoline
               \expandafter{\the\@temptokena}%
             \def\next{\verbatim@#1}%
           \fi\fi\fi
           \next}%
    \def\verbatim@testend#1{%
         \if\noexpand#1\noexpand~%
           \expandafter\verbatim@addtoline
             \expandafter{\the\@temptokena[}%
           \expandafter\verbatim@addtoline
             \expandafter{\@tempc}%
           \verbatim@processline
           \verbatim@startline
           \let\next\verbatim@
         \else\if\noexpand#1\noexpand]%
           \let\next\verbatim@@testend
         \else\if\noexpand#1\noexpand!%
           \expandafter\verbatim@addtoline
             \expandafter{\the\@temptokena[}%
           \expandafter\verbatim@addtoline
             \expandafter{\@tempc}%
           \def\next{\verbatim@!}%
         \else \expandafter\def\expandafter\@tempc\expandafter
           {\@tempc#1}\fi\fi\fi
         \next}%
    \def\verbatim@@testend{%
       \ifx\@tempc\@currenvir
         \verbatim@finish
         \edef\next{\noexpand\end{\@currenvir}%
                    \noexpand\verbatim@rescan{\@currenvir}}%
       \else
         \expandafter\verbatim@addtoline
           \expandafter{\the\@temptokena[}%
           \expandafter\verbatim@addtoline
             \expandafter{\@tempc]}%
         \let\next\verbatim@
       \fi
       \next}%
    \def\verbatim@rescan#1#2~{\if\noexpand~\noexpand#2~\else
        \@warning{Characters dropped after `\string\end{#1}'}\fi}}
\newread\verbatim@in@stream
\def\verbatim@readfile#1{%
  \verbatim@startline
  \openin\verbatim@in@stream #1\relax
  \ifeof\verbatim@in@stream
    \typeout{No file #1.}%
  \else
    \@addtofilelist{#1}%
    \ProvidesFile{#1}[(verbatim)]%
    \expandafter\endlinechar\expandafter\m@ne
    \expandafter\verbatim@read@file
    \expandafter\endlinechar\the\endlinechar\relax
    \closein\verbatim@in@stream
  \fi
  \verbatim@finish
}
\def\verbatim@read@file{%
  \read\verbatim@in@stream to\next
  \ifeof\verbatim@in@stream
  \else
    \expandafter\verbatim@addtoline\expandafter{\next}%
    \verbatim@processline
    \verbatim@startline
    \expandafter\verbatim@read@file
  \fi
}
\def\verbatiminput{\begingroup
  \ift@bs
    \def\verbatim@processline{\tabverbatim@processline}%
  \fi
  \@ifstar{\verbatim@input{\@maybeobeytabs}}%
          {\verbatim@input{\frenchspacing\@vobeyspaces\@maybeobeytabs}}}
\def\verbatim@input#1#2{%
   \IfFileExists {#2}{\@verbatim #1\relax
    \verbatim@readfile{\@filef@und}\endtrivlist\endgroup\@doendpe}%
   {\typeout {No file #2.}\endgroup}}
\newlength{\verbatimindent}
  \setlength{\verbatimindent}{3em}
\newcommand*{\verbatimbreakchar}{\char`\%}
\newcommand*{\setverbatimbreak}{%
  \vspace*{-\baselineskip}%
  \def\@xobeysp{~\discretionary{\verbatimbreakchar}%
    {\kern\verbatimindent}{}}%
}

\newcommand*{\raggedwrap}{%
  \@rightskip\@flushglue
%%%  \rightskip\@rightskip
  \memRTLrightskip\@rightskip
%%%  \leftskip\@totalleftmargin
  \memRTLleftskip\@totalleftmargin
  \parindent\ragrparindent}
\newcommand*{\wrappingon}{%
  \def\@xobeysp{~\discretionary{\verbatimbreakchar}%
    {\kern\verbatimindent}{}}%
  \def\wrapright{\raggedwrap}}
\newcommand*{\wrappingoff}{%
  \def\@xobeysp{\leavevmode\penalty\@M\ }%
  \def\wrapright{}}
\wrappingoff

\newwrite \verbatim@out
\def\verbatimoutput#1{%
  \@bsphack
  \immediate\openout \verbatim@out #1
  \let\do\@makeother\dospecials
  \catcode`\^^M\active %% \catcode`\^^I=12
  \def\verbatim@processline{%
    \immediate\write\verbatim@out
      {\the\verbatim@line}}%
  \verbatim@start}
\def\endverbatimoutput{%
  \immediate\closeout\verbatim@out
  \@esphack}
\def\fboxverbatim{\begingroup%
  \tabsoff %% PW otherwise box fills the width
  \def\verbatim@processline{%
    {\setbox0=\hbox{\the\verbatim@line}%
    \hsize=\wd0 \the\verbatim@line\par}}%
  \@minipagetrue%%%DPC%%%
  \@tempswatrue%%%DPC%%%
  \setbox0=\vbox\bgroup \verbatim
}
\def\endfboxverbatim{%
  \endverbatim
  \unskip\setbox0=\lastbox %%%DPC%%%
  \egroup
  \fbox{\box0}% <<<=== change here for centering,...
\endgroup}
\def\MakeShortVerb#1{%
  \expandafter\ifx\csname cc\string#1\endcsname\relax
    \@shortvrbinfo{Made }{#1}%
    \add@special{#1}%
    \expandafter
    \xdef\csname cc\string#1\endcsname{\the\catcode`#1}%
    \begingroup
      \catcode`\~\active  \lccode`\~`#1%
      \lowercase{%
      \global\expandafter\let
         \csname ac\string#1\endcsname~%
      \gdef~{\verb~}}%
    \endgroup
    \global\catcode`#1\active
  \else
    \@shortvrbinfo\@empty{#1 already}%
  \fi}
\def\DeleteShortVerb#1{%
  \expandafter\ifx\csname cc\string#1\endcsname\relax
  \else
    \@shortvrbinfo{Deleted }{#1 as}%
    \rem@special{#1}%
    \global\catcode`#1\csname cc\string#1\endcsname
    \global \expandafter\let \csname cc\string#1\endcsname \relax
    \ifnum\catcode`#1=\active
      \begingroup
        \catcode`\~\active   \lccode`\~`#1%
        \lowercase{%
          \global\expandafter\let\expandafter~%
          \csname ac\string#1\endcsname}%
      \endgroup \fi \fi}
\def\@shortvrbinfo#1#2{%
  \ClassInfo{memoir}{%
     #1\expandafter\@gobble\string#2 a short reference
                                          for \string\verb}}
\def\add@special#1{%
  \rem@special{#1}%
  \expandafter\gdef\expandafter\dospecials\expandafter
    {\dospecials \do #1}%
  \expandafter\gdef\expandafter\@sanitize\expandafter
    {\@sanitize \@makeother #1}}
\def\rem@special#1{%
  \def\do##1{%
    \ifnum`#1=`##1 \else \noexpand\do\noexpand##1\fi}%
  \xdef\dospecials{\dospecials}%
  \begingroup
    \def\@makeother##1{%
      \ifnum`#1=`##1 \else \noexpand\@makeother\noexpand##1\fi}%
    \xdef\@sanitize{\@sanitize}%
  \endgroup}
\def\boxverbflag{14 }
\newlength{\bvboxsep}      % user can change this
\setlength{\bvboxsep}{1em}

\newif\ifbvperpage % start/end lines on every page of multipage verbatim
\bvperpagetrue

\newcommand{\bvtopofpage}[1]{%
  \long\def\b@vtop{#1}}
\def\b@vtop{}  % used in \boxverb@split for heading

\newcounter{memfbvline}
  \c@memfbvline=\z@
\newcounter{bvlinectr}
\newcommand*{\setbvlinenums}[2]{%
  \c@bvlinectr #1\relax \advance\c@bvlinectr \m@ne
  \ifnum\z@<\linemodnum%   we are printing line numbers
    \@tempcnta #2\relax
    \divide\@tempcnta\linemodnum
    \multiply\@tempcnta\linemodnum
    \c@memfbvline #2\relax
    \advance\c@memfbvline-\@tempcnta
  \fi}

\def\theb@vlinenumber{\getthelinenumber{bvlinectr}{memfbvline}}
\newcommand*{\resetbvlinenumber}{\setcounter{bvlinectr}{0}}

\def\b@vdocount{\ifbvcountlines\stepcounter{bvlinectr}\fi}
\newlength{\bvnumlength}
%% \settowidth{\bvnumlength}{\vlvnumfont 9999}
\settowidth{\bvnumlength}{\normalfont 999}

\newif\ifbvcountinside  % TRUE if line numbers inside box
  \bvcountinsidetrue
\newcommand*{\bvnumbersinside}{\bvcountinsidetrue}
\newcommand*{\bvnumbersoutside}{\bvcountinsidefalse}

\def\b@vdoinside{%
  \ifbvcountlines\ifbvcountinside%
    \makebox[\bvnumlength][r]{%
      \vlvnumfont \theb@vlinenumber\space}%
  \fi\fi}

\def\b@vdooutside{%
  \ifbvcountlines\ifbvcountinside\else%
    \llap{\makebox[\bvnumlength][r]{%
      \vlvnumfont \theb@vlinenumber\space}}%
  \fi\fi}

\newcommand*{\@@m@mline}{\hb@xt@\linewidth}

\newcommand{\setupboxverb@line}{%
  \par
  \ifbvperpage
    \output=\expandafter{\expandafter\boxverb@split \the\output}
  \fi
  \def\verbatim@processline{\leavevmode
    \b@vdocount%
    \bvleftsidehook\vbox{\advance% \hsize-.8\p@ \@@line % changed to \linewidth
                                 \linewidth-.8\p@ \@@line
      {\b@vdooutside\strut\kern\bvboxsep%
       \b@vdoinside%
       \ift@bs
         \tabverbatim@processline
       \else
         \the\verbatim@line
       \fi
       \hss}%
     \kern\bvboxsep}\bvrightsidehook\par}}

\newcommand{\setupbox@verb}{%
  \leftskip\z@skip \rightskip\z@skip
  \interlinepenalty\boxverbflag
  \parfillskip\z@ plus\p@ minus\p@
  \lineskip-\bvboxsep \baselineskip\z@skip
  \frenchspacing\@vobeyspaces\@maybeobeytabs
  \boxverb@toprule}

\def\boxedverbatim{\begingroup
  \let\@@line\@@m@mline%    new from mempatch v4.9
  \setupboxverb@line
  \@verbatim
  \setupbox@verb
  \verbatim@start}
\def\endboxedverbatim{\bvendrulehook\endtrivlist\endgroup\@doendpe}
\@namedef{boxedverbatim*}{\let\frenchspacing\@gobble \boxedverbatim}
\@namelet{endboxedverbatim*}\endboxverbatim

\def\boxverb@toprule{\bvtoprulehook
  \@@line{\bvleftsidehook \bvtopmidhook \bvrightsidehook}}

\newcommand*{\bvendofpage}[1]{%
  \def\boxverb@botpage{#1}}
%%%%\bvendofpage{\hrule\kern-.4pt}
\bvendofpage{\hrule width\linewidth\kern-.4pt}

\def\boxverb@split{\ifnum\outputpenalty=\boxverbflag
  \ifdim\dp\@cclv=\z@
%%%%    \setbox\@cclv\vbox{\unvbox\@cclv\hrule\kern-.4pt}%
    \setbox\@cclv\vbox{\unvbox\@cclv\boxverb@botpage}%
    \null \kern-.7\topskip \b@vtop \boxverb@toprule
  \fi
\fi}

\def\bvtoprulehook{\hrule width\linewidth \nobreak\vskip-.1\p@}
\def\bvendrulehook{\hrule width\linewidth}
\def\bvleftsidehook{\vrule}
\def\bvrightsidehook{\vrule}
\def\bvtopmidhook{\rule{0\p@}{2\bvboxsep} \hss}

\newcommand{\boxedverbatiminput}{\begingroup
  \@ifstar{\let\frenchspacing\@gobble
           \boxedverbatim@input\relax}%
          {\boxedverbatim@input{\frenchspacing\@vobeyspaces}}}

\def\boxedverbatim@input#1#2{%
  \setupboxverb@line
  \IfFileExists{#2}{\@verbatim #1\relax
  \setupbox@verb
    \verbatim@readfile{\@filef@und}%
      \bvendrulehook\endtrivlist\endgroup\@doendpe}%
  {\typeout {No file #2.}\endgroup}}

\newcommand{\bvbox}{%
  \bvperpagetrue%
  \renewcommand{\bvtoprulehook}{\hrule \nobreak \vskip-.1\p@}%
  \renewcommand{\bvleftsidehook}{\vrule}%
  \renewcommand{\bvrightsidehook}{\vrule}%
  \renewcommand{\bvendrulehook}{\hrule}}

\newcommand{\nobvbox}{%
  \bvperpagefalse%
  \renewcommand{\bvtoprulehook}{}%
  \renewcommand{\bvleftsidehook}{}%
  \renewcommand{\bvrightsidehook}{}%
  \renewcommand{\bvendrulehook}{}}

\newcommand{\bvtopandtail}{%
  \bvperpagefalse%
  \renewcommand{\bvtoprulehook}{\hrule \nobreak \vskip-.1\p@}%
  \renewcommand{\bvleftsidehook}{}%
  \renewcommand{\bvrightsidehook}{}%
  \renewcommand{\bvendrulehook}{\hrule}}

\newcommand{\bvsides}{%
  \bvperpagefalse%
  \renewcommand{\bvtoprulehook}{\vskip 3ex}%
  \renewcommand{\bvleftsidehook}{\vrule}%
  \renewcommand{\bvrightsidehook}{\vrule}%
  \renewcommand{\bvendrulehook}{}}

\let\framed\relax \let\endframed\relax
\let\shaded\relax \let\endshaded\relax

\chardef\FrameRestore=\catcode`\| % for debug
\catcode`\|=\catcode`\% % (debug: insert space after backslash)

\def\MakeFramed#1{\par
 \fb@sizeofframe\FrameCommand
 \let\width\fb@frw \let\height\fb@frh
 \begingroup
 \skip@\lastskip
 \if@nobreak\else
    \penalty9999 % updates \page parameters
    \ifdim\pagefilstretch=\z@ \ifdim\pagefillstretch=\z@
       \edef\@tempa{\the\skip@}%
       \ifx\@tempa\zero@glue \penalty-30
       \else \vskip-\skip@ \penalty-30 \vskip\skip@
    \fi\fi\fi
    \penalty\z@
    \advance\skip@ \z@ plus-.5\baselineskip
    \advance\skip@ \z@ plus-.231\height
    \advance\skip@ \z@ plus-.231\skip@
    \advance\skip@ \z@ plus-.231\topsep
    \vskip-\skip@ \penalty 1800 \vskip\skip@
 \fi
 \addvspace{\topsep}%
 \endgroup
 \penalty\@M \vskip 2\baselineskip \vskip\height
 \penalty9999 \vskip -2\baselineskip \vskip-\height
 \penalty9999 % updates \pagetotal
|\message{After clearout, \pagetotal=\the\pagetotal,
|         \pagegoal=\the\pagegoal. }%
 \fb@adjheight
 \setbox\@tempboxa\vbox\bgroup
   #1% Modifications to \hsize (can use \width and \height)
   \textwidth\hsize \columnwidth\hsize}

\def\endMakeFramed{\par
     \kern\z@
     \hrule\@width\hsize\@height\z@
     \penalty-100 % put depth into height
 \egroup
  % {\showoutput\showbox\@tempboxa}%
 \begingroup
   \fb@put@frame\FrameCommand\FirstFrameCommand
 \endgroup}

\def\fb@put@frame#1#2{\relax
 \ifdim\pagegoal=\maxdimen \pagegoal\vsize \fi
 \ifinner
   \fb@putboxa#1%
   \fb@afterframe
 \else
  \dimen@\pagegoal \advance\dimen@-\pagetotal % natural space left on page
  \ifdim\dimen@<2\baselineskip % Too little room on page
|   \message{Page has only \the\dimen@\space room left; eject. }%
    \eject \fb@adjheight \fb@put@frame#1#2%
  \else % there's appreciable room left on the page
     \fb@sizeofframe#1%
|    \message{\string\pagetotal=\the\pagetotal,
|        \string\pagegoal=\the\pagegoal,
|        \string\pagestretch=\the\pagestretch,
|        \string\pageshrink=\the\pageshrink,
|        \string\fb@frh=\fb@frh. \space}
|    \message{Box of size \the\ht\@tempboxa\space + \fb@frh}%
     \begingroup % temporarily set \dimen@ to be...
     \advance\dimen@.8\pageshrink  % maximum space available on page
     \advance\dimen@-\fb@frh\relax % space available for frame's contents
     \expandafter\endgroup
     \ifdim\dimen@>\ht\@tempboxa % whole box does fit
|       \message{fits in \the\dimen@. }%
        \fb@putboxa#1%
        \fb@afterframe
     \else % box must be split
|       \message{must be split to fit in \the\dimen@. }%
        \fb@sizeofframe#2%
        \setbox\@tempboxa\vbox{% simulate frame and flexiblity of the page:
           \vskip \fb@frh \@plus\pagestretch \@minus.8\pageshrink
           \kern137sp\kern-137sp\penalty-30
           \unvbox\@tempboxa}%
        \edef\fb@resto@set{\boxmaxdepth\the\boxmaxdepth
                           \splittopskip\the\splittopskip}%
        \boxmaxdepth\z@ \splittopskip\z@
|       \message{Padded box of size \the\ht\@tempboxa\space split
|                to \the\dimen@}%
        \setbox\tw@\vsplit\@tempboxa to\dimen@
|       \toks99\expandafter{\splitfirstmark}%
|       \toks98\expandafter{\splitbotmark}%
|       \message{Marks are: \the\toks99, \the\toks98. }%
        \setbox\tw@\vbox{\unvbox\tw@}% natural-sized
|       \message{Natural height of split box is \the\ht\tw@, leaving
|          \the\ht\@tempboxa\space remainder. }%
        \begingroup
        \advance\dimen@\topskip
        \expandafter\endgroup
        \ifdim\dimen@>\pagegoal
|         \message{Frame is big -- Use up the full column. }%
          \dimen@ii\pagegoal
          \advance\dimen@ii -\topskip
          \advance\dimen@ii \FrameHeightAdjust\relax
        \else  % suspect this is wrong:
          \advance\dimen@.8\pageshrink
          \ifdim\ht\tw@>\dimen@
|           \message{Box too tall; rebox it to \the\dimen@. }%
            \dimen@ii\dimen@
          \else % use natural size
            \dimen@ii\ht\tw@
          \fi
        \fi
        \advance\dimen@ii -\fb@frh
        \setbox\tw@\vbox to\dimen@ii \bgroup
        \vskip -\fb@frh \@plus-\pagestretch \@minus-.8\pageshrink
        \unvbox\tw@ \unpenalty\unpenalty
        \ifdim\lastkern=-137sp % whole box went to next page
|          \message{box split at beginning! }%
           % need work here???
           \egroup \fb@resto@set \eject % (\vskip for frame size was discarded)
           \fb@adjheight
           \fb@put@frame#1#2% INSERTED ???
        \else % Got material split off at the head
           \egroup \fb@resto@set
           \ifvoid\@tempboxa % it all fit after all
|             \message{box split at end! }%
              \setbox\@tempboxa\box\tw@
              \fb@putboxa#1%
              \fb@afterframe
           \else % it really did split
|             \message{box split as expected. Its reboxed height
|                      is \the\ht\tw@. }%
              \ifdim\wd\tw@>\z@
                \wd\tw@\wd\@tempboxa
                \memfblineboxtwo{#2{\box\tw@}}%  ??? \centerline bad idea? \\
              \else
|               \message{Zero width means likely blank.
|                        Don't frame it (guess)}%
                \box\tw@
              \fi
              \hrule \@height\z@ \@width\hsize
              \eject
              \fb@adjheight
              \fb@put@frame\LastFrameCommand\MidFrameCommand
  \fi\fi\fi\fi\fi}

\newcommand{\memfblineboxtwo}[1]{\centerline{#1}}
\newcommand{\memfblineboxa}[1]{\centerline{#1}}

\def\fb@putboxa#1{%
  \ifvoid\@tempboxa
%%%%    PackageWarning{framed}{Boxa is void -- discard it. }%
    \@memwarn{Boxa is void -- discard it. }%
  \else
|   \message{Frame and place boxa. }%
|   %{\showoutput\showbox\@tempboxa}%
%%%%%%%    \centerline{#1{\box\@tempboxa}}%
    \memfblineboxa{#1{\box\@tempboxa}}%
  \fi}

\def\fb@afterframe{%
    \nointerlineskip \null %{\showoutput \showlists}
    \penalty-30 \vskip\topsep \relax}

\newdimen\fb@frw
\newdimen\fb@frh
\def\fb@sizeofframe#1{\begingroup
 \setbox\z@\vbox{\vskip-5in \hbox{\hskip-5in
   #1{\hbox{\vrule \@height 4.7in \@depth.3in \@width 5in}}}%
   \vskip\z@skip}%
|  \message{Measuring frame addition for \string#1 in \@currenvir\space
|    gives ht \the\ht\z@\space and wd \the\wd\z@. }%
 \global\fb@frw\wd\z@ \global\fb@frh\ht\z@
 \endgroup}

\def\fb@adjheight{%
  \vbox to\FrameHeightAdjust{}% get proper baseline skip from above.
  \penalty\@M \nointerlineskip
  \vskip-\FrameHeightAdjust
  \penalty\@M} % useful for tops of pages

\edef\zero@glue{\the\z@skip}

\catcode`\|=\FrameRestore

\providecommand\FrameCommand{%
 \setlength\fboxrule{\FrameRule}\setlength\fboxsep{\FrameSep}%
 \fbox}
\@ifundefined{FrameRule}{\newdimen\FrameRule \FrameRule=\fboxrule}{}
\@ifundefined{FrameSep} {\newdimen\FrameSep  \FrameSep =3\fboxsep}{}
\providecommand\FirstFrameCommand{\FrameCommand}
\providecommand\MidFrameCommand{\FrameCommand}
\providecommand\LastFrameCommand{\FrameCommand}
\providecommand\FrameHeightAdjust{6pt}

\def\FrameRestore{%
   \let\if@nobreak\iffalse
   \let\if@noskipsec\iffalse
   \let\-\@dischyph
   \let\'\@acci\let\`\@accii\let\=\@acciii
   %  \message{FrameRestore:
   %    \@totalleftmargin=\the \@totalleftmargin,
   %    \rightmargin=\the\rightmargin,
   %    \@listdepth=\the\@listdepth.  }%
   \ifnum \ifdim\@totalleftmargin>\z@ 1\fi
          \ifdim\rightmargin>\z@ 1\fi
          \ifnum\@listdepth>0 1\fi 0>\z@
     %     \message{In a list: \linewidth=\the\linewidth,
     %       \@totalleftmargin=\the\@totalleftmargin,
     %       \parshape=\the\parshape, \columnwidth=\the\columnwidth,
     %       \hsize=\the\hsize,
     %       \labelwidth=\the\labelwidth. }%
%%%     \@setminipage % snug fit around the item
%%%     \advance\linewidth-\columnwidth \advance\linewidth\hsize
%%%     \parshape\@ne \@totalleftmargin \linewidth
     \memfblistfixparams
   \else % Not in list
     \linewidth=\hsize
     %\message{No list, set \string\linewidth=\the\hsize. }%
   \fi
   \sloppy}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\newcommand*{\memfblistfixparams}{%
  \@setminipage % snug fit around the item
  \advance\linewidth-\columnwidth \advance\linewidth\hsize
  \parshape\@ne \@totalleftmargin \linewidth}

\newenvironment{framed}% using default \FrameCommand
  {\MakeFramed {\advance\hsize-\width \FrameRestore}}%
  {\endMakeFramed}

\newenvironment{shaded}{%
  \def\FrameCommand{\fboxsep=\FrameSep \colorbox{shadecolor}}%
  \MakeFramed {\FrameRestore}}%
  {\endMakeFramed}

\newenvironment{leftbar}{%
  \def\FrameCommand{\vrule width 3pt \hspace{10pt}}%
  \MakeFramed {\advance\hsize-\width \FrameRestore}}%
 {\endMakeFramed}

\newenvironment{snugshade}{%
  \def\FrameCommand{\colorbox{shadecolor}}%
  \MakeFramed {\FrameRestore\@setminipage}}%
 {\par\unskip\endMakeFramed}

\AtBeginPackage{framed}{%
  \let\framed\relax \let\endframed\relax
  \let\shaded\relax \let\endshaded\relax
  \let\leftbar\relax \let\endleftbar\relax
  \let\snugshade\relax \let\endsnugshade\relax}

\newenvironment{qframe}{%
  \def\FrameCommand##1{\fboxrule=\FrameRule\fboxsep=\FrameSep
    \hskip\@totalleftmargin\fbox{##1}% There is no \@totalrightmargin, so...
      \hskip-\linewidth \hskip-\@totalleftmargin \hskip\columnwidth}%
  \MakeFramed{\advance\hsize-\width
              \advance\hsize \FrameSep
              \@totalleftmargin\z@ \linewidth=\hsize}}%
 {\endMakeFramed}

\newenvironment{qshade}{%
  \def\FrameCommand##1{\fboxsep=\FrameSep
    \hskip\@totalleftmargin
    \hskip -1\FrameSep
    \colorbox{shadecolor}{##1}%
      \hskip-\linewidth \hskip-\@totalleftmargin
      \hskip -1\FrameSep
      \hskip\columnwidth}%
  \MakeFramed{\advance\hsize-\width
              \advance\hsize 3\FrameSep
              \@totalleftmargin\z@ \linewidth=\hsize}}%
 {\endMakeFramed}

\newcommand*{\newoutputstream}[1]{%
  \@ifundefined{#1outstre@m}%
    {\expandafter\newwrite\csname #1outstre@m\endcsname
     \csname newif\expandafter\endcsname
       \csname ifstre@m#1open\endcsname
     \global\csname stre@m#1openfalse\endcsname
     \expandafter\ifx\csname atstreamopen#1\endcsname\relax
       \global\@namedef{atstreamopen#1}{}%
     \fi
     \expandafter\ifx\csname atstreamclose#1\endcsname\relax
       \global\@namedef{atstreamclose#1}{}%
     \fi
    }%
    {\@memwarn{Output stream #1\space is already defined}}}

\newcommand*{\newinputstream}[1]{%
  \@ifundefined{#1instre@m}%
    {\expandafter\newread\csname #1instre@m\endcsname
     \csname newif\expandafter\endcsname
       \csname ifstre@m#1open\endcsname
     \global\csname stre@m#1openfalse\endcsname
     \expandafter\ifx\csname atstreamopen#1\endcsname\relax
       \global\@namedef{atstreamopen#1}{}%
     \fi
     \expandafter\ifx\csname atstreamclose#1\endcsname\relax
       \global\@namedef{atstreamclose#1}{}%
     \fi
    }%
    {\@memwarn{Input stream #1\space is already defined}}}

\newcommand{\IfStreamOpen}[3]{%
  \csname ifstre@m#1open\endcsname#2\else#3\fi}
\newcommand{\instre@mandopen}[2]{%
  \@ifundefined{#1instre@m}{%
    \@memwarn{#1\space is not an input stream}}%
  {\IfStreamOpen{#1}{#2}{%
    \@memwarn{Input stream #1\space is not open}}}}

\newcommand{\instre@mandclosed}[2]{%
  \@ifundefined{#1instre@m}{%
    \@memwarn{#1\space is not an input stream}}%
  {\IfStreamOpen{#1}{%
    \@memwarn{Input stream #1\space is open}}{#2}}}

\newcommand{\outstre@mandopen}[2]{%
  \@ifundefined{#1outstre@m}{%
    \@memwarn{#1\space is not an output stream}}%
  {\IfStreamOpen{#1}{#2}{%
    \@memwarn{Output stream #1\space is not open}}}}

\newcommand{\outstre@mandclosed}[2]{%
  \@ifundefined{#1outstre@m}{%
    \@memwarn{#1\space is not an output stream}}%
  {\IfStreamOpen{#1}{%
    \@memwarn{Output stream #1\space is open}}{#2}}}

\newcommand*{\openoutputfile}[2]{%
  \outstre@mandclosed{#2}{%
    \global\@namedef{#1@filename}{#1}%
    \if@filesw
      \immediate\openout\@nameuse{#2outstre@m}=\@nameuse{#1@filename}%
    \fi
    \global\csname stre@m#2opentrue\endcsname%
    \@nameuse{atstreamopen#2}}}

\newcommand*{\closeoutputstream}[1]{%
  \outstre@mandopen{#1}{%
    \@nameuse{atstreamclose#1}%
    \immediate\closeout\@nameuse{#1outstre@m}%
    \global\csname stre@m#1openfalse\endcsname}}

\newcommand{\openinputfile}[2]{%
  \IfFileExists{#1}{%                   file exists
    \instre@mandclosed{#2}{%
      \@addtofilelist{#1}%
      \global\@namedef{#1@filename}{#1}%
      \immediate\openin\@nameuse{#2instre@m}=\@nameuse{#1@filename}%
      \global\csname stre@m#2opentrue\endcsname%
      \@nameuse{atstreamopen#2}}}%
  {%                                    file not found
    \typeout{No file #1.}
  }}

\newcommand{\closeinputstream}[1]{%
  \instre@mandopen{#1}{%
     \@nameuse{atstreamclose#1}%
     \immediate\closein\@nameuse{#1instre@m}%
     \global\csname stre@m#1openfalse\endcsname}}

\def\writeverbatim#1{%
  \@bsphack
  \let\do\@makeother\dospecials
  \catcode`\^^M\active
  \def\verbatim@processline{%
    \immediate\write\@nameuse{#1outstre@m}{\the\verbatim@line}}%
  \verbatim@start}
\def\endwriteverbatim{\@esphack}

\newcommand{\addtostream}[2]{%
  \@bsphack
  \outstre@mandopen{#1}{%
    {\let\protect\string
     \immediate\write\@nameuse{#1outstre@m}{#2}%
    }}%
  \@esphack}

\newif\ifstre@mnoteof
\newcommand{\checkstre@meof}[1]{%
  \stre@mnoteoftrue\ifeof\@nameuse{#1instre@m}\stre@mnoteoffalse\fi}

\def\readstream#1{
  \instre@mandopen{#1}{%
    \loop \checkstre@meof{#1} \ifstre@mnoteof
      \read\@nameuse{#1instre@m} to\temptokstre@m
     \temptokstre@m
    \repeat
    }}

\def\readaline#1{
  \instre@mandopen{#1}{%
    \ifeof\@nameuse{#1instre@m}
      \@memwarn{No more to read from stream #1}
    \else
      \read\@nameuse{#1instre@m} to\temptokstre@m
      \temptokstre@m
    \fi}}

\def\readverbatim{\begingroup
  \ift@bs
    \def\verbatim@processline{\tabverbatim@processline}%
  \fi
  \@ifstar{\stre@mverb@input{\@maybeobeytabs}}%
     {\stre@mverb@input{\frenchspacing\@vobeyspaces\@maybeobeytabs}}}

\newcommand{\stre@mverb@input}[2]{%
  \IfStreamOpen{#2}%
    {\@verbatim #1\relax
     \def\@verbinstre@m{\@nameuse{#2instre@m}}
     \verb@readstre@m\endtrivlist\endgroup\@doendpe}%
    {\@memwarn{Stream #2\space is not open}\endgroup}}

\newcommand{\verb@readstre@m}{%
  \verbatim@startline
  \expandafter\endlinechar\expandafter\m@ne
  \expandafter\verbatim@read@stre@m
  \expandafter\endlinechar\the\endlinechar\relax
  \verbatim@finish}

\newcommand{\verbatim@read@stre@m}{%
  \read\@verbinstre@m to\next
  \ifeof\@verbinstre@m
  \else
    \expandafter\verbatim@addtoline\expandafter{\next}%
    \verbatim@processline
    \verbatim@startline
    \expandafter\verbatim@read@stre@m
  \fi}

\newcommand{\readboxedverbatim}{\begingroup
  \@ifstar{\stre@mbvin\relax}%
          {\stre@mbvin{\frenchspacing\@vobeyspaces}}}

\newcommand{\stre@mbvin}[2]{%
  \IfStreamOpen{#2}%
    {\setupboxverb@line
     \@verbatim #1\relax
     \def\@verbinstre@m{\@nameuse{#2instre@m}}%
     \setupbox@verb
     \verb@readstre@m\bvendrulehook\endtrivlist\endgroup\@doendpe}%
    {\@memwarn{Stream #2\space is not open}\endgroup}}

\newcommand{\provideenvironment}{\@star@or@long\m@mprovenv}
\newcommand{\m@mprovenv}[1]{\@ifundefined{#1}%
  {\new@environment{#1}}%       % create new environment
  {\@memwarn{Environment `#1' already defined}%
   \m@mgobbleoptsandtwo}}
\newcommand{\m@mgobbleoptsandtwo}{%
  \@ifnextchar [{\m@mgobbleoptandtwo}{\@gobbletwo}}
\def\m@mgobbleoptandtwo[#1]{%
  \@ifnextchar [{\m@mgobbleoptandtwo}{\@gobbletwo}}

\newcommand*{\providecounter}[1]{%
  \@ifundefined{c@#1}%
    {\newcounter{#1}}%
    {\@memwarn{Counter `#1' already defined}%
      \@ifnextchar[{\m@mgobbleopt}{}}}

\def\m@mgobbleopt[#1]{}

\newcommand*{\providelength}[1]{%
  \begingroup
    \escapechar\m@ne\xdef\@gtempa{{\string#1}}%
  \endgroup
  \expandafter\@ifundefined\@gtempa
    {\newlength{#1}}%
    {\@memwarn{Length #1 already defined}}}

\newcommand*{\newloglike}{\@ifstar{\m@mnewlogs}{\m@mnewlog}}
\newcommand*{\m@mnewlogs}[2]{%
  \newcommand*{#1}{\mathop{\operator@font #2}}}
\newcommand*{\m@mnewlog}[2]{%
  \newcommand*{#1}{\mathop{\operator@font #2}\nolimits}}

\newcommand*{\provideloglike}{\@ifstar{\m@mprovlogs}{\m@mprovlog}}
\newcommand*{\m@mprovlogs}[2]{%
  \providecommand*{#1}{\mathop{\operator@font #2}}}
\newcommand*{\m@mprovlog}[2]{%
  \providecommand*{#1}{\mathop{\operator@font #2}\nolimits}}

\providecommand{\@removefromreset}[2]{{%
  \expandafter\let\csname c@#1\endcsname\@removefromreset
  \def\@elt##1{%
    \expandafter\ifx\csname c@##1\endcsname\@removefromreset
    \else
      \noexpand\@elt{##1}%
    \fi}%
  \expandafter\xdef\csname cl@#2\endcsname{%
    \csname cl@#2\endcsname}}}

\newcommand{\@ifbothcntrs}[3]{%
  \@ifundefined{c@#1}{% counter undefined
    \@memerror{#1 is not a counter}{\@eha}}%
  {% else counter is defined
    \@ifundefined{c@#2}{% within undefined
      \@memerror{#2 is not a counter}{\@eha}}%
    {% else both counter and within  are defined
     #3}}}

\providecommand{\counterwithin}{\@ifstar{\@csinstar}{\@csin}}
\providecommand{\@csinstar}[2]{%
  \@ifbothcntrs{#1}{#2}{\@addtoreset{#1}{#2}}}
\providecommand{\@csin}[2]{%
  \@ifbothcntrs{#1}{#2}{\@addtoreset{#1}{#2}%
                        \@namedef{the#1}{\@nameuse{the#2}.\arabic{#1}}}}

\providecommand{\counterwithout}{\@ifstar{\@csoutstar}{\@csout}}
\providecommand{\@csoutstar}[2]{%
  \@ifbothcntrs{#1}{#2}{\@removefromreset{#1}{#2}}}
\providecommand{\@csout}[2]{%
  \@ifbothcntrs{#1}{#2}{\@removefromreset{#1}{#2}%
                        \@namedef{the#1}{\arabic{#1}}}}

\newcommand*{\letcountercounter}[2]{%
  \expandafter\let\csname c@m@morig@ctr#1\expandafter\endcsname%
                   \csname c@#1\endcsname
  \expandafter\let\csname c@#1\expandafter\endcsname%
                  \csname c@#2\endcsname}
\newcommand*{\unletcounter}[1]{%
 \expandafter\let\csname c@#1\expandafter\endcsname%
                 \csname c@m@morig@ctr#1\endcsname}

\newif\ifoddpage
\newif\ifstrictpagecheck
  \strictpagecheckfalse
\newcommand*{\strictpagecheck}{\strictpagechecktrue}
\newcommand*{\easypagecheck}{\strictpagecheckfalse}

\newcounter{cp@cntr}
\newcommand{\cplabel}{^_}
\DeclareRobustCommand{\checkoddpage}{%
  \oddpagefalse%
  \ifstrictpagecheck%
    \stepcounter{cp@cntr}\pmemlabel{\cplabel\thecp@cntr}%
    \@memcnta=\pmemlabelref{\cplabel\thecp@cntr}\relax
    \ifodd\@memcnta\oddpagetrue\fi
  \else
    \ifodd\c@page\oddpagetrue\fi
  \fi}

\gdef\thepmemc@@page{\the\c@page}

\long\def\pmemprotected@write#1#2#3{%
  \begingroup
  \let\thepmemc@@page\relax
  #2%
  \let\protect\@unexpandable@protect
  \edef\reserved@a{\write#1{#3}}%
  \reserved@a
  \endgroup
  \if@nobreak\ifvmode\nobreak\fi\fi}

\newcommand{\pmemlabel}[1]{\@bsphack
  \pmemprotected@write\@auxout{}%
    {\string\newpmemlabel{#1}{\thepmemc@@page}}%
  \@esphack}
\newcommand{\newpmemlabel}[2]{{\global\@namedef{m@#1}{#2}}}
\newcommand{\pmemlabelref}[1]{%
  \expandafter\ifx\csname m@#1\endcsname\relax
    0%
  \else
    \csname m@#1\endcsname
  \fi}

\begingroup
\catcode`\Q=3
\long\gdef\@ifmtarg#1{\@xifmtarg#1QQ\@secondoftwo\@firstoftwo\@nil}
\long\gdef\@xifmtarg#1#2Q#3#4#5\@nil{#4}
\long\gdef\@ifnotmtarg#1{\@xifmtarg#1QQ\@firstofone\@gobble\@nil}
\endgroup

\DeclareRobustCommand{\ch@ngetext}{%
  \setlength{\@colht}{\textheight}\setlength{\@colroom}{\textheight}%
  \setlength{\vsize}{\textheight}\setlength{\columnwidth}{\textwidth}%
  \if@twocolumn%
    \advance\columnwidth-\columnsep \divide\columnwidth\tw@%
    \@firstcolumntrue%
  \fi%
  \setlength{\hsize}{\columnwidth}%
  \setlength{\linewidth}{\hsize}}

\DeclareRobustCommand{\changetext}[5]{%
  \@ifmtarg{#1}{}{\addtolength{\textheight}{#1}}%
  \@ifmtarg{#2}{}{\addtolength{\textwidth}{#2}}%
  \@ifmtarg{#3}{}{\addtolength{\evensidemargin}{#3}}%
  \@ifmtarg{#4}{}{\addtolength{\oddsidemargin}{#4}}%
  \@ifmtarg{#5}{}{\addtolength{\columnsep}{#5}}%
  \ch@ngetext}

\DeclareRobustCommand{\changepage}[9]{%
  \@ifmtarg{#1}{}{\addtolength{\textheight}{#1}}%
  \@ifmtarg{#2}{}{\addtolength{\textwidth}{#2}}%
  \@ifmtarg{#3}{}{\addtolength{\evensidemargin}{#3}}%
  \@ifmtarg{#4}{}{\addtolength{\oddsidemargin}{#4}}%
  \@ifmtarg{#5}{}{\addtolength{\columnsep}{#5}}%
  \ch@ngetext
  \@ifmtarg{#6}{}{\addtolength{\topmargin}{#6}}%
  \@ifmtarg{#7}{}{\addtolength{\headheight}{#7}}%
  \@ifmtarg{#8}{}{\addtolength{\headsep}{#8}}%
  \@ifmtarg{#9}{}{\addtolength{\footskip}{#9}}}

\newenvironment{adjustwidth}[2]{%
  \begin{list}{}{%
    \topsep\z@%
    \listparindent\parindent%
    \parsep\parskip%
    \@ifmtarg{#1}{\setlength{\leftmargin}{\z@}}%
                 {\setlength{\leftmargin}{#1}}%
    \@ifmtarg{#2}{\setlength{\rightmargin}{\z@}}%
                 {\setlength{\rightmargin}{#2}}%
    }
    \item[]}{\end{list}}

\newenvironment{adjustwidth*}[2]{%
  \begin{list}{}{%
    \topsep\z@%
    \listparindent\parindent%
    \parsep\parskip%
    \checkoddpage
    \ifoddpage  % odd numbered page
      \@ifmtarg{#1}{\setlength{\leftmargin}{\z@}}%
                   {\setlength{\leftmargin}{#1}}%
      \@ifmtarg{#2}{\setlength{\rightmargin}{\z@}}%
                   {\setlength{\rightmargin}{#2}}%
    \else       % even numbered page
      \@ifmtarg{#2}{\setlength{\leftmargin}{\z@}}%
                   {\setlength{\leftmargin}{#2}}%
      \@ifmtarg{#1}{\setlength{\rightmargin}{\z@}}%
                   {\setlength{\rightmargin}{#1}}%
    \fi
    }
    \item[]}{\end{list}}

\newcommand{\calccentering}[1]{
  #1 = \paperwidth
  \advance #1 by -\textwidth
  \divide #1 by \tw@
  \advance #1 by -\spinemargin}

\newenvironment{vplace}[1][1]{%
  \par\vspace*{\stretch{#1}}%
}{%
  \vspace*{\stretch{1}}%
  \par}

\newcommand{\cleartoevenpage}[1][\@empty]{%
  \clearpage%
  \ifodd\c@page\hbox{}#1\clearpage\fi}

\newcommand{\movetoevenpage}[1][\@empty]{%
  \newpage%
  \ifodd\c@page\hbox{}#1\newpage\fi}

\newcommand{\cleartooddpage}[1][\@empty]{%
  \clearpage%
  \ifodd\c@page\else\hbox{}#1\clearpage\fi}

\newcommand{\movetooddpage}[1][\@empty]{%
  \newpage%
  \ifodd\c@page\else\hbox{}#1\newpage\fi}

\newcommand{\needspace}[1]{\begingroup\setlength{\dimen@}{#1}%
  \vskip\z@\@plus\dimen@\penalty -100\vskip\z@\@plus-\dimen@
  \vskip\dimen@\penalty 9999\vskip-\dimen@\vskip\z@skip\endgroup}

\newcommand{\Needspace}{\@ifstar{\M@sneedsp@}{\M@needsp@}}
\newcommand{\M@sneedsp@}[1]{\par \penalty-100\begingroup
  \setlength{\dimen@}{#1}%
  \dimen@ii\pagegoal \advance\dimen@ii-\pagetotal
  \ifdim \dimen@>\dimen@ii
    \break
  \fi\endgroup}
\newcommand{\M@needsp@}[1]{\par \penalty-100\begingroup
  \setlength{\dimen@}{#1}%
  \dimen@ii\pagegoal \advance\dimen@ii-\pagetotal
  \ifdim \dimen@>\dimen@ii
    \ifdim \dimen@ii>\z@
      \vfil
    \fi
    \break
  \fi\endgroup}

\newcommand*{\midsloppy}{%
  \tolerance 5000%
  \hbadness 4000%
  \emergencystretch 1.5em%
  \hfuzz .1\p@
  \vfuzz\hfuzz}
\newenvironment{midsloppypar}{\par\midsloppy}{\par}

\@ifl@t@r\fmtversion{2020-10-01}{
  % nothing to do with newer kernel
}{%
\providecommand{\medspace}{\kern .22222em }
\DeclareRobustCommand{\:}{%
  \relax\ifmmode\mskip\medmuskip\else\medspace\fi}
\DeclareRobustCommand{\!}{%
  \relax\ifmmode\mskip-\thinmuskip\else\negthinspace\fi}

} % end kernel version wrapper
\DeclareRobustCommand*{\slashfracstyle}[1]{%
  {\m@th\ensuremath{\mbox{\fontsize\sf@size\z@\selectfont #1}}}}
\DeclareRobustCommand*{\slashfrac}[2]{\leavevmode
  \raise.5ex\hbox{\slashfracstyle{#1}}\kern-.13em/%
  \kern-.15em\lower.25ex\hbox{\slashfracstyle{#2}}}

\@ifundefined{textsubscript}{%
  \DeclareRobustCommand*{\textsubscript}[1]{%
    \@textsubscript{\selectfont#1}}
  \providecommand*{\@textsubscript}[1]{%
    {\m@th\ensuremath{_{\mbox{\fontsize\sf@size\z@#1}}}}}
}{}

%%%%%%%%%%%%%%%%%%%% number formatting

\newif\iflowernumtoname
  \lowernumtonamefalse
\newif\ifpriornum
\newif\ifminusnumber
\newif\ifnotnumtonameallcaps
\newif\ifmakeordinal

\newcommand*{\namenumberand}{ and }
\newcommand*{\namenumbercomma}{, }
\newcommand*{\lcminusname}{minus }
\newcommand*{\ucminusname}{Minus }
\let\minusname\lcminusname
\newcommand*{\fnumbersep}{,}
\newcommand*\tensunitsep{-}
\newcommand*{\nthstring}{th}      % nth
\newcommand*{\iststring}{st}      % 1st
\newcommand*{\iindstring}{nd}     % 2nd
\newcommand*{\iiirdstring}{rd}    % 3rd
\newcommand*{\tiethstring}{tieth} % tieth
\newcommand*{\teenstring}{teen}   % teen
\newcommand{\ordscript}[1]{#1}

\chardef\m@mten=10 % shorthand for 10

\newcounter{ism@mctr}  % units
\newcounter{xsm@mctr}  % tens
\newcounter{csm@mctr}  % hundreds
\newcounter{ksm@mctr}  % thousands
\newcounter{xksm@mctr} % ten thousands
\newcounter{cksm@mctr} % hundred thousands
\newcounter{msm@mctr}  % millions
\newcounter{xmsm@mctr} % ten millions
\newcounter{cmsm@mctr} % hundred millions
\newcounter{bsm@mctr}  % billions
\newcounter{workm@mctr}

\newcommand*{\numdigits}[1]{%
  \setcounter{ism@mctr}{0}%
  \setcounter{xsm@mctr}{0}%
  \setcounter{csm@mctr}{0}%
  \setcounter{ksm@mctr}{0}%
  \setcounter{xksm@mctr}{0}%
  \setcounter{cksm@mctr}{0}%
  \setcounter{msm@mctr}{0}%
  \setcounter{xmsm@mctr}{0}%
  \setcounter{cmsm@mctr}{0}%
  \setcounter{bsm@mctr}{0}%
  \setcounter{workm@mctr}{#1}%
  \minusnumberfalse
  \ifnum \c@workm@mctr < \z@  % negative
    \minusnumbertrue
    \c@workm@mctr = -\c@workm@mctr
  \fi
  \ifnum \c@workm@mctr > \m@ne     % units
    \c@ism@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@ism@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@    % tens
    \c@xsm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@xsm@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@   % hundreds
    \c@csm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@csm@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@   % thousands
    \c@ksm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@ksm@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@   % ten thousands
    \c@xksm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@xksm@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@   % hundred thousands
    \c@cksm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@cksm@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@   % millions
    \c@msm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@msm@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@  % ten millions
    \c@xmsm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@xmsm@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@  % hundred millions
    \c@cmsm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@cmsm@mctr by -\c@workm@mctr
    \divide \c@workm@mctr by \m@mten
  \fi
  \ifnum \c@workm@mctr > \z@% billions
    \c@bsm@mctr = \c@workm@mctr
    \divide \c@workm@mctr by \m@mten
    \multiply \c@workm@mctr by \m@mten
    \advance \c@bsm@mctr by -\c@workm@mctr
  \fi}

\newcommand*{\form@tnumber}[1]{%
  \numdigits{#1}%
  \ifminusnumber-\fi
  \priornumfalse
  \ifnum \c@bsm@mctr > \z@ % billions
    \priornumtrue
    \thebsm@mctr\fnumbersep
  \fi
  \ifpriornum                 % hundred millions
    \thecmsm@mctr
  \else
    \ifnum \c@cmsm@mctr > \z@
      \priornumtrue
      \thecmsm@mctr
    \fi
  \fi
  \ifpriornum                 % ten millions
    \thexmsm@mctr
  \else
    \ifnum \c@xmsm@mctr > \z@
      \priornumtrue
      \thexmsm@mctr
    \fi
  \fi
  \ifpriornum                 % millions
    \themsm@mctr\fnumbersep
  \else
    \ifnum \c@msm@mctr > \z@
      \priornumtrue
      \themsm@mctr\fnumbersep
    \fi
  \fi
  \ifpriornum                % hundred thousands
    \thecksm@mctr
  \else
    \ifnum \c@cksm@mctr > \z@
      \priornumtrue
      \thecksm@mctr
    \fi
  \fi
  \ifpriornum                % ten thousands
    \thexksm@mctr
  \else
    \ifnum \c@xksm@mctr > \z@
      \priornumtrue
      \thexksm@mctr
    \fi
  \fi
  \ifpriornum                % thousands
    \theksm@mctr\fnumbersep
  \else
    \ifnum \c@ksm@mctr > \z@
      \priornumtrue
      \theksm@mctr\fnumbersep
    \fi
  \fi
  \ifpriornum                % hundreds
    \thecsm@mctr
  \else
    \ifnum \c@csm@mctr > \z@
      \priornumtrue
      \thecsm@mctr
    \fi
  \fi
  \ifpriornum                % tens
    \thexsm@mctr
  \else
    \ifnum \c@xsm@mctr > \z@
      \priornumtrue
      \thexsm@mctr
    \fi
  \fi
  \theism@mctr}              % units

\newcommand*{\cardinal}[1]{%
  \begingroup
  \let\fnumbersep\relax
  \form@tnumber{#1}%
  \endgroup}
\newcommand*{\fcardinal}[1]{%
  \begingroup
  \form@tnumber{#1}%
  \endgroup}

\newcommand*{\ordinal}[1]{%
  \begingroup
  \let\fnumbersep\relax
  \form@tnumber{#1}%
  \let\ordstring\nthstring
  \ifnum \c@xsm@mctr=\@ne\else
    \ifcase \c@ism@mctr
      \or \let\ordstring\iststring%    1st
      \or \let\ordstring\iindstring%   2nd
      \or \let\ordstring\iiirdstring%  3rd
    \fi
  \fi
  \ordscript{\ordstring}%
  \endgroup
}
\newcommand*{\fordinal}[1]{%
  \begingroup
  \form@tnumber{#1}%
  \let\ordstring\nthstring
  \ifnum \c@xsm@mctr=\@ne\else
    \ifcase \c@ism@mctr
      \or \let\ordstring\iststring%    1st
      \or \let\ordstring\iindstring%   2nd
      \or \let\ordstring\iiirdstring%  3rd
    \fi
  \fi
  \ordscript{\ordstring}%
  \endgroup
}

\newcommand*\nNameo{\iflowernumtoname z\else Z\fi ero}
\newcommand*\nNamec{\iflowernumtoname h\else H\fi undred}
\newcommand*\nNamem{\iflowernumtoname t\else T\fi housand}
\newcommand*\nNamemm{\iflowernumtoname m\else M\fi illion}
\newcommand*\nNamemmm{\iflowernumtoname b\else B\fi illion}

\newcommand*\nNamei{\iflowernumtoname o\else O\fi ne}
\newcommand*\nNameii{\iflowernumtoname t\else T\fi wo}
\newcommand*\nNameiii{\iflowernumtoname t\else T\fi hree}
\newcommand*\nNameiv{\iflowernumtoname f\else F\fi our}
\newcommand*\nNamev{\iflowernumtoname f\else F\fi ive}
\newcommand*\nNamevi{\iflowernumtoname s\else S\fi ix}
\newcommand*\nNamevii{\iflowernumtoname s\else S\fi even}
\newcommand*\nNameviii{\iflowernumtoname e\else E\fi ight}
\newcommand*\nNameix{\iflowernumtoname n\else N\fi ine}
\newcommand*\nNamex{\iflowernumtoname t\else T\fi en}
\newcommand*\nNamexi{\iflowernumtoname e\else E\fi leven}
\newcommand*\nNamexii{\iflowernumtoname t\else T\fi welve}
\newcommand*\nNamexiii{\iflowernumtoname t\else T\fi hir\teenstring}
\newcommand*\nNamexiv{\iflowernumtoname f\else F\fi our\teenstring}
\newcommand*\nNamexv{\iflowernumtoname f\else F\fi if\teenstring}
\newcommand*\nNamexvi{\iflowernumtoname s\else S\fi ix\teenstring}
\newcommand*\nNamexvii{\iflowernumtoname s\else S\fi even\teenstring}
\newcommand*\nNamexviii{\iflowernumtoname e\else E\fi igh\teenstring}
\newcommand*\nNamexix{\iflowernumtoname n\else N\fi ine\teenstring}
\newcommand*\nNamexx{\iflowernumtoname t\else T\fi wenty}
\newcommand*\nNamexxx{\iflowernumtoname t\else T\fi hirty}
\newcommand*\nNamexl{\iflowernumtoname f\else F\fi orty}
\newcommand*\nNamel{\iflowernumtoname f\else F\fi ifty}
\newcommand*\nNamelx{\iflowernumtoname s\else S\fi ixty}
\newcommand*\nNamelxx{\iflowernumtoname s\else S\fi eventy}
\newcommand*\nNamelxxx{\iflowernumtoname e\else E\fi ighty}
\newcommand*\nNamexc{\iflowernumtoname n\else N\fi inety}

\newcommand*{\unitnumbername}[1]{%
  \ifcase #1 \nNameo\or
   \nNamei\or
   \nNameii\or
   \nNameiii\or
   \nNameiv\or
   \nNamev\or
   \nNamevi\or
   \nNamevii\or
   \nNameviii\or
   \nNameix\fi}

\newcommand*{\teennumbername}[1]{%
  \ifcase #1 \nNamex\or
   \nNamexi\or
   \nNamexii\or
   \nNamexiii\or
   \nNamexiv\or
   \nNamexv\or
   \nNamexvi\or
   \nNamexvii\or
   \nNamexviii\or
   \nNamexix\fi}

\newcommand*{\tensnumbername}[2]{%
  \ifnum #1=\@ne
    \teennumbername{#2}\ifnotnumtonameallcaps\lowernumtonametrue\fi
  \else
    \ifcase #1
    \or
    \or \nNamexx
    \or \nNamexxx
    \or \nNamexl
    \or \nNamel
    \or \nNamelx
    \or \nNamelxx
    \or \nNamelxxx
    \or \nNamexc
    \fi
    \ifnotnumtonameallcaps\lowernumtonametrue\fi
    \ifnum #2 > \z@ \tensunitsep\unitnumbername{#2}\fi
  \fi}

\newcommand*\nthNameo{\nNameo\nthstring}
\newcommand*\nthNamei{\iflowernumtoname f\else F\fi irst}
\newcommand*\nthNameii{\iflowernumtoname s\else S\fi econd}
\newcommand*\nthNameiii{\iflowernumtoname t\else T\fi hird}
\newcommand*\nthNameiv{\nNameiv\nthstring}
\newcommand*\nthNamev{\iflowernumtoname f\else F\fi if\nthstring}
\newcommand*\nthNamevi{\nNamevi\nthstring}
\newcommand*\nthNamevii{\nNamevii\nthstring}
\newcommand*\nthNameviii{\iflowernumtoname e\else E\fi igh\nthstring}
\newcommand*\nthNameix{\iflowernumtoname n\else N\fi in\nthstring}
\newcommand*\nthNamexii{\iflowernumtoname t\else T\fi welf\nthstring}

\newcommand*{\unitordinalname}[1]{%
  \ifcase #1 \nthNameo\or
  \nthNamei\or
  \nthNameii\or
  \nthNameiii\or
  \nthNameiv\or
  \nthNamev\or
  \nthNamevi\or
  \nthNamevii\or
  \nthNameviii\or
  \nthNameix\fi}

\newcommand*{\teenordinalname}[1]{%
  \ifcase #1 \nNamex\nthstring\or
  \nNamexi\nthstring\or
  \nthNamexii\or
  \nNamexiii\nthstring\or
  \nNamexiv\nthstring\or
  \nNamexv\nthstring\or
  \nNamexvi\nthstring\or
  \nNamexvii\nthstring\or
  \nNamexviii\nthstring\or
  \nNamexix\nthstring\fi}

\newcommand*{\tensordinalname}[2]{%
  \ifnum #1=\@ne
    \teenordinalname{#2}\ifnotnumtonameallcaps\lowernumtonametrue\fi
  \else
    \ifnum #2> \z@
      \ifcase #1
      \or
      \or \nNamexx
      \or \nNamexxx
      \or \nNamexl
      \or \nNamel
      \or \nNamelx
      \or \nNamelxx
      \or \nNamelxxx
      \or \nNamexc
      \fi
      \ifnotnumtonameallcaps\lowernumtonametrue\fi
      \tensunitsep\unitordinalname{#2}
    \else
      \ifcase #1
      \or
      \or \nthNamexx
      \or \nthNamexxx
      \or \nthNamexl
      \or \nthNamel
      \or \nthNamelx
      \or \nthNamelxx
      \or \nthNamelxxx
      \or \nthNamexc
      \fi
      \ifnotnumtonameallcaps\lowernumtonametrue\fi
    \fi
  \fi}

\newcommand*\nthNamexx{\iflowernumtoname t\else T\fi wen\tiethstring}
\newcommand*\nthNamexxx{\iflowernumtoname t\else T\fi hir\tiethstring}
\newcommand*\nthNamexl{\iflowernumtoname f\else F\fi or\tiethstring}
\newcommand*\nthNamel{\iflowernumtoname f\else F\fi if\tiethstring}
\newcommand*\nthNamelx{\iflowernumtoname s\else S\fi ix\tiethstring}
\newcommand*\nthNamelxx{\iflowernumtoname s\else S\fi even\tiethstring}
\newcommand*\nthNamelxxx{\iflowernumtoname e\else E\fi igh\tiethstring}
\newcommand*\nthNamexc{\iflowernumtoname n\else N\fi ine\tiethstring}

\newcommand*{\n@me@number}[1]{%
\begingroup
    \numdigits{#1}%
    \ifminusnumber\minusname\fi
    \priornumfalse
%% billions
    \ifnum \c@bsm@mctr > \z@
      \unitnumbername{\thebsm@mctr}\space
      \ifnotnumtonameallcaps\lowernumtonametrue\fi\nNamemmm
      \priornumtrue
    \fi
%% hundred millions
    \ifnum \c@cmsm@mctr > \z@
      \ifpriornum\namenumbercomma\fi
      \unitnumbername{\thecmsm@mctr}\space
      \ifnotnumtonameallcaps\lowernumtonametrue\fi\nNamec
      \priornumtrue
    \fi
%% tens/units millions
    \ifnum \c@xmsm@mctr > \z@
      \ifpriornum
        \ifnum\c@cmsm@mctr>\z@\namenumberand\else\namenumbercomma\fi
      \fi
      \tensnumbername{\thexmsm@mctr}{\themsm@mctr}%
      \priornumtrue
    \else
      \ifnum \c@msm@mctr > \z@
        \ifpriornum
          \ifnum\c@cmsm@mctr>\z@\namenumberand\else\namenumbercomma\fi
        \fi
        \unitnumbername{\themsm@mctr}%
        \ifnotnumtonameallcaps\lowernumtonametrue\fi
        \priornumtrue
      \fi
    \fi
    \ifnum \c@cmsm@mctr > \z@
      \ifpriornum\space\fi
      \nNamemm
    \else
      \ifnum \c@xmsm@mctr > \z@
        \ifpriornum\space\fi
        \nNamemm
      \else
        \ifnum \c@msm@mctr > \z@
          \ifpriornum\space\fi
          \nNamemm
        \fi
      \fi
    \fi
%% hundred thousands
    \ifnum \c@cksm@mctr > \z@
      \ifpriornum\namenumbercomma\fi
      \unitnumbername{\thecksm@mctr}\space
        \ifnotnumtonameallcaps\lowernumtonametrue\fi\nNamec
      \priornumtrue
    \fi
%% tens/units thousands
    \ifnum \c@xksm@mctr > \z@
      \ifpriornum
        \ifnum\c@cksm@mctr>\z@\namenumberand\else\namenumbercomma\fi
      \fi
      \tensnumbername{\thexksm@mctr}{\theksm@mctr}%
      \priornumtrue
    \else
      \ifnum \c@ksm@mctr > \z@
        \ifpriornum
          \ifnum\c@cksm@mctr>\z@\namenumberand\else\namenumbercomma\fi
        \fi
        \unitnumbername{\theksm@mctr}%
        \ifnotnumtonameallcaps\lowernumtonametrue\fi
        \priornumtrue
      \fi
    \fi
    \ifnum \c@cksm@mctr > \z@
      \ifpriornum\space\fi
      \nNamem
    \else
      \ifnum \c@xksm@mctr > \z@
        \ifpriornum\space\fi
        \nNamem
      \else
        \ifnum \c@ksm@mctr > \z@
          \ifpriornum\space\fi
          \nNamem
        \fi
      \fi
    \fi
%% hundreds
    \ifnum \c@csm@mctr > \z@
      \ifpriornum\namenumbercomma\fi
      \unitnumbername{\thecsm@mctr}\space
        \ifnotnumtonameallcaps\lowernumtonametrue\fi\nNamec
      \priornumtrue
    \fi
%% tens/units
  \ifmakeordinal
    \ifnum \c@xsm@mctr > \z@
      \ifpriornum\namenumberand\fi
      \tensordinalname{\thexsm@mctr}{\theism@mctr}%
    \else
      \ifnum \c@ism@mctr > \z@
        \ifpriornum\namenumberand\fi
        \unitordinalname{\theism@mctr}%
      \else
        \ifpriornum\nthstring\else\unitordinalname{\theism@mctr}\fi
      \fi
    \fi
  \else  % not ordinal
    \ifnum \c@xsm@mctr > \z@
      \ifpriornum\namenumberand\fi
      \tensnumbername{\thexsm@mctr}{\theism@mctr}%
    \else
      \ifnum \c@ism@mctr > \z@
        \ifpriornum\namenumberand\fi
        \unitnumbername{\theism@mctr}%
      \else
        \ifpriornum\else\unitnumbername{\theism@mctr}\fi
      \fi
    \fi
  \fi % end ifmakeordinal
\endgroup}

\DeclareRobustCommand{\numtoname}[1]{%
  \makeordinalfalse
  \notnumtonameallcapstrue%
  \lowernumtonametrue%
  \n@me@number{#1}}

\DeclareRobustCommand{\numtoName}[1]{%
  \makeordinalfalse
  \notnumtonameallcapstrue%
  \lowernumtonamefalse%
  \n@me@number{#1}}

\DeclareRobustCommand{\NumToName}[1]{%
  \makeordinalfalse
  \notnumtonameallcapsfalse%
  \lowernumtonamefalse%
  \n@me@number{#1}}

\DeclareRobustCommand{\ordinaltoname}[1]{%
  \makeordinaltrue
  \notnumtonameallcapstrue%
  \lowernumtonametrue%
  \n@me@number{#1}}

\DeclareRobustCommand{\ordinaltoName}[1]{%
  \makeordinaltrue
  \notnumtonameallcapstrue%
  \lowernumtonamefalse%
  \n@me@number{#1}}

\DeclareRobustCommand{\OrdinalToName}[1]{%
  \makeordinaltrue
  \notnumtonameallcapsfalse%
  \lowernumtonamefalse%
  \n@me@number{#1}}

\long\def \@topnewpage [#1]{%
  \@nodocument
  \@next\@currbox\@freelist{}{}%
  \global \setbox\@currbox
    \vbox {%
      \break
      \prevdepth\z@
      \begingroup
      \normalcolor
      \hsize\textwidth
      \@parboxrestore
      \col@number \@ne
      #1%
      \vskip -\dbltextfloatsep
      \endgroup
      \null % ordinary \baselineskip
      \vskip -\topskip
  }%
  \begingroup %% \showbox\@currbox
    \splitmaxdepth\maxdepth \splittopskip\topskip
    \setbox\@tempboxa \vsplit\@currbox to \z@
  \endgroup %% \showbox\@currbox
  \ifdim \ht\@currbox>\textheight
    \ht\@currbox \textheight
  \fi
  \global \count\@currbox \tw@
  \@tempdima -\ht\@currbox
  \advance \@tempdima -\dbltextfloatsep
  \global \advance \@colht \@tempdima
  \ifx \@dbltoplist \@empty
  \else
    \@latexerr{Float(s) lost}\@ehb
    \let \@dbltoplist \@empty
  \fi
  \@cons \@dbltoplist \@currbox
  \global \@dbltopnum \m@ne
  \ifdim \@colht<2.5\baselineskip
    \@latex@warning@no@line {Optional argument of \noexpand\twocolumn
        too tall on page \thepage}%
    \@emptycol
    \if@firstcolumn
    \else
      \@emptycol
    \fi
  \else
    \global \vsize \@colht
    \global \@colroom \@colht
    \@floatplacement
  \fi}

\newcommand*{\m@mcalchm}{%
  \count0 = \time \divide \count0 by 60\relax
  \count2 = \count0\relax%    the hour
  \count4 = \time \multiply\count0 by 60\relax
  \advance\count4 by -\count0\relax% the minute
  \ifnum\count4<10 \toks1 = {0}%  make a leading zero
  \else \toks1 = {}%
  \fi}
%%% punctuation, am and pm for \printtime
\newcommand*{\hmpunct}{:}% hours minutes separator
\newcommand*{\amname}{am}% ante meridiem
\newcommand*{\pmname}{pm}% post meridiem

\newcommand*{\printtime}{%
  \@ifstar{\m@msprtime}{\m@mprtime}}
\newcommand*{\m@mprtime}{\begingroup
  \m@mcalchm
  \number\count2\hmpunct\the\toks1 \number\count4
  \endgroup}
\newcommand*{\m@msprtime}{\begingroup
  \m@mcalchm
  \def\@mpm{\pmname}%
  \ifnum\count2<1\relax% early in the morning
    \count2=12\relax
    \ifnum\count4>0\relax% not midnight
      \def\@mpm{\amname}%
    \fi
  \else
    \ifnum\time<721\relax% noon or earlier
      \def\@mpm{\amname}%
    \else
      \ifnum\time>779\relax% 1300 hrs or later
        \advance\count2 by -12\relax
      \fi
    \fi
  \fi
  \number\count2\hmpunct\the\toks1 \number\count4\ \@mpm
  \endgroup}

\newcounter{sheetsequence}
  \setcounter{sheetsequence}{1}
  \renewcommand{\thesheetsequence}{\@arabic\c@sheetsequence}
\g@addto@macro{\@outputpage}{\stepcounter{sheetsequence}}

\newcounter{lastsheet}
  \setcounter{lastsheet}{0}
\newcounter{lastpage}
  \setcounter{lastpage}{0}

\newcommand{\dol@stsheet}{%
  \if@filesw
    \addtocounter{sheetsequence}{-1}%
    \immediate\write\@auxout%
      {\string\memsetcounter{lastsheet}{\the\c@sheetsequence}}%
    \stepcounter{sheetsequence}%
  \fi}
\newcommand{\dol@stpage}{%
  \if@filesw
    \addtocounter{page}{-1}%
    \immediate\write\@auxout%
      {\string\memsetcounter{lastpage}{\the\c@page}}%
    \stepcounter{page}%
  \fi}
\AtBeginDocument{\AtEndDocument{\clearpage\dol@stsheet\dol@stpage}}

\newif\ifcntrmod
\newif\ifnotcntrmod
\newcommand*{\iscntrmod}[2]{
  \@tempcnta=\@nameuse{c@#1}%
  \@tempcntb=\@tempcnta
  \divide\@tempcnta #2\relax
  \multiply\@tempcnta #2\relax
  \advance\@tempcntb-\@tempcnta
  \ifnum\@tempcntb=0\relax
    \cntrmodtrue
    \notcntrmodfalse
  \else
    \cntrmodfalse
    \notcntrmodtrue
  \fi}

\newcommand*{\@memensuresigpages}{%
  \ifnum\@mempagespersig<\@ne
  \else
    \iscntrmod{sheetsequence}{\@mempagespersig}
    \ifcntrmod
    \else
        \clearpage
        \pagestyle{empty}
        \mbox{}
      \loop
        \iscntrmod{sheetsequence}{\@mempagespersig}
        \ifnotcntrmod
        \clearpage
        \pagestyle{empty}
        \mbox{}
      \repeat
    \fi
  \fi}

\newcommand*{\leavespergathering}[1]{\@memcnta=#1\relax
                                     \ifnum\@memcnta<\tw@
                                       \def\@mempagespersig{-1}%
                                     \else
                                       \multiply\@memcnta \tw@
                                       \edef\@mempagespersig{\@memcnta}%
                                     \fi}
\leavespergathering{0}

\AtEndDocument{\@memensuresigpages}

\expandafter\let\csname MemOrigMakeUppercase \expandafter\endcsname
                \csname MakeUppercase \endcsname
\expandafter\let\csname MemOrigMakeLowercase \expandafter\endcsname
                \csname MakeLowercase \endcsname
\def\MemRestoreOrigMakecase{
  \expandafter\let\csname MakeUppercase \expandafter\endcsname
                  \csname MemOrigMakeUppercase \endcsname
  \expandafter\let\csname MakeLowercase \expandafter\endcsname
                  \csname MemOrigMakeLowercase \endcsname
}
\IfFileExists{textcase.sty}{
  \RequirePackage[overload]{textcase}
  }{% resort to the
  \@memwarn{Haven't found the textcase package,\MessageBreak resorting to embedded
   copy of v0.07 (2004/10/07),\MessageBreak consider installing the textcase package}
%%%%      Nearly a carbon copy from textcase.dtx by David Carlisle
%%%% Since we are inside a \IfFileExists we need to double the #/daleif
\def\@uclcnotmath##1##2##3##4{\begingroup
      ##1%
      \def\({$}\let\)\(% $ for emacs :-)
      \def\NoCaseChange####1{\noexpand\NoCaseChange{\noexpand####1}}%
      \@nonchangecase\label
      \@nonchangecase\ref
      \@nonchangecase\ensuremath
      \def\cite####1####{\toks@{\noexpand\cite####1}\@citex}%
      \def\@citex####1{\NoCaseChange{\the\toks@{####1}}}%
      \def\reserved@a####1####2{\let##2\reserved@a}%
      \expandafter\reserved@a\@uclclist\reserved@b{\reserved@b\@gobble}%
      \protected@edef\reserved@a{\endgroup
          \noexpand\@skipmath##3##4$\valign$}%
      \reserved@a}
\def\@nonchangecase##1{\def##1####1{\NoCaseChange{##1{####1}}}}
\let\NoCaseChange\@firstofone
\def\@skipmath##1##2$##3${%
  \@skip@nonchangecase##1##2\NoCaseChange\valign
  \ifx\valign##3%
  \else
    $##3$%
    \expandafter\@skipmath\expandafter##1%
  \fi}
\def\@skip@nonchangecase##1##2\NoCaseChange##3{%
  ##1{##2}%
  \ifx\valign##3%
  \else
    ##3%
    \expandafter\@skip@nonchangecase\expandafter##1%
  \fi}
\DeclareRobustCommand\MakeTextUppercase{%
  \@uclcnotmath{\def\i{I}\def\j{J}}{####1####2}\uppercase}
\protected@edef\MakeTextUppercase##1{\MakeTextUppercase{##1}}
\DeclareRobustCommand\MakeTextLowercase{%
  \@uclcnotmath{}{####2####1}\lowercase}
\protected@edef\MakeTextLowercase##1{\MakeTextLowercase{##1}}
%%%% End copy from textcase.dtx
} % end of \IfFileExists
\newcommand*{\abstractname}{Abstract}
\newcommand*{\contentsname}{Contents}
\newcommand*{\listfigurename}{List of Figures}
\newcommand*{\listtablename}{List of Tables}
\newcommand*{\bookname}{Book}
\newcommand*{\partname}{Part}
\newcommand*{\chaptername}{Chapter}
\newcommand*{\appendixname}{Appendix}
\newcommand*{\appendixtocname}{Appendices}
\newcommand*{\appendixpagename}{Appendices}
\newcommand*{\bibname}{Bibliography}
\newcommand*{\indexname}{Index}
\newcommand*{\glossaryname}{Glossary}
\newcommand*{\figurename}{Figure}
\newcommand*{\tablename}{Table}
\newcommand*{\figurerefname}{Figure}
\newcommand*{\tablerefname}{Table}
\newcommand*{\pagename}{page}
\newcommand*{\pagerefname}{page}
\newcommand*{\bookrefname}{Book~}
\newcommand*{\partrefname}{Part~}
\newcommand*{\chapterrefname}{Chapter~}
\newcommand*{\sectionrefname}{\S}
\newcommand*{\appendixrefname}{Appendix~}

\newcommand{\today}{\ifcase\month\or
  January\or February\or March\or April\or May\or June\or
  July\or August\or September\or October\or November\or December\fi
  \space\number\day, \number\year}
\setlength\columnsep{10\p@}
\setlength\columnseprule{0\p@}
\setcounter{part}{0}
\setcounter{chapter}{0}
\setcounter{tocdepth}{1}
\setcounter{secnumdepth}{2}
\maxsecnumdepth{section}

\linenumberfrequency{0}
\linenumberfont{\small\rmfamily}
\settowidth{\bvnumlength}{\vlvnumfont 9999}

\if@twoside
\else
  \raggedbottom
\fi
\if@twocolumn
  \twocolumn
  \sloppy
  \flushbottom
\else
  \onecolumn
\fi

\newfloat[chapter]{figure}{lof}{\figurename}
%%%  \kill@lastcounter{lofdepth}
\renewcommand{\thefigure}{\thechapter.\@arabic\c@figure}

\newlistof{listoffigures}{lof}{\listfigurename}
%%%  \kill@lastcounter{lofdepth}
\newlistentry[chapter]{figure}{lof}{0}
  \cftsetindents{figure}{0em}{2.3em}
%%  \kill@lastcounter{lofdepth}

\newfloat[chapter]{table}{lot}{\tablename}
%%%  \kill@lastcounter{lotdepth}
\renewcommand{\thetable}{\thechapter.\@arabic\c@table}

\newlistof{listoftables}{lot}{\listtablename}
%%%  \kill@lastcounter{lotdepth}
\newlistentry[chapter]{table}{lot}{0}
  \cftsetindents{table}{0em}{2.3em}
%%  \kill@lastcounter{lotdepth}

%%%\AtBeginDocument{%
%%%  \@ifundefined{c@lofdepth}%
%%%     {\newcounter{lofdepth}\setcounter{lofdepth}{1}}{}
%%%  \@ifundefined{c@lotdepth}%
%%%     {\newcounter{lotdepth}\setcounter{lotdepth}{1}}{}}

\ifartopt
  \chapterstyle{article}
  \counterwithout{figure}{chapter}
  \counterwithout{table}{chapter}
  \counterwithout{footnote}{chapter}
  \counterwithout{equation}{chapter}
  %\renewcommand{\chaptername}{}
  \if@twoside
    \addtopsmarks{headings}{}{%
      \createmark{chapter}{left}{shownumber}{}{. \ }
    }
  \else
    \addtopsmarks{headings}{}{%
      \createmark{chapter}{right}{shownumber}{}{. \ }
    }
  \fi
  \renewcommand{\maketitlehookb}{%
    \vskip -1.5\topsep\vskip -1.5\partopsep}
  \renewcommand{\maketitlehookc}{%
    \vskip -1.5\topsep\vskip -1.5\partopsep}
\fi

\newcommand{\msdoublespacing}{}
\newcommand{\mssinglespacing}{}
\ifmsdoc
  \renewcommand{\msdoublespacing}{%
    \renewcommand{\baselinestretch}{1.6}\large\normalsize}
  \renewcommand{\mssinglespacing}{%
    \renewcommand{\baselinestretch}{1.0}\large\normalsize}
  \renewcommand{\familydefault}{cmtt}
  \renewcommand{\rmdefault}{cmtt}
  \renewcommand{\sfdefault}{cmtt}
  \renewcommand{\bfdefault}{m}
  \renewcommand{\itdefault}{n}
  \renewcommand{\sldefault}{n}
  \renewcommand{\scdefault}{n}
  \renewcommand{\baselinestretch}{1.6}
  \@twocolumnfalse
  \onecolumn
  \sloppy
  \@twosidefalse
  \raggedbottom
  \pagestyle{plain}
\fi

\EmulatedPackage{abstract}[2008/07/23]
\EmulatedPackage{appendix}[2008/07/23]
 % \EmulatedPackage{array}[2016/10/06]
 % \EmulatedPackage{booktabs}[2016/05/16]
\EmulatedPackage{ccaption}[2008/07/23]
\EmulatedPackage{changepage}[2008/07/23]
\EmulatedPackage{chngcntr}[2008/07/23]
\EmulatedPackage{chngpage}[2008/07/23]
\EmulatedPackage{crop}
 % \EmulatedPackage{dcolumn}[2008/07/23]
 % \EmulatedPackage{delarray}[2014/10/28]
\EmulatedPackage{enumerate}[2008/07/23]
\EmulatedPackage{epigraph}[2008/07/23]
%%%%%\EmulatedPackage{framed}[2008/07/23]
\EmulatedPackage{ifmtarg}[2008/07/23]
 %\ifm@mifetex\EmulatedPackage{ifetex}[2008/07/23]\fi
 %\ifm@mifluatex\EmulatedPackage{ifluatex}[2008/07/23]\fi
 %\ifm@mifpdf\EmulatedPackage{ifpdf}[2008/07/23]\fi
 %\ifm@mifxetex\EmulatedPackage{ifxetex}[2008/07/23]\fi
\EmulatedPackage{index}[2008/07/23]
\EmulatedPackage{makeidx}[2008/07/23]
\EmulatedPackage{moreverb}[2008/07/23]
\if@twocolumn
  \RequirePackage{mparhack}
\fi
  %\EmulatedPackage{mparhack}[2008/07/23]
\EmulatedPackage{needspace}[2008/07/23]
\EmulatedPackage{newfile}[2008/07/23]
\EmulatedPackage{nextpage}[2008/07/23]
\EmulatedPackage{pagenote}[2008/07/23]
\EmulatedPackage{parskip}[2008/07/23]
\EmulatedPackage{patchcmd}[2008/07/23]
\EmulatedPackage{setspace}[2008/07/23]
\EmulatedPackage{shortvrb}[2008/07/23]
\EmulatedPackage{showidx}[2008/07/23]
 % \EmulatedPackage{tabularx}[2016/02/03]
\EmulatedPackage{titleref}[2008/07/23]
\EmulatedPackage{titling}[2008/07/23]
\EmulatedPackage{tocbibind}[2008/07/23]
\EmulatedPackage{tocloft}[2008/07/23]
\EmulatedPackage{tocvsec2}[2008/07/23]
\EmulatedPackage{verbatim}[2008/07/23]
\EmulatedPackage{verse}[2008/07/23]

\AtBeginPackage{float}{\let\newfloat\relax}

\AtEndPackage{hyperref}{\RequirePackage{memhfixc}}
\ifartopt
\pagestyle{plain}
\else
\pagestyle{headings}
\fi
\pagenumbering{arabic}


\endinput
%%
%% End of file `memoir.cls'.
