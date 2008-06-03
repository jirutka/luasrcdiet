local base=_G
local string=require"string"
module"llex"
local find=string.find
local match=string.match
local sub=string.sub
local kw={}
for v in string.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while]],"%S+")do
kw[v]=true
end
local z,
sourceid,
I,
buff,
ln
local function addtoken(token,info)
local i=#tok+1
tok[i]=token
seminfo[i]=info
tokln[i]=ln
end
local function inclinenumber(i,is_tok)
local sub=sub
local old=sub(z,i,i)
i=i+1
local c=sub(z,i,i)
if(c=="\n"or c=="\r")and(c~=old)then
i=i+1
old=old..c
end
if is_tok then addtoken("TK_EOL",old)end
ln=ln+1
I=i
return i
end
function init(_z,_sourceid)
z=_z
sourceid=_sourceid
I=1
ln=1
tok={}
seminfo={}
tokln={}
local p,_,q,r=find(z,"^(#[^\r\n]*)(\r?\n?)")
if p then
I=I+#q
addtoken("TK_COMMENT",q)
if#r>0 then inclinenumber(I,true)end
end
end
function chunkid()
if sourceid and match(sourceid,"^[=@]")then
return sub(sourceid,2)
end
return"[string]"
end
function errorline(s,line)
local e=error or base.error
e(string.format("%s:%d: %s",chunkid(),line or ln,s))
end
local errorline=errorline
local function skip_sep(i)
local sub=sub
local s=sub(z,i,i)
i=i+1
local count=#match(z,"=*",i)
i=i+count
I=i
return(sub(z,i,i)==s)and count or(-count)-1
end
local function read_long_string(is_str,sep)
local i=I+1
local sub=sub
local c=sub(z,i,i)
if c=="\r"or c=="\n"then
i=inclinenumber(i)
end
local j=i
while true do
local p,q,r=find(z,"([\r\n%]])",i)
if not p then
errorline(is_str and"unfinished long string"or
"unfinished long comment")
end
i=p
if r=="]"then
if skip_sep(i)==sep then
buff=sub(z,buff,I)
I=I+1
return buff
end
i=I
else
buff=buff.."\n"
i=inclinenumber(i)
end
end
end
local function read_string(del)
local i=I
local find=find
local sub=sub
while true do
local p,q,r=find(z,"([\n\r\\\"\'])",i)
if p then
if r=="\n"or r=="\r"then
errorline("unfinished string")
end
i=p
if r=="\\"then
i=i+1
r=sub(z,i,i)
if r==""then break end
p=find("abfnrtv\n\r",r,1,true)
if p then
if p>7 then
i=inclinenumber(i)
else
i=i+1
end
elseif find(r,"%D")then
i=i+1
else
local p,q,s=find(z,"^(%d%d?%d?)",i)
i=q+1
if s+1>256 then
errorline("escape sequence too large")
end
end
else
i=i+1
if r==del then
I=i
return sub(z,buff,i-1)
end
end
else
break
end
end
errorline("unfinished string")
end
function llex()
local find=find
local match=match
while true do
local i=I
while true do
local p,_,r=find(z,"^([_%a][_%w]*)",i)
if p then
I=i+#r
if kw[r]then
addtoken("TK_KEYWORD",r)
else
addtoken("TK_NAME",r)
end
break
end
local p,_,r=find(z,"^(%.?)%d",i)
if p then
if r=="."then i=i+1 end
local _,q,r=find(z,"^%d*[%.%d]*([eE]?)",i)
i=q+1
if#r==1 then
if match(z,"^[%+%-]",i)then
i=i+1
end
end
local _,q=find(z,"^[_%w]*",i)
I=q+1
local v=sub(z,p,q)
if not base.tonumber(v)then
errorline("malformed number")
end
addtoken("TK_NUMBER",v)
break
end
local p,q,r,t=find(z,"^((%s)[ \t\v\f]*)",i)
if p then
if t=="\n"or t=="\r"then
inclinenumber(i,true)
else
I=q+1
addtoken("TK_SPACE",r)
end
break
end
local r=match(z,"^%p",i)
if r then
buff=i
local p=find("-[\"\'.=<>~",r,1,true)
if p then
if p<=2 then
if p==1 then
local c=match(z,"^%-%-(%[?)",i)
if c then
i=i+2
local sep=-1
if c=="["then
sep=skip_sep(i)
end
if sep>=0 then
addtoken("TK_LCOMMENT",read_long_string(false,sep))
else
I=find(z,"[\n\r]",i)or(#z+1)
addtoken("TK_COMMENT",sub(z,buff,I-1))
end
break
end
else
local sep=skip_sep(i)
if sep>=0 then
addtoken("TK_LSTRING",read_long_string(true,sep))
elseif sep==-1 then
addtoken("TK_OP","[")
else
errorline("invalid long string delimiter")
end
break
end
elseif p<=5 then
if p<5 then
I=i+1
addtoken("TK_STRING",read_string(r))
break
end
r=match(z,"^%.%.?%.?",i)
else
r=match(z,"^%p=?",i)
end
end
I=i+#r
addtoken("TK_OP",r)
break
end
local r=sub(z,i,i)
if r~=""then
I=i+1
addtoken("TK_OP",r)
break
end
addtoken("TK_EOS","")
return
end
end
end
return base.getfenv()
