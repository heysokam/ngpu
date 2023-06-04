#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# General purpose Pipeline creation.               |
# Each Technique must send their specific config.  |
#__________________________________________________|
# External dependencies
import wgpu
# ndk dependencies
import nstd/types as base
# ngpu dependencies
import ../types   as ngpu
import ./binding/group


#_______________________________________
proc default *(_:typedesc[PrimitiveState]) :PrimitiveState=
  result = PrimitiveState(
    nextInChain      : nil,
    topology         : PrimitiveTopology.triangleList,
    stripIndexFormat : IndexFormat.undefined,
    frontFace        : FrontFace.ccw,
    cullMode         : CullMode.none,
    ) # << primitive
#_______________________________________
proc default *(_:typedesc[MultisampleState]) :MultisampleState=
  result = MultisampleState(
    nextInChain            : nil,
    count                  : 1,
    mask                   : uint32.high,
    alphaToCoverageEnabled : false,
    ) # << multisample
#_______________________________________
proc default *(_:typedesc[BlendComponent]) :BlendComponent=
  result = BlendComponent(
    operation : BlendOperation.Add,
    srcFactor : BlendFactor.one,
    dstFactor : BlendFactor.zero,
    ) # << BlendComponent()

#_______________________________________
proc new *(_:typedesc[PipelineShape];
    device : ngpu.Device;
    shapes : GroupShapes= GroupShapes.default();
    label  : str = "ngpu | PipelineShape";
  ) :PipelineShape=
  new result
  result.label    = label
  result.groups   = shapes
  var groupShapes = result.groups.toWgpu
  result.cfg      = PipelineLayoutDescriptor(
    nextInChain          : nil,
    label                : result.label.cstring,
    bindGroupLayoutCount : groupShapes.len.uint32,
    bindGroupLayouts     : if groupShapes.len > 0: groupShapes[0].addr else: nil,
    ) # << device.createPipelineShape()
  result.ct = device.ct.create(result.cfg.addr)

#_______________________________________
proc new *(_:typedesc[Pipeline];
    shape        : PipelineShape;
    device       : ngpu.Device;
    shader       : Shader;
    meshShape    : MeshShape;
    vertex       : VertexState;
    fragment     : ptr FragmentState;
    primitive    : PrimitiveState        = PrimitiveState.default();
    multisample  : MultisampleState      = MultisampleState.default();
    depthStencil : ptr DepthStencilState = nil;
    label        : str                   = "ngpu | Pipeline";
  ) :Pipeline=
  new result
  result.label     = label
  result.shape     = shape
  result.meshShape = meshShape
  result.shader    = shader
  result.cfg       = RenderPipelineDescriptor(
    nextInChain  : nil,
    label        : result.label.cstring,
    layout       : result.shape.ct,
    vertex       : vertex,
    primitive    : primitive,
    depthStencil : depthStencil,
    multisample  : multisample,
    fragment     : fragment,
    ) # << RenderPipelineDescriptor( ... )
  result.ct = device.ct.create(result.cfg.addr)

