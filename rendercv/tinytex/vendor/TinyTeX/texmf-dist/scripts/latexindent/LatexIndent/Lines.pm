package LatexIndent::Lines;

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
use LatexIndent::Switches qw/%switches/;
use LatexIndent::Verbatim qw/%verbatimStorage/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/lines_body_selected_lines lines_verbatim_create_line_block/;

sub lines_body_selected_lines {
    my $self  = shift;
    my @lines = @{ $_[0] };

    # strip all space from lines switch
    $switches{lines} =~ s/\h//sg;

    # convert multiple - into single
    $switches{lines} =~ s/-+/-/sg;

    $logger->info("*-n,--lines switch is active, operating on lines $switches{lines}");
    $logger->info( "number of lines in file: " . ( $#lines + 1 ) );
    $logger->info("*interpreting $switches{lines}");

    my @lineRanges = split( /,/, $switches{lines} );
    my @indentLineRange;
    my @NOTindentLineRange;

    my %minMaxStorage;
    my %negationMinMaxStorage;

    # loop through line ranges, which are separated by commas
    #
    #       --lines 3-15,17-19
    #
    foreach (@lineRanges) {
        my $minLine      = 0;
        my $maxLine      = 0;
        my $negationMode = 0;

        #
        #  --lines !3-15
        #
        if ( $_ =~ m/!/s ) {
            $negationMode = 1;
            $_ =~ s/!//s;
            $logger->info("negation mode active as $_");
        }

        #  --lines min-max
        if ( $_ =~ m/-/s ) {
            ( $minLine, $maxLine ) = split( /-/, $_ );
        }
        else {
            $minLine = $_;
            $maxLine = $_;
        }

        # both minLine and maxLine need to be INTEGERS
        if ( $minLine !~ m/^\d+$/ or $maxLine !~ m/^\d+$/ ) {
            $logger->warn("*$_ not a valid line specification; I'm ignoring this entry");
            next;
        }

        # swap minLine and maxLine if necessary
        if ( $minLine > $maxLine ) {
            ( $minLine, $maxLine ) = ( $maxLine, $minLine );
        }

        # minline > number of lines needs addressing
        if ( $minLine - 1 > $#lines ) {
            $logger->warn(
                "*--lines specified with min line $minLine which is *greater than* the number of lines in file: "
                    . ( $#lines + 1 ) );
            $logger->warn( "adjusting this value to be " . ( $#lines + 1 ) );
            $minLine = $#lines + 1;
        }

        # maxline > number of lines needs addressing
        if ( $maxLine - 1 > $#lines ) {
            $logger->warn(
                "*--lines specified with max line $maxLine which is *greater than* the number of lines in file: "
                    . ( $#lines + 1 ) );
            $logger->warn( "adjusting this value to be " . ( $#lines + 1 ) );
            $maxLine = $#lines + 1;
        }

        # either store the negation, or not
        if ($negationMode) {
            $negationMinMaxStorage{$minLine} = $maxLine;
        }
        else {
            $minMaxStorage{$minLine} = $maxLine;
        }
        $logger->info("min line: $minLine, max line: $maxLine");
    }

    # only proceed if we have a valid line range
    if ( ( keys %minMaxStorage ) < 1 and ( keys %negationMinMaxStorage ) < 1 ) {
        $logger->warn("*--lines not specified with valid range: $switches{lines}");
        $logger->warn("entire body will be indented, and ignoring $switches{lines}");
        $switches{lines} = 0;
        ${$self}{body} = join( "", @lines );
        return;
    }

    # we need to perform the token check here
    ${$self}{body} = join( "", @lines );
    $self->token_check;
    ${$self}{body} = q();

    # negated line ranges
    if ( keys %negationMinMaxStorage >= 1 ) {
        @NOTindentLineRange = &lines_sort_and_combine_line_range( \%negationMinMaxStorage );

        $logger->info("*negation line range summary: ");
        $logger->info( "the number of NEGATION line ranges: " . ( ( $#NOTindentLineRange + 1 ) / 2 ) );
        $logger->info("the *sorted* NEGATION line ranges are in the form MIN-MAX: ");
        for ( my $index = 0; $index < ( ( $#NOTindentLineRange + 1 ) / 2 ); $index++ ) {
            $logger->info( join( "-", @NOTindentLineRange[ 2 * $index .. 2 * $index + 1 ] ) );

            if ( $index == 0 and $NOTindentLineRange[ 2 * $index ] > 1 ) {
                $minMaxStorage{1} = $NOTindentLineRange[ 2 * $index ] - 1;
            }
            elsif ( $index > 0 ) {
                $minMaxStorage{ $NOTindentLineRange[ 2 * $index - 1 ] + 1 } = $NOTindentLineRange[ 2 * $index ] - 1;
            }
        }

        # final range
        if ( $NOTindentLineRange[-1] < $#lines ) {
            $minMaxStorage{ $NOTindentLineRange[-1] + 1 } = $#lines + 1;
        }
    }

    @indentLineRange = &lines_sort_and_combine_line_range( \%minMaxStorage ) if ( keys %minMaxStorage >= 1 );

    $logger->info("*line range summary: ");
    $logger->info( "the number of indent line ranges: " . ( ( $#indentLineRange + 1 ) / 2 ) );
    $logger->info("the *sorted* line ranges are in the form MIN-MAX: ");
    for ( my $index = 0; $index < ( ( $#indentLineRange + 1 ) / 2 ); $index++ ) {
        $logger->info( join( "-", @indentLineRange[ 2 * $index .. 2 * $index + 1 ] ) );
    }

    my $startLine = 0;

    # now that we have the line range, we can sort arrange the body
    while ( $#indentLineRange > 0 ) {
        my $minLine = shift(@indentLineRange);
        my $maxLine = shift(@indentLineRange);

        # perl arrays start at 0
        $minLine--;
        $maxLine--;

        $self->lines_verbatim_create_line_block( \@lines, $startLine, $minLine - 1 ) unless ( $minLine == 0 );

        ${$self}{body} .= join( "", @lines[ $minLine .. $maxLine ] );

        $startLine = $maxLine + 1;
    }

    # final line range
    $self->lines_verbatim_create_line_block( \@lines, $startLine, $#lines ) if ( $startLine <= $#lines );
    return;
}

sub lines_sort_and_combine_line_range {

    my %minMaxStorage = %{ $_[0] };
    #
    #     --lines 8-10,4-5,1-2
    #
    # needs to be interpreted as
    #
    #     --lines 1-2,4-5,8-10,
    #
    # sort the line ranges by the *minimum* value, the associated
    # maximum values will be arranged after this
    my @indentLineRange = sort { $a <=> $b } keys(%minMaxStorage);

    my @justMinimumValues = @indentLineRange;
    for ( my $index = 0; $index <= $#justMinimumValues; $index++ ) {
        splice( @indentLineRange, 2 * $index + 1, 0, $minMaxStorage{ $justMinimumValues[$index] } );
    }

    for ( my $index = 1; $index < ( ( $#indentLineRange + 1 ) / 2 ); $index++ ) {
        my $currentMin  = $indentLineRange[ 2 * $index ];
        my $currentMax  = $indentLineRange[ 2 * $index + 1 ];
        my $previousMax = $indentLineRange[ 2 * $index - 1 ];
        my $previousMin = $indentLineRange[ 2 * $index - 2 ];

        if ( ( $currentMin - 1 ) <= $previousMax and ( $currentMax > $previousMax ) ) {

            # overlapping line ranges, for example
            #
            #     --lines 3-5,4-10
            #
            # needs to be interpreted as
            #
            #     --lines 3-10
            #
            $logger->info("overlapping line range found");
            $logger->info( "line ranges (before): " . join( ", ", @indentLineRange ) );
            splice( @indentLineRange, 2 * $index - 1, 2 );
            $logger->info( "line ranges (after): " . join( ", ", @indentLineRange ) );

            # reset index so that loop starts again
            $index = 0;
        }
        elsif ( ( $currentMin - 1 ) <= $previousMax and ( $currentMax <= $previousMax ) ) {

            # overlapping line ranges, for example
            #
            #     --lines 3-7,4-6
            #
            # needs to be interpreted as
            #
            #     --lines 3-7
            #
            $logger->info("overlapping line range found");
            $logger->info( "line ranges (before): " . join( ", ", @indentLineRange ) );
            splice( @indentLineRange, 2 * $index, 2 );
            $logger->info( "line ranges (after): " . join( ", ", @indentLineRange ) );

            # reset index so that loop starts again
            $index = 0;
        }
    }

    return @indentLineRange;
}

sub lines_verbatim_create_line_block {
    my $self       = shift;
    my @lines      = @{ $_[0] };
    my $startLine  = $_[1];
    my $finishLine = $_[2];

    my $verbBody = join( "", @lines[ $startLine .. $finishLine ] );
    $verbBody =~ s/\R?$//s;

    # create a new Verbatim object
    my $noIndentBlockObj = LatexIndent::Verbatim->new(
        begin                    => q(),
        body                     => $verbBody,
        end                      => q(),
        name                     => "line-switch-verbatim-protection",
        type                     => "linesprotect",
        modifyLineBreaksYamlName => "lines-not-to-be-indented",
    );

    # give unique id
    $noIndentBlockObj->create_unique_id;

    # verbatim children go in special hash
    $verbatimStorage{ ${$noIndentBlockObj}{id} } = $noIndentBlockObj;

    # remove the environment block, and replace with unique ID
    ${$self}{body} .= ${$noIndentBlockObj}{id} . "\n";

    return;
}

1;
