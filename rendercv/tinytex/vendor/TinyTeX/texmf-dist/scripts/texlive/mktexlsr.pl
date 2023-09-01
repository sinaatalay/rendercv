#!/usr/bin/env perl
#
# Copyright 2015 Norbert Preining
#
# This file is licensed under the GNU General Public License version 2
# or any later version.
#
# History:
# Original shell script (C) 1994 Thomas Esser (as texhash), Public domain.
#


=pod

=head1 NAME

C<mktexlsr> and C<TeX::LSR> - handle TeX's Kpathsea file name database C<ls-R>

=head1 SYNOPSIS

mktexlsr [I<option>]... [I<dir>]...

texhash [I<option>]... [I<dir>]...

=head1 DESCRIPTION

B<mktexlsr> rebuilds the C<ls-R> filename databases used by TeX.
If one or more arguments I<dir> are given, these are used as the 
directories in which to build C<ls-R>. Else all directories in the 
search path for C<ls-R> files (i.e., \$TEXMFDBS) are used.

B<texhash> is a synonym for B<mktexlsr>; there are no differences in
behavior based on the name.

=head1 OPTIONS

=over 4

=item B<--dry-run>, B<-n>  

do not actually update anything

=item B<--help>, B<-h>

display this help and exit 

=item B<--nofollow>

do not follow symlinks (default to follow)

=item B<--output[=]>I<NAME>, B<-o> I<NAME>

if (and only if) exactly one I<dir> is given, output C<ls-R> file to I<NAME>

=item B<--quiet>, B<-q>, B<--silent>

cancel --verbose

=item B<--verbose>

explain what is being done, defaults to on when output is connected
to a terminal.

=item B<--version>, B<-v>

output version information and exit
 
=back

=cut

use strict;
$^W = 1;


package mktexlsr;

my $ismain;

BEGIN {
  $^W = 1;
  $ismain = (__FILE__ eq $0);
}

# for future inclusion in TeX Live svn:
my $svnid = '$Id: mktexlsr.pl 62699 2022-03-14 09:53:53Z siepo $';
my $lastchdate = '$Date: 2022-03-14 10:53:53 +0100 (Mon, 14 Mar 2022) $';
$lastchdate =~ s/^\$Date:\s*//;
$lastchdate =~ s/ \(.*$//;
my $svnrev = '$Revision: 62699 $';
$svnrev =~ s/^\$Revision:\s*//;
$svnrev =~ s/\s*\$$//;
my $version = "revision $svnrev ($lastchdate)";

use Getopt::Long;
use File::Basename;
use Pod::Usage;

my $opt_dryrun = 0;
my $opt_help   = 0;
my $opt_verbose = (-t STDIN); # test whether connected to a terminal
my $opt_version = 0;
my $opt_output;
my $opt_sort = 0;   # for debugging sort output
my $opt_follow = win32() ? 0 : 1; # follow links - check whether they are dirs or not

(my $prg = basename($0)) =~ s/\.pl$//;

my $lsrmagic = 
  '% ls-R -- filename database for kpathsea; do not change this line.';
my $oldlsrmagic = 
  '% ls-R -- maintained by MakeTeXls-R; do not change this line.';


&main() if $ismain;



#################################################################
#
# usage as module
#

package TeX::LSR;

use Cwd;
use File::Spec::Functions;
use File::Find;

=pod

=head1 Perl Module Usage

This file also provides a module C<TeX::LSR> that can be used
as programmatic interface to the C<ls-R> files. Available
methods are:

  $lsr = new TeX::LSR( root => $texmftree );
  $lsr->loadtree();
  $lsr->loadfile();
  $lsr->write( [filename => $fn, sort => $do_sort ] );
  $lsr->addfiles ( @files );

=head1 Methods

=over 4

=item C<< TeX::LSR->new( [root => "$path"] ) >>

create a new C<LSR> object related to the tree in C<$path>, 
without loading any further information. Returns 1 on success
and 0 on failure.

The tree is represented as hash, where each file and directory
acts as key, with files having 1 as value, and directories 
their recursive representation hash as value.

=cut

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    root => $params{'root'},
    filename => '',           # to accomodated both ls-r and ls-R
    is_loaded => 0,
    tree => { }
  };
  bless $self, $class;
  return $self;
}

