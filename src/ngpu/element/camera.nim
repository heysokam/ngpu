#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________



# TODO



#____________________
# types
#_____________________________________________________
# n*dk dependencies
import nstd/types as base
import nmath

#____________________
type Camera * = object
  # Note: pos/rot/up should be a Transform instead.
  pos   *:DVec3  ## Position / Origin point of the camera
  rot   *:DVec3  ## X/Y/Z angles of rotation (pitch, yaw, roll)
  up    *:DVec3  ## Up direction for the camera (in world space)
  fov   *:f64    ## fov Y angle in degrees (vmath format)
  near  *:f64    ## Nearest  distance that the camera can see
  far   *:f64    ## Farthest distance that the camera can see

const SafePitch = Tau-Epsilon




#____________________
# camera.nim
#_____________________________________________________
# n*dk dependencies
import nstd/types as base
import nmath

proc new *(_ :typedesc[Camera]; origin, target, up :DVec3; fov, near, far :f64) :Camera=
  result.rot  = origin.lookAt(target, up).angles
  result.pos  = origin
  result.up   = up
  result.fov  = fov
  result.near = near
  result.far  = far 
#____________________
proc init *(cam :var Camera; origin, target, up :DVec3; fov, near, far :f64) :void=
  cam = Camera.new(origin, target, up, fov, near, far)
#__________________________________________________
proc reset *(cam :var Camera; pos :DVec3) :void=
  cam.pos    = pos
  let target = dvec3(0,0,0)
  let up     = dvec3(0,1,0)
  cam.rot    = cam.pos.lookAt(target, up).angles

#____________________
proc view  *(cam :Camera) :DMat4=  inverse(cam.pos.translate * cam.rot.fromAngles)
proc dir   *(cam :Camera) :DVec3=  cam.view.forward
proc right *(cam :Camera) :DVec3=  cam.view.left

#____________________
proc proj *(cam :Camera; ratio :f64) :DMat4=
  perspective(cam.fov, ratio, cam.near, cam.far).toWgpu

#____________________
proc move *(cam :var Camera; vel :DVec3) :void=
  cam.pos = cam.pos + vel
#____________________
proc rotate *(cam :var Camera; chg :DVec2) :void=
  const scale = TAU * 0.00005
  cam.rot.x += chg.y * -scale  # Y movement = Rotation around X
  cam.rot.y += chg.x * -scale  # X movement = Rotation around Y
  cam.rot.x.clamp(-SafePitch, SafePitch) # Clamp vertical rotation to never reach the top or bottom

