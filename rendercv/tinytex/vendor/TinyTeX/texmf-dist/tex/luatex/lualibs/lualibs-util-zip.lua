if not modules then modules = { } end modules ['util-zip'] = {
    version   = 1.001,
    author    = "Hans Hagen, PRAGMA-ADE, Hasselt NL",
    copyright = "PRAGMA ADE / ConTeXt Development Team",
    license   = "see context related readme files"
}

-- This module is mostly meant for relative simple zip and unzip tasks. We can read
-- and write zip files but with limitations. Performance is quite good and it makes
-- us independent of zip tools, which (for some reason) are not always installed.
--
-- This is an lmtx module and at some point will be lmtx only but for a while we
-- keep some hybrid functionality.

local type, tostring, tonumber = type, tostring, tonumber
local sort, concat = table.sort, table.concat

local find, format, sub, gsub = string.find, string.format, string.sub, string.gsub
local osdate, ostime, osclock = os.date, os.time, os.clock
local ioopen = io.open
local loaddata, savedata = io.loaddata, io.savedata
local filejoin, isdir, dirname, mkdirs = file.join, lfs.isdir, file.dirname, dir.mkdirs
local suffix, suffixes = file.suffix, file.suffixes
local openfile = io.open

gzip = gzip or { } -- so in luatex we keep the old ones too

if not zlib then
    zlib = xzip    -- in luametatex we shadow the old one
elseif not xzip then
    xzip = zlib
end

local files         = utilities.files
local openfile      = files.open
local closefile     = files.close
local getsize       = files.size
local readstring    = files.readstring
local readcardinal2 = files.readcardinal2le
local readcardinal4 = files.readcardinal4le
local setposition   = files.setposition
local getposition   = files.getposition
local skipbytes     = files.skip

local band          = bit32.band
local rshift        = bit32.rshift
local lshift        = bit32.lshift

local zlibdecompress     = zlib.decompress
local zlibdecompresssize = zlib.decompresssize
local zlibchecksum       = zlib.crc32

if not CONTEXTLMTXMODE or CONTEXTLMTXMODE == 0 then
    local cs = zlibchecksum
    zlibchecksum = function(str,n) return cs(n or 0, str) end
end

local decompress     = function(source)            return zlibdecompress    (source,-15)            end -- auto
local decompresssize = function(source,targetsize) return zlibdecompresssize(source,targetsize,-15) end -- auto
local calculatecrc   = function(buffer,initial)    return zlibchecksum      (initial or 0,buffer)   end

local zipfiles      = { }
utilities.zipfiles  = zipfiles

local openzipfile, closezipfile, unzipfile, foundzipfile, getziphash, getziplist  do

    function openzipfile(name)
        return {
            name   = name,
            handle = openfile(name,0),
        }
    end

 -- https://pkware.cachefly.net/webdocs/casestudies/APPNOTE.TXT

--     local function collect(z)
--         if not z.list then
--             local list     = { }
--             local hash     = { }
--             local position = 0
--             local index    = 0
--             local handle   = z.handle
--             while true do
--                 setposition(handle,position)
--                 local signature = readstring(handle,4)
--                 if signature == "PK\3\4" then
--                     -- [local file header 1]
--                     -- [encryption header 1]
--                     -- [file data 1]
--                     -- [data descriptor 1]
--                     local version      = readcardinal2(handle)
--                     local flag         = readcardinal2(handle)
--                     local method       = readcardinal2(handle)
--                     local filetime     = readcardinal2(handle)
--                     local filedate     = readcardinal2(handle)
--                     local crc32        = readcardinal4(handle)
--                     local compressed   = readcardinal4(handle)
--                     local uncompressed = readcardinal4(handle)
--                     local namelength   = readcardinal2(handle)
--                     local extralength  = readcardinal2(handle)
--                     local filename     = readstring(handle,namelength)
--                     local descriptor   = band(flag,8) ~= 0
--                     local encrypted    = band(flag,1) ~= 0
--                     local acceptable   = method == 0 or method == 8
--                     -- 30 bytes of header including the signature
--                     local skipped      = 0
--                     local size         = 0
--                     if encrypted then
--                         size = readcardinal2(handle)
--                         skipbytes(handle,size)
--                         skipped = skipped + size + 2
--                         skipbytes(8)
--                         skipped = skipped + 8
--                         size = readcardinal2(handle)
--                         skipbytes(handle,size)
--                         skipped = skipped + size + 2
--                         size = readcardinal4(handle)
--                         skipbytes(handle,size)
--                         skipped = skipped + size + 4
--                         size = readcardinal2(handle)
--                         skipbytes(handle,size)
--                         skipped = skipped + size + 2
--                     end
--                     position = position + 30 + namelength + extralength + skipped
--                  -- if descriptor then
--                  --     -- where is this one located
--                  --     setposition(handle,position + compressed)
--                  --     crc32        = readcardinal4(handle)
--                  --     compressed   = readcardinal4(handle)
--                  --     uncompressed = readcardinal4(handle)
--                  -- end
--                     if acceptable then
--                         index = index + 1
--                         local data = {
--                             filename     = filename,
--                             index        = index,
--                             position     = position,
--                             method       = method,
--                             compressed   = compressed,
--                             uncompressed = uncompressed,
--                             crc32        = crc32,
--                             encrypted    = encrypted,
--                         }
--                         hash[filename] = data
--                         list[index]    = data
--                     else
--                         -- maybe a warning when encrypted
--                     end
--                     position = position + compressed
--                 else
--                     break
--                 end
--                 z.list = list
--                 z.hash = hash
--             end
--         end
--     end
-- end

