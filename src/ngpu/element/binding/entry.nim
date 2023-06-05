#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# External dependencies
import wgpu
# ndk dependencies
import nstd/types  as base
# ngpu dependencies
import ../../types as ngpu
import ../validate


#_______________________________________
# Binding: Shape
#___________________
proc new *(_:typedesc[BindingShape];
    T      : typedesc;
    bindID : BindingID;
    kind   : BindingKind;
    usage  : ShaderStageFlags = { ShaderStage.vertex, ShaderStage.fragment };
    label  : str              = "ngpu | BindingShape Entry";
  ) :BindingShape=
  # Generate temp data, based on input kind
  var buffer   :BufferBindingLayout
  var sampler  :SamplerBindingLayout
  var texture  :TextureBindingLayout
  var texStore :StorageTextureBindingLayout
  case kind
  # RenderData
  of BindingKind.data:
    buffer = BufferBindingLayout(
      nextInChain      : nil,
      typ              : BufferBindingType.uniform,  # Mark the buffer for usage as a uniform or storage
      hasDynamicOffset : false,            # TODO: For dynamic buffers. What's is this?  https://docs.rs/wgpu/latest/wgpu/enum.BindingType.html#variant.Buffer.field.has_dynamic_offset
      minBindingSize   : T.sizeof.uint64,  # Minimum size for uploaded values is now the size of the object
      ) # << buffer
    sampler  = SamplerBindingLayout()
    texture  = TextureBindingLayout()
    texStore = StorageTextureBindingLayout()
  # Texture
  # TODO: Support for Custom Properties
  #     :   Sample Type (float, sint, uint, etc)
  #     :   TextureDimension  (1D and 3D)
  of BindingKind.tex:
    buffer   = BufferBindingLayout()
    sampler  = SamplerBindingLayout(
      nextInChain   : nil,
      typ           : SamplerBindingType.nonFiltering,  # Set filter to none for Textures
      ) # << sampler
    texture  = TextureBindingLayout(
      nextInChain   : nil,
      sampleType    : TextureSampleType.Float,    # Set the color type to float
      viewDimension : TextureViewDimension.dim2D, # Make it a 2D texture
      multisampled  : false,
      ) # << texture
    texStore = StorageTextureBindingLayout()
  # Sampler
  of BindingKind.sampler:
    buffer  = BufferBindingLayout()
    sampler = SamplerBindingLayout(
      nextInChain : nil,
      typ         : SamplerBindingType.filtering,  # Set filtering
      ) # << sampler
    texture  = TextureBindingLayout()
    texStore = StorageTextureBindingLayout()
    raise newException(InitError, "Sampler BindingShape support is not implemented.")
  # TODO: Support for StorageTexture and StorageBuffer
  of BindingKind.blck:      raise newException(InitError, "RenderBlock BindingShape support is not implemented.")
  of BindingKind.texBlock:  raise newException(InitError, "TexBlock BindingShape support is not implemented.")
  # Apply to the result
  new result
  result.label = label & &" {$T}"
  result.id    = bindID
  result.ct    = BindGroupLayoutEntry(
    nextInChain    : nil,
    binding        : result.id.uint32,  # Shader @binding(id) index
    visibility     : usage,             # Default: Used in both vertex and fragment stages
    buffer         : buffer,
    sampler        : sampler,
    texture        : texture,
    storageTexture : texStore,
    ) # << entry

#_______________________________________
# Binding: Real
#___________________
proc new *[T](_:typedesc[Binding];
    data   : RenderData[T];
    id     : BindingID;
    offset : Someinteger = 0;
  ) :Binding=
  ## Creates a new binding for the given RenderData object.
  new result
  result.id      = id
  result.bufCt   = data.buffer.ct
  result.bufOffs = offset.uint64
  result.bufSize = data.buffer.cfg.size
  result.sampler = nil
  result.texView = nil
#___________________
proc new *(_:typedesc[Binding];
    tex : ngpu.TexData;
    id  : BindingID;
  ) :Binding=
  ## Creates a new binding for the given Texture.
  new result
  result.id      = id
  result.bufCt   = nil
  result.bufOffs = 0
  result.bufSize = 0
  result.sampler = nil
  result.texView = tex.view.ct
#___________________
proc new *(_:typedesc[Binding];
    sampler : ngpu.Sampler;
    id      : BindingID;
  ) :Binding=
  ## Creates a new binding for the given Sampler.
  new result
  result.id      = id
  result.bufCt   = nil
  result.bufOffs = 0
  result.bufSize = 0
  result.sampler = sampler.ct 
  result.texView = nil


#_______________________________________
# wgpu Conversion
#___________________
proc toWgpu *(shapes :BindingShapes) :seq[wgpu.BindGroupLayoutEntry]=
  ## Converts the given BindingShapes list into the format expected by wgpu.
  for entry in shapes:
    if entry == nil: continue
    result.add entry.ct
#___________________
proc toWgpu *(bindings :Bindings) :seq[wgpu.BindGroupEntry]=
  ## Converts the given Bindings list into the format expected by wgpu.
  for entry in bindings:
    if entry == nil: continue
    result.add BindGroupEntry(
      nextInChain : nil,
      binding     : entry.id.uint32,  # Shader @binding(id) index
      buffer      : entry.bufCt,      # Buffer that contains the data for this binding
      offset      : entry.bufOffs,    # Offset within the buffer (useful for storing multiple blocks in the same buffer)
      size        : entry.bufSize,    # Size of the buffer, when its relevant
      sampler     : entry.sampler,    # Sampler context
      textureView : entry.texView,    # TextureView context
      ) # << BindGroupEntry( ... )


#_______________________________________
# List Management
#___________________
proc next *(entries :BindingShapes; group :Group) :BindingID=
  ## Returns the next BindingID available in the given list of entries.
  ## The group input is used for error messages only, and it is assumed to be given correctly.
  for id,entry in entries.pairs:
    if   entry == nil:             return id  # Return the id of the first nil entry found
    elif id < DefaultMaxBindings:  continue   # We found a non-nil, so continue searching
    else: raise newException(DataError, &"Reached BindingID:{id} for Group.{$group}, but the group is full.")  # Should never be reached
#___________________
proc next *(pass: RenderPass; _:typedesc[BindingID]; group :Group) :BindingID=
  ## Returns the next free id available in the given group id of the given RenderPass.
  pass.pipeline.shape.groups[group].entries.next(group)

