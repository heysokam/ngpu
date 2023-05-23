# Changes from wgpu to ngpu:
- `ngpu.RenderTarget` is conceptually the same as a `wgpu.RenderPass`, but contains more data (like the textures it draws into).
- `ngpu.RenderPass` is a new concept. Its the smallest part of a `RenderTech`. (see the [tech doc](./tech.md) file for an explanation)

Buffer operations:
- upload     : Copies the CPU.data of a Buffer into its GPU memory.            (called `write` in wgpu)
- transfer   : Copies the GPU.data of Buffer into another Buffer.              (called `copy`` in wgpu)
- connect    : Allows the GPU.data of a buffer to be accessible from the CPU.  (called `map` in wgpu)
- disconnect : Opposite action of connect.                                     (called `unmap` in wgpu)
- getData    : Returns a CPU copy of the GPU.data, without storing it in Buffer.CPU.data  (called `getMappedRange` in wgpu)
- download   : Copies the GPU.data of a Buffer into its CPU memory. Triggers a sync operation.
- copy       : Copies both GPU/CPU.data of a buffer into another. Like transfer, but for both sides of the data.
- clone      : Creates a duplicate of a Buffer in its current state (both its GPU/CPU data).  (also called `deepcopy` in the programming culture)


# Internal Structure of the Elements
The wgpu/Dawn/WebGPU API defines each element used for drawing as an opaque pointer.
They are configured used what's called `Descriptor`s, which are the same in concept as the ones in Vulkan.
This library merges both into a single object, containing:
- `Thing.ct`    : The context (or content) of the object. Aka, the opaque pointer itself.
- `Thing.cfg`   : The configuration information. Aka, the Descriptor
- `Thing.label` : A recognizable string used for debugging and logging messages. They can also be found when debugging with RenderDoc, since they are used by wgpu to generate the names of the objects.

Some elements contain other content, when said content is technically "linked" to the element itself as an idea.
Examples of this can be:
- The device.queue being inside the device
- The adapter.surface being part of the adapter
Instead being separate objects by themselves, they are stored inside the object/element that they are conceptually "linked" to or "associated" with.

# Unrolled examples
The fully unrolled versions of this repostory's examples can be found @[heysokam/wgpu/examples](https://github.com/heysokam/wgpu/examples).


# Threading
This lib is single threaded.  
Making a multi-threaded renderer is a far-reaching goal.  
Which means that it will definitely happen, just not anytime soon.  

