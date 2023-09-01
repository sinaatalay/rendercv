package LatexIndent::Preamble;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_m_switch_active/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::Environment qw/$environmentBasicRegExp/;
use LatexIndent::IfElseFi qw/$ifElseFiBasicRegExp/;
use LatexIndent::Special qw/$specialBeginBasicRegExp/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our $preambleCounter;

sub create_unique_id {
    my $self = shift;

    $preambleCounter++;
    ${$self}{id} = "$tokens{preamble}$preambleCounter$tokens{endOfToken}";
    return;
}

sub get_replacement_text {
    my $self = shift;

    # the replacement text for preamble needs to put the \\begin{document} back in
    $logger->trace("Custom replacement text routine for preamble ${$self}{name}") if $is_t_switch_active;
    ${$self}{replacementText} = ${$self}{id} . ${$self}{afterbit};
    delete ${$self}{afterbit};
}

sub indent {

    # preamble doesn't receive any additional indentation
    return;
}

sub tasks_particular_to_each_object {
    my $self = shift;

    # search for environments
    $self->find_environments if ${$self}{body} =~ m/$environmentBasicRegExp/;

    # search for ifElseFi blocks
    $self->find_ifelsefi if ${$self}{body} =~ m/$ifElseFiBasicRegExp/s;

    if ( ${ $mainSettings{specialBeginEnd} }{specialBeforeCommand} ) {

        # search for special begin/end
        $self->find_special if ${$self}{body} =~ m/$specialBeginBasicRegExp/s;

        # search for commands with arguments
        $self->find_commands_or_key_equals_values_braces if ( !$mainSettings{preambleCommandsBeforeEnvironments} );
    }
    else {
        # search for commands with arguments
        $self->find_commands_or_key_equals_values_braces if ( !$mainSettings{preambleCommandsBeforeEnvironments} );

        # search for special begin/end
        $self->find_special if ${$self}{body} =~ m/$specialBeginBasicRegExp/s;
    }
}

1;
