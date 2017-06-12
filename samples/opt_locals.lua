#!/usr/bin/env lua
--[[--------------------------------------------------------------------

  LuaSrcDiet
  Compresses Lua source code by removing unnecessary characters.
  For Lua 5.1.x source code.

  Copyright (c) 2008,2011,2012 Kein-Hong Man <keinhong@gmail.com>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- NOTES:
-- * Remember to update version and date information below (MSG_TITLE)
-- * TODO: passing data tables around is a horrific mess
-- * TODO: to implement pcall() to properly handle lexer etc. errors
-- * TODO: need some automatic testing for a semblance of sanity
-- * TODO: the plugin module is highly experimental and unstable
----------------------------------------------------------------------]]

-- standard libraries, functions
local s = string
local e = math
local ee = table
local j = require
local y = print
local f = s.sub
local G = s.gmatch
local B = s.match

-- modules incorporated as preload functions follows
local p = package.preload
local a = _G

local Z = {
  html = "html    generates a HTML file for checking globals",
  sloc = "sloc    calculates SLOC for given source file",
}

local W = {
  'html',
  'sloc',
}

-- preload function for module llex
p.llex =
function()
--start of inserted module
module "llex"

local h = a.require "string"
local u = h.find
local c = h.match
local n = h.sub

----------------------------------------------------------------------
-- initialize keyword list, variables
----------------------------------------------------------------------

local f = {}
for e in h.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]], "%S+") do
  f[e] = true
end

-- see init() for module variables (externally visible):
--       tok, seminfo, tokln

local e,                -- source stream
      l,         -- name of source
      o,                -- position of lexer
      s,             -- buffer for strings
      r                -- line number

----------------------------------------------------------------------
-- add information to token listing
----------------------------------------------------------------------

local function i(t, a)
  local e = #tok + 1
  tok[e] = t
  seminfo[e] = a
  tokln[e] = r
end

----------------------------------------------------------------------
-- handles line number incrementation and end-of-line characters
----------------------------------------------------------------------

local function d(t, s)
  local n = n
  local a = n(e, t, t)
  t = t + 1  -- skip '\n' or '\r'
  local e = n(e, t, t)
  if (e == "\n" or e == "\r") and (e ~= a) then
    t = t + 1  -- skip '\n\r' or '\r\n'
    a = a..e
  end
  if s then i("TK_EOL", a) end
  r = r + 1
  o = t
  return t
end

----------------------------------------------------------------------
-- initialize lexer for given source _z and source name _sourceid
----------------------------------------------------------------------

function init(a, t)
  e = a                        -- source
  l = t          -- name of source
  o = 1                         -- lexer's position in source
  r = 1                        -- line number
  tok = {}                      -- lexed token list*
  seminfo = {}                  -- lexed semantic information list*
  tokln = {}                    -- line numbers for messages*
                                -- (*) externally visible thru' module
  --------------------------------------------------------------------
  -- initial processing (shbang handling)
  --------------------------------------------------------------------
  local a, n, e, t = u(e, "^(#[^\r\n]*)(\r?\n?)")
  if a then                             -- skip first line
    o = o + #e
    i("TK_COMMENT", e)
    if #t > 0 then d(o, true) end
  end
end

----------------------------------------------------------------------
-- returns a chunk name or id, no truncation for long names
----------------------------------------------------------------------

function chunkid()
  if l and c(l, "^[=@]") then
    return n(l, 2)  -- remove first char
  end
  return "[string]"
end

----------------------------------------------------------------------
-- formats error message and throws error
-- * a simplified version, does not report what token was responsible
----------------------------------------------------------------------

function errorline(o, t)
  local e = error or a.error
  e(h.format("%s:%d: %s", chunkid(), t or r, o))
end
local r = errorline

------------------------------------------------------------------------
-- count separators ("=") in a long string delimiter
------------------------------------------------------------------------

local function m(t)
  local i = n
  local n = i(e, t, t)
  t = t + 1
  local a = #c(e, "=*", t)
  t = t + a
  o = t
  return (i(e, t, t) == n) and a or (-a) - 1
end

----------------------------------------------------------------------
-- reads a long string or long comment
----------------------------------------------------------------------

local function w(h, l)
  local t = o + 1  -- skip 2nd '['
  local i = n
  local a = i(e, t, t)
  if a == "\r" or a == "\n" then  -- string starts with a newline?
    t = d(t)  -- skip it
  end
  while true do
    local a, u, n = u(e, "([\r\n%]])", t) -- (long range match)
    if not a then
      r(h and "unfinished long string" or
                "unfinished long comment")
    end
    t = a
    if n == "]" then                    -- delimiter test
      if m(t) == l then
        s = i(e, s, o)
        o = o + 1  -- skip 2nd ']'
        return s
      end
      t = o
    else                                -- newline
      s = s.."\n"
      t = d(t)
    end
  end--while
end

----------------------------------------------------------------------
-- reads a string
----------------------------------------------------------------------

local function y(l)
  local t = o
  local h = u
  local n = n
  while true do
    local i, u, a = h(e, "([\n\r\\\"\'])", t) -- (long range match)
    if i then
      if a == "\n" or a == "\r" then
        r("unfinished string")
      end
      t = i
      if a == "\\" then                         -- handle escapes
        t = t + 1
        a = n(e, t, t)
        if a == "" then break end -- (EOZ error)
        i = h("abfnrtv\n\r", a, 1, true)
        ------------------------------------------------------
        if i then                               -- special escapes
          if i > 7 then
            t = d(t)
          else
            t = t + 1
          end
        ------------------------------------------------------
        elseif h(a, "%D") then               -- other non-digits
          t = t + 1
        ------------------------------------------------------
        else                                    -- \xxx sequence
          local o, e, a = h(e, "^(%d%d?%d?)", t)
          t = e + 1
          if a + 1 > 256 then -- UCHAR_MAX
            r("escape sequence too large")
          end
        ------------------------------------------------------
        end--if p
      else
        t = t + 1
        if a == l then                        -- ending delimiter
          o = t
          return n(e, s, t - 1)            -- return string
        end
      end--if r
    else
      break -- (error)
    end--if p
  end--while
  r("unfinished string")
end

------------------------------------------------------------------------
-- main lexer function
------------------------------------------------------------------------

