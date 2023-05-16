#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# ndk dependencies
import nstd/types  as base
import nmath
import vmath
# ngpu dependencies
import ./types        as ngpu
import ./tools/logger as l
from   ./callbacks    as cb import nil
import ./window

#_______________________________________
# Logging
#___________________
proc set *(logLevel :wgpu.LogLevel; logCB :wgpu.LogCallback) :void=
  wgpu.setLogCallback(logCB, nil)
  wgpu.set logLevel


#_______________________________________
# Instance
#___________________
proc new *(_:typedesc[ngpu.Instance];
    label :str= "ngpu | Instance"
  ) :ngpu.Instance=
  new result
  result.label = label
  result.cfg   = wgpu.InstanceDescriptor(nextInChain: nil)
  result.ct    = wgpu.create(result.cfg.addr)
  doAssert result.ct != nil, "Could not initialize the wgpu instance"


#_______________________________________
# Adapter
#___________________
proc info *(adapter :ngpu.Adapter) :void=
  l.info ":: WGPU Features supported by this system: "
  for it in adapter.ct.features(): l.info ":  - ",$it
  l.info ":: Surface Capabilities supported by this system: "
  let (textureFormats, presentModes, alphaModes) = wgpu.capabilities(adapter.surface, adapter.ct)
  l.info ":  Texture Formats:"
  for formt in textureFormats: l.info ":  - ",$formt
  l.info ":  Present Modes:"
  for prsnt in presentModes:   l.info ":  - ",$prsnt
  l.info ":  Alpha Modes:"
  for alpha in alphaModes:     l.info ":  - ",$alpha
#___________________
proc getPreferredFormat *(adapter :ngpu.Adapter) :wgpu.TextureFormat=
  wgpu.getPreferredFormat(adapter.surface, adapter.ct)
#___________________
proc new *(_:typedesc[ngpu.Adapter];
    instance      : ngpu.Instance;
    win           : ngpu.Window;
    power         : PowerPreference             = PowerPreference.highPerformance;
    forceFallback : bool                        = false;
    requestCB     : wgpu.RequestAdapterCallback = cb.adapterRequest;
    report        : bool                        = true;
    label         : str                         = "ngpu | Adapter";
  ) :ngpu.Adapter=
  new result
  # Create the Surface and Adapter
  result.surface = instance.ct.getSurface(win.ct)
  result.cfg     = RequestAdapterOptions(
    nextInChain           : nil,
    compatibleSurface     : result.surface,
    powerPreference       : power,
    forceFallbackAdapter  : forceFallback,
    ) # << RequestAdapterOptions()
  instance.ct.request(result.cfg.addr, requestCB, result.ct.addr)
  # Report Features and Capabilities
  if report: result.info()

#_______________________________________
# Command Buffer
#___________________
proc new *(_:typedesc[ngpu.CommandBuffer];
    encoder : ngpu.CommandEncoder;
    label   : str = "ngpu | CommandBuffer";
  ) :ngpu.CommandBuffer=
  new result
  result.label = label
  result.cfg   = CommandBufferDescriptor(
    nextInChain : nil,
    label       : label,
    ) # << CommandBufferDescriptor
  result.ct = encoder.ct.finish(result.cfg.addr)

#_______________________________________
# Queue
#___________________
proc get *(device :wgpu.Device; _:typedesc[wgpu.Queue]) :wgpu.Queue=  wgpu.getQueue(device)
  ## Gets Queue handle for the given physical device
proc new *(_:typedesc[ngpu.Queue];
    device : ngpu.Device;
  ) :ngpu.Queue=
  new result
  result.ct = device.ct.get(wgpu.Queue)
  # Create a throwaway Buffer and Encoder (will be replaced each frame)
  result.buffer  = new ngpu.CommandBuffer
  result.encoder = new ngpu.CommandEncoder
#___________________
proc submitQueueLabeled *(r :var Renderer; label :str= "ngpu | Command Buffer") :void=
  ## Submits the current state of the Queue to the GPU.
  r.device.queue.buffer = ngpu.CommandBuffer.new(r.device.queue.encoder, label = label)
  r.device.queue.ct.submit(1, r.device.queue.buffer.ct.addr)
proc submitQueue *(r :var Renderer) :void=  r.submitQueueLabeled(r.label&" | Command Buffer")
  ## Submits the current state of the Queue to the GPU.


