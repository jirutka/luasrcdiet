#!/usr/bin/env lua
local s=string
local e=math
local ee=table
local j=require
local y=print
local f=s.sub
local G=s.gmatch
local B=s.match
local p=package.preload
local a=_G
local Z={
html="html    generates a HTML file for checking globals",
sloc="sloc    calculates SLOC for given source file",
}
local W={
'html',
'sloc',
}
p.llex=
function()
module"llex"
local h=a.require"string"
local u=h.find
local c=h.match
local n=h.sub
local f={}
for e in h.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]],"%S+")do
f[e]=true
end
local e,
l,
o,
s,
r
local function i(t,a)
local e=#tok+1
tok[e]=t
seminfo[e]=a
tokln[e]=r
end
local function d(t,s)
local n=n
local a=n(e,t,t)
t=t+1
local e=n(e,t,t)
if(e=="\n"or e=="\r")and(e~=a)then
t=t+1
a=a..e
end
if s then i("TK_EOL",a)end
r=r+1
o=t
return t
end
function init(a,t)
e=a
l=t
o=1
r=1
tok={}
seminfo={}
tokln={}
local a,n,e,t=u(e,"^(#[^\r\n]*)(\r?\n?)")
if a then
o=o+#e
i("TK_COMMENT",e)
if#t>0 then d(o,true)end
end
end
function chunkid()
if l and c(l,"^[=@]")then
return n(l,2)
end
return"[string]"
end
function errorline(o,t)
local e=error or a.error
e(h.format("%s:%d: %s",chunkid(),t or r,o))
end
local r=errorline
local function m(t)
local i=n
local n=i(e,t,t)
t=t+1
local a=#c(e,"=*",t)
t=t+a
o=t
return(i(e,t,t)==n)and a or(-a)-1
end
local function w(h,l)
local t=o+1
local i=n
local a=i(e,t,t)
if a=="\r"or a=="\n"then
t=d(t)
end
while true do
local a,u,n=u(e,"([\r\n%]])",t)
if not a then
r(h and"unfinished long string"or
"unfinished long comment")
end
t=a
if n=="]"then
if m(t)==l then
s=i(e,s,o)
o=o+1
return s
end
t=o
else
s=s.."\n"
t=d(t)
end
end
end
local function y(l)
local t=o
local h=u
local n=n
while true do
local i,u,a=h(e,"([\n\r\\\"\'])",t)
if i then
if a=="\n"or a=="\r"then
r("unfinished string")
end
t=i
if a=="\\"then
t=t+1
a=n(e,t,t)
if a==""then break end
i=h("abfnrtv\n\r",a,1,true)
if i then
if i>7 then
t=d(t)
else
t=t+1
end
elseif h(a,"%D")then
t=t+1
else
local o,e,a=h(e,"^(%d%d?%d?)",t)
t=e+1
if a+1>256 then
r("escape sequence too large")
end
end
else
t=t+1
if a==l then
o=t
return n(e,s,t-1)
end
end
else
break
end
end
r("unfinished string")
end
function llex()
local h=u
local l=c
while true do
local t=o
while true do
local c,p,u=h(e,"^([_%a][_%w]*)",t)
if c then
o=t+#u
if f[u]then
i("TK_KEYWORD",u)
else
i("TK_NAME",u)
end
break
end
local u,f,c=h(e,"^(%.?)%d",t)
if u then
if c=="."then t=t+1 end
local c,s,d=h(e,"^%d*[%.%d]*([eE]?)",t)
t=s+1
if#d==1 then
if l(e,"^[%+%-]",t)then
t=t+1
end
end
local s,t=h(e,"^[_%w]*",t)
o=t+1
local e=n(e,u,t)
if not a.tonumber(e)then
r("malformed number")
end
i("TK_NUMBER",e)
break
end
local c,f,u,a=h(e,"^((%s)[ \t\v\f]*)",t)
if c then
if a=="\n"or a=="\r"then
d(t,true)
else
o=f+1
i("TK_SPACE",u)
end
break
end
local a=l(e,"^%p",t)
if a then
s=t
local d=h("-[\"\'.=<>~",a,1,true)
if d then
if d<=2 then
if d==1 then
local r=l(e,"^%-%-(%[?)",t)
if r then
t=t+2
local a=-1
if r=="["then
a=m(t)
end
if a>=0 then
i("TK_LCOMMENT",w(false,a))
else
o=h(e,"[\n\r]",t)or(#e+1)
i("TK_COMMENT",n(e,s,o-1))
end
break
end
else
local e=m(t)
if e>=0 then
i("TK_LSTRING",w(true,e))
elseif e==-1 then
i("TK_OP","[")
else
r("invalid long string delimiter")
end
break
end
elseif d<=5 then
if d<5 then
o=t+1
i("TK_STRING",y(a))
break
end
a=l(e,"^%.%.?%.?",t)
else
a=l(e,"^%p=?",t)
end
end
o=t+#a
i("TK_OP",a)
break
end
local e=n(e,t,t)
if e~=""then
o=t+1
i("TK_OP",e)
break
end
i("TK_EOS","")
return
end
end
end
end
p.lparser=
function()
module"lparser"
local v=a.require"string"
local E,
k,
A,
S,
s,
u,
Y,
t,T,d,f,
y,
o,
P,
_,
D,
l,
b,
I,
z
local q,r,g,N,O,x
local e=v.gmatch
local R={}
for e in e("else elseif end until <eof>","%S+")do
R[e]=true
end
local H={}
local V={}
for e,a,t in e([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")do
H[e]=a+0
V[e]=t+0
end
local te={["not"]=true,["-"]=true,
["#"]=true,}
local ee=8
local function i(e,t)
local a=error or a.error
a(v.format("(source):%d: %s",t or d,e))
end
local function e()
Y=A[s]
t,T,d,f
=E[s],k[s],A[s],S[s]
s=s+1
end
local function Z()
return E[s]
end
local function h(a)
local e=t
if e~="<number>"and e~="<string>"then
if e=="<name>"then e=T end
e="'"..e.."'"
end
i(a.." near "..e)
end
local function m(e)
h("'"..e.."' expected")
end
local function i(a)
if t==a then e();return true end
end
local function M(e)
if t~=e then m(e)end
end
local function n(t)
M(t);e()
end
local function X(e,t)
if not e then h(t)end
end
local function c(e,a,t)
if not i(e)then
if t==d then
m(e)
else
h("'"..e.."' expected (to close '"..a.."' at line "..t..")")
end
end
end
local function w()
M("<name>")
local t=T
y=f
e()
return t
end
local function F(e,t)
e.k="VK"
end
local function U(e)
F(e,w())
end
local function m(i,a)
local t=o.bl
local e
if t then
e=t.locallist
else
e=o.locallist
end
local t=#l+1
l[t]={
name=i,
xref={y},
decl=y,
}
if a then
l[t].isself=true
end
local a=#b+1
b[a]=t
I[a]=e
end
local function j(e)
local t=#b
while e>0 do
e=e-1
local e=t-e
local a=b[e]
local t=l[a]
local o=t.name
t.act=f
b[e]=nil
local i=I[e]
I[e]=nil
local e=i[o]
if e then
t=l[e]
t.rem=-a
end
i[o]=a
end
end
local function L()
local t=o.bl
local e
if t then
e=t.locallist
else
e=o.locallist
end
for t,e in a.pairs(e)do
local e=l[e]
e.rem=f
end
end
local function f(e,t)
if v.sub(e,1,1)=="("then
return
end
m(e,t)
end
local function C(o,a)
local t=o.bl
local e
if t then
e=t.locallist
while e do
if e[a]then return e[a]end
t=t.prev
e=t and t.locallist
end
end
e=o.locallist
return e[a]or-1
end
local function v(t,o,e)
if t==nil then
e.k="VGLOBAL"
return"VGLOBAL"
else
local a=C(t,o)
if a>=0 then
e.k="VLOCAL"
e.id=a
return"VLOCAL"
else
if v(t.prev,o,e)=="VGLOBAL"then
return"VGLOBAL"
end
e.k="VUPVAL"
return"VUPVAL"
end
end
end
local function K(a)
local t=w()
v(o,t,a)
if a.k=="VGLOBAL"then
local e=D[t]
if not e then
e=#_+1
_[e]={
name=t,
xref={y},
}
D[t]=e
else
local e=_[e].xref
e[#e+1]=y
end
else
local e=a.id
local e=l[e].xref
e[#e+1]=y
end
end
local function y(t)
local e={}
e.isbreakable=t
e.prev=o.bl
e.locallist={}
o.bl=e
end
local function v()
local e=o.bl
L()
o.bl=e.prev
end
local function G()
local e
if not o then
e=P
else
e={}
end
e.prev=o
e.bl=nil
e.locallist={}
o=e
end
local function Q()
L()
o=o.prev
end
local function C(t)
local a={}
e()
U(a)
t.k="VINDEXED"
end
local function J(t)
e()
r(t)
n("]")
end
local function W(e)
local e,a={},{}
if t=="<name>"then
U(e)
else
J(e)
end
n("=")
r(a)
end
local function a(e)
if e.v.k=="VVOID"then return end
e.v.k="VVOID"
end
local function L(e)
r(e.v)
end
local function B(a)
local o=d
local e={}
e.v={}
e.t=a
a.k="VRELOCABLE"
e.v.k="VVOID"
n("{")
repeat
if t=="}"then break end
local t=t
if t=="<name>"then
if Z()~="="then
L(e)
else
W(e)
end
elseif t=="["then
W(e)
else
L(e)
end
until not i(",")and not i(";")
c("}","{",o)
end
local function Z()
local a=0
if t~=")"then
repeat
local t=t
if t=="<name>"then
m(w())
a=a+1
elseif t=="..."then
e()
o.is_vararg=true
else
h("<name> or '...' expected")
end
until o.is_vararg or not i(",")
end
j(a)
end
local function W(n)
local a={}
local i=d
local o=t
if o=="("then
if i~=Y then
h("ambiguous syntax (function call x new statement)")
end
e()
if t==")"then
a.k="VVOID"
else
q(a)
end
c(")","(",i)
elseif o=="{"then
B(a)
elseif o=="<string>"then
F(a,T)
e()
else
h("function arguments expected")
return
end
n.k="VCALL"
end
local function Y(a)
local t=t
if t=="("then
local t=d
e()
r(a)
c(")","(",t)
elseif t=="<name>"then
K(a)
else
h("unexpected symbol")
end
end
local function L(a)
Y(a)
while true do
local t=t
if t=="."then
C(a)
elseif t=="["then
local e={}
J(e)
elseif t==":"then
local t={}
e()
U(t)
W(a)
elseif t=="("or t=="<string>"or t=="{"then
W(a)
else
return
end
end
end
local function U(a)
local t=t
if t=="<number>"then
a.k="VKNUM"
elseif t=="<string>"then
F(a,T)
elseif t=="nil"then
a.k="VNIL"
elseif t=="true"then
a.k="VTRUE"
elseif t=="false"then
a.k="VFALSE"
elseif t=="..."then
X(o.is_vararg==true,
"cannot use '...' outside a vararg function");
a.k="VVARARG"
elseif t=="{"then
B(a)
return
elseif t=="function"then
e()
O(a,false,d)
return
else
L(a)
return
end
e()
end
local function T(o,i)
local a=t
local n=te[a]
if n then
e()
T(o,ee)
else
U(o)
end
a=t
local t=H[a]
while t and t>i do
local o={}
e()
local e=T(o,V[a])
a=e
t=H[a]
end
return a
end
function r(e)
T(e,0)
end
local function H(e)
local t={}
local e=e.v.k
X(e=="VLOCAL"or e=="VUPVAL"or e=="VGLOBAL"
or e=="VINDEXED","syntax error")
if i(",")then
local e={}
e.v={}
L(e.v)
H(e)
else
n("=")
q(t)
return
end
t.k="VNONRELOC"
end
local function a(e,t)
n("do")
y(false)
j(e)
g()
v()
end
local function U(e)
local t=u
f("(for index)")
f("(for limit)")
f("(for step)")
m(e)
n("=")
N()
n(",")
N()
if i(",")then
N()
else
end
a(1,true)
end
local function W(e)
local t={}
f("(for generator)")
f("(for state)")
f("(for control)")
m(e)
local e=1
while i(",")do
m(w())
e=e+1
end
n("in")
local o=u
q(t)
a(e,false)
end
local function F(e)
local a=false
K(e)
while t=="."do
C(e)
end
if t==":"then
a=true
C(e)
end
return a
end
function N()
local e={}
r(e)
end
local function a()
local e={}
r(e)
end
local function T()
e()
a()
n("then")
g()
end
local function N()
local t,e={}
m(w())
t.k="VLOCAL"
j(1)
O(e,false,d)
end
local function C()
local e=0
local t={}
repeat
m(w())
e=e+1
until not i(",")
if i("=")then
q(t)
else
t.k="VVOID"
end
j(e)
end
function q(e)
r(e)
while i(",")do
r(e)
end
end
function O(a,t,e)
G()
n("(")
if t then
f("self",true)
j(1)
end
Z()
n(")")
x()
c("end","function",e)
Q()
end
function g()
y(false)
x()
v()
end
local function f()
local o=u
y(true)
e()
local a=w()
local e=t
if e=="="then
U(a)
elseif e==","or e=="in"then
W(a)
else
h("'=' or 'in' expected")
end
c("end","for",o)
v()
end
local function m()
local t=u
e()
a()
y(true)
n("do")
g()
c("end","while",t)
v()
end
local function w()
local t=u
y(true)
y(false)
e()
x()
c("until","repeat",t)
a()
v()
v()
end
local function j()
local a=u
local o={}
T()
while t=="elseif"do
T()
end
if t=="else"then
e()
g()
end
c("end","if",a)
end
local function v()
local a={}
e()
local e=t
if R[e]or e==";"then
else
q(a)
end
end
local function y()
local t=o.bl
e()
while t and not t.isbreakable do
t=t.prev
end
if not t then
h("no loop to break")
end
end
local function r()
local t=s-1
local e={}
e.v={}
L(e.v)
if e.v.k=="VCALL"then
z[t]="call"
else
e.prev=nil
H(e)
z[t]="assign"
end
end
local function h()
local o=u
local a,t={},{}
e()
local e=F(a)
O(t,e,o)
end
local function a()
local t=u
e()
g()
c("end","do",t)
end
local function n()
e()
if i("function")then
N()
else
C()
end
end
local n={
["if"]=j,
["while"]=m,
["do"]=a,
["for"]=f,
["repeat"]=w,
["function"]=h,
["local"]=n,
["return"]=v,
["break"]=y,
}
local function a()
u=d
local e=t
local t=n[e]
if t then
z[s-1]=e
t()
if e=="return"or e=="break"then return true end
else
r()
end
return false
end
function x()
local e=false
while not e and not R[t]do
e=a()
i(";")
end
end
function parser()
G()
o.is_vararg=true
e()
x()
M("<eof>")
Q()
return{
globalinfo=_,
localinfo=l,
statinfo=z,
toklist=E,
seminfolist=k,
toklnlist=A,
xreflist=S,
}
end
function init(e,i,n)
s=1
P={}
local t=1
E,k,A,S={},{},{},{}
for a=1,#e do
local e=e[a]
local o=true
if e=="TK_KEYWORD"or e=="TK_OP"then
e=i[a]
elseif e=="TK_NAME"then
e="<name>"
k[t]=i[a]
elseif e=="TK_NUMBER"then
e="<number>"
k[t]=0
elseif e=="TK_STRING"or e=="TK_LSTRING"then
e="<string>"
k[t]=""
elseif e=="TK_EOS"then
e="<eof>"
else
o=false
end
if o then
E[t]=e
A[t]=n[a]
S[t]=a
t=t+1
end
end
_,D,l={},{},{}
b,I={},{}
z={}
end
end
p.optlex=
function()
module"optlex"
local c=a.require"string"
local i=c.match
local e=c.sub
local h=c.find
local d=c.rep
local f
error=a.error
warn={}
local n,o,l
local y={
TK_KEYWORD=true,
TK_NAME=true,
TK_NUMBER=true,
TK_STRING=true,
TK_LSTRING=true,
TK_OP=true,
TK_EOS=true,
}
local v={
TK_COMMENT=true,
TK_LCOMMENT=true,
TK_EOL=true,
TK_SPACE=true,
}
local r
local function b(e)
local t=n[e-1]
if e<=1 or t=="TK_EOL"then
return true
elseif t==""then
return b(e-1)
end
return false
end
local function g(t)
local e=n[t+1]
if t>=#n or e=="TK_EOL"or e=="TK_EOS"then
return true
elseif e==""then
return g(t+1)
end
return false
end
local function A(a)
local t=#i(a,"^%-%-%[=*%[")
local a=e(a,t+1,-(t-1))
local e,t=1,0
while true do
local a,n,i,o=h(a,"([\r\n])([\r\n]?)",e)
if not a then break end
e=a+1
t=t+1
if#o>0 and i~=o then
e=e+1
end
end
return t
end
local function k(s,h)
local a=i
local t,e=n[s],n[h]
if t=="TK_STRING"or t=="TK_LSTRING"or
e=="TK_STRING"or e=="TK_LSTRING"then
return""
elseif t=="TK_OP"or e=="TK_OP"then
if(t=="TK_OP"and(e=="TK_KEYWORD"or e=="TK_NAME"))or
(e=="TK_OP"and(t=="TK_KEYWORD"or t=="TK_NAME"))then
return""
end
if t=="TK_OP"and e=="TK_OP"then
local t,e=o[s],o[h]
if(a(t,"^%.%.?$")and a(e,"^%."))or
(a(t,"^[~=<>]$")and e=="=")or
(t=="["and(e=="["or e=="="))then
return" "
end
return""
end
local t=o[s]
if e=="TK_OP"then t=o[h]end
if a(t,"^%.%.?%.?$")then
return" "
end
return""
else
return" "
end
end
local function w()
local h,s,a={},{},{}
local e=1
for t=1,#n do
local i=n[t]
if i~=""then
h[e],s[e],a[e]=i,o[t],l[t]
e=e+1
end
end
n,o,l=h,s,a
end
local function O(h)
local t=o[h]
local t=t
local n
if i(t,"^0[xX]")then
local e=a.tostring(a.tonumber(t))
if#e<=#t then
t=e
else
return
end
end
if i(t,"^%d+%.?0*$")then
t=i(t,"^(%d+)%.?0*$")
if t+0>0 then
t=i(t,"^0*([1-9]%d*)$")
local o=#i(t,"0*$")
local a=a.tostring(o)
if o>#a+1 then
t=e(t,1,#t-o).."e"..a
end
n=t
else
n="0"
end
elseif not i(t,"[eE]")then
local o,t=i(t,"^(%d*)%.(%d+)$")
if o==""then o=0 end
if t+0==0 and o==0 then
n="0"
else
local s=#i(t,"0*$")
if s>0 then
t=e(t,1,#t-s)
end
if o+0>0 then
n=o.."."..t
else
n="."..t
local o=#i(t,"^0*")
local o=#t-o
local a=a.tostring(#t)
if o+2+#a<1+#t then
n=e(t,-o).."e-"..a
end
end
end
else
local t,o=i(t,"^([^eE]+)[eE]([%+%-]?%d+)$")
o=a.tonumber(o)
local s,h=i(t,"^(%d*)%.(%d*)$")
if s then
o=o-#h
t=s..h
end
if t+0==0 then
n="0"
else
local s=#i(t,"^0*")
t=e(t,s+1)
s=#i(t,"0*$")
if s>0 then
t=e(t,1,#t-s)
o=o+s
end
local a=a.tostring(o)
if o==0 then
n=t
elseif o>0 and(o<=1+#a)then
n=t..d("0",o)
elseif o<0 and(o>=-#t)then
s=#t+o
n=e(t,1,s).."."..e(t,s+1)
elseif o<0 and(#a>=-o-#t)then
s=-o-#t
n="."..d("0",s)..t
else
n=t.."e"..o
end
end
end
if n and n~=o[h]then
if r then
f("<number> (line "..l[h]..") "..o[h].." -> "..n)
r=r+1
end
o[h]=n
end
end
local function E(u)
local t=o[u]
local s=e(t,1,1)
local w=(s=="'")and'"'or"'"
local t=e(t,2,-2)
local a=1
local m,d=0,0
while a<=#t do
local u=e(t,a,a)
if u=="\\"then
local o=a+1
local r=e(t,o,o)
local n=h("abfnrtv\\\n\r\"\'0123456789",r,1,true)
if not n then
t=e(t,1,a-1)..e(t,o)
a=a+1
elseif n<=8 then
a=a+2
elseif n<=10 then
local i=e(t,o,o+1)
if i=="\r\n"or i=="\n\r"then
t=e(t,1,a).."\n"..e(t,o+2)
elseif n==10 then
t=e(t,1,a).."\n"..e(t,o+1)
end
a=a+2
elseif n<=12 then
if r==s then
m=m+1
a=a+2
else
d=d+1
t=e(t,1,a-1)..e(t,o)
a=a+1
end
else
local n=i(t,"^(%d%d?%d?)",o)
o=a+1+#n
local l=n+0
local r=c.char(l)
local h=h("\a\b\f\n\r\t\v",r,1,true)
if h then
n="\\"..e("abfnrtv",h,h)
elseif l<32 then
if i(e(t,o,o),"%d")then
n="\\"..n
else
n="\\"..l
end
elseif r==s then
n="\\"..r
m=m+1
elseif r=="\\"then
n="\\\\"
else
n=r
if r==w then
d=d+1
end
end
t=e(t,1,a-1)..n..e(t,o)
a=a+#n
end
else
a=a+1
if u==w then
d=d+1
end
end
end
if m>d then
a=1
while a<=#t do
local o,n,i=h(t,"([\'\"])",a)
if not o then break end
if i==s then
t=e(t,1,o-2)..e(t,o)
a=o
else
t=e(t,1,o-1).."\\"..e(t,o)
a=o+2
end
end
s=w
end
t=s..t..s
if t~=o[u]then
if r then
f("<string> (line "..l[u]..") "..o[u].." -> "..t)
r=r+1
end
o[u]=t
end
end
local function T(u)
local t=o[u]
local r=i(t,"^%[=*%[")
local a=#r
local c=e(t,-a,-1)
local s=e(t,a+1,-(a+1))
local n=""
local t=1
while true do
local a,o,r,h=h(s,"([\r\n])([\r\n]?)",t)
local o
if not a then
o=e(s,t)
elseif a>=t then
o=e(s,t,a-1)
end
if o~=""then
if i(o,"%s+$")then
warn.LSTRING="trailing whitespace in long string near line "..l[u]
end
n=n..o
end
if not a then
break
end
t=a+1
if a then
if#h>0 and r~=h then
t=t+1
end
if not(t==1 and t==a)then
n=n.."\n"
end
end
end
if a>=3 then
local e,t=a-1
while e>=2 do
local a="%]"..d("=",e-2).."%]"
if not i(n,a)then t=e end
e=e-1
end
if t then
a=d("=",t-2)
r,c="["..a.."[","]"..a.."]"
end
end
o[u]=r..n..c
end
local function q(u)
local a=o[u]
local r=i(a,"^%-%-%[=*%[")
local t=#r
local l=e(a,-(t-2),-1)
local s=e(a,t+1,-(t-1))
local n=""
local a=1
while true do
local o,t,r,h=h(s,"([\r\n])([\r\n]?)",a)
local t
if not o then
t=e(s,a)
elseif o>=a then
t=e(s,a,o-1)
end
if t~=""then
local a=i(t,"%s*$")
if#a>0 then t=e(t,1,-(a+1))end
n=n..t
end
if not o then
break
end
a=o+1
if o then
if#h>0 and r~=h then
a=a+1
end
n=n.."\n"
end
end
t=t-2
if t>=3 then
local e,a=t-1
while e>=2 do
local t="%]"..d("=",e-2).."%]"
if not i(n,t)then a=e end
e=e-1
end
if a then
t=d("=",a-2)
r,l="--["..t.."[","]"..t.."]"
end
end
o[u]=r..n..l
end
local function j(a)
local t=o[a]
local i=i(t,"%s*$")
if#i>0 then
t=e(t,1,-(i+1))
end
o[a]=t
end
local function _(o,t)
if not o then return false end
local a=i(t,"^%-%-%[=*%[")
local a=#a
local i=e(t,-a,-1)
local e=e(t,a+1,-(a-1))
if h(e,o,1,true)then
return true
end
end
function optimize(t,s,i,h)
local c=t["opt-comments"]
local u=t["opt-whitespace"]
local m=t["opt-emptylines"]
local p=t["opt-eols"]
local z=t["opt-strings"]
local I=t["opt-numbers"]
local x=t["opt-experimental"]
local N=t.KEEP
r=t.DETAILS and 0
f=f or a.print
if p then
c=true
u=true
m=true
elseif x then
u=true
end
n,o,l
=s,i,h
local t=1
local a,h
local s
local function i(i,a,e)
e=e or t
n[e]=i or""
o[e]=a or""
end
if x then
while true do
a,h=n[t],o[t]
if a=="TK_EOS"then
break
elseif a=="TK_OP"and h==";"then
i("TK_SPACE"," ")
end
t=t+1
end
w()
end
t=1
while true do
a,h=n[t],o[t]
local r=b(t)
if r then s=nil end
if a=="TK_EOS"then
break
elseif a=="TK_KEYWORD"or
a=="TK_NAME"or
a=="TK_OP"then
s=t
elseif a=="TK_NUMBER"then
if I then
O(t)
end
s=t
elseif a=="TK_STRING"or
a=="TK_LSTRING"then
if z then
if a=="TK_STRING"then
E(t)
else
T(t)
end
end
s=t
elseif a=="TK_COMMENT"then
if c then
if t==1 and e(h,1,1)=="#"then
j(t)
else
i()
end
elseif u then
j(t)
end
elseif a=="TK_LCOMMENT"then
if _(N,h)then
if u then
q(t)
end
s=t
elseif c then
local e=A(h)
if v[n[t+1]]then
i()
a=""
else
i("TK_SPACE"," ")
end
if not m and e>0 then
i("TK_EOL",d("\n",e))
end
if u and a~=""then
t=t-1
end
else
if u then
q(t)
end
s=t
end
elseif a=="TK_EOL"then
if r and m then
i()
elseif h=="\r\n"or h=="\n\r"then
i("TK_EOL","\n")
end
elseif a=="TK_SPACE"then
if u then
if r or g(t)then
i()
else
local a=n[s]
if a=="TK_LCOMMENT"then
i()
else
local e=n[t+1]
if v[e]then
if(e=="TK_COMMENT"or e=="TK_LCOMMENT")and
a=="TK_OP"and o[s]=="-"then
else
i()
end
else
local e=k(s,t+1)
if e==""then
i()
else
i("TK_SPACE"," ")
end
end
end
end
end
else
error("unidentified token encountered")
end
t=t+1
end
w()
if p then
t=1
if n[1]=="TK_COMMENT"then
t=3
end
while true do
a,h=n[t],o[t]
if a=="TK_EOS"then
break
elseif a=="TK_EOL"then
local a,e=n[t-1],n[t+1]
if y[a]and y[e]then
local t=k(t-1,t+1)
if t==""or e=="TK_EOS"then
i()
end
end
end
t=t+1
end
w()
end
if r and r>0 then f()end
return n,o,l
end
end
p.optparser=
function()
module"optparser"
local n=a.require"string"
local g=a.require"table"
local i="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"
local d="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"
local A={}
for e in n.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]],"%S+")do
A[e]=true
end
local h,c,
s,k,v,
_,o,
w,
b,O,
q,
r
local function z(e)
local i={}
for n=1,#e do
local t=e[n]
local o=t.name
if not i[o]then
i[o]={
decl=0,token=0,size=0,
}
end
local e=i[o]
e.decl=e.decl+1
local i=t.xref
local a=#i
e.token=e.token+a
e.size=e.size+a*#o
if t.decl then
t.id=n
t.xcount=a
if a>1 then
t.first=i[2]
t.last=i[a]
end
else
e.id=n
end
end
return i
end
local function I(e)
local s=n.byte
local n=n.char
local t={
TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,
TK_STRING=true,TK_LSTRING=true,
}
if not e["opt-comments"]then
t.TK_COMMENT=true
t.TK_LCOMMENT=true
end
local a={}
for e=1,#h do
a[e]=c[e]
end
for e=1,#o do
local e=o[e]
local t=e.xref
for e=1,e.xcount do
local e=t[e]
a[e]=""
end
end
local e={}
for t=0,255 do e[t]=0 end
for o=1,#h do
local o,a=h[o],a[o]
if t[o]then
for t=1,#a do
local t=s(a,t)
e[t]=e[t]+1
end
end
end
local function a(o)
local t={}
for a=1,#o do
local o=s(o,a)
t[a]={c=o,freq=e[o],}
end
g.sort(t,
function(t,e)
return t.freq>e.freq
end
)
local e={}
for a=1,#t do
e[a]=n(t[a].c)
end
return g.concat(e)
end
i=a(i)
d=a(d)
end
local function S()
local t
local s,h=#i,#d
local e=q
if e<s then
e=e+1
t=n.sub(i,e,e)
else
local o,a=s,1
repeat
e=e-o
o=o*h
a=a+1
until o>e
local o=e%s
e=(e-o)/s
o=o+1
t=n.sub(i,o,o)
while a>1 do
local o=e%h
e=(e-o)/h
o=o+1
t=t..n.sub(d,o,o)
a=a-1
end
end
q=q+1
return t,b[t]~=nil
end
local function N(T,I,O,i)
local e=y or a.print
local t=n.format
local f=i.DETAILS
if i.QUIET then return end
local w,y,p,A,_,
j,v,m,E,z,
s,c,l,q,x,
h,u,d,b,k
=0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0
local function i(e,t)
if e==0 then return 0 end
return t/e
end
for t,e in a.pairs(T)do
w=w+1
s=s+e.token
h=h+e.size
end
for t,e in a.pairs(I)do
y=y+1
v=v+e.decl
c=c+e.token
u=u+e.size
end
for t,e in a.pairs(O)do
p=p+1
m=m+e.decl
l=l+e.token
d=d+e.size
end
A=w+y
E=j+v
q=s+c
b=h+u
_=w+p
z=j+m
x=s+l
k=h+d
if f then
local f={}
for t,e in a.pairs(T)do
e.name=t
f[#f+1]=e
end
g.sort(f,
function(t,e)
return t.size>e.size
end
)
local a,y="%8s%8s%10s  %s","%8d%8d%10.2f  %s"
local w=n.rep("-",44)
e("*** global variable list (sorted by size) ***\n"..w)
e(t(a,"Token","Input","Input","Global"))
e(t(a,"Count","Bytes","Average","Name"))
e(w)
for a=1,#f do
local a=f[a]
e(t(y,a.token,a.size,i(a.token,a.size),a.name))
end
e(w)
e(t(y,s,h,i(s,h),"TOTAL"))
e(w.."\n")
local a,f="%8s%8s%8s%10s%8s%10s  %s","%8d%8d%8d%10.2f%8d%10.2f  %s"
local n=n.rep("-",70)
e("*** local variable list (sorted by allocation order) ***\n"..n)
e(t(a,"Decl.","Token","Input","Input","Output","Output","Global"))
e(t(a,"Count","Count","Bytes","Average","Bytes","Average","Name"))
e(n)
for a=1,#r do
local s=r[a]
local a=O[s]
local h,n=0,0
for t=1,#o do
local e=o[t]
if e.name==s then
h=h+e.xcount
n=n+e.xcount*#e.oldname
end
end
e(t(f,a.decl,a.token,n,i(h,n),
a.size,i(a.token,a.size),s))
end
e(n)
e(t(f,m,l,u,i(c,u),
d,i(l,d),"TOTAL"))
e(n.."\n")
end
local r,o="%-16s%8s%8s%8s%8s%10s","%-16s%8d%8d%8d%8d%10.2f"
local a=n.rep("-",58)
e("*** local variable optimization summary ***\n"..a)
e(t(r,"Variable","Unique","Decl.","Token","Size","Average"))
e(t(r,"Types","Names","Count","Count","Bytes","Bytes"))
e(a)
e(t(o,"Global",w,j,s,h,i(s,h)))
e(a)
e(t(o,"Local (in)",y,v,c,u,i(c,u)))
e(t(o,"TOTAL (in)",A,E,q,b,i(q,b)))
e(a)
e(t(o,"Local (out)",p,m,l,d,i(l,d)))
e(t(o,"TOTAL (out)",_,z,x,k,i(x,k)))
e(a.."\n")
end
local function l()
local function o(e)
local t=s[e+1]or""
local a=s[e+2]or""
local e=s[e+3]or""
if t=="("and a=="<string>"and e==")"then
return true
end
end
local a={}
local e=1
while e<=#s do
local t=w[e]
if t=="call"and o(e)then
a[e+1]=true
a[e+3]=true
e=e+3
end
e=e+1
end
local t,e,o=1,1,#s
local i={}
while e<=o do
if a[t]then
i[v[t]]=true
t=t+1
end
if t>e then
if t<=o then
s[e]=s[t]
k[e]=k[t]
v[e]=v[t]-(t-e)
w[e]=w[t]
else
s[e]=nil
k[e]=nil
v[e]=nil
w[e]=nil
end
end
t=t+1
e=e+1
end
local e,t,a=1,1,#h
while t<=a do
if i[e]then
e=e+1
end
if e>t then
if e<=a then
h[t]=h[e]
c[t]=c[e]
else
h[t]=nil
c[t]=nil
end
end
e=e+1
t=t+1
end
end
local function u(h)
q=0
r={}
b=z(_)
O=z(o)
if h["opt-entropy"]then
I(h)
end
local e={}
for t=1,#o do
e[t]=o[t]
end
g.sort(e,
function(t,e)
return t.xcount>e.xcount
end
)
local a,t,d={},1,false
for o=1,#e do
local e=e[o]
if not e.isself then
a[t]=e
t=t+1
else
d=true
end
end
e=a
local s=#e
while s>0 do
local n,a
repeat
n,a=S()
until not A[n]
r[#r+1]=n
local t=s
if a then
local i=_[b[n].id].xref
local n=#i
for a=1,s do
local a=e[a]
local s,e=a.act,a.rem
while e<0 do
e=o[-e].rem
end
local o
for t=1,n do
local t=i[t]
if t>=s and t<=e then o=true end
end
if o then
a.skip=true
t=t-1
end
end
end
while t>0 do
local a=1
while e[a].skip do
a=a+1
end
t=t-1
local i=e[a]
a=a+1
i.newname=n
i.skip=true
i.done=true
local s,h=i.first,i.last
local r=i.xref
if s and t>0 then
local n=t
while n>0 do
while e[a].skip do
a=a+1
end
n=n-1
local e=e[a]
a=a+1
local n,a=e.act,e.rem
while a<0 do
a=o[-a].rem
end
if not(h<n or s>a)then
if n>=i.act then
for o=1,i.xcount do
local o=r[o]
if o>=n and o<=a then
t=t-1
e.skip=true
break
end
end
else
if e.last and e.last>=i.act then
t=t-1
e.skip=true
end
end
end
if t==0 then break end
end
end
end
local a,t={},1
for o=1,s do
local e=e[o]
if not e.done then
e.skip=false
a[t]=e
t=t+1
end
end
e=a
s=#e
end
for e=1,#o do
local e=o[e]
local t=e.xref
if e.newname then
for a=1,e.xcount do
local t=t[a]
c[t]=e.newname
end
e.name,e.oldname
=e.newname,e.name
else
e.oldname=e.name
end
end
if d then
r[#r+1]="self"
end
local e=z(o)
N(b,O,e,h)
end
function optimize(t,i,a,e)
h,c
=i,a
s,k,v
=e.toklist,e.seminfolist,e.xreflist
_,o,w
=e.globalinfo,e.localinfo,e.statinfo
if t["opt-locals"]then
u(t)
end
if t["opt-experimental"]then
l()
end
end
end
p.equiv=
function()
module"equiv"
local e=a.require"string"
local d=a.loadstring
local u=e.sub
local r=e.match
local s=e.dump
local v=e.byte
local l={
TK_KEYWORD=true,
TK_NAME=true,
TK_NUMBER=true,
TK_STRING=true,
TK_LSTRING=true,
TK_OP=true,
TK_EOS=true,
}
local i,e,h
function init(o,a,t)
i=o
e=a
h=t
end
local function n(t)
e.init(t)
e.llex()
local a,i
=e.tok,e.seminfo
local e,t
={},{}
for o=1,#a do
local a=a[o]
if l[a]then
e[#e+1]=a
t[#t+1]=i[o]
end
end
return e,t
end
function source(t,l)
local function u(e)
local e=d("return "..e,"z")
if e then
return s(e)
end
end
local function o(e)
if i.DETAILS then a.print("SRCEQUIV: "..e)end
h.SRC_EQUIV=true
end
local e,d=n(t)
local a,h=n(l)
local t=r(t,"^(#[^\r\n]*)")
local n=r(l,"^(#[^\r\n]*)")
if t or n then
if not t or not n or t~=n then
o("shbang lines different")
end
end
if#e~=#a then
o("count "..#e.." "..#a)
return
end
for t=1,#e do
local e,s=e[t],a[t]
local n,a=d[t],h[t]
if e~=s then
o("type ["..t.."] "..e.." "..s)
break
end
if e=="TK_KEYWORD"or e=="TK_NAME"or e=="TK_OP"then
if e=="TK_NAME"and i["opt-locals"]then
elseif n~=a then
o("seminfo ["..t.."] "..e.." "..n.." "..a)
break
end
elseif e=="TK_EOS"then
else
local i,s=u(n),u(a)
if not i or not s or i~=s then
o("seminfo ["..t.."] "..e.." "..n.." "..a)
break
end
end
end
end
function binary(n,o)
local e=0
local _=1
local z=3
local E=4
local function e(e)
if i.DETAILS then a.print("BINEQUIV: "..e)end
h.BIN_EQUIV=true
end
local function a(e)
local t=r(e,"^(#[^\r\n]*\r?\n?)")
if t then
e=u(e,#t+1)
end
return e
end
local t=d(a(n),"z")
if not t then
e("failed to compile original sources for binary chunk comparison")
return
end
local a=d(a(o),"z")
if not a then
e("failed to compile compressed result for binary chunk comparison")
end
local i={i=1,dat=s(t)}
i.len=#i.dat
local r={i=1,dat=s(a)}
r.len=#r.dat
local g,
d,c,
y,w,
o,m
local function h(e,t)
if e.i+t-1>e.len then return end
return true
end
local function f(t,e)
if not e then e=1 end
t.i=t.i+e
end
local function n(t)
local e=t.i
if e>t.len then return end
local a=u(t.dat,e,e)
t.i=e+1
return v(a)
end
local function k(a)
local t,e=0,1
if not h(a,d)then return end
for o=1,d do
t=t+e*n(a)
e=e*256
end
return t
end
local function q(t)
local e=0
if not h(t,d)then return end
for a=1,d do
e=e*256+n(t)
end
return e
end
local function j(a)
local t,e=0,1
if not h(a,c)then return end
for o=1,c do
t=t+e*n(a)
e=e*256
end
return t
end
local function x(t)
local e=0
if not h(t,c)then return end
for a=1,c do
e=e*256+n(t)
end
return e
end
local function l(e,o)
local t=e.i
local a=t+o-1
if a>e.len then return end
local a=u(e.dat,t,a)
e.i=t+o
return a
end
local function s(t)
local e=m(t)
if not e then return end
if e==0 then return""end
return l(t,e)
end
local function v(e,t)
local e,t=n(e),n(t)
if not e or not t or e~=t then
return
end
return e
end
local function u(e,t)
local e=v(e,t)
if not e then return true end
end
local function p(e,t)
local e,t=o(e),o(t)
if not e or not t or e~=t then
return
end
return e
end
local function b(a,t)
if not s(a)or not s(t)then
e("bad source name");return
end
if not o(a)or not o(t)then
e("bad linedefined");return
end
if not o(a)or not o(t)then
e("bad lastlinedefined");return
end
if not(h(a,4)and h(t,4))then
e("prototype header broken")
end
if u(a,t)then
e("bad nups");return
end
if u(a,t)then
e("bad numparams");return
end
if u(a,t)then
e("bad is_vararg");return
end
if u(a,t)then
e("bad maxstacksize");return
end
local i=p(a,t)
if not i then
e("bad ncode");return
end
local n=l(a,i*y)
local i=l(t,i*y)
if not n or not i or n~=i then
e("bad code block");return
end
local i=p(a,t)
if not i then
e("bad nconst");return
end
for o=1,i do
local o=v(a,t)
if not o then
e("bad const type");return
end
if o==_ then
if u(a,t)then
e("bad boolean value");return
end
elseif o==z then
local a=l(a,w)
local t=l(t,w)
if not a or not t or a~=t then
e("bad number value");return
end
elseif o==E then
local a=s(a)
local t=s(t)
if not a or not t or a~=t then
e("bad string value");return
end
end
end
local i=p(a,t)
if not i then
e("bad nproto");return
end
for o=1,i do
if not b(a,t)then
e("bad function prototype");return
end
end
local n=o(a)
if not n then
e("bad sizelineinfo1");return
end
local i=o(t)
if not i then
e("bad sizelineinfo2");return
end
if not l(a,n*d)then
e("bad lineinfo1");return
end
if not l(t,i*d)then
e("bad lineinfo2");return
end
local n=o(a)
if not n then
e("bad sizelocvars1");return
end
local i=o(t)
if not i then
e("bad sizelocvars2");return
end
for t=1,n do
if not s(a)or not o(a)or not o(a)then
e("bad locvars1");return
end
end
for a=1,i do
if not s(t)or not o(t)or not o(t)then
e("bad locvars2");return
end
end
local i=o(a)
if not i then
e("bad sizeupvalues1");return
end
local o=o(t)
if not o then
e("bad sizeupvalues2");return
end
for t=1,i do
if not s(a)then e("bad upvalues1");return end
end
for a=1,o do
if not s(t)then e("bad upvalues2");return end
end
return true
end
if not(h(i,12)and h(r,12))then
e("header broken")
end
f(i,6)
g=n(i)
d=n(i)
c=n(i)
y=n(i)
w=n(i)
f(i)
f(r,12)
if g==1 then
o=k
m=j
else
o=q
m=x
end
b(i,r)
if i.i~=i.len+1 then
e("inconsistent binary chunk1");return
elseif r.i~=r.len+1 then
e("inconsistent binary chunk2");return
end
end
end
p["plugin/html"]=
function()
module"plugin/html"
local t=a.require"string"
local c=a.require"table"
local u=a.require"io"
local l=".html"
local m={
["&"]="&amp;",["<"]="&lt;",[">"]="&gt;",
["'"]="&apos;",["\""]="&quot;",
}
local y=[[
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
]]
local w=[[
</pre>
</body>
</html>
]]
local f=[[
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
]]
local n
local e,o
local i,d,h
local function s(...)
if n.QUIET then return end
a.print(...)
end
function init(s,i,h)
n=s
e=i
local i,h=t.find(e,"%.[^%.%\\%/]*$")
local s,r=e,""
if i and i>1 then
s=t.sub(e,1,i-1)
r=t.sub(e,i,h)
end
o=s..l
if n.OUTPUT_FILE then
o=n.OUTPUT_FILE
end
if e==o then
a.error("output filename identical to input filename")
end
end
function post_load(t)
s([[
HTML plugin module for LuaSrcDiet
]])
s("Exporting: "..e.." -> "..o.."\n")
end
function post_lex(e,t,a)
i,d,h
=e,t,a
end
local function h(a)
local e=1
while e<=#a do
local o=t.sub(a,e,e)
local i=m[o]
if i then
o=i
a=t.sub(a,1,e-1)..o..t.sub(a,e+1)
end
e=e+#o
end
return a
end
local function m(t,o)
local e=u.open(t,"wb")
if not e then a.error("cannot open \""..t.."\" for writing")end
local o=e:write(o)
if not o then a.error("cannot write to \""..t.."\"")end
e:close()
end
function post_parse(l,u)
local r={}
local function s(e)
r[#r+1]=e
end
local function a(e,t)
s('<span class="'..e..'">'..t..'</span>')
end
for e=1,#l do
local e=l[e]
local e=e.xref
for t=1,#e do
local e=e[t]
i[e]="TK_GLOBAL"
end
end
for e=1,#u do
local e=u[e]
local e=e.xref
for t=1,#e do
local e=e[t]
i[e]="TK_LOCAL"
end
end
s(t.format(y,
h(e),
f))
for e=1,#i do
local e,t=i[e],d[e]
if e=="TK_KEYWORD"then
a("keyword",t)
elseif e=="TK_STRING"or e=="TK_LSTRING"then
a("string",h(t))
elseif e=="TK_COMMENT"or e=="TK_LCOMMENT"then
a("comment",h(t))
elseif e=="TK_GLOBAL"then
a("global",t)
elseif e=="TK_LOCAL"then
a("local",t)
elseif e=="TK_NAME"then
a("name",t)
elseif e=="TK_NUMBER"then
a("number",t)
elseif e=="TK_OP"then
a("operator",h(t))
elseif e~="TK_EOS"then
s(t)
end
end
s(w)
m(o,c.concat(r))
n.EXIT=true
end
end
p["plugin/sloc"]=
function()
module"plugin/sloc"
local n=a.require"string"
local e=a.require"table"
local o
local h
function init(t,e,a)
o=t
o.QUIET=true
h=e
end
local function s(o)
local a={}
local t,i=1,#o
while t<=i do
local e,s,r,h=n.find(o,"([\r\n])([\r\n]?)",t)
if not e then
e=i+1
end
a[#a+1]=n.sub(o,t,e-1)
t=e+1
if e<i and s>e and r~=h then
t=t+1
end
end
return a
end
function post_lex(t,r,d)
local e,i=0,0
local function n(t)
if t>e then
i=i+1;e=t
end
end
for e=1,#t do
local t,a,e
=t[e],r[e],d[e]
if t=="TK_KEYWORD"or t=="TK_NAME"or
t=="TK_NUMBER"or t=="TK_OP"then
n(e)
elseif t=="TK_STRING"then
local t=s(a)
e=e-#t+1
for t=1,#t do
n(e);e=e+1
end
elseif t=="TK_LSTRING"then
local t=s(a)
e=e-#t+1
for a=1,#t do
if t[a]~=""then n(e)end
e=e+1
end
end
end
a.print(h..": "..i)
o.EXIT=true
end
end
local o=j"llex"
local u=j"lparser"
local x=j"optlex"
local E=j"optparser"
local q=j"equiv"
local a
local p=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.12.1 (20120407)  Copyright (c) 2012 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]
local m=[[
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
%s]]
local v=[[
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
]]
local _=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
  --opt-srcequiv --opt-binequiv
]]
local N=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]
local O=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
  --opt-srcequiv --opt-binequiv
]]
local I=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]
local h="_"
local A="plugin/"
local function i(e)
y("LuaSrcDiet (error): "..e);os.exit(1)
end
if not B(_VERSION,"5.1",1,1)then
i("requires Lua 5.1 to run")
end
local n=""
do
local i=24
local t={}
for a,o in G(v,"%s*([^,]+),'([^']+)'")do
local e="  "..a
e=e..s.rep(" ",i-#e)..o.."\n"
n=n..e
t[a]=true
t["--no"..f(a,3)]=true
end
v=t
end
m=s.format(m,n,_)
if W then
local e="\nembedded plugins:\n"
for t=1,#W do
local t=W[t]
e=e.."  "..Z[t].."\n"
end
m=m..e
end
local z=h
local e={}
local h,n
local function w(t)
for t in G(t,"(%-%-%S+)")do
if f(t,3,4)=="no"and
v["--"..f(t,5)]then
e[f(t,5)]=false
else
e[f(t,3)]=true
end
end
end
local d={
"TK_KEYWORD","TK_NAME","TK_NUMBER",
"TK_STRING","TK_LSTRING","TK_OP",
"TK_EOS",
"TK_COMMENT","TK_LCOMMENT",
"TK_EOL","TK_SPACE",
}
local c=7
local l={
["\n"]="LF",["\r"]="CR",
["\n\r"]="LFCR",["\r\n"]="CRLF",
}
local function r(e)
local t=io.open(e,"rb")
if not t then i('cannot open "'..e..'" for reading')end
local a=t:read("*a")
if not a then i('cannot read from "'..e..'"')end
t:close()
return a
end
local function T(t,a)
local e=io.open(t,"wb")
if not e then i('cannot open "'..t..'" for writing')end
local a=e:write(a)
if not a then i('cannot write to "'..t..'"')end
e:close()
end
local function k()
h,n={},{}
for e=1,#d do
local e=d[e]
h[e],n[e]=0,0
end
end
local function g(e,t)
h[e]=h[e]+1
n[e]=n[e]+#t
end
local function b()
local function i(e,t)
if e==0 then return 0 end
return t/e
end
local o={}
local e,t=0,0
for a=1,c do
local a=d[a]
e=e+h[a];t=t+n[a]
end
h.TOTAL_TOK,n.TOTAL_TOK=e,t
o.TOTAL_TOK=i(e,t)
e,t=0,0
for a=1,#d do
local a=d[a]
e=e+h[a];t=t+n[a]
o[a]=i(h[a],n[a])
end
h.TOTAL_ALL,n.TOTAL_ALL=e,t
o.TOTAL_ALL=i(e,t)
return o
end
local function H(e)
local e=r(e)
o.init(e)
o.llex()
local e,a=o.tok,o.seminfo
for t=1,#e do
local t,e=e[t],a[t]
if t=="TK_OP"and s.byte(e)<32 then
e="("..s.byte(e)..")"
elseif t=="TK_EOL"then
e=l[e]
else
e="'"..e.."'"
end
y(t.." "..e)
end
end
local function R(e)
local t=y
local e=r(e)
o.init(e)
o.llex()
local e,o,a
=o.tok,o.seminfo,o.tokln
u.init(e,o,a)
local e=u.parser()
local a,i=
e.globalinfo,e.localinfo
local o=s.rep("-",72)
t("*** Local/Global Variable Tracker Tables ***")
t(o.."\n GLOBALS\n"..o)
for e=1,#a do
local a=a[e]
local e="("..e..") '"..a.name.."' -> "
local a=a.xref
for o=1,#a do e=e..a[o].." "end
t(e)
end
t(o.."\n LOCALS (decl=declared act=activated rem=removed)\n"..o)
for e=1,#i do
local a=i[e]
local e="("..e..") '"..a.name.."' decl:"..a.decl..
" act:"..a.act.." rem:"..a.rem
if a.isself then
e=e.." isself"
end
e=e.." -> "
local a=a.xref
for o=1,#a do e=e..a[o].." "end
t(e)
end
t(o.."\n")
end
local function D(a)
local e=y
local t=r(a)
o.init(t)
o.llex()
local t,o=o.tok,o.seminfo
e(p)
e("Statistics for: "..a.."\n")
k()
for e=1,#t do
local e,t=t[e],o[e]
g(e,t)
end
local t=b()
local a=s.format
local function r(e)
return h[e],n[e],t[e]
end
local i,o="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"
local t=s.rep("-",42)
e(a(i,"Lexical","Input","Input","Input"))
e(a(i,"Elements","Count","Bytes","Average"))
e(t)
for i=1,#d do
local i=d[i]
e(a(o,i,r(i)))
if i=="TK_EOS"then e(t)end
end
e(t)
e(a(o,"Total Elements",r("TOTAL_ALL")))
e(t)
e(a(o,"Total Tokens",r("TOTAL_TOK")))
e(t.."\n")
end
local function S(f,w)
local function t(...)
if e.QUIET then return end
_G.print(...)
end
if a and a.init then
e.EXIT=false
a.init(e,f,w)
if e.EXIT then return end
end
t(p)
local c=r(f)
if a and a.post_load then
c=a.post_load(c)or c
if e.EXIT then return end
end
o.init(c)
o.llex()
local r,l,m
=o.tok,o.seminfo,o.tokln
if a and a.post_lex then
a.post_lex(r,l,m)
if e.EXIT then return end
end
k()
for e=1,#r do
local t,e=r[e],l[e]
g(t,e)
end
local v=b()
local p,y=h,n
E.print=t
u.init(r,l,m)
local u=u.parser()
if a and a.post_parse then
a.post_parse(u.globalinfo,u.localinfo)
if e.EXIT then return end
end
E.optimize(e,r,l,u)
if a and a.post_optparse then
a.post_optparse()
if e.EXIT then return end
end
local u=x.warn
x.print=t
r,l,m
=x.optimize(e,r,l,m)
if a and a.post_optlex then
a.post_optlex(r,l,m)
if e.EXIT then return end
end
local a=ee.concat(l)
if s.find(a,"\r\n",1,1)or
s.find(a,"\n\r",1,1)then
u.MIXEDEOL=true
end
q.init(e,o,u)
q.source(c,a)
q.binary(c,a)
local m="before and after lexer streams are NOT equivalent!"
local c="before and after binary chunks are NOT equivalent!"
if u.SRC_EQUIV then
if e["opt-srcequiv"]then i(m)end
else
t("*** SRCEQUIV: token streams are sort of equivalent")
if e["opt-locals"]then
t("(but no identifier comparisons since --opt-locals enabled)")
end
t()
end
if u.BIN_EQUIV then
if e["opt-binequiv"]then i(c)end
else
t("*** BINEQUIV: binary chunks are sort of equivalent")
t()
end
T(w,a)
k()
for e=1,#r do
local e,t=r[e],l[e]
g(e,t)
end
local o=b()
t("Statistics for: "..f.." -> "..w.."\n")
local a=s.format
local function r(e)
return p[e],y[e],v[e],
h[e],n[e],o[e]
end
local o,i="%-16s%8s%8s%10s%8s%8s%10s",
"%-16s%8d%8d%10.2f%8d%8d%10.2f"
local e=s.rep("-",68)
t("*** lexer-based optimizations summary ***\n"..e)
t(a(o,"Lexical",
"Input","Input","Input",
"Output","Output","Output"))
t(a(o,"Elements",
"Count","Bytes","Average",
"Count","Bytes","Average"))
t(e)
for o=1,#d do
local o=d[o]
t(a(i,o,r(o)))
if o=="TK_EOS"then t(e)end
end
t(e)
t(a(i,"Total Elements",r("TOTAL_ALL")))
t(e)
t(a(i,"Total Tokens",r("TOTAL_TOK")))
t(e)
if u.LSTRING then
t("* WARNING: "..u.LSTRING)
elseif u.MIXEDEOL then
t("* WARNING: ".."output still contains some CRLF or LFCR line endings")
elseif u.SRC_EQUIV then
t("* WARNING: "..m)
elseif u.BIN_EQUIV then
t("* WARNING: "..c)
end
t()
end
local r={...}
local h={}
w(_)
local function l(n)
for t=1,#n do
local t=n[t]
local a
local o,r=s.find(t,"%.[^%.%\\%/]*$")
local h,s=t,""
if o and o>1 then
h=f(t,1,o-1)
s=f(t,o,r)
end
a=h..z..s
if#n==1 and e.OUTPUT_FILE then
a=e.OUTPUT_FILE
end
if t==a then
i("output filename identical to input filename")
end
if e.DUMP_LEXER then
H(t)
elseif e.DUMP_PARSER then
R(t)
elseif e.READ_ONLY then
D(t)
else
S(t,a)
end
end
end
local function d()
local t,o=#r,1
if t==0 then
e.HELP=true
end
while o<=t do
local t,n=r[o],r[o+1]
local s=B(t,"^%-%-?")
if s=="-"then
if t=="-h"then
e.HELP=true;break
elseif t=="-v"then
e.VERSION=true;break
elseif t=="-s"then
if not n then i("-s option needs suffix specification")end
z=n
o=o+1
elseif t=="-o"then
if not n then i("-o option needs a file name")end
e.OUTPUT_FILE=n
o=o+1
elseif t=="-"then
break
else
i("unrecognized option "..t)
end
elseif s=="--"then
if t=="--help"then
e.HELP=true;break
elseif t=="--version"then
e.VERSION=true;break
elseif t=="--keep"then
if not n then i("--keep option needs a string to match for")end
e.KEEP=n
o=o+1
elseif t=="--plugin"then
if not n then i("--plugin option needs a module name")end
if e.PLUGIN then i("only one plugin can be specified")end
e.PLUGIN=n
a=j(A..n)
o=o+1
elseif t=="--quiet"then
e.QUIET=true
elseif t=="--read-only"then
e.READ_ONLY=true
elseif t=="--basic"then
w(N)
elseif t=="--maximum"then
w(O)
elseif t=="--none"then
w(I)
elseif t=="--dump-lexer"then
e.DUMP_LEXER=true
elseif t=="--dump-parser"then
e.DUMP_PARSER=true
elseif t=="--details"then
e.DETAILS=true
elseif v[t]then
w(t)
else
i("unrecognized option "..t)
end
else
h[#h+1]=t
end
o=o+1
end
if e.HELP then
y(p..m);return true
elseif e.VERSION then
y(p);return true
end
if#h>0 then
if#h>1 and e.OUTPUT_FILE then
i("with -o, only one source file can be specified")
end
l(h)
return true
else
i("nothing to do!")
end
end
if not d()then
i("Please run with option -h or --help for usage information")
end
