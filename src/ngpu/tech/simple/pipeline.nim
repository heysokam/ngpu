#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd
# ngpu dependencies
import ../../types as ngpu
# Tech dependencies
import ../shared/types as simple
import ../shared/mesh


#___________________
proc new *(_:typedesc[ngpu.PipelineLayout];
    device    : ngpu.Device;
    label     : str= "ngpu | Pipeline Layout";
  ) :ngpu.PipelineLayout=
  ## Creates a new PipelineLayout for the Simple Technique, without any BindGroups.
  new result
  result.label = label
  result.cfg   = PipelineLayoutDescriptor(
    nextInChain          : nil,
    label                : result.label.cstring,
    bindGroupLayoutCount : 0,
    bindGroupLayouts     : nil,
    ) # << PipelineLayoutDescriptor()
  result.ct = device.ct.create(result.cfg.addr)

#___________________
proc get *(device :ngpu.Device;
    _         : typedesc[Pipeline];
    shader    : Shader;
    swapChain : ngpu.Swapchain;
    label     : str= "ngpu | Tech.Simple Pipeline";
  ) :Pipeline=
  ## Creates the Pipeline of the Simple Technique.
  new result
  result.label     = label
  # Configure the pipeline with the given shader, and this Technique's mesh buffer shape
  result.meshShape = Mesh.new(MeshShape)
  var vlayout      = VertexBufferLayout.new(result.meshShape)
  # for it in result.meshShape.inner:  vlayout.add it.ct
  result.shader    = shader
  result.layout    = ngpu.PipelineLayout.new(device, label = result.label&" Layout")
  result.cfg       = RenderPipelineDescriptor(
    nextInChain               : nil,
    label                     : result.label.cstring,
    layout                    : result.layout.ct,
    vertex                    : VertexState(
      module                  : shader.ct,
      entryPoint              : VertMain,
      constantCount           : 0,
      constants               : nil,
      bufferCount             : vlayout.len.uint32,
      buffers                 : vlayout[0].addr,
      ), # << vertex
    primitive                 : PrimitiveState(
      nextInChain             : nil,
      topology                : PrimitiveTopology.triangleList,
      stripIndexFormat        : IndexFormat.undefined,
      frontFace               : FrontFace.ccw,
      cullMode                : CullMode.none,
      ), # << primitive
    depthStencil              : nil,
    multisample               : MultisampleState(
      nextInChain             : nil,
      count                   : 1,
      mask                    : uint32.high,
      alphaToCoverageEnabled  : false,
      ), # << multisample
    fragment                  : vaddr FragmentState(
      nextInChain             : nil,
      module                  : shader.ct,
      entryPoint              : FragMain,
      constantCount           : 0,
      constants               : nil,
      targetCount             : 1,
      targets                 : vaddr ColorTargetState(
        nextInChain           : nil,
        format                : swapChain.cfg.format,
        blend                 : vaddr BlendState(
          alpha               : BlendComponent(
            operation         : BlendOperation.Add,
            srcFactor         : BlendFactor.one,
            dstFactor         : BlendFactor.zero,
            ), # << alpha
          color               : BlendComponent(
            operation         : BlendOperation.Add,
            srcFactor         : BlendFactor.one,
            dstFactor         : BlendFactor.zero,
            ), # << color
          ), # << blend
        writeMask             : ColorWriteMask.all,
        ), # << targets
      ), # << fragment
    ) # << RenderPipelineDescriptor
  result.ct = device.ct.create(result.cfg.addr)

