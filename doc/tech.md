# Rendering: Techniques (tech) and Phases (phs)
This library uses the concept of `Rendering Technique`s, subdivided into `Phase`s to define rendering behavior.
The code for this is connected through the files @`ngpu/tech`.

## Overview
A technique defines a rendering style, which is made of one or more phases.  
Each phase can contain one or more passes, and each pass could execute one or more draw calls, depending on what data is given as input.  


## Base definitions:
**Technique**:
```md
Specific details related to the expression of a skill, craft or art style.
```
> Rendering Technique: Details related to achieving a specific Rendering Style.  

**Phase**:
```md
Particular stage or point in a recurring sequence of movement or changes
Each step of the sequence is introduced gradually as a separate stage of the process
```
> Rendering Phase: Individual step/stage in a rendering technique sequence.  

**Pass**:
Individual step in a rendering Phase.  
The whole scene (one or many objects), is rendered to the screen.  

**Draw Call**:
Individual order to the GPU to draw a single set of geometry.  
This could be batched geometry, instanced objects or a single-object.  

## Explanation
Typically, a technique is limited to a simpler concept, with one or two rendering methods included in them.
This library has extended the meaning of the word to, instead, refer to what someone could call Rendering `Style`, `Category`, or `Group/Set of techniques`.

**Examples:**
1. Simple technique: The process required to create Blinn-Phong rendering
2. Advanced techniques could be Deferred rendering, VoxelConeTracing, etc
3. Adding post-processed Cel-Shading to a Phong pipeline would result in a different tech
  _(notice how the culture would consider these two things in example#3 to be separate techniques, but this library considers them to be one technique composed of two different phases)_

Hello Triangle:
- Technique:  Render vertices to the screen with a hardcoded color, without any shading.  
- Phases:     One. Just draw everything to the color buffer, with no depth clear.  
- Passes:     One. Draw a single triangle to the screen.  
- Calls:      One. Draw three vertex positions, sorted by their indices.  
Deferred Rendering:
- Technique:  Deferred rendering, multiple dynamic lights, no GI, Diffuse materials only, no transparency.
- Phases:     Generate the G buffer. Draw the lights.
- Passes:     Inside the G buffer phase: Depth map pass, normal map pass, diffuse map pass (could result in a single call per object when using MRT). 
- Calls:      Inside one of the passes: One Call. Draw the vertex positions of the triangle.

As such, a `Rendering Technique` can be thought of as representing the entirety of a single rendering path of an engine.

The goal of this feature is to be able to draw with different rendering styles, without having to rewrite or refactor the whole rendering code.
This means:
- Being able to draw some objects with one technique, and others with a different one, at the same time into the screen.
- Switch comfortably between one technique and another one, as long as the assets being rendered have the data required for both.

Imagine these objects:  
- Object One:    contains PBR mrao texture-based materials.  
- Object Two:    contains Blinn-Phong number-based materials.
- Object Three:  contains Cel-shaded Blinn-Phong texture-based materials.
How do you draw them all in the same scene, assuming that your rendering code only supports a hardcoded combination of uniforms+shaders?

When you offload this problem to the application, by keeping the rendering API agnostic and not providing any type of abstraction over the renderer architecture, you end up with applications that demand a much much higher base skill level to setup and run with just the bare minimum defaults.  
Offloading the responsibility is a fair solution, but if the renderer was more concise in how data is meant to be sent and processed, then this weight wouldn't need to be sent to the application and could stay on the renderer side. Without losing any of its configurability or power in the process.  

By creating a way to handle the use of different `RenderTech`s for different `RenderMesh`es, this issue is solved.  
Applications, then, can implement their own `RenderTech` code without issues if they need them, and still be able to use the rest of the library as normal.  

Another potential solution would be to separate the objects into different types, depending on the way the will be drawn. But then, in order to support new rendering types, the library would need to be rewritten to accommodate for these new types of data. And all its flexibility would be gone.  
This could be a fair solution when offloading the drawing itself to the app, since data drawn in this way would be very much application-dependent. But, like mentioned, this would raise the baseline skill-level required to use the app by a long shot, it wouldn't really be flexible anymore... or would need to become a renderer-agnostic API to solve the problem, which is not the goal of this library.  

