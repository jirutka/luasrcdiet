-- vim: set ft=lua:

package = 'LuaSrcDiet'
version = 'dev-0'

source = {
  url = 'git://github.com/jirutka/LuaSrcDiet.git',
  branch = 'master',
}

description = {
  summary = 'Compresses Lua source code by removing unnecessary characters',
  detailed = [[
This is revival of LuaSrcDiet originally written by Kein-Hong Man.]],
  homepage = 'https://github.com/jirutka/LuaSrcDiet',
  maintainer = 'Jakub Jirutka <jakub@jirutka.cz>',
  license = 'MIT',
}

dependencies = {
  'lua >= 5.1',
}

build = {
  type = 'builtin',
  modules = {
    ['luasrcdiet.plugin.example'] = 'luasrcdiet/plugin/example.lua',
    ['luasrcdiet.plugin.html'] = 'luasrcdiet/plugin/html.lua',
    ['luasrcdiet.plugin.sloc'] = 'luasrcdiet/plugin/sloc.lua',
    ['luasrcdiet.equiv'] = 'luasrcdiet/equiv.lua',
    ['luasrcdiet.llex'] = 'luasrcdiet/llex.lua',
    ['luasrcdiet.lparser'] = 'luasrcdiet/lparser.lua',
    ['luasrcdiet.LuaSrcDiet'] = 'luasrcdiet/LuaSrcDiet.lua',
    ['luasrcdiet.optlex'] = 'luasrcdiet/optlex.lua',
    ['luasrcdiet.optparser'] = 'luasrcdiet/optparser.lua',
  },
  install = {
    bin = {
      luasrcdiet = 'luasrcdiet/LuaSrcDiet.lua',
    }
  }
}
