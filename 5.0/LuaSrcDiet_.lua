#!/usr/bin/env lua
title=[[
LuaSrcDiet: Puts your Lua 5 source code on a diet
Version 0.9.1 (20050816)  Copyright (c) 2005 Kein-Hong Man
The COPYRIGHT file describes the conditions under which this
software may be distributed (basically a Lua 5-style license.)
]]
USAGE=[[
usage: %s [options] [filenames]

options:
  -h, --help        prints usage information
  -o <file>         specify file name to write output
  --quiet           do not display statistics
  --read-only       read file and print token stats
  --keep-lines      preserve line numbering
  --maximum         maximize reduction of source
  --dump            dump raw tokens from lexer
  --                stop handling arguments

example:
  >%s myscript.lua -o myscript_.lua
]]
local usage,exec
if arg[0]then exec="lua LuaSrcDiet.lua"else exec="LuaSrcDiet"end
usage=string.format(USAGE,exec,exec)
config={}
config.SUFFIX="_"
llex={}
llex.EOZ=-1
llex.keywords=
"and break do else elseif end false for function if in local \
nil not or repeat return then true until while "
llex.str2tok={}
for v in string.gfind(llex.keywords,"[^%s]+")do
llex.str2tok[v]=true
end
function llex:checklimit(val,limit,msg)
if val>limit then
msg=string.format("too many %s (limit=%d)",msg,limit)
error(string.format("%s:%d: %s",self.source,self.line,msg))
end
end
function llex:error(s,token)
error(string.format("%s:%d: %s near '%s'",self.source,self.line,s,token))
end
function llex:lexerror(s,token)
if token then self:error(s,token)else self:error(s,self.buff)end
end
function llex:nextc()
if self.ipos>self.ilen then
if self.z then
self.ibuf=self.z:read("*l")
if self.ibuf==nil then
self.z:close()
self.c=self.EOZ;self.ch=""
self.z=nil
return
else
self.ibuf=self.ibuf.."\n"
self.ipos=1
self.ilen=string.len(self.ibuf)
end
else
self.c=self.EOZ;self.ch=""
return
end
end
self.c=string.byte(self.ibuf,self.ipos)
self.ch=string.char(self.c)
self.ipos=self.ipos+1
end
function llex:initbuff()
self.buff=""
self.obuff=""
end
function llex:save(c)
self.buff=self.buff..c
end
function llex:osave(c)
self.obuff=self.obuff..c
end
function llex:save_and_next()
self:save(self.ch)
self:osave(self.ch)
self:nextc()
end
function llex:inclinenumber()
self:nextc()
self.line=self.line+1
self:checklimit(self.line,2147483645,"lines in a chunk")
end
function llex:setinput(z,source)
if z then
self.ilen=0
self.z=z
end
self.ipos=1
self.line=1
self.lastline=1
self.source=source
if not self.source then
self.source="main"
end
self:nextc()
end
function llex:setstring(chunk,source)
self.ibuf=chunk
self.ilen=string.len(self.ibuf)
self:setinput(nil,source)
end
function llex:readloop(pat)
while string.find(self.ch,pat)do
self:save_and_next()
end
end
function llex:readtoeol()
while self.ch~='\n'and self.c~=self.EOZ do
self:save_and_next()
end
end
function llex:read_numeral(comma)
self:initbuff()
if comma then
self.buff='.';self.obuff='.'
end
self:readloop("%d")
if self.ch=='.'then
self:save_and_next()
if self.ch=='.'then
self:save_and_next()
self:lexerror("ambiguous syntax (decimal point x string concatenation)")
end
end
self:readloop("%d")
if self.ch=='e'or self.ch=='E'then
self:save_and_next()
if self.ch=='+'or self.ch=='-'then
self:save_and_next()
end
self:readloop("%d")
end
local value=tonumber(self.buff)
if not value then
self:lexerror("malformed number")
end
return self.obuff,value
end
function llex:read_long_string(comment)
local cont=0
local eols=0
if comment then
self.buff="--["
else
self.buff="["
end
self.obuff=self.buff
self:save_and_next()
if self.ch=='\n'then
eols=eols+1
self:osave('\n')
self:inclinenumber()
end
while true do
if self.c==self.EOZ then
if comment then
self:lexerror("unfinished long comment","<eof>")
else
self:lexerror("unfinished long string","<eof>")
end
elseif self.ch=='['then
self:save_and_next()
if self.ch=='['then
cont=cont+1
self:save_and_next()
end
elseif self.ch==']'then
self:save_and_next()
if self.ch==']'then
if cont==0then break end
cont=cont-1
self:save_and_next()
end
elseif self.ch=='\n'then
self:save('\n')
eols=eols+1
self:osave('\n')
self:inclinenumber()
else
self:save_and_next()
end
end
self:save_and_next()
if comment then
return self.obuff,eols
end
return self.obuff,string.sub(self.buff,3,-3)
end
function llex:read_string(del)
self:initbuff()
self:save_and_next()
while self.ch~=del do
if self.c==self.EOZ then
self:lexerror("unfinished string","<eof>")
elseif self.ch=='\n'then
self:lexerror("unfinished string")
elseif self.ch=='\\'then
self:osave('\\')
self:nextc()
if self.c~=self.EOZ then
local i=string.find("\nabfnrtv",self.ch,1,1)
if i then
self:save(string.sub("\n\a\b\f\n\r\t\v",i,i))
self:osave(self.ch)
if i==1then
self:inclinenumber()
else
self:nextc()
end
elseif string.find(self.ch,"%d")==nil then
self:save_and_next()
else
local c=0
i=0
repeat
c=10*c+self.ch
self:osave(self.ch)
self:nextc()
i=i+1
until(i>=3or not string.find(self.ch,"%d"))
if c>255then
self:lexerror("escape sequence too large")
end
self:save(string.char(c))
end
end
else
self:save_and_next()
end
end
self:save_and_next()
return self.obuff,string.sub(self.buff,2,-2)
end
function llex:lex()
local strfind=string.find
while true do
local c=self.c
if self.line==1and self.ipos==2
and self.ch=='#'then
self:initbuff()
self:readtoeol()
return"TK_COMMENT",self.obuff
end
if self.ch=='\n'then
self:inclinenumber()
return"TK_EOL",'\n'
elseif self.ch=='-'then
self:nextc()
if self.ch~='-'then
return"TK_OP",'-'
end
self:nextc()
if self.ch=='['then
self:nextc()
if self.ch=='['then
return"TK_LCOMMENT",self:read_long_string(1)
else
self.buff=""
self.obuff="--["
self:readtoeol()
return"TK_COMMENT",self.obuff
end
else
self.buff=""
self.obuff="--"
self:readtoeol()
return"TK_COMMENT",self.obuff
end
elseif self.ch=='['then
self:nextc()
if self.ch~='['then
return"TK_OP",'['
else
return"TK_STRING",self:read_long_string()
end
elseif self.ch=="\""or self.ch=="\'"then
return"TK_STRING",self:read_string(self.ch)
elseif self.ch=='.'then
self:nextc()
if self.ch=='.'then
self:nextc()
if self.ch=='.'then
self:nextc()
return"TK_OP",'...'
else
return"TK_OP",'..'
end
elseif strfind(self.ch,"%d")==nil then
return"TK_OP",'.'
else
return"TK_NUMBER",self:read_numeral(1)
end
elseif self.c==self.EOZ then
return"TK_EOS",''
else
local op=strfind("=><~",self.ch,1,1)
local c=self.ch
if op then
self:nextc()
if self.ch~='='then
return"TK_OP",c
else
self:nextc()
return"TK_OP",c..'='
end
else
if strfind(self.ch,"%s")then
self:initbuff()
self:readloop("%s")
return"TK_SPACE",self.obuff
elseif strfind(self.ch,"%d")then
return"TK_NUMBER",self:read_numeral()
elseif strfind(self.ch,"[%a_]")then
self:initbuff()
self:readloop("[%w_]")
if self.str2tok[self.buff]then
return"TK_KEYWORD",self.buff
end
return"TK_NAME",self.buff
else
if strfind(self.ch,"%c")then
self:error("invalid control char",string.format("char(%d)",self.c))
end
self:nextc()
return"TK_OP",c
end
end
end
end
end
function llex:olex()
local _ltok,_lorig,_lval
while true do
_ltok,_lorig,_lval=self:lex()
if _ltok~="TK_COMMENT"and _ltok~="TK_LCOMMENT"
and _ltok~="TK_EOL"and _ltok~="TK_SPACE"then
return _ltok,_lorig,_lval
end
end
end
stats_c=nil
stats_l=nil
ltok=nil
lorig=nil
lval=nil
ntokens=0
ttypes={
"TK_KEYWORD","TK_NAME","TK_NUMBER","TK_STRING","TK_OP",
"TK_EOS","TK_COMMENT","TK_LCOMMENT","TK_EOL","TK_SPACE",
}
function LoadFile(filename)
if not filename and type(filename)~="string"then
error("invalid filename specified")
end
stats_c={}
stats_l={}
ltok={}
lorig={}
lval={}
ntokens=0
for _,i in ipairs(ttypes)do
stats_c[i]=0;stats_l[i]=0
end
local INF=io.open(filename,"rb")
if not INF then
error("cannot open \""..filename.."\" for reading")
end
llex:setinput(INF,filename)
local _ltok,_lorig,_lval
local i=0
while _ltok~="TK_EOS"do
_ltok,_lorig,_lval=llex:lex()
i=i+1
ltok[i]=_ltok
lorig[i]=_lorig
lval[i]=_lval
stats_c[_ltok]=stats_c[_ltok]+1
stats_l[_ltok]=stats_l[_ltok]+string.len(_lorig)
end
ntokens=i
end
function GetRealTokens(stok,sorig,stokens)
local rtok,rorig,rtokens={},{},0
for i=1,stokens do
local _stok=stok[i]
local _sorig=sorig[i]
if _stok~="TK_COMMENT"and _stok~="TK_LCOMMENT"
and _stok~="TK_EOL"and _stok~="TK_SPACE"then
rtokens=rtokens+1
rtok[rtokens]=_stok
rorig[rtokens]=_sorig
end
end
return rtok,rorig,rtokens
end
function DispSrcStats(filename)
local underline="--------------------------------\n"
LoadFile(filename)
print(title)
io.stdout:write("Statistics for: "..filename.."\n\n"
..string.format("%-14s%8s%10s\n","Elements","Count","Bytes")
..underline)
local total_c,total_l,tok_c,tok_l=0,0,0,0
for j=1,10do
local i=ttypes[j]
local c,l=stats_c[i],stats_l[i]
total_c=total_c+c
total_l=total_l+l
if j<=6then
tok_c=tok_c+c
tok_l=tok_l+l
end
io.stdout:write(string.format("%-14s%8d%10d\n",i,c,l))
if i=="TK_EOS"then io.stdout:write(underline)end
end
io.stdout:write(underline
..string.format("%-14s%8d%10d\n","Total Elements",total_c,total_l)
..underline
..string.format("%-14s%8d%10d\n","Total Tokens",tok_c,tok_l)
..underline.."\n")
end
function DispAllStats(srcfile,src_c,src_l,destfile,dest_c,dest_l)
local underline="--------------------------------------------------\n"
print(title)
local stot_c,stot_l,stok_c,stok_l=0,0,0,0
local dtot_c,dtot_l,dtok_c,dtok_l=0,0,0,0
io.stdout:write("Statistics for: "..srcfile.." -> "..destfile.."\n\n"
..string.format("%-14s%8s%10s%8s%10s\n","Lexical","Input","Input","Output","Output")
..string.format("%-14s%8s%10s%8s%10s\n","Elements","Count","Bytes","Count","Bytes")
..underline)
for j=1,10do
local i=ttypes[j]
local s_c,s_l=src_c[i],src_l[i]
local d_c,d_l=dest_c[i],dest_l[i]
stot_c=stot_c+s_c
stot_l=stot_l+s_l
dtot_c=dtot_c+d_c
dtot_l=dtot_l+d_l
if j<=6then
stok_c=stok_c+s_c
stok_l=stok_l+s_l
dtok_c=dtok_c+d_c
dtok_l=dtok_l+d_l
end
io.stdout:write(string.format("%-14s%8d%10d%8d%10d\n",i,s_c,s_l,d_c,d_l))
if i=="TK_EOS"then io.stdout:write(underline)end
end
io.stdout:write(underline
..string.format("%-14s%8d%10d%8d%10d\n","Total Elements",stot_c,stot_l,dtot_c,dtot_l)
..underline
..string.format("%-14s%8d%10d%8d%10d\n","Total Tokens",stok_c,stok_l,dtok_c,dtok_l)
..underline.."\n")
end
function ProcessToken(srcfile,destfile)
LoadFile(srcfile)
if ntokens<1then
error("no tokens to process")
end
local dtok={}
local dorig={}
local dtokens=0
local stok,sorig,stokens=
GetRealTokens(ltok,lorig,ntokens)
local function savetok(src)
dtokens=dtokens+1
dtok[dtokens]=ltok[src]
dorig[dtokens]=lorig[src]
end
local function iswhitespace(i)
local tok=ltok[i]
if tok=="TK_SPACE"or tok=="TK_EOL"
or tok=="TK_COMMENT"or tok=="TK_LCOMMENT"then
return true
end
end
local function whitesp(previ,nexti)
local p=ltok[previ]
local n=ltok[nexti]
if iswhitespace(n)then return""end
if p=="TK_OP"then
if n=="TK_NUMBER"then
if string.sub(lorig[nexti],1,1)=="."then return" "end
end
return""
elseif p=="TK_KEYWORD"or p=="TK_NAME"then
if n=="TK_KEYWORD"or n=="TK_NAME"then
return" "
elseif n=="TK_NUMBER"then
if string.sub(lorig[nexti],1,1)=="."then return""end
return" "
end
return""
elseif p=="TK_STRING"then
return""
elseif p=="TK_NUMBER"then
if n=="TK_NUMBER"then
return" "
elseif n=="TK_KEYWORD"or n=="TK_NAME"then
local c=string.sub(lorig[nexti],1,1)
if string.lower(c)=="e"then return" "end
end
return""
else
error("token comparison failed")
end
end
local i=1
local linestart=true
local tok=""
local prev=0
while true do
tok=ltok[i]
if tok=="TK_SPACE"then
if linestart then
lorig[i]=""
else
lorig[i]=whitesp(prev,i+1)
end
savetok(i)
elseif tok=="TK_NAME"or tok=="TK_KEYWORD"or tok=="TK_OP"
or tok=="TK_STRING"or tok=="TK_NUMBER"then
prev=i
savetok(i)
linestart=false
elseif tok=="TK_EOL"then
if linestart then
if config.KEEP_LINES then
savetok(i)
linestart=true
end
else
savetok(i)
linestart=true
end
elseif tok=="TK_COMMENT"then
if i==1and string.sub(lorig[i],1,1)=="#"then
savetok(i)
linestart=false
end
elseif tok=="TK_LCOMMENT"then
local eols=nil
if config.KEEP_LINES then
if lval[i]>0then eols=string.rep("\n",lval[i])end
end
if iswhitespace(i+1)then
lorig[i]=eols or""
else
lorig[i]=eols or" "
end
savetok(i)
elseif tok=="TK_EOS"then
savetok(i)
break
else
error("unidentified token encountered")
end
i=i+1
end
if config.ZAP_EOLS then
ltok,lorig={},{}
ntokens=0
for i=1,dtokens do
local tok=dtok[i]
local orig=dorig[i]
if orig~=""or tok=="TK_EOS"then
ntokens=ntokens+1
ltok[ntokens]=tok
lorig[ntokens]=orig
end
end
dtok,dorig={},{}
dtokens=0
i=1
tok,prev="",""
while tok~="TK_EOS"do
tok=ltok[i]
if tok=="TK_EOL"and prev~="TK_COMMENT"then
if whitesp(i-1,i+1)==" "then
savetok(i)
end
else
prev=tok
savetok(i)
end
i=i+1
end
end
local dest=table.concat(dorig)
local OUTF=io.open(destfile,"wb")
if not OUTF then
error("cannot open \""..destfile.."\" for writing")
end
OUTF:write(dest)
io.close(OUTF)
src_stats_c=stats_c
src_stats_l=stats_l
LoadFile(destfile)
dtok,dorig,dtokens=
GetRealTokens(ltok,lorig,ntokens)
if stokens~=dtokens then
error("token count incorrect")
end
for i=1,stokens do
if stok[i]~=dtok[i]or sorig[i]~=dorig[i]then
error("token verification by comparison failed")
end
end
if not config.QUIET then
DispAllStats(srcfile,src_stats_c,src_stats_l,destfile,stats_c,stats_l)
end
end
function DumpTokens(srcfile)
local function Esc(v)return string.format("%q",v)end
LoadFile(srcfile)
for i=1,ntokens do
local ltok,lorig,lval=ltok[i],lorig[i],lval[i]
if ltok=="TK_KEYWORD"or ltok=="TK_NAME"or
ltok=="TK_NUMBER"or ltok=="TK_STRING"or
ltok=="TK_OP"then
print(ltok,lorig)
elseif ltok=="TK_COMMENT"or ltok=="TK_LCOMMENT"or
ltok=="TK_SPACE"then
print(ltok,Esc(lorig))
elseif ltok=="TK_EOS"or ltok=="TK_EOL"then
print(ltok)
else
error("unknown token type encountered")
end
end
end
function DoFiles(files)
for i,srcfile in ipairs(files)do
local destfile
local extb,exte=string.find(srcfile,"%.[^%.%\\%/]*$")
local basename,extension=srcfile,""
if extb and extb>1then
basename=string.sub(srcfile,1,extb-1)
extension=string.sub(srcfile,extb,exte)
end
destfile=config.OUTPUT_FILE or basename..config.SUFFIX..extension
if srcfile==destfile then
error("output filename identical to input filename")
end
if config.DUMP then
DumpTokens(srcfile)
elseif config.READ_ONLY then
DispSrcStats(srcfile)
else
ProcessToken(srcfile,destfile)
end
end
end
function main()
if table.getn(arg)==0then
print(title..usage)return
end
local files,i={},1
while i<=table.getn(arg)do
local a,b=arg[i],arg[i+1]
if string.sub(a,1,1)=="-"then
if a=="-h"or a=="--help"then
print(title)print(usage)return
elseif a=="--quiet"then
config.QUIET=true
elseif a=="--read-only"then
config.READ_ONLY=true
elseif a=="--keep-lines"then
config.KEEP_LINES=true
elseif a=="--maximum"then
config.MAX=true
elseif a=="--dump"then
config.DUMP=true
elseif a=="-o"then
if not b then error("-o option needs a file name")end
config.OUTPUT_FILE=b
i=i+1
elseif a=="--"then
break
else
error("unrecognized option "..a)
end
else
table.insert(files,a)
end
i=i+1
end
if config.MAX then
config.KEEP_LINES=false
config.ZAP_EOLS=true
end
if table.getn(files)>0then
if table.getn(files)>1then
if config.OUTPUT_FILE then
error("with -o, only one source file can be specified")
end
end
DoFiles(files)
else
print("LuaSrcDiet: nothing to do!")
end
end
if not TEST then
local OK,msg=pcall(main)
if not OK then
print("* Run with option -h or --help for usage information")
print(msg)
end
end
