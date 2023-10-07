%!PS-Adobe-3.0 Resource-procset
%%Title: xy389dict.pro
%%Version: 3.8.9
%%Creator: Xy-ps backend to Xy-pic
%%DocumentSuppliedProcSets: XYdict
%%For: nulluse of Xy-pic
%%BeginResource: procset XYdict
/XYdict where not{250 dict /XYdict exch def
 /xy{mark exch XYdict begin countdictstack /xylevel exch def
 xyopen xycolor mark xypatt xypattern stopped xyclose end
 cleartomark}def /xyg{gsave xy}def
 /xyf{currentfont exch xy grestore setfont}def
 /xycc{{xychgcol}xy}def /xyc{XYdict begin xycolstore end}def
 /xyx{/xyYpos exch def /xyXpos exch def}def
 /xyp{currentpoint xyx}def
 /xyd{setupDirection XYdirection 2 mul}def
 /xyct{currentpoint xyt 2 copy 6 2 roll}def
 /xyt{xyXpos xyYpos 2 copy translate}def /xyr{neg rotate xynt}def
 /xyrs{neg rotate 3 -1 roll sub neg 3 1 roll sub exch moveto xynt}def
 /xynt{neg exch neg exch translate}def /xys{scale xynt}def
 /xyss{scale 3 -1 roll sub neg 3 1 roll sub exch moveto xynt}def
 /xyi{0 0 transform grestore gsave itransform}def
 }if

