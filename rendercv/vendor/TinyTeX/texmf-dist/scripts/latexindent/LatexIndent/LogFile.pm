package LatexIndent::LogFile;

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
use FindBin;
use File::Basename;    # to get the filename and directory path
use File::Path qw(make_path);
use Exporter qw/import/;
use LatexIndent::Switches qw/%switches/;
use LatexIndent::Version qw/$versionNumber $versionDate/;
use Encode qw/decode/;
our @EXPORT_OK = qw/process_switches $logger/;
our $logger;

sub process_switches {

    # -v switch is just to show the version number
    if ( $switches{version} ) {
        print $versionNumber, ", ", $versionDate, "\n";
        if ( $switches{vversion} ) {
            print "$FindBin::Script lives here: $FindBin::RealBin/$FindBin::Script\n";
            if ( -e "$FindBin::RealBin/defaultSettings.yaml" ) {
                print "defaultSettings.yaml lives here $FindBin::RealBin/defaultSettings.yaml\n";
            }
            elsif ( -e "$FindBin::RealBin/../../texmf-dist/scripts/latexindent/defaultSettings.yaml" ) {
                print
                    "defaultSettings.yaml lives here $FindBin::RealBin/../../texmf-dist/scripts/latexindent/defaultSettings.yaml\n";
            }
            elsif ( -e "$FindBin::RealBin/LatexIndent/defaultSettings.yaml" ) {
                print "defaultSettings.yaml lives here $FindBin::RealBin/LatexIndent/defaultSettings.yaml\n";
            }
            print "project home: https://github.com/cmhughes/latexindent.pl\n";
        }
        exit(0);
    }

    if ( scalar(@ARGV) < 1 or $switches{showhelp} ) {
        print <<ENDQUOTE
latexindent.pl version $versionNumber, $versionDate
usage: latexindent.pl [options] [file]
      -v, --version
          displays the version number and date of release
      -vv, --vversion
          displays verbose version details: the version number, date of release, 
          and location details of latexindent.pl and defaultSettings.yaml
      -h, --help
          help (see the documentation for detailed instructions and examples)
      -sl, --screenlog
          log file will also be output to the screen
      -o, --outputfile=<name-of-output-file>
          output to another file; sample usage:
                latexindent.pl -o outputfile.tex myfile.tex
                latexindent.pl -o=outputfile.tex myfile.tex
      -w, --overwrite
          overwrite the current file; a backup will be made, but still be careful
      -wd, --overwriteIfDifferent
          overwrite the current file IF the indented text is different from original; 
          a backup will be made, but still be careful
      -s, --silent
          silent mode: no output will be given to the terminal
      -t, --trace
          tracing mode: verbose information given to the log file
      -l, --local[=myyaml.yaml]
          use `localSettings.yaml`, `.localSettings.yaml`, `latexindent.yaml`,
          or `.latexindent.yaml` (assuming one of them exists in the directory of your file or in
          the current working directory); alternatively, use `myyaml.yaml`, if it exists;
          sample usage:
                latexindent.pl -l some.yaml myfile.tex
                latexindent.pl -l=another.yaml myfile.tex
                latexindent.pl -l=some.yaml,another.yaml myfile.tex
      -y, --yaml=<yaml settings>
          specify YAML settings; sample usage:
                latexindent.pl -y="defaultIndent:' '" myfile.tex
                latexindent.pl -y="defaultIndent:' ',maximumIndentation:' '" myfile.tex
      -d, --onlydefault
          ONLY use defaultSettings.yaml, ignore ALL (yaml) user files
      -g, --logfile=<name of log file>
          used to specify the name of logfile (default is indent.log)
      -c, --cruft=<cruft directory>
          used to specify the location of backup files and indent.log
      -m, --modifylinebreaks
          modify linebreaks before, during, and at the end of code blocks;
          trailing comments and blank lines can also be added using this feature
      -r, --replacement
          replacement mode, allows you to replace strings and regular expressions
          verbatim blocks not respected
      -rv, --replacementrespectverb
          replacement mode, allows you to replace strings and regular expressions
          while respecting verbatim code blocks
      -rr, --onlyreplacement
          *only* replacement mode, no indentation;
          verbatim blocks not respected
      -k, --check mode
          will exit with 0 if document body unchanged, 1 if changed
      -kv, --check mode verbose
          as in check mode, but outputs diff to screen as well as to logfile
      -n, --lines=<MIN-MAX>
          only operate on selected lines; sample usage:
                latexindent.pl --lines 3-5 myfile.tex
                latexindent.pl --lines 3-5,7-10 myfile.tex
      --GCString
          loads the Unicode::GCString module for the align-at-ampersand routine
          Note: this requires the Unicode::GCString module to be installed on your system
ENDQUOTE
            ;
        exit(0);
    }

    # if we've made it this far, the processing of switches and logging begins
    my $self      = shift;
    my @fileNames = @{ $_[0] };

    $logger = LatexIndent::Logger->new();

    # cruft directory
    ${$self}{cruftDirectory} = $switches{cruftDirectory} || ( dirname ${$self}{fileName} );

    my $cruftDirectoryCreation = 0;

    # if cruft directory does not exist, create it
    if ( !( -d ${$self}{cruftDirectory} ) ) {
        eval { make_path( ${$self}{cruftDirectory} ) };
        if ($@) {
            $logger->fatal( "*Could not create cruft directory " . decode( "utf-8", ${$self}{cruftDirectory} ) );
            $logger->fatal("Exiting, no indentation done.");
            $self->output_logfile();
            exit(6);
        }
        $cruftDirectoryCreation = 1;
    }

    my $logfileName = ( $switches{cruftDirectory} ? ${$self}{cruftDirectory} . "/" : '' )
        . ( $switches{logFileName} || "indent.log" );

    $logfileName = decode( "utf-8", $logfileName );

    # details of the script to log file
    $logger->info("*$FindBin::Script version $versionNumber, $versionDate, a script to indent .tex files");
    $logger->info("$FindBin::Script lives here: $FindBin::RealBin/");

    my $time = localtime();
    $logger->info($time);

    if ( ${$self}{fileName} ne "-" ) {

        # multiple filenames or not
        if ( ( scalar(@fileNames) ) > 1 ) {
            $logger->info("Filenames:");
            foreach (@fileNames) {
                $logger->info("   $_");
            }
            $logger->info( "total number of files: " . ( scalar(@fileNames) ) );
        }
        else {
            $logger->info("Filename: ${$self}{fileName}");
        }
    }
    else {
        $logger->info("Reading input from STDIN");
        if ( -t STDIN ) {
            my $buttonText = ( $FindBin::Script eq 'latexindent.exe' ) ? 'CTRL+Z followed by ENTER' : 'CTRL+D';
            print STDERR "Please enter text to be indented: (press $buttonText when finished)\n";
        }
    }

    # log the switches from the user
    $logger->info("*Processing switches:");

    # check on the trace mode switch (should be turned on if ttrace mode active)
    $switches{trace} = $switches{ttrace} ? 1 : $switches{trace};

    # output details of switches
    $logger->info("-sl|--screenlog: log file will also be output to the screen") if ( $switches{screenlog} );
    $logger->info("-t|--trace: Trace mode active (you have used either -t or --trace)")
        if ( $switches{trace} and !$switches{ttrace} );
    $logger->info("-tt|--ttrace: TTrace mode active (you have used either -tt or --ttrace)") if ( $switches{ttrace} );
    $logger->info("-s|--silent: Silent mode active (you have used either -s or --silent)") if ( $switches{silentMode} );
    $logger->info("-d|--onlydefault: Only defaultSettings.yaml will be used (you have used either -d or --onlydefault)")
        if ( $switches{onlyDefault} );
    $logger->info("-w|--overwrite: Overwrite mode active, will make a back up before overwriting")
        if ( $switches{overwrite} );
    $logger->info("-wd|--overwriteIfDifferent: will overwrite ONLY if indented text is different")
        if ( $switches{overwriteIfDifferent} );
    $logger->info("-l|--localSettings: Read localSettings YAML file")               if ( $switches{readLocalSettings} );
    $logger->info("-y|--yaml: YAML settings specified via command line")            if ( $switches{yaml} );
    $logger->info("-o|--outputfile: output to file")                                if ( $switches{outputToFile} );
    $logger->info("-m|--modifylinebreaks: modify line breaks")                      if ( $switches{modifyLineBreaks} );
    $logger->info("-g|--logfile: logfile name")                                     if ( $switches{logFileName} );
    $logger->info("-c|--cruft: cruft directory")                                    if ( $switches{cruftDirectory} );
    $logger->info("-r|--replacement: replacement mode")                             if ( $switches{replacement} );
    $logger->info("-rr|--onlyreplacement: *only* replacement mode, no indentation") if ( $switches{onlyreplacement} );
    $logger->info("-k|--check mode: will exit with 0 if document body unchanged, 1 if changed") if ( $switches{check} );
    $logger->info("-kv|--check mode verbose: as in check mode, but outputs diff to screen")
        if ( $switches{checkverbose} );
    $logger->info("-n|--lines mode: will only operate on specific lines $switches{lines}") if ( $switches{lines} );
    $logger->info("--GCString switch active, loading Unicode::GCString module")            if ( $switches{GCString} );

    # check if overwrite and outputfile are active similtaneously
    if ( $switches{overwrite} and $switches{outputToFile} ) {
        $logger->info("*Options check: -w and -o specified");
        $logger->info("You have called latexindent.pl with both -o and -w");
        $logger->info("The -o switch will take priority, and -w (overwrite) will be ignored");
        $switches{overwrite} = 0;
    }

    # check if overwrite and outputfile are active similtaneously
    if ( $switches{overwrite} and $switches{overwriteIfDifferent} ) {
        $logger->info("*Options check: -w and -wd specified");
        $logger->info("You have called latexindent.pl with both -w and -wd.");
        $logger->info("The -wd switch will take priority, and -w (overwrite) will be ignored");
        $switches{overwrite} = 0;
    }

    # check if overwriteIfDifferent and outputfile are active similtaneously
    if ( $switches{overwriteIfDifferent} and $switches{outputToFile} ) {
        $logger->info("*Options check: -wd and -o specified");
        $logger->info("You have called latexindent.pl with both -o and -wd");
        $logger->info("The -o switch will take priority, and -wd (overwriteIfDifferent) will be ignored");
        $switches{overwriteIfDifferent} = 0;
    }

    # multiple files with the -o switch needs care
    #
    # example
    #
    #       latexindent.pl *.tex -o myfile.tex
    #
    # would result in only the final file being written to myfile.tex
    #
    # So, if -o switch does *not* match having a + symbol at the beginning, then
    # we ignore it, and turn it off
    #
    if ( ( scalar @fileNames > 1 ) and $switches{outputToFile} and ( $switches{outputToFile} !~ m/^h*\+/ ) ) {
        $logger->warn("*-o switch specified as single file, but multiple files given as input");
        $logger->warn("ignoring your specification -o $switches{outputToFile}");
        $logger->warn("perhaps you might specify it using, for example, -o=++ or -o=+myoutput");
        $switches{outputToFile} = 0;
    }

    $logger->info("*Directory for backup files and $logfileName:");
    $logger->info( $switches{cruftDirectory} ? decode( "utf-8", ${$self}{cruftDirectory} ) : ${$self}{cruftDirectory} );
    $logger->info("cruft directory creation: ${$self}{cruftDirectory}") if $cruftDirectoryCreation;

    # output location of modules
    if ( $FindBin::Script eq 'latexindent.pl' or ( $FindBin::Script eq 'latexindent.exe' and $switches{trace} ) ) {
        my @listOfModules
            = ( 'FindBin', 'YAML::Tiny', 'File::Copy', 'File::Basename', 'Getopt::Long', 'File::HomeDir' );
        push( @listOfModules, 'Unicode::GCString' ) if $switches{GCString};

        $logger->info("*Perl modules are being loaded from the following directories:");
        foreach my $moduleName (@listOfModules) {
            ( my $file = $moduleName ) =~ s|::|/|g;
            $logger->info( $INC{ $file . '.pm' } );
        }
        $logger->info("*LatexIndent perl modules are being loaded from, for example:");
        ( my $file = 'LatexIndent::Document' ) =~ s|::|/|g;
        $logger->info( $INC{ $file . '.pm' } );
    }

    return;
}

1;
