local k=_G
local D=require"string"module"lparser"local W=k.getfenv()local g,_,E,R,d,f,X,n,m,u,s,L,l,F,O,C,a,v,I
local p,c,b,w,N,A
local e=D.gmatch
local S={}for e in e("else elseif end until <eof>","%S+")do
S[e]=true
end
local Y={}for e in e("if while do for repeat function local return break","%S+")do
Y[e]=e.."_stat"end
local U={}local P={}for e,l,n in e([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")do
U[e]=l+0
P[e]=n+0
end
local ee={["not"]=true,["-"]=true,["#"]=true,}local Z=8
local function o(l,n)local e=error or k.error
e(D.format("(source):%d: %s",n or u,l))end
local function e()X=E[d]n,m,u,s=g[d],_[d],E[d],R[d]d=d+1
end
local function z()return g[d]end
local function r(l)local e=n
if e~="<number>"and e~="<string>"then
if e=="<name>"then e=m end
e="'"..e.."'"end
o(l.." near "..e)end
local function h(e)r("'"..e.."' expected")end
local function t(l)if n==l then e();return true end
end
local function G(e)if n~=e then h(e)end
end
local function o(n)G(n);e()end
local function j(n,e)if not n then r(e)end
end
local function i(e,l,n)if not t(e)then
if n==u then
h(e)else
r("'"..e.."' expected (to close '"..l.."' at line "..n..")")end
end
end
local function V()G("<name>")local n=m
L=s
e()return n
end
local function K(e,n)e.k="VK"end
local function B(e)K(e,V())end
local function h(o,t)local e=l.bl
local n
if e then
n=e.locallist
else
n=l.locallist
end
local e=#a+1
a[e]={name=o,xref={L},decl=L,}if t then
a[e].isself=true
end
local l=#v+1
v[l]=e
I[l]=n
end
local function x(e)local n=#v
while e>0 do
e=e-1
local e=n-e
local l=v[e]local n=a[l]local o=n.name
n.act=s
v[e]=nil
local t=I[e]I[e]=nil
local e=t[o]if e then
n=a[e]n.rem=-l
end
t[o]=l
end
end
local function T()local n=l.bl
local e
if n then
e=n.locallist
else
e=l.locallist
end
for n,e in k.pairs(e)do
local e=a[e]e.rem=s
end
end
local function s(e,n)if D.sub(e,1,1)=="("then
return
end
h(e,n)end
local function D(o,l)local n=o.bl
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
local function k(n,o,e)if n==nil then
e.k="VGLOBAL"return"VGLOBAL"else
local l=D(n,o)if l>=0 then
e.k="VLOCAL"e.id=l
return"VLOCAL"else
if k(n.prev,o,e)=="VGLOBAL"then
return"VGLOBAL"end
e.k="VUPVAL"return"VUPVAL"end
end
end
local function J(o)local n=V()k(l,n,o)if o.k=="VGLOBAL"then
local e=C[n]if not e then
e=#O+1
O[e]={name=n,xref={L},}C[n]=e
else
local e=O[e].xref
e[#e+1]=L
end
else
local e=o.id
local e=a[e].xref
e[#e+1]=L
end
end
local function k(n)local e={}e.isbreakable=n
e.prev=l.bl
e.locallist={}l.bl=e
end
local function L()local e=l.bl
T()l.bl=e.prev
end
local function H()local e
if not l then
e=F
else
e={}end
e.prev=l
e.bl=nil
e.locallist={}l=e
end
local function Q()T()l=l.prev
end
local function D(n)local l={}e()B(l)n.k="VINDEXED"end
local function q(n)e()c(n)o("]")end
local function M(e)local e,l={},{}if n=="<name>"then
B(e)else
q(e)end
o("=")c(l)end
local function T(e)if e.v.k=="VVOID"then return end
e.v.k="VVOID"end
local function T(e)c(e.v)end
local function y(l)local c=u
local e={}e.v={}e.t=l
l.k="VRELOCABLE"e.v.k="VVOID"o("{")repeat
if n=="}"then break end
local n=n
if n=="<name>"then
if z()~="="then
T(e)else
M(e)end
elseif n=="["then
M(e)else
T(e)end
until not t(",")and not t(";")i("}","{",c)end
local function z()local o=0
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
x(o)end
local function M(c)local l={}local t=u
local o=n
if o=="("then
if t~=X then
r("ambiguous syntax (function call x new statement)")end
e()if n==")"then
l.k="VVOID"else
p(l)end
i(")","(",t)elseif o=="{"then
y(l)elseif o=="<string>"then
K(l,m)e()else
r("function arguments expected")return
end
c.k="VCALL"end
local function X(l)local n=n
if n=="("then
local n=u
e()c(l)i(")","(",n)elseif n=="<name>"then
J(l)else
r("unexpected symbol")end
end
local function T(l)X(l)while true do
local n=n
if n=="."then
D(l)elseif n=="["then
local e={}q(e)elseif n==":"then
local n={}e()B(n)M(l)elseif n=="("or n=="<string>"or n=="{"then
M(l)else
return
end
end
end
local function B(o)local n=n
if n=="<number>"then
o.k="VKNUM"elseif n=="<string>"then
K(o,m)elseif n=="nil"then
o.k="VNIL"elseif n=="true"then
o.k="VTRUE"elseif n=="false"then
o.k="VFALSE"elseif n=="..."then
j(l.is_vararg==true,"cannot use '...' outside a vararg function");o.k="VVARARG"elseif n=="{"then
y(o)return
elseif n=="function"then
e()N(o,false,u)return
else
T(o)return
end
e()end
local function m(o,c)local l=n
local t=ee[l]if t then
e()m(o,Z)else
B(o)end
l=n
local n=U[l]while n and n>c do
local o={}e()local e=m(o,P[l])l=e
n=U[l]end
return l
end
function c(e)m(e,0)end
local function K(e)local n={}local e=e.v.k
j(e=="VLOCAL"or e=="VUPVAL"or e=="VGLOBAL"or e=="VINDEXED","syntax error")if t(",")then
local e={}e.v={}T(e.v)K(e)else
o("=")p(n)return
end
n.k="VNONRELOC"end
local function m(e,n)o("do")k(false)x(e)b()L()end
local function M(e)local n=f
s("(for index)")s("(for limit)")s("(for step)")h(e)o("=")w()o(",")w()if t(",")then
w()else
end
m(1,true)end
local function P(e)local n={}s("(for generator)")s("(for state)")s("(for control)")h(e)local e=1
while t(",")do
h(V())e=e+1
end
o("in")local l=f
p(n)m(e,false)end
local function U(e)local l=false
J(e)while n=="."do
D(e)end
if n==":"then
l=true
D(e)end
return l
end
function w()local e={}c(e)end
local function m()local e={}c(e)end
local function w()e()m()o("then")b()end
local function B()local e,n={}h(V())e.k="VLOCAL"x(1)N(n,false,u)end
local function D()local e=0
local n={}repeat
h(V())e=e+1
until not t(",")if t("=")then
p(n)else
n.k="VVOID"end
x(e)end
function p(e)c(e)while t(",")do
c(e)end
end
function N(l,e,n)H()o("(")if e then
s("self",true)x(1)end
z()o(")")A()i("end","function",n)Q()end
function b()k(false)A()L()end
function for_stat()local o=f
k(true)e()local l=V()local e=n
if e=="="then
M(l)elseif e==","or e=="in"then
P(l)else
r("'=' or 'in' expected")end
i("end","for",o)L()end
function while_stat()local n=f
e()m()k(true)o("do")b()i("end","while",n)L()end
function repeat_stat()local n=f
k(true)k(false)e()A()i("until","repeat",n)m()L()L()end
function if_stat()local l=f
local o={}w()while n=="elseif"do
w()end
if n=="else"then
e()b()end
i("end","if",l)end
function return_stat()local l={}e()local e=n
if S[e]or e==";"then
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
function expr_stat()local e={}e.v={}T(e.v)if e.v.k=="VCALL"then
else
e.prev=nil
K(e)end
end
function function_stat()local l=f
local o,n={},{}e()local e=U(o)N(n,e,l)end
function do_stat()local n=f
e()b()i("end","do",n)end
function local_stat()e()if t("function")then
B()else
D()end
end
local function o()f=u
local e=n
local n=Y[e]if n then
W[n]()if e=="return"or e=="break"then return true end
else
expr_stat()end
return false
end
function A()local e=false
while not e and not S[n]do
e=o()t(";")end
end
function parser()H()l.is_vararg=true
e()A()G("<eof>")Q()return O,a
end
function init(e,o,c)d=1
F={}local n=1
g,_,E,R={},{},{},{}for l=1,#e do
local e=e[l]local t=true
if e=="TK_KEYWORD"or e=="TK_OP"then
e=o[l]elseif e=="TK_NAME"then
e="<name>"_[n]=o[l]elseif e=="TK_NUMBER"then
e="<number>"_[n]=0
elseif e=="TK_STRING"or e=="TK_LSTRING"then
e="<string>"_[n]=""elseif e=="TK_EOS"then
e="<eof>"else
t=false
end
if t then
g[n]=e
E[n]=c[l]R[n]=l
n=n+1
end
end
O,C,a={},{},{}v,I={},{}end
return W
