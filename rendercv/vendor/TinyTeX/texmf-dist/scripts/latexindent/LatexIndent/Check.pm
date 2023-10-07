package LatexIndent::Check;

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
use Exporter qw/import/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::Switches qw/$is_m_switch_active $is_check_verbose_switch_active/;
our @ISA       = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/simple_diff/;

sub simple_diff {
    my $self = shift;

    # simple diff...
    $logger->info("*simple diff: (check switch active)");

    # check switch work below here
    if ( ${$self}{originalBody} eq ${$self}{body} ) {
        $logger->info("no differences, no diff to report");
        return;
    }

    # otherwise we loop through the old and new body, and make comparisons
    my @oldBody = split( "\n", ${$self}{originalBody} );
    my @newBody = split( "\n", ${$self}{body} );
    my @diff    = ();

    # this loop stores the differences ...
    if ($is_m_switch_active) {

        # if -m *is* active, then the number of lines in old and new may not be the same
        # so we need to go through the options
        my $maxLines = ( $#oldBody >= $#newBody ? $#oldBody : $#newBody );

        # loop through to maxLines, accounting for the three scenarios:
        #
        #   oldBody[lineCount] and newBody[lineCount] both defined
        #   oldBody[lineCount] defined and newBody[lineCount] not defined
        #   oldBody[lineCount] not defined and newBody[lineCount] defined
        #
        for ( my $lineCount = 0; $lineCount <= $maxLines; $lineCount++ ) {
            if ( $lineCount <= $#oldBody and $lineCount <= $#newBody ) {
                if ( $oldBody[$lineCount] ne $newBody[$lineCount] ) {
                    push( @diff,
                        { old => $oldBody[$lineCount], new => $newBody[$lineCount], lineNumber => $lineCount + 1 } );
                }
            }
            elsif ( $lineCount <= $#oldBody ) {
                push( @diff, { old => $oldBody[$lineCount], lineNumber => $lineCount + 1 } );
            }
            else {
                push( @diff, { new => $newBody[$lineCount], lineNumber => $lineCount + 1 } );
            }
        }
    }
    else {
        # if -m is not active, then the number of lines in old and new will be the same
        for ( my $lineCount = 0; $lineCount <= $#oldBody; $lineCount++ ) {
            if ( $oldBody[$lineCount] ne $newBody[$lineCount] ) {
                push( @diff,
                    { old => $oldBody[$lineCount], new => $newBody[$lineCount], lineNumber => $lineCount + 1 } );
            }
        }
    }

    # initialise the old and new tmp body for storage
    my $tmpOldBody         = '-';
    my $tmpNewBody         = '+';
    my $previousLineNumber = -1;

    # and the 'diff chunk' storage array
    my @diffChunks               = ();
    my $diffChunkFirstLineNumber = ${ $diff[0] }{lineNumber};

    # ... and this loop combines the diffs into chunks
    for my $i ( 0 .. $#diff ) {

        my $currentLineNumber = ${ $diff[$i] }{lineNumber};

        if ( $i == $#diff
            or ( $previousLineNumber >= 0 and $currentLineNumber > ( $previousLineNumber + 1 ) ) )
        {

            my $lastLine = ${ $diff[ $i - 1 ] }{lineNumber};

            if ( $i == $#diff ) {
                $lastLine = $currentLineNumber;
                $tmpOldBody .= ( $tmpOldBody eq '-' ? q() : "\n-" ) . ${ $diff[$i] }{old};
                $tmpNewBody .= ( $tmpNewBody eq '+' ? q() : "\n+" ) . ${ $diff[$i] }{new};
            }

            push(
                @diffChunks,
                {   old       => $tmpOldBody,
                    new       => $tmpNewBody,
                    firstLine => $diffChunkFirstLineNumber,
                    lastLine  => $lastLine
                }
            );

            $tmpOldBody = '-' . ${ $diff[$i] }{old} if defined ${ $diff[$i] }{old};
            $tmpNewBody = '+' . ${ $diff[$i] }{new} if defined ${ $diff[$i] }{new};
            $diffChunkFirstLineNumber = $currentLineNumber;
        }
        else {
            $tmpOldBody .= ( $tmpOldBody eq '-' ? q() : "\n-" ) . ${ $diff[$i] }{old} if defined ${ $diff[$i] }{old};
            $tmpNewBody .= ( $tmpNewBody eq '+' ? q() : "\n+" ) . ${ $diff[$i] }{new} if defined ${ $diff[$i] }{new};
        }

        $previousLineNumber = ${ $diff[$i] }{lineNumber};
    }

    # finally, output the diff chunks
    foreach (@diffChunks) {
        $logger->info("@@ ${$_}{firstLine} -- ${$_}{lastLine} @@");
        $logger->info( ${$_}{old} );
        $logger->info( ${$_}{new} );

        # possibly output to terminal
        if ($is_check_verbose_switch_active) {
            print "\n@@ ${$_}{firstLine} -- ${$_}{lastLine} @@\n";
            print ${$_}{old}, "\n";
            print ${$_}{new}, "\n";
        }
    }
}

1;
