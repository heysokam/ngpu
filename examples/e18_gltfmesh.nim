#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# glTF Mesh Example                              |
# Draws a single gltf mesh using Tech.Simple     |
#________________________________________________|
# std dependencies
import std/os
import std/sequtils
# n*dk dependencies
import nstd
import nmath
import nsys
from   nglfw as glfw import nil
import nimp/mdl
# n*gpu dependencies
import ngpu
# Examples dependencies
import ./types
import ./cfg
import ./state as e
import ./extras  # These should be coming from external libraries instead.


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
const MeshFile = Path currentSourcePath().parentDir()/"mdl"/"bottle"/"bottle.gltf"


#________________________________________________
import ngpu/tech/shared/data # TODO: This should be imported auto, but missing RenderData.new( ... )
#________________________________________________



#________________________________________________
# Entry Point
#__________________
proc run=
  echo cfg.Prefix&" | Hello glTF-Mesh"
  #__________________
  # Init the window+input and Renderer
  e.sys = nsys.init(cfg.res, cfg.Prefix&" | Hello glTF-Mesh",
    key          = keyCB,
    mousePos     = mousePosCB,
    mouseCapture = on,
    ) # << state.sys.init()
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
  u.W = mat4()                     # Identity matrix for the Model-to-World conversion of our cube and pyramid coordinates
  u.V = cam.view()                 # Get the view matrix from the camera
  u.P = cam.proj(e.sys.win.ratio)  # Get the proj matrix from the camera, based on the current screen size
  #__________________
  # Init the Data, Mesh and Technique
  var texture = e.render.new(Texture, img, "texPixels", "texSampler")  # Create the Texture     (sampled with default settings)
  var uniform = e.render.new(RenderData[Uniforms], u, "u")             # Create the RenderData  (aka uniform)
  var model   = mdl.load(MeshFile)                                     # Load the glTF file
  var mesh    = e.render.new(RenderMesh, model[0])                     # Create the glTF RenderMesh
  var tech    = e.render.init(Tech.Simple,
    code = shaderCode,
    data = (uniform,texture).mvar, # The simple tech only accepts a tuple of Group.global data
    ) # << Tech.Simple.init( ... )
  e.render.upload(mesh)  # Upload the mesh to the GPU
  # Explicit upload step. Could be done when creating the objects (with upload = true)
  e.render.upload(texture)
  e.render.upload(uniform)
  #__________________
  # Update loop
  while not e.sys.close():
    e.sys.update()
    # 3. Update the camera at the beginning of the frame
    e.cam.update()  # Update the camera properties
    # Update the uniform contents
    u.V    = cam.view()                        # Get the view matrix from the camera
    u.P    = cam.proj(e.render.sys.win.ratio)  # Get the proj matrix from the camera, based on the current screen size
    u.time = glfw.getTime().float32
    e.render.update(uniform, u)
    # Render these meshes, with this style
    e.render.draw(mesh, tech)  # (note: uses any global data contained in the style)
  #__________________
  # Terminate
  e.render.term()
  e.sys.term()


#________________________________________________
when isMainModule: run()