/XYdict where pop begin XYdict begin
 /xyopen{currentdict /XYddict known{XYddict null eq{}
 {XYddict begin xyopen}ifelse}if}def
 /xyclose{countdictstack -1 xylevel 1 add{pop end}for}def
 /xychgcol{/xycolor exch def}def /xysetcol{xypush xychgcol}def

 /xypush{16 dict /XYddict exch def XYddict begin}def
 /undef where
 {pop /xypop{countdictstack xylevel eq{}{end}ifelse
 currentdict /XYddict undef}def}
 {/xypop{countdictstack xylevel eq{}{end}ifelse
 /XYddict null def}def}ifelse
 /pu /xypush load def /pp /xypop load def
 /xypspt{72 72.27 div dup scale}bind def /pscorrect{.85 mul}bind def
 /gstartxy{gsave xypspt xywidth xycap xyjoin xymiter newpath 0 0 moveto}def
 /xypath{gstartxy rmoveto counttomark 2 idiv -1 1{pop lineto}for}def
 /xystroke{stroke grestore}bind def
 /xyfill{closepath fill grestore}bind def
 /xystfil{closepath gsave fill grestore 0 setgray
 0 setlinewidth xystroke}bind def
 /xyeofill{closepath eofill grestore}bind def

 /xypolyline{xypath xystroke}def /xypolyfill{xypath xyfill}def
 /xydotsep{/@ currentlinewidth 2 mul def}def
 /xypolydot{xypath xydotsep [xydt @] 0 setdash xystroke}def
 /xypolydash{xypath xydotsep [@ @] 0 setdash xystroke}def
 /xypolyeofill{xypath xyeofill}def /pe /xypolyeofill load def
 /pl /xypolyline load def /pf /xypolyfill load def
 /pt /xypolydot load def /pd /xypolydash load def 
 /arc4pop{arcto 4{pop}repeat}bind def
 /xyoval{gstartxy oval closepath xystroke}def
 /xycircle{gstartxy circle xystroke}def
 /circle{dup 0 moveto 0 0 3 -1 roll 0 360 arc}def
 /oval{newpath 2 copy exch 5 index add 2 div exch 3 copy 10 3 roll
 moveto 1 index dup 5 1 roll 3 index 7 index arc4pop
 dup dup 4 1 roll 4 index exch 6 index arc4pop
 1 index dup 8 1 roll 4 index 4 index arc4pop
 arc4pop closepath}def
 /xyellipse{gstartxy counttomark 1 gt{squarify pop pop 1}if
 circle xystroke}def
 /ov /xyoval load def /ox /xyellipse load def 
 /dotit{dup currentlinewidth 6 mul div round div
 /@ exch def [xydt @] 0 setdash}def
 /elldash{dup 4 -1 roll 10 exch div dashit}def
 /ovdash{dup 10 dashit}def
 /dashit{div round 2 mul div /@ exch def [@ @] 0 setdash}def
 /dotcirc{gstartxy cirlen dotit circle xystroke}def
 /dashcirc{gstartxy cirlen dashit circle xystroke}def
 /dotoval{gstartxy 5 copy ovlen dotit oval xystroke}def
 /dashoval{gstartxy 5 copy ovlen ovdash oval xystroke}def
 /cirlen{dup 6.283185 mul}bind def
 /ovlen{3 -1 roll sub 3 1 roll sub add exch 1.716815 mul sub}def
 /dotellipse{gstartxy counttomark 1 gt{squarify pop pop 1}if
 cirlen dotit circle closepath xystroke}def
 /dashellipse{gstartxy counttomark 1 gt{squarify add 2 div 1}
 {1 exch 1 exch}ifelse cirlen elldash circle xystroke}def
 /ot /dotellipse load def /od /dashellipse load def
 /vt /dotoval load def /vd /dashoval load def 
 /filloval{gstartxy oval xyfill}def
 /stfiloval{gstartxy oval xystfil}def
 /fillcircle{gstartxy circle xyfill}def
 /stfilcircle{gstartxy circle xystfil}def
 /fillellipse{gstartxy squarify pop pop 1 circle xyfill}def
 /stfilellipse{gstartxy squarify pop pop 1 circle xystfil}def
 /squarify{4 copy sub 2 div 3 1 roll sub 2 div translate
 add 2 div 3 1 roll add 2 div 2 copy scale
 2 copy add 2 div currentlinewidth exch div setlinewidth
 newpath}def
 /fe /fillellipse load def /sfe /stfilellipse load def
 /fo /filloval load def /sfo /stfiloval load def
 /fc /fillcircle load def /sfc /stfilcircle load def 
 /xywidth{.4 pscorrect setlinewidth}bind def
 /xydash{[] 0 setdash}bind def /xycap{1 setlinecap}bind def
 /xyjoin{1 setlinejoin}bind def /xymiter{10 setmiterlimit}bind def

 /cc{dup exec xychgcol}def
 /lw{dup setlinewidth /@l exch def
 /xywidth{@l setlinewidth}bind def}def
 /lc{dup setlinecap /@c exch def
 /xycap{@c setlinecap}bind def}def
 /lj{dup setlinejoin /@j exch def
 /xyjoin{@j setlinejoin}bind def}def
 /ml{dup setmitrelimit /@m exch def
 /xymiter{@m setmitrelimit}bind def}def

 /setupDirection{dup -2048 lt{3072 add neg 1024 exch}
 {dup 0 lt{1024 add neg -1024}{dup 2048 lt{1024 sub -1024 exch}
 {3072 sub 1024}ifelse}ifelse}ifelse atan
 dup 180 gt{360 sub}if dup /XYdirection exch def rotate}def
 
 userdict begin
 /gray{setgray}bind def /gray@{setgray}bind def
 /rgb{setrgbcolor}bind def /rgb@{setrgbcolor}bind def
 /hsb{sethsbcolor}bind def /hsb@{sethsbcolor}bind def
 /setcmykcolor where{pop}{/setcmykcolor{dup 3 1 roll dup 5 1 roll
 exch sub 1 add 5 1 roll exch sub 1 add 4 1 roll
 exch sub 1 add 3 1 roll setrgbcolor}bind def}ifelse
 /cmyk{setcmykcolor}bind def /cmyk@{setcmykcolor}bind def
 /sethalftone where{/sethalftone load /tone exch def}if
 /xycolarray 3 array def /xycolstore{currentrgbcolor 2 -1 0
 {exch xycolarray 3 1 roll put}for}def xycolstore
 /xycolor{0 1 2{xycolarray exch get}for setrgbcolor}def
 /xypatt{}def /xypattern{cleartomark}bind def
 end
end end
/XYdict where pop begin XYdict begin
/:patt
{XYddict begin
14 dict begin
/BGnd exch def
/FGnd exch def
/PaintData exch def
/PatternType 1 def
/PaintType 1 def
/BBox[0 0 1 1]def
/TilingType 1 def
/XStep 1 def
/YStep 1 def
/PatternMtx[24 0 0 24 0 0]def
/PaintProc BGnd null ne
 {{begin BGnd aload pop setrgbcolor 0 0 1 1 rF
 FGnd aload pop setrgbcolor
 24 24 true PatternMtx PaintData imagemask end}}
 {{begin FGnd aload pop setrgbcolor
 24 24 true PatternMtx PaintData imagemask end}}
 ifelse def
 currentdict PatternMtx end
 gsave patangle xyland{180 add}if
 rotate macfreq patfreq div dup neg exch scale matrix currentmatrix
 grestore gsave setmatrix /DeviceRGB setcolorspace makepattern grestore
 end}def
