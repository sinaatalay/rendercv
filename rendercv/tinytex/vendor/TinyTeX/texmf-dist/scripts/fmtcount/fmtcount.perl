# File        : fmtcount.perl
# Author      : Nicola Talbot
# Date        : 2012-09-25
# Version     : 1.06
# Description : LaTeX2HTML implementation of fmtcount package
# This file should be place in LaTeX2HTML's styles directory
# in order for LaTeX2HTML to find it.

package main;

sub do_fmtcount_raise{
   local($tmp)="";

   $tmp .= 'sub do_cmd_fmtord{';
   $tmp .= 'local($_) = @_;';
   $tmp .= 'local($suffix) = &missing_braces unless (s/$next_pair_pr_rx/$suffix=$2;\'\'/eo);';
   $tmp .= 'join("", "<SUP>",$suffix,"</SUP>",$_);';
   $tmp .='}';

   eval($tmp);
}

sub do_fmtcount_level{
   local($tmp)="";

   $tmp .= 'sub do_cmd_fmtord{';
   $tmp .= 'local($_) = @_;';
   $tmp .= 'local($suffix) = &missing_braces unless (s/$next_pair_pr_rx/$suffix=$2;\'\'/eo);';
   $tmp .= 'join("", $suffix,$_);';
   $tmp .='}';

   eval($tmp);
}

if (not defined &do_cmd_fmtord)
{
   &do_fmtcount_raise(@_);
}

$frenchdialect = 'france';
$ordinalabbrv = 0;

sub get_ordinal_suffix_english{
   local($num,$gender) = @_;
   local($suffix);

   if ((($num % 10) == 1) && ($num%100 != 11))
   {
      $suffix = 'st';
   }
   elsif ((($num % 10) == 2) && ($num%100 != 12))
   {
      $suffix = 'nd';
   }
   elsif ((($num % 10) == 3) && ($num%100 != 13))
   {
      $suffix = 'rd';
   }
   else
   {
      $suffix = 'th';
   }

   $suffix;
}

sub get_ordinal_suffix_french{
   local($num,$gender) = @_;
   local($_);

   if ($ordinalabbrv > 0)
   {
      $_ = 'e';
   }
   else
   {
      if ($num == 1)
      {
         $_ =  ($gender eq 'f' ? 'ere' : 'er');
      }
      else
      {
         $_ = 'eme';
      }
   }
}

sub get_ordinal_suffix_spanish{
   local($num,$gender) = @_;

   ($gender eq 'f' ? 'a' : 'o');
}

sub get_ordinal_suffix_portuges{
   local($num,$gender) = @_;

   ($gender eq 'f' ? 'a' : 'o');
}

sub get_ordinal_suffix_german{
   local($num,$gender) = @_;

   '';
}

sub get_ordinal_suffix_ngerman{
   local($num,$gender) = @_;

   '';
}

sub get_ordinal_suffix{
   local($num,$gender) = @_;
   local($suffix,$suffixsub);

   $suffixsub = "get_ordinal_suffix_$default_language";

   if (defined ($suffixsub))
   {
      $suffix = &$suffixsub($num,$gender);
   }
   else
   {
      $suffix = &get_ordinal_suffix_english($num,$gender);
   }

   $suffix;
}

sub getordinal{
   local($num,$gender) = @_;
   local($suffix) = &get_ordinal_suffix($num,$gender);
   local($text)='';

   if ($suffix eq '')
   {
      $text = $num;
   }
   else
   {
      local($br_id) = ++$global{'max_id'};
      $text = $num . "\\fmtord${OP}$br_id${CP}$suffix${OP}$br_id${CP}";
   }

   $text;
}

sub do_cmd_ordinalnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);
   my($gender)='m';
   local($suffix)='';

   if (s/\[([mfn])\]//)
   {
      $gender = $1;
   }

   $suffix = &get_ordinal_suffix($num,$gender);

   local($br_id) = ++$global{'max_id'};
   join('', $num, "\\fmtord${OP}$br_id${CP}$suffix${OP}$br_id${CP}", $_);
}

sub do_cmd_FCordinal{
   &do_cmd_ordinal;
}

sub do_cmd_ordinal{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);
   my($gender)='m';

   $_[0] =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_[0]=~s/\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $str eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      join('', '{ORDINAL{', $ctr, '}}', $_[0]);
   }
   else
   {
      join('', &getordinal($val, $gender), $_[0]);
   }
}

sub do_cmd_storeordinal{
   local($_) = @_;
   local($key);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   local($ctr, $val, $id, $_) = &read_counter_value($_);
   my($gender)='m';

   $_ =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      $fmtcntvar{$key} = join('', '{ORDINAL{', $ctr, '}}');
   }
   else
   {
      $fmtcntvar{$key} = &getordinal($val, $gender);
   }

   $_;
}

sub do_cmd_storeordinalnum{
   local($_) = @_;
   local($key, $val);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   $val = &missing_braces
          unless (s/$next_pair_pr_rx/$val=$2;''/eo);

   my($gender)='m';

   if ($_ =~s/\s*\[([mfn])\]//)
   {
      $gender = $1;
   }

   $fmtcntvar{$key} = &getordinal($val, $gender);

   $_;
}

@unitthstring = ('zeroth',
                 'first',
                 'second',
                 'third',
                 'fourth',
                 'fifth',
                 'sixth',
                 'seventh',
                 'eighth',
                 'ninth');

@tenthstring  = ('',
                 'tenth',
                 'twentieth',
                 'thirtieth',
                 'fortieth',
                 'fiftieth',
                 'sixtieth',
                 'seventieth',
                 'eightieth',
                 'ninetieth');

@teenthstring = ('tenth',
                 'eleventh',
                 'twelfth',
                 'thirteenth',
                 'fourteenth',
                 'fifteenth',
                 'sixteenth',
                 'seventeenth',
                 'eighteenth',
                 'nineteenth');

@unitstring = ('zero',
               'one',
               'two',
               'three',
               'four',
               'five',
               'six',
               'seven',
               'eight',
               'nine');

@teenstring = ('ten',
              'eleven',
              'twelve',
              'thirteen',
              'fourteen',
              'fifteen',
              'sixteen',
              'seventeen',
              'eighteen',
              'nineteen');
@tenstring  = ('',
              'ten',
              'twenty',
              'thirty',
              'forty',
              'fifty',
              'sixty',
              'seventy',
              'eighty',
              'ninety');

$hundredname    = "hundred";
$hundredthname  = "hundredth";
$thousandname   = "thousand";
$thousandthname = "thousandth";

sub get_numberstringenglish{
   local($num) = @_;
   local($name)="";

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000)
      {
         local($thousands) = &get_numberstringenglish($num/1000);
         $name .= $thousands . " $thousandname";
         $num = $num%1000;
      }

      if ($num >= 100)
      {
         if ($_[0] >= 1000) { $name .= " "; }

         local($hundreds) = &get_numberstringenglish($num/100);
         $name .= $hundreds . " $hundredname";
         $num = $num%100;
      }

      if (($_[0] > 100) && ($_[0]%100 > 0)) { $name .= " and "; }

      if ($num >= 20)
      {
         $name .= $tenstring[$num/10];

         if ($num%10 > 0) { $name .= '-'; }
      }

      if (($num >= 10) && ($num < 20))
      {
         $name .= $teenstring[$num%10];
      }
      elsif (($num%10 > 0) || ($_[0] == 0))
      {
         $name .= $unitstring[$num%10];
      }
   }

   $name;
}

