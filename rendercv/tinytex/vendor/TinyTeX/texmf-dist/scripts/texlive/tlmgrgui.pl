#!/usr/bin/env perl
# $Id: tlmgrgui.pl 65932 2023-02-19 20:49:48Z siepo $
#
# Copyright 2009-2019 Norbert Preining
# This file is licensed under the GNU General Public License version 2
# or any later version.
#
# GUI for tlmgr
# version 2, completely rewritten GUI
#
# TODO: implement path adjustment also for Windows

$^W = 1;
use strict;

my $guisvnrev = '$Revision: 65932 $';
my $guidatrev = '$Date: 2023-02-19 21:49:48 +0100 (Sun, 19 Feb 2023) $';
my $tlmgrguirevision;
if ($guisvnrev =~ m/: ([0-9]+) /) {
  $tlmgrguirevision = $1;
} else {
  $tlmgrguirevision = "unknown";
}
$guidatrev =~ s/^.*Date: //;
$guidatrev =~ s/ \(.*$//;
$tlmgrguirevision .= " ($guidatrev)";

use Tk;
use Tk::Dialog;
use Tk::Adjuster;
use Tk::BrowseEntry;
use Tk::ROText;
use Tk::HList;
use Tk::ItemStyle;
use File::Glob;

use Pod::Text;

#use Devel::Leak;

use TeXLive::TLUtils qw(setup_programs platform_desc wndws debug);
use TeXLive::TLConfig;

#
# GUI mode
#
our %config;
my $mode_expert = $config{"gui-expertmode"};

#
# stuff defined in tlmgr.pl that needs to be our-ed
our $Master;
our $remotetlpdb;
our $localtlpdb;
our $location;
our %opts;
our @update_function_list;

my $tlpdb_location;
my %tlpdb_repos;
my @tlpdb_tags;
my $cmdline_location;
my @critical_updates = ();

my $single_repo_mode = 1;
my %repos;
my @tags;

my $location_button; # uggg, change from far away ...

#
# shortcuts for padding, expand/fill, and pack sides, anchors
my @p_ii = qw/-padx 2m -pady 2m/;
my @p_iii= qw/-padx 3m -pady 3m/;
my @x_x = qw/-expand 1 -fill x/;
my @x_y = qw/-expand 1 -fill y/;
my @x_xy= qw/-expand 1 -fill both/;
my @left = qw/-side left/;
my @right= qw/-side right/;
my @bot  = qw/-side bottom/;
my @a_w = qw/-anchor w/;
my @a_c = qw/-anchor c/;
my @htype = qw/-relief ridge/;

#
# the list of packages as shown by TixGrid
#
my %Packages;
my $mw;
my $tlmgrrev;
my $menu;
my $menu_file;
my $menu_options;
my $menu_actions;
my $menu_help;

# default color for background
my $bgcolor;

#
# GUI elements
#
my $g;          # the scrolled list of packages
my $lighttext;
my $darktext;
my $match_entry;
my $loaded_text;
my $loaded_text_button;
my $default_repo;
my $update_all_button;

my %settings_label;

#
# communication between filters and the rest
my $status_all = 0;
my $status_only_installed = 1;
my $status_only_not_installed = 2;
my $status_only_updated = 3;
my $status_value = 0;
my $show_packages = 1;
my $show_collections = 1;
my $show_schemes = 1;
my $match_descriptions = 1;
my $match_filenames = 1;
my $match_text = "";
my $selection_value = 0;

# locale support moved to tlmgr.pl

my @archsavail;
my @archsinstalled;
my %archs;
my $currentarch;

my @fileassocdesc;
$fileassocdesc[0] = __("None");
$fileassocdesc[1] = __("Only new");
$fileassocdesc[2] = __("All");
my %defaults;
my %changeddefaults;

my %papers;
my %currentpaper;
my %changedpaper;
my %init_paper_subs;
$init_paper_subs{"xdvi"} = \&init_paper_xdvi;
$init_paper_subs{"pdftex"} = \&init_paper_pdftex;
$init_paper_subs{"dvips"} = \&init_paper_dvips;
$init_paper_subs{"context"} = \&init_paper_context;
$init_paper_subs{"dvipdfmx"} = \&init_paper_dvipdfmx;
$init_paper_subs{"psutils"} = \&init_paper_psutils;


guimain();

############# MAIN FUNCTION ##########################

sub guimain {
  build_initial_gui();
  init_hooks();

  info(__("Loading local TeX Live database") . 
       "\n  ($::maintree/$InfraLocation/$DatabaseName)\n" . 
       __("This may take some time, please be patient ...") . 
       "\n");

  # call the init function from tlmgr.pl
  # with 0 as argument, so that it does not call die on errors.
  init_local_db(0);
  # before this code was used, which is a duplication, and in addition
  # it does not handle auto-loading of $location
  #$localtlmedia = TeXLive::TLMedia->new ( $Master );
  #die("cannot setup TLMedia in $Master") unless (defined($localtlmedia));
  #$localtlpdb = $localtlmedia->tlpdb;
  #die("cannot find tlpdb!") unless (defined($localtlpdb));

  #
  # init_local_db sets up $location to the winning one:
  #  cmd line > tlpdb
  # save the two possible location for the menu
  $tlpdb_location = $localtlpdb->option("location");
  %tlpdb_repos = repository_to_array($tlpdb_location);
  @tlpdb_tags = keys %tlpdb_repos;
  if (defined($opts{"location"})) {
    $cmdline_location = $opts{"location"};
  }


  push @update_function_list, \&check_location_on_ctan;
  push @update_function_list, \&init_install_media;

  # already done by init_local_db above
  # setup_programs("$Master/tlpkg/installer", $localtlmedia->platform);

  #
  # check that we can actually save the database
  #
  if (check_on_writable()) {
    $::we_can_save = 1;
  } else {
    $::we_can_save = 0;
  }
  $::action_button_state = ($::we_can_save ? "normal" : "disabled");

  $tlmgrrev = give_version();
  chomp($tlmgrrev);

  setup_menu_system();
  do_rest_of_gui();
  $bgcolor = $loaded_text->cget('-background');

  setup_list();
  update_grid();


  if ($opts{"load"}) {
    setup_location($tlpdb_location);
  }


  info(__("... done loading") . ".\n");
  $mw->deiconify;


  if (!$::we_can_save) {
    my $no_write_warn = $mw->Dialog(-title => __("Warning"),
      -text => __("You don't have permissions to change the installation in any way;\nspecifically, the directory %s is not writable.\nPlease run this program as administrator, or contact your local admin.\n\nMost buttons will be disabled.", "$Master/tlpkg/"),
      -buttons => [ __("Ok") ])->Show();
  }

  Tk::MainLoop();
}


############## GUI ########################

sub build_initial_gui {
  # processed @::SAVEDARGV to replace 
  #  --font='foobar'
  # with 
  #  --font 'foobar'
  # as required by Tk::CmdLine.
  my @a;
  for my $c (@::SAVEDARGV) {
    if ($c =~ m/^--?(font|background|class|display|screen|foreground|geometry|name|title|xrm)=(.*)$/) {
      push @a, "--$1", $2;
    } else {
      push @a, $c;
    }
  }
  Tk::CmdLine::SetArguments(@a);
  $mw = MainWindow->new;
  $mw->title("TeX Live Manager $TeXLive::TLConfig::ReleaseYear");
  $mw->withdraw;

  #
  # default layout definitions
  #
  # priority 20 = widgetDefault 
  # see Mastering Perl/Tk, 16.2. Using the Option Database
  $mw->optionAdd("*Button.Relief", "ridge", 20);
  #
  # does not work, makes all buttons exactely 10, which is not a good idea
  # I would like to have something like MinWidth 10...
  #$mw->optionAdd("*Button.Width", "10", 20);

  # create a progress bar window
  $::progressw = $mw->Scrolled("ROText", -scrollbars => "e", -height => 4);
  $::progressw->pack(-fill => "x", @bot);
}

sub do_rest_of_gui {
  # This needs to come first as we call update_grid rather early
  #my $list_frame = $mw->Labelframe(-text => "Packages");
  my $gf = $mw->Frame;

  #my $list_frame = $mw->Frame;
  my $list_frame = $gf->Frame;
  $g = $list_frame->Scrolled('HList', -scrollbars => "se", -bd => 0,
        -command => \&show_extended_info, # does not work, double click!
        -columns => 5, -header => 1,
        -borderwidth => 1, #-padx => 0, -pady => 0,
        -separator => "/",
        -selectmode => "none");

  my $button_frame = $mw->Labelframe(-text => __("Repository"));
  $loaded_text = $button_frame->Label(-text => __("Loaded:") . " " . __("none"));
  $loaded_text->pack(@left, @p_ii);

  $loaded_text_button = $button_frame->Button(-text => __("Load default"),
    -command => sub { setup_location($tlpdb_location); });
  $loaded_text_button->pack( @left, @p_ii);

  my %repos = repository_to_array($tlpdb_location);
  my @tags = keys %repos;
  my $foo;
  if ($#tags > 0) {
    $foo = __("multiple repositories");
  } else {
    $foo = $tlpdb_location;
  }

  $default_repo = $button_frame->Label(-text => __("Default:") . " " . $foo );
  $default_repo->pack(@left, @p_ii);

  #$button_frame->pack(-expand => 1, -fill => 'x', @p_ii);

  #my $top_frame = $mw->Labelframe(-text => __("Display configuration"));
  my $top_frame = $gf->Labelframe(-text => __("Display configuration"));

  my $filter_frame = $top_frame->Frame();
  $filter_frame->pack(-expand => 1, -fill => 'both');

  my $filter_status = $filter_frame->Labelframe(-text => __("Status"));
  $filter_status->pack(@left, @x_y, @p_ii);

  $filter_status->Radiobutton(-text => __("all"), -command => \&update_grid,
    -variable => \$status_value, -value => $status_all)->pack(@a_w);
  $filter_status->Radiobutton(-text => __("installed"), -command => \&update_grid,
    -variable => \$status_value, -value => $status_only_installed)->pack(@a_w);
  $filter_status->Radiobutton(-text => __("not installed"), -command => \&update_grid,
    -variable => \$status_value, -value => $status_only_not_installed)->pack(@a_w);
  $filter_status->Radiobutton(-text => __("updates"), -command => \&update_grid,
    -variable => \$status_value, -value => $status_only_updated)->pack(@a_w);

  my $filter_category = $filter_frame->Labelframe(-text => __("Category"));
  if ($mode_expert) { $filter_category->pack(@left, @x_y, @p_ii); }
  $filter_category->Checkbutton(-text => __("packages"), -command => \&update_grid,
    -variable => \$show_packages)->pack(@a_w);
  $filter_category->Checkbutton(-text => __("collections"), -command => \&update_grid,
    -variable => \$show_collections)->pack(@a_w);
  $filter_category->Checkbutton(-text => __("schemes"), -command => \&update_grid,
    -variable => \$show_schemes)->pack(@a_w);

  my $filter_match = $filter_frame->Labelframe(-text => __("Match"));
  $filter_match->pack(@left, @x_y, @p_ii);
  $match_entry = 
    $filter_match->Entry(-width => 15, -validate => 'key',
                        )->pack(@a_w, -padx => '2m', @x_x);
  $filter_match->Checkbutton(-text => __("descriptions"),
          -command => \&update_grid,
          -variable => \$match_descriptions)->pack(@a_w);
  $filter_match->Checkbutton(-text => __("filenames"),
          -command => \&update_grid,
          -variable => \$match_filenames)->pack(@a_w);

  $match_entry->configure(-validate => 'key',
    -validatecommand => sub { 
      my ($new_val, undef, $old_val) = @_;
    #   if (!$new_val) {
    #     $match_descriptions = 0;
    #     $match_filenames = 0;
    #   } else {
    #    # if something is already in the search field don't change selection
    #     if (!$old_val) {
    #       $match_descriptions = 1;
    #       $match_filenames = 1;
    #     }
    #   }
      my $new_match_text = ( length($new_val) >= 3 ? $new_val : "" );
      if ($new_match_text ne $match_text) {
        $match_text = $new_match_text;
        update_grid(); 
      }
      return 1; });

  my $filter_selection = $filter_frame->Labelframe(-text => __("Selection"));
  if ($mode_expert) { $filter_selection->pack(@left, @x_y, @p_ii); }
  $filter_selection->Radiobutton(-text => __("all"), -command => \&update_grid,
                      -variable => \$selection_value, -value => 0)->pack(@a_w);
  $filter_selection->Radiobutton(-text => __("selected"), 
    -command => \&update_grid, -variable => \$selection_value, -value => 1)
    ->pack(@a_w);
  $filter_selection->Radiobutton(-text => __("not selected"), 
    -command => \&update_grid, -variable => \$selection_value, -value => 2)
    ->pack(@a_w);


  my $filter_button = $filter_frame->Frame;
  $filter_button->pack(@left, @x_y, @p_ii);
  if ($mode_expert) {
    $filter_button->Button(-text => __("Select all"), 
      -command => [ \&update_grid, 1 ])->pack(@x_x, @a_c);
    $filter_button->Button(-text => __("Select none"), 
      -command => [ \&update_grid, 0 ])->pack(@x_x, @a_c);
  }

  $filter_button->Button(-text => __("Reset filters"),
    -command => sub { $status_value = $status_all;
                      $show_packages = 1; $show_collections = 1; 
                      $show_schemes = 1;
                      $selection_value = 0;
                      $match_descriptions = 1;
                      $match_filenames = 1;
                      update_grid();
                    })->pack(@x_x, @a_c);

  ########## Packages #######################
  $g->pack(qw/-expand 1 -fill both -padx 3 -pady 3/);
  $g->focus;

  $lighttext = $g->ItemStyle('text', -background => 'gray90',
    -selectbackground => 'gray90', -selectforeground => 'blue');
  $darktext = $g->ItemStyle('text', -background => 'gray70',
    -selectbackground => 'gray70', -selectforeground => 'blue');


  $g->headerCreate(0, @htype, -itemtype => 'text', -text => "");
  $g->headerCreate(1, @htype, -itemtype => 'text', -text => __("Package name"));
  $g->headerCreate(2, @htype, -itemtype => 'text', -text => __("Local rev. (ver.)"));
  $g->headerCreate(3, @htype, -itemtype => 'text', -text => __("Remote rev. (ver.)"));
$g->headerCreate(4, @htype, -itemtype => 'text', -text => __("Short description"));

  $g->columnWidth(0, 40);
  $g->columnWidth(2, -char => 20);
  $g->columnWidth(3, -char => 20);

  my $bot_frame = $gf->Frame;
  #my $bot_frame = $mw->Frame;

  my $actions_frame = $bot_frame->Frame;
  $actions_frame->pack();

  my $with_all_frame = $actions_frame->Frame;
  $with_all_frame->pack(@left, -padx => '5m');
  $update_all_button =
    $with_all_frame->Button(-text => __('Update all installed'),
                            -state => $::action_button_state,
                            -command => sub { update_all_packages(); }
      )->pack(@p_ii);
  $with_all_frame->Checkbutton(-text => __("Reinstall previously removed packages"), 
    -variable => \$opts{"reinstall-forcibly-removed"})->pack();


  my $with_sel_frame = $actions_frame->Frame;
  $with_sel_frame->pack(@left, -padx => '5m');


  #
  # disable the with filter applied or not applied, it is too complicated, or?
  #

  if ($mode_expert) {
    $with_sel_frame->Button(-text => __('Update'),
                            -state => $::action_button_state,
                            -command => sub { update_selected_packages(); }
      )->pack(@left, @p_ii);
  }
  $with_sel_frame->Button(-text => __('Install'),
                          -state => $::action_button_state,
                          -command => sub { install_selected_packages(); }
    )->pack(@left, @p_ii);
  $with_sel_frame->Button(-text => __('Remove'),
                          -state => $::action_button_state,
                          -command => sub { remove_selected_packages(); }
    )->pack(@left, @p_ii);
  if ($mode_expert) {
    $with_sel_frame->Button(-text => __('Backup'),
                            -state => $::action_button_state,
                            -command => sub { backup_selected_packages(); }
      )->pack(@left, @p_ii);
  }

  $button_frame->pack(-expand => 0, -fill => 'x', @p_ii);
  $top_frame->pack(-fill => 'x', -padx => '2m');
  $bot_frame->pack(-fill => 'x', @p_ii, -side => 'bottom');
  $list_frame->pack(@x_xy, @p_ii);

  $mw->Adjuster(-widget => $::progressw, -side => 'bottom')
    ->pack(-side => 'bottom', -fill => 'x');

  $gf->pack(-side => 'top', -fill => 'both', -expand => 1);

}

########### LOGGING ETC FUNCTIONS #############

sub update_status_box {
  update_status(join(" ", @_));
  $mw->update;
}

sub init_hooks {
  push @::info_hook, \&update_status_box;
  push @::warn_hook, \&update_status_box;
  push @::debug_hook, \&update_status_box;
  push @::ddebug_hook, \&update_status_box;
  push @::dddebug_hook, \&update_status_box;
}

sub update_status {
  my ($p) = @_;
  $::progressw->insert("end", "$p");
  $::progressw->see("end");
}

############# GUI CALLBACKS ##################

sub setup_menu_system {
  $menu = $mw->Menu();
  $menu_file = $menu->Menu();
  $menu_options = $menu->Menu();
  $menu_actions = $menu->Menu();
  $menu_help = $menu->Menu();
  $menu->add('cascade', -label => "tlmgr", -menu => $menu_file);
  $menu->add('cascade', -label => __("Options"), -menu => $menu_options);
  if ($mode_expert) {
    $menu->add('cascade', -label => __("Actions"), -menu => $menu_actions);
  }
  # on win32 people expect to have the Help button on the right side
  if (wndws()) { $menu->add('separator'); }
  $menu->add('cascade', -label => __("Help"), -menu => $menu_help);

  #
  # FILE MENU
  #
  my %foo = repository_to_array($tlpdb_location);
  my @bar = keys %foo;
  my $tlpdb_location_string = $tlpdb_location;
  if ($#bar > 0) {
    $tlpdb_location_string = __("multiple repositories");
  }
  $menu_file->add('command', 
    -label => __("Load default (from tlpdb) repository:") . " $tlpdb_location_string",
    -command => sub { setup_location($tlpdb_location); });
  if (defined($cmdline_location)) {
    $menu_file->add('command', -label => __("Load cmd line repository:") . " $cmdline_location",
      -command => sub { setup_location($cmdline_location); });
  }
  $menu_file->add('command', -label => __("Load standard net repository:") . " $TeXLiveURL",
    -command => sub { setup_location($TeXLiveURL); });
  if ($mode_expert) {
    $menu_file->add('command', -label => __("Load other repository ..."),
      -command => \&cb_edit_location);
  }
  $menu_file->add('separator');
  $menu_file->add('command', -label => __("Quit"),
                             -command => sub { $mw->destroy; exit(0); });

  #
  # OPTIONS MENU
  #
  $menu_options->add('command', -label => __("General ..."),
    -command => sub { do_general_settings(); });
  $menu_options->add('command', -label => __("Paper ..."),
    -command => sub { do_paper_settings(); });
  if (!wndws() && $mode_expert) {
    $menu_options->add('command', -label => __("Platforms ..."),
      -command => sub { do_arch_settings(); });
  }
  if ($mode_expert) {
    $menu_options->add('command', -label => __("GUI language ..."),
      -command => sub { do_gui_language_setting(); });
  }
  $menu_options->add('separator');
  $menu_options->add('checkbutton', -label => __("Expert options"),
    -variable => \$mode_expert,
    -command => sub { do_and_warn_gui_mode_settings(); });
  if ($mode_expert) {
    $menu_options->add('checkbutton', -label => __("Enable debugging output"),
      -onvalue => ($::opt_verbosity == 0 ? 1 : $::opt_verbosity),
      -variable => \$::opt_verbosity);
    $menu_options->add('checkbutton', 
      -label => __("Disable auto-install of new packages"),
      -variable => \$opts{"no-auto-install"});
    $menu_options->add('checkbutton', 
      -label => __("Disable auto-removal of server-deleted packages"),
      -variable => \$opts{"no-auto-remove"});
  }

  #
  # Actions menu
  #
  $menu_actions->add('command', -label => __("Update filename database"),
    -state => $::action_button_state,
    -command => sub { 
                      $mw->Busy(-recurse => 1);
                      info("Running mktexlsr, this may take some time ...\n");
                      info(`mktexlsr 2>&1`); 
                      $mw->Unbusy;
                    });
  $menu_actions->add('command', -label => __("Rebuild all formats"),
    -state => $::action_button_state,
    -command => sub { 
                      $mw->Busy(-recurse => 1);
                      info("Running fmtutil-sys --all, this may take some time ...\n");
                      for my $l (`fmtutil-sys --all 2>&1`) {
                        info($l);
                        $mw->update;
                      }
                      $mw->Unbusy;
                    });
  $menu_actions->add('command', -label => __("Update font map database"),
    -state => $::action_button_state,
    -command => sub { 
                      $mw->Busy(-recurse => 1);
                      info("Running updmap-sys, this may take some time ...\n");
                      for my $l (`updmap-sys 2>&1`) {
                        info($l);
                        $mw->update;
                      }
                      $mw->Unbusy;
                    });

  $menu_actions->add('command', 
    -label => __("Restore packages from backup") . " ...",
    -state => $::action_button_state,
    -command => \&cb_handle_restore);

  if (!wndws()) {
    $menu_actions->add('command', 
      -label => __("Handle symlinks in system dirs") . " ...",
      -state => $::action_button_state,
      -command => \&cb_handle_symlinks);
  }
  if (!wndws()) {
    $menu_actions->add('separator');
    $menu_actions->add('command', -label => __("Remove TeX Live %s ...", $TeXLive::TLConfig::ReleaseYear),
      -state => $::action_button_state,
      -command => sub { 
        my $sw = $mw->DialogBox(-title => __("Remove TeX Live %s", $TeXLive::TLConfig::ReleaseYear),
                                -buttons => [ __("Ok"), __("Cancel") ],
                                -cancel_button => __("Cancel"),
                                -command => sub { 
                                  my $b = shift;
                                  if ($b eq __("Ok")) {
                                    system("tlmgr", "remove", "--all", "--force");
                                    $mw->Dialog(-text => __("Complete removal finished"), -buttons => [ __("Ok") ])->Show;
                                    $mw->destroy; 
                                    exit(0); 
                                  }
                                });
        $sw->add("Label", -text =>  __("Really remove (uninstall) the COMPLETE TeX Live %s installation?\nYour last chance to change your mind!", $TeXLive::TLConfig::ReleaseYear))->pack(@p_iii);
        $sw->Show;
      });
  }
  


  #
  # HELP MENU
  $menu_help->add('command', -label => __("Manual"), -command => \&pod_to_text);
  $menu_help->add('command', -label => __("About"),
    -command => sub {
      my $sw = $mw->DialogBox(-title => __("About"),
                              -buttons => [ __("Ok") ]);
      $sw->add("Label", -text => "TeX Live Manager

tlmgrgui revision $tlmgrguirevision
$tlmgrrev
Copyright 2009-2017 Norbert Preining

Licensed under the GNU General Public License version 2 or higher
In case of problems, please contact: texlive\@tug.org"
        )->pack(@p_iii);
      $sw->Show;
      });
 

  $mw->configure(-menu => $menu);
}

sub show_extended_info {
  my $p = shift;
  $g->selectionClear;
  $g->anchorClear;
  my $sw = $mw->Toplevel(-title => __("Details on:") . $p, @p_ii);
  $sw->transient($mw);

  my $tlp = $Packages{$p}{'tlp'};

  our $tf = $sw->Frame;
  my $bf = $sw->Frame;
  $tf->pack;
  $bf->pack(-pady => '3m');

  $tf->Label(-text => __("Package:"))->grid(
    $tf->Label(-text => $p), -sticky => "nw");
  $tf->Label(-text => __("Category:"))->grid(
    $tf->Label(-text => $tlp->category), -sticky => "nw");
  $tf->Label(-text => __("Short description:"))->grid(
    $tf->Label(-wraplength => '500', -justify => 'left',
    -text => $tlp->shortdesc), -sticky => "nw");
  # old version with ROText
  #my $t = $sw->Scrolled('ROText', -scrollbars => "oe", -height => 10,
  #  -width => 50, -wrap => 'word', -relief => 'flat');
  #$t->insert("1.0", $tlp->longdesc);
  #$sw->Label(-text => "Long desc:")->grid($t, -sticky => 'nw');
  $tf->Label(-text => __("Long description:"))->grid(
    $tf->Label(-wraplength => '500', -justify => 'left', 
      -text => $tlp->longdesc), -sticky => "nw");
  $tf->Label(-text => __("Installed:"))->grid(
    $tf->Label(-text => ($Packages{$p}{'installed'} ? __("Yes") : __("No"))),
    -sticky => "nw");
  $tf->Label(-text => __("Local revision:"))->grid(
    $tf->Label(-text => $Packages{$p}{'localrevision'}),
    -sticky => "nw");
  if (defined($Packages{$p}{'localcatalogueversion'})) {
    $tf->Label(-text => __("Local Catalogue version:"))->grid(
      $tf->Label(-text => $Packages{$p}{'localcatalogueversion'}),
      -sticky => "nw");
  }
  $tf->Label(-text => __("Remote revision:"))->grid(
    $tf->Label(-text => $Packages{$p}{'remoterevisionstring'}),
    -sticky => "nw");
  if (defined($Packages{$p}{'remotecatalogueversion'})) {
    $tf->Label(-text => __("Remote Catalogue version:"))->grid(
      $tf->Label(-text => $Packages{$p}{'remotecatalogueversion'}),
      -sticky => "nw");
  }
  if (defined($Packages{$p}{'keyword'})) {
    $tf->Label(-text => __("Keywords:"))->grid(
      $tf->Label(-text => $Packages{$p}{'keyword'}),
      -sticky => "nw");
  }
  if (defined($Packages{$p}{'functionality'})) {
    $tf->Label(-text => __("Functionality:"))->grid(
      $tf->Label(-text => $Packages{$p}{'functionality'}),
      -sticky => "nw");
  }
  if (defined($Packages{$p}{'primary'})) {
    $tf->Label(-text => __("Primary characterization:"))->grid(
      $tf->Label(-text => $Packages{$p}{'primary'}),
      -sticky => "nw");
  }
  if (defined($Packages{$p}{'secondary'})) {
    $tf->Label(-text => __("Secondary characterization:"))->grid(
      $tf->Label(-text => $Packages{$p}{'secondary'}),
      -sticky => "nw");
  }
  if ($remotetlpdb) {
    my @colls;
    if ($tlp->category ne "Collection" && $tlp->category ne "Scheme") {
      @colls = $remotetlpdb->needed_by($tlp->name);
    }
    @colls = grep {m;^collection-;} @colls;
    if (@colls) {
      $tf->Label(-text => __("Collection:"))->grid(
        $tf->Label(-text => "@colls"), -sticky => "nw");
    }
  }
  $tf->Label(-text => __("Warning: Catalogue versions might be lagging behind or be simply wrong."))->grid(-stick => "nw", -columnspan => 2);

  our %further_a;
  our %further_b;

  @{$further_a{$p}} = ();
  @{$further_b{$p}} = ();
  
  sub add_filelist_text {
    my $p = shift;
    my $text = shift;
    my @files = @_;
    if (@files) {
      my $t = "";
      for my $f (@files) { $t .= "$f\n"; }
      $t =~ s/\n$//;
      push @{$further_a{$p}}, $tf->Label(-text => $text);
      if ($#files >= 4) {
        my $foo = $tf->Scrolled('ROText', -scrollbars => "oe", -height => 5,
          -width => 50, -wrap => 'word', -relief => 'flat');
        $foo->insert("1.0", $t);
        push @{$further_b{$p}}, $foo;
      } else {
        push @{$further_b{$p}},
          $tf->Label(-wraplength => '500', -justify => 'left', -text => $t);
      }
    }
  }
  my @deps;
  my $do_arch;
  my @arch_deps;
  for my $d ($tlp->depends) {
    if ($d eq "$p.ARCH") {
      $do_arch = 1;
    } else {
      push @deps, $d;
    }
  }
  add_filelist_text($p, __("Depends:"), @deps);
  if ($do_arch) {
    my @archs = $localtlpdb->available_architectures;
    @arch_deps = map { "$p.$_"; } @archs;
    add_filelist_text($p, __("Binaries' dependencies:"), sort(@arch_deps));
  }
  add_filelist_text($p, __("Runfiles:"), $tlp->runfiles);
  add_filelist_text($p, __("Docfiles:"), $tlp->docfiles);
  add_filelist_text($p, __("Srcfiles:"), $tlp->srcfiles);
  my @binf = $tlp->allbinfiles;
  if ($do_arch) {
    for my $bp (@arch_deps) {
      my $tlpb = $localtlpdb->get_package($bp);
      if (!$tlpb) {
        tlwarn("Cannot find $bp.\n");
      } else {
        push @binf, $tlpb->allbinfiles;
      }
    }
  }
  add_filelist_text($p, __("Binfiles:"), @binf);

  my $f = $tf->Frame;
  my $fb = $f->Button(-padx => 0, -pady => 0,
    -text => "+", -borderwidth => 1, -relief => "ridge");
  my $ff = $f->Label(-text => "------ " . __("Further information") . " ------");
  $fb->grid($ff, -sticky => "nw");

  $f->grid(-sticky => "nw", -columnspan => 2);
  my $showdetails = 0;
  $fb->configure(-command =>
    sub {
      $showdetails = not($showdetails);
      if ($showdetails) {
        for my $i (0..$#{$further_a{$p}}) {
          ${$further_a{$p}}[$i]->grid(${$further_b{$p}}[$i], -sticky => "nw");
        }
      } else {
        for my $i (0..$#{$further_a{$p}}) {
          ${$further_a{$p}}[$i]->gridForget(${$further_b{$p}}[$i]);
        }
      }
    });


  $bf->Button(-text => __("Ok"), -width => 10,
    -command => sub { for (@{$further_a{$p}}) { $_->destroy; };
                      for (@{$further_b{$p}}) { $_->destroy; };
                      $sw->destroy; })->pack;
}

sub update_grid {
  # select code
  # if not given just do nothing
  # if == 1 select all packages that will be shown
  # if == 0 deselect all packages that will be shown
  my $selectcode = shift;

  my @schemes;
  my @colls;
  my @packs;
  for my $p (sort keys %Packages) {
    if ($Packages{$p}{'category'} eq "Scheme") {
      push @schemes, $p;
    } elsif ($Packages{$p}{'category'} eq "Collection") {
      push @colls, $p;
    } else {
      push @packs, $p;
    }
  }
  $g->delete('all');
  my $i = 0;
  my @displist;
  my $crit_match = 0;
  if (@critical_updates) {
    @displist = @critical_updates;
    $crit_match = 1;
    $lighttext->configure(-foreground => 'red');
    $darktext->configure(-foreground => 'red');
    $update_all_button->configure(-text => __('Update the TeX Live Manager'));
  } else {
    @displist = (@schemes, @colls, @packs);
  }
  my %match_hit;
  for my $p (@displist) {
    $match_hit{$p} = 1 if MatchesFilters($p);
  }
  my @match_keys = keys %match_hit;
  for my $p (@displist) {
    if ($crit_match || defined($match_hit{$p})) {
      if (defined($selectcode)) {
        $Packages{$p}{'selected'} = $selectcode;
      }
      $g->add($p);
      my $st = ($i%2 ? $lighttext : $darktext);
      $g->itemCreate($p, 0, -itemtype => 'window', 
        -widget => $Packages{$p}{'cb'});
      $Packages{$p}{'cb'}->configure(-background => ($i%2?'gray90':'gray70'));
      $g->itemCreate($p, 1, -itemtype => 'text', -style => $st, 
        -text => $Packages{$p}{'displayname'});
      my $t = ($Packages{$p}{'localrevision'} || '');
      if ($Packages{$p}{'localcatalogueversion'}) {
        $t .= " ($Packages{$p}{'localcatalogueversion'})";
      }
      $g->itemCreate($p, 2, -itemtype => 'text', -style => $st, -text => $t);
      $t = ($Packages{$p}{'remoterevisionstring'} || '');
      if ($Packages{$p}{'remotecatalogueversion'}) {
        $t .= " ($Packages{$p}{'remotecatalogueversion'})";
      }
      $g->itemCreate($p, 3, -itemtype => 'text', -style => $st, -text => $t);
      $g->itemCreate($p, 4, -itemtype => 'text', -style => $st,
        -text => $Packages{$p}{'tlp'}->shortdesc);
      $i++;
    }
  }
}

sub maybe_strip_last_plus {
  my $v = shift;
  if ($v =~ m/\+$/) {
    chop($v);
    # just for comparison add one to the version of there is a "+"
    $v++;
  }
  return $v;
}
  
sub MatchesFilters {
  my $p = shift;
  # we have to take care since strings in revision numbers on the remote
  # and might contain "+" indicating sub-package updates
  # status
  if (( ($status_value == $status_all) ) ||
      ( ($status_value == $status_only_installed) && 
        (defined($Packages{$p}{'installed'})) && 
        ($Packages{$p}{'installed'} == 1) ) ||
      ( ($status_value == $status_only_not_installed) &&
        ( !defined($Packages{$p}{'installed'}) ||
          ($Packages{$p}{'installed'} == 0)) ) ||
      ( ($status_value == $status_only_updated) &&
        (defined($Packages{$p}{'localrevision'})) &&
        (defined($Packages{$p}{'remoterevision'})) &&
        ($Packages{$p}{'localrevision'} < 
         maybe_strip_last_plus($Packages{$p}{'remoterevision'})))) {
    # do nothing, more checks have to be done
  } else {
    return 0;
  }
  # category
  if (($show_packages    && ($Packages{$p}{'category'} eq 'Other')) ||
      ($show_collections && ($Packages{$p}{'category'} eq 'Collection')) ||
      ($show_schemes     && ($Packages{$p}{'category'} eq 'Scheme')) ) {
    # do nothing, more checks have to be done
  } else {
    return 0;
  }
  #
  # match dealing
  #
  # * search string empty
  #   -> true
  # * search string non-empty
  #   + some search targets selected
  #     -> check
  #   + no search target selected
  #     -> show empty list (maybe show warning "select something")
  #
  if ($match_descriptions || $match_filenames) {
    my $found = 0;
    my $r = $match_text;
    if ($r eq "") {
      return 1;
    }
    # check first for the default search type, the descriptions
    # also match the remoterevisionstring to get search for repositories
    if ($match_descriptions) {
      if ($Packages{$p}{'match_desc'} =~ m/$r/i) {
        $found = 1;
      } elsif (defined($Packages{$p}{'remoterevisionstring'}) &&
               $Packages{$p}{'remoterevisionstring'} =~ m/$r/i) {
        $found = 1;
      }
    }
    # if we already found something, don't check the next condition!
    if (!$found) {
      if ($match_filenames) {
        if ($Packages{$p}{'match_files'} =~ m/$r/i) {
          $found = 1;
        }
      }
    } 
    if (!$found) {
      # not matched in either of the above cases, return 0 immediately
      return 0;
    }
    # otherwise more checks have to be done
  } else {
    if ($match_text eq "") {
      return 1;
    } else {
      # we could give a warning "select something" but HOW???
      return 0;
    }
  }
  # selection
  if ($selection_value == 0) {
    # all -> maybe more checks
  } elsif ($selection_value == 1) {
    # only selected
    if ($Packages{$p}{'selected'}) {
      # do nothing, maybe more checks
    } else {
      # not selected package and only selected packages shown
      return 0;
    }
  } else {
    # only not selected
    if ($Packages{$p}{'selected'}) {
      # selected, but only not selected should be shown
      return 0;
    } # else do nothing
  }
  # if we come down to here the package matches
  return 1;
}

############# ARCH HANDLING #####################

sub init_archs {
  if (!defined($remotetlpdb)) {
    @archsavail = $localtlpdb->available_architectures;
  } else {
    @archsavail = $remotetlpdb->available_architectures;
  }
  $currentarch = $localtlpdb->platform();
  @archsinstalled = $localtlpdb->available_architectures;
  foreach my $a (@archsavail) {
    $archs{$a} = 0;
    if (grep(/^$a$/,@archsinstalled)) {
      $archs{$a} = 1;
    }
  }
}


sub do_arch_settings {
  my $sw = $mw->Toplevel(-title => __("Select platforms to support"));
  my %archsbuttons;
  init_archs();
  $sw->transient($mw);
  $sw->grab();
  my $subframe = $sw->Labelframe(-text => __("Select platforms to support"));
  $subframe->pack(-fill => "both", -padx => "2m", -pady => "2m");
  foreach my $a (sort @archsavail) {
    $archsbuttons{$a} = 
      $subframe->Checkbutton(-command => sub { check_on_removal($sw, $a); },
                          -variable => \$archs{$a}, 
                          -text => platform_desc($a)
                         )->pack(-anchor => 'w');
  }
  my $arch_frame = $sw->Frame;
  $arch_frame->pack(-padx => "10m", -pady => "5m");
  $arch_frame->Button(-text => __("Apply changes"), 
    -state => $::action_button_state,
    -command => sub { apply_arch_changes(); $sw->destroy; })->pack(-side => 'left', -padx => "3m");
  $arch_frame->Button(-text => __("Cancel"), 
    -command => sub { $sw->destroy; })->pack(-side => 'left', -padx => "3m");
}

sub check_on_removal {
  my $arch_frame = shift;
  my $a = shift;
  if (!$archs{$a} && $a eq $currentarch) {
    # removal not supported
    $archs{$a} = 1;
    $arch_frame->Dialog(-title => __("Warning"),
                        -text => __("Removals of the main platform not possible!"),
                        -buttons => [ __("Ok") ])->Show;
  }
}

sub apply_arch_changes {
  my @todo_add;
  my @todo_remove;
  foreach my $a (@archsavail) {
    if (!$archs{$a} && grep(/^$a$/,@archsinstalled)) {
      push @todo_remove, $a;
      next;
    }
    if ($archs{$a} && !grep(/^$a$/,@archsinstalled)) {
      push @todo_add, $a;
      next;
    }
  }
  if (@todo_add) {
    execute_action_gui ( "platform", "add", @todo_add );
  }
  if (@todo_remove) {
    execute_action_gui ( "platform", "remove", @todo_remove );
  }
  if (@todo_add || @todo_remove) {
    reinit_local_tlpdb();
    init_archs();
  }
}


######### CONFIG HANDLING #############

sub init_defaults_setting {
  for my $key (keys %TeXLive::TLConfig::TLPDBOptions) {
    if ($TeXLive::TLConfig::TLPDBOptions{$key}->[0] eq "b") {
      $defaults{$key} = ($localtlpdb->option($key) ? 1 : 0);
    } else {
      $defaults{$key} = $localtlpdb->option($key);
    }
  }
  %changeddefaults = ();
  for my $k (keys %defaults) {
    $changeddefaults{$k}{'changed'} = 0;
    $changeddefaults{$k}{'value'}   = $defaults{$k};
    if ($TeXLive::TLConfig::TLPDBOptions{$k}->[0] eq "b") {
      $changeddefaults{$k}{'display'} = ($defaults{$k} ? __("Yes") : __("No"));
    } else {
      if ($k eq "file_assocs") {
        $changeddefaults{$k}{'display'} = $fileassocdesc[$defaults{$k}];
      } elsif ($k eq "location") {
        if ($#tlpdb_tags > 0) {
          # we are using multiple repositories
          $changeddefaults{$k}{'display'} = __("multiple repositories");
        } else {
          $changeddefaults{$k}{'display'} = $defaults{$k};
        }
      } else {
        $changeddefaults{$k}{'display'} = $defaults{$k};
      }
    }
  }
}

sub do_general_settings {
  my $sw = $mw->Toplevel(-title => __("General options"));
  $sw->transient($mw);
  $sw->grab();
  init_defaults_setting();

  my @config_set_l;
  my @config_set_m;
  my @config_set_r;

  my $back_config_set = $sw->Labelframe(-text => __("General options"));
  my $back_config_buttons = $sw->Frame();
  $back_config_set->pack(-fill => "both", -padx => "2m", -pady => "2m");

  push @config_set_l, 
    $back_config_set->Label(-text => __("Default package repository"), -anchor => "w");


  $location_button = $back_config_set->Button(-relief => 'flat',
    -textvariable => \$changeddefaults{"location"}{'display'});

  push @config_set_m, $location_button;
  push @config_set_r,
    $back_config_set->Button(-text => __("Change"), 
      -command => sub { menu_multi_location($sw); });

  if ($#tlpdb_tags > 0) {
    my @vals = map { "$_:$tlpdb_repos{$_}" } sort sort_main_first @tlpdb_tags;
    $location_button->configure(
      -command => sub { transient_show_multiple_repos($location_button, @vals); });
  }

  $settings_label{'location'} = $location_button;

  if ($mode_expert) {
    push @config_set_l,
      $back_config_set->Label(-text => __("Create formats on installation"), -anchor => "w");
    $settings_label{'create_formats'} = $back_config_set->Label(-textvariable => \$changeddefaults{"create_formats"}{'display'});
    push @config_set_m, $settings_label{'create_formats'};
    push @config_set_r,
      $back_config_set->Button(-text => __("Toggle"),
        -command => sub { toggle_setting("create_formats"); });
  
    push @config_set_l, $back_config_set->Label(-text => __("Install macro/font sources"), -anchor => "w");
    $settings_label{'install_srcfiles'} = $back_config_set->Label(-textvariable => \$changeddefaults{"install_srcfiles"}{'display'});
    push @config_set_m, $settings_label{'install_srcfiles'};
    push @config_set_r,
      $back_config_set->Button(-text => __("Toggle"),
        -command => sub { toggle_setting("install_srcfiles"); });

    push @config_set_l, $back_config_set->Label(-text => __("Install macro/font docs"), -anchor => "w");
    $settings_label{'install_docfiles'} = $back_config_set->Label(-textvariable => \$changeddefaults{"install_docfiles"}{'display'});
    push @config_set_m, $settings_label{'install_docfiles'};
    push @config_set_r,
      $back_config_set->Button(-text => __("Toggle"),
        -command => sub { toggle_setting("install_docfiles"); });

    push @config_set_l, $back_config_set->Label(-text => __("Default backup directory"), -anchor => "w");
    $settings_label{'backupdir'} = $back_config_set->Label(-textvariable => \$changeddefaults{"backupdir"}{'display'});
    push @config_set_m, $settings_label{'backupdir'};
    push @config_set_r,
      $back_config_set->Button(-text => __("Change"),
        -command => sub { edit_dir_option ($sw, "backupdir"); });

    push @config_set_l,
      $back_config_set->Label(-text => __("Auto backup setting"), -anchor => "w");
    $settings_label{'autobackup'} = $back_config_set->Label(-textvariable => \$changeddefaults{"autobackup"}{'display'});
    push @config_set_m, $settings_label{'autobackup'};
    push @config_set_r,
      $back_config_set->Button(-text => __("Change"),
        -command => sub { select_autobackup($sw); });

    if (!wndws()) {
      push @config_set_l,
        $back_config_set->Label(-text => __("Link destination for programs"), -anchor => "w");
      $settings_label{'sys_bin'} = $back_config_set->Label(-textvariable => \$changeddefaults{"sys_bin"}{'display'});
      push @config_set_m, $settings_label{'sys_bin'};
      push @config_set_r,
        $back_config_set->Button(-text => __("Change"),
          -command => sub { edit_dir_option ($sw, "sys_bin"); });

      push @config_set_l,
        $back_config_set->Label(-text => __("Link destination for info docs"), -anchor => "w");
      $settings_label{'sys_info'} = $back_config_set->Label(-textvariable => \$changeddefaults{"sys_info"}{'display'});
      push @config_set_m, $settings_label{'sys_info'};
      push @config_set_r,
        $back_config_set->Button(-text => __("Change"),
          -command => sub { edit_dir_option ($sw, "sys_info"); });

      push @config_set_l,
        $back_config_set->Label(-text => __("Link destination for man pages"), -anchor => "w");
      $settings_label{'sys_man'} = $back_config_set->Label(-textvariable => \$changeddefaults{"sys_man"}{'display'});
      push @config_set_m, $settings_label{'sys_man'};
      push @config_set_r,
        $back_config_set->Button(-text => __("Change"),
          -command => sub { edit_dir_option ($sw, "sys_man"); });
    }

    if (wndws()) {
      push @config_set_l,
        $back_config_set->Label(-text => __("Create shortcuts on the desktop"), -anchor => "w");
      $settings_label{'desktop_integration'} = $back_config_set->Label(-textvariable => \$changeddefaults{"desktop_integration"}{'display'});
      push @config_set_m, $settings_label{'desktop_integration'};
      push @config_set_r,
        $back_config_set->Button(-text => __("Toggle"),
          -command => sub { toggle_setting("desktop_integration"); });
  
      if (admin()) {
        push @config_set_l,
          $back_config_set->Label(-text => __("Install for all users"), -anchor => "w");
        $settings_label{'w32_multi_user'} = $back_config_set->Label(-textvariable => \$changeddefaults{"w32_multi_user"}{'display'});
        push @config_set_m, $settings_label{'w32_multi_user'};
        push @config_set_r,
          $back_config_set->Button(-text => __("Toggle"),
            -command => sub { toggle_setting("w32_multi_user"); });
      }
  
      push @config_set_l,
        $back_config_set->Label(-text => __("Change file associations"), -anchor => "w");
      $settings_label{'file_assocs'} = $back_config_set->Label(-textvariable => \$changeddefaults{'file_assocs'}{'display'});
      push @config_set_m, $settings_label{'file_assocs'};
      push @config_set_r,
        $back_config_set->Button(-text => __("Change"),
          -command => sub { select_file_assocs($sw); });
  
    }
  } # of $mode_export

  for my $i (0..$#config_set_l) {
    $config_set_l[$i]->grid( $config_set_m[$i], $config_set_r[$i],
                              -padx => "1m", -pady => "1m", -sticky => "nwe");
  }

  $back_config_buttons->pack(-padx => "10m", -pady => "5m");
  $back_config_buttons->Button(-text => __("Apply changes"), 
    -state => $::action_button_state,
    -command => sub { apply_settings_changes(); $sw->destroy; })->pack(-side => 'left', -padx => "3m");
  $back_config_buttons->Button(-text => __("Cancel"), 
    -command => sub { $sw->destroy; })->pack(-side => 'left', -padx => "3m");
}
  
sub apply_settings_changes {
  for my $k (keys %defaults) {
    if ($defaults{$k} ne $changeddefaults{$k}{'value'}) {
      $localtlpdb->option($k, $changeddefaults{$k}{'value'});
      if ($k eq "location") {
        # change interface to program, too
        # set default tlpdb location
        $tlpdb_location = $changeddefaults{'location'}{'value'};
        # update tlpdb_repos and tlpdb_tags accordingly
        %tlpdb_repos = repository_to_array($tlpdb_location);
        @tlpdb_tags = keys %tlpdb_repos;
        # change the menu entry in File->Load default...
        if ($#tlpdb_tags > 0) {
          my @vals = map { "$_:$tlpdb_repos{$_}" } 
            sort sort_main_first keys %tlpdb_repos;
          $menu_file->entryconfigure(1, -label => __("Load default repository:") . " " . __("multiple repositories"));
        } else {
          $menu_file->entryconfigure(1, -label => __("Load default repository:") . " $tlpdb_location");
        }
      }
    }
  }
  $localtlpdb->save;
}



########## PAPER HANDLING #################

sub init_paper_xdvi {
  if (!wndws()) {
    $papers{"xdvi"} = TeXLive::TLPaper::get_paper_list("xdvi");
    $currentpaper{"xdvi"} = $papers{"xdvi"}->[0];
  }
}
sub init_paper_pdftex {
  $papers{"pdftex"} = TeXLive::TLPaper::get_paper_list("pdftex");
  $currentpaper{"pdftex"} = $papers{"pdftex"}->[0];
}
sub init_paper_dvips {
  $papers{"dvips"} = TeXLive::TLPaper::get_paper_list("dvips");
  $currentpaper{"dvips"} = $papers{"dvips"}->[0];
}
sub init_paper_context {
  if (defined($localtlpdb->get_package("bin-context"))) {
    $papers{"context"} = TeXLive::TLPaper::get_paper_list("context");
    $currentpaper{"context"} = $papers{"context"}->[0];
  }
}
sub init_paper_dvipdfmx {
  $papers{"dvipdfmx"} = TeXLive::TLPaper::get_paper_list("dvipdfmx");
  $currentpaper{"dvipdfmx"} = $papers{"dvipdfmx"}->[0];
}

sub init_paper_psutils {
  $papers{"psutils"} = TeXLive::TLPaper::get_paper_list("psutils");
  $currentpaper{"psutils"} = $papers{"psutils"}->[0];
}


sub init_all_papers {
  for my $p (keys %init_paper_subs) {
    my $pkg = $TeXLive::TLPaper::paper{$p}{'pkg'};
    if ($localtlpdb->get_package($pkg)) {
      &{$init_paper_subs{$p}}();
    }
  }
}


sub do_paper_settings {
  # empty paper array
  %papers = ();
  init_all_papers();
  my $sw = $mw->Toplevel(-title => __("Paper options"));
  $sw->transient($mw);
  $sw->grab();
  
  %changedpaper = %currentpaper;

  my $lower = $sw->Frame;
  $lower->pack(-fill => "both");

  my $back_config_pap = $lower->Labelframe(-text => __("Paper options"));
  my $back_config_buttons = $sw->Frame();


  my $back_config_pap_l1 = $back_config_pap->Label(-text => __("Default paper for all"), -anchor => "w");
  my $back_config_pap_m1 = $back_config_pap->Button(-text => __("A4"),
    -command => sub { change_paper("all", "a4"); });
  my $back_config_pap_r1 = $back_config_pap->Button(-text => __("Letter"),
    -command => sub { change_paper("all", "letter"); });

  $back_config_pap_l1->grid( $back_config_pap_m1, $back_config_pap_r1,
    -padx => "2m", -pady => "2m", -sticky => "nswe");

  my (%l,%m,%r);
  if ($mode_expert) {
    foreach my $p (sort keys %papers) {
      if (($p eq "context") && !defined($localtlpdb->get_package("bin-context"))) {
        next;
      }
      $l{$p} = $back_config_pap->Label(-text => __("Default paper for %s", $p), -anchor => "w");
      $m{$p} = $back_config_pap->Label(-textvariable => \$changedpaper{$p}, -anchor => "w");
      $settings_label{$p} = $m{$p};
      $r{$p} = $back_config_pap->Button(-text => __("Change"),
        -command => sub { select_paper($sw,$p); }, -anchor => "w");
      $l{$p}->grid( $m{$p}, $r{$p},
        -padx => "2m", -pady => "2m", -sticky => "nsw");
    }
  }

  $back_config_pap->pack(-side => 'left', -fill => "both", -padx => "2m", -pady => "2m");

  $back_config_buttons->pack(-padx => "10m", -pady => "5m");
  $back_config_buttons->Button(-text => __("Apply changes"), 
    -state => $::action_button_state,
    -command => sub { apply_paper_changes(); $sw->destroy; })->pack(-side => 'left', -padx => "3m");
  $back_config_buttons->Button(-text => __("Cancel"), 
    -command => sub { $sw->destroy; })->pack(-side => 'left', -padx => "3m");
}

sub do_gui_language_setting {
  my $sw = $mw->Toplevel(-title => __("GUI Language"));
  my %code_lang = (
    cs => "Czech",
    de => "German",
    en => "English",
    es => "Spanish",
    fr => "French",
    it => "Italian",
    ja => "Japanese",
    nl => "Dutch",
    pl => "Polish",
    "pt_BR" => "Brasilian",
    ru => "Russian",
    sk => "Slovak",
    sl => "Slovenian",
    sr => "Serbian",
    uk => "Ukrainian",
    vi => "Vietnamese",
    "zh_CN" => "Simplified Chinese",
    "zh_TW" => "Traditional Chinese"
  );

  $sw->transient($mw);
  $sw->grab();
  my $var = __("System default");
  $var = $config{"gui-lang"} if (defined($config{"gui-lang"}));
  $var = $opts{"gui-lang"} if (defined($opts{"gui-lang"}));
  $var = (defined($code_lang{$var}) ? $code_lang{$var} : $var);
  my $opt = $sw->BrowseEntry(-label => __("Default language for GUI:"), -variable => \$var);
  $opt->insert(0, __("System default"));
  my @ll;
  foreach my $p (<$Master/tlpkg/translations/*.po>) {
    $p =~ s!^.*translations/!!;
    $p =~ s!\.po$!!;
    push @ll, $p;
  }
  # add English as possible language!
  push @ll, "en";
  foreach my $l (sort @ll) {
    my $el = (defined($code_lang{$l}) ? $code_lang{$l} : $l);
    $opt->insert("end", $el);
  }
  $opt->pack(-padx => "2m", -pady => "2m");
  $sw->Label(-text => __("Changes will take effect after restart"))->pack(-padx => "2m", -pady => "2m");
  my $f = $sw->Frame;
  my $okbutton = $f->Button(-text => __("Ok"), 
    -command => sub { 
      if ($var eq __("System default")) {
        # we have to remove the setting in the config file
        delete($config{'gui-lang'});
        write_config_file();
      } else {
        for my $l (keys %code_lang) {
          if ($code_lang{$l} eq $var) {
            if (!defined($config{'gui-lang'}) ||
                (defined($config{'gui-lang'}) && ($config{'gui-lang'} ne $l))) {
              $config{'gui-lang'} = $l;
              write_config_file();
            }
            last;
          }
        }
      }
      $sw->destroy; 
    })->pack(-side => "left", -padx => "2m", -pady => "2m");
  my $cancelbutton = $f->Button(-text => __("Cancel"), -command => sub { $sw->destroy; })->pack(-side => "left", -padx => "2m", -pady => "2m");
  $f->pack;
  $sw->bind('<Return>', [ $okbutton, 'Invoke' ]);
  $sw->bind('<Escape>', [ $cancelbutton, 'Invoke' ]);
}

sub do_and_warn_gui_mode_settings {
  my $ans = $mw->Dialog(-text => __("Changes will take effect after restart"),
    -title => __("Expert options"),
    -default_button => 'Ok',
    -buttons => [__("Ok"), __("Cancel")])->Show;
  if ($ans eq __("Ok")) {
    $config{"gui-expertmode"} = $mode_expert;
    write_config_file();
  }
}

sub ask_one_repository {
  my ($mw, $title, $info) = @_;
  my $val;
  my $done;
  my $sw = $mw->Toplevel(-title => $title);
  $sw->transient($mw);
  $sw->withdraw;
  $sw->Label(-text => $info)->pack(-padx => "2m", -pady => "2m");

  my $f1 = $sw->Frame;
  my @mirror_list;
  push @mirror_list, "  " . __("Default remote repository") . ": http://mirror.ctan.org";
  push @mirror_list, TeXLive::TLUtils::create_mirror_list();
  my $entry = $f1->BrowseEntry(
    -listheight => 12, 
    -listwidth => 400,
    -width => 50,
    -autolistwidth => 1,
    -choices => \@mirror_list,
    -browsecmd => 
      sub {
        if ($val !~ m/^  /) {
          $val = "";
        } elsif ($val =~ m!(http|ftp)://!) {
          $val = TeXLive::TLUtils::extract_mirror_entry($val);
        } else {
          $val =~ s/^\s*//;
        }
      },
    -variable => \$val)->pack(-side => "left",-padx => "2m", -pady => "2m");

  #my $entry = $f1->Entry(-text => $val, -width => 50);
  #$entry->pack(-side => "left",-padx => "2m", -pady => "2m");

  my $f2 = $sw->Frame;
  $f2->Button(-text => __("Choose directory"), 
    -command => sub {
                      $val = $sw->chooseDirectory;
                      #if (defined($var)) {
                      #  $entry->delete(0,"end");
                      #  $entry->insert(0,$var);
                      #}
                    })->pack(-side => "left",-padx => "2m", -pady => "2m");
  $f2->Button(-text => __("Default remote repository"),
    -command => sub {
                      #$entry->delete(0,"end");
                      #$entry->insert(0,$TeXLiveURL);
                      $val = $TeXLiveURL;
                    })->pack(-side => "left",-padx => "2m", -pady => "2m");
  $f1->pack;
  $f2->pack;

  my $f = $sw->Frame;
  my $okbutton = $f->Button(-text => __("Ok"), 
    -command => sub { $done = 1; }
    )->pack(-side => 'left',-padx => "2m", -pady => "2m");
  my $cancelbutton = $f->Button(-text => __("Cancel"), 
    -command => sub { $val = undef; $done = 1; }
    )->pack(-side => 'right',-padx => "2m", -pady => "2m");
  $f->pack(-expand => 'x');
  $sw->bind('<Return>', [ $okbutton, 'Invoke' ]);
  $sw->bind('<Escape>', [ $cancelbutton, 'Invoke' ]);
  my $old_focus = $sw->focusSave;
  my $old_grab = $sw->grabSave;
  $sw->Popup;
  $sw->grab;
  $sw->waitVariable(\$done);
  $sw->grabRelease if Tk::Exists($sw);
  $sw->destroy if Tk::Exists($sw);
  return $val;
}

