#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# General purpose Pipeline creation.               |
# Each Technique must send their specific config.  |
#__________________________________________________|
# External dependencies
import wgpu
# n*dk dependencies
import nstd/types as base
# n*gpu dependencies
import ../types   as ngpu
import ./binding/group


#_______________________________________
proc default *(_:typedesc[PrimitiveState]) :PrimitiveState=
  ## Creates a new PrimitiveState with the default values preferred by the lib.
  result = PrimitiveState(
    nextInChain      : nil,
    topology         : PrimitiveTopology.triangleList,
    stripIndexFormat : IndexFormat.undefined,
    frontFace        : FrontFace.ccw,
    cullMode         : CullMode.none,
    ) # << PrimitiveState( ... )
#_______________________________________
proc default *(_:typedesc[MultisampleState]) :MultisampleState=
  ## Creates a new MultisampleState with the default values preferred by the lib.
  result = MultisampleState(
    nextInChain            : nil,
    count                  : 1,
    mask                   : uint32.high,
    alphaToCoverageEnabled : false,
    ) # << MultisampleState( ... )
#_______________________________________
proc default *(_:typedesc[BlendComponent]) :BlendComponent=
  ## Creates a new BlendComponent with the default values preferred by the lib.
  result = BlendComponent(
    operation : BlendOperation.Add,
    srcFactor : BlendFactor.one,
    dstFactor : BlendFactor.zero,
    ) # << BlendComponent( ... )
#_______________________________________
proc default *(_:typedesc[StencilFaceState]) :StencilFaceState=
  ## Creates a new StencilFaceState with the default values preferred by the lib.
  result = StencilFaceState(
    compare     : CompareFunction.always, # This would be CompareFunction.undefined when Zero-Initalizated
    failOp      : StencilOperation.keep,
    depthFailOp : StencilOperation.keep,
    passOp      : StencilOperation.keep,
    ) # << StencilFaceState( ... )
#_______________________________________
proc depth *(
    compare : CompareFunction = DefaultDepthCompare;
    format  : TextureFormat   = DefaultDepthFormat;
  ) :DepthStencilState=
  ## Creates a new depth shape with no-stencil.
  ## Will use their default values when omitted (stored at types.nim).
  result = DepthStencilState(
    nextInChain            : nil,
    format                 : format,   # Assign the depth format to the pipeline
    depthWriteEnabled      : true,     # If fragment passes the test, its depth is stored as the new value
    depthCompare           : compare,  # Blend fragment if its depth is less/more than the current value of the z-buffer
    # Not Used. Could be Zero-Initalizated instead of explicit.
    stencilFront           : StencilFaceState.default(),
    stencilBack            : StencilFaceState.default(),
    stencilReadMask        : 0,  # Stencil disabled
    stencilWriteMask       : 0,  # Stencil disabled
    depthBias              : 0,
    depthBiasSlopeScale    : 0.cfloat,
    depthBiasClamp         : 0.cfloat,
    ) # << depthStencil

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

