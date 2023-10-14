-- Copyright 2011 by Christophe Jorssen and Mark Wibrow
-- Copyright 2014 by Christian Feuersaenger
--
-- This file may be distributed and/or modified
--
-- 1. under the LaTeX Project Public License and/or
-- 2. under the GNU Public License.
--
-- See the file doc/generic/pgf/licenses/LICENSE for more details.
--
-- $Id$
--
-- usage:
--
-- pgfluamathparser = require("pgf.luamath.parser")
--
-- local result = pgfluamathparser.pgfmathparse("1+ 2*4^2")
--
-- This LUA class has a direct backend in \pgfuselibrary{luamath}, see the documentation of that TeX package.

local pgfluamathparser = pgfluamathparser or {}

pgfluamathfunctions = require("pgf.luamath.functions")

-- lpeg is always present in luatex
local lpeg = require("lpeg")

local S, P, R = lpeg.S, lpeg.P, lpeg.R
local C, Cc, Ct = lpeg.C, lpeg.Cc, lpeg.Ct
local Cf, Cg, Cs = lpeg.Cf, lpeg.Cg, lpeg.Cs
local V = lpeg.V
local match = lpeg.match

local space_pattern = S(" \n\r\t")^0
local tex_unit =
        P('pt') + P('mm') + P('cm') + P('in') +
        -- while valid units, the font-depending ones need special attention... move them to the TeX side. For now.
        -- P('ex') + P('em') +
        P('bp') + P('pc') +
        P('dd') + P('cc') + P('sp');

local one_digit_pattern = R("09")
local positive_integer_pattern = one_digit_pattern^1
-- FIXME : it might be a better idea to remove '-' from all number_patterns! Instead, rely on the prefix operator 'neg' to implement negative numbers.
-- Is that wise? It is certainly less efficient...
local integer_pattern = S("+-")^-1 * positive_integer_pattern
-- Valid positive decimals are |xxx.xxx|, |.xxx| and |xxx.|
local positive_integer_or_decimal_pattern = positive_integer_pattern * ( P(".") * one_digit_pattern^0)^-1 +
                                 (P(".") * one_digit_pattern^1)
local integer_or_decimal_pattern = S("+-")^-1 * positive_integer_or_decimal_pattern
local fpu_pattern = R"05" * P"Y" * positive_integer_or_decimal_pattern * P"e" * S("+-")^-1 * R("09")^1 * P"]"
local unbounded_pattern = P"inf" + P"INF" + P"nan" + P"NaN" + P"Inf"
local number_pattern = C(unbounded_pattern + fpu_pattern + integer_or_decimal_pattern * (S"eE" * integer_pattern + C(tex_unit))^-1)

local underscore_pattern = P("_")

local letter_pattern = R("az","AZ")
local alphanum__pattern = letter_pattern + one_digit_pattern + underscore_pattern

local identifier_pattern = letter_pattern^1 * alphanum__pattern^0

local openparen_pattern = P("(") * space_pattern
local closeparen_pattern = P(")")
local opencurlybrace_pattern = P("{")
local closecurlybrace_pattern = P("}")
local openbrace_pattern = P("[")
local closebrace_pattern = P("]")

-- hm. what about '\\' or '\%' ?
-- accept \pgf@x, \count0, \dimen42, \c@pgf@counta, \wd0, \ht0, \dp 0
local controlsequence_pattern = P"\\" * C( (R("az","AZ") + P"@")^1) * space_pattern* C( R"09"^0 )

-- local string = P('"') * C((1 - P('"'))^0) * P('"')

local comma_pattern = P(",") * space_pattern


----------------
local TermOp = C(S("+-")) * space_pattern
local EqualityOp = C( P"==" + P"!=" ) * space_pattern
local RelationalOp = C( P"<=" + P">=" + P"<" + P">" ) * space_pattern
local FactorOp = C(S("*/")) * space_pattern

-- Grammar
local Exp, Term, Factor = V"Exp", V"Term", V"Factor"
local Prefix = V"Prefix"
local Postfix = V"Postfix"



local function eval (v1, op, v2)
  if (op == "+") then return v1 + v2
  elseif (op == "-") then return v1 - v2
  elseif (op == "*") then return v1 * v2
  elseif (op == "/") then return v1 / v2
  else
    error("This function must not be invoked for operator "..op)
  end
end

local pgfStringToFunctionMap = pgfluamathfunctions.stringToFunctionMap
local function function_eval(name, ... )
    local f = pgfStringToFunctionMap[name]
    if not f then
      error("Function '" .. name .. "' is undefined (did not find pgfluamathfunctions."..name .." (looked into pgfluamathfunctions.stringToFunctionMap))")
    end
    -- FIXME: validate signature
    return f(...)
