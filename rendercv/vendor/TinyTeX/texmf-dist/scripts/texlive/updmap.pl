#!/usr/bin/env perl
# $Id: updmap.pl 65932 2023-02-19 20:49:48Z siepo $
# updmap - maintain map files for outline fonts.
# (Maintained in TeX Live:Master/texmf-dist/scripts/texlive.)
# 
# Copyright 2011-2022 Norbert Preining
# This file is licensed under the GNU General Public License version 2
# or any later version.
#
# History:
# Original shell script (C) 2002 Thomas Esser, released to the public domain.
# first perl variant by Fabrice Popineau
# later adaptions by Reinhard Kotucha, and Karl Berry.
# The current implementation is a complete rewrite.

my $svnid = '$Id: updmap.pl 65932 2023-02-19 20:49:48Z siepo $';

my $TEXMFROOT;
BEGIN {
  $^W = 1;
  $TEXMFROOT = `kpsewhich -var-value=TEXMFROOT`;
  if ($?) {
    die "$0: kpsewhich -var-value=TEXMFROOT failed, aborting early.\n";
  }
  chomp($TEXMFROOT);
  unshift(@INC, "$TEXMFROOT/tlpkg");
}

my $lastchdate = '$Date: 2023-02-19 21:49:48 +0100 (Sun, 19 Feb 2023) $';
$lastchdate =~ s/^\$Date:\s*//;
$lastchdate =~ s/ \(.*$//;
my $svnrev = '$Revision: 65932 $';
$svnrev =~ s/^\$Revision:\s*//;
$svnrev =~ s/\s*\$$//;
my $version = "r$svnrev ($lastchdate)";

use Getopt::Long qw(:config no_autoabbrev ignore_case_always);
use strict;
use TeXLive::TLUtils qw(mkdirhier mktexupd wndws basename dirname 
  sort_uniq member touch);

(my $prg = basename($0)) =~ s/\.pl$//;

# sudo sometimes does not reset the home dir of root;
# see more comments at the definition of this function.
reset_root_home();

chomp(my $TEXMFDIST = `kpsewhich --var-value=TEXMFDIST`);
chomp(my $TEXMFVAR = `kpsewhich -var-value=TEXMFVAR`);
chomp(my $TEXMFSYSVAR = `kpsewhich -var-value=TEXMFSYSVAR`);
chomp(my $TEXMFCONFIG = `kpsewhich -var-value=TEXMFCONFIG`);
chomp(my $TEXMFSYSCONFIG = `kpsewhich -var-value=TEXMFSYSCONFIG`);
chomp(my $TEXMFHOME = `kpsewhich -var-value=TEXMFHOME`);

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

my $texmfconfig = $TEXMFCONFIG;
my $texmfvar    = $TEXMFVAR;

my %opts = ( quiet => 0, nohash => 0, nomkmap => 0 );
my $alldata;
my $updLSR;

my @cmdline_options = (
  "sys",
  "user",
  "listfiles",
  "cnffile=s@", 
  "copy", 
  "disable=s@",
  "dvipdfmoutputdir=s",
  "dvipdfmxoutputdir=s",
  "dvipsoutputdir=s",
  # the following does not work, Getopt::Long looses the first
  # entry in a multi setting, treat it separately in processOptions
  # furthermore, it is not supported by older perls, so do it differently
  #"enable=s{1,2}",
  "edit",
  "force",
  "listavailablemaps",
  "listmaps|l",
  "nohash",
  "nomkmap",
  "dry-run|n",
  "outputdir=s",
  "pdftexoutputdir=s",
  "pxdvioutputdir=s",
  "quiet|silent|q",
  # the following is a correct specification of an option according
  # to the manual, but it does not work!
  # we will treat that option by itself in processOptions
  # furthermore, it is not supported by older perls, so do it differently
  #"setoption=s@{1,2}",
  "showoptions=s@",
  "showoption=s@",
  "syncwithtrees",
  "version",
  "help|h",
  # some debugging invocations
  "_readsave=s",
  "_dump",
  );

my %settings = (
  dvipsPreferOutline    => {
    type     => "binary",
    default  => "true",
  },
  LW35                  => {
    type     => "string",
    possible => [ qw/URW URWkb ADOBE ADOBEkb/ ],
    default  => "URWkb",
  },
  dvipsDownloadBase35   => {
    type     => "binary",
    default  => "true",
  },
  pdftexDownloadBase14  => {
    type     => "binary",
    default  => "true",
  },
  dvipdfmDownloadBase14 => {
    type     => "binary",
    default  => "true",
  },
  pxdviUse              => {
    type     => "binary",
    default  => "false",
  },
  jaEmbed               => {
    type     => "any",
    default  => "noEmbed",
  },
  jaVariant             => {
    type     => "any",
    default  => "",
  },
  scEmbed            => {
    type     => "any",
    default  => "noEmbed",
  },
  tcEmbed            => {
    type     => "any",
    default  => "noEmbed",
  },
  koEmbed            => {
    type     => "any",
    default  => "noEmbed",
  },
);

&main();

##################################################################
#
sub main {
  processOptions();

  help() if $opts{'help'};

  if ($opts{'version'}) {
    print version();
    exit (0);
  }

  ($texmfconfig, $texmfvar) = 
    TeXLive::TLUtils::setup_sys_user_mode($prg, \%opts,
      $TEXMFCONFIG, $TEXMFSYSCONFIG, $TEXMFVAR, $TEXMFSYSVAR);

  if ($opts{'dvipdfmoutputdir'} && !defined($opts{'dvipdfmxoutputdir'})) {
    $opts{'dvipdfmxoutputdir'} = $opts{'dvipdfmoutputdir'};
    print_warning("Using --dvipdfmoutputdir options for dvipdfmx,"
                  . " but please use --dvipdfmxoutputdir\n");
  }

  if ($opts{'dvipdfmoutputdir'} && $opts{'dvipdfmxoutputdir'}
      && $opts{'dvipdfmoutputdir'} ne $opts{'dvipdfmxoutputdir'}) {
    print_error("Options for --dvipdfmoutputdir and --dvipdfmxoutputdir"
                . " do not match\n"
                . "Please use only --dvipdfmxoutputdir; exiting.\n");
    exit(1);
  }

  if ($opts{'_readsave'}) {
    read_updmap_files($opts{'_readsave'});
    merge_settings_replace_kanji();
    print "READING DONE ============================\n";
    $alldata->{'updmap'}{$opts{'_readsave'}}{'changed'} = 1;
    save_updmap($opts{'_readsave'});
    exit 0;
  }
 
  if ($opts{'showoptions'}) {
    for my $o (@{$opts{'showoptions'}}) {
      if (defined($settings{$o})) {
        if ($settings{$o}{'type'} eq "binary") {
          print "true false\n";
        } elsif ($settings{$o}{'type'} eq "string") {
          print "@{$settings{$o}{'possible'}}\n";
        } elsif ($settings{$o}{'type'} eq "any") {
          print "(any string)\n";
        } else {
          print_warning("strange: unknown type of option $o\nplease report\n");
        }
      } else {
        print_warning("unknown option: $o\n");
      }
    }
    exit 0;
  }

  # config file for changes
  my $changes_config_file;

  # determine which config files should be used
  # replaces the former "setupCfgFile"
  #
  # we also determine here where changes will be saved to
  if ($opts{'cnffile'}) {
    my @tmp;
    for my $f (@{$opts{'cnffile'}}) {
      if (! -f $f) {
        die "$prg: Config file \"$f\" not found.";
      }
      push @tmp, (wndws() ? lc($f) : $f);
    }
    @{$opts{'cnffile'}} = @tmp;
    # in case that config files are given on the command line, the first
    # in the list is the one where changes will be written to.
    ($changes_config_file) = @{$opts{'cnffile'}};
  } else {
    my @all_files = `kpsewhich -all updmap.cfg`;
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
    # search for TEXMFLOCAL/web2c/updmap.cfg
    my @tmlused;
    for my $tml (@TEXMFLOCAL) {
      my $TMLabs = Cwd::abs_path($tml);
      next if (!$TMLabs);
      if (-r "$TMLabs/web2c/updmap.cfg") {
        push @tmlused, "$TMLabs/web2c/updmap.cfg";
      }
      #
      # at least check for old updmap-local.cfg and warn!
      if (-r "$TMLabs/web2c/updmap-local.cfg") {
        print_warning("=============================\n");
        print_warning("Old configuration file\n  $TMLabs/web2c/updmap-local.cfg\n");
        print_warning("found! This file is *not* evaluated anymore, please move the information\n");
        print_warning("to the file $TMLabs/updmap.cfg!\n");
        print_warning("=============================\n");
      }
    }
    #
    # updmap (user):
    # ==============
    # TEXMFCONFIG    $HOME/.texliveYYYY/texmf-config/web2c/updmap.cfg
    # TEXMFVAR       $HOME/.texliveYYYY/texmf-var/web2c/updmap.cfg
    # TEXMFHOME      $HOME/texmf/web2c/updmap.cfg
    # TEXMFSYSCONFIG $TEXLIVE/YYYY/texmf-config/web2c/updmap.cfg
    # TEXMFSYSVAR    $TEXLIVE/YYYY/texmf-var/web2c/updmap.cfg
    # TEXMFLOCAL     $TEXLIVE/texmf-local/web2c/updmap.cfg
    # TEXMFDIST      $TEXLIVE/YYYY/texmf-dist/web2c/updmap.cfg
    # 
    # updmap-sys (root):
    # ==================
    # TEXMFSYSCONFIG $TEXLIVE/YYYY/texmf-config/web2c/updmap.cfg
    # TEXMFSYSVAR    $TEXLIVE/YYYY/texmf-var/web2c/updmap.cfg
    # TEXMFLOCAL     $TEXLIVE/texmf-local/web2c/updmap.cfg
    # TEXMFDIST      $TEXLIVE/YYYY/texmf-dist/web2c/updmap.cfg
    #
    @{$opts{'cnffile'}} = @used_files;
    #
    # Determine the config file that we will use for changes:
    # if the list of used files contains one from either
    # TEXMFHOME or TEXMFCONFIG (which is TEXMFSYSCONFIG in the -sys case)
    # then use the *top* file (which will be one of the two *CONFIG);
    # if neither of those two exists, create a file in TEXMFCONFIG and use it.
    my $use_top = 0;
    for my $f (@used_files) {
      if ($f =~ m!(\Q$TEXMFHOME\E|\Q$texmfconfig\E)/web2c/updmap.cfg!) {
        $use_top = 1;
        last;
      }
    }
    if ($use_top) {
      ($changes_config_file) = @used_files;
    } else {
      # add the empty config file
      my $dn = "$texmfconfig/web2c";
      $changes_config_file = "$dn/updmap.cfg";
    }
  }
  if (!$opts{'quiet'}) {
    print "$prg will read the following updmap.cfg files (in precedence order):\n";
    for my $f (@{$opts{'cnffile'}}) {
      print "  $f\n";
    }
    print "$prg may write changes to the following updmap.cfg file:\n";
    print "  $changes_config_file\n";
  }
  if ($opts{'listfiles'}) {
    # we listed it above, so be done
    exit 0;
  }

  $alldata->{'changes_config'} = $changes_config_file;

  read_updmap_files(@{$opts{'cnffile'}});

  if ($opts{'_dump'}) {
    merge_settings_replace_kanji();
    read_map_files();
    require Data::Dumper;
    # two times to silence perl warnings!
    $Data::Dumper::Indent = 1;
    $Data::Dumper::Indent = 1;
    print "READING DONE ============================\n";
    print Data::Dumper::Dumper($alldata);
    exit 0;
  }

  if ($opts{'showoption'}) {
    merge_settings_replace_kanji();
    for my $o (@{$opts{'showoption'}}) {
      if (defined($settings{$o})) {
        my ($v, $vo) = get_cfg($o);
        $v = "\"$v\"" if ($v =~ m/\s/);
        print "$o=$v ($vo)\n";
      } else {
        print_warning("unknown option: $o\n");
      }
    }
    exit 0;
  }

  if ($opts{'listmaps'} || $opts{'listavailablemaps'}) {
    merge_settings_replace_kanji();
    # only check for missing map files 
    # (pass in true argument to read_map_files)
    my %missing = map { $_ => 1 } read_map_files(1);
    for my $m (sort keys %{$alldata->{'maps'}}) {
      next if ($missing{$m} && $opts{'listavailablemaps'});
      my $origin = $alldata->{'maps'}{$m}{'origin'};
      my $type = ($origin eq 'builtin' ? 'Map' :
        $alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'});
      my $status = ($origin eq 'builtin' ? 'enabled' :
        $alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'});
      my $avail = ($missing{$m} ? "\t(not available)" : '');
      print "$type\t$m\t$status\t$origin$avail\n";
      #print $alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'}, " $m ",
      #$alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'}, " in $origin\n";
    }
    exit 0;
  }

  # we do changes always in the used config file with the highest
  # priority
  my $bakFile = $changes_config_file;
  $bakFile =~ s/\.cfg$/.bak/;
  my $changed = 0;

  $updLSR = &mktexupd();
  $updLSR->{mustexist}(0);

  if ($opts{'syncwithtrees'}) {
    merge_settings_replace_kanji();
    my @missing = read_map_files();
    if (@missing) {
      print "Missing map files found, disabling\n";
      for my $m (@missing) {
        my $orig = $alldata->{'maps'}{$m}{'origin'};
        print "\t$m (in $orig)\n";
      }
      print "in $changes_config_file\n";
      print "Do you really want to continue (y/N)? ";
      my $answer = <STDIN>;
      $answer = "n" if !defined($answer);
      chomp($answer);
      print "answer =$answer=\n";
      if ($answer ne "y" && $answer ne "Y") {
        print "Please fix manually before running updmap(-sys) again!\n";
        exit 0;
      }
      $changed ||= enable_disable_maps(@missing);
      print "$0 --syncwithtrees finished.\n";
      print "Now you need to run $prg normally to recreate map files.\n"
    }
    exit 0;
  }

  my $cmd;
  if ($opts{'edit'}) {
    if ($opts{"dry-run"}) {
      print_error("No, are you joking, you want to edit with --dry-run?\n");
      exit 1;
    }
    # it's not a good idea to edit updmap.cfg manually these days,
    # but for compatibility we'll silently keep the option.
    $cmd = 'edit';
    my $editor = $ENV{'VISUAL'} || $ENV{'EDITOR'};
    $editor ||= (wndws() ? "notepad" : "vi");
    if (-r $changes_config_file) {
      &copyFile($changes_config_file, $bakFile);
    } else {
      touch($bakFile);
      touch($changes_config_file);
    }
    system($editor, $changes_config_file);
    $changed = files_are_different($bakFile, $changes_config_file);
  } elsif ($opts{'setoption'}) {
    $cmd = 'setOption';
    $changed = setOptions (@{$opts{'setoption'}});
  } elsif ($opts{'enable'} || $opts{'disable'}) {
    $cmd = 'enableMap';
    $changed ||= enable_disable_maps(@{$opts{'enable'}}, @{$opts{'disable'}});
  }


  if ($cmd && !$opts{'force'} && !$changed) {
    print "$changes_config_file unchanged.  Map files not recreated.\n" 
      if !$opts{'quiet'};
  } else {
    if (!$opts{'nomkmap'}) {
      # before we continue we have to make sure that a newly created config
      # file is acually used. So we have to push the $changes_config_file
      # onto the list of available files. Since it is already properly
      # initialized and the merging is done later,  all settings should be
      # honored
      my @aaa = @{$alldata->{'order'}};
      unshift @aaa, $changes_config_file;
      $alldata->{'order'} = [ @aaa ];
      #
      setupOutputDir("dvips");
      setupOutputDir("pdftex");
      setupOutputDir("dvipdfmx");
      # do pxdvi below, in mkmaps.
      merge_settings_replace_kanji();
      my @missing = read_map_files();
      if (@missing) {
        print_error("The following map file(s) couldn't be found:\n"); 
        for my $m (@missing) {
          my $orig = $alldata->{'maps'}{$m}{'origin'};
          print_error("\t$m (in $orig)\n");
        }
        print_error("Did you run mktexlsr?\n\n" .
          "\tYou can disable non-existent map entries using the option\n".
          "\t  --syncwithtrees.\n\n");
        exit 1;
      }
      merge_data();
      # for inspecting the output
      #print STDERR Data::Dumper->Dump([$alldata], [qw(mapdata)]);
      #print Dumper($alldata);
      mkMaps();
    }
    unlink ($bakFile) if (-r $bakFile);
  }

  if (!$opts{'nohash'}) {
    my $not = $opts{"dry-run"} ? " not (-n)" : "";
    print "$prg:$not updating ls-R files.\n" if !$opts{'quiet'};
    $updLSR->{exec}() unless $opts{"dry-run"};
  }

  return 0;
}

##################################################################
#
sub getFonts {
  my ($first, @rest) = @_;
  my $getall = 0;
  my @maps = ();
  return if !defined($first);
  if ($first eq "-all") {
    $getall = 1;
    @maps = @rest;
  } else {
    @maps = ($first, @rest);
  }
  my @lines = ();
  for my $m (@maps) {
    if (defined($alldata->{'maps'}{$m})) {
      print LOG "\n" . $alldata->{'maps'}{$m}{'fullpath'} . ":\n" unless $opts{'dry-run'};
      push @lines, "% $m";
      for my $k (sort keys %{$alldata->{'maps'}{$m}{'fonts'}}) {
        if ($getall || $alldata->{'fonts'}{$k}{'origin'} eq $m) {
          if (defined($alldata->{'maps'}{$m}{'fonts'}{$k})) {
            push @lines, "$k " . $alldata->{'maps'}{$m}{'fonts'}{$k};
          } else {
            print_warning("undefined fonts for $k in $m   ?!?!?\n");
          }
          print LOG "$k\n" unless $opts{'dry-run'};
        }
      }
    }
  }
  chomp @lines;
  return @lines;
}

###############################################################################
# writeLines()
#   write the lines in $filename
#
sub writeLines {
  my ($fname, @lines) = @_;
  return if $opts{"dry-run"};
  map { ($_ !~ m/\n$/ ? s/$/\n/ : $_ ) } @lines;
  open FILE, ">$fname" or die "$prg: can't write lines to $fname: $!";
  print FILE @lines;
  close FILE;
}

###############################################################################
# to_pdftex()
#   if $pdftexStripEnc is set, strip "PS_Encoding_Name ReEncodeFont"
#   from map entries; they are ignored by pdftex.  But since the sh
#   incarnation of updmap included them, and we want to minimize
#   differences, this is not done by default.
#
sub to_pdftex {
  my $pdftexStripEnc = 0;
  return @_ unless $pdftexStripEnc;
  my @in = @_;
  my @out;
  foreach my $line (@in) {
    if ($line =~ /^(.*\s+)(\S+\s+ReEncodeFont\s)(.*)/) {
      $line = "$1$3";
      $line =~ s/\s+\"\s+\"\s+/ /;
    }
    push @out, $line;
  }
  return @out;
}

###############################################################################
# setupSymlinks()
#   set symlink for psfonts.map according to dvipsPreferOutline variable
#
sub setupSymlinks {
  my ($dvipsPreferOutline, $dvipsoutputdir, $pdftexDownloadBase14, $pdftexoutputdir) = @_;
  my $src;
  my %link;
  my @link;

  if ($dvipsPreferOutline eq "true") {
    $src = "psfonts_t1.map";
  } else {
    $src = "psfonts_pk.map";
  }
  unlink "$dvipsoutputdir/psfonts.map" unless $opts{"dry-run"};
  push @link, &SymlinkOrCopy("$dvipsoutputdir", "$src", "psfonts.map");

  if ($pdftexDownloadBase14 eq "true") {
    $src = "pdftex_dl14.map";
  } else {
    $src = "pdftex_ndl14.map";
  }
  unlink "$pdftexoutputdir/pdftex.map" unless $opts{"dry-run"};
  push @link, &SymlinkOrCopy("$pdftexoutputdir", "$src", "pdftex.map");
  %link = @link;
  return \%link;
}

###############################################################################
# SymlinkOrCopy(dir, src, dest)
#   create symlinks if possible, otherwise copy files
#
sub SymlinkOrCopy {
  my ($dir, $src, $dest) = @_;
  return ($src, $dest) if $opts{"dry-run"};
  if (wndws() || $opts{'copy'}) {  # always copy
    &copyFile("$dir/$src", "$dir/$dest");
  } else { # symlink if supported by fs, copy otherwise
    system("cd \"$dir\" && ln -s $src $dest 2>/dev/null || "
           . "cp -p \"$dir/$src\" \"$dir/$dest\"");
  }
  # remember for "Files generated" in &mkMaps.
  return ($dest, $src);
}


###############################################################################
# transLW35(mode args ...)
#   transform fontname and filenames according to transformation specified
#   by mode.  Possible values:
#      URW|URWkb|ADOBE|ADOBEkb
#
sub transLW35 {
  my ($mode, @lines) = @_;

  my @psADOBE = (
       's/ URWGothicL-Demi / AvantGarde-Demi /',
       's/ URWGothicL-DemiObli / AvantGarde-DemiOblique /',
       's/ URWGothicL-Book / AvantGarde-Book /',
       's/ URWGothicL-BookObli / AvantGarde-BookOblique /',
       's/ URWBookmanL-DemiBold / Bookman-Demi /',
       's/ URWBookmanL-DemiBoldItal / Bookman-DemiItalic /',
       's/ URWBookmanL-Ligh / Bookman-Light /',
       's/ URWBookmanL-LighItal / Bookman-LightItalic /',
       's/ NimbusMonL-Bold / Courier-Bold /',
       's/ NimbusMonL-BoldObli / Courier-BoldOblique /',
       's/ NimbusMonL-Regu / Courier /',
       's/ NimbusMonL-ReguObli / Courier-Oblique /',
       's/ NimbusSanL-Bold / Helvetica-Bold /',
       's/ NimbusSanL-BoldCond / Helvetica-Narrow-Bold /',
       's/ NimbusSanL-BoldItal / Helvetica-BoldOblique /',
       's/ NimbusSanL-BoldCondItal / Helvetica-Narrow-BoldOblique /',
       's/ NimbusSanL-Regu / Helvetica /',
       's/ NimbusSanL-ReguCond / Helvetica-Narrow /',
       's/ NimbusSanL-ReguItal / Helvetica-Oblique /',
       's/ NimbusSanL-ReguCondItal / Helvetica-Narrow-Oblique /',
       's/ CenturySchL-Bold / NewCenturySchlbk-Bold /',
       's/ CenturySchL-BoldItal / NewCenturySchlbk-BoldItalic /',
       's/ CenturySchL-Roma / NewCenturySchlbk-Roman /',
       's/ CenturySchL-Ital / NewCenturySchlbk-Italic /',
       's/ URWPalladioL-Bold / Palatino-Bold /',
       's/ URWPalladioL-BoldItal / Palatino-BoldItalic /',
       's/ URWPalladioL-Roma / Palatino-Roman /',
       's/ URWPalladioL-Ital / Palatino-Italic /',
       's/ StandardSymL / Symbol /',
       's/ NimbusRomNo9L-Medi / Times-Bold /',
       's/ NimbusRomNo9L-MediItal / Times-BoldItalic /',
       's/ NimbusRomNo9L-Regu / Times-Roman /',
       's/ NimbusRomNo9L-ReguItal / Times-Italic /',
       's/ URWChanceryL-MediItal / ZapfChancery-MediumItalic /',
       's/ Dingbats / ZapfDingbats /',
    );

  my @fileADOBEkb = (
        's/\buagd8a.pfb\b/pagd8a.pfb/',
        's/\buagdo8a.pfb\b/pagdo8a.pfb/',
        's/\buagk8a.pfb\b/pagk8a.pfb/',
        's/\buagko8a.pfb\b/pagko8a.pfb/',
        's/\bubkd8a.pfb\b/pbkd8a.pfb/',
        's/\bubkdi8a.pfb\b/pbkdi8a.pfb/',
        's/\bubkl8a.pfb\b/pbkl8a.pfb/',
        's/\bubkli8a.pfb\b/pbkli8a.pfb/',
        's/\bucrb8a.pfb\b/pcrb8a.pfb/',
        's/\bucrbo8a.pfb\b/pcrbo8a.pfb/',
        's/\bucrr8a.pfb\b/pcrr8a.pfb/',
        's/\bucrro8a.pfb\b/pcrro8a.pfb/',
        's/\buhvb8a.pfb\b/phvb8a.pfb/',
        's/\buhvb8ac.pfb\b/phvb8an.pfb/',
        's/\buhvbo8a.pfb\b/phvbo8a.pfb/',
        's/\buhvbo8ac.pfb\b/phvbo8an.pfb/',
        's/\buhvr8a.pfb\b/phvr8a.pfb/',
        's/\buhvr8ac.pfb\b/phvr8an.pfb/',
        's/\buhvro8a.pfb\b/phvro8a.pfb/',
        's/\buhvro8ac.pfb\b/phvro8an.pfb/',
        's/\buncb8a.pfb\b/pncb8a.pfb/',
        's/\buncbi8a.pfb\b/pncbi8a.pfb/',
        's/\buncr8a.pfb\b/pncr8a.pfb/',
        's/\buncri8a.pfb\b/pncri8a.pfb/',
        's/\buplb8a.pfb\b/pplb8a.pfb/',
        's/\buplbi8a.pfb\b/pplbi8a.pfb/',
        's/\buplr8a.pfb\b/pplr8a.pfb/',
        's/\buplri8a.pfb\b/pplri8a.pfb/',
        's/\busyr.pfb\b/psyr.pfb/',
        's/\butmb8a.pfb\b/ptmb8a.pfb/',
        's/\butmbi8a.pfb\b/ptmbi8a.pfb/',
        's/\butmr8a.pfb\b/ptmr8a.pfb/',
        's/\butmri8a.pfb\b/ptmri8a.pfb/',
        's/\buzcmi8a.pfb\b/pzcmi8a.pfb/',
        's/\buzdr.pfb\b/pzdr.pfb/',
      );

  my @fileURW = (
        's/\buagd8a.pfb\b/a010015l.pfb/',
  's/\buagdo8a.pfb\b/a010035l.pfb/',
  's/\buagk8a.pfb\b/a010013l.pfb/',
  's/\buagko8a.pfb\b/a010033l.pfb/',
  's/\bubkd8a.pfb\b/b018015l.pfb/',
  's/\bubkdi8a.pfb\b/b018035l.pfb/',
  's/\bubkl8a.pfb\b/b018012l.pfb/',
  's/\bubkli8a.pfb\b/b018032l.pfb/',
  's/\bucrb8a.pfb\b/n022004l.pfb/',
  's/\bucrbo8a.pfb\b/n022024l.pfb/',
  's/\bucrr8a.pfb\b/n022003l.pfb/',
  's/\bucrro8a.pfb\b/n022023l.pfb/',
  's/\buhvb8a.pfb\b/n019004l.pfb/',
  's/\buhvb8ac.pfb\b/n019044l.pfb/',
  's/\buhvbo8a.pfb\b/n019024l.pfb/',
  's/\buhvbo8ac.pfb\b/n019064l.pfb/',
  's/\buhvr8a.pfb\b/n019003l.pfb/',
  's/\buhvr8ac.pfb\b/n019043l.pfb/',
  's/\buhvro8a.pfb\b/n019023l.pfb/',
  's/\buhvro8ac.pfb\b/n019063l.pfb/',
  's/\buncb8a.pfb\b/c059016l.pfb/',
  's/\buncbi8a.pfb\b/c059036l.pfb/',
  's/\buncr8a.pfb\b/c059013l.pfb/',
  's/\buncri8a.pfb\b/c059033l.pfb/',
  's/\buplb8a.pfb\b/p052004l.pfb/',
  's/\buplbi8a.pfb\b/p052024l.pfb/',
  's/\buplr8a.pfb\b/p052003l.pfb/',
  's/\buplri8a.pfb\b/p052023l.pfb/',
  's/\busyr.pfb\b/s050000l.pfb/',
  's/\butmb8a.pfb\b/n021004l.pfb/',
  's/\butmbi8a.pfb\b/n021024l.pfb/',
  's/\butmr8a.pfb\b/n021003l.pfb/',
  's/\butmri8a.pfb\b/n021023l.pfb/',
  's/\buzcmi8a.pfb\b/z003034l.pfb/',
  's/\buzdr.pfb\b/d050000l.pfb/',
       );

  my @fileADOBE = (
  's/\buagd8a.pfb\b/agd_____.pfb/',
  's/\buagdo8a.pfb\b/agdo____.pfb/',
  's/\buagk8a.pfb\b/agw_____.pfb/',
  's/\buagko8a.pfb\b/agwo____.pfb/',
  's/\bubkd8a.pfb\b/bkd_____.pfb/',
  's/\bubkdi8a.pfb\b/bkdi____.pfb/',
  's/\bubkl8a.pfb\b/bkl_____.pfb/',
  's/\bubkli8a.pfb\b/bkli____.pfb/',
  's/\bucrb8a.pfb\b/cob_____.pfb/',
  's/\bucrbo8a.pfb\b/cobo____.pfb/',
  's/\bucrr8a.pfb\b/com_____.pfb/',
  's/\bucrro8a.pfb\b/coo_____.pfb/',
  's/\buhvb8a.pfb\b/hvb_____.pfb/',
  's/\buhvb8ac.pfb\b/hvnb____.pfb/',
  's/\buhvbo8a.pfb\b/hvbo____.pfb/',
  's/\buhvbo8ac.pfb\b/hvnbo___.pfb/',
  's/\buhvr8a.pfb\b/hv______.pfb/',
  's/\buhvr8ac.pfb\b/hvn_____.pfb/',
  's/\buhvro8a.pfb\b/hvo_____.pfb/',
  's/\buhvro8ac.pfb\b/hvno____.pfb/',
  's/\buncb8a.pfb\b/ncb_____.pfb/',
  's/\buncbi8a.pfb\b/ncbi____.pfb/',
  's/\buncr8a.pfb\b/ncr_____.pfb/',
  's/\buncri8a.pfb\b/nci_____.pfb/',
  's/\buplb8a.pfb\b/pob_____.pfb/',
  's/\buplbi8a.pfb\b/pobi____.pfb/',
  's/\buplr8a.pfb\b/por_____.pfb/',
  's/\buplri8a.pfb\b/poi_____.pfb/',
  's/\busyr.pfb\b/sy______.pfb/',
  's/\butmb8a.pfb\b/tib_____.pfb/',
  's/\butmbi8a.pfb\b/tibi____.pfb/',
  's/\butmr8a.pfb\b/tir_____.pfb/',
  's/\butmri8a.pfb\b/tii_____.pfb/',
  's/\buzcmi8a.pfb\b/zcmi____.pfb/',
  's/\buzdr.pfb\b/zd______.pfb/',
    );

  if ($mode eq "" || $mode eq "URWkb") {
    # do nothing
  } elsif ($mode eq "URW") {
    for my $r (@fileURW) {
      map { eval($r); } @lines;
    }
  } elsif ($mode eq "ADOBE" || $mode eq "ADOBEkb") {
    for my $r (@psADOBE) {
      map { eval($r); } @lines;
    }
    my @filemode = eval ("\@file" . $mode);
    for my $r (@filemode) {
      map { eval($r); } @lines;
    }
  }
  return @lines;
}

###############################################################################
# cidx2dvips()
#   reads from stdin, writes to stdout. It transforms "cid-x"-like syntax into
#   "dvips"-like syntax.
#
# Specifying the PS Name:
# dvips needs the PSname instead of the file name. Thus we allow specifying
# the PSname in the comment:
#       The PS Name can be specified in the font definition line
#       by including the following sequence somewhere after the
#       other components:
#
#       %!PS<SPACE-TAB><PSNAME><NON-WORD-CHAR-OR-EOL>
#
#       where
#         <SPACE-TAB> is either a space or a tab character
#         <PSNAME>    is *one* word, defined by \w\w* perl re
#         <NON-WORD-CHAR-OR-EOL> is a non-\w char or the end of line
#
# That means we could have
#       ... %here the PS font name: %!PS fontname some other comment
#       ... %!PS fontname %other comments
#       ... %!PS fontname
#
# reimplementation of the cryptic code that was there before
sub cidx2dvips {
  my ($s) = @_;
  my %fname_psname = (
    # Morisawa
    'A-OTF-FutoGoB101Pr6N-Bold'  => 'FutoGoB101Pr6N-Bold',
    'A-OTF-FutoGoB101Pro-Bold'   => 'FutoGoB101Pro-Bold',
    'A-OTF-FutoMinA101Pr6N-Bold' => 'FutoMinA101Pr6N-Bold',
    'A-OTF-FutoMinA101Pro-Bold'  => 'FutoMinA101Pro-Bold',
    'A-OTF-GothicBBBPr6N-Medium' => 'GothicBBBPr6N-Medium',
    'A-OTF-GothicBBBPro-Medium'  => 'GothicBBBPro-Medium',
    'A-OTF-Jun101Pr6N-Light'     => 'Jun101Pr6N-Light',
    'A-OTF-Jun101Pro-Light'      => 'Jun101Pro-Light',
    'A-OTF-MidashiGoPr6N-MB31'   => 'MidashiGoPr6N-MB31',
    'A-OTF-MidashiGoPro-MB31'    => 'MidashiGoPro-MB31',
    'A-OTF-RyuminPr6N-Light'     => 'RyuminPr6N-Light',
    'A-OTF-RyuminPro-Light'      => 'RyuminPro-Light',
    # Hiragino font file names and PS names are the same
    #
    # IPA
    'ipaexg' => 'IPAexGothic',
    'ipaexm' => 'IPAexMincho',
    'ipag'   => 'IPAGothic',
    'ipam'   => 'IPAMincho',
    #
    # Kozuka font names and PS names are the same
    );
  my @d;
  foreach (@$s) {
    # ship empty lines and comment lines out as is
    if (m/^\s*(%.*)?$/) {
      push(@d, $_);
      next;
    }
    # get rid of new lines for now
    chomp;
    # save the line for warnings
    my $l = $_;
    #
    my $psname;
    my $fbname;
    #
    # special case for pre-defined fallback from unicode encoded font
    if ($_ =~ m/%!DVIPSFB\s\s*([0-9A-Za-z-_!,][0-9A-Za-z-_!,]*)/) {
      $fbname = $1;
      # minimal adjustment
      $fbname =~ s/^!//;
      $fbname =~ s/,Bold//;
    }
    # first check whether a PSname is given
    # the matching on \w* is greedy, so will take all the word chars available
    # that means we do not need to test for end of word
    if ($_ =~ m/%!PS\s\s*([0-9A-Za-z-_][0-9A-Za-z-_]*)/) {
      $psname = $1;
    }
    # remove comments
    s/[^0-9A-Za-z-_]*%.*$//;
    # replace supported ",SOMETHING" constructs
    my $italicmax = 0;
    if (m/,BoldItalic/) {
      $italicmax = .3;
      s/,BoldItalic//;
    }
    s/,Bold//;
    if (m/,Italic/) {
      $italicmax = .3;
      s/,Italic//;
    }
    # replace supported "/AJ16" and co. for ptex-fontmaps CID emulation
    # note that the emulation method in GS is incomplete
    # due to "Reversal CMap method" (cf. "ToUnicode method")
    s!/A[JGCK]1[0-6]!!;
    # break out if unsupported constructs are found: @ / ,
    next if (m![\@/,]!);
    # make everything single spaced
    s/\s\s*/ /g;
    # unicode encoded fonts are not supported
    # but if a fallback font is pre-defined, we can use it
    next if (!defined($fbname) && (m!^[0-9A-Za-z-_][0-9A-Za-z-_]* unicode !));
    # now we have the following format
    #  <word> <word> <word> some options like -e or -s
    if ($_ !~ m/([^ ][^ ]*) ([^ ][^ ]*) ([^ ][^ ]*)( (.*))?$/) {
      print_warning("cidx2dvips warning: Cannot translate font line:\n==> $l\n");
      print_warning("Current translation status: ==>$_==\n");
      next;
    }
    my $tfmname = $1;
    my $cid = $2;
    my $fname = $3;
    my $opts = (defined($5) ? " $5" : "");
    # remove extensions from $fname
    $fname =~ s/\.[Oo][Tt][Ff]//;
    $fname =~ s/\.[Tt][Tt][FfCc]//;
    # remove leading ! from $fname
    $fname =~ s/^!//;
    # remove leading :<number>: from $fname
    $fname =~ s/:[0-9]+://;
    # remove leading space from $opt
    $opts =~ s/^\s+//;
    # replace -e and -s in the options
    $opts =~ s/-e ([.0-9-][.0-9-]*)/ "$1 ExtendFont"/;
    if (m/-s ([.0-9-][.0-9-]*)/) {
      if ($italicmax > 0) {
        # we have already a definition of SlantFont via ,Italic or ,BoldItalic
        # warn the user that larger one is kept
        print_warning("cidx2dvips warning: Double slant specified via Italic and -s:\n==> $l\n==> Using only the biggest slant value.\n");
      }
      $italicmax = $1 if ($1 > $italicmax);
      $opts =~ s/-s ([.0-9-][.0-9-]*)//;
    }
    if ($italicmax != 0) {
      $opts .= " \"$italicmax SlantFont\"";
    }
    # print out the result
    if (defined($fbname)) {
      push @d, "$tfmname $fbname\n";
    } else {
      if (defined($psname)) {
        push @d, "$tfmname $psname-$cid$opts\n";
      } else {
        if (defined($fname_psname{$fname})) {
          push @d, "$tfmname $fname_psname{$fname}-$cid$opts\n";
        } else {
          push @d, "$tfmname $fname-$cid$opts\n";
        }
      }
    }
  }
  return @d;
}

sub cidx2dvips_old {
    my ($s) = @_;
    my @d;
    foreach (@$s) {
      if (m/^%/) {
        push(@d, $_);
        next;
      }
      s/,BoldItalic/ -s .3/;
      s/,Bold//;
      s/,Italic/ -s .3/;
      s/\s\s*/ /g;
      if ($_ =~ /.*[@\:\/,]/) {next;}
      elsif ($_ =~ /^[^ ][^ ]* unicode /) {next;}
      s/^([^ ][^ ]* [^ ][^ ]* [^ ][^ ]*)\.[Oo][Tt][Ff]/$1/;
      s/^([^ ][^ ]* [^ ][^ ]* [^ ][^ ]*)\.[Tt][Tt][FfCc]/$1/; 
      s/$/ %/;
      s/^(([^ ]*).*)/$1$2/;
      s/^([^ ][^ ]* ([^ ][^ ]*) !*([^ ][^ ]*).*)/$1 $3-$2/;
      s/^(.* -e ([.0-9-][.0-9-]*).*)/$1 "$2 ExtendFont"/;
      s/^(.* -s ([.0-9-][.0-9-]*).*)/$1 "$2 SlantFont"/;
      s/.*%//;
      push(@d, $_);
    }
    return @d
}

sub get_cfg {
  my ($v) = @_;
  if (defined($alldata->{'merged'}{'setting'}{$v})) {
    return ( $alldata->{'merged'}{'setting'}{$v}{'val'},
             $alldata->{'merged'}{'setting'}{$v}{'origin'} );
  } else {
    return ($settings{$v}{'default'}, "default");
  }
}

sub mkMaps {
  my $logfile;

  $logfile = "$texmfvar/web2c/updmap.log";

  if (! $opts{'dry-run'}) {
    mkdirhier("$texmfvar/web2c");
    open LOG, ">$logfile"
        or die "$prg: Can't open log file \"$logfile\": $!";
    print LOG &version();
    printf LOG "%s\n\n", scalar localtime();
    print LOG  "Using the following config files:\n";
    for (@{$opts{'cnffile'}}) {
      print LOG "  $_\n";
    }
  }
  sub print_and_log {
    my $str=shift;
    print $str if !$opts{'quiet'};
    print LOG $str unless $opts{'dry-run'};
  }
  sub only_log {
    print LOG shift unless $opts{'dry-run'};
  }

  my ($mode, $mode_origin) = get_cfg('LW35');
  my ($dvipsPreferOutline, $dvipsPreferOutline_origin) = 
    get_cfg('dvipsPreferOutline');
  my ($dvipsDownloadBase35, $dvipsDownloadBase35_origin) = 
    get_cfg('dvipsDownloadBase35');
  my ($pdftexDownloadBase14, $pdftexDownloadBase14_origin) = 
    get_cfg('pdftexDownloadBase14');
  my ($pxdviUse, $pxdviUse_origin) = get_cfg('pxdviUse');
  my ($jaEmbed, $jaEmbed_origin) = get_cfg('jaEmbed');
  my ($jaVariant, $jaVariant_origin) = get_cfg('jaVariant');
  my ($scEmbed, $scEmbed_origin) = get_cfg('scEmbed');
  my ($tcEmbed, $tcEmbed_origin) = get_cfg('tcEmbed');
  my ($koEmbed, $koEmbed_origin) = get_cfg('koEmbed');

  # keep backward compatibility with old definitions
  # of kanjiEmbed, kanjiVariant
  ($jaEmbed, $jaEmbed_origin) = get_cfg('kanjiEmbed')
    if (!defined($jaEmbed));
  ($jaVariant, $jaVariant_origin) = get_cfg('kanjiVariant')
    if (!defined($jaVariant));


  # pxdvi is optional, and off by default.  Don't create the output
  # directory unless we are going to put something there.
  setupOutputDir("pxdvi") if $pxdviUse eq "true";

  my $not = $opts{"dry-run"} ? " not (-n)" : "";
  print_and_log ("\n$prg is$not creating new map files"
         . "\nusing the following configuration:"
         . "\n  LW35 font names                  : "
         .      "$mode ($mode_origin)"
         . "\n  prefer outlines                  : "
         .      "$dvipsPreferOutline ($dvipsPreferOutline_origin)"
         . "\n  texhash enabled                  : "
         .      ($opts{'nohash'} ? "false" : "true")
         . "\n  download standard fonts (dvips)  : "
         .      "$dvipsDownloadBase35 ($dvipsDownloadBase35_origin)"
         . "\n  download standard fonts (pdftex) : "
         .      "$pdftexDownloadBase14 ($pdftexDownloadBase14_origin)"
         . "\n  jaEmbed replacement string       : "
         .      "$jaEmbed ($jaEmbed_origin)"
         . "\n  jaVariant replacement string     : "
         .      ($jaVariant ? $jaVariant : "<empty>") . " ($jaVariant_origin)"
         . "\n  scEmbed replacement string       : "
         .      "$scEmbed ($scEmbed_origin)"
         . "\n  tcEmbed replacement string       : "
         .      "$tcEmbed ($tcEmbed_origin)"
         . "\n  koEmbed replacement string       : "
         .      "$koEmbed ($koEmbed_origin)"
         . "\n  create a mapfile for pxdvi       : "
         .      "$pxdviUse ($pxdviUse_origin)"
         . "\n\n");

  print_and_log ("Scanning for LW35 support files");
  my $dvips35 = $alldata->{'maps'}{"dvips35.map"}{'fullpath'};
  my $pdftex35 = $alldata->{'maps'}{"pdftex35.map"}{'fullpath'};
  my $ps2pk35 = $alldata->{'maps'}{"ps2pk35.map"}{'fullpath'};
  my $LW35 = "\n$dvips35\n$pdftex35\n$ps2pk35\n\n";
  only_log ("\n");
  only_log ($LW35);
  print_and_log ("  [  3 files]\n");
  only_log ("\n");

  print_and_log ("Scanning for MixedMap entries");
  my @mixedmaps;
  my @notmixedmaps;
  my @kanjimaps;
  for my $m (keys %{$alldata->{'maps'}}) {
    my $origin = $alldata->{'maps'}{$m}{'origin'};
    next if !defined($origin);
    next if ($origin eq 'builtin');
    next if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'} eq "disabled");
    push @mixedmaps, $m
      if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "MixedMap");
    push @notmixedmaps, $m
      if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "Map");
    push @kanjimaps, $m
      if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "KanjiMap");
  }

  @mixedmaps = sort @mixedmaps;
  @notmixedmaps = sort @notmixedmaps;
  @kanjimaps = sort @kanjimaps;
  only_log("\n");
  foreach my $m (sort @mixedmaps) {
    if (defined($alldata->{'maps'}{$m}{'fullpath'})) {
      only_log($alldata->{'maps'}{$m}{'fullpath'} . "\n");
    } else {
      only_log("$m (full path not set?)\n");
    }
  }
  only_log("\n");
  print_and_log (sprintf("    [%3d files]\n", scalar @mixedmaps));
  only_log("\n");

  print_and_log ("Scanning for KanjiMap entries");
  only_log("\n");
  foreach my $m (@kanjimaps) {
    if (defined($alldata->{'maps'}{$m}{'fullpath'})) {
      only_log($alldata->{'maps'}{$m}{'fullpath'} . "\n");
    } else {
      only_log("$m (full path not set?)\n");
    }
  }
  only_log("\n");
  print_and_log (sprintf("    [%3d files]\n", scalar @kanjimaps));
  only_log("\n");

  print_and_log ("Scanning for Map entries");
  only_log("\n");
  foreach my $m (@notmixedmaps) {
    if (defined($alldata->{'maps'}{$m}{'fullpath'})) {
      only_log($alldata->{'maps'}{$m}{'fullpath'} . "\n");
    } else {
      only_log("$m (full path not set?)\n");
    }
  }
  only_log("\n");
  print_and_log (sprintf("         [%3d files]\n\n", scalar @notmixedmaps));
  only_log("\n");

  my $first_time_creation_in_usermode = 0;
  # Create psfonts_t1.map, psfonts_pk.map, ps2pk.map and pdftex.map:
  my $dvipsoutputdir = $opts{'dvipsoutputdir'};
  my $pdftexoutputdir = $opts{'pdftexoutputdir'};
  my $dvipdfmxoutputdir = $opts{'dvipdfmxoutputdir'};
  my $pxdvioutputdir = $opts{'pxdvioutputdir'};
  if (!$opts{'dry-run'}) {
    my @managed_files =  ("$dvipsoutputdir/download35.map",
      "$dvipsoutputdir/builtin35.map",
      "$dvipsoutputdir/psfonts_t1.map",
      "$dvipsoutputdir/psfonts_pk.map",
      "$pdftexoutputdir/pdftex_dl14.map",
      "$pdftexoutputdir/pdftex_ndl14.map",
      "$dvipdfmxoutputdir/kanjix.map",
      "$dvipsoutputdir/ps2pk.map");
    push @managed_files, "$pxdvioutputdir/xdvi-ptex.map"
      if ($pxdviUse eq "true");
    for my $file (@managed_files) {
      if (!$opts{'sys'} && ! -r $file) {
        $first_time_creation_in_usermode = 1;
      }
      open FILE, ">$file";
      print FILE "% $file:\
% maintained by updmap[-sys] (multi).\
% Don't change this file directly. Use updmap[-sys] instead.\
% See the updmap documentation.\
% A log of the run that created this file is available here:\
% $logfile\
";
      close FILE;
    }
  }

  my @kanjimaps_fonts = getFonts(@kanjimaps);
  @kanjimaps_fonts = &normalizeLines(@kanjimaps_fonts);
  my @ps2pk_fonts = getFonts('-all', "ps2pk35.map");
  my @dvips35_fonts = getFonts('-all', "dvips35.map");
  my @pdftex35_fonts = getFonts('-all', "pdftex35.map");
  my @mixedmaps_fonts = getFonts(@mixedmaps);
  my @notmixedmaps_fonts = getFonts(@notmixedmaps);

  print "Generating output for dvipdfmx...\n" if !$opts{'quiet'};
  &writeLines(">$dvipdfmxoutputdir/kanjix.map", @kanjimaps_fonts);

  if ($pxdviUse eq "true") {
    # we use the very same data as for kanjix.map, but generate
    # a different file, in case a user wants to hand-craft it
    print "Generating output for pxdvi...\n" if !$opts{'quiet'};
     &writeLines(">$pxdvioutputdir/xdvi-ptex.map", @kanjimaps_fonts);
  }


  print "Generating output for ps2pk...\n" if !$opts{'quiet'};
  my @ps2pk_map;
  push @ps2pk_map, "% ps2pk35.map";
  push @ps2pk_map, transLW35($mode, @ps2pk_fonts);
  push @ps2pk_map, @mixedmaps_fonts;
  push @ps2pk_map, @notmixedmaps_fonts;
  &writeLines(">$dvipsoutputdir/ps2pk.map", 
    normalizeLines(@ps2pk_map));

  print "Generating output for dvips...\n" if !$opts{'quiet'};
  my @download35_map;
  push @download35_map, "% ps2pk35.map";
  push @download35_map, transLW35($mode, @ps2pk_fonts);
  &writeLines(">$dvipsoutputdir/download35.map", 
    normalizeLines(@download35_map));

  my @builtin35_map;
  push @builtin35_map, "% dvips35.map";
  push @builtin35_map, transLW35($mode, @dvips35_fonts);
  &writeLines(">$dvipsoutputdir/builtin35.map", 
    normalizeLines(@builtin35_map));

  my @dftdvips_fonts = 
    (($dvipsDownloadBase35 eq "true") ? @ps2pk_fonts : @dvips35_fonts);

  my @psfonts_t1_map;
  if ($dvipsDownloadBase35 eq "true") {
    push @psfonts_t1_map, "% ps2pk35.map";
    @dftdvips_fonts = @ps2pk_fonts;
  } else {
    push @psfonts_t1_map, "% dvips35.map";
    @dftdvips_fonts =  @dvips35_fonts;
  }
  push @psfonts_t1_map, transLW35($mode, @dftdvips_fonts);
  my @tmpkanji2 = cidx2dvips(\@kanjimaps_fonts);
  push @psfonts_t1_map, @mixedmaps_fonts;
  push @psfonts_t1_map, @notmixedmaps_fonts;
  push @psfonts_t1_map, @tmpkanji2;
  &writeLines(">$dvipsoutputdir/psfonts_t1.map", 
    normalizeLines(@psfonts_t1_map));

  my @psfonts_pk_map;
  push @psfonts_pk_map, transLW35($mode, @dftdvips_fonts);
  push @psfonts_pk_map, @notmixedmaps_fonts;
  push @psfonts_pk_map, @tmpkanji2;
  &writeLines(">$dvipsoutputdir/psfonts_pk.map", 
    normalizeLines(@psfonts_pk_map));

  print "Generating output for pdftex...\n" if !$opts{'quiet'};
  # remove PaintType due to Sebastian's request
  my @pdftexmaps_ndl;
  push @pdftexmaps_ndl, "% pdftex35.map";
  push @pdftexmaps_ndl, transLW35($mode, @pdftex35_fonts);
  push @pdftexmaps_ndl, @mixedmaps_fonts;
  push @pdftexmaps_ndl, @notmixedmaps_fonts;
  @pdftexmaps_ndl = grep { $_ !~ m/(^%\|PaintType)/ } @pdftexmaps_ndl;

  my @pdftexmaps_dl;
  push @pdftexmaps_dl, "% ps2pk35.map";
  push @pdftexmaps_dl, transLW35($mode, @ps2pk_fonts);
  push @pdftexmaps_dl, @mixedmaps_fonts;
  push @pdftexmaps_dl, @notmixedmaps_fonts;
  @pdftexmaps_dl = grep { $_ !~ m/(^%\|PaintType)/ } @pdftexmaps_dl;

  my @pdftex_ndl14_map = @pdftexmaps_ndl;
  @pdftex_ndl14_map = &normalizeLines(@pdftex_ndl14_map);
  @pdftex_ndl14_map = &to_pdftex(@pdftex_ndl14_map);
  &writeLines(">$pdftexoutputdir/pdftex_ndl14.map", @pdftex_ndl14_map);

  my @pdftex_dl14_map = @pdftexmaps_dl;
  @pdftex_dl14_map = &normalizeLines(@pdftex_dl14_map);
  @pdftex_dl14_map = &to_pdftex(@pdftex_dl14_map);
  &writeLines(">$pdftexoutputdir/pdftex_dl14.map", @pdftex_dl14_map);

  our $link = &setupSymlinks($dvipsPreferOutline, $dvipsoutputdir, $pdftexDownloadBase14, $pdftexoutputdir);

  print_and_log ("\nFiles$not generated:\n");
  sub dir {
    my ($d, $f, $target)=@_;
    our $link;
    if (-e "$d/$f") {
      my @stat=lstat("$d/$f");
      my ($s,$m,$h,$D,$M,$Y)=localtime($stat[9]);
      my $timestamp=sprintf ("%04d-%02d-%02d %02d:%02d:%02d",
                             $Y+1900, $M+1, $D, $h, $m, $s);
      my $date=sprintf "%12d %s %s", $stat[7], $timestamp, $f;
      print_and_log ($date);

      if (-l "$d/$f") {
        my $lnk=sprintf " -> %s\n", readlink ("$d/$f");
        print_and_log ($lnk);
      } elsif ($f eq $target) {
        if (&files_are_identical("$d/$f", "$d/" . $link->{$target})) {
          print_and_log (" = $link->{$target}\n");
        } else {
          print_and_log (" = ?????\n"); # This shouldn't happen.
        }
      } else {
        print_and_log ("\n");
      }
    } else {
      print_warning("File $d/$f doesn't exist.\n");
      print LOG     "Warning: File $d/$f doesn't exist.\n" 
        unless $opts{'dry-run'};
    }
  }

  sub check_mismatch {
    my ($mm, $d, $f, $prog) = @_;
    chomp (my $kpsefound = `kpsewhich --progname=$prog $f`);
    if (lc("$d/$f") ne lc($kpsefound)) {
      $mm->{$f} = $kpsefound;
    }
  }

  my %mismatch;
  my $d;
  $d = "$dvipsoutputdir";
  print_and_log("  $d:\n");
  foreach my $f ('builtin35.map', 'download35.map', 'psfonts_pk.map',
                 'psfonts_t1.map', 'ps2pk.map', 'psfonts.map') {
    dir ($d, $f, 'psfonts.map');
    if (!$opts{'dry-run'}) {
      $updLSR->{add}("$d/$f");
      $updLSR->{exec}();
      $updLSR->{reset}();
      check_mismatch(\%mismatch, $d, $f, "dvips");
    }
  }
  $d = "$pdftexoutputdir";
  print_and_log("  $d:\n");
  foreach my $f ('pdftex_dl14.map', 'pdftex_ndl14.map', 'pdftex.map') {
    dir ($d, $f, 'pdftex.map');
    if (!$opts{'dry-run'}) {
      $updLSR->{add}("$d/$f");
      $updLSR->{exec}();
      $updLSR->{reset}();
      check_mismatch(\%mismatch, $d, $f, "pdftex");
    }
  }
  $d="$dvipdfmxoutputdir";
  print_and_log("  $d:\n");
  foreach my $f ('kanjix.map') {
    dir ($d, $f, '');
    if (!$opts{'dry-run'}) {
      $updLSR->{add}("$d/$f");
      $updLSR->{exec}();
      $updLSR->{reset}();
      check_mismatch(\%mismatch, $d, $f, "dvipdfmx");
    }
  }
  if ($pxdviUse eq "true") {
    $d="$pxdvioutputdir";
    print_and_log("  $d:\n");
    foreach my $f ('xdvi-ptex.map') {
      dir ($d, $f, '');
      $updLSR->{add}("$d/$f") unless $opts{'dry-run'};
      if (!$opts{'dry-run'}) {
        $updLSR->{add}("$d/$f");
        $updLSR->{exec}();
        $updLSR->{reset}();
        check_mismatch(\%mismatch, $d, $f, "xdvi");
      }
    }
  }

  # all kinds of warning messages
  if ($first_time_creation_in_usermode) {
    print_and_log("
*************************************************************
*                                                           *
* WARNING: you are switching to updmap's per-user mappings. *
*         Please read the following warnings!               *
*                                                           *
*************************************************************

You have run updmap-user (as opposed to updmap-sys) for the first time;
this has created configuration files which are local to your personal account.

From now on, any changes in system map files will *not* be automatically
reflected in your files; furthermore, running updmap-sys (as is done
automatically) will no longer have any effect for you.

As a consequence, you yourself have to rerun updmap-user yourself after
any change in the *system* directories! For example, if a new font
package is added or existing mappings change, which happens frequently.
See https://tug.org/texlive/scripts-sys-user.html for details.

If you want to undo this, remove the files mentioned above.

(Run $prg --help for full documentation of updmap.)
");
  }

  if (keys %mismatch) {
    print_and_log("
WARNING: $prg has found mismatched files!

The following files have been generated as listed above,
but will not be found because overriding files exist, listed below.
");
    #
    if ($opts{'sys'}) {
      print_and_log ("
Perhaps you have run updmap-user in the past, but are running updmap-sys
now.  Once you run updmap-user the first time, you have to keep using it,
or else remove the personal configuration files it creates (the ones
listed below).
");
    }
    #
    for my $f (sort keys %mismatch) {
      print_and_log (" $f: $mismatch{$f}\n");
    }
    #
    print_and_log("(Run $prg --help for full documentation of updmap.)\n");
  }

  close LOG unless $opts{'dry-run'};
  print "\nTranscript$not written on: $logfile\n" if !$opts{'quiet'};
}


sub locateMap {
  my $map = shift;
  my $ret = `kpsewhich --format=map $map`;
  chomp($ret);
  return $ret;
}

sub processOptions {
  # first process the stupid setoption= s@{1,2} which is not accepted
  # furthermore, try to work around missing s{1,2} support in older perls
  my $oldconfig = Getopt::Long::Configure(qw(pass_through));
  our @setoptions;
  our @enable;
  sub read_one_or_two {
    my ($opt, $val) = @_;
    our @setoptions;
    our @enable;
    # check if = occirs in $val, if not, get the next argument
    if ($val =~ m/=/) {
      if ($opt eq "setoption") {
        push @setoptions, $val;
      } else {
        push @enable, $val;
      }
    } else {
      my $vv = shift @ARGV;
      die "Try \"$prg --help\" for more information.\n"
        if !defined($vv);
      if ($opt eq "setoption") {
        push @setoptions, "$val=$vv";
      } else {
        push @enable, "$val=$vv";
      }
    }
  }
  GetOptions("setoption=s@" => \&read_one_or_two,
             "enable=s@"    => \&read_one_or_two) or
    die "Try \"$prg --help\" for more information.\n";

  @{$opts{'setoption'}} = @setoptions if (@setoptions);
  @{$opts{'enable'}} = @enable if (@enable);

  Getopt::Long::Configure($oldconfig);

  # now continue with normal option handling

  GetOptions(\%opts, @cmdline_options) or 
    die "Try \"$prg --help\" for more information.\n";
}

# determines the output dir for driver from cmd line, or if not given
# from TEXMFVAR
sub setupOutputDir {
  my $driver = shift;
  if (!$opts{$driver . "outputdir"}) {
    if ($opts{'outputdir'}) {
      $opts{$driver . "outputdir"} = $opts{'outputdir'};
    } else {
      $opts{$driver . "outputdir"} = "$texmfvar/fonts/map/$driver/updmap";
    }
  }
  my $od = $opts{$driver . "outputdir"};
  if (!$opts{"dry-run"}) {
    &mkdirhier($od);
    if (! -w $od) {
      die "$prg: Directory \"$od\" isn't writable: $!";
    }
  }
  print "$driver output dir: \"$od\"\n" if !$opts{'quiet'};
  return $od;
}

###############################################################################
# setOption (@options)
#   parse @options for "key=value" (one element of @options)
#   we can only have "key=value" since that is the way it was prepared
#   in process_options
#   (These were the values provided to --setoption.)
#   
sub setOptions {
  my (@options) = @_;
  for (my $i = 0; $i < @options; $i++) {
    my $o = $options[$i];

    my ($key,$val) = split (/=/, $o, 2);
    
    die "$prg: unexpected empty key or val for options (@options), goodbye.\n"
      if !$key || !defined($val);

    &setOption ($key, $val);
  }
  return save_updmap($alldata->{'changes_config'});
}

sub enable_disable_maps {
  my (@what) = @_;
  my $tc = $alldata->{'changes_config'};
  die "$prg: top config file $tc has not been read."
    if (!defined($alldata->{'updmap'}{$tc}));

  for my $w (@what) {
    if ($w =~ m/=/) {
      # this is --enable MapType=MapName
      my ($type, $map) = split ('=', $w);
      # allow for all lowercase map types (map/mixedmap/kanjimap)
      $type =~ s/map$/Map/;
      $type = ucfirst($type);
      # don't allow map names containing /
      die "$prg: map names cannot contain /: $map\n" if ($map =~ m{/});
      enable_map($tc, $type, $map);
    } else {
      # this is --disable MapName
      disable_map($tc, $w);
    }
  }
  return save_updmap($tc);
}

sub enable_map {
  my ($tc, $type, $map) = @_;

  die "$prg: invalid mapType $type" if ($type !~ m/^(Map|MixedMap|KanjiMap)$/);

  if (defined($alldata->{'updmap'}{$tc}{'maps'}{$map})) {
    # the map data has already been read in, no special precautions necessary
    if (($alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} eq "enabled") &&
        ($alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} eq $type)) {
      # nothing to do here ... be happy!
      return;
    } else {
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "enabled";
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} = $type;
      $alldata->{'maps'}{$map}{'origin'} = $tc;
      $alldata->{'maps'}{$map}{'status'} = "enabled";
      $alldata->{'updmap'}{$tc}{'changed'} = 1;
    }
  } else {
    # add a new map file!
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} = $type;
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "enabled";
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'line'} = -1;
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
    $alldata->{'maps'}{$map}{'origin'} = $tc;
    $alldata->{'maps'}{$map}{'status'} = "enabled";
  }
}

