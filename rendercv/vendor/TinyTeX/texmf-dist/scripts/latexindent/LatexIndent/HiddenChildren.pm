package LatexIndent::HiddenChildren;

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
use LatexIndent::Switches qw/$is_t_switch_active $is_tt_switch_active $is_m_switch_active /;
use LatexIndent::Tokens qw/%tokens/;
use LatexIndent::LogFile qw/$logger/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use Data::Dumper;
use Exporter qw/import/;
our @EXPORT_OK
    = qw/find_surrounding_indentation_for_children update_family_tree get_family_tree check_for_hidden_children %familyTree hidden_children_preparation_for_alignment unpack_children_into_body/;

# hiddenChildren can be stored in a global array, it doesn't matter what level they're at
our %familyTree;
our %allChildren;

#----------------------------------------------------------
#   Discussion surrounding hidden children
#
#   Consider the following latex code
#
#   \begin{one}
#       body of one
#       body of one
#       body of one
#       \begin{two}
#          body of two
#          body of two
#          body of two
#          body of two
#       \end{two}
#   \end{one}
#
#   From the visual perspective, we might say that <one> and <two> are *nested* children;
#   from the perspective of latexindent.pl, however, they actually have *the same level*.
#
#   Graphically, you might represent it as follows
#
#                     *
#                   /  \
#                  /    \
#                 /      \
#                O        O
#
#   where * represents the 'root' document object, and each 'O' is an environment object; the
#   first one, on the left, represents <two> and the second one, on the right, represents <one>.
#   (Remember that the environment regexp does not allow \begin within its body.)
#
#   When processing the document, <one> will be processed *before* <two>. Furthermore, because
#   <one> and <two> are at the same level, they are not *natural* ancestors of each other; as such,
#   we say that <two> is a *hidden* child, and that its 'adopted' ancestor is <one>.
#
#   We need to go to a lot of effort to make sure that <two> knows about its ancestors and its
#   surrounding indentation (<one> in this case). The subroutines in this file do that effort.
#----------------------------------------------------------

sub find_surrounding_indentation_for_children {
    my $self = shift;

    # output to logfile
    $logger->trace("*FamilyTree before update:") if $is_tt_switch_active;
    $logger->trace( Dumper( \%familyTree ) ) if ($is_tt_switch_active);

    # update the family tree with ancestors
    $self->update_family_tree;

    # output information to the logfile
    $logger->trace("*FamilyTree after update:") if $is_tt_switch_active;
    $logger->trace( Dumper( \%familyTree ) ) if ($is_tt_switch_active);

    while ( my ( $idToSearch, $ancestorToSearch ) = each %familyTree ) {
        $logger->trace("*Hidden child ID: ,$idToSearch, here are its ancestors:") if $is_t_switch_active;
        foreach ( @{ ${$ancestorToSearch}{ancestors} } ) {
            $logger->trace("ID: ${$_}{ancestorID}") if ($is_t_switch_active);
            my $tmpIndentation
                = ref( ${$_}{ancestorIndentation} ) eq 'SCALAR'
                ? ${ ${$_}{ancestorIndentation} }
                : ${$_}{ancestorIndentation};
            $tmpIndentation = $tmpIndentation ? $tmpIndentation : q();
            $logger->trace("indentation: '$tmpIndentation'") if ($is_t_switch_active);
        }
    }

    return;
}

