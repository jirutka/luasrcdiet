--[[--------------------------------------------------------------------

  optlex.lua: does lexer-based optimizations
  This file is part of LuaSrcDiet.

  Copyright (c) 2008 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- NOTES:
-- * For lexer-based optimization ideas, see the TODO items
----------------------------------------------------------------------]]

local base = _G
local string = require "string"
module "optlex"
local match = string.match
local sub = string.sub
local find = string.find

------------------------------------------------------------------------
-- variables and data structures
------------------------------------------------------------------------

-- error function, can override by setting own function into module
error = base.error

local stoks, sinfos             -- source lists

local is_realtoken = {          -- significant (grammar) tokens
  TK_KEYWORD = true,
  TK_NAME = true,
  TK_NUMBER = true,
  TK_STRING = true,
  TK_LSTRING = true,
  TK_OP = true,
  TK_EOS = true,
}
local is_faketoken = {          -- whitespace (non-grammar) tokens
  TK_COMMENT = true,
  TK_LCOMMENT = true,
  TK_EOL = true,
  TK_SPACE = true,
}

------------------------------------------------------------------------
-- true if current token is at the start of a line
-- * skips over deleted tokens via recursion
------------------------------------------------------------------------

local function atlinestart(i)
  local tok = stoks[i - 1]
  if i <= 1 or tok == "TK_EOL" then
    return true
  elseif tok == "" then
    return atlinestart(i - 1)
  end
  return false
end

------------------------------------------------------------------------
-- true if current token is at the end of a line
-- * skips over deleted tokens via recursion
------------------------------------------------------------------------

local function atlineend(i)
  local tok = stoks[i + 1]
  if i >= #stoks or tok == "TK_EOL" or tok == "TK_EOS" then
    return true
  elseif tok == "" then
    return atlineend(i + 1)
  end
  return false
end

------------------------------------------------------------------------
-- counts comment EOLs inside a long comment
-- * in order to keep line numbering, EOLs need to be reinserted
------------------------------------------------------------------------

local function commenteols(lcomment)
  local sep = #match(lcomment, "^%-%-%[=*%[")
  local z = sub(lcomment, sep + 1, -(sep - 1))  -- remove delims
  local i, c = 1, 0
  while true do
    local p, q, r, s = find(z, "([\r\n])([\r\n]?)", i)
    if not p then break end     -- if no matches, done
    i = p + 1
    c = c + 1
    if #s > 0 and r ~= s then   -- skip CRLF or LFCR
      i = i + 1
    end
  end
  return c
end

------------------------------------------------------------------------
-- compares two tokens (i, j) and returns the whitespace required
-- * important! see technotes.txt for more information
-- * only two grammar/real tokens are being considered
-- * if "", no separation is needed
-- * if " ", then at least one whitespace (or EOL) is required
------------------------------------------------------------------------

local function checkpair(i, j)
  local match = match
  local t1, t2 = stoks[i], stoks[j]
  --------------------------------------------------------------------
  if t1 == "TK_STRING" or t1 == "TK_LSTRING" or
     t2 == "TK_STRING" or t2 == "TK_LSTRING" then
    return ""
  --------------------------------------------------------------------
  elseif t1 == "TK_OP" or t2 == "TK_OP" then
    if (t1 == "TK_OP" and (t2 == "TK_KEYWORD" or t2 == "TK_NAME")) or
       (t2 == "TK_OP" and (t1 == "TK_KEYWORD" or t1 == "TK_NAME")) then
      return ""
    end
    if t1 == "TK_OP" and t2 == "TK_OP" then
      -- for TK_OP/TK_OP pairs, see notes in technotes.txt
      local op, op2 = sinfos[i], sinfos[j]
      if (match(op, "^%.%.?$") and match(op2, "^%.")) or
         (match(op, "^[~=<>]$") and op2 == "=") or
         (op == "[" and (op2 == "[" or op2 == "=")) then
        return " "
      end
      return ""
    end
    -- "TK_OP" + "TK_NUMBER" case
    local op = sinfos[i]
    if t2 == "TK_OP" then op = sinfos[j] end
    if match(op, "^%.%.?%.?$") then
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

local function repack_tokens()
  local dtoks, dinfos = {}, {}
  local j = 1
  for i = 1, #stoks do
    local tok = stoks[i]
    if tok ~= "" then
      dtoks[j], dinfos[j] = tok, sinfos[i]
      j = j + 1
    end
  end
  stoks, sinfos = dtoks, dinfos
end

