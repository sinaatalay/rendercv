--[[
   File `frenchb.lua’ generated from frenchb.dtx
         [2023/03/08 v3.5q French support from the babel system]
   Copyright © 2014-2022 Daniel Flipo
   <daniel (dot) flipo (at) free (dot) fr>
   License LPPL: see french.ldf.
--]]
local FB_punct_thin =
  {[string.byte("!")] = true,
   [string.byte("?")] = true,
   [string.byte(";")] = true}
local FB_punct_thick =
  {[string.byte(":")] = true}
local FB_punct_left =
  {[string.byte("!")] = true,
   [string.byte("?")] = true,
   [string.byte(";")] = true,
   [string.byte(":")] = true,
   [0x14]             = true,
   [0xBB]             = true}
local FB_punct_right =
  {[0x13]             = true,
   [0xAB]             = true}
local FB_punct_null =
  {[string.byte("!")] = true,
   [string.byte("?")] = true,
   [string.byte("[")] = true,
   [string.byte("(")] = true,
   [0xA0]             = true,
   [0x202F]           = true}
local FB_guil_null =
  {[0xA0]             = true,
   [0x202F]           = true}
local new_node     = node.new
local copy_node    = node.copy
local node_id      = node.id
local HLIST        = node_id("hlist")
local TEMP         = node_id("temp")
local KERN         = node_id("kern")
local GLUE         = node_id("glue")
local GLYPH        = node_id("glyph")
local PENALTY      = node_id("penalty")
local nobreak      = new_node(PENALTY)
nobreak.penalty    = 10000
local nbspace      = new_node(GLYPH)
local insert_node_before = node.insert_before
local insert_node_after  = node.insert_after
local remove_node        = node.remove
function FBget_glue(toks)
  local t = nil
  local f = string.match(toks,
                         "[^%w]hskip%s*([%d%.]*)%s*[^%w]fontdimen 2")
  if f == "" then f = 1 end
  if tonumber(f) then
     t = {tonumber(f), 0, 0}
     f = string.match(toks,    "plus%s*([%d%.]*)%s*[^%w]fontdimen 3")
     if f == "" then f = 1 end
     if tonumber(f) then
        t[2] = tonumber(f)
        f = string.match(toks, "minus%s*([%d%.]*)%s*[^%w]fontdimen 4")
        if f == "" then f = 1 end
        if tonumber(f) then
           t[3] = tonumber(f)
        end
     end
  elseif string.match(toks, "[^%w]F?B?thinspace") then
     t = {0.5, 0, 0}
  elseif string.match(toks, "[^%w]space") then
     t = {1, 1, 1}
  end
  return t
end
FBsp = {}
FBsp.thin = {}
FBsp.thin.gl = {}
FBsp.thin.gl.fr = {.5,  0,  0}  ; FBsp.thin.gl.ac = {}
FBsp.thin.ch = {}
FBsp.thin.ch.fr = 0x202F        ; FBsp.thin.ch.ac = nil
FBsp.colon = {}
FBsp.colon.gl = {}
FBsp.colon.gl.fr = { 1,  1,  1} ; FBsp.colon.gl.ac = {}
FBsp.colon.ch = {}
FBsp.colon.ch.fr = 0xA0         ; FBsp.colon.ch.ac = nil
FBsp.guill = {}
FBsp.guill.gl = {}
FBsp.guill.gl.fr = {.8, .3, .8} ; FBsp.guill.gl.ac = {}
FBsp.guill.ch = {}
FBsp.guill.ch.fr = 0xA0         ; FBsp.guill.ch.ac = nil
local font_table = {}
local function new_glue_scaled (fid,table)
  if fid > 0 and table[1] then
     local fp = font_table[fid]
     if not fp then
        local ft = font.getfont(fid)
        if ft then
           font_table[fid] = ft.parameters
           fp = font_table[fid]
        end
     end
     local gl = new_node(GLUE,0)
     if fp then
        node.setglue(gl, table[1]*fp.space,
                         table[2]*fp.space_stretch,
                         table[3]*fp.space_shrink)
        return gl
     else
        return nil
     end
  else
     return nil
  end
end
local FBspacing    = luatexbase.attributes['FB@spacing']
local addDPspace   = luatexbase.attributes['FB@addDPspace']
local addGUILspace = luatexbase.attributes['FB@addGUILspace']
local FBucsNBSP    = luatexbase.attributes['FB@ucsNBSP']
local FBdialect    = luatexbase.attributes['FB@dialect']
local has_attribute = node.has_attribute
-- Main function (to be added to the kerning callback).
local function french_punctuation (head)
  node.kerning(head)
  for item in node.traverse_id(GLYPH, head) do
    local lang = item.lang
    local char = item.char
    if (lang == FR_fr or lang == FR_ca) and
         (FB_punct_left[char] or FB_punct_right[char]) then
       local fid  = item.font
       local attr = item.attr
       local FRspacing = has_attribute(item, FBspacing)
       FRspacing = FRspacing and FRspacing > 0
       local FRucsNBSP = has_attribute(item, FBucsNBSP)
       FRucsNBSP = FRucsNBSP and FRucsNBSP > 0
       local FRdialect = has_attribute(item, FBdialect)
       FRdialect = FRdialect and FRdialect > 0
       local SIG  = has_attribute(item, addGUILspace)
       SIG = SIG and SIG >0
       if FRspacing and fid > 0 then
          if FB_punct_left[char] then
             local prev = item.prev
             local prev_id, prev_subtype, prev_char
             if prev then
                prev_id = prev.id
                prev_subtype = prev.subtype
                if prev_id == GLYPH then
                   prev_char = prev.char
                end
             end
             local is_glue = prev_id == GLUE
             local glue_wd
             if is_glue then
                glue_wd = prev.width
             end
             local realglue = is_glue and glue_wd > 1
             if FB_punct_thin[char] or FB_punct_thick[char] then
                local SBDP = has_attribute(item, addDPspace)
                local auto = SBDP and SBDP > 0
                if FB_punct_thick[char] and auto then
                   local next = item.next
                   local next_id
                   if next then
                      next_id = next.id
                   end
                   if next_id and next_id == GLYPH then
                      auto = false
                   end
                end
                if auto then
                   if (prev_char and FB_punct_null[prev_char]) or
                      (is_glue and glue_wd <= 1) or
                      (prev_id == HLIST and prev_subtype == 3) or
                      (prev_id == TEMP) then
                      auto = false
                   end
                end
                local fbglue
                local t
                if FB_punct_thick[char] then
                   if FRdialect then
                      t = FBsp.colon.gl.ac
                      nbspace.char = FBsp.colon.ch.ac
                   else
                      t = FBsp.colon.gl.fr
                      nbspace.char = FBsp.colon.ch.fr
                   end
                else
                   if FRdialect then
                      t = FBsp.thin.gl.ac
                      nbspace.char = FBsp.thin.ch.ac
                   else
                      t = FBsp.thin.gl.fr
                      nbspace.char = FBsp.thin.ch.fr
                   end
                end
                fbglue = new_glue_scaled(fid, t)
                if (realglue or auto) and fbglue then
                   if realglue then
                      head = remove_node(head,prev,true)
                   end
                   if (FRucsNBSP) then
                      nbspace.font = fid
                      nbspace.attr = attr
                      insert_node_before(head,item,copy_node(nbspace))
                   else
                      nobreak.attr = attr
                      fbglue.attr  = attr
                      insert_node_before(head,item,copy_node(nobreak))
                      insert_node_before(head,item,copy_node(fbglue))
                   end
                end
             elseif SIG then
                local addgl = (prev_char and
                               not FB_guil_null[prev_char])
                              or
                              (not prev_char and
                               prev_id ~= TEMP and
                               not (prev_id == HLIST and
                                    prev_subtype == 3)
                              )
                if is_glue and glue_wd <= 1 then
                   addgl = false
                end
                local t = FBsp.guill.gl.fr
                nbspace.char = FBsp.guill.ch.fr
                if FRdialect then
                   t = FBsp.guill.gl.ac
                   nbspace.char = FBsp.guill.ch.ac
                end
                local fbglue = new_glue_scaled(fid, t)
                if addgl and fbglue then
                   if is_glue then
                      head = remove_node(head,prev,true)
                   end
                   if (FRucsNBSP) then
                      nbspace.font = fid
                      nbspace.attr = attr
                      insert_node_before(head,item,copy_node(nbspace))
                   else
                      nobreak.attr = attr
                      fbglue.attr  = attr
                      insert_node_before(head,item,copy_node(nobreak))
                      insert_node_before(head,item,copy_node(fbglue))
                   end
                end
             end
          elseif SIG then
             local next = item.next
             local next_id, next_subtype, next_char, nextnext, kern_wd
             if next then
                next_id = next.id
                next_subtype = next.subtype
                if next_id == PENALTY then
                   nextnext = next.next
                   if nextnext and nextnext.id == GLUE then
                      head = remove_node(head,nextnext,true)
                      head = remove_node(head,next,true)
                      next = item.next
                      if next then
                         next_id = next.id
                         next_subtype = next.subtype
                         if next_id == GLYPH then
                            next_char = next.char
                         end
                     end
                   end
                end
                if next_id == KERN then
                   kern_wd = next.kern
                   if kern_wd == 0 then
                      nextnext = next.next
                      if nextnext then
                         next = nextnext
                         next_id = nextnext.id
                         next_subtype = nextnext.subtype
                         if next_id == PENALTY then
                            nextnext = next.next
                            if nextnext and nextnext.id == GLUE then
                               head = remove_node(head,next,true)
                               head = remove_node(head,nextnext,true)
                               next = item.next
                               if next then
                                  next_id = next.id
                                  next_subtype = next.subtype
                               end
                            end
                         end
                      end
                   end
                end
                if next_id == GLYPH then
                   next_char = next.char
                end
             end
             local is_glue = next_id == GLUE
             if is_glue then
                glue_wd = next.width
             end
             local addgl = (next_char and not FB_guil_null[next_char])
                           or (next and not next_char)
             if is_glue and glue_wd == 0 then
                addgl = false
             end
             local fid = item.font
             local t = FBsp.guill.gl.fr
             nbspace.char = FBsp.guill.ch.fr
             if FRdialect then
                t = FBsp.guill.gl.ac
                nbspace.char = FBsp.guill.ch.ac
             end
             local fbglue = new_glue_scaled(fid, t)
             if addgl and fbglue then
                if is_glue then
                   head = remove_node(head,next,true)
                end
                if (FRucsNBSP) then
                   nbspace.font = fid
                   nbspace.attr = attr
                   insert_node_after(head, item, copy_node(nbspace))
                else
                   nobreak.attr = attr
                   fbglue.attr  = attr
                   insert_node_after(head, item, copy_node(fbglue))
                   insert_node_after(head, item, copy_node(nobreak))
                end
             end
          end
       end
    end
  end
  return head
end
return french_punctuation
--  End of File frenchb.lua.
