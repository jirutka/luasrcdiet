--[[--------------------------------------------------------------------

  llex.lua: Lua 5.1 lexical analyzer in Lua
  This file is part of LuaSrcDiet, based on Yueliang material.

  Copyright (c) 2008 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- NOTES:
-- * This is a version of the native 5.1.x lexer from Yueliang 0.4.0,
--   with significant modifications to handle LuaSrcDiet's needs:
--   (1) llex.error is an optional error function handler
--   (2) seminfo for strings include their delimiters and no
--       translation operations are performed on them
-- * ADDED shbang handling has been added to support executable scripts
-- * NO localized decimal point replacement magic
-- * NO limit to number of lines
-- * NO support for compatible long strings (LUA_COMPAT_LSTR)
-- * Please read technotes.txt for more technical details.
----------------------------------------------------------------------]]

local w = _G
local l = require "string"
module "llex"

local f = l.find
local y = l.match
local n = l.sub

----------------------------------------------------------------------
-- initialize keyword list, variables
----------------------------------------------------------------------

local v = {}
for e in l.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]], "%S+") do
  v[e] = true
end

-- NOTE: see init() for module variables (externally visible):
--       tok, seminfo, tokln

local e,                -- source stream
      m,         -- name of source
      a,                -- position of lexer
      i,             -- buffer for strings
      d                -- line number

----------------------------------------------------------------------
-- add information to token listing
----------------------------------------------------------------------

local function o(t, a)
  local e = #tok + 1
  tok[e] = t
  seminfo[e] = a
  tokln[e] = d
end

----------------------------------------------------------------------
-- handles line number incrementation and end-of-line characters
----------------------------------------------------------------------

local function u(t, s)
  local n = n
  local i = n(e, t, t)
  t = t + 1  -- skip '\n' or '\r'
  local e = n(e, t, t)
  if (e == "\n" or e == "\r") and (e ~= i) then
    t = t + 1  -- skip '\n\r' or '\r\n'
    i = i..e
  end
  if s then o("TK_EOL", i) end
  d = d + 1
  a = t
  return t
end

----------------------------------------------------------------------
-- initialize lexer for given source _z and source name _sourceid
----------------------------------------------------------------------

function init(i, t)
  e = i                        -- source
  m = t          -- name of source
  a = 1                         -- lexer's position in source
  d = 1                        -- line number
  tok = {}                      -- lexed token list*
  seminfo = {}                  -- lexed semantic information list*
  tokln = {}                    -- line numbers for messages*
                                -- (*) externally visible thru' module
  --------------------------------------------------------------------
  -- initial processing (shbang handling)
  --------------------------------------------------------------------
  local t, n, e, i = f(e, "^(#[^\r\n]*)(\r?\n?)")
  if t then                             -- skip first line
    a = a + #e
    o("TK_COMMENT", e)
    if #i > 0 then u(a, true) end
  end
end

----------------------------------------------------------------------
-- returns a chunk name or id, no truncation for long names
----------------------------------------------------------------------

function chunkid()
  if m and y(m, "^[=@]") then
    return n(m, 2)  -- remove first char
  end
  return "[string]"
end

----------------------------------------------------------------------
-- formats error message and throws error
-- * a simplified version, does not report what token was responsible
----------------------------------------------------------------------

function errorline(e, a)
  local t = error or w.error
  t(l.format("%s:%d: %s", chunkid(), a or d, e))
end
local r = errorline

------------------------------------------------------------------------
-- count separators ("=") in a long string delimiter
------------------------------------------------------------------------

local function m(t)
  local i = n
  local n = i(e, t, t)
  t = t + 1
  local o = #y(e, "=*", t)  -- note, take the length
  t = t + o
  a = t
  return (i(e, t, t) == n) and o or (-o) - 1
end

----------------------------------------------------------------------
-- reads a long string or long comment
----------------------------------------------------------------------

local function p(h, s)
  local t = a + 1  -- skip 2nd '['
  local n = n
  local o = n(e, t, t)
  if o == "\r" or o == "\n" then  -- string starts with a newline?
    t = u(t)  -- skip it
  end
  local l = t
  while true do
    local o, l, d = f(e, "([\r\n%]])", t) -- (long range)
    if not o then
      r(h and "unfinished long string" or
                "unfinished long comment")
    end
    t = o
    if d == "]" then                    -- delimiter test
      if m(t) == s then
        i = n(e, i, a)
        a = a + 1  -- skip 2nd ']'
        return i
      end
      t = a
    else                                -- newline
      i = i.."\n"
      t = u(t)
    end
  end--while
