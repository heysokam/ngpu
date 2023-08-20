#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Write a Buffer to GPU, and read its data back      |
# No window, no compute. Only does a read/write op.  |
# These operations are only useful for compute.      |
#____________________________________________________|_____________________
# NOTE: This example is fairly verbose for whats normal in the lib.        |
# The functionality of the Minimal core is not abstracted into any Tech.   |
#__________________________________________________________________________|
# std dependencies
import std/strformat
import std/sequtils
# n*dk dependencies
import nstd
# n*gpu dependencies
import ngpu

#__________________
# We need extra imports for this example, because its so barebones
import ngpu/core/minimal
from   wgpu import nil
#__________________


#________________________________________________
# Entry Point
#__________________
proc run=
  echo "ngpu | Hello Buffer"
  #__________________
  # Define the CPU.data:  size 16 bytes, filled with numbers 0..15
  var numbers = (0'u8..15'u8).toSeq
  #__________________
  # Init the minimal wgpu elements needed
  minimal.initLog()
  var core = Minimal.new(label = "ngpu")
  #__________________
  # Init the Buffers
  # Define the first Buffer object, used to upload to the GPU
  var buffer1 = Buffer.new(numbers,
    usage     = {BufferUsage.copyDst, BufferUsage.copySrc},
    size      = numbers.size,
    device    = core.device,
    mapped    = false,
    label     = "Input buffer: Written from the CPU to the GPU",
    ) # << Buffer.new( ... )
  # Define the second Buffer object, with a `mapRead` flag so that we can map it later.
  var buffer2 = Buffer[numbers.type].new(
    usage     = {BufferUsage.copyDst, BufferUsage.mapRead},
    size      = numbers.size,
    device    = core.device,
    mapped    = false,
    label     = "Output buffer: Read back from the GPU by the CPU",
    ) # << Buffer.new( ... )
  # Copy the data and read it back
  core.upload(buffer1)             # Copy the buffer data from RAM to VRAM
  core.updateEncoder()             # Create the CommandEncoder, which is needed to do anything other than uploading data.
  core.transfer(buffer1, buffer2)  # Copy the GPU.data of buffer1 into buffer2, without changing the CPU.data
  core.submitQueue()               # Finalize the Command Encoder and Submit the queue
  core.download(buffer2)           # Download the GPU.data of buffer2 into its CPU.data field
  # Make sure that the data stored in buffer2 is correct
  doAssert buffer2.data == numbers, "Data contained in buffer2 is invalid"
  # Report to console
  echo "CPU.data = ",numbers
  echo "GPU.data = ",buffer2.data 
  # Terminate the buffers
  buffer1.term()
  buffer2.term()

#________________________________________________
when isMainModule: run()