@unitthstringfrench = ('zeroi\`eme',
                 'uni\`eme',
                 'deuxi\`eme',
                 'troisi\`eme',
                 'quatri\`eme',
                 'cinqui\`eme',
                 'sixi\`eme',
                 'septi\`eme',
                 'huiti\`eme',
                 'neuvi\`eme');

@tenthstringfrench  = ('',
                 'dixi\`eme',
                 'vingti\`eme',
                 'trentri\`eme',
                 'quaranti\`eme',
                 'cinquanti\`eme',
                 'soixanti\`eme',
                 'septenti\`eme',
                 'huitanti\`eme',
                 'nonenti\`eme');

@teenthstringfrench = ('dixi\`eme',
                 'onzi\`eme',
                 'douzi\`eme',
                 'treizi\`eme',
                 'quatorzi\`eme',
                 'quinzi\`eme',
                 'seizi\`eme',
                 'dix-septi\`eme',
                 'dix-huiti\`eme',
                 'dix-neuvi\`eme');

@unitstringfrench = ('zero',
               'un',
               'deux',
               'trois',
               'quatre',
               'cinq',
               'six',
               'sept',
               'huit',
               'neuf');

@teenstringfrench = ('dix',
              'onze',
              'douze',
              'treize',
              'quatorze',
              'quinze',
              'seize',
              'dix-sept',
              'dix-huit',
              'dix-neuf');

@tenstringfrench  = ('',
              'dix',
              'vingt',
              'trente',
              'quarante',
              'cinquante',
              'soixante',
              'septante',
              'octante',
              'nonante');

$hundrednamefrench    = "cent";
$hundredthnamefrench  = "centi\\`eme";
$thousandnamefrench   = "mille";
$thousandthnamefrench = "mili\\`eme";

@unitthstringspanish = ('cero',
                 'primero',
                 'segundo',
                 'tercero',
                 'cuarto',
                 'quinto',
                 'sexto',
                 's\\\'eptimo',
                 'octavo',
                 'noveno');

@tenthstringspanish  = ('',
                 'd\\\'ecimo',
                 'vig\\\'esimo',
                 'trig\\\'esimo',
                 'cuadrag\\\'esimo',
                 'quincuag\\\'esimo',
                 'sexag\\\'esimo',
                 'septuag\\\'esimo',
                 'octog\\\'esimo',
                 'nonag\\\'esimo');

@teenthstringspanish = ('d\\\'ecimo',
                 'und\\\'ecimo',
                 'duod\\\'ecimo',
                 'decimotercero',
                 'decimocuarto',
                 'decimoquinto',
                 'decimosexto',
                 'decimos\\\'eptimo',
                 'decimoctavo',
                 'decimonoveno');

@hundredthstringspanish  = ('',
              'cent\\\'esimo',
              'ducent\\\'esimo',
              'tricent\\\'esimo',
              'cuadringent\\\'esimo',
              'quingent\\\'esimo',
              'sexcent\\\'esimo',
              'septing\\\'esimo',
              'octingent\\\'esimo',
              'noningent\\\'esimo');

@unitstringspanish = ('cero',
               'uno',
               'dos',
               'tres',
               'cuatro',
               'cinco',
               'seis',
               'siete',
               'ocho',
               'nueve');

@teenstringspanish = ('diez',
              'once',
              'doce',
              'trece',
              'catorce',
              'quince',
              'diecis\\\'eis',
              'diecisiete',
              'dieciocho',
              'diecinueve');

@twentystringspanish = ('viente',
              'vientiuno',
              'vientid\\\'os',
              'vientitr\\\'es',
              'vienticuatro',
              'vienticinco',
              'vientis\\\'eis',
              'vientisiete',
              'vientiocho',
              'vientinueve');

@tenstringspanish  = ('',
              'diez',
              'viente',
              'treinta',
              'cuarenta',
              'cincuenta',
              'sesenta',
              'setenta',
              'ochenta',
              'noventa');

@hundredstringspanish  = ('',
              'ciento',
              'doscientos',
              'trescientos',
              'cuatrocientos',
              'quinientos',
              'seiscientos',
              'setecientos',
              'ochocientos',
              'novecientos');

$hundrednamespanish    = "cien";
$hundredthnamespanish  = "centi\\`eme";
$thousandnamespanish   = "mil";
$thousandthnamespanish = "mil\\'esimo";

@unitthstringportuges = ('zero',
                 'primeiro',
                 'segundo',
                 'terceiro',
                 'quatro',
                 'quinto',
                 'sexto',
                 's\\\'etimo',
                 'oitavo',
                 'nono');

@tenthstringportuges  = ('',
                 'd\\\'ecimo',
                 'vig\\\'esimo',
                 'trig\\\'esimo',
                 'quadrag\\\'esimo',
                 'q\"uinquag\\\'esimo',
                 'sexag\\\'esimo',
                 'setuag\\\'esimo',
                 'octog\\\'esimo',
                 'nonag\\\'esimo');

@hundredthstringportuges  = ('',
              'cent\\\'esimo',
              'ducent\\\'esimo',
              'trecent\\\'esimo',
              'quadringent\\\'esimo',
              'q\"uingent\\\'esimo',
              'seiscent\\\'esimo',
              'setingent\\\'esimo',
              'octingent\\\'esimo',
              'nongent\\\'esimo');

@unitstringportuges = ('zero',
               'um',
               'dois',
               'tr\^es',
               'quatro',
               'cinco',
               'seis',
               'sete',
               'oito',
               'nove');

@teenstringportuges = ('dez',
              'onze',
              'doze',
              'treze',
              'quatorze',
              'quinze',
              'dezesseis',
              'dezessete',
              'dezoito',
              'dezenove');

@tenstringportuges  = ('',
              'dez',
              'vinte',
              'trinta',
              'quaranta',
              'cinq\"uenta',
              'sessenta',
              'setenta',
              'oitenta',
              'noventa');