/rF{gsave
 newpath 4 2 roll moveto 1 index 0 rlineto 0 exch rlineto neg 0 rlineto
 fill grestore}bind def 
 /setpatscreen{/pattstring exch store patfreq
 patangle xyport not{90 add}if
 {1 add 4 mul cvi pattstring exch get exch 1 add 4 mul cvi 7 sub
 bitshift 1 and}setscreen}bind def
 /setcolpattern{setpatscreen 64 div 1 exch sub currentrgbcolor
 1 1 3{pop 1 exch sub 3 index mul 1 exch sub 3 1 roll}for
 setrgbcolor pop}def
 /setgraypattern{setpatscreen 64 div setgray}def
 /macfreq 9.375 def /patangle 0 def /patfreq 12.5 def
/checkland{ /normland where{pop normland not}{false}ifelse
 /xyland exch def
 /por where{pop por}{/isls where{pop isls not /xyland true def}
 {/land where{pop land not}{true}
 ifelse}ifelse}ifelse /xyport exch def}def 
 /setpatfreq{/patfreq exch def}def
 /setpatangle{/patangle exch def}def
 /setbackcolor{/backcolor exch def}def
 /setforecolor{/forecolor exch def}def
 [1 1 1] setbackcolor xycolarray setforecolor
 /bg /setbackcolor load def /fg /setforecolor load def
 /pa /setpatangle load def /pq /setpatfreq load def 
 /xypattern{checkland counttomark dup 0 eq{pop}
 {dup 1 eq{pop setpatscreen}
 {dup 2 eq{pop setcolpattern}
 {dup 3 eq{pop
 /setcolorspace where {
 /.setcolorspace where{pop pop pop setcolpattern}
 {/.buildpattern where {pop
 forecolor backcolor :patt setpattern
 }{pop pop setcolpattern}ifelse}ifelse}
 {pop setcolpattern}ifelse}
 {5 eq{/setcolorspace where{
 /.setcolorspace where{pop pop pop pop pop setcolpattern}
 {/.buildpattern where {pop
 :patt setpattern
 }{pop pop pop pop setcolpattern}ifelse}ifelse}
 {pop pop pop setcolpattern}ifelse
 }{}ifelse}ifelse}ifelse}ifelse}ifelse cleartomark }def
 /xysetpattern{/xypatt exch def}def
 /sp /xysetpattern load def 
end end
/XYdict where pop begin XYdict begin
 /xysize 10 def /T true def /F false def
 /dimendiv{65536 div}bind def
 /xysegl 327680  dimendiv def
 /xyopp{1 -1 scale}bind def
 /xynormwidth{26213  dimendiv pscorrect}bind def
 /xywidth{xynormwidth setlinewidth}bind def

 /xyfont{4096 add 64 div round 64 mul 4096 sub}def /xydt 0.01 def
 /xysdfont{4096 add 32 div round 32 mul 4096 sub}def
 /xydots{xywidth 1 setlinecap [xydt 2] 0 setdash}bind def
 /f /xyfont load def /fs /xysdfont load def
 /xyCheckDir{dup 8 div 3 mul 3 -1 roll sub neg exch div 360 mul
 dup dup XYdirection sub 180 div round 180 mul XYdirection add
 dup 3 -1 roll sub abs 10 gt not{exch}if pop}def

 /xyrulth{26213  dimendiv pscorrect setlinewidth
 0 setlinecap}bind def

 /gsavexy{gsave xypspt XYdirection rotate xywidth newpath 0 0 moveto}def
 /gchksavexy{gsave xypspt setupDirection xywidth newpath 0 0 moveto}def

 /xyswap{XYdirection 180 add /XYdirection exch def}def
 /xyline{gstartxy setupDirection rlineto xystroke}def

 /dash{exch gchksavexy xysegl XYdirection dup
 -90 lt{pop neg}{90 gt{neg}if}ifelse exch{neg}if
 0 rlineto xystroke}def
 /stopper{gstartxy setupDirection 0 xysegl 2 div rmoveto
 0 xysegl neg rlineto xystroke }def
 /d /dash load def /st /stopper load def
 /solid{gstartxy xydash neg exch neg exch rlineto xystroke}def
 /dashed{gstartxy 2 copy dup mul exch dup mul add sqrt dup
 xysegl add xysegl 2 mul div round 2 mul 1 sub div [ exch dup ] 0 setdash
 neg exch neg exch rlineto xystroke}def
 /l /solid load def /dd /dashed load def
 /dot{gstartxy 2 setlinecap [xydt 2] 0 setdash
 1 0 rlineto xystroke}def
 /dotted{gstartxy 2 copy dup mul exch dup mul add sqrt dup
 2 div round 1 add div 2 setlinecap [xydt 3 -1 roll] 0 setdash
 neg exch neg exch rlineto 0 0 rlineto xystroke}def
 /p /dot load def /dt /dotted load def
 /cubic{gstartxy docubic} def
 /docubic{chkvalid
 {chkcubedge 8 -2 roll moveto curveto xystroke pop}
 {cleartomark grestore}ifelse}def
 /chkcubedge{2 copy 1.0 eq{0.0 eq{pop pop}{cubicedge}ifelse}
 {pop cubicedge}ifelse}def
 /bz /cubic load def
 /dotcubic{gstartxy 1 setlinecap [xydt 2] 0 setdash docubic}def
 /dashcubic{gstartxy [5 5] 0 setdash docubic}def
 /bt /dotcubic load def /bd /dashcubic load def
 /squine{gstartxy dosquine}def
 /dosquine{chkvalid
 {chksquedge 2 copy moveto xysq2cub curveto xystroke pop}
 {cleartomark grestore}ifelse}def
 /q /squine load def
 /chkvalid{2 copy lt{dup 1 gt{false}{true}ifelse}{false}ifelse}def

 /chksquedge{2 copy 1.0 eq{0.0 eq{pop pop}{squineedge}ifelse}
 {pop squineedge}ifelse}def
 /xysq2cub{xysq2cubit 6 1 roll xysq2cubit 6 1 roll 3 index 3 index
 xysq2cubit 6 1 roll xysq2cubit 6 1 roll pop pop}def
 /xysq2cubit{2 index 2 mul add 3 div}def

 /dotsquine{gstartxy 1 setlinecap [xydt 2] 0 setdash dosquine}def
 /dashsquine{gstartxy [5 5] 0 setdash dosquine}def
 /qt /dotsquine load def /qd /dashsquine load def
