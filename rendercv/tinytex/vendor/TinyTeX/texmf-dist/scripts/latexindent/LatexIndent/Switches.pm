package LatexIndent::Switches;

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
use Exporter qw/import/;
our @EXPORT_OK
    = qw/%switches store_switches $is_m_switch_active $is_t_switch_active $is_tt_switch_active $is_r_switch_active $is_rr_switch_active $is_rv_switch_active $is_check_switch_active $is_check_verbose_switch_active/;
our %switches;
our $is_m_switch_active;
our $is_t_switch_active;
our $is_tt_switch_active;
our $is_r_switch_active;
our $is_rr_switch_active;
our $is_rv_switch_active;
our $is_check_switch_active;
our $is_check_verbose_switch_active;

sub store_switches {
    my $self = shift;

    # copy document switches into hash local to this module
    %switches = %{ ${$self}{switches} };
    $switches{version}   = defined $switches{vversion}         ? 1                           : $switches{version};
    $is_m_switch_active  = defined $switches{modifyLineBreaks} ? $switches{modifyLineBreaks} : 0;
    $is_t_switch_active  = defined $switches{trace}            ? $switches{trace}            : 0;
    $is_tt_switch_active = defined $switches{ttrace}           ? $switches{ttrace}           : 0;
    $is_t_switch_active  = $is_tt_switch_active                ? $is_tt_switch_active        : $is_t_switch_active;
    $is_r_switch_active  = defined $switches{replacement}      ? $switches{replacement}      : 0;
    $is_rr_switch_active = defined $switches{onlyreplacement}  ? $switches{onlyreplacement}  : 0;
    $is_rv_switch_active = defined $switches{replacementRespectVerb} ? $switches{replacementRespectVerb} : 0;
    $is_r_switch_active
        = ( $is_rr_switch_active | $is_rv_switch_active )
        ? ( $is_rr_switch_active | $is_rv_switch_active )
        : $is_r_switch_active;
    $is_check_switch_active         = defined $switches{check}        ? $switches{check}        : 0;
    $is_check_verbose_switch_active = defined $switches{checkverbose} ? $switches{checkverbose} : 0;
    $is_check_switch_active
        = $is_check_verbose_switch_active ? $is_check_verbose_switch_active : $is_check_switch_active;
    delete ${$self}{switches};
}
1;
