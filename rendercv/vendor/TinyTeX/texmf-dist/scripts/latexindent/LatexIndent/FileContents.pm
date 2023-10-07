package LatexIndent::FileContents;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active $is_m_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::Environment qw/$environmentBasicRegExp/;
use LatexIndent::IfElseFi qw/$ifElseFiBasicRegExp/;
use LatexIndent::Special qw/$specialBeginAndBracesBracketsBasicRegExp/;
use LatexIndent::Heading qw/$allHeadingsRegexp/;
use LatexIndent::Verbatim qw/%verbatimStorage/;
use Data::Dumper;
use Exporter qw/import/;
our @EXPORT_OK = qw/find_file_contents_environments_and_preamble/;
our @ISA       = "LatexIndent::Document";                            # class inheritance, Programming Perl, pg 321
our $fileContentsCounter;

sub find_file_contents_environments_and_preamble {
    my $self = shift;

    # store the file contents blocks in an array which, depending on the value
    # of indentPreamble, will be put into the verbatim hash, or otherwise
    # stored as children to be operated upon
    my @fileContentsStorageArray;

    # fileContents environments
    $logger->trace('*Searching for FILE CONTENTS environments (see fileContentsEnvironments)') if $is_t_switch_active;
    $logger->trace( Dumper( \%{ $mainSettings{fileContentsEnvironments} } ) ) if ($is_tt_switch_active);
    while ( my ( $fileContentsEnv, $yesno ) = each %{ $mainSettings{fileContentsEnvironments} } ) {

        if ( !$yesno ) {
            $logger->trace(" *not* looking for $fileContentsEnv as $fileContentsEnv:$yesno");
            next;
        }

        $logger->trace("looking for $fileContentsEnv environments") if $is_t_switch_active;

        # the trailing * needs some care
        if ( $fileContentsEnv =~ m/\*$/ ) {
            $fileContentsEnv =~ s/\*$//;
            $fileContentsEnv .= '\*';
        }

        my $fileContentsRegExp = qr/
                        (
                        \\begin\{
                                ($fileContentsEnv) # environment name captured into $2
                               \}                  # begin statement captured into $1
                        )
                        (
                            .*?                    # non-greedy match (body) into $3
                        )                            
                        (
                        \\end\{\2\}                # end statement captured into $4
                        \h*                        # possible horizontal spaces
                        )                    
                        (\R)?                      # possibly followed by a line break
                    /sx;

        while ( ${$self}{body} =~ m/$fileContentsRegExp/sx ) {

            # create a new Environment object
            my $fileContentsBlock = LatexIndent::FileContents->new(
                begin           => $1,
                body            => $3,
                end             => $4,
                name            => $2,
                linebreaksAtEnd => {
                    begin => 0,
                    body  => 0,
                    end   => $5 ? 1 : 0,
                },
                modifyLineBreaksYamlName => "filecontents",
            );

            # give unique id
            $fileContentsBlock->create_unique_id;

            # text wrapping can make the ID split across lines
            ${$fileContentsBlock}{idRegExp} = ${$fileContentsBlock}{id};

            if ( $is_m_switch_active and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge} ne "overflow" ) {
                my $IDwithLineBreaks = join( "\\R?\\h*", split( //, ${$fileContentsBlock}{id} ) );
                ${$fileContentsBlock}{idRegExp} = qr/$IDwithLineBreaks/s;
            }

            # the replacement text can be just the ID, but the ID might have a line break at the end of it
            $fileContentsBlock->get_replacement_text;

            # count body line breaks
            $fileContentsBlock->count_body_line_breaks;

            # the above regexp, when used below, will remove the trailing linebreak in ${$self}{linebreaksAtEnd}{end}
            # so we compensate for it here
            $fileContentsBlock->adjust_replacement_text_line_breaks_at_end;

            # store the fileContentsBlock, and determine location afterwards
            push( @fileContentsStorageArray, $fileContentsBlock );

            # log file output
            $logger->trace("FILECONTENTS environment found: ${$fileContentsBlock}{name}") if $is_t_switch_active;

            # remove the environment block, and replace with unique ID
            ${$self}{body} =~ s/$fileContentsRegExp/${$fileContentsBlock}{replacementText}/sx;

            $logger->trace("replaced with ID: ${$fileContentsBlock}{id}") if $is_tt_switch_active;
        }
    }

    # determine if body of document contains \begin{document} -- if it does, then assume
    # that the body has a preamble
    my $preambleRegExp = qr/
                        (.*?)
                        (\R*\h*)?            # linebreaks at end of body into $2
                        \\begin\{document\}
                /sx;
    my $preamble = q();

    my $needToStorePreamble = 0;

    # try and find the preamble
    if ( ${$self}{body} =~ m/$preambleRegExp/sx and ${ $mainSettings{lookForPreamble} }{ ${$self}{fileExtension} } ) {

        $logger->trace(
            "\\begin{document} found in body (after searching for filecontents)-- assuming that a preamble exists")
            if $is_t_switch_active;

        # create a preamble object
        $preamble = LatexIndent::Preamble->new(
            begin           => q(),
            body            => $1,
            end             => q(),
            name            => "preamble",
            linebreaksAtEnd => {
                begin => 0,
                body  => $2 ? 1 : 0,
                end   => 0,
            },
            afterbit                 => ( $2 ? $2 : q() ) . "\\begin{document}",
            modifyLineBreaksYamlName => "preamble",
        );

        # give unique id
        $preamble->create_unique_id;

        # text wrapping can make the ID split across lines
        ${$preamble}{idRegExp} = ${$preamble}{id};

        if ( $is_m_switch_active and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge} ne "overflow" ) {
            my $IDwithLineBreaks = join( "\\R?\\h*", split( //, ${$preamble}{id} ) );
            ${$preamble}{idRegExp} = qr/$IDwithLineBreaks/s;
        }

        # get the replacement_text
        $preamble->get_replacement_text;

        # log file output
        $logger->trace("preamble found: preamble") if $is_t_switch_active;

        # remove the environment block, and replace with unique ID
        ${$self}{body} =~ s/$preambleRegExp/${$preamble}{replacementText}/sx;

        $logger->trace("replaced with ID: ${$preamble}{replacementText}") if $is_tt_switch_active;

        # indentPreamble set to 1
        if ( $mainSettings{indentPreamble} ) {
            $logger->trace("storing ${$preamble}{id} for indentation (see indentPreamble)") if $is_tt_switch_active;
            $needToStorePreamble = 1;
        }
        else {
            # indentPreamble set to 0
            $logger->trace(
                "NOT storing ${$preamble}{id} for indentation -- will store as VERBATIM object (because indentPreamble:0)"
            ) if $is_t_switch_active;
            $preamble->unprotect_blank_lines
                if ( $is_m_switch_active and ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} );
            $verbatimStorage{ ${$preamble}{id} } = $preamble;
        }
    }
    else {
        ${$self}{preamblePresent} = 0;
    }

    # loop through the fileContents array, check if it's in the preamble
    foreach (@fileContentsStorageArray) {
        my $indentThisChild = 0;

        # verbatim children go in special hash
        if ( $preamble ne '' and ${$preamble}{body} =~ m/${$_}{id}/ ) {
            $logger->trace("filecontents (${$_}{id}) is within preamble") if $is_t_switch_active;

            # indentPreamble set to 1
            if ( $mainSettings{indentPreamble} ) {
                $logger->trace("storing ${$_}{id} for indentation (indentPreamble is 1)") if $is_t_switch_active;
                $indentThisChild = 1;
            }
            else {
                # indentPreamble set to 0
                $logger->trace("Storing ${$_}{id} as a VERBATIM object (indentPreamble is 0)") if $is_t_switch_active;
                $verbatimStorage{ ${$_}{id} } = $_;
            }
        }
        else {
            $logger->trace("storing ${$_}{id} for indentation (${$_}{name} found outside of preamble)")
                if $is_t_switch_active;
            $indentThisChild = 1;
        }

        # store the child, if necessary
        if ($indentThisChild) {
            $_->remove_leading_space;
            $_->yaml_get_indentation_settings_for_this_object;
            $_->tasks_particular_to_each_object;
            push( @{ ${$self}{children} }, $_ );

            # possible decoration in log file
            $logger->trace( ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace} )
                if ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace};
        }
    }

    if ($needToStorePreamble) {
        $preamble->dodge_double_backslash;
        $preamble->remove_leading_space;

        # text wrapping
        $preamble->text_wrap()
            if ( $is_m_switch_active and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{columns} != 0 );
        $preamble->find_commands_or_key_equals_values_braces if ( $mainSettings{preambleCommandsBeforeEnvironments} );
        $preamble->tasks_particular_to_each_object;
        push( @{ ${$self}{children} }, $preamble );
    }
    return;
}

sub create_unique_id {
    my $self = shift;

    $fileContentsCounter++;
    ${$self}{id} = "$tokens{filecontents}$fileContentsCounter$tokens{endOfToken}";
    return;
}

sub tasks_particular_to_each_object {
    my $self = shift;

    # search for environments
    $self->find_environments if ${$self}{body} =~ m/$environmentBasicRegExp/s;

    # search for ifElseFi blocks
    $self->find_ifelsefi if ${$self}{body} =~ m/$ifElseFiBasicRegExp/s;

    # search for headings (part, chapter, section, setc)
    $self->find_heading if ${$self}{body} =~ m/$allHeadingsRegexp/s;

    # search for commands and special code blocks
    $self->find_commands_or_key_equals_values_braces_and_special
        if ${$self}{body} =~ m/$specialBeginAndBracesBracketsBasicRegExp/s;
}

1;