sub disable_map {
  my ($tc, $map) = @_;

  merge_settings_replace_kanji();

  if (defined($alldata->{'updmap'}{$tc}{'maps'}{$map})) {
    # the map data has already been read in, no special precautions necessary
    if ($alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} eq "disabled") {
      # nothing to do here ... be happy!
    } else {
      $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "disabled";
      $alldata->{'maps'}{$map}{'origin'} = $tc;
      $alldata->{'maps'}{$map}{'status'} = "disabled";
      $alldata->{'updmap'}{$tc}{'changed'} = 1;
    }
  } else {
    # disable a Map type that might be activated in a lower ranked updmap.cfg
    if (!defined($alldata->{'maps'}{$map})) {
      print_warning("map file not present, nothing to disable: $map\n");
      return;
    }
    my $orig = $alldata->{'maps'}{$map}{'origin'};
    # add a new entry to the top level where we disable it
    # copy over the type from the last entry
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'type'} = 
      $alldata->{'updmap'}{$orig}{'maps'}{$map}{'type'};
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'status'} = "disabled";
    $alldata->{'updmap'}{$tc}{'maps'}{$map}{'line'} = -1;
    # rewrite the origin
    $alldata->{'maps'}{$map}{'origin'} = $tc;
    $alldata->{'maps'}{$map}{'status'} = "disabled";
    # go on for writing
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
  }
}


