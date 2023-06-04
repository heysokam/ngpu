#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/packedsets
# External dependencies
import pkg/chroma
# ndk dependencies
import nstd/types  as base
import nmath/types as m
from   nglfw       as glfw import nil
from   wgpu        import nil

#_______________________________________
# Exports
#__________________
export wgpu.BufferUsage
export chroma.Color

#_______________________________________
# ngpu: Constants
#__________________
const NoFile     * = "UndefinedFile.ext"
const NoCode     * = "// NoShaderCode"
const NoTypeCode * = "// NoTypeCode"

#_______________________________________
# ngpu: Errors
#__________________
type InitError * = object of IOError  ## When initializing objects in the whole lib.
type LoadError * = object of IOError  ## When trying to load a resource.
type DataError * = object of IOError  ## When trying to access data that should already be loaded/declared.
type DrawError * = object of IOError  ## When trying to draw an object.
#_______________________________________
# ngpu: Window
#__________________
type Window * = ref object
  ct     *:glfw.Window
  size   *:UVec2
  title  *:str

#_______________________________________
# ngpu: Elements
#__________________
type Instance * = ref object
  ct       *:wgpu.Instance
  cfg      *:wgpu.InstanceDescriptor
  label    *:str
#__________________
type AdapterBase * = ref object of RootObj
  ## Base Adapter. Used only for no-window apps.
  ct       *:wgpu.Adapter
  cfg      *:wgpu.RequestAdapterOptions
  label    *:str
type Adapter * = ref object of AdapterBase
  surface  *:wgpu.Surface
#__________________
type CommandBuffer * = ref object
  ct       *:wgpu.CommandBuffer
  cfg      *:wgpu.CommandBufferDescriptor
  label    *:str
#__________________
type CommandEncoder * = ref object
  ct       *:wgpu.CommandEncoder
  cfg      *:wgpu.CommandEncoderDescriptor
  label    *:str
#__________________
type Queue * = ref object
  ct       *:wgpu.Queue
  buffer   *:CommandBuffer
  encoder  *:CommandEncoder
#__________________
type Device * = ref object
  limits   *:wgpu.RequiredLimits
  features *:seq[wgpu.Feature]
  ct       *:wgpu.Device
  cfg      *:wgpu.DeviceDescriptor
  label    *:str
  queue    *:Queue   ## Device Queue. Contains the Command Buffer and Encoder
#__________________
type Swapchain * = ref object
  view     *:wgpu.TextureView
  ct       *:wgpu.Swapchain
  cfg      *:wgpu.SwapChainDescriptor
  label    *:str
#__________________
type Buffer *[T]= ref object
  data   *:T
  ct     *:wgpu.Buffer
  cfg    *:wgpu.BufferDescriptor
  label  *:str

#_______________________________________
# ngpu: Core
#__________________
type Renderer * = ref object of RootObj
  ## Rendering core
  label      *:str
  win        *:Window
  bg         *:Color
  instance   *:Instance
  adapter    *:Adapter
  device     *:Device
  swapChain  *:Swapchain
  # cam        *:Camera
#__________________
type Minimal * = ref object of RootObj
  ## Minimal core
  label     *:str
  instance  *:Instance
  adapter   *:AdapterBase
  device    *:Device
#__________________
type Compute * = ref object of RootObj
  ## Compute-only core
  label     *:str



#_______________________________________
# ngpu: Tech Elements
#__________________
const DefaultMaxBindgroups * = 4     # from: https://docs.rs/wgpu-types/0.16.0/src/wgpu_types/lib.rs.html#912
const DefaultMaxBindings   * = 640
#_____________________________
type BindingKind *{.pure.}= enum data, blck, sampler, tex, texStore
type BindingID  * = range[0..DefaultMaxBindings-1]  ## Range of ids allowed for binding.
type BindingIDs * = PackedSet[BindingID]            ## Contains the binding ids used by a binding group.
type Group *{.pure.}= enum  # aka BindGroup id
  global   ##  Data that never changes, or changes once per frame.
  model    ##  Data used for an entire model. Changes only on model change.
  mesh     ##  Data of a single Mesh. Changes each time the Mesh is changed.
  multi    ##  Data that changes more than once for the same Mesh (multipass). Maximum guaranteed group to exist.
  # other  ##  Other data. We use wgpu.default() values, so it is disabled. Not guaranteed to exist by the spec.
converter toInt *[T :SomeInteger](g :Group) :T=  T(g.ord)
#_____________________________
type BindingShape * = ref object
  kind   *:BindingKind  # TODO: Texture+Sampler binding shape as variant type
  id     *:BindingID
  ct     *:wgpu.BindGroupLayoutEntry
  label  *:str
type BindingShapes * = array[BindingID, BindingShape]
#_____________________________
type Binding * = ref object
  id       *:BindingID
  bufCt    *:wgpu.Buffer
  bufOffs  *:uint64
  bufSize  *:uint64
  sampler  *:wgpu.Sampler
  texView  *:wgpu.TextureView
