package LatexIndent::HorizontalWhiteSpace;

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
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use Exporter qw/import/;
our @EXPORT_OK = qw/remove_trailing_whitespace remove_leading_space/;

sub remove_trailing_whitespace {
    my $self  = shift;
    my %input = @_;

    $logger->trace("*Horizontal space removal routine") if $is_t_switch_active;

    # removeTrailingWhitespace can be either a hash or a scalar, but if
    # it's a scalar, we need to fix it
    if ( ref( $mainSettings{removeTrailingWhitespace} ) ne 'HASH' ) {
        $logger->trace("removeTrailingWhitespace specified as scalar, will update it to be a hash")
            if $is_t_switch_active;

        # grab the value
        my $removeTWS = $mainSettings{removeTrailingWhitespace};

        # delete the scalar
        delete $mainSettings{removeTrailingWhitespace};

        # redefine it as a hash
        ${ $mainSettings{removeTrailingWhitespace} }{beforeProcessing} = $removeTWS;
        ${ $mainSettings{removeTrailingWhitespace} }{afterProcessing}  = $removeTWS;
        $logger->trace("removeTrailingWhitespace: beforeProcessing is now $removeTWS") if $is_t_switch_active;
        $logger->trace("removeTrailingWhitespace: afterProcessing is now $removeTWS")  if $is_t_switch_active;
    }

    # this method can be called before the indentation, and after, depending upon the input
    if ( $input{when} eq "before" ) {
        return unless ( ${ $mainSettings{removeTrailingWhitespace} }{beforeProcessing} );
        $logger->trace(
            "Removing trailing white space *before* the document is processed (see removeTrailingWhitespace: beforeProcessing)"
        ) if $is_t_switch_active;
    }
    elsif ( $input{when} eq "after" ) {
        return unless ( ${ $mainSettings{removeTrailingWhitespace} }{afterProcessing} );
        $logger->trace(
            "Removing trailing white space *after* the document is processed (see removeTrailingWhitespace: afterProcessing)"
        ) if $is_t_switch_active;
    }
    else {
        return;
    }

    ${$self}{body} =~ s/
                       \h+  # followed by possible horizontal space
                       $    # up to the end of a line
                       //xsmg;

}

sub remove_leading_space {
    my $self = shift;
    $logger->trace("*Removing leading space from ${$self}{name} (verbatim/noindentblock already accounted for)")
        if $is_t_switch_active;
    ${$self}{body} =~ s/
                        (   
                            ^           # beginning of the line
                            \h*         # with 0 or more horizontal spaces
                        )?              # possibly
                        //mxg;
    return;
}

1;