# returns 1 if actually saved due to changes
sub save_updmap {
  my $fn = shift;
  return if $opts{'dry-run'};
  my %upd = %{$alldata->{'updmap'}{$fn}};
  if ($upd{'changed'}) {
    mkdirhier(dirname($fn));
    open (FN, ">$fn") || die "$prg: can't write to $fn: $!";
    my @lines = @{$upd{'lines'}};
    if (!@lines) {
      print "Creating new config file $fn\n";
      # update lsR database
      $updLSR->{add}($fn);
      $updLSR->{exec}();
      # reset the LSR stuff, otherwise we add files several times
      $updLSR->{reset}();
    }
    # collect the lines with data
    my %line_to_setting;
    my %line_to_map;
    my @add_setting;
    my @add_map;
    if (defined($upd{'setting'})) {
      for my $k (keys %{$upd{'setting'}}) {
        if ($upd{'setting'}{$k}{'line'} == -1) {
          push @add_setting, $k;
        } else {
          $line_to_setting{$upd{'setting'}{$k}{'line'}} = $k;
        }
      }
    }
    if (defined($upd{'maps'})) {
      for my $k (keys %{$upd{'maps'}}) {
        if ($upd{'maps'}{$k}{'line'} == -1) {
          push @add_map, $k;
        } else {
          $line_to_map{$upd{'maps'}{$k}{'line'}} = $k;
        }
      }
    }
    for my $i (0..$#lines) {
      if (defined($line_to_setting{$i})) {
        my $k = $line_to_setting{$i};
        my $v = $upd{'setting'}{$k}{'val'};
        print FN "$k $v\n";
      } elsif (defined($line_to_map{$i})) {
        my $m = $line_to_map{$i};
        my $rm;
        if (defined($upd{'maps'}{$m}{'original'})) {
          # we have the case that @noEmbed@ was replaced by the respective
          # setting. Before writing out we have to replace this back with
          # the original line!A
          $rm = $upd{'maps'}{$m}{'original'};
        } else {
          $rm = $m;
        }
        my $t = $upd{'maps'}{$m}{'type'};
        my $p = ($upd{'maps'}{$m}{'status'} eq "disabled" ? "#! " : "");
        print FN "$p$t $rm\n";
      } else {
        print FN "$lines[$i]\n";
      }
    }
    # add the new settings and maps
    for my $k (@add_setting) {
      my $v = $upd{'setting'}{$k}{'val'};
      print FN "$k $v\n";
    }
    for my $m (@add_map) {
      my $t = $upd{'maps'}{$m}{'type'};
      my $p = ($upd{'maps'}{$m}{'status'} eq "disabled" ? "#! " : "");
      print FN "$p$t $m\n";
    }
    close(FN) || warn("$prg: Cannot close file handle for $fn: $!");
    delete $alldata->{'updmap'}{$fn}{'changed'};
    return 1;
  }
  return 0;
}

