#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ngpu dependencies
import ../../types as ngpu
import ../../element/target
import ../../element/window
import ../../core/render
# Tech dependencies
import ../shared/types as simple
import ../shared/mesh
import ./pipeline
import ./shader

# Required exports
export mesh.new

#___________________
proc initPass  (render :var Renderer; shader :Shader) :RenderPass=
  ## Creates the Tech.Simple RenderPass object
  new result
  result.label    = render.label&" | Tech.Simple.phase[0].pass[0]"
  result.pipeline = render.device.get(Pipeline, shader, render.swapChain, render.label)
  result.trg      = new RenderTarget
#___________________
proc initPhase (render :var Renderer; shader :Shader) :RenderPhase=
  ## Creates the Tech.Simple RenderPhase object
  new result
  result.label = render.label&" | Tech.Simple.phase[0]"
  result.pass.add render.initPass(shader)
#___________________
proc init *(render :var Renderer; shader :Shader) :RenderTech=
  ## Creates the Tech.Simple RenderTech object
  ## This tech is very simple. It only uses a single Pipeline.
  new result
  result.label = render.label&" | Tech.Simple"
  result.kind  = Tech.Simple
  result.phase.add render.initPhase(shader)
#___________________
proc init *(render :var Renderer) :RenderTech=
  ## Creates the Tech.Simple RenderTech object, using the default shader.
  ## This tech is very simple. It only uses a single Pipeline.
  render.init(shader = render.device.get(Shader))


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
    swapChain = r.swapChain,
    queue     = r.device.queue,  )
  # Draw into the texture with the given settings
  wgpu.set(
    renderPass = tech.phase[0].pass[0].trg.ct,
    pipeline   = tech.phase[0].pass[0].pipeline.ct,
    ) # << wgpu.renderPass.set(pipeline)
  # Set the attributes of the mesh in the RenderTarget
  tech.phase[0].pass[0].trg.set mesh
  wgpu.draw(tech.phase[0].pass[0].trg.ct, mesh.indsCount, 1,0,0)  # instanceCount, firstVertex, firstInstance
  # Finish the RenderPass : Clears the swapChain.view, and renders the commands we sent.
  wgpu.End(tech.phase[0].pass[0].trg.ct)
  wgpu.drop(r.swapChain.view)  # Required by wgpu-native. Not standard WebGPU

#___________________
proc draw *(render :var Renderer; mesh :RenderMesh; tech :var RenderTech) :void=
  ## Draws the Tech.Simple, using the Pipeline initialized with triangle.init()
  render.win.update()       # Input update from glfw
  render.updateView()       # Update the swapChain's View  (we draw into it each frame)
  render.updateEncoder()    # Create this frame's Command Encoder
  render.simple(mesh, tech) # Order to draw the Tech.Simple with the given Pipeline
  render.submitQueue()      # Submit the Rendering Queue
  render.present()          # Present the next swapchain texture on the screen.

