-- merged file : lualibs-extended-merged.lua
-- parent file : lualibs-extended.lua
-- merge date  : 2023-07-13 12:55

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-sac']={
 version=1.001,
 optimize=true,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local byte,sub=string.byte,string.sub
local tonumber=tonumber
utilities=utilities or {}
local streams={}
utilities.streams=streams
function streams.open(filename,zerobased)
 local f=filename and io.loaddata(filename)
 if f then
  return { f,1,#f,zerobased or false }
 end
end
function streams.openstring(f,zerobased)
 if f then
  return { f,1,#f,zerobased or false }
 end
end
function streams.getstring(f)
 if f then
  return f[1]
 end
end
function streams.close()
end
function streams.size(f)
 return f and f[3] or 0
end
streams.getsize=streams.size
function streams.setposition(f,i)
 if f[4] then
  if i<=0 then
   f[2]=1
  else
   f[2]=i+1
  end
 else
  if i<=1 then
   f[2]=1
  else
   f[2]=i
  end
 end
end
function streams.getposition(f)
 if f[4] then
  return f[2]-1
 else
  return f[2]
 end
end
function streams.look(f,n,chars)
 local b=f[2]
 local e=b+n-1
 if chars then
  return sub(f[1],b,e)
 else
  return byte(f[1],b,e)
 end
end
function streams.skip(f,n)
 f[2]=f[2]+n
end
function streams.readbyte(f)
 local i=f[2]
 f[2]=i+1
 return byte(f[1],i)
end
function streams.readbytes(f,n)
 local i=f[2]
 local j=i+n
 f[2]=j
 return byte(f[1],i,j-1)
end
function streams.readbytetable(f,n)
 local i=f[2]
 local j=i+n
 f[2]=j
 return { byte(f[1],i,j-1) }
end
function streams.skipbytes(f,n)
 f[2]=f[2]+n
end
function streams.readchar(f)
 local i=f[2]
 f[2]=i+1
 return sub(f[1],i,i)
end
function streams.readstring(f,n)
 local i=f[2]
 local j=i+n
 f[2]=j
 return sub(f[1],i,j-1)
end
function streams.readinteger1(f)  
 local i=f[2]
 f[2]=i+1
 local n=byte(f[1],i)
 if n>=0x80 then
  return n-0x100
 else
  return n
 end
end
streams.readcardinal1=streams.readbyte  
streams.readcardinal=streams.readcardinal1
streams.readinteger=streams.readinteger1
function streams.readcardinal2(f)
 local i=f[2]
 local j=i+1
 f[2]=j+1
 local a,b=byte(f[1],i,j)
 return 0x100*a+b
end
function streams.readcardinal2le(f)
 local i=f[2]
 local j=i+1
 f[2]=j+1
 local b,a=byte(f[1],i,j)
 return 0x100*a+b
end
function streams.readinteger2(f)
 local i=f[2]
 local j=i+1
 f[2]=j+1
 local a,b=byte(f[1],i,j)
 if a>=0x80 then
  return 0x100*a+b-0x10000
 else
  return 0x100*a+b
 end
end
function streams.readinteger2le(f)
 local i=f[2]
 local j=i+1
 f[2]=j+1
 local b,a=byte(f[1],i,j)
 if a>=0x80 then
  return 0x100*a+b-0x10000
 else
  return 0x100*a+b
 end
end
function streams.readcardinal3(f)
 local i=f[2]
 local j=i+2
 f[2]=j+1
 local a,b,c=byte(f[1],i,j)
 return 0x10000*a+0x100*b+c
end
function streams.readcardinal3le(f)
 local i=f[2]
 local j=i+2
 f[2]=j+1
 local c,b,a=byte(f[1],i,j)
 return 0x10000*a+0x100*b+c
end
function streams.readinteger3(f)
 local i=f[2]
 local j=i+3
 f[2]=j+1
 local a,b,c=byte(f[1],i,j)
 if a>=0x80 then
  return 0x10000*a+0x100*b+c-0x1000000
 else
  return 0x10000*a+0x100*b+c
 end
end
function streams.readinteger3le(f)
 local i=f[2]
 local j=i+3
 f[2]=j+1
 local c,b,a=byte(f[1],i,j)
 if a>=0x80 then
  return 0x10000*a+0x100*b+c-0x1000000
 else
  return 0x10000*a+0x100*b+c
 end
end
function streams.readcardinal4(f)
 local i=f[2]
 local j=i+3
 f[2]=j+1
 local a,b,c,d=byte(f[1],i,j)
 return 0x1000000*a+0x10000*b+0x100*c+d
end
function streams.readcardinal4le(f)
 local i=f[2]
 local j=i+3
 f[2]=j+1
 local d,c,b,a=byte(f[1],i,j)
 return 0x1000000*a+0x10000*b+0x100*c+d
end
function streams.readinteger4(f)
 local i=f[2]
 local j=i+3
 f[2]=j+1
 local a,b,c,d=byte(f[1],i,j)
 if a>=0x80 then
  return 0x1000000*a+0x10000*b+0x100*c+d-0x100000000
 else
  return 0x1000000*a+0x10000*b+0x100*c+d
 end
end
function streams.readinteger4le(f)
 local i=f[2]
 local j=i+3
 f[2]=j+1
 local d,c,b,a=byte(f[1],i,j)
 if a>=0x80 then
  return 0x1000000*a+0x10000*b+0x100*c+d-0x100000000
 else
  return 0x1000000*a+0x10000*b+0x100*c+d
 end
end
function streams.readfixed2(f)
 local i=f[2]
 local j=i+1
 f[2]=j+1
 local n1,n2=byte(f[1],i,j)
 if n1>=0x80 then
  n1=n1-0x100
 end
 return n1+n2/0xFF
end
function streams.readfixed4(f)
 local i=f[2]
 local j=i+3
 f[2]=j+1
 local a,b,c,d=byte(f[1],i,j)
 local n1=0x100*a+b
 local n2=0x100*c+d
 if n1>=0x8000 then
  n1=n1-0x10000
 end
 return n1+n2/0xFFFF
end
if bit32 then
 local extract=bit32.extract
 local band=bit32.band
 function streams.read2dot14(f)
  local i=f[2]
  local j=i+1
  f[2]=j+1
  local a,b=byte(f[1],i,j)
  if a>=0x80 then
   local n=-(0x100*a+b)
   return-(extract(n,14,2)+(band(n,0x3FFF)/16384.0))
  else
   local n=0x100*a+b
   return   (extract(n,14,2)+(band(n,0x3FFF)/16384.0))
  end
 end
end
function streams.skipshort(f,n)
 f[2]=f[2]+2*(n or 1)
end
function streams.skiplong(f,n)
 f[2]=f[2]+4*(n or 1)
end
if sio and sio.readcardinal2 then
 local readcardinal1=sio.readcardinal1
 local readcardinal2=sio.readcardinal2
 local readcardinal3=sio.readcardinal3
 local readcardinal4=sio.readcardinal4
 local readinteger1=sio.readinteger1
 local readinteger2=sio.readinteger2
 local readinteger3=sio.readinteger3
 local readinteger4=sio.readinteger4
 local readfixed2=sio.readfixed2
 local readfixed4=sio.readfixed4
 local read2dot14=sio.read2dot14
 local readbytes=sio.readbytes
 local readbytetable=sio.readbytetable
 function streams.readcardinal1(f)
  local i=f[2]
  f[2]=i+1
  return readcardinal1(f[1],i)
 end
 function streams.readcardinal2(f)
  local i=f[2]
  f[2]=i+2
  return readcardinal2(f[1],i)
 end
 function streams.readcardinal3(f)
  local i=f[2]
  f[2]=i+3
  return readcardinal3(f[1],i)
 end
 function streams.readcardinal4(f)
  local i=f[2]
  f[2]=i+4
  return readcardinal4(f[1],i)
 end
 function streams.readinteger1(f)
  local i=f[2]
  f[2]=i+1
  return readinteger1(f[1],i)
 end
 function streams.readinteger2(f)
  local i=f[2]
  f[2]=i+2
  return readinteger2(f[1],i)
 end
 function streams.readinteger3(f)
  local i=f[2]
  f[2]=i+3
  return readinteger3(f[1],i)
 end
 function streams.readinteger4(f)
  local i=f[2]
  f[2]=i+4
  return readinteger4(f[1],i)
 end
 function streams.readfixed2(f) 
  local i=f[2]
  f[2]=i+2
  return readfixed2(f[1],i)
 end
 function streams.readfixed4(f) 
  local i=f[2]
  f[2]=i+4
  return readfixed4(f[1],i)
 end
 function streams.read2dot14(f)
  local i=f[2]
  f[2]=i+2
  return read2dot14(f[1],i)
 end
 function streams.readbytes(f,n)
  local i=f[2]
  local s=f[3]
  local p=i+n
  if p>s then
   f[2]=s+1
  else
   f[2]=p
  end
  return readbytes(f[1],i,n)
 end
 function streams.readbytetable(f,n)
  local i=f[2]
  local s=f[3]
  local p=i+n
  if p>s then
   f[2]=s+1
  else
   f[2]=p
  end
  return readbytetable(f[1],i,n)
 end
 streams.readbyte=streams.readcardinal1
 streams.readsignedbyte=streams.readinteger1
 streams.readcardinal=streams.readcardinal1
 streams.readinteger=streams.readinteger1
end
if sio and sio.readcardinaltable then
 local readcardinaltable=sio.readcardinaltable
 local readintegertable=sio.readintegertable
 function utilities.streams.readcardinaltable(f,n,b)
  local i=f[2]
  local s=f[3]
  local p=i+n*b
  if p>s then
   f[2]=s+1
  else
   f[2]=p
  end
  return readcardinaltable(f[1],i,n,b)
 end
 function utilities.streams.readintegertable(f,n,b)
  local i=f[2]
  local s=f[3]
  local p=i+n*b
  if p>s then
   f[2]=s+1
  else
   f[2]=p
  end
  return readintegertable(f[1],i,n,b)
 end
else
 local readcardinal1=streams.readcardinal1
 local readcardinal2=streams.readcardinal2
 local readcardinal3=streams.readcardinal3
 local readcardinal4=streams.readcardinal4
 function streams.readcardinaltable(f,n,b)
  local i=f[2]
  local s=f[3]
  local p=i+n*b
  if p>s then
   f[2]=s+1
  else
   f[2]=p
  end
  local t={}
   if b==1 then for i=1,n do t[i]=readcardinal1(f[1],i) end
  elseif b==2 then for i=1,n do t[i]=readcardinal2(f[1],i) end
  elseif b==3 then for i=1,n do t[i]=readcardinal3(f[1],i) end
  elseif b==4 then for i=1,n do t[i]=readcardinal4(f[1],i) end end
  return t
 end
 local readinteger1=streams.readinteger1
 local readinteger2=streams.readinteger2
 local readinteger3=streams.readinteger3
 local readinteger4=streams.readinteger4
 function streams.readintegertable(f,n,b)
  local i=f[2]
  local s=f[3]
  local p=i+n*b
  if p>s then
   f[2]=s+1
  else
   f[2]=p
  end
  local t={}
   if b==1 then for i=1,n do t[i]=readinteger1(f[1],i) end
  elseif b==2 then for i=1,n do t[i]=readinteger2(f[1],i) end
  elseif b==3 then for i=1,n do t[i]=readinteger3(f[1],i) end
  elseif b==4 then for i=1,n do t[i]=readinteger4(f[1],i) end end
  return t
 end
end
do
 local files=utilities.files
 if files then
  local openfile=files.open
  local openstream=streams.open
  local openstring=streams.openstring
  local setmetatable=setmetatable
  function io.newreader(str,method)
   local f,m
   if method=="string" then
    f=openstring(str,true)
    m=streams
   elseif method=="stream" then
    f=openstream(str,true)
    m=streams
   else
    f=openfile(str,"rb")
    m=files
   end
   if f then
    local t={}
    setmetatable(t,{
     __index=function(t,k)
      local r=m[k]
      if k=="close" then
       if f then
        m.close(f)
        f=nil
       end
       return function() end
      elseif r then
       local v=function(_,a,b) return r(f,a,b) end
       t[k]=v
       return v
      else
       print("unknown key",k)
      end
     end
    } )
    return t
   end
  end
 end
end
if bit32 and not streams.tocardinal1 then
 local extract=bit32.extract
 local char=string.char
    streams.tocardinal1=char
 function streams.tocardinal2(n)   return char(extract(n,8,8),extract(n,0,8)) end
 function streams.tocardinal3(n)   return char(extract(n,16,8),extract(n,8,8),extract(n,0,8)) end
 function streams.tocardinal4(n)   return char(extract(n,24,8),extract(n,16,8),extract(n,8,8),extract(n,0,8)) end
    streams.tocardinal1le=char
 function streams.tocardinal2le(n) return char(extract(n,0,8),extract(n,8,8)) end
 function streams.tocardinal3le(n) return char(extract(n,0,8),extract(n,8,8),extract(n,16,8)) end
 function streams.tocardinal4le(n) return char(extract(n,0,8),extract(n,8,8),extract(n,16,8),extract(n,24,8)) end
end
if not streams.readcstring then
 local readchar=streams.readchar
 local concat=table.concat
 function streams.readcstring(f)
  local t={}
  while true do
   local c=readchar(f)
   if c and c~="\0" then
    t[#t+1]=c
   else
    return concat(t)
   end
  end
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-str']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
utilities=utilities or {}
utilities.strings=utilities.strings or {}
local strings=utilities.strings
local format,gsub,rep,sub,find,char=string.format,string.gsub,string.rep,string.sub,string.find,string.char
local load,dump=load,string.dump
local tonumber,type,tostring,next,setmetatable=tonumber,type,tostring,next,setmetatable
local unpack,concat=table.unpack,table.concat
local P,V,C,S,R,Ct,Cs,Cp,Carg,Cc=lpeg.P,lpeg.V,lpeg.C,lpeg.S,lpeg.R,lpeg.Ct,lpeg.Cs,lpeg.Cp,lpeg.Carg,lpeg.Cc
local patterns,lpegmatch=lpeg.patterns,lpeg.match
local tsplitat=lpeg.tsplitat
local utfchar,utfbyte,utflen=utf.char,utf.byte,utf.len
local loadstripped=function(str,shortcuts)
 if shortcuts then
  return load(dump(load(str),true),nil,nil,shortcuts)
 else
  return load(dump(load(str),true))
 end
end
if not number then number={} end 
local stripzero=patterns.stripzero
local stripzeros=patterns.stripzeros
local newline=patterns.newline
local endofstring=patterns.endofstring
local anything=patterns.anything
local whitespace=patterns.whitespace
local space=patterns.space
local spacer=patterns.spacer
local spaceortab=patterns.spaceortab
local digit=patterns.digit
local sign=patterns.sign
local period=patterns.period
local ptf=1/65536
local bpf=(7200/7227)/65536
local function points(n)
 if n==0 then
  return "0pt"
 end
 n=tonumber(n)
 if not n or n==0 then
  return "0pt"
 end
 n=n*ptf
 if n%1==0 then
  return format("%ipt",n)
 else
  return lpegmatch(stripzeros,format("%.5fpt",n)) 
 end
end
local function nupoints(n)
 if n==0 then
  return "0"
 end
 n=tonumber(n)
 if not n or n==0 then
  return "0"
 end
 n=n*ptf
 if n%1==0 then
  return format("%i",n)
 else
  return format("%.5f",n) 
 end
end
local function basepoints(n)
 if n==0 then
  return "0bp"
 end
 n=tonumber(n)
 if not n or n==0 then
  return "0bp"
 end
 n=n*bpf
 if n%1==0 then
  return format("%ibp",n)
 else
  return lpegmatch(stripzeros,format("%.5fbp",n)) 
 end
end
local function nubasepoints(n)
 if n==0 then
  return "0"
 end
 n=tonumber(n)
 if not n or n==0 then
  return "0"
 end
 n=n*bpf
 if n%1==0 then
  return format("%i",n)
 else
  return format("%.5f",n) 
 end
end
number.points=points
number.nupoints=nupoints
number.basepoints=basepoints
number.nubasepoints=nubasepoints
local rubish=spaceortab^0*newline
local anyrubish=spaceortab+newline
local stripped=(spaceortab^1/"")*newline
local leading=rubish^0/""
local trailing=(anyrubish^1*endofstring)/""
local redundant=rubish^3/"\n"
local pattern=Cs(leading*(trailing+redundant+stripped+anything)^0)
function strings.collapsecrlf(str)
 return lpegmatch(pattern,str)
end
local repeaters={} 
function strings.newrepeater(str,offset)
 offset=offset or 0
 local s=repeaters[str]
 if not s then
  s={}
  repeaters[str]=s
 end
 local t=s[offset]
 if t then
  return t
 end
 t={}
 setmetatable(t,{ __index=function(t,k)
  if not k then
   return ""
  end
  local n=k+offset
  local s=n>0 and rep(str,n) or ""
  t[k]=s
  return s
 end })
 s[offset]=t
 return t
end
local extra,tab,start=0,0,4,0
local nspaces=strings.newrepeater(" ")
string.nspaces=nspaces
local pattern=Carg(1)/function(t)
  extra,tab,start=0,t or 7,1
 end*Cs((
   Cp()*patterns.tab/function(position)
    local current=(position-start+1)+extra
    local spaces=tab-(current-1)%tab
    if spaces>0 then
     extra=extra+spaces-1
     return nspaces[spaces] 
    else
     return ""
    end
   end+newline*Cp()/function(position)
    extra,start=0,position
   end+anything
  )^1)
function strings.tabtospace(str,tab)
 return lpegmatch(pattern,str,1,tab or 7)
end
function string.utfpadding(s,n)
 if not n or n==0 then
  return ""
 end
 local l=utflen(s)
 if n>0 then
  return nspaces[n-l]
 else
  return nspaces[-n-l]
 end
end
local optionalspace=spacer^0
local nospace=optionalspace/""
local endofline=nospace*newline
local stripend=(whitespace^1*endofstring)/""
local normalline=(nospace*((1-optionalspace*(newline+endofstring))^1)*nospace)
local stripempty=endofline^1/""
local normalempty=endofline^1
local singleempty=endofline*(endofline^0/"")
local doubleempty=endofline*endofline^-1*(endofline^0/"")
local stripstart=stripempty^0
local intospace=whitespace^1/" "
local noleading=whitespace^1/""
local notrailing=noleading*endofstring
local p_prune_normal=Cs (stripstart*(stripend+normalline+normalempty )^0 )
local p_prune_collapse=Cs (stripstart*(stripend+normalline+doubleempty )^0 )
local p_prune_noempty=Cs (stripstart*(stripend+normalline+singleempty )^0 )
local p_prune_intospace=Cs (noleading*(notrailing+intospace+1     )^0 )
local p_retain_normal=Cs ((normalline+normalempty )^0 )
local p_retain_collapse=Cs ((normalline+doubleempty )^0 )
local p_retain_noempty=Cs ((normalline+singleempty )^0 )
local p_collapse_all=Cs (stripstart*(stripend+((whitespace+newline)^1/" ")+1)^0 )
local striplinepatterns={
 ["prune"]=p_prune_normal,
 ["prune and collapse"]=p_prune_collapse,
 ["prune and no empty"]=p_prune_noempty,
 ["prune and to space"]=p_prune_intospace,
 ["retain"]=p_retain_normal,
 ["retain and collapse"]=p_retain_collapse,
 ["retain and no empty"]=p_retain_noempty,
 ["collapse all"]=p_collapse_all,
 ["collapse"]=patterns.collapser,
}
setmetatable(striplinepatterns,{ __index=function(t,k) return p_prune_collapse end })
strings.striplinepatterns=striplinepatterns
function strings.striplines(str,how)
 return str and lpegmatch(striplinepatterns[how],str) or str
end
function strings.collapse(str) 
 return str and lpegmatch(p_prune_intospace,str) or str
end
strings.striplong=strings.striplines
function strings.nice(str)
 str=gsub(str,"[:%-+_]+"," ") 
 return str
end
local n=0
local sequenced=table.sequenced
function string.autodouble(s,sep)
 if s==nil then
  return '""'
 end
 local t=type(s)
 if t=="number" then
  return tostring(s) 
 end
 if t=="table" then
  return ('"'..sequenced(s,sep or ",")..'"')
 end
 return ('"'..tostring(s)..'"')
end
function string.autosingle(s,sep)
 if s==nil then
  return "''"
 end
 local t=type(s)
 if t=="number" then
  return tostring(s) 
 end
 if t=="table" then
  return ("'"..sequenced(s,sep or ",").."'")
 end
 return ("'"..tostring(s).."'")
end
local tracedchars={ [0]=
 "[null]","[soh]","[stx]","[etx]","[eot]","[enq]","[ack]","[bel]",
 "[bs]","[ht]","[lf]","[vt]","[ff]","[cr]","[so]","[si]",
 "[dle]","[dc1]","[dc2]","[dc3]","[dc4]","[nak]","[syn]","[etb]",
 "[can]","[em]","[sub]","[esc]","[fs]","[gs]","[rs]","[us]",
 "[space]",
}
string.tracedchars=tracedchars
strings.tracers=tracedchars
function string.tracedchar(b)
 if type(b)=="number" then
  return tracedchars[b] or (utfchar(b).." (U+"..format("%05X",b)..")")
 else
  local c=utfbyte(b)
  return tracedchars[c] or (b.." (U+"..(c and format("%05X",c) or "?????")..")")
 end
end
function number.signed(i)
 if i>0 then
  return "+",i
 else
  return "-",-i
 end
end
local two=digit*digit
local three=two*digit
local prefix=(Carg(1)*three)^1
local splitter=Cs (
 (((1-(three^1*period))^1+C(three))*prefix+C((1-period)^1))*(anything/""*Carg(2))*C(2)
)
local splitter3=Cs (
 three*prefix*endofstring+two*prefix*endofstring+digit*prefix*endofstring+three+two+digit
)
patterns.formattednumber=splitter
function number.formatted(n,sep1,sep2)
 if sep1==false then
  if type(n)=="number" then
   n=tostring(n)
  end
  return lpegmatch(splitter3,n,1,sep2 or ".")
 else
  if type(n)=="number" then
   n=format("%0.2f",n)
  end
  if sep1==true then
   return lpegmatch(splitter,n,1,".",",")
  elseif sep1=="." then
   return lpegmatch(splitter,n,1,sep1,sep2 or ",")
  elseif sep1=="," then
   return lpegmatch(splitter,n,1,sep1,sep2 or ".")
  else
   return lpegmatch(splitter,n,1,sep1 or ",",sep2 or ".")
  end
 end
end
local p=Cs(
  P("-")^0*(P("0")^1/"")^0*(1-period)^0*(period*P("0")^1*endofstring/""+period^0)*P(1-P("0")^1*endofstring)^0
 )
function number.compactfloat(n,fmt)
 if n==0 then
  return "0"
 elseif n==1 then
  return "1"
 end
 n=lpegmatch(p,format(fmt or "%0.3f",n))
 if n=="." or n=="" or n=="-" then
  return "0"
 end
 return n
end
local zero=P("0")^1/""
local plus=P("+")/""
local minus=P("-")
local separator=period
local trailing=zero^1*#S("eE")
local exponent=(S("eE")*(plus+Cs((minus*zero^0*endofstring)/"")+minus)*zero^0*(endofstring*Cc("0")+anything^1))
local pattern_a=Cs(minus^0*digit^1*(separator/""*trailing+separator*(trailing+digit)^0)*exponent)
local pattern_b=Cs((exponent+anything)^0)
function number.sparseexponent(f,n)
 if not n then
  n=f
  f="%e"
 end
 local tn=type(n)
 if tn=="string" then 
  local m=tonumber(n)
  if m then
   return lpegmatch((f=="%e" or f=="%E") and pattern_a or pattern_b,format(f,m))
  end
 elseif tn=="number" then
  return lpegmatch((f=="%e" or f=="%E") and pattern_a or pattern_b,format(f,n))
 end
 return tostring(n)
end
local hf={}
local hs={}
setmetatable(hf,{ __index=function(t,k)
 local v="%."..k.."f"
 t[k]=v
 return v
end } )
setmetatable(hs,{ __index=function(t,k)
 local v="%"..k.."s"
 t[k]=v
 return v
end } )
function number.formattedfloat(n,b,a)
 local s=format(hf[a],n)
 local l=(b or 0)+(a or 0)+1
 if #s<l then
  return format(hs[l],s)
 else
  return s
 end
end
local template=[[
%s
%s
return function(%s) return %s end
]]
local pattern=Cs(Cc('"')*(
 (1-S('"\\\n\r'))^1+P('"')/'\\"'+P('\\')/'\\\\'+P('\n')/'\\n'+P('\r')/'\\r'
)^0*Cc('"'))
patterns.escapedquotes=pattern
function string.escapedquotes(s)
 return lpegmatch(pattern,s)
end
local pattern=(1-P("\\"))^1;pattern=Cs (
 pattern*((P("\\")/""*(digit^-3/function(s) return char(tonumber(s)) end))+pattern )^1
)
patterns.unescapedquotes=pattern
function string.unescapedquotes(s)
 return lpegmatch(pattern,s) or s
end
string.texnewlines=lpeg.replacer(patterns.newline,"\r",true)
local preamble=""
local environment={
 global=global or _G,
 lpeg=lpeg,
 type=type,
 tostring=tostring,
 tonumber=tonumber,
 format=string.format,
 concat=table.concat,
 signed=number.signed,
 points=number.points,
 nupoints=number.nupoints,
 basepoints=number.basepoints,
 nubasepoints=number.nubasepoints,
 utfchar=utf.char,
 utfbyte=utf.byte,
 lpegmatch=lpeg.match,
 nspaces=string.nspaces,
 utfpadding=string.utfpadding,
 tracedchar=string.tracedchar,
 autosingle=string.autosingle,
 autodouble=string.autodouble,
 sequenced=table.sequenced,
 formattednumber=number.formatted,
 sparseexponent=number.sparseexponent,
 formattedfloat=number.formattedfloat,
 stripzero=patterns.stripzero,
 stripzeros=patterns.stripzeros,
 escapedquotes=string.escapedquotes,
 FORMAT=string.f6,
}
local arguments={ "a1" } 
setmetatable(arguments,{ __index=function(t,k)
  local v=t[k-1]..",a"..k
  t[k]=v
  return v
 end
})
local prefix_any=C((sign+space+period+digit)^0)
local prefix_sub=(C((sign+digit)^0)+Cc(0))*period*(C((sign+digit)^0)+Cc(0))
local prefix_tab=P("{")*C((1-P("}"))^0)*P("}")+C((1-R("az","AZ","09","%%"))^0)
local format_s=function(f)
 n=n+1
 if f and f~="" then
  return format("format('%%%ss',a%s)",f,n)
 else 
  return format("(a%s or '')",n) 
 end
end
local format_S=function(f) 
 n=n+1
 if f and f~="" then
  return format("format('%%%ss',tostring(a%s))",f,n)
 else
  return format("tostring(a%s)",n)
 end
end
local format_right=function(f)
 n=n+1
 f=tonumber(f)
 if not f or f==0 then
  return format("(a%s or '')",n)
 elseif f>0 then
  return format("utfpadding(a%s,%i)..a%s",n,f,n)
 else
  return format("a%s..utfpadding(a%s,%i)",n,n,f)
 end
end
local format_left=function(f)
 n=n+1
 f=tonumber(f)
 if not f or f==0 then
  return format("(a%s or '')",n)
 end
 if f<0 then
  return format("utfpadding(a%s,%i)..a%s",n,-f,n)
 else
  return format("a%s..utfpadding(a%s,%i)",n,n,-f)
 end
end
local format_q=JITSUPPORTED and function()
 n=n+1
 return format("(a%s ~= nil and format('%%q',tostring(a%s)) or '')",n,n)
end or function()
 n=n+1
 return format("(a%s ~= nil and format('%%q',a%s) or '')",n,n)
end
local format_Q=function() 
 n=n+1
 return format("escapedquotes(tostring(a%s))",n)
end
local format_i=function(f)
 n=n+1
 if f and f~="" then
  return format("format('%%%si',a%s)",f,n)
 else
  return format("format('%%i',a%s)",n) 
 end
end
local format_d=format_i
local format_I=function(f)
 n=n+1
 return format("format('%%s%%%si',signed(a%s))",f,n)
end
local format_f=function(f)
 n=n+1
 return format("format('%%%sf',a%s)",f,n)
end
local format_F=function(f) 
 n=n+1
 if not f or f=="" then
  return format("(((a%s > -0.0000000005 and a%s < 0.0000000005) and '0') or format((a%s %% 1 == 0) and '%%i' or '%%.9f',a%s))",n,n,n,n)
 else
  return format("format((a%s %% 1 == 0) and '%%i' or '%%%sf',a%s)",n,f,n)
 end
end
local format_k=function(b,a) 
 n=n+1
 return format("formattedfloat(a%s,%s,%s)",n,b or 0,a or 0)
end
local format_g=function(f)
 n=n+1
 return format("format('%%%sg',a%s)",f,n)
end
local format_G=function(f)
 n=n+1
 return format("format('%%%sG',a%s)",f,n)
end
local format_e=function(f)
 n=n+1
 return format("format('%%%se',a%s)",f,n)
end
local format_E=function(f)
 n=n+1
 return format("format('%%%sE',a%s)",f,n)
end
local format_j=function(f)
 n=n+1
 return format("sparseexponent('%%%se',a%s)",f,n)
end
local format_J=function(f)
 n=n+1
 return format("sparseexponent('%%%sE',a%s)",f,n)
end
local format_x=function(f)
 n=n+1
 return format("format('%%%sx',a%s)",f,n)
end
local format_X=function(f)
 n=n+1
 return format("format('%%%sX',a%s)",f,n)
end
local format_o=function(f)
 n=n+1
 return format("format('%%%so',a%s)",f,n)
end
local format_c=function()
 n=n+1
 return format("utfchar(a%s)",n)
end
local format_C=function()
 n=n+1
 return format("tracedchar(a%s)",n)
end
local format_r=function(f)
 n=n+1
 return format("format('%%%s.0f',a%s)",f,n)
end
local format_h=function(f)
 n=n+1
 if f=="-" then
  f=sub(f,2)
  return format("format('%%%sx',type(a%s) == 'number' and a%s or utfbyte(a%s))",f=="" and "05" or f,n,n,n)
 else
  return format("format('0x%%%sx',type(a%s) == 'number' and a%s or utfbyte(a%s))",f=="" and "05" or f,n,n,n)
 end
end
local format_H=function(f)
 n=n+1
 if f=="-" then
  f=sub(f,2)
  return format("format('%%%sX',type(a%s) == 'number' and a%s or utfbyte(a%s))",f=="" and "05" or f,n,n,n)
 else
  return format("format('0x%%%sX',type(a%s) == 'number' and a%s or utfbyte(a%s))",f=="" and "05" or f,n,n,n)
 end
end
local format_u=function(f)
 n=n+1
 if f=="-" then
  f=sub(f,2)
  return format("format('%%%sx',type(a%s) == 'number' and a%s or utfbyte(a%s))",f=="" and "05" or f,n,n,n)
 else
  return format("format('u+%%%sx',type(a%s) == 'number' and a%s or utfbyte(a%s))",f=="" and "05" or f,n,n,n)
 end
end
local format_U=function(f)
 n=n+1
 if f=="-" then
  f=sub(f,2)
  return format("format('%%%sX',type(a%s) == 'number' and a%s or utfbyte(a%s))",f=="" and "05" or f,n,n,n)
 else
  return format("format('U+%%%sX',type(a%s) == 'number' and a%s or utfbyte(a%s))",f=="" and "05" or f,n,n,n)
 end
end
local format_p=function()
 n=n+1
 return format("points(a%s)",n)
end
local format_P=function()
 n=n+1
 return format("nupoints(a%s)",n)
end
local format_b=function()
 n=n+1
 return format("basepoints(a%s)",n)
end
local format_B=function()
 n=n+1
 return format("nubasepoints(a%s)",n)
end
local format_t=function(f)
 n=n+1
 if f and f~="" then
  return format("concat(a%s,%q)",n,f)
 else
  return format("concat(a%s)",n)
 end
end
local format_T=function(f)
 n=n+1
 if f and f~="" then
  return format("sequenced(a%s,%q)",n,f)
 else
  return format("sequenced(a%s)",n)
 end
end
local format_l=function()
 n=n+1
 return format("(a%s and 'true' or 'false')",n)
end
local format_L=function()
 n=n+1
 return format("(a%s and 'TRUE' or 'FALSE')",n)
end
local format_n=function() 
 n=n+1
 return format("((a%s %% 1 == 0) and format('%%i',a%s) or tostring(a%s))",n,n,n)
end
local format_N  if environment.FORMAT then
 format_N=function(f)
  n=n+1
  if not f or f=="" then
   return format("FORMAT(a%s,'%%.9f')",n)
  elseif f==".6" or f=="0.6" then
   return format("FORMAT(a%s)",n)
  else
   return format("FORMAT(a%s,'%%%sf')",n,f)
  end
 end
else
 format_N=function(f) 
  n=n+1
  if not f or f=="" then
   f=".9"
  end 
  return format("(((a%s %% 1 == 0) and format('%%i',a%s)) or lpegmatch(stripzero,format('%%%sf',a%s)))",n,n,f,n)
 end
end
local format_a=function(f)
 n=n+1
 if f and f~="" then
  return format("autosingle(a%s,%q)",n,f)
 else
  return format("autosingle(a%s)",n)
 end
end
local format_A=function(f)
 n=n+1
 if f and f~="" then
  return format("autodouble(a%s,%q)",n,f)
 else
  return format("autodouble(a%s)",n)
 end
end
local format_w=function(f) 
 n=n+1
 f=tonumber(f)
 if f then 
  return format("nspaces[%s+a%s]",f,n) 
 else
  return format("nspaces[a%s]",n) 
 end
end
local format_W=function(f) 
 return format("nspaces[%s]",tonumber(f) or 0)
end
local format_m=function(f)
 n=n+1
 if not f or f=="" then
  f=","
 end
 if f=="0" then
  return format([[formattednumber(a%s,false)]],n)
 else
  return format([[formattednumber(a%s,%q,".")]],n,f)
 end
end
local format_M=function(f)
 n=n+1
 if not f or f=="" then
  f="."
 end
 if f=="0" then
  return format([[formattednumber(a%s,false)]],n)
 else
  return format([[formattednumber(a%s,%q,",")]],n,f)
 end
end
local format_z=function(f)
 n=n+(tonumber(f) or 1)
 return "''" 
end
local format_rest=function(s)
 return format("%q",s) 
end
local format_extension=function(extensions,f,name)
 local extension=extensions[name] or "tostring(%s)"
 local f=tonumber(f) or 1
 local w=find(extension,"%.%.%.")
 if f==0 then
  if w then
   extension=gsub(extension,"%.%.%.","")
  end
  return extension
 elseif f==1 then
  if w then
   extension=gsub(extension,"%.%.%.","%%s")
  end
  n=n+1
  local a="a"..n
  return format(extension,a,a) 
 elseif f<0 then
  if w then
   extension=gsub(extension,"%.%.%.","")
   return extension
  else
   local a="a"..(n+f+1)
   return format(extension,a,a)
  end
 else
  if w then
   extension=gsub(extension,"%.%.%.",rep("%%s,",f-1).."%%s")
  end
  local t={}
  for i=1,f do
   n=n+1
   t[i]="a"..n
  end
  return format(extension,unpack(t))
 end
end
local builder=Cs { "start",
 start=(
  (
   P("%")/""*(
    V("!") 
+V("s")+V("q")+V("i")+V("d")+V("f")+V("F")+V("g")+V("G")+V("e")+V("E")+V("x")+V("X")+V("o")
+V("c")+V("C")+V("S") 
+V("Q") 
+V("n") 
+V("N") 
+V("k")
+V("r")+V("h")+V("H")+V("u")+V("U")+V("p")+V("P")+V("b")+V("B")+V("t")+V("T")+V("l")+V("L")+V("I")+V("w") 
+V("W") 
+V("a") 
+V("A") 
+V("j")+V("J") 
+V("m")+V("M") 
+V("z")
+V(">") 
+V("<")
   )+V("*")
  )*(endofstring+Carg(1))
 )^0,
 ["s"]=(prefix_any*P("s"))/format_s,
 ["q"]=(prefix_any*P("q"))/format_q,
 ["i"]=(prefix_any*P("i"))/format_i,
 ["d"]=(prefix_any*P("d"))/format_d,
 ["f"]=(prefix_any*P("f"))/format_f,
 ["F"]=(prefix_any*P("F"))/format_F,
 ["g"]=(prefix_any*P("g"))/format_g,
 ["G"]=(prefix_any*P("G"))/format_G,
 ["e"]=(prefix_any*P("e"))/format_e,
 ["E"]=(prefix_any*P("E"))/format_E,
 ["x"]=(prefix_any*P("x"))/format_x,
 ["X"]=(prefix_any*P("X"))/format_X,
 ["o"]=(prefix_any*P("o"))/format_o,
 ["S"]=(prefix_any*P("S"))/format_S,
 ["Q"]=(prefix_any*P("Q"))/format_Q,
 ["n"]=(prefix_any*P("n"))/format_n,
 ["N"]=(prefix_any*P("N"))/format_N,
 ["k"]=(prefix_sub*P("k"))/format_k,
 ["c"]=(prefix_any*P("c"))/format_c,
 ["C"]=(prefix_any*P("C"))/format_C,
 ["r"]=(prefix_any*P("r"))/format_r,
 ["h"]=(prefix_any*P("h"))/format_h,
 ["H"]=(prefix_any*P("H"))/format_H,
 ["u"]=(prefix_any*P("u"))/format_u,
 ["U"]=(prefix_any*P("U"))/format_U,
 ["p"]=(prefix_any*P("p"))/format_p,
 ["P"]=(prefix_any*P("P"))/format_P,
 ["b"]=(prefix_any*P("b"))/format_b,
 ["B"]=(prefix_any*P("B"))/format_B,
 ["t"]=(prefix_tab*P("t"))/format_t,
 ["T"]=(prefix_tab*P("T"))/format_T,
 ["l"]=(prefix_any*P("l"))/format_l,
 ["L"]=(prefix_any*P("L"))/format_L,
 ["I"]=(prefix_any*P("I"))/format_I,
 ["w"]=(prefix_any*P("w"))/format_w,
 ["W"]=(prefix_any*P("W"))/format_W,
 ["j"]=(prefix_any*P("j"))/format_j,
 ["J"]=(prefix_any*P("J"))/format_J,
 ["m"]=(prefix_any*P("m"))/format_m,
 ["M"]=(prefix_any*P("M"))/format_M,
 ["z"]=(prefix_any*P("z"))/format_z,
 ["a"]=(prefix_any*P("a"))/format_a,
 ["A"]=(prefix_any*P("A"))/format_A,
 ["<"]=(prefix_any*P("<"))/format_left,
 [">"]=(prefix_any*P(">"))/format_right,
 ["*"]=Cs(((1-P("%"))^1+P("%%")/"%%")^1)/format_rest,
 ["?"]=Cs(((1-P("%"))^1      )^1)/format_rest,
 ["!"]=Carg(2)*prefix_any*P("!")*C((1-P("!"))^1)*P("!")/format_extension,
}
local xx=setmetatable({},{ __index=function(t,k) local v=format("%02x",k) t[k]=v return v end })
local XX=setmetatable({},{ __index=function(t,k) local v=format("%02X",k) t[k]=v return v end })
local preset={
 ["%02x"]=function(n) return xx[n] end,
 ["%02X"]=function(n) return XX[n] end,
}
local direct=P("%")*(sign+space+period+digit)^0*S("sqidfgGeExXo")*endofstring/[[local format = string.format return function(str) return format("%0",str) end]]
local function make(t,str)
 local f=preset[str]
 if f then
  return f
 end
 local p=lpegmatch(direct,str)
 if p then
  f=loadstripped(p)()
 else
  n=0
  p=lpegmatch(builder,str,1,t._connector_,t._extensions_) 
  if n>0 then
   p=format(template,preamble,t._preamble_,arguments[n],p)
   f=loadstripped(p,t._environment_)() 
  else
   f=function() return str end
  end
 end
 t[str]=f
 return f
end
local function use(t,fmt,...)
 return t[fmt](...)
end
strings.formatters={}
function strings.formatters.new(noconcat)
 local e={} 
 for k,v in next,environment do
  e[k]=v
 end
 local t={
  _type_="formatter",
  _connector_=noconcat and "," or "..",
  _extensions_={},
  _preamble_="",
  _environment_=e,
 }
 setmetatable(t,{ __index=make,__call=use })
 return t
end
local formatters=strings.formatters.new() 
string.formatters=formatters 
string.formatter=function(str,...) return formatters[str](...) end 
local function add(t,name,template,preamble)
 if type(t)=="table" and t._type_=="formatter" then
  t._extensions_[name]=template or "%s"
  if type(preamble)=="string" then
   t._preamble_=preamble.."\n"..t._preamble_ 
  elseif type(preamble)=="table" then
   for k,v in next,preamble do
    t._environment_[k]=v
   end
  end
 end
end
strings.formatters.add=add
patterns.xmlescape=Cs((P("<")/"&lt;"+P(">")/"&gt;"+P("&")/"&amp;"+P('"')/"&quot;"+anything)^0)
patterns.texescape=Cs((C(S("#$%\\{}"))/"\\%1"+anything)^0)
patterns.luaescape=Cs(((1-S('"\n'))^1+P('"')/'\\"'+P('\n')/'\\n"')^0) 
patterns.luaquoted=Cs(Cc('"')*((1-S('"\n'))^1+P('"')/'\\"'+P('\n')/'\\n"')^0*Cc('"'))
add(formatters,"xml",[[lpegmatch(xmlescape,%s)]],{ xmlescape=patterns.xmlescape })
add(formatters,"tex",[[lpegmatch(texescape,%s)]],{ texescape=patterns.texescape })
add(formatters,"lua",[[lpegmatch(luaescape,%s)]],{ luaescape=patterns.luaescape })
local dquote=patterns.dquote 
local equote=patterns.escaped+dquote/'\\"'+1
local cquote=Cc('"')
local pattern=Cs(dquote*(equote-P(-2))^0*dquote)     
+Cs(cquote*(equote-space)^0*space*equote^0*cquote) 
function string.optionalquoted(str)
 return lpegmatch(pattern,str) or str
end
local pattern=Cs((newline/(os.newline or "\r")+1)^0)
function string.replacenewlines(str)
 return lpegmatch(pattern,str)
end
function strings.newcollector()
 local result,r={},0
 return
  function(fmt,str,...) 
   r=r+1
   result[r]=str==nil and fmt or formatters[fmt](str,...)
  end,
  function(connector) 
   if result then
    local str=concat(result,connector)
    result,r={},0
    return str
   end
  end
end
local f_16_16=formatters["%0.5N"]
function number.to16dot16(n)
 return f_16_16(n/65536.0)
end
if not string.explode then
 local p_utf=patterns.utf8character
 local p_check=C(p_utf)*(P("+")*Cc(true))^0
 local p_split=Ct(C(p_utf)^0)
 local p_space=Ct((C(1-P(" ")^1)+P(" ")^1)^0)
 function string.explode(str,symbol)
  if symbol=="" then
   return lpegmatch(p_split,str)
  elseif symbol then
   local a,b=lpegmatch(p_check,symbol)
   if b then
    return lpegmatch(tsplitat(P(a)^1),str)
   else
    return lpegmatch(tsplitat(a),str)
   end
  else
   return lpegmatch(p_space,str)
  end
 end
end
do
 local p_whitespace=patterns.whitespace^1
 local cache=setmetatable({},{ __index=function(t,k)
  local p=tsplitat(p_whitespace*P(k)*p_whitespace)
  local v=function(s)
   return lpegmatch(p,s)
  end
  t[k]=v
  return v
 end })
 function string.wordsplitter(s)
  return cache[s]
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-fil']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local byte=string.byte
local char=string.char
utilities=utilities or {}
local files={}
utilities.files=files
local zerobased={}
function files.open(filename,zb)
 local f=io.open(filename,"rb")
 if f then
  zerobased[f]=zb or false
 end
 return f
end
function files.close(f)
 zerobased[f]=nil
 f:close()
end
function files.size(f)
 local current=f:seek()
 local size=f:seek("end")
 f:seek("set",current)
 return size
end
files.getsize=files.size
function files.setposition(f,n)
 if zerobased[f] then
  f:seek("set",n)
 else
  f:seek("set",n-1)
 end
end
function files.getposition(f)
 if zerobased[f] then
  return f:seek()
 else
  return f:seek()+1
 end
end
function files.look(f,n,chars)
 local p=f:seek()
 local s=f:read(n)
 f:seek("set",p)
 if chars then
  return s
 else
  return byte(s,1,#s)
 end
end
function files.skip(f,n)
 if n==1 then
  f:read(n)
 else
  f:seek("set",f:seek()+n)
 end
end
function files.readbyte(f)
 return byte(f:read(1))
end
function files.readbytes(f,n)
 return byte(f:read(n),1,n)
end
function files.readbytetable(f,n)
 local s=f:read(n or 1)
 return { byte(s,1,#s) } 
end
function files.readchar(f)
 return f:read(1)
end
function files.readstring(f,n)
 return f:read(n or 1)
end
function files.readinteger1(f)  
 local n=byte(f:read(1))
 if n>=0x80 then
  return n-0x100
 else
  return n
 end
end
files.readcardinal1=files.readbyte  
files.readcardinal=files.readcardinal1
files.readinteger=files.readinteger1
files.readsignedbyte=files.readinteger1
function files.readcardinal2(f)
 local a,b=byte(f:read(2),1,2)
 return 0x100*a+b
end
function files.readcardinal2le(f)
 local b,a=byte(f:read(2),1,2)
 return 0x100*a+b
end
function files.readinteger2(f)
 local a,b=byte(f:read(2),1,2)
 if a>=0x80 then
  return 0x100*a+b-0x10000
 else
  return 0x100*a+b
 end
end
function files.readinteger2le(f)
 local b,a=byte(f:read(2),1,2)
 if a>=0x80 then
  return 0x100*a+b-0x10000
 else
  return 0x100*a+b
 end
end
function files.readcardinal3(f)
 local a,b,c=byte(f:read(3),1,3)
 return 0x10000*a+0x100*b+c
end
function files.readcardinal3le(f)
 local c,b,a=byte(f:read(3),1,3)
 return 0x10000*a+0x100*b+c
end
function files.readinteger3(f)
 local a,b,c=byte(f:read(3),1,3)
 if a>=0x80 then
  return 0x10000*a+0x100*b+c-0x1000000
 else
  return 0x10000*a+0x100*b+c
 end
end
function files.readinteger3le(f)
 local c,b,a=byte(f:read(3),1,3)
 if a>=0x80 then
  return 0x10000*a+0x100*b+c-0x1000000
 else
  return 0x10000*a+0x100*b+c
 end
end
function files.readcardinal4(f)
 local a,b,c,d=byte(f:read(4),1,4)
 return 0x1000000*a+0x10000*b+0x100*c+d
end
function files.readcardinal4le(f)
 local d,c,b,a=byte(f:read(4),1,4)
 return 0x1000000*a+0x10000*b+0x100*c+d
end
function files.readinteger4(f)
 local a,b,c,d=byte(f:read(4),1,4)
 if a>=0x80 then
  return 0x1000000*a+0x10000*b+0x100*c+d-0x100000000
 else
  return 0x1000000*a+0x10000*b+0x100*c+d
 end
end
function files.readinteger4le(f)
 local d,c,b,a=byte(f:read(4),1,4)
 if a>=0x80 then
  return 0x1000000*a+0x10000*b+0x100*c+d-0x100000000
 else
  return 0x1000000*a+0x10000*b+0x100*c+d
 end
end
function files.readfixed2(f)
 local a,b=byte(f:read(2),1,2)
 if a>=0x80 then
  return (a-0x100)+b/0x100
 else
  return (a  )+b/0x100
 end
end
function files.readfixed4(f)
 local a,b,c,d=byte(f:read(4),1,4)
 if a>=0x80 then
  return (0x100*a+b-0x10000)+(0x100*c+d)/0x10000
 else
  return (0x100*a+b    )+(0x100*c+d)/0x10000
 end
end
if bit32 then
 local extract=bit32.extract
 local band=bit32.band
 function files.read2dot14(f)
  local a,b=byte(f:read(2),1,2)
  if a>=0x80 then
   local n=-(0x100*a+b)
   return-(extract(n,14,2)+(band(n,0x3FFF)/16384.0))
  else
   local n=0x100*a+b
   return   (extract(n,14,2)+(band(n,0x3FFF)/16384.0))
  end
 end
end
function files.skipshort(f,n)
 f:read(2*(n or 1))
end
function files.skiplong(f,n)
 f:read(4*(n or 1))
end
if bit32 then
 local rshift=bit32.rshift
 function files.writecardinal2(f,n)
  local a=char(n%256)
  n=rshift(n,8)
  local b=char(n%256)
  f:write(b,a)
 end
else
 local floor=math.floor
 function files.writecardinal2(f,n)
  local a=char(n%256)
  n=floor(n/256)
  local b=char(n%256)
  f:write(b,a)
 end
end
function files.writecardinal4(f,n)
 local a=char(n%256)
 n=rshift(n,8)
 local b=char(n%256)
 n=rshift(n,8)
 local c=char(n%256)
 n=rshift(n,8)
 local d=char(n%256)
 f:write(d,c,b,a)
end
function files.writestring(f,s)
 f:write(char(byte(s,1,#s)))
end
function files.writebyte(f,b)
 f:write(char(b))
end
if fio and fio.readcardinal1 then
 files.readcardinal1=fio.readcardinal1
 files.readcardinal2=fio.readcardinal2
 files.readcardinal3=fio.readcardinal3
 files.readcardinal4=fio.readcardinal4
 files.readinteger1=fio.readinteger1
 files.readinteger2=fio.readinteger2
 files.readinteger3=fio.readinteger3
 files.readinteger4=fio.readinteger4
 files.readfixed2=fio.readfixed2
 files.readfixed4=fio.readfixed4
 files.read2dot14=fio.read2dot14
 files.setposition=fio.setposition
 files.getposition=fio.getposition
 files.readbyte=files.readcardinal1
 files.readsignedbyte=files.readinteger1
 files.readcardinal=files.readcardinal1
 files.readinteger=files.readinteger1
 local skipposition=fio.skipposition
 files.skipposition=skipposition
 files.readbytes=fio.readbytes
 files.readbytetable=fio.readbytetable
 function files.skipshort(f,n)
  skipposition(f,2*(n or 1))
 end
 function files.skiplong(f,n)
  skipposition(f,4*(n or 1))
 end
end
if fio and fio.readcardinaltable then
 files.readcardinaltable=fio.readcardinaltable
 files.readintegertable=fio.readintegertable
else
 local readcardinal1=files.readcardinal1
 local readcardinal2=files.readcardinal2
 local readcardinal3=files.readcardinal3
 local readcardinal4=files.readcardinal4
 function files.readcardinaltable(f,n,b)
  local t={}
   if b==1 then for i=1,n do t[i]=readcardinal1(f) end
  elseif b==2 then for i=1,n do t[i]=readcardinal2(f) end
  elseif b==3 then for i=1,n do t[i]=readcardinal3(f) end
  elseif b==4 then for i=1,n do t[i]=readcardinal4(f) end end
  return t
 end
 local readinteger1=files.readinteger1
 local readinteger2=files.readinteger2
 local readinteger3=files.readinteger3
 local readinteger4=files.readinteger4
 function files.readintegertable(f,n,b)
  local t={}
   if b==1 then for i=1,n do t[i]=readinteger1(f) end
  elseif b==2 then for i=1,n do t[i]=readinteger2(f) end
  elseif b==3 then for i=1,n do t[i]=readinteger3(f) end
  elseif b==4 then for i=1,n do t[i]=readinteger4(f) end end
  return t
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-tab']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
utilities=utilities or {}
utilities.tables=utilities.tables or {}
local tables=utilities.tables
local format,gmatch,gsub,sub=string.format,string.gmatch,string.gsub,string.sub
local concat,insert,remove,sort=table.concat,table.insert,table.remove,table.sort
local setmetatable,getmetatable,tonumber,tostring,rawget=setmetatable,getmetatable,tonumber,tostring,rawget
local type,next,rawset,tonumber,tostring,load,select=type,next,rawset,tonumber,tostring,load,select
local lpegmatch,P,Cs,Cc=lpeg.match,lpeg.P,lpeg.Cs,lpeg.Cc
local sortedkeys,sortedpairs=table.sortedkeys,table.sortedpairs
local formatters=string.formatters
local utftoeight=utf.toeight
local splitter=lpeg.tsplitat(".")
function utilities.tables.definetable(target,nofirst,nolast) 
 local composed=nil
 local t={}
 local snippets=lpegmatch(splitter,target)
 for i=1,#snippets-(nolast and 1 or 0) do
  local name=snippets[i]
  if composed then
   composed=composed.."."..name
    t[#t+1]=formatters["if not %s then %s = { } end"](composed,composed)
  else
   composed=name
   if not nofirst then
    t[#t+1]=formatters["%s = %s or { }"](composed,composed)
   end
  end
 end
 if composed then
  if nolast then
   composed=composed.."."..snippets[#snippets]
  end
  return concat(t,"\n"),composed 
 else
  return "",target
 end
end
function tables.definedtable(...)
 local t=_G
 for i=1,select("#",...) do
  local li=select(i,...)
  local tl=t[li]
  if not tl then
   tl={}
   t[li]=tl
  end
  t=tl
 end
 return t
end
function tables.accesstable(target,root)
 local t=root or _G
 for name in gmatch(target,"([^%.]+)") do
  t=t[name]
  if not t then
   return
  end
 end
 return t
end
function tables.migratetable(target,v,root)
 local t=root or _G
 local names=lpegmatch(splitter,target)
 for i=1,#names-1 do
  local name=names[i]
  t[name]=t[name] or {}
  t=t[name]
  if not t then
   return
  end
 end
 t[names[#names]]=v
end
function tables.removevalue(t,value) 
 if value then
  for i=1,#t do
   if t[i]==value then
    remove(t,i)
   end
  end
 end
end
function tables.replacevalue(t,oldvalue,newvalue)
 if oldvalue and newvalue then
  for i=1,#t do
   if t[i]==oldvalue then
    t[i]=newvalue
   end
  end
 end
end
function tables.insertbeforevalue(t,value,extra)
 for i=1,#t do
  if t[i]==extra then
   remove(t,i)
  end
 end
 for i=1,#t do
  if t[i]==value then
   insert(t,i,extra)
   return
  end
 end
 insert(t,1,extra)
end
function tables.insertaftervalue(t,value,extra)
 for i=1,#t do
  if t[i]==extra then
   remove(t,i)
  end
 end
 for i=1,#t do
  if t[i]==value then
   insert(t,i+1,extra)
   return
  end
 end
 insert(t,#t+1,extra)
end
local escape=Cs(Cc('"')*((P('"')/'""'+P(1))^0)*Cc('"'))
function table.tocsv(t,specification)
 if t and #t>0 then
  local result={}
  local r={}
  specification=specification or {}
  local fields=specification.fields
  if type(fields)~="string" then
   fields=sortedkeys(t[1])
  end
  local separator=specification.separator or ","
  local noffields=#fields
  if specification.preamble==true then
   for f=1,noffields do
    r[f]=lpegmatch(escape,tostring(fields[f]))
   end
   result[1]=concat(r,separator)
  end
  for i=1,#t do
   local ti=t[i]
   for f=1,noffields do
    local field=ti[fields[f]]
    if type(field)=="string" then
     r[f]=lpegmatch(escape,field)
    else
     r[f]=tostring(field)
    end
   end
   result[i+1]=concat(r,separator)
  end
  return concat(result,"\n")
 else
  return ""
 end
end
local nspaces=utilities.strings.newrepeater(" ")
local function toxml(t,d,result,step)
 local r=#result
 for k,v in sortedpairs(t) do
  local s=nspaces[d] 
  local tk=type(k)
  local tv=type(v)
  if tv=="table" then
   if tk=="number" then
    r=r+1 result[r]=formatters["%s<entry n='%s'>"](s,k)
    toxml(v,d+step,result,step)
    r=r+1 result[r]=formatters["%s</entry>"](s,k)
   else
    r=r+1 result[r]=formatters["%s<%s>"](s,k)
    toxml(v,d+step,result,step)
    r=r+1 result[r]=formatters["%s</%s>"](s,k)
   end
  elseif tv=="string" then
   if tk=="number" then
    r=r+1 result[r]=formatters["%s<entry n='%s'>%!xml!</entry>"](s,k,v,k)
   else
    r=r+1 result[r]=formatters["%s<%s>%!xml!</%s>"](s,k,v,k)
   end
  elseif tk=="number" then
   r=r+1 result[r]=formatters["%s<entry n='%s'>%S</entry>"](s,k,v,k)
  else
   r=r+1 result[r]=formatters["%s<%s>%S</%s>"](s,k,v,k)
  end
 end
end
function table.toxml(t,specification)
 specification=specification or {}
 local name=specification.name
 local noroot=name==false
 local result=(specification.nobanner or noroot) and {} or { "<?xml version='1.0' standalone='yes' ?>" }
 local indent=specification.indent or 0
 local spaces=specification.spaces or 1
 if noroot then
  toxml(t,indent,result,spaces)
 else
  toxml({ [name or "data"]=t },indent,result,spaces)
 end
 return concat(result,"\n")
end
function tables.encapsulate(core,capsule,protect)
 if type(capsule)~="table" then
  protect=true
  capsule={}
 end
 for key,value in next,core do
  if capsule[key] then
   print(formatters["\ninvalid %s %a in %a"]("inheritance",key,core))
   os.exit()
  else
   capsule[key]=value
  end
 end
 if protect then
  for key,value in next,core do
   core[key]=nil
  end
  setmetatable(core,{
   __index=capsule,
   __newindex=function(t,key,value)
    if capsule[key] then
     print(formatters["\ninvalid %s %a' in %a"]("overload",key,core))
     os.exit()
    else
     rawset(t,key,value)
    end
   end
  } )
 end
end
if JITSUPPORTED then
 local f_hashed_string=formatters["[%Q]=%Q,"]
 local f_hashed_number=formatters["[%Q]=%s,"]
 local f_hashed_boolean=formatters["[%Q]=%l,"]
 local f_hashed_table=formatters["[%Q]="]
 local f_indexed_string=formatters["[%s]=%Q,"]
 local f_indexed_number=formatters["[%s]=%s,"]
 local f_indexed_boolean=formatters["[%s]=%l,"]
 local f_indexed_table=formatters["[%s]="]
 local f_ordered_string=formatters["%Q,"]
 local f_ordered_number=formatters["%s,"]
 local f_ordered_boolean=formatters["%l,"]
 function table.fastserialize(t,prefix)
  local r={ type(prefix)=="string" and prefix or "return" }
  local m=1
  local function fastserialize(t,outer) 
   local n=#t
   m=m+1
   r[m]="{"
   if n>0 then
    local v=t[0]
    if v then
     local tv=type(v)
     if tv=="string" then
      m=m+1 r[m]=f_indexed_string(0,v)
     elseif tv=="number" then
      m=m+1 r[m]=f_indexed_number(0,v)
     elseif tv=="table" then
      m=m+1 r[m]=f_indexed_table(0)
      fastserialize(v)
      m=m+1 r[m]=f_indexed_table(0)
     elseif tv=="boolean" then
      m=m+1 r[m]=f_indexed_boolean(0,v)
     end
    end
    for i=1,n do
     local v=t[i]
     local tv=type(v)
     if tv=="string" then
      m=m+1 r[m]=f_ordered_string(v)
     elseif tv=="number" then
      m=m+1 r[m]=f_ordered_number(v)
     elseif tv=="table" then
      fastserialize(v)
     elseif tv=="boolean" then
      m=m+1 r[m]=f_ordered_boolean(v)
     end
    end
   end
   for k,v in next,t do
    local tk=type(k)
    if tk=="number" then
     if k>n or k<0 then
      local tv=type(v)
      if tv=="string" then
       m=m+1 r[m]=f_indexed_string(k,v)
      elseif tv=="number" then
       m=m+1 r[m]=f_indexed_number(k,v)
      elseif tv=="table" then
       m=m+1 r[m]=f_indexed_table(k)
       fastserialize(v)
      elseif tv=="boolean" then
       m=m+1 r[m]=f_indexed_boolean(k,v)
      end
     end
    else
     local tv=type(v)
     if tv=="string" then
      m=m+1 r[m]=f_hashed_string(k,v)
     elseif tv=="number" then
      m=m+1 r[m]=f_hashed_number(k,v)
     elseif tv=="table" then
      m=m+1 r[m]=f_hashed_table(k)
      fastserialize(v)
     elseif tv=="boolean" then
      m=m+1 r[m]=f_hashed_boolean(k,v)
     end
    end
   end
   m=m+1
   if outer then
    r[m]="}"
   else
    r[m]="},"
   end
   return r
  end
  return concat(fastserialize(t,true))
 end
else
 function table.fastserialize(t,prefix) 
  local r={ type(prefix)=="string" and prefix or "return" }
  local m=1
  local function fastserialize(t,outer) 
   local n=#t
   m=m+1
   r[m]="{"
   if n>0 then
    local v=t[0]
    if v then
     m=m+1
     r[m]="[0]="
     if type(v)=="table" then
      fastserialize(v)
     else
      r[m]=format("%q,",v)
     end
    end
    for i=1,n do
     local v=t[i]
     m=m+1
     if type(v)=="table" then
      r[m]=format("[%i]=",i)
      fastserialize(v)
     else
      r[m]=format("[%i]=%q,",i,v)
     end
    end
   end
   for k,v in next,t do
    local tk=type(k)
    if tk=="number" then
     if k>n or k<0 then
      m=m+1
      if type(v)=="table" then
       r[m]=format("[%i]=",k)
       fastserialize(v)
      else
       r[m]=format("[%i]=%q,",k,v)
      end
     end
    else
     m=m+1
     if type(v)=="table" then
      r[m]=format("[%q]=",k)
      fastserialize(v)
     else
      r[m]=format("[%q]=%q,",k,v)
     end
    end
   end
   m=m+1
   if outer then
    r[m]="}"
   else
    r[m]="},"
   end
   return r
  end
  return concat(fastserialize(t,true))
 end
end
function table.deserialize(str)
 if not str or str=="" then
  return
 end
 local code=load(str)
 if not code then
  return
 end
 code=code()
 if not code then
  return
 end
 return code
end
function table.load(filename,loader)
 if filename then
  local t=(loader or io.loaddata)(filename)
  if t and t~="" then
   local t=utftoeight(t)
   t=load(t)
   if type(t)=="function" then
    t=t()
    if type(t)=="table" then
     return t
    end
   end
  end
 end
end
function table.save(filename,t,n,...)
 io.savedata(filename,table.serialize(t,n==nil and true or n,...)) 
end
local f_key_value=formatters["%s=%q"]
local f_add_table=formatters[" {%t},\n"]
local f_return_table=formatters["return {\n%t}"]
local function slowdrop(t) 
 local r={}
 local l={}
 for i=1,#t do
  local ti=t[i]
  local j=0
  for k,v in next,ti do
   j=j+1
   l[j]=f_key_value(k,v)
  end
  r[i]=f_add_table(l)
 end
 return f_return_table(r)
end
local function fastdrop(t)
 local r={ "return {\n" }
 local m=1
 for i=1,#t do
  local ti=t[i]
  m=m+1 r[m]=" {"
  for k,v in next,ti do
   m=m+1 r[m]=f_key_value(k,v)
  end
  m=m+1 r[m]="},\n"
 end
 m=m+1
 r[m]="}"
 return concat(r)
end
function table.drop(t,slow) 
 if #t==0 then
  return "return { }"
 elseif slow==true then
  return slowdrop(t) 
 else
  return fastdrop(t) 
 end
end
local selfmapper={ __index=function(t,k) t[k]=k return k end }
function table.twowaymapper(t) 
 if not t then     
  t={}       
 else        
  local zero=rawget(t,0)  
  for i=zero and 0 or 1,#t do
   local ti=t[i]    
   if ti then
    local i=tostring(i)
    t[i]=ti   
    t[ti]=i    
   end
  end
 end
 setmetatable(t,selfmapper)
 return t
end
local f_start_key_idx=formatters["%w{"]
local f_start_key_num=JITSUPPORTED and formatters["%w[%s]={"] or formatters["%w[%q]={"]
local f_start_key_str=formatters["%w[%q]={"]
local f_start_key_boo=formatters["%w[%l]={"]
local f_start_key_nop=formatters["%w{"]
local f_stop=formatters["%w},"]
local f_key_num_value_num=JITSUPPORTED and formatters["%w[%s]=%s,"] or formatters["%w[%s]=%q,"]
local f_key_str_value_num=JITSUPPORTED and formatters["%w[%Q]=%s,"] or formatters["%w[%Q]=%q,"]
local f_key_boo_value_num=JITSUPPORTED and formatters["%w[%l]=%s,"] or formatters["%w[%l]=%q,"]
local f_key_num_value_str=JITSUPPORTED and formatters["%w[%s]=%Q,"] or formatters["%w[%q]=%Q,"]
local f_key_str_value_str=formatters["%w[%Q]=%Q,"]
local f_key_boo_value_str=formatters["%w[%l]=%Q,"]
local f_key_num_value_boo=JITSUPPORTED and formatters["%w[%s]=%l,"] or formatters["%w[%q]=%l,"]
local f_key_str_value_boo=formatters["%w[%Q]=%l,"]
local f_key_boo_value_boo=formatters["%w[%l]=%l,"]
local f_key_num_value_not=JITSUPPORTED and formatters["%w[%s]={},"] or formatters["%w[%q]={},"]
local f_key_str_value_not=formatters["%w[%Q]={},"]
local f_key_boo_value_not=formatters["%w[%l]={},"]
local f_key_num_value_seq=JITSUPPORTED and formatters["%w[%s]={ %, t },"] or formatters["%w[%q]={ %, t },"]
local f_key_str_value_seq=formatters["%w[%Q]={ %, t },"]
local f_key_boo_value_seq=formatters["%w[%l]={ %, t },"]
local f_val_num=JITSUPPORTED and formatters["%w%s,"] or formatters["%w%q,"]
local f_val_str=formatters["%w%Q,"]
local f_val_boo=formatters["%w%l,"]
local f_val_not=formatters["%w{},"]
local f_val_seq=formatters["%w{ %, t },"]
local f_fin_seq=formatters[" %, t }"]
local f_table_return=formatters["return {"]
local f_table_name=formatters["%s={"]
local f_table_direct=formatters["{"]
local f_table_entry=formatters["[%Q]={"]
local f_table_finish=formatters["}"]
local spaces=utilities.strings.newrepeater(" ")
local original_serialize=table.serialize
local is_simple_table=table.is_simple_table
local function serialize(root,name,specification)
 if type(specification)=="table" then
  return original_serialize(root,name,specification) 
 end
 local t 
 local n=1
 local unknown=false
 local function do_serialize(root,name,depth,level,indexed)
  if level>0 then
   n=n+1
   if indexed then
    t[n]=f_start_key_idx(depth)
   else
    local tn=type(name)
    if tn=="number" then
     t[n]=f_start_key_num(depth,name)
    elseif tn=="string" then
     t[n]=f_start_key_str(depth,name)
    elseif tn=="boolean" then
     t[n]=f_start_key_boo(depth,name)
    else
     t[n]=f_start_key_nop(depth)
    end
   end
   depth=depth+1
  end
  if root and next(root)~=nil then
   local first=nil
   local last=#root
   if last>0 then
    for k=1,last do
     if rawget(root,k)==nil then
      last=k-1
      break
     end
    end
    if last>0 then
     first=1
    end
   end
   local sk=sortedkeys(root)
   for i=1,#sk do
    local k=sk[i]
    local v=root[k]
    local tv=type(v)
    local tk=type(k)
    if first and tk=="number" and k<=last and k>=first then
     if tv=="number" then
      n=n+1 t[n]=f_val_num(depth,v)
     elseif tv=="string" then
      n=n+1 t[n]=f_val_str(depth,v)
     elseif tv=="table" then
      if next(v)==nil then 
       n=n+1 t[n]=f_val_not(depth)
      else
       local st=is_simple_table(v)
       if st then
        n=n+1 t[n]=f_val_seq(depth,st)
       else
        do_serialize(v,k,depth,level+1,true)
       end
      end
     elseif tv=="boolean" then
      n=n+1 t[n]=f_val_boo(depth,v)
     elseif unknown then
      n=n+1 t[n]=f_val_str(depth,tostring(v))
     end
    elseif tv=="number" then
     if tk=="number" then
      n=n+1 t[n]=f_key_num_value_num(depth,k,v)
     elseif tk=="string" then
      n=n+1 t[n]=f_key_str_value_num(depth,k,v)
     elseif tk=="boolean" then
      n=n+1 t[n]=f_key_boo_value_num(depth,k,v)
     elseif unknown then
      n=n+1 t[n]=f_key_str_value_num(depth,tostring(k),v)
     end
    elseif tv=="string" then
     if tk=="number" then
      n=n+1 t[n]=f_key_num_value_str(depth,k,v)
     elseif tk=="string" then
      n=n+1 t[n]=f_key_str_value_str(depth,k,v)
     elseif tk=="boolean" then
      n=n+1 t[n]=f_key_boo_value_str(depth,k,v)
     elseif unknown then
      n=n+1 t[n]=f_key_str_value_str(depth,tostring(k),v)
     end
    elseif tv=="table" then
     if next(v)==nil then
      if tk=="number" then
       n=n+1 t[n]=f_key_num_value_not(depth,k)
      elseif tk=="string" then
       n=n+1 t[n]=f_key_str_value_not(depth,k)
      elseif tk=="boolean" then
       n=n+1 t[n]=f_key_boo_value_not(depth,k)
      elseif unknown then
       n=n+1 t[n]=f_key_str_value_not(depth,tostring(k))
      end
     else
      local st=is_simple_table(v)
      if not st then
       do_serialize(v,k,depth,level+1)
      elseif tk=="number" then
       n=n+1 t[n]=f_key_num_value_seq(depth,k,st)
      elseif tk=="string" then
       n=n+1 t[n]=f_key_str_value_seq(depth,k,st)
      elseif tk=="boolean" then
       n=n+1 t[n]=f_key_boo_value_seq(depth,k,st)
      elseif unknown then
       n=n+1 t[n]=f_key_str_value_seq(depth,tostring(k),st)
      end
     end
    elseif tv=="boolean" then
     if tk=="number" then
      n=n+1 t[n]=f_key_num_value_boo(depth,k,v)
     elseif tk=="string" then
      n=n+1 t[n]=f_key_str_value_boo(depth,k,v)
     elseif tk=="boolean" then
      n=n+1 t[n]=f_key_boo_value_boo(depth,k,v)
     elseif unknown then
      n=n+1 t[n]=f_key_str_value_boo(depth,tostring(k),v)
     end
    else
     if tk=="number" then
      n=n+1 t[n]=f_key_num_value_str(depth,k,tostring(v))
     elseif tk=="string" then
      n=n+1 t[n]=f_key_str_value_str(depth,k,tostring(v))
     elseif tk=="boolean" then
      n=n+1 t[n]=f_key_boo_value_str(depth,k,tostring(v))
     elseif unknown then
      n=n+1 t[n]=f_key_str_value_str(depth,tostring(k),tostring(v))
     end
    end
   end
  end
  if level>0 then
   n=n+1 t[n]=f_stop(depth-1)
  end
 end
 local tname=type(name)
 if tname=="string" then
  if name=="return" then
   t={ f_table_return() }
  else
   t={ f_table_name(name) }
  end
 elseif tname=="number" then
  t={ f_table_entry(name) }
 elseif tname=="boolean" then
  if name then
   t={ f_table_return() }
  else
   t={ f_table_direct() }
  end
 else
  t={ f_table_name("t") }
 end
 if root then
  if getmetatable(root) then 
   local dummy=root._w_h_a_t_e_v_e_r_ 
   root._w_h_a_t_e_v_e_r_=nil
  end
  if next(root)~=nil then
   local st=is_simple_table(root)
   if st then
    return t[1]..f_fin_seq(st) 
   else
    do_serialize(root,name,1,0)
   end
  end
 end
 n=n+1
 t[n]=f_table_finish()
 return concat(t,"\n")
end
table.serialize=serialize
if setinspector then
 setinspector("table",function(v)
  if type(v)=="table" then
   print(serialize(v,"table",{ metacheck=false }))
   return true
  end
 end)
end
local mt={
 __newindex=function(t,k,v)
  local n=t.last+1
  t.last=n
  t.list[n]=k
  t.hash[k]=v
 end,
 __index=function(t,k)
  return t.hash[k]
 end,
 __len=function(t)
  return t.last
 end,
}
function table.orderedhash()
 return setmetatable({ list={},hash={},last=0 },mt)
end
function table.ordered(t)
 local n=t.last
 if n>0 then
  local l=t.list
  local i=1
  local h=t.hash
  local f=function()
   if i<=n then
    local k=i
    local v=h[l[k]]
    i=i+1
    return k,v
   end
  end
  return f,1,h[l[1]]
 else
  return function() end
 end
end
function combine(target,source)
 if target then
  for k,v in next,source do
   if type(v)=="table" then
      target[k]=combine(target[k],source[k])
   else
      target[k]=v
   end
  end
  return target
 else
  return source
 end
end
table.combine=combine

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-sto']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local setmetatable,getmetatable,rawset,type=setmetatable,getmetatable,rawset,type
utilities=utilities or {}
utilities.storage=utilities.storage or {}
local storage=utilities.storage
function storage.mark(t)
 if not t then
  print("\nfatal error: storage cannot be marked\n")
  os.exit()
  return
 end
 local m=getmetatable(t)
 if not m then
  m={}
  setmetatable(t,m)
 end
 m.__storage__=true
 return t
end
function storage.allocate(t)
 t=t or {}
 local m=getmetatable(t)
 if not m then
  m={}
  setmetatable(t,m)
 end
 m.__storage__=true
 return t
end
function storage.marked(t)
 local m=getmetatable(t)
 return m and m.__storage__
end
function storage.checked(t)
 if not t then
  report("\nfatal error: storage has not been allocated\n")
  os.exit()
  return
 end
 return t
end
function storage.setinitializer(data,initialize)
 local m=getmetatable(data) or {}
 m.__index=function(data,k)
  m.__index=nil 
  initialize()
  return data[k]
 end
 setmetatable(data,m)
end
local keyisvalue={ __index=function(t,k)
 t[k]=k
 return k
end }
function storage.sparse(t)
 t=t or {}
 setmetatable(t,keyisvalue)
 return t
end
local function f_empty ()         return "" end 
local function f_self  (t,k) t[k]=k      return k  end
local function f_table (t,k) local v={} t[k]=v return v  end
local function f_number(t,k) t[k]=0      return 0  end 
local function f_ignore()          end 
local f_index={
 ["empty"]=f_empty,
 ["self"]=f_self,
 ["table"]=f_table,
 ["number"]=f_number,
}
function table.setmetatableindex(t,f)
 if type(t)~="table" then
  f,t=t,{}
 end
 local m=getmetatable(t)
 local i=f_index[f] or f
 if m then
  m.__index=i
 else
  setmetatable(t,{ __index=i })
 end
 return t
end
local f_index={
 ["ignore"]=f_ignore,
}
function table.setmetatablenewindex(t,f)
 if type(t)~="table" then
  f,t=t,{}
 end
 local m=getmetatable(t)
 local i=f_index[f] or f
 if m then
  m.__newindex=i
 else
  setmetatable(t,{ __newindex=i })
 end
 return t
end
function table.setmetatablecall(t,f)
 if type(t)~="table" then
  f,t=t,{}
 end
 local m=getmetatable(t)
 if m then
  m.__call=f
 else
  setmetatable(t,{ __call=f })
 end
 return t
end
function table.setmetatableindices(t,f,n,c)
 if type(t)~="table" then
  f,t=t,{}
 end
 local m=getmetatable(t)
 local i=f_index[f] or f
 if m then
  m.__index=i
  m.__newindex=n
  m.__call=c
 else
  setmetatable(t,{
   __index=i,
   __newindex=n,
   __call=c,
  })
 end
 return t
end
function table.setmetatablekey(t,key,value)
 local m=getmetatable(t)
 if not m then
  m={}
  setmetatable(t,m)
 end
 m[key]=value
 return t
end
function table.getmetatablekey(t,key,value)
 local m=getmetatable(t)
 return m and m[key]
end
function table.makeweak(t)
 if not t then
  t={}
 end
 local m=getmetatable(t)
 if m then
  m.__mode="v"
 else
  setmetatable(t,{ __mode="v" })
 end
 return t
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-prs']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local lpeg,table,string=lpeg,table,string
local P,R,V,S,C,Ct,Cs,Carg,Cc,Cg,Cf,Cp=lpeg.P,lpeg.R,lpeg.V,lpeg.S,lpeg.C,lpeg.Ct,lpeg.Cs,lpeg.Carg,lpeg.Cc,lpeg.Cg,lpeg.Cf,lpeg.Cp
local lpegmatch,lpegpatterns=lpeg.match,lpeg.patterns
local concat,gmatch,find=table.concat,string.gmatch,string.find
local tonumber,tostring,type,next,rawset=tonumber,tostring,type,next,rawset
local mod,div=math.mod,math.div
utilities=utilities or {}
local parsers=utilities.parsers or {}
utilities.parsers=parsers
local patterns=parsers.patterns or {}
parsers.patterns=patterns
local setmetatableindex=table.setmetatableindex
local sortedhash=table.sortedhash
local sortedkeys=table.sortedkeys
local tohash=table.tohash
local hashes={}
parsers.hashes=hashes
local digit=R("09")
local space=P(' ')
local equal=P("=")
local colon=P(":")
local comma=P(",")
local lbrace=P("{")
local rbrace=P("}")
local lparent=P("(")
local rparent=P(")")
local lbracket=P("[")
local rbracket=P("]")
local period=S(".")
local punctuation=S(".,:;")
local spacer=lpegpatterns.spacer
local whitespace=lpegpatterns.whitespace
local newline=lpegpatterns.newline
local anything=lpegpatterns.anything
local endofstring=lpegpatterns.endofstring
local nobrace=1-(lbrace+rbrace )
local noparent=1-(lparent+rparent)
local nobracket=1-(lbracket+rbracket)
local escape,left,right=P("\\"),P('{'),P('}')
lpegpatterns.balanced=P {
 ((escape*(left+right))+(1-(left+right))+V(2))^0,
 left*V(1)*right
}
local nestedbraces=P { lbrace*(nobrace+V(1))^0*rbrace }
local nestedparents=P { lparent*(noparent+V(1))^0*rparent }
local nestedbrackets=P { lbracket*(nobracket+V(1))^0*rbracket }
local spaces=space^0
local argument=Cs((lbrace/"")*((nobrace+nestedbraces)^0)*(rbrace/""))
local content=(1-endofstring)^0
lpegpatterns.nestedbraces=nestedbraces   
lpegpatterns.nestedparents=nestedparents  
lpegpatterns.nestedbrackets=nestedbrackets 
lpegpatterns.nested=nestedbraces   
lpegpatterns.argument=argument    
lpegpatterns.content=content  
local value=lbrace*C((nobrace+nestedbraces)^0)*rbrace+C((nestedbraces+(1-comma))^0)
local key=C((1-equal-comma)^1)
local pattern_a=(space+comma)^0*(key*equal*value+key*C(""))
local pattern_c=(space+comma)^0*(key*equal*value)
local pattern_d=(space+comma)^0*(key*(equal+colon)*value+key*C(""))
local key=C((1-space-equal-comma)^1)
local pattern_b=spaces*comma^0*spaces*(key*((spaces*equal*spaces*value)+C("")))
local hash={}
local function set(key,value)
 hash[key]=value
end
local pattern_a_s=(pattern_a/set)^1
local pattern_b_s=(pattern_b/set)^1
local pattern_c_s=(pattern_c/set)^1
local pattern_d_s=(pattern_d/set)^1
patterns.settings_to_hash_a=pattern_a_s
patterns.settings_to_hash_b=pattern_b_s
patterns.settings_to_hash_c=pattern_c_s
patterns.settings_to_hash_d=pattern_d_s
function parsers.make_settings_to_hash_pattern(set,how)
 if how=="strict" then
  return (pattern_c/set)^1
 elseif how=="tolerant" then
  return (pattern_b/set)^1
 else
  return (pattern_a/set)^1
 end
end
function parsers.settings_to_hash(str,existing)
 if not str or str=="" then
  return {}
 elseif type(str)=="table" then
  if existing then
   for k,v in next,str do
    existing[k]=v
   end
   return exiting
  else
   return str
  end
 else
  hash=existing or {}
  lpegmatch(pattern_a_s,str)
  return hash
 end
end
function parsers.settings_to_hash_colon_too(str)
 if not str or str=="" then
  return {}
 elseif type(str)=="table" then
  return str
 else
  hash={}
  lpegmatch(pattern_d_s,str)
  return hash
 end
end
function parsers.settings_to_hash_tolerant(str,existing)
 if not str or str=="" then
  return {}
 elseif type(str)=="table" then
  if existing then
   for k,v in next,str do
    existing[k]=v
   end
   return exiting
  else
   return str
  end
 else
  hash=existing or {}
  lpegmatch(pattern_b_s,str)
  return hash
 end
end
function parsers.settings_to_hash_strict(str,existing)
 if not str or str=="" then
  return nil
 elseif type(str)=="table" then
  if existing then
   for k,v in next,str do
    existing[k]=v
   end
   return exiting
  else
   return str
  end
 elseif str and str~="" then
  hash=existing or {}
  lpegmatch(pattern_c_s,str)
  return next(hash) and hash
 end
end
local separator=comma*space^0
local value=lbrace*C((nobrace+nestedbraces)^0)*rbrace+C((nestedbraces+(1-comma))^0)
local pattern=spaces*Ct(value*(separator*value)^0)
patterns.settings_to_array=pattern
function parsers.settings_to_array(str,strict)
 if not str or str=="" then
  return {}
 elseif type(str)=="table" then
  return str
 elseif strict then
  if find(str,"{",1,true) then
   return lpegmatch(pattern,str)
  else
   return { str }
  end
 elseif find(str,",",1,true) then
  return lpegmatch(pattern,str)
 else
  return { str }
 end
end
function parsers.settings_to_numbers(str)
 if not str or str=="" then
  return {}
 end
 if type(str)=="table" then
 elseif find(str,",",1,true) then
  str=lpegmatch(pattern,str)
 else
  return { tonumber(str) }
 end
 for i=1,#str do
  str[i]=tonumber(str[i])
 end
 return str
end
local value=lbrace*C((nobrace+nestedbraces)^0)*rbrace+C((nestedbraces+nestedbrackets+nestedparents+(1-comma))^0)
local pattern=spaces*Ct(value*(separator*value)^0)
function parsers.settings_to_array_obey_fences(str)
 return lpegmatch(pattern,str)
end
local cache_a={}
local cache_b={}
function parsers.groupedsplitat(symbol,withaction)
 if not symbol then
  symbol=","
 end
 local pattern=(withaction and cache_b or cache_a)[symbol]
 if not pattern then
  local symbols=S(symbol)
  local separator=space^0*symbols*space^0
  local value=lbrace*C((nobrace+nestedbraces)^0)
*(rbrace*(#symbols+P(-1))) 
+C((nestedbraces+(1-(space^0*(symbols+P(-1)))))^0)
  if withaction then
   local withvalue=Carg(1)*value/function(f,s) return f(s) end
   pattern=spaces*withvalue*(separator*withvalue)^0
   cache_b[symbol]=pattern
  else
   pattern=spaces*Ct(value*(separator*value)^0)
   cache_a[symbol]=pattern
  end
 end
 return pattern
end
local pattern_a=parsers.groupedsplitat(",",false)
local pattern_b=parsers.groupedsplitat(",",true)
function parsers.stripped_settings_to_array(str)
 if not str or str=="" then
  return {}
 else
  return lpegmatch(pattern_a,str)
 end
end
function parsers.process_stripped_settings(str,action)
 if not str or str=="" then
  return {}
 else
  return lpegmatch(pattern_b,str,1,action)
 end
end
local function set(t,v)
 t[#t+1]=v
end
local value=P(Carg(1)*value)/set
local pattern=value*(separator*value)^0*Carg(1)
function parsers.add_settings_to_array(t,str)
 return lpegmatch(pattern,str,nil,t)
end
function parsers.hash_to_string(h,separator,yes,no,strict,omit)
 if h then
  local t={}
  local tn=0
  local s=sortedkeys(h)
  omit=omit and tohash(omit)
  for i=1,#s do
   local key=s[i]
   if not omit or not omit[key] then
    local value=h[key]
    if type(value)=="boolean" then
     if yes and no then
      if value then
       tn=tn+1
       t[tn]=key..'='..yes
      elseif not strict then
       tn=tn+1
       t[tn]=key..'='..no
      end
     elseif value or not strict then
      tn=tn+1
      t[tn]=key..'='..tostring(value)
     end
    else
     tn=tn+1
     t[tn]=key..'='..value
    end
   end
  end
  return concat(t,separator or ",")
 else
  return ""
 end
end
function parsers.array_to_string(a,separator)
 if a then
  return concat(a,separator or ",")
 else
  return ""
 end
end
local pattern=Cf(Ct("")*Cg(C((1-S(", "))^1)*S(", ")^0*Cc(true))^1,rawset)
function parsers.settings_to_set(str)
 return str and lpegmatch(pattern,str) or {}
end
hashes.settings_to_set=table.setmetatableindex(function(t,k) 
 local v=k and lpegmatch(pattern,k) or {}
 t[k]=v
 return v
end)
function parsers.settings_to_set(str)
 return str and lpegmatch(pattern,str) or {}
end
local pattern=Ct((C((1-S(", "))^1)*S(", ")^0)^1)
hashes.settings_to_list=table.setmetatableindex(function(t,k) 
 local v=k and lpegmatch(pattern,k) or {}
 t[k]=v
 return v
end)
getmetatable(hashes.settings_to_set ).__mode="kv" 
getmetatable(hashes.settings_to_list).__mode="kv" 
function parsers.simple_hash_to_string(h,separator)
 local t={}
 local tn=0
 for k,v in sortedhash(h) do
  if v then
   tn=tn+1
   t[tn]=k
  end
 end
 return concat(t,separator or ",")
end
local str=Cs(lpegpatterns.unquoted)+C((1-whitespace-equal)^1)
local setting=Cf(Carg(1)*(whitespace^0*Cg(str*whitespace^0*(equal*whitespace^0*str+Cc(""))))^1,rawset)
local splitter=setting^1
function parsers.options_to_hash(str,target)
 return str and lpegmatch(splitter,str,1,target or {}) or {}
end
local splitter=lpeg.tsplitat(" ")
function parsers.options_to_array(str)
 return str and lpegmatch(splitter,str) or {}
end
local value=P(lbrace*C((nobrace+nestedbraces)^0)*rbrace)+C(digit^1*lparent*(noparent+nestedparents)^1*rparent)+C((nestedbraces+(1-comma))^1)
local pattern_a=spaces*Ct(value*(separator*value)^0)
local function repeater(n,str)
 if not n then
  return str
 else
  local s=lpegmatch(pattern_a,str)
  if n==1 then
   return unpack(s)
  else
   local t={}
   local tn=0
   for i=1,n do
    for j=1,#s do
     tn=tn+1
     t[tn]=s[j]
    end
   end
   return unpack(t)
  end
 end
end
local value=P(lbrace*C((nobrace+nestedbraces)^0)*rbrace)+(C(digit^1)/tonumber*lparent*Cs((noparent+nestedparents)^1)*rparent)/repeater+C((nestedbraces+(1-comma))^1)
local pattern_b=spaces*Ct(value*(separator*value)^0)
function parsers.settings_to_array_with_repeat(str,expand) 
 if expand then
  return lpegmatch(pattern_b,str) or {}
 else
  return lpegmatch(pattern_a,str) or {}
 end
end
local value=lbrace*C((nobrace+nestedbraces)^0)*rbrace
local pattern=Ct((space+value)^0)
function parsers.arguments_to_table(str)
 return lpegmatch(pattern,str)
end
function parsers.getparameters(self,class,parentclass,settings)
 local sc=self[class]
 if not sc then
  sc={}
  self[class]=sc
  if parentclass then
   local sp=self[parentclass]
   if not sp then
    sp={}
    self[parentclass]=sp
   end
   setmetatableindex(sc,sp)
  end
 end
 parsers.settings_to_hash(settings,sc)
end
function parsers.listitem(str)
 return gmatch(str,"[^, ]+")
end
local pattern=Cs { "start",
 start=V("one")+V("two")+V("three"),
 rest=(Cc(",")*V("thousand"))^0*(P(".")+endofstring)*anything^0,
 thousand=digit*digit*digit,
 one=digit*V("rest"),
 two=digit*digit*V("rest"),
 three=V("thousand")*V("rest"),
}
lpegpatterns.splitthousands=pattern 
function parsers.splitthousands(str)
 return lpegmatch(pattern,str) or str
end
local optionalwhitespace=whitespace^0
lpegpatterns.words=Ct((Cs((1-punctuation-whitespace)^1)+anything)^1)
lpegpatterns.sentences=Ct((optionalwhitespace*Cs((1-period)^0*period))^1)
lpegpatterns.paragraphs=Ct((optionalwhitespace*Cs((whitespace^1*endofstring/""+1-(spacer^0*newline*newline))^1))^1)
local dquote=P('"')
local equal=P('=')
local escape=P('\\')
local separator=S(' ,')
local key=C((1-equal)^1)
local value=dquote*C((1-dquote-escape*dquote)^0)*dquote
local pattern=Cf(Ct("")*(Cg(key*equal*value)*separator^0)^1,rawset)^0*P(-1)
function parsers.keq_to_hash(str)
 if str and str~="" then
  return lpegmatch(pattern,str)
 else
  return {}
 end
end
local defaultspecification={ separator=",",quote='"' }
function parsers.csvsplitter(specification)
 specification=specification and setmetatableindex(specification,defaultspecification) or defaultspecification
 local separator=specification.separator
 local quotechar=specification.quote
 local numbers=specification.numbers
 local separator=S(separator~="" and separator or ",")
 local whatever=C((1-separator-newline)^0)
 if quotechar and quotechar~="" then
  local quotedata=nil
  for chr in gmatch(quotechar,".") do
   local quotechar=P(chr)
   local quoteitem=(1-quotechar)^0
   local quoteword=quotechar*(numbers and (quoteitem/tonumber) or C(quoteitem))*quotechar
   if quotedata then
    quotedata=quotedata+quoteword
   else
    quotedata=quoteword
   end
  end
  whatever=quotedata+whatever
 end
 local parser=Ct((Ct(whatever*(separator*whatever)^0)*S("\n\r")^1)^0 )
 return function(data)
  return lpegmatch(parser,data)
 end
end
function parsers.rfc4180splitter(specification)
 specification=specification and setmetatableindex(specification,defaultspecification) or defaultspecification
 local numbers=specification.numbers
 local separator=specification.separator 
 local quotechar=P(specification.quote)  
 local dquotechar=quotechar*quotechar   
/specification.quote
 local separator=S(separator~="" and separator or ",")
 local whatever=(dquotechar+(1-quotechar))^0
 local escaped=quotechar*(numbers and (whatever/tonumber) or Cs(whatever))*quotechar
 local non_escaped=C((1-quotechar-newline-separator)^1)
 local field=escaped+non_escaped+Cc("")
 local record=Ct(field*(separator*field)^1)
 local headerline=record*Cp()
 local morerecords=(newline^(specification.strict and -1 or 1)*record)^0
 local headeryes=Ct(morerecords)
 local headernop=Ct(record*morerecords)
 return function(data,getheader)
  if getheader then
   local header,position=lpegmatch(headerline,data)
   local data=lpegmatch(headeryes,data,position)
   return data,header
  else
   return lpegmatch(headernop,data)
  end
 end
end
local function ranger(first,last,n,action)
 if not first then
 elseif last==true then
  for i=first,n or first do
   action(i)
  end
 elseif last then
  for i=first,last do
   action(i)
  end
 else
  action(first)
 end
end
local cardinal=(lpegpatterns.hexadecimal+lpegpatterns.cardinal)/tonumber
local spacers=lpegpatterns.spacer^0
local endofstring=lpegpatterns.endofstring
local stepper=spacers*(cardinal*(spacers*S(":-")*spacers*(cardinal+Cc(true) )+Cc(false) )*Carg(1)*Carg(2)/ranger*S(", ")^0 )^1
local stepper=spacers*(cardinal*(spacers*S(":-")*spacers*(cardinal+(P("*")+endofstring)*Cc(true) )+Cc(false) )*Carg(1)*Carg(2)/ranger*S(", ")^0 )^1*endofstring 
function parsers.stepper(str,n,action)
 local ts=type(str)
 if type(n)=="function" then
  if ts=="number" then
   n(str)
  elseif ts=="table" then
   for i=1,#str do
    n(str[i])
   end
  else
   lpegmatch(stepper,str,1,false,n or print)
  end
 elseif ts=="string" then
  lpegmatch(stepper,str,1,n,action or print)
 end
end
local pattern_math=Cs((P("%")/"\\percent "+P("^")*Cc("{")*lpegpatterns.integer*Cc("}")+anything)^0)
local pattern_text=Cs((P("%")/"\\percent "+(P("^")/"\\high")*Cc("{")*lpegpatterns.integer*Cc("}")+anything)^0)
patterns.unittotex=pattern
function parsers.unittotex(str,textmode)
 return lpegmatch(textmode and pattern_text or pattern_math,str)
end
local pattern=Cs((P("^")/"<sup>"*lpegpatterns.integer*Cc("</sup>")+anything)^0)
function parsers.unittoxml(str)
 return lpegmatch(pattern,str)
end
local cache={}
local spaces=lpegpatterns.space^0
local dummy=function() end
setmetatableindex(cache,function(t,k)
 local separator=S(k) 
 local value=(1-separator)^0
 local pattern=spaces*C(value)*separator^0*Cp()
 t[k]=pattern
 return pattern
end)
local commalistiterator=cache[","]
function parsers.iterator(str,separator)
 local n=#str
 if n==0 then
  return dummy
 else
  local pattern=separator and cache[separator] or commalistiterator
  local p=1
  return function()
   if p<=n then
    local s,e=lpegmatch(pattern,str,p)
    if e then
     p=e
     return s
    end
   end
  end
 end
end
local function initialize(t,name)
 local source=t[name]
 if source then
  local result={}
  for k,v in next,t[name] do
   result[k]=v
  end
  return result
 else
  return {}
 end
end
local function fetch(t,name)
 return t[name] or {}
end
local function process(result,more)
 for k,v in next,more do
  result[k]=v
 end
 return result
end
local name=C((1-S(", "))^1)
local parser=(Carg(1)*name/initialize)*(S(", ")^1*(Carg(1)*name/fetch))^0
local merge=Cf(parser,process)
function parsers.mergehashes(hash,list)
 return lpegmatch(merge,list,1,hash)
end
function parsers.runtime(time)
 if not time then
  time=os.runtime()
 end
 local days=div(time,24*60*60)
 time=mod(time,24*60*60)
 local hours=div(time,60*60)
 time=mod(time,60*60)
 local minutes=div(time,60)
 local seconds=mod(time,60)
 return days,hours,minutes,seconds
end
local spacing=whitespace^0
local apply=P("->")
local method=C((1-apply)^1)
local token=lbrace*C((1-rbrace)^1)*rbrace+C(anything^1)
local pattern=spacing*(method*spacing*apply+Carg(1))*spacing*token
function parsers.splitmethod(str,default)
 if str then
  return lpegmatch(pattern,str,1,default or false)
 else
  return default or false,""
 end
end
local p_year=lpegpatterns.digit^4/tonumber
local pattern=Cf(Ct("")*(
  (Cg(Cc("year")*p_year)*S("-/")*Cg(Cc("month")*cardinal)*S("-/")*Cg(Cc("day")*cardinal)
  )+(Cg(Cc("day")*cardinal)*S("-/")*Cg(Cc("month")*cardinal)*S("-/")*Cg(Cc("year")*p_year)
  )+(Cg(Cc("year")*p_year)*S("-/")*Cg(Cc("month")*cardinal)
  )+(Cg(Cc("month")*cardinal)*S("-/")*Cg(Cc("year")*p_year)
  )
 )*(
   P(" ")*Cg(Cc("hour")*cardinal)*P(":")*Cg(Cc("min")*cardinal)*(P(":")*Cg(Cc("sec")*cardinal))^-1+P(-1) )
,rawset)
lpegpatterns.splittime=pattern
function parsers.totime(str)
 return lpegmatch(pattern,str)
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-dim']={
 version=1.001,
 comment="support for dimensions",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local format,match,gsub,type,setmetatable=string.format,string.match,string.gsub,type,setmetatable
local P,S,R,Cc,C,lpegmatch=lpeg.P,lpeg.S,lpeg.R,lpeg.Cc,lpeg.C,lpeg.match
local allocate=utilities.storage.allocate
local setmetatableindex=table.setmetatableindex
local formatters=string.formatters
local texget=tex and tex.get or function() return 65536*10*100 end
local p_stripzeros=lpeg.patterns.stripzeros
number=number or {}
local number=number
number.tonumberf=function(n) return lpegmatch(p_stripzeros,format("%.20f",n)) end
number.tonumberg=function(n) return format("%.20g",n) end
local dimenfactors=allocate {
 ["pt"]=1/65536,
 ["in"]=(100/7227)/65536,
 ["cm"]=(254/7227)/65536,
 ["mm"]=(2540/7227)/65536,
 ["sp"]=1,
 ["bp"]=(7200/7227)/65536,
 ["pc"]=(1/12)/65536,
 ["dd"]=(1157/1238)/65536,
 ["cc"]=(1157/14856)/65536,
 ["es"]=(9176/129)/65536,
 ["ts"]=(4588/645)/65536,
}
local f_none=formatters["%s%s"]
local f_true=formatters["%0.5F%s"]
local function numbertodimen(n,unit,fmt) 
 if type(n)=='string' then
  return n
 else
  unit=unit or 'pt'
  n=n*dimenfactors[unit]
  if not fmt then
   fmt=f_none(n,unit)
  elseif fmt==true then
   fmt=f_true(n,unit)
  else
   return formatters[fmt](n,unit)
  end
 end
end
number.maxdimen=1073741823
number.todimen=numbertodimen
number.dimenfactors=dimenfactors
function number.topoints   (n,fmt) return numbertodimen(n,"pt",fmt) end
function number.toinches   (n,fmt) return numbertodimen(n,"in",fmt) end
function number.tocentimeters (n,fmt) return numbertodimen(n,"cm",fmt) end
function number.tomillimeters (n,fmt) return numbertodimen(n,"mm",fmt) end
function number.toscaledpoints(n)  return   n.."sp"   end
function number.tobasepoints  (n,fmt) return numbertodimen(n,"bp",fmt) end
function number.topicas    (n,fmt) return numbertodimen(n "pc",fmt) end
function number.todidots   (n,fmt) return numbertodimen(n,"dd",fmt) end
function number.tociceros  (n,fmt) return numbertodimen(n,"cc",fmt) end
function number.toediths   (n,fmt) return numbertodimen(n,"es",fmt) end
function number.totoves    (n,fmt) return numbertodimen(n,"ts",fmt) end
local amount=(S("+-")^0*R("09")^0*P(".")^0*R("09")^0)+Cc("0")
local unit=R("az")^1+P("%")
local dimenpair=amount/tonumber*(unit^1/dimenfactors+Cc(1)) 
lpeg.patterns.dimenpair=dimenpair
local splitter=amount/tonumber*C(unit^1)
function number.splitdimen(str)
 return lpegmatch(splitter,str)
end
setmetatableindex(dimenfactors,function(t,s)
 return false
end)
local stringtodimen 
local amount=S("+-")^0*R("09")^0*S(".,")^0*R("09")^0
local unit=P("pt")+P("cm")+P("mm")+P("sp")+P("bp")+P("es")+P("ts")+P("pc")+P("dd")+P("cc")+P("in")
local validdimen=amount*unit
lpeg.patterns.validdimen=validdimen
local dimensions={}
function dimensions.__add(a,b)
 local ta,tb=type(a),type(b)
 if ta=="string" then a=stringtodimen(a) elseif ta=="table" then a=a[1] end
 if tb=="string" then b=stringtodimen(b) elseif tb=="table" then b=b[1] end
 return setmetatable({ a+b },dimensions)
end
function dimensions.__sub(a,b)
 local ta,tb=type(a),type(b)
 if ta=="string" then a=stringtodimen(a) elseif ta=="table" then a=a[1] end
 if tb=="string" then b=stringtodimen(b) elseif tb=="table" then b=b[1] end
 return setmetatable({ a-b },dimensions)
end
function dimensions.__mul(a,b)
 local ta,tb=type(a),type(b)
 if ta=="string" then a=stringtodimen(a) elseif ta=="table" then a=a[1] end
 if tb=="string" then b=stringtodimen(b) elseif tb=="table" then b=b[1] end
 return setmetatable({ a*b },dimensions)
end
function dimensions.__div(a,b)
 local ta,tb=type(a),type(b)
 if ta=="string" then a=stringtodimen(a) elseif ta=="table" then a=a[1] end
 if tb=="string" then b=stringtodimen(b) elseif tb=="table" then b=b[1] end
 return setmetatable({ a/b },dimensions)
end
function dimensions.__unm(a)
 local ta=type(a)
 if ta=="string" then a=stringtodimen(a) elseif ta=="table" then a=a[1] end
 return setmetatable({-a },dimensions)
end
function dimensions.__lt(a,b)
 return a[1]<b[1]
end
function dimensions.__eq(a,b)
 return a[1]==b[1]
end
function dimensions.__tostring(a)
 return a[1]/65536 .."pt" 
end
function dimensions.__index(tab,key)
 local d=dimenfactors[key]
 if not d then
  error("illegal property of dimen: "..key)
  d=1
 end
 return 1/d
end
   dimenfactors["ex"]=4/65536 
   dimenfactors["em"]=10/65536
   dimenfactors["eu"]=(9176/129)/65536
local known={} setmetatable(known,{ __mode="v" })
function dimen(a)
 if a then
  local ta=type(a)
  if ta=="string" then
   local k=known[a]
   if k then
    a=k
   else
    local value,unit=lpegmatch(dimenpair,a)
    if value and unit then
     k=value/unit 
    else
     k=0
    end
    known[a]=k
    a=k
   end
  elseif ta=="table" then
   a=a[1]
  end
  return setmetatable({ a },dimensions)
 else
  return setmetatable({ 0 },dimensions)
 end
end
function string.todimen(str) 
 local t=type(str)
 if t=="number" then
  return str
 else
  local k=known[str]
  if not k then
   if t=="string" then
    local value,unit=lpegmatch(dimenpair,str)
    if value and unit then
     k=value/unit 
    else
     k=0
    end
   else
    k=0
   end
   known[str]=k
  end
  return k
 end
end
stringtodimen=string.todimen 
function number.toscaled(d)
 return format("%0.5f",d/0x10000) 
end
function number.percent(n,d) 
 d=d or texget("hsize")
 if type(d)=="string" then
  d=stringtodimen(d)
 end
 return (n/100)*d
end
number["%"]=number.percent

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-jsn']={
 version=1.001,
 comment="companion to m-json.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
if utilities and utilities.json then
 return json
end
local P,V,R,S,C,Cc,Cs,Ct,Cf,Cg=lpeg.P,lpeg.V,lpeg.R,lpeg.S,lpeg.C,lpeg.Cc,lpeg.Cs,lpeg.Ct,lpeg.Cf,lpeg.Cg
local lpegmatch=lpeg.match
local format,gsub=string.format,string.gsub
local formatters=string.formatters
local utfchar=utf.char
local concat,sortedkeys=table.concat,table.sortedkeys
local tonumber,tostring,rawset,type,next=tonumber,tostring,rawset,type,next
local json=utilities.json or {}
utilities.json=json
do
 local lbrace=P("{")
 local rbrace=P("}")
 local lparent=P("[")
 local rparent=P("]")
 local comma=P(",")
 local colon=P(":")
 local dquote=P('"')
 local whitespace=lpeg.patterns.whitespace
 local optionalws=whitespace^0
 local escapes={
  ["b"]="\010",
  ["f"]="\014",
  ["n"]="\n",
  ["r"]="\r",
  ["t"]="\t",
 }
 local escape_un=P("\\u")/""*(C(R("09","AF","af")^-4)/function(s)
  return utfchar(tonumber(s,16))
 end)
 local escape_bs=P([[\]])/""*(P(1)/escapes) 
 local jstring=dquote*Cs((escape_un+escape_bs+(1-dquote))^0)*dquote
 local jtrue=P("true")*Cc(true)
 local jfalse=P("false")*Cc(false)
 local jnull=P("null")*Cc(nil)
 local jnumber=(1-whitespace-rparent-rbrace-comma)^1/tonumber
 local key=jstring
 local jsonconverter={ "value",
  hash=lbrace*Cf(Ct("")*(V("pair")*(comma*V("pair"))^0+optionalws),rawset)*rbrace,
  pair=Cg(optionalws*key*optionalws*colon*V("value")),
  array=Ct(lparent*(V("value")*(comma*V("value"))^0+optionalws)*rparent),
  value=optionalws*(jstring+V("hash")+V("array")+jtrue+jfalse+jnull+jnumber)*optionalws,
 }
 function json.tolua(str)
  return lpegmatch(jsonconverter,str)
 end
 function json.load(filename)
  local data=io.loaddata(filename)
  if data then
   return lpegmatch(jsonconverter,data)
  end
 end
end
do
 local escaper
 local f_start_hash=formatters[   '%w{' ]
 local f_start_array=formatters[   '%w[' ]
 local f_start_hash_new=formatters[ "\n"..'%w{' ]
 local f_start_array_new=formatters[ "\n"..'%w[' ]
 local f_start_hash_key=formatters[ "\n"..'%w"%s" : {' ]
 local f_start_array_key=formatters[ "\n"..'%w"%s" : [' ]
 local f_stop_hash=formatters[ "\n"..'%w}' ]
 local f_stop_array=formatters[ "\n"..'%w]' ]
 local f_key_val_seq=formatters[ "\n"..'%w"%s" : %s' ]
 local f_key_val_str=formatters[ "\n"..'%w"%s" : "%s"'  ]
 local f_key_val_num=f_key_val_seq
 local f_key_val_yes=formatters[ "\n"..'%w"%s" : true'  ]
 local f_key_val_nop=formatters[ "\n"..'%w"%s" : false' ]
 local f_key_val_null=formatters[ "\n"..'%w"%s" : null'  ]
 local f_val_num=formatters[ "\n"..'%w%s' ]
 local f_val_str=formatters[ "\n"..'%w"%s"'  ]
 local f_val_yes=formatters[ "\n"..'%wtrue'  ]
 local f_val_nop=formatters[ "\n"..'%wfalse' ]
 local f_val_null=formatters[ "\n"..'%wnull'  ]
 local f_val_empty=formatters[ "\n"..'%w{ }'  ]
 local f_val_seq=f_val_num
 local t={}
 local n=0
 local function is_simple_table(tt) 
  local l=#tt
  if l>0 then
   for i=1,l do
    if type(tt[i])=="table" then
     return false
    end
   end
   local nn=n
   n=n+1 t[n]="[ "
   for i=1,l do
    if i>1 then
     n=n+1 t[n]=", "
    end
    local v=tt[i]
    local tv=type(v)
    if tv=="number" then
     n=n+1 t[n]=v
    elseif tv=="string" then
     n=n+1 t[n]='"'
     n=n+1 t[n]=lpegmatch(escaper,v) or v
     n=n+1 t[n]='"'
    elseif tv=="boolean" then
     n=n+1 t[n]=v and "true" or "false"
    elseif v then
     n=n+1 t[n]=tostring(v)
    else
     n=n+1 t[n]="null"
    end
   end
   n=n+1 t[n]=" ]"
   local s=concat(t,"",nn+1,n)
   n=nn
   return s
  end
  return false
 end
 local function tojsonpp(root,name,depth,level,size)
  if root then
   local indexed=size>0
   n=n+1
   if level==0 then
    if indexed then
     t[n]=f_start_array(depth)
    else
     t[n]=f_start_hash(depth)
    end
   elseif name then
    if tn=="string" then
     name=lpegmatch(escaper,name) or name
    elseif tn~="number" then
     name=tostring(name)
    end
    if indexed then
     t[n]=f_start_array_key(depth,name)
    else
     t[n]=f_start_hash_key(depth,name)
    end
   else
    if indexed then
     t[n]=f_start_array_new(depth)
    else
     t[n]=f_start_hash_new(depth)
    end
   end
   depth=depth+1
   if indexed then 
    for i=1,size do
     if i>1 then
      n=n+1 t[n]=","
     end
     local v=root[i]
     local tv=type(v)
     if tv=="number" then
      n=n+1 t[n]=f_val_num(depth,v)
     elseif tv=="string" then
      v=lpegmatch(escaper,v) or v
      n=n+1 t[n]=f_val_str(depth,v)
     elseif tv=="table" then
      if next(v) then
       local st=is_simple_table(v)
       if st then
        n=n+1 t[n]=f_val_seq(depth,st)
       else
        tojsonpp(v,nil,depth,level+1,#v)
       end
      else
       n=n+1
       t[n]=f_val_empty(depth)
      end
     elseif tv=="boolean" then
      n=n+1
      if v then
       t[n]=f_val_yes(depth,v)
      else
       t[n]=f_val_nop(depth,v)
      end
     else
      n=n+1
      t[n]=f_val_null(depth)
     end
    end
   elseif next(root) then
    local sk=sortedkeys(root)
    for i=1,#sk do
     if i>1 then
      n=n+1 t[n]=","
     end
     local k=sk[i]
     local v=root[k]
     local tv=type(v)
     local tk=type(k)
     if tv=="number" then
      if tk=="number" then
       n=n+1 t[n]=f_key_val_num(depth,k,v)
      elseif tk=="string" then
       k=lpegmatch(escaper,k) or k
       n=n+1 t[n]=f_key_val_num(depth,k,v)
      end
     elseif tv=="string" then
      if tk=="number" then
       v=lpegmatch(escaper,v) or v
       n=n+1 t[n]=f_key_val_str(depth,k,v)
      elseif tk=="string" then
       k=lpegmatch(escaper,k) or k
       v=lpegmatch(escaper,v) or v
       n=n+1 t[n]=f_key_val_str(depth,k,v)
      elseif i>1 then
       n=n-1
      end
     elseif tv=="table" then
      local l=#v
      if l>0 then
       local st=is_simple_table(v)
       if not st then
        tojsonpp(v,k,depth,level+1,l)
       elseif tk=="number" then
        n=n+1 t[n]=f_key_val_seq(depth,k,st)
       elseif tk=="string" then
        k=lpegmatch(escaper,k) or k
        n=n+1 t[n]=f_key_val_seq(depth,k,st)
       end
      elseif next(v) then
       tojsonpp(v,k,depth,level+1,0)
      elseif i>1 then
       n=n-1
      end
     elseif tv=="boolean" then
      if tk=="number" then
       n=n+1
       if v then
        t[n]=f_key_val_yes(depth,k)
       else
        t[n]=f_key_val_nop(depth,k)
       end
      elseif tk=="string" then
       k=lpegmatch(escaper,k) or k
       n=n+1
       if v then
        t[n]=f_key_val_yes(depth,k)
       else
        t[n]=f_key_val_nop(depth,k)
       end
      elseif i>1 then
       n=n-1
      end
     else
      if tk=="number" then
       n=n+1
       t[n]=f_key_val_null(depth,k)
      elseif tk=="string" then
       k=lpegmatch(escaper,k) or k
       n=n+1
       t[n]=f_key_val_null(depth,k)
      elseif i>1 then
       n=n-1
      end
     end
    end
   end
   n=n+1
   if indexed then
    t[n]=f_stop_array(depth-1)
   else
    t[n]=f_stop_hash(depth-1)
   end
  end
 end
 local function tojson(value,n)
  local kind=type(value)
  if kind=="table" then
   local done=false
   local size=#value
   if size==0 then
    for k,v in next,value do
     if done then
      n=n+1;t[n]=',"'
     else
      n=n+1;t[n]='{"'
      done=true
     end
     n=n+1;t[n]=lpegmatch(escaper,k) or k
     n=n+1;t[n]='":'
     t,n=tojson(v,n)
    end
    if done then
     n=n+1;t[n]="}"
    else
     n=n+1;t[n]="{}"
    end
   elseif size==1 then
    n=n+1;t[n]="["
    t,n=tojson(value[1],n)
    n=n+1;t[n]="]"
   else
    for i=1,size do
     if done then
      n=n+1;t[n]=","
     else
      n=n+1;t[n]="["
      done=true
     end
     t,n=tojson(value[i],n)
    end
    n=n+1;t[n]="]"
   end
  elseif kind=="string"  then
   n=n+1;t[n]='"'
   n=n+1;t[n]=lpegmatch(escaper,value) or value
   n=n+1;t[n]='"'
  elseif kind=="number" then
   n=n+1;t[n]=value
  elseif kind=="boolean" then
   n=n+1;t[n]=tostring(value)
  else
   n=n+1;t[n]="null"
  end
  return t,n
 end
 local function jsontostring(value,pretty)
  local kind=type(value)
  if kind=="table" then
   if not escaper then
    local escapes={
     ["\\"]="\\u005C",
     ["\""]="\\u0022",
    }
    for i=0,0x1F do
     escapes[utfchar(i)]=format("\\u%04X",i)
    end
    escaper=Cs((
     (R('\0\x20')+S('\"\\'))/escapes+P(1)
    )^1 )
   end
   t={}
   n=0
   if pretty then
    tojsonpp(value,name,0,0,#value)
    value=concat(t,"",1,n)
   else
    t,n=tojson(value,0)
    value=concat(t,"",1,n)
   end
   t=nil
   n=0
   return value
  elseif kind=="string" or kind=="number" then
   return lpegmatch(escaper,value) or value
  else
   return tostring(value)
  end
 end
 json.tostring=jsontostring
 function json.tojson(value)
  return jsontostring(value,true)
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['trac-inf']={
 version=1.001,
 comment="companion to trac-inf.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local type,tonumber,select=type,tonumber,select
local format,lower,find=string.format,string.lower,string.find
local concat=table.concat
local clock=os.gettimeofday or os.clock 
local setmetatableindex=table.setmetatableindex
local serialize=table.serialize
local formatters=string.formatters
statistics=statistics or {}
local statistics=statistics
statistics.enable=true
statistics.threshold=0.01
local statusinfo,n,registered,timers={},0,{},{}
setmetatableindex(timers,function(t,k)
 local v={ timing=0,loadtime=0,offset=0 }
 t[k]=v
 return v
end)
local function hastiming(instance)
 return instance and timers[instance]
end
local function resettiming(instance)
 timers[instance or "notimer"]={ timing=0,loadtime=0,offset=0 }
end
local ticks=clock
local seconds=function(n) return n or 0 end
if os.type~="windows" then
elseif lua.getpreciseticks then
 ticks=lua.getpreciseticks
 seconds=lua.getpreciseseconds
elseif FFISUPPORTED then
 local okay,kernel=pcall(ffi.load,"kernel32")
 if kernel then
  local tonumber=ffi.number or tonumber
  ffi.cdef[[
            int QueryPerformanceFrequency(int64_t *lpFrequency);
            int QueryPerformanceCounter(int64_t *lpPerformanceCount);
        ]]
  local target=ffi.new("__int64[1]")
  ticks=function()
   if kernel.QueryPerformanceCounter(target)==1 then
    return tonumber(target[0])
   else
    return 0
   end
  end
  local target=ffi.new("__int64[1]")
  seconds=function(ticks)
   if kernel.QueryPerformanceFrequency(target)==1 then
    return ticks/tonumber(target[0])
   else
    return 0
   end
  end
 end
else
end
local function starttiming(instance,reset)
 local timer=timers[instance or "notimer"]
 local it=timer.timing
 if reset then
  it=0
  timer.loadtime=0
 end
 if it==0 then
  timer.starttime=ticks()
  if not timer.loadtime then
   timer.loadtime=0
  end
 end
 timer.timing=it+1
end
local function stoptiming(instance)
 local timer=timers[instance or "notimer"]
 local it=timer.timing
 if it>1 then
  timer.timing=it-1
 else
  local starttime=timer.starttime
  if starttime and starttime>0 then
   local stoptime=ticks()
   local loadtime=stoptime-starttime
   timer.stoptime=stoptime
   timer.loadtime=timer.loadtime+loadtime
   timer.timing=0
   timer.starttime=0
  end
 end
end
local function benchmarktimer(instance)
 local timer=timers[instance or "notimer"]
 local it=timer.timing
 if it>1 then
  timer.timing=it-1
 else
  local starttime=timer.starttime
  if starttime and starttime>0 then
   timer.offset=ticks()-starttime
  else
   timer.offset=0
  end
 end
end
local function elapsed(instance)
 if type(instance)=="number" then
  return instance
 else
  local timer=timers[instance or "notimer"]
  return timer and seconds(timer.loadtime-2*(timer.offset or 0)) or 0
 end
end
local function currenttime(instance)
 if type(instance)=="number" then
  return instance
 else
  local timer=timers[instance or "notimer"]
  local it=timer.timing
  if it>1 then
  else
   local starttime=timer.starttime
   if starttime and starttime>0 then
    return seconds(timer.loadtime+ticks()-starttime-2*(timer.offset or 0))
   end
  end
  return 0
 end
end
local function elapsedtime(instance)
 return format("%0.3f",elapsed(instance))
end
local function elapsedindeed(instance)
 return elapsed(instance)>statistics.threshold
end
local function elapsedseconds(instance,rest) 
 if elapsedindeed(instance) then
  return format("%0.3f seconds %s",elapsed(instance),rest or "")
 end
end
statistics.hastiming=hastiming
statistics.resettiming=resettiming
statistics.starttiming=starttiming
statistics.stoptiming=stoptiming
statistics.currenttime=currenttime
statistics.elapsed=elapsed
statistics.elapsedtime=elapsedtime
statistics.elapsedindeed=elapsedindeed
statistics.elapsedseconds=elapsedseconds
statistics.benchmarktimer=benchmarktimer
function statistics.register(tag,fnc)
 if statistics.enable and type(fnc)=="function" then
  local rt=registered[tag] or (#statusinfo+1)
  statusinfo[rt]={ tag,fnc }
  registered[tag]=rt
  if #tag>n then n=#tag end
 end
end
local report=logs.reporter("mkiv lua stats")
function statistics.show()
 if statistics.enable then
  local register=statistics.register
  register("used platform",function()
   return format("%s, type: %s, binary subtree: %s",
    os.platform or "unknown",os.type or "unknown",environment.texos or "unknown")
  end)
  register("used engine",function()
   return format("%s version: %s, functionality level: %s, banner: %s",
    LUATEXENGINE,LUATEXVERSION,LUATEXFUNCTIONALITY,lower(status.banner))
  end)
  register("used hash slots",function()
   return format("%s of %s + %s",status.cs_count,status.hash_size,status.hash_extra)
  end)
  register("callbacks",statistics.callbacks)
  if JITSUPPORTED then
   local jitstatus=jit.status
   if jitstatus then
    local jitstatus={ jitstatus() }
    if jitstatus[1] then
     register("luajit options",concat(jitstatus," ",2))
    end
   end
  end
  register("lua properties",function()
   local hash=2^status.luatex_hashchars
   local mask=load([[τεχ = 1]]) and "utf" or "ascii"
   return format("engine: %s %s, used memory: %s, hash chars: min(%i,40), symbol mask: %s (%s)",
    jit and "luajit" or "lua",LUAVERSION,statistics.memused(),hash,mask,mask=="utf" and "τεχ" or "tex")
  end)
  register("runtime",statistics.runtime)
  logs.newline() 
  for i=1,#statusinfo do
   local s=statusinfo[i]
   local r=s[2]()
   if r then
    report("%s: %s",s[1],r)
   end
  end
  statistics.enable=false
 end
end
function statistics.memused() 
 local round=math.round or math.floor
 return format("%s MB, ctx: %s MB, max: %s MB",
  round(collectgarbage("count")/1000),
  round(status.luastate_bytes/1000000),
  status.luastate_bytes_max and round(status.luastate_bytes_max/1000000) or "unknown"
 )
end
starttiming(statistics)
function statistics.formatruntime(runtime) 
 return format("%s seconds",runtime)   
end
function statistics.runtime()
 stoptiming(statistics)
 local runtime=lua.getruntime and lua.getruntime() or elapsedtime(statistics)
 return statistics.formatruntime(runtime)
end
local report=logs.reporter("system")
function statistics.timed(action,all)
 starttiming("run")
 action()
 stoptiming("run")
 local runtime=tonumber(elapsedtime("run"))
 if all then
  local alltime=tonumber(lua.getruntime and lua.getruntime() or elapsedtime(statistics))
  if alltime and alltime>0 then
   report("total runtime: %0.3f seconds of %0.3f seconds",runtime,alltime)
   return
  end
 end
 report("total runtime: %0.3f seconds",runtime)
end
function statistics.tracefunction(base,tag,...)
 for i=1,select("#",...) do
  local name=select(i,...)
  local stat={}
  local func=base[name]
  setmetatableindex(stat,function(t,k) t[k]=0 return 0 end)
  base[name]=function(n,k,v) stat[k]=stat[k]+1 return func(n,k,v) end
  statistics.register(formatters["%s.%s"](tag,name),function() return serialize(stat,"calls") end)
 end
end
function status.getreadstate()
 return {
  filename=status.filename   or "?",
  linenumber=status.linenumber or 0,
  iocode=status.inputid or 0,
 }
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-lua']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 comment="the strip code is written by Peter Cawley",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local rep,sub,byte,dump,format=string.rep,string.sub,string.byte,string.dump,string.format
local load,loadfile,type,collectgarbage=load,loadfile,type,collectgarbage
utilities=utilities or {}
utilities.lua=utilities.lua or {}
local luautilities=utilities.lua
local report_lua=logs.reporter("system","lua")
local report_mem=logs.reporter("system","lua memory")
local tracestripping=false
local tracememory=false
luautilities.stripcode=true  
luautilities.alwaysstripcode=false 
luautilities.nofstrippedchunks=0
luautilities.nofstrippedbytes=0
local strippedchunks={} 
luautilities.strippedchunks=strippedchunks
if not LUATEXENGINE then
 LUATEXENGINE=status.luatex_engine and string.lower(status.luatex_engine)
 JITSUPPORTED=LUATEXENGINE=="luajittex" or jit
 CONTEXTLMTXMODE=CONTEXTLMTXMODE or (LUATEXENGINE=="luametatex" and 1) or 0
end
luautilities.suffixes={
 tma="tma",
 tmc=(CONTEXTLMTXMODE and CONTEXTLMTXMODE>0 and "tmd") or (jit and "tmb") or "tmc",
 lua="lua",
 luc=(CONTEXTLMTXMODE and CONTEXTLMTXMODE>0 and "lud") or (jit and "lub") or "luc",
 lui="lui",
 luv="luv",
 luj="luj",
 tua="tua",
 tuc=(CONTEXTLMTXMODE and CONTEXTLMTXMODE>0 and "tud") or (jit and "tub") or "tuc",
}
local function register(name) 
 if tracestripping then
  report_lua("stripped bytecode from %a",name or "unknown")
 end
 strippedchunks[#strippedchunks+1]=name
 luautilities.nofstrippedchunks=luautilities.nofstrippedchunks+1
end
local function stupidcompile(luafile,lucfile,strip)
 local code=io.loaddata(luafile)
 if code and code~="" then
  code=load(code)
  if code then
   code=dump(code,strip and luautilities.stripcode or luautilities.alwaysstripcode)
   if code and code~="" then
    register(name)
    io.savedata(lucfile,code)
    return true,0
   end
  else
   report_lua("fatal error %a in file %a",1,luafile)
  end
 else
  report_lua("fatal error %a in file %a",2,luafile)
 end
 return false,0
end
function luautilities.loadedluacode(fullname,forcestrip,name,macros)
 name=name or fullname
 if macros then
  macros=lua.macros
 end
 local code,message
 if macros then
  code,message=macros.loaded(fullname,true,false)
 else
  code,message=loadfile(fullname)
 end
 if code then
  code()
 else
  report_lua("loading of file %a failed:\n\t%s",fullname,message or "no message")
  code,message=loadfile(fullname)
 end
 if forcestrip and luautilities.stripcode then
  if type(forcestrip)=="function" then
   forcestrip=forcestrip(fullname)
  end
  if forcestrip or luautilities.alwaysstripcode then
   register(name)
   return load(dump(code,true)),0
  else
   return code,0
  end
 elseif luautilities.alwaysstripcode then
  register(name)
  return load(dump(code,true)),0
 else
  return code,0
 end
end
function luautilities.strippedloadstring(code,name,forcestrip) 
 local code,message=load(code)
 if not code then
  report_lua("loading of file %a failed:\n\t%s",name,message or "no message")
 end
 if forcestrip and luautilities.stripcode or luautilities.alwaysstripcode then
  register(name)
  return load(dump(code,true)),0 
 else
  return code,0
 end
end
function luautilities.loadstring(code,name) 
 local code,message=load(code)
 if not code then
  report_lua("loading of file %a failed:\n\t%s",name,message or "no message")
 end
 return code,0
end
function luautilities.compile(luafile,lucfile,cleanup,strip,fallback) 
 report_lua("compiling %a into %a",luafile,lucfile)
 os.remove(lucfile)
 local done=stupidcompile(luafile,lucfile,strip~=false)
 if done then
  report_lua("dumping %a into %a stripped",luafile,lucfile)
  if cleanup==true and lfs.isfile(lucfile) and lfs.isfile(luafile) then
   report_lua("removing %a",luafile)
   os.remove(luafile)
  end
 end
 return done
end
function luautilities.loadstripped(...)
 local l=load(...)
 if l then
  return load(dump(l,true))
 end
end
local finalizers={}
setmetatable(finalizers,{
 __gc=function(t)
  for i=1,#t do
   pcall(t[i]) 
  end
 end
} )
function luautilities.registerfinalizer(f)
 finalizers[#finalizers+1]=f
end
function luautilities.checkmemory(previous,threshold,trace) 
 local current=collectgarbage("count")
 if previous then
  local checked=(threshold or 64)*1024
  local delta=current-previous
  if current-previous>checked then
   collectgarbage("collect")
   local afterwards=collectgarbage("count")
   if trace or tracememory then
    report_mem("previous %r MB, current %r MB, delta %r MB, threshold %r MB, afterwards %r MB",
     previous/1024,current/1024,delta/1024,threshold,afterwards)
   end
   return afterwards
  elseif trace or tracememory then
   report_mem("previous %r MB, current %r MB, delta %r MB, threshold %r MB",
    previous/1024,current/1024,delta/1024,threshold)
  end
 end
 return current
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-deb']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local type,next,tostring,tonumber=type,next,tostring,tonumber
local format,find,sub,gsub=string.format,string.find,string.sub,string.gsub
local insert,remove,sort=table.insert,table.remove,table.sort
local setmetatableindex=table.setmetatableindex
utilities=utilities or {}
local debugger=utilities.debugger or {}
utilities.debugger=debugger
local report=logs.reporter("debugger")
local ticks=os.gettimeofday or os.clock
local seconds=function(n) return n or 0 end
local overhead=0
local dummycalls=10*1000
local nesting=0
local names={}
local initialize=false
if lua.getpreciseticks then
 initialize=function()
  ticks=lua.getpreciseticks
  seconds=lua.getpreciseseconds
  initialize=false
 end
elseif not (FFISUPPORTED and ffi) then
elseif os.type=="windows" then
 initialize=function()
  local kernel=ffilib("kernel32","system") 
  if kernel then
   local tonumber=ffi.number or tonumber
   ffi.cdef[[
                int QueryPerformanceFrequency(int64_t *lpFrequency);
                int QueryPerformanceCounter(int64_t *lpPerformanceCount);
            ]]
   local target=ffi.new("__int64[1]")
   ticks=function()
    if kernel.QueryPerformanceCounter(target)==1 then
     return tonumber(target[0])
    else
     return 0
    end
   end
   local target=ffi.new("__int64[1]")
   seconds=function(ticks)
    if kernel.QueryPerformanceFrequency(target)==1 then
     return ticks/tonumber(target[0])
    else
     return 0
    end
   end
  end
  initialize=false
 end
elseif os.type=="unix" then
 initialize=function()
  local C=ffi.C
  local tonumber=ffi.number or tonumber
  ffi.cdef [[
            /* what a mess */
            typedef int clk_id_t;
            typedef enum { CLOCK_REALTIME, CLOCK_MONOTONIC, CLOCK_PROCESS_CPUTIME_ID } clk_id;
            typedef struct timespec { long sec; long nsec; } ctx_timespec;
            int clock_gettime(clk_id_t timerid, struct timespec *t);
        ]]
  local target=ffi.new("ctx_timespec[?]",1)
  local clock=C.CLOCK_PROCESS_CPUTIME_ID
  ticks=function ()
   C.clock_gettime(clock,target)
   return tonumber(target[0].sec*1000000000+target[0].nsec)
  end
  seconds=function(ticks)
   return ticks/1000000000
  end
  initialize=false
 end
end
setmetatableindex(names,function(t,name)
 local v=setmetatableindex(function(t,source)
  local v=setmetatableindex(function(t,line)
   local v={ total=0,count=0,nesting=0 }
   t[line]=v
   return v
  end)
  t[source]=v
  return v
 end)
 t[name]=v
 return v
end)
local getinfo=nil
local sethook=nil
local function hook(where)
 local f=getinfo(2,"nSl")
 if f then
  local source=f.short_src
  if not source then
   return
  end
  local line=f.linedefined or 0
  local name=f.name
  if not name then
   local what=f.what
   if what=="C" then
    name="<anonymous>"
   else
    name=f.namewhat or what or "<unknown>"
   end
  end
  local data=names[name][source][line]
  if where=="call" then
   local nesting=data.nesting
   if nesting==0 then
    data.count=data.count+1
    insert(data,ticks())
    data.nesting=1
   else
    data.nesting=nesting+1
   end
  elseif where=="return" then
   local nesting=data.nesting
   if nesting==1 then
    local t=remove(data)
    if t then
     data.total=data.total+ticks()-t
    end
    data.nesting=0
   else
    data.nesting=nesting-1
   end
  end
 end
end
function debugger.showstats(printer,threshold)
 local printer=printer or report
 local calls=0
 local functions=0
 local dataset={}
 local length=0
 local realtime=0
 local totaltime=0
 local threshold=threshold or 0
 for name,sources in next,names do
  for source,lines in next,sources do
   for line,data in next,lines do
    local count=data.count
    if count>threshold then
     if #name>length then
      length=#name
     end
     local total=data.total
     local real=total
     if real>0 then
      real=total-(count*overhead/dummycalls)
      if real<0 then
       real=0
      end
      realtime=realtime+real
     end
     totaltime=totaltime+total
     if line<0 then
      line=0
     end
     dataset[#dataset+1]={ real,total,count,name,source,line }
    end
   end
  end
 end
 sort(dataset,function(a,b)
  if a[1]==b[1] then
   if a[2]==b[2] then
    if a[3]==b[3] then
     if a[4]==b[4] then
      if a[5]==b[5] then
       return a[6]<b[6]
      else
       return a[5]<b[5]
      end
     else
      return a[4]<b[4]
     end
    else
     return b[3]<a[3]
    end
   else
    return b[2]<a[2]
   end
  else
   return b[1]<a[1]
  end
 end)
 if length>50 then
  length=50
 end
 local fmt=string.formatters["%4.9k s  %3.3k %%  %4.9k s  %3.3k %%  %8i #  %-"..length.."s  %4i  %s"]
 for i=1,#dataset do
  local data=dataset[i]
  local real=data[1]
  local total=data[2]
  local count=data[3]
  local name=data[4]
  local source=data[5]
  local line=data[6]
  calls=calls+count
  functions=functions+1
  name=gsub(name,"%s+"," ")
  if #name>length then
   name=sub(name,1,length)
  end
  printer(fmt(seconds(total),100*total/totaltime,seconds(real),100*real/realtime,count,name,line,source))
 end
 printer("")
 printer(format("functions : %i",functions))
 printer(format("calls     : %i",calls))
 printer(format("overhead  : %f",seconds(overhead/1000)))
end
local function getdebug()
 if sethook and getinfo then
  return
 end
 if not debug then
  local okay
  okay,debug=pcall(require,"debug")
 end
 if type(debug)~="table" then
  return
 end
 getinfo=debug.getinfo
 sethook=debug.sethook
 if type(getinfo)~="function" then
  getinfo=nil
 end
 if type(sethook)~="function" then
  sethook=nil
 end
end
function debugger.savestats(filename,threshold)
 local f=io.open(filename,'w')
 if f then
  debugger.showstats(function(str) f:write(str,"\n") end,threshold)
  f:close()
 end
end
function debugger.enable()
 getdebug()
 if sethook and getinfo and nesting==0 then
  running=true
  if initialize then
   initialize()
  end
  sethook(hook,"cr")
  local function dummy() end
  local t=ticks()
  for i=1,dummycalls do
   dummy()
  end
  overhead=ticks()-t
 end
 if nesting>0 then
  nesting=nesting+1
 end
end
function debugger.disable()
 if nesting>0 then
  nesting=nesting-1
 end
 if sethook and getinfo and nesting==0 then
  sethook()
 end
end
local function showtraceback(rep) 
 getdebug()
 if getinfo then
  local level=2 
  local reporter=rep or report
  while true do
   local info=getinfo(level,"Sl")
   if not info then
    break
   elseif info.what=="C" then
    reporter("%2i : %s",level-1,"C function")
   else
    reporter("%2i : %s : %s",level-1,info.short_src,info.currentline)
   end
   level=level+1
  end
 end
end
debugger.showtraceback=showtraceback
if luac then
 local show,dump=luac.print,string.dump
 function luac.inspect(v)
  if type(v)=="function" then
   local ok,str=xpcall(dump,function() end,v)
   if ok then
    v=str
   end
  end
  if type(v)=="string" then
   show(v,true)
  else
   print(v)
  end
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-tpl']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
utilities.templates=utilities.templates or {}
local templates=utilities.templates
local trace_template=false  trackers.register("templates.trace",function(v) trace_template=v end)
local report_template=logs.reporter("template")
local tostring,next=tostring,next
local format,sub,byte=string.format,string.sub,string.byte
local P,C,R,Cs,Cc,Carg,lpegmatch,lpegpatterns=lpeg.P,lpeg.C,lpeg.R,lpeg.Cs,lpeg.Cc,lpeg.Carg,lpeg.match,lpeg.patterns
local formatters=string.formatters
local replacer
local function replacekey(k,t,how,recursive)
 local v=t[k]
 if not v then
  if trace_template then
   report_template("unknown key %a",k)
  end
  return ""
 else
  v=tostring(v)
  if trace_template then
   report_template("setting key %a to value %a",k,v)
  end
  if recursive then
   return lpegmatch(replacer,v,1,t,how,recursive)
  else
   return v
  end
 end
end
local sqlescape=lpeg.replacer {
 { "'","''"   },
 { "\\","\\\\" },
 { "\r\n","\\n"  },
 { "\r","\\n"  },
}
local sqlquoted=Cs(Cc("'")*sqlescape*Cc("'"))
lpegpatterns.sqlescape=sqlescape
lpegpatterns.sqlquoted=sqlquoted
local luaescape=lpegpatterns.luaescape
local escapers={
 lua=function(s)
  return lpegmatch(luaescape,s)
 end,
 sql=function(s)
  return lpegmatch(sqlescape,s)
 end,
}
local quotedescapers={
 lua=function(s)
  return format("%q",s)
 end,
 sql=function(s)
  return lpegmatch(sqlquoted,s)
 end,
}
local luaescaper=escapers.lua
local quotedluaescaper=quotedescapers.lua
local function replacekeyunquoted(s,t,how,recurse) 
 if how==false then
  return replacekey(s,t,how,recurse)
 else
  local escaper=how and escapers[how] or luaescaper
  return escaper(replacekey(s,t,how,recurse))
 end
end
local function replacekeyquoted(s,t,how,recurse) 
 if how==false then
  return replacekey(s,t,how,recurse)
 else
  local escaper=how and quotedescapers[how] or quotedluaescaper
  return escaper(replacekey(s,t,how,recurse))
 end
end
local function replaceoptional(l,m,r,t,how,recurse)
 local v=t[l]
 return v and v~="" and lpegmatch(replacer,r,1,t,how or "lua",recurse or false) or ""
end
local function replaceformatted(l,m,r,t,how,recurse)
 local v=t[r]
 return v and formatters[l](v)
end
local single=P("%")  
local double=P("%%") 
local lquoted=P("%[") 
local rquoted=P("]%") 
local lquotedq=P("%(") 
local rquotedq=P(")%") 
local escape=double/'%%'
local nosingle=single/''
local nodouble=double/''
local nolquoted=lquoted/''
local norquoted=rquoted/''
local nolquotedq=lquotedq/''
local norquotedq=rquotedq/''
local nolformatted=P(":")/"%%"
local norformatted=P(":")/""
local noloptional=P("%?")/''
local noroptional=P("?%")/''
local nomoptional=P(":")/''
local args=Carg(1)*Carg(2)*Carg(3)
local key=nosingle*((C((1-nosingle)^1)*args)/replacekey)*nosingle
local quoted=nolquotedq*((C((1-norquotedq)^1)*args)/replacekeyquoted)*norquotedq
local unquoted=nolquoted*((C((1-norquoted)^1)*args)/replacekeyunquoted)*norquoted
local optional=noloptional*((C((1-nomoptional)^1)*nomoptional*C((1-noroptional)^1)*args)/replaceoptional)*noroptional
local formatted=nosingle*((Cs(nolformatted*(1-norformatted )^1)*norformatted*C((1-nosingle)^1)*args)/replaceformatted)*nosingle
local any=P(1)
   replacer=Cs((unquoted+quoted+formatted+escape+optional+key+any)^0)
local function replace(str,mapping,how,recurse)
 if mapping and str then
  return lpegmatch(replacer,str,1,mapping,how or "lua",recurse or false) or str
 else
  return str
 end
end
templates.replace=replace
function templates.replacer(str,how,recurse) 
 return function(mapping)
  return lpegmatch(replacer,str,1,mapping,how or "lua",recurse or false) or str
 end
end
function templates.load(filename,mapping,how,recurse)
 local data=io.loaddata(filename) or ""
 if mapping and next(mapping) then
  return replace(data,mapping,how,recurse)
 else
  return data
 end
end
function templates.resolve(t,mapping,how,recurse)
 if not mapping then
  mapping=t
 end
 for k,v in next,t do
  t[k]=replace(v,mapping,how,recurse)
 end
 return t
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-sta']={
 version=1.001,
 comment="companion to util-ini.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local insert,remove,fastcopy,concat=table.insert,table.remove,table.fastcopy,table.concat
local format=string.format
local select,tostring=select,tostring
local trace_stacker=false  trackers.register("stacker.resolve",function(v) trace_stacker=v end)
local stacker=stacker or {}
utilities.stacker=stacker
local function start(s,t,first,last)
 if s.mode=="switch" then
  local n=tostring(t[last])
  if trace_stacker then
   s.report("start: %s",n)
  end
  return n
 else
  local r={}
  for i=first,last do
   r[#r+1]=tostring(t[i])
  end
  local n=concat(r," ")
  if trace_stacker then
   s.report("start: %s",n)
  end
  return n
 end
end
local function stop(s,t,first,last)
 if s.mode=="switch" then
  local n=tostring(false)
  if trace_stacker then
   s.report("stop: %s",n)
  end
  return n
 else
  local r={}
  for i=last,first,-1 do
   r[#r+1]=tostring(false)
  end
  local n=concat(r," ")
  if trace_stacker then
   s.report("stop: %s",n)
  end
  return n
 end
end
local function change(s,t1,first1,last1,t2,first2,last2)
 if s.mode=="switch" then
  local n=tostring(t2[last2])
  if trace_stacker then
   s.report("change: %s",n)
  end
  return n
 else
  local r={}
  for i=last1,first1,-1 do
   r[#r+1]=tostring(false)
  end
  local n=concat(r," ")
  for i=first2,last2 do
   r[#r+1]=tostring(t2[i])
  end
  if trace_stacker then
   s.report("change: %s",n)
  end
  return n
 end
end
function stacker.new(name)
 local report=logs.reporter("stacker",name or nil)
 local s
 local stack={}
 local list={}
 local ids={}
 local hash={}
 local hashing=true
 local function push(...)
  for i=1,select("#",...) do
   insert(stack,(select(i,...))) 
  end
  if hashing then
   local c=concat(stack,"|")
   local n=hash[c]
   if not n then
    n=#list+1
    hash[c]=n
    list[n]=fastcopy(stack)
   end
   insert(ids,n)
   return n
  else
   local n=#list+1
   list[n]=fastcopy(stack)
   insert(ids,n)
   return n
  end
 end
 local function pop()
  remove(stack)
  remove(ids)
  return ids[#ids] or s.unset or -1
 end
 local function clean()
  if #stack==0 then
   if trace_stacker then
    s.report("%s list entries, %s stack entries",#list,#stack)
   end
  end
 end
 local tops={}
 local top=nil
 local switch=nil
 local function resolve_reset(mode)
  if #tops>0 then
   report("resetting %s left-over states of %a",#tops,name)
  end
  tops={}
  top=nil
  switch=nil
 end
 local function resolve_begin(mode)
  if mode then
   switch=mode=="switch"
  else
   switch=s.mode=="switch"
  end
  top={ switch=switch }
  insert(tops,top)
 end
 local function resolve_step(ti)
  if not top then
   return
  end
  local result=nil
  local noftop=#top
  if ti>0 then
   local current=list[ti]
   if current then
    local noflist=#current
    local nofsame=0
    if noflist>noftop then
     for i=1,noflist do
      if current[i]==top[i] then
       nofsame=i
      else
       break
      end
     end
    else
     for i=1,noflist do
      if current[i]==top[i] then
       nofsame=i
      else
       break
      end
     end
    end
    local plus=nofsame+1
    if plus<=noftop then
     if plus<=noflist then
      if switch then
       result=s.change(s,top,plus,noftop,current,nofsame,noflist)
      else
       result=s.change(s,top,plus,noftop,current,plus,noflist)
      end
     else
      if switch then
       result=s.change(s,top,plus,noftop,current,nofsame,noflist)
      else
       result=s.stop(s,top,plus,noftop)
      end
     end
    elseif plus<=noflist then
     if switch then
      result=s.start(s,current,nofsame,noflist)
     else
      result=s.start(s,current,plus,noflist)
     end
    end
    top=current
   else
    if 1<=noftop then
     result=s.stop(s,top,1,noftop)
    end
    top={}
   end
   return result
  else
   if 1<=noftop then
    result=s.stop(s,top,1,noftop)
   end
   top={}
   return result
  end
 end
 local function resolve_end()
  if #tops>0 then 
   local result=s.stop(s,top,1,#top)
   remove(tops)
   top=tops[#tops]
   switch=top and top.switch
   return result
  end
 end
 local function resolve(t)
  resolve_begin()
  for i=1,#t do
   resolve_step(t[i])
  end
  resolve_end()
 end
 s={
  name=name or "unknown",
  unset=-1,
  report=report,
  start=start,
  stop=stop,
  change=change,
  push=push,
  pop=pop,
  clean=clean,
  resolve=resolve,
  resolve_begin=resolve_begin,
  resolve_step=resolve_step,
  resolve_end=resolve_end,
  resolve_reset=resolve_reset,
 }
 return s 
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['util-zip']={
 version=1.001,
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local type,tostring,tonumber=type,tostring,tonumber
local sort,concat=table.sort,table.concat
local find,format,sub,gsub=string.find,string.format,string.sub,string.gsub
local osdate,ostime,osclock=os.date,os.time,os.clock
local ioopen=io.open
local loaddata,savedata=io.loaddata,io.savedata
local filejoin,isdir,dirname,mkdirs=file.join,lfs.isdir,file.dirname,dir.mkdirs
local suffix,suffixes=file.suffix,file.suffixes
local openfile=io.open
gzip=gzip or {} 
if not zlib then
 zlib=xzip 
elseif not xzip then
 xzip=zlib
end
local files=utilities.files
local openfile=files.open
local closefile=files.close
local getsize=files.size
local readstring=files.readstring
local readcardinal2=files.readcardinal2le
local readcardinal4=files.readcardinal4le
local setposition=files.setposition
local getposition=files.getposition
local skipbytes=files.skip
local band=bit32.band
local rshift=bit32.rshift
local lshift=bit32.lshift
local zlibdecompress=zlib.decompress
local zlibdecompresssize=zlib.decompresssize
local zlibchecksum=zlib.crc32
if not CONTEXTLMTXMODE or CONTEXTLMTXMODE==0 then
 local cs=zlibchecksum
 zlibchecksum=function(str,n) return cs(n or 0,str) end
end
local decompress=function(source)   return zlibdecompress (source,-15)   end 
local decompresssize=function(source,targetsize) return zlibdecompresssize(source,targetsize,-15) end 
local calculatecrc=function(buffer,initial) return zlibchecksum   (initial or 0,buffer)   end
local zipfiles={}
utilities.zipfiles=zipfiles
local openzipfile,closezipfile,unzipfile,foundzipfile,getziphash,getziplist  do
 function openzipfile(name)
  return {
   name=name,
   handle=openfile(name,0),
  }
 end
 local function update(handle,data)
  position=data.offset
  setposition(handle,position)
  local signature=readstring(handle,4)
  if signature=="PK\3\4" then
   local version=readcardinal2(handle)
   local flag=readcardinal2(handle)
   local method=readcardinal2(handle)
          skipbytes(handle,4)
   local crc32=readcardinal4(handle)
   local compressed=readcardinal4(handle)
   local uncompressed=readcardinal4(handle)
   local namelength=readcardinal2(handle)
   local extralength=readcardinal2(handle)
   local filename=readstring(handle,namelength)
   local descriptor=band(flag,8)~=0
   local encrypted=band(flag,1)~=0
   local acceptable=method==0 or method==8
   local skipped=0
   local size=0
   if encrypted then
    size=readcardinal2(handle)
    skipbytes(handle,size)
    skipped=skipped+size+2
    skipbytes(8)
    skipped=skipped+8
    size=readcardinal2(handle)
    skipbytes(handle,size)
    skipped=skipped+size+2
    size=readcardinal4(handle)
    skipbytes(handle,size)
    skipped=skipped+size+4
    size=readcardinal2(handle)
    skipbytes(handle,size)
    skipped=skipped+size+2
   end
   if acceptable then
     if        filename~=data.filename  then
    else
     position=position+30+namelength+extralength+skipped
     data.position=position
     return position
    end
   else
   end
  end
  data.position=false
  return false
 end
 local function collect(z)
  if not z.list then
   local list={}
   local hash={}
   local position=0
   local index=0
   local handle=z.handle
   local size=getsize(handle)
   for i=size-4,size-64*1024,-1 do
    setposition(handle,i)
    local enddirsignature=readcardinal4(handle)
    if enddirsignature==0x06054B50 then
     local thisdisknumber=readcardinal2(handle)
     local centraldisknumber=readcardinal2(handle)
     local thisnofentries=readcardinal2(handle)
     local totalnofentries=readcardinal2(handle)
     local centralsize=readcardinal4(handle)
     local centraloffset=readcardinal4(handle)
     local commentlength=readcardinal2(handle)
     local comment=readstring(handle,length)
     if size-i>=22 then
      if thisdisknumber==centraldisknumber then
       setposition(handle,centraloffset)
       while true do
        if readcardinal4(handle)==0x02014B50 then
                skipbytes(handle,4)
         local flag=readcardinal2(handle)
         local method=readcardinal2(handle)
                skipbytes(handle,4)
         local crc32=readcardinal4(handle)
         local compressed=readcardinal4(handle)
         local uncompressed=readcardinal4(handle)
         local namelength=readcardinal2(handle)
         local extralength=readcardinal2(handle)
         local commentlength=readcardinal2(handle)
                skipbytes(handle,8)
         local headeroffset=readcardinal4(handle)
         local filename=readstring(handle,namelength)
                skipbytes(handle,extralength+commentlength)
         local descriptor=band(flag,8)~=0
         local encrypted=band(flag,1)~=0
         local acceptable=method==0 or method==8
         if acceptable then
          index=index+1
          local data={
           filename=filename,
           index=index,
           position=nil,
           method=method,
           compressed=compressed,
           uncompressed=uncompressed,
           crc32=crc32,
           encrypted=encrypted,
           offset=headeroffset,
          }
          hash[filename]=data
          list[index]=data
         end
        else
         break
        end
       end
      end
      break
     end
    end
   end
   z.list=list
   z.hash=hash
  end
 end
 function getziplist(z)
  local list=z.list
  if not list then
   collect(z)
  end
  return z.list
 end
 function getziphash(z)
  local hash=z.hash
  if not hash then
   collect(z)
  end
  return z.hash
 end
 function foundzipfile(z,name)
  return getziphash(z)[name]
 end
 function closezipfile(z)
  local f=z.handle
  if f then
   closefile(f)
   z.handle=nil
  end
 end
 function unzipfile(z,filename,check)
  local hash=z.hash
  if not hash then
   hash=zipfiles.hash(z)
  end
  local data=hash[filename] 
  if not data then
  end
  if data then
   local handle=z.handle
   local position=data.position
   local compressed=data.compressed
   if position==nil then
    position=update(handle,data)
   end
   if position and compressed>0 then
    setposition(handle,position)
    local result=readstring(handle,compressed)
    if data.method==8 then
     if decompresssize then
      result=decompresssize(result,data.uncompressed)
     else
      result=decompress(result)
     end
    end
    if check and data.crc32~=calculatecrc(result) then
     print("checksum mismatch")
     return ""
    end
    return result
   else
    return ""
   end
  end
 end
 zipfiles.open=openzipfile
 zipfiles.close=closezipfile
 zipfiles.unzip=unzipfile
 zipfiles.hash=getziphash
 zipfiles.list=getziplist
 zipfiles.found=foundzipfile
end
if xzip then 
 local writecardinal1=files.writebyte
 local writecardinal2=files.writecardinal2le
 local writecardinal4=files.writecardinal4le
 local logwriter=logs.writer
 local globpattern=dir.globpattern
 local compress=xzip.compress
 local checksum=xzip.crc32
 local function fromdostime(dostime,dosdate)
  return ostime {
   year=rshift(dosdate,9)+1980,
   month=band(rshift(dosdate,5),0x0F),
   day=band((dosdate   ),0x1F),
   hour=band(rshift(dostime,11)    ),
   min=band(rshift(dostime,5),0x3F),
   sec=band((dostime   ),0x1F),
  }
 end
 local function todostime(time)
  local t=osdate("*t",time)
  return
   lshift(t.year-1980,9)+lshift(t.month,5)+t.day,
   lshift(t.hour,11)+lshift(t.min,5)+rshift(t.sec,1)
 end
 local function openzip(filename,level,comment,verbose)
  local f=ioopen(filename,"wb")
  if f then
   return {
    filename=filename,
    handle=f,
    list={},
    level=tonumber(level) or 3,
    comment=tostring(comment),
    verbose=verbose,
    uncompressed=0,
    compressed=0,
   }
  end
 end
 local function writezip(z,name,data,level,time)
  local f=z.handle
  local list=z.list
  local level=tonumber(level) or z.level or 3
  local method=8
  local zipped=compress(data,level)
  local checksum=checksum(data)
  local verbose=z.verbose
  if not zipped then
   method=0
   zipped=data
  end
  local start=f:seek()
  local compressed=#zipped
  local uncompressed=#data
  z.compressed=z.compressed+compressed
  z.uncompressed=z.uncompressed+uncompressed
  if verbose then
   local pct=100*compressed/uncompressed
   if pct>=100 then
    logwriter(format("%10i        %s",uncompressed,name))
   else
    logwriter(format("%10i  %02.1f  %s",uncompressed,pct,name))
   end
  end
  f:write("\x50\x4b\x03\x04")
  writecardinal2(f,0)   
  writecardinal2(f,0)   
  writecardinal2(f,method)    
  writecardinal2(f,0)   
  writecardinal2(f,0)   
  writecardinal4(f,checksum)  
  writecardinal4(f,compressed)   
  writecardinal4(f,uncompressed) 
  writecardinal2(f,#name)  
  writecardinal2(f,0)
  f:write(name)      
  f:write(zipped)
  list[#list+1]={ #zipped,#data,name,checksum,start,time or 0 }
 end
 local function closezip(z)
  local f=z.handle
  local list=z.list
  local comment=z.comment
  local verbose=z.verbose
  local count=#list
  local start=f:seek()
  for i=1,count do
   local l=list[i]
   local compressed=l[1]
   local uncompressed=l[2]
   local name=l[3]
   local checksum=l[4]
   local start=l[5]
   local time=l[6]
   local date,time=todostime(time)
   f:write('\x50\x4b\x01\x02')
   writecardinal2(f,0)   
   writecardinal2(f,0)   
   writecardinal2(f,0)   
   writecardinal2(f,8)   
   writecardinal2(f,time)   
   writecardinal2(f,date)   
   writecardinal4(f,checksum)  
   writecardinal4(f,compressed)   
   writecardinal4(f,uncompressed) 
   writecardinal2(f,#name)  
   writecardinal2(f,0)   
   writecardinal2(f,0)   
   writecardinal2(f,0)   
   writecardinal2(f,0)   
   writecardinal4(f,0)   
   writecardinal4(f,start)  
   f:write(name)      
  end
  local stop=f:seek()
  local size=stop-start
  f:write('\x50\x4b\x05\x06')
  writecardinal2(f,0)   
  writecardinal2(f,0)   
  writecardinal2(f,count)  
  writecardinal2(f,count)  
  writecardinal4(f,size)   
  writecardinal4(f,start)  
  if type(comment)=="string" and comment~="" then
   writecardinal2(f,#comment) 
   f:write(comment)     
  else
   writecardinal2(f,0)
  end
  if verbose then
   local compressed=z.compressed
   local uncompressed=z.uncompressed
   local filename=z.filename
   local pct=100*compressed/uncompressed
   logwriter("")
   if pct>=100 then
    logwriter(format("%10i        %s",uncompressed,filename))
   else
    logwriter(format("%10i  %02.1f  %s",uncompressed,pct,filename))
   end
  end
  f:close()
 end
 local function zipdir(zipname,path,level,verbose)
  if type(zipname)=="table" then
   verbose=zipname.verbose
   level=zipname.level
   path=zipname.path
   zipname=zipname.zipname
  end
  if not zipname or zipname=="" then
   return
  end
  if not path or path=="" then
   path="."
  end
  if not isdir(path) then
   return
  end
  path=gsub(path,"\\+","/")
  path=gsub(path,"/+","/")
  local list={}
  local count=0
  globpattern(path,"",true,function(name,size,time)
   count=count+1
   list[count]={ name,time }
  end)
  sort(list,function(a,b)
   return a[1]<b[1]
  end)
  local zipf=openzip(zipname,level,comment,verbose)
  if zipf then
   local p=#path+2
   for i=1,count do
    local li=list[i]
    local name=li[1]
    local time=li[2]
    local data=loaddata(name)
    local name=sub(name,p,#name)
    writezip(zipf,name,data,level,time,verbose)
   end
   closezip(zipf)
  end
 end
 local function unzipdir(zipname,path,verbose,collect,validate)
  if type(zipname)=="table" then
   validate=zipname.validate
   collect=zipname.collect
   verbose=zipname.verbose
   path=zipname.path
   zipname=zipname.zipname
  end
  if not zipname or zipname=="" then
   return
  end
  if not path or path=="" then
   path="."
  end
  local z=openzipfile(zipname)
  if z then
   local list=getziplist(z)
   if list then
    local total=0
    local count=#list
    local step=number.idiv(count,10)
    local done=0
    local steps=verbose=="steps"
    local time=steps and osclock()
    if collect then
     collect={}
    else
     collect=false
    end
    for i=1,count do
     local l=list[i]
     local n=l.filename
     if not validate or validate(n) then
      local d=unzipfile(z,n) 
      if d then
       local p=filejoin(path,n)
       if mkdirs(dirname(p)) then
        if steps then
         total=total+#d
         done=done+1
         if done>=step then
          done=0
          logwriter(format("%4i files of %4i done, %10i bytes, %0.3f seconds",i,count,total,osclock()-time))
         end
        elseif verbose then
         logwriter(n)
        end
        savedata(p,d)
        if collect then
         collect[#collect+1]=p
        end
       end
      else
       logwriter(format("problem with file %s",n))
      end
     else
     end
    end
    if steps then
     logwriter(format("%4i files of %4i done, %10i bytes, %0.3f seconds",count,count,total,osclock()-time))
    end
    closezipfile(z)
    if collect then
     return collect
    end
   else
    closezipfile(z)
   end
  end
 end
 zipfiles.zipdir=zipdir
 zipfiles.unzipdir=unzipdir
end
local pattern="^\x1F\x8B\x08"
local gziplevel=3
function gzip.suffix(filename)
 local suffix,extra=suffixes(filename)
 local gzipped=extra=="gz"
 return suffix,gzipped
end
function gzip.compressed(s)
 return s and find(s,pattern)
end
local getdecompressed
local putcompressed
if gzip.compress then
 local gzipwindow=15+16 
 local compress=zlib.compress
 local decompress=zlib.decompress
 getdecompressed=function(str)
  return decompress(str,gzipwindow) 
 end
 putcompressed=function(str,level)
  return compress(str,level or gziplevel,nil,gzipwindow)
 end
else
 local gzipwindow=-15 
 local identifier="\x1F\x8B"
 local compress=zlib.compress
 local decompress=zlib.decompress
 local zlibchecksum=zlib.crc32
 if not CONTEXTLMTXMODE or CONTEXTLMTXMODE==0 then
  local cs=zlibchecksum
  zlibchecksum=function(str,n) return cs(n or 0,str) end
 end
 local streams=utilities.streams
 local openstream=streams.openstring
 local closestream=streams.close
 local getposition=streams.getposition
 local readbyte=streams.readbyte
 local readcardinal4=streams.readcardinal4le
 local readcardinal2=streams.readcardinal2le
 local readstring=streams.readstring
 local readcstring=streams.readcstring
 local skipbytes=streams.skip
 local tocardinal1=streams.tocardinal1
 local tocardinal4=streams.tocardinal4le
 getdecompressed=function(str)
  local s=openstream(str)
  local identifier=readstring(s,2)
  local method=readbyte(s,1)
  local flags=readbyte(s,1)
  local timestamp=readcardinal4(s)
  local compression=readbyte(s,1)
  local operating=readbyte(s,1)
  local isjusttext=band(flags,0x01)~=0 and true    or false
  local extrasize=band(flags,0x04)~=0 and readcardinal2(s) or 0
  local filename=band(flags,0x08)~=0 and readcstring(s)   or ""
  local comment=band(flags,0x10)~=0 and readcstring(s)   or ""
  local checksum=band(flags,0x02)~=0 and readcardinal2(s) or 0
  local compressed=readstring(s,#str)
  local data=decompress(compressed,gzipwindow) 
  return data
 end
 putcompressed=function(str,level,originalname)
  return concat {
   identifier,
   tocardinal1(0x08),
   tocardinal1(0x08),
   tocardinal4(os.time()),
   tocardinal1(0x02),
   tocardinal1(0xFF),
   (originalname or "unknownname").."\0",
   compress(str,level,nil,gzipwindow),
   tocardinal4(zlibchecksum(str)),
   tocardinal4(#str),
  }
 end
end
function gzip.load(filename)
 local f=openfile(filename,"rb")
 if not f then
 else
  local data=f:read("*all")
  f:close()
  if data and data~="" then
   if suffix(filename)=="gz" then
    data=getdecompressed(data)
   end
   return data
  end
 end
end
function gzip.save(filename,data,level,originalname)
 if suffix(filename)~="gz" then
  filename=filename..".gz"
 end
 local f=openfile(filename,"wb")
 if f then
  data=putcompressed(data or "",level or gziplevel,originalname)
  f:write(data)
  f:close()
  return #data
 end
end
function gzip.compress(s,level)
 if s and not find(s,pattern) then
  if not level then
   level=gziplevel
  elseif level<=0 then
   return s
  elseif level>9 then
   level=9
  end
  return putcompressed(s,level or gziplevel) or s
 end
end
function gzip.decompress(s)
 if s and find(s,pattern) then
  return getdecompressed(s)
 else
  return s
 end
end

end -- closure