######################
# check for correct option value
#
sub check_option {
  my ($opt, $val) = @_;
  if ((($settings{$opt}{'type'} eq "binary") && 
       $val ne "true" && $val ne "false") ||
      (($settings{$opt}{'type'} eq "string") &&
       !member($val, @{$settings{$opt}{'possible'}}))) {
    return 0;
  }
  return 1;
}

###############################################################################
# setOption (conf_file, option, value)
#   sets option to value in the config file (replacing the existing setting
#   or by adding a new line to the config file).
#
sub setOption {
  my ($opt, $val) = @_;

  # allow backward compatility with old kanjiEmbed and kanjiVariant settings
  if ($opt eq "kanjiEmbed") {
    print_warning("using jaEmbed instead of kanjiEmbed\n");
    $opt = "jaEmbed";
  }
  if ($opt eq "kanjiVariant") {
    print_warning("using jaVariant instead of kanjiVariant\n");
    $opt = "jaVariant";
  }

  die "$prg: Unsupported option $opt." if (!defined($settings{$opt}));
  die "$0: Invalid value $val for option $opt." 
    if (!check_option($opt, $val));

  # silently accept this old option name, just in case.
  return if $opt eq "dvipdfmDownloadBase14";
  
  #print "Setting option $opt to $val...\n" if !$opts{'quiet'};
  my $tc = $alldata->{'changes_config'};

  die "$prg: top config file $tc has not been read."
    if (!defined($alldata->{'updmap'}{$tc}));

  if (defined($alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'})) {
    # the value is already set, do nothing
    if ($alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'} eq $val) {
      return;
    }
    $alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'} = $val;
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
  } else {
    $alldata->{'updmap'}{$tc}{'setting'}{$opt}{'val'} = $val;
    $alldata->{'updmap'}{$tc}{'setting'}{$opt}{'line'} = -1;
    $alldata->{'updmap'}{$tc}{'changed'} = 1;
  }
}


###############################################################################
# copyFile()
#   copy file $src to $dst, sets $dst creation and mod time
#
sub copyFile {
  my ($src, $dst) = @_;
  my $dir;
  ($dir=$dst)=~s/(.*)\/.*/$1/;
  mkdirhier($dir);

  $src eq $dst && return "can't copy $src to itself!\n";

  open IN, "<$src" or die "$0: can't open source file $src for copying: $!";
  open OUT, ">$dst";

  binmode(IN);
  binmode(OUT);
  print OUT <IN>;
  close(OUT);
  close(IN);
  my @t = stat($src);
  utime($t[8], $t[9], $dst);
}

###############################################################################
# files_are_identical(file_A, file_B)
#   compare two files.  Same as cmp(1).
#
sub files_are_identical {
  my $file_A=shift;
  my $file_B=shift;
  my $retval=0;

  open IN, "$file_A";
  my $A=(<IN>);
  close IN;
  open IN, "$file_B";
  my $B=(<IN>);
  close IN;

  $retval=1 if ($A eq $B);
  return $retval;
}

###############################################################################
# files_are_different(file_A, file_B[, comment_char])
#   compare two equalized files.
#
sub files_are_different {
  my $file_A=shift;
  my $file_B=shift;
  my $comment=shift;
  my $retval=0;

  my $A=equalize_file("$file_A", $comment);
  my $B=equalize_file("$file_B", $comment);
  $retval=1 unless ($A eq $B);
  return $retval;
}

###############################################################################
# equalize_file(filename[, comment_char])
#   read a file and return its processed content as a string.
#   look into the source code for more details.
#
sub equalize_file {
  my $file=shift;
  my $comment=shift;
  my @temp;

  open IN, "$file";
  my @lines = (<IN>);
  close IN;
  chomp(@lines);

  for (@lines) {
    s/\s*${comment}.*// if (defined $comment); # remove comments
    next if /^\s*$/;                           # remove empty lines
    s/\s+/ /g;     # replace multiple whitespace chars by a single one
    push @temp, $_;
  }
  return join('X', sort(@temp));
}

###############################################################################
# normalizeLines()
#   not the original function, we want it to keep comments, that are
#   anyway only the file names we are adding!
#   whitespace is exactly one space, no empty lines,
#   no whitespace at end of line, one space before and after "
#
sub normalizeLines {
  my @lines = @_;
  my %count = ();

  # @lines = grep { $_ !~ m/^[*#;%]/ } @lines;
  map {$_ =~ s/\s+/ /gx } @lines;
  @lines = grep { $_ !~ m/^\s*$/x } @lines;
  map { $_ =~ s/\s$//x ;
        $_ =~ s/\s*\"\s*/ \" /gx;
        $_ =~ s/\" ([^\"]*) \"/\"$1\"/gx;
      } @lines;

  # @lines = grep {++$count{$_} < 2 } (sort @lines);
  @lines = grep {++$count{$_} < 2 } (@lines);

  return @lines;
}


#################################################################
#
# reading updmap-cfg files and the actual map files
#
# the following hash saves *all* the information and is passed around
# we do not fill everything from the very beginning to make sure that
# we only read what is necessary (speed!)
#
# initialized by main
# $alldata->{'changes_config'} = the config file where changes are saved
#
# initialized by read_updmap_files
# $alldata->{'order'} = [ list of updmap in decreasing priority ]
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'lines'} = \@lines
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'setting'}{$key}{'val'} = $val
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'setting'}{$key}{'line'} = $i
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'maps'}{$mapname}{'type'} 
#            = 'Map'|'MixedMap'|'KanjiMap'|'disabled'
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'maps'}{$mapname}{'status'} 
#            = 'enabled'|'disabled'
# $alldata->{'updmap'}{$full_path_name_of_updmap}{'maps'}{$mapname}{'line'} = $i
# $alldata->{'maps'}{$m}{'origin'} = $updmap_path_name
# $alldata->{'maps'}{$m}{'status'} = enabled | disabled
#
# initialized by read_map_files
# $alldata->{'maps'}{$m}{'fonts'}{$font} = $definition
# $alldata->{'fonts'}{$f}{'origin'} = $map
#
# initialized by merge_data
# $alldata->{'merged'}{'setting'}{$key}{'val'} = $val
# $alldata->{'merged'}{'setting'}{$key}{'origin'} = $origin_updmap_cfg
# $alldata->{'merged'}{'allMaps'}{'fonts'}{$fontdef} = $rest
# $alldata->{'merged'}{'noMixedMaps'}{'fonts'}{$fontdef} = $rest
# $alldata->{'merged'}{'KanjiMaps'}{'fonts'}{$fontdef} = $rest
#