end

----------------------------------------------------------------------
-- reads a string
----------------------------------------------------------------------

local function b(d)
  local t = a
  local s = f
  local h = n
  while true do
    local n, l, o = s(e, "([\n\r\\\"\'])", t) -- (long range)
    if n then
      if o == "\n" or o == "\r" then
        r("unfinished string")
      end
      t = n
      if o == "\\" then                         -- handle escapes
        t = t + 1
        o = h(e, t, t)
        if o == "" then break end -- (EOZ error)
        n = s("abfnrtv\n\r", o, 1, true)
        ------------------------------------------------------
        if n then                               -- special escapes
          if n > 7 then
            t = u(t)
          else
            t = t + 1
          end
        ------------------------------------------------------
        elseif s(o, "%D") then               -- other non-digits
          t = t + 1
        ------------------------------------------------------
        else                                    -- \xxx sequence
          local o, e, a = s(e, "^(%d%d?%d?)", t)
          t = e + 1
          if a + 1 > 256 then -- UCHAR_MAX
            r("escape sequence too large")
          end
        ------------------------------------------------------
        end--if p
      else
        t = t + 1
        if o == d then                        -- ending delimiter
          a = t
          return h(e, i, t - 1)            -- return string
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
  local s = f
  local l = y
  while true do--outer
    local t = a
    -- inner loop allows break to be used to nicely section tests
    while true do--inner
      ----------------------------------------------------------------
      local g, k, c = s(e, "^([_%a][_%w]*)", t)
      if g then
        a = t + #c
        if v[c] then
          o("TK_KEYWORD", c)             -- reserved word (keyword)
        else
          o("TK_NAME", c)                -- identifier
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local f, v, y = s(e, "^(%.?)%d", t)
      if f then                                 -- numeral
        if y == "." then t = t + 1 end
        local d, h, i = s(e, "^%d*[%.%d]*([eE]?)", t)
        t = h + 1
        if #i == 1 then                         -- optional exponent
          if l(e, "^[%+%-]", t) then        -- optional sign
            t = t + 1
          end
        end
        local i, t = s(e, "^[_%w]*", t)
        a = t + 1
        local e = n(e, f, t)                  -- string equivalent
        if not w.tonumber(e) then            -- handles hex test also
          r("malformed number")
        end
        o("TK_NUMBER", e)
        break -- (continue)
      end
      ----------------------------------------------------------------
      local w, f, y, c = s(e, "^((%s)[ \t\v\f]*)", t)
      if w then
        if c == "\n" or c == "\r" then          -- newline
          u(t, true)
        else
          a = f + 1                             -- whitespace
          o("TK_SPACE", y)
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local h = l(e, "^%p", t)
      if h then
        i = t
        local d = s("-[\"\'.=<>~", h, 1, true)
        if d then
          -- two-level if block for punctuation/symbols
          --------------------------------------------------------
          if d <= 2 then
            if d == 1 then                      -- minus
              local r = l(e, "^%-%-(%[?)", t)
              if r then
                t = t + 2
                local h = -1
                if r == "[" then
                  h = m(t)
                end
                if h >= 0 then                -- long comment
                  o("TK_LCOMMENT", p(false, h))
                else                            -- short comment
                  a = s(e, "[\n\r]", t) or (#e + 1)
                  o("TK_COMMENT", n(e, i, a - 1))
                end
                break -- (continue)
              end
              -- (fall through for "-")
            else                                -- [ or long string
              local e = m(t)
              if e >= 0 then
                o("TK_LSTRING", p(true, e))
              elseif e == -1 then
                o("TK_OP", "[")
              else
                r("invalid long string delimiter")
              end
              break -- (continue)
            end
          --------------------------------------------------------
          elseif d <= 5 then
            if d < 5 then                       -- strings
              a = t + 1
              o("TK_STRING", b(h))
              break -- (continue)
            end
            h = l(e, "^%.%.?%.?", t)        -- .|..|... dots
            -- (fall through)
          --------------------------------------------------------
          else                                  -- relational
            h = l(e, "^%p=?", t)
            -- (fall through)
          end
        end
        a = t + #h
        o("TK_OP", h)  -- for other symbols, fall through
        break -- (continue)
      end
      ----------------------------------------------------------------
      local e = n(e, t, t)
      if e ~= "" then
        a = t + 1
        o("TK_OP", e)                    -- other single-char tokens
        break
      end
      o("TK_EOS", "")                    -- end of stream,
      return                                    -- exit here
      ----------------------------------------------------------------
    end--while inner
  end--while outer
end

return w.getfenv()