/xy4mul{8 copy
 5 -1 roll mul 5 1 roll 6 -1 roll mul 6 1 roll
 3 -1 roll mul exch 4 -1 roll mul 3 1 roll
 add 3 1 roll add exch 10 2 roll
 7 -1 roll mul 7 1 roll 4 -1 roll mul 5 1 roll
 4 -1 roll mul 4 1 roll mul add 3 1 roll add
 exch 3 -1 roll }def

 /xy44mul{4 copy 16 4 roll exch 3 1 roll 4 copy 12 4 roll
 xy4mul 12 4 roll xy4mul 12 -4 roll 4 copy 16 4 roll
 8 4 roll xy4mul 12 4 roll xy4mul}def

 /cubicedge{10 2 roll exch 8 1 roll 3 -1 roll dup dup 9 2 roll
 5 -1 roll dup dup 9 1 roll 8 3 roll
 4 1 roll dup dup 5 3 roll dup dup 5 1 roll 3 -1 roll
 18 -2 roll 2 copy 1 sub neg 4 1 roll 1 sub neg exch 4 1 roll
 xy444mul
 pop pop pop 13 1 roll pop pop pop 9 1 roll 10 1 roll
 pop 8 1 roll 7 1 roll 8 1 roll pop 5 1 roll 3 1 roll}def

 /xy444mul{4 copy 24 4 roll 12 -4 roll 16 4 roll 4 copy 16 4 roll
 xy44mul 20 8 roll xy44mul
 12 -4 roll 4 -1 roll 7 1 roll exch 4 1 roll exch 6 -1 roll exch
 4 2 roll 16 8 roll 8 4 roll
 4 -1 roll 7 1 roll exch 4 1 roll exch 6 -1 roll exch 4 2 roll
 8 4 roll 16 4 roll 8 4 roll 20 -4 roll exch 3 1 roll
 4 copy 20 4 roll 4 copy 16 4 roll 4 copy 12 4 roll
 xy4mul 28 4 roll xy4mul 20 4 roll xy4mul 12 4 roll xy4mul}def

 /squineedge{8 2 roll
 exch 5 1 roll 3 -1 roll dup 6 2 roll 1 index exch
 10 -2 roll 2 copy 1 sub neg 4 1 roll 1 sub neg exch 4 1 roll
 xy44mul 4 1 roll pop 5 1 roll 6 1 roll 3 -1 roll pop}def

 /xyshort{2 copy abs exch abs add xysegl .5 mul lt
 {pop pop grestore}{rlineto xystroke}ifelse}def

 /tipwidth{xywidth xynormwidth dup currentlinewidth exch div
 sqrt dup dup scale mul setlinewidth 1 setlinecap}def

 /halftip{tipwidth xysize 10 div 0 0 moveto
 -.25 0 3 -1 roll -2.5 mul 0 xysize 2 div neg
 dup .62 mul 2 div neg curveto}bind def

