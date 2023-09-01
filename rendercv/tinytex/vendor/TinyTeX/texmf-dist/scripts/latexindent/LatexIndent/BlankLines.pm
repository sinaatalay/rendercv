package LatexIndent::BlankLines;

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
use LatexIndent::Switches qw/$is_m_switch_active $is_t_switch_active $is_tt_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use Exporter qw/import/;
our @EXPORT_OK = qw/protect_blank_lines unprotect_blank_lines condense_blank_lines/;

sub protect_blank_lines {
    my $self = shift;

    unless ( ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} ) {
        $logger->trace("*Blank lines will not be protected (preserveBlankLines=0)") if $is_t_switch_active;
        return;
    }

    $logger->trace("*Protecting blank lines (see preserveBlankLines)") if $is_t_switch_active;
    ${$self}{body} =~ s/^(\h*)?\R/$tokens{blanklines}\n/mg;
    return;
}

sub condense_blank_lines {

    my $self = shift;

    $logger->trace("*condense blank lines routine") if $is_t_switch_active;

    # if preserveBlankLines is set to 0, then the blank-line-token will not be present
    # in the document -- we change that here
    if ( ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} == 0 ) {

        # turn the switch on
        ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} = 1;

        # log file information
        $logger->trace("Updating body to include blank line token, this requires preserveBlankLines = 1")
            if ($is_tt_switch_active);
        $logger->trace("(any blanklines that could have been removed, would have done so by this point)")
            if ($is_tt_switch_active);

        # make the call
        $self->protect_blank_lines;
        $logger->trace("body now looks like:\n${$self}{body}") if ($is_tt_switch_active);
    }

    # grab the value from the settings
    my $condenseMultipleBlankLinesInto = ${ $mainSettings{modifyLineBreaks} }{condenseMultipleBlankLinesInto};

    # grab the blank-line-token
    my $blankLineToken = $tokens{blanklines};

    # condense!
    $logger->trace(
        "Condensing multiple blank lines into $condenseMultipleBlankLinesInto (see condenseMultipleBlankLinesInto)")
        if $is_t_switch_active;
    my $replacementToken = $blankLineToken;
    for ( my $i = 1; $i < $condenseMultipleBlankLinesInto; $i++ ) {
        $replacementToken .= "\n$blankLineToken";
    }

    $logger->trace("blank line replacement token: $replacementToken") if ($is_tt_switch_active);
    ${$self}{body} =~ s/($blankLineToken\h*\R*\h*){1,}$blankLineToken/$replacementToken/mgs;
    $logger->trace("body now looks like:\n${$self}{body}") if ($is_tt_switch_active);
    return;
}

sub unprotect_blank_lines {
    my $self = shift;

    # remove any empty lines that might have been added by the text_wrap routine; see, for example,
    #       test-cases/maxLineChars/multi-object-all.tex -l=multi-object2.yaml -m
    ${$self}{body} =~ s/^\h*\R//mg;

    $logger->trace("Unprotecting blank lines (see preserveBlankLines)") if $is_t_switch_active;
    my $blankLineToken = $tokens{blanklines};

    if ( $is_m_switch_active and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge} ne "overflow" ) {
        $blankLineToken = join( "(?:\\h|\\R)*", split( //, $tokens{blanklines} ) );
    }

    # loop through the body, looking for the blank line token
    while ( ${$self}{body} =~ m/$blankLineToken/s ) {

        # when the blank line token occupies the whole line
        ${$self}{body} =~ s/^\h*$blankLineToken$//mg;

        # when there's stuff *after* the blank line token
        ${$self}{body} =~ s/(^\h*)$blankLineToken/"\n".$1/meg;

        # when there is stuff before and after the blank line token
        ${$self}{body} =~ s/^(.*?)$blankLineToken\h*(.*?)\h*$/$1."\n".($2?"\n".$2:$2)/meg;

        # when there is only stuff *after* the blank line token
        ${$self}{body} =~ s/^$blankLineToken\h*(.*?)$/$1."\n"/emg;
    }
    $logger->trace("Finished unprotecting lines (see preserveBlankLines)") if $is_t_switch_active;
    $logger->trace("body now looks like:")                                 if ($is_tt_switch_active);
    $logger->trace("${$self}{body}")                                       if ($is_tt_switch_active);
}

1;
