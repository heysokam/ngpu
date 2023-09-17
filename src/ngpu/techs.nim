#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  :
#:____________________________________________________
# std dependencies
import std/strformat
# n*dk dependencies
import nstd/types as base
# n*gpu dependencies
import ./types as ngpu

#________________________________________________
# Tech: Import/Export
#___________________
# Shared
import ./tech/shared/types as Type
export Type.RenderMesh
import ./tech/shared/mesh
export mesh.new
export mesh.upload
import ./tech/shared/texture
export texture.new
#___________________
import ./tech/clear
import ./tech/triangle
import ./tech/simple

#________________________________________________
# Tech: Init Selection
#___________________
proc init *(render :var Renderer; tech :Tech; code :str; data :var tuple) :RenderTech=
  case  tech
  of    Tech.Clear:     raise newException(InitError, "Initializing Tech.Clear is not needed. Just call to draw with its name directly.")
  of    Tech.Triangle:  result = triangle.init(render)
  of    Tech.Simple:    result = simple.init(render, code, data)
  else: raise newException(InitError, "Initializing RenderTech.{$tech} is not implemented. Create your own function for it, or submit a PR.")
#___________________
proc init *(render :var Renderer; tech :Tech) :RenderTech=
  var noData :tuple= ()
  result = render.init(tech, NoCode, noData)
#___________________
proc init *(render :var Renderer; tech :Tech; code :str) :RenderTech=
  var noData :tuple= ()
  result = render.init(tech, code, noData)

#________________________________________________
# Tech: Draw Selection
#___________________
proc draw *(render :var Renderer; tech :Tech) :void=
  case  tech
  of    Tech.Clear: clear.draw(render)
  else: raise newException(DrawError, &"Drawing with Tech.{$tech} without a RenderMesh or a RenderTech is not supported. Remember that RenderTech and Tech are different types.")
#___________________
proc draw *(render :var Renderer; tech :var RenderTech) :void=
  case  tech.kind
  of    Tech.Clear:     raise newException(DrawError, "Drawing Tech.Clear with a RenderTech object is not supported. Use Tech.Clear directly instead.")
  of    Tech.Triangle:  triangle.draw(render, tech)
  else: raise newException(DrawError, &"Drawing with RenderTech.{$tech.kind} without a RenderMesh is not supported.")
#___________________
proc draw *(render :var Renderer; mesh :seq[RenderMesh]; tech :var RenderTech) :void=
  case  tech.kind
  of    Tech.Clear, Tech.Triangle: raise newException(DrawError, &"Drawing a mesh with RenderTech.{$tech.kind} is not supported. Remove the mesh to call the other function overloads.")
  of    Tech.Simple:  simple.draw(render, mesh, tech)
  else: raise newException(DrawError, &"Drawing a RenderMesh with RenderTech.{$tech.kind} is not implemented. Create your own function for it, or submit a PR.")
#___________________
proc draw *(render :var Renderer; mesh :RenderMesh; tech :var RenderTech) :void=  render.draw( @[mesh], tech )
  ## Draws a single mesh.  note: Alias for ergonomics.
  ## Converts into a list, and draws it with the seq[RenderMesh] function instead.

