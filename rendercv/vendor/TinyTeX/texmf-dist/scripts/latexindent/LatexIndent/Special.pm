package LatexIndent::Special;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::IfElseFi qw/$ifElseFiBasicRegExp/;
use Data::Dumper;
use Exporter qw/import/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK
    = qw/find_special construct_special_begin $specialBeginAndBracesBracketsBasicRegExp $specialBeginBasicRegExp/;
our $specialCounter;
our $specialBegins           = q();
our $specialAllMatchesRegExp = q();
our %individualSpecialRegExps;
our $specialBeginAndBracesBracketsBasicRegExp;
our $specialBeginBasicRegExp;

sub construct_special_begin {
    my $self = shift;

    $logger->trace("*Constructing specialBeginEnd regex (see specialBeginEnd)") if $is_t_switch_active;

    # put together a list of the begin terms in special
    while ( my ( $specialName, $BeginEnd ) = each %{ $mainSettings{specialBeginEnd} } ) {
        if ( ref($BeginEnd) eq "HASH" ) {
            if ( not defined ${$BeginEnd}{lookForThis} ) {
                ${$BeginEnd}{lookForThis} = 1;
                ${ ${ $mainSettings{specialBeginEnd} }{$specialName} }{lookForThis} = 1;
                $logger->trace("setting lookForThis:1 for $specialName (lookForThis not specified)")
                    if $is_t_switch_active;
            }

            # only append the regexps if lookForThis is 1
            $specialBegins .= ( $specialBegins eq "" ? q() : "|" ) . ${$BeginEnd}{begin}
                if ( ${$BeginEnd}{lookForThis} =~ m/\d/s and ${$BeginEnd}{lookForThis} == 1 );
        }
    }

    # put together a list of the begin terms in special
    while ( my ( $specialName, $BeginEnd ) = each %{ $mainSettings{specialBeginEnd} } ) {

        # only append the regexps if lookForThis is 1
        if ( ref($BeginEnd) eq "HASH" ) {
            if ( ${$BeginEnd}{lookForThis} =~ m/\d/s and ${$BeginEnd}{lookForThis} == 0 ) {
                $logger->trace("The specialBeginEnd regexps won't include anything from $specialName (lookForThis: 0)")
                    if $is_t_switch_active;
                next;
            }
        }
        else {
            next;
        }

        # the overall regexp
        $specialAllMatchesRegExp .= ( $specialAllMatchesRegExp eq "" ? q() : "|" ) . qr/
                                  ${$BeginEnd}{begin}
                                  (?:                        # cluster-only (), don't capture 
                                      (?!             
                                          (?:$specialBegins) # cluster-only (), don't capture
                                      ).                     # any character, but not anything in $specialBegins
                                  )*?                 
                                  ${$BeginEnd}{end}
                           /sx;

        # store the individual special regexp
        $individualSpecialRegExps{$specialName} = qr/
                                (
                                    ${$BeginEnd}{begin}
                                    \h*
                                    (\R*)?
                                )
                                (
                                    (?:                        # cluster-only (), don't capture 
                                        (?!             
                                            (?:$specialBegins) # cluster-only (), don't capture
                                        ).                     # any character, but not anything in $specialBegins
                                    )*?                 
                                   (\R*)?
                                )                       
                                (
                                  ${$BeginEnd}{end}
                                )
                                (\h*)
                                (\R)?
                             /sx

    }

    # move $$ to the beginning
    if ( $specialBegins =~ m/\|\\\$\\\$/ ) {
        $specialBegins =~ s/\|(\\\$\\\$)//;
        $specialBegins = $1 . "|" . $specialBegins;
    }

    # info to the log file
    $logger->trace("*The special beginnings regexp is: (see specialBeginEnd)") if $is_tt_switch_active;
    $logger->trace($specialBegins) if $is_tt_switch_active;

    # overall special regexp
    $logger->trace("*The overall special regexp is: (see specialBeginEnd)") if $is_tt_switch_active;
    $logger->trace($specialAllMatchesRegExp) if $is_tt_switch_active;

    # basic special begin regexp
    $specialBeginBasicRegExp                  = qr/$specialBegins/;
    $specialBeginAndBracesBracketsBasicRegExp = $specialBegins . "|\\{|\\[";
    $specialBeginAndBracesBracketsBasicRegExp = qr/$specialBeginAndBracesBracketsBasicRegExp/;
}

