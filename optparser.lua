--[[--------------------------------------------------------------------

  optparser.lua: does parser-based optimizations
  This file is part of LuaSrcDiet.

  Copyright (c) 2008 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- NOTES:
-- *
----------------------------------------------------------------------]]

local base = _G
local string = require "string"
module "optparser"

----------------------------------------------------------------------
-- Letter frequencies for reducing symbol entropy
-- * Might help a wee bit when the output file is compressed
-- * See Wikipedia: http://en.wikipedia.org/wiki/Letter_frequencies
-- * We use letter frequencies according to a Linotype keyboard
-- * This is certainly not optimal, but is quick-and-dirty and the
--   process has no significant overhead
----------------------------------------------------------------------

local LETTERS = "etaoinshrdlucmfwypvbgkqjxz"

----------------------------------------------------------------------
--
----------------------------------------------------------------------
