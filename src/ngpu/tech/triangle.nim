#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# ndk dependencies
import nstd
# ngpu dependencies
import ../types as ngpu
import ../elements
import ../tool/color
import ../core/render

#___________________
# Triangle shader
const shaderCode = """
@vertex fn vert(
    @builtin(vertex_index) aID :u32
  ) ->@builtin(position) vec4<f32> {
  let x = f32(i32(aID) - 1);
  let y = f32(i32(aID & 1u) * 2 - 1);
  return vec4<f32>(x, y, 0.0, 1.0);
}

@fragment fn frag() ->@location(0) vec4<f32> {
  return vec4<f32>(1.0, 0.0, 0.0, 1.0);
}
"""

#___________________
proc get (device :ngpu.Device;
    _      : typedesc[Shader];
    label  : str = "ngpu";
  ) :Shader=
  ## Creates the Shader of the Triangle Technique.
  result = Shader.new(
    device = device,
    label  = label&" | Tech.Triangle Shader",
    code   = shaderCode,
    file   = NoFile,    )

#___________________
proc get (device :ngpu.Device;
    _         : typedesc[Pipeline];
    swapChain : ngpu.Swapchain;
    label     : str = "ngpu";
  ) :Pipeline=
  ## Creates the Pipeline of the Triangle Technique.
  new result
  result.shader = device.get(Shader, label)
  result.label  = label&" | Tech.Triangle Pipeline"
  result.cfg    = RenderPipelineDescriptor(
    nextInChain               : nil,
    label                     : result.label.cstring,
    layout                    : nil,
    vertex                    : VertexState(
      module                  : result.shader.ct,
      entryPoint              : VertMain,
      constantCount           : 0,
      constants               : nil,
      bufferCount             : 0,
      buffers                 : nil,
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
      module                  : result.shader.ct,
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
    ) # << pipeline.cfg
  result.ct = device.ct.create(result.cfg.addr)
#___________________
proc initPass  (render :var Renderer) :RenderPass=
  ## Creates the Tech.Triangle RenderPass object
  new result
  result.label    = render.label&" | Tech.Triangle.phase[0].pass[0]"
  result.pipeline = render.device.get(Pipeline, render.swapChain, render.label)
  result.trg      = new RenderTarget
#___________________
proc initPhase (render :var Renderer) :RenderPhase=
  ## Creates the Tech.Triangle RenderPhase object
  new result
  result.label = render.label&" | Tech.Triangle.phase[0]"
  result.pass.add render.initPass()
#___________________
proc init *(render :var Renderer) :RenderTech=
  ## Creates the Tech.Triangle RenderTech object
  ## This tech is very simple. It only uses a single Pipeline.
  new result
  result.label = render.label&" | Tech.Triangle"
  result.kind  = Tech.Triangle
  result.phase.add render.initPhase()

#___________________
proc triangle *(r :var Renderer; tech :var RenderTech) :void=
  ## Orders wgpu to execute the triangle RenderPass.
  # Create the RenderTarget attachments
  var colors = @[RenderPassColorAttachment(
    view                  : r.swapChain.view,
    resolveTarget         : nil,
    loadOp                : LoadOp.clear,
    storeOp               : StoreOp.store,
    clearValue            : color(0.2, 0.2, 0.2, 1.0),  # Autoconverts to WGPU.Color
    )] # << colorAttachments
  # Create the RenderTarget
  tech.phase[0].pass[0].trg.cfg = RenderPassDescriptor(
    nextInChain             : nil,
    label                   : nil,
    colorAttachmentCount    : colors.len.uint32,
    colorAttachments        : colors[0].addr,
    depthStencilAttachment  : nil,
    occlusionQuerySet       : nil,
    timestampWriteCount     : 0,
    timestampWrites         : nil,
    ) # << renderTarget.cfg  (remember: ngpu.RenderTarget == wgpu.RenderPass)
  tech.phase[0].pass[0].trg.ct = wgpu.begin(
    commandEncoder = r.device.queue.encoder.ct,
    descriptor     = tech.phase[0].pass[0].trg.cfg.addr,
    ) # << wgpu.beginRenderPass
  # Draw into the texture with the given settings
  wgpu.set(
    renderPass = tech.phase[0].pass[0].trg.ct,
    pipeline   = tech.phase[0].pass[0].pipeline.ct,
    ) # << wgpu.renderPass.set(pipeline)
  wgpu.draw(tech.phase[0].pass[0].trg.ct, 3, 1,0,0)  # vertexCount, instanceCount, firstVertex, firstInstance
  # Finish the RenderPass : Clears the swapChain.view, and renders the commands we sent.
  wgpu.End(tech.phase[0].pass[0].trg.ct)
  wgpu.drop(r.swapChain.view)  # Required by wgpu-native. Not standard WebGPU

#___________________
proc draw *(render :var Renderer; tech :var RenderTech) :void=
  ## Draws the Tech.Triangle, using the Pipeline initialized with triangle.init()
  render.win.update()    # Input update from glfw
  render.updateView()    # Update the swapChain's View  (we draw into it each frame)
  render.updateEncoder() # Create this frame's Command Encoder
  render.triangle(tech)  # Order to draw the Tech.Triangle with the given Pipeline
  render.submitQueue()   # Submit the Rendering Queue
  render.present()       # Present the next swapchain texture on the screen.

