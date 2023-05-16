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
import ./tech/clear
import ./tech/triangle
import ./tech/simple   ; export simple

#________________________________________________
# Tech: Init Selection
#___________________
proc init *(render :var Renderer; tech :Tech) :RenderTech=
  case  tech
  of    Tech.Clear:     raise newException(InitError, "Initializing Tech.Clear is not needed. Just draw with it directly.")
  of    Tech.Triangle:  result = triangle.init(render)
  else: raise newException(InitError, &"Initializing RenderTech.{$tech} is not implemented. Create your own function for it, or submit a PR.")

#________________________________________________
# Tech: Draw Selection
#___________________
proc draw *(render :var Renderer; tech :Tech) :void=
  case  tech
  of    Tech.Clear:     clear.draw(render)
  else: raise newException(DrawError, &"Drawing with Tech.{$tech} without a RenderMesh or a RenderTech is not supported. Remember that RenderTech and Tech are different types.")
#___________________
proc draw *(render :var Renderer; tech :var RenderTech) :void=
  case  tech.kind
  of    Tech.Clear:     raise newException(DrawError, "Drawing Tech.Clear with a RenderTech object is not supported. Use Tech.Clear directly instead.")
  of    Tech.Triangle:  triangle.draw(render, tech)
  else: raise newException(DrawError, &"Drawing with RenderTech.{$tech.kind} without a RenderMesh is not supported.")

