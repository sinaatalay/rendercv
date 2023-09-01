package LatexIndent::DoubleBackSlash;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active/;
use LatexIndent::Tokens qw/%tokens/;
use Exporter qw/import/;
our @EXPORT_OK = qw/dodge_double_backslash un_dodge_double_backslash/;

# some code can contain, e.g
#       cycle list={blue,mark=none\\},
# see test-cases/texexchange/29293-christian-feuersanger.tex
#
# This is problematic, as the argument regexp won't count the right } because it has a
# backslash immediately infront of it!
sub dodge_double_backslash {
    my $self = shift;

    ${$self}{body} =~ s/(?:\\\\(\{|\}|\]))/$tokens{doubleBackSlash}$1/sg;
    return;
}

# this routine replaces the token with the \\\\
sub un_dodge_double_backslash {
    my $self = shift;

    ${$self}{body} =~ s/$tokens{doubleBackSlash}/\\\\/sg;
    return;
}

1;