#sub menu_default_location {
#  my $mw = shift;
#  my $ret = ask_one_repository($mw, __("Change default package repository"),
#    __("New default package repository"));
#  if (defined($ret)) {
#     $changeddefaults{'location'}{'value'} = 
#       $changeddefaults{'location'}{'display'} = $ret;
#  }
#}

sub sort_main_first {
  if ($a eq 'main') {
    if ($b eq 'main') {
      return 0;
    } else {
      return -1;
    }
  } else {
    if ($b eq 'main') {
      return 1;
    } else {
      return ($a cmp $b);
    }
  }
}

sub menu_multi_location {
  my $mw = shift;
  my $val;
  our $sw = $mw->Toplevel(-title => __("Edit default package repositories"));
  $sw->transient($mw);
  $sw->grab();
  $sw->Label(-text => __("Specify set of repositories to be used"))->pack(-padx => "2m", -pady => "2m");

  our $f1 = $sw->Frame;
  my @entry_tag; our $tagw = 10;
  my @entry_loc; our $locw = 30;
  my @entry_del;
  my @entry_chg;

  my $addrepo_button;


  sub add_buttons {
    my ($ref) = @_;
    my $t = $ref->{'tag'};
    $ref->{'tag_w'} = $f1->Entry(-textvariable => \$ref->{'tag'}, -state => ($t eq "main" ? 'readonly' : 'normal'), -width => $tagw);
    $ref->{'val_w'} = $f1->Entry(-textvariable => \$ref->{'val'}, -width => $locw);
    $ref->{'del_w'} = $f1->Button(-text => __("Delete"),
      -state => ($t eq "main" ? 'disabled' : 'normal'),
      -command => sub {
        $ref->{'status'} = 0;
        $ref->{'tag_w'}->configure(-state => 'disabled');
        $ref->{'val_w'}->configure(-state => 'disabled');
        $ref->{'del_w'}->configure(-state => 'disabled');
        $ref->{'chg_w'}->configure(-state => 'disabled');
      });
    $ref->{'chg_w'} = $f1->Button(-text => __("Change"),
      -command => sub {
        our $sw;
        my $ret = ask_one_repository($sw, 
          ($t eq "main" ?
            __("Change main package repository") :
            __("Change subsidiary package repository")),
          ($t eq "main" ?
            __("Change main package repository") :
            __("Change subsidiary package repository")));
        $ref->{'val'} = $ret if (defined($ret));
      });
  }

  my %changed_repos = repository_to_array($changeddefaults{'location'}{'value'});

  my @edit_repos;
  push @edit_repos, { 'tag' => 'main', 'val' => $changed_repos{'main'}, 'status' => 1};
  for my $k (sort keys %changed_repos) {
    next if ($k eq "main");
    push @edit_repos, { 'tag'=> $k, 'val' => $changed_repos{$k}, 'status' => 1 };
  }
  for my $ref (@edit_repos) {
    add_buttons($ref);
  }
  for my $ref (@edit_repos) {
    my %foo = %$ref;
    $foo{'tag_w'}->grid($foo{'val_w'}, $foo{'del_w'}, $foo{'chg_w'},
       -padx => "1m", -pady => "1m", -sticky => "nwe");
  }
  $addrepo_button = $f1->Button(-text => __("Add repository") . "...",
    -command => sub { 
      my $ret = ask_one_repository($sw, __("Add package repository"),
        __("Add package repository"));
      if (defined($ret)) {
        $addrepo_button->gridForget;
        my %foo = ( 'tag' => $ret, 'val' => $ret, 'status' => 1 );
        add_buttons(\%foo);
        $foo{'tag_w'}->grid($foo{'val_w'}, $foo{'del_w'}, $foo{'chg_w'},
          -padx => "1m", -pady => "1m", -sticky => "nwe");
        push @edit_repos, \%foo;
      }
      $addrepo_button->grid(-columnspan => 2, -column => 2);
    });
  $addrepo_button->grid(-columnspan => 2, -column => 2);

  $f1->pack;

  my $f = $sw->Frame;
  my $okbutton = $f->Button(-text => __("Ok"), 
    -command => 
      sub { 
        # we have to check if something has changed ... and for consistency!!!
        my %new_repos;
        for my $ref (@edit_repos) {
          my %foo = %$ref;
          if ($foo{'status'}) {
            if (defined($new_repos{$foo{'tag'}})) {
              $sw->Dialog(-title => __("Warning"),
                -text => __("Repository tag name already used: %s", $foo{'tag'}), -buttons => [ __("Ok") ])->Show;
              return;
            }
            $new_repos{$foo{'tag'}} = $foo{'val'};
          }
        }
        my $differs = 0;
        for my $k (keys %changed_repos) {
          if (!defined($new_repos{$k})) {
            $differs = 1;
            last;
          }
          if ($changed_repos{$k} ne $new_repos{$k}) {
            $differs = 1;
            last;
          }
        }
        if (!$differs) {
          # do the same the other way round
          for my $k (keys %new_repos) {
            if (!defined($changed_repos{$k})) {
              $differs = 1;
              last;
            }
            if ($changed_repos{$k} ne $new_repos{$k}) {
              $differs = 1;
              last;
            }
          }
        }

        if ($differs) {
          # print "current repos:\n";
          # for my $ref (@edit_repos) {
          #   print "tag = $ref->{'tag'}\n";
          #   print "val = $ref->{'val'}\n";
          #   print "act = $ref->{'status'}\n";
          # }
          $changeddefaults{'location'}{'value'} = array_to_repository(%new_repos);
          my @vals = map { "$_:$new_repos{$_}" } 
            sort sort_main_first keys %new_repos;
          if ($#vals > 0) {
            $location_button->configure(
              -command => sub { transient_show_multiple_repos($location_button, @vals); });
            $changeddefaults{'location'}{'display'} = __("multiple repositories");
          } else {
            $changeddefaults{'location'}{'display'} = $changeddefaults{'location'}{'value'};
          }
        } else {
          # print "Nothing happend!\n";
        }
        $location_button->configure(-background =>
          ($changeddefaults{'location'}{'value'} eq $defaults{'location'} ?
            $bgcolor : 'red'));
        $sw->destroy;
      })->pack(-side => 'left',-padx => "2m", -pady => "2m");
  my $cancelbutton = $f->Button(-text => __("Cancel"), 
          -command => sub { $sw->destroy })->pack(-side => 'right',-padx => "2m", -pady => "2m");
  my $resetbutton = $f->Button(-text => __("Revert"), 
          -command => sub { $sw->destroy; menu_multi_location($mw); })->pack(-side => 'right',-padx => "2m", -pady => "2m");
  $f->pack(-expand => 'x');
  $sw->bind('<Return>', [ $okbutton, 'Invoke' ]);
  $sw->bind('<Escape>', [ $cancelbutton, 'Invoke' ]);
}

