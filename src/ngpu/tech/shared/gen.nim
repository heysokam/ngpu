#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# ndk dependencies
import nmath
# ngpu dependencies
import ../../tool/color
# Tech.shared dependencies
import ./types
import ./mesh


#_____________________________
proc chk (mesh :Mesh) :void=
  ## Checks that all attributes in the given Mesh contain the same amount of vertex.
  let vertc = mesh.vertCount.int
  assert vertc == mesh.color.len and 
         vertc == mesh.uv.len and 
         vertc == mesh.norm.len,
         "All attributes must contain the same amount of vertex"

#_____________________________
proc triangle *() :Mesh=
  ## Creates a Triangle Mesh object.
  result = Mesh(
    pos: @[#  x    y    z
      vec3( -0.5, -0.5, 0.0 ),  # v0
      vec3(  0.5, -0.5, 0.0 ),  # v1
      vec3(  0.0,  0.5, 0.0 ),  # v2
      ], # << pos
    color: @[#r   g    b    a
      color( 1.0, 0.0, 0.0, 1.0 ),  # v0
      color( 0.0, 1.0, 0.0, 1.0 ),  # v1
      color( 0.0, 0.0, 1.0, 1.0 ),  # v2
      ], # << color
    uv: @[#  u    v
      vec2( 1.0, 0.0 ),  # v0
      vec2( 0.0, 0.0 ),  # v1
      vec2( 0.0, 1.0 ),  # v2
      ], # << uv
    norm: @[
      vec3( 1.0, 0.0, 0.0 ),  # v0
      vec3( 0.0, 1.0, 0.0 ),  # v1
      vec3( 0.0, 0.0, 1.0 ),  # v2
      ], # norm
    inds: @[uvec3(0,1,2)]
    ) # << Mesh()
  result.chk()

