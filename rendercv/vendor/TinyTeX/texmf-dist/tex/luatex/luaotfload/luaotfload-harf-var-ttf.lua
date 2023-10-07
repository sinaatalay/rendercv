-----------------------------------------------------------------------
--         FILE:  luaotfload-harf-var-ttf.lua
--  DESCRIPTION:  part of luaotfload / HarfBuzz / Parse and apply gvar tables
-----------------------------------------------------------------------
do
 assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
     name          = "luaotfload-harf-var-ttf",
     version       = "3.26",       --TAGVERSION
     date          = "2023-08-31", --TAGDATE
     description   = "luaotfload submodule / gvar table processing",
     license       = "GPL v2.0",
     author        = "Marcel Krüger",
     copyright     = "Luaotfload Development Team",     
 }
end

local hb = assert(luaotfload.harfbuzz)
local gvar_tag = hb.Tag.new'gvar'
local glyf_tag = hb.Tag.new'glyf'
local loca_tag = hb.Tag.new'loca'

local function read_tuple(data, offset, axes_count)
  local tuple = lua.newtable(axes_count, 0)
  for i=1, axes_count do
    tuple[i] = sio.readinteger2(data, offset + 2*i-2)
  end
  return tuple, offset + 2*axes_count
end

local function read_gvar(data)
  if 1 ~= sio.readcardinal2(data, 1) then
    return nil, 'Unknown gvar version'
  end
  local axes_count = sio.readcardinal2(data, 5)
  local shared_count = sio.readcardinal2(data, 7)
  local shared_offset = sio.readcardinal4(data, 9) + 1
  local glyph_count = sio.readcardinal2(data, 13)
  local flags = sio.readcardinal2(data, 15)
  local variation_offset = sio.readcardinal4(data, 17) + 1
  local variation_offsets = sio.readcardinaltable(data, 21, glyph_count+1, flags & 1 == 1 and 4 or 2)
  if flags & 1 == 1 then
    for i = 1, glyph_count+1 do
      variation_offsets[i] = variation_offset + variation_offsets[i]
    end
  else
    for i = 1, glyph_count+1 do
      variation_offsets[i] = variation_offset + 2*variation_offsets[i]
    end
  end

  local shared = lua.newtable(shared_count, 0)
  for i=1, shared_count do
    shared[i], shared_offset = read_tuple(data, shared_offset, axes_count)
  end

  local glyph_variation = lua.newtable(glyph_count, 0)
  for i = 1, glyph_count do
    local offset = variation_offsets[i]
    if variation_offsets[i+1] ~= offset then
      local tuple_variations = sio.readcardinal2(data, offset)
      local flags = tuple_variations >> 12
      tuple_variations = tuple_variations & 0xFFF
      local data_offset = offset + sio.readcardinal2(data, offset + 2)

      local headers = lua.newtable(tuple_variations, 0)
      offset = offset + 4
      for j=1, tuple_variations do
        local data_size = sio.readcardinal2(data, offset)
        local tuple_index = sio.readcardinal2(data, offset + 2)
        local peak, start_inter, end_inter
        offset = offset + 4
        if tuple_index & 0x8000 == 0x8000 then
          peak, offset = read_tuple(data, offset, axes_count)
        else
          peak = shared[(tuple_index & 0xFFF) + 1]
        end
        if tuple_index & 0x4000 == 0x4000 then
          start_inter, offset = read_tuple(data, offset, axes_count)
          end_inter, offset = read_tuple(data, offset, axes_count)
        end
        headers[j] = {
          size = data_size,
          peak = peak,
          start_inter = start_inter,
          end_inter = end_inter,
          private_points = tuple_index & 0x2000 == 0x2000 or nil,
        }
      end
      glyph_variation[i] = {
        offset = data_offset,
        shared_points = flags & 0x8 == 0x8 or nil,
        headers = headers,
      }
    end
  end
  return glyph_variation
end

