package LatexIndent::AlignmentAtAmpersand;

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
use Data::Dumper;
use Exporter qw/import/;
use List::Util qw/max min sum/;
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active %switches/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::HiddenChildren qw/%familyTree/;
use LatexIndent::Verbatim qw/%verbatimStorage/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK
    = qw/align_at_ampersand find_aligned_block double_back_slash_else main_formatting individual_padding multicolumn_padding multicolumn_pre_check multicolumn_post_check dont_measure hidden_child_cell_row_width hidden_child_row_width get_column_width/;
our $alignmentBlockCounter;
our @cellStorage;                      # two-dimensional storage array containing the cell information
our @formattedBody;                    # array for the new body
our @minMultiColSpan;
our @maxColumnWidth;
our @maxDelimiterWidth;

sub find_aligned_block {

    my $self = shift;

    return unless ( ${$self}{body} =~ m/(?!<\\)%\*\h*\\begin\{/s );

    # aligned block
    #      %* \begin{tabular}
    #         1 & 2 & 3 & 4 \\
    #         5 &   & 6 &   \\
    #        %* \end{tabular}
    $logger->trace('*Searching for ALIGNED blocks marked by comments')  if ($is_t_switch_active);
    $logger->trace( Dumper( \%{ $mainSettings{lookForAlignDelims} } ) ) if ($is_tt_switch_active);
    while ( my ( $alignmentBlock, $yesno ) = each %{ $mainSettings{lookForAlignDelims} } ) {
        if ( ref $yesno eq "HASH" ) {
            $yesno = ( defined ${$yesno}{delims} ) ? ${$yesno}{delims} : 1;
        }
        if ($yesno) {
            $logger->trace("looking for %*\\begin\{$alignmentBlock\} environments");

            my $alignmentRegExp = qr/
                            (
                                (?!<\\)
                                %
                                \*
                                \h*                       # possible horizontal spaces
                                \\begin\{
                                        ($alignmentBlock) # environment name captured into $2
                                       \}                 # \begin{alignmentBlock} statement captured into $1
                            )
                            (
                                .*?                       # non-greedy match (body) into $3
                            )
                            \R                            # a line break
                            \h*                           # possible horizontal spaces
                            (
                                (?!<\\)
                                %\*                       # %
                                \h*                       # possible horizontal spaces
                                \\end\{\2\}               # \end{alignmentBlock} statement captured into $4
                            )
                        /sx;

            while ( ${$self}{body} =~ m/$alignmentRegExp/sx ) {

                ${$self}{body} =~ s/
                                    $alignmentRegExp
                                /
                                    # create a new Environment object
                                    my $alignmentBlockObj = LatexIndent::AlignmentAtAmpersand->new( begin=>$1,
                                                                          body=>$3,
                                                                          end=>$4,
                                                                          name=>$2,
                                                                          modifyLineBreaksYamlName=>"environments",
                                                                          linebreaksAtEnd=>{
                                                                            begin=>1,
                                                                            body=>1,
                                                                            end=>0,
                                                                          },
                                                                          );
            
                                    # log file output
                                    $logger->trace("*Alignment block found: %*\\begin\{${$alignmentBlock}{name}\}") if $is_t_switch_active;

                                    # the settings and storage of most objects has a lot in common
                                    $self->get_settings_and_store_new_object($alignmentBlockObj);
                                    
                                    ${@{${$self}{children}}[-1]}{replacementText};
                              /xseg;
            }
        }
        else {
            $logger->trace("*not* looking for $alignmentBlock as $alignmentBlock:$yesno");
        }
    }
    return;
}

sub yaml_modify_line_breaks_settings {
    return;
}

sub tasks_particular_to_each_object {
    return;
}

sub create_unique_id {
    my $self = shift;

    $alignmentBlockCounter++;
    ${$self}{id} = "$tokens{alignmentBlock}$alignmentBlockCounter";
    return;
}

sub align_at_ampersand {
    my $self  = shift;
    my %input = @_;

    return if ( ${$self}{bodyLineBreaks} == 0 );

    # some blocks may contain verbatim to be measured
    ${$self}{measureVerbatim} = ( ${$self}{body} =~ m/$tokens{verbatim}/ ? 1 : 0 );

    my $maximumNumberOfAmpersands = 0;

    # clear the global arrays
    @formattedBody     = ();
    @cellStorage       = ();
    @minMultiColSpan   = ();
    @maxColumnWidth    = ();
    @maxDelimiterWidth = ();

    # maximum column widths
    my @maximumColumnWidths;

    my $rowCounter    = -1;
    my $columnCounter = -1;

    $logger->trace("*dontMeasure routine, row mode") if ( ${$self}{dontMeasure} and $is_t_switch_active );

    #
    # initial loop for column storage and measuring
    #
    foreach ( split( "\n", ${$self}{body} ) ) {
        $rowCounter++;

        # default is to measure this row, but it can be switched off by the dont_measure routine
        ${$self}{measureRow} = 1;

        # call the dont_measure routine
        $self->dont_measure( mode => "row", row => $_ ) if ${$self}{dontMeasure};

        # remove \\ and anything following it
        my $endPiece = q();
        if ( $_ =~ m/(\\\\.*)/ ) {
            if ( ${$self}{alignFinalDoubleBackSlash} ) {

                # for example, if we want:
                #
                #  Name & \shortstack{Hi \\ Lo} \\      <!--- Note this row!
                #  Foo  & Bar                   \\
                #
                # in the first row, note that the first \\
                # needs to be ignored, and we align by
                # the final double back slash

                $_ =~ s/(\\\\
                          (?:                      
                              (?!                 
                                  (?:\\\\)           
                              ).            # any character, but not \\
                          )*?$              # non-greedy
                        )//sx;
                $endPiece = $1;
            }
            else {
                $_ =~ s/(\\\\.*)//;
                $endPiece = $1;
            }
        }

        # remove any trailing comments
        my $trailingComments;
        if ( $_ =~ m/$trailingCommentRegExp/ ) {
            $_ =~ s/($trailingCommentRegExp)//;
            $trailingComments = $1;
        }

        # some rows shouldn't be formatted
        my $unformattedRow = $_;

        # delimiters regex, default is:
        #
        #   (?<!\\)&
        #
        # which is set in GetYamlSettings.pm, but can be set
        # by the user using, for example
        #
        #   lookForAlignDelims:
        #       tabular:
        #           delimiter: '\<'
        #
        my $delimiterRegEx = qr/${$self}{delimiterRegEx}/;

        my $numberOfAmpersands = () = $_ =~ /$delimiterRegEx/g;
        $maximumNumberOfAmpersands = $numberOfAmpersands if ( $numberOfAmpersands > $maximumNumberOfAmpersands );

        # remove space at the beginning of a row, surrounding &, and at the end of the row
        $_ =~ s/(?<!\\)\h*($delimiterRegEx)\h*/$1/g;
        $_ =~ s/^\h*//g;
        $_ =~ s/\h*$//g;

        # if the line finishes with an &, then add an empty space,
        # otherwise the column count is off
        $_ .= ( $_ =~ m/$delimiterRegEx$/ ? " " : q() );

        # store the columns, which are either split by &
        # or otherwise simply the current line, if for example, the current line simply
        # contains \multicolumn{8}... \\  (see test-cases/texexchange/366841-zarko.tex, for example)
        my @columns = ( $_ =~ m/$delimiterRegEx/ ? split( /($delimiterRegEx)/, $_ ) : $_ );

        $columnCounter = -1;
        my $spanning = 0;

        foreach my $column (@columns) {

            # if a column contains only the delimiter, then we need to
            #       - measure it
            #       - add it and its length to the previous cell
            #       - remove it from the columns array
            #
            if ( $column =~ m/$delimiterRegEx/ ) {

                # update the delimiter to be used, and its associated length
                # for the *previous* cell
                my $spanningOffSet = ( $spanning > 0 ? $spanning - 1 : 0 );
                ${ $cellStorage[$rowCounter][ $columnCounter - $spanningOffSet ] }{delimiter} = $1;
                ${ $cellStorage[$rowCounter][ $columnCounter - $spanningOffSet ] }{delimiterLength}
                    = &get_column_width($1);

                # keep track of maximum delimiter width
                $maxDelimiterWidth[ $columnCounter - $spanningOffSet ] = (
                    defined $maxDelimiterWidth[ $columnCounter - $spanningOffSet ]
                    ? max( $maxDelimiterWidth[ $columnCounter - $spanningOffSet ],
                        ${ $cellStorage[$rowCounter][ $columnCounter - $spanningOffSet ] }{delimiterLength} )
                    : ${ $cellStorage[$rowCounter][ $columnCounter - $spanningOffSet ] }{delimiterLength}
                );

                # importantly, move on to the next column!
                next;
            }

            # otherwise increment the column counter, and proceed
            $columnCounter++;

            # reset spanning (only applicable if multiColumnGrouping)
            $spanning = 0;

            # if a column has finished with a \ then we need to add a trailing space,
            # otherwise the \ can be put next to &. See test-cases/texexchange/112343-gonzalo for example
            $column .= ( $column =~ m/\\$/ ? " " : q() );

            # basic cell storage
            $cellStorage[$rowCounter][$columnCounter] = (
                {   width           => &get_column_width($column),
                    entry           => $column,
                    type            => ( $numberOfAmpersands > 0 ? "X" : "*" ),
                    groupPadding    => 0,
                    colSpan         => ".",
                    delimiter       => "",
                    delimiterLength => 0,
                    measureThis     => ( $numberOfAmpersands > 0 ? ${$self}{measureRow} : 0 ),
                    DBSpadding      => 0,
                }
            );

            #
            # if content is to be aligned after \\
            # (using alignContentAfterDoubleBackSlash) then we need to
            # adjust the width of the first cell
            #
            if ( defined $input{beforeDBSlengths} and $columnCounter == 0 ) {
                my $currentRowDBSlength = ${ $input{beforeDBSlengths} }[ $rowCounter + 1 ];
                ${ $cellStorage[$rowCounter][$columnCounter] }{width}
                    += $currentRowDBSlength + ( $input{maxDBSlength} - $currentRowDBSlength );

                ${ $cellStorage[$rowCounter][$columnCounter] }{DBSpadding}
                    = ( $input{maxDBSlength} - $currentRowDBSlength );

            }

            # possible hidden children, see https://github.com/cmhughes/latexindent.pl/issues/85
            if ( ( ${$self}{measureHiddenChildren} or ${$self}{measureVerbatim} )
                and $column =~ m/.*?$tokens{beginOfToken}/s )
            {
                $self->hidden_child_cell_row_width( $column, $rowCounter, $columnCounter );
            }

            # store the maximum column width
            $maxColumnWidth[$columnCounter] = (
                defined $maxColumnWidth[$columnCounter]
                ? max( $maxColumnWidth[$columnCounter], ${ $cellStorage[$rowCounter][$columnCounter] }{width} )
                : ${ $cellStorage[$rowCounter][$columnCounter] }{width}
            ) if ${ $cellStorage[$rowCounter][$columnCounter] }{type} eq "X";

            # \multicolumn cell
            if ( ${$self}{multiColumnGrouping} and $column =~ m/\\multicolumn\{(\d+)\}/ and $1 > 1 ) {
                $spanning = $1;

                # adjust the type
                ${ $cellStorage[$rowCounter][$columnCounter] }{type} = "$spanning";

                # some \multicol cells can have their spanning information removed from type
                # so we store it in colSpan as well
                ${ $cellStorage[$rowCounter][$columnCounter] }{colSpan} = $spanning;

                # and don't measure it
                ${ $cellStorage[$rowCounter][$columnCounter] }{measureThis} = 0;

                # create 'gap' columns
                for ( my $j = $columnCounter + 1; $j <= $columnCounter + ( $spanning - 1 ); $j++ ) {
                    $cellStorage[$rowCounter][$j] = (
                        {   type              => "-",
                            entry             => '',
                            width             => 0,
                            individualPadding => 0,
                            groupPadding      => 0,
                            colSpan           => ".",
                            delimiter         => "",
                            delimiterLength   => 0,
                            DBSpadding        => 0,
                            measureThis       => 0
                        }
                    );
                }

                # store the minimum spanning value
                $minMultiColSpan[$columnCounter] = (
                    defined $minMultiColSpan[$columnCounter]
                    ? min( $minMultiColSpan[$columnCounter], $spanning )
                    : $spanning
                );

                # adjust the column counter
                $columnCounter += $spanning - 1;
            }
        }

        # store the information
        push(
            @formattedBody,
            {   row                => $_,
                endPiece           => $endPiece,
                trailingComment    => $trailingComments,
                numberOfAmpersands => $numberOfAmpersands,
                unformattedRow     => $unformattedRow
            }
        );

    }

    # store the maximum number of ampersands
    ${$self}{maximumNumberOfAmpersands} = $maximumNumberOfAmpersands;

    # blocks with nested multicolumns need some pre checking
    $self->multicolumn_pre_check if ${$self}{multiColumnGrouping};

    # maximum column width loop, and individual padding
    $self->individual_padding;

    # multi column rearrangement and multicolumn padding
    $self->multicolumn_padding if ${$self}{multiColumnGrouping};

    # multi column post check to ensure that multicolumn commands have received appropriate padding
    $self->multicolumn_post_check if ${$self}{multiColumnGrouping};

    # output to log file
    if ($is_t_switch_active) {
        &pretty_print_cell_info($_)
            for (
            "entry",       "type",               "colSpan",           "width",
            "measureThis", "maximumColumnWidth", "individualPadding", "groupPadding",
            "delimiter",   "delimiterLength",    "DBSpadding"
            );
    }

    # main formatting loop
    $self->main_formatting;

    if ( defined $input{measure_after_DBS} ) {

        # delete the original body
        ${$self}{body} = q();

        # update the body
        ${$self}{body} .= ${$_}{row} . "\n" for @formattedBody;

        return;
    }

    #
    # final \\ loop
    #
    foreach (@formattedBody) {

        # reset the padding
        my $padding = q();

        # possibly adjust the padding
        if ( ${$_}{row} !~ m/^\h*$/ ) {

            # remove trailing horizontal space if ${$self}{alignDoubleBackSlash} is set to 0
            ${$_}{row} =~ s/\h*$// if ( !${$self}{alignDoubleBackSlash} );

            # format spacing infront of \\
            if (    defined ${$self}{spacesBeforeDoubleBackSlash}
                and ${$self}{spacesBeforeDoubleBackSlash} < 0
                and !${$self}{alignDoubleBackSlash} )
            {
                # zero spaces (possibly resulting in un-aligned \\)
                $padding = q();
            }
            elsif ( defined ${$self}{spacesBeforeDoubleBackSlash}
                and ${$self}{spacesBeforeDoubleBackSlash} >= 0
                and !${$self}{alignDoubleBackSlash} )
            {
                # specified number of spaces (possibly resulting in un-aligned \\)
                $padding = " " x ( ${$self}{spacesBeforeDoubleBackSlash} );
            }
            else {
                # aligned \\
                $padding = " " x max( 0, ( ${$self}{maximumRowWidth} - ${$_}{rowWidth} ) );
            }
        }

        # format the row, and put the trailing \\ and trailing comments back into the row
        ${$_}{row}
            .= $padding
            . ( ${$_}{endPiece}        ? ${$_}{endPiece}        : q() )
            . ( ${$_}{trailingComment} ? ${$_}{trailingComment} : q() );

        # some rows shouldn't be formatted, and may only have trailing comments;
        # see test-cases/alignment/table4.tex for example
        if (( ${$_}{numberOfAmpersands} == 0 and !${$_}{endPiece} )
            or (    ${$_}{numberOfAmpersands} < ${$self}{maximumNumberOfAmpersands}
                and !${$self}{alignRowsWithoutMaxDelims}
                and !${$_}{endPiece} )
            )
        {
            ${$_}{row} = ( ${$_}{unformattedRow} ne "" ? ${$_}{unformattedRow} : q() )
                . ( ${$_}{trailingComment} ? ${$_}{trailingComment} : q() );
        }

        # spaces for leadingBlankColumn in operation
        if ( ${$self}{leadingBlankColumn} > -1 ) {
            $padding = " " x ( ${$self}{leadingBlankColumn} );
            ${$_}{row} =~ s/^\h*/$padding/s;
        }
    }

    #
    # put original body and 'after DBS body' together
    #
    if ( ${$self}{alignContentAfterDoubleBackSlash} ) {

        # check that spacesAfterDoubleBackSlash>=0
        ${$self}{spacesAfterDoubleBackSlash} = max( ${$self}{spacesAfterDoubleBackSlash}, 0 );

        my @beforeDBSlengths      = q();
        my @originalFormattedBody = @formattedBody;
        my $afterDBSbody          = q();
        my $maxDBSlength          = 0;
        foreach (@originalFormattedBody) {
            ${$_}{row} =~ s/(.*?)(${${$mainSettings{fineTuning}}{modifyLineBreaks}}{doubleBackSlash})\h*//s;
            ${$_}{beforeDBS} = ( $1 ? $1 : q() );
            ${$_}{DBS}       = ( $2 ? $2 : q() );
            ${$_}{DBS} .= " " x ( ${$self}{spacesAfterDoubleBackSlash} ) if ( ${$_}{DBS} ne '' );
            $afterDBSbody .= ${$_}{row} . "\n";
            push( @beforeDBSlengths, &get_column_width( ${$_}{beforeDBS} . ${$_}{DBS} ) );
            $maxDBSlength = max( $maxDBSlength, &get_column_width( ${$_}{beforeDBS} . ${$_}{DBS} ) );
        }

        ${$self}{body} = $afterDBSbody;
        $self->align_at_ampersand(
            measure_after_DBS => 1,
            beforeDBSlengths  => \@beforeDBSlengths,
            maxDBSlength      => $maxDBSlength
        );

        # create new afterDBSbody
        my @afterDBSbody = split( "\n", ${$self}{body} );

        # combine ORIGINAL body and ENDPIECE body
        my $index = -1;
        foreach (@originalFormattedBody) {
            $index++;
            ${$_}{row} = ${$_}{beforeDBS} . ${$_}{DBS};
            ${$_}{row} .= $afterDBSbody[$index];
        }

        @formattedBody = @originalFormattedBody;
    }

    # delete the original body
    ${$self}{body} = q();

    # update the body
    ${$self}{body} .= ${$_}{row} . "\n" for @formattedBody;

    # if the \end{} statement didn't originally have a line break before it, we need to remove the final
    # line break added by the above
    ${$self}{body} =~ s/\h*\R$//s if !${$self}{linebreaksAtEnd}{body};

    # if the \begin{} statement doesn't finish with a line break, then we adjust the indentation
    # to be the length of the begin statement.
    #
    # example:
    #
    #       \begin{align*}1&2\\
    #         3&4\\
    #         5 &    6
    #       \end{align*}
    #
    # goes to
    #
    #       \begin{align*}1 & 2 \\
    #                     3 & 4 \\
    #                     5 & 6
    #       \end{align*}
    #
    # see https://github.com/cmhughes/latexindent.pl/issues/223 for example

    if (   !${ ${$self}{linebreaksAtEnd} }{begin}
        and ${ $cellStorage[0][0] }{type} eq "X"
        and ${ $cellStorage[0][0] }{measureThis} )
    {

        my $lengthOfBegin = ${$self}{begin};
        if ( ( ${$self}{begin} eq '{' | ${$self}{begin} eq '[' ) and ${$self}{parentBegin} ) {
            $lengthOfBegin = ${$self}{parentBegin} . "{";
        }
        ${$self}{indentation} = " " x ( &get_column_width($lengthOfBegin) );
        $logger->trace("Adjusting indentation of ${$self}{name} in AlignAtAmpersand routine") if ($is_t_switch_active);
    }
}

sub main_formatting {

    # PURPOSE:
    #   (1) perform the *padding* operations
    #       by adding
    #
    #           <spacesBeforeAmpersand>
    #           &
    #           <spacesEndAmpersand>
    #
    #       to the cell entries, accounting for
    #       the justification being LEFT or RIGHT
    #
    #   (2) measure the row width and store
    #       the maximum row width for use with
    #       the (possible) alignment of the \\
    #
    my $self = shift;

    ${$self}{maximumRowWidth} = 0;

    #
    # objective (1): padding
    #

    $logger->trace("*formatted rows for: ${$self}{name}") if ($is_t_switch_active);

    my $rowCount = -1;

    # row loop
    foreach my $row (@cellStorage) {
        $rowCount++;

        # clear the temporary row
        my $tmpRow = q();

        # column loop
        foreach my $cell (@$row) {
            if ( ${$cell}{type} eq "*" or ${$cell}{type} eq "-" ) {
                $tmpRow .= ${$cell}{entry};
                next;
            }

            # alignment *after* double back slash, see
            #
            #   test-cases/alignment/issue-393.tex
            #
            $tmpRow .= " " x ${$cell}{DBSpadding};

            # the placement of the padding is dependent on the value of justification
            if ( ${$self}{justification} eq "left" ) {

                #
                # LEFT:
                #
                #   <cell entry> <individual padding> <group padding> ...
                $tmpRow .= ${$cell}{entry};
                $tmpRow .= " " x ${$cell}{individualPadding};
                $tmpRow .= " " x ${$cell}{groupPadding};
            }
            else {
                #
                # RIGHT:
                #
                #   <group padding> <individual padding> <cell entry> ...
                $tmpRow .= " " x ${$cell}{groupPadding};
                $tmpRow .= " " x ${$cell}{individualPadding};
                $tmpRow .= ${$cell}{entry};
            }

            # either way, finish with:  <spacesBeforeAmpersand> & <spacesAfterAmpersand>
            $tmpRow .= " " x ${$self}{spacesBeforeAmpersand};
            $tmpRow .= ${$cell}{delimiter};
            $tmpRow .= " " x ${$self}{spacesAfterAmpersand};
        }

        # if alignRowsWithoutMaxDelims = 0
        # and there are *less than* the maximum number of ampersands, then
        # we undo all of the work above!
        if (   !${$self}{alignRowsWithoutMaxDelims}
            and ${ $formattedBody[$rowCount] }{numberOfAmpersands} < ${$self}{maximumNumberOfAmpersands} )
        {
            $tmpRow = ${ $formattedBody[$rowCount] }{unformattedRow};
        }

        # spacing before \\
        my $finalSpacing = q();
        $finalSpacing = " " x ( ${$self}{spacesBeforeDoubleBackSlash} ) if ${$self}{spacesBeforeDoubleBackSlash} >= 1;
        $tmpRow =~ s/\h*$/$finalSpacing/;

        # if $tmpRow is made up of only horizontal space, then empty it
        $tmpRow = q() if ( $tmpRow =~ m/^\h*$/ );

        # to the log file
        $logger->trace($tmpRow) if ($is_t_switch_active);

        # store this formatted row
        ${ $formattedBody[$rowCount] }{row} = $tmpRow;

        #
        # objective (2): calculate row width and update maximumRowWidth
        #
        my $rowWidth = &get_column_width($tmpRow);

        # possibly update rowWidth if there are hidden children; see test-cases/alignment/hidden-child1.tex and friends
        $rowWidth = $self->hidden_child_row_width( $tmpRow, $rowCount, $rowWidth )
            if ( ${$self}{measureHiddenChildren} or ${$self}{measureVerbatim} );

        ${ $formattedBody[$rowCount] }{rowWidth} = $rowWidth;

        # update the maximum row width
        if ( $rowWidth > ${$self}{maximumRowWidth}
            and
            !( ${ $formattedBody[$rowCount] }{numberOfAmpersands} == 0 and !${ $formattedBody[$rowCount] }{endPiece} ) )
        {
            ${$self}{maximumRowWidth} = $rowWidth;
        }
    }

    # log file information
    if ( $is_tt_switch_active and ${$self}{measureHiddenChildren} ) {
        $logger->info('*FamilyTree after align for ampersand');
        $logger->trace( Dumper( \%familyTree ) ) if ($is_tt_switch_active);

        $rowCount = -1;

        # row loop
        foreach my $row (@cellStorage) {
            $rowCount++;
            $logger->trace("row $rowCount row width: ${$formattedBody[$rowCount]}{rowWidth}");
        }
    }
}

sub dont_measure {

    my $self  = shift;
    my %input = @_;

    if (    $input{mode} eq "cell"
        and ref( \${$self}{dontMeasure} ) eq "SCALAR"
        and ${$self}{dontMeasure} eq "largest"
        and ${ $cellStorage[ $input{row} ][ $input{column} ] }{width} == $maxColumnWidth[ $input{column} ] )
    {
        # dontMeasure stored as largest, for example
        #
        # lookForAlignDelims:
        #    tabular:
        #       dontMeasure: largest
        $logger->trace(
            "CELL FOUND with maximum column width, $maxColumnWidth[$input{column}], and will not be measured (largest mode)"
        ) if ($is_t_switch_active);
        $logger->trace( "column: ", $input{column}, " width: ",
            ${ $cellStorage[ $input{row} ][ $input{column} ] }{width} )
            if ($is_t_switch_active);
        $logger->trace( "entry: ", ${ $cellStorage[ $input{row} ][ $input{column} ] }{entry} ) if ($is_t_switch_active);
        $logger->trace("--------------------------") if ($is_t_switch_active);
        ${ $cellStorage[ $input{row} ][ $input{column} ] }{measureThis} = 0;
        ${ $cellStorage[ $input{row} ][ $input{column} ] }{type}        = "X";
    }
    elsif ( $input{mode} eq "cell" and ( ref( ${$self}{dontMeasure} ) eq "ARRAY" ) ) {

        # loop through the entries in dontMeasure
        foreach ( @{ ${$self}{dontMeasure} } ) {
            if ( ref( \$_ ) eq "SCALAR" and ${ $cellStorage[ $input{row} ][ $input{column} ] }{entry} eq $_ ) {

                # dontMeasure stored as *strings*, for example:
                #
                #   lookForAlignDelims:
                #      tabular:
                #         dontMeasure:
                #           - \multicolumn{1}{c}{Expiry}
                #           - Tenor
                #           - \multicolumn{1}{c}{$\Delta_{\text{call},10}$}

                $logger->trace("CELL FOUND (this): $_ and will not be measured") if ($is_t_switch_active);
                ${ $cellStorage[ $input{row} ][ $input{column} ] }{measureThis} = 0;
                ${ $cellStorage[ $input{row} ][ $input{column} ] }{type}        = "X";
            }
            elsif ( ref($_) eq "HASH"
                and ${$_}{this}
                and ${ $cellStorage[ $input{row} ][ $input{column} ] }{entry} eq ${$_}{this} )
            {
                # for example:
                #
                #   lookForAlignDelims:
                #      tabular:
                #         dontMeasure:
                #           -
                #               this: \multicolumn{1}{c}{Expiry}
                #               applyTo: cell
                #
                # OR (note that applyTo is optional):
                #
                #   lookForAlignDelims:
                #      tabular:
                #         dontMeasure:
                #           -
                #               this: \multicolumn{1}{c}{Expiry}
                next if ( defined ${$_}{applyTo} and !${$_}{applyTo} eq "cell" );
                $logger->trace("CELL FOUND (this): ${$_}{this} and will not be measured") if ($is_t_switch_active);
                ${ $cellStorage[ $input{row} ][ $input{column} ] }{measureThis} = 0;
                ${ $cellStorage[ $input{row} ][ $input{column} ] }{type}        = "X";
            }
            elsif ( ref($_) eq "HASH" and ${$_}{regex} ) {

                # for example:
                #
                #   lookForAlignDelims:
                #      tabular:
                #         dontMeasure:
                #           -
                #               regex: \multicolumn{1}{c}{Expiry}
                #               applyTo: cell
                #
                # OR (note that applyTo is optional):
                #
                #   lookForAlignDelims:
                #      tabular:
                #         dontMeasure:
                #           -
                #               regex: \multicolumn{1}{c}{Expiry}
                next if ( defined ${$_}{applyTo} and !${$_}{applyTo} eq "cell" );
                my $regex = qr/${$_}{regex}/;
                next unless ${ $cellStorage[ $input{row} ][ $input{column} ] }{entry} =~ m/${$_}{regex}/;
                $logger->trace("CELL FOUND (regex): ${$_}{regex} and will not be measured") if ($is_t_switch_active);
                ${ $cellStorage[ $input{row} ][ $input{column} ] }{measureThis} = 0;
                ${ $cellStorage[ $input{row} ][ $input{column} ] }{type}        = "X";
            }
        }
    }
    elsif ( $input{mode} eq "row" and ( ref( ${$self}{dontMeasure} ) eq "ARRAY" ) ) {
        foreach ( @{ ${$self}{dontMeasure} } ) {

            # move on, unless we have specified applyTo as row:
            #
            #    lookForAlignDelims:
            #       tabular:
            #          dontMeasure:
            #            -
            #                this: \multicolumn{1}{c}{Expiry}
            #                applyTo: row
            #
            # note: *default value* of applyTo is cell
            next unless ( ref($_) eq "HASH" and defined ${$_}{applyTo} and ${$_}{applyTo} eq "row" );
            if ( ${$_}{this} and $input{row} eq ${$_}{this} ) {
                $logger->trace("ROW FOUND (this): ${$_}{this}") if ($is_t_switch_active);
                $logger->trace("and will not be measured")      if ($is_t_switch_active);
                ${$self}{measureRow} = 0;
            }
            elsif ( ${$_}{regex} and $input{row} =~ ${$_}{regex} ) {
                $logger->trace("ROW FOUND (regex): ${$_}{regex}") if ($is_t_switch_active);
                $logger->trace("and will not be measured")        if ($is_t_switch_active);
                ${$self}{measureRow} = 0;
            }
        }
    }
}

sub individual_padding {

    # PURPOSE
    #     (1) the *primary* purpose of this routine is to
    #         measure the *individual padding* of
    #         each cell.
    #
    #         for example, for
    #
    #            111 & 2  & 33333 \\
    #            4   & 55 & 66\\
    #
    #         then the individual padding will be
    #
    #            0    1   0
    #            2    0   3
    #
    #         this is calculated by looping
    #         through the rows & columns
    #         and finding the maximum column widths
    #
    #     (2) the *secondary* purpose of this routine is to
    #         fill in any gaps in the @cellStorage array
    #         for any entries that don't yet exist;
    #
    #         for example,
    #               111 & 2  & 33333 \\
    #               4   & 55 & 66\\
    #               77  & 8   <------ GAP HERE
    #
    #         there is a gap in @cellStorage in the final row,
    #         which is completed by the second loop in the below

    my $self = shift;

    # array to store maximum column widths
    my @maximumColumnWidths;

    # we count the maximum number of columns
    my $maximumNumberOfColumns = 0;

    #
    # maximum column width loop
    #

    $logger->trace("*dontMeasure routine, cell mode") if ( ${$self}{dontMeasure} and $is_t_switch_active );

    # row loop
    my $rowCount = -1;
    foreach my $row (@cellStorage) {
        $rowCount++;

        # column loop
        my $j = -1;
        foreach my $cell (@$row) {
            $j++;

            # if alignRowsWithoutMaxDelims = 0
            # and there are *less than* the maximum number of ampersands, then
            # don't measure this column
            if (   !${$self}{alignRowsWithoutMaxDelims}
                and ${ $formattedBody[$rowCount] }{numberOfAmpersands} < ${$self}{maximumNumberOfAmpersands} )
            {
                ${$cell}{measureThis} = 0;
                ${$cell}{type}        = "*";
            }

            # check if the cell shouldn't be measured
            $self->dont_measure( mode => "cell", row => $rowCount, column => $j ) if ${$self}{dontMeasure};

            # it's possible to have delimiters of different lengths, for example
            #
            #       \begin{tabbing}
            #       	1   # 22  \> 333   # 4444     \\
            #       	xxx # aaa #  yyyyy # zzzzzzzz \\
            #       	.   #     #  &     #          \\
            #
            #       	          ^^
            #       	          ||
            #       \end{tabbing}
            #
            # note that this has a delimiter of \> (length 2) and # (length 1)
            #
            # furthermore, it's possible to specify the delimiter justification as "left" or "right"
            if ( ${$cell}{delimiterLength} > 0 and ${$cell}{delimiterLength} < $maxDelimiterWidth[$j] ) {
                if ( ${$self}{delimiterJustification} eq "left" ) {
                    ${$cell}{delimiter} .= " " x ( $maxDelimiterWidth[$j] - ${$cell}{delimiterLength} );
                }
                elsif ( ${$self}{delimiterJustification} eq "right" ) {
                    ${$cell}{delimiter}
                        = " " x ( $maxDelimiterWidth[$j] - ${$cell}{delimiterLength} ) . ${$cell}{delimiter};
                }

                # update the delimiterLength
                ${$cell}{delimiterLength} = $maxDelimiterWidth[$j];
            }

            # to keep leadingBlankColumn on, we need to check:
            #
            #   - are we in the first column?
            #   - is leadingBlankColumn 0 or more?
            #   - cell width of first column equal 0?
            #   - are we measuring this cell?
            #
            # see test-cases/alignment/issue-275a.tex and the associated logfile
            #
            if ( $j == 0 and ${$self}{leadingBlankColumn} > -1 and ${$cell}{width} > 0 and ${$cell}{measureThis} == 1 )
            {
                ${$self}{leadingBlankColumn} = -1;
            }

            # there are some cells that shouldn't be accounted for in measuring,
            # for example {ccc}
            next if !${$cell}{measureThis};

            # otherwise, make the measurement
            $maximumColumnWidths[$j] = (
                defined $maximumColumnWidths[$j]
                ? max( $maximumColumnWidths[$j], ${$cell}{width} )
                : ${$cell}{width}
            );

        }

        # update the maximum number of columns
        $maximumNumberOfColumns = $j if ( $j > $maximumNumberOfColumns );
    }

    #
    # individual padding and gap filling loop
    #

    # row loop
    foreach my $row (@cellStorage) {

        # column loop
        foreach ( my $j = 0; $j <= $maximumNumberOfColumns; $j++ ) {
            if ( defined ${$row}[$j] ) {

                # individual padding
                my $maximum   = ( defined $maximumColumnWidths[$j] ? $maximumColumnWidths[$j] : 0 );
                my $cellWidth = ${$row}[$j]{width};
                ${$row}[$j]{individualPadding} += ( $maximum > $cellWidth ? $maximum - $cellWidth : 0 );
            }
            else {
                # gap filling
                ${$row}[$j] = (
                    {   type              => "-",
                        entry             => '',
                        width             => 0,
                        individualPadding => 0,
                        groupPadding      => 0,
                        measureThis       => 0,
                        colSpan           => ".",
                        delimiter         => "",
                        delimiterLength   => 0,
                        DBSpadding        => 0,
                    }
                );
            }

            # now the gaps have been filled, store the maximumColumnWidth for future reference
            ${$row}[$j]{maximumColumnWidth} = ( defined $maximumColumnWidths[$j] ? $maximumColumnWidths[$j] : 0 );
        }
    }
}

sub multicolumn_pre_check {

    # PURPOSE:
    #     ensure that multiple multicolumn commands are
    #     handled appropriately
    #
    #     example 1
    #
    #           \multicolumn{2}{c}{thing} &       \\
    #           111 & 2                   & 33333 \\
    #           4   & 55                  & 66    \\
    #           \multicolumn{2}{c}{a}     &       \\
    #
    #              ^^^^^^^^
    #              ||||||||
    #
    #     the second multicolumn command should not be measured, but
    #     *should* receive individual padding
    my $self = shift;

    # loop through minMultiColSpan and add empty entries as necessary
    foreach (@minMultiColSpan) {
        $_ = "." if !( defined $_ );
    }

    # ensure that only the *MINIMUM* multicolumn commands are designated
    # to be measured; for example:
    #
    #     \multicolumn{2}{c|}{Ótimo humano}      & Abuso da pontuação & Recompensas densas \\
    #     \multicolumn{3}{c||}{Exploração Fácil}                      & second             \\
    #     Assault     & Asterix                  & Beam Rider         & Alien              \\
    #
    # the \multicolumn{2}{c|}{Ótimo humano} *is* the minimum multicolumn command
    # for the first column, and the \multicolumn{3}{c||}{Exploração Fácil} *is not*
    # to be measured

    # row loop
    my $rowCount = -1;
    foreach my $row (@cellStorage) {
        $rowCount++;

        # column loop
        my $j = -1;
        foreach my $cell (@$row) {
            $j++;
            if ( ${$cell}{type} =~ m/(\d)/ and ( $1 > $minMultiColSpan[$j] ) ) {
                ${$cell}{type}        = "X";
                ${$cell}{measureThis} = 0;
            }
        }
    }

    # now loop back through and ensure that each of the \multicolumn commands
    # are measured correctly
    #
    # row loop
    $rowCount = -1;
    foreach my $row (@cellStorage) {
        $rowCount++;

        # column loop
        my $j = -1;
        foreach my $cell (@$row) {
            $j++;

            # multicolumn entry
            if ( ${$cell}{type} =~ m/(\d+)/ ) {

                my $multiColumnSpan = $1;

                # *inner* row loop
                my $innerRowCount = -1;
                foreach my $innerRow (@cellStorage) {
                    $innerRowCount++;

                    # we only want to measure the *other* rows
                    next if ( $innerRowCount == $rowCount );

                    # column loop
                    my $innerJ = -1;
                    foreach my $innerCell (@$innerRow) {
                        $innerJ++;

                        if ( $innerJ == $j and ${$innerCell}{type} =~ m/(\d)/ and $1 >= $multiColumnSpan ) {
                            if ( ${$cell}{width} < ${$innerCell}{width} ) {
                                ${$cell}{type}              = "X";
                                ${$cell}{measureThis}       = 0;
                                ${$cell}{individualPadding} = ( ${$innerCell}{width} - ${$cell}{width} );
                            }
                            else {
                                ${$innerCell}{type}              = "X";
                                ${$innerCell}{measureThis}       = 0;
                                ${$innerCell}{individualPadding} = ( ${$cell}{width} - ${$innerCell}{width} );
                            }
                        }
                    }
                }
            }
        }
    }
}

sub multicolumn_padding {

    # PURPOSE:
    #   assign multi column padding, for example:
    #
    #       \multicolumn{2}{c}{thing}&\\
    #       111 &2&33333 \\
    #       4& 55&66\\
    #
    #  needs to be transformed into
    #
    #       \multicolumn{2}{c}{thing} &       \\
    #       111 & 2                   & 33333 \\
    #       4   & 55                  & 66    \\
    #
    #                ^^^^^^^^^^^^^^^
    #                |||||||||||||||
    #
    #  and we need to compute the multi column padding,
    #  illustrated by the up arrows in the above
    #
    #  Approach:
    #   (1) measure the "grouping widths" under/above each of the
    #       \multicolumn entries; these are stored within
    #
    #               groupingWidth
    #
    #       for the relevant column entries; in the
    #       above example, they would be stored in the
    #
    #           2
    #           55
    #
    #       entries when justification is LEFT, and in the
    #
    #           111
    #           4
    #
    #       entries when justification is RIGHT. We also calculate
    #       maximum grouping width and store it within $maxGroupingWidth
    #
    #   (2) loop back through and update
    #
    #           groupPadding
    #
    #       for each of the relevant column entries; in the
    #       above example, they would be stored in the
    #
    #           2
    #           55
    #
    #       entries when justification is LEFT, and in the
    #
    #           111
    #           4
    #
    #   (3) finally, account for the \multicolumn command itself;
    #       ensuring that we account for it being wider or narrower
    #       than its spanning columns
    my $self = shift;

    # row loop
    my $rowCount = -1;
    foreach my $row (@cellStorage) {
        $rowCount++;

        # column loop
        my $j = -1;
        foreach my $cell (@$row) {
            $j++;

            # multicolumn entry
            next unless ( ${$cell}{type} =~ m/(\d+)/ );

            my $multiColumnSpan = $1;

            my $maxGroupingWidth = 0;

            # depending on the
            #
            #    justification
            #
            # setting (left or right), we store the
            #
            #    groupingWidth
            #
            # and groupPadding accordingly
            my $justificationOffset = ( ${$self}{justification} eq "left" ? $j + $multiColumnSpan - 1 : $j );

            #
            # phase (1)
            #

            # *inner* row loop
            my $innerRowCount = -1;
            foreach my $innerRow (@cellStorage) {
                $innerRowCount++;

                # we only want to measure the *other* rows
                next if ( $innerRowCount == $rowCount );

                # we will store the width of columns spanned by the multicolumn command
                my $groupingWidth = 0;

                # *inner* column loop
                for ( my $innerJ = 0; $innerJ < $multiColumnSpan; $innerJ++ ) {

                    # some entries should not be measured in the grouping width,
                    # for example
                    #
                    #       \multicolumn{2}{c}{thing} &       \\
                    #       111 & 2                   & 33333 \\
                    #       4   & 55                  & 66    \\
                    #       \multicolumn{2}{c}{a}     &       \\
                    #
                    #          ^^^^^^^^
                    #          ||||||||
                    #
                    # the second \multicolumn entry shouldn't be measured, and it will
                    # have had
                    #
                    #         measureThis
                    #
                    # switched off during multicolumn_pre_check

                    next if !${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{measureThis};

                    $groupingWidth += ${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{width};
                    $groupingWidth += ${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{individualPadding};
                    $groupingWidth += ${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{delimiterLength}
                        if ( $innerJ < $multiColumnSpan - 1 );
                }

                # adjust for
                #           <spacesBeforeAmpersand>
                #           &
                #           <spacesEndAmpersand>
                # note:
                #    we need to multiply this by the appropriate multicolumn
                #    spanning; in the above example:
                #
                #       \multicolumn{2}{c}{thing} &       \\
                #       111 & 2                   & 33333 \\
                #       4   & 55                  & 66    \\
                #
                #   we multiply by (2-1) = 1 because there is *1* ampersand
                #   underneath the multicolumn command
                #
                # note:
                #   the & will have been accounted for in the above section using delimiterLength

                $groupingWidth
                    += ( $multiColumnSpan - 1 ) * ( ${$self}{spacesBeforeAmpersand} + ${$self}{spacesAfterAmpersand} );

                # store the grouping width for the next phase
                ${ $cellStorage[$innerRowCount][$justificationOffset] }{groupingWidth} = $groupingWidth;

                # update the maximum grouping width
                $maxGroupingWidth = max( $maxGroupingWidth, $groupingWidth );

            }

            #
            # phase (2)
            #

            # now that the maxGroupingWidth has been established, loop back
            # through and update groupingWidth for the appropriate cells

            # *inner* row loop
            $innerRowCount = -1;
            foreach my $innerRow (@cellStorage) {
                $innerRowCount++;

                # we only want to make adjustment on the *other* rows
                next if ( $innerRowCount == $rowCount );

                # it's possible that we have multicolumn commands that were *not* measured,
                # and are *narrower* than the maxGroupingWidth, for example:
                #
                #        \multicolumn{3}{l}{aaaa}         &         \\    <------ this entry won't have been measured!
                #        $S_N$ & $=$ & $\SI{1000}{\kV\A}$ & $U_0$ & \\
                #        \multicolumn{3}{l}{bbbbbbb}      &         \\
                #
                if (    ${ $cellStorage[$innerRowCount][$j] }{colSpan} ne "."
                    and ${ $cellStorage[$innerRowCount][$j] }{colSpan} == $multiColumnSpan
                    and !${ $cellStorage[$innerRowCount][$j] }{measureThis}
                    and $maxGroupingWidth > ${ $cellStorage[$innerRowCount][$j] }{width}
                    and ${ $cellStorage[$innerRowCount][$j] }{width} >= ${$cell}{width} )
                {
                    ${ $cellStorage[$innerRowCount][$j] }{individualPadding} = 0;
                    ${ $cellStorage[$innerRowCount][$j] }{groupPadding}
                        = ( $maxGroupingWidth - ${ $cellStorage[$innerRowCount][$j] }{width} );
                }

                my $groupingWidth = ${ $cellStorage[$innerRowCount][$justificationOffset] }{groupingWidth};

                #
                # phase (3)
                #

                # there are two possible cases:
                #
                # (1) the \multicolumn statement is *WIDER* than its grouped columns, e.g.:
                #
                #       \multicolumn{2}{c}{thing} &       \\
                #       111 & 2                   & 33333 \\
                #       4   & 55                  & 66    \\
                #                ^^^^^^^^^^^^^^^
                #                |||||||||||||||
                #
                #     in this situation, we need to adjust each of the group paddings for the cells
                #     marked with an up arrow
                #
                # (2) the \multicolumn statement is *NARROWER* than its grouped columns, e.g.:
                #
                #                                 ||
                #                                 **
                #       \multicolumn{2}{c}{thing}    &       \\
                #       111 & bbbbbbbbbbbbbbbbbbbbbb & 33333 \\
                #       4   & 55                     & 66    \\
                #
                #     in this situation, we need to adjust the groupPadding of the multicolumn
                #     entry, which happens ***once the row loop has finished***
                #
                if ( ${$cell}{width} > $maxGroupingWidth ) {
                    ${ $cellStorage[$innerRowCount][$justificationOffset] }{groupPadding}
                        = ( ${$cell}{width} - $maxGroupingWidth );
                }
            }

            # case (2) from above when \multicolumn statement is *NARROWER* than its grouped columns
            if ( ${$cell}{width} < $maxGroupingWidth ) {
                ${$cell}{groupPadding} += ( $maxGroupingWidth - ${$cell}{width} );
                ${$cell}{individualPadding} = 0;
            }
        }

    }

}

sub multicolumn_post_check {

    # PURPOSE:
    #     ensure that multiple multicolumn commands are
    #     handled appropriately
    #
    #     example 1
    #
    #           \multicolumn{2}{c}{thing} & aaa     & bbb  \\
    #           111 & 2                   & 33333   &      \\
    #           4   & 55                  & 66      &      \\
    #           \multicolumn{3}{c}{a}               &      \\
    #
    #                                 ^^^^^^^^
    #                                 ||||||||
    #
    #     the second multicolumn command needs to have its group padding
    #     accounted for.
    #
    #     *Note* this will not have been done previously, as
    #     this second multicolumn command will have had its type changed to
    #     X, because it spans 3 columns, and there is a cell within its
    #     column that spans *less than 3 columns*
    my $self = shift;

    # row loop
    my $rowCount = -1;
    foreach my $row (@cellStorage) {
        $rowCount++;

        # column loop
        my $j = -1;
        foreach my $cell (@$row) {
            $j++;

            # we only need to account for X-type columns, with an integer colSpan
            next unless ( ${$cell}{type} eq "X" and ${$cell}{colSpan} =~ m/(\d+)/ );

            # multicolumn entry
            my $multiColumnSpan = $1;

            # we store the maximum grouping width
            my $maxGroupingWidth = 0;

            # *inner* row loop
            my $innerRowCount = -1;
            foreach my $innerRow (@cellStorage) {
                $innerRowCount++;

                # we only want to measure the *other* rows
                next if ( $innerRowCount == $rowCount );

                # we will store the width of columns spanned by the multicolumn command
                my $groupingWidth = 0;

              # we need to keep track of the number of ampersands encountered;
              #
              # for example:
              #
              #       \multicolumn{2}{c}{thing} & aaa     & bbb  \\
              #       111 & 2                   & 33333   &      \\
              #       4   & 55                  & 66      &      \\
              #       \multicolumn{3}{c}{a}               &      \\   <!----- focus on the multicolumn entry in this row
              #
              # focusing on the final multicolumn entry (spanning 3 columns),
              # when we loop back through the rows, we will encounter:
              #
              #   row 1: one ampersand
              #
              #       \multicolumn{2}{c}{thing} & aaa    ...
              #
              #   row 2: two ampersands
              #
              #       111 & 2                   & 33333  ...
              #
              #   row 3: two ampersands
              #
              #       4   & 55                  & 66     ...
              #
              # note: we start the counter at -1, because the count of ampersands
              #       is always one behind the cell count; for example, looking
              #       at row 3 in the above, in the above, in cell 1 (entry: 4)
              #       we have 0 ampersands, in cell 2 (entry: 55) we now have 1 ampersands, etc
                my $ampersandsEncountered = -1;

                # column loop
                my @dumRow = @$innerRow;
                foreach ( my $innerJ = 0; $innerJ <= $#dumRow; $innerJ++ ) {

                    # exit the loop if we've reached the multiColumn spanning width
                    last if ( $innerJ >= ($multiColumnSpan) );

                    # don't include '*' or '-' cell types in the calculations
                    my $type = ${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{type};
                    next if ( $type eq "*" or $type eq "-" );

                    # update the grouping width
                    $groupingWidth += ${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{width};
                    $groupingWidth += ${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{individualPadding};

                    # update the number of & encountered
                    $ampersandsEncountered++;
                    $groupingWidth += ${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{delimiterLength}
                        if ( $ampersandsEncountered > 0 );

              # and adjust the column count, if necessary; in the above example
              #
              #       \multicolumn{2}{c}{thing} & aaa     & bbb  \\
              #       111 & 2                   & 33333   &      \\
              #       4   & 55                  & 66      &      \\
              #       \multicolumn{3}{c}{a}               &      \\   <!----- focus on the multicolumn entry in this row
              #
              # the *first entry* \multicolumn{2}{c}{thing} spans 2 columns, so
              # we need to move the column count along accordingly

                    if ( ${ $cellStorage[$innerRowCount][ $j + $innerJ ] }{colSpan} =~ m/(\d+)/ ) {
                        $innerJ += $1 - 1;
                    }

                }

                # adjust for
                #           <spacesBeforeAmpersand>
                #           &
                #           <spacesEndAmpersand>
                # note:
                #    we need to multiply this by the appropriate
                #    number of *ampersandsEncountered*
                #
                #       \multicolumn{2}{c}{thing} &       \\
                #       111 & 2                   & 33333 \\
                #       4   & 55                  & 66    \\

                $groupingWidth
                    += $ampersandsEncountered * ( ${$self}{spacesBeforeAmpersand} + ${$self}{spacesAfterAmpersand} );

                # update the maximum grouping width
                $maxGroupingWidth = max( $maxGroupingWidth, $groupingWidth );
            }

            ${$cell}{individualPadding} = 0;

            # there are cases where the
            #
            #     maxGroupingWidth
            #
            # is *less than* the cell width, for example:
            #
            #    \multicolumn{4}{|c|}{\textbf{Search Results}} \\  <!------ the width of this multicolumn entry
            #    1  & D7  & R                       &          \\           is larger than maxGroupingWidth
            #    2  & D2  & R                       &          \\
            #    \multicolumn{3}{|c|}{\textbf{Avg}} &          \\
            #
            ${$cell}{groupPadding} = max( 0, $maxGroupingWidth - ${$cell}{width} );
        }
    }
}

sub pretty_print_cell_info {

    my $thingToPrint = ( defined $_[0] ? $_[0] : "entry" );

    $logger->trace("*cell information: $thingToPrint");

    $logger->trace( "minimum multi col span: " . join( ",", @minMultiColSpan ) ) if (@minMultiColSpan);

    foreach my $row (@cellStorage) {
        my $tmpLogFileLine = q();
        foreach my $cell (@$row) {
            $tmpLogFileLine .= ${$cell}{$thingToPrint} . "\t";
        }
        $logger->trace( ' ' . $tmpLogFileLine ) if ($is_t_switch_active);
    }

    if ( $thingToPrint eq "type" ) {
        $logger->trace("*key to types:");
        $logger->trace("\tX\tbasic cell, will be measured and aligned");
        $logger->trace("\t*\t will not be measured, and no ampersand");
        $logger->trace("\t-\t phantom/blank cell for gaps");
        $logger->trace("\t[0-9]\tmulticolumn cell, spanning multiple columns");
    }

}

sub double_back_slash_else {
    my $self = shift;

    # check for existence of \\ statement, and associated line break information
    $self->check_for_else_statement(

        # else name regexp
        elseNameRegExp => qr/${${$mainSettings{fineTuning}}{modifyLineBreaks}}{doubleBackSlash}/,

        # else statements name: note that DBS stands for 'Double Back Slash'
        ElseStartsOnOwnLine => "DBSStartsOnOwnLine",

        # end statements
        ElseFinishesWithLineBreak => "DBSFinishesWithLineBreak",

        # for the YAML settings storage
        storageNameAppend => "DBS",

        # logfile information
        logName => "double-back-slash-block (for align at ampersand, see lookForAlignDelims)",

        # we don't want to store these "\\" blocks as demonstrated in test-cases/alignment/issue-426.tex
        storage => 0,
    );

    # can return if no "\\" blocks were found
    return unless defined ${$self}{children};

    # now loop back through and put the "\\" blocks back in, accounting for all poly-switches
    while ( ${ ${$self}{children}[-1] }{storage} == 0 ) {
        my $child = ${$self}{children}[-1];
        $self->replace_id_with_begin_body_end( $child, -1 );
        last if scalar( @{ ${$self}{children} } ) == 0;
    }
}

# possible hidden children, see test-cases/alignment/issue-162.tex and friends
#
#     \begin{align}
#     	A & =\begin{array}{cc}      % <!--- Hidden child
#     		     BBB & CCC \\       % <!--- Hidden child
#     		     E   & F            % <!--- Hidden child
#     	     \end{array} \\         % <!--- Hidden child
#
#     	Z & =\begin{array}{cc}      % <!--- Hidden child
#     		     Y & X \\           % <!--- Hidden child
#     		     W & V              % <!--- Hidden child
#     	     \end{array}            % <!--- Hidden child
#     \end{align}
#

# PURPOSE:
#
#   measure CELL width that has hidden children
#
#     	A &     =\begin{array}{cc}
#     	             BBB & CCC \\
#     	             E   & F
#     	         \end{array} \\
#
#     	       ^^^^^^^^^^^^^^^^^^
#     	       ||||||||||||||||||
#
#     	              Cell
#
sub hidden_child_cell_row_width {
    my $self = shift;

    my ( $tmpCellEntry, $rowCounter, $columnCounter ) = @_;

    for my $hiddenChildToMeasure ( @{ ${$self}{measureHiddenChildren} } ) {
        if ( $tmpCellEntry =~ m/.*?$hiddenChildToMeasure/s
            and defined $familyTree{$hiddenChildToMeasure}{bodyForMeasure} )
        {
            $tmpCellEntry =~ s/$hiddenChildToMeasure/$familyTree{$hiddenChildToMeasure}{bodyForMeasure}/s;
        }
    }

    if ( $tmpCellEntry =~ m/$tokens{verbatim}/ ) {
        #
        # verbatim example:
        #
        #    \begin{tabular}{ll}
        #      Testing & Line 1                        \\
        #      Testing & Line 2                        \\
        #      Testing & Line 3 \verb|X| \\
        #      Testing & Line 4                        \\
        #    \end{tabular}
        while ( my ( $verbatimID, $child ) = each %verbatimStorage ) {
            if ( $tmpCellEntry =~ m/.*?$verbatimID/s ) {
                $tmpCellEntry =~ s/$verbatimID/${$child}{begin}${$child}{body}${$child}{end}/s;
            }
        }
    }
    my $bodyLineBreaks = 0;
    $bodyLineBreaks++ while ( $tmpCellEntry =~ m/\R/sg );
    if ( $bodyLineBreaks > 0 ) {
        my $maxRowWidthWithinCell = 0;
        foreach ( split( "\n", $tmpCellEntry ) ) {
            my $currentRowWidth = &get_column_width($_);
            $maxRowWidthWithinCell = $currentRowWidth if ( $currentRowWidth > $maxRowWidthWithinCell );
        }
        ${ $cellStorage[$rowCounter][$columnCounter] }{width} = $maxRowWidthWithinCell;
    }
    else {
        ${ $cellStorage[$rowCounter][$columnCounter] }{width} = &get_column_width($tmpCellEntry);
    }
}

# PURPOSE:
#
#   measure ROW width that has hidden children
#
#     	A & =\begin{array}{cc}
#     		     BBB & CCC \\
#     		     E   & F
#     	     \end{array} \\
#
#     	^^^^^^^^^^^^^^^^^^^^^^
#     	||||||||||||||||||||||
#
#     	          row
#
sub hidden_child_row_width {
    my $self = shift;

    my ( $tmpRow, $rowCount, $rowWidth ) = @_;

    # some alignment blocks have the 'begin' statement on the opening line:
    #
    #           this bit
    #       ||||||||||||||
    #       ``````````````
    #       \begin{align*}1 & 2 \\
    #                     3 & 4 \\
    #                     5 & 6
    #       \end{align*}
    #
    my $lengthOfBegin = 0;
    if (   !${ ${$self}{linebreaksAtEnd} }{begin}
        and ${ $cellStorage[0][0] }{type} eq "X"
        and ${ $cellStorage[0][0] }{measureThis} )
    {

        my $beginToMeasure = ${$self}{begin};
        if ( ( ${$self}{begin} eq '{' | ${$self}{begin} eq '[' ) and ${$self}{parentBegin} ) {
            $beginToMeasure = ${$self}{parentBegin} . "{";
        }
        $lengthOfBegin = &get_column_width($beginToMeasure);
        $tmpRow        = $beginToMeasure . $tmpRow if $rowCount == 0;
    }

    if ( $tmpRow =~ m/.*?$tokens{beginOfToken}/s ) {

        $tmpRow = ( "." x $lengthOfBegin ) . $tmpRow;

        for my $hiddenChildToMeasure ( @{ ${$self}{measureHiddenChildren} } ) {
            if ( $tmpRow =~ m/(^.*)?$hiddenChildToMeasure/m
                and defined $familyTree{$hiddenChildToMeasure}{bodyForMeasure} )
            {
                my $partBeforeId       = $1;
                my $lengthPartBeforeId = &get_column_width($partBeforeId);

                foreach ( @{ $familyTree{$hiddenChildToMeasure}{ancestors} } ) {
                    if ( ${$_}{ancestorID} eq ${$self}{id} ) {
                        if ( $lengthOfBegin > 0 ) {
                            ${$_}{ancestorIndentation} = ( " " x ($lengthPartBeforeId) );
                        }
                        else {
                            ${$_}{ancestorIndentation} = ${$_}{ancestorIndentation} . ( " " x ($lengthPartBeforeId) );
                        }
                    }
                }
                my $tmpBodyToMeasure = join(
                    "\n" . ( "." x ($lengthPartBeforeId) ),
                    split( "\n", $familyTree{$hiddenChildToMeasure}{bodyForMeasure} )
                );

                # remove trailing \\
                $tmpBodyToMeasure =~ s/(\\\\\h*$)//mg;

                $tmpRow =~ s/$hiddenChildToMeasure/$tmpBodyToMeasure/s;
            }
        }

        if ( $tmpRow =~ m/$tokens{verbatim}/ ) {
            #
            # verbatim example:
            #
            #    \begin{tabular}{ll}
            #      Testing & Line 1                        \\
            #      Testing & Line 2                        \\
            #      Testing & Line 3 \verb|X| \\
            #      Testing & Line 4                        \\
            #    \end{tabular}
            while ( my ( $verbatimID, $child ) = each %verbatimStorage ) {
                if ( $tmpRow =~ m/.*?$verbatimID/s ) {
                    $tmpRow =~ s/$verbatimID/${$child}{begin}${$child}{body}${$child}{end}/s;
                }
            }
        }

        my $bodyLineBreaks = 0;
        $bodyLineBreaks++ while ( $tmpRow =~ m/\R/sg );
        if ( $bodyLineBreaks > 0 ) {
            my $maxRowWidth = 0;

            foreach ( split( "\n", $tmpRow ) ) {
                my $currentRowWidth = &get_column_width($_);
                $maxRowWidth = $currentRowWidth if ( $currentRowWidth > $maxRowWidth );
            }
            $rowWidth = $maxRowWidth;
        }
        else {
            $rowWidth = &get_column_width($tmpRow);
        }
    }
    elsif (!${ ${$self}{linebreaksAtEnd} }{begin}
        and ${ $cellStorage[0][0] }{type} eq "X"
        and ${ $cellStorage[0][0] }{measureThis} )
    {
        $rowWidth = &get_column_width($tmpRow);
    }

    # possibly draw ruler to log file
    &draw_ruler_to_logfile( $tmpRow, $rowWidth ) if ($is_t_switch_active);
    return $rowWidth;
}

sub draw_ruler_to_logfile {

    # draw a ruler to the log file, useful for debugging
    #
    # example:
    #
    # ----|----|----|----|----|----|----|----|----|----|----|----|----|----|
    #    5   10   15   20   25   30   35   40   45   50   55   60   65   70
    #

    my ( $tmpRow, $maxRowWidth ) = @_;
    $logger->trace("*tmpRow:");

    foreach ( split( "\n", $tmpRow ) ) {
        my $currentRowWidth = &get_column_width($_);
        $logger->trace("$_ \t(length: $currentRowWidth)");
    }

    my $rulerMax = int( $maxRowWidth / 10 + 1.5 ) * 10;
    $logger->trace( ( "----|" x ( int( $rulerMax / 5 ) ) ) );

    my $ruler = q();
    for ( my $i = 1; $i <= $rulerMax / 5; $i++ ) { $ruler .= "   " . $i * 5 }
    $logger->trace($ruler);

}

sub get_column_width {

    my $stringToBeMeasured = $_[0];

    # default length measurement
    # credit/reference: https://perldoc.perl.org/perlunicook#%E2%84%9E-33:-String-length-in-graphemes
    unless ( $switches{GCString} ) {
        my $count = 0;
        while ( $stringToBeMeasured =~ /\X/g ) { $count++ }
        return $count;
    }

    # if GCString active, then use Unicode::GCString
    return Unicode::GCString->new($stringToBeMeasured)->columns();
}
1;
