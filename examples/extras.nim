#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# n*dk dependencies
import nmath ; export nmath
import nsys  ; export nsys

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


#__________________________________________________
# Input system    : Should be coming from ndk/nin
#____________________
type Cursor * = object
  pos*, chg* :Vec2
type Inputs * = object
  fw*,bw*,lf*,rt* :bool
  cursor*         :Cursor


#__________________________________________________
# Camera    : Should be coming from ndk/ncam
#____________________
type Camera * = object
  # Note: pos/rot/up should be a Transform instead.
  pos   *:Vec3     ## Position / Origin point of the camera
  rot   *:Vec3     ## X/Y/Z angles of rotation (pitch, yaw, roll)
  up    *:Vec3     ## Up direction for the camera (in world space)
  fov   *:float32  ## fov Y angle in degrees (vmath format)
  near  *:float32  ## Nearest  distance that the camera can see
  far   *:float32  ## Farthest distance that the camera can see

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

