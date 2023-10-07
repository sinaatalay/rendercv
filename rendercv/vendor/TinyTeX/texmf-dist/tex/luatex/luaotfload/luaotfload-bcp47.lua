-- Suport for parsing BCP47 based language tags into components
local normalize_case, language_tag do
  local l = lpeg or require'lpeg'
  local function rep(base, num, max)
    max = max or num
    if num == 1 then
      if max == 1 then
        return base
      else
        return base * base^-(max-1)
      end
    end
    return base * rep(base, num - 1, max - 1)
  end
  local eor = #(l.P'-' + -1) -- End of record
  local alpha = l.R('az', 'AZ')
  local alphanum = l.R('az', 'AZ', '09')
  local digit = l.R'09'
  normalize_case = l.Cs(
      (alphanum^2/string.lower)
      * (
          ('-' * (alphanum/string.upper) * (rep(alphanum, 3)/string.lower))
        + ('-' * alphanum^3/string.lower)
        + ('-' * rep(alphanum, 2)/string.upper)
        )^0
      * ('-' * alphanum * '-' * l.P(1)^1 / string.lower)^-1
    + alphanum * '-' * l.P(1)^1 / string.lower
  ) * -1
  local extlang = l.Cg(rep(alpha, 3), 'extlang')
  local language = l.Cg(rep(alpha, 2, 3), 'language') * ('-' * extlang * eor)^-1
  local script = l.Cg(rep(alpha, 4), 'script')
  local region = l.Cg(rep(alpha, 2) + rep(digit, 3), 'region')
  local variant = l.Cg(rep(alphanum, 5, 8) + digit * rep(alphanum, 3), 'variant')
  local singleton = l.R('09', 'aw', 'yz')
  local extension = l.Cg(l.C(singleton) * l.Ct(('-' * l.C(rep(alphanum, 2, 8)))^1))
  local privateuse = l.P'x' * l.Cg(l.Ct(('-' * l.C(rep(alphanum, 2, 8)))^1), 'private')
  local irregular =
      l.P'en-GB-oed' * l.Cc{language = 'en', region = 'GB', variant = 'oxendict'}
    + l.P'i-ami' * l.Cc{language = 'ami'}
    + l.P'i-bnn' * l.Cc{language = 'bnn'}
    + l.P'i-default' * l.Cc{language = 'i-default'} -- Not deprecated
    + l.P'i-enochian' * l.Cc{language = 'i-enochian'} -- The non-existance of a non deprecated language code for enochian
                                                      -- demonstrates a shocking for the language of my ancestors
    + l.P'i-hak' * l.Cc{language = 'hak'}
    + l.P'i-klingon' * l.Cc{language = 'tlh'}
    + l.P'i-lux' * l.Cc{language = 'lb'}
    + l.P'i-mingo' * l.Cc{language = 'i-mingo'} -- Not deprecated
    + l.P'i-navajo' * l.Cc{language = 'nv'}
    + l.P'i-pwn' * l.Cc{language = 'pwn'}
    + l.P'i-tao' * l.Cc{language = 'tao'}
    + l.P'i-tay' * l.Cc{language = 'tay'}
    + l.P'i-tsu' * l.Cc{language = 'tsu'}
    + l.P'sgn-BE-FR' * l.Cc{language = 'sfb'}
    + l.P'sgn-BE-NL' * l.Cc{language = 'vgt'}
    + l.P'sgn-CH-DE' * l.Cc{language = 'sgg'}
  local regular =
      l.P'art-lojban' * l.Cc{language = 'jbo'}
    + l.P'cel-gaulish' * l.Cc{language = 'cel-gaulish'} -- Might be xcg, xga or xtg
    + l.P'no-bok' * l.Cc{language = 'nb'}
    + l.P'no-nyn' * l.Cc{language = 'nn'}
    + l.P'zh-guoyu' * l.Cc{language = 'cmn'}
    + l.P'zh-hakka' * l.Cc{language = 'hak'}
    + l.P'zh-min' * l.Cc{language = '...'}
    + l.P'zh-min-nan' * l.Cc{language = 'nan'}
    + l.P'zh-xiang' * l.Cc{language = 'hsn'}
  local grandfathered = irregular + regular
  local langtag = language * ('-' * script * eor)^-1
                           * ('-' * region * eor)^-1
                           * ('-' * variant)^0
                           * (#('-' * singleton * '-') * l.Cg(l.Cf(l.Ct'' * ('-' * extension)^0, rawset), 'extension'))^-1
                           * ('-' * privateuse)^-1
  language_tag = (grandfathered + l.Ct(langtag + privateuse)) * -1
end
local function parse(tag)
  tag = normalize_case:match(tag)
  if not tag then return end
  return language_tag:match(tag), tag
end
-- for l in io.lines() do
--   print(parse(l))
--   -- io.stdout:write(parse(l), '\n')
-- end
return {
  normalize_case = function(n) return normalize_case:match(tag) end,
  parse = parse,
}
