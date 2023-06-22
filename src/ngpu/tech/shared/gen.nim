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
  ## Creates a Triangle Mesh object, with Deinterleaved vertex attributes.
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

#_____________________________
proc cube *() :Mesh=
  ## Creates a Cube mesh with Deinterleaved vertex attributes
  result = Mesh(
    pos: @[#  x    y    z
      vec3( -1, -1,  0 ),  # v0
      vec3(  1, -1,  0 ),  # v1
      vec3(  1, -1,  1 ),  # v2
      vec3( -1, -1,  1 ),  # v3
      vec3( -1,  1,  0 ),  # v4
      vec3(  1,  1,  0 ),  # v5
      vec3(  1,  1,  1 ),  # v6
      vec3( -1,  1,  1 ),  # v7
      ], # << pos
    color: @[#r   g    b    a
      color( 1.0, 0.0, 0.0, 1.0 ),  # v0
      color( 0.0, 1.0, 0.0, 1.0 ),  # v1
      color( 1.0, 0.0, 1.0, 1.0 ),  # v2
      color( 1.0, 1.0, 0.0, 1.0 ),  # v3
      color( 1.0, 0.0, 1.0, 1.0 ),  # v4
      color( 1.0, 1.0, 0.0, 1.0 ),  # v5
      color( 1.0, 1.0, 1.0, 1.0 ),  # v6
      color( 1.0, 1.0, 1.0, 1.0 ),  # v7
      ], # << color
    uv: @[#  u    v
      # NOTE: Incorrect (just placeholders)
      vec2( 1, 0 ),  # v0
      vec2( 0, 1 ),  # v1
      vec2( 1, 1 ),  # v2
      vec2( 0, 0 ),  # v3
      vec2( 1, 0 ),  # v4
      vec2( 0, 1 ),  # v5
      vec2( 1, 1 ),  # v6
      vec2( 0, 0 ),  # v7
      ], # << uv
    norm: @[
      # NOTE: Incorrect (just placeholders)
      vec3( 1, 0, 0 ),  # v0
      vec3( 0, 1, 0 ),  # v1
      vec3( 1, 0, 1 ),  # v2
      vec3( 1, 1, 0 ),  # v3
      vec3( 1, 0, 1 ),  # v4
      vec3( 1, 1, 0 ),  # v5
      vec3( 1, 1, 1 ),  # v6
      vec3( 1, 1, 1 ),  # v7
      ], # << norm
    inds: @[
      uvec3(0, 1, 2), uvec3(0, 2, 3),  # Bottom face
      uvec3(4, 5, 6), uvec3(4, 6, 7),  # Top    face
      uvec3(3, 2, 6), uvec3(3, 6, 7),  # Front  face
      uvec3(1, 0, 4), uvec3(1, 4, 5),  # Back   face
      uvec3(3, 0, 7), uvec3(0, 7, 4),  # Left   face
      uvec3(2, 1, 6), uvec3(1, 6, 5),  # Right  face
      ] # << inds
    ) # << Mesh()
  result.chk()

