#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# n*dk dependencies
import nstd/types   as base
# n*gpu dependencies
import ../types     as ngpu
from   ../callbacks as cb import nil
import ./device
# Exports needed by the rest of the code
export wgpu.BufferMapCallback


#_______________________________________
# Buffer: Construct
#___________________
proc new *[T](_:typedesc[ngpu.Buffer[T]];
    data   : T;
    size   : SomeInteger;
    usage  : BufferUsageFlags;
    device : ngpu.Device;
    mapped : bool = false;
    label  : str  = "ngpu | Buffer"
  ) :ngpu.Buffer[T]=
  new result
  result.data  = data
  result.label = label & &" {$T}"
  result.cfg   = BufferDescriptor(
    nextInChain      : nil,
    label            : result.label.cstring,
    usage            : usage,
    size             : size.uint32,
    mappedAtCreation : mapped,
    ) # << device.createBuffer()
  result.ct = device.ct.create(result.cfg.addr)
#___________________
proc new *[T](_:typedesc[ngpu.Buffer[T]];
    usage  : BufferUsageFlags;
    size   : SomeInteger;
    device : ngpu.Device;
    mapped : bool = false;
    label  : str  = "ngpu | Buffer";
  ) :ngpu.Buffer[T]=
  new result
  result.label = label & &" {$T}"
  result.cfg   = BufferDescriptor(
    nextInChain      : nil,
    label            : result.label.cstring,
    usage            : usage,
    size             : size.uint32,
    mappedAtCreation : mapped,
    ) # << device.createBuffer()
  result.ct = device.ct.create(result.cfg.addr)
#___________________
proc term *[T](trg :var ngpu.Buffer[T]) :void=  trg.ct.destroy()
  ## Terminates the GPU side of the `trg` Buffer.
  ##
  ## The GC will terminate the rest of its data when it goes out of scope.
  ## Should call `trg.disconnect()` first if it has been manually connected.

#_______________________________________
# Buffer: Operations
#_____________________________
# Buffer: Upload
#__________________
proc upload *[T](queue :ngpu.Queue; data :pointer; buf :ngpu.Buffer[T]; Tsize :SomeInteger= 0; offset :SomeInteger= 0) :void {.inline.}=
  ## Queues a command to upload the given CPU.data pointer to the given GPU buffer.
  ##
  ## Tsize is taken from buf.cfg.size when omitted (or 0).
  ## Will start writing at offset 0 when ommited (aka from the start of the buffer).
  ## Inline alias to wgpu.writeBuffer()
  queue.ct.write(
    buffer       = buf.ct,
    bufferOffset = offset.uint64,
    data         = data,
    size         = if Tsize == 0: buf.cfg.size.csize_t else: Tsize.csize_t,
    ) # << wgpu.writeBuffer
#__________________
proc upload *[T :not seq](device :ngpu.Device; buf :ngpu.Buffer[T]; Tsize :SomeInteger= 0; offset :SomeInteger= 0) :void=
  ## Queues a command to upload the CPU.data of the buffer into its GPU.data,
  ##
  ## Tsize is taken from buf.cfg.size when omitted (or 0).
  ## Will start writing at offset 0 when ommited (aka from the start of the buffer).
  ##
  ## note: This function won't trigger when `T is seq`.
  ##       Buffer[seq[T]] has its own generic version, found automatically by the compiler.
  device.queue.upload(
    data   = buf.data.addr,
    buf    = buf,
    Tsize  = if Tsize == 0: buf.cfg.size.uint64 else: Tsize.uint64,
    offset = offset.uint64,
    )
#__________________
proc upload *[T :seq](device :ngpu.Device; buf :ngpu.Buffer[T]; Tsize :SomeInteger= 0; offset :SomeInteger= 0) :void=
  ## Queues a command to upload the CPU.data of the buffer to the GPU.
  ##
  ## Tsize is taken from buf.cfg.size when omitted (or 0).
  ## Will start writing at offset 0 when ommited (aka from the start of the buffer).
  ##
  ## note: seq[seq[T]] will not work, since wgpu doesn't know about Nim sequences.
  ##       Use the raw queue.upload proc for uploading Nim sequences to wgpu as they are
  ##       Pro-Tip: Don't do that. Data should have the same shape in both CPU and GPU. But the proc is there if you require it.
  device.queue.upload(
    data   = buf.data[0].addr,
    buf    = buf,
    Tsize  = if Tsize == 0: buf.cfg.size.uint64 else: Tsize.uint64,
    offset = offset.uint64,
    )
