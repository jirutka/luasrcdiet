--[[--------------------------------------------------------------------

  test_llex.lua: Tests for llex.lua
  This file is part of LuaSrcDiet, based on Yueliang material.

  Copyright (c) 2008 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- NOTES:
-- * Changes compared to tests in Yueliang 0.4.0:
--   (a) whitespace tests VT and FF ('\v' and '\f') also, which were not
--       significant in a normal lexer, but needed here
--   (b) shbang tests added because LuaSrcDiet needs to support it
--   (c) added a test for control characters, does it really matter?
--   (d) added a test for accented identifier names, test FAILS
-- * To test, run it like this:
--     lua5.1 test_llex.lua
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- if BRIEF is not set to false, auto-test will silently succeed
------------------------------------------------------------------------
BRIEF = true  -- if set to true, messages are less verbose

package.path = "../?.lua;"..package.path
local llex = require "llex"

------------------------------------------------------------------------
-- simple manual test
------------------------------------------------------------------------

--[[
local function dump(z)
  llex.init(z)
  llex.llex()
  local tok, seminfo = llex.tok, llex.seminfo
  for i = 1, #tok do
    io.stdout:write(tok[i].." '"..seminfo[i].."'\n")
  end
end

dump("local c = luaZ:zgetc(z)")
os.exit()
--]]

------------------------------------------------------------------------
-- auto-testing of simple test cases to validate lexer behaviour:
-- * NOTE coverage has not been checked; not comprehensive
-- * only test cases with non-empty comments are processed
-- * if no result, then the output is displayed for manual decision
--   (output may be used to set expected success or fail text)
-- * cases expected to be successful may be a partial match
-- * cases expected to fail may also be a partial match
------------------------------------------------------------------------

-- [=====[
local function auto_test()
  local PASS, FAIL = true, false
  ------------------------------------------------------------------
  -- table of test cases
  ------------------------------------------------------------------
  local test_cases =
  {
    -------------------------------------------------------------
  --{ "comment",  -- comment about the test
  --  "chunk",    -- chunk to test
  --  PASS,       -- PASS or FAIL outcome
  --  "output",   -- output to compare against
  --},
    -------------------------------------------------------------
    { "empty chunk string, test EOS",
      "",
      PASS, "TK_EOS = \n",
    },
    -------------------------------------------------------------
    { "line number counting",
      "\n\n \r\n",
      PASS, "TK_EOL = LF\nTK_EOL = LF\nTK_SPACE = ' '\nTK_EOL = CRLF\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "various whitespaces 1",
      "  \n\t\t\n  \t  \t \n\n",
      PASS, "TK_SPACE = '  '\nTK_EOL = LF\nTK_SPACE = '\t\t'\nTK_EOL = LF\nTK_SPACE = '  \t  \t '\nTK_EOL = LF\nTK_EOL = LF\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "various whitespaces 2",
      "\v\f \v\v \f\f",
      PASS, "TK_SPACE = '\v\f \v\v \f\f'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "short comment ending in EOS",
      "-- moo moo",
      PASS, "TK_COMMENT = -- moo moo\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "short comment ending in newline",
      "-- moo moo\n",
      PASS, "TK_COMMENT = -- moo moo\nTK_EOL = LF\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "several lines of short comments",
      "--moo\n-- moo moo\n\n--\tmoo\n",
      PASS, "TK_COMMENT = --moo\nTK_EOL = LF\nTK_COMMENT = -- moo moo\nTK_EOL = LF\nTK_EOL = LF\nTK_COMMENT = --\tmoo\nTK_EOL = LF\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "basic block comment 1",
      "--[[bovine]]",
      PASS, "TK_LCOMMENT = --[[bovine]]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "basic block comment 2",
      "--[=[bovine]=]",
      PASS, "TK_LCOMMENT = --[=[bovine]=]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "basic block comment 3",
      "--[====[-[[bovine]]-]====]",
      PASS, "TK_LCOMMENT = --[====[-[[bovine]]-]====]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "unterminated block comment 1",
      "--[[bovine",
      FAIL, ":1: unfinished long comment",
    },
    -------------------------------------------------------------
    { "unterminated block comment 2",
      "--[==[bovine",
      FAIL, ":1: unfinished long comment",
    },
    -------------------------------------------------------------
    { "unterminated block comment 3",
      "--[[bovine]",
      FAIL, ":1: unfinished long comment",
    },
    -------------------------------------------------------------
    { "unterminated block comment 4",
      "--[[bovine\nmoo moo\nwoof",
      FAIL, ":3: unfinished long comment",
    },
    -------------------------------------------------------------
    { "basic long string 1",
      "\n[[bovine]]\n",
      PASS, "TK_EOL = LF\nTK_LSTRING = [[bovine]]\nTK_EOL = LF\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "basic long string 2",
      "\n[=[bovine]=]\n",
      PASS, "TK_EOL = LF\nTK_LSTRING = [=[bovine]=]\nTK_EOL = LF\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "first newline consumed in long string",
      "[[\nmoo]]",
      PASS, "TK_LSTRING = [[\nmoo]]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "multiline long string 1",
      "[[moo\nmoo moo\n]]",
      PASS, "TK_LSTRING = [[moo\nmoo moo\n]]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "multiline long string 2",
      "[===[moo\n[=[moo moo]=]\n]===]",
      PASS, "TK_LSTRING = [===[moo\n[=[moo moo]=]\n]===]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "unterminated long string 1",
      "\n[[\nbovine",
      FAIL, ":3: unfinished long string",
    },
    -------------------------------------------------------------
    { "unterminated long string 2",
      "[[bovine]",
      FAIL, ":1: unfinished long string",
    },
    -------------------------------------------------------------
    { "unterminated long string 2",
      "[==[bovine]==",
      FAIL, ":1: unfinished long string",
    },
    -------------------------------------------------------------
    { "complex long string 1",
      "[=[moo[[moo]]moo]=]",
      PASS, "TK_LSTRING = [=[moo[[moo]]moo]=]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "complex long string 2",
      "[=[moo[[moo[[[[]]]]moo]]moo]=]",
      PASS, "TK_LSTRING = [=[moo[[moo[[[[]]]]moo]]moo]=]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "complex long string 3",
      "[=[[[[[]]]][[[[]]]]]=]",
      PASS, "TK_LSTRING = [=[[[[[]]]][[[[]]]]]=]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    -- NOTE: this native lexer does not support compatible long
    -- strings (LUA_COMPAT_LSTR)
    -------------------------------------------------------------
  --{ "deprecated long string 1",
  --  "[[moo[[moo]]moo]]",
  --  FAIL, ":1: nesting of [[...]] is deprecated near '['",
  --},
  ---------------------------------------------------------------
  --{ "deprecated long string 2",
  --  "[[[[ \n",
  --  FAIL, ":1: nesting of [[...]] is deprecated near '['",
  --},
  ---------------------------------------------------------------
  --{ "deprecated long string 3",
  --  "[[moo[[moo[[[[]]]]moo]]moo]]",
  --  FAIL, ":1: nesting of [[...]] is deprecated near '['",
  --},
  ---------------------------------------------------------------
  --{ "deprecated long string 4",
  --  "[[[[[[]]]][[[[]]]]]]",
  --  FAIL, ":1: nesting of [[...]] is deprecated near '['",
  --},
    -------------------------------------------------------------
    { "brackets in long strings 1",
      "[[moo[moo]]",
      PASS, "TK_LSTRING = [[moo[moo]]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "brackets in long strings 2",
      "[=[moo[[moo]moo]]moo]=]",
      PASS, "TK_LSTRING = [=[moo[[moo]moo]]moo]=]\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "unprocessed escapes in long strings",
      [[ [=[\a\b\f\n\r\t\v\123]=] ]],
      PASS, "TK_SPACE = ' '\nTK_LSTRING = [=[\\a\\b\\f\\n\\r\\t\\v\\123]=]\nTK_SPACE = ' '\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "unbalanced long string",
      "[[moo]]moo]]",
      PASS, "TK_LSTRING = [[moo]]\nTK_NAME = moo\nTK_OP = ']'\nTK_OP = ']'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "keywords 1",
      "and break do else",
      PASS, "TK_KEYWORD = and\nTK_SPACE = ' '\nTK_KEYWORD = break\nTK_SPACE = ' '\nTK_KEYWORD = do\nTK_SPACE = ' '\nTK_KEYWORD = else\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "keywords 2",
      "elseif end false for",
      PASS, "TK_KEYWORD = elseif\nTK_SPACE = ' '\nTK_KEYWORD = end\nTK_SPACE = ' '\nTK_KEYWORD = false\nTK_SPACE = ' '\nTK_KEYWORD = for\nTK_EOS = \n",
      PASS, "1 elseif\n1 end\n1 false\n1 for\n1 <eof>",
    },
    -------------------------------------------------------------
    { "keywords 3",
      "function if in local nil",
      PASS, "TK_KEYWORD = function\nTK_SPACE = ' '\nTK_KEYWORD = if\nTK_SPACE = ' '\nTK_KEYWORD = in\nTK_SPACE = ' '\nTK_KEYWORD = local\nTK_SPACE = ' '\nTK_KEYWORD = nil\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "keywords 4",
      "not or repeat return",
      PASS, "TK_KEYWORD = not\nTK_SPACE = ' '\nTK_KEYWORD = or\nTK_SPACE = ' '\nTK_KEYWORD = repeat\nTK_SPACE = ' '\nTK_KEYWORD = return\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "keywords 5",
      "then true until while",
      PASS, "TK_KEYWORD = then\nTK_SPACE = ' '\nTK_KEYWORD = true\nTK_SPACE = ' '\nTK_KEYWORD = until\nTK_SPACE = ' '\nTK_KEYWORD = while\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "concat and dots",
      ".. ...",
      PASS, "TK_OP = '..'\nTK_SPACE = ' '\nTK_OP = '...'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    -- NOTE: shbang handling needed for LuaSrcDiet
    -------------------------------------------------------------
    { "shbang handling 1",
      "#blahblah",
      PASS, "TK_COMMENT = #blahblah\nTK_EOS = \n",
      PASS, "1 <eof>",
    },
    -------------------------------------------------------------
    { "shbang handling 2",
      "#blahblah\nmoo moo\n",
      PASS, "TK_COMMENT = #blahblah\nTK_EOL = LF\nTK_NAME = moo\nTK_SPACE = ' '\nTK_NAME = moo\nTK_EOL = LF\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "empty string",
      [['']],
      PASS, "TK_STRING = ''\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "single-quoted string",
      [['bovine']],
      PASS, "TK_STRING = 'bovine'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "double-quoted string",
      [["bovine"]],
      PASS, "TK_STRING = \"bovine\"\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "unterminated string 1",
      [['moo ]],
      FAIL, ":1: unfinished string",
    },
    -------------------------------------------------------------
    { "unterminated string 2",
      [["moo \n]],
      FAIL, ":1: unfinished string",
    },
    -------------------------------------------------------------
    { "escaped newline in string, line number counted",
      "\"moo\\\nmoo\\\nmoo\"",
      PASS, "TK_STRING = \"moo\\\nmoo\\\nmoo\"\nTK_EOS = \n",
      PASS, "3 <string> = moo\nmoo\nmoo\n3 <eof>",
    },
    -------------------------------------------------------------
    { "escaped characters in string 1",
      [["moo\amoo"]],
      PASS, "TK_STRING = \"moo\\amoo\"\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "escaped characters in string 2",
      [["moo\bmoo"]],
      PASS, "TK_STRING = \"moo\\bmoo\"\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "escaped characters in string 3",
      [["moo\f\n\r\t\vmoo"]],
      PASS, "TK_STRING = \"moo\\f\\n\\r\\t\\vmoo\"\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "escaped characters in string 4",
      [["\\ \" \' \? \[ \]"]],
      PASS, "TK_STRING = \"\\\\ \\\" \\\' \\? \\[ \\]\"\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "escaped characters in string 5",
      [["\z \k \: \;"]],
      PASS, "TK_STRING = \"\\z \\k \\: \\;\"\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "escaped characters in string 6",
      [["\8 \65 \160 \180K \097097"]],
      PASS, "TK_STRING = \"\\8 \\65 \\160 \\180K \\097097\"\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "escaped characters in string 7",
      [["\666"]],
      FAIL, ":1: escape sequence too large",
    },
    -------------------------------------------------------------
    { "simple numbers",
      "123 123+",
      PASS, "TK_NUMBER = 123\nTK_SPACE = ' '\nTK_NUMBER = 123\nTK_OP = '+'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "longer numbers",
      "1234567890 12345678901234567890",
      PASS, "TK_NUMBER = 1234567890\nTK_SPACE = ' '\nTK_NUMBER = 12345678901234567890\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "fractional numbers",
      ".123 .12345678901234567890",
      PASS, "TK_NUMBER = .123\nTK_SPACE = ' '\nTK_NUMBER = .12345678901234567890\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "more numbers with decimal points",
      "12345.67890",
      PASS, "TK_NUMBER = 12345.67890\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "malformed number with decimal points",
      "1.1.",
      FAIL, ":1: malformed number",
    },
    -------------------------------------------------------------
    { "double decimal points",
      ".1.1",
      FAIL, ":1: malformed number",
    },
    -------------------------------------------------------------
    { "double dots within numbers",
      "1..1",
      FAIL, ":1: malformed number",
    },
    -------------------------------------------------------------
    { "incomplete exponential numbers",
      "123e",
      FAIL, ":1: malformed number",
    },
    -------------------------------------------------------------
    { "exponential numbers 1",
      "1234e5 1234e5.",
      PASS, "TK_NUMBER = 1234e5\nTK_SPACE = ' '\nTK_NUMBER = 1234e5\nTK_OP = '.'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "exponential numbers 2",
      "1234e56 1.23e123",
      PASS, "TK_NUMBER = 1234e56\nTK_SPACE = ' '\nTK_NUMBER = 1.23e123\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "exponential numbers 3",
      "12.34e+",
      FAIL, ":1: malformed number",
    },
    -------------------------------------------------------------
    { "exponential numbers 4",
      "12.34e+5 123.4e-5 1234.E+5",
      PASS, "TK_NUMBER = 12.34e+5\nTK_SPACE = ' '\nTK_NUMBER = 123.4e-5\nTK_SPACE = ' '\nTK_NUMBER = 1234.E+5\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "hexadecimal numbers",
      "0x00FF 0X1234 0xDEADBEEF",
      PASS, "TK_NUMBER = 0x00FF\nTK_SPACE = ' '\nTK_NUMBER = 0X1234\nTK_SPACE = ' '\nTK_NUMBER = 0xDEADBEEF\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "invalid hexadecimal numbers 1",
      "0xFOO",
      FAIL, ":1: malformed number",
    },
    -------------------------------------------------------------
    { "invalid hexadecimal numbers 2",
      "0.BAR",
      FAIL, ":1: malformed number",
    },
    -------------------------------------------------------------
    { "invalid hexadecimal numbers 3",
      "0BAZ",
      FAIL, ":1: malformed number",
    },
    -------------------------------------------------------------
    { "single character symbols 1",
      "= > < ~ #",
      PASS, "TK_OP = '='\nTK_SPACE = ' '\nTK_OP = '>'\nTK_SPACE = ' '\nTK_OP = '<'\nTK_SPACE = ' '\nTK_OP = '~'\nTK_SPACE = ' '\nTK_OP = '#'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "double character symbols",
      "== >= <= ~=",
      PASS, "TK_OP = '=='\nTK_SPACE = ' '\nTK_OP = '>='\nTK_SPACE = ' '\nTK_OP = '<='\nTK_SPACE = ' '\nTK_OP = '~='\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "simple identifiers",
      "abc ABC",
      PASS, "TK_NAME = abc\nTK_SPACE = ' '\nTK_NAME = ABC\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "more identifiers",
      "_abc _ABC",
      PASS, "TK_NAME = _abc\nTK_SPACE = ' '\nTK_NAME = _ABC\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "still more identifiers",
      "_aB_ _123",
      PASS, "TK_NAME = _aB_\nTK_SPACE = ' '\nTK_NAME = _123\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "identifiers with accented characters",
      "àáâ ÈÉÊ",
      PASS, "TK_NAME = àáâ\nTK_SPACE = ' '\nTK_NAME = ÈÉÊ\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "single character symbols 2",
      "` ! @ $ %",
      PASS, "TK_OP = '`'\nTK_SPACE = ' '\nTK_OP = '!'\nTK_SPACE = ' '\nTK_OP = '@'\nTK_SPACE = ' '\nTK_OP = '$'\nTK_SPACE = ' '\nTK_OP = '%'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "single character symbols 3",
      "^ & * ( )",
      PASS, "TK_OP = '^'\nTK_SPACE = ' '\nTK_OP = '&'\nTK_SPACE = ' '\nTK_OP = '*'\nTK_SPACE = ' '\nTK_OP = '('\nTK_SPACE = ' '\nTK_OP = ')'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "single character symbols 4",
      "_ - + \\ |",
      PASS, "TK_NAME = _\nTK_SPACE = ' '\nTK_OP = '-'\nTK_SPACE = ' '\nTK_OP = '+'\nTK_SPACE = ' '\nTK_OP = '\\'\nTK_SPACE = ' '\nTK_OP = '|'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "single character symbols 5",
      "{ } [ ] :",
      PASS, "TK_OP = '{'\nTK_SPACE = ' '\nTK_OP = '}'\nTK_SPACE = ' '\nTK_OP = '['\nTK_SPACE = ' '\nTK_OP = ']'\nTK_SPACE = ' '\nTK_OP = ':'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "single character symbols 6",
      "; , . / ?",
      PASS, "TK_OP = ';'\nTK_SPACE = ' '\nTK_OP = ','\nTK_SPACE = ' '\nTK_OP = '.'\nTK_SPACE = ' '\nTK_OP = '/'\nTK_SPACE = ' '\nTK_OP = '?'\nTK_EOS = \n",
    },
    -------------------------------------------------------------
    { "some control characters",
      "\4\16\20",
      PASS, "TK_OP = (4)\nTK_OP = (16)\nTK_OP = (20)\nTK_EOS = \n",
    },
    -------------------------------------------------------------
-- [=====[
--]=====]
  }
  ------------------------------------------------------------------
  -- perform a test case
  ------------------------------------------------------------------
  function do_test_case(count, test_case)
    if comment == "" then return end  -- skip empty entries
    local comment, chunk, outcome, matcher = unpack(test_case)
    local result = PASS
    local output = ""
    -- initialize lexer
    llex.init(chunk, "=test")
    -- lexer sequence
    local status, msg = pcall(llex.llex)  -- protected call
    local tokenlist, seminfolist = llex.tok, llex.seminfo
    if status then
      -- successful call
      for i = 1, #tokenlist do
        local token, seminfo = tokenlist[i], seminfolist[i]
        if token == "TK_OP" then
          if string.byte(seminfo) >= 32 then  -- displayable chars
            seminfo = "'"..seminfo.."'"
          else  -- control characters
            seminfo = "(".. string.byte(seminfo)..")"
          end
        elseif token == "TK_EOL" then
          if seminfo == "\r" then
            seminfo = "CR"
          elseif seminfo == "\n" then
            seminfo = "LF"
          elseif seminfo == "\r\n" then
            seminfo = "CRLF"
          else
            seminfo = "LFCR"
          end
        elseif token == "TK_SPACE" then
          seminfo = "'"..seminfo.."'"
        end
        output = output..token.." = "..seminfo.."\n"
      end
    else
      -- failed call
      output = output..msg  -- token is the error message
      result = FAIL
    end
    -- decision making and reporting
    local head = "Test "..count..": "..comment
    if matcher == "" then
      -- nothing to check against, display for manual check
      print(head.."\nMANUAL please check manually"..
            "\n--chunk---------------------------------\n"..chunk..
            "\n--actual--------------------------------\n"..output..
            "\n\n")
      return
    else
      if outcome == PASS then
        -- success expected
        -- USE THIS IF PARTIAL MATCH: string.find(output, matcher, 1, 1)
        if output == matcher and result == PASS then
          if not BRIEF then print(head.."\nOK expected success\n") end
          return
        end
      else
        -- failure expected, may be a partial match
        if string.find(output, matcher, 1, 1) and result == FAIL then
          if not BRIEF then print(head.."\nOK expected failure\n") end
          return
        end
      end
      -- failed because of unmatched string or boolean result
      local function passfail(status)
        if status == PASS then return "PASS" else return "FAIL" end
      end
      print(head.." *FAILED*"..
            "\noutcome="..passfail(outcome)..
            "\nactual= "..passfail(result)..
            "\n--chunk---------------------------------\n"..chunk..
            "\n--expected------------------------------\n"..matcher..
            "\n--actual--------------------------------\n"..output..
            "\n\n")
    end
  end
  ------------------------------------------------------------------
  -- perform auto testing
  ------------------------------------------------------------------
  for i,test_case in ipairs(test_cases) do
    do_test_case(i, test_case)
  end
end

auto_test()
--]=====]