end


local func =
    (C(identifier_pattern) * space_pattern * openparen_pattern * Exp * (comma_pattern * Exp)^0 * closeparen_pattern) / function_eval;

local functionWithoutArg = identifier_pattern / function_eval

-- this is what can occur as exponent after '^'.
-- I have the impression that the priorities could be implemented in a better way than this... but it seems to work.
local pow_exponent =
    -- allows 2^-4,  2^1e4, 2^2
    -- FIXME : why not 2^1e2 ?
    Cg(C(integer_or_decimal_pattern)
    -- 2^pi, 2^multiply(2,2)
    + Cg(func+functionWithoutArg)
    -- 2^(2+2)
    + openparen_pattern * Exp * closeparen_pattern )

local function prefix_eval(op, x)
  if op == "-" then
    return pgfluamathfunctions.neg(x)
  elseif op == "!" then
    return pgfluamathfunctions.notPGF(x)
  else
    error("This function must not be invoked for operator "..op)
  end
end


local prefix_operator = C( S"-!" )
local prefix_operator_pattern = (prefix_operator * space_pattern * Cg(Prefix) ) / prefix_eval

-- apparently, we need to distinguish between <expr> ! and  <expr> != <expr2>:
local postfix_operator = C( S"r!" - P"!=" )  + C(P"^") * space_pattern * pow_exponent

pgfluamathfunctions.functionMustBeEvaluatedInTeX = function()
  error("The function in this context cannot be evaluated by LUA because it depends on TeX macros.")
end

local ternary_eval = pgfluamathfunctions.ifthenelse

local factorial_eval = pgfluamathfunctions.factorial
local deg = pgfluamathfunctions.deg
local pow_eval = pgfluamathfunctions.pow

-- @param prefix the argument before the postfix operator.
-- @param op either nil or the postfix operator
-- @param arg either nil or the (mandatory) argument for 'op'
local function postfix_eval(prefix, op, arg)
  local result
  if op == nil then
    result = prefix
  elseif op == "r" then
    if arg then error("parser setup error: expected nil argument") end
    result = deg(prefix)
  elseif op == "!" then
    if arg then error("parser setup error: expected nil argument") end
    result = factorial_eval(prefix)
  elseif op == "^" then
    if not arg then error("parser setup error: ^ with its argument") end
    result = pow_eval(prefix, arg)
  else
    error("Parser setup error: " .. tostring(op) .. " unexpected in this context")
  end
  return result
end

local function equality_eval(v1, op, v2)
  local fct
  if (op == "==") then fct = pgfluamathfunctions.equal
  elseif (op == "!=") then fct = pgfluamathfunctions.notequal
  else
    error("This function must not be invoked for operator "..op)
  end
  return fct(v1,v2)
end
local function relational_eval(v1, op, v2)
  local fct
  if (op == "<") then fct = pgfluamathfunctions.less
  elseif (op == ">") then fct = pgfluamathfunctions.greater
  elseif (op == ">=") then fct = pgfluamathfunctions.notless
  elseif (op == "<=") then fct = pgfluamathfunctions.notgreater
  else
    error("This function must not be invoked for operator "..op)
  end
  return fct(v1,v2)
end

-- @return either the box property or nil
-- @param cs "wd", "ht", or "dp"
-- @param intSuffix some integer
local function get_tex_box(cs, intSuffix)
  -- assume get_tex_box is only called when a dimension is required.
  local result
  pgfluamathparser.units_declared = true
  local box =tex.box[tonumber(intSuffix)]
  if not box then error("There is no box " .. intSuffix) end
  if cs == "wd" then
    result = box.width / 65536
  elseif cs == "ht" then
    result = box.height / 65536
  elseif cs == "dp" then
    result = box.depth / 65536
  else
    result = nil
  end
  return result
end


local function controlsequence_eval(cs, intSuffix)
  local result
  if intSuffix and #intSuffix >0 then
    if cs == "count" then
      result= pgfluamathparser.get_tex_count(intSuffix)
    elseif cs == "dimen" then
      result= pgfluamathparser.get_tex_dimen(intSuffix)
    else
      result = get_tex_box(cs,intSuffix)
      if not result then
        -- this can happen - we cannot expand \chardef'ed boxes here.
        -- this will be done by the TeX part
        error('I do not know/support the TeX register "\\' .. cs .. '"')
      end
    end
  else
    result = pgfluamathparser.get_tex_register(cs)
  end
  return result
end

