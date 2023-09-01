#!/usr/bin/env perl
# $Id: epstopdf.pl 67585 2023-07-08 21:10:52Z karl $
# (Copyright lines below.)
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright
#    notice, this list of conditions and the following disclaimer.
# 2. Redistributions in binary form must reproduce the above copyright
#    notice, this list of conditions and the following disclaimer in the
#    documentation and/or other materials provided with the distribution.
# 3. The name of the author may not be used to endorse or promote
#    products derived from this software without specific prior written
#    permission.
#
# THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY EXPRESS OR
# IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY DIRECT,
# INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR
# SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
# HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
# STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN
# ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# ----------------------------------------------------------------
# This is a script to transform an EPS file to PDF.  Theoretically, any
# Level 2 PS interpreter should work, although in practice using
# Ghostscript is near-universal.  Many more details below.
# 
# One thing not supported is the case of
# "%%BoundingBox: (atend)" when input is not seekable (e.g., from a pipe),
#
# emacs-page
#
my $ver = "2.32";
#  2023/07/08 2.32 (Karl Berry)
#    * check that kpsewhich and gs are in PATH.
#    * correct TL path for kpsewhich to bin/windows.
#  2023/03/06 v2.31 (Karl Berry)
#    * disallow --nosafer in restricted mode.
#    * disallow output to pipes in restricted mode.
#    Report from nikolay.ermishkin to tlsecurity.
#  2022/09/05 v2.30 (Siep Kroonenberg)
#    * still use gswin32c if gswin64c.exe not on PATH.
#  2022/08/29 v2.29 (Karl Berry)
#    * use gswin64c.exe on 64-bit Windows.
#  2018/09/17 v2.28 (Karl Berry)
#    * -dCompatibilityLevel=1.5 by default, since gs9.25 switched to 1.7.
#  2017/09/14 v2.27 (Karl Berry)
#    * extract value from --gsopt with $3 not $2 (extra regexp group
#      added previously), and check it with ^(...)$ so anchors apply to all.
#      (report to Karl from Yannick Berker, 7 Sep 2017 14:07:09.)
#  2017/01/07 v2.26 (Norbert Preining, Karl Berry)
#    * allow cmdline of infile outfile.pdf.
#    * explicitly allow -o as abbreviation for --outfile,
#      to guard against future --options. (Also --output.)
#  2016/06/30 v2.25 (Norbert Preining, Karl Berry)
#    * don't set (default) device until after restricted check.
#    * a few more debugging lines.
#  2016/05/29 v2.24 (Karl Berry)
#    * new option --gray; patch from William Bader,
#      tex-k mail 9 Feb 2016 19:37:08.
#    * disallow --device completely in restricted mode,
#      to avoid maintenance of device list.
#      tex-live mail 10 Feb 2016 10:36:26.
#  2015/01/22 v2.23 (Karl Berry)
#    * use # instead of = to placate msys; report from KUROKI Yusuke,
#      tex-k mail 20 Jan 2015 12:40:16.
#  2014/06/18 v2.22 (Karl Berry)
#    * escape % in $outputfilename; report from William Fischer,
#      tex-k mail 16 Jun 2014 18:45:12.
#  2014/01/17 v2.21 (Karl Berry)
#    * tweaks to help message, per reports from Knuth.
#  2013/09/28 v2.20 (Heiko Oberdiek, and (a little) Karl Berry)
#    * New command line argument --(no)safer which allows setting
#      -dNOSAFER instead of -dSAFER (only for non-restricted).
#    * New command line argument --pdfsettings for
#      Ghostscript's -dPDFSETTINGS.
#    * New command line argument --(no)quiet.
#    * New command line argument --device for specifying a differnt
#      Ghostscript device (limited set of devices for restricted mode).
#    * New command line arguments --gsopts and --gsopt for adding
#      Ghostscript options.
#    * Full support of ghostscript's option -r, DPIxDPI added.
#    * Support for DOS EPS binary files (TN 5002) added.
#    * Removes PJL commands at start of file.
#  2013/05/12 v2.19 (Karl Berry)
#    * explain option naming conventions (= defaults for Getopt::Long).
#  2012/05/22 v2.18 (Karl Berry)
#    * use /usr/bin/env, since Ruby has apparently required #! for years,
#      and we rely on it for our other scripts, so why not.
#      (tex-k mail from Jean Krohn, 2 Aug 2010 15:57:54,
#       per http://osdir.com/ml/lang.ruby.general/2002-06/msg01388.html
#       and ruby-bugs:PR#315).
#  2012/05/12 v2.17 (Karl Berry)
#    * uselessly placate -w.  Debian bug 672281.
#  2010/05/09 v2.16 (Karl Berry)
#    * make --nogs dump edited PostScript to stdout by default
#      (report from Reinhard Kotucha).
#  2010/03/19 v2.15 (Karl Berry)
#    * let --outfile override --filter again.
#    * recognize MSWin64 as well as MSWin32, just in case.
#  2010/03/08 v2.14 (Manuel P\'egouri\'e-Gonnard)
#    * In restricted mode, forbid --gscmd (all platforms) and call GS with full
#    path relative to self location (Windows).
#  2010/02/26 v2.13 (Karl Berry)
#    * New release.
#  2010/02/23       (Manuel P\'egouri\'e-Gonnard)
#    * Use kpsewhich for filename validation in restricted mode, both input and
#    output. Requires kpathsea 5.1.0 (TL2010), rejects the name with earlier
#    versions of kpsewhich.
#    * Call external programs with full path on win32 in order to avoid obvious
#    attacks with rogue versions of these programs in the current directory.
#  2009/11/27 v2.12 (Karl Berry)
#    * Make --filter work again
#  2009/11/25       (Manuel P\'egouri\'e-Gonnard)
#    * Better extension detection, suggested by A. Cherepanov.
#  2009/10/18       (Manuel P\'egouri\'e-Gonnard)
#    * Better argument validation (Alexander Cherepanov).
#    * Use list form of pipe open() (resp. system()) to prevent injection.
#    Since Perl's fork() emulation doesn't work on Windows with Perl 5.8.8 from
#    TeX Live 2009, use a temporary file instead of a pipe on Windows.
#  2009/10/14       (Manuel P\'egouri\'e-Gonnard)
#    * Added restricted mode.
#  2009/09/27 v2.11 (Karl Berry)
#    * Fixed two bugs in the (atend) handling code (Martin von Gagern)
#    * Improved handling of CR line ending (Martin von Gagern)
#    * More error checking
#    * --version option
#    * Create source repository in TeX Live
#  2009/07/17 v2.9.11gw
#    * Added -dSAFER to default gs options
#       TL2009 wants to use a restricted variant of -shell-escape,
#       allowing epstopdf to run. However without -dSAFER Ghostscript
#       allows writing to files (other than given in -sOutputFile)
#       and running commands (through Ghostscript pipe's language feature).
#  2009/05/09 v2.9.10gw
#    * Changed cygwin name for ghostscript to gs
#  2008/08/26 v2.9.9gw
#    * Switch to embed fonts (default=yes) (J.P. Chretien)
#    * turned no AutoRotatePages into an option (D. Kreil) (default = None)
#    * Added resolution switch (D. Kreil)
#    * Added BSD-style license
#  2007/07/18 v2.9.8gw
#  2007/05/18 v.2.9.7gw (Gerben Wierda)
#    * Merged both supplied 2.9.6 versions
#  2007/05/15 v2.9.6tp (Theo Papadopoulo)
#    * Simplified the (atend) support
#  2007/01/24 v2.9.6sw (Staszek Wawrykiewicz)
#    * patched to work also on Windows
#  2005/10/06 v2.9.5gw (Gerben Wierda)
#    * Fixed a horrendous bug in the (atend) handling code
#  2005/10/06 v2.9.4gw (Gerben Wierda)
#    * This has become the official version for now
#  2005/10/01 v2.9.3draft (Gerben Wierda)
#    * Quote OutFilename
#  2005/09/29 v2.9.2draft (Gerben Wierda)
#    * Quote OutFilename
#  2004/03/17 v2.9.1draft (Gerben Wierda)
#    * No autorotate page
#  2003/04/22 v2.9draft (Gerben Wierda)
#    * Fixed bug where with cr-eol files everything up to the first %!
#    * in the first 2048 bytes was gobbled (double ugh!)
#  2002/02/21 v2.8draft (Gerben Wierda)
#    * Fixed bug where last line of buffer was not copied out (ugh!)
#  2002/02/18 v2.8draft (Gerben Wierda)
#    * Handle different eol styles transparantly
#    * Applied fix from Peder Axensten for Freehand bug
#  2001/03/05 v2.7 (Heiko Oberdiek)
#    * Newline before grestore for the case that there is no
#      whitespace at the end of the eps file.
#  2000/11/05 v2.6 (Heiko Oberdiek)
#    * %%HiresBoundingBox corrected to %%HiResBoundingBox
#  1999/05/06 v2.5 (Heiko Oberdiek)
#    * New options: --hires, --exact, --filter, --help.
#    * Many cosmetics: title, usage, ...
#    * New code for debug, warning, error
#    * Detecting of cygwin perl
#    * Scanning for %%{Hires,Exact,}BoundingBox.
#    * Scanning only the header in order not to get a wrong
#      BoundingBox of an included file.
#    * (atend) supported.
#    * uses strict; (earlier error detecting).
#    * changed first comment from '%!PS' to '%!';
#    * corrected (atend) pattern: '\s*\(atend\)'
#    * using of $bbxpat in all BoundingBox cases,
#      correct the first white space to '...Box:\s*$bb...'
#    * corrected first line (one line instead of two before 'if 0;';
#
# Thomas Esser, Sept. 1998: change initial lines to find
# perl along $PATH rather than guessing a fixed location. The above
# construction should work with most shells.
#
# Originally by Sebastian Rahtz, for Elsevier Science
# with extra tricks from Hans Hagen's texutil and many more.