local function read_loca(face)
  local data = face:get_table(loca_tag):get_data()
  local count = face:get_glyph_count() + 1
  if #data == count * 2 then
    local result = sio.readcardinaltable(data, 1, count, 2)
    for i=1, count do
      result[i] = 2 * result[i]
    end
    return result
  elseif #data == count * 4 then
    return sio.readcardinaltable(data, 1, count, 4)
  else
    return nil, 'Invalid loca format'
  end
end

local function parse_glyf(loca, glyf, gid)
  local offset = loca[gid + 1] + 1
  if loca[gid + 2] + 1 == offset then return end
  local num_contours = sio.readinteger2(glyf, offset)
  -- local xmin = sio.readinteger2(glyf, offset + 2)
  -- local ymin = sio.readinteger2(glyf, offset + 4)
  -- local xmax = sio.readinteger2(glyf, offset + 6)
  -- local ymax = sio.readinteger2(glyf, offset + 8)
  if num_contours < 0 then
    -- composite
    local xmin = sio.readinteger2(glyf, offset + 2)
    local ymin = sio.readinteger2(glyf, offset + 4)
    local xmax = sio.readinteger2(glyf, offset + 6)
    local ymax = sio.readinteger2(glyf, offset + 8)
    local components = { -- FIXME: These are likely incorrect
      xmin = xmin,
      ymin = ymin,
      xmax = xmax,
      ymax = ymax,
    }
    local flags
    offset = offset + 10
    repeat
      local component = {}
      flags = sio.readcardinal2(glyf, offset)
      component.glyph = sio.readcardinal2(glyf, offset + 2)
      local payload_length
      if flags & 0x2 == 0x2 then
        if flags & 0x1 == 0x1 then
          component.x = sio.readinteger2(glyf, offset + 4)
          component.y = sio.readinteger2(glyf, offset + 6)
          offset = offset + 8
        else
          component.x = sio.readinteger1(glyf, offset + 4)
          component.y = sio.readinteger1(glyf, offset + 5)
          offset = offset + 6
        end
        payload_length = 0
      else
        offset = offset + 4
        if flags & 0x1 == 0x1 then
          payload_length = 4
        else
          payload_length = 2
        end
      end
      if flags & 0x8 == 0x8 then
        payload_length = payload_length + 2
      elseif flags & 0x40 == 0x40 then
        payload_length = payload_length + 4
      elseif flags & 0x80 == 0x80 then
        payload_length = payload_length + 8
      end
      if flags & 0x120 == 0x100 then -- Only applies to the last character
        payload_length = payload_length + 2 + sio.readcardinal2(glyf, offset + payload_length)
      end
      component.flags = flags
      component.payload = glyf:sub(offset, offset + payload_length - 1)
      components[#components+1] = component
      offset = offset + payload_length
    until flags & 0x20 == 0
    return components
  else
    local end_contours = sio.readcardinaltable(glyf, offset+10, num_contours, 2)
    offset = offset + 10 + num_contours * 2
    local instruction_length = sio.readcardinal2(glyf, offset)
    local instructions = glyf:sub(offset+2, offset+1+instruction_length)
    offset = offset+2+instruction_length
    local total_points = end_contours[num_contours] + 1
    local points = lua.newtable(total_points, 2)
    do
      local i = 1
      while i <= total_points do
        local flags = sio.readcardinal1(glyf, offset)
        offset = offset + 1
        local count = 0
        if flags & 0x8 == 0x8 then
          count = sio.readcardinal1(glyf, offset)
          offset = offset + 1
        end
        for j=i, i + count do
          points[j] = {flags = flags}
        end
        i = i + 1 + count
      end
    end
    do
      local last = 0
      for i=1, total_points do
        local point = points[i]
        local flags = point.flags
        local value
        if flags & 0x2 == 0x2 then -- short
          value = sio.readcardinal1(glyf, offset)
          offset = offset + 1
          if flags & 0x10 == 0 then
            value = -value
          end
        elseif flags & 0x10 == 0 then
          value = sio.readinteger2(glyf, offset)
          offset = offset + 2
        else
          value = 0
        end
        last = last + value
        point.x = last
      end
      last = 0
      for i=1, total_points do
        local point = points[i]
        local flags = point.flags
        local value
        if flags & 0x4 == 0x4 then -- short
          value = sio.readcardinal1(glyf, offset)
          offset = offset + 1
          if flags & 0x20 == 0 then
            value = -value
          end
        elseif flags & 0x20 == 0 then
          value = sio.readinteger2(glyf, offset)
          offset = offset + 2
        else
          value = 0
        end
        last = last + value
        point.y = last
        point.flags = flags & 0xC1 -- Discard all flags we aready used
      end
      -- assert (i == total_points)
    end
    points.contours = end_contours
    points.instructions = instructions
    return points
  end
end

local function serialize_glyf(points, map)
  local contours = points.contours
  if points.contours then
    local flagdata, xdata, ydata = {}, {}, {}
    local last_flags, last_x, last_y = 0x100 -- Impossible flag to avoid triggering a repeated flag in the first step
    local xmin, ymin, xmax, ymax
    for i=1, #points do
      local point = points[i]
      local flags, x, y = point.flags, math.floor(point.x + .5), math.floor(point.y + .5)
      xmin = xmin and xmin < x and xmin or x
      xmax = xmax and xmax > x and xmax or x
      ymin = ymin and ymin < y and ymin or y
      ymax = ymax and ymax > y and ymax or y
      x, last_x = x - (last_x or 0), x
      if x == 0 then
        flags = flags | 0x10
      elseif x < 0x100 and x > -0x100 then
        if x < 0 then
          x = -x
          flags = flags | 0x2
        else
          flags = flags | 0x12
        end
        xdata[#xdata+1] = x
      else
        if x > 0x7FFF then
          x = 0x7FFF
        elseif x < -0x8000 then
          x = -0x8000
        end
        if x < 0 then
          x = x + 0x10000
        end
        xdata[#xdata+1] = x >> 8
        xdata[#xdata+1] = x & 0xFF
      end
      y, last_y = y - (last_y or 0), y
      if y == 0 then
        flags = flags | 0x20
      elseif y < 0x100 and y > -0x100 then
        if y < 0 then
          y = -y
          flags = flags | 0x4
        else
          flags = flags | 0x24
        end
        ydata[#ydata+1] = y
      else
        if y > 0x7FFF then
          y = 0x7FFF
        elseif y < -0x8000 then
          y = -0x8000
        end
        if y < 0 then
          y = y + 0x10000
        end
        ydata[#ydata+1] = y >> 8
        ydata[#ydata+1] = y & 0xFF
      end
      if flags == last_flags & 0x1F7 then
        if last_flags & 0x8 == 0x8 then
          flagdata[#flagdata] = flagdata[#flagdata] + 1
        else
          last_flags = last_flags | 0x8
          flagdata[#flagdata] = last_flags
          flagdata[#flagdata+1] = 1
        end
      else
        last_flags = flags
        flagdata[#flagdata+1] = last_flags
      end
    end
    local header = string.pack(">i2i2i2i2i2" .. string.rep('I2', #contours), #contours, xmin, ymin, xmax, ymax, table.unpack(contours))
    return header .. string.pack(">s2", points.instructions) .. string.char(table.unpack(flagdata)) .. string.char(table.unpack(xdata)) .. string.char(table.unpack(ydata))
  else
    local result = string.pack(">i2i2i2i2i2", -1, points.xmin, points.ymin, points.xmax, points.ymax)
    for i = 1, #points do
      local component = points[i]
      local x, y = component.x, component.y
      x = x and math.floor(x + .5)
      y = y and math.floor(y + .5)
      if component.flags & 0x3 == 0x2 and (x >= 0x100 or x < -0x100 or y >= 0x100 or y < 0x100) then
        component.flags = component.flags | 0x1
      end
      result = result
          .. string.pack(component.flags & 0x2 == 0 and '>I2I2'
                      or component.flags & 0x1 == 0x1 and '>I2I2i2i2'
                      or '>I2I2i1i1',
              component.flags, map[component.glyph], x, y)
          .. component.payload
    end
    return result
  end
end

local function read_points(gvar_data, offset)
  local point_count = sio.readcardinal1(gvar_data, offset)
  offset = offset + 1
  if point_count == 0 then
    return true, offset
  end
  if point_count & 0x80 ~= 0 then
    point_count = ((point_count & 0x7F) << 8) | sio.readcardinal1(gvar_data, offset)
    offset = offset + 1
  end
  local points = lua.newtable(point_count, 0)
  local i, last = 1, 1
  while i <= point_count do
    local control = sio.readcardinal1(gvar_data, offset)
    offset = offset + 1
    local count = (control & 0x7F) + 1
    local size = control & 0x80 == 0x80 and 2 or 1
    local read = size == 2 and sio.readcardinal2 or sio.readcardinal1
    for j=0, count - 1 do
      last = last + read(gvar_data, offset + j * size)
      points[i + j] = last
    end
    i, offset = i + count, offset + size * count
  end
  return points, offset
end

local function read_deltas(gvar_data, offset, count)
  local deltas = lua.newtable(count, 0)
  local i = 1
  while i <= count do
    local control = sio.readcardinal1(gvar_data, offset)
    offset = offset + 1
    local length = (control & 0x3F) + 1
    if control & 0x80 == 0x80 then
      for j=0, length - 1 do
        deltas[i + j] = 0
      end
    else
      local size = control & 0x40 == 0x40 and 2 or 1
      local read = size == 2 and sio.readinteger2 or sio.readinteger1
      for j=0, length - 1 do
        deltas[i + j] = read(gvar_data, offset + j * size)
      end
      offset = offset + size * length
    end
    i = i + length
  end
  return deltas, offset
end

local function interpolate_glyf(loca, gvar_index, gvar, glyf, gid, coords, map)
  local var = gvar_index[gid+1]
  if not var then
    local start = loca[gid+1] + 1
    local stop = loca[gid+2]
    -- If the glyph uses components then we can never just copy it but have to parse
    -- it to rewrite the components if necessary.
    if stop >= start + 2 and sio.readinteger2(glyf, start) < 0 then
      return serialize_glyf(parse_glyf(loca, glyf, gid), map)
    else
      return glyf:sub(start, stop)
    end
  end
  local points = parse_glyf(loca, glyf, gid)
  if not points then return '' end
  local offset = var.offset
  local shared_points
  if var.shared_points then
    shared_points, offset = read_points(gvar, offset)
  end
  for i=1, #var.headers do
    local header = var.headers[i]
    local size = header.size
    local factor = 1
    local start, peak, stop = header.start_inter, header.peak, header.end_inter
    for j = 1, #coords do
      local coord = coords[j]
      local peak = peak[j]
      local start = start and start[j] or peak < 0 and peak or 0
      local stop = stop and stop[j] or peak > 0 and peak or 0
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
    if factor ~= 0 then
      local base_points, suboffset
      if header.private_points then
        base_points, suboffset = read_points(gvar, offset)
      else
        base_points, suboffset = shared_points, offset
      end
      local count = base_points == true and #points + 4 or #base_points
      local x_deltas, y_deltas
      x_deltas, suboffset = read_deltas(gvar, suboffset, count)
      y_deltas, suboffset = read_deltas(gvar, suboffset, count)
      local contours = points.contours
      if contours then
        if base_points == true then
          for i=1, #points do
            local point = points[i]
            point.x = point.x + factor * x_deltas[i]
            point.y = point.y + factor * y_deltas[i]
          end
        else
          local contour = 1
          local last, last_x, last_y, last_dx, last_dy
          local first, first_x, first_y, first_dx, first_dy
          local cur = 1
          local skip = base_points[1] > contours[1] + 1
          local n_points = #points
          for i = 1, n_points do
            if i == contours[contour] + 2 then
              contour = contour + 1
              last_x, last_y, last_dx, last_dy = nil
              first_x, first_y, first_dx, first_dy = nil
              skip = (base_points[cur] or n_points + 1) > contours[contour] + 1
            end
            if not skip then
              local point = points[i]
              local this_x, this_y = point.x, point.y
              if base_points[cur] == i then
                repeat
                  last_x, last_y = this_x, this_y
                  last_dx, last_dy = x_deltas[cur], y_deltas[cur]
                  if not first_x then
                    first_x, first_y, first_dx, first_dy = last_x, last_y, last_dx, last_dy
                  end
                  point.x = last_x + factor * last_dx
                  point.y = last_y + factor * last_dy
                  cur = cur + 1
                until base_points[cur] ~= i
              else
                if not last_x then -- We started a new contour and haven't seen a real point yet. Look for the last one instead.
                  local idx = cur
                  while (base_points[idx + 1] or n_points + 1) <= contours[contour] + 1 do
                    idx = idx + 1
                  end
                  local idx_point = points[base_points[idx]]
                  last_x, last_y = idx_point.x, idx_point.y
                  last_dx, last_dy = x_deltas[idx], y_deltas[idx]
                end
                local after_x, after_y, after_dx, after_dy
                if (base_points[cur] or n_points + 1) <= contours[contour] + 1 then -- If the next point is part of the contour, use it. Otherwise use the first point in our contour)
                  local next_point = points[base_points[cur]]
                  after_x, after_y = next_point.x, next_point.y
                  after_dx, after_dy = x_deltas[cur], y_deltas[cur]
                else
                  after_x, after_y = first_x, first_y
                  after_dx, after_dy = first_dx, first_dy
                end

                -- The first case is a bit weird, but afterwards we just interpolate while clipping to the boundaries.
                -- See the gvar spec for details.
                if last_x == after_x then
                  if last_dx == after_dx then
                    point.x = this_x + factor * last_dx
                  end
                elseif this_x <= last_x and this_x <= after_x then
                  point.x = this_x + factor * (last_x < after_x and last_dx or after_dx)
                elseif this_x >= last_x and this_x >= after_x then
                  point.x = this_x + factor * (last_x > after_x and last_dx or after_dx)
                else -- We have to interpolate
                  local t = (this_x - last_x) / (after_x - last_x)
                  point.x = this_x + factor * ((1-t) * last_dx + t * after_dx)
                end

                -- And again for y
                if last_y == after_y then
                  if last_dy == after_dy then
                    point.y = this_y + factor * last_dy
                  end
                elseif this_y <= last_y and this_y <= after_y then
                  point.y = this_y + factor * (last_y < after_y and last_dy or after_dy)
                elseif this_y >= last_y and this_y >= after_y then
                  point.y = this_y + factor * (last_y > after_y and last_dy or after_dy)
                else -- We have to interpolate
                  local t = (this_y - last_y) / (after_y - last_y)
                  point.y = this_y + factor * ((1-t) * last_dy + t * after_dy)
                end
              end
            end
          end
        end
      else
        -- Composite glyph
        if base_points == true then
          for i=1, #points do
            local point = points[i]
            if point.x then
              point.x = point.x + factor * x_deltas[i]
              point.y = point.y + factor * y_deltas[i]
            end
          end
        else
          for i=1, #base_points do
            local point = points[base_points[i]]
            if point and point.x then
              point.x = point.x + factor * x_deltas[i]
              point.y = point.y + factor * y_deltas[i]
            end
          end
        end
      end
      assert(suboffset == offset + size)
    end
    offset = offset + size
  end
  return serialize_glyf(points, map)
end

return function(face, font, map, map_inv)
  local gvar = assert(face:get_table(gvar_tag):get_data())
  local gvar_index = assert(read_gvar(gvar))
  local loca = assert(read_loca(face))
  local glyf = assert(face:get_table(glyf_tag):get_data())
  local normalized = {font:get_var_coords_normalized()}
  return function(gid)
    return interpolate_glyf(loca, gvar_index, gvar, glyf, map_inv[gid], normalized, map)
  end
end
