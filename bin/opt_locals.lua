#!/usr/bin/env lua
--[[--------------------------------------------------------------------

  LuaSrcDiet
  Compresses Lua source code by removing unnecessary characters.
  For Lua 5.1.x source code.

  Copyright (c) 2008,2011 Kein-Hong Man <keinhong@gmail.com>
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
local g = require
local p = print
local y = s.sub
local Z = s.gmatch
local X = s.match

-- modules incorporated as preload functions follows
local v = package.preload
local a = _G

local te = {
  html = "html    generates a HTML file for checking globals",
  sloc = "sloc    calculates SLOC for given source file",
}

local W = {
  'html',
  'sloc',
}

-- preload function for module llex
v.llex =
function()
--start of inserted module
module "llex"

local r = a.require "string"
local u = r.find
local m = r.match
local s = r.sub

----------------------------------------------------------------------
-- initialize keyword list, variables
----------------------------------------------------------------------

local f = {}
for e in r.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]], "%S+") do
  f[e] = true
end

-- see init() for module variables (externally visible):
--       tok, seminfo, tokln

local e,                -- source stream
      l,         -- name of source
      o,                -- position of lexer
      n,             -- buffer for strings
      h                -- line number

----------------------------------------------------------------------
-- add information to token listing
----------------------------------------------------------------------

local function i(t, a)
  local e = #tok + 1
  tok[e] = t
  seminfo[e] = a
  tokln[e] = h
end

----------------------------------------------------------------------
-- handles line number incrementation and end-of-line characters
----------------------------------------------------------------------

local function d(t, r)
  local n = s
  local a = n(e, t, t)
  t = t + 1  -- skip '\n' or '\r'
  local e = n(e, t, t)
  if (e == "\n" or e == "\r") and (e ~= a) then
    t = t + 1  -- skip '\n\r' or '\r\n'
    a = a..e
  end
  if r then i("TK_EOL", a) end
  h = h + 1
  o = t
  return t
end

----------------------------------------------------------------------
-- initialize lexer for given source _z and source name _sourceid
----------------------------------------------------------------------

function init(t, a)
  e = t                        -- source
  l = a          -- name of source
  o = 1                         -- lexer's position in source
  h = 1                        -- line number
  tok = {}                      -- lexed token list*
  seminfo = {}                  -- lexed semantic information list*
  tokln = {}                    -- line numbers for messages*
                                -- (*) externally visible thru' module
  --------------------------------------------------------------------
  -- initial processing (shbang handling)
  --------------------------------------------------------------------
  local t, n, e, a = u(e, "^(#[^\r\n]*)(\r?\n?)")
  if t then                             -- skip first line
    o = o + #e
    i("TK_COMMENT", e)
    if #a > 0 then d(o, true) end
  end
end

----------------------------------------------------------------------
-- returns a chunk name or id, no truncation for long names
----------------------------------------------------------------------

function chunkid()
  if l and m(l, "^[=@]") then
    return s(l, 2)  -- remove first char
  end
  return "[string]"
end

----------------------------------------------------------------------
-- formats error message and throws error
-- * a simplified version, does not report what token was responsible
----------------------------------------------------------------------

function errorline(e, t)
  local a = error or a.error
  a(r.format("%s:%d: %s", chunkid(), t or h, e))
end
local r = errorline

------------------------------------------------------------------------
-- count separators ("=") in a long string delimiter
------------------------------------------------------------------------

local function c(t)
  local i = s
  local n = i(e, t, t)
  t = t + 1
  local a = #m(e, "=*", t)
  t = t + a
  o = t
  return (i(e, t, t) == n) and a or (-a) - 1
end

----------------------------------------------------------------------
-- reads a long string or long comment
----------------------------------------------------------------------

