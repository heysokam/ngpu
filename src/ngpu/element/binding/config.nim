#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# ndk dependencies
import nstd/types  as base
# ngpu dependencies
import ../../types as ngpu
import ../../tool/wgsl


#_____________________________
# Config: Construct
#__________________
proc new *(_:typedesc[Bind];
    group : Group;
    id    : BindingID;
    shape : BindingShape;
    ct    : Binding;
    kind  : BindingKind;
  ) :Bind=
  new result
  result.kind  = kind
  result.group = group
  result.id    = id
  result.shape = shape
  result.ct    = ct
#__________________
proc new *[T :not SomeTexture](_:typedesc[BindCode];
    data    : T;
    varName : str;
    groupID : Group;
    bindID  : BindingID;
  ) :BindCode=
  result.vName = varName
  result.tName = $T
  (result.define, result.variable) = wgsl.renderdata(data, groupID.ord, bindID, result.vName)
#__________________
proc new *[T :SomeTexture](_:typedesc[BindCode];
    data    : T;
    varName : str;
    groupID : Group;
    bindID  : BindingID;
  ) :BindCode=
  result.vName = varName
  result.tName = $T
  (result.define, result.variable) = wgsl.texdata(data, groupID.ord, bindID, result.vName)

