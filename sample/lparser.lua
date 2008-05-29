local N=_G
local U=require"string"module"lparser"local X=N.getfenv()local _,k,z,C,l,u,K,t,g,s,x,y,a,Q,j,D,n,p,A
local v,r,w,E,T
local L=U.gmatch
local R={}for e in L("else elseif end until <eof>","%S+")do
R[e]=true
end
local Z={}for e in L("if while do for repeat function local return break","%S+")do
Z[e]=e.."_stat"end
local S={}local B={}for e,t,a in L([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")do
S[e]=t+0
B[e]=a+0
end
local oe={["not"]=true,["-"]=true,["#"]=true,}local ae=8
local function te(a,e)local t=error or N.error
t(U.format("(source):%d: %s",e or s,a))end
local function e()K=z[l]t,g,s,x=_[l],k[l],z[l],C[l]l=l+1
end
local function ee()return _[l]end
local function h(a)local e=t
if e~="<number>"and e~="<string>"then
if e=="<name>"then e=g end
e="'"..e.."'"end
te(a.." near "..e)end
local function V(e)h("'"..e.."' expected")end
local function o(a)if t==a then e();return true end
end
local function L(e)if t~=e then V(e)end
end
local function i(t)L(t);e()end
local function G(e,t)if not e then h(t)end
end
local function d(e,a,t)if not o(e)then
if t==s then
V(e)else
h("'"..e.."' expected (to close '"..a.."' at line "..t..")")end
end
end
local function f()L("<name>")local t=g
y=x
e()return t
end
local function H(e,t)e.k="VK"end
local function O(e)H(e,f())end
local function m(s,i)local o=a.bl
local e
if o then
e=o.locallist
else
e=a.locallist
end
local t=#n+1
n[t]={name=s,xref={y},decl=y,}if i then
n[t].isself=true
end
local a=#p+1
p[a]=t
A[a]=e
end
local function q(e)local s=#p
while e>0 do
e=e-1
local e=s-e
local a=p[e]local t=n[a]local o=t.name
t.act=x
p[e]=nil
local i=A[e]A[e]=nil
local e=i[o]if e then
t=n[e]t.rem=-a
end
i[o]=a
end
end
local function P()local t=a.bl
local e
if t then
e=t.locallist
else
e=a.locallist
end
for t,e in N.pairs(e)do
local e=n[e]e.rem=x
end
end
local function c(e,t)if U.sub(e,1,1)=="("then
return
end
m(e,t)end
local function te(a,t)local e=a.bl
if e then
locallist=e.locallist
while locallist do
if locallist[t]then return locallist[t]end
e=e.prev
locallist=e and e.locallist
end
end
locallist=a.locallist
return locallist[t]or-1
end
local function V(t,a,e)if t==nil then
e.k="VGLOBAL"return"VGLOBAL"else
local o=te(t,a)if o>=0 then
e.k="VLOCAL"e.id=o
return"VLOCAL"else
if V(t.prev,a,e)=="VGLOBAL"then
return"VGLOBAL"end
e.k="VUPVAL"return"VUPVAL"end
end
end
local function J(o)local t=f()V(a,t,o)if o.k=="VGLOBAL"then
local e=D[t]if not e then
e=#j+1
j[e]={name=t,xref={y},}D[t]=e
else
local e=j[e].xref
e[#e+1]=y
end
else
local t=o.id
local e=n[t].xref
e[#e+1]=y
end
end
local function b(t)local e={}e.isbreakable=t
e.prev=a.bl
e.locallist={}a.bl=e
end
local function y()local e=a.bl
P()a.bl=e.prev
end
local function F()local e
if not a then
e=Q
else
e={}end
e.prev=a
e.bl=nil
e.locallist={}a=e
end
local function M()P()a=a.prev
end
local function x(a)local t={}e()O(t)a.k="VINDEXED"end
local function N(t)e()r(t)i("]")end
local function U(o)local e,a={},{}if t=="<name>"then
O(e)else
N(e)end
i("=")r(a)end
local function V(e)if e.v.k=="VVOID"then return end
e.v.k="VVOID"end
local function W(e)r(e.v)end
local function Y(a)local n=s
local e={}e.v={}e.t=a
a.k="VRELOCABLE"e.v.k="VVOID"i("{")repeat
if t=="}"then break end
local t=t
if t=="<name>"then
if ee()~="="then
W(e)else
U(e)end
elseif t=="["then
U(e)else
W(e)end
until not o(",")and not o(";")d("}","{",n)end
local function W()local i=0
if t~=")"then
repeat
local t=t
if t=="<name>"then
m(f())i=i+1
elseif t=="..."then
e()a.is_vararg=true
else
h("<name> or '...' expected")end
until a.is_vararg or not o(",")end
q(i)end
local function U(n)local a={}local i=s
local o=t
if o=="("then
if i~=K then
h("ambiguous syntax (function call x new statement)")end
e()if t==")"then
a.k="VVOID"else
v(a)end
d(")","(",i)elseif o=="{"then
Y(a)elseif o=="<string>"then
H(a,g)e()else
h("function arguments expected")return
end
n.k="VCALL"end
local function P(a)local t=t
if t=="("then
local t=s
e()r(a)d(")","(",t)elseif t=="<name>"then
J(a)else
h("unexpected symbol")end
end
local function I(a)P(a)while true do
local t=t
if t=="."then
x(a)elseif t=="["then
local e={}N(e)elseif t==":"then
local t={}e()O(t)U(a)elseif t=="("or t=="<string>"or t=="{"then
U(a)else
return
end
end
end
local function U(o)local t=t
if t=="<number>"then
o.k="VKNUM"elseif t=="<string>"then
H(o,g)elseif t=="nil"then
o.k="VNIL"elseif t=="true"then
o.k="VTRUE"elseif t=="false"then
o.k="VFALSE"elseif t=="..."then
G(a.is_vararg==true,"cannot use '...' outside a vararg function");o.k="VVARARG"elseif t=="{"then
Y(o)return
elseif t=="function"then
e()T(o,false,s)return
else
I(o)return
end
e()end
local function g(o,i)local a=t
local n=oe[a]if n then
e()g(o,ae)else
U(o)end
a=t
local t=S[a]while t and t>i do
local o={}e()local e=g(o,B[a])a=e
t=S[a]end
return a
end
function r(e)g(e,0)end
local function O(a)local t={}local e=a.v.k
G(e=="VLOCAL"or e=="VUPVAL"or e=="VGLOBAL"or e=="VINDEXED","syntax error")if o(",")then
local e={}e.v={}I(e.v)O(e)else
i("=")v(t)return
end
t.k="VNONRELOC"end
local function N(e,t)i("do")b(false)q(e)w()y()end
local function U(e)local t=u
c("(for index)")c("(for limit)")c("(for step)")m(e)i("=")E()i(",")E()if o(",")then
E()else
end
N(1,true)end
local function H(a)local t={}c("(for generator)")c("(for state)")c("(for control)")m(a)local e=1
while o(",")do
m(f())e=e+1
end
i("in")local a=u
v(t)N(e,false)end
local function S(e)local a=false
J(e)while t=="."do
x(e)end
if t==":"then
a=true
x(e)end
return a
end
function E()local e={}r(e)end
local function g()local e={}r(e)end
local function x()e()g()i("then")w()end
local function E()local t,e={}m(f())t.k="VLOCAL"q(1)T(e,false,s)end
local function N()local e=0
local t={}repeat
m(f())e=e+1
until not o(",")if o("=")then
v(t)else
t.k="VVOID"end
q(e)end
function v(e)r(e)while o(",")do
r(e)end
end
function T(a,t,e)F()i("(")if t then
c("self",true)q(1)end
W()i(")")chunk()d("end","function",e)M()end
function w()b(false)chunk()y()end
function for_stat()local o=u
b(true)e()local a=f()local e=t
if e=="="then
U(a)elseif e==","or e=="in"then
H(a)else
h("'=' or 'in' expected")end
d("end","for",o)y()end
function while_stat()local t=u
e()g()b(true)i("do")w()d("end","while",t)y()end
function repeat_stat()local t=u
b(true)b(false)e()chunk()d("until","repeat",t)g()y()y()end
function if_stat()local a=u
local o={}x()while t=="elseif"do
x()end
if t=="else"then
e()w()end
d("end","if",a)end
function return_stat()local a={}e()local e=t
if R[e]or e==";"then
else
v(a)end
end
function break_stat()local t=a.bl
e()while t and not t.isbreakable do
t=t.prev
end
if not t then
h("no loop to break")end
end
function expr_stat()local e={}e.v={}I(e.v)if e.v.k=="VCALL"then
else
e.prev=nil
O(e)end
end
function function_stat()local o=u
local a,t={},{}e()local e=S(a)T(t,e,o)end
function do_stat()local t=u
e()w()d("end","do",t)end
function local_stat()e()if o("function")then
E()else
N()end
end
local function h()u=s
local e=t
local t=Z[e]if t then
X[t]()if e=="return"or e=="break"then return true end
else
expr_stat()end
return false
end
function chunk()local e=false
while not e and not R[t]do
e=h()o(";")end
end
function parser()F()a.is_vararg=true
e()chunk()L("<eof>")M()return j,n
end
function init(o,i,s)l=1
Q={}local t=1
_,k,z,C={},{},{},{}for a=1,#o do
local e=o[a]local o=true
if e=="TK_KEYWORD"or e=="TK_OP"then
e=i[a]elseif e=="TK_NAME"then
e="<name>"k[t]=i[a]elseif e=="TK_NUMBER"then
e="<number>"k[t]=0
elseif e=="TK_STRING"or e=="TK_LSTRING"then
e="<string>"k[t]=""elseif e=="TK_EOS"then
e="<eof>"else
o=false
end
if o then
_[t]=e
z[t]=s[a]C[t]=a
t=t+1
end
end
j,D,n={},{},{}p,A={},{}end
return X
