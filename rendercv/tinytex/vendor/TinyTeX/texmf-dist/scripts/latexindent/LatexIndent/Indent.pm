package LatexIndent::Indent;

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
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::Switches qw/$is_m_switch_active $is_t_switch_active $is_tt_switch_active/;
use LatexIndent::HiddenChildren qw/%familyTree/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::LogFile qw/$logger/;
use Text::Tabs;
use Data::Dumper;
use Exporter qw/import/;
our @EXPORT_OK
    = qw/indent wrap_up_statement determine_total_indentation indent_begin indent_body indent_end_statement final_indentation_check push_family_tree_to_indent get_surrounding_indentation indent_children_recursively check_for_blank_lines_at_beginning put_blank_lines_back_in_at_beginning add_surrounding_indentation_to_begin_statement post_indentation_check replace_id_with_begin_body_end/;
our %familyTree;

sub indent {
    my $self = shift;

    # determine the surrounding and current indentation
    $self->determine_total_indentation;

    # indent the begin statement
    $self->indent_begin;

    # indent the body
    $self->indent_body;

    # indent the end statement
    $self->indent_end_statement;

    # output the completed object to the log file
    $logger->trace(
        "Complete indented object (${$self}{name}) after indentation:\n${$self}{begin}${$self}{body}${$self}{end}")
        if $is_tt_switch_active;

    # wrap-up statement
    $self->wrap_up_statement;
    return $self;
}

sub wrap_up_statement {
    my $self = shift;
    $logger->trace("*Finished indenting ${$self}{name}") if $is_t_switch_active;
    return $self;
}

sub determine_total_indentation {
    my $self = shift;

    # calculate and grab the surrounding indentation
    $self->get_surrounding_indentation;

    # logfile information
    my $surroundingIndentation = ${$self}{surroundingIndentation};
    $logger->trace("indenting object ${$self}{name}") if ($is_t_switch_active);
    ( my $during = $surroundingIndentation ) =~ s/\t/TAB/g;
    $logger->trace("indentation *surrounding* object: '$during'") if ($is_t_switch_active);
    ( $during = ${$self}{indentation} ) =~ s/\t/TAB/g;
    $logger->trace("indentation *of* object: '$during'") if ($is_t_switch_active);
    ( $during = $surroundingIndentation . ${$self}{indentation} ) =~ s/\t/TAB/g;
    $logger->trace("*total* indentation to be added: '$during'") if ($is_t_switch_active);

    # form the total indentation of the object
    ${$self}{indentation} = $surroundingIndentation . ${$self}{indentation};

}

sub get_surrounding_indentation {
    my $self = shift;

    my $surroundingIndentation = q();

    if ( $familyTree{ ${$self}{id} } ) {
        $logger->trace("Adopted ancestors found!") if ($is_t_switch_active);
        foreach ( @{ ${ $familyTree{ ${$self}{id} } }{ancestors} } ) {
            if ( ${$_}{type} eq "adopted" ) {
                my $newAncestorId = ${$_}{ancestorID};
                $logger->trace(
                    "ancestor ID: $newAncestorId, adding indentation of $newAncestorId to surroundingIndentation of ${$self}{id}"
                ) if ($is_t_switch_active);
                $surroundingIndentation .=
                    ref( ${$_}{ancestorIndentation} ) eq 'SCALAR'
                    ? ( ${ ${$_}{ancestorIndentation} } ? ${ ${$_}{ancestorIndentation} } : q() )
                    : ( ${$_}{ancestorIndentation}      ? ${$_}{ancestorIndentation}      : q() );
            }
        }
    }
    ${$self}{surroundingIndentation} = $surroundingIndentation;

}

sub indent_begin {

    # for most objects, the begin statement is just one line, but there are exceptions, e.g KeyEqualsValuesBraces
    return;
}

