package LatexIndent::FileExtension;

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
use PerlIO::encoding;
use open ':std', ':encoding(UTF-8)';
use File::Basename;    # to get the filename and directory path
use Exporter qw/import/;
use Encode qw/decode/;
use LatexIndent::GetYamlSettings qw/%mainSettings/;
use LatexIndent::Switches qw/%switches $is_check_switch_active/;
use LatexIndent::LogFile qw/$logger/;
our @EXPORT_OK = qw/file_extension_check/;

sub file_extension_check {
    my $self = shift;

    # grab the filename
    my $fileName = ${$self}{fileName};

    # see if an extension exists for the fileName
    my ( $name, $dir, $ext ) = fileparse( $fileName, qr/\..[^.]*$/ );

    # grab the file extension preferences
    my %fileExtensionPreference = %{ $mainSettings{fileExtensionPreference} };

    # sort the file extensions by preference
    my @fileExtensions
        = sort { $fileExtensionPreference{$a} <=> $fileExtensionPreference{$b} } keys(%fileExtensionPreference);

    # store the base name
    ${$self}{baseName} = $name;

    # if no extension, search according to fileExtensionPreference
    if ( $fileName ne "-" ) {
        if ( !$ext ) {
            $logger->info("*File extension work:");
            $logger->info(
                "latexindent called to act upon $fileName without a file extension;\nsearching for files in the following order (see fileExtensionPreference):"
            );
            $logger->info( $fileName . join( "\n$fileName", @fileExtensions ) );

            my $fileFound = 0;

            # loop through the known file extensions (see @fileExtensions)
            foreach (@fileExtensions) {
                if ( -e $fileName . $_ ) {
                    $logger->info("$fileName$_ found!");
                    $fileName .= $_;
                    $logger->info("Updated fileName to $fileName");
                    ${$self}{fileName} = $fileName;
                    $fileFound = 1;
                    $ext       = $_;
                    last;
                }
            }
            unless ($fileFound) {
                if ( defined ${$self}{multipleFiles} ) {
                    $logger->warn(
                        "*I couldn't find a match for $fileName in fileExtensionPreference (see defaultSettings.yaml)");
                    $logger->warn("moving on, no indentation done for ${$self}{fileName}.");
                    return 3;
                }
                else {
                    $logger->fatal(
                        "*I couldn't find a match for $fileName in fileExtensionPreference (see defaultSettings.yaml)");
                    foreach (@fileExtensions) {
                        $logger->fatal("I searched for $fileName$_");
                    }
                    $logger->fatal("but couldn't find any of them.\nConsider updating fileExtensionPreference.");
                    $logger->fatal("*Exiting, no indentation done.");
                    $self->output_logfile();
                    exit(3);
                }
            }
        }
        else {
            # if the file has a recognised extension, check that the file exists
            unless ( -e $fileName ) {
                if ( defined ${$self}{multipleFiles} ) {
                    $logger->warn("*I couldn't find $fileName, are you sure it exists?");
                    $logger->warn("moving on, no indentation done for ${$self}{fileName}.");
                    return 3;
                }
                else {
                    $logger->fatal("*I couldn't find $fileName, are you sure it exists?");
                    $logger->fatal("Exiting, no indentation done.");
                    $self->output_logfile();
                    exit(3);
                }
            }
        }
    }

    # store the file extension
    ${$self}{fileExtension} = $ext;

    # check to see if -o switch is active
    if ( $switches{outputToFile} ) {

        $logger->info("*-o switch active: output file check");

        # diacritics in file names (highlighted in https://github.com/cmhughes/latexindent.pl/pull/439)
        #
        # note, related:
        #
        #   git config --add core.quotePath false
        ${$self}{outputToFile} = decode( "utf-8", $switches{outputToFile} );

        if ( $fileName eq "-" and $switches{outputToFile} =~ m/^\+/ ) {
            $logger->info("STDIN input mode active, -o switch is removing all + symbols");
            ${$self}{outputToFile} =~ s/\+//g;
        }

        # the -o file name might begin with a + symbol
        if ( $switches{outputToFile} =~ m/^\+(.*)/ and $1 ne "+" ) {
            $logger->info("-o switch called with + symbol at the beginning: ${$self}{outputToFile}");
            ${$self}{outputToFile} = decode( "utf-8", ${$self}{baseName} . $1 );
            $logger->info("output file is now: ${$self}{outputToFile}");
        }

        my $strippedFileExtension = ${$self}{fileExtension};
        $strippedFileExtension =~ s/\.//;
        $strippedFileExtension = "tex" if ( $strippedFileExtension eq "" );

        # grab the name, directory, and extension of the output file
        my ( $name, $dir, $ext ) = fileparse( ${$self}{outputToFile}, $strippedFileExtension );

        # if there is no extension, then add the extension from the file to be operated upon
        if ( !$ext ) {
            $logger->info(
                "-o switch called with file name without extension: " . decode( "utf-8", $switches{outputToFile} ) );
            ${$self}{outputToFile} = $name . ( $name =~ m/\.\z/ ? q() : "." ) . $strippedFileExtension;
            $logger->info(
                "Updated to ${$self}{outputToFile} as the file extension of the input file is $strippedFileExtension");
        }

        # the -o file name might end with ++ in which case we wish to search for existence,
        # and then increment accordingly
        $name =~ s/\.$//;
        if ( $name =~ m/\+\+$/ ) {
            $logger->info("-o switch called with file name ending with ++: ${$self}{outputToFile}");
            $name =~ s/\+\+$//;
            $name = ${$self}{baseName} if ( $name eq "" );
            my $outputFileCounter = 0;
            my $fileName          = $name . $outputFileCounter . "." . $strippedFileExtension;
            $logger->info("will search for existence and increment counter, starting with $fileName");
            while ( -e $fileName ) {
                $logger->info("$fileName exists, incrementing counter");
                $outputFileCounter++;
                $fileName = $name . $outputFileCounter . "." . $strippedFileExtension;
            }
            $logger->info("$fileName does not exist, and will be the output file");
            ${$self}{outputToFile} = $fileName;
        }
    }

    # read the file into the Document body
    my @lines;
    if ( $fileName ne "-" ) {
        my $openFilePossible = 1;
        open( MAINFILE, $fileName ) or ( $openFilePossible = 0 );
        if ( $openFilePossible == 0 ) {
            if ( defined ${$self}{multipleFiles} ) {
                $logger->warn("*$fileName exists, but could not open it");
                $logger->warn("moving on, no indentation done for $fileName");
                return 4;
            }
            else {
                $logger->fatal("*$fileName exists, but could not open it");
                $logger->fatal("Exiting, no indentation done.");
                $self->output_logfile();
                exit(4);
            }
        }
        push( @lines, $_ ) while (<MAINFILE>);
        close(MAINFILE);
    }
    else {
        push( @lines, $_ ) while (<>);
    }

    # -n, --lines mode active
    if ( $switches{lines} ) {
        $self->lines_body_selected_lines( \@lines );
    }
    else {
        # the all-important step: update the body
        ${$self}{body} = join( "", @lines );
    }

    # necessary extra storage if
    #
    #   check switch is active
    #
    # or
    #
    #   $switches{overwriteIfDifferent}
    #
    if ( $is_check_switch_active or $switches{overwriteIfDifferent} ) {
        ${$self}{originalBody} = ${$self}{body};
    }

    return 0;
}
1;
