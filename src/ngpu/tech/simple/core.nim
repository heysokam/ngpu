#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/types  as base
# ngpu dependencies
import ../../types as ngpu
import ../../core/render
import ../../element/target
import ../../element/window
import ../../element/binding/group
import ../../element/binding/entry
import ../../element/tuples
# Tech dependencies
import ../shared/types as simple
import ../shared/mesh
import ../shared/data
import ../shared/texture
import ./pipeline
import ./shader

# Required exports
export mesh.new
export data.new
export texture.new

#___________________
proc initPass  (render :var Renderer; shader :Shader; shapes :GroupShapes; binds :Bindings) :RenderPass=
  ## Creates the Tech.Simple RenderPass object
  new result
  result.label = render.label&" | Tech.Simple.phase[0].pass[0]"
  result.binds = BindGroups.new(
    global     = ngpu.BindGroup.new(
      shape    = shapes[Group.global],
      entries  = binds,
      device   = render.device,
      label    = result.label&" : BindGroup.global",
      ) # << BindGroup.new( global ... )
    ) # << BindGroups.new( ... )
  result.pipeline = render.device.get(Pipeline,
    shader     = shader,
    shapes     = shapes,
    swapChain  = render.swapChain,
    label      = render.label
    ) # << device.get(Pipeline, ... )
  result.trg = new RenderTarget
#___________________
proc initPhase (render :var Renderer; shader :Shader; shapes :GroupShapes; binds :Bindings) :RenderPhase=
  ## Creates the Tech.Simple RenderPhase object
  new result
  result.label = render.label&" | Tech.Simple.phase[0]"
  result.pass.add render.initPass(shader, shapes, binds)
#___________________
proc init *(render :var Renderer; shader :Shader; shapes :GroupShapes; binds :Bindings) :RenderTech=
  ## Creates the Tech.Simple RenderTech object
  ## This tech is very simple. It only uses a single Pipeline.
  new result
  result.label = render.label&" | Tech.Simple"
  result.kind  = Tech.Simple
  result.phase.add render.initPhase(shader, shapes, binds)
#___________________
proc init *(render :var Renderer; code :str; data :var tuple; initData :bool= true) :RenderTech=
  ## Creates the Tech.Simple RenderTech object, using the given shader code and RenderData tuple.
  ## This tech is very simple. It only uses a single Pipeline.
  if initData:
    data.initBinding(Group.global)
    data.initCode()
  render.init(
    shader = render.device.get(Shader, data.getCode() & code),
    shapes = GroupShapes.new(data, render.device),
    binds  = Bindings.new(data),
    ) # << render.init( ... )
#___________________
proc init *(render :var Renderer; code :str= shaderCode) :RenderTech=
  ## Creates the Tech.Simple RenderTech object, using the default shader when omitted.
  ## This tech is very simple. It only uses a single Pipeline.
  var data :tuple= ()
  render.init(code=code, data=data, initData=false)


#___________________
proc set *(trg :RenderTarget; mesh :RenderMesh) :void=
  ## Sets the Indices and Attributes of the Mesh.buffer in the RenderTarget
  trg.ct.setIndexBuffer(mesh.inds.format, mesh.buffer.ct, mesh.inds.offset,  mesh.inds.size)
  trg.ct.setVertexBuffer(mesh.pos.kind,   mesh.buffer.ct, mesh.pos.offset,   mesh.pos.size)
  trg.ct.setVertexBuffer(mesh.color.kind, mesh.buffer.ct, mesh.color.offset, mesh.color.size)
  trg.ct.setVertexBuffer(mesh.uv.kind,    mesh.buffer.ct, mesh.uv.offset,    mesh.uv.size)
  trg.ct.setVertexBuffer(mesh.norm.kind,  mesh.buffer.ct, mesh.norm.offset,  mesh.norm.size)

#___________________
proc simple *(r :var Renderer; mesh :RenderMesh; tech :var RenderTech) :void=
  ## Executes the RenderPass of Tech.Simple.
  # Create the RenderTarget
  tech.phase[0].pass[0].trg = RenderTarget.new(
    swapChain   = r.swapChain,
    queue       = r.device.queue,
    kind        = Target.ColorD,
    # Including a new depth texture
    depth       = Depth.new(
      device    = r.device,
      swapChain = r.swapChain,
      format    = DefaultDepthFormat,
      label     = r.label&" | RenderTarget : Tech.Simple.phase[0].pass[0].Depth"
      ), # << Depth.new( ... )
    label       = r.label&" | RenderTarget : Tech.Simple.phase[0].pass[0]",
    ) # << RenderTarget.new( ... )
  # Draw into the texture with the given settings
  wgpu.set(
    renderPass = tech.phase[0].pass[0].trg.ct,
    pipeline   = tech.phase[0].pass[0].pipeline.ct,
    ) # << wgpu.renderPass.set(pipeline)
  # Set the attributes of the mesh in the RenderTarget
  tech.phase[0].pass[0].trg.set mesh
  for group in tech.phase[0].pass[0].binds:
    tech.phase[0].pass[0].trg.set group  # Set the `bindGroup` at @group(0), with no dynamic offsets (0, nil)
  wgpu.draw(tech.phase[0].pass[0].trg.ct, mesh.indsCount, 1,0,0,0)  # instanceCount, firstVertex, baseVertex, firstInstance
  # Finish the RenderPass : Clears the swapChain.view, and renders the commands we sent.
  wgpu.End(tech.phase[0].pass[0].trg.ct)
  wgpu.drop(r.swapChain.view)  # Required by wgpu-native. Not standard WebGPU

#___________________
proc draw *(render :var Renderer; mesh :RenderMesh; tech :var RenderTech) :void=
  ## Draws the given mesh using the Pipeline of the given Tech.Simple,
  ## and connecting the given `data` tuple of RenderData for drawing.
  render.win.update()        # Input update from glfw
  render.updateView()        # Update the swapChain's View  (we draw into it each frame)
  render.updateEncoder()     # Create this frame's Command Encoder
  render.simple(mesh, tech)  # Order to draw the mesh with the Tech.Simple and the given data
  render.submitQueue()       # Submit the Rendering Queue
  render.present()           # Present the next swapchain texture on the screen.

