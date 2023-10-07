if not modules then modules = { } end modules ["font-ott"] = {
    version   = 1.001,
    comment   = "companion to font-ini.mkiv",
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files",
 -- dataonly  = true,
}

local type, next, tonumber, tostring, rawget, rawset = type, next, tonumber, tostring, rawget, rawset
local gsub, lower, format, match, gmatch, find = string.gsub, string.lower, string.format, string.match, string.gmatch, string.find
local sequenced = table.sequenced
local is_boolean = string.is_boolean

local setmetatableindex    = table.setmetatableindex
local setmetatablenewindex = table.setmetatablenewindex
local allocate             = utilities.storage.allocate

local fonts                = fonts
local otf                  = fonts.handlers.otf
local otffeatures          = otf.features

local tables               = otf.tables or { }
otf.tables                 = tables

local statistics           = otf.statistics or { }
otf.statistics             = statistics

local scripts = allocate {
    ["adlm"] = "adlam",
    ["aghb"] = "caucasian albanian",
    ["ahom"] = "ahom",
    ["arab"] = "arabic",
    ["armi"] = "imperial aramaic",
    ["armn"] = "armenian",
    ["avst"] = "avestan",
    ["bali"] = "balinese",
    ["bamu"] = "bamum",
    ["bass"] = "bassa vah",
    ["batk"] = "batak",
    ["beng"] = "bengali",
    ["bhks"] = "bhaiksuki",
    ["bng2"] = "bengali variant 2",
    ["bopo"] = "bopomofo",
    ["brah"] = "brahmi",
    ["brai"] = "braille",
    ["bugi"] = "buginese",
    ["buhd"] = "buhid",
    ["byzm"] = "byzantine music",
    ["cakm"] = "chakma",
    ["cans"] = "canadian syllabics",
    ["cari"] = "carian",
    ["cham"] = "cham",
    ["cher"] = "cherokee",
    ["chrs"] = "chorasmian",
    ["copt"] = "coptic",
    ["cpmn"] = "cypro-minoan",
    ["cprt"] = "cypriot syllabary",
    ["cyrl"] = "cyrillic",
    ["dev2"] = "devanagari variant 2",
    ["deva"] = "devanagari",
    ["diak"] = "dives akuru",
    ["dogr"] = "dogra",
    ["dsrt"] = "deseret",
    ["dupl"] = "duployan",
    ["egyp"] = "egyptian heiroglyphs",
    ["elba"] = "elbasan",
    ["elym"] = "elymaic",
    ["ethi"] = "ethiopic",
    ["geor"] = "georgian",
    ["gjr2"] = "gujarati variant 2",
    ["glag"] = "glagolitic",
    ["gong"] = "gunjala gondi",
    ["gonm"] = "masaram gondi",
    ["goth"] = "gothic",
    ["gran"] = "grantha",
    ["grek"] = "greek",
    ["gujr"] = "gujarati",
    ["gur2"] = "gurmukhi variant 2",
    ["guru"] = "gurmukhi",
    ["hang"] = "hangul",
    ["hani"] = "cjk ideographic",
    ["hano"] = "hanunoo",
    ["hatr"] = "hatran",
    ["hebr"] = "hebrew",
    ["hluw"] = "anatolian hieroglyphs",
    ["hmng"] = "pahawh hmong",
    ["hmnp"] = "nyiakeng puachue hmong",
    ["hung"] = "old hungarian",
    ["ital"] = "old italic",
    ["jamo"] = "hangul jamo",
    ["java"] = "javanese",
    ["kali"] = "kayah li",
    ["kana"] = "hiragana and katakana",
    ["khar"] = "kharosthi",
    ["khmr"] = "khmer",
    ["khoj"] = "khojki",
    ["kits"] = "khitan small script",
    ["knd2"] = "kannada variant 2",
    ["knda"] = "kannada",
    ["kthi"] = "kaithi",
    ["lana"] = "tai tham",
    ["lao" ] = "lao",
    ["latn"] = "latin",
    ["lepc"] = "lepcha",
    ["limb"] = "limbu",
    ["lina"] = "linear a",
    ["linb"] = "linear b",
    ["lisu"] = "lisu",
    ["lyci"] = "lycian",
    ["lydi"] = "lydian",
    ["mahj"] = "mahajani",
    ["maka"] = "makasar",
    ["mand"] = "mandaic and mandaean",
    ["mani"] = "manichaean",
    ["marc"] = "marchen",
    ["math"] = "mathematical alphanumeric symbols",
    ["medf"] = "medefaidrin",
    ["mend"] = "mende kikakui",
    ["merc"] = "meroitic cursive",
    ["mero"] = "meroitic hieroglyphs",
    ["mlm2"] = "malayalam variant 2",
    ["mlym"] = "malayalam",
    ["modi"] = "modi",
    ["mong"] = "mongolian",
    ["mroo"] = "mro",
    ["mtei"] = "meitei Mayek",
    ["mult"] = "multani",
    ["musc"] = "musical symbols",
    ["mym2"] = "myanmar variant 2",
    ["mymr"] = "myanmar",
    ["nand"] = "nandinagari",
    ["narb"] = "old north arabian",
    ["nbat"] = "nabataean",
    ["newa"] = "newa",
    ["nko" ] = 'n"ko',
    ["nshu"] = "nüshu",
    ["ogam"] = "ogham",
    ["olck"] = "ol chiki",
    ["orkh"] = "old turkic and orkhon runic",
    ["ory2"] = "odia variant 2",
    ["orya"] = "odia",
    ["osge"] = "osage",
    ["osma"] = "osmanya",
    ["ougr"] = "old uyghur",
    ["palm"] = "palmyrene",
    ["pauc"] = "pau cin hau",
    ["perm"] = "old permic",
    ["phag"] = "phags-pa",
    ["phli"] = "inscriptional pahlavi",
    ["phlp"] = "psalter pahlavi",
    ["phnx"] = "phoenician",
    ["plrd"] = "miao",
    ["prti"] = "inscriptional parthian",
    ["rjng"] = "rejang",
    ["rohg"] = "hanifi rohingya",
    ["runr"] = "runic",
    ["samr"] = "samaritan",
    ["sarb"] = "old south arabian",
    ["saur"] = "saurashtra",
    ["sgnw"] = "sign writing",
    ["shaw"] = "shavian",
    ["shrd"] = "sharada",
    ["sidd"] = "siddham",
    ["sind"] = "khudawadi",
    ["sinh"] = "sinhala",
    ["sogd"] = "sogdian",
    ["sogo"] = "old sogdian",
    ["sora"] = "sora sompeng",
    ["soyo"] = "soyombo",
    ["sund"] = "sundanese",
    ["sylo"] = "syloti nagri",
    ["syrc"] = "syriac",
    ["tagb"] = "tagbanwa",
    ["takr"] = "takri",
    ["tale"] = "tai le",
    ["talu"] = "new tai lue",
    ["taml"] = "tamil",
    ["tang"] = "tangut",
    ["tavt"] = "tai viet",
    ["tel2"] = "telugu variant 2",
    ["telu"] = "telugu",
    ["tfng"] = "tifinagh",
    ["tglg"] = "tagalog",
    ["thaa"] = "thaana",
    ["thai"] = "thai",
    ["tibt"] = "tibetan",
    ["tirh"] = "tirhuta",
    ["tnsa"] = "tangsa",
    ["tml2"] = "tamil variant 2",
    ["toto"] = "toto",
    ["ugar"] = "ugaritic cuneiform",
    ["vai" ] = "vai",
    ["wara"] = "warang citi",
    ["wcho"] = "wancho",
    ["xpeo"] = "old persian cuneiform",
    ["xsux"] = "sumero-akkadian cuneiform",
    ["yezi"] = "yezidi",
    ["yi"  ] = "yi",
    ["zanb"] = "zanabazar square",
}