@hundredstringportuges  = ('',
              'cento',
              'duzentos',
              'trezentos',
              'quatrocentos',
              'quinhentos',
              'seiscentos',
              'setecentos',
              'oitocentos',
              'novecentos');

$hundrednameportuges    = "cem";
$thousandnameportuges   = "mil";
$thousandthnameportuges = "mil\\'esimo";

sub get_numberstringfrench{
   local($num,$gender) = @_;
   local($name)="";

   if ($gender eq 'f')
   {
      $unitstringfrench[1] = 'une';
   }
   else
   {
      $unitstringfrench[1] = 'un';
   }

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000)
      {
         local($thousands) = '';

         if ($num >= 2000)
         {
            $thousands = &get_numberstringfrench($num/1000,$gender).' ';
         }

         $name .= $thousands . $thousandnamefrench;
         $num = $num%1000;
      }

      if ($num >= 100)
      {
         if ($_[0] >= 1000) { $name .= " "; }

         local($hundreds) = '';

         if ($num >= 200)
         {
            $hundreds = &get_numberstringfrench($num/100,$gender).' ';
         }

         $name .= $hundreds . $hundrednamefrench;
         $num = $num%100;

         if (($_[0]%100 == 0) && ($_[0]/100 > 1))
         {
           $name .= 's';
         }
      }

      if (($_[0] > 100) && ($_[0]%100 > 0)) { $name .= " "; }

      if ($num >= 20)
      {
         if ($frenchdialect eq 'france' and $num >= 70)
         {
            if ($num < 80)
            {
               $name .= $tenstringfrench[6];

               if ($num%10 == 1)
               {
                  $name .= ' et ';
               }
               else
               {
                  $name .= '-';
               }

               $num = 10+($num%10);
            }
            else
            {
               $name .= 'quatre-vingt' . ($num==80?'s':'-');

               if ($num >= 90)
               {
                  $num = 10+($num%10);
               }
            }
         }
         elsif ($frenchdialect eq 'belgian'
            && ($num >= 80) && ($num < 90))
         {
            $name .= 'quatre-vingt' . ($num==80?'s':'-');
         }
         else
         {
            $name .= $tenstringfrench[$num/10];

            if ($num%10 == 1) { $name .= ' et ';}
            elsif ($num%10 > 0) { $name .= '-'; }
         }
      }

      if (($num >= 10) && ($num < 20))
      {
         $name .= $teenstringfrench[$num%10];
      }
      elsif (($num%10 > 0) || ($_[0] == 0))
      {
         $name .= $unitstringfrench[$num%10];
      }
   }

   $name;
}

sub get_numberstringspanish{
   local($num,$gender) = @_;
   local($name)="";

   if ($gender eq 'f')
   {
      $unitstringspanish[1] = 'una';
   }
   else
   {
      $unitstringspanish[1] = 'uno';
   }

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000)
      {
         local($thousands) = '';

         if ($num >= 2000)
         {
            $thousands = &get_numberstringspanish($num/1000,$gender).' ';
         }

         $name .= $thousands . $thousandnamespanish;
         $num = $num%1000;
      }

      if ($num >= 100)
      {
         if ($_[0] >= 1000) { $name .= " "; }

         local($hundreds) = '';

         if ($num > 100)
         {
            $hundreds = $hundredstringspanish[$num/100];
         }
         else
         {
            $hundreds = 'cien';
         }

         $name .= $hundreds;
         $num = $num%100;
      }

      if (($_[0] > 100) && ($_[0]%100 > 0)) { $name .= " y "; }

      if ($num >= 30)
      {
         $name .= $tenstringspanish[$num/10];

         if ($num%10 > 0) { $name .= ' y '; }
      }

      if (($num >=20) && ($num < 30))
      {
         $name .= $twentystringspanish[$num%10];
      }
      elsif (($num >= 10) && ($num < 20))
      {
         $name .= $teenstringspanish[$num%10];
      }
      elsif (($num%10 > 0) || ($_[0] == 0))
      {
         $name .= $unitstringspanish[$num%10];
      }
   }

   $name;
}

sub get_numberstringportuges{
   local($num,$gender) = @_;
   local($name)="";

   if ($gender eq 'f')
   {
      $unitstringportuges[0] = 'zera';
      $unitstringportuges[1] = 'uma';
      $unitstringportuges[2] = 'duas';
   }
   else
   {
      $unitstringportuges[0] = 'zero';
      $unitstringportuges[1] = 'um';
      $unitstringportuges[2] = 'dois';
   }

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000)
      {
         local($thousands) = '';

         if ($num >= 2000)
         {
            $thousands = &get_numberstringportuges($num/1000,$gender).' ';
         }

         $name .= $thousands . $thousandnameportuges;
         $num = $num%1000;
      }

      if ($num >= 100)
      {
         if ($_[0] >= 1000) { $name .= " "; }

         local($hundreds) = '';

         if ($num > 100)
         {
            $hundreds = $hundredstringportuges[$num/100];

            if ($gender eq 'f' and $num >= 200)
            {
               $hundreds =~s/o(s?)$/a\1/;
            }
         }
         else
         {
            $hundreds = $hundrednameportuges;
         }

         $name .= $hundreds;
         $num = $num%100;
      }

      if (($_[0] > 100) && ($_[0]%100 > 0)) { $name .= " e "; }

      if ($num >= 20)
      {
         $name .= $tenstringportuges[$num/10];

         if ($num%10 == 1) { $name .= ' e ';}
         elsif ($num%10 > 0) { $name .= ' '; }
      }

      if (($num >= 10) && ($num < 20))
      {
         $name .= $teenstringportuges[$num%10];
      }
      elsif (($num%10 > 0) || ($_[0] == 0))
      {
         $name .= $unitstringportuges[$num%10];
      }
   }

   $name;
}

@unitthstringMgerman = ('nullter',
                 'erster',
                 'zweiter',
                 'dritter',
                 'vierter',
                 'f\\"unter',
                 'sechster',
                 'siebter',
                 'achter',
                 'neunter');

@tenthstringMgerman  = ('',
                 'zehnter',
                 'zwanzigster',
                 'drei\\ss igster',
                 'vierzigster',
                 'f\\"unfzigster',
                 'sechzigster',
                 'siebzigster',
                 'achtzigster',
                 'neunzigster');

@teenthstringMgerman = ('zehnter',
                 'elfter',
                 'zw\\"olfter',
                 'dreizehnter',
                 'vierzehnter',
                 'f\\"unfzehnter',
                 'sechzehnter',
                 'siebzehnter',
                 'achtzehnter',
                 'neunzehnter');

