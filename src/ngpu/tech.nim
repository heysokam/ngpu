#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# ngpu dependencies
import ./types

#________________________________________________
# Tech: Import/Export
#___________________
import ./tech/clear  ; export clear
import ./tech/simple ; export simple

#________________________________________________
# Tech: Draw Selection
proc draw *(render :var Renderer; tech :Tech) :void=
  case  tech
  of    Tech.Clear:  clear.draw(render)
  else: raise newException(DrawError, &"Drawing with RenderTech.{$tech} is not implemented. Create your own function to draw with it.")