local languages = allocate {
    ["aba" ] = "abaza",
    ["abk" ] = "abkhazian",
    ["ach" ] = "acholi",
    ["acr" ] = "achi",
    ["ady" ] = "adyghe",
    ["afk" ] = "afrikaans",
    ["afr" ] = "afar",
    ["agw" ] = "agaw",
    ["aio" ] = "aiton",
    ["aka" ] = "akan",
    ["akb" ] = "batak angkola",
    ["als" ] = "alsatian",
    ["alt" ] = "altai",
    ["amh" ] = "amharic",
    ["ang" ] = "anglo-saxon",
    ["apph"] = "phonetic transcription—americanist conventions",
    ["ara" ] = "arabic",
    ["arg" ] = "aragonese",
    ["ari" ] = "aari",
    ["ark" ] = "rakhine",
    ["asm" ] = "assamese",
    ["ast" ] = "asturian",
    ["ath" ] = "athapaskan",
    ["avn" ] = "avatime",
    ["avr" ] = "avar",
    ["awa" ] = "awadhi",
    ["aym" ] = "aymara",
    ["azb" ] = "torki",
    ["aze" ] = "azerbaijani",
    ["bad" ] = "badaga",
    ["bad0"] = "banda",
    ["bag" ] = "baghelkhandi",
    ["bal" ] = "balkar",
    ["ban" ] = "balinese",
    ["bar" ] = "bavarian",
    ["bau" ] = "baulé",
    ["bbc" ] = "batak toba",
    ["bbr" ] = "berber",
    ["bch" ] = "bench",
    ["bcr" ] = "bible cree",
    ["bdy" ] = "bandjalang",
    ["bel" ] = "belarussian",
    ["bem" ] = "bemba",
    ["ben" ] = "bengali",
    ["bgc" ] = "haryanvi",
    ["bgq" ] = "bagri",
    ["bgr" ] = "bulgarian",
    ["bhi" ] = "bhili",
    ["bho" ] = "bhojpuri",
    ["bik" ] = "bikol",
    ["bil" ] = "bilen",
    ["bis" ] = "bislama",
    ["bjj" ] = "kanauji",
    ["bkf" ] = "blackfoot",
    ["bli" ] = "baluchi",
    ["blk" ] = "pa'o karen",
    ["bln" ] = "balante",
    ["blt" ] = "balti",
    ["bmb" ] = "bambara (bamanankan)",
    ["bml" ] = "bamileke",
    ["bos" ] = "bosnian",
    ["bpy" ] = "bishnupriya manipuri",
    ["bre" ] = "breton",
    ["brh" ] = "brahui",
    ["bri" ] = "braj bhasha",
    ["brm" ] = "burmese",
    ["brx" ] = "bodo",
    ["bsh" ] = "bashkir",
    ["bsk" ] = "burushaski",
    ["bta" ] = "batak alas kluet",
    ["btd" ] = "batak dairi (pakpak)",
    ["bti" ] = "beti",
    ["btm" ] = "batak mandailing",
    ["bts" ] = "batak simalungun",
    ["btx" ] = "batak karo",
    ["bug" ] = "bugis",
    ["byv" ] = "medumba",
    ["cak" ] = "kaqchikel",
    ["cat" ] = "catalan",
    ["cbk" ] = "zamboanga chavacano",
    ["cchn"] = "chinantec",
    ["ceb" ] = "cebuano",
    ["cgg" ] = "chiga",
    ["cha" ] = "chamorro",
    ["che" ] = "chechen",
    ["chg" ] = "chaha gurage",
    ["chh" ] = "chattisgarhi",
    ["chi" ] = "chichewa (chewa, nyanja)",
    ["chk" ] = "chukchi",
    ["chk0"] = "chuukese",
    ["cho" ] = "choctaw",
    ["chp" ] = "chipewyan",
    ["chr" ] = "cherokee",
    ["chu" ] = "chuvash",
    ["chy" ] = "cheyenne",
    ["cja" ] = "western cham",
    ["cjm" ] = "eastern cham",
    ["cmr" ] = "comorian",
    ["cop" ] = "coptic",
    ["cor" ] = "cornish",
    ["cos" ] = "corsican",
    ["cpp" ] = "creoles",
    ["cre" ] = "cree",
    ["crr" ] = "carrier",
    ["crt" ] = "crimean tatar",
    ["csb" ] = "kashubian",
    ["csl" ] = "church slavonic",
    ["csy" ] = "czech",
    ["ctg" ] = "chittagonian",
    ["ctt" ] = "wayanad chetti",
    ["cuk" ] = "san blas kuna",
    ["dag" ] = "dagbani",
    ["dan" ] = "danish",
    ["dar" ] = "dargwa",
    ["dax" ] = "dayi",
    ["dcr" ] = "woods cree",
    ["deu" ] = "german",
    ["dgo" ] = "dogri (individual language)",
    ["dgr" ] = "dogri (macro language)",
    ["dhg" ] = "dhangu",
    ["dhv" ] = "divehi (dhivehi, maldivian)",
    ["diq" ] = "dimli",
    ["div" ] = "divehi (dhivehi, maldivian)",
    ["djr" ] = "zarma",
    ["djr0"] = "djambarrpuyngu",
    ["dng" ] = "dangme",
    ["dnj" ] = "dan",
    ["dnk" ] = "dinka",
    ["dri" ] = "dari",
    ["duj" ] = "dhuwal",
    ["dun" ] = "dungan",
    ["dzn" ] = "dzongkha",
    ["ebi" ] = "ebira",
    ["ecr" ] = "eastern cree",
    ["edo" ] = "edo",
    ["efi" ] = "efik",
    ["ell" ] = "greek",
    ["emk" ] = "eastern maninkakan",
    ["eng" ] = "english",
    ["erz" ] = "erzya",
    ["esp" ] = "spanish",
    ["esu" ] = "central yupik",
    ["eti" ] = "estonian",
    ["euq" ] = "basque",
    ["evk" ] = "evenki",
    ["evn" ] = "even",
    ["ewe" ] = "ewe",
    ["fan" ] = "french antillean",
    ["fan0"] = " fang",
    ["far" ] = "persian",
    ["fat" ] = "fanti",
    ["fin" ] = "finnish",
    ["fji" ] = "fijian",
    ["fle" ] = "dutch (flemish)",
    ["fmp" ] = "fe’fe’",
    ["fne" ] = "forest nenets",
    ["fon" ] = "fon",
    ["fos" ] = "faroese",
    ["fra" ] = "french",
    ["frc" ] = "cajun french",
    ["fri" ] = "frisian",
    ["frl" ] = "friulian",
    ["frp" ] = "arpitan",
    ["fta" ] = "futa",
    ["ful" ] = "fulah",
    ["fuv" ] = "nigerian fulfulde",
    ["gad" ] = "ga",
    ["gae" ] = "scottish gaelic (gaelic)",
    ["gag" ] = "gagauz",
    ["gal" ] = "galician",
    ["gar" ] = "garshuni",
    ["gaw" ] = "garhwali",
    ["gez" ] = "ge'ez",
    ["gih" ] = "githabul",
    ["gil" ] = "gilyak",
    ["gil0"] = "kiribati (gilbertese)",
    ["gkp" ] = "kpelle (guinea)",
    ["glk" ] = "gilaki",
    ["gmz" ] = "gumuz",
    ["gnn" ] = "gumatj",
    ["gog" ] = "gogo",
    ["gon" ] = "gondi",
    ["grn" ] = "greenlandic",
    ["gro" ] = "garo",
    ["gua" ] = "guarani",
    ["guc" ] = "wayuu",
    ["guf" ] = "gupapuyngu",
    ["guj" ] = "gujarati",
    ["guz" ] = "gusii",
    ["hai" ] = "haitian (haitian creole)",
    ["hai0"] = "haida",
    ["hal" ] = "halam",
    ["har" ] = "harauti",
    ["hau" ] = "hausa",
    ["haw" ] = "hawaiian",
    ["hay" ] = "haya",
    ["haz" ] = "hazaragi",
    ["hmz" ] = "hmong shuat",
    ["hbn" ] = "hammer-banna",
    ["hei" ] = "heiltsuk",
    ["her" ] = "herero",
    ["hil" ] = "hiligaynon",
    ["hin" ] = "hindi",
    ["hma" ] = "high mari",
    ["hmn" ] = "hmong",
    ["hmo" ] = "hiri motu",
    ["hnd" ] = "hindko",
    ["ho"  ] = "ho",
    ["hri" ] = "harari",
    ["hrv" ] = "croatian",
    ["hun" ] = "hungarian",
    ["hye" ] = "armenian",
    ["hye0"] = "armenian east",
    ["iba" ] = "iban",
    ["ibb" ] = "ibibio",
    ["ibo" ] = "igbo",
    ["ido" ] = "ido",
    ["ijo" ] = "ijo languages",
    ["ile" ] = "interlingue",
    ["ilo" ] = "ilokano",
    ["ina" ] = "interlingua",
    ["ind" ] = "indonesian",
    ["ing" ] = "ingush",
    ["inu" ] = "inuktitut",
    ["inuk"] = "nunavik inuktitut",
    ["ipk" ] = "inupiat",
    ["ipph"] = "phonetic transcription—ipa conventions",
    ["iri" ] = "irish",
    ["irt" ] = "irish traditional",
    ["uri" ] = "irula",
    ["isl" ] = "icelandic",
    ["ism" ] = "inari sami",
    ["ita" ] = "italian",
    ["iwr" ] = "hebrew",
    ["jam" ] = "jamaican creole",
    ["jan" ] = "japanese",
    ["jav" ] = "javanese",
    ["jbo" ] = "lojban",
    ["jct" ] = "krymchak",
    ["jii" ] = "yiddish",
    ["jud" ] = "ladino",
    ["jul" ] = "jula",
    ["kab" ] = "kabardian",
    ["kab0"] = "kabyle",
    ["kac" ] = "kachchi",
    ["kal" ] = "kalenjin",
    ["kan" ] = "kannada",
    ["kar" ] = "karachay",
    ["kat" ] = "georgian",
    ["kaw" ] = "kawi (old javanese)",
    ["kaz" ] = "kazakh",
    ["kde" ] = "makonde",
    ["kea" ] = "kabuverdianu (crioulo)",
    ["keb" ] = "kebena",
    ["kek" ] = "kekchi",
    ["kge" ] = "khutsuri georgian",
    ["kha" ] = "khakass",
    ["khk" ] = "khanty-kazim",
    ["khm" ] = "khmer",
    ["khs" ] = "khanty-shurishkar",
    ["kht" ] = "khamti shan",
    ["khv" ] = "khanty-vakhi",
    ["khw" ] = "khowar",
    ["kik" ] = "kikuyu (gikuyu)",
    ["kir" ] = "kirghiz (kyrgyz)",
    ["kis" ] = "kisii",
    ["kiu" ] = "kirmanjki",
    ["kjd" ] = "southern kiwai",
    ["kjp" ] = "eastern pwo karen",
    ["kjz" ] = "bumthangkha",
    ["kkn" ] = "kokni",
    ["klm" ] = "kalmyk",
    ["kmb" ] = "kamba",
    ["kmn" ] = "kumaoni",
    ["kmo" ] = "komo",
    ["kms" ] = "komso",
    ["kmz" ] = "khorasani turkic",
    ["knr" ] = "kanuri",
    ["kod" ] = "kodagu",
    ["koh" ] = "korean old hangul",
    ["kok" ] = "konkani",
    ["kom" ] = "komi",
    ["kon" ] = "kikongo",
    ["kon0"] = "kongo",
    ["kop" ] = "komi-permyak",
    ["kor" ] = "korean",
    ["kos" ] = "kosraean",
    ["koz" ] = "komi-zyrian",
    ["kpl" ] = "kpelle",
    ["kri" ] = "krio",
    ["krk" ] = "karakalpak",
    ["krl" ] = "karelian",
    ["krm" ] = "karaim",
    ["krn" ] = "karen",
    ["krt" ] = "koorete",
    ["ksh" ] = "kashmiri",
    ["ksh0"] = "ripuarian",
    ["ksi" ] = "khasi",
    ["ksm" ] = "kildin sami",
    ["ksw" ] = "s’gaw karen",
    ["kua" ] = "kuanyama",
    ["kui" ] = "kui",
    ["kul" ] = "kulvi",
    ["kum" ] = "kumyk",
    ["kur" ] = "kurdish",
    ["kuu" ] = "kurukh",
    ["kuy" ] = "kuy",
    ["kwk" ] = "kwakʼwala",
    ["kyk" ] = "koryak",
    ["kyu" ] = "western kayah",
    ["lad" ] = "ladin",
    ["lah" ] = "lahuli",
    ["lak" ] = "lak",
    ["lam" ] = "lambani",
    ["lao" ] = "lao",
    ["lat" ] = "latin",
    ["laz" ] = "laz",
    ["lcr" ] = "l-cree",
    ["ldk" ] = "ladakhi",
    ["lef" ] = "lelemi",
    ["lez" ] = "lezgi",
    ["lij" ] = "ligurian",
    ["lim" ] = "limburgish",
    ["lin" ] = "lingala",
    ["lis" ] = "lisu",
    ["ljp" ] = "lampung",
    ["lki" ] = "laki",
    ["lma" ] = "low mari",
    ["lmb" ] = "limbu",
    ["lmo" ] = "lombard",
    ["lmw" ] = "lomwe",
    ["lom" ] = "loma",
    ["lpo" ] = "lipo",
    ["lrc" ] = "luri",
    ["lsb" ] = "lower sorbian",
    ["lsm" ] = "lule sami",
    ["lth" ] = "lithuanian",
    ["ltz" ] = "luxembourgish",
    ["lua" ] = "luba-lulua",
    ["lub" ] = "luba-katanga",
    ["lug" ] = "ganda",
    ["luh" ] = "luyia",
    ["luo" ] = "luo",
    ["lvi" ] = "latvian",
    ["mad" ] = "madura",
    ["mag" ] = "magahi",
    ["mah" ] = "marshallese",
    ["maj" ] = "majang",
    ["mak" ] = "makhuwa",
    ["mal" ] = "malayalam",
    ["mam" ] = "mam",
    ["man" ] = "mansi",
    ["map" ] = "mapudungun",
    ["mar" ] = "marathi",
    ["maw" ] = "marwari",
    ["mbn" ] = "mbundu",
    ["mbo" ] = "mbo",
    ["mch" ] = "manchu",
    ["mcr" ] = "moose cree",
    ["mde" ] = "mende",
    ["mdr" ] = "mandar",
    ["men" ] = "me'en",
    ["mer" ] = "meru",
    ["mfa" ] = "pattani malay",
    ["mfe" ] = "morisyen",
    ["min" ] = "minangkabau",
    ["miz" ] = "mizo",
    ["mkd" ] = "macedonian",
    ["mkr" ] = "makasar",
    ["mkw" ] = "kituba",
    ["mle" ] = "male",
    ["mlg" ] = "malagasy",
    ["mln" ] = "malinke",
    ["mlr" ] = "malayalam reformed",
    ["mly" ] = "malay",
    ["mnd" ] = "mandinka",
    ["mng" ] = "mongolian",
    ["mni" ] = "manipuri",
    ["mnk" ] = "maninka",
    ["mnx" ] = "manx",
    ["moh" ] = "mohawk",
    ["mok" ] = "moksha",
    ["mol" ] = "moldavian",
    ["mon" ] = "mon",
    ["mnw" ] = "thailand mon",
    ["mor" ] = "moroccan",
    ["mos" ] = "mossi",
    ["mri" ] = "maori",
    ["mth" ] = "maithili",
    ["mts" ] = "maltese",
    ["mun" ] = "mundari",
    ["mus" ] = "muscogee",
    ["mwl" ] = "mirandese",
    ["mww" ] = "hmong daw",
    ["myn" ] = "mayan",
    ["mzn" ] = "mazanderani",
    ["nag" ] = "naga-assamese",
    ["nah" ] = "nahuatl",
    ["nan" ] = "nanai",
    ["nap" ] = "neapolitan",
    ["nas" ] = "naskapi",
    ["nau" ] = "nauruan",
    ["nav" ] = "navajo",
    ["ncr" ] = "n-cree",
    ["ndb" ] = "ndebele",
    ["ndc" ] = "ndau",
    ["ndg" ] = "ndonga",
    ["nds" ] = "low saxon",
    ["nep" ] = "nepali",
    ["new" ] = "newari",
    ["nga" ] = "ngbaka",
    ["ngr" ] = "nagari",
    ["nhc" ] = "norway house cree",
    ["nis" ] = "nisi",
    ["niu" ] = "niuean",
    ["nkl" ] = "nyankole",
    ["nko" ] = "n'ko",
    ["nld" ] = "dutch",
    ["noe" ] = "nimadi",
    ["nog" ] = "nogai",
    ["nor" ] = "norwegian",
    ["nov" ] = "novial",
    ["nsm" ] = "northern sami",
    ["nso" ] = "northern sotho",
    ["nta" ] = "northern tai",
    ["nto" ] = "esperanto",
    ["nym" ] = "nyamwezi",
    ["nyn" ] = "norwegian nynorsk",
    ["nza" ] = "mbembe tigon",
    ["oci" ] = "occitan",
    ["ocr" ] = "oji-cree",
    ["ojb" ] = "ojibway",
    ["ori" ] = "odia",
    ["oro" ] = "oromo",
    ["oss" ] = "ossetian",
    ["paa" ] = "palestinian aramaic",
    ["pag" ] = "pangasinan",
    ["pal" ] = "pali",
    ["pam" ] = "pampangan",
    ["pan" ] = "punjabi",
    ["pap" ] = "palpa",
    ["pap0"] = "papiamentu",
    ["pas" ] = "pashto",
    ["pau" ] = "palauan",
    ["pcc" ] = "bouyei",
    ["pcd" ] = "picard",
    ["pdc" ] = "pennsylvania german",
    ["pgr" ] = "polytonic greek",
    ["phk" ] = "phake",
    ["pih" ] = "norfolk",
    ["pil" ] = "filipino",
    ["plg" ] = "palaung",
    ["plk" ] = "polish",
    ["pms" ] = "piemontese",
    ["pnb" ] = "western panjabi",
    ["poh" ] = "pocomchi",
    ["pon" ] = "pohnpeian",
    ["pro" ] = "provencal",
    ["ptg" ] = "portuguese",
    ["pwo" ] = "western pwo karen",
    ["qin" ] = "chin",
    ["quc" ] = "k’iche’",
    ["quh" ] = "quechua (bolivia)",
    ["quz" ] = "quechua",
    ["qvi" ] = "quechua (ecuador)",
    ["qwh" ] = "quechua (peru)",
    ["raj" ] = "rajasthani",
    ["rar" ] = "rarotongan",
    ["rbu" ] = "russian buriat",
    ["rcr" ] = "r-cree",
    ["rej" ] = "rejang",
    ["rhg" ] = "rohingya",
    ["ria" ] = "riang",
    ["rif" ] = "tarifit",
    ["rit" ] = "ritarungo",
    ["rkw" ] = "arakwal",
    ["rms" ] = "romansh",
    ["rmy" ] = "vlax romani",
    ["rom" ] = "romanian",
    ["roy" ] = "romany",
    ["rsy" ] = "rusyn",
    ["rtm" ] = "rotuman",
    ["rua" ] = "kinyarwanda",
    ["run" ] = "rundi",
    ["rup" ] = "aromanian",
    ["rus" ] = "russian",
    ["sad" ] = "sadri",
    ["san" ] = "sanskrit",
    ["sas" ] = "sasak",
    ["sat" ] = "santali",
    ["say" ] = "sayisi",
    ["scn" ] = "sicilian",
    ["sco" ] = "scots",
    ["scs" ] = "north slavey",
    ["sek" ] = "sekota",
    ["sel" ] = "selkup",
    ["sfm" ] = "small flowery miao",
    ["sga" ] = "old irish",
    ["sgo" ] = "sango",
    ["sgs" ] = "samogitian",
    ["shi" ] = "tachelhit",
    ["shn" ] = "shan",
    ["sib" ] = "sibe",
    ["sid" ] = "sidamo",
    ["sig" ] = "silte gurage",
    ["sks" ] = "skolt sami",
    ["sky" ] = "slovak",
    ["sla" ] = "slavey",
    ["slv" ] = "slovenian",
    ["sml" ] = "somali",
    ["smo" ] = "samoan",
    ["sna" ] = "sena",
    ["sna0"] = "shona",
    ["snd" ] = "sindhi",
    ["snh" ] = "sinhala (sinhalese)",
    ["snk" ] = "soninke",
    ["sog" ] = "sodo gurage",
    ["sop" ] = "songe",
    ["sot" ] = "southern sotho",
    ["sqi" ] = "albanian",
    ["srb" ] = "serbian",
    ["srd" ] = "sardinian",
    ["srk" ] = "saraiki",
    ["srr" ] = "serer",
    ["ssl" ] = "south slavey",
    ["ssm" ] = "southern sami",
    ["stq" ] = "saterland frisian",
    ["suk" ] = "sukuma",
    ["sun" ] = "sundanese",
    ["sur" ] = "suri",
    ["sva" ] = "svan",
    ["sve" ] = "swedish",
    ["swa" ] = "swadaya aramaic",
    ["swk" ] = "swahili",
    ["swz" ] = "swati",
    ["sxt" ] = "sutu",
    ["sxu" ] = "upper saxon",
    ["syl" ] = "sylheti",
    ["syr" ] = "syriac",
    ["syre"] = "estrangela syriac",
    ["syrj"] = "western syriac",
    ["syrn"] = "eastern syriac",
    ["szl" ] = "silesian",
    ["tab" ] = "tabasaran",
    ["taj" ] = "tajiki",
    ["tam" ] = "tamil",
    ["tat" ] = "tatar",
    ["tcr" ] = "th-cree",
    ["tdd" ] = "dehong dai",
    ["tel" ] = "telugu",
    ["tet" ] = "tetum",
    ["tgl" ] = "tagalog",
    ["tgn" ] = "tongan",
    ["tgr" ] = "tigre",
    ["tgy" ] = "tigrinya",
    ["tha" ] = "thai",
    ["tht" ] = "tahitian",
    ["tib" ] = "tibetan",
    ["tiv" ] = "tiv",
    ["tj;" ] = "tai laing",
    ["tkm" ] = "turkmen",
    ["tli" ] = "tlingit",
    ["tmh" ] = "tamashek",
    ["tmn" ] = "temne",
    ["tna" ] = "tswana",
    ["tne" ] = "tundra nenets",
    ["tng" ] = "tonga",
    ["tod" ] = "todo",
    ["tod0"] = "toma",
    ["tpi" ] = "tok pisin",
    ["trk" ] = "turkish",
    ["tsg" ] = "tsonga",
    ["tsj" ] = "tshangla",
    ["tua" ] = "turoyo aramaic",
    ["tul" ] = "tulu",
    ["tum" ] = "tumbuka",
    ["tuv" ] = "tuvin",
    ["tvl" ] = "tuvalu",
    ["twi" ] = "twi",
    ["tyz" ] = "tày",
    ["tzm" ] = "tamazight",
    ["tzo" ] = "tzotzil",
    ["udm" ] = "udmurt",
    ["ukr" ] = "ukrainian",
    ["umb" ] = "umbundu",
    ["urd" ] = "urdu",
    ["usb" ] = "upper sorbian",
    ["uyg" ] = "uyghur",
    ["uzb" ] = "uzbek",
    ["vec" ] = "venetian",
    ["ven" ] = "venda",
    ["vit" ] = "vietnamese",
    ["vol" ] = "volapük",
    ["vro" ] = "võro",
    ["wa"  ] = "wa",
    ["wag" ] = "wagdi",
    ["war" ] = "waray-waray",
    ["wci" ] = "waci gbe",
    ["wcr" ] = "west-cree",
    ["wel" ] = "welsh",
    ["wlf" ] = "wolof",
    ["wln" ] = "walloon",
    ["wtm" ] = "mewati",
    ["xbd" ] = "lü",
    ["xhs" ] = "xhosa",
    ["xjb" ] = "minjangbal",
    ["xkf" ] = "khengkha",
    ["xog" ] = "soga",
    ["xpe" ] = "kpelle (liberia)",
    ["xub" ] = "bette kuruma",
    ["xuj" ] = "jennu kuruma",
    ["yak" ] = "sakha",
    ["yao" ] = "yao",
    ["yap" ] = "yapese",
    ["yba" ] = "yoruba",
    ["ycr" ] = "y-cree",
    ["ygp" ] = "gepo",
    ["yic" ] = "yi classic",
    ["yim" ] = "yi modern",
    ["yna" ] = "aluo",
    ["ywq" ] = "wuding-luquan",
    ["zea" ] = "zealandic",
    ["zgh" ] = "standard morrocan tamazigh",
    ["zha" ] = "zhuang",
    ["zhh" ] = "chinese, hong kong sar",
    ["zho" ] = "chinese traditional, macao",
    ["zhp" ] = "chinese phonetic",
    ["zhs" ] = "chinese simplified",
    ["zht" ] = "chinese traditional",
    ["znd" ] = "zande",
    ["zul" ] = "zulu",
    ["zza" ] = "zazaki",
}