### emacs-page
### program identification
my $program = "epstopdf";
my $ident = '($Id: epstopdf.pl 67585 2023-07-08 21:10:52Z karl $)' . " $ver";
my $copyright = <<END_COPYRIGHT ;
Copyright 2009-2023 Karl Berry et al.
Copyright 2002-2009 Gerben Wierda et al.
Copyright 1998-2001 Sebastian Rahtz et al.
License RBSD: Revised BSD <http://www.xfree86.org/3.3.6/COPYRIGHT2.html#5>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.
END_COPYRIGHT
my $title = "$program $ident\n";

my $on_windows = $^O =~ /^(MSWin|msys$)/;
my $on_windows_or_cygwin = $on_windows || $^O eq "cygwin";

### ghostscript command name
my $GS = "gs";
if ($on_windows) {
  $GS = "gswin32c";
  if ($ENV{"PROCESSOR_ARCHITECTURE"} eq "AMD64"
      || $ENV{"PROCESSOR_ARCHITEW6432"} eq "AMD64") {
    # prefer gswin64c.exe if on search path.
    my @pdirs = split(/;/, $ENV{"PATH"});
    foreach $d (@pdirs) {
      $d = substr ($d, 1, -1) if (substr ($d,1,1) eq '"');
      if (-f $d . "/gswin64c.exe") {
        $GS = "gswin64c";
        last;
      }
    }
  }
}

