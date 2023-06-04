#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# ngpu dependencies
import ../types as ngpu


#_______________________________________
# Bindings
#___________________
proc empty *(shapes :BindingShapes | GroupShapes) :bool=
  ## Returns true if at least one of the elements in the given list of shapes is initialized.
  for it in shapes:
    if it != nil: return false
  result = true


#_______________________________________
# RenderData
#__________________
proc isRenderData *(data :tuple) :bool=
  ## Checks that all fields of the tuple are RenderData types.
  for it in data.fields:
    if it isnot RenderData: return false
  result = true
#__________________
proc hasBinding *[T](data :RenderData[T]) :bool=
  ## Checks that the given RenderData object has a correct binding initialized.
  result = data.binding != nil and data.binding.shape != nil and data.binding.ct != nil
#__________________
proc hasCode *[T](data :RenderData[T]) :bool=
  ## Checks if the code of the given RenderData object has been initialized.
  ## Code is considered uninitialized if at least one of the fields is empty.
  for name,code in data.code.fieldPairs:  # Check all fields one by one
    if name == "vName": continue          # Skip checking the vName field. The object could have no code while having a vName.
    if code == "": return false           # Fail the check as soon as one is empty.
  result = true

