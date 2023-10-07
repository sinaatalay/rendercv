
% This class is buggy and needs fixing

\ProvidesClass{source2edoc}
              [2022/04/03 v0.2c Quick hack to typeset source2.tex
               (not usable for anything else and buggy -- will vanish again)!]



\LoadClass{l3doc}

\RemoveFromHook{begindocument}[l3doc]          % drop the standard setting  making " a shortverb
\AddToHook{begindocument}{\MakeShortVerb \|}   % but readd | as one

%\ShowHook{begindocument}




\ExplSyntaxOn

% in 2e we have a lot of functions that have no ``user-level'' documentation so we disable
% a bogus backref in that case. Over time the sources should be cleaned up to have such documentation.

\cs_set_protected:Npn \__codedoc_print_documented:
  {
    \seq_gset_filter:NNn \g__codedoc_nested_names_seq
      \g__codedoc_nested_names_seq
      { ! \__codedoc_if_macro_internal_p:n {##1} }
    \seq_if_empty:NF \g__codedoc_nested_names_seq
      {
% This is a crude change: we grab the first name
        \__codedoc_get_hyper_target:xN
          { \seq_item:Nn \g__codedoc_nested_names_seq { 1 } }
          \l__codedoc_tmpa_tl
% ... and check if it has a reference
        \cs_if_exist:cT{ r@\l__codedoc_tmpa_tl }
% If it does we show it, if not we don't.
         {
           \int_set:Nn \l__codedoc_tmpa_int
             { \seq_count:N \g__codedoc_nested_names_seq }
           \int_compare:nNnTF \l__codedoc_tmpa_int = 1 {~This~} {~These~}
           \bool_if:NTF \l__codedoc_macro_var_bool {variable} {function}
           \int_compare:nNnTF \l__codedoc_tmpa_int = 1 {~is~} {s~are~}
           documented~on~page~
           \exp_args:Nx \pageref { \l__codedoc_tmpa_tl } .
         }
      }
    \seq_gclear:N \g__codedoc_nested_names_seq
  }


  
% some l3doc's def are buggy (already fixed there but not distributed yet)

\RenewDocumentCommand \DocInclude { m }
  {
    \relax\clearpage
    \docincludeaux
    \IfFileExists{#1.fdd}
      { \cs_set:Npn \currentfile{#1.fdd} }
      { \cs_set:Npn \currentfile{#1.dtx} }
    \int_compare:nNnTF \@auxout = \@partaux
      { \@latexerr{\string\include\space cannot~be~nested}\@eha }
      { \@docinclude {#1} }  % <--- braces needed!
    \int_compare:nNnF { \tex_currentgrouplevel:D } = { 0 }
      {
        \int_compare:nNnT { \tex_interactionmode:D } = { 0 }
          { \int_set:Nn \tex_interactionmode:D { 1 } }
        \msg_fatal:nnn { source2edoc } { missing-endgroup } {#1}
      }
  }
\msg_new:nnn { source2edoc } { missing-endgroup }
  {
    \str_if_eq:VnTF \@currenvir { document }
      {
        There~are~\int_use:N \tex_currentgrouplevel:D
        \c_space_tl unclosed~groups~in~#1.dtx.
      }
      {
        The~\@currenvir \c_space_tl environment~on~line~\@currenvline
        \c_space_tl doesn't~have~a~matching~\iow_char:N\\end{\@currenvir}.
      }
  }
\cs_gset:Npn \@docinclude #1
  {
    \clearpage
    \immediate\write\@mainaux{\string\@input{#1.aux}}
    \@tempswatrue
    \if@partsw
      \@tempswafalse
      \cs_set:Npx \@tempb {#1}
      \clist_map_inline:Nn \@partlist
        {
          \if_meaning:w \@tempa \@tempb
            \@tempswatrue
          \fi:
        }
    \fi
    \if@tempswa
      \cs_set_eq:NN \@auxout                 \@partaux
      \immediate\openout\@partaux #1.aux
      \immediate\write\@partaux{\relax}
      \cs_set_eq:NN \@ltxdoc@PrintIndex      \PrintIndex
      \cs_set_eq:NN \PrintIndex              \relax
      \cs_set_eq:NN \@ltxdoc@PrintChanges    \PrintChanges
      \cs_set_eq:NN \PrintChanges            \relax
      \cs_set_eq:NN \@ltxdoc@theglossary     \theglossary
      \cs_set_eq:NN \@ltxdoc@endtheglossary  \endtheglossary
      \part{\currentfile}
      {
        \cs_set_eq:NN \ttfamily\relax
        \cs_gset:Npx \filekey
          { \filekey,~ \thepart = { \ttfamily \currentfile } } % <-- mising spaces considered harmful
      }
      \DocInput{\currentfile}
      \cs_set_eq:NN \PrintIndex              \@ltxdoc@PrintIndex
      \cs_set_eq:NN \PrintChanges            \@ltxdoc@PrintChanges
      \cs_set_eq:NN \theglossary             \@ltxdoc@theglossary
      \cs_set_eq:NN \endtheglossary          \@ltxdoc@endtheglossary
      \clearpage
      \@writeckpt{#1}
      \immediate \closeout \@partaux
    \else
      \@nameuse{cp@#1}
    \fi
    \cs_set_eq:NN \@auxout \@mainaux
  }


% change the setup here: we have a lot of long names so better run raggeded
  
\cs_set_protected:Npn \__codedoc_macro_end_style:n #1
  {
    \nobreak \noindent
    { \raggedright\hangindent1pc \footnotesize ( \emph{#1} ) \par }
  }

  
% next two declarations should move to l3doc.cls in the l3kernel eventually
% they should be ``new'' not ``set'' but to avoid getting in timing issues
% when they will be officially defined we use ``set'' here
  
\cs_set_eq:NN \__codedoc_saved_detect_internals:N \__codedoc_detect_internals:N

% maybe this change should be local so that it automatically reverts on \verb=\end{macro}=
% without the need to explicitly turn it on again.

\cs_new_protected:Npn \InternalDetectionOff
  { \cs_gset_eq:NN \__codedoc_detect_internals:N \use_none:n }
\cs_new_protected:Npn \InternalDetectionOn
  { \cs_gset_eq:NN \__codedoc_detect_internals:N \__codedoc_saved_detect_internals:N }
  
\ExplSyntaxOff

\def\partname{File}


\gdef\codeline@wrindex#1{\if@filesw
      \begingroup
        \let\protect\noexpand
        \immediate\write\@indexfile
            {\string\indexentry{#1}%
            {\filesep\number\c@CodelineNo}}%
      \endgroup\fi}
\let\filesep\@empty
\def\aalph#1{\@aalph{\csname c@#1\endcsname}}
\def\@aalph#1{%
  \ifcase#1\or a\or b\or c\or d\or e\or f\or g\or h\or i\or
         j\or k\or l\or m\or n\or o\or p\or q\or r\or s\or
         t\or u\or v\or w\or x\or y\or z\or A\or B\or C\or
         D\or E\or F\or G\or H\or I\or J\or K\or L\or M\or
         N\or O\or P\or Q\or R\or S\or T\or U\or V\or W\or
         X\or Y\or Z\or
         aa\or bb\or cc\or  % we are getting definitely too many modules
         dd%
         \else\@ctrerr\fi}
\def\docincludeaux{%
  \def\thepart{\aalph{part}}\def\filesep{\thepart-}%
  \let\filekey\@gobble
  \g@addto@macro\index@prologue{%
    \gdef\@oddfoot{\parbox[t]{\textwidth}{\strut\footnotesize
       \raggedright{\bfseries File Key:} \filekey}}%
    \let\@evenfoot\@oddfoot}%
  \global\let\docincludeaux\relax
 \gdef\@oddfoot{%
   \expandafter\ifx\csname ver@\currentfile\endcsname\relax
    File \thepart: {\ttfamily\currentfile} %
   \else
    \GetFileInfo{\currentfile}%
    File \thepart: {\ttfamily\filename} %
    Date: \filedate\ %
    Version \fileversion
    \fi
    \hfill\thepage}%
 \let\@evenfoot\@oddfoot}%
\def\MaintainedBy#1{\gdef\@maintainedby{#1}}
\let\@maintainedby\@empty
\def\MaintainedByLaTeXTeam#1{%
{\gdef\@maintainedby{%
This file is maintained by the \LaTeX{} Project team.\\%
Bug reports can be opened (category \texttt{#1}) at\\%
\url{https://latex-project.org/bugs.html}.}}}
\def\@maketitle{%
  \newpage
  \null
  \vskip 2em%
  \begin{center}%
  \let \footnote \thanks
    {\LARGE \@title \par}%
    \vskip 1.5em%
    {\large
      \lineskip .5em%
      \begin{tabular}[t]{c}%
        \@author
      \end{tabular}\par}%
    \vskip 1em%
    {\large \@date}%
    \ifx\@maintainedby\@empty
    \else
    \vskip 1em%
    \fbox{\fbox{\begin{tabular}{@{}l@{}}\@maintainedby\end{tabular}}}%
    \fi
  \end{center}%
  \par
  \vskip 1.5em}
\providecommand\url{\texttt}
\def\task#1#2{}


\def\oc@scan#1{%
  \ifx\oc@bslash#1%
                      \egroup\let\next\oc@bslash\else
  \ifcat a\noexpand#1%
                      #1\let\next\oc@scan\else
  \ifx\oc@percent#1%
                      \def\next{\char`\%\egroup}%
  \else
                      #1\let\next\egroup
  \fi\fi\fi\next}
\def\oc@bslash{\bgroup\oc@ttf\char`\\\oc@scan}%
\def\oc@verb#1{%
  \catcode`#1\active
  \uccode`\~`#1%
  \uppercase{\def~{{\oc@ttf\char`#1}}}}
\begingroup
  \obeyspaces%
  \catcode`\/=\catcode`\\
  /catcode`/\/active
  /catcode`<=/catcode`{%
  /catcode`>=/catcode`}%
  /catcode`/{/active%
  /catcode`/}/active%
  /gdef/oldc< \end{oldcomments}>%
  /gdef/begmac<    \begin{macrocode}>%
  /gdef/obs</def <</oc@ttf/ >>>%
/endgroup%
\begingroup
  \catcode`\/=\catcode`\\
  \catcode`\\=13
  /catcode`/|=/catcode`/%
  /catcode`/%=13
  /gdef/oldcomments{|
    /makeatletter
    /let/do/oc@verb/dospecials
    /frenchspacing/@vobeyspaces/obs
    /raggedright
    /oc@verb/>|
    /oc@verb/<|
    /let\/oc@bslash
    /let%/oc@percent
    /obeylines
    /parindent/z@
    /ttfamily/expandafter/let/expandafter/oc@ttf/the/font
    /rmfamily
    /textit{Historical /LaTeX/,2.09 comments (not necessarily accurate any more):}
    /hfuzz/maxdimen
    }
/endgroup
\begingroup
  \sloppy%
  \obeylines%
  \gdef\oc@percent#1^^M{%
    \ifvmode%
    \def\commentline{#1}%
    \ifx\commentline\oldc%
    \textit{End of historical \LaTeX\,2.09 comments.}
    \end{oldcomments}%
    \else%
    \ifx\commentline\begmac%
    \begin{macrocode}%
    \else%
    \leavevmode%
    #1^^M%
    \fi\fi%
    \else%
    {\oc@ttf\char`\%}#1^^M%
    \fi}%
\endgroup%


% don't run tocs when they are in some module files
\AddToHook{cmd/tableofcontents/after}{\global\let\tableofcontents\relax} 


\InputIfFileExists{ltxdoc.cfg}
           {\typeout{*************************************^^J%
                     * Local config file ltxdoc.cfg used^^J%
                     *************************************}}
           {}



\errorstopmode
\batchmode           

\endinput
