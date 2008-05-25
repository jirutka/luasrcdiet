#!/usr/bin/env lua
--[[-------------------------------------------------------------------

  LuaSrcDiet
  Compresses Lua source code by removing unnecessary characters.

  Copyright (c) 2005 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions under which this
  software may be distributed (basically a Lua 5-style license.)

  http://luaforge.net/projects/luasrcdiet/
  (TODO) http://www.geocities.com/keinhong/luasrcdiet.html
  See the ChangeLog for more information.

-----------------------------------------------------------------------
-- * See the README file and script comments for notes and caveats.
-----------------------------------------------------------------------
--]]

--[[-------------------------------------------------------------------
-- description and help texts
--]]-------------------------------------------------------------------

title = [[
LuaSrcDiet: Puts your Lua 5 source code on a diet
Version 0.9.1 (20050816)  Copyright (c) 2005 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed (basically a Lua 5-style license.)
]]

USAGE = [[
usage: %s [options] [filenames]

options:
  -h, --help        prints usage information
  -o <file>         specify file name to write output
  --quiet           do not display statistics
  --read-only       read file and print token stats
  --keep-lines      preserve line numbering
  --maximum         maximize reduction of source
  --dump            dump raw tokens from lexer
  --                stop handling arguments

example:
  >%s myscript.lua -o myscript_.lua
]]

-- for embedding, we won't set arg[0]
local usage, exec
if arg[0] then exec = "lua LuaSrcDiet.lua" else exec = "LuaSrcDiet" end
usage = string.format(USAGE, exec, exec)

-- user options
config = {}
config.SUFFIX = "_"

--[[-------------------------------------------------------------------
-- llex is a port of the Lua 5.0.2 lexer (llex.*) to Lua, with the
-- token output modified and the code simplified for LuaSrcDiet.
-----------------------------------------------------------------------
-- Instead of returning a number, llex:lex() returns strings, like
-- "TK_EOS". The other values returned are the original snippet of
-- source and the "value" of the lexed token, if applicable.
-----------------------------------------------------------------------
-- * Prep lexer with llex:setinput(), llex will close the file handle.
-- * For LuaSrcDiet, llex has been changed:
--   TK_* returns classes of tokens, made less specific
--   "TK_OP" -> operators and punctuations, "TK_KEYWORD" -> keywords
--   "TK_EOL" -> end-of-lines, "TK_SPACE" -> whitespace
--   "TK_COMMENT" -> comments, "TK_LCOMMENT" -> block comments
-----------------------------------------------------------------------
--]]

llex = {}

-----------------------------------------------------------------------
-- llex initialization stuff
-----------------------------------------------------------------------

llex.EOZ = -1                           -- end of stream marker
llex.keywords =                         -- Lua 5 keywords
"and break do else elseif end false for function if in local \
nil not or repeat return then true until while "

llex.str2tok = {}                       -- for matching keywords
for v in string.gfind(llex.keywords, "[^%s]+") do
  llex.str2tok[v] = true
end

--[[-------------------------------------------------------------------
-- Support functions for Lua lexer (mainly error handling)
-- * REMOVED functions luaX_errorline, luaX_errorline, luaX_token2str,
--   luaX_syntaxerror, either unused or simplified.
-----------------------------------------------------------------------
--]]

function llex:checklimit(val, limit, msg)
  if val > limit then
    msg = string.format("too many %s (limit=%d)", msg, limit)
    -- luaX_syntaxerror merged here; removed token reference
    error(string.format("%s:%d: %s", self.source, self.line, msg))
  end
end

function llex:error(s, token)
  -- luaX_errorline merged here
  error(string.format("%s:%d: %s near '%s'", self.source, self.line, s, token))
end

function llex:lexerror(s, token)
  if token then self:error(s, token) else self:error(s, self.buff) end
end

--[[-------------------------------------------------------------------
-- Principal input, output stream functions: nextc, save
-- * self.c and self.ch are identical, self.ch is the string version
-- * lexer has a token buffer, buff, intended for the lexed value, and
--   another buffer, obuff, for the original characters -- it's not a
--   very efficient method, but we want both, just in case
-----------------------------------------------------------------------
--]]

