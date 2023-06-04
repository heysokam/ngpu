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
  # TODO: Support for Samplers and Textures
  of BindingKind.blck:      raise newException(InitError, "RenderBlock BindingEntry support is not implemented.")
  of BindingKind.sampler:   raise newException(InitError, "Sampler BindingEntry support is not implemented.")
  of BindingKind.tex:       raise newException(InitError, "Texture BindingEntry support is not implemented.")
  of BindingKind.texStore:  raise newException(InitError, "StorageTexture BindingEntry support is not implemented.")
  # Apply to the result
  new result
  result.label = label & &" {$T}"
  result.id    = bindID
  result.ct    = BindGroupLayoutEntry(  # Uniform Layout Entry starts here
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
    tex : ngpu.Texture;
    id  : BindingID;
  ) :Binding=
  new result
  ## Creates a new binding for the given Texture
  result.id      = id
  result.bufCt   = nil
  result.bufOffs = 0
  result.bufSize = 0
  result.sampler = tex.sampler
  result.texView = tex.view
#___________________
proc new *(_:typedesc[Bindings];
    data : tuple;
  ) :Bindings=
  ## Returns the list of Bindings of the given tuple of RenderData objects.
  assert data.isRenderData, "Tried to create a Bindings list, but one or more of the data inputs are not RenderData types."
  for it in data.fields: result[it.binding.id] = it.binding.ct


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
      size        : entry.bufSize,
      sampler     : entry.sampler,
      textureView : entry.texView,
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

