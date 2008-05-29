local y=_G
local s=require"string"local I=require"table"module"optparser"local g="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"local x="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"local A,j,k,o,p,E,v
local function b(s)local o={}for n=1,#s do
local t=s[n]local i=t.name
if not o[i]then
o[i]={decl=0,token=0,size=0,}end
local e=o[i]e.decl=e.decl+1
local o=t.xref
local a=#o
e.token=e.token+a
e.size=e.size+a*#i
if t.decl then
t.id=n
t.xcount=a
if a>1 then
t.first=o[2]t.last=o[a]end
else
e.id=n
end
end
return o
end
local function _()local t
local n,h=#g,#x
local e=v
if e<n then
e=e+1
t=s.sub(g,e,e)else
local i,a=n,1
repeat
e=e-i
i=i*h
a=a+1
until i>e
local o=e%n
e=(e-o)/n
o=o+1
t=s.sub(g,o,o)while a>1 do
local o=e%h
e=(e-o)/h
o=o+1
t=t..s.sub(x,o,o)a=a-1
end
end
v=v+1
return t,p[t]~=nil
end
local function O(T,_,E)local e=print or y.print
local u,c,f,j,q,b,m,w,x,z,o,n,r,g,k,a,d,l,v,p=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
local function h(e,t)if e==0 then return 0 end
return t/e
end
for t,e in y.pairs(T)do
u=u+1
o=o+e.token
a=a+e.size
end
for t,e in y.pairs(_)do
c=c+1
m=m+e.decl
n=n+e.token
d=d+e.size
end
for t,e in y.pairs(E)do
f=f+1
w=w+e.decl
r=r+e.token
l=l+e.size
end
j=u+c
x=b+m
g=o+n
v=a+d
q=u+f
z=b+w
k=o+r
p=a+l
local t=s.format
local y,i="%-16s%8s%8s%8s%8s%10s","%-16s%8d%8d%8d%8d%10.2f"local s=s.rep("-",58)e("*** local variable optimization summary ***\n"..s)e(t(y,"Variable","Unique","Decl.","Token","Size","Average"))e(t(y,"Types","Names","Count","Count","Bytes","Bytes"))e(s)e(t(i,"Global",u,b,o,a,h(o,a)))e(s)e(t(i,"Local (in)",c,m,n,d,h(n,d)))e(t(i,"TOTAL (in)",j,x,g,v,h(g,v)))e(s)e(t(i,"Local (out)",f,w,r,l,h(r,l)))e(t(i,"TOTAL (out)",q,z,k,p,h(k,p)))e(s.."\n")end
function optimize(f,l,m,c,u)A,j,k,o=l,m,c,u
v=0
p=b(k)E=b(o)local e={}for t=1,#o do
e[t]=o[t]end
I.sort(e,function(t,e)return t.xcount>e.xcount
end)local r,h={},1
for t=1,#e do
local e=e[t]if not e.isself then
r[h]=e
h=h+1
end
end
e=r
local n=#e
while n>0 do
local s,h=_()if s=="self"then
s,h=_()end
local a=n
if h then
local i=k[p[s].id].xref
local s=#i
for n=1,n do
local t=e[n]local n,e=t.act,t.rem
while e<0 do
e=o[-e].rem
end
local o
for a=1,s do
local t=i[a]if t>=n and t<=e then o=true end
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
local i=e[t]t=t+1
i.newname=s
i.skip=true
i.done=true
local s,r=i.first,i.last
local d=i.xref
if s and a>0 then
local n=a
while n>0 do
while e[t].skip do
t=t+1
end
n=n-1
local n=e[t]t=t+1
local h,e=n.act,n.rem
while e<0 do
e=o[-e].rem
end
if not(r<h or s>e)then
for o=1,i.xcount do
local t=d[o]if t>=h and t<=e then
a=a-1
n.skip=true
break
end
end
end
if a==0 then break end
end
end
end
local a,t={},1
for o=1,n do
local e=e[o]if not e.done then
e.skip=false
a[t]=e
t=t+1
end
end
e=a
n=#e
end
for t=1,#o do
local e=o[t]local a=e.xref
for t=1,e.xcount do
local t=a[t]if e.newname then
j[t]=e.newname
end
end
if e.newname then
e.name=e.newname
end
end
local e=b(o)O(p,E,e)end
