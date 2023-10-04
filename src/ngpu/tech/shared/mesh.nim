#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# n*dk dependencies
import nstd
import nmath
# n*gpu dependencies
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
func hasPos    *(m :RenderMesh) :bool=  m.pos.data.len > 0
func hasColors *(m :RenderMesh) :bool=  m.color.data.len > 0
func hasUVs    *(m :RenderMesh) :bool=  m.uv.data.len > 0
func hasNorms  *(m :RenderMesh) :bool=  m.norm.data.len > 0
func hasInds   *(m :RenderMesh) :bool=  m.inds.data.len > 0
#__________________
func hasPos    *(m :Mesh) :bool=  m.pos.len > 0
func hasColors *(m :Mesh) :bool=  m.color.len > 0
func hasUVs    *(m :Mesh) :bool=  m.uv.len > 0
func hasNorms  *(m :Mesh) :bool=  m.norm.len > 0
func hasInds   *(m :Mesh) :bool=  m.inds.len > 0
#__________________
proc chk *(mesh :Mesh) :void=
  ## Checks that all attributes of the mesh have data, and contain the same amount of vertex.
  assert mesh != nil,    "Mesh objects must be initialized"
  assert mesh.hasPos,    "Mesh objects must have vertex positions data"
  assert mesh.hasColors, "Mesh objects must have vertex colors data"
  assert mesh.hasUVs,    "Mesh objects must have UVs data"
  assert mesh.hasNorms,  "Mesh objects must have vertex normals data"
  assert mesh.hasInds,   "Mesh objects must have indices data"
  let vertc = mesh.vertCount.int
  assert vertc == mesh.color.len and
         vertc == mesh.uv.len and
         vertc == mesh.norm.len,
         "All attributes must contain the same amount of vertex"
#__________________
func size *(m :Mesh) :uint64=
  ## Returns the size in bytes of the given mesh
  for attr in m[].fields():
    if attr.len > 0:  result += attr.size   # Do not add empty seq
#__________________
proc indexFormat *[T](_:typedesc[T]) :IndexFormat=
  ## Returns the IndexFormat type required for creating an index buffer with the given T.
  when T is UVec3   : IndexFormat.Uint32
  elif T is U16Vec3 : IndexFormat.Uint16
  else: raise newException(LoadError, &"Tried to return the IndexFormat of type {$T}, but the operation is not implemented for it.")
proc format *[T](_:typedesc[T]) :VertexFormat=
  ## Returns the VertexFormat type required for creating a vertex buffer with the given T.
  when T is Vec2       : result = VertexFormat.float32x2
  elif T is Vec3       : result = VertexFormat.float32x3
  elif T is Vec4       : result = VertexFormat.float32x4
  elif T is ngpu.Color : result = VertexFormat.float32x4
  else: raise newException(LoadError, &"Tried to return the VertexFormat of type {$T}, but the operation is not implemented for it.")

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
func fillerData [T](_:typedesc[T]; pos :seq[Vec3]) :seq[T]=
  ## Returns a seq of T, with the same length as the given vertex positions list
  for entry in pos: result.add default(T)
#__________________
proc new *(_:typedesc[RenderMesh];
    mesh   : Mesh;
    device : ngpu.Device;
    label  : str = "ngpu | RenderMesh";
  ) :RenderMesh=
  ## Creates a new RenderMesh from the given Mesh object.
  ## This Technique uses a deinterleaved Vertex Buffer.
  if not mesh.hasPos   : raise newException(DataError, "Illegal Mesh operation: Tried to create a RenderMesh from a Mesh that has no vertex position data.")
  if not mesh.hasInds  : raise newException(DataError, "Unsupported Mesh operation: Tried to create a RenderMesh from a Mesh that has no indices data.")
  if not mesh.hasNorms : raise newException(DataError, "Unsupported Mesh operation: Tried to create a RenderMesh from a Mesh that has no normals data.")
  new result
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
    data       = if mesh.hasColors: mesh.color else: fillerData(mesh.color[0].type, mesh.pos),
    offset     = result.pos.offset + result.pos.size,
    ) # << RenderMesh.color
  result.uv    = MeshAttribute[mesh.uv[0].type].new(
    kind       = Attr.uv,
    data       = if mesh.hasUVs: mesh.uv else: fillerData(mesh.uv[0].type, mesh.pos),
    offset     = result.color.offset + result.color.size,
    ) # << RenderMesh.uv
  result.norm  = MeshAttribute[mesh.norm[0].type].new(
    kind       = Attr.norm,
    data       = mesh.norm,
    offset     = result.uv.offset + result.uv.size,
    ) # << RenderMesh.norm
  result.buffer = ngpu.Buffer[Mesh].new(
    usage  = {BufferUsage.copyDst, BufferUsage.vertex, BufferUsage.index},
    size   = result.inds.size + result.pos.size + result.color.size + result.uv.size + result.norm.size,
    device = device,
    mapped = false,
    label  = label&" Buffer",
    ) # << device.createBuffer()
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
  if not mesh.hasPos    : raise newException(DataError, "Uploading a RenderMesh to the GPU without position data is an illegal operation.")
  if not mesh.hasInds   : raise newException(DataError, "Uploading a RenderMesh without indices data to the GPU is not supported.")
  if not mesh.hasColors : raise newException(DataError, "Uploading a RenderMesh without colors  data to the GPU is not supported.")
  if not mesh.hasUVs    : raise newException(DataError, "Uploading a RenderMesh without uvs     data to the GPU is not supported.")
  if not mesh.hasNorms  : raise newException(DataError, "Uploading a RenderMesh without normals data to the GPU is not supported.")
  device.upload(mesh.inds,  mesh.buffer)
  device.upload(mesh.pos,   mesh.buffer)
  device.upload(mesh.color, mesh.buffer)
  device.upload(mesh.uv,    mesh.buffer)
  device.upload(mesh.norm,  mesh.buffer)
#___________________
proc upload *(render :Renderer; mesh :RenderMesh) :void=  render.device.upload(mesh)
  ## Queues upload operations to copy the given RenderMesh data to its GPU buffer.

