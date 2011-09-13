#!/usr/bin/env lua
local i=string
local e=math
local ee=table
local K=require
local b=print
local m=i.sub
local Z=i.gmatch
local j=i.match
local _=package.preload
local l=_G
local ne={html="html    generates a HTML file for checking globals",sloc="sloc    calculates SLOC for given source file",}local z={'html','sloc',}_.llex=function()module"llex"local c=l.require"string"local s=c.find
local h=c.match
local i=c.sub
local p={}for e in c.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]],"%S+")do
p[e]=true
end
local e,f,o,a,r
local function t(n,l)local e=#tok+1
tok[e]=n
seminfo[e]=l
tokln[e]=r
end
local function d(n,c)local a=i
local l=a(e,n,n)n=n+1
local e=a(e,n,n)if(e=="\n"or e=="\r")and(e~=l)then
n=n+1
l=l..e
end
if c then t("TK_EOL",l)end
r=r+1
o=n
return n
end
function init(n,l)e=n
f=l
o=1
r=1
tok={}seminfo={}tokln={}local n,a,e,l=s(e,"^(#[^\r\n]*)(\r?\n?)")if n then
o=o+#e
t("TK_COMMENT",e)if#l>0 then d(o,true)end
end
end
function chunkid()if f and h(f,"^[=@]")then
return i(f,2)end
return"[string]"end
function errorline(e,n)local l=error or l.error
l(c.format("%s:%d: %s",chunkid(),n or r,e))end
local c=errorline
local function u(n)local t=i
local a=t(e,n,n)n=n+1
local l=#h(e,"=*",n)n=n+l
o=n
return(t(e,n,n)==a)and l or(-l)-1
end
local function T(f,r)local n=o+1
local l=i
local t=l(e,n,n)if t=="\r"or t=="\n"then
n=d(n)end
while true do
local t,s,i=s(e,"([\r\n%]])",n)if not t then
c(f and"unfinished long string"or"unfinished long comment")end
n=t
if i=="]"then
if u(n)==r then
a=l(e,a,o)o=o+1
return a
end
n=o
else
a=a.."\n"n=d(n)end
end
end
local function m(f)local n=o
local r=s
local i=i
while true do
local t,s,l=r(e,"([\n\r\\\"'])",n)if t then
if l=="\n"or l=="\r"then
c"unfinished string"end
n=t
if l=="\\"then
n=n+1
l=i(e,n,n)if l==""then break end
t=r("abfnrtv\n\r",l,1,true)if t then
if t>7 then
n=d(n)else
n=n+1
end
elseif r(l,"%D")then
n=n+1
else
local o,l,e=r(e,"^(%d%d?%d?)",n)n=l+1
if e+1>256 then
c"escape sequence too large"end
end
else
n=n+1
if l==f then
o=n
return i(e,a,n-1)end
end
else
break
end
end
c"unfinished string"end
function llex()local r=s
local f=h
while true do
local n=o
while true do
local h,b,s=r(e,"^([_%a][_%w]*)",n)if h then
o=n+#s
if p[s]then
t("TK_KEYWORD",s)else
t("TK_NAME",s)end
break
end
local s,p,h=r(e,"^(%.?)%d",n)if s then
if h=="."then n=n+1 end
local u,a,d=r(e,"^%d*[%.%d]*([eE]?)",n)n=a+1
if#d==1 then
if f(e,"^[%+%-]",n)then
n=n+1
end
end
local a,n=r(e,"^[_%w]*",n)o=n+1
local e=i(e,s,n)if not l.tonumber(e)then
c"malformed number"end
t("TK_NUMBER",e)break
end
local p,s,h,l=r(e,"^((%s)[ \t\v\f]*)",n)if p then
if l=="\n"or l=="\r"then
d(n,true)else
o=s+1
t("TK_SPACE",h)end
break
end
local l=f(e,"^%p",n)if l then
a=n
local d=r("-[\"'.=<>~",l,1,true)if d then
if d<=2 then
if d==1 then
local c=f(e,"^%-%-(%[?)",n)if c then
n=n+2
local l=-1
if c=="["then
l=u(n)end
if l>=0 then
t("TK_LCOMMENT",T(false,l))else
o=r(e,"[\n\r]",n)or(#e+1)t("TK_COMMENT",i(e,a,o-1))end
break
end
else
local e=u(n)if e>=0 then
t("TK_LSTRING",T(true,e))elseif e==-1 then
t("TK_OP","[")else
c"invalid long string delimiter"end
break
end
elseif d<=5 then
if d<5 then
o=n+1
t("TK_STRING",m(l))break
end
l=f(e,"^%.%.?%.?",n)else
l=f(e,"^%p=?",n)end
end
o=n+#l
t("TK_OP",l)break
end
local e=i(e,n,n)if e~=""then
o=n+1
t("TK_OP",e)break
end
t("TK_EOS","")return
end
end
end
end
_.lparser=function()module"lparser"local L=l.require"string"local k,K,g,y,i,r,V,n,A,c,h,b,o,z,N,P,s,E,R,v
local m,u,O,w,x,I
local e=L.gmatch
local C={}for e in e("else elseif end until <eof>","%S+")do
C[e]=true
end
local M={}local B={}for e,n,l in e([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")do
M[e]=n+0
B[e]=l+0
end
local ee={["not"]=true,["-"]=true,["#"]=true,}local Z=8
local function t(e,n)local l=error or l.error
l(L.format("(source):%d: %s",n or c,e))end
local function e()V=g[i]n,A,c,h=k[i],K[i],g[i],y[i]i=i+1
end
local function j()return k[i]end
local function d(l)local e=n
if e~="<number>"and e~="<string>"then
if e=="<name>"then e=A end
e="'"..e.."'"end
t(l.." near "..e)end
local function p(e)d("'"..e.."' expected")end
local function t(l)if n==l then e()return true end
end
local function q(e)if n~=e then p(e)end
end
local function a(n)q(n)e()end
local function Y(e,n)if not e then d(n)end
end
local function f(e,l,n)if not t(e)then
if n==c then
p(e)else
d("'"..e.."' expected (to close '"..l.."' at line "..n..")")end
end
end
local function p()q"<name>"local n=A
b=h
e()return n
end
local function D(e,n)e.k="VK"end
local function U(e)D(e,p())end
local function T(t,l)local e=o.bl
local n
if e then
n=e.locallist
else
n=o.locallist
end
local e=#s+1
s[e]={name=t,xref={b},decl=b,}if l then
s[e].isself=true
end
local l=#E+1
E[l]=e
R[l]=n
end
local function S(e)local n=#E
while e>0 do
e=e-1
local e=n-e
local l=E[e]local n=s[l]local o=n.name
n.act=h
E[e]=nil
local t=R[e]R[e]=nil
local e=t[o]if e then
n=s[e]n.rem=-l
end
t[o]=l
end
end
local function G()local n=o.bl
local e
if n then
e=n.locallist
else
e=o.locallist
end
for n,e in l.pairs(e)do
local e=s[e]e.rem=h
end
end
local function h(e,n)if L.sub(e,1,1)=="("then
return
end
T(e,n)end
local function W(o,l)local n=o.bl
local e
if n then
e=n.locallist
while e do
if e[l]then return e[l]end
n=n.prev
e=n and n.locallist
end
end
e=o.locallist
return e[l]or-1
end
local function L(n,l,e)if n==nil then
e.k="VGLOBAL"return"VGLOBAL"else
local o=W(n,l)if o>=0 then
e.k="VLOCAL"e.id=o
return"VLOCAL"else
if L(n.prev,l,e)=="VGLOBAL"then
return"VGLOBAL"end
e.k="VUPVAL"return"VUPVAL"end
end
end
local function J(l)local n=p()L(o,n,l)if l.k=="VGLOBAL"then
local e=P[n]if not e then
e=#N+1
N[e]={name=n,xref={b},}P[n]=e
else
local e=N[e].xref
e[#e+1]=b
end
else
local e=l.id
local e=s[e].xref
e[#e+1]=b
end
end
local function b(n)local e={}e.isbreakable=n
e.prev=o.bl
e.locallist={}o.bl=e
end
local function L()local e=o.bl
G()o.bl=e.prev
end
local function X()local e
if not o then
e=z
else
e={}end
e.prev=o
e.bl=nil
e.locallist={}o=e
end
local function Q()G()o=o.prev
end
local function G(l)local n={}e()U(n)l.k="VINDEXED"end
local function W(n)e()u(n)a"]"end
local function l(e)local e,l={},{}if n=="<name>"then
U(e)else
W(e)end
a"="u(l)end
local function F(e)if e.v.k=="VVOID"then return end
e.v.k="VVOID"end
local function H(e)u(e.v)end
local function F(o)local i=c
local e={}e.v={}e.t=o
o.k="VRELOCABLE"e.v.k="VVOID"a"{"repeat
if n=="}"then break end
local n=n
if n=="<name>"then
if j()~="="then
H(e)else
l(e)end
elseif n=="["then
l(e)else
H(e)end
until not t(",")and not t(";")f("}","{",i)end
local function j()local l=0
if n~=")"then
repeat
local n=n
if n=="<name>"then
T(p())l=l+1
elseif n=="..."then
e()o.is_vararg=true
else
d"<name> or '...' expected"end
until o.is_vararg or not t(",")end
S(l)end
local function H(a)local l={}local t=c
local o=n
if o=="("then
if t~=V then
d"ambiguous syntax (function call x new statement)"end
e()if n==")"then
l.k="VVOID"else
m(l)end
f(")","(",t)elseif o=="{"then
F(l)elseif o=="<string>"then
D(l,A)e()else
d"function arguments expected"return
end
a.k="VCALL"end
local function ne(l)local n=n
if n=="("then
local n=c
e()u(l)f(")","(",n)elseif n=="<name>"then
J(l)else
d"unexpected symbol"end
end
local function V(l)ne(l)while true do
local n=n
if n=="."then
G(l)elseif n=="["then
local e={}W(e)elseif n==":"then
local n={}e()U(n)H(l)elseif n=="("or n=="<string>"or n=="{"then
H(l)else
return
end
end
end
local function U(l)local n=n
if n=="<number>"then
l.k="VKNUM"elseif n=="<string>"then
D(l,A)elseif n=="nil"then
l.k="VNIL"elseif n=="true"then
l.k="VTRUE"elseif n=="false"then
l.k="VFALSE"elseif n=="..."then
Y(o.is_vararg==true,"cannot use '...' outside a vararg function")l.k="VVARARG"elseif n=="{"then
F(l)return
elseif n=="function"then
e()x(l,false,c)return
else
V(l)return
end
e()end
local function A(o,t)local l=n
local a=ee[l]if a then
e()A(o,Z)else
U(o)end
l=n
local n=M[l]while n and n>t do
local o={}e()local e=A(o,B[l])l=e
n=M[l]end
return l
end
function u(e)A(e,0)end
local function A(e)local n={}local e=e.v.k
Y(e=="VLOCAL"or e=="VUPVAL"or e=="VGLOBAL"or e=="VINDEXED","syntax error")if t(",")then
local e={}e.v={}V(e.v)A(e)else
a"="m(n)return
end
n.k="VNONRELOC"end
local function l(e,n)a"do"b(false)S(e)O()L()end
local function U(e)local n=r
h"(for index)"h"(for limit)"h"(for step)"T(e)a"="w()a","w()if t(",")then
w()else
end
l(1,true)end
local function M(e)local n={}h"(for generator)"h"(for state)"h"(for control)"T(e)local e=1
while t(",")do
T(p())e=e+1
end
a"in"local o=r
m(n)l(e,false)end
local function D(e)local l=false
J(e)while n=="."do
G(e)end
if n==":"then
l=true
G(e)end
return l
end
function w()local e={}u(e)end
local function l()local e={}u(e)end
local function w()e()l()a"then"O()end
local function B()local n,e={}T(p())n.k="VLOCAL"S(1)x(e,false,c)end
local function G()local e=0
local n={}repeat
T(p())e=e+1
until not t(",")if t("=")then
m(n)else
n.k="VVOID"end
S(e)end
function m(e)u(e)while t(",")do
u(e)end
end
function x(l,n,e)X()a"("if n then
h("self",true)S(1)end
j()a")"I()f("end","function",e)Q()end
function O()b(false)I()L()end
local function S()local o=r
b(true)e()local l=p()local e=n
if e=="="then
U(l)elseif e==","or e=="in"then
M(l)else
d"'=' or 'in' expected"end
f("end","for",o)L()end
local function p()local n=r
e()l()b(true)a"do"O()f("end","while",n)L()end
local function h()local n=r
b(true)b(false)e()I()f("until","repeat",n)l()L()L()end
local function u()local l=r
local o={}w()while n=="elseif"do
w()end
if n=="else"then
e()O()end
f("end","if",l)end
local function T()local l={}e()local e=n
if C[e]or e==";"then
else
m(l)end
end
local function b()local n=o.bl
e()while n and not n.isbreakable do
n=n.prev
end
if not n then
d"no loop to break"end
end
local function m()local n=i-1
local e={}e.v={}V(e.v)if e.v.k=="VCALL"then
v[n]="call"else
e.prev=nil
A(e)v[n]="assign"end
end
local function d()local o=r
local n,l={},{}e()local e=D(n)x(l,e,o)end
local function l()local n=r
e()O()f("end","do",n)end
local function a()e()if t("function")then
B()else
G()end
end
local l={["if"]=u,["while"]=p,["do"]=l,["for"]=S,["repeat"]=h,["function"]=d,["local"]=a,["return"]=T,["break"]=b,}local function a()r=c
local e=n
local n=l[e]if n then
v[i-1]=e
n()if e=="return"or e=="break"then return true end
else
m()end
return false
end
function I()local e=false
while not e and not C[n]do
e=a()t";"end
end
function parser()X()o.is_vararg=true
e()I()q"<eof>"Q()return{globalinfo=N,localinfo=s,statinfo=v,toklist=k,seminfolist=K,toklnlist=g,xreflist=y,}end
function init(e,t,a)i=1
z={}local n=1
k,K,g,y={},{},{},{}for l=1,#e do
local e=e[l]local o=true
if e=="TK_KEYWORD"or e=="TK_OP"then
e=t[l]elseif e=="TK_NAME"then
e="<name>"K[n]=t[l]elseif e=="TK_NUMBER"then
e="<number>"K[n]=0
elseif e=="TK_STRING"or e=="TK_LSTRING"then
e="<string>"K[n]=""elseif e=="TK_EOS"then
e="<eof>"else
o=false
end
if o then
k[n]=e
g[n]=a[l]y[n]=l
n=n+1
end
end
N,P,s={},{},{}E,R={},{}v={}end
end
_.optlex=function()module"optlex"local h=l.require"string"local t=h.match
local e=h.sub
local d=h.find
local s=h.rep
local u
error=l.error
warn={}local a,o,f
local b={TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,TK_STRING=true,TK_LSTRING=true,TK_OP=true,TK_EOS=true,}local K={TK_COMMENT=true,TK_LCOMMENT=true,TK_EOL=true,TK_SPACE=true,}local c
local function E(e)local n=a[e-1]if e<=1 or n=="TK_EOL"then
return true
elseif n==""then
return E(e-1)end
return false
end
local function L(n)local e=a[n+1]if n>=#a or e=="TK_EOL"or e=="TK_EOS"then
return true
elseif e==""then
return L(n+1)end
return false
end
local function A(n)local l=#t(n,"^%-%-%[=*%[")local l=e(n,l+1,-(l-1))local e,n=1,0
while true do
local o,a,t,l=d(l,"([\r\n])([\r\n]?)",e)if not o then break end
e=o+1
n=n+1
if#l>0 and t~=l then
e=e+1
end
end
return n
end
local function m(i,r)local l=t
local n,e=a[i],a[r]if n=="TK_STRING"or n=="TK_LSTRING"or
e=="TK_STRING"or e=="TK_LSTRING"then
return""elseif n=="TK_OP"or e=="TK_OP"then
if(n=="TK_OP"and(e=="TK_KEYWORD"or e=="TK_NAME"))or(e=="TK_OP"and(n=="TK_KEYWORD"or n=="TK_NAME"))then
return""end
if n=="TK_OP"and e=="TK_OP"then
local n,e=o[i],o[r]if(l(n,"^%.%.?$")and l(e,"^%."))or(l(n,"^[~=<>]$")and e=="=")or(n=="["and(e=="["or e=="="))then
return" "end
return""end
local n=o[i]if e=="TK_OP"then n=o[r]end
if l(n,"^%.%.?%.?$")then
return" "end
return""else
return" "end
end
local function T()local l,i,t={},{},{}local e=1
for n=1,#a do
local a=a[n]if a~=""then
l[e],i[e],t[e]=a,o[n],f[n]e=e+1
end
end
a,o,f=l,i,t
end
local function I(r)local n=o[r]local n=n
local a
if t(n,"^0[xX]")then
local e=l.tostring(l.tonumber(n))if#e<=#n then
n=e
else
return
end
end
if t(n,"^%d+%.?0*$")then
n=t(n,"^(%d+)%.?0*$")if n+0>0 then
n=t(n,"^0*([1-9]%d*)$")local o=#t(n,"0*$")local l=l.tostring(o)if o>#l+1 then
n=e(n,1,#n-o).."e"..l
end
a=n
else
a="0"end
elseif not t(n,"[eE]")then
local o,n=t(n,"^(%d*)%.(%d+)$")if o==""then o=0 end
if n+0==0 and o==0 then
a="0"else
local i=#t(n,"0*$")if i>0 then
n=e(n,1,#n-i)end
if o+0>0 then
a=o.."."..n
else
a="."..n
local o=#t(n,"^0*")local o=#n-o
local l=l.tostring(#n)if o+2+#l<1+#n then
a=e(n,-o).."e-"..l
end
end
end
else
local n,o=t(n,"^([^eE]+)[eE]([%+%-]?%d+)$")o=l.tonumber(o)local r,i=t(n,"^(%d*)%.(%d*)$")if r then
o=o-#i
n=r..i
end
if n+0==0 then
a="0"else
local i=#t(n,"^0*")n=e(n,i+1)i=#t(n,"0*$")if i>0 then
n=e(n,1,#n-i)o=o+i
end
local l=l.tostring(o)if o==0 then
a=n
elseif o>0 and(o<=1+#l)then
a=n..s("0",o)elseif o<0 and(o>=-#n)then
i=#n+o
a=e(n,1,i).."."..e(n,i+1)elseif o<0 and(#l>=-o-#n)then
i=-o-#n
a="."..s("0",i)..n
else
a=n.."e"..o
end
end
end
if a and a~=o[r]then
if c then
u("<number> (line "..f[r]..") "..o[r].." -> "..a)c=c+1
end
o[r]=a
end
end
local function N(s)local n=o[s]local i=e(n,1,1)local T=(i=="'")and'"'or"'"local n=e(n,2,-2)local l=1
local p,r=0,0
while l<=#n do
local s=e(n,l,l)if s=="\\"then
local o=l+1
local c=e(n,o,o)local a=d("abfnrtv\\\n\r\"'0123456789",c,1,true)if not a then
n=e(n,1,l-1)..e(n,o)l=l+1
elseif a<=8 then
l=l+2
elseif a<=10 then
local t=e(n,o,o+1)if t=="\r\n"or t=="\n\r"then
n=e(n,1,l).."\n"..e(n,o+2)elseif a==10 then
n=e(n,1,l).."\n"..e(n,o+1)end
l=l+2
elseif a<=12 then
if c==i then
p=p+1
l=l+2
else
r=r+1
n=e(n,1,l-1)..e(n,o)l=l+1
end
else
local a=t(n,"^(%d%d?%d?)",o)o=l+1+#a
local f=a+0
local c=h.char(f)local d=d("\a\b\f\n\r\t\v",c,1,true)if d then
a="\\"..e("abfnrtv",d,d)elseif f<32 then
if t(e(n,o,o),"%d")then
a="\\"..a
else
a="\\"..f
end
elseif c==i then
a="\\"..c
p=p+1
elseif c=="\\"then
a="\\\\"else
a=c
if c==T then
r=r+1
end
end
n=e(n,1,l-1)..a..e(n,o)l=l+#a
end
else
l=l+1
if s==T then
r=r+1
end
end
end
if p>r then
l=1
while l<=#n do
local o,a,t=d(n,"(['\"])",l)if not o then break end
if t==i then
n=e(n,1,o-2)..e(n,o)l=o
else
n=e(n,1,o-1).."\\"..e(n,o)l=o+2
end
end
i=T
end
n=i..n..i
if n~=o[s]then
if c then
u("<string> (line "..f[s]..") "..o[s].." -> "..n)c=c+1
end
o[s]=n
end
end
local function v(i)local n=o[i]local c=t(n,"^%[=*%[")local l=#c
local u=e(n,-l,-1)local r=e(n,l+1,-(l+1))local a=""local n=1
while true do
local l,o,d,c=d(r,"([\r\n])([\r\n]?)",n)local o
if not l then
o=e(r,n)elseif l>=n then
o=e(r,n,l-1)end
if o~=""then
if t(o,"%s+$")then
warn.LSTRING="trailing whitespace in long string near line "..f[i]end
a=a..o
end
if not l then
break
end
n=l+1
if l then
if#c>0 and d~=c then
n=n+1
end
if not(n==1 and n==l)then
a=a.."\n"end
end
end
if l>=3 then
local e,n=l-1
while e>=2 do
local l="%]"..s("=",e-2).."%]"if not t(a,l)then n=e end
e=e-1
end
if n then
l=s("=",n-2)c,u="["..l.."[","]"..l.."]"end
end
o[i]=c..a..u
end
local function O(c)local l=o[c]local i=t(l,"^%-%-%[=*%[")local n=#i
local f=e(l,-n,-1)local r=e(l,n+1,-(n-1))local a=""local l=1
while true do
local o,n,c,i=d(r,"([\r\n])([\r\n]?)",l)local n
if not o then
n=e(r,l)elseif o>=l then
n=e(r,l,o-1)end
if n~=""then
local l=t(n,"%s*$")if#l>0 then n=e(n,1,-(l+1))end
a=a..n
end
if not o then
break
end
l=o+1
if o then
if#i>0 and c~=i then
l=l+1
end
a=a.."\n"end
end
n=n-2
if n>=3 then
local e,l=n-1
while e>=2 do
local n="%]"..s("=",e-2).."%]"if not t(a,n)then l=e end
e=e-1
end
if l then
n=s("=",l-2)i,f="--["..n.."[","]"..n.."]"end
end
o[c]=i..a..f
end
local function g(a)local n=o[a]local l=t(n,"%s*$")if#l>0 then
n=e(n,1,-(l+1))end
o[a]=n
end
local function R(o,n)if not o then return false end
local l=t(n,"^%-%-%[=*%[")local l=#l
local t=e(n,-l,-1)local e=e(n,l+1,-(l-1))if d(e,o,1,true)then
return true
end
end
function optimize(n,r,i,t)local h=n["opt-comments"]local d=n["opt-whitespace"]local p=n["opt-emptylines"]local k=n["opt-eols"]local S=n["opt-strings"]local w=n["opt-numbers"]local _=n["opt-experimental"]local x=n.KEEP
c=n.DETAILS and 0
u=u or l.print
if k then
h=true
d=true
p=true
elseif _ then
d=true
end
a,o,f=r,i,t
local n=1
local l,r
local i
local function t(t,l,e)e=e or n
a[e]=t or""o[e]=l or""end
if _ then
while true do
l,r=a[n],o[n]if l=="TK_EOS"then
break
elseif l=="TK_OP"and r==";"then
t("TK_SPACE"," ")end
n=n+1
end
T()end
n=1
while true do
l,r=a[n],o[n]local c=E(n)if c then i=nil end
if l=="TK_EOS"then
break
elseif l=="TK_KEYWORD"or
l=="TK_NAME"or
l=="TK_OP"then
i=n
elseif l=="TK_NUMBER"then
if w then
I(n)end
i=n
elseif l=="TK_STRING"or
l=="TK_LSTRING"then
if S then
if l=="TK_STRING"then
N(n)else
v(n)end
end
i=n
elseif l=="TK_COMMENT"then
if h then
if n==1 and e(r,1,1)=="#"then
g(n)else
t()end
elseif d then
g(n)end
elseif l=="TK_LCOMMENT"then
if R(x,r)then
if d then
O(n)end
i=n
elseif h then
local e=A(r)if K[a[n+1]]then
t()l=""else
t("TK_SPACE"," ")end
if not p and e>0 then
t("TK_EOL",s("\n",e))end
if d and l~=""then
n=n-1
end
else
if d then
O(n)end
i=n
end
elseif l=="TK_EOL"then
if c and p then
t()elseif r=="\r\n"or r=="\n\r"then
t("TK_EOL","\n")end
elseif l=="TK_SPACE"then
if d then
if c or L(n)then
t()else
local l=a[i]if l=="TK_LCOMMENT"then
t()else
local e=a[n+1]if K[e]then
if(e=="TK_COMMENT"or e=="TK_LCOMMENT")and
l=="TK_OP"and o[i]=="-"then
else
t()end
else
local e=m(i,n+1)if e==""then
t()else
t("TK_SPACE"," ")end
end
end
end
end
else
error"unidentified token encountered"end
n=n+1
end
T()if k then
n=1
if a[1]=="TK_COMMENT"then
n=3
end
while true do
l,r=a[n],o[n]if l=="TK_EOS"then
break
elseif l=="TK_EOL"then
local l,e=a[n-1],a[n+1]if b[l]and b[e]then
local n=m(n-1,n+1)if n==""or e=="TK_EOS"then
t()end
end
end
n=n+1
end
T()end
if c and c>0 then u()end
return a,o,f
end
end
_.optparser=function()module"optparser"local i=l.require"string"local K=l.require"table"local t="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"local c="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"local A={}for e in i.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]],"%S+")do
A[e]=true
end
local r,u,a,L,m,g,o,T,O,v,E,f
local function I(e)local o={}for a=1,#e do
local e=e[a]local t=e.name
if not o[t]then
o[t]={decl=0,token=0,size=0,}end
local n=o[t]n.decl=n.decl+1
local o=e.xref
local l=#o
n.token=n.token+l
n.size=n.size+l*#t
if e.decl then
e.id=a
e.xcount=l
if l>1 then
e.first=o[2]e.last=o[l]end
else
n.id=a
end
end
return o
end
local function w(e)local d=i.byte
local i=i.char
local n={TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,TK_STRING=true,TK_LSTRING=true,}if not e["opt-comments"]then
n.TK_COMMENT=true
n.TK_LCOMMENT=true
end
local l={}for e=1,#r do
l[e]=u[e]end
for e=1,#o do
local e=o[e]local n=e.xref
for e=1,e.xcount do
local e=n[e]l[e]=""end
end
local e={}for n=0,255 do e[n]=0 end
for o=1,#r do
local o,l=r[o],l[o]if n[o]then
for n=1,#l do
local n=d(l,n)e[n]=e[n]+1
end
end
end
local function a(o)local n={}for l=1,#o do
local o=d(o,l)n[l]={c=o,freq=e[o],}end
K.sort(n,function(n,e)return n.freq>e.freq
end)local e={}for l=1,#n do
e[l]=i(n[l].c)end
return K.concat(e)end
t=a(t)c=a(c)end
local function x()local n
local a,r=#t,#c
local e=E
if e<a then
e=e+1
n=i.sub(t,e,e)else
local o,l=a,1
repeat
e=e-o
o=o*r
l=l+1
until o>e
local o=e%a
e=(e-o)/a
o=o+1
n=i.sub(t,o,o)while l>1 do
local o=e%r
e=(e-o)/r
o=o+1
n=n..i.sub(c,o,o)l=l-1
end
end
E=E+1
return n,O[n]~=nil
end
local function R(v,w,S,t)local e=b or l.print
local n=i.format
local x=t.DETAILS
if t.QUIET then return end
local h,T,m,A,I,O,b,p,N,g,r,u,s,L,k,a,d,c,_,E=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
local function t(e,n)if e==0 then return 0 end
return n/e
end
for n,e in l.pairs(v)do
h=h+1
r=r+e.token
a=a+e.size
end
for n,e in l.pairs(w)do
T=T+1
b=b+e.decl
u=u+e.token
d=d+e.size
end
for n,e in l.pairs(S)do
m=m+1
p=p+e.decl
s=s+e.token
c=c+e.size
end
A=h+T
N=O+b
L=r+u
_=a+d
I=h+m
g=O+p
k=r+s
E=a+c
if x then
local h={}for n,e in l.pairs(v)do
e.name=n
h[#h+1]=e
end
K.sort(h,function(e,n)return e.size>n.size
end)local l,m="%8s%8s%10s  %s","%8d%8d%10.2f  %s"local T=i.rep("-",44)e("*** global variable list (sorted by size) ***\n"..T)e(n(l,"Token","Input","Input","Global"))e(n(l,"Count","Bytes","Average","Name"))e(T)for l=1,#h do
local l=h[l]e(n(m,l.token,l.size,t(l.token,l.size),l.name))end
e(T)e(n(m,r,a,t(r,a),"TOTAL"))e(T.."\n")local l,h="%8s%8s%8s%10s%8s%10s  %s","%8d%8d%8d%10.2f%8d%10.2f  %s"local i=i.rep("-",70)e("*** local variable list (sorted by allocation order) ***\n"..i)e(n(l,"Decl.","Token","Input","Input","Output","Output","Global"))e(n(l,"Count","Count","Bytes","Average","Bytes","Average","Name"))e(i)for l=1,#f do
local i=f[l]local l=S[i]local r,a=0,0
for n=1,#o do
local e=o[n]if e.name==i then
r=r+e.xcount
a=a+e.xcount*#e.oldname
end
end
e(n(h,l.decl,l.token,a,t(r,a),l.size,t(l.token,l.size),i))end
e(i)e(n(h,p,s,d,t(u,d),c,t(s,c),"TOTAL"))e(i.."\n")end
local f,o="%-16s%8s%8s%8s%8s%10s","%-16s%8d%8d%8d%8d%10.2f"local l=i.rep("-",58)e("*** local variable optimization summary ***\n"..l)e(n(f,"Variable","Unique","Decl.","Token","Size","Average"))e(n(f,"Types","Names","Count","Count","Bytes","Bytes"))e(l)e(n(o,"Global",h,O,r,a,t(r,a)))e(l)e(n(o,"Local (in)",T,b,u,d,t(u,d)))e(n(o,"TOTAL (in)",A,N,L,_,t(L,_)))e(l)e(n(o,"Local (out)",m,p,s,c,t(s,c)))e(n(o,"TOTAL (out)",I,g,k,E,t(k,E)))e(l.."\n")end
local function t(e)if e<1 or e>=#a then
return
end
local o=m[e]local n,l=#a,#r
for e=e+1,n do
a[e-1]=a[e]L[e-1]=L[e]m[e-1]=m[e]-1
T[e-1]=T[e]end
a[n]=nil
L[n]=nil
m[n]=nil
T[n]=nil
for e=o+1,l do
r[e-1]=r[e]u[e-1]=u[e]end
r[l]=nil
u[l]=nil
end
local function d()local function o(e)local n=a[e+1]or""local l=a[e+2]or""local e=a[e+3]or""if n=="("and l=="<string>"and e==")"then
return true
end
end
local n=1
while true do
local e,l=n,false
while e<=#a do
local a=T[e]if a=="call"and o(e)then
t(e+1)t(e+2)l=true
n=e+2
end
e=e+1
end
if not l then break end
end
end
local function s(r)E=0
f={}O=I(g)v=I(o)if r["opt-entropy"]then
w(r)end
local e={}for n=1,#o do
e[n]=o[n]end
K.sort(e,function(n,e)return n.xcount>e.xcount
end)local l,n,c={},1,false
for o=1,#e do
local e=e[o]if not e.isself then
l[n]=e
n=n+1
else
c=true
end
end
e=l
local i=#e
while i>0 do
local a,n
repeat
a,n=x()until not A[a]f[#f+1]=a
local l=i
if n then
local t=g[O[a].id].xref
local a=#t
for n=1,i do
local n=e[n]local i,e=n.act,n.rem
while e<0 do
e=o[-e].rem
end
local o
for n=1,a do
local n=t[n]if n>=i and n<=e then o=true end
end
if o then
n.skip=true
l=l-1
end
end
end
while l>0 do
local n=1
while e[n].skip do
n=n+1
end
l=l-1
local t=e[n]n=n+1
t.newname=a
t.skip=true
t.done=true
local i,c=t.first,t.last
local r=t.xref
if i and l>0 then
local a=l
while a>0 do
while e[n].skip do
n=n+1
end
a=a-1
local e=e[n]n=n+1
local a,n=e.act,e.rem
while n<0 do
n=o[-n].rem
end
if not(c<a or i>n)then
if a>=t.act then
for o=1,t.xcount do
local o=r[o]if o>=a and o<=n then
l=l-1
e.skip=true
break
end
end
else
if e.last and e.last>=t.act then
l=l-1
e.skip=true
end
end
end
if l==0 then break end
end
end
end
local l,n={},1
for o=1,i do
local e=e[o]if not e.done then
e.skip=false
l[n]=e
n=n+1
end
end
e=l
i=#e
end
for e=1,#o do
local e=o[e]local l=e.xref
if e.newname then
for n=1,e.xcount do
local n=l[n]u[n]=e.newname
end
e.name,e.oldname=e.newname,e.name
else
e.oldname=e.name
end
end
if c then
f[#f+1]="self"end
local e=I(o)R(O,v,e,r)end
function optimize(n,t,l,e)r,u=t,l
a,L,m=e.toklist,e.seminfolist,e.xreflist
g,o,T=e.globalinfo,e.localinfo,e.statinfo
if n["opt-locals"]then
s(n)end
if n["opt-experimental"]then
d()end
end
end
_.equiv=function()module"equiv"local e=l.require"string"local c=l.loadstring
local s=e.sub
local d=e.match
local i=e.dump
local b=e.byte
local f={TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,TK_STRING=true,TK_LSTRING=true,TK_OP=true,TK_EOS=true,}local t,e,r
function init(o,n,l)t=o
e=n
r=l
end
local function a(n)e.init(n)e.llex()local l,t=e.tok,e.seminfo
local e,n={},{}for o=1,#l do
local l=l[o]if f[l]then
e[#e+1]=l
n[#n+1]=t[o]end
end
return e,n
end
function source(n,f)local function s(e)local e=c("return "..e,"z")if e then
return i(e)end
end
local function o(e)if t.DETAILS then l.print("SRCEQUIV: "..e)end
r.SRC_EQUIV=true
end
local e,c=a(n)local l,r=a(f)local a=d(n,"^(#[^\r\n]*)")local n=d(f,"^(#[^\r\n]*)")if a or n then
if not a or not n or a~=n then
o"shbang lines different"end
end
if#e~=#l then
o("count "..#e.." "..#l)return
end
for n=1,#e do
local e,i=e[n],l[n]local l,a=c[n],r[n]if e~=i then
o("type ["..n.."] "..e.." "..i)break
end
if e=="TK_KEYWORD"or e=="TK_NAME"or e=="TK_OP"then
if e=="TK_NAME"and t["opt-locals"]then
elseif l~=a then
o("seminfo ["..n.."] "..e.." "..l.." "..a)break
end
elseif e=="TK_EOS"then
else
local t,i=s(l),s(a)if not t or not i or t~=i then
o("seminfo ["..n.."] "..e.." "..l.." "..a)break
end
end
end
end
function binary(a,o)local e=0
local O=1
local L=3
local k=4
local function e(e)if t.DETAILS then l.print("BINEQUIV: "..e)end
r.BIN_EQUIV=true
end
local function l(e)local n=d(e,"^(#[^\r\n]*\r?\n?)")if n then
e=s(e,#n+1)end
return e
end
local n=c(l(a),"z")if not n then
e"failed to compile original sources for binary chunk comparison"return
end
local l=c(l(o),"z")if not l then
e"failed to compile compressed result for binary chunk comparison"end
local t={i=1,dat=i(n)}t.len=#t.dat
local f={i=1,dat=i(l)}f.len=#f.dat
local K,d,u,m,T,o,h
local function i(e,n)if e.i+n-1>e.len then return end
return true
end
local function p(n,e)if not e then e=1 end
n.i=n.i+e
end
local function a(n)local e=n.i
if e>n.len then return end
local l=s(n.dat,e,e)n.i=e+1
return b(l)end
local function g(l)local e,n=0,1
if not i(l,d)then return end
for o=1,d do
e=e+n*a(l)n=n*256
end
return e
end
local function I(n)local e=0
if not i(n,d)then return end
for l=1,d do
e=e*256+a(n)end
return e
end
local function v(l)local n,e=0,1
if not i(l,u)then return end
for o=1,u do
n=n+e*a(l)e=e*256
end
return n
end
local function N(n)local e=0
if not i(n,u)then return end
for l=1,u do
e=e*256+a(n)end
return e
end
local function c(e,o)local n=e.i
local l=n+o-1
if l>e.len then return end
local l=s(e.dat,n,l)e.i=n+o
return l
end
local function r(n)local e=h(n)if not e then return end
if e==0 then return""end
return c(n,e)end
local function _(n,e)local e,n=a(n),a(e)if not e or not n or e~=n then
return
end
return e
end
local function s(e,n)local e=_(e,n)if not e then return true end
end
local function b(n,e)local e,n=o(n),o(e)if not e or not n or e~=n then
return
end
return e
end
local function E(n,l)if not r(n)or not r(l)then
e"bad source name"return
end
if not o(n)or not o(l)then
e"bad linedefined"return
end
if not o(n)or not o(l)then
e"bad lastlinedefined"return
end
if not(i(n,4)and i(l,4))then
e"prototype header broken"end
if s(n,l)then
e"bad nups"return
end
if s(n,l)then
e"bad numparams"return
end
if s(n,l)then
e"bad is_vararg"return
end
if s(n,l)then
e"bad maxstacksize"return
end
local t=b(n,l)if not t then
e"bad ncode"return
end
local a=c(n,t*m)local t=c(l,t*m)if not a or not t or a~=t then
e"bad code block"return
end
local t=b(n,l)if not t then
e"bad nconst"return
end
for o=1,t do
local o=_(n,l)if not o then
e"bad const type"return
end
if o==O then
if s(n,l)then
e"bad boolean value"return
end
elseif o==L then
local n=c(n,T)local l=c(l,T)if not n or not l or n~=l then
e"bad number value"return
end
elseif o==k then
local n=r(n)local l=r(l)if not n or not l or n~=l then
e"bad string value"return
end
end
end
local t=b(n,l)if not t then
e"bad nproto"return
end
for o=1,t do
if not E(n,l)then
e"bad function prototype"return
end
end
local t=o(n)if not t then
e"bad sizelineinfo1"return
end
local a=o(l)if not a then
e"bad sizelineinfo2"return
end
if not c(n,t*d)then
e"bad lineinfo1"return
end
if not c(l,a*d)then
e"bad lineinfo2"return
end
local t=o(n)if not t then
e"bad sizelocvars1"return
end
local a=o(l)if not a then
e"bad sizelocvars2"return
end
for l=1,t do
if not r(n)or not o(n)or not o(n)then
e"bad locvars1"return
end
end
for n=1,a do
if not r(l)or not o(l)or not o(l)then
e"bad locvars2"return
end
end
local t=o(n)if not t then
e"bad sizeupvalues1"return
end
local o=o(l)if not o then
e"bad sizeupvalues2"return
end
for l=1,t do
if not r(n)then e"bad upvalues1"return end
end
for n=1,o do
if not r(l)then e"bad upvalues2"return end
end
return true
end
if not(i(t,12)and i(f,12))then
e"header broken"end
p(t,6)K=a(t)d=a(t)u=a(t)m=a(t)T=a(t)p(t)p(f,12)if K==1 then
o=g
h=v
else
o=I
h=N
end
E(t,f)if t.i~=t.len+1 then
e"inconsistent binary chunk1"return
elseif f.i~=f.len+1 then
e"inconsistent binary chunk2"return
end
end
end
_["plugin/html"]=function()module"plugin/html"local n=l.require"string"local h=l.require"table"local c=l.require"io"local r=".html"local f={["&"]="&amp;",["<"]="&lt;",[">"]="&gt;",["'"]="&apos;",['"']="&quot;",}local p=[[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>%s</title>
<meta name="Generator" content="LuaSrcDiet">
<style type="text/css">
%s</style>
</head>
<body>
<pre class="code">
]]local m=[[
</pre>
</body>
</html>
]]local T=[[
BODY {
    background: white;
    color: navy;
}
pre.code { color: black; }
span.comment { color: #00a000; }
span.string  { color: #009090; }
span.keyword { color: black; font-weight: bold; }
span.number { color: #993399; }
span.operator { }
span.name { }
span.global { color: #ff0000; font-weight: bold; }
span.local { color: #0000ff; font-weight: bold; }
]]local t
local e,a
local o,d,s
local function i(...)if t.QUIET then return end
l.print(...)end
function init(o,i,c)t=o
e=i
local o,d=n.find(e,"%.[^%.%\\%/]*$")local i,c=e,""if o and o>1 then
i=n.sub(e,1,o-1)c=n.sub(e,o,d)end
a=i..r
if t.OUTPUT_FILE then
a=t.OUTPUT_FILE
end
if e==a then
l.error("output filename identical to input filename")end
end
function post_load(n)i[[
HTML plugin module for LuaSrcDiet
]]i("Exporting: "..e.." -> "..a.."\n")end
function post_lex(e,l,n)o,d,s=e,l,n
end
local function r(l)local e=1
while e<=#l do
local o=n.sub(l,e,e)local t=f[o]if t then
o=t
l=n.sub(l,1,e-1)..o..n.sub(l,e+1)end
e=e+#o
end
return l
end
local function u(n,o)local e=c.open(n,"wb")if not e then l.error('cannot open "'..n..'" for writing')end
local o=e:write(o)if not o then l.error('cannot write to "'..n..'"')end
e:close()end
function post_parse(s,f)local c={}local function i(e)c[#c+1]=e
end
local function l(e,n)i('<span class="'..e..'">'..n..'</span>')end
for e=1,#s do
local e=s[e]local e=e.xref
for n=1,#e do
local e=e[n]o[e]="TK_GLOBAL"end
end
for e=1,#f do
local e=f[e]local e=e.xref
for n=1,#e do
local e=e[n]o[e]="TK_LOCAL"end
end
i(n.format(p,r(e),T))for e=1,#o do
local e,n=o[e],d[e]if e=="TK_KEYWORD"then
l("keyword",n)elseif e=="TK_STRING"or e=="TK_LSTRING"then
l("string",r(n))elseif e=="TK_COMMENT"or e=="TK_LCOMMENT"then
l("comment",r(n))elseif e=="TK_GLOBAL"then
l("global",n)elseif e=="TK_LOCAL"then
l("local",n)elseif e=="TK_NAME"then
l("name",n)elseif e=="TK_NUMBER"then
l("number",n)elseif e=="TK_OP"then
l("operator",r(n))elseif e~="TK_EOS"then
i(n)end
end
i(m)u(a,h.concat(c))t.EXIT=true
end
end
_["plugin/sloc"]=function()module"plugin/sloc"local a=l.require"string"local e=l.require"table"local o
local i
function init(n,e,l)o=n
o.QUIET=true
i=e
end
local function r(o)local l={}local n,t=1,#o
while n<=t do
local e,i,c,r=a.find(o,"([\r\n])([\r\n]?)",n)if not e then
e=t+1
end
l[#l+1]=a.sub(o,n,e-1)n=e+1
if e<t and i>e and c~=r then
n=n+1
end
end
return l
end
function post_lex(n,d,c)local e,a=0,0
local function t(n)if n>e then
a=a+1 e=n
end
end
for e=1,#n do
local n,l,e=n[e],d[e],c[e]if n=="TK_KEYWORD"or n=="TK_NAME"or
n=="TK_NUMBER"or n=="TK_OP"then
t(e)elseif n=="TK_STRING"then
local n=r(l)e=e-#n+1
for n=1,#n do
t(e)e=e+1
end
elseif n=="TK_LSTRING"then
local n=r(l)e=e-#n+1
for l=1,#n do
if n[l]~=""then t(e)end
e=e+1
end
end
end
l.print(i..": "..a)o.EXIT=true
end
end
local o=K"llex"local f=K"lparser"local g=K"optlex"local A=K"optparser"local k=K"equiv"local l
local _=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.12.0 (20110913)  Copyright (c) 2005-2008,2011 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]local p=[[
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
%s]]local E=[[
--opt-comments,'remove comments and block comments'
--opt-whitespace,'remove whitespace excluding EOLs'
--opt-emptylines,'remove empty lines'
--opt-eols,'all above, plus remove unnecessary EOLs'
--opt-strings,'optimize strings and long strings'
--opt-numbers,'optimize numbers'
--opt-locals,'optimize local variable names'
--opt-entropy,'tries to reduce symbol entropy of locals'
--opt-srcequiv,'insist on source (lexer stream) equivalence'
--opt-binequiv,'insist on binary chunk equivalence'
--opt-experimental,'apply experimental optimizations'
]]local v=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
  --opt-srcequiv --opt-binequiv
]]local R=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]local w=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
  --opt-srcequiv --opt-binequiv
]]local S=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]local a="_"local x="plugin/"local function t(e)b("LuaSrcDiet (error): "..e)os.exit(1)end
if not j(_VERSION,"5.1",1,1)then
t"requires Lua 5.1 to run"end
local n=""do
local t=24
local o={}for l,a in Z(E,"%s*([^,]+),'([^']+)'")do
local e="  "..l
e=e..i.rep(" ",t-#e)..a.."\n"n=n..e
o[l]=true
o["--no"..m(l,3)]=true
end
E=o
end
p=i.format(p,n,v)if z then
local e="\nembedded plugins:\n"for n=1,#z do
local n=z[n]e=e.."  "..ne[n].."\n"end
p=p..e
end
local N=a
local e={}local a,r
local function T(n)for n in Z(n,"(%-%-%S+)")do
if m(n,3,4)=="no"and
E["--"..m(n,5)]then
e[m(n,5)]=false
else
e[m(n,3)]=true
end
end
end
local d={"TK_KEYWORD","TK_NAME","TK_NUMBER","TK_STRING","TK_LSTRING","TK_OP","TK_EOS","TK_COMMENT","TK_LCOMMENT","TK_EOL","TK_SPACE",}local s=7
local u={["\n"]="LF",["\r"]="CR",["\n\r"]="LFCR",["\r\n"]="CRLF",}local function c(n)local e=io.open(n,"rb")if not e then t('cannot open "'..n..'" for reading')end
local l=e:read("*a")if not l then t('cannot read from "'..n..'"')end
e:close()return l
end
local function V(n,l)local e=io.open(n,"wb")if not e then t('cannot open "'..n..'" for writing')end
local l=e:write(l)if not l then t('cannot write to "'..n..'"')end
e:close()end
local function I()a,r={},{}for e=1,#d do
local e=d[e]a[e],r[e]=0,0
end
end
local function O(e,n)a[e]=a[e]+1
r[e]=r[e]+#n
end
local function L()local function t(e,n)if e==0 then return 0 end
return n/e
end
local o={}local e,n=0,0
for l=1,s do
local l=d[l]e=e+a[l]n=n+r[l]end
a.TOTAL_TOK,r.TOTAL_TOK=e,n
o.TOTAL_TOK=t(e,n)e,n=0,0
for l=1,#d do
local l=d[l]e=e+a[l]n=n+r[l]o[l]=t(a[l],r[l])end
a.TOTAL_ALL,r.TOTAL_ALL=e,n
o.TOTAL_ALL=t(e,n)return o
end
local function y(e)local e=c(e)o.init(e)o.llex()local e,l=o.tok,o.seminfo
for n=1,#e do
local n,e=e[n],l[n]if n=="TK_OP"and i.byte(e)<32 then
e="("..i.byte(e)..")"elseif n=="TK_EOL"then
e=u[e]else
e="'"..e.."'"end
b(n.." "..e)end
end
local function C(e)local l=b
local e=c(e)o.init(e)o.llex()local o,n,e=o.tok,o.seminfo,o.tokln
f.init(o,n,e)local e=f.parser()local n,t=e.globalinfo,e.localinfo
local o=i.rep("-",72)l"*** Local/Global Variable Tracker Tables ***"l(o.."\n GLOBALS\n"..o)for e=1,#n do
local n=n[e]local e="("..e..") '"..n.name.."' -> "local n=n.xref
for o=1,#n do e=e..n[o].." "end
l(e)end
l(o.."\n LOCALS (decl=declared act=activated rem=removed)\n"..o)for e=1,#t do
local n=t[e]local e="("..e..") '"..n.name.."' decl:"..n.decl.." act:"..n.act.." rem:"..n.rem
if n.isself then
e=e.." isself"end
e=e.." -> "local n=n.xref
for o=1,#n do e=e..n[o].." "end
l(e)end
l(o.."\n")end
local function P(l)local e=b
local n=c(l)o.init(n)o.llex()local n,o=o.tok,o.seminfo
e(_)e("Statistics for: "..l.."\n")I()for e=1,#n do
local n,e=n[e],o[e]O(n,e)end
local n=L()local l=i.format
local function c(e)return a[e],r[e],n[e]end
local o,t="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"local n=i.rep("-",42)e(l(o,"Lexical","Input","Input","Input"))e(l(o,"Elements","Count","Bytes","Average"))e(n)for o=1,#d do
local o=d[o]e(l(t,o,c(o)))if o=="TK_EOS"then e(n)end
end
e(n)e(l(t,"Total Elements",c("TOTAL_ALL")))e(n)e(l(t,"Total Tokens",c("TOTAL_TOK")))e(n.."\n")end
local function M(p,T)local function n(...)if e.QUIET then return end
_G.print(...)end
if l and l.init then
e.EXIT=false
l.init(e,p,T)if e.EXIT then return end
end
n(_)local u=c(p)if l and l.post_load then
u=l.post_load(u)or u
if e.EXIT then return end
end
o.init(u)o.llex()local c,s,h=o.tok,o.seminfo,o.tokln
if l and l.post_lex then
l.post_lex(c,s,h)if e.EXIT then return end
end
I()for e=1,#c do
local e,n=c[e],s[e]O(e,n)end
local b=L()local _,m=a,r
A.print=n
f.init(c,s,h)local f=f.parser()if l and l.post_parse then
l.post_parse(f.globalinfo,f.localinfo)if e.EXIT then return end
end
A.optimize(e,c,s,f)if l and l.post_optparse then
l.post_optparse()if e.EXIT then return end
end
local f=g.warn
g.print=n
c,s,h=g.optimize(e,c,s,h)if l and l.post_optlex then
l.post_optlex(c,s,h)if e.EXIT then return end
end
local l=ee.concat(s)if i.find(l,"\r\n",1,1)or
i.find(l,"\n\r",1,1)then
f.MIXEDEOL=true
end
k.init(e,o,f)k.source(u,l)k.binary(u,l)local h="before and after lexer streams are NOT equivalent!"local u="before and after binary chunks are NOT equivalent!"if f.SRC_EQUIV then
if e["opt-srcequiv"]then t(h)end
else
n"*** SRCEQUIV: token streams are sort of equivalent"if e["opt-locals"]then
n"(but no identifier comparisons since --opt-locals enabled)"end
n()end
if f.BIN_EQUIV then
if e["opt-binequiv"]then t(u)end
else
n"*** BINEQUIV: binary chunks are sort of equivalent"n()end
V(T,l)I()for e=1,#c do
local n,e=c[e],s[e]O(n,e)end
local o=L()n("Statistics for: "..p.." -> "..T.."\n")local l=i.format
local function c(e)return _[e],m[e],b[e],a[e],r[e],o[e]end
local o,t="%-16s%8s%8s%10s%8s%8s%10s","%-16s%8d%8d%10.2f%8d%8d%10.2f"local e=i.rep("-",68)n("*** lexer-based optimizations summary ***\n"..e)n(l(o,"Lexical","Input","Input","Input","Output","Output","Output"))n(l(o,"Elements","Count","Bytes","Average","Count","Bytes","Average"))n(e)for o=1,#d do
local o=d[o]n(l(t,o,c(o)))if o=="TK_EOS"then n(e)end
end
n(e)n(l(t,"Total Elements",c("TOTAL_ALL")))n(e)n(l(t,"Total Tokens",c("TOTAL_TOK")))n(e)if f.LSTRING then
n("* WARNING: "..f.LSTRING)elseif f.MIXEDEOL then
n("* WARNING: ".."output still contains some CRLF or LFCR line endings")elseif f.SRC_EQUIV then
n("* WARNING: "..h)elseif f.BIN_EQUIV then
n("* WARNING: "..u)end
n()end
local c={...}local r={}T(v)local function f(a)for n=1,#a do
local n=a[n]local l
local o,c=i.find(n,"%.[^%.%\\%/]*$")local r,i=n,""if o and o>1 then
r=m(n,1,o-1)i=m(n,o,c)end
l=r..N..i
if#a==1 and e.OUTPUT_FILE then
l=e.OUTPUT_FILE
end
if n==l then
t"output filename identical to input filename"end
if e.DUMP_LEXER then
y(n)elseif e.DUMP_PARSER then
C(n)elseif e.READ_ONLY then
P(n)else
M(n,l)end
end
end
local function d()local n,o=#c,1
if n==0 then
e.HELP=true
end
while o<=n do
local n,a=c[o],c[o+1]local i=j(n,"^%-%-?")if i=="-"then
if n=="-h"then
e.HELP=true break
elseif n=="-v"then
e.VERSION=true break
elseif n=="-s"then
if not a then t"-s option needs suffix specification"end
N=a
o=o+1
elseif n=="-o"then
if not a then t"-o option needs a file name"end
e.OUTPUT_FILE=a
o=o+1
elseif n=="-"then
break
else
t("unrecognized option "..n)end
elseif i=="--"then
if n=="--help"then
e.HELP=true break
elseif n=="--version"then
e.VERSION=true break
elseif n=="--keep"then
if not a then t"--keep option needs a string to match for"end
e.KEEP=a
o=o+1
elseif n=="--plugin"then
if not a then t"--plugin option needs a module name"end
if e.PLUGIN then t"only one plugin can be specified"end
e.PLUGIN=a
l=K(x..a)o=o+1
elseif n=="--quiet"then
e.QUIET=true
elseif n=="--read-only"then
e.READ_ONLY=true
elseif n=="--basic"then
T(R)elseif n=="--maximum"then
T(w)elseif n=="--none"then
T(S)elseif n=="--dump-lexer"then
e.DUMP_LEXER=true
elseif n=="--dump-parser"then
e.DUMP_PARSER=true
elseif n=="--details"then
e.DETAILS=true
elseif E[n]then
T(n)else
t("unrecognized option "..n)end
else
r[#r+1]=n
end
o=o+1
end
if e.HELP then
b(_..p)return true
elseif e.VERSION then
b(_)return true
end
if#r>0 then
if#r>1 and e.OUTPUT_FILE then
t"with -o, only one source file can be specified"end
f(r)return true
else
t"nothing to do!"end
end
if not d()then
t"Please run with option -h or --help for usage information"end