### restricted mode
my $restricted = 0;
$restricted = 1 if $0 =~ /repstopdf/;

### default values
my $default_device = 'pdfwrite';

### options
$::opt_autorotate = "None";
$::opt_compress = 1;
$::opt_debug = 0;
$::opt_device = "";
$::opt_embed = 1;
$::opt_exact = 0;
$::opt_filter = 0;
$::opt_gray = 0;
$::opt_gs = 1;
$::opt_gscmd = "";
@::opt_gsopt = ();
$::opt_help = 0;
$::opt_hires = 0;
$::opt_outfile = "";
$::opt_pdfsettings = "";
$::opt_res = '';
$::opt_restricted = 0;
$::opt_safer = 1;
$::opt_quiet = 1;
$::opt_version = 0;

sub gsopts { push (@::opt_gsopt, split (' ', $_[1])); }

# known-safe Ghostscript options and values.
my %optcheck = qw<
  AlignToPixels 0|1
  AntiAliasColorImages true|false
  AntiAliasGrayImages true|false
  AntiAliasMonoImages true|false
  ASCII85EncodePages true|false
  AutoFilterColorImages true|false
  AutoFilterGrayImages true|false
  AutoPositionEPSFiles true|false
  AutoRotatePages /(None|All|PageByPage)
  BATCH true
  Binding /(Left|Right)
  CannotEmbedFontPolicy /(OK|Warning|Error)
  ColorConversionStrategy /(LeaveColorUnchanged|UseDeviceIndependentColor|UseDeviceIndependendColorForImages|sRGB|CMYK)
  ColorImageDepth -1|1|2|4|8
  ColorImageDownsampleThreshold 10(.0*)?|\d(.\d*)|\.\d+
  ColorImageDownsampleType /(Average|Bicubic|Subsample|None)
  ColorImageFilter /(DCTEncode|FlateEncode|JPXEncode)
  ColorImageResolution \d+
  COLORSCREEN true|0|false
  CompatibilityLevel 1\.[0-7]
  CompressFonts true|false
  CompressPages true|false
  ConvertCMYKImagesToRGB true|false
  ConvertImagesToIndexed true|false
  DefaultRenderingIntent /(Default|Perceptual|Saturation|AbsoluteColorimetric|RelativeColorimetric)
  DetectBlends true|false
  DetectDuplicateImages true|false
  DITHERPPI \d+
  DOINTERPOLATE true
  DoThumbnails true|false
  DownsampleColorImages true|false
  DownsampleGrayImages true|false
  DownsampleMonoImages true|false
  EmbedAllFonts true|false
  EmitDSCWarnings true|false
  EncodeColorImages true|false
  EncodeGrayImages true|false
  EncodeMonoImages true|false
  EndPage -?\d+
  FIXEDRESOLUTION true
  GraphicsAlphaBits 1|2|4
  GrayImageDepth -1|1|2|4|8
  GrayImageDownsampleThreshold \d+\.?\d*|\.\d+
  GrayImageDownsampleType /(Average|Bicubic)
  GrayImageFilter /(DCTEncode|FlateEncode|JPXEncode)
  GrayImageResolution \d+
  GridFitTT 0|1|2|3
  HaveTransparency true|false
  HaveTrueTypes true|false
  ImageMemory \d+
  LockDistillerParams true|false
  LZWEncodePages true|false
  MaxSubsetPct 100|[1-9][0-9]?
  MaxClipPathSize \d+
  MaxInlineImageSize \d+
  MaxShadingBitmapSize \d+
  MonoImageDepth -1|1|2|4|8
  MonoImageDownsampleThreshold  \d+\.?\d*|\.\d+
  MonoImageDownsampleType /(Average|Bicubic|Subsample|None)
  MonoImageFilter /(CCITTFaxEncode|FlateEncode|RunLengthEncode)
  MonoImageResolution \d+
  NOCIE true
  NODISPLAY true
  NOEPS true
  NOINTERPOLATE true
  NOPSICC true
  NOSUBSTDEVICECOLORS true|false
  NOTRANSPARENCY true
  OPM 0|1
  Optimize true|false
  ParseDSCComments true|false
  ParseDSCCommentsForDocInfo true|false
  PreserveCopyPage true|false
  PreserveEPSInfo true|false
  PreserveHalftoneInfo true|false
  PreserveOPIComments true|false
  PreserveOverprintSettings true|false
  StartPage -?\d+
  PatternImagemask true|false
  PDFSETTINGS /(screen|ebook|printer|prepress|default)
  PDFX true|false
  PreserveDeviceN true|false
  PreserveSeparation true|false
  QUIET true
  SHORTERRORS true
  SubsetFonts true|false
  TextAlphaBits 1|2|4
  TransferFunctionInfo /(Preserve|Remove|Apply)
  UCRandBGInfo /(Preserve|Remove)
  UseCIEColor true|false
  UseFlateCompression true|false
  UsePrologue true|false