local features = allocate {
    ["aalt"] = "access all alternates",
    ["abvf"] = "above-base forms",
    ["abvm"] = "above-base mark positioning",
    ["abvs"] = "above-base substitutions",
    ["afrc"] = "alternative fractions",
    ["akhn"] = "akhands",
    ["blwf"] = "below-base forms",
    ["blwm"] = "below-base mark positioning",
    ["blws"] = "below-base substitutions",
    ["c2pc"] = "petite capitals from capitals",
    ["c2sc"] = "small capitals from capitals",
    ["calt"] = "contextual alternates",
    ["case"] = "case-sensitive forms",
    ["ccmp"] = "glyph composition/decomposition",
    ["cfar"] = "conjunct form after ro",
    ["chws"] = "contextual half-width spacing",
    ["cjct"] = "conjunct forms",
    ["clig"] = "contextual ligatures",
    ["cpct"] = "centered cjk punctuation",
    ["cpsp"] = "capital spacing",
    ["cswh"] = "contextual swash",
    ["curs"] = "cursive positioning",
    ["dflt"] = "default processing",
    ["dist"] = "distances",
    ["dlig"] = "discretionary ligatures",
    ["dnom"] = "denominators",
    ["dtls"] = "dotless forms",                    -- math
    ["expt"] = "expert forms",
    ["falt"] = "final glyph alternates",
    ["fin2"] = "terminal forms #2",
    ["fin3"] = "terminal forms #3",
    ["fina"] = "terminal forms",
    ["flac"] = "flattened accents over capitals",  -- math
    ["frac"] = "fractions",
    ["fwid"] = "full width",
    ["half"] = "half forms",
    ["haln"] = "halant forms",
    ["halt"] = "alternate half width",
    ["hist"] = "historical forms",
    ["hkna"] = "horizontal kana alternates",
    ["hlig"] = "historical ligatures",
    ["hngl"] = "hangul",                           -- depricated
    ["hojo"] = "hojo kanji forms",
    ["hwid"] = "half width",
    ["init"] = "initial forms",
    ["isol"] = "isolated forms",
    ["ital"] = "italics",
    ["jalt"] = "justification alternatives",
    ["jp04"] = "jis2004 forms",
    ["jp78"] = "jis78 forms",
    ["jp83"] = "jis83 forms",
    ["jp90"] = "jis90 forms",
    ["kern"] = "kerning",
    ["lfbd"] = "left bounds",
    ["liga"] = "standard ligatures",
    ["ljmo"] = "leading jamo forms",
    ["lnum"] = "lining figures",
    ["locl"] = "localized forms",
    ["ltra"] = "left-to-right alternates",
    ["ltrm"] = "left-to-right mirrored forms",
    ["mark"] = "mark positioning",
    ["med2"] = "medial forms #2",
    ["medi"] = "medial forms",
    ["mgrk"] = "mathematical greek",
    ["mkmk"] = "mark to mark positioning",
    ["mset"] = "mark positioning via substitution",
    ["nalt"] = "alternate annotation forms",
    ["nlck"] = "nlc kanji forms",
    ["nukt"] = "nukta forms",
    ["numr"] = "numerators",
    ["onum"] = "old style figures",
    ["opbd"] = "optical bounds", -- funny, this is obsolete (too hard?) (and was recomended always true)
    ["ordn"] = "ordinals",
    ["ornm"] = "ornaments",
    ["palt"] = "proportional alternate width",
    ["pcap"] = "petite capitals",
    ["pkna"] = "proportional kana",
    ["pnum"] = "proportional figures",
    ["pref"] = "pre-base forms",
    ["pres"] = "pre-base substitutions",
    ["pstf"] = "post-base forms",
    ["psts"] = "post-base substitutions",
    ["pwid"] = "proportional widths",
    ["qwid"] = "quarter widths",
    ["rand"] = "randomize",
    ["rclt"] = "required contextual alternates",
    ["rkrf"] = "rakar forms",
    ["rlig"] = "required ligatures",
    ["rphf"] = "reph form",
    ["rtbd"] = "right bounds",
    ["rtla"] = "right-to-left alternates",
    ["rtlm"] = "right to left mirrored forms",
    ["ruby"] = "ruby notation forms",
    ["rvrn"] = "required variation alternates",
    ["salt"] = "stylistic alternates",
    ["sinf"] = "scientific inferiors",
    ["size"] = "optical size", -- now stat table
    ["smcp"] = "small capitals",
    ["smpl"] = "simplified forms",
 -- ["ss01"] = "stylistic set 1",
 -- ["ss02"] = "stylistic set 2",
 -- ["ss03"] = "stylistic set 3",
 -- ["ss04"] = "stylistic set 4",
 -- ["ss05"] = "stylistic set 5",
 -- ["ss06"] = "stylistic set 6",
 -- ["ss07"] = "stylistic set 7",
 -- ["ss08"] = "stylistic set 8",
 -- ["ss09"] = "stylistic set 9",
 -- ["ss10"] = "stylistic set 10",
 -- ["ss11"] = "stylistic set 11",
 -- ["ss12"] = "stylistic set 12",
 -- ["ss13"] = "stylistic set 13",
 -- ["ss14"] = "stylistic set 14",
 -- ["ss15"] = "stylistic set 15",
 -- ["ss16"] = "stylistic set 16",
 -- ["ss17"] = "stylistic set 17",
 -- ["ss18"] = "stylistic set 18",
 -- ["ss19"] = "stylistic set 19",
 -- ["ss20"] = "stylistic set 20",
    ["ssty"] = "script style", -- math
    ["stch"] = "stretching glyph decomposition",
    ["subs"] = "subscript",
    ["sups"] = "superscript",
    ["swsh"] = "swash",
    ["titl"] = "titling",
    ["tjmo"] = "trailing jamo forms",
    ["tnam"] = "traditional name forms",
    ["tnum"] = "tabular figures",
    ["trad"] = "traditional forms",
    ["twid"] = "third widths",
    ["unic"] = "unicase",
    ["valt"] = "alternate vertical metrics",
    ["vatu"] = "vattu variants",
    ["vchw"] = "vertical contextual half-width spacing",
    ["vert"] = "vertical writing",
    ["vhal"] = "alternate vertical half metrics",
    ["vjmo"] = "vowel jamo forms",
    ["vkna"] = "vertical kana alternates",
    ["vkrn"] = "vertical kerning",
    ["vpal"] = "proportional alternate vertical metrics",
    ["vrtr"] = "vertical alternates for rotation",
    ["vrt2"] = "vertical rotation",
    ["zero"] = "slashed zero",

    ["trep"] = "traditional tex replacements",
    ["tlig"] = "traditional tex ligatures",

    ["ss.."] = "stylistic set ..",
    ["cv.."] = "character variant ..",
    ["js.."] = "justification ..",

    ["dv.."] = "devanagari ..", -- for internal use
    ["ml.."] = "malayalam ..",  -- for internal use

}

