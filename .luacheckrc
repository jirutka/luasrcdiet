-- vim: set ft=lua:

include_files = { 'bin/**', 'luasrcdiet/**' }
ignore = {
  '542', -- empty if branch
}
files = {
  ['luasrcdiet/llex.lua'] = {
    ignore = { '411' },  -- variable was previosly defined
  },
  ['luasrcdiet/lparser.lua'] = {
    ignore = { '431' },  -- shadowing upvalue
  },
  ['luasrcdiet/optparser.lua'] = {
    ignore = { '421' },  -- shadowing definition of variable
  },
}
std = 'min'
codes = true