>;
# In any case not suitable for restricted:
# -dDOPS

### usage
my @bool = ("false", "true");
my $resmsg = $::opt_res ? $::opt_res : "[use gs default]";
my $rotmsg = $::opt_autorotate ? $::opt_autorotate : "[use gs default]";

my $usage = <<"END_OF_USAGE";
${title}Usage: $program [OPTION]... [EPSFILE [PDFFILE.pdf]]

Convert an EPS file to PDF (or other formats), by default using Ghostscript.

By default, the output name is the input name with any extension
replaced by ".pdf".  An output name ending with .pdf can also be given
as a second argument on the command line, or the --outfile (-o) option
can be used with any name.

The output is PDF 1.5 by default; use --gsopt=-dCompatibilityLevel=1.7
(for example) to change this.

The resulting output is guaranteed to start at the 0,0 coordinate, and
sets a page size exactly corresponding to the BoundingBox.  Thus, the
result does not need any cropping, and the PDF MediaBox is correct.

If the bounding box in the input is incorrect, of course there will
be resulting problems.

Options:
  --help             display this help and exit
  --version          display version information and exit

  -o, --outfile=FILE write result to FILE   (default based on input name)
  --restricted       use restricted mode    (default: $bool[$restricted])

  --(no)debug        output debugging info  (default: $bool[$::opt_debug])
  --(no)exact        scan ExactBoundingBox  (default: $bool[$::opt_exact])
  --(no)filter       read standard input    (default: $bool[$::opt_filter])
  --(no)gs           run ghostscript        (default: $bool[$::opt_gs])
  --(no)hires        scan HiResBoundingBox  (default: $bool[$::opt_hires])

Options for Ghostscript:
  --gscmd=VAL        pipe output to VAL     (default: $GS)
  --gsopt=VAL        single option for gs   (see below)
  --gsopts=VAL       options for gs         (see below)
  --autorotate=VAL   set AutoRotatePages    (default: $rotmsg)
                       recognized VAL choices: None, All, PageByPage;
                       for EPS files, PageByPage is equivalent to All.
  --(no)compress     use compression        (default: $bool[$::opt_compress])
  --device=DEV       use -sDEVICE=DEV       (default: $default_device)
  --(no)embed        embed fonts            (default: $bool[$::opt_embed])
  --(no)gray         grayscale output       (default: $bool[$::opt_gray])
  --pdfsettings=VAL  use -dPDFSETTINGS=/VAL (default is prepress if --embed,
                       else empty); recognized VAL choices:
                       screen, ebook, printer, prepress, default.
  --(no)quiet        use -q (-dQUIET)       (default: $bool[$::opt_quiet])
  --res=DPI|DPIxDPI  set image resolution   (default: $resmsg)
                       ignored if option --debug is set.
  --(no)safer        use -d(NO)SAFER        (default: $bool[$::opt_safer])

Examples all equivalently converting test.eps to test.pdf:
  \$ $program test.eps
  \$ $program test.eps test.pdf
  \$ cat test.eps | $program --filter >test.pdf
  \$ cat test.eps | $program -f -o=test.pdf

Example for using HiResBoundingBox instead of BoundingBox:
  \$ $program --hires test.eps

Example for producing epstopdf's attempt at corrected PostScript:
  \$ $program --nogs test.ps >testcorr.ps

In all cases, you can add --debug (-d) to see more about what epstopdf
is doing.

More about the options for Ghostscript:
  Additional options to be used with gs can be specified
    with either or both of the two cumulative options --gsopts and --gsopt.
  --gsopts takes a single string of options, which is split at whitespace
    and each resulting word then added to the gs command line individually.
  --gsopt adds its argument as a single option to the gs command line.
    It can be used multiple times to specify options separately,
    and is necessary if an option or its value contains whitespace.
  In restricted mode, options are limited to those with names and values
    known to be safe.  Some options taking booleans, integers or fixed
    names are allowed, those taking general strings are not.

All options to epstopdf may start with either - or --, and may be
unambiguously abbreviated.  It is best to use the full option name in
scripts to avoid possible collisions with new options in the future.

When reporting bugs, please include an input file and all command line
options so the problem can be reproduced.

Report bugs to: tex-k\@tug.org
epstopdf home page: <http://tug.org/epstopdf/>
END_OF_USAGE

### process options
use Getopt::Long;
GetOptions (
  "autorotate=s",         # \ref{val_autorotate}
  "compress!",
  "debug!",
  "device=s",
  "embed!",
  "exact!",
  "gray!",
  "filter!",
  "gs!",
  "gscmd=s",              # \ref{val_gscmd}
  "gsopt=s@",             # \ref{val_gsopt}
  "gsopts=s" => \&gsopts, # \ref{val_gsopts}
  "help|h",
  "hires!",
  "outfile|output|o=s",   # \ref{openout_any}
  "pdfsettings=s",
  "quiet",
  "res=s",
  "restricted",
  "safer!",
  "version",
) or die "Try $0 --help for more information\n";

### disable --quiet if option --debug is given
$::opt_quiet = 0 if $::opt_debug;

### restricted option
$restricted = 1 if $::opt_restricted;