local baselines = allocate {
    ["hang"] = "hanging baseline",
    ["icfb"] = "ideographic character face bottom edge baseline",
    ["icft"] = "ideographic character face tope edige baseline",
    ["ideo"] = "ideographic em-box bottom edge baseline",
    ["idtp"] = "ideographic em-box top edge baseline",
    ["math"] = "mathematical centered baseline",
    ["romn"] = "roman baseline"
}

tables.scripts   = scripts
tables.languages = languages
tables.features  = features
tables.baselines = baselines

local acceptscripts   = true  directives.register("otf.acceptscripts",   function(v) acceptscripts   = v end)
local acceptlanguages = true  directives.register("otf.acceptlanguages", function(v) acceptlanguages = v end)

local report_checks   = logs.reporter("fonts","checks")

-- hm, we overload the metatables

if otffeatures.features then
    for k, v in next, otffeatures.features do
        features[k] = v
    end
    otffeatures.features = features
end

local function swapped(h)
    local r = { }
    for k, v in next, h do
        r[gsub(v,"[^a-z0-9]","")] = k -- is already lower
    end
    return r
end

local verbosescripts   = allocate(swapped(scripts  ))
local verboselanguages = allocate(swapped(languages))
local verbosefeatures  = allocate(swapped(features ))
local verbosebaselines = allocate(swapped(baselines))

