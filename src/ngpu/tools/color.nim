#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import pkg/chroma ; export chroma
import wgpu

# Converters
converter toWGPU *(color :chroma.Color) :wgpu.Color=  wgpu.Color( r: float64 color.r,  g: float64 color.g,  b: float64 color.b, a: float64 color.a )
  ## Automatically converts chroma.color to WGPU Color, which is similar but uses f64

