#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd
import nmath
# ngpu dependencies
import ../../types as ngpu
import ../../element/buffer
# Tech dependencies
import ./types as simple

#________________________________________________
# Helpers
#__________________
func vertCount *(m :Mesh) :uint32=  uint32( m.pos.len )
  ## Returns the mesh vertex count, based on the number of vertex positions.
func indsCount *(m :Mesh) :uint32=  uint32( m.inds.len * 3)
  ## Returns the mesh index count, based on the indices data. Assumes meshes are triangulated (aka 3 vertex per entry).
func indsCount *(m :RenderMesh) :uint32=  uint32( m.inds.data.len * 3)
  ## Returns the mesh index count, based on the indices data. Assumes meshes are triangulated (aka 3 vertex per entry).
#__________________
func size *(m :Mesh) :uint64=
  ## Returns the size in bytes of the given mesh
  for attr in m.fields:
    if attr.len > 0:  result += attr.size   # Do not add empty seq
#__________________
proc indexFormat *[T](_:typedesc[T]) :IndexFormat=
  ## Returns the IndexFormat type required for creating an index buffer with the given T.
  when T is UVec3:    IndexFormat.Uint32
  else: raise newException(LoadError, "Tried to return the IndexFormat of type {$T}, but the operation is not implemented for it.")
proc format *[T](_:typedesc[T]) :VertexFormat=
  ## Returns the VertexFormat type required for creating a vertex buffer with the given T.
  when T is Vec2:        result = VertexFormat.float32x2
  elif T is Vec3:        result = VertexFormat.float32x3
  elif T is Vec4:        result = VertexFormat.float32x4
  elif T is ngpu.Color:  result = VertexFormat.float32x4
  else: raise newException(LoadError, "Tried to return the VertexFormat of type {$T}, but the operation is not implemented for it.")

#__________________
proc new *(_:typedesc[VertexShape]; T :typedesc; location :Attr) :VertexShape=
  ## Returns a VertexShape object, with data based on `T` and `location`.
  new result
  result.attr = VertexAttribute(
    format         : T.format,
    offset         : 0, # Offset within the sub-buffer   !! Not the same as result.offset  !!
    shaderLocation : location,
    ) # << Attr
  result.ct = VertexBufferLayout(
    arrayStride      : T.sizeof.uint64,
    stepMode         : VertexStepMode.vertex,
    attributeCount   : 1,
    attributes       : result.attr.addr,
    ) # << VertexBufferLayout
#__________________
proc new *(_:typedesc[VertexShape]; vert :var VertexShape) :VertexBufferLayout=
  ## Returns a VertexShape object, with data based on a single VertexShape.
  ## The resulting data:
  ## - Is valid for sending to wgpu as it is.
  ## - Depends on the address of the input VertexShape.attr for its `attributes` field.
  result = VertexBufferLayout(
    arrayStride      : vert.ct.arrayStride,
    stepMode         : vert.ct.stepMode,
    attributeCount   : 1,
    attributes       : vert.attr.addr,
    ) # << VertexBufferLayout
#__________________
proc new *(_:typedesc[VertexShape]; verts :seq[VertexShape]) :seq[VertexBufferLayout]=
  ## Returns a seq[VertexBufferLayout] objects, with data based on the given seq[VertexShape].
  ## The resulting data:
  ## - Is valid for sending to wgpu as it is.
  ## - Depends on the address of the input VertexShape.attr for its `attributes` field.
  for vert in verts: result.add vert.ct
#__________________
proc new *(_:typedesc[Mesh]; t2:typedesc[MeshShape]) :MeshShape=
  ## Returns an appropriate MeshShape for the given `Mesh` type.
  result.add VertexShape.new(Vec3, Attr.pos)
  result.add VertexShape.new(ngpu.Color, Attr.color)
  result.add VertexShape.new(Vec2, Attr.uv)
  result.add VertexShape.new(Vec3, Attr.norm)