#_______________________________________
# Device
#___________________
proc new *(_:typedesc[ngpu.Device];
    adapter   : ngpu.Adapter;
    limits    : wgpu.Limits                = Limits.default();
    features  : seq[wgpu.Feature]          = @[];
    queueCfg  : QueueDescriptor            = QueueDescriptor(label: "ngpu | Default Queue");
    errorCB   : wgpu.ErrorCallback         = cb.error;
    requestCB : wgpu.RequestDeviceCallback = cb.deviceRequest;
    lostCB    : wgpu.DeviceLostCallback    = cb.deviceLost;
    label     : str                        = "ngpu | Device";
  ) :ngpu.Device=
  new result
  result.label    = label
  result.limits   = limits
  result.features = features
  result.cfg      = DeviceDescriptor(
    nextInChain           : nil,
    label                 : label,
    requiredFeaturesCount : result.features.len.uint32,
    requiredFeatures      : if features: result.features[0].addr else: nil,
    requiredLimits        : result.limits.addr,
    defaultQueue          : queueCfg,
    ) # << deviceDesc
  adapter.ct.request(result.cfg.addr, requestCB, result.ct.addr)
  # Set the callbacks
  result.ct.set(errorCB, nil)
  result.ct.set(lostCB, nil)
  # Get the device queue
  result.queue = ngpu.Queue.new(result)


#________________________________________________
# Swapchain
#___________________
proc setSize *(swapChain :var ngpu.Swapchain; width,height :SomeInteger) :void=
  ## Updates the size of the given Swapchain config, based on the given width and height.
  swapChain.cfg.width  = uint32 width
  swapChain.cfg.height = uint32 height
proc setSize *(swapChain :var ngpu.Swapchain; win :Window) :void=  swapChain.setSize(win.size.x, win.size.y)
  ## Updates the size of the given Swapchain config, based on the size of the given Window.
proc getView    *(swapChain :ngpu.Swapchain) :wgpu.TextureView=  swapChain.ct.getCurrentTextureView()
  ## Returns the TextureView of the given Swapchain.
proc getSize    *(swapChain :ngpu.Swapchain) :UVec2=  uvec2( swapChain.cfg.width, swapChain.cfg.height )
  ## Returns the current size of the given Swapchain.
#___________________
proc new *(_:typedesc[ngpu.Swapchain];
    win     : var Window;
    adapter : ngpu.Adapter; 
    device  : ngpu.Device;
    alpha   : wgpu.CompositeAlphaMode = CompositeAlphaMode.auto;
    present : wgpu.PresentMode        = PresentMode.fifo;
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
    usage              : {TextureUsage.renderAttachment},  # Other options only useful for reading back the image, etc (eg: compute pipeline)
    format             : adapter.getPreferredFormat(),
    width              : size.x,
    height             : size.y,
    presentMode        : present,
    ) # << SwapchainDescriptor
  let (x,y) = (size.x, size.y)
  l.info &"Initial window size: {x} x {y}"
  result.ct = device.ct.create(adapter.surface, result.cfg.addr)
#___________________
proc updateView *(r :var Renderer; attempts :int= 2) :void=
  ## Returns the current texture view of the Swapchain.
  ## This is a fallible operation by spec, so we attempt multiple times (2x by default when omitted).
  for attempt in 0..<attempts:
    let prev = r.swapChain.getSize()
    let curr = r.win.getSize()
    # Reset the swapchain context if the window was resized
    if prev != curr:
      r.swapChain.setSize(r.win)
      r.swapChain.ct = r.device.ct.create(r.adapter.surface, r.swapChain.cfg.addr)
    r.swapChain.view = r.swapChain.getView()
    if attempt == 0 and r.swapChain.view == nil:
      wrn "swapChain.getCurrentTextureView() failed; attempting to create a new swap chain..."
      r.swapChain.setSize(0,0)
      continue  # Go back for another attempt
    break       # Exit attempts. We are either at the last attempt, or the texture already works
  doAssert r.swapChain.view != nil, "Couldn't acquire next swap chain texture"

#________________________________________________
# Command Encoder
#___________________
proc new *(_:typedesc[ngpu.CommandEncoder];
    device : ngpu.Device;
    label  : str = "ngpu | Command Encoder";
  ) :ngpu.CommandEncoder=
  new result
  result.label = label
  result.cfg   = CommandEncoderDescriptor(
    nextInChain  : nil,
    label        : label,
    ) # << CommandEncoderDescriptor()
  result.ct = device.ct.create(result.cfg.addr)
#___________________
proc update *(encoder :var ngpu.CommandEncoder; device :ngpu.Device) :void=
  ## Updates the given encoder with a new one.
  ## Meant to be called each frame by spec.
  encoder = ngpu.CommandEncoder.new(device, encoder.label)
proc updateEncoder *(r :var Renderer) :void=
  ## Updates the CommandEncoder of the given Renderer with a new one.
  ## Meant to be called each frame by spec.
  r.device.queue.encoder.update(r.device)

#________________________________________________
# Shader
#___________________
proc new *(_:typedesc[Shader];
    device          :ngpu.Device;
    label,code,file :str;
  ) :Shader=
  ## Creates a new Shader with the given data
  new result
  result.label = label
  result.code  = code 
  result.file  = file
  result.cfg   = result.code.wgslToDescriptor(label = result.label)
  result.ct    = device.ct.create(result.cfg.addr)

