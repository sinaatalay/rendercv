-------------------------------------------------------------------------------
--         FILE:  luaotfload-parsers.lua
--  DESCRIPTION:  various lpeg-based parsers used in Luaotfload
-- REQUIREMENTS:  Luaotfload
--       AUTHOR:  Philipp Gesang (Phg), <phg@phi-gamma.net>, Marcel Krüger
-------------------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-parsers",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / parsers",
    license       = "GPL v2.0"
}

local traversal_maxdepth  = 42 --- prevent stack overflows

local rawset            = rawset

local lpeg              = require "lpeg"
local patterns          = lpeg.patterns
local P, R, S, V        = lpeg.P, lpeg.R, lpeg.S, lpeg.V
local lpegmatch         = lpeg.match
local C, Cc, Cf         = lpeg.C, lpeg.Cc, lpeg.Cf
local Cg, Cmt, Cs, Ct   = lpeg.Cg, lpeg.Cmt, lpeg.Cs, lpeg.Ct

local kpse              = kpse
local kpseexpand_path   = kpse.expand_path
local kpsereadable_file = kpse.readable_file

local file              = file
local filejoin          = file.join
local filedirname       = file.dirname

local io                = io
local ioopen            = io.open

local logreport         = print

local string            = string
local stringsub         = string.sub
local stringfind        = string.find
local stringlower       = string.lower

local mathceil          = math.ceil

local lfs               = lfs
local lfsisfile         = lfs.isfile
local lfsisdir          = lfs.isdir

-------------------------------------------------------------------------------
---                         COMMON PATTERNS
-------------------------------------------------------------------------------

local asterisk          = P"*"
local dot               = P"."
local colon             = P":"
local semicolon         = P";"
local comma             = P","
local noncomma          = 1 - comma
local slash             = P"/"
local backslash         = P"\\"
local equals            = P"="
local dash              = P"-"
local gartenzaun        = P"#"
local lbrk, rbrk        = P"[", P"]"
local brackets          = lbrk + rbrk
local squote            = P"'"
local dquote            = P"\""

local newline           = P"\n"
local returnchar        = P"\r"
local spacing           = S" \t\v"
local linebreak         = S"\n\r"
local whitespace        = spacing + linebreak
local ws                = spacing^0
local xmlws             = whitespace^1
local eol               = P"\n\r" + P"\r\n" + linebreak

local digit             = R"09"
local alpha             = R("az", "AZ")
local anum              = alpha + digit
local decimal           = digit^1 * (dot * digit^0)^-1
local hexdigit          = R("09", "af", "AF")
local hex               = P"0x" * hexdigit^1

-------------------------------------------------------------------------------
---                                FONTCONFIG
-------------------------------------------------------------------------------

--[[doc--

  For fonts installed on the operating system, there are several
  options to make Luaotfload index them:

   - If OSFONTDIR is set (which is the case under windows by default
     but not on the other OSs), it scans it at the same time as the
     texmf tree, in the function scan_texmf_fonts().

   - Otherwise
     - under Windows and Mac OSX, we take a look at some hardcoded
       directories,
     - under Unix, it reads /etc/fonts/fonts.conf and processes the
       directories specified there.

  This means that if you have fonts in fancy directories, you need to
  set them in OSFONTDIR.

  Beware: OSFONTDIR is a kpathsea variable, so fonts found in these
  paths, though technically system fonts, are registered in the
  category “texmf”, not “system”. This may have consequences for the
  lookup order when a font file (or a font with the same name
  information) is located in both the system and the texmf tree.

--doc]]--

local tag_name          = C(alpha^1)
local comment           = P"<!--" * (1 - P"--")^0 * P"-->"

---> header specifica
local xml_declaration   = P"<?xml" * (1 - P"?>")^0 * P"?>"
local xml_doctype       = P"<!DOCTYPE" * xmlws
                        * "fontconfig" * (1 - P">")^0 * P">"
