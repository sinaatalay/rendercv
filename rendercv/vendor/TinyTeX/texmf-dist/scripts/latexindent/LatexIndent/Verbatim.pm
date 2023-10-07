package LatexIndent::Verbatim;

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
use Data::Dumper;
use Exporter qw/import/;
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active $is_m_switch_active/;
use LatexIndent::LogFile qw/$logger/;
our @EXPORT_OK
    = qw/put_verbatim_back_in find_verbatim_environments find_noindent_block find_verbatim_commands find_verbatim_special verbatim_common_tasks %verbatimStorage/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our $verbatimCounter;
our %verbatimStorage;

sub find_noindent_block {
    my $self = shift;

    # noindent block
    $logger->trace('*Searching for NOINDENTBLOCK (see noIndentBlock)') if $is_t_switch_active;
    $logger->trace( Dumper( \%{ $mainSettings{noIndentBlock} } ) ) if ($is_tt_switch_active);
    while ( my ( $noIndentBlock, $yesno ) = each %{ $mainSettings{noIndentBlock} } ) {

        # integrity check on the field for noIndentBlock
        if ( ref($yesno) eq "HASH" ) {
            if ( defined ${$yesno}{lookForThis} and !${$yesno}{lookForThis} ) {
                $logger->trace(" *not* looking for $noIndentBlock as lookForThis: 0") if $is_t_switch_active;
                next;
            }
            if ( not defined ${$yesno}{name} ) {
                if ( not defined ${$yesno}{begin} ) {
                    $logger->trace(" *not* looking for $noIndentBlock as $noIndentBlock:begin not specified")
                        if $is_t_switch_active;
                    next;
                }
                elsif ( not defined ${$yesno}{end} ) {
                    $logger->trace(" *not* looking for $noIndentBlock as $noIndentBlock:end not specified")
                        if $is_t_switch_active;
                    next;
                }
            }
            elsif ( defined ${$yesno}{begin} or defined ${$yesno}{end} ) {
                $logger->trace(
                    " *not* looking for $noIndentBlock as $noIndentBlock:name specified with begin and/or end")
                    if $is_t_switch_active;
                next;
            }
        }
        elsif ( ref($yesno) ne "HASH" and !$yesno ) {
            $logger->trace(" *not* looking for $noIndentBlock as $noIndentBlock:$yesno") if $is_t_switch_active;
            next;
        }

        # if we've made it this far, then we're good to go
        my $noIndentRegExp;
        my $noIndentBlockObj;

        if ( ref($yesno) eq "HASH" ) {

            # default value of begin and end
            if ( defined ${$yesno}{name} and not defined ${$yesno}{begin} and not defined ${$yesno}{end} ) {
                ${$yesno}{begin} = "\\\\begin\\{(${$yesno}{name})\\}";
                ${$yesno}{end}   = "\\\\end\\{\\2\\}";
                $logger->trace("looking for regex based $noIndentBlock, name: ${$yesno}{name}") if $is_t_switch_active;
                $logger->trace("begin not specified for $noIndentBlock, setting default ${$yesno}{begin}")
                    if $is_t_switch_active;
                $logger->trace("end not specified for $noIndentBlock, setting default ${$yesno}{end}")
                    if $is_t_switch_active;
            }

            # default value of body
            if ( not defined ${$yesno}{body} ) {
                $logger->trace("looking for regex based $noIndentBlock, begin: ${$yesno}{begin}, end: ${$yesno}{end}")
                    if $is_t_switch_active;
                $logger->trace("body not specified for $noIndentBlock, setting default .*?") if $is_t_switch_active;
                ${$yesno}{body} = qr/.*?/sx;
            }
            else {
                $logger->trace("looking for regex based $noIndentBlock") if $is_t_switch_active;
                $logger->trace("begin: ${$yesno}{begin}")                if $is_t_switch_active;
                $logger->trace("body: ${$yesno}{body}")                  if $is_t_switch_active;
                $logger->trace("end: ${$yesno}{end}")                    if $is_t_switch_active;
            }

            $noIndentRegExp = qr/
                            (${$yesno}{begin})
                            (${$yesno}{body})
                            (${$yesno}{end})
                        /sx;
        }
        else {
            $logger->trace("looking for $noIndentBlock:$yesno noIndentBlock") if $is_t_switch_active;

            ( my $noIndentBlockSpec = $noIndentBlock ) =~ s/\*/\\*/sg;
            $noIndentRegExp = qr/
                            (
                                (?!<\\)
                                %
                                (?:\h|(?!<\\)%)*             # possible horizontal spaces
                                \\begin\{
                                        ($noIndentBlockSpec) # environment name captured into $2
                                       \}                    # % \begin{noindentblock} statement
                            )                                # begin statement captured into $1
                            (
                                .*?                          # non-greedy match (body) into $3
                            )
                            (
                                (?!<\\)
                                %                            # %
                                (?:\h|(?!<\\)%)*             # possible horizontal spaces
                                \\end\{\2\}                  # % \end{noindentblock} statement
                            )                                # end statement captured into $4
                        /sx;
        }
        while ( ${$self}{body} =~ m/$noIndentRegExp/sx ) {

            # create a new Verbatim object
            if ( ref($yesno) eq "HASH" and not defined ${$yesno}{name} ) {

                # user defined begin and end statements
                $noIndentBlockObj = LatexIndent::Verbatim->new(
                    begin                    => $1,
                    body                     => $2,
                    end                      => $3,
                    name                     => $noIndentBlock,
                    type                     => "noindentblock",
                    modifyLineBreaksYamlName => "verbatim",
                );
            }
            else {
                # specified by name (entry:1 or entry: name: regex)
                $noIndentBlockObj = LatexIndent::Verbatim->new(
                    begin                    => $1,
                    body                     => $3,
                    end                      => $4,
                    name                     => $2,
                    type                     => "noindentblock",
                    modifyLineBreaksYamlName => "verbatim",
                );
            }

            # give unique id
            $noIndentBlockObj->create_unique_id;

            # verbatim children go in special hash
            $verbatimStorage{ ${$noIndentBlockObj}{id} } = $noIndentBlockObj;

            # log file output
            $logger->trace("NOINDENTBLOCK found: ${$noIndentBlockObj}{name}") if $is_t_switch_active;

            # remove the environment block, and replace with unique ID
            ${$self}{body} =~ s/$noIndentRegExp/${$noIndentBlockObj}{id}/sx;

            $logger->trace("replaced with ID: ${$noIndentBlockObj}{id}") if $is_t_switch_active;

            # possible decoration in log file
            $logger->trace( ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace} )
                if ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace};
        }
    }
    return;
}