### help functions
sub debug      { print STDERR "* @_\n" if $::opt_debug; }
sub warning    { print STDERR "==> Warning: @_\n"; }
sub error      { die "$title!!! Error: @_\n"; }
sub errorUsage { die "$program: Error: @_ (try --help for more information)\n"; }
sub warnerr    { $restricted ? error(@_) : warning(@_); }

### debug messages
debug "on_windows=$on_windows, on_windows_or_cygwin=$on_windows_or_cygwin";
debug "Restricted mode activated" if $restricted;

### safer external commands for Windows in restricted mode
my $kpsewhich = 'kpsewhich';
if ($restricted && $on_windows) {
  use File::Basename;
  my $mydirname = dirname $0;
  # $mydirname is the location of the Perl script
  $kpsewhich = "$mydirname/../../../bin/windows/$kpsewhich";
  debug "Restricted Windows kpsewhich: $kpsewhich";
  $GS = "$mydirname/../../../tlpkg/tlgs/bin/$GS";
  debug "Restricted Windows gs: $GS";
}
debug "kpsewhich command: $kpsewhich";

### check that PROG is in PATH and executable, abort if not. It'd be
# better to actually try running the program, but then we'd have to
# either replicate Perl's logic for finding the command interpreter
# (trivial on Unix, complicated on Windows), or do a fork/exec and close
# the file descriptors ourselves, which seems too painful. Nor do we
# want to load/assume File::Which. Instead we'll look along PATH
# ourselves, which is good enough in practice for us, since the only
# goal here is to give a better error message if the program isn't
# available.
sub check_prog_exists {
  my ($prog) = @_;
  my @w_ext = ("exe", "com", "bat");
  debug " Checking if $prog is in PATH";

  # absolute unix
  if (! $on_windows_or_cygwin && $prog =~ m,^((\.(\.)?)?/),) {
    return 1 if -x $prog; # absolute or explicitly relative
    error "Required program $prog not found, given explicit directory";

  # absolute windows: optional drive letter, then . or .., then \ or /.
  } elsif ($on_windows_or_cygwin
           && $prog =~ m,^(([a-zA-Z]:)?(\.(\.)?)?[/\\]),) {
    return 1 if -x $prog;
    for my $ext (@w_ext) {
      return 1 if (-x "$prog.$ext");
    }
    error "Required program $prog not found, given explicit Windows directory";
  }

  # not absolute, check path
  for my $dir (split ($on_windows_or_cygwin ? ";" : ":", $ENV{"PATH"})) {
    $dir = "." if $dir eq ""; # empty path element
    debug " Checking dir $dir";
    if (-x "$dir/$prog") {
      return 1;
    } elsif ($on_windows_or_cygwin) {
      for my $ext (@w_ext) {
        return 1 if (-x "$dir/$prog.$ext");
      }
    }
  }

  # if made it through the whole loop, not found, so quit.
  error "Required program $prog not found in PATH ($ENV{PATH})";
}
check_prog_exists ($kpsewhich);

### check if a name is "safe" according to kpse's open(in|out)_any
# return true if name is ok, false otherwise
sub safe_name {
  my ($mode, $name) = @_;
  my $option = "";
  $option = '-safe-in-name'  if $mode eq 'in';
  $option = '-safe-out-name' if $mode eq 'out';
  error "Unknown check mode in safe_name(): $mode" unless $option;
  my @args = ($kpsewhich, '-progname', 'repstopdf', $option, $name);
  debug "Checking safe_name with: @args";
  my $bad = system { $args[0] } @args;
  return ! $bad;
}

### help, version options.
if ($::opt_help) {
  print $usage;
  exit 0;
}

if ($::opt_version) {
  print $title;
  print $copyright;
  exit 0;
}

### get input filename (\ref{openin_any} for validation)
my $InputFilename = "";
if ($::opt_filter) {
  @ARGV == 0 or
    errorUsage "Input file cannot be used with filter option";
  debug "Filtering: will read standard input";
} else {
  # not filtering.
  @ARGV > 0 or errorUsage "Input filename missing";
  # allow infile outfile.pdf.
  if (@ARGV == 2) {
    if ($::opt_outfile) {
      errorUsage ("Multiple output specifications: second arg=$ARGV[1],"
                  . " --outfile=$::opt_outfile");
    }
    if ($ARGV[1] !~ m/\.pdf$/i) {
      errorUsage "Output file argument requires .pdf extension: $ARGV[1]";
    }
    # seems we can use it.
    $::opt_outfile = $ARGV[1];
    debug "Output filename from argv:", $::opt_outfile;
  }
  @ARGV > 2 and errorUsage "Too many arguments: @ARGV";
  
  $InputFilename = $ARGV[0];
  debug "Input filename:", $InputFilename;
}

### emacs-page
### building the gs invocation.

### option gscmd
if ($::opt_gscmd) {
  if ($restricted) { # \label{val_gscmd}
    error "Option forbidden in restricted mode: --gscmd";
  } else {
    debug "Switching from $GS to $::opt_gscmd";
    $GS = $::opt_gscmd;
  }
}
debug "GS command: $GS";
check_prog_exists ($GS);

### option (no)safer
my $gs_opt_safer = "-dSAFER";
if (! $::opt_safer) {
  if ($restricted) {
    error "Option forbidden in restricted mode: --nosafer";
  } else {
    debug "Switching from $gs_opt_safer to -dNOSAFER";
    $gs_opt_safer = "--nosafer";
  }
}

