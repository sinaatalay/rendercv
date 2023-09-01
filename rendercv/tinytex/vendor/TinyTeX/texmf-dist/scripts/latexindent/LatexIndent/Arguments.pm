package LatexIndent::Arguments;

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
use LatexIndent::Switches qw/$is_m_switch_active $is_t_switch_active $is_tt_switch_active/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::LogFile qw/$logger/;
use Data::Dumper;
use Exporter qw/import/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK
    = qw/get_arguments_regexp find_opt_mand_arguments construct_arguments_regexp $optAndMandRegExp comma_else/;
our $ArgumentCounter;
our $optAndMandRegExp;
our $optAndMandRegExpWithLineBreaks;

sub construct_arguments_regexp {
    my $self = shift;

    $optAndMandRegExp = $self->get_arguments_regexp;

    $optAndMandRegExpWithLineBreaks = $self->get_arguments_regexp( mode => "lineBreaksAtEnd" );
}

sub indent {
    my $self = shift;
    ${$self}{body} =~ s/\R$//s if ( $is_m_switch_active and ${$self}{IDFollowedImmediatelyByLineBreak} );
    $logger->trace("*Arguments object doesn't receive any direct indentation, but its children will...")
        if $is_t_switch_active;
    return;
}

sub find_opt_mand_arguments {
    my $self = shift;

    $logger->trace("*Searching ${$self}{name} for optional and mandatory arguments") if $is_t_switch_active;

    # blank line token
    my $blankLineToken = $tokens{blanklines};

    # the command object allows ()
    my $objectDependentOptAndMandRegExp
        = ( defined ${$self}{optAndMandArgsRegExp} ? ${$self}{optAndMandArgsRegExp} : $optAndMandRegExpWithLineBreaks );

    if ( ${$self}{body} =~ m/^$objectDependentOptAndMandRegExp\h*($trailingCommentRegExp)?/ ) {
        $logger->trace(
            "Optional/Mandatory arguments"
                . (
                ${ $mainSettings{commandCodeBlocks} }{roundParenthesesAllowed} ? " (possibly round Parentheses)" : q()
                )
                . " found in ${$self}{name}: $1"
        ) if $is_t_switch_active;

        # create a new Arguments object
        # The arguments object is a little different to most
        # other objects, as it is created purely for its children,
        # so some of the properties common to other objects, such
        # as environment, ifelsefi, etc do not exist for Arguments;
        # they will, however, exist for its children: OptionalArgument, MandatoryArgument
        my $arguments = LatexIndent::Arguments->new(
            begin                           => "",
            name                            => ${$self}{name} . ":arguments",
            parent                          => ${$self}{name},
            body                            => $1,
            linebreaksAtEnd                 => { end => $2 ? 1 : 0, },
            end                             => "",
            regexp                          => $objectDependentOptAndMandRegExp,
            endImmediatelyFollowedByComment => $2 ? 0 : ( $3 ? 1 : 0 ),
        );

        # give unique id
        $arguments->create_unique_id;

        # text wrapping can make the ID split across lines
        ${$arguments}{idRegExp} = ${$arguments}{id};

        if ( $is_m_switch_active and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge} ne "overflow" ) {
            my $IDwithLineBreaks = join( "\\R?\\h*", split( //, ${$arguments}{id} ) );
            ${$arguments}{idRegExp} = qr/$IDwithLineBreaks/s;
        }

        # determine which comes first, optional or mandatory
        if ( ${$arguments}{body} =~ m/.*?((?<!\\)\{|\[)/s ) {

            if ( $1 eq "\[" ) {
                $logger->trace("Searching for optional arguments, and then mandatory (optional found first)")
                    if $is_t_switch_active;

                # look for optional arguments
                $arguments->find_optional_arguments;

                # look for mandatory arguments
                $arguments->find_mandatory_arguments;
            }
            else {
                $logger->trace("Searching for mandatory arguments, and then optional (mandatory found first)")
                    if $is_t_switch_active;

                # look for mandatory arguments
                $arguments->find_mandatory_arguments;

                # look for optional arguments
                $arguments->find_optional_arguments;
            }

            # it's possible not to have any mandatory or optional arguments, see
            # https://github.com/cmhughes/latexindent.pl/issues/123
            if ( !( defined ${$arguments}{children} ) ) {
                $logger->trace("No optional or mandatory arguments found; searching for matching round parenthesis")
                    if $is_t_switch_active;
                $arguments->find_round_brackets;
            }
        }
        else {
            $logger->trace("Searching for round brackets ONLY") if $is_t_switch_active;

            # look for round brackets
            $arguments->find_round_brackets;
        }

        # we need to store the parent begin in each of the arguments, for example, see
        #   test-cases/texexchange/112343-morbusg.tex
        # which has an alignment delimiter in the first line
        if ( ${$self}{lookForAlignDelims} ) {
            foreach ( @{ ${$arguments}{children} } ) {
                ${$_}{parentBegin} = ${$self}{begin};
            }
        }

# examine *first* child
#   situation: parent BodyStartsOnOwnLine >= 1, but first child has BeginStartsOnOwnLine == 0 || BeginStartsOnOwnLine == undef
#   problem: the *body* of parent actually starts after the arguments
#   solution: remove the linebreak at the end of the begin statement of the parent
        if ( defined ${$self}{BodyStartsOnOwnLine} and ${$self}{BodyStartsOnOwnLine} >= 1 ) {
            if (!(  defined ${ ${ ${$arguments}{children} }[0] }{BeginStartsOnOwnLine}
                    and ${ ${ ${$arguments}{children} }[0] }{BeginStartsOnOwnLine} >= 1
                )
                and ${$self}{body} !~ m/^$blankLineToken/
                )
            {
                my $BodyStringLogFile = ${$self}{aliases}{BodyStartsOnOwnLine} || "BodyStartsOnOwnLine";
                my $BeginStringLogFile
                    = ${ ${ ${$arguments}{children} }[0] }{aliases}{BeginStartsOnOwnLine} || "BeginStartsOnOwnLine";
                $logger->trace(
                    "$BodyStringLogFile = 1 (in ${$self}{name}), but first argument should not begin on its own line (see $BeginStringLogFile)"
                ) if $is_t_switch_active;
                $logger->trace("Removing line breaks at the end of ${$self}{begin}") if $is_t_switch_active;
                ${$self}{begin} =~ s/\R*$//s;
                ${$self}{linebreaksAtEnd}{begin} = 0;
            }
        }

        # situation: preserveBlankLines is active, so the body may well begin with a blank line token
        #            which means that ${$self}{linebreaksAtEnd}{begin} *should be* 1
        if ( ${ ${ ${$arguments}{children} }[0] }{body} =~ m/^($blankLineToken)/ ) {
            $logger->trace(
                "Updating {linebreaksAtEnd}{begin} for ${$self}{name} as $blankLineToken or blank line found at beginning of argument child"
            ) if $is_t_switch_active;
            ${$self}{linebreaksAtEnd}{begin} = 1;
        }

        # examine *first* child
        #   situation: parent BodyStartsOnOwnLine == -1, but first child has BeginStartsOnOwnLine == 1
        #   problem: the *body* of parent actually starts after the arguments
        #   solution: add a linebreak at the end of the begin statement of the parent so that
        #              the child settings are obeyed.
        #              BodyStartsOnOwnLine == 0 will actually be controlled by the last arguments'
        #              settings of EndFinishesWithLineBreak
        if (${$self}{linebreaksAtEnd}{begin} == 0
            and ( ( defined ${$self}{BodyStartsOnOwnLine} and ${$self}{BodyStartsOnOwnLine} == -1 )
                or !( defined ${$self}{BodyStartsOnOwnLine} ) )
            )
        {
            if ( defined ${ ${ ${$arguments}{children} }[0] }{BeginStartsOnOwnLine}
                and ${ ${ ${$arguments}{children} }[0] }{BeginStartsOnOwnLine} >= 1 )
            {
                my $BodyStringLogFile = ${$self}{aliases}{BodyStartsOnOwnLine} || "BodyStartsOnOwnLine";
                my $BeginStringLogFile
                    = ${ ${ ${$arguments}{children} }[0] }{aliases}{BeginStartsOnOwnLine} || "BeginStartsOnOwnLine";
                my $BodyValue = ( defined ${$self}{BodyStartsOnOwnLine} ) ? ${$self}{BodyStartsOnOwnLine} : "0";
                $logger->trace(
                    "$BodyStringLogFile = $BodyValue (in ${$self}{name}), but first argument *should* begin on its own line (see $BeginStringLogFile)"
                ) if $is_t_switch_active;

                # possibly add a comment or a blank line, depending on if BeginStartsOnOwnLine == 2 or 3 respectively
                # at the end of the begin statement
                my $trailingCharacterToken = q();
                if ( ${ ${ ${$arguments}{children} }[0] }{BeginStartsOnOwnLine} == 1 ) {
                    $logger->trace(
                        "Adding line breaks at the end of ${$self}{begin} (first argument, see $BeginStringLogFile == ${${${$arguments}{children}}[0]}{BeginStartsOnOwnLine})"
                    ) if $is_t_switch_active;
                }
                elsif ( ${ ${ ${$arguments}{children} }[0] }{BeginStartsOnOwnLine} == 2 ) {
                    $logger->trace(
                        "Adding a % at the end of begin, ${$self}{begin} followed by a linebreak ($BeginStringLogFile == 2)"
                    ) if $is_t_switch_active;
                    $trailingCharacterToken = "%" . $self->add_comment_symbol;
                    $logger->trace("Removing trailing space on ${$self}{begin}") if $is_t_switch_active;
                    ${$self}{begin} =~ s/\h*$//s;
                }
                elsif ( ${ ${ ${$arguments}{children} }[0] }{BeginStartsOnOwnLine} == 3 ) {
                    $logger->trace("Adding a blank line immediately ${$self}{begin} ($BeginStringLogFile==3)")
                        if $is_t_switch_active;
                    $trailingCharacterToken = "\n"
                        . ( ${ $mainSettings{modifyLineBreaks} }{preserveBlankLines} ? $tokens{blanklines} : q() );
                }

                # modification
                ${$self}{begin} .= "$trailingCharacterToken\n";
                ${$self}{linebreaksAtEnd}{begin} = 1;
            }
        }

        # the replacement text can be just the ID, but the ID might have a line break at the end of it
        ${$arguments}{replacementText} = ${$arguments}{id};

        # children need to receive ancestor information, see test-cases/commands/commands-triple-nested.tex
        foreach ( @{ ${$arguments}{children} } ) {
            $logger->trace("Updating argument child of ${$self}{name} to include ${$self}{id} in ancestors")
                if $is_t_switch_active;
            push(
                @{ ${$_}{ancestors} },
                { ancestorID => ${$self}{id}, ancestorIndentation => ${$self}{indentation}, type => "natural" }
            );
        }

        # the argument object only needs a trailing line break if the *last* child
        # did not add one at the end, and if BodyStartsOnOwnLine >= 1
        if ((   defined ${ ${ ${$arguments}{children} }[-1] }{EndFinishesWithLineBreak}
                and ${ ${ ${$arguments}{children} }[-1] }{EndFinishesWithLineBreak} < 1
            )
            and ( defined ${$self}{BodyStartsOnOwnLine} and ${$self}{BodyStartsOnOwnLine} >= 1 )
            )
        {
            $logger->trace("Updating replacementtext to include a linebreak for arguments in ${$self}{name}")
                if $is_t_switch_active;
            ${$arguments}{replacementText} .= "\n" if ( ${$arguments}{linebreaksAtEnd}{end} );
        }

        # store children in special hash
        push( @{ ${$self}{children} }, $arguments );

        # remove the environment block, and replace with unique ID
        ${$self}{body} =~ s/${$arguments}{regexp}/${$arguments}{replacementText}/;

        # delete the regexp, as there's no need for it
        delete ${ ${ ${$self}{children} }[-1] }{regexp};

        $logger->trace( Dumper( \%{$arguments} ) ) if ($is_tt_switch_active);
        $logger->trace("replaced with ID: ${$arguments}{id}") if $is_tt_switch_active;
    }
    else {
        $logger->trace("... no arguments found") if $is_t_switch_active;
    }

}

sub create_unique_id {
    my $self = shift;

    $ArgumentCounter++;
    ${$self}{id} = "$tokens{arguments}$ArgumentCounter$tokens{endOfToken}";
    return;
}

sub get_arguments_regexp {

    my $self  = shift;
    my %input = @_;

    # blank line token
    my $blankLineToken = $tokens{blanklines};

    # some calls to this routine need to account for the linebreaks at the end, some do not
    my $lineBreaksAtEnd = ( defined ${input}{mode} and ${input}{mode} eq 'lineBreaksAtEnd' ) ? '\R*' : q();

    # arguments Before, by default, includes beamer special and numbered arguments, for example #1 #2, etc
    my $argumentsBefore  = qr/${${$mainSettings{fineTuning}}{arguments}}{before}/;
    my $argumentsBetween = qr/${${$mainSettings{fineTuning}}{arguments}}{between}/;

# commands are allowed strings between arguments, e.g node, decoration, etc, specified in stringsAllowedBetweenArguments
    my $stringsBetweenArguments = q();

    if (    defined ${input}{stringBetweenArguments}
        and ${input}{stringBetweenArguments} == 1
        and ref( ${ $mainSettings{commandCodeBlocks} }{stringsAllowedBetweenArguments} ) eq "ARRAY" )
    {
        # grab the strings allowed between arguments
        my @stringsAllowedBetweenArguments = @{ ${ $mainSettings{commandCodeBlocks} }{stringsAllowedBetweenArguments} };

        $logger->trace("*Looping through array for commandCodeBlocks->stringsAllowedBetweenArguments")
            if $is_t_switch_active;

        # note that the zero'th element in this array contains the amalgamate switch, which we don't want!
        foreach ( @stringsAllowedBetweenArguments[ 1 .. $#stringsAllowedBetweenArguments ] ) {
            $logger->trace("$_") if $is_t_switch_active;
            $stringsBetweenArguments .= ( $stringsBetweenArguments eq "" ? q() : "|" ) . $_;
        }

        $stringsBetweenArguments = qr/$stringsBetweenArguments/;

        # report to log file
        $logger->trace(
            "*Strings allowed between arguments: $stringsBetweenArguments (see stringsAllowedBetweenArguments)")
            if $is_t_switch_active;
    }

    if ( defined ${input}{roundBrackets} and ${input}{roundBrackets} == 1 ) {

        # arguments regexp
        return qr/
                                  (                          # capture into $1
                                     (?:                  
                                        (?:\h|\R|$blankLineToken|$trailingCommentRegExp|$argumentsBefore|$argumentsBetween|$stringsBetweenArguments)* 
                                        (?:
                                             (?:
                                                 \h*         # 0 or more spaces
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \[
                                                     (?:
                                                         (?!
                                                             (?:(?<!\\)\[|(?<!\\)\{) 
                                                         ).
                                                     )*?     # not including [, but \[ ok
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \]          # [optional arguments]
                                             )
                                             |               # OR
                                             (?:
                                                 \h*         # 0 or more spaces
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \{
                                                     (?:
                                                         (?!
                                                             (?:(?<!\\)\{|(?<!\\)\[) 
                                                         ).
                                                     )*?     # not including {, but \{ ok
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \}          # {mandatory arguments}
                                             )
                                             |               # OR
                                             (?:
                                                 \h*         # 0 or more spaces
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \(\$
                                                     (?:
                                                         (?!
                                                             (?:(?<!\\)\$) 
                                                         ).
                                                     )*?     # not including $
                                                 \$
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \)          # {mandatory arguments}
                                             )
                                             |               # OR
                                             (?:
                                                 \h*         # 0 or more spaces
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \(
                                                     (?:
                                                         (?!
                                                             (?:(?<!\\)\() 
                                                         ).
                                                     )*?     # not including {, but \{ ok
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \)          # {mandatory arguments}
                                             )
                                        )
                                     )
                                     +                       # at least one of the above
                                     # NOT followed by
                                     (?!
                                       (?:
                                           (?:\h|\R|$blankLineToken|$trailingCommentRegExp|$argumentsBefore|$stringsBetweenArguments)*  # 0 or more h-space, blanklines, trailing comments
                                           (?:
                                             (?:(?<!\\)\[)
                                             |
                                             (?:(?<!\\)\{)
                                             |
                                             (?:(?<!\\)\()
                                           )
                                       )
                                     )
                                     \h*
                                     ($lineBreaksAtEnd)
                                  )                  
                                  /sx;
    }
    else {
        return qr/
                                  (                          # capture into $1
                                     (?:                  
                                        (?:\h|\R|$blankLineToken|$trailingCommentRegExp|$argumentsBefore|$argumentsBetween|$stringsBetweenArguments)* 
                                        (?:
                                             (?:
                                                 \h*         # 0 or more spaces
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \[
                                                     (?:
                                                         (?!
                                                             (?:(?<!\\)\[|(?<!\\)\{) 
                                                         ).
                                                     )*?     # not including [, but \[ ok
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \]          # [optional arguments]
                                             )
                                             |               # OR
                                             (?:
                                                 \h*         # 0 or more spaces
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \{
                                                     (?:
                                                         (?!
                                                             (?:(?<!\\)\{|(?<!\\)\[) 
                                                         ).
                                                     )*?     # not including {, but \{ ok
                                                 (?<!\\)     # not immediately pre-ceeded by \
                                                 \}          # {mandatory arguments}
                                             )
                                        )
                                     )
                                     +                       # at least one of the above
                                     # NOT followed by
                                     (?!
                                       (?:
                                           (?:\h|\R|$blankLineToken|$trailingCommentRegExp|$argumentsBefore)*  # 0 or more h-space, blanklines, trailing comments
                                           (?:
                                             (?:(?<!\\)\[)
                                             |
                                             (?:(?<!\\)\{)
                                           )
                                       )
                                     )
                                     \h*
                                     ($lineBreaksAtEnd)
                                  )                  
                                  /sx;
    }
}

sub comma_else {
    my $self = shift;

    # check for existence of \\ statement, and associated line break information
    $self->check_for_else_statement(

        # else name regexp
        elseNameRegExp => qr/${${$mainSettings{fineTuning}}{modifyLineBreaks}}{comma}/,

        # else statements name
        ElseStartsOnOwnLine => "CommaStartsOnOwnLine",

        # end statements
        ElseFinishesWithLineBreak => "CommaFinishesWithLineBreak",

        # for the YAML settings storage
        storageNameAppend => "comma",

        # logfile information
        logName => "comma block, see CommaStartsOnOwnLine and CommaFinishesWithLineBreak",
    );
}
1;
