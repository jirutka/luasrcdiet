-- string samples in lieu of automatic testing PUBLIC DOMAIN 2008
-- note: does not test newlines other than LF
-- note: does not comprehensively test delimiter switching
--
-- empty strings
local a=""
local a=''
-- simple string
local a="foo bar BAZ 123"
-- alphanumeric characters
local a="abcdefghijklmnopqrstuvxyz0123456789"
-- escaped 'normal' alphabets
local a="\c\d\e\g\h\i\j\k\l\m\o\p\q\s\u\x\y\z"
-- unescaped punctuation
local a="~`!@#$%^&*()-_=+|[]{};:,.<>/?"
-- escaped punctuation
local a="\~\`\!\@\#\$\%\^\&\*\(\)\-\_\=\+\|\[\]\{\}\;\:\,\.\<\>\/\?"
-- \a\b\f\n\r\t\v -- no change
local a="\a\b\f\n\r\t\v"
-- \\ -- no change
local a="\\"
local a='\\'
-- \"\' -- depends on delim, other can remove \
local a="\'\""
local a='\'\"'
-- \<eol> -- normalize the EOL only
local a="\
"
local a="foo\
bar"
local a="foo\
\
bar"
-- \ddd -- if \a\b\f\n\r\t\v, change to latter
local a="\7\8\9\10\11\12\13"
-- \ddd -- if other < ascii 32, keep ddd but zap leading zeros
local a="\0\1\2\3\4\5\6\14\15"
local a="\16\17\18\19\20\21\22\23\24\25\26\27\28\29\30\31"
local a="\000\01\004\015"
-- \ddd -- if >= ascii 32, translate into literal, check \\,\",\' cases
local a="\32\065\097\164"
local a="\92"
local a="\39\34"
local a='\39\34'
-- switch delimiters if string becomes shorter
local a="'\"\"\"\"\"\"'"
local a='"\'\'\'\'\'\'"'