### start building GS command line for the pipe
my @GS = ($GS);
push @GS, '-q' if $::opt_quiet;
push @GS, $gs_opt_safer;
push @GS, '-dNOPAUSE';
push @GS, '-dBATCH';
push @GS, '-dCompatibilityLevel=1.5';

### option device
if ($::opt_device) {
  if ($restricted) {
    error "Option forbidden in restricted mode: --device";
  } else {
    debug "Switching from $default_device to $::opt_device";
  }
} else {
  $::opt_device = $default_device;
}

push @GS, "-sDEVICE=$::opt_device";

### option outfile
my $OutputFilename = $::opt_outfile;
if (! $OutputFilename) {
  if ($::opt_gs) {
    if ($::opt_filter) {
      debug "Filtering: will write standard output";
      $OutputFilename = "-";
    } else {
      # Ghostscript, no filter: replace input extension with .pdf.
      $OutputFilename = $InputFilename;
      my $ds = $on_windows_or_cygwin ? '\\/' : '/';
      $OutputFilename =~ s/\.[^\.$ds]*$//;
      $OutputFilename .= ".pdf";
    }
  } else {
    debug "No Ghostscript: will write standard output";
    $OutputFilename = "-";
  }
}
#
# gs -sOutputFilename opens pipes itself if the string starts with
# %pipe or |. Disallow this in restricted mode.
if ($restricted && $OutputFilename =~ /^(%pipe|\|)/) {
    error "Output to pipe forbidden in restricted mode: $OutputFilename";
}
$OutputFilename =~ s/%/%%/g; # stop gs interpretation of % characters
debug "Output filename:", $OutputFilename;
push @GS, "-sOutputFile=$OutputFilename";

### options compress, embed, res, autorotate
$::opt_pdfsettings = 'prepress' if $::opt_embed and not $::opt_pdfsettings;
if ($::opt_pdfsettings
    && $::opt_pdfsettings
       !~ s/^\/?(screen|ebook|printer|prepress|default)$/$1/) {
  warnerr "Invalid value for --pdfsettings: $::opt_pdfsettings";
  $::opt_pdfsettings = '';
}
# use # instead of = to avoid mingw path munging.
push (@GS, "-dPDFSETTINGS#/$::opt_pdfsettings") if $::opt_pdfsettings;

push @GS, qw[
  -dMaxSubsetPct=100
  -dSubsetFonts=true
  -dEmbedAllFonts=true
] if $::opt_embed;

push @GS, '-dUseFlateCompression=false' unless $::opt_compress;

push @GS, qw(-sColorConversionStrategy=Gray -dProcessColorModel=/DeviceGray)
  if $::opt_gray;

if ($::opt_res and
    not $::opt_res =~ /^(\d+(x\d+)?)$/) {
  warnerr "Invalid resolution: $opt_res";
  $::opt_res = '';
}
push @GS, "-r$::opt_res" if $::opt_res;
$resmsg = $::opt_res ? $::opt_res : "[use gs default]";

# \label{val_autorotate}
if ($::opt_autorotate and
    not $::opt_autorotate =~ /^(None|All|PageByPage)$/) {
  warnerr "Invalid value for --autorotate: $::opt_autorotate' "
        . "(use 'All', 'None' or 'PageByPage'";
  $::opt_autorotate = '';
}
# use # instead of = to avoid mingw path munging.
push (@GS, "-dAutoRotatePages#/$::opt_autorotate") if $::opt_autorotate;
$rotmsg = $::opt_autorotate ? $::opt_autorotate : "[use gs default]";

foreach my $gsopt (@::opt_gsopt) {
  if ($restricted) {
    my $ok = 0;
    if ($gsopt =~ /^-[dD]([A-Za-z0-9]+)(=(.*))?$/) {
      my $name = $1;
      my $value = $3;
      $value = 'true' if not defined $value;
      if ($optcheck{$name} and $value =~ /^($optcheck{$name})$/) {
        $ok = 1;
      }
      else {
        warnerr "Option forbidden in restricted mode: --gsopt $gsopt";
        $gsopt = '';
      }
    }
    if (not $ok) {
      warnerr "Option forbidden in restricted mode: --gsopt $gsopt";
      $gsopt = '';
    }
  }
  push @GS, $gsopt if $gsopt;
}

### option BoundingBox types
my $BBName = "%%BoundingBox:";
!($::opt_hires and $::opt_exact) or
  error "Options --hires and --exact cannot be used together";
$BBName = "%%HiResBoundingBox:" if $::opt_hires;
$BBName = "%%ExactBoundingBox:" if $::opt_exact;
debug "BoundingBox comment:", $BBName;

### validate input file name in restricted mode \label{openin_any}
if ($restricted and not $::opt_filter
    and not safe_name('in', $InputFilename)) {
  error "Input filename '$InputFilename' not allowed in restricted mode.";
}

### validate output file name in restricted mode \label{openout_any}
if ($restricted and not safe_name('out', $OutputFilename)) {
  error "Output filename '$OutputFilename' not allowed in restricted mode.";
}

### option gs
if ($::opt_gs) {
  debug "Ghostscript command:", $GS;
  debug "Compression:", ($::opt_compress) ? "on" : "off";
  debug "Embedding:", ($::opt_embed) ? "on" : "off";
  debug "Grayscale:", ($::opt_gray) ? "on" : "off";
  debug "PDFSettings:", $::opt_pdfsettings;
  debug "Resolution:", $resmsg;
  debug "Rotation:", $rotmsg;
}

