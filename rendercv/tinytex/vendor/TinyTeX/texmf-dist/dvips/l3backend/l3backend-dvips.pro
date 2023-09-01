%%
%% This is file `l3backend-dvips.pro',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% l3backend-header.dtx  (with options: `header,dvips')
%% 
%% Copyright (C) 2019-2023 The LaTeX Project
%% 
%% It may be distributed and/or modified under the conditions of
%% the LaTeX Project Public License (LPPL), either version 1.3c of
%% this license or (at your option) any later version.  The latest
%% version of this license is in the file:
%% 
%%    https://www.latex-project.org/lppl.txt
%% 
%% This file is part of the "l3backend bundle" (The Work in LPPL)
%% and all files in that bundle must be distributed together.
%% 
%% File: l3backend-header.dtx
/color.sc { } def
TeXDict begin
/TeXcolorseparation { setcolor } def
end
true setglobal
/pdf.globaldict 4 dict def
false setglobal
/pdf.cvs { 65534 string cvs } def
/pdf.dvi.pt { 72.27 mul Resolution div } def
/pdf.pt.dvi { 72.27 div Resolution mul } def
/pdf.rect.ht { dup 1 get neg exch 3 get add } def
/pdf.linkmargin { 1 pdf.pt.dvi } def
/pdf.linkdp.pad { 0 } def
/pdf.linkht.pad { 0 } def
/pdf.rect
  { /Rect [ pdf.llx pdf.lly pdf.urx pdf.ury ] } def
/pdf.save.ll
  {
    currentpoint
    /pdf.lly exch def
    /pdf.llx exch def
  }
    def
/pdf.save.ur
  {
    currentpoint
    /pdf.ury exch def
    /pdf.urx exch def
  }
    def
/pdf.save.linkll
  {
    currentpoint
    pdf.linkmargin add
    pdf.linkdp.pad add
    /pdf.lly exch def
    pdf.linkmargin sub
    /pdf.llx exch def
  }
    def
/pdf.save.linkur
  {
    currentpoint
    pdf.linkmargin sub
    pdf.linkht.pad sub
    /pdf.ury exch def
    pdf.linkmargin add
    /pdf.urx exch def
  }
    def
/pdf.dest.anchor
  {
    currentpoint exch
    pdf.dvi.pt 72 add
    /pdf.dest.x exch def
    pdf.dvi.pt
    vsize 72 sub exch sub
    /pdf.dest.y exch def
  }
    def
/pdf.dest.point
  { pdf.dest.x pdf.dest.y } def
/pdf.dest2device
  {
    /pdf.dest.y exch def
    /pdf.dest.x exch def
    matrix currentmatrix
    matrix defaultmatrix
    matrix invertmatrix
    matrix concatmatrix
    cvx exec
    /pdf.dev.y exch def
    /pdf.dev.x exch def
    /pdf.tmpd exch def
    /pdf.tmpc exch def
    /pdf.tmpb exch def
    /pdf.tmpa exch def
    pdf.dest.x pdf.tmpa mul
      pdf.dest.y pdf.tmpc mul add
      pdf.dev.x add
    pdf.dest.x pdf.tmpb mul
     pdf.dest.y pdf.tmpd mul add
     pdf.dev.y add
  }
    def
/pdf.bordertracking false def
/pdf.bordertracking.begin
  {
    SDict /pdf.bordertracking true put
    SDict /pdf.leftboundary undef
    SDict /pdf.rightboundary undef
    /a where
      {
        /a
          {
            currentpoint pop
            SDict /pdf.rightboundary known dup
              {
                SDict /pdf.rightboundary get 2 index lt
                  { not }
                if
              }
            if
              { pop }
              { SDict exch /pdf.rightboundary exch put }
            ifelse
            moveto
            currentpoint pop
            SDict /pdf.leftboundary known dup
              {
                SDict /pdf.leftboundary get 2 index gt
                  { not }
                if
              }
            if
              { pop }
              { SDict exch /pdf.leftboundary exch put }
            ifelse
          }
        put
      }
    if
  }
    def
/pdf.bordertracking.end
  {
    /a where { /a { moveto } put } if
    /x where { /x { 0 exch rmoveto } put } if
    SDict /pdf.leftboundary known
      { pdf.outerbox 0 pdf.leftboundary put }
    if
    SDict /pdf.rightboundary known
      { pdf.outerbox 2 pdf.rightboundary put }
    if
    SDict /pdf.bordertracking false put
  }
    def
  /pdf.bordertracking.endpage
{
  pdf.bordertracking
    {
      pdf.bordertracking.end
      true setglobal
      pdf.globaldict
        /pdf.brokenlink.rect [ pdf.outerbox aload pop ] put
      pdf.globaldict
        /pdf.brokenlink.skip pdf.baselineskip put
      pdf.globaldict
        /pdf.brokenlink.dict
          pdf.link.dict pdf.cvs put
      false setglobal
      mark pdf.link.dict cvx exec /Rect
        [
          pdf.llx
          pdf.lly
          pdf.outerbox 2 get pdf.linkmargin add
          currentpoint exch pop
          pdf.outerbox pdf.rect.ht sub pdf.linkmargin sub
        ]
      /ANN pdf.pdfmark
    }
  if
}
  def
