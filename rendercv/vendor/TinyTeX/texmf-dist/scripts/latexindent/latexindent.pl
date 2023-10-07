#!/usr/bin/env perl
#
#   latexindent.pl, version 3.22.2, 2023-07-14
#
#	This program is free software: you can redistribute it and/or modify
#	it under the terms of the GNU General Public License as published by
#	the Free Software Foundation, either version 3 of the License, or
#	(at your option) any later version.
#
#	This program is distributed in the hope that it will be useful,
#	but WITHOUT ANY WARRANTY; without even the implied warranty of
#	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#	GNU General Public License for more details.
#
#	See http://www.gnu.org/licenses/.
#
#	Chris Hughes, 2017
#
#	For all communication, please visit: https://github.com/cmhughes/latexindent.pl

use strict;
use warnings;
use FindBin;         # help find defaultSettings.yaml
use Getopt::Long;    # to get the switches/options/flags

# use lib to make sure that @INC contains the latexindent directory
use lib $FindBin::RealBin;
use LatexIndent::Document;

# get the options
my %switches = ( readLocalSettings => 0 );

GetOptions(
    "version|v"                 => \$switches{version},
    "vversion|vv"               => \$switches{vversion},
    "silent|s"                  => \$switches{silentMode},
    "trace|t"                   => \$switches{trace},
    "ttrace|tt"                 => \$switches{ttrace},
    "local|l:s"                 => \$switches{readLocalSettings},
    "yaml|y=s"                  => \$switches{yaml},
    "onlydefault|d"             => \$switches{onlyDefault},
    "overwrite|w"               => \$switches{overwrite},
    "overwriteIfDifferent|wd"   => \$switches{overwriteIfDifferent},
    "outputfile|o=s"            => \$switches{outputToFile},
    "modifylinebreaks|m"        => \$switches{modifyLineBreaks},
    "logfile|g=s"               => \$switches{logFileName},
    "help|h"                    => \$switches{showhelp},
    "cruft|c=s"                 => \$switches{cruftDirectory},
    "screenlog|sl"              => \$switches{screenlog},
    "replacement|r"             => \$switches{replacement},
    "onlyreplacement|rr"        => \$switches{onlyreplacement},
    "replacementrespectverb|rv" => \$switches{replacementRespectVerb},
    "check|k"                   => \$switches{check},
    "checkv|kv"                 => \$switches{checkverbose},
    "lines|n=s"                 => \$switches{lines},
    "GCString"                  => \$switches{GCString},
);

# conditionally load the GCString module
eval "use Unicode::GCString" if $switches{GCString};

# check local settings doesn't interfere with reading the file;
# this can happen if the script is called as follows:
#
#       latexindent.pl -l myfile.tex
#
# in which case, the GetOptions routine mistakes myfile.tex
# as the optional parameter to the l flag.
#
# In such circumstances, we correct the mistake by assuming that
# the only argument is the file to be indented, and place it in @ARGV
if ( $switches{readLocalSettings} and scalar(@ARGV) < 1 ) {
    push( @ARGV, $switches{readLocalSettings} );
    $switches{readLocalSettings} = '';
}

# allow STDIN as input, if a filename is not present
unshift( @ARGV, '-' ) unless @ARGV;

my $document = bless(
    {
        name                     => "mainDocument",
        modifyLineBreaksYamlName => "mainDocument",
        switches                 => \%switches
    },
    "LatexIndent::Document"
);
$document->latexindent( \@ARGV );
exit(0);