/atip{gchksavexy halftip xystroke}def
 /btip{gchksavexy xyopp halftip xystroke}def
 /tip{gchksavexy gsave halftip stroke grestore
 xyopp halftip xystroke}def
 /t /tip load def /a /atip load def /b /btip load def
/cmatip{gchksavexy halfcmtip xystroke}def
 /cmbtip{gchksavexy xyopp halfcmtip xystroke}def
 /cmtip{gchksavexy gsave halfcmtip stroke grestore
 xyopp halfcmtip xystroke}def
 /halfcmtip{tipwidth 0 0 moveto
 -.1333 0 .25 neg dup .125 3 -1 roll .25 curveto}bind def
 /ct /cmtip load def /ca /cmatip load def /cb /cmbtip load def
 /xyfscale{/xyfsize exch def}def /xyfsize{10}def
 /eu{-0.0551 0.0643 -0.0976 0.1386 -0.125 0.2188}def
 /cm{-0.105 0.0437 -0.1804 0.1380 -0.2 0.25}def
 /XY{-0.1753 0.0181 -0.3452 0.0708 -0.5 0.155}def
 /tipstart{3 -1 roll gchksavexy exch xyfscale tipwidth dup XYdict exch
 known{dup /xy eq{pop /XY}if}{pop /XY}ifelse XYdict exch get}def
 /tipend{halfxytip xystroke}def
 /halfxytip{1 1 6{pop xyfsize mul 6 1 roll}for 0 0 moveto curveto}def
 /A{tipstart D}def /B{tipstart C}def /C{xyopp D}def /D{exec tipend}def
 /AB{tipstart dup gsave exec halfxytip stroke grestore C}def

 /Tip{exch gchksavexy /xyfsize{10}def tipwidth gsave
 dup XYdict exch known{dup /xy eq{pop /XT}if}{pop /XT}ifelse
 XYdict exch get dup
 halfTip stroke grestore xyopp halfTip xystroke}def
 /XT{360 32 div neg}def /Xt{-1 .31 mul 1 atan}def
 /ET{360 64 div 5 mul neg}def /Et{-1 .31 mul 1 atan}def
 /halfTip{exec rotate XY halfxytip}def /halfTtip{halfTip}def
 /Ttip{exch gchksavexy /xyfsize{10}def tipwidth gsave
 dup XYdict exch known{dup /xy eq{pop /Xt}if}{pop /Xt}ifelse
 XYdict exch get dup
 halfTtip stroke grestore xyopp halfTtip xystroke}def
 /tt /Tip load def /tT /Ttip load def
/halfturn{xysegl 2 div dup dup neg exch rmoveto
 0 exch dup exch -180 -90 arc}bind def
 /aturn{gchksavexy halfturn xystroke}def
 /bturn{gchksavexy xyopp halfturn xystroke}def
 /ta /aturn load def /tb /bturn load def
 /xysqll 231705  dimendiv def
 /squigl{gchksavexy xysqll dup neg 0 rmoveto
 2 div dup dup neg dup 3 -1 roll
 2 sqrt mul dup 5 1 roll
 135 45 arcn dup 3 -1 roll -135 -45 arc
 xystroke}def
 /g /squigl load def
/fullhook{0 xysegl 2 div dup -90 90 arcn}bind def
 /halfhook{xysegl 2 div dup 0 exch 180 90 arcn}bind def

/ahook{gchksavexy fullhook xystroke}def
 /bhook{gchksavexy xyopp fullhook xystroke}def
 /hook{gchksavexy gsave halfhook stroke grestore
 xyopp halfhook xystroke}def
 /h /hook load def /ha /ahook load def /hb /bhook load def
 /xyqcirc{dup dup neg exch translate newpath
 dup neg 0 exch moveto 0 0 3 -1 roll -90 0 arc}bind def

 /circ{gstartxy
 3 copy pop 2 copy cos mul 3 1 roll sin mul
 rmoveto 0 0 5 2 roll arc xystroke}bind def
 /o /circ load def
 /circhar{gsave dup 3 gt{7 sub neg}if dup
 3 eq{pop dup 2 sqrt -2 div mul}{dup 1 eq{pop dup 2 sqrt 2 div mul}
 {0 eq{dup}{0}ifelse}ifelse}ifelse
 0 translate 3 1 roll circ grestore}bind def
 /c /circhar load def
end end
%%EndResource
