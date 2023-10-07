package LatexIndent::ModifyLineBreaks;

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
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use LatexIndent::Switches qw/$is_m_switch_active $is_t_switch_active $is_tt_switch_active/;
use LatexIndent::Item qw/$listOfItems/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::Verbatim qw/%verbatimStorage/;
our @EXPORT_OK
    = qw/modify_line_breaks_body modify_line_breaks_end modify_line_breaks_end_after adjust_line_breaks_end_parent remove_line_breaks_begin verbatim_modify_line_breaks/;
our $paragraphRegExp = q();

sub modify_line_breaks_body {
    my $self = shift;
    #
    # Blank line poly-switch notes (==4)
    #
    # when BodyStartsOnOwnLine=4 we adopt the following approach:
    #   temporarily change BodyStartsOnOwnLine to -1, make adjustments
    #   temporarily change BodyStartsOnOwnLine to 3, make adjustments
    # switch BodyStartsOnOwnLine back to 4

    # add a line break after \begin{statement} if appropriate
    my @polySwitchValues = ( ${$self}{BodyStartsOnOwnLine} == 4 ) ? ( -1, 3 ) : ( ${$self}{BodyStartsOnOwnLine} );
    foreach (@polySwitchValues) {
        my $BodyStringLogFile = ${$self}{aliases}{BodyStartsOnOwnLine} || "BodyStartsOnOwnLine";
        if ( $_ >= 1 and !${$self}{linebreaksAtEnd}{begin} ) {

            # if the <begin> statement doesn't finish with a line break,
            # then we have different actions based upon the value of BodyStartsOnOwnLine:
            #     BodyStartsOnOwnLine == 1 just add a new line
            #     BodyStartsOnOwnLine == 2 add a comment, and then new line
            #     BodyStartsOnOwnLine == 3 add a blank line, and then new line
            if ( $_ == 1 ) {

                # modify the begin statement
                $logger->trace(
                    "Adding a linebreak at the end of begin statement ${$self}{begin} (see $BodyStringLogFile)")
                    if $is_t_switch_active;
                ${$self}{begin} .= "\n";
                ${$self}{linebreaksAtEnd}{begin} = 1;
                $logger->trace("Removing leading space from body of ${$self}{name} (see $BodyStringLogFile)")
                    if $is_t_switch_active;
                ${$self}{body} =~ s/^\h*//;
            }
            elsif ( $_ == 2 ) {

                # by default, assume that no trailing comment token is needed
                my $trailingCommentToken = q();
                if ( ${$self}{body} !~ m/^\h*$trailingCommentRegExp/s ) {

                    # modify the begin statement
                    $logger->trace(
                        "Adding a % at the end of begin ${$self}{begin} followed by a linebreak ($BodyStringLogFile == 2)"
                    ) if $is_t_switch_active;
                    $trailingCommentToken = "%" . $self->add_comment_symbol;
                    ${$self}{begin} =~ s/\h*$//;
                    ${$self}{begin} .= "$trailingCommentToken\n";
                    ${$self}{linebreaksAtEnd}{begin} = 1;
                    $logger->trace("Removing leading space from body of ${$self}{name} (see $BodyStringLogFile)")
                        if $is_t_switch_active;
                    ${$self}{body} =~ s/^\h*//;
                }
                else {
                    $logger->trace(
                        "Even though $BodyStringLogFile == 2, ${$self}{begin} already finishes with a %, so not adding another."
                    ) if $is_t_switch_active;
                }
            }
            elsif ( $_ == 3 ) {
                my $trailingCharacterToken = q();
                $logger->trace(
                    "Adding a blank line at the end of begin ${$self}{begin} followed by a linebreak ($BodyStringLogFile == 3)"
                ) if $is_t_switch_active;
                ${$self}{begin} =~ s/\h*$//;
                ${$self}{begin}
                    .= ( ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} ? $tokens{blanklines} : "\n" ) . "\n";
                ${$self}{linebreaksAtEnd}{begin} = 1;
                $logger->trace("Removing leading space from body of ${$self}{name} (see $BodyStringLogFile)")
                    if $is_t_switch_active;
                ${$self}{body} =~ s/^\h*//;
            }
        }
        elsif ( $_ == -1 and ${$self}{linebreaksAtEnd}{begin} ) {

            # remove line break *after* begin, if appropriate
            $self->remove_line_breaks_begin;
        }
    }
}

