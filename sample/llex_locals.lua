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

local c = _G
local h = require "string"
module "llex"

local l = h.find
local m = h.match
local n = h.sub

----------------------------------------------------------------------
-- initialize keyword list, variables
----------------------------------------------------------------------

local w = {}
for e in h.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]], "%S+") do
  w[e] = true
end

-- NOTE: see init() for module variables (externally visible):
--       tok, seminfo, tokln

local e,                -- source stream
      r,         -- name of source
      a,                -- position of lexer
      i,             -- buffer for strings
      s                -- line number

----------------------------------------------------------------------
-- add information to token listing
----------------------------------------------------------------------

local function o(t, a)
  local e = #tok + 1
  tok[e] = t
  seminfo[e] = a
  tokln[e] = s
end

----------------------------------------------------------------------
-- handles line number incrementation and end-of-line characters
----------------------------------------------------------------------

local function d(t, h)
  local n = n
  local i = n(e, t, t)
  t = t + 1  -- skip '\n' or '\r'
  local e = n(e, t, t)
  if (e == "\n" or e == "\r") and (e ~= i) then
    t = t + 1  -- skip '\n\r' or '\r\n'
    i = i..e
  end
  if h then o("TK_EOL", i) end
  s = s + 1
  a = t
  return t
end

----------------------------------------------------------------------
-- initialize lexer for given source _z and source name _sourceid
----------------------------------------------------------------------

function init(i, t)
  e = i                        -- source
  r = t          -- name of source
  a = 1                         -- lexer's position in source
  s = 1                        -- line number
  tok = {}                      -- lexed token list*
  seminfo = {}                  -- lexed semantic information list*
  tokln = {}                    -- line numbers for messages*
                                -- (*) externally visible thru' module
  --------------------------------------------------------------------
  -- initial processing (shbang handling)
  --------------------------------------------------------------------
  local t, n, e, i = l(e, "^(#[^\r\n]*)(\r?\n?)")
  if t then                             -- skip first line
    a = a + #e
    o("TK_COMMENT", e)
    if #i > 0 then d(a, true) end
  end
end

----------------------------------------------------------------------
-- returns a chunk name or id, no truncation for long names
----------------------------------------------------------------------

function chunkid()
  if r and m(r, "^[=@]") then
    return n(r, 2)  -- remove first char
  end
  return "[string]"
end

----------------------------------------------------------------------
-- formats error message and throws error
-- * a simplified version, does not report what token was responsible
----------------------------------------------------------------------

function errorline(e, a)
  local t = error or c.error
  t(h.format("%s:%d: %s", chunkid(), a or s, e))
end
local r = errorline

------------------------------------------------------------------------
-- count separators ("=") in a long string delimiter
------------------------------------------------------------------------

local function u(t)
  local i = n
  local n = i(e, t, t)
  t = t + 1
  local o = #m(e, "=*", t)  -- note, take the length
  t = t + o
  a = t
  return (i(e, t, t) == n) and o or (-o) - 1
end

----------------------------------------------------------------------
-- reads a long string or long comment
----------------------------------------------------------------------

local function f(h, s)
  local t = a + 1  -- skip 2nd '['
  local n = n
  local o = n(e, t, t)
  if o == "\r" or o == "\n" then  -- string starts with a newline?
    t = d(t)  -- skip it
  end
  local o = t
  while true do
    local o, c, l = l(e, "([\r\n%]])", t) -- (long range)
    if not o then
      r(h and "unfinished long string" or
                "unfinished long comment")
    end
    t = o
    if l == "]" then                    -- delimiter test
      if u(t) == s then
        i = n(e, i, a)
        a = a + 1  -- skip 2nd ']'
        return i
      end
      t = a
    else                                -- newline
      i = i.."\n"
      t = d(t)
    end
  end--while
end

----------------------------------------------------------------------
-- reads a string
----------------------------------------------------------------------

local function y(u)
  local t = a
  local s = l
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
            t = d(t)
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
        if o == u then                        -- ending delimiter
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
  local s = l
  local l = m
  while true do--outer
    local t = a
    -- inner loop allows break to be used to nicely section tests
    while true do--inner
      ----------------------------------------------------------------
      local m, p, h = s(e, "^([_%a][_%w]*)", t)
      if m then
        a = t + #h
        if w[h] then
          o("TK_KEYWORD", h)             -- reserved word (keyword)
        else
          o("TK_NAME", h)                -- identifier
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local h, w, m = s(e, "^(%.?)%d", t)
      if h then                                 -- numeral
        if m == "." then t = t + 1 end
        local u, d, i = s(e, "^%d*[%.%d]*([eE]?)", t)
        t = d + 1
        if #i == 1 then                         -- optional exponent
          if l(e, "^[%+%-]", t) then        -- optional sign
            t = t + 1
          end
        end
        local i, t = s(e, "^[_%w]*", t)
        a = t + 1
        local e = n(e, h, t)                  -- string equivalent
        if not c.tonumber(e) then            -- handles hex test also
          r("malformed number")
        end
        o("TK_NUMBER", e)
        break -- (continue)
      end
      ----------------------------------------------------------------
      local m, c, w, h = s(e, "^((%s)[ \t\v\f]*)", t)
      if m then
        if h == "\n" or h == "\r" then          -- newline
          d(t, true)
        else
          a = c + 1                             -- whitespace
          o("TK_SPACE", w)
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
                  h = u(t)
                end
                if h >= 0 then                -- long comment
                  o("TK_LCOMMENT", f(false, h))
                else                            -- short comment
                  a = s(e, "[\n\r]", t) or (#e + 1)
                  o("TK_COMMENT", n(e, i, a - 1))
                end
                break -- (continue)
              end
              -- (fall through for "-")
            else                                -- [ or long string
              local e = u(t)
              if e >= 0 then
                o("TK_LSTRING", f(true, e))
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
              o("TK_STRING", y(h))
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

return c.getfenv()
