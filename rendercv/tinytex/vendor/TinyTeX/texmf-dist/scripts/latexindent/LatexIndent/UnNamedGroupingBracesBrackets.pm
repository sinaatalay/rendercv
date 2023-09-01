package LatexIndent::UnNamedGroupingBracesBrackets;

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
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use Exporter qw/import/;
our @ISA = "LatexIndent::Command";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK
    = qw/construct_unnamed_grouping_braces_brackets_regexp $un_named_grouping_braces_RegExp $un_named_grouping_braces_RegExp_trailing_comment/;
our $unNamedGroupingBracesCounter;
our $un_named_grouping_braces_RegExp;
our $un_named_grouping_braces_RegExp_trailing_comment;

sub construct_unnamed_grouping_braces_brackets_regexp {
    my $self = shift;

    # grab the arguments regexp
    my $optAndMandRegExp = $self->get_arguments_regexp;

    # blank line token
    my $blankLineToken = $tokens{blanklines};

    # arguments Before, by default, includes beamer special and numbered arguments, for example #1 #2, etc
    my $argumentsBefore             = qr/${${$mainSettings{fineTuning}}{arguments}}{before}/;
    my $UnNamedGroupingFollowRegExp = qr/${${$mainSettings{fineTuning}}{UnNamedGroupingBracesBrackets}}{follow}/;

    # store the regular expression for matching and replacing
    $un_named_grouping_braces_RegExp = qr/
                  # NOT
                  (?!
                      (?:
                        (?:(?<!\\)\]) 
                        |
                        (?:(?<!\\)\}) 
                      )
                      (?:\h|\R|$blankLineToken|$trailingCommentRegExp|$argumentsBefore)*  # 0 or more h-space, blanklines, trailing comments
                  )
                  # END of NOT
                  (
                     (?:
                        $UnNamedGroupingFollowRegExp # starting with { OR [ OR , OR & OR ) OR ( OR $
                     )
                     \h*
                  )                                  # $1 into beginning bit
                  (\R*)                              # $2 linebreaksAtEnd of begin
                  ($optAndMandRegExp)                # $3 mand|opt arguments (at least one) stored into body
                  (\R)?                              # $6 linebreak 
                /sx;

    $un_named_grouping_braces_RegExp_trailing_comment
        = qr/$un_named_grouping_braces_RegExp(\h*)((?:$trailingCommentRegExp\h*)*)?/;
}

sub create_unique_id {
    my $self = shift;

    $unNamedGroupingBracesCounter++;
    ${$self}{id} = "$tokens{UnNamedGroupingBracesBrackets}$unNamedGroupingBracesCounter";
    return;
}

sub get_replacement_text {
    my $self = shift;

# the replacement text for a key = {value} needes to accommodate the leading [ OR { OR % OR , OR any combination thereof
    $logger->trace("Custom replacement text routine for ${$self}{name}") if $is_t_switch_active;

# the un-named object is a little special, as it doesn't have a name; as such, if there are blank lines before
# the braces/brackets, we have to insert them
#
# also, the argument reg-exp can pick up a leading comment (with line break), which needs to be put
# into the replacement text (see documentation/demonstrations/pstricks.tex and test-cases/unnamed-braces/unnamed.tex for example)
    ${$self}{body} =~ s/(.*?)(\{|\[)/$2/s;
    ${$self}{replacementText} = ${$self}{beginningbit} . ( $1 ne '' ? $1 : q() ) . ${$self}{id};

    # but now turn off the switch for linebreaksAtEnd{begin}, otherwise the first brace gets too much indentation
    # (see, for example, test-cases/namedGroupingBracesBrackets/special-characters-minimal.tex)
    ${ ${$self}{linebreaksAtEnd} }{begin} = 0;
    $logger->trace("Beginning bit is: ${$self}{beginningbit}") if ($is_t_switch_active);
    delete ${$self}{beginningbit};
}

sub check_for_blank_lines_at_beginning {

    # some examples can have blank line tokens at the beginning of the body,
    # which can confuse the routine below
    # See, for example,
    #       test-cases/namedGroupingBracesBrackets/special-characters-minimal-blank-lines-m-switch.tex
    #   compared to
    #       test-cases/namedGroupingBracesBrackets/special-characters-minimal-blank-lines-default.tex
    my $self = shift;

    # blank line token
    my $blankLineToken = $tokens{blanklines};

    # if the body begins with 2 or more blank line tokens
    if ( ${$self}{body} =~ m/^((?:$blankLineToken\R){2,})/s ) {

        # remove them
        ${$self}{body} =~ s/^((?:$blankLineToken\R)+)//s;

        # store
        my $blank_line_tokens_at_beginning_of_body = $1;

        # and count them, for use after the indentation routine
        ${$self}{blankLinesAtBeginning} = () = $blank_line_tokens_at_beginning_of_body =~ /$blankLineToken\R/sg;
    }
    return;
}

sub put_blank_lines_back_in_at_beginning {
    my $self = shift;

    # some bodies have blank lines at the beginning
    if ( ${$self}{blankLinesAtBeginning} ) {
        for ( my $i = 0; $i < ${$self}{blankLinesAtBeginning}; $i++ ) {
            ${$self}{body} = $tokens{blanklines} . ${$self}{body};
        }
    }
    return;
}

1;
