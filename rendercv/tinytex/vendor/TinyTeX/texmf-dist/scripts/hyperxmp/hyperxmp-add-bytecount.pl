#!/usr/bin/env perl
use warnings;

#############################################################
#############################################################

########################################################################
# hyperxmp-add-bytecount                                               #
#   Adds/updates byteCount specification in XMP packet in pdf file(s)  #
#   made by hyperxmp, with byteCount = file size.                      #
# Copyright (C) 2020-2022 John Collins <jcc8@psu.edu>                  #
#    and Scott Pakin, <scott+hyxmp@pakin.org>                          #
#                                                                      #
# This program may be distributed and/or modified under the conditions #
# of the LaTeX Project Public License, either version 1.3c of this     #
# license or (at your option) any later version.                       #
#                                                                      #
# The latest version of this license is in:                            #
#                                                                      #
#    http://www.latex-project.org/lppl.txt                             #
#                                                                      #
# and version 1.3c or later is part of all distributions of LaTeX      #
# version 2008/05/04 or later.                                         #
########################################################################

$name = 'hyperref-add-bytecount';
$version = '1.1-2020-11-20';
$maintainer
    = 'John Collins, jcc8@psu.edu; Scott Pakin, scott+hyxmp@pakin.org';

my $exit_code = 0;

if ( (! @ARGV) || ($ARGV[0] =~ /^(-|--)(h|help)$/)  ) {
    print "$name  $version.\n",
        "Usage: $name [options] pdf_filename(s)\n",
        "  Adds/updates byteCount specification in XMP packet in pdf file(s) from\n",
        "  hyperxmp, with byteCount = file size.\n",
        "  No change if there's no XMP packet of the form produced by hyperxmp.\n",
        "Options:\n",
        "  -help or -h      Output usage information.\n",
        "  -version or -v   Output version information.\n",
        "Bug reports to:\n  $maintainer.\n";
    exit;
} elsif ( $ARGV[0] =~ /^(-|--)(v|version)$/  ) {
    print "$name $version.\n",
          "Bug reports to:\n  $maintainer.\n";
    exit;
}

foreach (@ARGV) {
    if ( ! fix_pdf($_) ) { $exit_code = 1; }
}

exit $exit_code;

#======================================================

sub fix_pdf {
  # Change/insert byteCount field with correct file length, while preserving
  # the file size and the length of the stream containing xmp metadata.
  # Return 1 on success, else 0.

  local $pdf_name = shift;
  local $tmp_name = "$pdf_name.new.pdf";
  local $pdf_size  = (stat($pdf_name))[7];
  warn "Inserting/correcting byteCount field in '$pdf_name' ...\n";

  # Strings surrounding (and identifying) the byteCount field, and other
  # parts of the xmp packet:
  local $xmp_start = '<x:xmpmeta xmlns:x="adobe:ns:meta/">';
  local $decl_bC = '<pdfaProperty:name>byteCount</pdfaProperty:name>';
  local $pre_bC = '<prism:byteCount>';
  local $post_bC = '</prism:byteCount>';
  local $pC = '<prism:pageCount>';
  local $rd_end = '</rdf:Description>';
  local $xmp_end = '</x:xmpmeta>';

  local *PDF;
  local *TMP;

  if (! open PDF, "<", $pdf_name ) {
      warn "  Cannot read '$pdf_name'\n";
      return 0;
  }
  if ( ! open TMP, ">", $tmp_name ) {
      warn "  Cannot write temporary file '$tmp_name'\n";
      close PDF;
      return 0;
  }
  local $status = 0;  # 0 = no XMP packet, 1 = success, >= errors
  while ( <PDF> ) {
      # Only examine first XMP packet:
      if ( ($status == 0)  &&  /^\s*\Q$xmp_start\E/ ) {
         local @xmp = $_;
         local $len_padding = 0;
         local $xmp_after_line = '';
         &xmp_get_mod;
         print TMP @xmp;
         # Insert correct padding to leave file size unchanged:
         while ( $len_padding > 0 ) {
             my $len_line = 64;
             if ( $len_line > $len_padding ) { $len_line = $len_padding; }
             $len_padding -= $len_line;
             print TMP (' ' x ($len_line - 1) ), "\n";
         }
         print TMP $xmp_after_line;
         $xmp_after_line = '';
     }
     else {
         print TMP "$_";
     }
  }
  close PDF;
  close TMP;

  if ($status == 0) {
      warn "  Could not insert/modify byteCount, since no XMP packet was found.\n";
      warn "  So '$pdf_name' is unchanged,\n",
           "  and I will delete temporary file '$tmp_name'.\n";
      unlink $tmp_name;
  } elsif ($status == 1)  {
      rename $tmp_name, $pdf_name
        or die "  Cannot move temporary file '$tmp_name' to '$pdf_name'.\n",
               "  Error is '$!'\n";
  } else {
      warn "  Could not insert correct byteCount. See above for reason.\n";
      warn "  So '$pdf_name' is unchanged,\n",
           "  and I will delete temporary file '$tmp_name'.\n";
      unlink $tmp_name;
  }
  return ($status == 1);
}