@unitthstringFgerman = ('nullte',
                 'erste',
                 'zweite',
                 'dritte',
                 'vierte',
                 'f\\"unfte',
                 'sechste',
                 'siebte',
                 'achte',
                 'neunte');

@tenthstringFgerman  = ('',
                 'zehnte',
                 'zwanzigste',
                 'drei\\ss igste',
                 'vierzigste',
                 'f\\"unfzigste',
                 'sechzigste',
                 'siebzigste',
                 'achtzigste',
                 'neunzigste');

@teenthstringFgerman = ('zehnte',
                 'elfte',
                 'zw\\"olfte',
                 'dreizehnte',
                 'vierzehnte',
                 'f\\"unfzehnte',
                 'sechzehnte',
                 'siebzehnte',
                 'achtzehnte',
                 'neunzehnte');

@unitthstringNgerman = ('nulltes',
                 'erstes',
                 'zweites',
                 'drittes',
                 'viertes',
                 'f\\"unte',
                 'sechstes',
                 'siebtes',
                 'achtes',
                 'neuntes');

@tenthstringNgerman  = ('',
                 'zehntes',
                 'zwanzigstes',
                 'drei\\ss igstes',
                 'vierzigstes',
                 'f\\"unfzigstes',
                 'sechzigstes',
                 'siebzigstes',
                 'achtzigstes',
                 'neunzigstes');

@teenthstringNgerman = ('zehntes',
                 'elftes',
                 'zw\\"olftes',
                 'dreizehntes',
                 'vierzehntes',
                 'f\\"unfzehntes',
                 'sechzehntes',
                 'siebzehntes',
                 'achtzehntes',
                 'neunzehntes');

@unitstringgerman = ('null',
               'ein', # eins dealt with separately (this is for prefixes)
               'zwei',
               'drei',
               'vier',
               'f\\"unf',
               'sechs',
               'sieben',
               'acht',
               'neun');

@teenstringgerman = ('zehn',
              'elf',
              'zw\\"olf',
              'dreizehn',
              'vierzehn',
              'f\\"unfzehn',
              'sechzehn',
              'siebzehn',
              'achtzehn',
              'neunzehn');

@tenstringgerman  = ('',
              'zehn',
              'zwanzig',
              'drei\\ss ig',
              'vierzig',
              'f\\"unfzig',
              'sechzig',
              'siebzig',
              'achtzig',
              'neunzig');

sub do_cmd_einhundert{
   local($_) = @_;

   "einhundert$_";
}

sub do_cmd_eintausend{
   local($_) = @_;

   "eintausend$_";
}

sub get_numberunderhundredgerman{
   local($num)=@_;
   local($name)='';

   if ($num == 1)
   {
      $name = 'eins';
   }
   elsif ($num < 10)
   {
      $name = $unitstringgerman[$num];
   }
   elsif ($num%10 == 0)
   {
      $name = $tenstringgerman[$num/10];
   }
   else
   {
      $name = join('und', $unitstringgerman[$num%10],
                          $tenstringgerman[$num/10]);
   }

   $name;
}

sub get_numberstringgerman{
   local($orgnum,$gender) = @_;
   local($name)="";

   local($num) = $orgnum;

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000 and $num < 2000)
      {
         $name = &translate_commands("\\eintausend ");
      }
      elsif ($num >= 2000)
      {
         $name = &get_numberunderhundredgerman($num/1000)
               . "tausend";
      }

      $num = $orgnum%1000;

      if ($num >= 100 and $num < 200)
      {
         if ($orgnum > 1000)
         {
            $name .= "einhundert";
         }
         else
         {
            $name = &translate_commands("\\einhundert ");
         }
      }
      elsif ($num >= 200)
      {
         $name .= $unitstringgerman[$num/100]."hundert";
      }

      $num = $num%100;

      if ($orgnum == 0)
      {
         $name = 'null';
      }
      elsif ($num > 0)
      {
         $name .= &get_numberunderhundredgerman($num);
      }
   }

   $name;
}

sub get_numberstring{
   local($val,$gender) = @_;

   if ($default_language eq 'french')
   {
      &get_numberstringfrench($val,$gender);
   }
   elsif ($default_language eq 'spanish')
   {
      &get_numberstringspanish($val,$gender);
   }
   elsif ($default_language eq 'portuges')
   {
      &get_numberstringportuges($val,$gender);
   }
   elsif ($default_language eq 'german'
       or $default_language eq 'ngerman')
   {
      &get_numberstringgerman($val,$gender);
   }
   else
   {
      &get_numberstringenglish($val);
   }
}

sub do_cmd_numberstringnum{
   local($_) = @_;
   local($num,$gender);
   $num = &missing_braces unless
      s/$next_pair_pr_rx/$num=$2;''/eo;

   if (s/\[(m|f|n)\]//)
   {
      $gender = $1;
   }
   else
   {
      $gender = 'm';
   }

   join('', &get_numberstring($num,$gender), $_);
}

sub do_cmd_numberstring{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);
   my($gender)='m';

   $_[0] =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_[0]=~s/\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      join('', '{NUMBERSTRING{', $ctr, '}}', $_[0]);
   }
   else
   {
      join('', &get_numberstring($val, $gender), $_[0]);
   }
}

sub do_cmd_storenumberstring{
   local($_) = @_;
   local($key);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   local($ctr, $val, $id, $_) = &read_counter_value($_);
   my($gender)='m';

   $_ =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      $fmtcntvar{$key} = join('', '{NUMBERSTRING{', $ctr, '}}');
   }
   else
   {
      $fmtcntvar{$key} = join('', &get_numberstring($val, $gender));
   }

   $_;
}

sub do_cmd_storenumberstringnum{
   local($_) = @_;
   local($key, $val);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   $val = &missing_braces
          unless (s/$next_pair_pr_rx/$val=$2;''/eo);

   my($gender)='m';

   if ($_ =~s/\s*\[([mfn])\]//)
   {
      $gender = $1;
   }

   $fmtcntvar{$key} = join('', &get_numberstring($val, $gender));

   $_;
}

sub get_Numberstring{
   local($val,$gender) = @_;
   local($string) = &get_numberstring($val,$gender);

   if ($default_language=~m/german/)
   {
      $string =~ s/([a-z])([^\s\-]+)/\u\1\2/;
   }
   else
   {
      $string =~ s/([a-z])([^\s\-]+)/\u\1\2/g;

      if ($default_language eq 'french')
      {
         $string =~ s/ Et / et /g;
      }
      elsif ($default_language eq 'spanish')
      {
         $string =~ s/ Y / y /g;
      }
      elsif ($default_language eq 'portuges')
      {
         $string =~ s/ E / e /g;
      }
      else
      {
         $string =~ s/ And / and /g;
      }
   }

   $string;
}

sub do_cmd_Numberstringnum{
   local($_) = @_;
   local($num,$gender);
   $num = &missing_braces
          unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   if (s/\[(m|f|n)\]//)
   {
      $gender = $1;
   }
   else
   {
      $gender = 'm';
   }

   join('', &get_Numberstring($num,$gender), $_);
}

sub do_cmd_Numberstring{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);
   my($gender)='m';

   $_[0] =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_[0]=~s/\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      join('', '{NNUMBERSTRING{', $ctr, '}}', $_[0]);
   }
   else
   {
      join('', &get_Numberstring($val, $gender), $_[0]);
   }
}