sub read_updmap_files {
  my (@l) = @_;
  for my $l (@l) {
    my $updmap = read_updmap_file($l);
    $alldata->{'updmap'}{$l}{'lines'} = $updmap->{'lines'};
    if (defined($updmap->{'setting'})) {
      for my $k (keys %{$updmap->{'setting'}}) {
        $alldata->{'updmap'}{$l}{'setting'}{$k}{'val'} = $updmap->{'setting'}{$k}{'val'};
        $alldata->{'updmap'}{$l}{'setting'}{$k}{'line'} = $updmap->{'setting'}{$k}{'line'};
      }
    }
    if (defined($updmap->{'maps'})) {
      for my $k (keys %{$updmap->{'maps'}}) {
        $alldata->{'updmap'}{$l}{'maps'}{$k}{'type'} = $updmap->{'maps'}{$k}{'type'};
        $alldata->{'updmap'}{$l}{'maps'}{$k}{'status'} = $updmap->{'maps'}{$k}{'status'};
        $alldata->{'updmap'}{$l}{'maps'}{$k}{'line'} = $updmap->{'maps'}{$k}{'line'};
      }
    }
  }
  # in case the changes_config is a new one read it in and initialize it here
  my $cc = $alldata->{'changes_config'};
  if (! -r $cc) {
    $alldata->{'updmap'}{$cc}{'lines'} = [ ];
  }
  #
  $alldata->{'order'} = \@l;
}