#======================================================

sub xmp_get_mod {
    # Get xmp packet, given that @xmp contains its first line.
    # Get amount of trailing padding, and line after that.
    # If possible, insert a byteCount field:
    #    Either replace existing specification, if it exists,
    #    or insert one in expected place for hyperxmp, if the XMP packet
    #      matches what hyperxmp would produce.
    # Return xmp packet in @xmp, amount of padding needed in $len_padding,
    # line after that in $xmp_after_line, and error code in $error.
    # Set $status appropriately: 1 for success; >=1 for failure.

    $len_padding = 0;
    $xmp_after_line = '';

    my $bC_index = -1;
    my $xmp_end_found = 0;
    my $decl_bC_found = 0;
    while ( <PDF> ) {
        push @xmp, $_;
        if ( /^\s*\Q$xmp_end\E/ ) {
            $xmp_end_found = 1;
            # Get amount of padding;
            while (<PDF>) {
                if ( /^\s*$/ ) {
                    $len_padding += length($_);
                } else {
                    $xmp_after_line = $_;
                    last;
                }
            }
            last;
        }
        elsif ( $bC_index >= 0 ){
            next;
        }
        # Rest of conditions only apply if no place yet found for byteCount
        # specification.
        elsif ( /^(\s*)\Q$pre_bC\E.*?\Q$post_bC\E\s*$/ ) {
            $bC_index = $#xmp;
        }
        elsif ( /^\s*\Q$decl_bC\E/ ) {
            $decl_bC_found = 1;
        }
        elsif ( /^(\s*)\Q$rd_end\E/ ){
            # End of rdf:Description block.
            # So having previous declaration of byteCount is irrelevant.
            $decl_bC_found = 0;
        }
        elsif ( $decl_bC_found  &&  /^(\s*)\Q$pC\E/ ){
            $bC_index = $#xmp;
            pop @xmp;
            push @xmp, '', $_;
        }

    } # End reading of XMP

    if ($bC_index < 0) {
        if ( ! $xmp_end_found ) {
            warn "  End of XMP packet not found.\n";
            $status = 2;
        }
        elsif ( ! $decl_bC_found ) {
            warn "  XMP packet not in appropriate hyperxmp-compatible format.\n";
            $status = 3;
        }
        return;
    }
    my $new_line = '      ' . $pre_bC . $pdf_size . $post_bC . "\n";
    my $old_line = $xmp[$bC_index];
    my $delta_len = length($new_line) - length($old_line);
    if ($delta_len > $len_padding) {
        warn "  Cannot get padding correct for '$pdf_name'.\n",
             "    Length change of bC line = $delta_len; ",
             "    Padding bytes available = $len_padding.\n";
        $status = 4;
        return;
    } else {
        $len_padding -= $delta_len;
        $xmp[$bC_index] = $new_line;
        $status = 1;
    }
}

#======================================================