-----------------------------------------------------------------------
-- returns the next character as a number
-----------------------------------------------------------------------
function llex:nextc()
  if self.ipos > self.ilen then
    if self.z then                      -- read from specified stream
      self.ibuf = self.z:read("*l")
      if self.ibuf == nil then          -- close stream
        self.z:close()
        self.c = self.EOZ; self.ch = ""
        self.z = nil
        return
      else                              -- preprocess source line
        self.ibuf = self.ibuf.."\n"
        self.ipos = 1
        self.ilen = string.len(self.ibuf)
        -- then grabs the first char (below)
      end
    else                                -- end of string chunk
      self.c = self.EOZ; self.ch = ""
      return
    end
  end
  self.c = string.byte(self.ibuf, self.ipos)    -- return a character
  self.ch = string.char(self.c)
  self.ipos = self.ipos + 1
end

-----------------------------------------------------------------------
-- ADDED initialize token buffers
-----------------------------------------------------------------------
function llex:initbuff()
  self.buff = ""
  self.obuff = ""
end

-----------------------------------------------------------------------
-- saves given character into buffer, c must be a string
-----------------------------------------------------------------------
function llex:save(c)
  self.buff = self.buff..c
end

-----------------------------------------------------------------------
-- ADDED saves original character into buffer
-----------------------------------------------------------------------
function llex:osave(c)
  self.obuff = self.obuff..c
end

-----------------------------------------------------------------------
-- save current character and grabs next character
-----------------------------------------------------------------------
function llex:save_and_next()
  self:save(self.ch)
  self:osave(self.ch)
  self:nextc()
end

-----------------------------------------------------------------------
-- move on to next line, updating line number count
-----------------------------------------------------------------------
function llex:inclinenumber()
  self:nextc()   -- skip EOL
  self.line = self.line + 1
  -- number of lines is limited to MAXINT
  self:checklimit(self.line, 2147483645, "lines in a chunk")
end

--[[-------------------------------------------------------------------
-- Initialize lexer to a particular stream (handle) or string
-----------------------------------------------------------------------
--]]

-----------------------------------------------------------------------
-- input stream initialization (file handle)
-----------------------------------------------------------------------
function llex:setinput(z, source)
  if z then
    self.ilen = 0               -- length
    self.z = z                  -- input stream
  end
  self.ipos = 1                 -- position
  self.line = 1
  self.lastline = 1
  self.source = source
  if not self.source then       -- default source name
    self.source = "main"
  end
  self:nextc()                  -- read first char
  -- shbang handling moved to llex()
end

-----------------------------------------------------------------------
-- input stream initialization (string)
-----------------------------------------------------------------------
function llex:setstring(chunk, source)
  self.ibuf = chunk
  self.ilen = string.len(self.ibuf) -- length
  self:setinput(nil, source)
end

--[[-------------------------------------------------------------------
-- Main Lua lexer functions
-----------------------------------------------------------------------
--]]

-----------------------------------------------------------------------
-- grab a class of characters
-----------------------------------------------------------------------
function llex:readloop(pat)
  while string.find(self.ch, pat) do
    self:save_and_next()
  end
end

-----------------------------------------------------------------------
-- grab characters until end-of-line
-----------------------------------------------------------------------
function llex:readtoeol()
  while self.ch ~= '\n' and self.c ~= self.EOZ do
    self:save_and_next()
  end
end

-----------------------------------------------------------------------
-- read a number
-----------------------------------------------------------------------
function llex:read_numeral(comma)
  self:initbuff()
  if comma then
    self.buff = '.'; self.obuff = '.'
  end
  self:readloop("%d")
  if self.ch == '.' then
    self:save_and_next()
    if self.ch == '.' then
      self:save_and_next()
      self:lexerror("ambiguous syntax (decimal point x string concatenation)")
    end
  end
  self:readloop("%d")
  if self.ch == 'e' or self.ch == 'E' then
    self:save_and_next()  -- read 'E'
    if self.ch == '+' or self.ch == '-' then
      self:save_and_next()  -- optional exponent sign
    end
    self:readloop("%d")
  end
  local value = tonumber(self.buff)
  if not value then
    self:lexerror("malformed number")
  end
  return self.obuff, value