sub toggle_setting() {
  my ($key) = @_;
  my $old = $changeddefaults{$key}{'value'};
  my $new = ($old ? 0 : 1);
  $changeddefaults{$key}{'display'} = ($new ? __("Yes") : __("No"));
  $changeddefaults{$key}{'value'} = $new;
  if (defined($settings_label{$key})) {
    if ($defaults{$key} ne $changeddefaults{$key}{'value'}) {
      $settings_label{$key}->configure(-background => 'red');
    } else {
      $settings_label{$key}->configure(-background => $bgcolor);
    }
  }
}


sub apply_paper_changes {
  $mw->Busy(-recurse => 1);
  for my $k (keys %changedpaper) {
    if ($currentpaper{$k} ne $changedpaper{$k}) {
      execute_action_gui ( "paper", $k, "paper", $changedpaper{$k});
      &{$init_paper_subs{$k}}();
    }
  }
  $mw->Unbusy;
}

sub change_paper {
  my ($prog, $pap) = @_;
  if ($prog eq "all") {
    for my $k (keys %changedpaper) {
      $changedpaper{$k} = $pap;
      $settings_label{$k}->configure(-background =>
        ($changedpaper{$k} eq $currentpaper{$k} ? $bgcolor : 'red'));
    }
  } else {
    $changedpaper{$prog} = $pap;
    $settings_label{$prog}->configure(-background =>
      ($changedpaper{$prog} eq $currentpaper{$prog} ? $bgcolor : 'red'));
  }
}

