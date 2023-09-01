package LatexIndent::Tokens;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active/;
use LatexIndent::LogFile qw/$logger/;
our @EXPORT_OK = qw/token_check %tokens/;

# each of the tokens begins the same way -- this is exploited during the hidden Children routine
my $beginningToken  = "LTXIN-TK-";
my $ifelsefiSpecial = "!-!";

# the %tokens hash is passed around many modules
our %tokens = (

    # user-facing naming convention
    environments                  => $beginningToken . "ENVIRONMENT",
    commands                      => $beginningToken . "COMMAND",
    optionalArguments             => $beginningToken . "OPTIONAL-ARGUMENT",
    mandatoryArguments            => $beginningToken . "MANDATORY-ARGUMENT",
    ifElseFi                      => $ifelsefiSpecial . $beginningToken . "IFELSEFI",
    else                          => $beginningToken . "ELSE",
    items                         => $beginningToken . "ITEMS",
    keyEqualsValuesBracesBrackets => $beginningToken . "KEY-VALUE-BRACES",
    namedGroupingBracesBrackets   => $beginningToken . "GROUPING-BRACES",
    UnNamedGroupingBracesBrackets => $beginningToken . "UN-NAMED-GROUPING-BRACES",
    specialBeginEnd               => $beginningToken . "SPECIAL",
    afterHeading                  => $beginningToken . "HEADING",
    filecontents                  => $beginningToken . "FILECONTENTS",

    # internal-facing naming convention
    trailingComment => "latexindenttrailingcomment",
    ifelsefiSpecial => $ifelsefiSpecial,
    blanklines      => $beginningToken . "blank-line",
    arguments       => $beginningToken . "ARGUMENTS",
    roundBracket    => $beginningToken . "ROUND-BRACKET",
    verbatim        => $beginningToken . "VERBATIM",
    verbatimInline  => $beginningToken . "VERBATIM-inline",
    preamble        => $beginningToken . "preamble",
    beginOfToken    => $beginningToken,
    doubleBackSlash => $beginningToken . "DOUBLEBACKSLASH",
    alignmentBlock  => $beginningToken . "ALIGNMENTBLOCK",
    paragraph       => $beginningToken . "PARA",
    sentence        => $beginningToken . "SENTENCE",
    endOfToken      => "-END",
);

sub token_check {
    my $self = shift;

    $logger->trace("*Token check") if $is_t_switch_active;

    # we use tokens for trailing comments, environments, commands, etc, so check that they're not in the body
    foreach ( keys %tokens ) {
        while ( ${$self}{body} =~ m/$tokens{$_}/si ) {
            $logger->trace("Found $tokens{$_} within body, updating replacement token to $tokens{$_}-LIN")
                if ($is_t_switch_active);
            $tokens{$_} .= "-LIN";
        }
    }
}

1;