end

-----------------------------------------------------------------------
-- read a long string or long comment
-----------------------------------------------------------------------
function llex:read_long_string(comment)
  local cont = 0                -- nesting
  local eols = 0
  if comment then
    self.buff = "--["
  else
    self.buff = "["             -- save first '['
  end
  self.obuff = self.buff
  self:save_and_next()          -- pass the second '['
  if self.ch == '\n' then       -- string starts with a newline?
    eols = eols + 1
    self:osave('\n')
    self:inclinenumber()        -- skip it
  end
  while true do
    -- case -----------------------------------------------------------
    if self.c == self.EOZ then  -- EOZ
      if comment then
        self:lexerror("unfinished long comment", "<eof>")
      else
        self:lexerror("unfinished long string", "<eof>")
      end
    -- case -----------------------------------------------------------
    elseif self.ch == '[' then
      self:save_and_next()
      if self.ch == '[' then
        cont = cont + 1
        self:save_and_next()
      end
    -- case -----------------------------------------------------------
    elseif self.ch == ']' then
      self:save_and_next()
      if self.ch == ']' then
        if cont == 0 then break end
        cont = cont - 1
        self:save_and_next()
      end
    -- case -----------------------------------------------------------
    elseif self.ch == '\n' then
      self:save('\n')
      eols = eols + 1
      self:osave('\n')
      self:inclinenumber()
    -- case -----------------------------------------------------------
    else
      self:save_and_next()
    -- endcase --------------------------------------------------------
    end
  end--while
  self:save_and_next()          -- skip the second ']'
  if comment then
    return self.obuff, eols
  end
  return self.obuff, string.sub(self.buff, 3, -3)
end

-----------------------------------------------------------------------
-- read a string
-----------------------------------------------------------------------
function llex:read_string(del)
  self:initbuff()
  self:save_and_next()
  while self.ch ~= del do
    -- case -----------------------------------------------------------
    if self.c == self.EOZ then
      self:lexerror("unfinished string", "<eof>")
    -- case -----------------------------------------------------------
    elseif self.ch == '\n' then
      self:lexerror("unfinished string")
    -- case -----------------------------------------------------------
    elseif self.ch == '\\' then
      self:osave('\\')
      self:nextc() -- do not save the '\'
      if self.c ~= self.EOZ then -- will raise an error next loop
        local i = string.find("\nabfnrtv", self.ch, 1, 1)
        if i then
          -- standard escapes
          self:save(string.sub("\n\a\b\f\n\r\t\v", i, i))
          self:osave(self.ch)
          if i == 1 then
            self:inclinenumber()
          else
            self:nextc()
          end
        elseif string.find(self.ch, "%d") == nil then
          -- escaped punctuation
          self:save_and_next()  -- handles \\, \", \', and \?
        else
          -- \xxx sequence
          local c = 0
          i = 0
          repeat
            c = 10 * c + self.ch -- (coerced)
            self:osave(self.ch)
            self:nextc()
            i = i + 1
          until (i >= 3 or not string.find(self.ch, "%d"))
          if c > 255 then -- UCHAR_MAX
            self:lexerror("escape sequence too large")
          end
          self:save(string.char(c))
        end
      end
    -- case -----------------------------------------------------------
    else
      self:save_and_next()
    -- endcase --------------------------------------------------------
    end
  end -- endwhile
  self:save_and_next()  -- skip delimiter
  return self.obuff, string.sub(self.buff, 2, -2)
end

--[[-------------------------------------------------------------------
-- Lexer feeder function for parser
-- * As we are not actually parsing the token stream, we return a token
--   class, the original snippet, and the token's value (for strings and
--   numbers.) Most token just passes through LuaSrcDiet processing...
-----------------------------------------------------------------------
--]]

