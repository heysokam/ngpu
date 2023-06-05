#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/packedsets
import std/strformat
import std/strutils
# External dependencies
from   wgpu import ShaderStageFlags, ShaderStage
# ndk dependencies
import nstd/types as base
# ngpu dependencies
import ../types   as ngpu
import ../tool/wgsl
import ./buffer
import ./bindings
import ./validate


#_____________________________
# RenderData: Construct
#__________________
proc new *[T](_:typedesc[RenderData[T]];
    data    : T;
    varName : str;
    device  : ngpu.Device;
    upload  : bool  = false;
    label   : str   = "ngpu | RenderData";
  ) :RenderData[T]=
  ## Creates a new RenderData object with the given data, in the selected Group of the given RenderPass.
  ## Adds its shape to the pass, so that data of the same shape can be uploaded and used with it.
  ## Optional upload value:
  ## - Doesn't upload the data to the GPU when omitted.
  ## - If true: A separate `data.upload()` call is not needed to use its contents.
  new result
  result.label   = label & &" {$T}"
  result.code    = BindCode(vName: varName)  # init with empty code, until registered
  result.binding = nil                       # init with empty binding, until registered
  # Create the RenderData Buffer that will hold the variable.
  result.buffer  = Buffer[T].new(
    data   = data,
    size   = sizeof(data),
    usage  = {BufferUsage.copyDst, BufferUsage.uniform},  # Mark the buffer as a RenderData Buffer
    device = device,
    mapped = false,
    label  = result.label&" Buffer",
    ) # << Buffer.new( ... )
  # Upload the data when requested to do so, and the device is active.
  if upload and device.ct != nil: device.upload(result.buffer)


#_____________________________
# RenderData: Management
#__________________
proc add *[T](
    pass  : var RenderPass;
    data  : var RenderData[T];
    group : Group            = Group.global;
    usage : ShaderStageFlags = { ShaderStage.vertex, ShaderStage.fragment };
  ) :void=
  ## Adds the shape of the given RenderData object into the given RenderPass,
  ## so it can be used with it during the drawing step.
  assert not pass.pipeline.shape.groups.empty, &"Tried to add a RenderData object to Group.{$group}.{$data.binding.id}, but the group is not initialized."
  data.code = BindCode.new(
    varName = data.code.vName,
    data    = data.buffer.data,
    groupID = group,
    bindID  = pass.next(BindingID),
    ) # << BindCode.new( ... )
  pass.pipeline.shape.groups[data.cfg.gid].entries[data.cfg.bid] = data.binding.shape
#__________________
proc initBinding *[T](data :var RenderData[T];
    gid   : Group;
    bid   : BindingID;
    usage : ShaderStageFlags = { ShaderStage.vertex, ShaderStage.fragment };
  ) :void=
  ## Inititializes the Binding of the given RenderData object.
  ## When omitted, usage will be both vertex+fragment stages.
  data.binding       = new Bind
  data.binding.group = gid
  data.binding.id    = bid
  data.binding.kind  = BindingKind.data
  data.binding.shape = BindingShape.new(
    T      = T,
    bindID = data.binding.id,
    kind   = data.binding.kind,
    usage  = usage,
    label  = data.label & &" {$T} BindingShape Entry"
    ) # << BindingShape.new( ... )
  data.binding.ct = Binding.new(
    id   = data.binding.id,
    data = data,
    ) # << Binding.new( ... )


#__________________
proc upload *[T](device :ngpu.Device; u :RenderData[T]) :void=  device.upload(u.buffer)
  ## Queues a command to upload the CPU.data of the RenderData into its GPU.data.
proc upload *[T](device :ngpu.Device; data :T; u :RenderData[T]) :void=
  ## Queues an operation for copying the given data into the GPU.data of the given RenderData.
  ## Also stores it into the CPU.data of the RenderData.
  u.buffer.data = data
  device.upload(u.buffer)

#_____________________________
# RenderData: Code Generation
#__________________
proc genCode *[T](data :RenderData[T]) :BindCode=
  ## Generates the code for the given RenderData object, and returns it as a BindCode object.
  ## The input object is not modified.
  ## WRN: Expects data.code to already contain a vName.
  assert data.code.vName != "", &"Tried to generate code for a {$T} RenderData object, but its vName field is empty."
  assert data.binding != nil, &"Tried to generate code for a {$T} RenderData object, but its binding is not initialized."
  result = BindCode.new(
    data    = data.buffer.data,
    varName = data.code.vName,
    groupID = data.binding.group,
    bindID  = data.binding.id,
    ) # << BindCode.new( ... )
#___________________
proc initCode *[T](data :var RenderData[T]) :void=
  ## Initializes the code field for the given RenderData object.
  if data.hasCode: echo &"WRN : Generating shader code for a {$T} RenderData object that already has it."
  data.code = data.genCode()
#___________________
proc getCode *[T](data :RenderData[T]) :string=
  ## Returns the block of wgsl code for the given RenderData object.
  when T is object:  result = data.code.define & data.code.variable
  else:              result = data.code.variable


#_____________________________
# RenderData: Validate
#__________________
proc hasBinding *[T](data :RenderData[T]) :bool=  not data.binding.empty
  ## Checks that the given RenderData object has a correct binding initialized.
proc hasCode *[T](data :RenderData[T]) :bool=  data.code.hasCode
  ## Checks if the code of the given RenderData object has been initialized.
  ## Code is considered uninitialized if at least one of the fields is empty.
proc registered *[T](data :RenderData[T]) :bool=  data.hasBinding and data.hasCode
  ## Returns true if the given RenderData object has already been registered.

