# New features:
- Introduction of the `Core` objects+logic, that remove initialization boilerplate.  
- Introduction of the `Rendering Techique` objects+logic, that add functionality to draw with specific rendering styles.  
- Constructors, with (optional) sane defaults, for all wgpu "Elements" (device, adapter, pipeline, bindgroup, etc).

# Changes from wgpu to ngpu:
- `ngpu.RenderTarget` is conceptually the same as a `wgpu.RenderPass`, but contains more data (like the textures it draws into).
- `ngpu.RenderPass` is a new concept. Its the smallest part of a `RenderTech`. (see the [tech doc](./tech.md) file for an explanation)
- `ngpu.____Shape` are a rename to what wgpu calls "wgpu.____Layout". See explanation for why the word "layout" is removed from `ngpu`.

## Buffer operations:
- upload     : Copies the CPU.data of a Buffer into its GPU memory.            (called `write` in wgpu)
- transfer   : Copies the GPU.data of Buffer into another Buffer.              (called `copy`` in wgpu)
- connect    : Allows the GPU.data of a buffer to be accessible from the CPU.  (called `map` in wgpu)
- disconnect : Opposite action of connect.                                     (called `unmap` in wgpu)
- getData    : Returns a CPU copy of the GPU.data, without storing it in Buffer.CPU.data  (called `getMappedRange` in wgpu)
- download   : Copies the GPU.data of a Buffer into its CPU memory. Triggers a sync operation.
- copy       : Copies both GPU/CPU.data of a buffer into another. Like transfer, but for both sides of the data.
- clone      : Creates a duplicate of a Buffer in its current state (both its GPU/CPU data).  (also called `deepcopy` in the programming culture)

## Shape vs Layout:
### Redefinition
The term `layout` is removed from this library, and renamed to `Shape`.
- BindGroup        : (not its layout) is like a VertexBuffer or an IndexBuffer.
- BindGroupLayout  : is actually just the -shape- of that data.

A Bindgroup has two separate parts:
1. Context : The specific "connector" where data is sent to.
2. Shape   : Determines the exact shape of the data that is expected to be sent.

- layout (n.) : "configuration, arrangement", 1852, from the verbal phrase; "rough design of a printing job" from 1910.
- shape  (n.) : "definite, regular, or proper form" from 1630s; 
From its very etymology, Layout describes a configuration or arrangement, but doesn't -imply- definitiveness or strictness.  
BUT... layouts in wgpu ARE strict and rigid.  
Once they are created, they cannot be changed (unless completely remade).  
As such, the word "Shape" actually describes what they are far better than "Layout".  

### ObjectShape vs Object    (eg: like wgpu.PipelineLayout vs wgpu.Pipeline):
- Shape  : Definite form that data MUST match to be able to be connected (aka "bound") to a slot.
- Object : The data that is being connected for access.
You can think of them as the shape of the connector hole for a cable.  
The cable must match a very specific shape (data, size, type) to be connected correctly.


## RenderData and RenderBlock
### Redefinition
- RenderData  : Type for read-only data, meant to be used by the GPU in shader code.  (aka Uniform Variable/Block)  
- RenderBlock : Type for data (read+write), meant to be used by the GPU in shader code.  (aka Shader Storage Variable/Block)  

### Why Data/Block, and not just "Uniform/Storage"
This library aims to achieve inuitive usage.  

While the word "uniform" is widely used, its an old term that is actually a shortened version of "Uniform Data Block/Variable".  
Uniform is trying to signal that its data both cannot be of a different shape, and that it cannot be written to.  
While that might be representative of its functionality, the concept of "Render Data" makes a lot more intuitive sense,  
without requiring explicit knowledge of graphics programming lingo.  

While the word "Data" could be thought of as a more generalistic (and therefore ambiguous) term,  
its intuitiveness makes up for the problem of generality.  
By using the term as a strict Nim Type, that ambiguity is gone. Since no other data can be RenderData.  
And the type system dictates its strict and non-modifiable properties.  


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
The fully unrolled versions of this repository's examples can be found @[heysokam/wgpu/examples](https://github.com/heysokam/wgpu/examples).


# Threading
This lib is single threaded.  
Making a multi-threaded renderer is a far-reaching goal.  
Which means that it will definitely happen, just not anytime soon.  