-- lets forget about trailing spaces

local function resolve(t,k)
    if k then
        k = gsub(lower(k),"[^a-z0-9]","")
        local v = rawget(t,k)
        if v then
            return v
        end
    end
end

setmetatableindex(verbosescripts,   resolve)
setmetatableindex(verboselanguages, resolve)
setmetatableindex(verbosefeatures,  resolve)
setmetatableindex(verbosebaselines, resolve)

-- We could optimize the next lookups by using an extra metatable and storing
-- already found values but in practice there are not that many lookups so
-- it's never a bottleneck.

setmetatableindex(scripts, function(t,k)
    if k then
        k = lower(k)
        if k == "dflt" then
            return k
        end
        local v = rawget(t,k)
        if v then
            return v
        end
        k = gsub(k," ","")
        v = rawget(t,v)
        if v then
            return v
        elseif acceptscripts then
            report_checks("registering extra script %a",k)
            rawset(t,k,k)
            return k
        end
    end
    return "dflt"
end)

setmetatableindex(languages, function(t,k)
    if k then
        k = lower(k)
        if k == "dflt" then
            return k
        end
        local v = rawget(t,k)
        if v then
            return v
        end
        k = gsub(k," ","")
        v = rawget(t,v)
        if v then
            return v
        elseif acceptlanguages then
            report_checks("registering extra language %a",k)
            rawset(t,k,k)
            return k
        end
    end
    return "dflt"
end)