#__________________
proc new *[T](_:typedesc[MeshIndices[T]];
    data   : seq[T];
    offset : SomeInteger;
  ) :MeshIndices[T]=
  new result
  result.data   = data
  result.offset = offset.uint64
  result.size   = result.data.size
  result.format = T.indexFormat
#__________________
proc new *[T](_:typedesc[MeshAttribute[T]];
    kind    :Attr;
    data    :seq[T];
    offset  :u64;
  ) :MeshAttribute[T]=
  new result
  result.kind   = kind
  result.data   = data
  result.size   = data.size
  result.offset = offset
  result.layout = VertexShape.new(T, result.kind)

#__________________
proc get *(mesh :RenderMesh; _:typedesc[MeshShape]) :MeshShape=
  ## Returns the MeshShape of the given RenderMesh.
  @[mesh.pos.layout, mesh.color.layout, mesh.uv.layout, mesh.norm.layout]
#__________________
proc new *(_:typedesc[RenderMesh];
    mesh   : Mesh;
    device : ngpu.Device;
    label  : str = "ngpu | RenderMesh";
  ) :RenderMesh=
  ## Creates a new RenderMesh from the given Mesh object.
  ## This Technique uses a deinterleaved Vertex Buffer.
  new result
  result.buffer = ngpu.Buffer[Mesh].new(
    usage  = {BufferUsage.copyDst, BufferUsage.vertex, BufferUsage.index},
    size   = mesh.size,
    device = device,
    mapped = false,
    label  = label&" Buffer",
    ) # << device.createBuffer()
  result.inds  = MeshIndices[mesh.inds[0].type].new(
    data       = mesh.inds,
    offset     = 0,
    ) # << RenderMesh.inds
  result.pos   = MeshAttribute[mesh.pos[0].type].new(
    kind       = Attr.pos,
    data       = mesh.pos,
    offset     = result.inds.offset + result.inds.size,
    ) # << RenderMesh.pos
  result.color = MeshAttribute[mesh.color[0].type].new(
    kind       = Attr.color,
    data       = mesh.color,
    offset     = result.pos.offset + result.pos.size,
    ) # << RenderMesh.color
  result.uv    = MeshAttribute[mesh.uv[0].type].new(
    kind       = Attr.uv,
    data       = mesh.uv,
    offset     = result.color.offset + result.color.size,
    ) # << RenderMesh.uv
  result.norm  = MeshAttribute[mesh.norm[0].type].new(
    kind       = Attr.norm,
    data       = mesh.norm,
    offset     = result.uv.offset + result.uv.size,
    ) # << RenderMesh.norm
#__________________
proc new *(render :Renderer; _:typedesc[RenderMesh];
    mesh   : Mesh;
    label  : str = "ngpu | RenderMesh";
  ) :RenderMesh=
  RenderMesh.new(mesh, render.device, label)

#__________________
proc upload *[T](
    device : ngpu.Device;
    attr   : MeshComponent[T];
    buffer : ngpu.Buffer[Mesh];
  ) :void=
  ## Queues an upload operation to copy the given Attribute to the given Mesh Buffer.
  device.queue.ct.write(buffer.ct, attr.offset, attr.data[0].addr, attr.size.csize_t)
#__________________
proc upload *(
    device : ngpu.Device;
    mesh   : RenderMesh;
  ) :void=
  ## Queues upload operations to copy the given RenderMesh data to its GPU buffer.
  device.upload(mesh.inds,  mesh.buffer)
  device.upload(mesh.pos,   mesh.buffer)
  device.upload(mesh.color, mesh.buffer)
  device.upload(mesh.uv,    mesh.buffer)
  device.upload(mesh.norm,  mesh.buffer)
#___________________
proc upload *(render :Renderer; mesh :RenderMesh) :void=  render.device.upload(mesh)
  ## Queues upload operations to copy the given RenderMesh data to its GPU buffer.