sub indent_body {
    my $self = shift;

    # output to the logfile
    $logger->trace("Body (${$self}{name}) before indentation:\n${$self}{body}") if $is_tt_switch_active;

    # last minute check for modified bodyLineBreaks
    $self->count_body_line_breaks if $is_m_switch_active;

    # some objects need to check for blank line tokens at the beginning
    $self->check_for_blank_lines_at_beginning if $is_m_switch_active;

    # some objects can format their body to align at the & character
    $self->align_at_ampersand if ( ${$self}{lookForAlignDelims} and !${$self}{dontMeasure} );

    # grab the indentation of the object
    # NOTE: we need this here, as ${$self}{indentation} can be updated by the align_at_ampersand routine,
    #       see https://github.com/cmhughes/latexindent.pl/issues/223 for example
    my $indentation = ${$self}{indentation};

    # possibly remove paragraph line breaks
    $self->remove_paragraph_line_breaks
        if ($is_m_switch_active
        and ${$self}{removeParagraphLineBreaks}
        and !${ $mainSettings{modifyLineBreaks}{removeParagraphLineBreaks} }{beforeTextWrap} );

    # body indentation
    if ( ${$self}{linebreaksAtEnd}{begin} == 1 ) {
        if ( ${$self}{body} =~ m/^\h*$/s ) {
            $logger->trace("Body of ${$self}{name} is empty, not applying indentation") if $is_t_switch_active;
        }
        else {
            # put any existing horizontal space after the current indentation
            $logger->trace("Entire body of ${$self}{name} receives indendentation") if $is_t_switch_active;
            ${$self}{body} =~ s/^(\h*)/$indentation$1/mg;    # add indentation
        }
    }
    elsif ( ${$self}{linebreaksAtEnd}{begin} == 0 and ${$self}{bodyLineBreaks} > 0 ) {
        if (${$self}{body} =~ m/
                            (.*?)      # content of first line
                            \R         # first line break
                            (.*$)      # rest of body
                            /sx
            )
        {
            my $bodyFirstLine = $1;
            my $remainingBody = $2;
            $logger->trace("first line of body: $bodyFirstLine") if $is_tt_switch_active;
            $logger->trace("remaining body (before indentation):\n'$remainingBody'") if ($is_tt_switch_active);

            # add the indentation to all the body except first line
            $remainingBody =~ s/^/$indentation/mg unless ( $remainingBody eq '' );    # add indentation
            $logger->trace("remaining body (after indentation):\n$remainingBody'") if ($is_tt_switch_active);

            # put the body back together
            ${$self}{body} = $bodyFirstLine . "\n" . $remainingBody;
        }
    }

    # some objects need a post-indentation check, e.g ifElseFi
    $self->post_indentation_check;

    # if the routine check_for_blank_lines_at_beginning has been called, then the following routine
    # puts blank line tokens back in
    $self->put_blank_lines_back_in_at_beginning if $is_m_switch_active;

    # the final linebreak can be modified by a child object; see test-cases/commands/figureValign-mod5.tex, for example
    if (    $is_m_switch_active
        and defined ${$self}{linebreaksAtEnd}{body}
        and ${$self}{linebreaksAtEnd}{body} == 1
        and ${$self}{body} !~ m/\R$/
        and ${$self}{body} ne '' )
    {
        $logger->trace(
            "Adding a linebreak at end of body for ${$self}{name} to contain a linebreak at the end (linebreaksAtEnd is 1, but there isn't currently a linebreak)"
        ) if ($is_t_switch_active);
        ${$self}{body} .= "\n";
    }

    # output to the logfile
    $logger->trace("Body (${$self}{name}) after indentation:\n${$self}{body}") if $is_tt_switch_active;
    return $self;
}

sub post_indentation_check {
    return;
}

sub check_for_blank_lines_at_beginning {

    # some objects need this routine
    return;
}

sub put_blank_lines_back_in_at_beginning {

    # some objects need this routine
    return;
}