-----------------------------------------------------------------------
-- lex function enhanced to return the snippets required for processing
-- * basically adds: TK_COMMENT, TK_LCOMMENT, TK_EOL, TK_SPACE
-----------------------------------------------------------------------
function llex:lex()
  local strfind = string.find
  while true do
    local c = self.c
    -- case -----------------------------------------------------------
    if self.line == 1 and self.ipos == 2                -- shbang handling
       and self.ch == '#' then                          -- skip first line
      self:initbuff()
      self:readtoeol()
      return "TK_COMMENT", self.obuff
    end
    -- case -----------------------------------------------------------
    if self.ch == '\n' then                             -- end of line
      self:inclinenumber()
      return "TK_EOL", '\n'
    -- case -----------------------------------------------------------
    elseif self.ch == '-' then                          -- comment
      self:nextc()
      if self.ch ~= '-' then                            -- '-' operator
        return "TK_OP", '-'
      end
      -- else is a comment '--' or '--[['
      self:nextc()
      if self.ch == '[' then
        self:nextc()
        if self.ch == '[' then                          -- block comment
          return "TK_LCOMMENT", self:read_long_string(1) -- long comment
        else                                            -- short comment
          self.buff = ""
          self.obuff = "--["
          self:readtoeol()
          return "TK_COMMENT", self.obuff
        end
      else                                              -- short comment
        self.buff = ""
        self.obuff = "--"
        self:readtoeol()
        return "TK_COMMENT", self.obuff
      end
    -- case -----------------------------------------------------------
    elseif self.ch == '[' then                          -- literal string
      self:nextc()
      if self.ch ~= '[' then
        return "TK_OP", '['
      else
        return "TK_STRING", self:read_long_string()
      end
    -- case -----------------------------------------------------------
    elseif self.ch == "\"" or self.ch == "\'" then       -- strings
      return "TK_STRING", self:read_string(self.ch)
    -- case -----------------------------------------------------------
    elseif self.ch == '.' then                          -- dot, concat,
      self:nextc()                                      -- or number
      if self.ch == '.' then
        self:nextc()
        if self.ch == '.' then
          self:nextc()
          return "TK_OP", '...'
        else
          return "TK_OP", '..'
        end
      elseif strfind(self.ch, "%d") == nil then
        return "TK_OP", '.'
      else
        return "TK_NUMBER", self:read_numeral(1)
      end
    -- case -----------------------------------------------------------
    elseif self.c == self.EOZ then                      -- end of input
      return "TK_EOS", ''
    -- case -----------------------------------------------------------
    else
      local op = strfind("=><~", self.ch, 1, 1)         -- relational ops
      local c = self.ch
      if op then
        self:nextc()
        if self.ch ~= '=' then                          -- single-char ops
          return "TK_OP", c
        else                                            -- double-char ops
          self:nextc()
          return "TK_OP", c..'='
        end
      else
        if strfind(self.ch, "%s") then                  -- whitespace
          self:initbuff()
          self:readloop("%s")
          return "TK_SPACE", self.obuff
        elseif strfind(self.ch, "%d") then              -- number
          return "TK_NUMBER", self:read_numeral()
        elseif strfind(self.ch, "[%a_]") then           -- identifier
          -- identifier or reserved word
          self:initbuff()
          self:readloop("[%w_]")
          if self.str2tok[self.buff] then               -- reserved word
            return "TK_KEYWORD", self.buff
          end
          return "TK_NAME", self.buff
        else                                            -- control/symbol
          if strfind(self.ch, "%c") then
            self:error("invalid control char", string.format("char(%d)", self.c))
          end
          self:nextc()
          return "TK_OP", c                             -- single-chars
        end
      end
    -- endcase --------------------------------------------------------
    end--if self.ch
  end--while
end

-----------------------------------------------------------------------
-- 'original' lex function, behaves *exactly* like original llex.c
-- * currently unused by LuaSrcDiet
-----------------------------------------------------------------------
function llex:olex()
  local _ltok, _lorig, _lval
  while true do
    _ltok, _lorig, _lval = self:lex()
    if _ltok ~= "TK_COMMENT" and _ltok ~= "TK_LCOMMENT"
       and _ltok ~= "TK_EOL" and _ltok ~= "TK_SPACE" then
      return _ltok, _lorig, _lval
    end
  end
end

--[[-------------------------------------------------------------------
-- Major functions
-- * We aren't using lval[] for now, except for TK_LCOMMENT processing,
--   perhaps for heavy-duty optimization, like constant optimization...
-----------------------------------------------------------------------
--]]

