#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# n*dk dependencies
import nstd
# n*gpu dependencies
import ../../types as ngpu
import ../../element/pipeline
# Tech dependencies
import ../shared/types as simple
import ../shared/mesh


#_______________________________________
# RenderData: Register
#___________________
proc register *[T](tech :var RenderTech; data :var RenderData[T]; group :Group = Group.global) :void=
  ## Registers the given RenderData object into the pass of the given Simple.RenderTech.
  discard #TODO


#___________________
proc get *(device :ngpu.Device;
    _          : typedesc[Pipeline];
    shader     : Shader;
    shapes     : GroupShapes;
    swapChain  : ngpu.Swapchain;
    label      : str= "ngpu | Tech.Simple Pipeline";
  ) :Pipeline=
  var meshShape    = Mesh.new(MeshShape)
  var vlayout      = VertexShape.new(meshShape)
  var depthStencil = pipeline.depth()
  result           = Pipeline.new(
    shape           = PipelineShape.new(
      device        = device,
      label         = label&" Shape",
      shapes        = shapes,
      ), # << PipelineShape.new( ... )
    device          = device,
    shader          = shader,
    meshShape       = meshShape,
    vertex          = VertexState(
      module        : shader.ct,
      entryPoint    : VertMain,
      constantCount : 0,
      constants     : nil,
      bufferCount   : vlayout.len.uint32,
      buffers       : vlayout[0].addr,
      ), # << vertex
    fragment        = vaddr FragmentState(
      nextInChain   : nil,
      module        : shader.ct,
      entryPoint    : FragMain,
      constantCount : 0,
      constants     : nil,
      targetCount   : 1,
      targets       : vaddr ColorTargetState(
        nextInChain : nil,
        format      : swapChain.cfg.format,
        blend       : vaddr BlendState(
          alpha     : BlendComponent.default(),
          color     : BlendComponent.default(),
          ), # << blend
        writeMask   : ColorWriteMask.all,
        ), # << targets
      ), # << fragment
    primitive    = PrimitiveState.default(),
    multisample  = MultisampleState.default(),
    depthStencil = depthStencil.addr,
    label        = label,
    ) # << Pipeline.new( ... )