sub find_verbatim_environments {
    my $self = shift;

    # verbatim environments
    $logger->trace('*Searching for VERBATIM environments (see verbatimEnvironments)') if $is_t_switch_active;
    $logger->trace( Dumper( \%{ $mainSettings{verbatimEnvironments} } ) ) if ($is_tt_switch_active);
    while ( my ( $verbEnv, $yesno ) = each %{ $mainSettings{verbatimEnvironments} } ) {
        my $verbEnvSpec;

        # integrity check on the field for noIndentBlock
        if ( ref($yesno) eq "HASH" ) {
            if ( defined ${$yesno}{lookForThis} and !${$yesno}{lookForThis} ) {
                $logger->trace(" *not* looking for $verbEnv as lookForThis: 0") if $is_t_switch_active;
                next;
            }
            elsif ( not defined ${$yesno}{name} ) {
                $logger->trace(" *not* looking for $verbEnv as $verbEnv:name not specified") if $is_t_switch_active;
                next;
            }
            else {
                $logger->trace("looking for VERBATIM-environments $verbEnv, name: ${$yesno}{name}")
                    if $is_t_switch_active;
                $verbEnvSpec = ${$yesno}{name};
            }
        }
        elsif ( ref($yesno) ne "HASH" and $yesno ) {
            $logger->trace("looking for $verbEnv:$yesno environments") if $is_t_switch_active;
            ( $verbEnvSpec = $verbEnv ) =~ s/\*/\\*/sg;
        }
        else {
            $logger->trace(" *not* looking for $verbEnv as $verbEnv:$yesno") if $is_t_switch_active;
            next;
        }

        # if we've made it this far, then we're good to go
        my $verbatimRegExp = qr/
                        (
                        \\begin\{
                                ($verbEnvSpec) # environment name captured into $2
                               \}              # \begin{<something>} statement captured into $1
                        )
                        (
                            .*?                # non-greedy match (body) into $3
                        )                      # any character, but not \\begin
                        (
                        \\end\{\2\}            # \end{<something>} statement captured into $4
                        )
                        (\h*)?                 # possibly followed by horizontal space
                        (\R)?                  # possibly followed by a line break
                    /sx;

        while ( ${$self}{body} =~ m/$verbatimRegExp/sx ) {

            # create a new Verbatim object
            my $verbatimBlock = LatexIndent::Verbatim->new(
                begin                    => $1,
                body                     => $3,
                end                      => $4,
                name                     => $2,
                type                     => "environment",
                modifyLineBreaksYamlName => "verbatim",
                linebreaksAtEnd          => { end => $6 ? 1 : 0, },
                horizontalTrailingSpace  => $5 ? $5 : q(),
                aliases                  => {

                    # begin statements
                    BeginStartsOnOwnLine => "VerbatimBeginStartsOnOwnLine",

                    # after end statements
                    EndFinishesWithLineBreak => "VerbatimEndFinishesWithLineBreak",
                },
            );

            # there are common tasks for each of the verbatim objects
            $verbatimBlock->verbatim_common_tasks;

            # verbatim children go in special hash
            $verbatimStorage{ ${$verbatimBlock}{id} } = $verbatimBlock;

            # log file output
            $logger->trace("*VERBATIM environment found: ${$verbatimBlock}{name}") if $is_t_switch_active;

            # remove the environment block, and replace with unique ID
            ${$self}{body} =~ s/$verbatimRegExp/${$verbatimBlock}{replacementText}/sx;

            $logger->trace("replaced with ID: ${$verbatimBlock}{id}") if $is_t_switch_active;

            # possible decoration in log file
            $logger->trace( ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace} )
                if ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace};
        }
    }
    return;
}

