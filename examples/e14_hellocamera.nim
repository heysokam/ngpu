#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# Minimal Camera controller                         |
# Vertex colored cube,                              |
# with perspective and WASD+Mouse camera movement.  |
#___________________________________________________|
# std dependencies
import std/strformat
import std/sequtils
# n*dk dependencies
import nstd
import nmath
# n*gpu dependencies
import ngpu
# Examples dependencies
import ./cfg
import ./state as e
import ./extras  # These should be coming from external libraries instead.


#_____________________________
# input.nim
#___________________
from nglfw as glfw import nil
var i :Inputs  # Inputs state
#__________________
proc key (win :glfw.Window; key, code, action, mods :cint) :void {.cdecl.}=
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
proc mousePos *(window :glfw.Window; xpos, ypos :float64) :void {.cdecl.}=
  ## GLFW Mouse Position Input Callback
  let chg = vec2(
    xpos.float32 - i.cursor.pos.x,
    ypos.float32 - i.cursor.pos.y,
    )  # Current - previous
  if chg < vec2(10,10): i.cursor.chg += chg  # Accumulate multiple events across the same frame
  i.cursor.pos = vec2(xpos, ypos)            # Store current x,y
#__________________
proc inputUpdate *() :void=  glfw.pollEvents()
  ## Orders GLFW to check for input updates.

#________________________________________________
# camera.nim
#__________________
const spd = 0.125'f
proc update (cam :var Camera) :void=
  # WASD movement
  if i.fw:  cam.move(cam.dir   * -spd)
  if i.bw:  cam.move(cam.dir   *  spd)
  if i.lf:  cam.move(cam.right * -spd)
  if i.rt:  cam.move(cam.right *  spd)
  # Mouse control
  cam.rotate(i.cursor.chg)
  i.cursor.chg = vec2(0,0) # Reset after each frame


#__________________
# Dependencies specific to this example
import ngpu/tech/shared/gen
from   ngpu/element/window import ratio

#_____________________________
# Shader code
#   The `u` variable and its struct type are generated by ngpu,
#   by registering our Uniforms variable.
#   Their code will be automatically added at the top of our shader.
#   Its fields and type will have the same names as our Nim object.
#__________________
type Uniforms = object          # Our uniform value is a struct. All fields must be aligned to the size of a Vec4 (aka 16)
  W      {.align(16).}:Mat4     # Local-to-World matrix
  V      {.align(16).}:Mat4     # World-to-View matrix
  P      {.align(16).}:Mat4     # View-to-Projection matrix
  time   {.align(16).}:float32  # Time in seconds
  color  {.align(16).}:Color    # Uniform color

var u = Uniforms(
  time  : glfw.getTime().float32,
  color : color(0,1,0,1),
  ) # << Uniforms( ... )
# Generate a fully white Image for the texture
let pix = newSeqWith[ColorRGBX](512*512, color(0,1,1,1).rgbx())
var img = Image(width:512, height:512, data:pix)
#__________________
const shaderCode = """
// We now have access to the sampler in the fragment stage, with the name that we specify  (aka "texSampler")
// We have access to the texture in the fragment stage, with the name that we specify  (aka "tex").
// The Uniforms struct variable "u" will also be available.

struct VertIn {
  @builtin(vertex_index) id :u32,
  @location(0) pos   :vec3<f32>,
  @location(1) color :vec4<f32>,
  @location(2) uv    :vec2<f32>,
  @location(3) norm  :vec3<f32>,
}
struct VertOut {
  @builtin(position) pos   :vec4<f32>,
  @location(0)       color :vec4<f32>,
  @location(1)       uv    :vec2<f32>,
  @location(2)       norm  :vec3<f32>,
}
@vertex fn vert(in :VertIn) ->VertOut {
  // Add the uniform variable to the position of this vertex
  let offset = 0.3 * vec3<f32>(cos(u.time), sin(u.time), 0.0);  // Calculate the (x,y) offset
  let pos    = in.pos + offset;                                 // Move the vertex position using the offset
  // Define the output of the vertex shader
  var out   :VertOut;
  out.pos   = u.P * u.V * u.W * vec4<f32>(in.pos, 1.0);
  out.color = in.color;  // Forward the color attribute to the fragment shader
  out.uv    = in.uv;     // Forward the texture coordinates to the fragment shader
  out.norm  = in.norm;   // Forward the vertex normal to the fragment shader
  return out;
}

@fragment fn frag(in :VertOut) ->@location(0) vec4<f32> {
  return textureSample(texPixels, texSampler, in.uv);
}
"""

import ngpu/tech/shared/data # TODO: This should be imported auto, but missing RenderData.new( ... )

#________________________________________________
# Entry Point
#__________________
proc run=
  echo cfg.Prefix&" | Hello Camera"
  #__________________
  # Init the window+input and Renderer
  e.sys    = nsys.init(cfg.res, title = cfg.Prefix&" | Hello Camera") # << state.sys.init()
  e.render = ngpu.new(Renderer, system = e.sys, label = cfg.Prefix) # << state.render.init()
  #__________________
  # NEW:
  # 1. Create the camera
  cam = Camera.new(
    origin = vec3(0,-1,-6),
    target = vec3(1,-1, 1),
    up     = vec3(0, 1, 0),
    fov    = 45.0,  # 90 degree vertical fov
    near   = 0.1,
    far    = 100.0,
    )
  # 2. Generate the camera transform matrix (WVP)
  u.W = mat4()                            # Identity matrix for the Model-to-World conversion of our cube coordinates
  u.V = cam.view()                        # Get the view matrix from the camera
  u.P = cam.proj(e.render.sys.win.ratio)  # Get the proj matrix from the camera, based on the current screen size
  #__________________
  # Init the Data, Mesh and Technique
  var texture = e.render.new(Texture, img, "texPixels", "texSampler")  # Create the Texture     (sampled with default settings)
  var uniform = e.render.new(RenderData[Uniforms], u, "u")             # Create the RenderData  (aka uniform)
  var cube    = e.render.new(RenderMesh, gen.cube())                   # Create the RenderMesh
  var tech    = e.render.init(Tech.Simple,
    code = shaderCode,
    data = (uniform,texture).mvar, # The simple tech only accepts a tuple of Group.global data
    ) # << Tech.Simple.init( ... )
  e.render.upload(cube)
  # Explicit upload step. Could be done when creating the objects (with upload = true)
  e.render.upload(texture)
  e.render.upload(uniform)
  #__________________
  # Update loop
  while not e.sys.close():
    e.sys.update()
    # 3. Update the camera at the beginning of the frame
    inputUpdate()   # Camera needs updated inputs for this frame  (should be coming from ndk/nin)
    e.cam.update()  # Update the camera properties
    # Update the uniform contents
    u.V    = cam.view()                        # Get the view matrix from the camera
    u.P    = cam.proj(e.render.sys.win.ratio)  # Get the proj matrix from the camera, based on the current screen size
    u.time = glfw.getTime().float32
    e.render.update(uniform, u)
    # Render this mesh, with this style
    e.render.draw(cube, tech)  # (note: uses any global data contained in the style)
  #__________________
  # Terminate
  e.render.term()
  e.sys.term()


#________________________________________________
when isMainModule: run()

