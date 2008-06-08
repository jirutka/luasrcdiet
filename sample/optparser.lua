local p=_G
local a=require"string"local b=require"table"module"optparser"local t="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"local c="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"local _={}for e in a.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]],"%S+")do
_[e]=true
end
local z,N,L,o,w,K,T,i
local function O(e)local a={}for t=1,#e do
local l=e[t]local n=l.name
if not a[n]then
a[n]={decl=0,token=0,size=0,}end
local e=a[n]e.decl=e.decl+1
local a=l.xref
local o=#a
e.token=e.token+o
e.size=e.size+o*#n
if l.decl then
l.id=t
l.xcount=o
if o>1 then
l.first=a[2]l.last=a[o]end
else
e.id=t
end
end
return a
end
local function E(e)local d=a.byte
local a=a.char
local l={TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,TK_STRING=true,TK_LSTRING=true,}if not e["opt-comments"]then
l.TK_COMMENT=true
l.TK_LCOMMENT=true
end
local n={}for e=1,#z do
n[e]=N[e]end
for e=1,#o do
local e=o[e]local l=e.xref
for e=1,e.xcount do
local e=l[e]n[e]=""end
end
local e={}for l=0,255 do e[l]=0 end
for o=1,#z do
local n,o=z[o],n[o]if l[n]then
for l=1,#o do
local l=d(o,l)e[l]=e[l]+1
end
end
end
local function o(o)local l={}for n=1,#o do
local o=d(o,n)l[n]={c=o,freq=e[o],}end
b.sort(l,function(l,e)return l.freq>e.freq
end)local o={}for e=1,#l do
o[e]=a(l[e].c)end
return b.concat(o)end
t=o(t)c=o(c)end
local function C()local l
local d,r=#t,#c
local e=T
if e<d then
e=e+1
l=a.sub(t,e,e)else
local o,n=d,1
repeat
e=e-o
o=o*r
n=n+1
until o>e
local o=e%d
e=(e-o)/d
o=o+1
l=a.sub(t,o,o)while n>1 do
local o=e%r
e=(e-o)/r
o=o+1
l=l..a.sub(c,o,o)n=n-1
end
end
T=T+1
return l,w[l]~=nil
end
local function I(N,v,L,n)local e=print or p.print
local l=a.format
local I=n.DETAILS
local u,k,T,O,K,y,m,h,_,g,d,f,s,A,x,t,r,c,w,z=0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0
local function n(e,l)if e==0 then return 0 end
return l/e
end
for l,e in p.pairs(N)do
u=u+1
d=d+e.token
t=t+e.size
end
for l,e in p.pairs(v)do
k=k+1
m=m+e.decl
f=f+e.token
r=r+e.size
end
for l,e in p.pairs(L)do
T=T+1
h=h+e.decl
s=s+e.token
c=c+e.size
end
O=u+k
_=y+m
A=d+f
w=t+r
K=u+T
g=y+h
x=d+s
z=t+c
if I then
local u={}for l,e in p.pairs(N)do
e.name=l
u[#u+1]=e
end
b.sort(u,function(l,e)return l.size>e.size
end)local m,T="%8s%8s%10s  %s","%8d%8d%10.2f  %s"local p=a.rep("-",44)e("*** global variable list (sorted by size) ***\n"..p)e(l(m,"Token","Input","Input","Global"))e(l(m,"Count","Bytes","Average","Name"))e(p)for o=1,#u do
local o=u[o]e(l(T,o.token,o.size,n(o.token,o.size),o.name))end
e(p)e(l(T,d,t,n(d,t),"TOTAL"))e(p.."\n")local t,u="%8s%8s%8s%10s%8s%10s  %s","%8d%8d%8d%10.2f%8d%10.2f  %s"local d=a.rep("-",70)e("*** local variable list (sorted by allocation order) ***\n"..d)e(l(t,"Decl.","Token","Input","Input","Output","Output","Global"))e(l(t,"Count","Count","Bytes","Average","Bytes","Average","Name"))e(d)for a=1,#i do
local d=i[a]local a=L[d]local c,t=0,0
for l=1,#o do
local e=o[l]if e.name==d then
c=c+e.xcount
t=t+e.xcount*#e.oldname
end
end
e(l(u,a.decl,a.token,t,n(c,t),a.size,n(a.token,a.size),d))end
e(d)e(l(u,h,s,r,n(f,r),c,n(s,c),"TOTAL"))e(d.."\n")end
local i,o="%-16s%8s%8s%8s%8s%10s","%-16s%8d%8d%8d%8d%10.2f"local a=a.rep("-",58)e("*** local variable optimization summary ***\n"..a)e(l(i,"Variable","Unique","Decl.","Token","Size","Average"))e(l(i,"Types","Names","Count","Count","Bytes","Bytes"))e(a)e(l(o,"Global",u,y,d,t,n(d,t)))e(a)e(l(o,"Local (in)",k,m,f,r,n(f,r)))e(l(o,"TOTAL (in)",O,_,A,w,n(A,w)))e(a)e(l(o,"Local (out)",T,h,s,c,n(s,c)))e(l(o,"TOTAL (out)",K,g,x,z,n(x,z)))e(a.."\n")end
function optimize(c,e,l,a,n)z,N,L,o=e,l,a,n
T=0
i={}w=O(L)K=O(o)if c["opt-entropy"]then
E(c)end
local e={}for l=1,#o do
e[l]=o[l]end
b.sort(e,function(e,l)return e.xcount>l.xcount
end)local n,l,r={},1,false
for o=1,#e do
local e=e[o]if not e.isself then
n[l]=e
l=l+1
else
r=true
end
end
e=n
local d=#e
while d>0 do
local t,l
repeat
t,l=C()until not _[t]i[#i+1]=t
local n=d
if l then
local a=L[w[t].id].xref
local c=#a
for l=1,d do
local l=e[l]local t,e=l.act,l.rem
while e<0 do
e=o[-e].rem
end
local o
for l=1,c do
local l=a[l]if l>=t and l<=e then o=true end
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
local d,c=a.first,a.last
local r=a.xref
if d and n>0 then
local t=n
while t>0 do
while e[l].skip do
l=l+1
end
t=t-1
local e=e[l]l=l+1
local t,l=e.act,e.rem
while l<0 do
l=o[-l].rem
end
if not(c<t or d>l)then
if t>=a.act then
for o=1,a.xcount do
local o=r[o]if o>=t and o<=l then
n=n-1
e.skip=true
break
end
end
else
if e.last and e.last>=a.act then
n=n-1
e.skip=true
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
for e=1,#o do
local e=o[e]local l=e.xref
if e.newname then
for o=1,e.xcount do
local l=l[o]N[l]=e.newname
end
e.name,e.oldname=e.newname,e.name
else
e.oldname=e.name
end
end
if r then
i[#i+1]="self"end
local e=O(o)I(w,K,e,c)end