sub do_cmd_storeNumberstring{
   local($_) = @_;
   local($key);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   local($ctr, $val, $id, $_) = &read_counter_value($_);
   my($gender)='m';

   $_ =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_ =~s/\s*\[([mfn])\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      $fmtcntvar{$key} = join('', '{NNUMBERSTRING{', $ctr, '}}');
   }
   else
   {
      $fmtcntvar{$key} = join('', &get_Numberstring($val, $gender));
   }

   $_;
}

sub do_cmd_storeNumberstringnum{
   local($_) = @_;
   local($key, $val);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   $val = &missing_braces
          unless (s/$next_pair_pr_rx/$val=$2;''/eo);

   my($gender)='m';

   if ($_ =~s/\s*\[([mfn])\]//)
   {
      $gender = $1;
   }

   $fmtcntvar{$key} = join('', &get_Numberstring($val, $gender));

   $_;
}

sub do_cmd_NUMBERstringnum{
   local($_) = @_;
   local($num,$gender);
   $num = &missing_braces
          unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   if (s/\[(m|f|n)\]//)
   {
      $gender = $1;
   }
   else
   {
      $gender = 'm';
   }

   join('', uc(&get_numberstring($num,$gender)), $_);
}

sub do_cmd_NUMBERstring{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);
   my($gender)='m';

   $_[0] =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_[0]=~s/\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      join('', '{CAPNUMBERSTRING{', $ctr, '}}', $_);
   }
   else
   {
      join('', uc(&get_numberstring($val, $gender)), $_);
   }
}

sub do_cmd_storeNUMBERstring{
   local($_) = @_;
   local($key);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   local($ctr, $val, $id, $_) = &read_counter_value($_);
   my($gender)='m';

   $_ =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      $fmtcntvar{$key} = join('', '{CAPNUMBERSTRING{', $ctr, '}}');
   }
   else
   {
      $fmtcntvar{$key} = uc(&get_numberstring($val, $gender));
   }

   $_;
}

sub do_cmd_storeNUMBERstringnum{
   local($_) = @_;
   local($key, $val);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   $val = &missing_braces
          unless (s/$next_pair_pr_rx/$val=$2;''/eo);

   my($gender)='m';

   if ($_ =~s/\s*\[([mfn])\]//)
   {
      $gender = $1;
   }

   $fmtcntvar{$key} = uc(&get_numberstring($val, $gender));

   $_;
}

sub get_ordinalstringenglish{
   local($num) = @_;
   local($name)="";

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000)
      {
         local($thousands) = &get_numberstring($num/1000);
         $name .= $thousands;

         if ($num%1000 > 0)
         {
            $name .= " $thousandname";
         }
         else
         {
            $name .= " $thousandthname";
         }

         $num = $num%1000;
      }

      if ($num >= 100)
      {
         if ($_[0] >= 1000) { $name .= " "; }

         local($hundreds) = &get_numberstring($num/100);
         $name .= $hundreds;

         if ($num%100 > 0)
         {
            $name .= " $hundredname";
         }
         else
         {
            $name .= " $hundredthname";
         }

         $num = $num%100;
      }

      if (($_[0] > 100) && ($_[0]%100 > 0)) { $name .= " and "; }

      if ($num >= 20)
      {
         if ($num%10 > 0)
         {
            $name .= $tenstring[$num/10] . '-';
         }
         else
         {
            $name .= $tenthstring[$num/10];
         }
      }

      if (($num >= 10) && ($num < 20))
      {
         $name .= $teenthstring[$num%10];
      }
      elsif (($num%10 > 0) || ($_[0] == 0))
      {
         $name .= $unitthstring[$num%10];
      }
   }

   $name;
}

sub get_ordinalstringfrench{
   local($num,$gender) = @_;
   local($name)="";

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000)
      {
         local($thousands) = '';

         if ($num >= 2000)
         {
            $thousands = &get_numberstringfrench($num/1000,$gender).' ';
         }

         $num = $num%1000;

         if ($num > 0)
         {
            $name .= $thousands . $thousandnamefrench;
         }
         else
         {
            $name .= $thousands . $thousandthnamefrench;
         }
      }

      if ($num >= 100)
      {
         if ($_[0] >= 1000) { $name .= " "; }

         local($hundreds) = '';

         if ($num >= 200)
         {
            $hundreds = &get_numberstringfrench($num/100,$gender).' ';
         }

         $num = $num%100;

         if ($num > 0)
         {
            $name .= $hundreds . $hundrednamefrench;
         }
         else
         {
            $name .= $hundreds . $hundredthnamefrench;
         }
      }

      if (($_[0] > 100) && ($_[0]%100 > 0)) { $name .= " "; }

      if ($num >= 20)
      {
         if ($frenchdialect eq 'france' and $num >= 70)
         {
            if ($num < 80)
            {
               if ($num%10 > 0)
               {
                  $name .= $tenstringfrench[6];
               }
               else
               {
                  $name .= $tenthstringfrench[6];
               }

               if ($num%10 == 1)
               {
                  $name .= ' et ';
               }
               else
               {
                  $name .= '-';
               }

               $num = 10+($num%10);
            }
            else
            {
               $name .= 'quatre-vingt' . ($num==80?'i\`eme':'-');

               if ($num >= 90)
               {
                  $num = 10+($num%10);
               }
            }
         }
         elsif ($frenchdialect eq 'belgian' and $num >= 80)
         {
            $name .= 'quatre-vingt' . ($num==80?'i\`eme':'-');

            if ($num >= 90)
            {
               $num = 10+($num%10);
            }
         }
         else
         {
            if ($num%10 > 0)
            {
               $name .= $tenstringfrench[$num/10];
            }
            else
            {
               $name .= $tenthstringfrench[$num/10];
            }

            if ($num%10 == 1) { $name .= ' et ';}
            elsif ($num%10 > 0) { $name .= '-'; }
         }
      }

      if (($num >= 10) && ($num < 20))
      {
         $name .= $teenthstringfrench[$num%10];
      }
      elsif ($_[0] == 1)
      {
         $name = 'premi\`ere';
      }
      elsif (($num%10 > 0) || ($_[0] == 0))
      {
         $name .= $unitthstringfrench[$num%10];
      }
   }

   $name;
}

