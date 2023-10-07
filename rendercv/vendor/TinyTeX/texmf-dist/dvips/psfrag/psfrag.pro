%%
%% This is file `psfrag.pro',
%% generated with the docstrip utility.
%%
%% The original source files were:
%%
%% psfrag.dtx  (with options: `filepro')
%% 
%% Copyright (c) 1996 Craig Barratt, Michael C. Grant, and David Carlisle.
%% All rights reserved.
%% 
%% This file is part of the PSfrag package.
%% 
userdict begin
/PSfragLib 90 dict def
/PSfragDict 6 dict def
/PSfrag { PSfragLib begin load exec end } bind def
end
PSfragLib begin
/RO /readonly      load def
/CP /currentpoint  load def
/CM /currentmatrix load def
/B { bind RO def } bind def
/X { exch def } B
/MD { { X } forall } B
/OE { end exec PSfragLib begin } B
/S false def
/tstr 8 string def
/islev2 { languagelevel } stopped { false } { 2 ge } ifelse def
[ /sM /tM /srcM /dstM /dM /idM /srcFM /dstFM ] { matrix def } forall
sM currentmatrix RO pop
dM defaultmatrix RO idM invertmatrix RO pop
srcFM identmatrix pop
/Hide { gsave { CP } stopped not newpath clip { moveto } if } B
/Unhide { { CP } stopped not grestore { moveto } if } B
/setrepl islev2 {{ /glob currentglobal def true setglobal array astore
                   globaldict exch /PSfrags exch put glob setglobal }}
                {{ array astore /PSfrags X }} ifelse B
/getrepl islev2 {{ globaldict /PSfrags get aload length }}
                {{ PSfrags aload length }} ifelse B
/convert {
   /src X src length string
   /c 0 def src length {
      dup c src c get dup 32 lt { pop 32 } if put /c c 1 add def
   } repeat
} B
/Begin {
    /saver save def
    srcFM exch 3 exch put
    0 ne /debugMode X 0 setrepl
    dup /S exch dict def { S 3 1 roll exch convert exch put } repeat
    srcM CM dup invertmatrix pop
    mark { currentdict { end } stopped { pop exit } if } loop
    PSfragDict counttomark { begin } repeat pop
} B
/End {
    mark { currentdict end dup PSfragDict eq { pop exit } if } loop
    counttomark { begin } repeat pop
    getrepl saver restore
    7 idiv dup /S exch dict def {
        6 array astore /mtrx X tstr cvs /K X
        S K [ S K known { S K get aload pop } if mtrx ] put
    } repeat
} B
/Place {
    tstr cvs /K X
    S K known {
        bind /proc X tM CM pop
        CP /cY X /cX X
        0 0 transform idtransform neg /aY X neg /aX X
        S K get dup length /maxiter X
        /iter 1 def {
            iter maxiter ne { /saver save def } if
            tM setmatrix aX aY translate
            [ exch aload pop idtransform ] concat
            cX neg cY neg translate cX cY moveto
            /proc load OE
            iter maxiter ne { saver restore /iter iter 1 add def } if
        } forall
        /noXY { CP /cY X /cX X } stopped def
        tM setmatrix noXY { newpath } { cX cY moveto } ifelse
    } {
        Hide OE Unhide
    } ifelse
} B
/normalize {
    2 index dup mul 2 index dup mul add sqrt div
    dup 4 -1 roll exch mul 3 1 roll mul
} B
/replace {
    aload pop MD
    CP /bY X /lX X gsave sM setmatrix
    str stringwidth abs exch abs add dup 0 eq
        { pop } { 360 exch div dup scale } ifelse
    lX neg bY neg translate newpath lX bY moveto
    str { /ch X ( ) dup 0 ch put false charpath ch Kproc } forall
    flattenpath pathbbox [ /uY /uX /lY /lX ] MD
    CP grestore moveto
    currentfont /FontMatrix get dstFM copy dup
    0 get 0 lt { uX lX /uX X /lX X } if
    3 get 0 lt { uY lY /uY X /lY X } if
    /cX uX lX add 0.5 mul def
    /cY uY lY add 0.5 mul def
    debugMode { gsave 0 setgray 1 setlinewidth
        lX lY moveto lX uY lineto uX uY lineto uX lY lineto closepath
        lX bY moveto uX bY lineto lX cY moveto uX cY lineto
        cX lY moveto cX uY lineto stroke
    grestore } if
    dstFM dup invertmatrix dstM CM srcM
    2 { dstM concatmatrix } repeat pop
    getrepl /temp X
        S str convert get {
            aload pop [ /rot /scl /loc /K ] MD
            /aX cX def /aY cY def
            loc {
                dup 66  eq { /aY bY def } { % B
                dup 98  eq { /aY lY def } { % b
                dup 108 eq { /aX lX def } { % l
                dup 114 eq { /aX uX def } { % r
                dup 116 eq { /aY uY def }   % t
                if } ifelse } ifelse } ifelse } ifelse pop
            } forall
            K srcFM rot tM rotate dstM
            2 { tM concatmatrix } repeat aload pop pop pop
            2 { scl normalize 4 2 roll } repeat
            aX aY transform
            /temp temp 7 add def
        } forall
    temp setrepl
} B
/Rif {
    S 3 index convert known { pop replace } { exch pop OE } ifelse
} B
/XA { bind [ /Kproc /str } B /XC { ] 2 array astore def } B
/xs   { pop } XA XC
/xks  { /kern load OE } XA /kern XC
/xas  { pop ax ay rmoveto } XA /ay /ax XC
/xws  { c eq { cx cy rmoveto } if } XA /c /cy /cx XC
/xaws { ax ay rmoveto c eq { cx cy rmoveto } if }
    XA /ay /ax /c /cy /cx XC
/raws { xaws { awidthshow } Rif } B
/rws  { xws { widthshow } Rif } B
/rks  { xks { kshow } Rif } B
/ras  { xas { ashow } Rif } B
/rs   { xs { show } Rif } B
/rrs { getrepl dup 2 add -1 roll //restore exec setrepl } B
PSfragDict begin
islev2 not { /restore { /rrs PSfrag } B } if
/show       { /rs   PSfrag } B
/kshow      { /rks  PSfrag } B
/ashow      { /ras  PSfrag } B
/widthshow  { /rws  PSfrag } B
/awidthshow { /raws PSfrag } B
end PSfragDict RO pop
end
