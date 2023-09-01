package LatexIndent::Braces;

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
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use LatexIndent::Command qw/$commandRegExp $commandRegExpTrailingComment $optAndMandAndRoundBracketsRegExpLineBreaks/;
use LatexIndent::KeyEqualsValuesBraces
    qw/$key_equals_values_bracesRegExp $key_equals_values_bracesRegExpTrailingComment/;
use LatexIndent::NamedGroupingBracesBrackets qw/$grouping_braces_regexp $grouping_braces_regexpTrailingComment/;
use LatexIndent::UnNamedGroupingBracesBrackets
    qw/$un_named_grouping_braces_RegExp $un_named_grouping_braces_RegExp_trailing_comment/;
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use Data::Dumper;
use Exporter qw/import/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/find_commands_or_key_equals_values_braces $braceBracketRegExpBasic/;
our $commandCounter;
our $braceBracketRegExpBasic = qr/\{|\[/;

sub find_commands_or_key_equals_values_braces {

    my $self = shift;

    $logger->trace("*Searching for commands with optional and/or mandatory arguments AND key = {value}")
        if $is_t_switch_active;

    # match either a \\command or key={value}
    while (${$self}{body} =~ m/$commandRegExpTrailingComment/
        or ${$self}{body} =~ m/$key_equals_values_bracesRegExpTrailingComment/
        or ${$self}{body} =~ m/$grouping_braces_regexpTrailingComment/
        or ${$self}{body} =~ m/$un_named_grouping_braces_RegExp_trailing_comment/ )
    {
        if ( ${$self}{body} =~ m/$commandRegExpTrailingComment/ ) {

            # global substitution
            ${$self}{body} =~ s/
                            $commandRegExpTrailingComment
                          /
                            # create a new command object
                            my $command = LatexIndent::Command->new(begin=>$1.$2.($3?$3:q()).($4?$4:q()),
                                                                    name=>$2,
                                                                    body=>$5.($8?$8:($10?$10:q())),    # $8 is linebreak, $10 is trailing comment
                                                                    end=>q(),
                                                                    linebreaksAtEnd=>{
                                                                      begin=>$4?1:0,
                                                                      end=>$8?1:0,            # $8 is linebreak before comment check, $10 is after
                                                                    },
                                                                    modifyLineBreaksYamlName=>"commands",
                                                                    endImmediatelyFollowedByComment=>$8?0:($10?1:0),
                                                                    aliases=>{
                                                                      # begin statements
                                                                      BeginStartsOnOwnLine=>"CommandStartsOnOwnLine",
                                                                      # body statements
                                                                      BodyStartsOnOwnLine=>"CommandNameFinishesWithLineBreak",
                                                                    },
                                                                    optAndMandArgsRegExp=>$optAndMandAndRoundBracketsRegExpLineBreaks,
                                                                  );
                                                                  
                            # log file output
                            $logger->trace("*command found: $2") if $is_t_switch_active ;

                            # the settings and storage of most objects has a lot in common
                            $self->get_settings_and_store_new_object($command);
                            ${@{${$self}{children}}[-1]}{replacementText}.($8?($10?$10:q()):q());
                         /xseg;

        }
        elsif ( ${$self}{body} =~ m/$key_equals_values_bracesRegExpTrailingComment/ ) {

            # global substitution
            ${$self}{body} =~ s/
                              $key_equals_values_bracesRegExpTrailingComment
                           /
                           # create a new key_equals_values_braces object
                           my $key_equals_values_braces = LatexIndent::KeyEqualsValuesBraces->new(
                                                                   begin=>($2?$2:q()).$3.$4.($5?$5:q()),
                                                                   name=>$3,
                                                                   body=>$6.($9?$9:($10?$10:q()).($11?$11:q())),     # $9 is linebreak before comment check, $11 is trailing comment
                                                                   end=>q(),
                                                                   linebreaksAtEnd=>{
                                                                     begin=>$5?1:0,
                                                                     end=>$9?1:0,                # $9 is linebreak before comment check
                                                                   },
                                                                   modifyLineBreaksYamlName=>"keyEqualsValuesBracesBrackets",
                                                                   beginningbit=>$1,
                                                                   endImmediatelyFollowedByComment=>$9?0:($11?1:0),
                                                                   aliases=>{
                                                                     # begin statements
                                                                     BeginStartsOnOwnLine=>"KeyStartsOnOwnLine",
                                                                     # body statements
                                                                     BodyStartsOnOwnLine=>"EqualsFinishesWithLineBreak",
                                                                   },
                                                                   additionalAssignments=>["EqualsStartsOnOwnLine"],
                                                                 );
                                                                 
                           # log file output
                           $logger->trace("*key_equals_values_braces found: $3") if $is_t_switch_active ;
                    
                           # the settings and storage of most objects has a lot in common
                           $self->get_settings_and_store_new_object($key_equals_values_braces);
                           ${@{${$self}{children}}[-1]}{replacementText}.($9?($11?$11:q()):q());
                           /xseg;

        }
        elsif ( ${$self}{body} =~ m/$grouping_braces_regexpTrailingComment/ ) {

            # global substitution
            ${$self}{body} =~ s/
                            $grouping_braces_regexpTrailingComment
                            /
                            # create a new key_equals_values_braces object
                            my $grouping_braces = LatexIndent::NamedGroupingBracesBrackets->new(
                                                                    begin=>$2.($3?$3:q()).($4?$4:q()),
                                                                    name=>$2,
                                                                    body=>$5.($8?$8:($9?$9:q())),    
                                                                    end=>q(),
                                                                    linebreaksAtEnd=>{
                                                                      begin=>$4?1:0,
                                                                      end=>$8?1:0,
                                                                    },
                                                                    modifyLineBreaksYamlName=>"namedGroupingBracesBrackets",
                                                                    beginningbit=>$1,
                                                                    endImmediatelyFollowedByComment=>$8?0:($9?1:0),
                                                                    aliases=>{
                                                                      # begin statements
                                                                      BeginStartsOnOwnLine=>"NameStartsOnOwnLine",
                                                                      # body statements
                                                                      BodyStartsOnOwnLine=>"NameFinishesWithLineBreak",
                                                                    },
                                                                  );
                            # log file output
                            $logger->trace("*named grouping braces found: $2") if $is_t_switch_active ;

                            # the settings and storage of most objects has a lot in common
                            $self->get_settings_and_store_new_object($grouping_braces);
                            ${@{${$self}{children}}[-1]}{replacementText}.($8?($9?$9:q()):q());
                           /xseg;

        }
        elsif ( ${$self}{body} =~ m/$un_named_grouping_braces_RegExp_trailing_comment/ ) {

            # global substitution
            ${$self}{body} =~ s/
                            $un_named_grouping_braces_RegExp_trailing_comment
                          /
                            # create a new Un-named-grouping-braces-brackets object
                            my $un_named_grouping_braces = LatexIndent::UnNamedGroupingBracesBrackets->new(
                                                                    begin=>q(),
                                                                    name=>"always-un-named",
                                                                    body=>$3.($6?$6:($8?$8:q())),    
                                                                    end=>q(),
                                                                    linebreaksAtEnd=>{
                                                                      begin=>$2?1:0,
                                                                      end=>$6?1:0,
                                                                    },
                                                                    modifyLineBreaksYamlName=>"UnNamedGroupingBracesBrackets",
                                                                    beginningbit=>$1.($2?$2:q()),
                                                                    endImmediatelyFollowedByComment=>$6?0:($8?1:0),
                                                                    # begin statements
                                                                    BeginStartsOnOwnLine=>0,
                                                                    # body statements
                                                                    BodyStartsOnOwnLine=>0,
                                                                  );

                            # log file output
                            $logger->trace("*UNnamed grouping braces found: (no name, by definition!)") if $is_t_switch_active ;

                            # the settings and storage of most objects has a lot in common
                            $self->get_settings_and_store_new_object($un_named_grouping_braces);
                            ${@{${$self}{children}}[-1]}{replacementText}.($6?($8?$8:q()):q());
                         /xseg;

        }
    }
    return;
}

1;
