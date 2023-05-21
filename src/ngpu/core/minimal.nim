#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/types   as base
# ngpu dependencies
import ../types     as ngpu
import ../elements
from   ../callbacks as cb import nil


#_______________________________________
# Logging
#___________________
export elements.ngpuLog.initLog


#_______________________________________
# Queue
#___________________
proc updateEncoder *(core :var Minimal) :void=
  ## Updates the CommandEncoder of the given Minimal core with a new one.
  ## Meant to be called each frame by spec.
  ## Must happen before the Queue is submitted.
  core.device.queue.encoder.update(core.device)

#___________________
proc submitQueueLabeled *(core :var Minimal; label :str= "ngpu | Command Buffer Minimal") :void=
  ## Submits the current state of the Queue to the GPU.
  ## Allows specifying a label for the Command Buffer.
  core.device.queue.buffer = ngpu.CommandBuffer.new(core.device.queue.encoder, label = label)
  core.device.queue.ct.submit(1, core.device.queue.buffer.ct.addr)
#___________________
proc submitQueue *(core :var Minimal) :void=  core.submitQueueLabeled(core.label&" | Command Buffer Minimal")
  ## Submits the current state of the Queue to the GPU.

#___________________
proc sync *(core :var Minimal) :bool {.discardable.}=  core.device.sync()
  ## Waits for the device to be done with all operations in its Queue (resource cleanups and mapping callbacks).
  ## Returns a (discardable) bool:
  ## - true  : the queue is empty
  ## - false : There are more queue submissions still in flight.
  ## Note: Unless access to the Queue is coordinated somehow,
  ##       this information could be out of date by the time the caller receives it.
  ##       Queues can be shared between threads, so other threads could submit new work at any time.
  ## Web:  No-Op. Devices are automatically polled.

#_______________________________________
# Construct
#___________________
proc new *(_:typedesc[Minimal];
    label          : str                         = "ngpu";
    errorWGPU      : wgpu.ErrorCallback          = cb.error;
    logWGPU        : wgpu.LogCallback            = cb.log;
    logLevel       : wgpu.LogLevel               = wgpu.LogLevel.warn;
    report         : bool                        = true;
    features       : seq[wgpu.Feature]           = @[];
    power          : wgpu.PowerPreference        = PowerPreference.highPerformance;
    forceFallback  : bool                        = false;
    requestAdapter : wgpu.RequestAdapterCallback = cb.adapterRequest;
    requestDevice  : wgpu.RequestDeviceCallback  = cb.deviceRequest;
    lost           : wgpu.DeviceLostCallback     = cb.deviceLost;
  ) :Minimal=
  new result
  result.instance = ngpu.Instance.new(label = label&" | Instance Minimal")
  result.adapter  = AdapterBase.new(
    instance      = result.instance,
    label         = label&" | Adapter Minimal",
    power         = power,
    forceFallback = forceFallback,
    requestCB     = requestAdapter,
    report        = report,
    ) # << AdapterBase.new( ... )
  result.device   = ngpu.Device.new(
    adapter       = result.adapter,
    limits        = Limits.default(),
    features      = @[],
    errorCB       = errorWGPU,
    requestCB     = requestDevice,
    lostCB        = lost,
    queueLabel    = label&" | Default Queue Minimal",
    label         = label&" | Device Minimal",
    ) # << Device.new( ... )


#_______________________________________
# Buffer: Operations
#__________________
export elements.ngpuBuffer.new
export elements.ngpuBuffer.term
#__________________
proc upload *[T](core :var Minimal; buf :ngpu.Buffer[T]; Tsize :SomeInteger= 0; offset :SomeInteger= 0) :void=
  ## Queues a command to upload the cpu.data of the buffer to the GPU.
  ## Tsize will be calculated from the data contained in the buffer when omitted (or set to 0).
  ## Will start writing at offset 0 when ommited (aka from the start of the buffer).
  core.device.upload(buf, Tsize, offset)
#__________________
proc transfer *[T](core :var Minimal; src :ngpu.Buffer[T]; trg :ngpu.Buffer[T]; srcOffset :SomeInteger= 0;  trgOffset :SomeInteger= 0; Tsize :SomeInteger= 0) :void=
  ## Queues a command to copy the GPU.data of src buffer into the GPU.data of the trg buffer.
  ## Does nothing to the CPU.data of either.
  ##
  ## Tsize is taken from src.cfg.size, unless specified with a value > 0.
  ## It will start copying at the start of src when srcOffset is omitted (or 0).
  ## It will start writing at the start of trg when trgOffset is ommited (or 0).
  core.device.transfer(src,trg, srcOffset,trgOffset, Tsize)
#__________________
export elements.ngpuBuffer.connect
export elements.ngpuBuffer.disconnect
export elements.ngpuBuffer.getData
#__________________
proc download *[T](core :var Minimal; trg :var ngpu.Buffer[T]; connectCB :wgpu.BufferMapCallback= cb.bufferConnect) :void=
  ## Copies the GPU.data of a Buffer into its CPU memory.
  ## Triggers a sync operation.
  ##
  ## Will call back with `bufferConnect()` at `callbacks.nim` when ommitted.
  core.device.download(trg, connectCB)

