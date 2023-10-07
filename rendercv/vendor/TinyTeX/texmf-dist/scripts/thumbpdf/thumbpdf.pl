eval '(exit $?0)' && eval 'exec perl -S $0 ${1+"$@"}' && eval 'exec perl -S $0 $argv:q'
  if 0;
use strict;
$^W=1; # turn warning on
#
# thumbpdf.pl
#
# Copyright (C) 1999-2018 Heiko Oberdiek.
#
# This work may be distributed and/or modified under the
# conditions of the LaTeX Project Public License, either version 1.3
# of this license or (at your option) any later version.
# The latest version of this license is in
#   http://www.latex-project.org/lppl.txt
# and version 1.3 or later is part of all distributions of LaTeX
# version 2003/12/01 or later.
#
# This work has the LPPL maintenance status "maintained".
#
# This Current Maintainer of this work is Heiko Oberdiek.
#
# See file "readme.txt" for a list of files that belong to this project.
#
# This file "thumbpdf.pl" may be renamed to "thumbpdf"
# for installation purposes.
#
my $file        = "thumbpdf.pl";
my $program     = uc($&) if $file =~ /^\w+/;
my $prj         = 'thumbpdf';
my $version     = "3.17";
my $date        = "2018/09/07";
my $author      = "Heiko Oberdiek";
my $copyright   = "Copyright (c) 1999-2018 by $author.";
#
# Reqirements: Perl5, Ghostscript
# History:
#   1999/02/14 v1.0: First release.
#   1999/02/23 v1.1:
#    * Looking for the media box to calculate the resolution
#      for Ghostscript
#    * new option --resolution
#   1999/03/01 v1.2:
#    * optimization: indirect objects for length values removed.
#    * "first line" from epstopdf
#   1999/03/12 v1.3:
#    * Copyright: LPPL
#   1999/05/05 v1.4:
#    * Detecting of cygwin32 environment.
#    * Minor corrections of output of error messages.
#    * Sharing RGB objects.
#   1999/06/13 v1.5:
#    * gs detection extended.
#   1999/07/27 v1.6
#   1999/08/08 v1.7:
#    * \immediate before \pdfobj (pdfTeX 0.14a)
#   1999/09/09 v1.8
#   1999/09/06 v1.9:
#    * Check for direct /Length values (for jpg images)
#   2000/01/11 v1.10:
#    * Bug fix: /Length (direct) as last entry.
#    * Direct /Length in RGB objects supported.
#   2000/01/19 v1.11:
#    * "for (my $j=0;...;...)"  replaced by "my $j; for($j=0;...;...)",
#      because there exist perl versions that have problems with.
#   2000/02/11 v1.12:
#    * Option `clean' added.
#    * The name of thumbnail data file: jobname.tnd,
#      if thumbpdf is called: thumbpdf jobname[.pdf] [options]
#   2000/02/22 v2.0:
#    * pdfmark support for dvips/ps2pdf route added.
#    * <jobname>.tpt replaces thumbdta.tex (for pdfTeX)
#      <jobname>.tpm (for pdfmark)
#      <jobname>.top replaces thumbopt.tex
#    * Options `useps', `modes' added,
#      `makedef' renamed to `makedata'.
#   2000/02/28 v2.1:
#    * Environment variable `THUMBPDF' supported.
#   2000/03/07 v2.2:
#    * Support for Distiller 3 and 4, the streams are uncompressed.
#    * Call of gs is changed in order to show the currently processed
#      page number of the pdf file.
#    * Option --printgscmd creates the command line file `thumbpdf.gs'
#      for the Ghostscript call.
#   2000/03/22 v2.3:
#    * Bug fix: --useps now works.
#   2000/04/10 v2.4:
#    * Fix for ActiveState Perl 5.6.0: uc line changed, fork removed.
#      (Thanks to Andreas Buehmann <andreas.buehmann@gmx.de>.)
#    * Version test for thumbpdf.tex added for users that
#      mix versions, sigh.
#   2000/07/29 v2.5:
#    * `save' trick in call of ghostscript.
#    * Undocumented option --gspages added.
#   2000/09/27 v2.6
#   2000/10/27 v2.7:
#    * -dFIXEDMEDIA=0 added in gs call
#   2001/01/12 v2.8:
#    * Bug fix in dvips mode and active option `level2':
#      pack parameter corrected for little-endian machines.
#    * /Rotate in pdf pages:
#      ghostscript versions around 6.01 have added a hack
#      in /pdfshowpage_setpage, that ignores the /Rotate entry.
#      A patch is added to disable the hack.
#    * Ghostscript uses the MediaBox for calculating the
#      page size. For version 6.50 a patch is added to use
#      the /CropBox instead.
#   2001/03/29 v2.9:
#    * Option --password added.
#   2001/04/02 v2.10
#   2001/04/26 v2.11
#    * Option --antialias added (suggestion of Juergen Bausa).
#   2002/01/11 v3.0
#    * Syntax of option --antialias changed (see readme.txt).
#    * Support for VTeX's PS mode added.
#    * Greek mode added (see readme.txt).
#    * Signal handlers added for cleanup.
#   2002/05/26 v3.1
#    * SIG_HUP unkown in Windows.
#    * Bug fix: The signal function for __DIE__ "cleanup" aborts
#      before the error message of "die" is printed.
#      Replaced by "clean" that does not contain "exit 1".
#    * Small bug fix in mode detection and mode "vtex"
#      removed from list. "vtexpdfmark" was detected,
#      "vtex" did not work and perhaps it will be used
#      later for VTeX in PDF mode.
#   2002/05/26 v3.2
#    * Fix: "MacOS/X: darwin" is now not interpreted as
#      Windows.
#   2003/03/19 v3.3
#    * Fix for gs 8.00 in mode dvips:
#      THB_DistillerPatch also applied to ghostscript >= 8.00.
#   2003/06/06 v3.4
#    * Bug fix, two forgotten "pop"s added for Distiller case.
#   2004/10/24 v3.5
#    * Revert Cygwin detection: is unix (request by Jan Nieuwenhuizen).
#    * LPPL 1.3.
#   2004/11/19 v3.6
#    * Bug fix for dvips mode and gs < 8.00 (/stackunderflow in pop).
#   2004/11/19 v3.7:
#    * For easier debugging, the special thumbpdf objects of
#      thumbpdf.pdf are now valid PDF objects (dictionaries).
#    * Remove of extra '\n' before "endstream" that is added
#      by pdfTeX 1.20a.
#   2005/07/06 v3.8:
#    * Fix because of pdfTeX 1.30.
#   2007/11/07 v3.9:
#    * Deprecation warning of perl 5.8.8 fixed.
#   2008/04/16 v3.10
#   2010/07/07 v3.11
#    * \input is used with file name extension for "thumbpdf.tex".
#   2011/08/10 v3.13
#    * Use gswin64c in Windows with 64 bits.
#   2012/04/09 v3.14
#   2012/04/18 v3.15
#    * Option --version added.
#   2014/07/15 v3.16
#    * Patch for "thumbpdf.pl" by Norbert Preining because of
#      pdfTeX 1.40.15 (TeX Live 2014).
#   2018/09/07 v3.17
#    * { } quoted as \{ \} in regex for "new" stricter perl syntax.
#