------------------------------------------------------------------------
-- number optimization
-- * TODO leading zeros (before .)
-- * TODO trailing zeros (after .)
-- * TODO remove fractional portion entirely
-- * TODO translate from scientific notation
-- * TODO remove redundant '+'
-- * TODO simplify exponent number
-- * TODO translate from hexadecimal
-- * TODO translate from large normal number
------------------------------------------------------------------------

local function do_number(i)
end

------------------------------------------------------------------------
-- string optimization
-- * TODO normalize embedded newlines
-- * TODO undo unnecessary escapes
-- * TODO switch delimiters if shorter
-- * TODO translate some \xxx escape sequences
-- * TODO convert to long string?
------------------------------------------------------------------------

local function do_string(i)
end

------------------------------------------------------------------------
-- long string optimization
-- * TODO remove first redundant newline
-- * TODO normalize embedded newlines
-- * TODO reduce '=' separators if possible
-- * TODO convert to normal string?
------------------------------------------------------------------------

local function do_lstring(i)
end

------------------------------------------------------------------------
-- long comment optimization
-- * TODO trim trailing whitespace
-- * TODO normalize embedded newlines
------------------------------------------------------------------------

local function do_comment(i)
end

------------------------------------------------------------------------
-- comment optimization
-- * TODO trim trailing whitespace
-- * TODO normalize embedded newlines
------------------------------------------------------------------------

local function do_comment(i)
end

------------------------------------------------------------------------
-- main entry point
-- * currently, lexer processing has 2 passes
-- * processing is done on a line-oriented basis, which is easier to
--   grok due to the next point...
-- * since there are various options that can be enabled or disabled,
--   processing is a little messy or convoluted
------------------------------------------------------------------------

