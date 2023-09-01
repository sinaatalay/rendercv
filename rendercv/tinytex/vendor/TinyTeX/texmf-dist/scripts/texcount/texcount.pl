#! /usr/bin/env perl
use strict;
use warnings;
use utf8; # Because the script itself is UTF-8 encoded
use Encode;
use Text::Wrap;
use Term::ANSIColor;

# System variables
my $terminalwidth;

# Conditional package inclusion
if ($^O=~/^MSWin/) {
  eval {
    require Win32::Console::ANSI;
    import Win32::Console::ANSI;
  };
  if ($@) {
    option_ansi_colours(0);
    print STDERR "NOTE: Package Win32::Console::ANSI required for colour coded output.\n";
  }
}

# Terminal or not
if (-t STDOUT) { # If in terminal
  eval {
    require Term::ReadKey;
    import Term::ReadKey;
    ($terminalwidth)=GetTerminalSize();
  };
} else {
  option_ansi_colours(0);
}

if (!defined $terminalwidth) {$terminalwidth=76;}
elsif ($terminalwidth<60) {$terminalwidth=60;}
elsif ($terminalwidth>120) {$terminalwidth=120;}


##### Version information

my $versionnumber="3.1.1";
my $versiondate="2018 Oct 28";

###### Set global constants and names

### Global data about TeXcount
my %GLOBALDATA=
   ('versionnumber'  => $versionnumber
   ,'versiondate'    => $versiondate
   ,'maintainer'     => 'Einar Andreas Rodland'
   ,'copyrightyears' => '2008-2018'
   ,'website'        => 'http://app.uio.no/ifi/texcount/'
   );

### Named constants
my ($INCLUDE_NONE,$INCLUDE_AFTER,$INCLUDE_MERGE)=(0,1,2); # Value of $includeTeX
my ($HTML_NONE,$HTML_CORE,$HTML_FULL)=(0,1,2); # Value of $htmlstyle



###### Set global settings and variables

### Options and states

# Outer object (for error reports not added by a TeX object)
my $Main=getMain();

# Global options and settings
my $htmlstyle=$HTML_NONE; # Flag to print HTML
my $texcodeoutput=0; # Flag to convert output to valid TeX text
my $encoding=undef; # Selected input encoding (default will be guess)
my @encodingGuessOrder=qw/ascii utf8 latin1/; # Encoding guessing order
my $outputEncoding; # Encoding used for output
my @AlphabetScripts=qw/Digit Is_alphabetic/; # Letters minus logograms: defined later
my @LogogramScripts=qw/Ideographic Katakana Hiragana Thai Lao Hangul/; # Scripts counted as whole words

# Parsing rules options
my $includeTeX=$INCLUDE_NONE; # Flag to parse included files
my $includeBibliography=0; # Flag to include bibliography
my %substitutions; # Substitutions to make globally
my %IncludedPackages; # List of included packages

# Counting options
my @sumweights; # Set count weights for computing sum
my $optionWordFreq=0; # Count words of this frequency, or don't count if 0
my $optionWordClassFreq=0; # Count words per word class (language) if set
my $optionMacroStat=0; # Count macro, environment and package usage

# Parsing details options
my $strictness=0; # Flag to check for undefined environments 
my $defaultVerbosity='0'; # Specification of default verbose output style
my $defaultprintlevel=0; # Flag indicating default level of verbose output
my $printlevel=undef; # Flag indicating level of verbose output
my $showstates=0; # Flag to show internal state in verbose log
my $showcodes=1; # Flag to show overview of colour codes (2=force)
my $showsubcounts=0; # Write subcounts if #>this, or not (if 0)
my $separatorstyleregex='^word'; # Styles (regex) after which separator should be added
my $separator=''; # Separator to add after words/tokens

# Final summary output options
my $showVersion=0; # Indicator that version info be included (1) or not (-1)
my $totalflag=0; # Flag to write only total summary
my $briefsum=0; # Flag to set brief summary
my $outputtemplate; # Output template
my $finalLineBreak=1; # Add line break at end

# Global settings
my $optionFast=1; # Flag inticating fast method 

# Global variables and internal states (for internal use only)
my $blankline=0; # Number of blank lines printed
my $errorcount=0; # Number of errors in parsing
my %warnings=(); # Warnings
my %WordFreq; # Hash for counting words
my %MacroUsage; # Hash for counting macros, environments and packages

# External sources
my $HTMLfile; # HTML file to use as HTML output template
my $CSSfile; # CSS file to use with HTML output
my $CSShref; # CSS reference to use with HTML output
my @htmlhead; # Lines to add to the HTML header
my $htmlopen; # text used to open the HTML file
my $htmlclose; # text used to close the HTML file

# String data storage
my $STRINGDATA;

# Other constants
my $_PARAM_='<param>'; # to identify parameter to _parse_unit
my $STRING_PARAMETER='{_}'; # used to log macro parameters
my $STRING_OPTIONAL_PARAM='[_]'; # used to log optional parameter
my $STRING_GOBBLED_OPTION='[]'; # used to log gobbled macro option
my $STRING_ERROR='<error>'; # used to log errors causing parsing to stop
my $REGEX_NUMBER=qr/^\d+$/; # regex to recognize a number


###### Set CMD specific settings and variables

## Preset command line options
# List of options (stings) separated by comma,
# e.g. ('-inc','-v') to parse included files and
# give verbose output by default.
my @StartupOptions=();

# CMD specific global variables
my @filelist; # List of files to parse
my $globalworkdir='./'; # Overrules workdir (default=present root)
my $workdir; # Current directory (default=taken from filename)
my $auxdir; # Directory for auxilary files, e.g. bbl (default=$workdir)
my $fileFromSTDIN=0; # Flag to set input from STDIN
my $_STDIN_='<STDIN>'; # File name to represent STDIN (must be '<...>'!)

# CMD specific settings
$Text::Wrap::columns=$terminalwidth; # Page width for wrapped output


###### Set state identifiers and methods


### Counter indices from 0 to $SIZE_CNT-1
#   0: Number of files
#   1: Text words
#   2: Header words
#   3: Caption words
#   4: Number of headers
#   5: Number of floating environments
#   6: Number of inlined math
#   7: Number of displayed math
my $SIZE_CNT=8;
my $SIZE_CNT_DEFAULT=8;
my $CNT_FILE=0;
my $CNT_WORDS_TEXT=1;
my $CNT_WORDS_HEADER=2;
my $CNT_WORDS_OTHER=3;
my $CNT_COUNT_HEADER=4;
my $CNT_COUNT_FLOAT=5;
my $CNT_COUNT_INLINEMATH=6;
my $CNT_COUNT_DISPLAYMATH=7;

# Labels used to describe the counts
my @countkey=('file','word','hword','oword','header','float','inmath','dsmath');
my @countdesc=('Files','Words in text','Words in headers',
      'Words outside text (captions, etc.)','Number of headers','Number of floats/tables/figures',
      'Number of math inlines','Number of math displayed');

# Map keywords to counters
my %key2cnt;
add_keys_to_hash(\%key2cnt,$CNT_FILE,0,'file');
add_keys_to_hash(\%key2cnt,$CNT_WORDS_TEXT,1,'text','word','w','wd');
add_keys_to_hash(\%key2cnt,$CNT_WORDS_HEADER,2,'headerword','hword','hw','hwd');
add_keys_to_hash(\%key2cnt,$CNT_WORDS_OTHER,3,'otherword','other','oword','ow','owd');
add_keys_to_hash(\%key2cnt,$CNT_COUNT_HEADER,4,'header','heading','head');
add_keys_to_hash(\%key2cnt,$CNT_COUNT_FLOAT,5,'float','table','figure');
add_keys_to_hash(\%key2cnt,$CNT_COUNT_INLINEMATH,6,'inline','inlinemath','imath','eq');
add_keys_to_hash(\%key2cnt,$CNT_COUNT_DISPLAYMATH,7,'displaymath','dsmath','dmath','ds');


### Token types
# Set in $tex->{'type'} by call to _next_token
my $TOKEN_SPACE=-1;
my $TOKEN_COMMENT=0;
my $TOKEN_WORD=1; # word (or other form of text or text component)
my $TOKEN_SYMBOL=2; # symbol (not word, e.g. punctuation)
my $TOKEN_MACRO=3; # macro (\name)
my $TOKEN_BRACE=4; # curly braces: { }
my $TOKEN_BRACKET=5; # brackets: [ ]
my $TOKEN_MATH=6;
my $TOKEN_LINEBREAK=9; # line break in file
my $TOKEN_TC=666; # TeXcount instructions (%TC:instr)
my $TOKEN_END=999; # end of line or blank line


### Parsing states
#
## States for regions that should not be counted
#   IGNORE = exclude from count
#   FLOAT = float (exclude, but include captions)
#   EXCLUDE_STRONG = strong exclude, ignore environments
#   EXCLUDE_STRONGER = stronger exclude, do not parse macro parameters
#   EXCLUDE_ALL = ignore everything except end marker: even {
#   PREAMBLE = preamble (between \documentclass and \begin{document})
## States for regions in which words should be counted
#   TEXT = text
#   TEXT_HEADER = header text
#   TEXT_FLOAT = float text
## State change: not used in parsing, but to switch state then ignore contents
#   TO_INLINEMATH = switch to inlined math
#   TO_DISPLAYMATH = switch to displayed math
## Other states
#   _NULL = default state to use if none other is defined
#   _OPTION = state used to indicate that the next parameter is an option
#   _EXCLUDE_ = cutoff, state <= this represents excluded text
## NB: Presently, it is assumed that additional states is added as 8,9,...,
## e.g. that states added through TC:newcounter correspond to the added counters.
#
my $STATE_IGNORE=-1;
my $STATE_MATH=-2;
my $STATE_FLOAT=-10;
my $STATE_EXCLUDE_STRONG=-20;
my $STATE_EXCLUDE_STRONGER=-30;
my $STATE_EXCLUDE_ALL=-40;
my $STATE_SPECIAL_ARGUMENT=-90;
my $STATE_PREAMBLE=-99;
my $STATE_TEXT=1;
my $STATE_TEXT_HEADER=2;
my $STATE_TEXT_FLOAT=3;
my $STATE_TO_HEADER=4;
my $STATE_TO_FLOAT=5;
my $STATE_TO_INLINEMATH=6;
my $STATE_TO_DISPLAYMATH=7;
my $__STATE_EXCLUDE_=-10;
my $__STATE_NULL=1;
my $_STATE_OPTION=-1000;
my $_STATE_NOOPTION=-1001;
my $_STATE_AUTOOPTION=-1002;

# Counter key mapped to STATE
my $PREFIX_PARAM_OPTION=' '; # Prefix for parameter options/modifiers
my %key2state;
add_keys_to_hash(\%key2state,$STATE_TEXT,1,'text','word','w','wd');
add_keys_to_hash(\%key2state,$STATE_TEXT_HEADER,2,'headertext','headerword','hword','hw','hwd');
add_keys_to_hash(\%key2state,$STATE_TEXT_FLOAT,3,'otherword','other','oword','ow','owd');
add_keys_to_hash(\%key2state,$STATE_TO_HEADER,4,'header','heading','head');
add_keys_to_hash(\%key2state,$STATE_TO_FLOAT,5,'float','table','figure');
add_keys_to_hash(\%key2state,$STATE_TO_INLINEMATH,6,'inline','inlinemath','imath','eq');
add_keys_to_hash(\%key2state,$STATE_TO_DISPLAYMATH,7,'displaymath','dsmath','dmath','ds');
add_keys_to_hash(\%key2state,$STATE_IGNORE,0,'ignore','x');
add_keys_to_hash(\%key2state,$STATE_MATH,'ismath');
add_keys_to_hash(\%key2state,$STATE_FLOAT,-1,'isfloat');
add_keys_to_hash(\%key2state,$STATE_EXCLUDE_STRONG,-2,'xx');
add_keys_to_hash(\%key2state,$STATE_EXCLUDE_STRONGER,-3,'xxx');
add_keys_to_hash(\%key2state,$STATE_EXCLUDE_ALL,-4,'xall');
add_keys_to_hash(\%key2state,$STATE_SPECIAL_ARGUMENT,'specarg','spescialarg','specialargument');
add_keys_to_hash(\%key2state,$_STATE_OPTION,'[',' option',' opt',' optional');
add_keys_to_hash(\%key2state,$_STATE_NOOPTION,'nooption','nooptions','noopt','noopts');
add_keys_to_hash(\%key2state,$_STATE_AUTOOPTION,'autooption','autooptions','autoopt','autoopts');

# When combining two states, use the first one; list must be complete!
my @STATE_FIRST_PRIORITY=(
    $STATE_EXCLUDE_ALL,
    $STATE_EXCLUDE_STRONGER,
    $STATE_EXCLUDE_STRONG,
    $STATE_SPECIAL_ARGUMENT,
    $STATE_FLOAT,
    $STATE_MATH,
    $STATE_IGNORE,
    $STATE_PREAMBLE,
    $STATE_TO_FLOAT,
    $STATE_TO_HEADER,
    $STATE_TO_INLINEMATH,
    $STATE_TO_DISPLAYMATH);
my @STATE_MID_PRIORITY=();
my @STATE_LAST_PRIORITY=(
    $STATE_TEXT_FLOAT,
    $STATE_TEXT_HEADER,
    $STATE_TEXT);

# Map state to corresponding word counter
my %state2cnt=(
    $STATE_TEXT        => $CNT_WORDS_TEXT,
    $STATE_TEXT_HEADER => $CNT_WORDS_HEADER,
    $STATE_TEXT_FLOAT  => $CNT_WORDS_OTHER);

# Transition state mapped to content state and counter
my %transition2state=(
    $STATE_TO_HEADER      => [$STATE_TEXT_HEADER,$CNT_COUNT_HEADER],
    $STATE_TO_INLINEMATH  => [$STATE_MATH       ,$CNT_COUNT_INLINEMATH],
    $STATE_TO_DISPLAYMATH => [$STATE_MATH       ,$CNT_COUNT_DISPLAYMATH],
    $STATE_TO_FLOAT       => [$STATE_FLOAT      ,$CNT_COUNT_FLOAT]);

# Parsing state descriptions (used for macro rule help)
my %state2desc=(
    $STATE_IGNORE           => 'ignore: do not count',
    $STATE_MATH             => 'math/equation contents',
    $STATE_FLOAT            => 'float (figure, etc.): ignore all but special macros',
    $STATE_EXCLUDE_STRONG   => 'strong exclude: ignore environments',
    $STATE_EXCLUDE_STRONGER => 'stronger exclude: ignore environments and macro paramters',
    $STATE_EXCLUDE_ALL      => 'exlude all: even {, only scan for end marker',
    $STATE_PREAMBLE         => 'preamble: from \documentclass to \begin{document}',
    $STATE_SPECIAL_ARGUMENT => 'special macro argument that TeXcount may process further',
    $STATE_TEXT             => 'text: count words',
    $STATE_TEXT_HEADER      => 'header text: count words as header words',
    $STATE_TEXT_FLOAT       => 'float text: count words as float words (e.g. captions)',
    $STATE_TO_HEADER        => 'header: count header, then count words as header words',
    $STATE_TO_FLOAT         => 'float: count float, then count words as float/other words',
    $STATE_TO_INLINEMATH    => 'inline math: count as inline math/equation',
    $STATE_TO_DISPLAYMATH   => 'displayed math: count as displayed math/equation',
    $_STATE_OPTION          => 'rule for [] option follows',
    $_STATE_NOOPTION        => 'no [] options allowed here',
    $_STATE_AUTOOPTION      => 'automatic [] option gobbling');

# Short state name for each state for use with -showstates
my %state2key = ($STATE_PREAMBLE=>'pre');
for my $key ('x','xx','xxx','xall','w','hw','ow','eq','ds',
        'head','float','isfloat','ismath','specarg') {
  $state2key{$key2state{$key}}=$key;
}

# Parsing state presentation style
my %state2style=(
    $STATE_TEXT        => 'word',
    $STATE_TEXT_HEADER => 'hword',
    $STATE_TEXT_FLOAT  => 'oword',
    );

# State: is a text state..."include state" is more correct
sub state_is_text {
  my $st=shift @_;
  return ($st>=$STATE_TEXT);
}

# State: is a parsed/included region, text or preamble
sub state_is_parsed {
  my $st=shift @_;
  return ($st>=$STATE_TEXT || $st==$STATE_PREAMBLE);
}

# State: get CNT corresponding to text state (or undef)
sub state_text_cnt {
  my $st=shift @_;
  return $state2cnt{$st};
}

# State: is an exclude state
sub state_is_exclude {
  my $st=shift @_;
  return ($st<=$__STATE_EXCLUDE_);
}

# State: \begin and \end should be processed
sub state_inc_envir {
  my $st=shift @_;
  return ($st>$STATE_EXCLUDE_STRONG);
}

# State as text (used with printstate)
# TODO: Should do a conversion based on STATE values.
sub state_to_text {
  my $st=shift @_;
  my $statename = $state2key{$st};
  if (defined $statename) {$st=$statename;}
  return $st;
}

# Style to use with text state
sub state_to_style {
  return $state2style{shift @_};
}

# Add new counter with the given key and description
sub add_new_counter {
  my ($key,$desc,$like)=@_;
  my $state=$SIZE_CNT;
  my $cnt=$SIZE_CNT;
  $key=lc($key);
  if (!defined $like){$like=$CNT_WORDS_OTHER;}
  $key2cnt{$key}=$cnt;
  push @countkey,$key;
  push @countdesc,$desc;
  if (defined $sumweights[$like]) {$sumweights[$cnt]=$sumweights[$like];}
  $key2state{$key}=$state;
  $state2key{$state}=$key;
  $state2cnt{$state}=$cnt;
  $state2style{$state}='altwd';
  push @STATE_MID_PRIORITY,$state;
  $SIZE_CNT++;
}


###### Set global definitions


### Break points
# Definition of macros that define break points that start a new subcount.
# The values given are used as labels.
my %BreakPointsOptions;
$BreakPointsOptions{'none'}={};
$BreakPointsOptions{'part'}={%{$BreakPointsOptions{'none'}},'\part'=>'Part'};
$BreakPointsOptions{'chapter'}={%{$BreakPointsOptions{'part'}},'\chapter'=>'Chapter'};
$BreakPointsOptions{'section'}={%{$BreakPointsOptions{'chapter'}},'\section'=>'Section'};
$BreakPointsOptions{'subsection'}={%{$BreakPointsOptions{'section'}},'\subsection'=>'Subsection'};
$BreakPointsOptions{'default'}=$BreakPointsOptions{'subsection'};
my %BreakPoints=%{$BreakPointsOptions{'none'}};

### Print styles
# Definition of different print styles: maps of class labels
# to ANSI codes. Class labels are as used by HTML styles.
my %STYLES;
my $STYLE_EMPTY=' ';
my $STYLE_BLOCK='-';
my $NOSTYLE=' ';
$STYLES{'Errors'}={'error'=>'bold red','note'=>'bold white'};
$STYLES{'Words'}={'word'=>'blue','hword'=>'bold blue','oword'=>'blue','altwd'=>'blue'};
$STYLES{'Macros'}={'cmd'=>'green','fileinc'=>'bold green','special'=>'bold red','specarg'=>'red'};
$STYLES{'Options'}={'option'=>'yellow','optparm'=>'green'};
$STYLES{'Ignored'}={'ignore'=>'cyan','math'=>'magenta'};
$STYLES{'Excluded'}={'exclcmd'=>'yellow','exclenv'=>'yellow','exclmath'=>'yellow','mathcmd'=>'yellow'};
$STYLES{'Groups'}={'document'=>'bold red','envir'=>'red','mathgroup'=>'magenta'};
$STYLES{'Comments'}={'tc'=>'bold yellow','comment'=>'yellow'};
$STYLES{'Sums'}={'cumsum'=>'yellow'};
$STYLES{'States'}={'state'=>'cyan underline'};
$STYLES{'<core>'}={%{$STYLES{'Errors'}},$STYLE_EMPTY=>$NOSTYLE,'<printlevel>'=>1,'note'=>'bold white'};
$STYLES{0}={%{$STYLES{'Errors'}},'<printlevel>'=>0,'note'=>'bold white'};
$STYLES{1}={%{$STYLES{'<core>'}},%{$STYLES{'Words'}},%{$STYLES{'Groups'}},%{$STYLES{'Sums'}}};
$STYLES{2}={%{$STYLES{1}},%{$STYLES{'Macros'}},%{$STYLES{'Ignored'}},%{$STYLES{'Excluded'}}};
$STYLES{3}={%{$STYLES{2}},%{$STYLES{'Options'}},%{$STYLES{'Comments'}},'<printlevel>'=>2};
$STYLES{4}={%{$STYLES{3}},%{$STYLES{'States'}}};
$STYLES{'All'}=$STYLES{4};
my %STYLE=%{$STYLES{$defaultVerbosity}};

