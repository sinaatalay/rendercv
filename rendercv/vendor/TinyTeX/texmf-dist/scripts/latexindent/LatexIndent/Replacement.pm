package LatexIndent::Replacement;

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
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active $is_rr_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use Exporter qw/import/;
our @ISA       = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/make_replacements/;

sub make_replacements {
    my $self  = shift;
    my %input = @_;
    if ( $is_t_switch_active and !$is_rr_switch_active ) {
        $logger->trace("*Replacement mode *$input{when}* indentation: -r");
    }
    elsif ( $is_t_switch_active and $is_rr_switch_active ) {
        $logger->trace("*Replacement mode, -rr switch is active") if $is_t_switch_active;
    }

    my @replacements = @{ $mainSettings{replacements} };

    foreach (@replacements) {
        next if !( ${$_}{this} or ${$_}{substitution} );

        # default value of "lookForThis" is 1
        ${$_}{lookForThis} = 1 if ( !( defined ${$_}{lookForThis} ) );

        # move on if this one shouldn't be looked for
        next if ( !${$_}{lookForThis} );

        # default value of "when" is before
        ${$_}{when} = "before" if ( !( defined ${$_}{when} ) or $is_rr_switch_active );

        # update to the logging file
        if ( $is_t_switch_active and ( ${$_}{when} eq $input{when} ) ) {
            $logger->trace("-");
            $logger->trace("this: ${$_}{this}")                 if ( ${$_}{this} );
            $logger->trace("that: ${$_}{that}")                 if ( ${$_}{that} );
            $logger->trace("substitution: ${$_}{substitution}") if ( ${$_}{substitution} );
            $logger->trace("when: ${$_}{when}");
        }

        # perform the substitutions
        if ( ${$_}{when} eq $input{when} ) {
            $logger->warn(
                "*You have specified both 'this' and 'substitution'; the 'substitution' field will be ignored")
                if ( ${$_}{this} and ${$_}{substitution} );
            if ( ${$_}{this} ) {

                # *string* replacement
                # *string* replacement
                # *string* replacement
                my $this        = qq{${$_}{this}};
                my $that        = ( defined ${$_}{that} ) ? qq{${$_}{that}} : q();
                my $index_match = index( ${$self}{body}, $this );
                while ( $index_match != -1 ) {
                    substr( ${$self}{body}, $index_match, length($this), $that );
                    $index_match = index( ${$self}{body}, $this );
                }
            }
            else {
                # *regex* replacement
                # *regex* replacement
                # *regex* replacement

# https://stackoverflow.com/questions/12423337/how-to-pass-a-replacing-regex-as-a-command-line-argument-to-a-perl-script
                my $body = ${$self}{body};
                eval("\$body =~ ${$_}{substitution}");
                ${$self}{body} = $body;
            }
        }
    }
}

1;
