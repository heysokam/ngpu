#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# std dependencies
import std/strformat
# n*dk dependencies
import nmath ; export nmath
import nsys  ; export nsys
# Examples dependencies
import ./types as ex
import ./state as e


#_______________________________________
# Math    : Should be coming from ndk/nmath
#_______________________________________
# wgpu : Coordinate Systems
#_____________________________
# NDC: normalized device coordinates
#   +X right, +Y up, +Z forward
#   (-1.0, -1.0) is the bottom-left corner
#   x,y : range[-1.0..1.0] inclusive
#   z   : range[ 0.0..1.0] inclusive
# Vertices out of this range will not introduce any errors, but will be clipped.
#_______________________________________
# Framebuffer Coordinates:
# - Start from the top-left corner of the render targets.
# - Each unit corresponds exactly to a pixel.
# - +Y-axis is down
# Window/present Coordinates:         Both match Framebuffer coordinates.
# Viewport and Fragment Coordinates:  origin(0, 0) is at the top-left corner
# Texture Coordinates:                UV origin(0, 0) is the first texel (the lowest byte) in texture memory.
# Matrices:                           Column major storage, you specify columns in matrix constructors
#_______________________________________
# Differences from OpenGL:
# 1. 3x3 matrices are padded to 4x4 
# 2. +Z is forward, instead of backwards (away from the screen)
# 3. Depth range of NDC is 0..1, instead of -1..1
#_______________________________________
# std/math : Extensions
const Epsilon :float32= 0.0001
template `/` *(a,b :uint64) :float32=  a.float32 / b.float32
proc clamp *(n :var SomeFloat; lo,hi :SomeFloat) :void=
  ## Restricts the given number to be between low and high.
  if n < lo: n = lo  elif n > hi: n = hi
#_____________________________
# wgpu : Matrices
const wgpuMat4 = mat4(
  ## Conversion matrix from OpenGL's Z[-1..1] to WebGPU's Z[0..1]
  1.0, 0.0, 0.0, 0.0,
  0.0, 1.0, 0.0, 0.0,
  0.0, 0.0, 0.5, 0.0,
  0.0, 0.0, 0.5, 1.0,
  )
const glMat4 = mat4(
  ## Conversion matrix from WebGPU's Z[0..1] to OpenGL's Z[-1..1]
  1.0, 0.0,  0.0, 0.0,
  0.0, 1.0,  0.0, 0.0,
  0.0, 0.0,  2.0, 0.0,
  0.0, 0.0, -1.0, 1.0,
  )
proc toWgpu *[T](proj :GMat4[T]) :GMat4[T]=  proj*wgpuMat4
  ## Converts an OpenGL.projection to a WebGPU.projection matrix
proc toGL   *[T](proj :GMat4[T]) :GMat4[T]=  proj*glMat4
  ## Converts a WebGPU.projection to an OpenGL.projection matrix
#_____________________________
# vmath extensions
proc `<` *[T](v1,v2 :GVec2[T]) :bool=  v1.length < v2.length


#________________________________________________
# camera.nim
#__________________
const SafePitch = Tau-Epsilon
#____________________
proc new *(_ :typedesc[Camera]; origin, target, up :Vec3; fov, near, far :float32) :Camera=
  result.rot  = origin.lookAt(target, up).angles
  result.pos  = origin
  result.up   = up
  result.fov  = fov
  result.near = near
  result.far  = far 
#____________________
proc init *(cam :var Camera; origin, target, up :Vec3; fov, near, far :float32) :void=
  cam = Camera.new(origin, target, up, fov, near, far)
#__________________________________________________
proc reset *(cam :var Camera; pos :Vec3) :void=
  cam.pos    = pos
  let target = vec3(0,0,0)
  let up     = vec3(0,1,0)
  cam.rot    = cam.pos.lookAt(target, up).angles

#____________________
proc view  *(cam :Camera) :Mat4=  inverse(cam.pos.translate * cam.rot.fromAngles)
proc dir   *(cam :Camera) :Vec3=  cam.view.forward
proc right *(cam :Camera) :Vec3=  cam.view.left

#____________________
proc proj *(cam :Camera; ratio :float32) :Mat4=
  perspective(cam.fov, ratio, cam.near, cam.far).toWgpu

#____________________
proc move *(cam :var Camera; vel :Vec3) :void=
  cam.pos = cam.pos + vel
#____________________
proc rotate *(cam :var Camera; chg :Vec2) :void=
  const scale :float32= TAU * 0.00005
  cam.rot.x += chg.y * -scale                        # Y movement = Rotation around X
  cam.rot.y += chg.x * -scale                        # X movement = Rotation around Y
  cam.rot.x.clamp(-SafePitch, SafePitch) # Clamp vertical rotation to never reach the top or bottom

#____________________
const spd = 0.125'f
proc update *(cam :var Camera) :void=
  # WASD movement
  if i.fw:  cam.move(cam.dir   * -spd)
  if i.bw:  cam.move(cam.dir   *  spd)
  if i.lf:  cam.move(cam.right * -spd)
  if i.rt:  cam.move(cam.right *  spd)
  # Mouse control
  cam.rotate(i.cursor.chg)
  i.cursor.chg = vec2(0,0) # Reset after each frame


#_____________________________
# input.nim
#___________________
from nglfw as glfw import nil
#__________________
proc keyCB *(win :glfw.Window; key, code, action, mods :cint) :void {.cdecl.}=
  ## GLFW Keyboard Input Callback
  let hold = action == glfw.Press or action == glfw.Repeat
  let rls  = action == glfw.Release
  if key == glfw.KeyEscape and action == glfw.Press:
    glfw.setWindowShouldClose(win, true)
  # Input manager: Update state
  case key
  of glfw.KeyW:
    if hold: i.fw = true elif rls: i.fw = false
  of glfw.KeyS:
    if hold: i.bw = true elif rls: i.bw = false
  of glfw.KeyA:
    if hold: i.lf = true elif rls: i.lf = false
  of glfw.KeyD:
    if hold: i.rt = true elif rls: i.rt = false
  of glfw.KeySpace:
    if action == glfw.Press: echo &"pos:{cam.pos}  trg:{cam.dir}"
  else: discard
#__________________
proc mousePosCB *(window :glfw.Window; xpos, ypos :float64) :void {.cdecl.}=
  ## GLFW Mouse Position Input Callback
  let chg = vec2(
    xpos.float32 - i.cursor.pos.x,
    ypos.float32 - i.cursor.pos.y,
    )  # Current - previous
  if chg < vec2(10,10): i.cursor.chg += chg  # Accumulate multiple events across the same frame
  i.cursor.pos = vec2(xpos, ypos)            # Store current x,y