my @STYLE_LIST=('error','word','hword','oword','altwd',
  'ignore','document','special','cmd','exclcmd',
  'option','optparm','envir','exclenv','specarg',
  'mathgroup','exclmath','math','mathcmd','comment','tc','fileinc','state','cumsum');
my %STYLE_DESC=(
  'error'       => 'ERROR: TeXcount error message',
  'word'        => 'Text which is counted: counted as text words',
  'hword'       => 'Header and title text: counted as header words',
  'oword'       => 'Caption text and footnotes: counted as caption words',
  'altwd'       => 'Words in user specified counters: counted in separate counters',
  'ignore'      => 'Ignored text or code: excluded or ignored',
  'document'    => '\documentclass: document start, beginning of preamble',
  'special'     => 'Special macros, eg require special handling or have side-effects',
  'cmd'         => '\macro: macro not counted, but parameters may be',
  'exclcmd'     => '\macro: macro in excluded region',
  'option'      => '[Macro options]: not counted',
  'optparm'     => '[Optional parameter]: content parsed and styled as counted',
  'specarg'     => 'Special argument, eg with side-effects',
  'envir'       => '\begin{name}  \end{name}: environment',
  'exclenv'     => '\begin{name}  \end{name}: environment in excluded region',
  'mathgroup'   => '$  $: counted as one equation',
  'exclmath'    => '$  $: equation in excluded region',
  'math'        => '2+2=4: maths (inside $...$ etc.)',
  'mathcmd'     => '$\macro$: macros inside maths',
  'comment'     => '% Comments: not counted',
  'tc'          => '%TC:TeXcount instructions: not counted',
  'fileinc'     => 'File to include: not counted but file may be counted later',
  'state'       => '[state]: internal TeXcount state',
  'cumsum'      => '[cumsum]: cumulative sum count');


###### Define what a word is and language options


# Patters matching a letter. Should be a single character or
# ()-enclosed regex for substitution into word pattern regex.
my @LetterMacros=qw/ae AE o O aa AA oe OE ss
   alpha beta gamma delta epsilon zeta eta theta iota kappa lamda
   mu nu xi pi rho sigma tau upsilon phi chi psi omega
   Gamma Delta Theta Lambda Xi Pi Sigma Upsilon Phi Psi Omega 
   /;
my $specialchars='\\\\('.join('|',@LetterMacros).')(\{\}|\s+|\b)';
my $modifiedchars='\\\\[\'\"\`\~\^\=](@|\{@\})';
my %NamedLetterPattern;
$NamedLetterPattern{'restricted'}='@';
$NamedLetterPattern{'default'}='('.join('|','@',$modifiedchars,$specialchars).')';
$NamedLetterPattern{'relaxed'}=$NamedLetterPattern{'default'};
my $LetterPattern=$NamedLetterPattern{'default'};

# List of regexp patterns that should be analysed as words.
# Use @ to represent a letter, will be substituted with $LetterPattern.
# Named patterns may replace or be appended to the original patterns.
# Apply_Options() results in a call to apply_language_options() which
# constructs $WordPattern based on $LetterPattern, @WordPatterns and
# alphabet/logogram settings.
my %NamedWordPattern;
$NamedWordPattern{'letters'}='@';
$NamedWordPattern{'words'}='(@+|@+\{@+\}|\{@+\}@+)([\-\'\.]?(@+|\{@+\}))*';
my @WordPatterns=($NamedWordPattern{'words'});
my $WordPattern; # Regex matching a word (defined in apply_language_options())

### Macro option regexp list
# List of regexp patterns to be gobbled as macro option in and after
# a macro.
my %NamedMacroOptionPattern;
$NamedMacroOptionPattern{'default'}='\[[^\[\]\n]*\]';
$NamedMacroOptionPattern{'relaxed'}='\[\n?([^\[\]\n]\n?)*\]';
$NamedMacroOptionPattern{'restricted'}='\[(\w|[,\-\s\~\.\:\;\+\?\*\_\=])*\]';
my $MacroOptionPattern=$NamedMacroOptionPattern{'default'};

### Alternative language encodings
my %NamedEncodingGuessOrder;
$NamedEncodingGuessOrder{'chinese'}=[qw/utf8 gb2312 big5/];
$NamedEncodingGuessOrder{'japanese'}=[qw/utf8 euc-jp iso-2022-jp jis shiftjis/];
$NamedEncodingGuessOrder{'korean'}=[qw/utf8 euc-kr iso-2022-kr/];



###### Define character classes (alphabets)


### Character classes to use as Unicode properties

# Character group representing digits 0-9 (more restrictive than Digits)
sub Is_digit { return <<END;
0030\t0039
END
}

# Character group representing letters (excluding logograms)
sub Is_alphabetic { return <<END;
+utf8::Alphabetic
-utf8::Ideographic
-utf8::Katakana
-utf8::Hiragana
-utf8::Thai
-utf8::Lao
-utf8::Hangul
END
}

# Character group representing letters (excluding logograms)
sub Is_alphanumeric { return <<END;
+utf8::Alphabetic
+utf8::Digit
-utf8::Ideographic
-utf8::Katakana
-utf8::Hiragana
-utf8::Thai
-utf8::Lao
-utf8::Hangul
END
}

# Character class for punctuation excluding special characters
sub Is_punctuation { return <<END;
+utf8::Punctuation
-0024\t0025
-005c
-007b\007e
END
}

# Character group representing CJK characters
sub Is_cjk { return <<END;
+utf8::Han
+utf8::Katakana
+utf8::Hiragana
+utf8::Hangul
END
}

# Character group for CJK punctuation characters
sub Is_cjkpunctuation { return <<END;
3000\t303f
2018\t201f
ff01\tff0f
ff1a\tff1f
ff3b\tff3f
ff5b\tff65
END
}


###### Define core rules

### Macros indicating package inclusion
# Will always be assumed to take one extra parameter which is the list of
# packages. Macro handling rule indicates parameters ignored prior to that.
# Gets added to TeXmacro. After that, values are not used, only membership.
# Handling is otherwise hard-coded rather than rule based.
my %TeXpackageinc;
add_keys_to_hash(\%TeXpackageinc,['[','ignore','specialargument'],'\usepackage','\RequirePackage');

### Macros that are counted within the preamble
# The preamble is the text between \documentclass and \begin{document}.
# Text and macros in the preamble is ignored unless specified here. The
# value is the states (1=text, 2=header, etc.) they should be interpreted as.
# Note that only the first unit (token or {...} block) is counted.
# Gets added to TeXmacro. Is used within preambles only.
my %TeXpreamble;
add_keys_to_hash(\%TeXpreamble,['header'],'\title');
add_keys_to_hash(\%TeXpreamble,['other'],'\thanks');
add_keys_to_hash(\%TeXpreamble,['xxx','xxx'],'\newcommand','\renewcommand');
add_keys_to_hash(\%TeXpreamble,['xxx','xxx','xxx'],'\newenvironment','\renewenvironment');

### In floats: include only specific macros
# Macros used to identify caption text within floats.
# Gets added to TeXmacro. Is used within floats only.
my %TeXfloatinc=('\caption'=>['otherword']);

### How many tokens to gobble after macro
# Each macro is assumed to gobble up a given number of
# tokens (or {...} groups), as well as options [...] before, within
# and after. The %TeXmacro hash gives a link from a macro
# (or beginNAME for environment with no the backslash)
# to either an integer giving the number of tokens to ignore
# or to an array (specified as [rule,rule,...]) of length N where
# N is the number of parameters to be read with the macro. The
# array values tell how each is to be interpreted (see the parser state
# keywords for valid values). Thus specifying a number N is
# equivalent to specifying an array of N 'ignore' rules.
#
# For macros not specified here, the default value is 0: i.e.
# no tokens are excluded, but [...] options are.
my %TeXmacro=(%TeXpreamble,%TeXfloatinc,%TeXpackageinc);
add_keys_to_hash(\%TeXmacro,['text'],
    '\textnormal','\textrm','\textit','\textbf','\textsf','\texttt','\textsc','\textsl','\textup','\textmd',
    '\makebox','\mbox','\framebox','\fbox','\uppercase','\lowercase','\textsuperscript','\textsubscript',
    '\citetext');
add_keys_to_hash(\%TeXmacro,['[','text'],
    '\item');
add_keys_to_hash(\%TeXmacro,['[','ignore'],
    '\linebreak','\nolinebreak','\pagebreak','\nopagebreak');
add_keys_to_hash(\%TeXmacro,0,
    '\maketitle','\indent','\noindent',
    '\centering','\raggedright','\raggedleft','\clearpage','\cleardoublepage','\newline','\newpage',
    '\smallskip','\medskip','\bigskip','\vfill','\hfill','\hrulefill','\dotfill',
    '\normalsize','\small','\footnotesize','\scriptsize','\tiny','\large','\Large','\LARGE','\huge','\Huge',
    '\normalfont','\em','\rm','\it','\bf','\sf','\tt','\sc','\sl',
    '\rmfamily','\sffamily','\ttfamily','\upshape','\itshape','\slshape','\scshape','\mdseries','\bfseries',
    '\selectfont',
    '\tableofcontents','\listoftables','\listoffigures');
add_keys_to_hash(\%TeXmacro,1,
    '\begin','\end',
    '\documentclass','\documentstyle','\hyphenation','\pagestyle','\thispagestyle',
    '\author','\date',
    '\bibliographystyle','\bibliography','\pagenumbering','\markright',
    '\includeonly','\includegraphics','\special',
    '\label','\ref','\pageref','\bibitem',
    '\eqlabel','\eqref','\hspace','\vspace','\addvspace',
    '\newsavebox','\usebox', 
    '\newlength','\newcounter','\stepcounter','\refstepcounter','\usecounter',
    '\fontfamily','\fontseries',
    '\alph','\arabic','\fnsymbol','\roman','\value',
    '\typeout', '\typein','\cline');
add_keys_to_hash(\%TeXmacro,2,
    '\newfont','\newtheorem','\sbox','\savebox','\rule','\markboth',
    '\setlength','\addtolength','\settodepth','\settoheight','\settowidth','\setcounter',
    '\addtocontents','\addtocounter',
    '\fontsize');
add_keys_to_hash(\%TeXmacro,3,'\addcontentsline');
add_keys_to_hash(\%TeXmacro,6,'\DeclareFontShape');
add_keys_to_hash(\%TeXmacro,['[','text','ignore'],
    '\cite','\nocite','\citep','\citet','\citeauthor','\citeyear','\citeyearpar',
    '\citealp','\citealt','\Citep','\Citet','\Citealp','\Citealt','\Citeauthor');
add_keys_to_hash(\%TeXmacro,['ignore','text'],'\parbox','\raisebox');
add_keys_to_hash(\%TeXmacro,['otherword'],'\marginpar','\footnote','\footnotetext');
add_keys_to_hash(\%TeXmacro,['header'],
    '\title','\part','\chapter','\section','\subsection','\subsubsection','\paragraph','\subparagraph');
add_keys_to_hash(\%TeXmacro,['xxx','xxx','text'],'\multicolumn');
add_keys_to_hash(\%TeXmacro,['xxx','xxx'],'\newcommand','\renewcommand');
add_keys_to_hash(\%TeXmacro,['xxx','xxx','xxx'],'\newenvironment','\renewenvironment');

### Environments
# The %TeXenvir hash provides content parsing rules (parser states).
# Environments that are not defined will be counted as the surrounding text.
#
# Parameters taken by the \begin{environment} are defined in %TeXmacro.
#
# Note that some environments may only exist within math-mode, and
# therefore need not be defined here: in fact, they should not as it
# is not clear if they will be in inlined or displayed math.
my %TeXenvir;
add_keys_to_hash(\%TeXenvir,'ignore',
    'titlepage','tabbing','tabular','tabular*','thebibliography','lrbox');
add_keys_to_hash(\%TeXenvir,'text',
    'document','letter','center','flushleft','flushright',
    'abstract','quote','quotation','verse','minipage',
    'description','enumerate','itemize','list',
    'theorem','thm','lemma','definition','corollary','example','proof','pf');
add_keys_to_hash(\%TeXenvir,'inlinemath',
    'math');
add_keys_to_hash(\%TeXenvir,'displaymath',
    'displaymath','equation','equation*','eqnarray','eqnarray*','align','align*',);
add_keys_to_hash(\%TeXenvir,'float',
    'float','picture','figure','figure*','table','table*');
add_keys_to_hash(\%TeXenvir,'xall',
    'verbatim','tikzpicture');

# Environment parameters
my $PREFIX_ENVIR='begin'; # Prefix used for environment names
add_keys_to_hash(\%TeXmacro,1,
    'beginthebibliography','beginlrbox','beginminipage');
add_keys_to_hash(\%TeXmacro,2,
    'beginlist');
add_keys_to_hash(\%TeXmacro,['ignore'],
    'beginletter');
add_keys_to_hash(\%TeXmacro,['xxx'],
    'begintabular');
add_keys_to_hash(\%TeXmacro,['ignore','xxx'],
    'begintabular*');
add_keys_to_hash(\%TeXmacro,['[','text'],
    'begintheorem','beginthm','beginlemma','begindefinition','begincorollary','beginexample','beginproof','beginpf');
add_keys_to_hash(\%TeXmacro,['nooptions'],
    'beginverbatim');

### Macros that should be counted as one or more words
# Macros that represent text may be declared here. The value gives
# the number of words the macro represents.
my %TeXmacrocount=('\LaTeX'=>1,'\TeX'=>1,'beginabstract'=>['header','headerword']);

### Macros for including tex files
# Allows \macro{file} to include file; or \macro file if of type 'input'.
# Main types are 'input' for \input, 'texfile' which adds '.tex', and
# 'file' which adds '.tex' if missing.
my %TeXfileinclude=('\input'=>'input','\include'=>'texfile');

### Convert state keys to codes
convert_hash(\%TeXpreamble,\&keyarray_to_state);
convert_hash(\%TeXpackageinc,\&keyarray_to_state);
convert_hash(\%TeXfloatinc,\&keyarray_to_state);
convert_hash(\%TeXmacro,\&keyarray_to_state);
convert_hash(\%TeXmacrocount,\&keyarray_to_cnt);
convert_hash(\%TeXenvir,\&key_to_state);


###### Define package specific rules

### Package rule definitions

my %PackageTeXpreamble=(); # TeXpreamble definitions per package
my %PackageTeXpackageinc=(); # TeXpackageinc definitions per package
my %PackageTeXfloatinc=(); # TeXfloatinc definitions per package
my %PackageTeXmacro=(); # TeXmacro definitions per package
my %PackageTeXmacrocount=(); # TeXmacrocount definitions per package
my %PackageTeXenvir=(); # TeXenvir definitions per package
my %PackageTeXfileinclude=(); # TeXfileinclude definitions per package
my %PackageSubpackage=(); # Subpackages to include (listed in array [...])


# Rules for bibliography inclusion
$PackageTeXmacrocount{'%incbib'}={'beginthebibliography'=>['header','hword']};
$PackageTeXmacro{'%incbib'}={'\bibliography'=>1};
$PackageTeXenvir{'%incbib'}={'thebibliography'=>'text'};
$PackageTeXfileinclude{'%incbib'}={'\bibliography'=>'<bbl>'};

# Rules for package alltt
$PackageTeXenvir{'alltt'}={
    'alltt'=>'xall'};

# Rules for package babel
# NB: Only core macros implemented, those expected found in regular documents
$PackageTeXenvir{'babel'}={
    'otherlanguage'=>'text','otherlanguage*'=>'text'};
$PackageTeXmacro{'babel'}={
    '\selectlanguage'=>1,'\foreignlanguage'=>['ignore','text'],
    'beginotherlanguage'=>1,'beginotherlanguage*'=>1};

# Rules for package comment
$PackageTeXenvir{'comment'}={
    'comment'=>'xxx'};

# Rules for package color
$PackageTeXmacro{'color'}={
    '\textcolor'=>['ignore','text'],'\color'=>1,'\pagecolor'=>1,'\normalcolor'=>0,
    '\colorbox'=>['ignore','text'],'\fcolorbox'=>['ignore','ignore','text'],
    '\definecolor'=>3,\'DefineNamedColor'=>4};

# Rules for package endnotes
$PackageTeXmacro{'endnotes'}={'\endnote'=>['oword'],'\endnotetext'=>['oword'],'\addtoendnotetext'=>['oword']};

# Rules for package etoolbox
$PackageTeXmacro{'etoolbox'}={'\apptocmd'=>['xxx','ignore','ignore','ignore'],
    '\pretocmd'=>['xxx','ignore','ignore','ignore'],
    '\patchcmd'=>['xxx','xxx','xxx','ignore','ignore']};

# Rules for package fancyhdr
$PackageTeXmacro{'fancyhdr'}={
    '\fancyhf'=>1,'\lhead'=>1,'\chead'=>1,'\rhead'=>1,'\lfoot'=>1,'\cfoot'=>1,'\rfoot'=>1};

# Rules for package geometry
$PackageTeXmacro{'geometry'}={
    '\geometry'=>1,'\newgeometry'=>1,'\restoregeometry'=>0,,'\savegeometry'=>1,'\loadgeometry'=>1};

# Rules for package graphicx
$PackageTeXmacro{'graphicx'}={
    '\DeclareGraphicsExtensions'=>1,'\graphicspath'=>1,
    '\includegraphics'=>['[','ignore','ignore'],
    '\includegraphics*'=>['[','ignore','[','ignore','[','ignore','ignore'],
    '\rotatebox'=>1,'\scalebox'=>1,'\reflectbox'=>1,'\resizebox'=>1};

# Rules for package hyperref (urls themselves counted as one word)
# NB: \hyperref[label]{text} preferred over \hyperref{url}{category}{name}{text}
# NB: Macros for use in Form environments not implemented
$PackageTeXmacro{'hyperref'}={
    '\hyperref'=>['[','ignore','text'],
    '\url'=>1,'\nolinkurl'=>1,'\href'=>['ignore','text'],
    '\hyperlink'=>['ignore','text'],'\hypertarget'=>['ignore','text'],
    '\hyperbaseurl'=>1,'\hyperimage'=>['ignore','text'],'\hyperdef'=>['ignore','ignore','text'],
    '\phantomsection'=>0,'\autoref'=>1,'\autopageref'=>1,
    '\hypersetup'=>1,'\urlstyle'=>1,
    '\pdfbookmark'=>2,'\currentpdfbookmark'=>2,'\subpdfbookmark'=>2,'\belowpdfbookmark'=>2,
    '\pdfstringref'=>2,'\texorpdfstring'=>['text','ignore'],
    '\hypercalcbp'=>1,'\Acrobatmenu'=>2};
$PackageTeXmacrocount{'hyperref'}={
    '\url'=>1,'\nolinkurl'=>1};

# Rules for package import
$PackageTeXfileinclude{'import'}={
    '\import'=>'dir file','\subimport'=>'subdir file',
    '\inputfrom'=>'dir file','\subinputfrom'=>'subdir file',
    '\includefrom'=>'dir file','\subincludefrom'=>'subdir file'};

# Rules for package inputenc
$PackageTeXmacro{'inputenc'}={
    '\inputencoding'=>1};

# Rules for package listings
$PackageTeXenvir{'listings'}={'lstlisting'=>'xall'};
$PackageTeXmacro{'listings'}={'\lstset'=>['ignore'],'\lstinputlisting'=>['ignore']};

