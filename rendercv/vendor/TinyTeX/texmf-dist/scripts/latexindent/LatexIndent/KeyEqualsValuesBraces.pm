package LatexIndent::KeyEqualsValuesBraces;

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
use LatexIndent::Switches qw/$is_m_switch_active $is_t_switch_active $is_tt_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use Exporter qw/import/;
our @ISA = "LatexIndent::Command";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK
    = qw/construct_key_equals_values_regexp $key_equals_values_bracesRegExp $key_equals_values_bracesRegExpTrailingComment/;
our $key_equals_values_braces_Counter;
our $key_equals_values_bracesRegExp;
our $key_equals_values_bracesRegExpTrailingComment;

sub construct_key_equals_values_regexp {
    my $self = shift;

    # grab the arguments regexp
    my $optAndMandRegExp = $self->get_arguments_regexp;

    # blank line token
    my $blankLineToken = $tokens{blanklines};

    # read from fine tuning
    my $keyEqualsValuesBracesBrackets = qr/${${$mainSettings{fineTuning}}{keyEqualsValuesBracesBrackets}}{name}/;
    my $keyEqualsValuesBracesBracketsFollow
        = qr/${${$mainSettings{fineTuning}}{keyEqualsValuesBracesBrackets}}{follow}/;

    # store the regular expression for matching and replacing
    $key_equals_values_bracesRegExp = qr/
                  (
                     (?:$keyEqualsValuesBracesBracketsFollow)
                     (?:\h|\R|$blankLineToken|$trailingCommentRegExp)*
                  )                                                     # $1 pre-key bit: could be { OR , OR [                                 
                  (\\)?                                                 # $2 possible backslash
                  (
                   $keyEqualsValuesBracesBrackets?                      # lowercase|uppercase letters, @, *, numbers, forward slash, dots
                  )                                                     # $3 name
                  (
                    (?:\h|\R|$blankLineToken|$trailingCommentRegExp)*
                    =\h*
                    (?:\d*\:?)
                  )                                                     # $4 = symbol
                  (\R*)?                                                # $5 linebreak after =
                  ($optAndMandRegExp)                                   # $6 opt|mand arguments
                  (\R)?                                                 # $9 linebreak at end
                /sx;

    $key_equals_values_bracesRegExpTrailingComment
        = qr/$key_equals_values_bracesRegExp(\h*)((?:$trailingCommentRegExp\h*)*)?/;
}

sub indent_begin {
    my $self = shift;

    # blank line token
    my $blankLineToken = $tokens{blanklines};

    if ( ${$self}{begin} =~ /\R=/s or ${$self}{begin} =~ /$blankLineToken\h*=/s ) {
        $logger->trace("= found on own line in ${$self}{name}, adding indentation") if $is_t_switch_active;
        ${$self}{begin} =~ s/=/${$self}{indentation}=/s;
    }
}

sub check_linebreaks_before_equals {

    # check if -m switch is active
    return unless $is_m_switch_active;

    my $self = shift;

    # linebreaks *infront* of = symbol
    if ( ${$self}{begin} =~ /\R\h*=/s ) {
        if ( defined ${$self}{EqualsStartsOnOwnLine} and ${$self}{EqualsStartsOnOwnLine} == -1 ) {
            $logger->trace("Removing linebreak before = symbol in ${$self}{name} (see EqualsStartsOnOwnLine)")
                if $is_t_switch_active;
            ${$self}{begin} =~ s/(\R|\h)*=/=/s;
        }
    }
    else {
        if ( defined ${$self}{EqualsStartsOnOwnLine} and ${$self}{EqualsStartsOnOwnLine} == 1 ) {
            $logger->trace("Adding a linebreak before = symbol for ${$self}{name} (see EqualsStartsOnOwnLine)")
                if $is_t_switch_active;
            ${$self}{begin} =~ s/=/\n=/s;
        }
        elsif ( defined ${$self}{EqualsStartsOnOwnLine} and ${$self}{EqualsStartsOnOwnLine} == 2 ) {
            $logger->trace(
                "Adding a % linebreak immediately before = symbol for ${$self}{name} (see EqualsStartsOnOwnLine)")
                if $is_t_switch_active;
            ${$self}{begin} =~ s/\h*=/%\n=/s;
        }
    }
    return;
}

sub create_unique_id {
    my $self = shift;

    $key_equals_values_braces_Counter++;
    ${$self}{id} = "$tokens{keyEqualsValuesBracesBrackets}$key_equals_values_braces_Counter";
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
