#!/usr/bin/env perl
# $Id: fmtutil.pl 65989 2023-02-20 21:52:59Z karl $
# fmtutil - utility to maintain format files.
# (Maintained in TeX Live:Master/texmf-dist/scripts/texlive.)
# 
# Copyright 2014-2023 Norbert Preining
# This file is licensed under the GNU General Public License version 2
# or any later version.
#
# History:
# Original shell script 2001 Thomas Esser, public domain

my $TEXMFROOT;

BEGIN {
  $^W = 1;
  $TEXMFROOT = `kpsewhich -var-value=TEXMFROOT`;
  if ($?) {
    die "$0: kpsewhich -var-value=TEXMFROOT failed, aborting early.\n";
  }
  chomp($TEXMFROOT);
  unshift(@INC, "$TEXMFROOT/tlpkg", "$TEXMFROOT/texmf-dist/scripts/texlive");
  require "mktexlsr.pl";
  TeX::Update->import();
}

my $svnid = '$Id: fmtutil.pl 65989 2023-02-20 21:52:59Z karl $';
my $lastchdate = '$Date: 2023-02-20 22:52:59 +0100 (Mon, 20 Feb 2023) $';
$lastchdate =~ s/^\$Date:\s*//;
$lastchdate =~ s/ \(.*$//;
my $svnrev = '$Revision: 65989 $';
$svnrev =~ s/^\$Revision:\s*//;
$svnrev =~ s/\s*\$$//;
my $version = "r$svnrev ($lastchdate)";

use strict;
use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use File::Basename;
use File::Spec;
use Cwd;

# don't import anything automatically, this requires us to explicitly
# call functions with TeXLive::TLUtils prefix, and makes it easier to
# find and if necessary remove references to TLUtils
use TeXLive::TLUtils qw(wndws);

require TeXLive::TLWinGoo if wndws();

# numerical constants
my $FMT_NOTSELECTED = 0;
my $FMT_DISABLED    = 1;
my $FMT_FAILURE     = 2;
my $FMT_SUCCESS     = 3;
my $FMT_NOTAVAIL    = 4;

my $nul = (wndws() ? 'nul' : '/dev/null');
my $sep = (wndws() ? ';' : ':');

my @deferred_stderr;
my @deferred_stdout;
# $::opt_verbosity = 3; # manually enable debugging

my $first_time_creation_in_usermode = 0;
my $first_time_usermode_warning = 1; # give lengthy warning if warranted?

my $DRYRUN = "";
my $STATUS_FH;

(our $prg = basename($0)) =~ s/\.pl$//;

# make sure that the main binary path is available at the front
TeXLive::TLUtils::prepend_own_path();

# sudo sometimes does not reset the home dir of root, check on that
# see more comments at the definition of the function itself
# this function checks by itself whether it is running on windows or not
reset_root_home();

chomp(our $TEXMFDIST = `kpsewhich --var-value=TEXMFDIST`);
chomp(our $TEXMFVAR = `kpsewhich -var-value=TEXMFVAR`);
chomp(our $TEXMFSYSVAR = `kpsewhich -var-value=TEXMFSYSVAR`);
chomp(our $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
chomp(our $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
chomp(our $TEXMFHOME = `kpsewhich -var-value=TEXMFHOME`);

# make sure that on windows *everything* is in lower case for comparison
if (wndws()) {
  $TEXMFDIST = lc($TEXMFDIST);
  $TEXMFVAR = lc($TEXMFVAR);
  $TEXMFSYSVAR = lc($TEXMFSYSVAR);
  $TEXMFCONFIG = lc($TEXMFCONFIG);
  $TEXMFSYSCONFIG = lc($TEXMFSYSCONFIG);
  $TEXMFROOT = lc($TEXMFROOT);
  $TEXMFHOME = lc($TEXMFHOME);
}

#
# these need to be "our" variables since they are used from the 
# functions in TLUtils.pm.
our $texmfconfig = $TEXMFCONFIG;
our $texmfvar    = $TEXMFVAR;
our $alldata;

# command line options with defaults
# 20160623 - switch to turn on strict mode
our %opts = ( quiet => 0 , strict => 1 );

# make a list of all the commands (as opposed to options), so we can
# reasonably check for multiple commands being (erroneously) given.
my @cmdline_cmds = (  # in same order as help message
  "all",
  "missing",
  "byengine=s",
  "byfmt=s",
  "byhyphen=s",
  "enablefmt=s",
  "disablefmt=s",
  "listcfg",
  "showhyphen=s",
);

our @cmdline_options = (  # in same order as help message
  "sys",
  "user",
  "cnffile=s@", 
  "dry-run|n",
  "fmtdir=s",
  "no-engine-subdir",
  "no-error-if-no-engine=s",
  "no-error-if-no-format",
  "nohash",
  "recorder",
  "refresh",
  "status-file=s",
  "strict!",
  "quiet|silent|q",
  "catcfg",
  "dolinks",
  "force",
  "test",
#
  @cmdline_cmds,
  "version",
  "help|h",
#
  "edit",		# omitted from help to discourage use
  "_dumpdata",		# omitted from help, data structure dump for debugging
  );

my $updLSR;
my $mktexfmtMode = 0;
# make sure we echo only *one* line in mktexfmt mode
my $mktexfmtFirst = 1;

my $status = &main();
print_info("exiting with status $status\n");
exit $status;


# 
sub main {
  if ($prg eq "mktexfmt") {
    # mktexfmtMode: if called as mktexfmt, set to true. Will echo the
    # first generated filename after successful generation to stdout then
    # (and nothing else), since kpathsea can only deal with one.
    $mktexfmtMode = 1;

    # we default to user mode here, in particular because **if** TEXMFSYSVAR
    # is writable we will use it to save format dumps created by mktexfmt
    # If root is running mktexfmt, then most probably the formats will end
    # up in TEXMFSYSVAR which is fine.
    $opts{'user'} = 1;

    my @save_argv = @ARGV;
    GetOptions (
      "dry-run|n", \$opts{'dry-run'},
      "help" => \$opts{'help'},
      "version" => \$opts{'version'}
      ) || die "$prg: Unknown option in mktexfmt command line: @save_argv\n";

    help() if $opts{'help'};
    if ($opts{'version'}) {
      print version();
      exit 0;  # no final print_info
    }

    if ($ARGV[0]) {
      if ($ARGV[0] =~ m/^(.*)\.(fmt|mem|base?)$/) {
        $opts{'byfmt'} = $1;
      } elsif ($ARGV[0] =~ m/\./) {
        die "unknown format type: $ARGV[0]";
      } else {
        $opts{'byfmt'} = $ARGV[0];
      }
    } else {
      die "missing argument to mktexfmt";
    }
  } else {
    # fmtutil mode.
    GetOptions(\%opts, @cmdline_options)
      || die "Try \"$prg --help\" for more information.\n";
    if (@ARGV) {
      die "$0: Unexpected non-option argument(s): @ARGV\n"
          . "Try \"$prg --help\" for more information.\n";
    }
  }

  help() if $opts{'help'};
  if ($opts{'version'}) {
    print version();
    exit 0;  # no final print_info
  }

  { # if two commands were given, complain and give up.
    my @cmds = ();
    for my $c (@cmdline_cmds) {
      $c =~ s,=.*$,,;                       # remove =s getopt spec
      push(@cmds, $c) if exists $opts{$c};  # remember if getopt found it
      # we could save/report the specified arg too, but maybe not worth it.
    }
    if (@cmds > 1) {
      print_error("multiple commands found: @cmds\n"
                  . "Try $prg --help if you need it.\n");
      return 1;
    } elsif (@cmds == 0) {
      if ($opts{'refresh'}) {
        # backward compatibility: till 2021 we had --refresh as a command
        # but now we allow combining it with --byfmt etc
        # In case that --refresh was given without any other command, we
        # treat it as --all --refresh as it was the case till the change.
        $opts{'all'} = 1;
      } else {
        print_error("no command specified; try $prg --help if you need it.\n");
        return 1;
      }
    }
  }

  $DRYRUN = "echo " if ($opts{'dry-run'});

  if ($opts{'status-file'} && ! $opts{'dry-run'}) {
    if (! open($STATUS_FH, '>>', $opts{'status-file'})) {
      print_error("cannot open status file >>$opts{'status-file'}: $!\n");
      print_error("not writing status information!\n");
    }
  }
  
  # get the config/var trees we will use.
  ($texmfconfig, $texmfvar)
    = TeXLive::TLUtils::setup_sys_user_mode($prg, \%opts,
                       $TEXMFCONFIG, $TEXMFSYSCONFIG, $TEXMFVAR, $TEXMFSYSVAR);
  
  # if we are using the sys tree, we don't want to give the usermode warning.
  if ($texmfvar eq $TEXMFSYSVAR) {
    $first_time_usermode_warning = 0;
  }

  determine_config_files("fmtutil.cnf");
  my $changes_config_file = $alldata->{'changes_config'};
  # we do changes always in the used config file with the highest priority
  my $bakFile = $changes_config_file;
  $bakFile =~ s/\.cfg$/.bak/;
  my $changed = 0;

  read_fmtutil_files(@{$opts{'cnffile'}});

  unless ($opts{"nohash"}) {
    # should be replaced by new mktexlsr perl version
    $updLSR = new TeX::Update;
    $updLSR->mustexist(0);
  }

  my $cmd;
  if ($opts{'edit'}) {
    if ($opts{"dry-run"}) {
      printf STDERR "No, are you joking, you want to edit with --dry-run?\n";
      return 1;
    }
    # it's not a good idea to edit fmtutil.cnf manually these days,
    # but for compatibility we'll silently keep the option.
    $cmd = 'edit';
    my $editor = $ENV{'VISUAL'} || $ENV{'EDITOR'};
    $editor ||= (&wndws ? "notepad" : "vi");
    if (-r $changes_config_file) {
      &copyFile($changes_config_file, $bakFile);
    } else {
      touch($bakFile);
      touch($changes_config_file);
    }
    system("$DRYRUN$editor", $changes_config_file);
    $changed = files_are_different($bakFile, $changes_config_file);

  } elsif ($opts{'showhyphen'}) {
    my $f = $opts{'showhyphen'};
    if ($alldata->{'merged'}{$f}) {
      my @all_engines = keys %{$alldata->{'merged'}{$f}};
      for my $e (sort @all_engines) {
        my $hf = $alldata->{'merged'}{$f}{$e}{'hyphen'};
        next if ($hf eq '-');
        my $ff = `kpsewhich -progname='$f' -format=tex '$hf'`;
        chomp($ff);
        if ($ff ne "") {
          if ($#all_engines > 0) {
            printf "$f/$e: ";
          }
          printf "$ff\n";
        } else {
          print_warning("hyphenfile (for $f/$e) not found: $hf\n");
          return 1;
        }
      }
    }

  } elsif ($opts{'listcfg'}) {
    return callback_list_cfg();

  } elsif ($opts{'disablefmt'}) {
    return callback_enable_disable_format($changes_config_file, 
                                          $opts{'disablefmt'}, 'disabled');
  } elsif ($opts{'enablefmt'}) {
    return callback_enable_disable_format($changes_config_file, 
                                          $opts{'enablefmt'}, 'enabled');
  } elsif ($opts{'byengine'}) {
    return callback_build_formats('byengine', $opts{'byengine'});

  } elsif ($opts{'byfmt'}) {
    # for this option, allow/ignore an extension.
    (my $fmtname = $opts{'byfmt'}) =~ s,\.(fmt|mem|base?)$,,;
    return callback_build_formats('byfmt', $fmtname);

  } elsif ($opts{'byhyphen'}) {
    return callback_build_formats('byhyphen', $opts{'byhyphen'});

  } elsif ($opts{'missing'}) {
    return callback_build_formats('missing');

  } elsif ($opts{'all'}) {
    return callback_build_formats('all');

  } elsif ($opts{'_dumpdata'}) {
    dump_data();

  } else {
    # redundant with check above, but just in case ...
    print_error("missing command; try $prg --help if you need it.\n");
    return 1;
  }

  if ($STATUS_FH) {
    close($STATUS_FH)
    || print_error("cannot close $opts{'status-file'}: $!\n");
  }

  unless ($opts{'nohash'}) {
    # TODO should only do this if built something, e.g., not --listcfg
    print_info("updating ls-R files\n");
    $updLSR->exec() unless $opts{"dry-run"};
  }

  # some simpler options 
  return 0;
}

sub dump_data {
  require Data::Dumper;
  $Data::Dumper::Indent = 1;
  $Data::Dumper::Indent = 1;
  print Data::Dumper::Dumper($alldata);
}

#
sub log_to_status {
  if ($STATUS_FH) {
    print $STATUS_FH "@_\n";
  }
}

#  callback_build_formats - (re)builds the formats as selected,
# returns exit status or dies.  Exit status is always zero unless
# --strict is specified, in which case it's the number of failed builds
# (presumably always less than 256 :).
#
sub callback_build_formats {
  my ($what, $whatarg) = @_;

  # set up a tmp dir
  # On W32 it seems that File::Temp creates restrictive permissions (ok)
  # that are copied over with the files created inside it (not ok).
  # So make our own temp dir.
  my $tmpdir = "";
  if (! $opts{"dry-run"}) {
    if (wndws()) {
      my $foo;
      my $tmp_deflt = File::Spec->tmpdir;
      for my $i (1..5) {
        # $foo = "$texmfvar/temp.$$." . int(rand(1000000));
        $foo = (($texmfvar =~ m!^//!) ? $tmp_deflt : $texmfvar)
          . "/temp.$$." . int(rand(1000000));
        if (! -d $foo) {
          TeXLive::TLUtils::mkdirhier($foo);
          sleep 1;
          if (-d $foo) {
            $tmpdir = $foo;
            last;
          }
        }
      }
      if (! $tmpdir) {
        die "Cannot get a temporary directory after five iterations, sorry!";
      }
      if ($texmfvar =~ m!^//!) {
        # used File::Spec->tmpdir; fix permissions
        TeXLive::TLWinGoo::maybe_make_ro ($tmpdir);
      }
    } else {
      $tmpdir = File::Temp::tempdir(CLEANUP => 1);
    }
  }
  # set up destination directory
  $opts{'fmtdir'} ||= "$texmfvar/web2c";
  if (! $opts{"dry-run"}) {
    TeXLive::TLUtils::mkdirhier($opts{'fmtdir'}) if (! -d $opts{'fmtdir'});
    if (! -w $opts{'fmtdir'}) {
      print_error("format directory not writable: $opts{fmtdir}\n");
      exit 1;
    }
  }
  # since the directory does not exist, we can make it absolute with abs_path
  # without any trickery around non-existing dirs
  $opts{'fmtdir'} = Cwd::abs_path($opts{'fmtdir'});
  # for safety, check again
  die "abs_path failed, strange: $!" if !$opts{'fmtdir'};
  print_info("writing formats under $opts{fmtdir}\n"); # report

  # code taken over from the original shell script for KPSE_DOT etc
  my $thisdir = cwd();
  $ENV{'KPSE_DOT'} = $thisdir;
  # due to KPSE_DOT, we don't search the current directory, so include
  # it explicitly for formats that \write and later on \read
  $ENV{'TEXINPUTS'} ||= "";
  $ENV{'TEXINPUTS'} = "$tmpdir$sep$ENV{TEXINPUTS}";
  #
  # for formats that load other formats (e.g., jadetex loads latex.fmt),
  # add the current directory to TEXFORMATS, too.  Currently unnecessary
  # for MFBASES.
  $ENV{'TEXFORMATS'} ||= "";
  $ENV{'TEXFORMATS'} = "$tmpdir$sep$ENV{TEXFORMATS}";

  # switch to temporary directory for format generation; on the other hand,
  # for -n, the tmpdir won't exist, but we don't want to find a spurious
  # tex.fmt in the cwd. Probably won't be such things in /.
  chdir($opts{"dry-run"} ? "/" : $tmpdir)
  || die "Cannot change to directory $tmpdir: $!";
  
  # we rebuild formats in two rounds:
  # round 1: only formats with the same name as engine (pdftex/pdftex)
  # round 2: all other formats
  # reason: later formats might need earlier formats to be already
  # initialized, e.g., xmltex.
  my $suc = 0;
  my $err = 0;
  my @err = ();
  my $disabled = 0;
  my $nobuild = 0;
  my $notavail = 0;
  my $total = 0;
  for my $swi (qw/format=engine format!=engine/) {
    for my $fmt (keys %{$alldata->{'merged'}}) {
      for my $eng (keys %{$alldata->{'merged'}{$fmt}}) {
        next if ($swi eq "format=engine" && $fmt ne $eng);
        next if ($swi eq "format!=engine" && $fmt eq $eng);
        $total++;
        my $val = select_and_rebuild_format($fmt, $eng, $what, $whatarg);
        if ($val == $FMT_DISABLED)    {
          log_to_status("DISABLED", $fmt, $eng, $what, $whatarg);
          $disabled++;
        } elsif ($val == $FMT_NOTSELECTED) {
          log_to_status("NOTSELECTED", $fmt, $eng, $what, $whatarg);
          $nobuild++;
        } elsif ($val == $FMT_FAILURE)  {
          log_to_status("FAILURE", $fmt, $eng, $what, $whatarg);
          $err++;
          push (@err, "$eng/$fmt");
        } elsif ($val == $FMT_SUCCESS)  {
          log_to_status("SUCCESS", $fmt, $eng, $what, $whatarg);
          $suc++;
        } elsif ($val == $FMT_NOTAVAIL) {
          log_to_status("NOTAVAIL", $fmt, $eng, $what, $whatarg);
          $notavail++; 
        }
        else {
          log_to_status("UNKNOWN", $fmt, $eng, $what, $whatarg);
          print_error("callback_build_format (round 1): unknown return "
           . "from select_and_rebuild.\n");
        }
      }
    }
  }

  # if the user asked to rebuild something, but we did nothing, report
  # unless we tried to rebuild only missing formats.
  if ($what ne "missing") {
    if ($err + $suc == 0) {
      if ($what eq "all") {
        print_warning("You seem to have no formats defined in your fmtutil.cnf files!\n");
      } else {
        print_info("Did not find entry for $what=" . ($whatarg?$whatarg:"") . " skipped\n");
      }
    }
  }
  my $stdo = ($mktexfmtMode ? \*STDERR : \*STDOUT);
  for (@deferred_stdout) { print $stdo $_; }
  for (@deferred_stderr) { print STDERR $_; }
  #
  print_info("disabled formats: $disabled\n")        if ($disabled);
  print_info("successfully rebuilt formats: $suc\n") if ($suc);
  print_info("not selected formats: $nobuild\n")     if ($nobuild);
  print_info("not available formats: $notavail\n")   if ($notavail);
  print_info("failed to build: $err (@err)\n")       if ($err);
  print_info("total formats: $total\n");
  chdir($thisdir) || warn "chdir($thisdir) failed: $!";
  if (wndws()) {
    # try to remove the tmpdir with all files
    TeXLive::TLUtils::rmtree($tmpdir);
  }
  #
  # In case of user mode and formats rebuilt, warn that these formats
  # will shadow future updates. Can be suppressed with --quiet which
  # does not show print_info output
  if ($opts{'user'} && $suc && $first_time_creation_in_usermode
      && $first_time_usermode_warning) {
    print_info("
*************************************************************
*                                                           *
* WARNING: you are switching to fmtutil's per-user formats. *
*         Please read the following warnings!               *
*                                                           *
*************************************************************

You have run fmtutil-user (as opposed to fmtutil-sys) for the first time;
this has created format files which are local to your personal account.

From now on, any changes in system formats will *not* be automatically
reflected in your files; furthermore, running fmtutil-sys will no longer
have any effect for you.

As a consequence, you yourself have to rerun fmtutil-user after any
change in the system directories. For example, when one of the LaTeX or
other format source files changes, which happens frequently.
See https://tug.org/texlive/scripts-sys-user.html for details.

If you want to undo this, remove the files mentioned above.

Run $prg --help for full documentation of fmtutil.
");
  }
  # return 
  return $opts{"strict"} ? $err : 0;
}

#  select_and_rebuild_format
# check condition and rebuild the format if selected
# return values: $FMT_*
# 
sub select_and_rebuild_format {
  my ($fmt, $eng, $what, $whatarg) = @_;
  return $FMT_DISABLED
      if ($alldata->{'merged'}{$fmt}{$eng}{'status'} eq 'disabled');

  my ($kpsefmt, $destdir, $fmtfile, $logfile) = compute_format_destination($fmt, $eng);

  my $doit = 0;
  # we just identify 'all', 'refresh', 'missing'
  # I don't see much point in keeping all of them
  $doit = 1 if ($what eq 'all');
  $doit = 1 if ($what eq 'refresh' && -r "$destdir/$fmtfile");
  $doit = 1 if ($what eq 'missing' && ! -r "$destdir/$fmtfile");
  $doit = 1 if ($what eq 'byengine' && $eng eq $whatarg);
  $doit = 1 if ($what eq 'byfmt' && $fmt eq $whatarg);
  #
  # Deal with the --refresh option
  # 2021 changed behavior that --refresh can be used with all other format
  # selection cmd line args.
  $doit = 0 if ($opts{'refresh'} && ! -r "$destdir/$fmtfile");
  #
  # TODO
  # original fmtutil.sh was stricter about existence of the hyphen file
  # not sure how we proceed here; let's implicitly ignore.
  #
  # original fmtutil.sh seemed to have accepted full path to the hyphen
  # file, so that one could give
  #   --byhyphen /full/path/to/the/hyphen/file
  # but this does not work anymore (see Debian bug report #815416)
  if ($what eq 'byhyphen') {
    my $fmthyp = (split(/,/ , $alldata->{'merged'}{$fmt}{$eng}{'hyphen'}))[0];
    if ($fmthyp ne '-') {
      if ($whatarg =~ m!^/!) {
        # $whatarg is a full path, we need to expand $fmthyp, too
        chomp (my $fmthyplong = `kpsewhich -progname=$fmt -engine=$eng $fmthyp`) ;
        if ($fmthyplong) {
          $fmthyp = $fmthyplong;
        } else {
          # we might have searched language.dat --engine=tex --progname=tex
          # which will not work. Search again without engine/format
          chomp ($fmthyplong = `kpsewhich $fmthyp`) ;
          if ($fmthyplong) {
            $fmthyp = $fmthyplong;
          } else {
            # don't give warnings or errors, it might be that the hyphen
            # file is not existing at all. See TODO above
            #print_deferred_warning("hyphen $fmthyp for $fmt/$eng cannot be expanded.\n");
          }
        }
      }
      if ($whatarg eq $fmthyp) {
        $doit = 1;
      }
    }
  }
  if ($doit) {
    check_and_warn_on_user_format($fmt,$eng);
    return rebuild_one_format($fmt,$eng,$kpsefmt,$destdir,$fmtfile,$logfile);
  } else {
    return $FMT_NOTSELECTED;
  }
}

sub check_and_warn_on_user_format {
  my ($fmt, $eng) = @_;
  # do nothing if we are updating files in $TEXMFVAR
  return if ($opts{'fmtdir'} eq "$TEXMFVAR/web2c");
  my $saved_fmtdir = $opts{'fmtdir'};
  $opts{'fmtdir'} = "$TEXMFVAR/web2c";
  my ($kpsefmt, $destdir, $fmtfile, $logfile) = compute_format_destination($fmt, $eng);
  if (-r "$destdir/$fmtfile") {
    print_deferred_warning("you have a shadowing format dump in TEXMFVAR for $fmt/$eng!!!\n");
  }
  $opts{'fmtdir'} = $saved_fmtdir;
}
  


#  compute_format_destination
# takes fmt/eng and returns the locations where format and log files
# should be saved, that is, a list: (dump file full path, log file full path)
# 
sub compute_format_destination {
  my ($fmt, $eng) = @_;
  my $enginedir;
  my $fmtfile = $fmt;
  my $kpsefmt;
  my $destdir;

  if ($eng eq "mpost") {
    $fmtfile .= ".mem" ;
    $kpsefmt = "mp" ;
    $enginedir = "metapost"; # the directory, not the executable
  } elsif ($eng =~ m/^mf(lua(jit)?)?(w|-nowin)?$/) {
    $fmtfile .= ".base" ;
    $kpsefmt = "mf" ;
    $enginedir = "metafont" ;
  } else {
    $fmtfile .= ".fmt" ;
    $kpsefmt = "tex" ;
    $enginedir = $eng;
    # strip final -dev from enginedir to support engines like luatex-dev
    $enginedir =~ s/-dev$//;
  }
  if ($opts{'no-engine-subdir'}) {
    $destdir = $opts{'fmtdir'};
  } else {
    $destdir = "$opts{'fmtdir'}/$enginedir";
  }
  return($kpsefmt, $destdir, $fmtfile, "$fmt.log");
}


#  rebuild_one_format
# takes fmt/eng and rebuilds it, irrelevant of any setting;
# copies generated log file
# return value FMT_*
#
sub rebuild_one_format {
  my ($fmt,$eng,$kpsefmt,$destdir,$fmtfile,$logfile) = @_;
  print_info("--- remaking $fmt with $eng\n");

  # get variables
  my $hyphen  = $alldata->{'merged'}{$fmt}{$eng}{'hyphen'};
  my $addargs = $alldata->{'merged'}{$fmt}{$eng}{'args'};

  # running parameters
  my $jobswitch = "-jobname=$fmt";
  my $prgswitch = "-progname=" ;
  my $recorderswitch = ($opts{'recorder'} ? "-recorder" : "");
  my $pool;
  my $tcx = "";
  my $tcxflag = "";
  my $localpool = 0;
  my $texargs;

  unlink glob "*.pool";

  # addargs processing:
  # can contain:
  # nls stuff (pool/tcx) see below
  # ini file (last argument)
  my $inifile = $addargs;
  $inifile = (split(' ', $addargs))[-1];
  # get rid of leading * in inifiles
  $inifile =~ s/^\*//;

  # Add -kanji-internal option for create (e-)p(La)TeX format
  # with (e-)upTeX's pTeX compatible mode.
  if ($eng =~ /^e?uptex$/
      && $fmt =~ /^e?p/
      && $addargs !~ /-kanji-internal=/) {
    my $kanji = wndws() ? "sjis" : "euc";
    $addargs = "-kanji-internal=$kanji " . $addargs;
  }

  if ($fmt eq "metafun")       { $prgswitch .= "mpost"; }
  elsif ($fmt eq "mptopdf")    { $prgswitch .= "context"; }
  elsif ($fmt =~ m/^cont-..$/) { $prgswitch .= "context"; }
  else                         { $prgswitch .= $fmt; }

  # check for existence of ini file before doing anything else
  if (system("kpsewhich -progname=$fmt -format=$kpsefmt $inifile >$nul 2>&1") != 0) {
    # we didn't find the ini file, skip
    print_deferred_warning("inifile $inifile for $fmt/$eng not found.\n");
    # The original script just skipped it but in TeX Live we expect that
    # all activated formats are also buildable, thus return failure.
    return $FMT_FAILURE;
  }

  #
  # If the 4th field in fmtutil.cnf contains
  #  -progname=...
  # then we do not add our own progname!
  if ($addargs =~ /-progname=/) {
    $prgswitch = '';
  }

  # NLS support
  #   Example (for fmtutil.cnf):
  #     mex-pl tex mexconf.tex nls=tex-pl,il2-pl mex.ini
  # The nls parameter (pool,tcx) can only be specified as the first argument
  # inside the 4th field in fmtutil.cnf.
  if ($addargs =~ m/^nls=([^\s]+)\s+(.*)$/) {
    $texargs = $2;
    ($pool, $tcx) = split(',', $1);
    $tcx || ($tcx = '');
  } else {
    $texargs = $addargs;
  }
  if ($pool) {
    chomp (my $poolfile = `kpsewhich -progname=$eng $pool.pool 2>$nul`);
    if ($poolfile && -f $poolfile) {
      print_verbose("attempting to create localized format "
                    . "using pool=$pool and tcx=$tcx.\n");
      TeXLive::TLUtils::copy("-f", $poolfile, "$eng.pool");
      $tcxflag = "-translate-file=$tcx" if ($tcx);
      $localpool = 1;
    }
  }

  # Check for infinite recursion before running the iniengine:
  # We do this check only if we are running in mktexfmt mode
  # otherwise double format definitions will create an infinite loop, too
  if ($mktexfmtMode) {
    if ($ENV{'mktexfmt_loop'}) {
      if ($ENV{'mktexfmt_loop'} =~ m!:$fmt/$eng:!) {
        die "$prg: infinite recursion detected in $fmt/$eng, giving up!";
      }
    } else {
      $ENV{'mktexfmt_loop'} = '';
    }
    $ENV{'mktexfmt_loop'} .= ":$fmt/$eng:";
  }

  #
  # check for existence of $engine
  # we do *NOT* use the return value but rely on execution of the shell
  if (!TeXLive::TLUtils::which($eng)) {
    if ($opts{'no-error-if-no-engine'} &&
        ",$opts{'no-error-if-no-engine'}," =~ m/,$eng,/) {
      return $FMT_NOTAVAIL;
    } else {
      print_deferred_error("not building $fmt due to missing engine: $eng\n");
      return $FMT_FAILURE;
    }
  }

  my $cmdline = "$eng -ini $tcxflag $recorderswitch $jobswitch "
                  . "$prgswitch $texargs";
  print_verbose("running \`$cmdline' ...\n");

  my $texpool = $ENV{'TEXPOOL'};
  if ($localpool) {
    $ENV{'TEXPOOL'} = cwd() . $sep . ($texpool ? $texpool : "");
  }

  # in mktexfmtMode we must redirect *all* output to stderr
  $cmdline .= " >&2" if $mktexfmtMode;
  $cmdline .= " <$nul";
  my $retval = system("$DRYRUN$cmdline");

  # report error if it failed.
  if ($retval != 0) {
    $retval /= 256 if ($retval > 0);
    print_deferred_error("running \`$cmdline' return status: $retval\n");
  }

  # Copy the log file after the program is run, so that the log file
  # is available to inspect even on failure. So we need the dest dir tree.
  TeXLive::TLUtils::mkdirhier($destdir) if ! $opts{"dry-run"};
  #
  if ($opts{"dry-run"}) {
    print_info("would copy log file to: $destdir/$logfile\n");
  } else {
    # Add the actual invocation to the end of the log file
    if (open(my $fd, ">>", $logfile)) {
      print $fd "# actual command line used during this run\n# $cmdline\n";
      close($fd);
    } else {
      print_deferred_error("cannot append cmdline to log file");
    }
    # Here and in the following we use copy instead of move
    # to make sure that in SElinux enabled cases the rules of
    # the destination directory are applied.
    # See https://bugs.debian.org/cgi-bin/bugreport.cgi?bug=900580
    # 
    if (TeXLive::TLUtils::copy("-f", $logfile, "$destdir/$logfile")) {
      print_info("log file copied to: $destdir/$logfile\n");
    } else {
      print_deferred_error("failed to copy log $logfile to: $destdir\n");
    }
  }

  # original shell script did *not* check the return value
  # we keep this behavior, but add an option --strict that
  # errors out on all failures.
  if ($retval != 0 && $opts{'strict'}) {
    print_deferred_error("returning error due to option --strict\n");
    return $FMT_FAILURE;
  }

  if ($localpool) {
    if ($texpool) {
      $ENV{'TEXPOOL'} = $texpool;
    } else {
      delete $ENV{'TEXPOOL'};
    }
  }

  # if this was a dry run, we don't expect anything to have been
  # created, so there's nothing to inspect or copy. Call it good.
  if ($opts{"dry-run"}) {
    print_info("dry run, so returning success: $fmtfile\n");
    return $FMT_SUCCESS;
  }

  # check and install of fmt and log files
  if (! -s $fmtfile) {
    print_deferred_error("no (or empty) $fmtfile made by: $cmdline\n");
    return $FMT_FAILURE;
  }

  if (! -f $logfile) {
    print_deferred_error("no log file generated for: $fmt/$eng\n");
    return $FMT_FAILURE;
  }

  open (LOGFILE, "<$logfile")
    || print_deferred_warning("cannot open $logfile, strange: $!\n");
  my @logfile = <LOGFILE>;
  close LOGFILE;
  if (grep(/^!/, @logfile) > 0) {
    print_deferred_error("\`$cmdline' had errors.\n");
  }

  if ($opts{'recorder'}) {
    # the recorder output is used by tl-check-fmttriggers to determine
    # package dependencies for each format.  Unfortunately omega-based
    # engines gratuitiously changed the extension from .fls to .ofl.
    my $recfile = $fmt . ($fmt =~ m/^(aleph|lamed)$/ ? ".ofl" : ".fls");
    if (! TeXLive::TLUtils::copy("-f", $recfile, "$destdir/$recfile")) {
      print_deferred_error("cannot copy recorder $recfile to: $destdir\n");
    }
  }

  my $destfile = "$destdir/$fmtfile";
  # set flag to warn that new user format was installed
  # we check whether the next command **would** create a new file,
  # and if it succeeded, we set the actual flag.
  my $possibly_warn = ($opts{'user'} && ! -r $destfile);
  if (TeXLive::TLUtils::copy("-f", $fmtfile, $destfile)) {
    print_info("$destfile installed.\n");
    $first_time_creation_in_usermode = $possibly_warn;
    #
    # original fmtutil.sh did some magic trick for mplib-luatex.mem
    # nowadays no mplib mem is created and all files loaded
    # so we comment and do not convert this
    #
    ## As a special special case, we create mplib-luatex.mem for use by
    ## the mplib embedded in luatex if it doesn't already exist.  (We
    ## never update it if it does exist.)
    ##
    ## This is used by the luamplib package.  This way, an expert user
    ## who wants to try a new version of luatex (hence with a new
    ## version of mplib) can manually update mplib-luatex.mem without
    ## having to tamper with mpost itself.
    ##
    ##  if test "x$format" = xmpost && test "x$engine" = xmpost; then
    ##    mplib_mem_name=mplib-luatex.mem
    ##    mplib_mem_file=$fulldestdir/$mplib_mem_name
    ##    if test \! -f $mplib_mem_file; then
    ##      verboseMsg "$progname: copying $destfile to $mplib_mem_file"
    ##      if cp "$destfile" "$mplib_mem_file" </dev/null; then
    ##        mktexupd "$fulldestdir" "$mplib_mem_name"
    ##      else
    ##        ## failure to copy merits failure handling: e.g., full file system.
    ##        log_failure "cp $destfile $mplib_mem_file failed."
    ##      fi
    ##    else
    ##      verboseMsg "$progname: $mplib_mem_file already exists, not updating."
    ##    fi
    ##  fi

    if ($mktexfmtMode && $mktexfmtFirst) {
      print "$destfile\n";
      $mktexfmtFirst = 0;
    }

    unless ($opts{'nohash'}) {
      $updLSR->add($destfile);
      $updLSR->exec();
      $updLSR->reset();
    }

    return $FMT_SUCCESS;

  } else {
    print_deferred_error("cannot copy format $fmtfile to: $destfile\n");
    if (-f $destfile) {
      # remove the empty file possibly left over if near-full file system.
      print_verbose("removing partial file after copy failure: $destfile\n");
      unlink($destfile)
        || print_deferred_error("unlink($destfile) failed: $!\n");
    }
    return $FMT_FAILURE;
  }

  print_deferred_error("we should not be here! $fmt/$eng\n");
  return $FMT_FAILURE;
}


# 
# enable_disable_format_engine
# assumes that format/engine is already defined somewhere,
# i.e., it $alldata->{'merged'}{$fmt}{$eng} is defined
#
# Return values:
# 1 - success with changes
# 0 - no changes done
# -1 - error appeared
sub enable_disable_format_engine {
  my ($tc, $fmt, $eng, $mode) = @_;
  if ($mode eq 'enabled' || $mode eq 'disabled') {
    if ($alldata->{'merged'}{$fmt}{$eng}{'status'} eq $mode) {
      print_info("Format/engine combination $fmt/$eng already $mode.\n");
      print_info("No changes done.\n");
      return 0;
    } else {
      my $origin = $alldata->{'merged'}{$fmt}{$eng}{'origin'};
      if ($origin ne $tc) {
        $alldata->{'fmtutil'}{$tc}{'formats'}{$fmt}{$eng} =
          {%{$alldata->{'fmtutil'}{$origin}{'formats'}{$fmt}{$eng}}};
        $alldata->{'fmtutil'}{$tc}{'formats'}{$fmt}{$eng}{'line'} = -1;
      }
      $alldata->{'fmtutil'}{$tc}{'formats'}{$fmt}{$eng}{'status'} = $mode;
      $alldata->{'fmtutil'}{$tc}{'changed'} = 1;
      $alldata->{'merged'}{$fmt}{$eng}{'status'} = $mode;
      $alldata->{'merged'}{$fmt}{$eng}{'origin'} = $tc;
      # dump_data();
      return save_fmtutil($tc);
    }
  } else {
    print_error("enable_disable_format_engine: unknown mode $mode\n");
    exit 1;
  }
}  

#
# enable a format named
#   format[/engine]
# where the engine part is optional
# Case 1: no "engine" given:
# - if format is defined and has only one engine instance -> activate
# - if format is defined and has more than one engine -> error
# Case 2: engine given:
# - if format/engine is defined -> activate
# - if format/engine is not defined -> error
#
# Return values:
# 1 - success with changes
# 0 - no changes done
# -1 - error appeared
sub callback_enable_disable_format {
  my ($tc, $fmtname, $mode) = @_;
  my ($fmt, $eng) = split('/', $fmtname, 2);
  if ($mode ne 'enabled' && $mode ne 'disabled') {
    print_error("callback_enable_disable_format: unknown mode $mode.\n");
    exit 1;
  }
  if ($eng) {
    if ($alldata->{'merged'}{$fmt}{$eng}) {
      return enable_disable_format_engine($tc, $fmt, $eng, $mode);
    } else {
      print_warning("Format/engine combination $fmt/$eng is not defined.\n");
      print_warning("Cannot (de)activate it.\n");
      return -1;
    }
  } else {
    # no engine given, check the number of entries
    if ($alldata->{'merged'}{$fmt}) {
      my @engs = keys %{$alldata->{'merged'}{$fmt}};
      if (($#engs > 0) || ($#engs == -1)) {
        print_warning("Selected format $fmt not uniquely defined;\n");
        print_warning("possible format/engine combinations:\n");
        for my $e (@engs) {
          print_warning("  $fmt/$e (currently "
                        . $alldata->{'merged'}{$fmt}{$e}{'status'} . ")\n");
        }
        print_warning("Please select one by fully specifying $fmt/ENGINE\n");
        print_warning("No changes done.\n");
        return 0;
      } else {
        # only one engine, enable it if necessary!
        return enable_disable_format_engine($tc, $fmt, $engs[0], $mode);
      }
    } else {
      print_warning("Format $fmt is not defined;\n");
      print_warning("cannot (de)activate it.\n");
      return -1;
    }
  }
}


sub callback_list_cfg {
  my @lines;
  for my $f (keys %{$alldata->{'merged'}}) {
    for my $e (keys %{$alldata->{'merged'}{$f}}) {
      my $orig = $alldata->{'merged'}{$f}{$e}{'origin'};
      my $hyph = $alldata->{'merged'}{$f}{$e}{'hyphen'};
      my $stat = $alldata->{'merged'}{$f}{$e}{'status'};
      my $args = $alldata->{'merged'}{$f}{$e}{'args'};
      push @lines,
        [ "$f/$e/$hyph",
          "$f (engine=$e) $stat\n  hyphen=$hyph, args=$args\n  origin=$orig\n" ];
    }
  }
  # sort lines
  @lines = map { $_->[1] } sort { $a->[0] cmp $b->[0] } @lines;
  print "List of all formats:\n";
  print @lines;
  
  return @lines == 0; # only return failure if no formats.
}


# sets %alldata.
# 
sub read_fmtutil_files {
  my (@l) = @_;
  for my $l (@l) { read_fmtutil_file($l); }
  # in case the changes_config is a new one read it in and initialize it here
  # the file might be already readable but not in ls-R so not found by
  # kpsewhich. That means we need to check that it is readable and whether
  # the lines entry is already defined
  my $cc = $alldata->{'changes_config'};
  if ((! -r $cc) || (!$alldata->{'fmtutil'}{$cc}{'lines'}) ) {
    $alldata->{'fmtutil'}{$cc}{'lines'} = [ ];
  }
  #
  $alldata->{'order'} = \@l;
  #
  # determine the origin of all formats
  for my $fn (reverse @l) {
    my @format_names = keys %{$alldata->{'fmtutil'}{$fn}{'formats'}};
    for my $f (@format_names) {
      for my $e (keys %{$alldata->{'fmtutil'}{$fn}{'formats'}{$f}}) {
        $alldata->{'merged'}{$f}{$e}{'origin'} = $fn;
        $alldata->{'merged'}{$f}{$e}{'hyphen'} = 
            $alldata->{'fmtutil'}{$fn}{'formats'}{$f}{$e}{'hyphen'} ;
        $alldata->{'merged'}{$f}{$e}{'status'} = 
            $alldata->{'fmtutil'}{$fn}{'formats'}{$f}{$e}{'status'} ;
        $alldata->{'merged'}{$f}{$e}{'args'} = 
            $alldata->{'fmtutil'}{$fn}{'formats'}{$f}{$e}{'args'} ;
      }
    }
  }
}

# 
sub read_fmtutil_file {
  my $fn = shift;
  open(FN, "<$fn") || die "Cannot read $fn: $!";
  #
  # we count lines from 0 ..!!!!?
  my $i = -1;
  my $printline = 0; # but not in error messages
  my @lines = <FN>;
  chomp(@lines);
  $alldata->{'fmtutil'}{$fn}{'lines'} = [ @lines ];
  close(FN) || warn("$prg: Cannot close $fn: $!");
  for (@lines) {
    $i++;
    $printline++;
    chomp;
    my $orig_line = $_;
    next if /^\s*#?\s*$/; # ignore empty and all-blank and just-# lines
    next if /^\s*#[^!]/;  # ignore whole-line comment that is not a disable
    s/#[^!].*//;          # remove within-line comment that is not a disable
    s/#$//;               # remove # at end of line
    my ($a,$b,$c,@rest) = split (' '); # special split rule, leading ws ign
    if (! $b) { # as in: "somefmt"
      print_warning("no engine specified for format $a, ignoring "
                    . "(file $fn, line $printline)\n");
      next;
    }
    if (! $c) { # as in: "somefmt someeng"
      print_warning("no pattern argument specified for $a/$b, ignoring line: "
                    . "$orig_line (file $fn, line $printline)\n");
      next;
    }
    if (@rest == 0) { # as in: "somefmt someeng somepat"
      print_warning("no inifile argument(s) specified for $a/$b, ignoring line: "
                    . "$orig_line (file $fn, line $printline)\n");
      next;
    }
    my $disabled = 0;
    if ($a eq "#!") {
      # we cannot feasibly determine whether a line is a proper fmtline or
      # not, so we have to assume that it is as long as we have four args.
      my $d = shift @rest;
      if (!defined($d)) {
        print_warning("apparently not a real disable line, ignoring: "
                      . "$orig_line (file $fn, line $printline)\n");
        next;
      } else {
        $disabled = 1;
        $a = $b; $b = $c; $c = $d;
      }
    }
    if (defined($alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b})) {
      print_warning("double mention of $a/$b in $fn\n");
    } else {
      $alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b}{'hyphen'} = $c;
      $alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b}{'args'} = "@rest";
      $alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b}{'status'}
        = ($disabled ? 'disabled' : 'enabled');
      $alldata->{'fmtutil'}{$fn}{'formats'}{$a}{$b}{'line'} = $i;
    }
  }
}



# 
# FUNCTIONS THAT SHOULD GO INTO TLUTILS.PM
# and also be reused in updmap.pl!!!


# sets global $alldata->{'changes_config'} to the config file to be
# changed if requested.
#
sub determine_config_files {
  my $fn = shift;

  # config file for changes
  my $changes_config_file;

  # determine which config files should be used
  # we also determine here where changes will be saved to
  if ($opts{'cnffile'}) {
    my @tmp;
    for my $f (@{$opts{'cnffile'}}) {
      if (! -f $f) {
        # if $f is a pure file name, that is dirname $f == ".",
        # then try to find it via kpsewhich
        if (dirname($f) eq ".") {
          chomp(my $kpfile = `kpsewhich $f`);
          if ($kpfile ne "") {
            $f = $kpfile;
          } else {
            die "$prg: Config file \"$f\" cannot be found via kpsewhich";
          }
        } else {
          die "$prg: Config file \"$f\" not found";
        }
      }
      push @tmp, (wndws() ? lc($f) : $f);
    }
    @{$opts{'cnffile'}} = @tmp;
    # in case that config files are given on the command line, the first
    # in the list is the one where changes will be written to.
    ($changes_config_file) = @{$opts{'cnffile'}};
  } else {
    my @all_files = `kpsewhich -all $fn`;
    chomp(@all_files);
    my @used_files;
    for my $f (@all_files) {
      push @used_files, (wndws() ? lc($f) : $f);
    }
    #
    my $TEXMFLOCALVAR;
    my @TEXMFLOCAL;
    if (wndws()) {
      chomp($TEXMFLOCALVAR =`kpsewhich --expand-path=\$TEXMFLOCAL`);
      @TEXMFLOCAL = map { lc } split(/;/ , $TEXMFLOCALVAR);
    } else {
      chomp($TEXMFLOCALVAR =`kpsewhich --expand-path='\$TEXMFLOCAL'`);
      @TEXMFLOCAL = split /:/ , $TEXMFLOCALVAR;
    }
    #
    # search for TEXMFLOCAL/web2c/$fn
    my @tmlused;
    for my $tml (@TEXMFLOCAL) {
      my $TMLabs = Cwd::abs_path($tml);
      next if (!$TMLabs);
      if (-r "$TMLabs/web2c/$fn") {
        push @tmlused, "$TMLabs/web2c/$fn";
      }
    }
    #
    # See help message for list of locations.
    @{$opts{'cnffile'}} = @used_files;
    #
    # determine the config file that we will use for changes
    # if in the list of used files contains either one from
    # TEXMFHOME or TEXMFCONFIG (TEXMFSYSCONFIG in the -sys case)
    # then use the *top* file (which will be either one of the two),
    # if neither of the two exists, create a file in TEXMFCONFIG and use it.
    my $use_top = 0;
    for my $f (@used_files) {
      if ($f =~ m!(\Q$TEXMFHOME\E|\Q$texmfconfig\E)/web2c/$fn!) {
        $use_top = 1;
        last;
      }
    }
    if ($use_top) {
      ($changes_config_file) = @used_files;
    } else {
      # add the empty config file
      my $dn = "$texmfconfig/web2c";
      $changes_config_file = "$dn/$fn";
    }
  }
  if (!$opts{'quiet'}) {
    print_verbose("$prg is using the following $fn files"
                  . " (in precedence order):\n");
    for my $f (@{$opts{'cnffile'}}) {
      print_verbose("  $f\n");
    }
    print_verbose("$prg is using the following $fn file"
                  . " for writing changes:\n");
    print_verbose("  $changes_config_file\n");
  }
  if ($opts{'listfiles'}) {
    # we listed it above, so be done
    exit 0;
  }

  $alldata->{'changes_config'} = $changes_config_file;
}



# returns 1 if actually saved due to changes
sub save_fmtutil {
  my $fn = shift;
  return 0 if $opts{'dry-run'};
  my %fmtf = %{$alldata->{'fmtutil'}{$fn}};
  if ($fmtf{'changed'}) {
    TeXLive::TLUtils::mkdirhier(dirname($fn));
    open (FN, ">$fn") || die "$prg: can't write to $fn: $!";
    my @lines = @{$fmtf{'lines'}};
    if (!@lines) {
      print_verbose ("Creating new config file $fn\n");
      unless ($opts{"nohash"}) {
        # update lsR database
        $updLSR->add($fn);
        $updLSR->exec();
        $updLSR->reset();
      }
    }
    # collect the lines with data
    my %line_to_fmt;
    my @add_fmt;
    if (defined($fmtf{'formats'})) {
      for my $f (keys %{$fmtf{'formats'}}) {
        for my $e (keys %{$fmtf{'formats'}{$f}}) {
          if ($fmtf{'formats'}{$f}{$e}{'line'} == -1) {
            push @add_fmt, [ $f, $e ];
          } else {
            $line_to_fmt{$fmtf{'formats'}{$f}{$e}{'line'}} = [ $f, $e ];
          }
        }
      }
    }
    for my $i (0..$#lines) {
      if (defined($line_to_fmt{$i})) {
        my $f = $line_to_fmt{$i}->[0];
        my $e = $line_to_fmt{$i}->[1];
        my $mode = $fmtf{'formats'}{$f}{$e}{'status'};
        my $args = $fmtf{'formats'}{$f}{$e}{'args'};
        my $hyph = $fmtf{'formats'}{$f}{$e}{'hyphen'};
        my $p = ($mode eq 'disabled' ? "#! " : "");
        print FN "$p$f $e $hyph $args\n";
      } else {
        print FN "$lines[$i]\n";
      }
    }
    # add the new settings and maps
    for my $m (@add_fmt) {
      my $f = $m->[0];
      my $e = $m->[1];
      my $mode = $fmtf{'formats'}{$f}{$e}{'status'};
      my $args = $fmtf{'formats'}{$f}{$e}{'args'};
      my $hyph = $fmtf{'formats'}{$f}{$e}{'hyphen'};
      my $p = ($mode eq 'disabled' ? "#! " : "");
      print FN "$p$f $e $hyph $args\n";
    }
    close(FN) || warn("$prg: Cannot close file handle for $fn: $!");
    delete $alldata->{'fmtutil'}{$fn}{'changed'};
    return 1;
  }
  return 0;
}


#
# $HOME and sudo and updmap-sys horror
#   some instances of sudo do not reset $HOME to the home of root
#   as an effect of "sudo updmap" creates root owned files in the home 
#   of a normal user, and "sudo updmap-sys" uses map files and updmap.cfg
#   files from the directory of a normal user, but creating files
#   in TEXMFSYSCONFIG. This is *all* wrong.
#   we check: if we are running as UID 0 (root) on Unix and the
#   ENV{HOME} is NOT the same as the one of root, then give a warning
#   and reset it to the real home dir of root.

sub reset_root_home {
  if (!wndws() && ($> == 0)) {  # $> is effective uid
    my $envhome = $ENV{'HOME'};
    # if $HOME isn't an existing directory, we don't care.
    if (defined($envhome) && (-d $envhome)) {
      # we want to avoid calling getpwuid as far as possible, so if
      # $envhome is one of some usual values we accept it without worrying.
      if ($envhome =~ m,^(/|/root|/var/root)/*$,) {
        return;
      }
      # $HOME is defined, check what is the home of root in reality
      my (undef,undef,undef,undef,undef,undef,undef,$roothome) = getpwuid(0);
      if (defined($roothome)) {
        if ($envhome ne $roothome) {
          print_warning("resetting \$HOME value (was $envhome) to root's "
            . "actual home ($roothome).\n");
          $ENV{'HOME'} = $roothome;
        } else {
          # envhome and roothome do agree, nothing to do, that is the good case
        }
      } else { 
        print_warning("home of root not defined, strange!\n");
      }
    }
  }
}

# printing to stdout (in mktexfmtMode also going to stderr!)
#   print_info    can be suppressed with --quiet
#   print_verbose cannot be suppressed
# printing to stderr
#   print_warning can be suppressed with --quiet
#   print_error   cannot be suppressed
#
sub print_info {
  if ($mktexfmtMode) {
    print STDERR "$prg [INFO]: ", @_ if (!$opts{'quiet'});
  } else {
    print STDOUT "$prg [INFO]: ", @_ if (!$opts{'quiet'});
  }
}
sub print_verbose {
  if ($mktexfmtMode) {
    print STDERR "$prg: ", @_;
  } else {
    print STDOUT "$prg: ", @_;
  }
}
sub print_warning {
  print STDERR "$prg [WARNING]: ", @_ if (!$opts{'quiet'}) 
}
sub print_error {
  print STDERR "$prg [ERROR]: ", @_;
}
#
# same with deferred
sub print_deferred_info {
  push @deferred_stdout, "$prg [INFO]: @_" if (!$opts{'quiet'});
}
sub print_deferred_verbose {
  push @deferred_stdout, "$prg: @_";
}
sub print_deferred_warning {
  push @deferred_stderr, "$prg [WARNING]: @_" if (!$opts{'quiet'}) 
}
sub print_deferred_error {
  push @deferred_stderr, "$prg [ERROR]: @_";
}



# version, help.

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}

sub help {
  my $usage = <<"EOF";
Usage: $prg      [-user|-sys] [OPTION] ... [COMMAND]
   or: $prg-sys  [OPTION] ... [COMMAND]
   or: $prg-user [OPTION] ... [COMMAND]
   or: mktexfmt  FORMAT.fmt|BASE.base|FMTNAME

Rebuild and manage TeX fmts and Metafont bases, collectively called
"formats" here. (MetaPost no longer uses the past-equivalent "mems".)

If not operating in mktexfmt mode, exactly one command must be given,
filename suffixes should generally not be specified, no non-option
arguments are allowed, and multiple formats can be generated.

If the command name ends in mktexfmt, only one format can be created.
The only options supported are --help and --version, and the command
line must be either a format name, with extension, or a plain name that
is passed as the argument to --byfmt (see below).  The full name of the
generated file (if any) is written to stdout, and nothing else.  The
system directories are used if they are writable, else the user directories.

By default, the return status is zero if all formats requested are
successfully built, else nonzero.

Options:
  --sys                   use TEXMFSYS{VAR,CONFIG}
  --user                  use TEXMF{VAR,CONFIG}
  --cnffile FILE          read FILE instead of fmtutil.cnf
                           (can be given multiple times, in which case
                           all the files are used)
  --dry-run, -n           don't actually build formts
  --fmtdir DIR            write formats under DIR instead of TEXMF[SYS]VAR
  --no-engine-subdir      don't use engine-specific subdir of the fmtdir
  --no-error-if-no-format  exit successfully if no format is selected
  --no-error-if-no-engine=ENGINE1,ENGINE2,...
                          exit successfully even if a required ENGINE
                           is missing, if it is included in the list.
  --no-strict             exit successfully even if a format fails to build
  --nohash                don't update ls-R files
  --recorder              pass the -recorder option and save .fls files
  --refresh               recreate only existing format files
  --status-file FILE      append status information about built formats to FILE
  --quiet                 be silent
  --catcfg                (does nothing, exists for compatibility)
  --dolinks               (does nothing, exists for compatibility)
  --force                 (does nothing, exists for compatibility)
  --test                  (does nothing, exists for compatibility)

Commands:
  --all                   recreate all format files
  --missing               create all missing format files
  --byengine ENGINE       (re)create formats built with ENGINE
  --byfmt FORMAT          (re)create format FORMAT
  --byhyphen HYPHENFILE   (re)create formats that depend on HYPHENFILE
  --enablefmt  FORMAT[/ENGINE]  enable FORMAT, as built with ENGINE
  --disablefmt FORMAT[/ENGINE]  disable FORMAT, as built with ENGINE
                          If multiple formats have the same name and
                           different engines, /ENGINE specifier is required.
  --listcfg               list (enabled and disabled) configurations,
                           filtered to available formats
  --showhyphen FORMAT     print name of hyphen file for FORMAT
  --version               show version information and exit
  --help                  show this message and exit

Explanation of trees and files normally used:

  If --cnffile is specified on the command line (possibly multiple
  times), its value(s) are used.  Otherwise, fmtutil reads all the
  fmtutil.cnf files found by running "kpsewhich -all fmtutil.cnf", in the
  order returned by kpsewhich.  Files specified via --cnffile are
  first tried to be loaded directly, and if not found and the file names
  don't contain directory parts, are searched via kpsewhich.

  In any case, if multiple fmtutil.cnf files are found, all the format
  definitions found in all the fmtutil.cnf files are merged.

  Thus, if fmtutil.cnf files are present in all trees, and the default
  layout is used as shipped with TeX Live, the following files are
  read, in the given order.
  
  For fmtutil-sys:
  TEXMFSYSCONFIG \$TEXLIVE/YYYY/texmf-config/web2c/fmtutil.cnf
  TEXMFSYSVAR    \$TEXLIVE/YYYY/texmf-var/web2c/fmtutil.cnf
  TEXMFLOCAL     \$TEXLIVE/texmf-local/web2c/fmtutil.cnf
  TEXMFDIST      \$TEXLIVE/YYYY/texmf-dist/web2c/fmtutil.cnf

  For fmtutil-user:
  TEXMFCONFIG    \$HOME/.texliveYYYY/texmf-config/web2c/fmtutil.cnf
  TEXMFVAR       \$HOME/.texliveYYYY/texmf-var/web2c/fmtutil.cnf
  TEXMFHOME      \$HOME/texmf/web2c/fmtutil.cnf
  TEXMFSYSCONFIG \$TEXLIVE/YYYY/texmf-config/web2c/fmtutil.cnf
  TEXMFSYSVAR    \$TEXLIVE/YYYY/texmf-var/web2c/fmtutil.cnf
  TEXMFLOCAL     \$TEXLIVE/texmf-local/web2c/fmtutil.cnf
  TEXMFDIST      \$TEXLIVE/YYYY/texmf-dist/web2c/fmtutil.cnf
  
  (where YYYY is the TeX Live release version).
  
  According to the actions, fmtutil might update one of the existing cnf
  files or create a new fmtutil.cnf, as described below.

Where format files are written:

  By default, format files are (re)written in \$TEXMFSYSVAR/ENGINE by
  fmtutil-sys, and \$TEXMFVAR/ENGINE by fmtutil-user, where /ENGINE is
  a subdirectory named for the engine used, such as "pdftex".

  For mktexfmt, TEXMFSYSVAR is used if it is writable, else TEXMFVAR.
  
  If the --fmtdir=DIR option is specified, DIR is used instead of
  TEXMF[SYS]VAR, but the /ENGINE subdir is still used by default.
  
  In all cases, if the --no-engine-subdir option is specified, the
  /ENGINE subdir is omitted.
  
Where configuration changes are saved: 

  If config files are given on the command line, then the first one 
  given will be used to save any changes from --enable or --disable.  
  
  If the config files are taken from kpsewhich output, then the 
  algorithm is more complicated:

    1) If \$TEXMFCONFIG/web2c/fmtutil.cnf or
    \$TEXMFHOME/web2c/fmtutil.cnf appears in the list of used files,
    then the one listed first by kpsewhich --all (equivalently, the one
    returned by "kpsewhich fmtutil.cnf"), is used.
      
    2) If neither of the above two are present and changes are made, a
    new config file is created in \$TEXMFCONFIG/web2c/fmtutil.cnf.
  
  In general, the idea is that if a given config file is not writable, a
  higher-level one can be used.  That way, the distribution's settings
  can be overridden system-wide using TEXMFLOCAL, and system settings
  can be overridden again in a particular user's TEXMFHOME or TEXMFCONF.

Resolving multiple definitions of a format:

  If a format is defined in more than one config file, then the definition
  coming from the first-listed fmtutil.cnf is used.

Disabling formats:

  fmtutil.cnf files with higher priority (listed earlier) can disable
  formats in lower priority (listed later) fmtutil.cnf files by
  writing a line like this in the higher-priority fmtutil.cnf file:
    \#! <fmtname> <enginename> <hyphen> <args>
  The \#! must be at the beginning of the line, with at least one space
  or tab afterward, and there must be whitespace between each word on
  the list.

  For example, you can disable the luajitlatex format by creating
  the file \$TEXMFCONFIG/web2c/fmtutil.cnf with the line
    #! luajitlatex luajittex language.dat,language.dat.lua lualatex.ini
  (As it happens, the luajittex-related formats are precisely why the
  --no-error-if-no-engine option exists, since luajittex cannot be
  compiled on all platforms. So this is not needed.)

fmtutil-user (fmtutil -user) vs. fmtutil-sys (fmtutil -sys):

  When fmtutil-sys is run or the command line option -sys is used,
  TEXMFSYSCONFIG and TEXMFSYSVAR are used instead of TEXMFCONFIG and
  TEXMFVAR, respectively. This is the primary difference between
  fmtutil-sys and fmtutil-user.

  See https://tug.org/texlive/scripts-sys-user.html for details.

  Other locations may be used if you give them on the command line, or
  these trees don't exist, or you are not using the original TeX Live.

Supporting development binaries:

  If an engine name ends with "-dev", formats are created in
  the respective directory with the -dev stripped.  This allows for
  easily running development binaries in parallel with the released
  binaries.

Report bugs to: tex-live\@tug.org
TeX Live home page: <https://tug.org/texlive/>
EOF
;
  print &version();
  print $usage;
  exit 0; # no final print_info
}

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
