#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Tools for managing Generic Lists of ShaderData.  |
# ShaderData means Texture, RenderData, etc.       |
#__________________________________________________|
# std dependencies
import std/strutils
# n*dk dependencies
import nstd/types as base
import nstd/typetools
import nstd/address
# n*gpu dependencies
import ../types   as ngpu
import ./data
import ./texture
import ./bindings


#_______________________________________
# Aliases
#__________________
template toData *(t :tuple) :var tuple=  address.mvar(t)
  ## Returns the given :tuple as a :var tuple

#_______________________________________
# Validate
#__________________
proc isShaderData *(data :tuple) :bool=  data.isType( SomeShaderData )
  ## Checks that all fields of the tuple are one of the valid ShaderData types.
proc isRenderData *(data :tuple) :bool=  data.isType( RenderData )
  ## Checks that all fields of the tuple are RenderData types.
proc isTexData    *(data :tuple) :bool=  data.isType( TexData )
  ## Checks that all fields of the tuple are TexData types.
proc isTexture    *(data :tuple) :bool=  data.isType( ngpu.Texture )
  ## Checks that all fields of the tuple are Texture types.


#_______________________________________
# Bindings
#__________________
# Binds
proc initBinding *(list :var tuple; group :Group) :void=
  ## Inititializes the Bindings of all entries in the given ShaderData tuple.
  ## Sets all of them to the default ShaderStage usage for each type.
  ## WRN: Reinitializes any entry that already has binding data.
  assert list.isShaderData, "Tried to initialize the binding of a tuple that contains one or more non-ShaderData objects."
  var id :int
  for data in list.fields:
    data.initBinding(group, id)
    if data is ngpu.Texture: id.inc  # Textures with data+sampler take two slots. Increase id an extra time.
    id.inc
#__________________
# Shapes
proc new *(_:typedesc[GroupShapes];
    list   : tuple;
    device : ngpu.Device;
    label  : str = "ngpu | Group";
  ) :GroupShapes=
  ## Creates a new GroupShapes list, from the given list of Group.global ShaderData objects.
  assert list.isShaderData, "Tried to create a GroupShapes object, but one or more of the data inputs are not ShaderData types."
  var shapes :BindingShapes
  var id :int
  for it in list.fields:
    doAssert id <= BindingID.high, "Tried to add more BindingShapes to Group.global than it is allowed per group."
    when it is ngpu.Texture:
      assert it.data.hasBinding,  "Tried to add a Texture object to a group, but its TexData binding (or one of its fields) is not initialized."
      assert it.sampl.hasBinding, "Tried to add a Texture object to a group, but its Sampler binding (or one of its fields) is not initialized."
      shapes[it.data.binding.id]  = it.data.binding.shape
      shapes[it.sampl.binding.id] = it.sampl.binding.shape
      id.inc # Textures with data and sampler take two binding slots. Increase tuple id a second time.
    else:
      assert it.hasBinding, "Tried to add a ShaderData object to a group, but its binding (or one of its fields) is not initialized."
      shapes[it.binding.id] = it.binding.shape
    id.inc # << tuple id   (fieldPairs gives a (name,field) instead)
  result = GroupShapes.new(
    global   = GroupShape.new(
      id     = Group.global,
      shapes = shapes,
      device = device,
      label  = label&".global Shape",
      ), # << global GroupShape.new( ... )
    model    = nil,
    mesh     = nil,
    multi    = nil,
    ) # << GroupShapes.new( ... )
#___________________
# Real Entries
proc new *(_:typedesc[Bindings];
    list : tuple;
  ) :Bindings=
  ## Returns the list of Bindings of the given tuple of ShaderData objects.
  assert list.isShaderData, "Tried to create a Bindings list, but one or more of the data inputs are not ShaderData types."
  for it in list.fields:
    when it is ngpu.Texture:
      result[it.data.binding.id]  = it.data.binding.ct
      result[it.sampl.binding.id] = it.sampl.binding.ct
    else:
      result[it.binding.id] = it.binding.ct


#_______________________________________
# wgsl Code
#___________________
proc initCode *(list :var tuple) :void=
  ## Initializes the code field for all items in the given ShaderData tuple.
  assert list.isShaderData, "Tried to initialize the shader code of a tuple that contains non-ShaderData objects."
  for it in list.fields:
    when it is ngpu.Texture:
      it.data.code  = it.data.genCode()
      it.sampl.code = it.sampl.genCode()
    else:
      it.code = it.genCode()
#___________________
proc getCode *(list :tuple) :string=
  ## Returns the single block of wgsl code for all items in the given ShaderData tuple.
  ## The input tuple is not modified.
  assert list.isShaderData, "Tried to get the shader code of a tuple that contains non-ShaderData objects."
  var defines   :seq[string]  # List of defines.   Concatenated at result
  var variables :seq[string]  # List of variables. Concatenated at result
  for it in list.fields:
    when it is ngpu.Texture:
      variables.add it.data.code.variable
      variables.add it.sampl.code.variable
    else:
      if it.code.define notin defines and it.code.define != NoTypeCode:
        defines.add it.code.define
      variables.add it.code.variable
  result = defines.join("") & variables.join("")
#___________________
proc genCode *(list :tuple) :seq[BindCode]=
  ## Generates the code for all items in the given ShaderData tuple, and returns it as a seq of BindCode objects.
  ## The input tuple is not modified.
  ## WRN: Expects the data.code of every item to already contain a vName.
  assert list.isShaderData, "Tried to generate shader code for a tuple that contains non-ShaderData objects."
  for data in list.fields:
    result.add data.genCode()

