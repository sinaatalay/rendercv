-----------------------------------------------------------------------
--         FILE:  luaotfload-harf-var-cff2.lua
--  DESCRIPTION:  part of luaotfload / HarfBuzz / Parse and convert CFF2 tables
-----------------------------------------------------------------------
do
 assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
     name          = "luaotfload-harf-var-cff2",
     version       = "3.26",       --TAGVERSION
     date          = "2023-08-31", --TAGDATE
     description   = "luaotfload submodule / CFF2 table processing",
     license       = "GPL v2.0",
     author        = "Marcel Krüger",
     copyright     = "Luaotfload Development Team",     
 }
end

local hb = assert(luaotfload.harfbuzz)
local cff2 = hb.Tag.new'CFF2'
local serialize = require'luaotfload-harf-var-t2-writer'

local offsetfmt = ">I%i"
local function parse_index(buf, i)
  local count, offsize
  count, offsize, i = string.unpack(">I4B", buf, i)
  if count == 0 then return {}, i-1 end
  local fmt = offsetfmt:format(offsize)
  local offsets = {}
  local dataoffset = i + offsize*count - 1
  for j=1,count+1 do
    offsets[j], i = string.unpack(fmt, buf, i)
  end
  for j=1,count+1 do
    offsets[j] = offsets[j] + i - 1
  end
  return offsets, offsets[#offsets]
end

local real_mapping = { [0] = '0', '1', '2', '3', '4', '5', '6', '7', '8', '9',
  '.', 'E', 'E-', nil, '-', nil}
local function parse_real(cs, offset)
  local c = cs:byte(offset)
  if not c then return offset end
  local c1, c2 = real_mapping[c>>4], real_mapping[c&0xF]
  if not c1 or not c2 then
    return c1 or offset, c1 and offset
  else
    return c1, c2, parse_real(cs, offset+1) --Warning: This is not a tail-call,
    -- so we are affected by the stack limit. On the other hand, as long as
    -- there are less than ~50 bytes we should be safe.
  end
end

local function get_number(result)
  assert(#result == 1)
  local num = result[1]
  result[1] = nil
  return num
end

local function get_bool(result)
  return get_number(result) == 1
end

local function get_array(result)
  local arr = table.move(result, 1, #result, 1, {})
  for i=1,#result do result[i] = nil end
  return arr
end

local function get_delta(result)
  local arr = get_array(result)
  local last = 0
  for i=1,#arr do
    arr[i] = arr[i]+last
    last = arr[i]
  end
  return arr
end

local function get_private(result)
  local arr = get_array(result)
  assert(#arr == 2)
  return arr
end

local function do_blend(result, vstore)
  if not vstore then
    error'blend operator only allowed in Private disctionary of variable fonts'
  end
  local vsindex = (result.vsindex or 0) + 1
  local factors = vstore[vsindex]
  local n = result[#result]
  local k = #factors
  local before = #result - 1 - n*(k+1)
  for i = 1, n do
    local val = result[before + i]
    for j = 1, k do
      val = val + factors[j] * result[before + n + (i-1) * k + j]
    end
    result[before + i] = math.floor(val + .5)
  end
  for i = before + n + 1, #result do
    result[i] = nil
  end
  return arr
end

local function apply_matrix(m, x, y)
  return (m[1] * x + m[3] * y + m[5])*1000, (m[2] * x + m[4] * y + m[6])*1000
end

local operators = {
  [6] = {'BlueValues', get_delta},
  [7] = {'OtherBlues', get_delta},
  [8] = {'FamilyBlues', get_delta},
  [9] = {'FamilyOtherBlues', get_delta},
 [10] = {'StdHW', get_number},
 [11] = {'StdVW', get_number},
 [17] = {'CharStrings', get_number},
 [18] = {'Private', get_private},
 [19] = {'Subrs', get_number},
 [22] = {'vsindex', get_number},
 [23] = {'blend', do_blend},
 [24] = {'vstore', get_number},
 [-8] = {'FontMatrix', get_array},
[-10] = {'BlueScale', get_number},
[-11] = {'BlueShift', get_number},
[-12] = {'BlueFuzz', get_number},
[-13] = {'StemSnapH', get_delta},
[-14] = {'StemSnapV', get_delta},
[-15] = {'ForceBold', get_bool}, -- ???
[-18] = {'LanguageGroup', get_number},
[-19] = {'ExpansionFactor', get_number},
[-20] = {'initialRandomSeed', get_number}, -- ???
[-37] = {'FDArray', get_number},
[-38] = {'FDSelect', get_number},
}
local function parse_dict(buf, i, j, vstore)
  result = {}
  while i<=j do
    local cmd = buf:byte(i)
    if cmd == 29 then
      result[#result+1] = string.unpack(">i4", buf:sub(i+1, i+4))
      i = i+4
    elseif cmd == 28 then
      result[#result+1] = string.unpack(">i2", buf:sub(i+1, i+2))
      i = i+2
    elseif cmd >= 251 then -- Actually "and cmd ~= 255", but 255 is reserved
      result[#result+1] = -((cmd-251)*256)-string.byte(buf, i+1)-108
      i = i+1
    elseif cmd >= 247 then
      result[#result+1] = (cmd-247)*256+string.byte(buf, i+1)+108
      i = i+1
    elseif cmd >= 32 then
      result[#result+1] = cmd-139
    elseif cmd == 30 then -- 31 is reserved again
      local real = {parse_real(buf, i+1)}
      i = real[#real]
      real[#real] = nil
      result[#result+1] = tonumber(table.concat(real))
    else
      if cmd == 12 then
        i = i+1
        cmd = -buf:byte(i)-1
      end
      local op = operators[cmd]
      if not op then error[[Unknown CFF operator]] end
      result[op[1]] = op[2](result, vstore)
    end
    i = i+1
  end
  return result
end

local function parse_charstring(buf, start, after, globalsubrs, subrs, result)
  local lastresult = result[#result]
  while start ~= after do
    local cmd = buf:byte(start)
    if cmd == 28 then
      lastresult[#lastresult+1] = string.unpack(">i2", buf:sub(start+1, start+2))
      start = start+2
    elseif cmd == 255 then
      lastresult[#lastresult+1] = string.unpack(">i4", buf:sub(start+1, start+4))/0x10000
      start = start+4
    elseif cmd >= 251 then
      lastresult[#lastresult+1] = -((cmd-251)*256)-string.byte(buf, start+1)-108
      start = start+1
    elseif cmd >= 247 then
      lastresult[#lastresult+1] = (cmd-247)*256+string.byte(buf, start+1)+108
      start = start+1
    elseif cmd >= 32 then
      lastresult[#lastresult+1] = cmd-139
    elseif cmd == 10 then
      local idx = lastresult[#lastresult]+subrs.bias
      local sub_start = subrs[idx]
      local sub_stop = subrs[idx+1]
      lastresult[#lastresult] = nil
      parse_charstring(buf, sub_start, sub_stop, globalsubrs, subrs, result)
      lastresult = result[#result]
    elseif cmd == 29 then
      local idx = lastresult[#lastresult]+globalsubrs.bias
      local sub_start = globalsubrs[idx]
      local sub_stop = globalsubrs[idx+1]
      lastresult[#lastresult] = nil
      parse_charstring(buf, sub_start, sub_stop, globalsubrs, subrs, result)
      lastresult = result[#result]
    elseif cmd == 11 then
      break -- We do not keep subroutines, so drop returns and continue with the outer commands
    elseif cmd == 15 then -- vsindex
      assert(#lastresult == 2)
      result.factors = result.vstore[lastresult[2] + 1]
      lastresult[2] = nil
    elseif cmd == 16 then -- blend
      local factors = result.factors
      if not factors then
        error'blend operator outside of variable font or with invalid vsindex'
      end
      local n = lastresult[#lastresult]
      local k = #factors
      local before = #lastresult - 1 - n*(k+1)
      for i = 1, n do
        local val = lastresult[before + i]
        for j = 1, k do
          val = val + factors[j] * lastresult[before + n + (i-1) * k + j]
        end
        lastresult[before + i] = math.floor(val + .5)
      end
      for i = before + n + 1, #lastresult do
        lastresult[i] = nil
      end
    else
      if cmd == 12 then
        start = start+1
        cmd = -buf:byte(start)-1
      elseif cmd == 19 or cmd == 20 then
        if #result == 1 then
          lastresult = {}
          result[#result+1] = lastresult
        end
        local newi = start+(result.stemcount+7)//8
        lastresult[2] = buf:sub(start+1, newi)
        start = newi
      elseif cmd == 21 and #result == 1 then
        table.insert(result, 1, {false})
        if #lastresult == 4 then
          result[1][2] = lastresult[2]
          table.remove(lastresult, 2)
        end
      elseif (cmd == 4 or cmd == 22) and #result == 1 then
        table.insert(result, 1, {false})
        if #lastresult == 3 then
          result[1][2] = lastresult[2]
          table.remove(lastresult, 2)
        end
      elseif cmd == 14 and #result == 1 then
        table.insert(result, 1, {false})
        if #lastresult == 2 or #lastresult == 6 then
          result[1][2] = lastresult[2]
          table.remove(lastresult, 2)
        end
      elseif cmd == 1 or cmd == 3 or cmd == 18 or cmd == 23 then
        if #result == 1 then
          table.insert(result, 1, {false})
          if #lastresult % 2 == 0 then
            result[1][2] = lastresult[2]
            table.remove(lastresult, 2)
          end
        end
        result.stemcount = result.stemcount + #lastresult//2
      end
      lastresult[1] = cmd
      lastresult =  {false}
      result[#result+1] = lastresult
    end
    start = start+1
  end
  return result
end

local function parse_fdselect(buf, offset, CharStrings)
  local format
  format, offset = string.unpack(">B", buf, offset)
  if format == 0 then
    for i=0,#CharStrings-1 do
      local code
      code, offset = string.unpack(">B", buf, offset)
      CharStrings[i][3] = code + 1
    end -- Reimplement with string.byte
  elseif format == 3 then
    local count, last
    count, offset = string.unpack(">I2", buf, offset)
    for i=1,count do
      local first, code, after = string.unpack(">I2BI2", buf, offset)
      for j=first, after-1 do
        CharStrings[j][3] = code + 1
      end
      offset = offset + 3
    end
  elseif format == 4 then
    local count, last
    count, offset = string.unpack(">I4", buf, offset)
    for i=1,count do
      local first, code, after = string.unpack(">I4I2I4", buf, offset)
      for j=first, after-1 do
        CharStrings[j][3] = code + 1
      end
      offset = offset + 6
    end
  else
    error[[Invalid FDSelect format]]
  end
end

local function parse_vstore(buf, offset, variation)
  local size, format, region_list_off, item_variation_count, off = string.unpack(">I2I2I4I2", buf, offset)
  if format ~= 1 then
    error'Unsupported vstore format'
  end
  offset = offset + 2 -- Skip the size
  region_list_off = offset + region_list_off

  local axis_count, region_count
  axis_count, region_count, region_list_off = string.unpack(">I2I2", buf, region_list_off)

  local variation_regions = {}
  for i = 1, region_count do
    local factor = 1
    for j = 1, axis_count do
      local start, peak, stop
      start, peak, stop, region_list_off = string.unpack(">i2i2i2", buf, region_list_off)
      local coord = variation[j]
      if peak == 0 then -- Skip
      elseif peak == coord then
        -- factor = factor * 1
      elseif coord <= start or coord >= stop then
        factor = 0
        break
      elseif coord < peak then
        factor = factor * ((coord-start) / (peak-start))
      else--if coord > peak then
        factor = factor * ((stop-coord) / (stop-peak))
      end
    end
    variation_regions[i] = factor
  end
  
  local variation_data = {}
  for i = 1, item_variation_count do
    local item_off
    item_off, off = string.unpack(">I4", buf, off)
    local i_count, short_count, region_count
    i_count, short_count, region_count, item_off = string.unpack(">I2I2I2", buf, item_off + offset)
    if i_count ~= 0 or short_count ~= 0 then
      error'Unexpected variation items in CFF2 table'
    end
    local factors = {}
    for j = 1, region_count do
      local region
      region, item_off = string.unpack(">I2", buf, item_off)
      factors[j] = variation_regions[region+1]
    end
    variation_data[i] = factors
  end
  return variation_data
end

local function parse_cff2(buf, i0, coords)
  local fontid = 1
  local major, minor, hdrSize, topSize = string.unpack(">BBBH", buf, i0)
  if major ~= 2 then error[[Unsupported CFF version]] end
  local i = i0 + hdrSize
  local top = parse_dict(buf, i, i + topSize - 1)
  i = i + topSize
  local globalsubrs
  globalsubrs, i = parse_index(buf, i)
  globalsubrs.bias = #globalsubrs-1 < 1240 and 108 or #globalsubrs-1 < 33900 and 1132 or 32769
  top.GlobalSubrs = globalsubrs
  local CharStrings = parse_index(buf, i0+top.CharStrings)
  for i=1,#CharStrings-1 do
    CharStrings[i-1] = {CharStrings[i], CharStrings[i+1]-1}
  end
  CharStrings[#CharStrings] = nil
  CharStrings[#CharStrings] = nil
  local fonts = parse_index(buf, i0+top.FDArray)
  top.FDArray = nil
  top.vstore = parse_vstore(buf, i0 + top.vstore, coords)
  local privates = {}
  top.Privates = privates
  for i=1,#fonts-1 do
    local font = fonts[i]
    local fontdir = parse_dict(buf, fonts[i], fonts[i+1]-1)
    privates[i] = parse_dict(buf, i0+fontdir.Private[2], i0+fontdir.Private[2]+fontdir.Private[1]-1, top.vstore)
    local subrs = privates[i].Subrs
    if subrs then
      subrs = parse_index(buf, i0+fontdir.Private[2]+subrs)
      subrs.bias = #subrs-1 < 1240 and 108 or #subrs-1 < 33900 and 1132 or 32769
      privates[i].Subrs = subrs
    end
  end
  if top.FDSelect then
    parse_fdselect(buf, i0+top.FDSelect, CharStrings)
  else
    for i=0,#CharStrings-1 do
      CharStrings[i][3] = 1
    end
  end
  top.CharStrings = CharStrings
  local bbox
  if top.FontMatrix then
    local x0, y0 = apply_matrix(top.FontMatrix, top.FontBBox[1], top.FontBBox[2])
    local x1, y1 = apply_matrix(top.FontMatrix, top.FontBBox[3], top.FontBBox[4])
    bbox = {x0, y0, x1, y1}
  else
    bbox = top.FontBBox
  end
  return top, bbox
end

local function parse_glyph(buffer, top, gid)
  local cs = top.CharStrings[gid]
  local Private = top.Privates[cs[3]]
  return parse_charstring(buffer, cs[1], cs[2] + 1,
    top.GlobalSubrs, Private.Subrs,
    {{false}, stemcount = 0, vstore = top.vstore, factors = top.vstore and top.vstore[(Private.vsindex or 0) + 1]})
end

return function(face, font)
  local data = face:get_table(cff2):get_data()
  local content = parse_cff2(data, 1, {font:get_var_coords_normalized()})
  return function(gid)
    local glyph = parse_glyph(data, content, gid)
    glyph[1][2] = font:get_glyph_h_advance(gid)
    return serialize(glyph)
  end
end
