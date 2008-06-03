local p=_G
local a=require"string"local x=require"table"module"optparser"local m="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"local k="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"local O={}for e in a.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]],"%S+")do
O[e]=true
end
local b,N,y,o,w,L,z,i
local function A(d)local a={}for t=1,#d do
local e=d[t]local n=e.name
if not a[n]then
a[n]={decl=0,token=0,size=0,}end
local l=a[n]l.decl=l.decl+1
local a=e.xref
local o=#a
l.token=l.token+o
l.size=l.size+o*#n
if e.decl then
e.id=t
e.xcount=o
if o>1 then
e.first=a[2]e.last=a[o]end
else
l.id=t
end
end
return a
end
local function E(r)local d=a.byte
local c=a.char
local n={TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,TK_STRING=true,TK_LSTRING=true,}if not r["opt-comments"]then
n.TK_COMMENT=true
n.TK_LCOMMENT=true
end
local a={}for e=1,#b do
a[e]=N[e]end
for l=1,#o do
local e=o[l]local l=e.xref
for o=1,e.xcount do
local e=l[o]a[e]=""end
end
local l={}for e=0,255 do l[e]=0 end
for o=1,#b do
local a,o=b[o],a[o]if n[a]then
for n=1,#o do
local e=d(o,n)l[e]=l[e]+1
end
end
end
local function t(a)local e={}for n=1,#a do
local o=d(a,n)e[n]={c=o,freq=l[o],}end
x.sort(e,function(l,e)return l.freq>e.freq
end)local l={}for o=1,#e do
l[o]=c(e[o].c)end
return x.concat(l)end
m=t(m)k=t(k)end
local function G()local l
local d,r=#m,#k
local e=z
if e<d then
e=e+1
l=a.sub(m,e,e)else
local c,t=d,1
repeat
e=e-c
c=c*r
t=t+1
until c>e
local n=e%d
e=(e-n)/d
n=n+1
l=a.sub(m,n,n)while t>1 do
local o=e%r
e=(e-o)/r
o=o+1
l=l..a.sub(k,o,o)t=t-1
end
end
z=z+1
return l,w[l]~=nil
end
local function C(g,I,_,v)local e=print or p.print
local l=a.format
local v=v.DETAILS
local h,T,k,L,O,z,m,u,K,N,d,s,f,w,b,t,r,c,A,y=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
local function n(e,l)if e==0 then return 0 end
return l/e
end
for l,e in p.pairs(g)do
h=h+1
d=d+e.token
t=t+e.size
end
for l,e in p.pairs(I)do
T=T+1
m=m+e.decl
s=s+e.token
r=r+e.size
end
for l,e in p.pairs(_)do
k=k+1
u=u+e.decl
f=f+e.token
c=c+e.size
end
L=h+T
K=z+m
w=d+s
A=t+r
O=h+k
N=z+u
b=d+f
y=t+c
if v then
local h={}for l,e in p.pairs(g)do
e.name=l
h[#h+1]=e
end
x.sort(h,function(e,l)return e.size>l.size
end)local m,T="%8s%8s%10s  %s","%8d%8d%10.2f  %s"local p=a.rep("-",44)e("*** global variable list (sorted by size) ***\n"..p)e(l(m,"Token","Input","Input","Global"))e(l(m,"Count","Bytes","Average","Name"))e(p)for a=1,#h do
local o=h[a]e(l(T,o.token,o.size,n(o.token,o.size),o.name))end
e(p)e(l(T,d,t,n(d,t),"TOTAL"))e(p.."\n")local p,h="%8s%8s%8s%10s%8s%10s  %s","%8d%8d%8d%10.2f%8d%10.2f  %s"local t=a.rep("-",70)e("*** local variable list (sorted by allocation order) ***\n"..t)e(l(p,"Decl.","Token","Input","Input","Output","Output","Global"))e(l(p,"Count","Count","Bytes","Average","Bytes","Average","Name"))e(t)for r=1,#i do
local c=i[r]local a=_[c]local d,t=0,0
for l=1,#o do
local e=o[l]if e.name==c then
d=d+e.xcount
t=t+e.xcount*#e.oldname
end
end
e(l(h,a.decl,a.token,t,n(d,t),a.size,n(a.token,a.size),c))end
e(t)e(l(h,u,f,r,n(s,r),c,n(f,c),"TOTAL"))e(t.."\n")end
local i,o="%-16s%8s%8s%8s%8s%10s","%-16s%8d%8d%8d%8d%10.2f"local a=a.rep("-",58)e("*** local variable optimization summary ***\n"..a)e(l(i,"Variable","Unique","Decl.","Token","Size","Average"))e(l(i,"Types","Names","Count","Count","Bytes","Bytes"))e(a)e(l(o,"Global",h,z,d,t,n(d,t)))e(a)e(l(o,"Local (in)",T,m,s,r,n(s,r)))e(l(o,"TOTAL (in)",L,K,w,A,n(w,A)))e(a)e(l(o,"Local (out)",k,u,f,c,n(f,c)))e(l(o,"TOTAL (out)",O,N,b,y,n(b,y)))e(a.."\n")end
function optimize(c,h,u,p,m)b,N,y,o=h,u,p,m
z=0
i={}w=A(y)L=A(o)if c["opt-entropy"]then
E(c)end
local e={}for l=1,#o do
e[l]=o[l]end
x.sort(e,function(l,e)return l.xcount>e.xcount
end)local f,r,s={},1,false
for l=1,#e do
local e=e[l]if not e.isself then
f[r]=e
r=r+1
else
s=true
end
end
e=f
local d=#e
while d>0 do
local t,c
repeat
t,c=G()until not O[t]i[#i+1]=t
local n=d
if c then
local a=y[w[t].id].xref
local t=#a
for c=1,d do
local l=e[c]local d,e=l.act,l.rem
while e<0 do
e=o[-e].rem
end
local o
for n=1,t do
local l=a[n]if l>=d and l<=e then o=true end
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
local a=e[l]l=l+1
a.newname=t
a.skip=true
a.done=true
local c,r=a.first,a.last
local i=a.xref
if c and n>0 then
local d=n
while d>0 do
while e[l].skip do
l=l+1
end
d=d-1
local t=e[l]l=l+1
local d,e=t.act,t.rem
while e<0 do
e=o[-e].rem
end
if not(r<d or c>e)then
for o=1,a.xcount do
local l=i[o]if l>=d and l<=e then
n=n-1
t.skip=true
break
end
end
end
if n==0 then break end
end
end
end
local o,l={},1
for n=1,d do
local e=e[n]if not e.done then
e.skip=false
o[l]=e
l=l+1
end
end
e=o
d=#e
end
for l=1,#o do
local e=o[l]local l=e.xref
if e.newname then
for o=1,e.xcount do
local l=l[o]N[l]=e.newname
end
e.name,e.oldname=e.newname,e.name
else
e.oldname=e.name
end
end
if s then
i[#i+1]="self"end
local e=A(o)C(w,L,e,c)end