sub get_ordinalstringspanish{
   local($num,$gender) = @_;
   local($name)="";
   local($str);

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000)
      {
         if ($num >= 2000)
         {
            local($thousands) = &get_ordinalstringspanish($num/1000);

            if ($gender eq 'f')
            {
               $thousands =~s/o(s?)$/a\1/;
            }

            $name .= $thousands. " ";
         }
         else
         {
            $name = "";
         }

         $name .= "$thousandthnamespanish";

         if ($gender eq 'f')
         {
            $name =~s/o$/a/;
         }

         $num = $num%1000;
      }

      if ($num >= 100)
      {
         if ($_[0] >= 1000) { $name .= " "; }

         local($hundreds) = $hundredthstringspanish[$num/100];

         if ($gender eq 'f')
         {
            $hundreds =~s/o$/a/;
         }

         $name .= $hundreds;

         $num = $num%100;
      }

      if (($_[0] > 100) && ($_[0]%100 > 0)) { $name .= " "; }

      local($lastbit)="";

      if ($num >= 20)
      {
         $lastbit = $tenthstringspanish[$num/10];

         if ($num%10 > 0)
         {
            $lastbit .=  ' ';
         }

         if ($gender eq 'f')
         {
            $lastbit =~s/o([ s]*)$/a\1/;
         }

         $name .= $lastbit;

         $lastbit = "";
      }

      if (($num >= 10) && ($num < 20))
      {
         $lastbit = $teenthstringspanish[$num%10];
      }
      elsif (($num%10 > 0) || ($_[0] == 0))
      {
         $lastbit = $unitthstringspanish[$num%10];
      }

      if ($gender eq 'f')
      {
         $lastbit =~s/o([ s]*)$/a\1/;
      }

      $name .= $lastbit;
   }

   $name;
}

sub get_ordinalstringportuges{
   local($num,$gender) = @_;
   local($name)="";
   local($str);

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000)
      {
         if ($num >= 2000)
         {
            local($thousands) = &get_ordinalstringportuges($num/1000);

            if ($gender eq 'f')
            {
               $thousands =~s/o(s?)$/a\1/;
            }

            $name .= $thousands. " ";
         }
         else
         {
            $name = "";
         }

         $name .= "$thousandthnameportuges";

         if ($gender eq 'f')
         {
            $name =~s/o$/a/;
         }

         $num = $num%1000;
      }

      if ($num >= 100)
      {
         if ($_[0] >= 1000) { $name .= " "; }

         local($hundreds) = $hundredthstringportuges[$num/100];

         if ($gender eq 'f')
         {
            $hundreds =~s/o$/a/;
         }

         $name .= $hundreds;

         $num = $num%100;
      }

      if (($_[0] > 100) && ($_[0]%100 > 0)) { $name .= "-"; }

      local($lastbit)="";

      if ($num >= 10)
      {
         $lastbit = $tenthstringportuges[$num/10];

         if ($num%10 > 0)
         {
            $lastbit .=  '-';
         }

         if ($gender eq 'f')
         {
            $lastbit =~s/o([ s]*)$/a\1/;
         }

         $name .= $lastbit;

         $lastbit = "";
      }

      if (($num%10 > 0) || ($_[0] == 0))
      {
         $lastbit = $unitthstringportuges[$num%10];
      }

      if ($gender eq 'f')
      {
         $lastbit =~s/o([ s]*)$/a\1/;
      }

      $name .= $lastbit;
   }

   $name;
}

sub get_numberunderhundredthgerman{
   local($num,$gender)=@_;
   local($name)='';

   if ($num < 10)
   {
      if ($gender eq 'F')
      {
         $name = $unitthstringFgerman[$num];
      }
      elsif ($gender eq 'N')
      {
         $name = $unitthstringNgerman[$num];
      }
      else
      {
         $name = $unitthstringMgerman[$num];
      }
   }
   elsif ($num%10 == 0)
   {
      if ($gender eq 'F')
      {
         $name = $tenthstringFgerman[$num/10];
      }
      elsif ($gender eq 'N')
      {
         $name = $tenthstringNgerman[$num/10];
      }
      else
      {
         $name = $tenthstringMgerman[$num/10];
      }
   }
   else
   {
      local($tenth);
      if ($gender eq 'F')
      {
         $tenth = $tenthstringFgerman[$num/10];
      }
      elsif ($gender eq 'N')
      {
         $tenth = $tenthstringNgerman[$num/10];
      }
      else
      {
         $tenth = $tenthstringMgerman[$num/10];
      }

      $name = join('und', $unitstringgerman[$num%10], $tenth);
   }

   $name;
}

sub get_ordinalstringgerman{
   local($orgnum,$gender) = @_;
   local($name)="";
   local($suffix)='';

   $gender = uc($gender);

   if ($gender eq 'F')
   {
      $suffix = 'ste';
   }
   elsif ($gender eq 'N')
   {
      $suffix = 'stes';
   }
   else
   {
      $suffix = 'ster';
      $gender = 'M';
   }

   local($num) = $orgnum;

   unless (($num >= 1000000) || ($num < 0))
   {
      if ($num >= 1000 and $num < 2000)
      {
         $name = &translate_commands("\\eintausend ");
      }
      elsif ($num >= 2000)
      {
         $name = &get_numberunderhundredgerman($num/1000)
               . "tausend";
      }

      $num = $orgnum%1000;

      # is that it or is there more?
      if ($orgnum >= 1000 and $num == 0)
      {
         $name .= $suffix;
         return $name;
      }

      if ($num >= 100 and $num < 200)
      {
         if ($orgnum > 1000)
         {
            $name .= "einhundert";
         }
         else
         {
            $name = &translate_commands("\\einhundert ");
         }
      }
      elsif ($num >= 200)
      {
         $name .= $unitstringgerman[$num/100]."hundert";
      }

      $num = $num%100;

      # is that it or is there more?
      if ($orgnum >= 100 and $num == 0)
      {
         $name .= $suffix;
         return $name;
      }

      if ($orgnum == 0)
      {
         if ($gender eq 'F')
         {
            $name = $unitthstringFgerman[0];
         }
         elsif ($gender eq 'N')
         {
            $name = $unitthstringNgerman[0];
         }
         else
         {
            $name = $unitthstringMgerman[0];
         }
      }
      elsif ($num > 0)
      {
         $name .= &get_numberunderhundredthgerman($num,$gender);
      }
   }

   $name;
}