sub find_verbatim_commands {
    my $self = shift;

    # verbatim commands need to be treated separately to verbatim environments;
    # note that, for example, we could quite reasonably have \lstinline!%!, which
    # would need to be found *before* trailing comments have been removed. Similarly,
    # verbatim commands need to be put back in *after* trailing comments have been put
    # back in
    $logger->trace('*Searching for VERBATIM commands (see verbatimCommands)') if $is_t_switch_active;
    $logger->trace( Dumper( \%{ $mainSettings{verbatimCommands} } ) ) if ($is_tt_switch_active);
    while ( my ( $verbCommand, $yesno ) = each %{ $mainSettings{verbatimCommands} } ) {
        my $verbCommandSpec;

        # integrity check on the field for noIndentBlock
        if ( ref($yesno) eq "HASH" ) {
            if ( defined ${$yesno}{lookForThis} and !${$yesno}{lookForThis} ) {
                $logger->trace(" *not* looking for $verbCommand as lookForThis: 0") if $is_t_switch_active;
                next;
            }
            elsif ( not defined ${$yesno}{name} ) {
                $logger->trace(" *not* looking for $verbCommand as $verbCommand:name not specified")
                    if $is_t_switch_active;
                next;
            }
            else {
                $logger->trace("looking for regex based VERBATIM-commands $verbCommand, name: ${$yesno}{name}")
                    if $is_t_switch_active;
                $verbCommandSpec = ${$yesno}{name};
            }
        }
        elsif ( ref($yesno) ne "HASH" and $yesno ) {
            $logger->trace("looking for $verbCommand:$yesno Commands") if $is_t_switch_active;
            $verbCommandSpec = $verbCommand;
        }
        else {
            $logger->trace("*not* looking for $verbCommand as $verbCommand:$yesno") if $is_t_switch_active;
            next;
        }

        # if we've made it this far, then we're good to go
        my $verbatimRegExp = qr/
                        (
                            \\($verbCommandSpec) # name of command into $2
                            \h*
                        )
                        (
                            \[
                                (?:
                                    (?!
                                        (?:(?<!\\)\[) 
                                    ).
                                )*?     # not including [, but \[ ok
                            (?<!\\)     # not immediately pre-ceeded by \
                            \]          # [optional arguments]
                            \h*
                        )?              # opt arg into $3
                        (
                            .
                        )               # delimiter into $4
                        (
                            .*?
                        )               # body into $5
                        \4
                        (\h*)?          # possibly followed by horizontal space
                        (\R)?           # possibly followed by a line break 
                    /mx;

        while ( ${$self}{body} =~ m/$verbatimRegExp/ ) {

            # create a new Verbatim object
            my $verbatimCommand = LatexIndent::Verbatim->new(
                begin                    => $1 . ( $3 ? $3 : q() ) . $4,
                body                     => $5,
                end                      => $4,
                name                     => $2,
                type                     => "command",
                modifyLineBreaksYamlName => "verbatim",
                linebreaksAtEnd          => { end => $7 ? 1 : 0, },
                horizontalTrailingSpace  => $6 ? $6 : q(),
                aliases                  => {

                    # begin statements
                    BeginStartsOnOwnLine => "VerbatimBeginStartsOnOwnLine",

                    # after end statements
                    EndFinishesWithLineBreak => "VerbatimEndFinishesWithLineBreak",
                },
                optArg => $3 ? $3 : q(),
            );

            # there are common tasks for each of the verbatim objects
            $verbatimCommand->verbatim_common_tasks;

            # output, if desired
            $logger->trace( Dumper($verbatimCommand), 'ttrace' ) if ($is_tt_switch_active);

            # check for nested verbatim commands
            if ( ${$verbatimCommand}{body} =~ m/($tokens{verbatimInline}\d+$tokens{endOfToken})/s ) {
                my $verbatimNestedID = $1;
                my $verbatimBody
                    = ${ $verbatimStorage{$verbatimNestedID} }{begin}
                    . ${ $verbatimStorage{$verbatimNestedID} }{body}
                    . ${ $verbatimStorage{$verbatimNestedID} }{end};
                ${$verbatimCommand}{body} =~ s/$verbatimNestedID/$verbatimBody/s;
                delete $verbatimStorage{$verbatimNestedID};
            }

            # verbatim children go in special hash
            $verbatimStorage{ ${$verbatimCommand}{id} } = $verbatimCommand;

            # log file output
            $logger->trace("*VERBATIM command found: ${$verbatimCommand}{name}") if $is_t_switch_active;

            # remove the environment block, and replace with unique ID
            ${$self}{body} =~ s/$verbatimRegExp/${$verbatimCommand}{replacementText}/sx;

            $logger->trace("replaced with ID: ${$verbatimCommand}{id}") if $is_t_switch_active;

            # possible decoration in log file
            $logger->trace( ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace} )
                if ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace};
        }
    }
    return;

}

