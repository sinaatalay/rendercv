#!/usr/bin/env perl
# $Id: uninstall-win32.pl 63068 2022-04-18 05:58:07Z preining $
# Copyright 2008, 2010, 2011, 2012, 2014 Norbert Preining
#
# GUI for tlmgr

my $Master;

BEGIN {
  $^W = 1;
  $Master = `%COMSPEC% /c kpsewhich -var-value=SELFAUTOPARENT`;
  chomp($Master);
  unshift (@INC, "$Master/tlpkg");
}

use TeXLive::TLWinGoo;
use TeXLive::TLPDB;
use TeXLive::TLPOBJ;
use TeXLive::TLConfig;
use TeXLive::TLUtils;

my $ans;

if (@ARGV) {
  $ans = 0;
} else {
  my $askfile = $0;
  $askfile =~ s!^(.*)([\\/])([^\\/]*)$!$1$2!;
  $askfile .= "uninstq.vbs";
  $ans = system("wscript", $askfile);
  # 0 means yes
}
if ($ans) {
  exit(1);
} else {
  doit();
}

sub doit {
  # first we remove the whole bunch of shortcuts and menu entries
  # by calling all the post action codes for the installed packages
  my $localtlpdb = TeXLive::TLPDB->new ("root" => $Master);
  if (!defined($localtlpdb)) {
    tlwarn("Cannot load the TLPDB from $Master, are you sure there is an installation?\n");
  } else {
    # set the mode for windows uninstall according to the setting in
    # tlpdb
    if (TeXLive::TLWinGoo::admin() && !$localtlpdb->option("w32_multi_user")) {
      non_admin();
    }
    for my $pkg ($localtlpdb->list_packages) {
      &TeXLive::TLUtils::do_postaction("remove", $localtlpdb->get_package($pkg),
                                   $localtlpdb->option("file_assocs"),
                                   $localtlpdb->option("desktop_integration"),
                                   $localtlpdb->option("desktop_integration"),
                                   $localtlpdb->option("post_code"));
    }
  }
  my $menupath = &TeXLive::TLWinGoo::menu_path();
  $menupath =~ s!/!\\!g;
  `rmdir /s /q "$menupath\\$TeXLive::TLConfig::WindowsMainMenuName" 2>nul`;

  # remove bindir from PATH settings
  TeXLive::TLUtils::w32_remove_from_path("$Master/bin/windows", 
    $localtlpdb->option("w32_multi_user"));

  # unsetenv_reg("TEXBINDIR");
  # unsetenv_reg("TEXMFSYSVAR");
  # unsetenv_reg("TEXMFCNF");
  TeXLive::TLWinGoo::unregister_uninstaller(
    $localtlpdb->option("w32_multi_user"));
  TeXLive::TLWinGoo::broadcast_env();
  TeXLive::TLWinGoo::update_assocs();
}

__END__


### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