sub update_family_tree {
    my $self = shift;

    # loop through the hash
    $logger->trace("*Updating FamilyTree...") if $is_t_switch_active;
    while ( my ( $idToSearch, $ancestorToSearch ) = each %familyTree ) {
        $logger->trace("*current ID: $idToSearch") if ($is_t_switch_active);
        foreach ( @{ ${$ancestorToSearch}{ancestors} } ) {
            my $ancestorID = ${$_}{ancestorID};

            # construct the natural ancestors
            my $naturalAncestors = q();
            foreach ( @{ ${ $familyTree{$idToSearch} }{ancestors} } ) {
                $naturalAncestors .= "---" . ${$_}{ancestorID} if ( ${$_}{type} eq "natural" );
            }

            # we only need to update the family tree if the $ancestorID is *not* a natural
            # ancestor, otherwise everything will be taken care of by the natural ancestor
            if ( $naturalAncestors !~ m/$ancestorID/ ) {
                $logger->trace("ancestor: $ancestorID") if ($is_t_switch_active);
                if ( $familyTree{$ancestorID} ) {
                    $logger->trace("$ancestorID is a key within familyTree, grabbing its ancestors")
                        if ($is_t_switch_active);
                    foreach ( @{ ${ $familyTree{$ancestorID} }{ancestors} } ) {
                        $logger->trace("ancestor of *hidden* child: ${$_}{ancestorID}") if ($is_t_switch_active);
                        my $newAncestorId = ${$_}{ancestorID};
                        my $type;
                        if ( $naturalAncestors =~ m/$ancestorID/ ) {
                            $type = "natural";
                        }
                        else {
                            $type = "adopted";
                        }
                        my $matched
                            = grep { $_->{ancestorID} eq $newAncestorId } @{ ${ $familyTree{$idToSearch} }{ancestors} };
                        push(
                            @{ ${ $familyTree{$idToSearch} }{ancestors} },
                            {   ancestorID          => ${$_}{ancestorID},
                                ancestorIndentation => ${$_}{ancestorIndentation},
                                type                => $type
                            }
                        ) unless ($matched);
                    }
                }
                else {
                    $logger->trace("natural ancestors of $ancestorID: $naturalAncestors") if ($is_t_switch_active);
                    foreach ( @{ ${ $allChildren{$ancestorID} }{ancestors} } ) {
                        my $newAncestorId = ${$_}{ancestorID};
                        my $type;
                        if ( $naturalAncestors =~ m/$newAncestorId/ ) {
                            $type = "natural";
                        }
                        else {
                            $type = "adopted";
                        }
                        my $matched
                            = grep { $_->{ancestorID} eq $newAncestorId } @{ ${ $familyTree{$idToSearch} }{ancestors} };
                        unless ($matched) {
                            $logger->trace("ancestor of UNHIDDEN child: ${$_}{ancestorID}") if ($is_t_switch_active);
                            push(
                                @{ ${ $familyTree{$idToSearch} }{ancestors} },
                                {   ancestorID          => ${$_}{ancestorID},
                                    ancestorIndentation => ${$_}{ancestorIndentation},
                                    type                => $type
                                }
                            );
                        }
                    }
                }
            }
        }
    }

}

