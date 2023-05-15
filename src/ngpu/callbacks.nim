#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# ndk dependencies
import wgpu
# ngpu dependencies
import ./tools/logger as l

#__________________
# WGPU default callbacks
proc adapterRequest *(status :RequestAdapterStatus; adapter :Adapter; message :cstring; userdata :pointer) :void {.cdecl.}=
  cast[ptr Adapter](userdata)[] = adapter  # *(WGPUAdapter*)userdata = received;
proc deviceRequest  *(status :RequestDeviceStatus; device :Device; message :cstring; userdata :pointer) :void {.cdecl.}=
  cast[ptr Device](userdata)[] = device  # *(WGPUAdapter*)userdata = received;
proc deviceLost *(reason :DeviceLostReason; message :cstring; userdata :pointer) :void {.cdecl.}=
  err &"DEVICE LOST: ({$reason}): {$message}"
proc error *(typ :ErrorType; message :cstring; userdata :pointer) :void {.cdecl.}=
  err &"UNCAPTURED ERROR: ({$typ}): {$message}"
proc log *(level :LogLevel; message :cstring; userdata :pointer) :void {.cdecl.}=
  l.log &"[{$level}] {$message}"