### program identification
my $title = "$program $version, $date - $copyright\n";

### error strings
my $Error = "!!! Error:"; # error prefix

### string constants for Ghostscript run
# get Ghostscript command name
my $GS = "gs";
$GS = "gs386"    if $^O =~ /dos/i;
$GS = "gsos2"    if $^O =~ /os2/i;
if ($^O =~ /mswin32c/i) {
    # http://perldoc.perl.org/perlport.html#DOS-and-Derivatives
    use Config;
    $GS = "gswin32c";
    $GS = "gswin64c" if $Config{'archname'} =~ /mswin32-x64/i;
}

# Windows detection (no SIGHUP)
my $Win = 0;
$Win = 1 if $^O =~ /mswin32/i;

my $gspages = 1;
$gspages = 0 if $^O =~ /dos/i;

### variables
my $jobname      = "";
my $jobfile      = "";
my $pdftexfile   = "";
my $pdfmarkfile  = "";
my $psext        = ".ps";
my $pdfext       = ".pdf";
my $pdftexext    = ".tpt";
my $pdfmarkext   = ".tpm";
my $thumbprefix  = "thb";
my $envvar       = "THUMBPDF";
my $pdffile      = "thumbpdf.pdf";
my $logfile      = "thumbpdf.log";
my $texfile      = "thumbpdf.tex";
my $package      = "thumbpdf.sty";
my $readme       = "readme.txt";
my $gscnffile    = "thumbpdf.gs";
my $gssection    = "section I. `Known Problems'";
my @cleanlist    = ();
my $resolution   = 9;
my $mode_pdftex  = 0;
my $mode_pdfmark = 0;
my $antialias_default = "4";
my @arglist      = @ARGV;
my $gskidrunning = 0;

### option variables
my @bool = ("false", "true");
$::opt_device     = "png16m";
$::opt_compress   = "10";
$::opt_resolution = "";
$::opt_modes      = "pdftex";
$::opt_gscmd      = "";
$::opt_level2     = 0;
$::opt_help       = 0;
$::opt_version    = 0;
$::opt_quiet      = 0;
$::opt_debug      = 0;
$::opt_verbose    = 0;
$::opt_useps      = 0;
$::opt_printgscmd = 0;
$::opt_gspages    = $gspages; # undocumented
$::opt_makepng    = 1;
$::opt_makepdf    = 1;
$::opt_makedata   = 1;
$::opt_clean      = 1;
$::opt_password   = "";
$::opt_antialias  = $antialias_default;
$::opt_greek      = 0;

my $usage = <<"END_OF_USAGE";
${title}Syntax:   \L$program\E [options] <jobname[.pdf|.ps]>
Function: Support of thumbnails for pdfTeX or dvips/ps2pdf (pdfmark).
          Thumbnails are generated by Ghostscript and the result is
          written to data files for package `$package':
          `<jobname>$pdftexext' (pdfTeX), `<jobname>$pdfmarkext' (pdfmark)
Options:                                                         (defaults:)
  --help          print usage
  --version       print version number
  --(no)quiet     suppress messages                              ($bool[$::opt_quiet])
  --(no)verbose   verbose printing                               ($bool[$::opt_verbose])
  --(no)debug     debug informations                             ($bool[$::opt_debug])
  --(no)makepng   make thumbnails `$thumbprefix*.png'                     ($bool[$::opt_makepng])
  --(no)makepdf   make `$pdffile' with thumbnails as images  ($bool[$::opt_makepdf])
  --(no)makedata  make data file(s) for package `$package'   ($bool[$::opt_makedata])
  --(no)clean     clear temp files                               ($bool[$::opt_clean])
  --(no)useps     `makepng' uses `.ps' instead of `.pdf' file    ($bool[$::opt_useps])
  --(no)level2    `<jobname>.tpm' with ps level 2 features       ($bool[$::opt_level2])
  --(no)greek     text in greek style (experimental)             ($bool[$::opt_greek])
  --gscmd <name>  call of ghostscript                            ($GS)
  --antialias <num1>[num2] anti-aliasing, 0 = disable, 4 = max   ($::opt_antialias)
  --device|png [png]<dev>  Ghostscript device for thumbnails,
                           dev = mono, gray, 16, 256, 16m        ($::opt_device)
  --resolution <res>       thumbnail resolution for makepng      ($resolution)
  --compress <n>           thumbnail compress level, n = 0..10   ($::opt_compress)
  --modes <mode>[,mode]    mode=pdftex|pdfmark|dvips|ps2pdf|
                                vtexpdfmark|all                  ($::opt_modes)
  --password <password>    for an encrypted pdf file             ($::opt_password)
END_OF_USAGE

### environment variable THUMBPDF
if ($ENV{$envvar}) {
  unshift(@ARGV, split(/\s+/, $ENV{$envvar}));
}

### process options
my @OrgArgv = @ARGV;
use Getopt::Long;
GetOptions(
  "help!",
  "version!",
  "quiet!",
  "debug!",
  "verbose!",
  "device|png=s",
  "gscmd=s",
  "level2!",
  "compress=i",
  "resolution=f",
  "modes=s",
  "useps!",
  "printgscmd!",
  "gspages!",
  "makepng!",
  "makepdf!",
  "makedata!",
  "clean!",
  "password=s",
  "antialias=s",
  "greek!"
) or die $usage;
!$::opt_help or die $usage;
if ($::opt_version) {
    print "$prj $date v$version\n";
    exit(0);
}
@ARGV < 2 or die "$usage$Error Too many files!\n";
@ARGV == 1 or die "$usage$Error Missing jobname!\n";

$::opt_device = "png$::opt_device" unless $::opt_device =~ /^png/;
$::opt_quiet = 0 if $::opt_verbose;
$::opt_clean = 0 if $::opt_debug or !$::opt_makepdf or !$::opt_makedata;

