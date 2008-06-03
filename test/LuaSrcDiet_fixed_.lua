local o=string
local I=math
local j=table
local r=o.sub
local q=o.gmatch
local a=require"llex"local f=require"lparser"local l=require"optlex"local k=require"optparser"local m=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.11.0 (20080529)  Copyright (c) 2005-2008 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]local v=[[
usage: LuaSrcDiet [options] [filenames]

example:
  >LuaSrcDiet myscript.lua -o myscript_.lua

options:
  -v, --version     prints version information
  -h, --help        prints usage information
  -o <file>         specify file name to write output
  -s <suffix>       suffix for output files (default '_')
  --keep <msg>      keep block comment with <msg> inside
  -                 stop handling arguments

  (optimization levels)
  --none            all optimizations off (normalizes EOLs only)
  --basic           lexer-based optimizations only
  --maximum         maximize reduction of source

  (informational)
  --quiet           process files quietly
  --read-only       read file and print token stats only
  --dump-lexer      dump raw tokens from lexer to stdout
  --dump-parser     dump variable tracking tables from parser
  --details         gives extra information, e.g. detailed stats

features (to disable, insert 'no' prefix like --noopt-comments):
%s
default settings:
%s]]local c=[[
--opt-comments,'remove comments and block comments'
--opt-whitespace,'remove whitespace excluding EOLs'
--opt-emptylines,'remove empty lines'
--opt-eols,'all above, plus remove unnecessary EOLs'
--opt-strings,'optimize strings and long strings'
--opt-numbers,'optimize numbers'
--opt-locals,'optimize local variable names'
]]local g=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
]]local x=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]local A=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers --opt-locals
]]local T=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]local E="_"local function i(e)print("LuaSrcDiet: "..e);os.exit()end
if not o.match(_VERSION,"5.1",1,1)then
i("requires Lua 5.1 to run")end
local p=""do
local n=24
local a={}for t,i in q(c,"%s*([^,]+),'([^']+)'")do
local e="  "..t
e=e..o.rep(" ",n-#e)..i.."\n"p=p..e
a[t]=true
a["--no"..r(t,3)]=true
end
c=a
end
v=o.format(v,p,g)local b=E
local e={}local s,n
local function d(a)for t in q(a,"(%-%-%S+)")do
if r(t,3,4)=="no"and
c["--"..r(t,5)]then
e[r(t,5)]=false
else
e[r(t,3)]=true
end
end
end
local h={"TK_KEYWORD","TK_NAME","TK_NUMBER","TK_STRING","TK_LSTRING","TK_OP","TK_EOS","TK_COMMENT","TK_LCOMMENT","TK_EOL","TK_SPACE",}local _=7
local z={["\n"]="LF",["\r"]="CR",["\n\r"]="LFCR",["\r\n"]="CRLF",}local function u(e)local t=io.open(e,"rb")if not t then i('cannot open "'..e..'" for reading')end
local a=t:read("*a")if not a then i('cannot read from "'..e..'"')end
t:close()return a
end
local function q(e,a)local t=io.open(e,"wb")if not t then i('cannot open "'..e..'" for writing')end
local a=t:write(a)if not a then i('cannot write to "'..e..'"')end
t:close()end
local function p()s,n={},{}for t=1,#h do
local e=h[t]s[e],n[e]=0,0
end
end
local function y(e,t)s[e]=s[e]+1
n[e]=n[e]+#t
end
local function w()local function i(e,t)if e==0 then return 0 end
return t/e
end
local o={}local t,e=0,0
for o=1,_ do
local a=h[o]t=t+s[a];e=e+n[a]end
s.TOTAL_TOK,n.TOTAL_TOK=t,e
o.TOTAL_TOK=i(t,e)t,e=0,0
for r=1,#h do
local a=h[r]t=t+s[a];e=e+n[a]o[a]=i(s[a],n[a])end
s.TOTAL_ALL,n.TOTAL_ALL=t,e
o.TOTAL_ALL=i(t,e)return o
end
local function O(s)local n=u(s)a.init(n)a.llex()local i,n=a.tok,a.seminfo
for a=1,#i do
local t,e=i[a],n[a]if t=="TK_OP"and o.byte(e)<32 then
e="("..o.byte(e)..")"elseif t=="TK_EOL"then
e=z[e]else
e="'"..e.."'"end
print(t.." "..e)end
end
local function z(h)local i=print
local h=u(h)a.init(h)a.llex()local r,d,h=a.tok,a.seminfo,a.tokln
f.init(r,d,h)local n,s=f.parser()local a=o.rep("-",72)i("*** Local/Global Variable Tracker Tables ***")i(a.."\n GLOBALS\n"..a)for o=1,#n do
local a=n[o]local e="("..o..") '"..a.name.."' -> "local t=a.xref
for a=1,#t do e=e..t[a].." "end
i(e)end
i(a.."\n LOCALS (decl=declared act=activated rem=removed)\n"..a)for a=1,#s do
local t=s[a]local e="("..a..") '"..t.name.."' decl:"..t.decl.." act:"..t.act.." rem:"..t.rem
if t.isself then
e=e.." isself"end
e=e.." -> "local t=t.xref
for a=1,#t do e=e..t[a].." "end
i(e)end
i(a.."\n")end
local function _(r)local e=print
local l=u(r)a.init(l)a.llex()local d,l=a.tok,a.seminfo
e(m)e("Statistics for: "..r.."\n")p()for e=1,#d do
local e,t=d[e],l[e]y(e,t)end
local r=w()local a=o.format
local function i(e)return s[e],n[e],r[e]end
local s,n="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"local t=o.rep("-",42)e(a(s,"Lexical","Input","Input","Input"))e(a(s,"Elements","Count","Bytes","Average"))e(t)for s=1,#h do
local o=h[s]e(a(n,o,i(o)))if o=="TK_EOS"then e(t)end
end
e(t)e(a(n,"Total Elements",i("TOTAL_ALL")))e(t)e(a(n,"Total Tokens",i("TOTAL_TOK")))e(t.."\n")end
local function E(d,c)local function t(...)if e.QUIET then return end
_G.print(...)end
local g=u(d)a.init(g)a.llex()local a,i,u=a.tok,a.seminfo,a.tokln
t(m)t("Statistics for: "..d.." -> "..c.."\n")p()for e=1,#a do
local t,e=a[e],i[e]y(t,e)end
local v=w()local b,m=s,n
if e["opt-locals"]then
k.print=t
f.init(a,i,u)local o,t=f.parser()k.optimize(e,a,i,o,t)end
a,i=l.optimize(e,a,i,u)local r=j.concat(i)if o.find(r,"\r\n",1,1)or
o.find(r,"\n\r",1,1)then
l.warn.mixedeol=true
end
q(c,r)p()for e=1,#a do
local t,e=a[e],i[e]y(t,e)end
local d=w()local a=o.format
local function r(e)return b[e],m[e],v[e],s[e],n[e],d[e]end
local n,i="%-16s%8s%8s%10s%8s%8s%10s","%-16s%8d%8d%10.2f%8d%8d%10.2f"local e=o.rep("-",68)t("*** lexer-based optimizations summary ***\n"..e)t(a(n,"Lexical","Input","Input","Input","Output","Output","Output"))t(a(n,"Elements","Count","Bytes","Average","Count","Bytes","Average"))t(e)for n=1,#h do
local o=h[n]t(a(i,o,r(o)))if o=="TK_EOS"then t(e)end
end
t(e)t(a(i,"Total Elements",r("TOTAL_ALL")))t(e)t(a(i,"Total Tokens",r("TOTAL_TOK")))t(e)if l.warn.lstring then
t("* WARNING: "..l.warn.lstring)elseif l.warn.mixedeol then
t("* WARNING: ".."output still contains some CRLF or LFCR line endings")end
t()end
local h={...}local s={}d(g)local function u(h)for l,t in ipairs(h)do
local a
local o,d=o.find(t,"%.[^%.%\\%/]*$")local n,s=t,""if o and o>1 then
n=r(t,1,o-1)s=r(t,o,d)end
a=n..b..s
if#h==1 and e.OUTPUT_FILE then
a=e.OUTPUT_FILE
end
if t==a then
i("output filename identical to input filename")end
if e.DUMP_LEXER then
O(t)elseif e.DUMP_PARSER then
z(t)elseif e.READ_ONLY then
_(t)else
E(t,a)end
end
end
local function l()local r,a=#h,1
if r==0 then
e.HELP=true
end
while a<=r do
local t,n=h[a],h[a+1]local o=o.match(t,"^%-%-?")if o=="-"then
if t=="-h"then
e.HELP=true;break
elseif t=="-v"then
e.VERSION=true;break
elseif t=="-s"then
if not n then i("-s option needs suffix specification")end
b=n
a=a+1
elseif t=="-o"then
if not n then i("-o option needs a file name")end
e.OUTPUT_FILE=n
a=a+1
elseif t=="-"then
break
else
i("unrecognized option "..t)end
elseif o=="--"then
if t=="--help"then
e.HELP=true;break
elseif t=="--version"then
e.VERSION=true;break
elseif t=="--keep"then
if not n then i("--keep option needs a string to match for")end
e.KEEP=n
a=a+1
elseif t=="--quiet"then
e.QUIET=true
elseif t=="--read-only"then
e.READ_ONLY=true
elseif t=="--basic"then
d(x)elseif t=="--maximum"then
d(A)elseif t=="--none"then
d(T)elseif t=="--dump-lexer"then
e.DUMP_LEXER=true
elseif t=="--dump-parser"then
e.DUMP_PARSER=true
elseif t=="--details"then
e.DETAILS=true
elseif c[t]then
d(t)else
i("unrecognized option "..t)end
else
s[#s+1]=t
end
a=a+1
end
if e.HELP then
print(m..v);return true
elseif e.VERSION then
print(m);return true
end
if#s>0 then
if#s>1 and e.OUTPUT_FILE then
i("with -o, only one source file can be specified")end
u(s)return true
else
i("nothing to do!")end
end
if not l()then
i("Please run with option -h or --help for usage information")end
