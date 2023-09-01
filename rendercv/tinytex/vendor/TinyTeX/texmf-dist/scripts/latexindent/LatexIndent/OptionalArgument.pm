package LatexIndent::OptionalArgument;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active $is_m_switch_active /;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::IfElseFi qw/$ifElseFiBasicRegExp/;
use LatexIndent::Special qw/$specialBeginBasicRegExp/;
use Exporter qw/import/;
our @ISA       = "LatexIndent::Document";       # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/find_optional_arguments/;
our $optionalArgumentCounter;
our $optArgRegExp = qr/      
                               (?<!\\)     # not immediately pre-ceeded by \
                               (
                                \[
                                   \h*
                                   (\R*)
                               )
                               (.*?)
                               (\R*)
                               (?<!\\)     # not immediately pre-ceeded by \
                               (
                                \]          # [optional arguments]
                               )
                               (\h*)
                               (\R)?
                           /sx;

sub find_optional_arguments {
    my $self = shift;

    # pick out the optional arguments
    while ( ${$self}{body} =~ m/$optArgRegExp\h*($trailingCommentRegExp)*(.*)/s ) {

        # log file output
        $logger->trace("*Optional argument found, body in ${$self}{name}") if $is_t_switch_active;
        $logger->trace("(last argument)") if ( $9 eq '' and $is_t_switch_active );

        ${$self}{body} =~ s/
                            $optArgRegExp(\h*)($trailingCommentRegExp)*(.*)
                           /
                            # create a new Optional Argument object
                            my $optionalArg = LatexIndent::OptionalArgument->new(begin=>$1,
                                                                    name=>${$self}{name}.":optionalArgument",
                                                                    nameForIndentationSettings=>${$self}{parent},
                                                                    parent=>${$self}{parent},
                                                                    body=>$3.($4?$4:q()),
                                                                    end=>$5,
                                                                    linebreaksAtEnd=>{
                                                                      begin=>$2?1:0,
                                                                      body=>$4?1:0,
                                                                      end=>$7?1:0,
                                                                    },
                                                                    aliases=>{
                                                                      # begin statements
                                                                      BeginStartsOnOwnLine=>"LSqBStartsOnOwnLine",
                                                                      # body statements
                                                                      BodyStartsOnOwnLine=>"OptArgBodyStartsOnOwnLine",
                                                                      # end statements
                                                                      EndStartsOnOwnLine=>"RSqBStartsOnOwnLine",
                                                                      # after end statements
                                                                      EndFinishesWithLineBreak=>"RSqBFinishesWithLineBreak",
                                                                    },
                                                                    modifyLineBreaksYamlName=>"optionalArguments",
                                                                    # the last argument (determined by $10 eq '') needs information from the argument container object
                                                                    endImmediatelyFollowedByComment=>($10 eq '')?${$self}{endImmediatelyFollowedByComment}:($9?1:0),
                                                                    horizontalTrailingSpace=>$6?$6:q(),
                                                                  );

                            # the settings and storage of most objects has a lot in common
                            $self->get_settings_and_store_new_object($optionalArg);
                            ${@{${$self}{children}}[-1]}{replacementText}.($8?$8:q()).($9?$9:q()).($10?$10:q());
                            /xseg;
    }
}

sub yaml_get_object_attribute_for_indentation_settings {
    my $self = shift;

    return ${$self}{modifyLineBreaksYamlName};
}

sub create_unique_id {
    my $self = shift;

    $optionalArgumentCounter++;
    ${$self}{id} = "$tokens{optionalArguments}$optionalArgumentCounter";
    return;
}

sub tasks_particular_to_each_object {
    my $self = shift;

    # lookForAlignDelims: lookForChildCodeBlocks set to 0 means no child objects searched for
    #   see: test-cases/alignment/issue-308-command.tex
    #
    if ( defined ${$self}{lookForChildCodeBlocks} and !${$self}{lookForChildCodeBlocks} ) {
        $logger->trace(
            "lookForAlignDelims: lookForChildCodeBlocks set to 0, so child objects will *NOT* be searched for")
            if ($is_t_switch_active);
        return;
    }

    # search for ifElseFi blocks
    $self->find_ifelsefi if ${$self}{body} =~ m/$ifElseFiBasicRegExp/s;

    # search for special begin/end
    $self->find_special if ${$self}{body} =~ m/$specialBeginBasicRegExp/s;

    # comma poly-switch check
    $self->comma_else if $is_m_switch_active;
}

1;
