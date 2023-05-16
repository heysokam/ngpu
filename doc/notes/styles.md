# NPR
Photo-realism can be achieved with the modern pipeline and tools provided by the library.
The library targets Non-Photo-Realism (NPR) first, but this is not a hardcoded rule.
- [ ] Cel-shading
- [ ] PSX-style shading
- [ ] High quality LowPoly NPR
  This tech aims to bring the highest and most modern lighting tech possible to the world of stylized low poly rendering.
  In this context, LowPoly does not mean the use of optimized assets to achieve Photo-Realism.
- [ ] 2D simulation with 3D

## Goals
Top1 Priority: https://www.youtube.com/watch?v=RpH851L0SCU
- Low poly
- Emissive Materials
- Sprite effects
- Real Time Global Illumination
- Volumetric Light
- Cel shader
- Compute-based occlusion-culling
- Edge detection https://www.youtube.com/watch?v=E9-LRRDVmo8
- Remember: Tech Masterpiece: https://www.youtube.com/watch?v=MC-hiXr69kY

## To explore:
- Gooch shading
- Anisotropic Kuwahara filter: https://www.youtube.com/watch?v=LDhN-JK3U9g
- PS1 look
  - Limited color palette
  - Dithering
  - Downsampling   (first sharpen, then downsample / pixelize)
  - Edge wobble
  - https://www.youtube.com/watch?v=8wOUe32Pt-E
  - (note) black and white :O
- Pixelized 3D: https://www.youtube.com/watch?v=8wOUe32Pt-E
- Unlit / baked: https://www.youtube.com/watch?v=ESXAxtdEkzY

## Cel shader
basic ogldev: https://www.youtube.com/watch?v=h15kTY3aWaY&list=PLA0dXqQjCx0S04ntJKUftl6OaOgsiwHjA&index=30
pro: https://www.youtube.com/watch?v=yhGjCzxJV3E

## Post process
pro chain: https://www.youtube.com/watch?v=FMfC47xsImU

# Deferred rendering and GI
1. learnopengl & nimfort : https://github.com/anossov/nimfort
2. vis buffer :  https://jcgt.org/published/0002/02/04/
3. forward+   :  https://simoncoenen.com/blog/programming/graphics/DoomEternalStudy
   teardown   :  voxel based world talk

## GI
voxel GI   :  https://github.com/jose-villegas/VCTRenderer
https://www.youtube.com/watch?v=9d_0YcEueOo
SDFGI      :  Signed distance field global illumination

# Compute shader culling:
- Start:  https://learnopengl.com/Guest-Articles/2021/Scene/Frustum-Culling
- how to write a compute shader
  https://www.youtube.com/watch?v=EB5HiqDl7VE
- how indirect multidraw works
- implement the actual culling algorithm
main: https://www.nickdarnell.com/hierarchical-z-buffer-occlusion-culling/
https://community.khronos.org/t/vulkan-vs-multidrawindirect/6897
https://vkguide.dev/docs/gpudriven/compute_culling/#occlusion-culling
https://www.youtube.com/watch?v=EB5HiqDl7VE
https://github.com/JuanDiegoMontoya/Fwog/blob/examples-refactor/example/05_gpu_driven.cpp
high-skill: https://www.youtube.com/watch?v=0DLOJPSxJEg
https://www.youtube.com/watch?v=eDLilzy2mq0
- other:
  https://www.gamedeveloper.com/programming/occlusion-culling-algorithms
  https://interplayoflight.wordpress.com/2017/11/15/experiments-in-gpu-based-occlusion-culling/
  https://github.com/JuanDiegoMontoya/Gengine/blob/master/data/game/Shaders/compact_batch.cs.glsl
- new tech. Requires 2017+ cards
  https://github.com/nvpro-samples/gl_vk_meshlet_cadscene
  https://developer.nvidia.com/blog/introduction-turing-mesh-shaders/
  https://github.com/microsoft/directx-graphics-samples/blob/master/Samples/Desktop/D3D12MeshShaders/src/MeshletCull/readme.md

## Vegetation
instanced billboards: https://www.youtube.com/watch?v=Y0Ko0kvwfgA



<!--__________________________________________________________________________________________
# Notes, Learning

# Raytraced vs deferred
s: are raytracing techniques exclusive to rtx-allowed cards, or are they separate things?
   wondering if im a victim to noob-level marketing ignorance, and im confusing terms, or if that's actually true and raytracing cannot be used outside of specially crafted gpus 🤔
j: Anything that support DXR can run hardware accelerated RT with both DX12U & Vk. Some pre-DXR cards can run a software emulation layer for very slow software RT using the same API as hardware RT (higher end Pascal cards certainly can, which is how they run eg Quake RTX despite not having the hardware).
   AMD RDNA2/3, Intel Alchemist, & nVidia Turing/Ampere/Ada all support hardware RT.

s: is that the same for opengl?
j: There is no hardware RT API for OpenGL (not even a vendor extension). Many of the other DX12U features (mesh shaders, VRS, etc) did get ported back to OpenGL but you need Vk or DX12U for hardware RT. https://developer.nvidia.com/vulkan-turing 

s: i assume rt techniques will be out of the question if i want to target opengl with no hardware rt support?
j: Lots of things use software RT. SSAO is just tracing short rays from the pixel point in a hemisphere into the depth buffer to find collisions & darken the scene. But it's all running as pixel or compute shaders & there is no hardware accelerating any of the ray intersection tests or helping generating BVH representations of the scene.
   That hardware acceleration (usually tied to using a BVH to optimise the throwing rays into your scene) is what you don't get with OpenGL unless you build a Vk interpo. You have to write your own ray intersection code & run them as normal shaders. 

s: does this have anything to do with deferred vs forward rendering?
   from my noob pov, deferred looks like the way i would aim to do things, but don't know how it ties into this concept you explain
j: Deferred is just rendering the non-lit scene data first (into a g-buffer) then doing lighting as a second pass (where you have all the info waiting for you & don't overdraw with expensive lighting calculations because you've already done a full visibility pass laying down your g-buffer). 
   Forward is doing the lighting calculation at the same time as drawing the triangles (so if you happen to draw one triangle then later render another triangle over the top of it, you may have already finished shading the final value for a pixel you ultimately don't use). it's orthogonal to RT. 

s: I was looking into this article/renderer, that looked the most promising of what i found
   Does it fit what you described? https://github.com/jose-villegas/VCTRenderer 
   Its definitely out of my currently skill level, so I get a bit lost in the details at the moment. But the idea is to have a long term plan, and just be moving in the right direction. Hence the Q
j: Normally when you say deferred rendering, it means the 2D process (the step 1 voxelization that link describes, but just a 2D frame). Using a 3D voxel volume like that is definitely quite an advanced technique.
   I would not assume that your real-time GI technique needs to be tied to your deferred/forward rendering choice.
   Forward with a depth pre-pass or visibility buffer is not uncommon for modern Forward+ (which basically takes Forward then makes it work rather well for lots of lights by cutting the scene up & making buckets of light that contribute to each bucket) and provides much of the benefit of deferred in having a cheap depth result very early in the frame.
   See modern Doom for how much pre-pass stuff you may be doing for a Forward+ renderer today (if you're using upscaling or motion blur then you'll be generating eg motion vectors for that, so you're doing work to create secondary buffers even in Forward). https://simoncoenen.com/blog/programming/graphics/DoomEternalStudy
-->
