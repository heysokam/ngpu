#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# n*dk dependencies
import nstd
import nsys
# n*gpu dependencies
import ../types as ngpu
import ../tool/color
import ../elements
import ../core/render

#_______________________________________
proc clear *(r :var Renderer; color :ngpu.Color) :void=
  ## Orders wgpu to execute a simple drawClear RenderPass.
  # Create the RenderPass
  var renderPass = r.device.queue.encoder.ct.begin(vaddr RenderPassDescriptor(
    nextInChain             : nil,
    label                   : cstring( r.label&" | RenderPass.Clear" ),
    colorAttachmentCount    : 1,
    colorAttachments        : vaddr RenderPassColorAttachment(
      view                  : r.swapChain.view,
      resolveTarget         : nil,
      loadOp                : LoadOp.clear,
      storeOp               : StoreOp.store,
      clearValue            : color,  # Autoconverts to wgpu.Color
      ), # << colorAttachments
    depthStencilAttachment  : nil,
    occlusionQuerySet       : nil,
    timestampWriteCount     : 0,
    timestampWrites         : nil,
    )) # << encoder.begin(RenderPass)
  # Finish the RenderPass : This will clear the swapChain.view with the color we gave.
  wgpu.End(renderPass)
  wgpu.release(r.swapChain.view)

#_______________________________________
proc draw *(render :var Renderer) :void=
  ## Executes everything needed to draw the Clear RenderTech.
  render.sys.update()                       # Input update from glfw
  render.updateView()                       # Update the swapChain's View  (we draw into it each frame)
  render.updateEncoder()                    # Create this frame's Command Encoder
  render.clear( color(1.0, 0.0, 0.0, 1.0) ) # Order to draw a simple window clearing RenderPass
  render.submitQueue()                      # Submit the Rendering Queue
  render.present()                          # Present the next swapchain texture on the screen.

