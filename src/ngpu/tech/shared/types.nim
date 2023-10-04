#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# n*dk dependencies
import nstd/types  as base
import nmath/types as m
import nimp/mdl    as nimp
# n*gpu dependencies
import ../../types as ngpu

#_____________________________
# Export the nimp.Mesh type
export nimp.Mesh

#_____________________________
type Attr *{.pure.}= enum pos, color, uv, norm
  ## Attribute location ids for the shader
converter toUint32 *(attr :Attr) :uint32=  attr.ord.uint32
  ## Automatically convert to uint32 when required, without needing to add `.ord` everywhere.

#_____________________________
type MeshComponent *[T]= ref object of RootObj
  ## Base type that Indices/Attributes inherit from
  data    *:seq[T]
  offset  *:u64
  size    *:u64
type MeshIndices *[T]= ref object of MeshComponent[T]
  format  *:IndexFormat
type MeshAttribute *[T]= ref object of MeshComponent[T]
  kind    *:Attr
  layout  *:VertexShape
#_____________________________
type RenderMesh * = ref object
  pos     *:MeshAttribute[Vec3]
  color   *:MeshAttribute[ngpu.Color]
  uv      *:MeshAttribute[Vec2]
  norm    *:MeshAttribute[Vec3]
  inds    *:MeshIndices[U16Vec3]
  buffer  *:ngpu.Buffer[Mesh]

