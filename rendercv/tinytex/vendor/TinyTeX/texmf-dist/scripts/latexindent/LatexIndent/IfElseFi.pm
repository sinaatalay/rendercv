package LatexIndent::IfElseFi;

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
use LatexIndent::TrailingComments qw/$trailingCommentRegExp/;
use LatexIndent::Switches qw/$is_m_switch_active $is_t_switch_active $is_tt_switch_active/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::Heading qw/$allHeadingsRegexp/;
use Exporter qw/import/;
our @ISA = "LatexIndent::Document";    # class inheritance, Programming Perl, pg 321
our @EXPORT_OK = qw/find_ifelsefi construct_ifelsefi_regexp $ifElseFiBasicRegExp/;
our $ifElseFiCounter;
our $ifElseFiRegExp;
our $ifElseFiBasicRegExp = qr/\\if/;

# store the regular expression for matching and replacing the \if...\else...\fi statements
# note: we search for \else separately in an attempt to keep this regexp a little more manageable

sub construct_ifelsefi_regexp {
    my $ifElseFiNameRegExp = qr/${${$mainSettings{fineTuning}}{ifElseFi}}{name}/;
    $ifElseFiRegExp = qr/
                (
                    \\
                        ($ifElseFiNameRegExp)
                    \h*
                    (\R*)
                )                           # begin statement, e.g \ifnum, \ifodd
                (
                    \\(?!if)|[0-9]|\R|\h|\#|!-!|$trailingCommentRegExp   # up until a \\, linebreak # or !-!, which is 
                )                           # part of the tokens used for latexindent
                (
                    (?: 
                        (?!\\$ifElseFiNameRegExp).
                    )*?                     # body, which can't include another \if
                )
                (\R*)                       # linebreaks after body
                (
                    \\fi(?![a-zA-Z])                    # \fi statement 
                )
                (\h*)                       # 0 or more horizontal spaces
                (\R)?                       # linebreaks after \fi
/sx;
}

sub find_ifelsefi {
    my $self = shift;

    while ( ${$self}{body} =~ m/$ifElseFiRegExp\h*($trailingCommentRegExp)?/ ) {

        ${$self}{body} =~ s/
                $ifElseFiRegExp(\h*)($trailingCommentRegExp)?
                    /
                        # create a new IfElseFi object
                        my $ifElseFi = LatexIndent::IfElseFi->new(begin=>$1.(($4 eq "\n" and !$3)?"\n":q()),
                                                                name=>$2,
                                                                # if $4 is a line break, don't count it twice (it will already be in 'begin')
                                                                body=>($4 eq "\n") ? $5.$6 : $4.$5.$6,
                                                                end=>$7,
                                                                linebreaksAtEnd=>{
                                                                  begin=>(($4 eq "\n")||$3)?1:0,
                                                                  body=>$6?1:0,
                                                                  end=>$9?1:0,
                                                                },
                                                                aliases=>{
                                                                  # begin statements
                                                                  BeginStartsOnOwnLine=>"IfStartsOnOwnLine",
                                                                  # end statements
                                                                  EndStartsOnOwnLine=>"FiStartsOnOwnLine",
                                                                  # after end statements
                                                                  EndFinishesWithLineBreak=>"FiFinishesWithLineBreak",
                                                                },
                                                                modifyLineBreaksYamlName=>"ifElseFi",
                                                                endImmediatelyFollowedByComment=>$9?0:($11?1:0),
                                                                horizontalTrailingSpace=>$8?$8:q(),
                                                              );
                        # log file output
                        $logger->trace("*IfElseFi found: $2")if $is_t_switch_active;
           
                        # the settings and storage of most objects has a lot in common
                        $self->get_settings_and_store_new_object($ifElseFi);
                        ${@{${$self}{children}}[-1]}{replacementText}.($10?$10:q()).($11?$11:q());
                        /xse;

    }
    return;
}

sub post_indentation_check {

    # needed to remove leading horizontal space before \else
    my $self = shift;

    # loop through \else and \or
    foreach ( { regExp => qr/\\else/ }, { regExp => qr/\\or/ } ) {
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

sub tasks_particular_to_each_object {
    my $self = shift;

    # check for existence of \else statement, and associated line break information
    $self->check_for_else_statement(

        # else name regexp
        elseNameRegExp => qr|\\else|,

        # else statements name
        ElseStartsOnOwnLine => "ElseStartsOnOwnLine",

        # end statements
        ElseFinishesWithLineBreak => "ElseFinishesWithLineBreak",

        # for the YAML settings storage
        storageNameAppend => "else",

        # logfile information
        logName => "else",
    );

    # check for existence of \or statement, and associated line break information
    $self->check_for_else_statement(

        # else name regexp
        elseNameRegExp => qr|\\or|,

        # else statements name
        ElseStartsOnOwnLine => "OrStartsOnOwnLine",

        # end statements
        ElseFinishesWithLineBreak => "OrFinishesWithLineBreak",

        # for the YAML settings storage
        storageNameAppend => "or",

        # logfile information
        logName => "or",
    );

    # search for headings (important to do this before looking for commands!)
    $self->find_heading if ${$self}{body} =~ m/$allHeadingsRegexp/s;

    # search for commands and special code blocks
    $self->find_commands_or_key_equals_values_braces_and_special;

}

sub indent_begin {
    my $self = shift;

    # line break checks after \if statement, can get messy if we
    # have, for example
    #       \ifnum
    #               something
    # which might be changed into
    #       \ifnumsomething
    # which is undeserible
    if (    defined ${$self}{BodyStartsOnOwnLine}
        and ${$self}{BodyStartsOnOwnLine} == -1
        and ${$self}{body} !~ m/^(\h|\\|(?:!-!))/s )
    {
        ${$self}{begin} .= " ";
    }
}

sub wrap_up_statement {
    my $self = shift;

    # line break checks *after* \end{statement}
    if ( defined ${$self}{EndFinishesWithLineBreak}
        and ${$self}{EndFinishesWithLineBreak} == -1 )
    {
        # add a single horizontal space after the child id, otherwise we can end up
        # with things like
        #       before:
        #               \fi
        #                   text
        #       after:
        #               \fitext
        $logger->trace(
            "*Adding a single space after \\fi statement (otherwise \\fi can be comined with next line of text in an unwanted way)"
        ) if $is_t_switch_active;
        ${$self}{end} = ${$self}{end} . " ";
    }
    $logger->trace("*Finished indenting ${$self}{name}") if $is_t_switch_active;
    return $self;
}

sub create_unique_id {
    my $self = shift;

    $ifElseFiCounter++;

    ${$self}{id} = "$tokens{ifElseFi}$ifElseFiCounter";
    return;
}

1;
