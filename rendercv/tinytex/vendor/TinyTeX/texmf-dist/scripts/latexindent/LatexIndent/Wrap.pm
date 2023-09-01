package LatexIndent::Wrap;

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
use Text::Wrap;
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::AlignmentAtAmpersand qw/get_column_width/;
use LatexIndent::TrailingComments qw/$trailingCommentRegExp @trailingComments/;
use LatexIndent::GetYamlSettings qw/%mainSettings %previouslyFoundSettings/;
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active $is_m_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::Verbatim qw/%verbatimStorage/;
use Exporter qw/import/;
our @ISA       = "LatexIndent::Document";                  # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/text_wrap text_wrap_comment_blocks/;
our $sentenceCounter;

sub text_wrap {
    my $self = shift;

    $logger->trace("*Text wrap regular expression construction: (see textWrapOptions: )") if $is_t_switch_active;

    #
    # textWrap Blocks FOLLOW
    #
    my $blocksFollow     = q();
    my $blocksFollowHash = \%{ ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{blocksFollow} };

    my $headingsRegEx = q();

    foreach my $blocksFollowEachPart ( sort keys %{$blocksFollowHash} ) {
        last if ${$self}{modifyLineBreaksYamlName} eq 'sentence';

        my $yesNo = $blocksFollowHash->{$blocksFollowEachPart};
        if ($yesNo) {
            if ( $blocksFollowEachPart eq "par" ) {
                $blocksFollowEachPart = qr/\R?\\par/s;
            }
            elsif ( $blocksFollowEachPart eq "blankLine" ) {
                $blocksFollowEachPart = qr/
                        (?:\A(?:$tokens{blanklines}\R)+)     # the order of each of these 
                                |                            # is important, as (like always) the first
                        (?:\G(?:$tokens{blanklines}\R)+)     # thing to be matched will 
                                |                            # be accepted
                        (?:(?:$tokens{blanklines}\h*\R)+)
                                |
                                \R{2,}
                                |
                                \G
                        /sx;
            }
            elsif ( $blocksFollowEachPart eq "commentOnPreviousLine" ) {
                $blocksFollowEachPart = qr/(?:^\h*$trailingCommentRegExp\R?)+/m;
            }
            elsif ( $blocksFollowEachPart eq "verbatim" ) {
                $blocksFollowEachPart = qr/$tokens{verbatim}\d+$tokens{endOfToken}/;
            }
            elsif ( $blocksFollowEachPart eq "filecontents" ) {
                $blocksFollowEachPart = qr/$tokens{filecontents}\d+$tokens{endOfToken}/;
            }
            elsif ( $blocksFollowEachPart eq "headings" ) {
                $blocksFollowEachPart = q();

                my %headingsLevels = %{ $mainSettings{indentAfterHeadings} };
                while ( my ( $headingName, $headingInfo ) = each %headingsLevels ) {

                    # check for a * in the name
                    $headingName =~ s/\*/\\\*/g;

                    # make the regex as
                    #
                    #    headingName
                    #     <hspace>   # possible horizontal space
                    #     []?        # possible optional argument
                    #     <hspace>   # possible horizontal space
                    #     {}         #          mandatory argument
                    #
                    $headingName = qr/\\$headingName\h*(?:\[[^]]*?\])?\h*\{[^}]*?\}\h*(?:\\label\{[^}]*?\})?/m;

                    # stored for possible use with 'after'
                    $headingsRegEx = $headingName . ( $headingsRegEx eq '' ? q() : "|$headingsRegEx" );

                    # put starred headings at the front of the regexp
                    if ( $headingName =~ m/\*/ ) {
                        $blocksFollowEachPart
                            = $headingName . ( $blocksFollowEachPart eq '' ? q() : "|$blocksFollowEachPart" );
                    }
                    else {
                        $blocksFollowEachPart .= ( $blocksFollowEachPart eq '' ? q() : "|" ) . $headingName;
                    }
                }
            }
            elsif ( $blocksFollowEachPart eq "other" ) {
                $blocksFollowEachPart = qr/$yesNo/x;
            }
            $blocksFollow .= ( $blocksFollow eq '' ? q() : "|" ) . qr/$blocksFollowEachPart/s;
        }
    }

    # if blankLine is not active from blocksFollow then we need to set up the
    # beginning of the string, but make sure that it is *not* followed by a
    # blank line token, or a blank line
    if ( !${ ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{blocksFollow} }{blankLine} ) {
        $blocksFollow .= ( $blocksFollow eq '' ? q() : "|" ) . qr/
                                        \G
                                        (?!$tokens{blanklines})
                                    /sx;
    }

    # followed by 0 or more h-space and line breaks
    if ( ${ ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{blocksFollow} }{commentOnPreviousLine} ) {
        $blocksFollow
            = ( $blocksFollow eq '' ? q() : qr/(?:$blocksFollow)(?:\h|\R)*(?:$trailingCommentRegExp\R\h*)?/s );
    }
    else {
        $blocksFollow = ( $blocksFollow eq '' ? q() : qr/(?:$blocksFollow)(?:\h|\R)*/s );
    }

    $logger->trace("textWrap blocks follow regexp:")
        if ( $is_tt_switch_active and ${$self}{modifyLineBreaksYamlName} ne 'sentence' );
    $logger->trace($blocksFollow) if $is_tt_switch_active;

    #
    # textWrap Blocks BEGIN with
    #
    my $blocksBeginWith     = q();
    my $blocksBeginWithHash = \%{ ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{blocksBeginWith} };

    foreach my $blocksBeginWithEachPart ( sort keys %{$blocksBeginWithHash} ) {
        last if ${$self}{modifyLineBreaksYamlName} eq 'sentence';

        my $yesNo = $blocksBeginWithHash->{$blocksBeginWithEachPart};
        if ($yesNo) {
            if ( $blocksBeginWithEachPart eq "A-Z" ) {
                $logger->trace("textWrap Blocks BEGINS with capital letters (see textWrap:blocksBeginWith:A-Z)")
                    if $is_t_switch_active;
                $blocksBeginWithEachPart = qr/(?!(?:$tokens{blanklines}|$tokens{verbatim}|$tokens{preamble}))[A-Z]/;
            }
            elsif ( $blocksBeginWithEachPart eq "a-z" ) {
                $logger->trace("textWrap Blocks BEGINS with lower-case letters (see textWrap:blocksBeginWith:a-z)")
                    if $is_t_switch_active;
                $blocksBeginWithEachPart = qr/[a-z]/;
            }
            elsif ( $blocksBeginWithEachPart eq "0-9" ) {
                $logger->trace("textWrap Blocks BEGINS with numbers (see textWrap:blocksBeginWith:0-9)")
                    if $is_t_switch_active;
                $blocksBeginWithEachPart = qr/[0-9]/;
            }
            elsif ( $blocksBeginWithEachPart eq "other" ) {
                $logger->trace(
                    "textWrap Blocks BEGINS with other $yesNo (reg exp) (see textWrap:blocksBeginWith:other)")
                    if $is_t_switch_active;
                $blocksBeginWithEachPart = qr/$yesNo/;
            }
            $blocksBeginWith .= ( $blocksBeginWith eq "" ? q() : "|" ) . $blocksBeginWithEachPart;
        }
    }
    $blocksBeginWith = qr/$blocksBeginWith/;

    #
    # textWrap Blocks END with
    #
    my $blocksEndBefore     = q();
    my $blocksEndBeforeHash = \%{ ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{blocksEndBefore} };

    foreach my $blocksEndBeforeEachPart ( sort keys %{$blocksEndBeforeHash} ) {
        last if ${$self}{modifyLineBreaksYamlName} eq 'sentence';

        my $yesNo = $blocksEndBeforeHash->{$blocksEndBeforeEachPart};
        if ($yesNo) {
            if ( $blocksEndBeforeEachPart eq "other" ) {
                $logger->trace("textWrap Blocks ENDS with other $yesNo (reg exp) (see textWrap:blocksEndBefore:other)")
                    if $is_t_switch_active;
                $blocksEndBeforeEachPart = qr/\R?$yesNo/;
            }
            elsif ( $blocksEndBeforeEachPart eq "commentOnOwnLine" ) {
                $logger->trace(
                    "textWrap Blocks ENDS with commentOnOwnLine (see textWrap:blocksEndBefore:commentOnOwnLine)")
                    if $is_t_switch_active;
                $blocksEndBeforeEachPart = qr/^\h*$trailingCommentRegExp/m;
            }
            elsif ( $blocksEndBeforeEachPart eq "verbatim" ) {
                $logger->trace("textWrap Blocks ENDS with verbatim (see textWrap:blocksEndBefore:verbatim)")
                    if $is_t_switch_active;
                $blocksEndBeforeEachPart = qr/$tokens{verbatim}\d/;
            }
            elsif ( $blocksEndBeforeEachPart eq "filecontents" ) {
                $logger->trace("textWrap Blocks ENDS with filecontents (see textWrap:blocksEndBefore:filecontents)")
                    if $is_t_switch_active;
                $blocksEndBeforeEachPart = qr/$tokens{filecontents}/;
            }
            $blocksEndBefore .= ( $blocksEndBefore eq "" ? q() : "|" ) . $blocksEndBeforeEachPart;
        }
    }
    $blocksEndBefore = qr/$blocksEndBefore/;

    #
    # the OVERALL textWrap Blocks regexp
    #
    $logger->trace("Overall textWrap Blocks end with regexp:")
        if ( $is_tt_switch_active and ${$self}{modifyLineBreaksYamlName} ne 'sentence' );
    $logger->trace($blocksEndBefore) if $is_tt_switch_active;

    # store the text wrap blocks
    my @textWrapBlockStorage = split( /($blocksFollow)/, ${$self}{body} );
    @textWrapBlockStorage = split( /(\s*$blocksFollow+)/, ${$self}{body} )
        if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after';

    # sentences need special treatment
    if ( ${$self}{modifyLineBreaksYamlName} eq 'sentence' ) {
        @textWrapBlockStorage = ( ${$self}{body} );
    }

    # call the text wrapping routine
    my $columns = ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{columns};

    # vital Text::Wrap options
    $Text::Wrap::columns  = $columns;
    $Text::Wrap::huge     = ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge};
    $Text::Wrap::unexpand = 0;

    # all other Text::Wrap options not usually needed/helpful, but available
    $Text::Wrap::separator = ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{separator}
        if ( ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{separator} ne '' );
    $Text::Wrap::break = ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{break}
        if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{break};
    $Text::Wrap::unexpand = ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{unexpand}
        if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{unexpand};
    $Text::Wrap::tabstop = ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{tabstop}
        if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{tabstop};

    # only needed if when:after
    my $subsequentSpace = q();

    # clear the body, which will be updated with newly wrapped body
    ${$self}{body} = q();

    # text wrap block loop counter
    my $textWrapBlockCount = -1;

    # loop back through the text wrap block storage
    foreach my $textWrapBlockStorageValue (@textWrapBlockStorage) {

        # increment text wrap block loop counter
        $textWrapBlockCount++;

        if ( $textWrapBlockStorageValue =~ m/^\s*$blocksBeginWith/s
            or ${$self}{modifyLineBreaksYamlName} eq 'sentence' )
        {

# text wrap AFTER indentation needs to turn, for example (with columns: 100),
#
# before:
#
#  \begin{abstract}
#      This is a very long sentence that should be wrapped at some point, which is the case but is is is is line width is not respected because of the indentation.
#  \end{abstract}
#
# after:
#
#  \begin{abstract}
#      This is a very long sentence that should be wrapped at some point, which is the case but is is
#      is is line width is not respected because of the indentation.
#  \end{abstract}
#  ----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|----|
#     5   10   15   20   25   30   35   40   45   50   55   60   65   70   75   80   85   90   95   100   105   110
#
# note: it respects the column width AND indentation
#
# see also: test-cases/text-wrap/issue-359*.tex
#
            my $firstLineColumns = 0;
            if ( ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after' ) {

                # reset columns
                $Text::Wrap::columns = $columns;

                # reset subsequent Space
                $subsequentSpace = q();

                my $numberOfTABS = 0;

                # measure leading horizontal space
                if ( ${$self}{modifyLineBreaksYamlName} eq 'sentence' ) {
                    my $thingToMeasure = ( split( /\R/, ${$self}{follows} ) )[-1];

                    $subsequentSpace
                        = ( ${$self}{follows} ? " " x &get_column_width($thingToMeasure) : q() );

                    # possible tab adjustments
                    $thingToMeasure = q() if ( not defined $thingToMeasure );
                    $numberOfTABS   = () = $thingToMeasure =~ m/\t/g;
                    for ( my $i = 1; $i <= $numberOfTABS; $i++ ) {
                        $subsequentSpace =~ s/ /    /;
                    }
                }
                else {
                    # note, in the above we have defined
                    #
                    #   @textWrapBlockStorage = split( /(\s*$blocksFollow)/, ${$self}{body} )
                    #
                    # so that both the *match* AND the *block* are stored, so
                    #
                    #   ( split( /\R/, $textWrapBlockStorage[ $textWrapBlockCount - 1 ] ) )[-1]
                    #
                    # represents the *match*
                    #

                    # scenarios such as
                    #
                    #       % comment goes here
                    #       text that isn't commented
                    #
                    # means that the *match* doesn't contain a linebreak
                    #
                    if ( scalar( split( /\R/, $textWrapBlockStorage[ $textWrapBlockCount - 1 ] ) ) == 1
                        and ( split( /\R/, $textWrapBlockStorage[ $textWrapBlockCount - 1 ] ) )[-1]
                        =~ m/$trailingCommentRegExp/ )
                    {
                        $subsequentSpace = q();
                    }
                    else {
                        my $thingToMeasure = ( split( /\R/, $textWrapBlockStorage[ $textWrapBlockCount - 1 ] ) )[-1];
                        $thingToMeasure =~ s/$tokens{blanklines}//;
                        $thingToMeasure =~ s/$tokens{verbatim}\d+$tokens{endOfToken}//;
                        $thingToMeasure =~ s/$trailingCommentRegExp//;
                        $thingToMeasure =~ s/$headingsRegEx//;

                        $subsequentSpace = (
                            $textWrapBlockCount == 0
                            ? q()
                            : " " x &get_column_width($thingToMeasure)
                        );

                        # possible tab adjustments
                        $numberOfTABS = () = $thingToMeasure =~ m/\t/g;
                        for ( my $i = 1; $i <= $numberOfTABS; $i++ ) {
                            $subsequentSpace =~ s/ /    /;
                        }

                        # check for custom indentRules see
                        #
                        #   test-cases/text-wrap/issue-444.tex and friends
                        #
                        # https://github.com/cmhughes/latexindent.pl/issues/444
                        #
                        # WARNING: this routine isn't perfect, it's *VERY DIFFICULT*
                        #          to figure out what a code block is without actually
                        #          finding the code block
                        #
                        #          **known issue** with textWrap: after and indentRules
                        #
                        #          the below will likely need to be built upon
                        #
                        my $name = $thingToMeasure;
                        $name =~ s/\\begin//sg;
                        $name =~ s/[^a-zA-Z\@0-9]//sg;

                        # check that $name is within indentRules
                        if (    $textWrapBlockCount > 0
                            and $name !~ m/^\h*$/
                            and defined $previouslyFoundSettings{textWrapAfter}
                            and defined ${ $previouslyFoundSettings{textWrapAfter} }{$name}
                            and ${ $previouslyFoundSettings{textWrapAfter} }{$name} =~ m/^\h*$/ )
                        {

                            $firstLineColumns = $columns - length($subsequentSpace);

                            $thingToMeasure =~ s/^\h*//;
                            for ( my $i = 0; $i < &get_column_width($thingToMeasure); $i++ ) {
                                $subsequentSpace =~ s/ //;
                            }
                            $subsequentSpace .= ${ $previouslyFoundSettings{textWrapAfter} }{$name};
                        }

                    }
                }

                $Text::Wrap::columns = $columns - length($subsequentSpace);

                # possible tab adjustments
                for ( my $i = 1; $i <= $numberOfTABS; $i++ ) {
                    $subsequentSpace =~ s/    /\t/;
                }
            }

            # LIMIT is one greater than the maximum number of times EXPR may be split
            my @textWrapBeforeEndWith = split( /($blocksEndBefore)/, $textWrapBlockStorageValue, 2 );
            @textWrapBeforeEndWith = split( /(\s*$blocksEndBefore)/, $textWrapBlockStorageValue, 2 )
                if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after';

            # sentences need special treatment
            if ( ${$self}{modifyLineBreaksYamlName} eq 'sentence' ) {
                @textWrapBeforeEndWith = ();
            }

            # if we have an occurrence of blocksEndBefore, then grab the stuff before it
            if ( scalar @textWrapBeforeEndWith > 1 ) {
                $textWrapBlockStorageValue = $textWrapBeforeEndWith[0];
            }

            $logger->trace("TEXTWRAP BLOCK: $textWrapBlockStorageValue") if $is_tt_switch_active;

            # initiate the trailing comments storage
            my $trailingComments = q();

            # about trailing comments
            #
            #   - trailing comments that do *not* have leading space instruct the text
            #     wrap routine to connect the lines *without* space
            #
            #   - multiple trailing comments will be connected at the end of the text wrap block
            #
            #   - the number of spaces between the end of the text wrap block and
            #     the (possibly combined) trailing comments is determined by the
            #     spaces (if any) at the end of the text wrap block

            # for trailing comments that
            #
            #   do *NOT* have a leading space
            #   do have a trailing line break
            #
            # then we *remove* the trailing line break
            while ( $textWrapBlockStorageValue =~ m|\H$trailingCommentRegExp\h*\R|s ) {
                $textWrapBlockStorageValue =~ s|(\H)($trailingCommentRegExp)\h*\R|$1$2|s;
            }

            # now we put all of the trailing comments together
            while ( $textWrapBlockStorageValue =~ m|$trailingCommentRegExp|s ) {
                $textWrapBlockStorageValue =~ s|($trailingCommentRegExp)||s;
                $trailingComments = $trailingComments . $1;
            }

            $trailingComments =~ s/\h{2,}/ /sg
                if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{multipleSpacesToSingle};

            # determine if text wrapping will remove paragraph line breaks
            my $removeBlockLineBreaks = ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{removeBlockLineBreaks};

            # sentence remove line breaks is determined by removeSentenceLineBreaks
            if ( ${$self}{modifyLineBreaksYamlName} eq 'sentence' ) {
                $removeBlockLineBreaks
                    = ${ $mainSettings{modifyLineBreaks}{oneSentencePerLine} }{removeSentenceLineBreaks};
            }

            # remove internal line breaks
            $textWrapBlockStorageValue =~ s/\R(?!\Z)/ /sg if $removeBlockLineBreaks;

            # convert multiple spaces into single
            $textWrapBlockStorageValue =~ s/\h{2,}/ /sg
                if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{multipleSpacesToSingle};

            # goal: get an accurate measurement of verbatim objects;
            #
            # example:
            #       Lorem \verb!x+y! ipsum dolor sit amet
            #
            # is represented as
            #
            #       Lorem LTXIN-TK-VERBATIM1-END ipsum dolor sit amet
            #
            # so we *measure* the verbatim token and replace it with
            # an appropriate-length string
            #
            #       Lorem a2A41233rt ipsum dolor sit amet
            #
            # and then put the body back to
            #
            #       Lorem LTXIN-TK-VERBATIM1-END ipsum dolor sit amet
            #
            # following the text wrapping
            my @putVerbatimBackIn;

            # check body for verbatim and get measurements
            if ( $textWrapBlockStorageValue =~ m/$tokens{verbatim}/s
                and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge} eq "overflow" )
            {

# reference: https://stackoverflow.com/questions/10336660/in-perl-how-can-i-generate-random-strings-consisting-of-eight-hex-digits
                my @set = ( '0' .. '9', 'A' .. 'Z', 'a' .. 'z' );

                # loop through verbatim objects
                while ( my ( $verbatimID, $child ) = each %verbatimStorage ) {
                    my $verbatimThing = ${$child}{begin} . ${$child}{body} . ${$child}{end};

                    # if the object has line breaks, don't measure it
                    next if $verbatimThing =~ m/\R/s;

                    if ( $textWrapBlockStorageValue =~ m/$verbatimID/s ) {

                        # measure length
                        my $verbatimLength = &get_column_width($verbatimThing);

                        # create temporary ID, and check that it is not contained in the body
                        my $verbatimTmpID = join '' => map $set[ rand @set ], 1 .. $verbatimLength;
                        while ( $textWrapBlockStorageValue =~ m/$verbatimTmpID/s ) {
                            $verbatimTmpID = join '' => map $set[ rand @set ], 1 .. $verbatimLength;
                        }

                        # store for use after the text wrapping
                        push( @putVerbatimBackIn, { origVerbatimID => $verbatimID, tmpVerbatimID => $verbatimTmpID } );

                        # make the substitution
                        $textWrapBlockStorageValue =~ s/$verbatimID/$verbatimTmpID/s;
                    }
                }
            }

            # perform the text wrap routine
            if ( $firstLineColumns > 0 ) {

                # when 'after' is active, and indentation rules specified, they need attention
                #
                #       noAdditionalIndent *per-name* basis
                #       indentRules *per-name* basis
                #       noAdditionalIndentGlobal
                #       indentRulesGlobal
                #
                # see
                #
                #   test-cases/text-wrap/issue-444.tex
                #
                my $secondLineOnwardsColumns = $Text::Wrap::columns;

                # wrap the *first* line
                $Text::Wrap::columns       = $firstLineColumns;
                $textWrapBlockStorageValue = wrap( '', '', $textWrapBlockStorageValue );
                my @tmpBlock  = split( /\R/, $textWrapBlockStorageValue );
                my $firstLine = shift(@tmpBlock);

                # wrap the *subsequent* lines
                my $secondLineOnwards = join( " ", @tmpBlock );
                $Text::Wrap::columns       = $secondLineOnwardsColumns;
                $secondLineOnwards         = wrap( '', '', $secondLineOnwards );
                $textWrapBlockStorageValue = $firstLine . "\n" . $secondLineOnwards;
            }
            else {
                $textWrapBlockStorageValue = wrap( '', '', $textWrapBlockStorageValue )
                    if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{columns} > 0;
            }

            # if text wrap has happened *AFTER* indentation,
            # then we need to add the leading indentation
            # onto the lines of the text wrap block
            #
            # before:
            #
            #  \begin{abstract}
            #      This is a very long sentence that should be wrapped at some point, which is the case but is is
            #  is is line width is not respected because of the indentation.
            #  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
            #  \end{abstract}
            #
            # after:
            #
            #  \begin{abstract}
            #      This is a very long sentence that should be wrapped at some point, which is the case but is is
            #      is is line width is not respected because of the indentation.
            #  ^^^^
            #  \end{abstract}
            if ( ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after' ) {

                # add leading indentation back in to the text-wrapped block
                $textWrapBlockStorageValue =~ s/^/$subsequentSpace/mg;

                # remove the very first leading space, which is already handled by blocks follow
                $textWrapBlockStorageValue =~ s/^\h*//s unless ${$self}{modifyLineBreaksYamlName} eq 'sentence';
            }

            #
            # optionally wrap comments
            #
            if ( ${ ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{comments} }{wrap}
                and $trailingComments ne '' )
            {

                my $commentValue = q();

                # split the trailing comments, and put the *values* together
                foreach ( split( /([0-9]+)$tokens{endOfToken}/, $trailingComments ) ) {
                    next unless $_ =~ m/[0-9]/;

                    $commentValue .= ${ $trailingComments[ $_ - 1 ] }{value};
                }

# leading comment space, e.g.
#
#     %     This is a very very long trailing comment that needs to be wrapped by latexindent to make sure the visual display is in a good shape.
#      ^^^^^
#
                $commentValue =~ m/^(\h+)/s;
                my $leadingCommentSpace = ( $1 ? $1 : ' ' );

                # reset columns
                $Text::Wrap::columns
                    = $columns - &get_column_width( ( split( /\R/, $textWrapBlockStorageValue ) )[-1] );
                $commentValue = wrap( '', '', $commentValue );

                # the 2nd and subsequent lines need further attention
                my @commentArray             = ( split( /\R/, $commentValue ) );
                my $firstLine                = shift(@commentArray);
                my $secondCommentLineOnwards = join( " ", @commentArray );
                $secondCommentLineOnwards =~ s/\h{2,}/ /sg;

                # assemble the new trailing comments, which will be wrapped after this routine as a comment block
                $trailingComments = "%" . $self->add_comment_symbol( value => $firstLine );
                $trailingComments .= "\n$subsequentSpace%"
                    . $self->add_comment_symbol( value => $leadingCommentSpace . $secondCommentLineOnwards );
            }

            # append trailing comments from WITHIN the block
            $textWrapBlockStorageValue =~ s/\R?$/$trailingComments\n/s if ( $trailingComments ne '' );

            # append blocksEndBefore and the stuff following it
            if ( scalar @textWrapBeforeEndWith > 1 ) {
                $textWrapBlockStorageValue .= $textWrapBeforeEndWith[1] . $textWrapBeforeEndWith[2];
            }

            # put blank line tokens on their own lines, should only happen when the following is used:
            #   blocksFollow:
            #      blankLine: 0
            while ( $textWrapBlockStorageValue =~ m/^\H.*?$tokens{blanklines}/m ) {
                $textWrapBlockStorageValue =~ s/^(\H.*?)$tokens{blanklines}/$1\n$tokens{blanklines}/m;
            }

            # remove surrounding spaces from blank line tokens
            $textWrapBlockStorageValue =~ s/^\h*$tokens{blanklines}\h*/$tokens{blanklines}/mg;

            # put verbatim back in
            $textWrapBlockStorageValue =~ s/${$_}{tmpVerbatimID}/${$_}{origVerbatimID}/s foreach (@putVerbatimBackIn);
        }

        # update the body
        ${$self}{body} .= $textWrapBlockStorageValue;
    }

}

