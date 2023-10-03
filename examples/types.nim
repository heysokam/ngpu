# n*dk dependencies
import nmath

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