# Rules for package psfig
$PackageTeXmacro{'psfig'}={'\psfig'=>1};

# Rules for package sectsty
$PackageTeXmacro{'sectsty'}={
    '\allsectionsfont'=>1,'\partfont'=>1,'\chapterfont'=>1,'\sectionfont'=>1,
    '\subsectionfont'=>1,'\subsubsectionfont'=>1,'\paragraphfont'=>1,'\subparagraphfont'=>1,
    '\minisecfont'=>1,'\partnumberfont'=>1,'\parttitlefont'=>1,'\chapternumberfont'=>1,
    '\chaptertitlefont'=>1,'\nohang'=>0};

# Rules for package setspace
$PackageTeXenvir{'setspace'}={
    'singlespace'=>'text','singlespace*'=>'text','onehalfspace'=>'text','doublespace'=>'text',
    'spacing'=>'text'};
$PackageTeXmacro{'setspace'}={
    'beginspacing'=>1,
    '\singlespacing'=>0,'\onehalfspacing'=>0,'\doublespacing'=>0,
    '\setstretch'=>1,'\SetSinglespace'=>1};

# Rules for package subfiles
$PackageTeXfileinclude{'subfiles'}={
    '\subfile'=>'file'};

# Rules for package url
# NB: \url|...| variant not implemented, only \url{...}
# NB: \urldef{macro}{url} will not be counted
$PackageTeXmacro{'url'}={
    '\url'=>1,'\urldef'=>2,'\urlstyle'=>1,'\DeclareUrlCommand'=>['ignore','xxx']};
$PackageTeXmacro{'setspace'}={
    '\url'=>1};

# Rules for package wrapfig
$PackageTeXenvir{'wrapfig'}={
    'wrapfigure'=>'float','wraptable'=>'float'};
$PackageTeXmacro{'wrapfig'}={
    'beginwrapfigure'=>2,'beginwraptable'=>2};

# Rules for package xcolor (reimplements the color package)
# NB: only main macros (mostly from package color) included
$PackageTeXmacro{'xcolor'}={
    '\textcolor'=>['ignore','text'],'\color'=>1,'\pagecolor'=>1,'\normalcolor'=>0,
    '\colorbox'=>['ignore','text'],'\fcolorbox'=>['ignore','ignore','text'],
    '\definecolor'=>3,\'DefineNamedColor'=>4,
    '\colorlet'=>2};

# Rules for package xparse
$PackageSubpackage{'xparse'}=['etoolbox'];


###### Main script



###################################################

MAIN(@ARGV);
exit; # Just to make sure it ends here...

###################################################


#########
######### Main routines
#########

# MAIN ROUTINE: Handle arguments, then parse files
sub MAIN {
  my @args;
  push @args,@StartupOptions;
  push @args,@_;
  Initialise();
  Check_Arguments(@args);
  my @toplevelfiles=Parse_Arguments(@args);
  Apply_Options();
  if (scalar @toplevelfiles>0 || $fileFromSTDIN) {
    if ($showVersion && !$htmlstyle && !($briefsum && $totalflag)) {
      print "\n=== LaTeX word count (TeXcount version $versionnumber) ===\n\n";
    }
    conditional_print_style_list();
    my $totalcount=Parse_file_list(@toplevelfiles);
    conditional_print_total($totalcount);
    Report_Errors();
    if ($optionWordFreq || $optionWordClassFreq) {print_word_freq();}
    if ($optionMacroStat) {print_macro_stat();}
  } elsif ($showcodes>1) {
    conditional_print_style_list();
  } else {
    error($Main,'No files specified.');
  }
  Close_Output();
}

# Initialise, overrule initial settings, etc.
sub Initialise {
  _option_subcount();
  # Windows settings
  if ($^O eq 'MSWin32') {
  } elsif ($^O=~/^MSWin/) {
    #DELETE: do not overrule colour setting
    option_ansi_colours(0);
  }
}

# Check arguments, exit on exit condition
sub Check_Arguments {
  my @args=@_;
  if (!@args) {
    print_version();
    print_help();
    exit;
  }
  for my $arg (@args) {
    $arg=~s/^(--?(h|\?|help)|\/(\?|h))\b/-h/;
    $arg=~s/[=:]/=/;
    if ($arg=~/^-h$/) {
      print_help();
      exit;
    } elsif ($arg=~/^-(h-)?(man|manual)$/) {
      print_help_man();
      exit;
    } elsif ($arg=~/^-h-?(opt|options?)$/) {
      print_help_options();
      exit;
    } elsif ($arg=~/^-h-?(opt|options?)=(.*)$/) {
      print_help_options_subset($2);
      exit;
    } elsif ($arg=~/^-h(-rule)?=(.*)$/) {
      print_help_on_rule($2);
      exit;
    } elsif ($arg=~/^-h-styles?$/) {
      print_help_on_styles();
      exit;
    } elsif ($arg=~/^-h-styles?=(\w+)$/) {
      print_help_on_styles($1);
      exit;
    } elsif ($arg=~/^-h-(tc|(tc)?inst(ructions?))?$/) {
      print_help_tcinst();
      exit;
    } elsif ($arg=~/^--?(ver|version)$/) {
      print_version();
      exit;
    } elsif ($arg=~/^--?(lic|license|licence)$/) {
      print_license();
      exit;
    }
  }
  return 1;
}

# Parse arguments, set options (global) and return file list
sub Parse_Arguments {
  my @args=@_;
  my @files;
  foreach my $arg (@args) {
    if ($arg=~/^\-/) {
      $arg=~s/[=:]/=/;
      if (parse_option($arg)) {next;}
      print "Invalid option $arg \n\n";
      print_help();
      exit;
    } elsif ($arg=~/^@\-/) { # ignored option
      next;
    } 
    $arg=~s/\\/\//g;
    push @files,$arg;
  }
  return @files;
}

# Parse individual option parameters
sub parse_option {
  my $arg=shift @_;
  return parse_options_preset($arg) 
  || parse_options_parsing($arg)
  || parse_options_counts($arg)
  || parse_options_output($arg)
  || parse_options_format($arg)
  ;
}

# Parse presetting options
sub parse_options_preset {
  my $arg=shift @_;
  if ($arg=~/^-(opt|option|options|optionfile)=(.*)$/) {
    _parse_optionfile($2);
  }
  else {return 0;}
  return 1;
}

# Parse parsing options
sub parse_options_parsing {
  my $arg=shift @_;
  if    ($arg eq '-') {$fileFromSTDIN=1;}
  elsif ($arg eq '-merge') {$includeTeX=$INCLUDE_MERGE;}
  elsif ($arg eq '-inc') {$includeTeX=$INCLUDE_AFTER;}
  elsif ($arg eq '-noinc') {$includeTeX=$INCLUDE_NONE;}
  elsif ($arg =~/^-(includepackage|incpackage|package|pack)=(.*)$/) {include_package($2);}
  elsif ($arg eq '-incbib') {$includeBibliography=1;}
  elsif ($arg eq '-nobib') {$includeBibliography=0;}
  elsif ($arg eq '-dir') {$globalworkdir=undef;}
  elsif ($arg=~/^-dir=(.*)$/) {
    $globalworkdir=$1;
    $globalworkdir=~s:([^\/\\])$:$1\/:;
  }
  elsif ($arg eq '-auxdir') {$auxdir=undef;}
  elsif ($arg=~/^-auxdir=(.*)$/) {
    $auxdir=$1;
    $auxdir=~s:([^\/\\])$:$1\/:;
  }
  elsif ($arg =~/^-(enc|encode|encoding)=(.+)$/) {$encoding=$2;}
  elsif ($arg =~/^-(utf8|unicode)$/) {$encoding='utf8';}
  elsif ($arg =~/^-(alpha(bets?)?)=(.*)$/) {set_script_options(\@AlphabetScripts,$3);}
  elsif ($arg =~/^-(logo(grams?)?)=(.*)$/) {set_script_options(\@LogogramScripts,$3);}
  elsif ($arg =~/^-([-a-z]+)$/ && set_language_option($1)) {}
  elsif ($arg eq '-relaxed') {
    $MacroOptionPattern=$NamedMacroOptionPattern{'relaxed'};
    $LetterPattern=$NamedLetterPattern{'relaxed'};
  }
  elsif ($arg eq '-restricted') {
    $MacroOptionPattern=$NamedMacroOptionPattern{'restricted'};
    $LetterPattern=$NamedLetterPattern{'restricted'};
  }
  else {return 0;}
  return 1;
}

# Parse count and summation options
sub parse_options_counts {
  my $arg=shift @_;
  if    ($arg =~/^-sum(=(.+))?$/) {_option_sum($2);}
  elsif ($arg =~/^-nosum/) {@sumweights=();}
  elsif ($arg =~/^-(sub|subcounts?)(=(.+))?$/) {_option_subcount($3);}
  elsif ($arg =~/^-(nosub|nosubcounts?)/) {$showsubcounts=0;}
  elsif ($arg eq '-freq') {$optionWordFreq=1;}
  elsif ($arg =~/^-freq=(\d+)$/) {$optionWordFreq=$1;}
  elsif ($arg eq '-stat') {$optionWordClassFreq=1;}
  elsif ($arg =~/^-macro-?(stat|freq)$/) {$optionMacroStat=1;}
  else {return 0;}
  return 1;
}

# Apply sum option
sub _option_sum {
  my $arg=shift @_;
  if (!defined $arg) {
    @sumweights=(0,1,1,1,0,0,1,1);
  } elsif ($arg=~/^(\d+(\.\d*)?([,+]\d+(\.\d*)?){0,6})$/) {
    @sumweights=(0,split(/[,+]/,$arg));
    print STDERR "SUMWEIGHTS: ",join(', ',@sumweights),"\n";
  } else {
    print STDERR "Warning: Option value $arg not valid, ignoring option.\n";
  }
}

# Apply subcount options
sub _option_subcount {
  my $arg=shift @_;
  $showsubcounts=2;
  if (!defined $arg) {
    %BreakPoints=%{$BreakPointsOptions{'default'}};
  } elsif (my $option=$BreakPointsOptions{$arg}) {
    %BreakPoints=%{$option};
  } else {
    print STDERR "Warning: Option value $arg not valid, using default instead.\n";
    %BreakPoints=%{$BreakPointsOptions{'default'}};
  }
}

# Parse output and verbosity options
sub parse_options_output {
  my $arg=shift @_;
  if    ($arg eq '-strict') {$strictness=1;}
  elsif ($arg eq '-v') {set_verbosity_options('3');}
  elsif ($arg =~/^-v([0-4=+\-].*)/) {set_verbosity_options($1);}
  elsif ($arg =~/^-showstates?$/ ) {$showstates=1;}
  elsif ($arg =~/^-(q|quiet)$/ ) {$printlevel=-1;}
  elsif ($arg =~/^-(template)=(.*)$/ ) {_set_output_template($2);}
  elsif ($arg eq '-split') {$optionFast=1;}
  elsif ($arg eq '-nosplit') {$optionFast=0;}
  elsif ($arg eq '-showver') {$showVersion=1;}
  elsif ($arg eq '-nover') {$showVersion=-1;}
  elsif ($arg =~/^-nosep(arator)?s?$/ ) {$separator='';}
  elsif ($arg =~/^-sep(arator)?s?=(.*)$/ ) {$separator=$2;}
  elsif ($arg =~/^-out=(.*)/ ) {
    close STDOUT;
    open STDOUT,'>',$1 or die "Could not open out file for writing: $1";
  }
  elsif ($arg =~/^-out-stderr/ ) {select STDERR;}
  else {return 0;}
  return 1;
}

