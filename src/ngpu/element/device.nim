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
import ../tool/logger as l
import ./queue

#___________________
proc reportLimits (device :ngpu.Device) :void=
  l.info ":: Limits to which this system's device has been restricted:"
  var sup :SupportedLimits
  discard device.ct.get(sup.addr)
  for name,limit in sup.limits.fieldPairs:
    l.info ":   device.",name,": ",limit
#___________________
proc info *(device :ngpu.Device) :void=
  ## Reports the limits supported by the given Device.
  ## Uses the internal `info` logging function, which can be reasigned on context creation.
  device.reportLimits()

#___________________
proc new *(_:typedesc[ngpu.Device];
    adapter    : ngpu.Adapter | ngpu.AdapterBase;
    limits     : wgpu.Limits                = Limits.default();
    features   : seq[wgpu.Feature]          = @[];
    errorCB    : wgpu.ErrorCallback         = cb.error;
    requestCB  : wgpu.RequestDeviceCallback = cb.deviceRequest;
    lostCB     : wgpu.DeviceLostCallback    = cb.deviceLost;
    report     : bool                       = true;
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
  wgpu.set(result.ct, errorCB, nil)
  wgpu.set(result.ct, lostCB, nil)
  # Get the device queue
  result.queue = ngpu.Queue.new(result)
  # Report info to console
  if report: result.info()

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