### emacs-page
### open input file
if ($::opt_filter) {
  open(IN, '<-') || error("Cannot open stdin: $!");
} else {
  open(IN, '<', $InputFilename) || error("Cannot open $InputFilename: $!");
}
binmode IN;

### open output file
my $outname;  # used in error message at end
my $tmp_filename; # temporary file for windows
my $OUT; # filehandle for output (GS pipe or temporary file)
use File::Temp 'tempfile';
if ($::opt_gs) {
  if (! $on_windows_or_cygwin) { # list piped open works
    push @GS, qw(- -c quit);
    debug "Ghostscript pipe: @GS";
    open($OUT, '|-', @GS)
      or error "Cannot open Ghostscript for piped input: @GS";
  } else { # use a temporary file on Windows/Cygwin.
    ($OUT, $tmp_filename) = tempfile(UNLINK => 1);
    debug "Using temporary file '$tmp_filename'";
  }
  $outname = $GS;
}
else {
  debug "No Ghostscript: opening $OutputFilename";
  if ($OutputFilename eq "-") {
    $OUT = *STDOUT;
    $outname = "-";
  } else {
    open($OUT, '>', $OutputFilename)
    || error ("Cannot write \"$OutputFilename\": $!");
    $outname = $OutputFilename;
  }
}
binmode $OUT;

# reading a cr-eol file on a lf-eol system makes it impossible to parse
# the header and besides it will read the intire file into yor line by line
# scalar. this is also true the other way around.

### emacs-page
### scan a block, try to determine eol style

my $buf;
my $buflen;
my @bufarray;
my $inputpos;
my $maxpos = -1;

# We assume 2048 is big enough.
my $EOLSCANBUFSIZE = 2048;

# PJL
my $UEL = "\x1B%-12345X";
my $PJL = '@PJL[^\r\n]*\r?\n';

$buflen = read(IN, $buf, $EOLSCANBUFSIZE);
if ($buflen > 0) {
  my $crlfpos;
  my $lfpos;
  my $crpos;

  $inputpos = 0;

  # TN 5002 "Encapsulated PostScript File Format Specification"
  # specifies a DOS EPS binary file format for including a
  # device-specific screen preview.
  #
  # DOS EPS Binary File Header (30 Bytes):
  # * Bytes 0-3:   0xC5D0D3C6
  # * Bytes 4-7:   Offset of PostScript section
  # * Bytes 8-11:  Length of PostScript section
  # * ...
  # * Bytes 28-29: XOR checksum of bytes 0-27 or 0xFFFF
  if ($buflen > 30 and $buf =~ /^\xC5\xD0\xD3\xC6/) {
    debug "DOS EPS binary file header found";
    my $header = substr($buf, 0, 30);
    my ($offset_ps, $length_ps, $checksum) = unpack("x[V]VVx[V4]n", $header);
    debug "  PS offset: $offset_ps";
    debug "  PS length: $length_ps";
    $maxpos = $offset_ps + $length_ps;
    # validate checksum
    if ($checksum == 0xFFFF) {
      debug "  No checksum";
    }
    else {
      debug "  Checksum: $checksum";
      my $cs = 0;
      map { $cs ^= $_ } unpack('n14', $header);
      if ($cs != $checksum) {
        warning "Wrong checksum of DOS EPS binary header";
      }
    }
    # go to the start of the PostScript section and refill buffer
    if ($::opt_filter) {
      if ($offset_ps <= $buflen) {
        $buf = substr($buf, $offset_ps);
        $buflen = $buflen - $offset_ps;
        $inputpos = $offset_ps;
        my $len = read(IN, $buf, $offset_ps, $buflen);
        $buflen += $len;
      }
      else {
        $inputpos = $buflen;
        $buflen = 0;
        my $skip = $offset_ps - $inputpos;
        while ($skip > 0) {
          $buflen = read(IN, $buf,
              $skip > $EOLSCANBUFSIZE ? $EOLSCANBUFSIZE : $skip);
          $buflen > 0 or error "Unexpected end of input stream";
          $inputpos += $buflen;
          $skip = $offset_ps - $inputpos;
        }
        $buflen = read(IN, $buf, $EOLSCANBUFSIZE);
        $buflen > 0 or error "Unexpected end of input stream";
      }
    }
    else {
      seek(IN, $offset_ps, 0) || error "Cannot seek to PostScript section";
      $inputpos = $offset_ps;
      $buflen = read(IN, $buf, $EOLSCANBUFSIZE);
      $buflen > 0 or error "Reading PostScript section failed";
    }
  }
  elsif ($buf =~ s/^($UEL($PJL)+)//) {
      $inputpos = length($1);
      debug "PJL commands removed at start of file: $inputpos bytes";
  }
  else {
    # remove binary junk before header
    # if there is no header, we assume the file starts with ascii style and
    # we look for a eol style anyway, to prevent possible loading of the
    # entire file
    if ($buf =~ /%!/) {
      # throw away binary junk before %!
      $buf =~ s/(.*?)%!/%!/o;
      $inputpos = length($1);
      debug "Binary junk at start of file: $inputpos byte(s)";
    }
  }

  $lfpos = index($buf, "\n");
  $crpos = index($buf, "\r");
  $crlfpos = index($buf, "\r\n");

  if ($crpos > 0 and ($lfpos == -1 or $lfpos > $crpos+1)) {
    # The first eol was a cr and it was not immediately followed by a lf
    $/ = "\r";
    debug "The first eol character was a CR ($crpos) and not immediately followed by a LF ($lfpos)";
  }

  # Now we have set the correct eol-character. Get one more line and add
  # it to our buffer. This will make the buffer contain an entire line
  # at the end. Then split the buffer in an array. We will draw lines from
  # that array until it is empty, then move again back to <IN>
  $buf .= <IN> unless eof(IN);
  $buflen = length($buf);

  # In case of DOS EPS binary files respect end of PostScript section.
  if ($maxpos> 0 and $inputpos + $buflen > $maxpos) {
    $buflen = $maxpos - $inputpos;
    $buflen > 0 or error "Internal error";
    $buf = substr($buf, 0, $buflen);
  }

  # Some extra magic is needed here: if we set $/ to \r, Perl's re engine
  # still thinks eol is \n in regular expressions (not very nice) so we
  # cannot split on ^, but have to split on a look-behind for \r.
  if ($/ eq "\r") {
    @bufarray = split(/(?<=\r)/ms, $buf); # split after \r
  }
  else {
    @bufarray = split(/^/ms, $buf);
  }
}