sub get_ordinalstring{
   local($val,$gender) = @_;

   if ($default_language eq 'french')
   {
      &get_ordinalstringfrench($val,$gender);
   }
   elsif ($default_language eq 'spanish')
   {
      &get_ordinalstringspanish($val,$gender);
   }
   elsif ($default_language eq 'portuges')
   {
      &get_ordinalstringportuges($val,$gender);
   }
   elsif ($default_language eq 'german'
        or $default_language eq 'ngerman')
   {
      &get_ordinalstringgerman($val,$gender);
   }
   else
   {
      &get_ordinalstringenglish($val);
   }
}

sub do_cmd_ordinalstringnum{
   local($_) = @_;
   local($num,$gender);
   $num = &missing_braces
          unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   if (s/\[(m|f|n)\]//)
   {
      $gender = $1;
   }
   else
   {
      $gender = 'm';
   }

   join('', &get_ordinalstring($num,$gender), $_);
}

sub do_cmd_ordinalstring{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);
   my($gender)='m';

   $_[0] =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_[0]=~s/\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      join('', '{ORDINALSTRING{', $ctr, '}}', $_);
   }
   else
   {
      join('', &get_ordinalstring($val, $gender), $_);
   }
}

 %fmtcntvar = ();

sub do_cmd_FMCuse{
   local($_) = @_;
   local($key);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   $fmtcntvar{$key}.$_;
}

sub do_cmd_storeordinalstring{
   local($_) = @_;
   local($key);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   local($ctr, $val, $id, $_) = &read_counter_value($_);
   my($gender)='m';

   $_ =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      $fmtcntvar{$key} = join('', '{ORDINALSTRING{', $ctr, '}}');
   }
   else
   {
      $fmtcntvar{$key} = join('', &get_ordinalstring($val, $gender));
   }

   $_;
}

sub do_cmd_storeordinalstringnum{
   local($_) = @_;
   local($key, $val);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   $val = &missing_braces
          unless (s/$next_pair_pr_rx/$val=$2;''/eo);

   my($gender)='m';

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   $fmtcntvar{$key} = join('', &get_ordinalstring($val, $gender));

   $_;
}

sub get_Ordinalstring{
   local($val,$gender) = @_;
   local($string) = &get_ordinalstring($val,$gender);

   if ($default_language=~m/german/)
   {
      $string =~ s/\b([a-z])([^\s\-]+)/\u\1\2/;
   }
   else
   {
      $string =~ s/\b([a-z])([^\s\-]+)/\u\1\2/g;

      if ($default_language eq 'french')
      {
         $string =~ s/ Et / et /g;
      }
      else
      {
         $string =~ s/ And / and /g;
      }
   }

   $string;
}

sub do_cmd_Ordinalstringnum{
   local($_) = @_;
   local($num,$gender);
   $num = &missing_braces
          unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   if (s/\[(m|f|n)\]//)
   {
      $gender = $1;
   }
   else
   {
      $gender = 'm';
   }

   join('', &get_Ordinalstring($num,$gender), $_);
}

sub do_cmd_Ordinalstring{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);
   my($gender)='m';

   $_[0] =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_[0]=~s/\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      join('', '{OORDINALSTRING{', $ctr, '}}', $_[0]);
   }
   else
   {
      join('', &get_Ordinalstring($val, $gender), $_[0]);
   }
}

sub do_cmd_storeOrdinalstring{
   local($_) = @_;
   local($key);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   local($ctr, $val, $id, $_) = &read_counter_value($_);
   my($gender)='m';

   $_ =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      $fmtcntvar{$key} = join('', '{OORDINALSTRING{', $ctr, '}}');
   }
   else
   {
      $fmtcntvar{$key} = join('', &get_Ordinalstring($val, $gender));
   }

   $_;
}

sub do_cmd_storeOrdinalstringnum{
   local($_) = @_;
   local($key, $val);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   $val = &missing_braces
          unless (s/$next_pair_pr_rx/$val=$2;''/eo);

   my($gender)='m';

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   $fmtcntvar{$key} = join('', &get_Ordinalstring($val, $gender));

   $_;
}

sub do_cmd_ORDINALstringnum{
   local($_) = @_;
   local($num,$gender);
   $num = &missing_braces
          unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   if (s/\[(m|f|n)\]//)
   {
      $gender = $1;
   }
   else
   {
      $gender = 'm';
   }

   join('', uc(&get_ordinalstring($num,$gender)), $_);
}

sub do_cmd_ORDINALstring{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);
   my($gender)='m';

   $_[0] =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_[0]=~s/\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      join('', '{CAPORDINALSTRING{', $ctr, '}}', $_);
   }
   else
   {
      join('', uc(&get_ordinalstring($val, $gender)), $_);
   }
}

sub do_cmd_storeORDINALstring{
   local($_) = @_;
   local($key);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   local($ctr, $val, $id, $_) = &read_counter_value($_);
   my($gender)='m';

   $_ =~ s/${OP}$id${CP}$ctr${OP}$id${CP}//;

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   if ($ctr eq 'DAY' or $ctr eq 'MONTH' or $ctr eq 'YEAR')
   {
      # this is a cludge to make it work with newdateformat
      $fmtcntvar{$key} = join('', '{CAPORDINALSTRING{', $ctr, '}}');
   }
   else
   {
      $fmtcntvar{$key} = uc(&get_ordinalstring($val, $gender));
   }

   $_;
}