sub remove_line_breaks_begin {
    my $self              = shift;
    my $BodyStringLogFile = ${$self}{aliases}{BodyStartsOnOwnLine} || "BodyStartsOnOwnLine";
    $logger->trace("Removing linebreak at the end of begin (see $BodyStringLogFile)") if $is_t_switch_active;
    ${$self}{begin} =~ s/\R*$//sx;
    ${$self}{linebreaksAtEnd}{begin} = 0;
}

sub modify_line_breaks_end {
    my $self = shift;

    #
    # Blank line poly-switch notes (==4)
    #
    # when EndStartsOnOwnLine=4 we adopt the following approach:
    #   temporarily change EndStartsOnOwnLine to -1, make adjustments
    #   temporarily change EndStartsOnOwnLine to 3, make adjustments
    # switch EndStartsOnOwnLine back to 4
    #

    my @polySwitchValues = ( ${$self}{EndStartsOnOwnLine} == 4 ) ? ( -1, 3 ) : ( ${$self}{EndStartsOnOwnLine} );
    foreach (@polySwitchValues) {

        # possibly modify line break *before* \end{statement}
        if ( defined ${$self}{EndStartsOnOwnLine} ) {
            my $EndStringLogFile = ${$self}{aliases}{EndStartsOnOwnLine} || "EndStartsOnOwnLine";
            if ( $_ >= 1 and !${$self}{linebreaksAtEnd}{body} ) {

                # if the <body> statement doesn't finish with a line break,
                # then we have different actions based upon the value of EndStartsOnOwnLine:
                #     EndStartsOnOwnLine == 1 just add a new line
                #     EndStartsOnOwnLine == 2 add a comment, and then new line
                #     EndStartsOnOwnLine == 3 add a blank line, and then new line
                $logger->trace("Adding a linebreak at the end of body (see $EndStringLogFile)") if $is_t_switch_active;

                # by default, assume that no trailing character token is needed
                my $trailingCharacterToken = q();
                if ( $_ == 2 ) {
                    $logger->trace("Adding a % immediately after body of ${$self}{name} ($EndStringLogFile==2)")
                        if $is_t_switch_active;
                    $trailingCharacterToken = "%" . $self->add_comment_symbol;
                    ${$self}{body} =~ s/\h*$//s;
                }
                elsif ( $_ == 3 ) {
                    $logger->trace(
                        "Adding a blank line immediately after body of ${$self}{name} ($EndStringLogFile==3)")
                        if $is_t_switch_active;
                    $trailingCharacterToken = "\n"
                        . ( ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} ? $tokens{blanklines} : q() );
                    ${$self}{body} =~ s/\h*$//s;
                }

                # modified end statement
                if (    ${$self}{body} =~ m/^\h*$/s
                    and ( defined ${$self}{BodyStartsOnOwnLine} )
                    and ${$self}{BodyStartsOnOwnLine} >= 1 )
                {
                    ${$self}{linebreaksAtEnd}{body} = 0;
                }
                else {
                    ${$self}{body} .= "$trailingCharacterToken\n";
                    ${$self}{linebreaksAtEnd}{body} = 1;
                }
            }
            elsif ( $_ == -1 and ${$self}{linebreaksAtEnd}{body} ) {

                # remove line break *after* body, if appropriate

                # check to see that body does *not* finish with blank-line-token,
                # if so, then don't remove that final line break
                if ( ${$self}{body} !~ m/$tokens{blanklines}$/s ) {
                    $logger->trace("Removing linebreak at the end of body (see $EndStringLogFile)")
                        if $is_t_switch_active;
                    ${$self}{body} =~ s/\R*$//sx;
                    ${$self}{linebreaksAtEnd}{body} = 0;
                }
                else {
                    $logger->trace(
                        "Blank line token found at end of body (${$self}{name}), see preserveBlankLines, not removing line break before ${$self}{end}"
                    ) if $is_t_switch_active;
                }
            }
        }
    }

}

