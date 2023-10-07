%!
/HPSdict 20 dict dup begin/braindeaddistill 50 def/rfch{dup length 1 sub
1 exch getinterval}bind def/splituri{dup(#)search{exch pop}{()exch}
ifelse dup(file:)anchorsearch{pop exch pop 3 -1 roll pop false}{pop 3 -1
roll exch pop true}ifelse}bind def/lookuptarget{exch rfch dup
/TargetAnchors where{pop TargetAnchors dup 3 -1 roll known{exch get true
}{pop(target unknown:)print == false}ifelse}{pop pop
(target dictionary unknown\012)print false}ifelse}bind def/savecount 0
def/stackstopped{count counttomark sub/savecount exch store stopped
count savecount sub 1 sub dup 0 gt{{exch pop}repeat}{pop}ifelse}bind def
/tempstring 128 string def/targetvalidate{1 index dup length 127 gt exch
tempstring cvs dup(/)search{pop pop pop exch pop true exch}{pop}ifelse
token{pop length 0 ne}{true}ifelse or not}bind def/targetdump-hook where
{pop}{/targetdump-hook{dup mark exch gsave initmat setmatrix{{mark/Dest
4 2 roll targetvalidate{aload pop exch pop/Page 3 1 roll/View exch[exch
/FitH exch]/DEST pdfmark}{cleartomark}ifelse}forall}stackstopped pop
grestore}bind def}ifelse/baseurl{mark exch 1 dict dup 3 -1 roll/Base
exch put/URI exch/DOCVIEW{pdfmark}stackstopped pop}bind def
/externalhack systemdict/PDF known def/oldstyle true def/initmat matrix
currentmatrix def/actiondict 2 dict dup/Subtype/URI put def
/weblinkhandler{dup 3 1 roll mark 4 1 roll/Title 4 1 roll splituri 3 -1
roll dup length 0 gt{cvn/Dest exch 4 2 roll}{pop}ifelse{externalhack{
/HTTPFile exch}{actiondict dup 3 -1 roll/URI exch put/Action exch}
ifelse}{externalhack{/HTTPFile exch}{/File exch/Action/GoToR}ifelse}
ifelse counttomark 2 sub -1 roll aload pop/Rect 4 1 roll/Border 3 1 roll
/Color exch oldstyle{/LNK}{/Subtype/Link/ANN}ifelse gsave initmat
setmatrix{pdfmark}stackstopped grestore}bind def/externalhandler where{
pop}{/externalhandler{2 copy{weblinkhandler}exec{/externalhack
externalhack not store 2 copy{weblinkhandler}exec{/externalhack
externalhack not store/oldstyle false store 2 copy{weblinkhandler}exec{
(WARNING: external refs disabled\012)print/externalhandler{pop pop}bind
store externalhandler}{pop pop}ifelse}{pop pop/externalhack externalhack
not store}ifelse}{pop pop/externalhandler{weblinkhandler pop}bind store}
ifelse}bind def}ifelse/pdfmnew{dup type/stringtype eq{externalhandler}{
exch dup rfch exch 3 -1 roll lookuptarget{mark 4 1 roll/Title 4 1 roll
aload pop exch pop/Page 3 1 roll/View exch[exch/FitH exch]5 -1 roll
aload pop/Rect 4 1 roll/Border 3 1 roll/Color exch/LNK gsave initmat
setmatrix pdfmark grestore}{pop pop}ifelse}ifelse}bind def/pdfmold{dup
type/stringtype eq{externalhandler}{exch dup rfch exch 3 -1 roll
lookuptarget{mark 4 1 roll/Title 4 1 roll aload pop exch pop/Page 3 1
roll/View exch[exch/FitH exch]5 -1 roll aload pop pop 0 3 getinterval
/Rect 3 1 roll/Border exch/LNK gsave initmat setmatrix pdfmark grestore}
{pop pop}ifelse}ifelse}bind def/pdfm where{pop}{/pdfm
/currentdistillerparams where{pop currentdistillerparams dup
/CoreDistVersion known{/CoreDistVersion get}{0}ifelse dup
braindeaddistill le{(WARNING: switching to old pdfm because version =)
print ==/pdfmold}{pop/pdfmnew}ifelse load}{/pdfmark where{pop{dup type
/stringtype eq{externalhandler}{2 copy mark 3 1 roll{pdfmnew}
stackstopped{2 copy mark 3 1 roll{pdfmold}stackstopped{
(WARNING: pdfm disabled\012)print/pdfm{pop pop}store}{
(WARNING: new pdfm failed, switching to old pdfm\012)print/pdfm/pdfmold
load store}ifelse}{/pdfm/pdfmnew load store}ifelse pop pop}ifelse}}{{
pop pop}}ifelse}ifelse bind def}ifelse end def
