local base=_G
local string=require"string"module"optlex"local match=string.match
local sub=string.sub
local find=string.find
error=base.error
local stoks,sinfos
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
local function repack_tokens()local dtoks,dinfos={},{}local j=1
for i=1,#stoks do
local tok=stoks[i]if tok~=""then
dtoks[j],dinfos[j]=tok,sinfos[i]j=j+1
end
end
stoks,sinfos=dtoks,dinfos
end
local function do_number(i)end
local function do_string(i)end
local function do_lstring(i)end
local function do_comment(i)end
local function do_comment(i)end
function optimize(option,toklist,semlist)local opt_comments=option["opt-comments"]local opt_whitespace=option["opt-whitespace"]local opt_emptylines=option["opt-emptylines"]local opt_eols=option["opt-eols"]local opt_strings=option["opt-strings"]local opt_numbers=option["opt-numbers"]if opt_eols then
opt_comments=true
opt_whitespace=true
opt_emptylines=true
end
stoks,sinfos=toklist,semlist
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
settoken("TK_EOL",string.rep("\n",eols))end
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
return stoks,sinfos
end
