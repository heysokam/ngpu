#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# n*dk dependencies
import nstd/types  as base
# n*gpu dependencies
import ../../types as ngpu
import ../../element/bindings
import ../../element/texture

# Exports required by other modules that call this element
export texture.genCode
export texture.getCode
export texture.initCode
export texture.initBinding


#_______________________________________
proc new *(render :Renderer;
    _       : typedesc[TexData];
    img     : Image;
    varName : str;
    upload  : bool = false;
    label   : str  = "ngpu | Texture";
  ) :TexData=
  TexData.new(
    img     = img,
    device  = render.device,
    varName = varName,
    upload  = upload,
    label   = label,
    ) # << TexData.new( ... )
#___________________
proc new *(render :Renderer;
    _           : typedesc[ngpu.Texture];
    img         : Image;
    textureName : str;
    samplerName : str    = "";
    wrap        : Wrap   = Wrap.default();
    filter      : Filter = Filter.default();
    upload      : bool   = false;
    label       : str    = "ngpu | Texture";
  ) :ngpu.Texture=
  Texture.new(
    img         = img,
    device      = render.device,
    textureName = textureName,
    samplerName = samplerName,
    wrap        = wrap,
    filter      = filter,
    upload      = upload,
    label       = label,
    ) # << Texture.new( ... )

