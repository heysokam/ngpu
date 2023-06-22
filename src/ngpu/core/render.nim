#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/types         as base
import nmath/types        as m
from   nglfw              as glfw import nil
# ngpu dependencies
import ../types           as ngpu
import ../elements
import ../element/window  as w
import ../element/buffer  as buf
import ../element/texture as tex
import ../callbacks       as cb
import ../tool/logger     as l
import ../element/log     as lg


#___________________
proc close *(render :Renderer) :bool=  render.win.close()
  ## Checks if the given Renderer has been marked for closing.
proc term *(render :var Renderer) :void=  render.win.term()
  ## Terminate the given Renderer.
proc present *(r :var Renderer) :void=  r.swapChain.ct.present()
  ## Presents the current swapChain texture into the screen.
  ## Similar to gl.swapBuffers()

#___________________
proc updateView *(r :var Renderer; attempts :int= 2) :void=
  ## Updates the texture view of the given Swapchain, based on the current window size.
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
#___________________
proc updateEncoder *(r :var Renderer) :void=
  ## Updates the CommandEncoder of the given Renderer with a new one.
  ## Meant to be called each frame by spec.
  ## Must happen before the Queue is submitted.
  r.device.queue.encoder.update(r.device)

#___________________
proc submitQueueLabeled *(r :var Renderer; label :str= "ngpu | Command Buffer") :void=
  ## Submits the current state of the Queue to the GPU.
  r.device.queue.buffer = ngpu.CommandBuffer.new(r.device.queue.encoder, label = label)
  r.device.queue.ct.submit(1, r.device.queue.buffer.ct.addr)
proc submitQueue *(r :var Renderer) :void=  r.submitQueueLabeled(r.label&" | Command Buffer")
  ## Submits the current state of the Queue to the GPU.

#___________________
proc upload *[T](render :Renderer; trg :RenderData[T]) :void=
  ## Queues an upload operation to copy the data currently contained in the buffer of the given RenderData object into the GPU.
  render.device.upload(trg.buffer)
proc upload *(render :Renderer; trg :TexData | ngpu.Texture) :void=
  ## Queues an upload operation to copy the current image of the given TexData or Texture object into the GPU.
  render.device.upload(trg)

#___________________
proc update *[T](render :Renderer; trg :var RenderData[T]; data :T) :void=
  ## Updates the given `trg` RenderData with the given input `data`.
  ## Queues an upload operation to send the data to the GPU.
  trg.buffer.data = data
  render.upload(trg)
#___________________
proc update *(render :Renderer; trg :var TexData; img :Image) :void=
  ## Updates the given `trg` TexData with the given input `img`.
  ## Queues an upload operation to send the image to the GPU.
  trg.img = img
  render.upload(trg)


#___________________
proc new *(_:typedesc[Renderer];
    res            : UVec2;
    title          : str                         = "ngpu | Renderer";
    label          : str                         = "ngpu";
    resizable      : bool                        = true;
    resize         : glfw.FrameBufferSizeFun     = nil;
    key            : glfw.KeyFun                 = nil;
    mousePos       : glfw.CursorPosFun           = nil;
    mouseBtn       : glfw.MouseButtonFun         = nil;
    mouseScroll    : glfw.ScrollFun              = nil;
    error          : glfw.ErrorFun               = w.error;
    errorWGPU      : wgpu.ErrorCallback          = cb.error;
    logWGPU        : wgpu.LogCallback            = cb.log;
    logLevel       : wgpu.LogLevel               = wgpu.LogLevel.warn;
    report         : bool                        = true;
    features       : seq[wgpu.Feature]           = @[];
    lost           : wgpu.DeviceLostCallback     = cb.deviceLost;
    power          : wgpu.PowerPreference        = PowerPreference.highPerformance;
    forceFallback  : bool                        = false;
    requestAdapter : wgpu.RequestAdapterCallback = cb.adapterRequest;
    requestDevice  : wgpu.RequestDeviceCallback  = cb.deviceRequest;
  ) :Renderer=
  ## Initializes and returns an ngpu Renderer
  ## 1. Creates a window with GLFW
  ## 2. Initializes all wgpu objects required by ngpu
  new result
  result.label = label
  #__________________
  # Init Window
  result.win = Window.new(res, title, resizable, resize, key, mousePos, mouseBtn, mouseScroll, error)
  #__________________
  # Set wgpu.Logging
  lg.set(logLevel, logWGPU)  # TODO: set(info, wrn, err, fail)
  #__________________
  # Init wgpu
  # Create the Instance
  result.instance = ngpu.Instance.new(label = label&" | Instance")
  # Create the Surface and Adapter
  result.adapter = ngpu.Adapter.new(
    label         = label&" | Adapter",
    instance      = result.instance,
    win           = result.win,
    power         = power,
    forceFallback = forceFallback,
    requestCB     = requestAdapter,
    report        = report,
    ) # << Adapter.new( ... )
  # Create the Device
  result.device = ngpu.Device.new(
    adapter    = result.adapter,
    limits     = Limits.default(),
    features   = features,
    errorCB    = cb.error,
    requestCB  = cb.deviceRequest,
    report     = report,
    lostCB     = cb.deviceLost,
    queueLabel = label&" | Default Queue",
    label      = label&" | Device",
    ) # << Device.new( ... )
  # Create the Swapchain
  result.swapchain = ngpu.Swapchain.new(
    win     = result.win,
    adapter = result.adapter,
    device  = result.device,
    alpha   = CompositeAlphaMode.auto,
    present = PresentMode.fifo,
    label   = label&" | Swapchain",
    ) # << Swapchain.new( ... )