stats_c = nil   -- number of tokens of a given type
stats_l = nil   -- bytes occupied by tokens of a given type
ltok = nil      -- source list of tokens
lorig = nil     -- source list of original snippets
lval = nil      -- source list of actual token values
ntokens = 0     -- number of tokens processed from file

-----------------------------------------------------------------------
-- "classes" of tokens; the last 4 aren't standard in llex.c
-- * arrangement/count significant!!! hardcoded for stats display
-----------------------------------------------------------------------
ttypes = {
  "TK_KEYWORD", "TK_NAME", "TK_NUMBER", "TK_STRING", "TK_OP",
  "TK_EOS", "TK_COMMENT", "TK_LCOMMENT", "TK_EOL", "TK_SPACE",
}

-----------------------------------------------------------------------
-- reads source file and create token array + fill in statistics
-----------------------------------------------------------------------
function LoadFile(filename)
  if not filename and type(filename) ~= "string" then
    error("invalid filename specified")
  end
  stats_c = {}
  stats_l = {}
  ltok = {}
  lorig = {}
  lval = {}
  ntokens = 0
  for _, i in ipairs(ttypes) do   -- init counters
    stats_c[i] = 0; stats_l[i] = 0
  end
  ---------------------------------------------------------------------
  local INF = io.open(filename, "rb")
  if not INF then
    error("cannot open \""..filename.."\" for reading")
  end
  llex:setinput(INF, filename)
  local _ltok, _lorig, _lval
  local i = 0
  while _ltok ~= "TK_EOS" do
    _ltok, _lorig, _lval = llex:lex()
    i = i + 1
    ltok[i] = _ltok
    lorig[i] = _lorig
    lval[i] = _lval
    stats_c[_ltok] = stats_c[_ltok] + 1
    stats_l[_ltok] = stats_l[_ltok] + string.len(_lorig)
  end
  ntokens = i
  -- INF closed by llex
end

-----------------------------------------------------------------------
-- returns token tables containing valid tokens only (for verification)
-----------------------------------------------------------------------
function GetRealTokens(stok, sorig, stokens)
  local rtok, rorig, rtokens = {}, {}, 0
  for i = 1, stokens do
    local _stok = stok[i]
    local _sorig = sorig[i]
    if _stok ~= "TK_COMMENT" and _stok ~= "TK_LCOMMENT"
       and _stok ~= "TK_EOL" and _stok ~= "TK_SPACE" then
      rtokens = rtokens + 1
      rtok[rtokens] = _stok
      rorig[rtokens] = _sorig
    end
  end
  return rtok, rorig, rtokens
end

-----------------------------------------------------------------------
-- display only source token statistics (for --read-only option)
-----------------------------------------------------------------------
function DispSrcStats(filename)
  local underline = "--------------------------------\n"
  LoadFile(filename)
  print(title)
  io.stdout:write("Statistics for: "..filename.."\n\n"
    ..string.format("%-14s%8s%10s\n", "Elements", "Count", "Bytes")
    ..underline)
  local total_c, total_l, tok_c, tok_l = 0, 0, 0, 0
  for j = 1, 10 do
    local i = ttypes[j]
    local c, l = stats_c[i], stats_l[i]
    total_c = total_c + c
    total_l = total_l + l
    if j <= 6 then
      tok_c = tok_c + c
      tok_l = tok_l + l
    end
    io.stdout:write(string.format("%-14s%8d%10d\n", i, c, l))
    if i == "TK_EOS" then io.stdout:write(underline) end
  end
  io.stdout:write(underline
    ..string.format("%-14s%8d%10d\n", "Total Elements", total_c, total_l)
    ..underline
    ..string.format("%-14s%8d%10d\n", "Total Tokens", tok_c, tok_l)
    ..underline.."\n")
end