sub do_cmd_storeORDINALstringnum{
   local($_) = @_;
   local($key, $val);

   $key = &missing_braces
          unless ((s/$next_pair_pr_rx//o)&&($key=$2));

   $val = &missing_braces
          unless (s/$next_pair_pr_rx/$val=$2;''/eo);

   my($gender)='m';

   if ($_ =~s/\s*\[(.)\]//)
   {
      $gender = $1;
   }

   $fmtcntvar{$key} = uc(&get_ordinalstring($val, $gender));

   $_;
}

sub do_cmd_fmtcountsetoptions{
   local($_) = @_;
   local($options) = &missing_braces unless ($_[0]=~(s/$next_pair_pr_rx//o)&&($options=$2));

   if ($options =~ m/french=?(\w*)(,|$)/)
   {
      if ($1 eq 'france' or $1 eq 'swiss' or $1 eq 'belgian')
      {
         $frenchdialect = $1;

        print "Using French dialect: $1" if ($VERBOSITY > 0) ;
      }
      elsif ($1 eq '')
      {
         $frenchdialect = 'france';

         print "Using French dialect: france" if ($VERBOSITY > 0);
      }
      else
      {
         &write_warnings("unknown french dialect '$1'");
      }
   }

   if ($options =~ m/abbrv=?(\w*)(,|$)/)
   {
      if ($1 eq 'true' or $1 eq '')
      {
         $ordinalabbrv = 1;

         print "Setting abbrv=true" if ($VERBOSITY > 0);
      }
      elsif ($1 eq 'false')
      {
         $ordinalabbrv = 0;

         print "Setting abbrv=false" if ($VERBOSITY > 0);
      }
      else
      {
         &write_warnings("fmtcountsetoptions key abbrv: unknown value '$1'.");
      }
   }

   if ($options =~ m/fmtord=(\w*)(,|$)/)
   {
      if ($1 eq 'raise')
      {
         &do_fmtcount_raise();

         print "Using raised ordinals" if ($VERBOSITY > 0);
      }
      elsif ($1 eq 'level')
      {
         &do_fmtcount_level();

         print "Using level ordinals" if ($VERBOSITY > 0);
      }
      elsif ($1 eq 'user')
      {
         # do nothing

         print "Using user defined fmtord" if ($VERBOSITY > 0);
      }
      else
      {
         &write_warnings("unknown fmtcount option fmtord=$1");
      }
   }

   $_[0];
}

$padzeroes = 0;

sub do_cmd_padzeroes{
   local($_) = @_;
   local($val,$pat) = &get_next_optional_argument;

   if ($val eq '')
   {
      $padzeroes = 17;
   }
   else
   {
      $padzeroes = $val;
   }

   $_;
}

sub get_binary{
   local($num) = @_;
   local($val) = "";

   for (my $i=17; $i>=0; $i--)
   {
      if (($i < $padzeroes) || ($num & (1 << $i)) || !($val eq ""))
      {
         $val .= ($num & (1 << $i) ? 1 : 0);
      }
   }

   $val;
}

sub do_cmd_binary{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', &get_binary($val), $_);
}

sub do_cmd_binarynum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', &get_binary($num), $_);
}

sub get_decimal{
   local($num) = @_;

   sprintf "%0${padzeroes}d", $num;
}

sub do_cmd_decimal{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', &get_decimal($val), $_);
}

sub do_cmd_decimalnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', &get_decimal($num), $_);
}

sub get_hexadecimal{
   local($num) = @_;

   sprintf "%0${padzeroes}lx", $num;
}

sub do_cmd_hexadecimal{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', &get_hexadecimal($val), $_);
}

sub do_cmd_hexadecimalnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', &get_hexadecimal($num), $_);
}

sub get_Hexadecimal{
   local($num) = @_;

   sprintf "%0${padzeroes}lX", $num;
}

sub do_cmd_Hexadecimal{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', &get_Hexadecimal($val), $_);
}

sub do_cmd_Hexadecimalnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', &get_Hexadecimal($num), $_);
}

sub get_octal{
   local($num) = @_;

   sprintf "%0${padzeroes}lo", $num;
}

sub do_cmd_octal{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', &get_octal($val), $_);
}

sub do_cmd_octalnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', &get_octal($num), $_);
}

sub get_aaalph{
   local($num) = @_;
   local($rep) = int($num/26) + 1;
   local($c) = chr(ord('a')-1+$num%26);

   local($_) = $c x $rep;
}

sub do_cmd_aaalph{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', &get_aaalph($val), $_);
}

sub get_AAAlph{
   local($num) = @_;
   local($rep) = int($num/26) + 1;
   local($c) = chr(ord('A')-1+$num%26);

   local($_) = $c x $rep;
}

sub do_cmd_AAAlph{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', &get_AAAlph($val), $_);
}

sub do_cmd_aaalphnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', (sprintf "%${padzeroes}s", &get_aaalph($num)), $_);
}

sub do_cmd_AAAlphnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', uc(sprintf "%${padzeroes}s", &get_aaalph($num)), $_);
}

sub get_abalph{
   local($num) = @_;
   local($str);

   if ($num == 0)
   {
      $str = '';
   }
   elsif ($num > 0 && $num <= 26)
   {
      $str = chr(ord('a')-1+$num);
   }
   else
   {
      $str = &get_abalph(int($num/26)) . chr(ord('a')-1+($num%26));
   }

   $str;
}

sub do_cmd_abalph{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', (sprintf "%${padzeroes}s", &get_abalph($val)), $_);
}

sub do_cmd_abalphnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', (sprintf "%${padzeroes}s", &get_abalph($num)), $_);
}

sub do_cmd_ABAlph{
   local($ctr, $val, $id, $_) = &read_counter_value($_[0]);

   join('', uc(sprintf "%${padzeroes}s", &get_abalph($val)), $_);
}

sub do_cmd_ABAlphnum{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   join('', uc(sprintf "%${padzeroes}s", &get_abalph($num)), $_);
}

sub get_twodigit{
   local($num) = @_;

   sprintf "%02d", $num;
}

sub do_cmd_twodigit{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   # this is a cludge
   if ($num eq "THEDAY" or $num eq "THEYEAR" or $num eq "THEMONTH")
   {
      join('', 'TWODIGIT{', $num, '}', $_);
   }
   else
   {
      join('', &get_twodigit($num), $_);
   }
}

# this was put here to help with the definition of \datelatin

sub do_cmd_romannumeral{
   local($_) = @_;
   local($num) = &missing_braces
      unless (s/$next_pair_pr_rx/$num=$2;''/eo);

   # this is a cludge
   if ($num eq "THEDAY" or $num eq "THEYEAR" or $num eq "THEMONTH")
   {
      join('', 'ROMANNUMERAL{', $num, '}', $_);
   }
   else
   {
      join('', &froman($num), $_);
   }
}

# load configuration file if it exists
# Note: The configuration file should be loaded before
# the package options are executed.

# why doesn't this work? If I call this subroutine it
# causes an infinite loop.

sub load_fmtcount_cfg{
   local($file,$found);

   $file = &fulltexpath('fmtcount.cfg');

   $found = (-f $file);

   if (!$found)
   {
      foreach $texpath (split /$envkey/, $TEXINPUTS)
      {
         $file = "$texpath${dd}fmtcount.cfg";

         last if ($found = (-f $file));
      }
   }

   if ($found)
   {
      print "\nusing configuration file $file\n";

      &slurp_input($file);
      &pre_process;
      &substitute_meta_cmds if (%new_command || %new_environment);
      &wrap_shorthand_environments;
      $_ = &translate_commands(&translate_environments($_));

      print "\n processed size: ".length($_)."\n" if ($VERBOSITY>1)
   }
   else
   {
      print "\nNo configuation file fmtcount.cfg found\n" if ($VERBOSITY>1)
   }
}

1;
