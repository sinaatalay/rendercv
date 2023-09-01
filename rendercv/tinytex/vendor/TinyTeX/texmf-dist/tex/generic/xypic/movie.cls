%% $Id: movie.cls,v 3.7 2011/03/14 20:14:00 krisrose Exp $ -*-latex-*-
%%
%% ``LaTeX Movie'' document class for DVI animations.
%% Copyright (c) 1994-1997	Kristoffer H. Rose  <krisrose@tug.org>
%%
%% This file is part of the Xy-pic package for graphs and diagrams in TeX.
%% Copyright (c) 1991-2011	Kristoffer H. Rose  <krisrose@tug.org>
%%
%% The Xy-pic package is free software; you can redistribute it and/or modify
%% it under the terms of the GNU General Public License as published by the
%% Free Software Foundation; either version 2 of the License, or (at your
%% option) any later version.
%%
%% The Xy-pic package is distributed in the hope that it will be useful, but
%% WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
%% or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License
%% for more details.
%%
%% You should have received a copy of the GNU General Public License along
%% with this package; if not, see http://www.gnu.org/licenses/.
%%
\ifx\xyloaded\undefined \input xy \fi

\NeedsTeXFormat{LaTeX2e}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Version.

\def\next$#1: #2 #3${#2}
\edef\next{\noexpand\ProvidesClass{movie}%
  [\next$Date: 2011/03/14 20:14:00 $
   Movies in LaTeX v.\next$Revision: 3.7 $.]}\next

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Options.

% nocaption  (omit caption at lower left; default)
% caption    (include caption)
\newif\ifm@caption
\DeclareOption{nocaption}{\m@captionfalse}
\DeclareOption{caption}{\m@captiontrue}

% nocount  (omit count at lower left; default)
% count    (include count)
\newif\ifm@count
\DeclareOption{nocount}{\m@countfalse}
\DeclareOption{count}{\m@counttrue}

% notime  (omit elapsed time in "seconds"; default)
% time    (include elapsed time)
\newif\ifm@time
\DeclareOption{notime}{\m@timefalse}
\DeclareOption{time}{\m@timetrue}

% loop  (make the animation loop; default)
% once  (don't loop)
\def\loop@@{-ns2}
\DeclareOption{loop}{\def\loop@@{-ns2}}
\DeclareOption{once}{\def\loop@@{-once}}

% Paper size (ignored since result is never printed).
\DeclareOption{a4paper}{}
\DeclareOption{a5paper}{}
\DeclareOption{b5paper}{}
\DeclareOption{letterpaper}{}
\DeclareOption{legalpaper}{}
\DeclareOption{executivepaper}{}
\DeclareOption{landscape}{}

%\vsize=9in \voffset=0in
%\hsize=7in \hoffset=0in % safe? :)

\newdimen\textheight \textheight=\vsize
\newdimen\textwidth  \textwidth=\hsize

% Font size.
\renewcommand\normalsize{\fontsize{10}{12}\selectfont}
\DeclareOption{10pt}{\renewcommand\normalsize{\fontsize{10}{12}\selectfont}}
\DeclareOption{11pt}{\renewcommand\normalsize{\fontsize{11}{13}\selectfont}}
\DeclareOption{12pt}{\renewcommand\normalsize{\fontsize{12}{14}\selectfont}}

% Driver (passed on to packages).
\DeclareOption{cmactex}{\OptionNotUsed}
\DeclareOption{dvips}{\OptionNotUsed}
\DeclareOption{dvitops}{\OptionNotUsed}
\DeclareOption{emtex}{\OptionNotUsed}
\DeclareOption{ln}{\OptionNotUsed}
\DeclareOption{oztex}{\OptionNotUsed}
\DeclareOption{textures}{\OptionNotUsed}
\DeclareOption{xdvi}{\OptionNotUsed}

% ...remaining options are numeric assignments...
\def\m@keys{}
\def\add@m@keys#1{\expandafter\def\expandafter\m@keys\expandafter{\m@keys,#1}}
\DeclareOption*{\expandafter\add@m@keys\expandafter{\CurrentOption}}

\ProcessOptions*

\LoadClass{article}
\pagestyle{empty}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dependencies.

\RequirePackage{keyval}         % key=value pair support
\input xy                       % Xy-pic kernel (not package to prevent clash)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Parameters (set via options or the setup).

