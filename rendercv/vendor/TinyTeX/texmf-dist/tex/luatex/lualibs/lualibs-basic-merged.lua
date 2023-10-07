-- merged file : lualibs-basic-merged.lua
-- parent file : lualibs-basic.lua
-- merge date  : 2023-07-13 12:55

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-lua']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local next,type,tonumber=next,type,tonumber
LUAMAJORVERSION,LUAMINORVERSION=string.match(_VERSION,"^[^%d]+(%d+)%.(%d+).*$")
LUAMAJORVERSION=tonumber(LUAMAJORVERSION) or 5
LUAMINORVERSION=tonumber(LUAMINORVERSION) or 1
LUAVERSION=LUAMAJORVERSION+LUAMINORVERSION/10
if LUAVERSION<5.2 and jit then
 MINORVERSION=2
 LUAVERSION=5.2
end
if not lpeg then
 lpeg=require("lpeg")
end
if loadstring then
 local loadnormal=load
 function load(first,...)
  if type(first)=="string" then
   return loadstring(first,...)
  else
   return loadnormal(first,...)
  end
 end
else
 loadstring=load
end
if not ipairs then
 local function iterate(a,i)
  i=i+1
  local v=a[i]
  if v~=nil then
   return i,v 
  end
 end
 function ipairs(a)
  return iterate,a,0
 end
end
if not pairs then
 function pairs(t)
  return next,t 
 end
end
if not table.unpack then
 table.unpack=_G.unpack
elseif not unpack then
 _G.unpack=table.unpack
end
if not package.loaders then 
 package.loaders=package.searchers
end
local print,select,tostring=print,select,tostring
local inspectors={}
function setinspector(kind,inspector) 
 inspectors[kind]=inspector
end
function inspect(...) 
 for s=1,select("#",...) do
  local value=select(s,...)
  if value==nil then
   print("nil")
  else
   local done=false
   local kind=type(value)
   local inspector=inspectors[kind]
   if inspector then
    done=inspector(value)
    if done then
     break
    end
   end
   for kind,inspector in next,inspectors do
    done=inspector(value)
    if done then
     break
    end
   end
   if not done then
    print(tostring(value))
   end
  end
 end
end
local dummy=function() end
function optionalrequire(...)
 local ok,result=xpcall(require,dummy,...)
 if ok then
  return result
 end
end
local flush=io.flush
if flush then
 local execute=os.execute if execute then function os.execute(...) flush() return execute(...) end end
 local exec=os.exec if exec then function os.exec   (...) flush() return exec   (...) end end
 local spawn=os.spawn   if spawn   then function os.spawn  (...) flush() return spawn  (...) end end
 local popen=io.popen   if popen   then function io.popen  (...) flush() return popen  (...) end end
end
FFISUPPORTED=type(ffi)=="table" and ffi.os~="" and ffi.arch~="" and ffi.load
if not FFISUPPORTED then
 local okay;okay,ffi=pcall(require,"ffi")
 FFISUPPORTED=type(ffi)=="table" and ffi.os~="" and ffi.arch~="" and ffi.load
end
if not FFISUPPORTED then
 ffi=nil
elseif not ffi.number then
 ffi.number=tonumber
end
if LUAVERSION>5.3 then
end
if status and os.setenv then
 os.setenv("engine",string.lower(status.luatex_engine or "unknown"))
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-package']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local type,unpack=type,unpack
local gsub,format,find=string.gsub,string.format,string.find
local insert,remove=table.insert,table.remove
local P,S,Cs,lpegmatch=lpeg.P,lpeg.S,lpeg.Cs,lpeg.match
local package=package
local searchers=package.searchers or package.loaders
local filejoin=file and file.join  or function(path,name)   return path.."/"..name end
local isreadable=file and file.is_readable or function(name)  local f=io.open(name) if f then f:close() return true end end
local addsuffix=file and file.addsuffix   or function(name,suffix) return name.."."..suffix end
local function cleanpath(path) 
 return path
end
local pattern=Cs((((1-S("\\/"))^0*(S("\\/")^1/"/"))^0*(P(".")^1/"/"+P(1))^1)*-1)
local function lualibfile(name)
 return lpegmatch(pattern,name) or name
end
local offset=luarocks and 1 or 0 
local helpers=package.helpers or {
 cleanpath=cleanpath,
 lualibfile=lualibfile,
 trace=false,
 report=function(...) print(format(...)) end,
 builtin={
  ["preload table"]=searchers[1+offset],
  ["path specification"]=searchers[2+offset],
  ["cpath specification"]=searchers[3+offset],
  ["all in one fallback"]=searchers[4+offset],
 },
 methods={},
 sequence={
  "reset loaded",
  "already loaded",
  "preload table",
  "qualified path",
  "lua extra list",
  "lib extra list",
  "path specification",
  "cpath specification",
  "all in one fallback",
  "not loaded",
 }
}
package.helpers=helpers
local methods=helpers.methods
local builtin=helpers.builtin
local extraluapaths={}
local extralibpaths={}
local checkedfiles={}
local luapaths=nil 
local libpaths=nil 
local oldluapath=nil
local oldlibpath=nil
local nofextralua=-1
local nofextralib=-1
local nofpathlua=-1
local nofpathlib=-1
local function listpaths(what,paths)
 local nofpaths=#paths
 if nofpaths>0 then
  for i=1,nofpaths do
   helpers.report("using %s path %i: %s",what,i,paths[i])
  end
 else
  helpers.report("no %s paths defined",what)
 end
 return nofpaths
end
local function getextraluapaths()
 if helpers.trace and #extraluapaths~=nofextralua then
  nofextralua=listpaths("extra lua",extraluapaths)
 end
 return extraluapaths
end
local function getextralibpaths()
 if helpers.trace and #extralibpaths~=nofextralib then
  nofextralib=listpaths("extra lib",extralibpaths)
 end
 return extralibpaths
end
local function getluapaths()
 local luapath=package.path or ""
 if oldluapath~=luapath then
  luapaths=file.splitpath(luapath,";")
  oldluapath=luapath
  nofpathlua=-1
 end
 if helpers.trace and #luapaths~=nofpathlua then
  nofpathlua=listpaths("builtin lua",luapaths)
 end
 return luapaths
end
local function getlibpaths()
 local libpath=package.cpath or ""
 if oldlibpath~=libpath then
  libpaths=file.splitpath(libpath,";")
  oldlibpath=libpath
  nofpathlib=-1
 end
 if helpers.trace and #libpaths~=nofpathlib then
  nofpathlib=listpaths("builtin lib",libpaths)
 end
 return libpaths
