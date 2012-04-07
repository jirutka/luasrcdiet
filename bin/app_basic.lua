#!/usr/bin/env lua
local string=string
local math=math
local table=table
local require=require
local print=print
local sub=string.sub
local gmatch=string.gmatch
local match=string.match
local preload=package.preload
local base=_G
local plugin_info={
html="html    generates a HTML file for checking globals",
sloc="sloc    calculates SLOC for given source file",
}
local p_embedded={
'html',
'sloc',
}
preload.llex=
function()
module"llex"
local string=base.require"string"
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
end
preload.lparser=
function()
module"lparser"
local string=base.require"string"
local toklist,
seminfolist,
toklnlist,
xreflist,
tpos,
line,
lastln,
tok,seminfo,ln,xref,
nameref,
fs,
top_fs,
globalinfo,
globallookup,
localinfo,
ilocalinfo,
ilocalrefs,
statinfo
local explist1,expr,block,exp1,body,chunk
local gmatch=string.gmatch
local block_follow={}
for v in gmatch("else elseif end until <eof>","%S+")do
block_follow[v]=true
end
local binopr_left={}
local binopr_right={}
for op,lt,rt in gmatch([[
{+ 6 6}{- 6 6}{* 7 7}{/ 7 7}{% 7 7}
{^ 10 9}{.. 5 4}
{~= 3 3}{== 3 3}
{< 3 3}{<= 3 3}{> 3 3}{>= 3 3}
{and 2 2}{or 1 1}
]],"{(%S+)%s(%d+)%s(%d+)}")do
binopr_left[op]=lt+0
binopr_right[op]=rt+0
end
local unopr={["not"]=true,["-"]=true,
["#"]=true,}
local UNARY_PRIORITY=8
local function errorline(s,line)
local e=error or base.error
e(string.format("(source):%d: %s",line or ln,s))
end
local function nextt()
lastln=toklnlist[tpos]
tok,seminfo,ln,xref
=toklist[tpos],seminfolist[tpos],toklnlist[tpos],xreflist[tpos]
tpos=tpos+1
end
local function lookahead()
return toklist[tpos]
end
local function syntaxerror(msg)
local tok=tok
if tok~="<number>"and tok~="<string>"then
if tok=="<name>"then tok=seminfo end
tok="'"..tok.."'"
end
errorline(msg.." near "..tok)
end
local function error_expected(token)
syntaxerror("'"..token.."' expected")
end
local function testnext(c)
if tok==c then nextt();return true end
end
local function check(c)
if tok~=c then error_expected(c)end
end
local function checknext(c)
check(c);nextt()
end
local function check_condition(c,msg)
if not c then syntaxerror(msg)end
end
local function check_match(what,who,where)
if not testnext(what)then
if where==ln then
error_expected(what)
else
syntaxerror("'"..what.."' expected (to close '"..who.."' at line "..where..")")
end
end
end
local function str_checkname()
check("<name>")
local ts=seminfo
nameref=xref
nextt()
return ts
end
local function codestring(e,s)
e.k="VK"
end
local function checkname(e)
codestring(e,str_checkname())
end
local function new_localvar(name,special)
local bl=fs.bl
local locallist
if bl then
locallist=bl.locallist
else
locallist=fs.locallist
end
local id=#localinfo+1
localinfo[id]={
name=name,
xref={nameref},
decl=nameref,
}
if special then
localinfo[id].isself=true
end
local i=#ilocalinfo+1
ilocalinfo[i]=id
ilocalrefs[i]=locallist
end
local function adjustlocalvars(nvars)
local sz=#ilocalinfo
while nvars>0 do
nvars=nvars-1
local i=sz-nvars
local id=ilocalinfo[i]
local obj=localinfo[id]
local name=obj.name
obj.act=xref
ilocalinfo[i]=nil
local locallist=ilocalrefs[i]
ilocalrefs[i]=nil
local existing=locallist[name]
if existing then
obj=localinfo[existing]
obj.rem=-id
end
locallist[name]=id
end
end
local function removevars()
local bl=fs.bl
local locallist
if bl then
locallist=bl.locallist
else
locallist=fs.locallist
end
for name,id in base.pairs(locallist)do
local obj=localinfo[id]
obj.rem=xref
end
end
local function new_localvarliteral(name,special)
if string.sub(name,1,1)=="("then
return
end
new_localvar(name,special)
end
local function searchvar(fs,n)
local bl=fs.bl
local locallist
if bl then
locallist=bl.locallist
while locallist do
if locallist[n]then return locallist[n]end
bl=bl.prev
locallist=bl and bl.locallist
end
end
locallist=fs.locallist
return locallist[n]or-1
end
local function singlevaraux(fs,n,var)
if fs==nil then
var.k="VGLOBAL"
return"VGLOBAL"
else
local v=searchvar(fs,n)
if v>=0 then
var.k="VLOCAL"
var.id=v
return"VLOCAL"
else
if singlevaraux(fs.prev,n,var)=="VGLOBAL"then
return"VGLOBAL"
end
var.k="VUPVAL"
return"VUPVAL"
end
end
end
local function singlevar(v)
local name=str_checkname()
singlevaraux(fs,name,v)
if v.k=="VGLOBAL"then
local id=globallookup[name]
if not id then
id=#globalinfo+1
globalinfo[id]={
name=name,
xref={nameref},
}
globallookup[name]=id
else
local obj=globalinfo[id].xref
obj[#obj+1]=nameref
end
else
local id=v.id
local obj=localinfo[id].xref
obj[#obj+1]=nameref
end
end
local function enterblock(isbreakable)
local bl={}
bl.isbreakable=isbreakable
bl.prev=fs.bl
bl.locallist={}
fs.bl=bl
end
local function leaveblock()
local bl=fs.bl
removevars()
fs.bl=bl.prev
end
local function open_func()
local new_fs
if not fs then
new_fs=top_fs
else
new_fs={}
end
new_fs.prev=fs
new_fs.bl=nil
new_fs.locallist={}
fs=new_fs
end
local function close_func()
removevars()
fs=fs.prev
end
local function field(v)
local key={}
nextt()
checkname(key)
v.k="VINDEXED"
end
local function yindex(v)
nextt()
expr(v)
checknext("]")
end
local function recfield(cc)
local key,val={},{}
if tok=="<name>"then
checkname(key)
else
yindex(key)
end
checknext("=")
expr(val)
end
local function closelistfield(cc)
if cc.v.k=="VVOID"then return end
cc.v.k="VVOID"
end
local function listfield(cc)
expr(cc.v)
end
local function constructor(t)
local line=ln
local cc={}
cc.v={}
cc.t=t
t.k="VRELOCABLE"
cc.v.k="VVOID"
checknext("{")
repeat
if tok=="}"then break end
local c=tok
if c=="<name>"then
if lookahead()~="="then
listfield(cc)
else
recfield(cc)
end
elseif c=="["then
recfield(cc)
else
listfield(cc)
end
until not testnext(",")and not testnext(";")
check_match("}","{",line)
end
local function parlist()
local nparams=0
if tok~=")"then
repeat
local c=tok
if c=="<name>"then
new_localvar(str_checkname())
nparams=nparams+1
elseif c=="..."then
nextt()
fs.is_vararg=true
else
syntaxerror("<name> or '...' expected")
end
until fs.is_vararg or not testnext(",")
end
adjustlocalvars(nparams)
end
local function funcargs(f)
local args={}
local line=ln
local c=tok
if c=="("then
if line~=lastln then
syntaxerror("ambiguous syntax (function call x new statement)")
end
nextt()
if tok==")"then
args.k="VVOID"
else
explist1(args)
end
check_match(")","(",line)
elseif c=="{"then
constructor(args)
elseif c=="<string>"then
codestring(args,seminfo)
nextt()
else
syntaxerror("function arguments expected")
return
end
f.k="VCALL"
end
local function prefixexp(v)
local c=tok
if c=="("then
local line=ln
nextt()
expr(v)
check_match(")","(",line)
elseif c=="<name>"then
singlevar(v)
else
syntaxerror("unexpected symbol")
end
end
local function primaryexp(v)
prefixexp(v)
while true do
local c=tok
if c=="."then
field(v)
elseif c=="["then
local key={}
yindex(key)
elseif c==":"then
local key={}
nextt()
checkname(key)
funcargs(v)
elseif c=="("or c=="<string>"or c=="{"then
funcargs(v)
else
return
end
end
end
local function simpleexp(v)
local c=tok
if c=="<number>"then
v.k="VKNUM"
elseif c=="<string>"then
codestring(v,seminfo)
elseif c=="nil"then
v.k="VNIL"
elseif c=="true"then
v.k="VTRUE"
elseif c=="false"then
v.k="VFALSE"
elseif c=="..."then
check_condition(fs.is_vararg==true,
"cannot use '...' outside a vararg function");
v.k="VVARARG"
elseif c=="{"then
constructor(v)
return
elseif c=="function"then
nextt()
body(v,false,ln)
return
else
primaryexp(v)
return
end
nextt()
end
local function subexpr(v,limit)
local op=tok
local uop=unopr[op]
if uop then
nextt()
subexpr(v,UNARY_PRIORITY)
else
simpleexp(v)
end
op=tok
local binop=binopr_left[op]
while binop and binop>limit do
local v2={}
nextt()
local nextop=subexpr(v2,binopr_right[op])
op=nextop
binop=binopr_left[op]
end
return op
end
function expr(v)
subexpr(v,0)
end
local function assignment(v)
local e={}
local c=v.v.k
check_condition(c=="VLOCAL"or c=="VUPVAL"or c=="VGLOBAL"
or c=="VINDEXED","syntax error")
if testnext(",")then
local nv={}
nv.v={}
primaryexp(nv.v)
assignment(nv)
else
checknext("=")
explist1(e)
return
end
e.k="VNONRELOC"
end
local function forbody(nvars,isnum)
checknext("do")
enterblock(false)
adjustlocalvars(nvars)
block()
leaveblock()
end
local function fornum(varname)
local line=line
new_localvarliteral("(for index)")
new_localvarliteral("(for limit)")
new_localvarliteral("(for step)")
new_localvar(varname)
checknext("=")
exp1()
checknext(",")
exp1()
if testnext(",")then
exp1()
else
end
forbody(1,true)
end
local function forlist(indexname)
local e={}
new_localvarliteral("(for generator)")
new_localvarliteral("(for state)")
new_localvarliteral("(for control)")
new_localvar(indexname)
local nvars=1
while testnext(",")do
new_localvar(str_checkname())
nvars=nvars+1
end
checknext("in")
local line=line
explist1(e)
forbody(nvars,false)
end
local function funcname(v)
local needself=false
singlevar(v)
while tok=="."do
field(v)
end
if tok==":"then
needself=true
field(v)
end
return needself
end
function exp1()
local e={}
expr(e)
end
local function cond()
local v={}
expr(v)
end
local function test_then_block()
nextt()
cond()
checknext("then")
block()
end
local function localfunc()
local v,b={}
new_localvar(str_checkname())
v.k="VLOCAL"
adjustlocalvars(1)
body(b,false,ln)
end
local function localstat()
local nvars=0
local e={}
repeat
new_localvar(str_checkname())
nvars=nvars+1
until not testnext(",")
if testnext("=")then
explist1(e)
else
e.k="VVOID"
end
adjustlocalvars(nvars)
end
function explist1(e)
expr(e)
while testnext(",")do
expr(e)
end
end
function body(e,needself,line)
open_func()
checknext("(")
if needself then
new_localvarliteral("self",true)
adjustlocalvars(1)
end
parlist()
checknext(")")
chunk()
check_match("end","function",line)
close_func()
end
function block()
enterblock(false)
chunk()
leaveblock()
end
local function for_stat()
local line=line
enterblock(true)
nextt()
local varname=str_checkname()
local c=tok
if c=="="then
fornum(varname)
elseif c==","or c=="in"then
forlist(varname)
else
syntaxerror("'=' or 'in' expected")
end
check_match("end","for",line)
leaveblock()
end
local function while_stat()
local line=line
nextt()
cond()
enterblock(true)
checknext("do")
block()
check_match("end","while",line)
leaveblock()
end
local function repeat_stat()
local line=line
enterblock(true)
enterblock(false)
nextt()
chunk()
check_match("until","repeat",line)
cond()
leaveblock()
leaveblock()
end
local function if_stat()
local line=line
local v={}
test_then_block()
while tok=="elseif"do
test_then_block()
end
if tok=="else"then
nextt()
block()
end
check_match("end","if",line)
end
local function return_stat()
local e={}
nextt()
local c=tok
if block_follow[c]or c==";"then
else
explist1(e)
end
end
local function break_stat()
local bl=fs.bl
nextt()
while bl and not bl.isbreakable do
bl=bl.prev
end
if not bl then
syntaxerror("no loop to break")
end
end
local function expr_stat()
local id=tpos-1
local v={}
v.v={}
primaryexp(v.v)
if v.v.k=="VCALL"then
statinfo[id]="call"
else
v.prev=nil
assignment(v)
statinfo[id]="assign"
end
end
local function function_stat()
local line=line
local v,b={},{}
nextt()
local needself=funcname(v)
body(b,needself,line)
end
local function do_stat()
local line=line
nextt()
block()
check_match("end","do",line)
end
local function local_stat()
nextt()
if testnext("function")then
localfunc()
else
localstat()
end
end
local stat_call={
["if"]=if_stat,
["while"]=while_stat,
["do"]=do_stat,
["for"]=for_stat,
["repeat"]=repeat_stat,
["function"]=function_stat,
["local"]=local_stat,
["return"]=return_stat,
["break"]=break_stat,
}
local function stat()
line=ln
local c=tok
local fn=stat_call[c]
if fn then
statinfo[tpos-1]=c
fn()
if c=="return"or c=="break"then return true end
else
expr_stat()
end
return false
end
function chunk()
local islast=false
while not islast and not block_follow[tok]do
islast=stat()
testnext(";")
end
end
function parser()
open_func()
fs.is_vararg=true
nextt()
chunk()
check("<eof>")
close_func()
return{
globalinfo=globalinfo,
localinfo=localinfo,
statinfo=statinfo,
toklist=toklist,
seminfolist=seminfolist,
toklnlist=toklnlist,
xreflist=xreflist,
}
end
function init(tokorig,seminfoorig,toklnorig)
tpos=1
top_fs={}
local j=1
toklist,seminfolist,toklnlist,xreflist={},{},{},{}
for i=1,#tokorig do
local tok=tokorig[i]
local yep=true
if tok=="TK_KEYWORD"or tok=="TK_OP"then
tok=seminfoorig[i]
elseif tok=="TK_NAME"then
tok="<name>"
seminfolist[j]=seminfoorig[i]
elseif tok=="TK_NUMBER"then
tok="<number>"
seminfolist[j]=0
elseif tok=="TK_STRING"or tok=="TK_LSTRING"then
tok="<string>"
seminfolist[j]=""
elseif tok=="TK_EOS"then
tok="<eof>"
else
yep=false
end
if yep then
toklist[j]=tok
toklnlist[j]=toklnorig[i]
xreflist[j]=i
j=j+1
end
end
globalinfo,globallookup,localinfo={},{},{}
ilocalinfo,ilocalrefs={},{}
statinfo={}
end
end
preload.optlex=
function()
module"optlex"
local string=base.require"string"
local match=string.match
local sub=string.sub
local find=string.find
local rep=string.rep
local print
error=base.error
warn={}
local stoks,sinfos,stoklns
local is_realtoken={
TK_KEYWORD=true,
TK_NAME=true,
TK_NUMBER=true,
TK_STRING=true,
TK_LSTRING=true,
TK_OP=true,
TK_EOS=true,
}
local is_faketoken={
TK_COMMENT=true,
TK_LCOMMENT=true,
TK_EOL=true,
TK_SPACE=true,
}
local opt_details
local function atlinestart(i)
local tok=stoks[i-1]
if i<=1 or tok=="TK_EOL"then
return true
elseif tok==""then
return atlinestart(i-1)
end
return false
end
local function atlineend(i)
local tok=stoks[i+1]
if i>=#stoks or tok=="TK_EOL"or tok=="TK_EOS"then
return true
elseif tok==""then
return atlineend(i+1)
end
return false
end
local function commenteols(lcomment)
local sep=#match(lcomment,"^%-%-%[=*%[")
local z=sub(lcomment,sep+1,-(sep-1))
local i,c=1,0
while true do
local p,q,r,s=find(z,"([\r\n])([\r\n]?)",i)
if not p then break end
i=p+1
c=c+1
if#s>0 and r~=s then
i=i+1
end
end
return c
end
local function checkpair(i,j)
local match=match
local t1,t2=stoks[i],stoks[j]
if t1=="TK_STRING"or t1=="TK_LSTRING"or
t2=="TK_STRING"or t2=="TK_LSTRING"then
return""
elseif t1=="TK_OP"or t2=="TK_OP"then
if(t1=="TK_OP"and(t2=="TK_KEYWORD"or t2=="TK_NAME"))or
(t2=="TK_OP"and(t1=="TK_KEYWORD"or t1=="TK_NAME"))then
return""
end
if t1=="TK_OP"and t2=="TK_OP"then
local op,op2=sinfos[i],sinfos[j]
if(match(op,"^%.%.?$")and match(op2,"^%."))or
(match(op,"^[~=<>]$")and op2=="=")or
(op=="["and(op2=="["or op2=="="))then
return" "
end
return""
end
local op=sinfos[i]
if t2=="TK_OP"then op=sinfos[j]end
if match(op,"^%.%.?%.?$")then
return" "
end
return""
else
return" "
end
end
local function repack_tokens()
local dtoks,dinfos,dtoklns={},{},{}
local j=1
for i=1,#stoks do
local tok=stoks[i]
if tok~=""then
dtoks[j],dinfos[j],dtoklns[j]=tok,sinfos[i],stoklns[i]
j=j+1
end
end
stoks,sinfos,stoklns=dtoks,dinfos,dtoklns
end
local function do_number(i)
local before=sinfos[i]
local z=before
local y
if match(z,"^0[xX]")then
local v=base.tostring(base.tonumber(z))
if#v<=#z then
z=v
else
return
end
end
if match(z,"^%d+%.?0*$")then
z=match(z,"^(%d+)%.?0*$")
if z+0>0 then
z=match(z,"^0*([1-9]%d*)$")
local v=#match(z,"0*$")
local nv=base.tostring(v)
if v>#nv+1 then
z=sub(z,1,#z-v).."e"..nv
end
y=z
else
y="0"
end
elseif not match(z,"[eE]")then
local p,q=match(z,"^(%d*)%.(%d+)$")
if p==""then p=0 end
if q+0==0 and p==0 then
y="0"
else
local v=#match(q,"0*$")
if v>0 then
q=sub(q,1,#q-v)
end
if p+0>0 then
y=p.."."..q
else
y="."..q
local v=#match(q,"^0*")
local w=#q-v
local nv=base.tostring(#q)
if w+2+#nv<1+#q then
y=sub(q,-w).."e-"..nv
end
end
end
else
local sig,ex=match(z,"^([^eE]+)[eE]([%+%-]?%d+)$")
ex=base.tonumber(ex)
local p,q=match(sig,"^(%d*)%.(%d*)$")
if p then
ex=ex-#q
sig=p..q
end
if sig+0==0 then
y="0"
else
local v=#match(sig,"^0*")
sig=sub(sig,v+1)
v=#match(sig,"0*$")
if v>0 then
sig=sub(sig,1,#sig-v)
ex=ex+v
end
local nex=base.tostring(ex)
if ex==0 then
y=sig
elseif ex>0 and(ex<=1+#nex)then
y=sig..rep("0",ex)
elseif ex<0 and(ex>=-#sig)then
v=#sig+ex
y=sub(sig,1,v).."."..sub(sig,v+1)
elseif ex<0 and(#nex>=-ex-#sig)then
v=-ex-#sig
y="."..rep("0",v)..sig
else
y=sig.."e"..ex
end
end
end
if y and y~=sinfos[i]then
if opt_details then
print("<number> (line "..stoklns[i]..") "..sinfos[i].." -> "..y)
opt_details=opt_details+1
end
sinfos[i]=y
end
end
local function do_string(I)
local info=sinfos[I]
local delim=sub(info,1,1)
local ndelim=(delim=="'")and'"'or"'"
local z=sub(info,2,-2)
local i=1
local c_delim,c_ndelim=0,0
while i<=#z do
local c=sub(z,i,i)
if c=="\\"then
local j=i+1
local d=sub(z,j,j)
local p=find("abfnrtv\\\n\r\"\'0123456789",d,1,true)
if not p then
z=sub(z,1,i-1)..sub(z,j)
i=i+1
elseif p<=8 then
i=i+2
elseif p<=10 then
local eol=sub(z,j,j+1)
if eol=="\r\n"or eol=="\n\r"then
z=sub(z,1,i).."\n"..sub(z,j+2)
elseif p==10 then
z=sub(z,1,i).."\n"..sub(z,j+1)
end
i=i+2
elseif p<=12 then
if d==delim then
c_delim=c_delim+1
i=i+2
else
c_ndelim=c_ndelim+1
z=sub(z,1,i-1)..sub(z,j)
i=i+1
end
else
local s=match(z,"^(%d%d?%d?)",j)
j=i+1+#s
local cv=s+0
local cc=string.char(cv)
local p=find("\a\b\f\n\r\t\v",cc,1,true)
if p then
s="\\"..sub("abfnrtv",p,p)
elseif cv<32 then
if match(sub(z,j,j),"%d")then
s="\\"..s
else
s="\\"..cv
end
elseif cc==delim then
s="\\"..cc
c_delim=c_delim+1
elseif cc=="\\"then
s="\\\\"
else
s=cc
if cc==ndelim then
c_ndelim=c_ndelim+1
end
end
z=sub(z,1,i-1)..s..sub(z,j)
i=i+#s
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
local p,q,r=find(z,"([\'\"])",i)
if not p then break end
if r==delim then
z=sub(z,1,p-2)..sub(z,p)
i=p
else
z=sub(z,1,p-1).."\\"..sub(z,p)
i=p+2
end
end
delim=ndelim
end
z=delim..z..delim
if z~=sinfos[I]then
if opt_details then
print("<string> (line "..stoklns[I]..") "..sinfos[I].." -> "..z)
opt_details=opt_details+1
end
sinfos[I]=z
end
end
local function do_lstring(I)
local info=sinfos[I]
local delim1=match(info,"^%[=*%[")
local sep=#delim1
local delim2=sub(info,-sep,-1)
local z=sub(info,sep+1,-(sep+1))
local y=""
local i=1
while true do
local p,q,r,s=find(z,"([\r\n])([\r\n]?)",i)
local ln
if not p then
ln=sub(z,i)
elseif p>=i then
ln=sub(z,i,p-1)
end
if ln~=""then
if match(ln,"%s+$")then
warn.LSTRING="trailing whitespace in long string near line "..stoklns[I]
end
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
y=y.."\n"
end
end
end
if sep>=3 then
local chk,okay=sep-1
while chk>=2 do
local delim="%]"..rep("=",chk-2).."%]"
if not match(y,delim)then okay=chk end
chk=chk-1
end
if okay then
sep=rep("=",okay-2)
delim1,delim2="["..sep.."[","]"..sep.."]"
end
end
sinfos[I]=delim1..y..delim2
end
local function do_lcomment(I)
local info=sinfos[I]
local delim1=match(info,"^%-%-%[=*%[")
local sep=#delim1
local delim2=sub(info,-(sep-2),-1)
local z=sub(info,sep+1,-(sep-1))
local y=""
local i=1
while true do
local p,q,r,s=find(z,"([\r\n])([\r\n]?)",i)
local ln
if not p then
ln=sub(z,i)
elseif p>=i then
ln=sub(z,i,p-1)
end
if ln~=""then
local ws=match(ln,"%s*$")
if#ws>0 then ln=sub(ln,1,-(ws+1))end
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
y=y.."\n"
end
end
sep=sep-2
if sep>=3 then
local chk,okay=sep-1
while chk>=2 do
local delim="%]"..rep("=",chk-2).."%]"
if not match(y,delim)then okay=chk end
chk=chk-1
end
if okay then
sep=rep("=",okay-2)
delim1,delim2="--["..sep.."[","]"..sep.."]"
end
end
sinfos[I]=delim1..y..delim2
end
local function do_comment(i)
local info=sinfos[i]
local ws=match(info,"%s*$")
if#ws>0 then
info=sub(info,1,-(ws+1))
end
sinfos[i]=info
end
local function keep_lcomment(opt_keep,info)
if not opt_keep then return false end
local delim1=match(info,"^%-%-%[=*%[")
local sep=#delim1
local delim2=sub(info,-sep,-1)
local z=sub(info,sep+1,-(sep-1))
if find(z,opt_keep,1,true)then
return true
end
end
function optimize(option,toklist,semlist,toklnlist)
local opt_comments=option["opt-comments"]
local opt_whitespace=option["opt-whitespace"]
local opt_emptylines=option["opt-emptylines"]
local opt_eols=option["opt-eols"]
local opt_strings=option["opt-strings"]
local opt_numbers=option["opt-numbers"]
local opt_x=option["opt-experimental"]
local opt_keep=option.KEEP
opt_details=option.DETAILS and 0
print=print or base.print
if opt_eols then
opt_comments=true
opt_whitespace=true
opt_emptylines=true
elseif opt_x then
opt_whitespace=true
end
stoks,sinfos,stoklns
=toklist,semlist,toklnlist
local i=1
local tok,info
local prev
local function settoken(tok,info,I)
I=I or i
stoks[I]=tok or""
sinfos[I]=info or""
end
if opt_x then
while true do
tok,info=stoks[i],sinfos[i]
if tok=="TK_EOS"then
break
elseif tok=="TK_OP"and info==";"then
settoken("TK_SPACE"," ")
end
i=i+1
end
repack_tokens()
end
i=1
while true do
tok,info=stoks[i],sinfos[i]
local atstart=atlinestart(i)
if atstart then prev=nil end
if tok=="TK_EOS"then
break
elseif tok=="TK_KEYWORD"or
tok=="TK_NAME"or
tok=="TK_OP"then
prev=i
elseif tok=="TK_NUMBER"then
if opt_numbers then
do_number(i)
end
prev=i
elseif tok=="TK_STRING"or
tok=="TK_LSTRING"then
if opt_strings then
if tok=="TK_STRING"then
do_string(i)
else
do_lstring(i)
end
end
prev=i
elseif tok=="TK_COMMENT"then
if opt_comments then
if i==1 and sub(info,1,1)=="#"then
do_comment(i)
else
settoken()
end
elseif opt_whitespace then
do_comment(i)
end
elseif tok=="TK_LCOMMENT"then
if keep_lcomment(opt_keep,info)then
if opt_whitespace then
do_lcomment(i)
end
prev=i
elseif opt_comments then
local eols=commenteols(info)
if is_faketoken[stoks[i+1]]then
settoken()
tok=""
else
settoken("TK_SPACE"," ")
end
if not opt_emptylines and eols>0 then
settoken("TK_EOL",rep("\n",eols))
end
if opt_whitespace and tok~=""then
i=i-1
end
else
if opt_whitespace then
do_lcomment(i)
end
prev=i
end
elseif tok=="TK_EOL"then
if atstart and opt_emptylines then
settoken()
elseif info=="\r\n"or info=="\n\r"then
settoken("TK_EOL","\n")
end
elseif tok=="TK_SPACE"then
if opt_whitespace then
if atstart or atlineend(i)then
settoken()
else
local ptok=stoks[prev]
if ptok=="TK_LCOMMENT"then
settoken()
else
local ntok=stoks[i+1]
if is_faketoken[ntok]then
if(ntok=="TK_COMMENT"or ntok=="TK_LCOMMENT")and
ptok=="TK_OP"and sinfos[prev]=="-"then
else
settoken()
end
else
local s=checkpair(prev,i+1)
if s==""then
settoken()
else
settoken("TK_SPACE"," ")
end
end
end
end
end
else
error("unidentified token encountered")
end
i=i+1
end
repack_tokens()
if opt_eols then
i=1
if stoks[1]=="TK_COMMENT"then
i=3
end
while true do
tok,info=stoks[i],sinfos[i]
if tok=="TK_EOS"then
break
elseif tok=="TK_EOL"then
local t1,t2=stoks[i-1],stoks[i+1]
if is_realtoken[t1]and is_realtoken[t2]then
local s=checkpair(i-1,i+1)
if s==""or t2=="TK_EOS"then
settoken()
end
end
end
i=i+1
end
repack_tokens()
end
if opt_details and opt_details>0 then print()end
return stoks,sinfos,stoklns
end
end
preload.optparser=
function()
module"optparser"
local string=base.require"string"
local table=base.require"table"
local LETTERS="etaoinshrdlucmfwypvbgkqjxz_ETAOINSHRDLUCMFWYPVBGKQJXZ"
local ALPHANUM="etaoinshrdlucmfwypvbgkqjxz_0123456789ETAOINSHRDLUCMFWYPVBGKQJXZ"
local SKIP_NAME={}
for v in string.gmatch([[
and break do else elseif end false for function if in
local nil not or repeat return then true until while
self]],"%S+")do
SKIP_NAME[v]=true
end
local toklist,seminfolist,
tokpar,seminfopar,xrefpar,
globalinfo,localinfo,
statinfo,
globaluniq,localuniq,
var_new,
varlist
local function preprocess(infotable)
local uniqtable={}
for i=1,#infotable do
local obj=infotable[i]
local name=obj.name
if not uniqtable[name]then
uniqtable[name]={
decl=0,token=0,size=0,
}
end
local uniq=uniqtable[name]
uniq.decl=uniq.decl+1
local xref=obj.xref
local xcount=#xref
uniq.token=uniq.token+xcount
uniq.size=uniq.size+xcount*#name
if obj.decl then
obj.id=i
obj.xcount=xcount
if xcount>1 then
obj.first=xref[2]
obj.last=xref[xcount]
end
else
uniq.id=i
end
end
return uniqtable
end
local function recalc_for_entropy(option)
local byte=string.byte
local char=string.char
local ACCEPT={
TK_KEYWORD=true,TK_NAME=true,TK_NUMBER=true,
TK_STRING=true,TK_LSTRING=true,
}
if not option["opt-comments"]then
ACCEPT.TK_COMMENT=true
ACCEPT.TK_LCOMMENT=true
end
local filtered={}
for i=1,#toklist do
filtered[i]=seminfolist[i]
end
for i=1,#localinfo do
local obj=localinfo[i]
local xref=obj.xref
for j=1,obj.xcount do
local p=xref[j]
filtered[p]=""
end
end
local freq={}
for i=0,255 do freq[i]=0 end
for i=1,#toklist do
local tok,info=toklist[i],filtered[i]
if ACCEPT[tok]then
for j=1,#info do
local c=byte(info,j)
freq[c]=freq[c]+1
end
end
end
local function resort(symbols)
local symlist={}
for i=1,#symbols do
local c=byte(symbols,i)
symlist[i]={c=c,freq=freq[c],}
end
table.sort(symlist,
function(v1,v2)
return v1.freq>v2.freq
end
)
local charlist={}
for i=1,#symlist do
charlist[i]=char(symlist[i].c)
end
return table.concat(charlist)
end
LETTERS=resort(LETTERS)
ALPHANUM=resort(ALPHANUM)
end
local function new_var_name()
local var
local cletters,calphanum=#LETTERS,#ALPHANUM
local v=var_new
if v<cletters then
v=v+1
var=string.sub(LETTERS,v,v)
else
local range,sz=cletters,1
repeat
v=v-range
range=range*calphanum
sz=sz+1
until range>v
local n=v%cletters
v=(v-n)/cletters
n=n+1
var=string.sub(LETTERS,n,n)
while sz>1 do
local m=v%calphanum
v=(v-m)/calphanum
m=m+1
var=var..string.sub(ALPHANUM,m,m)
sz=sz-1
end
end
var_new=var_new+1
return var,globaluniq[var]~=nil
end
local function stats_summary(globaluniq,localuniq,afteruniq,option)
local print=print or base.print
local fmt=string.format
local opt_details=option.DETAILS
if option.QUIET then return end
local uniq_g,uniq_li,uniq_lo,uniq_ti,uniq_to,
decl_g,decl_li,decl_lo,decl_ti,decl_to,
token_g,token_li,token_lo,token_ti,token_to,
size_g,size_li,size_lo,size_ti,size_to
=0,0,0,0,0,0,0,0,0,0,
0,0,0,0,0,0,0,0,0,0
local function avg(c,l)
if c==0 then return 0 end
return l/c
end
for name,uniq in base.pairs(globaluniq)do
uniq_g=uniq_g+1
token_g=token_g+uniq.token
size_g=size_g+uniq.size
end
for name,uniq in base.pairs(localuniq)do
uniq_li=uniq_li+1
decl_li=decl_li+uniq.decl
token_li=token_li+uniq.token
size_li=size_li+uniq.size
end
for name,uniq in base.pairs(afteruniq)do
uniq_lo=uniq_lo+1
decl_lo=decl_lo+uniq.decl
token_lo=token_lo+uniq.token
size_lo=size_lo+uniq.size
end
uniq_ti=uniq_g+uniq_li
decl_ti=decl_g+decl_li
token_ti=token_g+token_li
size_ti=size_g+size_li
uniq_to=uniq_g+uniq_lo
decl_to=decl_g+decl_lo
token_to=token_g+token_lo
size_to=size_g+size_lo
if opt_details then
local sorted={}
for name,uniq in base.pairs(globaluniq)do
uniq.name=name
sorted[#sorted+1]=uniq
end
table.sort(sorted,
function(v1,v2)
return v1.size>v2.size
end
)
local tabf1,tabf2="%8s%8s%10s  %s","%8d%8d%10.2f  %s"
local hl=string.rep("-",44)
print("*** global variable list (sorted by size) ***\n"..hl)
print(fmt(tabf1,"Token","Input","Input","Global"))
print(fmt(tabf1,"Count","Bytes","Average","Name"))
print(hl)
for i=1,#sorted do
local uniq=sorted[i]
print(fmt(tabf2,uniq.token,uniq.size,avg(uniq.token,uniq.size),uniq.name))
end
print(hl)
print(fmt(tabf2,token_g,size_g,avg(token_g,size_g),"TOTAL"))
print(hl.."\n")
local tabf1,tabf2="%8s%8s%8s%10s%8s%10s  %s","%8d%8d%8d%10.2f%8d%10.2f  %s"
local hl=string.rep("-",70)
print("*** local variable list (sorted by allocation order) ***\n"..hl)
print(fmt(tabf1,"Decl.","Token","Input","Input","Output","Output","Global"))
print(fmt(tabf1,"Count","Count","Bytes","Average","Bytes","Average","Name"))
print(hl)
for i=1,#varlist do
local name=varlist[i]
local uniq=afteruniq[name]
local old_t,old_s=0,0
for j=1,#localinfo do
local obj=localinfo[j]
if obj.name==name then
old_t=old_t+obj.xcount
old_s=old_s+obj.xcount*#obj.oldname
end
end
print(fmt(tabf2,uniq.decl,uniq.token,old_s,avg(old_t,old_s),
uniq.size,avg(uniq.token,uniq.size),name))
end
print(hl)
print(fmt(tabf2,decl_lo,token_lo,size_li,avg(token_li,size_li),
size_lo,avg(token_lo,size_lo),"TOTAL"))
print(hl.."\n")
end
local tabf1,tabf2="%-16s%8s%8s%8s%8s%10s","%-16s%8d%8d%8d%8d%10.2f"
local hl=string.rep("-",58)
print("*** local variable optimization summary ***\n"..hl)
print(fmt(tabf1,"Variable","Unique","Decl.","Token","Size","Average"))
print(fmt(tabf1,"Types","Names","Count","Count","Bytes","Bytes"))
print(hl)
print(fmt(tabf2,"Global",uniq_g,decl_g,token_g,size_g,avg(token_g,size_g)))
print(hl)
print(fmt(tabf2,"Local (in)",uniq_li,decl_li,token_li,size_li,avg(token_li,size_li)))
print(fmt(tabf2,"TOTAL (in)",uniq_ti,decl_ti,token_ti,size_ti,avg(token_ti,size_ti)))
print(hl)
print(fmt(tabf2,"Local (out)",uniq_lo,decl_lo,token_lo,size_lo,avg(token_lo,size_lo)))
print(fmt(tabf2,"TOTAL (out)",uniq_to,decl_to,token_to,size_to,avg(token_to,size_to)))
print(hl.."\n")
end
local function optimize_func1()
local function is_strcall(j)
local t1=tokpar[j+1]or""
local t2=tokpar[j+2]or""
local t3=tokpar[j+3]or""
if t1=="("and t2=="<string>"and t3==")"then
return true
end
end
local del_list={}
local i=1
while i<=#tokpar do
local id=statinfo[i]
if id=="call"and is_strcall(i)then
del_list[i+1]=true
del_list[i+3]=true
i=i+3
end
i=i+1
end
local i,dst,idend=1,1,#tokpar
local del_list2={}
while dst<=idend do
if del_list[i]then
del_list2[xrefpar[i]]=true
i=i+1
end
if i>dst then
if i<=idend then
tokpar[dst]=tokpar[i]
seminfopar[dst]=seminfopar[i]
xrefpar[dst]=xrefpar[i]-(i-dst)
statinfo[dst]=statinfo[i]
else
tokpar[dst]=nil
seminfopar[dst]=nil
xrefpar[dst]=nil
statinfo[dst]=nil
end
end
i=i+1
dst=dst+1
end
local i,dst,idend=1,1,#toklist
while dst<=idend do
if del_list2[i]then
i=i+1
end
if i>dst then
if i<=idend then
toklist[dst]=toklist[i]
seminfolist[dst]=seminfolist[i]
else
toklist[dst]=nil
seminfolist[dst]=nil
end
end
i=i+1
dst=dst+1
end
end
local function optimize_locals(option)
var_new=0
varlist={}
globaluniq=preprocess(globalinfo)
localuniq=preprocess(localinfo)
if option["opt-entropy"]then
recalc_for_entropy(option)
end
local object={}
for i=1,#localinfo do
object[i]=localinfo[i]
end
table.sort(object,
function(v1,v2)
return v1.xcount>v2.xcount
end
)
local temp,j,gotself={},1,false
for i=1,#object do
local obj=object[i]
if not obj.isself then
temp[j]=obj
j=j+1
else
gotself=true
end
end
object=temp
local nobject=#object
while nobject>0 do
local varname,gcollide
repeat
varname,gcollide=new_var_name()
until not SKIP_NAME[varname]
varlist[#varlist+1]=varname
local oleft=nobject
if gcollide then
local gref=globalinfo[globaluniq[varname].id].xref
local ngref=#gref
for i=1,nobject do
local obj=object[i]
local act,rem=obj.act,obj.rem
while rem<0 do
rem=localinfo[-rem].rem
end
local drop
for j=1,ngref do
local p=gref[j]
if p>=act and p<=rem then drop=true end
end
if drop then
obj.skip=true
oleft=oleft-1
end
end
end
while oleft>0 do
local i=1
while object[i].skip do
i=i+1
end
oleft=oleft-1
local obja=object[i]
i=i+1
obja.newname=varname
obja.skip=true
obja.done=true
local first,last=obja.first,obja.last
local xref=obja.xref
if first and oleft>0 then
local scanleft=oleft
while scanleft>0 do
while object[i].skip do
i=i+1
end
scanleft=scanleft-1
local objb=object[i]
i=i+1
local act,rem=objb.act,objb.rem
while rem<0 do
rem=localinfo[-rem].rem
end
if not(last<act or first>rem)then
if act>=obja.act then
for j=1,obja.xcount do
local p=xref[j]
if p>=act and p<=rem then
oleft=oleft-1
objb.skip=true
break
end
end
else
if objb.last and objb.last>=obja.act then
oleft=oleft-1
objb.skip=true
end
end
end
if oleft==0 then break end
end
end
end
local temp,j={},1
for i=1,nobject do
local obj=object[i]
if not obj.done then
obj.skip=false
temp[j]=obj
j=j+1
end
end
object=temp
nobject=#object
end
for i=1,#localinfo do
local obj=localinfo[i]
local xref=obj.xref
if obj.newname then
for j=1,obj.xcount do
local p=xref[j]
seminfolist[p]=obj.newname
end
obj.name,obj.oldname
=obj.newname,obj.name
else
obj.oldname=obj.name
end
end
if gotself then
varlist[#varlist+1]="self"
end
local afteruniq=preprocess(localinfo)
stats_summary(globaluniq,localuniq,afteruniq,option)
end
function optimize(option,_toklist,_seminfolist,xinfo)
toklist,seminfolist
=_toklist,_seminfolist
tokpar,seminfopar,xrefpar
=xinfo.toklist,xinfo.seminfolist,xinfo.xreflist
globalinfo,localinfo,statinfo
=xinfo.globalinfo,xinfo.localinfo,xinfo.statinfo
if option["opt-locals"]then
optimize_locals(option)
end
if option["opt-experimental"]then
optimize_func1()
end
end
end
preload.equiv=
function()
module"equiv"
local string=base.require"string"
local loadstring=base.loadstring
local sub=string.sub
local match=string.match
local dump=string.dump
local byte=string.byte
local is_realtoken={
TK_KEYWORD=true,
TK_NAME=true,
TK_NUMBER=true,
TK_STRING=true,
TK_LSTRING=true,
TK_OP=true,
TK_EOS=true,
}
local option,llex,warn
function init(_option,_llex,_warn)
option=_option
llex=_llex
warn=_warn
end
local function build_stream(s)
llex.init(s)
llex.llex()
local stok,sseminfo
=llex.tok,llex.seminfo
local tok,seminfo
={},{}
for i=1,#stok do
local t=stok[i]
if is_realtoken[t]then
tok[#tok+1]=t
seminfo[#seminfo+1]=sseminfo[i]
end
end
return tok,seminfo
end
function source(z,dat)
local function dumpsem(s)
local sf=loadstring("return "..s,"z")
if sf then
return dump(sf)
end
end
local function bork(msg)
if option.DETAILS then base.print("SRCEQUIV: "..msg)end
warn.SRC_EQUIV=true
end
local tok1,seminfo1=build_stream(z)
local tok2,seminfo2=build_stream(dat)
local sh1=match(z,"^(#[^\r\n]*)")
local sh2=match(dat,"^(#[^\r\n]*)")
if sh1 or sh2 then
if not sh1 or not sh2 or sh1~=sh2 then
bork("shbang lines different")
end
end
if#tok1~=#tok2 then
bork("count "..#tok1.." "..#tok2)
return
end
for i=1,#tok1 do
local t1,t2=tok1[i],tok2[i]
local s1,s2=seminfo1[i],seminfo2[i]
if t1~=t2 then
bork("type ["..i.."] "..t1.." "..t2)
break
end
if t1=="TK_KEYWORD"or t1=="TK_NAME"or t1=="TK_OP"then
if t1=="TK_NAME"and option["opt-locals"]then
elseif s1~=s2 then
bork("seminfo ["..i.."] "..t1.." "..s1.." "..s2)
break
end
elseif t1=="TK_EOS"then
else
local s1b,s2b=dumpsem(s1),dumpsem(s2)
if not s1b or not s2b or s1b~=s2b then
bork("seminfo ["..i.."] "..t1.." "..s1.." "..s2)
break
end
end
end
end
function binary(z,dat)
local TNIL=0
local TBOOLEAN=1
local TNUMBER=3
local TSTRING=4
local function bork(msg)
if option.DETAILS then base.print("BINEQUIV: "..msg)end
warn.BIN_EQUIV=true
end
local function zap_shbang(s)
local shbang=match(s,"^(#[^\r\n]*\r?\n?)")
if shbang then
s=sub(s,#shbang+1)
end
return s
end
local cz=loadstring(zap_shbang(z),"z")
if not cz then
bork("failed to compile original sources for binary chunk comparison")
return
end
local cdat=loadstring(zap_shbang(dat),"z")
if not cdat then
bork("failed to compile compressed result for binary chunk comparison")
end
local c1={i=1,dat=dump(cz)}
c1.len=#c1.dat
local c2={i=1,dat=dump(cdat)}
c2.len=#c2.dat
local endian,
sz_int,sz_sizet,
sz_inst,sz_number,
getint,getsizet
local function ensure(c,sz)
if c.i+sz-1>c.len then return end
return true
end
local function skip(c,sz)
if not sz then sz=1 end
c.i=c.i+sz
end
local function getbyte(c)
local i=c.i
if i>c.len then return end
local d=sub(c.dat,i,i)
c.i=i+1
return byte(d)
end
local function getint_l(c)
local n,scale=0,1
if not ensure(c,sz_int)then return end
for j=1,sz_int do
n=n+scale*getbyte(c)
scale=scale*256
end
return n
end
local function getint_b(c)
local n=0
if not ensure(c,sz_int)then return end
for j=1,sz_int do
n=n*256+getbyte(c)
end
return n
end
local function getsizet_l(c)
local n,scale=0,1
if not ensure(c,sz_sizet)then return end
for j=1,sz_sizet do
n=n+scale*getbyte(c)
scale=scale*256
end
return n
end
local function getsizet_b(c)
local n=0
if not ensure(c,sz_sizet)then return end
for j=1,sz_sizet do
n=n*256+getbyte(c)
end
return n
end
local function getblock(c,sz)
local i=c.i
local j=i+sz-1
if j>c.len then return end
local d=sub(c.dat,i,j)
c.i=i+sz
return d
end
local function getstring(c)
local n=getsizet(c)
if not n then return end
if n==0 then return""end
return getblock(c,n)
end
local function goodbyte(c1,c2)
local b1,b2=getbyte(c1),getbyte(c2)
if not b1 or not b2 or b1~=b2 then
return
end
return b1
end
local function badbyte(c1,c2)
local b=goodbyte(c1,c2)
if not b then return true end
end
local function goodint(c1,c2)
local i1,i2=getint(c1),getint(c2)
if not i1 or not i2 or i1~=i2 then
return
end
return i1
end
local function getfunc(c1,c2)
if not getstring(c1)or not getstring(c2)then
bork("bad source name");return
end
if not getint(c1)or not getint(c2)then
bork("bad linedefined");return
end
if not getint(c1)or not getint(c2)then
bork("bad lastlinedefined");return
end
if not(ensure(c1,4)and ensure(c2,4))then
bork("prototype header broken")
end
if badbyte(c1,c2)then
bork("bad nups");return
end
if badbyte(c1,c2)then
bork("bad numparams");return
end
if badbyte(c1,c2)then
bork("bad is_vararg");return
end
if badbyte(c1,c2)then
bork("bad maxstacksize");return
end
local ncode=goodint(c1,c2)
if not ncode then
bork("bad ncode");return
end
local code1=getblock(c1,ncode*sz_inst)
local code2=getblock(c2,ncode*sz_inst)
if not code1 or not code2 or code1~=code2 then
bork("bad code block");return
end
local nconst=goodint(c1,c2)
if not nconst then
bork("bad nconst");return
end
for i=1,nconst do
local ctype=goodbyte(c1,c2)
if not ctype then
bork("bad const type");return
end
if ctype==TBOOLEAN then
if badbyte(c1,c2)then
bork("bad boolean value");return
end
elseif ctype==TNUMBER then
local num1=getblock(c1,sz_number)
local num2=getblock(c2,sz_number)
if not num1 or not num2 or num1~=num2 then
bork("bad number value");return
end
elseif ctype==TSTRING then
local str1=getstring(c1)
local str2=getstring(c2)
if not str1 or not str2 or str1~=str2 then
bork("bad string value");return
end
end
end
local nproto=goodint(c1,c2)
if not nproto then
bork("bad nproto");return
end
for i=1,nproto do
if not getfunc(c1,c2)then
bork("bad function prototype");return
end
end
local sizelineinfo1=getint(c1)
if not sizelineinfo1 then
bork("bad sizelineinfo1");return
end
local sizelineinfo2=getint(c2)
if not sizelineinfo2 then
bork("bad sizelineinfo2");return
end
if not getblock(c1,sizelineinfo1*sz_int)then
bork("bad lineinfo1");return
end
if not getblock(c2,sizelineinfo2*sz_int)then
bork("bad lineinfo2");return
end
local sizelocvars1=getint(c1)
if not sizelocvars1 then
bork("bad sizelocvars1");return
end
local sizelocvars2=getint(c2)
if not sizelocvars2 then
bork("bad sizelocvars2");return
end
for i=1,sizelocvars1 do
if not getstring(c1)or not getint(c1)or not getint(c1)then
bork("bad locvars1");return
end
end
for i=1,sizelocvars2 do
if not getstring(c2)or not getint(c2)or not getint(c2)then
bork("bad locvars2");return
end
end
local sizeupvalues1=getint(c1)
if not sizeupvalues1 then
bork("bad sizeupvalues1");return
end
local sizeupvalues2=getint(c2)
if not sizeupvalues2 then
bork("bad sizeupvalues2");return
end
for i=1,sizeupvalues1 do
if not getstring(c1)then bork("bad upvalues1");return end
end
for i=1,sizeupvalues2 do
if not getstring(c2)then bork("bad upvalues2");return end
end
return true
end
if not(ensure(c1,12)and ensure(c2,12))then
bork("header broken")
end
skip(c1,6)
endian=getbyte(c1)
sz_int=getbyte(c1)
sz_sizet=getbyte(c1)
sz_inst=getbyte(c1)
sz_number=getbyte(c1)
skip(c1)
skip(c2,12)
if endian==1 then
getint=getint_l
getsizet=getsizet_l
else
getint=getint_b
getsizet=getsizet_b
end
getfunc(c1,c2)
if c1.i~=c1.len+1 then
bork("inconsistent binary chunk1");return
elseif c2.i~=c2.len+1 then
bork("inconsistent binary chunk2");return
end
end
end
preload["plugin/html"]=
function()
module"plugin/html"
local string=base.require"string"
local table=base.require"table"
local io=base.require"io"
local HTML_EXT=".html"
local ENTITIES={
["&"]="&amp;",["<"]="&lt;",[">"]="&gt;",
["'"]="&apos;",["\""]="&quot;",
}
local HEADER=[[
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<html>
<head>
<title>%s</title>
<meta name="Generator" content="LuaSrcDiet">
<style type="text/css">
%s</style>
</head>
<body>
<pre class="code">
]]
local FOOTER=[[
</pre>
</body>
</html>
]]
local STYLESHEET=[[
BODY {
    background: white;
    color: navy;
}
pre.code { color: black; }
span.comment { color: #00a000; }
span.string  { color: #009090; }
span.keyword { color: black; font-weight: bold; }
span.number { color: #993399; }
span.operator { }
span.name { }
span.global { color: #ff0000; font-weight: bold; }
span.local { color: #0000ff; font-weight: bold; }
]]
local option
local srcfl,destfl
local toklist,seminfolist,toklnlist
local function print(...)
if option.QUIET then return end
base.print(...)
end
function init(_option,_srcfl,_destfl)
option=_option
srcfl=_srcfl
local extb,exte=string.find(srcfl,"%.[^%.%\\%/]*$")
local basename,extension=srcfl,""
if extb and extb>1 then
basename=string.sub(srcfl,1,extb-1)
extension=string.sub(srcfl,extb,exte)
end
destfl=basename..HTML_EXT
if option.OUTPUT_FILE then
destfl=option.OUTPUT_FILE
end
if srcfl==destfl then
base.error("output filename identical to input filename")
end
end
function post_load(z)
print([[
HTML plugin module for LuaSrcDiet
]])
print("Exporting: "..srcfl.." -> "..destfl.."\n")
end
function post_lex(_toklist,_seminfolist,_toklnlist)
toklist,seminfolist,toklnlist
=_toklist,_seminfolist,_toklnlist
end
local function do_entities(z)
local i=1
while i<=#z do
local c=string.sub(z,i,i)
local d=ENTITIES[c]
if d then
c=d
z=string.sub(z,1,i-1)..c..string.sub(z,i+1)
end
i=i+#c
end
return z
end
local function save_file(fname,dat)
local OUTF=io.open(fname,"wb")
if not OUTF then base.error("cannot open \""..fname.."\" for writing")end
local status=OUTF:write(dat)
if not status then base.error("cannot write to \""..fname.."\"")end
OUTF:close()
end
function post_parse(globalinfo,localinfo)
local html={}
local function add(s)
html[#html+1]=s
end
local function span(class,s)
add('<span class="'..class..'">'..s..'</span>')
end
for i=1,#globalinfo do
local obj=globalinfo[i]
local xref=obj.xref
for j=1,#xref do
local p=xref[j]
toklist[p]="TK_GLOBAL"
end
end
for i=1,#localinfo do
local obj=localinfo[i]
local xref=obj.xref
for j=1,#xref do
local p=xref[j]
toklist[p]="TK_LOCAL"
end
end
add(string.format(HEADER,
do_entities(srcfl),
STYLESHEET))
for i=1,#toklist do
local tok,info=toklist[i],seminfolist[i]
if tok=="TK_KEYWORD"then
span("keyword",info)
elseif tok=="TK_STRING"or tok=="TK_LSTRING"then
span("string",do_entities(info))
elseif tok=="TK_COMMENT"or tok=="TK_LCOMMENT"then
span("comment",do_entities(info))
elseif tok=="TK_GLOBAL"then
span("global",info)
elseif tok=="TK_LOCAL"then
span("local",info)
elseif tok=="TK_NAME"then
span("name",info)
elseif tok=="TK_NUMBER"then
span("number",info)
elseif tok=="TK_OP"then
span("operator",do_entities(info))
elseif tok~="TK_EOS"then
add(info)
end
end
add(FOOTER)
save_file(destfl,table.concat(html))
option.EXIT=true
end
end
preload["plugin/sloc"]=
function()
module"plugin/sloc"
local string=base.require"string"
local table=base.require"table"
local option
local srcfl
function init(_option,_srcfl,_destfl)
option=_option
option.QUIET=true
srcfl=_srcfl
end
local function split(blk)
local lines={}
local i,nblk=1,#blk
while i<=nblk do
local p,q,r,s=string.find(blk,"([\r\n])([\r\n]?)",i)
if not p then
p=nblk+1
end
lines[#lines+1]=string.sub(blk,i,p-1)
i=p+1
if p<nblk and q>p and r~=s then
i=i+1
end
end
return lines
end
function post_lex(toklist,seminfolist,toklnlist)
local lnow,sloc=0,0
local function chk(ln)
if ln>lnow then
sloc=sloc+1;lnow=ln
end
end
for i=1,#toklist do
local tok,info,ln
=toklist[i],seminfolist[i],toklnlist[i]
if tok=="TK_KEYWORD"or tok=="TK_NAME"or
tok=="TK_NUMBER"or tok=="TK_OP"then
chk(ln)
elseif tok=="TK_STRING"then
local t=split(info)
ln=ln-#t+1
for j=1,#t do
chk(ln);ln=ln+1
end
elseif tok=="TK_LSTRING"then
local t=split(info)
ln=ln-#t+1
for j=1,#t do
if t[j]~=""then chk(ln)end
ln=ln+1
end
end
end
base.print(srcfl..": "..sloc)
option.EXIT=true
end
end
local llex=require"llex"
local lparser=require"lparser"
local optlex=require"optlex"
local optparser=require"optparser"
local equiv=require"equiv"
local plugin
local MSG_TITLE=[[
LuaSrcDiet: Puts your Lua 5.1 source code on a diet
Version 0.12.1 (20120407)  Copyright (c) 2012 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed.
]]
local MSG_USAGE=[[
usage: LuaSrcDiet [options] [filenames]

example:
  >LuaSrcDiet myscript.lua -o myscript_.lua

options:
  -v, --version       prints version information
  -h, --help          prints usage information
  -o <file>           specify file name to write output
  -s <suffix>         suffix for output files (default '_')
  --keep <msg>        keep block comment with <msg> inside
  --plugin <module>   run <module> in plugin/ directory
  -                   stop handling arguments

  (optimization levels)
  --none              all optimizations off (normalizes EOLs only)
  --basic             lexer-based optimizations only
  --maximum           maximize reduction of source

  (informational)
  --quiet             process files quietly
  --read-only         read file and print token stats only
  --dump-lexer        dump raw tokens from lexer to stdout
  --dump-parser       dump variable tracking tables from parser
  --details           extra info (strings, numbers, locals)

features (to disable, insert 'no' prefix like --noopt-comments):
%s
default settings:
%s]]
local OPTION=[[
--opt-comments,'remove comments and block comments'
--opt-whitespace,'remove whitespace excluding EOLs'
--opt-emptylines,'remove empty lines'
--opt-eols,'all above, plus remove unnecessary EOLs'
--opt-strings,'optimize strings and long strings'
--opt-numbers,'optimize numbers'
--opt-locals,'optimize local variable names'
--opt-entropy,'tries to reduce symbol entropy of locals'
--opt-srcequiv,'insist on source (lexer stream) equivalence'
--opt-binequiv,'insist on binary chunk equivalence'
--opt-experimental,'apply experimental optimizations'
]]
local DEFAULT_CONFIG=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-numbers --opt-locals
  --opt-srcequiv --opt-binequiv
]]
local BASIC_CONFIG=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]
local MAXIMUM_CONFIG=[[
  --opt-comments --opt-whitespace --opt-emptylines
  --opt-eols --opt-strings --opt-numbers
  --opt-locals --opt-entropy
  --opt-srcequiv --opt-binequiv
]]
local NONE_CONFIG=[[
  --noopt-comments --noopt-whitespace --noopt-emptylines
  --noopt-eols --noopt-strings --noopt-numbers
  --noopt-locals --noopt-entropy
  --opt-srcequiv --opt-binequiv
]]
local DEFAULT_SUFFIX="_"
local PLUGIN_SUFFIX="plugin/"
local function die(msg)
print("LuaSrcDiet (error): "..msg);os.exit(1)
end
if not match(_VERSION,"5.1",1,1)then
die("requires Lua 5.1 to run")
end
local MSG_OPTIONS=""
do
local WIDTH=24
local o={}
for op,desc in gmatch(OPTION,"%s*([^,]+),'([^']+)'")do
local msg="  "..op
msg=msg..string.rep(" ",WIDTH-#msg)..desc.."\n"
MSG_OPTIONS=MSG_OPTIONS..msg
o[op]=true
o["--no"..sub(op,3)]=true
end
OPTION=o
end
MSG_USAGE=string.format(MSG_USAGE,MSG_OPTIONS,DEFAULT_CONFIG)
if p_embedded then
local EMBED_INFO="\nembedded plugins:\n"
for i=1,#p_embedded do
local p=p_embedded[i]
EMBED_INFO=EMBED_INFO.."  "..plugin_info[p].."\n"
end
MSG_USAGE=MSG_USAGE..EMBED_INFO
end
local suffix=DEFAULT_SUFFIX
local option={}
local stat_c,stat_l
local function set_options(CONFIG)
for op in gmatch(CONFIG,"(%-%-%S+)")do
if sub(op,3,4)=="no"and
OPTION["--"..sub(op,5)]then
option[sub(op,5)]=false
else
option[sub(op,3)]=true
end
end
end
local TTYPES={
"TK_KEYWORD","TK_NAME","TK_NUMBER",
"TK_STRING","TK_LSTRING","TK_OP",
"TK_EOS",
"TK_COMMENT","TK_LCOMMENT",
"TK_EOL","TK_SPACE",
}
local TTYPE_GRAMMAR=7
local EOLTYPES={
["\n"]="LF",["\r"]="CR",
["\n\r"]="LFCR",["\r\n"]="CRLF",
}
local function load_file(fname)
local INF=io.open(fname,"rb")
if not INF then die('cannot open "'..fname..'" for reading')end
local dat=INF:read("*a")
if not dat then die('cannot read from "'..fname..'"')end
INF:close()
return dat
end
local function save_file(fname,dat)
local OUTF=io.open(fname,"wb")
if not OUTF then die('cannot open "'..fname..'" for writing')end
local status=OUTF:write(dat)
if not status then die('cannot write to "'..fname..'"')end
OUTF:close()
end
local function stat_init()
stat_c,stat_l={},{}
for i=1,#TTYPES do
local ttype=TTYPES[i]
stat_c[ttype],stat_l[ttype]=0,0
end
end
local function stat_add(tok,seminfo)
stat_c[tok]=stat_c[tok]+1
stat_l[tok]=stat_l[tok]+#seminfo
end
local function stat_calc()
local function avg(c,l)
if c==0 then return 0 end
return l/c
end
local stat_a={}
local c,l=0,0
for i=1,TTYPE_GRAMMAR do
local ttype=TTYPES[i]
c=c+stat_c[ttype];l=l+stat_l[ttype]
end
stat_c.TOTAL_TOK,stat_l.TOTAL_TOK=c,l
stat_a.TOTAL_TOK=avg(c,l)
c,l=0,0
for i=1,#TTYPES do
local ttype=TTYPES[i]
c=c+stat_c[ttype];l=l+stat_l[ttype]
stat_a[ttype]=avg(stat_c[ttype],stat_l[ttype])
end
stat_c.TOTAL_ALL,stat_l.TOTAL_ALL=c,l
stat_a.TOTAL_ALL=avg(c,l)
return stat_a
end
local function dump_tokens(srcfl)
local z=load_file(srcfl)
llex.init(z)
llex.llex()
local toklist,seminfolist=llex.tok,llex.seminfo
for i=1,#toklist do
local tok,seminfo=toklist[i],seminfolist[i]
if tok=="TK_OP"and string.byte(seminfo)<32 then
seminfo="("..string.byte(seminfo)..")"
elseif tok=="TK_EOL"then
seminfo=EOLTYPES[seminfo]
else
seminfo="'"..seminfo.."'"
end
print(tok.." "..seminfo)
end
end
local function dump_parser(srcfl)
local print=print
local z=load_file(srcfl)
llex.init(z)
llex.llex()
local toklist,seminfolist,toklnlist
=llex.tok,llex.seminfo,llex.tokln
lparser.init(toklist,seminfolist,toklnlist)
local xinfo=lparser.parser()
local globalinfo,localinfo=
xinfo.globalinfo,xinfo.localinfo
local hl=string.rep("-",72)
print("*** Local/Global Variable Tracker Tables ***")
print(hl.."\n GLOBALS\n"..hl)
for i=1,#globalinfo do
local obj=globalinfo[i]
local msg="("..i..") '"..obj.name.."' -> "
local xref=obj.xref
for j=1,#xref do msg=msg..xref[j].." "end
print(msg)
end
print(hl.."\n LOCALS (decl=declared act=activated rem=removed)\n"..hl)
for i=1,#localinfo do
local obj=localinfo[i]
local msg="("..i..") '"..obj.name.."' decl:"..obj.decl..
" act:"..obj.act.." rem:"..obj.rem
if obj.isself then
msg=msg.." isself"
end
msg=msg.." -> "
local xref=obj.xref
for j=1,#xref do msg=msg..xref[j].." "end
print(msg)
end
print(hl.."\n")
end
local function read_only(srcfl)
local print=print
local z=load_file(srcfl)
llex.init(z)
llex.llex()
local toklist,seminfolist=llex.tok,llex.seminfo
print(MSG_TITLE)
print("Statistics for: "..srcfl.."\n")
stat_init()
for i=1,#toklist do
local tok,seminfo=toklist[i],seminfolist[i]
stat_add(tok,seminfo)
end
local stat_a=stat_calc()
local fmt=string.format
local function figures(tt)
return stat_c[tt],stat_l[tt],stat_a[tt]
end
local tabf1,tabf2="%-16s%8s%8s%10s","%-16s%8d%8d%10.2f"
local hl=string.rep("-",42)
print(fmt(tabf1,"Lexical","Input","Input","Input"))
print(fmt(tabf1,"Elements","Count","Bytes","Average"))
print(hl)
for i=1,#TTYPES do
local ttype=TTYPES[i]
print(fmt(tabf2,ttype,figures(ttype)))
if ttype=="TK_EOS"then print(hl)end
end
print(hl)
print(fmt(tabf2,"Total Elements",figures("TOTAL_ALL")))
print(hl)
print(fmt(tabf2,"Total Tokens",figures("TOTAL_TOK")))
print(hl.."\n")
end
local function process_file(srcfl,destfl)
local function print(...)
if option.QUIET then return end
_G.print(...)
end
if plugin and plugin.init then
option.EXIT=false
plugin.init(option,srcfl,destfl)
if option.EXIT then return end
end
print(MSG_TITLE)
local z=load_file(srcfl)
if plugin and plugin.post_load then
z=plugin.post_load(z)or z
if option.EXIT then return end
end
llex.init(z)
llex.llex()
local toklist,seminfolist,toklnlist
=llex.tok,llex.seminfo,llex.tokln
if plugin and plugin.post_lex then
plugin.post_lex(toklist,seminfolist,toklnlist)
if option.EXIT then return end
end
stat_init()
for i=1,#toklist do
local tok,seminfo=toklist[i],seminfolist[i]
stat_add(tok,seminfo)
end
local stat1_a=stat_calc()
local stat1_c,stat1_l=stat_c,stat_l
optparser.print=print
lparser.init(toklist,seminfolist,toklnlist)
local xinfo=lparser.parser()
if plugin and plugin.post_parse then
plugin.post_parse(xinfo.globalinfo,xinfo.localinfo)
if option.EXIT then return end
end
optparser.optimize(option,toklist,seminfolist,xinfo)
if plugin and plugin.post_optparse then
plugin.post_optparse()
if option.EXIT then return end
end
local warn=optlex.warn
optlex.print=print
toklist,seminfolist,toklnlist
=optlex.optimize(option,toklist,seminfolist,toklnlist)
if plugin and plugin.post_optlex then
plugin.post_optlex(toklist,seminfolist,toklnlist)
if option.EXIT then return end
end
local dat=table.concat(seminfolist)
if string.find(dat,"\r\n",1,1)or
string.find(dat,"\n\r",1,1)then
warn.MIXEDEOL=true
end
equiv.init(option,llex,warn)
equiv.source(z,dat)
equiv.binary(z,dat)
local smsg="before and after lexer streams are NOT equivalent!"
local bmsg="before and after binary chunks are NOT equivalent!"
if warn.SRC_EQUIV then
if option["opt-srcequiv"]then die(smsg)end
else
print("*** SRCEQUIV: token streams are sort of equivalent")
if option["opt-locals"]then
print("(but no identifier comparisons since --opt-locals enabled)")
end
print()
end
if warn.BIN_EQUIV then
if option["opt-binequiv"]then die(bmsg)end
else
print("*** BINEQUIV: binary chunks are sort of equivalent")
print()
end
save_file(destfl,dat)
stat_init()
for i=1,#toklist do
local tok,seminfo=toklist[i],seminfolist[i]
stat_add(tok,seminfo)
end
local stat_a=stat_calc()
print("Statistics for: "..srcfl.." -> "..destfl.."\n")
local fmt=string.format
local function figures(tt)
return stat1_c[tt],stat1_l[tt],stat1_a[tt],
stat_c[tt],stat_l[tt],stat_a[tt]
end
local tabf1,tabf2="%-16s%8s%8s%10s%8s%8s%10s",
"%-16s%8d%8d%10.2f%8d%8d%10.2f"
local hl=string.rep("-",68)
print("*** lexer-based optimizations summary ***\n"..hl)
print(fmt(tabf1,"Lexical",
"Input","Input","Input",
"Output","Output","Output"))
print(fmt(tabf1,"Elements",
"Count","Bytes","Average",
"Count","Bytes","Average"))
print(hl)
for i=1,#TTYPES do
local ttype=TTYPES[i]
print(fmt(tabf2,ttype,figures(ttype)))
if ttype=="TK_EOS"then print(hl)end
end
print(hl)
print(fmt(tabf2,"Total Elements",figures("TOTAL_ALL")))
print(hl)
print(fmt(tabf2,"Total Tokens",figures("TOTAL_TOK")))
print(hl)
if warn.LSTRING then
print("* WARNING: "..warn.LSTRING)
elseif warn.MIXEDEOL then
print("* WARNING: ".."output still contains some CRLF or LFCR line endings")
elseif warn.SRC_EQUIV then
print("* WARNING: "..smsg)
elseif warn.BIN_EQUIV then
print("* WARNING: "..bmsg)
end
print()
end
local arg={...}
local fspec={}
set_options(DEFAULT_CONFIG)
local function do_files(fspec)
for i=1,#fspec do
local srcfl=fspec[i]
local destfl
local extb,exte=string.find(srcfl,"%.[^%.%\\%/]*$")
local basename,extension=srcfl,""
if extb and extb>1 then
basename=sub(srcfl,1,extb-1)
extension=sub(srcfl,extb,exte)
end
destfl=basename..suffix..extension
if#fspec==1 and option.OUTPUT_FILE then
destfl=option.OUTPUT_FILE
end
if srcfl==destfl then
die("output filename identical to input filename")
end
if option.DUMP_LEXER then
dump_tokens(srcfl)
elseif option.DUMP_PARSER then
dump_parser(srcfl)
elseif option.READ_ONLY then
read_only(srcfl)
else
process_file(srcfl,destfl)
end
end
end
local function main()
local argn,i=#arg,1
if argn==0 then
option.HELP=true
end
while i<=argn do
local o,p=arg[i],arg[i+1]
local dash=match(o,"^%-%-?")
if dash=="-"then
if o=="-h"then
option.HELP=true;break
elseif o=="-v"then
option.VERSION=true;break
elseif o=="-s"then
if not p then die("-s option needs suffix specification")end
suffix=p
i=i+1
elseif o=="-o"then
if not p then die("-o option needs a file name")end
option.OUTPUT_FILE=p
i=i+1
elseif o=="-"then
break
else
die("unrecognized option "..o)
end
elseif dash=="--"then
if o=="--help"then
option.HELP=true;break
elseif o=="--version"then
option.VERSION=true;break
elseif o=="--keep"then
if not p then die("--keep option needs a string to match for")end
option.KEEP=p
i=i+1
elseif o=="--plugin"then
if not p then die("--plugin option needs a module name")end
if option.PLUGIN then die("only one plugin can be specified")end
option.PLUGIN=p
plugin=require(PLUGIN_SUFFIX..p)
i=i+1
elseif o=="--quiet"then
option.QUIET=true
elseif o=="--read-only"then
option.READ_ONLY=true
elseif o=="--basic"then
set_options(BASIC_CONFIG)
elseif o=="--maximum"then
set_options(MAXIMUM_CONFIG)
elseif o=="--none"then
set_options(NONE_CONFIG)
elseif o=="--dump-lexer"then
option.DUMP_LEXER=true
elseif o=="--dump-parser"then
option.DUMP_PARSER=true
elseif o=="--details"then
option.DETAILS=true
elseif OPTION[o]then
set_options(o)
else
die("unrecognized option "..o)
end
else
fspec[#fspec+1]=o
end
i=i+1
end
if option.HELP then
print(MSG_TITLE..MSG_USAGE);return true
elseif option.VERSION then
print(MSG_TITLE);return true
end
if#fspec>0 then
if#fspec>1 and option.OUTPUT_FILE then
die("with -o, only one source file can be specified")
end
do_files(fspec)
return true
else
die("nothing to do!")
end
end
if not main()then
die("Please run with option -h or --help for usage information")
end
