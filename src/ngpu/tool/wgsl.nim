#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/macros
import std/strformat
import std/strutils
# ndk dependencies
import nmath/types as m
# ngpu dependencies
import ../types as ngpu


#_______________________________________
# Helpers
#_____________________________
macro name (v :typed) :untyped=
  ## Returns the name of a dot expression or a symbol as a string literal.
  if   v.kind == nnkSym:      result = newLit v.strVal
  elif v.kind == nnkDotExpr:  result = newLit v[1].repr
  else:                       error("expected to work on DotExpr or Sym", v)
#_____________________________
proc toWgpu (tname :string) :string=
  ## Returns the wgpu version of the given typeName string.
  case tname
  of "float32": "f32"
  of "int32":   "i32"
  of "uint32":  "u32"
  of "Vec2":    "vec2<f32>"
  of "Vec3":    "vec3<f32>"
  of "Vec4":    "vec4<f32>"
  of "Color":   "vec4<f32>"
  of "Image":   "texture_2d<f32>"
  of "TexData": "texture_2d<f32>"
  of "Sampler": "sampler"
  else: tname


#_______________________________________
# Validation: GPU types
#_____________________________
proc onlyGpuValues (T :typedesc) :bool=
  ## Checks that all fields of the type are GPU valid types.
  when T is SomeTexture: return true
  elif T is object:
    for field in default(T).fields:
      when field isnot SomeGpuType: return false
  elif T isnot SomeGpuType: return false
  result = true
proc onlyGpuValues [T](t :T) :bool=  t.typeof.onlyGpuValues
  ## Checks that all fields of the type are GPU valid types.
proc alignedTo (t1,t2 :typedesc) :bool=  (t1.sizeof mod t2.sizeof) == 0
  ## Checks that `t1` is aligned to the size of `t2`.
  ## TODO: NOTE: Should iterate over the fields of `t1` and check the offset of all of them against `t2`.

#_______________________________________
# Validation: User Code
#_____________________________
proc hasFrag (code :string) :bool=  ("@fragment" in code) and (&"fn {FragMain}" in code)
proc hasVert (code :string) :bool=  ("@vertex"   in code) and (&"fn {VertMain}" in code)
proc hasComp (code :string) :bool=  ("@compute"  in code) and (&"fn {CompMain}" in code)
template chk (code :string) :void=
  assert code.hasFrag, "The given wgsl code doesn't have a fragment function."
  assert code.hasVert, "The given wgsl code doesn't have a vertex function."

#_______________________________________
# Generation: Nim Type to wgsl
#_____________________________
proc genType (T :typedesc) :string=
  ## Returns the wgsl code for `T`.
  let tName = ($T).toWgpu
  assert T.alignedTo(Vec4), &"Type {$tName} is not aligned to the size of a Vec4 (required by wgpu)"
  let tab = "  "
  result.add &"struct {tName}" & " {\n"
  for field in default(T).fields:
    let fType = ($(field.type)).toWgpu
    let fName = field.name
    result.add &"{tab}{fName} :{fType},\n"
  result.add "}\n"
#_____________________________
proc genVariable (T :typedesc; gid,bid :int; space,varName :string) :string=
  ## Returns the wgsl code for a variable of type `T` and name `varName`, using the address `space`.
  let tName = ($T).toWgpu
  &"@group({$gid}) @binding({$bid}) var{space} {varName} :{tName};\n"
#_____________________________
proc genDataVar (T :typedesc; gid,bid :int; varName :string) :string=
  ## Returns the wgsl code for a Data variable of type `T` and name `varName`.
  result = T.genVariable(gid,bid, "<uniform>", varName)
#_____________________________
proc genVar (T :typedesc; gid,bid :int; varName :string) :string=
  ## Returns the wgsl code for a variable of type `T` and name `varName`.
  result = T.genVariable(gid,bid, "", varName)

#_______________________________________
# Generation: Nim Variable to wgsl RenderData code
#_____________________________
proc renderdata (T :typedesc; gid,bid :int; varName :string) :tuple[tcode: string, vcode: string]=
  ## Returns a string of Uniform wgsl code for the input `T`.
  assert T.onlyGpuValues, &"Type {$T} contains a field with a type that cannot be uploaded to the GPU. Only 32bit types are allowed."
  when T is SomeGpuType: result.tcode = NoTypeCode
  when T is object:
    result.tcode = T.genType
  result.vcode = T.genDataVar(gid,bid,varName)
#_____________________________
proc renderdata *[T](t :T; gid,bid :int; varName :string) :tuple[tcode: string, vcode: string]=
  ## Returns a string of Uniform wgsl code for the variable `t`.
  t.typeof.renderdata(gid,bid, varName)
#_____________________________
proc texdata *(t :TexData|Image|Sampler; gid,bid :int; varName :string) :tuple[tcode: string, vcode: string]=
  result.tcode = NoTypeCode
  result.vcode = t.type.genVar(gid,bid, varName)




#_____________________________
when isMainModule:
  echo "\nngpu: Starting wgsl code test...\n"
  var tstCode :string
  # Uniform Type registering test
  type Uniform * = object
    time  *{.align(16).}:float32
    color *{.align(16).}:Color
  tstCode.add Uniform.register()
  # Uniform Variable registering test
  var myUniform :Uniform ; tstCode.add myUniform.uniform(2,5)
  var myFloat   :float32 ; tstCode.add myFloat.uniform(3,0)
  var myInt     :int32   ; tstCode.add myInt.uniform(2,0)
  var myColor   :Color   ; tstCode.add myColor.uniform(1,1)
  # Correct Shader Code test
  tstCode.add """

@fragment fn frag() {}
@vertex fn vert() {}
  """; tstCode.chk
  echo tstCode