-----------------------------------------------------------------------
-- display source and destination stats (enabled by default)
-----------------------------------------------------------------------
function DispAllStats(srcfile, src_c, src_l, destfile, dest_c, dest_l)
  local underline = "--------------------------------------------------\n"
  print(title)
  local stot_c, stot_l, stok_c, stok_l = 0, 0, 0, 0
  local dtot_c, dtot_l, dtok_c, dtok_l = 0, 0, 0, 0
  io.stdout:write("Statistics for: "..srcfile.." -> "..destfile.."\n\n"
    ..string.format("%-14s%8s%10s%8s%10s\n", "Lexical", "Input", "Input", "Output", "Output")
    ..string.format("%-14s%8s%10s%8s%10s\n", "Elements", "Count", "Bytes", "Count", "Bytes")
    ..underline)
  for j = 1, 10 do
    local i = ttypes[j]
    local s_c, s_l = src_c[i], src_l[i]
    local d_c, d_l = dest_c[i], dest_l[i]
    stot_c = stot_c + s_c
    stot_l = stot_l + s_l
    dtot_c = dtot_c + d_c
    dtot_l = dtot_l + d_l
    if j <= 6 then
      stok_c = stok_c + s_c
      stok_l = stok_l + s_l
      dtok_c = dtok_c + d_c
      dtok_l = dtok_l + d_l
    end
    io.stdout:write(string.format("%-14s%8d%10d%8d%10d\n", i, s_c, s_l, d_c, d_l))
    if i == "TK_EOS" then io.stdout:write(underline) end
  end
  io.stdout:write(underline
    ..string.format("%-14s%8d%10d%8d%10d\n", "Total Elements", stot_c, stot_l, dtot_c, dtot_l)
    ..underline
    ..string.format("%-14s%8d%10d%8d%10d\n", "Total Tokens", stok_c, stok_l, dtok_c, dtok_l)
    ..underline.."\n")
end

