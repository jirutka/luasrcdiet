#!/usr/bin/env lua
local l=string
local P=math
local K=table
local T=require
local d=print
local r=l.sub
local y=l.gmatch
local n=T"llex"local m=T"lparser"local c=T"optlex"local g=T"optparser"local h=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.11.0 (20080529)  Copyright (c) 2005-2008 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]local L=[[
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
  --details         extra info (strings, numbers, locals)

features (to disable, insert 'no' prefix like --noopt-comments):
%s
default settings:
%s]]local p=[[
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
]]local R=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]local k=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
]]local w=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals
]]local I="_"local function t(e)d("LuaSrcDiet: "..e);os.exit()end
if not l.match(_VERSION,"5.1",1,1)then
t("requires Lua 5.1 to run")end
local T=""do
local i=24
local o={}for n,t in y(p,"%s*([^,]+),'([^']+)'")do
local e="  "..n
e=e..l.rep(" ",i-#e)..t.."\n"T=T..e
o[n]=true
o["--no"..r(n,3)]=true
end
p=o
end
L=l.format(L,T,b)local _=I
local e={}local i,a
local function f(n)for o in y(n,"(%-%-%S+)")do
if r(o,3,4)=="no"and
p["--"..r(o,5)]then
e[r(o,5)]=false
else
e[r(o,3)]=true
end
end
end
local s={"TK_KEYWORD","TK_NAME","TK_NUMBER","TK_STRING","TK_LSTRING","TK_OP","TK_EOS","TK_COMMENT","TK_LCOMMENT","TK_EOL","TK_SPACE",}local A=7
local y={["\n"]="LF",["\r"]="CR",["\n\r"]="LFCR",["\r\n"]="CRLF",}local function u(o)local e=io.open(o,"rb")if not e then t('cannot open "'..o..'" for reading')end
local n=e:read("*a")if not n then t('cannot read from "'..o..'"')end
e:close()return n
end
local function x(e,n)local o=io.open(e,"wb")if not o then t('cannot open "'..e..'" for writing')end
local n=o:write(n)if not n then t('cannot write to "'..e..'"')end
o:close()end
local function E()i,a={},{}for o=1,#s do
local e=s[o]i[e],a[e]=0,0
end
end
local function O(e,o)i[e]=i[e]+1
a[e]=a[e]+#o
end
local function T()local function t(e,o)if e==0 then return 0 end
return o/e
end
local l={}local o,e=0,0
for l=1,A do
local n=s[l]o=o+i[n];e=e+a[n]end
i.TOTAL_TOK,a.TOTAL_TOK=o,e
l.TOTAL_TOK=t(o,e)o,e=0,0
for r=1,#s do
local n=s[r]o=o+i[n];e=e+a[n]l[n]=t(i[n],a[n])end
i.TOTAL_ALL,a.TOTAL_ALL=o,e
l.TOTAL_ALL=t(o,e)return l
end
local function S(a)local a=u(a)n.init(a)n.llex()local n,i=n.tok,n.seminfo
for t=1,#n do
local o,e=n[t],i[t]if o=="TK_OP"and l.byte(e)<32 then
e="("..l.byte(e)..")"elseif o=="TK_EOL"then
e=y[e]else
e="'"..e.."'"end
d(o.." "..e)end
end
local function y(s)local t=d
local c=u(s)n.init(c)n.llex()local s,r,c=n.tok,n.seminfo,n.tokln
m.init(s,r,c)local i,a=m.parser()local n=l.rep("-",72)t("*** Local/Global Variable Tracker Tables ***")t(n.."\n GLOBALS\n"..n)for l=1,#i do
local n=i[l]local e="("..l..") '"..n.name.."' -> "local o=n.xref
for n=1,#o do e=e..o[n].." "end
t(e)end
t(n.."\n LOCALS (decl=declared act=activated rem=removed)\n"..n)for n=1,#a do
local o=a[n]local e="("..n..") '"..o.name.."' decl:"..o.decl.." act:"..o.act.." rem:"..o.rem
if o.isself then
e=e.." isself"end
e=e.." -> "local o=o.xref
for n=1,#o do e=e..o[n].." "end
t(e)end
t(n.."\n")end
local function A(c)local e=d
local p=u(c)n.init(p)n.llex()local d,f=n.tok,n.seminfo
e(h)e("Statistics for: "..c.."\n")E()for e=1,#d do
local o,e=d[e],f[e]O(o,e)end
local c=T()local o=l.format
local function r(e)return i[e],a[e],c[e]end
local i,t="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"local n=l.rep("-",42)e(o(i,"Lexical","Input","Input","Input"))e(o(i,"Elements","Count","Bytes","Average"))e(n)for i=1,#s do
local l=s[i]e(o(t,l,r(l)))if l=="TK_EOS"then e(n)end
end
e(n)e(o(t,"Total Elements",r("TOTAL_ALL")))e(n)e(o(t,"Total Tokens",r("TOTAL_TOK")))e(n.."\n")end
local function I(p,L)local function o(...)if e.QUIET then return end
_G.print(...)end
local _=u(p)n.init(_)n.llex()local n,t,f=n.tok,n.seminfo,n.tokln
o(h)o("Statistics for: "..p.." -> "..L.."\n")E()for e=1,#n do
local o,e=n[e],t[e]O(o,e)end
local h=T()local p,u=i,a
if e["opt-locals"]then
g.print=o
m.init(n,t,f)local l,o=m.parser()g.optimize(e,n,t,l,o)end
c.print=o
n,t=c.optimize(e,n,t,f)local d=K.concat(t)if l.find(d,"\r\n",1,1)or
l.find(d,"\n\r",1,1)then
c.warn.mixedeol=true
end
x(L,d)E()for e=1,#n do
local e,o=n[e],t[e]O(e,o)end
local d=T()local n=l.format
local function r(e)return p[e],u[e],h[e],i[e],a[e],d[e]end
local i,t="%-16s%8s%8s%10s%8s%8s%10s","%-16s%8d%8d%10.2f%8d%8d%10.2f"local e=l.rep("-",68)o("*** lexer-based optimizations summary ***\n"..e)o(n(i,"Lexical","Input","Input","Input","Output","Output","Output"))o(n(i,"Elements","Count","Bytes","Average","Count","Bytes","Average"))o(e)for i=1,#s do
local l=s[i]o(n(t,l,r(l)))if l=="TK_EOS"then o(e)end
end
o(e)o(n(t,"Total Elements",r("TOTAL_ALL")))o(e)o(n(t,"Total Tokens",r("TOTAL_TOK")))o(e)if c.warn.lstring then
o("* WARNING: "..c.warn.lstring)elseif c.warn.mixedeol then
o("* WARNING: ".."output still contains some CRLF or LFCR line endings")end
o()end
local s={...}local a={}f(b)local function u(a)for d,o in ipairs(a)do
local i
local n,c=l.find(o,"%.[^%.%\\%/]*$")local s,l=o,""if n and n>1 then
s=r(o,1,n-1)l=r(o,n,c)end
i=s.._..l
if#a==1 and e.OUTPUT_FILE then
i=e.OUTPUT_FILE
end
if o==i then
t("output filename identical to input filename")end
if e.DUMP_LEXER then
S(o)elseif e.DUMP_PARSER then
y(o)elseif e.READ_ONLY then
A(o)else
I(o,i)end
end
end
local function c()local r,n=#s,1
if r==0 then
e.HELP=true
end
while n<=r do
local o,i=s[n],s[n+1]local l=l.match(o,"^%-%-?")if l=="-"then
if o=="-h"then
e.HELP=true;break
elseif o=="-v"then
e.VERSION=true;break
elseif o=="-s"then
if not i then t("-s option needs suffix specification")end
_=i
n=n+1
elseif o=="-o"then
if not i then t("-o option needs a file name")end
e.OUTPUT_FILE=i
n=n+1
elseif o=="-"then
break
else
t("unrecognized option "..o)end
elseif l=="--"then
if o=="--help"then
e.HELP=true;break
elseif o=="--version"then
e.VERSION=true;break
elseif o=="--keep"then
if not i then t("--keep option needs a string to match for")end
e.KEEP=i
n=n+1
elseif o=="--quiet"then
e.QUIET=true
elseif o=="--read-only"then
e.READ_ONLY=true
elseif o=="--basic"then
f(R)elseif o=="--maximum"then
f(k)elseif o=="--none"then
f(w)elseif o=="--dump-lexer"then
e.DUMP_LEXER=true
elseif o=="--dump-parser"then
e.DUMP_PARSER=true
elseif o=="--details"then
e.DETAILS=true
elseif p[o]then
f(o)else
t("unrecognized option "..o)end
else
a[#a+1]=o
end
n=n+1
end
if e.HELP then
d(h..L);return true
elseif e.VERSION then
d(h);return true
end
if#a>0 then
if#a>1 and e.OUTPUT_FILE then
t("with -o, only one source file can be specified")end
u(a)return true
else
t("nothing to do!")end
end
if not c()then
t("Please run with option -h or --help for usage information")end