sub modify_line_breaks_end_after {
    my $self = shift;
    #
    # Blank line poly-switch notes (==4)
    #
    # when EndFinishesWithLineBreak=4 we adopt the following approach:
    #   temporarily change EndFinishesWithLineBreak to -1, make adjustments
    #   temporarily change EndFinishesWithLineBreak to 3, make adjustments
    # switch EndFinishesWithLineBreak back to 4
    #
    my @polySwitchValues
        = ( ${$self}{EndFinishesWithLineBreak} == 4 ) ? ( -1, 3 ) : ( ${$self}{EndFinishesWithLineBreak} );
    foreach (@polySwitchValues) {
        last if !( defined $_ );
        ${$self}{linebreaksAtEnd}{end} = 0
            if ( $_ == 3
            and ( defined ${$self}{EndFinishesWithLineBreak} and ${$self}{EndFinishesWithLineBreak} == 4 ) );

        # possibly modify line break *after* \end{statement}
        if (    defined $_
            and $_ >= 1
            and !${$self}{linebreaksAtEnd}{end}
            and ${$self}{end} ne '' )
        {
            # if the <end> statement doesn't finish with a line break,
            # then we have different actions based upon the value of EndFinishesWithLineBreak:
            #     EndFinishesWithLineBreak == 1 just add a new line
            #     EndFinishesWithLineBreak == 2 add a comment, and then new line
            #     EndFinishesWithLineBreak == 3 add a blank line, and then new line
            my $EndStringLogFile = ${$self}{aliases}{EndFinishesWithLineBreak} || "EndFinishesWithLineBreak";
            if ( $_ == 1 ) {
                $logger->trace("Adding a linebreak at the end of ${$self}{end} ($EndStringLogFile==1)")
                    if $is_t_switch_active;
                ${$self}{linebreaksAtEnd}{end} = 1;

                # modified end statement
                ${$self}{replacementText} .= "\n";
            }
            elsif ( $_ == 2 ) {
                if ( ${$self}{endImmediatelyFollowedByComment} ) {

                    # no need to add a % if one already exists
                    $logger->trace(
                        "Even though $EndStringLogFile == 2, ${$self}{end} is immediately followed by a %, so not adding another; not adding line break."
                    ) if $is_t_switch_active;
                }
                else {
                    # otherwise, create a trailing comment, and tack it on
                    $logger->trace("Adding a % immediately after ${$self}{end} ($EndStringLogFile==2)")
                        if $is_t_switch_active;
                    my $trailingCommentToken = "%" . $self->add_comment_symbol;
                    ${$self}{end} =~ s/\h*$//s;
                    ${$self}{replacementText} .= "$trailingCommentToken\n";
                    ${$self}{linebreaksAtEnd}{end} = 1;
                }
            }
            elsif ( $_ == 3 ) {
                $logger->trace("Adding a blank line at the end of ${$self}{end} ($EndStringLogFile==3)")
                    if $is_t_switch_active;
                ${$self}{linebreaksAtEnd}{end} = 1;

                # modified end statement
                ${$self}{replacementText}
                    .= ( ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} ? $tokens{blanklines} : "\n" ) . "\n";
            }
        }
    }

}

sub adjust_line_breaks_end_parent {

    # when a parent object contains a child object, the line break
    # at the end of the parent object can become messy

    my $self = shift;

    # most recent child object
    my $child = @{ ${$self}{children} }[-1];

    # adjust parent linebreaks information
    if (    ${$child}{linebreaksAtEnd}{end}
        and ${$self}{body} =~ m/${$child}{replacementText}\h*\R*$/s
        and !${$self}{linebreaksAtEnd}{body} )
    {
        $logger->trace("ID: ${$child}{id}") if ($is_t_switch_active);
        $logger->trace(
            "${$child}{begin}...${$child}{end} is found at the END of body of parent, ${$self}{name}, avoiding a double line break:"
        ) if ($is_t_switch_active);
        $logger->trace("adjusting ${$self}{name} linebreaksAtEnd{body} to be 1") if ($is_t_switch_active);
        ${$self}{linebreaksAtEnd}{body} = 1;
    }

    # the modify line switch can adjust line breaks, so we need another check,
    # see for example, test-cases/environments/environments-remove-line-breaks-trailing-comments.tex
    if (    defined ${$child}{linebreaksAtEnd}{body}
        and !${$child}{linebreaksAtEnd}{body}
        and ${$child}{body} =~ m/\R(?:$trailingCommentRegExp\h*)?$/s )
    {
        # log file information
        $logger->trace("Undisclosed line break at the end of body of ${$child}{name}: '${$child}{end}'")
            if ($is_t_switch_active);
        $logger->trace("Adding a linebreak at the end of body for ${$child}{id}") if ($is_t_switch_active);

        # make the adjustments
        ${$child}{body} .= "\n";
        ${$child}{linebreaksAtEnd}{body} = 1;
    }

}