sub merge_settings_replace_kanji {
  #
  my @l = @{$alldata->{'order'}};
  #
  # for security clean out everything that was there
  %{$alldata->{'merged'}} = ();
  #
  # first read in the settings
  # we read it in *reverse* order and simple fill up the combined data
  # thus if there are multiple definitions/settings, the one coming from
  # the first in the original list will win!
  for my $l (reverse @l) {
    # merge settings
    if (defined($alldata->{'updmap'}{$l}{'setting'})) {
      for my $k (keys %{$alldata->{'updmap'}{$l}{'setting'}}) {
        $alldata->{'merged'}{'setting'}{$k}{'val'} = $alldata->{'updmap'}{$l}{'setting'}{$k}{'val'};
        $alldata->{'merged'}{'setting'}{$k}{'origin'} = $l;
      }
    }
  }
  #
  my ($jaEmbed, $jaEmbed_origin) = get_cfg('jaEmbed');
  my ($jaVariant, $jaVariant_origin) = get_cfg('jaVariant');
  my ($scEmbed, $scEmbed_origin) = get_cfg('scEmbed');
  my ($tcEmbed, $tcEmbed_origin) = get_cfg('tcEmbed');
  my ($koEmbed, $koEmbed_origin) = get_cfg('koEmbed');

  # keep backward compatibility with old definitions
  # of kanjiEmbed, kanjiVariant
  ($jaEmbed, $jaEmbed_origin) = get_cfg('kanjiEmbed')
    if (!defined($jaEmbed));
  ($jaVariant, $jaVariant_origin) = get_cfg('kanjiVariant')
    if (!defined($jaVariant));

  #
  # go through all map files and check that the text is properly replaced
  # after the replacement check that the generated map file actually
  # exists, we do NOT want to break in this case!
  #
  for my $l (@l) {
    for my $m (keys %{$alldata->{'updmap'}{$l}{'maps'}}) {
      my $newm = $m;
      # do all kinds of substitutions
      $newm =~ s/\@jaEmbed@/$jaEmbed/;
      $newm =~ s/\@jaVariant@/$jaVariant/;
      $newm =~ s/\@scEmbed@/$scEmbed/;
      $newm =~ s/\@tcEmbed@/$tcEmbed/;
      $newm =~ s/\@koEmbed@/$koEmbed/;
      # also do substitutions of old strings in case they are left
      # over somewhere
      $newm =~ s/\@kanjiEmbed@/$jaEmbed/;
      $newm =~ s/\@kanjiVariant@/$jaVariant/;
      if ($newm ne $m) {
        # something was substituted
        if (locateMap($newm)) {
          # now we have to update various linked items
          $alldata->{'updmap'}{$l}{'maps'}{$newm}{'type'} =
            $alldata->{'updmap'}{$l}{'maps'}{$m}{'type'};
          $alldata->{'updmap'}{$l}{'maps'}{$newm}{'status'} =
            $alldata->{'updmap'}{$l}{'maps'}{$m}{'status'};
          $alldata->{'updmap'}{$l}{'maps'}{$newm}{'line'} =
            $alldata->{'updmap'}{$l}{'maps'}{$m}{'line'};
          $alldata->{'updmap'}{$l}{'maps'}{$newm}{'original'} = $m;
        } else {
          print_warning("generated map $newm (from $m) does not exist, not activating it!\n");
        }
        # in any case delete the @kanji...@ entry line, such a map will
        # never exist
        delete $alldata->{'updmap'}{$l}{'maps'}{$m};
      }
    }
  }
  #
  # first round determine which maps should be used and which type, as
  # different updmap.cfg files might specify different types of maps
  # (MixedMap or Map or KanjiMap).
  # Again, we have to do that in reverse order
  for my $l (reverse @l) {
    if (defined($alldata->{'updmap'}{$l}{'maps'})) {
      for my $m (keys %{$alldata->{'updmap'}{$l}{'maps'}}) {
        $alldata->{'maps'}{$m}{'origin'} = $l;
        $alldata->{'maps'}{$m}{'status'} = $alldata->{'updmap'}{$l}{'maps'}{$m}{'status'};
      }
    }
  }
}

