local f=_G
local l=require"string"
module"llex"
local c=l.find
local w=l.match
local i=l.sub
local y={}
for e in l.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]],"%S+")do
y[e]=true
end
local e,
m,
a,
n,
u
local function o(t,a)
local e=#tok+1
tok[e]=t
seminfo[e]=a
tokln[e]=u
end
local function r(t,s)
local n=i
local i=n(e,t,t)
t=t+1
local e=n(e,t,t)
if(e=="\n"or e=="\r")and(e~=i)then
t=t+1
i=i..e
end
if s then o("TK_EOL",i)end
u=u+1
a=t
return t
end
function init(i,t)
e=i
m=t
a=1
u=1
tok={}
seminfo={}
tokln={}
local t,n,e,i=c(e,"^(#[^\r\n]*)(\r?\n?)")
if t then
a=a+#e
o("TK_COMMENT",e)
if#i>0 then r(a,true)end
end
end
function chunkid()
if m and w(m,"^[=@]")then
return i(m,2)
end
return"[string]"
end
function errorline(e,a)
local t=error or f.error
t(l.format("%s:%d: %s",chunkid(),a or u,e))
end
local function u(t)
local i=i
local n=i(e,t,t)
t=t+1
local o=#w(e,"=*",t)
t=t+o
a=t
return(i(e,t,t)==n)and o or(-o)-1
end
local function m(d,h)
local t=a+1
local s=i
local i=s(e,t,t)
if i=="\r"or i=="\n"then
t=r(t)
end
local l=t
while true do
local o,l,i=c(e,"([\r\n%]])",t)
if not o then
errorline(d and"unfinished long string"or
"unfinished long comment")
end
t=o
if i=="]"then
if u(t)==h then
n=s(e,n,a)
a=a+1
return n
end
t=a
else
n=n.."\n"
t=r(t)
end
end
end
local function p(d)
local t=a
local s=c
local h=i
while true do
local i,l,o=s(e,"([\n\r\\\"\'])",t)
if i then
if o=="\n"or o=="\r"then
errorline("unfinished string")
end
t=i
if o=="\\"then
t=t+1
o=h(e,t,t)
if o==""then break end
i=s("abfnrtv\n\r",o,1,true)
if i then
if i>7 then
t=r(t)
else
t=t+1
end
elseif s(o,"%D")then
t=t+1
else
local o,e,a=s(e,"^(%d%d?%d?)",t)
t=e+1
if a+1>256 then
errorline("escape sequence too large")
end
end
else
t=t+1
if o==d then
a=t
return h(e,n,t-1)
end
end
else
break
end
end
errorline("unfinished string")
end
function llex()
local h=c
local d=w
while true do
local t=a
while true do
local v,b,l=h(e,"^([_%a][_%w]*)",t)
if v then
a=t+#l
if y[l]then
o("TK_KEYWORD",l)
else
o("TK_NAME",l)
end
break
end
local c,y,w=h(e,"^(%.?)%d",t)
if c then
if w=="."then t=t+1 end
local r,s,n=h(e,"^%d*[%.%d]*([eE]?)",t)
t=s+1
if#n==1 then
if d(e,"^[%+%-]",t)then
t=t+1
end
end
local n,t=h(e,"^[_%w]*",t)
a=t+1
local e=i(e,c,t)
if not f.tonumber(e)then
errorline("malformed number")
end
o("TK_NUMBER",e)
break
end
local f,c,w,l=h(e,"^((%s)[ \t\v\f]*)",t)
if f then
if l=="\n"or l=="\r"then
r(t,true)
else
a=c+1
o("TK_SPACE",w)
end
break
end
local s=d(e,"^%p",t)
if s then
n=t
local r=h("-[\"\'.=<>~",s,1,true)
if r then
if r<=2 then
if r==1 then
local r=d(e,"^%-%-(%[?)",t)
if r then
t=t+2
local s=-1
if r=="["then
s=u(t)
end
if s>=0 then
o("TK_LCOMMENT",m(false,s))
else
a=h(e,"[\n\r]",t)or(#e+1)
o("TK_COMMENT",i(e,n,a-1))
end
break
end
else
local e=u(t)
if e>=0 then
o("TK_LSTRING",m(true,e))
elseif e==-1 then
o("TK_OP","[")
else
errorline("invalid long string delimiter")
end
break
end
elseif r<=5 then
if r<5 then
a=t+1
o("TK_STRING",p(s))
break
end
s=d(e,"^%.%.?%.?",t)
else
s=d(e,"^%p=?",t)
end
end
a=t+#s
o("TK_OP",s)
break
end
local e=i(e,t,t)
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
return f.getfenv()
