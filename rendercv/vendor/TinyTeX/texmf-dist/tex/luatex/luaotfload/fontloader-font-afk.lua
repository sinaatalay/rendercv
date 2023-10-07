if not modules then modules = { } end modules ['font-afk'] = {
    version   = 1.001,
    comment   = "companion to font-lib.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files",
    dataonly  = true,
}

-- For ligatures, only characters with a code smaller than 128 make sense, anything
-- larger is encoding dependent. An interesting complication is that a character can
-- be in an encoding twice but is hashed once.

local allocate = utilities.storage.allocate

fonts.handlers.afm.helpdata = {
    ligatures = allocate { -- okay, nowadays we could parse the name but type 1 fonts
        ['f'] = { -- don't have that many ligatures anyway
            { 'f', 'ff' },
            { 'i', 'fi' },
            { 'l', 'fl' },
        },
        ['ff'] = {
            { 'i', 'ffi' }
        },
        ['fi'] = {
            { 'i', 'fii' }
        },
        ['fl'] = {
            { 'i', 'fli' }
        },
        ['s'] = {
            { 't', 'st' }
        },
        ['i'] = {
            { 'j', 'ij' }
        },
    },
    texligatures = allocate {
     -- ['space'] = {
     --     { 'L', 'Lslash' },
     --     { 'l', 'lslash' }
     -- },
     -- ['question'] = {
     --     { 'quoteleft', 'questiondown' }
     -- },
     -- ['exclam'] = {
     --     { 'quoteleft', 'exclamdown' }
     -- },
        ['quoteleft'] = {
            { 'quoteleft', 'quotedblleft' }
        },
        ['quoteright'] = {
            { 'quoteright', 'quotedblright' }
        },
        ['hyphen'] = {
            { 'hyphen', 'endash' }
        },
        ['endash'] = {
            { 'hyphen', 'emdash' }
        }
    },
    leftkerned = allocate {
        AEligature = "A",  aeligature = "a",
        OEligature = "O",  oeligature = "o",
        IJligature = "I",  ijligature = "i",
        AE         = "A",  ae         = "a",
        OE         = "O",  oe         = "o",
        IJ         = "I",  ij         = "i",
        Ssharp     = "S",  ssharp     = "s",
    },
    rightkerned = allocate {
        AEligature = "E",  aeligature = "e",
        OEligature = "E",  oeligature = "e",
        IJligature = "J",  ijligature = "j",
        AE         = "E",  ae         = "e",
        OE         = "E",  oe         = "e",
        IJ         = "J",  ij         = "j",
        Ssharp     = "S",  ssharp     = "s",
    },
    bothkerned = allocate {
        Acircumflex = "A",  acircumflex = "a",
        Ccircumflex = "C",  ccircumflex = "c",
        Ecircumflex = "E",  ecircumflex = "e",
        Gcircumflex = "G",  gcircumflex = "g",
        Hcircumflex = "H",  hcircumflex = "h",
        Icircumflex = "I",  icircumflex = "i",
        Jcircumflex = "J",  jcircumflex = "j",
        Ocircumflex = "O",  ocircumflex = "o",
        Scircumflex = "S",  scircumflex = "s",
        Ucircumflex = "U",  ucircumflex = "u",
        Wcircumflex = "W",  wcircumflex = "w",
        Ycircumflex = "Y",  ycircumflex = "y",

        Agrave = "A",  agrave = "a",
        Egrave = "E",  egrave = "e",
        Igrave = "I",  igrave = "i",
        Ograve = "O",  ograve = "o",
        Ugrave = "U",  ugrave = "u",
        Ygrave = "Y",  ygrave = "y",

        Atilde = "A",  atilde = "a",
        Itilde = "I",  itilde = "i",
        Otilde = "O",  otilde = "o",
        Utilde = "U",  utilde = "u",
        Ntilde = "N",  ntilde = "n",

        Adiaeresis = "A",  adiaeresis = "a",  Adieresis = "A",  adieresis = "a",
        Ediaeresis = "E",  ediaeresis = "e",  Edieresis = "E",  edieresis = "e",
        Idiaeresis = "I",  idiaeresis = "i",  Idieresis = "I",  idieresis = "i",
        Odiaeresis = "O",  odiaeresis = "o",  Odieresis = "O",  odieresis = "o",
        Udiaeresis = "U",  udiaeresis = "u",  Udieresis = "U",  udieresis = "u",
        Ydiaeresis = "Y",  ydiaeresis = "y",  Ydieresis = "Y",  ydieresis = "y",

        Aacute = "A",  aacute = "a",
        Cacute = "C",  cacute = "c",
        Eacute = "E",  eacute = "e",
        Iacute = "I",  iacute = "i",
        Lacute = "L",  lacute = "l",
        Nacute = "N",  nacute = "n",
        Oacute = "O",  oacute = "o",
        Racute = "R",  racute = "r",
        Sacute = "S",  sacute = "s",
        Uacute = "U",  uacute = "u",
        Yacute = "Y",  yacute = "y",
        Zacute = "Z",  zacute = "z",

        Dstroke = "D",  dstroke = "d",
        Hstroke = "H",  hstroke = "h",
        Tstroke = "T",  tstroke = "t",

        Cdotaccent = "C",  cdotaccent = "c",
        Edotaccent = "E",  edotaccent = "e",
        Gdotaccent = "G",  gdotaccent = "g",
        Idotaccent = "I",  idotaccent = "i",
        Zdotaccent = "Z",  zdotaccent = "z",

        Amacron = "A",  amacron = "a",
        Emacron = "E",  emacron = "e",
        Imacron = "I",  imacron = "i",
        Omacron = "O",  omacron = "o",
        Umacron = "U",  umacron = "u",

        Ccedilla = "C",  ccedilla = "c",
        Kcedilla = "K",  kcedilla = "k",
        Lcedilla = "L",  lcedilla = "l",
        Ncedilla = "N",  ncedilla = "n",
        Rcedilla = "R",  rcedilla = "r",
        Scedilla = "S",  scedilla = "s",
        Tcedilla = "T",  tcedilla = "t",

        Ohungarumlaut = "O",  ohungarumlaut = "o",
        Uhungarumlaut = "U",  uhungarumlaut = "u",

        Aogonek = "A",  aogonek = "a",
        Eogonek = "E",  eogonek = "e",
        Iogonek = "I",  iogonek = "i",
        Uogonek = "U",  uogonek = "u",

        Aring = "A",  aring = "a",
        Uring = "U",  uring = "u",

        Abreve = "A",  abreve = "a",
        Ebreve = "E",  ebreve = "e",
        Gbreve = "G",  gbreve = "g",
        Ibreve = "I",  ibreve = "i",
        Obreve = "O",  obreve = "o",
        Ubreve = "U",  ubreve = "u",

        Ccaron = "C",  ccaron = "c",
        Dcaron = "D",  dcaron = "d",
        Ecaron = "E",  ecaron = "e",
        Lcaron = "L",  lcaron = "l",
        Ncaron = "N",  ncaron = "n",
        Rcaron = "R",  rcaron = "r",
        Scaron = "S",  scaron = "s",
        Tcaron = "T",  tcaron = "t",
        Zcaron = "Z",  zcaron = "z",

        dotlessI = "I",  dotlessi = "i",
        dotlessJ = "J",  dotlessj = "j",

        AEligature = "AE",  aeligature = "ae",  AE         = "AE",  ae         = "ae",
        OEligature = "OE",  oeligature = "oe",  OE         = "OE",  oe         = "oe",
        IJligature = "IJ",  ijligature = "ij",  IJ         = "IJ",  ij         = "ij",

        Lstroke    = "L",   lstroke    = "l",   Lslash     = "L",   lslash     = "l",
        Ostroke    = "O",   ostroke    = "o",   Oslash     = "O",   oslash     = "o",

        Ssharp     = "SS",  ssharp     = "ss",

        Aumlaut = "A",  aumlaut = "a",
        Eumlaut = "E",  eumlaut = "e",
        Iumlaut = "I",  iumlaut = "i",
        Oumlaut = "O",  oumlaut = "o",
        Uumlaut = "U",  uumlaut = "u",
    }
}
