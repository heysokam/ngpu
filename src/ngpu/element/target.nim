#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# ndk dependencies
import nstd/types    as base
# ngpu dependencies
import ../types      as ngpu
import ../tool/color as c


#_____________________________
proc new *(_:typedesc[Depth | DepthStencil];
    device    : ngpu.Device;
    swapChain : ngpu.Swapchain;
    format    : wgpu.TextureFormat = DefaultDepthFormat;
    label     : str                = "ngpu | Depth Texture"
  ) :Depth=
  # Create the depth texture
  result.label  = label
  result.format = format
  result.cfg    = TextureDescriptor(
    nextInChain          : nil,
    label                : result.label.cstring,
    usage                : { TextureUsage.renderAttachment },
    dimension            : TextureDimension.dim2D,
    size                 : Extent3D(
      width              : swapChain.cfg.width,
      height             : swapChain.cfg.height,
      depthOrArrayLayers : 1,
      ), # << size
    format               : result.format,
    mipLevelCount        : 1,  # TODO: Generate mips
    sampleCount          : 1,
    viewFormatCount      : 1,
    viewFormats          : result.format.addr,
    ) # << TextureDescriptor( ... )
  result.tex = device.ct.create(result.cfg.addr) # << device.createTexture()
  # Create the depth texture view
  result.viewCfg = TextureViewDescriptor(
    nextInChain     : nil,
    label           : cstring( result.label&" View" ),
    format          : result.format,
    dimension       : TextureViewDimension.dim2D,
    baseMipLevel    : 0,
    mipLevelCount   : result.cfg.mipLevelCount,
    baseArrayLayer  : 0,
    arrayLayerCount : 1,
    aspect          : TextureAspect.depthOnly,
    ) # << TextureViewDescriptor( ... )
  result.view = result.tex.create(result.viewCfg.addr)  # << depthTexture.createView()
  # Create the depth attachment
  result.ct = RenderPassDepthStencilAttachment(
    view              : result.view,    # Attach the depth view
    depthLoadOp       : LoadOp.clear,   # Similar to the color attachment
    depthStoreOp      : StoreOp.store,  # Similar to the color attachment
    depthClearValue   : 1.float32,      # Initial value of the depth buffer (far)   # TODO: Reverse Depth
    depthReadOnly     : false,          # Optional: true means disable depth write
    # Stencil disabled
    stencilLoadOp     : LoadOp.clear,
    stencilStoreOp    : StoreOp.store,
    stencilClearValue : 0,
    stencilReadOnly   : true,
    ) # << RenderPassDepthStencilAttachment( ... )
#_____________________________
proc drop *(depth :Depth) :void=
  ## Drops the texture and view of the given Depth object.
  wgpu.drop( depth.tex )
  wgpu.drop( depth.view )


#_____________________________
proc new *(_:typedesc[RenderTarget];
    swapChain : ngpu.Swapchain;
    queue     : ngpu.Queue;
    kind      : Target     = Target.Color;
    clear     : ngpu.Color = ColorClear;
    depth     : Depth      = Depth();
    label     : str        = "ngpu | RenderTarget";
  ) :RenderTarget=
  ## Creates a RenderTarget with a single Color attachment
  if depth == Depth() and kind != Target.Color:
    raise newException(InitError, &"Tried to initialize a {$kind} RenderTarget, with an empty depth input.")
  result       = RenderTarget(kind: kind)
  result.label = label
  result.color = @[RenderPassColorAttachment(
    view                   : swapChain.view,
    resolveTarget          : nil,
    loadOp                 : LoadOp.clear,
    storeOp                : StoreOp.store,
    clearValue             : clear,  # Autoconverts to WGPU.Color
    )] # << colorAttachments
  # Create the depth attachment when needed.
  case result.kind
  of Target.Color          : discard
  of Target.ColorD         : result.depth        = depth
  of Target.ColorDS        : result.depthStencil = depth
  # Create the RenderTarget
  result.cfg = RenderPassDescriptor(
    nextInChain            : nil,
    label                  : result.label.cstring,
    colorAttachmentCount   : result.color.len.uint32,
    colorAttachments       : result.color[0].addr,
    depthStencilAttachment : case result.kind
      of Target.Color      : nil
      of Target.ColorD     :
        if result.depth == Depth(): nil
        else: result.depth.ct.addr
      of Target.ColorDS    :
        if result.depthStencil == DepthStencil(): nil
        else: result.depthStencil.ct.addr,
    occlusionQuerySet      : nil,
    timestampWriteCount    : 0,
    timestampWrites        : nil,
    ) # << renderTarget.cfg  (remember: ngpu.RenderTarget == wgpu.RenderPass)
  result.ct = wgpu.begin(
    commandEncoder = queue.encoder.ct,
    descriptor     = result.cfg.addr,
    ) # << wgpu.beginRenderPass