sub read_updmap_file {
  my $fn = shift;
  my %data;
  if (!open(FN,"<$fn")) {
    die ("Cannot read $fn: $!");
  }
  # we count lines from 0 ..!!!!
  my $i = -1;
  my @lines = <FN>;
  chomp(@lines);
  $data{'lines'} = [ @lines ];
  close(FN) || warn("$prg: Cannot close $fn: $!");
  for (@lines) {
    $i++;
    chomp;
    next if /^\s*$/;
    next if /^\s*#$/;
    next if /^\s*#[^!]/;
    next if /^\s*##/;
    next if /^#![^ ]/;
    # allow for commands on the line itself
    s/([^#].*)#.*$/$1/;
    my ($a, $b, @rest) = split ' ';
    # make sure we get empty strings as arguments
    $b = "" if (!defined($b));
    if ($a eq "#!") {
      if ($b eq "Map" || $b eq "MixedMap" || $b eq "KanjiMap") {
        my $c = shift @rest;
        if (!defined($c)) {
          print_warning("apparently not a real disable line, ignored: $_\n");
        } else {
          if (defined($data{'maps'}{$c})) {
            print_warning("double mention of $c in $fn\n");
          }
          $data{'maps'}{$c}{'status'} = 'disabled';
          $data{'maps'}{$c}{'type'} = $b;
          $data{'maps'}{$c}{'line'} = $i;
        }
      }
      next;
    }
    if (@rest) {
      print_warning("line $i in $fn contains a syntax error, more than two words!\n");
    }
    # backward compatibility with kanjiEmbed/kanjiVariant
    $a = ($a eq "kanjiEmbed" ? "jaEmbed" : $a);
    $a = ($a eq "kanjiVariant" ? "jaVariant" : $a);
    if (defined($settings{$a})) {
      if (check_option($a, $b)) {
        $data{'setting'}{$a}{'val'} = $b;
        $data{'setting'}{$a}{'line'} = $i;
      } else {
        print_warning("unknown setting for $a: $b, ignored!\n");
      }
    } elsif ($a eq "Map" || $a eq "MixedMap" || $a eq "KanjiMap") {
      if (defined($data{'maps'}{$b}) && $data{'maps'}{$b}{'type'} ne $a) {
        print_warning("double mention of $b with conflicting types in $fn\n");
      } else {
        $data{'maps'}{$b}{'type'} = $a;
        $data{'maps'}{$b}{'status'} = 'enabled';
        $data{'maps'}{$b}{'line'} = $i;
      }
    } else {
      print_warning("unrecognized line $i in $fn: $_\n");
    }
  }
  return \%data;
}

sub read_map_files {
  my $quick = shift;
  if (!defined($alldata->{'updmap'})) {
    return;
  }
  my @missing;
  my @l = @{$alldata->{'order'}};
  # first collect all the map files we are interested in
  # and determine whether they exist, and get their full path
  my @maps;
  for my $f (@l) {
    next if !defined($alldata->{'updmap'}{$f}{'maps'});
    for my $m (keys %{$alldata->{'updmap'}{$f}{'maps'}}) {
      # only read a map file if its final status is enabled!
      push @maps, $m if ($alldata->{'maps'}{$m}{'status'} eq 'enabled');
    }
  }
  for my $m (qw/dvips35.map pdftex35.map ps2pk35.map/) {
    push @maps, $m;
    $alldata->{'maps'}{$m}{'status'} = 'enabled';
    $alldata->{'maps'}{$m}{'origin'} = 'builtin';
  }
  @maps = sort_uniq(@maps);
  my @fullpath = `kpsewhich --format=map @maps`;
  chomp @fullpath;
  foreach my $map (@maps) {
    # in case they give an absolute path (not needed/desired, but ...);
    # Windows not supported.
    my $dirsep = ($map =~ m!^/!) ? "" : "/";
    # quotemeta the map string to avoid perl regexp warning, e.g.,
    # if map name contains "\Users", the "\U" should be literal.
    my ($ff) = grep /$dirsep\Q$map\E(\.map)?$/, @fullpath;
    if ($ff) {
      $alldata->{'maps'}{$map}{'fullpath'} = $ff;
    } else {
      # if the map file is not found, then push it onto the list of 
      # missing map files, since we know that it is enabled
      push @missing, $map;
    }
  }
  return @missing if $quick;

  #
  # read in the three basic fonts definition maps
  for my $m (qw/dvips35.map pdftex35.map ps2pk35.map/) {
    my $ret = read_map_file($alldata->{'maps'}{$m}{'fullpath'});
    my @ff = ();
    for my $font (keys %$ret) {
      $alldata->{'fonts'}{$font}{'origin'} = $m;
      $alldata->{'maps'}{$m}{'fonts'}{$font} = $ret->{$font};
    }
  }
  # we read the updmap in reverse directions, since we
  # replace the origin field of font definition always with the
  # top one
  for my $f (reverse @l) {
    my @maps = keys %{$alldata->{'updmap'}{$f}{'maps'}};
    for my $m (@maps) {
      # we do not read a map file multiple times, if $alldata{'maps'}{$m} is
      # defined we expect that it was read and do skip it
      next if defined($alldata->{'maps'}{$m}{'fonts'});
      # we do not read a map files content if it is disabled
      next if ($alldata->{'maps'}{$m}{'status'} eq 'disabled');
      if (!defined($alldata->{'maps'}{$m}{'fullpath'})) {
        # we have already pushed these map files onto the list of missing
        # map files, so do nothing here
        next;
      }
      my $ret = read_map_file($alldata->{'maps'}{$m}{'fullpath'});
      if (defined($ret)) {
        for my $font (keys %$ret) {
          if (defined($alldata->{'fonts'}{$font})) {
            # we got another definition, warn on that
            # if the origin is not defined by now, the font is defined
            # multiple times in the same map file, otherwise it is
            # defined in another map file already
            if (defined($alldata->{'fonts'}{$font}{'origin'})) {
              my $fontorig = $alldata->{'fonts'}{$font}{'origin'};
              my $maporig;
              if (($fontorig eq "ps2pk35.map") ||
                  ($fontorig eq "pdftex35.map") ||
                  ($fontorig eq "dvips35.map")) {
                $maporig = "built in map - both used - warning!";
              } else {
                $maporig = "from " . $alldata->{'maps'}{$fontorig}{'origin'};
              }
              print_warning("font $font is defined multiple times:\n");
              print_warning("  $fontorig ($maporig)\n");
              print_warning("  $m (from $f) (used)\n");
            } else {
              print_warning("font $font is multiply defined in $m, using an arbitrary instance!\n");
            }
          }
          $alldata->{'fonts'}{$font}{'origin'} = $m;
          $alldata->{'maps'}{$m}{'fonts'}{$font} = $ret->{$font};
        }
      }
    }
  }
  return (@missing);
}

sub read_map_file {
  my $fn = shift;
  my @lines;
  if (!open(MF,"<$fn")) {
    warn("$prg: open($fn) failed: $!");
    return;
  }
  @lines = <MF>;
  close(MF);
  chomp(@lines);
  my %data;
  for (@lines) {
    next if /^\s*#/;
    next if /^\s*%/;
    next if /^\s*$/;
    my ($a, $b) = split(' ', $_, 2);
    $data{$a} = $b;
  }
  return \%data;
}

#
# merging the various font definitions
#
sub merge_data {
  my @l = @{$alldata->{'order'}};
  #
  # now merge the data
  #
  for my $m (keys %{$alldata->{'maps'}}) {
    my $origin = $alldata->{'maps'}{$m}{'origin'};
    next if !defined($origin);
    next if ($origin eq 'builtin');
    next if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'status'} eq "disabled");
    for my $f (keys %{$alldata->{'maps'}{$m}{'fonts'}}) {
      # use the font definition only for those fonts where the origin matches
      if ($alldata->{'fonts'}{$f}{'origin'} eq $m) {
        $alldata->{'merged'}{'allMaps'}{'fonts'}{$f} = 
          $alldata->{'maps'}{$m}{'fonts'}{$f}
            if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} ne "KanjiMap");
        $alldata->{'merged'}{'noMixedMaps'}{'fonts'}{$f} = 
          $alldata->{'maps'}{$m}{'fonts'}{$f}
            if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "Map");
        $alldata->{'merged'}{'KanjiMap'}{'fonts'}{$f} = 
          $alldata->{'maps'}{$m}{'fonts'}{$f}
            if ($alldata->{'updmap'}{$origin}{'maps'}{$m}{'type'} eq "KanjiMap");
      }
    }
  }
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