--         end
--     end

    local function update(handle,data)
        position = data.offset
        setposition(handle,position)
        local signature = readstring(handle,4)
        if signature == "PK\3\4" then -- 0x04034B50
            -- [local file header 1]
            -- [encryption header 1]
            -- [file data 1]
            -- [data descriptor 1]
            local version      = readcardinal2(handle)
            local flag         = readcardinal2(handle)
            local method       = readcardinal2(handle)
                                  skipbytes(handle,4)
            ----- filetime     = readcardinal2(handle)
            ----- filedate     = readcardinal2(handle)
            local crc32        = readcardinal4(handle)
            local compressed   = readcardinal4(handle)
            local uncompressed = readcardinal4(handle)
            local namelength   = readcardinal2(handle)
            local extralength  = readcardinal2(handle)
            local filename     = readstring(handle,namelength)
            local descriptor   = band(flag,8) ~= 0
            local encrypted    = band(flag,1) ~= 0
            local acceptable   = method == 0 or method == 8
            -- 30 bytes of header including the signature
            local skipped      = 0
            local size         = 0
            if encrypted then
                size = readcardinal2(handle)
                skipbytes(handle,size)
                skipped = skipped + size + 2
                skipbytes(8)
                skipped = skipped + 8
                size = readcardinal2(handle)
                skipbytes(handle,size)
                skipped = skipped + size + 2
                size = readcardinal4(handle)
                skipbytes(handle,size)
                skipped = skipped + size + 4
                size = readcardinal2(handle)
                skipbytes(handle,size)
                skipped = skipped + size + 2
            end
            if acceptable then
                    if                       filename     ~= data.filename     then
             -- elseif                       method       ~= data.method       then
             -- elseif                       encrypted    ~= data.encrypted    then
             -- elseif crc32        ~= 0 and crc32        ~= data.crc32        then
             -- elseif uncompressed ~= 0 and uncompressed ~= data.uncompressed then
             -- elseif compressed   ~= 0 and compressed   ~= data.compressed   then
                else
                    position = position + 30 + namelength + extralength + skipped
                    data.position = position
                    return position
                end
            else
                -- maybe a warning when encrypted
            end
        end
        data.position = false
        return false
    end

    local function collect(z)
        if not z.list then
            local list     = { }
            local hash     = { }
            local position = 0
            local index    = 0
            local handle   = z.handle
            local size     = getsize(handle)
            --
            -- Not all files have the compressed into set so we need to get the directory
            -- first. We only handle single disk zip files.
            --
            for i=size-4,size-64*1024,-1 do
                setposition(handle,i)
                local enddirsignature = readcardinal4(handle)
                if enddirsignature == 0x06054B50 then
                    local thisdisknumber    = readcardinal2(handle)
                    local centraldisknumber = readcardinal2(handle)
                    local thisnofentries    = readcardinal2(handle)
                    local totalnofentries   = readcardinal2(handle)
                    local centralsize       = readcardinal4(handle)
                    local centraloffset     = readcardinal4(handle)
                    local commentlength     = readcardinal2(handle)
                    local comment           = readstring(handle,length)
                    if size - i >= 22 then
                        if thisdisknumber == centraldisknumber then
                            setposition(handle,centraloffset)
                            while true do
                                if readcardinal4(handle) == 0x02014B50 then
                                                          skipbytes(handle,4)
                                    ----- versionmadeby = readcardinal2(handle)
                                    ----- versionneeded = readcardinal2(handle)
                                    local flag          = readcardinal2(handle)
                                    local method        = readcardinal2(handle)
                                                          skipbytes(handle,4)
                                    ----- filetime      = readcardinal2(handle)
                                    ----- filedate      = readcardinal2(handle)
                                    local crc32         = readcardinal4(handle)
                                    local compressed    = readcardinal4(handle)
                                    local uncompressed  = readcardinal4(handle)
                                    local namelength    = readcardinal2(handle)
                                    local extralength   = readcardinal2(handle)
                                    local commentlength = readcardinal2(handle)
                                                          skipbytes(handle,8)
                                    ----- disknumber    = readcardinal2(handle)
                                    ----- intattributes = readcardinal2(handle)
                                    ----- extattributes = readcardinal4(handle)
                                    local headeroffset  = readcardinal4(handle)
                                    local filename      = readstring(handle,namelength)
                                                          skipbytes(handle,extralength+commentlength)
                                    ----- extradata     = readstring(handle,extralength)
                                    ----- comment       = readstring(handle,commentlength)
                                    --
                                    local descriptor   = band(flag,8) ~= 0
                                    local encrypted    = band(flag,1) ~= 0
                                    local acceptable   = method == 0 or method == 8
                                    if acceptable then
                                        index = index + 1
                                        local data = {
                                            filename     = filename,
                                            index        = index,
                                            position     = nil,
                                            method       = method,
                                            compressed   = compressed,
                                            uncompressed = uncompressed,
                                            crc32        = crc32,
                                            encrypted    = encrypted,
                                            offset       = headeroffset,
                                        }
                                        hash[filename] = data
                                        list[index]    = data
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
         -- for i=1,index do -- delayed
         --     local data = list[i]
         --     if not data.position then
         --         update(handle,list[i])
         --     end
         -- end
            z.list = list
            z.hash = hash
        end
    end

    function getziplist(z)
        local list = z.list
        if not list then
            collect(z)
        end
     -- inspect(z.list)
        return z.list
    end

    function getziphash(z)
        local hash = z.hash
        if not hash then
            collect(z)
        end
        return z.hash
    end

    function foundzipfile(z,name)
        return getziphash(z)[name]
    end

    function closezipfile(z)
        local f = z.handle
        if f then
            closefile(f)
            z.handle = nil
        end
    end

    function unzipfile(z,filename,check)
        local hash = z.hash
        if not hash then
            hash = zipfiles.hash(z)
        end
        local data = hash[filename] -- normalize
        if not data then
            -- lower and cleanup
            -- only name
        end
        if data then
            local handle     = z.handle
            local position   = data.position
            local compressed = data.compressed
            if position == nil then
                position = update(handle,data)
            end
            if position and compressed > 0 then
                setposition(handle,position)
                local result = readstring(handle,compressed)
                if data.method == 8 then
                    if decompresssize then
                        result = decompresssize(result,data.uncompressed)
                    else
                        result = decompress(result)
                    end
                end
                if check and data.crc32 ~= calculatecrc(result) then
                    print("checksum mismatch")
                    return ""
                end
                return result
            else
                return ""
            end
        end
    end

    zipfiles.open  = openzipfile
    zipfiles.close = closezipfile
    zipfiles.unzip = unzipfile
    zipfiles.hash  = getziphash
    zipfiles.list  = getziplist
    zipfiles.found = foundzipfile

