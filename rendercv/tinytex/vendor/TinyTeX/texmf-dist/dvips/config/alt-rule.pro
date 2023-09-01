%!
% Patch by TVZ
% Makes dvips files draw rules with stroke rather than fill.
% Makes narrow rules more predictable at low resolutions
% after distilling to PDF.
% May have unknown consequences for very thick rules.
% Tested only with dvips 5.85(k).
TeXDict begin
/QV {
  gsave newpath /ruleY X /ruleX X
  Rx Ry gt
  { ruleX ruleY Ry 2 div sub moveto Rx 0 rlineto Ry }
  { ruleX Rx 2 div add ruleY moveto 0 Ry neg rlineto Rx }
  ifelse
  setlinewidth 0 setlinecap stroke grestore
} bind def
end