if setmetatablenewindex then

    setmetatablenewindex(languages, "ignore")
    setmetatablenewindex(scripts,   "ignore")
    setmetatablenewindex(baselines, "ignore")

end

local function resolve(t,k)
    if k then
        k = lower(k)
        local v = rawget(t,k)
        if v then
            return v
        end
        k = gsub(k," ","")
        local v = rawget(t,k)
        if v then
            return v
        end
        local tag, dd = match(k,"(..)(%d+)")
        if tag and dd then
            local v = rawget(t,tag)
            if v then
                return v -- return format(v,tonumber(dd)) -- old way
            else
                local v = rawget(t,tag.."..") -- nicer in overview
                if v then
                    return (gsub(v,"%.%.",tonumber(dd))) -- new way
                end
            end
        end
    end
    return k -- "dflt"
end

setmetatableindex(features, resolve)

local function assign(t,k,v)
    if k and v then
        v = lower(v)
        rawset(t,k,v) -- rawset ?
     -- rawset(features,gsub(v,"[^a-z0-9]",""),k) -- why ? old code
    end
end

if setmetatablenewindex then

    setmetatablenewindex(features, assign)

end

local checkers = {
    rand = function(v)
        return v == true and "random" or v
    end
}

if not storage then
    return
end

local usedfeatures      = statistics.usedfeatures or { }
statistics.usedfeatures = usedfeatures