local header            = xml_declaration^-1
                        * (xml_doctype + comment + xmlws)^0

---> enforce root node
local root_start        = P"<"  * xmlws^-1 * P"fontconfig" * xmlws^-1 * P">"
local root_stop         = P"</" * xmlws^-1 * P"fontconfig" * xmlws^-1 * P">"

local dquote, squote    = P[["]], P"'"
local xml_namestartchar = S":_" + alpha --- ascii only, funk the rest
local xml_namechar      = S":._" + alpha + digit
local xml_name          = xmlws^-1
                        * C(xml_namestartchar * xml_namechar^0)
local xml_attvalue      = dquote * C((1 - S[[%&"]])^1) * dquote * xmlws^-1
                        + squote * C((1 - S[[%&']])^1) * squote * xmlws^-1
local xml_attr          = Cg(xml_name * P"=" * xml_attvalue)
local xml_attr_list     = Cf(Ct"" * xml_attr^1, rawset)

--[[doc--
      scan_node creates a parser for a given xml tag.
--doc]]--
--- string -> bool -> lpeg_t
local function scan_node (tag)
  --- Node attributes go into a table with the index “attributes”
  --- (relevant for “prefix="xdg"” and the likes).
  local p_tag = P(tag)
  local with_attributes   = P"<" * p_tag
                          * Cg(xml_attr_list, "attributes")^-1
                          * xmlws^-1
                          * P">"
  local plain             = P"<" * p_tag * xmlws^-1 * P">"
  local node_start        = plain + with_attributes
  local node_stop         = P"</" * p_tag * xmlws^-1 * P">"
  --- there is no nesting, the earth is flat ...
  local node              = node_start
                          * Cc(tag) * C(comment + (1 - node_stop)^1)
                          * node_stop
  return Ct(node) -- returns {string, string [, attributes = { key = val }] }
end

--[[doc--
      At the moment, the interesting tags are “dir” for
      directory declarations, and “include” for including
      further configuration files.

      spec: http://freedesktop.org/software/fontconfig/fontconfig-user.html
--doc]]--
local include_node        = scan_node"include"
local dir_node            = scan_node"dir"

local element             = dir_node
                          + include_node
                          + comment         --> ignore
                          + P(1-root_stop)  --> skip byte

local root                = root_start * Ct(element^0) * root_stop
local p_cheapxml          = header * root

--lpeg.print(p_cheapxml) ---> 757 rules with v0.10

--[[doc--
      fonts_conf_scanner() handles configuration files.
      It is called on an abolute path to a config file (e.g.
      /home/luser/.config/fontconfig/fonts.conf) and returns a list
      of the nodes it managed to extract from the file.
--doc]]--
--- string -> path list
local function fonts_conf_scanner (path)
  logreport("both", 5, "db", "Read fontconfig file %s.", path)
  local fh = ioopen(path, "r")
  if not fh then
    logreport("both", 3, "db", "Cannot open fontconfig file %s.", path)
    return
  end
  local raw = fh:read"*all"
  fh:close()
  logreport("both", 7, "db",
            "Reading fontconfig file %s completed (%d bytes).",
            path, #raw)

  logreport("both", 5, "db", "Scan fontconfig file %s.", path)
  local confdata = lpegmatch(p_cheapxml, raw)
  if not confdata then
    logreport("both", 3, "db", "Cannot scan fontconfig file %s.", path)
    return
  end
  logreport("both", 7, "db", "Scan of fontconfig file %s completed.", path)
  return confdata
end

local p_conf   = P".conf" * P(-1)
local p_filter = (1 - p_conf)^1 * p_conf

local function conf_filter (path)
  if lpegmatch (p_filter, path) then
    return true
  end
  return false
end

--[[doc--

      read_fonts_conf_indeed() -- Scan paths included from fontconfig
      configuration files recursively. Called with eight arguments.
      The first five are

          · the current recursion depth
          · the path to the file
          · the expanded $HOME
          · the expanded $XDG_CONFIG_HOME
          · the expanded $XDG_DATA_HOME

      determining the path to be checked. Another three arguments are
      tables that represent the state of the current job as lists of
      strings; these are always returned. Finally a reference to the
      find_files function is passed.

--doc]]--

--- size_t -> string -> string -> string -> string
---     -> string list -> string list -> string list
---     -> (string -> fun option -> string list)
---     -> tab * tab * tab
local function read_fonts_conf_indeed (depth,
                                       start,
                                       home,
                                       xdg_config_home,
                                       xdg_data_home,
                                       acc,
                                       done,
                                       dirs_done,
                                       find_files,
                                       basedir)

  logreport ("both", 4, "db",
             "Fontconfig scanner processing path %s.",
             start)
  if depth >= traversal_maxdepth then
    --- prevent overflow of Lua call stack
    logreport ("both", 0, "db",
               "Fontconfig scanner hit recursion limit (%d); "
               .. "aborting directory traversal.",
               traversal_maxdepth)
    return acc, done, dirs_done
  end

  local paths = fonts_conf_scanner(start)
  if not paths then --- nothing to do
    return acc, done, dirs_done
  end

  for i=1, #paths do
    local pathobj = paths[i]
    local kind, path = pathobj[1], pathobj[2]
    local attributes = pathobj.attributes

    if kind == "dir" then
      if attributes and attributes.prefix == "xdg" then
        path = filejoin(xdg_data_home, path)
      end
      if stringsub(path, 1, 1) == "~" then
        path = filejoin(home, stringsub(path, 2))
      end
      --- We exclude paths with texmf in them, as they should be
      --- found anyway; also duplicates are ignored by checking
      --- if they are elements of dirs_done.
      ---
      --- FIXME does this mean we cannot access paths from
      --- distributions (e.g. Context minimals) installed
      --- separately?
      if not (stringfind(path, "texmf") or dirs_done[path]) then
        logreport ("log", 5, "db",
                   "New fontconfig path at %s.",
                   path)
        acc[#acc+1] = path
        dirs_done[path] = true
      end

    elseif kind == "include" then
      if attributes and attributes.prefix == "xdg" then
        path = filejoin(xdg_config_home, path)
      end
      --- here the path can be four things: a directory or a file,
      --- an absolute or relative path.
      if stringsub(path, 1, 1) == "~" then
        path = filejoin(home, stringsub(path, 2))
      elseif --- if the path is relative, we make it absolute
        not ( lfsisfile(path) or lfsisdir(path) )
      then
          path = filejoin(basedir, path)
      end
      if  lfsisfile(path)
        and kpsereadable_file(path)
      then
        if done[path] then
          logreport("log", 3, "db",
                    "Skipping file at %s, already included.", path)
        else
          done[path] = true
          acc = read_fonts_conf_indeed(depth + 1,
                                       path,
                                       home,
                                       xdg_config_home,
                                       xdg_data_home,
                                       acc,
                                       done,
                                       dirs_done,
                                       find_files,
                                       basedir)
        end
      elseif lfsisdir(path) then --- arrow code ahead
        if done[path] then
          logreport ("log", 3, "db",
                     "Skipping directory at %s, already included.", path)
        else
          done[path] = true
          local config_files = find_files (path, conf_filter)
          for _, filename in next, config_files do
            if done[filename] then
              logreport ("log", 3, "db",
                         "Skipping file at %s, already included.", filename)
            else
              done[filename] = true
              acc = read_fonts_conf_indeed(depth + 1,
                                           filename,
                                           home,
                                           xdg_config_home,
                                           xdg_data_home,
                                           acc,
                                           done,
                                           dirs_done,
                                           find_files,
                                           basedir)
            end
          end
        end
      end --- match “kind”
    end --- iterate paths
  end

  --inspect(acc)
  --inspect(done)
  return acc, done, dirs_done
end --- read_fonts_conf_indeed()

--[[doc--
      read_fonts_conf() sets up an accumulator and two sets
      for tracking what’s been done.

      Also, the environment variables HOME, XDG_DATA_HOME and
      XDG_CONFIG_HOME -- which are constants anyways -- are expanded
      so we don’t have to repeat that over and over again as with the
      old parser. Now they’re just passed on to every call of
      read_fonts_conf_indeed().
--doc]]--

--- list -> (string -> function option -> string list) -> list

local function read_fonts_conf (path_list, find_files)
  local home      = kpseexpand_path"~" --- could be os.getenv"HOME"
  local xdg_config_home  = kpseexpand_path"$XDG_CONFIG_HOME"
  if xdg_config_home == "" then xdg_config_home = filejoin(home, ".config") end
  local xdg_data_home  = kpseexpand_path"$XDG_DATA_HOME"
  if xdg_data_home == "" then xdg_data_home = filejoin(home, ".local/share") end
  local acc       = { } ---> list: paths collected
  local done      = { } ---> set:  files inspected
  local dirs_done = { } ---> set:  dirs in list
  for i=1, #path_list do --- we keep the state between files
    -- MK Pass the base directory
    acc, done, dirs_done = read_fonts_conf_indeed(0,
                                                  path_list[i],
                                                  home,
                                                  xdg_config_home,
                                                  xdg_data_home,
                                                  acc,
                                                  done,
                                                  dirs_done,
                                                  find_files,
                                                  filedirname(path_list[i]))
    -- /MK
  end
  return acc
end

-------------------------------------------------------------------------------
---                               MISC PARSERS
-------------------------------------------------------------------------------


local trailingslashes   = slash^1 * P(-1)
local stripslashes      = C((1 - trailingslashes)^0)

local splitcomma        = Ct((C(noncomma^1) + comma)^1)



-------------------------------------------------------------------------------
---                              FONT REQUEST
-------------------------------------------------------------------------------


--[[doc------------------------------------------------------------------------

    The luaotfload font request syntax (see manual)
    has a canonical form:

        \font<csname>=<prefix>:<identifier>:<features>

    where
      <csname> is the control sequence that activates the font
      <prefix> is either “file” or “name”, determining the lookup
      <identifer> is either a file name (no path) or a font
                  name, depending on the lookup
      <features> is a list of switches or options, separated by
                 semicolons or commas; a switch is of the form “+” foo
                 or “-” foo, options are of the form lhs “=” rhs

    however, to ensure backward compatibility we also have
    support for Xetex-style requests.

    for the Xetex emulation see:
    · The XeTeX Reference Guide by Will Robertson, 2011
    · The XeTeX Companion by Michel Goosens, 2010
    · About XeTeX by Jonathan Kew, 2005


    caueat emptor.

        the request is parsed into one of **four** different lookup
        categories: the regular ones, file and name, as well as the
        Xetex compatibility ones, path and anon. (maybe a better choice
        of identifier would be “ambig”.)

        according to my reconstruction, the correct chaining of the
        lookups for each category is as follows:

        | File -> ( db/filename lookup )

        | Name -> ( db/name lookup,
                    db/filename lookup )

        | Path -> ( db/filename lookup,
                    fullpath lookup )

        | Anon -> ( kpse.find_file(),     // <- for tfm, ofm
                    db/name lookup,
                    db/filename lookup,
                    fullpath lookup )

        caching of successful lookups is essential. we now as of v2.2
        have a lookup cache that is stored in a separate file. it
        pertains only to name: lookups, and is described in more detail
        in luaotfload-database.lua.

-------------------------------------------------------------------------------

    One further incompatibility between Xetex and Luatex-Fonts consists
    in their option list syntax: apparently, Xetex requires key-value
    options to be prefixed by a "+" (ascii “plus”) character. We
    silently accept this as well, dropping the first byte if it is a
    plus or minus character.

    Reference: https://github.com/lualatex/luaotfload/issues/79#issuecomment-18104483

--doc]]------------------------------------------------------------------------


--[[doc--

    Xetex style indexing begins at zero which we just increment before
    passing it along to the font loader.  Ymmv.

--doc]]--

local function handle_xetex_option (val)
  return tostring(1 + tonumber(val))
end

local featuresep = comma + semicolon

--- modifiers ---------------------------------------------------------
--[[doc--
    The slash notation: called “modifiers” (Kew) or “font options”
    (Robertson, Goosens)
    we only support the shorthands for italic / bold / bold italic
    shapes, as well as setting optical size, the rest is ignored.
--doc]]--
local style_modifier    = (S'bB' * S'iI'^-1 + S'iI' * S'bB'^-1 + S'rR')
                        / stringlower
local size_modifier     = S"Ss" * P"="    --- optical size
                        * Cc"optsize" * C(decimal)
local other_modifier    = P"AAT" + P"aat" --- apple stuff;  unsupported
                        + P"ICU" + P"icu" --- not applicable
                        + P"GR"  + P"gr"  --- sil stuff;    unsupported
local garbage_modifier  = ((1 - colon - slash)^0 * Cc(false))
local modifier          = slash * (other_modifier      --> ignore
                                 + Cs(style_modifier)  --> collect
                                 + Ct(size_modifier)   --> collect
                                 + garbage_modifier)   --> warn
local modifier_list     = Cg(Ct(modifier^0), "modifiers")

--- combining ---------------------------------------------------------
---
--- \font \three = combo: 1->42; 2->99,0xdeadbeef; 3->(1,U+2a-U+1337*42)
---                       v  +~  v  +~ +~~~~~~~~~  v   v +~~~ +~~~~~ +~
---                       |  |   |  |  |           |   | |    |      |
---                       |  |   |  |  |           |   | |    |      |
---        idx   :     ---+--÷---+--÷--÷-----------+   | +----+      |
---                          |      |  |               | |           |
---        id    :     ------+------+--÷---------------+ +-----------+
---                                    |                 |
---        chars :     ----------------+-----------------+
---
local comborowsep       = ws * semicolon * ws
local combomapsep       = ws * P"->"     * ws
local combodefsep       = ws * comma     * ws
local comborangesep     = ws * asterisk  * ws

local combohex          = hex     / tonumber
local combouint         = digit^1 / tonumber
local tonumber16        = function (s) return tonumber (s, 16) end
local combouni          = P"U+" * (digit^1 / tonumber16)
local combonum          = combohex + combouni + combouint
local comborange        = Ct(combonum * dash * combonum) + combonum
local combochars        = comborange * (comborangesep * comborange)^0
local parenthesized     = function (p) return P"(" * ws * p * ws * P")" end

local comboidxpat       = Cg(combouint, "idx")
local comboidpat        = Cg(combouint, "id" )
local combocharspat     = Cg(P"fallback" * Cc(true) + Ct(combochars^1), "chars")
local comboidcharspat   = comboidpat * combodefsep * combocharspat

local comboidx          = parenthesized (comboidxpat    ) + comboidxpat
local comboid           = parenthesized (comboidpat     ) + comboidpat
local comboidchars      = parenthesized (comboidcharspat) + comboidcharspat

local combodef1         = Ct(comboidx * combomapsep * comboid) --> no chars
local combodef          = Ct(comboidx * combomapsep * comboidchars)
local combolist         = Ct(combodef1 * (comborowsep * combodef)^1)

--- subfonts ----------------------------------------------------------
--- This rule is present in the original parser. It sets the “sub”
--- field of the specification which allows addressing a specific
--- font inside a TTC container. Neither in Luatex-Fonts nor in
--- Luaotfload is this documented, so we might as well silently drop
--- it. However, as backward compatibility is one of our prime goals we
--- just insert it here and leave it undocumented until someone cares
--- to ask. (Note: afair subfonts are numbered, but this rule matches a
--- string; I won’t mess with it though until someone reports a
--- problem.)
--- local subvalue   = P("(") * (C(P(1-S("()"))^1)/issub) * P(")") -- for Kim
--- Note to self: subfonts apparently start at index 0. Tested with
--- Cambria.ttc that includes “Cambria Math” at 0 and “Cambria” at 1.
--- Other values cause luatex to segfault.
local subfont           = P"(" * Cg(R'09'^1 / function (s)
                            return tonumber(s) + 1
                          end + (1 - S"()")^1, "sub") * P")"
-- An optional subfont shouldn't use subfont^-1 to ensure that parens
-- at the subfont location are never interpreted in different ways.
local maybe_subfont     = subfont + #(1 - P"(" + -1)

--- lookups -----------------------------------------------------------
local fontname          = C((1-S":(/")^1)  --- like luatex-fonts
local combo             = Cg(P"combo", "lookup") * colon * ws
                          * Cg(combolist, "name")
--- initially we intended file: to emulate the behavior of
--- luatex-fonts, i.e. no paths allowed. after all, we do have XeTeX
--- emulation with the path lookup and it interferes with db lookups.
--- turns out fontspec and other widely used packages rely on file:
--- with paths already, so we’ll add a less strict rule here.  anyways,
--- we’ll emit a warning.
local prefixed          = Cg(P"name" + "file" + "kpse" + "my", "lookup")
                          * colon * ws * Cg(fontname, "name")
                        + Cg(P"id", "lookup")
                          * colon * ws * Cg(R'09'^1 / tonumber, "id")
local unprefixed        = Cg(Cc"anon", "lookup") * Cg(fontname, "name")
--- Bracketed “path” lookups: These may contain any character except
--- for unbalanced brackets. A backslash escapes any following
--- character. Everything inside the outermost brackets is treated as
--- part of the filename or path to look up. Subfonts may be specified
--- in parens *after* the closing bracket. Note that this differs from
--- Xetex whose syntax expects the subfont passed inside the brackets,
--- separated by a colon.
local path_escape       = backslash / "" * patterns.utf8char
local path_content      = path_escape + (1 - brackets)
local path_balanced     = { (path_content + V(2))^1
                          , lbrk * V(1)^-1 * rbrk }
local path_lookup       = Cg(Cc"path", "lookup")
                          * lbrk * Cg(Cs(path_balanced), "name") * rbrk

--- features ----------------------------------------------------------
local balanced_braces   = P{((1 - S'{}') + '{' * V(1) * '}')^0}
local field_char        = '{' *   balanced_braces  * '}' + (1 - S'={}' - featuresep)
local field             = '{' * C(balanced_braces) * '}' + C(field_char^1)
--- assignments are “lhs=rhs”
---              or “+lhs=rhs” (Xetex-style)
--- switches    are “+key” | “-key”
local normal_option     = field * ws * equals * ws * field
local xetex_option      = P"+" * ws * (  field * ws * equals * ws
                                               * (digit^1/handle_xetex_option)
                                       + normal_option)
local assignment        = xetex_option
                        + normal_option
local switch            = P"-"    * ws * field * Cc(false)
                        + P"+"^-1 * ws * field * Cc(true)
local feature_expr      = ws * Cg(assignment + switch) * ws
local option            = feature_expr
local feature_list      = Cf(Ct""
                           * option
                           * (featuresep * option^-1)^0
                           , rawset)
                        * featuresep^-1
--- top-level rules ---------------------------------------------------
--- \font\foo=<specification>:<features>
local features          = Cg(feature_list, "features")
local specification     = (path_lookup + prefixed + unprefixed)
                        * maybe_subfont
                        * modifier_list
local font_request      = Ct(combo --> TODO: feature list needed?
                           + specification * (colon^-1 * features)^-1)

--  lpeg.print(font_request)
--- v2.5 parser: 1065 rules
--- v1.2 parser:  230 rules

-------------------------------------------------------------------------------
---                                INI FILES
-------------------------------------------------------------------------------

--[[doc--

    Luaotfload uses the pervasive flavor of the INI files that allows '#' in
    addition to ';' to indicate comment lines (see git-config(1) for a
    description of the syntax we’re targeting).

--doc]]--

local truth_ids = {
  ["true"]  = true,
  ["1"]     = true,
  yes       = true,
  on        = true,
  ["false"] = false,
  ["2"]     = false,
  no        = false,
  off       = false,
}

local function maybe_cast (var)
  local bool = truth_ids[var]
  if bool ~= nil then
    return bool
  end
  return tonumber (var) or var
end

local function escape (chr, repl)
  return (backslash * P(chr) / (repl or chr))
end

local valid_escapes     = escape "\""
                        + escape "\\"
                        + escape ("n", "\n")
                        + escape ("t", "\t")
                        + escape ("b", "\b")
local comment_char      = semicolon + gartenzaun
local comment_line      = ws * comment_char * (1 - eol)^0 * eol
local blank_line        = ws * eol
local skip_line         = comment_line + blank_line
local ini_id_char       = alpha + (dash / "_")
local ini_id            = Cs(alpha * ini_id_char^0) / stringlower
local ini_value_char    = (valid_escapes + (1 - linebreak - backslash - comment_char))
local ini_value         = (Cs (ini_value_char^0) / string.strip)
                        * (comment_char * (1 - eol)^0)^-1
local ini_string_char   = (valid_escapes + (1 - linebreak - dquote - backslash))
local ini_string        = dquote
                        * Cs (ini_string_char^0)
                        * dquote

local ini_heading_title = Ct (Cg (ini_id, "title")
                            * (ws * Cg (ini_string / stringlower, "subtitle"))^-1)
local ini_heading       = lbrk * ws
                        * Cg (ini_heading_title, "section")
                        * ws * rbrk * ws * eol

local ini_variable_full = Cg (ws
                            * ini_id
                            * ws
                            * equals
                            * ws
                            * (ini_string + (ini_value / maybe_cast))
                            * ws
                            * eol)
local ini_variable_true = Cg (ws * ini_id * ws * eol * Cc (true))
local ini_variable      = ini_variable_full
                        + ini_variable_true
                        + skip_line
local ini_variables     = Cg (Cf (Ct "" * ini_variable^0, rawset), "variables")

local ini_section       = Ct (ini_heading * ini_variables)
local ini_sections      = skip_line^0 * ini_section^0
local parse_config      = Ct (ini_sections)

--[=[doc--

    The INI parser converts an input of the form

            [==[
              [foo]
              bar = baz
              xyzzy = no
              buzz

              [lavernica "brutalitops"]
              # It’s a locomotive that runs on us.
                laan-ev = zip zop zooey   ; jib-jab
              Crouton = "Fibrosis \"\\ # "

            ]==]

    to a Lua table of the form

            { { section = { title = "foo" },
                variables = { bar = "baz",
                              xyzzy = false,
                              buzz = true } },
              { section = { title = "boing",
                            subtitle = "brutalitops" },
                variables = { ["laan-ev"] = "zip zop zooey",
                              crouton = "Fibrosis \"\\ # " } } }

--doc]=]--

luaotfload.parsers = {
  --- parameters
  traversal_maxdepth    = traversal_maxdepth,
  --- main parsers
  read_fonts_conf       = read_fonts_conf,
  font_request          = font_request,
  config                = parse_config,
  --- common patterns
  stripslashes          = stripslashes,
  splitcomma            = splitcomma,
}

return function ()
  logreport = luaotfload.log.report
  return true
end

-- vim:ft=lua:tw=71:et:sw=2:sts=4:ts=8