function optimize(option, toklist, semlist)
  --------------------------------------------------------------------
  -- set option flags
  --------------------------------------------------------------------
  local opt_comments = option["opt-comments"]
  local opt_whitespace = option["opt-whitespace"]
  local opt_emptylines = option["opt-emptylines"]
  local opt_eols = option["opt-eols"]
  local opt_strings = option["opt-strings"]
  local opt_numbers = option["opt-numbers"]
  if opt_eols then  -- forced settings, otherwise won't work properly
    opt_comments = true
    opt_whitespace = true
    opt_emptylines = true
  end
  --------------------------------------------------------------------
  -- variable initialization
  --------------------------------------------------------------------
  stoks, sinfos = toklist, semlist      -- set source lists
  local i = 1                           -- token position
  local tok                             -- current token
  local prev    -- position of last grammar token
                -- on same line (for TK_SPACE stuff)
  --------------------------------------------------------------------
  -- changes a token, info pair
  --------------------------------------------------------------------
  local function settoken(tok, info, I)
    I = I or i
    stoks[I] = tok or ""
    sinfos[I] = info or ""
  end
  --------------------------------------------------------------------
  -- processing loop (PASS 1)
  --------------------------------------------------------------------
  while true do
    tok, info = stoks[i], sinfos[i]
    ----------------------------------------------------------------
    local atstart = atlinestart(i)      -- set line begin flag
    if atstart then prev = nil end
    ----------------------------------------------------------------
    if tok == "TK_EOS" then             -- end of stream/pass
      break
    ----------------------------------------------------------------
    elseif tok == "TK_KEYWORD" or       -- keywords, identifiers,
           tok == "TK_NAME" or          -- operators
           tok == "TK_OP" then
      -- TK_KEYWORD and TK_OP can't be optimized without a big
      -- optimization framework; it would be more of an optimizing
      -- compiler, not a source code compressor
      -- TK_NAME that are locals needs parser to analyze/optimize
      prev = i
    ----------------------------------------------------------------
    elseif tok == "TK_NUMBER" then      -- numbers
      if opt_numbers then
        do_number(i)  -- optimize
      end
      prev = i
    ----------------------------------------------------------------
    elseif tok == "TK_STRING" or        -- strings, long strings
           tok == "TK_LSTRING" then
      if opt_strings then
        if tok == "TK_STRING" then
          do_string(i)  -- optimize
        else
          do_lstring(i)  -- optimize
        end
      end
      prev = i
    ----------------------------------------------------------------
    elseif tok == "TK_COMMENT" then     -- short comments
      if opt_comments then
        if i == 1 and sub(info, 1, 1) == "#" then
          -- keep shbang comment, trim whitespace
          do_comment(i)
        else
          -- safe to delete, as a TK_EOL (or TK_EOS) always follows
          settoken()  -- remove entirely
        end
      elseif opt_whitespace then        -- trim whitespace only
        do_comment(i)
      end
    ----------------------------------------------------------------
    elseif tok == "TK_LCOMMENT" then    -- long comments
      if opt_comments then
        local eols = commenteols(info)
        ------------------------------------------------------------
        -- prepare opt_emptylines case first, if a disposable token
        -- follows, current one is safe to dump, else keep a space;
        -- it is implied that the operation is safe for '-', because
        -- current is a TK_LCOMMENT, and must be separate from a '-'
        if is_faketoken[stoks[i + 1]] then
          settoken()  -- remove entirely
          tok = ""
        else
          settoken("TK_SPACE", " ")
        end
        ------------------------------------------------------------
        -- if there are embedded EOLs to keep and opt_emptylines is
        -- disabled, then switch the token into one or more EOLs
        if not opt_emptylines and eols > 0 then
          settoken("TK_EOL", string.rep("\n", eols))
        end
        ------------------------------------------------------------
        -- if optimizing whitespaces, force reinterpretation of the
        -- token to give a chance for the space to be optimized away
        if opt_whitespace and tok ~= "" then
          i = i - 1  -- to reinterpret
        end
        ------------------------------------------------------------
      else                              -- disabled case
        if opt_whitespace then          -- trim whitespace only
          do_lcomment(i)
        end
        prev = i
      end
    ----------------------------------------------------------------
    elseif tok == "TK_EOL" then         -- line endings
      if atstart and opt_emptylines then
        settoken()  -- remove entirely
      elseif info == "\r\n" or info == "\n\r" then
        -- normalize the rest of the EOLs for CRLF/LFCR only
        -- (note that TK_LCOMMENT can change into several EOLs)
        settoken("TK_EOL", "\n")
      end
    ----------------------------------------------------------------
    elseif tok == "TK_SPACE" then       -- whitespace
      if opt_whitespace then
        if atstart or atlineend(i) then
          -- delete leading and trailing whitespace
          settoken()  -- remove entirely
        else
          ------------------------------------------------------------
          -- at this point, since leading whitespace have been removed,
          -- there should be a either a real token or a TK_LCOMMENT
          -- prior to hitting this whitespace; the TK_LCOMMENT case
          -- only happens if opt_comments is disabled; so prev ~= nil
          local ptok = stoks[prev]
          if ptok == "TK_LCOMMENT" then
            -- previous TK_LCOMMENT can abut with anything
            settoken()  -- remove entirely
          else
            -- prev must be a grammar token; consecutive TK_SPACE
            -- tokens is impossible when optimizing whitespace
            local ntok = stoks[i + 1]
            if is_faketoken[ntok] then
              -- handle special case where a '-' cannot abut with
              -- either a short comment or a long comment
              if (ntok == "TK_COMMENT" or ntok == "TK_LCOMMENT") and
                 ptok == "TK_OP" and sinfos[prev] == "-" then
                -- keep token
              else
                settoken()  -- remove entirely
              end
            else--is_realtoken
              -- check a pair of grammar tokens, if can abut, then
              -- delete space token entirely, otherwise keep one space
              local s = checkpair(prev, i + 1)
              if s == "" then
                settoken()  -- remove entirely
              else
                settoken("TK_SPACE", " ")
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
    i = i + 1
  end--while
  repack_tokens()
  --------------------------------------------------------------------
  -- processing loop (PASS 2)
  --------------------------------------------------------------------
  if opt_eols then
    i = 1
    -- aggressive EOL removal only works with most non-grammar tokens
    -- optimized away, so basically it checks token pairs around EOLs
    -- first comment still existing must be an shbang, skip it & EOL
    if stoks[1] == "TK_COMMENT" then
      i = 3
    end
    while true do
      tok, info = stoks[i], sinfos[i]
      --------------------------------------------------------------
      if tok == "TK_EOS" then           -- end of stream/pass
        break
      --------------------------------------------------------------
      elseif tok == "TK_EOL" then       -- consider each TK_EOL
        local t1, t2 = stoks[i - 1], stoks[i + 1]
        if is_realtoken[t1] and is_realtoken[t2] then  -- sanity check
          local s = checkpair(i - 1, i + 1)
          if s == "" then
            settoken()  -- remove entirely
          end
        end
      end--if tok
      --------------------------------------------------------------
      i = i + 1
    end--while
    repack_tokens()
  end
  --------------------------------------------------------------------
  return stoks, sinfos
end
