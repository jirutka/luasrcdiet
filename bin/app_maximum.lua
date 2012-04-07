#!/usr/bin/env lua
local i=string
local e=math
local ee=table
local k=require
local m=print
local p=i.sub
local Q=i.gmatch
local X=i.match
local b=package.preload
local l=_G
local Z={html="html    generates a HTML file for checking globals",sloc="sloc    calculates SLOC for given source file",}local z={'html','sloc',}b.llex=function()module"llex"local r=l.require"string"local s=r.find
local u=r.match
local a=r.sub
local p={}for e in r.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]],"%S+")do
p[e]=true
end
local e,f,o,i,c
local function t(n,l)local e=#tok+1
tok[e]=n
seminfo[e]=l
tokln[e]=c
end
local function d(n,i)local a=a
local l=a(e,n,n)n=n+1
local e=a(e,n,n)if(e=="\n"or e=="\r")and(e~=l)then
n=n+1
l=l..e
end
if i then t("TK_EOL",l)end
c=c+1
o=n
return n
end
function init(l,n)e=l
f=n
o=1
c=1
tok={}seminfo={}tokln={}local l,a,e,n=s(e,"^(#[^\r\n]*)(\r?\n?)")if l then
o=o+#e
t("TK_COMMENT",e)if#n>0 then d(o,true)end
end
end
function chunkid()if f and u(f,"^[=@]")then
return a(f,2)end
return"[string]"end
function errorline(o,n)local e=error or l.error
e(r.format("%s:%d: %s",chunkid(),n or c,o))end
local c=errorline
local function h(n)local t=a
local a=t(e,n,n)n=n+1
local l=#u(e,"=*",n)n=n+l
o=n
return(t(e,n,n)==a)and l or(-l)-1
end
local function T(r,f)local n=o+1
local t=a
local l=t(e,n,n)if l=="\r"or l=="\n"then
n=d(n)end
while true do
local l,s,a=s(e,"([\r\n%]])",n)if not l then
c(r and"unfinished long string"or"unfinished long comment")end
n=l
if a=="]"then
if h(n)==f then
i=t(e,i,o)o=o+1
return i
end
n=o
else
i=i.."\n"n=d(n)end
end
end
local function m(f)local n=o
local r=s
local a=a
while true do
local t,s,l=r(e,"([\n\r\\\"'])",n)if t then
if l=="\n"or l=="\r"then
c("unfinished string")end
n=t
if l=="\\"then
n=n+1
l=a(e,n,n)if l==""then break end
t=r("abfnrtv\n\r",l,1,true)if t then
if t>7 then
n=d(n)else
n=n+1
end
elseif r(l,"%D")then
n=n+1
else
local o,e,l=r(e,"^(%d%d?%d?)",n)n=e+1
if l+1>256 then
c("escape sequence too large")end
end
else
n=n+1
if l==f then
o=n
return a(e,i,n-1)end
end
else
break
end
end
c("unfinished string")end
function llex()local r=s
local f=u
while true do
local n=o
while true do
local u,b,s=r(e,"^([_%a][_%w]*)",n)if u then
o=n+#s
if p[s]then
t("TK_KEYWORD",s)else
t("TK_NAME",s)end
break
end
local s,p,u=r(e,"^(%.?)%d",n)if s then
if u=="."then n=n+1 end
local u,i,d=r(e,"^%d*[%.%d]*([eE]?)",n)n=i+1
if#d==1 then
if f(e,"^[%+%-]",n)then
n=n+1
end
end
local i,n=r(e,"^[_%w]*",n)o=n+1
local e=a(e,s,n)if not l.tonumber(e)then
c("malformed number")end
t("TK_NUMBER",e)break
end
local u,p,s,l=r(e,"^((%s)[ \t\v\f]*)",n)if u then
if l=="\n"or l=="\r"then
d(n,true)else
o=p+1
t("TK_SPACE",s)end
break
end
local l=f(e,"^%p",n)if l then
i=n
local d=r("-[\"'.=<>~",l,1,true)if d then
if d<=2 then
if d==1 then
local c=f(e,"^%-%-(%[?)",n)if c then
n=n+2
local l=-1
if c=="["then
l=h(n)end
if l>=0 then
t("TK_LCOMMENT",T(false,l))else
o=r(e,"[\n\r]",n)or(#e+1)t("TK_COMMENT",a(e,i,o-1))end
break
end
else
local e=h(n)if e>=0 then
t("TK_LSTRING",T(true,e))elseif e==-1 then
t("TK_OP","[")else
c("invalid long string delimiter")end
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
local e=a(e,n,n)if e~=""then
o=n+1
t("TK_OP",e)break
end
t("TK_EOS","")return
end
end
end
end
b.lparser=function()module"lparser"local _=l.require"string"local v,L,w,y,i,s,B,n,A,d,p,m,o,Y,N,P,f,E,x,I
local O,c,K,R,S,g
local e=_.gmatch
local C={}for e in e("else elseif end until <eof>","%S+")do
C[e]=true
end
local M={}local W={}for e,l,n in e([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")do
M[e]=l+0
W[e]=n+0
end
local ne={["not"]=true,["-"]=true,["#"]=true,}local ee=8
local function t(e,n)local l=error or l.error
l(_.format("(source):%d: %s",n or d,e))end
local function e()B=w[i]n,A,d,p=v[i],L[i],w[i],y[i]i=i+1
end
local function Z()return v[i]end
local function r(l)local e=n
if e~="<number>"and e~="<string>"then
if e=="<name>"then e=A end
e="'"..e.."'"end
t(l.." near "..e)end
local function h(e)r("'"..e.."' expected")end
local function t(l)if n==l then e();return true end
end
local function D(e)if n~=e then h(e)end
end
local function a(n)D(n);e()end
local function j(e,n)if not e then r(n)end
end
local function u(e,l,n)if not t(e)then
if n==d then
h(e)else
r("'"..e.."' expected (to close '"..l.."' at line "..n..")")end
end
end
local function T()D("<name>")local n=A
m=p
e()return n
end
local function q(e,n)e.k="VK"end
local function G(e)q(e,T())end
local function h(t,l)local n=o.bl
local e
if n then
e=n.locallist
else
e=o.locallist
end
local n=#f+1
f[n]={name=t,xref={m},decl=m,}if l then
f[n].isself=true
end
local l=#E+1
E[l]=n
x[l]=e
end
local function k(e)local n=#E
while e>0 do
e=e-1
local e=n-e
local l=E[e]local n=f[l]local o=n.name
n.act=p
E[e]=nil
local t=x[e]x[e]=nil
local e=t[o]if e then
n=f[e]n.rem=-l
end
t[o]=l
end
end
local function V()local n=o.bl
local e
if n then
e=n.locallist
else
e=o.locallist
end
for n,e in l.pairs(e)do
local e=f[e]e.rem=p
end
end
local function p(e,n)if _.sub(e,1,1)=="("then
return
end
h(e,n)end
local function U(o,l)local n=o.bl
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
local function _(n,o,e)if n==nil then
e.k="VGLOBAL"return"VGLOBAL"else
local l=U(n,o)if l>=0 then
e.k="VLOCAL"e.id=l
return"VLOCAL"else
if _(n.prev,o,e)=="VGLOBAL"then
return"VGLOBAL"end
e.k="VUPVAL"return"VUPVAL"end
end
end
local function F(l)local n=T()_(o,n,l)if l.k=="VGLOBAL"then
local e=P[n]if not e then
e=#N+1
N[e]={name=n,xref={m},}P[n]=e
else
local e=N[e].xref
e[#e+1]=m
end
else
local e=l.id
local e=f[e].xref
e[#e+1]=m
end
end
local function m(n)local e={}e.isbreakable=n
e.prev=o.bl
e.locallist={}o.bl=e
end
local function _()local e=o.bl
V()o.bl=e.prev
end
local function Q()local e
if not o then
e=Y
else
e={}end
e.prev=o
e.bl=nil
e.locallist={}o=e
end
local function H()V()o=o.prev
end
local function U(n)local l={}e()G(l)n.k="VINDEXED"end
local function J(n)e()c(n)a("]")end
local function z(e)local e,l={},{}if n=="<name>"then
G(e)else
J(e)end
a("=")c(l)end
local function l(e)if e.v.k=="VVOID"then return end
e.v.k="VVOID"end
local function V(e)c(e.v)end
local function X(l)local o=d
local e={}e.v={}e.t=l
l.k="VRELOCABLE"e.v.k="VVOID"a("{")repeat
if n=="}"then break end
local n=n
if n=="<name>"then
if Z()~="="then
V(e)else
z(e)end
elseif n=="["then
z(e)else
V(e)end
until not t(",")and not t(";")u("}","{",o)end
local function Z()local l=0
if n~=")"then
repeat
local n=n
if n=="<name>"then
h(T())l=l+1
elseif n=="..."then
e()o.is_vararg=true
else
r("<name> or '...' expected")end
until o.is_vararg or not t(",")end
k(l)end
local function z(a)local l={}local t=d
local o=n
if o=="("then
if t~=B then
r("ambiguous syntax (function call x new statement)")end
e()if n==")"then
l.k="VVOID"else
O(l)end
u(")","(",t)elseif o=="{"then
X(l)elseif o=="<string>"then
q(l,A)e()else
r("function arguments expected")return
end
a.k="VCALL"end
local function B(l)local n=n
if n=="("then
local n=d
e()c(l)u(")","(",n)elseif n=="<name>"then
F(l)else
r("unexpected symbol")end
end
local function V(l)B(l)while true do
local n=n
if n=="."then
U(l)elseif n=="["then
local e={}J(e)elseif n==":"then
local n={}e()G(n)z(l)elseif n=="("or n=="<string>"or n=="{"then
z(l)else
return
end
end
end
local function G(l)local n=n
if n=="<number>"then
l.k="VKNUM"elseif n=="<string>"then
q(l,A)elseif n=="nil"then
l.k="VNIL"elseif n=="true"then
l.k="VTRUE"elseif n=="false"then
l.k="VFALSE"elseif n=="..."then
j(o.is_vararg==true,"cannot use '...' outside a vararg function");l.k="VVARARG"elseif n=="{"then
X(l)return
elseif n=="function"then
e()S(l,false,d)return
else
V(l)return
end
e()end
local function A(o,t)local l=n
local a=ne[l]if a then
e()A(o,ee)else
G(o)end
l=n
local n=M[l]while n and n>t do
local o={}e()local e=A(o,W[l])l=e
n=M[l]end
return l
end
function c(e)A(e,0)end
local function M(e)local n={}local e=e.v.k
j(e=="VLOCAL"or e=="VUPVAL"or e=="VGLOBAL"or e=="VINDEXED","syntax error")if t(",")then
local e={}e.v={}V(e.v)M(e)else
a("=")O(n)return
end
n.k="VNONRELOC"end
local function l(e,n)a("do")m(false)k(e)K()_()end
local function G(e)local n=s
p("(for index)")p("(for limit)")p("(for step)")h(e)a("=")R()a(",")R()if t(",")then
R()else
end
l(1,true)end
local function z(e)local n={}p("(for generator)")p("(for state)")p("(for control)")h(e)local e=1
while t(",")do
h(T())e=e+1
end
a("in")local o=s
O(n)l(e,false)end
local function q(e)local l=false
F(e)while n=="."do
U(e)end
if n==":"then
l=true
U(e)end
return l
end
function R()local e={}c(e)end
local function l()local e={}c(e)end
local function A()e()l()a("then")K()end
local function R()local n,e={}h(T())n.k="VLOCAL"k(1)S(e,false,d)end
local function U()local e=0
local n={}repeat
h(T())e=e+1
until not t(",")if t("=")then
O(n)else
n.k="VVOID"end
k(e)end
function O(e)c(e)while t(",")do
c(e)end
end
function S(l,n,e)Q()a("(")if n then
p("self",true)k(1)end
Z()a(")")g()u("end","function",e)H()end
function K()m(false)g()_()end
local function p()local o=s
m(true)e()local l=T()local e=n
if e=="="then
G(l)elseif e==","or e=="in"then
z(l)else
r("'=' or 'in' expected")end
u("end","for",o)_()end
local function h()local n=s
e()l()m(true)a("do")K()u("end","while",n)_()end
local function T()local n=s
m(true)m(false)e()g()u("until","repeat",n)l()_()_()end
local function k()local l=s
local o={}A()while n=="elseif"do
A()end
if n=="else"then
e()K()end
u("end","if",l)end
local function _()local l={}e()local e=n
if C[e]or e==";"then
else
O(l)end
end
local function m()local n=o.bl
e()while n and not n.isbreakable do
n=n.prev
end
if not n then
r("no loop to break")end
end
local function c()local n=i-1
local e={}e.v={}V(e.v)if e.v.k=="VCALL"then
I[n]="call"else
e.prev=nil
M(e)I[n]="assign"end
end
local function r()local o=s
local l,n={},{}e()local e=q(l)S(n,e,o)end
local function l()local n=s
e()K()u("end","do",n)end
local function a()e()if t("function")then
R()else
U()end
end
local a={["if"]=k,["while"]=h,["do"]=l,["for"]=p,["repeat"]=T,["function"]=r,["local"]=a,["return"]=_,["break"]=m,}local function l()s=d
local e=n
local n=a[e]if n then
I[i-1]=e
n()if e=="return"or e=="break"then return true end
else
c()end
return false
end
function g()local e=false
while not e and not C[n]do
e=l()t(";")end
end
function parser()Q()o.is_vararg=true
e()g()D("<eof>")H()return{globalinfo=N,localinfo=f,statinfo=I,toklist=v,seminfolist=L,toklnlist=w,xreflist=y,}end
function init(e,t,a)i=1
Y={}local n=1
v,L,w,y={},{},{},{}for l=1,#e do
local e=e[l]local o=true
if e=="TK_KEYWORD"or e=="TK_OP"then
e=t[l]elseif e=="TK_NAME"then
e="<name>"L[n]=t[l]elseif e=="TK_NUMBER"then
e="<number>"L[n]=0
elseif e=="TK_STRING"or e=="TK_LSTRING"then
e="<string>"L[n]=""elseif e=="TK_EOS"then
e="<eof>"else
o=false
end
if o then
v[n]=e
w[n]=a[l]y[n]=l
n=n+1
end
end
N,P,f={},{},{}E,x={},{}I={}end
end
b.optlex=function()module"optlex"local u=l.require"string"local t=u.match
local e=u.sub
local r=u.find
local d=u.rep
local p
error=l.error
warn={}local a,o,f
local m={TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,TK_STRING=true,TK_LSTRING=true,TK_OP=true,TK_EOS=true,}local _={TK_COMMENT=true,TK_LCOMMENT=true,TK_EOL=true,TK_SPACE=true,}local c
local function E(e)local n=a[e-1]if e<=1 or n=="TK_EOL"then
return true
elseif n==""then
return E(e-1)end
return false
end
local function K(n)local e=a[n+1]if n>=#a or e=="TK_EOL"or e=="TK_EOS"then
return true
elseif e==""then
return K(n+1)end
return false
end
local function w(l)local n=#t(l,"^%-%-%[=*%[")local l=e(l,n+1,-(n-1))local e,n=1,0
while true do
local l,a,t,o=r(l,"([\r\n])([\r\n]?)",e)if not l then break end
e=l+1
n=n+1
if#o>0 and t~=o then
e=e+1
end
end
return n
end
local function L(i,r)local l=t
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
local function T()local r,i,l={},{},{}local e=1
for n=1,#a do
local t=a[n]if t~=""then
r[e],i[e],l[e]=t,o[n],f[n]e=e+1
end
end
a,o,f=r,i,l
end
local function S(r)local n=o[r]local n=n
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
local n,o=t(n,"^([^eE]+)[eE]([%+%-]?%d+)$")o=l.tonumber(o)local i,r=t(n,"^(%d*)%.(%d*)$")if i then
o=o-#r
n=i..r
end
if n+0==0 then
a="0"else
local i=#t(n,"^0*")n=e(n,i+1)i=#t(n,"0*$")if i>0 then
n=e(n,1,#n-i)o=o+i
end
local l=l.tostring(o)if o==0 then
a=n
elseif o>0 and(o<=1+#l)then
a=n..d("0",o)elseif o<0 and(o>=-#n)then
i=#n+o
a=e(n,1,i).."."..e(n,i+1)elseif o<0 and(#l>=-o-#n)then
i=-o-#n
a="."..d("0",i)..n
else
a=n.."e"..o
end
end
end
if a and a~=o[r]then
if c then
p("<number> (line "..f[r]..") "..o[r].." -> "..a)c=c+1
end
o[r]=a
end
end
local function v(s)local n=o[s]local i=e(n,1,1)local T=(i=="'")and'"'or"'"local n=e(n,2,-2)local l=1
local h,d=0,0
while l<=#n do
local s=e(n,l,l)if s=="\\"then
local o=l+1
local c=e(n,o,o)local a=r("abfnrtv\\\n\r\"'0123456789",c,1,true)if not a then
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
h=h+1
l=l+2
else
d=d+1
n=e(n,1,l-1)..e(n,o)l=l+1
end
else
local a=t(n,"^(%d%d?%d?)",o)o=l+1+#a
local f=a+0
local c=u.char(f)local r=r("\a\b\f\n\r\t\v",c,1,true)if r then
a="\\"..e("abfnrtv",r,r)elseif f<32 then
if t(e(n,o,o),"%d")then
a="\\"..a
else
a="\\"..f
end
elseif c==i then
a="\\"..c
h=h+1
elseif c=="\\"then
a="\\\\"else
a=c
if c==T then
d=d+1
end
end
n=e(n,1,l-1)..a..e(n,o)l=l+#a
end
else
l=l+1
if s==T then
d=d+1
end
end
end
if h>d then
l=1
while l<=#n do
local o,a,t=r(n,"(['\"])",l)if not o then break end
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
p("<string> (line "..f[s]..") "..o[s].." -> "..n)c=c+1
end
o[s]=n
end
end
local function A(s)local n=o[s]local c=t(n,"^%[=*%[")local l=#c
local u=e(n,-l,-1)local i=e(n,l+1,-(l+1))local a=""local n=1
while true do
local l,o,c,r=r(i,"([\r\n])([\r\n]?)",n)local o
if not l then
o=e(i,n)elseif l>=n then
o=e(i,n,l-1)end
if o~=""then
if t(o,"%s+$")then
warn.LSTRING="trailing whitespace in long string near line "..f[s]end
a=a..o
end
if not l then
break
end
n=l+1
if l then
if#r>0 and c~=r then
n=n+1
end
if not(n==1 and n==l)then
a=a.."\n"end
end
end
if l>=3 then
local e,n=l-1
while e>=2 do
local l="%]"..d("=",e-2).."%]"if not t(a,l)then n=e end
e=e-1
end
if n then
l=d("=",n-2)c,u="["..l.."[","]"..l.."]"end
end
o[s]=c..a..u
end
local function O(s)local l=o[s]local c=t(l,"^%-%-%[=*%[")local n=#c
local f=e(l,-(n-2),-1)local i=e(l,n+1,-(n-1))local a=""local l=1
while true do
local o,n,c,r=r(i,"([\r\n])([\r\n]?)",l)local n
if not o then
n=e(i,l)elseif o>=l then
n=e(i,l,o-1)end
if n~=""then
local l=t(n,"%s*$")if#l>0 then n=e(n,1,-(l+1))end
a=a..n
end
if not o then
break
end
l=o+1
if o then
if#r>0 and c~=r then
l=l+1
end
a=a.."\n"end
end
n=n-2
if n>=3 then
local e,l=n-1
while e>=2 do
local n="%]"..d("=",e-2).."%]"if not t(a,n)then l=e end
e=e-1
end
if l then
n=d("=",l-2)c,f="--["..n.."[","]"..n.."]"end
end
o[s]=c..a..f
end
local function k(l)local n=o[l]local t=t(n,"%s*$")if#t>0 then
n=e(n,1,-(t+1))end
o[l]=n
end
local function N(o,n)if not o then return false end
local l=t(n,"^%-%-%[=*%[")local l=#l
local t=e(n,-l,-1)local e=e(n,l+1,-(l-1))if r(e,o,1,true)then
return true
end
end
function optimize(n,i,t,r)local u=n["opt-comments"]local s=n["opt-whitespace"]local h=n["opt-emptylines"]local b=n["opt-eols"]local I=n["opt-strings"]local x=n["opt-numbers"]local g=n["opt-experimental"]local R=n.KEEP
c=n.DETAILS and 0
p=p or l.print
if b then
u=true
s=true
h=true
elseif g then
s=true
end
a,o,f=i,t,r
local n=1
local l,r
local i
local function t(t,l,e)e=e or n
a[e]=t or""o[e]=l or""end
if g then
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
if x then
S(n)end
i=n
elseif l=="TK_STRING"or
l=="TK_LSTRING"then
if I then
if l=="TK_STRING"then
v(n)else
A(n)end
end
i=n
elseif l=="TK_COMMENT"then
if u then
if n==1 and e(r,1,1)=="#"then
k(n)else
t()end
elseif s then
k(n)end
elseif l=="TK_LCOMMENT"then
if N(R,r)then
if s then
O(n)end
i=n
elseif u then
local e=w(r)if _[a[n+1]]then
t()l=""else
t("TK_SPACE"," ")end
if not h and e>0 then
t("TK_EOL",d("\n",e))end
if s and l~=""then
n=n-1
end
else
if s then
O(n)end
i=n
end
elseif l=="TK_EOL"then
if c and h then
t()elseif r=="\r\n"or r=="\n\r"then
t("TK_EOL","\n")end
elseif l=="TK_SPACE"then
if s then
if c or K(n)then
t()else
local l=a[i]if l=="TK_LCOMMENT"then
t()else
local e=a[n+1]if _[e]then
if(e=="TK_COMMENT"or e=="TK_LCOMMENT")and
l=="TK_OP"and o[i]=="-"then
else
t()end
else
local e=L(i,n+1)if e==""then
t()else
t("TK_SPACE"," ")end
end
end
end
end
else
error("unidentified token encountered")end
n=n+1
end
T()if b then
n=1
if a[1]=="TK_COMMENT"then
n=3
end
while true do
l,r=a[n],o[n]if l=="TK_EOS"then
break
elseif l=="TK_EOL"then
local l,e=a[n-1],a[n+1]if m[l]and m[e]then
local n=L(n-1,n+1)if n==""or e=="TK_EOS"then
t()end
end
end
n=n+1
end
T()end
if c and c>0 then p()end
return a,o,f
end
end
b.optparser=function()module"optparser"local a=l.require"string"local K=l.require"table"local t="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"local d="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"local w={}for e in a.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]],"%S+")do
w[e]=true
end
local r,u,i,L,_,N,o,T,E,S,O,c
local function I(e)local t={}for a=1,#e do
local n=e[a]local o=n.name
if not t[o]then
t[o]={decl=0,token=0,size=0,}end
local e=t[o]e.decl=e.decl+1
local t=n.xref
local l=#t
e.token=e.token+l
e.size=e.size+l*#o
if n.decl then
n.id=a
n.xcount=l
if l>1 then
n.first=t[2]n.last=t[l]end
else
e.id=a
end
end
return t
end
local function x(e)local i=a.byte
local a=a.char
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
local n=i(l,n)e[n]=e[n]+1
end
end
end
local function l(o)local n={}for l=1,#o do
local o=i(o,l)n[l]={c=o,freq=e[o],}end
K.sort(n,function(n,e)return n.freq>e.freq
end)local e={}for l=1,#n do
e[l]=a(n[l].c)end
return K.concat(e)end
t=l(t)d=l(d)end
local function y()local n
local i,r=#t,#d
local e=O
if e<i then
e=e+1
n=a.sub(t,e,e)else
local o,l=i,1
repeat
e=e-o
o=o*r
l=l+1
until o>e
local o=e%i
e=(e-o)/i
o=o+1
n=a.sub(t,o,o)while l>1 do
local o=e%r
e=(e-o)/r
o=o+1
n=n..a.sub(d,o,o)l=l-1
end
end
O=O+1
return n,E[n]~=nil
end
local function R(A,x,S,t)local e=m or l.print
local n=a.format
local p=t.DETAILS
if t.QUIET then return end
local T,m,b,w,N,k,_,h,v,I,i,u,f,O,g,r,s,d,E,L=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
local function t(e,n)if e==0 then return 0 end
return n/e
end
for n,e in l.pairs(A)do
T=T+1
i=i+e.token
r=r+e.size
end
for n,e in l.pairs(x)do
m=m+1
_=_+e.decl
u=u+e.token
s=s+e.size
end
for n,e in l.pairs(S)do
b=b+1
h=h+e.decl
f=f+e.token
d=d+e.size
end
w=T+m
v=k+_
O=i+u
E=r+s
N=T+b
I=k+h
g=i+f
L=r+d
if p then
local p={}for n,e in l.pairs(A)do
e.name=n
p[#p+1]=e
end
K.sort(p,function(n,e)return n.size>e.size
end)local l,m="%8s%8s%10s  %s","%8d%8d%10.2f  %s"local T=a.rep("-",44)e("*** global variable list (sorted by size) ***\n"..T)e(n(l,"Token","Input","Input","Global"))e(n(l,"Count","Bytes","Average","Name"))e(T)for l=1,#p do
local l=p[l]e(n(m,l.token,l.size,t(l.token,l.size),l.name))end
e(T)e(n(m,i,r,t(i,r),"TOTAL"))e(T.."\n")local l,p="%8s%8s%8s%10s%8s%10s  %s","%8d%8d%8d%10.2f%8d%10.2f  %s"local a=a.rep("-",70)e("*** local variable list (sorted by allocation order) ***\n"..a)e(n(l,"Decl.","Token","Input","Input","Output","Output","Global"))e(n(l,"Count","Count","Bytes","Average","Bytes","Average","Name"))e(a)for l=1,#c do
local i=c[l]local l=S[i]local r,a=0,0
for n=1,#o do
local e=o[n]if e.name==i then
r=r+e.xcount
a=a+e.xcount*#e.oldname
end
end
e(n(p,l.decl,l.token,a,t(r,a),l.size,t(l.token,l.size),i))end
e(a)e(n(p,h,f,s,t(u,s),d,t(f,d),"TOTAL"))e(a.."\n")end
local c,o="%-16s%8s%8s%8s%8s%10s","%-16s%8d%8d%8d%8d%10.2f"local l=a.rep("-",58)e("*** local variable optimization summary ***\n"..l)e(n(c,"Variable","Unique","Decl.","Token","Size","Average"))e(n(c,"Types","Names","Count","Count","Bytes","Bytes"))e(l)e(n(o,"Global",T,k,i,r,t(i,r)))e(l)e(n(o,"Local (in)",m,_,u,s,t(u,s)))e(n(o,"TOTAL (in)",w,v,O,E,t(O,E)))e(l)e(n(o,"Local (out)",b,h,f,d,t(f,d)))e(n(o,"TOTAL (out)",N,I,g,L,t(g,L)))e(l.."\n")end
local function f()local function o(e)local n=i[e+1]or""local l=i[e+2]or""local e=i[e+3]or""if n=="("and l=="<string>"and e==")"then
return true
end
end
local l={}local e=1
while e<=#i do
local n=T[e]if n=="call"and o(e)then
l[e+1]=true
l[e+3]=true
e=e+3
end
e=e+1
end
local n,e,o=1,1,#i
local t={}while e<=o do
if l[n]then
t[_[n]]=true
n=n+1
end
if n>e then
if n<=o then
i[e]=i[n]L[e]=L[n]_[e]=_[n]-(n-e)T[e]=T[n]else
i[e]=nil
L[e]=nil
_[e]=nil
T[e]=nil
end
end
n=n+1
e=e+1
end
local e,n,l=1,1,#r
while n<=l do
if t[e]then
e=e+1
end
if e>n then
if e<=l then
r[n]=r[e]u[n]=u[e]else
r[n]=nil
u[n]=nil
end
end
e=e+1
n=n+1
end
end
local function s(r)O=0
c={}E=I(N)S=I(o)if r["opt-entropy"]then
x(r)end
local e={}for n=1,#o do
e[n]=o[n]end
K.sort(e,function(n,e)return n.xcount>e.xcount
end)local l,n,d={},1,false
for o=1,#e do
local e=e[o]if not e.isself then
l[n]=e
n=n+1
else
d=true
end
end
e=l
local i=#e
while i>0 do
local a,l
repeat
a,l=y()until not w[a]c[#c+1]=a
local n=i
if l then
local t=N[E[a].id].xref
local a=#t
for l=1,i do
local l=e[l]local i,e=l.act,l.rem
while e<0 do
e=o[-e].rem
end
local o
for n=1,a do
local n=t[n]if n>=i and n<=e then o=true end
end
if o then
l.skip=true
n=n-1
end
end
end
while n>0 do
local l=1
while e[l].skip do
l=l+1
end
n=n-1
local t=e[l]l=l+1
t.newname=a
t.skip=true
t.done=true
local i,r=t.first,t.last
local c=t.xref
if i and n>0 then
local a=n
while a>0 do
while e[l].skip do
l=l+1
end
a=a-1
local e=e[l]l=l+1
local a,l=e.act,e.rem
while l<0 do
l=o[-l].rem
end
if not(r<a or i>l)then
if a>=t.act then
for o=1,t.xcount do
local o=c[o]if o>=a and o<=l then
n=n-1
e.skip=true
break
end
end
else
if e.last and e.last>=t.act then
n=n-1
e.skip=true
end
end
end
if n==0 then break end
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
local e=o[e]local n=e.xref
if e.newname then
for l=1,e.xcount do
local n=n[l]u[n]=e.newname
end
e.name,e.oldname=e.newname,e.name
else
e.oldname=e.name
end
end
if d then
c[#c+1]="self"end
local e=I(o)R(E,S,e,r)end
function optimize(n,t,l,e)r,u=t,l
i,L,_=e.toklist,e.seminfolist,e.xreflist
N,o,T=e.globalinfo,e.localinfo,e.statinfo
if n["opt-locals"]then
s(n)end
if n["opt-experimental"]then
f()end
end
end
b.equiv=function()module"equiv"local e=l.require"string"local d=l.loadstring
local s=e.sub
local c=e.match
local i=e.dump
local _=e.byte
local f={TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,TK_STRING=true,TK_LSTRING=true,TK_OP=true,TK_EOS=true,}local t,e,r
function init(o,l,n)t=o
e=l
r=n
end
local function a(n)e.init(n)e.llex()local l,t=e.tok,e.seminfo
local e,n={},{}for o=1,#l do
local l=l[o]if f[l]then
e[#e+1]=l
n[#n+1]=t[o]end
end
return e,n
end
function source(n,f)local function s(e)local e=d("return "..e,"z")if e then
return i(e)end
end
local function o(e)if t.DETAILS then l.print("SRCEQUIV: "..e)end
r.SRC_EQUIV=true
end
local e,d=a(n)local l,r=a(f)local n=c(n,"^(#[^\r\n]*)")local a=c(f,"^(#[^\r\n]*)")if n or a then
if not n or not a or n~=a then
o("shbang lines different")end
end
if#e~=#l then
o("count "..#e.." "..#l)return
end
for n=1,#e do
local e,i=e[n],l[n]local a,l=d[n],r[n]if e~=i then
o("type ["..n.."] "..e.." "..i)break
end
if e=="TK_KEYWORD"or e=="TK_NAME"or e=="TK_OP"then
if e=="TK_NAME"and t["opt-locals"]then
elseif a~=l then
o("seminfo ["..n.."] "..e.." "..a.." "..l)break
end
elseif e=="TK_EOS"then
else
local t,i=s(a),s(l)if not t or not i or t~=i then
o("seminfo ["..n.."] "..e.." "..a.." "..l)break
end
end
end
end
function binary(a,o)local e=0
local N=1
local I=3
local v=4
local function e(e)if t.DETAILS then l.print("BINEQUIV: "..e)end
r.BIN_EQUIV=true
end
local function l(e)local n=c(e,"^(#[^\r\n]*\r?\n?)")if n then
e=s(e,#n+1)end
return e
end
local n=d(l(a),"z")if not n then
e("failed to compile original sources for binary chunk comparison")return
end
local l=d(l(o),"z")if not l then
e("failed to compile compressed result for binary chunk comparison")end
local t={i=1,dat=i(n)}t.len=#t.dat
local c={i=1,dat=i(l)}c.len=#c.dat
local K,d,u,m,T,o,h
local function r(e,n)if e.i+n-1>e.len then return end
return true
end
local function p(n,e)if not e then e=1 end
n.i=n.i+e
end
local function a(n)local e=n.i
if e>n.len then return end
local l=s(n.dat,e,e)n.i=e+1
return _(l)end
local function L(l)local n,e=0,1
if not r(l,d)then return end
for o=1,d do
n=n+e*a(l)e=e*256
end
return n
end
local function O(n)local e=0
if not r(n,d)then return end
for l=1,d do
e=e*256+a(n)end
return e
end
local function k(l)local n,e=0,1
if not r(l,u)then return end
for o=1,u do
n=n+e*a(l)e=e*256
end
return n
end
local function g(n)local e=0
if not r(n,u)then return end
for l=1,u do
e=e*256+a(n)end
return e
end
local function f(e,o)local n=e.i
local l=n+o-1
if l>e.len then return end
local l=s(e.dat,n,l)e.i=n+o
return l
end
local function i(n)local e=h(n)if not e then return end
if e==0 then return""end
return f(n,e)end
local function _(e,n)local e,n=a(e),a(n)if not e or not n or e~=n then
return
end
return e
end
local function s(e,n)local e=_(e,n)if not e then return true end
end
local function b(e,n)local e,n=o(e),o(n)if not e or not n or e~=n then
return
end
return e
end
local function E(l,n)if not i(l)or not i(n)then
e("bad source name");return
end
if not o(l)or not o(n)then
e("bad linedefined");return
end
if not o(l)or not o(n)then
e("bad lastlinedefined");return
end
if not(r(l,4)and r(n,4))then
e("prototype header broken")end
if s(l,n)then
e("bad nups");return
end
if s(l,n)then
e("bad numparams");return
end
if s(l,n)then
e("bad is_vararg");return
end
if s(l,n)then
e("bad maxstacksize");return
end
local t=b(l,n)if not t then
e("bad ncode");return
end
local a=f(l,t*m)local t=f(n,t*m)if not a or not t or a~=t then
e("bad code block");return
end
local t=b(l,n)if not t then
e("bad nconst");return
end
for o=1,t do
local o=_(l,n)if not o then
e("bad const type");return
end
if o==N then
if s(l,n)then
e("bad boolean value");return
end
elseif o==I then
local l=f(l,T)local n=f(n,T)if not l or not n or l~=n then
e("bad number value");return
end
elseif o==v then
local l=i(l)local n=i(n)if not l or not n or l~=n then
e("bad string value");return
end
end
end
local t=b(l,n)if not t then
e("bad nproto");return
end
for o=1,t do
if not E(l,n)then
e("bad function prototype");return
end
end
local a=o(l)if not a then
e("bad sizelineinfo1");return
end
local t=o(n)if not t then
e("bad sizelineinfo2");return
end
if not f(l,a*d)then
e("bad lineinfo1");return
end
if not f(n,t*d)then
e("bad lineinfo2");return
end
local a=o(l)if not a then
e("bad sizelocvars1");return
end
local t=o(n)if not t then
e("bad sizelocvars2");return
end
for n=1,a do
if not i(l)or not o(l)or not o(l)then
e("bad locvars1");return
end
end
for l=1,t do
if not i(n)or not o(n)or not o(n)then
e("bad locvars2");return
end
end
local t=o(l)if not t then
e("bad sizeupvalues1");return
end
local o=o(n)if not o then
e("bad sizeupvalues2");return
end
for n=1,t do
if not i(l)then e("bad upvalues1");return end
end
for l=1,o do
if not i(n)then e("bad upvalues2");return end
end
return true
end
if not(r(t,12)and r(c,12))then
e("header broken")end
p(t,6)K=a(t)d=a(t)u=a(t)m=a(t)T=a(t)p(t)p(c,12)if K==1 then
o=L
h=k
else
o=O
h=g
end
E(t,c)if t.i~=t.len+1 then
e("inconsistent binary chunk1");return
elseif c.i~=c.len+1 then
e("inconsistent binary chunk2");return
end
end
end
b["plugin/html"]=function()module"plugin/html"local n=l.require"string"local u=l.require"table"local s=l.require"io"local f=".html"local h={["&"]="&amp;",["<"]="&lt;",[">"]="&gt;",["'"]="&apos;",['"']="&quot;",}local m=[[
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
]]local T=[[
</pre>
</body>
</html>
]]local p=[[
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
]]local a
local e,o
local t,d,r
local function i(...)if a.QUIET then return end
l.print(...)end
function init(i,t,r)a=i
e=t
local t,r=n.find(e,"%.[^%.%\\%/]*$")local i,c=e,""if t and t>1 then
i=n.sub(e,1,t-1)c=n.sub(e,t,r)end
o=i..f
if a.OUTPUT_FILE then
o=a.OUTPUT_FILE
end
if e==o then
l.error("output filename identical to input filename")end
end
function post_load(n)i([[
HTML plugin module for LuaSrcDiet
]])i("Exporting: "..e.." -> "..o.."\n")end
function post_lex(e,n,l)t,d,r=e,n,l
end
local function r(l)local e=1
while e<=#l do
local o=n.sub(l,e,e)local t=h[o]if t then
o=t
l=n.sub(l,1,e-1)..o..n.sub(l,e+1)end
e=e+#o
end
return l
end
local function h(n,o)local e=s.open(n,"wb")if not e then l.error('cannot open "'..n..'" for writing')end
local o=e:write(o)if not o then l.error('cannot write to "'..n..'"')end
e:close()end
function post_parse(f,s)local c={}local function i(e)c[#c+1]=e
end
local function l(e,n)i('<span class="'..e..'">'..n..'</span>')end
for e=1,#f do
local e=f[e]local e=e.xref
for n=1,#e do
local e=e[n]t[e]="TK_GLOBAL"end
end
for e=1,#s do
local e=s[e]local e=e.xref
for n=1,#e do
local e=e[n]t[e]="TK_LOCAL"end
end
i(n.format(m,r(e),p))for e=1,#t do
local e,n=t[e],d[e]if e=="TK_KEYWORD"then
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
i(T)h(o,u.concat(c))a.EXIT=true
end
end
b["plugin/sloc"]=function()module"plugin/sloc"local a=l.require"string"local e=l.require"table"local o
local r
function init(n,e,l)o=n
o.QUIET=true
r=e
end
local function i(o)local l={}local n,t=1,#o
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
function post_lex(n,c,d)local e,t=0,0
local function a(n)if n>e then
t=t+1;e=n
end
end
for e=1,#n do
local n,l,e=n[e],c[e],d[e]if n=="TK_KEYWORD"or n=="TK_NAME"or
n=="TK_NUMBER"or n=="TK_OP"then
a(e)elseif n=="TK_STRING"then
local n=i(l)e=e-#n+1
for n=1,#n do
a(e);e=e+1
end
elseif n=="TK_LSTRING"then
local n=i(l)e=e-#n+1
for l=1,#n do
if n[l]~=""then a(e)end
e=e+1
end
end
end
l.print(r..": "..t)o.EXIT=true
end
end
local o=k"llex"local s=k"lparser"local g=k"optlex"local v=k"optparser"local O=k"equiv"local l
local b=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.12.1 (20120407)  Copyright (c) 2012 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]local h=[[
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
%s]]local _=[[
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
]]local N=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
  --opt-srcequiv --opt-binequiv
]]local R=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]local S=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
  --opt-srcequiv --opt-binequiv
]]local x=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]local r="_"local w="plugin/"local function t(e)m("LuaSrcDiet (error): "..e);os.exit(1)end
if not X(_VERSION,"5.1",1,1)then
t("requires Lua 5.1 to run")end
local a=""do
local t=24
local n={}for l,o in Q(_,"%s*([^,]+),'([^']+)'")do
local e="  "..l
e=e..i.rep(" ",t-#e)..o.."\n"a=a..e
n[l]=true
n["--no"..p(l,3)]=true
end
_=n
end
h=i.format(h,a,N)if z then
local e="\nembedded plugins:\n"for n=1,#z do
local n=z[n]e=e.."  "..Z[n].."\n"end
h=h..e
end
local I=r
local e={}local r,a
local function T(n)for n in Q(n,"(%-%-%S+)")do
if p(n,3,4)=="no"and
_["--"..p(n,5)]then
e[p(n,5)]=false
else
e[p(n,3)]=true
end
end
end
local d={"TK_KEYWORD","TK_NAME","TK_NUMBER","TK_STRING","TK_LSTRING","TK_OP","TK_EOS","TK_COMMENT","TK_LCOMMENT","TK_EOL","TK_SPACE",}local u=7
local f={["\n"]="LF",["\r"]="CR",["\n\r"]="LFCR",["\r\n"]="CRLF",}local function c(e)local n=io.open(e,"rb")if not n then t('cannot open "'..e..'" for reading')end
local l=n:read("*a")if not l then t('cannot read from "'..e..'"')end
n:close()return l
end
local function A(n,l)local e=io.open(n,"wb")if not e then t('cannot open "'..n..'" for writing')end
local l=e:write(l)if not l then t('cannot write to "'..n..'"')end
e:close()end
local function L()r,a={},{}for e=1,#d do
local e=d[e]r[e],a[e]=0,0
end
end
local function K(e,n)r[e]=r[e]+1
a[e]=a[e]+#n
end
local function E()local function t(e,n)if e==0 then return 0 end
return n/e
end
local o={}local e,n=0,0
for l=1,u do
local l=d[l]e=e+r[l];n=n+a[l]end
r.TOTAL_TOK,a.TOTAL_TOK=e,n
o.TOTAL_TOK=t(e,n)e,n=0,0
for l=1,#d do
local l=d[l]e=e+r[l];n=n+a[l]o[l]=t(r[l],a[l])end
r.TOTAL_ALL,a.TOTAL_ALL=e,n
o.TOTAL_ALL=t(e,n)return o
end
local function M(e)local e=c(e)o.init(e)o.llex()local e,l=o.tok,o.seminfo
for n=1,#e do
local n,e=e[n],l[n]if n=="TK_OP"and i.byte(e)<32 then
e="("..i.byte(e)..")"elseif n=="TK_EOL"then
e=f[e]else
e="'"..e.."'"end
m(n.." "..e)end
end
local function C(e)local n=m
local e=c(e)o.init(e)o.llex()local e,o,l=o.tok,o.seminfo,o.tokln
s.init(e,o,l)local e=s.parser()local l,t=e.globalinfo,e.localinfo
local o=i.rep("-",72)n("*** Local/Global Variable Tracker Tables ***")n(o.."\n GLOBALS\n"..o)for e=1,#l do
local l=l[e]local e="("..e..") '"..l.name.."' -> "local l=l.xref
for o=1,#l do e=e..l[o].." "end
n(e)end
n(o.."\n LOCALS (decl=declared act=activated rem=removed)\n"..o)for e=1,#t do
local l=t[e]local e="("..e..") '"..l.name.."' decl:"..l.decl.." act:"..l.act.." rem:"..l.rem
if l.isself then
e=e.." isself"end
e=e.." -> "local l=l.xref
for o=1,#l do e=e..l[o].." "end
n(e)end
n(o.."\n")end
local function P(l)local e=m
local n=c(l)o.init(n)o.llex()local n,o=o.tok,o.seminfo
e(b)e("Statistics for: "..l.."\n")L()for e=1,#n do
local e,n=n[e],o[e]K(e,n)end
local n=E()local l=i.format
local function c(e)return r[e],a[e],n[e]end
local t,o="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"local n=i.rep("-",42)e(l(t,"Lexical","Input","Input","Input"))e(l(t,"Elements","Count","Bytes","Average"))e(n)for t=1,#d do
local t=d[t]e(l(o,t,c(t)))if t=="TK_EOS"then e(n)end
end
e(n)e(l(o,"Total Elements",c("TOTAL_ALL")))e(n)e(l(o,"Total Tokens",c("TOTAL_TOK")))e(n.."\n")end
local function y(p,T)local function n(...)if e.QUIET then return end
_G.print(...)end
if l and l.init then
e.EXIT=false
l.init(e,p,T)if e.EXIT then return end
end
n(b)local u=c(p)if l and l.post_load then
u=l.post_load(u)or u
if e.EXIT then return end
end
o.init(u)o.llex()local c,f,h=o.tok,o.seminfo,o.tokln
if l and l.post_lex then
l.post_lex(c,f,h)if e.EXIT then return end
end
L()for e=1,#c do
local n,e=c[e],f[e]K(n,e)end
local _=E()local b,m=r,a
v.print=n
s.init(c,f,h)local s=s.parser()if l and l.post_parse then
l.post_parse(s.globalinfo,s.localinfo)if e.EXIT then return end
end
v.optimize(e,c,f,s)if l and l.post_optparse then
l.post_optparse()if e.EXIT then return end
end
local s=g.warn
g.print=n
c,f,h=g.optimize(e,c,f,h)if l and l.post_optlex then
l.post_optlex(c,f,h)if e.EXIT then return end
end
local l=ee.concat(f)if i.find(l,"\r\n",1,1)or
i.find(l,"\n\r",1,1)then
s.MIXEDEOL=true
end
O.init(e,o,s)O.source(u,l)O.binary(u,l)local h="before and after lexer streams are NOT equivalent!"local u="before and after binary chunks are NOT equivalent!"if s.SRC_EQUIV then
if e["opt-srcequiv"]then t(h)end
else
n("*** SRCEQUIV: token streams are sort of equivalent")if e["opt-locals"]then
n("(but no identifier comparisons since --opt-locals enabled)")end
n()end
if s.BIN_EQUIV then
if e["opt-binequiv"]then t(u)end
else
n("*** BINEQUIV: binary chunks are sort of equivalent")n()end
A(T,l)L()for e=1,#c do
local e,n=c[e],f[e]K(e,n)end
local o=E()n("Statistics for: "..p.." -> "..T.."\n")local l=i.format
local function c(e)return b[e],m[e],_[e],r[e],a[e],o[e]end
local o,t="%-16s%8s%8s%10s%8s%8s%10s","%-16s%8d%8d%10.2f%8d%8d%10.2f"local e=i.rep("-",68)n("*** lexer-based optimizations summary ***\n"..e)n(l(o,"Lexical","Input","Input","Input","Output","Output","Output"))n(l(o,"Elements","Count","Bytes","Average","Count","Bytes","Average"))n(e)for o=1,#d do
local o=d[o]n(l(t,o,c(o)))if o=="TK_EOS"then n(e)end
end
n(e)n(l(t,"Total Elements",c("TOTAL_ALL")))n(e)n(l(t,"Total Tokens",c("TOTAL_TOK")))n(e)if s.LSTRING then
n("* WARNING: "..s.LSTRING)elseif s.MIXEDEOL then
n("* WARNING: ".."output still contains some CRLF or LFCR line endings")elseif s.SRC_EQUIV then
n("* WARNING: "..h)elseif s.BIN_EQUIV then
n("* WARNING: "..u)end
n()end
local c={...}local r={}T(N)local function f(a)for n=1,#a do
local n=a[n]local l
local o,c=i.find(n,"%.[^%.%\\%/]*$")local r,i=n,""if o and o>1 then
r=p(n,1,o-1)i=p(n,o,c)end
l=r..I..i
if#a==1 and e.OUTPUT_FILE then
l=e.OUTPUT_FILE
end
if n==l then
t("output filename identical to input filename")end
if e.DUMP_LEXER then
M(n)elseif e.DUMP_PARSER then
C(n)elseif e.READ_ONLY then
P(n)else
y(n,l)end
end
end
local function d()local n,o=#c,1
if n==0 then
e.HELP=true
end
while o<=n do
local n,a=c[o],c[o+1]local i=X(n,"^%-%-?")if i=="-"then
if n=="-h"then
e.HELP=true;break
elseif n=="-v"then
e.VERSION=true;break
elseif n=="-s"then
if not a then t("-s option needs suffix specification")end
I=a
o=o+1
elseif n=="-o"then
if not a then t("-o option needs a file name")end
e.OUTPUT_FILE=a
o=o+1
elseif n=="-"then
break
else
t("unrecognized option "..n)end
elseif i=="--"then
if n=="--help"then
e.HELP=true;break
elseif n=="--version"then
e.VERSION=true;break
elseif n=="--keep"then
if not a then t("--keep option needs a string to match for")end
e.KEEP=a
o=o+1
elseif n=="--plugin"then
if not a then t("--plugin option needs a module name")end
if e.PLUGIN then t("only one plugin can be specified")end
e.PLUGIN=a
l=k(w..a)o=o+1
elseif n=="--quiet"then
e.QUIET=true
elseif n=="--read-only"then
e.READ_ONLY=true
elseif n=="--basic"then
T(R)elseif n=="--maximum"then
T(S)elseif n=="--none"then
T(x)elseif n=="--dump-lexer"then
e.DUMP_LEXER=true
elseif n=="--dump-parser"then
e.DUMP_PARSER=true
elseif n=="--details"then
e.DETAILS=true
elseif _[n]then
T(n)else
t("unrecognized option "..n)end
else
r[#r+1]=n
end
o=o+1
end
if e.HELP then
m(b..h);return true
elseif e.VERSION then
m(b);return true
end
if#r>0 then
if#r>1 and e.OUTPUT_FILE then
t("with -o, only one source file can be specified")end
f(r)return true
else
t("nothing to do!")end
end
if not d()then
t("Please run with option -h or --help for usage information")end