sub select_paper {
  my $back_config = shift;
  my $prog = shift;
  my $foo = $back_config->Toplevel(-title => __("Select paper format for %s", $prog));
  $foo->transient($back_config);
  $foo->grab();
  my $var = $changedpaper{$prog};
  my $opt = $foo->BrowseEntry(-label => __("Default paper for %s", $prog), -variable => \$var);
  foreach my $p (sort @{$papers{$prog}}) {
    $opt->insert("end",$p);
  }
  $opt->pack(-padx => "2m", -pady => "2m");
  my $f = $foo->Frame;
  my $okbutton = $f->Button(-text => __("Ok"), -command => sub { change_paper($prog,$var); $foo->destroy; })->pack(-side => "left", -padx => "2m", -pady => "2m");
  my $cancelbutton = $f->Button(-text => __("Cancel"), -command => sub { $foo->destroy; })->pack(-side => "left", -padx => "2m", -pady => "2m");
  $f->pack;
  $foo->bind('<Return>', [ $okbutton, 'Invoke' ]);
  $foo->bind('<Escape>', [ $cancelbutton, 'Invoke' ]);
}

sub select_autobackup {
  my $mw = shift;
  my $foo = $mw->Toplevel(-title => __("Auto backup setting"));
  $foo->transient($mw);
  $foo->grab();
  #my $var = $defaults{"autobackup"};
  my $var = $changeddefaults{"autobackup"}{'value'};
  my $opt = $foo->BrowseEntry(-label => __("Auto backup setting"), 
                              -variable => \$var);
  my @al;
  push @al, "-1 (" . __("keep arbitrarily many") . ")";
  push @al, "0  (" . __("disable") . ")";
  for my $i (1..100) {
    push @al, $i;
  }
  foreach my $p (@al) {
    $opt->insert("end",$p);
  }
  $opt->pack(-padx => "2m", -pady => "2m");
  my $f = $foo->Frame;
  my $okbutton = $f->Button(-text => __("Ok"), 
        -command => sub { 
                          $var =~ s/ .*$//;
                          $changeddefaults{"autobackup"}{'value'} = $var;
                          $changeddefaults{"autobackup"}{'display'} = $var;
                          $settings_label{'autobackup'}->configure(
                            -background => 
                              ($var eq $defaults{"autobackup"} ? $bgcolor : 'red'));
                          $foo->destroy;
                        }
     )->pack(-side => "left", -padx => "2m", -pady => "2m");
  my $cancelbutton = $f->Button(-text => __("Cancel"), -command => sub { $foo->destroy; })->pack(-side => "left", -padx => "2m", -pady => "2m");
  $f->pack;
  $foo->bind('<Return>', [ $okbutton, 'Invoke' ]);
  $foo->bind('<Escape>', [ $cancelbutton, 'Invoke' ]);
}


