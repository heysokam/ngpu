# ngpu : Native WebGPU library in Nim
Rendering library, targeting the design concepts of the WebGPU API.
Don't be fooled by the `web` part.  
This project's target is native gpu usage.  


## ngpu as a Graphics Library
ngpu is a cohesive graphics API layer, built on top of other tools.  

Not agnostic. Technically a renderer:  
- Goes beyond a raw wrapper, and takes assumptions on how rendering will be done.  
- Provides notions of data beyond what a pure API would.  
- Doesn't try to be agnostic or generalistic.  
- One single purpose: Tools to create a good modern renderer.  

Note: Modern means 2015+ hardware, not 2000's version of "modern".  
_Not looking at you, opengl3..._  

Not reinventing the wheel:  
`glfw`   for window creation  
`vmath`  for vector math  
`pixie`  for image loading  
`chroma` for colors  


## Current state and todo
See the [examples](./examples/todo.md) file and folder for a reference of the current state of the lib.  


## Syntax and usage
See the [examples](./examples/) folder for how the library is used.  
The library is built using the Nim `wgpu` wrapper. See the `heysokam/wgpu/examples` folder to get a feel of what the ngpu library is doing in the background.  


## wgpu vs Dawn
The WebGPU API is currently tied to a division between wgpu and Dawn.  
This means that, with time, either one or the other might (or might not) fall out of use.  
In the end, the goal of this library is to use the same API concepts that WebGPU uses for rendering.  

This lib is currently using wgpu-native as its WebGPU backend.  
Dawn support might (or might not) be implemented in the future, depending on how the situation evolves.  




## (TODO) Ideas ported from a previous OpenGL implementation
### Data and Config Defaults
- Vertex are expected in CCW order.  
- Backfaces are culled.  
- Color buffer is cleared at the start of each frame.  
  - Debug:   Will clear to Pure Magenta.  
  - Release: Will clear to 0.1gray.  
- Depth buffer is cleared at the start of each frame.  
- Shaders:
  - Read from `.vert`, `.frag`, `.tess` and `.comp` files.  
  - Name formatting:
    - Attributes:      `aTheName`
    - Uniforms:        `uTheName`
    - Vertex/Varyings: `vTheName`
    - Fragments:       `fTheName`