type Bindings * = array[BindingID, Binding]
#_____________________________
type GroupShape * = ref object
  entries  *:BindingShapes
  id       *:Group
  ct       *:wgpu.BindGroupLayout
  cfg      *:wgpu.BindGroupLayoutDescriptor
  label    *:str
type GroupShapes * = array[Group, GroupShape]  ## Data of all BindGroup Shapes. Used by the PipelineShape
#_____________________________
type BindGroup * = ref object
  entries  *:Bindings
  id       *:Group
  ct       *:wgpu.BindGroup
  cfg      *:wgpu.BindGroupDescriptor
  label    *:str
type BindGroups * = array[Group, BindGroup]   ## Data of all the -real- BindGroups
#__________________
type DataBind * = ref object
  group      *:Group        ## @group(id) where this Uniform is connected to.
  id         *:BindingID    ## @binding(id) where this Uniform is connected to.
  kind       *:BindingKind  ## Will always be `.data` for this object
  shape      *:BindingShape ## Shape of the RenderData connector
  ct         *:Binding      ## RenderData connector context
#__________________
type DataCode * = object
  vName      *:str          ## Name by which the variable will be accessed in shader code.
  tName      *:str          ## Type Name of the variable in wgsl code.
  define     *:str          ## wgsl code for its Type declaration
  variable   *:str          ## wgsl code for its variable definition
#__________________
type RenderData *[T]= ref object
  # note: Called `Uniform` in other libraries. Same concept.
  binding    *:DataBind    ## Binding data of the RenderData object
  code       *:DataCode    ## wgsl Code that is generated to use the RenderData object
  buffer     *:Buffer[T]   ## CPU and GPU data contents.
  label      *:str
type RenderBlock *[T]= distinct RenderData  ## Read+Write version of RenderData
  # note: Called `Shader Storage` in other libraries. Same concept.
#__________________
type Texture * = ref object
  ct       *:wgpu.Texture
  view     *:wgpu.TextureView
  label    *:str
# TODO: TextureBlock  (aka StorageTex)
#__________________
const VertMain * = "vert"  ## Default name for the entry point of the vertex   shader
const FragMain * = "frag"  ## Default name for the entry point of the fragment shader
const CompMain * = "comp"  ## Default name for the entry point of the compute  shader
type  Shader   * = ref object
  ct     *:wgpu.ShaderModule
  cfg    *:wgpu.ShaderModuleDescriptor
  label  *:str
  code   *:str
  file   *:str
#__________________
type VertexShape * = ref object
  ct    *:wgpu.VertexBufferLayout
  attr  *:wgpu.VertexAttribute
type MeshShape * = seq[VertexShape]
#__________________
type PipelineShape * = ref object
  groups   *:GroupShapes
  ct       *:wgpu.PipelineLayout
  cfg      *:wgpu.PipelineLayoutDescriptor
  label    *:str
#__________________
type Pipeline * = ref object
  shader    *:Shader
  meshShape *:MeshShape
  shape     *:PipelineShape
  ct        *:wgpu.RenderPipeline
  cfg       *:wgpu.RenderPipelineDescriptor
  label     *:str


#_______________________________________
# ngpu: Tech Components/Parts
#__________________
when defined(debug):
  const ColorClear *:Color= color(1.0, 0.0, 0.5, 1.0)
else:
  const ColorClear *:Color= color(0.1, 0.1, 0.1, 1.0)
#__________________
type Target *{.pure.}= enum  Color, ColorD, ColorDS
#__________________
type RenderTarget * = ref object
  case kind*:Target
  of Target.Color:    discard
  of Target.ColorD:   depth         *:wgpu.RenderPassDepthStencilAttachment
  of Target.ColorDS:  depthStencil  *:wgpu.RenderPassDepthStencilAttachment
  texture  *:Texture
  color    *:seq[wgpu.RenderPassColorAttachment]
  ct       *:wgpu.RenderPassEncoder
  cfg      *:wgpu.RenderPassDescriptor
  label    *:str
#__________________
type RenderPass * = ref object
  binds    *:BindGroups
  pipeline *:Pipeline
  trg      *:RenderTarget
  label    *:str
#__________________
# TODO
type Phase *{.pure.}= enum Unknown, G, Light, Post
type RenderPhase * = ref object
  kind     *:Phase
  pass     *:seq[RenderPass]
  label    *:str
#__________________
type Tech *{.pure.}= enum Unknown, Clear, Triangle, Simple
type RenderTech * = ref object
  kind     *:Tech
  phase    *:seq[RenderPhase]
  label    *:str


#_______________________________________
# ngpu: wgpu-to-ngpu auto Converters
#__________________
converter toBool *(list :seq[wgpu.Feature]) :bool=  list.len > 0
  ## Automatically converts a list of wgpu.Features to bool when empty.
converter toLimits *(lim :wgpu.Limits) :wgpu.RequiredLimits=  wgpu.RequiredLimits(nextInChain: nil, limits: lim)
  ## Automatically converts wgpu.RequiredLimits into wgpu.Limits