sub select_file_assocs {
  my $sw = shift;
  my $foo = $sw->Toplevel(-title => __("Change file associations"));
  $foo->transient($mw);
  $foo->grab();
  my $var = $defaults{"file_assocs"};
  my $opt = $foo->BrowseEntry(-label => __("Change file associations"), 
                              -variable => \$var);
  my @al;
  for my $i (0..2) {
    push @al, "$i $fileassocdesc[$i]";
  }
  foreach my $p (@al) {
    $opt->insert("end",$p);
  }
  $opt->pack(-padx => "2m", -pady => "2m");
  my $f = $foo->Frame;
  my $okbutton = $f->Button(-text => __("Ok"), 
        -command => sub { 
                          $var = substr($var,0,1);
                          $changeddefaults{"file_assocs"}{'display'} = $fileassocdesc[$var];
                          $changeddefaults{"file_assocs"}{'value'} = $var;

                          $foo->destroy;
                        }
     )->pack(-side => "left", -padx => "2m", -pady => "2m");
  my $cancelbutton = $f->Button(-text => __("Cancel"), -command => sub { $foo->destroy; })->pack(-side => "left", -padx => "2m", -pady => "2m");
  $f->pack;
  $foo->bind('<Return>', [ $okbutton, 'Invoke' ]);
  $foo->bind('<Escape>', [ $cancelbutton, 'Invoke' ]);
}


 
############################

