#:____________________________________________________
#  ngpu  |  Copyright (C) Ivan Mar (sOkam!)  |  MIT  |
#:____________________________________________________
# External dependencies
import wgpu
# n*dk dependencies
import nstd/types as base
# n*gpu dependencies
import ../../types as ngpu
import ../../element/shader

#___________________
const Code * = """
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
  var out   :VertOut;
  out.pos   = vec4<f32>(in.pos, 1.0);
  out.color = in.color;  // Forward the color attribute to the fragment shader
  out.uv    = in.uv;     // Forward the texture coordinates to the fragment shader
  out.norm  = in.norm;   // Forward the vertex normal to the fragment shader
  return out;
}

@fragment fn frag(in :VertOut) ->@location(0) vec4<f32> {
  return vec4<f32>(in.color);
}
"""  ## Fallback shader code used by the Simple Technique, when nothing else is given

#___________________
proc get *(device :ngpu.Device;
    _      : typedesc[Shader];
    code   : str = Code;
    file   : str = NoFile;
    label  : str = "ngpu | Tech.Simple Shader";
  ) :Shader=
  ## Creates a Shader for the Simple Technique.
  result = Shader.new(
    device = device,
    label  = label,
    code   = code,
    file   = file,    )

