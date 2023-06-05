#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# ndk dependencies
import nstd/types  as base
# ngpu dependencies
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

