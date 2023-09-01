package LatexIndent::Environment;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active $is_m_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::Braces qw/$braceBracketRegExpBasic/;
use LatexIndent::IfElseFi qw/$ifElseFiBasicRegExp/;
use LatexIndent::Heading qw/$allHeadingsRegexp/;
use LatexIndent::Special qw/$specialBeginAndBracesBracketsBasicRegExp/;
use Exporter qw/import/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/find_environments $environmentBasicRegExp construct_environments_regexp/;
our $environmentCounter;
our $environmentBasicRegExp = qr/\\begin\{/;
our $environmentRegExp;

# store the regular expression for matching and replacing the \begin{}...\end{} statements
sub construct_environments_regexp {

    # read from fine tuning
    my $environmentNameRegExp = qr/${${$mainSettings{fineTuning}}{environments}}{name}/;
    $environmentRegExp = qr/
                (
                    \\begin\{
                            (
                             $environmentNameRegExp # lowercase|uppercase letters, @, *, numbers
                            )                       # environment name captured into $2
                           \}                       # \begin{<something>} statement
                           \h*                      # horizontal space
                           (\R*)?                   # possible line breaks (into $3)
                )                                   # begin statement captured into $1
                (
                    (?:                             # cluster-only (), don't capture 
                        (?!                         # don't include \begin in the body
                            (?:\\begin\{)           # cluster-only (), don't capture
                        ).                          # any character, but not \\begin
                    )*?                             # non-greedy
                            (\R*)?                  # possible line breaks (into $5)
                )                                   # environment body captured into $4
                (
                    \\end\{\2\}                     # \end{<something>} statement
                )                                   # captured into $6
                (\h*)?                              # possibly followed by horizontal space
                (\R)?                               # possibly followed by a line break 
                /sx;
}

sub find_environments {
    my $self = shift;

    while ( ${$self}{body} =~ m/$environmentRegExp\h*($trailingCommentRegExp)?/ ) {

        # global substitution
        ${$self}{body} =~ s/
                $environmentRegExp(\h*)($trailingCommentRegExp)?
             /
                # create a new Environment object
                my $env = LatexIndent::Environment->new(begin=>$1,
                                                        name=>$2,
                                                        body=>$4,
                                                        end=>$6,
                                                        linebreaksAtEnd=>{
                                                          begin=>$3?1:0,
                                                          body=>$5?1:0,
                                                          end=>$8?1:0,
                                                        },
                                                        modifyLineBreaksYamlName=>"environments",
                                                        endImmediatelyFollowedByComment=>$8?0:($10?1:0),
                                                        horizontalTrailingSpace=>$7?$7:q(),
                                                      );

                # log file output
                $logger->trace("*environment found: $2") if $is_t_switch_active;

                # the settings and storage of most objects has a lot in common
                $self->get_settings_and_store_new_object($env);
                ${@{${$self}{children}}[-1]}{replacementText}.($9?$9:q()).($10?$10:q());
                /xseg;
        $self->adjust_line_breaks_end_parent if $is_m_switch_active;
    }
    return;
}

sub tasks_particular_to_each_object {
    my $self = shift;

    # if the environment is empty, we may need to update linebreaksAtEnd{body}
    if ( ${$self}{body} =~ m/^\h*$/s and ${ ${$self}{linebreaksAtEnd} }{begin} ) {
        $logger->trace("empty environment body (${$self}{name}), updating linebreaksAtEnd{body} to be 1")
            if ($is_t_switch_active);
        ${ ${$self}{linebreaksAtEnd} }{body} = 1;
    }

    # lookForAlignDelims: lookForChildCodeBlocks set to 0 means no child objects searched for
    #   see: test-cases/alignment/issue-308.tex
    #
    if ( defined ${$self}{lookForChildCodeBlocks} and !${$self}{lookForChildCodeBlocks} ) {
        $logger->trace(
            "lookForAlignDelims: lookForChildCodeBlocks set to 0, so child objects will *NOT* be searched for")
            if ($is_t_switch_active);
        return;
    }

    # search for items as the first order of business
    $self->find_items if ${ $mainSettings{indentAfterItems} }{ ${$self}{name} };

    # search for headings (important to do this before looking for commands!)
    $self->find_heading if ${$self}{body} =~ m/$allHeadingsRegexp/s;

    # search for commands and special code blocks
    $self->find_commands_or_key_equals_values_braces_and_special
        if ${$self}{body} =~ m/$specialBeginAndBracesBracketsBasicRegExp/s;

    # search for arguments
    $self->find_opt_mand_arguments if ${$self}{body} =~ m/$braceBracketRegExpBasic/s;

    # search for ifElseFi blocks
    $self->find_ifelsefi if ${$self}{body} =~ m/$ifElseFiBasicRegExp/s;

}

sub create_unique_id {
    my $self = shift;

    $environmentCounter++;
    ${$self}{id} = "$tokens{environments}$environmentCounter";
    return;
}

1;
