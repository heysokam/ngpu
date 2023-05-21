Preset configuration values:
```md
# Device
powerPreference       : highPerformance
forceFallbackAdapter  : false
```

When not explicitely initialized, defaults for the elements will be:
```md
# General
prefix label                 : ngpu
per-element label            : prefix + " | OBJECTNAME"  >> eg: "ngpu | Device"
logLevel                     : warn
log functions                : functions found @ngpu/tools/logger.nim
report features+capabilities : true
wgpu.callbacks               : functions found @ngpu/callbacks.nim

# Device
requiredLimits    : wgpu.default(Limits)  >>  from : https://docs.rs/wgpu-types/0.16.0/src/wgpu_types/lib.rs.html#912
requiredFeatures  : none

# Swapchain
composite alphaMode   : auto
presentMode           : fifo
usage                 : RenderAttachment
updateView attempts   : 2

# Window
error callback       : error() function found @ngpu/window.nim
all other callbacks  : nil
resizable            : true
```