sub setup_location {
  my $loc = shift;
  $location = $loc; 
  # first check if $location contains multiple locations
  # in this case we go to virtual mode
  %repos = ();
  %repos = repository_to_array($location);
  @tags = keys %repos;
  if ($#tags == 0) {
    $single_repo_mode = 1;
  } else {
    $single_repo_mode = 0;
  }
  run_update_functions(); 
}

sub init_install_media {
  my $newroot = $location;
  if (defined($remotetlpdb) && !$remotetlpdb->is_virtual &&
      ($remotetlpdb->root eq $newroot)) {
    # nothing to be done
  } else {
    $mw->Busy(-recurse => 1);
    my ($ret, $err) = init_tlmedia();
    $mw->Unbusy;
    if (!$ret) {
      # something went badly wrong, maybe the newroot is wrong?
      $mw->Dialog(-title => __("Warning"),
        -text => __("Loading of remote database failed.") . "\n" .
                 __("Error message:") . "\n$err\n\n",
        -buttons => [ __("Ok") ])->Show;
      $remotetlpdb = undef;
      update_list_remote();
      update_grid();
      update_loaded_location_string("none");
    } else {
      update_list_remote();
      update_grid();
      update_loaded_location_string($location);
    }
  }
}

sub set_text_win {
  my ($w, $t) = @_;
  $w->delete("0.0", "end");
  $w->insert("0.0", "$t");
  $w->see("0.0");
}

sub install_selected_packages {
  my @foo = SelectedPackages();
  if (@foo) {
    # that doesn't hurt if it is already loaded
    # it does hurt when there are critical updates ... so don't do it
    #init_install_media();
    my @args = qw/install/;
    push @args, @foo;
    execute_action_gui(@args);
    reinit_local_tlpdb();
    # now we check that the installation has succeeded by checking that 
    # all packages in @_ are installed. Otherwise we pop up a warning window
    my $do_warn = 0;
    for my $p (@_) {
      if (!defined($localtlpdb->get_package($p))) {
        $do_warn = 1;
        last;
      }
    }
    give_warning_window(__("Installation"), @_) if $do_warn;
  }
}

sub SelectedPackages {
  my @ret;
  # first select those that are
  for my $p (keys %Packages) {
    next if !$Packages{$p}{'selected'};
    if (MatchesFilters($p)) {
      push @ret, $p;
    }
  }
  return @ret;
}

sub critical_updates_done_msg_and_end {
  # terminate here immediately so that we are sure the auto-updater
  # is run immediately
  # warn that program will now be terminated
  $mw->Dialog(-title => __("Warning"),
    -text => __("Critical updates have been installed.\nProgram will terminate now.\nPlease restart if necessary."),
    -buttons => [ __("Ok") ])->Show;
  # also delete the main window before we kill the process to 
  # make sure that Tk is happy (segfault on cmd line, email Taco)
  $mw->destroy;
  # don't call finish(0) as we need to exit immediately
  exit(0); 
}
  
sub update_all_packages {
  my @args = qw/update/;
  if (@critical_updates) {
    $opts{"self"} = 1;
  } else {
    $opts{"all"} = 1;
  }
  # that doesn't hurt if it is already loaded
  # it does hurt when there are critical updates ... so don't do it
  #init_install_media();
  execute_action_gui(qw/update/);
  if (@critical_updates) {
    critical_updates_done_msg_and_end();
  }
  reinit_local_tlpdb();
}
    
sub update_selected_packages {
  my @foo = SelectedPackages();
  if (@foo) {
    # that doesn't hurt if it is already loaded
    # it does hurt when there are critical updates ... so don't do it
    #init_install_media();
    my @args = qw/update/;
    # argument processing
    # in case we have critical updates present we do put the list of
    # critical updates into the argument instead of --all
    if (@critical_updates) {
      $opts{"self"} = 1;
    }
    push @args, @foo;
    execute_action_gui(@args);
    if (@critical_updates) {
      critical_updates_done_msg_and_end();
    }
    reinit_local_tlpdb();
  }
}

sub remove_selected_packages {
  my @foo = SelectedPackages();
  if (@foo) {
    my @args = qw/remove/;
    push @args, @foo;
    execute_action_gui(@args);
    reinit_local_tlpdb();
    my $do_warn = 0;
    for my $p (@_) {
      if (defined($localtlpdb->get_package($p))) {
        $do_warn = 1;
        last;
      }
    }
    give_warning_window(__("Remove"), @_) if $do_warn;
  }
}

sub backup_selected_packages {
  my @foo = SelectedPackages();
  if (@foo) {
    my @args = qw/backup/;
    push @args, @foo;
    execute_action_gui(@args);
  }
}

sub reinit_local_tlpdb {
  $mw->Busy(-recurse => 1);
  $localtlpdb = TeXLive::TLPDB->new ("root" => "$Master");
  die("cannot find tlpdb!") unless (defined($localtlpdb));
  setup_list();
  update_grid();
  $mw->Unbusy;
}