sub text_wrap_comment_blocks {

    my $self = shift;

    # call the text wrapping routine
    my $columns = ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{columns};

    #
    # text wrap comment blocks
    #
    #
    # from:
    #
    #   % first comment
    #   % second comment
    #   % third comment
    #   % fourth comment
    #   % fifth comment
    #
    # into:
    #
    #   % first comment second comment
    #   % third comment fourth comment
    #   % fifth comment
    #
    ${$self}{body} =~ s&((?:^\h*$trailingCommentRegExp\R)+)&
          my @commentBlocks = $1;
          my $trailingComments = q();

          # loop through comment blocks
          foreach my $commentBlock (@commentBlocks){

                  my $leadingHorizontalSpace = ($commentBlock =~ m|^(\h*\t*)|s? $1 : q());
                  my $numberOfTABS = () = $leadingHorizontalSpace =~ m/\t/g;
                  $leadingHorizontalSpace =~ s/\t/    /g;

                  my $commentValue = q();
                  $trailingComments = q();

                  # split the trailing comments, and put the *values* together
                  foreach (split(/([0-9]+)$tokens{endOfToken}/,$commentBlock)){
                     next unless $_ =~ m/[0-9]/;

                     $commentValue .= " ".${$trailingComments[$_-1]}{value};
                  }

                  # very first space
                  $commentValue =~ s|^\h||s;

                  # leading space
                  $commentValue =~ s|^(\h*)||s;
                  my $leadingSpace =  (${${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{comments}}{inheritLeadingSpace}? $1: ' ' );

                  $commentValue =~ s/\h{2,}/ /sg if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{multipleSpacesToSingle};

                  # reset columns
                  $Text::Wrap::columns = $columns - length($leadingHorizontalSpace)-length($leadingSpace);
                  #                                                                ^^
                  #                                                                for the space added after comment symbol below
                  
                  # tab adjustment
                  for (my $i=1; $i<=$numberOfTABS;$i++){
                      $leadingHorizontalSpace =~ s/    /\t/;
                  }

                  # wrap the comments
                  $commentValue = wrap( '', '', $commentValue );

                  # put them into storage
                  $trailingComments .= $leadingHorizontalSpace."%".$self->add_comment_symbol(value=>$leadingSpace.$_)."\n" foreach (split( /\R/, $commentValue ) );
            
          }
          $trailingComments;
    &xemg;

    #
    # text wrap multiple comments on a line
    #
    # from:
    #
    #   % fifth comment% fourth comment% third comment% second comment% first comment
    #
    # into:
    #
    #   % first comment second comment
    #   % third comment fourth comment
    #   % fifth comment
    #
    ${$self}{body} =~ s&((?:$trailingCommentRegExp\h*)+)&
          my @commentBlocks = $1;
          my $trailingComments = q();

          # loop through comment blocks
          foreach my $commentBlock (@commentBlocks){

                  my $leadingHorizontalSpace = ($commentBlock =~ m|^(\h*\t*)|s? $1 : q());
                  my $numberOfTABS = () = $leadingHorizontalSpace =~ m/\t/g;
                  $leadingHorizontalSpace =~ s/\t/    /g;

                  my $commentValue = q();
                  $trailingComments = q();

                  # split the trailing comments, and put the *values* together
                  foreach (split(/([0-9]+)$tokens{endOfToken}/,$commentBlock)){
                     next unless $_ =~ m/[0-9]/;

                     $commentValue .= " ".${$trailingComments[$_-1]}{value};
                  }

                  # very first space
                  $commentValue =~ s|^\h||s;

                  # leading space
                  $commentValue =~ s|^(\h*)||s;
                  my $leadingSpace =  (${${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{comments}}{inheritLeadingSpace}? $1: ' ' );

                  $commentValue =~ s/\h{2,}/ /sg if ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{multipleSpacesToSingle};

                  # reset columns
                  $Text::Wrap::columns = $columns - length($leadingHorizontalSpace)-length($leadingSpace);
                  #                                                                ^^
                  #                                                                for the space added after comment symbol below
                  
                  # tab adjustment
                  for (my $i=1; $i<=$numberOfTABS;$i++){
                      $leadingHorizontalSpace =~ s/    /\t/;
                  }

                  # wrap the comments
                  $commentValue = wrap( '', '', $commentValue );

                  # put them into storage
                  $trailingComments .= $leadingHorizontalSpace."%".$self->add_comment_symbol(value=>$leadingSpace.$_)."\n" foreach (split( /\R/, $commentValue ) );
            
          }
          $trailingComments;
    &xemg;
}
1;
