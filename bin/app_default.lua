#!/usr/bin/env lua
local s=string
local e=math
local ee=table
local g=require
local p=print
local y=s.sub
local Z=s.gmatch
local X=s.match
local v=package.preload
local a=_G
local te={
html="html    generates a HTML file for checking globals",
sloc="sloc    calculates SLOC for given source file",
}
local W={
'html',
'sloc',
}
v.llex=
function()
module"llex"
local r=a.require"string"
local u=r.find
local m=r.match
local s=r.sub
local f={}
for e in r.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]],"%S+")do
f[e]=true
end
local e,
l,
o,
n,
h
local function i(t,a)
local e=#tok+1
tok[e]=t
seminfo[e]=a
tokln[e]=h
end
local function d(t,r)
local n=s
local a=n(e,t,t)
t=t+1
local e=n(e,t,t)
if(e=="\n"or e=="\r")and(e~=a)then
t=t+1
a=a..e
end
if r then i("TK_EOL",a)end
h=h+1
o=t
return t
end
function init(t,a)
e=t
l=a
o=1
h=1
tok={}
seminfo={}
tokln={}
local t,n,e,a=u(e,"^(#[^\r\n]*)(\r?\n?)")
if t then
o=o+#e
i("TK_COMMENT",e)
if#a>0 then d(o,true)end
end
end
function chunkid()
if l and m(l,"^[=@]")then
return s(l,2)
end
return"[string]"
end
function errorline(e,t)
local a=error or a.error
a(r.format("%s:%d: %s",chunkid(),t or h,e))
end
local r=errorline
local function c(t)
local i=s
local n=i(e,t,t)
t=t+1
local a=#m(e,"=*",t)
t=t+a
o=t
return(i(e,t,t)==n)and a or(-a)-1
end
local function w(l,h)
local t=o+1
local a=s
local i=a(e,t,t)
if i=="\r"or i=="\n"then
t=d(t)
end
while true do
local i,u,s=u(e,"([\r\n%]])",t)
if not i then
r(l and"unfinished long string"or
"unfinished long comment")
end
t=i
if s=="]"then
if c(t)==h then
n=a(e,n,o)
o=o+1
return n
end
t=o
else
n=n.."\n"
t=d(t)
end
end
end
local function y(l)
local t=o
local h=u
local s=s
while true do
local i,u,a=h(e,"([\n\r\\\"\'])",t)
if i then
if a=="\n"or a=="\r"then
r("unfinished string")
end
t=i
if a=="\\"then
t=t+1
a=s(e,t,t)
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
local o,a,e=h(e,"^(%d%d?%d?)",t)
t=a+1
if e+1>256 then
r("escape sequence too large")
end
end
else
t=t+1
if a==l then
o=t
return s(e,n,t-1)
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
local l=m
while true do
local t=o
while true do
local m,p,u=h(e,"^([_%a][_%w]*)",t)
if m then
o=t+#u
if f[u]then
i("TK_KEYWORD",u)
else
i("TK_NAME",u)
end
break
end
local u,f,m=h(e,"^(%.?)%d",t)
if u then
if m=="."then t=t+1 end
local c,n,d=h(e,"^%d*[%.%d]*([eE]?)",t)
t=n+1
if#d==1 then
if l(e,"^[%+%-]",t)then
t=t+1
end
end
local n,t=h(e,"^[_%w]*",t)
o=t+1
local e=s(e,u,t)
if not a.tonumber(e)then
r("malformed number")
end
i("TK_NUMBER",e)
break
end
local f,u,m,a=h(e,"^((%s)[ \t\v\f]*)",t)
if f then
if a=="\n"or a=="\r"then
d(t,true)
else
o=u+1
i("TK_SPACE",m)
end
break
end
local a=l(e,"^%p",t)
if a then
n=t
local d=h("-[\"\'.=<>~",a,1,true)
if d then
if d<=2 then
if d==1 then
local r=l(e,"^%-%-(%[?)",t)
if r then
t=t+2
local a=-1
if r=="["then
a=c(t)
end
if a>=0 then
i("TK_LCOMMENT",w(false,a))
else
o=h(e,"[\n\r]",t)or(#e+1)
i("TK_COMMENT",s(e,n,o-1))
end
break
end
else
local e=c(t)
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
local e=s(e,t,t)
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
v.lparser=
function()
module"lparser"
local k=a.require"string"
local j,
g,
x,
S,
s,
h,
L,
t,T,r,m,
p,
o,
W,
_,
D,
u,
b,
N,
E
local y,c,q,O,I,z
local e=k.gmatch
local R={}
for e in e("else elseif end until <eof>","%S+")do
R[e]=true
end
local H={}
local Y={}
for e,t,a in e([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")do
H[e]=t+0
Y[e]=a+0
end
local ee={["not"]=true,["-"]=true,
["#"]=true,}
local Z=8
local function i(e,t)
local a=error or a.error
a(k.format("(source):%d: %s",t or r,e))
end
local function e()
L=x[s]
t,T,r,m
=j[s],g[s],x[s],S[s]
s=s+1
end
local function X()
return j[s]
end
local function d(a)
local e=t
if e~="<number>"and e~="<string>"then
if e=="<name>"then e=T end
e="'"..e.."'"
end
i(a.." near "..e)
end
local function f(e)
d("'"..e.."' expected")
end
local function i(a)
if t==a then e();return true end
end
local function F(e)
if t~=e then f(e)end
end
local function n(t)
F(t);e()
end
local function P(e,t)
if not e then d(t)end
end
local function l(e,a,t)
if not i(e)then
if t==r then
f(e)
else
d("'"..e.."' expected (to close '"..a.."' at line "..t..")")
end
end
end
local function f()
F("<name>")
local t=T
p=m
e()
return t
end
local function M(e,t)
e.k="VK"
end
local function C(e)
M(e,f())
end
local function w(i,a)
local e=o.bl
local t
if e then
t=e.locallist
else
t=o.locallist
end
local e=#u+1
u[e]={
name=i,
xref={p},
decl=p,
}
if a then
u[e].isself=true
end
local a=#b+1
b[a]=e
N[a]=t
end
local function A(e)
local t=#b
while e>0 do
e=e-1
local e=t-e
local a=b[e]
local t=u[a]
local o=t.name
t.act=m
b[e]=nil
local i=N[e]
N[e]=nil
local e=i[o]
if e then
t=u[e]
t.rem=-a
end
i[o]=a
end
end
local function U()
local t=o.bl
local e
if t then
e=t.locallist
else
e=o.locallist
end
for t,e in a.pairs(e)do
local e=u[e]
e.rem=m
end
end
local function m(e,t)
if k.sub(e,1,1)=="("then
return
end
w(e,t)
end
local function V(o,a)
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
local function k(t,a,e)
if t==nil then
e.k="VGLOBAL"
return"VGLOBAL"
else
local o=V(t,a)
if o>=0 then
e.k="VLOCAL"
e.id=o
return"VLOCAL"
else
if k(t.prev,a,e)=="VGLOBAL"then
return"VGLOBAL"
end
e.k="VUPVAL"
return"VUPVAL"
end
end
end
local function J(a)
local t=f()
k(o,t,a)
if a.k=="VGLOBAL"then
local e=D[t]
if not e then
e=#_+1
_[e]={
name=t,
xref={p},
}
D[t]=e
else
local e=_[e].xref
e[#e+1]=p
end
else
local e=a.id
local e=u[e].xref
e[#e+1]=p
end
end
local function p(t)
local e={}
e.isbreakable=t
e.prev=o.bl
e.locallist={}
o.bl=e
end
local function k()
local e=o.bl
U()
o.bl=e.prev
end
local function B()
local e
if not o then
e=W
else
e={}
end
e.prev=o
e.bl=nil
e.locallist={}
o=e
end
local function G()
U()
o=o.prev
end
local function U(a)
local t={}
e()
C(t)
a.k="VINDEXED"
end
local function V(t)
e()
c(t)
n("]")
end
local function a(e)
local e,a={},{}
if t=="<name>"then
C(e)
else
V(e)
end
n("=")
c(a)
end
local function K(e)
if e.v.k=="VVOID"then return end
e.v.k="VVOID"
end
local function Q(e)
c(e.v)
end
local function K(o)
local s=r
local e={}
e.v={}
e.t=o
o.k="VRELOCABLE"
e.v.k="VVOID"
n("{")
repeat
if t=="}"then break end
local t=t
if t=="<name>"then
if X()~="="then
Q(e)
else
a(e)
end
elseif t=="["then
a(e)
else
Q(e)
end
until not i(",")and not i(";")
l("}","{",s)
end
local function X()
local a=0
if t~=")"then
repeat
local t=t
if t=="<name>"then
w(f())
a=a+1
elseif t=="..."then
e()
o.is_vararg=true
else
d("<name> or '...' expected")
end
until o.is_vararg or not i(",")
end
A(a)
end
local function Q(n)
local a={}
local i=r
local o=t
if o=="("then
if i~=L then
d("ambiguous syntax (function call x new statement)")
end
e()
if t==")"then
a.k="VVOID"
else
y(a)
end
l(")","(",i)
elseif o=="{"then
K(a)
elseif o=="<string>"then
M(a,T)
e()
else
d("function arguments expected")
return
end
n.k="VCALL"
end
local function te(a)
local t=t
if t=="("then
local t=r
e()
c(a)
l(")","(",t)
elseif t=="<name>"then
J(a)
else
d("unexpected symbol")
end
end
local function L(a)
te(a)
while true do
local t=t
if t=="."then
U(a)
elseif t=="["then
local e={}
V(e)
elseif t==":"then
local t={}
e()
C(t)
Q(a)
elseif t=="("or t=="<string>"or t=="{"then
Q(a)
else
return
end
end
end
local function C(a)
local t=t
if t=="<number>"then
a.k="VKNUM"
elseif t=="<string>"then
M(a,T)
elseif t=="nil"then
a.k="VNIL"
elseif t=="true"then
a.k="VTRUE"
elseif t=="false"then
a.k="VFALSE"
elseif t=="..."then
P(o.is_vararg==true,
"cannot use '...' outside a vararg function");
a.k="VVARARG"
elseif t=="{"then
K(a)
return
elseif t=="function"then
e()
I(a,false,r)
return
else
L(a)
return
end
e()
end
local function T(o,i)
local a=t
local n=ee[a]
if n then
e()
T(o,Z)
else
C(o)
end
a=t
local t=H[a]
while t and t>i do
local o={}
e()
local e=T(o,Y[a])
a=e
t=H[a]
end
return a
end
function c(e)
T(e,0)
end
local function T(e)
local t={}
local e=e.v.k
P(e=="VLOCAL"or e=="VUPVAL"or e=="VGLOBAL"
or e=="VINDEXED","syntax error")
if i(",")then
local e={}
e.v={}
L(e.v)
T(e)
else
n("=")
y(t)
return
end
t.k="VNONRELOC"
end
local function a(e,t)
n("do")
p(false)
A(e)
q()
k()
end
local function C(e)
local t=h
m("(for index)")
m("(for limit)")
m("(for step)")
w(e)
n("=")
O()
n(",")
O()
if i(",")then
O()
else
end
a(1,true)
end
local function H(e)
local t={}
m("(for generator)")
m("(for state)")
m("(for control)")
w(e)
local e=1
while i(",")do
w(f())
e=e+1
end
n("in")
local o=h
y(t)
a(e,false)
end
local function M(e)
local a=false
J(e)
while t=="."do
U(e)
end
if t==":"then
a=true
U(e)
end
return a
end
function O()
local e={}
c(e)
end
local function a()
local e={}
c(e)
end
local function O()
e()
a()
n("then")
q()
end
local function Y()
local t,e={}
w(f())
t.k="VLOCAL"
A(1)
I(e,false,r)
end
local function U()
local e=0
local t={}
repeat
w(f())
e=e+1
until not i(",")
if i("=")then
y(t)
else
t.k="VVOID"
end
A(e)
end
function y(e)
c(e)
while i(",")do
c(e)
end
end
function I(a,t,e)
B()
n("(")
if t then
m("self",true)
A(1)
end
X()
n(")")
z()
l("end","function",e)
G()
end
function q()
p(false)
z()
k()
end
local function A()
local o=h
p(true)
e()
local a=f()
local e=t
if e=="="then
C(a)
elseif e==","or e=="in"then
H(a)
else
d("'=' or 'in' expected")
end
l("end","for",o)
k()
end
local function f()
local t=h
e()
a()
p(true)
n("do")
q()
l("end","while",t)
k()
end
local function m()
local t=h
p(true)
p(false)
e()
z()
l("until","repeat",t)
a()
k()
k()
end
local function c()
local a=h
local o={}
O()
while t=="elseif"do
O()
end
if t=="else"then
e()
q()
end
l("end","if",a)
end
local function w()
local a={}
e()
local e=t
if R[e]or e==";"then
else
y(a)
end
end
local function p()
local t=o.bl
e()
while t and not t.isbreakable do
t=t.prev
end
if not t then
d("no loop to break")
end
end
local function y()
local t=s-1
local e={}
e.v={}
L(e.v)
if e.v.k=="VCALL"then
E[t]="call"
else
e.prev=nil
T(e)
E[t]="assign"
end
end
local function d()
local o=h
local t,a={},{}
e()
local e=M(t)
I(a,e,o)
end
local function a()
local t=h
e()
q()
l("end","do",t)
end
local function n()
e()
if i("function")then
Y()
else
U()
end
end
local a={
["if"]=c,
["while"]=f,
["do"]=a,
["for"]=A,
["repeat"]=m,
["function"]=d,
["local"]=n,
["return"]=w,
["break"]=p,
}
local function n()
h=r
local e=t
local t=a[e]
if t then
E[s-1]=e
t()
if e=="return"or e=="break"then return true end
else
y()
end
return false
end
function z()
local e=false
while not e and not R[t]do
e=n()
i(";")
end
end
function parser()
B()
o.is_vararg=true
e()
z()
F("<eof>")
G()
return{
globalinfo=_,
localinfo=u,
statinfo=E,
toklist=j,
seminfolist=g,
toklnlist=x,
xreflist=S,
}
end
function init(e,i,n)
s=1
W={}
local t=1
j,g,x,S={},{},{},{}
for a=1,#e do
local e=e[a]
local o=true
if e=="TK_KEYWORD"or e=="TK_OP"then
e=i[a]
elseif e=="TK_NAME"then
e="<name>"
g[t]=i[a]
elseif e=="TK_NUMBER"then
e="<number>"
g[t]=0
elseif e=="TK_STRING"or e=="TK_LSTRING"then
e="<string>"
g[t]=""
elseif e=="TK_EOS"then
e="<eof>"
else
o=false
end
if o then
j[t]=e
x[t]=n[a]
S[t]=a
t=t+1
end
end
_,D,u={},{},{}
b,N={},{}
E={}
end
end
v.optlex=
function()
module"optlex"
local m=a.require"string"
local i=m.match
local e=m.sub
local d=m.find
local u=m.rep
local c
error=a.error
warn={}
local n,o,l
local p={
TK_KEYWORD=true,
TK_NAME=true,
TK_NUMBER=true,
TK_STRING=true,
TK_LSTRING=true,
TK_OP=true,
TK_EOS=true,
}
local g={
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
local function k(t)
local e=n[t+1]
if t>=#n or e=="TK_EOL"or e=="TK_EOS"then
return true
elseif e==""then
return k(t+1)
end
return false
end
local function T(t)
local a=#i(t,"^%-%-%[=*%[")
local a=e(t,a+1,-(a-1))
local e,t=1,0
while true do
local o,n,i,a=d(a,"([\r\n])([\r\n]?)",e)
if not o then break end
e=o+1
t=t+1
if#a>0 and i~=a then
e=e+1
end
end
return t
end
local function y(s,h)
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
local a,s,i={},{},{}
local e=1
for t=1,#n do
local n=n[t]
if n~=""then
a[e],s[e],i[e]=n,o[t],l[t]
e=e+1
end
end
n,o,l=a,s,i
end
local function z(h)
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
local h,s=i(t,"^(%d*)%.(%d*)$")
if h then
o=o-#s
t=h..s
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
n=t..u("0",o)
elseif o<0 and(o>=-#t)then
s=#t+o
n=e(t,1,s).."."..e(t,s+1)
elseif o<0 and(#a>=-o-#t)then
s=-o-#t
n="."..u("0",s)..t
else
n=t.."e"..o
end
end
end
if n and n~=o[h]then
if r then
c("<number> (line "..l[h]..") "..o[h].." -> "..n)
r=r+1
end
o[h]=n
end
end
local function _(u)
local t=o[u]
local s=e(t,1,1)
local w=(s=="'")and'"'or"'"
local t=e(t,2,-2)
local a=1
local f,h=0,0
while a<=#t do
local u=e(t,a,a)
if u=="\\"then
local o=a+1
local r=e(t,o,o)
local n=d("abfnrtv\\\n\r\"\'0123456789",r,1,true)
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
f=f+1
a=a+2
else
h=h+1
t=e(t,1,a-1)..e(t,o)
a=a+1
end
else
local n=i(t,"^(%d%d?%d?)",o)
o=a+1+#n
local l=n+0
local r=m.char(l)
local d=d("\a\b\f\n\r\t\v",r,1,true)
if d then
n="\\"..e("abfnrtv",d,d)
elseif l<32 then
if i(e(t,o,o),"%d")then
n="\\"..n
else
n="\\"..l
end
elseif r==s then
n="\\"..r
f=f+1
elseif r=="\\"then
n="\\\\"
else
n=r
if r==w then
h=h+1
end
end
t=e(t,1,a-1)..n..e(t,o)
a=a+#n
end
else
a=a+1
if u==w then
h=h+1
end
end
end
if f>h then
a=1
while a<=#t do
local o,n,i=d(t,"([\'\"])",a)
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
c("<string> (line "..l[u]..") "..o[u].." -> "..t)
r=r+1
end
o[u]=t
end
end
local function E(s)
local t=o[s]
local r=i(t,"^%[=*%[")
local a=#r
local c=e(t,-a,-1)
local h=e(t,a+1,-(a+1))
local n=""
local t=1
while true do
local a,o,d,r=d(h,"([\r\n])([\r\n]?)",t)
local o
if not a then
o=e(h,t)
elseif a>=t then
o=e(h,t,a-1)
end
if o~=""then
if i(o,"%s+$")then
warn.LSTRING="trailing whitespace in long string near line "..l[s]
end
n=n..o
end
if not a then
break
end
t=a+1
if a then
if#r>0 and d~=r then
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
local a="%]"..u("=",e-2).."%]"
if not i(n,a)then t=e end
e=e-1
end
if t then
a=u("=",t-2)
r,c="["..a.."[","]"..a.."]"
end
end
o[s]=r..n..c
end
local function q(r)
local a=o[r]
local s=i(a,"^%-%-%[=*%[")
local t=#s
local l=e(a,-t,-1)
local h=e(a,t+1,-(t-1))
local n=""
local a=1
while true do
local o,t,r,s=d(h,"([\r\n])([\r\n]?)",a)
local t
if not o then
t=e(h,a)
elseif o>=a then
t=e(h,a,o-1)
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
if#s>0 and r~=s then
a=a+1
end
n=n.."\n"
end
end
t=t-2
if t>=3 then
local e,a=t-1
while e>=2 do
local t="%]"..u("=",e-2).."%]"
if not i(n,t)then a=e end
e=e-1
end
if a then
t=u("=",a-2)
s,l="--["..t.."[","]"..t.."]"
end
end
o[r]=s..n..l
end
local function x(n)
local t=o[n]
local a=i(t,"%s*$")
if#a>0 then
t=e(t,1,-(a+1))
end
o[n]=t
end
local function N(o,t)
if not o then return false end
local a=i(t,"^%-%-%[=*%[")
local a=#a
local i=e(t,-a,-1)
local e=e(t,a+1,-(a-1))
if d(e,o,1,true)then
return true
end
end
function optimize(t,h,s,i)
local m=t["opt-comments"]
local d=t["opt-whitespace"]
local f=t["opt-emptylines"]
local j=t["opt-eols"]
local A=t["opt-strings"]
local O=t["opt-numbers"]
local v=t["opt-experimental"]
local I=t.KEEP
r=t.DETAILS and 0
c=c or a.print
if j then
m=true
d=true
f=true
elseif v then
d=true
end
n,o,l
=h,s,i
local t=1
local a,h
local s
local function i(i,a,e)
e=e or t
n[e]=i or""
o[e]=a or""
end
if v then
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
if O then
z(t)
end
s=t
elseif a=="TK_STRING"or
a=="TK_LSTRING"then
if A then
if a=="TK_STRING"then
_(t)
else
E(t)
end
end
s=t
elseif a=="TK_COMMENT"then
if m then
if t==1 and e(h,1,1)=="#"then
x(t)
else
i()
end
elseif d then
x(t)
end
elseif a=="TK_LCOMMENT"then
if N(I,h)then
if d then
q(t)
end
s=t
elseif m then
local e=T(h)
if g[n[t+1]]then
i()
a=""
else
i("TK_SPACE"," ")
end
if not f and e>0 then
i("TK_EOL",u("\n",e))
end
if d and a~=""then
t=t-1
end
else
if d then
q(t)
end
s=t
end
elseif a=="TK_EOL"then
if r and f then
i()
elseif h=="\r\n"or h=="\n\r"then
i("TK_EOL","\n")
end
elseif a=="TK_SPACE"then
if d then
if r or k(t)then
i()
else
local a=n[s]
if a=="TK_LCOMMENT"then
i()
else
local e=n[t+1]
if g[e]then
if(e=="TK_COMMENT"or e=="TK_LCOMMENT")and
a=="TK_OP"and o[s]=="-"then
else
i()
end
else
local e=y(s,t+1)
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
if j then
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
if p[a]and p[e]then
local t=y(t-1,t+1)
if t==""or e=="TK_EOS"then
i()
end
end
end
t=t+1
end
w()
end
if r and r>0 then c()end
return n,o,l
end
end
v.optparser=
function()
module"optparser"
local s=a.require"string"
local g=a.require"table"
local i="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"
local r="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"
local T={}
for e in s.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]],"%S+")do
T[e]=true
end
local h,c,
n,k,y,
x,o,
w,
q,E,
b,
l
local function z(e)
local o={}
for n=1,#e do
local e=e[n]
local i=e.name
if not o[i]then
o[i]={
decl=0,token=0,size=0,
}
end
local t=o[i]
t.decl=t.decl+1
local o=e.xref
local a=#o
t.token=t.token+a
t.size=t.size+a*#i
if e.decl then
e.id=n
e.xcount=a
if a>1 then
e.first=o[2]
e.last=o[a]
end
else
t.id=n
end
end
return o
end
local function O(e)
local d=s.byte
local s=s.char
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
local t=d(a,t)
e[t]=e[t]+1
end
end
end
local function n(o)
local t={}
for a=1,#o do
local o=d(o,a)
t[a]={c=o,freq=e[o],}
end
g.sort(t,
function(t,e)
return t.freq>e.freq
end
)
local e={}
for a=1,#t do
e[a]=s(t[a].c)
end
return g.concat(e)
end
i=n(i)
r=n(r)
end
local function I()
local t
local n,h=#i,#r
local e=b
if e<n then
e=e+1
t=s.sub(i,e,e)
else
local o,a=n,1
repeat
e=e-o
o=o*h
a=a+1
until o>e
local o=e%n
e=(e-o)/n
o=o+1
t=s.sub(i,o,o)
while a>1 do
local o=e%h
e=(e-o)/h
o=o+1
t=t..s.sub(r,o,o)
a=a-1
end
end
b=b+1
return t,q[t]~=nil
end
local function N(E,O,A,i)
local e=p or a.print
local t=s.format
local I=i.DETAILS
if i.QUIET then return end
local m,w,y,T,z,
q,p,f,_,x,
h,c,u,k,j,
n,d,r,v,b
=0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0
local function i(e,t)
if e==0 then return 0 end
return t/e
end
for t,e in a.pairs(E)do
m=m+1
h=h+e.token
n=n+e.size
end
for t,e in a.pairs(O)do
w=w+1
p=p+e.decl
c=c+e.token
d=d+e.size
end
for t,e in a.pairs(A)do
y=y+1
f=f+e.decl
u=u+e.token
r=r+e.size
end
T=m+w
_=q+p
k=h+c
v=n+d
z=m+y
x=q+f
j=h+u
b=n+r
if I then
local m={}
for t,e in a.pairs(E)do
e.name=t
m[#m+1]=e
end
g.sort(m,
function(e,t)
return e.size>t.size
end
)
local a,y="%8s%8s%10s  %s","%8d%8d%10.2f  %s"
local w=s.rep("-",44)
e("*** global variable list (sorted by size) ***\n"..w)
e(t(a,"Token","Input","Input","Global"))
e(t(a,"Count","Bytes","Average","Name"))
e(w)
for a=1,#m do
local a=m[a]
e(t(y,a.token,a.size,i(a.token,a.size),a.name))
end
e(w)
e(t(y,h,n,i(h,n),"TOTAL"))
e(w.."\n")
local a,m="%8s%8s%8s%10s%8s%10s  %s","%8d%8d%8d%10.2f%8d%10.2f  %s"
local s=s.rep("-",70)
e("*** local variable list (sorted by allocation order) ***\n"..s)
e(t(a,"Decl.","Token","Input","Input","Output","Output","Global"))
e(t(a,"Count","Count","Bytes","Average","Bytes","Average","Name"))
e(s)
for a=1,#l do
local s=l[a]
local a=A[s]
local h,n=0,0
for t=1,#o do
local e=o[t]
if e.name==s then
h=h+e.xcount
n=n+e.xcount*#e.oldname
end
end
e(t(m,a.decl,a.token,n,i(h,n),
a.size,i(a.token,a.size),s))
end
e(s)
e(t(m,f,u,d,i(c,d),
r,i(u,r),"TOTAL"))
e(s.."\n")
end
local l,o="%-16s%8s%8s%8s%8s%10s","%-16s%8d%8d%8d%8d%10.2f"
local a=s.rep("-",58)
e("*** local variable optimization summary ***\n"..a)
e(t(l,"Variable","Unique","Decl.","Token","Size","Average"))
e(t(l,"Types","Names","Count","Count","Bytes","Bytes"))
e(a)
e(t(o,"Global",m,q,h,n,i(h,n)))
e(a)
e(t(o,"Local (in)",w,p,c,d,i(c,d)))
e(t(o,"TOTAL (in)",T,_,k,v,i(k,v)))
e(a)
e(t(o,"Local (out)",y,f,u,r,i(u,r)))
e(t(o,"TOTAL (out)",z,x,j,b,i(j,b)))
e(a.."\n")
end
local function i(e)
if e<1 or e>=#n then
return
end
local o=y[e]
local t,a=
#n,#h
for e=e+1,t do
n[e-1]=n[e]
k[e-1]=k[e]
y[e-1]=y[e]-1
w[e-1]=w[e]
end
n[t]=nil
k[t]=nil
y[t]=nil
w[t]=nil
for e=o+1,a do
h[e-1]=h[e]
c[e-1]=c[e]
end
h[a]=nil
c[a]=nil
end
local function d()
local function o(e)
local t=n[e+1]or""
local a=n[e+2]or""
local e=n[e+3]or""
if t=="("and a=="<string>"and e==")"then
return true
end
end
local t=1
while true do
local e,a=t,false
while e<=#n do
local n=w[e]
if n=="call"and o(e)then
i(e+1)
i(e+2)
a=true
t=e+2
end
e=e+1
end
if not a then break end
end
end
local function u(h)
b=0
l={}
q=z(x)
E=z(o)
if h["opt-entropy"]then
O(h)
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
local a,t,r={},1,false
for o=1,#e do
local e=e[o]
if not e.isself then
a[t]=e
t=t+1
else
r=true
end
end
e=a
local s=#e
while s>0 do
local n,t
repeat
n,t=I()
until not T[n]
l[#l+1]=n
local a=s
if t then
local i=x[q[n].id].xref
local n=#i
for t=1,s do
local t=e[t]
local s,e=t.act,t.rem
while e<0 do
e=o[-e].rem
end
local o
for t=1,n do
local t=i[t]
if t>=s and t<=e then o=true end
end
if o then
t.skip=true
a=a-1
end
end
end
while a>0 do
local t=1
while e[t].skip do
t=t+1
end
a=a-1
local i=e[t]
t=t+1
i.newname=n
i.skip=true
i.done=true
local s,r=i.first,i.last
local h=i.xref
if s and a>0 then
local n=a
while n>0 do
while e[t].skip do
t=t+1
end
n=n-1
local e=e[t]
t=t+1
local n,t=e.act,e.rem
while t<0 do
t=o[-t].rem
end
if not(r<n or s>t)then
if n>=i.act then
for o=1,i.xcount do
local o=h[o]
if o>=n and o<=t then
a=a-1
e.skip=true
break
end
end
else
if e.last and e.last>=i.act then
a=a-1
e.skip=true
end
end
end
if a==0 then break end
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
local a=e.xref
if e.newname then
for t=1,e.xcount do
local t=a[t]
c[t]=e.newname
end
e.name,e.oldname
=e.newname,e.name
else
e.oldname=e.name
end
end
if r then
l[#l+1]="self"
end
local e=z(o)
N(q,E,e,h)
end
function optimize(t,i,a,e)
h,c
=i,a
n,k,y
=e.toklist,e.seminfolist,e.xreflist
x,o,w
=e.globalinfo,e.localinfo,e.statinfo
if t["opt-locals"]then
u(t)
end
if t["opt-experimental"]then
d()
end
end
end
v.equiv=
function()
module"equiv"
local e=a.require"string"
local r=a.loadstring
local u=e.sub
local d=e.match
local s=e.dump
local p=e.byte
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
function init(o,t,a)
i=o
e=t
h=a
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
local e=r("return "..e,"z")
if e then
return s(e)
end
end
local function o(e)
if i.DETAILS then a.print("SRCEQUIV: "..e)end
h.SRC_EQUIV=true
end
local e,r=n(t)
local a,h=n(l)
local n=d(t,"^(#[^\r\n]*)")
local t=d(l,"^(#[^\r\n]*)")
if n or t then
if not n or not t or n~=t then
o("shbang lines different")
end
end
if#e~=#a then
o("count "..#e.." "..#a)
return
end
for t=1,#e do
local e,s=e[t],a[t]
local a,n=r[t],h[t]
if e~=s then
o("type ["..t.."] "..e.." "..s)
break
end
if e=="TK_KEYWORD"or e=="TK_NAME"or e=="TK_OP"then
if e=="TK_NAME"and i["opt-locals"]then
elseif a~=n then
o("seminfo ["..t.."] "..e.." "..a.." "..n)
break
end
elseif e=="TK_EOS"then
else
local i,s=u(a),u(n)
if not i or not s or i~=s then
o("seminfo ["..t.."] "..e.." "..a.." "..n)
break
end
end
end
end
function binary(n,o)
local e=0
local q=1
local k=3
local j=4
local function e(e)
if i.DETAILS then a.print("BINEQUIV: "..e)end
h.BIN_EQUIV=true
end
local function a(e)
local t=d(e,"^(#[^\r\n]*\r?\n?)")
if t then
e=u(e,#t+1)
end
return e
end
local t=r(a(n),"z")
if not t then
e("failed to compile original sources for binary chunk comparison")
return
end
local a=r(a(o),"z")
if not a then
e("failed to compile compressed result for binary chunk comparison")
end
local i={i=1,dat=s(t)}
i.len=#i.dat
local l={i=1,dat=s(a)}
l.len=#l.dat
local g,
d,c,
y,w,
o,m
local function s(e,t)
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
return p(a)
end
local function x(a)
local e,t=0,1
if not s(a,d)then return end
for o=1,d do
e=e+t*n(a)
t=t*256
end
return e
end
local function z(t)
local e=0
if not s(t,d)then return end
for a=1,d do
e=e*256+n(t)
end
return e
end
local function E(a)
local t,e=0,1
if not s(a,c)then return end
for o=1,c do
t=t+e*n(a)
e=e*256
end
return t
end
local function _(t)
local e=0
if not s(t,c)then return end
for a=1,c do
e=e*256+n(t)
end
return e
end
local function r(e,o)
local t=e.i
local a=t+o-1
if a>e.len then return end
local a=u(e.dat,t,a)
e.i=t+o
return a
end
local function h(t)
local e=m(t)
if not e then return end
if e==0 then return""end
return r(t,e)
end
local function v(t,e)
local e,t=n(t),n(e)
if not e or not t or e~=t then
return
end
return e
end
local function u(e,t)
local e=v(e,t)
if not e then return true end
end
local function p(t,e)
local e,t=o(t),o(e)
if not e or not t or e~=t then
return
end
return e
end
local function b(t,a)
if not h(t)or not h(a)then
e("bad source name");return
end
if not o(t)or not o(a)then
e("bad linedefined");return
end
if not o(t)or not o(a)then
e("bad lastlinedefined");return
end
if not(s(t,4)and s(a,4))then
e("prototype header broken")
end
if u(t,a)then
e("bad nups");return
end
if u(t,a)then
e("bad numparams");return
end
if u(t,a)then
e("bad is_vararg");return
end
if u(t,a)then
e("bad maxstacksize");return
end
local i=p(t,a)
if not i then
e("bad ncode");return
end
local n=r(t,i*y)
local i=r(a,i*y)
if not n or not i or n~=i then
e("bad code block");return
end
local i=p(t,a)
if not i then
e("bad nconst");return
end
for o=1,i do
local o=v(t,a)
if not o then
e("bad const type");return
end
if o==q then
if u(t,a)then
e("bad boolean value");return
end
elseif o==k then
local t=r(t,w)
local a=r(a,w)
if not t or not a or t~=a then
e("bad number value");return
end
elseif o==j then
local t=h(t)
local a=h(a)
if not t or not a or t~=a then
e("bad string value");return
end
end
end
local i=p(t,a)
if not i then
e("bad nproto");return
end
for o=1,i do
if not b(t,a)then
e("bad function prototype");return
end
end
local i=o(t)
if not i then
e("bad sizelineinfo1");return
end
local n=o(a)
if not n then
e("bad sizelineinfo2");return
end
if not r(t,i*d)then
e("bad lineinfo1");return
end
if not r(a,n*d)then
e("bad lineinfo2");return
end
local i=o(t)
if not i then
e("bad sizelocvars1");return
end
local n=o(a)
if not n then
e("bad sizelocvars2");return
end
for a=1,i do
if not h(t)or not o(t)or not o(t)then
e("bad locvars1");return
end
end
for t=1,n do
if not h(a)or not o(a)or not o(a)then
e("bad locvars2");return
end
end
local i=o(t)
if not i then
e("bad sizeupvalues1");return
end
local o=o(a)
if not o then
e("bad sizeupvalues2");return
end
for a=1,i do
if not h(t)then e("bad upvalues1");return end
end
for t=1,o do
if not h(a)then e("bad upvalues2");return end
end
return true
end
if not(s(i,12)and s(l,12))then
e("header broken")
end
f(i,6)
g=n(i)
d=n(i)
c=n(i)
y=n(i)
w=n(i)
f(i)
f(l,12)
if g==1 then
o=x
m=E
else
o=z
m=_
end
b(i,l)
if i.i~=i.len+1 then
e("inconsistent binary chunk1");return
elseif l.i~=l.len+1 then
e("inconsistent binary chunk2");return
end
end
end
v["plugin/html"]=
function()
module"plugin/html"
local t=a.require"string"
local m=a.require"table"
local r=a.require"io"
local h=".html"
local l={
["&"]="&amp;",["<"]="&lt;",[">"]="&gt;",
["'"]="&apos;",["\""]="&quot;",
}
local f=[[
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
local y=[[
</pre>
</body>
</html>
]]
local w=[[
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
local i
local e,n
local o,d,u
local function s(...)
if i.QUIET then return end
a.print(...)
end
function init(o,s,r)
i=o
e=s
local o,d=t.find(e,"%.[^%.%\\%/]*$")
local s,r=e,""
if o and o>1 then
s=t.sub(e,1,o-1)
r=t.sub(e,o,d)
end
n=s..h
if i.OUTPUT_FILE then
n=i.OUTPUT_FILE
end
if e==n then
a.error("output filename identical to input filename")
end
end
function post_load(t)
s([[
HTML plugin module for LuaSrcDiet
]])
s("Exporting: "..e.." -> "..n.."\n")
end
function post_lex(e,a,t)
o,d,u
=e,a,t
end
local function h(a)
local e=1
while e<=#a do
local o=t.sub(a,e,e)
local i=l[o]
if i then
o=i
a=t.sub(a,1,e-1)..o..t.sub(a,e+1)
end
e=e+#o
end
return a
end
local function c(t,o)
local e=r.open(t,"wb")
if not e then a.error("cannot open \""..t.."\" for writing")end
local o=e:write(o)
if not o then a.error("cannot write to \""..t.."\"")end
e:close()
end
function post_parse(u,l)
local r={}
local function s(e)
r[#r+1]=e
end
local function a(e,t)
s('<span class="'..e..'">'..t..'</span>')
end
for e=1,#u do
local e=u[e]
local e=e.xref
for t=1,#e do
local e=e[t]
o[e]="TK_GLOBAL"
end
end
for e=1,#l do
local e=l[e]
local e=e.xref
for t=1,#e do
local e=e[t]
o[e]="TK_LOCAL"
end
end
s(t.format(f,
h(e),
w))
for e=1,#o do
local e,t=o[e],d[e]
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
s(y)
c(n,m.concat(r))
i.EXIT=true
end
end
v["plugin/sloc"]=
function()
module"plugin/sloc"
local n=a.require"string"
local e=a.require"table"
local o
local s
function init(t,e,a)
o=t
o.QUIET=true
s=e
end
local function h(o)
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
function post_lex(t,d,r)
local e,n=0,0
local function i(t)
if t>e then
n=n+1;e=t
end
end
for e=1,#t do
local t,a,e
=t[e],d[e],r[e]
if t=="TK_KEYWORD"or t=="TK_NAME"or
t=="TK_NUMBER"or t=="TK_OP"then
i(e)
elseif t=="TK_STRING"then
local t=h(a)
e=e-#t+1
for t=1,#t do
i(e);e=e+1
end
elseif t=="TK_LSTRING"then
local t=h(a)
e=e-#t+1
for a=1,#t do
if t[a]~=""then i(e)end
e=e+1
end
end
end
a.print(s..": "..n)
o.EXIT=true
end
end
local o=g"llex"
local l=g"lparser"
local x=g"optlex"
local T=g"optparser"
local j=g"equiv"
local a
local v=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.12.0 (20110913)  Copyright (c) 2005-2008,2011 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]
local f=[[
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
local b=[[
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
local E=[[
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
local A=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]
local n="_"
local I="plugin/"
local function i(e)
p("LuaSrcDiet (error): "..e);os.exit(1)
end
if not X(_VERSION,"5.1",1,1)then
i("requires Lua 5.1 to run")
end
local t=""
do
local i=24
local o={}
for a,n in Z(b,"%s*([^,]+),'([^']+)'")do
local e="  "..a
e=e..s.rep(" ",i-#e)..n.."\n"
t=t..e
o[a]=true
o["--no"..y(a,3)]=true
end
b=o
end
f=s.format(f,t,E)
if W then
local e="\nembedded plugins:\n"
for t=1,#W do
local t=W[t]
e=e.."  "..te[t].."\n"
end
f=f..e
end
local _=n
local e={}
local n,h
local function w(t)
for t in Z(t,"(%-%-%S+)")do
if y(t,3,4)=="no"and
b["--"..y(t,5)]then
e[y(t,5)]=false
else
e[y(t,3)]=true
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
local u=7
local c={
["\n"]="LF",["\r"]="CR",
["\n\r"]="LFCR",["\r\n"]="CRLF",
}
local function r(t)
local e=io.open(t,"rb")
if not e then i('cannot open "'..t..'" for reading')end
local a=e:read("*a")
if not a then i('cannot read from "'..t..'"')end
e:close()
return a
end
local function L(t,a)
local e=io.open(t,"wb")
if not e then i('cannot open "'..t..'" for writing')end
local a=e:write(a)
if not a then i('cannot write to "'..t..'"')end
e:close()
end
local function z()
n,h={},{}
for e=1,#d do
local e=d[e]
n[e],h[e]=0,0
end
end
local function q(e,t)
n[e]=n[e]+1
h[e]=h[e]+#t
end
local function k()
local function i(e,t)
if e==0 then return 0 end
return t/e
end
local o={}
local e,t=0,0
for a=1,u do
local a=d[a]
e=e+n[a];t=t+h[a]
end
n.TOTAL_TOK,h.TOTAL_TOK=e,t
o.TOTAL_TOK=i(e,t)
e,t=0,0
for a=1,#d do
local a=d[a]
e=e+n[a];t=t+h[a]
o[a]=i(n[a],h[a])
end
n.TOTAL_ALL,h.TOTAL_ALL=e,t
o.TOTAL_ALL=i(e,t)
return o
end
local function S(e)
local e=r(e)
o.init(e)
o.llex()
local e,a=o.tok,o.seminfo
for t=1,#e do
local t,e=e[t],a[t]
if t=="TK_OP"and s.byte(e)<32 then
e="("..s.byte(e)..")"
elseif t=="TK_EOL"then
e=c[e]
else
e="'"..e.."'"
end
p(t.." "..e)
end
end
local function R(e)
local a=p
local e=r(e)
o.init(e)
o.llex()
local o,t,e
=o.tok,o.seminfo,o.tokln
l.init(o,t,e)
local e=l.parser()
local t,i=
e.globalinfo,e.localinfo
local o=s.rep("-",72)
a("*** Local/Global Variable Tracker Tables ***")
a(o.."\n GLOBALS\n"..o)
for e=1,#t do
local t=t[e]
local e="("..e..") '"..t.name.."' -> "
local t=t.xref
for o=1,#t do e=e..t[o].." "end
a(e)
end
a(o.."\n LOCALS (decl=declared act=activated rem=removed)\n"..o)
for e=1,#i do
local t=i[e]
local e="("..e..") '"..t.name.."' decl:"..t.decl..
" act:"..t.act.." rem:"..t.rem
if t.isself then
e=e.." isself"
end
e=e.." -> "
local t=t.xref
for o=1,#t do e=e..t[o].." "end
a(e)
end
a(o.."\n")
end
local function D(a)
local e=p
local t=r(a)
o.init(t)
o.llex()
local t,o=o.tok,o.seminfo
e(v)
e("Statistics for: "..a.."\n")
z()
for e=1,#t do
local t,e=t[e],o[e]
q(t,e)
end
local t=k()
local a=s.format
local function r(e)
return n[e],h[e],t[e]
end
local o,i="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"
local t=s.rep("-",42)
e(a(o,"Lexical","Input","Input","Input"))
e(a(o,"Elements","Count","Bytes","Average"))
e(t)
for o=1,#d do
local o=d[o]
e(a(i,o,r(o)))
if o=="TK_EOS"then e(t)end
end
e(t)
e(a(i,"Total Elements",r("TOTAL_ALL")))
e(t)
e(a(i,"Total Tokens",r("TOTAL_TOK")))
e(t.."\n")
end
local function H(f,w)
local function t(...)
if e.QUIET then return end
_G.print(...)
end
if a and a.init then
e.EXIT=false
a.init(e,f,w)
if e.EXIT then return end
end
t(v)
local c=r(f)
if a and a.post_load then
c=a.post_load(c)or c
if e.EXIT then return end
end
o.init(c)
o.llex()
local r,u,m
=o.tok,o.seminfo,o.tokln
if a and a.post_lex then
a.post_lex(r,u,m)
if e.EXIT then return end
end
z()
for e=1,#r do
local e,t=r[e],u[e]
q(e,t)
end
local p=k()
local v,y=n,h
T.print=t
l.init(r,u,m)
local l=l.parser()
if a and a.post_parse then
a.post_parse(l.globalinfo,l.localinfo)
if e.EXIT then return end
end
T.optimize(e,r,u,l)
if a and a.post_optparse then
a.post_optparse()
if e.EXIT then return end
end
local l=x.warn
x.print=t
r,u,m
=x.optimize(e,r,u,m)
if a and a.post_optlex then
a.post_optlex(r,u,m)
if e.EXIT then return end
end
local a=ee.concat(u)
if s.find(a,"\r\n",1,1)or
s.find(a,"\n\r",1,1)then
l.MIXEDEOL=true
end
j.init(e,o,l)
j.source(c,a)
j.binary(c,a)
local m="before and after lexer streams are NOT equivalent!"
local c="before and after binary chunks are NOT equivalent!"
if l.SRC_EQUIV then
if e["opt-srcequiv"]then i(m)end
else
t("*** SRCEQUIV: token streams are sort of equivalent")
if e["opt-locals"]then
t("(but no identifier comparisons since --opt-locals enabled)")
end
t()
end
if l.BIN_EQUIV then
if e["opt-binequiv"]then i(c)end
else
t("*** BINEQUIV: binary chunks are sort of equivalent")
t()
end
L(w,a)
z()
for e=1,#r do
local t,e=r[e],u[e]
q(t,e)
end
local o=k()
t("Statistics for: "..f.." -> "..w.."\n")
local a=s.format
local function r(e)
return v[e],y[e],p[e],
n[e],h[e],o[e]
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
if l.LSTRING then
t("* WARNING: "..l.LSTRING)
elseif l.MIXEDEOL then
t("* WARNING: ".."output still contains some CRLF or LFCR line endings")
elseif l.SRC_EQUIV then
t("* WARNING: "..m)
elseif l.BIN_EQUIV then
t("* WARNING: "..c)
end
t()
end
local r={...}
local h={}
w(E)
local function l(n)
for t=1,#n do
local t=n[t]
local a
local o,r=s.find(t,"%.[^%.%\\%/]*$")
local h,s=t,""
if o and o>1 then
h=y(t,1,o-1)
s=y(t,o,r)
end
a=h.._..s
if#n==1 and e.OUTPUT_FILE then
a=e.OUTPUT_FILE
end
if t==a then
i("output filename identical to input filename")
end
if e.DUMP_LEXER then
S(t)
elseif e.DUMP_PARSER then
R(t)
elseif e.READ_ONLY then
D(t)
else
H(t,a)
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
local s=X(t,"^%-%-?")
if s=="-"then
if t=="-h"then
e.HELP=true;break
elseif t=="-v"then
e.VERSION=true;break
elseif t=="-s"then
if not n then i("-s option needs suffix specification")end
_=n
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
a=g(I..n)
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
w(A)
elseif t=="--dump-lexer"then
e.DUMP_LEXER=true
elseif t=="--dump-parser"then
e.DUMP_PARSER=true
elseif t=="--details"then
e.DETAILS=true
elseif b[t]then
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
p(v..f);return true
elseif e.VERSION then
p(v);return true
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