function llex()
  local h = u
  local l = c
  while true do--outer
    local t = o
    -- inner loop allows break to be used to nicely section tests
    while true do--inner
      ----------------------------------------------------------------
      local c, p, u = h(e, "^([_%a][_%w]*)", t)
      if c then
        o = t + #u
        if f[u] then
          i("TK_KEYWORD", u)             -- reserved word (keyword)
        else
          i("TK_NAME", u)                -- identifier
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local u, f, c = h(e, "^(%.?)%d", t)
      if u then                                 -- numeral
        if c == "." then t = t + 1 end
        local c, s, d = h(e, "^%d*[%.%d]*([eE]?)", t)
        t = s + 1
        if #d == 1 then                         -- optional exponent
          if l(e, "^[%+%-]", t) then        -- optional sign
            t = t + 1
          end
        end
        local s, t = h(e, "^[_%w]*", t)
        o = t + 1
        local e = n(e, u, t)                  -- string equivalent
        if not a.tonumber(e) then            -- handles hex test also
          r("malformed number")
        end
        i("TK_NUMBER", e)
        break -- (continue)
      end
      ----------------------------------------------------------------
      local c, f, u, a = h(e, "^((%s)[ \t\v\f]*)", t)
      if c then
        if a == "\n" or a == "\r" then          -- newline
          d(t, true)
        else
          o = f + 1                             -- whitespace
          i("TK_SPACE", u)
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local a = l(e, "^%p", t)
      if a then
        s = t
        local d = h("-[\"\'.=<>~", a, 1, true)
        if d then
          -- two-level if block for punctuation/symbols
          --------------------------------------------------------
          if d <= 2 then
            if d == 1 then                      -- minus
              local r = l(e, "^%-%-(%[?)", t)
              if r then
                t = t + 2
                local a = -1
                if r == "[" then
                  a = m(t)
                end
                if a >= 0 then                -- long comment
                  i("TK_LCOMMENT", w(false, a))
                else                            -- short comment
                  o = h(e, "[\n\r]", t) or (#e + 1)
                  i("TK_COMMENT", n(e, s, o - 1))
                end
                break -- (continue)
              end
              -- (fall through for "-")
            else                                -- [ or long string
              local e = m(t)
              if e >= 0 then
                i("TK_LSTRING", w(true, e))
              elseif e == -1 then
                i("TK_OP", "[")
              else
                r("invalid long string delimiter")
              end
              break -- (continue)
            end
          --------------------------------------------------------
          elseif d <= 5 then
            if d < 5 then                       -- strings
              o = t + 1
              i("TK_STRING", y(a))
              break -- (continue)
            end
            a = l(e, "^%.%.?%.?", t)        -- .|..|... dots
            -- (fall through)
          --------------------------------------------------------
          else                                  -- relational
            a = l(e, "^%p=?", t)
            -- (fall through)
          end
        end
        o = t + #a
        i("TK_OP", a)  -- for other symbols, fall through
        break -- (continue)
      end
      ----------------------------------------------------------------
      local e = n(e, t, t)
      if e ~= "" then
        o = t + 1
        i("TK_OP", e)                    -- other single-char tokens
        break
      end
      i("TK_EOS", "")                    -- end of stream,
      return                                    -- exit here
      ----------------------------------------------------------------
    end--while inner
  end--while outer
end
--end of inserted module
end

-- preload function for module lparser
p.lparser =
function()
--start of inserted module
module "lparser"

local v = a.require "string"

--[[--------------------------------------------------------------------
-- variable and data structure initialization
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- initialization: main variables
----------------------------------------------------------------------

local E,                  -- grammar-only token tables (token table,
      k,              -- semantic information table, line number
      A,                -- table, cross-reference table)
      S,
      s,                     -- token position

      u,                     -- start line # for error messages
      Y,                   -- last line # for ambiguous syntax chk
      t, T, d, f,   -- token, semantic info, line
      y,                  -- proper position of <name> token
      o,                       -- current function state
      P,                   -- top-level function state

      _,               -- global variable information table
      D,             -- global variable name lookup table
      l,                -- local variable information table
      b,               -- inactive locals (prior to activation)
      I,               -- corresponding references to activate
      z                  -- statements labeled by type

-- forward references for local functions
local q, r, g, N, O, x

----------------------------------------------------------------------
-- initialization: data structures
----------------------------------------------------------------------

local e = v.gmatch

local R = {}         -- lookahead check in chunk(), returnstat()
for e in e("else elseif end until <eof>", "%S+") do
  R[e] = true
end

local H = {}          -- binary operators, left priority
local V = {}         -- binary operators, right priority
for e, a, t in e([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]], "{(%S+)%s(%d+)%s(%d+)}") do
  H[e] = a + 0
  V[e] = t + 0
end

local te = { ["not"] = true, ["-"] = true,
                ["#"] = true, } -- unary operators
local ee = 8        -- priority for unary operators

--[[--------------------------------------------------------------------
-- support functions
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- formats error message and throws error (duplicated from llex)
-- * a simplified version, does not report what token was responsible
----------------------------------------------------------------------

local function i(e, t)
  local a = error or a.error
  a(v.format("(source):%d: %s", t or d, e))
end

----------------------------------------------------------------------
-- handles incoming token, semantic information pairs
-- * NOTE: 'nextt' is named 'next' originally
----------------------------------------------------------------------

-- reads in next token
local function e()
  Y = A[s]
  t, T, d, f
    = E[s], k[s], A[s], S[s]
  s = s + 1
end

-- peek at next token (single lookahead for table constructor)
local function Z()
  return E[s]
end

----------------------------------------------------------------------
-- throws a syntax error, or if token expected is not there
----------------------------------------------------------------------

local function h(a)
  local e = t
  if e ~= "<number>" and e ~= "<string>" then
    if e == "<name>" then e = T end
    e = "'"..e.."'"
  end
  i(a.." near "..e)
end

local function m(e)
  h("'"..e.."' expected")
end

----------------------------------------------------------------------
-- tests for a token, returns outcome
-- * return value changed to boolean
----------------------------------------------------------------------

local function i(a)
  if t == a then e(); return true end
end

----------------------------------------------------------------------
-- check for existence of a token, throws error if not found
----------------------------------------------------------------------

local function M(e)
  if t ~= e then m(e) end
end

----------------------------------------------------------------------
-- verify existence of a token, then skip it
----------------------------------------------------------------------

local function n(t)
  M(t); e()
end

----------------------------------------------------------------------
-- throws error if condition not matched
----------------------------------------------------------------------

local function X(e, t)
  if not e then h(t) end
end

----------------------------------------------------------------------
-- verifies token conditions are met or else throw error
----------------------------------------------------------------------

local function c(e, a, t)
  if not i(e) then
    if t == d then
      m(e)
    else
      h("'"..e.."' expected (to close '"..a.."' at line "..t..")")
    end
  end
end

----------------------------------------------------------------------
-- expect that token is a name, return the name
----------------------------------------------------------------------

local function w()
  M("<name>")
  local t = T
  y = f
  e()
  return t
end

----------------------------------------------------------------------
-- adds given string s in string pool, sets e as VK
----------------------------------------------------------------------

local function F(e, t)
  e.k = "VK"
end

----------------------------------------------------------------------
-- consume a name token, adds it to string pool
----------------------------------------------------------------------

local function U(e)
  F(e, w())
end

--[[--------------------------------------------------------------------
-- variable (global|local|upvalue) handling
-- * to track locals and globals, variable management code needed
-- * entry point is singlevar() for variable lookups
-- * lookup tables (bl.locallist) are maintained awkwardly in the basic
--   block data structures, PLUS the function data structure (this is
--   an inelegant hack, since bl is nil for the top level of a function)
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- register a local variable, create local variable object, set in
-- to-activate variable list
-- * used in new_localvarliteral(), parlist(), fornum(), forlist(),
--   localfunc(), localstat()
----------------------------------------------------------------------

local function m(i, a)
  local t = o.bl
  local e
  -- locate locallist in current block object or function root object
  if t then
    e = t.locallist
  else
    e = o.locallist
  end
  -- build local variable information object and set localinfo
  local t = #l + 1
  l[t] = {             -- new local variable object
    name = i,                -- local variable name
    xref = { y },         -- xref, first value is declaration
    decl = y,             -- location of declaration, = xref[1]
  }
  if a then               -- "self" must be not be changed
    l[t].isself = true
  end
  -- this can override a local with the same name in the same scope
  -- but first, keep it inactive until it gets activated
  local a = #b + 1
  b[a] = t
  I[a] = e
end

----------------------------------------------------------------------
-- actually activate the variables so that they are visible
-- * remember Lua semantics, e.g. RHS is evaluated first, then LHS
-- * used in parlist(), forbody(), localfunc(), localstat(), body()
----------------------------------------------------------------------

local function j(e)
  local t = #b
  -- i goes from left to right, in order of local allocation, because
  -- of something like: local a,a,a = 1,2,3 which gives a = 3
  while e > 0 do
    e = e - 1
    local e = t - e
    local a = b[e]            -- local's id
    local t = l[a]
    local o = t.name               -- name of local
    t.act = f                      -- set activation location
    b[e] = nil
    local i = I[e]     -- ref to lookup table to update
    I[e] = nil
    local e = i[o]    -- if existing, remove old first!
    if e then                    -- do not overlap, set special
      t = l[e]         -- form of rem, as -id
      t.rem = -a
    end
    i[o] = a                -- activate, now visible to Lua
  end
end

----------------------------------------------------------------------
-- remove (deactivate) variables in current scope (before scope exits)
-- * zap entire locallist tables since we are not allocating registers
-- * used in leaveblock(), close_func()
----------------------------------------------------------------------

local function L()
  local t = o.bl
  local e
  -- locate locallist in current block object or function root object
  if t then
    e = t.locallist
  else
    e = o.locallist
  end
  -- enumerate the local list at current scope and deactivate 'em
  for t, e in a.pairs(e) do
    local e = l[e]
    e.rem = f                      -- set deactivation location
  end
end

----------------------------------------------------------------------
-- creates a new local variable given a name
-- * skips internal locals (those starting with '('), so internal
--   locals never needs a corresponding adjustlocalvars() call
-- * special is true for "self" which must not be optimized
-- * used in fornum(), forlist(), parlist(), body()
----------------------------------------------------------------------

local function f(e, t)
  if v.sub(e, 1, 1) == "(" then  -- can skip internal locals
    return
  end
  m(e, t)
end

----------------------------------------------------------------------
-- search the local variable namespace of the given fs for a match
-- * returns localinfo index
-- * used only in singlevaraux()
----------------------------------------------------------------------

local function C(o, a)
  local t = o.bl
  local e
  if t then
    e = t.locallist
    while e do
      if e[a] then return e[a] end  -- found
      t = t.prev
      e = t and t.locallist
    end
  end
  e = o.locallist
  return e[a] or -1  -- found or not found (-1)
end

----------------------------------------------------------------------
-- handle locals, globals and upvalues and related processing
-- * search mechanism is recursive, calls itself to search parents
-- * used only in singlevar()
----------------------------------------------------------------------

local function v(t, o, e)
  if t == nil then  -- no more levels?
    e.k = "VGLOBAL"  -- default is global variable
    return "VGLOBAL"
  else
    local a = C(t, o)  -- look up at current level
    if a >= 0 then
      e.k = "VLOCAL"
      e.id = a
      --  codegen may need to deal with upvalue here
      return "VLOCAL"
    else  -- not found at current level; try upper one
      if v(t.prev, o, e) == "VGLOBAL" then
        return "VGLOBAL"
      end
      -- else was LOCAL or UPVAL, handle here
      e.k = "VUPVAL"  -- upvalue in this level
      return "VUPVAL"
    end--if v
  end--if fs
end

----------------------------------------------------------------------
-- consume a name token, creates a variable (global|local|upvalue)
-- * used in prefixexp(), funcname()
----------------------------------------------------------------------

local function K(a)
  local t = w()
  v(o, t, a)
  ------------------------------------------------------------------
  -- variable tracking
  ------------------------------------------------------------------
  if a.k == "VGLOBAL" then
    -- if global being accessed, keep track of it by creating an object
    local e = D[t]
    if not e then
      e = #_ + 1
      _[e] = {                -- new global variable object
        name = t,                    -- global variable name
        xref = { y },             -- xref, first value is declaration
      }
      D[t] = e           -- remember it
    else
      local e = _[e].xref
      e[#e + 1] = y           -- add xref
    end
  else
    -- local/upvalue is being accessed, keep track of it
    local e = a.id
    local e = l[e].xref
    e[#e + 1] = y             -- add xref
  end
end

--[[--------------------------------------------------------------------
-- state management functions with open/close pairs
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- enters a code unit, initializes elements
----------------------------------------------------------------------

local function y(t)
  local e = {}  -- per-block state
  e.isbreakable = t
  e.prev = o.bl
  e.locallist = {}
  o.bl = e
end

----------------------------------------------------------------------
-- leaves a code unit, close any upvalues
----------------------------------------------------------------------

local function v()
  local e = o.bl
  L()
  o.bl = e.prev
end

----------------------------------------------------------------------
-- opening of a function
-- * top_fs is only for anchoring the top fs, so that parser() can
--   return it to the caller function along with useful output
-- * used in parser() and body()
----------------------------------------------------------------------

local function G()
  local e  -- per-function state
  if not o then  -- top_fs is created early
    e = P
  else
    e = {}
  end
  e.prev = o  -- linked list of function states
  e.bl = nil
  e.locallist = {}
  o = e
end

----------------------------------------------------------------------
-- closing of a function
-- * used in parser() and body()
----------------------------------------------------------------------

local function Q()
  L()
  o = o.prev
end

--[[--------------------------------------------------------------------
-- other parsing functions
-- * for table constructor, parameter list, argument list
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- parse a function name suffix, for function call specifications
-- * used in primaryexp(), funcname()
----------------------------------------------------------------------

local function C(t)
  -- field -> ['.' | ':'] NAME
  local a = {}
  e()  -- skip the dot or colon
  U(a)
  t.k = "VINDEXED"
end

----------------------------------------------------------------------
-- parse a table indexing suffix, for constructors, expressions
-- * used in recfield(), primaryexp()
----------------------------------------------------------------------

local function J(t)
  -- index -> '[' expr ']'
  e()  -- skip the '['
  r(t)
  n("]")
end

----------------------------------------------------------------------
-- parse a table record (hash) field
-- * used in constructor()
----------------------------------------------------------------------

local function W(e)
  -- recfield -> (NAME | '['exp1']') = exp1
  local e, a = {}, {}
  if t == "<name>" then
    U(e)
  else-- tok == '['
    J(e)
  end
  n("=")
  r(a)
end

----------------------------------------------------------------------
-- emit a set list instruction if enough elements (LFIELDS_PER_FLUSH)
-- * note: retained in this skeleton because it modifies cc.v.k
-- * used in constructor()
----------------------------------------------------------------------

local function a(e)
  if e.v.k == "VVOID" then return end  -- there is no list item
  e.v.k = "VVOID"
end

----------------------------------------------------------------------
-- parse a table list (array) field
-- * used in constructor()
----------------------------------------------------------------------

local function L(e)
  r(e.v)
end

----------------------------------------------------------------------
-- parse a table constructor
-- * used in funcargs(), simpleexp()
----------------------------------------------------------------------

local function B(a)
  -- constructor -> '{' [ field { fieldsep field } [ fieldsep ] ] '}'
  -- field -> recfield | listfield
  -- fieldsep -> ',' | ';'
  local o = d
  local e = {}
  e.v = {}
  e.t = a
  a.k = "VRELOCABLE"
  e.v.k = "VVOID"
  n("{")
  repeat
    if t == "}" then break end
    -- closelistfield(cc) here
    local t = t
    if t == "<name>" then  -- may be listfields or recfields
      if Z() ~= "=" then  -- look ahead: expression?
        L(e)
      else
        W(e)
      end
    elseif t == "[" then  -- constructor_item -> recfield
      W(e)
    else  -- constructor_part -> listfield
      L(e)
    end
  until not i(",") and not i(";")
  c("}", "{", o)
  -- lastlistfield(cc) here
end

----------------------------------------------------------------------
-- parse the arguments (parameters) of a function declaration
-- * used in body()
----------------------------------------------------------------------

local function Z()
  -- parlist -> [ param { ',' param } ]
  local a = 0
  if t ~= ")" then  -- is 'parlist' not empty?
    repeat
      local t = t
      if t == "<name>" then  -- param -> NAME
        m(w())
        a = a + 1
      elseif t == "..." then
        e()
        o.is_vararg = true
      else
        h("<name> or '...' expected")
      end
    until o.is_vararg or not i(",")
  end--if
  j(a)
end

----------------------------------------------------------------------
-- parse the parameters of a function call
-- * contrast with parlist(), used in function declarations
-- * used in primaryexp()
----------------------------------------------------------------------

local function W(n)
  local a = {}
  local i = d
  local o = t
  if o == "(" then  -- funcargs -> '(' [ explist1 ] ')'
    if i ~= Y then
      h("ambiguous syntax (function call x new statement)")
    end
    e()
    if t == ")" then  -- arg list is empty?
      a.k = "VVOID"
    else
      q(a)
    end
    c(")", "(", i)
  elseif o == "{" then  -- funcargs -> constructor
    B(a)
  elseif o == "<string>" then  -- funcargs -> STRING
    F(a, T)
    e()  -- must use 'seminfo' before 'next'
  else
    h("function arguments expected")
    return
  end--if c
  n.k = "VCALL"
end

--[[--------------------------------------------------------------------
-- mostly expression functions
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- parses an expression in parentheses or a single variable
-- * used in primaryexp()
----------------------------------------------------------------------

local function Y(a)
  -- prefixexp -> NAME | '(' expr ')'
  local t = t
  if t == "(" then
    local t = d
    e()
    r(a)
    c(")", "(", t)
  elseif t == "<name>" then
    K(a)
  else
    h("unexpected symbol")
  end--if c
end

----------------------------------------------------------------------
-- parses a prefixexp (an expression in parentheses or a single
-- variable) or a function call specification
-- * used in simpleexp(), assignment(), expr_stat()
----------------------------------------------------------------------

local function L(a)
  -- primaryexp ->
  --    prefixexp { '.' NAME | '[' exp ']' | ':' NAME funcargs | funcargs }
  Y(a)
  while true do
    local t = t
    if t == "." then  -- field
      C(a)
    elseif t == "[" then  -- '[' exp1 ']'
      local e = {}
      J(e)
    elseif t == ":" then  -- ':' NAME funcargs
      local t = {}
      e()
      U(t)
      W(a)
    elseif t == "(" or t == "<string>" or t == "{" then  -- funcargs
      W(a)
    else
      return
    end--if c
  end--while
end

----------------------------------------------------------------------
-- parses general expression types, constants handled here
-- * used in subexpr()
----------------------------------------------------------------------

local function U(a)
  -- simpleexp -> NUMBER | STRING | NIL | TRUE | FALSE | ... |
  --              constructor | FUNCTION body | primaryexp
  local t = t
  if t == "<number>" then
    a.k = "VKNUM"
  elseif t == "<string>" then
    F(a, T)
  elseif t == "nil" then
    a.k = "VNIL"
  elseif t == "true" then
    a.k = "VTRUE"
  elseif t == "false" then
    a.k = "VFALSE"
  elseif t == "..." then  -- vararg
    X(o.is_vararg == true,
                    "cannot use '...' outside a vararg function");
    a.k = "VVARARG"
  elseif t == "{" then  -- constructor
    B(a)
    return
  elseif t == "function" then
    e()
    O(a, false, d)
    return
  else
    L(a)
    return
  end--if c
  e()
end

------------------------------------------------------------------------
-- Parse subexpressions. Includes handling of unary operators and binary
-- operators. A subexpr is given the rhs priority level of the operator
-- immediately left of it, if any (limit is -1 if none,) and if a binop
-- is found, limit is compared with the lhs priority level of the binop
-- in order to determine which executes first.
-- * recursively called
-- * used in expr()
------------------------------------------------------------------------

local function T(o, i)
  -- subexpr -> (simpleexp | unop subexpr) { binop subexpr }
  --   * where 'binop' is any binary operator with a priority
  --     higher than 'limit'
  local a = t
  local n = te[a]
  if n then
    e()
    T(o, ee)
  else
    U(o)
  end
  -- expand while operators have priorities higher than 'limit'
  a = t
  local t = H[a]
  while t and t > i do
    local o = {}
    e()
    -- read sub-expression with higher priority
    local e = T(o, V[a])
    a = e
    t = H[a]
  end
  return a  -- return first untreated operator
end

----------------------------------------------------------------------
-- Expression parsing starts here. Function subexpr is entered with the
-- left operator (which is non-existent) priority of -1, which is lower
-- than all actual operators. Expr information is returned in parm v.
-- * used in cond(), explist1(), index(), recfield(), listfield(),
--   prefixexp(), while_stat(), exp1()
----------------------------------------------------------------------

-- this is a forward-referenced local
function r(e)
  -- expr -> subexpr
  T(e, 0)
end

--[[--------------------------------------------------------------------
-- third level parsing functions
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- parse a variable assignment sequence
-- * recursively called
-- * used in expr_stat()
------------------------------------------------------------------------

local function H(e)
  local t = {}
  local e = e.v.k
  X(e == "VLOCAL" or e == "VUPVAL" or e == "VGLOBAL"
                  or e == "VINDEXED", "syntax error")
  if i(",") then  -- assignment -> ',' primaryexp assignment
    local e = {}  -- expdesc
    e.v = {}
    L(e.v)
    -- lparser.c deals with some register usage conflict here
    H(e)
  else  -- assignment -> '=' explist1
    n("=")
    q(t)
    return  -- avoid default
  end
  t.k = "VNONRELOC"
end

----------------------------------------------------------------------
-- parse a for loop body for both versions of the for loop
-- * used in fornum(), forlist()
----------------------------------------------------------------------

local function a(e, t)
  -- forbody -> DO block
  n("do")
  y(false)  -- scope for declared variables
  j(e)
  g()
  v()  -- end of scope for declared variables
end

----------------------------------------------------------------------
-- parse a numerical for loop, calls forbody()
-- * used in for_stat()
----------------------------------------------------------------------

local function U(e)
  -- fornum -> NAME = exp1, exp1 [, exp1] DO body
  local t = u
  f("(for index)")
  f("(for limit)")
  f("(for step)")
  m(e)
  n("=")
  N()  -- initial value
  n(",")
  N()  -- limit
  if i(",") then
    N()  -- optional step
  else
    -- default step = 1
  end
  a(1, true)
end

----------------------------------------------------------------------
-- parse a generic for loop, calls forbody()
-- * used in for_stat()
----------------------------------------------------------------------

local function W(e)
  -- forlist -> NAME {, NAME} IN explist1 DO body
  local t = {}
  -- create control variables
  f("(for generator)")
  f("(for state)")
  f("(for control)")
  -- create declared variables
  m(e)
  local e = 1
  while i(",") do
    m(w())
    e = e + 1
  end
  n("in")
  local o = u
  q(t)
  a(e, false)
end

----------------------------------------------------------------------
-- parse a function name specification
-- * used in func_stat()
----------------------------------------------------------------------

local function F(e)
  -- funcname -> NAME {field} [':' NAME]
  local a = false
  K(e)
  while t == "." do
    C(e)
  end
  if t == ":" then
    a = true
    C(e)
  end
  return a
end

----------------------------------------------------------------------
-- parse the single expressions needed in numerical for loops
-- * used in fornum()
----------------------------------------------------------------------

-- this is a forward-referenced local
function N()
  -- exp1 -> expr
  local e = {}
  r(e)
end

----------------------------------------------------------------------
-- parse condition in a repeat statement or an if control structure
-- * used in repeat_stat(), test_then_block()
----------------------------------------------------------------------

local function a()
  -- cond -> expr
  local e = {}
  r(e)  -- read condition
end

----------------------------------------------------------------------
-- parse part of an if control structure, including the condition
-- * used in if_stat()
----------------------------------------------------------------------

local function T()
  -- test_then_block -> [IF | ELSEIF] cond THEN block
  e()  -- skip IF or ELSEIF
  a()
  n("then")
  g()  -- 'then' part
end

----------------------------------------------------------------------
-- parse a local function statement
-- * used in local_stat()
----------------------------------------------------------------------

local function N()
  -- localfunc -> NAME body
  local t, e = {}
  m(w())
  t.k = "VLOCAL"
  j(1)
  O(e, false, d)
end

----------------------------------------------------------------------
-- parse a local variable declaration statement
-- * used in local_stat()
----------------------------------------------------------------------

local function C()
  -- localstat -> NAME {',' NAME} ['=' explist1]
  local e = 0
  local t = {}
  repeat
    m(w())
    e = e + 1
  until not i(",")
  if i("=") then
    q(t)
  else
    t.k = "VVOID"
  end
  j(e)
end

----------------------------------------------------------------------
-- parse a list of comma-separated expressions
-- * used in return_stat(), localstat(), funcargs(), assignment(),
--   forlist()
----------------------------------------------------------------------

-- this is a forward-referenced local
function q(e)
  -- explist1 -> expr { ',' expr }
  r(e)
  while i(",") do
    r(e)
  end
end

----------------------------------------------------------------------
-- parse function declaration body
-- * used in simpleexp(), localfunc(), func_stat()
----------------------------------------------------------------------

-- this is a forward-referenced local
function O(a, t, e)
  -- body ->  '(' parlist ')' chunk END
  G()
  n("(")
  if t then
    f("self", true)
    j(1)
  end
  Z()
  n(")")
  x()
  c("end", "function", e)
  Q()
end

----------------------------------------------------------------------
-- parse a code block or unit
-- * used in do_stat(), while_stat(), forbody(), test_then_block(),
--   if_stat()
----------------------------------------------------------------------

-- this is a forward-referenced local
function g()
  -- block -> chunk
  y(false)
  x()
  v()
end

--[[--------------------------------------------------------------------
-- second level parsing functions, all with '_stat' suffix
-- * since they are called via a table lookup, they cannot be local
--   functions (a lookup table of local functions might be smaller...)
-- * stat() -> *_stat()
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- initial parsing for a for loop, calls fornum() or forlist()
-- * removed 'line' parameter (used to set debug information only)
-- * used in stat()
----------------------------------------------------------------------

local function f()
  -- stat -> for_stat -> FOR (fornum | forlist) END
  local o = u
  y(true)  -- scope for loop and control variables
  e()  -- skip 'for'
  local a = w()  -- first variable name
  local e = t
  if e == "=" then
    U(a)
  elseif e == "," or e == "in" then
    W(a)
  else
    h("'=' or 'in' expected")
  end
  c("end", "for", o)
  v()  -- loop scope (`break' jumps to this point)
end

----------------------------------------------------------------------
-- parse a while-do control structure, body processed by block()
-- * used in stat()
----------------------------------------------------------------------

local function m()
  -- stat -> while_stat -> WHILE cond DO block END
  local t = u
  e()  -- skip WHILE
  a()  -- parse condition
  y(true)
  n("do")
  g()
  c("end", "while", t)
  v()
end

----------------------------------------------------------------------
-- parse a repeat-until control structure, body parsed by chunk()
-- * originally, repeatstat() calls breakstat() too if there is an
--   upvalue in the scope block; nothing is actually lexed, it is
--   actually the common code in breakstat() for closing of upvalues
-- * used in stat()
----------------------------------------------------------------------

local function w()
  -- stat -> repeat_stat -> REPEAT block UNTIL cond
  local t = u
  y(true)  -- loop block
  y(false)  -- scope block
  e()  -- skip REPEAT
  x()
  c("until", "repeat", t)
  a()
  -- close upvalues at scope level below
  v()  -- finish scope
  v()  -- finish loop
end

----------------------------------------------------------------------
-- parse an if control structure
-- * used in stat()
----------------------------------------------------------------------

local function j()
  -- stat -> if_stat -> IF cond THEN block
  --                    {ELSEIF cond THEN block} [ELSE block] END
  local a = u
  local o = {}
  T()  -- IF cond THEN block
  while t == "elseif" do
    T()  -- ELSEIF cond THEN block
  end
  if t == "else" then
    e()  -- skip ELSE
    g()  -- 'else' part
  end
  c("end", "if", a)
end

----------------------------------------------------------------------
-- parse a return statement
-- * used in stat()
----------------------------------------------------------------------

local function v()
  -- stat -> return_stat -> RETURN explist
  local a = {}
  e()  -- skip RETURN
  local e = t
  if R[e] or e == ";" then
    -- return no values
  else
    q(a)  -- optional return values
  end
end

----------------------------------------------------------------------
-- parse a break statement
-- * used in stat()
----------------------------------------------------------------------

local function y()
  -- stat -> break_stat -> BREAK
  local t = o.bl
  e()  -- skip BREAK
  while t and not t.isbreakable do -- find a breakable block
    t = t.prev
  end
  if not t then
    h("no loop to break")
  end
end

----------------------------------------------------------------------
-- parse a function call with no returns or an assignment statement
-- * the struct with .prev is used for name searching in lparse.c,
--   so it is retained for now; present in assignment() also
-- * used in stat()
----------------------------------------------------------------------

local function r()
  local t = s - 1
  -- stat -> expr_stat -> func | assignment
  local e = {}
  e.v = {}
  L(e.v)
  if e.v.k == "VCALL" then  -- stat -> func
    -- call statement uses no results
    z[t] = "call"
  else  -- stat -> assignment
    e.prev = nil
    H(e)
    z[t] = "assign"
  end
end

----------------------------------------------------------------------
-- parse a function statement
-- * used in stat()
----------------------------------------------------------------------

local function h()
  -- stat -> function_stat -> FUNCTION funcname body
  local o = u
  local a, t = {}, {}
  e()  -- skip FUNCTION
  local e = F(a)
  O(t, e, o)
end

----------------------------------------------------------------------
-- parse a simple block enclosed by a DO..END pair
-- * used in stat()
----------------------------------------------------------------------

local function a()
  -- stat -> do_stat -> DO block END
  local t = u
  e()  -- skip DO
  g()
  c("end", "do", t)
end

----------------------------------------------------------------------
-- parse a statement starting with LOCAL
-- * used in stat()
----------------------------------------------------------------------

local function n()
  -- stat -> local_stat -> LOCAL FUNCTION localfunc
  --                    -> LOCAL localstat
  e()  -- skip LOCAL
  if i("function") then  -- local function?
    N()
  else
    C()
  end
end

--[[--------------------------------------------------------------------
-- main functions, top level parsing functions
-- * accessible functions are: init(lexer), parser()
-- * [entry] -> parser() -> chunk() -> stat()
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- initial parsing for statements, calls '_stat' suffixed functions
-- * used in chunk()
----------------------------------------------------------------------

local n = {             -- lookup for calls in stat()
  ["if"] = j,
  ["while"] = m,
  ["do"] = a,
  ["for"] = f,
  ["repeat"] = w,
  ["function"] = h,
  ["local"] = n,
  ["return"] = v,
  ["break"] = y,
}

local function a()
  -- stat -> if_stat while_stat do_stat for_stat repeat_stat
  --         function_stat local_stat return_stat break_stat
  --         expr_stat
  u = d  -- may be needed for error messages
  local e = t
  local t = n[e]
  -- handles: if while do for repeat function local return break
  if t then
    z[s - 1] = e
    t()
    -- return or break must be last statement
    if e == "return" or e == "break" then return true end
  else
    r()
  end
  return false
end

----------------------------------------------------------------------
-- parse a chunk, which consists of a bunch of statements
-- * used in parser(), body(), block(), repeat_stat()
----------------------------------------------------------------------

-- this is a forward-referenced local
function x()
  -- chunk -> { stat [';'] }
  local e = false
  while not e and not R[t] do
    e = a()
    i(";")
  end
end

----------------------------------------------------------------------
-- performs parsing, returns parsed data structure
----------------------------------------------------------------------

function parser()
  G()
  o.is_vararg = true  -- main func. is always vararg
  e()  -- read first token
  x()
  M("<eof>")
  Q()
  return {  -- return everything
    globalinfo = _,
    localinfo = l,
    statinfo = z,
    toklist = E,
    seminfolist = k,
    toklnlist = A,
    xreflist = S,
  }
end

----------------------------------------------------------------------
-- initialization function
----------------------------------------------------------------------

function init(e, i, n)
  s = 1                      -- token position
  P = {}                   -- reset top level function state
  ------------------------------------------------------------------
  -- set up grammar-only token tables; impedance-matching...
  -- note that constants returned by the lexer is source-level, so
  -- for now, fake(!) constant tokens (TK_NUMBER|TK_STRING|TK_LSTRING)
  ------------------------------------------------------------------
  local t = 1
  E, k, A, S = {}, {}, {}, {}
  for a = 1, #e do
    local e = e[a]
    local o = true
    if e == "TK_KEYWORD" or e == "TK_OP" then
      e = i[a]
    elseif e == "TK_NAME" then
      e = "<name>"
      k[t] = i[a]
    elseif e == "TK_NUMBER" then
      e = "<number>"
      k[t] = 0  -- fake!
    elseif e == "TK_STRING" or e == "TK_LSTRING" then
      e = "<string>"
      k[t] = ""  -- fake!
    elseif e == "TK_EOS" then
      e = "<eof>"
    else
      -- non-grammar tokens; ignore them
      o = false
    end
    if o then  -- set rest of the information
      E[t] = e
      A[t] = n[a]
      S[t] = a
      t = t + 1
    end
  end--for
  ------------------------------------------------------------------
  -- initialize data structures for variable tracking
  ------------------------------------------------------------------
  _, D, l = {}, {}, {}
  b, I = {}, {}
  z = {}  -- experimental
end
--end of inserted module
end

-- preload function for module optlex
p.optlex =
function()
--start of inserted module
module "optlex"

local c = a.require "string"
local i = c.match
local e = c.sub
local h = c.find
local d = c.rep
local f

------------------------------------------------------------------------
-- variables and data structures
------------------------------------------------------------------------

-- error function, can override by setting own function into module
error = a.error

warn = {}                       -- table for warning flags

local n, o, l    -- source lists

local y = {          -- significant (grammar) tokens
  TK_KEYWORD = true,
  TK_NAME = true,
  TK_NUMBER = true,
  TK_STRING = true,
  TK_LSTRING = true,
  TK_OP = true,
  TK_EOS = true,
}
local v = {          -- whitespace (non-grammar) tokens
  TK_COMMENT = true,
  TK_LCOMMENT = true,
  TK_EOL = true,
  TK_SPACE = true,
}

local r               -- for extra information

------------------------------------------------------------------------
-- true if current token is at the start of a line
-- * skips over deleted tokens via recursion
------------------------------------------------------------------------

local function b(e)
  local t = n[e - 1]
  if e <= 1 or t == "TK_EOL" then
    return true
  elseif t == "" then
    return b(e - 1)
  end
  return false
end

------------------------------------------------------------------------
-- true if current token is at the end of a line
-- * skips over deleted tokens via recursion
------------------------------------------------------------------------

local function g(t)
  local e = n[t + 1]
  if t >= #n or e == "TK_EOL" or e == "TK_EOS" then
    return true
  elseif e == "" then
    return g(t + 1)
  end
  return false
end

------------------------------------------------------------------------
-- counts comment EOLs inside a long comment
-- * in order to keep line numbering, EOLs need to be reinserted
------------------------------------------------------------------------

local function A(a)
  local t = #i(a, "^%-%-%[=*%[")
  local a = e(a, t + 1, -(t - 1))  -- remove delims
  local e, t = 1, 0
  while true do
    local a, n, i, o = h(a, "([\r\n])([\r\n]?)", e)
    if not a then break end     -- if no matches, done
    e = a + 1
    t = t + 1
    if #o > 0 and i ~= o then   -- skip CRLF or LFCR
      e = e + 1
    end
  end
  return t
end

------------------------------------------------------------------------
-- compares two tokens (i, j) and returns the whitespace required
-- * see documentation for a reference table of interactions
-- * only two grammar/real tokens are being considered
-- * if "", no separation is needed
-- * if " ", then at least one whitespace (or EOL) is required
-- * NOTE: this doesn't work at the start or the end or for EOS!
------------------------------------------------------------------------

local function k(s, h)
  local a = i
  local t, e = n[s], n[h]
  --------------------------------------------------------------------
  if t == "TK_STRING" or t == "TK_LSTRING" or
     e == "TK_STRING" or e == "TK_LSTRING" then
    return ""
  --------------------------------------------------------------------
  elseif t == "TK_OP" or e == "TK_OP" then
    if (t == "TK_OP" and (e == "TK_KEYWORD" or e == "TK_NAME")) or
       (e == "TK_OP" and (t == "TK_KEYWORD" or t == "TK_NAME")) then
      return ""
    end
    if t == "TK_OP" and e == "TK_OP" then
      -- for TK_OP/TK_OP pairs, see notes in technotes.txt
      local t, e = o[s], o[h]
      if (a(t, "^%.%.?$") and a(e, "^%.")) or
         (a(t, "^[~=<>]$") and e == "=") or
         (t == "[" and (e == "[" or e == "=")) then
        return " "
      end
      return ""
    end
    -- "TK_OP" + "TK_NUMBER" case
    local t = o[s]
    if e == "TK_OP" then t = o[h] end
    if a(t, "^%.%.?%.?$") then
      return " "
    end
    return ""
  --------------------------------------------------------------------
  else-- "TK_KEYWORD" | "TK_NAME" | "TK_NUMBER" then
    return " "
  --------------------------------------------------------------------
  end
end

------------------------------------------------------------------------
-- repack tokens, removing deletions caused by optimization process
------------------------------------------------------------------------

local function w()
  local h, s, a = {}, {}, {}
  local e = 1
  for t = 1, #n do
    local i = n[t]
    if i ~= "" then
      h[e], s[e], a[e] = i, o[t], l[t]
      e = e + 1
    end
  end
  n, o, l = h, s, a
end

------------------------------------------------------------------------
-- number optimization
-- * optimization using string formatting functions is one way of doing
--   this, but here, we consider all cases and handle them separately
--   (possibly an idiotic approach...)
-- * scientific notation being generated is not in canonical form, this
--   may or may not be a bad thing
-- * note: intermediate portions need to fit into a normal number range
-- * optimizations can be divided based on number patterns:
-- * hexadecimal:
--   (1) no need to remove leading zeros, just skip to (2)
--   (2) convert to integer if size equal or smaller
--       * change if equal size -> lose the 'x' to reduce entropy
--   (3) number is then processed as an integer
--   (4) note: does not make 0[xX] consistent
-- * integer:
--   (1) note: includes anything with trailing ".", ".0", ...
--   (2) remove useless fractional part, if present, e.g. 123.000
--   (3) remove leading zeros, e.g. 000123
--   (4) switch to scientific if shorter, e.g. 123000 -> 123e3
-- * with fraction:
--   (1) split into digits dot digits
--   (2) if no integer portion, take as zero (can omit later)
--   (3) handle degenerate .000 case, after which the fractional part
--       must be non-zero (if zero, it's matched as an integer)
--   (4) remove trailing zeros for fractional portion
--   (5) p.q where p > 0 and q > 0 cannot be shortened any more
--   (6) otherwise p == 0 and the form is .q, e.g. .000123
--   (7) if scientific shorter, convert, e.g. .000123 -> 123e-6
-- * scientific:
--   (1) split into (digits dot digits) [eE] ([+-] digits)
--   (2) if significand has ".", shift it out so it becomes an integer
--   (3) if significand is zero, just use zero
--   (4) remove leading zeros for significand
--   (5) shift out trailing zeros for significand
--   (6) examine exponent and determine which format is best:
--       integer, with fraction, scientific
------------------------------------------------------------------------

local function O(h)
  local t = o[h]      -- 'before'
  local t = t              -- working representation
  local n                       -- 'after', if better
  --------------------------------------------------------------------
  if i(t, "^0[xX]") then            -- hexadecimal number
    local e = a.tostring(a.tonumber(t))
    if #e <= #t then
      t = e  -- change to integer, AND continue
    else
      return  -- no change; stick to hex
    end
  end
  --------------------------------------------------------------------
  if i(t, "^%d+%.?0*$") then        -- integer or has useless frac
    t = i(t, "^(%d+)%.?0*$")  -- int portion only
    if t + 0 > 0 then
      t = i(t, "^0*([1-9]%d*)$")  -- remove leading zeros
      local o = #i(t, "0*$")
      local a = a.tostring(o)
      if o > #a + 1 then  -- scientific is shorter
        t = e(t, 1, #t - o).."e"..a
      end
      n = t
    else
      n = "0"  -- basic zero
    end
  --------------------------------------------------------------------
  elseif not i(t, "[eE]") then      -- number with fraction part
    local o, t = i(t, "^(%d*)%.(%d+)$")  -- split
    if o == "" then o = 0 end  -- int part zero
    if t + 0 == 0 and o == 0 then
      n = "0"  -- degenerate .000 case
    else
      -- now, q > 0 holds and p is a number
      local s = #i(t, "0*$")  -- remove trailing zeros
      if s > 0 then
        t = e(t, 1, #t - s)
      end
      -- if p > 0, nothing else we can do to simplify p.q case
      if o + 0 > 0 then
        n = o.."."..t
      else
        n = "."..t  -- tentative, e.g. .000123
        local o = #i(t, "^0*")  -- # leading spaces
        local o = #t - o            -- # significant digits
        local a = a.tostring(#t)
        -- e.g. compare 123e-6 versus .000123
        if o + 2 + #a < 1 + #t then
          n = e(t, -o).."e-"..a
        end
      end
    end
  --------------------------------------------------------------------
  else                                  -- scientific number
    local t, o = i(t, "^([^eE]+)[eE]([%+%-]?%d+)$")
    o = a.tonumber(o)
    -- if got ".", shift out fractional portion of significand
    local s, h = i(t, "^(%d*)%.(%d*)$")
    if s then
      o = o - #h
      t = s..h
    end
    if t + 0 == 0 then
      n = "0"  -- basic zero
    else
      local s = #i(t, "^0*")  -- remove leading zeros
      t = e(t, s + 1)
      s = #i(t, "0*$") -- shift out trailing zeros
      if s > 0 then
        t = e(t, 1, #t - s)
        o = o + s
      end
      -- examine exponent and determine which format is best
      local a = a.tostring(o)
      if o == 0 then  -- it's just an integer
        n = t
      elseif o > 0 and (o <= 1 + #a) then  -- a number
        n = t..d("0", o)
      elseif o < 0 and (o >= -#t) then  -- fraction, e.g. .123
        s = #t + o
        n = e(t, 1, s).."."..e(t, s + 1)
      elseif o < 0 and (#a >= -o - #t) then
        -- e.g. compare 1234e-5 versus .01234
        -- gives: #sig + 1 + #nex >= 1 + (-ex - #sig) + #sig
        --     -> #nex >= -ex - #sig
        s = -o - #t
        n = "."..d("0", s)..t
      else  -- non-canonical scientific representation
        n = t.."e"..o
      end
    end--if sig
  end
  --------------------------------------------------------------------
  if n and n ~= o[h] then
    if r then
      f("<number> (line "..l[h]..") "..o[h].." -> "..n)
      r = r + 1
    end
    o[h] = n
  end
end

------------------------------------------------------------------------
-- string optimization
-- * note: works on well-formed strings only!
-- * optimizations on characters can be summarized as follows:
--   \a\b\f\n\r\t\v -- no change
--   \\ -- no change
--   \"\' -- depends on delim, other can remove \
--   \[\] -- remove \
--   \<char> -- general escape, remove \
--   \<eol> -- normalize the EOL only
--   \ddd -- if \a\b\f\n\r\t\v, change to latter
--           if other < ascii 32, keep ddd but zap leading zeros
--                                but cannot have following digits
--           if >= ascii 32, translate it into the literal, then also
--                           do escapes for \\,\",\' cases
--   <other> -- no change
-- * switch delimiters if string becomes shorter
------------------------------------------------------------------------

local function E(u)
  local t = o[u]
  local s = e(t, 1, 1)                 -- delimiter used
  local w = (s == "'") and '"' or "'"  -- opposite " <-> '
  local t = e(t, 2, -2)                    -- actual string
  local a = 1
  local m, d = 0, 0                -- "/' counts
  --------------------------------------------------------------------
  while a <= #t do
    local u = e(t, a, a)
    ----------------------------------------------------------------
    if u == "\\" then                   -- escaped stuff
      local o = a + 1
      local r = e(t, o, o)
      local n = h("abfnrtv\\\n\r\"\'0123456789", r, 1, true)
      ------------------------------------------------------------
      if not n then                     -- \<char> -- remove \
        t = e(t, 1, a - 1)..e(t, o)
        a = a + 1
      ------------------------------------------------------------
      elseif n <= 8 then                -- \a\b\f\n\r\t\v\\
        a = a + 2                       -- no change
      ------------------------------------------------------------
      elseif n <= 10 then               -- \<eol> -- normalize EOL
        local i = e(t, o, o + 1)
        if i == "\r\n" or i == "\n\r" then
          t = e(t, 1, a).."\n"..e(t, o + 2)
        elseif n == 10 then  -- \r case
          t = e(t, 1, a).."\n"..e(t, o + 1)
        end
        a = a + 2
      ------------------------------------------------------------
      elseif n <= 12 then               -- \"\' -- remove \ for ndelim
        if r == s then
          m = m + 1
          a = a + 2
        else
          d = d + 1
          t = e(t, 1, a - 1)..e(t, o)
          a = a + 1
        end
      ------------------------------------------------------------
      else                              -- \ddd -- various steps
        local n = i(t, "^(%d%d?%d?)", o)
        o = a + 1 + #n                  -- skip to location
        local l = n + 0
        local r = c.char(l)
        local h = h("\a\b\f\n\r\t\v", r, 1, true)
        if h then                       -- special escapes
          n = "\\"..e("abfnrtv", h, h)
        elseif l < 32 then             -- normalized \ddd
          if i(e(t, o, o), "%d") then
            -- if a digit follows, \ddd cannot be shortened
            n = "\\"..n
          else
            n = "\\"..l
          end
        elseif r == s then         -- \<delim>
          n = "\\"..r
          m = m + 1
        elseif r == "\\" then          -- \\
          n = "\\\\"
        else                            -- literal character
          n = r
          if r == w then
            d = d + 1
          end
        end
        t = e(t, 1, a - 1)..n..e(t, o)
        a = a + #n
      ------------------------------------------------------------
      end--if p
    ----------------------------------------------------------------
    else-- c ~= "\\"                    -- <other> -- no change
      a = a + 1
      if u == w then  -- count ndelim, for switching delimiters
        d = d + 1
      end
    ----------------------------------------------------------------
    end--if c
  end--while
  --------------------------------------------------------------------
  -- switching delimiters, a long-winded derivation:
  -- (1) delim takes 2+2*c_delim bytes, ndelim takes c_ndelim bytes
  -- (2) delim becomes c_delim bytes, ndelim becomes 2+2*c_ndelim bytes
  -- simplifying the condition (1)>(2) --> c_delim > c_ndelim
  if m > d then
    a = 1
    while a <= #t do
      local o, n, i = h(t, "([\'\"])", a)
      if not o then break end
      if i == s then                -- \<delim> -> <delim>
        t = e(t, 1, o - 2)..e(t, o)
        a = o
      else-- r == ndelim                -- <ndelim> -> \<ndelim>
        t = e(t, 1, o - 1).."\\"..e(t, o)
        a = o + 2
      end
    end--while
    s = w  -- actually change delimiters
  end
  --------------------------------------------------------------------
  t = s..t..s
  if t ~= o[u] then
    if r then
      f("<string> (line "..l[u]..") "..o[u].." -> "..t)
      r = r + 1
    end
    o[u] = t
  end
end

------------------------------------------------------------------------
-- long string optimization
-- * note: warning flagged if trailing whitespace found, not trimmed
-- * remove first optional newline
-- * normalize embedded newlines
-- * reduce '=' separators in delimiters if possible
------------------------------------------------------------------------

local function T(u)
  local t = o[u]
  local r = i(t, "^%[=*%[")  -- cut out delimiters
  local a = #r
  local c = e(t, -a, -1)
  local s = e(t, a + 1, -(a + 1))  -- lstring without delims
  local n = ""
  local t = 1
  --------------------------------------------------------------------
  while true do
    local a, o, r, h = h(s, "([\r\n])([\r\n]?)", t)
    -- deal with a single line
    local o
    if not a then
      o = e(s, t)
    elseif a >= t then
      o = e(s, t, a - 1)
    end
    if o ~= "" then
      -- flag a warning if there are trailing spaces, won't optimize!
      if i(o, "%s+$") then
        warn.LSTRING = "trailing whitespace in long string near line "..l[u]
      end
      n = n..o
    end
    if not a then  -- done if no more EOLs
      break
    end
    -- deal with line endings, normalize them
    t = a + 1
    if a then
      if #h > 0 and r ~= h then  -- skip CRLF or LFCR
        t = t + 1
      end
      -- skip first newline, which can be safely deleted
      if not(t == 1 and t == a) then
        n = n.."\n"
      end
    end
  end--while
  --------------------------------------------------------------------
  -- handle possible deletion of one or more '=' separators
  if a >= 3 then
    local e, t = a - 1
    -- loop to test ending delimiter with less of '=' down to zero
    while e >= 2 do
      local a = "%]"..d("=", e - 2).."%]"
      if not i(n, a) then t = e end
      e = e - 1
    end
    if t then  -- change delimiters
      a = d("=", t - 2)
      r, c = "["..a.."[", "]"..a.."]"
    end
  end
  --------------------------------------------------------------------
  o[u] = r..n..c
end

------------------------------------------------------------------------
-- long comment optimization
-- * note: does not remove first optional newline
-- * trim trailing whitespace
-- * normalize embedded newlines
-- * reduce '=' separators in delimiters if possible
------------------------------------------------------------------------

local function q(u)
  local a = o[u]
  local r = i(a, "^%-%-%[=*%[")  -- cut out delimiters
  local t = #r
  local l = e(a, -(t - 2), -1)
  local s = e(a, t + 1, -(t - 1))  -- comment without delims
  local n = ""
  local a = 1
  --------------------------------------------------------------------
  while true do
    local o, t, r, h = h(s, "([\r\n])([\r\n]?)", a)
    -- deal with a single line, extract and check trailing whitespace
    local t
    if not o then
      t = e(s, a)
    elseif o >= a then
      t = e(s, a, o - 1)
    end
    if t ~= "" then
      -- trim trailing whitespace if non-empty line
      local a = i(t, "%s*$")
      if #a > 0 then t = e(t, 1, -(a + 1)) end
      n = n..t
    end
    if not o then  -- done if no more EOLs
      break
    end
    -- deal with line endings, normalize them
    a = o + 1
    if o then
      if #h > 0 and r ~= h then  -- skip CRLF or LFCR
        a = a + 1
      end
      n = n.."\n"
    end
  end--while
  --------------------------------------------------------------------
  -- handle possible deletion of one or more '=' separators
  t = t - 2
  if t >= 3 then
    local e, a = t - 1
    -- loop to test ending delimiter with less of '=' down to zero
    while e >= 2 do
      local t = "%]"..d("=", e - 2).."%]"
      if not i(n, t) then a = e end
      e = e - 1
    end
    if a then  -- change delimiters
      t = d("=", a - 2)
      r, l = "--["..t.."[", "]"..t.."]"
    end
  end
  --------------------------------------------------------------------
  o[u] = r..n..l
end

------------------------------------------------------------------------
-- short comment optimization
-- * trim trailing whitespace
------------------------------------------------------------------------

local function j(a)
  local t = o[a]
  local i = i(t, "%s*$")        -- just look from end of string
  if #i > 0 then
    t = e(t, 1, -(i + 1))      -- trim trailing whitespace
  end
  o[a] = t
end

------------------------------------------------------------------------
-- returns true if string found in long comment
-- * this is a feature to keep copyright or license texts
------------------------------------------------------------------------

local function _(o, t)
  if not o then return false end  -- option not set
  local a = i(t, "^%-%-%[=*%[")  -- cut out delimiters
  local a = #a
  local i = e(t, -a, -1)
  local e = e(t, a + 1, -(a - 1))  -- comment without delims
  if h(e, o, 1, true) then  -- try to match
    return true
  end
end

------------------------------------------------------------------------
-- main entry point
-- * currently, lexer processing has 2 passes
-- * processing is done on a line-oriented basis, which is easier to
--   grok due to the next point...
-- * since there are various options that can be enabled or disabled,
--   processing is a little messy or convoluted
------------------------------------------------------------------------

function optimize(t, s, i, h)
  --------------------------------------------------------------------
  -- set option flags
  --------------------------------------------------------------------
  local c = t["opt-comments"]
  local u = t["opt-whitespace"]
  local m = t["opt-emptylines"]
  local p = t["opt-eols"]
  local z = t["opt-strings"]
  local I = t["opt-numbers"]
  local x = t["opt-experimental"]
  local N = t.KEEP
  r = t.DETAILS and 0  -- upvalues for details display
  f = f or a.print
  if p then  -- forced settings, otherwise won't work properly
    c = true
    u = true
    m = true
  elseif x then
    u = true
  end
  --------------------------------------------------------------------
  -- variable initialization
  --------------------------------------------------------------------
  n, o, l                -- set source lists
    = s, i, h
  local t = 1                           -- token position
  local a, h                       -- current token
  local s    -- position of last grammar token
                -- on same line (for TK_SPACE stuff)
  --------------------------------------------------------------------
  -- changes a token, info pair
  --------------------------------------------------------------------
  local function i(i, a, e)
    e = e or t
    n[e] = i or ""
    o[e] = a or ""
  end
  --------------------------------------------------------------------
  -- experimental optimization for ';' operator
  --------------------------------------------------------------------
  if x then
    while true do
      a, h = n[t], o[t]
      if a == "TK_EOS" then           -- end of stream/pass
        break
      elseif a == "TK_OP" and h == ";" then
        -- ';' operator found, since it is entirely optional, set it
        -- as a space to let whitespace optimization do the rest
        i("TK_SPACE", " ")
      end
      t = t + 1
    end
    w()
  end
  --------------------------------------------------------------------
  -- processing loop (PASS 1)
  --------------------------------------------------------------------
  t = 1
  while true do
    a, h = n[t], o[t]
    ----------------------------------------------------------------
    local r = b(t)      -- set line begin flag
    if r then s = nil end
    ----------------------------------------------------------------
    if a == "TK_EOS" then             -- end of stream/pass
      break
    ----------------------------------------------------------------
    elseif a == "TK_KEYWORD" or       -- keywords, identifiers,
           a == "TK_NAME" or          -- operators
           a == "TK_OP" then
      -- TK_KEYWORD and TK_OP can't be optimized without a big
      -- optimization framework; it would be more of an optimizing
      -- compiler, not a source code compressor
      -- TK_NAME that are locals needs parser to analyze/optimize
      s = t
    ----------------------------------------------------------------
    elseif a == "TK_NUMBER" then      -- numbers
      if I then
        O(t)  -- optimize
      end
      s = t
    ----------------------------------------------------------------
    elseif a == "TK_STRING" or        -- strings, long strings
           a == "TK_LSTRING" then
      if z then
        if a == "TK_STRING" then
          E(t)  -- optimize
        else
          T(t)  -- optimize
        end
      end
      s = t
    ----------------------------------------------------------------
    elseif a == "TK_COMMENT" then     -- short comments
      if c then
        if t == 1 and e(h, 1, 1) == "#" then
          -- keep shbang comment, trim whitespace
          j(t)
        else
          -- safe to delete, as a TK_EOL (or TK_EOS) always follows
          i()  -- remove entirely
        end
      elseif u then        -- trim whitespace only
        j(t)
      end
    ----------------------------------------------------------------
    elseif a == "TK_LCOMMENT" then    -- long comments
      if _(N, h) then
        ------------------------------------------------------------
        -- if --keep, we keep a long comment if <msg> is found;
        -- this is a feature to keep copyright or license texts
        if u then          -- trim whitespace only
          q(t)
        end
        s = t
      elseif c then
        local e = A(h)
        ------------------------------------------------------------
        -- prepare opt_emptylines case first, if a disposable token
        -- follows, current one is safe to dump, else keep a space;
        -- it is implied that the operation is safe for '-', because
        -- current is a TK_LCOMMENT, and must be separate from a '-'
        if v[n[t + 1]] then
          i()  -- remove entirely
          a = ""
        else
          i("TK_SPACE", " ")
        end
        ------------------------------------------------------------
        -- if there are embedded EOLs to keep and opt_emptylines is
        -- disabled, then switch the token into one or more EOLs
        if not m and e > 0 then
          i("TK_EOL", d("\n", e))
        end
        ------------------------------------------------------------
        -- if optimizing whitespaces, force reinterpretation of the
        -- token to give a chance for the space to be optimized away
        if u and a ~= "" then
          t = t - 1  -- to reinterpret
        end
        ------------------------------------------------------------
      else                              -- disabled case
        if u then          -- trim whitespace only
          q(t)
        end
        s = t
      end
    ----------------------------------------------------------------
    elseif a == "TK_EOL" then         -- line endings
      if r and m then
        i()  -- remove entirely
      elseif h == "\r\n" or h == "\n\r" then
        -- normalize the rest of the EOLs for CRLF/LFCR only
        -- (note that TK_LCOMMENT can change into several EOLs)
        i("TK_EOL", "\n")
      end
    ----------------------------------------------------------------
    elseif a == "TK_SPACE" then       -- whitespace
      if u then
        if r or g(t) then
          -- delete leading and trailing whitespace
          i()  -- remove entirely
        else
          ------------------------------------------------------------
          -- at this point, since leading whitespace have been removed,
          -- there should be a either a real token or a TK_LCOMMENT
          -- prior to hitting this whitespace; the TK_LCOMMENT case
          -- only happens if opt_comments is disabled; so prev ~= nil
          local a = n[s]
          if a == "TK_LCOMMENT" then
            -- previous TK_LCOMMENT can abut with anything
            i()  -- remove entirely
          else
            -- prev must be a grammar token; consecutive TK_SPACE
            -- tokens is impossible when optimizing whitespace
            local e = n[t + 1]
            if v[e] then
              -- handle special case where a '-' cannot abut with
              -- either a short comment or a long comment
              if (e == "TK_COMMENT" or e == "TK_LCOMMENT") and
                 a == "TK_OP" and o[s] == "-" then
                -- keep token
              else
                i()  -- remove entirely
              end
            else--is_realtoken
              -- check a pair of grammar tokens, if can abut, then
              -- delete space token entirely, otherwise keep one space
              local e = k(s, t + 1)
              if e == "" then
                i()  -- remove entirely
              else
                i("TK_SPACE", " ")
              end
            end
          end
          ------------------------------------------------------------
        end
      end
    ----------------------------------------------------------------
    else
      error("unidentified token encountered")
    end
    ----------------------------------------------------------------
    t = t + 1
  end--while
  w()
  --------------------------------------------------------------------
  -- processing loop (PASS 2)
  --------------------------------------------------------------------
  if p then
    t = 1
    -- aggressive EOL removal only works with most non-grammar tokens
    -- optimized away because it is a rather simple scheme -- basically
    -- it just checks 'real' token pairs around EOLs
    if n[1] == "TK_COMMENT" then
      -- first comment still existing must be shbang, skip whole line
      t = 3
    end
    while true do
      a, h = n[t], o[t]
      --------------------------------------------------------------
      if a == "TK_EOS" then           -- end of stream/pass
        break
      --------------------------------------------------------------
      elseif a == "TK_EOL" then       -- consider each TK_EOL
        local a, e = n[t - 1], n[t + 1]
        if y[a] and y[e] then  -- sanity check
          local t = k(t - 1, t + 1)
          if t == "" or e == "TK_EOS" then
            i()  -- remove entirely
          end
        end
      end--if tok
      --------------------------------------------------------------
      t = t + 1
    end--while
    w()
  end
  --------------------------------------------------------------------
  if r and r > 0 then f() end -- spacing
  return n, o, l
end
--end of inserted module
end

-- preload function for module optparser
p.optparser =
function()
--start of inserted module
module "optparser"

local n = a.require "string"
local g = a.require "table"

----------------------------------------------------------------------
-- Letter frequencies for reducing symbol entropy (fixed version)
-- * Might help a wee bit when the output file is compressed
-- * See Wikipedia: http://en.wikipedia.org/wiki/Letter_frequencies
-- * We use letter frequencies according to a Linotype keyboard, plus
--   the underscore, and both lower case and upper case letters.
-- * The arrangement below (LC, underscore, %d, UC) is arbitrary.
-- * This is certainly not optimal, but is quick-and-dirty and the
--   process has no significant overhead
----------------------------------------------------------------------

local i = "etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"
local d = "etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"

-- names or identifiers that must be skipped
-- * the first two lines are for keywords
local A = {}
for e in n.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]], "%S+") do
  A[e] = true
end

------------------------------------------------------------------------
-- variables and data structures
------------------------------------------------------------------------

local h, c,             -- token lists (lexer output)
      s, k, v,      -- token lists (parser output)
      _, o,            -- variable information tables
      w,                         -- statment type table
      b, O,            -- unique name tables
      q,                          -- index of new variable names
      r                           -- list of output variables

----------------------------------------------------------------------
-- preprocess information table to get lists of unique names
----------------------------------------------------------------------

local function z(e)
  local i = {}
  for n = 1, #e do              -- enumerate info table
    local t = e[n]
    local o = t.name
    --------------------------------------------------------------------
    if not i[o] then         -- not found, start an entry
      i[o] = {
        decl = 0, token = 0, size = 0,
      }
    end
    --------------------------------------------------------------------
    local e = i[o]        -- count declarations, tokens, size
    e.decl = e.decl + 1
    local i = t.xref
    local a = #i
    e.token = e.token + a
    e.size = e.size + a * #o
    --------------------------------------------------------------------
    if t.decl then            -- if local table, create first,last pairs
      t.id = n
      t.xcount = a
      if a > 1 then        -- if ==1, means local never accessed
        t.first = i[2]
        t.last = i[a]
      end
    --------------------------------------------------------------------
    else                        -- if global table, add a back ref
      e.id = n
    end
    --------------------------------------------------------------------
  end--for
  return i
end

----------------------------------------------------------------------
-- calculate actual symbol frequencies, in order to reduce entropy
-- * this may help further reduce the size of compressed sources
-- * note that since parsing optimizations is put before lexing
--   optimizations, the frequency table is not exact!
-- * yes, this will miss --keep block comments too...
----------------------------------------------------------------------

local function I(e)
  local s = n.byte
  local n = n.char
  -- table of token classes to accept in calculating symbol frequency
  local t = {
    TK_KEYWORD = true, TK_NAME = true, TK_NUMBER = true,
    TK_STRING = true, TK_LSTRING = true,
  }
  if not e["opt-comments"] then
    t.TK_COMMENT = true
    t.TK_LCOMMENT = true
  end
  --------------------------------------------------------------------
  -- create a new table and remove any original locals by filtering
  --------------------------------------------------------------------
  local a = {}
  for e = 1, #h do
    a[e] = c[e]
  end
  for e = 1, #o do              -- enumerate local info table
    local e = o[e]
    local t = e.xref
    for e = 1, e.xcount do
      local e = t[e]
      a[e] = ""                  -- remove locals
    end
  end
  --------------------------------------------------------------------
  local e = {}                       -- reset symbol frequency table
  for t = 0, 255 do e[t] = 0 end
  for o = 1, #h do                -- gather symbol frequency
    local o, a = h[o], a[o]
    if t[o] then
      for t = 1, #a do
        local t = s(a, t)
        e[t] = e[t] + 1
      end
    end--if
  end--for
  --------------------------------------------------------------------
  -- function to re-sort symbols according to actual frequencies
  --------------------------------------------------------------------
  local function a(o)
    local t = {}
    for a = 1, #o do              -- prepare table to sort
      local o = s(o, a)
      t[a] = { c = o, freq = e[o], }
    end
    g.sort(t,                 -- sort selected symbols
      function(t, e)
        return t.freq > e.freq
      end
    )
    local e = {}                 -- reconstitute the string
    for a = 1, #t do
      e[a] = n(t[a].c)
    end
    return g.concat(e)
  end
  --------------------------------------------------------------------
  i = a(i)             -- change letter arrangement
  d = a(d)
end

----------------------------------------------------------------------
-- returns a string containing a new local variable name to use, and
-- a flag indicating whether it collides with a global variable
-- * trapping keywords and other names like 'self' is done elsewhere
----------------------------------------------------------------------

local function S()
  local t
  local s, h = #i, #d
  local e = q
  if e < s then                  -- single char
    e = e + 1
    t = n.sub(i, e, e)
  else                                  -- longer names
    local o, a = s, 1       -- calculate # chars fit
    repeat
      e = e - o
      o = o * h
      a = a + 1
    until o > e
    local o = e % s              -- left side cycles faster
    e = (e - o) / s              -- do first char first
    o = o + 1
    t = n.sub(i, o, o)
    while a > 1 do
      local o = e % h
      e = (e - o) / h
      o = o + 1
      t = t..n.sub(d, o, o)
      a = a - 1
    end
  end
  q = q + 1
  return t, b[t] ~= nil
end

----------------------------------------------------------------------
-- calculate and print some statistics
-- * probably better in main source, put here for now
----------------------------------------------------------------------

local function N(T, I, O, i)
  local e = y or a.print
  local t = n.format
  local f = i.DETAILS
  if i.QUIET then return end
  local w , y, p, A, _,  -- stats needed
        j, v, m, E, z,
        s, c, l, q, x,
        h, u, d, b, k
    = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  local function i(e, t)              -- safe average function
    if e == 0 then return 0 end
    return t / e
  end
  --------------------------------------------------------------------
  -- collect statistics (note: globals do not have declarations!)
  --------------------------------------------------------------------
  for t, e in a.pairs(T) do
    w = w + 1
    s = s + e.token
    h = h + e.size
  end
  for t, e in a.pairs(I) do
    y = y + 1
    v = v + e.decl
    c = c + e.token
    u = u + e.size
  end
  for t, e in a.pairs(O) do
    p = p + 1
    m = m + e.decl
    l = l + e.token
    d = d + e.size
  end
  A = w + y
  E = j + v
  q = s + c
  b = h + u
  _ = w + p
  z = j + m
  x = s + l
  k = h + d
  --------------------------------------------------------------------
  -- detailed stats: global list
  --------------------------------------------------------------------
  if f then
    local f = {} -- sort table of unique global names by size
    for t, e in a.pairs(T) do
      e.name = t
      f[#f + 1] = e
    end
    g.sort(f,
      function(t, e)
        return t.size > e.size
      end
    )
    local a, y = "%8s%8s%10s  %s", "%8d%8d%10.2f  %s"
    local w = n.rep("-", 44)
    e("*** global variable list (sorted by size) ***\n"..w)
    e(t(a, "Token",  "Input", "Input", "Global"))
    e(t(a, "Count", "Bytes", "Average", "Name"))
    e(w)
    for a = 1, #f do
      local a = f[a]
      e(t(y, a.token, a.size, i(a.token, a.size), a.name))
    end
    e(w)
    e(t(y, s, h, i(s, h), "TOTAL"))
    e(w.."\n")
  --------------------------------------------------------------------
  -- detailed stats: local list
  --------------------------------------------------------------------
    local a, f = "%8s%8s%8s%10s%8s%10s  %s", "%8d%8d%8d%10.2f%8d%10.2f  %s"
    local n = n.rep("-", 70)
    e("*** local variable list (sorted by allocation order) ***\n"..n)
    e(t(a, "Decl.", "Token",  "Input", "Input", "Output", "Output", "Global"))
    e(t(a, "Count", "Count", "Bytes", "Average", "Bytes", "Average", "Name"))
    e(n)
    for a = 1, #r do  -- iterate according to order assigned
      local s = r[a]
      local a = O[s]
      local h, n = 0, 0
      for t = 1, #o do  -- find corresponding old names and calculate
        local e = o[t]
        if e.name == s then
          h = h + e.xcount
          n = n + e.xcount * #e.oldname
        end
      end
      e(t(f, a.decl, a.token, n, i(h, n),
                a.size, i(a.token, a.size), s))
    end
    e(n)
    e(t(f, m, l, u, i(c, u),
              d, i(l, d), "TOTAL"))
    e(n.."\n")
  end--if opt_details
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  local r, o = "%-16s%8s%8s%8s%8s%10s", "%-16s%8d%8d%8d%8d%10.2f"
  local a = n.rep("-", 58)
  e("*** local variable optimization summary ***\n"..a)
  e(t(r, "Variable",  "Unique", "Decl.", "Token", "Size", "Average"))
  e(t(r, "Types", "Names", "Count", "Count", "Bytes", "Bytes"))
  e(a)
  e(t(o, "Global", w, j, s, h, i(s, h)))
  e(a)
  e(t(o, "Local (in)", y, v, c, u, i(c, u)))
  e(t(o, "TOTAL (in)", A, E, q, b, i(q, b)))
  e(a)
  e(t(o, "Local (out)", p, m, l, d, i(l, d)))
  e(t(o, "TOTAL (out)", _, z, x, k, i(x, k)))
  e(a.."\n")
end

----------------------------------------------------------------------
-- experimental optimization for f("string") statements
-- * safe to delete parentheses without adding whitespace, as both
--   kinds of strings can abut with anything else
----------------------------------------------------------------------

local function l()
  ------------------------------------------------------------------
  local function o(e)          -- find f("string") pattern
    local t = s[e + 1] or ""
    local a = s[e + 2] or ""
    local e = s[e + 3] or ""
    if t == "(" and a == "<string>" and e == ")" then
      return true
    end
  end
  ------------------------------------------------------------------
  local a = {}           -- scan for function pattern,
  local e = 1                   -- tokens to be deleted are marked
  while e <= #s do
    local t = w[e]
    if t == "call" and o(e) then  -- found & mark ()
      a[e + 1] = true    -- '('
      a[e + 3] = true    -- ')'
      e = e + 3
    end
    e = e + 1
  end
  ------------------------------------------------------------------
  -- delete a token and adjust all relevant tables
  -- * currently invalidates globalinfo and localinfo (not updated),
  --   so any other optimization is done after processing locals
  --   (of course, we can also lex the source data again...)
  -- * faster one-pass token deletion
  ------------------------------------------------------------------
  local t, e, o = 1, 1, #s
  local i = {}
  while e <= o do         -- process parser tables
    if a[t] then         -- found a token to delete?
      i[v[t]] = true
      t = t + 1
    end
    if t > e then
      if t <= o then        -- shift table items lower
        s[e] = s[t]
        k[e] = k[t]
        v[e] = v[t] - (t - e)
        w[e] = w[t]
      else                      -- nil out excess entries
        s[e] = nil
        k[e] = nil
        v[e] = nil
        w[e] = nil
      end
    end
    t = t + 1
    e = e + 1
  end
  local e, t, a = 1, 1, #h
  while t <= a do         -- process lexer tables
    if i[e] then        -- found a token to delete?
      e = e + 1
    end
    if e > t then
      if e <= a then        -- shift table items lower
        h[t] = h[e]
        c[t] = c[e]
      else                      -- nil out excess entries
        h[t] = nil
        c[t] = nil
      end
    end
    e = e + 1
    t = t + 1
  end
end

----------------------------------------------------------------------
-- local variable optimization
----------------------------------------------------------------------

local function u(h)
  q = 0                           -- reset variable name allocator
  r = {}
  ------------------------------------------------------------------
  -- preprocess global/local tables, handle entropy reduction
  ------------------------------------------------------------------
  b = z(_)
  O = z(o)
  if h["opt-entropy"] then         -- for entropy improvement
    I(h)
  end
  ------------------------------------------------------------------
  -- build initial declared object table, then sort according to
  -- token count, this might help assign more tokens to more common
  -- variable names such as 'e' thus possibly reducing entropy
  -- * an object knows its localinfo index via its 'id' field
  -- * special handling for "self" special local (parameter) here
  ------------------------------------------------------------------
  local e = {}
  for t = 1, #o do
    e[t] = o[t]
  end
  g.sort(e,                    -- sort largest first
    function(t, e)
      return t.xcount > e.xcount
    end
  )
  ------------------------------------------------------------------
  -- the special "self" function parameters must be preserved
  -- * the allocator below will never use "self", so it is safe to
  --   keep those implicit declarations as-is
  ------------------------------------------------------------------
  local a, t, d = {}, 1, false
  for o = 1, #e do
    local e = e[o]
    if not e.isself then
      a[t] = e
      t = t + 1
    else
      d = true
    end
  end
  e = a
  ------------------------------------------------------------------
  -- a simple first-come first-served heuristic name allocator,
  -- note that this is in no way optimal...
  -- * each object is a local variable declaration plus existence
  -- * the aim is to assign short names to as many tokens as possible,
  --   so the following tries to maximize name reuse
  -- * note that we preserve sort order
  ------------------------------------------------------------------
  local s = #e
  while s > 0 do
    local n, a
    repeat
      n, a = S()  -- collect a variable name
    until not A[n]          -- skip all special names
    r[#r + 1] = n       -- keep a list
    local t = s
    ------------------------------------------------------------------
    -- if variable name collides with an existing global, the name
    -- cannot be used by a local when the name is accessed as a global
    -- during which the local is alive (between 'act' to 'rem'), so
    -- we drop objects that collides with the corresponding global
    ------------------------------------------------------------------
    if a then
      -- find the xref table of the global
      local i = _[b[n].id].xref
      local n = #i
      -- enumerate for all current objects; all are valid at this point
      for a = 1, s do
        local a = e[a]
        local s, e = a.act, a.rem  -- 'live' range of local
        -- if rem < 0, it is a -id to a local that had the same name
        -- so follow rem to extend it; does this make sense?
        while e < 0 do
          e = o[-e].rem
        end
        local o
        for t = 1, n do
          local t = i[t]
          if t >= s and t <= e then o = true end  -- in range?
        end
        if o then
          a.skip = true
          t = t - 1
        end
      end--for
    end--if gcollide
    ------------------------------------------------------------------
    -- now the first unassigned local (since it's sorted) will be the
    -- one with the most tokens to rename, so we set this one and then
    -- eliminate all others that collides, then any locals that left
    -- can then reuse the same variable name; this is repeated until
    -- all local declaration that can use this name is assigned
    -- * the criteria for local-local reuse/collision is:
    --   A is the local with a name already assigned
    --   B is the unassigned local under consideration
    --   => anytime A is accessed, it cannot be when B is 'live'
    --   => to speed up things, we have first/last accesses noted
    ------------------------------------------------------------------
    while t > 0 do
      local a = 1
      while e[a].skip do  -- scan for first object
        a = a + 1
      end
      ------------------------------------------------------------------
      -- first object is free for assignment of the variable name
      -- [first,last] gives the access range for collision checking
      ------------------------------------------------------------------
      t = t - 1
      local i = e[a]
      a = a + 1
      i.newname = n
      i.skip = true
      i.done = true
      local s, h = i.first, i.last
      local r = i.xref
      ------------------------------------------------------------------
      -- then, scan all the rest and drop those colliding
      -- if A was never accessed then it'll never collide with anything
      -- otherwise trivial skip if:
      -- * B was activated after A's last access (last < act)
      -- * B was removed before A's first access (first > rem)
      -- if not, see detailed skip below...
      ------------------------------------------------------------------
      if s and t > 0 then  -- must have at least 1 access
        local n = t
        while n > 0 do
          while e[a].skip do  -- next valid object
            a = a + 1
          end
          n = n - 1
          local e = e[a]
          a = a + 1
          local n, a = e.act, e.rem  -- live range of B
          -- if rem < 0, extend range of rem thru' following local
          while a < 0 do
            a = o[-a].rem
          end
          --------------------------------------------------------
          if not(h < n or s > a) then  -- possible collision
            --------------------------------------------------------
            -- B is activated later than A or at the same statement,
            -- this means for no collision, A cannot be accessed when B
            -- is alive, since B overrides A (or is a peer)
            --------------------------------------------------------
            if n >= i.act then
              for o = 1, i.xcount do  -- ... then check every access
                local o = r[o]
                if o >= n and o <= a then  -- A accessed when B live!
                  t = t - 1
                  e.skip = true
                  break
                end
              end--for
            --------------------------------------------------------
            -- A is activated later than B, this means for no collision,
            -- A's access is okay since it overrides B, but B's last
            -- access need to be earlier than A's activation time
            --------------------------------------------------------
            else
              if e.last and e.last >= i.act then
                t = t - 1
                e.skip = true
              end
            end
          end
          --------------------------------------------------------
          if t == 0 then break end
        end
      end--if first
      ------------------------------------------------------------------
    end--while
    ------------------------------------------------------------------
    -- after assigning all possible locals to one variable name, the
    -- unassigned locals/objects have the skip field reset and the table
    -- is compacted, to hopefully reduce iteration time
    ------------------------------------------------------------------
    local a, t = {}, 1
    for o = 1, s do
      local e = e[o]
      if not e.done then
        e.skip = false
        a[t] = e
        t = t + 1
      end
    end
    e = a  -- new compacted object table
    s = #e  -- objects left to process
    ------------------------------------------------------------------
  end--while
  ------------------------------------------------------------------
  -- after assigning all locals with new variable names, we can
  -- patch in the new names, and reprocess to get 'after' stats
  ------------------------------------------------------------------
  for e = 1, #o do  -- enumerate all locals
    local e = o[e]
    local t = e.xref
    if e.newname then                 -- if got new name, patch it in
      for a = 1, e.xcount do
        local t = t[a]               -- xrefs indexes the token list
        c[t] = e.newname
      end
      e.name, e.oldname             -- adjust names
        = e.newname, e.name
    else
      e.oldname = e.name            -- for cases like 'self'
    end
  end
  ------------------------------------------------------------------
  -- deal with statistics output
  ------------------------------------------------------------------
  if d then  -- add 'self' to end of list
    r[#r + 1] = "self"
  end
  local e = z(o)
  N(b, O, e, h)
end


----------------------------------------------------------------------
-- main entry point
----------------------------------------------------------------------

function optimize(t, i, a, e)
  -- set tables
  h, c                  -- from lexer
    = i, a
  s, k, v           -- from parser
    = e.toklist, e.seminfolist, e.xreflist
  _, o, w       -- from parser
    = e.globalinfo, e.localinfo, e.statinfo
  ------------------------------------------------------------------
  -- optimize locals
  ------------------------------------------------------------------
  if t["opt-locals"] then
    u(t)
  end
  ------------------------------------------------------------------
  -- other optimizations
  ------------------------------------------------------------------
  if t["opt-experimental"] then    -- experimental
    l()
    -- WARNING globalinfo and localinfo now invalidated!
  end
end
--end of inserted module
end

-- preload function for module equiv
p.equiv =
function()
--start of inserted module
module "equiv"

local e = a.require "string"
local d = a.loadstring
local u = e.sub
local r = e.match
local s = e.dump
local v = e.byte

--[[--------------------------------------------------------------------
-- variable and data initialization
----------------------------------------------------------------------]]

local l = {          -- significant (grammar) tokens
  TK_KEYWORD = true,
  TK_NAME = true,
  TK_NUMBER = true,
  TK_STRING = true,
  TK_LSTRING = true,
  TK_OP = true,
  TK_EOS = true,
}

local i, e, h

--[[--------------------------------------------------------------------
-- functions
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- initialization function
------------------------------------------------------------------------

function init(o, a, t)
  i = o
  e = a
  h = t
end

------------------------------------------------------------------------
-- function to build lists containing a 'normal' lexer stream
------------------------------------------------------------------------

local function n(t)
  e.init(t)
  e.llex()
  local a, i -- source list (with whitespace elements)
    = e.tok, e.seminfo
  local e, t   -- processed list (real elements only)
    = {}, {}
  for o = 1, #a do
    local a = a[o]
    if l[a] then
      e[#e + 1] = a
      t[#t + 1] = i[o]
    end
  end--for
  return e, t
end

------------------------------------------------------------------------
-- test source (lexer stream) equivalence
------------------------------------------------------------------------

function source(t, l)
  --------------------------------------------------------------------
  -- function to return a dumped string for seminfo compares
  --------------------------------------------------------------------
  local function u(e)
    local e = d("return "..e, "z")
    if e then
      return s(e)
    end
  end
  --------------------------------------------------------------------
  -- mark and optionally report non-equivalence
  --------------------------------------------------------------------
  local function o(e)
    if i.DETAILS then a.print("SRCEQUIV: "..e) end
    h.SRC_EQUIV = true
  end
  --------------------------------------------------------------------
  -- get lexer streams for both source strings, compare
  --------------------------------------------------------------------
  local e, d = n(t)        -- original
  local a, h = n(l)      -- compressed
  --------------------------------------------------------------------
  -- compare shbang lines ignoring EOL
  --------------------------------------------------------------------
  local t = r(t, "^(#[^\r\n]*)")
  local n = r(l, "^(#[^\r\n]*)")
  if t or n then
    if not t or not n or t ~= n then
      o("shbang lines different")
    end
  end
  --------------------------------------------------------------------
  -- compare by simple count
  --------------------------------------------------------------------
  if #e ~= #a then
    o("count "..#e.." "..#a)
    return
  end
  --------------------------------------------------------------------
  -- compare each element the best we can
  --------------------------------------------------------------------
  for t = 1, #e do
    local e, s = e[t], a[t]
    local n, a = d[t], h[t]
    if e ~= s then  -- by type
      o("type ["..t.."] "..e.." "..s)
      break
    end
    if e == "TK_KEYWORD" or e == "TK_NAME" or e == "TK_OP" then
      if e == "TK_NAME" and i["opt-locals"] then
        -- can't compare identifiers of locals that are optimized
      elseif n ~= a then  -- by semantic info (simple)
        o("seminfo ["..t.."] "..e.." "..n.." "..a)
        break
      end
    elseif e == "TK_EOS" then
      -- no seminfo to compare
    else-- "TK_NUMBER" or "TK_STRING" or "TK_LSTRING"
      -- compare 'binary' form, so dump a function
      local i,s = u(n), u(a)
      if not i or not s or i ~= s then
        o("seminfo ["..t.."] "..e.." "..n.." "..a)
        break
      end
    end
  end--for
  --------------------------------------------------------------------
  -- successful comparison if end is reached with no borks
  --------------------------------------------------------------------
end

------------------------------------------------------------------------
-- test binary chunk equivalence
------------------------------------------------------------------------

function binary(n, o)
  local e     = 0
  local _ = 1
  local z  = 3
  local E  = 4
  --------------------------------------------------------------------
  -- mark and optionally report non-equivalence
  --------------------------------------------------------------------
  local function e(e)
    if i.DETAILS then a.print("BINEQUIV: "..e) end
    h.BIN_EQUIV = true
  end
  --------------------------------------------------------------------
  -- function to remove shbang line so that loadstring runs
  --------------------------------------------------------------------
  local function a(e)
    local t = r(e, "^(#[^\r\n]*\r?\n?)")
    if t then                      -- cut out shbang
      e = u(e, #t + 1)
    end
    return e
  end
  --------------------------------------------------------------------
  -- attempt to compile, then dump to get binary chunk string
  --------------------------------------------------------------------
  local t = d(a(n), "z")
  if not t then
    e("failed to compile original sources for binary chunk comparison")
    return
  end
  local a = d(a(o), "z")
  if not a then
    e("failed to compile compressed result for binary chunk comparison")
  end
  -- if loadstring() works, dump assuming string.dump() is error-free
  local i = { i = 1, dat = s(t) }
  i.len = #i.dat
  local r = { i = 1, dat = s(a) }
  r.len = #r.dat
  --------------------------------------------------------------------
  -- support functions to handle binary chunk reading
  --------------------------------------------------------------------
  local g,
        d, c,               -- sizes of data types
        y, w,
        o, m
  --------------------------------------------------------------------
  local function h(e, t)          -- check if bytes exist
    if e.i + t - 1 > e.len then return end
    return true
  end
  --------------------------------------------------------------------
  local function f(t, e)            -- skip some bytes
    if not e then e = 1 end
    t.i = t.i + e
  end
  --------------------------------------------------------------------
  local function n(t)             -- return a byte value
    local e = t.i
    if e > t.len then return end
    local a = u(t.dat, e, e)
    t.i = e + 1
    return v(a)
  end
  --------------------------------------------------------------------
  local function k(a)            -- return an int value (little-endian)
    local t, e = 0, 1
    if not h(a, d) then return end
    for o = 1, d do
      t = t + e * n(a)
      e = e * 256
    end
    return t
  end
  --------------------------------------------------------------------
  local function q(t)            -- return an int value (big-endian)
    local e = 0
    if not h(t, d) then return end
    for a = 1, d do
      e = e * 256 + n(t)
    end
    return e
  end
  --------------------------------------------------------------------
  local function j(a)          -- return a size_t value (little-endian)
    local t, e = 0, 1
    if not h(a, c) then return end
    for o = 1, c do
      t = t + e * n(a)
      e = e * 256
    end
    return t
  end
  --------------------------------------------------------------------
  local function x(t)          -- return a size_t value (big-endian)
    local e = 0
    if not h(t, c) then return end
    for a = 1, c do
      e = e * 256 + n(t)
    end
    return e
  end
  --------------------------------------------------------------------
  local function l(e, o)        -- return a block (as a string)
    local t = e.i
    local a = t + o - 1
    if a > e.len then return end
    local a = u(e.dat, t, a)
    e.i = t + o
    return a
  end
  --------------------------------------------------------------------
  local function s(t)           -- return a string
    local e = m(t)
    if not e then return end
    if e == 0 then return "" end
    return l(t, e)
  end
  --------------------------------------------------------------------
  local function v(e, t)       -- compare byte value
    local e, t = n(e), n(t)
    if not e or not t or e ~= t then
      return
    end
    return e
  end
  --------------------------------------------------------------------
  local function u(e, t)        -- compare byte value
    local e = v(e, t)
    if not e then return true end
  end
  --------------------------------------------------------------------
  local function p(e, t)        -- compare int value
    local e, t = o(e), o(t)
    if not e or not t or e ~= t then
      return
    end
    return e
  end
  --------------------------------------------------------------------
  -- recursively-called function to compare function prototypes
  --------------------------------------------------------------------
  local function b(a, t)
    -- source name (ignored)
    if not s(a) or not s(t) then
      e("bad source name"); return
    end
    -- linedefined (ignored)
    if not o(a) or not o(t) then
      e("bad linedefined"); return
    end
    -- lastlinedefined (ignored)
    if not o(a) or not o(t) then
      e("bad lastlinedefined"); return
    end
    if not (h(a, 4) and h(t, 4)) then
      e("prototype header broken")
    end
    -- nups (compared)
    if u(a, t) then
      e("bad nups"); return
    end
    -- numparams (compared)
    if u(a, t) then
      e("bad numparams"); return
    end
    -- is_vararg (compared)
    if u(a, t) then
      e("bad is_vararg"); return
    end
    -- maxstacksize (compared)
    if u(a, t) then
      e("bad maxstacksize"); return
    end
    -- code (compared)
    local i = p(a, t)
    if not i then
      e("bad ncode"); return
    end
    local n = l(a, i * y)
    local i = l(t, i * y)
    if not n or not i or n ~= i then
      e("bad code block"); return
    end
    -- constants (compared)
    local i = p(a, t)
    if not i then
      e("bad nconst"); return
    end
    for o = 1, i do
      local o = v(a, t)
      if not o then
        e("bad const type"); return
      end
      if o == _ then
        if u(a, t) then
          e("bad boolean value"); return
        end
      elseif o == z then
        local a = l(a, w)
        local t = l(t, w)
        if not a or not t or a ~= t then
          e("bad number value"); return
        end
      elseif o == E then
        local a = s(a)
        local t = s(t)
        if not a or not t or a ~= t then
          e("bad string value"); return
        end
      end
    end
    -- prototypes (compared recursively)
    local i = p(a, t)
    if not i then
      e("bad nproto"); return
    end
    for o = 1, i do
      if not b(a, t) then
        e("bad function prototype"); return
      end
    end
    -- debug information (ignored)
    -- lineinfo (ignored)
    local n = o(a)
    if not n then
      e("bad sizelineinfo1"); return
    end
    local i = o(t)
    if not i then
      e("bad sizelineinfo2"); return
    end
    if not l(a, n * d) then
      e("bad lineinfo1"); return
    end
    if not l(t, i * d) then
      e("bad lineinfo2"); return
    end
    -- locvars (ignored)
    local n = o(a)
    if not n then
      e("bad sizelocvars1"); return
    end
    local i = o(t)
    if not i then
      e("bad sizelocvars2"); return
    end
    for t = 1, n do
      if not s(a) or not o(a) or not o(a) then
        e("bad locvars1"); return
      end
    end
    for a = 1, i do
      if not s(t) or not o(t) or not o(t) then
        e("bad locvars2"); return
      end
    end
    -- upvalues (ignored)
    local i = o(a)
    if not i then
      e("bad sizeupvalues1"); return
    end
    local o = o(t)
    if not o then
      e("bad sizeupvalues2"); return
    end
    for t = 1, i do
      if not s(a) then e("bad upvalues1"); return end
    end
    for a = 1, o do
      if not s(t) then e("bad upvalues2"); return end
    end
    return true
  end
  --------------------------------------------------------------------
  -- parse binary chunks to verify equivalence
  -- * for headers, handle sizes to allow a degree of flexibility
  -- * assume a valid binary chunk is generated, since it was not
  --   generated via external means
  --------------------------------------------------------------------
  if not (h(i, 12) and h(r, 12)) then
    e("header broken")
  end
  f(i, 6)                   -- skip signature(4), version, format
  g    = n(i)       -- 1 = little endian
  d    = n(i)       -- get data type sizes
  c  = n(i)
  y   = n(i)
  w = n(i)
  f(i)                      -- skip integral flag
  f(r, 12)                  -- skip other header (assume similar)
  if g == 1 then           -- set for endian sensitive data we need
    o   = k
    m = j
  else
    o   = q
    m = x
  end
  b(i, r)               -- get prototype at root
  if i.i ~= i.len + 1 then
    e("inconsistent binary chunk1"); return
  elseif r.i ~= r.len + 1 then
    e("inconsistent binary chunk2"); return
  end
  --------------------------------------------------------------------
  -- successful comparison if end is reached with no borks
  --------------------------------------------------------------------
end
--end of inserted module
end

-- preload function for module plugin/html
p["plugin/html"] =
function()
--start of inserted module
module "plugin/html"

local t = a.require "string"
local c = a.require "table"
local u = a.require "io"

------------------------------------------------------------------------
-- constants and configuration
------------------------------------------------------------------------

local l = ".html"
local m = {
  ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;",
  ["'"] = "&apos;", ["\""] = "&quot;",
}

-- simple headers and footers
local y = [[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>%s</title>
<meta name="Generator" content="LuaSrcDiet">
<style type="text/css">
%s</style>
</head>
<body>
<pre class="code">
]]
local w = [[
</pre>
</body>
</html>
]]
-- for more, please see wikimain.css from the Lua wiki site
local f = [[
BODY {
    background: white;
    color: navy;
}
pre.code { color: black; }
span.comment { color: #00a000; }
span.string  { color: #009090; }
span.keyword { color: black; font-weight: bold; }
span.number { color: #993399; }
span.operator { }
span.name { }
span.global { color: #ff0000; font-weight: bold; }
span.local { color: #0000ff; font-weight: bold; }
]]

------------------------------------------------------------------------
-- option handling, plays nice with --quiet option
------------------------------------------------------------------------

local n                    -- local reference to list of options
local e, o             -- filenames
local i, d, h  -- token data

local function s(...)               -- handle quiet option
  if n.QUIET then return end
  a.print(...)
end

------------------------------------------------------------------------
-- initialization
------------------------------------------------------------------------

function init(s, i, h)
  n = s
  e = i
  local i, h = t.find(e, "%.[^%.%\\%/]*$")
  local s, r = e, ""
  if i and i > 1 then
    s = t.sub(e, 1, i - 1)
    r = t.sub(e, i, h)
  end
  o = s..l
  if n.OUTPUT_FILE then
    o = n.OUTPUT_FILE
  end
  if e == o then
    a.error("output filename identical to input filename")
  end
end

------------------------------------------------------------------------
-- message display, post-load processing
------------------------------------------------------------------------

function post_load(t)
  s([[
HTML plugin module for LuaSrcDiet
]])
  s("Exporting: "..e.." -> "..o.."\n")
end

------------------------------------------------------------------------
-- post-lexing processing, can work on lexer table output
------------------------------------------------------------------------

function post_lex(e, t, a)
  i, d, h
    = e, t, a
end

------------------------------------------------------------------------
-- escape the usual suspects for HTML/XML
------------------------------------------------------------------------

local function h(a)
  local e = 1
  while e <= #a do
    local o = t.sub(a, e, e)
    local i = m[o]
    if i then
      o = i
      a = t.sub(a, 1, e - 1)..o..t.sub(a, e + 1)
    end
    e = e + #o
  end--while
  return a
end

------------------------------------------------------------------------
-- save source code to file
------------------------------------------------------------------------

local function m(t, o)
  local e = u.open(t, "wb")
  if not e then a.error("cannot open \""..t.."\" for writing") end
  local o = e:write(o)
  if not o then a.error("cannot write to \""..t.."\"") end
  e:close()
end

------------------------------------------------------------------------
-- post-parsing processing, gives globalinfo, localinfo
------------------------------------------------------------------------

function post_parse(l, u)
  local r = {}
  local function s(e)         -- html helpers
    r[#r + 1] = e
  end
  local function a(e, t)
    s('<span class="'..e..'">'..t..'</span>')
  end
  ----------------------------------------------------------------------
  for e = 1, #l do     -- mark global identifiers as TK_GLOBAL
    local e = l[e]
    local e = e.xref
    for t = 1, #e do
      local e = e[t]
      i[e] = "TK_GLOBAL"
    end
  end--for
  ----------------------------------------------------------------------
  for e = 1, #u do      -- mark local identifiers as TK_LOCAL
    local e = u[e]
    local e = e.xref
    for t = 1, #e do
      local e = e[t]
      i[e] = "TK_LOCAL"
    end
  end--for
  ----------------------------------------------------------------------
  s(t.format(y,     -- header and leading stuff
    h(e),
    f))
  for e = 1, #i do        -- enumerate token list
    local e, t = i[e], d[e]
    if e == "TK_KEYWORD" then
      a("keyword", t)
    elseif e == "TK_STRING" or e == "TK_LSTRING" then
      a("string", h(t))
    elseif e == "TK_COMMENT" or e == "TK_LCOMMENT" then
      a("comment", h(t))
    elseif e == "TK_GLOBAL" then
      a("global", t)
    elseif e == "TK_LOCAL" then
      a("local", t)
    elseif e == "TK_NAME" then
      a("name", t)
    elseif e == "TK_NUMBER" then
      a("number", t)
    elseif e == "TK_OP" then
      a("operator", h(t))
    elseif e ~= "TK_EOS" then  -- TK_EOL, TK_SPACE
      s(t)
    end
  end--for
  s(w)
  m(o, c.concat(r))
  n.EXIT = true
end
--end of inserted module
end

-- preload function for module plugin/sloc
p["plugin/sloc"] =
function()
--start of inserted module
module "plugin/sloc"

local n = a.require "string"
local e = a.require "table"

------------------------------------------------------------------------
-- initialization
------------------------------------------------------------------------

local o                    -- local reference to list of options
local h                     -- source file name

function init(t, e, a)
  o = t
  o.QUIET = true
  h = e
end

------------------------------------------------------------------------
-- splits a block into a table of lines (minus EOLs)
------------------------------------------------------------------------

local function s(o)
  local a = {}
  local t, i = 1, #o
  while t <= i do
    local e, s, r, h = n.find(o, "([\r\n])([\r\n]?)", t)
    if not e then
      e = i + 1
    end
    a[#a + 1] = n.sub(o, t, e - 1)
    t = e + 1
    if e < i and s > e and r ~= h then  -- handle Lua-style CRLF, LFCR
      t = t + 1
    end
  end
  return a
end

------------------------------------------------------------------------
-- post-lexing processing, can work on lexer table output
------------------------------------------------------------------------

function post_lex(t, r, d)
  local e, i = 0, 0
  local function n(t)        -- if a new line, count it as an SLOC
    if t > e then           -- new line # must be > old line #
      i = i + 1; e = t
    end
  end
  for e = 1, #t do        -- enumerate over all tokens
    local t, a, e
      = t[e], r[e], d[e]
    --------------------------------------------------------------------
    if t == "TK_KEYWORD" or t == "TK_NAME" or       -- significant
       t == "TK_NUMBER" or t == "TK_OP" then
      n(e)
    --------------------------------------------------------------------
    -- Both TK_STRING and TK_LSTRING may be multi-line, hence, a loop
    -- is needed in order to mark off lines one-by-one. Since llex.lua
    -- currently returns the line number of the last part of the string,
    -- we must subtract in order to get the starting line number.
    --------------------------------------------------------------------
    elseif t == "TK_STRING" then      -- possible multi-line
      local t = s(a)
      e = e - #t + 1
      for t = 1, #t do
        n(e); e = e + 1
      end
    --------------------------------------------------------------------
    elseif t == "TK_LSTRING" then     -- possible multi-line
      local t = s(a)
      e = e - #t + 1
      for a = 1, #t do
        if t[a] ~= "" then n(e) end
        e = e + 1
      end
    --------------------------------------------------------------------
    -- other tokens are comments or whitespace and are ignored
    --------------------------------------------------------------------
    end
  end--for
  a.print(h..": "..i) -- display result
  o.EXIT = true
end
--end of inserted module
end

-- support modules
local o = j "llex"
local u = j "lparser"
local x = j "optlex"
local E = j "optparser"
local q = j "equiv"
local a

--[[--------------------------------------------------------------------
-- messages and textual data
----------------------------------------------------------------------]]

local p = [[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.12.1 (20120407)  Copyright (c) 2012 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]

local m = [[
usage: LuaSrcDiet [options] [filenames]

example:
  >LuaSrcDiet myscript.lua -o myscript_.lua

options:
  -v, --version       prints version information
  -h, --help          prints usage information
  -o <file>           specify file name to write output
  -s <suffix>         suffix for output files (default '_')
  --keep <msg>        keep block comment with <msg> inside
  --plugin <module>   run <module> in plugin/ directory
  -                   stop handling arguments

  (optimization levels)
  --none              all optimizations off (normalizes EOLs only)
  --basic             lexer-based optimizations only
  --maximum           maximize reduction of source

  (informational)
  --quiet             process files quietly
  --read-only         read file and print token stats only
  --dump-lexer        dump raw tokens from lexer to stdout
  --dump-parser       dump variable tracking tables from parser
  --details           extra info (strings, numbers, locals)

features (to disable, insert 'no' prefix like --noopt-comments):
%s
default settings:
%s]]

------------------------------------------------------------------------
-- optimization options, for ease of switching on and off
-- * positive to enable optimization, negative (no) to disable
-- * these options should follow --opt-* and --noopt-* style for now
------------------------------------------------------------------------

local v = [[
--opt-comments,'remove comments and block comments'
--opt-whitespace,'remove whitespace excluding EOLs'
--opt-emptylines,'remove empty lines'
--opt-eols,'all above, plus remove unnecessary EOLs'
--opt-strings,'optimize strings and long strings'
--opt-numbers,'optimize numbers'
--opt-locals,'optimize local variable names'
--opt-entropy,'tries to reduce symbol entropy of locals'
--opt-srcequiv,'insist on source (lexer stream) equivalence'
--opt-binequiv,'insist on binary chunk equivalence'
--opt-experimental,'apply experimental optimizations'
]]

-- preset configuration
local _ = [[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
  --opt-srcequiv --opt-binequiv
]]
-- override configurations
-- * MUST explicitly enable/disable everything for
--   total option replacement
local N = [[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]
local O = [[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
  --opt-srcequiv --opt-binequiv
]]
local I = [[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]

local h = "_"      -- default suffix for file renaming
local A = "plugin/" -- relative location of plugins

--[[--------------------------------------------------------------------
-- startup and initialize option list handling
----------------------------------------------------------------------]]

-- simple error message handler; change to error if traceback wanted
local function i(e)
  y("LuaSrcDiet (error): "..e); os.exit(1)
end
--die = error--DEBUG

if not B(_VERSION, "5.1", 1, 1) then  -- sanity check
  i("requires Lua 5.1 to run")
end

------------------------------------------------------------------------
-- prepares text for list of optimizations, prepare lookup table
------------------------------------------------------------------------

local n = ""
do
  local i = 24
  local t = {}
  for a, o in G(v, "%s*([^,]+),'([^']+)'") do
    local e = "  "..a
    e = e..s.rep(" ", i - #e)..o.."\n"
    n = n..e
    t[a] = true
    t["--no"..f(a, 3)] = true
  end
  v = t  -- replace OPTION with lookup table
end

m = s.format(m, n, _)

if W then  -- embedded plugins
  local e = "\nembedded plugins:\n"
  for t = 1, #W do
    local t = W[t]
    e = e.."  "..Z[t].."\n"
  end
  m = m..e
end

------------------------------------------------------------------------
-- global variable initialization, option set handling
------------------------------------------------------------------------

local z = h           -- file suffix
local e = {}                       -- program options
local h, n                    -- statistics tables

-- function to set option lookup table based on a text list of options
-- note: additional forced settings for --opt-eols is done in optlex.lua
local function w(t)
  for t in G(t, "(%-%-%S+)") do
    if f(t, 3, 4) == "no" and        -- handle negative options
       v["--"..f(t, 5)] then
      e[f(t, 5)] = false
    else
      e[f(t, 3)] = true
    end
  end
end

--[[--------------------------------------------------------------------
-- support functions
----------------------------------------------------------------------]]

-- list of token types, parser-significant types are up to TTYPE_GRAMMAR
-- while the rest are not used by parsers; arranged for stats display
local d = {
  "TK_KEYWORD", "TK_NAME", "TK_NUMBER",         -- grammar
  "TK_STRING", "TK_LSTRING", "TK_OP",
  "TK_EOS",
  "TK_COMMENT", "TK_LCOMMENT",                  -- non-grammar
  "TK_EOL", "TK_SPACE",
}
local c = 7

local l = {                      -- EOL names for token dump
  ["\n"] = "LF", ["\r"] = "CR",
  ["\n\r"] = "LFCR", ["\r\n"] = "CRLF",
}

------------------------------------------------------------------------
-- read source code from file
------------------------------------------------------------------------

local function r(e)
  local t = io.open(e, "rb")
  if not t then i('cannot open "'..e..'" for reading') end
  local a = t:read("*a")
  if not a then i('cannot read from "'..e..'"') end
  t:close()
  return a
end

------------------------------------------------------------------------
-- save source code to file
------------------------------------------------------------------------

local function T(t, a)
  local e = io.open(t, "wb")
  if not e then i('cannot open "'..t..'" for writing') end
  local a = e:write(a)
  if not a then i('cannot write to "'..t..'"') end
  e:close()
end

------------------------------------------------------------------------
-- functions to deal with statistics
------------------------------------------------------------------------

-- initialize statistics table
local function k()
  h, n = {}, {}
  for e = 1, #d do
    local e = d[e]
    h[e], n[e] = 0, 0
  end
end

-- add a token to statistics table
local function g(e, t)
  h[e] = h[e] + 1
  n[e] = n[e] + #t
end

-- do totals for statistics table, return average table
local function b()
  local function i(e, t)                      -- safe average function
    if e == 0 then return 0 end
    return t / e
  end
  local o = {}
  local e, t = 0, 0
  for a = 1, c do                   -- total grammar tokens
    local a = d[a]
    e = e + h[a]; t = t + n[a]
  end
  h.TOTAL_TOK, n.TOTAL_TOK = e, t
  o.TOTAL_TOK = i(e, t)
  e, t = 0, 0
  for a = 1, #d do                         -- total all tokens
    local a = d[a]
    e = e + h[a]; t = t + n[a]
    o[a] = i(h[a], n[a])
  end
  h.TOTAL_ALL, n.TOTAL_ALL = e, t
  o.TOTAL_ALL = i(e, t)
  return o
end

--[[--------------------------------------------------------------------
-- main tasks
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- a simple token dumper, minimal translation of seminfo data
------------------------------------------------------------------------

local function H(e)
  --------------------------------------------------------------------
  -- load file and process source input into tokens
  --------------------------------------------------------------------
  local e = r(e)
  o.init(e)
  o.llex()
  local e, a = o.tok, o.seminfo
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  for t = 1, #e do
    local t, e = e[t], a[t]
    if t == "TK_OP" and s.byte(e) < 32 then
      e = "(".. s.byte(e)..")"
    elseif t == "TK_EOL" then
      e = l[e]
    else
      e = "'"..e.."'"
    end
    y(t.." "..e)
  end--for
end

----------------------------------------------------------------------
-- parser dump; dump globalinfo and localinfo tables
----------------------------------------------------------------------

local function R(e)
  local t = y
  --------------------------------------------------------------------
  -- load file and process source input into tokens
  --------------------------------------------------------------------
  local e = r(e)
  o.init(e)
  o.llex()
  local e, o, a
    = o.tok, o.seminfo, o.tokln
  --------------------------------------------------------------------
  -- do parser optimization here
  --------------------------------------------------------------------
  u.init(e, o, a)
  local e = u.parser()
  local a, i =
    e.globalinfo, e.localinfo
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  local o = s.rep("-", 72)
  t("*** Local/Global Variable Tracker Tables ***")
  t(o.."\n GLOBALS\n"..o)
  -- global tables have a list of xref numbers only
  for e = 1, #a do
    local a = a[e]
    local e = "("..e..") '"..a.name.."' -> "
    local a = a.xref
    for o = 1, #a do e = e..a[o].." " end
    t(e)
  end
  -- local tables have xref numbers and a few other special
  -- numbers that are specially named: decl (declaration xref),
  -- act (activation xref), rem (removal xref)
  t(o.."\n LOCALS (decl=declared act=activated rem=removed)\n"..o)
  for e = 1, #i do
    local a = i[e]
    local e = "("..e..") '"..a.name.."' decl:"..a.decl..
                " act:"..a.act.." rem:"..a.rem
    if a.isself then
      e = e.." isself"
    end
    e = e.." -> "
    local a = a.xref
    for o = 1, #a do e = e..a[o].." " end
    t(e)
  end
  t(o.."\n")
end

------------------------------------------------------------------------
-- reads source file(s) and reports some statistics
------------------------------------------------------------------------

local function D(a)
  local e = y
  --------------------------------------------------------------------
  -- load file and process source input into tokens
  --------------------------------------------------------------------
  local t = r(a)
  o.init(t)
  o.llex()
  local t, o = o.tok, o.seminfo
  e(p)
  e("Statistics for: "..a.."\n")
  --------------------------------------------------------------------
  -- collect statistics
  --------------------------------------------------------------------
  k()
  for e = 1, #t do
    local e, t = t[e], o[e]
    g(e, t)
  end--for
  local t = b()
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  local a = s.format
  local function r(e)
    return h[e], n[e], t[e]
  end
  local i, o = "%-16s%8s%8s%10s", "%-16s%8d%8d%10.2f"
  local t = s.rep("-", 42)
  e(a(i, "Lexical",  "Input", "Input", "Input"))
  e(a(i, "Elements", "Count", "Bytes", "Average"))
  e(t)
  for i = 1, #d do
    local i = d[i]
    e(a(o, i, r(i)))
    if i == "TK_EOS" then e(t) end
  end
  e(t)
  e(a(o, "Total Elements", r("TOTAL_ALL")))
  e(t)
  e(a(o, "Total Tokens", r("TOTAL_TOK")))
  e(t.."\n")
end

------------------------------------------------------------------------
-- process source file(s), write output and reports some statistics
------------------------------------------------------------------------

local function S(f, w)
  local function t(...)             -- handle quiet option
    if e.QUIET then return end
    _G.print(...)
  end
  if a and a.init then        -- plugin init
    e.EXIT = false
    a.init(e, f, w)
    if e.EXIT then return end
  end
  t(p)                      -- title message
  --------------------------------------------------------------------
  -- load file and process source input into tokens
  --------------------------------------------------------------------
  local c = r(f)
  if a and a.post_load then   -- plugin post-load
    c = a.post_load(c) or c
    if e.EXIT then return end
  end
  o.init(c)
  o.llex()
  local r, l, m
    = o.tok, o.seminfo, o.tokln
  if a and a.post_lex then    -- plugin post-lex
    a.post_lex(r, l, m)
    if e.EXIT then return end
  end
  --------------------------------------------------------------------
  -- collect 'before' statistics
  --------------------------------------------------------------------
  k()
  for e = 1, #r do
    local t, e = r[e], l[e]
    g(t, e)
  end--for
  local v = b()
  local p, y = h, n
  --------------------------------------------------------------------
  -- do parser optimization here
  --------------------------------------------------------------------
  E.print = t  -- hack
  u.init(r, l, m)
  local u = u.parser()
  if a and a.post_parse then          -- plugin post-parse
    a.post_parse(u.globalinfo, u.localinfo)
    if e.EXIT then return end
  end
  E.optimize(e, r, l, u)
  if a and a.post_optparse then       -- plugin post-optparse
    a.post_optparse()
    if e.EXIT then return end
  end
  --------------------------------------------------------------------
  -- do lexer optimization here, save output file
  --------------------------------------------------------------------
  local u = x.warn  -- use this as a general warning lookup
  x.print = t  -- hack
  r, l, m
    = x.optimize(e, r, l, m)
  if a and a.post_optlex then         -- plugin post-optlex
    a.post_optlex(r, l, m)
    if e.EXIT then return end
  end
  local a = ee.concat(l)
  -- depending on options selected, embedded EOLs in long strings and
  -- long comments may not have been translated to \n, tack a warning
  if s.find(a, "\r\n", 1, 1) or
     s.find(a, "\n\r", 1, 1) then
    u.MIXEDEOL = true
  end
  --------------------------------------------------------------------
  -- test source and binary chunk equivalence
  --------------------------------------------------------------------
  q.init(e, o, u)
  q.source(c, a)
  q.binary(c, a)
  local m = "before and after lexer streams are NOT equivalent!"
  local c = "before and after binary chunks are NOT equivalent!"
  -- for reporting, die if option was selected, else just warn
  if u.SRC_EQUIV then
    if e["opt-srcequiv"] then i(m) end
  else
    t("*** SRCEQUIV: token streams are sort of equivalent")
    if e["opt-locals"] then
      t("(but no identifier comparisons since --opt-locals enabled)")
    end
    t()
  end
  if u.BIN_EQUIV then
    if e["opt-binequiv"] then i(c) end
  else
    t("*** BINEQUIV: binary chunks are sort of equivalent")
    t()
  end
  --------------------------------------------------------------------
  -- save optimized source stream to output file
  --------------------------------------------------------------------
  T(w, a)
  --------------------------------------------------------------------
  -- collect 'after' statistics
  --------------------------------------------------------------------
  k()
  for e = 1, #r do
    local e, t = r[e], l[e]
    g(e, t)
  end--for
  local o = b()
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  t("Statistics for: "..f.." -> "..w.."\n")
  local a = s.format
  local function r(e)
    return p[e], y[e], v[e],
           h[e],  n[e],  o[e]
  end
  local o, i = "%-16s%8s%8s%10s%8s%8s%10s",
                       "%-16s%8d%8d%10.2f%8d%8d%10.2f"
  local e = s.rep("-", 68)
  t("*** lexer-based optimizations summary ***\n"..e)
  t(a(o, "Lexical",
            "Input", "Input", "Input",
            "Output", "Output", "Output"))
  t(a(o, "Elements",
            "Count", "Bytes", "Average",
            "Count", "Bytes", "Average"))
  t(e)
  for o = 1, #d do
    local o = d[o]
    t(a(i, o, r(o)))
    if o == "TK_EOS" then t(e) end
  end
  t(e)
  t(a(i, "Total Elements", r("TOTAL_ALL")))
  t(e)
  t(a(i, "Total Tokens", r("TOTAL_TOK")))
  t(e)
  --------------------------------------------------------------------
  -- report warning flags from optimizing process
  --------------------------------------------------------------------
  if u.LSTRING then
    t("* WARNING: "..u.LSTRING)
  elseif u.MIXEDEOL then
    t("* WARNING: ".."output still contains some CRLF or LFCR line endings")
  elseif u.SRC_EQUIV then
    t("* WARNING: "..m)
  elseif u.BIN_EQUIV then
    t("* WARNING: "..c)
  end
  t()
end

--[[--------------------------------------------------------------------
-- main functions
----------------------------------------------------------------------]]

local r = {...}  -- program arguments
local h = {}
w(_)     -- set to default options at beginning

------------------------------------------------------------------------
-- per-file handling, ship off to tasks
------------------------------------------------------------------------

local function l(n)
  for t = 1, #n do
    local t = n[t]
    local a
    ------------------------------------------------------------------
    -- find and replace extension for filenames
    ------------------------------------------------------------------
    local o, r = s.find(t, "%.[^%.%\\%/]*$")
    local h, s = t, ""
    if o and o > 1 then
      h = f(t, 1, o - 1)
      s = f(t, o, r)
    end
    a = h..z..s
    if #n == 1 and e.OUTPUT_FILE then
      a = e.OUTPUT_FILE
    end
    if t == a then
      i("output filename identical to input filename")
    end
    ------------------------------------------------------------------
    -- perform requested operations
    ------------------------------------------------------------------
    if e.DUMP_LEXER then
      H(t)
    elseif e.DUMP_PARSER then
      R(t)
    elseif e.READ_ONLY then
      D(t)
    else
      S(t, a)
    end
  end--for
end

------------------------------------------------------------------------
-- main function (entry point is after this definition)
------------------------------------------------------------------------

local function d()
  local t, o = #r, 1
  if t == 0 then
    e.HELP = true
  end
  --------------------------------------------------------------------
  -- handle arguments
  --------------------------------------------------------------------
  while o <= t do
    local t, n = r[o], r[o + 1]
    local s = B(t, "^%-%-?")
    if s == "-" then                 -- single-dash options
      if t == "-h" then
        e.HELP = true; break
      elseif t == "-v" then
        e.VERSION = true; break
      elseif t == "-s" then
        if not n then i("-s option needs suffix specification") end
        z = n
        o = o + 1
      elseif t == "-o" then
        if not n then i("-o option needs a file name") end
        e.OUTPUT_FILE = n
        o = o + 1
      elseif t == "-" then
        break -- ignore rest of args
      else
        i("unrecognized option "..t)
      end
    elseif s == "--" then            -- double-dash options
      if t == "--help" then
        e.HELP = true; break
      elseif t == "--version" then
        e.VERSION = true; break
      elseif t == "--keep" then
        if not n then i("--keep option needs a string to match for") end
        e.KEEP = n
        o = o + 1
      elseif t == "--plugin" then
        if not n then i("--plugin option needs a module name") end
        if e.PLUGIN then i("only one plugin can be specified") end
        e.PLUGIN = n
        a = j(A..n)
        o = o + 1
      elseif t == "--quiet" then
        e.QUIET = true
      elseif t == "--read-only" then
        e.READ_ONLY = true
      elseif t == "--basic" then
        w(N)
      elseif t == "--maximum" then
        w(O)
      elseif t == "--none" then
        w(I)
      elseif t == "--dump-lexer" then
        e.DUMP_LEXER = true
      elseif t == "--dump-parser" then
        e.DUMP_PARSER = true
      elseif t == "--details" then
        e.DETAILS = true
      elseif v[t] then  -- lookup optimization options
        w(t)
      else
        i("unrecognized option "..t)
      end
    else
      h[#h + 1] = t             -- potential filename
    end
    o = o + 1
  end--while
  if e.HELP then
    y(p..m); return true
  elseif e.VERSION then
    y(p); return true
  end
  if #h > 0 then
    if #h > 1 and e.OUTPUT_FILE then
      i("with -o, only one source file can be specified")
    end
    l(h)
    return true
  else
    i("nothing to do!")
  end
end

-- entry point -> main() -> do_files()
if not d() then
  i("Please run with option -h or --help for usage information")
end

-- end of script