sub verbatim_modify_line_breaks {

    # verbatim modify line breaks are a bit special, as they happen before
    # any of the main processes have been done
    my $self  = shift;
    my %input = @_;
    while ( my ( $key, $child ) = each %verbatimStorage ) {
        if ( defined ${$child}{BeginStartsOnOwnLine} ) {
            my $BeginStringLogFile = ${$child}{aliases}{BeginStartsOnOwnLine};
            $logger->trace("*$BeginStringLogFile is ${$child}{BeginStartsOnOwnLine} for ${$child}{name}")
                if $is_t_switch_active;

            my @polySwitchValues
                = ( ${$child}{BeginStartsOnOwnLine} == 4 ) ? ( -1, 3 ) : ( ${$child}{BeginStartsOnOwnLine} );

            foreach (@polySwitchValues) {
                if ( $_ == -1 ) {

                    # VerbatimStartsOnOwnLine = -1
                    if ( ${$self}{body} =~ m/^\h*${$child}{id}/m ) {
                        $logger->trace("${$child}{name} begins on its own line, removing leading line break")
                            if $is_t_switch_active;
                        ${$self}{body} =~ s/(\R|\h)*${$child}{id}/${$child}{id}/s;
                    }
                }
                elsif ( $_ >= 1 and ${$self}{body} !~ m/^\h*${$child}{id}/m ) {

                    # VerbatimStartsOnOwnLine = 1, 2 or 3
                    my $trailingCharacterToken = q();
                    if ( $_ == 1 ) {
                        $logger->trace(
                            "Adding a linebreak at the beginning of ${$child}{begin} (see $BeginStringLogFile)")
                            if $is_t_switch_active;
                    }
                    elsif ( $_ == 2 ) {
                        $logger->trace(
                            "Adding a % at the end of the line that ${$child}{begin} is on, then a linebreak ($BeginStringLogFile == 2)"
                        ) if $is_t_switch_active;
                        $trailingCharacterToken = "%" . $self->add_comment_symbol;
                    }
                    elsif ( $_ == 3 ) {
                        $logger->trace(
                            "Adding a blank line at the end of the line that ${$child}{begin} is on, then a linebreak ($BeginStringLogFile == 3)"
                        ) if $is_t_switch_active;
                        $trailingCharacterToken = "\n";
                    }
                    ${$self}{body} =~ s/\h*${$child}{id}/$trailingCharacterToken\n${$child}{id}/s;
                }
            }
        }

        # after text wrap poly-switch check
        if ( $input{when} eq "afterTextWrap" ) {
            $logger->trace("*post text wrap poly-switch check for EndFinishesWithLineBreak") if $is_t_switch_active;
            if (    defined ${$child}{EndFinishesWithLineBreak}
                and ${$child}{EndFinishesWithLineBreak} >= 1
                and ${$self}{body} =~ m/${$child}{id}\h*\S+/m )
            {
                ${$child}{linebreaksAtEnd}{end} = 1;

                # by default, assume that no trailing comment token is needed
                my $trailingCommentToken = q();
                my $lineBreakCharacter   = q();
                my $EndStringLogFile     = ${$self}{aliases}{EndStartsOnOwnLine} || "EndStartsOnOwnLine";

                if ( ${$child}{EndFinishesWithLineBreak} == 1 ) {
                    $logger->trace(
                        "Adding a linebreak at the end of ${$child}{end} (post text wrap $EndStringLogFile==1)")
                        if $is_t_switch_active;
                    $lineBreakCharacter = "\n";
                }
                elsif ( ${$child}{EndFinishesWithLineBreak} == 2
                    and ${$self}{body} !~ m/${$child}{id}\h*$trailingCommentRegExp/s )
                {
                    $logger->trace("Adding a % immediately after ${$child}{end} (post text wrap $EndStringLogFile==2)")
                        if $is_t_switch_active;
                    $trailingCommentToken = "%" . $self->add_comment_symbol . "\n";
                }
                elsif ( ${$child}{EndFinishesWithLineBreak} == 3 ) {
                    $lineBreakCharacter
                        .= ( ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} ? $tokens{blanklines} : "\n" )
                        . "\n";
                }
                ${$self}{body} =~ s/${$child}{id}(\h*)/${$child}{id}$1$trailingCommentToken$lineBreakCharacter/s;
            }
        }
    }
}

1;
