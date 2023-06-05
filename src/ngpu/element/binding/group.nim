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


