package LatexIndent::GetYamlSettings;

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
use Data::Dumper;
use LatexIndent::Switches qw/%switches $is_m_switch_active $is_t_switch_active $is_tt_switch_active/;
use YAML::Tiny;        # interpret defaultSettings.yaml and other potential settings files
use File::Basename;    # to get the filename and directory path
use File::HomeDir;
use Cwd;
use Exporter qw/import/;
use LatexIndent::LogFile qw/$logger/;
our @EXPORT_OK
    = qw/yaml_read_settings yaml_modify_line_breaks_settings yaml_get_indentation_settings_for_this_object yaml_poly_switch_get_every_or_custom_value yaml_get_indentation_information yaml_get_object_attribute_for_indentation_settings yaml_alignment_at_ampersand_settings %mainSettings %previouslyFoundSettings/;

# Read in defaultSettings.YAML file
our $defaultSettings;

# master yaml settings is a hash, global to this module
our %mainSettings;

# previously found settings is a hash, global to this module
our %previouslyFoundSettings;

# default values for align at ampersand routine
our @alignAtAmpersandInformation = (
    { name => "lookForAlignDelims",               yamlname => "delims", default => 1 },
    { name => "alignDoubleBackSlash",             default  => 1 },
    { name => "spacesBeforeDoubleBackSlash",      default  => 1 },
    { name => "multiColumnGrouping",              default  => 0 },
    { name => "alignRowsWithoutMaxDelims",        default  => 1 },
    { name => "spacesBeforeAmpersand",            default  => 1 },
    { name => "spacesAfterAmpersand",             default  => 1 },
    { name => "justification",                    default  => "left" },
    { name => "alignFinalDoubleBackSlash",        default  => 0 },
    { name => "dontMeasure",                      default  => 0 },
    { name => "delimiterRegEx",                   default  => "(?<!\\\\)(&)" },
    { name => "delimiterJustification",           default  => "left" },
    { name => "leadingBlankColumn",               default  => -1 },
    { name => "lookForChildCodeBlocks",           default  => 1 },
    { name => "alignContentAfterDoubleBackSlash", default  => 0 },
    { name => "spacesAfterDoubleBackSlash",       default  => 1 },
);

