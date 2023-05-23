#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# ndk dependencies
import nstd
import nmath
# ngpu dependencies
import ../types       as ngpu
import ../tool/logger as l
import ./adapter
import ./window


#________________________________________________
# Swapchain
#___________________
proc setSize *(swapChain :var ngpu.Swapchain; width,height :SomeInteger) :void=
  ## Updates the size of the given Swapchain config, based on the given width and height.
  swapChain.cfg.width  = uint32 width
  swapChain.cfg.height = uint32 height
proc setSize *(swapChain :var ngpu.Swapchain; win :Window) :void=  swapChain.setSize(win.size.x, win.size.y)
  ## Updates the size of the given Swapchain config, based on the size of the given Window.
proc getSize *(swapChain :ngpu.Swapchain) :UVec2=  uvec2( swapChain.cfg.width, swapChain.cfg.height )
  ## Returns the current size of the given Swapchain.
#___________________
proc getView *(swapChain :ngpu.Swapchain) :wgpu.TextureView=  swapChain.ct.getCurrentTextureView()
  ## Returns the TextureView of the given Swapchain.

#___________________
proc new *(_:typedesc[ngpu.Swapchain];
    win     : var Window;
    adapter : ngpu.Adapter;
    device  : ngpu.Device;
    alpha   : wgpu.CompositeAlphaMode = CompositeAlphaMode.auto;
    present : wgpu.PresentMode        = PresentMode.fifo;
    usage   : wgpu.TextureUsageFlags  = {TextureUsage.renderAttachment};  # Other options only useful for reading back the image, etc (eg: compute pipeline)
    label   : str                     = "ngpu | Swapchain";
  ) :ngpu.Swapchain=
  new result
  let size     = win.getSize()
  result.label = label
  result.cfg   = SwapchainDescriptor(
    nextInChain        : cast[ptr ChainedStruct](vaddr SwapchainDescriptorExtras(
      chain            : ChainedStruct(
        next           : nil,
        sType          : SType.swapChainDescriptorExtras,
        ), # << chain
      alphaMode        : alpha,  # For window compositing alpha
      # Only useful for changing the format of the texture view
      viewFormatCount  : 0,
      viewFormats      : nil,
      )), # << nextInChain (wgpu Extension)
    label              : result.label.cstring,
    usage              : usage,
    format             : adapter.getPreferredFormat(),
    width              : size.x,
    height             : size.y,
    presentMode        : present,
    ) # << SwapchainDescriptor
  let (x,y) = (size.x, size.y)
  l.info &"Initial window size: {x} x {y}"
  result.ct = device.ct.create(adapter.surface, result.cfg.addr)