sub indent_end_statement {
    my $self = shift;
    my $surroundingIndentation
        = ( ${$self}{surroundingIndentation} and $familyTree{ ${$self}{id} } )
        ? (
        ref( ${$self}{surroundingIndentation} ) eq 'SCALAR'
        ? ${ ${$self}{surroundingIndentation} }
        : ${$self}{surroundingIndentation}
        )
        : q();

    # end{statement} indentation, e.g \end{environment}, \fi, }, etc
    if ( ${$self}{linebreaksAtEnd}{body} ) {
        ${$self}{end} =~ s/^\h*/$surroundingIndentation/mg;    # add indentation
        $logger->trace("Adding surrounding indentation to ${$self}{end} (${$self}{name}: '$surroundingIndentation')")
            if ($is_t_switch_active);
    }
    return $self;
}

sub final_indentation_check {

    # problem:
    #       if a tab is appended to spaces, it will look different
    #       from spaces appended to tabs (see test-cases/items/spaces-and-tabs.tex)
    # solution:
    #       move all of the tabs to the beginning of ${$self}{indentation}
    # notes;
    #       this came to light when studying test-cases/items/items1.tex

    my $self = shift;

    my $indentation;
    my $numberOfTABS;
    my $after;
    ${$self}{body} =~ s/
                        ^((\h*|\t*)((\h+)(\t+))+)
                        /   
                        # fix the indentation
                        $indentation = $1;

                        # count the number of tabs
                        $numberOfTABS = () = $indentation=~ \/\t\/g;
                        $logger->trace("Number of tabs: $numberOfTABS") if($is_t_switch_active);

                        # log the after
                        ($after = $indentation) =~ s|\t||g;
                        $after = "TAB"x$numberOfTABS.$after;
                        $logger->trace("Indentation after: '$after'") if($is_t_switch_active);
                        ($indentation = $after) =~s|TAB|\t|g;

                        $indentation;
                       /xsmeg;

    return unless ( $mainSettings{maximumIndentation} =~ m/^\h+$/ );

    # maximum indentation check
    $logger->trace("*Maximum indentation check") if ($is_t_switch_active);

    # replace any leading tabs with spaces, and update the body
    my @expanded_lines = expand( ${$self}{body} );
    ${$self}{body} = join( "", @expanded_lines );

    # grab the maximum indentation
    my $maximumIndentation       = $mainSettings{maximumIndentation};
    my $maximumIndentationLength = length($maximumIndentation) + 1;

    # replace any leading space that is greater than the
    # specified maximum indentation with the maximum indentation
    ${$self}{body} =~ s/^\h{$maximumIndentationLength,}/$maximumIndentation/smg;
}

sub indent_children_recursively {
    my $self = shift;

    unless ( defined ${$self}{children} ) {
        $logger->trace("No child objects (${$self}{name})") if $is_t_switch_active;
        return;
    }

    $logger->trace('Pre-processed body:') if $is_tt_switch_active;
    $logger->trace( ${$self}{body} ) if ($is_tt_switch_active);

    # send the children through this indentation routine recursively
    if ( defined ${$self}{children} ) {
        foreach my $child ( @{ ${$self}{children} } ) {
            $logger->trace("Indenting child objects on ${$child}{name}") if $is_t_switch_active;
            $child->indent_children_recursively;
        }
    }

    $logger->trace("*Replacing ids with begin, body, and end statements:") if $is_t_switch_active;

    # loop through document children hash
    while ( scalar( @{ ${$self}{children} } ) > 0 ) {
        my $index = 0;

        # we work through the array *in order*
        foreach my $child ( @{ ${$self}{children} } ) {
            $logger->trace("Searching ${$self}{name} for ${$child}{id}...") if $is_t_switch_active;

            my $restartLoop = $self->replace_id_with_begin_body_end( $child, $index );
            last if $restartLoop;

            # increment the loop counter
            $index++;
        }
    }

    # logfile info
    $logger->trace("${$self}{name} has this many children:") if $is_tt_switch_active;
    $logger->trace( scalar @{ ${$self}{children} } )         if $is_tt_switch_active;
    $logger->trace("Post-processed body (${$self}{name}):")  if ($is_tt_switch_active);
    $logger->trace( ${$self}{body} )                         if ($is_tt_switch_active);

}