#_____________________________
# Buffer: Transfer
#__________________
proc transfer *[T](encoder :ngpu.CommandEncoder; src :ngpu.Buffer[T]; trg :ngpu.Buffer[T]; srcOffset :SomeInteger= 0; trgOffset :SomeInteger= 0; Tsize :SomeInteger= 0) :void {.inline.}=
  ## Queues a command to copy the GPU.data of src buffer into the GPU.data of the trg buffer.
  ## Does nothing to the CPU.data of either.
  ##
  ## Tsize is taken from src.cfg.size, unless specified with a value > 0.
  ## It will start copying at the start of src when srcOffset is omitted (or 0).
  ## It will start writing at the start of trg when trgOffset is ommited (or 0).
  encoder.ct.copy(
    source            = src.ct,
    sourceOffset      = srcOffset.uint64,
    destination       = trg.ct,
    destinationOffset = trgOffset.uint64,
    size              = if Tsize == 0: src.cfg.size else: Tsize.uint64,
    ) # << wgpu.copyBufferToBuffer
#__________________
proc transfer *[T](device :ngpu.Device; src :ngpu.Buffer[T]; trg :ngpu.Buffer[T]; srcOffset :SomeInteger= 0;  trgOffset :SomeInteger= 0; Tsize :SomeInteger= 0) :void=
  ## Queues a command to copy the GPU.data of src buffer into the GPU.data of the trg buffer.
  ## Does nothing to the CPU.data of either.
  ##
  ## Tsize is taken from src.cfg.size, unless specified with a value > 0.
  ## It will start copying at the start of src when srcOffset is omitted (or 0).
  ## It will start writing at the start of trg when trgOffset is ommited (or 0).
  device.queue.encoder.transfer(src,trg, srcOffset,trgOffset, Tsize)
#_____________________________
# Buffer: Connect / Disconnect
#__________________
proc connect *[T](
    trg      : ngpu.Buffer[T];
    callback : wgpu.BufferMapCallback = cb.bufferConnect;
    Tsize    : SomeInteger            = 0;
    offset   : SomeInteger            = 0;
  ) :void=
  ## Queues a command to connect the GPU.data of trg, so that it can be accessed from the CPU.
  ## The `cb` function will be called when the operation finishes on the GPU side.
  ##
  ## Tsize is taken from buf.cfg.size when omitted (or 0).
  ## Will start reading at offset 0 when ommited (aka from the start of the buffer).
  ## Will call back with `bufferConnect()` at `callbacks.nim` when ommitted.
  trg.ct.mapAsync(
    mode     = {MapMode.read},
    offset   = offset.csize_t,
    size     = if Tsize == 0: trg.cfg.size.csize_t else: Tsize.csize_t,
    callback = callback,
    userdata = trg.ct.addr,
    ) # << wgpu.mapAsync
#__________________
proc disconnect *[T](trg :ngpu.Buffer[T]) :void=  wgpu.unmap(trg.ct)
  ## Orders to stop the connection between the GPU and CPU for the given Buffer.
#_____________________________
# Buffer: Get GPU data
#__________________
proc getData *[T :not seq](trg :ngpu.Buffer[T];) :T=
  ## Returns the GPU.data stored in the `trg` buffer.
  ## Requires the buffer to be `connect()`ed before calling.
  ## Does not store the data inside the buffer. Only returns it.
  result = cast[ptr T]( trg.ct.getMappedRange(0, trg.cfg.size) )[]
#__________________
proc getData *[T :seq](trg :ngpu.Buffer[T]) :T=
  ## Returns the GPU.data stored in the `trg` buffer.
  ## Requires the buffer to be `connect()`ed before calling.
  ## Does not store the data inside the buffer. Only returns it.
  let data = cast[ptr UncheckedArray[trg.data[0].type]]( trg.ct.getMappedRange(0, trg.cfg.size.csize_t) )
  for id in 0..<trg.cfg.size:  result.add data[id]
#_____________________________
# Buffer: Download
#__________________
proc download *[T](
    device    : var ngpu.Device;
    trg       : var ngpu.Buffer[T];
    connectCB : wgpu.BufferMapCallback = cb.bufferConnect;
  ) :void=
  ## Copies the GPU.data of a Buffer into its CPU memory.
  ## Triggers a sync operation on the device   (aka `device.poll()` in wgpu)
  ##
  ## Will call back with `bufferConnect()` at `callbacks.nim` when ommitted.
  trg.connect(connectCB)    # Connect the GPU.data at buffer2. The API will execute `buffer2CB` when done.
  device.sync()             # Wait for the device to be done connecting.
  trg.data = trg.getData()  # Read back the data, and store a copy in buffer.data.
  trg.disconnect()          # Clean after we are done.

#_____________________________
# Buffer: Copy
#__________________
# TODO
# copy  : Copies both GPU/CPU.data of a buffer into another. Like transfer, but for both sides of the data.
#_____________________________
# Buffer: Clone
#__________________
# TODO
# clone : Creates a duplicate of a Buffer in its current state (both its GPU/CPU data).  (also called `deepcopy` in the programming culture)