#
# sub populate_Packages
#
sub populate_Packages {
  my ($mode, $tlp, $maxtag) = @_;
  my $p = $tlp->name;
  $Packages{$p}{'displayname'}   = $p;
  if ($mode eq "local") {
    $Packages{$p}{'localrevision'} = $tlp->revision;
    $Packages{$p}{'installed'}     = 1;
    $Packages{$p}{'selected'}      = 0;
    delete($Packages{$p}{'tlp'}) if defined($Packages{$p}{'tlp'});
    $Packages{$p}{'tlp'}           = $tlp;
  } else {
    $Packages{$p}{'remoterevision'} = $tlp->revision;
    $Packages{$p}{'remoterevisionstring'} = $tlp->revision;
    if ($remotetlpdb->is_virtual) {
      $Packages{$p}{'remoterevisionstring'} .= "\@$maxtag";
    }
    $Packages{$p}{'selected'}      = 0
      unless defined $Packages{$p}{'selected'};
    if (!defined($Packages{$p}{'tlp'})) {
      $Packages{$p}{'tlp'}           = $tlp;
    }
  }
  $Packages{$p}{'match_desc'}    = "$p\n";
  $Packages{$p}{'match_desc'}    .= ($tlp->shortdesc || "");
  $Packages{$p}{'match_desc'}    .= "\n";
  $Packages{$p}{'match_desc'}    .= ($tlp->longdesc || "");
  #
  # file matching
  my @all_f = $tlp->all_files;
  if ($tlp->relocated) { for (@all_f) { s:^$RelocPrefix/:$RelocTree/:; } }
  $Packages{$p}{'match_files'}   = "@all_f";
  if ($mode eq "local") {
    $Packages{$p}{'cb'}->destroy() if defined($Packages{$p}{'cb'});
    $Packages{$p}{'cb'}            = $g->Checkbutton(-variable => \$Packages{$p}{'selected'});
  } else {
    $Packages{$p}{'cb'}            = $g->Checkbutton(-variable => \$Packages{$p}{'selected'})
            unless defined $Packages{$p}{'cb'};
  }
  if (($tlp->category eq "Collection") ||
      ($tlp->category eq "Scheme")) {
    $Packages{$p}{'category'}      = $tlp->category;
  } else {
    $Packages{$p}{'category'}      = "Other";
  }
  if (defined($tlp->cataloguedata->{'version'})) {
    if ($mode eq "local") {
      $Packages{$p}{'localcatalogueversion'} = $tlp->cataloguedata->{'version'};
    } else {
      $Packages{$p}{'remotecatalogueversion'} = $tlp->cataloguedata->{'version'};
    }
  }
}

#
# creates/updates the list of packages as shown in tix grid
# 
sub setup_list {
  my @do_later;
  for my $p ($localtlpdb->list_packages()) {
    # skip 00texlive packages
    next if ($p =~ m!^00texlive!);
    # collect packages containing a . for later
    # we want to ignore them in most cases but those where there is 
    # no father package (without .)
    if ($p =~ m;\.;) {
      push @do_later, $p;
      next;
    }
    my $tlp = $localtlpdb->get_package($p);
    populate_Packages("local", $tlp);
  }
  my @avail_arch = $localtlpdb->available_architectures;
  for my $p (@do_later) {
    my ($mp, $ma) = ($p =~ m/^(.*)\.([^.]*)$/);
    if (!defined($mp)) {
      tlerror("very strange, above it matched and now not anymore?!?! $p\n");
      next;
    }
    if (!defined($Packages{$mp})) {
      my $tlp = $localtlpdb->get_package($p);
      populate_Packages("local", $tlp);
    } else {
      # two cases:
      # - $mp.$ma where $ma is in available_archs
      #   check if $pkg itself has been update present, otherwise
      #   add a "+" to the revision number of the upstream package
      #   but do NOT show the sub package
      #
      #   this has to be deferred to later processing as we don't have
      #   this information at hand at this time
      #
      # - $pkg.$arch where $arch is NOT in available_arch
      #   thus it was installed by the user, show it
      #
      if (!TeXLive::TLUtils::member($ma, @avail_arch)) {
        my $tlp = $localtlpdb->get_package($p);
        populate_Packages("local", $tlp);
      }
    }
  }
  update_list_remote();
}