pgfluamathparser.units_declared = false
function pgfluamathparser.get_tex_register(register)
  -- register is a string which could be a count or a dimen.
  if pcall(tex.getcount, register) then
    return tex.count[register]
  elseif pcall(tex.getdimen, register) then
    pgfluamathparser.units_declared = true
    return tex.dimen[register] / 65536 -- return in points.
  else
    error('I do not know the TeX register "' .. register .. '"')
    return nil
  end
end

function pgfluamathparser.get_tex_count(count)
  -- count is expected to be a number
  return tex.count[tonumber(count)]
end

function pgfluamathparser.get_tex_dimen(dimen)
  -- dimen is expected to be a number
  pgfluamathparser.units_declared = true
  return tex.dimen[tonumber(dimen)] / 65536
end

function pgfluamathparser.get_tex_sp(dimension)
  -- dimension should be a string
  pgfluamathparser.units_declared = true
  return tex.sp(dimension) / 65536
end


local initialRule = V"initial"

local Summand = V"Summand"
local Relational = V"Relational"
local Equality = V"Equality"
local LogicalOr = V"LogicalOr"
local LogicalAnd = V"LogicalAnd"

local pgftonumber = pgfluamathfunctions.tonumber
local tonumber_withunit = pgfluamathparser.get_tex_sp
local function number_optional_units_eval(x, unit)
  if not unit then
    return pgftonumber(x)
  else
    return tonumber_withunit(x)
  end
end

-- @param scale the number.
-- @param controlsequence either nil in which case just the number must be returned or a control sequence
-- @see controlsequence_eval
local function scaled_controlsequence_eval(scale, controlsequence, intSuffix)
    if controlsequence==nil then
        return scale
    else
        return scale * controlsequence_eval(controlsequence, intSuffix)
    end
end

-- Grammar
--
-- for me:
-- - use '/' to evaluate all expressions which contain a _constant_ number of captures.
-- - use Cf to evaluate expressions which contain a _dynamic_ number of captures
--
-- see unittest_luamathparser.tex for tons of examples
local G = P{ "initialRule",
  initialRule = space_pattern* Exp * -1;
  -- ternary operator (or chained ternary operators):
  -- FIXME : is this chaining a good idea!?
  Exp = Cf( LogicalOr * Cg(P"?" * space_pattern * LogicalOr * P":" *space_pattern * LogicalOr )^0, ternary_eval) ;
  LogicalOr = Cf(LogicalAnd * (P"||" * space_pattern * LogicalAnd)^0, pgfluamathfunctions.orPGF);
  LogicalAnd = Cf(Equality * (P"&&" * space_pattern * Equality)^0, pgfluamathfunctions.andPGF);
  Equality = Cf(Relational * Cg(EqualityOp * Relational)^0, equality_eval);
  Relational = Cf(Summand * Cg(RelationalOp * Summand)^0, relational_eval);
  Summand = Cf(Term * Cg(TermOp * Term)^0, eval) ;
  Term = Cf(Prefix * Cg(FactorOp * Prefix)^0, eval);
  Prefix = prefix_operator_pattern + Postfix;
  -- this calls 'postfix_eval' with nil arguments if it is no postfix operation.. but that does not hurt (right?)
  Postfix = Factor * (postfix_operator * space_pattern)^-1 / postfix_eval;
  Factor =
    (
    number_pattern / number_optional_units_eval *
      -- this construction will evaluate number_pattern with 'number_optional_units_eval' FIRST.
      -- also accept '0.5 \pgf@x' here:
      space_pattern *controlsequence_pattern^-1 / scaled_controlsequence_eval
    + func
    + functionWithoutArg
    + openparen_pattern * Exp * closeparen_pattern
    + controlsequence_pattern / controlsequence_eval
    ) *space_pattern
  ;
}

-- does not reset units_declared.
local function pgfmathparseinternal(str)
  local result = match(G,str)
  if result == nil then
    error("The string '" .. str .. "' is no valid PGF math expression. Please check for syntax errors.")
  end
  return result
end


-- This is the math parser function in this module.
--
-- @param str a string like "1+1" which is accepted by the PGF math language
-- @return the result of the expression.
--
-- Throws an error if the string is no valid expression.
function pgfluamathparser.pgfmathparse(str)
  pgfluamathparser.units_declared = false

  return pgfmathparseinternal(str)
end

local pgfmathparse = pgfluamathparser.pgfmathparse
local tostringfixed = pgfluamathfunctions.tostringfixed
local tostringfpu = pgfluamathfunctions.toTeXstring

local tmpFunctionArgumentPrefix = "tmpVar"
local stackOfLocalFunctions = {}

