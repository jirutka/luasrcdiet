#!/usr/bin/env lua
--[[--------------------------------------------------------------------

  onefile.lua: stuffs LuaSrcDiet modules into the main file
  This file is part of LuaSrcDiet.

  Copyright (c) 2008,2011 Kein-Hong Man <keinhong@gmail.com>
  The COPYRIGHT file describes the conditions
  under which this software may be distributed.

----------------------------------------------------------------------]]

--[[--------------------------------------------------------------------
-- NOTES:
-- * WARNING: assumptions are made in processing the source files,
--   see the stuff that is hard-coded into this script below...
----------------------------------------------------------------------]]

-- standard libraries, functions
local string = string
local find = string.find
local match = string.match
local sub = string.sub
local type = type

--[[--------------------------------------------------------------------
-- configuration
----------------------------------------------------------------------]]

local SOURCE_DIR = "../src/"

local MAIN_SOURCE = SOURCE_DIR.."LuaSrcDiet.lua"
local MAIN_TARGET = "../bin/LuaSrcDiet.lua"

local moduls = {
  "llex", "lparser", "optlex", "optparser", "equiv",
  "plugin/html", "plugin/sloc",
}

local plugin_info = [[
local plugin_info = {
  html = "html    generates a HTML file for checking globals",
  sloc = "sloc    calculates SLOC for given source file",
}

]]

-- handle embedded plugin reporting
local has_plugins
local p_embedded = "local p_embedded = {\n"
for i = 1, #moduls do
  local m = moduls[i]
  local p = match(m, "^plugin/([_%a][_%w]*)$")
  if p then
    has_plugins = true
    p_embedded = p_embedded.."  '"..p.."',\n"
  end
end
p_embedded = p_embedded.."}\n\n"

--[[--------------------------------------------------------------------
-- utility functions
----------------------------------------------------------------------]]

-- simple error message handler; change to error if traceback wanted
local function die(msg)
  print("onefile: "..msg); os.exit(1)
end
--die = error--DEBUG

------------------------------------------------------------------------
-- read source code from file
------------------------------------------------------------------------

local function load_file(fname)
  local INF = io.open(fname, "rb")
  if not INF then die('cannot open "'..fname..'" for reading') end
  local dat = INF:read("*a")
  if not dat then die('cannot read from "'..fname..'"') end
  INF:close()
  return dat
end

------------------------------------------------------------------------
-- save source code to file
------------------------------------------------------------------------

local function save_file(fname, dat)
  local OUTF = io.open(fname, "wb")
  if not OUTF then die('cannot open "'..fname..'" for writing') end
  local status = OUTF:write(dat)
  if not status then die('cannot write to "'..fname..'"') end
  OUTF:close()
end

------------------------------------------------------------------------
-- split raw file data into lines
------------------------------------------------------------------------

local function split_data(dat)
  local t = {}
  while true do
    local p, q, r, e1, e2 = find(dat, "([^\r\n]*)([\r\n])([\r\n]?)")
    if not p then break end
    if e1 == "\r" and e2 == "\n" then -- handle CRLF
      e1 = e1..e2
    end
    r = r..e1
    t[#t + 1] = r
    dat = sub(dat, #r + 1)
  end--while
  if #dat > 0 then -- final line without EOL char
    t[#t + 1] = dat
  end
  return t
end

--[[--------------------------------------------------------------------
-- main functions
----------------------------------------------------------------------]]

local w = {} -- target

------------------------------------------------------------------------
-- adds a string or a set of lines into target table w
------------------------------------------------------------------------
local function addw(t, n1, n2)
  if type(t) == "string" then
    w[#w + 1] = t
    return
  end
  if n1 > #t or n2 > #t or n1 > n2 then return end
  for i = n1, n2 do
    w[#w + 1] = t[i]
  end
end

------------------------------------------------------------------------
-- find start of module requires, must insert modules before it
------------------------------------------------------------------------
local z = load_file(MAIN_SOURCE)
z = split_data(z)
local matcher = '^%-%- support modules'
local zid
for i = 1, #z do
  local ln = z[i]
  if match(ln, matcher) then
    zid = i; break
  end
end
if not zid then
  die('cannot find require start in "'..MAIN_SOURCE..'"')
end
addw(z, 1, zid - 1)     -- add code before module requires
addw([[
-- modules incorporated as preload functions follows
local preload = package.preload
local base = _G

]])                     -- add preload boilerplate
if has_plugins then
  addw(plugin_info)
  addw(p_embedded)
end

------------------------------------------------------------------------
-- process each module and add pre-module boilerplate
------------------------------------------------------------------------
for i = 1, #moduls do
  modul = moduls[i]
  local mfname = SOURCE_DIR..modul..".lua"
  local y = load_file(mfname)
  y = split_data(y)
  local matcher = '^module%s"'..modul..'"'
  local yid
  for j = 1, #y do
    local ln = y[j]
    if match(ln, matcher) then
      yid = j; break
    end
  end
  if not yid then
    die('cannot find module start in "'..mfname..'"')
  end
  -- handle names that are not in identifier form
  local preload_name = modul
  if not match(preload_name, "^[_%a][_%w]*$") then
    preload_name = 'preload["'..preload_name..'"]'
  else
    preload_name = "preload."..preload_name
  end
  -- found module start, add pre-module boilerplate
  addw("-- preload function for module "..modul.."\n"
     ..preload_name.." =\n"
     .."function()\n"
     .."--start of inserted module\n")
  addw(y, yid, #y)
  addw("--end of inserted module\n"
     .."end\n\n")
end

addw(z, zid, #z)        -- add rest of code

save_file(MAIN_TARGET, table.concat(w)) -- save processed code

-- end of script
