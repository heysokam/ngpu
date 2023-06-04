#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# ndk dependencies
import nstd/types  as base
# ngpu dependencies
import ../../types as ngpu
import ../data
import ../validate
import ./entry


#_______________________________________
# BindGroup: Shape
#___________________
proc new *(_:typedesc[GroupShape];
    id     : Group;
    shapes : BindingShapes;
    device : ngpu.Device;
    label  : str = "ngpu | BindGroup Shape";
  ) :GroupShape=
  new result
  result.id         = id
  result.label      = label
  result.entries    = shapes
  var bindingShapes = result.entries.toWgpu
  result.cfg = BindGroupLayoutDescriptor(
    nextInChain  : nil,
    label        : result.label.cstring, # Recognizable name for errors
    entryCount   : bindingShapes.len.uint32,
    entries      : if bindingShapes.len > 0: bindingShapes[0].addr else: nil,
    ) # << device.createBindGroupLayout()
  result.ct = device.ct.create(result.cfg.addr)
#_______________________________________
proc new *(_:typedesc[GroupShapes];
    global : GroupShape;
    model  : GroupShape = nil;
    mesh   : GroupShape = nil;
    multi  : GroupShape = nil;
  ) :GroupShapes=
  result[Group.global] = global
  result[Group.model]  = model
  result[Group.mesh]   = mesh
  result[Group.multi]  = multi
#_______________________________________
proc new *(_:typedesc[GroupShapes];
    globalData : tuple;
    device     : ngpu.Device;
    label      : str = "ngpu | Group";
  ) :GroupShapes=
  ## Creates a new GroupShapes list, from the given tuple of Group.global RenderData objects.
  ## WRN: `data` must be a tuple of RenderData[T]
  assert globalData.isRenderData, "Tried to create a GroupShapes object, but one or more of the data inputs are not RenderData types."
  var globalShapes :BindingShapes
  var id :int
  for name,it in globalData.fieldPairs:
    doAssert id <= BindingID.high, "Tried to add more BindingShapes to Group.global than it is allowed per group."
    assert it.hasBinding, "Tried to add a RenderData object to a group, but its binding (or one of its fields) is not initialized."
    globalShapes[it.binding.id] = it.binding.shape
    id.inc # << tuple id   (fieldPairs gives a (name,field) instead)
  result = GroupShapes.new(
    global   = GroupShape.new(
      id     = Group.global,
      shapes = globalShapes,
      device = device,
      label  = label&".global Shape",
      ), # << global GroupShape.new( ... )
    model    = nil,
    mesh     = nil,
    multi    = nil,
    ) # << GroupShapes.new( ... )

#_______________________________________
# BindGroup: Real
#___________________
proc new *(_:typedesc[ngpu.BindGroup];
    shape   : GroupShape;
    entries : Bindings;
    device  : ngpu.Device;
    label   : str = "ngpu | BindGroup";
  ) :ngpu.BindGroup=
  new result
  result.label   = label
  result.entries = entries
  result.id      = shape.id
  var bindings   = result.entries.toWgpu
  result.cfg     = BindGroupDescriptor(
    nextInChain   : nil,
    label         : result.label.cstring,
    layout        : shape.ct,
    entryCount    : bindings.len.uint32,
    entries       : bindings[0].addr,
    ) # << BindGroupDescriptor( ... )
  result.ct = device.ct.create(result.cfg.addr) # device.createBindGroup()
#___________________
proc new *(_:typedesc[BindGroups];
    global : ngpu.BindGroup;
    model  : ngpu.BindGroup = nil;
    mesh   : ngpu.BindGroup = nil;
    multi  : ngpu.BindGroup = nil;
  ) :BindGroups=
  result[Group.global] = global
  result[Group.model]  = model
  result[Group.mesh]   = mesh
  result[Group.multi]  = multi

#_______________________________________
# BindGroup: Management
#___________________
proc set *(trg :var RenderTarget; group :ngpu.BindGroup) :void=
  ## Activates the target group in the given `trg` RenderTarget, so that its usable by the GPU.
  if group == nil: return  # Silently do nothing if the group is inactive, so that checks are not needed outside.
  trg.ct.set(group.id.ord.uint32, group.ct, 0, nil)  # Set the `bindGroup` at @group(id), with no dynamic offsets (0, nil)

#_______________________________________
# wgpu Conversion
#___________________
proc toWgpu *(groups :GroupShapes) :seq[wgpu.BindGroupLayout]=
  ## Converts the given groups list into the correct format for sending to wgpu.
  for group in groups:
    if group != nil:  result.add group.ct  # filter nil refs, and only add each item.ct to the seq


