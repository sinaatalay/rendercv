package LatexIndent::NamedGroupingBracesBrackets;

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
    = qw/construct_grouping_braces_brackets_regexp $grouping_braces_regexp $grouping_braces_regexpTrailingComment/;
our $groupingBracesCounter;
our $grouping_braces_regexp;
our $grouping_braces_regexpTrailingComment;

sub construct_grouping_braces_brackets_regexp {
    my $self = shift;

    # grab the arguments regexp
    my $optAndMandRegExp = $self->get_arguments_regexp;

    # read from fine tuning
    my $NamedGroupingBracesBracketsRegExp = qr/${${$mainSettings{fineTuning}}{namedGroupingBracesBrackets}}{name}/;
    my $NamedGroupingFollowRegExp         = qr/${${$mainSettings{fineTuning}}{namedGroupingBracesBrackets}}{follow}/;

    # defaultSettings.yaml mistakenly had
    #
    # fineTuning:
    #     NamedGroupingBracesBrackets:
    #
    # when it should have been
    #
    # fineTuning:
    #     namedGroupingBracesBrackets:
    #
    # the mistake was mine, so I feel that the following is necessary; if we
    # get to V4, then this will be removed and only namedGroupingBracesBrackets will be supported
    if ( ${ ${ $mainSettings{fineTuning} }{NamedGroupingBracesBrackets} }{name} ) {
        $logger->warn(
            "*fineTuning:NamedGroupingBracesBrackets is ok for now, but in future versions, fineTuning:namedGroupingBracesBrackets will be used"
        );
        $NamedGroupingBracesBracketsRegExp = qr/${${$mainSettings{fineTuning}}{NamedGroupingBracesBrackets}}{name}/;
    }
    if ( ${ ${ $mainSettings{fineTuning} }{NamedGroupingBracesBrackets} }{follow} ) {
        $logger->warn(
            "*fineTuning:NamedGroupingBracesBrackets is ok for now, but in future versions, fineTuning:namedGroupingBracesBrackets will be used"
        );
        $NamedGroupingFollowRegExp = qr/${${$mainSettings{fineTuning}}{NamedGroupingBracesBrackets}}{follow}/;
    }

    # store the regular expression for matching and replacing
    $grouping_braces_regexp = qr/
                  (
                     $NamedGroupingFollowRegExp
                  )
                  (
                   $NamedGroupingBracesBracketsRegExp  # lowercase|uppercase letters, @, *, numbers, forward slash, dots
                  )                                    # $2 name
                  (\h*)                                # $3 h-space
                  (\R*)                                # $4 linebreaks
                  ($optAndMandRegExp)                  # $5 mand|opt arguments (at least one)
                  (\R)?                                # $8 linebreak 
                /sx;

    # something {value} grouping braces with trailing comment
    $grouping_braces_regexpTrailingComment = qr/$grouping_braces_regexp\h*((?:$trailingCommentRegExp\h*)*)?/;

}

sub create_unique_id {
    my $self = shift;

    $groupingBracesCounter++;
    ${$self}{id} = "$tokens{namedGroupingBracesBrackets}$groupingBracesCounter";
    return;
}

sub get_replacement_text {
    my $self = shift;

# the replacement text for a key = {value} needes to accommodate the leading [ OR { OR % OR , OR any combination thereof
    $logger->trace("Custom replacement text routine for ${$self}{name}") if $is_t_switch_active;
    ${$self}{replacementText} = ${$self}{beginningbit} . ${$self}{id};
    delete ${$self}{beginningbit};
}

1;
