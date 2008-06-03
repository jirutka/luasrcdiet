local w=_G
local l=require"string"
module"llex"
local f=l.find
local y=l.match
local n=l.sub
local v={}
for e in l.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]],"%S+")do
v[e]=true
end
local e,
m,
a,
i,
d
local function o(t,a)
local e=#tok+1
tok[e]=t
seminfo[e]=a
tokln[e]=d
end
local function u(t,s)
local n=n
local i=n(e,t,t)
t=t+1
local e=n(e,t,t)
if(e=="\n"or e=="\r")and(e~=i)then
t=t+1
i=i..e
end
if s then o("TK_EOL",i)end
d=d+1
a=t
return t
end
function init(i,t)
e=i
m=t
a=1
d=1
tok={}
seminfo={}
tokln={}
local t,n,e,i=f(e,"^(#[^\r\n]*)(\r?\n?)")
if t then
a=a+#e
o("TK_COMMENT",e)
if#i>0 then u(a,true)end
end
end
function chunkid()
if m and y(m,"^[=@]")then
return n(m,2)
end
return"[string]"
end
function errorline(e,a)
local t=error or w.error
t(l.format("%s:%d: %s",chunkid(),a or d,e))
end
local r=errorline
local function m(t)
local i=n
local n=i(e,t,t)
t=t+1
local o=#y(e,"=*",t)
t=t+o
a=t
return(i(e,t,t)==n)and o or(-o)-1
end
local function p(h,s)
local t=a+1
local n=n
local o=n(e,t,t)
if o=="\r"or o=="\n"then
t=u(t)
end
local l=t
while true do
local o,l,d=f(e,"([\r\n%]])",t)
if not o then
r(h and"unfinished long string"or
"unfinished long comment")
end
t=o
if d=="]"then
if m(t)==s then
i=n(e,i,a)
a=a+1
return i
end
t=a
else
i=i.."\n"
t=u(t)
end
end
end
local function b(d)
local t=a
local s=f
local h=n
while true do
local n,l,o=s(e,"([\n\r\\\"\'])",t)
if n then
if o=="\n"or o=="\r"then
r("unfinished string")
end
t=n
if o=="\\"then
t=t+1
o=h(e,t,t)
if o==""then break end
n=s("abfnrtv\n\r",o,1,true)
if n then
if n>7 then
t=u(t)
else
t=t+1
end
elseif s(o,"%D")then
t=t+1
else
local o,e,a=s(e,"^(%d%d?%d?)",t)
t=e+1
if a+1>256 then
r("escape sequence too large")
end
end
else
t=t+1
if o==d then
a=t
return h(e,i,t-1)
end
end
else
break
end
end
r("unfinished string")
end
function llex()
local s=f
local l=y
while true do
local t=a
while true do
local g,k,c=s(e,"^([_%a][_%w]*)",t)
if g then
a=t+#c
if v[c]then
o("TK_KEYWORD",c)
else
o("TK_NAME",c)
end
break
end
local f,v,y=s(e,"^(%.?)%d",t)
if f then
if y=="."then t=t+1 end
local d,h,i=s(e,"^%d*[%.%d]*([eE]?)",t)
t=h+1
if#i==1 then
if l(e,"^[%+%-]",t)then
t=t+1
end
end
local i,t=s(e,"^[_%w]*",t)
a=t+1
local e=n(e,f,t)
if not w.tonumber(e)then
r("malformed number")
end
o("TK_NUMBER",e)
break
end
local w,f,y,c=s(e,"^((%s)[ \t\v\f]*)",t)
if w then
if c=="\n"or c=="\r"then
u(t,true)
else
a=f+1
o("TK_SPACE",y)
end
break
end
local h=l(e,"^%p",t)
if h then
i=t
local d=s("-[\"\'.=<>~",h,1,true)
if d then
if d<=2 then
if d==1 then
local r=l(e,"^%-%-(%[?)",t)
if r then
t=t+2
local h=-1
if r=="["then
h=m(t)
end
if h>=0 then
o("TK_LCOMMENT",p(false,h))
else
a=s(e,"[\n\r]",t)or(#e+1)
o("TK_COMMENT",n(e,i,a-1))
end
break
end
else
local e=m(t)
if e>=0 then
o("TK_LSTRING",p(true,e))
elseif e==-1 then
o("TK_OP","[")
else
r("invalid long string delimiter")
end
break
end
elseif d<=5 then
if d<5 then
a=t+1
o("TK_STRING",b(h))
break
end
h=l(e,"^%.%.?%.?",t)
else
h=l(e,"^%p=?",t)
end
end
a=t+#h
o("TK_OP",h)
break
end
local e=n(e,t,t)
if e~=""then
a=t+1
o("TK_OP",e)
break
end
o("TK_EOS","")
return
end
end
end
return w.getfenv()