sub find_verbatim_special {
    my $self = shift;

    # loop through specialBeginEnd
    while ( my ( $specialName, $BeginEnd ) = each %{ $mainSettings{specialBeginEnd} } ) {

        # only classify special Verbatim if lookForThis is 'verbatim'
        if (    ( ref($BeginEnd) eq "HASH" )
            and ${$BeginEnd}{lookForThis} =~ m/v/s
            and ${$BeginEnd}{lookForThis} eq 'verbatim' )
        {
            $logger->trace('*Searching for VERBATIM special (see specialBeginEnd)') if $is_t_switch_active;

            my $verbatimRegExp = qr/
                            (
                                ${$BeginEnd}{begin}
                            )
                            (
                                .*?
                            )                    
                            (
                                ${$BeginEnd}{end}
                            )                    
                            (\h*)?                    # possibly followed by horizontal space
                            (\R)?                     # possibly followed by a line break 
                        /sx;

            while ( ${$self}{body} =~ m/$verbatimRegExp/sx ) {

                # create a new Verbatim object
                my $verbatimBlock = LatexIndent::Verbatim->new(
                    begin                    => $1,
                    body                     => $2,
                    end                      => $3,
                    name                     => $specialName,
                    modifyLineBreaksYamlName => "specialBeginEnd",
                    linebreaksAtEnd          => { end => $5 ? 1 : 0, },
                    horizontalTrailingSpace  => $4 ? $4 : q(),
                    type                     => "special",
                    aliases                  => {

                        # begin statements
                        BeginStartsOnOwnLine => "SpecialBeginStartsOnOwnLine",

                        # after end statements
                        EndFinishesWithLineBreak => "SpecialEndFinishesWithLineBreak",
                    },
                );

                # there are common tasks for each of the verbatim objects
                $verbatimBlock->verbatim_common_tasks;

                # verbatim children go in special hash
                $verbatimStorage{ ${$verbatimBlock}{id} } = $verbatimBlock;

                # log file output
                $logger->trace("*VERBATIM special found: $specialName") if $is_t_switch_active;

                # remove the special block, and replace with unique ID
                ${$self}{body} =~ s/$verbatimRegExp/${$verbatimBlock}{replacementText}/sx;

                $logger->trace("replaced with ID: ${$verbatimBlock}{id}") if $is_t_switch_active;

                # possible decoration in log file
                $logger->trace( ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace} )
                    if ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace};
            }
        }
    }
}

