#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ngpu dependencies
import ../types      as ngpu
import ../tool/color as c


#_____________________________
proc new *(_:typedesc[RenderTarget];
    swapChain : ngpu.Swapchain;
    queue     : ngpu.Queue;
    clear     : ngpu.Color = ColorClear;
  ) :RenderTarget=
  ## Creates a RenderTarget with a single Color attachment
  result       = RenderTarget(kind: Target.Color)
  result.color = @[RenderPassColorAttachment(
    view                   : swapChain.view,
    resolveTarget          : nil,
    loadOp                 : LoadOp.clear,
    storeOp                : StoreOp.store,
    clearValue             : clear,  # Autoconverts to WGPU.Color
    )] # << colorAttachments
  # Create the RenderTarget
  result.cfg = RenderPassDescriptor(
    nextInChain            : nil,
    label                  : nil,
    colorAttachmentCount   : result.color.len.uint32,
    colorAttachments       : result.color[0].addr,
    depthStencilAttachment : nil,
    occlusionQuerySet      : nil,
    timestampWriteCount    : 0,
    timestampWrites        : nil,
    ) # << renderTarget.cfg  (remember: ngpu.RenderTarget == wgpu.RenderPass)
  result.ct = wgpu.begin(
    commandEncoder = queue.encoder.ct,
    descriptor     = result.cfg.addr,
    ) # << wgpu.beginRenderPass