sub find_special {
    my $self = shift;

    # no point carrying on if the list of specials is empty
    return if ( $specialBegins eq "" );

    # otherwise loop through the special begin/end
    $logger->trace("*Searching ${$self}{name} for special begin/end (see specialBeginEnd)") if $is_t_switch_active;
    $logger->trace( Dumper( \%{ $mainSettings{specialBeginEnd} } ) ) if $is_tt_switch_active;

    # keep looping as long as there is a special match of some kind
    while ( ${$self}{body} =~ m/$specialAllMatchesRegExp/sx ) {

        # loop through each special match
        while ( my ( $specialName, $BeginEnd ) = each %{ $mainSettings{specialBeginEnd} } ) {

            # log file
            if (    ( ref($BeginEnd) eq "HASH" )
                and ${$BeginEnd}{lookForThis} =~ m/\d/s
                and ${$BeginEnd}{lookForThis} == 1 )
            {
                $logger->trace("Looking for $specialName") if $is_t_switch_active;
            }
            else {
                $logger->trace("Not looking for $specialName (see lookForThis)")
                    if ( $is_t_switch_active and ( ref($BeginEnd) eq "HASH" ) );
                next;
            }

            # the regexp
            my $specialRegExp = $individualSpecialRegExps{$specialName};
            $logger->trace("$specialName regexp: \n$specialRegExp") if $is_tt_switch_active;

            while ( ${$self}{body} =~ m/$specialRegExp(\h*)($trailingCommentRegExp)?/ ) {

                # global substitution
                ${$self}{body} =~ s/
                                    $specialRegExp(\h*)($trailingCommentRegExp)?
                                   /
                                    # create a new special object
                                    my $specialObject = LatexIndent::Special->new(begin=>$1,
                                                                            body=>$3,
                                                                            end=>$5,
                                                                            name=>$specialName,
                                                                            linebreaksAtEnd=>{
                                                                              begin=>$2?1:0,
                                                                              body=>$4?1:0,
                                                                              end=>$7?1:0,
                                                                            },
                                                                            aliases=>{
                                                                              # begin statements
                                                                              BeginStartsOnOwnLine=>"SpecialBeginStartsOnOwnLine",
                                                                              # body statements
                                                                              BodyStartsOnOwnLine=>"SpecialBodyStartsOnOwnLine",
                                                                              # end statements
                                                                              EndStartsOnOwnLine=>"SpecialEndStartsOnOwnLine",
                                                                              # after end statements
                                                                              EndFinishesWithLineBreak=>"SpecialEndFinishesWithLineBreak",
                                                                            },
                                                                            modifyLineBreaksYamlName=>"specialBeginEnd",
                                                                            endImmediatelyFollowedByComment=>$7?0:($9?1:0),
                                                                            horizontalTrailingSpace=>$6?$6:q(),
                                                                          );

                                    # log file output
                                    $logger->trace("*Special found: $specialName") if $is_t_switch_active;

                                    # the settings and storage of most objects has a lot in common
                                    $self->get_settings_and_store_new_object($specialObject);
                                    ${@{${$self}{children}}[-1]}{replacementText}.($8?$8:q()).($9?$9:q());
                                    /xseg;

                $self->wrap_up_tasks;
            }
        }
    }
}

sub tasks_particular_to_each_object {
    my $self = shift;

    if ( defined ${ ${ $mainSettings{specialBeginEnd} }{ ${$self}{name} } }{middle} ) {
        $logger->trace("middle specified for ${$self}{name} (see specialBeginEnd -> ${$self}{name} -> middle)")
            if $is_t_switch_active;

        # initiate the middle regexp
        my $specialMiddle = q();

        # we can specify middle as either an array or a hash
        if ( ref( ${ ${ $mainSettings{specialBeginEnd} }{ ${$self}{name} } }{middle} ) eq "ARRAY" ) {
            $logger->trace("looping through middle array for ${$self}{name}") if $is_t_switch_active;
            foreach ( @{ ${ ${ $mainSettings{specialBeginEnd} }{ ${$self}{name} } }{middle} } ) {
                $specialMiddle .= ( $specialMiddle eq "" ? q() : "|" ) . $_;
            }
            $specialMiddle = qr/$specialMiddle/;
        }
        else {
            $specialMiddle = qr/${${$mainSettings{specialBeginEnd}}{${$self}{name}}}{middle}/;
        }

        $logger->trace("overall middle regexp for ${$self}{name}: $specialMiddle") if $is_t_switch_active;

        # store the middle regexp for later
        ${$self}{middleRegExp} = $specialMiddle;

        # check for existence of a 'middle' statement, and associated line break information
        $self->check_for_else_statement(

            # else name regexp
            elseNameRegExp => $specialMiddle,

            # else statements name
            ElseStartsOnOwnLine => "SpecialMiddleStartsOnOwnLine",

            # end statements
            ElseFinishesWithLineBreak => "SpecialMiddleFinishesWithLineBreak",

            # for the YAML settings storage
            storageNameAppend => "middle",

            # logfile information
            logName => "special middle",
        );

    }

    return unless ( ${ $mainSettings{specialBeginEnd} }{specialBeforeCommand} );

    # lookForAlignDelims: lookForChildCodeBlocks set to 0 means no child objects searched for
    #   see: test-cases/alignment/issue-308-special.tex
    #
    if ( defined ${$self}{lookForChildCodeBlocks} and !${$self}{lookForChildCodeBlocks} ) {
        $logger->trace(
            "lookForAlignDelims: lookForChildCodeBlocks set to 0, so child objects will *NOT* be searched for")
            if ($is_t_switch_active);
        return;
    }

    # search for commands with arguments
    $self->find_commands_or_key_equals_values_braces;

    # search for arguments
    $self->find_opt_mand_arguments;

    # search for ifElseFi blocks
    $self->find_ifelsefi;

}

sub post_indentation_check {

    # needed to remove leading horizontal space before \else
    my $self = shift;

    return unless ( defined ${ ${ $mainSettings{specialBeginEnd} }{ ${$self}{name} } }{middle} );

    $logger->trace("post indentation check for ${$self}{name} to account for middle") if $is_t_switch_active;

    # loop through \else and \or
    foreach ( { regExp => ${$self}{middleRegExp} } ) {
        my %else = %{$_};
        if ( ${$self}{body} =~ m/^\h*$else{regExp}/sm
            and !( ${$self}{body} =~ m/^\h*$else{regExp}/s and ${$self}{linebreaksAtEnd}{begin} == 0 ) )
        {
            $logger->trace(
                "*Adding surrounding indentation to $else{regExp} statement(s) ('${$self}{surroundingIndentation}')")
                if $is_t_switch_active;
            ${$self}{body} =~ s/^\h*($else{regExp})/${$self}{surroundingIndentation}$1/smg;
        }
    }
    return;
}

sub create_unique_id {
    my $self = shift;

    $specialCounter++;

    ${$self}{id} = "$tokens{specialBeginEnd}$specialCounter";
    return;
}

1;
