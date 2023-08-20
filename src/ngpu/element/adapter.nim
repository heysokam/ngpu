#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# n*dk dependencies
import nstd/types as base
# n*gpu dependencies
import ../types       as ngpu
import ../tool/logger as l
from   ../callbacks   as cb import nil


#___________________
proc reportLimits (adapter :ngpu.AdapterBase) :void=
  # Read the vertex attributes and buffers limits of the system
  l.info ":: \"Best\" limits supported by the adapter initialized on this system:"
  var sup :SupportedLimits
  discard adapter.ct.get(sup.addr)
  for name,limit in sup.limits.fieldPairs:
    l.info ":   adapter.",name,": ",limit
#___________________
proc reportFeatures (adapter :ngpu.AdapterBase) :void=
  l.info ":: WGPU Features supported by this system: "
  for it in adapter.ct.features(): l.info ":  - ",$it
#___________________
proc reportCapabilities (adapter :ngpu.Adapter) :void=
  l.info ":: Surface Capabilities supported by this system: "
  let (textureFormats, presentModes, alphaModes) = wgpu.capabilities(adapter.surface, adapter.ct)
  l.info ":  Texture Formats:"
  for formt in textureFormats: l.info ":  - ",$formt
  l.info ":  Present Modes:"
  for prsnt in presentModes:   l.info ":  - ",$prsnt
  l.info ":  Alpha Modes:"
  for alpha in alphaModes:     l.info ":  - ",$alpha

#___________________
proc info *(adapter :ngpu.AdapterBase) :void=
  ## Reports the features and limits supported by the given AdapterBase
  ## Uses the internal `info` logging function, which can be reasigned on context creation.
  adapter.reportFeatures()
  adapter.reportLimits()
proc info *(adapter :ngpu.Adapter) :void=
  ## Reports the features, capabilities and limits supported by the given Adapter
  ## Uses the internal `info` logging function, which can be reasigned on context creation.
  adapter.reportFeatures()
  adapter.reportCapabilities()
  adapter.reportLimits()

#___________________
proc getPreferredFormat *(adapter :ngpu.Adapter) :wgpu.TextureFormat=
  wgpu.getPreferredFormat(adapter.surface, adapter.ct)

#___________________
# Adapter: Standard
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

#___________________
# Adapter: Base
proc new *(_:typedesc[ngpu.AdapterBase];
    instance      : ngpu.Instance;
    power         : PowerPreference             = PowerPreference.highPerformance;
    forceFallback : bool                        = false;
    requestCB     : wgpu.RequestAdapterCallback = cb.adapterRequest;
    report        : bool                        = true;
    label         : str                         = "ngpu | Adapter Base";
  ) :ngpu.AdapterBase=
  ## Creates a new AdapterBase object.
  ## Only for no-window apps. Use Adapter.new() for normal rendering instead.
  new result
  # Create an Adapter, but not a surface
  result.cfg = RequestAdapterOptions(
    nextInChain           : nil,
    compatibleSurface     : nil,
    powerPreference       : power,
    forceFallbackAdapter  : forceFallback,
    ) # << RequestAdapterOptions()
  instance.ct.request(result.cfg.addr, requestCB, result.ct.addr)
  # Report Features and Capabilities
  if report: result.info()