=pod

=item C<< $lsr->loadtree() >>

Loads the file information from the actual tree by traversing the
whole directory recursively.

Common VCS files and directories are ignored (C<.git>, C<.svn>, C<.hg>,
C<.bzr>, C<CVS>). See above for the representation.

Returns 1 on success, 0 on failure.

=cut

# returns 1 on success, 0 on failure
sub loadtree {
  my $self = shift;
  return 0 if (!defined($self->{'root'}));
  return 0 if (! -d $self->{'root'});

  my $tree;
  build_tree($tree, $self->{'root'});
  $self->{'tree'} = $tree->{$self->{'root'}};
  $self->{'is_loaded'} = 1;
  return 1;

  # code adapted from
  # http://www.perlmonks.org/?node=How%20to%20map%20a%20directory%20tree%20to%20a%20perl%20hash%20tree
    sub build_tree {
      my $node = $_[0] = {};
      my @s;
      # go through all dirs recursively (File::Find::find), 
      # links are dereferenced according to $opt_follow
      # add an entry of 1 if it is not a directory, otherwise
      # create an empty hash as argument
      File::Find::find( { follow_skip => 2, follow_fast => $opt_follow, wanted => sub {
        $node = (pop @s)->[1] while (@s && $File::Find::dir ne $s[-1][0]);
        # ignore VCS
        return if ($_ eq ".git");
        return if ($_ eq ".svn");
        return if ($_ eq ".hg");
        return if ($_ eq ".bzr");
        return if ($_ eq "CVS");
        return $node->{$_} = 1 if (! -d);
        push (@s, [ $File::Find::name, $node ]);
        $node = $node->{$_} = {};
      }}, $_[1]);
      $_[0]{$_[1]} = delete $_[0]{'.'};
    }
}

# set the `filename' member; check ls-R first, then ls-r.

=pod C<< $lsr->setup_filename() >>

We support file names C<ls-R> and C<ls-r>, but create as C<ls-R>.
Internal function, should not be used outside.

=cut

sub setup_filename {
  my $self = shift;
  if (!$self->{'filename'}) {
    if (-r $self->{'root'} . "/ls-R") {
      $self->{'filename'} = 'ls-R';
    } elsif (-r $self->{'root'} . "/ls-r") {
      $self->{'filename'} = 'ls-r';
    } else {
      $self->{'filename'} = 'ls-R';
    }
  }
  return 1;
}



=pod

=item C<< $lsr->load() >>

Loads the file information either from the C<lsr-R> file, if
present, otherwise from the actual tree.

Returns 1 on success, 0 on failure.

=cut

sub load {
  my $self = shift;
  return 0 if (!defined($self->{'root'}));
  return 0 if (! -d $self->{'root'});
  $self->setup_filename();
  if (-r $self->{'filename'}) {
    return $self->loadfile();
  } else {
    return $self->loadtree();
  }
}

=pod

=item C<< $lsr->loadfile() >>

Loads the file information from the C<ls-R> file. Checks for the
presence of the magic header as first line.

Returns 1 on success, 0 on failure.

=cut