sub update_list_remote {
  my @do_later_media;
  #my $handle;
  #Devel::Leak::NoteSV($handle);
  # clear old info from remote media
  for my $p (keys %Packages) {
    if (!$Packages{$p}{'installed'}) {
      $Packages{$p}{'cb'}->destroy() if defined($Packages{$p}{'cb'});
      delete($Packages{$p}{'tlp'}) if defined($Packages{$p}{'tlp'});
      delete $Packages{$p};
      next;
    }
    delete $Packages{$p}{'remoterevision'};
    delete $Packages{$p}{'remoterevisionstring'};
    delete $Packages{$p}{'remotecatalogueversion'};
  }
  if (defined($remotetlpdb)) {
    for my $p ($remotetlpdb->list_packages()) {
      # skip 00texlive packages
      next if ($p =~ m!^00texlive!);
      if ($p =~ m;\.;) {
        push @do_later_media, $p;
        next;
      }
      my $tlp;
      my $maxtag;
      if ($remotetlpdb->is_virtual) {
        ($maxtag, undef, $tlp, undef) =
          $remotetlpdb->virtual_candidate($p);
      } else {
        $tlp = $remotetlpdb->get_package($p);
      }
      populate_Packages("remote", $tlp, $maxtag);
    }
  }
  my @avail_arch = $localtlpdb->available_architectures;
  for my $p (@do_later_media) {
    my ($mp, $ma) = ($p =~ m/^(.*)\.([^.]*)$/);
    if (!defined($mp)) {
      tlerror("very strange, above it matched and now not anymore?!?! $p\n");
      next;
    }
    my $tlp;
    my $maxtag;
    if ($remotetlpdb->is_virtual) {
      ($maxtag, undef, $tlp, undef) =
        $remotetlpdb->virtual_candidate($p);
    } else {
      $tlp = $remotetlpdb->get_package($p);
    }
    if (!defined($Packages{$mp})) {
      populate_Packages("remote", $tlp, $maxtag);
    } else {
      # two cases:
      # - $mp.$ma where $ma is in available_archs
      #   check if $pkg itself has been update present, otherwise
      #   add a "+" to the revision number of the upstream package
      #   but do NOT show the sub package
      # We have to make sure that the remote version does not get
      # TWO times a + added. This can happen if you have multiple
      # architectures installed, and all of the .ARCH packages (more 
      # than 1) are updated, but not the main package
      #
      if (TeXLive::TLUtils::member($ma, @avail_arch)) {
        if (defined($Packages{$mp}{'localrevision'}) &&
            defined($Packages{$mp}{'remoterevision'}) &&
            # a subpackage was already checked and found to be updated
            $Packages{$mp}{'remoterevision'} !~ m/\+$/ &&
            $Packages{$mp}{'localrevision'} < $Packages{$mp}{'remoterevision'}) {
          # the main package is updated, so just do nothing
        } else {
          if ($Packages{$mp}{'remoterevision'} !~ m/\+$/) {
            # if there is an update to a binary sub package mark that with
            # a "+" in the remote revision
            my $ltlp = $localtlpdb->get_package($p);
            if (defined($ltlp) && $ltlp->revision < $tlp->revision) {
              $Packages{$mp}{'remoterevision'} .= "+";
            }
          }
          # no else clause, in this case the main package is not updated,
          # but already one subpackage was checked and a + added, so don't
          # do anything
        }
      # - $pkg.$arch where $arch is NOT in available_arch
      #   thus it was installed by the user, show it
      #
      } else {
        # only show that one if it is locally installed
        if (defined($Packages{$p})) {
          populate_Packages("remote", $tlp, $maxtag);
        }
      }
    }
  }
  #
  # check for critical updates
  my @critical = $localtlpdb->expand_dependencies("-no-collections",
    $localtlpdb, @TeXLive::TLConfig::CriticalPackagesList);
  @critical_updates = ();
  for my $p (@critical) {
    if (defined($Packages{$p}) &&
        defined($Packages{$p}{'localrevision'}) &&
        defined($Packages{$p}{'remoterevision'}) &&
        $Packages{$p}{'localrevision'} < $Packages{$p}{'remoterevision'}) {
      push @critical_updates, $p;
    }
  }
  #
  #
  if (@critical_updates) {
    # add to the warning text if further updates are available
    # compute the number of further updates 
    # we do NOT make a correct computation here like done in the actual
    # tlmgr.pl sub action_update, but only count the numbers of packages
    # that would be updated (without any forcibly remove/new counting)
    my $min_action = 0;
    for my $p (keys %Packages) {
      next if member($p, @critical);
      if (defined($Packages{$p}{'localrevision'}) &&
          defined($Packages{$p}{'remoterevision'}) &&
          $Packages{$p}{'localrevision'} < 
            maybe_strip_last_plus($Packages{$p}{'remoterevision'})) {
        $min_action++;
      }
    }
    #
    # create the warning dialog
    #
    my $sw = $mw->DialogBox(-title => __("Warning"), -buttons => [ __("Ok") ]);
    my $t = __("The TeX Live manager (the software you're currently running)
needs to be updated before any other updates can be done.

Please do this by clicking the \"Update the TeX Live Manager\" button,
after dismissing this dialogue.

After the update, the TeX Live manager will terminate.
You can then restart it to proceed with further updates."); 
    if ($min_action) {
      $t .= "\n\n"
. __("(Further updates will be available after tlmgr has been updated.)");
    }
    $t .= "\n\n" . __("Please wait a bit after the program has terminated so that the update can be completed.") if wndws();
    $sw->add("Label", -text => $t)->pack(-padx => "3m", -pady => "3m");
    $sw->Show;
  }
  #Devel::Leak::CheckSV($handle);
  #warn join(",", currmem());
}

sub currmem {
    my $pid = shift || $$;
    if (open(MAP, "dd if=/proc/$pid/map bs=64k 2>/dev/null |")) { # FreeBSD
        my $mem = 0;
        my $realmem = 0;
        while(<MAP>) {
            my(@l) = split /\s+/;
            my $delta = (hex($l[1])-hex($l[0]));
            $mem += $delta;
            if ($l[11] ne 'vnode') {
                $realmem += $delta;
            }
        }
        close MAP;
        ($mem, $realmem);
    } elsif (open(MAP, "/proc/$pid/maps")) { # Linux
        my $mem = 0;
        my $realmem = 0;
        while(<MAP>) {
            my(@l) = split /\s+/;
            my($start,$end) = split /-/, $l[0];
            my $delta = (hex($end)-hex($start));
            $mem += $delta;
            if (!defined $l[5] || $l[5] eq '') {
                $realmem += $delta;
            }
        }
        close MAP;
        ($mem, $realmem);
    } else {
        undef;
    }
}

sub cb_handle_restore {
  init_defaults_setting();
  # first do the handling of the backup dir selection
  {
    my ($a, $b) = check_backupdir_selection();
    if ($a != $F_OK) {
      # in all these cases we want to terminate in the non-gui mode
      my $sw = $mw->DialogBox(-title => __("Warning"), -buttons => [ __("Ok") ]);
      $sw->add("Label", -text => $b)->pack(@p_iii);
      $sw->Show;
      # delete the backupdir setting it might contain rubbish and
      # we want to recheck
      delete $opts{'backupdir'};
      return;
    }
  }

  my $sw = $mw->Toplevel(-title => __("Restore packages from backup"));
  $sw->transient($mw);
  $sw->grab;

  my $tf = $sw->Frame;
  $tf->pack(-ipadx => '3m', -ipady => '3m');

  my %backups = get_available_backups($opts{"backupdir"});

  my @pkgbackup = sort keys %backups;
  my $lstlen = ($#pkgbackup >= 10 ? 10 : ($#pkgbackup + 1));

  my $pkg;
  my $rev;

  my $restore_dialog = $sw->DialogBox(-title => __("Restore completed"), 
                                      -buttons => [ __("Ok") ]);
  $restore_dialog->add("Label", -text => __("Restore completed"))->pack(@p_iii);


  my $revbrowser;

  $tf->Label(-text => __("Select the package to restore, or restore all packages"))->pack(@p_ii);

  $tf->BrowseEntry(-label => __("Package:"),
    -listheight => $lstlen,
    -autolistwidth => 1,
    -choices => \@pkgbackup,
    -browsecmd => 
      sub { my @revlist = sort { $b <=> $a } (keys %{$backups{$pkg}});
            $revbrowser->delete(0,"end"); 
            for my $r (@revlist) { 
              $revbrowser->insert("end", $r); 
            }; 
            $rev = "";
      },
    -variable => \$pkg)->pack(@p_ii);

  $revbrowser = $tf->BrowseEntry(-label => __("Revision:"),
    -listheight => 10,
    -variable => \$rev)->pack(@p_ii);

  $tf->pack(-ipadx => '3m', -ipady => '3m');
  $tf->Button(-text => __("Restore selected package"),
    -command => sub {
                      if (!defined($pkg) || !defined($rev) ||
                          !($backups{$pkg}->{$rev})) {
                        tlwarn("Please select a package and revision first!\n");
                        return;
                      }
                      $mw->Busy(-recurse => 1);
                      info("Restoring $pkg, rev $rev from $opts{'backupdir'}/${pkg}.r${rev}.tar.xz\n");
                      restore_one_package($pkg, $rev, $opts{"backupdir"});
                      reinit_local_tlpdb;
                      $restore_dialog->Show;
                      $pkg = "";
                      $rev = "";
                      $mw->Unbusy;
                    })->pack(@p_ii);
  $tf->Button(-text => __("Restore all packages to latest version"),
    -command => sub {
                      $mw->Busy(-recurse => 1);
                      for my $p (@pkgbackup) {
                        my @tmp = sort {$b <=> $a} (keys %{$backups{$p}});
                        my $r = $tmp[0];
                        info("Restoring $p, rev $r from $opts{'backupdir'}/${p}.r${r}.tar.xz\n");
                        restore_one_package($p, $r, $opts{"backupdir"});
                      }
                      reinit_local_tlpdb;
                      $restore_dialog->Show;
                      $pkg = "";
                      $rev = "";
                      $mw->Unbusy;
                    })->pack(@p_ii);

  $tf->Button(-text => __("Close"),
    -command => sub { $sw->destroy; })
    ->pack(@p_iii);
}


sub cb_handle_symlinks {
  my $sw = $mw->Toplevel(-title => __("Handle symlinks in system dirs"));
  $sw->transient($mw);
  $sw->grab;
  init_defaults_setting();

  my $tp = $sw->Frame;
  $tp->pack(-ipadx => '3m', -ipady => '3m');
  $tp->Label(-text => __("Link destination for programs"), @a_w)->grid(
    $tp->Label(-textvariable => \$changeddefaults{"sys_bin"}{'display'}, @a_w),
    $tp->Button(-text => __("Change"),
      -command => sub { edit_dir_option ($sw, "sys_bin"); }),
    -sticky => 'w');
  $tp->Label(-text => __("Link destination for info docs"), @a_w)->grid(
    $tp->Label(-textvariable => \$changeddefaults{"sys_info"}{'display'}, @a_w),
    $tp->Button(-text => __("Change"), 
      -command => sub { edit_dir_option ($sw, "sys_info"); }),
    -sticky => 'w');
  $tp->Label(-text => __("Link destination for man pages"), @a_w)->grid(
    $tp->Label(-textvariable => \$changeddefaults{"sys_man"}{'display'}, @a_w),
    $tp->Button(-text => __("Change"),
      -command => sub { edit_dir_option ($sw, "sys_man"); }),
    -sticky => 'w');
  
  my $md = $sw->Frame;
  $md->pack(-ipadx => '3m', -ipady => '3m');
  $md->Button(-text => __("Update symbolic links"),
    -command => sub {
                      $mw->Busy(-recurse => 1);
                      info("Updating symlinks ...\n");
                      execute_action_gui("path", "add");
                      $mw->Unbusy;
                    })->pack(@left, -padx => '3m');
  $md->Button(-text => __("Remove symbolic links"),
    -command => sub {
                      $mw->Busy(-recurse => 1);
                      info("Removing symlinks ...\n");
                      execute_action_gui("path", "remove");
                      $mw->Unbusy;
                    })->pack(@left, -padx => '3m');

  my $bt = $sw->Frame;
  $bt->pack(-ipadx => '3m', -ipady => '3m');
  $bt->Button(-text => __("Ok"),
    -command => sub { apply_settings_changes(); $sw->destroy; })
    ->pack(@left, -padx => '3m');
  $bt->Button(-text => __("Cancel"),
    -command => sub { $sw->destroy; })->pack(-side => 'left', -padx => "3m");
}

sub edit_dir_option {
  my $sw = shift;
  my $what = shift;
  my $dir = cb_edit_string_or_dir($sw, $what, $changeddefaults{$what}{'value'});
  if (defined($dir)) {
    $changeddefaults{$what}{'value'} = $dir;
    $changeddefaults{$what}{'display'} = $dir;
    $settings_label{$what}->configure(
      -background => ($defaults{$what} eq $dir ? $bgcolor : 'red'));
  }
}

sub cb_edit_string_or_dir {
  my ($mw, $what, $cur) = @_;
  my $done;
  my $val;
  my $sw = $mw->Toplevel(-title => __("Edit directory"));
  $sw->transient($mw);
  $sw->withdraw;
  $sw->Label(-text => __("New value for %s:", $what))->pack(@p_ii);
  my $entry = $sw->Entry(-text => $cur, -width => 30);
  $entry->pack(@p_ii);
  $sw->Button(-text => __("Choose Directory"),
    -command => sub {
                      my $var = $sw->chooseDirectory();
                      if (defined($var)) {
                        $entry->delete(0,"end");
                        $entry->insert(0,$var);
                      }
                    })->pack(@p_ii);
  my $f = $sw->Frame;
  my $okbutton = $f->Button(-text => __("Ok"),
    -command => sub { $val = $entry->get; $done = 1; })->pack(@left, @p_ii);
  my $cancelbutton = $f->Button(-text => __("Cancel"),
          -command => sub { $val = undef; $done = 1 })->pack(@right, @p_ii);
  $f->pack(-expand => 1);
  $sw->bind('<Return>', [ $okbutton, 'Invoke' ]);
  $sw->bind('<Escape>', [ $cancelbutton, 'Invoke' ]);
  my $old_focus = $sw->focusSave;
  my $old_grab = $sw->grabSave;
  $sw->Popup;
  $sw->grab;
  $sw->waitVariable(\$done);
  $sw->grabRelease if Tk::Exists($sw);
  $sw->destroy if Tk::Exists($sw);
  return $val;
}

sub cb_edit_location {
  my $key = shift;
  my $okbutton;
  my $val;
  my $sw = $mw->Toplevel(-title => __("Load package repository"));
  $sw->transient($mw);
  $sw->grab();
  $sw->Label(-text => __("Load this package repository:"))->pack(@p_ii);
  my @mirror_list;
  push @mirror_list, TeXLive::TLUtils::create_mirror_list();
  my $entry = $sw->BrowseEntry(
    -listheight => 12, 
    -listwidth => 400,
    -width => 50,
    -autolistwidth => 1,
    -choices => \@mirror_list,
    -browsecmd => 
      sub {
        if ($val !~ m/^  /) {
          $val = "";
          # $okbutton->configure(-state => 'disabled');
        } elsif ($val =~ m!(http|ftp)://!) {
          $val = TeXLive::TLUtils::extract_mirror_entry($val);
          # $okbutton->configure(-state => 'normal');
        } else {
          $val =~ s/^\s*//;
          # $okbutton->configure(-state => 'normal');
        }
      },
    -variable => \$val);
  # end new
  $entry->pack(@p_ii);
  my $f1 = $sw->Frame;
  $f1->Button(-text => __("Choose local directory"),
    -command => sub {
                      my $var = $sw->chooseDirectory();
                      if (defined($var)) {
                        $val = $var;
                        # $okbutton->configure(-state => 'normal');
                      }
                    })->pack(@left, @p_ii);
  $f1->Button(-text => __("Use standard net repository"),
    -command => sub {
                      $val = $TeXLiveURL;
                      # $okbutton->configure(-state => 'normal');
                    })->pack(@left, @p_ii);
  $f1->pack;
  my $f = $sw->Frame;
  $okbutton = $f->Button(-text => __("Load"), # -state => "disabled",
    -command => sub { 
                      if ($val) {
                        $location = $val;
                        $sw->destroy;
                        my $foo = $mw->Toplevel();
                        $foo->transient($mw);
                        $foo->overrideredirect(1);
                        my $frame = $foo->Frame( -border => 5, -relief => 'groove' )->pack;
                        $frame->Label( -text => __("Loading remote repository - this may take some time, please be patient ...") )->pack( -padx => 5 );
                        $foo->Popup(-popanchor => 'c');
                        setup_location($location);
                        $foo->destroy;
                      } else {
                        # button should be disabled and not clickable 
                        # why are we here???
                      }
                    })->pack(@left, @p_ii);
  my $cancelbutton = $f->Button(-text => __("Cancel"),
          -command => sub { $sw->destroy })->pack(@right, @p_ii);
  $f->pack(-expand => 1);
  $sw->bind('<Return>', [ $okbutton, 'Invoke' ]);
  $sw->bind('<Escape>', [ $cancelbutton, 'Invoke' ]);
}

sub update_loaded_location_string {
  my $arg = shift;
  $arg || ($arg = $location);
  my %repos = repository_to_array($arg);
  my @tags = sort keys %repos;
  my @vals;
  if ($#tags > 0) {
    @vals = map {
      "$_:$repos{$_} (" .
      ($remotetlpdb->virtual_get_tlpdb($_)->is_verified ?
        __("verified") : __("not verified")) . ")"
    } sort sort_main_first @tags;
  } else {
    $arg .= " (" . ($remotetlpdb->is_verified ?
      __("verified") : __("not verified")) . ")";
    @vals = ( $arg );
  }
  if ($#tags > 0) {
    $loaded_text_button->configure(-text => __("multiple repositories"));
  } else {
    $loaded_text_button->configure(-text => $arg);
  }
  $loaded_text->configure(-text => __("Loaded:"));
  $loaded_text_button->configure( -command => 
      sub { transient_show_multiple_repos($loaded_text_button, @vals); });
  $default_repo->packForget;
}

sub transient_show_multiple_repos {
  my ($ref_widget, @vals) = @_;
  my $xx = $ref_widget->rootx;
  my $yy = $ref_widget->rooty + $ref_widget->reqheight;
  my $sw = $mw->Toplevel(-bd => 2);
  $sw->geometry("+$xx+$yy");
  $sw->overrideredirect(1);
  $sw->transient($mw);
  $sw->grab;
  # we want to have a global grab, but that somehow does not work!
  #$sw->grabGlobal;
  $sw->bind('<1>', sub { $sw->grabRelease; $sw->destroy; });
  my $foo = $sw->Listbox(-height => 0, -width => 0,
                         -listvariable => \@vals,
                         -state => 'normal');
  $foo->pack;
}

sub run_update_functions {
  foreach my $f (@update_function_list) {
    &{$f}();
  }
}

sub check_location_on_ctan {
  # we want to check that if mirror.ctan.org
  # is used that we select a mirror once
  for my $k (keys %repos) {
    if ($repos{$k} =~ m/$TeXLive::TLConfig::TeXLiveServerURL/) {
      $repos{$k} = TeXLive::TLUtils::give_ctan_mirror();
    }
  }
}

sub execute_action_gui {
  $mw->Busy(-recurse => 1);
  info ("Executing action @_\n");
  my $error_code = execute_action(@_);
  if ($error_code) {
    give_warning_window(@_);
  }
  info(__("Completed") . ".\n");
  $mw->Unbusy;
}

sub give_warning_window {
  my ($act, @args) = @_;
  my $sw = $mw->DialogBox(-title => __("Warning"), -buttons => [ __("Ok") ]);
  $sw->add("Label", -text => __("Running %s failed.\nPlease consult the log window for details.", "$act @args")
    )->pack(@p_iii);
  $sw->Show;
}

# pod help thing

sub pod_to_text {
  my $txt;
  eval { require IO::String; };
  if ($@) {
    $txt = "
The Perl Module IO::String is not available.
Without it the documentation cannot be shown. Please install it.

As an alternative use
  tlmgr help
on the command line.
";
  } else {
    my $io = IO::String->new($txt);
    my $parser = Pod::Text->new (sentence => 0, width => 78);
    $parser->parse_from_file("$Master/texmf-dist/scripts/texlive/tlmgr.pl", $io);
  }
  my $sw = $mw->Toplevel(-title => __("Help"));
  $sw->transient($mw);
  my $t = $sw->Scrolled("ROText", -scrollbars => "e",
                                  -height => 40, -width => 80);
  $t->Contents($txt);
  $t->pack;
}

1;

__END__


### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
