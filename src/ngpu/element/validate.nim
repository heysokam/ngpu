#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# n*dk dependencies
import nstd
# n*gpu dependencies
import ../types as ngpu


#_______________________________________
# Bindings
#___________________
proc empty *(shapes :BindingShapes | GroupShapes) :bool=
  ## Returns true if at least one of the elements in the given list of shapes is initialized.
  for it in shapes:
    if it != nil: return false
  result = true
#___________________
proc empty *(binding :Bind) :bool=
  ## Returns true if the given binding has not been initialized.
  result = binding == nil and binding.shape == nil and binding.ct == nil

#_______________________________________
# Code
#___________________
proc hasCode *(code :BindCode) :bool=
  ## Checks if the given code object has been initialized.
  ## It is considered uninitialized if at least one of the fields is empty.
  for name,code in code.fieldPairs:  # Check all fields one by one
    if name == "vName": discard      # Skip checking the vName field. The object could have no code while having a vName.
    elif code == "": return false    # Fail the check as soon as one is empty.
  result = true