/pdf.bordertracking.continue
  {
    /pdf.link.dict pdf.globaldict
      /pdf.brokenlink.dict get def
    /pdf.outerbox pdf.globaldict
      /pdf.brokenlink.rect get def
    /pdf.baselineskip pdf.globaldict
      /pdf.brokenlink.skip get def
    pdf.globaldict dup dup
    /pdf.brokenlink.dict undef
    /pdf.brokenlink.skip undef
    /pdf.brokenlink.rect undef
    currentpoint
    /pdf.originy exch def
    /pdf.originx exch def
    /a where
      {
        /a
          {
            moveto
            SDict
            begin
            currentpoint pdf.originy ne exch
              pdf.originx ne or
              {
                pdf.save.linkll
                /pdf.lly
                  pdf.lly pdf.outerbox 1 get sub def
                pdf.bordertracking.begin
              }
            if
            end
          }
        put
      }
    if
    /x where
      {
        /x
          {
            0 exch rmoveto
            SDict
            begin
            currentpoint
            pdf.originy ne exch pdf.originx ne or
              {
                pdf.save.linkll
                /pdf.lly
                  pdf.lly pdf.outerbox 1 get sub def
                pdf.bordertracking.begin
              }
            if
            end
          }
        put
      }
    if
  }
    def
/pdf.breaklink
  {
    pop
    counttomark 2 mod 0 eq
      {
        counttomark /pdf.count exch def
          {
           pdf.count 0 eq { exit } if
           counttomark 2 roll
           1 index /Rect eq
             {
               dup 4 array copy
               dup dup
                 1 get
                 pdf.outerbox pdf.rect.ht
                 pdf.linkmargin 2 mul add sub
                 3 exch put
               dup
                 pdf.outerbox 2 get
                 pdf.linkmargin add
                 2 exch put
               dup dup
                 3 get
                 pdf.outerbox pdf.rect.ht
                 pdf.linkmargin 2 mul add add
                 1 exch put
               /pdf.currentrect exch  def
               pdf.breaklink.write
                 {
                   pdf.currentrect
                   dup
                     pdf.outerbox 0 get
                     pdf.linkmargin sub
                     0 exch put
                   dup
                     pdf.outerbox 2 get
                     pdf.linkmargin add
                     2 exch put
                   dup dup
                     1 get
                     pdf.baselineskip add
                     1 exch put
                   dup dup
                     3 get
                     pdf.baselineskip add
                     3 exch put
                   /pdf.currentrect exch def
                   pdf.breaklink.write
                  }
                1 index 3 get
                pdf.linkmargin 2 mul add
                pdf.outerbox pdf.rect.ht add
                2 index 1 get sub
                pdf.baselineskip div round cvi 1 sub
                exch
              repeat
              pdf.currentrect
              dup
                pdf.outerbox 0 get
                pdf.linkmargin sub
                0 exch put
              dup dup
                1 get
                pdf.baselineskip add
                1 exch put
              dup dup
                3 get
                pdf.baselineskip add
                3 exch put
              dup 2 index 2 get  2 exch put
              /pdf.currentrect exch def
              pdf.breaklink.write
              SDict /pdf.pdfmark.good false put
              exit
            }
            { pdf.count 2 sub /pdf.count exch def }
          ifelse
        }
      loop
    }
  if
  /ANN
}
  def
/pdf.breaklink.write
  {
    counttomark 1 sub
    index /_objdef eq
      {
        counttomark -2 roll
        dup wcheck
          {
            readonly
            counttomark 2 roll
          }
          { pop pop }
        ifelse
      }
    if
    counttomark 1 add copy
    pop pdf.currentrect
    /ANN pdfmark
  }
    def
/pdf.pdfmark
  {
    SDict /pdf.pdfmark.good true put
    dup /ANN eq
      {
        pdf.pdfmark.store
        pdf.pdfmark.dict
          begin
            Subtype /Link eq
            currentdict /Rect known and
            SDict /pdf.outerbox known and
            SDict /pdf.baselineskip known and
              {
                Rect 3 get
                pdf.linkmargin 2 mul add
                pdf.outerbox pdf.rect.ht add
                Rect 1 get sub
                pdf.baselineskip div round cvi 0 gt
                  { pdf.breaklink }
                if
              }
            if
          end
        SDict /pdf.outerbox undef
        SDict /pdf.baselineskip undef
        currentdict /pdf.pdfmark.dict undef
      }
    if
    pdf.pdfmark.good
      { pdfmark }
      { cleartomark }
    ifelse
  }
    def
/pdf.pdfmark.store
  {
    /pdf.pdfmark.dict 65534 dict def
    counttomark 1 add copy
    pop
      {
        dup mark eq
          {
            pop
            exit
          }
          {
            pdf.pdfmark.dict
            begin def end
          }
        ifelse
      }
    loop
}
  def
%% 
%%
%% End of file `l3backend-dvips.pro'.