% pixel=<dimen>  (makes \pixels{<number>} a valid <dimen>; default: 1in/300)
% dpi=<number>   (dots per inch ~ pixel=1in/number)
\newdimen\m@pixel \m@pixel=0.0033333333in
\define@key{movie}{pixel}{\m@pixel=#1\relax}
\define@key{movie}{dpi}{\m@pixel=1in \divide \m@pixel by #1\relax}

% height=<dimen>
% width=<dimen>
\newdimen\m@height \m@height=2in
\newdimen\m@width  \m@width=2in
\define@key{movie}{height}{\m@height=#1\relax}
\define@key{movie}{width}{\m@width=#1\relax}

% tick=<fraction>  (set the duration of each frame to <fraction> seconds)
% fps=<number>     (frames per second ~ tick=1/number)
\newdimen\m@tick \m@tick=0.083333333pt
\define@key{movie}{tick}{\m@tick=#1pt\relax}
\define@key{movie}{fps}{\m@tick=1pt \divide \m@tick by #1\relax}

\def\next#1{\setkeys{movie}{#1}}
\expandafter\next\expandafter{\m@keys}
\let\m@keys=\undefined

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Setting parameters explicitly...

\def\MovieSetup#1{\setkeys{movie}{#1}}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Internals.

\def\m@caption{}

\countdef\m@scene=1             % count1 = scene#
\countdef\m@frame=2             % count2 = frame# (in scene)

\font\fiverm=cmr5               % safe small font

\newdimen\m@total \m@total=0pt  % total elapsed time

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% User accessible progress macros:

\def\theFrame{0}
\def\theScene{0}

\def\theF{0}
\def\theFr{1}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% User command: \scene [<fraction>] {...}
%
% Produce scene of <fraction> seconds (default: 1.0) with each frame produced
% by ... centered in vertical mode.

\newif\iflastframe@
\newdimen\m@length              % duration of scene
\newdimen\m@init                % start of zoom

\newcommand\scene{%
  \@ifnextchar*{\lastframe@true \DN@*{\scene@i}\next@}%
    {\lastframe@false \scene@i}}

\newcommand\scene@i[1][1]{\scene@ii{#1}}

\def\setm@caption#1{\xdef\m@caption{#1}}

\long\def\scene@ii#1#2{{%
    \let\caption=\setm@caption
    \global\advance\m@scene\@ne \edef\theScene{\the\m@scene}%
    \global\m@frame=\z@ \m@length=#1pt \m@init=\z@
    \loop
      \dimen@=\m@frame\m@tick
    \ifdim\dimen@<\m@length
      \scene@frame{#2}%
    \repeat
    \iflastframe@ \scene@frame{#2}\fi
    \dimen@=#1pt \advance\dimen@ by -\m@frame\m@tick
    \ifdim.1\m@tick<\ifdim\dimen@<\z@-\fi\dimen@
      \dimen@=\m@frame\m@tick
      \@warning{scene \the\m@scene\space rounded from #1 to
        \expandafter\unPT@\the\dimen@\space seconds}%
    \fi}\ignorespaces}

\def\scene@frame#1{\frame@compute
  \null
  \vfill
  \hrule width\m@width
  \hbox to\m@width{\hss
    \vbox to\m@height{\hsize=\m@width \null\vfil{#1}\vfil\null}%
    \hss}%
  \setbox0=\hbox{%
    \setbox0=\hbox to\m@width{\hss\fiverm\strut
      \ifm@caption \m@caption \fi
      \ifm@time \quad \m@nicetotal s \fi
      \ifm@count \quad \the\m@scene.%
        \ifnum\m@frame<100 0\ifnum\m@frame<10 0\fi\fi\the\m@frame\fi}%
    \dimen0=\dp0 \ht0=0pt \dp0=0pt \raise\dimen0\box0}%
  \ht0=0pt \dp0=0pt \box0\relax
  \hrule width\m@width
  \global\advance\m@frame\@ne
  \global\advance\m@total\m@tick
  \eject}

\def\frame@compute{%
  \edef\theFrame{\the\m@frame}%
  \dimen@=\m@frame\m@tick \advance\dimen@-\m@init
  \ifdim\dimen@<\z@ \dimen@=\z@ \fi
  \ifdim\dimen@>\m@length \dimen@=\m@length \fi
  \quotient@\theF\dimen@\m@length
  \dimen@=-\dimen@ \advance\dimen@\m@length
  \quotient@\theFr\dimen@\m@length}

\def\m@nicetotal{%
  \edef\tmp{\expandafter\removePT@\the\m@total}%
  \expandafter\twodecimals@\tmp 00@}
\def\twodecimals@#1.#2#3#4@{#1.#2#3}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Triggers.
%
% Triggers are used to make the individual frames in a scene different! :)

% \F{C} expands to C(F) where F = (#frames / frame#) ; 0.0 < F <= 1.0 .
% \Fr{C} expands to C(Fr) where Fr = 1 - F .

\def\F{\expandafter\F@\expandafter{\theF}}
\def\Fr{\expandafter\F@\expandafter{\theFr}}

\def\F@#1#2{#2(#1)}

% \Zoom[A;B]{C} expands C zooming onto the interval [A;B], i.e., within C the
% interval [0;1] really denotes the (current) interval [A;B] ...

% Specifically:   F     F inside [A;B]
%                0;A          0
%                A;B      F-A / B-A
%                B;1          1

\newcommand\Zoom[1][0;1]{\Zoom@#1;}
\def\Zoom@#1;#2;#3{{%
    \dimen@=#1\m@length \advance\dimen@\m@init
    \m@length=#2\m@length \advance\m@length\m@init
    \advance\m@length-\dimen@ \m@init=\dimen@
    \frame@compute #3}}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Preliminary FADING support...
%
% by Ross Moore; depends on Xy-pic `ps' backend...
%
% use as a <shape> modifier:  \drop[<colour>][!\F\lighten]<object>
% use as a <shape> modifier:  \drop[<colour>][!\F\darken}]<object>
%
%  \lighten(1) = white	\lighten(0) = natural colour
%  \darken (1) = black	\darken (0) = natural colour
%
\def\lighten@(#1){/@col #1 def{1 sub 1 @col sub mul 1 add}settransfer}
\def\darken@(#1){/@col #1 def{1 @col sub mul}settransfer}

\xywithoption{ps}{\let\lighten=\lighten@ \let\darken=\darken@}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Dump size file.
%
\AtEndDocument{\dumpsizefile}

\newwrite\m@write

{\catcode`p=12 \catcode`t=12 \gdef\unPT@#1pt{#1}}

\def\dumpsizefile{\immediate\openout\m@write=\jobname.size
%
 \dimen@=1in \divide\dimen@\m@pixel
 \immediate\write\m@write{dpi=\number\dimen@}%
%
 \dimen@=\m@tick \multiply\dimen@ by 1000\advance\dimen@.5\m@tick
 \divide\dimen@\p@ \immediate\write\m@write{delay=\number\dimen@}%
%
 \immediate\write\m@write{loop=\loop@@}%
%
 \immediate\closeout\m@write}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Misc. class-provided commands...

\DeclareOldFontCommand{\rm}{\normalfont\rmfamily}{\mathrm}
\DeclareOldFontCommand{\sf}{\normalfont\sffamily}{\mathsf}
\DeclareOldFontCommand{\tt}{\normalfont\ttfamily}{\mathtt}
\DeclareOldFontCommand{\bf}{\normalfont\bfseries}{\mathbf}
\DeclareOldFontCommand{\it}{\normalfont\itshape}{\mathit}
\DeclareOldFontCommand{\sl}{\normalfont\slshape}{\@nomath\sl}
\DeclareOldFontCommand{\sc}{\normalfont\scshape}{\@nomath\sc}

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% The End.

\endinput

% $Log: movie.cls,v $
% Revision 3.7  2011/03/14 20:14:00  krisrose
% Preparing for release 3.8.6.
%
% Revision 3.6  2010/06/10 18:45:49  krisrose
% Reference to GPL by URL.
%
% Revision 3.5  2010/04/16 06:06:51  krisrose
% Preparing for a new release...
%
% Revision 3.4  1997/05/18 01:14:25  krisrose
% Essential bugfixes.
%
% Revision 1.5  1997/05/13 12:36:26  krisrose
% Intermediate version; factors function nicely.
%
% Revision 1.4  1997/05/01 21:55:44  krisrose
% Works again.
%
% Revision 1.3  1997/02/11 04:20:19  krisrose
% Fits new dvitogif89a 1.1 :)
%
% Moved to Xy-pic hierarchy.