-- This is a backend for PGF's 'declare function'.
--   \tikzset{declare function={mu(\x,\i)=\x^\i;}}
-- will boil down to
--   pgfluamathparser.declareExpressionFunction("mu", 2, "#1^#2")
--
-- The local function will be pushed on a stack of known local functions and is
-- available until popLocalExpressionFunction() is called. TeX will call this using
-- \aftergroup.
--
-- @param name the name of the new function
-- @param numArgs the number of arguments
-- @param expression an expression containing #1, ... #n where n is numArgs
--
-- ATTENTION: local functions behave DIFFERENTLY in LUA!
-- In LUA, local variables are not expanded whereas TeX expands them.
-- The difference is
--
-- declare function={mu1(\x,\i)=\x^\i;}
-- \pgfmathparse{mu1(-5,2)} --> -25
-- \pgfluamathparse{mu1(-5,2)} --> 25
--
-- x = -5
-- \pgfmathparse{mu1(x,2)} --> 25
-- \pgfluamathparse{mu1(x,2)} --> 25
--
-- In an early prototype, I simulated TeX's expansion to fix the first case (successfully).
-- BUT: that "simulated expansion" broke the second case because LUA will evaluate "x" and hand -5 to the local function.
-- I decided to keep it as is. Perhaps we should fix PGF's expansion approach in TeX (which is ugly anyway)
function pgfluamathparser.pushLocalExpressionFunction(name, numArgs, expression)
  -- now we have "tmpVar1^tmpVar2" instead of "#1^#2"
  local normalizedExpr = expression:gsub("#", tmpFunctionArgumentPrefix)
  local restores = {}
  local tmpVars = {}
  for i=1,numArgs do
    local tmpVar = tmpFunctionArgumentPrefix .. tostring(i)
    tmpVars[i] = tmpVar
  end

  local newFunction = function(...)
    local args = table.pack(...)

    -- define "tmpVar1" ... "tmpVarN" to return args[i].
    -- Of course, we need to restore "tmpVar<i>" after we return!
    for i=1,numArgs do
      local tmpVar = tmpVars[i]
      local value = args[i]
      restores[i] = pgfStringToFunctionMap[tmpVar]
      pgfStringToFunctionMap[tmpVar] = function () return value end
    end

    -- parse our expression.

    -- FIXME : this here is an attempt to mess around with "units_declared".
    --   It would be better to call pgfmathparse and introduce some
    --   semaphore to check if pgfmathparse is a nested call-- in this case, it should
    --   not reset units_declared. But there is no "finally" block and pcall is crap (looses stack trace).
    local success,result = pcall(pgfmathparseinternal, normalizedExpr)

    -- remove 'tmpVar1', ... from the function table:
    for i=1,numArgs do
      local tmpVar = tmpVars[i]
      pgfStringToFunctionMap[tmpVar] = restores[i]
    end

    if success==false then error(result) end
    return result
  end
  table.insert(stackOfLocalFunctions, name)
  pgfStringToFunctionMap[name] = newFunction
end

function pgfluamathparser.popLocalExpressionFunction()
  local name = stackOfLocalFunctions[#stackOfLocalFunctions]
  pgfStringToFunctionMap[name] = nil
  -- this removes the last element:
  table.remove(stackOfLocalFunctions)
end


-- A Utility function which simplifies the interaction with the TeX code
-- @param expression the input expression (string)
-- @param outputFormatChoice 0 if the result should be a fixed point number, 1 if it should be in FPU format
-- @param showErrorMessage (boolean) true if any error should be displayed, false if errors should simply result in an invocation of TeX's parser (the default)
--
-- it defines \pgfmathresult and \ifpgfmathunitsdeclared
function pgfluamathparser.texCallParser(expression, outputFormatChoice, showErrorMessage)
  local success, result
  if showErrorMessage then
    result = pgfmathparse(expression)
    success = true
  else
    success, result = pcall(pgfmathparse, expression)
  end

  if success and result then
    local result_str
    if outputFormatChoice == 0 then
      -- luamath/output format=fixed
      result_str = tostringfixed(result)
    else
      -- luamath/output format=fixed
      result_str = tostringfpu(result)
    end
    tex.sprint("\\def\\pgfmathresult{" .. result_str .. "}")
    if pgfluamathparser.units_declared then
      tex.sprint("\\pgfmathunitsdeclaredtrue")
    else
      tex.sprint("\\pgfmathunitsdeclaredfalse")
    end
  else
    tex.sprint("\\def\\pgfmathresult{}")
    tex.sprint("\\pgfmathunitsdeclaredfalse")
  end
end

return pgfluamathparser