# read given file; return 0 if failure, 1 if ok.
sub loadfile {
  my $self = shift;
  return 0 if (!defined($self->{'root'}));
  return 0 if (! -d $self->{'root'});

  $self->setup_filename();
  my $lsrfile = catfile($self->{'root'}, $self->{'filename'});
  return 0 if (! -r $lsrfile);

  open (LSR, "<", $lsrfile)
    || die "$prg: readable but not openable $lsrfile??: $!";

  # check first line for the magic header
  chomp (my $fl = <LSR>);
  if (($fl eq $lsrmagic) || ($fl eq $oldlsrmagic)) {
    my %tree;
    my $t;
    for my $l (<LSR>) {
      chomp($l);
      next if ($l =~ m!^\s*$!);
      next if ($l =~ m!^\./:!);
      if ($l =~ m!^(.*):!) {
        $t = \%tree;
        my @a = split(/\//, $1);
        for (@a) {
          $t->{$_} = {} if (!defined($t->{$_}) || ($t->{$_} == 1));
          $t = $t->{$_};
        }
      } else {
        $t->{$l} = 1;
      }
    }
    $self->{'tree'} = $tree{'.'};
  }
  close(LSR);
  $self->{'is_loaded'} = 1;
  return 1;
}

# 

=pod

=item C<< $lsr->write( [ filename => "$fn", sort => $val) >>

Writes out the C<ls-R> file, either to the default file name, or
to C<$fn> if given. Entries within a directory are not sorted
(not necessary), but sorting can be enforced by passing a true 
value to C<sort>.

Returns 1 on success, 0 on failure (and give warning).

=cut

sub write {
  my $self = shift;
  my %params = @_;
  my $fn;
  my $dosort = 0;
  $fn = $params{'filename'} if $params{'filename'};
  $dosort = $params{'sort'};
  if (!defined($self->{'root'})) {
    warn "TeX::LSR: root undefined, cannot write.\n";
    return 0;
  }
  if ($self->{'is_loaded'} == 0) {
    warn "TeX::LSR: tree not loaded, cannot write: $self->{root}\n";
    return 0;
  }
  if (!defined($fn)) {
    $self->setup_filename();
    $fn = catfile($self->{'root'}, $self->{'filename'});
  }
  if (-e $fn && ! -w $fn) {
    warn "TeX::LSR: ls-R file not writable, skipping: $fn\n";
    return 0;
  }
  open (LSR, ">$fn") || die "TeX::LSR writable but cannot open??; $!";
  print LSR "$lsrmagic\n\n";
  print LSR "./:\n";  # hardwired ./ for top-level files
  do_entry($self->{'tree'}, ".", $dosort);
  close LSR;
  return 1;
  
    sub do_entry {
      my ($t, $n, $sortit) = @_;
      print LSR "$n:\n";
      my @sd;
      for my $st ($sortit ? sort(keys %$t) : keys %$t) {
        push (@sd, $st) if (ref($t->{$st}) eq 'HASH');
        print LSR "$st\n";
      }
      print LSR "\n";
      for my $st ($sortit ? sort @sd : @sd) {
        do_entry($t->{$st}, "$n/$st", $sortit);
      }
    }
}

=pod

=item C<< $lsr->addfiles( @files ) >>

Adds the files from C<@files> to the C<ls-R> tree. If a file
is relative, it is added relative the the root of the tree. If
it is absolute and the root agrees with a prefix of the file name,
add the remaining part. If they disagree, throw an error.

Returns 1 on success, 0 on failure (and give warning).

=cut

sub addfiles {
  my ($self, @files) = @_;
  if ($self->{'is_loaded'} == 0) {
    warn "TeX::LSR: tree not loaded, cannot add files: $self->{root}\n";
    return 0;
  }

  # if we are passed an absolute file name, check whether the prefix
  # coincides with the root of the texmf tree, and add the relative
  # file name, otherwise bail out
  for my $f (@files) {
    if (file_name_is_absolute($f)) {
      my $cf = canonpath($f);
      my $cr = canonpath($self->root);
      if ($cf =~ m/^$cr([\\\/])?(.*)$/) {
        $f = $2;
      } else {
        warn("File $f does not reside in $self->root.");
        return 0;
      }
    }
    my $t = $self->{'tree'};
    my @a = split(/[\\\/]/, $f);
    my $fn = pop @a;
    for (@a) {
      $t->{$_} = {} if (!defined($t->{$_}) || ($t->{$_} == 1));
      $t = $t->{$_};
    }
    $t->{$fn} = 1;
  }
  return 1;
}

=pod

=back

=cut




##########################################################
#
# package TeX::Update
#
# based on the mktexupd function in TLUtils

package TeX::Update;

=pod

=head1 TeX ls-R Update module

This file also provides a module C<TeX::Update> that can be used
to add files to their respective trees.
Available methods are:

  $upd = new TeX::Update();
  $upd->mustexist(1);
  $upd->add(file1, [file2]);
  $upd->add(file3);
  $upd->exec();
  $upd->reset();

=head1 Methods

=over 4

=item C<< TeX::Update->new() >>

Create a new TeX::Update object.

=cut

sub new {
  my $class = shift;
  my $self = {
    files => {},
    mustexist => 0,
  };
  bless $self, $class;
  return $self;
}

=pod

=item C<< $upd->add( @files ) >>

Adds a list of files without any checks done.
Returns 1.

=cut

sub add {
  my $self = shift;
  foreach my $file (@_) {
    $file =~ s|\\|/|g;
    $self->{'files'}{$file} = 1;
  }
  return 1;
}

=pod

=item C<< $upd->reset( ) >>

Removes all references to added files. Returns 1.

=cut

sub reset {
  my $self = shift;
  $self->{'files'} = {};
  return 1;
}

=pod

=item C<< $upd->mustexist( [ $newvalue ] ) >>

Wit C<$newvalue> given, sets the mustexist propery. In both
cases returns the current value afterwards.

=cut

sub mustexist {
  my $self = shift;
  if (@_) { $self->{'mustexist'} = shift }
  return $self->{'mustexist'};
}

=pod

=item C<< $upd->exec( ) >>

Goes through all added files, determines whether the files is contained
in a tree that contains a ls-R files. If yes, adds the files there.
If the mustexist property is set, bails out in case a file does not
exists. 

Returns 1 on success, 0 on failure (and give warning).

=cut

sub exec {
  my $self = shift;
  # first check whether all files exist
  if ($self->{'mustexist'}) {
    for my $f (keys %{$self->{'files'}}) {
      die "File \'$f\' doesn't exist.\n" if (! -f $f);
    }
  }
  my @texmfdbs = mktexlsr::find_default_lsr_trees();
  # filter files into the respective trees
  my %dbs;
  for my $p (keys %{$self->{'files'}}) {
    for my $db (@texmfdbs) {
      # remove terminal / if present
      $db =~ s|/$||;
      # lowercase for Windows
      $db = lc($db) if mktexlsr::win32();
      # search path
      my $used_path = mktexlsr::win32() ? lc($p) : $p;
      # check whether $p/$used_path is a file in $db
      # we append a / to make sure that subdirs do not overlap (texmf/-dist)
      if ( substr($used_path, 0, length("$db/")) eq "$db/" ) {
        # fie $p/$used_path resides in the current $db
        # strip initial $db/
        my $filepart = substr($used_path, length("$db/"));
        $dbs{$db}{$filepart} = 1;
        last; # of the db loops!
      }
    }
  }
  #
  # now do the actual work
  for my $db (keys %dbs) {
    if (! -d $db) {
      if (! mktexlsr::mkdirhier($db) ) {
        die "Cannot create directory $db: $!";
      }
    }
    my $lsr = new TeX::LSR(root => $db);
    # load either from ls-R or tree
    $lsr->load() || die "Cannot load ls-R in $db.";
    $lsr->addfiles(keys %{$dbs{$db}}) || die "Cannot add some file to $db.";
    $lsr->write() || die "Cannot write ls-R in $db.";
  }
  return 1;
}

=pod

=back

=cut



#############################################################
#
# back to main mktexlsr package/program.

package mktexlsr;

sub main {
  GetOptions("dry-run|n"      => \$opt_dryrun,
             "help|h"         => \$opt_help,
             "verbose!"       => \$opt_verbose,
             "quiet|q|silent" => sub { $opt_verbose = 0 },
             "sort"           => \$opt_sort,
             "output|o=s"     => \$opt_output,
             "follow!"        => \$opt_follow,
             "version|v"      => \$opt_version)
  || pod2usage(2);

  pod2usage(-verbose => 2, -exitval => 0) if $opt_help;

  if ($opt_version) {
    print version();
    exit (0);
  }

  if ($opt_output && $#ARGV != 0) {
    # we only support --output with only one tree as argument
    die "$prg: with --output, exactly one tree must be given: @ARGV\n";
  }

  for my $t (find_lsr_trees()) {
    my $lsr = new TeX::LSR(root => $t);
    print "$prg: Updating $t...\n" if $opt_verbose;
    if ($lsr->loadtree()) {
      if ($opt_dryrun) {
        print "$prg: Dry run, not writing files.\n" if $opt_dryrun;
      } elsif ($opt_output) {
        #warn "writing to $opt_output\n";
        $lsr->write(filename => $opt_output, sort => $opt_sort);
      } else {
        #warn "writing with sort=$opt_sort\n";
        $lsr->write(sort => $opt_sort);
      }
    } else {
      warn "$prg: cannot read files, skipping: $t\n";
    }
  }
  print "$prg: Done.\n" if $opt_verbose;
}

sub find_default_lsr_trees {
  # the shellfile used kpsewhich --show-path=ls-R | tr : '\n' 
  # seems to be simpler than using -var-value TEXMFDBS and
  # fixing the return value
  my $delim = win32() ? ';' : ':';
  chomp( my $t = `kpsewhich -show-path=ls-R` );
  my @texmfdbs = split($delim, $t);
  return @texmfdbs;
}

sub find_lsr_trees {
  my %lsrs;
  my @candidates = @ARGV;
  if (!@candidates) {
    @candidates = find_default_lsr_trees();
  }
  for my $t (@candidates) {
    my $ret;
    eval {$ret = Cwd::abs_path($t);}; # eval needed for w32
    if ($ret) {
      $lsrs{$ret} = 1;
    } else {
      # ignored, we simply skip directories that don't exist
    }
  }
  return sort(keys %lsrs);
}

sub version {
  my $ret = sprintf "%s version %s\n", $prg, $version;
  return $ret;
}


sub win32 {
  return ( ($^O =~ /^MSWin/i) ? 1 : 0 );
}

# copied from TLUtils.pm
sub mkdirhier {
  my ($tree,$mode) = @_;

  return if (-d "$tree");
  my $subdir = "";
  # win32 is special as usual: we need to separate //servername/ part
  # from the UNC path, since (! -d //servername/) tests true
  $subdir = $& if ( win32() && ($tree =~ s!^//[^/]+/!!) );

  my @dirs = split (/\//, $tree);
  for my $dir (@dirs) {
    $subdir .= "$dir/";
    if (! -d $subdir) {
      if (defined $mode) {
        mkdir ($subdir, $mode)
        || die "$0: mkdir($subdir,$mode) failed, goodbye: $!\n";
      } else {
        mkdir ($subdir) || die "$0: mkdir($subdir) failed, goodbye: $!\n";
      }
    }
  }
}


# for module loading!
1;

=pod

=head1 FURTHER INFORMATION AND BUG REPORTING

For more information, see the `Filename database' section of
Kpathsea manual available at http://tug.org/kpathsea.

Report bugs to: tex-k@tug.org

=head1 AUTHORS AND COPYRIGHT

This script and its documentation were written for the TeX Live
distribution (L<http://tug.org/texlive>) and both are licensed under the
GNU General Public License Version 2 or later.

=cut


### Local Variables:
### perl-indent-level: 2
### tab-width: 2
### indent-tabs-mode: nil
### End:
# vim:set tabstop=2 expandtab: #