### getline
sub getline
{
  if ($#bufarray >= 0) {
    $_ = shift(@bufarray);
  }
  elsif ($maxpos > 0 and $inputpos >= $maxpos) {
    $_ = undef;
  }
  else {
    $_ = <IN>;
    if ($maxpos > 0) {
      my $skip = $maxpos - $inputpos - length($_);
      if ($skip < 0) {
        $_ = substr($_, 0, $skip);
      }
    }
  }
  $inputpos += length($_) if defined $_;
  return defined($_);
}

### scan first line
my $header = 0;
getline();
if (/%!/) {
  # throw away binary junk before %!
  s/(.*)%!/%!/o;
}
$header = 1 if /^%/;
debug "Scanning header for BoundingBox";
print $OUT $_;

### variables and pattern for BoundingBox search
my $bbxpatt = '[0-9eE\.\-]';
               # protect backslashes: "\\" gets '\'
my $BBValues = "\\s*($bbxpatt+)\\s+($bbxpatt+)\\s+($bbxpatt+)\\s+($bbxpatt+)";
my $BBCorrected = 0;

sub CorrectBoundingBox
{
  my ($llx, $lly, $urx, $ury) = @_;
  debug "Old BoundingBox:", $llx, $lly, $urx, $ury;
  my ($width, $height) = ($urx - $llx, $ury - $lly);
  my ($xoffset, $yoffset) = (-$llx, -$lly);
  debug "New BoundingBox: 0 0", $width, $height;
  debug "Offset:", $xoffset, $yoffset;

  print $OUT "%%BoundingBox: 0 0 $width $height$/";
  print $OUT "<< /PageSize [$width $height] >> setpagedevice$/";
  print $OUT "gsave $xoffset $yoffset translate$/";
}

### emacs-page
### scan header
if ($header) {
  HEADER: while (getline()) {
    ### Fix for freehand bug ### by Peder Axensten
    next HEADER if(!/\S/);

    ### end of header
    if (!/^%/ or /^%%EndComments/) {
      print $OUT $_;
      last;
    }

    ### BoundingBox with values
    if (/^$BBName$BBValues/o) {
      CorrectBoundingBox $1, $2, $3, $4;
      $BBCorrected = 1;
      last;
    }

    ### BoundingBox with (atend)
    if (/^$BBName\s*\(atend\)/) {
      debug $BBName, "(atend)";
      if ($::opt_filter) {
        warning "Cannot look for BoundingBox in the trailer",
                "with option --filter";
        last;
      }
      my $pos = $inputpos;
      debug "Current file position:", $pos;

      # looking for %%BoundingBox
      while (getline()) {
        # skip over included documents
        my $nestDepth = 0;
        $nestDepth++ if /^%%BeginDocument/;
        $nestDepth-- if /^%%EndDocument/;
        if ($nestDepth == 0 && /^$BBName$BBValues/o) {
          CorrectBoundingBox $1, $2, $3, $4;
          $BBCorrected = 1;
          last;
        }
      }

      # go back
      seek(IN, $pos, 0) or error "Cannot go back to line \"$BBName (atend)\"";
      $inputpos = $pos;
      @bufarray = ();
      last;
    }

    # print header line
    print $OUT $_;
  }
}

### print rest of file
while (getline()) {
  print $OUT $_;
}

### emacs-page
### close files
close(IN);
print $OUT "$/grestore$/" if $BBCorrected;
close($OUT);

### actually run GS if we were writing to a temporary file
if (defined $tmp_filename) {
  push @GS, $tmp_filename;
  push @GS, qw(-c quit);
  debug "Ghostscript command: @GS";
  system @GS;
}

# if ghostscript exited badly, we should too.
if ($? & 127) {
  error(sprintf "Writing to $outname failed, signal %d\n", $? & 127);
} elsif ($? != 0) {
  error(sprintf "Writing to $outname failed, error code %d\n", $? >> 8);
}

warning "BoundingBox not found" unless $BBCorrected;
debug "Done.";

# vim: ts=8 sw=2 expandtab:
