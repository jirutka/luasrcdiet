--[[--------------------------------------------------------------------

  test_benchmark1.lua: Tests source/binary chunk load performance.
  This file is part of LuaSrcDiet.

  Copyright (c) 2008 Kein-Hong Man <khman@users.sf.net>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

  See the ChangeLog for more information.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- NOTES:
-- * Please have the appropriate files in the appropriate areas before
--   running this script.
-- * Binary chunk files are missing! See sample/Makefile or generate
--   using something like:
--     luac5.1 -s -o llex.out llex.lua
-- * There has to be LuaSrcDiet_fixed.lua and LuaSrcDiet_fixed_.lua
--   because loadstring() can't handle scripts with a shbang line.
-- * To test, run it like this:
--     lua5.1 test_benchmark1.lua
----------------------------------------------------------------------]]

------------------------------------------------------------------------
-- input datasets
------------------------------------------------------------------------

local FILE_SETS = {
-- uncompressed originals are in the parent directory
[[
LuaSrcDiet_fixed.lua
../llex.lua
../lparser.lua
../optlex.lua
../optparser.lua
]],
-- compressed sources (using --maximum) are in the ../sample directory
[[
LuaSrcDiet_fixed_.lua
../sample/llex.lua
../sample/lparser.lua
../sample/optlex.lua
../sample/optparser.lua
]],
-- stripped binary need to be generated and put somewhere
[[
../sample/LuaSrcDiet.out
../sample/llex.out
../sample/lparser.out
../sample/optlex.out
../sample/optparser.out
]],
-- dummy to measure call overhead
[[
foo
foo
foo
foo
foo
]],
}

------------------------------------------------------------------------
-- read data from file
------------------------------------------------------------------------

local function load_file(fname)
  if fname == "foo" then return "" end
  local INF = io.open(fname, "rb")
  if not INF then error("cannot open \""..fname.."\" for reading") end
  local dat = INF:read("*a")
  if not dat then error("cannot read from \""..fname.."\"") end
  INF:close()
  return dat
end

------------------------------------------------------------------------
-- load data
------------------------------------------------------------------------

local DATA_SETS = {}

for k = 1, #FILE_SETS do
  local dset = {}
  local fset = {}
  for fn in string.gmatch(FILE_SETS[k], "%S+") do
    fset[#fset + 1] = fn
  end
  dset.size = 0
  for j = 1, #fset do
    local data = load_file(fset[j])
    if not loadstring(data) then
      error("error trying to load script \""..fset[j].."\"")
    end
    dset[j] = data
    dset.size = dset.size + #data
  end
  DATA_SETS[k] = dset
end

------------------------------------------------------------------------
-- benchmark tester
------------------------------------------------------------------------

local DURATION = 1       -- how long the benchmark should run

local loadstring = loadstring
local time = os.time

for k = 1, #DATA_SETS do
  local dset = DATA_SETS[k]
  local tnow, elapsed, c = time(), 0, 0
  while time() == tnow do end  -- wait for second to click over
  tnow = time()
  while true do
    for i = 1, #dset do
      local fn = loadstring(dset[i])
    end
    c = c + 1
    if time() > tnow then
      tnow = time()
      elapsed = elapsed + 1
      if elapsed == DURATION then break end
    end
  end
  print("Set: ", k)
  print("Size: ", dset.size)
  print("Iterations: ", c)
  print("Duration: ", DURATION)
  print()
end

-- end of script