end

if xzip then -- flate then do

    local writecardinal1 = files.writebyte
    local writecardinal2 = files.writecardinal2le
    local writecardinal4 = files.writecardinal4le

    local logwriter      = logs.writer

    local globpattern    = dir.globpattern
--     local compress       = flate.flate_compress
--     local checksum       = flate.update_crc32
    local compress       = xzip.compress
    local checksum       = xzip.crc32

 -- local function fromdostime(dostime,dosdate)
 --     return ostime {
 --         year  = (dosdate >>  9) + 1980, -- 25 .. 31
 --         month = (dosdate >>  5) & 0x0F, -- 21 .. 24
 --         day   = (dosdate      ) & 0x1F, -- 16 .. 20
 --         hour  = (dostime >> 11)       , -- 11 .. 15
 --         min   = (dostime >>  5) & 0x3F, --  5 .. 10
 --         sec   = (dostime      ) & 0x1F, --  0 ..  4
 --     }
 -- end
 --
 -- local function todostime(time)
 --     local t = osdate("*t",time)
 --     return
 --         ((t.year - 1980) <<  9) + (t.month << 5) +  t.day,
 --          (t.hour         << 11) + (t.min   << 5) + (t.sec >> 1)
 -- end

    local function fromdostime(dostime,dosdate)
        return ostime {
            year  =      rshift(dosdate, 9) + 1980,  -- 25 .. 31
            month = band(rshift(dosdate, 5),  0x0F), -- 21 .. 24
            day   = band(      (dosdate   ),  0x1F), -- 16 .. 20
            hour  = band(rshift(dostime,11)       ), -- 11 .. 15
            min   = band(rshift(dostime, 5),  0x3F), --  5 .. 10
            sec   = band(      (dostime   ),  0x1F), --  0 ..  4
        }
    end

    local function todostime(time)
        local t = osdate("*t",time)
        return
            lshift(t.year - 1980, 9) + lshift(t.month,5) +        t.day,
            lshift(t.hour       ,11) + lshift(t.min  ,5) + rshift(t.sec,1)
    end

    local function openzip(filename,level,comment,verbose)
        local f = ioopen(filename,"wb")
        if f then
            return {
                filename     = filename,
                handle       = f,
                list         = { },
                level        = tonumber(level) or 3,
                comment      = tostring(comment),
                verbose      = verbose,
                uncompressed = 0,
                compressed   = 0,
            }
        end
    end

    local function writezip(z,name,data,level,time)
        local f        = z.handle
        local list     = z.list
        local level    = tonumber(level) or z.level or 3
        local method   = 8
        local zipped   = compress(data,level)
        local checksum = checksum(data)
        local verbose  = z.verbose
        --
        if not zipped then
            method = 0
            zipped = data
        end
        --
        local start        = f:seek()
        local compressed   = #zipped
        local uncompressed = #data
        --
        z.compressed   = z.compressed   + compressed
        z.uncompressed = z.uncompressed + uncompressed
        --
        if verbose then
            local pct = 100 * compressed/uncompressed
            if pct >= 100 then
                logwriter(format("%10i        %s",uncompressed,name))
            else
                logwriter(format("%10i  %02.1f  %s",uncompressed,pct,name))
            end
        end
        --
        f:write("\x50\x4b\x03\x04") -- PK..  0x04034b50
        --
        writecardinal2(f,0)            -- minimum version
        writecardinal2(f,0)            -- flag
        writecardinal2(f,method)       -- method
        writecardinal2(f,0)            -- time
        writecardinal2(f,0)            -- date
        writecardinal4(f,checksum)     -- crc32
        writecardinal4(f,compressed)   -- compressed
        writecardinal4(f,uncompressed) -- uncompressed
        writecardinal2(f,#name)        -- namelength
        writecardinal2(f,0)            -- extralength
        --
        f:write(name)                  -- name
        f:write(zipped)
        --
        list[#list+1] = { #zipped, #data, name, checksum, start, time or 0 }
    end

    local function closezip(z)
        local f       = z.handle
        local list    = z.list
        local comment = z.comment
        local verbose = z.verbose
        local count   = #list
        local start   = f:seek()
        --
        for i=1,count do
            local l = list[i]
            local compressed   = l[1]
            local uncompressed = l[2]
            local name         = l[3]
            local checksum     = l[4]
            local start        = l[5]
            local time         = l[6]
            local date, time   = todostime(time)
            f:write('\x50\x4b\x01\x02')
            writecardinal2(f,0)            -- version made by
            writecardinal2(f,0)            -- version needed to extract
            writecardinal2(f,0)            -- flags
            writecardinal2(f,8)            -- method
            writecardinal2(f,time)         -- time
            writecardinal2(f,date)         -- date
            writecardinal4(f,checksum)     -- crc32
            writecardinal4(f,compressed)   -- compressed
            writecardinal4(f,uncompressed) -- uncompressed
            writecardinal2(f,#name)        -- namelength
            writecardinal2(f,0)            -- extralength
            writecardinal2(f,0)            -- commentlength
            writecardinal2(f,0)            -- nofdisks -- ?
            writecardinal2(f,0)            -- internal attr (type)
            writecardinal4(f,0)            -- external attr (mode)
            writecardinal4(f,start)        -- local offset
            f:write(name)                  -- name
        end
        --
        local stop = f:seek()
        local size = stop - start
        --
        f:write('\x50\x4b\x05\x06')
        writecardinal2(f,0)            -- disk
        writecardinal2(f,0)            -- disks
        writecardinal2(f,count)        -- entries
        writecardinal2(f,count)        -- entries
        writecardinal4(f,size)         -- dir size
        writecardinal4(f,start)        -- dir offset
        if type(comment) == "string" and comment ~= "" then
            writecardinal2(f,#comment) -- comment length
            f:write(comment)           -- comemnt
        else
            writecardinal2(f,0)
        end
        --
        if verbose then
            local compressed   = z.compressed
            local uncompressed = z.uncompressed
            local filename     = z.filename
            --
            local pct = 100 * compressed/uncompressed
            logwriter("")
            if pct >= 100 then
                logwriter(format("%10i        %s",uncompressed,filename))
            else
                logwriter(format("%10i  %02.1f  %s",uncompressed,pct,filename))
            end
        end
        --
        f:close()
    end

    local function zipdir(zipname,path,level,verbose)
        if type(zipname) == "table" then
            verbose = zipname.verbose
            level   = zipname.level
            path    = zipname.path
            zipname = zipname.zipname
        end
        if not zipname or zipname == "" then
            return
        end
        if not path or path == "" then
            path = "."
        end
        if not isdir(path) then
            return
        end
        path = gsub(path,"\\+","/")
        path = gsub(path,"/+","/")
        local list  = { }
        local count = 0
        globpattern(path,"",true,function(name,size,time)
            count = count + 1
            list[count] = { name, time }
        end)
        sort(list,function(a,b)
            return a[1] < b[1]
        end)
        local zipf = openzip(zipname,level,comment,verbose)
        if zipf then
            local p = #path + 2
            for i=1,count do
                local li   = list[i]
                local name = li[1]
                local time = li[2]
                local data = loaddata(name)
                local name = sub(name,p,#name)
                writezip(zipf,name,data,level,time,verbose)
            end
            closezip(zipf)
        end
    end

    local function unzipdir(zipname,path,verbose,collect,validate)
        if type(zipname) == "table" then
            validate = zipname.validate
            collect  = zipname.collect
            verbose  = zipname.verbose
            path     = zipname.path
            zipname  = zipname.zipname
        end
        if not zipname or zipname == "" then
            return
        end
        if not path or path == "" then
            path = "."
        end
        local z = openzipfile(zipname)
        if z then
            local list = getziplist(z)
            if list then
                local total = 0
                local count = #list
                local step  = number.idiv(count,10)
                local done  = 0
                local steps = verbose == "steps"
                local time  = steps and osclock()
             -- local skip  = 0
                if collect then
                    collect = { }
                else
                    collect = false
                end
                for i=1,count do
                    local l = list[i]
                    local n = l.filename
                    if not validate or validate(n) then
                        local d = unzipfile(z,n) -- true for check
                        if d then
                            local p = filejoin(path,n)
                            if mkdirs(dirname(p)) then
                                if steps then
                                    total = total + #d
                                    done = done + 1
                                    if done >= step then
                                        done = 0
                                        logwriter(format("%4i files of %4i done, %10i bytes, %0.3f seconds",i,count,total,osclock()-time))
                                    end
                                elseif verbose then
                                    logwriter(n)
                                end
                                savedata(p,d)
                                if collect then
                                    collect[#collect+1] = p
                                end
                            end
                        else
                            logwriter(format("problem with file %s",n))
                        end
                    else
                     -- skip = skip + 1
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

    zipfiles.zipdir   = zipdir
    zipfiles.unzipdir = unzipdir

end

-- todo: compress/decompress that work with offset in string

-- We only have a few official methods here:
--
--   local decompressed = gzip.load       (filename)
--   local resultsize   = gzip.save       (filename,compresslevel)
--   local compressed   = gzip.compress   (str,compresslevel)
--   local decompressed = gzip.decompress (str)
--   local iscompressed = gzip.compressed (str)
--   local suffix, okay = gzip.suffix     (filename)
--
-- In LuaMetaTeX we have only xzip which implements a very few methods:
--
--   compress   (str,level,method,window,memory,strategy)
--   decompress (str,window)
--   adler32    (str,checksum)
--   crc32      (str,checksum)

local pattern   = "^\x1F\x8B\x08"
local gziplevel = 3

function gzip.suffix(filename)
    local suffix, extra = suffixes(filename)
    local gzipped = extra == "gz"
    return suffix, gzipped
end

function gzip.compressed(s)
    return s and find(s,pattern)
end

local getdecompressed
local putcompressed

if gzip.compress then

    local gzipwindow = 15 + 16 -- +16: gzip, +32: gzip|zlib

    local compress   = zlib.compress
    local decompress = zlib.decompress

    getdecompressed = function(str)
        return decompress(str,gzipwindow) -- pass offset
    end

    putcompressed = function(str,level)
        return compress(str,level or gziplevel,nil,gzipwindow)
    end

else

    -- Special window values are: flate: -15, zlib: 15, gzip : -15

    local gzipwindow = -15 -- miniz needs this
    local identifier = "\x1F\x8B"

    local compress      = zlib.compress
    local decompress    = zlib.decompress
    local zlibchecksum  = zlib.crc32

    if not CONTEXTLMTXMODE or CONTEXTLMTXMODE == 0 then
        local cs = zlibchecksum
        zlibchecksum = function(str,n) return cs(n or 0, str) end
    end

    local streams       = utilities.streams
    local openstream    = streams.openstring
    local closestream   = streams.close
    local getposition   = streams.getposition
    local readbyte      = streams.readbyte
    local readcardinal4 = streams.readcardinal4le
    local readcardinal2 = streams.readcardinal2le
    local readstring    = streams.readstring
    local readcstring   = streams.readcstring
    local skipbytes     = streams.skip

    local tocardinal1   = streams.tocardinal1
    local tocardinal4   = streams.tocardinal4le

    getdecompressed = function(str)
        local s = openstream(str)
        local identifier  = readstring(s,2)
        local method      = readbyte(s,1)
        local flags       = readbyte(s,1)
        local timestamp   = readcardinal4(s)
        local compression = readbyte(s,1)
        local operating   = readbyte(s,1)
     -- local isjusttext  = (flags & 0x01 ~= 0) and true             or false
     -- local extrasize   = (flags & 0x04 ~= 0) and readcardinal2(s) or 0
     -- local filename    = (flags & 0x08 ~= 0) and readcstring(s)   or ""
     -- local comment     = (flags & 0x10 ~= 0) and readcstring(s)   or ""
     -- local checksum    = (flags & 0x02 ~= 0) and readcardinal2(s) or 0
        local isjusttext  = band(flags,0x01) ~= 0 and true             or false
        local extrasize   = band(flags,0x04) ~= 0 and readcardinal2(s) or 0
        local filename    = band(flags,0x08) ~= 0 and readcstring(s)   or ""
        local comment     = band(flags,0x10) ~= 0 and readcstring(s)   or ""
        local checksum    = band(flags,0x02) ~= 0 and readcardinal2(s) or 0
        local compressed  = readstring(s,#str)
        local data = decompress(compressed,gzipwindow) -- pass offset
        return data
    end

    putcompressed = function(str,level,originalname)
        return concat {
            identifier, -- 2 identifier
            tocardinal1(0x08), -- 1 method
            tocardinal1(0x08), -- 1 flags
            tocardinal4(os.time()), -- 4 mtime
            tocardinal1(0x02), -- 1 compression (2 or 4)
            tocardinal1(0xFF), -- 1 operating
            (originalname or "unknownname") .. "\0",
            compress(str,level,nil,gzipwindow),
            tocardinal4(zlibchecksum(str)), -- 4
            tocardinal4(#str), -- 4
        }
    end

end

function gzip.load(filename)
    local f = openfile(filename,"rb")
    if not f then
        -- invalid file
    else
        local data = f:read("*all")
        f:close()
        if data and data ~= "" then
            if suffix(filename) == "gz" then
                data = getdecompressed(data)
            end
            return data
        end
    end
end

function gzip.save(filename,data,level,originalname)
    if suffix(filename) ~= "gz" then
        filename = filename .. ".gz"
    end
    local f = openfile(filename,"wb")
    if f then
        data = putcompressed(data or "",level or gziplevel,originalname)
        f:write(data)
        f:close()
        return #data
    end
end

function gzip.compress(s,level)
    if s and not find(s,pattern) then
        if not level then
            level = gziplevel
        elseif level <= 0 then
            return s
        elseif level > 9 then
            level = 9
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

-- return zipfiles