sub check_for_hidden_children {

    my $self = shift;

    my @matched;

    # grab the matches
    if ( $is_m_switch_active and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{huge} ne "overflow" ) {

        # if modifyLineBreaks is active, then the IDS can be split across lines
        my $ifElseFiSpecialBegin     = join( "\\R?\\h*", split( //, $tokens{ifelsefiSpecial} ) );
        my $BeginwithLineBreaks      = join( "\\R?\\h*", split( //, $tokens{beginOfToken} ) );
        my $EndwithLineBreaks        = join( "\\R?\\h*", split( //, $tokens{endOfToken} ) );
        my $BlankLinesWithLineBreaks = join( "\\R?\\h*", split( //, $tokens{blanklines} ) );
        @matched
            = ( ${$self}{body}
                =~ /(?!$BlankLinesWithLineBreaks)((?:$ifElseFiSpecialBegin)?$BeginwithLineBreaks[-a-z0-9\n]+?$EndwithLineBreaks)/ig
            );

        # remove line breaks and horizontal space from matches
        $_ =~ s/\R|\h//gs foreach (@matched);
    }
    else {
        @matched = ( ${$self}{body}
                =~ /((?:$tokens{ifelsefiSpecial})?$tokens{beginOfToken}.[-a-z0-9]+?$tokens{endOfToken})/igs );
    }

    # log file
    $logger->trace("*Hidden children check for ${$self}{name}") if $is_t_switch_active;
    $logger->trace( join( "|", @matched ) ) if $is_t_switch_active;

    my $naturalAncestors = ${$self}{naturalAncestors};

    # loop through the hidden children
    foreach my $match (@matched) {
        next if $match =~ m/$tokens{verbatim}/;

        # update the family tree with ancestors of self
        if ( ${$self}{ancestors} ) {
            foreach ( @{ ${$self}{ancestors} } ) {
                my $newAncestorId = ${$_}{ancestorID};
                unless ( grep { $_->{ancestorID} eq $newAncestorId } @{ ${ $familyTree{$match} }{ancestors} } ) {
                    my $type = ( $naturalAncestors =~ m/${$_}{ancestorID}/ ) ? "natural" : "adopted";
                    $logger->trace("Adding ${$_}{ancestorID} to the $type family tree of $match")
                        if ($is_t_switch_active);
                    push(
                        @{ $familyTree{$match}{ancestors} },
                        {   ancestorID          => ${$_}{ancestorID},
                            ancestorIndentation => ${$_}{ancestorIndentation},
                            type                => $type
                        }
                    );
                }
            }
        }

        # update the family tree with self
        unless ( grep { $_->{ancestorID} eq ${$self}{id} } @{ ${ $familyTree{$match} }{ancestors} } ) {
            my $type = ( $naturalAncestors =~ m/${$self}{id}/ ) ? "natural" : "adopted";
            $logger->trace("Adding ${$self}{id} to the $type family tree of hiddenChild $match")
                if ($is_t_switch_active);
            push(
                @{ $familyTree{$match}{ancestors} },
                { ancestorID => ${$self}{id}, ancestorIndentation => ${$self}{indentation}, type => $type }
            );

            if ( ${$self}{lookForAlignDelims} ) {
                $logger->trace("$match needs measuring for ${$self}{name} (see lookForAlignDelims)")
                    if ($is_t_switch_active);
                push( @{ ${$self}{measureHiddenChildren} }, $match );
            }
        }
    }

}

#
# AlignmentAtAmpersand routine calculations are below
#
# PURPOSE:
#
# Consider the following example, which contains hidden children
#
#     \begin{align}
#     	A & =\begin{array}{cc}      % <!--- Hidden child
#     		     BBB & CCC \\       % <!--- Hidden child
#     		     E   & F            % <!--- Hidden child
#     	     \end{array} \\         % <!--- Hidden child
#
#     	Z & =\begin{array}{cc}      % <!--- Hidden child
#     		     Y & X \\           % <!--- Hidden child
#     		     W & V              % <!--- Hidden child
#     	     \end{array}            % <!--- Hidden child
#     \end{align}
#
# the approach that we adopt is:
#
#   1. for the *original* object  (align in the above), we loop through
#       its hidden children (array in the above) and unpack their contents
#       for measuring
#
#       see hidden_children_preparation_for_alignment
#           unpack_children_into_body
#
#   2. we store the unpacked body in the familyTree hash, using 'bodyForMeasure'
#
#       see $familyTree{${$_}{id}}{bodyForMeasure} = $bodyForMeasure;
#
#   3. during the alignment routine, we use 'bodyForMeasure' for measuring the cells
#
sub hidden_children_preparation_for_alignment {

    my $self              = shift;
    my $latexIndentObject = shift;
    for my $hiddenChildToMeasure ( @{ ${$latexIndentObject}{measureHiddenChildren} } ) {
        for ( @{ ${$self}{children} } ) {
            if ( ${$_}{id} eq $hiddenChildToMeasure ) {

                my $bodyForMeasure = ${$_}{begin} . ${$_}{body} . ${$_}{end};
                for my $child ( ${$_}{children} ) {
                    $bodyForMeasure = &unpack_children_into_body( \@{$child}, $bodyForMeasure );
                }
                $familyTree{ ${$_}{id} }{bodyForMeasure} = $bodyForMeasure;
            }
        }
    }
    return;
}

sub unpack_children_into_body {
    my $child = shift;
    my $body  = shift;
    for my $individualChild ( @{$child} ) {
        $body
            =~ s/${$individualChild}{id}/${$individualChild}{begin}${$individualChild}{body}${$individualChild}{end}/s;

        if ( ${$individualChild}{children} ) {
            for my $nextlevelchild ( ${$individualChild}{children} ) {
                $body = &unpack_children_into_body( \@{$nextlevelchild}, $body );
            }
        }
    }
    return $body;
}

1;
