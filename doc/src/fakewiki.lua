#!/usr/bin/env lua
--[[--------------------------------------------------------------------

  fakewiki.lua: generate HTML pages from wiki-like sources
  This file is part of LuaSrcDiet.

  Copyright (c) 2008,2011 Kein-Hong Man <keinhong@gmail.com>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- NOTES:
-- * wiki syntax used is broadly similar to that used in the Lua wiki
-- * intended to be self-contained
-- * TODO: check parsing of non-usual filenames
-- * TODO: <p> not generated if do_text() sees a leading empty line
-- * TODO: Lua lexer has no line numbering info, since this wiki
--   generator is not meant for very long pieces of Lua code. It will
--   also fail to lex nested long strings or long comments.
-- * TODO: Lua highlighting does not mark library functions for now
-- * TODO: primitive tables forces align right for simple numbers
--   but the number testing regex is pretty bad
----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- messages, constants
------------------------------------------------------------------------]]

local MSG_TITLE = [[
fakewiki.lua: generate HTML pages from wiki-like sources
Copyright (c) 2008,2011 Kein-Hong Man
The COPYRIGHT file describes the conditions under
which this software may be distributed.

usage: fakewiki.lua [filenames]
]]

local HTML_EXT = ".html"

local ENTITIES = {                      -- standard xml entities
  ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;",
  ["'"] = "&apos;", ["\""] = "&quot;",
}

local PROTOCOLS = {                     -- don't do all protocols...
  http = true, https = true, ftp = true, news = true, nntp = true,
}

local DELIM = {                         -- some wiki delimiter pairs
  ["'''"] = "'''", ["''"] = "''",
  ["{{{"] = "}}}", ["{{"] = "}}",
}

-- simple header
local HEADER = [[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>%s</title>
<meta name="Generator" content="fakewiki.lua">
<style type="text/css">
%s</style>
</head>
<body>
]]

-- simple footer
local FOOTER = [[
</body>
</html>
]]