end
package.luapaths=getluapaths
package.libpaths=getlibpaths
package.extraluapaths=getextraluapaths
package.extralibpaths=getextralibpaths
local hashes={
 lua={},
 lib={},
}
local function registerpath(tag,what,target,...)
 local pathlist={... }
 local cleanpath=helpers.cleanpath
 local trace=helpers.trace
 local report=helpers.report
 local hash=hashes[what]
 local function add(path)
  local path=cleanpath(path)
  if not hash[path] then
   target[#target+1]=path
   hash[path]=true
   if trace then
    report("registered %s path %s: %s",tag,#target,path)
   end
  else
   if trace then
    report("duplicate %s path: %s",tag,path)
   end
  end
 end
 for p=1,#pathlist do
  local path=pathlist[p]
  if type(path)=="table" then
   for i=1,#path do
    add(path[i])
   end
  else
   add(path)
  end
 end
end
local function pushpath(tag,what,target,path)
 local path=helpers.cleanpath(path)
 insert(target,1,path)
 if helpers.trace then
  helpers.report("pushing %s path in front: %s",tag,path)
 end
end
local function poppath(tag,what,target)
 local path=remove(target,1)
 if helpers.trace then
  if path then
   helpers.report("popping %s path from front: %s",tag,path)
  else
   helpers.report("no %s path to pop",tag)
  end
 end
end
helpers.registerpath=registerpath
function package.extraluapath(...)
 registerpath("extra lua","lua",extraluapaths,...)
end
function package.pushluapath(path)
 pushpath("extra lua","lua",extraluapaths,path)
end
function package.popluapath()
 poppath("extra lua","lua",extraluapaths)
end
function package.extralibpath(...)
 registerpath("extra lib","lib",extralibpaths,...)
end
function package.pushlibpath(path)
 pushpath("extra lib","lib",extralibpaths,path)
end
function package.poplibpath()
 poppath("extra lib","lua",extralibpaths)
end
local function loadedaslib(resolved,rawname) 
 local base=gsub(rawname,"%.","_")
 local init="luaopen_"..gsub(base,"%.","_")
 local data={ resolved,init,"" }
 checkedfiles[#checkedfiles+1]=data
 if helpers.trace then
  helpers.report("calling loadlib with '%s' with init '%s'",resolved,init)
 end
 local a,b,c=package.loadlib(resolved,init)
 if not a and type(b)=="string" then
  data[3]=string.fullstrip(b or "unknown error")
 end
 return a,b,c 
end
helpers.loadedaslib=loadedaslib
local function loadedbypath(name,rawname,paths,islib,what)
 local trace=helpers.trace
 for p=1,#paths do
  local path=paths[p]
  local resolved=filejoin(path,name)
  if trace then
   helpers.report("%s path, identifying '%s' on '%s'",what,name,path)
  end
  if isreadable(resolved) then
   if trace then
    helpers.report("%s path, '%s' found on '%s'",what,name,resolved)
   end
   if islib then
    return loadedaslib(resolved,rawname)
   else
    return loadfile(resolved)
   end
  end
 end
end
helpers.loadedbypath=loadedbypath
local function loadedbyname(name,rawname)
 if find(name,"^/") or find(name,"^[a-zA-Z]:/") then
  local trace=helpers.trace
  if trace then
   helpers.report("qualified name, identifying '%s'",what,name)
  end
  if isreadable(name) then
   if trace then
    helpers.report("qualified name, '%s' found",what,name)
   end
   return loadfile(name)
  end
 end
end
helpers.loadedbyname=loadedbyname
methods["reset loaded"]=function(name)
 checkedfiles={}
 return false
end
methods["already loaded"]=function(name)
 return package.loaded[name]
end
methods["preload table"]=function(name)
 local f=builtin["preload table"]
 if f then
  return f(name)
 end
end
methods["qualified path"]=function(name)
  return loadedbyname(addsuffix(lualibfile(name),"lua"),name)
end
methods["lua extra list"]=function(name)
 return loadedbypath(addsuffix(lualibfile(name),"lua"),name,getextraluapaths(),false,"lua")
end
methods["lib extra list"]=function(name)
 return loadedbypath(addsuffix(lualibfile(name),os.libsuffix),name,getextralibpaths(),true,"lib")
end
methods["path specification"]=function(name)
 local f=builtin["path specification"]
 if f then
  getluapaths() 
  return f(name)
 end
end
methods["cpath specification"]=function(name)
 local f=builtin["cpath specification"]
 if f then
  getlibpaths() 
  return f(name)
 end
end
methods["all in one fallback"]=function(name)
 local f=builtin["all in one fallback"]
 if f then
  return f(name)
 end
end
methods["not loaded"]=function(name)
 if helpers.trace then
  helpers.report("unable to locate '%s'",name or "?")
  for i=1,#checkedfiles do
   helpers.report("checked file '%s', initializer '%s', message '%s'",unpack(checkedfiles[i]))
  end
 end
 return nil
end
local level=0
local used={}
helpers.traceused=false
function helpers.loaded(name)
 local sequence=helpers.sequence
 level=level+1
 for i=1,#sequence do
  local method=sequence[i]
  local lookup=method and methods[method]
  if type(lookup)=="function" then
   if helpers.trace then
    helpers.report("%s, level '%s', method '%s', name '%s'","locating",level,method,name)
   end
   local result,rest=lookup(name)
   if type(result)=="function" then
    if helpers.trace then
     helpers.report("%s, level '%s', method '%s', name '%s'","found",level,method,name)
    end
    if helpers.traceused then
     used[#used+1]={ level=level,name=name }
    end
    level=level-1
    return result,rest
   end
  end
 end
 level=level-1
 return nil
end
function helpers.showused()
 local n=#used
 if n>0 then
  helpers.report("%s libraries loaded:",n)
  helpers.report()
  for i=1,n do
   local u=used[i]
   helpers.report("%i %a",u.level,u.name)
  end
  helpers.report()
  end
end
function helpers.unload(name)
 if helpers.trace then
  if package.loaded[name] then
   helpers.report("unloading, name '%s', %s",name,"done")
  else
   helpers.report("unloading, name '%s', %s",name,"not loaded")
  end
 end
 package.loaded[name]=nil
end
table.insert(searchers,1,helpers.loaded)
if context then
 package.path=""
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-lpeg']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
lpeg=require("lpeg") 
local lpeg=lpeg
if not lpeg.print then function lpeg.print(...) print(lpeg.pcode(...)) end end
local type,next,tostring=type,next,tostring
local byte,char,gmatch,format=string.byte,string.char,string.gmatch,string.format
local floor=math.floor
local P,R,S,V,Ct,C,Cs,Cc,Cp,Cmt=lpeg.P,lpeg.R,lpeg.S,lpeg.V,lpeg.Ct,lpeg.C,lpeg.Cs,lpeg.Cc,lpeg.Cp,lpeg.Cmt
local lpegtype,lpegmatch,lpegprint=lpeg.type,lpeg.match,lpeg.print
if setinspector then
 setinspector("lpeg",function(v) if lpegtype(v) then lpegprint(v) return true end end)
end
lpeg.patterns=lpeg.patterns or {} 
local patterns=lpeg.patterns
local anything=P(1)
local endofstring=P(-1)
local alwaysmatched=P(true)
patterns.anything=anything
patterns.endofstring=endofstring
patterns.beginofstring=alwaysmatched
patterns.alwaysmatched=alwaysmatched
local sign=S('+-')
local zero=P('0')
local digit=R('09')
local digits=digit^1
local octdigit=R("07")
local octdigits=octdigit^1
local lowercase=R("az")
local uppercase=R("AZ")
local underscore=P("_")
local hexdigit=digit+lowercase+uppercase
local hexdigits=hexdigit^1
local cr,lf,crlf=P("\r"),P("\n"),P("\r\n")
local newline=P("\r")*(P("\n")+P(true))+P("\n")  
local escaped=P("\\")*anything
local squote=P("'")
local dquote=P('"')
local space=P(" ")
local period=P(".")
local comma=P(",")
local utfbom_32_be=P('\000\000\254\255') 
local utfbom_32_le=P('\255\254\000\000') 
local utfbom_16_be=P('\254\255')   
local utfbom_16_le=P('\255\254')   
local utfbom_8=P('\239\187\191')  
local utfbom=utfbom_32_be+utfbom_32_le+utfbom_16_be+utfbom_16_le+utfbom_8
local utftype=utfbom_32_be*Cc("utf-32-be")+utfbom_32_le*Cc("utf-32-le")+utfbom_16_be*Cc("utf-16-be")+utfbom_16_le*Cc("utf-16-le")+utfbom_8*Cc("utf-8")+alwaysmatched*Cc("utf-8") 
local utfstricttype=utfbom_32_be*Cc("utf-32-be")+utfbom_32_le*Cc("utf-32-le")+utfbom_16_be*Cc("utf-16-be")+utfbom_16_le*Cc("utf-16-le")+utfbom_8*Cc("utf-8")
local utfoffset=utfbom_32_be*Cc(4)+utfbom_32_le*Cc(4)+utfbom_16_be*Cc(2)+utfbom_16_le*Cc(2)+utfbom_8*Cc(3)+Cc(0)
local utf8next=R("\128\191")
patterns.utfbom_32_be=utfbom_32_be
patterns.utfbom_32_le=utfbom_32_le
patterns.utfbom_16_be=utfbom_16_be
patterns.utfbom_16_le=utfbom_16_le
patterns.utfbom_8=utfbom_8
patterns.utf_16_be_nl=P("\000\r\000\n")+P("\000\r")+P("\000\n") 
patterns.utf_16_le_nl=P("\r\000\n\000")+P("\r\000")+P("\n\000") 
patterns.utf_32_be_nl=P("\000\000\000\r\000\000\000\n")+P("\000\000\000\r")+P("\000\000\000\n")
patterns.utf_32_le_nl=P("\r\000\000\000\n\000\000\000")+P("\r\000\000\000")+P("\n\000\000\000")
patterns.utf8one=R("\000\127")
patterns.utf8two=R("\194\223")*utf8next
patterns.utf8three=R("\224\239")*utf8next*utf8next
patterns.utf8four=R("\240\244")*utf8next*utf8next*utf8next
patterns.utfbom=utfbom
patterns.utftype=utftype
patterns.utfstricttype=utfstricttype
patterns.utfoffset=utfoffset
local utf8char=patterns.utf8one+patterns.utf8two+patterns.utf8three+patterns.utf8four
local validutf8char=utf8char^0*endofstring*Cc(true)+Cc(false)
local utf8character=P(1)*R("\128\191")^0 
patterns.utf8=utf8char
patterns.utf8char=utf8char
patterns.utf8character=utf8character 
patterns.validutf8=validutf8char
patterns.validutf8char=validutf8char
local eol=S("\n\r")
local spacer=S(" \t\f\v")  
local whitespace=eol+spacer
local nonspacer=1-spacer
local nonwhitespace=1-whitespace
patterns.eol=eol
patterns.spacer=spacer
patterns.whitespace=whitespace
patterns.nonspacer=nonspacer
patterns.nonwhitespace=nonwhitespace
local stripper=spacer^0*C((spacer^0*nonspacer^1)^0)  
local fullstripper=whitespace^0*C((whitespace^0*nonwhitespace^1)^0)
local collapser=Cs(spacer^0/""*nonspacer^0*((spacer^0/" "*nonspacer^1)^0))
local nospacer=Cs((whitespace^1/""+nonwhitespace^1)^0)
local b_collapser=Cs(whitespace^0/""*(nonwhitespace^1+whitespace^1/" ")^0)
local m_collapser=Cs((nonwhitespace^1+whitespace^1/" ")^0)
local e_collapser=Cs((whitespace^1*endofstring/""+nonwhitespace^1+whitespace^1/" ")^0)
local x_collapser=Cs((nonwhitespace^1+whitespace^1/"" )^0)
local b_stripper=Cs(spacer^0/""*(nonspacer^1+spacer^1/" ")^0)
local m_stripper=Cs((nonspacer^1+spacer^1/" ")^0)
local e_stripper=Cs((spacer^1*endofstring/""+nonspacer^1+spacer^1/" ")^0)
local x_stripper=Cs((nonspacer^1+spacer^1/"" )^0)
patterns.stripper=stripper
patterns.fullstripper=fullstripper
patterns.collapser=collapser
patterns.nospacer=nospacer
patterns.b_collapser=b_collapser
patterns.m_collapser=m_collapser
patterns.e_collapser=e_collapser
patterns.x_collapser=x_collapser
patterns.b_stripper=b_stripper
patterns.m_stripper=m_stripper
patterns.e_stripper=e_stripper
patterns.x_stripper=x_stripper
patterns.lowercase=lowercase
patterns.uppercase=uppercase
patterns.letter=patterns.lowercase+patterns.uppercase
patterns.space=space
patterns.tab=P("\t")
patterns.spaceortab=patterns.space+patterns.tab
patterns.newline=newline
patterns.emptyline=newline^1
patterns.equal=P("=")
patterns.comma=comma
patterns.commaspacer=comma*spacer^0
patterns.period=period
patterns.colon=P(":")
patterns.semicolon=P(";")
patterns.underscore=underscore
patterns.escaped=escaped
patterns.squote=squote
patterns.dquote=dquote
patterns.nosquote=(escaped+(1-squote))^0
patterns.nodquote=(escaped+(1-dquote))^0
patterns.unsingle=(squote/"")*patterns.nosquote*(squote/"") 
patterns.undouble=(dquote/"")*patterns.nodquote*(dquote/"") 
patterns.unquoted=patterns.undouble+patterns.unsingle 
patterns.unspacer=((patterns.spacer^1)/"")^0
patterns.singlequoted=squote*patterns.nosquote*squote
patterns.doublequoted=dquote*patterns.nodquote*dquote
patterns.quoted=patterns.doublequoted+patterns.singlequoted
patterns.digit=digit
patterns.digits=digits
patterns.octdigit=octdigit
patterns.octdigits=octdigits
patterns.hexdigit=hexdigit
patterns.hexdigits=hexdigits
patterns.sign=sign
patterns.cardinal=digits
patterns.integer=sign^-1*digits
patterns.unsigned=digit^0*period*digits
patterns.float=sign^-1*patterns.unsigned
patterns.cunsigned=digit^0*comma*digits
patterns.cpunsigned=digit^0*(period+comma)*digits
patterns.cfloat=sign^-1*patterns.cunsigned
patterns.cpfloat=sign^-1*patterns.cpunsigned
patterns.number=patterns.float+patterns.integer
patterns.cnumber=patterns.cfloat+patterns.integer
patterns.cpnumber=patterns.cpfloat+patterns.integer
patterns.oct=zero*octdigits 
patterns.octal=patterns.oct
patterns.HEX=zero*P("X")*(digit+uppercase)^1
patterns.hex=zero*P("x")*(digit+lowercase)^1
patterns.hexadecimal=zero*S("xX")*hexdigits
patterns.hexafloat=sign^-1*zero*S("xX")*(hexdigit^0*period*hexdigits+hexdigits*period*hexdigit^0+hexdigits)*(S("pP")*sign^-1*hexdigits)^-1
patterns.decafloat=sign^-1*(digit^0*period*digits+digits*period*digit^0+digits)*S("eE")*sign^-1*digits
patterns.propername=(uppercase+lowercase+underscore)*(uppercase+lowercase+underscore+digit)^0*endofstring
patterns.somecontent=(anything-newline-space)^1 
patterns.beginline=#(1-newline)
patterns.longtostring=Cs(whitespace^0/""*((patterns.quoted+nonwhitespace^1+whitespace^1/""*(endofstring+Cc(" ")))^0))
local function anywhere(pattern) 
 return (1-P(pattern))^0*P(pattern)
end
lpeg.anywhere=anywhere
function lpeg.instringchecker(p)
 p=anywhere(p)
 return function(str)
  return lpegmatch(p,str) and true or false
 end
end
function lpeg.splitter(pattern,action)
 if action then
  return (((1-P(pattern))^1)/action+1)^0
 else
  return (Cs((1-P(pattern))^1)+1)^0
 end
end
function lpeg.tsplitter(pattern,action)
 if action then
  return Ct((((1-P(pattern))^1)/action+1)^0)
 else
  return Ct((Cs((1-P(pattern))^1)+1)^0)
 end
end
local splitters_s,splitters_m,splitters_t={},{},{}
local function splitat(separator,single)
 local splitter=(single and splitters_s[separator]) or splitters_m[separator]
 if not splitter then
  separator=P(separator)
  local other=C((1-separator)^0)
  if single then
   local any=anything
   splitter=other*(separator*C(any^0)+"") 
   splitters_s[separator]=splitter
  else
   splitter=other*(separator*other)^0
   splitters_m[separator]=splitter
  end
 end
 return splitter
end
local function tsplitat(separator)
 local splitter=splitters_t[separator]
 if not splitter then
  splitter=Ct(splitat(separator))
  splitters_t[separator]=splitter
 end
 return splitter
end
lpeg.splitat=splitat
lpeg.tsplitat=tsplitat
function string.splitup(str,separator)
 if not separator then
  separator=","
 end
 return lpegmatch(splitters_m[separator] or splitat(separator),str)
end
local cache={}
function lpeg.split(separator,str)
 local c=cache[separator]
 if not c then
  c=tsplitat(separator)
  cache[separator]=c
 end
 return lpegmatch(c,str)
end
function string.split(str,separator)
 if separator then
  local c=cache[separator]
  if not c then
   c=tsplitat(separator)
   cache[separator]=c
  end
  return lpegmatch(c,str)
 else
  return { str }
 end
end
local spacing=patterns.spacer^0*newline 
local empty=spacing*Cc("")
local nonempty=Cs((1-spacing)^1)*spacing^-1
local content=(empty+nonempty)^1
patterns.textline=content
local linesplitter=tsplitat(newline)
patterns.linesplitter=linesplitter
function string.splitlines(str)
 return lpegmatch(linesplitter,str)
end
local cache={}
function lpeg.checkedsplit(separator,str)
 local c=cache[separator]
 if not c then
  separator=P(separator)
  local other=C((1-separator)^1)
  c=Ct(separator^0*other*(separator^1*other)^0)
  cache[separator]=c
 end
 return lpegmatch(c,str)
end
function string.checkedsplit(str,separator)
 local c=cache[separator]
 if not c then
  separator=P(separator)
  local other=C((1-separator)^1)
  c=Ct(separator^0*other*(separator^1*other)^0)
  cache[separator]=c
 end
 return lpegmatch(c,str)
end
local function f2(s) local c1,c2=byte(s,1,2) return   c1*64+c2-12416 end
local function f3(s) local c1,c2,c3=byte(s,1,3) return  (c1*64+c2)*64+c3-925824 end
local function f4(s) local c1,c2,c3,c4=byte(s,1,4) return ((c1*64+c2)*64+c3)*64+c4-63447168 end
local utf8byte=patterns.utf8one/byte+patterns.utf8two/f2+patterns.utf8three/f3+patterns.utf8four/f4
patterns.utf8byte=utf8byte
local cache={}
function lpeg.stripper(str)
 if type(str)=="string" then
  local s=cache[str]
  if not s then
   s=Cs(((S(str)^1)/""+1)^0)
   cache[str]=s
  end
  return s
 else
  return Cs(((str^1)/""+1)^0)
 end
end
local cache={}
function lpeg.keeper(str)
 if type(str)=="string" then
  local s=cache[str]
  if not s then
   s=Cs((((1-S(str))^1)/""+1)^0)
   cache[str]=s
  end
  return s
 else
  return Cs((((1-str)^1)/""+1)^0)
 end
end
function lpeg.frontstripper(str) 
 return (P(str)+P(true))*Cs(anything^0)
end
function lpeg.endstripper(str) 
 return Cs((1-P(str)*endofstring)^0)
end
function lpeg.replacer(one,two,makefunction,isutf) 
 local pattern
 local u=isutf and utf8char or 1
 if type(one)=="table" then
  local no=#one
  local p=P(false)
  if no==0 then
   for k,v in next,one do
    p=p+P(k)/v
   end
   pattern=Cs((p+u)^0)
  elseif no==1 then
   local o=one[1]
   one,two=P(o[1]),o[2]
   pattern=Cs((one/two+u)^0)
  else
   for i=1,no do
    local o=one[i]
    p=p+P(o[1])/o[2]
   end
   pattern=Cs((p+u)^0)
  end
 else
  pattern=Cs((P(one)/(two or "")+u)^0)
 end
 if makefunction then
  return function(str)
   return lpegmatch(pattern,str)
  end
 else
  return pattern
 end
end
function lpeg.finder(lst,makefunction,isutf) 
 local pattern
 if type(lst)=="table" then
  pattern=P(false)
  if #lst==0 then
   for k,v in next,lst do
    pattern=pattern+P(k) 
   end
  else
   for i=1,#lst do
    pattern=pattern+P(lst[i])
   end
  end
 else
  pattern=P(lst)
 end
 if isutf then
  pattern=((utf8char or 1)-pattern)^0*pattern
 else
  pattern=(1-pattern)^0*pattern
 end
 if makefunction then
  return function(str)
   return lpegmatch(pattern,str)
  end
 else
  return pattern
 end
end
local splitters_f,splitters_s={},{}
function lpeg.firstofsplit(separator) 
 local splitter=splitters_f[separator]
 if not splitter then
  local pattern=P(separator)
  splitter=C((1-pattern)^0)
  splitters_f[separator]=splitter
 end
 return splitter
end
function lpeg.secondofsplit(separator) 
 local splitter=splitters_s[separator]
 if not splitter then
  local pattern=P(separator)
  splitter=(1-pattern)^0*pattern*C(anything^0)
  splitters_s[separator]=splitter
 end
 return splitter
end
local splitters_s,splitters_p={},{}
function lpeg.beforesuffix(separator) 
 local splitter=splitters_s[separator]
 if not splitter then
  local pattern=P(separator)
  splitter=C((1-pattern)^0)*pattern*endofstring
  splitters_s[separator]=splitter
 end
 return splitter
end
function lpeg.afterprefix(separator) 
 local splitter=splitters_p[separator]
 if not splitter then
  local pattern=P(separator)
  splitter=pattern*C(anything^0)
  splitters_p[separator]=splitter
 end
 return splitter
end
function lpeg.balancer(left,right)
 left,right=P(left),P(right)
 return P { left*((1-left-right)+V(1))^0*right }
end
function lpeg.counter(pattern,action)
 local n=0
 local pattern=(P(pattern)/function() n=n+1 end+anything)^0
 if action then
  return function(str) n=0;lpegmatch(pattern,str);action(n) end
 else
  return function(str) n=0;lpegmatch(pattern,str);return n end
 end
end
function lpeg.is_lpeg(p)
 return p and lpegtype(p)=="pattern"
end
function lpeg.oneof(list,...) 
 if type(list)~="table" then
  list={ list,... }
 end
 local p=P(list[1])
 for l=2,#list do
  p=p+P(list[l])
 end
 return p
end
local sort=table.sort
local function copyindexed(old)
 local new={}
 for i=1,#old do
  new[i]=old
 end
 return new
end
local function sortedkeys(tab)
 local keys,s={},0
 for key,_ in next,tab do
  s=s+1
  keys[s]=key
 end
 sort(keys)
 return keys
end
function lpeg.append(list,pp,delayed,checked)
 local p=pp
 if #list>0 then
  local keys=copyindexed(list)
  sort(keys)
  for i=#keys,1,-1 do
   local k=keys[i]
   if p then
    p=P(k)+p
   else
    p=P(k)
   end
  end
 elseif delayed then 
  local keys=sortedkeys(list)
  if p then
   for i=1,#keys,1 do
    local k=keys[i]
    local v=list[k]
    p=P(k)/list+p
   end
  else
   for i=1,#keys do
    local k=keys[i]
    local v=list[k]
    if p then
     p=P(k)+p
    else
     p=P(k)
    end
   end
   if p then
    p=p/list
   end
  end
 elseif checked then
  local keys=sortedkeys(list)
  for i=1,#keys do
   local k=keys[i]
   local v=list[k]
   if p then
    if k==v then
     p=P(k)+p
    else
     p=P(k)/v+p
    end
   else
    if k==v then
     p=P(k)
    else
     p=P(k)/v
    end
   end
  end
 else
  local keys=sortedkeys(list)
  for i=1,#keys do
   local k=keys[i]
   local v=list[k]
   if p then
    p=P(k)/v+p
   else
    p=P(k)/v
   end
  end
 end
 return p
end
local p_false=P(false)
local p_true=P(true)
local lower=utf and utf.lower or string.lower
local upper=utf and utf.upper or string.upper
function lpeg.setutfcasers(l,u)
 lower=l or lower
 upper=u or upper
end
local function make1(t,rest)
 local p=p_false
 local keys=sortedkeys(t)
 for i=1,#keys do
  local k=keys[i]
  if k~="" then
   local v=t[k]
   if v==true then
    p=p+P(k)*p_true
   elseif v==false then
   else
    p=p+P(k)*make1(v,v[""])
   end
  end
 end
 if rest then
  p=p+p_true
 end
 return p
end
local function make2(t,rest) 
 local p=p_false
 local keys=sortedkeys(t)
 for i=1,#keys do
  local k=keys[i]
  if k~="" then
   local v=t[k]
   if v==true then
    p=p+(P(lower(k))+P(upper(k)))*p_true
   elseif v==false then
   else
    p=p+(P(lower(k))+P(upper(k)))*make2(v,v[""])
   end
  end
 end
 if rest then
  p=p+p_true
 end
 return p
end
local function utfchartabletopattern(list,insensitive) 
 local tree={}
 local n=#list
 if n==0 then
  for s in next,list do
   local t=tree
   local p,pk
   for c in gmatch(s,".") do
    if t==true then
     t={ [c]=true,[""]=true }
     p[pk]=t
     p=t
     t=false
    elseif t==false then
     t={ [c]=false }
     p[pk]=t
     p=t
     t=false
    else
     local tc=t[c]
     if not tc then
      tc=false
      t[c]=false
     end
     p=t
     t=tc
    end
    pk=c
   end
   if t==false then
    p[pk]=true
   elseif t==true then
   else
    t[""]=true
   end
  end
 else
  for i=1,n do
   local s=list[i]
   local t=tree
   local p,pk
   for c in gmatch(s,".") do
    if t==true then
     t={ [c]=true,[""]=true }
     p[pk]=t
     p=t
     t=false
    elseif t==false then
     t={ [c]=false }
     p[pk]=t
     p=t
     t=false
    else
     local tc=t[c]
     if not tc then
      tc=false
      t[c]=false
     end
     p=t
     t=tc
    end
    pk=c
   end
   if t==false then
    p[pk]=true
   elseif t==true then
   else
    t[""]=true
   end
  end
 end
 return (insensitive and make2 or make1)(tree)
end
lpeg.utfchartabletopattern=utfchartabletopattern
function lpeg.utfreplacer(list,insensitive)
 local pattern=Cs((utfchartabletopattern(list,insensitive)/list+utf8character)^0)
 return function(str)
  return lpegmatch(pattern,str) or str
 end
end
patterns.containseol=lpeg.finder(eol)
local function nextstep(n,step,result)
 local m=n%step   
 local d=floor(n/step) 
 if d>0 then
  local v=V(tostring(step))
  local s=result.start
  for i=1,d do
   if s then
    s=v*s
   else
    s=v
   end
  end
  result.start=s
 end
 if step>1 and result.start then
  local v=V(tostring(step/2))
  result[tostring(step)]=v*v
 end
 if step>0 then
  return nextstep(m,step/2,result)
 else
  return result
 end
end
function lpeg.times(pattern,n)
 return P(nextstep(n,2^16,{ "start",["1"]=pattern }))
end
do
 local trailingzeros=zero^0*-digit 
 local stripper=Cs((
  digits*(
   period*trailingzeros/""+period*(digit-trailingzeros)^1*(trailingzeros/"")
  )+1
 )^0)
 lpeg.patterns.stripzeros=stripper 
 local nonzero=digit-zero
 local trailingzeros=zero^1*endofstring
 local stripper=Cs((1-period)^0*(
  period*trailingzeros/""+period*(nonzero^1+(trailingzeros/"")+zero^1)^0+endofstring
 ))
 lpeg.patterns.stripzero=stripper
end
local byte_to_HEX={}
local byte_to_hex={}
local byte_to_dec={} 
local hex_to_byte={}
for i=0,255 do
 local H=format("%02X",i)
 local h=format("%02x",i)
 local d=format("%03i",i)
 local c=char(i)
 byte_to_HEX[c]=H
 byte_to_hex[c]=h
 byte_to_dec[c]=d
 hex_to_byte[h]=c
 hex_to_byte[H]=c
end
local hextobyte=P(2)/hex_to_byte
local bytetoHEX=P(1)/byte_to_HEX
local bytetohex=P(1)/byte_to_hex
local bytetodec=P(1)/byte_to_dec
local hextobytes=Cs(hextobyte^0)
local bytestoHEX=Cs(bytetoHEX^0)
local bytestohex=Cs(bytetohex^0)
local bytestodec=Cs(bytetodec^0)
patterns.hextobyte=hextobyte
patterns.bytetoHEX=bytetoHEX
patterns.bytetohex=bytetohex
patterns.bytetodec=bytetodec
patterns.hextobytes=hextobytes
patterns.bytestoHEX=bytestoHEX
patterns.bytestohex=bytestohex
patterns.bytestodec=bytestodec
function string.toHEX(s)
 if not s or s=="" then
  return s
 else
  return lpegmatch(bytestoHEX,s)
 end
end
function string.tohex(s)
 if not s or s=="" then
  return s
 else
  return lpegmatch(bytestohex,s)
 end
end
function string.todec(s)
 if not s or s=="" then
  return s
 else
  return lpegmatch(bytestodec,s)
 end
end
function string.tobytes(s)
 if not s or s=="" then
  return s
 else
  return lpegmatch(hextobytes,s)
 end
end
local patterns={} 
local function containsws(what)
 local p=patterns[what]
 if not p then
  local p1=P(what)*(whitespace+endofstring)*Cc(true)
  local p2=whitespace*P(p1)
  p=P(p1)+P(1-p2)^0*p2+Cc(false)
  patterns[what]=p
 end
 return p
end
lpeg.containsws=containsws
function string.containsws(str,what)
 return lpegmatch(patterns[what] or containsws(what),str)
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-functions']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
functions=functions or {}
function functions.dummy() end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-string']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local string=string
local sub,gmatch,format,char,byte,rep,lower,find=string.sub,string.gmatch,string.format,string.char,string.byte,string.rep,string.lower,string.find
local lpegmatch,patterns=lpeg.match,lpeg.patterns
local P,S,C,Ct,Cc,Cs=lpeg.P,lpeg.S,lpeg.C,lpeg.Ct,lpeg.Cc,lpeg.Cs
local unquoted=patterns.squote*C(patterns.nosquote)*patterns.squote+patterns.dquote*C(patterns.nodquote)*patterns.dquote
function string.unquoted(str)
 return lpegmatch(unquoted,str) or str
end
function string.quoted(str)
 return format("%q",str) 
end
function string.count(str,pattern)
 local n=0
 local i=1
 local l=#pattern
 while true do
  i=find(str,pattern,i)
  if i then
   n=n+1
   i=i+l
  else
   break
  end
 end
 return n
end
function string.limit(str,n,sentinel) 
 if #str>n then
  sentinel=sentinel or "..."
  return sub(str,1,(n-#sentinel))..sentinel
 else
  return str
 end
end
local stripper=patterns.stripper
local fullstripper=patterns.fullstripper
local collapser=patterns.collapser
local nospacer=patterns.nospacer
local longtostring=patterns.longtostring
function string.strip(str)
 return str and lpegmatch(stripper,str) or ""
end
function string.fullstrip(str)
 return str and lpegmatch(fullstripper,str) or ""
end
function string.collapsespaces(str)
 return str and lpegmatch(collapser,str) or ""
end
function string.nospaces(str)
 return str and lpegmatch(nospacer,str) or ""
end
function string.longtostring(str)
 return str and lpegmatch(longtostring,str) or ""
end
local pattern=P(" ")^0*P(-1)
function string.is_empty(str)
 if not str or str=="" then
  return true
 else
  return lpegmatch(pattern,str) and true or false
 end
end
local anything=patterns.anything
local moreescapes=Cc("%")*S(".-+%?()[]*$^{}")
local allescapes=Cc("%")*S(".-+%?()[]*")   
local someescapes=Cc("%")*S(".-+%()[]")  
local matchescapes=Cc(".")*S("*?")     
local pattern_m=Cs ((moreescapes+anything )^0 )
local pattern_a=Cs ((allescapes+anything )^0 )
local pattern_b=Cs ((someescapes+matchescapes+anything )^0 )
local pattern_c=Cs (Cc("^")*(someescapes+matchescapes+anything )^0*Cc("$") )
function string.escapedpattern(str,simple)
 return lpegmatch(simple and pattern_b or pattern_a,str)
end
function string.topattern(str,lowercase,strict)
 if str=="" or type(str)~="string" then
  return ".*"
 elseif strict=="all" then
  str=lpegmatch(pattern_m,str)
 elseif strict then
  str=lpegmatch(pattern_c,str)
 else
  str=lpegmatch(pattern_b,str)
 end
 if lowercase then
  return lower(str)
 else
  return str
 end
end
function string.valid(str,default)
 return (type(str)=="string" and str~="" and str) or default or nil
end
string.itself=function(s) return s end
local pattern_c=Ct(C(1)^0) 
local pattern_b=Ct((C(1)/byte)^0)
function string.totable(str,bytes)
 return lpegmatch(bytes and pattern_b or pattern_c,str)
end
local replacer=lpeg.replacer("@","%%") 
function string.tformat(fmt,...)
 return format(lpegmatch(replacer,fmt),...)
end
string.quote=string.quoted
string.unquote=string.unquoted
if not string.bytetable then 
 local limit=5000 
 function string.bytetable(str) 
  local n=#str
  if n>limit then
   local t={ byte(str,1,limit) }
   for i=limit+1,n do
    t[i]=byte(str,i)
   end
   return t
  else
   return { byte(str,1,n) }
  end
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-table']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local type,next,tostring,tonumber,select,rawget=type,next,tostring,tonumber,select,rawget
local table,string=table,string
local concat,sort=table.concat,table.sort
local format,lower,dump=string.format,string.lower,string.dump
local getmetatable,setmetatable=getmetatable,setmetatable
local lpegmatch,patterns=lpeg.match,lpeg.patterns
local floor=math.floor
local stripper=patterns.stripper
function table.getn(t)
 return t and #t 
end
function table.strip(tab)
 local lst={}
 local l=0
 for i=1,#tab do
  local s=lpegmatch(stripper,tab[i]) or ""
  if s=="" then
  else
   l=l+1
   lst[l]=s
  end
 end
 return lst
end
function table.keys(t)
 if t then
  local keys={}
  local k=0
  for key in next,t do
   k=k+1
   keys[k]=key
  end
  return keys
 else
  return {}
 end
end
local function compare(a,b)
 local ta=type(a) 
 if ta=="number" then
  local tb=type(b) 
  if ta==tb then
   return a<b
  elseif tb=="string" then
   return tostring(a)<b
  end
 elseif ta=="string" then
  local tb=type(b) 
  if ta==tb then
   return a<b
  else
   return a<tostring(b)
  end
 end
 return tostring(a)<tostring(b) 
end
local function sortedkeys(tab)
 if tab then
  local srt={}
  local category=0 
  local s=0
  for key in next,tab do
   s=s+1
   srt[s]=key
   if category~=3 then
    local tkey=type(key)
    if category==1 then
     if tkey~="string" then
      category=3
     end
    elseif category==2 then
     if tkey~="number" then
      category=3
     end
    else
     if tkey=="string" then
      category=1
     elseif tkey=="number" then
      category=2
     else
      category=3
     end
    end
   end
  end
  if s<2 then
  elseif category==3 then
   sort(srt,compare)
  else
   sort(srt)
  end
  return srt
 else
  return {}
 end
end
local function sortedhashonly(tab)
 if tab then
  local srt={}
  local s=0
  for key in next,tab do
   if type(key)=="string" then
    s=s+1
    srt[s]=key
   end
  end
  if s>1 then
   sort(srt)
  end
  return srt
 else
  return {}
 end
end
local function sortedindexonly(tab)
 if tab then
  local srt={}
  local s=0
  for key in next,tab do
   if type(key)=="number" then
    s=s+1
    srt[s]=key
   end
  end
  if s>1 then
   sort(srt)
  end
  return srt
 else
  return {}
 end
end
local function sortedhashkeys(tab,cmp) 
 if tab then
  local srt={}
  local s=0
  for key in next,tab do
   if key then
    s=s+1
    srt[s]=key
   end
  end
  if s>1 then
   sort(srt,cmp)
  end
  return srt
 else
  return {}
 end
end
function table.allkeys(t)
 local keys={}
 for k,v in next,t do
  for k in next,v do
   keys[k]=true
  end
 end
 return sortedkeys(keys)
end
table.sortedkeys=sortedkeys
table.sortedhashonly=sortedhashonly
table.sortedindexonly=sortedindexonly
table.sortedhashkeys=sortedhashkeys
local function nothing() end
local function sortedhash(t,cmp)
 if t then
  local s
  if cmp then
   s=sortedhashkeys(t,function(a,b) return cmp(t,a,b) end)
  else
   s=sortedkeys(t) 
  end
  local m=#s
  if m==1 then
   return next,t
  elseif m>0 then
   local n=0
   return function()
    if n<m then
     n=n+1
     local k=s[n]
     return k,t[k]
    end
   end
  end
 end
 return nothing
end
table.sortedhash=sortedhash
table.sortedpairs=sortedhash 
function table.append(t,list)
 local n=#t
 for i=1,#list do
  n=n+1
  t[n]=list[i]
 end
 return t
end
function table.prepend(t,list)
 local nl=#list
 local nt=nl+#t
 for i=#t,1,-1 do
  t[nt]=t[i]
  nt=nt-1
 end
 for i=1,#list do
  t[i]=list[i]
 end
 return t
end
function table.merge(t,...) 
 if not t then
  t={}
 end
 for i=1,select("#",...) do
  for k,v in next,(select(i,...)) do
   t[k]=v
  end
 end
 return t
end
function table.merged(...)
 local t={}
 for i=1,select("#",...) do
  for k,v in next,(select(i,...)) do
   t[k]=v
  end
 end
 return t
end
function table.imerge(t,...)
 local nt=#t
 for i=1,select("#",...) do
  local nst=select(i,...)
  for j=1,#nst do
   nt=nt+1
   t[nt]=nst[j]
  end
 end
 return t
end
function table.imerged(...)
 local tmp={}
 local ntmp=0
 for i=1,select("#",...) do
  local nst=select(i,...)
  for j=1,#nst do
   ntmp=ntmp+1
   tmp[ntmp]=nst[j]
  end
 end
 return tmp
end
local function fastcopy(old,metatabletoo) 
 if old then
  local new={}
  for k,v in next,old do
   if type(v)=="table" then
    new[k]=fastcopy(v,metatabletoo) 
   else
    new[k]=v
   end
  end
  if metatabletoo then
   local mt=getmetatable(old)
   if mt then
    setmetatable(new,mt)
   end
  end
  return new
 else
  return {}
 end
end
local function copy(t,tables) 
 if not tables then
  tables={}
 end
 local tcopy={}
 if not tables[t] then
  tables[t]=tcopy
 end
 for i,v in next,t do 
  if type(i)=="table" then
   if tables[i] then
    i=tables[i]
   else
    i=copy(i,tables)
   end
  end
  if type(v)~="table" then
   tcopy[i]=v
  elseif tables[v] then
   tcopy[i]=tables[v]
  else
   tcopy[i]=copy(v,tables)
  end
 end
 local mt=getmetatable(t)
 if mt then
  setmetatable(tcopy,mt)
 end
 return tcopy
end
table.fastcopy=fastcopy
table.copy=copy
function table.derive(parent) 
 local child={}
 if parent then
  setmetatable(child,{ __index=parent })
 end
 return child
end
function table.tohash(t,value)
 local h={}
 if t then
  if value==nil then value=true end
  for _,v in next,t do
   h[v]=value
  end
 end
 return h
end
function table.fromhash(t)
 local hsh={}
 local h=0
 for k,v in next,t do
  if v then
   h=h+1
   hsh[h]=k
  end
 end
 return hsh
end
local noquotes,hexify,handle,compact,inline,functions,metacheck,accurate
local reserved=table.tohash { 
 'and','break','do','else','elseif','end','false','for','function','if',
 'in','local','nil','not','or','repeat','return','then','true','until','while',
 'NaN','goto','const',
}
local function is_simple_table(t,hexify,accurate) 
 local nt=#t
 if nt>0 then
  local n=0
  for _,v in next,t do
   n=n+1
   if type(v)=="table" then
    return nil
   end
  end
  local haszero=rawget(t,0) 
  if n==nt then
   local tt={}
   for i=1,nt do
    local v=t[i]
    local tv=type(v)
    if tv=="number" then
     if hexify then
      tt[i]=format("0x%X",v)
     elseif accurate then
      tt[i]=format("%q",v)
     else
      tt[i]=v 
     end
    elseif tv=="string" then
     tt[i]=format("%q",v) 
    elseif tv=="boolean" then
     tt[i]=v and "true" or "false"
    else
     return nil
    end
   end
   return tt
  elseif haszero and (n==nt+1) then
   local tt={}
   for i=0,nt do
    local v=t[i]
    local tv=type(v)
    if tv=="number" then
     if hexify then
      tt[i+1]=format("0x%X",v)
     elseif accurate then
      tt[i+1]=format("%q",v)
     else
      tt[i+1]=v 
     end
    elseif tv=="string" then
     tt[i+1]=format("%q",v) 
    elseif tv=="boolean" then
     tt[i+1]=v and "true" or "false"
    else
     return nil
    end
   end
   tt[1]="[0] = "..tt[1]
   return tt
  end
 end
 return nil
end
table.is_simple_table=is_simple_table
local propername=patterns.propername 
local function dummy() end
local function do_serialize(root,name,depth,level,indexed)
 if level>0 then
  depth=depth.." "
  if indexed then
   handle(format("%s{",depth))
  else
   local tn=type(name)
   if tn=="number" then
    if hexify then
     handle(format("%s[0x%X]={",depth,name))
    else
     handle(format("%s[%s]={",depth,name))
    end
   elseif tn=="string" then
    if noquotes and not reserved[name] and lpegmatch(propername,name) then
     handle(format("%s%s={",depth,name))
    else
     handle(format("%s[%q]={",depth,name))
    end
   elseif tn=="boolean" then
    handle(format("%s[%s]={",depth,name and "true" or "false"))
   else
    handle(format("%s{",depth))
   end
  end
 end
 if root and next(root)~=nil then
  local first=nil
  local last=0
  if compact then
   last=#root
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
   if compact and first and tk=="number" and k>=first and k<=last then
    if tv=="number" then
     if hexify then
      handle(format("%s 0x%X,",depth,v))
     elseif accurate then
      handle(format("%s %q,",depth,v))
     else
      handle(format("%s %s,",depth,v)) 
     end
    elseif tv=="string" then
     handle(format("%s %q,",depth,v))
    elseif tv=="table" then
     if next(v)==nil then
      handle(format("%s {},",depth))
     elseif inline then 
      local st=is_simple_table(v,hexify,accurate)
      if st then
       handle(format("%s { %s },",depth,concat(st,", ")))
      else
       do_serialize(v,k,depth,level+1,true)
      end
     else
      do_serialize(v,k,depth,level+1,true)
     end
    elseif tv=="boolean" then
     handle(format("%s %s,",depth,v and "true" or "false"))
    elseif tv=="function" then
     if functions then
      handle(format('%s load(%q),',depth,dump(v))) 
     else
      handle(format('%s "function",',depth))
     end
    else
     handle(format("%s %q,",depth,tostring(v)))
    end
   elseif k=="__p__" then 
    if false then
     handle(format("%s __p__=nil,",depth))
    end
   elseif tv=="number" then
    if tk=="number" then
     if hexify then
      handle(format("%s [0x%X]=0x%X,",depth,k,v))
     elseif accurate then
      handle(format("%s [%s]=%q,",depth,k,v))
     else
      handle(format("%s [%s]=%s,",depth,k,v)) 
     end
    elseif tk=="boolean" then
     if hexify then
      handle(format("%s [%s]=0x%X,",depth,k and "true" or "false",v))
     elseif accurate then
      handle(format("%s [%s]=%q,",depth,k and "true" or "false",v))
     else
      handle(format("%s [%s]=%s,",depth,k and "true" or "false",v)) 
     end
    elseif tk~="string" then
    elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
     if hexify then
      handle(format("%s %s=0x%X,",depth,k,v))
     elseif accurate then
      handle(format("%s %s=%q,",depth,k,v))
     else
      handle(format("%s %s=%s,",depth,k,v)) 
     end
    else
     if hexify then
      handle(format("%s [%q]=0x%X,",depth,k,v))
     elseif accurate then
      handle(format("%s [%q]=%q,",depth,k,v))
     else
      handle(format("%s [%q]=%s,",depth,k,v)) 
     end
    end
   elseif tv=="string" then
    if tk=="number" then
     if hexify then
      handle(format("%s [0x%X]=%q,",depth,k,v))
     elseif accurate then
      handle(format("%s [%q]=%q,",depth,k,v))
     else
      handle(format("%s [%s]=%q,",depth,k,v))
     end
    elseif tk=="boolean" then
     handle(format("%s [%s]=%q,",depth,k and "true" or "false",v))
    elseif tk~="string" then
    elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
     handle(format("%s %s=%q,",depth,k,v))
    else
     handle(format("%s [%q]=%q,",depth,k,v))
    end
   elseif tv=="table" then
    if next(v)==nil then
     if tk=="number" then
      if hexify then
       handle(format("%s [0x%X]={},",depth,k))
      elseif accurate then
       handle(format("%s [%q]={},",depth,k))
      else
       handle(format("%s [%s]={},",depth,k))
      end
     elseif tk=="boolean" then
      handle(format("%s [%s]={},",depth,k and "true" or "false"))
     elseif tk~="string" then
     elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
      handle(format("%s %s={},",depth,k))
     else
      handle(format("%s [%q]={},",depth,k))
     end
    elseif inline then
     local st=is_simple_table(v,hexify,accurate)
     if st then
      if tk=="number" then
       if hexify then
        handle(format("%s [0x%X]={ %s },",depth,k,concat(st,", ")))
       elseif accurate then
        handle(format("%s [%q]={ %s },",depth,k,concat(st,", ")))
       else
        handle(format("%s [%s]={ %s },",depth,k,concat(st,", ")))
       end
      elseif tk=="boolean" then
       handle(format("%s [%s]={ %s },",depth,k and "true" or "false",concat(st,", ")))
      elseif tk~="string" then
      elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
       handle(format("%s %s={ %s },",depth,k,concat(st,", ")))
      else
       handle(format("%s [%q]={ %s },",depth,k,concat(st,", ")))
      end
     else
      do_serialize(v,k,depth,level+1)
     end
    else
     do_serialize(v,k,depth,level+1)
    end
   elseif tv=="boolean" then
    if tk=="number" then
     if hexify then
      handle(format("%s [0x%X]=%s,",depth,k,v and "true" or "false"))
     elseif accurate then
      handle(format("%s [%q]=%s,",depth,k,v and "true" or "false"))
     else
      handle(format("%s [%s]=%s,",depth,k,v and "true" or "false"))
     end
    elseif tk=="boolean" then
     handle(format("%s [%s]=%s,",depth,tostring(k),v and "true" or "false"))
    elseif tk~="string" then
    elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
     handle(format("%s %s=%s,",depth,k,v and "true" or "false"))
    else
     handle(format("%s [%q]=%s,",depth,k,v and "true" or "false"))
    end
   elseif tv=="function" then
    if functions then
     local getinfo=debug and debug.getinfo
     if getinfo then
      local f=getinfo(v).what=="C" and dump(dummy) or dump(v)
      if tk=="number" then
       if hexify then
        handle(format("%s [0x%X]=load(%q),",depth,k,f))
       elseif accurate then
        handle(format("%s [%q]=load(%q),",depth,k,f))
       else
        handle(format("%s [%s]=load(%q),",depth,k,f))
       end
      elseif tk=="boolean" then
       handle(format("%s [%s]=load(%q),",depth,k and "true" or "false",f))
      elseif tk~="string" then
      elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
       handle(format("%s %s=load(%q),",depth,k,f))
      else
       handle(format("%s [%q]=load(%q),",depth,k,f))
      end
     end
    end
   else
    if tk=="number" then
     if hexify then
      handle(format("%s [0x%X]=%q,",depth,k,tostring(v)))
     elseif accurate then
      handle(format("%s [%q]=%q,",depth,k,tostring(v)))
     else
      handle(format("%s [%s]=%q,",depth,k,tostring(v)))
     end
    elseif tk=="boolean" then
     handle(format("%s [%s]=%q,",depth,k and "true" or "false",tostring(v)))
    elseif tk~="string" then
    elseif noquotes and not reserved[k] and lpegmatch(propername,k) then
     handle(format("%s %s=%q,",depth,k,tostring(v)))
    else
     handle(format("%s [%q]=%q,",depth,k,tostring(v)))
    end
   end
  end
 end
 if level>0 then
  handle(format("%s},",depth))
 end
end
local function serialize(_handle,root,name,specification) 
 local tname=type(name)
 if type(specification)=="table" then
  noquotes=specification.noquotes
  hexify=specification.hexify
  accurate=specification.accurate
  handle=_handle or specification.handle or print
  functions=specification.functions
  compact=specification.compact
  inline=specification.inline and compact
  metacheck=specification.metacheck
  if functions==nil then
   functions=true
  end
  if compact==nil then
   compact=true
  end
  if inline==nil then
   inline=compact
  end
  if metacheck==nil then
   metacheck=true
  end
 else
  noquotes=false
  hexify=false
  handle=_handle or print
  compact=true
  inline=true
  functions=true
  metacheck=true
 end
 if tname=="string" then
  if name=="return" then
   handle("return {")
  else
   handle(name.."={")
  end
 elseif tname=="number" then
  if hexify then
   handle(format("[0x%X]={",name))
  else
   handle("["..name.."]={")
  end
 elseif tname=="boolean" then
  if name then
   handle("return {")
  else
   handle("{")
  end
 else
  handle("t={")
 end
 if root then
  if metacheck and getmetatable(root) then
   local dummy=root._w_h_a_t_e_v_e_r_
   root._w_h_a_t_e_v_e_r_=nil
  end
  if next(root)~=nil then
   do_serialize(root,name,"",0)
  end
 end
 handle("}")
end
function table.serialize(root,name,specification)
 local t={}
 local n=0
 local function flush(s)
  n=n+1
  t[n]=s
 end
 serialize(flush,root,name,specification)
 return concat(t,"\n")
end
table.tohandle=serialize
local maxtab=2*1024
function table.tofile(filename,root,name,specification)
 local f=io.open(filename,'w')
 if f then
  if maxtab>1 then
   local t={}
   local n=0
   local function flush(s)
    n=n+1
    t[n]=s
    if n>maxtab then
     f:write(concat(t,"\n"),"\n") 
     t={} 
     n=0
    end
   end
   serialize(flush,root,name,specification)
   f:write(concat(t,"\n"),"\n")
  else
   local function flush(s)
    f:write(s,"\n")
   end
   serialize(flush,root,name,specification)
  end
  f:close()
  io.flush()
 end
end
local function flattened(t,f,depth) 
 if f==nil then
  f={}
  depth=0xFFFF
 elseif tonumber(f) then
  depth=f
  f={}
 elseif not depth then
  depth=0xFFFF
 end
 for k,v in next,t do
  if type(k)~="number" then
   if depth>0 and type(v)=="table" then
    flattened(v,f,depth-1)
   else
    f[#f+1]=v
   end
  end
 end
 for k=1,#t do
  local v=t[k]
  if depth>0 and type(v)=="table" then
   flattened(v,f,depth-1)
  else
   f[#f+1]=v
  end
 end
 return f
end
table.flattened=flattened
local function collapsed(t,f,h)
 if f==nil then
  f={}
  h={}
 end
 for k=1,#t do
  local v=t[k]
  if type(v)=="table" then
   collapsed(v,f,h)
  elseif not h[v] then
   f[#f+1]=v
   h[v]=true
  end
 end
 return f
end
local function collapsedhash(t,h)
 if h==nil then
  h={}
 end
 for k=1,#t do
  local v=t[k]
  if type(v)=="table" then
   collapsedhash(v,h)
  else
   h[v]=true
  end
 end
 return h
end
table.collapsed=collapsed  
table.collapsedhash=collapsedhash
local function unnest(t,f) 
 if not f then    
  f={}   
 end
 for i=1,#t do
  local v=t[i]
  if type(v)=="table" then
   if type(v[1])=="table" then
    unnest(v,f)
   else
    f[#f+1]=v
   end
  else
   f[#f+1]=v
  end
 end
 return f
end
function table.unnest(t) 
 return unnest(t)
end
local function are_equal(a,b,n,m) 
 if a==b then
  return true
 elseif a and b and #a==#b then
  if not n then
   n=1
  end
  if not m then
   m=#a
  end
  for i=n,m do
   local ai,bi=a[i],b[i]
   if ai==bi then
   elseif type(ai)=="table" and type(bi)=="table" then
    if not are_equal(ai,bi) then
     return false
    end
   else
    return false
   end
  end
  return true
 else
  return false
 end
end
local function identical(a,b) 
 if a~=b then
  for ka,va in next,a do
   local vb=b[ka]
   if va==vb then
   elseif type(va)=="table" and  type(vb)=="table" then
    if not identical(va,vb) then
     return false
    end
   else
    return false
   end
  end
 end
 return true
end
table.identical=identical
table.are_equal=are_equal
local function sparse(old,nest,keeptables)
 local new={}
 for k,v in next,old do
  if not (v=="" or v==false) then
   if nest and type(v)=="table" then
    v=sparse(v,nest)
    if keeptables or next(v)~=nil then
     new[k]=v
    end
   else
    new[k]=v
   end
  end
 end
 return new
end
table.sparse=sparse
function table.compact(t)
 return sparse(t,true,true)
end
function table.contains(t,v)
 if t then
  for i=1,#t do
   if t[i]==v then
    return i
   end
  end
 end
 return false
end
function table.count(t)
 local n=0
 for k,v in next,t do
  n=n+1
 end
 return n
end
function table.swapped(t,s) 
 local n={}
 if s then
  for k,v in next,s do
   n[k]=v
  end
 end
 for k,v in next,t do
  n[v]=k
 end
 return n
end
function table.hashed(t) 
 for i=1,#t do
  t[t[i]]=i
 end
 return t
end
function table.mirrored(t) 
 local n={}
 for k,v in next,t do
  n[v]=k
  n[k]=v
 end
 return n
end
function table.reversed(t)
 if t then
  local tt={}
  local tn=#t
  if tn>0 then
   local ttn=0
   for i=tn,1,-1 do
    ttn=ttn+1
    tt[ttn]=t[i]
   end
  end
  return tt
 end
end
function table.reverse(t) 
 if t then
  local n=#t
  local m=n+1
  for i=1,floor(n/2) do 
   local j=m-i
   t[i],t[j]=t[j],t[i]
  end
  return t
 end
end
local function sequenced(t,sep,simple)
 if not t then
  return ""
 elseif type(t)~="table" then
  return t 
 end
 local n=#t
 local s={}
 if n>0 then
  for i=1,n do
   local v=t[i]
   if type(v)=="table" then
    s[i]="{"..sequenced(v,sep,simple).."}"
   else
    s[i]=tostring(t[i])
   end
  end
 else
  n=0
  for k,v in sortedhash(t) do
   if simple then
    if v==true then
     n=n+1
     s[n]=k
    elseif v and v~="" then
     n=n+1
     if type(v)=="table" then
      s[n]=k.."={"..sequenced(v,sep,simple).."}"
     else
      s[n]=k.."="..tostring(v)
     end
    end
   else
    n=n+1
    if type(v)=="table" then
     s[n]=k.."={"..sequenced(v,sep,simple).."}"
    else
     s[n]=k.."="..tostring(v)
    end
   end
  end
 end
 if sep==true then
  return "{ "..concat(s,", ").." }"
 else
  return concat(s,sep or " | ")
 end
end
table.sequenced=sequenced
function table.print(t,...)
 if type(t)~="table" then
  print(tostring(t))
 else
  serialize(print,t,...)
 end
end
if setinspector then
 setinspector("table",function(v) if type(v)=="table" then serialize(print,v,"table") return true end end)
end
function table.sub(t,i,j)
 return { unpack(t,i,j) }
end
function table.is_empty(t)
 return not t or next(t)==nil
end
function table.has_one_entry(t)
 return t and next(t,next(t))==nil
end
function table.loweredkeys(t) 
 local l={}
 for k,v in next,t do
  l[lower(k)]=v
 end
 return l
end
function table.unique(old)
 local hash={}
 local new={}
 local n=0
 for i=1,#old do
  local oi=old[i]
  if not hash[oi] then
   n=n+1
   new[n]=oi
   hash[oi]=true
  end
 end
 return new
end
function table.sorted(t,...)
 sort(t,...)
 return t 
end
function table.values(t,s) 
 if t then
  local values={}
  local keys={}
  local v=0
  for key,value in next,t do
   if not keys[value] then
    v=v+1
    values[v]=value
    keys[k]=key
   end
  end
  if s then
   sort(values)
  end
  return values
 else
  return {}
 end
end
function table.filtered(t,pattern,sort,cmp)
 if t and type(pattern)=="string" then
  if sort then
   local s
   if cmp then
    s=sortedhashkeys(t,function(a,b) return cmp(t,a,b) end)
   else
    s=sortedkeys(t) 
   end
   local n=0
   local m=#s
   local function kv(s)
    while n<m do
     n=n+1
     local k=s[n]
     if find(k,pattern) then
      return k,t[k]
     end
    end
   end
   return kv,s
  else
   local n=next(t)
   local function iterator()
    while n~=nil do
     local k=n
     n=next(t,k)
     if find(k,pattern) then
      return k,t[k]
     end
    end
   end
   return iterator,t
  end
 else
  return nothing
 end
end
if not table.move then
 function table.move(a1,f,e,t,a2)
  if a2 and a1~=a2 then
   for i=f,e do
    a2[t]=a1[i]
    t=t+1
   end
   return a2
  else
   t=t+e-f
   for i=e,f,-1 do
    a1[t]=a1[i]
    t=t-1
   end
   return a1
  end
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-boolean']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local type,tonumber=type,tonumber
boolean=boolean or {}
local boolean=boolean
function boolean.tonumber(b)
 if b then return 1 else return 0 end 
end
function toboolean(str,tolerant) 
 if  str==nil then
  return false
 elseif str==false then
  return false
 elseif str==true then
  return true
 elseif str=="true" then
  return true
 elseif str=="false" then
  return false
 elseif not tolerant then
  return false
 elseif str==0 then
  return false
 elseif (tonumber(str) or 0)>0 then
  return true
 else
  return str=="yes" or str=="on" or str=="t"
 end
end
string.toboolean=toboolean
function string.booleanstring(str)
 if str=="0" then
  return false
 elseif str=="1" then
  return true
 elseif str=="" then
  return false
 elseif str=="false" then
  return false
 elseif str=="true" then
  return true
 elseif (tonumber(str) or 0)>0 then
  return true
 else
  return str=="yes" or str=="on" or str=="t"
 end
end
function string.is_boolean(str,default,strict)
 if type(str)=="string" then
  if str=="true" or str=="yes" or str=="on" or str=="t" or (not strict and str=="1") then
   return true
  elseif str=="false" or str=="no" or str=="off" or str=="f" or (not strict and str=="0") then
   return false
  end
 end
 return default
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-number']={
 version=1.001,
 comment="companion to luat-lib.mkxl",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local tostring,tonumber=tostring,tonumber
local format,match,rep=string.format,string.match,string.rep
local concat,insert=table.concat,table.insert
local lpegmatch=lpeg.match
local floor=math.floor
number=number or {}
local number=number
if bit32 then
 local bextract=bit32.extract
 local t={
  "0","0","0","0","0","0","0","0",
  "0","0","0","0","0","0","0","0",
  "0","0","0","0","0","0","0","0",
  "0","0","0","0","0","0","0","0",
 }
 function number.tobitstring(b,m,w)
  if not w then
   w=32
  end
  local n=w
  for i=0,w-1 do
   local v=bextract(b,i)
   local k=w-i
   if v==1 then
    n=k
    t[k]="1"
   else
    t[k]="0"
   end
  end
  if w then
   return concat(t,"",1,w)
  elseif m then
   m=33-m*8
   if m<1 then
    m=1
   end
   return concat(t,"",1,m)
  elseif n<8 then
   return concat(t)
  elseif n<16 then
   return concat(t,"",9)
  elseif n<24 then
   return concat(t,"",17)
  else
   return concat(t,"",25)
  end
 end
else
 function number.tobitstring(n,m)
  if n>0 then
   local t={}
   while n>0 do
    insert(t,1,n%2>0 and 1 or 0)
    n=floor(n/2)
   end
   local nn=8-#t%8
   if nn>0 and nn<8 then
    for i=1,nn do
     insert(t,1,0)
    end
   end
   if m then
    m=m*8-#t
    if m>0 then
     insert(t,1,rep("0",m))
    end
   end
   return concat(t)
  elseif m then
   rep("00000000",m)
  else
   return "00000000"
  end
 end
end
function number.valid(str,default)
 return tonumber(str) or default or nil
end
function number.toevenhex(n)
 local s=format("%X",n)
 if #s%2==0 then
  return s
 else
  return "0"..s
 end
end
function number.bytetodecimal(b)
 local d=floor(b*100/255+0.5)
 if d>100 then
  return 100
 elseif d<-100 then
  return -100
 else
  return d
 end
end
function number.decimaltobyte(d)
 local b=floor(d*255/100+0.5)
 if b>255 then
  return 255
 elseif b<-255 then
  return -255
 else
  return b
 end
end
function number.idiv(i,d)
 return floor(i/d) 
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-math']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
if not math.ceiling then
 math.ceiling=math.ceil
end
if not math.round then
 if xmath then
  math.round=xmath.round
 else
  local floor=math.floor
  function math.round(x)
   return x<0 and -floor(-x+0.5) or floor(x+0.5)
  end
 end
end
if not math.div then
 local floor=math.floor
 function math.div(n,m) return floor(n/m) end
end
if not math.mod then
 function math.mod(n,m) return n%m end
end
if not math.sind then
 local sin,cos,tan=math.sin,math.cos,math.tan
 local pipi=2*math.pi/360
 function math.sind(d) return sin(d*pipi) end
 function math.cosd(d) return cos(d*pipi) end
 function math.tand(d) return tan(d*pipi) end
end
if not math.odd then
 function math.odd (n) return n%2~=0 end
 function math.even(n) return n%2==0 end
end
if not math.cosh then
 local exp=math.exp
 function math.cosh(x)
  local xx=exp(x)
  return (xx+1/xx)/2
 end
 function math.sinh(x)
  local xx=exp(x)
  return (xx-1/xx)/2
 end
 function math.tanh(x)
  local xx=exp(x)
  return (xx-1/xx)/(xx+1/xx)
 end
end
if not math.pow then
 function math.pow(x,y)
  return x^y
 end
end
if not math.atan2 then
 math.atan2=math.atan
end
if not math.ldexp then
 function math.ldexp(x,e)
  return x*2.0^e
 end
end
if not math.log10 then
 local log=math.log
 function math.log10(x)
  return log(x,10)
 end
end
if not math.type then
 function math.type()
  return "float"
 end
end
if not math.tointeger then
 math.mininteger=-0x4FFFFFFFFFFF
 math.maxinteger=0x4FFFFFFFFFFF
 local floor=math.floor
 function math.tointeger(n)
  local f=floor(n)
  return f==n and f or nil
 end
end
if not math.ult then
 local floor=math.floor
 function math.ult(m,n)
  return floor(m)<floor(n) 
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-io']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local io=io
local open,flush,write,read=io.open,io.flush,io.write,io.read
local byte,find,gsub,format=string.byte,string.find,string.gsub,string.format
local concat=table.concat
local type=type
if string.find(os.getenv("PATH") or "",";",1,true) then
 io.fileseparator,io.pathseparator="\\",";"
else
 io.fileseparator,io.pathseparator="/",":"
end
local large=0x01000000 
local medium=0x00100000 
local small=0x00020000
local function readall(f)
 local size=f:seek("end")
 if size>0 then
  f:seek("set",0)
  return f:read(size)
 else
  return ""
 end
end
io.readall=readall
function io.loaddata(filename,textmode) 
 local f=open(filename,(textmode and 'r') or 'rb')
 if f then
  local size=f:seek("end")
  local data=nil
  if size>0 then
   f:seek("set",0)
   data=f:read(size)
  end
  f:close()
  return data
 end
end
function io.copydata(source,target,action)
 local f=open(source,"rb")
 if f then
  local g=open(target,"wb")
  if g then
   local size=f:seek("end")
   if size>0 then
    f:seek("set",0)
    local data=f:read(size)
    if action then
     data=action(data)
    end
    if data then
     g:write(data)
    end
   end
   g:close()
  end
  f:close()
  flush()
 end
end
function io.savedata(filename,data,joiner,append)
 local f=open(filename,append and "ab" or "wb")
 if f then
  if append and joiner and f:seek("end")>0 then
   f:write(joiner)
  end
  if type(data)=="table" then
   f:write(concat(data,joiner or ""))
  elseif type(data)=="function" then
   data(f)
  else
   f:write(data or "")
  end
  f:close()
  flush()
  return true
 else
  return false
 end
end
if fio and fio.readline then
 local readline=fio.readline
 function io.loadlines(filename,n) 
  local f=open(filename,'r')
  if not f then
  elseif n then
   local lines={}
   for i=1,n do
    local line=readline(f)
    if line then
     lines[i]=line
    else
     break
    end
   end
   f:close()
   lines=concat(lines,"\n")
   if #lines>0 then
    return lines
   end
  else
   local line=readline(f)
   f:close()
   if line and #line>0 then
    return line
   end
  end
 end
else
 function io.loadlines(filename,n) 
  local f=open(filename,'r')
  if not f then
  elseif n then
   local lines={}
   for i=1,n do
    local line=f:read("*lines")
    if line then
     lines[i]=line
    else
     break
    end
   end
   f:close()
   lines=concat(lines,"\n")
   if #lines>0 then
    return lines
   end
  else
   local line=f:read("*line") or ""
   f:close()
   if #line>0 then
    return line
   end
  end
 end
end
function io.loadchunk(filename,n)
 local f=open(filename,'rb')
 if f then
  local data=f:read(n or 1024)
  f:close()
  if #data>0 then
   return data
  end
 end
end
function io.exists(filename)
 local f=open(filename)
 if f==nil then
  return false
 else
  f:close()
  return true
 end
end
function io.size(filename)
 local f=open(filename)
 if f==nil then
  return 0
 else
  local s=f:seek("end")
  f:close()
  return s
 end
end
local function noflines(f)
 if type(f)=="string" then
  local f=open(filename)
  if f then
   local n=f and noflines(f) or 0
   f:close()
   return n
  else
   return 0
  end
 else
  local n=0
  for _ in f:lines() do
   n=n+1
  end
  f:seek('set',0)
  return n
 end
end
io.noflines=noflines
local nextchar={
 [ 4]=function(f)
  return f:read(1,1,1,1)
 end,
 [ 2]=function(f)
  return f:read(1,1)
 end,
 [ 1]=function(f)
  return f:read(1)
 end,
 [-2]=function(f)
  local a,b=f:read(1,1)
  return b,a
 end,
 [-4]=function(f)
  local a,b,c,d=f:read(1,1,1,1)
  return d,c,b,a
 end
}
function io.characters(f,n)
 if f then
  return nextchar[n or 1],f
 end
end
local nextbyte={
 [4]=function(f)
  local a,b,c,d=f:read(1,1,1,1)
  if d then
   return byte(a),byte(b),byte(c),byte(d)
  end
 end,
 [3]=function(f)
  local a,b,c=f:read(1,1,1)
  if b then
   return byte(a),byte(b),byte(c)
  end
 end,
 [2]=function(f)
  local a,b=f:read(1,1)
  if b then
   return byte(a),byte(b)
  end
 end,
 [1]=function (f)
  local a=f:read(1)
  if a then
   return byte(a)
  end
 end,
 [-2]=function (f)
  local a,b=f:read(1,1)
  if b then
   return byte(b),byte(a)
  end
 end,
 [-3]=function(f)
  local a,b,c=f:read(1,1,1)
  if b then
   return byte(c),byte(b),byte(a)
  end
 end,
 [-4]=function(f)
  local a,b,c,d=f:read(1,1,1,1)
  if d then
   return byte(d),byte(c),byte(b),byte(a)
  end
 end
}
function io.bytes(f,n)
 if f then
  return nextbyte[n or 1],f
 else
  return nil,nil
 end
end
function io.ask(question,default,options)
 while true do
  write(question)
  if options then
   write(format(" [%s]",concat(options,"|")))
  end
  if default then
   write(format(" [%s]",default))
  end
  write(format(" "))
  flush()
  local answer=read()
  answer=gsub(answer,"^%s*(.*)%s*$","%1")
  if answer=="" and default then
   return default
  elseif not options then
   return answer
  else
   for k=1,#options do
    if options[k]==answer then
     return answer
    end
   end
   local pattern="^"..answer
   for k=1,#options do
    local v=options[k]
    if find(v,pattern) then
     return v
    end
   end
  end
 end
end
local function readnumber(f,n,m) 
 if m then
  f:seek("set",n)
  n=m
 end
 if n==1 then
  return byte(f:read(1))
 elseif n==2 then
  local a,b=byte(f:read(2),1,2)
  return 0x100*a+b
 elseif n==3 then
  local a,b,c=byte(f:read(3),1,3)
  return 0x10000*a+0x100*b+c
 elseif n==4 then
  local a,b,c,d=byte(f:read(4),1,4)
  return 0x1000000*a+0x10000*b+0x100*c+d
 elseif n==8 then
  local a,b=readnumber(f,4),readnumber(f,4)
  return 0x100*a+b
 elseif n==12 then
  local a,b,c=readnumber(f,4),readnumber(f,4),readnumber(f,4)
  return 0x10000*a+0x100*b+c
 elseif n==-2 then
  local b,a=byte(f:read(2),1,2)
  return 0x100*a+b
 elseif n==-3 then
  local c,b,a=byte(f:read(3),1,3)
  return 0x10000*a+0x100*b+c
 elseif n==-4 then
  local d,c,b,a=byte(f:read(4),1,4)
  return 0x1000000*a+0x10000*b+0x100*c+d
 elseif n==-8 then
  local h,g,f,e,d,c,b,a=byte(f:read(8),1,8)
  return 0x100000000000000*a+0x1000000000000*b+0x10000000000*c+0x100000000*d+0x1000000*e+0x10000*f+0x100*g+h
 else
  return 0
 end
end
io.readnumber=readnumber
function io.readstring(f,n,m)
 if m then
  f:seek("set",n)
  n=m
 end
 local str=gsub(f:read(n),"\000","")
 return str
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-os']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local os=os
local date,time,difftime=os.date,os.time,os.difftime
local find,format,gsub,upper,gmatch=string.find,string.format,string.gsub,string.upper,string.gmatch
local concat=table.concat
local random,ceil,randomseed,modf=math.random,math.ceil,math.randomseed,math.modf
local type,setmetatable,tonumber,tostring=type,setmetatable,tonumber,tostring
do
 local selfdir=os.selfdir
 if selfdir=="" then
  selfdir=nil
 end
 if not selfdir then
  if arg then
   for i=1,#arg do
    local a=arg[i]
    if find(a,"^%-%-[c:]*texmfbinpath=") then
     selfdir=gsub(a,"^.-=","")
     break
    end
   end
  end
  if not selfdir then
   selfdir=os.selfbin or "luatex"
   if find(selfdir,"[/\\]") then
    selfdir=gsub(selfdir,"[/\\][^/\\]*$","")
   elseif os.getenv then
    local path=os.getenv("PATH")
    local name=gsub(selfdir,"^.*[/\\][^/\\]","")
    local patt="[^:]+"
    if os.type=="windows" then
     patt="[^;]+"
     name=name..".exe"
    end
    local isfile
    if lfs then
     local attributes=lfs.attributes
     isfile=function(name)
      local a=attributes(name,"mode")
      return a=="file" or a=="link" or nil
     end
    else
     local open=io.open
     isfile=function(name)
      local f=open(name)
      if f then
       f:close()
       return true
      end
     end
    end
    for p in gmatch(path,patt) do
     if isfile(p.."/"..name) then
      selfdir=p
      break
     end
    end
   end
  end
  os.selfdir=selfdir or "."
 end
end
math.initialseed=tonumber(string.sub(string.reverse(tostring(ceil(socket and socket.gettime()*10000 or time()))),1,6))
randomseed(math.initialseed)
if not os.__getenv__ then
 os.__getenv__=os.getenv
 os.__setenv__=os.setenv
 if os.env then
  local osgetenv=os.getenv
  local ossetenv=os.setenv
  local osenv=os.env   local _=osenv.PATH 
  function os.setenv(k,v)
   if v==nil then
    v=""
   end
   local K=upper(k)
   osenv[K]=v
   if type(v)=="table" then
    v=concat(v,";") 
   end
   ossetenv(K,v)
  end
  function os.getenv(k)
   local K=upper(k)
   local v=osenv[K] or osenv[k] or osgetenv(K) or osgetenv(k)
   if v=="" then
    return nil
   else
    return v
   end
  end
 else
  local ossetenv=os.setenv
  local osgetenv=os.getenv
  local osenv={}
  function os.setenv(k,v)
   if v==nil then
    v=""
   end
   local K=upper(k)
   osenv[K]=v
  end
  function os.getenv(k)
   local K=upper(k) 
   local v=osenv[K] or osgetenv(K) or osgetenv(k)
   if v=="" then
    return nil
   else
    return v
   end
  end
  local function __index(t,k)
   return os.getenv(k)
  end
  local function __newindex(t,k,v)
   os.setenv(k,v)
  end
  os.env={}
  setmetatable(os.env,{ __index=__index,__newindex=__newindex } )
 end
end
if not io.fileseparator then
 if find(os.getenv("PATH"),";",1,true) then
  io.fileseparator,io.pathseparator,os.type="\\",";",os.type or "windows"
 else
  io.fileseparator,io.pathseparator,os.type="/",":",os.type or "unix"
 end
end
os.type=os.type or (io.pathseparator==";"    and "windows") or "unix"
os.name=os.name or (os.type=="windows" and "mswin"  ) or "linux"
if os.type=="windows" then
 os.libsuffix,os.binsuffix,os.binsuffixes='dll','exe',{ 'exe','cmd','bat' }
else
 os.libsuffix,os.binsuffix,os.binsuffixes='so','',{ '' }
end
do
 local execute=os.execute
 local iopopen=io.popen
 local ostype=os.type
 local function resultof(command)
  local handle=iopopen(command,ostype=="windows" and "rb" or "r")
  if handle then
   local result=handle:read("*all") or ""
   handle:close()
   return result
  else
   return ""
  end
 end
 os.resultof=resultof
 function os.pipeto(command)
  return iopopen(command,"w") 
 end
 local launchers={
  windows="start %s",
  macosx="open %s",
  unix="xdg-open %s &> /dev/null &",
 }
 function os.launch(str)
  local command=format(launchers[os.name] or launchers.unix,str)
  execute(command)
 end
end
do
 local gettimeofday=os.gettimeofday or os.clock
 os.gettimeofday=gettimeofday
 local startuptime=gettimeofday()
 function os.runtime()
  return gettimeofday()-startuptime
 end
end
do
 local name=os.name or "linux"
 local platform=os.getenv("MTX_PLATFORM") or ""
 local architecture=os.uname and os.uname().machine 
 local bits=os.getenv("MTX_BITS") or find(platform,"64") and 64 or 32
 if platform~="" then
 elseif os.type=="windows" then
  architecture=string.lower(architecture or os.getenv("PROCESSOR_ARCHITECTURE") or "")
  if architecture=="x86_64" then
   bits,platform=64,"win64"
  elseif find(architecture,"amd64") then
   bits,platform=64,"win64"
  elseif find(architecture,"arm64") then
   bits,platform=64,"windows-arm64"
  elseif find(architecture,"arm32") then
   bits,platform=32,"windows-arm32"
  else
   bits,platform=32,"mswin"
  end
 elseif name=="linux" then
  architecture=architecture or os.getenv("HOSTTYPE") or resultof("uname -m") or ""
  local musl=find(os.selfdir or "","linuxmusl")
  if find(architecture,"x86_64") then
   bits,platform=64,musl and "linuxmusl" or "linux-64"
  elseif find(architecture,"ppc") then
   bits,platform=32,"linux-ppc" 
  else
   bits,platform=32,musl and "linuxmusl" or "linux"
  end
 elseif name=="macosx" then
  architecture=architecture or resultof("echo $HOSTTYPE") or ""
  if architecture=="" then
   bits,platform=64,"osx-intel"
  elseif find(architecture,"i386") then
   bits,platform=64,"osx-intel"
  elseif find(architecture,"x86_64") then
   bits,platform=64,"osx-64"
  elseif find(architecture,"arm64") then
   bits,platform=64,"osx-arm"
  else
   bits,platform=32,"osx-ppc"
  end
 elseif name=="sunos" then
  architecture=architecture or resultof("uname -m") or ""
  if find(architecture,"sparc") then
   bits,platform=32,"solaris-sparc"
  else 
   bits,platform=32,"solaris-intel"
  end
 elseif name=="freebsd" then
  architecture=architecture or os.getenv("MACHTYPE") or resultof("uname -m") or ""
  if find(architecture,"amd64") or find(architecture,"AMD64") then
   bits,platform=64,"freebsd-amd64"
  else
   bits,platform=32,"freebsd"
  end
 elseif name=="kfreebsd" then
  architecture=architecture or os.getenv("HOSTTYPE") or resultof("uname -m") or ""
  if architecture=="x86_64" then
   bits,platform=64,"kfreebsd-amd64"
  else
   bits,platform=32,"kfreebsd-i386"
  end
 else
  architecture=architecture or resultof("uname -m") or ""
  if find(architecture,"aarch64") then
   bits,platform="linux-aarch64"
  elseif find(architecture,"armv7l") then
   bits,platform=32,"linux-armhf"
  elseif find(architecture,"mips64") or find(architecture,"mips64el") then
   bits,platform=64,"linux-mipsel"
  elseif find(architecture,"mipsel") or find(architecture,"mips") then
   bits,platform=32,"linux-mipsel"
  else
   bits,platform=64,"linux-64" 
  end
 end
 os.setenv("MTX_PLATFORM",platform)
 os.setenv("MTX_BITS",bits)
 os.platform=platform
 os.bits=bits
 os.newline=name=="windows" and "\013\010" or "\010" 
end
do
 local t={ 8,9,"a","b" }
 function os.uuid()
  return format("%04x%04x-4%03x-%s%03x-%04x-%04x%04x%04x",
   random(0xFFFF),random(0xFFFF),
   random(0x0FFF),
   t[ceil(random(4))] or 8,random(0x0FFF),
   random(0xFFFF),
   random(0xFFFF),random(0xFFFF),random(0xFFFF)
  )
 end
end
do
 local hour,min
 function os.timezone(difference)
  if not hour then
   local current=time()
   local utcdate=date("!*t",current)
   local localdate=date("*t",current)
   localdate.isdst=false
   local timediff=difftime(time(localdate),time(utcdate))
   hour,min=modf(timediff/3600)
   min=min*60
  end
  if difference then
   return hour,min
  else
   return format("%+03d:%02d",hour,min) 
  end
 end
 local timeformat=format("%%s%s",os.timezone())
 local dateformat="%Y-%m-%d %H:%M:%S"
 local lasttime=nil
 local lastdate=nil
 function os.fulltime(t,default)
  t=t and tonumber(t) or 0
  if t>0 then
  elseif default then
   return default
  else
   t=time()
  end
  if t~=lasttime then
   lasttime=t
   lastdate=format(timeformat,date(dateformat))
  end
  return lastdate
 end
 local dateformat="%Y-%m-%d %H:%M:%S"
 local lasttime=nil
 local lastdate=nil
 function os.localtime(t,default)
  t=t and tonumber(t) or 0
  if t>0 then
  elseif default then
   return default
  else
   t=time()
  end
  if t~=lasttime then
   lasttime=t
   lastdate=date(dateformat,t)
  end
  return lastdate
 end
 function os.converttime(t,default)
  local t=tonumber(t)
  if t and t>0 then
   return date(dateformat,t)
  else
   return default or "-"
  end
 end
 function os.today()
  return date("!*t")
 end
 function os.now()
  return date("!%Y-%m-%d %H:%M:%S")
 end
end
do
 local cache={}
 local function which(filename)
  local fullname=cache[filename]
  if fullname==nil then
   local suffix=file.suffix(filename)
   local suffixes=suffix=="" and os.binsuffixes or { suffix }
   for directory in gmatch(os.getenv("PATH"),"[^"..io.pathseparator.."]+") do
    local df=file.join(directory,filename)
    for i=1,#suffixes do
     local dfs=file.addsuffix(df,suffixes[i])
     if io.exists(dfs) then
      fullname=dfs
      break
     end
    end
   end
   if not fullname then
    fullname=false
   end
   cache[filename]=fullname
  end
  return fullname
 end
 os.which=which
 os.where=which
end
if not os.sleep then
 local socket=socket
 function os.sleep(n)
  if not socket then
   socket=require("socket")
  end
  socket.sleep(n)
 end
end
do
 local function isleapyear(year)
  return (year%4==0) and (year%100~=0 or year%400==0)
 end
 os.isleapyear=isleapyear
 local days={ 31,28,31,30,31,30,31,31,30,31,30,31 }
 local function nofdays(year,month,day)
  if not month then
   return isleapyear(year) and 365 or 364
  elseif not day then
   return month==2 and isleapyear(year) and 29 or days[month]
  else
   for i=1,month-1 do
    day=day+days[i]
   end
   if month>2 and isleapyear(year) then
    day=day+1
   end
   return day
  end
 end
 os.nofdays=nofdays
 function os.weekday(day,month,year)
  return date("%w",time { year=year,month=month,day=day })+1
 end
 function os.validdate(year,month,day)
  if month<1 then
   month=1
  elseif month>12 then
   month=12
  end
  if day<1 then
   day=1
  else
   local max=nofdays(year,month)
   if day>max then
    day=max
   end
  end
  return year,month,day
 end
 function os.date(fmt,...)
  if not fmt then
   fmt="%Y-%m-%d %H:%M"
  end
  return date(fmt,...)
 end
end
do
 local osexit=os.exit
 local exitcode=nil
 function os.setexitcode(code)
  exitcode=code
 end
 function os.exit(c)
  if exitcode~=nil then
   return osexit(exitcode)
  end
  if c~=nil then
   return osexit(c)
  end
  return osexit()
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-file']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
file=file or {}
local file=file
if not lfs then
 lfs=optionalrequire("lfs")
end
local insert,concat=table.insert,table.concat
local match,find,gmatch=string.match,string.find,string.gmatch
local lpegmatch=lpeg.match
local getcurrentdir,attributes=lfs.currentdir,lfs.attributes
local checkedsplit=string.checkedsplit
local P,R,S,C,Cs,Cp,Cc,Ct=lpeg.P,lpeg.R,lpeg.S,lpeg.C,lpeg.Cs,lpeg.Cp,lpeg.Cc,lpeg.Ct
local attributes=lfs.attributes
function lfs.isdir(name)
 if name then
  return attributes(name,"mode")=="directory"
 end
end
function lfs.isfile(name)
 if name then
  local a=attributes(name,"mode")
  return a=="file" or a=="link" or nil
 end
end
function lfs.isfound(name)
 if name then
  local a=attributes(name,"mode")
  return (a=="file" or a=="link") and name or nil
 end
end
function lfs.modification(name)
 return name and attributes(name,"modification") or nil
end
if sandbox then
 sandbox.redefine(lfs.isfile,"lfs.isfile")
 sandbox.redefine(lfs.isdir,"lfs.isdir")
 sandbox.redefine(lfs.isfound,"lfs.isfound")
end
local colon=P(":")
local period=P(".")
local periods=P("..")
local fwslash=P("/")
local bwslash=P("\\")
local slashes=S("\\/")
local noperiod=1-period
local noslashes=1-slashes
local name=noperiod^1
local suffix=period/""*(1-period-slashes)^1*-1
local pattern=C((1-(slashes^1*noslashes^1*-1))^1)*P(1) 
local function pathpart(name,default)
 return name and lpegmatch(pattern,name) or default or ""
end
local pattern=(noslashes^0*slashes)^1*C(noslashes^1)*-1
local function basename(name)
 return name and lpegmatch(pattern,name) or name
end
local pattern=(noslashes^0*slashes^1)^0*Cs((1-suffix)^1)*suffix^0
local function nameonly(name)
 return name and lpegmatch(pattern,name) or name
end
local pattern=(noslashes^0*slashes)^0*(noperiod^1*period)^1*C(noperiod^1)*-1
local function suffixonly(name)
 return name and lpegmatch(pattern,name) or ""
end
local pattern=(noslashes^0*slashes)^0*noperiod^1*((period*C(noperiod^1))^1)*-1+Cc("")
local function suffixesonly(name)
 if name then
  return lpegmatch(pattern,name)
 else
  return ""
 end
end
file.pathpart=pathpart
file.basename=basename
file.nameonly=nameonly
file.suffixonly=suffixonly
file.suffix=suffixonly
file.suffixesonly=suffixesonly
file.suffixes=suffixesonly
file.dirname=pathpart   
file.extname=suffixonly
local drive=C(R("az","AZ"))*colon
local path=C((noslashes^0*slashes)^0)
local suffix=period*C(P(1-period)^0*P(-1))
local base=C((1-suffix)^0)
local rest=C(P(1)^0)
drive=drive+Cc("")
path=path+Cc("")
base=base+Cc("")
suffix=suffix+Cc("")
local pattern_a=drive*path*base*suffix
local pattern_b=path*base*suffix
local pattern_c=C(drive*path)*C(base*suffix) 
local pattern_d=path*rest
function file.splitname(str,splitdrive)
 if not str then
 elseif splitdrive then
  return lpegmatch(pattern_a,str) 
 else
  return lpegmatch(pattern_b,str) 
 end
end
function file.splitbase(str)
 if str then
  return lpegmatch(pattern_d,str) 
 else
  return "",str 
 end
end
function file.nametotable(str,splitdrive)
 if str then
  local path,drive,subpath,name,base,suffix=lpegmatch(pattern_c,str)
  if splitdrive then
   return {
    path=path,
    drive=drive,
    subpath=subpath,
    name=name,
    base=base,
    suffix=suffix,
   }
  else
   return {
    path=path,
    name=name,
    base=base,
    suffix=suffix,
   }
  end
 end
end
local pattern=Cs(((period*(1-period-slashes)^1*-1)/""+1)^1)
function file.removesuffix(name)
 return name and lpegmatch(pattern,name)
end
local suffix=period/""*(1-period-slashes)^1*-1
local pattern=Cs((noslashes^0*slashes^1)^0*((1-suffix)^1))*Cs(suffix)
function file.addsuffix(filename,suffix,criterium)
 if not filename or not suffix or suffix=="" then
  return filename
 elseif criterium==true then
  return filename.."."..suffix
 elseif not criterium then
  local n,s=lpegmatch(pattern,filename)
  if not s or s=="" then
   return filename.."."..suffix
  else
   return filename
  end
 else
  local n,s=lpegmatch(pattern,filename)
  if s and s~="" then
   local t=type(criterium)
   if t=="table" then
    for i=1,#criterium do
     if s==criterium[i] then
      return filename
     end
    end
   elseif t=="string" then
    if s==criterium then
     return filename
    end
   end
  end
  return (n or filename).."."..suffix
 end
end
local suffix=period*(1-period-slashes)^1*-1
local pattern=Cs((1-suffix)^0)
function file.replacesuffix(name,suffix)
 if name and suffix and suffix~="" then
  return lpegmatch(pattern,name).."."..suffix
 else
  return name
 end
end
local reslasher=lpeg.replacer(P("\\"),"/")
function file.reslash(str)
 return str and lpegmatch(reslasher,str)
end
if lfs.isreadablefile and lfs.iswritablefile then
 file.is_readable=lfs.isreadablefile
 file.is_writable=lfs.iswritablefile
else
 function file.is_writable(name)
  if not name then
  elseif lfs.isdir(name) then
   name=name.."/m_t_x_t_e_s_t.tmp"
   local f=io.open(name,"wb")
   if f then
    f:close()
    os.remove(name)
    return true
   end
  elseif lfs.isfile(name) then
   local f=io.open(name,"ab")
   if f then
    f:close()
    return true
   end
  else
   local f=io.open(name,"ab")
   if f then
    f:close()
    os.remove(name)
    return true
   end
  end
  return false
 end
 local readable=P("r")*Cc(true)
 function file.is_readable(name)
  if name then
   local a=attributes(name)
   return a and lpegmatch(readable,a.permissions) or false
  else
   return false
  end
 end
end
file.isreadable=file.is_readable 
file.iswritable=file.is_writable 
function file.size(name)
 if name then
  local a=attributes(name)
  return a and a.size or 0
 else
  return 0
 end
end
function file.splitpath(str,separator) 
 return str and checkedsplit(lpegmatch(reslasher,str),separator or io.pathseparator)
end
function file.joinpath(tab,separator) 
 return tab and concat(tab,separator or io.pathseparator) 
end
local someslash=S("\\/")
local stripper=Cs(P(fwslash)^0/""*reslasher)
local isnetwork=someslash*someslash*(1-someslash)+(1-fwslash-colon)^1*colon
local isroot=fwslash^1*-1
local hasroot=fwslash^1
local reslasher=lpeg.replacer(S("\\/"),"/")
local deslasher=lpeg.replacer(S("\\/")^1,"/")
function file.join(one,two,three,...)
 if not two then
  return one=="" and one or lpegmatch(reslasher,one)
 end
 if not one or one=="" then
  return lpegmatch(stripper,three and concat({ two,three,... },"/") or two)
 end
 if lpegmatch(isnetwork,one) then
  local one=lpegmatch(reslasher,one)
  local two=lpegmatch(deslasher,three and concat({ two,three,... },"/") or two)
  if lpegmatch(hasroot,two) then
   return one..two
  else
   return one.."/"..two
  end
 elseif lpegmatch(isroot,one) then
  local two=lpegmatch(deslasher,three and concat({ two,three,... },"/") or two)
  if lpegmatch(hasroot,two) then
   return two
  else
   return "/"..two
  end
 else
  return lpegmatch(deslasher,concat({  one,two,three,... },"/"))
 end
end
local drivespec=R("az","AZ")^1*colon
local anchors=fwslash+drivespec
local untouched=periods+(1-period)^1*P(-1)
local mswindrive=Cs(drivespec*(bwslash/"/"+fwslash)^0)
local mswinuncpath=(bwslash+fwslash)*(bwslash+fwslash)*Cc("//")
local splitstarter=(mswindrive+mswinuncpath+Cc(false))*Ct(lpeg.splitat(S("/\\")^1))
local absolute=fwslash
function file.collapsepath(str,anchor) 
 if not str then
  return
 end
 if anchor==true and not lpegmatch(anchors,str) then
  str=getcurrentdir().."/"..str
 end
 if str=="" or str=="." then
  return "."
 elseif lpegmatch(untouched,str) then
  return lpegmatch(reslasher,str)
 end
 local starter,oldelements=lpegmatch(splitstarter,str)
 local newelements={}
 local i=#oldelements
 while i>0 do
  local element=oldelements[i]
  if element=='.' then
  elseif element=='..' then
   local n=i-1
   while n>0 do
    local element=oldelements[n]
    if element~='..' and element~='.' then
     oldelements[n]='.'
     break
    else
     n=n-1
    end
    end
   if n<1 then
      insert(newelements,1,'..')
   end
  elseif element~="" then
   insert(newelements,1,element)
  end
  i=i-1
 end
 if #newelements==0 then
  return starter or "."
 elseif starter then
  return starter..concat(newelements,'/')
 elseif lpegmatch(absolute,str) then
  return "/"..concat(newelements,'/')
 else
  newelements=concat(newelements,'/')
  if anchor=="." and find(str,"^%./") then
   return "./"..newelements
  else
   return newelements
  end
 end
end
local validchars=R("az","09","AZ","--","..")
local pattern_a=lpeg.replacer(1-validchars)
local pattern_a=Cs((validchars+P(1)/"-")^1)
local whatever=P("-")^0/""
local pattern_b=Cs(whatever*(1-whatever*-1)^1)
function file.robustname(str,strict)
 if str then
  str=lpegmatch(pattern_a,str) or str
  if strict then
   return lpegmatch(pattern_b,str) or str 
  else
   return str
  end
 end
end
local loaddata=io.loaddata
local savedata=io.savedata
file.readdata=loaddata
file.savedata=savedata
function file.copy(oldname,newname)
 if oldname and newname then
  local data=loaddata(oldname)
  if data and data~="" then
   savedata(newname,data)
  end
 end
end
local letter=R("az","AZ")+S("_-+")
local separator=P("://")
local qualified=period^0*fwslash+letter*colon+letter^1*separator+letter^1*fwslash
local rootbased=fwslash+letter*colon
lpeg.patterns.qualified=qualified
lpeg.patterns.rootbased=rootbased
function file.is_qualified_path(filename)
 return filename and lpegmatch(qualified,filename)~=nil
end
function file.is_rootbased_path(filename)
 return filename and lpegmatch(rootbased,filename)~=nil
end
function file.strip(name,dir)
 if name then
  local b,a=match(name,"^(.-)"..dir.."(.*)$")
  return a~="" and a or name
 end
end
function lfs.mkdirs(path)
 local full=""
 for sub in gmatch(path,"(/*[^\\/]+)") do 
  full=full..sub
  lfs.mkdir(full)
 end
end
function file.withinbase(path) 
 local l=0
 if not find(path,"^/") then
  path="/"..path
 end
 for dir in gmatch(path,"/([^/]+)") do
  if dir==".." then
   l=l-1
  elseif dir~="." then
   l=l+1
  end
  if l<0 then
   return false
  end
 end
 return true
end
do
 local symlinktarget=lfs.symlinktarget  
 local symlinkattributes=lfs.symlinkattributes 
 if symlinktarget then
  function lfs.readlink(name)
   local target=symlinktarget(name)
   return name~=target and name or nil
  end
 elseif symlinkattributes then
  function lfs.readlink(name)
   return symlinkattributes(name,"target") or nil
  end
 else
  function lfs.readlink(name)
   return nil
  end
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-md5']={
 version=1.001,
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
if not md5 then
 md5=optionalrequire("md5")
end
if not md5 then
 md5={
  sum=function(str) print("error: md5 is not loaded (sum     ignored)") return str end,
  sumhexa=function(str) print("error: md5 is not loaded (sumhexa ignored)") return str end,
 }
end
local md5,file=md5,file
local gsub=string.gsub
local modification,isfile,touch=lfs.modification,lfs.isfile,lfs.touch
local loaddata,savedata=io.loaddata,io.savedata
do
 local patterns=lpeg and lpeg.patterns
 if patterns then
  local bytestoHEX=patterns.bytestoHEX
  local bytestohex=patterns.bytestohex
  local bytestodec=patterns.bytestodec
  local lpegmatch=lpeg.match
  local md5sum=md5.sum
  if not md5.HEX then function md5.HEX(str) if str then return lpegmatch(bytestoHEX,md5sum(str)) end end end
  if not md5.hex then function md5.hex(str) if str then return lpegmatch(bytestohex,md5sum(str)) end end end
  if not md5.dec then function md5.dec(str) if str then return lpegmatch(bytestodec,md5sum(str)) end end end
  md5.sumhexa=md5.hex
  md5.sumHEXA=md5.HEX
 end
end
local md5HEX=md5.HEX
function file.needsupdating(oldname,newname,threshold) 
 local oldtime=modification(oldname)
 if oldtime then
  local newtime=modification(newname)
  if not newtime then
   return true 
  elseif newtime>=oldtime then
   return false 
  elseif oldtime-newtime<(threshold or 1) then
   return false 
  else
   return true 
  end
 else
  return false 
 end
end
file.needs_updating=file.needsupdating
function file.syncmtimes(oldname,newname)
 local oldtime=modification(oldname)
 if oldtime and isfile(newname) then
  touch(newname,oldtime,oldtime)
 end
end
local function checksum(name)
 if md5 then
  local data=loaddata(name)
  if data then
   return md5HEX(data)
  end
 end
 return nil
end
file.checksum=checksum
function file.loadchecksum(name)
 if md5 then
  local data=loaddata(name..".md5")
  return data and (gsub(data,"%s",""))
 end
 return nil
end
function file.savechecksum(name,checksum)
 if not checksum then checksum=checksum(name) end
 if checksum then
  savedata(name..".md5",checksum)
  return checksum
 end
 return nil
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-dir']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local type,select=type,select
local find,gmatch,match,gsub,sub=string.find,string.gmatch,string.match,string.gsub,string.sub
local concat,insert,remove,unpack=table.concat,table.insert,table.remove,table.unpack
local lpegmatch=lpeg.match
local P,S,R,C,Cc,Cs,Ct,Cv,V=lpeg.P,lpeg.S,lpeg.R,lpeg.C,lpeg.Cc,lpeg.Cs,lpeg.Ct,lpeg.Cv,lpeg.V
dir=dir or {}
local dir=dir
local lfs=lfs
local attributes=lfs.attributes
local scandir=lfs.dir
local isdir=lfs.isdir  
local isfile=lfs.isfile 
local currentdir=lfs.currentdir
local chdir=lfs.chdir
local mkdir=lfs.mkdir
local onwindows=os.type=="windows" or find(os.getenv("PATH"),";",1,true)
if onwindows then
 local tricky=S("/\\")*P(-1)
 isdir=function(name)
  if lpegmatch(tricky,name) then
   return attributes(name,"mode")=="directory"
  else
   return attributes(name.."/.","mode")=="directory"
  end
 end
 isfile=function(name)
  return attributes(name,"mode")=="file"
 end
 lfs.isdir=isdir
 lfs.isfile=isfile
else
 isdir=function(name)
  return attributes(name,"mode")=="directory"
 end
 isfile=function(name)
  return attributes(name,"mode")=="file"
 end
 lfs.isdir=isdir
 lfs.isfile=isfile
end
local isreadable=file.isreadable
local walkdir=function(p,...)
 if isreadable(p.."/.") then
  return scandir(p,...)
 else
  return function() end
 end
end
lfs.walkdir=walkdir
function dir.current()
 return (gsub(currentdir(),"\\","/"))
end
local function glob_pattern_function(path,patt,recurse,action)
 if isdir(path) then
  local usedpath
  if path=="/" then
   usedpath="/."
  elseif not find(path,"/$") then
   usedpath=path.."/."
   path=path.."/"
  else
   usedpath=path
  end
  local dirs
  local nofdirs=0
  for name,mode,size,time in walkdir(usedpath) do
   if name~="." and name~=".." then
    local full=path..name
    if mode==nil then
     mode=attributes(full,'mode')
    end
    if mode=='file' then
     if not patt or find(full,patt) then
      action(full,size,time)
     end
    elseif recurse and mode=="directory" then
     if dirs then
      nofdirs=nofdirs+1
      dirs[nofdirs]=full
     else
      nofdirs=1
      dirs={ full }
     end
    end
   end
  end
  if dirs then
   for i=1,nofdirs do
    glob_pattern_function(dirs[i],patt,recurse,action)
   end
  end
 end
end
local function glob_pattern_table(path,patt,recurse,result)
 if not result then
  result={}
 end
 local usedpath
 if path=="/" then
  usedpath="/."
 elseif not find(path,"/$") then
  usedpath=path.."/."
  path=path.."/"
 else
  usedpath=path
 end
 local dirs
 local nofdirs=0
 local noffiles=#result
 for name,mode in walkdir(usedpath) do
  if name~="." and name~=".." then
   local full=path..name
   if mode==nil then
    mode=attributes(full,'mode')
   end
   if mode=='file' then
    if not patt or find(full,patt) then
     noffiles=noffiles+1
     result[noffiles]=full
    end
   elseif recurse and mode=="directory" then
    if dirs then
     nofdirs=nofdirs+1
     dirs[nofdirs]=full
    else
     nofdirs=1
     dirs={ full }
    end
   end
  end
 end
 if dirs then
  for i=1,nofdirs do
   glob_pattern_table(dirs[i],patt,recurse,result)
  end
 end
 return result
end
local function globpattern(path,patt,recurse,method)
 local kind=type(method)
 if patt and sub(patt,1,-3)==path then
  patt=false
 end
 local okay=isdir(path)
 if kind=="function" then
  return okay and glob_pattern_function(path,patt,recurse,method) or {}
 elseif kind=="table" then
  return okay and glob_pattern_table(path,patt,recurse,method) or method
 else
  return okay and glob_pattern_table(path,patt,recurse,{}) or {}
 end
end
dir.globpattern=globpattern
local function collectpattern(path,patt,recurse,result)
 local ok,scanner
 result=result or {}
 if path=="/" then
  ok,scanner,first=xpcall(function() return walkdir(path..".") end,function() end) 
 else
  ok,scanner,first=xpcall(function() return walkdir(path)   end,function() end) 
 end
 if ok and type(scanner)=="function" then
  if not find(path,"/$") then
   path=path..'/'
  end
  for name in scanner,first do 
   if name=="." then
   elseif name==".." then
   else
    local full=path..name
    local attr=attributes(full)
    local mode=attr.mode
    if mode=='file' then
     if find(full,patt) then
      result[name]=attr
     end
    elseif recurse and mode=="directory" then
     attr.list=collectpattern(full,patt,recurse)
     result[name]=attr
    end
   end
  end
 end
 return result
end
dir.collectpattern=collectpattern
local separator,pattern
if onwindows then 
 local slash=S("/\\")/"/"
 pattern={
  (Cs(P(".")+slash^1)+Cs(R("az","AZ")*P(":")*slash^0)+Cc("./"))*V(2)*V(3),
  Cs(((1-S("*?/\\"))^0*slash)^0),
  Cs(P(1)^0)
 }
else
 pattern={
  (C(P(".")+P("/")^1)+Cc("./"))*V(2)*V(3),
  C(((1-S("*?/"))^0*P("/"))^0),
  C(P(1)^0)
 }
end
local filter=Cs ((
 P("**")/".*"+P("*")/"[^/]*"+P("?")/"[^/]"+P(".")/"%%."+P("+")/"%%+"+P("-")/"%%-"+P(1)
)^0 )
local function glob(str,t)
 if type(t)=="function" then
  if type(str)=="table" then
   for s=1,#str do
    glob(str[s],t)
   end
  elseif isfile(str) then
   t(str)
  else
   local root,path,base=lpegmatch(pattern,str) 
   if root and path and base then
    local recurse=find(base,"**",1,true) 
    local start=root..path
    local result=lpegmatch(filter,start..base)
    globpattern(start,result,recurse,t)
   end
  end
 else
  if type(str)=="table" then
   local t=t or {}
   for s=1,#str do
    glob(str[s],t)
   end
   return t
  elseif isfile(str) then
   if t then
    t[#t+1]=str
    return t
   else
    return { str }
   end
  else
   local root,path,base=lpegmatch(pattern,str) 
   if root and path and base then
    local recurse=find(base,"**",1,true) 
    local start=root..path
    local result=lpegmatch(filter,start..base)
    return globpattern(start,result,recurse,t)
   else
    return {}
   end
  end
 end
end
dir.glob=glob
local function globfiles(path,recurse,func,files) 
 if type(func)=="string" then
  local s=func
  func=function(name) return find(name,s) end
 end
 files=files or {}
 local noffiles=#files
 for name,mode in walkdir(path) do
  if find(name,"^%.") then
  else
   if mode==nil then
    mode=attributes(name,'mode')
   end
   if mode=="directory" then
    if recurse then
     globfiles(path.."/"..name,recurse,func,files)
    end
   elseif mode=="file" then
    if not func or func(name) then
     noffiles=noffiles+1
     files[noffiles]=path.."/"..name
    end
   end
  end
 end
 return files
end
dir.globfiles=globfiles
local function globdirs(path,recurse,func,files) 
 if type(func)=="string" then
  local s=func
  func=function(name) return find(name,s) end
 end
 files=files or {}
 local noffiles=#files
 for name,mode in walkdir(path) do
  if find(name,"^%.") then
  else
   if mode==nil then
    mode=attributes(name,'mode')
   end
   if mode=="directory" then
    if not func or func(name) then
     noffiles=noffiles+1
     files[noffiles]=path.."/"..name
     if recurse then
      globdirs(path.."/"..name,recurse,func,files)
     end
    end
   end
  end
 end
 return files
end
dir.globdirs=globdirs
function dir.ls(pattern)
 return concat(glob(pattern),"\n")
end
local make_indeed=true 
if onwindows then
 function dir.mkdirs(...)
  local n=select("#",...)
  local str
  if n==1 then
   str=select(1,...)
   if isdir(str) then
    return str,true
   end
  else
   str=""
   for i=1,n do
    local s=select(i,...)
    if s=="" then
    elseif str=="" then
     str=s
    else
     str=str.."/"..s
    end
   end
  end
  local pth=""
  local drive=false
  local first,middle,last=match(str,"^(//)(//*)(.*)$")
  if first then
  else
   first,last=match(str,"^(//)/*(.-)$")
   if first then
    middle,last=match(str,"([^/]+)/+(.-)$")
    if middle then
     pth="//"..middle
    else
     pth="//"..last
     last=""
    end
   else
    first,middle,last=match(str,"^([a-zA-Z]:)(/*)(.-)$")
    if first then
     pth,drive=first..middle,true
    else
     middle,last=match(str,"^(/*)(.-)$")
     if not middle then
      last=str
     end
    end
   end
  end
  for s in gmatch(last,"[^/]+") do
   if pth=="" then
    pth=s
   elseif drive then
    pth,drive=pth..s,false
   else
    pth=pth.."/"..s
   end
   if make_indeed and not isdir(pth) then
    mkdir(pth)
   end
  end
  return pth,(isdir(pth)==true)
 end
else
 function dir.mkdirs(...)
  local n=select("#",...)
  local str,pth
  if n==1 then
   str=select(1,...)
   if isdir(str) then
    return str,true
   end
  else
   str=""
   for i=1,n do
    local s=select(i,...)
    if s and s~="" then 
     if str~="" then
      str=str.."/"..s
     else
      str=s
     end
    end
   end
  end
  str=gsub(str,"/+","/")
  if find(str,"^/") then
   pth="/"
   for s in gmatch(str,"[^/]+") do
    local first=(pth=="/")
    if first then
     pth=pth..s
    else
     pth=pth.."/"..s
    end
    if make_indeed and not first and not isdir(pth) then
     mkdir(pth)
    end
   end
  else
   pth="."
   for s in gmatch(str,"[^/]+") do
    pth=pth.."/"..s
    if make_indeed and not isdir(pth) then
     mkdir(pth)
    end
   end
  end
  return pth,(isdir(pth)==true)
 end
end
dir.makedirs=dir.mkdirs
do
 local chdir=sandbox and sandbox.original(chdir) or chdir
 if onwindows then
  local xcurrentdir=dir.current
  function dir.expandname(str) 
   local first,nothing,last=match(str,"^(//)(//*)(.*)$")
   if first then
    first=xcurrentdir().."/" 
   end
   if not first then
    first,last=match(str,"^(//)/*(.*)$")
   end
   if not first then
    first,last=match(str,"^([a-zA-Z]:)(.*)$")
    if first and not find(last,"^/") then
     local d=currentdir() 
     if chdir(first) then
      first=xcurrentdir() 
     end
     chdir(d)
    end
   end
   if not first then
    first,last=xcurrentdir(),str
   end
   last=gsub(last,"//","/")
   last=gsub(last,"/%./","/")
   last=gsub(last,"^/*","")
   first=gsub(first,"/*$","")
   if last=="" or last=="." then
    return first
   else
    return first.."/"..last
   end
  end
 else
  function dir.expandname(str) 
   if not find(str,"^/") then
    str=currentdir().."/"..str
   end
   str=gsub(str,"//","/")
   str=gsub(str,"/%./","/")
   str=gsub(str,"(.)/%.$","%1")
   return str
  end
 end
 function dir.expandlink(dir,report)
  local curdir=currentdir()
  local trace=type(report)=="function"
  if chdir(dir) then
   local newdir=currentdir()
   if newdir~=dir and trace then
    report("following symlink %a to %a",dir,newdir)
   end
   chdir(curdir)
   return newdir
  else
   if trace then
    report("unable to check path %a",dir)
   end
   return dir
  end
 end
end
file.expandname=dir.expandname 
local stack={}
function dir.push(newdir)
 local curdir=currentdir()
 insert(stack,curdir)
 if newdir and newdir~="" and chdir(newdir) then
  return newdir
 else
  return curdir
 end
end
function dir.pop()
 local d=remove(stack)
 if d then
  chdir(d)
 end
 return d
end
local function found(...) 
 for i=1,select("#",...) do
  local path=select(i,...)
  local kind=type(path)
  if kind=="string" then
   if isdir(path) then
    return path
   end
  elseif kind=="table" then
   local path=found(unpack(path))
   if path then
    return path
   end
  end
 end
end
dir.found=found

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-unicode']={
 version=1.001,
 optimize=true,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
utf=utf or {}
if not string.utfcharacters then
 local gmatch=string.gmatch
 function string.characters(str)
  return gmatch(str,".[\128-\191]*")
 end
end
utf.characters=string.utfcharacters
local type=type
local char,byte,format,sub,gmatch=string.char,string.byte,string.format,string.sub,string.gmatch
local concat=table.concat
local P,C,R,Cs,Ct,Cmt,Cc,Carg,Cp=lpeg.P,lpeg.C,lpeg.R,lpeg.Cs,lpeg.Ct,lpeg.Cmt,lpeg.Cc,lpeg.Carg,lpeg.Cp
local lpegmatch=lpeg.match
local patterns=lpeg.patterns
local tabletopattern=lpeg.utfchartabletopattern
local bytepairs=string.bytepairs
local finder=lpeg.finder
local replacer=lpeg.replacer
local p_utftype=patterns.utftype
local p_utfstricttype=patterns.utfstricttype
local p_utfoffset=patterns.utfoffset
local p_utf8character=patterns.utf8character
local p_utf8char=patterns.utf8char
local p_utf8byte=patterns.utf8byte
local p_utfbom=patterns.utfbom
local p_newline=patterns.newline
local p_whitespace=patterns.whitespace
if not utf.char then
 utf.char=string.utfcharacter or (utf8 and utf8.char)
 if not utf.char then
  local char=string.char
  if bit32 then
   local rshift=bit32.rshift
   function utf.char(n)
    if n<0x80 then
     return char(n)
    elseif n<0x800 then
     return char(
      0xC0+rshift(n,6),
      0x80+(n%0x40)
     )
    elseif n<0x10000 then
     return char(
      0xE0+rshift(n,12),
      0x80+(rshift(n,6)%0x40),
      0x80+(n%0x40)
     )
    elseif n<0x200000 then
     return char(
      0xF0+rshift(n,18),
      0x80+(rshift(n,12)%0x40),
      0x80+(rshift(n,6)%0x40),
      0x80+(n%0x40)
     )
    else
     return ""
    end
   end
  else
   local floor=math.floor
   function utf.char(n)
    if n<0x80 then
     return char(n)
    elseif n<0x800 then
     return char(
      0xC0+floor(n/0x40),
      0x80+(n%0x40)
     )
    elseif n<0x10000 then
     return char(
      0xE0+floor(n/0x1000),
      0x80+(floor(n/0x40)%0x40),
      0x80+(n%0x40)
     )
    elseif n<0x200000 then
     return char(
      0xF0+floor(n/0x40000),
      0x80+(floor(n/0x1000)%0x40),
      0x80+(floor(n/0x40)%0x40),
      0x80+(n%0x40)
     )
    else
     return ""
    end
   end
  end
 end
end
if not utf.byte then
 utf.byte=string.utfvalue or (utf8 and utf8.codepoint)
 if not utf.byte then
  function utf.byte(c)
   return lpegmatch(p_utf8byte,c)
  end
 end
end
local utfchar,utfbyte=utf.char,utf.byte
function utf.filetype(data)
 return data and lpegmatch(p_utftype,data) or "unknown"
end
local toentities=Cs (
 (
  patterns.utf8one+(
    patterns.utf8two+patterns.utf8three+patterns.utf8four
   )/function(s) local b=utfbyte(s) if b<127 then return s else return format("&#%X;",b) end end
 )^0
)
patterns.toentities=toentities
function utf.toentities(str)
 return lpegmatch(toentities,str)
end
local one=P(1)
local two=C(1)*C(1)
local four=C(R(utfchar(0xD8),utfchar(0xFF)))*C(1)*C(1)*C(1)
local pattern=P("\254\255")*Cs((
     four/function(a,b,c,d)
        local ab=0xFF*byte(a)+byte(b)
        local cd=0xFF*byte(c)+byte(d)
        return utfchar((ab-0xD800)*0x400+(cd-0xDC00)+0x10000)
       end+two/function(a,b)
        return utfchar(byte(a)*256+byte(b))
       end+one
    )^1 )+P("\255\254")*Cs((
     four/function(b,a,d,c)
        local ab=0xFF*byte(a)+byte(b)
        local cd=0xFF*byte(c)+byte(d)
        return utfchar((ab-0xD800)*0x400+(cd-0xDC00)+0x10000)
       end+two/function(b,a)
        return utfchar(byte(a)*256+byte(b))
       end+one
    )^1 )
function string.toutf(s) 
 return lpegmatch(pattern,s) or s 
end
local validatedutf=Cs (
 (
  patterns.utf8one+patterns.utf8two+patterns.utf8three+patterns.utf8four+P(1)/"�"
 )^0
)
patterns.validatedutf=validatedutf
function utf.is_valid(str)
 return type(str)=="string" and lpegmatch(validatedutf,str) or false
end
if not utf.len then
 utf.len=string.utflength or (utf8 and utf8.len)
 if not utf.len then
  local n,f=0,1
  local utfcharcounter=patterns.utfbom^-1*Cmt (
   Cc(1)*patterns.utf8one^1+Cc(2)*patterns.utf8two^1+Cc(3)*patterns.utf8three^1+Cc(4)*patterns.utf8four^1,
   function(_,t,d) 
    n=n+(t-f)/d
    f=t
    return true
   end
  )^0
  function utf.len(str)
   n,f=0,1
   lpegmatch(utfcharcounter,str or "")
   return n
  end
 end
end
utf.length=utf.len
if not utf.sub then
 local utflength=utf.length
 local b,e,n,first,last=0,0,0,0,0
 local function slide_zero(s,p)
  n=n+1
  if n>=last then
   e=p-1
  else
   return p
  end
 end
 local function slide_one(s,p)
  n=n+1
  if n==first then
   b=p
  end
  if n>=last then
   e=p-1
  else
   return p
  end
 end
 local function slide_two(s,p)
  n=n+1
  if n==first then
   b=p
  else
   return true
  end
 end
 local pattern_zero=Cmt(p_utf8character,slide_zero)^0
 local pattern_one=Cmt(p_utf8character,slide_one )^0
 local pattern_two=Cmt(p_utf8character,slide_two )^0
 local pattern_first=C(p_utf8character)
 function utf.sub(str,start,stop)
  if not start then
   return str
  end
  if start==0 then
   start=1
  end
  if not stop then
   if start<0 then
    local l=utflength(str) 
    start=l+start
   else
    start=start-1
   end
   b,n,first=0,0,start
   lpegmatch(pattern_two,str)
   if n>=first then
    return sub(str,b)
   else
    return ""
   end
  end
  if start<0 or stop<0 then
   local l=utf.length(str)
   if start<0 then
    start=l+start
    if start<=0 then
     start=1
    else
     start=start+1
    end
   end
   if stop<0 then
    stop=l+stop
    if stop==0 then
     stop=1
    else
     stop=stop+1
    end
   end
  end
  if start==1 and stop==1 then
   return lpegmatch(pattern_first,str) or ""
  elseif start>stop then
   return ""
  elseif start>1 then
   b,e,n,first,last=0,0,0,start-1,stop
   lpegmatch(pattern_one,str)
   if n>=first and e==0 then
    e=#str
   end
   return sub(str,b,e)
  else
   b,e,n,last=1,0,0,stop
   lpegmatch(pattern_zero,str)
   if e==0 then
    e=#str
   end
   return sub(str,b,e)
  end
 end
end
function utf.remapper(mapping,option,action) 
 local variant=type(mapping)
 if variant=="table" then
  action=action or mapping
  if option=="dynamic" then
   local pattern=false
   table.setmetatablenewindex(mapping,function(t,k,v) rawset(t,k,v) pattern=false end)
   return function(str)
    if not str or str=="" then
     return ""
    else
     if not pattern then
      pattern=Cs((tabletopattern(mapping)/action+p_utf8character)^0)
     end
     return lpegmatch(pattern,str)
    end
   end
  elseif option=="pattern" then
   return Cs((tabletopattern(mapping)/action+p_utf8character)^0)
  else
   local pattern=Cs((tabletopattern(mapping)/action+p_utf8character)^0)
   return function(str)
    if not str or str=="" then
     return ""
    else
     return lpegmatch(pattern,str)
    end
   end,pattern
  end
 elseif variant=="function" then
  if option=="pattern" then
   return Cs((p_utf8character/mapping+p_utf8character)^0)
  else
   local pattern=Cs((p_utf8character/mapping+p_utf8character)^0)
   return function(str)
    if not str or str=="" then
     return ""
    else
     return lpegmatch(pattern,str)
    end
   end,pattern
  end
 else
  return function(str)
   return str or ""
  end
 end
end
function utf.replacer(t) 
 local r=replacer(t,false,false,true)
 return function(str)
  return lpegmatch(r,str)
 end
end
function utf.subtituter(t) 
 local f=finder  (t)
 local r=replacer(t,false,false,true)
 return function(str)
  local i=lpegmatch(f,str)
  if not i then
   return str
  elseif i>#str then
   return str
  else
   return lpegmatch(r,str)
  end
 end
end
local utflinesplitter=p_utfbom^-1*lpeg.tsplitat(p_newline)
local utfcharsplitter_ows=p_utfbom^-1*Ct(C(p_utf8character)^0)
local utfcharsplitter_iws=p_utfbom^-1*Ct((p_whitespace^1+C(p_utf8character))^0)
local utfcharsplitter_raw=Ct(C(p_utf8character)^0)
patterns.utflinesplitter=utflinesplitter
function utf.splitlines(str)
 return lpegmatch(utflinesplitter,str or "")
end
function utf.split(str,ignorewhitespace) 
 if ignorewhitespace then
  return lpegmatch(utfcharsplitter_iws,str or "")
 else
  return lpegmatch(utfcharsplitter_ows,str or "")
 end
end
function utf.totable(str) 
 return lpegmatch(utfcharsplitter_raw,str)
end
function utf.magic(f) 
 local str=f:read(4) or ""
 local off=lpegmatch(p_utfoffset,str)
 if off<4 then
  f:seek('set',off)
 end
 return lpegmatch(p_utftype,str)
end
local utf16_to_utf8_be,utf16_to_utf8_le
local utf32_to_utf8_be,utf32_to_utf8_le
local utf_16_be_getbom=patterns.utfbom_16_be^-1
local utf_16_le_getbom=patterns.utfbom_16_le^-1
local utf_32_be_getbom=patterns.utfbom_32_be^-1
local utf_32_le_getbom=patterns.utfbom_32_le^-1
local utf_16_be_linesplitter=utf_16_be_getbom*lpeg.tsplitat(patterns.utf_16_be_nl)
local utf_16_le_linesplitter=utf_16_le_getbom*lpeg.tsplitat(patterns.utf_16_le_nl)
local utf_32_be_linesplitter=utf_32_be_getbom*lpeg.tsplitat(patterns.utf_32_be_nl)
local utf_32_le_linesplitter=utf_32_le_getbom*lpeg.tsplitat(patterns.utf_32_le_nl)
local more=0
local p_utf16_to_utf8_be=C(1)*C(1)/function(left,right)
 local now=256*byte(left)+byte(right)
 if more>0 then
  now=(more-0xD800)*0x400+(now-0xDC00)+0x10000
  more=0
  return utfchar(now)
 elseif now>=0xD800 and now<=0xDBFF then
  more=now
  return "" 
 else
  return utfchar(now)
 end
end
local p_utf16_to_utf8_le=C(1)*C(1)/function(right,left)
 local now=256*byte(left)+byte(right)
 if more>0 then
  now=(more-0xD800)*0x400+(now-0xDC00)+0x10000
  more=0
  return utfchar(now)
 elseif now>=0xD800 and now<=0xDBFF then
  more=now
  return "" 
 else
  return utfchar(now)
 end
end
local p_utf32_to_utf8_be=C(1)*C(1)*C(1)*C(1)/function(a,b,c,d)
 return utfchar(256*256*256*byte(a)+256*256*byte(b)+256*byte(c)+byte(d))
end
local p_utf32_to_utf8_le=C(1)*C(1)*C(1)*C(1)/function(a,b,c,d)
 return utfchar(256*256*256*byte(d)+256*256*byte(c)+256*byte(b)+byte(a))
end
p_utf16_to_utf8_be=P(true)/function() more=0 end*utf_16_be_getbom*Cs(p_utf16_to_utf8_be^0)
p_utf16_to_utf8_le=P(true)/function() more=0 end*utf_16_le_getbom*Cs(p_utf16_to_utf8_le^0)
p_utf32_to_utf8_be=P(true)/function() more=0 end*utf_32_be_getbom*Cs(p_utf32_to_utf8_be^0)
p_utf32_to_utf8_le=P(true)/function() more=0 end*utf_32_le_getbom*Cs(p_utf32_to_utf8_le^0)
patterns.utf16_to_utf8_be=p_utf16_to_utf8_be
patterns.utf16_to_utf8_le=p_utf16_to_utf8_le
patterns.utf32_to_utf8_be=p_utf32_to_utf8_be
patterns.utf32_to_utf8_le=p_utf32_to_utf8_le
utf16_to_utf8_be=function(s)
 if s and s~="" then
  return lpegmatch(p_utf16_to_utf8_be,s)
 else
  return s
 end
end
local utf16_to_utf8_be_t=function(t)
 if not t then
  return nil
 elseif type(t)=="string" then
  t=lpegmatch(utf_16_be_linesplitter,t)
 end
 for i=1,#t do
  local s=t[i]
  if s~="" then
   t[i]=lpegmatch(p_utf16_to_utf8_be,s)
  end
 end
 return t
end
utf16_to_utf8_le=function(s)
 if s and s~="" then
  return lpegmatch(p_utf16_to_utf8_le,s)
 else
  return s
 end
end
local utf16_to_utf8_le_t=function(t)
 if not t then
  return nil
 elseif type(t)=="string" then
  t=lpegmatch(utf_16_le_linesplitter,t)
 end
 for i=1,#t do
  local s=t[i]
  if s~="" then
   t[i]=lpegmatch(p_utf16_to_utf8_le,s)
  end
 end
 return t
end
utf32_to_utf8_be=function(s)
 if s and s~="" then
  return lpegmatch(p_utf32_to_utf8_be,s)
 else
  return s
 end
end
local utf32_to_utf8_be_t=function(t)
 if not t then
  return nil
 elseif type(t)=="string" then
  t=lpegmatch(utf_32_be_linesplitter,t)
 end
 for i=1,#t do
  local s=t[i]
  if s~="" then
   t[i]=lpegmatch(p_utf32_to_utf8_be,s)
  end
 end
 return t
end
utf32_to_utf8_le=function(s)
 if s and s~="" then
  return lpegmatch(p_utf32_to_utf8_le,s)
 else
  return s
 end
end
local utf32_to_utf8_le_t=function(t)
 if not t then
  return nil
 elseif type(t)=="string" then
  t=lpegmatch(utf_32_le_linesplitter,t)
 end
 for i=1,#t do
  local s=t[i]
  if s~="" then
   t[i]=lpegmatch(p_utf32_to_utf8_le,s)
  end
 end
 return t
end
utf.utf16_to_utf8_le_t=utf16_to_utf8_le_t
utf.utf16_to_utf8_be_t=utf16_to_utf8_be_t
utf.utf32_to_utf8_le_t=utf32_to_utf8_le_t
utf.utf32_to_utf8_be_t=utf32_to_utf8_be_t
utf.utf16_to_utf8_le=utf16_to_utf8_le
utf.utf16_to_utf8_be=utf16_to_utf8_be
utf.utf32_to_utf8_le=utf32_to_utf8_le
utf.utf32_to_utf8_be=utf32_to_utf8_be
function utf.utf8_to_utf8_t(t)
 return type(t)=="string" and lpegmatch(utflinesplitter,t) or t
end
function utf.utf16_to_utf8_t(t,endian)
 return endian and utf16_to_utf8_be_t(t) or utf16_to_utf8_le_t(t) or t
end
function utf.utf32_to_utf8_t(t,endian)
 return endian and utf32_to_utf8_be_t(t) or utf32_to_utf8_le_t(t) or t
end
if bit32 then
 local rshift=bit32.rshift
 local function little(b)
  if b<0x10000 then
   return char(b%256,rshift(b,8))
  else
   b=b-0x10000
   local b1=rshift(b,10)+0xD800
   local b2=b%1024+0xDC00
   return char(b1%256,rshift(b1,8),b2%256,rshift(b2,8))
  end
 end
 local function big(b)
  if b<0x10000 then
   return char(rshift(b,8),b%256)
  else
   b=b-0x10000
   local b1=rshift(b,10)+0xD800
   local b2=b%1024+0xDC00
   return char(rshift(b1,8),b1%256,rshift(b2,8),b2%256)
  end
 end
 local l_remap=Cs((p_utf8byte/little+P(1)/"")^0)
 local b_remap=Cs((p_utf8byte/big+P(1)/"")^0)
 local function utf8_to_utf16_be(str,nobom)
  if nobom then
   return lpegmatch(b_remap,str)
  else
   return char(254,255)..lpegmatch(b_remap,str)
  end
 end
 local function utf8_to_utf16_le(str,nobom)
  if nobom then
   return lpegmatch(l_remap,str)
  else
   return char(255,254)..lpegmatch(l_remap,str)
  end
 end
 utf.utf8_to_utf16_be=utf8_to_utf16_be
 utf.utf8_to_utf16_le=utf8_to_utf16_le
 function utf.utf8_to_utf16(str,littleendian,nobom)
  if littleendian then
   return utf8_to_utf16_le(str,nobom)
  else
   return utf8_to_utf16_be(str,nobom)
  end
 end
end
local pattern=Cs (
 (p_utf8byte/function(unicode    ) return format("0x%04X",unicode) end)*(p_utf8byte*Carg(1)/function(unicode,separator) return format("%s0x%04X",separator,unicode) end)^0
)
function utf.tocodes(str,separator)
 return lpegmatch(pattern,str,1,separator or " ")
end
function utf.ustring(s)
 return format("U+%05X",type(s)=="number" and s or utfbyte(s))
end
function utf.xstring(s)
 return format("0x%05X",type(s)=="number" and s or utfbyte(s))
end
function utf.toeight(str)
 if not str or str=="" then
  return nil
 end
 local utftype=lpegmatch(p_utfstricttype,str)
 if utftype=="utf-8" then
  return sub(str,4)      
 elseif utftype=="utf-16-be" then
  return utf16_to_utf8_be(str) 
 elseif utftype=="utf-16-le" then
  return utf16_to_utf8_le(str) 
 else
  return str
 end
end
do
 local p_nany=p_utf8character/""
 local cache={}
 function utf.count(str,what)
  if type(what)=="string" then
   local p=cache[what]
   if not p then
    p=Cs((P(what)/" "+p_nany)^0)
    cache[p]=p
   end
   return #lpegmatch(p,str)
  else 
   return #lpegmatch(Cs((P(what)/" "+p_nany)^0),str)
  end
 end
end
if not string.utfvalues then
 local find=string.find
 local dummy=function()
 end
 function string.utfvalues(str)
  local n=#str
  if n==0 then
   return dummy
  elseif n==1 then
   return function() return utfbyte(str) end
  else
   local p=1
   return function()
     local b,e=find(str,".[\128-\191]*",p)
     if b then
      p=e+1
      return utfbyte(sub(str,b,e))
     end
   end
  end
 end
end
utf.values=string.utfvalues
function utf.chrlen(u) 
 return
  (u<0x80 and 1) or
  (u<0xE0 and 2) or
  (u<0xF0 and 3) or
  (u<0xF8 and 4) or
  (u<0xFC and 5) or
  (u<0xFE and 6) or 0
end
if bit32 then
 local extract=bit32.extract
 local char=string.char
 function utf.toutf32string(n)
  if n<=0xFF then
   return
    char(n).."\000\000\000"
  elseif n<=0xFFFF then
   return
    char(extract(n,0,8))..char(extract(n,8,8)).."\000\000"
  elseif n<=0xFFFFFF then
   return
    char(extract(n,0,8))..char(extract(n,8,8))..char(extract(n,16,8)).."\000"
  else
   return
    char(extract(n,0,8))..char(extract(n,8,8))..char(extract(n,16,8))..char(extract(n,24,8))
  end
 end
end
local len=utf.len
local rep=rep
function string.utfpadd(s,n)
 if n and n~=0 then
  local l=len(s)
  if n>0 then
   local d=n-l
   if d>0 then
    return rep(c or " ",d)..s
   end
  else
   local d=- n-l
   if d>0 then
    return s..rep(c or " ",d)
   end
  end
 end
 return s
end
do
 local utfcharacters=utf.characters or string.utfcharacters
 local utfchar=utf.char    or string.utfcharacter
 lpeg.UP=P
 if utfcharacters then
  function lpeg.US(str)
   local p=P(false)
   for uc in utfcharacters(str) do
    p=p+P(uc)
   end
   return p
  end
 else
  function lpeg.US(str)
   local p=P(false)
   local f=function(uc)
    p=p+P(uc)
   end
   lpegmatch((p_utf8char/f)^0,str)
   return p
  end
 end
 local range=p_utf8byte*p_utf8byte+Cc(false) 
 function lpeg.UR(str,more)
  local first,last
  if type(str)=="number" then
   first=str
   last=more or first
  else
   first,last=lpegmatch(range,str)
   if not last then
    return P(str)
   end
  end
  if first==last then
   return P(str)
  end
  if not utfchar then
   utfchar=utf.char 
  end
  if utfchar and (last-first<8) then 
   local p=P(false)
   for i=first,last do
    p=p+P(utfchar(i))
   end
   return p 
  else
   local f=function(b)
    return b>=first and b<=last
   end
   return p_utf8byte/f 
  end
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-url']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
local char,format,byte=string.char,string.format,string.byte
local concat=table.concat
local tonumber,type,next=tonumber,type,next
local P,C,R,S,Cs,Cc,Ct,Cf,Cg,V=lpeg.P,lpeg.C,lpeg.R,lpeg.S,lpeg.Cs,lpeg.Cc,lpeg.Ct,lpeg.Cf,lpeg.Cg,lpeg.V
local lpegmatch,lpegpatterns,replacer=lpeg.match,lpeg.patterns,lpeg.replacer
local sortedhash=table.sortedhash
url=url or {}
local url=url
local unescapes={}
local escapes={}
setmetatable(unescapes,{ __index=function(t,k)
 local v=char(tonumber(k,16))
 t[k]=v
 return v
end })
setmetatable(escapes,{ __index=function(t,k)
 local v=format("%%%02X",byte(k))
 t[k]=v
 return v
end })
local colon=P(":")
local qmark=P("?")
local hash=P("#")
local slash=P("/")
local atsign=P("@")
local percent=P("%")
local endofstring=P(-1)
local hexdigit=R("09","AF","af")
local plus=P("+")
local nothing=Cc("")
local okay=R("09","AZ","az")+S("-_.,:=+*~!'()@&$")
local escapedchar=(percent*C(hexdigit*hexdigit))/unescapes
local unescapedchar=P(1)/escapes
local escaped=(plus/" ")+escapedchar 
local noslash=P("/")/""
local plustospace=P("+")/" "
local decoder=Cs((
     plustospace+escapedchar+P("\r\n")/"\n"+P(1)
    )^0 )
local encoder=Cs((
     R("09","AZ","az")^1+S("-./_")^1+P(" ")/"+"+P("\n")/"\r\n"+unescapedchar
    )^0 )
lpegpatterns.urldecoder=decoder
lpegpatterns.urlencoder=encoder
function url.decode  (str) return str and lpegmatch(decoder,str) or str end
function url.encode  (str) return str and lpegmatch(encoder,str) or str end
function url.unescape(str) return str and lpegmatch(unescaper,str) or str end
local schemestr=Cs((escaped+(1-colon-slash-qmark-hash))^2)
local authoritystr=Cs((escaped+(1-   slash-qmark-hash))^0)
local pathstr=Cs((escaped+(1-   qmark-hash))^0)
local querystr=Cs(((1-      hash))^0)
local fragmentstr=Cs((escaped+(1-     endofstring))^0)
local scheme=schemestr*colon+nothing
local authority=slash*slash*authoritystr+nothing
local path=slash*pathstr+nothing
local query=qmark*querystr+nothing
local fragment=hash*fragmentstr+nothing
local validurl=scheme*authority*path*query*fragment
local parser=Ct(validurl)
lpegpatterns.url=validurl
lpegpatterns.urlsplitter=parser
local escaper=Cs((R("09","AZ","az")^1+P(" ")/"%%20"+S("-./_:")^1+P(1)/escapes)^0) 
local unescaper=Cs((escapedchar+1)^0)
local getcleaner=Cs((P("+++")/"%%2B"+P("+")/"%%20"+P(1))^1)
lpegpatterns.urlunescaped=escapedchar
lpegpatterns.urlescaper=escaper
lpegpatterns.urlunescaper=unescaper
lpegpatterns.urlgetcleaner=getcleaner
function url.unescapeget(str)
 return lpegmatch(getcleaner,str)
end
local function split(str)
 return (type(str)=="string" and lpegmatch(parser,str)) or str
end
local isscheme=schemestr*colon*slash*slash 
local function hasscheme(str)
 if str then
  local scheme=lpegmatch(isscheme,str) 
  return scheme~="" and scheme or false
 else
  return false
 end
end
local rootletter=R("az","AZ")+S("_-+")
local separator=P("://")
local qualified=P(".")^0*P("/")+rootletter*P(":")+rootletter^1*separator+rootletter^1*P("/")
local rootbased=P("/")+rootletter*P(":")
local barswapper=replacer("|",":")
local backslashswapper=replacer("\\","/")
local equal=P("=")
local amp=P("&")
local key=Cs(((plustospace+escapedchar+1)-equal     )^0)
local value=Cs(((plustospace+escapedchar+1)-amp-endofstring)^0)
local splitquery=Cf (Ct("")*P { "sequence",
 sequence=V("pair")*(amp*V("pair"))^0,
 pair=Cg(key*equal*value),
},rawset)
local userpart=(1-atsign-colon)^1
local serverpart=(1-colon)^1
local splitauthority=((Cs(userpart)*colon*Cs(userpart)+Cs(userpart)*Cc(nil))*atsign+Cc(nil)*Cc(nil))*Cs(serverpart)*(colon*(serverpart/tonumber)+Cc(nil))
local function hashed(str) 
 if not str or str=="" then
  return {
   scheme="invalid",
   original=str,
  }
 end
 local detailed=split(str)
 local rawscheme=""
 local rawquery=""
 local somescheme=false
 local somequery=false
 if detailed then
  rawscheme=detailed[1]
  rawquery=detailed[4]
  somescheme=rawscheme~=""
  somequery=rawquery~=""
 end
 if not somescheme and not somequery then
  return {
   scheme="file",
   authority="",
   path=str,
   query="",
   fragment="",
   original=str,
   noscheme=true,
   filename=str,
  }
 end
 local authority=detailed[2]
 local path=detailed[3]
 local filename  
 local username  
 local password  
 local host   
 local port   
 if authority~="" then
  username,password,host,port=lpegmatch(splitauthority,authority)
 end
 if authority=="" then
  filename=path
 elseif path=="" then
  filename=""
 else
  filename=authority.."/"..path
 end
 return {
  scheme=rawscheme,
  authority=authority,
  path=path,
  query=lpegmatch(unescaper,rawquery),
  queries=lpegmatch(splitquery,rawquery),
  fragment=detailed[5],
  original=str,
  noscheme=false,
  filename=filename,
  host=host,
  port=port,
 }
end
url.split=split
url.hasscheme=hasscheme
url.hashed=hashed
function url.addscheme(str,scheme) 
 if hasscheme(str) then
  return str
 elseif not scheme then
  return "file:///"..str
 else
  return scheme..":///"..str
 end
end
function url.construct(hash) 
 local result,r={},0
 local scheme=hash.scheme
 local authority=hash.authority
 local path=hash.path
 local queries=hash.queries
 local fragment=hash.fragment
 if scheme and scheme~="" then
  r=r+1;result[r]=lpegmatch(escaper,scheme)
  r=r+1;result[r]="://"
 end
 if authority and authority~="" then
  r=r+1;result[r]=lpegmatch(escaper,authority)
 end
 if path and path~="" then
  r=r+1;result[r]="/"
  r=r+1;result[r]=lpegmatch(escaper,path)
 end
 if queries then
  local done=false
  for k,v in sortedhash(queries) do
   r=r+1;result[r]=done and "&" or "?"
   r=r+1;result[r]=lpegmatch(escaper,k) 
   r=r+1;result[r]="="
   r=r+1;result[r]=lpegmatch(escaper,v) 
   done=true
  end
 end
 if fragment and fragment~="" then
  r=r+1;result[r]="#"
  r=r+1;result[r]=lpegmatch(escaper,fragment)
 end
 return concat(result)
end
local pattern=Cs(slash^-1/""*R("az","AZ")*((S(":|")/":")+P(":"))*slash*P(1)^0)
function url.filename(filename)
 local spec=hashed(filename)
 local path=spec.path
 return (spec.scheme=="file" and path and lpegmatch(pattern,path)) or filename
end
local function escapestring(str)
 return lpegmatch(escaper,str)
end
url.escape=escapestring
function url.query(str)
 if type(str)=="string" then
  return lpegmatch(splitquery,str) or ""
 else
  return str
 end
end
function url.toquery(data)
 local td=type(data)
 if td=="string" then
  return #str and escape(data) or nil 
 elseif td=="table" then
  if next(data) then
   local t={}
   for k,v in next,data do
    t[#t+1]=format("%s=%s",k,escapestring(v))
   end
   return concat(t,"&")
  end
 else
 end
end
local pattern=Cs(noslash^0*(1-noslash*P(-1))^0)
function url.barepath(path)
 if not path or path=="" then
  return ""
 else
  return lpegmatch(pattern,path)
 end
end

end -- closure

do -- begin closure to overcome local limits and interference

if not modules then modules={} end modules ['l-set']={
 version=1.001,
 comment="companion to luat-lib.mkiv",
 author="Hans Hagen, PRAGMA-ADE, Hasselt NL",
 copyright="PRAGMA ADE / ConTeXt Development Team",
 license="see context related readme files"
}
set=set or {}
local nums={}
local tabs={}
local concat=table.concat
local next,type=next,type
set.create=table.tohash
function set.tonumber(t)
 if next(t) then
  local s=""
  for k,v in next,t do
   if v then
    s=s.." "..k
   end
  end
  local n=nums[s]
  if not n then
   n=#tabs+1
   tabs[n]=t
   nums[s]=n
  end
  return n
 else
  return 0
 end
end
function set.totable(n)
 if n==0 then
  return {}
 else
  return tabs[n] or {}
 end
end
function set.tolist(n)
 if n==0 or not tabs[n] then
  return ""
 else
  local t,n={},0
  for k,v in next,tabs[n] do
   if v then
    n=n+1
    t[n]=k
   end
  end
  return concat(t," ")
 end
end
function set.contains(n,s)
 if type(n)=="table" then
  return n[s]
 elseif n==0 then
  return false
 else
  local t=tabs[n]
  return t and t[s]
 end
end

end -- closure
