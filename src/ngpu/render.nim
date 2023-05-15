#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/types  as base
import nmath/types as m
from   nglfw       as glfw import nil
# ngpu dependencies
import ./types     as ngpu
import ./elements
import ./window    as w
import ./callbacks as cb

#________________________________________________
# Renderer: Core
#___________________
proc close *(render :Renderer) :bool=  render.win.close()
  ## Checks if the given Renderer has been marked for closing.
proc term *(render :var Renderer) :void=  render.win.term()
  ## Terminate the given Renderer.
proc present *(r :var Renderer) :void=  r.swapChain.ct.present()
  ## Presents the current swapChain texture into the screen.
  ## Similar to gl.swapBuffers()
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
  logLevel.set(logWGPU)  # TODO: set(info, wrn, err, fail)
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
    report        = true,
    ) # << Adapter.new( ... )
  # Create the Device
  result.device = ngpu.Device.new(
    adapter   = result.adapter,
    limits    = Limits.default(),
    features  = features,
    queueCfg  = QueueDescriptor(label: label&" | Default Queue"),
    errorCB   = cb.error,
    requestCB = cb.deviceRequest,
    lostCB    = cb.deviceLost,
    label     = label&" | Device",
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

