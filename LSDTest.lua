--[[-------------------------------------------------------------------

  LSDTest.lua
  Test functions for LuaSrcDiet.lua, including automatic testing.

  Copyright (c) 2005 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions under which this
  software may be distributed (basically a Lua 5-style license.)

  http://luaforge.net/projects/luasrcdiet/
  (TODO) http://www.geocities.com/keinhong/luasrcdiet.html
  See the ChangeLog for more information.

-----------------------------------------------------------------------
--]]

--[[-------------------------------------------------------------------
-- Notes:
-- * To run: lua LSDTest.lua
-- * TODO include test suite for lexer (currently elsewhere)
-- * Look near the end of the script for testing options.
-- * Setting TEST disables main() in LuaSrcDiet.lua.
-----------------------------------------------------------------------
--]]

-----------------------------------------------------------------------
TEST    = true          -- always true to skip LuaSrcDiet's main()
require("LuaSrcDiet.lua")

-----------------------------------------------------------------------
-- tests adjacent pairs to see whether lexer accepts it
-- * most pairs would not be valid Lua code, just valid lexer input
-----------------------------------------------------------------------
function TestTokenPairs()
  local items = {
    "while'foo'", "foo'bar'", "12then", "12.34foo",
    "'foo'end", "'foo'bar", "'foo''bar'", "'foo'123",
    "12.3'foo'",
  }
  for _, chunk in ipairs(items) do
    llex:setstring(chunk, "(test)")
    local ltok, lorig, lval
    while ltok ~= "TK_EOS" do
      lline = llex.line
      ltok, lorig, lval = llex:lex()
      lorig = lorig or ""
      if ltok ~= "TK_EOS" then
        print(lline, ltok, "'"..lorig.."'")
      end
    end
    print()
  end
end

-----------------------------------------------------------------------
-- simple token dumper for visual inspection
-----------------------------------------------------------------------
function DumpTokens(filename)
  if not filename and type(filename) ~= "string" then
    error("invalid filename specified for DumpTokens")
  end
  local INF = io.open(filename, "rb")
  if not INF then
    error("cannot open \""..filename.."\" for reading")
  end
  llex:setinput(INF, filename)
  local ltok, lorig, lval
  while ltok ~= "TK_EOS" do
    lline = llex.line
    ltok, lorig, lval = llex:lex()
    print(lline, ltok)
    lorig = lorig or ""
    print("'"..lorig.."'")
    lval = lval or ""
    print(lval)
  end
  -- INF closed by llex
end

-----------------------------------------------------------------------
-- program entry point
-----------------------------------------------------------------------

-- token dump for visual inspection
--[[
DumpTokens("LuaSrcDiet.lua")
--]]
-- try out no-whitespace pairs
--[[
TestTokenPairs()
--]]

-- end of script