sub print_warning {
  print STDERR "$prg [WARNING]: ", @_ if (!$opts{'quiet'}) 
}
sub print_error {
  print STDERR "$prg [ERROR]: ", @_;
}


# help, version.

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}

sub help {
  my $usage = <<"EOF";
Usage: $prg [-user|-sys] [OPTION] ... [COMMAND]
   or: $prg-user [OPTION] ... [COMMAND]
   or: $prg-sys  [OPTION] ... [COMMAND]

Update the default font map files used by pdftex and dvipdfm(x)
(pdftex.map), dvips (psfonts.map), and optionally pxdvi, as determined
by all configuration files updmap.cfg (usually the ones returned by
running "kpsewhich --all updmap.cfg", but see below).

Among other things, these map files are used to determine which fonts
should be used as bitmaps and which as outlines, and to determine which
font files are included, typically subsetted, in the PDF or PostScript output.

updmap-sys (or updmap -sys) is intended to affect the system-wide 
configuration, while updmap-user (or updmap -user) affects personal
configuration files only, overriding the system files.  

As a consequence, once updmap-user has been run, even a single time,
running updmap-sys no longer has any effect.  updmap-sys issues a
warning about this, since it is rarely desirable.
See https://tug.org/texlive/scripts-sys-user.html for details.

By default, the TeX filename database (ls-R) is also updated.

The updmap system is regrettably complicated, for both inherent and
historical reasons.  A general overview:

- updmap.cfg files are mainly about listing other files, namely the
  font-specific .maps, in which each line gives information about a
  different TeX (.tfm) font.
- updmap reads the updmap.cfg files and then concatenates the
  contents of those .map files into the main output files: psfonts.map
  for dvips and pdftex.map for pdftex and dvipdfmx.
- The updmap.cfg files themselves are created and updated at package
  installation time, by the system installer or the package manager or
  by hand, and not (by default) by updmap.

Options:
  --cnffile FILE            read FILE for the updmap configuration 
                             (can be given multiple times, in which case
                             all the files are used)
  --dvipdfmxoutputdir DIR   specify output directory (dvipdfm(x) syntax)
  --dvipsoutputdir DIR      specify output directory (dvips syntax)
  --pdftexoutputdir DIR     specify output directory (pdftex syntax)
  --pxdvioutputdir DIR      specify output directory (pxdvi syntax)
  --outputdir DIR           specify output directory (for all files)
  --copy                    cp generic files rather than using symlinks
  --force                   recreate files even if config hasn't changed
  --nomkmap                 do not recreate map files
  --nohash                  do not run mktexlsr (a.k.a. texhash)
  --sys                     affect system-wide files (equivalent to updmap-sys)
  --user                    affect personal files (equivalent to updmap-user)
  -n, --dry-run             only show the configuration, no output
  --quiet, --silent         reduce verbosity

Commands:
  --help                     show this message and exit
  --version                  show version information and exit
  --showoption OPTION        show the current setting of OPTION
  --showoptions OPTION       show possible settings for OPTION
  --setoption OPTION VALUE   set OPTION to value; option names below
  --setoption OPTION=VALUE   as above, just different syntax
  --enable MAPTYPE MAPFILE   add "MAPTYPE MAPFILE" to updmap.cfg,
                              where MAPTYPE is Map, MixedMap, or KanjiMap
  --enable Map=MAPFILE       add \"Map MAPFILE\" to updmap.cfg
  --enable MixedMap=MAPFILE  add \"MixedMap MAPFILE\" to updmap.cfg
  --enable KanjiMap=MAPFILE  add \"KanjiMap MAPFILE\" to updmap.cfg
  --disable MAPFILE          disable MAPFILE, of whatever type
  --listmaps                 list all maps (details below)
  --listavailablemaps        list available maps (details below)
  --syncwithtrees            disable unavailable map files in updmap.cfg

The main output:

  The main output of updmap is the files containing the individual font
  map lines which the drivers (dvips, pdftex, etc.) read to handle fonts.
  
  The map files for dvips (psfonts.map) and pdftex and dvipdfmx
  (pdftex.map) are written to TEXMFVAR/fonts/map/updmap/{dvips,pdftex}/.
  
  In addition, information about Kanji fonts is written to
  TEXMFVAR/fonts/map/updmap/dvipdfmx/kanjix.map, and optionally to 
  TEXMFVAR/fonts/map/updmap/pxdvi/xdvi-ptex.map.  These are for Kanji
  only and are not like other map files.  dvipdfmx reads pdftex.map for
  the map entries for non-Kanji fonts.
  
  If no option is given, so the invocation is just "updmap-user" or
  "updmap-sys", these output files are always recreated.

  Otherwise, if an option such as --enable or --disable is given, the
  output files are recreated if the list of enabled map files (from
  updmap.cfg) has changed.  The --force option overrides this,
  always recreating the output files.
  
Explanation of the map types:

  The normal type is Map.
  
  The only difference between Map and MixedMap is that MixedMap entries
  are not added to psfonts_pk.map.  The purpose is to help users with
  devices that render Type 1 outline fonts worse than mode-tuned Type 3
  bitmap fonts.  So, MixedMap is used for fonts that are available as
  both Type 1 and Metafont.

  KanjiMap entries are added to psfonts_t1.map and kanjix.map.

Explanation of the OPTION names for --showoptions, --showoption, --setoption:

  dvipsPreferOutline    true,false  (default true)
    Whether dvips uses bitmaps or outlines, when both are available.
  dvipsDownloadBase35   true,false  (default true)
    Whether dvips includes the standard 35 PostScript fonts in its output.
  pdftexDownloadBase14  true,false   (default true)
    Whether pdftex includes the standard 14 PDF fonts in its output.
  pxdviUse              true,false  (default false)
    Whether maps for pxdvi (Japanese-patched xdvi) are under updmap's control.
  jaEmbed               (any string)
  jaVariant             (any string)
  scEmbed               (any string)
  tcEmbed               (any string)
  koEmbed               (any string)
    See below.
  LW35                  URWkb,URW,ADOBEkb,ADOBE  (default URWkb)
    Adapt the font and file names of the standard 35 PostScript fonts.

    URWkb    URW fonts with "berry" filenames    (e.g. uhvbo8ac.pfb)
    URW      URW fonts with "vendor" filenames   (e.g. n019064l.pfb)
    ADOBEkb  Adobe fonts with "berry" filenames  (e.g. phvbo8an.pfb)
    ADOBE    Adobe fonts with "vendor" filenames (e.g. hvnbo___.pfb)

  These options are only read and acted on by updmap; dvips, pdftex, etc.,
  do not know anything about them.  They work by changing the default map
  file which the programs read, so they can be overridden by specifying
  command-line options or configuration files to the programs, as
  explained at the beginning of updmap.cfg.

  The options jaEmbed and jaVariant (formerly kanjiEmbed and kanjiVariant)
  specify special replacements in the map lines.  If a map contains the 
  string \@jaEmbed\@, then this will be replaced by the value of that option;
  similarly for jaVariant.  In this way, users of Japanese TeX can select
  different fonts to be included in the final output.  The counterpart for
  Simplified Chinese, Traditional Chinese and Korean fonts are
  scEmbed, tcEmbed and koEmbed respectively.

Explanation of trees and files normally used:

  If --cnffile is specified on the command line (can be given multiple
  times), its value(s) is(are) used.  Otherwise, updmap reads all the
  updmap.cfg files found by running \`kpsewhich -all updmap.cfg',
  in the order returned by kpsewhich (which is the order of trees
  defined in texmf.cnf).

  In either case, if multiple updmap.cfg files are found, all the maps
  mentioned in all the updmap.cfg files are merged.

  Thus, if updmap.cfg files are present in all trees, and the default
  layout is used as shipped with TeX Live, the following files are
  read, in the given order.
  
  For updmap-sys:
  TEXMFSYSCONFIG \$TEXLIVE/YYYY/texmf-config/web2c/updmap.cfg
  TEXMFSYSVAR    \$TEXLIVE/YYYY/texmf-var/web2c/updmap.cfg
  TEXMFLOCAL     \$TEXLIVE/texmf-local/web2c/updmap.cfg
  TEXMFDIST      \$TEXLIVE/YYYY/texmf-dist/web2c/updmap.cfg

  For updmap-user:
  TEXMFCONFIG    \$HOME/.texliveYYYY/texmf-config/web2c/updmap.cfg
  TEXMFVAR       \$HOME/.texliveYYYY/texmf-var/web2c/updmap.cfg
  TEXMFHOME      \$HOME/texmf/web2c/updmap.cfg
  TEXMFSYSCONFIG \$TEXLIVE/YYYY/texmf-config/web2c/updmap.cfg
  TEXMFSYSVAR    \$TEXLIVE/YYYY/texmf-var/web2c/updmap.cfg
  TEXMFLOCAL     \$TEXLIVE/texmf-local/web2c/updmap.cfg
  TEXMFDIST      \$TEXLIVE/YYYY/texmf-dist/web2c/updmap.cfg
  
  (where YYYY is the TeX Live release version).
  
  According to the actions, updmap might write to one of the given files
  or create a new updmap.cfg, described further below.

Where and which updmap.cfg changes are saved: 

  When no options are given, the updmap.cfg file(s) are only read, not
  written.  It's when an option --setoption, --enable or --disable is
  specified that an updmap.cfg needs to be updated.  In this case:

  1) If config files are given on the command line, then the first one
  given is used to save any such changes.
  
  2) If the config files are taken from kpsewhich output, then the
  algorithm is more complex:

    2a) If \$TEXMFCONFIG/web2c/updmap.cfg or \$TEXMFHOME/web2c/updmap.cfg
    appears in the list of used files, then the one listed first by
    kpsewhich --all (equivalently, the one returned by kpsewhich
    updmap.cfg), is used.
      
    2b) If neither of the above two are present and changes are made, a
    new config file is created in \$TEXMFCONFIG/web2c/updmap.cfg.
  
  In general, the idea is that if the user cannot write to a given
  config file, a higher-level one can be used.  That way, the
  distribution's settings can be overridden system-wide using
  TEXMFLOCAL, and system settings can be overridden again in a
  particular user's TEXMFHOME or TEXMFCONFIG.

Resolving multiple definitions of a font:

  If a font is defined in more than one map file, then the definition
  coming from the first-listed updmap.cfg is used.  If a font is
  defined multiple times within the same map file, one is chosen
  arbitrarily.  In both cases a warning is issued.

Disabling maps:

  updmap.cfg files with higher priority (listed earlier) can disable
  maps mentioned in lower priority (listed later) updmap.cfg files by
  writing, e.g.,
    \#! Map mapname.map
  or
    \#! MixedMap mapname.map
  in the higher-priority updmap.cfg file.  (The \#! must be at the
  beginning of the line, with at least one space or tab afterward, and
  whitespace between each word on the list.)

  As an example, suppose you have a copy of MathTime Pro fonts
  and want to disable the Belleek version of the fonts; that is,
  disable the map belleek.map.  You can create the file
  \$TEXMFCONFIG/web2c/updmap.cfg with the content
    #! Map belleek.map
    Map mt-plus.map
    Map mt-yy.map
  and call $prg.

Listing of maps:

  The two options --listmaps and --listavailablemaps list all maps
  defined in any of the updmap.cfg files (for --listmaps), and 
  only those actually found on the system (for --listavailablemaps).
  The output format is one line per font map, with the following
  fields separated by tabs: map, type (Map, MixedMap, KanjiMap),
  status (enabled, disabled), origin (the updmap.cfg file where
  it is mentioned, or 'builtin' for the three basic maps).

  In the case of --listmaps there can be one additional fields
  (again separated by tab) containing '(not available)' for those
  map files that cannot be found.
 
updmap-user vs. updmap-sys:

  When updmap-sys is run, TEXMFSYSCONFIG and TEXMFSYSVAR are used
  instead of TEXMFCONFIG and TEXMFVAR, respectively.  This is the
  primary difference between updmap-sys and updmap-user.

  Other locations may be used if you give them on the command line, or
  these trees don't exist, or you are not using the original TeX Live.

To see the precise locations of the various files that
will be read and written, give the -n option (or read the source).

The log file is written to TEXMFVAR/web2c/updmap.log.

For step-by-step instructions on making new fonts known to TeX, read
https://tug.org/fonts/fontinstall.html.  For even more terse
instructions, read the beginning of the main updmap.cfg file.

Report bugs to: tex-live\@tug.org
TeX Live home page: <https://tug.org/texlive/>
EOF
;
  print &version();
  print $usage;
  exit 0;
}

### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
