# n*gpu | Graphics Library for Nim
![ngpu](./doc/res/gh_banner.png)
Rendering library, targeting the design concepts of WebGPU-native.  
_Don't be fooled by the `web` part. This project's target is native gpu usage._  


## ngpu as a Rendering Library
ngpu is a cohesive graphics library, built on top of other tools.  

Not agnostic. Technically a renderer:  
- Makes assumptions on how rendering will be done.  
- Provides notions of data beyond what a pure API would.  
- Doesn't try to be agnostic or generalistic.  
- One single purpose: Tools to create a good modern renderer.  

_Note: Modern means 2015+ hardware, not 2000's version of "modern"._  
_Not looking at you, opengl3..._  

```md
# Not reinventing the wheel:
`wgpu`   for graphics api
`glfw`   for window creation
`gltf`   for 3D models
`vmath`  for vector math
`pixie`  for image tools
`chroma` for colors tools

# Build requirements
rust : For building wgpu-native
nim  : For building and running the code
```

## Current state and todo
See the [examples](./examples) folder for a reference of the current state of what the library can do.  
The file @[roadmap.md](./doc/roadmap.md) has a list of the features that will be implemented.

## Syntax and usage
See the [examples](./examples/) folder for how the library is used.  
Each example is incrementally more complex than the previous one.  

The basic examples follow the structure of [Learn WebGPU C++](https://eliemichel.github.io/LearnWebGPU/), which I highly recommend for learning the WebGPU-based APIs.  
The advanced ones are modeled after the [webgpu-native-examples](https://github.com/samdauwe/webgpu-native-examples#Basics) repository.

If you are familiar with `vulkan.hpp` and `vk-bootstrap`, ngpu offers a lot of similarities for initializing wgpu.  
If you only use the constructor procs, the API will be similar to theirs.  
But then ngpu goes far beyond that boilerplate reduction step, and actually implements renderer features with its `RenderTech` logic,  
which can also be expanded with your own rendering logic/features if you need them.  

### Configurability
ngpu is very configurable, as long as you use the provided tools/paradigms.

#### Data and Config Defaults
Most data and setup options are dependent on each Render Technique.  
You can see a list of the implied defaults @[config.md](doc/config.md) doc file.

#### Custom options
All of the initializer variables have customizable inputs, with sane defaults for when they are omitted.
Also, all of the elements have a `Type.new( ... )` function, that takes as many options as its technically possible to do so within the bounds of the library.  
If you create your own functions to do the rendering logic, you can customize basically everything.  

#### Custom Shaders
Shader uniforms are allowed to be custom types.  
You only need to register them using the provided ngpu function for it, and the variable and its data will be accesible in your shader code.
A more in-depth explanation can be found @[shaders.md](./doc/shaders.md) doc file.  

#### Custom Techniques
Every Rendering style has a unique set of properties and requirements _(what this lib calls a `Technique`)_.
Each specific Technique requires its unique own set of Pipelines, Buffers, data formats, etc, etc.  
It would be mental to create an API that could handle all of it without any assumptions _(plus that's essentially what wgpu itself is...)_.  
As such, the chosen way to configure the Rendering, beyond what's already supplied, is through the creation of new RenderTech logic.  
You can find reference implementations of this in the [ngpu/tech](./src/ngpu/tech/) folder.  
And an explanation of what they conceptually are @[tech.md](./doc/tech.md) file.  


## ngpu vs wgpu
ngpu is an abstraction built with `wgpu-native`, with the wrapper at [heysokam/wgpu](https://github.com/heysokam/wgpu).
Its internal structure is a rendering library, not a raw API.  
As such, some wgpu conventions have been changed to fit its goals.  
You can find more information about this in the [internal.md](doc/internal.md) doc file.


## wgpu vs Dawn
The WebGPU API is currently tied to a division between wgpu and Dawn.  
This means that, with time, either one or the other might (or might not) fall out of use.  
In the end, the goal of this library is to use the same API concepts that WebGPU uses for rendering.  

This lib is currently using wgpu-native as its WebGPU backend.  
Dawn support might (or might not) be implemented in the future, depending on how the situation evolves.  

