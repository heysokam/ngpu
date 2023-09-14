#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# n*dk dependencies
import wgpu
# n*gpu dependencies
import ./tool/logger as l

#_______________________________________
# WGPU default callbacks
#__________________
proc error *(typ :ErrorType; message :CString; userdata :pointer) :void {.cdecl.}=
  err &"UNCAPTURED ERROR: ({$typ}): {$message}"
proc log *(level :LogLevel; message :CString; userdata :pointer) :void {.cdecl.}=
  l.log &"[{$level}] {$message}"

#__________________
# Core
proc adapterRequest *(status :RequestAdapterStatus; adapter :Adapter; message :CString; userdata :pointer) :void {.cdecl.}=
  cast[ptr Adapter](userdata)[] = adapter  # *(WGPUAdapter*)userdata = received;
proc deviceRequest  *(status :RequestDeviceStatus; device :Device; message :CString; userdata :pointer) :void {.cdecl.}=
  cast[ptr Device](userdata)[] = device  # *(WGPUAdapter*)userdata = received;
proc deviceLost *(reason :DeviceLostReason; message :CString; userdata :pointer) :void {.cdecl.}=
  err &"DEVICE LOST: ({$reason}): {$message}"

#__________________
# Buffer
proc bufferConnect *(status :wgpu.BufferMapAsyncStatus; userdata :pointer) :void {.cdecl.}=
  l.info &"async -> buffer Connected with status: {$status}"

#__________________
# Queue Done
when false:  # Disable compilation. Here for future reference. wgpuQueueOnSubmittedWorkDone is unimplemented by wgpu-native
  proc queueDoneCB (status :QueueWorkDoneStatus; userdata :pointer) :void {.cdecl.}=
    info &"wgpu -> Queue Work: Finished with status: {$status}"

