

#_____________________________
# wgsl test
when isMainModule:
  type Uniform = object
    v :float32
  var u :Uniform
  echo wgsl.uniform(u)

