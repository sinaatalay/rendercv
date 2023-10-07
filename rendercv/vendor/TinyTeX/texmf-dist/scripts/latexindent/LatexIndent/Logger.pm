package LatexIndent::Logger;

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
use Exporter;
use LatexIndent::Switches qw/%switches/;
our @ISA       = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/@logFileLines/;
our @logFileLines;

sub info {
    my $self        = shift;
    my $logfileline = shift;
    return unless ( defined $logfileline );
    if ( $logfileline =~ m/^\*/s ) {
        $logfileline =~ s/^\*/INFO:  /s;
        $logfileline =~ s/^/        /mg;
        $logfileline =~ s/^\h+INFO/INFO/s;
    }
    else {
        $logfileline =~ s/^/       /mg;
    }
    push( @logFileLines, $logfileline );
    print $logfileline, "\n" if $switches{screenlog};
}

sub warn {
    my $self        = shift;
    my $logfileline = shift;
    if ( $logfileline =~ m/^\*/s ) {
        $logfileline =~ s/^\*/WARN:  /s;
    }
    else {
        $logfileline =~ s/^/       /mg;
    }
    push( @logFileLines, $logfileline );
    print $logfileline, "\n" if $switches{screenlog};
}

sub fatal {
    my $self        = shift;
    my $logfileline = shift;
    if ( $logfileline =~ m/^\*/s ) {
        $logfileline =~ s/^\*/FATAL /s;
        $logfileline =~ s/^/       /mg;
        $logfileline =~ s/^\h+FATAL/FATAL/s;
    }
    else {
        $logfileline =~ s/^/      /mg;
    }
    push( @logFileLines, $logfileline );
    print $logfileline, "\n";
}

sub trace {
    my $self        = shift;
    my $logfileline = shift;
    if ( $logfileline =~ m/^\*/s ) {
        $logfileline =~ s/^\*/TRACE: /s;
    }
    else {
        $logfileline =~ s/^/       /mg;
    }
    push( @logFileLines, $logfileline );
    print $logfileline, "\n" if $switches{screenlog};
}

1;