sub replace_id_with_begin_body_end {

    my $self = shift;
    my ( $child, $index ) = (@_);

    if ( ${$self}{body} =~ m/${$child}{idRegExp}/s ) {

        # we only care if id is first non-white space character
        # and if followed by line break
        # if m switch is active
        my $IDFirstNonWhiteSpaceCharacter    = 0;
        my $IDFollowedImmediatelyByLineBreak = 0;

        # update the above two, if necessary
        if ($is_m_switch_active) {
            $IDFirstNonWhiteSpaceCharacter = (
                       ${$self}{body} =~ m/^${$child}{idRegExp}/m
                    or ${$self}{body} =~ m/^\h\h*${$child}{idRegExp}/m
            ) ? 1 : 0;
            $IDFollowedImmediatelyByLineBreak = ( ${$self}{body} =~ m/${$child}{idRegExp}\h*\R+/m ) ? 1 : 0;
            ${$child}{IDFollowedImmediatelyByLineBreak} = $IDFollowedImmediatelyByLineBreak;
        }

        # log file info
        $logger->trace("${$child}{id} found!")                              if ($is_t_switch_active);
        $logger->trace("*Indenting  ${$child}{name} (id: ${$child}{id})")   if $is_t_switch_active;
        $logger->trace("looking up indentation scheme for ${$child}{name}") if ($is_t_switch_active);

        # line break checks *after* <end statement>
        if (    defined ${$child}{EndFinishesWithLineBreak}
            and ${$child}{EndFinishesWithLineBreak} == -1
            and $IDFollowedImmediatelyByLineBreak )
        {
            # remove line break *after* <end statement>, if appropriate
            my $EndStringLogFile = ${$child}{aliases}{EndFinishesWithLineBreak} || "EndFinishesWithLineBreak";
            $logger->trace("Removing linebreak after ${$child}{end} (see $EndStringLogFile)")
                if $is_t_switch_active;
            ${$self}{body} =~ s/${$child}{idRegExp}(\h*)?(\R|\h)*/${$child}{id}$1/s;
            ${$child}{linebreaksAtEnd}{end} = 0;
        }

        # perform indentation
        $child->indent;

        # surrounding indentation is now up to date
        my $surroundingIndentation
            = ( ${$child}{surroundingIndentation} and ${$child}{hiddenChildYesNo} )
            ? (
            ref( ${$child}{surroundingIndentation} ) eq 'SCALAR'
            ? ${ ${$child}{surroundingIndentation} }
            : ${$child}{surroundingIndentation}
            )
            : q();

        # line break checks before <begin statement>
        if ( defined ${$child}{BeginStartsOnOwnLine} and ${$child}{BeginStartsOnOwnLine} != 0 ) {
            my $BeginStringLogFile = ${$child}{aliases}{BeginStartsOnOwnLine} || "BeginStartsOnOwnLine";

            #
            # Blank line poly-switch notes (==4)
            #
            # when BeginStartsOnOwnLine=4 we adopt the following approach:
            #   temporarily change BeginStartsOnOwnLine to -1, make adjustments
            #   temporarily change BeginStartsOnOwnLine to 3, make adjustments
            #
            # we use an array, @polySwitchValues to facilitate this
            my @polySwitchValues
                = ( ${$child}{BeginStartsOnOwnLine} == 4 ) ? ( -1, 3 ) : ( ${$child}{BeginStartsOnOwnLine} );

            foreach (@polySwitchValues) {

                # if BeginStartsOnOwnLine is 4, then we hack
                #       $IDFirstNonWhiteSpaceCharacter
                # to be 0 on the second time through (poly-switch set to 3)
                $IDFirstNonWhiteSpaceCharacter = 0 if ( ${$child}{BeginStartsOnOwnLine} == 4 and $_ == 3 );

                # if the child ID is not the first character and BeginStartsOnOwnLine>=1
                # then we will need to add a line break (==1), a comment (==2) or another blank line (==3)
                if ( $_ >= 1 and !$IDFirstNonWhiteSpaceCharacter ) {

                    # by default, assume that no trailing comment token is needed
                    my $trailingCharacterToken = q();
                    if ( $_ == 2 ) {
                        $logger->trace(
                            "Removing space immediately before ${$child}{id}, in preparation for adding % ($BeginStringLogFile == 2)"
                        ) if $is_t_switch_active;
                        ${$self}{body} =~ s/\h*${$child}{idRegExp}/${$child}{id}/s;
                        $logger->trace(
                            "Adding a % at the end of the line that ${$child}{begin} is on, then a linebreak ($BeginStringLogFile == 2)"
                        ) if $is_t_switch_active;
                        $trailingCharacterToken = "%" . $self->add_comment_symbol;
                    }
                    elsif ( $_ == 3 ) {
                        $logger->trace(
                            "Adding a blank line at the end of the line that ${$child}{begin} is on, then a linebreak ($BeginStringLogFile == 3)"
                        ) if $is_t_switch_active;
                        $trailingCharacterToken = "\n"
                            . (
                            ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines}
                            ? $tokens{blanklines}
                            : q()
                            );
                    }
                    else {
                        $logger->trace(
                            "Adding a linebreak at the beginning of ${$child}{begin} (see $BeginStringLogFile)")
                            if $is_t_switch_active;
                    }

                    # the trailing comment/linebreak magic
                    ${$child}{begin} = "$trailingCharacterToken\n" . ${$child}{begin};
                    $child->add_surrounding_indentation_to_begin_statement;

                    # remove surrounding indentation ahead of %
                    ${$child}{begin} =~ s/^(\h*)%/%/ if ( $_ == 2 );
                }
                elsif ( $_ == -1 and $IDFirstNonWhiteSpaceCharacter ) {

                    # finally, if BeginStartsOnOwnLine == -1 then we might need to *remove* a blank line(s)
                    # important to check we don't move the begin statement next to a blank-line-token
                    my $blankLineToken = $tokens{blanklines};
                    if ( ${$self}{body} !~ m/$blankLineToken\R*\h*${$child}{idRegExp}/s ) {
                        $logger->trace(
                            "Removing linebreak before ${$child}{begin} (see $BeginStringLogFile in ${$child}{modifyLineBreaksYamlName} YAML)"
                        ) if $is_t_switch_active;
                        ${$self}{body} =~ s/(\h*)(?:\R*|\h*)+${$child}{idRegExp}/$1${$child}{id}/s;
                    }
                    else {
                        $logger->trace(
                            "Not removing linebreak ahead of ${$child}{begin}, as blank-line-token present (see preserveBlankLines)"
                        ) if $is_t_switch_active;
                    }
                }
            }
        }

        $logger->trace( Dumper( \%{$child} ) ) if ($is_tt_switch_active);

        # replace ids with body
        ${$self}{body} =~ s/${$child}{idRegExp}/${$child}{begin}${$child}{body}${$child}{end}/;

        # log file info
        $logger->trace("Body (${$self}{name}) now looks like:") if $is_tt_switch_active;
        $logger->trace( ${$self}{body} ) if ($is_tt_switch_active);

# remove element from array: http://stackoverflow.com/questions/174292/what-is-the-best-way-to-delete-a-value-from-an-array-in-perl
        splice( @{ ${$self}{children} }, $index, 1 );

        # output to the log file
        $logger->trace("deleted child key ${$child}{name} (parent is: ${$self}{name})") if $is_t_switch_active;

        # restart the loop, as the size of the array has changed
        return 1;
    }
    else {
        $logger->trace("${$child}{id} not found") if ($is_t_switch_active);
        return 0;
    }
}

sub add_surrounding_indentation_to_begin_statement {

    # almost all of the objects add surrounding indentation to the 'begin' statements,
    # but some (e.g HEADING) have their own method
    my $self = shift;

    my $surroundingIndentation = ${$self}{surroundingIndentation};
    ${$self}{begin} =~ s/^(\h*)?/$surroundingIndentation/mg;    # add indentation

}

1;