-----------------------------------------------------------------------
-- token processing function
-----------------------------------------------------------------------
function ProcessToken(srcfile, destfile)
  LoadFile(srcfile)
  if ntokens < 1 then
    error("no tokens to process")
  end
  local dtok = {}               -- processed list of tokens
  local dorig = {}              -- processed list of original snippets
  local dtokens = 0             -- number of tokens generated
  local stok, sorig, stokens =  -- src tokens for verification
    GetRealTokens(ltok, lorig, ntokens)
  ---------------------------------------------------------------------
  -- saves specified token to the destination token list
  ---------------------------------------------------------------------
  local function savetok(src)
    dtokens = dtokens + 1
    dtok[dtokens] = ltok[src]
    dorig[dtokens] = lorig[src]
  end
  ---------------------------------------------------------------------
  -- check if token at location is whitespace-equivalent
  ---------------------------------------------------------------------
  local function iswhitespace(i)
    local tok = ltok[i]
    if tok == "TK_SPACE" or tok == "TK_EOL"
       or tok == "TK_COMMENT" or tok == "TK_LCOMMENT" then
      return true
    end
  end
  ---------------------------------------------------------------------
  -- compare two tokens and returns whitespace if needed in between
  -- * note that some comparisons won't occur in Lua code; we assume
  --   no knowledge of Lua syntax, only knowledge of lexical analysis
  ---------------------------------------------------------------------
  local function whitesp(previ, nexti)
    local p = ltok[previ]
    local n = ltok[nexti]
    -- if next token is a whitespace, remove current whitespace token
    if iswhitespace(n) then return "" end
    -- otherwise we are comparing non-whitespace tokens, so we use
    -- the following optimization rules...
    -------------------------------------------------------------------
    if p == "TK_OP" then
      if n == "TK_NUMBER" then
        -- eg . .123
        if string.sub(lorig[nexti], 1, 1) == "." then return " " end
      end
      return ""
    -------------------------------------------------------------------
    elseif p == "TK_KEYWORD" or p == "TK_NAME" then
      if n == "TK_KEYWORD" or n == "TK_NAME" then
        return " "
      elseif n == "TK_NUMBER" then
        -- eg foo.123
        if string.sub(lorig[nexti], 1, 1) == "." then return "" end
        return " "
      end
      return ""
    -------------------------------------------------------------------
    elseif p == "TK_STRING" then
      return ""
    -------------------------------------------------------------------
    elseif p == "TK_NUMBER" then
      if n == "TK_NUMBER" then
        return " "
      elseif n == "TK_KEYWORD" or n == "TK_NAME" then
        -- eg 123 e4
        local c = string.sub(lorig[nexti], 1, 1)
        if string.lower(c) == "e" then return " " end
      end
      return ""
    -------------------------------------------------------------------
    else -- should never arrive here
      error("token comparison failed")
    end
  end
  ---------------------------------------------------------------------
  -- main processing loop (pass 1)
  ---------------------------------------------------------------------
  local i = 1                   -- token position
  local linestart = true        -- true at the start of a line
  local tok = ""                -- current token
  local prev = 0                -- index of previous non-whitespace tok
  while true do
    tok = ltok[i]
    -------------------------------------------------------------------
    if tok == "TK_SPACE" then
      if linestart then
        -- delete leading whitespace
        lorig[i] = ""
      else
        -- remove in-between whitespace if possible
        lorig[i] = whitesp(prev, i + 1)
      end
      savetok(i)
    -------------------------------------------------------------------
    elseif tok == "TK_NAME" or tok == "TK_KEYWORD" or tok == "TK_OP"
           or tok == "TK_STRING" or tok == "TK_NUMBER" then
      -- these are all unchanged
      prev = i
      savetok(i)
      linestart = false
    -------------------------------------------------------------------
    elseif tok == "TK_EOL" then
      if linestart then
        if config.KEEP_LINES then
          savetok(i)
          linestart = true
        end
        -- otherwise it's an empty line, drop it
      else
        savetok(i)
        linestart = true
      end
    -------------------------------------------------------------------
    elseif tok == "TK_COMMENT" then
      -- must keep shbang for correctness, force a TK_EOL too
      if i == 1 and string.sub(lorig[i], 1, 1) == "#" then
        savetok(i)
        linestart = false
      end
      -- don't change linestart; the now empty line can be consumed
    -------------------------------------------------------------------
    elseif tok == "TK_LCOMMENT" then
      local eols = nil
      if config.KEEP_LINES then
        -- preserve newlines inside long comments
        if lval[i] > 0 then eols = string.rep("\n", lval[i]) end
      end
      if iswhitespace(i + 1) then
        lorig[i] = eols or ""
      else
        lorig[i] = eols or " "
      end
      savetok(i)
    -------------------------------------------------------------------
    elseif tok == "TK_EOS" then
      savetok(i)
      break
    -------------------------------------------------------------------
    else
      error("unidentified token encountered")
    end--if tok
    i = i + 1
  end--while
  ---------------------------------------------------------------------
  -- aggressive end-of-line removal pass (pass 2)
  ---------------------------------------------------------------------
  if config.ZAP_EOLS then
    ltok, lorig = {}, {}
    ntokens = 0
    -- redo source table by removing deleted bits
    for i = 1, dtokens do
      local tok = dtok[i]
      local orig = dorig[i]
      if orig ~= "" or tok == "TK_EOS" then
        ntokens = ntokens + 1
        ltok[ntokens] = tok
        lorig[ntokens] = orig
      end
    end
    -- try to remove end-of-lines by comparing token pairs
    dtok, dorig = {}, {}
    dtokens = 0
    i = 1
    tok, prev = "", ""
    while tok ~= "TK_EOS" do
      tok = ltok[i]
      if tok == "TK_EOL" and prev ~= "TK_COMMENT" then
        -- TK_COMMENT to trap shbang case
        if whitesp(i - 1, i + 1) == " " then    -- can't delete
          savetok(i)
        end
      else
        prev = tok
        savetok(i)
      end
      i = i + 1
    end--while
  end
  ---------------------------------------------------------------------
  -- write output file
  ---------------------------------------------------------------------
  local dest = table.concat(dorig)              -- join up source
  local OUTF = io.open(destfile, "wb")
  if not OUTF then
    error("cannot open \""..destfile.."\" for writing")
  end
  OUTF:write(dest)
  io.close(OUTF)
  ---------------------------------------------------------------------
  -- post processing: verification and reporting
  ---------------------------------------------------------------------
  src_stats_c = stats_c
  src_stats_l = stats_l
  LoadFile(destfile)            -- reload to verify output okay
  dtok, dorig, dtokens =        -- dest tokens for verification
    GetRealTokens(ltok, lorig, ntokens)
  -- WARNING the following WON'T WORK when an optimization method
  -- changes the real token stream in any way
  if stokens ~= dtokens then
    error("token count incorrect")
  end
  for i = 1, stokens do
    if stok[i] ~= dtok[i] or sorig[i] ~= dorig[i] then
      error("token verification by comparison failed")
    end
  end
  if not config.QUIET then
    DispAllStats(srcfile, src_stats_c, src_stats_l, destfile, stats_c, stats_l)
  end