# Set output template
sub _set_output_template {
  my $template=shift @_;
  $outputtemplate=$template;
  if ($template=~/\{(SUM)[\?\}]/i && !@sumweights) {
    @sumweights=(0,1,1,1,0,0,1,1);
  }
  if ($template=~/\{SUB\?/i && !$showsubcounts) {
    _option_subcount();
  }
}

# Parse output formating options
sub parse_options_format {
  my $arg=shift @_;
  if    ($arg eq '-brief') {$briefsum=1;}
  elsif ($arg eq '-total') {$totalflag=1;}
  elsif ($arg eq '-0') {$briefsum=1;$totalflag=1;$printlevel=-1;$finalLineBreak=0;}
  elsif ($arg eq '-1') {$briefsum=1;$totalflag=1;$printlevel=-1;}
  elsif ($arg eq '-htmlcore' ) {option_ansi_colours(0);$htmlstyle=$HTML_CORE;}
  elsif ($arg eq '-html' ) {option_ansi_colours(0);$htmlstyle=$HTML_FULL;}
  elsif ($arg eq '-tex' ) {option_ansi_colours(0);$texcodeoutput=1;}
  elsif ($arg =~/^\-(nocol|nc$)/) {option_ansi_colours(0);}
  elsif ($arg =~/^\-(col)$/) {option_ansi_colours(1);}
  elsif ($arg eq '-codes') {$showcodes=2;}
  elsif ($arg eq '-nocodes') {$showcodes=0;}
  elsif ($arg =~/^-htmlfile=(.+)$/) {$HTMLfile=$1;}
  elsif ($arg =~/^-cssfile=(.+)$/) {$CSSfile=$1;}
  elsif ($arg =~/^-css=file:(.+)$/) {$CSSfile=$1;}
  elsif ($arg =~/^-css=(.+)$/) {$CSShref=$1;}
  else {return 0;}
  return 1;
}

# Include options from option file
sub _parse_optionfile {
  my $filename=shift @_;
  open(FH,'<',$filename)
    || die "Option file not found: $filename\n";
  my @options=<FH>;
  close(FH);
  s/^\s*(#.*|)//s for @options;
  my $text=join('',@options);
  $text=~s/(\n|\r|\r\n)\s*\\//g;
  @options=split("\n",$text);
  foreach my $arg (@options) {
    __optionfile_tc($arg)
      || parse_option($arg)
      || die "Invalid option $arg in $filename.\n";
  }
}

# Parse option file TC options
sub __optionfile_tc {
  my $arg=shift @_;
  if ($arg=~/^\%\%/) {return 1;}
  $arg=~s/^\%\s*// || return 0;
  if ($arg=~/^subst\s+(\\\w+)\s+(.*)$/i) {
    $substitutions{$1}=$2;
  } elsif ($arg=~/^(\w+)\s+([\\]*\w+)\s+([^\s\n]+)(\s+(\-?[0-9]+|\w+))?/i) {
    tc_macro_param_option($Main,$1,$2,$3,$5) || die "Invalid TC option: $arg\n";
  } else {
    print "Invalid TC option format: $arg\n";
    return 0;
  }
  return 1;
}

# Parse file list and return total count
sub Parse_file_list {
  my @files=@_;
  my $listtotalcount=new_count('Total');
  foreach (@files) {
    $_='"'.$_.'"'
  }
  if (@files) {
    @files=<@files>; # For the sake of Windows: expand wildcards!
    for my $file (@files) {
      my $filetotalcount=parse_file($file);
      add_to_total($listtotalcount,$filetotalcount);
    }
  }
  if ($fileFromSTDIN) {
    my $filetotalcount=parse_file($_STDIN_);
    add_to_total($listtotalcount,$filetotalcount);
  }
  return $listtotalcount;
}

# Parse file and included files, and return total count
sub parse_file {
  my $file=shift @_;
  if (defined ($workdir=$globalworkdir)) {}
  elsif ($file eq $_STDIN_) {$workdir='';}
  else {
    $workdir=$file;
    $workdir =~ s/^((.*[\\\/])?)[^\\\/]+$/$1/;
  }
  if ($htmlstyle && ($printlevel>0 || !$totalflag)) {print "\n<div class='filegroup'>\n";}
  my $filetotalcount=new_count('File(s) total: '.$file);
  @filelist=();
  _add_file($filetotalcount,[$file,$workdir],'File: '.$file);
  foreach my $f (@filelist) {
    _add_file($filetotalcount,$f,'Included file: '.$f->[0]);
  }
  if (!$totalflag && get_count($filetotalcount,$CNT_FILE)>1) {
    #if ($htmlstyle) {formatprint("Sum of files: $file\n",'h2');}
    print_count($filetotalcount,'sumcount',"Sum of files: $file");
  }
  if ($htmlstyle && ($printlevel>0 || !$totalflag)) {print "</div>\n\n";}
  return $filetotalcount;
}

# Parse single file, included files will be appended to @filelist.
sub _add_file {
  my ($filetotalcount,$pathfile,$title)=@_;
  my @paths=@$pathfile;
  my $file=shift @paths;
  my $tex=TeXfile($file,$title);
  if (!defined $tex) {
    error($Main,'File not found or not readable: '.$file);
    return;
  }
  $tex->{'PATH'}=\@paths;
  parse($tex);
  my $filecount=next_subcount($tex);
  if (!$totalflag) {print_count($filecount);}
  add_to_total($filetotalcount,$filecount);
}


######
###### Subroutines
######

###### CMD specific implementations


# Add file to list of files scheduled for parsing
sub include_file {
  my ($tex,$state,$file,$refparam)=@_;
  my %params=%$refparam;
  my $type=$params{'<type>'};
  my @paths=@{$tex->{'PATH'}};
  if ($type eq '<bbl>' && defined $auxdir) {
    $auxdir=~s/([\\\/])*$/\//;
    if (defined $globalworkdir) {@paths=[$auxdir];}
    elsif ($auxdir=~/^(\w:)?[\\\/]/) {@paths=[$auxdir];}
    else {@paths=[$workdir.$auxdir]}
  }
  foreach my $key (split(/\s+/,$type)) {
    my $value=$params{$key};
    if ($key eq 'dir') {unshift @paths,$workdir.$value;}
    elsif ($key eq 'subdir') {unshift @paths,$paths[0].$value;}
  }
  # Decide full file path
  my $filepath;
  if ($file=~/^(\w:)?[\\\/]/) {$filepath=$file;}
  else {
    $filepath=_find_file_in_path($tex,$file,\@paths,$params{'SUFFICES'}) || BLOCK {
      error($tex,'File '.$file.' not found in path ['.join(';',@paths).'].');
      return;
    };
  }
  if ($includeTeX==$INCLUDE_MERGE) {
    my $bincode=read_binary($filepath) || BLOCK {
      error($tex,"File $filepath not readable.");
      return;
    };
    flush_next($tex);
    line_return(0,$tex);
    my $texstate=texcode_insert_text($tex,$bincode,$filepath,@paths);
    parse_all($tex,$state);
    texcode_restore_state($tex,$texstate);
  } else {
    push @filelist,[$filepath,@paths];
  }
}

# Seach path list to find file
sub _find_file_in_path {
  my ($tex,$file,$paths,$suffices)=@_;
  foreach my $suffix (@{$suffices}) {
    foreach my $path (@{$paths}) {
      if ($path && $path!~/[\\\/]$/) {$path.='/';}
      my $filepath=$path.$file.$suffix;
      if (-e $filepath && ! -d $filepath) {return $filepath;}
      # DELETE: elsif ($filepath=~/\.tex$/i) {}
      # DELETE: elsif (-e $filepath.'.tex') {return $filepath.'.tex';}
    }
  }
  return undef;
}

# Print count (total) if conditions are met
sub conditional_print_total {
  my $sumcount=shift @_;
  if ($totalflag || number_of_subcounts($sumcount)>1) {
    if ($totalflag && $briefsum && @sumweights) {
      print get_sum_count($sumcount),"\n";
    } elsif ($htmlstyle) {
      print "<div class='sumgroup'>\n";
      formatprint('Total word count','h2');
      print_count($sumcount,'sumcount');
      print "</div>\n";
    } else {
      print_count($sumcount,'sumcount');
    }
  }
}

# Set or unset use of ANSI colours
sub option_ansi_colours {
  my $flag=shift @_;
  $ENV{'ANSI_COLORS_DISABLED'} = $flag?undef:1;
}

# Print text using ANSI colours
sub ansiprint {
  my ($text,$colour)=@_;
  print Term::ANSIColor::colored($text,$colour);
}


###### Option handling


# Apply options to set values
sub Apply_Options {
  apply_encoding_options();
  if ($htmlstyle==$HTML_FULL) {html_head();}
  flush_errorbuffer($Main);
  apply_language_options();
  if ($includeBibliography) {apply_include_bibliography();}
  if ($showcodes>1 && !($STYLE{'<printlevel>'})) {%STYLE=%{$STYLES{'All'}};} 
  if ($showstates) {set_verbosity_options('+States');}
  if (!@sumweights) {set_verbosity_options('-Sums');}
  (defined $printlevel)
   || (defined ($printlevel=$STYLE{'<printlevel>'}))
   || ($printlevel=$defaultprintlevel);
}

# Set or add styles included in the verbose output
sub set_verbosity_options {
  my $verb=shift @_;
  my $st;
  if ($defaultprintlevel<1) {$defaultprintlevel=1;}
  if ( $verb=~s/^([0-4])// || $verb=~s/^=([0-4])?// ) {
    my $key=$1;
    if (!defined $key) {%STYLE=(%{$STYLES{'<core>'}});}
    elsif ($st=$STYLES{$key}) {%STYLE=(%$st);}
    else {
      error($Main,"Unknown verbosity option '$key'.");
      %STYLE=(%{$STYLES{'<core>'}});
    }
  }
  while ($verb=~s/^([\+\-]?)(\w+)//) {
    my $add=!($1 eq '-');
    my $key=$2;
    if ($st=$STYLES{$key}) {
      if ($add) {@STYLE{keys %$st}=values %$st;}
      else {delete @STYLE{keys %$st};}
    } elsif ($st=$STYLES{'All'}->{$key}) {
      if ($add) {$STYLE{$key}=$st;}
      elsif ($STYLE{$key}) {delete $STYLE{$key};}
    } else {
      error($Main,"Unknown verbosity option '$key'.");
    }
  }
  if ($verb ne '') {
    error($Main,"Unknown verbosity option format: $verb");
  }
}

# Set or add scripts to array of scripts
sub set_script_options {
  my ($scriptset,$str)=@_;
  if ($str=~s/^\+//) {} else {splice(@$scriptset,0,scalar $scriptset);}
  my @scripts=split(/[+,]/,$str);
  foreach my $scr (@scripts) {
    $scr=~tr/_/ /;
    if ($scr eq 'Alphabetic') {
      warning($Main,'Using alphabetic instead of Unicode class Alphabetic');
      $scr='alphabetic';
    }
    if ($scr=~/^[a-z]/) {$scr='Is_'.$scr;}
    if (_is_property_valid($scr)) {push @$scriptset,$scr;}
    else {error($Main,"Unknown script $scr ignored.");}
  }
}

sub _is_property_valid {
  my $script=shift @_;
  if (! $script=~/^\w+$/) {return 0;}
  eval {' '=~/\p{$script}/};
  if ($@) {return 0;} else {return 1;}
}

# Set language option, return language if applied, undef if not
sub set_language_option {
  my $language=shift @_;
  if ($language=~/^(count\-?)all$/) {
    @AlphabetScripts=qw/Digit Is_alphabetic/;
    @LogogramScripts=qw/Ideographic Katakana Hiragana Thai Lao Hangul/;
  } elsif ($language=~/^words(-?only)?$/) {
    @LogogramScripts=();
  } elsif ($language=~/^(ch|chinese|zhongwen)(-?only)?$/) {
    @LogogramScripts=qw/Han/;
    if (defined $2) {$LetterPattern=undef;}
    @encodingGuessOrder=@{$NamedEncodingGuessOrder{'chinese'}};
    return 'chinese';
  } elsif ($language=~/^(jp|japanese)(-?only)?$/) {
    @LogogramScripts=qw/Han Hiragana Katakana/;
    if (defined $2) {$LetterPattern=undef;}
    @encodingGuessOrder=@{$NamedEncodingGuessOrder{'japanese'}};
    return 'japanese';
  } elsif ($language=~/^(kr|korean)(-?only)?$/) {
    @LogogramScripts=qw/Han Hangul/;
    if (defined $2) {$LetterPattern=undef;}
    @encodingGuessOrder=@{$NamedEncodingGuessOrder{'korean'}};
    return 'korean';
  } elsif ($language=~/^(kr|korean)-?words?(-?only)?$/) {
    if (defined $2) {
      @AlphabetScripts=qw/Hangul/;
      @LogogramScripts=qw/Han/;
    } else {
      @AlphabetScripts=qw/Digit Is_alphabetic Hangul/;
      @LogogramScripts=qw/Han Katakana Hiragana Thai Lao/;
    }
    @encodingGuessOrder=@{$NamedEncodingGuessOrder{'korean'}};
    return 'korean-words';
  } elsif ($language=~/^(char|character|letter)s?(-?only)?$/) {
    @WordPatterns=($NamedWordPattern{'letters'});
    if (defined $2) {@LogogramScripts=();}
    $countdesc[1]='Letters in text';
    $countdesc[2]='Letters in headers';
    $countdesc[3]='Letters in captions';
    return 'letter';
  } elsif ($language=~/^all-nonspace-(char|character|letter)s?$/) {
    @WordPatterns=($NamedWordPattern{'letters'});
    @AlphabetScripts=qw/Digit Is_alphabetic Is_punctuation/;
    $countdesc[1]='Characters in text';
    $countdesc[2]='Characters in headers';
    $countdesc[3]='Characters in captions';
    return 'nonspace-characters';
  } else {
    return undef;
  }
}

# Set encoding based on encoding options, guess encoding if not set
sub apply_encoding_options {
  if (defined $encoding && $encoding eq 'guess') {$encoding=undef;}
  if (!defined $encoding) {
  } elsif (ref(find_encoding($encoding))) {
    if (!$htmlstyle) {$outputEncoding=$encoding;}
  } else {
    error($Main,"Unknown encoding $encoding ignored.");
    error_details($Main,'Valid encodings are: '.wrap('','',join(', ',Encode->encodings(':all'))));
    $encoding=undef;
  }
  if (!defined $outputEncoding) {$outputEncoding='utf8';}
  binmode STDIN;
  binmode STDOUT,':encoding('.$outputEncoding.')';
}

# Apply language options
sub apply_language_options {
  my @tmp;
  if (defined $LetterPattern && @AlphabetScripts && scalar @AlphabetScripts>0) {
    @tmp=@AlphabetScripts;
    foreach (@tmp) {$_='\\p{'.$_.'}';}
    my $letterchars='['.join('',@tmp).']';
    my $letter=$LetterPattern;
    $letter=~s/@/$letterchars/g;
    @WordPatterns=map { s/\@/$letter/g ; qr/$_/ } @WordPatterns;
  } else {
    @WordPatterns=();
  }
  if (@LogogramScripts && scalar @LogogramScripts>0) {
    @tmp=@LogogramScripts;
    foreach (@tmp) {$_='\\p{'.$_.'}';}
    push @WordPatterns,'['.join('',@tmp).']';
  }
  if (scalar @WordPatterns==0) {
    error($Main,'No script (alphabets or logograms) defined. Using fallback mode.');
    push @WordPatterns,'\\w+';
  }
  $WordPattern=join '|',@WordPatterns;
}

# Apply incbib rule
sub apply_include_bibliography {
  include_package('%incbib');
}

# Process TC instruction, return 1 if applied, 0 if not (e.g. error)
sub tc_macro_param_option {
  my ($tex,$instr,$macro,$param,$option)=@_;
  if (!defined $param) {
    error($tex,'%TC:'.$instr.' requires parameter rule specification.');
    return 0;
  }
  elsif ($instr eq 'macro') {
    if (!($macro=~/^\\/)) {
      warning($tex,'%TC:macro '.$macro.': should perhaps be \\'.$macro.'?');
    }
    return _tc_macro_set_param($tex,\%TeXmacro,$instr,$macro,$param);
  }
  elsif ($instr eq 'exclude') {
    warning($tex,'%TC:exclude is deprecated. Use %TC:macro instead.');
    return _tc_macro_set_param($tex,\%TeXmacro,$instr,$macro,$param);
  }
  elsif ($instr eq 'header') {
    warning($tex,'%TC:header is deprecated. Instead use e.g. %TC:macro \\name [header].');
    $TeXmacrocount{$macro}=[$CNT_COUNT_HEADER];
    return _tc_macro_set_param($tex,\%TeXmacro,$instr,$macro,$param);
  }
  elsif ($instr eq 'preambleinclude') {
    return _tc_macro_set_param($tex,\%TeXpreamble,$instr,$macro,$param);
  }
  elsif ($instr eq 'floatinclude') {
    return _tc_macro_set_param($tex,\%TeXfloatinc,$instr,$macro,$param);
  }
  elsif ($instr=~/^(group|envir)$/) {
    if (!defined $option) {
      error($tex,'TC:'.$instr.' requires contents rule specification.');
      return 0;
    }
    defined ($option=key_to_state($option,$tex)) || return 0;
    $TeXenvir{$macro}=$option;
    return _tc_macro_set_param($tex,\%TeXmacro,$instr,$PREFIX_ENVIR.$macro,$param);
  }
  elsif ($instr=~/^(macrocount|macroword)$/) {
    return _tc_macro_set_param($tex,\%TeXmacrocount,$instr,$macro,$param,\&key_to_cnt,$REGEX_NUMBER);
  }
  elsif ($instr eq 'fileinclude') {
    # No parameter checking here, just pass on; errors reported when used instead.
    $param=~s/^\[(.*)\]$/$1/;
    $param=~s/,/ /g;
    assert($param=~/^\w+(\s\w+)*$/,$tex,'Invalid %TC:fileinclude parameter: '.$param)
    || return 0;
    $TeXfileinclude{$macro}=$param;
  }
  elsif ($instr eq 'breakmacro') {$BreakPoints{$macro}=$param;}
  else {
    error($tex,'Unknown TC command: '.$instr);
    return 0;
  }
  return 1;
}

# Convert TC command parameters and add to hash
sub _tc_macro_set_param {
  my ($tex,$hash,$instr,$macro,$param,$keymap,$validregex)=@_;
  if (!defined $keymap) {$keymap=\&key_to_state; $validregex=$REGEX_NUMBER;}
  $param=__interpret_tc_parameter($tex,$param,$keymap,$validregex);
  if (!defined $param) {return 0;}
  $hash->{$macro}=$param;
  return 1;
}

# Convert [...] into array of states, optionally return value if a valid pattern
sub __interpret_tc_parameter {
  my ($tex,$param,$keymap,$validregex)=@_;
  if ((defined $validregex) && ($param=~$validregex)) {
    return $param;
  } elsif ($param=~/^\[([0-9a-zA-Z,:]*)\]$/) {
    my @params;
    my $value;
    foreach my $key (split(',',$1)) {
      if ($key=~/^(\w*):(\w+)$/) {
        defined ($value=$keymap->($PREFIX_PARAM_OPTION.$1,$tex)) || return undef;
        push @params,$value;
        $key=$2;
      }
      defined ($value=$keymap->($key,$tex)) || return undef;
      push @params,$value;
    }
    return [@params];
  }
  error($tex,'Invalid TC command parameter: '.$param);
  return undef;
}



###### Macro rules handling


# Takes hash, value, list of keys and adds mappings to hash
sub add_keys_to_hash {
  my $hash=shift @_;
  my $value=shift @_;
  foreach (@_) {
    $hash->{$_}=$value;
  }
}

# Add source hash to target hash, optionally converting values
sub __add_to_hash {
  my $target=shift @_;
  my $source=shift @_;
  my $convert=shift @_;
  if (!defined $convert) {$convert=&__dummy;}
  while (my ($key,$val)=each(%$source)) {
    $target->{$key}=$convert->($val,@_);
  }
}

# Convert hash by applying function to all values
sub convert_hash {
  my $hash=shift @_;
  my $convert=shift @_;
  while (my ($key,$val)=each(%$hash)) {
    $hash->{$key}=$convert->($val,@_);
  }
}

# Convert key to parser state constant
sub key_to_state {
  my ($key,$tex)=@_;
  return key_convert(lc($key),$tex,\%key2state,'Unknown state key {key} replaced by IGNORE.',$STATE_IGNORE);
}

# Convert key array to parser state constants
sub keyarray_to_state {
  my ($array,$tex)=@_;
  return keyarray_convert($array,$tex,\&key_to_state);
}

# Convert key to counter constant
sub key_to_cnt {
  my ($key,$tex)=@_;
  return key_convert(lc($key),$tex,\%key2cnt,'Unknown counter key {key} ignored.');
}

# Convert key array to counter constants
sub keyarray_to_cnt {
  my ($array,$tex)=@_;
  return keyarray_convert($array,$tex,\&key_to_cnt);
}

# Convert key to value using map
sub key_convert {
  my ($key,$tex,$map,$error,$default)=@_;
  my $value=$map->{$key};
  if (!defined $value) {
    if (!defined $tex) {$tex=$Main;}
    $error=~s/\{key\}/$key/g;
    error($tex,$error);
    return $default;
  }
  return $value;
}

# Convert state keys to state nos for arrays
sub keyarray_convert {
  my ($array,$tex,$conv)=@_;
  if (ref($array) eq 'ARRAY') {
    my @ar;
    foreach my $key (@$array) {
      if (defined (my $cnt=$conv->($key,$tex))) {push @ar,$cnt;}
    }
    $array=\@ar;
  }
  return $array;
}

# Convert transition state to parsing state, and increment counter
sub transition_to_content_state {
  my ($tex,$state)=@_;
  my $tr=$transition2state{$state};
  if (defined $tr) {
    if (my $cnt=$tr->[1]) {inc_count($tex,$tr->[1]);}
    return $tr->[0];
  }
  return $state;
}

# Remove all rules
sub remove_all_rules {
  %TeXpackageinc=();
  %TeXpreamble=();
  %TeXfloatinc=();
  %TeXmacro=();
  %TeXmacrocount=();
  %TeXenvir=();
  %TeXfileinclude=();
  %IncludedPackages=();
}

# Process package inclusion
sub include_package {
  my ($incpackage,$tex)=@_;
  if (defined $IncludedPackages{$incpackage}) {return;}
  $IncludedPackages{$incpackage}=1;
  # Add rules for package, preamble and float inclusion, and add to macro rules
  _add_package(\%TeXpackageinc,\%PackageTeXpackageinc,$incpackage,\&__dummy,$tex);
  _add_package(\%TeXpreamble,\%PackageTeXpreamble,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXfloatinc,\%PackageTeXfloatinc,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXmacro,\%PackageTeXpackageinc,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXmacro,\%PackageTeXpreamble,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXmacro,\%PackageTeXfloatinc,$incpackage,\&keyarray_to_state,$tex);
  # Add regular rules
  _add_package(\%TeXmacro,\%PackageTeXmacro,$incpackage,\&keyarray_to_state,$tex);
  _add_package(\%TeXmacrocount,\%PackageTeXmacrocount,$incpackage,\&keyarray_to_cnt,$tex);
  _add_package(\%TeXenvir,\%PackageTeXenvir,$incpackage,\&key_to_state,$tex);
  _add_package(\%TeXfileinclude,\%PackageTeXfileinclude,$incpackage,\&__dummy,$tex);
  if (my $subpackages=$PackageSubpackage{$incpackage}) {
    foreach my $sub (@{$subpackages}) {
      include_package($sub,$tex);
    }
  }
}

# Add package rules if defined
sub _add_package {
  my ($target,$source,$name,$convert,$tex)=@_;
  my $sub;
  if ($sub=$source->{$name}) {
    __add_to_hash($target,$sub,$convert);
  }
}

# Dummy conversion function: returns arguments unchanged
sub __dummy {
  return shift @_;
}


###### TeX code handle



# Return object capable of capturing errors for use when
# no TeXcode object is available.
sub getMain {
  my %main=();
  $main{'errorcount'}=0;
  $main{'errorbuffer'}=[];
  $main{'warnings'}={};
  return \%main;
}


## Make TeX handle for LaTeX code: the main TeXcount object
# The "TeX object" is a data containser: a hash containing
#  - filepath: path of LaTeX file being parsed
#  - filename: file name of LaTeX file
#  - dirpath: path to directory containing LaTeX file
#  - PATH: array of paths to search for included files
#  - countsum: count object with total count (incl. subcounts)
#  - subcount: count object for subcount (to be added to countsum)
#  - subcounts: list of subcounts
#  - errorcount: the number of errors reported
# plus following elements used for the processing the LaTeX code 
#  - line: the LaTeX paragraph being processed
#  - texcode: what remains of LaTeX code to process (after line)
#  - texlength: length of LaTeX code
#  - next: the next token, i.e. the one being processed
#  - type: the type of the next token
#  - style: the present output style (for verbose output)
#  - printstate: present parsing state (for verbose output only)
#  - eof: set once the end of the input is reached
# which are passed to methods by passing the TeX object. It is used when parsing
# the LaTeX code, and discarded once the parsing is done. During parsing, counts
# are added to the subcount element; whenever a break point is encountered, the
# subcount is added to the countsum (next_subcount) and a new subcount object
# prepared. Note that this requires that the last subcount object be added to
# the countsum once the end of the document is reached.
sub TeXcode {
  my ($bincode,$file,$title)=@_;
  my $tex=_TeXcode_blank($file,$title);
  _TeXcode_setcode($tex,$bincode);
  more_texcode($tex);
  return $tex;
}

# Return a blank TeXcode object
sub _TeXcode_blank {
  my ($file,$title)=@_;
  if (defined $title) {}
  elsif (defined $file) {$title='File: '.$file;}
  else {$title='Word count';}
  my %TeX=();
  $TeX{'errorcount'}=0;
  $TeX{'warnings'}={};
  $TeX{'filepath'}=$file;
  if (!defined $file) {}
  elsif ($file=~/^<.+>$/) {$TeX{'filename'}=$file;}
  elsif ($file=~/^(.*[\\\/])([^\\\/]+)$/) {
    $TeX{'dirpath'}=$1; $TeX{'filename'}=$2;
  }
  else {$TeX{'dirpath'}=''; $TeX{'filename'}=$file;}
  $TeX{'PATH'}=[];
  $TeX{'line'}='';
  $TeX{'next'}=undef;
  $TeX{'type'}=undef;
  $TeX{'style'}=undef;
  $TeX{'printstate'}=undef;
  $TeX{'eof'}=0;
  my $countsum=new_count($title);
  $TeX{'countsum'}=$countsum;
  $countsum->{'TeXcode'}=\%TeX;
  my $count=new_count('_top_');
  $TeX{'subcount'}=$count;
  inc_count(\%TeX,$CNT_FILE);
  return \%TeX;
}

# Set the texcode element of the TeXcount object
sub _TeXcode_setcode {
  my ($tex,$bincode)=@_;
  $tex->{'texcode'}=_prepare_texcode($tex,$bincode);
  $tex->{'texlength'}=length($tex->{'texcode'});
}

# Decode and return TeX/LaTeX code
sub _prepare_texcode {
  my ($tex,$texcode)=@_;
  $texcode=_decode_texcode($tex,$texcode);
  foreach my $key (keys %substitutions) {
    my $value=$substitutions{$key};
    $texcode=~s/(\w)\Q$key\E/$1 $value/g;
    $texcode=~s/\Q$key\E/$value/g;
  }
  return $texcode;
}

# Return text decoder
sub _decode_texcode {
  my ($tex,$texcode)=@_;
  my $decoder;
  if (defined $encoding) {
    $decoder=find_encoding($encoding);
    eval {$texcode=$decoder->decode($texcode);};
    if ($@) {
      error($tex,'Decoding file/text using the '.$decoder->name.' encoding failed.');
    }
  } else {
    ($texcode,$decoder)=_guess_encoding($texcode);
    if (!ref($decoder)) {
      error($tex,'Failed to identify encoding or incorrect encoding specified.');
      $tex->{'encoding'}='[FAILED]';
      return $texcode;
    }
  }
  __set_encoding_name($tex,$decoder->name);
  $texcode =~ s/^\x{feff}//; # Remove BOM (relevant for UTF only)
  if ($texcode =~/\x{fffd}/ ) {
    error($tex,'File/text was not valid '.$decoder->name.' encoded.');
  }
  return $texcode;
}

# Guess the right encoding to use
sub _guess_encoding {
  my ($texcode)=@_;
  foreach my $enc (@encodingGuessOrder) {
    my $dec=find_encoding($enc);
    if (ref($dec)) {
      eval {
        $texcode=$dec->decode($texcode,Encode::FB_CROAK)
      };
      if (!$@) {return $texcode,$dec;}
    }
  }
  return $texcode,undef;
}

# Set name of current encoding
sub __set_encoding_name {
  my ($tex,$enc)=@_;
  my $cur=$tex->{'encoding'};
  if (!defined $enc) {$enc='[FAILED]';} # Shouldn't happen here though...
  if (!defined $cur) {}
  elsif ($enc eq 'ascii') {$enc=$cur;}
  elsif ($cur eq 'ascii') {}
  elsif ($cur ne $enc) {
    error($tex,"Mismatching encodings: $cur versus $enc.");
  }
  $tex->{'encoding'}=$enc;
}

# Apply substitution rule
sub apply_substitution_rule {
  my ($tex,$from,$to)=@_;
  $tex->{'line'}=~s/(\w)\Q$from\E\b\s*/$1 $to/g;
  $tex->{'line'}=~s/\Q$from\E\b\s*/$to/g;
  $tex->{'texcode'}=~s/(\w)\Q$from\E\b\s*/$1 $to/g;
  $tex->{'texcode'}=~s/\Q$from\E\b\s*/$to/g;
}

## Get more TeX code from texcode buffer if possible, return 1 if done
sub more_texcode {
  my ($tex)=@_;
  if ($tex->{'texcode'} eq '') {return 0;}
  if ( $optionFast && $tex->{'texcode'} =~ s/^(.*?(\r{2,}|\n{2,}|(\r\n){2,}))//s ) {
    $tex->{'line'}.=$1; # $1 ~ ${^MATCH}
    return 1;
  }
  $tex->{'line'}.=$tex->{'texcode'};
  $tex->{'texcode'}='';
  return 1;
}

## Prepend LaTeX code to TeXcode object
sub prepend_code {
  my ($tex,$code,$filename)=@_;
  my $prefix="\n% --- Start of included file $filename\n";
  my $suffix="\n% --- End of included file $filename\n";
  $code=_decode_texcode($tex,$code);
  $tex->{'length'}+=length($code);
  $tex->{'texcode'}=$prefix.$code.$suffix.$tex->{'line'}.$tex->{'texcode'};
  $tex->{'line'}='';
  more_texcode($tex);
}

# Save and return TeXcode state, and replace with new text
sub texcode_insert_text {
  my ($tex,$code,$filename,@path)=@_;
  my %texstate=(
      'texcode'=>$tex->{'line'}.$tex->{'texcode'},
      'eof'=>$tex->{'eof'},
      'PATH'=>$tex->{'PATH'});
  my $prefix="\n% --- Start of included file $filename\n";
  my $suffix="\n% --- End of included file $filename\n";
  $code=_decode_texcode($tex,$code);
  $tex->{'length'}+=length($code);
  $tex->{'texcode'}=$prefix.$code.$suffix;
  $tex->{'line'}='';
  more_texcode($tex);
  return \%texstate;
}

# Restore TeXcode state
sub texcode_restore_state {
  my ($tex,$texstate)=@_;
  while (my ($key,$value)=each %$texstate) {
    $tex->{$key}=$value;
  }
}

## Returns size of TeX code in bytes
sub get_texsize {
  my $tex=shift @_;
  return $tex->{'texlength'}
}



###### TeX file reader


# Read LaTeX file into TeX object
sub TeXfile {
  my ($filename,$title)=@_;
  my ($header,$bincode);
  if ($filename eq $_STDIN_) {
    $header='File from STDIN';
    $bincode=_read_stdin();
  } else {
    defined ($bincode=read_binary($filename)) || return undef;
    $header='File: '.$filename;
  }
  if ($printlevel>0) {
    formatprint($header."\n",'h2');
    $blankline=0;
  }
  my $tex=TeXcode($bincode,$filename,$title);
  return $tex;
}

# Read file to string without regard for encoding
sub read_binary {
  my $filename=shift @_;
  open(FH,$filename) || return undef;
  binmode(FH);
  my $bincode;
  read(FH,$bincode,-s FH);
  close(FH);
  return $bincode;
}

# Read file from STDIN
sub _read_stdin {
  my @text=<STDIN>;
  my $latexcode=join('',@text);
  return $latexcode;
}


###### Error handling


# Print note to output
sub note {
  my ($tex,$level,$text,$prefix,$style)=@_;
  if ($printlevel>=$level) {
    $prefix=(defined $prefix)?$prefix:'%NOTE: ';
    $style=(defined $style)?$style:'note';
    $text=count_in_template($tex->{'subcount'},$text);
    flush_next($tex);
    line_return(0,$tex);
    print_style($prefix.$text,$style);
    flush_next($tex);
    $blankline=-1;    
  }
}

# Compare count with expected and note if assertion fails
sub assertion_note {
  my ($tex,$checktext,$template)=@_;
  my $count=$tex->{'subcount'};
  my @check=split(/,/,$checktext);
  my @actual;
  for (my $i=scalar @check;$i>0;$i--) {$actual[$i-1]=get_count($count,$i);}
  for (my $i=scalar @check;$i>0;$i--) {
    if ($check[$i-1] ne $actual[$i-1]) {
      my $msg=$template.' [expected:'.join('+',@check).'; found: '.join('+',@actual).']';
      note($tex,0,$msg,'%ASSERTION FAILED: ','error');
      return 1;
    }
  }
  return 0;
}

# Add warning to list of registered warnings (optionally to be reported at the end)
sub warning {
  my ($tex,$text)=@_;
  $warnings{$text}++;
  # TODO: should only add warnings to subcount, not to TeXcode object
  $tex->{'warnings'}->{$text}++;
  if (my $count=$tex->{'subcount'}) {$count->{'warnings'}->{$text}++};
}

# Register error and print error message
sub error {
  my ($tex,$text,$type)=@_;
  if (defined $type) {$text=$type.': '.$text;}
  $errorcount++;
  $tex->{'errorcount'}++;
  if (my $count=$tex->{'subcount'}) {$count->{'errorcount'}++};
  if (my $err=$tex->{'errorbuffer'}) {push @$err,$text;}
  else {print_error($text);}
}

# Print error details
sub error_details {
  my ($tex,$text)=@_;
  print STDERR $text,"\n";
}

# Make assertion: i.e. report error if not true and return truthfullness
sub assert {
  my $assertion=shift @_;
  if ($assertion) {return 1;}
  error(@_);
  return 0;
}

# Print error message
sub print_error {
  my $text=shift @_;
  line_return(1);
  if ($printlevel<0) {
    print STDERR 'ERROR: ',$text,"\n";
  } elsif ($htmlstyle) {
    print STDERR 'ERROR: ',$text,"\n";
    print_style($text,'error');
  } else {
    print_style("!!! $text !!!",'error');
  }
  line_return(1);
}

# Print errors in buffer and delete errorbuffer
sub flush_errorbuffer {
  my $source=shift @_;
  my $err=$source->{'errorbuffer'} || return;
  foreach (@$err) {print_error($_);}
  $source->{'errorbuffer'}=undef;
}


###### Parsing routines


# Parse LaTeX document
sub parse {
  my ($tex)=@_;
  if ($htmlstyle && $printlevel>0) {print "<div class='parse'><p>\n";}
  parse_all($tex);
  if ($htmlstyle && $printlevel>0) {print "</p></div>\n";}
}

# Parse until end
sub parse_all {
  my ($tex,$state)=@_;
  if (!defined $state) {$state=$STATE_TEXT;}
  while (!($tex->{'eof'})) {
    _parse_unit($tex,$state);
  }
}

# Parse one block/unit with given state until end token
# If end token is set to $_PARAM_, unit is assumed to be a parameter
# and words parsed as individual letters (simple_token is set)
sub _parse_unit {
  my ($tex,$state,$end)=@_;
  my $simple_token=0;
  (  assert(defined $state,$tex,'Undefined parser state!','BUG')
  && assert(!ref($state),$tex,'Invalid parser state of type '.ref($state).'!','BUG')
  ) || exit;
  $state=transition_to_content_state($tex,$state);
  _set_printstate($tex,$state,$end);
  if (defined $end && $end eq $_PARAM_) {
    $end=undef;
    $simple_token=1;
  }
  my $next;
  my @specarg;
  while (defined ($next=next_token($tex,$simple_token))) {
    # Parse next token until token matches $end
    set_style($tex,'ignore');
    if ($state==$STATE_MATH) {set_style($tex,'math');}
    if ((defined $end) && ($end eq $next)) {return @specarg;}
    # Determine how token should be interpreted
    if ($state==$STATE_PREAMBLE && $next eq '\begin' && $tex->{'line'}=~/^\{\s*document\s*\}/) {
      # \begin{document}
      $state=$STATE_TEXT;
    }
    # Pick the first matching interpretation:
    if ($state==$STATE_EXCLUDE_ALL) {
      # ignore everything
    } elsif ($tex->{'type'}==$TOKEN_SPACE) {
      # space or other code that should be passed through without styling
      flush_next($tex,' ');
    } elsif ($next eq '{') {
      # {...} group
      set_style($tex,'ignore');
      push @specarg,_parse_unit($tex,$state,'}');
      set_style($tex,'ignore');
    } elsif ($next eq '}') {
      error($tex,'Encountered } without corresponding {.');
    } elsif ($tex->{'type'}==$TOKEN_TC) {
      # parse TC instructions
      _parse_tc($tex,$next);
    } elsif ($state==$STATE_SPECIAL_ARGUMENT) {
      set_style($tex,'specarg');
      push @specarg,$next;
    } elsif ($tex->{'type'}==$TOKEN_WORD) {
      # word
      if (my $cnt=state_text_cnt($state)) {
        _process_word($tex,$next,$state);
        inc_count($tex,$cnt);
        set_style($tex,state_to_style($state));
      }
    } elsif ($state==$STATE_EXCLUDE_STRONGER) {
      # ignore remaining tokens
      set_style($tex,'ignore');
    } elsif ($next eq '\documentclass') {
      # defines document class and starts preamble
      set_style($tex,'document');
      _parse_documentclass_params($tex);
      while (!($tex->{'eof'})) {
        push @specarg,_parse_unit($tex,$STATE_PREAMBLE);
      }
    } elsif ($tex->{'type'}==$TOKEN_MACRO) {
      # macro call
      _parse_macro($tex,$next,$state);
    } elsif ($next eq '$') {
      # math inline
      _parse_math($tex,$state,$CNT_COUNT_INLINEMATH,'$');
    } elsif ($next eq '$$') {
      # math display (unless already in inlined math)
      if (!(defined $end && $end eq '$')) {
        _parse_math($tex,$state,$CNT_COUNT_DISPLAYMATH,'$$');
      }
    } elsif ($simple_token) {
      #DELETE: simple tokens should be handled properly
      #print STDERR '<',$next,'>',"\n";
      # handle as parameter that should not be counted
      set_style($tex,'ignore');
    }
    if (!defined $end) {return @specarg;}
  }
  defined $end && error($tex,'Reached end of file while waiting for '.$end.'.');
  return @specarg;
}

# Print state
sub _set_printstate {
  my ($tex,$state,$end)=@_;
  $tex->{'printstate'}=':'.state_to_text($state).(defined $end?'>'.$end:'').':';
  flush_next($tex);
}

# Process word with a given state (>0, i.e. counted)
sub _process_word {
  my ($tex,$word,$state)=@_;
  $WordFreq{$word}++;
}

# Parse unit when next token is a macro
sub _parse_macro {
  my ($tex,$next,$state)=@_;
  my $substat;
  my @macro=($next);
  if (my $label=$BreakPoints{$next}) {
    if ($tex->{'line'}=~ /^[*]?(\s*\[.*?\])*\s*\{((.|\{.*\})*)\}/ ) {
      $label=$label.': '.$2;
    }
    next_subcount($tex,$label);
  }
  if ($state==$STATE_MATH) {set_style($tex,'mathcmd');}
  elsif ($state==$STATE_SPECIAL_ARGUMENT) {set_style($tex,'specarg');}
  else {set_style($tex,state_is_text($state)?'cmd':'exclcmd');}
  if ($next eq '\begin' && state_inc_envir($state)) {
    _parse_envir($tex,$state);
    push @macro,'<envir>';
  } elsif ($next eq '\end' && state_inc_envir($state)) {
    error($tex,'Encountered \end without corresponding \begin');
    push @macro,$STRING_ERROR;
  } elsif ($next eq '\verb') {
    _parse_verb_region($tex,$state);
  } elsif (state_is_parsed($state) && defined (my $substat=$TeXpackageinc{$next})) {
    # Parse macro parameters, use _parse_include_argument to process package list
    set_style($tex,'document');
  	push @macro,__gobble_macro_parms($tex,$substat,$__STATE_NULL,\&_parse_include_argument);
    push @macro,'<package>';
  } elsif (state_is_parsed($state) && defined (my $def=$TeXfileinclude{$next})) {
    # include file (merge in or queue up for parsing)
    set_style($tex,'cmd');
    if (defined ($substat=$TeXmacro{'@pre'.$next})) {__gobble_macro_parms($tex,$substat,$state);}
    __count_macrocount($tex,$next,$state);
    _parse_include_file($tex,$state,$def);
    push @macro,'<filespec>';
    if (defined ($substat=$TeXmacro{'@post'.$next})) {__gobble_macro_parms($tex,$substat,$state);}
  } elsif (($state==$STATE_FLOAT) && ($substat=$TeXfloatinc{$next})) {
    # text included from float
    set_style($tex,'cmd');
    push @macro,__gobble_macro_parms($tex,$substat,$__STATE_NULL);
  } elsif ($state==$STATE_PREAMBLE && defined ($substat=$TeXpreamble{$next})) {
    # parse preamble include macros
    set_style($tex,'cmd');
    __count_macrocount($tex,$next,$STATE_TEXT);
    push @macro,__gobble_macro_parms($tex,$substat,$__STATE_NULL);
  } elsif (state_is_exclude($state)) {
   # ignore
    push @macro,__gobble_options($tex),'/*ignored*/';
  } elsif ($next eq '\(') {
    # math inline
    _parse_math($tex,$state,$CNT_COUNT_INLINEMATH,'\)');
  } elsif ($next eq '\[') {
    # math display
    _parse_math($tex,$state,$CNT_COUNT_DISPLAYMATH,'\]');
  } elsif ($next=~/^\\(def|edef|gdef|xdef)$/) {
    # ignore \def...
    $tex->{'line'} =~ s/^([^\{]*)\{/\{/;
    flush_next($tex);
    print_style($1,'ignore');
    _parse_unit($tex,$STATE_EXCLUDE_STRONG);
    push @macro,'<macro>',$STRING_PARAMETER;
  } elsif (defined ($substat=$TeXmacro{$next})) {
    # macro: exclude options
    __count_macrocount($tex,$next,$state);
    push @macro,__gobble_macro_parms($tex,$substat,$state);
  } elsif (defined __count_macrocount($tex,$next,$state)) {
    # count macro as word (or a given number of words)
  } elsif ($next =~ /^\\[^\w\_]$/) {
    # handle \<symbol> as single symbol macro
    push @macro,__gobble_options($tex),'/*symbol*/';
  } else {
    push @macro,__gobble_options($tex),'/*defaultrule*/';
  }
  $MacroUsage{join('',@macro)}++;
}

# Parse TC instruction
sub _parse_tc {
  my ($tex,$next)=@_;
  set_style($tex,'tc');
  flush_next($tex);
  assert($next=~s/^\%+TC:\s*(\w+)\s*//i
    ,$tex,'TC command should have format %TC:instruction [[parameters]]')
  || return;
  my $instr=$1;
  $instr=~tr/[A-Z]/[a-z]/;
  if ($instr eq 'break') {next_subcount($tex,$next);
  } elsif ($instr=~/^(incbib|includebibliography)$/) {
    $includeBibliography=1;
    apply_include_bibliography();
  } elsif ($instr eq 'ignore') {__gobble_tc_ignore($tex);
  } elsif ($instr eq 'endignore') {error($tex,'%TC:endignore without corresponding %TC:ignore.');
  } elsif ($instr eq 'newtemplate') {$outputtemplate='';
  } elsif ($instr eq 'template') {$outputtemplate.=$next;
  } elsif ($instr eq 'insert') {
    $tex->{'line'}="\n".$next.$tex->{'line'};
  } elsif ($instr eq 'subst') {
    if ($next=~/^(\S+)\s*(\S.*)?$/) {
      my $from=$1;
      my $to=$2;
      $substitutions{$from}=$to;
      apply_substitution_rule($tex,$from,$to);
    } else {
      error($tex,'Invalid %TC:subst format.');
    }
  } elsif ($instr eq 'newcounter') {
    assert($next=~s/^(\w+)(=(\w+))?\s*//,$tex,'Expected format: %TC:newcounter {key}[={like-key}] {description}')
    || return;
    my $key=$1;
    my $like=$3;
    if ($next eq '') {$next=$key;}
    add_new_counter($key,$next,$like);
  } elsif ($instr eq 'log') {
    assert($next=~s/^(.*)$//,$tex,'Expected format: %TC:log {text or template}') || return;
    note($tex,1,$1);
  } elsif ($instr eq 'assert') {
    assert($next=~s/^(\d+(,\d+)*)(\s+(.*))?$//,$tex,'Expected format: %TC:assert count+count+... {text or template}')
    || return;
    my $template=$4 || 'Words counted: {w} in text, {hw} in headers, {ow} other.';
    assertion_note($tex,$1,$template);
  } elsif ($next=~/^([\\]*\S+)\s+([^\s]+)(\s+(-?\w+))?/) {
    # %TC:instr macro param option
    my $macro=$1;
    my $param=$2;
    my $option=$4;
    tc_macro_param_option($tex,$instr,$macro,$param,$option);
  } else {
    error($tex,'Invalid TC command: '.$instr);
  }
}

# Parse math formulae
sub _parse_math {
  my ($tex,$state,$cnt,$end)=@_;
  my $localstyle;
  if (state_is_text($state)) {
    $localstyle='mathgroup';
    inc_count($tex,$cnt);
  } else {
    $localstyle='exclmath';
  }
  set_style($tex,$localstyle);
  _parse_unit($tex,$STATE_MATH,$end);
  set_style($tex,$localstyle);
}

# Parse \verb region
sub _parse_verb_region {
 my ($tex,$state)=@_;
 #flush_next($tex);
 __gobble_macro_modifier($tex);
 set_style($tex,'ignore');
 assert($tex->{'line'} =~ s/^([^\s])//,$tex,'Invalid \verb: delimiter required.')
 || return;
 my $dlm=$1;
 print_style($dlm,'cmd');
 assert($tex->{'line'}=~s/^([^\Q$dlm\E]*)(\Q$dlm\E)//
   ,$tex,'Invalid \verb: could not find ending delimiter ('.$dlm.').')
 || return;
 print_style($1,'ignore');
 print_style($2,'cmd');
}

# Parse environment
sub _parse_envir {
  my ($tex,$state)=@_;
  my $localstyle=state_is_text($state) ? 'envir' : 'exclenv';
  flush_next_gobble_space($tex,$localstyle,$state);
  my ($envirname,$next);
  if ($tex->{'line'} =~ s/^\{([^\{\}\s]+)\}[ \t\r\f]*//) {
    # gobble environment name
    $envirname=$1;
    my @macro=('<envir:'.$envirname.'>');
    print_style('{'.$1.'}',$localstyle);
    $next=$PREFIX_ENVIR.$envirname;
    __count_macrocount($tex,$next,$state);
    if (defined (my $def=$TeXmacro{$next})) {
      push @macro,__gobble_macro_parms($tex,$def,$__STATE_NULL);
    } else {
      push @macro,__gobble_options($tex);
    }
    $MacroUsage{join('',@macro)}++;
  } else {
    $envirname='???'; $next='???';
    error($tex,'Encountered \begin without environment name provided.');
  }
  # find new parsing state (or leave unchanged)
  my $substat=$TeXenvir{$1};
  if (!defined $substat) {
    $substat=$state;
    if ($strictness>=1) {
      warning($tex,'Using default rule for environment '.$envirname);
    }
  } else {
    $substat=__new_state($substat,$state);
  }
  if (state_inc_envir($substat)) {
    # Parse until \end arrives, and check that it matches
    _parse_unit($tex,$substat,'\end');
    flush_next_gobble_space($tex,$localstyle,$state);
    if ($tex->{'line'} =~ s/^\{([^\{\}\s]+)\}[ \t\r\f]*//) {
      # gobble environment name
      print_style('{'.$1.'}',$localstyle);
      assert($envirname eq $1,$tex,"Environment \\begin{$envirname} ended with \\end{$1}.");
    } else {
      error($tex,"Environment ended while waiting for \end{$envirname}.");
    }  
  } else {
    # Keep parsing until appropriate \end arrives ignoring all else
    while (!$tex->{'eof'}) {
      _parse_unit($tex,$substat,'\end');
      if ($tex->{'line'} =~ s/^(\s*)(\{\Q$envirname\E\})[ \t\r\f]*//) {
        # gobble \end parameter and end environment
        flush_next($tex,$localstyle,$state);
        print_style($1,$localstyle);
        print_style($2,$localstyle);
        return;
      }
    }
  }
}

# Parse and process file inclusion
sub _parse_include_file {
  my ($tex,$state,$includetype)=@_;
  my $include=state_is_parsed($state);
  my $style=$include?'fileinc':'ignore';
  my $file;
  my %params;
  flush_next($tex);
  $params{'<type>'}=$includetype;
  $params{'SUFFICES'}=[''];
  if ($includetype eq '<bbl>') {
    _parse_include_bbl($tex,$state,\%params);
    return;
  }
  elsif ($includetype eq 'input') {
    $tex->{'line'} =~ s/^(\s*\{([^\{\}\s]+)\})//
    || $tex->{'line'} =~ s/^(\s*([^\{\}\%\\\s]+))//
    || $tex->{'line'} =~ s/^(\s*\{(.+?)\})//
    || BLOCK {
      error($tex,'Failed to identify file name.');
      return;
    };
    print_style($1,$style);
    $file=$2;
    if (!($file=~/\.tex$/i)) {$params{'SUFFICES'}=['.tex',''];}
  }
  else {
    foreach my $param (split(/\s+|,/,$includetype)) {
      if ($param=~/^<.*>$/) {next;}
      $tex->{'line'} =~ s/(\s*\{)([^\{\}\%]*)(\})//|| BLOCK {
        error($tex,"Failed to identify file parameter {$param}.");
        return;
      };
      print_style($1,'ignore');
      print_style($2,$style);
      print_style($3,'ignore');
      if ($param eq 'file') {
        $file=$2;
        if (!($file=~/\.tex$/i)) {$params{'SUFFICES'}=['.tex',''];}
      } elsif ($param eq 'texfile') {
        $file=$2.'.tex';
      } else {$params{$param}=$2;}
    }
  }
  if (!defined $file) {
    error($tex,'Undefined file name.');
  }
  elsif ($includeTeX && $include) {
    include_file($tex,$state,$file,\%params);
  }
}

# Parse and process bibliography file
sub _parse_include_bbl {
  my ($tex,$state,$params)=@_;
  if ($includeBibliography && state_is_text($state)) {
    my $filename=$tex->{'filename'};
    $filename=~s/(\.tex)?$/\.bbl/i;
    include_file($tex,$state,$filename,$params);
  }
}

# Parse and process package inclusion
sub _parse_include_package {
  my ($tex)=@_;
  set_style($tex,'document');
  if ( $tex->{'line'}=~s/^\{(([\w\-]+)(\s*,\s*[\w\-]+)*)\}// ) {
    print_style("{$1}",'document');
    foreach (split(/\s*,\s*/,$1)) {
      $MacroUsage{"<package:$_>"}++;
      include_package($_,$tex);
    }
  } else {
    _parse_unit($tex,$STATE_IGNORE);
    error($tex,'Could not recognise package list, ignoring it instead.');
  }
}

# Extract package names from token list and include packages
sub _parse_include_argument {
  my $tex=shift @_;
  my $args=join('',@_);
  set_style($tex,'document');
  foreach (split(/\s*,\s*/,$args)) {
    $MacroUsage{"<package:$_>"}++;
    include_package($_,$tex);
  }
}

# Parse \documentclass parameters and include rules
sub _parse_documentclass_params {
  my ($tex)=@_;
  my $options=__gobble_option($tex);
  if ( $tex->{'line'}=~s/^(\{\s*([^\{\}\s]+)\s*\})// ) {
    print_style("$1",'document');
    $MacroUsage{"<documentclass:$2>"}++;
    include_package("class%$2",$tex);
  } else {
    _parse_unit($tex,$STATE_IGNORE);
    error($tex,'Could not identify document class.');
  }
}

# Count macrocount using given state
sub __count_macrocount {
  my ($tex,$next,$state)=@_;
  my $def=$TeXmacrocount{$next};
  my $cnt;
  if (!defined $def) {return undef;}
  elsif (ref($def) eq 'ARRAY') {
    # TODO: Is this an appropriate style to use?
    set_style($tex,state_to_style($state));
    flush_next($tex);
    foreach $cnt (@{$def}) {
      if ($cnt==$CNT_WORDS_TEXT) {$cnt=state_text_cnt($state);}
      inc_count($tex,$cnt);
    }
  }
  elsif ($cnt=state_text_cnt($state)) {
    set_style($tex,state_to_style($state));
    flush_next($tex);
    inc_count($tex,$cnt,$def);
  }
  return $def;
}

# Gobble next option, return option or undef if none
sub __gobble_option {
  my $tex=shift @_;
  flush_next_gobble_space($tex);
  if ($tex->{'line'}=~s/^($MacroOptionPattern)//) {
    print_style($1,'option');
    return $1;
  }
  return undef;
}

# Gobble all options, return the number of gobble options 
sub __gobble_options {
  my $n=0;
  while (__gobble_option(@_)) {$n++}
  return ($STRING_GOBBLED_OPTION)x$n;
}

# Gobble macro modifyer (e.g. following *)
sub __gobble_macro_modifier {
  my $tex=shift @_;
  flush_next($tex);
  if ($tex->{'line'} =~ s/^(\*)//) {
    print_style($1,'option');
    return $1;
  }
  return;
}

# Gobble macro parameters as specified in parm plus options
sub __gobble_macro_parms {
  my ($tex,$parm,$oldstat,$specarghandler)=@_;
  my $n;
  my @ret;
  if (ref($parm) eq 'ARRAY') {
    $n=scalar @{$parm};
  } else {
    $n=$parm;
    $parm=[($STATE_IGNORE)x$n];
  }
  # TODO: Optionally gobble macro modifier?
  if ($n>0) {push @ret,__gobble_macro_modifier($tex);}
  my $auto_gobble_options=1;
  for (my $j=0;$j<$n;$j++) {
    my $p=$parm->[$j];
    if ($p==$_STATE_OPTION) {
      # Parse macro option
      $p=$parm->[++$j];
      if ($tex->{'line'}=~s/^(\s*\[)//) {
        flush_next_gobble_space($tex);
        print_style($1,'optparm');
        push @ret,$STRING_OPTIONAL_PARAM;
        _parse_unit($tex,__new_state($p,$oldstat),']');
        set_style($tex,'optparm');
      }
    } elsif ($p==$_STATE_NOOPTION) {
      $auto_gobble_options=0;
    } elsif ($p==$_STATE_AUTOOPTION) {
      $auto_gobble_options=1;
    } else {
      # Parse macro parameter
      if ($auto_gobble_options) {push @ret,__gobble_options($tex);}
      push @ret,$STRING_PARAMETER;
      my @specarg=_parse_unit($tex,__new_state($p,$oldstat),$_PARAM_);
      if ($p==$STATE_SPECIAL_ARGUMENT && defined $specarghandler) {
        &$specarghandler($tex,@specarg);
      }
    }
  }
  #TODO: Drop default gobbling of option at end?
  if ($auto_gobble_options) {push @ret,__gobble_options($tex);}
  return @ret;
}

# Parse through ignored LaTeX code
sub __gobble_tc_ignore {
  my ($tex)=@_;
  set_style($tex,'ignore');
  _parse_unit($tex,$STATE_EXCLUDE_ALL,'%TC:endignore');
  set_style($tex,'tc');
  flush_next($tex);
}

# Return new parsing state given old and substate
sub __new_state {
  my ($substat,$oldstat)=@_;
  if (!defined $oldstat) {return $substat;}
  foreach my $st (@STATE_FIRST_PRIORITY,@STATE_MID_PRIORITY,@STATE_LAST_PRIORITY) {
    if ($oldstat==$st || $substat==$st) {return $st;}
  }
  error($Main,'Could not determine new state in __new_state!','BUG');
  return $oldstat;
}



###### Tokenisation routines


# Get next token skipping comments and flushing output buffer
sub next_token {
  my ($tex,$simple_token)=@_;
  if (!defined $simple_token) {$simple_token=0;}
  my ($next,$type);
  my $style=$tex->{'style'};
  if (defined $tex->{'next'}) {print_style($tex->{'next'},$tex->{'style'});}
  $tex->{'style'}=undef;
  while (defined ($next=_get_next_token($tex,$simple_token))) {
    $type=$tex->{'type'};
    if ($type==$TOKEN_COMMENT) {
      print_style($next,'comment');
    } elsif ($type==$TOKEN_LINEBREAK) {
      if ($printlevel>0) {line_return(-1,$tex);}
    } else {
      return $next;
    }
  }
  return $next;
}

# Read, interpret and return next token
# If simple_token is set, words cannot form tokens
sub _get_next_token {
  my ($tex,$simple_token)=@_;
  my $next;
  my $ch;
  while (!$tex->{'eof'}) {
    $ch=substr($tex->{'line'},0,1);
    if ($ch eq '') {
      if (!more_texcode($tex)) {$tex->{'eof'}=1;}
      next;
    } elsif ($ch=~/^[ \t\f]/) {
      $tex->{'line'}=~s/^([ \t\f]+)//;
      return __set_token($tex,$1,$TOKEN_SPACE);
    } elsif ($ch eq "\n" || $ch eq "\r") {
      $tex->{'line'}=~s/^(\r\n?|\n)//;
      return __set_token($tex,$1,$TOKEN_LINEBREAK);
    } elsif (!$simple_token && $tex->{'line'}=~s/^($WordPattern)//o) {
      return __set_token($tex,$1,$TOKEN_WORD);
    } elsif ($simple_token && $tex->{'line'}=~s/^(\w)//) {
      # When parsing simple tokens (not words), only include single characters
      # TODO: the handling of simple tokens should be improved
      my $match=$1;
      if ($match=~/^$WordPattern$/) {return __set_token($tex,$match,$TOKEN_WORD);}
      else {return __set_token($tex,$match,$TOKEN_SYMBOL);}
    } elsif ($ch eq '\\') {
      if ($tex->{'line'}=~s/^(\\[\{\}%])//) {return __set_token($tex,$1,$TOKEN_SYMBOL);}
      if ($tex->{'line'}=~s/^(\\([a-zA-Z@]+|[^a-zA-Z@[:^print:]]))//) {return __set_token($tex,$1,$TOKEN_MACRO);}
      return __get_chtoken($tex,$ch,$TOKEN_END);
    } elsif ($ch eq '$') {
      $tex->{'line'}=~s/^(\$\$?)//;
      return __set_token($tex,$1,$TOKEN_MATH);
    } elsif ($ch eq '{' || $ch eq '}') {
      return __get_chtoken($tex,$ch,$TOKEN_BRACE);
    } elsif ($ch eq '[' || $ch eq ']') {
      return __get_chtoken($tex,$ch,$TOKEN_BRACKET);
    } elsif ($ch=~/^['"`:.,()[]!+-*=\/^_@<>~#&]$/) {
      return __get_chtoken($tex,$ch,$TOKEN_SYMBOL);
    } elsif ($ch eq '%') {
      if ($tex->{'line'}=~s/^(\%+TC:\s*endignore\b[^\r\n]*)//i) {
        __set_token($tex,$1,$TOKEN_TC);
        return "%TC:endignore";
      }
      if ($tex->{'line'}=~s/^(\%+[tT][cC]:[^\r\n]*)//) {return __set_token($tex,$1,$TOKEN_TC);}
      if ($tex->{'line'}=~s/^(\%+[^\r\n]*)//) {return __set_token($tex,$1,$TOKEN_COMMENT);}
      return __get_chtoken($tex,$ch,$TOKEN_COMMENT);
    } else {
      return __get_chtoken($tex,$ch,$TOKEN_END);
    }
  }
  return undef;
}

# Set next token and its type
sub __set_token {
  my ($tex,$next,$type)=@_;
  $tex->{'next'}=$next;
  $tex->{'type'}=$type;
  return $next;
}

# Set character token and remove from line
sub __get_chtoken {
  my ($tex,$ch,$type)=@_;
  $tex->{'line'}=substr($tex->{'line'},1);
  $tex->{'next'}=$ch;
  $tex->{'type'}=$type;
  return $ch;
}



###### Count handling routines



## Make new count object
# The "count object" is a hash containing:
#  - title: the title of the count (name of file, section, ...)
#  - counts: a list of numbers (the counts: files, text words, ...)
#  - subcounts: list of count objects (used by the TeX object)
#  - warnings: list of warnings produced
# The elements are specified by the $CONT_* constants.
sub new_count {
  my ($title)=@_;
  my @cnt=(0) x $SIZE_CNT;
  my %count=('counts'=>\@cnt,'title'=>$title,'subcounts'=>[],'errorcount'=>0,'warnings'=>{});
  return \%count;
}

# Ensure the count array is of the right size
sub update_count_size {
  my $count=shift @_;
  my $counts=$count->{'counts'};
  while (scalar @{$counts}<$SIZE_CNT) {push @$counts,0;}
}

# Increment TeX count for a given count type
sub inc_count {
  my ($tex,$cnt,$value)=@_;
  my $count=$tex->{'subcount'};
  if (!defined $value) {$value=1;}
  ${$count->{'counts'}}[$cnt]+=$value;
}

# Get count value for a given count type
sub get_count {
  my ($count,$cnt)=@_;
  my $counts=$count->{'counts'};
  if ($cnt<scalar @{$counts}) {return ${$counts}[$cnt];}
  else {return 0;}
}

# Compute sum count for a count object
sub get_sum_count {
  my $count=shift @_;
  my $sum=0;
  for (my $i=scalar(@sumweights);$i-->1;) {
    if ($sumweights[$i]) {
      $sum+=get_count($count,$i)*$sumweights[$i];
    }
  }
  return $sum;
}

# Returns the number of subcounts
sub number_of_subcounts {
  my $count=shift @_;
  if (my $subcounts=$count->{'subcounts'}) {
    return scalar(@{$subcounts});
  } else {
    return 0;
  }
}

# Returns the number of warnings (not distinct)
sub number_of_warnings {
  my $count=shift @_;
  my $n=0;
  foreach my $m (values %{$count->{'warnings'}}) {$n+=$m;}
  return $n;
}

# Returns the number of distinct warnings
sub number_of_distinct_warnings {
  my $count=shift @_;
  return scalar keys %{$count->{'warnings'}};
}

# Is a null count? (counts 1-7 zero, title starts with _)
sub _count_is_null {
  my $count=shift @_;
  if (!$count->{'title'}=~/^_/) {return 0;}
  for (my $i=1;$i<$SIZE_CNT;$i++) {
    if (get_count($count,$i)>0) {return 0;}
  }
  if (scalar keys %{$count->{'warnings'}}) {return 0;}
  if ($count->{'errorcount'}) {return 0;}
  return 1;
}

# Add one count to another
sub _add_to_count {
  my ($a,$b)=@_;
  update_count_size($a);
  update_count_size($b);
  for (my $i=0;$i<$SIZE_CNT;$i++) {
   ${$a->{'counts'}}[$i]+=${$b->{'counts'}}[$i];
  }
  while (my ($text,$n)=each %{$a->{'warnings'}}) {
    $a->{'warnings'}->{$text}+=$n;
  }
  $a->{'errorcount'}+=$b->{'errorcount'};
}

# Add subcount to sum count and prepare new subcount
sub next_subcount {
  my ($tex,$title)=@_;
  add_to_total($tex->{'countsum'},$tex->{'subcount'});
  $tex->{'subcount'}=new_count($title);
  return $tex->{'countsum'};
}

# Add count to total as subcount
sub add_to_total {
  my ($total,$count)=@_;
  _add_to_count($total,$count);
  if (_count_is_null($count)) {return;}
  push @{$total->{'subcounts'}},$count;
  $count->{'parentcount'}=$total;
}


###### Result output routines


# Close the output (STDOUT), e.g. adding HTML tail
sub Close_Output {
  if ($htmlstyle==$HTML_FULL) {
    html_tail();
  }
  close STDOUT;
}

# Report if there were any errors occurring during parsing
sub Report_Errors {
  if (defined $outputtemplate) {return;}
  if ( !$briefsum && !$totalflag && $printlevel>=0 ) {
    foreach (keys %warnings) {formatprint($_,'p','nb');print "\n";}
  }
  if ($errorcount==0) {return;}
  if ($briefsum && $totalflag) {print ' ';}
  if ($htmlstyle) {
    print "<div class='error'><p>\n";
    print "There were $errorcount error(s) reported!\n";
    print "</p></div>\n";
  } elsif ($briefsum && $totalflag) {
    print "(errors:$errorcount)";
  } else {
    print "(errors:$errorcount)\n";
  }
}

# Print word frequencies (as text only)
sub print_word_freq {
  my ($word,$wd,$freq,%Freq,%Word,%Class);
  my %regs;
  foreach my $cg (@AlphabetScripts,@LogogramScripts) {
    $regs{$cg}=qr/\p{$cg}/;
  }
  my $sum=0;
  for $word (keys %WordFreq) {
    $wd=lc $word;
    $Freq{$wd}+=$WordFreq{$word};
    $sum+=$WordFreq{$word};
    $Word{$wd}=__lc_merge($word,$Word{$wd});
  }
  if ($htmlstyle) {print "<table class='stat'>\n<thead>\n";}
  __print_word_freq('Word','Freq','th');
  if ($htmlstyle) {print "</thead>\n";}
  if ($optionWordClassFreq>0) {
    for $word (keys %Freq) {$Class{__word_class($word,\%regs)}+=$Freq{$word};}
    __print_sorted_freqs('langstat',\%Class);
  }
  if ($htmlstyle) {print "<tbody class='sumstat'>\n";}
  __print_word_freq('All words',$sum,'td','sum');
  if ($htmlstyle) {print "</tbody>\n";}
  if ($optionWordFreq>0) {__print_sorted_freqs('wordstat',\%Freq,\%Word,$optionWordFreq);}
  if ($htmlstyle) {print "</table>\n";}
}

# Merge to words which have the same lower case
sub __lc_merge {
  my ($word,$w)=@_;
  if (defined $w) {
    for (my $i=length($word);$i-->0;) {
      if (substr($word,$i,1) ne substr($w,$i,1)) {
        substr($word,$i,1)=lc substr($word,$i,1);
      }
    }
  }
  return $word;
}

# Return the word class based on script groups it contains
sub __word_class {
  my ($wd,$regs)=@_;
  my @classes;
  $wd=~s/\\\w+(\{\})?/\\{}/g;
  foreach my $name (keys %{$regs}) {
    if ($wd=~$regs->{$name}) {push @classes,$name;}
  }
  my $cl=join('+',@classes);
  if ($cl) {}
  elsif ($wd=~/\\/) {$cl='(macro)';}
  else {$cl='(unidentified)';} 
  return $cl;
}

# Print table body containing word frequencies
sub __print_sorted_freqs {
  my ($class,$Freq,$Word,$min)=@_;
  my $sum=0;
  my ($word,$wd,$freq);
  if (!defined $min) {$min=0;}
  if ($htmlstyle) {print "<tbody class='$class'>\n";}
  else {print "---\n";}
  for $wd (sort {$Freq->{$b} <=> $Freq->{$a}} keys %{$Freq}) {
    if (defined $Word) {$word=$Word->{$wd};} else {$word=$wd;}
    $freq=$Freq->{$wd};
    if ($freq>=$min) {
      $sum+=$freq;
      __print_word_freq($word,$freq);
    }
  }
  if ($min>0) {__print_word_freq('Sum of subset',$sum,'td','sum');}
  if ($htmlstyle) {print "</tbody>\n";}
}

# Print one word freq line
sub __print_word_freq {
  my ($word,$freq,$tag,$class)=@_;
  if (!defined $tag) {$tag='td';}
  if (defined $class) {$class=" class='$class'";} else {$class='';}
  if ($htmlstyle) {
    print "<tr$class><$tag>$word</$tag><$tag>$freq</$tag></tr>\n";
  } else {
    print $word,': ',$freq,"\n";
  }
}

# Print macro usage statistics
sub print_macro_stat {
  if ($htmlstyle) {print "<table class='stat'>\n<thead>\n";}
  __print_word_freq('Macro/envir','Freq','th');
  if ($htmlstyle) {print "</thead>\n";}
  if ($htmlstyle) {print "<tbody class='macrostat'>\n";}
  foreach my $name (sort keys %MacroUsage) {
    my $freq=$MacroUsage{$name};
    $name=text_to_printable($name);
    $name=text_to_print($name);
    if ($htmlstyle) {
      print "<tr><td>$name</td><td>$freq</td></tr>\n";
    } else {
      print $name,': ',$freq,"\n";
    }
  }
  if ($htmlstyle) {print "</tbody>\n";}
  if ($htmlstyle) {print "</table>\n";}
}



###### Printing routines


# Print text using given style/colour
sub print_with_style {
  my ($text,$style,$colour)=@_;
  if ($style eq $NOSTYLE) {
    print text_to_print($text);
  } elsif ($htmlstyle) {
    print "<span class='$style'>",text_to_print($text),'</span>';
  } else {
    ansiprint(text_to_print($text),$colour);
    if ($style=~/$separatorstyleregex/) {print $separator;}
  }
}

# Prepare text string for print: convert special characters
sub text_to_print {
  my $text=join('',@_);
  if ($htmlstyle) {
    $text=~s/&/&amp;/g;
    $text=~s/</&lt;/g;
    $text=~s/>/&gt;/g;
    $text=~s/[ \t]{2}/\&nbsp; /g;
  } elsif ($texcodeoutput) {
    $text=~s/\\/\\textbackslash¤/g;
    $text=~s/([%\{\}])/\\$1/g;
    $text=~s/¤/{}/g;
  }
  return $text;
}

# Return &#xxx; code for character ;
sub convert_to_charcode {
  my $ch=shift @_;
  return '&#'.ord($ch).';';
}

# Convert special characters to charcodes to make it printable ;
sub text_to_printable {
  my $text=shift @_;
  $text=~s/([^[:print:]])/convert_to_charcode($1)/gse;
  return $text;
}

# Print text, using appropriate tags for HTML
sub formatprint {
  my ($text,$tag,$class)=@_;
  my $break=($text=~s/(\r\n?|\n)$//);
  if ($htmlstyle && defined $tag) {
    print '<'.$tag;
    if ($class) {print " class='$class'";}
    print '>'.text_to_print($text)."</$tag>";
  } else {
    print text_to_print($text);
  }
  if ($break) {print "\n";}
}

# Add a line break to output
sub linebreak {
  if ($htmlstyle) {print "<br>\n";} else {print "\n";}
}


###### Routines for printing count summary


# Print count summary for a count object
sub print_count {
  my ($count,$class,$title)=@_;
  line_return(0);
  if ($htmlstyle) {print "<div class='".($class||'count')."'>\n";}
  if (defined $title) {formatprint($title."\n",'h2');}
  if ($outputtemplate) {
    _print_count_template($count,$outputtemplate);
  } elsif ($briefsum && @sumweights) {
    _print_sum_count($count);
  } elsif ($briefsum) {
    if ($htmlstyle) {print "<p class='count'>";}
    _print_count_brief($count);
    if ($htmlstyle) {print "</p>\n";}
  } else {
    _print_count_details($count);
  }
  if ($htmlstyle) {print "</div>\n";}  
}

# Return count,header,... list filling in header if missing
sub __count_and_header {
  my $count=shift @_;
  my $header=__count_header($count);
  return $count,$header,@_;
}

# Return count title or '' if missing
sub __count_header {
  my $count=shift @_;
  return $count->{'title'}||'';
}

# Print total count (sum) for a given count object
sub _print_sum_count {
  my ($count,$header)=__count_and_header(@_);
  if ($htmlstyle) {print "<p class='count'>".text_to_print($header).": ";}
  print get_sum_count($count);
  if ($htmlstyle) {print "</p>\n";}
  else {print ": ".text_to_print($header);}
  print "\n";
}

# Print brief summary of count object
sub _print_count_brief {
  my ($count,$header,$tag1,$tag2)=__count_and_header(@_);
  my @cnt=@{$count->{'counts'}};
  if ($htmlstyle && $tag1) {print '<',$tag1,'>';}
  print $cnt[$CNT_WORDS_TEXT],'+',$cnt[$CNT_WORDS_HEADER],'+',$cnt[$CNT_WORDS_OTHER];
  for (my $i=$SIZE_CNT_DEFAULT;$i<$SIZE_CNT;$i++) {
    if ($cnt[$i]) {print '+',$cnt[$i],$countkey[$i];}
  }
  print ' (',$cnt[$CNT_COUNT_HEADER],'/',$cnt[$CNT_COUNT_FLOAT],
      '/',$cnt[$CNT_COUNT_INLINEMATH],'/',$cnt[$CNT_COUNT_DISPLAYMATH],')';
  if ($htmlstyle && $tag2) {
    print '</',$tag1,'><',$tag2,'>';
    $tag1=$tag2;
  } else {print ' ';}
  print text_to_print($header);
  if ($htmlstyle && $tag1) {print '</',$tag1,'>';}
  if ($finalLineBreak) {print "\n";}
}

# Print detailed summary of count object
sub _print_count_details {
  my ($count,$header)=__count_and_header(@_);
  if ($htmlstyle) {print "<ul class='count'>\n";}
  if ($header) {formatprint($header."\n",'li','header');}
  if (my $tex=$count->{'TeXcode'}) {
    if (!defined $encoding) {formatprint('Encoding: '.$tex->{'encoding'}."\n",'li');}
  }
  if (@sumweights) {formatprint('Sum count: '.get_sum_count($count)."\n",'li');}
  for (my $i=1;$i<$SIZE_CNT;$i++) {
    formatprint($countdesc[$i].': '.get_count($count,$i)."\n",'li');
  }
  if (get_count($count,$CNT_FILE)>1) {
    formatprint($countdesc[$CNT_FILE].': '.get_count($count,$CNT_FILE)."\n",'li');
  }
  my $subcounts=$count->{'subcounts'};
  if ($showsubcounts && defined $subcounts && scalar(@{$subcounts})>=$showsubcounts) {
    formatprint("Subcounts:\n",'li');
    if ($htmlstyle) {print "<span class='subcount'>\n";}
    formatprint("  text+headers+captions (#headers/#floats/#inlines/#displayed)\n",'li','fielddesc');
    foreach my $subcount (@{$subcounts}) {
      print '  ';
      _print_count_brief($subcount,'li');
    }
    if ($htmlstyle) {print "</span>\n";}
  }
  if ($htmlstyle) {print "</ul>\n";} else {print "\n";}
}

# Print summary of count object using template
sub _print_count_template {
  my ($count,$header,$template)=__count_and_header(@_);
  $template=~s/\\n/\n/g;
  if ($htmlstyle) {$template=~s/\n/<br>/g;}
  my ($subtemplate,$posttemplate);
  while ($template=~/^(.*)\{SUB\?((.*?)\|)?(.*?)(\|(.*?))?\?SUB\}(.*)$/is) {
    __print_count_using_template($count,$1); # $1 ~ ${^PREMATCH}
    if (number_of_subcounts($count)>1) {
      if (defined $3) {print $3;}
      __print_subcounts_using_template($count,$4);
      if (defined $6) {print $6;}
    }
    $template=$7; # $7 ~ ${^POSTMATCH}
  }
  __print_count_using_template($count,$template);
}

# Return string with counts based on template
sub count_in_template {
  my ($count,$template)=@_;
  while (my ($key,$cnt)=each %key2cnt) {
    $template=__process_template($template,$key,get_count($count,$cnt));
  }
  $template=~s/\{VER\}/\Q$versionnumber\E/gi;
  $template=__process_template($template,'WARN|WARNING|WARNINGS',number_of_distinct_warnings($count));
  $template=__process_template($template,'NWARN|NWARNING|NWARNINGS',number_of_warnings($count));
  $template=__process_template($template,'ERR|ERROR|ERRORS',$count->{'errorcount'});
  $template=__process_template($template,'SUM',get_sum_count($count));
  $template=__process_template($template,'TITLE',$count->{'title'}||'');
  $template=__process_template($template,'SUB',number_of_subcounts($count));
  $template=~s/\a//gis;
  return $template;
}

# Print counts using template
sub __print_count_using_template {
  print count_in_template(@_);
}

# Print subcounts using template
sub __print_subcounts_using_template {
  my ($count,$template)=@_;
  my $subcounts=$count->{'subcounts'};
  if ($template && defined $subcounts && scalar(@{$subcounts})>=$showsubcounts) {
    foreach my $subcount (@{$subcounts}) {
      __print_count_using_template($subcount,$template);
    }
  }
}

# Process template for specific label
sub __process_template {
  my ($template,$label,$value)=@_;
  if ($value) {
    $template=~s/\{($label)\?(.*?)(\|(.*?))?\?(\1)\}/$2/gis;
  } else {
    $template=~s/\{($label)\?(.*?)\|(.*?)\?(\1)\}/$3/gis;
    $template=~s/\{($label)\?(.*?)\?(\1)\}//gis;
  }
  if (!defined $value) {$value='';}
  $template=~s/\{($label)\}/$value\a/gis;
  return $template;
}



###### Routines for printing parsing details


# Print next token
sub flush_next {
  my ($tex,$style)=@_;
  my $ret=undef;
  if (defined $style) {set_style($tex,$style);}
  if (defined $tex->{'next'}) {
    $ret=print_style($tex->{'next'},$tex->{'style'},$tex->{'printstate'});
  }
  $tex->{'printstate'}=undef;
  $tex->{'style'}=$STYLE_BLOCK;
  return $ret;
}

# Print next token and gobble following spaces (incl. line break and comments)
sub flush_next_gobble_space {
  my ($tex,$style,$state)=@_;
  my $ret=flush_next($tex,$style);
  if (!defined $ret) {$ret=0;}
  if (!defined $state) {$state=$STATE_IGNORE;}
  my $prt=($printlevel>0);
  while (1) {
    if ($tex->{'line'}=~s/^([ \t\f]*)(\r\n|\r|\n)([ \t\f]*)//) {
      if (!$prt) {
      } elsif ($printlevel>1 || $ret) {
        print $1;
        line_return(-1,$tex);
        my $space=$3;
        if ($htmlstyle) {$space=~s/  /\&nbsp;/g;}
        print $space;
        $ret=0;
      } else {
        line_return(0,$tex);
      }
    } elsif ($tex->{'line'}=~s/^([ \t\f]+)//) {
      if ($prt) {print $1;}
    }
    if ($tex->{'line'}=~/^\%TC:/i) {return;}
    if ($tex->{'line'}=~s/^(\%+[^\r\n]*)//) {
      print_style($1,'comment');
      $ret=1;
    } else {return;}
  }
}

# Set presentation style
sub set_style {
  my ($tex,$style)=@_;
  if (!(defined $tex->{'style'} && $tex->{'style'} eq $STYLE_BLOCK)) {$tex->{'style'}=$style;}
}

# Print text using the given style, and log state if given
sub print_style {
  my ($text,$style,$state)=@_;
  (($printlevel>=0) && (defined $text) && (defined $style)) || return 0;
  my $colour;
  ($colour=$STYLE{$style}) || return;
  if (defined $colour && $colour ne '-') {
    print_with_style($text,$style,$colour);
    if (defined $state) {print_style($state,'state');}
    if ($style ne 'cumsum') {$blankline=-1;}
    return 1;
  } else {
    return 0;
  }
}

# Conditional line return
sub line_return {
  my ($blank,$tex)=@_;
  if ($blank<0 && $printlevel<2) {$blank=1;}
  if ($blank<0 || $blank>$blankline) {
    if ((defined $tex) && @sumweights) {
      my $num=get_sum_count($tex->{'subcount'});
      print_style(" [$num]",'cumsum');
    }
    linebreak();
    $blankline++;
  }
}


###### Print help on style/colour codes


# Print output style codes if conditions are met
sub conditional_print_style_list {
  if ($showcodes) {_print_style_list();}
  return $showcodes;
}

# Print help on output styles
sub _print_style_list {
  if ($printlevel<=0) {return;}
  if ($htmlstyle) {print '<div class="stylehelp"><p>';}
  formatprint('Format/colour codes of verbose output:','h2');
  print "\n\n";
  foreach my $style (@STYLE_LIST) {
    my $desc=$STYLE_DESC{$style};
    if ($desc=~/^(.*):\s+(.*)$/) {
      _help_style_line($1,$style,$2); # $1~${^PREMATCH}, $2~${^POSTMATCH}
    } else {
      _help_style_line($desc,$style);
    }
  }
  if ($htmlstyle) {print '</p></div>';}
  print "\n\n";
}

# Print one line of help
sub _help_style_line {
  my ($text,$style,$comment)=@_;
  if (!defined $comment) {$comment='';}
  if ($htmlstyle) {$comment='&nbsp;&nbsp;....&nbsp;&nbsp;'.text_to_print($comment);}
  else {$comment=' .... '.$comment;}
  if (print_style($text,$style)) {
    print $comment;
    linebreak();
  }
}


###### Help routines


# Print TeXcount version
sub print_version {
  wprintstringdata('Version');
}

# Print TeXcount licence text
sub print_license {
  wprintstringdata('License');
}

# Print short TeXcount help
sub print_help {
  wprintstringdata('ShortHelp');
}

# Print main TeXcount help
sub print_help_man {
  wprintstringdata('HelpTitle');
  wprintstringdata('HelpText');
  wprintstringdata('Reference');
}

# Print help on TC instructions
sub print_help_tcinst {
  wprintstringdata('TCinstructions');
}

# Print TeXcount options list
sub print_help_options {
  wprintstringdata('OptionsHead');
  wprintstringdata('Options',StringDatum('OptionsFormat'));
}

# Print TeXcount options containing substring
sub print_help_options_subset {
  my $pattern=shift @_;
  my $data=StringData('Options');
  if (!defined $data) {
    error($Main,'No StringData Options.','BUG');
    return;
  }
  my @options;
  foreach (@$data) {
    if (/^\s*([^\s]+\s)*[^\s]*\Q$pattern\E/) {push @options,$_;}
  }
  if (scalar(@options)==0) {print "No options contained $pattern.\n";}
  else {
    print "Options containing \"$pattern\":\n\n";
    wprintlines(StringDatum('OptionsFormat'),@options);
  }
}

# Print help on specific macro or environment
sub print_help_on_rule {
  my $arg=shift @_;
  my $def;
  my %rules=(
    '\documentclass' => 'Initiates LaTeX document preamble.',
    '\begin' => 'Treatmend depends on environment handling rules.',
    '\def' => 'Excluded from count.',
    '\verb' => 'Strong exclude for enclosed region.',
    '$'    => 'Opens or closes inlined equation',
    '$$'   => 'Opens or closes displayed equation.',
    '\('   => 'Opens inlined equation.',
    '\)'   => 'Closes inlined equation initiated by \(.',
    '\['   => 'Opens displayed equation.',
    '\]'   => 'Closes displayed equation initiated by \[.');
  if (!defined $arg || $arg=~/^\s*$/) {
    print "\nSpecify macro or environment name after the -h= option.\n";
    return;
  }
  if ($arg=~/^[\w\-\%]+:/) {
    remove_all_rules();
    %rules=();
    while ($arg=~s/^([\w\-\%]+)://) {include_package($1);}
  }
  if ($def=$rules{$arg}) {
    print "\nSpecial rule (hard coded) for $arg\n";
    print $def."\n";
  } elsif ($arg=~/^\\/) {
    my $hasrule=0;
    print "\nRule(s) for macro $arg\n";
    if ($def=$TeXmacrocount{$arg}) {
      $hasrule=1;
    }
    if ($def=$TeXfileinclude{$arg}) {
      $hasrule=1;
      print "Takes file name as parameter which is included in document.\n";
    }
    if ($def=$TeXmacro{$arg}) {
      $hasrule=1;
      _print_rule_macro($arg,$def);
    }
    if ($def=$TeXfloatinc{$arg}) {
      $hasrule=1;
      print "\nIncluded inside floats:\n";
      _print_rule_macro($arg,$def);
    }
    if (!$hasrule) {
      print "\nNo macro rule defined for $arg.\nParameters treated as surrounding text.\n";
    }
  } else {
    if ($def=$TeXenvir{$arg}) {
      print "\nRule for environment $arg\n";
      _print_rule_macrocount($PREFIX_ENVIR.$arg);
      _print_rule_envir($arg,$def);
    } else {
      print "\nNo default environment rule defined for $arg.\nContent handled as surrounding text.\n";
    }
  }
}

# Print macro handling rule
sub _print_rule_macro {
  my ($arg,$def)=@_;
  if (!defined $def) {
    print "Takes no parameter(s).\n";
  } elsif (ref($def) eq 'ARRAY') {
    my $optionflag=0;
    print "Takes has the following parameters and parameter rules:\n";
    foreach my $state (@{$def}) {
      if ($state==$_STATE_OPTION) {$optionflag=1;}
      elsif ($state==$_STATE_NOOPTION) {print " - no [] options permitted here\n";}
      elsif ($state==$_STATE_AUTOOPTION) {}
      elsif ($optionflag) {
        $optionflag=0;
        print " + optional [] containing $state2desc{$state}\n";
      } else {
        print " + $state2desc{$state}\n";
      }
    }
  } else {
    print "Takes $def parameter(s): content ignored, i.e. not included in counts.\n";
  }
}

# Print environment handling rule
sub _print_rule_envir {
  my ($arg,$def)=@_;
  print "Contents parsed as $state2desc{$def}\n";
  if ($def=$TeXmacro{$PREFIX_ENVIR.$arg}) {
    _print_rule_macro($arg,$def);
  } else {
    print "Takes no parameter(s).\n";
  }
}

# Print macrocount rule, return rule
sub _print_rule_macrocount {
  my $arg=shift @_;
  my $def=$TeXmacrocount{$arg};
  if (!defined $def) {return undef;}
  if (ref($def) eq 'ARRAY') {
    my @wd=@$def;
    foreach (@wd) {$_=$countdesc[$_];}
    print 'Increments the following counters: ',join('; ',@wd),".\n";
  } else {
    print "Counted as $def word(s).\n";
  }
}

# Print style or style category summary
sub print_help_on_styles {
  my $style=shift @_;
  if (defined $style) {
    if (my $def=$STYLES{$style}) {
      _print_help_on_style_category($style);
      print wrap('','    ',"$style = ".join(', ',grep(/^\w+$/,sort keys %$def))),".\n";
    } elsif ($def=$STYLE_DESC{$style}) {
      print $style,' = ',$def,"\n";
    } else {
      print "Unknown style or style category: $style.\n";
    }
  } else {
    print wrap('','   ','Styles: '.join(', ',@STYLE_LIST)),".\n\n";
    print wrap('','   ','Style categories: '.join(', ',sort grep(/^\w+$/,keys %STYLES))),".\n\n";
    print "Use -help-style={style} to get help on particular style or style category.\n";
  }
}

# Print help on a particular style category (optional prefix and indentation)
sub _print_help_on_style_category {
  my ($cat,$prefix,$indent)=@_;
  if (!defined $prefix) {$prefix='';}
  if (!defined $indent) {$indent='   ';}
}


###### HTML routines


# Print HTML header
sub html_head {
  if (defined $HTMLfile) {
    if (open(FH,$HTMLfile)) {
      my $text=join('',<FH>);
      close FH;
      if ( $text=~/^(.*)<!--+\s*texcount\s*--+>(.*)$/is
        || $text=~/^(.*)\$\{texcount\}(.*)$/is
        || $text=~/^(.*)(<\/body.*)$/is
        ) {
        $htmlopen=$1;
        $htmlclose=$2;
      } else {
        error($Main,"Invalid HTML template format.");
      }
    } else {
      error($Main,"HTML template file not found: $HTMLfile");
    }
  }
  if (defined $htmlopen) {
    $htmlopen=~s/\$\{encoding\}/\Q$outputEncoding\E/g;
    $htmlopen=~s/\$\{version\}/@{[_html_version()]}/g;
    print $htmlopen;
    $htmlopen=undef;
  } else {
    print "<html>\n<head>\n";
    print "<meta http-equiv='content-type' content='text/html; charset=$outputEncoding'>\n";
    _print_html_style();
    foreach (@htmlhead) {print $_,"\n";}
    print "</head>\n\n<body>\n";
    print "\n<h1>LaTeX word count";
    if ($showVersion>0) {print ' (version ',_html_version(),')'}
    print "</h1>\n";
  }
}

# Print HTML tail
sub html_tail {
  if (defined $htmlclose) {
    print $htmlclose;
    $htmlclose=undef;
  } else {
    print "</body>\n\n</html>\n";
  }
}

# Return version number using HTML
sub _html_version {
  my $htmlver=$versionnumber;
  $htmlver=~s/\b(alpha|beta)\b/&$1;/g;
  return $htmlver;
}

# Print HTML STYLE element
sub _print_html_style {
if (defined $CSShref) {
  print "<link rel='stylesheet' href='$CSShref' type='text/css'>\n";
  return;
}
if (defined $CSSfile) {
  if (open(FH,$CSSfile)) {
    print "<style>\n<!---\n",<FH>,"-->\n</style>\n";
    close(FH);
    return;
  } else {
    error($Main,"CSS file not found: $CSSfile");
  }
}
print <<END
<style>
<!--
body {width:auto;padding:5;margin:5;}
.error {font-weight:bold;color:#f00;font-style:italic; border: solid 1px red;}
.word,.hword,.oword,.altwd {border-left: 1px solid #CDF; border-bottom: 1px solid #CDF;}
.word {color: #009}
.hword {color: #009; font-weight: 700;}
.oword {color: #009; font-style: italic;}
.altwd {color: #00c; font-style: oblique;}
.cmd {color: #c00;}
.exclcmd {color: #f99;}
.option {color: #cc0;}
.optparm {color: #c90;}
.envir, .document {color: #900; font-weight:bold;}
.math {color: #6c0;}
.mathgroup {color: #090;}
.exclmath {color: #9f6;}
.mathcmd {color: #6c0;}
.ignore {color: #999;}
.exclenv {color:#c66;}
.special {color:#c66; font-weight: bold;}
.specarg {color:#c66; font-weight: bold; font-style: italic;}
.tc {color: #999; font-weight:bold;}
.comment {color: #999; font-style: italic;}
.state {color: #990; font-size: 70%;}
.cumsum {color: #999; font-size: 80%;}
.fileinc {color: #696; font-weight:bold;}
.warning {color: #c00; font-weight: 700;}
.note {color: #c90; font-weight: bold;}

div.filegroup, div.parse, div.stylehelp, div.count, div.sumcount, div.error {
   border: solid 1px #999; margin: 4pt 0pt; padding: 4pt;
}
div.stylehelp {font-size: 80%; background: #fffff0; margin-bottom: 16pt;}
div.filegroup {background: #dfd; margin-bottom: 16pt;}
div.count {background: #ffe;}
div.sumcount {background: #cec;}
div.error {background: #fcc;}
.parse {font-size: 80%; background: #f8fff8; border-bottom:none;}

ul.count {list-style-type: none; margin: 4pt 0pt; padding: 0pt;}
.count li.header {font-weight: bold; font-style: italic;}
.subcount li.header {font-weight: normal; font-style: italic;}
.subcount li {margin-left: 16pt; font-size: 80%;}
.fielddesc {font-style: italic;}
.nb {color: #900;}

table.stat {border:2px solid #339; margin:0 0 8pt 0; background:#666; border-collapse:collapse;}
table.stat tr {border:1px solid #CCC;}
table.stat th, table.stat td {padding:1pt 4pt;}
table.stat col {padding:4pt;}
table.stat thead {background: #CCF;}
table.stat tbody {border:1px solid #333;}
table.stat tbody.sumstat {background:#FFC;}
table.stat tbody.langstat {background:#FEE;}
table.stat tbody.wordstat {background:#EEF;}
table.stat tbody.macrostat {background:#EFE;}
table.stat .sum {font-weight:bold; font-style:italic;}
-->
</style>
END
}


###### Read text data



# Return the STRINGDATA hash (lazy instantiation)
sub STRINGDATA {
  if (!defined $STRINGDATA) {
    my @DATA=<DATA>;
    foreach (@DATA) {
      $_=~s/\$\{(\w+)\}/__apply_globaldata($1)/ge;
    }
    $STRINGDATA=splitlines(':{3,}\s*(\w+)?',\@DATA);
  }
  return $STRINGDATA;
}

# Return value from STRINGDATA hash
sub StringData {
  my $name=shift @_;
  return STRINGDATA()->{$name};
}

# First line of StringData
sub StringDatum {
  return pop @{StringData(@_)};
}

# Insert value from GLOBALDATA
sub __apply_globaldata {
  my $name=shift @_;
  if (my $value=$GLOBALDATA{$name}) {
    return $value;
  }
  return '[['.$name.']]';
}

# Print value from STRINGDATA using wprintlines
sub wprintstringdata {
  my $name=shift @_;
  my $data=StringData($name);
  if (!defined $data) {
    error($Main,"No StringData $name.",'BUG');
    return;
  }
  wprintlines(@_,@$data);  
}

# Divide array of lines by identifying headers
sub splitlines {
  my ($pattern,$lines)=@_;
  if (!defined $lines) {return;}
  my $id=undef;
  my %hash;
  foreach my $line (@$lines) {
    if ($line=~/^$pattern$/) {
      $id=$1;
      if (defined $id) {
        $hash{$id}=[];
        if (defined $2) {push @{$hash{$id}},$2;}
      }
    } elsif (defined $id) {
      chomp $line;
      push @{$hash{$id}},$line;
    }
  }
  return \%hash;
}

# Print string with word wrapping and indentation using
# wprintlines.
sub wprint {
  my $text=shift @_;
  my @lines=split(/\n/,$text);
  wprintlines(@lines);
}

# Print with word wrapping and indentation. A line with
# @  -    :
# sets two column tabs. A tab or multiple spaces is taken
# to indicate indentation. If the first column value is
# only a single '|', this is just an indication to skip
# one tab.
sub wprintlines {
  my @lines=@_;
  my $ind1=2;
  my $ind2=6;
  my $i;
  foreach my $line (@lines) {
    if ($line=~s/^@/ /) {
      $ind1=index($line,'-');
      $ind2=index($line,':');
      if ($ind1<1) {$ind1=$ind2;}
      next;
    }
    my $firstindent=0;
    if ($line=~s/^(\t|\s{2,})(\S)/$2/) {$firstindent=$ind1;}
    my $indent=$firstindent;
    if ($line=~/^(.*?\S)(\t|\s{2,})(.*)$/) {
      $indent=$ind2;
      if ($1 eq '|') {$line=' ';}
      else {$line=$1.'   ';}
      $i=$indent-$firstindent-length($line);
      if ($i>0) {$line.=' ' x $i;}
      $line.=$3; # $3~${^POSTMATCH}
    }
    print wrap(' ' x $firstindent,' ' x $indent,$line)."\n";
  }
}


########################################
##### TEXT DATA

__DATA__


::::::::::::::::::::::::::::::::::::::::
:::::::::: Version
TeXcount version ${versionnumber}, ${versiondate}.

:::::::::: Reference
Go to the TeXcount web page
    ${website}
for more help and information about the script: news, updates, help, usage tips, known issues and short-comings, or to access the script as a web application. Feedback such as problems or errors can be reported to einarro@ifi.uio.no.

The TeXcount script is copyright of ${maintainer} (${copyrightyears}) and published under the LaTeX Project Public Licence.

:::::::::: License
TeXcount version ${versionnumber}
  
Copyright ${copyrightyears} ${maintainer}

The TeXcount script is published under the LaTeX Project Public License (LPPL)
    http://www.latex-project.org/lppl.txt
which grants you, the user, the right to use, modify and distribute the script. However, if the script is modified, you must change its name or use other technical means to avoid confusion.

The script has LPPL status "maintained" with ${maintainer} being the current maintainer.

::::::::::::::::::::::::::::::::::::::::
:::::::::: ShortHelp
Syntax: texcount.pl [options] files

Use option -help (or just -h) to get help. For more detailed help, the following alternatives exist:
@ -                      :
  -help-man, -man          Manual with more extensive help
  -help-rule={macro/envir}    Macro/environment handling rule (backslash needed with macros)       
  -help-options (-hopt)    Get list of command line options
  -help-options={substring}    Help on options containing substring
  -help-styles             List styles which determine how different elements (words, macros, etc) are presented in the verbose output
  -help-style={style}      Describe a particular style or style category
  -help-tc, -help-instructions    Help on %TC:instruction for inserting TeXcount instructions into the TeX code.

Help, documentation, FAQ and updates are available from the TeXcount web page:
    ${website}
or through running
    texdoc texcount
on the command line.

::::::::::::::::::::::::::::::::::::::::
:::::::::: HelpTitle
***************************************************************
*   TeXcount version ${versionnumber}, ${versiondate}
*

Count words in TeX and LaTeX files, ignoring macros, tables, formulae, etc.

::::::::::::::::::::::::::::::::::::::::
:::::::::: HelpText
The script counts words as either words in the text, words in headers/titles or words in floats (figure/table captions). Macro options (i.e. \\macro[...]) are ignored; macro parameters (i.e. \\macro{...}) are counted or ignored depending on the macro, but by default counted. Begin-end groups are by default ignored and treated as 'floats', though some (e.g. center) are counted.

Mathematical formulae are not counted as words, but are instead counted separately with separate counts for inlined formulae and displayed formulae. Similarly, the number of headers and the number of 'floats' are counted. Note that 'float' is used here to describe anything defined in a begin-end group unless explicitly recognized as text or mathematics.

The verbose options (-v1, -v2, -v3, showstate) produces output indicating how the text has been interpreted. Check this to ensure that words in the text has been interpreted as such, whereas mathematical formulae and text/non-text in begin-end groups have been correctly interpreted.

Summary, as well as the verbose output, may be produced as text (default) or as HTML code using the -html option. The HTML may then be sent to file which may be viewed with you favourite browser.

Under UNIX, unless -nocol (or -nc) has been specified, the output will be colour coded using ANSI colour codes. Counted text is coloured blue with headers are in bold and in HTML output caption text is italicised. Use 'less -r' instead of just 'less' to view output: the '-r' option makes less treat text formating codes properly. Windows does not support ANSI colour codes, and so this is turned off by default.

::::::::::::::::::::::::::::::::::::::::
:::::::::: OptionsHead

Syntax: texcount.pl [options] files

Options:

:::::::::: OptionsFormat
@ -          :
:::::::::: Options
  -relaxed      Uses relaxed rules for word and option handling: i.e. allows more general cases to be counted as either words or macros.
  -restricted    Restricts the rules for word and option handling.
  -v            Verbose (same as -v3).
  -v0           Do not present parsing details.
  -v1           Verbose: print parsed words, mark formulae.
  -v2           More verbose: also print ignored text.
  -v3           Even more verbose: include comments and options.
  -v4           Same as -v3 -showstate.
  -v=, v0=, ..., -v4=    Set verbosity by adding/removing particular types of token (styles) to include in the verbose output. Use -help-style to get details of which tokens are included in each style, and of classes of tokens (style categories).
  -showstate    Show internal states (with verbose).
  -brief        Only prints a brief, one line summary of counts.
  -q, -quiet    Quiet mode, no error messages. Use is discouraged!
  -strict       Strict mode, warns against begin-end groups for which rule are not defined.
  -sum, -sum=   Make sum of all word and equation counts. May also use -sum=#[,#] with up to 7 numbers to indicate how each of the counts (text words, header words, caption words, #headers, #floats, #inlined formulae, #displayed formulae) are summed. The default sum (if only -sum is used) is the same as -sum=1,1,1,0,0,1,1.
  -nosum        Do not compute sum.
  -sub, -sub=   Generate subcounts. Option values are none, part, chapter, section or subsection. Default (-sub) is set to subsection, whereas unset is none. (Alternative option name is -subcount.)
  -nosub        Do not generate subcounts.
  -col          Use ANSI colours in text output.
  -nc, -nocol   No colours (colours require ANSI).
  -nosep, -noseparator   No separating character/string added after each word (default).
  -sep=, -separator=   Separating character or string to be added after each word.
  -html         Output in HTML format.
  -htmlcore     Only HTML body contents.
  -htmlfile=    HTML template file to use with the -html option. Use <!-- TeXcode --> to indicate where the output from TeXcount should be inserted.
  -tex          Encode TeX special characters for output into TeX code
  -cssfile=     CSS file to include instead of default styles.
  -css=         CSS href to include instead of default styles. Can use -css=file:{filename} instead of -cssfile={filename}.
  -opt=, -optionfile=   Read options/parameters from file.
  -             Read LaTeX code from STDIN.
  -inc          Parse included TeX files (as separate file).
  -merge        Merge included TeX files into code (in place).
  -noinc        Do not include included tex files (default).
  -incbib       Include bibliography in count, include bbl file if needed.
  -nobib        Do not include bibliography in count (default).
  -incpackage=    Include rules for the given package.
  -total        Do not give sums per file, only total sum.
  -1            Same as -brief and -total. Ensures there is only one line of output. If used in conjunction with -sum, the output will only be the total number. (NB: Character is the number one, not the letter L.)
  -template=    Speficy an output template. Use {1},...,{7}, {SUM} and {TITLE} to include values, {1?...?1} etc. to conditionally include sections, {1?....|...?1} etc. to specify an alternative text if zero. To include subcounts, use {SUB?...?SUB} where ... is replaced with the template to use per subcount. Line shift may be specified using \\n.
  -dir, -dir=   Specify the working directory using -dir=path. Remember that the path must end with \\ or /. If only -dir is used, the directory of the provided file is used and paths (e.g. included files) are assumed to be absolute or relative to this. The default at startup is -dir=. which means that the directory from which TeXcount is run is the working directory with all paths absolute or relative to this.
  -auxdir, -auxdir=   Specify directory for auxilary files, e.g. the bibliograph (.bbl) file. If only -auxdir is used, the working directory (as determined by -dir or -dir=) is assumed. If -auxdir= is used with -dir=, it sets the path to the auxilary directiry. If -auxdir= is used with -dir, the working directory is determined from the location of the provided file, and the path to the auxilary directory is assumed to be absolute or relative to this.
  -enc=, -encoding=    Specify encoding (default is to guess the encoding).
  -utf8, -unicode    Selects Unicode (UTF-8) for input and output. This is automatic with -chinese, and is required to handle e.g. Korean text. Note that the TeX file must be save in UTF-8 format (not e.g. GB2312 or Big5), or the result will be unpredictable.
  -alpha=, -alphabets=    List of Unicode character groups (or digit, alphabetic) permitted as letters. Names are separated by ',' or '+'. If list starts with '+', the alphabets will be added to those already included. The default is Digit+alphabetic.
  -logo=, -logograms=    List of Unicode character groups interpreted as whole word characters, e.g. Han for Chinese characters. Names are separated by ',' or '+'. If list starts with '+', the alphabets will be added to those already included. By default, this is set to include Ideographic, Katakana, Hiragana, Thai and Lao.
  -ch, -chinese, -zhongwen    Turns on support for Chinese characters. TeXcount will then count each Chinese character as a word.
  -jp, -japanese    Turns on support for Japanese characters. TeXcount will count each Japanese character (kanji, hiragana, and katakana) as one word, i.e. not do any form of word segmentation.
  -kr, -korean    Turns on support for Korean. This will count hangul and han characters, i.e. with no word separation. NB: Experimental!
  -kr-words, -korean-words    Turns on support for Korean words, i.e. hangul words separated by characters. Han characters are still counted as characters. NB: Experimental!
  -ch-only, ..., -korean-words-only    As options -chinese, ..., -korean-words, but also excludes letter-based words or trims down the character set to the minimum.
  -char, -character, -letters    Counts letters/characters instead of words. Note that spaces and punctuation is not counted.
  -char-only, ..., -letters-only    Like -letters, but counts alphabetic letters only.
  -countall, -count-all    The default setting in which all characters are included as either alphabets og logograms.
  -freq, -freq=    Produce individual word frequency table. Optionally give minimal number of occurences to be listed.
  -stat         Produce statistics on language/script usage.
  -macrostat, -macrofreq    Print macro usage statistics.
  -codes        Display output style code overview and explanation. This is on by default.
  -nocodes      Do not display output style code overview.
  -out=         Write output to file, give filename as option value.
  -out-stderr   Write output to STDERR instead of STDOUT.
  -h, -?, -help, /?    Help text.
  -help-man, -man    Short manual.
  -h=, -help-rule=    Takes a macro or group name as option and returns a description of the rules for handling this if any are defined. If handling rule is package specific, use -incpackage=package name: -incpackage must come before -h= on the command line to take effect.
  -help-options, -h-opt    List all options.
  -help-options=, -h-opt=   List all options containing the provided string, e.g. -h-opt=dir or -h-opt=-v (the initial - in -v causes only options starting with v to be listed).
  -help-tc, -help-inst    List all TeXcount instructions insertable as %TC comments in the TeX document.
  -help-style   List the styles and style categories: i.e. those permitted used with -v={styles-list}.
  -help-style=   Give description of style or style category.
  -ver, -version    Print version number.
  -lic, -license, -licence    Licence information.

::::::::::::::::::::::::::::::::::::::::
:::::::::: TCinstructions
Parsing instructions may be passed to TeXcount using comments in the LaTeX files on the format
@ -      :
  %TC:instruction arguments
and are used to control how TeXcount parses the document. The following instructions are used to set parsing rules which will apply to all subsequent parsing (including other files):
  %TC:macro [macro] [param.states]
    |    macro handling rule, no. of and rules for parameters
  %TC:macrocount [macro] [number]
    |    macro counted as a given number of words (alternative: %TC:macroword)
  %TC:header [macro] [param.states]
    |    header macro rule, as macro but counts as one header (deprecated, use instead: %TC:macro \macro [header])
  %TC:breakmacro [macro] [label]
    |    macro causing subcount break point
  %TC:envir [name] [param.states] [content-state]
    |    \begin-\end environment handling rule (alternative: %TC:group)
  %TC:floatinclude [macro] [param.states]
    |    as macro, but also counted inside floats
  %TC:preambleinclude [macro] [param.states]
    |    as macro, but also counted inside the preamble
  %TC:fileinclue [macro] [rule]
    |    file include, add .tex if rule=2, not if rule=0, if missing when rule=1
The [param.states] is used to indicate the number of parameters used by the macro and the rules of handling each of these: the format is [#,#,...,#] with # representing one number for each parameter giving the parsing state to use for that parameter, alternatively just a single number (#) indicating how many parameters to ignore (parsing state 0). The option [content-state] is used to give the parsing state to use for the contents of a begin-end group. The main parsing states are 0 to ignore and 1 to count as text.

Parsing instructions which may be used anywhere are:
@ -                         :
  %TC:break [title]         add subcount break point here
  %TC:incbib                include bibliography (same as running with -incbib)
  %TC:ignore                ignore region, end with %TC:endignore
  %TC:insert [code]         insert code for TeXcount to process as TeX code
  %TC:subst [from] [to]     replace string thoughout document
  %TC:newtemplate           start a new template, ie delete the existing one
  %TC:template [template]   add another line to the template specification
See the documentation for more details.

Command line options and most %TC commands (prefixed by % rather than %TC:) may be placed in an options file. This is particularly useful for defining your own output templates and macro handling rules.

::::::::::::::::::::::::::::::::::::::::


