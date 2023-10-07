package LatexIndent::TrailingComments;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active $is_m_switch_active/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::LogFile qw/$logger/;
use Data::Dumper;
use Exporter qw/import/;
our @EXPORT_OK
    = qw/remove_trailing_comments put_trailing_comments_back_in $trailingCommentRegExp add_comment_symbol construct_trailing_comment_regexp @trailingComments/;
our @trailingComments;
our $commentCounter = 0;
our $trailingCommentRegExp;

sub construct_trailing_comment_regexp {
    my $notPreceededBy = qr/${${$mainSettings{fineTuning}}{trailingComments}}{notPreceededBy}/;

    $trailingCommentRegExp = qr/$notPreceededBy%$tokens{trailingComment}\d+$tokens{endOfToken}/;
}

sub add_comment_symbol {

    # add a trailing comment token after, for example, a square brace [
    # or a curly brace { when, for example, BeginStartsOnOwnLine == 2
    my $self  = shift;
    my %input = @_;

    my $commentValue = ( defined $input{value} ? $input{value} : q() );

    # increment the comment counter
    $commentCounter++;

    # store the comment -- without this, it won't get processed correctly at the end
    push( @trailingComments,
        { id => $tokens{trailingComment} . $commentCounter . $tokens{endOfToken}, value => $commentValue } );

    # log file info
    $logger->trace("*Updating trailing comment array") if $is_t_switch_active;
    $logger->trace( Dumper( \@trailingComments ), 'ttrace' ) if ($is_tt_switch_active);

    # the returned value
    return $tokens{trailingComment} . $commentCounter . $tokens{endOfToken};
}

sub remove_trailing_comments {
    my $self = shift;

    $commentCounter = 0;

    $logger->trace("*Storing trailing comments") if $is_t_switch_active;

    my $notPreceededBy = qr/${${$mainSettings{fineTuning}}{trailingComments}}{notPreceededBy}/;
    my $afterComment   = qr/${${$mainSettings{fineTuning}}{trailingComments}}{afterComment}/;

    # perform the substitution
    ${$self}{body} =~ s/
                            $notPreceededBy   # not preceded by a \
                            %                 # % 
                            (
                                $afterComment # anything else
                            )
                            $                 # up to the end of a line
                        /   
                            # increment comment counter and store comment
                            $commentCounter++;
                            push(@trailingComments,{id=>$tokens{trailingComment}.$commentCounter.$tokens{endOfToken},value=>$1});

                            # replace comment with dummy text
                            "%".$tokens{trailingComment}.$commentCounter.$tokens{endOfToken};
                       /xsmeg;
    if (@trailingComments) {
        $logger->trace("Trailing comments stored in:") if ($is_tt_switch_active);
        $logger->trace( Dumper( \@trailingComments ) ) if ($is_tt_switch_active);
    }
    else {
        $logger->trace("No trailing comments found") if ($is_t_switch_active);
    }
    return;
}

sub put_trailing_comments_back_in {
    my $self = shift;
    return unless ( @trailingComments > 0 );

    $logger->trace("*Returning trailing comments to body") if $is_t_switch_active;

    # loop through trailing comments in reverse so that, for example,
    # latexindenttrailingcomment1 doesn't match the first
    # part of latexindenttrailingcomment18, which would result in an 8 left over (bad)
    while ( my $comment = pop @trailingComments ) {
        my $trailingcommentID    = ${$comment}{id};
        my $trailingcommentValue = ${$comment}{value};

        # the -m switch can modify max characters per line, and trailing comment IDs can
        # be split across lines
        if (    $is_m_switch_active
            and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge} ne "overflow"
            and ${$self}{body} !~ m/%$trailingcommentID/m )
        {
            $logger->trace(
                "$trailingcommentID not found in body using /m matching, assuming it has been split across line (see modifyLineBreaks: textWrapOptions)"
            ) if ($is_t_switch_active);
            my $trailingcommentIDwithLineBreaks;

            # construct a reg exp that contains possible line breaks in between each character
            if ( ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{separator} ne '' ) {
                $trailingcommentIDwithLineBreaks = join(
                    "\\" . ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{separator} . "?",
                    split( //, $trailingcommentID )
                );
            }
            else {
                $trailingcommentIDwithLineBreaks = join( "(?:\\h|\\R)*", split( //, $trailingcommentID ) );
            }
            my $trailingcommentIDwithLineBreaksRegExp = qr/$trailingcommentIDwithLineBreaks/s;

            # replace the line-broken trailing comment ID with a non-broken trailing comment ID
            ${$self}{body} =~ s/%\R?$trailingcommentIDwithLineBreaksRegExp/%$trailingcommentID/s;
        }
        my $notPreceededBy = qr/${${$mainSettings{fineTuning}}{trailingComments}}{notPreceededBy}/;
        if (${$self}{body} =~ m/%$trailingcommentID
                              (
                                  (?!                  # not immediately preceded by 
                                      $notPreceededBy  # \
                                      %                # %
                                  ).*?
                              )                        # captured into $1
                              (\h*)?$                
                          /mx and $1 ne ''
            )
        {
            $logger->trace("Comment not at end of line $trailingcommentID, moving it to end of line")
                if $is_t_switch_active;
            ${$self}{body} =~ s/%$trailingcommentID(.*)$/$1%$trailingcommentValue/m;
        }
        else {
            ${$self}{body} =~ s/%$trailingcommentID/%$trailingcommentValue/;
        }
        $logger->trace("replace %$trailingcommentID with %$trailingcommentValue") if ($is_tt_switch_active);
    }
    return;
}

1;
