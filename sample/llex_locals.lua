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

local f = _G
local l = require "string"
module "llex"

local c = l.find
local w = l.match
local i = l.sub

----------------------------------------------------------------------
-- initialize keyword list, variables
----------------------------------------------------------------------

local y = {}
for e in l.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]], "%S+") do
  y[e] = true
end

-- NOTE: see init() for module variables (externally visible):
--       tok, seminfo, tokln

local e,                -- source stream
      m,         -- name of source
      a,                -- position of lexer
      n,             -- buffer for strings
      u                -- line number

----------------------------------------------------------------------
-- add information to token listing
----------------------------------------------------------------------

local function o(t, a)
  local e = #tok + 1
  tok[e] = t
  seminfo[e] = a
  tokln[e] = u
end

----------------------------------------------------------------------
-- handles line number incrementation and end-of-line characters
----------------------------------------------------------------------

local function r(t, s)
  local n = i
  local i = n(e, t, t)
  t = t + 1  -- skip '\n' or '\r'
  local e = n(e, t, t)
  if (e == "\n" or e == "\r") and (e ~= i) then
    t = t + 1  -- skip '\n\r' or '\r\n'
    i = i..e
  end
  if s then o("TK_EOL", i) end
  u = u + 1
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
  u = 1                        -- line number
  tok = {}                      -- lexed token list*
  seminfo = {}                  -- lexed semantic information list*
  tokln = {}                    -- line numbers for messages*
                                -- (*) externally visible thru' module
  --------------------------------------------------------------------
  -- initial processing (shbang handling)
  --------------------------------------------------------------------
  local t, n, e, i = c(e, "^(#[^\r\n]*)(\r?\n?)")
  if t then                             -- skip first line
    a = a + #e
    o("TK_COMMENT", e)
    if #i > 0 then r(a, true) end
  end
end

----------------------------------------------------------------------
-- returns a chunk name or id, no truncation for long names
----------------------------------------------------------------------

function chunkid()
  if m and w(m, "^[=@]") then
    return i(m, 2)  -- remove first char
  end
  return "[string]"
end

----------------------------------------------------------------------
-- formats error message and throws error
-- * a simplified version, does not report what token was responsible
----------------------------------------------------------------------

function errorline(e, a)
  local t = error or f.error
  t(l.format("%s:%d: %s", chunkid(), a or u, e))
end

------------------------------------------------------------------------
-- count separators ("=") in a long string delimiter
------------------------------------------------------------------------

local function u(t)
  local i = i
  local n = i(e, t, t)
  t = t + 1
  local o = #w(e, "=*", t)  -- note, take the length
  t = t + o
  a = t
  return (i(e, t, t) == n) and o or (-o) - 1
end

----------------------------------------------------------------------
-- reads a long string or long comment
----------------------------------------------------------------------

local function m(d, h)
  local t = a + 1  -- skip 2nd '['
  local s = i
  local i = s(e, t, t)
  if i == "\r" or i == "\n" then  -- string starts with a newline?
    t = r(t)  -- skip it
  end
  local l = t
  while true do
    local o, l, i = c(e, "([\r\n%]])", t) -- (long range)
    if not o then
      errorline(d and "unfinished long string" or
                "unfinished long comment")
    end
    t = o
    if i == "]" then                    -- delimiter test
      if u(t) == h then
        n = s(e, n, a)
        a = a + 1  -- skip 2nd ']'
        return n
      end
      t = a
    else                                -- newline
      n = n.."\n"
      t = r(t)
    end
  end--while
end

----------------------------------------------------------------------
-- reads a string
----------------------------------------------------------------------

local function p(d)
  local t = a
  local s = c
  local h = i
  while true do
    local i, l, o = s(e, "([\n\r\\\"\'])", t) -- (long range)
    if i then
      if o == "\n" or o == "\r" then
        errorline("unfinished string")
      end
      t = i
      if o == "\\" then                         -- handle escapes
        t = t + 1
        o = h(e, t, t)
        if o == "" then break end -- (EOZ error)
        i = s("abfnrtv\n\r", o, 1, true)
        ------------------------------------------------------
        if i then                               -- special escapes
          if i > 7 then
            t = r(t)
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
            errorline("escape sequence too large")
          end
        ------------------------------------------------------
        end--if p
      else
        t = t + 1
        if o == d then                        -- ending delimiter
          a = t
          return h(e, n, t - 1)            -- return string
        end
      end--if r
    else
      break -- (error)
    end--if p
  end--while
  errorline("unfinished string")
end

------------------------------------------------------------------------
-- main lexer function
------------------------------------------------------------------------

function llex()
  local h = c
  local d = w
  while true do--outer
    local t = a
    -- inner loop allows break to be used to nicely section tests
    while true do--inner
      ----------------------------------------------------------------
      local v, b, l = h(e, "^([_%a][_%w]*)", t)
      if v then
        a = t + #l
        if y[l] then
          o("TK_KEYWORD", l)             -- reserved word (keyword)
        else
          o("TK_NAME", l)                -- identifier
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local c, y, w = h(e, "^(%.?)%d", t)
      if c then                                 -- numeral
        if w == "." then t = t + 1 end
        local r, s, n = h(e, "^%d*[%.%d]*([eE]?)", t)
        t = s + 1
        if #n == 1 then                         -- optional exponent
          if d(e, "^[%+%-]", t) then        -- optional sign
            t = t + 1
          end
        end
        local n, t = h(e, "^[_%w]*", t)
        a = t + 1
        local e = i(e, c, t)                  -- string equivalent
        if not f.tonumber(e) then            -- handles hex test also
          errorline("malformed number")
        end
        o("TK_NUMBER", e)
        break -- (continue)
      end
      ----------------------------------------------------------------
      local f, c, w, l = h(e, "^((%s)[ \t\v\f]*)", t)
      if f then
        if l == "\n" or l == "\r" then          -- newline
          r(t, true)
        else
          a = c + 1                             -- whitespace
          o("TK_SPACE", w)
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local s = d(e, "^%p", t)
      if s then
        n = t
        local r = h("-[\"\'.=<>~", s, 1, true)
        if r then
          -- two-level if block for punctuation/symbols
          --------------------------------------------------------
          if r <= 2 then
            if r == 1 then                      -- minus
              local r = d(e, "^%-%-(%[?)", t)
              if r then
                t = t + 2
                local s = -1
                if r == "[" then
                  s = u(t)
                end
                if s >= 0 then                -- long comment
                  o("TK_LCOMMENT", m(false, s))
                else                            -- short comment
                  a = h(e, "[\n\r]", t) or (#e + 1)
                  o("TK_COMMENT", i(e, n, a - 1))
                end
                break -- (continue)
              end
              -- (fall through for "-")
            else                                -- [ or long string
              local e = u(t)
              if e >= 0 then
                o("TK_LSTRING", m(true, e))
              elseif e == -1 then
                o("TK_OP", "[")
              else
                errorline("invalid long string delimiter")
              end
              break -- (continue)
            end
          --------------------------------------------------------
          elseif r <= 5 then
            if r < 5 then                       -- strings
              a = t + 1
              o("TK_STRING", p(s))
              break -- (continue)
            end
            s = d(e, "^%.%.?%.?", t)        -- .|..|... dots
            -- (fall through)
          --------------------------------------------------------
          else                                  -- relational
            s = d(e, "^%p=?", t)
            -- (fall through)
          end
        end
        a = t + #s
        o("TK_OP", s)  -- for other symbols, fall through
        break -- (continue)
      end
      ----------------------------------------------------------------
      local e = i(e, t, t)
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

return f.getfenv()
