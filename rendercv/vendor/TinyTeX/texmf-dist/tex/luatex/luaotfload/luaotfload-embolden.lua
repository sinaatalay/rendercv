-----------------------------------------------------------------------
--         FILE:  luaotfload-embolden.lua
--  DESCRIPTION:  part of luaotfload / embolden
-----------------------------------------------------------------------

assert(luaotfload_module, "This is a part of luaotfload and should not be loaded independently") { 
    name          = "luaotfload-embolden",
    version       = "3.26",       --TAGVERSION
    date          = "2023-08-31", --TAGDATE
    description   = "luaotfload submodule / embolden",
    license       = "GPL v2.0",
    author        = "Marcel Krüger"
}

local otffeatures        = fonts.constructors.newfeatures "otf"

local function enableembolden(tfmdata, _, embolden)
  tfmdata.mode, tfmdata.width = 2, tfmdata.size*embolden/6578.176
end

otffeatures.register {
  name        = "embolden",
  description = "embolden",
  manipulators = {
    base = enableembolden,
    node = enableembolden,
    plug = enableembolden,
  }
}

--- vim:sw=2:ts=2:expandtab:tw=71