local function w(l, h)
  local t = o + 1  -- skip 2nd '['
  local a = s
  local i = a(e, t, t)
  if i == "\r" or i == "\n" then  -- string starts with a newline?
    t = d(t)  -- skip it
  end
  while true do
    local i, u, s = u(e, "([\r\n%]])", t) -- (long range match)
    if not i then
      r(l and "unfinished long string" or
                "unfinished long comment")
    end
    t = i
    if s == "]" then                    -- delimiter test
      if c(t) == h then
        n = a(e, n, o)
        o = o + 1  -- skip 2nd ']'
        return n
      end
      t = o
    else                                -- newline
      n = n.."\n"
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
  local s = s
  while true do
    local i, u, a = h(e, "([\n\r\\\"\'])", t) -- (long range match)
    if i then
      if a == "\n" or a == "\r" then
        r("unfinished string")
      end
      t = i
      if a == "\\" then                         -- handle escapes
        t = t + 1
        a = s(e, t, t)
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
          local o, a, e = h(e, "^(%d%d?%d?)", t)
          t = a + 1
          if e + 1 > 256 then -- UCHAR_MAX
            r("escape sequence too large")
          end
        ------------------------------------------------------
        end--if p
      else
        t = t + 1
        if a == l then                        -- ending delimiter
          o = t
          return s(e, n, t - 1)            -- return string
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
  local l = m
  while true do--outer
    local t = o
    -- inner loop allows break to be used to nicely section tests
    while true do--inner
      ----------------------------------------------------------------
      local m, p, u = h(e, "^([_%a][_%w]*)", t)
      if m then
        o = t + #u
        if f[u] then
          i("TK_KEYWORD", u)             -- reserved word (keyword)
        else
          i("TK_NAME", u)                -- identifier
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local u, f, m = h(e, "^(%.?)%d", t)
      if u then                                 -- numeral
        if m == "." then t = t + 1 end
        local c, n, d = h(e, "^%d*[%.%d]*([eE]?)", t)
        t = n + 1
        if #d == 1 then                         -- optional exponent
          if l(e, "^[%+%-]", t) then        -- optional sign
            t = t + 1
          end
        end
        local n, t = h(e, "^[_%w]*", t)
        o = t + 1
        local e = s(e, u, t)                  -- string equivalent
        if not a.tonumber(e) then            -- handles hex test also
          r("malformed number")
        end
        i("TK_NUMBER", e)
        break -- (continue)
      end
      ----------------------------------------------------------------
      local f, u, m, a = h(e, "^((%s)[ \t\v\f]*)", t)
      if f then
        if a == "\n" or a == "\r" then          -- newline
          d(t, true)
        else
          o = u + 1                             -- whitespace
          i("TK_SPACE", m)
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local a = l(e, "^%p", t)
      if a then
        n = t
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
                  a = c(t)
                end
                if a >= 0 then                -- long comment
                  i("TK_LCOMMENT", w(false, a))
                else                            -- short comment
                  o = h(e, "[\n\r]", t) or (#e + 1)
                  i("TK_COMMENT", s(e, n, o - 1))
                end
                break -- (continue)
              end
              -- (fall through for "-")
            else                                -- [ or long string
              local e = c(t)
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
      local e = s(e, t, t)
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
v.lparser =
function()
--start of inserted module
module "lparser"

local k = a.require "string"

--[[--------------------------------------------------------------------
-- variable and data structure initialization
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- initialization: main variables
----------------------------------------------------------------------

local j,                  -- grammar-only token tables (token table,
      g,              -- semantic information table, line number
      x,                -- table, cross-reference table)
      S,
      s,                     -- token position

      h,                     -- start line # for error messages
      L,                   -- last line # for ambiguous syntax chk
      t, T, r, m,   -- token, semantic info, line
      p,                  -- proper position of <name> token
      o,                       -- current function state
      W,                   -- top-level function state

      _,               -- global variable information table
      D,             -- global variable name lookup table
      u,                -- local variable information table
      b,               -- inactive locals (prior to activation)
      N,               -- corresponding references to activate
      E                  -- statements labeled by type

-- forward references for local functions
local y, c, q, O, I, z

----------------------------------------------------------------------
-- initialization: data structures
----------------------------------------------------------------------

local e = k.gmatch

local R = {}         -- lookahead check in chunk(), returnstat()
for e in e("else elseif end until <eof>", "%S+") do
  R[e] = true
end

local H = {}          -- binary operators, left priority
local Y = {}         -- binary operators, right priority
for e, t, a in e([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]], "{(%S+)%s(%d+)%s(%d+)}") do
  H[e] = t + 0
  Y[e] = a + 0
end

local ee = { ["not"] = true, ["-"] = true,
                ["#"] = true, } -- unary operators
local Z = 8        -- priority for unary operators

--[[--------------------------------------------------------------------
-- support functions
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- formats error message and throws error (duplicated from llex)
-- * a simplified version, does not report what token was responsible
----------------------------------------------------------------------

local function i(e, t)
  local a = error or a.error
  a(k.format("(source):%d: %s", t or r, e))
end

----------------------------------------------------------------------
-- handles incoming token, semantic information pairs
-- * NOTE: 'nextt' is named 'next' originally
----------------------------------------------------------------------

-- reads in next token
local function e()
  L = x[s]
  t, T, r, m
    = j[s], g[s], x[s], S[s]
  s = s + 1
end

-- peek at next token (single lookahead for table constructor)
local function X()
  return j[s]
end

----------------------------------------------------------------------
-- throws a syntax error, or if token expected is not there
----------------------------------------------------------------------

local function d(a)
  local e = t
  if e ~= "<number>" and e ~= "<string>" then
    if e == "<name>" then e = T end
    e = "'"..e.."'"
  end
  i(a.." near "..e)
end

local function f(e)
  d("'"..e.."' expected")
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

local function F(e)
  if t ~= e then f(e) end
end

----------------------------------------------------------------------
-- verify existence of a token, then skip it
----------------------------------------------------------------------

local function n(t)
  F(t); e()
end

----------------------------------------------------------------------
-- throws error if condition not matched
----------------------------------------------------------------------

local function P(e, t)
  if not e then d(t) end
end

----------------------------------------------------------------------
-- verifies token conditions are met or else throw error
----------------------------------------------------------------------

local function l(e, a, t)
  if not i(e) then
    if t == r then
      f(e)
    else
      d("'"..e.."' expected (to close '"..a.."' at line "..t..")")
    end
  end
end

----------------------------------------------------------------------
-- expect that token is a name, return the name
----------------------------------------------------------------------

local function f()
  F("<name>")
  local t = T
  p = m
  e()
  return t
end

----------------------------------------------------------------------
-- adds given string s in string pool, sets e as VK
----------------------------------------------------------------------

local function M(e, t)
  e.k = "VK"
end

----------------------------------------------------------------------
-- consume a name token, adds it to string pool
----------------------------------------------------------------------

local function C(e)
  M(e, f())
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

local function w(i, a)
  local e = o.bl
  local t
  -- locate locallist in current block object or function root object
  if e then
    t = e.locallist
  else
    t = o.locallist
  end
  -- build local variable information object and set localinfo
  local e = #u + 1
  u[e] = {             -- new local variable object
    name = i,                -- local variable name
    xref = { p },         -- xref, first value is declaration
    decl = p,             -- location of declaration, = xref[1]
  }
  if a then               -- "self" must be not be changed
    u[e].isself = true
  end
  -- this can override a local with the same name in the same scope
  -- but first, keep it inactive until it gets activated
  local a = #b + 1
  b[a] = e
  N[a] = t
end

----------------------------------------------------------------------
-- actually activate the variables so that they are visible
-- * remember Lua semantics, e.g. RHS is evaluated first, then LHS
-- * used in parlist(), forbody(), localfunc(), localstat(), body()
----------------------------------------------------------------------

local function A(e)
  local t = #b
  -- i goes from left to right, in order of local allocation, because
  -- of something like: local a,a,a = 1,2,3 which gives a = 3
  while e > 0 do
    e = e - 1
    local e = t - e
    local a = b[e]            -- local's id
    local t = u[a]
    local o = t.name               -- name of local
    t.act = m                      -- set activation location
    b[e] = nil
    local i = N[e]     -- ref to lookup table to update
    N[e] = nil
    local e = i[o]    -- if existing, remove old first!
    if e then                    -- do not overlap, set special
      t = u[e]         -- form of rem, as -id
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

local function U()
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
    local e = u[e]
    e.rem = m                      -- set deactivation location
  end
end

----------------------------------------------------------------------
-- creates a new local variable given a name
-- * skips internal locals (those starting with '('), so internal
--   locals never needs a corresponding adjustlocalvars() call
-- * special is true for "self" which must not be optimized
-- * used in fornum(), forlist(), parlist(), body()
----------------------------------------------------------------------

local function m(e, t)
  if k.sub(e, 1, 1) == "(" then  -- can skip internal locals
    return
  end
  w(e, t)
end

----------------------------------------------------------------------
-- search the local variable namespace of the given fs for a match
-- * returns localinfo index
-- * used only in singlevaraux()
----------------------------------------------------------------------

local function V(o, a)
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

local function k(t, a, e)
  if t == nil then  -- no more levels?
    e.k = "VGLOBAL"  -- default is global variable
    return "VGLOBAL"
  else
    local o = V(t, a)  -- look up at current level
    if o >= 0 then
      e.k = "VLOCAL"
      e.id = o
      --  codegen may need to deal with upvalue here
      return "VLOCAL"
    else  -- not found at current level; try upper one
      if k(t.prev, a, e) == "VGLOBAL" then
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

local function J(a)
  local t = f()
  k(o, t, a)
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
        xref = { p },             -- xref, first value is declaration
      }
      D[t] = e           -- remember it
    else
      local e = _[e].xref
      e[#e + 1] = p           -- add xref
    end
  else
    -- local/upvalue is being accessed, keep track of it
    local e = a.id
    local e = u[e].xref
    e[#e + 1] = p             -- add xref
  end
end

--[[--------------------------------------------------------------------
-- state management functions with open/close pairs
----------------------------------------------------------------------]]

----------------------------------------------------------------------
-- enters a code unit, initializes elements
----------------------------------------------------------------------

local function p(t)
  local e = {}  -- per-block state
  e.isbreakable = t
  e.prev = o.bl
  e.locallist = {}
  o.bl = e
end

----------------------------------------------------------------------
-- leaves a code unit, close any upvalues
----------------------------------------------------------------------

local function k()
  local e = o.bl
  U()
  o.bl = e.prev
end

----------------------------------------------------------------------
-- opening of a function
-- * top_fs is only for anchoring the top fs, so that parser() can
--   return it to the caller function along with useful output
-- * used in parser() and body()
----------------------------------------------------------------------

local function B()
  local e  -- per-function state
  if not o then  -- top_fs is created early
    e = W
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

local function G()
  U()
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

local function U(a)
  -- field -> ['.' | ':'] NAME
  local t = {}
  e()  -- skip the dot or colon
  C(t)
  a.k = "VINDEXED"
end

----------------------------------------------------------------------
-- parse a table indexing suffix, for constructors, expressions
-- * used in recfield(), primaryexp()
----------------------------------------------------------------------

local function V(t)
  -- index -> '[' expr ']'
  e()  -- skip the '['
  c(t)
  n("]")
end

----------------------------------------------------------------------
-- parse a table record (hash) field
-- * used in constructor()
----------------------------------------------------------------------

local function a(e)
  -- recfield -> (NAME | '['exp1']') = exp1
  local e, a = {}, {}
  if t == "<name>" then
    C(e)
  else-- tok == '['
    V(e)
  end
  n("=")
  c(a)
end

----------------------------------------------------------------------
-- emit a set list instruction if enough elements (LFIELDS_PER_FLUSH)
-- * note: retained in this skeleton because it modifies cc.v.k
-- * used in constructor()
----------------------------------------------------------------------

local function K(e)
  if e.v.k == "VVOID" then return end  -- there is no list item
  e.v.k = "VVOID"
end

----------------------------------------------------------------------
-- parse a table list (array) field
-- * used in constructor()
----------------------------------------------------------------------

local function Q(e)
  c(e.v)
end

----------------------------------------------------------------------
-- parse a table constructor
-- * used in funcargs(), simpleexp()
----------------------------------------------------------------------

local function K(o)
  -- constructor -> '{' [ field { fieldsep field } [ fieldsep ] ] '}'
  -- field -> recfield | listfield
  -- fieldsep -> ',' | ';'
  local s = r
  local e = {}
  e.v = {}
  e.t = o
  o.k = "VRELOCABLE"
  e.v.k = "VVOID"
  n("{")
  repeat
    if t == "}" then break end
    -- closelistfield(cc) here
    local t = t
    if t == "<name>" then  -- may be listfields or recfields
      if X() ~= "=" then  -- look ahead: expression?
        Q(e)
      else
        a(e)
      end
    elseif t == "[" then  -- constructor_item -> recfield
      a(e)
    else  -- constructor_part -> listfield
      Q(e)
    end
  until not i(",") and not i(";")
  l("}", "{", s)
  -- lastlistfield(cc) here
end

----------------------------------------------------------------------
-- parse the arguments (parameters) of a function declaration
-- * used in body()
----------------------------------------------------------------------

local function X()
  -- parlist -> [ param { ',' param } ]
  local a = 0
  if t ~= ")" then  -- is 'parlist' not empty?
    repeat
      local t = t
      if t == "<name>" then  -- param -> NAME
        w(f())
        a = a + 1
      elseif t == "..." then
        e()
        o.is_vararg = true
      else
        d("<name> or '...' expected")
      end
    until o.is_vararg or not i(",")
  end--if
  A(a)
end

----------------------------------------------------------------------
-- parse the parameters of a function call
-- * contrast with parlist(), used in function declarations
-- * used in primaryexp()
----------------------------------------------------------------------

local function Q(n)
  local a = {}
  local i = r
  local o = t
  if o == "(" then  -- funcargs -> '(' [ explist1 ] ')'
    if i ~= L then
      d("ambiguous syntax (function call x new statement)")
    end
    e()
    if t == ")" then  -- arg list is empty?
      a.k = "VVOID"
    else
      y(a)
    end
    l(")", "(", i)
  elseif o == "{" then  -- funcargs -> constructor
    K(a)
  elseif o == "<string>" then  -- funcargs -> STRING
    M(a, T)
    e()  -- must use 'seminfo' before 'next'
  else
    d("function arguments expected")
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

local function te(a)
  -- prefixexp -> NAME | '(' expr ')'
  local t = t
  if t == "(" then
    local t = r
    e()
    c(a)
    l(")", "(", t)
  elseif t == "<name>" then
    J(a)
  else
    d("unexpected symbol")
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
  te(a)
  while true do
    local t = t
    if t == "." then  -- field
      U(a)
    elseif t == "[" then  -- '[' exp1 ']'
      local e = {}
      V(e)
    elseif t == ":" then  -- ':' NAME funcargs
      local t = {}
      e()
      C(t)
      Q(a)
    elseif t == "(" or t == "<string>" or t == "{" then  -- funcargs
      Q(a)
    else
      return
    end--if c
  end--while
end

----------------------------------------------------------------------
-- parses general expression types, constants handled here
-- * used in subexpr()
----------------------------------------------------------------------

local function C(a)
  -- simpleexp -> NUMBER | STRING | NIL | TRUE | FALSE | ... |
  --              constructor | FUNCTION body | primaryexp
  local t = t
  if t == "<number>" then
    a.k = "VKNUM"
  elseif t == "<string>" then
    M(a, T)
  elseif t == "nil" then
    a.k = "VNIL"
  elseif t == "true" then
    a.k = "VTRUE"
  elseif t == "false" then
    a.k = "VFALSE"
  elseif t == "..." then  -- vararg
    P(o.is_vararg == true,
                    "cannot use '...' outside a vararg function");
    a.k = "VVARARG"
  elseif t == "{" then  -- constructor
    K(a)
    return
  elseif t == "function" then
    e()
    I(a, false, r)
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
  local n = ee[a]
  if n then
    e()
    T(o, Z)
  else
    C(o)
  end
  -- expand while operators have priorities higher than 'limit'
  a = t
  local t = H[a]
  while t and t > i do
    local o = {}
    e()
    -- read sub-expression with higher priority
    local e = T(o, Y[a])
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
function c(e)
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

local function T(e)
  local t = {}
  local e = e.v.k
  P(e == "VLOCAL" or e == "VUPVAL" or e == "VGLOBAL"
                  or e == "VINDEXED", "syntax error")
  if i(",") then  -- assignment -> ',' primaryexp assignment
    local e = {}  -- expdesc
    e.v = {}
    L(e.v)
    -- lparser.c deals with some register usage conflict here
    T(e)
  else  -- assignment -> '=' explist1
    n("=")
    y(t)
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
  p(false)  -- scope for declared variables
  A(e)
  q()
  k()  -- end of scope for declared variables
end

----------------------------------------------------------------------
-- parse a numerical for loop, calls forbody()
-- * used in for_stat()
----------------------------------------------------------------------

local function C(e)
  -- fornum -> NAME = exp1, exp1 [, exp1] DO body
  local t = h
  m("(for index)")
  m("(for limit)")
  m("(for step)")
  w(e)
  n("=")
  O()  -- initial value
  n(",")
  O()  -- limit
  if i(",") then
    O()  -- optional step
  else
    -- default step = 1
  end
  a(1, true)
end

----------------------------------------------------------------------
-- parse a generic for loop, calls forbody()
-- * used in for_stat()
----------------------------------------------------------------------

local function H(e)
  -- forlist -> NAME {, NAME} IN explist1 DO body
  local t = {}
  -- create control variables
  m("(for generator)")
  m("(for state)")
  m("(for control)")
  -- create declared variables
  w(e)
  local e = 1
  while i(",") do
    w(f())
    e = e + 1
  end
  n("in")
  local o = h
  y(t)
  a(e, false)
end

----------------------------------------------------------------------
-- parse a function name specification
-- * used in func_stat()
----------------------------------------------------------------------

local function M(e)
  -- funcname -> NAME {field} [':' NAME]
  local a = false
  J(e)
  while t == "." do
    U(e)
  end
  if t == ":" then
    a = true
    U(e)
  end
  return a
end

----------------------------------------------------------------------
-- parse the single expressions needed in numerical for loops
-- * used in fornum()
----------------------------------------------------------------------

-- this is a forward-referenced local
function O()
  -- exp1 -> expr
  local e = {}
  c(e)
end

----------------------------------------------------------------------
-- parse condition in a repeat statement or an if control structure
-- * used in repeat_stat(), test_then_block()
----------------------------------------------------------------------

local function a()
  -- cond -> expr
  local e = {}
  c(e)  -- read condition
end

----------------------------------------------------------------------
-- parse part of an if control structure, including the condition
-- * used in if_stat()
----------------------------------------------------------------------

local function O()
  -- test_then_block -> [IF | ELSEIF] cond THEN block
  e()  -- skip IF or ELSEIF
  a()
  n("then")
  q()  -- 'then' part
end

----------------------------------------------------------------------
-- parse a local function statement
-- * used in local_stat()
----------------------------------------------------------------------

local function Y()
  -- localfunc -> NAME body
  local t, e = {}
  w(f())
  t.k = "VLOCAL"
  A(1)
  I(e, false, r)
end

----------------------------------------------------------------------
-- parse a local variable declaration statement
-- * used in local_stat()
----------------------------------------------------------------------

local function U()
  -- localstat -> NAME {',' NAME} ['=' explist1]
  local e = 0
  local t = {}
  repeat
    w(f())
    e = e + 1
  until not i(",")
  if i("=") then
    y(t)
  else
    t.k = "VVOID"
  end
  A(e)
end

----------------------------------------------------------------------
-- parse a list of comma-separated expressions
-- * used in return_stat(), localstat(), funcargs(), assignment(),
--   forlist()
----------------------------------------------------------------------

-- this is a forward-referenced local
function y(e)
  -- explist1 -> expr { ',' expr }
  c(e)
  while i(",") do
    c(e)
  end
end

----------------------------------------------------------------------
-- parse function declaration body
-- * used in simpleexp(), localfunc(), func_stat()
----------------------------------------------------------------------

-- this is a forward-referenced local
function I(a, t, e)
  -- body ->  '(' parlist ')' chunk END
  B()
  n("(")
  if t then
    m("self", true)
    A(1)
  end
  X()
  n(")")
  z()
  l("end", "function", e)
  G()
end

----------------------------------------------------------------------
-- parse a code block or unit
-- * used in do_stat(), while_stat(), forbody(), test_then_block(),
--   if_stat()
----------------------------------------------------------------------

-- this is a forward-referenced local
function q()
  -- block -> chunk
  p(false)
  z()
  k()
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

local function A()
  -- stat -> for_stat -> FOR (fornum | forlist) END
  local o = h
  p(true)  -- scope for loop and control variables
  e()  -- skip 'for'
  local a = f()  -- first variable name
  local e = t
  if e == "=" then
    C(a)
  elseif e == "," or e == "in" then
    H(a)
  else
    d("'=' or 'in' expected")
  end
  l("end", "for", o)
  k()  -- loop scope (`break' jumps to this point)
end

----------------------------------------------------------------------
-- parse a while-do control structure, body processed by block()
-- * used in stat()
----------------------------------------------------------------------

local function f()
  -- stat -> while_stat -> WHILE cond DO block END
  local t = h
  e()  -- skip WHILE
  a()  -- parse condition
  p(true)
  n("do")
  q()
  l("end", "while", t)
  k()
end

----------------------------------------------------------------------
-- parse a repeat-until control structure, body parsed by chunk()
-- * originally, repeatstat() calls breakstat() too if there is an
--   upvalue in the scope block; nothing is actually lexed, it is
--   actually the common code in breakstat() for closing of upvalues
-- * used in stat()
----------------------------------------------------------------------

local function m()
  -- stat -> repeat_stat -> REPEAT block UNTIL cond
  local t = h
  p(true)  -- loop block
  p(false)  -- scope block
  e()  -- skip REPEAT
  z()
  l("until", "repeat", t)
  a()
  -- close upvalues at scope level below
  k()  -- finish scope
  k()  -- finish loop
end

----------------------------------------------------------------------
-- parse an if control structure
-- * used in stat()
----------------------------------------------------------------------

local function c()
  -- stat -> if_stat -> IF cond THEN block
  --                    {ELSEIF cond THEN block} [ELSE block] END
  local a = h
  local o = {}
  O()  -- IF cond THEN block
  while t == "elseif" do
    O()  -- ELSEIF cond THEN block
  end
  if t == "else" then
    e()  -- skip ELSE
    q()  -- 'else' part
  end
  l("end", "if", a)
end

----------------------------------------------------------------------
-- parse a return statement
-- * used in stat()
----------------------------------------------------------------------

local function w()
  -- stat -> return_stat -> RETURN explist
  local a = {}
  e()  -- skip RETURN
  local e = t
  if R[e] or e == ";" then
    -- return no values
  else
    y(a)  -- optional return values
  end
end

----------------------------------------------------------------------
-- parse a break statement
-- * used in stat()
----------------------------------------------------------------------

local function p()
  -- stat -> break_stat -> BREAK
  local t = o.bl
  e()  -- skip BREAK
  while t and not t.isbreakable do -- find a breakable block
    t = t.prev
  end
  if not t then
    d("no loop to break")
  end
end

----------------------------------------------------------------------
-- parse a function call with no returns or an assignment statement
-- * the struct with .prev is used for name searching in lparse.c,
--   so it is retained for now; present in assignment() also
-- * used in stat()
----------------------------------------------------------------------

local function y()
  local t = s - 1
  -- stat -> expr_stat -> func | assignment
  local e = {}
  e.v = {}
  L(e.v)
  if e.v.k == "VCALL" then  -- stat -> func
    -- call statement uses no results
    E[t] = "call"
  else  -- stat -> assignment
    e.prev = nil
    T(e)
    E[t] = "assign"
  end
end

----------------------------------------------------------------------
-- parse a function statement
-- * used in stat()
----------------------------------------------------------------------

local function d()
  -- stat -> function_stat -> FUNCTION funcname body
  local o = h
  local t, a = {}, {}
  e()  -- skip FUNCTION
  local e = M(t)
  I(a, e, o)
end

----------------------------------------------------------------------
-- parse a simple block enclosed by a DO..END pair
-- * used in stat()
----------------------------------------------------------------------

local function a()
  -- stat -> do_stat -> DO block END
  local t = h
  e()  -- skip DO
  q()
  l("end", "do", t)
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
    Y()
  else
    U()
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

local a = {             -- lookup for calls in stat()
  ["if"] = c,
  ["while"] = f,
  ["do"] = a,
  ["for"] = A,
  ["repeat"] = m,
  ["function"] = d,
  ["local"] = n,
  ["return"] = w,
  ["break"] = p,
}

local function n()
  -- stat -> if_stat while_stat do_stat for_stat repeat_stat
  --         function_stat local_stat return_stat break_stat
  --         expr_stat
  h = r  -- may be needed for error messages
  local e = t
  local t = a[e]
  -- handles: if while do for repeat function local return break
  if t then
    E[s - 1] = e
    t()
    -- return or break must be last statement
    if e == "return" or e == "break" then return true end
  else
    y()
  end
  return false
end

----------------------------------------------------------------------
-- parse a chunk, which consists of a bunch of statements
-- * used in parser(), body(), block(), repeat_stat()
----------------------------------------------------------------------

-- this is a forward-referenced local
function z()
  -- chunk -> { stat [';'] }
  local e = false
  while not e and not R[t] do
    e = n()
    i(";")
  end
end

----------------------------------------------------------------------
-- performs parsing, returns parsed data structure
----------------------------------------------------------------------

function parser()
  B()
  o.is_vararg = true  -- main func. is always vararg
  e()  -- read first token
  z()
  F("<eof>")
  G()
  return {  -- return everything
    globalinfo = _,
    localinfo = u,
    statinfo = E,
    toklist = j,
    seminfolist = g,
    toklnlist = x,
    xreflist = S,
  }
end

----------------------------------------------------------------------
-- initialization function
----------------------------------------------------------------------

function init(e, i, n)
  s = 1                      -- token position
  W = {}                   -- reset top level function state
  ------------------------------------------------------------------
  -- set up grammar-only token tables; impedance-matching...
  -- note that constants returned by the lexer is source-level, so
  -- for now, fake(!) constant tokens (TK_NUMBER|TK_STRING|TK_LSTRING)
  ------------------------------------------------------------------
  local t = 1
  j, g, x, S = {}, {}, {}, {}
  for a = 1, #e do
    local e = e[a]
    local o = true
    if e == "TK_KEYWORD" or e == "TK_OP" then
      e = i[a]
    elseif e == "TK_NAME" then
      e = "<name>"
      g[t] = i[a]
    elseif e == "TK_NUMBER" then
      e = "<number>"
      g[t] = 0  -- fake!
    elseif e == "TK_STRING" or e == "TK_LSTRING" then
      e = "<string>"
      g[t] = ""  -- fake!
    elseif e == "TK_EOS" then
      e = "<eof>"
    else
      -- non-grammar tokens; ignore them
      o = false
    end
    if o then  -- set rest of the information
      j[t] = e
      x[t] = n[a]
      S[t] = a
      t = t + 1
    end
  end--for
  ------------------------------------------------------------------
  -- initialize data structures for variable tracking
  ------------------------------------------------------------------
  _, D, u = {}, {}, {}
  b, N = {}, {}
  E = {}  -- experimental
end
--end of inserted module
end

-- preload function for module optlex
v.optlex =
function()
--start of inserted module
module "optlex"

local m = a.require "string"
local i = m.match
local e = m.sub
local d = m.find
local u = m.rep
local c

------------------------------------------------------------------------
-- variables and data structures
------------------------------------------------------------------------

-- error function, can override by setting own function into module
error = a.error

warn = {}                       -- table for warning flags

local n, o, l    -- source lists

local p = {          -- significant (grammar) tokens
  TK_KEYWORD = true,
  TK_NAME = true,
  TK_NUMBER = true,
  TK_STRING = true,
  TK_LSTRING = true,
  TK_OP = true,
  TK_EOS = true,
}
local g = {          -- whitespace (non-grammar) tokens
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

local function k(t)
  local e = n[t + 1]
  if t >= #n or e == "TK_EOL" or e == "TK_EOS" then
    return true
  elseif e == "" then
    return k(t + 1)
  end
  return false
end

------------------------------------------------------------------------
-- counts comment EOLs inside a long comment
-- * in order to keep line numbering, EOLs need to be reinserted
------------------------------------------------------------------------

local function T(t)
  local a = #i(t, "^%-%-%[=*%[")
  local a = e(t, a + 1, -(a - 1))  -- remove delims
  local e, t = 1, 0
  while true do
    local o, n, i, a = d(a, "([\r\n])([\r\n]?)", e)
    if not o then break end     -- if no matches, done
    e = o + 1
    t = t + 1
    if #a > 0 and i ~= a then   -- skip CRLF or LFCR
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

local function y(s, h)
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
  local a, s, i = {}, {}, {}
  local e = 1
  for t = 1, #n do
    local n = n[t]
    if n ~= "" then
      a[e], s[e], i[e] = n, o[t], l[t]
      e = e + 1
    end
  end
  n, o, l = a, s, i
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

local function z(h)
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
    local h, s = i(t, "^(%d*)%.(%d*)$")
    if h then
      o = o - #s
      t = h..s
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
        n = t..u("0", o)
      elseif o < 0 and (o >= -#t) then  -- fraction, e.g. .123
        s = #t + o
        n = e(t, 1, s).."."..e(t, s + 1)
      elseif o < 0 and (#a >= -o - #t) then
        -- e.g. compare 1234e-5 versus .01234
        -- gives: #sig + 1 + #nex >= 1 + (-ex - #sig) + #sig
        --     -> #nex >= -ex - #sig
        s = -o - #t
        n = "."..u("0", s)..t
      else  -- non-canonical scientific representation
        n = t.."e"..o
      end
    end--if sig
  end
  --------------------------------------------------------------------
  if n and n ~= o[h] then
    if r then
      c("<number> (line "..l[h]..") "..o[h].." -> "..n)
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

local function _(u)
  local t = o[u]
  local s = e(t, 1, 1)                 -- delimiter used
  local w = (s == "'") and '"' or "'"  -- opposite " <-> '
  local t = e(t, 2, -2)                    -- actual string
  local a = 1
  local f, h = 0, 0                -- "/' counts
  --------------------------------------------------------------------
  while a <= #t do
    local u = e(t, a, a)
    ----------------------------------------------------------------
    if u == "\\" then                   -- escaped stuff
      local o = a + 1
      local r = e(t, o, o)
      local n = d("abfnrtv\\\n\r\"\'0123456789", r, 1, true)
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
          f = f + 1
          a = a + 2
        else
          h = h + 1
          t = e(t, 1, a - 1)..e(t, o)
          a = a + 1
        end
      ------------------------------------------------------------
      else                              -- \ddd -- various steps
        local n = i(t, "^(%d%d?%d?)", o)
        o = a + 1 + #n                  -- skip to location
        local l = n + 0
        local r = m.char(l)
        local d = d("\a\b\f\n\r\t\v", r, 1, true)
        if d then                       -- special escapes
          n = "\\"..e("abfnrtv", d, d)
        elseif l < 32 then             -- normalized \ddd
          if i(e(t, o, o), "%d") then
            -- if a digit follows, \ddd cannot be shortened
            n = "\\"..n
          else
            n = "\\"..l
          end
        elseif r == s then         -- \<delim>
          n = "\\"..r
          f = f + 1
        elseif r == "\\" then          -- \\
          n = "\\\\"
        else                            -- literal character
          n = r
          if r == w then
            h = h + 1
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
        h = h + 1
      end
    ----------------------------------------------------------------
    end--if c
  end--while
  --------------------------------------------------------------------
  -- switching delimiters, a long-winded derivation:
  -- (1) delim takes 2+2*c_delim bytes, ndelim takes c_ndelim bytes
  -- (2) delim becomes c_delim bytes, ndelim becomes 2+2*c_ndelim bytes
  -- simplifying the condition (1)>(2) --> c_delim > c_ndelim
  if f > h then
    a = 1
    while a <= #t do
      local o, n, i = d(t, "([\'\"])", a)
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
      c("<string> (line "..l[u]..") "..o[u].." -> "..t)
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

local function E(s)
  local t = o[s]
  local r = i(t, "^%[=*%[")  -- cut out delimiters
  local a = #r
  local c = e(t, -a, -1)
  local h = e(t, a + 1, -(a + 1))  -- lstring without delims
  local n = ""
  local t = 1
  --------------------------------------------------------------------
  while true do
    local a, o, d, r = d(h, "([\r\n])([\r\n]?)", t)
    -- deal with a single line
    local o
    if not a then
      o = e(h, t)
    elseif a >= t then
      o = e(h, t, a - 1)
    end
    if o ~= "" then
      -- flag a warning if there are trailing spaces, won't optimize!
      if i(o, "%s+$") then
        warn.LSTRING = "trailing whitespace in long string near line "..l[s]
      end
      n = n..o
    end
    if not a then  -- done if no more EOLs
      break
    end
    -- deal with line endings, normalize them
    t = a + 1
    if a then
      if #r > 0 and d ~= r then  -- skip CRLF or LFCR
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
      local a = "%]"..u("=", e - 2).."%]"
      if not i(n, a) then t = e end
      e = e - 1
    end
    if t then  -- change delimiters
      a = u("=", t - 2)
      r, c = "["..a.."[", "]"..a.."]"
    end
  end
  --------------------------------------------------------------------
  o[s] = r..n..c
end

------------------------------------------------------------------------
-- long comment optimization
-- * note: does not remove first optional newline
-- * trim trailing whitespace
-- * normalize embedded newlines
-- * reduce '=' separators in delimiters if possible
------------------------------------------------------------------------

local function q(r)
  local a = o[r]
  local s = i(a, "^%-%-%[=*%[")  -- cut out delimiters
  local t = #s
  local l = e(a, -t, -1)
  local h = e(a, t + 1, -(t - 1))  -- comment without delims
  local n = ""
  local a = 1
  --------------------------------------------------------------------
  while true do
    local o, t, r, s = d(h, "([\r\n])([\r\n]?)", a)
    -- deal with a single line, extract and check trailing whitespace
    local t
    if not o then
      t = e(h, a)
    elseif o >= a then
      t = e(h, a, o - 1)
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
      if #s > 0 and r ~= s then  -- skip CRLF or LFCR
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
      local t = "%]"..u("=", e - 2).."%]"
      if not i(n, t) then a = e end
      e = e - 1
    end
    if a then  -- change delimiters
      t = u("=", a - 2)
      s, l = "--["..t.."[", "]"..t.."]"
    end
  end
  --------------------------------------------------------------------
  o[r] = s..n..l
end

------------------------------------------------------------------------
-- short comment optimization
-- * trim trailing whitespace
------------------------------------------------------------------------

local function x(n)
  local t = o[n]
  local a = i(t, "%s*$")        -- just look from end of string
  if #a > 0 then
    t = e(t, 1, -(a + 1))      -- trim trailing whitespace
  end
  o[n] = t
end

------------------------------------------------------------------------
-- returns true if string found in long comment
-- * this is a feature to keep copyright or license texts
------------------------------------------------------------------------

local function N(o, t)
  if not o then return false end  -- option not set
  local a = i(t, "^%-%-%[=*%[")  -- cut out delimiters
  local a = #a
  local i = e(t, -a, -1)
  local e = e(t, a + 1, -(a - 1))  -- comment without delims
  if d(e, o, 1, true) then  -- try to match
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

function optimize(t, h, s, i)
  --------------------------------------------------------------------
  -- set option flags
  --------------------------------------------------------------------
  local m = t["opt-comments"]
  local d = t["opt-whitespace"]
  local f = t["opt-emptylines"]
  local j = t["opt-eols"]
  local A = t["opt-strings"]
  local O = t["opt-numbers"]
  local v = t["opt-experimental"]
  local I = t.KEEP
  r = t.DETAILS and 0  -- upvalues for details display
  c = c or a.print
  if j then  -- forced settings, otherwise won't work properly
    m = true
    d = true
    f = true
  elseif v then
    d = true
  end
  --------------------------------------------------------------------
  -- variable initialization
  --------------------------------------------------------------------
  n, o, l                -- set source lists
    = h, s, i
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
  if v then
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
      if O then
        z(t)  -- optimize
      end
      s = t
    ----------------------------------------------------------------
    elseif a == "TK_STRING" or        -- strings, long strings
           a == "TK_LSTRING" then
      if A then
        if a == "TK_STRING" then
          _(t)  -- optimize
        else
          E(t)  -- optimize
        end
      end
      s = t
    ----------------------------------------------------------------
    elseif a == "TK_COMMENT" then     -- short comments
      if m then
        if t == 1 and e(h, 1, 1) == "#" then
          -- keep shbang comment, trim whitespace
          x(t)
        else
          -- safe to delete, as a TK_EOL (or TK_EOS) always follows
          i()  -- remove entirely
        end
      elseif d then        -- trim whitespace only
        x(t)
      end
    ----------------------------------------------------------------
    elseif a == "TK_LCOMMENT" then    -- long comments
      if N(I, h) then
        ------------------------------------------------------------
        -- if --keep, we keep a long comment if <msg> is found;
        -- this is a feature to keep copyright or license texts
        if d then          -- trim whitespace only
          q(t)
        end
        s = t
      elseif m then
        local e = T(h)
        ------------------------------------------------------------
        -- prepare opt_emptylines case first, if a disposable token
        -- follows, current one is safe to dump, else keep a space;
        -- it is implied that the operation is safe for '-', because
        -- current is a TK_LCOMMENT, and must be separate from a '-'
        if g[n[t + 1]] then
          i()  -- remove entirely
          a = ""
        else
          i("TK_SPACE", " ")
        end
        ------------------------------------------------------------
        -- if there are embedded EOLs to keep and opt_emptylines is
        -- disabled, then switch the token into one or more EOLs
        if not f and e > 0 then
          i("TK_EOL", u("\n", e))
        end
        ------------------------------------------------------------
        -- if optimizing whitespaces, force reinterpretation of the
        -- token to give a chance for the space to be optimized away
        if d and a ~= "" then
          t = t - 1  -- to reinterpret
        end
        ------------------------------------------------------------
      else                              -- disabled case
        if d then          -- trim whitespace only
          q(t)
        end
        s = t
      end
    ----------------------------------------------------------------
    elseif a == "TK_EOL" then         -- line endings
      if r and f then
        i()  -- remove entirely
      elseif h == "\r\n" or h == "\n\r" then
        -- normalize the rest of the EOLs for CRLF/LFCR only
        -- (note that TK_LCOMMENT can change into several EOLs)
        i("TK_EOL", "\n")
      end
    ----------------------------------------------------------------
    elseif a == "TK_SPACE" then       -- whitespace
      if d then
        if r or k(t) then
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
            if g[e] then
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
              local e = y(s, t + 1)
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
  if j then
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
        if p[a] and p[e] then  -- sanity check
          local t = y(t - 1, t + 1)
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
  if r and r > 0 then c() end -- spacing
  return n, o, l
end
--end of inserted module
end

-- preload function for module optparser
v.optparser =
function()
--start of inserted module
module "optparser"

local s = a.require "string"
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
local r = "etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"

-- names or identifiers that must be skipped
-- * the first two lines are for keywords
local T = {}
for e in s.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]], "%S+") do
  T[e] = true
end

------------------------------------------------------------------------
-- variables and data structures
------------------------------------------------------------------------

local h, c,             -- token lists (lexer output)
      n, k, y,      -- token lists (parser output)
      x, o,            -- variable information tables
      w,                         -- statment type table
      q, E,            -- unique name tables
      b,                          -- index of new variable names
      l                           -- list of output variables

----------------------------------------------------------------------
-- preprocess information table to get lists of unique names
----------------------------------------------------------------------

local function z(e)
  local o = {}
  for n = 1, #e do              -- enumerate info table
    local e = e[n]
    local i = e.name
    --------------------------------------------------------------------
    if not o[i] then         -- not found, start an entry
      o[i] = {
        decl = 0, token = 0, size = 0,
      }
    end
    --------------------------------------------------------------------
    local t = o[i]        -- count declarations, tokens, size
    t.decl = t.decl + 1
    local o = e.xref
    local a = #o
    t.token = t.token + a
    t.size = t.size + a * #i
    --------------------------------------------------------------------
    if e.decl then            -- if local table, create first,last pairs
      e.id = n
      e.xcount = a
      if a > 1 then        -- if ==1, means local never accessed
        e.first = o[2]
        e.last = o[a]
      end
    --------------------------------------------------------------------
    else                        -- if global table, add a back ref
      t.id = n
    end
    --------------------------------------------------------------------
  end--for
  return o
end

----------------------------------------------------------------------
-- calculate actual symbol frequencies, in order to reduce entropy
-- * this may help further reduce the size of compressed sources
-- * note that since parsing optimizations is put before lexing
--   optimizations, the frequency table is not exact!
-- * yes, this will miss --keep block comments too...
----------------------------------------------------------------------

local function O(e)
  local d = s.byte
  local s = s.char
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
        local t = d(a, t)
        e[t] = e[t] + 1
      end
    end--if
  end--for
  --------------------------------------------------------------------
  -- function to re-sort symbols according to actual frequencies
  --------------------------------------------------------------------
  local function n(o)
    local t = {}
    for a = 1, #o do              -- prepare table to sort
      local o = d(o, a)
      t[a] = { c = o, freq = e[o], }
    end
    g.sort(t,                 -- sort selected symbols
      function(t, e)
        return t.freq > e.freq
      end
    )
    local e = {}                 -- reconstitute the string
    for a = 1, #t do
      e[a] = s(t[a].c)
    end
    return g.concat(e)
  end
  --------------------------------------------------------------------
  i = n(i)             -- change letter arrangement
  r = n(r)
end

----------------------------------------------------------------------
-- returns a string containing a new local variable name to use, and
-- a flag indicating whether it collides with a global variable
-- * trapping keywords and other names like 'self' is done elsewhere
----------------------------------------------------------------------

local function I()
  local t
  local n, h = #i, #r
  local e = b
  if e < n then                  -- single char
    e = e + 1
    t = s.sub(i, e, e)
  else                                  -- longer names
    local o, a = n, 1       -- calculate # chars fit
    repeat
      e = e - o
      o = o * h
      a = a + 1
    until o > e
    local o = e % n              -- left side cycles faster
    e = (e - o) / n              -- do first char first
    o = o + 1
    t = s.sub(i, o, o)
    while a > 1 do
      local o = e % h
      e = (e - o) / h
      o = o + 1
      t = t..s.sub(r, o, o)
      a = a - 1
    end
  end
  b = b + 1
  return t, q[t] ~= nil
end

----------------------------------------------------------------------
-- calculate and print some statistics
-- * probably better in main source, put here for now
----------------------------------------------------------------------

local function N(E, O, A, i)
  local e = p or a.print
  local t = s.format
  local I = i.DETAILS
  if i.QUIET then return end
  local m , w, y, T, z,  -- stats needed
        q, p, f, _, x,
        h, c, u, k, j,
        n, d, r, v, b
    = 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  local function i(e, t)              -- safe average function
    if e == 0 then return 0 end
    return t / e
  end
  --------------------------------------------------------------------
  -- collect statistics (note: globals do not have declarations!)
  --------------------------------------------------------------------
  for t, e in a.pairs(E) do
    m = m + 1
    h = h + e.token
    n = n + e.size
  end
  for t, e in a.pairs(O) do
    w = w + 1
    p = p + e.decl
    c = c + e.token
    d = d + e.size
  end
  for t, e in a.pairs(A) do
    y = y + 1
    f = f + e.decl
    u = u + e.token
    r = r + e.size
  end
  T = m + w
  _ = q + p
  k = h + c
  v = n + d
  z = m + y
  x = q + f
  j = h + u
  b = n + r
  --------------------------------------------------------------------
  -- detailed stats: global list
  --------------------------------------------------------------------
  if I then
    local m = {} -- sort table of unique global names by size
    for t, e in a.pairs(E) do
      e.name = t
      m[#m + 1] = e
    end
    g.sort(m,
      function(e, t)
        return e.size > t.size
      end
    )
    local a, y = "%8s%8s%10s  %s", "%8d%8d%10.2f  %s"
    local w = s.rep("-", 44)
    e("*** global variable list (sorted by size) ***\n"..w)
    e(t(a, "Token",  "Input", "Input", "Global"))
    e(t(a, "Count", "Bytes", "Average", "Name"))
    e(w)
    for a = 1, #m do
      local a = m[a]
      e(t(y, a.token, a.size, i(a.token, a.size), a.name))
    end
    e(w)
    e(t(y, h, n, i(h, n), "TOTAL"))
    e(w.."\n")
  --------------------------------------------------------------------
  -- detailed stats: local list
  --------------------------------------------------------------------
    local a, m = "%8s%8s%8s%10s%8s%10s  %s", "%8d%8d%8d%10.2f%8d%10.2f  %s"
    local s = s.rep("-", 70)
    e("*** local variable list (sorted by allocation order) ***\n"..s)
    e(t(a, "Decl.", "Token",  "Input", "Input", "Output", "Output", "Global"))
    e(t(a, "Count", "Count", "Bytes", "Average", "Bytes", "Average", "Name"))
    e(s)
    for a = 1, #l do  -- iterate according to order assigned
      local s = l[a]
      local a = A[s]
      local h, n = 0, 0
      for t = 1, #o do  -- find corresponding old names and calculate
        local e = o[t]
        if e.name == s then
          h = h + e.xcount
          n = n + e.xcount * #e.oldname
        end
      end
      e(t(m, a.decl, a.token, n, i(h, n),
                a.size, i(a.token, a.size), s))
    end
    e(s)
    e(t(m, f, u, d, i(c, d),
              r, i(u, r), "TOTAL"))
    e(s.."\n")
  end--if opt_details
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  local l, o = "%-16s%8s%8s%8s%8s%10s", "%-16s%8d%8d%8d%8d%10.2f"
  local a = s.rep("-", 58)
  e("*** local variable optimization summary ***\n"..a)
  e(t(l, "Variable",  "Unique", "Decl.", "Token", "Size", "Average"))
  e(t(l, "Types", "Names", "Count", "Count", "Bytes", "Bytes"))
  e(a)
  e(t(o, "Global", m, q, h, n, i(h, n)))
  e(a)
  e(t(o, "Local (in)", w, p, c, d, i(c, d)))
  e(t(o, "TOTAL (in)", T, _, k, v, i(k, v)))
  e(a)
  e(t(o, "Local (out)", y, f, u, r, i(u, r)))
  e(t(o, "TOTAL (out)", z, x, j, b, i(j, b)))
  e(a.."\n")
end

----------------------------------------------------------------------
-- delete a token and adjust all relevant tables
-- * horribly inefficient... luckily it's an off-line processor
-- * currently invalidates globalinfo and localinfo (not updated),
--   so any other optimization is done after processing locals
--   (of course, we can also lex the source data again...)
----------------------------------------------------------------------

local function i(e)
  if e < 1 or e >= #n then
    return  -- ignore if invalid (id == #tokpar is <eof> token)
  end
  local o = y[e]        -- position in lexer lists
  local t, a =          -- final indices
    #n, #h
  for e = e + 1, t do      -- shift parser tables
    n[e - 1] = n[e]
    k[e - 1] = k[e]
    y[e - 1] = y[e] - 1
    w[e - 1] = w[e]
  end
  n[t] = nil
  k[t] = nil
  y[t] = nil
  w[t] = nil
  for e = o + 1, a do      -- shift lexer tables
    h[e - 1] = h[e]
    c[e - 1] = c[e]
  end
  h[a] = nil
  c[a] = nil
end

----------------------------------------------------------------------
-- experimental optimization for f("string") statements
-- * safe to delete parentheses without adding whitespace, as both
--   kinds of strings can abut with anything else
----------------------------------------------------------------------

local function d()
  ------------------------------------------------------------------
  local function o(e)          -- find f("string") pattern
    local t = n[e + 1] or ""
    local a = n[e + 2] or ""
    local e = n[e + 3] or ""
    if t == "(" and a == "<string>" and e == ")" then
      return true
    end
  end
  ------------------------------------------------------------------
  local t = 1
  while true do
    local e, a = t, false
    while e <= #n do               -- scan for function pattern
      local n = w[e]
      if n == "call" and o(e) then  -- found, delete ()
        i(e + 1)        -- '('
        i(e + 2)        -- ')' (index shifted by -1)
        a = true
        t = e + 2
      end
      e = e + 1
    end
    if not a then break end
  end
end

----------------------------------------------------------------------
-- local variable optimization
----------------------------------------------------------------------

local function u(h)
  b = 0                           -- reset variable name allocator
  l = {}
  ------------------------------------------------------------------
  -- preprocess global/local tables, handle entropy reduction
  ------------------------------------------------------------------
  q = z(x)
  E = z(o)
  if h["opt-entropy"] then         -- for entropy improvement
    O(h)
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
  local a, t, r = {}, 1, false
  for o = 1, #e do
    local e = e[o]
    if not e.isself then
      a[t] = e
      t = t + 1
    else
      r = true
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
    local n, t
    repeat
      n, t = I()  -- collect a variable name
    until not T[n]          -- skip all special names
    l[#l + 1] = n       -- keep a list
    local a = s
    ------------------------------------------------------------------
    -- if variable name collides with an existing global, the name
    -- cannot be used by a local when the name is accessed as a global
    -- during which the local is alive (between 'act' to 'rem'), so
    -- we drop objects that collides with the corresponding global
    ------------------------------------------------------------------
    if t then
      -- find the xref table of the global
      local i = x[q[n].id].xref
      local n = #i
      -- enumerate for all current objects; all are valid at this point
      for t = 1, s do
        local t = e[t]
        local s, e = t.act, t.rem  -- 'live' range of local
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
          t.skip = true
          a = a - 1
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
    while a > 0 do
      local t = 1
      while e[t].skip do  -- scan for first object
        t = t + 1
      end
      ------------------------------------------------------------------
      -- first object is free for assignment of the variable name
      -- [first,last] gives the access range for collision checking
      ------------------------------------------------------------------
      a = a - 1
      local i = e[t]
      t = t + 1
      i.newname = n
      i.skip = true
      i.done = true
      local s, r = i.first, i.last
      local h = i.xref
      ------------------------------------------------------------------
      -- then, scan all the rest and drop those colliding
      -- if A was never accessed then it'll never collide with anything
      -- otherwise trivial skip if:
      -- * B was activated after A's last access (last < act)
      -- * B was removed before A's first access (first > rem)
      -- if not, see detailed skip below...
      ------------------------------------------------------------------
      if s and a > 0 then  -- must have at least 1 access
        local n = a
        while n > 0 do
          while e[t].skip do  -- next valid object
            t = t + 1
          end
          n = n - 1
          local e = e[t]
          t = t + 1
          local n, t = e.act, e.rem  -- live range of B
          -- if rem < 0, extend range of rem thru' following local
          while t < 0 do
            t = o[-t].rem
          end
          --------------------------------------------------------
          if not(r < n or s > t) then  -- possible collision
            --------------------------------------------------------
            -- B is activated later than A or at the same statement,
            -- this means for no collision, A cannot be accessed when B
            -- is alive, since B overrides A (or is a peer)
            --------------------------------------------------------
            if n >= i.act then
              for o = 1, i.xcount do  -- ... then check every access
                local o = h[o]
                if o >= n and o <= t then  -- A accessed when B live!
                  a = a - 1
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
                a = a - 1
                e.skip = true
              end
            end
          end
          --------------------------------------------------------
          if a == 0 then break end
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
    local a = e.xref
    if e.newname then                 -- if got new name, patch it in
      for t = 1, e.xcount do
        local t = a[t]               -- xrefs indexes the token list
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
  if r then  -- add 'self' to end of list
    l[#l + 1] = "self"
  end
  local e = z(o)
  N(q, E, e, h)
end


----------------------------------------------------------------------
-- main entry point
----------------------------------------------------------------------

function optimize(t, i, a, e)
  -- set tables
  h, c                  -- from lexer
    = i, a
  n, k, y           -- from parser
    = e.toklist, e.seminfolist, e.xreflist
  x, o, w       -- from parser
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
    d()
  end
end
--end of inserted module
end

-- preload function for module equiv
v.equiv =
function()
--start of inserted module
module "equiv"

local e = a.require "string"
local r = a.loadstring
local u = e.sub
local d = e.match
local s = e.dump
local p = e.byte

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

function init(o, t, a)
  i = o
  e = t
  h = a
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
    local e = r("return "..e, "z")
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
  local e, r = n(t)        -- original
  local a, h = n(l)      -- compressed
  --------------------------------------------------------------------
  -- compare shbang lines ignoring EOL
  --------------------------------------------------------------------
  local n = d(t, "^(#[^\r\n]*)")
  local t = d(l, "^(#[^\r\n]*)")
  if n or t then
    if not n or not t or n ~= t then
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
    local a, n = r[t], h[t]
    if e ~= s then  -- by type
      o("type ["..t.."] "..e.." "..s)
      break
    end
    if e == "TK_KEYWORD" or e == "TK_NAME" or e == "TK_OP" then
      if e == "TK_NAME" and i["opt-locals"] then
        -- can't compare identifiers of locals that are optimized
      elseif a ~= n then  -- by semantic info (simple)
        o("seminfo ["..t.."] "..e.." "..a.." "..n)
        break
      end
    elseif e == "TK_EOS" then
      -- no seminfo to compare
    else-- "TK_NUMBER" or "TK_STRING" or "TK_LSTRING"
      -- compare 'binary' form, so dump a function
      local i,s = u(a), u(n)
      if not i or not s or i ~= s then
        o("seminfo ["..t.."] "..e.." "..a.." "..n)
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
  local q = 1
  local k  = 3
  local j  = 4
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
    local t = d(e, "^(#[^\r\n]*\r?\n?)")
    if t then                      -- cut out shbang
      e = u(e, #t + 1)
    end
    return e
  end
  --------------------------------------------------------------------
  -- attempt to compile, then dump to get binary chunk string
  --------------------------------------------------------------------
  local t = r(a(n), "z")
  if not t then
    e("failed to compile original sources for binary chunk comparison")
    return
  end
  local a = r(a(o), "z")
  if not a then
    e("failed to compile compressed result for binary chunk comparison")
  end
  -- if loadstring() works, dump assuming string.dump() is error-free
  local i = { i = 1, dat = s(t) }
  i.len = #i.dat
  local l = { i = 1, dat = s(a) }
  l.len = #l.dat
  --------------------------------------------------------------------
  -- support functions to handle binary chunk reading
  --------------------------------------------------------------------
  local g,
        d, c,               -- sizes of data types
        y, w,
        o, m
  --------------------------------------------------------------------
  local function s(e, t)          -- check if bytes exist
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
    return p(a)
  end
  --------------------------------------------------------------------
  local function x(a)            -- return an int value (little-endian)
    local e, t = 0, 1
    if not s(a, d) then return end
    for o = 1, d do
      e = e + t * n(a)
      t = t * 256
    end
    return e
  end
  --------------------------------------------------------------------
  local function z(t)            -- return an int value (big-endian)
    local e = 0
    if not s(t, d) then return end
    for a = 1, d do
      e = e * 256 + n(t)
    end
    return e
  end
  --------------------------------------------------------------------
  local function E(a)          -- return a size_t value (little-endian)
    local t, e = 0, 1
    if not s(a, c) then return end
    for o = 1, c do
      t = t + e * n(a)
      e = e * 256
    end
    return t
  end
  --------------------------------------------------------------------
  local function _(t)          -- return a size_t value (big-endian)
    local e = 0
    if not s(t, c) then return end
    for a = 1, c do
      e = e * 256 + n(t)
    end
    return e
  end
  --------------------------------------------------------------------
  local function r(e, o)        -- return a block (as a string)
    local t = e.i
    local a = t + o - 1
    if a > e.len then return end
    local a = u(e.dat, t, a)
    e.i = t + o
    return a
  end
  --------------------------------------------------------------------
  local function h(t)           -- return a string
    local e = m(t)
    if not e then return end
    if e == 0 then return "" end
    return r(t, e)
  end
  --------------------------------------------------------------------
  local function v(t, e)       -- compare byte value
    local e, t = n(t), n(e)
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
  local function p(t, e)        -- compare int value
    local e, t = o(t), o(e)
    if not e or not t or e ~= t then
      return
    end
    return e
  end
  --------------------------------------------------------------------
  -- recursively-called function to compare function prototypes
  --------------------------------------------------------------------
  local function b(t, a)
    -- source name (ignored)
    if not h(t) or not h(a) then
      e("bad source name"); return
    end
    -- linedefined (ignored)
    if not o(t) or not o(a) then
      e("bad linedefined"); return
    end
    -- lastlinedefined (ignored)
    if not o(t) or not o(a) then
      e("bad lastlinedefined"); return
    end
    if not (s(t, 4) and s(a, 4)) then
      e("prototype header broken")
    end
    -- nups (compared)
    if u(t, a) then
      e("bad nups"); return
    end
    -- numparams (compared)
    if u(t, a) then
      e("bad numparams"); return
    end
    -- is_vararg (compared)
    if u(t, a) then
      e("bad is_vararg"); return
    end
    -- maxstacksize (compared)
    if u(t, a) then
      e("bad maxstacksize"); return
    end
    -- code (compared)
    local i = p(t, a)
    if not i then
      e("bad ncode"); return
    end
    local n = r(t, i * y)
    local i = r(a, i * y)
    if not n or not i or n ~= i then
      e("bad code block"); return
    end
    -- constants (compared)
    local i = p(t, a)
    if not i then
      e("bad nconst"); return
    end
    for o = 1, i do
      local o = v(t, a)
      if not o then
        e("bad const type"); return
      end
      if o == q then
        if u(t, a) then
          e("bad boolean value"); return
        end
      elseif o == k then
        local t = r(t, w)
        local a = r(a, w)
        if not t or not a or t ~= a then
          e("bad number value"); return
        end
      elseif o == j then
        local t = h(t)
        local a = h(a)
        if not t or not a or t ~= a then
          e("bad string value"); return
        end
      end
    end
    -- prototypes (compared recursively)
    local i = p(t, a)
    if not i then
      e("bad nproto"); return
    end
    for o = 1, i do
      if not b(t, a) then
        e("bad function prototype"); return
      end
    end
    -- debug information (ignored)
    -- lineinfo (ignored)
    local i = o(t)
    if not i then
      e("bad sizelineinfo1"); return
    end
    local n = o(a)
    if not n then
      e("bad sizelineinfo2"); return
    end
    if not r(t, i * d) then
      e("bad lineinfo1"); return
    end
    if not r(a, n * d) then
      e("bad lineinfo2"); return
    end
    -- locvars (ignored)
    local i = o(t)
    if not i then
      e("bad sizelocvars1"); return
    end
    local n = o(a)
    if not n then
      e("bad sizelocvars2"); return
    end
    for a = 1, i do
      if not h(t) or not o(t) or not o(t) then
        e("bad locvars1"); return
      end
    end
    for t = 1, n do
      if not h(a) or not o(a) or not o(a) then
        e("bad locvars2"); return
      end
    end
    -- upvalues (ignored)
    local i = o(t)
    if not i then
      e("bad sizeupvalues1"); return
    end
    local o = o(a)
    if not o then
      e("bad sizeupvalues2"); return
    end
    for a = 1, i do
      if not h(t) then e("bad upvalues1"); return end
    end
    for t = 1, o do
      if not h(a) then e("bad upvalues2"); return end
    end
    return true
  end
  --------------------------------------------------------------------
  -- parse binary chunks to verify equivalence
  -- * for headers, handle sizes to allow a degree of flexibility
  -- * assume a valid binary chunk is generated, since it was not
  --   generated via external means
  --------------------------------------------------------------------
  if not (s(i, 12) and s(l, 12)) then
    e("header broken")
  end
  f(i, 6)                   -- skip signature(4), version, format
  g    = n(i)       -- 1 = little endian
  d    = n(i)       -- get data type sizes
  c  = n(i)
  y   = n(i)
  w = n(i)
  f(i)                      -- skip integral flag
  f(l, 12)                  -- skip other header (assume similar)
  if g == 1 then           -- set for endian sensitive data we need
    o   = x
    m = E
  else
    o   = z
    m = _
  end
  b(i, l)               -- get prototype at root
  if i.i ~= i.len + 1 then
    e("inconsistent binary chunk1"); return
  elseif l.i ~= l.len + 1 then
    e("inconsistent binary chunk2"); return
  end
  --------------------------------------------------------------------
  -- successful comparison if end is reached with no borks
  --------------------------------------------------------------------
end
--end of inserted module
end

-- preload function for module plugin/html
v["plugin/html"] =
function()
--start of inserted module
module "plugin/html"

local t = a.require "string"
local m = a.require "table"
local r = a.require "io"

------------------------------------------------------------------------
-- constants and configuration
------------------------------------------------------------------------

local h = ".html"
local l = {
  ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;",
  ["'"] = "&apos;", ["\""] = "&quot;",
}

-- simple headers and footers
local f = [[
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
local y = [[
</pre>
</body>
</html>
]]
-- for more, please see wikimain.css from the Lua wiki site
local w = [[
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

local i                    -- local reference to list of options
local e, n             -- filenames
local o, d, u  -- token data

local function s(...)               -- handle quiet option
  if i.QUIET then return end
  a.print(...)
end

------------------------------------------------------------------------
-- initialization
------------------------------------------------------------------------

function init(o, s, r)
  i = o
  e = s
  local o, d = t.find(e, "%.[^%.%\\%/]*$")
  local s, r = e, ""
  if o and o > 1 then
    s = t.sub(e, 1, o - 1)
    r = t.sub(e, o, d)
  end
  n = s..h
  if i.OUTPUT_FILE then
    n = i.OUTPUT_FILE
  end
  if e == n then
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
  s("Exporting: "..e.." -> "..n.."\n")
end

------------------------------------------------------------------------
-- post-lexing processing, can work on lexer table output
------------------------------------------------------------------------

function post_lex(e, a, t)
  o, d, u
    = e, a, t
end

------------------------------------------------------------------------
-- escape the usual suspects for HTML/XML
------------------------------------------------------------------------

local function h(a)
  local e = 1
  while e <= #a do
    local o = t.sub(a, e, e)
    local i = l[o]
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

local function c(t, o)
  local e = r.open(t, "wb")
  if not e then a.error("cannot open \""..t.."\" for writing") end
  local o = e:write(o)
  if not o then a.error("cannot write to \""..t.."\"") end
  e:close()
end

------------------------------------------------------------------------
-- post-parsing processing, gives globalinfo, localinfo
------------------------------------------------------------------------

function post_parse(u, l)
  local r = {}
  local function s(e)         -- html helpers
    r[#r + 1] = e
  end
  local function a(e, t)
    s('<span class="'..e..'">'..t..'</span>')
  end
  ----------------------------------------------------------------------
  for e = 1, #u do     -- mark global identifiers as TK_GLOBAL
    local e = u[e]
    local e = e.xref
    for t = 1, #e do
      local e = e[t]
      o[e] = "TK_GLOBAL"
    end
  end--for
  ----------------------------------------------------------------------
  for e = 1, #l do      -- mark local identifiers as TK_LOCAL
    local e = l[e]
    local e = e.xref
    for t = 1, #e do
      local e = e[t]
      o[e] = "TK_LOCAL"
    end
  end--for
  ----------------------------------------------------------------------
  s(t.format(f,     -- header and leading stuff
    h(e),
    w))
  for e = 1, #o do        -- enumerate token list
    local e, t = o[e], d[e]
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
  s(y)
  c(n, m.concat(r))
  i.EXIT = true
end
--end of inserted module
end

-- preload function for module plugin/sloc
v["plugin/sloc"] =
function()
--start of inserted module
module "plugin/sloc"

local n = a.require "string"
local e = a.require "table"

------------------------------------------------------------------------
-- initialization
------------------------------------------------------------------------

local o                    -- local reference to list of options
local s                     -- source file name

function init(t, e, a)
  o = t
  o.QUIET = true
  s = e
end

------------------------------------------------------------------------
-- splits a block into a table of lines (minus EOLs)
------------------------------------------------------------------------

local function h(o)
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

function post_lex(t, d, r)
  local e, n = 0, 0
  local function i(t)        -- if a new line, count it as an SLOC
    if t > e then           -- new line # must be > old line #
      n = n + 1; e = t
    end
  end
  for e = 1, #t do        -- enumerate over all tokens
    local t, a, e
      = t[e], d[e], r[e]
    --------------------------------------------------------------------
    if t == "TK_KEYWORD" or t == "TK_NAME" or       -- significant
       t == "TK_NUMBER" or t == "TK_OP" then
      i(e)
    --------------------------------------------------------------------
    -- Both TK_STRING and TK_LSTRING may be multi-line, hence, a loop
    -- is needed in order to mark off lines one-by-one. Since llex.lua
    -- currently returns the line number of the last part of the string,
    -- we must subtract in order to get the starting line number.
    --------------------------------------------------------------------
    elseif t == "TK_STRING" then      -- possible multi-line
      local t = h(a)
      e = e - #t + 1
      for t = 1, #t do
        i(e); e = e + 1
      end
    --------------------------------------------------------------------
    elseif t == "TK_LSTRING" then     -- possible multi-line
      local t = h(a)
      e = e - #t + 1
      for a = 1, #t do
        if t[a] ~= "" then i(e) end
        e = e + 1
      end
    --------------------------------------------------------------------
    -- other tokens are comments or whitespace and are ignored
    --------------------------------------------------------------------
    end
  end--for
  a.print(s..": "..n) -- display result
  o.EXIT = true
end
--end of inserted module
end

-- support modules
local o = g "llex"
local l = g "lparser"
local x = g "optlex"
local T = g "optparser"
local j = g "equiv"
local a

--[[--------------------------------------------------------------------
-- messages and textual data
----------------------------------------------------------------------]]

local v = [[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.12.0 (20110913)  Copyright (c) 2005-2008,2011 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]

local f = [[
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

local b = [[
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
local E = [[
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
local A = [[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]

local n = "_"      -- default suffix for file renaming
local I = "plugin/" -- relative location of plugins

--[[--------------------------------------------------------------------
-- startup and initialize option list handling
----------------------------------------------------------------------]]

-- simple error message handler; change to error if traceback wanted
local function i(e)
  p("LuaSrcDiet (error): "..e); os.exit(1)
end
--die = error--DEBUG

if not X(_VERSION, "5.1", 1, 1) then  -- sanity check
  i("requires Lua 5.1 to run")
end

------------------------------------------------------------------------
-- prepares text for list of optimizations, prepare lookup table
------------------------------------------------------------------------

local t = ""
do
  local i = 24
  local o = {}
  for a, n in Z(b, "%s*([^,]+),'([^']+)'") do
    local e = "  "..a
    e = e..s.rep(" ", i - #e)..n.."\n"
    t = t..e
    o[a] = true
    o["--no"..y(a, 3)] = true
  end
  b = o  -- replace OPTION with lookup table
end

f = s.format(f, t, E)

if W then  -- embedded plugins
  local e = "\nembedded plugins:\n"
  for t = 1, #W do
    local t = W[t]
    e = e.."  "..te[t].."\n"
  end
  f = f..e
end

------------------------------------------------------------------------
-- global variable initialization, option set handling
------------------------------------------------------------------------

local _ = n           -- file suffix
local e = {}                       -- program options
local n, h                    -- statistics tables

-- function to set option lookup table based on a text list of options
-- note: additional forced settings for --opt-eols is done in optlex.lua
local function w(t)
  for t in Z(t, "(%-%-%S+)") do
    if y(t, 3, 4) == "no" and        -- handle negative options
       b["--"..y(t, 5)] then
      e[y(t, 5)] = false
    else
      e[y(t, 3)] = true
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
local u = 7

local c = {                      -- EOL names for token dump
  ["\n"] = "LF", ["\r"] = "CR",
  ["\n\r"] = "LFCR", ["\r\n"] = "CRLF",
}

------------------------------------------------------------------------
-- read source code from file
------------------------------------------------------------------------

local function r(t)
  local e = io.open(t, "rb")
  if not e then i('cannot open "'..t..'" for reading') end
  local a = e:read("*a")
  if not a then i('cannot read from "'..t..'"') end
  e:close()
  return a
end

------------------------------------------------------------------------
-- save source code to file
------------------------------------------------------------------------

local function L(t, a)
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
local function z()
  n, h = {}, {}
  for e = 1, #d do
    local e = d[e]
    n[e], h[e] = 0, 0
  end
end

-- add a token to statistics table
local function q(e, t)
  n[e] = n[e] + 1
  h[e] = h[e] + #t
end

-- do totals for statistics table, return average table
local function k()
  local function i(e, t)                      -- safe average function
    if e == 0 then return 0 end
    return t / e
  end
  local o = {}
  local e, t = 0, 0
  for a = 1, u do                   -- total grammar tokens
    local a = d[a]
    e = e + n[a]; t = t + h[a]
  end
  n.TOTAL_TOK, h.TOTAL_TOK = e, t
  o.TOTAL_TOK = i(e, t)
  e, t = 0, 0
  for a = 1, #d do                         -- total all tokens
    local a = d[a]
    e = e + n[a]; t = t + h[a]
    o[a] = i(n[a], h[a])
  end
  n.TOTAL_ALL, h.TOTAL_ALL = e, t
  o.TOTAL_ALL = i(e, t)
  return o
end

--[[--------------------------------------------------------------------
-- main tasks
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- a simple token dumper, minimal translation of seminfo data
------------------------------------------------------------------------

local function S(e)
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
      e = c[e]
    else
      e = "'"..e.."'"
    end
    p(t.." "..e)
  end--for
end

----------------------------------------------------------------------
-- parser dump; dump globalinfo and localinfo tables
----------------------------------------------------------------------

local function R(e)
  local a = p
  --------------------------------------------------------------------
  -- load file and process source input into tokens
  --------------------------------------------------------------------
  local e = r(e)
  o.init(e)
  o.llex()
  local o, t, e
    = o.tok, o.seminfo, o.tokln
  --------------------------------------------------------------------
  -- do parser optimization here
  --------------------------------------------------------------------
  l.init(o, t, e)
  local e = l.parser()
  local t, i =
    e.globalinfo, e.localinfo
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  local o = s.rep("-", 72)
  a("*** Local/Global Variable Tracker Tables ***")
  a(o.."\n GLOBALS\n"..o)
  -- global tables have a list of xref numbers only
  for e = 1, #t do
    local t = t[e]
    local e = "("..e..") '"..t.name.."' -> "
    local t = t.xref
    for o = 1, #t do e = e..t[o].." " end
    a(e)
  end
  -- local tables have xref numbers and a few other special
  -- numbers that are specially named: decl (declaration xref),
  -- act (activation xref), rem (removal xref)
  a(o.."\n LOCALS (decl=declared act=activated rem=removed)\n"..o)
  for e = 1, #i do
    local t = i[e]
    local e = "("..e..") '"..t.name.."' decl:"..t.decl..
                " act:"..t.act.." rem:"..t.rem
    if t.isself then
      e = e.." isself"
    end
    e = e.." -> "
    local t = t.xref
    for o = 1, #t do e = e..t[o].." " end
    a(e)
  end
  a(o.."\n")
end

------------------------------------------------------------------------
-- reads source file(s) and reports some statistics
------------------------------------------------------------------------

local function D(a)
  local e = p
  --------------------------------------------------------------------
  -- load file and process source input into tokens
  --------------------------------------------------------------------
  local t = r(a)
  o.init(t)
  o.llex()
  local t, o = o.tok, o.seminfo
  e(v)
  e("Statistics for: "..a.."\n")
  --------------------------------------------------------------------
  -- collect statistics
  --------------------------------------------------------------------
  z()
  for e = 1, #t do
    local t, e = t[e], o[e]
    q(t, e)
  end--for
  local t = k()
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  local a = s.format
  local function r(e)
    return n[e], h[e], t[e]
  end
  local o, i = "%-16s%8s%8s%10s", "%-16s%8d%8d%10.2f"
  local t = s.rep("-", 42)
  e(a(o, "Lexical",  "Input", "Input", "Input"))
  e(a(o, "Elements", "Count", "Bytes", "Average"))
  e(t)
  for o = 1, #d do
    local o = d[o]
    e(a(i, o, r(o)))
    if o == "TK_EOS" then e(t) end
  end
  e(t)
  e(a(i, "Total Elements", r("TOTAL_ALL")))
  e(t)
  e(a(i, "Total Tokens", r("TOTAL_TOK")))
  e(t.."\n")
end

------------------------------------------------------------------------
-- process source file(s), write output and reports some statistics
------------------------------------------------------------------------

local function H(f, w)
  local function t(...)             -- handle quiet option
    if e.QUIET then return end
    _G.print(...)
  end
  if a and a.init then        -- plugin init
    e.EXIT = false
    a.init(e, f, w)
    if e.EXIT then return end
  end
  t(v)                      -- title message
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
  local r, u, m
    = o.tok, o.seminfo, o.tokln
  if a and a.post_lex then    -- plugin post-lex
    a.post_lex(r, u, m)
    if e.EXIT then return end
  end
  --------------------------------------------------------------------
  -- collect 'before' statistics
  --------------------------------------------------------------------
  z()
  for e = 1, #r do
    local e, t = r[e], u[e]
    q(e, t)
  end--for
  local p = k()
  local v, y = n, h
  --------------------------------------------------------------------
  -- do parser optimization here
  --------------------------------------------------------------------
  T.print = t  -- hack
  l.init(r, u, m)
  local l = l.parser()
  if a and a.post_parse then          -- plugin post-parse
    a.post_parse(l.globalinfo, l.localinfo)
    if e.EXIT then return end
  end
  T.optimize(e, r, u, l)
  if a and a.post_optparse then       -- plugin post-optparse
    a.post_optparse()
    if e.EXIT then return end
  end
  --------------------------------------------------------------------
  -- do lexer optimization here, save output file
  --------------------------------------------------------------------
  local l = x.warn  -- use this as a general warning lookup
  x.print = t  -- hack
  r, u, m
    = x.optimize(e, r, u, m)
  if a and a.post_optlex then         -- plugin post-optlex
    a.post_optlex(r, u, m)
    if e.EXIT then return end
  end
  local a = ee.concat(u)
  -- depending on options selected, embedded EOLs in long strings and
  -- long comments may not have been translated to \n, tack a warning
  if s.find(a, "\r\n", 1, 1) or
     s.find(a, "\n\r", 1, 1) then
    l.MIXEDEOL = true
  end
  --------------------------------------------------------------------
  -- test source and binary chunk equivalence
  --------------------------------------------------------------------
  j.init(e, o, l)
  j.source(c, a)
  j.binary(c, a)
  local m = "before and after lexer streams are NOT equivalent!"
  local c = "before and after binary chunks are NOT equivalent!"
  -- for reporting, die if option was selected, else just warn
  if l.SRC_EQUIV then
    if e["opt-srcequiv"] then i(m) end
  else
    t("*** SRCEQUIV: token streams are sort of equivalent")
    if e["opt-locals"] then
      t("(but no identifier comparisons since --opt-locals enabled)")
    end
    t()
  end
  if l.BIN_EQUIV then
    if e["opt-binequiv"] then i(c) end
  else
    t("*** BINEQUIV: binary chunks are sort of equivalent")
    t()
  end
  --------------------------------------------------------------------
  -- save optimized source stream to output file
  --------------------------------------------------------------------
  L(w, a)
  --------------------------------------------------------------------
  -- collect 'after' statistics
  --------------------------------------------------------------------
  z()
  for e = 1, #r do
    local t, e = r[e], u[e]
    q(t, e)
  end--for
  local o = k()
  --------------------------------------------------------------------
  -- display output
  --------------------------------------------------------------------
  t("Statistics for: "..f.." -> "..w.."\n")
  local a = s.format
  local function r(e)
    return v[e], y[e], p[e],
           n[e],  h[e],  o[e]
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
  if l.LSTRING then
    t("* WARNING: "..l.LSTRING)
  elseif l.MIXEDEOL then
    t("* WARNING: ".."output still contains some CRLF or LFCR line endings")
  elseif l.SRC_EQUIV then
    t("* WARNING: "..m)
  elseif l.BIN_EQUIV then
    t("* WARNING: "..c)
  end
  t()
end

--[[--------------------------------------------------------------------
-- main functions
----------------------------------------------------------------------]]

local r = {...}  -- program arguments
local h = {}
w(E)     -- set to default options at beginning

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
      h = y(t, 1, o - 1)
      s = y(t, o, r)
    end
    a = h.._..s
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
      S(t)
    elseif e.DUMP_PARSER then
      R(t)
    elseif e.READ_ONLY then
      D(t)
    else
      H(t, a)
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
    local s = X(t, "^%-%-?")
    if s == "-" then                 -- single-dash options
      if t == "-h" then
        e.HELP = true; break
      elseif t == "-v" then
        e.VERSION = true; break
      elseif t == "-s" then
        if not n then i("-s option needs suffix specification") end
        _ = n
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
        a = g(I..n)
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
        w(A)
      elseif t == "--dump-lexer" then
        e.DUMP_LEXER = true
      elseif t == "--dump-parser" then
        e.DUMP_PARSER = true
      elseif t == "--details" then
        e.DETAILS = true
      elseif b[t] then  -- lookup optimization options
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
    p(v..f); return true
  elseif e.VERSION then
    p(v); return true
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
