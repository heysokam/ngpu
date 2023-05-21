#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/types   as base
# ngpu dependencies
import ../types     as ngpu
from   ../callbacks as cb import nil
import ./queue


#___________________
proc new *(_:typedesc[ngpu.Device];
    adapter    : ngpu.Adapter | ngpu.AdapterBase;
    limits     : wgpu.Limits                = Limits.default();
    features   : seq[wgpu.Feature]          = @[];
    errorCB    : wgpu.ErrorCallback         = cb.error;
    requestCB  : wgpu.RequestDeviceCallback = cb.deviceRequest;
    lostCB     : wgpu.DeviceLostCallback    = cb.deviceLost;
    queueLabel : str                        = "ngpu | Default Queue";
    label      : str                        = "ngpu | Device";
  ) :ngpu.Device=
  new result
  let queueCfg    = QueueDescriptor(label: queueLabel)
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

#___________________
proc sync *(device :var ngpu.Device) :bool {.discardable.}=  device.ct.poll(wait = true, nil)
  ## Waits for the device to be done with all operations in its Queues (resource cleanups and mapping callbacks).
  ## Returns a (discardable) bool:
  ## - true  : the queue is empty
  ## - false : There are more queue submissions still in flight.
  ## Note: This information could be out of date by the time the caller receives it,
  ##       unless access to the Queue is coordinated somehow,
  ##       Queues can be shared between threads, so other threads could submit new work at any time.
  ## Web:  No-Op. Devices are automatically polled.

