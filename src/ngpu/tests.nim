#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/format



#__________________
proc basic *() :void=
  ## Most minimal basic test
  ## Checks that wgpu/ngpu work correctly on the system
  ## Creates a wgpu.Instance and prints its address.
  var descriptor = wgpu.InstanceDescriptor()
  var instance   = wgpu.create(descriptor.addr)
  doAssert instance != nil, "Couldn't create the wgpu-native instance."
  echo "ngpu works | Press Escape to close the window."
  echo "           | descriptor address is: ", descriptor.repra()
  echo "           | instance   address is: ", instance.repra()

