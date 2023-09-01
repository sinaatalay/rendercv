package LatexIndent::MandatoryArgument;

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
our @ISA       = "LatexIndent::Document";                             # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/find_mandatory_arguments get_mand_arg_reg_exp/;
our $mandatoryArgumentCounter;

sub find_mandatory_arguments {
    my $self = shift;

    my $mandArgRegExp = $self->get_mand_arg_reg_exp;

    # pick out the mandatory arguments
    while ( ${$self}{body} =~ m/$mandArgRegExp\h*($trailingCommentRegExp)*(.*)/s ) {

        # log file output
        $logger->trace("*Mandatory argument found, body in ${$self}{name}") if $is_t_switch_active;
        $logger->trace("(last argument)") if ( $9 eq '' and $is_t_switch_active );

        ${$self}{body} =~ s/
                            $mandArgRegExp(\h*)($trailingCommentRegExp)*(.*)
                           /
                            # create a new Mandatory Argument object
                            my $mandatoryArg = LatexIndent::MandatoryArgument->new(begin=>$1,
                                                                    name=>${$self}{name}.":mandatoryArgument",
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
                                                                      BeginStartsOnOwnLine=>"LCuBStartsOnOwnLine",
                                                                      # body statements
                                                                      BodyStartsOnOwnLine=>"MandArgBodyStartsOnOwnLine",
                                                                      # end statements
                                                                      EndStartsOnOwnLine=>"RCuBStartsOnOwnLine",
                                                                      # after end statements
                                                                      EndFinishesWithLineBreak=>"RCuBFinishesWithLineBreak",
                                                                    },
                                                                    horizontalTrailingSpace=>$6?$6:q(),
                                                                    modifyLineBreaksYamlName=>"mandatoryArguments",
                                                                    # the last argument (determined by $10 eq '') needs information from the argument container object
                                                                    endImmediatelyFollowedByComment=>($10 eq '')?${$self}{endImmediatelyFollowedByComment}:($9?1:0),
                                                                  );

                            # the settings and storage of most objects has a lot in common
                            $self->get_settings_and_store_new_object($mandatoryArg);
                            ${@{${$self}{children}}[-1]}{replacementText}.($8?$8:q()).($9?$9:q()).($10?$10:q());
                            /xseg;
        $self->wrap_up_tasks;
    }
}

sub create_unique_id {
    my $self = shift;

    $mandatoryArgumentCounter++;
    ${$self}{id} = "$tokens{mandatoryArguments}$mandatoryArgumentCounter";
    return;
}

sub get_mand_arg_reg_exp {

    my $mandArgRegExp = qr/      
                                   (?<!\\)     # not immediately pre-ceeded by \
                                   (
                                    \{
                                       \h*
                                       (\R*)   # linebreaks after { into $2
                                   )           # { captured into $1
                                   (
                                       (?:
                                           (?!
                                               (?:(?<!\\)\{) 
                                           ).
                                       )*?     # not including {, but \{ ok
                                   )            # body into $3
                                   (\R*)       # linebreaks after body into $4
                                   (?<!\\)     # not immediately pre-ceeded by \
                                   (
                                    \}         # {mandatory arguments}
                                   )           # } into $5
                                   (\h*)
                                   (\R)?       # linebreaks after } into $6
                               /sx;

    return $mandArgRegExp;
}

sub yaml_get_object_attribute_for_indentation_settings {
    my $self = shift;

    return ${$self}{modifyLineBreaksYamlName};
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