sub put_verbatim_back_in {
    my $self  = shift;
    my %input = @_;

    my $verbatimCount = 0;
    my $toMatch       = q();
    if ( $input{match} eq "everything-except-commands" ) {
        $toMatch = "noindentblockenvironmentspeciallinesprotect";
    }
    else {
        $toMatch = "command";
    }

    # count the number of non-command verbatim objects
    while ( my ( $key, $child ) = each %verbatimStorage ) {
        ${$child}{type} = "environment" if !( defined ${$child}{type} );
        $verbatimCount++ if ( $toMatch =~ m/${$child}{type}/ );
    }

    return unless ( $verbatimCount > 0 );

    # search for environments/commands
    $logger->trace('*Putting verbatim back in') if $is_t_switch_active;
    $logger->trace('pre-processed body:')       if $is_tt_switch_active;
    $logger->trace( ${$self}{body} )            if ($is_tt_switch_active);

    # loop through document children hash
    my $verbatimFound = 0;
    while ( $verbatimFound < $verbatimCount ) {
        while ( my ( $verbatimID, $child ) = each %verbatimStorage ) {
            if ( $toMatch =~ m/${$child}{type}/ ) {
                if ( ${$self}{body} =~ m/$verbatimID/m ) {

                    # possibly remove trailing line break
                    if (    $is_m_switch_active
                        and defined ${$child}{EndFinishesWithLineBreak}
                        and ${$child}{EndFinishesWithLineBreak} == -1
                        and ${$self}{body} =~ m/$verbatimID\h*\R/s )
                    {
                        $logger->trace("m-switch active, removing trailing line breaks from ${$child}{name}")
                            if $is_t_switch_active;
                        ${$self}{body} =~ s/$verbatimID(\h*)?(\R|\h)*/$verbatimID /s;
                    }

                    # line protection mode can allow line breaks to be removed
                    # at end of verbatim; these need to be added back in
                    #
                    # see
                    #
                    #   test-cases/line-switch-test-cases/environments-simple-nested-mod13.tex
                    #
                    if ( ${$child}{type} eq "linesprotect" ) {

                        # remove leading space ahead of verbatim ID
                        ${$self}{body} =~ s/^\h*$verbatimID/$verbatimID/m;

                        if ( $is_m_switch_active and ${$self}{body} =~ m/$verbatimID\h*\S/s ) {
                            ${$self}{body} =~ s/$verbatimID\h*(\S)/$verbatimID\n$1/s;
                        }
                    }

                    # replace ids with body
                    ${$self}{body} =~ s/$verbatimID/${$child}{begin}${$child}{body}${$child}{end}/s;

                    # log file info
                    $logger->trace('Body now looks like:') if $is_tt_switch_active;
                    $logger->trace( ${$self}{body}, 'ttrace' ) if ($is_tt_switch_active);

                    # delete the child so it won't be operated upon again
                    delete $verbatimStorage{$verbatimID};
                    $verbatimFound++;
                }
                elsif ( $is_m_switch_active
                    and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{columns} > 1
                    and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge} ne "overflow"
                    and ${$self}{body} !~ m/${$child}{id}/ )
                {
                    $logger->trace(
                        "$verbatimID not found in body using /m matching, it may have been split across line (see modifyLineBreaks: textWrapOptions)"
                    ) if ($is_t_switch_active);

                    # search for a version of the verbatim ID that may have line breaks
                    my $verbatimIDwithLineBreaks       = join( "\\R?", split( //, $verbatimID ) );
                    my $verbatimIDwithLineBreaksRegExp = qr/$verbatimIDwithLineBreaks/s;

                    # replace the line-broken verbatim ID with a non-broken verbatim ID
                    ${$self}{body} =~ s/$verbatimIDwithLineBreaksRegExp/${$child}{id}/s;

                    # note: we do *not* label this as found, as we need to go back through
                    #       and search for the newly modified ID
                }
            }

            # logfile info
            $logger->trace('*Post-processed body:') if $is_tt_switch_active;
            $logger->trace( ${$self}{body} ) if ($is_tt_switch_active);
        }
    }
    return;
}

sub verbatim_common_tasks {

    my $self = shift;

    # get yaml settings
    $self->yaml_modify_line_breaks_settings if $is_m_switch_active;

    # give unique id
    $self->create_unique_id;

    # the replacement text can be just the ID, but the ID might have a line break at the end of it
    $self->get_replacement_text;

    # the above regexp, when used below, will remove the trailing linebreak in ${$self}{linebreaksAtEnd}{end}
    # so we compensate for it here
    $self->adjust_replacement_text_line_breaks_at_end;

    # modify line breaks end statements
    $self->modify_line_breaks_end
        if ( $is_m_switch_active and defined ${$self}{EndStartsOnOwnLine} and ${$self}{EndStartsOnOwnLine} != 0 );
    $self->modify_line_breaks_end_after
        if ($is_m_switch_active
        and defined ${$self}{EndFinishesWithLineBreak}
        and ${$self}{EndFinishesWithLineBreak} != 0 );
}

sub create_unique_id {
    my $self = shift;

    $verbatimCounter++;
    ${$self}{id}
        = ( ${$self}{type} eq 'command' ? $tokens{verbatimInline} : $tokens{verbatim} )
        . $verbatimCounter
        . $tokens{endOfToken};
    return;
}

sub yaml_get_textwrap_removeparagraphline_breaks {
    my $self = shift;
    $logger->trace("No text wrap or remove paragraph line breaks for verbatim code blocks, ${$self}{name}")
        if ${ $mainSettings{logFilePreferences} }{showDecorationFinishCodeBlockTrace};
}

1;