$::opt_compress = 0 if $::opt_compress < 0;
$::opt_compress = 10 if $::opt_compress > 10;
my $J = "^^J";
$J = "" if $::opt_compress == 10;

$::opt_antialias = $antialias_default if $::opt_antialias eq "";
$::opt_antialias =~ /^[0124][0124]?$/ or
  die "$usage$Error Wrong value for option --antialias!\n";
$::opt_antialias .= $::opt_antialias if length($::opt_antialias) < 2;
my $AntiAliasText     = substr($::opt_antialias, 0, 1);
my $AntiAliasGraphics = substr($::opt_antialias, 1, 1);
$AntiAliasText     = "1" if $AntiAliasText     eq "0";
$AntiAliasGraphics = "1" if $AntiAliasGraphics eq "0";

$GS = $::opt_gscmd if $::opt_gscmd;
$gspages = $::opt_gspages;

### get modes
$::opt_modes = "\L$::opt_modes\E";
$::opt_modes =~ s/dvips/pdfmark/g;
$::opt_modes =~ s/ps2pdf/pdfmark/g;
$::opt_modes =~ s/vtexpdfmark/pdfmark/g;
$::opt_modes =~ s/vtexpdfmark/pdfmark/g;
if ($::opt_modes =~ /pdftex/)
{
  $mode_pdftex = 1;
  $::opt_modes =~ s/pdftex//g;
}
if ($::opt_modes =~ /pdfmark/)
{
  $mode_pdfmark = 1;
  $::opt_modes =~ s/pdfmark//g;
}
if ($::opt_modes =~ /all/)
{
  $mode_pdftex = 1;
  $mode_pdfmark = 1;
  $::opt_modes =~ s/all//g;
}
$::opt_modes =~ s/\s+//g;
$::opt_modes =~ s/,+/,/g;
$::opt_modes =~ s/^,//;
$::opt_modes =~ s/,$//;
if ($::opt_modes ne "")
{
  die "$usage$Error Unknown mode(s): `$::opt_modes'\n";
}
if ($::opt_makedata)
{
  $mode_pdftex or $mode_pdfmark or
    die "$usage$Error Missing mode!\n";
}

### get jobname
$jobname = $ARGV[0];
if ($::opt_useps)
{
  $jobname =~ s/\.ps$//i;
  $jobname =~ s/\\/\//g;
  $jobfile = $jobname . $psext;
}
else
{
  $jobname =~ s/\.pdf$//i;
  $jobname =~ s/\\/\//g;
  $jobfile = $jobname . $pdfext;
}
$pdftexfile  = $jobname . $pdftexext;
$pdfmarkfile = $jobname . $pdfmarkext;

print $title unless $::opt_quiet;

print "* jobname: `$jobname'\n" if $::opt_verbose;

if ($::opt_debug) {
  print <<"END_DEB";
* OSNAME: $^O
* PERL_VERSION: $]
* ARGV: @OrgArgv
END_DEB
}

### set signals
$SIG{__DIE__} = \&clean;
setsignals(\&cleanup);

my $MaxThumb = 0;