end

-----------------------------------------------------------------------
-- dump token (diagnostic feature)
-----------------------------------------------------------------------
function DumpTokens(srcfile)
  local function Esc(v) return string.format("%q", v) end
  LoadFile(srcfile)
  for i = 1, ntokens do
    local ltok, lorig, lval = ltok[i], lorig[i], lval[i]
    -- display only necessary information
    if ltok == "TK_KEYWORD" or ltok == "TK_NAME" or
       ltok == "TK_NUMBER" or ltok == "TK_STRING" or
       ltok == "TK_OP" then
      print(ltok, lorig)
    elseif ltok == "TK_COMMENT" or ltok == "TK_LCOMMENT" or
           ltok == "TK_SPACE" then
      print(ltok, Esc(lorig))
    elseif ltok == "TK_EOS" or ltok == "TK_EOL" then
      print(ltok)
    else
      error("unknown token type encountered")
    end
  end
end

-----------------------------------------------------------------------
-- perform per-file handling
-----------------------------------------------------------------------
function DoFiles(files)
  for i, srcfile in ipairs(files) do
    local destfile
    -------------------------------------------------------------------
    -- find and replace extension for filenames
    -------------------------------------------------------------------
    local extb, exte = string.find(srcfile, "%.[^%.%\\%/]*$")
    local basename, extension = srcfile, ""
    if extb and extb > 1 then
      basename = string.sub(srcfile, 1, extb - 1)
      extension = string.sub(srcfile, extb, exte)
    end
    destfile = config.OUTPUT_FILE or basename..config.SUFFIX..extension
    if srcfile == destfile then
      error("output filename identical to input filename")
    end
    -------------------------------------------------------------------
    -- perform requested operations
    -------------------------------------------------------------------
    if config.DUMP then
      DumpTokens(srcfile)
    elseif config.READ_ONLY then
      DispSrcStats(srcfile)
    else
      ProcessToken(srcfile, destfile)
    end
  end--for
end

--[[-------------------------------------------------------------------
-- Command-line interface
-----------------------------------------------------------------------
--]]

function main()
  ---------------------------------------------------------------
  -- handle arguments
  ---------------------------------------------------------------
  if table.getn(arg) == 0 then
    print(title..usage) return
  end
  local files, i = {}, 1
  while i <= table.getn(arg) do
    local a, b = arg[i], arg[i + 1]
    if string.sub(a, 1, 1) == "-" then        -- handle options here
      if a == "-h" or a == "--help" then
        print(title) print(usage) return
      elseif a == "--quiet" then
        config.QUIET = true
      elseif a == "--read-only" then
        config.READ_ONLY = true
      elseif a == "--keep-lines" then
        config.KEEP_LINES = true
      elseif a == "--maximum" then
        config.MAX = true
      elseif a == "--dump" then
        config.DUMP = true
      elseif a == "-o" then
        if not b then error("-o option needs a file name") end
        config.OUTPUT_FILE = b
        i = i + 1
      elseif a == "--" then
        break -- ignore rest of args
      else
        error("unrecognized option "..a)
      end
    else
      table.insert(files, a)                  -- potential filename
    end
    i = i + 1
  end--while
  ---------------------------------------------------------------
  if config.MAX then
    -- set flags for maximum reduction
    config.KEEP_LINES = false
    config.ZAP_EOLS = true
  end
  if table.getn(files) > 0 then
    if table.getn(files) > 1 then
      if config.OUTPUT_FILE then
        error("with -o, only one source file can be specified")
      end
    end
    DoFiles(files)
  else
    print("LuaSrcDiet: nothing to do!")
  end
end

-----------------------------------------------------------------------
-- program entry point
-----------------------------------------------------------------------
if not TEST then
  local OK, msg = pcall(main)
  if not OK then
    print("* Run with option -h or --help for usage information")
    print(msg)
  end
end

-- end of script
