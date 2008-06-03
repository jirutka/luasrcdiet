local K=_G
local P=require"string"module"lparser"local Y=K.getfenv()local E,m,N,B,d,f,F,n,O,u,w,b,l,W,A,S,a,v,D
local p,c,_,I,T,x
local C=P.gmatch
local U={}for e in C("else elseif end until <eof>","%S+")do
U[e]=true
end
local q={}for e in C("if while do for repeat function local return break","%S+")do
q[e]=e.."_stat"end
local M={}local y={}for e,l,n in C([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")do
M[e]=l+0
y[e]=n+0
end
local ce={["not"]=true,["-"]=true,["#"]=true,}local te=8
local function le(l,n)local e=error or K.error
e(P.format("(source):%d: %s",n or u,l))end
local function e()F=N[d]n,O,u,w=E[d],m[d],N[d],B[d]d=d+1
end
local function oe()return E[d]end
local function r(l)local e=n
if e~="<number>"and e~="<string>"then
if e=="<name>"then e=O end
e="'"..e.."'"end
le(l.." near "..e)end
local function Z(e)r("'"..e.."' expected")end
local function t(l)if n==l then e();return true end
end
local function R(e)if n~=e then Z(e)end
end
local function o(n)R(n);e()end
local function ee(n,e)if not n then r(e)end
end
local function i(e,l,n)if not t(e)then
if n==u then
Z(e)else
r("'"..e.."' expected (to close '"..l.."' at line "..n..")")end
end
end
local function V()R("<name>")local n=O
b=w
e()return n
end
local function G(e,n)e.k="VK"end
local function C(e)G(e,V())end
local function h(t,c)local o=l.bl
local n
if o then
n=o.locallist
else
n=l.locallist
end
local e=#a+1
a[e]={name=t,xref={b},decl=b,}if c then
a[e].isself=true
end
local l=#v+1
v[l]=e
D[l]=n
end
local function g(n)local c=#v
while n>0 do
n=n-1
local e=c-n
local l=v[e]local n=a[l]local o=n.name
n.act=w
v[e]=nil
local t=D[e]D[e]=nil
local e=t[o]if e then
n=a[e]n.rem=-l
end
t[o]=l
end
end
local function H()local n=l.bl
local e
if n then
e=n.locallist
else
e=l.locallist
end
for l,n in K.pairs(e)do
local e=a[n]e.rem=w
end
end
local function s(e,n)if P.sub(e,1,1)=="("then
return
end
h(e,n)end
local function ne(o,l)local n=o.bl
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
local function z(n,o,e)if n==nil then
e.k="VGLOBAL"return"VGLOBAL"else
local l=ne(n,o)if l>=0 then
e.k="VLOCAL"e.id=l
return"VLOCAL"else
if z(n.prev,o,e)=="VGLOBAL"then
return"VGLOBAL"end
e.k="VUPVAL"return"VUPVAL"end
end
end
local function j(o)local n=V()z(l,n,o)if o.k=="VGLOBAL"then
local e=S[n]if not e then
e=#A+1
A[e]={name=n,xref={b},}S[n]=e
else
local e=A[e].xref
e[#e+1]=b
end
else
local n=o.id
local e=a[n].xref
e[#e+1]=b
end
end
local function k(n)local e={}e.isbreakable=n
e.prev=l.bl
e.locallist={}l.bl=e
end
local function L()local e=l.bl
H()l.bl=e.prev
end
local function Z()local e
if not l then
e=W
else
e={}end
e.prev=l
e.bl=nil
e.locallist={}l=e
end
local function z()H()l=l.prev
end
local function b(n)local l={}e()C(l)n.k="VINDEXED"end
local function Q(n)e()c(n)o("]")end
local function J(t)local e,l={},{}if n=="<name>"then
C(e)else
Q(e)end
o("=")c(l)end
local function H(e)if e.v.k=="VVOID"then return end
e.v.k="VVOID"end
local function P(e)c(e.v)end
local function X(l)local c=u
local e={}e.v={}e.t=l
l.k="VRELOCABLE"e.v.k="VVOID"o("{")repeat
if n=="}"then break end
local n=n
if n=="<name>"then
if oe()~="="then
P(e)else
J(e)end
elseif n=="["then
J(e)else
P(e)end
until not t(",")and not t(";")i("}","{",c)end
local function J()local o=0
if n~=")"then
repeat
local n=n
if n=="<name>"then
h(V())o=o+1
elseif n=="..."then
e()l.is_vararg=true
else
r("<name> or '...' expected")end
until l.is_vararg or not t(",")end
g(o)end
local function K(c)local l={}local t=u
local o=n
if o=="("then
if t~=F then
r("ambiguous syntax (function call x new statement)")end
e()if n==")"then
l.k="VVOID"else
p(l)end
i(")","(",t)elseif o=="{"then
X(l)elseif o=="<string>"then
G(l,O)e()else
r("function arguments expected")return
end
c.k="VCALL"end
local function F(l)local n=n
if n=="("then
local n=u
e()c(l)i(")","(",n)elseif n=="<name>"then
j(l)else
r("unexpected symbol")end
end
local function w(l)F(l)while true do
local n=n
if n=="."then
b(l)elseif n=="["then
local e={}Q(e)elseif n==":"then
local n={}e()C(n)K(l)elseif n=="("or n=="<string>"or n=="{"then
K(l)else
return
end
end
end
local function F(o)local n=n
if n=="<number>"then
o.k="VKNUM"elseif n=="<string>"then
G(o,O)elseif n=="nil"then
o.k="VNIL"elseif n=="true"then
o.k="VTRUE"elseif n=="false"then
o.k="VFALSE"elseif n=="..."then
ee(l.is_vararg==true,"cannot use '...' outside a vararg function");o.k="VVARARG"elseif n=="{"then
X(o)return
elseif n=="function"then
e()T(o,false,u)return
else
w(o)return
end
e()end
local function O(o,c)local l=n
local t=ce[l]if t then
e()O(o,te)else
F(o)end
l=n
local n=M[l]while n and n>c do
local o={}e()local e=O(o,y[l])l=e
n=M[l]end
return l
end
function c(e)O(e,0)end
local function O(l)local n={}local e=l.v.k
ee(e=="VLOCAL"or e=="VUPVAL"or e=="VGLOBAL"or e=="VINDEXED","syntax error")if t(",")then
local e={}e.v={}w(e.v)O(e)else
o("=")p(n)return
end
n.k="VNONRELOC"end
local function K(e,n)o("do")k(false)g(e)_()L()end
local function M(e)local n=f
s("(for index)")s("(for limit)")s("(for step)")h(e)o("=")I()o(",")I()if t(",")then
I()else
end
K(1,true)end
local function P(l)local n={}s("(for generator)")s("(for state)")s("(for control)")h(l)local e=1
while t(",")do
h(V())e=e+1
end
o("in")local l=f
p(n)K(e,false)end
local function C(e)local l=false
j(e)while n=="."do
b(e)end
if n==":"then
l=true
b(e)end
return l
end
function I()local e={}c(e)end
local function b()local e={}c(e)end
local function I()e()b()o("then")_()end
local function G()local e,n={}h(V())e.k="VLOCAL"g(1)T(n,false,u)end
local function K()local e=0
local n={}repeat
h(V())e=e+1
until not t(",")if t("=")then
p(n)else
n.k="VVOID"end
g(e)end
function p(e)c(e)while t(",")do
c(e)end
end
function T(l,e,n)Z()o("(")if e then
s("self",true)g(1)end
J()o(")")x()i("end","function",n)z()end
function _()k(false)x()L()end
function for_stat()local o=f
k(true)e()local l=V()local e=n
if e=="="then
M(l)elseif e==","or e=="in"then
P(l)else
r("'=' or 'in' expected")end
i("end","for",o)L()end
function while_stat()local n=f
e()b()k(true)o("do")_()i("end","while",n)L()end
function repeat_stat()local n=f
k(true)k(false)e()x()i("until","repeat",n)b()L()L()end
function if_stat()local l=f
local o={}I()while n=="elseif"do
I()end
if n=="else"then
e()_()end
i("end","if",l)end
function return_stat()local l={}e()local e=n
if U[e]or e==";"then
else
p(l)end
end
function break_stat()local n=l.bl
e()while n and not n.isbreakable do
n=n.prev
end
if not n then
r("no loop to break")end
end
function expr_stat()local e={}e.v={}w(e.v)if e.v.k=="VCALL"then
else
e.prev=nil
O(e)end
end
function function_stat()local l=f
local o,n={},{}e()local e=C(o)T(n,e,l)end
function do_stat()local n=f
e()_()i("end","do",n)end
function local_stat()e()if t("function")then
G()else
K()end
end
local function c()f=u
local e=n
local n=q[e]if n then
Y[n]()if e=="return"or e=="break"then return true end
else
expr_stat()end
return false
end
function x()local e=false
while not e and not U[n]do
e=c()t(";")end
end
function parser()Z()l.is_vararg=true
e()x()R("<eof>")z()return A,a
end
function init(t,o,c)d=1
W={}local n=1
E,m,N,B={},{},{},{}for l=1,#t do
local e=t[l]local t=true
if e=="TK_KEYWORD"or e=="TK_OP"then
e=o[l]elseif e=="TK_NAME"then
e="<name>"m[n]=o[l]elseif e=="TK_NUMBER"then
e="<number>"m[n]=0
elseif e=="TK_STRING"or e=="TK_LSTRING"then
e="<string>"m[n]=""elseif e=="TK_EOS"then
e="<eof>"else
t=false
end
if t then
E[n]=e
N[n]=c[l]B[n]=l
n=n+1
end
end
A,S,a={},{},{}v,D={},{}end
return Y
