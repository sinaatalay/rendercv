#!/usr/bin/env perl
use warnings;

## Copyright John Collins 1998-2023
##           (username jcc8 at node psu.edu)
##      (and thanks to David Coppit (username david at node coppit.org) 
##           for suggestions) 
## Copyright Evan McLean
##         (modifications up to version 2)
## Copyright 1992 by David J. Musliner and The University of Michigan.
##         (original version)
##
##    This program is free software; you can redistribute it and/or modify
##    it under the terms of the GNU General Public License as published by
##    the Free Software Foundation; either version 2 of the License, or
##    (at your option) any later version.
##
##    This program is distributed in the hope that it will be useful,
##    but WITHOUT ANY WARRANTY; without even the implied warranty of
##    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
##    GNU General Public License for more details.
##
##    You should have received a copy of the GNU General Public License
##    along with this program; if not, write to the Free Software
##    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307
##
## See file CHANGES for list of main version-to-version changes.
##
## Modified by Evan McLean (no longer available for support)
## Original script (RCS version 2.3) called "go" written by David J. Musliner
##
##-----------------------------------------------------------------------

## Explicit exit codes: 
##             10 = bad command line arguments
##             11 = file specified on command line not found
##                  or other file not found
##             12 = failure in some part of making files
##             13 = error in initialization file
##             20 = probable bug
##             or retcode from called program.

$my_name = 'latexmk';
$My_name = 'Latexmk';
$version_num = '4.80';
$version_details = "$My_name, John Collins, 4 Apr. 2023. Version $version_num";

use Config;
use File::Basename;
use File::Copy;
use File::Spec::Functions qw( catfile file_name_is_absolute rel2abs );

# If possible, use better glob, which does not use space as item separator.
# It's either File::Glob::bsd_glob or File::Glob::glob
# The first does not exist in old versions of Perl, while the second
# is deprecated in more recent versions and will be removed
$have_bsd_glob = 0;
use File::Glob;
if ( eval{ File::Glob->import('bsd_glob'); 1; } ) {
    # Success in importing bsd_glob
    $have_bsd_glob = 1;
}
elsif ( eval{ File::Glob->import('glob'); 1; } ) {
    warn( "$My_name: I could not import File::Glob:bsd_glob, probably because your\n",
             "  Perl is too old.  I have arranged to use the deprecated File::Glob:glob\n",
             "  instead.\n",
             "  WARNING: It may malfunction on clean up operation on filenames containing\n",
             "           spaces.\n" );
    $have_bsd_glob = 0;
}
else {
    die "Could not import 'File::Glob:bsd_glob' or 'File::Glob:glob'\n";
}

use File::Path 2.08 qw( make_path );
use FileHandle;
use File::Find;
use List::Util qw( max );
use Cwd;
use Cwd "abs_path"; 
use Cwd "chdir";    # Ensure $ENV{PWD}  tracks cwd.
use Digest::MD5;

# **WARNING**: Don't import time; that overrides core function time(), and messes up
#  
use Time::HiRes;

#################################################
#
#  Unicode set up to be used in latexmk
#
use Encode qw( decode encode );
use Unicode::Normalize;
use utf8;  # For UTF-8 strings in **this** script
use feature 'unicode_strings';
use feature 'say';


# Coding:
# 1. $CS_system = CS for file names in file system calls, and for CL.
#    It's to be UTF-8 on all except: MSWin when the MSWin system code page is
#    not 65001.
# 2. Internally use CS_system generally, and especially for filenames.
#    Then standard file system calls, print to terminal don't need encoding,
#    and things in rc files work unchanged from earlier versions of latexmk,
#    when I didn't treat non-ASCII coding issues explicitly.
# 3. But must set console codepage to system codepage on MSWin, otherwise
#    display on terminal is garbled.
# 4. fdb_latexmk: write and read UTF-8, convert to and from CS_system for
#    strings.
# 5. .fls, .log, .aux are all UTF-8, so if necessary convert to CS_system.
# 6. However, with TeXLive on MSWin with system CP not equal to 65001,
#    the PWD is in CS_system on all but most recent *latex (that's a bug).
#    Convert file/path names to CS_system.
# 7. Don't support non-UTF-8 on *nix.
# 8. Do NOT do any conversion to a NF for Unicode: File systems and OS calls
#    to access them are **either** normalization-sensitive (I think, e.g.,
#    ext4) and we need to preserve normalization, **or** they are
#    normalization-insensitve (e.g., hfs+, apfs), in which case we can access
#    a file with any normalization for its name.
#
# N.B.  I18N::Langinfo often doesn't give useful enough information.



# My default CSs: UTF-8
our $CS_system;
$CS_system = 'UTF-8';
# Quick short cut for tests of whether conversions needed:
our $no_CP_conversions = 1;

# Win32 specific CP **numbers**.  Initialize to 65001 (utf-8), and change
# by results of system calls.
# Corresponding CS name: Prefix by 'CP'.
# Preserve intial values for console/terminal to allow restore on exit.
our ($CP_Win_system, $CP_init_Win_console_in, $CP_init_Win_console_out);
$CP_Win_system = $CP_init_Win_console_in = $CP_init_Win_console_out = '65001';

# Whether to revert Windows console CPs on exit:
our $Win_revert_settings = 0;

if ($^O eq "MSWin32") {
    eval {  require Win32;
            $CP_Win_system = Win32::GetACP();
            $CS_system = 'CP' . $CP_Win_system;
            $CP_init_Win_console_in = Win32::GetConsoleCP();
            $CP_init_Win_console_out = Win32::GetConsoleOutputCP();
            if ( Win32::SetConsoleOutputCP($CP_Win_system)
                 && Win32::SetConsoleCP($CP_Win_system) ) {
            } else {
                warn "Cannot set Windows Console Output CP to $CP_Win_system.\n";
            }
    };
    if ($@) { warn "Trouble finding and setting code pages used by Windows:\n",
              "  $@",
              "  I'LL CONTINUE WITH UTF-8.\n"; 
    }
    else {
        $Win_revert_settings =
              ($CP_init_Win_console_in ne $CP_Win_system)
              || ($CP_init_Win_console_out ne $CP_Win_system);
        print
        "Initial Win CP for (console input, console output, system): ",
        "(CP$CP_init_Win_console_in, CP$CP_init_Win_console_out, CP$CP_Win_system)\n",
        "I changed them all to CP$CP_Win_system\n";
    }
}
$no_CP_conversions = ($CS_system eq 'UTF-8') || ($CS_system eq 'CP65001');

# Ensure that on ctrl/C interruption, etc, Windows console CPs are restored:
use sigtrap qw(die untrapped normal-signals);
END {
    if ($Win_revert_settings ) {
        warn "Reverting Windows console CPs to ",
             "(in,out) = ($CP_init_Win_console_in,$CP_init_Win_console_out)\n";
        Win32::SetConsoleCP($CP_init_Win_console_in);
        Win32::SetConsoleOutputCP($CP_init_Win_console_out);
    }
}

########################################################

#************************************************************
#************************************************************
#            Unicode manipuation and normalization
# Notes about Perl strings:
# 1. Strings have a flag utf8.
#    a. If the utf8 flag is on, the string is to be interpreted as a sequence
#       of code points.
#       When "use utf8;" is used, a string containing non-ASCII characters
#       has the utf8 flag set.
#       If 'no bytes;' is in effect, the ordinal value for each item in the
#       string is the Unicode code point value.
#    b. If the utf8 flag is off for a string, the string is a sequence of
#       bytes, to be interpreted according to whatever CS the user happens
#       to choose to use.
#    c. The utf8 flag is NOT to be interpreted as saying that the string is
#       encoded as UTF-8, even though under the hood that may be the case.
#    d. Indeed, setting 'use bytes;' appears to expose the internal
#       byte-level representation of a string with the utf8 flag set, and
#       that appears to be UTF-8.
# 2. The utf8 flag is quite confusing in its meaning.
# 3. When encode is applied to a string whose utf8 flag is on, the result
#    is a string with the utf8 flag off, and the result consists of a sequence
#    of bytes in the chosen encoding scheme, which may be chosen as UTF-8.
# 4. Strings received from the command line have the utf8 flag off and are
#    encoded in whatever CS the OS/terminal is using.
# 5. When a string is supplied to print (or c), by default:
#    a. If the utf8 flag is off or if 'use bytes;' is in effect, then the
#       string is sent as a sequence of bytes.  They are UTF-8 coded if
#       the utf8 flag is on and 'use bytes;' is in effect.
#    b. If the utf8 flag is on and if 'no bytes;' is in effect, then mostly
#       garbage results for non-ASCII characters; the string must first be
#       encoded as a byte string, in the CS suitable for the OS.
#    c. Correct results are obtained when the utf8 flag is on and 'no bytes'
#       is used when the binmode for the file handle is set suitably.
# 6. Generally OS calls and interactions with the OS need encoded byte strings.
# 7. Even more generally, interaction with the external world, including file
#    contents is in terms of byte strings, with some CS chosen by default, by
#    the user, or the OS.  Unix-like OSs: Default is UTF-8, but as much by
#    convention as by a requirement of the OS.

#-------------------------------------

sub utf8_to_mine {
    # Given string encoded in UTF-8, return encoded string in my current CS.
    # Don't use Encode::from_to, which does in-place conversion.
    if  ($no_CP_conversions) { return $_[0]; }
    else { return  encode( $CS_system, decode('UTF-8', $_[0])); }  
}

#-------------------------------------

sub utf8_to_mine_errors {
    # Given string encoded in UTF-8, return encoded string in my current CS.
    # Don't use Encode::from_to, which does in-place conversion.
    # Assume coding of input string is correctly UTF-8, but
    # check for correct encoding in CS_system.
    # Error message is returned in $@.  No error => $@ is null string.
    # (Same style as eval!)
    $@ = '';
    if  ($no_CP_conversions) { return $_[0]; }
    else {
        my $result = '';
        eval {
            $result = encode( $CS_system,
                              decode('UTF-8', $_[0]),
                              Encode::FB_CROAK | Encode::LEAVE_SRC
                      );
        };
        return $result;
    }  
}

#-------------------------------------

sub config_to_mine {
    # Ensure that configuration strings about files and directories are
    # encoded in system CS.
    # Configuration strings set in an rc file SHOULD either be:
    #   a. ASCII only, with Perl's utf8 flag off.
    #   b. Containing non-ASCII characters, with utf8 flag on.
    #      These need to be converted to encoded strings in system CS (and
    #      hence with utf8 flag off).
    # Configuration variables set from the command line, e.g., from an
    # -outdir=... option, are already in the system CS, because that is
    # how strings are passed on  the command line.
    # So we just need to do a conversion for strings with utf8 flag on:
    foreach ( $out_dir, $aux_dir, @default_files, @default_excluded_files ) {
        if (utf8::is_utf8($_)) { $_ = encode( $CS_system, $_ ); }
    }
} #END config_to_mine

#************************************************************

sub mine_to_utf8 {
    # Given string encoded in my current CS, return utf-8 encoded string.
    # Don't use Encode::from_to, which does in-place conversion.
    if  ($no_CP_conversions) { return $_[0]; }
    else { return  encode( 'UTF-8', decode($CS_system, $_[0])); }
}

#-------------------------------------

sub is_valid_utf8 {
   eval { decode( 'UTF-8', $_[0], (Encode::FB_CROAK | Encode::LEAVE_SRC ) ); };
   if ($@) { return 0; }
   else { return 1; }
}

#-------------------------------------

sub fprint8 {
    # Usage: fprint8( handle, data array)
    # Write to file converting from my CS to UTF-8
    my $fh = shift;
    print $fh mine_to_utf8( join( '', @_ ) );
}

#-------------------------------------

################################################################




################################################################
################################################################
#============ Deal with how I'm invoked: name and CL args:

# Name that I'm invoked with indicates default behavior (latexmk
# v. pdflatexmk, etc):
(our $invoked_name) = fileparseA($0);

our $invoked_kind = $invoked_name;
print "$My_name: Invoked as '$invoked_name'\n"
    if ($invoked_name ne 'latexmk');

# Map my invoked name to pointer to array of default values for $dvi_mode,
# $postscript_mode, $pdf_mode, $xdv_mode.  These are used if after processing
# rc files and CL args, no values are set for any of these variables.
# Thus default compilation for latexmk is by latex,
#                          for pdflatexmk is by pdflatex, etc.
%compilation_defaults =
    ( 'latexmk' => [1,0,0,0],
      'lualatexmk' => [0,0,4,0],
      'pdflatexmk' => [0,0,1,0],
      'xelatexmk' => [0,0,5,0],
    );
# If name isn't in canonical set, change it to a good default:
unless (exists $compilation_defaults{$invoked_name}) { $invoked_name = 'latexmk'; }

#==================

################################################################
################################################################
# The following variables are assigned once and then used in symbolic 
#     references, so we need to avoid warnings 'name used only once':
use vars qw( $dvi_update_command $ps_update_command $pdf_update_command
             $aux_dir_requested $out_dir_requested );

# Translation of signal names to numbers and vv:
%signo = ();
@signame = ();
if ( defined $Config{sig_name} ) {
   $i = 0;
   foreach $name (split('\s+', $Config{sig_name})) {
      $signo{$name} = $i;
      $signame[$i] = $name;
      $i++;
   }
}
else {
   warn "Something wrong with the perl configuration: No signals?\n";
}


# Line length in log file that indicates wrapping.  
# This number EXCLUDES line-end characters, and is one-based.
# It is the parameter max_print_line in the TeX program.  (tex.web)
$log_wrap = 79;

#########################################################################
## Default parsing and file-handling settings

## Array of reg-exps for patterns in log-file for file-not-found
## Each item is the string in a regexp, without the enclosing slashes.
## First parenthesized part is the filename.
## Note the need to quote slashes and single right quotes to make them 
## appear in the regexp.
## Add items by push, e.g.,
##     push @file_not_found, '^No data file found `([^\\\']*)\\\'';
## will give match to line starting "No data file found `filename'"
@file_not_found = (
    '^No file\\s*(.*)\\.$',
    '^No file\\s*(.+)\s*$',
    '^\\! LaTeX Error: File `([^\\\']*)\\\' not found\\.',
    '^\\! I can\\\'t find file `([^\\\']*)\\\'\\.',
    '.*?:\\d*: LaTeX Error: File `([^\\\']*)\\\' not found\\.',
    '^LaTeX Warning: File `([^\\\']*)\\\' not found',
    '^Package .* [fF]ile `([^\\\']*)\\\' not found',
    '^Package .* No file `([^\\\']*)\\\'',
    'Error: pdflatex \(file ([^\)]*)\): cannot find image file',
    ': File (.*) not found:\s*$',
    '! Unable to load picture or PDF file \\\'([^\\\']+)\\\'.',
    );

# Array of reg-exps for patterns in log file for certain latex warnings
# that we will call bad warnings.  They are not treated as errors by
# *latex, but depending on the $bad_warning_is_error setting 
# we will treat as if they were actual errors.
@bad_warnings = (
    # Remember: \\ in perl inside single quotes gives a '\', so we need
    # '\\\\' to get '\\' in the regexp.
    '^\(\\\\end occurred when .* was incomplete\)',
    '^\(\\\\end occurred inside .*\)',
);
$bad_warning_is_error = 0; 

# Characters that we won't allow in the name of a TeX file.
# Notes: Some are disallowed by TeX itself.
#        '\' results in TeX macro expansion
#        '$' results in possible variable substitution by kpsewhich called from tex.
#        '"' gets special treatment.
#        See subroutine test_fix_texnames and its call for their use.
$illegal_in_texname = "\x00\t\f\n\r\$%\\~\x7F";

# Whether to normalize aux_dir and out_dir where possible.
# This is important when these directories aren't subdirectories of the cwd,
# and TeXLive's makeindex and/or bibtex are used.
$normalize_names = 2;  # Strongest kind.

## Hash mapping file extension (w/o period, e.g., 'eps') to a single regexp,
#  whose matching by a line in a file with that extension indicates that the 
#  line is to be ignored in the calculation of the hash number (md5 checksum)
#  for the file.  Typically used for ignoring datestamps in testing whether 
#  a file has changed.
#  Add items e.g., by
#     $hash_calc_ignore_pattern{'eps'} = '^%%CreationDate: ';
#  This makes the hash calculation for an eps file ignore lines starting with
#  '%%CreationDate: '
#  ?? Note that a file will be considered changed if 
#       (a) its size changes
#    or (b) its hash changes
#  So it is useful to ignore lines in the hash calculation only if they
#  are of a fixed size (as with a date/time stamp).
%hash_calc_ignore_pattern =();

# Specification of templates for extra rules.
# See subroutine rdb_initialize_rules for examples of rule templates, and
# how they get used to construct rules.
# (Documentation obviously needs to be improved!)
%extra_rule_spec = ();


#??????? !!!!!!!!! If @aux_hooks and @latex_file_hooks are still needed,
# should I incorporate them into the general hook hash???
#
# Hooks for customized extra processing on aux files.  The following
# variable is an array of references to functions.  Each function is
# invoked in turn when a line of an aux file is processed (if none
# of the built-in actions have been done).  On entry to the function,
# the following variables are set:
#    $_ = current line of aux file
#    $rule = name of rule during the invocation of which, the aux file
#            was supposed to have been generated.
our @aux_hooks = ();
#
# Hooks for customized processing on lists of source and missing files.
# The following variable is an array of references to functions.  Each 
# function is invoked in turn after a run of latex (or pdflatex etc) and
# latexmk has analyzed the .log and .fls files for dependency information.
# On entry to each called function, the following variables are set:
#    $rule = name of *latex rule
#    %dependents: maps source files and possible source files to a status.
#                 See begining of sub parse_log for possible values.
our @latex_file_hooks = ();
#
# Single hash for various stacks of hooks:
our %hooks = ();
for ( 'before_xlatex', 'after_xlatex', 'after_xlatex_analysis' ) {
    $hooks{$_} = [];
}
$hooks{aux_hooks} = \@aux_hooks;
$hooks{latex_file_hooks} = \@latex_file_hooks;

#########################################################################
## Default document processing programs, and related settings,
## These are mostly the same on all systems.
## Most of these variables represents the external command needed to 
## perform a certain action.  Some represent switches.


## Which TeX distribution is being used
## E.g., "MiKTeX 2.9", "TeX Live 2018"
## "" means not determined. Obtain from first line of .log file.
$tex_distribution = '';

# List of known *latex rules:
%possible_primaries = ( 'dvilualatex'  => 'primary', 'latex'  => 'primary',
                        'lualatex'  => 'primary', 'pdflatex'  => 'primary',
                        'xelatex'  => 'primary' );
&std_tex_cmds;

# Possible code to execute by *latex before inputting source file.
# Not used by default.
$pre_tex_code = '';

## Default switches:
$latex_default_switches = '';
$pdflatex_default_switches = '';
$dvilualatex_default_switches = '';
$lualatex_default_switches = '';
    # Note that xelatex is used to give xdv file, not pdf file, hence 
    # we need the -no-pdf option.
$xelatex_default_switches = '-no-pdf';

## Switch(es) to make them silent:
$latex_silent_switch  = '-interaction=batchmode';
$pdflatex_silent_switch  = '-interaction=batchmode';
$dvilualatex_silent_switch  = '-interaction=batchmode';
$lualatex_silent_switch  = '-interaction=batchmode';
$xelatex_silent_switch  = '-interaction=batchmode';

# Whether to emulate -aux-directory, so we can use it on system(s) (TeXLive)
# that don't support it:
$emulate_aux = 1;
# Whether emulate_aux had to be switched on during a run:
$emulate_aux_switched = 0;

#--------------------
# Specification of extensions/files that need special treatment,
# e.g., in cleanup or in analyzing missing dependent files. 
#
# %input_extensions maps primary_rule_name to pointer to hash of file extensions
#    used for extensionless files specified in the source file by constructs
#    like \input{file}  \includegraphics{file}
%input_extensions = ();
set_input_ext( 'latex', 'tex', 'eps' );
set_input_ext( 'pdflatex', 'tex', 'jpg', 'pdf', 'png' );
$input_extensions{lualatex} = $input_extensions{pdflatex};
$input_extensions{xelatex} = $input_extensions{pdflatex};
# Save these values as standards to be used when switching output,
# i.e., when actual primary rule differs from standard.
%standard_input_extensions = %input_extensions;

# Possible extensions for main output file of *latex:
%allowed_output_ext = ( ".dvi" => 1, ".xdv" => 1, ".pdf" => 1 );

# Variables relevant to specifying cleanup.
# The first set of variables is intended to be user configurable.
#
# The @generated_exts array contains list of extensions (without
# period) for files that are generated by rules run by latexmk.
#
# Instead of an extension, an item in the array can be a string containing
# the placeholder %R for the root of the filenames.  This is used for more
# general patterns.  Such a pattern may contain wildcards (bsd_glob
# definitions).
#
# By default, it excludes "final output files" that
# are normally only deleted on a full cleanup, not a small cleanup.
# These files get two kinds of special treatment:
#     1.  In clean up, where depending on the kind of clean up, some
#         or all of these generated files are deleted.
#         (Note that special treatment is given to aux files.)
#     2.  In analyzing the results of a run of *LaTeX, to
#         determine if another run is needed.  With an error free run,
#         a rerun should be provoked by a change in any source file,
#         whether a user file or a generated file.  But with a run
#         that ends in an error, only a change in a user file during
#         the run (which might correct the error) should provoke a
#         rerun, but a change in a generated file should not.
#         Also at the start of a round of processing, only user-file
#         changes are relevant.
# Special cases for extensions aux and bbl
#   aux files beyond the standard one are found by a special analysis
#   bbl files get special treatment because their deletion is conditional
#       and because of the possibility of extra bibtex/biber rules with
#       non-standard basename.
@generated_exts = ( 'aux', 'bcf', 'fls', 'idx', 'ind', 'lof', 'lot', 
                    'out', 'toc',
                    'blg', 'ilg', 'log',
                    'xdv'
                  );
                  # N.B. 'out' is generated by hyperref package
$clean_ext = "";        # For backward compatibility: Space separated 
                        # extensions to be added to @generated_exts after
                        # startup (and rc file reading).
# Extensions of files to be deleted by -C, but aren't normally included
# in the small clean up by -c.  Analogous to @generated_exts and $clean_ext,
# except that pattern rules (with %R) aren't applied.
@final_output_exts = ( 'dvi', 'dviF', 'ps', 'psF', 'pdf',
                        'synctex', 'synctex.gz' );
$clean_full_ext = "";


# Set of extra specific files to be deleted in small cleanup. These are
#  ones that get generated under some kinds of error conditions.  All cases:
#   Relative to current directory, and relative to aux and out directories.
@std_small_cleanup_files = ( 'texput.log', "texput.aux", "missfont.log" );

#-------------------------

# Information about options to latex and pdflatex that latexmk will simply
#   pass through to *latex
# Option without arg. maps to itself.
# Option with arg. maps the option part to the full specification
#  e.g., -kpathsea-debug => -kpathsea-debug=NUMBER
%allowed_latex_options = ();
%allowed_latex_options_with_arg = ();
foreach ( 
  #####
  # TeXLive options
    "-draftmode              switch on draft mode (generates no output PDF)",
    "-enc                    enable encTeX extensions such as \\mubyte",
    "-etex                   enable e-TeX extensions",
    "-file-line-error        enable file:line:error style messages",
    "-no-file-line-error     disable file:line:error style messages",
    "-fmt=FMTNAME            use FMTNAME instead of program name or a %& line",
    "-halt-on-error          stop processing at the first error",
    "-interaction=STRING     set interaction mode (STRING=batchmode/nonstopmode/\n".
    "                           scrollmode/errorstopmode)",
    "-ipc                    send DVI output to a socket as well as the usual\n".
    "                           output file",
    "-ipc-start              as -ipc, and also start the server at the other end",
    "-kpathsea-debug=NUMBER  set path searching debugging flags according to\n".
    "                           the bits of NUMBER",
    "-mktex=FMT              enable mktexFMT generation (FMT=tex/tfm/pk)",
    "-no-mktex=FMT           disable mktexFMT generation (FMT=tex/tfm/pk)",
    "-mltex                  enable MLTeX extensions such as \charsubdef",
    "-output-comment=STRING  use STRING for DVI file comment instead of date\n".
    "                           (no effect for PDF)",
    "-parse-first-line       enable parsing of first line of input file",
    "-no-parse-first-line    disable parsing of first line of input file",
    "-progname=STRING        set program (and fmt) name to STRING",
    "-shell-escape           enable \\write18{SHELL COMMAND}",
    "-no-shell-escape        disable \\write18{SHELL COMMAND}",
    "-shell-restricted       enable restricted \\write18",
    "-src-specials           insert source specials into the DVI file",
    "-src-specials=WHERE     insert source specials in certain places of\n".
    "                           the DVI file. WHERE is a comma-separated value\n".
    "                           list: cr display hbox math par parend vbox",
    "-synctex=NUMBER         generate SyncTeX data for previewers if nonzero",
    "-translate-file=TCXNAME use the TCX file TCXNAME",
    "-8bit                   make all characters printable by default",

  #####
  # MikTeX options not in TeXLive
    "-alias=app              pretend to be app",
    "-buf-size=n             maximum number of characters simultaneously present\n".
    "                           in current lines",
    "-c-style-errors         C-style error messages",
    "-disable-installer      disable automatic installation of missing packages",
    "-disable-pipes          disable input (output) from (to) child processes",
    "-disable-write18        disable the \\write18{command} construct",
    "-dont-parse-first-line  disable checking whether the first line of the main\n".
    "                           input file starts with %&",
    "-enable-enctex          enable encTeX extensions such as \\mubyte",
    "-enable-installer       enable automatic installation of missing packages",
    "-enable-mltex           enable MLTeX extensions such as \charsubdef",
    "-enable-pipes           enable input (output) from (to) child processes",
    "-enable-write18         fully enable the \\write18{command} construct",
    "-error-line=n           set the width of context lines on terminal error\n".
    "                           messages",
    "-extra-mem-bot=n        set the extra size (in memory words) for large data\n".
    "                           structures",
    "-extra-mem-top=n        set the extra size (in memory words) for chars,\n".
    "                           tokens, et al",
    "-font-max=n             set the maximum internal font number",
    "-font-mem-size=n        set the size, in TeX memory words, of the font memory",
    "-half-error-line=n      set the width of first lines of contexts in terminal\n".
    "                           error messages",
    "-hash-extra=n           set the extra space for the hash table of control\n".
    "                           sequences",
    "-job-time=file          set the time-stamp of all output files equal to\n".
    "                           file's time-stamp",
    "-main-memory=n          change the total size (in memory words) of the main\n".
    "                           memory array",
    "-max-in-open=n          set the maximum number of input files and error\n".
    "                           insertions that can be going on simultaneously",
    "-max-print-line=n       set the width of longest text lines output",
    "-max-strings=n          set the maximum number of strings",
    "-nest-size=n            set the maximum number of semantic levels\n".
    "                           simultaneously active",
    "-no-c-style-errors      standard error messages",
    "-param-size=n           set the the maximum number of simultaneous macro\n".
    "                           parameters",
    "-pool-size=n            set the maximum number of characters in strings",
    "-record-package-usages=file record all package usages and write them into\n".
    "                           file",
    "-restrict-write18       partially enable the \\write18{command} construct",
    "-save-size=n            set the the amount of space for saving values\n".
    "                           outside of current group",
    "-stack-size=n           set the maximum number of simultaneous input sources",
    "-string-vacancies=n     set the minimum number of characters that should be\n".
    "                           available for the user's control sequences and font\n".
    "                           names",
    "-tcx=name               process the TCX table name",
    "-time-statistics        show processing time statistics",
    "-trace                  enable trace messages",
    "-trace=tracestreams     enable trace messages. The tracestreams argument is\n".
    "                           a comma-separated list of trace stream names",
    "-trie-size=n            set the amount of space for hyphenation patterns",
    "-undump=name            use name as the name of the format to be used,\n".
    "                           instead of the name by which the program was\n".
    "                           called or a %& line.",

  #####
    # Options passed to *latex that have special processing by latexmk,
    #   so they are commented out here.
    #-jobname=STRING         set the job name to STRING
    #-aux-directory=dir    Set the directory dir to which auxiliary files are written
    #-output-directory=DIR   use existing DIR as the directory to write files in
    # "-output-format=FORMAT   use FORMAT for job output; FORMAT is `dvi\" or `pdf\"",
    #-quiet
    #-recorder               enable filename recorder
    #
    # Options with different processing by latexmk than *latex
    #-help
    #-version
    #
    # Options NOT used by latexmk
    #-includedirectory=dir    prefix dir to the search path
    #-initialize              become the INI variant of the compiler
    #-ini                     be pdfinitex, for dumping formats; this is implicitly
    #                          true if the program name is `pdfinitex'
) {
    if ( /^([^\s=]+)=/ ) {
        $allowed_latex_options_with_arg{$1} = $_;
    }
    elsif ( /^([^\s=]+)\s/ ) {
        $allowed_latex_options{$1} = $_;
    }
}

# Arrays of options that will be added to latex and pdflatex.
# These need to be stored until after the command line parsing is finished,
#  in case the values of $latex and/or $pdflatex change after an option
#  is added.
@extra_dvilualatex_options = ();
@extra_latex_options = ();
@extra_pdflatex_options = ();
@extra_lualatex_options = ();
@extra_xelatex_options = ();


## Command to invoke biber & bibtex
$biber  = 'biber %O %S';
$bibtex  = 'bibtex %O %S';
# Switch(es) to make biber & bibtex silent:
$biber_silent_switch  = '--onlylog';
$bibtex_silent_switch  = '-terse';
$bibtex_use = 1;   # Whether to actually run bibtex to update bbl files.
                   # This variable is also used in deciding whether to
                   #   delete bbl files in clean up operations.
                   # 0:  Never run bibtex.
                   #     Do NOT delete bbl files on clean up.
                   # 1:  Run bibtex only if the bibfiles exists 
                   #     according to kpsewhich, and the bbl files
                   #     appear to be out-of-date.
                   #     Do NOT delete bbl files on clean up.
                   # 1.5:  Run bibtex only if the bibfiles exists 
                   #     according to kpsewhich, and the bbl files
                   #     appear to be out-of-date.
                   #     Only delete bbl files on clean up if bibfiles exist.
                   # 2:  Run bibtex when the bbl files are out-of-date
                   #     Delete bbl files on clean up.
                   #
                   # In any event bibtex is only run if the log file
                   #   indicates that the document uses bbl files.
$bibtex_fudge = 1; #  Whether or not to cd to aux dir when running bibtex.
                   #  If the cd is not done, and bibtex is passed a
                   #  filename with a path component, then it can easily
                   #  happen that (a) bibtex refuses to write bbl and blg
                   #  files to the aux directory, for security reasons,
                   #  and/or (b) bibtex in pre-2019 versions fails to find
                   #  some input file(s).  But in some other cases, the cd
                   #  method fails. 

## Command to invoke makeindex
$makeindex  = 'makeindex %O -o %D %S';
# Switch(es) to make makeinex silent:
$makeindex_silent_switch  = '-q';
$makeindex_fudge = 1; # Whether or not to cd to aux dir when running makeindex.
                      # Set to 1 to avoid security-related prohibition on
                      # makeindex writing to aux_dir when it is not specified
                      # as a subdirectory of cwd.

## Command to convert dvi file to pdf file directly.
#   Use option -dALLOWPSTRANSPARENCY so that it works with documents
#   using pstricks etc:
$dvipdf  = 'dvipdf -dALLOWPSTRANSPARENCY %O %S %D';
# N.B. Standard dvipdf runs dvips and gs with their silent switch, so for
#      standard dvipdf $dvipdf_silent_switch is unneeded, but innocuous. 
#      But dvipdfmx can be used instead, and it has a silent switch (-q).
#      So implementing $dvipdf_silent_switch is useful.
$dvipdf_silent_switch  = '-q';

## Command to convert dvi file to ps file:
$dvips  = 'dvips %O -o %D %S';
## Command to convert dvi file to ps file in landscape format:
$dvips_landscape = 'dvips -tlandscape %O -o %D %S';
# Switch(es) to get dvips to make ps file suitable for conversion to good pdf:
#    (If this is not used, ps file and hence pdf file contains bitmap fonts
#       (type 3), which look horrible under acroread.  An appropriate switch
#       ensures type 1 fonts are generated.  You can put this switch in the 
#       dvips command if you prefer.)
$dvips_pdf_switch = '-P pdf';
# Switch(es) to make dvips silent:
$dvips_silent_switch  = '-q';

## Command to convert ps file to pdf file.
#   Use option -dALLOWPSTRANSPARENCY so that it works with documents
#   using pstricks etc:
$ps2pdf = 'ps2pdf -dALLOWPSTRANSPARENCY %O %S %D';

## Command to convert xdv file to pdf file
$xdvipdfmx  = 'xdvipdfmx -E -o %D %O %S';
$xdvipdfmx_silent_switch  = '-q';


## Command to search for tex-related files
$kpsewhich = 'kpsewhich %S';

## Command to run make:
$make = 'make';

##Printing:
$print_type = 'auto';   # When printing, print the postscript file.
                        # Possible values: 'dvi', 'ps', 'pdf', 'auto', 'none'
                        # 'auto' ==> set print type according to the printable
                        # file(s) being made: priority 'ps', 'pdf', 'dvi'

# Viewers.  These are system dependent, so default to none:
$pdf_previewer = $ps_previewer  = $ps_previewer_landscape  = $dvi_previewer  = $dvi_previewer_landscape = "NONE";

$dvi_update_signal = undef;
$ps_update_signal = undef;
$pdf_update_signal = undef;

$dvi_update_command = undef;
$ps_update_command = undef;
$pdf_update_command = undef;

$allow_subdir_creation = 1;

$new_viewer_always = 0;     # If 1, always open a new viewer in pvc mode.
                            # If 0, only open a new viewer if no previous
                            #     viewer for the same file is detected.

# Commands for use in pvc mode for compiling, success, warnings, and failure;
# they default to empty, i.e., not to use:
$compiling_cmd = $success_cmd = $warning_cmd = $failure_cmd = "";

# Commands for printing are highly system dependent, so default to NONE:
$lpr = 'NONE $lpr variable is not configured to allow printing of ps files';
$lpr_dvi = 'NONE $lpr_dvi variable is not configured to allow printing of dvi files';
$lpr_pdf = 'NONE $lpr_pdf variable is not configured to allow printing of pdf files';


# The $pscmd below holds a **system-dependent** command to list running
# processes.  It is used to find the process ID of the viewer looking at
# the current output file.  The output of the command must include the
# process number and the command line of the processes, since the
# relevant process is identified by the name of file to be viewed.
# Its use is not essential.
$pscmd =  'NONE $pscmd variable is not configured to detect running processes';
$pid_position = -1;     # offset of PID in output of pscmd.  
                        # Negative means I cannot use ps


$quote_filenames = 1;       # Quote filenames in external commands

$del_dir = '';        # Directory into which cleaned up files are to be put.
                      # If $del_dir is '', just delete the files in a clean up.

@rc_system_files = ();

#########################################################################

################################################################
##  Special variables for system-dependent fudges, etc.
#    ???????? !!!!!!!!!!
$log_file_binary = 0;   # Whether to treat log file as binary
                        # Normally not, since the log file SHOULD be pure text.
                        # But Miktex 2.7 sometimes puts binary characters
                        #    in it.  (Typically in construct \OML ... after
                        #    overfull box with mathmode.)
                        # Sometimes there is ctrl/Z, which is not only non-text, 
                        #    but is end-of-file marker for MS-Win in text mode.  

$MSWin_fudge_break = 1; # Give special treatment to ctrl/C and ctrl/break
                        #    in -pvc mode under MSWin
                        # Under MSWin32 (at least with perl 5.8 and WinXP)
                        #   when latexmk is running another program, and the 
                        #   user gives ctrl/C or ctrl/break, to stop the 
                        #   daughter program, not only does it reach
                        #   the daughter, but also latexmk/perl, so
                        #   latexmk is stopped also.  In -pvc mode,
                        #   this is not normally desired.  So when the
                        #   $MSWin_fudge_break variable is set,
                        #   latexmk arranges to ignore ctrl/C and
                        #   ctrl/break during processing of files;
                        #   only the daughter programs receive them.
                        # This fudge is not applied in other
                        #   situations, since then having latexmk also
                        #   stopping because of the ctrl/C or
                        #   ctrl/break signal is desirable.
                        # The fudge is not needed under UNIX (at least
                        #   with Perl 5.005 on Solaris 8).  Only the
                        #   daughter programs receive the signal.  In
                        #   fact the inverse would be useful: In
                        #   normal processing, as opposed to -pvc, if
                        #   force mode (-f) is set, a ctrl/C is
                        #   received by a daughter program does not
                        #   also stop latexmk.  Under tcsh, we get
                        #   back to a command prompt, while latexmk
                        #   keeps running in the background!

## Substitute backslashes in file and directory names for
##  MSWin command line
$MSWin_back_slash = 0;

## Separator of elements in search_path.  Default is unix value
$search_path_separator = ':'; 


# Directory for temporary files.  Default to current directory.
$tmpdir = ".";


# Latexmk does tests on whether a particular generated file, e.g., log or
# fls, has been generated on a current run of a rule, especially *latex, or
# is leftover from previous runs.  This is done by finding whether or not
# the modification time of the file is at least as recent as the system
# time at the start of the run.  A file with a modification time
# significantly less than the time at the start of the run is presumably
# left over from a previous run and not generated in the currrent run.  (An
# allowance is made in this comparison for the effects of granularity of
# file-system times.  Such granularity can make a file time a second or two
# earlier than the system time at which the file was last modified.)
#
# But generated files may be on a file system hosted by a server computer
# that is different than the computer running latexmk.  There may there may
# be an offset between the time on the two computers; this can make it
# appear that the generated files were made before the run. Most of the
# time, this problem does not arise, since (a) typical usage of latexmk is
# with a local file system, and (b) current-day computers and operating
# systems have their time synchronized accurately with a time server.
#
# But when latexmk sees symptoms of an excessive offset, it measures the
# offset between the filesystem time and the system time. This involves
# writing a temporary file, getting its modification time, and deleting
# it.   The following variables are used for this purpose.

#
our $filetime_offset_measured = 0;       # Measurement not yet done.
our $filetime_offset = 0;                # Filetime relative to system time.
our $filetime_offset_report_threshold = 10; # Threshold beyond which filetime offsets
                                     # are reported; large offsets indicate
                                     # incorrect system time on at least one system.
# The following variable gives the threshold for detection of left-over
# file. It allows for (a) different granularity between system time and
# filesystem time, (b) for some mismatch between file and system time.
# Note that the making or not making of a file is controlled by the
# state of the document being compiled and by latexmk's configuration.
# So a file that is left over from a previous run and not overwritten
# on the current run will have a file time at least many seconds less
# than the current time, corresponding to the time scale for a human
# run-edit-run cycle.
#
# Note that the making or not making of a file is controlled by the
# state of the document being compiled and by latexmk's configuration.
# So a file that is left over from a previous run and not overwritten
# on the current run will have a file time at least many seconds less
# than the current time, corresponding to the time scale for a human
# run-edit-run cycle.  So one does NOT have to tune this variable
# precisely. 
#
# Concerning granularity of file system 
# FAT file system: 2 sec granularity. Others 1 sec or less.
# Perl CORE's mtime in stat: 1 sec.
# Perl CORE's time(): 1 sec.  Time::HiRes::time(): Much less than 1 sec.

our $filetime_causality_threshold = 5;


################################################################
################################################################


# System-dependent overrides:
# Currently, the cases I have tests for are: MSWin32, cygwin, linux and 
#   darwin, msys, with the main complications being for MSWin32 and cygwin.
# Further special treatment may also be useful for MSYS (for which $^O reports 
#   "msys").  This is another *nix-emulation/system for MSWindows.  At
#   present it is treated as unix-like, but the environment variables
#   are those of Windows.  (The test for USERNAME as well as USER was
#   to make latexmk work under MSYS's perl.)
#
if ( $^O eq "MSWin32" ) {
    # Pure MSWindows configuration

    ## Configuration parameters:

    ## Use first existing case for $tmpdir:
    $tmpdir = $ENV{TMPDIR} || $ENV{TEMP} || '.';
    $log_file_binary = 1;   # Protect against ctrl/Z in log file from
                            # Miktex 2.7.

    ## List of possibilities for the system-wide initialization file.  
    ## The first one found (if any) is used.
    @rc_system_files = ( "C:/latexmk/LatexMk", "C:/latexmk/latexmkrc" );

    $search_path_separator = ';';  # Separator of elements in search_path

    # For a pdf-file, "start x.pdf" starts the pdf viewer associated with
    #   pdf files, so no program name is needed:
    $pdf_previewer = 'start %O %S';
    $ps_previewer  = 'start %O %S';
    $ps_previewer_landscape  = $ps_previewer;
    $dvi_previewer  = 'start %O %S';
    $dvi_previewer_landscape = "$dvi_previewer";
    # Viewer update methods: 
    #    0 => auto update: viewer watches file (e.g., gv)
    #    1 => manual update: user must do something: e.g., click on window.
    #         (e.g., ghostview, MSWIN previewers, acroread under UNIX)
    #    2 => send signal.  Number of signal in $dvi_update_signal,
    #                         $ps_update_signal, $pdf_update_signal
    #    3 => viewer can't update, because it locks the file and the file 
    #         cannot be updated.  (acroread under MSWIN)
    #    4 => run a command to force the update.  The commands are 
    #         specified by the variables $dvi_update_command, 
    #         $ps_update_command, $pdf_update_command
    $dvi_update_method = 1;
    $ps_update_method = 1;
    $pdf_update_method = 3; # acroread locks the pdf file
}
elsif ( $^O eq "cygwin" ) {
    # The problem is a mixed MSWin32 and UNIX environment. 
    # Perl decides the OS is cygwin in two situations:
    # 1. When latexmk is run from a cygwin shell under a cygwin
    #    environment.  Perl behaves in a UNIX way.  This is OK, since
    #    the user is presumably expecting UNIXy behavior.  
    # 2. When CYGWIN exectuables are in the path, but latexmk is run
    #    from a native NT shell.  Presumably the user is expecting NT
    #    behavior. But perl behaves more UNIXy.  This causes some
    #    clashes. 
    # The issues to handle are:
    # 1.  Perl sees both MSWin32 and cygwin filenames.  This is 
    #     normally only an advantage.
    # 2.  Perl uses a UNIX shell in the system command
    #     This is a nasty problem: under native NT, there is a
    #     start command that knows about NT file associations, so that
    #     we can do, e.g., (under native NT) system("start file.pdf");
    #     But this won't work when perl has decided the OS is cygwin,
    #     even if it is invoked from a native NT command line.  An
    #     NT command processor must be used to deal with this.
    # 3.  External executables can be native NT (which only know
    #     NT-style file names) or cygwin executables (which normally
    #     know both cygwin UNIX-style file names and NT file names,
    #     but not always; some do not know about drive names, for
    #     example).
    #     Cygwin executables for tex and latex may only know cygwin
    #     filenames. 
    # 4.  The BIBINPUTS environment variables may be
    #     UNIX-style or MSWin-style depending on whether native NT or
    #     cygwin executables are used.  They are therefore parsed
    #     differently.  Here is the clash:
    #        a. If a user is running under an NT shell, is using a
    #           native NT installation of tex (e.g., fptex or miktex),
    #           but has the cygwin executables in the path, then perl
    #           detects the OS as cygwin, but the user needs NT
    #           behavior from latexmk.
    #        b. If a user is running under an UNIX shell in a cygwin
    #           environment, and is using the cygwin installation of
    #           tex, then perl detects the OS as cygwin, and the user
    #           needs UNIX behavior from latexmk.
    #     Latexmk has no way of detecting the difference.  The two
    #     situations may even arise for the same user on the same
    #     computer simply by changing the order of directories in the
    #     path environment variable


    ## Configuration parameters: We'll assume native NT executables.
    ## The user should override if they are not.

    # This may fail: perl converts MSWin temp directory name to cygwin
    # format. Names containing this string cannot be handled by native
    # NT executables.
    $tmpdir = $ENV{TMPDIR} || $ENV{TEMP} || '.';

    ## List of possibilities for the system-wide initialization file.  
    ## The first one found (if any) is used.
    ## We could stay with MSWin files here, since cygwin perl understands them
    ## @rc_system_files = ( 'C:/latexmk/LatexMk', 'C:/latexmk/latexmkrc' );
    ## But they are deprecated in v. 1.7.  So use the UNIX version, prefixed
    ##   with a cygwin equivalent of the MSWin location
    ## In addition, we need to add the same set of possible locations as with
    ## unix, so that the user use a unix-style setup.
    @rc_system_files = ();
    foreach ( 'LatexMk', 'latexmkrc' ) {
       push @rc_system_files,
           ( "/cygdrive/c/latexmk/$_",
             "/etc/$_",
             "/opt/local/share/latexmk/$_", 
             "/usr/local/share/latexmk/$_",
             "/usr/local/lib/latexmk/$_" );
    }
    $search_path_separator = ';';  # Separator of elements in search_path
    # This is tricky.  The search_path_separator depends on the kind
    # of executable: native NT v. cygwin.  
    # So the user will have to override this.

    # We will assume that files can be viewed by native NT programs.
    #  Then we must fix the start command/directive, so that the
    #  NT-native start command of a cmd.exe is used.
    # For a pdf-file, "start x.pdf" starts the pdf viewer associated with
    #   pdf files, so no program name is needed:
    $start_NT = "cmd /c start \"\"";
    $pdf_previewer = "$start_NT %O %S";
    $ps_previewer  = "$start_NT %O %S";
    $ps_previewer_landscape  = $ps_previewer;
    $dvi_previewer  = "$start_NT %O %S";
    $dvi_previewer_landscape = $dvi_previewer;
    # Viewer update methods: 
    #    0 => auto update: viewer watches file (e.g., gv)
    #    1 => manual update: user must do something: e.g., click on window.
    #         (e.g., ghostview, MSWIN previewers, acroread under UNIX)
    #    2 => send signal.  Number of signal in $dvi_update_signal,
    #                         $ps_update_signal, $pdf_update_signal
    #    3 => viewer can't update, because it locks the file and the file 
    #         cannot be updated.  (acroread under MSWIN)
    $dvi_update_method = 1;
    $ps_update_method = 1;
    $pdf_update_method = 3; # acroread locks the pdf file
}
elsif ( $^O eq "msys" ) {
    $search_path_separator = ';';  # Separator of elements in search_path
                                   # I think MS-Win value is OK, since
                                   # msys is running under MS-Win
    $pdf_previewer = q[sh -c 'start %S'];
    $ps_previewer = q[sh -c 'start %S'];
    $dvi_previewer = q[sh -c 'start %S'];
    $ps_previewer_landscape  = $ps_previewer;
    $dvi_previewer_landscape = "$dvi_previewer";
}
else {
    # Assume anything else is UNIX or clone
    # Do special cases (e.g., linux, darwin (i.e., OS-X)) inside this block.

    ## Use first existing case for $tmpdir:
    $tmpdir = $ENV{TMPDIR} || '/tmp';

    ## List of possibilities for the system-wide initialization file.  
    ## The first one found (if any) is used.
    @rc_system_files = ();
    foreach ( 'LatexMk', 'latexmkrc' ) {
       push @rc_system_files,
            ( "/etc/$_",
              "/opt/local/share/latexmk/$_", 
              "/usr/local/share/latexmk/$_",
              "/usr/local/lib/latexmk/$_" );
    }
    $search_path_separator = ':';  # Separator of elements in search_path

    $dvi_update_signal = $signo{USR1} 
         if ( defined $signo{USR1} ); # Suitable for xdvi
    $ps_update_signal = $signo{HUP} 
         if ( defined $signo{HUP} );  # Suitable for gv
    $pdf_update_signal = $signo{HUP} 
         if ( defined $signo{HUP} );  # Suitable for gv
    ## default document processing programs.
    # Viewer update methods: 
    #    0 => auto update: viewer watches file (e.g., gv)
    #    1 => manual update: user must do something: e.g., click on window.
    #         (e.g., ghostview, MSWIN previewers, acroread under UNIX)
    #    2 => send signal.  Number of signal in $dvi_update_signal,
    #                         $ps_update_signal, $pdf_update_signal
    #    3 => viewer can't update, because it locks the file and the file 
    #         cannot be updated.  (acroread under MSWIN)
    #    4 => Run command to update.  Command in $dvi_update_command, 
    #    $ps_update_command, $pdf_update_command.
    $dvi_previewer  = 'start xdvi %O %S';
    $dvi_previewer_landscape = 'start xdvi -paper usr %O %S';
    if ( defined $dvi_update_signal ) { 
        $dvi_update_method = 2;  # xdvi responds to signal to update
    } else {
        $dvi_update_method = 1;  
    }
#    if ( defined $ps_update_signal ) { 
#        $ps_update_method = 2;  # gv responds to signal to update
#        $ps_previewer  = 'start gv -nowatch';
#        $ps_previewer_landscape  = 'start gv -swap -nowatch';
#    } else {
#        $ps_update_method = 0;  # gv -watch watches the ps file
#        $ps_previewer  = 'start gv -watch';
#        $ps_previewer_landscape  = 'start gv -swap -watch';
#    }
    # Turn off the fancy options for gv.  Regular gv likes -watch etc
    #   GNU gv likes --watch etc.  User must configure
    $ps_update_method = 0;  # gv -watch watches the ps file
    $ps_previewer  = 'start gv %O %S';
    $ps_previewer_landscape  = 'start gv -swap %O %S';
    $pdf_previewer = 'start acroread %O %S';
    $pdf_update_method = 1;  # acroread under unix needs manual update
    $lpr = 'lpr %O %S';         # Assume lpr command prints postscript files correctly
    $lpr_dvi =
        'NONE $lpr_dvi variable is not configured to allow printing of dvi files';
    $lpr_pdf =
        'NONE $lpr_pdf variable is not configured to allow printing of pdf files';
    # The $pscmd below holds a command to list running processes.  It
    # is used to find the process ID of the viewer looking at the
    # current output file.  The output of the command must include the
    # process number and the command line of the processes, since the
    # relevant process is identified by the name of file to be viewed.
    # Uses:
    #   1.  In preview_continuous mode, to save running a previewer
    #       when one is already running on the relevant file.
    #   2.  With xdvi in preview_continuous mode, xdvi must be
    #       signalled to make it read a new dvi file.
    #
    # The following works on Solaris, LINUX, HP-UX, IRIX
    # Use -f to get full listing, including command line arguments.
    # Use -u $ENV{USER} to get all processes started by current user (not just
    #   those associated with current terminal), but none of other users' 
    #   processes. 
    # However, the USER environment variable may not exist.  Windows uses 
    #   USERNAME instead.  (And this propagates to a situation of 
    #   unix-emulation software running under Windows.) 
    if ( exists $ENV{USER} ) {
       $pscmd = "ps -f -u $ENV{USER}"; 
    }
    elsif ( exists $ENV{USERNAME} ) {
       $pscmd = "ps -f -u $ENV{USERNAME}"; 
    }
    else {
       $pscmd = "ps -f"; 
    }
    $pid_position = 1; # offset of PID in output of pscmd; first item is 0.  
    if ( $^O eq "linux" ) {
        # Ps on Redhat (at least v. 7.2) appears to truncate its output
        #    at 80 cols, so that a long command string is truncated.
        # Fix this with the --width option.  This option works under 
        #    other versions of linux even if not necessary (at least 
        #    for SUSE 7.2). 
        # However the option is not available under other UNIX-type 
        #    systems, e.g., Solaris 8.
        # But (19 Aug 2010), the truncation doesn't happen on RHEL4 and 5,
        #    unless the output is written to a terminal.  So the --width 
        #    option is now unnecessary
        # $pscmd = "ps --width 200 -f -u $ENV{USER}"; 
    }
    elsif ( $^O eq "darwin" ) {
        # OS-X on Macintosh
        # open starts command associated with a file.
        # For pdf, this is set by default to OS-X's preview, which is suitable.
        #     Manual update is simply by clicking on window etc, which is OK.
        # For ps, this is set also to preview.  This works, but since it
        #     converts the file to pdf and views the pdf file, it doesn't
        #     see updates, and a refresh cannot be done.  This is far from
        #     optimal.
        # For a full installation of MacTeX, which is probably the most common
        #     on OS-X, an association is created between dvi files and TeXShop.
        #     This also converts the file to pdf, so again while it works, it
        #     does not deal with changed dvi files, as far as I can see.
        $pdf_previewer = 'open %S';
        $pdf_update_method = 1;     # manual
        $dvi_previewer = $dvi_previewer_landscape = 'NONE';
        $ps_previewer = $ps_previewer_landscape = 'NONE';
        # Others
        $lpr_pdf  = 'lpr %O %S';
        $pscmd = "ps -ww -u $ENV{USER}"; 
    }
}

## default parameters
$auto_rc_use = 1;       # Whether to read rc files automatically
$user_deleted_file_treated_as_changed = 0; # Whether when testing for changed
               # files, a user file that changes status from existing
               # to non-existing should be regarded as changed.
               # Value 1: only in non-preview-continuous mode.
               # Value 2: always.
               # Primary purpose is to cover cases where behavior of
               # compilation of .tex file tests for file existence and
               # adjusts behavior accordingly, instead of simply giving an
               # error. 
$max_repeat = 5;        # Maximum times I repeat latex.  Normally
                        # 3 would be sufficient: 1st run generates aux file,
                        # 2nd run picks up aux file, and maybe toc, lof which 
                        # contain out-of-date information, e.g., wrong page
                        # references in toc, lof and index, and unresolved
                        # references in the middle of lines.  But the 
                        # formatting is more-or-less correct.  On the 3rd
                        # run, the page refs etc in toc, lof, etc are about
                        # correct, but some slight formatting changes may
                        # occur, which mess up page numbers in the toc and lof,
                        # Hence a 4th run is conceivably necessary. 
                        # At least one document class (JHEP.cls) works
                        # in such a way that a 4th run is needed.  
                        # We allow an extra run for safety for a
                        # maximum of 5. Needing further runs is
                        # usually an indication of a problem; further
                        # runs may not resolve the problem, and
                        # instead could cause an infinite loop.
@cus_dep_list = ();     # Custom dependency list
@default_files = ( '*.tex' );   # Array of LaTeX files to process when 
                        # no files are specified on the command line.
                        # Wildcards allowed
                        # Best used for project specific files.
@default_excluded_files = ( );   
                        # Array of LaTeX files to exclude when using
                        # @default_files, i.e., when no files are specified
                        # on the command line.
                        # Wildcards allowed
                        # Best used for project specific files.
$texfile_search = "";   # Specification for extra files to search for
                        # when no files are specified on the command line
                        # and the @default_files variable is empty.
                        # Space separated, and wildcards allowed.
                        # These files are IN ADDITION to *.tex in current 
                        # directory. 
                        # This variable is obsolete, and only in here for
                        # backward compatibility.

$fdb_ext = 'fdb_latexmk'; # Extension for the file for latexmk's
                          # file-database
                          # Make it long to avoid possible collisions.
$fdb_ver = 4;             # Version number for kind of fdb_file.

$jobname = '';          # Jobname: as with current tex, etc indicates
                        # basename of generated files.  Defined so
                        # that --jobname=STRING on latexmk's command
                        # line has same effect as with current tex,
                        # etc, with the exception listed below.  (If
                        # $jobname is non-empty, then the
                        # --jobname=... option is used on tex.)
                        # Extension: $jobname is allowed to contain
                        # placeholder(s) (currently only %A),
                        # which allows construction of jobnames
                        # dependent on name of main TeX file; this is
                        # useful when a jobname is used and latexmk is
                        # invoked on multiple files.
$out_dir = '';          # Directory for output files.  
                        # Cf. --output-directory of current *latex
                        # Blank means default, i.e., cwd.
$aux_dir = '';          # Directory for aux files (log, aux, etc).
                        # Cf. --aux-directory of current *latex in MiKTeX.
                        # Blank means default, i.e., same as $out_dir.
                        # Note that these values get modified when
                        # processing a .tex file.

## default flag settings.
$recorder = 1;          # Whether to use recorder option on latex/pdflatex
$silent = 0;            # Whether fo silence latex's messages (and others)
$warnings_as_errors = 0;# Treat warnings as errors and exit with non-zero exit code
$silence_logfile_warnings = 0; # Do list warnings in log file
                        # The warnings reported are those about undefined refs
                        # and citations, and the like.
$max_logfile_warnings = 7; # Max. # number of log file warnings to report
$rc_report = 1;         # Whether to report on rc files read
$aux_out_dir_report = 0; # Whether to report on aux_dir & out_dir after
                         # initialization and normalization

$kpsewhich_show = 0;    # Show calls to and results from kpsewhich
$landscape_mode = 0;    # default to portrait mode
$analyze_input_log_always = 1; # Always analyze .log for input files in the
                        #  <...> and (...) constructions.  Otherwise, only
                        # do the analysis when fls file doesn't exist or is
                        # out of date.
                        # Under normal circumstances, the data in the fls file
                        # is reliable, and the test of the log file gets lots
                        # of false positives; usually $analyze_input_log_always
                        # is best set to zero.  But the test of the log file
                        # is needed at least in the following situation:
                        # When a user needs to persuade latexmk that a certain
                        # file is a source file, and latexmk doesn't otherwise
                        # find it.  User code causes line with (...) to be
                        # written to log file.  One important case is for 
                        # lualatex, which doesn't always generate lines in the
                        # .fls file for input lua files.  (The situation with
                        # lualatex is HIGHLY version dependent, e.g., between
                        # 2016 and 2017.)
                        # To keep backward compatibility with older versions
                        # of latexmk, the default is to set
                        # $analyze_input_log_always to 1.
$fls_uses_out_dir = 0;  # Whether fls file is to be in out directory (as with
                        # pre-Oct-2020 MiKTeX), or in aux directory (as with
                        # newer versions of MiKTeX).
                        # If the implementation of *latex puts the fls file in
                        # the other directory, I will copy it to the directory
                        # I am configured to use.


# Which kinds of file do I have requests to make?
our ($dvi_mode, $pdf_mode, $postscript_mode, $xdv_mode,
     $cleanup_mode, $force_mode, $go_mode, $landscape_mode, $preview_mode, $preview_continuous_mode, $printout_mode );
# If no requests at all are made, then I will make dvi file
# If particular requests are made then other files may also have to be
# made.  E.g., ps file requires a dvi file
$dvi_mode = 0;          # No dvi file requested.
                        # Possible values:
                        #  0: no request for dvi file
                        #  1: use latex to make dvi file
                        #  2: use dvilualatex to make dvi file
$postscript_mode = 0;   # No postscript file requested
$pdf_mode = 0;          # No pdf file requested to be made by pdflatex
                        # Possible values: 
                        #     0 don't create pdf file
                        #     1 to create pdf file by pdflatex
                        #     2 to create pdf file by compile-to-dvi+dvips+ps2pdf
                        #     3 to create pdf file by compile-to-dvi+dvipdf
                        #     4 to create pdf file by lualatex
                        #     5 to create pdf file by xelatex + xdvipdfmx
$xdv_mode = 0;          # No xdv file requested

$view = 'default';      # Default preview is of highest of dvi, ps, pdf
$sleep_time = 2;        # time to sleep b/w checks for file changes in -pvc mode
$banner = 0;            # Non-zero if we have a banner to insert
$banner_scale = 220;    # Original default scale
$banner_intensity = 0.95;  # Darkness of the banner message
$banner_message = 'DRAFT'; # Original default message
$do_cd = 0;     # Do not do cd to directory of source file.
                #   Thus behave like latex.
$dependents_list = 0;   # Whether to display list(s) of dependencies
$dependents_phony = 0;  # Whether list(s) of dependencies includes phony targets
                        # (as with 'gcc -MP').
$deps_file = '-';       # File for dependency list output.  Default stdout.
$rules_list = 0;        # Whether to display list(s) of dependencies
# Kind of escaping in names of files written to deps file.
$deps_escape = 'none';
# Allowed kinds of escape:
%deps_escape_kinds =  ( 'none' => ' ', 'unix' => '\ ', 'nmake' => '^ ');

@dir_stack = ();        # Stack of pushed directories, each of form of 
                        # pointer to array  [ cwd, good_cwd ], where
                        # good_cwd differs from cwd by being converted
                        # to native MSWin path when cygwin is used.
$cleanup_mode = 0;      # No cleanup of nonessential LaTex-related files.
                        # $cleanup_mode = 0: no cleanup
                        # $cleanup_mode = 1: full cleanup 
                        # $cleanup_mode = 2: cleanup except for dvi,
                        #                    dviF, pdf, ps, psF & xdv
$cleanup_fdb  = 0;      # On normal run, no removal of file for latexmk's file-database
$cleanup_only = 0;      # When doing cleanup, do not go on to making files
$cleanup_includes_generated = 0; 
                        # Determines whether cleanup deletes files generated by
                        #    *latex (found from \openout lines in log file).
                        # It's more than that.  BUG
$cleanup_includes_cusdep_generated = 0;
                        # Determines whether cleanup deletes files generated by
                        #    custom dependencies
$diagnostics = 0;
$dvi_filter = '';       # DVI filter command
$ps_filter = '';        # Postscript filter command

$force_mode = 0;        # =1: to force processing past errors
$go_mode = 0;           # =1: to force processing regardless of time-stamps
                        # =2: full clean-up first
                        # =3: Just force primary rule(s) to run
$preview_mode = 0;
$preview_continuous_mode  = 0;
$printout_mode = 0;     # Don't print the file

## Control pvc inactivity timeout:
$pvc_timeout = 0;
$pvc_timeout_mins = 30;

# Timing information
# Whether to report processing time: 
our $show_time = 0;

# Whether times computed are clock times (HiRes) since Epoch, or are
# processing times for this process and child processes, as reported by
# times().  Second is the best, if accurate.  But on MSWin32, times()
# appears not to included subprocess times, so we use clock time instead.
our $times_are_clock = ($^O eq "MSWin32" );


# Data for 1 run and global (ending in '0'):
our ( $processing_time1, $processing_time0, @timings1, @timings0);
&init_timing_all;


$use_make_for_missing_files = 0;   # Whether to use make to try to make missing files.

# Do we make view file in temporary then move to final destination?
#  (To avoid premature updating by viewer).
$always_view_file_via_temporary = 0;      # Set to 1 if  viewed file is always
                                   #    made through a temporary.
$pvc_view_file_via_temporary = 1;  # Set to 1 if only in -pvc mode is viewed 
                                   #    file made through a temporary.

# State variables initialized here:

$updated = 0;           # Flags whether something has been remade in this round
                        # of compilation. 
$waiting = 0;           # Flags whether we are in loop waiting for an event
                        # Used to avoid unnecessary repeated o/p in wait loop

# The following are used for some results of parsing log file
# Global variables, so results can be reported in main program. 
$reference_changed = 0;
$mult_defined = 0;
$bad_reference = 0;
$bad_character = 0;
$bad_citation = 0;
@primary_warning_summary = ();

# Cache of expensive-to-compute state variables, e.g., cwd in form
# fixed to deal with cygwin issues.
%cache = ();
&cache_good_cwd;

# Set search paths for includes.
# Set them early so that they can be overridden
$BIBINPUTS = $ENV{'BIBINPUTS'};
if (!$BIBINPUTS) { $BIBINPUTS = '.'; }

# ???!!! 
# Old configuration variable @BIBINPUTS to be equivalent to environment
# variable BIBINPUTS.  It was to be easier to work with inside latexmk. But
# under present conditions, it's better to manipulate $ENV{BIBINPUTS}.
# ??? Need to explain better.
# Why only for BIBINPUTS, not TEXINPUTS.
#
# But retain @BIBINPUTS for backward compatibility, since users may have
# configured it.  We'll save the values, allow for possible user changes in
# @BIBINPUTS or $ENV{BIBINPUTS} in rc files and from command line
# arguments. Then funnel changes back to $ENV{BIBINPUTS}, ...
#
# Convert search paths to arrays:
# If any of the paths end in '//' then recursively search the
# directory.  After these operations, @BIBINPUTS  should
# have all the directories that need to be searched
#
@BIBINPUTS = find_dirs1( $BIBINPUTS );
our @BIBINPUTS_SAVE = @BIBINPUTS;
our $BIBINPUTS_ENV_SAVE = $ENV{BIBINPUTS};


######################################################################
######################################################################
#
#  ???  UPDATE THE FOLLOWING!!
#
# We will need to determine whether source files for runs of various
# programs are out of date.  In a normal situation, this is done by
# asking whether the times of the source files are later than the
# destination files.  But this won't work for us, since a common
# situation is that a file is written on one run of latex, for
# example, and read back in on the next run (e.g., an .aux file).
# Some situations of this kind are standard in latex generally; others
# occur with particular macro packages or with particular
# postprocessors. 
#
# The correct criterion for whether a source is out-of-date is
# therefore NOT that its modification time is later than the
# destination file, but whether the contents of the source file have
# changed since the last successful run.  This also handles the case
# that the user undoes some changes to a source file by replacing the
# source file by reverting to an earlier version, which may well have
# an older time stamp.  Since a direct comparison of old and new files
# would involve storage and access of a large number of backup files,
# we instead use the md5 signature of the files.  (Previous versions
# of latexmk used the backup file method, but restricted to the case
# of .aux and .idx files, sufficient for most, but not all,
# situations.)
#
# We will have a database of (time, size, md5) for the relevant
# files. If the time and size of a file haven't changed, then the file
# is assumed not to have changed; this saves us from having to
# determine its md5 signature, which would involve reading the whole 
# file, which is naturally time-consuming, especially if network file
# access to a server is needed, and many files are involved, when most
# of them don't change.  It is of course possible to change a file
# without changing its size, but then to adjust its timestamp 
# to what it was previously; this requires a certain amount of
# perversity.  We can safely assume that if the user edits a file or
# changes its contents, then the file's timestamp changes.  The
# interesting case is that the timestamp does change, because the file
# has actually been written to, but that the contents do not change;
# it is for this that we use the md5 signature.  However, since
# computing the md5 signature involves reading the whole file, which
# may be large, we should avoid computing it more than necessary. 
#
# So we get the following structure:
#
#     1.  For each relevant run (latex, pdflatex, each instance of a
#         custom dependency) we have a database of the state of the
#         source files that were last used by the run.
#     2.  On an initial startup, the database for a primary tex file
#         is read that was created by a previous run of latex or
#         pdflatex, if this exists.  
#     3.  If the file doesn't exist, then the criterion for
#         out-of-dateness for an initial run is that it goes by file
#         timestamps, as in previous versions of latexmk, with due
#         (dis)regard to those files that are known to be generated by
#         latex and re-read on the next run.
#     4.  Immediately before a run, the database is updated to
#         represent the current conditions of the run's source files.
#     5.  After the run, it is determined whether any of the source
#         files have changed.  This covers both files written by the
#         run, which are therefore in a dependency loop, and files that
#         the user may have updated during the run.  (The last often
#         happens when latex takes a long time, for a big document,
#         and the user makes edits before latex has finished.  This is
#         particularly prevalent when latexmk is used with
#         preview-continuous mode.)
#     6.  In the case of latex or pdflatex, the custom dependencies
#         must also be checked and redone if out-of-date.
#     7.  If any source files have changed, the run is redone,
#         starting at step 1.
#     8.  There is naturally a limit on the number of reruns, to avoid
#         infinite loops from bugs and from pathological or unforeseen
#         conditions. 
#     9.  After the run is done, the run's file database is updated.
#         (By hypothesis, the sizes and md5s are correct, if the run
#         is successful.)
#    10.  To allow reuse of data from previous runs, the file database
#         is written to a file after every complete set of passes
#         through latex or pdflatex.  (Note that there is separate
#         information for latex and pdflatex; the necessary
#         information won't coincide: Out-of-dateness for the files
#         for each program concerns the properties of the files when
#         the other program was run, and the set of source files could
#         be different, e.g., for graphics files.)  
#
# We therefore maintain the following data structures.:
#
#     a.  For each run (latex, pdflatex, each custom dependency) a
#         database is maintained.  This is a hash from filenames to a
#         reference to an array:  [time, size, md5].  The semantics of
#         the database is that it represents the state of the source
#         files used in the run.  During a run it represents the state
#         immediately before the run; after a run, with all reruns, it
#         represents the state of the files used, modified by having
#         the latest timestamps for generated files.
#     b.  There is a global database for all files, which represents
#         the current state.  This saves having to recompute the md5
#         signatures of a changed file used in more than one run
#         (e.g., latex and pdflatex).
#     c.  Each of latex and pdflatex has a list of the relevant custom
#         dependencies. 
#
# In all the following a fdb-hash is a hash of the form:
#                      filename -> [time, size, md5] 
# If a file is found to disappear, its entry is removed from the hash.
# In returns from fdb access routines, a size entry of -1 indicates a
# non-existent file.



# Hashes, whose keys give names of particular kinds of rule, and targets.
# We use hashes for ease of lookup.
%possible_one_time = ( 'view' => 1, 'print' => 1, 'update_view' => 1,  );
%target_files      = (); # Hash for target files.
                    # The keys are the filenames and the value is 
                    # currently irrelevant.
%target_rules      = (); # Hash for target rules beyond those corresponding to files.
                    # The keys are the rule names and the value is 
                    # currently irrelevant.
# The target **files** can only be set inside the FILE loop.
$current_primary  = 'latex';   # Rule to compile .tex file.
                    # It will be overridden at rule-initialization time, and
                    # is subject to document-dependent override if .tex document
                    # uses metcommands and obeying them is implemented/enabled.
$pdf_method       = '';  # How to make pdf file.  '' if not requested,
                    # else 'ps2pdf', 'dvipdf', 'pdflatex', 'lualatex' or 'xelatex'
                    # Subject to document-dependent override if .tex document
                    #uses \pdfoutput or c.
%requested_filetypes = (); # Hash of requested file types (dvi, dviF, etc)
%one_time = ();     # Hash for requested one-time-only rules, currently
                    # possible values 'print' and 'view'.  

%actives = ();      # Hash of active rules

$allow_switch = 1;  # Allow switch of rule structure to accommodate
                    # changed output file name of primary. Even if
                    # this flag is set on, the switch may be
                    # prohibited by other issues.

%rule_db = ();      # Database of all rules:
                    # Hash: rulename -> [array of rule data]
                    # Rule data:
                    #   0: [ cmd_type, ext_cmd, int_cmd, no_history, 
                    #       source, dest, base,
                    #       out_of_date, out_of_date_user,
                    #       time_of_last_run, time_of_last_file_check,
                    #       changed
                    #       last_result, last_result_info, last_message,
                    #       default_extra_generated,
                    #      ]
                    # where 
                    #     cmd_type is 'primary', 'external', or 'cusdep'
                    #     ext_cmd is string for associated external command
                    #       with substitutions (%D for destination, %S
                    #       for source, %B for base of current rule,
                    #       %R for base of primary tex file, %T for
                    #       texfile name, %O for options,
                    #       %V=$aux_dir, %W=$out_dir,
                    #       %Y for $aux_dir1, and %Z for $out_dir1
                    #     int_cmd specifies any internal command to be
                    #       used to implement the application of the
                    #       rule.  If this is present, it overrides
                    #       **direct** execution of the external command, and
                    #       it is the responsibility of the perl subroutine
                    #       specified in intcmd to execute the specified
                    #       external command if this is appropriate.
                    #       This variable intcmd is a reference to an array,  
                    #       $$intcmd[0] = internal routine
                    #       $$intcmd[1...] = its arguments (if any)
                    #     no_history being true indicates that there was no
                    #       data on the file state from a previous run.  In
                    #       this case the implication is that when the next
                    #       test for whether a run of the rule is needed,
                    #       the file-contents criterion won't be useful.
                    #       Then a time-based criterion (as in normal make)
                    #       is used, i.e., if a source file is newer than
                    #       the destination file, then a rerun is needed.
                    #       After that first test for a rerun has been
                    #       done, a run or no run is made according as
                    #       appropriate.  After that the file-change
                    #       criterion works, and no_history is turned off.
                    #     source = name of primary source file, if any
                    #     dest   = name of primary destination file,
                    #              if any
                    #     base   = base name, if any, of files for
                    #              this rule
                    #     out_of_date = 1 if it has been detected that
                    #                     this rule needs to be run
                    #                     (typically because a source
                    #                     file has changed).
                    #                   Other values may be used for special cases.
                    #                   0 otherwise
                    #     out_of_date_user is like out_of_date, except
                    #         that the detection of out-of-dateness
                    #         has been made from a change of a
                    #         putative user file, i.e., one that is
                    #         not a generated file (e.g., aux). This
                    #         kind of out-of-dateness should provoke a
                    #         rerun whether or not there was an error
                    #         during a run of *LaTeX.  Normally,
                    #         if there is an error, one should wait
                    #         for the user to correct the error.  But
                    #         it is possible the error condition is
                    #         already corrected during the run, e.g.,
                    #         by the user changing a source file in
                    #         response to an error message. 
                    #     time_of_last_run = time that this rule was
                    #              last applied.  (In standard units
                    #              from perl, to be directly compared
                    #              with file modification times.)
                    #     time_of_last_file_check = last time that a check
                    #              was made for changes in source files.
                    #     changed flags whether special changes have been made
                    #          that require file-existence status to be ignored
                    #     last_result is 
                    #                 -1 if no run has been made
                    #                  0 if the last run was successful
                    #                  1 if last run was successful, but
                    #                    failed to create an output file
                    #                  2 if last run failed
                    #                  200 if last run gave a warning that is
                    #                    important enough to be reported with 
                    #                    the error summary.  The warning
                    #                    message is stored in last_message.
                    #     last_result_info is info about run that gave
                    #         code in last_result. Currently used values:
                    #              ''      No record of this rule being run
                    #              'CURR'  Run of rule was in current
                    #                      round of compilation. 
                    #              'PREV'  Run of rule was in a previous
                    #                      round of compilation (as with
                    #                      -pvc), but in current invocation
                    #                      of latexmk.
                    #              'CACHE' Run of rule was in a previous
                    #                      invocation of latexmk, with
                    #                      last_result having been read
                    #                      from fdb_latexmk file.
                    #     last_message is error message for last run
                    #     default_extra_generated is a reference to an array
                    #       of specifications of extra generated files (beyond
                    #       the main dest file.  Standard place holders are used.
                    #   1: {Hash sourcefile -> [source-file data] }
                    #      Source-file data array: 
                    #        0: time
                    #        1: size
                    #        2: md5
                    #        3: DUMMY.  Not used any more. ?? Lots of code depends
                    #               on array structure, Let's not change things now.
                    #        4: whether the file is of the kind made by epstopdf.sty 
                    #           during a primary run.  It will have been read during
                    #           the run, so that even though the file changes during
                    #           a primary run, there is no need to trigger another 
                    #           run because of this.
                    #       Size and md5 correspond to the values at the last run.
                    #       But time may be updated to correspond to the time
                    #       for the file, if the file is otherwise unchanged.
                    #       This saves excessive md5 calculations, which would
                    #       otherwise be done everytime the file is checked, 
                    #       in the following situation:
                    #          When the file has been rewritten after a run
                    #          has started (commonly aux, bbl files etc),
                    #          but the actual file contents haven't
                    #          changed.  Then because the filetime has
                    #          changed, on every file-change check latexmk
                    #          would normally redo the md5 calculation to
                    #          test for actual changes.  Once one such
                    #          check is done, and the contents are
                    #          unchanged, later checks are superfluous, and
                    #          can be avoided by changing the file's time
                    #          in the source-file list.
                    #   2: {Hash generated_file -> 1 }
                    #      This lists all generated files.
                    #      The values for the hash are currently unused, only the keys.
                    #   3: {Hash rewritten_before_read_file -> 1 }
                    #      This lists all files that are only read after being
                    #      written **and** that existed before being
                    #      written, i.e., that existed at the beginning of
                    #      the run.  These are listed in both the source-
                    #      and generated-file hashes, but do not need
                    #      to be checked for changes in testing whether
                    #      another run is needed, i.e., they aren't true
                    #      source files.  **IMPORTANT NOTE:** If a file is
                    #      read only after being written, but the file didn't
                    #      exist at the beginning of the run, it is
                    #      possible (and often true) that on a subsequent
                    #      run the file would be read, then written, and
                    #      perhaps read again.  That is, it can be that
                    #      before the file is written, there is a test for
                    #      file existence, and the file is read, but only
                    #      if it exists.  Examples: .aux and .toc
                    #      files. Such files are true dependencies and must
                    #      be checked for changes. Only when the file
                    #      existed at the start of the run and was then
                    #      written before being read, do we know that
                    #      write-before-read shows that the file is not a
                    #      true source-dependency.
                    #      This issue is significant: under some situations,
                    #      like the use of latexmk and tex4ht, the file may
                    #      be changed by other software before the next run
                    #      of the current rule.  That must not trigger
                    #      another run. 
                    #      The values for the hash are currently unused, only the keys.
                    #   4: {Hash source_rule -> last_pass }
                    #      This lists rules that are to be considered source
                    #      rules for the current rule, separately from the 
                    #      source_rules of the source files. Its main use
                    #      (the only one at present) is when the list of
                    #      known source files, at item 1, is/may be
                    #      incomplete. This is notably the case for rules
                    #      applied to dvi and xdv files when graphics files
                    #      are involved. Their names are coded inside the
                    #      dvi/xdv file, but not the contents. It would
                    #      need parsing of the contents of the file to
                    #      determine the actual source files. In the case
                    #      of rules that process dvi and xdv files, the
                    #      source_rule is the *latex rule that generates
                    #      the dvi or xdv file.
                    #
                    #      In determining whether a rerun of the current
                    #      rule is needed at some stage in a round of
                    #      compilation, the following is added to the
                    #      basic source-file-change criterion.
                    #        The value that a source rule in this hash maps
                    #        to is its pass number when the current rule was
                    #        last run. The current rule is flagged
                    #        out-of-date if the saved last_pass for a source
                    #        rule is less than the current pass number for
                    #        that source rule (as known to the compilation
                    #        process). 
                    #      An implication of using a source_rule in this
                    #      way is that the source_rule passes files (or
                    #      other information) to the current rule, and that
                    #      the current rule is to be rerun whenever the
                    #      source_rule has been run. 

%fdb_current = ();  # Hash of information for all files used.
                    # It maps filename to a reference to an array
                    #  (time, size, md5_checksum).
@nofile = (0,-1,0); # What we use for initializing a new entry in fdb
                    # or flagging non-existent file.

# The following are variables which are set by the routine rdb_set_rule_net.
# They are **derived** from information in %rule_db, and provide information
# about the structure of the network of rules and files.   This derived
# information is in a form useful for using the network of rules.

# For recursing backwards through the network of rules:
%from_rules = ();        # This maps file names to rule names.
                         # $from_rules{'File'} is the name of the rule that
                         # generates file 'File'.  If there is no rule to
                         # generate the file, then $from_rules{'File'} is
                         # not defined (or possibly the null string '').

# Classification of rules, for determining order of application
@pre_primary = ();         # Array of rules that are thought of as pre-primary,
                           # Should be in an appropriate order for invoking
                           # them, to optimize making.
@post_primary = ();        # Array of rules that are thought of as post-primary.
                           # In suitable order for invocation
@unusual_one_time = ();    # Array of rules that are special cases of
                           # one-time rules.
                           # Currently not used.


# User's home directory
$HOME = '';
if (exists $ENV{'HOME'} ) {
    $HOME = $ENV{'HOME'};
}
elsif (exists $ENV{'USERPROFILE'} ) {
    $HOME = $ENV{'USERPROFILE'};
}
# XDG configuration home
$XDG_CONFIG_HOME = '';
if (exists $ENV{'XDG_CONFIG_HOME'} ) {
    $XDG_CONFIG_HOME = $ENV{'XDG_CONFIG_HOME'};
}
elsif ($HOME ne '') {
    if ( -d "$HOME/.config") {
        $XDG_CONFIG_HOME = "$HOME/.config";
    }
}


#==================================================

# Which rc files did I read?
@rc_files_read = ();  # In order of reading
%rc_files_read2 = (); # Map **abs** filename to 1; used to check duplicate reads.

# Options that are to be obeyed before rc files are read:
foreach $_ ( @ARGV )
{
    if (/^-{1,2}norc$/ ) {
        $auto_rc_use = 0;
    }
}

#==================================================
## Read rc files with this subroutine

sub read_first_rc_file_in_list {
    foreach my $rc_file ( @_ ) {
        if ( -d $rc_file ) {
            warn "$My_name: I have found a DIRECTORY named \"$rc_file\".\n",
                 "   Have you perhaps misunderstood latexmk's documentation?\n",
                 "   This name is normally used for a latexmk configuration (rc) file,\n",
                 "   and in that case it should be a regular text file, not a directory.\n";
        }
        elsif ( -e $rc_file ) {
            process_rc_file( $rc_file );
            return;
        }
    }
}

# Note that each rc file may unset $auto_rc_use to
# prevent lower-level rc files from being read.
# So test on $auto_rc_use in each case.
if ( $auto_rc_use ) {
    # System rc file:
    if (exists $ENV{LATEXMKRCSYS} ) {
        unshift @rc_system_files, $ENV{LATEXMKRCSYS};
        if ( !-e $ENV{LATEXMKRCSYS} ) {
            warn "$My_name: you've specified a system rc file `$ENV{LATEXMKRCSYS}`\n",
                 "   in environment variable LATEXMKRCSYS, but the file doesn't exist.\n",
                 "   I won't read any system rc file.\n";
        }
        else {
           process_rc_file( $ENV{LATEXMKRCSYS} );
        }
    }
    else {
        read_first_rc_file_in_list( @rc_system_files );
    }
}
if ( $auto_rc_use && ($HOME ne "" ) ) {
    # User rc file:
    @user_rc = ();
    if ( $XDG_CONFIG_HOME ) { 
       push @user_rc, "$XDG_CONFIG_HOME/latexmk/latexmkrc";
    }
    # N.B. $HOME equals "" if latexmk couldn't determine a home directory.
    # In that case, we shouldn't look for an rc file there.
    if ( $HOME ) { 
       push @user_rc, "$HOME/.latexmkrc";
    }
    read_first_rc_file_in_list( @user_rc );
}
if ( $auto_rc_use ) { 
    # Rc file in current directory:
    read_first_rc_file_in_list( ".latexmkrc", "latexmkrc" );
}



## Process command line args.
@command_line_file_list = ();
$bad_options = 0;

while (defined($_ = $ARGV[0])) {
  # Make -- and - equivalent at beginning of option,
  # but save original for possible use in *latex command line
  $original = $_;
  s/^--/-/;
  shift;
  if ( /^-aux-directory=(.*)$/ || /^-auxdir=(.*)$/ ) {
      $aux_dir = $1;
  }
  elsif (/^-bib(tex|)fudge$/) { $bibtex_fudge = 1; }
  elsif (/^-bib(tex|)fudge-$/) { $bibtex_fudge = 0; }
  elsif (/^-bibtex$/) { $bibtex_use = 2; }
  elsif (/^-bibtex-$/) { $bibtex_use = 0; }
  elsif (/^-nobibtex$/) { $bibtex_use = 0; }
  elsif (/^-bibtex-cond$/) { $bibtex_use = 1; }
  elsif (/^-bibtex-cond1$/) { $bibtex_use = 1.5; }
  elsif (/^-c$/)        { $cleanup_mode = 2; $cleanup_only = 1; }
  elsif (/^-C$/ || /^-CA$/ ) { $cleanup_mode = 1; $cleanup_only = 1; }
  elsif (/^-CF$/)    { $cleanup_fdb = 1; }
  elsif (/^-cd$/)    { $do_cd = 1; }
  elsif (/^-cd-$/)   { $do_cd = 0; }
  elsif (/^-commands$/) { &print_commands; exit; }
  elsif (/^-d$/)     { $banner = 1; }
  elsif (/^-dependents$/ || /^-deps$/ || /^-M$/ ) { $dependents_list = 1; }
  elsif (/^-nodependents$/ || /^-dependents-$/ || /^-deps-$/) { $dependents_list = 0; }
  elsif (/^-deps-escape=(.*)$/) {
      if ( $deps_escape_kinds{$1} ) { $deps_escape = $1; }
      else { warn "$My_name: In '$_', kind of escape is not one of those I know, which are\n",
                   "   ", join( ' ', sort( keys %deps_escape_kinds )), "\n";
      }
  }
  elsif (/^-deps-out=(.*)$/) {
      $deps_file = $1;
      $dependents_list = 1; 
  }
  elsif (/^-diagnostics/) { $diagnostics = 1; }
  elsif (/^-dir-report$/)    { $aux_out_dir_report = 1; }
  elsif (/^-dir-report-$/)   { $aux_out_dir_report = 0; }
  elsif (/^-dvi$/)    { $dvi_mode = 1; }
  elsif (/^-dvilua$/) { $dvi_mode = 2; }
  elsif (/^-dvi-$/)   { $dvi_mode = 0; }
  elsif ( /^-dvilualatex=(.*)$/ ) {
      $dvilualatex = $1;
  }
  elsif (/^-emulate-aux-dir$/) { $emulate_aux = 1; }
  elsif (/^-emulate-aux-dir-$/) { $emulate_aux = 0; }
  elsif (/^-f$/)     { $force_mode = 1; }
  elsif (/^-f-$/)    { $force_mode = 0; }
  elsif (/^-g$/)     { $go_mode = 1; }
  elsif (/^-g-$/)    { $go_mode = 0; }
  elsif (/^-gg$/)    { 
     $go_mode = 2; $cleanup_mode = 1; $cleanup_only = 0; 
  }
  elsif (/^-gt$/)    { 
     $go_mode = 3;
  }
  elsif ( /^-h$/ || /^-help$/ )   { &print_help; exit;}
  elsif (/^-jobname=(.*)$/) {
      $jobname = $1;
  }
  elsif (/^-l$/)     { $landscape_mode = 1; }
  elsif (/^-l-$/)    { $landscape_mode = 0; }
  elsif ( /^-latex$/ )      { 
      $pdf_mode = 0;
      $postscript_mode = 0; 
      $dvi_mode = 1;
  }
  elsif (/^-latex=(.*)$/) {
      $latex = $1;
  }
  elsif (/^-latexoption=(.*)$/) {
      push @extra_dvilualatex_options, $1;
      push @extra_latex_options, $1;
      push @extra_pdflatex_options, $1;
      push @extra_lualatex_options, $1;
      push @extra_xelatex_options, $1;
  }
  elsif ( /^-logfilewarninglist$/ || /^-logfilewarnings$/ )
      { $silence_logfile_warnings = 0; }
  elsif ( /^-logfilewarninglist-$/ || /^-logfilewarnings-$/ )
      { $silence_logfile_warnings = 1; }
  elsif ( /^-lualatex$/ || /^-pdflualatex$/ )      { 
      $pdf_mode = 4;
      $dvi_mode = $postscript_mode = 0; 
  }
# See below for -lualatex=...
# See above for -M
  elsif (/^-MF$/) {
     if ( $ARGV[0] eq '' ) {
        &exit_help( "No file name specified after -MF switch");
     }
     $deps_file = $ARGV[0];
     shift; 
  }
  elsif ( /^-MP$/ ) { $dependents_phony = 1; }
  elsif (/^-(make|)indexfudge$/) { $makeindex_fudge = 1; }
  elsif (/^-(make|)indexfudge-$/) { $makeindex_fudge = 0; }
  elsif ( /-MSWinBackSlash$/ ) { $MSWin_back_slash = 1; }
  elsif ( /-MSWinBackSlash-$/ ) { $MSWin_back_slash = 0; }
  elsif (/^-new-viewer$/) {
      $new_viewer_always = 1; 
  }
  elsif (/^-new-viewer-$/) {
      $new_viewer_always = 0;
  }
  elsif (/^-norc$/ ) {
      $auto_rc_use = 0;
      # N.B. This has already been obeyed.
  }
  elsif (/^-nobib(tex|)fudge$/) { $bibtex_fudge = 0; }
  elsif (/^-noemulate-aux-dir$/) { $emulate_aux = 0; }
  elsif (/^-no(make|)indexfudge$/) { $makeindex_fudge = 0; }
  elsif ( /^-output-directory=(.*)$/ ||/^-outdir=(.*)$/ ) {
      $out_dir = $1;
  }
  elsif ( /^-output-format=(.*)$/ ) {
      my $format = $1;
      if ($format eq 'dvi' ) {
          $dvi_mode = 1;
          $pdf_mode = $postscript_mode = 0;
      }
      elsif ($format eq 'pdf' ) {
          $pdf_mode = 1;
          $dvi_mode = $postscript_mode = 0;
      }
      else {
          warn "$My_name: unknown format in option '$_'\n";
          $bad_options++;
      }
  }
  elsif (/^-p$/)     { $printout_mode = 1; 
                       $preview_continuous_mode = 0; # to avoid conflicts
                       $preview_mode = 0;  
                     }
  elsif (/^-p-$/)    { $printout_mode = 0; }
  elsif (/^-pdf$/)   { $pdf_mode = 1; }
  elsif (/^-pdf-$/)  { $pdf_mode = 0; }
  elsif (/^-pdfdvi$/){ $pdf_mode = 3; }
  elsif (/^-pdflua$/){ $pdf_mode = 4; }
  elsif (/^-pdfps$/) { $pdf_mode = 2; }
  elsif (/^-pdfxe$/) { $pdf_mode = 5; }
  elsif (/^-pdflatex$/) {
      $pdflatex = "pdflatex %O %S";
      $pdf_mode = 1;
      $dvi_mode = $postscript_mode = 0; 
  }
  elsif (/^-pdflatex=(.*)$/) {
      $pdflatex = $1;
  }
  elsif ( /^-pdflualatex=(.*)$/ || /^-lualatex=(.*)$/ ) {
      $lualatex = $1;
  }
  elsif ( /^-pdfxelatex=(.*)$/ || /^-xelatex=(.*)$/ ) {
      $xelatex = $1;
  }
  elsif (/^-pretex=(.*)$/) {
      $pre_tex_code = $1;
  }
  elsif (/^-print=(.*)$/) {
      $value = $1;
      if ( $value =~ /^dvi$|^ps$|^pdf$|^auto$/ ) {
          $print_type = $value;
          $printout_mode = 1;
      }
      else {
          &exit_help("$My_name: unknown print type '$value' in option '$_'");
      }
  }
  elsif (/^-ps$/)    { $postscript_mode = 1; }
  elsif (/^-ps-$/)   { $postscript_mode = 0; }
  elsif (/^-pv$/)    { $preview_mode = 1; 
                       $preview_continuous_mode = 0; # to avoid conflicts
                       $printout_mode = 0; 
                     }
  elsif (/^-pv-$/)   { $preview_mode = 0; }
  elsif (/^-pvc$/)   { $preview_continuous_mode = 1;
                       $force_mode = 0;    # So that errors do not cause loops
                       $preview_mode = 0;  # to avoid conflicts
                       $printout_mode = 0; 
                     }
  elsif (/^-pvc-$/)  { $preview_continuous_mode = 0; }
  elsif (/^-pvctimeout$/) { $pvc_timeout = 1; }
  elsif (/^-pvctimeout-$/) { $pvc_timeout = 0; }
  elsif (/^-pvctimeoutmins=(.*)$/) { $pvc_timeout_mins = $1; }
  elsif (/^-rc-report$/)    { $rc_report = 1; }
  elsif (/^-rc-report-$/)   { $rc_report = 0; }
  elsif (/^-recorder$/ ){ $recorder = 1; }
  elsif (/^-recorder-$/ ){ $recorder = 0; }
  elsif (/^-rules$/ ) { $rules_list = 1; }
  elsif (/^-norules$/ || /^-rules-$/ ) { $rules_list = 0; }
  elsif (/^-showextraoptions$/) {
     print "List of extra latex and pdflatex options recognized by $my_name.\n",
           "These are passed as is to *latex.  They may not be recognized by\n",
           "particular versions of *latex.  This list is a combination of those\n",
           "for TeXLive and MikTeX.\n",
           "\n",
           "Note that in addition to the options in this list, there are several\n",
           "options known to the *latex programs that are also recognized by\n",
           "latexmk and trigger special behavior by latexmk.  Since these options\n",
           "appear in the main list given by running 'latexmk --help', they do not\n",
           "appear in the following list\n",
           "NOTE ALSO: Not all of these options are supported by all versions of *latex.\n",
           "\n";
     foreach $option ( sort( keys %allowed_latex_options, keys %allowed_latex_options_with_arg ) ) {
       if (exists $allowed_latex_options{$option} ) { print "   $allowed_latex_options{$option}\n"; }
       if (exists $allowed_latex_options_with_arg{$option} ) { print "   $allowed_latex_options_with_arg{$option}\n"; }
     }
     exit;
  }
  elsif (/^-silent$/ || /^-quiet$/ ){ $silent = 1; }
  elsif (/^-stdtexcmds$/) { &std_tex_cmds; }
  elsif (/^-time$/) { $show_time = 1;}
  elsif (/^-time-$/) { $show_time = 0;}
  elsif (/^-use-make$/)  { $use_make_for_missing_files = 1; }
  elsif (/^-use-make-$/)  { $use_make_for_missing_files = 0; }
  elsif (/^-usepretex$/) { &alt_tex_cmds; }
  elsif (/^-usepretex=(.*)$/) {
      &alt_tex_cmds;
      $pre_tex_code = $1;
  }
  elsif (/^-v$/ || /^-version$/)   { 
      print "$version_details\n";
      exit;
  }
  elsif (/^-verbose$/)  { $silent = 0; }
  elsif (/^-view=default$/) { $view = "default";}
  elsif (/^-view=dvi$/)     { $view = "dvi";}
  elsif (/^-view=none$/)    { $view = "none";}
  elsif (/^-view=ps$/)      { $view = "ps";}
  elsif (/^-view=pdf$/)     { $view = "pdf"; }
  elsif (/^-Werror$/){ $warnings_as_errors = 1; }
  elsif (/^-xdv$/)    { $xdv_mode = 1; }
  elsif (/^-xdv-$/)   { $xdv_mode = 0; }
  elsif ( /^-xelatex$/ || /^-pdfxelatex$/ )      { 
      $pdf_mode = 5;
      $dvi_mode = $postscript_mode = 0; 
  }
# See above for -xelatex=...
  elsif (/^-e$/) {  
     if ( $#ARGV < 0 ) {
        &exit_help( "No code to execute specified after -e switch"); 
     }
     execute_code_string( $ARGV[0] );
     shift;
  }
  elsif (/^-r$/) {  
     if ( $ARGV[0] eq '' ) {
        &exit_help( "No RC file specified after -r switch"); 
     }
     if ( -e $ARGV[0] ) {
         # Give process_rc_file a non-zero argument so that there is a warning
         # if $ARGV[0] has already been processed as an rc file:
         process_rc_file( $ARGV[0], 1 );
     } 
     else {
        die "$My_name: RC file [$ARGV[0]] does not exist\n"; 
     }
     shift; 
  }
  elsif (/^-bm$/) {
     if ( $ARGV[0] eq '' ) {
        &exit_help( "No message specified after -bm switch");
     }
     $banner = 1; $banner_message = $ARGV[0];
     shift; 
  }
  elsif (/^-bi$/) {
     if ( $ARGV[0] eq '' ) {
        &exit_help( "No intensity specified after -bi switch");
     }
     $banner_intensity = $ARGV[0];
     shift; 
  }
  elsif (/^-bs$/) {
     if ( $ARGV[0] eq '' ) {
        &exit_help( "No scale specified after -bs switch");
     }
     $banner_scale = $ARGV[0];
     shift; 
  }
  elsif (/^-dF$/) {
     if ( $ARGV[0] eq '' ) {
        &exit_help( "No dvi filter specified after -dF switch");
     }
     $dvi_filter = $ARGV[0];
     shift; 
  }
  elsif (/^-pF$/) {
     if ( $ARGV[0] eq '' ) {
        &exit_help( "No ps filter specified after -pF switch");
     }
     $ps_filter = $ARGV[0];
     shift; 
  }
  elsif ( ( exists( $allowed_latex_options{$_} ) )
          || ( /^(-.+)=/ && exists( $allowed_latex_options_with_arg{$1} ) )
        )
  {
      push @extra_dvilualatex_options, $original;
      push @extra_latex_options, $original;
      push @extra_pdflatex_options, $original;
      push @extra_lualatex_options, $original;
      push @extra_xelatex_options, $original;
  }
  elsif (/^-/) {
     warn "$My_name: $_ unknown option\n"; 
     $bad_options++;
  }
  else {
     push @command_line_file_list, $_ ; 
  }
}

if ( $diagnostics || $rc_report ) {
    show_array( "Rc files read:", @rc_files_read );
}

if ( $bad_options > 0 ) {
    &exit_help( "Bad options specified" );
}

print "$My_name: This is $version_details.\n",
   unless $silent;

&config_to_mine;

if ($out_dir eq '' ){
    # Default to cwd
    $out_dir = '.';
}
if ( $aux_dir eq '' ){
    # Default to out_dir
    #  ?? This is different than MiKTeX
    $aux_dir = $out_dir;
}
# Save original values for use in diagnositics.
# We may change $aux_dir and $out_dir after a detection
#  of results of misconfiguration.
$aux_dir_requested = $aux_dir;
$out_dir_requested = $out_dir;

if ($bibtex_use > 1) {
    push @generated_exts, 'bbl';
}

# For backward compatibility, convert $texfile_search to @default_files
# Since $texfile_search is initialized to "", a nonzero value indicates
# that an initialization file has set it.
if ( $texfile_search ne "" ) {
    @default_files = split /\s+/, "*.tex $texfile_search";
}

#Glob the filenames command line if the script was not invoked under a 
#   UNIX-like environment.
#   Cases: (1) MS/MSwin native    Glob
#                      (OS detected as MSWin32)
#          (2) MS/MSwin cygwin    Glob [because we do not know whether
#                  the cmd interpreter is UNIXy (and does glob) or is
#                  native MS-Win (and does not glob).]
#                      (OS detected as cygwin)
#          (3) UNIX               Don't glob (cmd interpreter does it)
#                      (Currently, I assume this is everything else)
if ( ($^O eq "MSWin32") || ($^O eq "cygwin") ) {
    # Preserve ordering of files
    @file_list = glob_list1(@command_line_file_list);
#print "A1:File list:\n";
#for ($i = 0; $i <= $#file_list; $i++ ) {  print "$i: '$file_list[$i]'\n"; }
}
else {
    @file_list = @command_line_file_list;
}
@file_list = uniq1( @file_list );


# Check we haven't selected mutually exclusive modes.
# Note that -c overrides all other options, but doesn't cause
# an error if they are selected.
if (($printout_mode && ( $preview_mode || $preview_continuous_mode ))
    || ( $preview_mode && $preview_continuous_mode ))
{
  # Each of the options -p, -pv, -pvc turns the other off.
  # So the only reason to arrive here is an incorrect inititalization
  #   file, or a bug.
  &exit_help( "Conflicting options (print, preview, preview_continuous) selected");
}

if ( @command_line_file_list ) {   
    # At least one file specified on command line (before possible globbing).
    if ( !@file_list ) {
        &exit_help( "Wildcards in file names didn't match any files");
    }
}
else {
    # No files specified on command line, try and find some
    # Evaluate in order specified.  The user may have some special
    #   for wanting processing in a particular order, especially
    #   if there are no wild cards.
    # Preserve ordering of files
    my @file_list1 = uniq1( glob_list1(@default_files) );
    my @excluded_file_list = uniq1( glob_list1(@default_excluded_files) );
    # Make hash of excluded files, for easy checking:
    my %excl = ();
    foreach my $file (@excluded_file_list) {
        $excl{$file} = '';
    }
    foreach my $file (@file_list1) {
        push( @file_list, $file)  unless ( exists $excl{$file} );
    }    
    if ( !@file_list ) {
        &exit_help( "No file name specified, and I couldn't find any");
    }
}

$num_files = $#file_list + 1;
$num_specified = $#command_line_file_list + 1;

#print "Command line file list:\n";
#for ($i = 0; $i <= $#command_line_file_list; $i++ ) {  print "$i: '$command_line_file_list[$i]'\n"; }
#print "File list:\n";
#for ($i = 0; $i <= $#file_list; $i++ ) {  print "$i: '$file_list[$i]'\n"; }


# If selected a preview-continuous mode, make sure exactly one filename was specified
if ($preview_continuous_mode && ($num_files != 1) ) {
    if ($num_specified > 1) {
        &exit_help( 
          "Need to specify exactly one filename for ".
              "preview-continuous mode\n".
          "    but $num_specified were specified"
        );
    }
    elsif ($num_specified == 1) {
        &exit_help( 
          "Need to specify exactly one filename for ".
              "preview-continuous mode\n".
          "    but wildcarding produced $num_files files"
        );
    }
    else {
        &exit_help( 
          "Need to specify exactly one filename for ".
              "preview-continuous mode.\n".
          "    Since none were specified on the command line, I looked for \n".
          "    files in '@default_files'.\n".
          "    But I found $num_files files, not 1."
        );
    }
}

# If selected jobname, can only apply that to one file:
if ( ($jobname ne '') && ($jobname !~ /%A/) && ($num_files > 1) ) {
    &exit_help( 
          "Need to specify at most one filename if ".
          "jobname specified without a %A, \n".
          "    but $num_files were found (after defaults and wildcarding)."
        );
}
if ( $jobname =~ /%[^A]/ ) {
    &exit_help( 
         "Jobname '$jobname' contains placeholder other than %A."
        );
}

# Normalize the commands, to have place-holders for source, dest etc:
&fix_cmds;

# Add common options
add_option( $dvilualatex_default_switches, \$dvilualatex );
add_option( $latex_default_switches,    \$latex );
add_option( $pdflatex_default_switches, \$pdflatex );
add_option( $lualatex_default_switches, \$lualatex );
add_option( $xelatex_default_switches,  \$xelatex );

foreach (@extra_dvilualatex_options) { add_option( $_, \$dvilualatex ); }
foreach (@extra_latex_options)    { add_option( $_, \$latex ); }
foreach (@extra_pdflatex_options) { add_option( $_, \$pdflatex ); }
foreach (@extra_lualatex_options) { add_option( $_, \$lualatex ); }
foreach (@extra_xelatex_options)  { add_option( $_, \$xelatex ); }


# If landscape mode, change dvips processor, and the previewers:
if ( $landscape_mode )
{
  $dvips = $dvips_landscape;
  $dvi_previewer = $dvi_previewer_landscape;
  $ps_previewer = $ps_previewer_landscape;
}

{ my $array_changed = 0;
  if ($#BIBINPUTS != $#BIBINPUTS_SAVE) { $array_changed = 1; }
  else {
      for( my $i = 0; $i <= $#BIBINPUTS; $i++ ) {
          if ($BIBINPUTS[$i] ne $BIBINPUTS_SAVE[$i]) {
              $array_changed = 1;
              last;
          }
      }
  }
  if ($array_changed) {
      foreach (@BIBINPUTS) { ensure_path( 'BIBINPUTS', $_ ); }
  }
}

if ( $silent ) { 
    add_option( "$dvilualatex_silent_switch", \$dvilualatex );
    add_option( "$latex_silent_switch", \$latex );
    add_option( "$pdflatex_silent_switch", \$pdflatex );
    add_option( "$lualatex_silent_switch", \$lualatex );
    add_option( "$xelatex_silent_switch", \$xelatex );
    add_option( "$biber_silent_switch", \$biber );
    add_option( "$bibtex_silent_switch", \$bibtex );
    add_option( "$makeindex_silent_switch", \$makeindex );
    add_option( "$dvipdf_silent_switch", \$dvipdf );
    add_option( "$dvips_silent_switch", \$dvips );
    add_option( "$xdvipdfmx_silent_switch", \$xdvipdfmx );
}

if ( $recorder ) {
    add_option( "-recorder", \$dvilualatex, \$latex, \$pdflatex, \$lualatex, \$xelatex );
}

# If the output and/or aux directories are specified, fix the *latex
#   commands to use them.
# N.B. We'll ensure that the directories actually exist only after a
#   possible cd to the document directory, since the directories can be
#   relative to the document.

if ( $jobname ne '' ) {
    # Since $jobname may include placeholder(s), put %R placeholder
    # in option, and let %R be substituted by actual jobname at runtime.
    add_option( "--jobname=%R", \$dvilualatex, \$latex, \$lualatex, \$pdflatex, \$xelatex );
}

# Make sure we make the kind of file we want to view:
if ( ($view eq 'dvi') && ($dvi_mode == 0) ) { $dvi_mode = 1; }
if ($view eq 'ps') { $postscript_mode = 1; }
if ( ($view eq 'pdf') && ($pdf_mode == 0) ) { 
    $pdf_mode = 1; 
}

# Make sure that we make something if all requests are turned off
unless ( $dvi_mode || $pdf_mode || $postscript_mode || $printout_mode || $xdv_mode )  {
    print "No specific requests made, so using default for $invoked_name.\n";
    ($dvi_mode, $postscript_mode, $pdf_mode, $xdv_mode )
        = @{$compilation_defaults{$invoked_name}};    
}


# Which kind of file do we preview?
if ( $view eq "default" ) {
    # If default viewer requested, use "highest" of dvi, ps and pdf
    #    that was requested by user.  
    # No explicit request means view dvi.
    $view = "dvi";
    if ( $postscript_mode ) { $view = "ps"; }
    if ( $pdf_mode ) { $view = "pdf"; }
}

# Determine requests.
if ( $banner ) { $postscript_mode = 1; }
if ( $dvi_mode ) {
    $requested_filetypes{'dvi'} = 1;
    if ( length($dvi_filter) != 0 ) { $requested_filetypes{'dviF'} = 1; }
}
if ( $postscript_mode ) {
    $requested_filetypes{'ps'} = 1;
    if ( length($ps_filter) != 0 )  { $requested_filetypes{'psF'} = 1; }
}

if ($pdf_mode > 5) {
    warn "$My_name: Non-allowed value of \$pdf_mode = $pdf_mode,",
        " replaced by 1.\n";
    $pdf_mode = 1;
}
if ( ($dvi_mode || $postscript_mode) && $pdf_mode ) {
    my %disallowed = ();
    foreach (1,4,5) { $disallowed{$_} = 1; }
    if ($disallowed{$pdf_mode}) {
        warn
            "$My_name: \$pdf_mode = $pdf_mode is incompatible with dvi and postscript modes\n",
            "  which are required by other requests.\n";
        if ($postscript_mode) { $pdf_mode = 2; }
        else { $pdf_mode = 3; }
        warn
            "  I replaced it by $pdf_mode, to be compatible with those other requests.\n";
    }
}
if ( $pdf_mode == 0 ) {
    $pdf_method = '';
}
elsif ( $pdf_mode == 1 ) { 
    $requested_filetypes{'pdf'} = 1;
    $pdf_method = 'pdflatex';
}
elsif ( $pdf_mode == 2 ) { 
    $requested_filetypes{'pdf'} = 1;
    $pdf_method = 'ps2pdf';
}
elsif ( $pdf_mode == 3 ) { 
    $requested_filetypes{'pdf'} = 1;
    $pdf_method = 'dvipdf';
}
elsif ( $pdf_mode == 4 ) { 
    $requested_filetypes{'pdf'} = 1;
    $pdf_method = 'lualatex';
}
elsif ( $pdf_mode == 5 ) { 
    $requested_filetypes{'pdf'} = 1;
    $pdf_method = 'xelatex';
}

if ($print_type eq 'auto') {
    if ( $postscript_mode ) { $print_type = 'ps'; }
    elsif ( $pdf_mode )     { $print_type = 'pdf'; }
    elsif ( $dvi_mode )     { $print_type = 'dvi'; }
    else                    { $print_type = 'none'; }
}
if ( $printout_mode ) {
    $one_time{'print'} = 1;
    if ($print_type eq 'none'){
        warn "$My_name: You have requested printout, but \$print_type is set to 'none'\n";
    }
}
if ( $preview_continuous_mode || $preview_mode ) { $one_time{'view'} = 1; }

$can_switch = $allow_switch;
if ( $dvi_mode || $postscript_mode || $xdv_mode
     || ( $printout_mode && ($print_type eq 'ps') || ($print_type eq 'dvi') )
     || ( ($preview_mode || $preview_continuous_mode)  &&  ( ($view eq 'ps') || ($view eq 'dvi') ) )
   ) {
    # Automatic switching (e.g., pdf<->dvi o/p) requires pdf files to be
    # the only destinations.  So if ps or dvi files needed, we cannot
    # allow switching.  (There will then be an error condition if a TeX
    # engine fails to produce the correct type of output file.)
    if ($diagnostics) {
        warn "$My_name: Disallowing switch of output file as incompatible\n",
             "    with file requests.\n";
    }
    $can_switch = 0;
}


if ( $pdf_mode == 2 ) {
    # We generate pdf from ps.  Make sure we have the correct kind of ps.
    add_option( "$dvips_pdf_switch", \$dvips );
}

# Note sleep has granularity of 1 second.
# Sleep periods 0 < $sleep_time < 1 give zero delay,
#    which is probably not what the user intended.
# Sleep periods less than zero give infinite delay
if ( $sleep_time == 0 ) {
     warn "$My_name: sleep_time was configured to zero.\n",
    "    Do you really want to do this?  It can give 100% CPU usage.\n";
}
elsif ( $sleep_time < 1 ) {
     warn "$My_name: Correcting nonzero sleep_time of less than 1 sec to 1 sec.\n";
     $sleep_time = 1;
}


# Standardize specifications for generated file extensions:
#
# Remove leading and trailing space in the following space-separated lists,
# and collapse multiple spaces to one,
# to avoid getting incorrect blank items when they are split.
foreach ($clean_ext, $clean_full_ext) { s/^\s+//; s/\s+$//; s/\s+/ /g; }
# Put everything in the arrays:
push @generated_exts,  split('\s+',$clean_ext);
push @final_output_exts,  split('\s+',$clean_full_ext);

# Convert the arrays to hashes, for ease of deletion:
# Keep extension without period!
%generated_exts = ();
foreach (@generated_exts ) { $generated_exts{$_} = 1; }

$quell_uptodate_msgs = $silent; 
   # Whether to quell informational messages when files are uptodate
   # Will turn off in -pvc mode

$failure_count = 0;
@failed_primaries = ();

if ($deps_file eq '' ) {
    # Standardize name used for stdout
    $deps_file = '-';
}

# Since deps_file is global (common to all processed files), we must
# delete it here when doing a clean up, and not in the FILE loop, where
# per-file processing (including clean-up) is done
if ( ($cleanup_mode > 0) &&  $dependents_list && ( $deps_file ne '-' ) ) {
    unlink_or_move( $deps_file );
}

# In non-pvc mode, the dependency list is global to all processed TeX files,
#   so we open a single file here, and add items to it after processing
#   each file.  But in -pvc mode, the dependency list should be written
#   after round of processing the single TeX file (as if each round were
#   a separate run of latexmk).
# If we are cleaning up ($cleanup_mode != 0) AND NOT continuing to
#   make files (--gg option and $go_mode == 2), deps_file should not be
#   created.
# I will use definedness of $deps_handle as flag for global deps file having
#   been opened and therefore being available to be written to after
#   compiling a file.

$deps_handle = undef;
if ( $dependents_list
     && ! $preview_continuous_mode
     && ( ($cleanup_mode == 0) || ($go_mode == 2) )
   ) {
    open( $deps_handle, ">$deps_file" );
    if (! $deps_handle ) {
        die "Cannot open '$deps_file' for output of dependency information\n";
    }
}

# Deal with illegal and problematic characters in filename:
test_fix_texnames( @file_list );

$quote = $quote_filenames ? '"' : '';

FILE:
foreach $filename ( @file_list )
{
    # Global variables for making of current file:
    $updated = 0;
    $failure = 0;        # Set nonzero to indicate failure at some point of 
                         # a make.  Use value as exit code if I exit.
    $failure_msg = '';   # Indicate reason for failure

    if ( $do_cd ) {
       ($filename, $path) = fileparse( $filename );
       print "$My_name: Changing directory to '$path'\n"
           if !$silent;
       pushd( dirname_no_tail( $path ) );
    }
    else {
        $path = '';
    }

    # Localize the following, because they may get changed because of
    # conditions specific to the current tex file, notably:
    #   Change of emulation state of aux_dir
    #   Use of $do_cd, which can affect how $aux_dir and $out_dir get normalized.
    local $aux_dir = $aux_dir;
    local $out_dir = $out_dir;

    local $dvilualatex = $dvilualatex;
    local $latex = $latex;
    local $lualatex = $lualatex;
    local $pdflatex = $pdflatex;
    local $xelatex = $xelatex;

    &normalize_aux_out_ETC;
    # Set -output-directory and -aux-directory options for *latex here,
    # since at least: Their method of use depends on the dynamically
    # set $emulate_aux, and the exact strings for the directory names are
    # not known until after the call to normalize_aux_out_ETC:
    &set_aux_out_options;
    &set_names;   # Names of standard files
    
    # For use under error conditions:
    @default_includes = ($texfile_name, $aux_main);
    # Set rules here for current conditions
    &rdb_initialize_rules;
    $view_file = '';
    rdb_one_rule( 'view', sub{ $view_file = $$Psource; } );

    if ( $diagnostics ) {
       print "$My_name: Rules after start up for '$texfile_name'\n";
       rdb_show();
    }

    if ($cleanup_fdb) {
        print "$My_name: Deleting '$fdb_name' (file of cached information)\n";
        unlink_or_move( $fdb_name );
    }

    # Set rules from fdb_latexmk file, if possible.
    # Allow adaptation of output extension for primary rule to cached
    # value, but not if we are doing a cleanup (since then the rules
    # will all be reset after the cleanup).
    if ( -e $fdb_name ) {
        if (0 != rdb_read( $fdb_name, $cleanup_mode ) ) {
            # There were some problems with the file of cached rules, so
            # the  resulting set of rules may be problematic: file status
            # data may be incorrect.
            # So use filetime criterion for make instead of file change from
            # previous run, until we have done our own make.
            #   ???!!! CHECK: WHY ONLY PRIMARIES????
            rdb_recurse( [$current_primary],
                         sub{ $$Pno_history = 1; }
            );
        }
    }
    elsif ( -e $log_name ) {
        # At least we can use dependency information from previous run of
        # *latex, which may not have been under latexmk control, otherwise
        # the fdb_latexmk file would have been made.
        rdb_for_some( [$current_primary],
                      sub{ rdb_set_latex_deps($cleanup_mode) }
                    );
        &rdb_set_rule_net;
    }

    # At this point, the file and rule databases are correctly initialized
    # either from the fdb_latexmk database (corresponding to the state at
    # the end of the previous run of latexmk), or from default initialization,
    # assisted by dependency information from log files about previous
    # run, if the log file exists.

    if ( $cleanup_mode ) { do_cleanup( $cleanup_mode ); }
    if ($cleanup_only) { next FILE; }

    if ( ! -e $aux_main ) {
        # No aux file => set up trivial aux file 
        #    and corresponding fdb_file.  Arrange them to provoke one run 
        #    as minimum, but no more if actual aux file is trivial.
        #    (Useful on short simple files.)
        # If aux file doesn't exist, then any fdb file is surely
        #    wrong. So updating it to current state is sensible.
        print( "No existing .aux file, so I'll make a simple one, and require run of *latex.\n")
            unless $silent;
        &set_trivial_aux_fdb;
    }

    if ($go_mode == 3) {
        # Force primaries to be remade.
        if (!$silent) { print "Force *latex to be remade.\n"; }
        rdb_for_some( [keys %possible_primaries], sub{$$Pout_of_date=1;}  );
    }
    elsif ($go_mode) {
        # Force everything to be remade.
        if (!$silent) { print "Force everything to be remade.\n"; }
        rdb_recurse( [ &rdb_target_array], sub{$$Pout_of_date=1;}  );
    }


    if ( $diagnostics ) {
       print "$My_name: Rules after initialization\n";
       rdb_show();
    }

    #************************************************************

    if ( $preview_continuous_mode ) { 
        &make_preview_continuous; 
        next FILE;
    }


## Handling of failures:
##    Variable $failure is set to indicate a failure, with information
##       put in $failure_msg.  
##    These variables should be set to 0 and '' at any point at which it
##       should be assumed that no failures have occurred.
##    When after a routine is called it is found that $failure is set, then
##       processing should normally be aborted, e.g., by return.
##    Then there is a cascade of returns back to the outermost level whose 
##       responsibility is to handle the error.
##    Exception: An outer level routine may reset $failure and $failure_msg
##       after initial processing, when the error condition may get 
##       ameliorated later.
    #Initialize failure flags now.
    $failure = 0;
    $failure_msg = '';
    &init_timing1;

    if ($compiling_cmd) { Run_subst( $compiling_cmd ); }
    $failure = &rdb_make;
    if ( ( $failure <= 0 ) || $force_mode ) {
      rdb_for_some( [keys %one_time], \&rdb_run1 );
    }
    if ($#primary_warning_summary > -1) {
        # N.B. $mult_defined, $bad_reference, $bad_character, $bad_citation also available here.
        if ($warnings_as_errors) {
            $failure = 1;
            $failure_msg = "Warning(s) from latex (or c.) for '$filename'; treated as error";
        }
    }
    
    if ($failure > 0) {
        if ($failure_cmd) { Run_subst( $failure_cmd ); }
        next FILE;
    } else {
        if ($success_cmd) { Run_subst( $success_cmd ); }
    }
} # end FILE
continue {
    if ($deps_handle) { deps_list($deps_handle); }
    # If requested, print the list of rules.  But don't do this in -pvc
    # mode, since the rules list has already been printed.
    if ($rules_list && ! $preview_continuous_mode) { rdb_list(); }
    # Handle any errors
    $error_message_count = rdb_show_rule_errors();
    if ( ($error_message_count == 0) || ($failure > 0) ) {
        if ( $failure_msg ) {
            #Remove trailing space
            $failure_msg =~ s/\s*$//;
            warn "----------------------\n";
            warn "This message may duplicate earlier message.\n";
            warn "$My_name: Failure in processing file '$filename':\n",
                 "   $failure_msg\n";
            warn "----------------------\n";
            $failure = 1;
        }
    }
    if ( ($failure > 0) || ($error_message_count > 0) ) {
        $failure_count ++;
        push @failed_primaries, $filename;
    }
    &ifcd_popd;
    if ($show_time) { &show_timing1; };
    print "\n";
}
close($deps_handle) if ( $deps_handle );

if ( $show_time && ( ($#file_list > 0) || $preview_continuous_mode ) ) {
    print "\n";
    show_timing_grand();
}

# If we get here without going through the continue section:
if ( $do_cd && ($#dir_stack > -1) ) {
   # Just in case we did an abnormal exit from the loop
   warn "$My_name: Potential bug: dir_stack not yet unwound, undoing all directory changes now\n";
   &finish_dir_stack;
}

if ($filetime_offset_measured) {
    if ( (abs($filetime_offset) >= $filetime_offset_report_threshold)
         && ($diagnostics || ! $silent) )
    {
        warn "$My_name: I am working around an offset relative to my system time by\n",
             "   $filetime_offset secs for file times in directory '$aux_dir1'.\n",
             "   This **probably** indicates that \n",
             "   (a) I ($my_name) am running on one computer, while the filesystem is\n",
             "       hosted on a different computer/\n",
             "   (b) There is a substantial time offset between system times on the two\n",
             "       computers.\n",
             "   (c) Therefore at least one of the computers has a misconfigured operating\n",
             "       system such that its system time is not correctly synchronized with a\n",
             "       time server.\n",
             "   These issues are likely to cause problems with other software, and any\n",
             "   such operating-system misconfigurations should be corrected.  By default\n",
             "   current operating systems are configured to correctly synchronize system\n",
             "   time when they are connected to the Internet\n";
    }
}

if ($failure_count > 0) {
    if ( $#file_list > 0 ) {
        # Error occured, but multiple files were processed, so
        #     user may not have seen all the error messages
        warn "\n------------\n";
        warn_array( 
           "$My_name: Some operations failed, for the following tex file(s)", 
           @failed_primaries);
    }
    if ( !$force_mode ) {
        warn
            "$My_name: If appropriate, the -f option can be used to get latexmk\n",
            "  to try to force complete processing.\n";
    }
    exit 12;
}

if ( $emulate_aux_switched ) {
    warn "$My_name: I had to switch emulate-aux-dir on after it was initially off,\n",
         "  because your *latex program appeared not to support -aux-directory. You\n",
         "  probably should either use the option -emulate-aux-dir, or in a\n",
         "  latexmkrc file set \$emulate_aux = 1;\n";
}

# end MAIN PROGRAM

#############################################################
#############################################################

# Subroutines for working with processing time

############################

sub add_timing {
    # Usage: add_timing( time_for_run, rule );
    # Adds time_for_run to @timings1, @timings0
    my ( $time, $rule ) = @_; 
    push @timings1, "'$rule': time = " . sprintf('%.2f',$time) . "\n";
    push @timings0, "'$rule': time = " . sprintf('%.2f',$time) . "\n";
}

############################

sub init_timing1 {
    # Initialize timing for one run.
    @timings1 = ();
    $processing_time1 = processing_time();    
}

############################

sub init_timing_all {
    # Initialize timing for totals and for one run:
    @timings0 = ();
    $processing_time0 = processing_time();
    &init_timing1;
}

############################

sub show_timing1 {
    # Show timing for one run.
    my $processing_time = processing_time() - $processing_time1;
    print @timings1, "Processing time = ",
          sprintf('%.2f', $processing_time), "\n";
    print "Number of rules run = ", 1+$#timings1, "\n";
}

############################

sub show_timing_grand {
    # Show grand total timing.
    my $processing_time = processing_time() - $processing_time0;
    print # @timings0,
          "Grand total processing time = ",
          sprintf('%.2f', $processing_time), "\n";
    print "Total number of rules run = ", 1+$#timings0, "\n";
}

#############################################################
#############################################################

sub set_tex_cmds {
    # Usage, e.g., set_tex_cmds( '%O %S' )
    #             or  set_tex_cmds( '%C-dev %O %S' )
    my $args = $_[0];
    foreach my $cmd ( keys %possible_primaries ) {
        my $spec = $args;
        if ( $spec =~ /%C/ ) { $spec =~ s/%C/$cmd/g; }
        else { $spec = "$cmd $args"; }
        ${$cmd} = $spec;
    }
    # N.B. See setting of $latex_default_switches, ...,
    # $xelatex_default_switches, etc, for any special options needed.
}

sub std_tex_cmds { set_tex_cmds( '%O %S' ); }

sub alt_tex_cmds { set_tex_cmds( '%O %P' ); }

#========================

sub test_fix_texnames {
    my $illegal_char = 0;
    my $unbalanced_quote = 0;
    my $balanced_quote = 0;
    foreach (@_) {
        if ( ($^O eq "MSWin32") || ($^O eq "msys") ) {
            # On MS-Win, change directory separator '\' to '/', as needed
            # by the TeX engines, for which '\' introduces a macro name.
            # Remember that '/' is a valid directory separator in MS-Win.
            s[\\][/]g;
        }
        if ($do_cd) {
           my ($filename, $path) = fileparse( $_ );
           if ($filename =~ /[\Q$illegal_in_texname\E]/ )  {
              $illegal_char++;
              warn "$My_name: Filename '$filename' contains character not allowed for TeX file.\n";
           }
           if ($filename =~ /^&/) {
              $illegal_char++;
              warn "$My_name: Filename '$filename' contains initial '&', which is\n",
                   "   not allowed for TeX file.\n";
           }
        }
        else {
           if ( /[\Q$illegal_in_texname\E]/ ) {
              $illegal_char++;
              warn "$My_name: Filename '$_' contains character not allowed for TeX file.\n";
           }
           if (/^&/ ) {
              $illegal_char++;
              warn "$My_name: Filename '$_' contains initial '&', which is not allowed\n",
                   "   for TeX file.\n";
           }
        }
        my $count_q = ($_ =~ tr/\"//);
        if ( ($count_q % 2) != 0 ) {
            warn "$My_name: Filename '$_' contains unbalanced quotes, not allowed.\n";
            $unbalanced_quote++;
        }
        elsif ( $count_q > 0 ) {
            print "$My_name: Removed (balanced quotes) from filename '$_',\n";
            s/\"//g;
            print "   and obtained '$_'.\n";
            $balanced_quote++;
        }
    }
    if ($illegal_char || $unbalanced_quote) {
        die "$My_name: Stopping because of bad filename(s).\n";
    }
}

#############################################################

sub ensure_path {
    # Usage: ensure_path( var, values ...)
    # $ENV{var} is an environment variable (e.g. $ENV{TEXINPUTS}.
    # Ensure the values are in it, prepending them if not, and
    # creating the environment variable if it doesn't already exist.
    my $var = shift;
    my %cmpts = ();
    if ( exists $ENV{$var} ) {
        foreach ( split $search_path_separator, $ENV{$var} ) {
            if ($_ ne '') { $cmpts{$_} = 1; }
        }
    }
    foreach (@_) {
        next if ( ($_ eq '') || (exists $cmpts{$_}) );
        if (exists $ENV{$var}) {
            $ENV{$var} = $_ . $search_path_separator . $ENV{$var};
        }
        else {
            $ENV{$var} = $_ . $search_path_separator;
        }
        if ($diagnostics) {
            print "Set environment variable $var='$ENV{$var}'\n";
        }
    }
} #END ensure_path

#############################################################

sub path_fudge {
    # Usage: path_fudge( var1[, var2 ...])
    # For each argument, $ENV{var} is an environment variable
    #   (e.g. $ENV{BIBINPUTS}, that is a search path. 
    # Adjust each of these environment variables so that it is
    #   appropriately set for use when a program is run with a changed wd,
    #   as with bibtex when $bibtex_fudge is set.
    # Specifically:
    #   1. Prepend current wd to each $ENV{var}, if it exists; otherwise
    #      set $ENV{var} to current wd followed by search-path separator,
    #      so that search path is cwd and then default.
    #      Hence files in cwd are found by a program run in another
    #      directory.
    #   2. For each item in $ENV{var} that isn't an absolute path, i.e.,
    #      that is relative, replace it by itself followed by the same path
    #      converted to an absolute path, with the relative path being
    #      assumed to be relative to the current wd. 
    #      Hence a program run in another directory finds files that were
    #      originally intended to be in a directory relative to the orginal
    #      cwd. In addition, in the conceivable case that the item in the
    #      search path is actually intended to be relative to the directory
    #      in which the program is run (normally the aux dir), it also
    #      works correctly.
    
    my $cwd = good_cwd();
    foreach my $var ( @_ ) {
        if ( exists $ENV{$var} ) {
            $ENV{$var} = $cwd.$search_path_separator.$ENV{$var};
        }
        else {
            $ENV{$var} = $cwd.$search_path_separator;
        }

        my @items = split_search_path( $search_path_separator, '', $ENV{$var} );
        my $changed = 0;

        foreach (@items) {
            if ($_ eq '' ) {
                # Empty item => std search path => nothing to do.
            }
            elsif ( ! file_name_is_absolute($_) ) {
               my $abs = rel2abs($_);
               $_ .= $search_path_separator.$abs;
               $changed = 1;
            }
        }

        if ($changed) {
            # Correct the env. var.
            $ENV{$var} = join( $search_path_separator, @items );
            print "====== ENV{$var} changed to '$ENV{$var}'\n";
         }
    }  # END loop over env. vars.
} #END path_fudge

#############################################################

sub normalize_aux_out_ETC {
    # 1. Normalize $out_dir and $aux_dir, so that if they have a non-trivial last
    #    component, any trailing '/' is removed.
    # 2. They should be non-empty.
    # 3. Set $out_dir1 and $aux_dir1 to have a directory separator character
    #    '/' added if needed to give forms suitable for direct concatenation with
    #    a filename.  These are needed for substitutions like %Y%R.
    #    Nasty cases of dir_name: "/"  on all systems,  "A:", "A:/" etc on MS-Win
    # 4. Set some TeX-related environment variables.
    # 5. Ensure the aux and out directories exist

    # Ensure the output/auxiliary directories exist, if need be, **with error checking**.
    my $ret1 = 0;
    my $ret2 = 0;
    eval {
        if ( $out_dir ) {
            $ret1 = make_path_mod( $out_dir,  'output' );
        }
        if ( $aux_dir && ($aux_dir ne $out_dir) ) {
            $ret2 = make_path_mod( $aux_dir,  'auxiliary' );
        }
    };
    if ($ret1 || $ret2 || $@ ) {
        if ($@) { print "Error message:\n  $@"; }
        die "$My_name: Since there was trouble making the output (and aux) dirs, I'll stop\n"
    }

    if ($normalize_names) {
        foreach ( $aux_dir, $out_dir ) { $_ = normalize_filename_abs($_); }
    }
    $aux_dir1 = $aux_dir;
    $out_dir1 = $out_dir;
    foreach ( $aux_dir1, $out_dir1 ) {
        if ($_ eq '.') {$_ = '';}
        if ( ($_ ne '')  && ! m([\\/\:]$) ) {
            # Add a trailing '/' if necessary to give a string that can be
            # correctly concatenated with a filename:
            $_ .= '/';
        }
    }
    if ($aux_dir) {
        # Ensure $aux_dir is in BIBINPUTS and TEXINPUTS search paths.
        # TEXINPUTS is used by dvips for files generated by mpost.
        # For BIBINPUTS, 
        # at least one widely package (revtex4-1) generates a bib file
        # (which is used in revtex4-1 for putting footnotes in the reference
        # list), and bibtex must be run to use it.  But latexmk needs to
        # determine the existence of the bib file by use of kpsewhich, otherwise
        # there is an error.  So cope with this situation (and any analogous
        # cases by adding the aux_dir to the relevant path search environment
        # variables.  BIBINPUTS seems to be the only one currently affected.
        # Convert $aux_dir to absolute path to make the search path invariant
        # under change of directory.
        foreach ( 'BIBINPUTS', 'TEXINPUTS' ) {
            ensure_path( $_, $aux_dir );
        }
        # Set TEXMFOUTPUT  so that when the aux_dir is not a subdirectory
        # of the cwd (or below), bibtex and makeindex can write to it.
        # Otherwise, security precautions in these programs will prevent
        # them from writing there, on TeXLive.  MiKTeX is different: see
        # below.
        # The security issues concern **document-controlled** writing of
        # files, when bibtex or makeindex is invoked directly by a
        # document. In contrast, here $aux_dir is set by latexmk, not by
        # the document. (See the main texmf.cnf file in a TeXLive
        # distribution for some information on security issues.)
        #
        # PROPERTIES:
        # 1. In TeXLive, the use of TEXMFOUTPUT works if
        #    (a) the directory given is an an absolute path,
        #    AND (b) the path contains no .. pieces
        #    AND (c) the directory component of the filename(s) on the command
        #       line for makeindex and bibtex is exactly the same string as
        #       for the directory named in TEXMFOUTPUT.
        # 2. In MiKTeX, bibtex has none of the security restrictions; but
        #    makeindex has, and the use of TEXMFOUTPUT has no effect.
        # So the following is only needed for TeXLive.
        $ENV{TEXMFOUTPUT} = $aux_dir;
    }
    
    if ($diagnostics || $aux_out_dir_report ) {
        print "$My_name: Cwd: '", good_cwd(), "'\n";
        print "$My_name: Normalized aux dir and out dir: '$aux_dir', '$out_dir'\n";
        print "$My_name: and combining forms: '$aux_dir1', '$out_dir1'\n";
    }

}  #END normalize_aux_out_ETC

#############################################################

sub set_aux_out_options {
    # Set -output-directory and -aux-directory options for *latex.  Use
    # placeholders for substitutions so that correct value is put in at
    # runtime.
    # N.B. At this point, $aux_dir and $out_dir should be non-empty, unlike the
    #      case after the reading of latexmkrc files, where empty string means
    #      use default.  Let's be certain, however:
    if ($out_dir eq '') { $out_dir = '.'; $out_dir1 = ''; }
    if ($aux_dir eq '') { $aux_dir = $out_dir; $aux_dir1 = $out_dir1; }
    
    if ($emulate_aux) {
        if ( $aux_dir ne '.' ) {
            # N.B. Set **output** directory to **aux_dir**, rather than
            # out_dir. If aux and out dirs are are different, then we'll move
            # the relevant files (.pdf, .ps, .dvi, .xdv, .fls to the output
            # directory after running *latex.
            add_option( "-output-directory=%V",
                        \$dvilualatex, \$latex, \$pdflatex, \$lualatex, \$xelatex );
        }
    }
    else {
        if ( $out_dir && ($out_dir ne '.') ) {
            add_option( "-output-directory=%W",
                        \$dvilualatex, \$latex, \$pdflatex, \$lualatex, \$xelatex );
        }
        if ( $aux_dir ne $out_dir ) {
            # N.B. If $aux_dir and $out_dir are the same, then the
            # -output-directory option is sufficient, especially because
            # the -aux-directory exists only in MiKTeX, not in TeXLive.
            add_option( "-aux-directory=%V",
                            \$dvilualatex, \$latex, \$pdflatex, \$lualatex, \$xelatex );
        }
    }
} #END set_aux_out_options

#############################################################

sub fix_cmds {
   # If commands do not have placeholders for %S etc, put them in
    foreach ($latex, $lualatex, $pdflatex, $xelatex, $lpr, $lpr_dvi, $lpr_pdf,
             $pdf_previewer, $ps_previewer, $ps_previewer_landscape,
             $dvi_previewer, $dvi_previewer_landscape,
             $kpsewhich
    ) {
        # Source only
        if ( $_ && ! /%/ ) { $_ .= " %O %S"; }
    }
    foreach ($pdf_previewer, $ps_previewer, $ps_previewer_landscape,
             $dvi_previewer, $dvi_previewer_landscape,
    ) {
        # Run previewers detached
        if ( $_ && ! /^(nostart|NONE|internal) / ) {
            $_ = "start $_";
        }
    }
    foreach ($biber, $bibtex) {
        # Base only
        if ( $_ && ! /%/ ) { $_ .= " %O %B"; }
    }
    foreach ($dvipdf, $ps2pdf) {
        # Source and dest without flag for destination
        if ( $_ && ! /%/ ) { $_ .= " %O %S %D"; }
    }
    foreach ($dvips, $makeindex) {
        # Source and dest with -o dest before source
        if ( $_ && ! /%/ ) { $_ .= " %O -o %D %S"; }
    }
    foreach ($dvi_filter, $ps_filter) {
        # Source and dest, but as filters
        if ( $_ && ! /%/ ) { $_ .= " %O <%S >%D"; }
    }
} #END fix_cmds

#############################################################

sub add_option {
    # Call add_option( $opt, \$cmd ... )
    # Add option to one or more commands
    my $option = shift;
    while (@_) {
        if ( ${$_[0]} !~ /%/ ) { &fix_cmds; }
        ${$_[0]} =~ s/%O/$option %O/;
        shift;
    }
} #END add_option

#############################################################

sub rdb_initialize_rules {
    # Initialize rule database.
    #   (The rule database may get overridden/extended after the fdb_latexmk
    #    file is read, and after running commands to adjust to dependencies
    #    determined from document.
    %rule_db = ();
    %target_rules = ();
    %target_files = ();

    local %rule_list = ();
    &rdb_set_rule_templates;

    my %rule_template = %rule_list;
    while ( my ($key, $value) = each %extra_rule_spec ) {
        $rule_template{$key} = $value;
    }
    #   ???!!!  REVISE
    foreach my $rule ( keys %rule_template ) {
        my ( $cmd_type, $ext_cmd, $int_cmd, $source, $dest, $base,
             $DUMMY, $PA_extra_gen, $PA_extra_source )
            = @{$rule_template{$rule}};
        if ( ! $PA_extra_gen ) { $PA_extra_gen = []; }
        if ( ! $PA_extra_source ) { $PA_extra_source = []; }
        my $needs_making = 0;
        # Substitute in the filename variables, since we will use
        # those for determining filenames.  But delay expanding $cmd 
        # until run time, in case of changes.
        foreach ($base, $source, $dest, @$PA_extra_gen, @$PA_extra_source ) {
            s/%R/$root_filename/g;
            s/%Y/$aux_dir1/;
            s/%Z/$out_dir1/;
        }
        foreach ($source, $dest ) { 
            s/%B/$base/;
            s/%T/$texfile_name/;
        }
        rdb_create_rule( $rule, $cmd_type, $ext_cmd, $int_cmd, $DUMMY, 
                         $source, $dest, $base,
                         $needs_making, undef, undef, 1, $PA_extra_gen, $PA_extra_source );
    } # End rule iteration

    # At this point, all the rules are active.
    # The rules that are used are determined by starting with the desired
    # final files and going backwards in the rule network to find what rules
    # have to be run to make the final files.
    # The only problem in doing this is if there is more than one way of making
    # a given file.  This arises only for rules that make pdf or dvi files,
    # since we have multiple rules for making them.

    # Ensure we only have one way to make pdf file, and only one active primary:
    # Deactivate pdf-making rules and primary rules,
    # then reactivating only one pdf producing rule and current primary,
    # setting $current_primary as side-effect.
    
    rdb_deactivate( 'dvipdf', 'ps2pdf', 'xdvipdfmx', keys %possible_primaries );

    $current_primary = 'latex';  # 
    # Activate needed non-primary pdf-making rules, set current primary (if
    # it isn't latex, and activate the current primary:
    if       ($pdf_mode == 1) { $current_primary = 'pdflatex'; }
    elsif    ($pdf_mode == 2) { rdb_activate( 'ps2pdf' ); }
    elsif    ($pdf_mode == 3) { rdb_activate( 'dvipdf' ); }
    elsif    ($pdf_mode == 4) { $current_primary = 'lualatex'; }
    elsif    ($pdf_mode == 5) { rdb_activate( 'xdvipdfmx' ); $current_primary = 'xelatex';  }
    if ($dvi_mode == 2) { $current_primary = 'dvilualatex'; }

    rdb_activate( $current_primary );
    
    if ($dvi_mode) { $target_files{$dvi_final} = 1; }
    if ($postscript_mode) { $target_files{$ps_final} = 1; }
    if ($pdf_mode) { $target_files{$pdf_final} = 1; }
    if ($xdv_mode) { $target_files{$xdv_final} = 1; }

    &rdb_set_rule_net;
} # END rdb_initialize_rules

#************************************************************

sub rdb_set_rule_templates {
# Set up specifications for standard rules, adjusted to current conditions
# Substitutions: %S = source, %D = dest, %B = this rule's base
#                %T = texfile, %R = root = base for latex.
#                %Y for $aux_dir1, %Z for $out_dir1


    my $print_file = '';
    my $print_cmd = 'NONE';
    if ( $print_type eq 'dvi' ) {
        $print_file = $dvi_final;
        $print_cmd = $lpr_dvi;
    }
    elsif ( $print_type eq 'pdf' ) {
        $print_file = $pdf_final;
        $print_cmd = $lpr_pdf;
    }
    elsif ( $print_type eq 'ps' ) {
        $print_file = $ps_final;
        $print_cmd = $lpr;
    }
    elsif ( $print_type eq 'none' ) {
        $print_cmd = 'NONE echo NO PRINTING CONFIGURED';
    }

    my $view_file = '';
    my $viewer = '';
    my $viewer_update_method = 0;
    my $viewer_update_signal = undef;
    my $viewer_update_command = undef;

    if ( ($view eq 'dvi') || ($view eq 'pdf') || ($view eq 'ps') ) { 
        $view_file = ${$view.'_final'};
        $viewer = ${$view.'_previewer'};
        $viewer_update_method = ${$view.'_update_method'};
        $viewer_update_signal = ${$view.'_update_signal'};
        if (defined ${$view.'_update_command'}) {
           $viewer_update_command = ${$view.'_update_command'};
        }
    }
    # Specification of internal command for viewer update:
    my $PA_update = ['do_update_view', $viewer_update_method, $viewer_update_signal, 0, 1];

    %rule_list = (
        'dvilualatex'  => [ 'primary',  "$dvilualatex",  '',      "%T",        $dvi_name,  "%R",   1, [$aux_main, $log_name], [$aux_main] ],
        'latex'     => [ 'primary',  "$latex",     '',            "%T",        $dvi_name,  "%R",   1, [$aux_main, $log_name], [$aux_main] ],
        'lualatex'  => [ 'primary',  "$lualatex",  '',            "%T",        $pdf_name,  "%R",   1, [$aux_main, $log_name], [$aux_main] ],
        'pdflatex'  => [ 'primary',  "$pdflatex",  '',            "%T",        $pdf_name,  "%R",   1, [$aux_main, $log_name], [$aux_main] ],
        'xelatex'   => [ 'primary',  "$xelatex",   '',            "%T",        $xdv_name,  "%R",   1, [$aux_main, $log_name], [$aux_main] ],
        'dvipdf'    => [ 'external', "$dvipdf",    'do_viewfile', $dvi_final,  $pdf_name,  "%Z%R", 1 ],
        'xdvipdfmx' => [ 'external', "$xdvipdfmx", 'do_viewfile', $xdv_final,  $pdf_name,  "%Z%R", 1 ],
        'dvips'     => [ 'external', "$dvips",     'do_viewfile', $dvi_final,  $ps_name,   "%Z%R", 1 ],
        'dvifilter' => [ 'external', $dvi_filter,  'do_viewfile', $dvi_name,   $dviF_name, "%Z%R", 1 ],
        'ps2pdf'    => [ 'external', "$ps2pdf",    'do_viewfile', $ps_final,   $pdf_name,  "%Z%R", 1 ],
        'psfilter'  => [ 'external', $ps_filter,   'do_viewfile', $ps_name,    $psF_name,  "%Z%R", 1 ],
        'print'     => [ 'external', "$print_cmd", 'if_source',   $print_file, "",         "",     1 ],
        'update_view' => [ 'external', $viewer_update_command, $PA_update,
                               $view_file,  "",        "",   2 ],
        'view'     => [ 'external', "$viewer",    'if_source',   $view_file,  "",        "",   2 ],
    );
} # END rdb_set_rule_templates 

#************************************************************

sub rdb_set_rule_net {
    # Set network of rules, including links and classifications.
    #
    # ?? Problem if there are multiple rules for getting a file.  Notably pdf.
    #    Which one to choose?
    # ?? Problem: what if a rule is inactive,
    #    e.g., bibtex because biber is in use,
    #          or xelatex when pdflatex is in use
    #          or bibtex when $bibtex_use is 0.
    #    What if both latex and pdflatex are being used?
    #      That has been allowed.  But .aux file (also
    #      .log file) are made by both.

    #  Other case: package (like bibtopic) creates bbl or other file when
    #  it doesn't exist.  Later a rule is created by latexmk to make that
    #  file.  Then the rule's main destination file should have priority
    #  over non-main generated files from other rules.
    local %from_rules_old = %from_rules;
    %from_rules = ();     # File to rule.
    rdb_for_actives( \&set_file_links_for_rule );
    rdb_for_actives( \&rdb_set_source_rules );
    &rdb_classify_rules;
}

#------------

sub set_file_links_for_rule {
    foreach my $dest ( @$PA_extra_gen, keys %$PHdest ) {
        if ( exists $from_rules{$dest} ) {
            my $old_rule = $from_rules{$dest};
            if ( $old_rule eq $rule ) {
                # OK
            }
            elsif ( exists($possible_primaries{$old_rule})
                    && exists($possible_primaries{$rule}) ) {
                # This could be problematic.  But we'll let it go,
                # because it is a common case for .aux and .log files
                # (etc), and these cases do not appear to mess up
                # anything (by experience).
                # Once we allow an active flag for rules and only
                # examine active rules, the only case of this that
                # will appear (in the absence of other problems) will
                # be where two primary rules are active, notably a
                # latex rule to make dvi and a pdflatex (or other
                # rule) to make pdf.
            }
            else {
                warn "$My_name: Possible bug:\n",
                 "  In linking rules I already set source_rules{$dest} to '$old_rule'\n",
                 "  But now I want to set it to '$rule'\n";
            }
        }
        $from_rules{$dest} = $rule;
    }
} # END set_file_links_for_rule
   
#------------

sub rdb_set_source_rules {
    # This assumes rule context, and sets explicit source rules in the hash
    # %$PHsource_rules.  These are to be rules on which the current rule
    # depends, but that aren't determined by using the known set of source
    # files of the current rule together with the known sets of destination
    # files for other rules.
    #
    # The standard case, and the only one used at the moment is for rules
    # whose **main** source file is a dvi or xdv file.  These programs used
    # by these rules (dvips etc) do not provide easily accessible
    # information on the set of graphics files that they read in.
    # So such rules are given a source rule that is the *latex that
    # generates them.
    #
    # These cases need special treatment coded here and in the algorithms
    # in rdb_make etc.
    #
    my ($base, $path, $ext) = fileparseA( $$Psource );
    if ( ($ext eq '.dvi') || ($ext eq '.dviF') || ($ext eq '.xdv') ) {
        # Rules that use .dvi, .dviF, .xdv don't get all dependencies,
        # notably about included graphics files.
        # So use a pass criterion instead.
        my $old_rule = $from_rules_old{$$Psource};
        my $new_rule = $from_rules{$$Psource};
        if ( defined $old_rule
             && defined $new_rule
             && ($old_rule eq $new_rule)
             && defined $$PHsource_rules{$new_rule}
            )
        {  # Nothing to do: source rule is correct.
        }
        else {
            if ( defined $old_rule ) { delete $$PHsource_rules{$old_rule}; }
            if ( defined $new_rule ) { $$PHsource_rules{$new_rule} = 0; }
        }
    }
} # END rdb_set_source_rules

#------------

sub rdb_classify_rules {
    # Usage: &rdb_classify_rules
    # Assume the following variables are available (global or local):
    # Input:
    #    %target_rules    # Set to target rules
    #    %target_files    # Set to target files
    #    %possible_primaries
    
    # Output:
    #    @pre_primary          # Array of rules
    #    @post_primary         # Array of rules
    #    @unusual_one_time     # Array of rules
    # @pre_primary and @post_primary are in natural order of application.

    local @requested_targets = &rdb_target_array;
    local $state = 0;       # Post-primary
    local @classify_stack = ();

    @pre_primary = ();
    @post_primary = ();
    @unusual_one_time = ();

    rdb_recurse( \@requested_targets, \&rdb_classify1, 0,0, \&rdb_classify2 );

    # Reverse, as tendency is to find last rules first.
    @pre_primary = reverse @pre_primary;
    @post_primary = reverse @post_primary;

    if ($diagnostics) {
        print "Rule classification: \n";
        show_array( "  Requested rules:",  @requested_targets );
        show_array( "  Pre-primaries:", @pre_primary );
        show_array( "  Primary:", $current_primary );
        show_array( "  Post-primaries:", @post_primary );
        show_array( "  Inner-level one_time rules:", @unusual_one_time );
        show_array( "  Outer-level one_time rules:", keys %one_time );
    } #end diagnostics

} #END rdb_classify_rules

#-------------------

sub rdb_classify1 {
    # Helper routine for rdb_classify_rules
    # Applied as rule_act1 in recursion over rules
    # Assumes rule context, and local variables from rdb_classify_rules
    push @classify_stack, [$state];
    if ( exists $possible_one_time{$rule} ) {
        # Normally, we will have already extracted the one_time rules,
        # and they will never be accessed here.  But just in case of
        # problems or generalizations, we will cover all possibilities:
        if ($depth > 1) {
           warn "ONE TIME rule not at outer level '$rule'\n";
        }
        push @unusual_one_time, $rule;
    }
    elsif ($state == 0) {
       if ( exists $possible_primaries{$rule} ) {
           $state = 1;   # In primary rule
       }
       else {
           push @post_primary, $rule;
       }
    }
    else {
        $state = 2;     # in post-primary rule
        push @pre_primary, $rule;
    }
} #END rdb_classify1

#-------------------

sub rdb_classify2 {
    # Helper routine for rdb_classify_rules
    # Applied as rule_act2 in recursion over rules
    # Assumes rule context
    ($state) = @{ pop @classify_stack };
} #END rdb_classify2

#================================

#************************************************************

sub set_trivial_aux_fdb {
    # 1. Write aux file as would be written if the tex file had no cross
    #    cross references, etc. i.e., a minimal .aux file, as would be
    #    written by latex with a simple document.
    #    That saves a run of latex on such simple documents.
    #    Before about 2020, latex only wrote one line, containing '\relax '
    #    in the aux file.  After that a reference to the last page was
    #    added.  So now I write what is written for a one page document.
    # 2. Write a corresponding fdb file
    # 3. Provoke a run of *latex (actually of all primaries). 

    open( my $aux_file, '>', $aux_main )
        or die "Cannot write file '$aux_main'\n";
    fprint8 $aux_file, "\\relax \n";
    # The following is added by recent versions of latex for a
    # one page document
    fprint8 $aux_file, "\\gdef \\\@abspage\@last{1}\n";
    close($aux_file);

    foreach my $rule (keys %possible_primaries ) { 
        rdb_one_rule(  $rule,  
                       sub{ $$Pout_of_date = 1; }
                    );
    }
    &rdb_write( $fdb_name );
} #END set_trivial_aux_fdb

#************************************************************
#### Particular actions
#************************************************************
#************************************************************

sub do_cleanup {
    my $kind = $_[0];
    if (! $kind ) { return; }
    my @files_to_delete = ();
    @dirs = ($aux_dir1);
    if ($out_dir1 ne $aux_dir1) { push @dirs, $out_dir1; }
    
    push @files_to_delete, &get_small_cleanup;
    if ($kind == 1) {
        foreach my $dir1 (@dirs) {
            push @files_to_delete, cleanup_get1( $dir1, @final_output_exts );
        }
    }
    #    show_array( "Files to delete", sort @files_to_delete );

    # Names of contents of directory are longer than the name of the directory,
    # but contain the directory name as an initial segment.
    # Therefore deleting files and directories in the order given by reverse
    # sort deletes contents of directory before attempting to delete the
    # directory:
    unlink_or_move( reverse sort @files_to_delete );
    
    # If the fdb file (or log, fls and/or aux files) exist, it/they will have
    #   been used to make a changed rule database.  But a cleanup implies
    #   that we need a virgin rule database, corresponding to current state
    #    of files (after cleanup) so we reset the rule database and rule net:
    &rdb_initialize_rules;
}

#----------------------------------------

sub cleanup_get1 {
    # Usage: cleanup_get1( directory, patterns_or_exts_without_period, ... )
    # Return array of files obeying the specification in the given directory.
    #     Specifications are either extensions to be appended to root_filename
    #     or are patterns containing %R for root_filename of job, with possible
    #        wildcards.
    #  Directory name must include directory separator, e.g., './' or 'output/',
    #  or be blank, i.e., suitable for prepending to file name.
    
    # The directory and the root file name are fixed names, so I must escape
    # any glob metacharacters in them:
    my $dir = fix_pattern( shift );
    my $root_fixed = fix_pattern( $root_filename );
    my @files = ();
    foreach (@_) { 
        my $name = ( /%R/ ? $_ : "%R.$_" );
        $name =~ s/%R/${root_fixed}/;
        $name = $dir.$name;
        push @files, my_glob( "$name" );
    }
    return @files;
} #END cleanup_get1

#----------------------------------------

sub get_small_cleanup {
    # Get list of files to be deleted in a small cleanup.
    # Assume dependency information from previous run has been obtained.
    my %other_generated = ();
    my %cusdep_generated = ();
    my @index_bibtex_generated = ();
    my @aux_files = ();
    my @missing_bib_files = ();
    my $bibs_all_exist = 0;
    my %final_output_files = ();
    print "$My_name: Doing main (small) clean up for '$texfile_name'\n"
        if ! $silent;

    foreach (@final_output_exts) {
        $final_output_files{"$out_dir1$root_filename.$_"} = 1;
    }
    rdb_for_actives(
        sub {  # Find generated files at rule level
               my ($base, $path, $ext) = fileparseA( $$Psource );
               $base = $path.$base;
               if ( $rule =~ /^makeindex/ ) {
                   push @index_bibtex_generated, $$Psource, $$Pdest, "$base.ilg";
               }
               elsif ( $rule =~ /^(bibtex|biber)/ ) {
                   push @index_bibtex_generated, $$Pdest, "$base.blg";
                   push @aux_files, $$Psource;
                   if ( $bibtex_use == 1.5) {
                       foreach ( keys %$PHsource ) {
                           if ( ( /\.bib$/ ) && (! -e $_) ) {
                               push @missing_bib_files, $_;
                           }
                       }
                   }
               }
               elsif ( $rule =~ /^(latex|lualtex|pdflatex|xelatex)/ ) {
                   foreach my $key (keys %$PHdest) {
                       $other_generated{$key} = 1;
                   }
               }
               elsif ( ($rule =~ /^cusdep/) && (-e $$Psource) ) {
                   # N.B. Deleting cusdep generated files is wrong if source file doesn't exist.
                   #  But that will be taken care of in the rule-network setup.
                   #  So just have a test for safety in the elsif line, without diagnostics.
                   foreach my $key (keys %$PHdest) {
                       $cusdep_generated{$key} = 1;
                   }
               }
            },
            sub {  # Find generated files at source file level
               if ( $file =~ /\.aux$/ ) { push @aux_files, $file; }
            }
    );
    if ($#missing_bib_files == -1) { $bibs_all_exist = 1; }
    
    my $keep_bbl = 1;
    if ( ($bibtex_use > 1.6)
         ||
         (  ($bibtex_use == 1.5) && ($bibs_all_exist) )
       ) {
           $keep_bbl = 0;
    }
    if ($keep_bbl) {
        delete $generated_exts{'bbl'}; 
    }
    # Convert some arrays to hashes, since deletions are easier to handle:
    my %index_bibtex_generated = ();
    my %aux_files = ();
    my %aux_files_to_save = ();
    foreach (@index_bibtex_generated) {
        $index_bibtex_generated{$_} = 1
           unless ( /\.bbl$/ && ($keep_bbl) );
        delete( $other_generated{$_} );
    }
    foreach (@aux_files) {
        if (exists $other_generated{$_} ) {
            $aux_files{$_} = 1;
        }
        else {
            $aux_files_to_save{$_} = 1;
        }
    }

    foreach (keys %final_output_files) { delete $other_generated{$_}; }

    if ($diagnostics) {
        print "For deletion, files are as follows. Lists are non-exclusive.\n";
        show_array( " Files specified by patterns\n"
                    ." (explicit pattern with %R or root-filename.extension):",
                    sort keys %generated_exts );
        show_array( " Files determined from fdb file or log file that were generated by makeindex\n"
                    ." or bibtex:", 
                    sort keys %index_bibtex_generated );
        show_array( " Aux files (from analysis of rules):", keys %aux_files );
        show_array( " Aux files to SAVE and not delete:", keys %aux_files_to_save );
        show_array( " Other non-cusdep generated files from *latex:\n"
                    ." (only deleted if \$cleanup_includes_generated is set and file\n"
                    ." doesn't appear in another list):",
                    sort keys %other_generated );
        show_array( " Cusdep generated files:\n"
                   ." (only deleted if \$cleanup_includes_cusdep_generated is set and file\n"
                    ." doesn't appear in another list):",
                    sort keys %cusdep_generated );
    }

    my @clean_args = keys %generated_exts;
    push @files, cleanup_get1( $aux_dir1, @clean_args );
    if ( $out_dir1 ne $aux_dir1 ) { push @files, cleanup_get1( $out_dir1, @clean_args ); }

    push @files, @std_small_cleanup_files;
    foreach my $file (@std_small_cleanup_files) {
        foreach my $dir ($aux_dir1, $out_dir1 ) {
            if ($dir) { push @files, "$dir$file"; }
        }
    }
    push @files, keys %index_bibtex_generated, keys %aux_files;

    if ($cleanup_includes_generated) { push @files, keys %other_generated; }
    if ( $cleanup_includes_cusdep_generated) { push @files, keys %cusdep_generated; }
    push @files, $fdb_name;
    return @files;
}  # END get_small_cleanup

#************************************************************

sub do_cusdep {
    # Unconditional application of custom-dependency
    # except that rule is not applied if the source file source 
    # does not exist, and an error is returned if the dest is not made.
    #
    # Assumes rule context for the custom-dependency, and that my first 
    # argument is the name of the subroutine to apply
    my $func_name = $_[0];
    my $return = 0;
    if ( !-e $$Psource ) {
        # Source does not exist.  Users of this rule will need to turn
        # it off when custom dependencies are reset
        if ( !$silent ) {
            print "$My_name: In trying to apply custom-dependency rule\n",
            "  to make '$$Pdest' from '$$Psource'\n",
            "  the source file has disappeared since the last run\n";
        }
        # Treat as successful
    }
    elsif ( !$func_name ) {
        warn "$My_name: Possible misconfiguration or bug:\n",
        "  In trying to apply custom-dependency rule\n",
        "  to make '$$Pdest' from '$$Psource'\n",
        "  the function name is blank.\n";
    }
    elsif ( ! defined &$func_name ) {
        warn "$My_name: Misconfiguration or bug,",
        " in trying to apply custom-dependency rule\n",
        "  to make '$$Pdest' from '$$Psource'\n",
        "  function name '$func_name' does not exists.\n";
    }
    else {
        my $cusdep_ret = &$func_name( $$Pbase );
        if ( defined $cusdep_ret && ($cusdep_ret != 0) ) {
            $return = $cusdep_ret;
            if ($return) {
                warn "Rule '$rule', function '$func_name'\n",
                     "   failed with return code = $return\n";
            }
        }
        elsif ( !-e $$Pdest ) {
            # Destination non-existent, but routine failed to give an error
            warn "$My_name: In running custom-dependency rule\n",
            "  to make '$$Pdest' from '$$Psource'\n",
            "  function '$func_name' did not make the destination.\n";
            $return = -1;
        }
    }
    return $return;
}  # END do_cusdep

#************************************************************

sub do_viewfile {
    # Unconditionally make file for viewing, going through temporary file if
    # Assumes rule context

    my $return = 0;
    my ($base, $path, $ext) = fileparseA( $$Pdest );
    if ( &view_file_via_temporary ) {
        if ( $$Pext_cmd =~ /%D/ ) {
            my $tmpfile = tempfile1( "${root_filename}_tmp", $ext );
            print "$My_name: Making '$$Pdest' via temporary '$tmpfile'...\n";
            $return = &Run_subst( undef, undef, undef, undef, $tmpfile );
            move( $tmpfile, $$Pdest );
        }
        else {
            warn "$My_name is configured to make '$$Pdest' via a temporary file\n",
                 "    but the command template '$$Pext_cmd' does not have a slot\n",
            "    to set the destination file, so I won't use a temporary file\n";
            $return = &Run_subst();
        }
    }
    else {
        $return = &Run_subst();
    }
    return $return;
} #END do_viewfile

#************************************************************

sub do_update_view {
    # Update viewer
    # Assumes rule context
    # Arguments: (method, signal, viewer_process)

    my $return = 0;

    # Although the process is passed as an argument, we'll need to update it.
    # So (FUDGE??) bypass the standard interface for the process.
    # We might as well do this for all the arguments.
    my $viewer_update_method = ${$PAint_cmd}[1];
    my $viewer_update_signal = ${$PAint_cmd}[2];
    my $Pviewer_process             = \${$PAint_cmd}[3];
    my $Pneed_to_get_viewer_process = \${$PAint_cmd}[4];
    
    if ($viewer_update_method == 2) {
        if ($$Pneed_to_get_viewer_process) {
            $$Pviewer_process = &find_process_id( $$Psource );
            if ($$Pviewer_process != 0) {
                $$Pneed_to_get_viewer_process = 0;
            }
        }
        if ($$Pviewer_process == 0) {
            print "$My_name: need to signal viewer for file '$$Psource', but didn't get \n",
                  "   process ID for some reason, e.g., no viewer, bad configuration, bug\n"
                if $diagnostics;             
        }
        elsif ( defined $viewer_update_signal) {
            print "$My_name: signalling viewer, process ID $$Pviewer_process ",
                  "with signal $viewer_update_signal\n"
                if $diagnostics;
            kill $viewer_update_signal, $$Pviewer_process;
        }
        else {
            warn "$My_name: viewer is supposed to be sent a signal\n",
                 "  but no signal is defined.  Misconfiguration or bug?\n";
            $return = 1;
        }
    }
    elsif ($viewer_update_method == 4) {
        if (defined $$Pext_cmd) {
            $return = &Run_subst();
        }
        else {
            warn "$My_name: viewer is supposed to be updated by running a command,\n",
                 "  but no command is defined.  Misconfiguration or bug?\n";
        }
    }
    return $return;
} #END do_update_view

#************************************************************

sub if_source {
    # Unconditionally apply rule if source file exists.
    # Assumes rule context
    if ( -e $$Psource ) {
        return &Run_subst();
    }
    else {
        warn "Needed source file '$$Psource' does not exist.\n";
        return -1;
    }
} #END if_source

#************************************************************
#### Subroutines
#************************************************************
#************************************************************

sub find_basename {
    # Finds the basename of the root file
    # Arguments:
    #  1 - Filename to breakdown
    #  2 - Where to place base file
    #  3 - Where to place tex file
    #  Returns non-zero if tex file does not exist

    my $fail = 0;
    local ( $given_name, $base_name, $ext, $path, $tex_name, $source_name );
    $given_name = $_[0];
    $source_name = '';
    $tex_name = $given_name;   # Default name if I don't find the tex file
    ($base_name, $path, $ext) = fileparseB( $given_name );

    # Treatment of extensions (in TeXLive 2019), with omission of path search:
    # Exists: always means exists as a file, i.e., not as a directory.
    #  A. Finding of tex file:
    #   1. If extension is .tex and given_name exists, use it.
    #   2. Else if given_name.tex exists, use it.
    #   3. Else if given_name exists, use it.
    # B. The base filename is obtained by deleting the path
    #    component and the extension.
    # C. The names of generated files (log, aux) are obtained by appending
    #    .log, .aux, etc to the basename.  Note that these are all in the
    #    CURRENT directory (or the output or aux directory, as appropriate).
    #    The drive/path part of the originally given filename is ignored.

    # Here we'll do:
    # 1. Find the tex file by the above method, if possible.
    # 2. If not, find a custom dependency with a source file that exists to
    #      make the tex file so that after the tex file is made, the above
    #      rules find the tex file.
    # 3. If that also fails, use kpsewhich on given_name to find the tex
    #      file
    # 4. If that also fails, report non-existent tex file.


    if ( ($ext eq '.tex') && (-f $given_name) ) {
       $tex_name = "$given_name";
    }
    elsif ( -f "$given_name.tex" ) {
       $tex_name = "$given_name.tex";
       $base_name .= $ext;
    }
    elsif ( -f $given_name ) {
       $tex_name = $given_name;
    }
    elsif ( ($ext eq '.tex') && find_cus_dep( $given_name, $source_name ) ) {
       $tex_name = $given_name;
    }
    elsif ( find_cus_dep( "$given_name.tex", $source_name ) ) {
       $tex_name = "$given_name.tex";
       $base_name .= $ext;
    }
    elsif ( ($ext =~ /^\..+/) && find_cus_dep( $given_name, $source_name ) ) {
       $tex_name = $given_name;
    }
    else {
        my @kpse_result = kpsewhich( $given_name );
        if ($#kpse_result < 0) {
            $fail = 1;
        }
        else {
            $tex_name = $kpse_result[0];
            ($base_name) = fileparseB( $tex_name );
        }
    }

    $_[1] = $base_name;
    $_[2] = $tex_name;

    if ($diagnostics) {
        print "Given='$given_name', tex='$tex_name', base='$base_name', ext= $ext";
        if ($source_name) { print ",  source='$source_name'"; }
        print "\n";
    }
    return $fail;

} #END find_basename

#************************************************************

sub make_preview_continuous {

    local $failure = 0;
    local $updated = 0;

    # ???!!!
    print "======= Need to update make_preview_continuous for target files\n";
    
    $quell_uptodate_msgs = 1;

    if ( ($view eq 'dvi') || ($view eq 'pdf') || ($view eq 'ps') ) { 
        print "Viewing $view\n";
    }
    elsif ( $view eq 'none' ) {
        print "Not using a previewer\n";
        $view_file = '';
    }
    else {
        warn "$My_name:  BUG: Invalid preview method '$view'\n";
        exit 20;
    }

    my $viewer_running = 0;    # No viewer known to be running yet
    # Get information from update_view rule
    local $viewer_update_method = 0;
    # Pointers so we can update the following:
    local $Pviewer_process = undef;    
    local $Pneed_to_get_viewer_process = undef;
    rdb_one_rule( 'update_view', 
                  sub{ $viewer_update_method = $$PAint_cmd[1]; 
                       $Pviewer_process = \$$PAint_cmd[3]; 
                       $Pneed_to_get_viewer_process = \$$PAint_cmd[4]; 
                     } 
                );
    # Note that we don't get the previewer process number from the program
    # that starts it; that might only be a script to get things set up and the 
    # actual previewer could be (and sometimes **is**) another process.

    if ( ($view_file ne '') && (-e $view_file) && !$new_viewer_always ) {
        # Is a viewer already running?
        #    (We'll save starting up another viewer.)
        $$Pviewer_process = &find_process_id( $view_file );
        if ( $$Pviewer_process ) {
            print "$My_name: Previewer is already running\n" 
              if !$silent;
            $viewer_running = 1;
            $$Pneed_to_get_viewer_process = 0;
        }
    }

    # Loop forever, rebuilding .dvi and .ps as necessary.
    # Set $first_time to flag first run (to save unnecessary diagnostics)
    my $last_action_time = time();
    my $timed_out = 0;
CHANGE:
    for (my $first_time = 1; 1; $first_time = 0 ) {

        my %rules_to_watch = array_to_hash( &rdb_accessible );

        &init_timing1;
        $updated = 0;
        $failure = 0;
        $failure_msg = '';
        if ( $MSWin_fudge_break && ($^O eq "MSWin32") ) {
            # Fudge under MSWin32 ONLY, to stop perl/latexmk from
            #   catching ctrl/C and ctrl/break, and let it only reach
            #   downstream programs. See comments at first definition of
            #   $MSWin_fudge_break.
            $SIG{BREAK} = $SIG{INT} = 'IGNORE';
        }
        if ($compiling_cmd) {
            Run_subst( $compiling_cmd );
        }
        $failure = &rdb_make;

        if ( $MSWin_fudge_break && ($^O eq "MSWin32") ) {
            $SIG{BREAK} = $SIG{INT} = 'DEFAULT';
        }
        # Start viewer if needed.
        if ( ($failure > 0) && (! $force_mode) ) {
            # No viewer yet
        }
        elsif ( ($view_file ne '') && (-e $view_file) && $updated && $viewer_running ) {
            # A viewer is running.  Explicitly get it to update screen if we have to do it:
            rdb_one_rule( 'update_view', \&rdb_run1 );
        }
        elsif ( ($view_file ne '') && (-e $view_file) && !$viewer_running ) {
            # Start the viewer
            if ( !$silent ) {
                if ($new_viewer_always) {
                    print "$My_name: starting previewer for '$view_file'\n",
                         "------------\n";
                }
                else {
                    print "$My_name: I have not found a previewer that ",
                         "is already running. \n",
                         "   So I will start it for '$view_file'\n",
                         "------------\n";
               }
            }
            local $retcode = 0;
            rdb_one_rule( 'view', sub { $retcode = &rdb_run1;} );
            if ( $retcode != 0 ) {
                if ($force_mode) {
                    warn "$My_name: I could not run previewer\n";
                }
                else {
                    &exit_msg1( "I could not run previewer", $retcode);
                }
            }
            else {
                $viewer_running = 1;
                $$Pneed_to_get_viewer_process = 1;
            } # end analyze result of trying to run viewer
        } # end start viewer

        # Updated rule collection, and the set of rules whose source files
        # the WAIT loop examines for changes:
        &rdb_set_rule_net;
        %rules_to_watch = array_to_hash( &rdb_accessible );

        if ( $failure > 0 ) {
            if ( !$failure_msg ) {
                $failure_msg = 'Failure to make the files correctly';
            }
            $failure_msg =~ s/\s*$//;  #Remove trailing space
            warn "$My_name: $failure_msg\n",
    "    ==> You will need to change a source file before I do another run <==\n";
            if ($failure_cmd) {
                Run_subst( $failure_cmd );
            }

            # In the WAIT loop, we will test for changes in source files
            # that trigger a remake. Special considerations after an error:
            # 1. State of **user** source files for a rule is that before
            #    the last run of the rule.  Any changes since trigger
            #    rerun. 
            # 2. .aux files etc may have changed during an error run of a
            #    rule, but no further runs were made to get them
            #    stabilized. So they can have changed since start of
            #    run.  To avoid triggering an incorrect remake, rdb_make
            #    has updated generated source files to their current state
            #    after the whole make.  User changes (e.g., deletion of aux
            #    file) are still able to trigger a remake.
            # 3. Post_primary rules may not have been run (e.g., to make ps
            #    and pdf from dvi).  Depending on the criterion for rerun,
            #    they may be out-of-date by some criterion, but they should
            #    not be run until after another *latex run.  Such rules
            #    must be excluded from the rules whose source files the
            #    WAIT loop scans for changes.
            # Set this up as follows:
            foreach (@post_primary) { delete $rules_to_watch{$_}; }
        }
        else {
            if ( ($#primary_warning_summary > -1) && $warning_cmd ) {
                Run_subst( $warning_cmd );
            }
            elsif ( ($#primary_warning_summary > -1) && $warnings_as_errors && $failure_cmd ) {
                Run_subst( $failure_cmd );
            }
            elsif ($success_cmd) {
                Run_subst( $success_cmd );
            }
        }
        rdb_show_rule_errors();
        if ($rules_list) { rdb_list(); }
        if ( $dependents_list && ($updated || $failure) ) {
            if ( open( my $deps_handle, ">$deps_file" ) ) {
               deps_list($deps_handle);
               close($deps_handle);
           }
           else {
               warn "Cannot open '$deps_file' for output of dependency information\n";
           }
         }
        if ($show_time) { &show_timing1; };

        
        # Now wait for a file to change...
        # During waiting for file changes, handle ctrl/C and ctrl/break here,
        #   rather than letting system handle them by terminating script (and
        #   code in the following command line to work: any script that calls
        #   it).  This allows, for example, the command cleanup in the following
        #   command line to work:
        #          latexmk -pvc foo; cleanup;
        &catch_break;
        $have_break = 0;
        $last_action_time = time();
        $waiting = 1;
        rdb_for_some(
            [keys %rule_db],
            sub{
                if ($$Plast_result_info eq 'CURR') {
                    $$Plast_result_info = 'PREV';
                }
            }
        );
        print "\n=== Watching for updated files. Use ctrl/C to stop ...\n";
  WAIT: while (1) {
           sleep( $sleep_time );
           if ($have_break) { last WAIT; }
           my %changes = ();
           if ( rdb_remake_needed(\%changes, 1, keys %rules_to_watch) ) { 
               if (!$silent) {
                   print "\n$My_name: Need to remake files.\n";
                   &rdb_diagnose_changes2( \%changes, "", 1 );
                   print "\n";
               }
               last WAIT;
           }
           #  Don't count waiting time in processing:
           $processing_time1 = processing_time();
        # Does this do this job????!!!
           local $new_files = 0;
           rdb_for_some( [keys %current_primaries], sub{ $new_files += &rdb_find_new_files } );
           if ($new_files > 0) {
               print "$My_name: New file(s) found.\n";
               last WAIT; 
           }
           if ($have_break) { last WAIT; }
           if ($pvc_timeout && ( time() > $last_action_time+60*$pvc_timeout_mins ) ) {
               $timed_out = 1;
               last WAIT;
           }
     } # end WAIT:
     &default_break;
     if ($have_break) { 
          print "$My_name: User typed ctrl/C or ctrl/break.  I'll finish.\n";
          return;
     }
     if ($timed_out) {
         print "$My_name: More than $pvc_timeout_mins mins of inactivity.  I'll finish.\n";
         return;
     }
     $waiting = 0; if ($diagnostics) { print "NOT       WAITING\n"; }
  } #end infinite_loop CHANGE:
} #END sub make_preview_continuous

#************************************************************

sub process_rc_file {
    # Usage process_rc_file( rc_file, [repeat_reaction] )
    #   2nd argument controls action if the the file rc_file has already been
    #   processed:
    #      Omitted, undef, or 0: Silently ignore.  Used for processing
    #                            standard rc files (system, user, current
    #                            directory) since this situation legitimately
    #                            occurs when cwd is one of the directories
    #                            for the previously processed file.
    #                     other: Give a warning, and don't process the file
    #
    # Run rc_file whose name is given in first argument
    #    Exit with code 0 on success
    #    Exit with code 1 if file cannot be read or does not exist.
    #    Stop if there is a syntax error or other problem.
    # PREVIOUSLY: 
    #    Exit with code 2 if is a syntax error or other problem.
    my ($rc_file, $repeat_reaction) = @_;
    my $abs_rc = abs_path($rc_file);
    my $ret_code = 0;
    if ( exists $rc_files_read2{$abs_rc} ) {
        if ( $repeat_reaction ) { 
            warn
                "$My_name: A user -r option asked me to process an rc file an extra time.\n",
                "   Name of file = '$rc_file'\n",
                ( ($rc_file ne $abs_rc) ? "   Abs. path = '$abs_rc'\n": ""),
                "  I'll not process it\n";
        }
        return 0;
    }
    else {
        $rc_files_read2{$abs_rc} = 1;
    }
    push @rc_files_read, $rc_file;

    # I could use the do function of perl, but:
    # 1. The preceeding -r test (in an earlier version of latexmk) to get
    #    good diagnostics gets the wrong result under cygwin (e.g., on
    #    /cygdrive/c/latexmk/LatexMk).  I forget now (Nov. 2022) what the
    #    problem was exactly.
    # 2. The do function searches directories in @INC, which is not wanted
    #    here, where the aim is to execute code in a specific file in a
    #    specific directory.  In addition, '.' isn't in the default @INC in
    #    current versions of Perl (Nov. 2022), so "do latexmkrc;" for
    #    latexmkrc in cwd fails.
    # So I'll read the rc file and eval its contents.
    if ( !-e $rc_file ) {
        warn "$My_name: The rc-file '$rc_file' does not exist\n";
        return 1;
    }
    elsif ( -d $rc_file ) {
        warn "$My_name: The supposed rc-file '$rc_file' is a directory; but it\n",
             "          should be a normal text file\n";
        return 1;
    }
    elsif ( open( my $RCH, "<", $rc_file ) ) {
        my $code = '';
        # Read all contents of file into $code:
        { local $/ = undef; $code = <$RCH>;}
        close $RCH;
        if (! is_valid_utf8($code) ) {
            die "$My_name: Rc-file '$rc_file' is not in UTF-8 coding. You should save\n",
                "   it in UTF-8 coding for use with current latexmk.\n";
        }
        my $BOM = Encode::encode( 'UTF-8', "\N{U+FEFF}" );
        $code =~ s/^$BOM//;
        eval $code;
    }
    else {
        warn "$My_name: I cannot read the rc-file '$rc_file'\n";
        return 1;
    }
    if ( $@ ) {
        # Indent each line of possibly multiline message:
        my $message = prefix( $@, "     " );
        warn "$My_name: Initialization file '$rc_file' gave an error:\n",
             "$message\n";
        die "$My_name: Stopping because of problem with rc file\n";
        # Use the following if want non-fatal error.
        return 2;
    }
    return 0;
} #END process_rc_file

#************************************************************

sub execute_code_string {
    # Usage execute_code_string( string_of_code )
    # Run the perl code contained in first argument
    #    Halt if there is a syntax error or other problem.
    # ???Should I leave the exiting to the caller (perhaps as an option)?
    #     But I can always catch it with an eval if necessary.
    #     That confuses ctrl/C and ctrl/break handling.
    my $code = $_[0];
    print "$My_name: Executing initialization code specified by -e:\n",
         "   '$code'...\n" 
        if  $diagnostics;
    eval $code;
    # The return value from the eval is not useful, since it is the value of 
    #    the last expression evaluated, which could be anything.
    # The correct test of errors is on the value of $@.

    if ( $@ ) {
        # Indent each line of possibly multiline message:
        my $message = prefix( $@, "    " );
        die "$My_name: ",
            "Stopping because executing following code from command line\n",
            "    $code\n",
            "gave an error:\n",
            "$message\n";
    }
} #END execute_code_string

#************************************************************

sub cleanup_cusdep_generated {
    # Remove files generated by custom dependencies
    rdb_for_actives( \&cleanup_one_cusdep_generated );
} #END cleanup_cusdep_generated

#************************************************************

sub cleanup_one_cusdep_generated {
    # Remove destination file generated by one custom dependency
    # Assume rule context, but not that the rule is a custom dependency.
    # Only delete destination file if source file exists (so destination 
    #   file can be recreated)
    if ( $$Pcmd_type ne 'cusdep' ) {
       # NOT cusdep
       return;
    }
    if ( ! -e $$Psource ) {
        print "$My_name: For custom dependency '$rule',\n",
             "    I won't delete destination file '$$Pdest'\n",
             "    and any other generated files,\n",
             "    because the source file '$$Psource' doesn't exist,\n",
             "    so the destination file may not be able to be recreated\n";
        return;
    }
    unlink_or_move( $$Pdest, keys %$PHdest );
} #END cleanup_one_cusdep_generated

#************************************************************
#************************************************************
#************************************************************

#   Error handling routines, warning routines, help

#************************************************************

sub die_trace {
    # Call: die_trace( message );
    &traceback;   # argument(s) passed unchanged
    die "\n";
} #END die_trace

#************************************************************

sub traceback {
    # Call: traceback() 
    # or traceback( message  )
    # NOT &traceback!!!
    my $msg = shift;
    if ($msg) { warn "$msg\n"; }
    warn "Traceback:\n";
    my $i=0;     # Start with immediate caller
    while ( my ($pack, $file, $line, $func) = caller($i++) ) {
        if ($func eq 'die_trace') { next; }
        warn "   $func called from line $line\n";
    }
} #END traceback

#************************************************************

sub exit_msg1
{
  # exit_msg1( error_message, retcode )
  #    1. display error message
  #    2. exit with retcode
  warn "\n------------\n";
  warn "$My_name: $_[0].\n";
  warn "-- Use the -f option to force complete processing.\n";

  my $retcode = $_[1];
  if ($retcode >= 256) {
     # Retcode is the kind returned by system from an external command
     # which is 256 * command's_retcode
     $retcode /= 256;
  }
  exit $retcode;
} #END exit_msg1

#************************************************************

sub warn_running {
   # Message about running program:
    if ( $silent ) {
        print "$My_name: @_\n";
    }
    else {
        print "------------\n@_\n------------\n";
    }
} #END warn_running

#************************************************************

sub exit_help
# Exit giving diagnostic from arguments and how to get help.
{
    print "\n$My_name: @_\n",
         "Use\n",
         "   $my_name -help\nto get usage information\n";
    exit 10;
} #END exit_help


#************************************************************

sub print_help
{
  print
  "$My_name $version_num: Automatic LaTeX document generation routine\n\n",
  "Usage: $my_name [latexmk_options] [filename ...]\n\n",
  "  Latexmk_options:\n",
  "   -aux-directory=dir or -auxdir=dir \n",
  "                 - set name of directory for auxiliary files (aux, log)\n",
  "                 - See also the -emulate-aux-dir option\n",
  "   -bibtex       - use bibtex when needed (default)\n",
  "   -bibtex-      - never use bibtex\n",
  "   -bibtex-cond  - use bibtex when needed, but only if the bib file exists\n",
  "   -bibtex-cond1 - use bibtex when needed, but only if the bib file exists;\n",
  "                   on cleanup delete bbl file only if bib file exists\n",
  "   -bibfudge or -bibtexfudge - change directory to output directory when running bibtex\n",
  "   -bibfudge- or -bibtexfudge- - don't change directory when running bibtex\n",
  "   -bm <message> - Print message across the page when converting to postscript\n",
  "   -bi <intensity> - Set contrast or intensity of banner\n",
  "   -bs <scale> - Set scale for banner\n",
  "   -commands  - list commands used by $my_name for processing files\n",
  "   -c     - clean up (remove) all nonessential files, except\n",
  "            dvi, ps and pdf files.\n",
  "            This and the other clean-ups are instead of a regular make.\n",
  "   -C     - clean up (remove) all nonessential files\n",
  "            including aux, dep, dvi, postscript and pdf files\n",
  "            and file of database of file information\n",
  "   -CA     - clean up (remove) all nonessential files.\n",
  "            Equivalent to -C option.\n",
  "   -CF     - Remove file of database of file information before doing \n",
  "            other actions\n",
  "   -cd    - Change to directory of source file when processing it\n",
  "   -cd-   - Do NOT change to directory of source file when processing it\n",
  "   -dependents or -deps - Show list of dependent files after processing\n",
  "   -dependents- or -deps- - Do not show list of dependent files\n",
  "   -deps-escape=<kind> - Set kind of escaping of spaces in names in deps file\n",    
  "                 (Possible values: ", join( ' ', sort keys %deps_escape_kinds ), ")\n",
  "   -deps-out=file - Set name of output file for dependency list,\n",
  "                    and turn on showing of dependency list\n",
  "   -dF <filter> - Filter to apply to dvi file\n",
  "   -dir-report  - Before processing a tex file, report aux and out dir settings\n",
  "   -dir-report- - Before processing a tex file, do not report aux and out dir settings\n",
  "   -dvi    - generate dvi by latex\n",
  "   -dvilua - generate dvi by dvilualatex\n",
  "   -dvi-   - turn off required dvi\n",
  "   -dvilualatex=<program> - set program used for dvilualatex.\n",
  "                      (replace '<program>' by the program name)\n",
  "   -e <code> - Execute specified Perl code (as part of latexmk start-up\n",
  "               code)\n",
  "   -emulate-aux-dir  - emulate -aux-directory option for *latex\n",
  "              This enables the -aux-directory option to work properly with TeX\n",
  "              Live as well as MiKTeX\n",      
  "   -emulate-aux-dir- - use -aux-directory option with *latex\n",
  "   -f     - force continued processing past errors\n",
  "   -f-    - turn off forced continuing processing past errors\n",
  "   -gg    - Super go mode: clean out generated files (-CA), and then\n",
  "            process files regardless of file timestamps\n",
  "   -g     - process at least one run of all rules\n",
  "   -g-    - Turn off -g and -gg\n",
  "   -h     - print help\n",
  "   -help - print help\n",
  "   -indexfudge or -makeindexfudge - change directory to output directory when running makeindex\n",
  "   -indexfudge- or -makeindexfudge- - don't change directory when running makeindex\n",
  "   -jobname=STRING - set basename of output file(s) to STRING.\n",
  "            (Like --jobname=STRING on command line for many current\n",
  "            implementations of latex/pdflatex.)\n",
  "   -l     - force landscape mode\n",
  "   -l-    - turn off -l\n",
  "   -latex=<program> - set program used for latex.\n",
  "                      (replace '<program>' by the program name)\n",
  "   -latexoption=<option> - add the given option to the *latex command\n",
  "   -logfilewarninglist or -logfilewarnings \n",
  "               give list of warnings after run of *latex\n",
  "   -logfilewarninglist- or -logfilewarnings- \n",
  "               do not give list of warnings after run of *latex\n",
  "   -lualatex     - use lualatex for processing files to pdf\n",
  "                   and turn dvi/ps modes off\n",
  "   -M     - Show list of dependent files after processing\n",
  "   -MF file - Specifies name of file to receives list dependent files\n",
  "   -MP    - List of dependent files includes phony target for each source file.\n",
  "   -makeindexfudge - change directory to output directory when running makeindex\n",
  "   -makeindexfudge-- don't change directory to output directory when running makeindex\n",
  "   -MSWinBackSlash  under MSWin use backslash (\\) for directory separators\n",
  "                    for filenames given to called programs\n",
  "   -MSWinBackSlash-  under MSWin use forward slash (/) for directory separators\n",
  "                     for filenames given to called programs\n",
  "   -new-viewer    - in -pvc mode, always start a new viewer\n",
  "   -new-viewer-   - in -pvc mode, start a new viewer only if needed\n",
  "   -nobibtex      - never use bibtex\n",
  "   -nobibfudge or -nobibtexfudge - don't change directory when running bibtex\n",
  "   -nodependents  - Do not show list of dependent files after processing\n",
  "   -noemulate-aux-dir - use -aux-directory option with *latex\n",
  "   -noindexfudge or -nomakeindexfudge - don't change directory when running makeindex\n",
  "   -norc          - omit automatic reading of system, user and project rc files\n",
  "   -output-directory=dir or -outdir=dir\n",
  "                  - set name of directory for output files\n",
  "   -output-format=FORMAT\n",
  "                  - if FORMAT is dvi, turn on dvi output, turn off others\n",
  "                  - if FORMAT is pdf, turn on pdf output, turn off others\n",
  "                  - otherwise error\n",    
  "   -pdf   - generate pdf by pdflatex\n",
  "   -pdfdvi - generate pdf by latex (or dvilualatex) + dvipdf\n",
  "             -- see -dvilua for how to get dvilualatex used\n",    
  "   -pdflatex=<program> - set program used for pdflatex.\n",
  "                      (replace '<program>' by the program name)\n",
  "   -pdflualatex=<program> - set program used for lualatex.\n",
  "                      (replace '<program>' by the program name)\n",
  "   -pdfps - generate pdf by latex (or dvilualatex) + dvips + ps2pdf\n",
  "             -- see -dvilua for how to get dvilualatex used\n",    
  "   -pdflua - generate pdf by lualatex\n",
  "   -pdfxe - generate pdf by xelatex\n",
  "   -pdfxelatex=<program> - set program used for xelatex.\n",
  "                      (replace '<program>' by the program name)\n",
  "   -pdf-  - turn off pdf\n",
  "   -pF <filter> - Filter to apply to postscript file\n",
  "   -p     - print document after generating postscript.\n",
  "            (Can also .dvi or .pdf files -- see documentation)\n",
  "   -pretex=<TeX code> - Sets TeX code to be executed before inputting source\n",
  "                    file, if commands suitable configured\n",    
  "   -print=dvi     - when file is to be printed, print the dvi file\n",
  "   -print=ps      - when file is to be printed, print the ps file (default)\n",
  "   -print=pdf     - when file is to be printed, print the pdf file\n",
  "   -ps    - generate postscript\n",
  "   -ps-   - turn off postscript\n",
  "   -pv    - preview document.  (Side effect turn off continuous preview)\n",
  "   -pv-   - turn off preview mode\n",
  "   -pvc   - preview document and continuously update.  (This also turns\n",
  "                on force mode, so errors do not cause $my_name to stop.)\n",
  "            (Side effect: turn off ordinary preview mode.)\n",
  "   -pvc-  - turn off -pvc\n",
  "   -pvctimeout    - timeout in pvc mode after period of inactivity\n",
  "   -pvctimeout-   - don't timeout in pvc mode after inactivity\n",
  "   -pvctimeoutmins=<time> - set period of inactivity (minutes) for pvc timeout\n",
  "   -quiet    - silence progress messages from called programs\n",
  "   -r <file> - Read custom RC file\n",
  "               (N.B. This file could override options specified earlier\n",
  "               on the command line.)\n",
  "   -rc-report  - After initialization, report names of rc files read\n",
  "   -rc-report- - After initialization, do not report names of rc files read\n",
  "   -recorder - Use -recorder option for *latex\n",
  "               (to give list of input and output files)\n",
  "   -recorder- - Do not use -recorder option for *latex\n",
  "   -rules    - Show list of rules after processing\n",
  "   -rules-   - Do not show list of rules after processing\n",
  "   -showextraoptions  - Show other allowed options that are simply passed\n",
  "               as is to latex and pdflatex\n",
  "   -silent   - silence progress messages from called programs\n",
  "   -stdtexcmds - Sets standard commands for *latex\n",    
  "   -time     - show CPU time used\n",
  "   -time-    - don't show CPU time used\n",
  "   -use-make - use the make program to try to make missing files\n",
  "   -use-make- - don't use the make program to try to make missing files\n",
  "   -usepretex - Sets commands for *latex to use extra code before inputting\n",
  "                source file\n",    
  "   -usepretex=<TeX code> - Equivalent to -pretex=<TeX code> -usepretex\n",
  "   -v        - display program version\n",
  "   -verbose  - display usual progress messages from called programs\n",
  "   -version      - display program version\n",
  "   -view=default - viewer is default (dvi, ps, pdf)\n",
  "   -view=dvi     - viewer is for dvi\n",
  "   -view=none    - no viewer is used\n",
  "   -view=ps      - viewer is for ps\n",
  "   -view=pdf     - viewer is for pdf\n",
  "   -Werror   - treat warnings from called programs as errors\n",
  "   -xdv      - generate xdv by xelatex\n",
  "   -xdv-     - turn off required xdv\n",
  "   -xelatex      - use xelatex for processing files to pdf\n",
  "                   and turn dvi/ps modes off\n",
  "\n",
  "   filename = the root filename of LaTeX document\n",
  "\n",
  "-p, -pv and -pvc are mutually exclusive\n",
  "-h, -c and -C override all other options.\n",
  "-pv and -pvc require one and only one filename specified\n",
  "All options can be introduced by '-' or '--'.  (E.g., --help or -help.)\n",
  " \n",
  "In addition, latexmk recognizes many other options that are passed to\n",
  "latex and/or pdflatex without interpretation by latexmk.  Run latexmk\n",
  "with the option -showextraoptions to see a list of these\n",
  "\n",
  "Report bugs etc to John Collins <jcc8 at psu.edu>.\n";

} #END print_help

#************************************************************

sub print_commands {
  print "Commands used by $my_name:\n",
       "   To run latex, I use \"$latex\"\n",
       "   To run pdflatex, I use \"$pdflatex\"\n",
       "   To run dvilualatex, I use \"$dvilualatex\"\n",
       "   To run lualatex, I use \"$lualatex\"\n",
       "   To run xelatex, I use \"$xelatex\"\n",
       "   To run biber, I use \"$biber\"\n",
       "   To run bibtex, I use \"$bibtex\"\n",
       "   To run makeindex, I use \"$makeindex\"\n",
       "   To make a ps file from a dvi file, I use \"$dvips\"\n",
       "   To make a ps file from a dvi file with landscape format, ",
           "I use \"$dvips_landscape\"\n",
       "   To make a pdf file from a dvi file, I use \"$dvipdf\"\n",
       "   To make a pdf file from a ps file, I use \"$ps2pdf\"\n",
       "   To make a pdf file from an xdv file, I use \"$xdvipdfmx\"\n",
       "   To view a pdf file, I use \"$pdf_previewer\"\n",
       "   To view a ps file, I use \"$ps_previewer\"\n",
       "   To view a ps file in landscape format, ",
            "I use \"$ps_previewer_landscape\"\n",
       "   To view a dvi file, I use \"$dvi_previewer\"\n",
       "   To view a dvi file in landscape format, ",
            "I use \"$dvi_previewer_landscape\"\n",
       "   To print a ps file, I use \"$lpr\"\n",
       "   To print a dvi file, I use \"$lpr_dvi\"\n",
       "   To print a pdf file, I use \"$lpr_pdf\"\n",
       "   To find running processes, I use \"$pscmd\", \n",
       "      and the process number is at position $pid_position\n";
   print "Notes:\n",
        "  Command starting with \"start\" is run detached\n",
        "  Command that is just \"start\" without any other command, is\n",
        "     used under MS-Windows to run the command the operating system\n",
        "     has associated with the relevant file.\n",
        "  Command starting with \"NONE\" is not used at all\n";
} #END print_commands

#************************************************************

sub view_file_via_temporary {
    return $always_view_file_via_temporary 
           || ($pvc_view_file_via_temporary && $preview_continuous_mode);
} #END view_file_via_temporary

#************************************************************
#### Tex-related utilities

#**************************************************

sub check_biber_log {
    # Check for biber warnings, and report source files.
    # Usage: check_biber_log( base_of_biber_run, \@biber_datasource )
    # return 0: OK;
    #        1: biber warnings;
    #        2: biber errors;
    #        3: could not open .blg file;
    #        4: failed to find one or more source files, except for bibfile;
    #        5: failed to find bib file;
    #        6: missing file, one of which is control file
    #       10: only error is missing \citation commands.
    #       11: Malformed bcf file (normally due to error in pdflatex run)
    # Side effect: add source files @biber_datasource
    # N.B. @biber_datasource is already initialized by caller.
    #   So do **not** initialize it here.
    my $base = $_[0];
    my $Pbiber_datasource = $_[1];
    my $blg_name = "$base.blg";
    open( my $blg_file, "<", $blg_name )
      or return 3;
    my $have_warning = 0;
    my $have_error = 0;
    my $missing_citations = 0;
    my $no_citations = 0;
    my $error_count = 0;            # From my counting of error messages
    my $warning_count = 0;          # From my counting of warning messages
    # The next two occur only from biber
    my $bibers_error_count = 0;     # From biber's counting of errors
    my $bibers_warning_count = 0;   # From biber's counting of warnings
    my $not_found_count = 0;
    my $control_file_missing = 0;
    my $control_file_malformed = 0;
    my %remote = ();                # List of extensions of remote files
    my @not_found = ();             # Files, normally .bib files, not found.
    while (<$blg_file>) {
        $_ = utf8_to_mine($_);
        if (/> WARN /) { 
            print "Biber warning: $_"; 
            $have_warning = 1;
            $warning_count ++;
        }
        elsif (/> (FATAL|ERROR) /) {
            print "Biber error: $_"; 
            if ( /> (FATAL|ERROR) - Cannot find file '([^']+)'/    #'
                 || /> (FATAL|ERROR) - Cannot find '([^']+)'/ ) {  #'
                $not_found_count++;
                push @not_found, $2;
            }
            elsif ( /> (FATAL|ERROR) - Cannot find control file '([^']+)'/ ) {  #'
                $not_found_count++;
                $control_file_missing = 1;
                push @not_found, $2;
            }
            elsif ( /> ERROR - .*\.bcf is malformed/ ) {
                #  Special treatment: Malformed .bcf file commonly results from error
                #  in *latex run.  This error must be ignored.
                $control_file_malformed = 1;
            }
            else {
                $have_error = 1;
                $error_count ++;
                if ( /> (FATAL|ERROR) - The file '[^']+' does not contain any citations!/ ) { #'
                    $no_citations++;
                }
            }
        }
        elsif ( /> INFO - Data source '([^']*)' is a remote BibTeX data source - fetching/
            ){
            my $spec = $1;
            my ( $base, $path, $ext ) = fileparseA( $spec );
            $remote{$ext} = 1;
        }
        elsif ( /> INFO - Found .* '([^']+)'\s*$/
                || /> INFO - Found '([^']+)'\s*$/
                || /> INFO - Reading '([^']+)'\s*$/
                || /> INFO - Processing .* file '([^']+)'.*$/
                || /> INFO - Config file is '([^']+)'.*$/
            ) {
            my $file = $1;
            my ( $base, $path, $ext ) = fileparseA( $file );
            if ($remote{$ext} && ( $base =~ /^biber_remote_data_source/ ) && 1) {
                # Ignore the file, which appears to be a temporary local copy
                # of a remote file. Treating the file as a source file will
                # be misleading, since it will normally have been deleted by
                # biber itself.
            }
            elsif ( -e $file ) {
                # Note that biber log file gives full path to file. (No search is
                # needed to find it.)  The file must have existed when biber was
                # run.  If it doesn't exist now, a few moments later, it must
                # have gotten deleted, probably by biber (e.g., because it is a
                # copy of a remote file).
                # So I have included a condition above that the file must
                # exist to be included in the source-file list.
                push @$Pbiber_datasource, $file;
            }
        }
        elsif ( /> INFO - WARNINGS: ([\d]+)\s*$/ ) {
            $bibers_warning_count = $1;
        }
        elsif ( /> INFO - ERRORS: ([\d]+)\s*$/ ) {
            $bibers_error_count = $1;
        }
    }
    close $blg_file;
    @$Pbiber_datasource = uniqs( @$Pbiber_datasource );
    @not_found = uniqs( @not_found );
    push @$Pbiber_datasource, @not_found;

    if ($control_file_malformed){return 11;} 

    if ( ($#not_found < 0) && ($#$Pbiber_datasource >= 0) ) {
        print "$My_name: Found biber source file(s) [@$Pbiber_datasource]\n"
        unless $silent;
    }
    elsif ( ($#not_found == 0) && ($not_found[0] =~ /\.bib$/) ) {
        # Special treatment if sole missing file is bib file
        # I don't want to treat that as an error
        print "$My_name: Biber did't find bib file [$not_found[0]]\n";
        return 5;
    }
    else {
        warn "$My_name: Failed to find one or more biber source files:\n";
        foreach (@not_found) { warn "    '$_'\n"; }
        if ($force_mode) {
            warn "==== Force_mode is on, so I will continue.  ",
                 "But there may be problems ===\n";
        }
        if ($control_file_missing) {
            return 6;
        }
        return 4;
    }
#    print "$My_name: #Biber errors = $error_count, warning messages = $warning_count,\n  ",
#          "missing citation messages = $missing_citations, no_citations = $no_citations\n";
    if ( ! $have_error && $no_citations ) {
        # If the only errors are missing citations, or lack of citations, that should
        # count as a warning.
        # HOWEVER: biber doesn't generate a new bbl.  So it is an error condition.
        return 10;
    }
    if ($have_error) {return 2;}
    if ($have_warning) {return 1;}
    return 0;
} #END check_biber_log

#**************************************************

sub run_bibtex {
    my $return = 999;
    # Prevent changes we make to environment becoming global:
    local %ENV = %ENV;

    my ( $base, $path, $ext ) = fileparseA( $$Psource );
    # Define source and dest base to include extension, no path.
    my $source_base = $base.$ext;
    my $dest_base = basename( $$Pdest );
    if ( $path && $bibtex_fudge ) {
        # Up to TeXLive 2018, the following was true; situation has changed since.
        #   When an output directory is specified and with a bibtex from 2018 or
        #   earlier, running 'bibtex output/main.aux' doesn't find subsidiary .aux
        #   files, as from \@include{chap.aux}.  To evade the bug, we change
        #   directory to the directory of the top-level .aux file to run bibtex.
        #   But we have to fix search paths for .bib and .bst, since they may be
        #   specified relative to the document directory.
        # There is also another problem: Depending on the exact
        #   specification of the aux dir, bibtex may refuse to write to the
        #   aux dir, for security reasons.
        #   This prevents changing the default $bibtex_fudge to off,
        #   without breaking backward compatibility.  (???!!! Perhaps I
        #   should change the default, and give a special message if the
        #   security issue of not being able to write arises.)

        path_fudge( 'BIBINPUTS', 'BSTINPUTS' );
        pushd( $path );
        if (!$silent) {
            print "$My_name: Change directory to '$path'.\n",
                  "To assist finding of files in document directory, I set\n",
                  "  BIBINPUTS='$ENV{BIBINPUTS}'\n",
                  "  BSTINPUTS='$ENV{BSTINPUTS}'.\n";
        }
        # Override standard substitutions for source, dest, and base names in
        # default external command:
        $return = &Run_subst( undef, undef, '', $source_base, $dest_base, $base );
        popd();
        if (!$silent) {
            print "$My_name: Change directory back to '", cwd(), "'\n";
        }
    }
    else {
        # Use default substitutions etc for rule:
        $return = Run_subst();
    }
    return $return;
} #END run_bibtex

#**************************************************

sub run_makeindex {
    my $return = 999;
    my ( $base, $path, $ext ) = fileparseA( $$Psource );

    # Define source and dest base to include extension, no path.
    my $source_base = $base.$ext;
    my $dest_base = basename( $$Pdest );
    if ( $path && $makeindex_fudge ) {
        my $cwd = good_cwd();
        pushd( $path );
        if (!$silent) {
            print "$My_name: Change directory to '$path'.\n";
        }
        # Override standard substitutions for source, dest, and base names in
        # default external command:
        $return = &Run_subst( undef, undef, '', $source_base, $dest_base, $base );
        popd();
        if (!$silent) {
            print "$My_name: Change directory back to '$cwd'\n";
        }
    }
    else {
        # Use default substitutions etc for rule:
        $return = Run_subst();
    }
    return $return;
} #END run_makeindex

#**************************************************

sub check_bibtex_log {
    # Check for bibtex warnings:
    # Usage: check_bibtex_log( base_of_bibtex_run )
    # return 0: OK, 1: bibtex warnings, 2: bibtex errors, 
    #        3: could not open .blg file.
    #       10: only error is missing \citation commands or a missing aux file
    #           (which would normally be corrected after a later run of 
    #           *latex).

    my $base = $_[0];
    my $blg_name = "$base.blg";
    open( my $blg_file, "<", $blg_name )
      or return 3;
    my $have_warning = 0;
    my $have_error = 0;
    my $missing_citations = 0;
    my @missing_aux = ();
    my $error_count = 0;
    while (<$blg_file>) {
        $_ = utf8_to_mine($_);
        if (/^Warning--/) { 
            #print "Bibtex warning: $_"; 
            $have_warning = 1;
        }
        elsif ( /^I couldn\'t open auxiliary file (.*\.aux)/ ) {
            push @missing_aux, $1;
        }
        elsif ( /^I found no \\citation commands---while reading file/ ) {
            $missing_citations++;
        }
        elsif (/There (were|was) (\d+) error message/) {
            $error_count = $2;
            #print "Bibtex error: count=$error_count $_"; 
            $have_error = 1;
        }
    }
    close $blg_file;
    my $missing = $missing_citations + $#missing_aux + 1;
    if ( $#missing_aux > -1 ) {
        # Need to make the missing files.
        print "$My_name: One or more aux files is missing for bibtex. I'll try\n",
             "          to get *latex to remake them.\n";
        rdb_for_some( [keys %current_primaries], sub{ $$Pout_of_date = 1; } );
    }
    #print "Bibtex errors = $error_count, missing aux files and citations = $missing\n";
    if ($have_error && ($error_count <= $missing )
        && ($missing > 0) ) {
        # If the only error is a missing citation line, that should only
        # count as a warning.
        # Also a missing aux file should be innocuous; it will be created on
        # next run of *latex.  ?? HAVE I HANDLED THAT CORRECTLY?
        # But have to deal with the problem that bibtex gives a non-zero 
        # exit code.  So leave things as they are so that the user gets
        # a better diagnostic ??????????????????????????
#        $have_error = 0;
#        $have_warning = 1;
        return 10;
    }
    if ($have_error) {return 2;}
    if ($have_warning) {return 1;}
    return 0;
} #END check_bibtex_log

#**************************************************

sub normalize_force_directory {
    #  Usage, normalize_force_directory( dir, filename )
    #  Filename is assumed to be relative to dir (terminated with directory separator).
    #  Perform the following operations:
    #    Clean filename
    #    Prefix filename with dir
    #    Normalize filename
    #  Return result
    my $dir = $_[0];
    my $filename = clean_filename( $_[1] );
    $filename = "$dir$filename";
    return normalize_filename( $filename );
} #END normalize force_directory

#**************************************************

sub set_names {
    # Set names of standard files.  These are global variables.

    ## Remove extension from filename if was given.
    if ( find_basename($filename, $root_filename, $texfile_name) )  {
        if ( $force_mode ) {
           warn "$My_name: Could not find file '$texfile_name'\n";
        }
        else {
            &ifcd_popd;
            &exit_msg1( "Could not find file '$texfile_name'",
                        11);
        }
    }
    $tex_basename = $root_filename;  # Base name of TeX file itself
    if ($jobname ne '' ) {
        $root_filename = $jobname;
        $root_filename =~ s/%A/$tex_basename/g;
    }

    $aux_main = "%Y%R.aux";
    $log_name = "%Y%R.log";
    $fdb_name = "%Y%R.$fdb_ext";
    # Note: Only MiKTeX allows out_dir ne aux_dir. It puts
    #       .fls file in out_dir, not aux_dir, which seems
    #       not natural.
    if ($fls_uses_out_dir) {
        $fls_name = "%Z%R.fls";
        $fls_name_alt = "%Y%R.fls";
    }
    else {
        $fls_name = "%Y%R.fls";
        $fls_name_alt = "%Z%R.fls";
    }
    $dvi_name  = "%Z%R.dvi";
    $dviF_name = "%Z%R.dviF";
    $ps_name   = "%Z%R.ps";
    $psF_name  = "%Z%R.psF";
    $pdf_name  = "%Z%R.pdf";
    ## It would be logical for a .xdv file to be put in the out_dir,
    ## just like a .dvi file.  But the only program, MiKTeX, that
    ## currently implements aux_dir, and hence allows aux_dir ne out_dir,
    ## puts .xdv file in aux_dir.  So we must use %Y not %Z:
    $xdv_name   = "%Y%R.xdv";

    foreach ( $aux_main, $log_name, $fdb_name, $fls_name, $fls_name_alt,
              $dvi_name, $ps_name, $pdf_name, $xdv_name, $dviF_name, $psF_name ) {
        s/%R/$root_filename/g;
        s/%Y/$aux_dir1/;
        s/%Z/$out_dir1/;
    }

    $dvi_final = $dvi_name;
    $ps_final  = $ps_name;
    $pdf_final = $pdf_name;
    $xdv_final = $xdv_name;

    if ( length($dvi_filter) > 0) {
        $dvi_final = $dviF_name;
    }
    if ( length($ps_filter) > 0) {
        $ps_final = $psF_name;
    }
}

#**************************************************

sub correct_aux_out_files {
    # Deal with situations after a *latex run where files are in different
    # directories than expected (specifically aux v. output directory).
    # Do minimal fix ups to allow latexmk to analyze dependencies with log
    # and fls files in expected places.


    # Deal with log file in unexpected place (e.g., lack of support by *latex
    # of -aux-directory option.  This is to be done first, since a run of
    # *latex always produces a log file unless there is a bad error, so
    # this gives the best chance of diagnosing errors.
    my $where_log = &find_set_log;

    if ( $emulate_aux && ($aux_dir ne $out_dir) ) {
        # Move output files from aux_dir to out_dir
        # Move fls file also, if the configuration is for fls in out_dir.
        # Omit 'xdv', that goes to aux_dir (as with MiKTeX). It's not final output.
        foreach my $ext ( 'fls', 'dvi', 'pdf', 'ps', 'synctex', 'synctex.gz' ) {
            if ( ($ext eq 'fls') && ! $fls_uses_out_dir ) {next;}
            my $from =  "$aux_dir1$root_filename.$ext";
            my $to = "$out_dir1$root_filename.$ext" ;
            if ( test_gen_file_time( $from ) ) {
                if (! $silent) { print "$My_name: Moving '$from' to '$to'\n"; }
                my $ret = move( $from, $to );
                if ( ! $ret ) { die "  That failed, with message '$!'\n";}
            }
        }
    }

    # Fix ups on fls file:
    if ($recorder) {
        # Deal with following special cases:
        #   1. Some implemenations of *latex give fls files of name latex.fls
        #      or pdflatex.fls instead of $root_filename.fls.
        #   2. In some implementations, the writing of the fls file (memory
        #      of old implementations) may not respect the -output-directory
        #      and -aux-directory options.
        #   3. Implementations don't agree on which directory (aux or output)
        #      the fls is written to.  (E.g., MiKTeX changed its behavior in
        #      Oct 2020.)
        #   4. Some implementations (TeXLive) don't use -aux-directory.
        # Situation on implementations, when $emulate_aux is off:
        #   TeXLive: implements -output-directory only, and gives a non-fatal
        #      warning for -aux-directory. Symptoms:
        #         .log, .fls, .aux files written to intended output directory.
        #         .log file reports TeXLive implementation
        #     Correct reaction: Turn $emulate_aux on and rerun *latex.  The
        #         variety of files that can be written by packages is too
        #         wide to allow simple prescription of a fix up.
        #  MiKTeX: Pre-Oct-2020: fls file written to out dir.
        #          Post-Oct-2020: fls file written to aux dir.
        #  Other names:
        #  Some older versions wrote pdflatex.fls or latex.fls
        #  Current TeXLive: the fls file is initially written with the name
        #    <program name><process number>.fls, and then changed to the
        #   correct name.  Under some error conditions, the change of name
        #   does not happen.

        my $std_fls_file = $fls_name;
        my @other_fls_names = ( );
        if ( $rule =~ /^pdflatex/ ) {
            push @other_fls_names, "pdflatex.fls";
        }
        else {
            push @other_fls_names, "latex.fls";
        }
        if ( $aux_dir1 ne '' ) {
            push @other_fls_names, "$root_filename.fls";
            # The fls file may be in the opposite directory to the
            # one configured by $fls_uses_out_dir:
            push @other_fls_names, $fls_name_alt;
        }
        # Find the first non-standard fls file and copy it to the standard
        # place. But only do this if the file time is compatible with being
        # generated in the current run, and if the standard fls file hasn't
        # been made in the current run,  as tested by the use of
        # test_gen_file_time; that avoids problems with fls files left over from
        # earlier runs with other versions of latex.
        if ( ! test_gen_file_time ( $std_fls_file ) ) {
            foreach my $cand (@other_fls_names) {
                if ( test_gen_file_time( $cand ) ) {
                    print "$My_name: Copying '$cand' to '$std_fls_file'.\n";
                    copy $cand, $std_fls_file;
                    last;
                }
            }
        }
        if ( ! test_gen_file_time( $std_fls_file ) ) {
            warn "$My_name: fls file doesn't appear to have been made.\n";
        }
    }
} # END correct_aux_out_files

#-----------------

sub find_log {
    # Locate log file generated on this run.
    # Side effect: measure filetime offset if necessary.
    # Don't take other actions.
    # Returns 
    #    0 log file not found;
    #    1 log file in aux_dir i.e., correct place;
    #    2 log file **not** in aux_dir but in out_dir
    #             (only applies if $emulate_aux off)
    #    3 log file is in ., not aux_dir or out_dir.
    #    4 log file in aux_dir, but out-of-date
    #    5 log file in out_dir, but out-of-date,
    #             (only applies if $emulate_aux off)
    #    6 log file is in ., but out-of-date


    my $where_log = -1; # Nothing analyzed yet
    my $log_aux = "$aux_dir1$root_filename.log";
    my $log_out = "$out_dir1$root_filename.log";
    my $log_cwd = "./$root_filename.log";

    # Basic tests first that assume accuracy of time of file system:
    if ( test_gen_file_time( $log_aux ) ) {
        # Expected case
        return 1;
    }
    elsif ( (! $emulate_aux) && test_gen_file_time( $log_out ) ) {
        # *latex was called with -aux-directory option, but does not
        # implement it (e.g., TeXLive's version)
        return 2;
    }
    elsif ( test_gen_file_time( $log_cwd ) ) {
        # Arrive here typically with configuration error so that aux_dir
        # and/or out_dir aren't supplied to *latex.
        return 3;
    }

    # Arrive here only if a log file with a time stamp not too much earlier
    # than the run time has not found in a relevant place.
    # If relevant files exist, then we must test for a serious offset
    # between system time and filesystem time (i.e., filesystem server
    # time).
    if ( ! $filetime_offset_measured ) {
        $filetime_offset = get_filetime_offset( $aux_dir1."tmp" );
        $filetime_offset_measured = 1;
    }

    my @candidates = ( );
    my $latest_mtime = undef;
    my $latest_log = undef;

    if ( -e $log_aux ) {
        if ( test_gen_file_time( $log_aux ) ) { return 1; }
        return 4;
    }
    # Get here if log file in aux doesn't exist or is apparently too old.
    if ( (! $emulate_aux) && ( -e $log_out ) ) {
        if (test_gen_file_time( $log_out ) ) { return 2; }
        return 5;
    }
    if ( -e $log_cwd ) {
        if (test_gen_file_time( $log_cwd ) ) { return 3; }
        return 6;
    }
    return 0;
}

sub find_set_log {
    # Locate the log file, generated on this run.
    # It should be in aux_dir. But:
    #  a. With aux_dir ne out_dir and emulate_aux off and a (TeXLive) *latex
    #     that doesn't support aux_dir, the log file is in out_dir.
    #  b. If the specified command has no %O or if *latex doesn't support
    #     out_dir (hence not TeXLive and not MiKTeX), the log file would
    #     be in cwd.
    #  c. With a sufficiently severe error in *latex, no log file was generated.
    #     Any log file that exists will be a left over from a previous run,
    #     and hence have a filetime less than the system time at the start of
    #     the current run.  (The strict filetime criterion is modified in the
    #     implementation to allow for issues from file system's time
    #     granularity, and mismatch of time on server hosting file system.)
    #
    # Possible return values, and side effects.
    #    0 log file not found;
    #    1 log file in aux_dir i.e., correct place;
    #    2 log file **not** in aux_dir but in out_dir
    #             (only applies if $emulate_aux off)
    #      $emulate_aux turned on, commands fixed, log file copied to
    #      aux_dir, and flags set to cause rerun
    #    3 log file is in ., not aux_dir or out_dir.
    #      Fatal error raised here, since cause is normally a configuration error
    #      not an error caused by contents of user file.
    #    4 log file in aux_dir, but out-of-date
    #    5 log file in out_dir, but out-of-date,
    #             (only applies if $emulate_aux off)
    #    6 log file is in ., but out-of-date
    #
    # Cases: 0, 4, 5, 6 are error conditions to be handled by caller
    #        2 is to be handled by caller by a rerun
    #        1 is success.


    my $log_aux = "$aux_dir1$root_filename.log";
    my $log_out = "$out_dir1$root_filename.log";
    my $log_cwd = "./$root_filename.log";

    my $where_log = &find_log;
    my $good_log_found = 0;

    if ($where_log == 1 ) {
        # As expected
        $good_log_found = 1;
    }
    elsif ($where_log == 2 ) {
        warn "$My_name: .log file in '$out_dir' instead of expected '$aux_dir'\n",
             "   But emulate_aux is off.  So I'll turn it on.\n",
             "   I'll copy the log file to the correct place.\n",
             "   The next run of *latex **SHOULD** not have this problem.\n";
        copy( "$out_dir1$root_filename.log", "$aux_dir1$root_filename.log" );
        $where_log = 2;
        $emulate_aux = 1;
        $emulate_aux_switched = 1;
        # Fix up commands to have fudged use of directories for
        # use with non-aux-dir-supported *latex engines.
        foreach ( $$Pext_cmd ) {
            s/ -output-directory=[^ ]*(?= )//g;
            s/ -aux(-directory=[^ ]*)(?= )/ -output$1/g;
        }
        $good_log_found = 1;
    }
    if ($where_log == 3 ) {
        # .log file is not in out_dir nor in aux_dir, but is in cwd.
        # Presumably there is a configuration error
        # that prevents the directories from being used by latex.
        die "$My_name: The log file found was '$root_filename.log' instead of\n",
            "  '$aux_dir1$root_filename.log'.  Probably a configuration error\n",
            "  prevented the use of the -aux-directory and/or the -output-directory\n",
            "  options with the *latex command.\n",
            "  I'll stop.\n";
    }
    elsif ($where_log == 4 ) {
        warn "$My_name: The expected log file, '$log_aux', does exist, but it appears\n",
            "   to be left over from a previous run: The time at the start of the\n",
            "   current run was $$Prun_time, but the log file appears to have been\n",
            "   created significantly earlier, at ", get_mtime($log_aux), ".\n";
    }
    elsif ($where_log == 5 ) {
        warn "$My_name: The expected log file, '$log_aux', does not exist, but one is found\n",
            "   in '$out_dir', but it apears to be left over from a previous run. The time\n",
            "   at the start of the current run was $$Prun_time, but the log file appears to\n",
            "   have been created significantly earlier, at ", get_mtime($log_out), ".\n";
    }
    elsif ($where_log == 6 ) {
        warn "$My_name: The expected log file, '$log_aux', does not exist, but one is found\n",
            "   in '.', but it apears to be left over from a previous run. The time\n",
            "   at the start of the current run was $$Prun_time, but the log file appears to\n",
            "   have been created significantly earlier, at ", get_mtime($log_cwd), ".\n";
    }
    elsif ($where_log == 0) {
        warn "$My_name: No log file was found, neither the expected one, '$log_aux', nor one in '.'.\n";
        if (! $emulate_aux) { warn "   I also looked in '$out_dir'\n"; }
    }
    if ( ! $good_log_found ) {
        $failure = 1;
        $$Plast_result = 2;
        $failure_msg 
            = "*LaTeX didn't generate the expected log file '$log_name'\n";
    }
    
    return $where_log;
} #END find_set_log

#************************************************************

sub parse_log {
# Use: parse_log( log_file_name,
#                 ref to array containing lines,
#                 ref to hash containing diagnostic etc information )
# Given lines from already read log file, scan them for: dependent files
#    reference_changed, bad_reference, bad_citation.
# Assume in the lines array, lines are already wrapped, and converted to my CS.   
# Return value: 1 if success, 0 if problems.
# Put results in UPDATES of global variables (which are normally declared
# local in calling routine, to be suitably scoped):
#   %dependents: maps definite dependents to code:
#      0 = from missing-file line
#            May have no extension
#            May be missing path
#      1 = from 'File: ... Graphic file (type ...)' line
#            no path.  Should exist, but may need a search, by kpsewhich.
#      2 = from regular '(...' coding for input file, 
#            Has NO path, which it would do if LaTeX file
#            Highly likely to be mis-parsed line
#      3 = ditto, but has a path character ('/').  
#            Should be LaTeX file that exists.
#            If it doesn't exist, we have probably a mis-parsed line.
#            There's no need to do a search.
#      4 = definitive, which in this subroutine is only done:
#             for default dependents, 
#             and for files that exist and are source of conversion
#                reported by epstopdf et al.
#      5 = Had a missing file line.  Now the file exists.
#      6 = File was written during run.  (Overrides 5)
#      7 = File was created during run to be read in, as a conversion
#          from some other file (e.g., by epstopdf package).
#          (Overrides 5 and 6)
#      8 = File was rewritten during run to be read in.  (Overrides 5 and 6)
# Treat the following specially, since they have special rules
#   @bbl_files to list of .bbl files.
#   %idx_files to map from .idx files to .ind files.
# %generated_log: keys give set of files written by *latex (e.g., aux, idx)
#   as determined by \openout = ... lines in log file.
# @missing_subdirs = list of needed subdirectories of aux_dir
#   These are needed for writing aux_files when an included file is in
#   a subdirectory relative to the directory of the main TeX file.
#   This variable is only set when the needed subdirectories don't exist,
#   and the aux_dir is non-trivial, which results in an error message in 
#   the log file
#  %conversions Internally made conversions from one file to another
#
#  These may have earlier found information in them, so they should NOT
#  be initialized.
#
# Also SET
#   $reference_changed, $bad_reference, $bad_citation
#   $pwd_latex
#
# Put in trivial or default values if log file does not exist/cannot be opened
#
# Input globals: $primary_out, $fls_file_analyzed
#

    my ($log_name, $PAlines, $PHinfo) = @_;
   
    # Give a quick way of looking up custom-dependency extensions
    my %cusdep_from = ();
    my %cusdep_to = ();
    foreach ( @cus_dep_list ) {
        my ($fromext, $toext) = split;
        $cusdep_from{$fromext} = $cusdep_from{".$fromext"} = $_;
        $cusdep_to{$toext} = $cusdep_to{".$toext"} = $_;
    }

    # $primary_out is actual output file (dvi or pdf)
    # It is initialized before the call to this routine, to ensure
    # a sensible default in case of misparsing

    $reference_changed = 0;
    $mult_defined = 0;
    $bad_reference = 0;
    $bad_character = 0;
    $bad_citation = 0;

    # ???!!! I don't know whether I will actually use these
    our @multiply_defined_references = ();
    our @undefined_citations = ();
    our @undefined_references = ();

    print "$My_name: Examining '$log_name'\n"
        if not $silent;

    my $engine = $$PHinfo{engine};
    my $tex_distribution = $$PHinfo{distribution};

    # Now analyze the result:
    $line_num = 0;
    my $state = 0;   # 0 => before ** line,
                     # 1 => after **filename line, before next line (first file-reading line)
                     # 2 => pwd_log determined.
    # For parsing multiple line blocks of info
    my $current_pkg = "";   # non-empty string for package name, if in 
                            # middle of parsing multi-line block of form:
                            #       Package name ....
                            #       (name) ...
                            #       ...
    my $block_type = "";         # Specify information in such a block
    my $delegated_source = "";   # If it is a file conversion, specify source
    my $delegated_output = "";   #    and output file.  (Don't put in
                                 #    data structure until block is ended.)
    my %new_conversions = ();
    my $log_silent = ($silent ||  $silence_logfile_warnings);
    @warning_list = ();

LINE:
    for (@$PAlines) {
        $line_num++;
        if ( /^! pdfTeX warning/ || /^pdfTeX warning/ ) {
            # This kind of warning is produced by some versions of pdftex
            # or produced by my reparse of warnings from other
            # versions.
            next;
        }
        if ( $line_num == 1 ){
            if ( /^This is / ) {
                # First line OK
                next LINE;
            } else {
                warn "$My_name: Error on first line of '$log_name'.\n".
                     "  This is apparently not a TeX log file.  ",
                     "  The first line is:\n$_\n";
                $failure = 1;
                $failure_msg = "Log file '$log_name' appears to have wrong format.";
                return 0;
            }
        }

        if ( ($state == 0) && /^\*\*(.*)$/ ) {
            # Line containing first line specified to tex
            # It's either a filename or a command starting with \
            my $first = $1;
            $state = 1;
            if ( ! /^\\/ ) {
                $source_log = $first;
                if ( -e "$source_log.tex" ) { $source_log .= '.tex'; }
            }
            else {
                $state = 2;
            }
            next LINE;
        }
        elsif ( $state == 1 ) {
            $state = 2;
            if (-e $source_log) {
                # then the string preceeding $source_log on the line after the
                # ** line is probably the PWD as it appears in filenames in the
                # log file, except if the file appears in two locations.
                if ( m{^\("([^"]*)[/\\]\Q$source_log\E"} ) {
                    unshift @pwd_log, $1;
                }
                elsif ( m{^\((.*)[/\\]\Q$source_log\E} ) {
                    unshift @pwd_log, $1;
                }
            }
        }

        if ( $block_type ) {
            # In middle of parsing block
            if ( /^\($current_pkg\)/ ) {
                # Block continues
                if ( ($block_type eq 'conversion') 
                     && /^\($current_pkg\)\s+Output file: <([^>]+)>/ ) 
                {
                    $delegated_output = normalize_clean_filename($1, @pwd_log);
                }
                next LINE;
            }
            # Block has ended.
            if ($block_type eq 'conversion') {
                 $new_conversions{$delegated_source} =  $delegated_output;
            }
            $current_pkg = $block_type 
                 = $delegated_source = $delegated_output = "";
            # Then process current line
        }

        # ???!!! Use the extra items. 
        # Check for changed references, bad references and bad citations:
        if (/Rerun to get/) { 
            print "$My_name: References changed.\n" if ! $log_silent;
            $reference_changed = 1;
        } 
#        if (/^LaTeX Warning: (Reference[^\001]*undefined on input line .*)\./) {
        if (/^LaTeX Warning: (Reference `([^']+)' on page .+ undefined on input line .*)\./) {
            push @warning_list, $1;
            push @undefined_references, $2;
            $bad_reference++;
        } 
        elsif (/^LaTeX Warning: (Label `([^']+)' multiply defined.*)\./) {
            push @warning_list, $1;
            push @multiply_defined_references, $2;
            $mult_defined++;
        }
        elsif (/^LaTeX Warning: (Citation `([^']+)' on page .* undefined on input line .*)\./) {
            push @warning_list, $1;
            push @undefined_citations, $2;
            $bad_citation++;
        }
        elsif (/^Package natbib Warning: (Citation[^\001]*undefined on input line .*)\./) {
            push @warning_list, $1;
            push @undefined_citations, $2;
            $bad_citation++;
        }
        elsif ( /^Missing character: There is no /
                || /^! Package inputenc Error: Unicode character /
                || /^! Bad character code /
                || /^! LaTeX Error: Unicode character /
            ) {
            push @warning_list, $_;
            $bad_character++;
        } 
        elsif ( /^Document Class: / ) {
            # Class sign-on line
            next LINE;
        }
        elsif ( /^\(Font\)/ ) {
            # Font info line
            next LINE;
        }
        elsif (/^No pages of output\./) {
            $primary_out = ''; 
            print "$My_name: Log file says no output from latex\n";
            next LINE;
        }
        elsif ( /^Output written on\s+(.*)\s+\(\d+\s+page/ ) {
            $primary_out = normalize_clean_filename($1, @pwd_log);
            print "$My_name: Log file says output to '$primary_out'\n"
               unless $silent;
            next LINE;
        }
        elsif ( /^Overfull / 
             || /^Underfull / 
             || /^or enter new name\. \(Default extension: .*\)/ 
             || /^\*\*\* \(cannot \\read from terminal in nonstop modes\)/
           ) {
            # Latex error/warning, etc.
            next LINE;
        }
        elsif ( /^\\openout\d+\s*=\s*(.*)\s*$/ ) {
            # \openout followed by filename followed by line end.
            # pdflatex and xelatex quote it and wrap,
            # lualatex leaves filename as is, and doesn't wrap.
            # Filename is always relative to aux_dir, given standard security
            # settings in TeXLive.
            my $cand = $1;
            if ( $cand =~ /\`\"([^\'\"]+)\"\'\.$/ ) {
                # One form of quoting by pdflatex, xelatex: `"..."'.
                $cand = $1;
            }
            elsif ( $cand =~ /\`([^\']+)\'\.$/ ) {
                # Another form of quoting by pdflatex, xelatex: `...'.
                $cand = $1;
            }
            if ( $cand =~ /[\`\'\"]/){
                # Bad quotes: e.g., incomplete wrapped line
                next LINE;
            }
            $generated_log{ normalize_force_directory($aux_dir1, $cand) } = 1;
            next LINE;
        }
        # Test for conversion produced by package:
        elsif ( /^Package (\S+) Info: Source file: <([^>]+)>/ ) {
            # Info. produced by epstopdf (and possibly others) 
            #    about file conversion
            $current_pkg = normalize_clean_filename($1, @pwd_log);
            $delegated_source = normalize_clean_filename($2, @pwd_log);
            $block_type = 'conversion';
            next LINE;
        }
#    Test for writing of index file.  The precise format of the message 
#    depends on which package (makeidx.sty , multind.sty or index.sty) and 
#    which version writes the message.
        elsif ( /Writing index file (.*)$/ ) {
            my $idx_file = '';
            if ( /^Writing index file (.*)$/ ) {
                # From makeidx.sty or multind.sty
                $idx_file = $1;
            }
            elsif ( /^index\.sty> Writing index file (.*)$/ ) {
                # From old versions of index.sty
                $idx_file = $1;
            }
            elsif ( /^Package \S* Info: Writing index file (.*) on input line/ ) {
                # From new versions of index.sty
                $idx_file = $1;                
            }
            else {
                warn "$My_name: Message indicates index file was written\n",
                     "  ==> but I do not know how to understand it: <==\n",
                     "  '$_'\n";
                next LINE;
            }
                # Typically, there is trailing space, not part of filename:
            $idx_file =~ s/\s*$//;
                #  When *latex is run with an -output-directory 
                #    or an -aux_directory, the file name does not contain
                #    the path. Fix this:
            $idx_file = normalize_force_directory( $aux_dir1, $idx_file );
            my ($idx_base, $idx_path, $idx_ext) = fileparseA( $idx_file );
            $idx_base = $idx_path.$idx_base;
            $idx_file = $idx_base.$idx_ext;
            if ( $idx_ext eq '.idx' ) {
                print "$My_name: Index file '$idx_file' was written\n"
                  unless $silent;
                $idx_files{$idx_file} = [ "$idx_base.ind", $idx_base ];
            }
            elsif ( exists $cusdep_from{$idx_ext} ) {
                if ( !$silent ) {
                    print "$My_name: Index file '$idx_file' was written\n";
                    print "   Cusdep '$cusdep_from{$idx_ext}' should be used\n";
                }
                # No action needed here
            }
            else {
                warn "$My_name: Index file '$idx_file' written\n",
                     "  ==> but it has an extension I do not know how to handle <==\n";
            }

            next LINE;
        }
        foreach my $pattern (@file_not_found) {
            if ( /$pattern/ ) {
                my $file = clean_filename($1);
                if ( $file =~ /\.bbl$/ ) {
                    # Note that bbl's filename is always relative to aux_dir.
                    my $bbl_file = normalize_force_directory( $aux_dir1, $file );
                    warn "$My_name: Missing bbl file '$bbl_file' in following:\n $_\n";
                    $dependents{$bbl_file} = 0;
                    push @bbl_files, $bbl_file;
                    next LINE;
                }
                warn "$My_name: Missing input file '$file' (or dependence on it) from following:\n  $_\n"
                    unless $silent;
                $dependents{normalize_filename($file, @pwd_log)} = 0;
                my $file1 = $file;
                if ( $aux_dir && ($aux_dir ne '.') ) {
                    # Allow for the possibility that latex generated
                    # a file in $aux_dir, from which the missing file can
                    # be created by a cusdep (or other) rule that puts
                    # the result in $out_dir.  If the announced missing file
                    # has no path, then it would be effectively a missing
                    # file in $aux_dir, with a path.  So give this alternate
                    # location.
                    # It is also possible to have a file that is in a directory
                    # relative to the aux_dir, so allow for that as well
                    my $file1 = normalize_force_directory( $aux_dir1, $file );
                    $dependents{$file1} = 0;
                }
                next LINE;
            }
        }
        foreach my $pattern (@bad_warnings) {
            if ( /$pattern/ ) {
                $log_info{bad_warning} = 1;
                warn "$My_name: Important warning:\n  $_\n"
                    unless $silent;
            }
        }
        if ( (! $fls_file_analyzed)
             && /^File: (.+) Graphic file \(type / ) {
            # First line of message from includegraphics/x
            # But this does NOT include full path information
            #   (if exact match is not found and a non-trivial
            #   kpsearch was done by *latex).
            # But the source-file information is in the fls file,
            #   if we are using it.
            $dependents{normalize_clean_filename($1, @pwd_log)} = 1;
            next LINE;
        }
        # Now test for generic lines to ignore, only after special cases!
        if ( /^File: / ) {
           # Package sign-on line. Includegraphics/x also produces a line 
           # with this signature, but I've already handled it.
           next LINE;
        }
        if ( /^Package: / ) {
            # Package sign-on line
            next LINE;
        }
        if (/^\! LaTeX Error: / ) {
            next LINE;
        }
        if ( m[^! I can't write on file `(.*)/([^/']*)'.\s*$] ) {
            my $dir = $1;
            my $file = $2;
            my $full_dir = $aux_dir1.$dir;
            if ( ($aux_dir ne '') && (! -e $full_dir) && ( $file =~ /\.aux$/) ) {
                warn "$My_name: === There were problems writing to '$file' in '$full_dir'\n",
                     "    I'll try to make the subdirectory later.\n"
                  if $diagnostics;
                push @missing_subdirs, $full_dir;
            }
            else {
                warn "$My_name: ====== There were problems writing to",
                     "----- '$file' in '$full_dir'.\n",
                     "----- But this is not the standard situation of\n",
                     "----- aux file to subdir of output directory, with\n",
                     "----- non-existent subdir\n",
            }
        }

        if ( ($fls_file_analyzed) && (! $analyze_input_log_always) ) {
            # Skip the last part, which is all about finding input
            # file names which should all appear more reliably in the
            # fls file.
            next LINE;
        }
        
        my @new_includes = ();
        
   GRAPHICS_INCLUDE_CANDIDATE:
        while ( /<([^>]+)(>|$)/g ) {
            if ( -f $1 ) { push @new_includes, $1; }
         }  # GRAPHICS_INCLUDE_CANDIDATE:

   INCLUDE_CANDIDATE:
        while ( /\((.*$)/ ) {
        # Filename found by
        # '(', then filename, then terminator.
        # Terminators: obvious candidates: ')':  end of reading file
        #                                  '(':  beginning of next file
        #                                  ' ':  space is an obvious separator
        #                                  ' [': start of page: latex
        #                                        and pdflatex put a
        #                                        space before the '['
        #                                  '[':  start of config file
        #                                        in pdflatex, after
        #                                        basefilename.
        #                                  '{':  some kind of grouping
        # Problem: 
        #   All or almost all special characters are allowed in
        #   filenames under some OS, notably UNIX.  Luckily most cases
        #   are rare, if only because the special characters need
        #   escaping.  BUT 2 important cases are characters that are
        #   natural punctuation
        #   Under MSWin, spaces are common (e.g., "C:\Program Files")
        #   Under VAX/VMS, '[' delimits directory names.  This is
        #   tricky to handle.  But I think few users use this OS
        #   anymore.
        #
        # Solution: use ' [', but not '[' as first try at delimiter.
        # Then if candidate filename is of form 'name1[name2]', then
        #   try splitting it.  If 'name1' and/or 'name2' exists, put
        #   it/them in list, else just put 'name1[name2]' in list.
        # So form of filename is now:
        #  '(', 
        # then any number of characters that are NOT ')', '(', or '{'
        #   (these form the filename);
        # then ' [', or ' (', or ')', or end-of-string.
        # That fails for pdflatex
        # In log file:
        #   '(' => start of reading of file, followed by filename
        #   ')' => end of reading of file
        #   '[' => start of page (normally preceeded by space)
        # Remember: 
        #    filename (on VAX/VMS) may include '[' and ']' (directory
        #             separators) 
        #    filenames (on MS-Win) commonly include space.
        #    filenames on UNIX can included space.
        #    Miktex quotes filenames
        #    But web2c doesn't.  Then 
        #       (string  message
        #    is ambiguous: is the filename "string" or "string message".
        #    Allow both as candidates, since user filenames with spaces 
        #    are rare.  System filenames with spaces are common, but
        #    they are normally followed by a newline rather than messages. 

        # First step: replace $_ by whole of line after the '('
        #             Thus $_ is putative filename followed by other stuff.
            $_ = $1; 
            # Array of new candidate include files; sometimes more than one.
            my $quoted = 0;
            if ( /^\"([^\"]+)\"/ ) {
               # Quoted file name, as from MikTeX
                $quoted = 1;
            }
            elsif ( /^\"/ ) {
                # Incomplete quoted file, as in wrapped line before appending
                # next line
                next LINE;
            }
            elsif ( /^([^\(^\)]*?)\s+[\[\{\<]/ ) {
                # Terminator: space then '[' or '{' or '<'
                # Use *? in condition: to pick up first ' [' (etc) 
                # as terminator
            }
            elsif ( /^([^\(^\)]*)\s+(?=\()/ ) {
                # Terminator is ' (', but '(' isn't in matched string,
                # so we keep the '(' ready for the next match
            }
            elsif  ( /^([^\(^\)]*)(\))/ ) {
                # Terminator is ')'
            }
            else {
                #Terminator is end-of-string
            }
            $_ = $';       # Put $_ equal to the unmatched tail of string '
            my $include_candidate = $1;
            $include_candidate =~ s/\s*$//;   # Remove trailing space.
            if ($quoted) {
            # Remove quotes around filename.
                $include_candidate =~ s/^\"(.*)\"$/$1/;
            }
            elsif ( !$quoted && ($include_candidate =~ /(\S+)\s/ ) ){
                # Non-space-containing filename-candidate
                # followed by space followed by message
                # (Common)
                push @new_includes, $1;
            }
            if ($include_candidate =~ /[\"\'\`]/) {
                # Quote inside filename.  Probably misparse.
                next INCLUDE_CANDIDATE;
            }
            if ( $include_candidate eq "[]" ) {
                # Part of overfull hbox message
                next INCLUDE_CANDIDATE;
            }
            if ( $include_candidate =~ /^\\/ ) {
                # Part of font message
                next INCLUDE_CANDIDATE;
            }

            push @new_includes, $include_candidate;
            if ( $include_candidate =~ /^(.+)\[([^\]]+)\]$/ ) {
                # Construct of form 'file1[file2]', as produced by pdflatex
                if ( -e $1 ) {
                    # If the first component exists, we probably have the
                    #   pdflatex form
                    push @new_includes, $1, $2;
                }
                else {
                    # We have something else.
                    # So leave the original candidate in the list
                }
            }
        } # INCLUDE_CANDIDATE

    INCLUDE_NAME:
        foreach my $include_name (@new_includes) {
            if ($include_name =~ /[\"\'\`]/) {
                # Quote inside filename.  Probably misparse.
                next INCLUDE_NAME;
            }
            $include_name = normalize_filename( $include_name, @pwd_log );
            if ( ! defined $include_name )  { next INCLUDE_NAME; }
            my ($base, $path, $ext) = fileparseB( $include_name );
            if ( ($path eq './') || ($path eq '.\\') ) {
                $include_name = $base.$ext;
            }
            if ( $include_name !~ m'[/|\\]' ) {
                # Filename does not include a path character
                # High potential for misparsed line
                $dependents{$include_name} = 2;
            } else {
                $dependents{$include_name} = 3;
            }
            if ( $ext eq '.bbl' ) {
                print "$My_name: Found input bbl file '$include_name'\n"
                   unless $silent;
                push @bbl_files, $include_name;
            }
        } # INCLUDE_NAME
    } # LINE

    # Default includes are always definitive:
    foreach (@default_includes) { $dependents{$_} = 4; }

    my @misparsed = ();
    my @missing = ();
    my @not_found = ();

    my %kpsearch_candidates = ();
CANDIDATE:
    foreach my $candidate (keys %dependents) {
        my $code = $dependents{$candidate};
        if ( -d $candidate ) {
            #  If $candidate is directory, it was presumably found from a 
            #     mis-parse, so remove it from the list.  (Misparse can 
            #     arise, for example from a mismatch of latexmk's $log_wrap
            #     value and texmf.cnf value of max_print_line.)
            delete $dependents{$candidate};
        }
        elsif ( -e $candidate ) {
            if ( exists $generated_log{$candidate} ){
                $dependents{$candidate} = 6;
            }
            elsif ($code == 0) {
                $dependents{$candidate} = 5;
            }
            else {
                $dependents{$candidate} = 4;
            }
        }
        elsif ($code == 1) {
            # Graphics file that is supposed to have been read.
            # Candidate name is as given in source file, not as path
            #   to actual file.
            # We have already tested that file doesn't exist, as given.
            #   so use kpsewhich.  
            # If the file still is not found, assume non-existent;
            $kpsearch_candidates{$candidate} = 1;
            delete $dependents{$candidate};
        }
        elsif ($code == 2) {
            # Candidate is from '(...' construct in log file, for input file
            #    which should include pathname if valid input file.
            # Name does not have pathname-characteristic character (hence
            #    $code==2.
            # We get here if candidate file does not exist with given name
            # Almost surely result of a misparsed line in log file.
            delete $dependents{$candidate};
            push @misparse, $candidate;
        }
        elsif ($code == 3) {
            # Candidate is from '(...' construct in log file, for input file
            #    which should include pathname if valid input file.
            # Name does have pathname-characteristic character (hence
            #    $code==3.
            # But we get here only if candidate file does not exist with 
            # given name.  
            # Almost surely result of a misparsed line in log file.
            # But with lower probability than $code == 2
            delete $dependents{$candidate};
            push @misparse, $candidate;
        }
        elsif ($code == 0) {
            my ($base, $path, $ext) = fileparseA($candidate);
            $ext =~ s/^\.//;
            if ( ($ext eq '') && (-e "$path$base.tex") ) {
                # I don't think the old version was correct.
                # If the missing-file report was of a bare
                #    extensionless file, and a corresponding .tex file
                #    exists, then the missing file does not correspond
                #    to the missing file, unless the .tex file was
                #    created during the run.  
                # OLD $dependents{"$path$base.tex"} = 4;
                # OLD delete $dependents{$candidate};
                # NEW:
                $dependents{"$path$base.tex"} = 4;
            }
            push @missing, $candidate;
        }
    }

    my @kpsearch_candidates = keys %kpsearch_candidates;
    if (@kpsearch_candidates) {
        foreach my $result ( kpsewhich( @kpsearch_candidates ) ) {
            $dependents{$result} = 4;
        }
    }
        
CANDIDATE_PAIR:
    foreach my $delegated_source (keys %new_conversions) {
        my $delegated_output = $new_conversions{$delegated_source};
        my $rule = "Delegated $delegated_source, $delegated_output";
        # N.B. $delegated_source eq '' means the output file
        #      was created without a named input file.
        foreach my $candidate ($delegated_source, $delegated_output) {
            if (! -e $candidate ) {
                # The file might be somewhere that can be found
                #   in the search path of kpathsea:
                my @kpse_result = kpsewhich( $candidate,);
                if ($#kpse_result > -1) {
                    $candidate = $kpse_result[0];
                }
            }
        }
        if ( ( (-e $delegated_source) || ($delegated_source eq '') )
              && (-e $delegated_output) )
        {
            $conversions{$delegated_output} = $delegated_source;
            $dependents{$delegated_output} = 7;
            if ($delegated_source) {
                $dependents{$delegated_source} = 4;
            }
        }
        elsif (!$silent) {
            print "Logfile claimed conversion from '$delegated_source' ",
                  "to '$delegated_output'.  But:\n";
            if (! -e $delegated_output) {
                print  "   Output file does not exist\n";
            }
            if ( ($delegated_source ne '') && (! -e $delegated_source) ) {
                print  "   Input file does not exist\n";
            }
        }
    }
    
    if ( $diagnostics ) {
        @misparse = uniqs( @misparse );
        @missing = uniqs( @missing );
        @not_found = uniqs( @not_found );
        my @dependents = sort( keys %dependents );

        my $dependents = $#dependents + 1;
        my $misparse = $#misparse + 1;
        my $missing = $#missing + 1;
        my $not_found = $#not_found + 1;
        my $exist = $dependents - $not_found - $missing;
        my $bbl = $#bbl_files + 1;

        print "$dependents dependent files detected, of which ",
              "$exist exist, $not_found were not found,\n",
              "   and $missing appear not to exist.\n";
        print "Dependents:\n";
        foreach (@dependents) { 
            print "   '$_' "; 
            if ( $dependents{$_} == 6 ) { print " written by *latex";}
            if ( $dependents{$_} == 7 ) { print " converted by *latex";}
            print "\n";
        }
        if ($not_found > 0) {
            show_array( "Not found:", @not_found );
        }
        if ($missing > 0) {
            show_array( "Not existent:", @missing );
        }
        if ( $bbl > 0 ) {
            show_array( "Input bbl files:", @bbl_files );
        }

        if ( $misparse > 0 ) {
            show_array( "Possible input files, perhaps from misunderstood lines in .log file:",  @misparse );
        }
    }
    return 1;
} #END parse_log

#************************************************************

sub get_log_file {
    # Use: get_log_file( log_file_name,
    #                    ref to array to receive lines,
    #                    ref to hash to receive diagnostic etc informaion )
    # 3rd argument is optional
    # Lines are unwrapped and converted to CS_system.
    
    my ($file, $PAlines, $PHinfo) = @_;

    # Where lines are wrapped at.  We'll sometimes override.
    local $log_wrap = $log_wrap;

    my $engine = '';
    my $tex_distribution = '';
    my ($line_num, $cont, $max_len) = ( 0, 0, 0 );
    my $lua_mode = 0;  # Whether to use luatex-specific wrapping method.
    my $byte_wrapping = 1;  # *latex does byte wrapping.  Modify if we find
                            # log file is generated by a tex program that
                            # wrapping by Unicode code points.

    # File encoding: pdftex: UTF-8 but with wrapping at $log_wrap BYTES.
    #                        (So individual wrapped lines can be malformed
    #                        UTF-8, but we get valid UTF-8 after unwrapping.)
    #                luatex: UTF-8 but with wrapping at APPROXIMATELY
    #                        $log_wrap bytes. Rest as pdftex
    #                xetex:  UTF-8 with wrapping at $log_wrap codepoints.
    # So we read file as bytes
    #   first line gives which program was used and hence whether to wrap
    #     according to byte or codepoint count.
    #   wrapping is always performed on the encoded byte strings, but the
    #     place to wrap is determined according to the length in bytes or
    #     in codepoints, as needed.
    print "$My_name: Getting log file '$file'\n";
    open( my $fh, '<', $file )
        or return 0;
  LINE:
    while (<$fh> ) {
        $line_num++;
        s/\r?\n$//;
        if ($line_num == 1) {
            if ( /^This is ([^,]+), [^\(]*\(([^\)]+)\)/ ) {
                $engine = $1;
                $tex_distribution = $2;
            }
            else {
                warn "$My_name: First line of .log file '$file' is not in standard format.\n";
            }
            if ( $engine =~ /XeTeX/i ) {
                $byte_wrapping = 0;
            }
            $lua_mode = ( $engine =~ /lua.*tex/i );
            # TeXLive's *tex take log wrap value from environment variable max_print_line, if it exists:
            if ( ($tex_distribution =~ /TeX\s*Live/) && $ENV{max_print_line} ) {
                $log_wrap = $ENV{max_print_line};
                print "$My_name: changed column for log file wrapping from standard to $log_wrap\n".
                      "  from env. var. max_print_line, which is obeyed by your TeXLive programs\n"
                   if $diagnostics;
            }
            # First (signon) line of log file doesn't get wrapped
            push @$PAlines, $_;
            next LINE;
        }
        my $len = 0;
        if ($byte_wrapping) { $len = length($_); }
        else {
            no bytes;
            $len = length( decode('UTF-8', $_) );
        }
        if ($len > $max_len) { $max_len = $len }

        # Is this line continuation of previous line?
        if ($cont) { $$PAlines[$#$PAlines] .= $_; }
        else { push @$PAlines, $_ }

        # Is this line wrapped? I.e., is next line to be appended to it?
        # Allow for fact that luatex doesn't reliably wrap at std place, e.g., 79.
        $cont = ($len == $log_wrap)
            || ( $lua_mode && ($len >= $log_wrap-2) && ($len <= $log_wrap+1) );
        if ($cont && $diagnostics ) {
            print "====Continuing line $line_num of length $len\n$_\n";
        }
    }
    close($fh);
    foreach (@$PAlines) { $_ = utf8_to_mine($_); }
    push @$PAlines, "";  # Blank line to terminate.  So multiline blocks 
              # are always terminated by non-block line, rather than eof.
    $$PHinfo{max_len} = $max_len;
    $$PHinfo{num_lines} = $line_num;
    $$PHinfo{num_after} = 1 + $#$PAlines;
    $$PHinfo{engine} = $engine;
    $$PHinfo{distribution} = $tex_distribution;
    return 1;
} #END get_log_file

#=====================================

sub parse_fls {
    my $start_time = processing_time();  
    my ($fls_name, $Pinputs, $Poutputs, $Pfirst_read_after_write, $Ppwd_latex ) = @_;
    %$Pinputs = %$Poutputs = %$Pfirst_read_after_write = ();
    my $fls_file;
    # Make a note of current working directory
    # I'll update it from the fls file later
    # Currently I don't use this, but it would be useful to use
    # this when testing prefix for cwd in a filename, by
    # giving *latex's best view of the cwd.  Note that the
    # value given by the cwd() function may be mangled, e.g., by cygwin
    # compared with native MSWin32.
    #
    # Two relevant forms of cwd exist: The system one, which we can find, and
    # the one reported by *latex in the fls file.  It will be
    # useful to remove leading part of cwd in filenames --- see the
    # comments in sub rdb_set_latex_deps.  Given the possible multiplicity
    # of representations of cwd, the one reported in the fls file should
    # be definitive in the fls file.

    my $cwd = good_cwd();
    if ( ! open($fls_file, "<", $fls_name) ) {
        return 1;
    }

    print "$My_name: Examining '$fls_name'\n"
        if not $silent;

    my $pdf_base = basename($pdf_name);
    my $log_base = basename($log_name);
    my $out_base = basename($$Pdest);
    my $pwd_subst = undef; # Initial string for pwd that is to be removed to
                           # make relative paths, when possible.  It must end
                           # in '/', if defined.
    my $line_no = 0;
    my $coding_errors = 0;
    my $coding_errors_max_print = 2;
    for ( <$fls_file> ) {
        # Remove trailing CR and LF. Thus we get correct behavior when an fls file
        #  is produced by MS-Windows program (e.g., in MiKTeX) with CRLF line ends,
        #  but is read by Unix Perl (which treats LF as line end, and preserves CRLF
        #  in read-in lines):
        # And convert '\'
        s/\r?\n$//;
        s[\\][/]g;
        $line_no++;
        if ($no_CP_conversions) {
            # Assume same byte representations for filenames in .fls file as
            # for file system calls.  No conversions needed.
        }
        else {
            # Deal with MS-Win issues when system CP isn't UTF-8
            if ( ($^O eq 'MSWin32') && /PWD/ && ! is_valid_utf8($_) ) {
                # TeXLive on MSWin produces PWD in CS_system not UTF-8.
                # ???? Later get tex_distribution before analyzing fls file, so do better test.
                print "PWD line not in UTF-8.  This is normal for TeXLive. I will handle it.\n";
                # Assume in CS_system, no change needed.
            }
            elsif ( ! is_valid_utf8($_) ) {
                $coding_errors++;
                warn "$My_name: In '$fls_name' =====Line $line_no is not in expected UTF-8 coding:\n$_\n"
                unless ($coding_errors > $coding_errors_max_print);
            }
            else {
                my $orig = $_;
                $_ = utf8_to_mine_errors($_);
                if ($@) {
                    $coding_errors++;
                    if (!$silent) {
                        warn "$@in conversion UTF-8 to system code page of line $line_no of $fls_name\n",
                              "$orig\n"
                        unless ($coding_errors > $coding_errors_max_print);
                    }
                }
            }
        } # End of fudge on MS-Win code page.
        if (/^\s*PWD\s+(.*)$/) {
            my $cwd_fls = $1;
            $pwd_subst = $$Ppwd_latex = $cwd_fls;
            if ($pwd_subst !~ m[/$] ) { $pwd_subst .= '/'; }
            if ( $cwd_fls =~ /\"/ ) {
                warn "$My_name: The working directory has a '\"' character in its name:\n",
                     "  '$cwd'\n  This can cause me trouble. Beware!\n";
            }
            if ( normalize_filename($cwd_fls) ne normalize_filename($cwd) ) {
                print "$My_name: ============== Inequiv cwd_fls cwd '$cwd_fls' '$cwd'\n";
            }
        }
        elsif (/^\s*INPUT\s+(.*)$/) {
            # Take precautions against aliasing of foo, ./foo and other possibilities for cwd.
            my $file = $1;
            # Remove exactly pwd reported in this file, and following separator.
            # MiKTeX reports absolute pathnames, and this way of removing PWD insulates
            #   us from coding issues if the PWD contains non-ASCII characters.  What
            #   coding scheme (UTF-8, code page, etc) is used depends on OS, TeX
            #   implementation, ...
            if ( defined $pwd_subst ) { 
                $file =~ s(^\Q$pwd_subst\E)();
            }
            $file = normalize_filename( $file );
            if ( (exists $$Poutputs{$file}) && (! exists $$Pinputs{$file}) ) {
                $$Pfirst_read_after_write{$file} = 1;
            }
            # Take precautions when the main destination file (or pdf file) or the log
            # file are listed as INPUT files in the .fls file.
            # At present, the known cases are caused by hyperxmp, which reads file metadata
            # for certain purposes (e.g., setting a current date and time, or finding the
            # pdf file size).  These uses are legitimate, but the files should not be
            # treated as genuine source files for *latex.
            # Note that both the pdf and log files have in their contents strings for
            # time and date, so in general their contents don't stabilize between runs
            # of *latex.  Hence adding them to the list of source files on the basis of
            # their appearance in the list of input files in the .fls file would cause
            # an incorrect infinite loop in the reruns of *latex.
            #
            # Older versions of hyperxmp (e.g., 2020/10/05 v. 5.6) reported the pdf file
            # as an input file.
            # The current version when used with xelatex reports the .log file as an
            # input file. 
            #
            # The test for finding the relevant .pdf (or .dvi ...) and .log files is
            # on basenames rather than full name to evade in a simple-minded way
            # alias issues with the directory part:
            if ( basename($file) eq $pdf_base ) {
                warn "$My_name: !!!!!!!!!!! Fls file lists main pdf **output** file as an input\n",
                     "   file for rule '$rule'. I won't treat as a source file, since that can\n",
                     "   lead to an infinite loop.\n",
                     "   This situation can be caused by the hyperxmp package in an old version,\n",
                     "   in which case you can ignore this message.\n";
            } elsif ( basename($file) eq $out_base ) {
                warn "$My_name: !!!!!!!!!!! Fls file lists main **output** file as an input\n",
                     "   file for rule '$rule'. I won't treat as a source file, since that can\n",
                     "   lead to an infinite loop.\n",
                     "   This situation can be caused by the hyperxmp package in an old version,\n",
                     "   in which case you can ignore this message.\n";
            } elsif ( basename($file) eq $log_base ) {
                warn "$My_name: !!!!!!!!!!! Fls file lists log file as an input file for\n",
                     "   rule '$rule'. I won't treat it as a source file.\n",
                     "   This situation can occur when the hyperxmp package is used with\n",
                     "   xelatex; the package reads the .log file's metadata to set current\n",
                     "   date and time.  In this case you can safely ignore this message.\n";
            } else {
                $$Pinputs{$file} = 1;
            }
        }
        elsif (/^\s*OUTPUT\s+(.*)$/) {
            # Take precautions against aliasing of foo, ./foo and other possibilities for cwd.
            my $file = $1;
            $file =~ s(^\Q$$Ppwd_latex\E[\\/])();
            $file = normalize_filename( $file );
            $$Poutputs{$file} = 1;
        }
    }
    close( $fls_file );
    if ($coding_errors) {
        warn "$My_name.$fls_name.  There were $coding_errors line(s) with character coding\n",
             "  errors: Characters not available in system code page and/or non-UTF-8 in\n",
             "  file when expected. Dependency information may be incomplete.\n";
        warn "The first few error lines are listed above\n";
    }
    return 0;
} #END parse_fls

#************************************************************

sub dirname_no_tail {
    my $dirname = $_[0];
    foreach ($dirname) {
        # Normalize name to use / to separate directory components:
        #   (Note both / and \ are allowed under MSWin.)
        s(\\)(/)g;
        # Change multiple trailing / to single /
        #   (Note internal // or \\ can have special meaning on MSWin)
        s(/+$)(/);
        # Remove trailing /,
        # BUT **not** if that changes the semantics, i.e., if name is "/" or "C:/".
        if ( m(/$) ) {
            if ( ( ! m(^/+$) ) && ( ! m(:/+$) ) ) {
                s(/$)();
            }
        }
    }
    return $dirname;
}

#************************************************************

sub clean_filename {
    # Convert quoted filename as found in log file to filename without quotes
    # Allows arbitrarily embedded double-quoted substrings, includes the
    # cases
    # 1. `"string".ext', which arises e.g., from \jobname.bbl:
    #    when the base filename contains spaces, \jobname has quotes.
    #    and from \includegraphics with basename specified.
    #    Also deals with filenames written by asymptote.sty
    # 2. Or "string.ext" from \includegraphcs with basename and ext specified.
    #    and from MiKTeX logfile for input files with spaces. 
    # Doubled quotes (e.g., A""B) don't get converted.
    # Neither do unmatched quotes.
    my $filename = $_[0];
    while ( $filename =~ s/^([^\"]*)\"([^\"]+)\"(.*)$/$1$2$3/ ) {}
    return $filename;
}

# ------------------------------

sub normalize_filename {
    # Usage: normalize_filename( filename [, extra forms of name of cwd] )
    # Returns filename with removal of various forms for cwd, and
    # with conversion of directory separator to '/' only,
    # and with use of my current choice of Unicode normalization.
    # Also when filename is name of a directory, with a trailing '/',
    #   the trailing '/' is removed.
    # ????In presence of accented characters in directory names, intended
    # functioning is when all cwd strings are in my chosen NF.
    #
    my ( $file, @dirs ) = @_;
    my $cwd = good_cwd();
    # Normalize files to use / to separate directory components:
    # (Note both / and \ are allowed under MSWin.)
    foreach ($cwd, $file,  @dirs) {
        s(\\)(/)g;
        # If this is directory name of form :.../", remove unnecessary
        # trailing directory separators:
        $_ = dirname_no_tail( $_ );
    }

    # Remove initial component equal to current working directory.
    # Use \Q and \E round directory name in regex to avoid interpretation
    #   of metacharacters in directory name:
    foreach my $dir ( @dirs, '.', $cwd ) {
        if ( $dir =~ /^\s*$/ ) {
            # All spaces, nothing to do.
            next;
        }
        if ($file eq $dir) {
            # Filename equals cwd, so it is . relative to cwd:
            $file = '.';
            last;
        }
        my $subst = $dir;
        if ($subst !~ m[/$]) { $subst .= '/'; }
        if ( $file =~ s(^\Q$subst\E)() ) {
            last;
      }
    }
    if ($file eq '' ) {
        # This only occurs for $file equal to a directory that
        # is the cwd. Our convention is always to set it to '.'
        # 
        $file = '.';
    }
    return $file;
} #END normalize_filename

# ------------------------------

sub normalize_filename_abs {
    # Convert filename to be either
    # absolute path in canonical form
    # or relative to cwd.
    return normalize_filename( abs_path($_[0]) );
}

#-----------------------------

sub normalize_clean_filename {
   # Usage: normalize_clean_filename( filename [, extra forms of name of cwd] )
   # Same as normalize_filename, but first remove any double quotes, as
   # done by clean_filename, which is appropriate for filenames from log file.
    my ($file, @dirs) = shift;
    return normalize_filename( clean_filename( $file ) , @dirs );
}

#************************************************************

sub fix_pattern {
   # Escape the characters [ and {, to give a pattern for use in glob
   #    with these characters taken literally.
   my $pattern = shift;
   $pattern =~ s/\[/\\\[/g;
   $pattern =~ s/\{/\\\{/g;
   return $pattern;
}

#************************************************************

sub parse_aux {
    # Usage: parse_aux( $aux_file, \@new_bib_files, \@new_aux_files, \@new_bst_files )
    # Parse aux_file (recursively) for bib files, and bst files.  
    # If can't open aux file, then
    #    Return 0 and leave @new_bib_files empty
    # Else set @new_bib_files and @new_bst_files from information in the
    #       aux files 
    #    And:
    #    Return 1 if no problems
    #    Return 2 with @new_bib_files empty if there are no \bibdata
    #      lines. 
    #    Return 3 if I couldn't locate all the bib_files
    # Set @new_aux_files to aux files parsed

    my $aux_file = $_[0];
    local $Pbib_files = $_[1];
    local $Paux_files = $_[2];
    local $Pbst_files = $_[3];
    # Default return values
    @$Pbib_files = ();
    @$Pbst_files = ();
    @$Paux_files = ();


    # Map file specs (in \bibdata and \bibstyle lines) to actual filenames:
    local %bib_files = ();
    local %bst_files = ();
      
    # Flag bad \bibdata lines in aux files:
    local @bad_bib_data = ( );
    # This array contains the offending lines, with trailing space (and
    # line terminator) removed.  (Currently detected problems: Arguments
    # containing spaces, which bibtex refuses to accept.)

    parse_aux1( $aux_file );
    if ($#{$Paux_files} < 0) {
        # No aux files found/read.
        return 0;
    }
    my @not_found_bib = ();
    my @not_found_bst = ();
    find_files( \%bib_files, 'bib', 'bib', $Pbib_files, \@not_found_bib );
    find_files( \%bst_files, 'bst', 'bst', $Pbst_files, \@not_found_bst );
    # ???!!! Should only get one bst file, of course. 

    if ( $#{$Pbib_files} + $#bad_bib_data  == -2 ) {
        # 
        print "$My_name: No .bib files listed in .aux file '$aux_file'\n";
        return 2;
    }

    show_array( "$My_name: Found bibliography file(s):", @$Pbib_files )
        unless $silent;
    if (@not_found_bib) {
        show_array(
            "Bib file(s) not found in search path:",
            @not_found_bib );
    }

    if (@not_found_bst) {
        show_array( "$My_name: Bst file not found in search path:", @not_found_bst);
    }
    

    if ($#bad_bib_data >= 0)  {
        warn
            "$My_name: White space in the argument for \\bibdata line(s) in an .aux file.\n",
            "   This is caused by the combination of spaces in a \\bibliography line in\n",
            "   a tex source file and the use of a pre-2018 version of *latex.\n",
            "   The spaces will give a fatal error when bibtex is used.  Bad lines:\n";
        foreach (@bad_bib_data ) { s/\s$//; warn "    '$_'\n"; }
        return 3;
    }
    if (@not_found_bib) {
        if ($force_mode) {
            warn "$My_name: Failed to find one or more bibliography files in search path.\n";
            warn "====BUT force_mode is on, so I will continue. There may be problems ===\n";
        }
        return 3;
    }
    return 1;
} #END parse_aux

#************************************************************

sub parse_aux1
# Parse single aux file for bib files.  
# Usage: &parse_aux1( aux_file_name )
#   Append newly found names of .bib files to %bib_files, already
#        initialized/in use.
#   Append newly found names of .bst files to %bst_files, already
#        initialized/in use.
#   Append aux_file_name to @$Paux_files if aux file opened
#   Recursively check \@input aux files
#   Return 1 if success in opening $aux_file_name and parsing it
#   Return 0 if fail to open it
{
   my $aux_file = $_[0];
   my $aux_fh;
   if (! open($aux_fh, $aux_file) ) { 
       warn "$My_name: Couldn't find aux file '$aux_file'\n";
       return 0; 
   }
   push @$Paux_files, $aux_file;
AUX_LINE:
   while (<$aux_fh>) {
       $_ = utf8_to_mine($_);
       s/\s$//;
       if ( /^\\bibdata\{(.*)\}/ ) { 
           # \\bibdata{comma_separated_list_of_bib_file_names}
           # This results from a \bibliography command in the document.
           my $arg = $1;
           if ($arg =~ /\s/) {
               # Bibtex will choke when the argument to \bibdata contains
               # spaces, so flag the error here.
               # N.B. *latex in TeX Live 2018 and later removes spaces from
               # the argument to \bibliography before placing it as the
               # argument to \bibdata in an aux file, so this error only
               # appears if a *latex from TeX Live 2017 or earlier is used.
               # Current MiKTeX's *latex (2022) also removes the space.
               push @bad_bib_data, $_;
           }
           else {
               foreach ( split /,/, $arg ) {
                   # bib files are always required to have an extension .bib,
                   # so provide the extension:
                   if ( ! /\.bib$/ ) { $_ .= '.bib'; }
                   $bib_files{$_} = '';
               }
           }
       }
       elsif ( /^\\bibstyle\{(.*)\}/ ) { 
           # \\bibstyle{bst_file_name}
           # Normally without the '.bst' extension.
           $bst_files{$1} = '';
       }
       elsif ( /^\\\@input\{(.*)\}/ ) { 
           # \\@input{next_aux_file_name}
           &parse_aux1( $aux_dir1.$1 );
       }
       else {
           run_hooks( 'aux_hooks' );
       }
   }
   close($aux_fh);
   return 1;
} #END parse_aux1

#************************************************************

sub parse_bcf {
    # Parse bcf file for bib and other source files.  
    # Usage: parse_bcf( $bcf_file, \@new_bib_files )
    # If can't open bcf file, then
    #    Return 0 and leave @new_bib_files empty
    # Else set @new_bib_files from information in the
    #       bcf files 
    #    And:
    #    Return 1 if no problems
    #    Return 2 with @new_bib_files empty if there are no relevant source
    #      file lines.
    #    Return 3 if I couldn't locate all the bib_files
    # A full parse of .bcf file as XML would need an XML parsing module, which
    # is not in a default installation of Perl, notably in TeXLive's perl for
    # Win32 platform.  To avoid requiring the installation, just search the
    # .bcf file for the relevant lines.

    my $bcf_file = $_[0];
    my $Pbib_files = $_[1];
    # Default return value
    @$Pbib_files = ();
    # Map file specs (from datasource lines) to actual filenames:
    local %bib_files = ();
    my @not_found_bib = ();

    open(my $bcf_fh, $bcf_file)
    || do {
       warn "$My_name: Couldn't find bcf file '$bcf_file'\n";
       return 0; 
    };
    while ( <$bcf_fh> ) {
        $_ = utf8_to_mine($_);
        if ( /^\s*<bcf:datasource type=\"file\"\s+datatype=\"bibtex\"\s+glob=\"false\">(.+)<\/bcf:datasource>/ ) {
            $bib_files{$1} = '';
        }
    }
    close $bcf_fh;

    find_files( \%bib_files, 'bib', 'bib', $Pbib_files, \@not_found_bib );
    if ( $#{$Pbib_files} == -1 ) {
        # 
        print "$My_name: No .bib files listed in .bcf file '$bcf_file'\n";
        return 2;
    }

    show_array( "$My_name: Bibliography file(s) form .bcf file:", @$Pbib_files )
        unless $silent;
    if (@not_found_bib) {
        show_array(
            "Bib file(s) not found in search path:",
            @not_found_bib );
    }
    if (@not_found_bib) {
        if ($force_mode) {
            warn "$My_name: Failed to find one or more bibliography files in search path.\n";
            warn "====BUT force_mode is on, so I will continue. There may be problems ===\n";
        }
        return 3;
    }
    return 1;

} #END parse_bcf


#************************************************************
#************************************************************
#************************************************************

#   Manipulations of main file database:

#************************************************************

sub fdb_get {
    # Call: fdb_get(filename [, check_time])
    # Returns an array (time, size, md5) for the current state of the
    #    named file.
    # The optional argument check_time is either the run_time of some command
    #    that may have changed the file or the last time the file was checked
    #    for changes --- see below.
    # For non-existent file, deletes its entry in fdb_current, 
    #    and returns (0,-1,0) (whatever is in @nofile).
    # As an optimization, the md5 value is taken from the cache in 
    #    fdb_current, if the time and size stamp indicate that the 
    #    file has not changed.
    # The md5 value is recalculated if
    #    the current filetime differs from the cached value: 
    #               file has been written
    #    the current filesize differs from the cached value: 
    #               file has definitely changed
    # But the file can also be rewritten without change in filetime when 
    #    file processing happens within the 1-second granularity of the 
    #    timestamp (notably for aux files from latex on a short source file).
    # The only case that concerns us is when the file is an input to a program
    #    at some runtime t, the file is rewritten later by the same or another
    #    program, with timestamp t, and when the initial file also has 
    #    timestamp t.
    # A test is applied for this situation if the check_time argument is
    #    supplied and is nonzero.

    my ($file, $check_time) = @_;
    if ( ! defined $check_time ) { $check_time = 0;}
    my ($new_time, $new_size) = get_time_size($file);
    if ( $new_size < 0 ) {
        delete $fdb_current{$file};
        return @nofile;
    }
    my $recalculate_md5 = 0;
    if ( ! exists $fdb_current{$file} ) {
        # Ensure we have a record.  
        $fdb_current{$file} = [@nofile];
        $recalculate_md5 = 1;
    }
    my $file_data = $fdb_current{$file};
    my ( $time, $size, $md5 ) = @$file_data;

    if ( ($new_time != $time) || ($new_size != $size) 
         || ( $check_time && ($check_time == $time ) )
       ) {
        # Only force recalculation of md5 if time or size changed.
        # However, the physical file time may have changed without
        #   affecting the value of the time coded in $time, because
        #   times are computed with a 1-second granularity.
        #   The only case to treat specially is where the file was created,
        #   then used by the current rule, and then rewritten, all within
        #   the granularity size, otherwise the value of the reported file
        #   time changed, and we've handled it.  But we may have already
        #   checked this at an earlier time than the current check.  So the
        #   only dangerous case is where the file time equals a check_time,
        #   which is either the run_time of the command or the time of a
        #   previous check.
        # Else we assume file is really unchanged.
        $recalculate_md5 = 1;
    }
    if ($recalculate_md5) {
        @$file_data = ( $new_time, $new_size, get_checksum_md5( $file ) );
    }
    return @$file_data;;
} #END fdb_get

#************************************************************

sub fdb_set {
    # Call: fdb_set(filename, $time, $size, $md5 )
    # Set data in file data cache, i.e., %fdb_current
    my ($file, $time, $size, $md5 ) = @_;
    if ( ! exists $fdb_current{$file} ) {
        $fdb_current{$file} = [@nofile];
    }
    @{$fdb_current{$file}} = ( $time, $size, $md5 );
} #END fdb_set

#************************************************************

sub fdb_show {
    # Displays contents of fdb
    foreach my $file ( sort keys %fdb_current ) {
        print "'$file': @{$fdb_current{$file}}\n";
    }
} #END fdb_show

#************************************************************
#************************************************************
#************************************************************

# Routines for manipulating rule database

#************************************************************

sub rdb_read {
    # Call: rdb_read( $in_name, inhibit_output_switch  )
    # Sets rule database from saved file, in format written by rdb_write.
    # The second argument controls behavior when there's a mismatch between
    # output extensions for primary rule in the cache and current settings.
    # If the second argument is true, omit a switch of output extension,
    # otherwise let the cached setting be obeyed (if possible).
    #
    # Returns: -2 if file doesn't exist,
    #          -1 if file existed but couldn't be read
    #          else number of errors.
    # Thus return value on success is 0
    # Requires: Rule database initialized with standard rules, with
    #             conditions corresponding to requests determined by
    #             initialization and command line options.
    # Asssumption: Normally the fdb_latexmk file contains state of
    #                rules and files corresponding to end of last
    #                compilation, and the rules in the file were
    #                active on that run.
    # Complications arise when that state does not correspond to current
    #   rule set:
    #   (a) Configuration etc may have changed: e.g., different out_dir,
    #       different target rules and files, including different tex engine.
    #   (b) Output extension of primary rule may be different from current
    #       initialized one, because of document properties (use of
    #       \pdfoutput etc).
    #   (c) The same may arise because of misconfigured rules, a situation
    #       that may or may not have changed in current run.
    #   (d) The primary engine requested may not be the one used in
    #       the previous run, possibly because (i) request has
    #       changed, or (ii) document metacommand was obeyed to change
    #       engine. (The last is not currently implemented, but
    #       may/should be in the future.)
    #   (e) Something else, e.g., copying/editing of fdb_latexmk file.
    #
    local ($in_name, $inhibit_output_switch) = @_;

    my $in_handle;
    if ( ! -e $in_name ) {
        # Note: This is NOT an error condition, since the fdb_latexmk file
        #       can legitimately not exist.
        return -2;   
    }
    if ( ! open( $in_handle, '<', $in_name ) ) {
        warn "$My_name: Couldn't read '$fdb_name' even though it exists\n";
        return -1;
    }
    print "$My_name: Examining fdb file '$fdb_name' for cached rules ...\n"
      if $diagnostics;
    my $errors = 0;
    my $state = -1;   # Values:
                      # -1: before start;
                      #  0: outside rule;
                      #  1: in source section;
                      #  2: in generated file section;
                      #  3: in rewritten-before-read file section;
                      # 10: ignored rule.
    my $rule = '';
    local $run_time = 0;
    local $last_result = -1;
    local $source = '';
    local $dest = '';
    my $base = '';
    my %old_actives = (); # Hash: keys are rules in fdb_latexmk file
    local %new_sources = ();  # Hash: rule => { file=>[ time, size, md5, fromrule ] }
    my $new_source = undef;   # Reference to hash of sources for current rule
LINE:
    while ( <$in_handle> ) {        
        # Remove leading and trailing white space.
        s/^\s*//;
        s/\s*$//;
        $_ = utf8_to_mine($_);
        
        if ($state == -1) {
            if ( ! /^# Fdb version ([\d]+)$/ ) {
                warn "$My_name: File-database '$in_name' is not of correct format\n";
                return 1;
            }
            if ( $1 ne $fdb_ver) {
                warn "$My_name: File-database '$in_name' is of incompatible version, $1 v. current version $fdb_ver\n";
                return 1;
            }
            $state = 0;
        }
        # Ignore blank lines and comments
        if ( /^$/ || /^#/ || /^%/ ) { next LINE;}
        if ( /^\[\"([^\"]+)\"\]/ ) {
            # Start of section
            $rule = $1;
            my $tail = $'; #'  Single quote in comment tricks the parser in
                           # emacs from misparsing an isolated single quote
            $run_time = $check_time = 0;
            $source = $dest = $base = '';
            $old_actives{$rule} = 1;
            $last_result = -1;
            if ( $tail =~ /^\s*(\S+)\s+\"([^\"]*)\"\s+\"([^\"]*)\"\s+\"([^\"]*)\"\s+(\S+)\s+(\S+)/ ) {
                $run_time = $1;
                $source = $2;
                $dest = $3;
                $base = $4;
                $check_time = $5;
                $last_result = $6;
            }
            else {
                # Line is not in correct format
                warn "$My_name: In '$in_name' there's a rule line not in correct format:\n",
                     "    $_\n",
                     "Perhaps the file has been edited, or there's a bug.\n";                    
                $errors ++;
                $state = 10;
                next LINE;
            }
            if ( rdb_rule_exists( $rule ) ) {
                # We need to set rule data from contents of fdb_latex file,
                # but we'll do that later, so that it can be done for both
                # existing and newly created rules.
            }
            elsif ($rule =~ /^cusdep\s+(\S+)\s+(\S+)\s+(.+)$/ ) {
                # create custom dependency
                my $fromext = $1;
                my $toext = $2;
                my $base = $3;
                # don't set $source and $dest here, but use the already-set values
                #  from the rule definition line: under some situations the rule
                #  may have these changed from normal.
                my $func_name = '';
                foreach my $dep ( @cus_dep_list ) {
                    my ($tryfromext,$trytoext,$must,$try_func_name) = split('\s+',$dep);
                    if ( ($tryfromext eq $fromext) && ($trytoext eq $toext) ) {
                        $func_name = $try_func_name;
                    }
                }
                if ($func_name) {
                    my $PAnew_cmd = ['do_cusdep', $func_name];
                    # Set source file as non-existent.  
                    # If it existed on last run, it will be in later 
                    #    lines of the fdb file
                    rdb_create_rule( $rule, 'cusdep', '', $PAnew_cmd, 1, 
                                     $source, $dest, $base, 0, $run_time, $check_time, 1 );
                }
                else {
                    warn "$My_name: In file-database '$in_name', the custom-dependency rule\n",
                         "  '$rule' is not available in this session.\n",
                         "  Presumably it's no longer in your configuration for latexmk.\n";
                    $state = 10;
                    next LINE;
                }
            }
            elsif ( $rule =~ /^(makeindex|bibtex|biber)\s*(.*)$/ ) {
                my $PA_extra_gen = [];
                my $rule_generic = $1;
                my $int_cmd = '';
                if ( ! $source ) {
                    # If fdb_file was old-style (v. 1)
                    $source = $2;
                    my $path = '';
                    my $ext = '';
                    ($base, $path, $ext) = fileparseA( $source );
                    $base = $path.$base;
                    if ($rule_generic eq 'makeindex') {
                        $dest = "$base.ind";
                    }
                    elsif ($rule_generic eq 'bibtex') {
                        $dest = "$base.bbl";
                        $source = "$base.aux";
                    }
                    elsif ($rule_generic eq 'biber') {
                        $dest = "$base.bbl";
                        $source = "$base.bcf";
                    }
                }
                if ($rule =~ /^makeindex/) { $PA_extra_gen = [ "$base.ilg" ]; }
                if ($rule =~ /^(bibtex|biber)/) { $PA_extra_gen = [ "$base.blg" ]; }
                if ($rule =~ /^bibtex/) { $int_cmd = "run_bibtex"; }
                if ($rule =~ /^makeindex/) { $int_cmd = "run_makeindex"; }
                print "$My_name: File-database '$in_name': setting rule '$rule'\n"
                   if $diagnostics;
                my $cmd_type = 'external';
                my $ext_cmd = ${$rule_generic};
                print "  Rule kind = '$rule_generic'; ext_cmd = '$ext_cmd';\n",
                     "  int_cmd = '$int_cmd';\n",
                     "  source = '$source'; dest = '$dest'; base = '$base';\n"
                   if $diagnostics;
                # Set source file as non-existent.  
                # If it existed on last run, it will be in later 
                #    lines of the fdb file
                rdb_create_rule( $rule, $cmd_type, $ext_cmd, $int_cmd, 1, 
                                 $source, $dest, $base, 0, $run_time,  $check_time, 1, $PA_extra_gen );
            }
            else {
                if ($diagnostics) {
                    print "$My_name: In file-database '$in_name' rule '$rule'\n",
                        "   is not in use in this session\n";
                }
                $new_source = undef;
                $state = 10;
                next LINE;
            }
            if ( rdb_rule_exists( $rule ) ) {
                rdb_one_rule( $rule, \&rdb_read_set_rule );
            }
            $new_source = $new_sources{$rule} = {};
            $state = 1;  #Reading a section, source part
        }
        elsif ( ($state <=0) || ($state >= 4) ) {
            next LINE;
        }
        elsif ( /^\(source\)/ ) { $state = 1; next LINE; }
        elsif ( /^\(generated\)/ ) { $state = 2; next LINE; }
        elsif ( /^\(rewritten before read\)/ ) { $state = 3; next LINE; }
        elsif ( ($state == 1) && /^\"([^\"]*)\"\s+(\S+)\s+(\S+)\s+(\S+)\s+\"([^\"]*)\"/ ) {
            # Source file line
            my $file = $1;
            my $time = $2;
            my $size = $3;
            my $md5 = $4;
            my $from_rule = $5;
            if ($state != 1) {
                warn "$My_name: In file-database '$in_name' ",
                     "line $. is outside a section:\n   '$_'\n";
                $errors++;
                next LINE;
            }
            # Set file in database.  But ensure we don't do an unnecessary 
            #    fdb_get, which can trigger a new MD5 calculation, which is
            #    lengthy for a big file.  Ininitially flagging the file
            #    as non-existent solves the problem:
            rdb_ensure_file( $rule, $file, undef, 1 ); 
            rdb_set_file1( $rule, $file, $time, $size, $md5 );
            fdb_set( $file, $time, $size, $md5 );
            # Save the rest of the data, especially the from_rule until we know all 
            #   the rules, otherwise the from_rule may not exist.
            # Also we'll have a better chance of looping through files.
            ${$new_source}{$file} = [ $time, $size, $md5, $from_rule ];
        }
        elsif ( ($state == 2) && /^\"([^\"]*)\"/ ) {
            my $file = $1;
            rdb_one_rule( $rule, sub{ rdb_add_generated($file); } );
        }
        elsif ( ($state == 3) && /^\"([^\"]*)\"/ ) {
            my $file = $1;
            rdb_one_rule( $rule, sub{ rdb_add_rewritten_before_read($file); } );
        }
        else {
            warn "$My_name: In file-database '$in_name' ",
                 "line $. is of wrong format:\n   '$_'\n";
            $errors++;
            next LINE;
        }
    }
    close $in_handle;
    # Get state of dependencies, including creating cus deps if needed
    &rdb_set_dependents( keys %rule_db );
    &rdb_set_rule_net;

    return $errors;
}  # END rdb_read

#************************************************************

sub rdb_read_set_rule {
    # Makes some settings for rule from data as read from .fdb_latexmk.
    # Rule context assumed.  Implicit passing of $dest, $run_time, $check_time,
    # $in_name used as local variables in calling routine rdb_read.
    #
    $$Pno_history = 0;
    $$Prun_time = $run_time;
    $$Pcheck_time = $check_time;
    $$Plast_result = $last_result;
    $$Plast_result_info = 'CACHE';
    
    # Deal with possibility that destination file in fdb_latexmk from
    # run differs from what is currently set. Often that just reflects a
    # difference between the end result of the last run and what the user
    # has requested for this run. 
    # 1. Diagnostics are given, in case that matters.
    # 2. Generally it's only needed to keep the current destination, and to
    #    flag the rule as out-of-date.
    # 3. But special treatmen is needed when the rule is a primary rule and
    #    only the extension of the destination file has changed.
    if ($dest eq $$Pdest) { return; }
    if ( ! rdb_is_active($rule) ) {
        # A common cause: Change of requested files.
        # No other causes known.
        # So just do nothing.
        return;
    }
    # Arrive here if rule is active and previous dest differs from current.
    my ($oldbase, $oldpath, $oldext) = fileparseA( $dest );
    my ($newbase, $newpath, $newext) = fileparseA( $$Pdest );
    if ( ($oldext ne $newext)
         && $possible_primaries{$rule}
         && exists( $allowed_output_ext{$oldext} )
         && ( $oldpath.$oldbase eq $newpath.$newbase )
         && ( ! $inhibit_output_switch )
        )
    {
        # Change only in extension: A common cause: use of \pdfoutput in tex
        # file, with conflict with requested compilation type.  The old
        # extension wins.
        warn "$My_name: In reading the fdb_latexmk file for the previous run of latexmk, I\n",
            "    found that the output extension for '$rule' was '$oldext', but requests for\n",
            "    this run of latexmk give '$newext'.  Probably that was due to a specific\n",
            "    request by the .tex document for output to '$oldext'.\n",
            "    So (if possible) I'll reset the output extension back to '$oldext', which\n",
            "    will be correct on the assumption that the old extension still reflects the\n",
            "    situation with the .tex document. If the assumption is wrong, I'll correct\n",
            "    that after the next run of '$rule'.\n";
        my $switch_error =  switch_output( $rule, $oldext, $newext );
        if ($switch_error) {
            warn "   I could not accommodate the changed output extension.\n",
                 "   That is either because the configuration does not allow it\n",
                 "   or because there is a conflict with implicit or explicit requested filetypes.\n",
                 "   (Typically that is about .dvi and/or .ps filetypes.)\n",
                 "===> There may be subsequent warnings, which may or may not be ignorable.\n",
                 "===> If necessary, clean out generated files and try again\n";
        }
        return;
    }
    # All special cases now dealt with. 
}  #END rdb_read_set_rule

#************************************************************

sub rdb_write {
    # Call: rdb_write( $out_name )
    # Writes to the given file name the database of file and rule data
    #   for all rules needed to make final output
    # Returns 1 on success, 0 if file couldn't be opened.
    local $out_name = $_[0];

    local $out_handle;
    if ( ($out_name eq "") || ($out_name eq "-") ) {
        # Open STDOUT
        open( $out_handle, '>-' );
    }
    else {
       open( $out_handle, '>', $out_name );
    }
    if (!$out_handle) { return 0; }

    #  ??? For safety?
    &rdb_set_rule_net;

    fprint8( $out_handle, "# Fdb version $fdb_ver\n" );
    my @rules = sort &rdb_accessible;
    rdb_for_some(
       \@rules,
       sub { 
           # Omit data on a unused and never-run primary rule:
           if ( ($$Prun_time == 0) 
                && exists( $possible_primaries{$rule} )
                && ! exists( $current_primaries{$rule} )
              )
           { 
               return;
           }
           fprint8( $out_handle, "[\"$rule\"] $$Prun_time \"$$Psource\" \"$$Pdest\" \"$$Pbase\" $$Pcheck_time $$Plast_result\n" );
           rdb_do_files(
               sub { my $from_rule = $from_rules{$file} || '';
                     fprint8( $out_handle, "  \"$file\" $$Ptime $$Psize $$Pmd5 \"$from_rule\"\n" );
               }
           );           
           fprint8( $out_handle, "  (generated)\n" );
           foreach (sort keys %$PHdest) {
               fprint8( $out_handle, "  \"$_\"\n" );
           }
           fprint8( $out_handle, "  (rewritten before read)\n" );
           foreach (sort keys %$PHrewritten_before_read) {
               fprint8( $out_handle, "  \"$_\"\n" );
           }
       }
    );
    close $out_handle;
    return 1;
} #END rdb_write

#************************************************************

sub rdb_set_latex_deps {
    # Call: rdb_set_latex_deps( [inhibit_output_switch] )
    # Assume primary rule context.  
    # This is intended to be applied only for a primary (LaTeX-like) rule.
    # Set its dependents etc, using information from log, aux, and fls files.
    # Use fls file only if $recorder is set, and the fls file was generated
    # on this run.
    # Return: 

    # N.B.  A complication which we try and handle in determining
    #   dependent files is that there may be aliasing of file names,
    #   especially when characters are used in file and directory
    #   names that are not pure 7-bit-ASCII.  Here is a list of some
    #   of the difficulties that do arise, between, on the one hand,
    #   the filenames specified on latexmk's and the cwd found by
    #   latexmk from the system, and, on the other hand, the filenames
    #   and their components reported by *latex in the fls and log
    #   files:
    #      1. Whether the separator of path components is / or \ in
    #         MSWin.
    #      2. Whether the LFN or the SFN is provided.
    #      3. Whether the filenames include the cwd or whether they
    #         are relative to the current directory.
    #      4. Under cygwin, whether the absolute filenames are
    #         specified by UNIX or native MSWin conventions.
    #         (With cygin, the programs used, including the Perl that
    #         executes latexmk, can be any combination of native MSWin
    #         programs and cygwin programs with their UNIX-like
    #         behavior.)
    #      5. Whether UTF-8 or some other coding is used, and under
    #         which circumstances: e.g., in calls to the OS to access
    #         files, in files output by programs, on latexmk's command
    #         line, on other programs' command lines, by the command
    #         interpreterS. 
    #      6. If UTF-8 is used, what kind of canonicalization is used,
    #         if any.  (This is a particular bugbear when files are
    #         transferred between different OSes.)
    #      7. Whether the name of a file in the current directory is
    #         reported as the simple filename or whether it is
    #         preceeded by ".\" or "./".
    #      8. How is it determined whether a pathname is absolute or
    #         relative?  An absolute pathname in MSWin may start with
    #         a drive letter and a colon, but under UNIX-type systems,
    #         the colon is an ordinary character.
    #      9. Whether a filename reported in an fls or log file can be
    #         used as is by perl to access a file, or on the command
    #         line to invoke another program, and whether the use on a
    #         command line depends on whether the command line is
    #         executed by a CLI, and by which CLI.  (E.g., cmd.exe,
    #         v. sh v. tcsh, etc.)
    #     10. Whether such a filename for the filename on *latex's
    #         file agrees with the one on the command line.
    #   The above questions have arisen from actual experiences and
    #   tests.
    #
    #   In any case, when determining dependent files, we will try to
    #   remove an initial directory string from filenames found in the
    #   fls and log files, whenever it denotes the current
    #   directory. The directory string may be an absolute pathname,
    #   such as MiKTeX writes in both fls and log files, or it may be
    #   simply "./" as given by TeXLive in its log file. There are
    #   several reasons for removing a directory string when possible:
    #
    #      1. To avoid having multiple names referring to the same
    #         file in the list of dependents.
    #      2. Because the name may be in a different coding.  Thus
    #         under MSWin 7, cmd.exe and perl (by default) work in an
    #         "ANSI" coding with some code page, but the filenames
    #         written by MiKTeX are UTF-8 coded (and if they are non-ASCII
    #         can't be used for file-processing by Perl without some
    #         trouble).  This is a particular problem if the pathname
    #         contains non-ASCII characters; the directory names may not
    #         even be under the user's control, unlike typical filenames.
    #      3. When it comes to filenames that are then used in calls to
    #         bibtex and makeindex, it is bad to use absolute pathnames
    #         instead of clearly relative pathnames, because the default
    #         security settings are to prohibit writing files to the
    #         corresponding directories, which makes the calls to these
    #         programs unnecessarily fail.
    #
    #   In removing unnecessary directory-specifying strings, to
    #   convert a filename to a simple specification relative to the
    #   current directory, it will be important to preferentially use
    #   a determination of the current directory from the file being
    #   processed.  In the fls file, there is normally a PWD line.  In
    #   the log file, if *latex is started with a filename instead
    #   of a command-executing first line, then this can be determined
    #   from the first few lines of the log file -- see parse_log.
    #   This gives a more reliable determination of the relevant path
    #   string; this is especially important in cases where there is a
    #   mismatch of coding of the current directory, particularly
    #   notable in the above-mentioned case of non-ASCII characters
    #   under MSWin.  Other inconsistencies happen when there is a
    #   mixure of cygwin and native MSWin software. There can also be
    #   inconsistencies between whether the separator of pathname
    #   components is "/" or "\".  So we will allow for this.  The
    #   necessary normalizations of filenames are handled by the
    #   subroutines normalize_filename and normalize_clean_filename.
    #
    #   I have not tried to handle the (currently rare) cases that the
    #   OS is neither UNIX-like nor MSWin-like.
    #
    #   Assumption: the list of generated files in %PHdest was already initialized earlier.
    #     In principle, I should do it here, but useful possibilities (e.g.,
    #     see pythontex-latexmk) for subroutine called to process a .tex to add items to
    #     %PHdest. So initializing here is too late.

    local ($inhibit_output_switch) = @_;
    # Rules should only be primary
    if ( $$Pcmd_type ne 'primary' ) {
        warn "\n$My_name: ==========$My_name: Probable BUG======= \n   ",
             "   rdb_set_latex_deps called to set files ",
             "for non-primary rule '$rule'\n\n";
        return;
    }

#??    # We'll prune this by all files determined to be needed for source files.
#??    my %unneeded_source = %$PHsource;

    # Parse fls and log files to find relevant filenames
    # Result in the following variables:
    local %dependents = ();    # Maps files to status
    local @bbl_files = ();
    local %idx_files = ();     # Maps idx_file to (ind_file, base)
    local %generated_log = (); # Lists generated files found in log file
    local %generated_fls = (); # Lists generated files found in fls file
    local %source_fls = ();    # Lists source files found in fls file
    local %first_read_after_write = (); # Lists source files that are only read
                                  # after being written (so are not true
                                  # source files).
    local $primary_out = $$Pdest;  # output file (dvi or pdf)
    local %conversions = ();   # *latex-performed conversions.
                     # Maps output file created and read by *latex
                     #    to source file of conversion.
    local @missing_subdirs = ();  # Missing subdirectories in aux_dir

    local $pwd_latex = undef;     # Cwd as reported in fls file by *latex

    local %created_rules = ();    # Maps files to rules existing or created to
                                  #  make them. Use to avoid misunderstood
                                  #  dependencies when a package creates a
                                  #  missing file during *latex compliation
                                  #  instead of just allowing to be made later
                                  #  by another rule. 

    # The following are also returned by parsing routines, but are global,
    # to be used by caller:
    # $reference_changed, $bad_reference, $bad_character, $bad_citation, $mult_defined

    # Do I have my own eps-to-pdf conversion?
    my $epspdf_cusdep = 0;
    foreach (@cus_dep_list) {
        if ( /^eps pdf / ) { $epspdf_cusdep = 1; last; }
    }


    # Settings to be found by reading log file:
    our $engine = ''; # Which tex program?  (Use of $latex v.  ... no good, since
                      # can be set to use another program.)
    our $tex_distribution = '';
    local %log_info = (); # Info. returned by get_log_file
    local @log_lines = ();  # Lines in log file after unwrapping and converting
                            # to use my internal CS.
    # Get lines from log file now, with side effect of setting $engine and
    #  $tex_distribution, so parse_fls can adjust its behavior if necessary).
    my $read_log_file = get_log_file( $log_name, \@log_lines, \%log_info );
    if (! $read_log_file ) {
        warn "$My_name: Couldn't read log file '$log_name':\n  $!\n";
    }
    else {
        $engine = $log_info{engine};
        $tex_distribution = $log_info{distribution};
    }


    
    # Analyze fls file first.  It tells us the working directory as seen by *latex
    # But we'll use the results later, so that they take priority over the findings
    # from the log file.
    local $fls_file_analyzed = 0;
    if ($recorder && test_gen_file_time($fls_name) ) {
        $fls_file_analyzed = 
            (0== parse_fls( $fls_name, \%source_fls, \%generated_fls, \%first_read_after_write, \$pwd_latex ));
        if (! $fls_file_analyzed ) {
            warn "$My_name: fls file '$fls_name' appears to have been made but it couldn't be opened.\n";
        }
    }
 
    if ($read_log_file) { parse_log( $log_name, \@log_lines, \%log_info ); }

    my $missing_dirs = 'none';      # Status of missing directories
    if (@missing_subdirs) {
        $missing_dirs = 'success';
        if ($allow_subdir_creation) {
            foreach my $dir ( uniqs( @missing_subdirs ) ) {
                if ( -d $dir ) {
                    $missing_dirs = 'failure';
                    warn "$My_name: ==== Directory '$dir' is said to be missing\n",
                         "     But it exists!\n";
                }
                elsif ( (-e $dir) && (!-d $dir) ) {
                    $missing_dirs = 'failure';
                    warn "$My_name: ==== Directory '$dir' is said to be missing\n",
                         "     But a non-directory file of this name exists!\n";
                }
                else {
                    if (mkdir $dir) {
                        print "$My_name: Directory '$dir' created\n";
                    }
                    else {
                        $missing_dirs = 'failure';
                        warn "$My_name: Couldn't create directory '$dir'.\n",
                             "    System error: '$!'\n";
                    }
                }
            }
        }
        else {
            $missing_dirs = 'not allowed';
            warn_array( "$My_name: There are missing subdirectories, but their creation\n".
                        "    is not allowed.  The subdirectories are:",
                        uniqs(@missing_subdirs) );
       }
    }
    # Use results from fls file.  (N.B. The hashes will be empty if the fls file
    # wasn't used/analyzed, so we don't need a test as to whether the fls file was
    # used.
    foreach (keys %source_fls) {
        if (! -e ) {
            # File is listed in .fls file as read, but doesn't exist now.
            # Therefore it is not a true source file, surely.
            # Sometimes this is caused by a bug (e.g., lualatex in TeXLive 2016, 
            #   2017) when there is an incorrect line in .fls file.  (This
            #   would deserve a warning.)
            # But sometimes (e.g., with minted package), the file could be
            #  created during a run, read, and then deleted.
           next;
        }
        $dependents{$_} = 4;
        if ( /\.bbl$/ ) { push @bbl_files, $_; }
    }
    foreach (keys %generated_fls) {
        if (! -e ) {
            # File is listed in .fls file as written, but doesn't exist now.
            # Therefore it is not a true externally visible generated file.
            # (Typically, e.g., with the minted package, it is a temporary
            #   file created during a run and then deleted during the run.)
            next;
        }
        rdb_add_generated( $_ );
        if ( exists($dependents{$_}) ) {
            $dependents{$_} = 6;
        }
     }

    for my $conv (sort keys %conversions) {
        my $conv_source = $conversions{$conv};
        if ( $conv =~ /^(.*)-eps-converted-to\.pdf$/ ) {
            # Check all the conditions for pdflatex's conversion eps to pdf
            # are valid; if they are, treat the converted file as not a
            # source file.
            my $base = $1;
            if ( (-e $conv_source) && (-e $conv) && ( $conv_source eq "$base.eps" ) ) {
                # $conv isn't a real source of *latex
                rdb_remove_files( $rule, $conv );
                delete $dependents{$conv};
                if ($epspdf_cusdep) {
                    $dependents{"$base.pdf"} = ((-e "$base.pdf") ? 4 : 0 );
                }
            }
        }
    }



# ?? !! Should also deal with .run.xml file

    # Handle result on output file:
    #   1.  Non-existent output file, which is because of no content.
    #         This could either be because the source file has genuinely
    #         no content, or because of a missing input file.  Since a
    #         missing input file might be correctable by a run of some
    #         other program whose running is provoked AFTER a run of
    #         *latex, we'll set a diagnostic and leave it to the
    #         rdb_make to handle after all circular dependencies are
    #         resolved. 
    #   2.  The output file might be of a different kind than expected
    #         (i.e., dvi instead of pdf, or vv).  This could
    #         legitimately occur when the source file (or an invoked
    #         package or class) sets \pdfoutput. 
    $missing_dvi_pdf = '';
    if ($primary_out eq '')  {
        print "$My_name: For rule '$rule', no output was made\n";
        $missing_dvi_pdf = $$Pdest;
    }
    elsif ($primary_out ne normalize_filename($$Pdest) ) {
        my ($actual_base, $actual_path, $actual_ext) = fileparseA( $primary_out );
        my ($intended_base, $intended_path, $intended_ext) = fileparseA( $$Pdest );
        if ( ($actual_ext ne $intended_ext) && (!$inhibit_output_switch) ) {
            warn "$My_name: ===For rule '$rule', the extensions differ between the\n",
                 "   actual output file '$primary_out',\n",
                 "   and the expected output '$$Pdest'.\n";
            if ( ! exists $allowed_output_ext{$actual_ext} ) {
                warn "   Actual output file has an extension '$actual_ext' that\n",
                     "   is not one I know about. I cannot handle this\n";
            }
            else {
                my $switch_error = switch_output( $rule, $actual_ext, $intended_ext );
                if ( $switch_error ) { 
                    warn "   I could not accommodate the changed output extension\n",
                         "   (either because the configuration does not allow it\n",
                         "   or because there is a conflict with requested filetypes).\n";
                    $failure = 1;
                    $failure_msg = 'Could not handle change of output extension';
                }
                else {
                    print "   Rule structure will be changed suitably.\n";
                }
            }
        }
    }

  IDX_FILE:
    foreach my $idx_file ( keys %idx_files ) {
        my ($ind_file, $ind_base) = @{$idx_files{$idx_file}};
        my $from_rule = "makeindex $idx_file";
        if ( ! rdb_rule_exists( $from_rule ) ){
            print "!!!===Creating rule '$from_rule': '$ind_file' from '$idx_file'\n"
                  if ($diagnostics);
            rdb_create_rule( $from_rule, 'external', $makeindex, 'run_makeindex', 1, 
                             $idx_file, $ind_file, $ind_base, 1, 0, 0, 1, [ "$ind_base.ilg" ] );
            print "  ===Source file '$ind_file' for '$rule'\n"
                  if ($diagnostics);
            rdb_ensure_file( $rule, $ind_file, $from_rule );
        }
        # Make sure the .ind file is treated as a detected source file;
        # otherwise if the log file has it under a different name (as
        # with MiKTeX which gives full directory information), there
        # will be problems with the clean-up of the rule concerning
        # no-longer-in-use source files:
        $dependents{$ind_file} = 4;
        if ( ! -e $ind_file ) { 
            # Failure was non-existence of makable file
            # Leave failure issue to other rules.
            $failure = 0;
        }
        $created_rules{$ind_file} = $from_rule;
    }

    local %processed_aux_files = ();
  BBL_FILE:
    foreach my $bbl_file ( uniqs( @bbl_files ) ) {
        my ($bbl_base, $bbl_path, $bbl_ext) = fileparseA( $bbl_file );
        $bbl_base = $bbl_path.$bbl_base;
        my @new_bib_files = ();
        my @new_aux_files = ();
        my @new_bst_files = ();
        my $bcf_file =  "$bbl_base.bcf";
        my $bib_program = 'bibtex';
        if ( test_gen_file( $bcf_file ) ) {
            $bib_program = 'biber';
        }
        my $from_rule = "$bib_program $bbl_base";
        print "=======  Dealing with '$from_rule'\n" if ($diagnostics);
        # Don't change to use activation and deactivation here, rather than
        # creation and removal of rules.  This is because rules are to be
        # created on the fly here with details corresponding to current state
        # of .tex source file(s). So activating a previously inactive rule,
        # which is out-of-date, may cause trouble.
        if ($bib_program eq 'biber') {
            # Remove OPPOSITE kind of bbl generation:
            rdb_remove_rule( "bibtex $bbl_base" );

            parse_bcf( $bcf_file, \@new_bib_files );
        }
        else {
            # Remove OPPOSITE kind of bbl generation:
            rdb_remove_rule( "biber $bbl_base" );
            
            parse_aux( "$bbl_base.aux", \@new_bib_files, \@new_aux_files, \@new_bst_files );
        }
        if ( ! rdb_rule_exists( $from_rule ) ){
            print "   ===Creating rule '$from_rule'\n" if ($diagnostics);
            if ( $bib_program eq 'biber' ) {
                rdb_create_rule( $from_rule, 'external', $biber, '', 1,
                                 $bcf_file, $bbl_file, $bbl_base, 1, 0, 0, 1, [ "$bbl_base.blg" ]  );
            }
            else {
                rdb_create_rule( $from_rule, 'external', $bibtex, 'run_bibtex', 1,
                                  "$bbl_base.aux", $bbl_file, $bbl_base, 1, 0, 0, 1, [ "$bbl_base.blg" ]  );
            }
        }
        $created_rules{$bbl_file} = $from_rule;
        local %old_sources = ();
        rdb_one_rule( $from_rule, sub { %old_sources = %$PHsource; } );
        my @new_sources = ( @new_bib_files, @new_aux_files, @new_bst_files );
        if ( $bib_program eq 'biber' ) {
            push @new_sources, $bcf_file;
        }
        foreach my $source ( @new_sources ) {
            print "  ===Source file '$source' for '$from_rule'\n"
               if ($diagnostics);
            rdb_ensure_file( $from_rule, $source );
            delete $old_sources{$source};
        }
        foreach my $source ( @new_aux_files ) {
            $processed_aux_files{$source} = 1;
        }
        if ($diagnostics) {
            foreach ( keys %old_sources ) {
                print "Removing no-longer-needed dependent '$_' from rule '$from_rule'\n";
            }
        }
        rdb_remove_files( $from_rule, keys %old_sources );
        print "  ===Source file '$bbl_file' for '$rule'\n"
            if ($diagnostics);
        rdb_ensure_file( $rule, $bbl_file, $from_rule );
        if ( ! -e $bbl_file ) { 
            # Failure was non-existence of makable file
            # Leave failure issue to other rules.
            $failure = 0;
        }
    }

    if ( ($#aux_hooks > -1) && ! exists $processed_aux_files{$aux_main} ) {
        my @new_bib_files = ();
        my @new_aux_files = ();
        my @new_bst_files = ();
        parse_aux( $aux_main, \@new_bib_files, \@new_aux_files, \@new_bst_files );
        foreach my $source ( @new_aux_files ) {
            $processed_aux_files{$source} = 1;
        }
    }

NEW_SOURCE:
    foreach my $new_source (keys %dependents) {
        print "  ===Source file for rule '$rule': '$new_source'\n"
            if ($diagnostics);
        if ( exists $first_read_after_write{$new_source} ) {
            if ( dep_at_start($new_source) ) {
                $dependents{$new_source} = 8;
            }
            else {
                $dependents{$new_source} = 6;
            }
        }
        if ( ($dependents{$new_source} == 5)
             || ($dependents{$new_source} == 6)
            ) {
            # (a) File was detected in "No file..." line in log file. 
            #     Typically file was searched for early in run of 
            #     latex/pdflatex, was not found, and then was written 
            #     later in run.
            # or (b) File was written during run. 
            # In both cases, if file doesn't already exist in database, we 
            #    don't know its previous status.  Therefore we tell 
            #    rdb_ensure_file that if it needs to add the file to its 
            #    database, then the previous version of the file should be 
            #    treated as non-existent, to ensure another run is forced.
            rdb_ensure_file( $rule, $new_source, undef, 1 );
        }
        elsif ( $dependents{$new_source} == 7 )  {
            # File was result of conversion by *latex.
            # start of run.  S
            my $cnv_source = $conversions{$new_source};
            rdb_ensure_file( $rule, $new_source );
#            if ($cnv_source && ($cnv_source !~ /\"/ ) ) {
             if ($cnv_source ) {
                # Conversion from $cnv_source to $new_source
                #   implies that effectively $cnv_source is a source
                #   of the *latex run.
                rdb_ensure_file( $rule, $cnv_source );
            }
            # Flag that changes of the generated file during a run 
            #    do not require a rerun:
            rdb_one_file( $new_source, sub{ $$Pcorrect_after_primary = 1; } );
        }
        elsif ( $dependents{$new_source} == 8 )  {
            print "=================  REWRITE '$new_source'\n";
            # File was read only after being written
            # and the file existed at the beginning of the run
            rdb_ensure_file( $rule, $new_source );
            rdb_add_generated( $new_source );
            rdb_add_rewritten_before_read( $new_source );
        }
        else {
            # But we don't need special precautions for ordinary user files 
            #    (or for files that are generated outside of latex/pdflatex). 
            rdb_ensure_file( $rule, $new_source );
        }
        if ( ($dependents{$new_source} == 6) 
             || ($dependents{$new_source} == 7) 
            ) {
            rdb_add_generated($new_source);
        }
    }

    run_hooks( 'latex_file_hooks' );

    # Some packages (e.g., bibtopic) generate a dummy error-message-providing
    #   bbl file when a bbl file does not exist.  Then the fls and log files
    #   show the bbl file as created by the primary run and hence as a
    #   generated file.  Since we now have a rule to create a real bbl file,
    #   the information in the fls and log files no longer represents a
    #   correct dependency, so the bbl file is to be removed from the
    #   generated files.
    foreach (keys %created_rules) { rdb_remove_generated( $_ );  }

    my @more_sources = &rdb_set_dependents( $rule );
    my $num_new = $#more_sources + 1;
    foreach (@more_sources) { 
        $dependents{$_} = 4;
        if ( ! -e $_ ) { 
            # Failure was non-existence of makable file
            # Leave failure issue to other rules.
            $failure = 0; 
            $$Pchanged = 1; # New files can be made.  Ignore error.
        }
    }
    if ($diagnostics) {
        if ($num_new > 0 ) {
            show_array( "$num_new new source files for rule '$rule':", @more_sources );
        }
        else {
            print "No new source files for rule '$rule':\n";
        }
        my @first_read_after_write = sort keys %first_read_after_write;
        if ($#first_read_after_write >= 0) {
            show_array( "The following files were only read after being written:", @first_read_after_write );
        }
    }
    my @files_not_needed = ();
    foreach (keys %$PHsource) {
        if ( ! exists $dependents{$_} ) {
            print "Removing no-longer-needed dependent '$_' from rule '$rule'\n"
              if $diagnostics;
            push @files_not_needed, $_;
        }
    }
    rdb_remove_files( $rule, @files_not_needed );

    return ($missing_dirs, [@missing_subdirs],
            ( $log_info{bad_warning} ? 1 : 0 ) );

} # END rdb_set_latex_deps

#************************************************************

sub switch_output {
    # Usage: switch_output( primary_rule, actual_ext, intended_ext )
    # Rearrange rules to deal with changed extension of output file of
    # the specified primary rule (one of *latex).
    # The switching only works if no request was made for dvi, ps or xdv
    # files, but only if the requested file was pdf.
    # Return 0 on success, non-zero error code on failure.

    my ( $rule, $actual_ext, $intended_ext ) = @_;
    if ( $actual_ext eq $intended_ext ) { return 0; }
    if ( ! $can_switch ) { return 1; }

    if (! defined $possible_primaries{$rule} ) {
        warn "$My_name: BUG: subroutine switch_output called with non-primary rule '$rule'\n";
        return 1;
    }

    # Turn off all pdf producers and all primaries (pdf producing or not).
    # Then reactivate what we need: current rule and whatever else is needed
    # to produce a pdf file.
    # Given that we get here if the rule is not producing the intended kind
    # of output file, it's best to turn off all primaries, so as to make the
    # primary in use unambiguous.
    rdb_deactivate_derequest( 'dvipdf', 'pspdf', 'xdvipdfmx', keys %possible_primaries );
    
    rdb_activate_request( $rule );

    if ( $actual_ext eq '.dvi' ) {
        rdb_activate_request( 'dvipdf' );
        $input_extensions{$rule} = $standard_input_extensions{latex};
    }
    elsif ( $actual_ext eq '.xdv' ) {
        rdb_activate_request( 'xdvipdfmx' );
        $input_extensions{$rule} = $standard_input_extensions{xelatex};
    }
    else {
        $input_extensions{$rule} = $standard_input_extensions{pdflatex};
    }

    my $old_dest = $$Pdest;
    my $new_dest = $$Pdest;
    $new_dest =~ s/$intended_ext$/$actual_ext/;
    # Compensate for MiKTeX's behavior: dvi and pdf are put in out_dir, but xdv is put in aux_dir:
    if ( ($actual_ext eq '.xdv') && ($out_dir ne $aux_dir) ){ $new_dest =~ s/^$out_dir1/$aux_dir1/; }
    if ( ($intended_ext eq '.xdv') && ($out_dir ne $aux_dir) ){ $new_dest =~ s/^$aux_dir1/$out_dir1/; }

    rdb_remove_generated( $old_dest );
    rdb_add_generated( $new_dest );
    $$Pdest = $new_dest;

    &rdb_set_rule_net;
        
    # Some fixes to avoid spurious error conditions:
    $switched_primary_output = 1;
    if (-e $$Pdest) {
        $missing_dvi_pdf = '';
        if ($$Plast_result == 1 ) { $$Plast_result = 0; }
    }
    else { $missing_dvi_pdf = $$Pdest; }

    return 0;
} #END switch_output

#************************************************************

sub test_gen_file {
    # Usage: test_gen_file( filename )
    # Tests whether a file of given name was generated during current run
    #   of *latex, with override of comparison of file and run time by
    #   file being listed in %generated_log or %generated_fls
    # Assumes context for primary rule.
    my $file = shift;
    return exists $generated_log{$file} || $generated_fls{$file}
          || test_gen_file_time($file);
}

#************************************************************

sub test_gen_file_time {
    # Usage: test_gen_file_time( filename )
    # Tests whether a file of given name exists and was generated during 
    #   current run of *latex.  Comparison of file and run time used for
    #   testing whether file was generated or is left over from a previous run.
    #
    my $file = shift;
    return (-e $file) && ( get_mtime( $file ) >= $$Prun_time + $filetime_offset - $filetime_causality_threshold );
}

#************************************************************

sub dep_at_start {
    # Usage: dep_at_start( filename )
    # Tests whether the file was source file and existed at start of run.
    # Assumes context for primary rule.
    my $time = undef;
    rdb_one_file( shift, sub{ $time = $$Ptime; } );
    return (defined $time) && ($time != 0);
}

#************************************************************

sub rdb_find_new_files {
    # Call: rdb_find_new_files
    # Assumes rule context for primary rule.
    # Deal with files which were missing and for which a method
    # of finding them has become available:
    #   (a) A newly available source file for a custom dependency.
    #   (b) When there was no extension, a file with appropriate
    #       extension
    #   (c) When there was no extension, and a newly available source 
    #       file for a custom dependency can make it.

    my %new_includes = ();

MISSING_FILE:
    foreach my $missing ( keys %$PHsource ) {
        next if ( $$PHsource{$missing} != 0 ); 
        my ($base, $path, $ext) = fileparseA( $missing );
        $ext =~ s/^\.//;
        if ( -e "$missing.tex" ) { 
            $new_includes{"$missing.tex"} = 1;
        }
        elsif ( -e $missing ) { 
            $new_includes{$missing} = 1;
        }
        elsif ( $ext ne "" ) {
            foreach my $dep (@cus_dep_list){
               my ($fromext,$toext) = split('\s+',$dep);
               if ( ( "$ext" eq "$toext" )
                    && ( -f "$path$base.$fromext" )
                  )  {
                  # Source file for the missing file exists
                  # So we have a real include file, and it will be made
                  # next time by rdb_set_dependents
                  $new_includes{$missing} = 1;
               }
               else {
                   # no point testing the $toext if the file doesn't exist.
               }
               next MISSING_FILE;
            }
       }
       else {
           # $_ doesn't exist, $_.tex doesn't exist,
           # and $_ doesn't have an extension
           foreach my $dep (@cus_dep_list){
              my ($fromext,$toext) = split('\s+',$dep);
              if ( -f "$path$base.$fromext" ) {
                  # Source file for the missing file exists
                  # So we have a real include file, and it will be made
                  # next time by &rdb__dependents
                  $new_includes{"$path$base.$toext"} = 1;
#                  next MISSING_FILE;
              }
              if ( -f "$path$base.$toext" ) {
                  # We've found the extension for the missing file,
                  # and the file exists
                  $new_includes{"$path$base.$toext"} = 1;
#                  next MISSING_FILE;
              }
           }
       }
    } # end MISSING_FILES

    # Sometimes bad line-breaks in log file (etc) create the
    # impression of a missing file e.g., ./file, but with an incorrect
    # extension.  The above tests find the file with an extension,
    # e.g., ./file.tex, but it is already in the list.  So now I will
    # remove files in the new_include list that are already in the
    # include list.  Also handle aliasing of file.tex and ./file.tex.
    # For example, I once found:
# (./qcdbook.aux (./to-do.aux) (./ideas.aux) (./intro.aux) (./why.aux) (./basics
#.aux) (./classics.aux)

    my $found = 0;
    foreach my $file (keys %new_includes) {
#       if ( $file =~ /\"/ ) {next; }
        my $stripped = $file;
        $stripped =~ s{^\./}{};
        if ( exists $PHsource{$file} ) {
            delete $new_includes{$file};
        }
        else {
            $found ++;
            rdb_ensure_file( $rule, $file );
        }
    }

    if ( $diagnostics && ( $found > 0 ) ) {
        show_array( "$My_name: Detected previously missing files:", sort keys %new_includes );
    }
    return $found;
} # END rdb_find_new_files

#************************************************************

sub rdb_set_dependents {
    # Call rdb_set_dependents( rules ...)
    # Returns array (sorted), of new source files for the given rules.
    local @new_sources = ();
    local @deletions = ();

    rdb_for_some( [@_],  0, \&rdb_one_dep );
    foreach (@deletions) {
        my ($rule, $file) = @$_;
        rdb_remove_files( $rule, $file );
    }
    return uniqs( @new_sources );
} #END rdb_set_dependents

#************************************************************

sub rdb_find_source_file {
    # Helper for searching dependencies in all paths inside the TEXINPUTS
    # environment variable.
    my $test = "$_[0].$_[1]";
    if ( -e $test ) {
        return $_[0];
    }
    if ( exists $ENV{TEXINPUTS} ) {
        foreach my $searchpath (split $search_path_separator, $ENV{TEXINPUTS}) {
            my $file = catfile($searchpath,$_[0]);
            my $test = "$file.$_[1]";
            if ( -e $test ) {
                return $file;
            }
        }
    }
    return "$_[0]";
}

#************************************************************

sub rdb_one_dep {
    # Helper for finding dependencies.  One case, $rule and $file given
    # Assume file (and rule) context for DESTINATION file.

    # Only look for dependency if $rule is primary rule (i.e., latex
    # or pdflatex) or is a custom dependency:
    if ( (! exists $possible_primaries{$rule}) && ($rule !~ /^cusdep/) ) {
        return;
    }
    local $new_dest = $file;
    if ($$PHdest{$new_dest} ) {
        # We already have a way of making the file.
        # No need to find another one.
        return;
    }
    my ($base_name, $path, $toext) = fileparseA( $new_dest );
    $base_name = $path.$base_name;
    $toext =~ s/^\.//;
    my $Pinput_extensions = $input_extensions{$rule};
DEP:
    foreach my $dep ( @cus_dep_list ) {
        my ($fromext,$proptoext,$must,$func_name) = split('\s+',$dep);
        if ( $toext eq $proptoext ) {
            # Look in search path for file of correct name:
            $base_name = rdb_find_source_file($base_name, $fromext);
            my $source = "$base_name.$fromext";
            # Found match of rule
            if ($diagnostics) {
                print "Found cusdep: $source to make $rule:$new_dest ====\n";
            }
            if ( -e $source ) {
                my $from_rule = "cusdep $fromext $toext $base_name";
                my $new_new_dest = "$base_name.$toext";
                if ($$PHdest{$new_new_dest} ) {
                    # We already have a way of making the file.
                    # No need to find another one.
                    return;
                }
                if ($new_new_dest ne $new_dest) {
                    rdb_ensure_file( $rule, $new_new_dest );
                    $new_dest = $new_new_dest;
                }
                local @PAnew_cmd = ( 'do_cusdep', $func_name );
                if ( !-e $new_dest ) {
                    push @new_sources, $new_dest;
                }
                if (! rdb_rule_exists( $from_rule ) ) {
                    print "$My_name: === Creating rule '$from_rule'\n" if $diagnostics;
                    rdb_create_rule( $from_rule, 'cusdep', '', \@PAnew_cmd, 3, 
                                     $source, $new_dest, $base_name, 0 );
                }
                return;
            }
            else {
                # Source file does not exist
                if ( !$force_mode && ( $must != 0 ) ) {
                    # But it is required that the source exist ($must !=0)
                    $failure = 1;
                    $failure_msg = "File '$base_name.$fromext' does not exist ".
                                   "to build '$base_name.$toext'";
                    return;
                }
                elsif ( $from_rules{$file} && ($from_rules{$file} =~ /^cusdep $fromext $toext / ) )  {
                    # Source file does not exist, destination has the rule set.
                    # So turn the from_rule off
                    delete $from_rules{$file};
                }
                else {
                }
            }
        }
        elsif ( ($toext eq '') 
                && (! -e $file ) 
                && (! -e "$base_name.$proptoext" ) 
                && exists $$Pinput_extensions{$proptoext}
              ) {
            # Empty extension and non-existent destination
            #   This normally results from  \includegraphics{A}
            #    without graphics extension for file, when file does
            #    not exist.  So we will try to find something to make it.
            $base_name = rdb_find_source_file($base_name, $fromext);
            my $source = "$base_name.$fromext";
            if ( -e $source ) {
                $new_dest = "$base_name.$proptoext";
                my $from_rule = "cusdep $fromext $proptoext $base_name";
                if ( $$PHdest{$new_dest} ) {
                    # We already have a way of making the file.
                    # No need to find another one.
                    return;
                }
                push @new_sources, $new_dest;
                print "$My_name: Ensuring rule for '$from_rule', to make '$new_dest'\n"
                    if $diagnostics > -1;
                local @PAnew_cmd = ( 'do_cusdep', $func_name );
                if (! rdb_rule_exists( $from_rule ) ) {
                    print "$My_name: === Creating rule '$from_rule'\n" if $diagnostics;
                    rdb_create_rule( $from_rule, 'cusdep', '', \@PAnew_cmd, 3, 
                                     $source, $new_dest, $base_name, 0 );
                }
                rdb_ensure_file( $rule, $new_dest, $from_rule );
                # We've now got a spurious file in our rule.  But don't mess
                # with deleting an item we are in the middle of!
                push @deletions, [$rule, $file];
                return;
            }
        } # End of Rule found
    } # End DEP
    if ( (! -e $file) && $use_make_for_missing_files ) {
        # Try to make the missing file
        #Set character to surround filenames in commands:
        if ( $toext ne '' ) {
             print "$My_name: '$rule': source file '$file' doesn't exist. I'll try making it...\n";
             &Run_subst( "$make $quote$file$quote" );
             if ( -e $file ) {
                 return;
             }
        }
        else {
             print "$My_name: '$rule': source '$file' doesn't exist.\n",
                   "   I'll try making it with allowed extensions \n";
             foreach my $try_ext ( keys %$Pinput_extensions ) {
                 my $new_dest = "$file.$try_ext";
                 &Run_subst( "$make $quote$new_dest$quote" );
                 if ( -e $new_dest ) {
                     print "SUCCESS in making '$new_dest'\n",
                          "I'll ensure '$rule' is rerun.\n";
                     # Put file in rule, without a from_rule, but
                     # set its state as non-existent, to correspond
                     # to file's state before the file was made
                     # This ensures a rerun of *latex is provoked.
                     rdb_ensure_file( $rule, $new_dest, undef, 1 );
                     push @new_sources, $new_dest;
                     push @deletions, [$rule, $file];
                     # Flag need for a new run of *latex despite
                     # the error due to a missing file.
                     $$Pout_of_date_user = 1;
                     return;
                 }
           }
        }
    }
} #END rdb_one_dep

#************************************************************

sub rdb_list {
    # Call: rdb_list()
    # List rules and their source files
    print "===Rules:\n";
    local $count_rules = 0;
    my @accessible_all = &rdb_accessible;
    rdb_for_some( 
        \@accessible_all,
        sub{ $count_rules++; 
             print "Rule '$rule' depends on:\n"; 
           },
        sub{ print "    '$file'\n"; },
        sub{ print "  and generates:\n";
             foreach (keys %$PHdest) { print "    '$_'\n"; }
#             print "  default_extra_generated:\n";
#             foreach (@$PA_extra_gen) { print "    '$_'\n"; }
           },
    );
    if ($count_rules <= 0) {
        print "   ---No rules defined\n";
    }
} #END rdb_list

#************************************************************

sub deps_list {
    # Call: deps_list(fh)
    # List dependent files to file open on fh
    my $fh = $_[0];
    fprint8 $fh, "#===Dependents, and related info, for $filename:\n";
    my @dest_exts = ();
    if ($pdf_mode) {push @dest_exts, '.pdf';}
    if ($dvi_mode) {push @dest_exts, '.dvi';}
    if ($postscript_mode) {push @dest_exts, '.ps';}

    my $deps_space = ' ';
    if ($deps_escape eq 'unix' ) { $deps_space = '\ '; }
    elsif ($deps_escape eq 'nmake' ) { $deps_space = '^ '; }
    $Pescape = sub { 
                    my $name = shift;
                    $name =~ s/ /$deps_space/g;
                    return $name;
    };

    my %source = ( $texfile_name => 1 );
    my @accessible_all = &rdb_accessible;
    rdb_for_some(
        \@accessible_all,
        sub{},
        sub{ $source{$file} = 1; }
    );
    foreach (keys %from_rules) {
        # Remove known generated files from list of source files.
        delete $source{$_};
    }

    show_array( "Sources:", sort keys %source ) if $diagnostics;

    foreach my $ext (@dest_exts) {
         # Don't insert name of deps file in targets.
         # The previous behavior of inserting the name of the deps file
         # matched the method recommended by GNU make for automatically
         # generated prerequisites -- see Sec. "Generating Prerequisites
         # Automatically" of GNU make manual (v. 4.2).  But this can
         # cause problems in complicated cases, and as far as I can see,
         # it doesn't actually help, despite the reasoning given.
         # The only purpose of the deps file is to to determine source
         # files for a particular rule.  The files whose changes make the
         # deps file out-of-date are the same as those that make the real
         # target file (e.g., .pdf) out-of-date. So the GNU method seems
         # completely unnecessary.
       fprint8 $fh, &$Pescape(${out_dir1}.${root_filename}.${ext}), " :";
       foreach (sort keys %source) {
           fprint8 $fh, "\\\n    ", &$Pescape($_);
       }
       fprint8 $fh, "\n";
    }
    fprint8 $fh, "#===End dependents for $filename:\n";
    if ($dependents_phony) {
        fprint8 $fh, "\n#===Phony rules for $filename:\n\n";
        foreach (sort keys %source) {
            fprint8 $fh, "$_ :\n\n";
        }
        fprint8 $fh, "#===End phony rules for $filename:\n";
    }
} #END deps_list

#************************************************************

sub rdb_show {
    # Call: rdb_show()
    # Displays contents of rule data base.
    # Side effect: Exercises access routines!
    print "===Rules:\n";
    local $count_rules = 0;
    rdb_for_actives( 
        sub{ $count_rules++; 
             my @int_cmd = @$PAint_cmd;
             foreach (@int_cmd) {
                 if ( !defined($_) ) { $_='undef';}
             }
             print "  [$rule]: '$$Pcmd_type' '$$Pext_cmd' '@int_cmd' $$Pno_history ",
                 "'$$Psource' '$$Pdest' '$$Pbase' $$Pout_of_date $$Pout_of_date_user\n";
        },
        sub{ print "    '$file': $$Ptime $$Psize $$Pmd5 '", ($from_rules{$file} || ''), "'\n"; }
    );
    if ($count_rules <= 0) {
        print "   ---No rules defined\n";
    }
} #END rdb_show

#************************************************************

sub rdb_target_array {
    # Returns array of all rules implicated by %target_rules and %target_files
    my %rules = &rdb_target_hash;
    return keys %rules;
} # End rdb_target_array

#************************************************************

sub rdb_target_hash {
    # Returns hash mapping to 1 all rules implicated by %target_rules and %target_files
    my %rules = %target_rules;
    foreach (keys %target_files) {
        if (exists $from_rules{$_}) { $rules{$from_rules{$_}} = 1; }
    }
#    show_array( 'target_hash', sort keys %rules );
#    &traceback;
    return %rules;
} # End rdb_target_hash

#************************************************************

sub rdb_accessible {
    # Call: &rdb_accessible
    # Returns array of rules accessible from target rules and rules to make target files

    local %accessible_rules = &rdb_target_hash;
    rdb_recurse( [keys %accessible_rules], sub{ $accessible_rules{$rule} = 1; } );
    return keys %accessible_rules;
} #END rdb_accessible

#************************************************************
#************************************************************
#************************************************************

sub rdb_make {
    # Call: &rdb_make
    # Makes the targets and prerequisites.  
    # Leaves one-time rules to last.
    # Does appropriate repeated makes to resolve dependency loops

    # Returns 0 on success, nonzero on failure.

    # General method: Find all accessible rules, then repeatedly make
    # them until all accessible rules are up-to-date and the source
    # files are unchanged between runs.  On termination, all
    # accessible rules have stable source files.
    #
    # One-time rules are view and print rules that should not be
    # repeated in an algorithm that repeats rules until the source
    # files are stable.  It is the calling routine's responsibility to
    # arrange to call them, or to use them here with caution.
    #
    # Note that an update-viewer rule need not be considered
    # one-time.  It can be legitimately applied everytime the viewed
    # file changes.
    #
    # Note also that the criterion of stability is to be applied to
    # source files, not to output files.  Repeated application of a
    # rule to IDENTICALLY CONSTANT source files may produce different
    # output files.  This may be for a trivial reason (e.g., the
    # output file contains a time stamp, as in the header comments for
    # a typical postscript file), or for a non-trivial reason (e.g., a
    # stochastic algorithm, as in abcm2ps).   
    #
    # This caused me some actual trouble in certain cases, with circular
    # dependencies causing non-termination when the standard
    # stability-of-source-file algorithm is applied, together with
    # non-optimality if the depedence isn't actually circular: e.g., from a
    # rerun of X-to-pdf cusdep, where the pdf file is unchanged from
    # previous one aside from a time of generation comment.  The following
    # situation is an example of a generic situation where a change from
    # the standard stability-of-input-files criterion must be modified in
    # order to obtain proper results: 
    #    1.  A/the latex source file contains specifications for
    #        certain postprocessing operations.  Standard *latex 
    #        already has this, for indexing and bibliography.
    #    2.  In the case in point that caused me trouble, the
    #        specification was for musical tunes that were contained
    #        in external source files not directly input to
    #        *latex.  But in the original version, there was a
    #        style file (abc.sty) that caused latex itself to call
    #        abcm2ps **un**conditionally to make .eps files for each tune
    #        that was to be read in on the next run of latex.
    #    3.  Thus the specification can cause a non-terminating loop
    #        for latexmk, because the output files of abcm2ps changed
    #        on every run, even with identical input.  
    #    4.  The solution was to 
    #        a. Use a style file abc_get.sty that simply wrote the
    #           specification on the tunes to the .aux file in a
    #           completely deterministic fashion.
    #        b. Instead of latex, use a script abclatex.pl that runs
    #           latex and then extracts the abc contents for each tune
    #           from the source abc file.  This is also
    #           deterministic. 
    #        c. Use a cusdep rule in latexmk to convert the tune abc
    #           files to eps.  This is non-deterministic, but only
    #           gets called when the (deterministic) source file
    #           changes.
    #        This solves the problem.  Latexmk works.  Also, it is no
    #        longer necessary to enable write18 in latex, and multiple
    #        unnecessary runs of abcm2ps are no longer used.

    #        [**N.B.** Other sty files have similar problems, of
    #        unconditional write18s to make eps, pdf or other files. That's
    #        always non-optimal, often highly so --- see at least one of
    #        the example_latexmkrc files for real cases. But work is needed
    #        on the package to do better, which has been done in some
    #        packages. It is also possible to do better with a suitable
    #        configuration of latexmk with write18 turned off. E,g,,
    #        perhaps a cusdep, or a fancy used of a subroutine for *latex
    #        --- see the example_latexmkrc files for examples.]
    #
    # The method used is conditioned on:
    #    1.  The network of active rules is constructed, with dependencies
    #        linking the rules.  The network may change during the
    #        make. Notably, dependency information can be discovered from
    #        the results of runs of rules, especially *latex. This involves
    #        addition (and deletion) of items in the source-file list of a
    #        rule. It also involves addition (or deletion) of rule-nodes
    #        for e.g., cusdeps, bibtex, makeindex.  Bigger changes
    #        sometimes occur --- e.g., when a .tex document chooses a
    #        kind of output file from the expected one: e.g., pdf to dvi or
    #        vice versa.
    #    2.  The *latex rules are called primary rules, and are the core
    #        source of dependency information (as ultimately determined by
    #        the .tex file(s). Only one primary rule is active.  That was
    #        enforced by initialization.
    #    3.  There are generally loops of dependencies.  The overall aim is
    #        to keep looping through rules until the content of the source
    #        files for each rule is unchanged from the previous run.  Given
    #        the basic assumption that it is the content of these files
    #        that determines the output, stability of input files gives
    #        stability of output.
    #    4.  During the loop, the main criterion for running a rule is
    #        that the current contents of the source files are changed
    #        compared with the state saved in the rule.  This is
    #        supplemented by the condition that a rule not previously run
    #        (under latexmk control) is to be run unconditionally.
    #    5.  In addition, there are specified dependencies not going via a
    #        set of files not known to latexmk as source files of the
    #        target rule.  The primary examples are dvips, dvipdf, etc,
    #        which use graphics files; these are specified to have a dvi
    #        producing fule (e.g., latex) as a source rule.  Such a rule is
    #        to be run after the source rule has been run.
    #    6.  There are special cases, coded in rdb_rerun_needed and
    #        rdb_file_change1. 
    #    7.  Immediately before running a rule, the saved state of its
    #        source files is updated to their current state.  If there is
    #        no error in the run, the source-file-state is **not** updated
    #        after the rule is run.  Then on a subsequent pass through
    #        rdb_make's main loop, when the rule is tested for a rerun, any
    #        change in source file contents is cause for running the rule
    #        again.
    #    8.  But after a run giving an error, the state of the generated
    #        files (i.e., non-user files) is updated to the current state.
    #        This is because the error (under normal circumstances) must be
    #        corrected by user action: e.g., correcting a source file, and
    #        possibly deleting some corrupted auxiliary file.  Files (e.g.,
    #        .aux by *latex) generated by the rule just run may well have
    #        changed, so updating their state to the current state prevents
    #        another run before a user change.  If a file was generated by
    #        another rule, it won't have changed its state, so updating its
    #        state won't matter.  But a non-generated file is a
    #        user-created file, and a rerun is entailed if its contents
    #        changed compared with the start of the run; it's the
    #        start-of-run contents that were used in the error run.
    #    9.  Note: an error may be caused by a problem with a file
    #        generated by another rule, e.g., a bbl file created by bibtex
    #        and read by *latex, but with no error reported by bibtex.  To
    #        correct the error a source file (possibly more than once
    #        removed must be changed).  That triggers a rerun of the
    #        producing rule, and after that the resulting change causes a
    #        rerun of the original rule that had the error.  E.g.,
    #        correcting a .bib file causes bibtex to run, producing a
    #        corrected .bbl file, after which *latex is caused to be run.
    #    10. With circular dependencies, there is a choice of which order
    #        to examine the rules.  Generally, primary rules are more 
    #        time-consuming than most others, so the choice of the order of
    #        examination of rules to check out-of-dateness is to try to
    #        minimize the number of primary runs.  The other time-consuming
    #        rules are things like xdvipdfmx in documents with much
    #        graphics. These are normally outside a dependency loop, so
    #        those are left to last.  Even if they are inside a dependency
    #        loop, they need the primary rule to have been run first.
    #    11. After rdb_make is run, all non-user source files are updated
    #        to their current state.  Rules are considered up-to-date
    #        here. On a subsequent call to rdb_make, subsequent changes are
    #        relevant to what is to be done.  Note: the states of user
    #        files aren't updated.  This guards against user caused changes
    #        that are made between the start of the run of a rule and the
    #        end of rdb_make.
    #
    #        [Comment: Possible scenario for dvips, xdvipdfmx etc in loop:
    #        Document is documentation for viewer. At some page, the result
    #        in the viewer is to be displayed, with the display in the
    #        viewer being a neighboring page of the document, so the
    #        relevant page is extracted from the pdf file (or ...), and
    #        then processed into a graphics file to be included in the
    #        document.] 
    #
    # This leads to the following approach:
    #    1.  Classify accessible rules as: primary, pre-primary
    #        (typically cusdep, bibtex, makeindex, etc), post-primary
    #        (typically dvips, etc), and one-time.
    #        This step is the start of rdb_make's main "PASS" loop.
    #    2.  Go over the pre-primaries, the primary and the
    #        post-primaries. Examine each rule for out-of-dateness; if 
    #        out-of-date run it.
    #    3.  Just before a run of a rule, update its source file state to
    #        the current state of the files.
    #    4.  After the rule is run, at least after a primary rule is run,
    #        examine the dependency information available (.fls, .log, .aux
    #        files) and updated the rule configuration. This can involve
    #        radical changes in the rule network: E.g., a newly found use
    #        of bibtex or makeindex, or even more radical rearrangements,
    #        if for example (under document control) *latex produces a .dvi
    #        file instead of an expected .pdf file.
    #    5.  If in any pass through the loop one (or more) of the
    #        pre-primary and primary rules is run, don't go on to examine
    #        the post-primaries. Not only are these are sometimes
    #        time-consuming and are almost always outside the dependency
    #        loops involving the primary, but, most importantly, dealing
    #        with the dependency information from a primary rule can change
    #        the rule network a lot.
    #        Instead go back to step 1.
    #    6.  Once visiting the pre-primaries and primaries no longer
    #        triggers any run, i.e., those rules are all stable, go on to
    #        the post-primaries.
    #    7.  If one or more of the post-primaries has been run, go back to
    #        1. This allows for the possibility that a post-primary rule is
    #        part of a dependency loop.  This is highly unusual for a
    #        normal document, but not impossible in principle.  See earlier
    #        for a conceivable example.
    #    10. Thus we finish the looping when no further run has been
    #        triggered by an examination of all of the pre-primary,
    #        primary, post-primary rules.
    #    11. In addition, the loop is terminated if the number of
    #        applications of a rule exceeds a configured maximum. This
    #        guards agains the possibility that it may never be possible to
    #        get stable output, i.e., there is an infinite loop.  It is
    #        impossible for an algorithm to determine in general whether
    #        there is an infinite loop.  (An example of the Turing halting
    #        theorem.) But normal documents need a decidable modest number
    #        of passes through the loop.  Any exceeding of the limit on the
    #        number of passes needs examination. 
    #    12. Finally apply one-time rules.  These are rules that by their
    #        nature are both outside of any dependency a loop and are ones
    #        that should be applied last.  Standard ones including running
    #        a viewer or causing it to be updated.  The standard ones are
    #        not actually in the class of rules that rdb_make runs. Instead
    #        they are run by the calling routines, since the needs may be
    #        quite special.

    # ???!!! Overkill?
    &rdb_set_rule_net;

    local %pass = ();     # Counts runs on each rule: Used for testing for
                          # exceeding maximum runs and for determining
                          # whether to run rules that have a list of source
                          # rules. (E.g., dvips, which is to be run
                          # whenever latex has been run to make a dvi
                          # file. This because the list of source files of
                          # dvips misses all graphics files, and so the
                          # source file method is insufficient for deciding
                          # on a rerun.)
    rdb_for_some( [keys %rule_db],
                 sub{ $pass{$rule} = 0; 
                      foreach (keys %$PHsource_rules) {
                          $$PHsource_rules{$_} = 0;
                      }
                  }
        );

    local $failure = 0;        # General accumulated error flag
    local $missing_dvi_pdf = ''; # Did primary run fail to make its output file?
    local $runs = 0;
    local $runs_total = 0;
    local $too_many_passes = 0;
    local $switched_primary_output = 0;
    local @warning_list = ();  # Undef refs etc reported in last primary run
    my $retry_msg = 0;         # Did I earlier say I was going to attempt 
                               # another pass after a failure?
    my %changes = ();  # For reporting of changes
  PASS:
    while (1==1) {
        # Exit condition at end of body of loop.
        $runs = 0;
        $switched_primary_output = 0;
        my $previous_failure = $failure;
        $failure = 0;
        local $newrule_nofile = 0;  # Flags whether rule created for
                           # making currently non-existent file, which
                           # could become a needed source file for a run
                           # and therefore undo an error condition
        foreach my $rule (keys %rule_db) {
            # Update %pass in case new rules have been created
            if (! exists $pass{$rule} ) { $pass{$rule} = 0; }
        }
        if ($diagnostics) {
            print "Make: doing pre_primary and primary...\n";
        }
        # Do the primary run preceeded by pre_primary runs, all only if needed.
        #      On return, $runs == 0 signals that nothing was run (and hence
        #      no output files changed), either because no input files
        #      changed and no run was needed, or because the
        #      number of passes through the rule exceeded the
        #      limit.  In the second case $too_many_runs is set.
        rdb_for_some( [@pre_primary, $current_primary], \&rdb_make1 );
        if ($switched_primary_output) {
            print "=========SWITCH OF OUTPUT WAS DONE.\n";
            next PASS;
        }
        if ( ($runs > 0) && ! $too_many_passes ) {
            $retry_msg = 0;
            if ( $force_mode || (! $failure) || $switched_primary_output ) {
                next PASS;
            }
            # Get here on failure, without being in force_mode
            if ( $newrule_nofile ) { 
                $retry_msg = 1;
                print "$My_name: Error on run, but found possibility to ",
                      "make new source files\n";
                next PASS;
            }
            elsif ( rdb_user_changes( \%changes, @pre_primary, $current_primary )) {
                print "$My_name: Some rule(s) failed, but user file(s) changed ",
                    "so keep trying\n";
                rdb_diagnose_changes2( \%changes, "", 1 ) if (!$silent);
                next PASS;
            }
            else { last PASS; }
        }
        if ($runs == 0) {
            # $failure not set on this pass, so use value from previous pass:
            $failure = $previous_failure;
            if ($retry_msg) {
                print "But in fact no new files made\n";
            }
            if ($failure && !$force_mode ) { last PASS; }
        }
        if ( $missing_dvi_pdf ) { 
            # No output from primary, after completing circular dependence
            warn "Failure to make '$missing_dvi_pdf'\n";
            $failure = 1; 
            last PASS;
        }    
        if ($diagnostics) {
            print "Make: doing post_primary...\n";
        }
        rdb_for_some( [@post_primary], \&rdb_make1 );
        if ( ($runs == 0) || $too_many_passes ) {
            # If $too_many_passes is set, it should also be that
            # $runs == 0; but for safety, I also checked
            # $too_many_passes.
            last PASS;
        }
     }
     continue {
         # Re-evaluate rule classification and accessibility,
         # but do not change primaries.
         # Problem is that %current_primaries gets altered
         &rdb_set_rule_net;
    }  #End PASS

    rdb_for_some( [@unusual_one_time], \&rdb_make1 );

    #---------------------------------------
    # All of make done. Finish book-keeping:
    # 1. Update state of source files suitably.
    # 2. Update fdb_latexmk file, if needed.
    # 3. Diagnostics.
    # 4. Other book-keeping and clean up.

    ############ Update state of source files.  Complications:
    # **Either** success.  Then the algorithms arrange that the contents of
    #       source files have stabilized between start and end of run of rule,
    #       so that output files have also stabilized.
    # **or** failure. Then processing is normally aborted, so source files
    #       that are generated may not have stabilized, e.g., .aux file.
    # At the next round of compilation (or test for a need for a rerun, as in
    # make_preview_continuous), the criterion for a rerun of a rule is that
    # source file(s) have changed relative to the saved state.
    # At this point the saved file state for each rule is the state just
    # before its last run.  After a successful make, that gives correct
    # behavior, including for user files (i.e., non-generated files). But
    # not always after a failure.
    #
    # **So at this point we set state of generated source files to current
    # state.**
    #
    # Normally there are no further changes in generated files, so they
    # won't trigger reruns, only changes in user files will do that.
    # That's correct behavior.
    # But occasionally generated files have errors that block further
    # processing, as is known for .aux and .bbl files. Then user can
    # delete .aux and .bbl and thereby trigger a rerun.  It also optimizes
    # testing for changes, since, e.g., an .aux file of the same content but
    # a different time than the current file will have its md5 signature
    # recomputed during a check for a rerun.  But when both time and size
    # are unchanged, the test is optimized by assuming no change, and it
    # doesn't do the md5 calculation.
    #
    # **However**, we will not update the state of the user files (i.e.,
    # the non-generated files).  This is because when the user notices an
    # error during a run, they may correct the error in a .tex file say,
    # but both too late to trigger a *latex and too early to be a post-make
    # changed. Then it is correct to compare the current state of a user
    # source file with its state just before the last run.
    #
    # In addition, we only update the file state for active rules, i.e.,
    # those that the current use of make is supposed to have made
    # up-to-date.
    # Only do file-state update if something was run, otherwise it's work
    # for nothing.
    
    if ($runs_total > 0) {
        rdb_for_some( [rdb_accessible()], \&rdb_update_gen_files );
        rdb_write( $fdb_name );
    }
    else { print "$My_name: Nothing to do for '$texfile_name'.\n"; }

    # Diagnostics
    if ($#primary_warning_summary > -1) {
        # N.B. $mult_defined, $bad_reference, $bad_character, $bad_citation also available here.
        show_array( "$My_name: Summary of warnings from last run of *latex:", 
                    @primary_warning_summary );
    }
    if ( ($#warning_list >= 0) && !$silence_logfile_warnings ) {
        warn "$My_name: ====List of undefined refs and citations:\n";
        for (my $i = 0; $i <= $#warning_list; $i++) {
            if ($i >= $max_logfile_warnings ) {
                warn " And ", $#warning_list + 1 - $i, " more --- see log file.\n";    
                last;
            }
            warn "  $warning_list[$i]\n";
        }
    }

    if (! $silent) {
        if ($failure && $force_mode) {
            print "$My_name: Errors, in force_mode: so I tried finishing targets\n";
        }
        elsif ($failure) {
            print "$My_name: Errors, so I did not complete making targets\n";
        }
        else {
#            local @dests = ( keys %current_primaries, @pre_primary, @post_primary, @unusual_one_time );
            local @rules = ( keys %current_primaries, @post_primary, @unusual_one_time );
            local @dests = ();
            rdb_for_some( [@rules], sub{ push @dests, $$Pdest if ($$Pdest); } );
            print "$My_name: All targets (@dests) are up-to-date\n";
        }
    }

    # ???!!! Rethink use of %pass, and it's scoping.
    # Currently %pass is local in rdb_make and is used only to determine
    # whether a rule needs to be run because a source rule has been run,
    # and this would be within the same call to rdb_make.
    # OLD COMMENT: Update source_rules.  Is this too late?  I don't think so, it's
    # internal to make and to multiple calls to it (pvc).  Is this
    # necessary?
    rdb_for_some( [keys %rule_db],
                   sub{ 
                        foreach my $s_rule (keys %$PHsource_rules) {
                            $$PHsource_rules{$s_rule} = $pass{$s_rule};
                        }
                   }
        );
    return $failure;
} #END rdb_make

#-------------------

sub rdb_show_rule_errors {
    local @errors = ();
    local @warnings = ();
    rdb_for_actives( 
        sub {
            my $message_tail = "";
            if ( $$Plast_result_info eq 'PREV' ) {
                $message_tail = " in previous round of document compilation.";
            }
            elsif ( $$Plast_result_info eq 'CACHE' ) {
                $message_tail = " in previous invocation of $my_name.";
            }
            if ($$Plast_message ne '') {
                if ($$Plast_result == 200) {
                    push @warnings, "$rule: $$Plast_message";
                 }
                 else {
                    push @errors, "$rule: $$Plast_message";
                 }
            }
            elsif ($$Plast_result == 1) {
                push @errors, "$rule: failed to create output file$message_tail";
            }
            elsif ($$Plast_result == 2) {
                push @errors, "$rule: gave an error$message_tail";
            }
            elsif ($$Prun_time == 0) {
                #  This can have innocuous causes.  So don't report
            }
        }
    );
    if ($#warnings > -1) { 
        show_array( "Collected warning summary (may duplicate other messages):". @warnings );
    }
    if ($#errors > -1) { 
        show_array( "Collected error summary (may duplicate other messages):", @errors );
    }
    return $#errors+1;
}

#-------------------

sub rdb_make1 {
    # ???!!! Rethink how $$Pout_of_date is reset at end.
    # Call: rdb_make1
    # Helper routine for rdb_make.
    # Carries out make at level of given rule (all data available).
    # Assumes contexts for recursion, make, and rule, and
    # assumes that source files for the rule are to be considered
    # up-to-date.
    our $rule;
    if ($diagnostics) { print "  Make for rule '$rule'\n"; }
    # Is this needed?  Yes; rdb_make1 is called on a sequence of rules and
    # if one gives an error, then it provides source files directly or
    # indirectly to later rules, which should not be run.
    if ($failure & ! $force_mode) {return;}

    # Rule may have been created since last run.  Just in case we didn't,
    # define $pass{$rule} elsewhere, do it here:
    if ( ! defined $pass{$rule} ) {$pass{$rule} = 0; }

    # Special fix up for bibtex:
    my $bibtex_not_run = -1;   # Flags status as to whether this is a
        # bibtex rule and if it is, whether out-of-date condition is to
        # be ignored.
        #  -1 => not a bibtex rule
        #   0 => no special treatment
        #   1 => don't run bibtex because of non-existent bibfiles
        #           (and setting to do this test)
        #   2 => don't run bibtex because of setting
    my @missing_bib_files = ();
    if ( $rule =~ /^(bibtex|biber)/ ) {
        $bibtex_not_run = 0;
        if ($bibtex_use == 0) {
           $bibtex_not_run = 2;
        }
        elsif ( ($bibtex_use == 1) || ($bibtex_use == 1.5) ) {
            # Conditional run of bibtex (or biber) depending on existence of .bib file.
            foreach ( keys %$PHsource ) {
                if ( ( /\.bib$/ ) && (! -e $_) ) {
                    push @missing_bib_files, $_;
                    $bibtex_not_run = 1;
                }
            }
        }
    }

    if ( ! rdb_rerun_needed(\%changes, 0) ) { return; }

    # Set this in case of early exit:
    # ???!!! Check I am setting $missing_dvi_pdf correctly.
    if ( $$Pdest && (! -e $$Pdest)  && ( $$Pcmd_type eq 'primary' ) ) {
        $missing_dvi_pdf = $$Pdest;
    }

    if (!$silent) { 
        print "$My_name: applying rule '$rule'...\n";
        &rdb_diagnose_changes2( \%changes, "Rule '$rule': ", 0 );
    }

    # We are applying the rule, so its source file state for when it was
    # last made is as of now.  This is do in the subroutines that do the
    # actual run, to allow for possible calls to them from other places.

    # The actual run
    my $return = 0;   # Return code from called routine

    if ( $pass{$rule} >= $max_repeat ) {
        # Avoid infinite loop by having a maximum repeat count
        # Getting here represents some kind of weird error.
        warn "$My_name: Maximum runs of $rule reached ",
             "without getting stable files\n";
        $too_many_passes = 1;
        # Treat rule as completed, else in -pvc mode get infinite reruns:
        $$Pout_of_date = 0;
        $failure = 1;
        $failure_msg = "'$rule' needed too many passes";
        return;
    }

    $runs++;
    $runs_total++;

    $pass{$rule}++;
    if ($bibtex_not_run > 0) {
        if ($bibtex_not_run == 1 ) {
            show_array ("$My_name: I WON'T RUN '$rule' because I don't find the following files:",
                        @missing_bib_files);
        }
        elsif ($bibtex_not_run == 2 ) {
            warn "$My_name: I AM CONFIGURED/INVOKED NOT TO RUN '$rule'\n"; 
        }
        $return = &rdb_dummy_run0;
    }
    else {
        warn_running( "Run number $pass{$rule} of rule '$rule'" );
        $return = &rdb_run1;
    }
    if ($$Pchanged) {
        $newrule_nofile = 1;
        $return = 0;
    }
    elsif ( $$Pdest && ( !-e $$Pdest ) && (! $failure) ){
        # If there is a destination to make, but for some reason
        #    it did not get made, and no other error was reported, 
        #    then a priori there appears to be an error condition:
        #    the run failed.   But there are some important cases in
        #    which this is a wrong diagnosis.
        if ( ( $$Pcmd_type eq 'cusdep') && $$Psource && (! -e $$Psource) ) {
            # However, if the rule is a custom dependency, this is not by
            #  itself an error, if also the source file does not exist.  In 
            #  that case, we may have the situation that (1) the dest file is no
            #  longer needed by the tex file, and (2) therefore the user
            #  has deleted the source and dest files.  After the next
            #  latex run and the consequent analysis of the log file, the
            #  cusdep rule will no longer be needed, and will be removed.

            # So in this case, do NOT report an error
            $$Pout_of_date = 0;
        }
        elsif ($$Pcmd_type eq 'primary' ) { 
            # For a primary rule, i.e., *latex, not to produce the 
            #    expected output file may not be an error condition.  
            # Diagnostics were handled in parsing the log file.
            # Special action in main loop in rdb_make
            $missing_dvi_pdf = $$Pdest;
        }
        elsif ($return == -2) {
           # Missing output file was reported to be NOT an error
           $$Pout_of_date = 0;
        }
        elsif ( ($bibtex_use <= 1.5) && ($bibtex_not_run > 0) ) {
           # Lack of destination file is not to be treated as an error
           # for a bibtex rule when latexmk is configured not to treat
           # this as an error, and the lack of a destination file is the
           # only error.
           $$Pout_of_date = 0;
        }
        else {
            $failure = 1;
        }
    }
    if ( ($return != 0) && ($return != -2) ) {
        $failure = 1; 
        $$Plast_result = 2;
        if ( !$$Plast_message ) {
            $$Plast_message = "Run of rule '$rule' gave a non-zero error code";
        }
        # Update state of generated source files, but not non-generated,
        # i.e., user source files. Thus any change in the rule's own
        # generated source files during the run will not cause a
        # rerun. Files generated by another rule should not have been
        # changed during the run, so updating their saved state in this
        # rule is a NOP.  But any change in user files since the **start**
        # of the run is a cause for a rerun, so their saved state must not
        # be updated.
        rdb_update_gen_files();
    }
    foreach ( keys %$PHsource_rules ) {
        $$PHsource_rules{$_} = $pass{$_};
    }
}  #END rdb_make1

#************************************************************

sub rdb_run1 {
    # Assumes context for: rule.
    # Unconditionally apply the rule
    # Returns return code from applying the rule.
    # Otherwise: 0 on other kind of success, 
    #            -1 on error, 
    #            -2 when missing dest_file is to be ignored

    # Defaults for summary of results of run.
    $$Prun_time = time();

    $$Pchanged = 0;       # No special changes in files
    $$Plast_result = 0;
    $$Plast_result_info = 'CURR';
    $$Plast_message = '';
    my $latex_like = ($$Pcmd_type eq 'primary'); 

    # Return value for external command:
    my $return = 0;

# Source file data, by definition, correspond to the file state just
# before the latest run, and the run_time to the time just before the run:
    if ($latex_like) {
        # For *latex, we will generate the list of generated files from the
        # analysis of the results of the run.  So before the run we must
        # reset the list of generated files saved in the rule data. Otherwise
        # it can continue to contain out-of-date items left from the previous
        # run.  (Think bibtopic, which writes bbl files!)
        #
        # This reset is not used/needed for other rules, since normally no
        # analysis of a log file (or similar) is made to find generated
        # files.  The set of extra generated files beyond the main
        # destination file  is hard wired into the rule definition.
        # 
        &rdb_initialize_generated;
    }
    # Now set the current state of the files
    &rdb_update_files;

    # Find any internal command
    my @int_args = @$PAint_cmd;
    my $int_cmd = shift @int_args;
    my @int_args_for_printing = @int_args;
    foreach (@int_args_for_printing) {
        if ( ! defined $_ ) { $_ = 'undef'; }
    }

# ==========  Now the actual run of the command or ... for the rule ==========
# But first save current total processing time for the process, so that after
# the run of the command for the rule we can measure the processing time of
# the rule (without overhead from other work latexmk does):

    if ($latex_like) { run_hooks( 'before_xlatex' ); }

    my $time_start = processing_time();
   
    if ($int_cmd) {
        print "For rule '$rule', use internal command '\&$int_cmd( @int_args_for_printing )' ...\n"
            if $diagnostics;
        $return = &$int_cmd( @int_args ); 
    }
    elsif ($$Pext_cmd) {
        $return = &Run_subst() / 256;
    }
    else {
        warn "$My_name: Either a bug OR a configuration error:\n",
             "    No command provided for '$rule'\n";
        traceback();
        $return = -1;
        $$Plast_result = 2;
        $$Plast_message = "Bug or configuration error; incorrect command type";
    }
    add_timing( processing_time() - $time_start, $rule );

#============================================================================


    # Analyze the results of the run, the first step of which is highly rule
    # dependent, and may reassess the return code in $return.
    # ????? Probably it would be best at a later revision to have analysis
    # subroutines for each special case instead of in-line code here; there
    # could possibly a user-configurable per-rulehook.
    #
    $$Pout_of_date = $$Pout_of_date_user = 0;
    if ($latex_like) {
        &correct_aux_out_files;
        run_hooks( 'after_xlatex' );
        $return = analyze_latex_run( $return );
        run_hooks( 'after_xlatex_analysis' );
    }
    elsif ( $rule =~ /^biber/ ) {
        my @biber_datasource = ( );
        my $retcode = check_biber_log( $$Pbase, \@biber_datasource );
        foreach my $source ( @biber_datasource ) {
#           if ( $source =~ /\"/ ) {next; }
            print "  ===Source file '$source' for '$rule'\n"
               if ($diagnostics);
            rdb_ensure_file( $rule, $source );
        }
        if ($retcode == 5) {
        # Special treatment if sole missing file is bib file
        # I don't want to treat that as an error
            $return = 0;
            $$Plast_result = 200;
            $$Plast_message = "Could not find bib file for '$$Pbase'";
            push @warnings, "Bib file not found for '$$Pbase'";
        }
        elsif ($retcode == 6) {
           # Missing control file.  Need to remake it (if possible)
           # Don't treat missing bbl file as error.
           print "$My_name: bibtex control file missing.  Since that can\n",
                "   be recreated, I'll try to do so.\n";
           $return = -2;
           rdb_for_some( [keys %current_primaries], sub{ $$Pout_of_date = 1; } );
        }
        elsif ($retcode == 4) {
            $$Plast_result = 2;
            $$Plast_message = "Could not find all biber source files for '$$Pbase'";
            push @warnings, "Not all biber source files found for '$$Pbase'";
        }
        elsif ($retcode == 3) {
            $$Plast_result = 2;
            $$Plast_message = "Could not open biber log file for '$$Pbase'";
            push @warnings, $$Plast_message;
        }
        elsif ($retcode == 2) {
            $$Plast_message = "Biber errors: See file '$$Pbase.blg'";
            push @warnings, $$Plast_message;
        }
        elsif ($retcode == 1) {
            push @warnings, "Biber warnings for '$$Pbase'";
        }
        elsif ($retcode == 10) {
            push @warnings, "Biber found no citations for '$$Pbase'";
            # Biber doesn't generate a bbl file in this situation.
            $return = -2;
        }
        elsif ($retcode == 11) {
            push @warnings, "Biber: malformed bcf file for '$$Pbase'.  IGNORE";
            if (!$silent) {
               print "$My_name: biber found malformed bcf file for '$$Pbase'.\n",
                    "  I'll ignore error, and delete any bbl file.\n";
            }
            # Malformed bcf file is a downstream consequence, normally,
            # of an error in *latex run.  So this is not an error
            # condition in biber itself.
            # Current version of biber deletes bbl file.
            # Older versions (pre-2016) made an incorrect bbl file, which
            # tended to cause latex errors, and give a self-perpetuating error.
            # To be safe, ensure the bbl file doesn't exist.
            unlink $$Pdest;
            # The missing bbl file is now not an error:
            $return = -2;
        }
    }
    elsif ( $rule =~ /^bibtex/ ) {
        my $retcode = check_bibtex_log($$Pbase);
        if ( ! -e $$Psource ) {
            $retcode = 10;
            if (!$silent) {
                print "Source '$$Psource' for '$rule' doesn't exist,\n",
                    "so I'll force *latex to run to try and make it.\n";
            }
            rdb_for_some( [keys %current_primaries], sub{ $$Pout_of_date = 1; } );
        }
        if ($retcode == 3) {
            $$Plast_result = 2;
            $$Plast_message = "Could not open bibtex log file for '$$Pbase'";
            push @warnings, $$Plast_message;
        }
        elsif ($retcode == 2) {
            $$Plast_message = "Bibtex errors: See file '$$Pbase.blg'";
            $failure = 1;
            push @warnings, $$Plast_message;
        }
        elsif ($retcode == 1) {
            push @warnings, "Bibtex warnings for '$$Pbase'";
        }
        elsif ($retcode == 10) {
            push @warnings, "Bibtex found no citations for '$$Pbase',\n",
                            "    or bibtex found a missing aux file\n";
            if (! -e $$Pdest ) {
                print "$My_name: Bibtex did not produce '$$Pdest'.  But that\n",
                     "     was because of missing files, so I will continue.\n";
                $return = -2;
            }
            else {
                $return = 0;
            }
        }
    }
    else {
        # No special analysis for other rules
    }

    # General
    $updated = 1;
    if ( ($$Plast_result == 0) && ($return != 0) && ($return != -2) ) {
        $$Plast_result = 2;
        if ($$Plast_message eq '') {
            $$Plast_message = "Command for '$rule' gave return code $return";
            if ($rule =~ /^(pdf|lua|xe|)latex/) {
                if ( test_gen_file($log_name) ) {
                    $$Plast_message .=
                      "\n      Refer to '$log_name' and/or above output for details";
                }
                else {
                    $$Plast_message .=
                    "\n     Serious error that appeared not to generate a log file.";
                }
            }
            elsif ($rule =~ /^makeindex/) {
                $$Plast_message .= "\n      Refer to '${aux_dir1}${root_filename}.ilg' for details";
            }
        }
    }
    elsif ( $$Pdest && (! -e $$Pdest) && ($return != -2) ) {
        $$Plast_result = 1;
    }
    return $return;
}  # END rdb_run1

#-----------------

sub rdb_dummy_run0 {
    # Assumes contexts for: rule.
    # Update rule state as if the rule ran successfully,
    #    but don't run the rule.
    # Returns 0 (success code)

    # Source file data, by definition, correspond to the file state just before 
    # the latest run, and the run_time to the time just before the run:
    &rdb_update_files;
    $$Prun_time = time();
    $$Pchanged = 0;       # No special changes in files
    $$Plast_result = 0;
    $$Plast_result_info = 'CURR';
    $$Plast_message = '';

    $$Pout_of_date = $$Pout_of_date_user = 0;

    return 0;
}  # END rdb_dummy_run0

#-----------------

sub Run_subst {
    # Call: Run_subst( cmd, msg, options, source, dest, base )
    # Runs command with substitutions.
    # If an argument is omitted or undefined, it is replaced by a default:
    #    cmd is the command to execute
    #    msg is whether to print a message: 
    #           0 for not, 1 according to $silent setting, 2 always
    #    options, source, dest, base: correspond to placeholders.
    # Substitutions:
    #    %S=source, %D=dest, %B=base, %R=root=base for latex, %O=options, 
    #    %T=texfile,
    #    %V=$aux_dir, %W=$out_dir, %Y=$aux_dir1, %Z=$out_dir1
    # This is a globally usable subroutine, and works in a rule context,
    #    and outside.
    # Defaults:
    #     cmd: $$Pext_cmd if defined, else '';
    #     msg: 1
    #     options: ''
    #     source:  $$Psource if defined, else $texfile_name;
    #     dest:    $$Pdest if defined, else $view_file, else '';
    #     base:    $$Pbase if defined, else $root_filename;

    my ($ext_cmd, $msg, $options, $source, $dest, $base ) = @_;

    $ext_cmd ||= ( $Pext_cmd ? $$Pext_cmd : '' );
    $msg     =   ( defined $msg ? $msg : 1 );
    $options ||= '';
    $source  ||= ( $Psource ? $$Psource : $texfile_name );
    $dest    ||= ( $Pdest ? $$Pdest : ( $view_file || '' ) );
    $base    ||= ( $Pbase ? $$Pbase : $root_filename );

    if ( $ext_cmd eq '' ) {
         return 0;
    }

    #Set character to surround filenames:
    my %subst = ( 
       '%A' => $quote.$tex_basename.$quote,
       '%B' => $quote.$base.$quote,
       '%D' => $quote.$dest.$quote,
       '%O' => $options,
       '%S' => $quote.$source.$quote,
       '%R' => $quote.$root_filename.$quote,
       '%S' => $quote.$source.$quote,
       '%T' => $quote.$texfile_name.$quote,
       '%V' => $quote.$aux_dir.$quote,
       '%W' => $quote.$out_dir.$quote,
       '%Y' => $quote.$aux_dir1.$quote,
       '%Z' => $quote.$out_dir1.$quote,
       '%%' => '%'         # To allow literal %B, %R, etc, by %%B.
        );
    if ($pre_tex_code) {
        $subst{'%U'} = $quote.$pre_tex_code.$quote;
        $subst{'%P'} = "$quote$pre_tex_code\\input{$source}$quote";
    }
    else {
        $subst{'%U'} = '';
        $subst{'%P'} = $subst{'%S'};
    }
    if ( ($^O eq "MSWin32" ) && $MSWin_back_slash ) {
        foreach ( '%R', '%B', '%T', '%S', '%D', '%Y', '%Z' ) {
            $subst{$_} =~ s(/)(\\)g;
        }
    }

    my @tokens = split /(%.)/, $ext_cmd;
    foreach (@tokens) {
        if (exists($subst{$_})) { $_ = $subst{$_}; }
    }
    $ext_cmd = join '', @tokens;
    my ($pid, $return) = 
          ( ($msg == 0) || ( ($msg == 1) && $silent ) )
             ? &Run($ext_cmd)
             : &Run_msg($ext_cmd);
    return $return;
} #END Run_subst

sub analyze_latex_run {
    # Call: analyze_latex_run(old_ret_code)
    # Analyze results of run of *latex (or whatever was run instead) from
    # fls, log and aux files, and certain other information.
    # It also deals with (a) Change of main output file from one allowed
    # extension to another (e.g., dvi -> pdf). (b) Failure of *latex to
    # handle -aux-directory option, as with TeXLive.
    #
    # The argument is the return code as obtained from the run of *latex
    # and the returned value is either the original return code or an adjusted
    # value depending on the conditions found (e.g., missing file(s) that
    # latexmk know how to create).
    #
    # Assumes contexts for: recursion, make, & rule.
    # Assumes (a) the rule is a primary, 
    #         (b) a run has been made,

    my $return_latex = shift;
    my $return = $return_latex;

    # Need to worry about changed directory, changed output extension
    # Where else is $missing_dvi_pdf set?  Was it initialized?
    if (-e $$Pdest) { $missing_dvi_pdf = '';}
    
    # Find current set of source files:
    my ($missing_dirs, $PA_missing_subdirs, $bad_warnings) = &rdb_set_latex_deps;
    if ($bad_warning_is_error && $bad_warnings) {
        warn "$My_name: Serious warnings in .log configured to be errors\n";
        $return ||= $bad_warnings;1
    }

    # For each file of the kind made by epstopdf.sty during a run, 
    #   if the file has changed during a run, then the new version of
    #   the file will have been read during the run.  Unlike the usual
    #   case, we will NOT need to redo the primary run because of the
    #   change of this file during the run.  Therefore set the file as
    #   up-to-date:
    rdb_do_files( sub { if ($$Pcorrect_after_primary) {&rdb_update1;} } );

    $updated = 1;    # Flag that some dependent file has been remade

    if ( $diagnostics ) {
        print "$My_name: Rules after run: \n";
        rdb_show();
    }

    if ($return_latex && ($missing_dirs ne 'none') ) {
       print "Error in *LaTeX, but needed subdirectories in output directory\n",
             "   were missing and successfully created, so try again.\n"
          if (! $silent);
       $return = 0;
    }
    # Summarize issues that may have escaped notice:
    @primary_warning_summary = ();
    if ($bad_reference) {
        push @primary_warning_summary,
             "Latex failed to resolve $bad_reference reference(s)";
    }
    if ($mult_defined) {
        push @primary_warning_summary,
             "Latex found $mult_defined multiply defined reference(s)";
    }
    if ($bad_character) {
        push @primary_warning_summary,
            "=====Latex reported missing or unavailable character(s).\n".
            "=====See log file for details.";
    }
    if ($bad_citation) {
        push @primary_warning_summary,
             "Latex failed to resolve $bad_citation citation(s)";
    }
    if ( $diagnostics && ($#primary_warning_summary > -1) ) {
       show_array( "$My_name: Summary of warnings:", @primary_warning_summary );
    }

    return $return;

} #END analyze_latex_run

#************************************************************

sub rdb_remake_needed {
    # Usage: rdb_remake_needed( \%change_record, outside-make-loop, rules ...)
    # Determine whether one or more of the rules needs to be rerun, and
    # return corresponding value.
    #
    # Report diagnostics (reasons for remake) in the hash referenced by the
    # first argument (the hash maps kinds of reason to refs to arrays).
    #
    # If second argument is true, use rerun criterion suitable to e.g.,
    # initial tests in rdb_make, rerun test in
    # make_preview_continuous. Otherwise use rerun criterion suitable for
    # with rdb_make's looping through rules.  
    # In the first case, the file state recorded in each rule corresponds
    # to the files **after** the of the previous invocation of rdb_make. In
    # the second case it corresponds to the state immediately **before**
    # the latest run of the rule.

    my $PHchanges = shift;
    my $outside_make_loop = shift;
    
    my $remake_needed = 0;

    %$PHchanges = ();
    
    # ???!!!  Need fancier tests:  SEE NOTES.

    rdb_recurse( [@_],
                sub {
                    my %changes_rule = ();
                    if( rdb_rerun_needed(\%changes_rule, $outside_make_loop)) {
                        $remake_needed = 1;
                        foreach my $kind (keys %changes_rule ) {
                            push @{$$PHchanges{$kind}}, @{$changes_rule{$kind}};
                        }
                    }
                }
        );

    return $remake_needed;
} #END rdb_remake_needed

#************************************************************

sub rdb_user_changes {
    # Usage: rdb_user_changes( \%change_record, rules ...)
    # Return value: whether any user files changed.
    # Report changes in hash pointed to by first argument.
    # Side effect: out-of-date rules flagged in $$Pout_of_date.
    #
    # ???!!!
    # Ideally, need specialized versions of rdb_rerun_needed and
    # rdb_file_change1 (or special option to those), to restrict attention
    # to user_changed files.  But for now, fudge our way around that.

    my $PHchanges = shift;
    my $user_changes = 0;
    %$PHchanges = ( 'changed_user' => [],
                    'rules_to_apply' => []
                  );

    rdb_recurse(
        [@_],
        sub {
            my %changes_rule = ( 'changed_user' => [] );
            if ( rdb_rerun_needed(\%changes_rule, 0 )
                 && @{$changes_rule{changed_user}}
            ) {
                push @{$$PHchanges{changed_user}},
                     @{$changes_rule{changed_user}};
                push @{$$PHchanges{rules_to_apply}}, $rule;
                $user_changes = 1;
                $$Pout_of_date = $$Pout_of_date_user = $user_changes;
             }
        }
     );

    return $user_changes;
}

#************************************************************

sub rdb_rerun_needed {
    # Usage: rdb_rerun_needed( \%change_record, outside-make-loop )
    # Rule context assumed.
    # Determines whether a rerun of the rule is needed.
    # Return value is whether a rerun is needed.
    # 
    # Report diagnostics (reasons for remake) in the hash referenced by the
    # first argument (the hash maps kinds of reason to refs to arrays).
    #
    # If second argument is true, use rerun criterion suitable to e.g.,
    # initial tests in rdb_make, rerun test in
    # make_preview_continuous. Otherwise use rerun criterion suitable for
    # with rdb_make's looping through rules. 
    #
    # ???!!!!
    # Check all uses!!!!!!!!!!!!!

    our ($rule, %pass);

    local our $PHchanges = shift;
    local our $outside_make_loop = shift;

    # File level routine reports its results in %$PHchanges: maps kind of
    # change to ref to array of files with that kind of change.  
    %$PHchanges = ();
    foreach ('changed', 'changed_source_rules', 'changed_user',
             'disappeared_gen_other', 'disappeared_gen_this',
             'disappeared_user', 'no_dest', 'other', 'rules_to_apply' )
        { $$PHchanges{$_} = []; }

    my $rerun_needed = $$Pout_of_date;
    if ($rerun_needed) {
        push @{$$PHchanges{other}},
            "Rerun of '$rule' forced or previously required";
        goto rdb_rerun_needed_CLEAN_UP;
    }

    my $user_deleted_is_changed =
        ( ($user_deleted_file_treated_as_changed == 1)
          && (! $preview_continuous_mode)
        )
        || ($user_deleted_file_treated_as_changed == 2);
    
    $$Pcheck_time = time();

    local $dest_mtime = 0;
    $dest_mtime = get_mtime($$Pdest) if ($$Pdest);

    rdb_do_files( \&rdb_file_change1);
    if (! $outside_make_loop) {
        while ( my ($s_rule, $l_pass) = each %$PHsource_rules ) {
            # %$PHsource_rules is about rules on which the current rule
            #   depends, but for which this dependence is not determined by
            #   the source rules of the set of known source files.
            # Use pass-count criterion to determine out-of-dateness for these.
            #
            if ( defined $pass{$s_rule}
                 && ($pass{$s_rule} > $l_pass)
                )
            {
                push @{$$PHchanges{changed_source_rules}}, $s_rule;
                $rerun_needed = 1;
            }
        }
    }

        # ???!!!: Comments about disappeared files.
        #    Relevant situations I know of:
        #      a. \input (or c.) of a file, and file deleted. No other version.
        #      b. Like a., but file of the correct name exists in
        #         source-file-search path; the earlier source file version may for
        #         example have been an override for a standard file.
        #      c. There's a chain of input-if-file-exists cases, where the first
        #         file found in a list of files is used.  Then deleting the file
        #         found on the previous run merely results in the next run using
        #         the next file in the list (if there is one, else the situation
        #         is as at a..
        #      d. File was deleted, either by user or automatically by something,
        #         and the file can be regenerated.  (Note: If an aux or bbl file
        #         (etc) persistently causes errors, then after correcting, e.g., a
        #         relevant .tex file, then a clean rerun can be triggered by
        #         deleting the offending file.)
        # Need tests: Has the file a from rule? If so it can be made, and
        #               current rule shouldn't be rerun now.
        #               **But** it's different if the rule that makes in
        #             Is the file the main source file?  If so problems will
        #               normally happen when trying to run rule.
        #             Can the file be found by kpsewhich?  If so, is it the
        #               main source of the rule?
        # Need to mention missing files at end of run.

    foreach my $kind (keys %$PHchanges) {
        if (($kind eq 'disappeared_user') && !$user_deleted_is_changed)
        { #???!!! Delete entry, as it is no longer a reason for rerun.
            $$PHchanges{$kind} = [];
        }
        elsif ($kind eq 'disappeared_gen_other') {
            # It's the generating rule of the file that needs to be run,
            # not this rule, to remake the missing file. So we should not
            # set the current rule to be rerun. A rerun of the current rule
            # will be triggered once the file-generating rule has generates
            # the file, unless, of course, the generated file is identical
            # to the version that got deleted.
            # ????!!! should the disappeared_gen_other item in the hash be
            # emptied out?
        }
        elsif ( @{$$PHchanges{$kind}} ) {
            $rerun_needed = 1;
        }
    }

    # Non-source-file-change reasons for rerun:
    if ( ( ($$Prun_time == 0) || ( $$Plast_result =~ /^-1/ ) )
         && ( $$Pcmd_type eq 'primary' ) )
    {
        # Never run.  Only use this test with primary, so we can get
        # dependency information, which is essential to latexmk's
        # functioning.  Other rules: there appears to be danger
        # of, e.g., rerunning many cusdeps when their destinations have
        # already been made and we used time criterion for deciding whether
        # to run the rule. 
        push @{$$PHchanges{never_run}}, $rule;
        $rerun_needed = $rule;
    }
    if ( $$Pdest && (! -e $$Pdest) && ( $$Plast_result <= 0 ) ) {
        # No dest.  But not if last run gave error, for then we should not
        # rerun rule until there's a change in source file(s), which
        # presumably contain the cause of the error.
        # But there are other reasons for not rerunning:
            if ( $$Psource && (! -e $$Psource)
                 && ( $$Pcmd_type ne 'primary' )
               ) {
                # Main source file doesn't exist, and rule is NOT primary.
                # No action, since a run is pointless.  Primary is different:
                # file might be found elsewhere (by kpsearch from *latex),
                # while non-existence of main source file is a clear error.
            }
            elsif ( $$Pcmd_type eq 'delegated' ) {
                # Delegate to destination rule
            }
            else {
                $rerun_needed = 1;
                push @{$$PHchanges{no_dest}}, $rule;
            }
    }

  rdb_rerun_needed_CLEAN_UP:
    foreach my $file ( @{$$PHchanges{changed}} ) {
        if ( ! $from_rules{$file} ) {
            push @{$$PHchanges{changed_user}}, $file; 
        }
    }
    $$Pno_history = 0;    # See comments in definition of %rule_db.
    if ($rerun_needed) {
        $$Pout_of_date = 1;
        push @{$$PHchanges{rules_to_apply}}, $rule;
        if (@{$$PHchanges{changed_user}}) {$$Pout_of_date_user = 1;}
    }
    return $rerun_needed;
} #END rdb_rerun_needed

#************************************************************

sub rdb_file_change1 {
    # Call: &rdb_file_change1
    # Assumes rule and file context.  Assumes $dest_mtime set.
    # Flag whether $file in $rule has changed or disappeared.
    our ($rule, $file, $PHchanges);

    my $check_time_argument =
        ($outside_make_loop ? 0 : max($$Pcheck_time, $$Prun_time) );

    
    # For files that won't be read until after they are written, ignore any changes:
    if (exists $$PHrewritten_before_read{$file}) {
        return;
    }
    my ($new_time, $new_size, $new_md5) = fdb_get($file, $check_time_argument );
    my $ext_no_period = ext_no_period( $file );

    my $generated = 0;
    if (exists $from_rules{$file}) {
        if ($from_rules{$file} eq $rule) { $generated = 1; }
        else { $generated = 2; }
    }

    if ( ($new_size < 0) && ($$Psize < 0) ) {
        return;
    }
    
    if ( ($new_size < 0) && ($$Psize >= 0) ) {
        if ($generated == 2) {
            # Non-existent file generated by another rule.  It's up to that
            # rule to remake it.
            push @{$$PHchanges{disappeared_gen_other}}, $file;
        }
        elsif ($generated == 1) {
            # Non-existent file generated by this rule.
            push @{$$PHchanges{disappeared_gen_this}}, $file;
        }
        # ???!!! Keep this, or only for primary, or not?
#        elsif ( my @kpse = kpsewhich( $file ) ) {
#            print "After '$file' disappeared for '$rule', kpsewhich found it at\n:",
#                  "  '$kpse[0]'.\n";
#            push @{$$PHchanges{changed}}, $file;
#        }
        else {
            push @{$$PHchanges{disappeared_user}}, $file;
        }
    }
    # For other kinds of file change, primarily use md5 signature to
    # determine whether file contents have changed.
    # Backup by file size change, but only in the case where there is
    # no pattern of lines to ignore in testing for a change
    elsif ( ($new_md5 ne $$Pmd5) 
            || (
                  (! exists $hash_calc_ignore_pattern{$ext_no_period})
                  && ($new_size != $$Psize)   
            )
       ) {
        push @{$$PHchanges{changed}}, $file;
    }
    elsif ( $new_time != $$Ptime ) {
        $$Ptime = $new_time;
    }
    # If there's no history, supplement by file-time criterion, i.e., is
    # this source file time later than destination file file
    if ( $$Pno_history && ( $new_time > $dest_mtime ) ) {
        push @{$$PHchanges{changed}}, $file;
    }

} #END rdb_file_change1

#************************************************************

sub rdb_diagnose_changes2 {
    # Call: rdb_diagnose_changes2( \%changes, heading, show_out_of_date_rules )

    my ($PHchanges, $heading, $show_out_of_date_rules) = @_;

    my %labels = (
        'changed' => 'Changed files or newly in use/created',
        );

    print "$heading Reasons for rerun\n";
    foreach my $kind (sort keys %$PHchanges) {
        if ( (! $show_out_of_date_rules) && ($kind eq 'rules_to_apply' ) )
            { next; }
        my $label = $labels{$kind}  || "Category '$kind'";
        if ( @{$$PHchanges{$kind}} ) {
            show_array( "$label:",
                        uniqs( @{$$PHchanges{$kind}} ) );
        }
    }
    print "\n";
}  #END rdb_diagnose_changes2

#************************************************************
#************************************************************
#************************************************************
#************************************************************

#************************************************************
#************************************************************
#************************************************************
#************************************************************

# Routines for convenient looping and recursion through rule database
# ================= NEW VERSION ================

# There are several places where we need to loop through or recurse
# through rules and files.  This tends to involve repeated, tedious
# and error-prone coding of much book-keeping detail.  In particular,
# working on files and rules needs access to the variables involved,
# which either involves direct access to the elements of the database,
# and consequent fragility against changes and upgrades in the
# database structure, or involves lots of routines for reading and
# writing data in the database, then with lots of repetitious
# house-keeping code.
#
# The routines below provide a solution.  Looping and recursion
# through the database are provided by a set of basic routines where
# each necessary kind of looping and iteration is coded once.  The
# actual actions are provided as references to action subroutines.
# (These can be either actual references, as in \&routine, or
# anonymous subroutines, as in sub{...}, or aas a zero value 0 or an
# omitted argument, to indicate that no action is to be performed.)
#
# When the action subroutine(s) are actually called, a context for the
# rule and/or file (as appropriate) is given by setting named
# variables to REFERENCES to the relevant data values.  These can be
# used to retrieve and set the data values.  As a convention,
# references to scalars are given by variables named start with "$P",
# as in "$Pdest", while references to arrays start with "$PA", as in 
# "$PAint_cmd", and references to hashes with "$PH", as in "$PHsource".
# After the action subroutine has finished, checks for data
# consistency may be made. 
#
# The only routines that actually use the database structure and need
# to be changed if that is changed are:  (a) the routines rdb_one_rule
# and rdb_one_file that implement the calling of the action subroutines,
# (b) routines for creation of single rules and file items, and (c) to
# a lesser extent, the routine for destroying a file item.  
#
# Note that no routine is provided for destroying a rule.  During a
# run, a rule, with its source files, may become inaccessible or
# unused.  This happens dynamically, depending on the dependencies
# caused by changes in the source file or by error conditions that
# cause the computation of dependencies, particular of latex files, to
# become wrong.  In that situation the files certainly come and go in
# the database, but subsidiary rules, with their content information
# on their source files, need to be retained so that their use can be
# reinstated later depending on dynamic changes in other files.
#
# However, there is a potential memory leak unless some pruning is
# done in what is written to the fdb file.  (Probably only accessible
# rules and those for which source files exist.  Other cases have no
# relevant information that needs to be preserved between runs.)

#
#


#************************************************************

# First the top level routines for recursion and iteration

#************************************************************

sub rdb_recurse {
    # Call: rdb_recurse( rule | [ rules],
    #                    \&rule_act1, \&file_act1, \&file_act2, 
    #                    \&rule_act2 )
    # The actions are pointers to subroutines, and may be null (0, or
    # undefined) to indicate no action to be applied.
    # Recursively acts on the given rules and all ancestors:
    #   foreach rule found:
    #       apply rule_act1
    #       loop through its files:
    #          apply file_act1
    #          act on its ancestor rule, if any
    #          apply file_act2
    #       apply rule_act2
    # Guards against loops.  
    # Access to the rule and file data by local variables, only
    #   for getting and setting.

    # This routine sets a context for anything recursive, with @heads,
    # %visited  and $depth being set as local variables.

    local @heads = ();
    my $rules = shift;

    # Distinguish between single rule (a string) and a reference to an
    # array of rules:
    if ( ref $rules eq 'ARRAY' ) { @heads = @$rules; }
    else { @heads = ( $rules ); }

    # Keep a list of visited rules, used to block loops in recursion:
    local %visited = (); 
    local $depth = 0;

    foreach $rule ( @heads ) {
        if ( rdb_is_active($rule) ) { rdb_recurse_rule( $rule, @_ ); }
    }

} #END rdb_recurse

#************************************************************

sub rdb_for_actives {
    # Call: rdb_for_actives( \&rule_act1, \&file_act, \&rule_act2 )
    # Loops through all rules and their source files, using the 
    #   specified set of actions, which are pointers to subroutines.
    # Sorts rules alphabetically.
    # See rdb_for_some for details.
#    rdb_for_some( [ sort keys %rule_db ], @_);
    rdb_for_some( [ sort &rdb_actives ], @_);
} #END rdb_for_actives

#************************************************************

sub rdb_for_some {
    # Call: rdb_for_some( rule | [ rules],
    #                    \&rule_act1, \&file_act, \&rule_act2)
    # Actions can be zero, and rules at tail of argument list can be
    # omitted.  E.g. rdb_for_some( rule, 0, \&file_act ).  
    # Anonymous subroutines can be used, e.g., rdb_for_some( rule, sub{...} ).  
    #
    # Loops through rules and their source files, using the 
    # specified set of rules:
    #   foreach rule:
    #       apply rule_act1
    #       loop through its files:
    #          apply file_act
    #       apply rule_act2
    #
    # Rule data and file data are made available in local variables 
    # for access by the subroutines.

    local @heads = ();
    my $rules = shift;
    # Distinguish between single rule (a string) and a reference to an
    # array of rules:
    if ( ref $rules eq 'ARRAY' ) { @heads = @$rules; }
    else { @heads = ( $rules ); }

    foreach $rule ( @heads ) {
        # $rule is implicitly local
        &rdb_one_rule( $rule, @_ );
    }
}  #END rdb_for_some

#************************************************************

sub rdb_for_one_file {
    # Use : rdb_for_one_file( rule, file, ref to action subroutine )
    my $rule = shift;
    # Avoid name collisions with general recursion and iteraction routines:
    local $file1 = shift;
    local $action1 = shift;
    rdb_for_some( $rule, sub{rdb_one_file($file1,$action1)} );
} #END rdb_for_one_file


#************************************************************

#   Routines for inner part of recursion and iterations

#************************************************************

sub rdb_recurse_rule {
    # Call: rdb_recurse_rule($rule, \&rule_act1, \&file_act1, \&file_act2, 
    #                    \&rule_act2 )
    # to do the work for one rule, recurisvely called source_rules for
    # the sources of the rules.
    # Assumes recursion context, i.e. that %visited, @heads, $depth.
    # We are overriding actions:
    my ($rule, $rule_act1, $new_file_act1, $new_file_act2, $rule_act2)
        = @_;
    if (! rdb_is_active($rule)) { return; }
    # and must propagate the file actions:
    local $file_act1 = $new_file_act1;
    local $file_act2 = $new_file_act2;
    # Prevent loops:
    if ( (! $rule) || exists $visited{$rule} ) { return; }
    $visited{$rule} = 1;
    # Recursion depth
    $depth++;
    # We may need to repeat actions on dependent rules, without being
    # blocked by the test on visited files.  So save %visited:
    # NOT CURRENTLY USED!!    local %visited_at_rule_start = %visited;
    # At end, the last value set for %visited wins.
    rdb_one_rule( $rule, $rule_act1, \&rdb_recurse_file, $rule_act2 );
    $depth--;
 } #END rdb_recurse_rule 

#************************************************************

sub rdb_recurse_file {
    # Call: rdb_recurse_file to do the work for one file.
    # This has no arguments, since it is used as an action subroutine,
    # passed as a reference in calls in higher-level subroutine.
    # Assumes contexts set for: Recursion, rule, and file
    &$file_act1 if $file_act1;
    my $from_rule = $from_rules{$file} || '';
    rdb_recurse_rule( $from_rule, $rule_act1, $file_act1, $file_act2,
                      $rule_act2 )
        if $from_rule;
    &$file_act2 if $file_act2;
} #END rdb_recurse_file

#************************************************************

sub rdb_do_files {
    # Assumes rule context, including $PHsource.
    # Applies an action to all the source files of the rule.
    local $file_act = shift;
    my @file_list = sort keys %$PHsource;
    foreach my $file ( @file_list ){
        rdb_one_file( $file, $file_act );
    }
} #END rdb_do_files

#************************************************************

# Routines for action on one rule and one file.  These are the main
# places (in addition to creation and destruction routines for rules
# and files) where the database structure is accessed.

#************************************************************

sub rdb_one_rule {
    # Call: rdb_one_rule( $rule, $rule_act1, $file_act, $rule_act2 )
    # Sets context for rule and carries out the actions.
#===== Accesses rule part of database structure =======

    local ( $rule, $rule_act1, $file_act, $rule_act2 ) = @_;
    if ( (! $rule) || ! rdb_rule_exists($rule) ) { return; }

    local ( $PArule_data, $PHsource, $PHdest, $PHrewritten_before_read, $PHsource_rules ) = @{$rule_db{$rule}};
    local ($Pcmd_type, $Pext_cmd, $PAint_cmd, $Pno_history, 
           $Psource, $Pdest, $Pbase,
           $Pout_of_date, $Pout_of_date_user, $Prun_time, $Pcheck_time,
           $Pchanged,
           $Plast_result, $Plast_result_info, $Plast_message, $PA_extra_gen )
        = Parray( $PArule_data );

    &$rule_act1 if $rule_act1;
    &rdb_do_files( $file_act ) if $file_act;
    &$rule_act2 if $rule_act2;
} #END rdb_one_rule

#************************************************************

sub rdb_activate {
    # Usage rdb_activate( rule_names )
    # Turns on active flag for the rules
    foreach ( @_ ) {
        if ( rdb_rule_exists($_) ) { $actives{$_} = 1; }
    }
}

#--------------------------------------------------

sub rdb_deactivate {
    # Usage rdb_deactivate( rule_names )
    # Turns off active flag for the rules
    foreach ( @_ ) { delete $actives{$_}; }
}

#--------------------------------------------------

sub rdb_activate_request {
    # Usage rdb_activate_request( rule_names )
    # Turns on active flag for the rules.
    # Adds rules to target_rules list
    foreach ( @_ ) {
        if ( rdb_rule_exists($_) ) { $actives{$_} = 1; $target_rules{$_} = 1; }
    }
}

#--------------------------------------------------

sub rdb_deactivate_derequest {
    # Usage rdb_deactivate_derequest( rule_names )
    # Turns off active flag for the rules
    # Removes rules from target_rules list
    foreach ( @_ ) { delete $actives{$_}; delete $target_rules{$_}; }
}

#--------------------------------------------------
sub rdb_is_active {
    # Usage rdb_is_active( rule_name )    
    if ( (exists $actives{$_[0]}) && rdb_rule_exists($_[0]) ) { return 1; }
    else { return 0; }
}

#--------------------------------------------------

sub rdb_actives {
    # Returns array of active rules
    return keys %actives;
}

#************************************************************

sub rdb_one_file {
    # Call: rdb_one_file($file, $file_act)
    # Sets context for file and carries out the action.
    # Assumes $rule context set.
#===== Accesses file part of database structure =======
    local ($file, $file_act) = @_;
    if ( (!$file) ||(!exists ${$PHsource}{$file}) ) { return; }
    local $PAfile_data = ${$PHsource}{$file};
    our $DUMMY;  # Fudge until fix rule_db
    local ($Ptime, $Psize, $Pmd5, $DUMMY, $Pcorrect_after_primary ) 
          = Parray( $PAfile_data );
    &$file_act() if $file_act;
} #END rdb_one_file

#************************************************************

# Routines for creation of rules and file items, and for removing file
# items. 

#************************************************************

sub rdb_remove_rule {
    # rdb_remove_rule( rule, ...  )
    foreach my $key (@_) {
       delete $rule_db{$key};
       delete $actives{$key};
    }
}

#************************************************************

sub rdb_create_rule {
    # rdb_create_rule( rule, command_type, ext_cmd, int_cmd, DUMMY,
    #                  source, dest, base, 
    #                  needs_making, run_time, check_time, set_file_not_exists,
    #                  ref_to_array_of_specs_of_extra_generated_files,
    #                  ref_to_array_of_specs_of_extra_source_files )
    # int_cmd is either a string naming a perl subroutine or it is a
    # reference to an array containing the subroutine name and its
    # arguments. 
    # Makes rule.  Update rule if it already exists.
    # Omitted arguments: replaced by 0, '', or [] as needed.
    # Rule is made active
    # 5th argument DUMMY is argument that used to be used (test_kind), but
    # is not used any more.  But I keep it there to avoid having to change
    # calls, which are not only in the latexmk code itself, but may be in
    # latexmkrc files created by others.
    
# ==== Set rule data from arguments ====
    my ( $rule, $cmd_type, $ext_cmd, $PAint_cmd, $DUMMY, 
         $source, $dest, $base, 
         $needs_making, $run_time, $check_time, $set_file_not_exists,
         $PAextra_gen, $PAextra_source ) = @_;
    # Set defaults for undefined arguments
    foreach ( $needs_making, $run_time, $check_time, $DUMMY ) {
        if (! defined $_) { $_ = 0; }
    }
    foreach ( $cmd_type, $ext_cmd, $PAint_cmd, $source, $dest, $base, 
              $set_file_not_exists ) {
        if (! defined $_) { $_ = ''; }
    }
    foreach ( $PAextra_gen, $PAextra_source ) {
        if (! defined $_) { $_ = []; }
    }
    my $last_result = -1;
    my $last_result_info = '';
    my $no_history = ($run_time <= 0);
    my $active = 1;
    my $changed = 0;

    if ( ($source =~ /\"/) || ($dest =~ /\"/) || ($base =~ /\"/) ) {
        die "$My_name: Error. In rdb_create_rule to create rule\n",
            "    '$rule',\n",
            "  there is a double quote in one of source, destination or base parameters:\n",
            "    '$source'\n",
            "    '$dest'\n",
            "    '$base'\n",
            "  I cannot handle this.  Cause is probably a latexmk bug.  Please report it.\n";
    }
    if ( ref( $PAint_cmd ) eq '' ) {
        #  It is a single command.  Convert to array reference:
        $PAint_cmd = [ $PAint_cmd ];
    }
    else {
        # COPY the referenced array:
        $PAint_cmd = [ @$PAint_cmd ];
    }
    $rule_db{$rule} = 
        [  [$cmd_type, $ext_cmd, $PAint_cmd, $no_history, 
            $source, $dest, $base,
            $needs_making, 0, $run_time, $check_time, $changed,
            $last_result, $last_result_info, '', $PAextra_gen ],
           {},
           {},
           {},
           {}
        ];
    foreach my $file ($source, @$PAextra_source ) {
        if ($file) { rdb_ensure_file( $rule, $file, undef, $set_file_not_exists ); }
    }
    rdb_one_rule( $rule, \&rdb_initialize_generated );
    if ($active) { rdb_activate($rule); }
    else { rdb_deactivate($rule); }
} #END rdb_create_rule

#************************************************************

sub rdb_initialize_generated {
# Assume rule context.
# Initialize hashes of generated files, and of files rewritten before read
    %$PHdest = ();
    if ($$Pdest) { rdb_add_generated($$Pdest); }
    rdb_add_generated(@$PA_extra_gen);

    %$PHrewritten_before_read = ();
} #END rdb_initialize_generated

#************************************************************

sub rdb_add_generated {
# Assume rule context.
# Add arguments to hash of generated files, and to global cache
    foreach (@_) {
        $$PHdest{$_} = 1;
        $from_rules{$_} = $rule;
    }
} #END rdb_add_generated

#************************************************************

sub rdb_add_rewritten_before_read {
# Assume rule context.
# Add arguments to hash of files rewritten before being read
    foreach (@_) { $$PHrewritten_before_read{$_} = 1; }
} #END rdb_add_rewritten_before_read

#************************************************************

sub rdb_remove_generated {
# Assume rule context.
# Remove arguments from hash of generated files
    foreach (@_) { delete $$PHdest{$_}; }
} #END rdb_remove_generated

#************************************************************

sub rdb_remove_rewritten_before_read {
# Assume rule context.
# Remove arguments from hash of files rewritten before being read
    foreach (@_) { delete $$PHrewritten_before_read{$_}; }
} #END rdb_add_rewritten_before_read

#************************************************************

sub rdb_ensure_file {
    # rdb_ensure_file( rule, file[, fromrule[, set_not_exists]] )
    # Ensures the source file item exists in the given rule.
    # Then if the fromrule is specified, set it for the file item.
    # If the item is created, then:
    #    (a) by default initialize it to current file state.
    #    (b) but if the fourth argument, set_not_exists, is true, 
    #        initialize the item as if the file does not exist.
    #        This case is typically used
    #         (1) when the log file for a run of latex/pdflatex claims
    #             that the file was non-existent at the beginning of a
    #             run.
    #         (2) When initializing rules, when there is no previous
    #             known run under the control of latexmk.
#============ NOTE: rule and file data set here ===============================
    my $rule = shift;
    local ( $new_file, $new_from_rule, $set_not_exists ) = @_;
    if ( ! rdb_rule_exists( $rule ) ) {
        die_trace( "$My_name: BUG in call to rdb_ensure_file: non-existent rule '$rule'" );
    }
    if ( ! defined $new_file ) {
        die_trace( "$My_name: BUG in call to rdb_ensure_file: undefined file for '$rule'" );
    }
    if ( $new_file =~ /\"/ ) {
        warn "$My_name: in rdb_ensure_file for rule '$rule', there is a double quote in\n",
             "  the filename: '$new_file'.\n",
             "  I cannot handle this, will ignore this file.\n";
        return;
    }
    if ( ! defined $set_not_exists ) { $set_not_exists = 0; }
    rdb_one_rule( $rule, 
                  sub{
                      if (! exists ${$PHsource}{$new_file} ) {
                          if ( $set_not_exists ) {
                              ${$PHsource}{$new_file} = [@nofile, '', 0];
                          }
                          else {
                              ${$PHsource}{$new_file} 
                              = [fdb_get($new_file, $$Prun_time), '', 0];
                          }
                      }
                  }
    );
    if (defined $new_from_rule ) {
        $from_rules{$new_file} = $new_from_rule;
    }
} #END rdb_ensure_file 

#************************************************************

sub rdb_remove_files {
    # rdb_remove_file( rule, file, ... )
    # Removes file(s) for the rule.  
    my $rule = shift;
    if (!$rule) { return; }
    local @files = @_;
    rdb_one_rule( $rule, 
                  sub{ foreach (@files) { delete ${$PHsource}{$_}; }  }
    );
} #END rdb_remove_files

#************************************************************

sub rdb_list_source {
    # rdb_list_source( rule )
    # Return array of source files for rule.
    my $rule = shift;
    my @files = ();
    rdb_one_rule( $rule, 
                  sub{ @files = keys %$PHsource; }
    );
    return @files;
} #END rdb_list_source

#************************************************************

sub rdb_set_source {
    # rdb_set_source( rule, file, ... )
    my $rule = shift;
    if (!$rule) { return; }
    my %files = ();
    foreach (@_) {
#       if ( /\"/ ) {next; }
        rdb_ensure_file( $rule, $_ );
        $files{$_} = 1;
    }
    foreach ( rdb_list_source($rule) ) {
        if ( ! exists $files{$_} ) { rdb_remove_files( $rule, $_ ); }
    }    
    return;
} #END rdb_list_source

#************************************************************

sub rdb_rule_exists { 
    # Call rdb_rule_exists($rule): Returns whether rule exists.
    my $rule = shift;
    if (! $rule ) { return 0; }
    return exists $rule_db{$rule}; 
} #END rdb_rule_exists

#************************************************************

sub rdb_file_exists { 
    # Call rdb_file_exists($rule, $file): 
    # Returns whether source file item in rule exists.
    local ( $rule, $file ) = @_;
    local $exists = 0;
    rdb_one_rule( $rule, 
                  sub{ $exists =  exists( ${$PHsource}{$file} ) ? 1:0; } 
                );
    return $exists; 
} #END rdb_file_exists

#************************************************************

sub rdb_update_gen_files {
    # Assumes rule context.  Update source files of rule to current state,
    # but only for source files that are generated by this or another rule.
    rdb_do_files( 
        sub{  if ( exists $from_rules{$file} ) { &rdb_update1; }  }
    );
} #END rdb_update_gen_files

#************************************************************

sub rdb_update_files {
    # Call: rdb_update_files
    # Assumes rule context.  Update all source files of rule to current state.
    rdb_do_files( \&rdb_update1 );
}

#************************************************************

sub rdb_update1 {
    # Call: rdb_update1.  
    # Assumes file context.  Updates file data to correspond to
    # current file state on disk
    ($$Ptime, $$Psize, $$Pmd5) = fdb_get($file);
}

#************************************************************

sub rdb_set_file1 {
    # Call: fdb_file1(rule, file, new_time, new_size, new_md5)
    # Sets file time, size and md5.
    my $rule = shift;
    my $file = shift;
    local @new_file_data = @_;
    rdb_for_one_file( $rule, $file, sub{ ($$Ptime,$$Psize,$$Pmd5)=@new_file_data; } );
}

#************************************************************

sub rdb_dummy_file {
    # Returns file data for non-existent file
# ==== Uses rule_db structure ====
    return (0, -1, 0, '');
}

#************************************************************
#************************************************************

# Predefined subroutines for custom dependency

sub cus_dep_delete_dest {
    # This subroutine is used for situations like epstopdf.sty, when
    #   the destination (target) of the custom dependency invoking
    #   this subroutine will be made by the primary run provided the
    #   file (destination of the custom dependency, source of the
    #   primary run) doesn't exist.
    # It is assumed that the resulting file will be read by the
    #   primary run.
    # N.B. 
    # The subroutine is not used by latexmk itself.  It is here to support
    # a need in TeXShop's pdflatexmk engine as the subroutine for a cusdep
    # to work with the epspdf package.

    print "I am delegating making of '$$Pdest' to *latex (e.g., by epspdf).\n",
          "  So I'll delete '$$Pdest' to flag it needs to be remade,\n",
          "  and flagging the rules using it to be rerun\n"
        if (!$silent);
    # Remove the destination file, to indicate it needs to be remade:
    unlink_or_move( $$Pdest );
    # Arrange that the non-existent destination file is not treated as
    #   an error.  The variable changed here is a bit misnamed.
    $$Pchanged = 1;
    # Ensure a primary run is done
    &cus_dep_require_primary_run;
    # Return success:
    return 0;
}

#************************************************************

sub cus_dep_require_primary_run {
    # This subroutine is used for situations like epstopdf.sty, when
    #   the destination (target) of the custom dependency invoking
    #   this subroutine will be made by the primary run provided the
    #   file (destination of the custom dependency, source of the
    #   primary run) doesn't exist.
    # It is assumed that the resulting file will be read by the
    #   primary run.

    local $cus_dep_target = $$Pdest;
    # Loop over all active rules and source files:
    rdb_for_actives( 0, 
                 sub { if ($file eq $cus_dep_target) {
                            $$Pout_of_date = 1;
                            $$Pcorrect_after_primary = 1;
                       }
                     }
               );
    # Return success:
    return 0;
}


#************************************************************
#************************************************************
#************************************************************
#
#      UTILITIES:
#

#************************************************************
# Miscellaneous

sub show_array {
# For use in diagnostics and debugging. 
#  On stdout, print line with $_[0] = label.  
#  Then print rest of @_, one item per line preceeded by some space
    print "$_[0]\n";
    shift;
    if ($#_ >= 0) {
        foreach (@_){
           if (defined $_ ) { print "  $_\n"; }
           else { print "  UNDEF\n"; }
        }
    }
    else { print "  NONE\n"; }
}

#************************************************************

sub show_hash {
    my ($msg, $PH) = @_;
    print "$msg\n";
    if (! %$PH ) {
        print "     NONE\n";
    }
    else {
        while ( my ($key, $value) = each %$PH ) {
            if (defined $value) { print "  '$key' => '$value'\n"; }
            else { print "  '$key' => UNDEF\n"; }
        }
    }
}

#************************************************************

sub warn_array {
#  For use in error messages etc.
#  On stderr, print line with $_[0] = label.  
#  Then print rest of @_, one item per line preceeded by some space
    warn "$_[0]\n";
    shift;
    if ($#_ >= 0) {
        foreach (@_){
           if (defined $_ ) { warn "  $_\n"; }
           else { warn "  undef\n"; }
        }
    }
    else { warn "  NONE\n"; }
}


#************************************************************

sub array_to_hash {
    # Call: array_to_hash( items )
    # Returns: hash mapping items to 1
    my %hash = ();
    foreach (@_) {$hash{$_} = 1; }
    return %hash;
}
    
#************************************************************

sub Parray {
    # Call: Parray( \@A )
    # Returns array of references to the elements of @A
    # But if an element of @A is already a reference, the
    # reference will be returned in the output array, not a
    # reference to the reference.
    my $PA = shift;
    my @P = (undef) x (1+$#$PA);
    foreach my $i (0..$#$PA) {
        $P[$i] = (ref $$PA[$i]) ? ($$PA[$i]) : (\$$PA[$i]);
      }
    return @P;
}

#************************************************************

sub analyze_string {
    # Show information about string: utf8 flag or not, length(s!), byte content
    my ($m,$s) = @_;

    print "=== $m ";
    my $length = length($s);
    if (utf8::is_utf8($s)) {
        my $encoded = encode( $CS_system, $s, Encode::FB_WARN | Encode::LEAVE_SRC );
        my $len_chars = 0;
        my $len_bytes = 0;
        { no bytes; $len_chars = length($s); }
        { use bytes; $len_bytes = length($s); }
        print "'$encoded':\n",
            "utf8, len = $length; chars = $len_chars; bytes = $len_bytes\n";
    }
    else {
        print "'$s':\n",
              "NOT utf8, len = $length\n";
    }

    print join ' ', to_hex($s), "\n";
}

#----------------------------

sub to_hex {
    return map { sprintf('%4X', $_) }  unpack( 'U*', shift );
}

#==================

sub glob_list1 {
    # Glob a collection of filenames.  
    # But no sorting or elimination of duplicates
    # Usage: e.g., @globbed = glob_list1(string, ...);
    # Since perl's glob appears to use space as separator, I'll do a special check
    # for existence of non-globbed file (assumed to be tex like)

    my @globbed = ();
    foreach my $file_spec (@_) {
        # Problem, when the PATTERN contains spaces, the space(s) are
        # treated as pattern separaters.
        # Solution: I now the glob from use File::Glob.
        # The following hack avoids issues with glob in the case that a file exists
        # with the specified name (possibly with extension .tex):
        if ( -e $file_spec || -e "$file_spec.tex" ) { 
           # Non-globbed file exists, return the file_spec.
           # Return $file_spec only because this is not a file-finding subroutine, but
           #   only a globber
           push @globbed, $file_spec; 
        }
        else { 
            push @globbed, my_glob( "$file_spec" );
        }
    }
    return @globbed;
} #END glob_list1

#************************************************************
# Miscellaneous

sub prefix {
   #Usage: prefix( string, prefix );
   #Return string with prefix inserted at the front of each line
   my @line = split( /\n/, $_[0] );
   my $prefix = $_[1];
   for (my $i = 0; $i <= $#line; $i++ ) {
       $line[$i] = $prefix.$line[$i]."\n";
   }
   return join( "", @line );
} #END prefix


#===============================

sub parse_quotes {
    # Split string into words.
    # Words are delimited by space, except that strings
    # quoted all stay inside a word.  E.g., 
    #   'asdf B" df "d "jkl"'
    # is split to ( 'asdf', 'B df d', 'jkl').
    # An array is returned.
    my @results = ();
    my $item = '';
    local $_ = shift;
    pos($_) = 0;
  ITEM:
    while() {
        /\G\s*/gc;
        if ( /\G$/ ) {
            last ITEM;
        }
        # Now pos (and \G) is at start of item:
      PART:
        while () {
            if (/\G([^\s\"]*)/gc) {
                $item .= $1;
            }
            if ( /\G\"([^\"]*)\"/gc ) {
                # Match balanced quotes
                $item .= $1;
                next PART;
            }
            elsif ( /\G\"(.*)$/gc ) {
                # Match unbalanced quote
                $item .= $1;
                warn "====Non-matching quotes in\n    '$_'\n";
            }
            push @results, $item;
            $item = '';
            last PART;
        }
    }
    return @results;
} #END parse_quotes

#************************************************************
#************************************************************
#      File handling utilities:


#************************************************************

sub get_latest_mtime
# - arguments: each is a filename.
# - returns most recent modify time.
{
  my $return_mtime = 0;
  foreach my $include (@_)
  {
    my $include_mtime = &get_mtime($include);
    # The file $include may not exist.  If so ignore it, otherwise
    # we'll get an undefined variable warning.
    if ( ($include_mtime) && ($include_mtime >  $return_mtime) )
    {
      $return_mtime = $include_mtime;
    }
  }
  return $return_mtime;
}

#************************************************************

sub get_mtime {
    # Return mtime of file if it exists, otherwise 0.
    # 
    # stat returns an empty array for a non-existent file, and then
    # accessing an element of the array gives undef.  Use || 0 to replace it
    # by the desired 0.
    return ( stat($_[0]) )[9] || 0;
}

#************************************************************

sub get_time_size {
    # Return time and size of file named in argument
    # If file does not exist, return (0,-1);
    # Argument _ to stat: use values from previous call, to save disk access.
    my @result = stat($_[0]);
    if (@result) { return ($result[9], $result[7]); }
    else { return (0,-1); }
}

#************************************************************

sub processing_time {
    # Return time used.
    # Either total processing time of process and child processes as reported
    # in pieces by times(), or HiRes time since Epoch depending on setting of
    # $times_are_clock.
    # That variable is to be set on OSs (MSWin32) where times() does not
    # include time for subprocesses.
    if ($times_are_clock) {
        return Time::HiRes::time();
    }
    my ($user, $system, $cuser, $csystem) = times();
    return $user + $system + $cuser + $csystem;
}

#************************************************************

sub get_checksum_md5 {
    my $source = shift;
    my $input;
    my $md5 = Digest::MD5->new;
    my $ignore_pattern = undef;

    if ( -d $source ) {
        # We won't use checksum for directory
        return 0;
    }
    else {
        open( $input, '<:bytes', $source )
        or return 0;
        my ($base, $path, $ext) = fileparseA( $source );
        $ext =~ s/^\.//;
        if ( exists $hash_calc_ignore_pattern{$ext} ) {
            $ignore_pattern = $hash_calc_ignore_pattern{$ext};
        }
    }
    if ( defined $ignore_pattern ) {
        while (<$input>) {
            if ( ! /$ignore_pattern/ ){
                $md5->add($_);
            }
        }
    }
    else {
        $md5->addfile($input);
    }
    close $input;
    return $md5->hexdigest();
}

#************************************************************
#************************************************************

sub create_empty_file {
    my $name = shift;
    open( my $h, ">", $name )
        or return 1;
    close ($h);
    return 0;
}

#************************************************************
#************************************************************

sub find_files {
    # Usage: find_files( \%files, format, default_ext, \@files, \@not_found )
    # ???!!! This may be too elaborate.  The hash is there to have all the
    # necessary information, but I don't actually use it.
    # The files hash, referred to by the 1st argument, has as its keys
    #   specified file names, as specified for example in \bibliography.
    #   The values are to be the names of the corresponding actual files,
    #   as found by kpsewhich, or '' if kpsewhich doesn't find a file.
    # The format is used in a -format=... option to kpsewhich, e.g., 'bib'
    #   for bib files, 'bst' for bst files.
    # The 3rd argument contains the default extension to use for not-found files. 
    # The array @files, referred to by the 4th argument, contains the
    #   sorted names of the found files, and then the specifications of the
    #   not-found files.
    #   But
    # The array @not_found, referred to by the 5th argument, contains the
    #   sorted names of the specified names for the not-found files.
    # The value of each item in the hash is set to the found filename
    #   corresponding to the key, if a file is found; otherwise it is set to
    #   the empty string.
    # Return number of files not found.
    #
    # ???!!! Ideally use only 1 call to kpsewhich. But KISS for now.  The
    # main use of this subroutine is for bib, bst files (and maybe index
    # files), which are few in number.  Only likely conceivable case for
    # having many files is with a big document, for which *latex running
    # time is large, so almost certainly that dwarfs run time for several
    # runs of kpsewhich. 

    my ($PHfiles, $format, $ext, $PAfiles, $PAnot_found) = @_;
    @$PAfiles = @$PAnot_found = ();
    foreach my $name (keys %$PHfiles) {
        if (my @lines = kpsewhich( "-format=$format", $name ) ) {
            $$PHfiles{$name} = $lines[0];
            push @$PAfiles, $lines[0];
        }
        else {
            $$PHfiles{$name} = '';
            push @$PAnot_found, $name;
        }
    }
    @$PAnot_found = sort @$PAnot_found;
    @$PAfiles = sort @$PAfiles;
    foreach (@$PAnot_found) {
        if ( ! /\..*$/ ) { $_ .= ".$ext"; }
        push @$PAfiles, $_;
    }
    
    return 1 + $#{$PAnot_found};
} #END find_files

#************************************************************
#************************************************************

sub unlink_or_move {
    if ( $del_dir eq '' ) {
        foreach (@_) {
            if (!-e) {next;}
            if (-d) {
                if (!rmdir) {
                    warn "$My_name: Cannot remove directory '$_'\n",
                         "   Error message = '$!'\n";
                }
            }
            else { 
                if (!unlink) {
                    warn "$My_name: Cannot remove file '$_'\n",
                         "   Error message = '$!'\n";
                }
            }
        }
    }
    else {
        foreach (@_) {
            if (-e $_ && ! move $_, "$del_dir/$_" ) {
                warn "$My_name: Cannot move '$_' to '$del_dir/$_'\n",
                     "   Error message = '$!'\n";
            }
        }
    }
}

#************************************************************

sub make_path_mod {
    # Ensures directory given in $_[0] exists, with error checking
    my $dir = $_[0];
    my $title = $_[1];
    my $ret = 0;
    if ( -d $dir ) {}
    elsif ( (! -e $dir) && (! -l $dir) ) {
        # N.B. A link pointing to a non-existing target
        # returns false for -e, so we must also check -l
        print "$My_name: making $title directory '$dir'\n"
            if ! $silent;
        # Error handling from File::Path documentation:
        make_path( $dir, {error => \my $err} );
        if ($err && @$err) {
             for my $diag (@$err) {
                 my ($file, $message) = %$diag;
                 if ($file eq '') {
                     print "general error in making dir: $message\n";
                 }
                 else {
                      print "problem making path $file: $message\n";
                }
             }
             $ret = 1;
        }
    }
    else {
        $ret = 2;
        warn "$My_name: you requested $title directory '$dir',\n",
            "    but a non-directory file/symlink of the same name exists.\n";
    }
    return $ret;
}

#************************************************************

sub kpsewhich {
    # Usage: kpsewhich( [options, ] filespec, ...)
    # The arguments are the command line arguments to kpsewhich, and the
    # return value is the array of filenames that are returned by
    # kpsewhich.
    # N.B. kpsewhich returns one line per found file; this routine removes
    # trailing line ends (\r\n or \n) before putting the line in the
    # returned array.
    # The arguments can just be names: e.g.,
    #    kpsewhich( 'try.sty', 'jcc.bib' );
    # or can include options, e.g., 
    #    kpsewhich( '-format=bib', 'trial.bib', 'file with spaces');
    # With standard use of kpsewhich (i.e., without -all option), the array
    # has either 0 or 1 element for each filespec argument.

    my $cmd = $kpsewhich;
    my @args = @_;
    if ( ($cmd eq '') || ( $cmd =~ /^NONE($| )/ ) ) {
        # Kpsewhich not set up.
        warn "$My_name: Kpsewhich command needed but not set up\n";
        return ();
    }
    foreach (@args) {
        if ( ! /^-/ ) {
            $_ = "\"$_\"";
        }
    }
    $cmd =~ s/%[RBTDO]//g;
    $cmd =~ s/%S/@_/g;
    my @found = ();
    local $fh;
    if ( $kpsewhich_show || $diagnostics ) {
        print "$My_name.kpsewhich: Running '$cmd'...\n";
    }
    open $fh, "$cmd|"
        or die "Cannot open pipe for \"$cmd\"\n";
    while ( <$fh> ) {
        s/\r?\n$//;
        push @found, $_;
    }
    close $fh;
    if ( $kpsewhich_show || $diagnostics ) {
        show_array( "$My_name.kpsewhich: '$cmd' ==>", @found );
    }
    return @found;
}

####################################################

sub add_cus_dep {
    # Usage: add_cus_dep( from_ext, to_ext, flag, sub_name )
    # Add cus_dep after removing old versions
    my ($from_ext, $to_ext, $must, $sub_name) = @_;
    remove_cus_dep( $from_ext, $to_ext );
    push @cus_dep_list, "$from_ext $to_ext $must $sub_name";
}

####################################################

sub remove_cus_dep {
    # Usage: remove_cus_dep( from_ext, to_ext )
    my ($from_ext, $to_ext) = @_;
    my $i = 0;
    while ($i <= $#cus_dep_list) {
        # Use \Q and \E round directory name in regex to avoid interpretation
        #   of metacharacters in directory name:
        if ( $cus_dep_list[$i] =~ /^\Q$from_ext $to_ext \E/ ) {
            splice @cus_dep_list, $i, 1;
        }
        else {
            $i++;
        }
    }
}

####################################################

sub show_cus_dep {
    show_array( "Custom dependency list:", @cus_dep_list );
}

####################################################

sub find_cus_dep {
    # Usage find_cus_dep( dest, source )
    # Given dest, if a cus_dep to make it is found, set source.
    # Return 1 or 0 on success or failure.
    #
    my $dest = $_[0];
    my ($base, $path, $ext) = fileparseB( $dest );
    $ext =~ s/^\.//;
    if (! $ext ) { return 0; }
    foreach my $dep ( @cus_dep_list ) {
        my ($fromext, $toext) = split( '\s+', $dep );
        if ( ( "$ext" eq "$toext" ) && ( -f "$path$base.$fromext" ) ) {
            # We have a way of making $dest
            $_[1] = "$path$base.$fromext";
            return 1
        }
    }
    return 0;
}

####################################################
####################################################

sub add_hook {
    # Usage: add_book( name of stack, name of orpointer to subroutine )
    # Return 1 for success, 0 for failure.
    our %hooks;
    my ($stack, $routine ) = @_;
    unless ( exists $hooks{$stack} ) {
        warn "In add_hook, request to add hook to non-existent stack '$stack'.\n";
        return 0;
    }

    my $ref;
    if ( ref $routine ) {
        $ref = $routine
    }
    elsif ( defined &$routine ) {
        $ref = \&$routine;
    }
    else {
        warn "In add_hook, no subroutine '$routine' to add to stack '$stack'.\n";
            return 0;
    }
    push @{$hooks{$stack}}, $ref;
    return 1;
}

#****************************************************

sub run_hooks {
    # Usage: run_hooks( stackname, ... )
    # Call the subroutines whose references on on the named stack.
    # They are given arguments as follows
    #   a. If arguments follow the stackname in the call to run_hooks, these
    #      are given to the called subroutines.
    #   b. Otherwise a hash of information is given to the called subroutines.
    # Return 1 for success, 0 for failure.        
    my $name = shift;
    my $Pstack = $hooks{$name};
    my @args = @_;
    if (!@args) { @args = &info_make; }
    else { print "Have args\n"; }
    if (defined $Pstack) {
        # Do NOT use default $_, as in "for (...) {...}":
        # The called subroutine may change $_, which is a global variable
        # (although localized to the for loop and called subroutines).
        for my $Psub ( @$Pstack) { &$Psub(@args); }
        return 1;
    }
    else {
        warn "run_hooks: No stack named '$name'\n";
        return 0;
    }
}

#-------------------------------------

sub info_make {
    my %info_make = (
        'aux_main'  => $aux_main,
        'fls_file'  => $fls_name,
        'log_file'  => $log_name,
        'root_name' => $root_filename,
        'tex_file'  => $texfile_name,   

        'aux_dir'   => $aux_dir,
        'aux_dir1'  => $aux_dir1,
        'out_dir'   => $out_dir,
        'out_dir1'  => $out_dir1,
        );
    # Rule data, if in rule context:
    if ($rule)    { $info_make{rule} = $rule; }
    if ($Pbase)   { $info_make{base} = $$Pbase; }
    if ($Psource) { $info_make{source} = $$Psource; }
    if ($Pdest)   { $info_make{dest} = $$Pdest; }
    return %info_make;
}

####################################################

sub set_input_ext {
    # Usage: set_input_ext( rule, ext, ... )
    # Set list of extension(s) (specified without a leading period) 
    # for the given rule ('latex', 'pdflatex', etc).  
    # These extensions are used when an input
    # file without an extension is found by *latex, as in
    # \input{file} or \includegraphics{figure}.  When latexmk searches
    # custom dependencies to make the missing file, it will assume that
    # the file has one of the specified extensions.
    my $rule = shift;
    $input_extensions{$rule} = { map { $_ => 1 } @_ };
}

####################################################

sub show_input_ext {
    # Usage: show_input_ext( rule )
    my $rule = shift;
    show_array ("Input extensions for rule '$rule': ", 
                keys %{$input_extensions{$rule}} );
}

####################################################

sub find_dirs1 {
   # Same as find_dirs, but argument is single string with directories
   # separated by $search_path_separator
   # ???!!! WRONG DEFAULT?
   find_dirs( &split_search_path( $search_path_separator, ".", $_[0] ) );
}


#************************************************************

sub find_dirs {
# @_ is list of directories
# return: same list of directories, except that for each directory 
#         name ending in //, a list of all subdirectories (recursive)
#         is added to the list.
#   Non-existent directories and non-directories are removed from the list
#   Trailing "/"s and "\"s are removed
    local @result = ();
    my $find_action 
        = sub 
          { ## Subroutine for use in File::find
            ## Check to see if we have a directory
               if (-d) { push @result, $File::Find::name; }
          };
    foreach my $directory (@_) {
        my $recurse = ( $directory =~ m[//$] );
        # Remove all trailing /s, since directory name with trailing /
        #   is not always allowed:
        $directory =~ s[/+$][];
        # Similarly for MSWin reverse slash
        $directory =~ s[\\+$][];
        if ( ! -e $directory ){
            next;
        }
        elsif ( $recurse ){
            # Recursively search directory
            find( $find_action, $directory );
        }
        else {
            push @result, $directory;
        }
    }
    return @result;
}

#************************************************************

# How I use the result of loading glob routines:
sub my_glob {
    my @results = ();
    if ($have_bsd_glob) { @results = bsd_glob( $_[0] ); }
    else { @results =  glob( $_[0] ); }
    return @results;
}

#************************************************************

sub uniq 
# Read arguments, delete neighboring items that are identical,
# return array of results
{
    my @sort = ();
    my ($current, $prev);
    my $first = 1;
    while (@_)
    {
        $current = shift;
        if ($first || ($current ne $prev) )
        {
            push @sort, $current; 
            $prev = $current;
            $first = 0;
        }
    }
    return @sort;
}

#==================================================

sub uniq1 {
   # Usage: uniq1( strings )
   # Returns array of strings with duplicates later in list than
   # first occurence deleted.  Otherwise preserves order.

    my @strings = ();
    my %string_hash = ();

    foreach my $string (@_) {
        if (!exists( $string_hash{$string} )) { 
            $string_hash{$string} = 1;
            push @strings, $string; 
        }
    }
    return @strings;
}

#************************************************************

sub uniqs {
    # Usage: uniq2( strings )
    # Returns array of strings sorted and with duplicates deleted
    return uniq( sort @_ );
}

#************************************************************

sub ext {
    # Return extension of filename.  Extension includes the period
    my $file_name = $_[0];
    my ($base_name, $path, $ext) = fileparseA( $file_name );
    return $ext;
 }

#************************************************************

sub ext_no_period {
    # Return extension of filename.  Extension excludes the period
    my $file_name = $_[0];
    my ($base_name, $path, $ext) = fileparseA( $file_name );
    $ext =~ s/^\.//;
    return $ext;
 }

#************************************************************

sub fileparseA {
    # Like fileparse but replace $path for current dir ('./' or '.\') by ''
    # Also default second argument to get normal extension.
    my $given = $_[0];
    my $pattern = '\.[^\.]*';
    if  ($#_ > 0 ) { $pattern = $_[1]; }
    my ($base_name, $path, $ext) = fileparse( $given, $pattern );
    if ( ($path eq './') || ($path eq '.\\') ) { 
        $path = ''; 
    }
    return ($base_name, $path, $ext);
}

#************************************************************

sub fileparseB {
    # Like fileparse but with default second argument for normal extension
    my $given = $_[0];
    my $pattern = '\.[^\.]*';
    if  ($#_ > 0 ) { $pattern = $_[1]; }
    my ($base_name, $path, $ext) = fileparse( $given, $pattern );
    return ($base_name, $path, $ext);
}

#************************************************************

sub split_search_path 
{
# Usage: &split_search_path( separator, default, string )
# Splits string by separator and returns array of the elements
# Allow empty last component.
    # Replace empty terms by the default. ???!!! WRONG DEFAULT?
    my $separator = $_[0]; 
    my $default = $_[1]; 
    my $search_path = $_[2]; 
    my @list = split( /$separator/, $search_path);
    if ( $search_path =~ /$separator$/ ) {
        # If search path ends in a blank item, the split subroutine
        #    won't have picked it up.
        # So add it to the list by hand:
        push @list, "";
    }
    # Replace each blank argument (default) by current directory:
    for ($i = 0; $i <= $#list ; $i++ ) {
        if ($list[$i] eq "") {$list[$i] = $default;}
    }
    return @list;
}

#################################

sub get_filetime_offset {
    # Usage: get_filetime_offset( prefix, [suffix] )
    # Measures offset between filetime in a directory and system time
    # Makes a temporary file of a unique name, and deletes in.
    # Filename is of form concatenation of prefix, an integer, suffix.
    # Prefix is normally of form dir/ or dir/tmp.
    # Default default suffix ".tmp".
    my $prefix = $_[0];
    my $suffix = $_[1] || '.tmp';
    my $tmp_file_count = 0;
    while (1==1) {
        # Find a new temporary file, and make it.
        $tmp_file_count++;
        my $tmp_file = "${prefix}${tmp_file_count}${suffix}";
        if ( ! -e $tmp_file ) {
            open( TMP, ">$tmp_file" ) 
                or die "$My_name.get_filetime_offset: In measuring filetime offset, couldn't write to\n",
                       "    temporary file '$tmp_file'\n";
            my $time = time();
            close(TMP);
            my $offset = get_mtime($tmp_file) - $time;
            unlink $tmp_file;
            return $offset;
         }
     }
     die "$My_name.get_filetime_offset: BUG TO ARRIVE HERE\n";
}

#################################

sub tempfile1 {
    # Makes a temporary file of a unique name.  I could use file::temp,
    # but it is not present in all versions of perl.
    # Filename is of form $tmpdir/$_[0]nnn$suffix, where nnn is an integer
    my $tmp_file_count = 0;
    my $prefix = $_[0];
    my $suffix = $_[1];
    while (1==1) {
        # Find a new temporary file, and make it.
        $tmp_file_count++;
        my $tmp_file = "${tmpdir}/${prefix}${tmp_file_count}${suffix}";
        if ( ! -e $tmp_file ) {
            open( my $tmp, ">$tmp_file" ) 
               or next;
            close($tmp);
            return $tmp_file;
         }
     }
     die "$My_name.tempfile1: BUG TO ARRIVE HERE\n";
}

#################################

#************************************************************
#************************************************************
#      Process/subprocess routines

sub Run_msg {
    # Same as Run, but give message about my running
    warn_running( "Running '$_[0]'" );
    return Run($_[0]);
} #END Run_msg

#==================

sub Run {
# Usage: Run_no_time ("command string");
#    or  Run_no_time ("one-or-more keywords command string");
# Possible keywords: internal, NONE, start, nostart.
#
# A command string not started by keywords just gives a call to system with
#   the specified string, I return after that has finished executing.
# Exceptions to this behavior are triggered by keywords.
# The general form of the string is
#    Zero or more occurences of the start keyword,
#    followed by at most one of the other key words (internal, nostart, NONE),
#    followed by (a) a command string to be executed by the systerm
#             or (b) if the command string is specified to be internal, then
#                    it is of the form
#
#                       routine arguments
#
#                    which implies invocation of the named Perl subroutine
#                    with the given arguments, which are obtained by splitting
#                    the string into words, delimited by spaces, but with
#                    allowance for double quotes.
#
# The meaning of the keywords is:
#
#    start: The command line is to be running detached, as appropriate for
#             a previewer.  The method is appropriate for the operating system
#             (and the keyword is inspired by the action of the start command
#             that implements in under MSWin).
#           HOWEVER: the start keyword is countermanded by the nostart,
#             internal, and NONE keywords.  This allows rules that do
#             previewing to insert a start keyword to create a presumption
#             of detached running unless otherwise.
#   nostart: Countermands a previous start keyword; the following command
#             string is then to be obeyed by the system, and any necessary
#             detaching (as of a previewer) is done by the executed command(s).
#   internal: The following command string, of the form 'routine arguments'
#             specifies a call to the named Perl subroutine.
#   NONE:   This does not run anything, but causes an error message to be
#             printed.  This is provided to allow program names defined in the
#             configuration to flag themselves as unimplemented.
# Note that if the word "start" is duplicated at the beginning, that is
#   equivalent to a single "start".
#
# Return value is a list (pid, exitcode):
#   If a process is spawned sucessfully, and I know the PID,
#       return (pid, 0),
#   else if process is spawned sucessfully, but I do not know the PID,
#       return (0, 0),
#   else if process is run, 
#       return (0, exitcode of process)
#   else if I fail to run the requested process
#       return (0, suitable return code)
#   where return code is 1 if cmdline is null or begins with "NONE" (for
#       an unimplemented command)
#       or the return value of the Perl subroutine.
    my $cmd_line = $_[0];
    if ( $cmd_line eq '' ) {
        traceback( "$My_name: Bug OR configuration error\n".
                   "   In run of '$rule', attempt to run a null program" );
        return (0, 1);
    }
    # Deal with latexmk-defined pseudocommands 'start' and 'NONE' 
    # at front of command line:
    my $detach = 0;
    while ( $cmd_line =~ s/^start +// ) {
        # But first remove extra starts (which may have been inserted
        # to force a command to be run detached, when the command
        # already contained a "start").
        $detach = 1;
    }
    if ( $cmd_line =~ s/^nostart +// ) {
        $detach = 0;
    }
    if ( $cmd_line =~ /^internal\s+([a-zA-Z_]\w*)\s+(.*)$/ ) {
        my $routine = $1;
        my @args = parse_quotes( $2 );
        print "$My_name: calling $routine( $2 )\n"
            if (! $silent);
        return ( 0, &$routine( @args ) );
    }
    elsif ( $cmd_line =~ /^internal\s+([a-zA-Z_]\w*)\s*$/ ) {
        my $routine = $1;
        print "$My_name: calling $routine()\n"
            if (! $silent);
        return ( 0, &$routine() );
    }
    elsif ( $cmd_line =~ /^NONE/ ) {
        warn "$My_name: ",
             "Program not implemented for this version.  Command line:\n";
        warn "   '$cmd_line'\n";
        return (0, 1);
    }
    elsif ($detach) {
        # Run detached.  How to do this depends on the OS
        return &Run_Detached( $cmd_line );
    }
    else { 
       # The command is given to system as a single argument, to force shell
       # metacharacters to be interpreted:
       return( 0, system( $cmd_line ) );
   }
}  #END Run

#************************************************************

sub Run_Detached {
# Usage: Run_Detached ("program arguments ");
# Runs program detached.  Returns 0 on success, 1 on failure.
# Under UNIX use a trick to avoid the program being killed when the 
#    parent process, i.e., me, gets a ctrl/C, which is undesirable for pvc 
#    mode.  (The simplest method, system("program arguments &"), makes the 
#    child process respond to the ctrl/C.)
# Return value is a list (pid, exitcode):
#   If process is spawned sucessfully, and I know the PID,
#       return (pid, 0),
#   else if process is spawned sucessfully, but I do not know the PID,
#       return (0, 0),
#   else if I fail to spawn a process
#       return (0, 1)

    my $cmd_line = $_[0];

##    print "Running '$cmd_line' detached...\n";
    if ( $cmd_line =~ /^NONE / ) {
        warn "$My_name: ",
             "Program not implemented for this version.  Command line:\n";
        warn "   '$cmd_line'\n";
        return (0, 1);
    }

    if ( "$^O" eq "MSWin32" ){
        # Win95, WinNT, etc: Use MS's start command:
        # Need extra double quotes to deal with quoted filenames: 
        #    MSWin start takes first quoted argument to be a Window title. 
        return( 0, system( "start \"\" $cmd_line" ) );
    } else {
        # Assume anything else is UNIX or clone
        # For this purpose cygwin behaves like UNIX.
        ## print "Run_Detached.UNIX: A\n";
        my $pid = fork();
        ## print "Run_Detached.UNIX: B pid=$pid\n";
        if ( ! defined $pid ) {
            ## print "Run_Detached.UNIX: C\n";
            warn "$My_name: Could not fork to run the following command:\n";
            warn "   '$cmd_line'\n";
            return (0, 1);
        }
        elsif( $pid == 0 ){
           ## print "Run_Detached.UNIX: D\n";
           # Forked child process arrives here
           # Insulate child process from interruption by ctrl/C to kill parent:
           #     setpgrp(0,0);
           # Perhaps this works if setpgrp doesn't exist 
           #    (and therefore gives fatal error):
           eval{ setpgrp(0,0);};
           exec( $cmd_line );
           # Exec never returns; it replaces current process by new process
           die "$My_name forked process: could not run the command\n",
               "  '$cmd_line'\n";
        }
        ##print "Run_Detached.UNIX: E\n";
        # Original process arrives here
        return ($pid, 0);
    }
    # NEVER GET HERE.
    ##print "Run_Detached.UNIX: F\n";
} #END Run_Detached

#************************************************************

sub find_process_id {
# find_process_id(string) finds id of process containing string and
# being run by the present user.  In all the uses in latexmk, the string is
# the name of a file that is expected to be on the command line.
#
# On success, this subroutine returns the process ID.
# On failure, it returns 0.
#
# This subroutine only works on UNIX systems at the moment.

    if ( $pid_position < 0 ) {
        # I cannot do a ps on this system
        return (0);
    }

    my $looking_for = $_[0];
    my @ps_output = `$pscmd`;
    my @ps_lines = ();

# There may be multiple processes.  Find only latest, 
#   almost surely the one with the highest process number
# This will deal with cases like xdvi where a script is used to 
#   run the viewer and both the script and the actual viewer binary
#   have running processes.
    my @found = ();

    shift(@ps_output);  # Discard the header line from ps
    foreach (@ps_output)   {
        next unless ( /$looking_for/ ) ;
        s/^\s*//;
        my @ps_line = split ('\s+');
        push @found, $ps_line[$pid_position];
        push @ps_lines, $_;
    }

    if ($#found < 0) {
       # No luck in finding the specified process.
       return(0);
    }
    @found = reverse sort @found;
    if ($diagnostics) {
       print "Found the following processes concerning '$looking_for'\n",
             "   @found\n",
             "   I will use $found[0]\n";
       print "   The relevant lines from '$pscmd' were:\n";
       foreach (@ps_lines) { print "   $_"; }
    }
    return $found[0];
}

#************************************************************
#************************************************************
#************************************************************

#============================================

sub cache_good_cwd {
    # Set cached value of cwd to current cwd.
    # Under cygwin, the cached value is converted to a native MSWin path so
    # that the result can be used for input to MSWin programs as well
    # as cygwin programs.
    # Similarly for msys.
    my $cwd = getcwd();
    if ( $^O eq "cygwin" ) {
        my $cmd = "cygpath -w \"$cwd\"";
        my $Win_cwd = `$cmd`;
        chomp $Win_cwd;
        if ( $Win_cwd ) {
            $cwd = $Win_cwd;
        }
        else {
            warn "$My_name: Could not correctly run command\n",
                 "      '$cmd'\n",
                 "  to get MSWin version of cygwin path\n",
                 "     '$cwd'\n",
                 "  The result was\n",
                 "     '$Win_cwd'\n";
        }
    }
    elsif ( $^O eq "msys" ) {
        $cwd =~ s[^/([a-z])/][\u$1:/];
    }
    # Normalized
    if ($normalize_names) {
        $cwd = abs_path($cwd);
    }
    $cache{cwd} = $cwd;
}  # END cache_good_cwd

#============================================

sub good_cwd {
    # Return cwd, but under cygwin (or ...), convert to MSWin path.
    # Use cached result, to save a possible expensive computation (running 
    #  of extenal program under cygwin).
    return $cache{cwd};
}  # END good_cwd

#============================================

#   Directory stack routines

sub pushd {
    push @dir_stack, [cwd(), $cache{cwd}];
    if ( $#_ > -1) {
        local $ret = 0;
        eval {
            if ( -d $_[0] ) {
                $ret = chdir dirname_no_tail( $_[0] );
            }
            else {
                print "$my_name: Can't change directory to '$_[0]'\n",
                      "   A directory of the same name does not exist.\n";
            }
        };
        if ( ($ret == 0) || $@ ) {            
            if ($@) {
                print "Error:\n  $@" ;
            }
            die "$My_name: Error in changing directory to '$_[0]'.  I must stop\n";
        }
        &cache_good_cwd;
    }
}

#************************************************************

sub popd {
    if ($#dir_stack > -1 ) { 
        my $Parr = pop @dir_stack;
        chdir $$Parr[0];
        $cache{cwd} = $$Parr[1];
    }
}

#************************************************************

sub ifcd_popd {
    if ( $do_cd ) {
        print "$My_name: Undoing directory change\n"
          if !$silent;
        &popd;
    }
}

#************************************************************

sub finish_dir_stack {
    while ($#dir_stack > -1 ) { &popd; }
}

#************************************************************
#************************************************************
# Break handling routines (for wait-loop in preview continuous)

sub end_wait {
    #  Handler for break: Set global variable $have_break to 1.
    # Some systems (e.g., MSWin reset) appear to reset the handler.
    # So I'll re-enable it
    &catch_break;
    $have_break = 1;
}

#========================

sub catch_break {
# Capture ctrl/C and ctrl/break.
# $SIG{INT} corresponds to ctrl/C on LINUX/?UNIX and MSWin
# $SIG{BREAK} corresponds to ctrl/break on MSWin, doesn't exist on LINUX
    $SIG{INT} = \&end_wait;
    if ( exists $SIG{BREAK} ) {
        $SIG{BREAK} = \&end_wait;
    }
}

#========================

sub default_break {
# Arrange for ctrl/C and ctrl/break to give default behavior
    $SIG{INT} = 'DEFAULT';
    if ( exists $SIG{BREAK} ) {
        $SIG{BREAK} = 'DEFAULT';
    }
}

#************************************************************
#************************************************************