###
### make thumbnails
###
if ($::opt_makepng)
{
  print "*** make png files / run Ghostscript ***\n"
      unless $::opt_quiet or $::opt_printgscmd;
  if ($::opt_useps)
  {
    print "* ps file: $jobfile\n" if $::opt_verbose;
  }
  else
  {
    print "* pdf file: $jobfile\n" if $::opt_verbose;
  }
  print "* Ghostscript command: `$GS'\n" .
        "* Ghostscript png device: `$::opt_device'\n" if $::opt_verbose;

  if ($::opt_resolution)
  {
    $resolution = $::opt_resolution
  }
  else
  {
    # looking for MediaBox

    my $max_x = 0;
    my $max_y = 0;
    {
      my $MB = $jobfile;
      open(MB, $MB) or die "$Error Cannot open `$MB'!\n";
      binmode(MB);
      my $xy_patt = '[\-\.\d]';
      while (<MB>)
      {
        if (/\/MediaBox\s*\[\s*($xy_patt+)\s+($xy_patt+)\s+($xy_patt+)\s+($xy_patt+)\s*\]/)
        {
          my $x = $3 - $1;
          my $y = $4 - $2;
          $max_x = $x if $x > $max_x;
          $max_y = $y if $y > $max_y;
        }
      }
      close(MB);
    }
    if ($max_x <= 0 || $max_y <= 0)
    {
      print "!!! Warning: MediaBox not found, " .
            "using default resolution: $resolution DPI\n";
    }
    else
    {
      print "* Max. Size of MediaBox: $max_x x $max_y\n" if $::opt_verbose;

      my $rx = 106 * 72 / $max_x;
      my $ry = 106 * 72 / $max_y;
      $resolution = $rx;
      $resolution = $ry if $ry < $rx;
      print "* Resolution: $resolution DPI\n" if $::opt_verbose;
    }
  }

# Ghostscript's pdfshowpage_setpage is patched for solving
# some problems:
# * gs6.0* includes a hack that ignores the /Rotate entry
#   in the PDF page, if OutputFile is set.
#   gs6.50 does not need a fix and it is not applied,
#   because pdfshowpage_setpage does not contain /OutputFile.
# * If /CropBox is set, then it should be used instead
#   of the /MediaBox entry. Because the CropBox area should
#   be part of the MediaBox, the MediaBox is overwritten
#   with the CropBox values for generating the thumbnails.
# The fixes are only applied for versions >= 6.0, because
# gs5.50 gets a /PageSize problem with this fix.
#
  my $SetPageHack = <<'SET_PAGE_HACK';
currentglobal true setglobal
false
/product where {
  pop
  product (Ghostscript) search {
    pop pop pop
    revision 600 ge {
      pop true
    } if
  }{pop} ifelse
} if
{ /pdfdict where {
    pop
    pdfdict begin
      /pdfshowpage_setpage
      [ pdfdict /pdfshowpage_setpage get
        { dup type /nametype eq
          { dup /OutputFile eq
            { pop /AntiRotationHack
            }{
              dup /MediaBox eq revision 650 ge and
              { /THB.CropHack {
                  1 index /CropBox pget
                  { 2 index exch /MediaBox exch put
                  } if
                } def
                /THB.CropHack cvx
              } if
            } ifelse
          } if
        } forall
      ] cvx def
    end
  } if
} if
setglobal
SET_PAGE_HACK

  my $Greek = "";
  $Greek = <<'END_GREEK' if $::opt_greek;
currentglobal true setglobal
userdict begin
  % * Patch for `show'
  /THB_ORG_show {show} bind def
  /THB_greekstring
  /.charboxpath where
  {
    pop
    {
      currentpoint newpath moveto
      true .charboxpath closepath fill
    } bind def
  }{
    {
      {
        1 string dup 0 4 -1 roll put
        dup stringwidth pop exch
        true charpath flattenpath pathbbox
        2 index sub exch 3 index sub exch rectfill
        0 rmoveto
      } forall
    } bind def
  } ifelse
  /show {
    currentfont /FontType get 1 eq
    {
      dup
      gsave
        % assuming white background
        [ currentrgbcolor ]
        { 1 add 2 div } forall
        setrgbcolor
        THB_greekstring
      grestore
      stringwidth pop 0 rmoveto
    }{
      THB_ORG_show
    } ifelse
  } bind def

  % * Patch for the PDF case
  userdict /GS_PDF_ProcSet known
  {
    % GS_PDF_ProcSet is readonly, so it will be copied first
    GS_PDF_ProcSet length 10 add dict dup
    GS_PDF_ProcSet {
      put dup
    } forall
    /GS_PDF_ProcSet exch def
    dup
    begin
      % `setshowstate' contains the use of `show', so it has to
      % be overwritten, because it was defined with `bind'.
      % The definition is taken from `pdf_ops.ps'.
      revision 710 lt
      { % 5.50, 6.51, 7.00, 7.02

/setshowstate
 { WordSpacing 0 eq TextSpacing 0 eq and
    { TextRenderingMode 0 eq
       { { setfillstate show } }
       { { false charpath textrenderingprocs TextRenderingMode get exec } }
      ifelse
    }
    { TextRenderingMode 0 eq
       { WordSpacing 0 eq
          { { setfillstate TextSpacing exch 0 exch ashow } }
          { TextSpacing 0 eq
             { { setfillstate WordSpacing exch 0 exch 32 exch widthshow } }
             { { setfillstate WordSpacing exch TextSpacing exch 0 32 4 2 roll 0 exch awidthshow } }
            ifelse
          }
         ifelse
       }
       { { WordSpacing TextSpacing
                        % Implement the combination of t3 and false charpath.
                        % Note that we must use cshow for this, because we
                        % can't parse multi-byte strings any other way.
                        % Stack: string xword xchar
            { pop pop (x) dup 0 3 index put false charpath
                        % Stack: xword xchar ccode
              3 copy 32 eq { add } { exch pop } ifelse 0 rmoveto pop
            }
           4 -1 roll cshow pop pop
           textrenderingprocs TextRenderingMode get exec
         }
       }
      ifelse
    }
   ifelse /Show gput
 } bdef

      }{ % 7.10

/setshowstate
 { WordSpacing 0 eq TextSpacing 0 eq and
    { TextRenderingMode 0 eq
       { { setfillstate show } }
       { { false charpath textrenderingprocs TextRenderingMode get exec } }
      ifelse
    }
    { TextRenderingMode 0 eq
       { WordSpacing 0 eq
          { { setfillstate TextSpacing 0 Vexch 3 -1 roll ashow } }
          { TextSpacing 0 eq
            { { setfillstate WordSpacing 0 Vexch 32 4 -1 roll widthshow } }
            { { setfillstate WordSpacing 0 Vexch 32
                 TextSpacing 0 Vexch 6 -1 roll awidthshow } }
            ifelse
          }
         ifelse
       }
       { { WordSpacing TextSpacing
                        % Implement the combination of t3 and false charpath.
                        % Note that we must use cshow for this, because we
                        % can't parse multi-byte strings any other way.
                        % Stack: string xword xchar
            { pop pop (x) dup 0 3 index put false charpath
                        % Stack: xword xchar ccode
             3 copy 32 eq { add } { exch pop } ifelse 0 Vexch rmoveto pop
            }
           4 -1 roll cshow pop pop
           textrenderingprocs TextRenderingMode get exec
         }
       }
      ifelse
    }
   ifelse /Show gput
 } bdef

      } ifelse
    end
    readonly pop
  } if
end
setglobal
END_GREEK

  my $SetPassword = "";
  $SetPassword = "/PDFPassword($::opt_password)def" if $::opt_password;

  my $PSHeader = "save pop $SetPassword $SetPageHack $Greek";
  $PSHeader =~ s/%\s.*\n/ /g;
  $PSHeader =~ s/\s+/ /g;
  $PSHeader =~ s/\s+([\(\/\[\]\{\}])/$1/g;
  $PSHeader =~ s/([\)\[\]\{\}])\s+/$1/g;
  $PSHeader =~ s/\s+$//;

  my $AntiAlias = "";
  $AntiAlias = "\n-dTextAlphaBits=$AntiAliasText\n" .
               "-dGraphicsAlphaBits=$AntiAliasGraphics"
    if $::opt_antialias;

  my $gs_cmd = <<"GS_CMD_END";
$GS$AntiAlias
-dNOPAUSE
-dBATCH
-sDEVICE=$::opt_device
-r$resolution
-sOutputFile=$thumbprefix%d.png
-c "$PSHeader"
-f $jobfile
GS_CMD_END
  # The trick with `save' comes from `ps2pdf':
  # Doing an initial `save' helps keep fonts from being flushed
  # between pages.

  if ($::opt_printgscmd)
  {
    open(GSCNF, ">$gscnffile") or die "$Error Cannot open `$gscnffile'!\n";
    $gs_cmd =~ s/^[^\r\n]+[\r\n]+//;
    print GSCNF $gs_cmd;
    close(GSCNF);
    my $options = "@arglist";
    $options =~ s/\s*--?pr[intgscmd]*\s*/ /i;
    $options =~ s/^\s+//;
    $options =~ s/\s+$//;
    print <<"END_PERL" if $::opt_verbose;
* Perl interpreter: $^X
* Perl script: $0
END_PERL
    print <<"END_GS";
1. Run `Ghostscript' manually:
   ==> $GS \@$gscnffile
2. Call `thumbpdf' again with the additional option `--nomakepng':
   ==> thumbpdf --nomakepng $options
END_GS
    exit(0);
  }

  chomp($gs_cmd);
  $gs_cmd =~ s/\n/ /mg;
  print "> $gs_cmd\n" if $::opt_verbose;

  if ($::opt_debug)
  {
    if ($gspages)
    {
      print "* Ghostscript with page numbers\n";
    }
    else
    {
      print "* Ghostscript without page numbers\n";
    }
  }

  setsignals(\&gscleanup);
  my $capture = "";
  if ($gspages)
  {
    my $newline = 0;
    open(KID, "$gs_cmd|") or die "$Error Cannot open Ghostscript ($!)!\n";
    *::GSKID = *KID;
    $gskidrunning = 1;
    my $orgbar = $|;
    $|=1;
    while (<KID>)
    {
      $capture .= $_;
      if ($::opt_verbose)
      {
        print;
      }
      else
      {
        if (!$::opt_quiet)
        {
          print if /^Processing pages/;
          if (/^Page\s+(\d+)/)
          {
            print " " if $newline;
            $newline = 1;
            print "[$1]";
          }
        }
      }
    }
    $gskidrunning =0;
    if (!close(KID))
    {
      if ($!)
      {
        die "$Error Closing Ghostscript ($!)!\n";
      }
      else
      {
        my $exitvalue = $? >> 8;
        die "$Error Closing Ghostscript (exit status: $exitvalue)!\n";
      }
    }
    print "\n" if $newline;
    $| = $orgbar;
  }
  else # without pages
  {
    $capture = `$gs_cmd`;
    if (!defined($capture))
    {
      die "$Error Cannot execute Ghostscript!\n";
    }
    print $capture if $::opt_verbose;
  }

  if ($capture =~ /Error:\s*(.*)\n/)
  {
    die <<"END_DIE";
$Error `$1' (Ghostscript)!
See `$readme', $gssection, for further information.
END_DIE
  }
  if ($capture =~ /Unknown device:\s*(.*)\n/)
  {
    die "$Error Unknown device `$1' (Ghostscript)!\n";
  }
  if ($?)
  {
    my $exitvalue = $?;
    if ($exitvalue > 255)
    {
      $exitvalue >>= 8;
      die "$Error Closing Ghostscript (exit status: $exitvalue)!\n";
    }
    die "$Error Closing Ghostscript ($exitvalue)!\n";
  }
  if ($capture =~ /Processing pages \d+ through (\d+)./)
  {
    $MaxThumb = $1;
  }
  print "* max. page: $MaxThumb\n" if $::opt_debug;
  setsignals(\&cleanup);
}

###
### make thumbpdf.pdf file
###
if ($::opt_makepdf)
{
  print "*** make `$pdffile' / run pdfTeX ***\n" unless $::opt_quiet;

  if ($MaxThumb > 0)
  {
    my $i;
    for ($i=1; $i<=$MaxThumb; $i++)
    {
      push(@cleanlist, "$thumbprefix$i.png");
    }
  }
  else
  {
    # get max thumb number to speed up the pdfTeX run
    $MaxThumb = 0;
    foreach (glob("$thumbprefix*.png"))
    {
      next unless /$thumbprefix(\d+).png/;
      $MaxThumb = $1 if $1 > $MaxThumb;
      push(@cleanlist, $_);
    }
  }

  push(@cleanlist, $logfile);
  push(@cleanlist, $pdffile);

  my $compress = $::opt_compress;
  $compress = 9 if $::opt_compress == 10;
  my $cmd = "pdftex \"" .
            "\\nonstopmode" .
            "\\pdfcompresslevel$compress" .
            "\\def\\thumbjob{$jobname}" .
            "\\def\\thumbmax{$MaxThumb}" .
            "\\input $texfile" .
            "\"";
  print "> $cmd\n" if $::opt_verbose;
  my @capture = `$cmd`;
  if (!@capture)
  {
    die "$Error Cannot execute pdfTeX!\n";
  }
  if ($::opt_verbose)
  {
    print @capture;
  }
  else
  {
    foreach (@capture)
    {
      print if /^!\s/;
    }
  }
  if ($?)
  {
    my $exitvalue = $?;
    if ($exitvalue > 255)
    {
      $exitvalue >>= 8;
      die "$Error Closing pdfTeX (exit status: $exitvalue)!\n";
    }
    die "$Error Closing pdfTeX ($exitvalue)!\n";
  }
  # test version
  my $versionfound = 0;
  foreach (@capture)
  {
    if (/File:.*thumbpdf.*(\d\d\d\d\/\d\d\/\d\d)\s+v(\d+\.\d+)/)
    {
      $versionfound = 1;
      if ($1 ne $date or $2 ne $version) {
        print <<"END_WARN";
!!! Warning: Version of `thumbpdf.tex' does not match with perl script!
    Current `thumbpdf.tex': $1 v$2
    Please install version: $date v$version
END_WARN
      }
    }
  }
  print "!!! Warning: Version of `thumbpdf.tex' not found!\n"
    if !$versionfound;

  $_ = pop(@cleanlist);
}

###
### parse thumbpdf.pdf
###

if ($::opt_makedata)
{
  push(@cleanlist, $pdffile);

  print "*** parse `$pdffile' ***\n" unless $::opt_quiet;

### reading file and parse obj structure

  my @objno = (); # obj number
  my @objdict = (); # boolean, object is dict
  my @objtext = (); # text of object
  my @objstream = (); # stream of object if any
  my $maxobj = 0;

  my @getobjindex = (); # $getobj[obj number] ==> index for $obj...[index]

  # open file
  my $PDF = $pdffile;
  open(PDF, $PDF) or die "$Error Cannot open `$PDF'!\n";
  binmode(PDF);
  my $lineno = 0;

  # read header
  $_ = <PDF>; $lineno++;
  $_ or die "$Error Cannot read header of `$PDF' or file is empty!\n";
  /^%PDF/ or die "$Error No PDF specification found!\n";
  print "* pdf header: $_" if ($::opt_debug);

  # read body objects
  my $count = 0;
  while (<PDF>)
  {
    $lineno++;

    # continue, if comment line (2nd line of PDF output by pdfTeX 1.30)
    next if /^%/;

    # stop at xref
    last if /^xref$/;

    # scan first obj line
    /^(\d+)\s+0\s+obj\s*(<<)?$/ or
      die "$Error `obj' expected on line $lineno!\n";
    $objno[$count] = $1;
    $getobjindex[$1] = $count;
    $objdict[$count] = ($2); # boolean (if $2 exists)
    if (!$objdict[$count]) {
      # check for << on thext line, new PDF-X/2014
      $_ = <PDF>;
      if (/^<<$/) {
      	$objdict[$count] = 1;
	$lineno++;
	$_ = <PDF>;
	$lineno++;
      }
    }
    my $stream = 0;
    print "* obj $objno[$count]" .
      (($objdict[$count]) ? " (dict)" : "") .
      "\n" if $::opt_debug;

    # get obj
    $objtext[$count] = "";
    while ($_)
    {
      if ($objdict[$count])
      {
        if (/^>>/)
        {
          last if /^>>\s+endobj$/; # obj without stream

          $_ = <PDF>; $lineno++;
          last if /^endobj$/; # obj without stream, new PDF-X/2014

          # get stream
          /^stream$/ or die "$Error `stream' expected on line $lineno!\n";

          print "* stream\n" if $::opt_debug;
          $objstream[$count] = "";
          while (<PDF>)
          {
            $lineno++;

            if (/(.*)endstream$/)
            {
              $objstream[$count] .= $1;
              last;
            }
            $objstream[$count] .= $_;
          }

          $_ = <PDF>; $lineno++;
          /^endobj$/ or die "$Error `endobj' expected on line $lineno!\n";
          last;
        }
      }
      else # no dict
      {
        last if /^endobj$/;
      }
      $objtext[$count] .= $_;

      $_ = <PDF>;
      $lineno++;
    }
    $count++;
  }
  close(PDF);
  $maxobj = $count;
  print "* $maxobj objects found.\n" if $::opt_debug;

### get thumbnail page numbers
  my @thumbpageno = ();
  my $found = 0;
  foreach (@objtext)
  {
    if (/^<<\/ListThumbs\s+(.+)>>$/)
    {
      $_ = $1;
      chomp;
      @thumbpageno = split / /; # split(/ /, $_);
      print "* ListThumbs: @thumbpageno\n" if $::opt_debug;
      $found = 1;
      last;
    }
  }
  $found or die "$Error `/ListThumbs' not found!\n";
  {
    my $j;
    for ($j=0; $j<@thumbpageno; $j++)
    {
      $thumbpageno[$j] = $1 if $thumbpageno[$j] =~ /^{(.+)}$/;
    }
  }

### identify thumb objects

  my @thumbobj = ();    # index for @obj... with image stream
  my @thumblength = (); # stream length values
  my @thumbrgbobj = (); # index for @obj... with rgb stream
  my @thumbrgblength = (); # rgb stream length values
  my $maxthumb = 0;

  $count = 0;
  my $i;
  for ($i=0; $i<$maxobj; $i++)
  {
    if ($objtext[$i] =~
        /^\/Type\s+\/XObject\n\/Subtype\s+\/Image\n/m)
    {
      $thumbobj[$count] = $i;
      $_ = $';
      $objtext[$i] = $_;

      # check width and height
      /\/Width\s+(\d+)\n\/Height\s+(\d+)/m or
        die "$Error width/height of thumbnail not found!\n";
      print "* Size: $1x$2\n" if $::opt_debug;
      print "==> Width ($1) " .
            "of thumbnail `$thumbpageno[$count]' " .
            "is larger than recommended (106).\n"
        if $1 > 106;
      print "==> Height ($2) " .
            "of thumbnail `$thumbpageno[$count]' " .
            "is larger than recommended (106).\n"
        if $2 > 106;

      # get stream length
      if (/\/Length\s+(\d+)\s+([\/\>]|$)/m)
      {
        $thumblength[$count] = $1;
        print "* Length (direct): $1\n" if $::opt_debug;
        # remove whitespace after length obj
        $objtext[$i] =~ s/(\/Length\s+\d+)\s+\n/$1\n/;
      }
      else # looking for indirect reference
      {
        /\/Length\s+(\d+)\s+0\s+R/m or
          die "$Error `/Length' entry not found!\n";
        # save obj text for later correction
        my $objpre = $`;
        my $objpost = $';
        # look for length obj
        $getobjindex[$1] or die "$Error Length obj not found!\n";
        $objtext[$getobjindex[$1]] =~ /^(\d+)$/m or
          die "$Error length value not found!\n";
        $thumblength[$count] = $1;
        print "* Length (indirect): $1\n" if $::opt_debug;
        # insert obj length directly:
        $objtext[$i] = $objpre . "/Length $1" . $objpost;
      }

      # remove \n from end of stream
      if ($thumblength[$count] < length($objstream[$i])) {
        chop($objstream[$i]);
      }

      # check /Indexed /DeviceRGB
      if ($objtext[$i] =~
        /\/ColorSpace\s+\[\/Indexed\s+\/DeviceRGB\s+(\d+)\s+(\d+)\s+0\s+R\]/m)
      {
        # correct thumb object text
        $objtext[$i] =
          "$`/ColorSpace [/Indexed /DeviceRGB $1 \\the\\pdflastobj\\ 0 R]$'";
        # get RGB obj number
        $getobjindex[$2] or die "$Error RGB object not found!\n";
        $_ = $getobjindex[$2];
        $thumbrgbobj[$count] = $_;
        # get stream length
        if ($objtext[$_] =~ /\/Length\s+(\d+)\s+([\/\>]|$)/m)
        {
          $thumbrgblength[$count] = $1;
          print "* RGB length (direct): $1\n" if $::opt_debug;
          $objtext[$_] =~ s/(\/Length\s+\d+)\s+\n/$1\n/;
        }
        else # looking for indirect reference
        {
          $objtext[$_] =~ /\/Length\s+(\d+)\s+0\s+R/m or
            die "$Error Length entry of rgb object not found\n";
          # save obj text for later correction
          my $objrgbpre = $`;
          my $objrgbpost = $';
          # get rgb stream length
          $getobjindex[$1] or die "$Error RGB length object not found!\n";
          $objtext[$getobjindex[$1]] =~ /^(\d+)$/m or
            die "$Error length value not found!\n";
          $thumbrgblength[$count] = $1;
          print "* RGB length (indirect): $1\n" if $::opt_debug;
          # insert RGB object length directly:
          $objtext[$_] = $objrgbpre . "/Length $1" . $objrgbpost;
        }
      }

      $count++;
    }
  }
  $maxthumb = $count;

  if ($maxthumb != @thumbpageno)
  {
    my $pagecount = @thumbpageno;
    die "$Error $maxthumb thumbnails found, but there should be $pagecount!\n";
  }
  print "* $maxthumb thumbnails found.\n" if $::opt_verbose;


###
### write data files
###

  my $timestamp;
  {
    my ($sec, $min, $hour, $mday, $mon, $year) = localtime();
    $mon++;
    $year += 1900;
    $timestamp = sprintf("%04d/%02d/%02d %02d:%02d:%02d",
      $year, $mon, $mday, $hour, $min, $sec);
  }
  if ($mode_pdftex)
  {
    print "*** write `$pdftexfile' (pdfTeX thumbnail data) ***\n"
      unless $::opt_quiet;
    my $DTA_PT = $pdftexfile;
    open(DTA_PT, ">$DTA_PT") or die "$Error Cannot open `$DTA_PT'!\n";
    binmode(DTA_PT);
    print DTA_PT <<"END_DTA";
% File: $DTA_PT
% Producer: $program $version
% Mode: pdftex
% Date: $timestamp
END_DTA
  }
  my $maxpagethumb;
  my $dictbegin;
  if ($mode_pdfmark)
  {
    print "*** write `$pdfmarkfile' (pdfmark thumbnail data) ***\n"
      unless $::opt_quiet;
    my $DTA_PM = $pdfmarkfile;
    open(DTA_PM, ">$DTA_PM") or die "$Error Cannot open `$DTA_PM'!\n";
    binmode(DTA_PM);

    # write tex part
    print DTA_PM <<"END_DTA";
% \\iffalse
% File: $DTA_PM
% Producer: $program $version
% Mode: pdfmark
% Date: $timestamp
% \\fi
END_DTA

    # looking for max. number of regular thumbnails
    $maxpagethumb = $maxthumb;
    for ($i=0; $i<$maxobj; $i++)
    {
      if ($objtext[$i] =~ /<<\/MaxThumbNumber\s+(\d+)>>/)
      {
        $maxpagethumb = $1;
        last;
      }
    }

    # write TeX part
    for ($i=$maxpagethumb; $i<$maxthumb; $i++)
    {
      print DTA_PM "% \\DefThisThumb{$thumbpageno[$i]}\n";
    }

    # write PostScript header
    my $dictstart = <<'END_DICT';
  4 dict begin
  /enddict {
    counttomark 2 idiv dup dict begin {def} repeat pop
    currentdict end
  } bind def
END_DICT
    chomp($dictstart);
    $dictbegin = "[";
    my $dictend = "enddict";
    my $filter = "";
    my $read = "readhexstring";
    if ($::opt_level2)
    {
      $dictstart = "  3 dict begin";
      $dictbegin = "<<";
      $dictend = ">>";
      $filter = " /ASCII85Decode filter";
      $read = "readstring";
    }

    print DTA_PM <<"END_DTA";
% \\endinput
% TeX part ends here

% PostScript definitions
END_DTA

    my $PS_Header = <<"END_HEAD";
%
% Default definition of pdfmark
/pdfmark where {pop} {userdict /pdfmark /cleartomark load put} ifelse
%
% Check the version of Ghostscript. If it is below 6.0,
% the commands, that produce the thumbnails, are defined
% to be dummies.
%
true
/product where {
  pop
  product (Ghostscript) search {
    pop pop pop
    revision 600 lt {
      (!!! Warning (thumbpdf): Ghostscript 6.0 required for thumbnails!\\n)
      print pop false
    } if
  }{pop} ifelse
} if
{
% Syntax: <thumb object> thisTHB -
% thisTHB is used globally, so it is defined in the current
% dictionary (perhaps userdict should explicitly be set).
  /thisTHB {[ exch /Thumb exch /PAGE pdfmark} bind def
$dictstart
% Syntax: <page object> <thumb object> pagethumb -
  /pagethumb {
    [ 3 1 roll $dictbegin exch /Thumb exch $dictend /PUT pdfmark
  } bind def
% Syntax: <thumb object> <stream length>
%         <mark> <key value pairs> streamobj -
%
% Distiller ignores the compression of previously compressed
% streams and uses its own settings. Therefore for Distiller
% the streams are uncompressed.
% Now ghostscript versions greater than 8 behave in the same way
% as Distiller. Therefore detection for this versions is added.
% The detection and patch for distiller require features of level 2
% and the filter /FlateDecode (level 3), that is used by pdfTeX's
% compression.
  /THB_DistillerPatch false def
  /languagelevel where {
    pop
    languagelevel 2 ge {
      product (Distiller) search {pop pop pop true}{pop false} ifelse
      product (Ghostscript) search {
        pop pop pop
        revision 800 ge
      }{pop false} ifelse
      or
      {
        (FlateDecode) {
          pop
% Syntax: <dict> THB_DistillerPatch <dict> false
%         <dict> THB_DistillerPatch <dict> <filter>
          /THB_DistillerPatch {
            dup /Filter known {
              dup dup /Filter get exch /Filter undef
            }{false} ifelse
          } bind def
        } (FlateDecode) /Filter resourceforall
      } if
    } if
  } if
  /streamobj {
    $dictend exch
% Stack: <thumb> <dict> <length>
    3 -1 roll dup
% Stack: <dict> <length> <thumb> <thumb>
    [ /_objdef 3 -1 roll /type /stream /OBJ pdfmark
% Stack: <dict> <length> <thumb>
    dup dup 5 -1 roll
% Stack: <length> <thumb> <thumb> <thumb> <dict>
    THB_DistillerPatch
% Stack: <length> <thumb> <thumb> <thumb> <dict> <filter/false>
    [ 4 -2 roll /PUT pdfmark
% Stack: <length> <thumb> <thumb> <filter/false>
    [ 3 1 roll currentfile${filter}
% Stack: <length> <thumb> [ <thumb> <filter/false> <file>
      6 -1 roll string $read pop
% Stack: <thumb> [ <thumb> <filter/false> <string>
      exch dup type /booleantype ne {true} if {filter} if
% Stack: <thumb> [ <thumb> <file>
      /PUT pdfmark
% Stack: <thumb>
    [ exch /CLOSE pdfmark
  } bind def
}{
% Syntax: <thumb object> thisTHB -
  /thisTHB {pop} bind def
  2 dict begin
% Syntax: <page object> <thumb object> pagethumb -
  /pagethumb {pop pop} bind def
% Syntax: <thumb object> <stream length>
%         <mark> <key value pairs> streamobj -
  /streamobj {
    cleartomark exch pop
    string currentfile${filter}
    exch $read pop pop
  } bind def
} ifelse
END_HEAD
    $PS_Header =~ s/%[^\r\n]*[\r\n]+//gm;
    print DTA_PM $PS_Header;
    print DTA_PM <<"END_DTA";

% adding thumbnails to pages
END_DTA

    for ($i=0; $i<$maxpagethumb; $i++)
    {
      print DTA_PM <<"END_DTA";
{Page$thumbpageno[$i]} {THB$thumbpageno[$i]} pagethumb
END_DTA
    }
    print DTA_PM "\n% thumbnail data\n";
  }

  for ($i=0; $i<$maxthumb; $i++)
  {
    # rgb object
    if ($thumbrgbobj[$i])
    {
      # find the same rgb object
      my $j;
      for ($j=0; $j<$i; $j++)
      {
        next unless $thumbrgbobj[$j];
        next unless $objtext[$thumbrgbobj[$j]] eq
                    $objtext[$thumbrgbobj[$i]];
        next unless $objstream[$thumbrgbobj[$j]] eq
                    $objstream[$thumbrgbobj[$i]];
        last;
      }
      if ($j==$i) # not found
      {
        if ($mode_pdftex)
        {
          {
            my $rgbstream = pdftexstream($objstream[$thumbrgbobj[$i]]);
            my $dict = $objtext[$thumbrgbobj[$i]];
            if ($::opt_compress == 10)
            {
              chomp($dict);
              $dict =~ s/\n([^\/])/^^J\n$1/mg;
              $dict =~ s/[ ]+\//\//mg;
            }
            else
            {
              $dict =~ s/\n/^^J\n/mg;
            }
            print DTA_PT <<"END_DTA";
\\immediate\\pdfobj{<<$J
$dict>>$J
stream^^J
$rgbstream
endstream}
\\DefRGB{$i}
END_DTA
          }
        }
        if ($mode_pdfmark)
        {
          {
            my $rgbstream = pdfmarkstream($objstream[$thumbrgbobj[$i]]);
            my $rgblength = $thumbrgblength[$i];
            my $dict = $objtext[$thumbrgbobj[$i]];
            $dict =~ s/\/Length\s+\d+\s*//;
            $dict =~ s/^\s+//;
            $dict =~ s/\s+$//;
            print DTA_PM <<"END_DTA";
{RGB_$i} $rgblength $dictbegin
$dict
streamobj
$rgbstream
END_DTA
          }
        }
      }
      else # $j with same rgb obj
      {
        $objtext[$thumbobj[$i]] =~
          s/\\the\\pdflastobj/\\UseRGB{$j}/;
        print "* Reuses RGB object $j for $i\n" if $::opt_debug;
      }
    }

    # thumb object
    if ($mode_pdftex)
    {
      {
        my $dict = $objtext[$thumbobj[$i]];
        if ($::opt_compress == 10)
        {
          chomp($dict);
          $dict =~ s/\n([^\/])/^^J\n$1/mg;
          $dict =~ s/[ ]+\//\//mg;
          $dict =~ s/[ ]+\[/\[/mg;
        }
        else
        {
          $dict =~ s/\n/^^J\n/mg;
        }
        my $stream = pdftexstream($objstream[$thumbobj[$i]]);
        print DTA_PT <<"END_DTA";
\\immediate\\pdfobj{<<$J
$dict>>$J
stream^^J
$stream
endstream}
\\DefThumb{$thumbpageno[$i]}
END_DTA
      }
    }
    if ($mode_pdfmark)
    {
      {
        my $stream = pdfmarkstream($objstream[$thumbobj[$i]]);
        my $length = $thumblength[$i];
        my $dict = $objtext[$thumbobj[$i]];
        $dict =~ s/\\the\\pdflastobj\\\s*\d+\s*R/{RGB_$i}/;
        $dict =~ s/\\UseRGB\{(\d+)\}\\\s*\d+\s*R/{RGB_$1}/;
        $dict =~ s/\/Length\s+\d+\s*//;
        $dict =~ s/^\s+//;
        $dict =~ s/\s+$//;
        my $thismarker = "";
        $thismarker = "_", if $i >= $maxpagethumb;
        print DTA_PM <<"END_DTA";
{THB$thismarker$thumbpageno[$i]} $length $dictbegin
$dict
streamobj
$stream
END_DTA
      }
    }
  }

  if ($mode_pdftex)
  {
    print DTA_PT "\\endinput\n";
    close(DTA_PT);
  }
  if ($mode_pdfmark)
  {
    print DTA_PM <<"END_DTA";
end
% end of thumbnail data file
END_DTA
    close(DTA_PM);
  }
}

sub pdftexstream
{
  my $str = "";
  my $mod = 0;
  foreach (split(//, $_[0]))
  {
    my $num = ord($_);
    if    ($num == 13)  { $str .= '\\/'; }
    elsif ($num < 32)   { $str .= '^^' . chr($num + 64); }
    elsif ($num == 32)  { $str .= '\\~'; } # space
    elsif ($num == 37)  { $str .= '\\%'; } # percent
    elsif ($num == 92)  { $str .= '\\\\'; } # backslash
    elsif ($num == 94)  { $str .= '\\+'; } # caret
    elsif ($num == 123) { $str .= '\\{'; } # curly brace left
    elsif ($num == 125) { $str .= '\\}'; } # curly brace right
    else  { $str .= $_; }
    $mod++;
    if ($mod == 26)
    {
      $mod = 0;
      $str .= "\n";
    }
  }
  chomp $str;
  return $str;
}

sub pdfmarkstream
{
  my $str;
  if ($::opt_level2)
  {
    my $s = $_[0];
    my $len = length($s);
    $str = "";
    my $i;
    for ($i=0; $i<$len-4; $i+=4)
    {
      $_ = ASCII85Encode(substr($s, $i, 4));
      s/!!!!!/z/;
      $str .= $_;
    }
    my $r = $len % 4;
    if ($r)
    {
      $_ = substr($s, $i, $r) . "\000\000\000";
      $_ = ASCII85Encode(substr($_, 0, 4));
      $str .= substr($_, 0, $r+1);
    }
    $str =~ s/(.{60})/$1\n/g;
    chomp($str);
    $str .= "~>";
  }
  else
  {
    $str = uc(unpack('H*', $_[0]));
    $str =~ s/(.{60})/$1\n/g;
    chomp($str);
  }
  return $str;
}

sub ASCII85Encode
{
  my $val = unpack("N", $_[0]);
  my @c;
  $c[4] = $val % 85 + 33;
  $val = int($val/85);
  $c[3] = $val % 85 + 33;
  $val = int($val/85);
  $c[2] = $val % 85 + 33;
  $val = int($val/85);
  $c[1] = $val % 85 + 33;
  $c[0] = int($val/85) + 33;
  return pack("C*", @c);
}

sub setsignals {
  my $func = $_[0];
  $SIG{'HUP'}   = $func unless $Win;
  $SIG{'INT'}   = $func;
  $SIG{'QUIT'}  = $func;
  $SIG{'TERM'}  = $func;
}

sub clean {
  if ($::opt_clean) {
    print "*** clear temp files ***\n" unless $::opt_quiet;
    foreach (@cleanlist) {
      unlink;
    }
  }
}

sub cleanup {
  print "\n" unless $::opt_quiet;
  clean();
  exit 1;
}

sub gscleanup {
  print "\n" unless $::opt_quiet;
  clean();
  close(::GSKID) if $gskidrunning;
  foreach (glob("$thumbprefix*.png")) {
    unlink;
  }
  exit 1;
}

clean();

print "*** ready. ***\n" unless $::opt_quiet;

__END__