table.setmetatableindex(usedfeatures, function(t,k) if k then local v = { } t[k] = v return v end end) -- table.autotable

storage.register("fonts/otf/usedfeatures", usedfeatures, "fonts.handlers.otf.statistics.usedfeatures" )

local normalizedaxis = otf.readers.helpers.normalizedaxis or function(s) return s end

function otffeatures.normalize(features,wrap) -- wrap is for context
    if features then
        local h = { }
        for key, value in next, features do
            local k = lower(key)
            if k == "language" then
                local v = gsub(lower(value),"[^a-z0-9]","")
                h.language = rawget(verboselanguages,v) or (languages[v] and v) or "dflt" -- auto adds
            elseif k == "script" then
                local v = gsub(lower(value),"[^a-z0-9]","")
                h.script = rawget(verbosescripts,v) or (scripts[v] and v) or "dflt" -- auto adds
            elseif k == "axis" then
                h[k] = normalizedaxis(value)
            else
                local uk = usedfeatures[key]
                local uv = uk[value]
                if uv then
                 -- report_checks("feature value %a first seen at %a",value,key)
                else
                    uv = tonumber(value) -- before boolean as there we also handle 0/1
                    if uv then
                        -- we're okay
                    elseif type(value) == "string" then
                        local b = is_boolean(value)
                        if type(b) == "nil" then
                         -- we do this elsewhere
                         --
                         -- if find(value,"=") then
                         --     local t = { }
                         --     for k, v in gmatch(value,"([^%s,=]+)%s*=%s*([^%s,=]+)") do
                         --         t[k] = tonumber(v) or v
                         --     end
                         --     if next(t) then
                         --         value = sequenced(t,",")
                         --     end
                         -- end
                            if wrap and find(value,",") then
                                uv = "{"..lower(value).."}"
                            else
                                uv = lower(value)
                            end
                        else
                            uv = b
                        end
                    elseif type(value) == "table" then
                        uv = sequenced(t,",")
                    else
                        uv = value
                    end
                    if not rawget(features,k) then
                        k = rawget(verbosefeatures,k) or k
                    end
                    local c = checkers[k]
                    if c then
                        uv = c(uv) or vc
                    end
                    uk[value] = uv
                end
                h[k] = uv
            end
        end
        return h
    end
end