sub yaml_read_settings {
    my $self = shift;

    # read the default settings
    $defaultSettings = YAML::Tiny->read("$FindBin::RealBin/defaultSettings.yaml")
        if ( -e "$FindBin::RealBin/defaultSettings.yaml" );

    # grab the logger object
    $logger->info("*YAML settings read: defaultSettings.yaml");
    $logger->info("Reading defaultSettings.yaml from $FindBin::RealBin/defaultSettings.yaml");
    my $myLibDir = dirname(__FILE__);

    my ( $name, $dir, $ext ) = fileparse( $INC{"LatexIndent/GetYamlSettings.pm"}, "pm" );
    $dir =~ s/\/$//;

    # if latexindent.exe is invoked from TeXLive, then defaultSettings.yaml won't be in
    # the same directory as it; we need to navigate to it
    if ( !$defaultSettings ) {
        $logger->info(
            "Reading defaultSettings.yaml (2nd attempt) from $FindBin::RealBin/../../texmf-dist/scripts/latexindent/defaultSettings.yaml"
        );
        $logger->info("and then, if necessary, $FindBin::RealBin/LatexIndent/defaultSettings.yaml");
        if ( -e "$FindBin::RealBin/../../texmf-dist/scripts/latexindent/defaultSettings.yaml" ) {
            $defaultSettings
                = YAML::Tiny->read("$FindBin::RealBin/../../texmf-dist/scripts/latexindent/defaultSettings.yaml");
        }
        elsif ( -e "$FindBin::RealBin/LatexIndent/defaultSettings.yaml" ) {
            $defaultSettings = YAML::Tiny->read("$FindBin::RealBin/LatexIndent/defaultSettings.yaml");
        }
        elsif ( -e "$dir/defaultSettings.yaml" ) {
            $defaultSettings = YAML::Tiny->read("$dir/defaultSettings.yaml");
        }
        elsif ( -e "$myLibDir/defaultSettings.yaml" ) {
            +$defaultSettings = YAML::Tiny->read("$myLibDir/defaultSettings.yaml");
        }
        else {
            $logger->fatal("*Could not open defaultSettings.yaml");
            $self->output_logfile();
            exit(2);
        }
    }

    # need to exit if we can't get defaultSettings.yaml
    if ( !$defaultSettings ) {
        $logger->fatal("*Could not open defaultSettings.yaml");
        $self->output_logfile();
        exit(2);
    }

    # master yaml settings is a hash, global to this module
    our %mainSettings = %{ $defaultSettings->[0] };

    &yaml_update_dumper_settings();

    # scalar to read user settings
    my $userSettings;

    # array to store the paths to user settings
    my @absPaths;

    # we'll need the home directory a lot in what follows
    my $homeDir = File::HomeDir->my_home;
    $logger->info("*YAML reading settings") unless $switches{onlyDefault};

    my $indentconfig = undef;
    if ( defined $ENV{LATEXINDENT_CONFIG} && !$switches{onlyDefault} ) {
        if ( -f $ENV{LATEXINDENT_CONFIG} ) {
            $indentconfig = $ENV{LATEXINDENT_CONFIG};
            $logger->info('The $LATEXINDENT_CONFIG variable was detected.');
            $logger->info( 'The value of $LATEXINDENT_CONFIG is: "' . $ENV{LATEXINDENT_CONFIG} . '"' );
        }
        else {
            $logger->warn('*The $LATEXINDENT_CONFIG variable is assigned, but does not point to a file!');
            $logger->warn( 'The value of $LATEXINDENT_CONFIG is: "' . $ENV{LATEXINDENT_CONFIG} . '"' );
        }
    }
    if ( !defined $indentconfig && !$switches{onlyDefault} ) {

# see all possible values of $^O here: https://perldoc.perl.org/perlport#Unix and https://perldoc.perl.org/perlport#DOS-and-Derivatives
        if ( $^O eq "linux" ) {
            if ( defined $ENV{XDG_CONFIG_HOME} && -f "$ENV{XDG_CONFIG_HOME}/latexindent/indentconfig.yaml" ) {
                $indentconfig = "$ENV{XDG_CONFIG_HOME}/latexindent/indentconfig.yaml";
                $logger->info( 'The $XDG_CONFIG_HOME variable and the config file in "'
                        . "$ENV{XDG_CONFIG_HOME}/latexindent/indentconfig.yaml"
                        . '" were recognized' );
                $logger->info( 'The value of $XDG_CONFIG_HOME is: "' . $ENV{XDG_CONFIG_HOME} . '"' );
            }
            elsif ( -f "$homeDir/.config/latexindent/indentconfig.yaml" ) {
                $indentconfig = "$homeDir/.config/latexindent/indentconfig.yaml";
                $logger->info(
                    'The config file in "' . "$homeDir/.config/latexindent/indentconfig.yaml" . '" will be read' );
            }
        }
        elsif ( $^O eq "darwin" ) {
            if ( -f "$homeDir/Library/Preferences/latexindent/indentconfig.yaml" ) {
                $indentconfig = "$homeDir/Library/Preferences/latexindent/indentconfig.yaml";
                $logger->info( 'The config file in "'
                        . "$homeDir/Library/Preferences/latexindent/indentconfig.yaml"
                        . '" will be read' );
            }
        }
        elsif ( $^O eq "MSWin32" || $^O eq "cygwin" ) {
            if ( defined $ENV{LOCALAPPDATA} && -f "$ENV{LOCALAPPDATA}/latexindent/indentconfig.yaml" ) {
                $indentconfig = "$ENV{LOCALAPPDATA}/latexindent/indentconfig.yaml";
                $logger->info( 'The $LOCALAPPDATA variable and the config file in "'
                        . "$ENV{LOCALAPPDATA}"
                        . '\latexindent\indentconfig.yaml" were recognized' );
                $logger->info( 'The value of $LOCALAPPDATA is: "' . $ENV{LOCALAPPDATA} . '"' );
            }
            elsif ( -f "$homeDir/AppData/Local/latexindent/indentconfig.yaml" ) {
                $indentconfig = "$homeDir/AppData/Local/latexindent/indentconfig.yaml";
                $logger->info( 'The config file in "'
                        . "$homeDir"
                        . '\AppData\Local\latexindent\indentconfig.yaml" will be read' );
            }
        }

        # if $indentconfig is still not defined, fallback to the location in $homeDir
        if ( !defined $indentconfig ) {

            # if all of these don't exist check home directly, with the non hidden file
            $indentconfig = ( -f "$homeDir/indentconfig.yaml" ) ? "$homeDir/indentconfig.yaml" : undef;

            # if indentconfig.yaml doesn't exist, check for the hidden file, .indentconfig.yaml
            if ( !defined $indentconfig ) {
                $indentconfig = ( -f "$homeDir/.indentconfig.yaml" ) ? "$homeDir/.indentconfig.yaml" : undef;
            }
            $logger->info( 'The config file in "' . "$indentconfig" . '" will be read' ) if defined $indentconfig;
        }
    }

    # messages for indentconfig.yaml and/or .indentconfig.yaml
    if ( defined $indentconfig and -f $indentconfig and !$switches{onlyDefault} ) {

        # read the absolute paths from indentconfig.yaml
        $userSettings = YAML::Tiny->read("$indentconfig");

        # update the absolute paths
        if ( $userSettings and ( ref( $userSettings->[0] ) eq 'HASH' ) and $userSettings->[0]->{paths} ) {
            $logger->info("Reading path information from $indentconfig");

            # output the contents of indentconfig to the log file
            $logger->info( Dump \%{ $userSettings->[0] } );

            # change the encoding of the paths according to the field `encoding`
            if ( $userSettings and ( ref( $userSettings->[0] ) eq 'HASH' ) and $userSettings->[0]->{encoding} ) {
                use Encode;
                my $encoding       = $userSettings->[0]->{encoding};
                my $encodingObject = find_encoding($encoding);

                # Check if the encoding is valid.
                if ( ref($encodingObject) ) {
                    $logger->info("*Encoding of the paths is $encoding");
                    foreach ( @{ $userSettings->[0]->{paths} } ) {
                        my $temp = $encodingObject->encode("$_");
                        $logger->info("Transform file encoding: $_ -> $temp");
                        push( @absPaths, $temp );
                    }
                }
                else {
                    $logger->warn("*encoding \"$encoding\" not found");
                    $logger->warn("Ignore this setting and will take the default encoding.");
                    @absPaths = @{ $userSettings->[0]->{paths} };
                }
            }
            else    # No such setting, and will take the default
            {
                # $logger->info("*Encoding of the paths takes the default.");
                @absPaths = @{ $userSettings->[0]->{paths} };
            }
        }
        else {
            $logger->warn(
                "*The paths field cannot be read from $indentconfig; this means it is either empty or contains invalid YAML"
            );
            $logger->warn(
                "See https://latexindentpl.readthedocs.io/en/latest/sec-indent-config-and-settings.html for an example"
            );
        }
    }
    else {
        if ( $switches{onlyDefault} ) {
            $logger->info("*-d switch active: only default settings requested");
            $logger->info("not reading USER settings from $indentconfig")
                if ( defined $indentconfig && -e $indentconfig );
            $logger->info("Ignoring the -l switch: $switches{readLocalSettings} (you used the -d switch)")
                if ( $switches{readLocalSettings} );
            $logger->info("Ignoring the -y switch: $switches{yaml} (you used the -d switch)") if ( $switches{yaml} );
            $switches{readLocalSettings} = 0;
            $switches{yaml}              = 0;
        }
        else {
            # give the user instructions on where to put the config file
            $logger->info("Home directory is $homeDir");
            $logger->info("latexindent.pl didn't find indentconfig.yaml or .indentconfig.yaml");
            $logger->info(
                "see all possible locations: https://latexindentpl.readthedocs.io/en/latest/sec-appendices.html#indentconfig-options)"
            );
        }
    }

    # default value of readLocalSettings
    #
    #       latexindent -l myfile.tex
    #
    # means that we wish to use localSettings.yaml
    if ( defined( $switches{readLocalSettings} ) and ( $switches{readLocalSettings} eq '' ) ) {
        $logger->info('*-l switch used without filename, will search for the following files in turn:');
        $logger->info('localSettings.yaml,latexindent.yaml,.localSettings.yaml,.latexindent.yaml');
        $switches{readLocalSettings} = 'localSettings.yaml,latexindent.yaml,.localSettings.yaml,.latexindent.yaml';
    }

    # local settings can be called with a + symbol, for example
    #     -l=+myfile.yaml
    #     -l "+ myfile.yaml"
    #     -l=myfile.yaml+
    # which translates to, respectively
    #     -l=localSettings.yaml,myfile.yaml
    #     -l=myfile.yaml,localSettings.yaml
    # Note: the following is *not allowed*:
    #     -l+myfile.yaml
    # and
    #     -l + myfile.yaml
    # will *only* load localSettings.yaml, and myfile.yaml will be ignored
    my @localSettings;

    $logger->info("*YAML settings read: -l switch") if $switches{readLocalSettings};

    # remove leading, trailing, and intermediate space
    $switches{readLocalSettings} =~ s/^\h*//g;
    $switches{readLocalSettings} =~ s/\h*$//g;
    $switches{readLocalSettings} =~ s/\h*,\h*/,/g;
    if ( $switches{readLocalSettings} =~ m/\+/ ) {
        $logger->info(
            "+ found in call for -l switch: will add localSettings.yaml,latexindent.yaml,.localSettings.yaml,.latexindent.yaml"
        );

        # + can be either at the beginning or the end, which determines if where the comma should go
        my $commaAtBeginning = ( $switches{readLocalSettings} =~ m/^\h*\+/ ? q() : "," );
        my $commaAtEnd       = ( $switches{readLocalSettings} =~ m/^\h*\+/ ? "," : q() );
        $switches{readLocalSettings} =~ s/\h*\+\h*/$commaAtBeginning
                    ."localSettings.yaml,latexindent.yaml,.localSettings.yaml,.latexindent.yaml"
                    .$commaAtEnd/ex;
        $logger->info("New value of -l switch: $switches{readLocalSettings}");
    }

    # local settings can be separated by ,
    # e.g
    #     -l = myyaml1.yaml,myyaml2.yaml
    # and in which case, we need to read them all
    if ( $switches{readLocalSettings} =~ m/,/ ) {
        $logger->info("Multiple localSettings found, separated by commas:");
        @localSettings = split( /,/, $switches{readLocalSettings} );
        $logger->info( join( ', ', @localSettings ) );
    }
    else {
        push( @localSettings, $switches{readLocalSettings} ) if ( $switches{readLocalSettings} );
    }

    my $workingFileLocation = dirname( ${$self}{fileName} );

    # add local settings to the paths, if appropriate
    foreach (@localSettings) {

        # check for an extension (.yaml)
        my ( $name, $dir, $ext ) = fileparse( $_, "yaml" );

        # if no extension is found, append the current localSetting with .yaml
        $_ = $_ . ( $_ =~ m/\.\z/ ? q() : "." ) . "yaml" if ( !$ext );

        # if the -l switch is called on its own, or else with +
        # and latexindent.pl is called from a different directory, then
        # we need to account for this
        if ( $_ =~ m/^[.]?(localSettings|latexindent)\.yaml$/ ) {

            # check for existence in the directory of the file.
            if ( ( -e $workingFileLocation . "/" . $_ ) ) {
                $_ = $workingFileLocation . "/" . $_;

                # otherwise we fallback to the current directory
            }
            elsif ( ( -e cwd() . "/" . $_ ) ) {
                $_ = cwd() . "/" . $_;
            }
        }

        # diacritics in YAML names (highlighted in https://github.com/cmhughes/latexindent.pl/pull/439)
        $_ = decode( "utf-8", $_ );

        # check for existence and non-emptiness
        if ( ( -e $_ ) and !( -z $_ ) ) {
            $logger->info("Adding $_ to YAML read paths");
            push( @absPaths, "$_" );
        }
        elsif ( !( -e $_ ) ) {
            if ((       $_ =~ m/localSettings|latexindent/s
                    and !( -e 'localSettings.yaml' )
                    and !( -e '.localSettings.yaml' )
                    and !( -e 'latexindent.yaml' )
                    and !( -e '.latexindent.yaml' )
                )
                or $_ !~ m/localSettings|latexindent/s
                )
            {
                $logger->warn("*yaml file not found: $_ not found. Proceeding without it.");
            }
        }
    }

    # heading for the log file
    $logger->info("*YAML settings, reading from the following files:") if @absPaths;

    # read in the settings from each file
    foreach my $settings (@absPaths) {

        # check that the settings file exists and that it isn't empty
        if ( -e $settings and !( -z $settings ) ) {
            $logger->info("Reading USER settings from $settings");
            $userSettings = YAML::Tiny->read("$settings");

            # if we can read userSettings
            if ($userSettings) {

                # update the MASTER settings to include updates from the userSettings
                while ( my ( $firstLevelKey, $firstLevelValue ) = each %{ $userSettings->[0] } ) {

                    # the update approach is slightly different for hashes vs scalars/arrays
                    if ( ref($firstLevelValue) eq "HASH" ) {
                        while ( my ( $secondLevelKey, $secondLevelValue )
                            = each %{ $userSettings->[0]{$firstLevelKey} } )
                        {
                            if ( ref $secondLevelValue eq "HASH" ) {

              # if mainSettings already contains a *scalar* value in secondLevelKey
              # then we need to delete it (test-cases/headings-first.tex with indentRules1.yaml first demonstrated this)
                                if ( defined $mainSettings{$firstLevelKey}{$secondLevelKey}
                                    and ref $mainSettings{$firstLevelKey}{$secondLevelKey} ne "HASH" )
                                {
                                    $logger->trace(
                                        "*mainSettings{$firstLevelKey}{$secondLevelKey} currently contains a *scalar* value, but it needs to be updated with a hash (see $settings); deleting the scalar"
                                    ) if ($is_t_switch_active);
                                    delete $mainSettings{$firstLevelKey}{$secondLevelKey};
                                }
                                while ( my ( $thirdLevelKey, $thirdLevelValue ) = each %{$secondLevelValue} ) {
                                    if ( ref $thirdLevelValue eq "HASH" ) {

                                        # similarly for third level
                                        if ( defined $mainSettings{$firstLevelKey}{$secondLevelKey}{$thirdLevelKey}
                                            and ref $mainSettings{$firstLevelKey}{$secondLevelKey}{$thirdLevelKey} ne
                                            "HASH" )
                                        {
                                            $logger->trace(
                                                "*mainSettings{$firstLevelKey}{$secondLevelKey}{$thirdLevelKey} currently contains a *scalar* value, but it needs to be updated with a hash (see $settings); deleting the scalar"
                                            ) if ($is_t_switch_active);
                                            delete $mainSettings{$firstLevelKey}{$secondLevelKey}{$thirdLevelKey};
                                        }
                                        while ( my ( $fourthLevelKey, $fourthLevelValue ) = each %{$thirdLevelValue} ) {
                                            $mainSettings{$firstLevelKey}{$secondLevelKey}{$thirdLevelKey}
                                                {$fourthLevelKey} = $fourthLevelValue;
                                        }
                                    }
                                    else {
                                        $mainSettings{$firstLevelKey}{$secondLevelKey}{$thirdLevelKey}
                                            = $thirdLevelValue;
                                    }
                                }
                            }
                            else {
                                # settings such as commandCodeBlocks can have arrays, which may wish
                                # to be amalgamated, rather than overwritten
                                if (    ref($secondLevelValue) eq "ARRAY"
                                    and ${ ${ $mainSettings{$firstLevelKey}{$secondLevelKey} }[0] }{amalgamate}
                                    and !(
                                            ref( ${$secondLevelValue}[0] ) eq "HASH"
                                        and defined ${$secondLevelValue}[0]{amalgamate}
                                        and !${$secondLevelValue}[0]{amalgamate}
                                    )
                                    )
                                {
                                    $logger->trace("*$firstLevelKey -> $secondLevelKey, amalgamate: 1")
                                        if ($is_t_switch_active);
                                    foreach ( @{$secondLevelValue} ) {
                                        $logger->trace("$_") if ($is_t_switch_active);
                                        push( @{ $mainSettings{$firstLevelKey}{$secondLevelKey} }, $_ )
                                            unless ( ref($_) eq "HASH" );
                                    }

# remove duplicated entries, https://stackoverflow.com/questions/7651/how-do-i-remove-duplicate-items-from-an-array-in-perl
                                    my %seen = ();
                                    my @unique
                                        = grep { !$seen{$_}++ } @{ $mainSettings{$firstLevelKey}{$secondLevelKey} };
                                    @{ $mainSettings{$firstLevelKey}{$secondLevelKey} } = @unique;

                                    $logger->trace(
                                        "*master settings for $firstLevelKey -> $secondLevelKey now look like:")
                                        if $is_t_switch_active;
                                    foreach ( @{ $mainSettings{$firstLevelKey}{$secondLevelKey} } ) {
                                        $logger->trace("$_") if ($is_t_switch_active);
                                    }
                                }
                                else {
                                    $mainSettings{$firstLevelKey}{$secondLevelKey} = $secondLevelValue;
                                }
                            }
                        }
                    }
                    elsif ( ref($firstLevelValue) eq "ARRAY" ) {

                        # update amalgamate in master settings
                        if ( ref( ${$firstLevelValue}[0] ) eq "HASH" and defined ${$firstLevelValue}[0]{amalgamate} ) {
                            ${ $mainSettings{$firstLevelKey}[0] }{amalgamate} = ${$firstLevelValue}[0]{amalgamate};
                            shift @{$firstLevelValue} if ${ $mainSettings{$firstLevelKey}[0] }{amalgamate};
                        }

                        # if amalgamate is set to 1, then append
                        if ( ${ $mainSettings{$firstLevelKey}[0] }{amalgamate} ) {

                            # loop through the other settings
                            foreach ( @{$firstLevelValue} ) {
                                push( @{ $mainSettings{$firstLevelKey} }, $_ );
                            }
                        }
                        else {
                            # otherwise overwrite
                            $mainSettings{$firstLevelKey} = $firstLevelValue;
                        }
                    }
                    else {
                        $mainSettings{$firstLevelKey} = $firstLevelValue;
                    }
                }

                # output settings to $logfile
                if ( $mainSettings{logFilePreferences}{showEveryYamlRead} ) {
                    $logger->info( Dump \%{ $userSettings->[0] } );
                }
                else {
                    $logger->info(
                        "Not showing settings in the log file (see showEveryYamlRead and showAmalgamatedSettings).");
                }

                # warning to log file if modifyLineBreaks specified and m switch not active
                if ( ${ $userSettings->[0] }{modifyLineBreaks} and !$is_m_switch_active ) {
                    $logger->warn("*modifyLineBreaks specified and m switch is *not* active");
                    $logger->warn("perhaps you intended to call");
                    $logger->warn("     latexindent.pl -m -l $settings ${$self}{fileName}");
                }
            }
            else {
                # otherwise print a warning that we can not read userSettings.yaml
                $logger->warn("*$settings contains invalid yaml format- not reading from it");
            }
        }
        else {
            # otherwise keep going, but put a warning in the log file
            $logger->warn("*$homeDir/indentconfig.yaml");
            if ( -z $settings ) {
                $logger->info("specifies $settings but this file is EMPTY -- not reading from it");
            }
            else {
                $logger->info(
                    "specifies $settings but this file does not exist - unable to read settings from this file");
            }
        }

        &yaml_update_dumper_settings();

    }

    # read settings from -y|--yaml switch
    if ( $switches{yaml} ) {

        # report to log file
        $logger->info("*YAML settings read: -y switch");

        # remove any horizontal space before or after , OR : OR ; or at the beginning or end of the switch value
        $switches{yaml} =~ s/\h*(,|(?<!\\):|;)\h*/$1/g;
        $switches{yaml} =~ s/^\h*//g;

        # store settings, possibly multiple ones split by commas
        my @yamlSettings;
        if ( $switches{yaml} =~ m/(?<!\\),/ ) {
            @yamlSettings = split( /(?<!\\),/, $switches{yaml} );
        }
        else {
            push( @yamlSettings, $switches{yaml} );
        }

        foreach (@yamlSettings) {
            $logger->info( "YAML setting: " . $_ );
        }

        # it is possible to specify, for example,
        #
        #   -y=indentAfterHeadings:paragraph:indentAfterThisHeading:1;level:1
        #   -y=specialBeginEnd:displayMath:begin:'\\\[';end: '\\\]';lookForThis: 1
        #
        # which should be translated into
        #
        #   indentAfterHeadings:
        #       paragraph:
        #           indentAfterThisHeading:1
        #           level:1
        #
        # so we need to loop through the comma separated list and search
        # for semi-colons
        my $settingsCounter      = 0;
        my @originalYamlSettings = @yamlSettings;
        foreach (@originalYamlSettings) {

            # increment the counter
            $settingsCounter++;

# need to be careful in splitting at ';'
#
# motivation as detailed in https://github.com/cmhughes/latexindent.pl/issues/243
#
#       latexindent.pl -m -y='modifyLineBreaks:oneSentencePerLine:manipulateSentences: 1,
#                             modifyLineBreaks:oneSentencePerLine:sentencesBeginWith:a-z: 1,
#                             fineTuning:modifyLineBreaks:betterFullStop: "(?:\.|;|:(?![a-z]))|(?:(?<!(?:(?:e\.g)|(?:i\.e)|(?:etc))))\.(?!(?:[a-z]|[A-Z]|\-|~|\,|[0-9]))"' myfile.tex
#
# in particular, the fineTuning part needs care in treating the argument between the quotes

            # check for a match of the ;
            if ( $_ !~ m/(?<!(?:\\))"/ and $_ =~ m/(?<!\\);/ ) {
                my (@subfield) = split( /(?<!\\);/, $_ );

                # the content up to the first ; is called the 'root'
                my $root = shift @subfield;

                # split the root at :
                my (@keysValues) = split( /:/, $root );

                # get rid of the last *two* elements, which will be
                #   key: value
                # for example, in
                #   -y=indentAfterHeadings:paragraph:indentAfterThisHeading:1;level:1
                # then @keysValues holds
                #   indentAfterHeadings:paragraph:indentAfterThisHeading:1
                # so we need to get rid of both
                #    1
                #    indentAfterThisHeading
                # so that we are in a position to concatenate
                #   indentAfterHeadings:paragraph
                # with
                #   level:1
                # to form
                #   indentAfterHeadings:paragraph:level:1
                pop(@keysValues);
                pop(@keysValues);

                # update the appropriate piece of the -y switch, for example:
                #   -y=indentAfterHeadings:paragraph:indentAfterThisHeading:1;level:1
                # needs to be changed to
                #   -y=indentAfterHeadings:paragraph:indentAfterThisHeading:1
                # the
                #   indentAfterHeadings:paragraph:level:1
                # will be added in the next part
                $yamlSettings[ $settingsCounter - 1 ] = $root;

                # reform the root
                $root = join( ":", @keysValues );
                $logger->trace("*Sub-field detected (; present) and the root is: $root") if $is_t_switch_active;

                # now we need to attach the $root back together with any subfields
                foreach (@subfield) {

    # splice the new field into @yamlSettings (reference: https://perlmaven.com/splice-to-slice-and-dice-arrays-in-perl)
                    splice @yamlSettings, $settingsCounter, 0, $root . ":" . $_;

                    # increment the counter
                    $settingsCounter++;
                }
                $logger->info( "-y switch value interpreted as: " . join( ',', @yamlSettings ) );
            }
        }

        # loop through each of the settings specified in the -y switch
        foreach (@yamlSettings) {

            my @keysValues;

# as above, need to be careful in splitting at ':'
#
# motivation as detailed in https://github.com/cmhughes/latexindent.pl/issues/243
#
#       latexindent.pl -m -y='modifyLineBreaks:oneSentencePerLine:manipulateSentences: 1,
#                             modifyLineBreaks:oneSentencePerLine:sentencesBeginWith:a-z: 1,
#                             fineTuning:modifyLineBreaks:betterFullStop: "(?:\.|;|:(?![a-z]))|(?:(?<!(?:(?:e\.g)|(?:i\.e)|(?:etc))))\.(?!(?:[a-z]|[A-Z]|\-|~|\,|[0-9]))"' myfile.tex
#
# in particular, the fineTuning part needs care in treating the argument between the quotes

            if ( $_ =~ m/(?<!(?:\\))"/ ) {
                my (@splitAtQuote) = split( /(?<!(?:\\))"/, $_ );
                $logger->info("quote found in -y switch");
                $logger->info( "key: " . $splitAtQuote[0] );

                # definition check
                $splitAtQuote[1] = '' if not defined $splitAtQuote[1];

                # then log the value
                $logger->info( "value: " . $splitAtQuote[1] );

                # split at :
                (@keysValues) = split( /(?<!(?:\\|\[)):(?!\])/, $splitAtQuote[0] );

                $splitAtQuote[1] = '"' . $splitAtQuote[1] . '"';
                push( @keysValues, $splitAtQuote[1] );
            }
            else {
                # split each value at semi-colon
                (@keysValues) = split( /(?<!(?:\\|\[)):(?!\])/, $_ );
            }

            # $value will always be the last element
            my $value = $keysValues[-1];

            # it's possible that the 'value' will contain an escaped
            # semi-colon, so we replace it with just a semi-colon
            $value =~ s/\\:/:/;

            # strings need special treatment
            if ( $value =~ m/^"(.*)"$/ ) {

                # double-quoted string
                # translate: '\t', '\n', '\"', '\\'
                my $raw_value = $value;
                $value = $1;

                # only translate string starts with an odd number of escape characters '\'
                $value =~ s/(?<!\\)((\\\\)*)\\t/$1\t/g;
                $value =~ s/(?<!\\)((\\\\)*)\\n/$1\n/g;
                $value =~ s/(?<!\\)((\\\\)*)\\"/$1"/g;

                # translate '\\' in double-quoted strings, but not in single-quoted strings
                $value =~ s/\\\\/\\/g;
                $logger->info("double-quoted string found in -y switch: $raw_value, substitute to $value");
            }
            elsif ( $value =~ m/^'(.*)'$/ ) {

                # single-quoted string
                my $raw_value = $value;
                $value = $1;

                # special treatment for tabs and newlines
                # translate: '\t', '\n'
                # only translate string starts with an odd number of escape characters '\'
                $value =~ s/(?<!\\)((\\\\)*)\\t/$1\t/g;
                $value =~ s/(?<!\\)((\\\\)*)\\n/$1\n/g;
                $logger->info("single-quoted string found in -y switch: $raw_value, substitute to $value");
            }

            if ( scalar(@keysValues) == 2 ) {

                # for example, -y="defaultIndent: ' '"
                my $key = $keysValues[0];
                $logger->info("Updating mainSettings with $key: $value");
                $mainSettings{$key} = $value;
            }
            elsif ( scalar(@keysValues) == 3 ) {

                # for example, -y="indentRules: one: '\t\t\t\t'"
                my $parent = $keysValues[0];
                my $child  = $keysValues[1];
                $logger->info("Updating mainSettings with $parent: $child: $value");
                $mainSettings{$parent}{$child} = $value;
            }
            elsif ( scalar(@keysValues) == 4 ) {

                # for example, -y='modifyLineBreaks  :  environments: EndStartsOnOwnLine:3' -m
                my $parent     = $keysValues[0];
                my $child      = $keysValues[1];
                my $grandchild = $keysValues[2];
                $logger->info("Updating mainSettings with $parent: $child: $grandchild: $value");
                $mainSettings{$parent}{$child}{$grandchild} = $value;
            }
            elsif ( scalar(@keysValues) == 5 ) {

                # for example, -y='modifyLineBreaks  :  environments: one: EndStartsOnOwnLine:3' -m
                my $parent          = $keysValues[0];
                my $child           = $keysValues[1];
                my $grandchild      = $keysValues[2];
                my $greatgrandchild = $keysValues[3];
                $logger->info("Updating mainSettings with $parent: $child: $grandchild: $greatgrandchild: $value");
                $mainSettings{$parent}{$child}{$grandchild}{$greatgrandchild} = $value;
            }

            &yaml_update_dumper_settings();
        }

    }

    # the following are incompatible:
    #
    #   modifyLineBreaks:
    #       oneSentencePerLine:
    #         manipulateSentences: 1
    #         textWrapSentences: 1
    #         sentenceIndent: " "       <!------
    #       textWrapOptions:
    #           columns: 100
    #           when: after             <!------
    #
    if (    $is_m_switch_active
        and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after'
        and ${ $mainSettings{modifyLineBreaks}{oneSentencePerLine} }{sentenceIndent} =~ m/\h+/ )
    {
        $logger->warn("*one-sentence-per-line *ignoring* sentenceIndent, as text wrapping set to 'after'");
        ${ $mainSettings{modifyLineBreaks}{oneSentencePerLine} }{sentenceIndent} = q();
    }

    # some users may wish to see showAmalgamatedSettings
    # which details the overall state of the settings modified
    # from the default in various user files
    if ( $mainSettings{logFilePreferences}{showAmalgamatedSettings} ) {
        $logger->info("Amalgamated/overall settings to be used:");
        $logger->info( Dumper( \%mainSettings ) );
    }

    return;
}

sub yaml_get_indentation_settings_for_this_object {
    my $self = shift;

    # create a name for previously found settings
    my $storageName
        = ${$self}{name}
        . ${$self}{modifyLineBreaksYamlName}
        . ( defined ${$self}{storageNameAppend} ? ${$self}{storageNameAppend} : q() );

    # check for storage of repeated objects
    if ( $previouslyFoundSettings{$storageName} ) {
        $logger->trace("*Using stored settings for $storageName") if ($is_t_switch_active);
    }
    else {
        my $name = ${$self}{name};
        $logger->trace("Storing settings for $storageName") if ($is_t_switch_active);

        # check for noAdditionalIndent and indentRules
        # otherwise use defaultIndent
        my $indentation = $self->yaml_get_indentation_information;

        # check for alignment at ampersand settings
        $self->yaml_alignment_at_ampersand_settings;

        # check for line break settings
        $self->yaml_modify_line_breaks_settings if $is_m_switch_active;

        # store the settings
        %{ ${previouslyFoundSettings}{$storageName} } = (
            indentation               => $indentation,
            BeginStartsOnOwnLine      => ${$self}{BeginStartsOnOwnLine},
            BodyStartsOnOwnLine       => ${$self}{BodyStartsOnOwnLine},
            EndStartsOnOwnLine        => ${$self}{EndStartsOnOwnLine},
            EndFinishesWithLineBreak  => ${$self}{EndFinishesWithLineBreak},
            removeParagraphLineBreaks => ${$self}{removeParagraphLineBreaks},
            textWrapOptions           => ${$self}{textWrapOptions},
            columns                   => ${$self}{columns},
        );

        # text wrap 'after' information
        if (    $is_m_switch_active
            and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after'
            and defined ${$self}{indentRule} )
        {
            ${ ${previouslyFoundSettings}{textWrapAfter} }{$name} = $indentation;
        }

        # don't forget alignment settings!
        foreach (@alignAtAmpersandInformation) {
            ${ ${previouslyFoundSettings}{$storageName} }{ ${$_}{name} } = ${$self}{ ${$_}{name} }
                if ( defined ${$self}{ ${$_}{name} } );
        }

        # some objects, e.g ifElseFi, can have extra assignments, e.g ElseStartsOnOwnLine
        # these need to be stored as well!
        foreach ( @{ ${$self}{additionalAssignments} } ) {
            ${ ${previouslyFoundSettings}{$storageName} }{$_} = ${$self}{$_};
        }

        # log file information
        $logger->trace("Settings for $name (stored for future use):") if $is_tt_switch_active;
        $logger->trace( Dump \%{ ${previouslyFoundSettings}{$storageName} } ) if $is_tt_switch_active;

    }

    # append indentation settings to the current object
    while ( my ( $key, $value ) = each %{ ${previouslyFoundSettings}{$storageName} } ) {
        ${$self}{$key} = $value;
    }

    return;
}

sub yaml_alignment_at_ampersand_settings {
    my $self = shift;

# if the YamlName is, for example, optionalArguments, mandatoryArguments, heading, then we'll be looking for information about the *parent*
    my $name = ( defined ${$self}{nameForIndentationSettings} ) ? ${$self}{nameForIndentationSettings} : ${$self}{name};

    # check, for example,
    #   lookForAlignDelims:
    #      tabular: 1
    # or
    #
    #   lookForAlignDelims:
    #      tabular:
    #         delims: 1
    #         alignDoubleBackSlash: 1
    #         spacesBeforeDoubleBackSlash: 2
    return unless ${ $mainSettings{lookForAlignDelims} }{$name};

    $logger->trace("alignAtAmpersand settings for $name (see lookForAlignDelims)") if ($is_t_switch_active);

    if ( ref ${ $mainSettings{lookForAlignDelims} }{$name} eq "HASH" ) {

        # specified as a hash, e.g
        #
        #   lookForAlignDelims:
        #      tabular:
        #         delims: 1
        #         alignDoubleBackSlash: 1
        #         spacesBeforeDoubleBackSlash: 2
        foreach (@alignAtAmpersandInformation) {
            my $yamlname = ( defined ${$_}{yamlname} ? ${$_}{yamlname} : ${$_}{name} );

            # each of the following cases need to be allowed:
            #
            #   lookForAlignDelims:
            #      aligned:
            #         spacesBeforeAmpersand:
            #           default: 1
            #           leadingBlankColumn: 0
            #
            #   lookForAlignDelims:
            #      aligned:
            #         spacesBeforeAmpersand:
            #           leadingBlankColumn: 0
            #
            #   lookForAlignDelims:
            #      aligned:
            #         spacesBeforeAmpersand:
            #           default: 0
            #
            # approach:
            #     - update mainSettings to have the relevant information: leadingBlankColumn and/or default
            #     - delete the spacesBeforeAmpersand hash
            #
            if ( $yamlname eq "spacesBeforeAmpersand"
                and ref( ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{spacesBeforeAmpersand} ) eq "HASH" )
            {
                $logger->trace("spacesBeforeAmpersand settings for $name") if $is_t_switch_active;

                #   lookForAlignDelims:
                #      aligned:
                #         spacesBeforeAmpersand:
                #           leadingBlankColumn: 0
                if (defined ${ ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{spacesBeforeAmpersand} }
                    {leadingBlankColumn} )
                {
                    $logger->trace("spacesBeforeAmpersand: leadingBlankColumn specified for $name")
                        if $is_t_switch_active;
                    ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{leadingBlankColumn}
                        = ${ ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{spacesBeforeAmpersand} }
                        {leadingBlankColumn};
                }

                #   lookForAlignDelims:
                #      aligned:
                #         spacesBeforeAmpersand:
                #           default: 0
                if ( defined ${ ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{spacesBeforeAmpersand} }{default} ) {
                    ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{spacesBeforeAmpersand}
                        = ${ ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{spacesBeforeAmpersand} }{default};
                }
                else {
                    # deleting spacesBeforeAmpersand hash allows spacesBeforeAmpersand
                    # to pull from the default values @alignAtAmpersandInformation
                    delete ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{spacesBeforeAmpersand};
                }
            }
            ${$self}{ ${$_}{name} }
                = ( defined ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{$yamlname} )
                ? ${ ${ $mainSettings{lookForAlignDelims} }{$name} }{$yamlname}
                : ${$_}{default};
        }
    }
    else {
        # specified as a scalar, e.g
        #
        #   lookForAlignDelims:
        #      tabular: 1
        foreach (@alignAtAmpersandInformation) {
            ${$self}{ ${$_}{name} } = ${$_}{default};
        }
    }
    return;
}

sub yaml_modify_line_breaks_settings {
    my $self = shift;

    # details to the log file
    $logger->trace("*-m modifylinebreaks switch active") if $is_t_switch_active;
    $logger->trace(
        "looking for polyswitch, textWrapOptions, removeParagraphLineBreaks, oneSentencePerLine settings for ${$self}{name} "
    ) if $is_t_switch_active;

    # some objects, e.g ifElseFi, can have extra assignments, e.g ElseStartsOnOwnLine
    my @toBeAssignedTo = ${$self}{additionalAssignments} ? @{ ${$self}{additionalAssignments} } : ();

    # the following will *definitley* be in the array, so let's add them
    push(
        @toBeAssignedTo,
        (   "BeginStartsOnOwnLine", "BodyStartsOnOwnLine", "EndStartsOnOwnLine", "EndFinishesWithLineBreak",
            "DBSStartsOnOwnLine",   "DBSFinishesWithLineBreak"
        )
    );

    # we can efficiently loop through the following
    foreach (@toBeAssignedTo) {
        $self->yaml_poly_switch_get_every_or_custom_value(
            toBeAssignedTo      => $_,
            toBeAssignedToAlias => ${$self}{aliases}{$_} ? ${$self}{aliases}{$_} : $_,
        );
    }

    return;
}

sub yaml_poly_switch_get_every_or_custom_value {
    my $self  = shift;
    my %input = @_;

    my $toBeAssignedTo      = $input{toBeAssignedTo};
    my $toBeAssignedToAlias = $input{toBeAssignedToAlias};

    # alias
    if ( ${$self}{aliases}{$toBeAssignedTo} ) {
        $logger->trace("aliased $toBeAssignedTo using ${$self}{aliases}{$toBeAssignedTo}") if ($is_t_switch_active);
    }

    # name of the object in the modifyLineBreaks yaml (e.g environments, ifElseFi, etc)
    my $YamlName = ${$self}{modifyLineBreaksYamlName};

# if the YamlName is either optionalArguments or mandatoryArguments, then we'll be looking for information about the *parent*
    my $name = ( $YamlName =~ m/Arguments/ ) ? ${$self}{parent} : ${$self}{name};

    # these variables just ease the notation what follows
    my $everyValue  = ${ ${ $mainSettings{modifyLineBreaks} }{$YamlName} }{$toBeAssignedToAlias};
    my $customValue = ${ ${ ${ $mainSettings{modifyLineBreaks} }{$YamlName} }{$name} }{$toBeAssignedToAlias};

    # check for the *custom* value
    if ( defined $customValue ) {
        $logger->trace("$name: $toBeAssignedToAlias=$customValue, (*per-name* value) adjusting $toBeAssignedTo")
            if ($is_t_switch_active);
        ${$self}{$toBeAssignedTo} = $customValue != 0 ? $customValue : undef;
    }
    else {
        # check for the *every* value
        if ( defined $everyValue and $everyValue != 0 ) {
            $logger->trace("$name: $toBeAssignedToAlias=$everyValue, (*global* value) adjusting $toBeAssignedTo")
                if ($is_t_switch_active);
            ${$self}{$toBeAssignedTo} = $everyValue;
        }
    }
    return;
}

sub yaml_get_indentation_information {
    my $self = shift;

    #**************************************
    # SEARCHING ORDER:
    #   noAdditionalIndent *per-name* basis
    #   indentRules *per-name* basis
    #   noAdditionalIndentGlobal
    #   indentRulesGlobal
    #**************************************

    # noAdditionalIndent can be a scalar or a hash, e.g
    #
    #   noAdditionalIndent:
    #       myexample: 1
    #
    # OR
    #
    #   noAdditionalIndent:
    #       myexample:
    #           body: 1
    #           optionalArguments: 1
    #           mandatoryArguments: 1
    #
    # specifying as a scalar with no field (e.g myexample: 1)
    # will be interpreted as noAdditionalIndent for *every*
    # field, so the body, optional arguments and mandatory arguments
    # will *all* receive noAdditionalIndent
    #
    # indentRules can also be a scalar or a hash, e.g
    #   indentRules:
    #       myexample: "\t"
    #
    # OR
    #
    #   indentRules:
    #       myexample:
    #           body: "  "
    #           optionalArguments: "\t \t"
    #           mandatoryArguments: ""
    #
    # specifying as a scalar with no field will
    # mean that *every* field will receive the same treatment

# if the YamlName is, for example, optionalArguments, mandatoryArguments, heading, then we'll be looking for information about the *parent*
    my $name = ( defined ${$self}{nameForIndentationSettings} ) ? ${$self}{nameForIndentationSettings} : ${$self}{name};

# if the YamlName is not optionalArguments, mandatoryArguments, heading (possibly others) then assume we're looking for 'body'
    my $YamlName = $self->yaml_get_object_attribute_for_indentation_settings;

    my $indentationInformation;
    foreach my $indentationAbout ( "noAdditionalIndent", "indentRules" ) {

        # check that the 'thing' is defined
        if ( defined ${ $mainSettings{$indentationAbout} }{$name} ) {
            if ( ref ${ $mainSettings{$indentationAbout} }{$name} eq "HASH" ) {
                $logger->trace(
                    "$indentationAbout indentation specified with multiple fields for $name, searching for $name: $YamlName (see $indentationAbout)"
                ) if $is_t_switch_active;
                $indentationInformation = ${ ${ $mainSettings{$indentationAbout} }{$name} }{$YamlName};
            }
            else {
                $indentationInformation = ${ $mainSettings{$indentationAbout} }{$name};
                $logger->trace(
                    "$indentationAbout indentation specified for $name (for *all* fields, body, optionalArguments, mandatoryArguments, afterHeading), using '$indentationInformation' (see $indentationAbout)"
                ) if $is_t_switch_active;
            }

            # return, after performing an integrity check
            if ( defined $indentationInformation ) {
                if ( $indentationAbout eq "noAdditionalIndent" and $indentationInformation == 1 ) {
                    $logger->trace("Found! Using '' (see $indentationAbout)") if $is_t_switch_active;

                    # text wrapping 'after' requires knowledge of indent rules
                    #
                    if ( $is_m_switch_active
                        and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after' )
                    {
                        ${$self}{indentRule} = $indentationInformation;
                    }
                    return q();
                }
                elsif ( $indentationAbout eq "indentRules" and $indentationInformation =~ m/^\h*$/ ) {
                    $logger->trace("Found! Using '$indentationInformation' (see $indentationAbout)")
                        if $is_t_switch_active;

                    # text wrapping 'after' requires knowledge of indent rules
                    #
                    if ( $is_m_switch_active
                        and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after' )
                    {
                        ${$self}{indentRule} = $indentationInformation;
                    }
                    return $indentationInformation;
                }
            }
        }
    }

    # gather information
    $YamlName = ${$self}{modifyLineBreaksYamlName};

    foreach my $indentationAbout ( "noAdditionalIndent", "indentRules" ) {

        # global assignments in noAdditionalIndentGlobal and/or indentRulesGlobal
        my $globalInformation = $indentationAbout . "Global";
        next if ( !( defined ${ $mainSettings{$globalInformation} }{$YamlName} ) );
        if ( ( $globalInformation eq "noAdditionalIndentGlobal" )
            and ${ $mainSettings{$globalInformation} }{$YamlName} == 1 )
        {
            $logger->trace("$globalInformation specified for $YamlName (see $globalInformation)")
                if $is_t_switch_active;

            # text wrapping 'after' requires knowledge of indent rules
            #
            if ( $is_m_switch_active
                and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after' )
            {
                ${$self}{indentRule} = $indentationInformation;
            }
            return q();
        }
        elsif ( $globalInformation eq "indentRulesGlobal" ) {
            if ( ${ $mainSettings{$globalInformation} }{$YamlName} =~ m/^\h*$/ ) {
                $logger->trace("$globalInformation specified for $YamlName (see $globalInformation)")
                    if $is_t_switch_active;

                # text wrapping 'after' requires knowledge of indent rules
                #
                if ( $is_m_switch_active
                    and ${ $mainSettings{modifyLineBreaks}{textWrapOptions} }{when} eq 'after' )
                {
                    ${$self}{indentRule} = $indentationInformation;
                }
                return ${ $mainSettings{$globalInformation} }{$YamlName};
            }
            elsif ( ${ $mainSettings{$globalInformation} }{$YamlName} ne '0' ) {
                $logger->warn(
                    "$globalInformation specified (${$mainSettings{$globalInformation}}{$YamlName}) for $YamlName, but it needs to only contain horizontal space -- I'm ignoring this one"
                );
            }
        }
    }

    # return defaultIndent, by default
    $logger->trace("Using defaultIndent for $name") if $is_t_switch_active;
    return $mainSettings{defaultIndent};
}

sub yaml_get_object_attribute_for_indentation_settings {

    # when looking for noAdditionalIndent or indentRules, we may need to determine
    # which thing we're looking for, e.g
    #
    #   chapter:
    #       body: 0
    #       optionalArguments: 1
    #       mandatoryArguments: 1
    #       afterHeading: 0
    #
    # this method returns 'body' by default, but the other objects (optionalArgument, mandatoryArgument, afterHeading)
    # return their appropriate identifier.
    return "body";
}

sub yaml_update_dumper_settings {

    # log file preferences
    $Data::Dumper::Terse     = ${ $mainSettings{logFilePreferences}{Dumper} }{Terse};
    $Data::Dumper::Indent    = ${ $mainSettings{logFilePreferences}{Dumper} }{Indent};
    $Data::Dumper::Useqq     = ${ $mainSettings{logFilePreferences}{Dumper} }{Useqq};
    $Data::Dumper::Deparse   = ${ $mainSettings{logFilePreferences}{Dumper} }{Deparse};
    $Data::Dumper::Quotekeys = ${ $mainSettings{logFilePreferences}{Dumper} }{Quotekeys};
    $Data::Dumper::Sortkeys  = ${ $mainSettings{logFilePreferences}{Dumper} }{Sortkeys};
    $Data::Dumper::Pair      = ${ $mainSettings{logFilePreferences}{Dumper} }{Pair};

}
1;