-- mostly copied from wikimain.css from Lua wiki site
local STYLESHEET = [[
BODY {
    background: white;
    color: navy;
}

A:link { color: #DF6C00 }
A:active, A:visited { color: maroon }

pre.code { color: black; }
span.comment { color: #00a000; }
span.string  { color: #009090; }
span.keyword { color: navy; font-weight: bold; }
span.number { color: #993399; }
span.c_comment { color: #00a000; }
span.c_string { color: #009090; }
span.c_keyword { color: navy; font-weight: bold; }
span.c_number { color: #993399; }
span.c_cpp { color: #7F7F00; }

/* In case of block indent (implemented with table), add cue at left border. */
dd pre.code {
    border-left: 1px dotted maroon;
    margin-left: -1em;
    padding-left: 1em;
}
]]

local TABLESTART = [[
<table style="text-align: left;" border="1" cellpadding="3" cellspacing="0">
<tbody>
]]

local TABLEEND = [[
</tbody>
</table>
<p>
]]

local CELLSTYLE = [[<td style="vertical-align: top;">]]
local CELLNUMBER = [[<td style="vertical-align: top; text-align: right;">]]

--[[--------------------------------------------------------------------
-- variables, initialization
------------------------------------------------------------------------]]

local string, io, table, math, error
  = string, io, table, math, error
local match, find, sub, concat
  = string.match, string.find, string.sub, table.concat

local arg = {...}       -- program arguments
local urllist           -- per-file numbered url list

--[[--------------------------------------------------------------------
-- utility functions
------------------------------------------------------------------------]]

------------------------------------------------------------------------
-- load/save source code
------------------------------------------------------------------------

local function load_file(fname)         -- loader
  local INF = io.open(fname, "rb")
  if not INF then error("cannot open \""..fname.."\" for reading") end
  local dat = INF:read("*a")
  if not dat then error("cannot read from \""..fname.."\"") end
  INF:close()
  return dat
end

local function save_file(fname, dat)    -- saver
  local OUTF = io.open(fname, "wb")
  if not OUTF then error("cannot open \""..fname.."\" for writing") end
  local status = OUTF:write(dat)
  if not status then error("cannot write to \""..fname.."\"") end
  OUTF:close()
end

------------------------------------------------------------------------
-- calculate indentation amount (space and tab only!)
------------------------------------------------------------------------

local function calc_indent(s)
  local col = 0
  for i = 1, #s do
    local c = sub(s, i, i)
    col = col + 1
    if c == "\t" then  -- tab
      while col % 8 > 0 do col = col + 1 end
    end
  end--for
  return math.floor(col / 8)
end

------------------------------------------------------------------------
-- some html helpers
------------------------------------------------------------------------

local function tag_begin(s) return "<"..s..">" end      -- for tags
local function tag_end(s) return "</"..s..">" end

local function do_entities(z)   -- escapes the usual xml entities
  local i = 1
  while i <= #z do
    local c = sub(z, i, i)
    local d = ENTITIES[c]
    if d then c = d; z = sub(z, 1, i - 1)..c..sub(z, i + 1) end
    i = i + #c
  end--while
  return z
end

------------------------------------------------------------------------
-- some matchers
------------------------------------------------------------------------

local function is_url(s)                -- a few select URLs
  local p, q = match(s, "^(%l+):(%S+)")
  if p and ((PROTOCOLS[p] and sub(q, 1, 2) == "//") or
            (p == "mailto" and match(q, "@"))) then
    return true
  end
end

local function is_indented(ln)          -- indented bullet or text
  if not ln then return end
  local s, bullet, txt = match(ln, "^(%s+)(%*)%s+(.*)$")
  if not s then
    s, txt = match(ln, "^(%s+)(%S.*)$")
    if not s or match(txt, "^{{{") then return end
    bullet = ""
  end
  local n = calc_indent(s)
  if n == 0 then return end
  return s, bullet, txt, n
end

--[[--------------------------------------------------------------------
-- highlighting lexer for Lua 5.1 sources (uses do_entities()!)
-- * adapted from llex.lua in LuaSrcDiet
------------------------------------------------------------------------]]

local function lua_lexer(z)
  ----------------------------------------------------------------------
  -- initialization
  ----------------------------------------------------------------------
  local I,                      -- lexer's position in source
        tok,                    -- lexed token list
        seminfo,                -- lexed semantic information list
        kw,                     -- keyword lookup init
        buff                    -- buffer for strings
    = 1, {}, {}, {}
  for v in string.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]], "%S+") do
    kw[v] = true
  end
  ----------------------------------------------------------------------
  -- add information to token listing
  ----------------------------------------------------------------------
  local function addtoken(token, info)
    local i = #tok + 1
    tok[i], seminfo[i] = token, info
  end
  ----------------------------------------------------------------------
  -- handles end-of-line characters
  ----------------------------------------------------------------------
  local function nextline(i, is_tok)
    local old = sub(z, i, i)
    i = i + 1  -- skip '\n' or '\r'
    local c = sub(z, i, i)
    if (c == "\n" or c == "\r") and (c ~= old) then
      i = i + 1  -- skip '\n\r' or '\r\n'
    end
    if is_tok then addtoken("TK_EOL", "\n") end
    I = i; return i
  end
  ----------------------------------------------------------------------
  -- count separators ("=") in a long string delimiter
  ----------------------------------------------------------------------
  local function skip_sep(i)
    local s = sub(z, i, i)
    i = i + 1
    local count = #match(z, "=*", i)  -- note, take the length
    i = i + count; I = i
    return (sub(z, i, i) == s) and count or (-count) - 1
  end
  ----------------------------------------------------------------------
  -- reads a long string or long comment
  ----------------------------------------------------------------------
  local function read_long_string(is_str, sep)
    local i = I + 1  -- skip 2nd '['
    local c = sub(z, i, i)
    if c == "\r" or c == "\n" then  -- string starts with a newline?
      i = nextline(i)  -- skip it
    end
    while true do
      local p, q, r = find(z, "([\r\n%]])", i) -- (long range)
      if not p then return end  -- error
      i = p
      if r == "]" then                  -- delimiter test
        if skip_sep(i) == sep then
          buff = sub(z, buff, I); I = I + 1  -- skip 2nd ']'
          return buff
        end
        i = I
      else                              -- newline
        buff = buff.."\n"; i = nextline(i)
      end
    end--while
  end
  ----------------------------------------------------------------------
  -- reads a string
  ----------------------------------------------------------------------
  local function read_string(del)
    local i = I
    local find = find
    local sub = sub
    while true do
      local p, q, r = find(z, "([\n\r\\\"\'])", i) -- (long range)
      if p then
        if r == "\n" or r == "\r" then return end  -- error
        i = p
        if r == "\\" then                       -- handle escapes
          i = i + 1; r = sub(z, i, i)
          if r == "" then break end -- (EOZ error)
          p = find("abfnrtv\n\r", r, 1, true)
          ------------------------------------------------------
          if p then                             -- special escapes
            i = (p > 7) and nextline(i) or (i + 1)
          ------------------------------------------------------
          elseif find(r, "%D") then             -- other non-digits
            i = i + 1
          ------------------------------------------------------
          else                                  -- \xxx sequence
            local p, q, s = find(z, "^(%d%d?%d?)", i)
            i = q + 1; if s + 1 > 256 then return end  -- error
          ------------------------------------------------------
          end--if p
        else
          i = i + 1
          if r == del then                      -- ending delimiter
            I = i; return sub(z, buff, i - 1)   -- return string
          end
        end--if r
      else
        return  -- error
      end--if p
    end--while
  end
  ----------------------------------------------------------------------
  -- initial processing (shbang handling)
  ----------------------------------------------------------------------
  local p, _, q, r = find(z, "^(#[^\r\n]*)(\r?\n?)")
  if p then                             -- skip first line
    I = I + #q; addtoken("TK_COMMENT", q)
    if #r > 0 then nextline(I, true) end
  end
  ----------------------------------------------------------------------
  -- main lexer loop
  ----------------------------------------------------------------------
  while I do--outer
    local i = I
    -- inner loop allows break to be used to nicely section tests
    while true do--inner
      ----------------------------------------------------------------
      local p, _, r = find(z, "^([_%a][_%w]*)", i)
      if p then
        I = i + #r              -- reserved word (keyword) or identifier
        addtoken(kw[r] and "TK_KEYWORD" or "TK_NAME", r)
        break -- (continue)
      end
      ----------------------------------------------------------------
      local p, _, r = find(z, "^(%.?)%d", i)
      if p then                                 -- numeral
        if r == "." then i = i + 1 end
        local _, q, r = find(z, "^%d*[%.%d]*([eE]?)", i)
        i = q + 1
        if #r == 1 then                         -- optional exp/sign
          if match(z, "^[%+%-]", i) then i = i + 1 end
        end
        local _, q = find(z, "^[_%w]*", i)
        I = q + 1
        local v = sub(z, p, q)                  -- string equivalent
        if not tonumber(v) then return z end  -- error
        addtoken("TK_NUMBER", v)
        break -- (continue)
      end
      ----------------------------------------------------------------
      local p, q, r, t = find(z, "^((%s)[ \t\v\f]*)", i)
      if p then
        if t == "\n" or t == "\r" then          -- newline
          nextline(i, true)
        else
          I = q + 1; addtoken("TK_SPACE", r)    -- whitespace
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local r = match(z, "^%p", i)
      if r then
        buff = i
        local p = find("-[\"\'.=<>~", r, 1, true)
        if p then
          -- two-level if block for punctuation/symbols
          --------------------------------------------------------
          if p <= 2 then
            if p == 1 then                      -- minus
              local c = match(z, "^%-%-(%[?)", i)
              if c then
                i = i + 2
                local sep = -1
                if c == "[" then sep = skip_sep(i) end
                if sep >= 0 then                -- long comment
                  local s = read_long_string(false, sep)
                  if not s then return z end  -- error
                  addtoken("TK_LCOMMENT", s)
                else                            -- short comment
                  I = find(z, "[\n\r]", i) or (#z + 1)
                  addtoken("TK_COMMENT", sub(z, buff, I - 1))
                end
                break -- (continue)
              end
              -- (fall through for "-")
            else                                -- [ or long string
              local sep = skip_sep(i)
              if sep >= 0 then
                local s = read_long_string(true, sep)
                if not s then return z end  -- error
                addtoken("TK_LSTRING", s)
              elseif sep == -1 then
                addtoken("TK_OP", "[")
              else
                return z  -- error
              end
              break -- (continue)
            end
          --------------------------------------------------------
          elseif p <= 5 then
            if p < 5 then                       -- strings
              I = i + 1
              local s = read_string(r)
              if not s then return z end  -- error
              addtoken("TK_STRING", s)
              break -- (continue)
            end
            r = match(z, "^%.%.?%.?", i)        -- .|..|... dots
            -- (fall through)
          --------------------------------------------------------
          else                                  -- relational
            r = match(z, "^%p=?", i)
            -- (fall through)
          end
        end
        I = i + #r
        addtoken("TK_OP", r)  -- for other symbols, fall through
        break -- (continue)
      end
      ----------------------------------------------------------------
      local r = sub(z, i, i)
      if r ~= "" then
        I = i + 1; addtoken("TK_OP", r)  -- other single-char tokens
        break
      end
      addtoken("TK_EOS", "")                    -- end of stream,
      I = nil; break                            -- exit here
      ----------------------------------------------------------------
    end--while inner
  end--while outer
  ----------------------------------------------------------------------
  -- mark up tokens with suitable styling
  ----------------------------------------------------------------------
  local html = {}                       -- html helpers
  local function add(s) html[#html + 1] = s end
  local function span(class, s)
    add('<span class="'..class..'">'..s..'</span>')
  end
  ----------------------------------------------------------------------
  for i = 1, #tok do                    -- enumerate token list
    local t, info = tok[i], seminfo[i]
    if t == "TK_KEYWORD" then
      span("keyword", info)
    elseif t == "TK_STRING" or t == "TK_LSTRING" then
      span("string", do_entities(info))
    elseif t == "TK_COMMENT" or t == "TK_LCOMMENT" then
      span("comment", do_entities(info))
    elseif t == "TK_NUMBER" then
      span("number", info)
    elseif t == "TK_OP" then
      add(do_entities(info))
    elseif t ~= "TK_EOS" then  -- others
      add(info)
    end
  end--for
  ----------------------------------------------------------------------
  return concat(html)
end

--[[--------------------------------------------------------------------
-- highlighting lexer for C/C++ sources (uses do_entities()!)
-- * written from scratch based on a text specification of Scintilla's
--   C/C++ lexer behaviour (a basic C/C++ subset only)
------------------------------------------------------------------------]]

local function c_lexer(z)
  ----------------------------------------------------------------------
  -- initialization
  ----------------------------------------------------------------------
  local tok,                    -- lexed token list
        seminfo,                -- lexed semantic information list
        kw,                     -- keyword lookup init
        nz                      -- size of source
    = {}, {}, {}, #z
  for v in string.gmatch([[
and and_eq asm auto bitand bitor bool break case catch char class compl
const const_cast continue default delete do double dynamic_cast else
enum explicit export extern false float for friend goto if inline int
long mutable namespace new not not_eq operator or or_eq private
protected public register reinterpret_cast return short signed sizeof
static static_cast struct switch template this throw true try typedef
typeid typename union unsigned using virtual void volatile wchar_t
while xor xor_eq]], "%S+") do
    kw[v] = true
  end
  ----------------------------------------------------------------------
  -- scan for line endings; main loop initialization
  ----------------------------------------------------------------------
  local lineStart, lineEnd = {}, {}
  local i = 1
  while true do  -- mark line beginnings and endings
    lineStart[i] = true
    i = find(z, "[\r\n]", i)
    if not i then break end
    local c = sub(z, i, i)
    i = i + 1
    local d = sub(z, i, i)
    if match(d, "[\r\n]") and c ~= d then i = i + 1 end
    lineEnd[i - 1] = true
  end
  lineEnd[nz] = true
  local i, I, state = 1, 1, "DEFAULT"
  ----------------------------------------------------------------------
  -- switch state, save older segment as a lexed element
  ----------------------------------------------------------------------
  local function setState(state_)
    if I == i then
      if state_ then state = state_ end
      return
    end
    if not state_ then state_ = "DEFAULT" end
    local j = #tok
    local sem = sub(z, I, i - 1)
    if j == 0 then tok[1], seminfo[1] = state, sem
    elseif tok[j] == state then seminfo[j] = seminfo[j]..sem
    else j = j + 1; tok[j], seminfo[j] = state, sem
    end
    I, state = i, state_
  end
  -- additional helper functions
  local function changeState(state_) state = state_ end
  local function getCurrent() return sub(z, I, i - 1) end
  ----------------------------------------------------------------------
  -- main lexer loop
  ----------------------------------------------------------------------
  local visibleChars, contLine
  while i <= nz do--outer
    while true do--inner
      --------------------------------------------------------------
      if lineStart[i] then  -- line start required processing
        visibleChars = false
        if state == "STRING" then setState("STRING") end
      end
      --------------------------------------------------------------
      local c = sub(z, i, i)
      if c == "\\" then  -- handle line continuations
        local d = sub(z, i + 1, i + 1)
        if match(d, "[\r\n]") then
          i = i + 1
          if not lineEnd[i] then i = i + 1 end
          contLine = true
          break
        end
      end
      --------------------------------------------------------------
      if state ~= "DEFAULT" then  -- non-default class being lexed
        if state == "OP" then  -- operators
          setState()
        elseif state == "NUMBER" then  -- numbers
          if not match(c, "[%w%._]") then setState() end
        elseif state == "IDENT" then
          if not match(c, "[%w_]") then  -- identifiers, keywords
            if kw[getCurrent()] then changeState("WORD") end
            setState()
          end
        elseif state == "CPP" then  -- preprocessor
          if (lineStart[i] and not contLine) or
             match(c, "%s") or
             match(z, "^/[/%*]", i) then
            setState()
          end
        elseif state == "COMMENT" then  -- block comments
          if sub(z, i, i + 1) == "*/" then i = i + 2; setState() end
        elseif state == "COMMENTL" then  -- line comments
          if lineStart[i] then setState() end
        elseif state == "STRING" then  -- strings
          if lineEnd[i] then changeState("STRINGEOL")
          elseif match(z, "^\\[\"'\\]", i) then i = i + 1
          elseif c == '"' then i = i + 1; setState()
          end
        elseif state == "CHAR" then  -- characters
          if lineEnd[i] then changeState("STRINGEOL")
          elseif match(z, "^\\[\"'\\]", i) then i = i + 1
          elseif c == "'" then i = i + 1; setState()
          end
        elseif state == "STRINGEOL" then  -- undelimited string/char
          if lineStart[i] then setState() end
        end
      end
      --------------------------------------------------------------
      if state == "DEFAULT" then  -- check for next non-default class
        local c, d = sub(z, i, i), sub(z, i, i + 1)
        if match(c, "%d") or match(d, "%.%d") then setState("NUMBER")
        elseif match(c, "[%a_]") then setState("IDENT")
        elseif d == "/*" then setState("COMMENT"); i = i + 1
        elseif d == "//" then setState("COMMENTL")
        elseif c == "\"" then setState("STRING")
        elseif c == "'" then setState("CHAR")
        elseif c == "#" and not visibleChars then
          setState("CPP")
          repeat i = i + 1 until not match(z, "^[ \t]", i)
          if lineEnd[i] then setState() end
        elseif match(c, "[%%%^&%*%(%)%-%+=|{}%[%]:;<>,/%?!%.~]") then setState("OP")
        end
      end
      --------------------------------------------------------------
      c = sub(z, i, i)
      if not (match(c, "%s") or state == "DEFAULT" or
         state == "COMMENT" or state == "COMMENTL") then
        visibleChars = true
      end
      contLine = false
      break
    end--while inner
    i = i + 1
  end--while outer
  setState()
  ----------------------------------------------------------------------
  -- mark up tokens with suitable styling
  ----------------------------------------------------------------------
  local html = {}                       -- html helpers
  local function add(s) html[#html + 1] = s end
  local function span(class, s)
    add('<span class="'..class..'">'..s..'</span>')
  end
  ----------------------------------------------------------------------
  for i = 1, #tok do                    -- enumerate token list
    local t, info = tok[i], seminfo[i]
    if t == "NUMBER" then
      span("c_number", info)
    elseif t == "WORD" then
      span("c_keyword", info)
    elseif t == "COMMENT" or t == "COMMENTL" then
      span("c_comment", do_entities(info))
    elseif t == "STRING" or t == "STRINGEOL" or t == "CHAR" then
      span("c_string", do_entities(info))
    elseif t == "CPP" then
      span("c_cpp", do_entities(info))
    elseif t == "OP" then
      add(do_entities(info))
    else  -- others
      add(info)
    end
  end
  ----------------------------------------------------------------------
  return concat(html)
  ----------------------------------------------------------------------
end

--[[--------------------------------------------------------------------
-- main program -> process() -> do_delim() -> do_text()
------------------------------------------------------------------------]]

------------------------------------------------------------------------
-- process text or words
------------------------------------------------------------------------

local function do_text(s)
  local part = {}
  --------------------------------------------------------------------
  local function add(s)                 -- save a processed segment
    part[#part + 1] = s
  end
  --------------------------------------------------------------------
  -- split into words and try to match patterns
  --------------------------------------------------------------------
  local i, ns = 1, #s
  while i <= ns do
    local word, space = match(s, "^(%S*)(%s*)", i)
    i = i + #word + #space
    if word ~= "" then
    ----------------------------------------------------------------
      -- match for URLs (this is a limited matcher)
      if is_url(word) then
        add('<a href="'..word..'">'..do_entities(word)..'</a>')
      else
        add(do_entities(word))
      end
    end--if word
    if space ~= "" then
    ----------------------------------------------------------------
      -- doesn't really optimize spaces, just deals with paragraphs
      local p = find(space, "\n\n")
      if p then                         -- add <p>
        space = sub(space, 1, p - 1).."\n<p>\n"..sub(space, p + 2)
        repeat                          -- skip other empty lines
          local p = find(space, "\n\n")
          if p then
            space = sub(space, 1, p - 1)..sub(space, p + 1)
          end
        until not p
      end
      add(space)
    end--if space
  end
  return concat(part)
end

------------------------------------------------------------------------
-- process delimited blocks: ''...'', '''...''', {{...}} and [...]
------------------------------------------------------------------------

local function do_delim(s, srcstack)
  local part = {}
  --------------------------------------------------------------------
  local function add(s)                 -- save a processed segment
    part[#part + 1] = s
  end
  --------------------------------------------------------------------
  -- style stack handling
  --------------------------------------------------------------------
  local stack = srcstack
  if not stack then stack = {} end
  --------------------------------------------------------------------
  local function delim_end()            -- returns expected end delimiter
    local i = #stack
    if i == 0 then return "" end
    return DELIM[stack[i]]
  end
  local function pops()                 -- pop style stack
    stack[#stack] = nil
  end
  local function pushs(delim)           -- push style stack
    stack[#stack + 1] = delim
  end
  --------------------------------------------------------------------
  -- scans for delimiters, break up text into segments
  --------------------------------------------------------------------
  local i, ns = 1, #s
  while i <= ns do
    local p, _, q = find(s, "([{}'%[])", i)
    if not p then p = ns + 1 end
    ------------------------------------------------------------------
    local words = sub(s, i, p - 1)      -- text handling
    if words ~= "" then
      add(do_text(words))
    end
    i = p
    ------------------------------------------------------------------
    if q == "'" then                    -- ''' (bold) or '' (italics)
      local p = match(s, "^'''?", i)
      if not p then                     -- single '
        add(do_text(q)); i = i + 1
      else
        local dend = delim_end()
        if dend == "''" and p == "'''" then  -- fix priority
          p = dend
        end
        i = i + #p
        local tag = (p == "'''") and "strong" or "em"
        if p == delim_end() then
          pops(); tag = tag_end(tag)
        else
          pushs(p); tag = tag_begin(tag)
        end
        add(tag)
      end
    ------------------------------------------------------------------
    elseif q == "{" or q == "}" then    -- {{ (monospace)
      local p = match(s, "^(([{}])%2)", i)
      if not p then                     -- single { or }
        add(do_text(q)); i = i + 1
      else
        i = i + 2
        local tag = "code"
        if p == delim_end() then        -- ending }}
          pops(); tag = tag_end(tag)
        else-- p == "{{"                -- starting {{
          pushs(p); tag = tag_begin(tag)
        end
        add(tag)
      end
    ------------------------------------------------------------------
    elseif q == "[" then                -- [ (url specification)
      i = i + 1
      local p = find(s, "%]", i)
      if not p then                     -- no ending ]
        add(do_text(q))
      else--p
        local seg = sub(s, i, p - 1)    -- candidate segment
        local url, txt = match(seg, "^(%S+)%s*(.*)$")
        if not url or not is_url(url) then
          local ccase = match(seg, "^%u[%l%d]+%u[%l%d]+%w*$")
          if ccase then  -- check UpperCamelCase
            add('<a href="'..ccase..HTML_EXT..'">'..ccase..'</a>')
            i = i + #ccase + 1
          else
            add(do_text(q))  -- other words (normal text)
          end
        else--url
          i = p + 1
          if txt == "" then
            local n = #urllist + 1
            urllist[n] = url
            txt = do_entities("["..n.."]")
          else
            txt = do_delim(txt)  -- recursive!
          end
          add('<a href="'..url..'">'..txt..'</a>')
        end--if url
      end--if p
    ------------------------------------------------------------------
    end
  end--while
  if not srcstack and #stack > 0 then   -- delimiter balancing error
    return s
  end
  return concat(part)
end

------------------------------------------------------------------------
-- main processing function
------------------------------------------------------------------------

local function process(srcfl, destfl)
  --------------------------------------------------------------------
  -- load and split into lines (the hard way)
  --------------------------------------------------------------------
  local dat = load_file(srcfl)
  local lines = {}
  local i, ndat = 1, #dat
  while i <= ndat do                    -- split with CRLF/LFCR detect
    local p, _, q, r = find(dat, "([\r\n])([\r\n]?)", i)
    if not p then p = ndat + 1 end
    lines[#lines + 1] = sub(dat, i, p - 1).."\n"
    if #r > 0 and q ~= r then
      p = p + 1
    end
    i = p + 1
  end
  --------------------------------------------------------------------
  -- initialization
  --------------------------------------------------------------------
  urllist = {}                          -- numbered urls
  local i, nlines = 1, #lines
  local buff,                           -- pending txt for do_delim()
        stack,                          -- main style stack
        part = {}, {}, {}               -- output segments
  --------------------------------------------------------------------
  local function add(s)                 -- save a processed segment
    part[#part + 1] = s
  end
  --------------------------------------------------------------------
  local title = match(destfl, "([^%\\%/]+)%.[^%.]+$")
  add(string.format(HEADER,             -- header and leading stuff
    do_entities(title),
    STYLESHEET))
  add("<h1>"..do_entities(title).."</h1>\n")
  --------------------------------------------------------------------
  local function flush_buff()           -- flush segment buffer
    if #buff > 0 then
      add(do_delim(concat(buff), stack))
    end
    buff = {}
  end
  --------------------------------------------------------------------
  local istack                          -- tracks indented text/bullets
  local function pushi(bullet)          -- enter an indent level
    local tag1, tag2 = "<ul>\n", "</ul>\n"
    if bullet == "" then
      tag1, tag2 = "<dl>\n", "</dl>\n"
    end
    add(tag1)
    istack[#istack + 1] = tag2
  end
  local function popi()                 -- exit an indent level
    add(istack[#istack])
    istack[#istack] = nil
  end
  --------------------------------------------------------------------
  local function is_tablerow(s)         -- match a table row
    local tbl = match(s, "^%s*||(.+)||%s*$")
    if tbl then
      local col = {}
      while true do                     -- split into columns
        local p, q = find(tbl, "||")
        if not p then
          col[#col + 1] = tbl
          break
        end
        col[#col + 1] = sub(tbl, 1, p - 1)
        tbl = sub(tbl, q + 1)
      end
      return col
    end
  end
  --------------------------------------------------------------------
  -- match and handle line-based wiki elements
  --------------------------------------------------------------------
  while i <= nlines do
    local ln = lines[i]
    while true do
      ----------------------------------------------------------------
      if match(ln, "^%s*%-%-%-%-+%s*$") then    -- separator line
        flush_buff()
        add("<hr>")
        i = i + 1; break -- (continue)
      end
      ----------------------------------------------------------------
      local s, t = match(ln, "^(===?)%s*(.-)%s*%1%s*$")  -- headings
      if s then
        flush_buff()
        s = "h"..(5-#s)
        add(tag_begin(s)..do_delim(t)..tag_end(s).."\n")
        i = i + 1
        break -- (continue)
      end
      ----------------------------------------------------------------
      local s, bullet, txt, n           -- bullet points (must before {{{)
        = is_indented(ln)
      if s then
        flush_buff()
        istack = {}
        for j = 1, n do pushi(bullet) end
        local prev, pbullet = n, bullet
        while s and n > 0 do            -- compile adjacent elements too
          if n > prev then
            for j = 1, n - prev do pushi(bullet) end
          elseif n < prev then
            for j = 1, prev - n do popi() end
          elseif bullet ~= pbullet then
            popi(); pushi(bullet)
          end
          add(((bullet == "*") and "<li>" or "<dt><dd>")..do_delim(txt))
          prev, pbullet = n, bullet
          i = i + 1
          ln = lines[i]
          s, bullet, txt, n = is_indented(ln)
        end--while
        for j = 1, prev do popi() end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local s = find(ln, "{{{")                 -- indented blocks
      if s then
        local t = sub(ln, 1, s - 1)
        local indent = 0
        if match(t, "^%s+$") then       -- indent detection
          indent = calc_indent(t)
        else
          buff[#buff + 1] = t
        end
        ln = sub(ln, s + 3)
        local tag = "<pre>"
        local lang = match(ln, "^!(%w*)%s*$")
        if lang == "Lua" or lang == "C" then  -- !Lua option control
          ln = ""
          tag = '<pre class="code">'
        end
        flush_buff()                    -- flush all text before {{{
        local old_i = i
        local pre = {}
        while true do                   -- scan for ending }}} delimiter
          local s = find(ln, "}}}")
          if s then                     -- process ending
            local t = sub(ln, 1, s - 1)
            pre[#pre + 1] = t
            ln = sub(ln, s + 3)
            lines[i] = ln
            break
          end
          pre[#pre + 1] = ln
          i = i + 1
          if i > nlines then            -- revert if no ending found
            i = old_i
            buff[#buff + 1] = "{{{"
            pre = nil
            break -- (continue)
          end
          ln = lines[i]
        end--while
        if pre then                     -- dump preformatted stuff plus
          istack = {}                   -- optional indentation control
          if indent > 0 then
            for j = 1, indent do pushi("") end
            add("<dt><dd>")
          end
          pre = concat(pre)
          local lexed                   -- do the highlighting
          if lang == "Lua" then lexed = lua_lexer(pre)
          elseif lang == "C" then lexed = c_lexer(pre)
          end
          add(tag..(lexed or do_entities(pre)).."</pre>")
          if indent > 0 then
            for j = 1, indent do popi() end
          end
        end
        break -- (continue)
      end
      ----------------------------------------------------------------
      local col = is_tablerow(ln)               -- table pattern
      if col then
        flush_buff()
        local cols = #col               -- fixed column count
        add(TABLESTART)
        while true do                   -- build up table columns
          local r = { "<tr>\n" }
          for j = 1, cols do
            local cell = col[j]
            -- force align right for simple numbers
            if match(cell, "^%s*%d*%.?%d+%s*") then
              r[#r + 1] = CELLNUMBER
            else
              r[#r + 1] = CELLSTYLE
            end
            r[#r + 1] = do_delim(cell)
            r[#r + 1] = "<br></td>\n"
          end
          r[#r + 1] = "</tr>\n"
          add(concat(r))
          i = i + 1
          col = is_tablerow(lines[i] or "")
          if not col or #col ~= cols then break end
        end
        add(TABLEEND)
        break -- (continue)
      end
      ----------------------------------------------------------------
      buff[#buff + 1] = ln              -- keep until flush needed
      i = i + 1; break
    end--while inner
  end--while outer
  flush_buff()                          -- flush all remaining text
  --------------------------------------------------------------------
  -- footer and save the final result
  --------------------------------------------------------------------
  add(FOOTER)
  save_file(destfl, concat(part))
end

------------------------------------------------------------------------
-- program entry point
------------------------------------------------------------------------

if #arg == 0 then
  print(MSG_TITLE)
else
  for i = 1, #arg do
    --------------------------------------------------------------------
    local srcfl, destfl = arg[i]        -- handle file extension
    local extb, exte = find(srcfl, "%.[^%.%\\%/]*$")
    local basename, extension = srcfl, ""
    if extb and extb > 1 then
      basename = sub(srcfl, 1, extb - 1)
      extension = sub(srcfl, extb, exte)
    end
    destfl = basename..HTML_EXT
    --------------------------------------------------------------------
    process(srcfl, destfl)              -- process a file
  end
end

-- end of script
