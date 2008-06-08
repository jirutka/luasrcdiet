#!/usr/bin/env lua
local l=string
local e=math
local P=table
local u=require
local d=print
local c=l.sub
local r=l.gmatch
local n=u"llex"local h=u"lparser"local f=u"optlex"local x=u"optparser"local o
local L=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.11.2 (20080608)  Copyright (c) 2005-2008 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]local E=[[
usage: LuaSrcDiet [options] [filenames]

example:
  >LuaSrcDiet myscript.lua -o myscript_.lua

options:
  -v, --version       prints version information
  -h, --help          prints usage information
  -o <file>           specify file name to write output
  -s <suffix>         suffix for output files (default '_')
  --keep <msg>        keep block comment with <msg> inside
  --plugin <module>   run <module> in plugin/ directory
  -                   stop handling arguments

  (optimization levels)
  --none              all optimizations off (normalizes EOLs only)
  --basic             lexer-based optimizations only
  --maximum           maximize reduction of source

  (informational)
  --quiet             process files quietly
  --read-only         read file and print token stats only
  --dump-lexer        dump raw tokens from lexer to stdout
  --dump-parser       dump variable tracking tables from parser
  --details           extra info (strings, numbers, locals)

features (to disable, insert 'no' prefix like --noopt-comments):
%s
default settings:
%s]]local m=[[
--opt-comments,'remove comments and block comments'
--opt-whitespace,'remove whitespace excluding EOLs'
--opt-emptylines,'remove empty lines'
--opt-eols,'all above, plus remove unnecessary EOLs'
--opt-strings,'optimize strings and long strings'
--opt-numbers,'optimize numbers'
--opt-locals,'optimize local variable names'
--opt-entropy,'tries to reduce symbol entropy of locals'
]]local b=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
]]local k=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]local K=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
]]local S=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]local s="_"local w="plugin/"local function i(e)d("LuaSrcDiet: "..e);os.exit()end
if not l.match(_VERSION,"5.1",1,1)then
i("requires Lua 5.1 to run")end
local t=""do
local a=24
local o={}for n,i in r(m,"%s*([^,]+),'([^']+)'")do
local e="  "..n
e=e..l.rep(" ",a-#e)..i.."\n"t=t..e
o[n]=true
o["--no"..c(n,3)]=true
end
m=o
end
E=l.format(E,t,b)local y=s
local e={}local a,s
local function p(n)for n in r(n,"(%-%-%S+)")do
if c(n,3,4)=="no"and
m["--"..c(n,5)]then
e[c(n,5)]=false
else
e[c(n,3)]=true
end
end
end
local r={"TK_KEYWORD","TK_NAME","TK_NUMBER","TK_STRING","TK_LSTRING","TK_OP","TK_EOS","TK_COMMENT","TK_LCOMMENT","TK_EOL","TK_SPACE",}local I=7
local A={["\n"]="LF",["\r"]="CR",["\n\r"]="LFCR",["\r\n"]="CRLF",}local function T(n)local e=io.open(n,"rb")if not e then i('cannot open "'..n..'" for reading')end
local o=e:read("*a")if not o then i('cannot read from "'..n..'"')end
e:close()return o
end
local function R(e,o)local n=io.open(e,"wb")if not n then i('cannot open "'..e..'" for writing')end
local o=n:write(o)if not o then i('cannot write to "'..e..'"')end
n:close()end
local function g()a,s={},{}for e=1,#r do
local e=r[e]a[e],s[e]=0,0
end
end
local function _(e,n)a[e]=a[e]+1
s[e]=s[e]+#n
end
local function O()local function l(e,n)if e==0 then return 0 end
return n/e
end
local t={}local n,e=0,0
for o=1,I do
local o=r[o]n=n+a[o];e=e+s[o]end
a.TOTAL_TOK,s.TOTAL_TOK=n,e
t.TOTAL_TOK=l(n,e)n,e=0,0
for o=1,#r do
local o=r[o]n=n+a[o];e=e+s[o]t[o]=l(a[o],s[o])end
a.TOTAL_ALL,s.TOTAL_ALL=n,e
t.TOTAL_ALL=l(n,e)return t
end
local function v(e)local e=T(e)n.init(e)n.llex()local n,o=n.tok,n.seminfo
for e=1,#n do
local n,e=n[e],o[e]if n=="TK_OP"and l.byte(e)<32 then
e="("..l.byte(e)..")"elseif n=="TK_EOL"then
e=A[e]else
e="'"..e.."'"end
d(n.." "..e)end
end
local function A(e)local o=d
local e=T(e)n.init(e)n.llex()local e,t,n=n.tok,n.seminfo,n.tokln
h.init(e,t,n)local n,i=h.parser()local t=l.rep("-",72)o("*** Local/Global Variable Tracker Tables ***")o(t.."\n GLOBALS\n"..t)for e=1,#n do
local n=n[e]local e="("..e..") '"..n.name.."' -> "local n=n.xref
for t=1,#n do e=e..n[t].." "end
o(e)end
o(t.."\n LOCALS (decl=declared act=activated rem=removed)\n"..t)for e=1,#i do
local n=i[e]local e="("..e..") '"..n.name.."' decl:"..n.decl.." act:"..n.act.." rem:"..n.rem
if n.isself then
e=e.." isself"end
e=e.." -> "local n=n.xref
for t=1,#n do e=e..n[t].." "end
o(e)end
o(t.."\n")end
local function I(o)local e=d
local t=T(o)n.init(t)n.llex()local n,t=n.tok,n.seminfo
e(L)e("Statistics for: "..o.."\n")g()for e=1,#n do
local e,n=n[e],t[e]_(e,n)end
local o=O()local n=l.format
local function i(e)return a[e],s[e],o[e]end
local t,a="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"local o=l.rep("-",42)e(n(t,"Lexical","Input","Input","Input"))e(n(t,"Elements","Count","Bytes","Average"))e(o)for t=1,#r do
local t=r[t]e(n(a,t,i(t)))if t=="TK_EOS"then e(o)end
end
e(o)e(n(a,"Total Elements",i("TOTAL_ALL")))e(o)e(n(a,"Total Tokens",i("TOTAL_TOK")))e(o.."\n")end
local function N(d,p)local function t(...)if e.QUIET then return end
_G.print(...)end
if o and o.init then
e.EXIT=false
o.init(e,d,p)if e.EXIT then return end
end
t(L)local i=T(d)if o and o.post_load then
i=o.post_load(i)or i
if e.EXIT then return end
end
n.init(i)n.llex()local n,i,c=n.tok,n.seminfo,n.tokln
if o and o.post_lex then
o.post_lex(n,i,c)if e.EXIT then return end
end
g()for e=1,#n do
local e,n=n[e],i[e]_(e,n)end
local u=O()local m,T=a,s
if e["opt-locals"]then
x.print=t
h.init(n,i,c)local l,t=h.parser()if o and o.post_parse then
o.post_parse(l,t)if e.EXIT then return end
end
x.optimize(e,n,i,l,t)if o and o.post_optparse then
o.post_optparse()if e.EXIT then return end
end
end
f.print=t
n,i,c=f.optimize(e,n,i,c)if o and o.post_optlex then
o.post_optlex(n,i,c)if e.EXIT then return end
end
local e=P.concat(i)if l.find(e,"\r\n",1,1)or
l.find(e,"\n\r",1,1)then
f.warn.mixedeol=true
end
R(p,e)g()for e=1,#n do
local e,n=n[e],i[e]_(e,n)end
local o=O()t("Statistics for: "..d.." -> "..p.."\n")local n=l.format
local function i(e)return m[e],T[e],u[e],a[e],s[e],o[e]end
local a,o="%-16s%8s%8s%10s%8s%8s%10s","%-16s%8d%8d%10.2f%8d%8d%10.2f"local e=l.rep("-",68)t("*** lexer-based optimizations summary ***\n"..e)t(n(a,"Lexical","Input","Input","Input","Output","Output","Output"))t(n(a,"Elements","Count","Bytes","Average","Count","Bytes","Average"))t(e)for l=1,#r do
local l=r[l]t(n(o,l,i(l)))if l=="TK_EOS"then t(e)end
end
t(e)t(n(o,"Total Elements",i("TOTAL_ALL")))t(e)t(n(o,"Total Tokens",i("TOTAL_TOK")))t(e)if f.warn.lstring then
t("* WARNING: "..f.warn.lstring)elseif f.warn.mixedeol then
t("* WARNING: ".."output still contains some CRLF or LFCR line endings")end
t()end
local a={...}local s={}p(b)local function f(s)for o,n in ipairs(s)do
local t
local o,r=l.find(n,"%.[^%.%\\%/]*$")local l,a=n,""if o and o>1 then
l=c(n,1,o-1)a=c(n,o,r)end
t=l..y..a
if#s==1 and e.OUTPUT_FILE then
t=e.OUTPUT_FILE
end
if n==t then
i("output filename identical to input filename")end
if e.DUMP_LEXER then
v(n)elseif e.DUMP_PARSER then
A(n)elseif e.READ_ONLY then
I(n)else
N(n,t)end
end
end
local function r()local n,t=#a,1
if n==0 then
e.HELP=true
end
while t<=n do
local n,a=a[t],a[t+1]local l=l.match(n,"^%-%-?")if l=="-"then
if n=="-h"then
e.HELP=true;break
elseif n=="-v"then
e.VERSION=true;break
elseif n=="-s"then
if not a then i("-s option needs suffix specification")end
y=a
t=t+1
elseif n=="-o"then
if not a then i("-o option needs a file name")end
e.OUTPUT_FILE=a
t=t+1
elseif n=="-"then
break
else
i("unrecognized option "..n)end
elseif l=="--"then
if n=="--help"then
e.HELP=true;break
elseif n=="--version"then
e.VERSION=true;break
elseif n=="--keep"then
if not a then i("--keep option needs a string to match for")end
e.KEEP=a
t=t+1
elseif n=="--plugin"then
if not a then i("--plugin option needs a module name")end
if e.PLUGIN then i("only one plugin can be specified")end
e.PLUGIN=a
o=u(w..a)t=t+1
elseif n=="--quiet"then
e.QUIET=true
elseif n=="--read-only"then
e.READ_ONLY=true
elseif n=="--basic"then
p(k)elseif n=="--maximum"then
p(K)elseif n=="--none"then
p(S)elseif n=="--dump-lexer"then
e.DUMP_LEXER=true
elseif n=="--dump-parser"then
e.DUMP_PARSER=true
elseif n=="--details"then
e.DETAILS=true
elseif m[n]then
p(n)else
i("unrecognized option "..n)end
else
s[#s+1]=n
end
t=t+1
end
if e.HELP then
d(L..E);return true
elseif e.VERSION then
d(L);return true
end
if#s>0 then
if#s>1 and e.OUTPUT_FILE then
i("with -o, only one source file can be specified")end
f(s)return true
else
i("nothing to do!")end
end
if not r()then
i("Please run with option -h or --help for usage information")end
