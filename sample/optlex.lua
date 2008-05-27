local base=_G
local string=require"string"module"optlex"local match=string.match
local sub=string.sub
local find=string.find
local rep=string.rep
error=base.error
warn={}local stoks,sinfos,stoklns
local is_realtoken={TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,TK_STRING=true,TK_LSTRING=true,TK_OP=true,TK_EOS=true,}local is_faketoken={TK_COMMENT=true,TK_LCOMMENT=true,TK_EOL=true,TK_SPACE=true,}local function atlinestart(i)local tok=stoks[i-1]if i<=1 or tok=="TK_EOL"then
return true
elseif tok==""then
return atlinestart(i-1)end
return false
end
local function atlineend(i)local tok=stoks[i+1]if i>=#stoks or tok=="TK_EOL"or tok=="TK_EOS"then
return true
elseif tok==""then
return atlineend(i+1)end
return false
end
local function commenteols(lcomment)local sep=#match(lcomment,"^%-%-%[=*%[")local z=sub(lcomment,sep+1,-(sep-1))local i,c=1,0
while true do
local p,q,r,s=find(z,"([\r\n])([\r\n]?)",i)if not p then break end
i=p+1
c=c+1
if#s>0 and r~=s then
i=i+1
end
end
return c
end
local function checkpair(i,j)local match=match
local t1,t2=stoks[i],stoks[j]if t1=="TK_STRING"or t1=="TK_LSTRING"or
t2=="TK_STRING"or t2=="TK_LSTRING"then
return""elseif t1=="TK_OP"or t2=="TK_OP"then
if(t1=="TK_OP"and(t2=="TK_KEYWORD"or t2=="TK_NAME"))or(t2=="TK_OP"and(t1=="TK_KEYWORD"or t1=="TK_NAME"))then
return""end
if t1=="TK_OP"and t2=="TK_OP"then
local op,op2=sinfos[i],sinfos[j]if(match(op,"^%.%.?$")and match(op2,"^%."))or(match(op,"^[~=<>]$")and op2=="=")or(op=="["and(op2=="["or op2=="="))then
return" "end
return""end
local op=sinfos[i]if t2=="TK_OP"then op=sinfos[j]end
if match(op,"^%.%.?%.?$")then
return" "end
return""else
return" "end
end
local function repack_tokens()local dtoks,dinfos,dtoklns={},{},{}local j=1
for i=1,#stoks do
local tok=stoks[i]if tok~=""then
dtoks[j],dinfos[j],dtoklns[j]=tok,sinfos[i],stoklns[i]j=j+1
end
end
stoks,sinfos,stoklns=dtoks,dinfos,dtoklns
end
local function do_number(i)local before=sinfos[i]local z=before
local y
if match(z,"^0[xX]")then
local v=base.tostring(base.tonumber(z))if#v<=#z then
z=v
else
return
end
end
if match(z,"^%d+%.?0*$")then
z=match(z,"^(%d+)%.?0*$")if z+0>0 then
z=match(z,"^0*([1-9]%d*)$")local v=#match(z,"0*$")local nv=base.tostring(v)if v>#nv+1 then
z=sub(z,1,#z-v).."e"..nv
end
y=z
else
y="0"end
elseif not match(z,"[eE]")then
local p,q=match(z,"^(%d*)%.(%d+)$")if p==""then p=0 end
if q+0==0 and p==0 then
y="0"else
local v=#match(q,"0*$")if v>0 then
q=sub(q,1,#q-v)end
if p+0>0 then
y=p.."."..q
else
y="."..q
local v=#match(q,"^0*")local w=#q-v
local nv=base.tostring(#q)if w+2+#nv<1+#q then
y=sub(q,-w).."e-"..nv
end
end
end
else
local sig,ex=match(z,"^([^eE]+)[eE]([%+%-]?%d+)$")ex=base.tonumber(ex)local p,q=match(sig,"^(%d*)%.(%d*)$")if p then
ex=ex-#q
sig=p..q
end
if sig+0==0 then
y="0"else
local v=#match(sig,"^0*")sig=sub(sig,v+1)v=#match(sig,"0*$")if v>0 then
sig=sub(sig,1,#sig-v)ex=ex+v
end
local nex=base.tostring(ex)if ex==0 then
y=sig
elseif ex>0 and(ex<=1+#nex)then
y=sig..rep("0",ex)elseif ex<0 and(ex>=-#sig)then
v=#sig+ex
y=sub(sig,1,v).."."..sub(sig,v+1)elseif ex<0 and(#nex>=-ex-#sig)then
v=-ex-#sig
y="."..rep("0",v)..sig
else
y=sig.."e"..ex
end
end
end
if y then sinfos[i]=y end
end
local function do_string(I)local info=sinfos[I]local delim=sub(info,1,1)local ndelim=(delim=="'")and'"'or"'"local z=sub(info,2,-2)local i=1
local c_delim,c_ndelim=0,0
while i<=#z do
local c=sub(z,i,i)if c=="\\"then
local j=i+1
local d=sub(z,j,j)local p=find("abfnrtv\\\n\r\"'0123456789",d,1,true)if not p then
z=sub(z,1,i-1)..sub(z,j)i=i+1
elseif p<=8 then
i=i+2
elseif p<=10 then
local eol=sub(z,j,j+1)if eol=="\r\n"or eol=="\n\r"then
z=sub(z,1,i).."\n"..sub(z,j+2)elseif p==10 then
z=sub(z,1,i).."\n"..sub(z,j+1)end
i=i+2
elseif p<=12 then
if d==delim then
c_delim=c_delim+1
i=i+2
else
c_ndelim=c_ndelim+1
z=sub(z,1,i-1)..sub(z,j)i=i+1
end
else
local s=match(z,"^(%d%d?%d?)",j)j=i+1+#s
local cv=s+0
local cc=string.char(cv)local p=find("\a\b\f\n\r\t\v",cc,1,true)if p then
s="\\"..sub("abfnrtv",p,p)elseif cv<32 then
s="\\"..cv
elseif cc==delim then
s="\\"..cc
c_delim=c_delim+1
elseif cc=="\\"then
s="\\\\"else
s=cc
if cc==ndelim then
c_ndelim=c_ndelim+1
end
end
z=sub(z,1,i-1)..s..sub(z,j)i=i+#s
end
else
i=i+1
if c==ndelim then
c_ndelim=c_ndelim+1
end
end
end
if c_delim>c_ndelim then
i=1
while i<=#z do
local p,q,r=find(z,"(['\"])",i)if not p then break end
if r==delim then
z=sub(z,1,p-2)..sub(z,p)i=p
else
z=sub(z,1,p-1).."\\"..sub(z,p)i=p+2
end
end
delim=ndelim
end
sinfos[I]=delim..z..delim
end
local function do_lstring(I)local info=sinfos[I]local delim1=match(info,"^%[=*%[")local sep=#delim1
local delim2=sub(info,-sep,-1)local z=sub(info,sep+1,-(sep+1))local y=""local i=1
while true do
local p,q,r,s=find(z,"([\r\n])([\r\n]?)",i)local ln
if not p then
ln=sub(z,i)elseif p>=i then
ln=sub(z,i,p-1)end
if ln~=""then
if match(ln,"%s+$")then
warn.lstring="trailing whitespace in long string near line "..stoklns[I]end
y=y..ln
end
if not p then
break
end
i=p+1
if p then
if#s>0 and r~=s then
i=i+1
end
if not(i==1 and i==p)then
y=y.."\n"end
end
end
if sep>=3 then
local chk,okay=sep-1
while chk>=2 do
local delim="%]"..rep("=",chk-2).."%]"if not match(y,delim)then okay=chk end
chk=chk-1
end
if okay then
sep=rep("=",okay-2)delim1,delim2="["..sep.."[","]"..sep.."]"end
end
sinfos[I]=delim1..y..delim2
end
local function do_lcomment(I)local info=sinfos[I]local delim1=match(info,"^%-%-%[=*%[")local sep=#delim1
local delim2=sub(info,-sep,-1)local z=sub(info,sep+1,-(sep-1))local y=""local i=1
while true do
local p,q,r,s=find(z,"([\r\n])([\r\n]?)",i)local ln
if not p then
ln=sub(z,i)elseif p>=i then
ln=sub(z,i,p-1)end
if ln~=""then
local ws=match(ln,"%s*$")if#ws>0 then ln=sub(ln,1,-(ws+1))end
y=y..ln
end
if not p then
break
end
i=p+1
if p then
if#s>0 and r~=s then
i=i+1
end
y=y.."\n"end
end
sep=sep-2
if sep>=3 then
local chk,okay=sep-1
while chk>=2 do
local delim="%]"..rep("=",chk-2).."%]"if not match(y,delim)then okay=chk end
chk=chk-1
end
if okay then
sep=rep("=",okay-2)delim1,delim2="--["..sep.."[","]"..sep.."]"end
end
sinfos[I]=delim1..y..delim2
end
local function do_comment(i)local info=sinfos[i]local ws=match(info,"%s*$")if#ws>0 then
info=sub(info,1,-(ws+1))end
sinfos[i]=info
end
function optimize(option,toklist,semlist,toklnlist)local opt_comments=option["opt-comments"]local opt_whitespace=option["opt-whitespace"]local opt_emptylines=option["opt-emptylines"]local opt_eols=option["opt-eols"]local opt_strings=option["opt-strings"]local opt_numbers=option["opt-numbers"]if opt_eols then
opt_comments=true
opt_whitespace=true
opt_emptylines=true
end
stoks,sinfos,stoklns=toklist,semlist,toklnlist
local i=1
local tok
local prev
local function settoken(tok,info,I)I=I or i
stoks[I]=tok or""sinfos[I]=info or""end
while true do
tok,info=stoks[i],sinfos[i]local atstart=atlinestart(i)if atstart then prev=nil end
if tok=="TK_EOS"then
break
elseif tok=="TK_KEYWORD"or
tok=="TK_NAME"or
tok=="TK_OP"then
prev=i
elseif tok=="TK_NUMBER"then
if opt_numbers then
do_number(i)end
prev=i
elseif tok=="TK_STRING"or
tok=="TK_LSTRING"then
if opt_strings then
if tok=="TK_STRING"then
do_string(i)else
do_lstring(i)end
end
prev=i
elseif tok=="TK_COMMENT"then
if opt_comments then
if i==1 and sub(info,1,1)=="#"then
do_comment(i)else
settoken()end
elseif opt_whitespace then
do_comment(i)end
elseif tok=="TK_LCOMMENT"then
if opt_comments then
local eols=commenteols(info)if is_faketoken[stoks[i+1]]then
settoken()tok=""else
settoken("TK_SPACE"," ")end
if not opt_emptylines and eols>0 then
settoken("TK_EOL",rep("\n",eols))end
if opt_whitespace and tok~=""then
i=i-1
end
else
if opt_whitespace then
do_lcomment(i)end
prev=i
end
elseif tok=="TK_EOL"then
if atstart and opt_emptylines then
settoken()elseif info=="\r\n"or info=="\n\r"then
settoken("TK_EOL","\n")end
elseif tok=="TK_SPACE"then
if opt_whitespace then
if atstart or atlineend(i)then
settoken()else
local ptok=stoks[prev]if ptok=="TK_LCOMMENT"then
settoken()else
local ntok=stoks[i+1]if is_faketoken[ntok]then
if(ntok=="TK_COMMENT"or ntok=="TK_LCOMMENT")and
ptok=="TK_OP"and sinfos[prev]=="-"then
else
settoken()end
else
local s=checkpair(prev,i+1)if s==""then
settoken()else
settoken("TK_SPACE"," ")end
end
end
end
end
else
error("unidentified token encountered")end
i=i+1
end
repack_tokens()if opt_eols then
i=1
if stoks[1]=="TK_COMMENT"then
i=3
end
while true do
tok,info=stoks[i],sinfos[i]if tok=="TK_EOS"then
break
elseif tok=="TK_EOL"then
local t1,t2=stoks[i-1],stoks[i+1]if is_realtoken[t1]and is_realtoken[t2]then
local s=checkpair(i-1,i+1)if s==""then
settoken()end
end
end
i=i+1
end
repack_tokens()end
return stoks,sinfos,stoklns
end
